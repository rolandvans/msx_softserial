;RECEIVING AND SENDING RS232 DATA @84600 BITS/S  ON A STANDARD MSX 3.57MHz 
CPU Z80
FNAME "86400.BIN"

;VOICEAQ:  EQU $D000 ;BUFFER TO OCCUPY IN SYSTEM AREA: DO NOT USE PLAY... 

;MSX .BIN HEADER
DB $FE
DW START, END, START

ORG $D000
START:

; READ BC BYTES FROM PORT TO (HL)
RECBYTES:
	DI			; NO INTERRUPTS, TIME CRITICAL ROUTINE
    INC BC      ; BC TO COMPENSATE LOOP (CHECK IS BEFORE ISO AFTER WRITING BYTE)
    LD D,B      ; USE DE AS COUNTER, WE NEED C FOR IN A,(C)
    LD E,C
	LD A,$0F	; PSG REGISTER 15, SELECT JOYSTICK PORT 2
	OUT ($A0),A
	IN A,($A2)
	SET 6,A		; SELECT JOY2
	OUT ($A1),A
	LD A,$0E	; SET PSG #14 WE READ BIT 0 (JOY-UP) AS INPUT (RX) 0V='0',5V='1'
	OUT ($A0),A
    LD C,$A2    ; PSG READ REGISTER
.FIRSTSTARTBIT:
    IN A,(C)    ; WAIT FOR STARTBIT
    JP PE,.FIRSTSTARTBIT
.DELAY:         ; 27 CYCLES DELAY TO NEXT READ
;    IN A,($A2)  ;27 DUMMY CYCLES DELAY
;    NOP
;    NOP
;    NOP
    DEC DE
    LD A,D
    OR E
    JR Z,.EXIT
.READBYTE:
;    IN A,($A2)  ;BIT0
    IN A,(C)    ; BIT0   
    RRCA
    RR B
    IN A,($A2)  ; 14 DUMMY CYCLES
    IN A,($A2)  ; BIT1
    RRCA
    RR B
    NOP         ; 15 DUMMY CYCLES
    NOP
    NOP
    IN A,($A2)  ; BIT2
    RRCA
    RR B
    IN A,($A2)  ; 14 DUMMY CYCLES
    IN A,($A2)  ; BIT3
    RRCA
    RR B
    IN A,($A2)  ; 14 DUMMY CYCLES
    IN A,($A2)  ; BIT4
    RRCA
    RR B
    NOP         ; 15 DUMMY CYCLES
    NOP
    NOP
    IN A,($A2)  ; BIT5
    RRCA
    RR B
    IN A,($A2)  ; 14 DUMMY CYCLES
    IN A,($A2)  ; BIT6
    RRCA
    RR B
    NOP         ; 15 DUMMY CYCLES
    NOP
    NOP
    IN A,($A2)  ; BIT7
    RRCA
    RR B
    LD (HL),B   ; STORE RESULT, IGNORE STOPBIT
    INC HL
.WAITFORSTARTBIT:
    IN A,(C)        ; 
    JP PO,.DELAY
    IN A,(C)
    JP PO,.DELAY
    IN A,(C)
    JP PO,.DELAY
.EXIT:
    EI              ; TIME-OUT, RETURN (END OR TIME-OUT, CHECK HL VALUE TO BE SURE)
    RET             ; IF ZERO FLAG IS SET: OK, OTHERWISE TIME-OUT ERROR.

;SEND 'BC' BYTES FROM [HL] TO PIN6, JOY2
;MSX, Z80 3.58MHz 86400bps
SENDBYTES:	
	DI	;NO INTERRUPTS
	LD A,$0F	;SELECT PSG REG #15
	OUT ($A0),A
	IN A,($A2)	;SAVE VALUE
    PUSH AF
	SET 6,A		;JOY2
	RES 2,A		;TRIG1 LOW
	LD E,A		;0V VALUE (0) IN E
	SET 2,A		;TRIG1 HIGH
	LD D,A		;5V VALUE (1) IN D

.BYTELOOP:
    PUSH BC
    LD B,(HL)
    LD C,$A1
.STARTBIT:
    OUT (C),E   ;STARTBIT=LOW
.BYTE:
    RRC B
    LD A,D
    JR C,.SETBIT0
    LD A,E
.SETBIT0:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT1
    LD A,E
.SETBIT1:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT2
    LD A,E
.SETBIT2:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT3
    LD A,E
.SETBIT3:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT4
    LD A,E
.SETBIT4:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT5
    LD A,E
.SETBIT5:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT6
    LD A,E
.SETBIT6:
    OUT (C),A
    RRC B
    LD A,D
    JR C,.SETBIT7
    LD A,E
.SETBIT7:
    OUT (C),A
    INC HL
    POP BC
    DEC BC
    LD A,D
.STOPBIT:
    OUT ($A1),A    
    LD A,B
    OR C
    JP NZ,.BYTELOOP
.EXIT:
	LD A,$0F	;SELECT PSG REG #15
	OUT ($A0),A
    POP AF
	OUT ($A1),A	;RESTORE VALUE
    EI  ;EXIT
    RET

;ADD ROUTINE TO CHECK DATA (CRC-16)
CRC16:
    ;\ Enter here with HL=>data, BC=count, DE=incoming CRC
    LD DE,$0000
bytelp:
    PUSH BC                   ;:\ Save count
    LD A,[HL]                 ;:\ Fetch byte from memory
    ;:
    ;\ The following code updates the CRC in DE with the byte in A ---+
    XOR D                     ;:\ XOR byte into CRC top byte          |
    LD B,8                    ;:\ Prepare to rotate 8 bits            |
rotlp:                    ;:\                                     |
    SLA E
    ADC A,A             ;:\ Rotate CRC                          |
    JP NC,clear               ;:\ b15 was zero                        |
    LD D,A                    ;:\ Put CRC high byte back into D       |
    LD A,E
    XOR $21
    LD E,A     ;:\ CRC=CRC XOR &1021, XMODEM polynomic |
    LD A,D
    XOR $10            ;:\ And get CRC top byte back into A    |
clear:                    ;:\                                     |
    DEC B
    JP NZ,rotlp         ;:\ Loop for 8 bits                     |
    LD D,A                    ;:\ Put CRC top byte back into D        |
    ;\ ---------------------------------------------------------------+
    ;:
    INC HL                    ;:\ Step to next byte
    POP BC
    DEC BC             ;:\ num=num-1
    LD A,B
    OR C
    JP NZ,bytelp  ;:\ Loop until num=0
    ;LD (crc),DE               ;:\ Store outgoing CRC
    RET
END:
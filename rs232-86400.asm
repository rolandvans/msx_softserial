;RECEIVING AND SENDING RS232 DATA @84600 BITS/S  ON A STANDARD MSX 3.57MHz                                                                                                                                                                             
CPU Z80                                                                                                                                                                            
FNAME "86400.BIN"                                                                                                                                                                            
                                                                                                                                                                            
;VOICEAQ:  EQU $D000                                                                                                                                                                              
                                                                                                                                                                            
;MSX .BIN HEADER                                                                                                                                                                            
DB $FE                                                                                                                                                                            
DW START, END, START                                                                                                                                                                            
                                                                                                                                                                            
ORG $D000                                                                                                                                                                            
START:                                                                                                                                                                            
                                                                                                                                                                            
; READ BC BYTES FROM PORT TO (HL)                                                                                                                                                                            
RX:                                                                                                                                                                            
	DI			; NO INTERRUPTS, TIME CRITICAL ROUTINE                                                                                                                                                                            
    INC BC      ; COMPENSATE LOOP (CHECK IS BEFORE ISO AFTER WRITING BYTE)                                                                                                                                                                            
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
    DEC DE                                                                                                                                                                            
    LD A,D                                                                                                                                                                            
    OR E                                                                                                                                                                            
    JR Z,.EXIT                                                                                                                                                                            
.READBYTE:                                                                                                                                                                            
    IN A,(C)    ; BIT0                                                                                                                                                                               
    RRCA                                                                                                                                                                            
    RR B                                                                                                                                                                            
    IN A,(C)  ; 14 DUMMY CYCLES                                                                                                                                                                            
    IN A,($A2)  ; BIT1                                                                                                                                                                            
    RRCA                                                                                                                                                                            
    RR B                                                                                                                                                                            
    NOP         ; 15 DUMMY CYCLES                                                                                                                                                                            
    NOP                                                                                                                                                                            
    NOP                                                                                                                                                                            
    IN A,($A2)  ; BIT2                                                                                                                                                                            
    RRCA                                                                                                                                                                            
    RR B                                                                                                                                                                            
    IN A,(C)  ; 14 DUMMY CYCLES                                                                                                                                                                            
    IN A,($A2)  ; BIT3                                                                                                                                                                            
    RRCA                                                                                                                                                                            
    RR B                                                                                                                                                                            
    IN A,(C)  ; 14 DUMMY CYCLES                                                                                                                                                                            
    IN A,($A2)  ; BIT4                                                                                                                                                                            
    RRCA                                                                                                                                                                            
    RR B                                                                                                                                                                            
    NOP         ; 15 DUMMY CYCLES                                                                                                                                                                            
    NOP                                                                                                                                                                            
    NOP                                                                                                                                                                            
    IN A,($A2)  ; BIT5                                                                                                                                                                            
    RRCA                                                                                                                                                                            
    RR B                                                                                                                                                                            
    IN A,(C)  ; 14 DUMMY CYCLES                                                                                                                                                                            
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
    IN A,(C)        ;TIME OUT IF STARTBIT IS TOO LATE                                                                                                                                                                             
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
TX:	                                                                                                                                                                            
	DI	;NO INTERRUPTS                                                                                                                                                                            
	LD A,$0F	;SELECT PSG REG #15                                                                                                                                                                            
	OUT ($A0),A                                                                                                                                                                            
	IN A,($A2)	;SAVE VALUE OF PSG REGISTER                                                                                                                                                                            
    PUSH AF                                                                                                                                                                            
	SET 6,A		;JOY2                                                                                                                                                                            
	RES 2,A		;TRIG1 LOW                                                                                                                                                                            
	LD E,A		;0V VALUE (0) IN E                                                                                                                                                                            
	SET 2,A		;TRIG1 HIGH                                                                                                                                                                            
	LD D,A		;5V VALUE (1) IN D                                                                                                                                                                            
    LD C,$A1    ;WRITE REGISTER                                                                                                                                                                            
    PUSH BC                                                                                                                                                                            
    EXX                                                                                                                                                                            
    POP BC      ;MOVE BC -> BC'                                                                                                                                                                            
    EXX                                                                                                                                                                            
.BYTELOOP:                                                                                                                                                                            
    LD B,(HL)                                                                                                                                                                            
.STARTBIT:                                                                                                                                                                            
    OUT (C),E   ;STARTBIT=LOW    |                                                                                                                                                                         
.BYTE:                          ;|                                                                                                                                                  
    RRC B                       ;|                                                                                                                                                     
    LD A,D                      ;|(42)                                                                                                                                                      
    JR C,.SETBIT0               ;|                                                                                                                                                             
    LD A,E                      ;|                                                                                                                                                      
.SETBIT0:                       ;|                                                                                                                                                     
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
    OUT (C),A       ;(41) TO STOPBIT                                                                                                                                                                            
    EXX             ;COUNTER IN BC'                                                                                                                                                                            
    DEC BC                                                                                                                                                                            
    LD A,B                                                                                                                                                                            
    OR C            ;Z-FLAG                                                                                                                                                                            
    EXX                                                                                                                                                                            
.STOPBIT:                                                                                                                                                                            
    OUT (C),D       ;(42) TO STARTBIT                                                                                                                                                                            
    INC HL                                                                                                                                                                                
    JR NZ,.BYTELOOP                                                                                                                                                                            
.EXIT:                                                                                                                                                                            
	LD A,$0F	    ;SELECT PSG REG #15                                                                                                                                                                            
	OUT ($A0),A                                                                                                                                                                            
    POP AF                                                                                                                                                                            
	OUT ($A1),A	    ;RESTORE VALUE                                                                                                                                                                            
    EI              ;EXIT                                                                                                                                                                            
    RET                                                                                                                                                                            

END:

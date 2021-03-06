;READ DATA VIA JYSTICK AT 115200 BITS/SECOND
;REQUIRES 2 STOPBITS (!!)
;STARTS WRITING DATA AT HL, STOPS AT TIMEOUT
;MODIFIES HL,BC,AF, PSG REG #15
CPU Z80
FNAME "RS232RD.BIN"

VOICEAQ:  EQU $F975 ;BUFFER TO OCCUPY IN SYSTEM AREA: DO NOT USE PLAY... 

;MSX .BIN HEADER
DB $FE
DW START, END, START

ORG VOICEAQ
START:

RECBYTES:
    ;INITIAL SETUP
	DI			;NO INTERRUPTS, TIME CRITICAL ROUTINE
	LD A,$0F	;PSG REGISTER 15, SELECT JOYSTICK PORT 2
	OUT ($A0),A
	IN A,($A2)
	SET 6,A		;SELECT JOY2
	OUT ($A1),A
    LD B,$00    ;NICE FOR DEBUGGING, NOT STRICTLY NEEDED

	LD A,$0E	;SET PSG #14 WE READ BIT 0 (JOY-UP)
	OUT ($A0),A
    LD C,$A2    ;PSG READ REGISTER
.WAITFORFIRSTSTARTBIT:
    IN A,(C)    ;STARTBIT
    JP PE,.WAITFORFIRSTSTARTBIT
    NOP   ;10 CYCLE DUMMY DELAY
    NOP
    ;START READING DATA BITS
    IN A,($A2)  ;BIT0
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT1
    RRCA
    RR B
    IN A,(C)    ;BIT2
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT3
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT4
    RRCA
    RR B
    IN A,(C)    ;BIT5
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT6
    RRCA
    RR B
    ;NOP
    IN A,(C)  ;BIT7
    RRCA
    RR B
    LD (HL),B
    INC HL
.WAITFORSTARTBIT:
    IN A,(C)
    JP PO,.READDATABITS
    IN A,(C)
    JP PO,.READDATABITS
    IN A,(C)
    JP PO,.READDATABITS
    EI
    RET
.READDATABITS:
    NOP   ;10 CYCLE DUMMY
    NOP
    ;START READING DATA BITS
    IN A,($A2)  ;BIT0
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT1
    RRCA
    RR B
    IN A,(C)    ;BIT2
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT3
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT4
    RRCA
    RR B
    IN A,(C)    ;BIT5
    RRCA
    RR B
    NOP
    IN A,($A2)  ;BIT6
    RRCA
    RR B
    ;NOP
    IN A,(C)  ;BIT7
    RRCA
    RR B
    LD (HL),B
    INC HL
    JP .WAITFORSTARTBIT

;SEND 'BC' BYTES FROM [HL] TO PIN6, JOY2
;MSX, Z80 3.58MHz 115200bps
SENDBYTES:	
	DI	;NO INTERRUPTS
	LD A,$0F	;SELECT PSG REG #15
	OUT ($A0),A
	IN A,($A2)	;SAVE VALUE
	;PUSH AF
	SET 6,A		;JOY2
	RES 2,A		;TRIG1 LOW
	LD E,A		;0V VALUE (0) IN E
	SET 2,A		;TRIG1 HIGH
	LD D,A		;5V VALUE (1) IN D

.BYTELOOP:
    LD A,(HL)
    PUSH BC
    LD C,$A1
.STARTBIT:
    OUT (C),E   ;STARTBIT=LOW
.BYTE:
    RRCA
    JP C,.BIT0H
;BIT LOW
.BIT0L:
    OUT (C),E
    RRCA
    JP C,.BIT1H
.BIT1L:
    OUT (C),E
    RRCA
    JP C,.BIT2H
.BIT2L:
    OUT (C),E
    RRCA
    JP C,.BIT3H
.BIT3L:
    OUT (C),E
    RRCA
    JP C,.BIT4H
.BIT4L:
    OUT (C),E
    RRCA
    JP C,.BIT5H
.BIT5L:
    OUT (C),E
    RRCA
    JP C,.BIT6H
.BIT6L:
    OUT (C),E
    RRCA
    JP C,.BIT7H
.BIT7L:
    OUT (C),E
    LD A,D  ;NOP
    POP BC  ;JP .STOPBIT
    OUT ($A1),A
.STOPBIT:
    ; INCREASE HL AND CHECK BC COUNTER
    INC HL
    DEC BC
    LD A,B
    OR C
    JP NZ,.BYTELOOP
.EXIT:
    EI  ;EXIT
    RET
;BIT HIGH
.BIT0H:
    OUT (C),D
    RRCA
    JP NC,.BIT1L
.BIT1H:
    OUT (C),D
    RRCA
    JP NC,.BIT2L
.BIT2H:
    OUT (C),D
    RRCA
    JP NC,.BIT3L
.BIT3H:
    OUT (C),D
    RRCA
    JP NC,.BIT4L
.BIT4H:
    OUT (C),D
    RRCA
    JP NC,.BIT5L
.BIT5H:
    OUT (C),D
    RRCA
    JP NC,.BIT6L
.BIT6H:
    OUT (C),D
    RRCA
    JP NC,.BIT7L
.BIT7H:
    OUT (C),D
    POP BC     ;NOP
    JP .STOPBIT

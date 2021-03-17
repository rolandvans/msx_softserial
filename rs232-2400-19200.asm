;RECEIVING AND SENDING RS232 DATA @9600 BITS/S  ON A STANDARD MSX 3.57MHz 
CPU Z80
FNAME "RS232.BIN"

VOICEAQ:  EQU $F975 ;BUFFER TO OCCUPY IN SYSTEM AREA: DO NOT USE PLAY... 

;MSX .BIN HEADER
DB $FE
DW START, END, START

ORG VOICEAQ
START:
;TRANSFER 'BC' BYTES FROM JOY2, 'UP', PIN1 TO (HL)
;MSX, Z80 3.58MHz
;SETS CARRY BIT ON ERROR. A HOLDS ERROR CODE:
;A=1 RS232 LINE NOT HIGH,A=2 STARTBIT TIMEOUT
RECBYTES:	
	LD D,B				;USE DE AS BYTE COUNTER, B AS BIT COUNTER AND C AS VDP STATUS REGISTER
	LD E,C
	LD BC,$0099			;B=0 -> ~4 SECONDS TIME-OUT

	DI					;NO INTERRUPTS, TIME CRITICAL ROUTINE

	LD A,$0F			;PSG REGISTER 15, SELECT JOYSTICK PORT 2
	OUT ($A0),A
	IN A,($A2)
	SET 6,A				;SELECT JOY2
	OUT ($A1),A

	LD A,$0E			;SET PSG #14
	OUT ($A0),A
	IN A,($A2)
	AND $01
	JR NZ,.STARTBIT		;RS232 LINE SHOULD BE HIGH, OTHERWISE STOP
	LD A,$01			;ERROR, RS232 LINE NOT READY
	SCF
	EI
	RET
.STARTBIT:
	IN A,($A2)
	AND $01
	JP Z,.STARTREAD		;YES, WE HAVE A START BIT

	IN F,(C)			;VDP INTERRUPT?
	JP P,.STARTBIT		;NO INTERRUPT

	IN A,($A2)
	AND $01
	JP Z,.STARTREAD		;YES, WE HAVE A START BIT

	DJNZ .STARTBIT
	LD A,$02			;ERROR START BIT TIME-OUT ~4-5S
	SCF
	EI
	RET
.STARTREAD:
	LD A,(DELAY_START)	;DELAY FROM START BIT -> BIT 0
	CALL DELAY			;WAIT FOR BIT0
	LD B,7				;WE NEED 8 BITS, READ AS 7+1
.READBITS:
	IN A,($A2)
	RRCA				;SHIFT DATA BIT (0) -> CARRY
	RR (HL)				;SHIFT CARRY -> [HL]
	LD A,(DELAY_BITS)	;DELAY FROM BIT N -> BIT N+1
	CALL DELAY
	DJNZ .READBITS
	IN A,($A2)			;LAST BIT, OTHER DELAY (STOPBIT)
	RRCA				;SHIFT DATA BIT (0) -> CARRY
	RR (HL)				;SHIFT CARRY -> [HL]
.NEXTBYTE:
	LD A,(DELAY_STOP)	;DELAY BIT 7 TO ENSURE WE ARE AT STOPBIT
	CALL DELAY
	LD B,A				;LD B,0 BUT A=0
	INC HL
	DEC DE
	LD A,D
	OR E
	JP Z,.FINISH		;WE ARE FINISHED
	IN A,($A2)			;READ ACTUAL STOPBIT VALUE
	AND $01
	JR Z,.STARTBIT		;NEXT BYTE OR STOPBIT ERROR
.STOPBITERROR:
	LD A,3
	SCF
	EI
	RET
.FINISH:
	OR A				;RESET CARRY FLAG
	EI
	RET

;SEND 'BC' BYTES FROM [HL] TO PIN6, JOY2
;MSX, Z80 3.58MHz
SENDBYTES:	
	DI	;NO INTERRUPTS
	LD A,$0F	;SELECT PSG REG #15
	OUT ($A0),A
	IN A,($A2)	
	PUSH AF		;SAVE VALUE OF REG #15
	SET 6,A		;JOY2
	RES 2,A		;TRIG1 LOW
	LD E,A		;0V VALUE (0) IN E
	SET 2,A		;TRIG1 HIGH
	LD D,A		;5V VALUE (1) IN D
.BYTELOOP:	
	PUSH BC
	LD A,E			;START BIT (=0)
.STARTBIT:	
	LD C,(HL)
	LD B,$08
	OUT ($A1),A
	ADD A,$00		;DUMMY 8 CYCLES
	LD A,(DELAY_BITS)
	CALL DELAY
.BITLOOP:	
	RRC C
	LD A,D			;ASSUME BIT=1
	JR C,.SETBIT
	LD A,E			;NO, BIT=0
.SETBIT:	
	OUT ($A1),A
	LD A,(DELAY_BITS)
	CALL DELAY
	DJNZ .BITLOOP
.STOPBIT:	
	LD A,D
	OUT ($A1),A		;STOP BIT (=1)
	LD A,(DELAY_STOP)
	CALL DELAY
	POP BC
	DEC BC
	INC HL
	LD A,B
	OR C
	JP NZ,.BYTELOOP
.EXIT:
	POP AF
	OUT ($A1),A		;RESTORE REG #15 OF PSG		
	EI
	RET

DELAY:
	DEC A
	JP NZ,DELAY
	RET

;SET SPEED FRO SERIAL COMMUNICATION: A=0 2400 BPS, A=1 4800 BPS, A=2 9600 BPS, A=3 19200 BPS
SETSPEED:
	AND 3
	LD HL,SERIALSPEEDDATA
	LD E,A
	SLA A
	ADD A,E
	LD E,A
	LD D,0
	ADD HL,DE
	LD DE,DELAY_START
	LD BC,3
	LDIR
	RET

;DEFAULT SETTING 9600 BPS
DELAY_START:
DB 28
DELAY_BITS:
DB 18
DELAY_STOP:
DB 16

SERIALSPEEDDATA:
;2400 BPS (0)
DB 133,88,85
;4800 BPS (1)
DB 63,41,38
;9600 BPS (2)
DB 28,18,16
;19200 BPS (3)
DB 11,6,4

END:
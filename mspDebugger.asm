.include "msp430g2553.inc"

    org 0xf000


start:
    ;initial setup
    ;initialize stack pointer
    mov.w #300h , SP
    ;stop watchdop timer
    mov.w #WDTPW+WDTHOLD , &WDTCTL
    ;call initUart in order to initialize UART communication
    call #initUart
main:

	mov.b #'>',R4
	call #OUTA_UART

	call #INCHAR_UART
	call #OUTA_UART
	cmp.b #'H',R4
	jne XLP1; jump to hex calculator
	;call #PRINT_MEM
	call #HEX_CALC
XLP1:
	cmp.b #'M',R4
	jne XLP2; jump to hex calculator
	;call #PRINT_MEM
	call #MEM_MODIFY

XLP2:
	cmp.b #'D',R4
	jne XLP3

	call #DISPLAY_MEM

XLP3:
	; mov.w #0x3157,R6
    ;call #HEX4IN
    ;call #PRINT_NEWLINE

;******************************************************************************
;;CODE BELOW USED TO HELP PRINT RESULT CORECTLY IN MAC  (SCREEN) HYPERTERMINAL
;******************************************************************************

;;; mov.w R6,R4
; call #HEX4OUT
	;;cmp.b #0xFF, R14
	;;jne XQ
	;;call #PRINT_NEWLINE
;;XQ:	;; call #PRINT_NEWLINE
	;;call #HEX2OUT
	;;cmp.b #0xFF, R14
	;;jne XQ2
	;;call #PRINT_NEWLINE

;;XQ2:

	;; call #HEX2OUT

 call #PRINT_NEWLINE

	mov.b #0x00,R14

	;; xor.b #0x41 ,  &P1OUT
    jmp main

DISPLAY_MEM:
;----------------------------------------------------------------
;***************PART 8 IS HERE
;This is a subroutine thatmemory as a 4 digit HEX number and an
;ASCII character between the values of ($21 to $7E) from addresses XXXX to YYYY.
;
; User needs to input two 4 Hexadecimal values to indicate range
;  XXXX is the start of the range and YYYY is the end of the range
;
;Here is an example output:
;D 0100 0112
; 0100 3132 3330 4100 FE00 0203 0405 3941 4243	1230A.......9ABC
; 0110 41ED 		A.
; The first number of lines display the values of the 16 bit memory address in
; hexadecimal value
; A space is printed then the same values printed from the range in memory
; are converted to their ascii values and printed
;	NOTE: The ascii value is printed fom the range 0x21 - 0x7E
;  any other number beyond that range gets a '.' as their ascii value
;----------------------------------------------------------------

	push.w R6
	push.w R7
	push.w R8
	push.w R9
	push.w R10

	call #SPACE
	call #HEX4IN
	mov.w R6,R7

	call #SPACE
	call #HEX4IN

	mov.b #0x00,R8

	mov.w R7,R9 ; move R7 start val in temp reg
	mov.w R6,R10
	incd R10 ; get next highest memory since conditins that I am doing is exclusive
	mov.w R9,R6
	call #PRINT_NEWLINE
	call #HEX4OUT

D_CHECK:
	cmp.w R9,R10
	jeq D_ASCII_END

	cmp.b #0x08,R8
	jeq D_ASCII
DLP1:
	call #SPACE
	mov.w 0(R9),R6

	call #HEX4OUT
	incd R9
	inc.w R8


	jmp D_CHECK



D_ASCII:
	call #SPACE
D_PASCII:
	cmp.w #0x00,R8
	jeq D_NEWLINE

	mov.w 0(R7),R6 ; 	This will cause the memory address to update now that it is printing ascii

	mov.w R6,R12
	mov.w R6,R13

	and.w #0xFF00,R12
	and.w #0x00FF,R13
	swpb R12
	call #CHECK_ASCII

	mov.w R13,R12
	call #CHECK_ASCII

	incd R7
	dec.w R8

	jmp D_PASCII

D_NEWLINE:
	call #PRINT_NEWLINE
	mov.w R9,R6
	call #HEX4OUT
	jmp DLP1

D_ASCII_END:
	call #SPACE
D_PASCII_END:
	cmp.w R7,R10
	jeq D_END

	mov.w 0(R7),R6

	mov.w R6,R12
	mov.w R6,R13

	and.w #0xFF00,R12
	and.w #0x00FF,R13
	swpb R12
	call #CHECK_ASCII

	mov.w R13,R12
	call #CHECK_ASCII

	incd R7
	dec.w R8

	jmp D_PASCII_END



D_END:
	pop.w R10
	pop.w R9
	pop.w R8
	pop.w R7
	pop.w R6

	ret

CHECK_ASCII:
;----------------------------------------------------------------
;This function checks to see if the hex value is within range
; 0x21 to 0x7E
; if it is in range, print the ascii value
;	else, print a '.'
; evaluates the result in R12
;----------------------------------------------------------------
	push.w R12
	push.w R6; used for HEX2OUT
	push.w R4

	cmp.w #0x0021,R12

	jlo PERIOD_PRINT

	cmp.w #0x007E,R12

	jhs PERIOD_PRINT

L1:	mov.b R12,R4
	call #OUTA_UART
	jmp WEND

PERIOD_PRINT:
	mov.w #'.',R12
	;call #OUTA_UART
	jmp L1

WEND:
	pop.w R4
	pop.w R6
	pop.w R12
	ret



MEM_MODIFY:
;----------------------------------------------------------------
;***************PART 7 IS HERE
; This a subroutine that changes memory address at address XXXX
;	The subroutine is triggered when an 'M' is entered from the keyboard
;
;	Once 'M' is entered, the user enters 4 ascii characters
;	which indicates the memory location as a 16 bit number in hexadecimal format
;
;	Once the memory location is entered, the user sees  the value in a similar
;	16 bit number in hexadecimal format 
;
; register R7 contains the status of whether the user enters a 'P', 'N', or a space
; register R9 contains the 16bit value in Hexidecimal format to be stored in the new address
;
;Here is a sample format of what the command would look like:
;Command Format: M XXXX QQQQ
;----------------------------------------------------------------

	push.w R5

		push.w R6
		push.w R7
		push.w R9

		call #SPACE

		call #HEX4IN


MLP1:	call #PRINT_NEWLINE
		call #HEX4OUT
		call #SPACE
		push.w R6

		mov.w 0(R6),R6

		call #HEX4OUT

		pop.w R6


	call #PRINT_NEWLINE



		call #HEX4OUT

		call #SPACE

		call #HEX2INA

		cmp.b #0x03,R7

		jeq MQUIT

		cmp.b #0x01,R7
		jeq MNEXT

		cmp.b #0x02,R7
		jeq MPREV

		;mov.w R9,R6

		mov.w R9,0(R6)
		jmp MLP1
MPREV:
		decd R6

		;mov.w R6,R5
		jmp MLP1


MNEXT:
		incd R6

		;mov.w R6,R5
		jmp MLP1

MQUIT:
		pop.w R9
		pop.w R7
		pop.w R6
		pop.w R5


		ret

HEX2INA:

	push.w R4

	mov.w #0x0000,R7
	mov.w #0x0000,R9 ; register that stores new value for memory address
	mov.w #0x0004,R8
CLP1:
	cmp.b #0x00,R8
	jeq CLP5
	call #INCHAR_UART
	cmp.b #'P',R4 ; CHECK O SEE IF MNEXT COMMAND IS CALLED
	jeq	IPLUS

	cmp.b	#'N' , R4; CHECK TO SEE IF MPREV COMMAND IS CALLED
	jeq INEG

	cmp.b #0x20 , R4

	jeq ISPC


	cmp.b #0x30 , R4; CHECK TO SEE IF KEY ENTERED IS LESS THAN ZERO
	jlo 	CLP1
	cmp.b #'G' , R4; CHECK TO SEE IF KEY ENTERED IS GREATER THAN F
	jhs 	CLP1

	call #OUTA_UART ; PRINT VALID NUMBER/LETTER
	cmp.b #0x41, R4

	jlo  NUMBER

	sub.b #0x37 , R4
	jmp SHIFT

	;cmp.B #'G' , R4
	;JHS CLP1

	;cmp.b #0x3A , R4
	;jlo INUM1

	;cmp.b #0x41, R4

	;JHS CLP1



NUMBER:		sub.b #0x30,R4;subtract 0x30 since character entered is a number
SHIFT:		rla.w R9
		rla.w R9
		rla.w R9
		rla.w R9
		add.w R4,R9

		dec.b R8
	;slb.b #0x30 , R4

	jmp CLP1

;ILET1 call #OUTA_UART

	;slb.b #0x30 , R4

CLP2:  rla.b R4

	rla.b R4

	rla.b R4

	rla.b R4

	mov.b R4, R5

	mov.b R4, R5
	jmp CLP1

CLP3:	call #INCHAR_UART

	cmp.b #'P' , R4

	jeq  IPLUS

	cmp.b #'N' , R4

	jeq  INEG

	cmp.b#0x20, R4

	JEQ ISPC

	;cmp.b #0x30, R4

	;JLO CLP3

	;cmp.B #'G", R4

	;cmp.b #0x3A, R4

	;JLO INUM2

	;cmp.b #0x41, R4

	jmp CLP3

	;JHS ILET2

;ILET2	call #OUTA_UART

	;slb.b #0x37,R4

	;jmp CLP4



CLP4:	and.B #0xF0 , R5

	add.b R4, R5

CLP5: 	pop.w R4

	ret

ISPC: call #OUTA_UART

	mov.w #0x0003, R7

	jmp CLP5

IPLUS:	  call #OUTA_UART

	mov.w #0x0001 , R7

	jmp CLP5

INEG: call #OUTA_UART

	mov.w #0x0002 , R7

	jmp CLP5

HEX_CALC:
;----------------------------------------------------------------
;***************PART 9 IS HERE
; This subroutine is an implementation of a 16 bit (2 byte) hex calculator
; this function requires a initial keys enter 'H' to trigger
; function;
;
; This functions calls two functions, ADD_FUNCTION and SUB_FUNCTION
; The ADD_FUNCTION adds the two 16 bit values
; The SUB_FUNCTION subtracts the two 16 bit values
;  -Both functions return the result and
;   returns the result and the status of the C(carry),N(negative)
;   V(overflow), and Z(zero) satus bits
;
; here is an example of the input and output:
;  ADD_FUNCTION example
; >HA 0012  0034  R=0046
; > C=0 N=0 V=0 Z=0
;
;  SUB_FUNCTION example
; >HA 0034  0012  R=0022
; > C=0 N=0 V=0 Z=0
;----------------------------------------------------------------

	push.w R4
	call #INCHAR_UART
	call #OUTA_UART
	cmp.b #'A', R4



	jne HLP1

	call #ADD_FUNCTION

HLP1:	cmp.b #'S', R4



	jne HLP2

	call #SUB_FUNCTION

HLP2:	pop.w R4
	ret
ADD_FUNCTION:
;----------------------------------------------------------------
; This function is apart of the 16 bit (2 byte) hex calculator
; this function requires a initial keys enter 'HA' to trigger
; function;
;
; This functions adds the two values entered by user and
;   returns the result and the status of the C(carry),N(negative)
;   V(overflow), and Z(zero) satus bits
;
; here is an example of the input and output:
; >HA 0012  0034  R=0046
; > C=0 N=0 V=0 Z=0
;----------------------------------------------------------------
	push.w R4
	push.w R6
	push.w R7
	mov.b #' ',R4

	call #OUTA_UART

	call #HEX8IN

	add.w R6, R7 ; add the two numbers
	push.w R2	; store the status bit results
	mov.w R7,R6

	mov.b #' ',R4

	call #OUTA_UART

	mov.b #'R',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	call #HEX4OUT


	call #PRINT_NEWLINE
	mov.b #'>',R4



	;----------------
	;Check carry status bit
	;----------------
	call #OUTA_UART
	mov.b #'C',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	pop.w R6 ;here get value of R2 to get actual status bit values
	mov.w R6,R7

	and.w #0x0001,R7 ; get carry bit value
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get carry bit

	call #OUTA_UART

	mov.b #' ',R4

	call #OUTA_UART
	;----------------
	;Check overflow status bit
	;----------------
	call #OUTA_UART
	mov.b #'V',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	mov.w R6,R7 ; now get overflow status bit

	and.w #0x0100,R7 ; get overflow bit value
	swpb R7
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get overflow bit

	call #OUTA_UART
	mov.b #' ',R4

	call #OUTA_UART
	;----------------
	;Check negative status bit
	;----------------
	call #OUTA_UART
	mov.b #'N',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	mov.w R6,R7 ; now get NEGATIVE status bit

	and.w #0x0004,R7 ; get negative bit value
	rra R7
	rra R7
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get negative bit

	call #OUTA_UART
	mov.b #' ',R4

	call #OUTA_UART
	;----------------
	;Check zero status bit
	;----------------
	call #OUTA_UART
	mov.b #'Z',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART
		mov.w R6,R7 ; now get xero status bit

	and.w #0x0002,R7 ; get zero bit value
	rra R7
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get zero bit

	call #OUTA_UART
	;mov.w R2,R7  ;here get value of R2 to get actual status bit values

	;and.w #0x0080,R7 ; get carry bit value

	;cmp.b #0x0080,R7 ; compare value to get overflow bit

	;jne ZERO
	;mov.b #0x31, R4

	call #PRINT_NEWLINE





	pop.w R7
	pop.w R6
	pop.w R4

	ret

SUB_FUNCTION:
;----------------------------------------------------------------
; This function is apart of the 16 bit (2 byte) hex calculator
; this function requires a initial keys enter 'HS' to trigger
; function;
;
; This functions SUBTRACTS the two values entered by user and
;   returns the result and the status of the C(carry),N(negative)
;   V(overflow), and Z(zero) satus bits
;
;Here is an example of the output:
; >HA 0034  0012  R=0022
; > C=0 N=0 V=0 Z=0
;----------------------------------------------------------------
	push.w R4
	push.w R6
	push.w R7
	mov.b #' ',R4

	call #OUTA_UART
	call #HEX8IN

	sub.w R6, R7  ; subtract the two numbers
	push.w R2   ; store status bit results
	mov.w R7,R6

	mov.b #' ',R4

	call #OUTA_UART

	mov.b #'R',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	call #HEX4OUT


	call #PRINT_NEWLINE
	mov.b #'>',R4


	pop.w R6 ;here get value of R2 to get actual status bit values
	;----------------
	;Check carry status bit
	;----------------
	call #OUTA_UART
	mov.b #'C',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	mov.w R6,R7

	and.w #0x0001,R7 ; get carry bit value
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get carry bit

	call #OUTA_UART

	mov.b #' ',R4

	call #OUTA_UART
	;----------------
	;Check overflow status bit
	;----------------
	call #OUTA_UART
	mov.b #'V',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	mov.w R6,R7 ; now get overflow status bit

	and.w #0x0100,R7 ; get overflow bit value
	rra.w R7
	rra.w R7
	rra.w R7
	rra.w R7
	rra.w R7
	rra.w R7
	rra.w R7
	rra.w R7

	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get overflow bit

	call #OUTA_UART
	mov.b #' ',R4

	call #OUTA_UART
	;----------------
	;Check negative status bit
	;----------------
	call #OUTA_UART
	mov.b #'N',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART

	mov.w R6,R7 ; now get NEGATIVE status bit

	and.w #0x0004,R7 ; get negative bit value
	rra R7
	rra R7
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get negative bit

	call #OUTA_UART
	mov.b #' ',R4

	call #OUTA_UART
	;----------------
	;Check zero status bit
	;----------------
	call #OUTA_UART
	mov.b #'Z',R4
	call #OUTA_UART

	mov.b #'=',R4
	call #OUTA_UART
		mov.w R6,R7 ; now get xero status bit

	and.w #0x0002,R7 ; get zero bit value
	rra R7
	add.w #0x30,R7 ; get ascii value
	mov.w R7,R4 ; MOVE value to get zero bit

	call #OUTA_UART
	;mov.w R2,R7  ;here get value of R2 to get actual status bit values

	;and.w #0x0080,R7 ; get carry bit value

	;cmp.b #0x0080,R7 ; compare value to get overflow bit

	;jne ZERO
	;mov.b #0x31, R4

	call #PRINT_NEWLINE





	pop.w R7
	pop.w R6
	pop.w R4

	ret

SPACE:
;----------------------------------------------------------------
;This function prints a space to the termainal
;----------------------------------------------------------------
	mov.b #' ',R4
	call #OUTA_UART
	ret

PRINT_ONE:
;----------------------------------------------------------------
;This function prints a one to the terminal
;----------------------------------------------------------------
	mov.b #0x31, R4
	call #OUTA_UART
	ret

PRINT_ZERO:
;----------------------------------------------------------------
;This function prints a one to the terminal
;----------------------------------------------------------------
	mov.b #0x30, R4
	call #OUTA_UART
	ret
HEX8IN:
;----------------------------------------------------------------
;***************PART 5 IS HERE
;This function enters two 4 ascii characters into
; registers R6 and R7
;----------------------------------------------------------------


	call #HEX4IN

	mov.b #' ',R4

	call #OUTA_UART

	mov.w R6, R7 ; temp store R6 vale temporarilt to R7

	call #HEX4IN




	ret
PRINT_MEM:
;----------------------------------------------------------------
; NOTE: functino contains implecit function HEX8IN and HEX8OUT
;subroutine that Print two 4 ascii character strings that are both
;inputted by the use
;
;function calls HEX4IN, calls HEX4OUT TWICE
; result is printed from R6 and R7->second 4 ascii value entered from keyboard
; temp storage is used with R8
;----------------------------------------------------------------
	push.w R7
	push.w R8

	call #HEX4IN

	mov.b #' ',R4

	call #OUTA_UART

	mov.w R6, R7 ; temp store R6 vale temporarilt to R7

	call #HEX4IN



	call #PRINT_NEWLINE

	mov.w R6, R8 ; temp store second ascii vale to R8
	mov.w R7, R6 ; return first 4 ascii value to r6
	call #HEX4OUT


	mov.b #' ',R4

	call #OUTA_UART


	mov.w R8, R6 ; ; return second 4 ascii value to r6
	;call #HEX4IN
	call #HEX4OUT
	pop.w R8
	pop.w R7

	ret


HEX4IN:
;----------------------------------------------------------------
;	***************PART 3 IS HERE
;This function calls the subroutine HEX2OUT twice in order to input 4 ASCII HEX format numbers
;   each ascii character is stored into R4, all 4 ascii values will be stored in R6
;----------------------------------------------------------------
	push.w R7
	mov.w #0x0000,R6
	call #HEX2IN ; store first ascii values into R6

	mov.w R6,R7
	call #HEX2IN ; store next character in lower bits

	swpb R7
	add.w R7,R6


	pop.w R7
	ret




HEX2IN:
;----------------------------------------------------------------
;***************PART 2 IS HERE
;;; This function stores the words entered in the hyper terminal from the keyboard into R6
;----------------------------------------------------------------

	push.w R7
	;; push.w R6
	call #INCHAR_UART
	;;
	mov.w R4,R6
	call #Convert  		; convert the first ascii to hex value
	 call #OUTA_UART
	call #INCHAR_UART

        call #OUTA_UART
	mov.w R6,R7
	mov.w R4, R6
	call #Convert

	cmp.b #0x40,R4
	jhs EXTRA_SPACE
	;; 	mov.w R6,R7

	;; 	mov.w R4,R6
	;; call #Convert


RET1:
	rla R7
	rla R7
	rla R7
	rla R7
	add.b R7,R6


	pop.w R7
	;call #PRINT_NEWLINE

	ret


	;; pop.w R6

EXTRA_SPACE:	mov.b #0xFF, R14 		;flag by setting R14 to FF (indicate extra printing)
	jmp  RET1


PRINT_NEWLINE:
;----------------------------------------------------------------
;***************PART 6 IS HERE
;;; This function is used to print a new line on the hyper terminal
;----------------------------------------------------------------

	push.w R4
    mov.w #0x0A,R4
    call #OUTA_UART

    mov.w #0x0D,R4
    call #OUTA_UART
	pop.w R4
    ret

Convert:

		push.w R9



			mov.w #0x2F, R9
			cmp.w R6,R9
			jge  if
			cmp.w #0x3A,R6
			jge  if
			sub.w #0x30,R6

if:	cmp.w R6, R9
			jge else
			cmp.w #0x3A, R6
			jge else
			sub.w #0x30,R6
			jmp continue




else:	mov.w #0x40, R9
		cmp.w R6,R9
			jge continue
			cmp.w #0x47, R6
			jge continue
			sub.w #0x37,R6





continue:
	pop.w R9

	ret

HEX4OUT:
;----------------------------------------------------------------
;***************PART 4 IS HERE
; Function prints to the screen 4 ASCII values in Hex Format
; result printed from register 6
;uses register 7 as temp value
;----------------------------------------------------------------

	push.w R6 ; entire word value is stored in register
	push.w R7 ;


	mov.w R6, R7
	swpb  R6 ; get higher bytes into lower bytes to print value

	and.w #0x00FF, R6

	call #HEX2OUT

	mov.w R7, R6

	and.w #0x00FF, R6
	;swpb R6

	call #HEX2OUT

	pop.w R7
	pop.w R6

	ret






;; this function takes hex values in R5 and displays the two hex values
HEX2OUT:
;----------------------------------------------------------------
;***************PART 1 IS HERE
; Function prints to the screen two hex values in ASCII format
; result  from register 6 , converted to register r4
;----------------------------------------------------------------

	 push.w R4
	push.w R6

	;; get 4 upper bits
	rra R6
	rra R6
	rra R6
	rra R6

	;; if character is between 0x00-0x09, add 0x30 to get ASCII hex result

	;; and.w #0x000F,R6
	;; R6>A
	cmp.b #0x0A,R6
	jhs  Letter1
	;; R6<A
	add.b #0x30,R6
	mov.b R6,R4
	call #OUTA_UART
	jmp LP1

;; if character is between 0x0A-0x0F,which is greater than 0x09,  add 0x37 to get ASCII hex result
Letter1: add.b #0x37,R6
	mov.b R6,R4
	call #OUTA_UART
	jmp LP1


LP1:	;print 4 lower bits
	pop.w R6
	pop.w R4

	 push.w R6
	push.w R4

	and.w #0x000F, R6; and to get only last 4 bits

	;; if character is between 0x00-0x09 hex, add 0x30 to get ASCII hex resuly

	;; R6>A
	cmp.b #0x0A,R6
	jhs  Letter2 	;jump if letter
	;; R6<A
	add.b #0x30,R6
	mov.b R6,R4
	call #OUTA_UART
	jmp LP2


;; if character is between 0x0A-0x0F hex,which is greater than 0x09,  add 0x37 to get ASCII hex result
Letter2: add.b #0x37,R6
	mov.b R6,R4
	call #OUTA_UART
	jmp LP2

LP2:

	pop.w R6
	pop.w R4

	ret







;Subprocess that creates a delay
delay:
    push R5
    mov.w #0xFFFF , R5
delay_loop:
    dec R5
    jn delay_loop
delay_done:
    pop R5
    ret

;Initialize the uart
initUart:
    ;set up the msp430 for a 1 MHZ clock speed
    mov.b &CALBC1_1MHZ, &BCSCTL1
    mov.b &CALDCO_1MHZ, &DCOCTL
    ;transmit and receive to port 1 bits 1 and 2
    mov.b #0x06 , &P1SEL
    ;transmit and receive to port 1 bits 1 and 2
    mov.b #0x06 , &P1SEL2
    ;8 data, no parity 1 stop, uart, async
    mov.b #0x00 , &UCA0CTL0
    ;select MLK set to 1 MHZ and put in software reset the UART
    mov.b #0x81 , &UCA0CTL1
    ;upper byte of divider clock word
    mov.b #0x00 , &UCA0BR1
    ;clock divide from a MLK of 1 MHZ to a bit clock of 9600 -> 1MHZ
    mov.b #0x68 , &UCA0BR0
    mov.b #0x06 , &UCA0MCTL
    ;do not loop the transmitter back to the receiver for echoing
    mov.b #0x00 , &UCA0STAT
    mov.b #0x80 , &UCA0CTL1
    ;turn transmit interrupts off
    mov.b #0x00 , &IE2
    ret
;prints the value in R4 to the uart
OUTA_UART:
    ;push R5 to the stack in order to preserve its value
    push R5
uartPutChar_loop:
    ;move the value from IFG2 to R5
    mov.b &IFG2 , R5
    ;isolate bit 1
    and.b #0x02 , R5
    ;check if it equals 0
    cmp.b #0x00 , R5
    ;if it equals zero jump back to beginnnig of loop
    jz uartPutChar_loop
    ;if it doesnt equal 0 move the value to be printed to UCA0TXBUF
    mov.b R4 , &UCA0TXBUF
    ;retrieve R5's original value from the stack
    pop R5
    ;return
    ret

;accepts a value as input from the uart
INCHAR_UART:
    ;push R5 to the stack in order to preserve its value
    push R5
uartGetChar_loop:
    ;move the value from IFG2 to R5
    mov.b &IFG2 , R5
    ;isolate bit 0
    and.b #0x01 , R5
    ;isolate bit 1
    cmp.b #0x00 , R5
    ;if it equals zero jump back to beginnnig of loop
    jz uartGetChar_loop
    ;if it doesnt equal 0 move the value in UCA0TXBUF to R4
    mov.b &UCA0RXBUF , R4
    ;retrieve R5's original value from the stack
    pop R5
    ;return
    ret



end:
    org 0xfffe
    dw start

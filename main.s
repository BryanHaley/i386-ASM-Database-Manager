#	FILENAME:	main.s
#	PURPOSE:	Handle user input for managing database.
#	AUTHOR:		Bryan Haley
#	DATE:		06/12/16

.equ	STDIN,		0
.equ	STDOUT,		1
.equ	SYS_CALL,	0x80
.equ	SYS_EXIT,	1
.equ	SYS_READ,	3
.equ	SYS_WRITE,	4

.section .data 

	option_string:
		.asciz "What would you like to do?\n1) Read next database entry.\n2) Create a new entry.\n3) Exit.\n\nChoice (1-2-3): "
	option_string_end:
		.equ option_string_len, option_string_end-option_string

	input_error_str:
		.asciz "\nError: Invalid input.\n\n"
	input_error_str_end:
		.equ input_error_str_len, input_error_str_end-input_error_str

	error_str:
		.asciz "\nAn unknown error has occured. Ending program.\n"
	error_str_end:
		.equ error_str_len, error_str_end-error_str

.section .bss

	.equ INPUT_BUFFER_SIZE, 4
	.lcomm INPUT_BUFFER, INPUT_BUFFER_SIZE

.section .text
.globl _start
_start:
	
	start_user_input:
	#write options to the console
	movl			$SYS_WRITE,				%eax
	movl			$STDOUT,				%ebx
	movl			$option_string,			%ecx
	movl			$option_string_len,		%edx
	int 			$SYS_CALL

	#get user input
	movl			$SYS_READ,				%eax
	movl			$STDIN,					%ebx
	movl			$INPUT_BUFFER,			%ecx
	movl			$INPUT_BUFFER_SIZE,		%edx
	int 			$SYS_CALL

	#check input and jump to appropiate code
	movl			$INPUT_BUFFER,			%eax
	subl			$'0',					%eax
	cmpl			$1,						%eax
	je				read_next
	jl				input_error
	cmpl			$2,						%eax
	je				create_record
	cmpl			$3,						%eax
	je				exit_prog
	jg				input_error

	read_next:
		jmp				start_user_input

	create_record:

	#If the input was invalid, just restart from the beginning.
	input_error:
	movl			$SYS_WRITE,				%eax
	movl			$STDOUT,				%ebx
	movl			$input_error_str,		%ecx
	movl			$input_error_str_len,	%edx
	int 			$SYS_CALL
	jmp				start_user_input

	#If any other errors occur, exit the program.
	general_error:
	movl			$SYS_WRITE,				%eax
	movl			$STDOUT,				%ebx
	movl			$error_str,				%ecx
	movl			$error_str_len,			%edx
	int 			$SYS_CALL
	jmp				exit_prog

	#exit
	exit_prog:
	movl			$SYS_EXIT,				%eax
	int 			$SYS_CALL

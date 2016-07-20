#	FILENAME:	main.s
#	PURPOSE:	Handle user input for managing database.
#	AUTHOR:		Bryan Haley
#	DATE:		06/12/16

#file descriptors for STDIN/STDOU
.equ STDIN, 0 #note to self: github doesn't like my tabs
.equ STDOUT, 1

#important system call numbers
.equ SYS_CALL, 0x80 #legacy i386
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ SYS_SEEK, 19

#define database entries
.equ ENTRY_SIZE, 80 #all entries are 80 characters long
.equ NAME_START, 0 #name starts at first character
.equ DOB_START, 51 #date of birth starts after 51st character
.equ SAL_START, 60 #so on
.equ DOE_START, 71

.equ DB_FILENM, 8 #database file name is given as a command-line argument
.equ DB_FILEDES, -4 #store the rw file descriptor here on the stack
.equ DB_FILEDES_RD, -8 #store the rd file descriptor here on the stack

#user input options
.equ OPT_READ, 1
.equ OPT_WRITE, 2
.equ OPT_QUIT, 3

.section .data 

	#define ascii strings for a simple user interface

	option_str:
		.ascii "\nWhat would you like to do?\n1) Read next database entry.\n2) Create a new entry.\n3) Exit.\n\nChoice (1-2-3): "
	option_str_end:
		.equ option_str_len, option_str_end-option_str

	input_error_str:
		.ascii "\nError: Invalid input.\n\n"
	input_error_str_end:
		.equ input_error_str_len, input_error_str_end-input_error_str

	error_str:
		.ascii "\nAn unknown error has occured. Ending program.\n"
	error_str_end:
		.equ error_str_len, error_str_end-error_str

	enter_name_str:
		.ascii "\nEnter a name (max 50 characters): "
	enter_name_end:
		.equ enter_name_len, enter_name_end-enter_name_str

	enter_dob_str:
		.ascii "Enter date of birth (MM/DD/YY): "
	enter_dob_end:
		.equ enter_dob_len, enter_dob_end-enter_dob_str

	enter_salary_str:
		.ascii "Enter salary: $"
	enter_salary_end:
		.equ enter_salary_len, enter_salary_end-enter_salary_str

	enter_doe_str:
		.ascii "Enter date of employment (MM/DD/YY): "
	enter_doe_end:
		.equ enter_doe_len, enter_doe_end-enter_doe_str

	record_written_str:
		.ascii "Record successfully written.\n"
	record_written_end:
		.equ record_written_len, record_written_end-record_written_str

.section .bss

	#buffer for reading from stdin and writing to the file
	.equ input_buffer_size, 80
	.lcomm input_buffer, input_buffer_size

	#buffer for reading from the file
	.equ read_buffer_size, 80
	.lcomm read_buffer, read_buffer_size

.section .text

#macros to easily read from STDIN and write to STDOUT
.macro print str, str_len
	movl $SYS_WRITE, %eax
	movl $STDOUT, 	%ebx
	movl $\str, 	%ecx
	movl $\str_len, %edx
	int $SYS_CALL
.endm

.macro readin buff, buff_size
	movl $SYS_READ, %eax
	movl $STDIN, %ebx
	movl $\buff, %ecx
	movl $\buff_size, %edx
	int $SYS_CALL
.endm

.globl _start
_start:
	
	#save stack pointer
	movl %esp, %ebp

	#open the file in append mode, create it if it doesn't exist, and open as 
	#write only
	movl $SYS_OPEN, %eax
	movl DB_FILENM(%ebp), %ebx
	movl $1089, %ecx
	movl $0666, %edx
	int $SYS_CALL

	#save the file descriptor on the stack at DB_FILEDES(%ebp)
	pushl %eax

	#get a separate file descriptor for reading so we can independently seek
	movl $SYS_OPEN, %eax
	movl DB_FILENM(%ebp), %ebx
	movl $0, %ecx
	movl $0666, %edx
	int $SYS_CALL

	#save the file descriptor on the stack at DB_FILEDES_RD(%ebp)
	pushl %eax

	start_user_input:

	#ask user for options
	print option_str, option_str_len

	#get user input
	readin input_buffer, input_buffer_size

	#check input and jump to appropiate label
	movb input_buffer, %al
	subl $'0', %eax #convert ascii character to number
	cmpl $OPT_READ,  %eax
	je read_next
	jl input_error #inputs less than 1 are not valid
	cmpl $OPT_WRITE,  %eax
	je create_record
	cmpl $OPT_QUIT,  %eax
	je exit_prog
	jg input_error #inputs greater than 3 are not valid

	#TODO: Put read and write into separate functions to demonstrate the C 
	#calling convention.

	#read the next record from the file
	read_next:
		movl $SYS_READ, %eax
		movl DB_FILEDES_RD(%ebp), %ebx
		movl $read_buffer, %ecx
		movl $read_buffer_size, %edx
		int $SYS_CALL

		#strings in the entries are terminated with line feeds, so it's 
		#presentable enough to print directly to the console
		#possible TODO: improve formatting before output
		print read_buffer, read_buffer_size

		#TODO: seek to the beginning of the file after the last record.

		#return to main menu once we're done
		jmp start_user_input

	create_record:
		
		#set ecx to zero for the loop
		xorl %ecx, %ecx

		#clear the input buffer so no junk is written
		clear_buff_loop:
			cmp $80, %ecx
			jge clear_buff_loop_end
			movb $0, %al
			movb %al, input_buffer(,%ecx,1)
			incl %ecx
			jmp clear_buff_loop

		clear_buff_loop_end:

		#get input from the user for the name, date of birth, salary, and 
		#date of employment. Place each string at fixed-length spots so that 
		#the data is randomly accessible.
		print enter_name_str, enter_name_len
		readin input_buffer, input_buffer_size
		print enter_dob_str, enter_dob_len
		readin input_buffer+DOB_START, input_buffer_size-DOB_START
		print enter_salary_str, enter_salary_len
		readin input_buffer+SAL_START, input_buffer_size-SAL_START
		print enter_doe_str, enter_doe_len
		readin input_buffer+DOE_START, input_buffer_size-DOE_START

		#write the buffer to the file
		movl $SYS_WRITE, %eax
		movl DB_FILEDES(%ebp), %ebx
		movl $input_buffer, %ecx
		movl $ENTRY_SIZE, %edx
		int $SYS_CALL

		#return to main menu
		jmp start_user_input

	#If the input was invalid, just restart from the beginning.
	input_error:
	print input_error_str, input_error_str_len
	jmp start_user_input

	#If any other errors occur, exit the program.
	general_error:
	print error_str, error_str_len
	jmp exit_prog

	#exit the program
	exit_prog:
	#close files
	movl $SYS_CLOSE, %eax
	movl DB_FILEDES(%ebp), %ebx
	int $SYS_CALL

	movl $SYS_CLOSE, %eax
	movl DB_FILEDES_RD(%ebp), %ebx
	int $SYS_CALL

	movl $SYS_EXIT, %eax
	int $SYS_CALL

#	FILENAME:	entry_handler.s
#	PURPOSE:	Handle reading and writing entries to a database file.
#	AUTHOR:		Bryan Haley
#	DATE:		06/11/16

.equ	ENTRY_SIZE,		80 		#Total length of entry.
.equ	NAME_SIZE,		51 		#Max length of a name in entry.
.equ	DOB_SIZE,		9 		#Text length of date of birth in entry.
.equ	SALARY_SIZE,	11		#Text length of salary in entry.
.equ	DOE_SIZE,		9		#Text length of date of employment in entry.

.equ	SYS_READ,		3		#Linux system call to read from a file.
.equ	SYS_WRITE,		3		#Linux system call to write to a file.
.equ	SYS_CALL,		0x80	#Interrupt number for system call (i386).

.section .text

	#FUNCTION:	READ_ENTRY 
	#PURPOSE:	Read a single entry from a file descriptor
	#			into a buffer.
	#INPUT:		1) A Linux file descriptor to read from.
	#			2) A buffer 80 bytes in size to read into.
	#OUTPUT:	The data is written to the provided buffer, and a status code 
	#			is provided in %eax.

	.equ	FILE_DESC, 		4 	#Location of the file descriptor on the stack.
	.equ 	BUFF_START, 	8 	#Location of the r/w buffer on the stack.

	.globl read_entry
	.type read_entry, @function
	read_entry:

		#create stack frame
		pushl			%ebp
		movl			%esp, 				%ebp

		#prepare for system read call
		movl			$SYS_READ, 			%eax
		movl			FILE_DESC(%ebp), 	%ebx
		movl			BUFF_START(%ebp), 	%ecx
		movl			$ENTRY_SIZE, 		%edx

		#call system
		int 			$SYS_CALL

		#The status code for the read from the system is already in eax, so
		#there's no need to return our own status code here. Simply return to 
		#the calling stack frame and end the function.
		movl			%ebp,				%esp
		popl			%ebp
		ret

	#FUNCTION:	WRITE_ENTRY
	#PURPOSE:	Write an entry of length 80 bytes to a provided file.
	#INPUT:		1) A Linux file descriptor to read to.
	#			2) A buffer of size 80 bytes to write with.			
	#			3) A name less than 50 characters in length. (ascii)
	#			4) A birth date 8 characters in length MM/DD/YY. (ascii)
	#			5) A salary less than 10 characters in length. (ascii)
	#			6) An employment date 8 characters in length MM/DD/YY (ascii)
	#OUTPUT:	The data in the buffer is written to the end of the provided 
	#			file, and a status code is returned to %eax.
	#NOTES:		Strings do not need to take up the max length, and should be
	#			null terminated. One extra character is alloted for the null
	#			terminator (e.g. a name can be 50 characters long + one null
	#			terminating character).

	#Location of important items on stack.
	.equ	FDES_STACK,			8
	.equ	BUFF_STACK, 		12
	.equ	NAME_STACK,			16
	.equ	DOB_STACK,			20
	.equ	SAL_STACK,			24
	.equ	DOE_STACK,			28

	#Intended locations of items in buffer.
	.equ	NAME_START,			0
	.equ	DOB_START,			51
	.equ	SAL_START,			60
	.equ	DOE_START,			71

	.globl write_entry
	.type write_entry, @function
	write_entry:

		#create stack frame
		pushl			%ebp
		movl			%esp,				%ebp

		#fill buffer with '\0' (can't assume it's empty)
		xorl			%ecx,				%ecx
		movl			$'\0',				%edx
		movl			BUFF_STACK(%ebp),	%ebx
		fill_loop:
			cmpl			$ENTRY_SIZE,		%ecx
			je				end_fill_loop
			movl			%edx,				(%ebx,%ecx,1)
			incl			%ecx
			jmp				fill_loop
		
		end_fill_loop: #continue function from here
		
		#load strings into buffer
		#buffer location is already in ebx
		xorl			%ecx,				%ecx
		movl			'\0',				%eax
		load_name:
			cmpl			%eax,						NAME_STACK(%ebp,%ecx,1)
			je				end_load_name
			movl			NAME_STACK(%ebp,%ecx,1),	%edx
			movl			%edx,						NAME_START(%ebx,%ecx,1)
			incl			%ecx
			jmp				load_name

			end_load_name:
				xorl			%ecx,				%ecx

		load_dob:
			cmpl			%eax,						DOB_STACK(%ebp,%ecx,1)
			je				end_load_dob
			movl			DOB_STACK(%ebp,%ecx,1),		%edx
			movl			%edx,						DOB_START(%ebx,%ecx,1)
			incl			%ecx
			jmp				load_dob

			end_load_dob:
				xorl			%ecx,				%ecx

		load_sal:
			cmpl			%eax,						SAL_STACK(%ebp,%ecx,1)
			je				end_load_sal
			movl			SAL_STACK(%ebp,%ecx,1),		%edx
			movl			%edx,						SAL_START(%ebx,%ecx,1)
			incl			%ecx
			jmp				load_sal

			end_load_sal:
				xorl			%ecx,				%ecx

		load_doe:
			cmpl			%eax,						DOE_STACK(%ebp,%ecx,1)
			je				end_load_sal
			movl			DOE_STACK(%ebp,%ecx,1),		%edx
			movl			%edx,						DOE_START(%ebx,%ecx,1)
			incl			%ecx
			jmp				load_sal

			end_load_doe:
				xorl			%ecx,				%ecx

		#write the buffer to the file
		movl			$SYS_WRITE,			%eax
		movl			FDES_STACK(%ebp),	%ebx
		movl			BUFF_STACK(%ebp),	%ecx
		movl			$ENTRY_SIZE,		%edx
		int 			$SYS_CALL

		#end the function
		movl			%ebp,				%esp
		popl			%ebp
		ret
	.section __TEXT,__cstring,cstring_literals
int.str:
	.string "%ld\0"
char.str:
	.string "%c\0"
true.str:
	.string "true"
false.str:
	.string "false"

	.data
Read_int: .quad

	.section __TEXT,__text,regular,pure_instructions


	.globl _main
_main:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp
	and $-32, %rsp
	push $3
	pop %rax
	mov %rax, -8(%rbp)
	push $6
	pop %rax
	mov %rax, -16(%rbp)
	mov $0, %rdi
	call _exit

RETURN: 
	mov %rbp, %rsp
	pop %rbp
	ret


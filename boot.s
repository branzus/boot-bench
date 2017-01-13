bits 16
org 0x7c00

%define PIT 0x46c		;address of timer increased by int8 in BDA
%define ITER 0x40000000		;iterations for CPU benchmark
%define MEMITER 0x100000	;iterations for Memory benchmark

	
jmp 0x0000:start 		;set cs to 0, ip to 7C00

start:
	sti			;make sure int 8 is enabled
	cdq
	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x700 		;setup

	mov cx, 14
	mov di, str_start
	call .bios_prstring 	;print "Computing..." so user knows it works


	mov eax, DWORD [PIT]
	mov [old_time], eax	
	
	call arith_test		;arithmetic test
	call jmp_test		;branch test
	
	mov eax, DWORD [PIT]
	sub eax, [old_time]
	
	mov di, str_cpu
	mov cx, 11
	call .bios_prstring	;write CPU Time:
	call .bios_print_dword	;write time

	mov di, newline
	mov cx,2
	call .bios_prstring	
	mov di, str_wri
	mov cx,11
	call .bios_prstring	;print mem write

	mov eax, DWORD [PIT]
	mov [old_time], eax

	call writetest		;call memory write test

	mov eax, DWORD [PIT]
	sub eax, [old_time]
	
	call .bios_print_dword
	mov di, newline	
	mov cx,2
	call .bios_prstring

	mov di, str_rea	
	mov cx,11		
	call .bios_prstring	;print mem read

	mov eax, DWORD [PIT]
	mov [old_time], eax
	
	call readtest		;call memory read test

	mov eax, DWORD [PIT]
	sub eax, [old_time]
	call .bios_print_dword
	
.halt:
	hlt			;halting loop
	jmp .halt


.bios_prstring:			;cx = size, di = address
	pusha
	xor bx, bx
	mov ah,0xe
.prloop:
	mov al, [di + bx]
	pusha
	int 10h
	popa
	inc bx
	cmp bx, cx
	jne .prloop

	popa
	ret

	
.bios_print_dword:		;eax = dword to print
	pusha
	mov esi, 7	
.filbuf:
	mov edi, eax		;filbuf with eax first
	shr eax, 4
	and di, 0xf
	mov bl, [hex_chars+di] 	;move equivalent hexchar to bx
	mov [str_buf+si], bl	;put hex char in buffer
	sub si, 1		
	jns .filbuf		;now str_buf has string version of

	mov ah, 0xe		;prepare for int 10
	xor bx, bx
	
.print_loop:
	pusha
	mov al, [str_buf+bx]
	int 10h
	popa	
	add bx, 1
	cmp bx, 8
	jb .print_loop

	popa
	ret

	
arith_test:			;arithmetic test for CPU
	mov ecx, ITER
	mov edx, 0x11854389
	mov eax, 0x2356221

.ariloop:
	add edx, eax
	sub edx, eax
	rol edx, 11
	sar edx, 4
	shl edx, 2
	not edx
	and edx, 0x38
	mul edx
	ror eax, 5
	add eax, edx
	or eax, edx
	neg eax
	dec ecx
	jne .ariloop
	ret


jmp_test:			;branch test for cpu
	mov ecx, ITER
	mov edx, 0x123456
	mov eax, 2
.first:
	add edx, -1
	js .third
	test ecx,0x400
	jne .fourth
.third:
	test edx, 0x1002
	je .fourth
.fourth:
	add eax,0x8000000
	test ecx, 0x1
	je .sixth
	jmp .fifth
.fifth:	
	cmp eax,0x80000000
	ja .sixth
	jmp .sixth
.sixth:
	dec ecx
	jne .first
	ret

writetest:			;writetest
	mov ebx, MEMITER
	mov ax, 0xffff
	mov di, 0x7e00
	mov cx, 0x4100
.wragain:
	push di
	push cx
	rep stosw
	pop cx
	pop di
	dec ebx
	jne .wragain	
	ret


readtest:			;readtest
	mov ebx, MEMITER
	mov si, 0x7e00
	mov cx, 0x4100
.readagain:
	push si
	push cx
	rep lodsw
	pop cx
	pop si	
	dec ebx
	jne .readagain
	ret
	

hex_chars db "0123456789ABCDEF"	;hex digits
old_time resd 1			
str_buf resb 8			;dword size in hexdigits
str_start db "Computing..."
newline db 0xd,0xa
str_cpu db "CPU Time:  "
str_wri db "Mem Write: "
str_rea db "Mem Read:  "
	
times 510-($-$$) db 0x90 	;fill remaing bytes with nops just cause
db 0x55, 0xaa
	

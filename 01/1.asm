; Advent Of Code 2023
; Works on DosBox 0.74-3
; Compile with "nasm.exe fileName.asm -fbin -o fileName.com"

org 100h

	mov ax, 3d00h ; open file
	push cs
	pop ds
	lea dx, fileName
	int 21h ; ax = file handle
	
	mov bx, ax
	push bx
	mov ax, 3f00h ; read from file handle
	xor cx, cx
	dec cx
	lea dx, buf
	int 21h ; ax = number of bytes read from file
	mov word[bytesRead], ax

	pop bx
	mov ah, 3eh ; close file
	int 21h

	lea si, buf
	xor bx, bx	; store the number on the current line
	xor ebp, ebp	; store the sum of all numbers

nextLine:
nextChar:
	lodsb
	cmp al, '0'
	jb notDigit
	cmp al, '9'
	ja notDigit
	sub al, '0'
	xor ah, ah
	jmp foundDigit
notDigit:
	jmp nextChar

foundDigit:
	mov di, ax ; store the first digit also as a last digit
	mov dx, 10
	mul dx
	mov bx, ax

nextDigit:
	lodsb
	cmp al, '0'
	jb notDigit2
	cmp al, '9'
	ja notDigit2
	sub al, '0'
	xor ah, ah

	mov di, ax ; store last digit in di, add it when we found the newline
	
notDigit2:	
	cmp al, 0x0d
	jne nextDigit
	lodsb ; skip 0x0a

	add bx, di ; add second digit
	
foundNextDigit:
	add bp, bx
		
checkEndOfFile:
	push bx
	mov bx, si
	sub bx, buf
	cmp bx, word[bytesRead]
	pop bx
	jae endOfFile

	jmp nextLine
endOfFile:


printResult:
	xor cx, cx ; cx = number of digits written to the buffer
	lea si, buf
	mov eax, ebp
	mov ebx, 10
printNextDigitToBuffer:
	xor edx, edx
	div ebx ; eax = quotient, edx = remainder
	push eax
	add dl, '0'
	mov [si], dl
	inc si
	inc cx
	pop eax
	test eax, eax
	jnz printNextDigitToBuffer

	dec si
printNextDigit:	
	mov ah, 02h
	mov dl, [si]
	int 21h
	dec si
	loop printNextDigit
	
	ret


fileName	db "input.txt"
bytesRead	dw 0

buf:

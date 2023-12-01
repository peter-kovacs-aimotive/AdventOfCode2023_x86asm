; Advent Of Code 2022
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

	call findDigit

	mov di, ax ; store the first digit also as a last digit
	mov dx, 10
	mul dx
	mov bx, ax

nextDigit:
	call findDigit
	jnc didNotFindMoreDigits
	mov di, ax ; store last digit in di, add it when we found the newline
	jmp nextDigit
didNotFindMoreDigits:	
	
	lodsb ; skip 0x0a

	add bx, di ; add second digit

	push bp
	mov bp, bx
	call printResult
	call printNewLine
	pop bp
	
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
	pusha

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
	
	popa
	
	ret


findDigit:
nextChar:
	xor cx, cx ; signal that we did not load extra bytes

	lodsb

	cmp al, '0'
	jb notDigit
	cmp al, '9'
	ja notDigit
	sub al, '0'
	xor ah, ah
	jmp foundDigit
notDigit:
	cmp al, 'o'
	jne notOne
	lodsb
	inc cx
	cmp al, 'n'
	jne notOne
	lodsb
	inc cx
	cmp al, 'e'
	jne notOne
	mov ax, 1 ; found a 'one'
	jmp foundDigit
notOne:
	cmp al, 't'
	jne notTwoOrThree
	lodsb
	inc cx
	cmp al, 'w'
	jne notTwo
	lodsb
	inc cx
	cmp al, 'o'
	jne notTwoOrThree
	mov ax, 2 ; found a 'two'
	jmp foundDigit
notTwo:
	cmp al, 'h'
	jne notTwoOrThree
	lodsb
	inc cx
	cmp al, 'r'
	jne notTwoOrThree
	lodsb
	inc cx
	cmp al, 'e'
	jne notTwoOrThree
	lodsb
	inc cx
	cmp al, 'e'
	jne notTwoOrThree
	mov ax, 3 ; found a 'three'
	jmp foundDigit
notTwoOrThree:
	cmp al, 'f'
	jne notFourOrFive
	lodsb
	inc cx
	cmp al, 'o'
	jne notFour
	lodsb
	inc cx
	cmp al, 'u'
	jne notFourOrFive
	lodsb
	inc cx
	cmp al, 'r'
	jne notFourOrFive
	mov ax, 4 ; found a 'four'
	jmp foundDigit
notFour:
	cmp al, 'i'
	jne notFourOrFive
	lodsb
	inc cx
	cmp al, 'v'
	jne notFourOrFive
	lodsb
	inc cx
	cmp al, 'e'
	jne notFourOrFive
	mov ax, 5 ; found a 'five'
	jmp foundDigit
notFourOrFive:
	cmp al, 's'
	jne notSixOrSeven
	lodsb
	inc cx
	cmp al, 'i'
	jne notSix
	lodsb
	inc cx
	cmp al, 'x'
	jne notSixOrSeven
	mov ax, 6
	jmp foundDigit
notSix:
	cmp al, 'e'
	jne notSixOrSeven
	lodsb
	inc cx
	cmp al, 'v'
	jne notSixOrSeven
	lodsb
	inc cx
	cmp al, 'e'
	jne notSixOrSeven
	lodsb
	inc cx
	cmp al, 'n'
	jne notSixOrSeven
	mov ax, 7
	jmp foundDigit
notSixOrSeven:
	cmp al, 'e'
	jne notEight
	lodsb
	inc cx
	cmp al, 'i'
	jne notEight
	lodsb
	inc cx
	cmp al, 'g'
	jne notEight
	lodsb
	inc cx
	cmp al, 'h'
	jne notEight
	lodsb
	inc cx
	cmp al, 't'
	jne notEight
	mov ax, 8
	jmp foundDigit
notEight:
	cmp al, 'n'
	jne notNine
	lodsb
	inc cx
	cmp al, 'i'
	jne notNine
	lodsb
	inc cx
	cmp al, 'n'
	jne notNine
	lodsb
	inc cx
	cmp al, 'e'
	jne notNine
	mov ax, 9
	jmp foundDigit
notNine:
	cmp al, 0x0d
	je foundEndOfLine

	sub si, cx ; backtrack any extra bytes

	jmp nextChar
foundDigit:
	sub si, cx ; we have to backtrack even if we found a digit, due to eightwo
	
	stc ; signal that we found a digit
	ret

foundEndOfLine:
	xor ax, ax
	clc
	ret


printNewLine:
	push ax
	push dx
	
	mov ah, 02h
	mov dl, 10
	int 21h

	mov ah, 02h
	mov dl, 13
	int 21h
	
	pop dx
	pop ax
	
	ret

fileName	db "input.txt"
bytesRead	dw 0

buf:

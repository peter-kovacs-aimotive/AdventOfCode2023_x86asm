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

	xor ebp, ebp	; store the sum of all numbers

	mov cx, word[matrixHeight]
nextLine:
	push cx
	mov cx, word[matrixWidth]
	mov word[startOfLine], si

nextChar:
	call scanNumber
	
	test ebx, ebx
	jz notaNumber
	mov ebp, eax
	push eax
	call printResult
	call printSpace
	mov ebp, ebx
	call printResult

	; check surroundings for non-whitespace characters
	mov byte[hasPartAround], 0
	mov di, si ; back up the position after the string

	sub si, bx
	dec si
	sub si, word[stride] ; we now point to the upper left diagonal character	
	mov cx, bx
	add cx, 2
	call checkLineForParts

	mov si, di
	sub si, bx
	dec si ; we point to the character before the number
	mov cx, 1
	call checkLineForParts
	
	mov si, di
	mov cx, 1 ; we point to the character after the number
	call checkLineForParts

	mov si, di
	sub si, bx
	dec si
	add si, word[stride] ; we now point to the lower left diagonal character	
	mov cx, bx
	add cx, 2
	call checkLineForParts

	pop eax

	cmp byte[hasPartAround], 1
	jne doesNotHavePartAround

	call printSpace
	mov dl, '*'
	call printChar
	
	add dword[sumOfAllNumbers], eax
	
doesNotHavePartAround:
	call printNewLine


	mov si, di ; restore position

	jmp checkEndOfLine
notaNumber:
	inc si
checkEndOfLine:	
	mov ax, si
	sub ax, word[startOfLine]
	cmp ax, word[matrixWidth]
	jne nextChar
	
	pop cx
	add si, 2
	
	dec cx
	test cx, cx
	jnz nextLine
	
	mov ebp, dword[sumOfAllNumbers]
	call printResult

	ret

; in: cx=number of chars to check
;     si=start char to check 
; out: hasPartAround is set to 1 if found a non-whitespace char
checkLineForParts:
	lodsb
	cmp si, buf
	jl doNotCheck
	
	push si
	sub si, buf
	cmp si, word[bufSize]
	pop si
	ja doNotCheck

	cmp al, '.'
	je whiteSpace
	cmp al, 0x0a
	je whiteSpace
	cmp al, 0x0d
	je whiteSpace
notWhiteSpace:	
	mov byte[hasPartAround], 1
doNotCheck:
whiteSpace:
	loop checkLineForParts
	ret
	

printResult:
	pusha

	xor cx, cx ; cx = number of digits written to the buffer
	lea si, printBuf
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

printSpace:
	push ax
	push dx
	
	mov ah, 02h
	mov dl, ' '
	int 21h
	
	pop dx
	pop ax
	
	ret


; in: dl=char to print
printChar:
	push ax
	push dx
	
	mov ah, 02h
	int 21h
	
	pop dx
	pop ax
	
	ret


; in: si=pointer to number
; out: eax = number
;      ebx = number of digits
scanNumber:
newNumber:
	push edx
	push ecx
	push ebp
	
	xor ebx, ebx ; actual number
	xor ecx, ecx ; sign
	xor ebp, ebp ; number of digits
newDigit:	
	lodsb
		
	;cmp al, '-'
	;je negative
	cmp al, '0'
	jb notDigit
	cmp al, '9'
	ja notDigit
	sub al, '0'
	inc ebp
	xor ah, ah
	push ax

	mov eax, ebx
	mov ebx, 10
	mul ebx ; eax = eax*10
	mov ebx, eax
	xor eax,eax
	pop ax
	add ebx, eax
	jmp newDigit
negative:
	mov ecx, 1
	jmp newDigit
notDigit:
	cmp ecx, 0
	je positive
	neg ebx
positive:
	mov eax, ebx
	mov ebx, ebp
	
	pop ebp
	pop ecx
	pop edx
	dec si
	ret


;fileName	db "test.txt", 0
;matrixWidth		dw 10
;matrixHeight	dw 10
;stride			dw 12
;bufSize			dw 10 * 12

fileName	db "input.txt", 0
matrixWidth		dw 140
matrixHeight	dw 140
stride			dw 142
bufSize			dw 140 * 142

bytesRead	dw 0
startOfLine		dw 0
hasPartAround	db 0

sumOfAllNumbers	dd 0

printBuf resb 256

buf:

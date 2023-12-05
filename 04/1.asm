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

	mov cx, word[numLines]
nextLine:
	push cx
	add si, word[numCardCols] ; skip 'Card X: '
	push ds
	pop es
	lea di, winningNumbers
	
	mov cx, word[numberOfWinningNumbers]
scanWinningNumbers:
	call scanNumber
	stosw
	loop scanWinningNumbers

	add si, 3 ; skip ' |'
	
	mov cx, word[numberOfMyNumbers]
	xor ebp, ebp ; point from the current game
scanMyNumbers:
	call scanNumber
	lea di, winningNumbers
	push cx
	mov cx, word[numberOfWinningNumbers]
scanWinningNumbers2:
	mov bx, es:[di]
	cmp ax, bx
	jnz numberDidNotWin
	test bp, bp
	jnz pointNotZero
	mov ebp, 1
	jmp endPointCalculation
pointNotZero:	
	shl ebp, 1
numberDidNotWin:
endPointCalculation:
	add di, 2
	loop scanWinningNumbers2
	pop cx
	loop scanMyNumbers
	add dword[totalNumberOfPoints], ebp
	
	add si, 2 ; skip newline
	
	pop cx
	loop nextLine
	
	mov ebp, dword[totalNumberOfPoints]
	call printResult
	
	ret
	

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


; in: si=pointer to number
; out: eax = number
scanNumber:
newNumber:
	push ebx
	push edx
	push ecx
	push es
	push di
	
	; skip trailing spaces silently
	mov al, ' '
	xor cx, cx
	dec cx
	push ds
	pop es
	push si
	pop di
	repe scasb
	mov si, di
	dec si

	xor ebx, ebx ; actual number
	xor ecx, ecx ; sign

newDigit:	
	lodsb		
	cmp al, '-'
	je negative
	cmp al, '0'
	jb notDigit
	cmp al, '9'
	ja notDigit
	sub al, '0'
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
	
	pop di
	pop es
	pop ecx
	pop edx
	pop ebx
	dec si
	ret


;fileName	db "test.txt", 0
;numberOfWinningNumbers	dw 5
;numberOfMyNumbers		dw 8
;numCardCols				dw 8 ; number of characters to skip before the first winning number
;numLines				dw 6

fileName	db "input.txt", 0
numberOfWinningNumbers	dw 10
numberOfMyNumbers		dw 25
numCardCols				dw 10 ; number of characters to skip before the first winning number
numLines				dw 192


winningNumbers	resw 256

bytesRead	dw 0

totalNumberOfPoints	dd 0

buf:

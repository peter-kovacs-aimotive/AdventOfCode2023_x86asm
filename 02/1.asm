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

nextLine:
	add si, 5 ; skip 'Game '
	call scanNumber
	mov dword[gameID], eax
	add si, 2 ; skip ': '

	mov dword[isGamePossible], 1

nextSet:
	mov dword[numberOfRed], 0
	mov dword[numberOfGreen], 0
	mov dword[numberOfBlue], 0
	
nextColor:
	call scanNumber
	mov ebx, eax ; ebx is the number 
	
	inc si ; skip ' '
	lodsb
	cmp al, 'r'
	je red
	cmp al, 'g'
	je green
	cmp al, 'b'
	je blue
	jmp unknownColor
	
red:
	mov dword[numberOfRed], ebx
	add si, 2 ; skip 'ed'
	jmp checkNextToken
green:
	mov dword[numberOfGreen], ebx
	add si, 4 ; skip 'reen'
	jmp checkNextToken
blue:
	mov dword[numberOfBlue], ebx
	add si, 3 ; skip 'lue'
	jmp checkNextToken
unknownColor:	
	hlt

checkNextToken:	
	lodsb
	inc si ; skip ' ' or 0x0a
	cmp al, ','
	je nextColor
	cmp al, ';'
	je checkSet
	cmp al, 0x0d
	je checkSet
	hlt

checkSet:
	cmp dword[numberOfRed], 12
	jg notPossible
	cmp dword[numberOfGreen], 13
	jg notPossible
	cmp dword[numberOfBlue], 14
	jg notPossible
possible:
;	mov ebp, dword[gameID]
;	call printResult
;	call printNewLine
	jmp checkNextChar
notPossible:
	mov dword[isGamePossible], 0
checkNextChar:
	cmp al, ';'
	je nextSet
	cmp al, 0x0d
	je endOfLine
	hlt

endOfLine:

	cmp dword[isGamePossible], 1
	jne checkEndOfFile
	mov ebp, dword[gameID]
	add dword[sumOfGameIDs], ebp
	call printResult
	call printNewLine
	
	
checkEndOfFile:
	push bx
	mov bx, si
	sub bx, buf
	cmp bx, word[bytesRead]
	pop bx
	jae endOfFile

	jmp nextLine
endOfFile:

	mov ebp, dword[sumOfGameIDs]
	call printResult
	call printNewLine

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

; in: si=pointer to number
; out: eax = number
scanNumber:
newNumber:
	push ebx
	push edx
	push ecx
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
	pop ecx
	pop edx
	pop ebx
	dec si
	ret


fileName	db "input.txt"
bytesRead	dw 0

gameID		dd 0
isGamePossible	dd 0
numberOfRed	dd 0
numberOfGreen	dd 0
numberOfBlue	dd 0
sumOfGameIDs	dd 0

buf:

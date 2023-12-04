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

	push 0b000h ; zero out segment 0b000h, which will be used for storing the values of the numbers found
	pop es
	xor di, di
	xor cx, cx
	dec cx
	xor al, al
	rep stosb
	push es
	pop fs

	push 0a000h ; zero out segment 0a000h, which will be used for storing the sequence number of the numbers found
	pop es
	xor di, di
	xor cx, cx
	dec cx
	xor al, al
	rep stosb

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

	push eax
	push eax
	
	;mov ebp, eax
	;call printResult
	;call printSpace
	;mov ebp, ebx
	;call printResult

	mov di, si
	sub di, bx
	shl di, 1
	mov ax, word[sequenceNumber]
	mov cx, bx
	rep stosw
	
	; store numbers as words in 0xb000 segment
	mov di, word[sequenceNumber]
	shl di, 1 
	pop eax
	mov fs:[di], ax
	
	inc word[sequenceNumber]

	pop eax
	
	;call printNewLine

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
	
	; scan for '*'
	lea si, buf
	mov cx, word[bufSize]
findNextStar:	
	lodsb
	cmp al, '*'
	je foundStar
	loop findNextStar
	jmp doneFindingStars

foundStar:
	call emptySequenceNumberSet
	
	dec si ; point to '*' again

	mov di, si
	sub di, word[stride]
	dec di
	shl di, 1
	mov ax, es:[di]
	call storeSequenceNumberInSet
	add di, 2
	mov ax, es:[di]
	call storeSequenceNumberInSet
	add di, 2
	mov ax, es:[di]
	call storeSequenceNumberInSet
	
	mov di, si
	dec di
	shl di, 1
	mov ax, es:[di]
	call storeSequenceNumberInSet
	add di, 4
	mov ax, es:[di]
	call storeSequenceNumberInSet
	
	mov di, si
	add di, word[stride]
	dec di
	shl di, 1
	mov ax, es:[di]
	call storeSequenceNumberInSet
	add di, 2
	mov ax, es:[di]
	call storeSequenceNumberInSet
	add di, 2
	mov ax, es:[di]
	call storeSequenceNumberInSet

	inc si ; point to char after '*' again

	; check that we have exactly two sequence numbers in the set
	cmp word[sequenceNumbersAdjacent], 0
	jz notExactlyTwoEntries
	cmp word[sequenceNumbersAdjacent + 2], 0
	jz notExactlyTwoEntries
	cmp word[sequenceNumbersAdjacent + 4], 0
	jnz notExactlyTwoEntries
	
	; grab the two numbers and multiply them
	xor eax, eax
	mov di, word[sequenceNumbersAdjacent]
	shl di, 1
	mov ax, fs:[di]
	
	xor ebp, ebp
	mov bp, ax
	call printResult
	mov dl, ' '
	call printChar
	
	mov di, word[sequenceNumbersAdjacent + 2]
	shl di, 1
	xor edx, edx
	mov dx, fs:[di]
	
	xor ebp, ebp
	mov bp, dx
	call printResult
	call printNewLine
	
	mul edx
	add dword[sumOfAllNumbers], eax
notExactlyTwoEntries:	

	dec cx
	jnz findNextStar
	;loop findNextStar
doneFindingStars:

	mov ebp, dword[sumOfAllNumbers]
	call printResult

	ret


; in: ax=sequence number to store
; out: none
storeSequenceNumberInSet:	
	pusha

	cmp ax, 0
	je endStoreSequenceNumberInSet

	lea si, sequenceNumbersAdjacent
tryNextSlot:
	mov bx, [si]
	cmp bx, 0 ; found an empty slot
	jne notEmptySlot
	mov [si], ax
	jmp storedSequenceNumberInSet
notEmptySlot:	
	cmp bx, ax
	je storedSequenceNumberInSet ; already stored earlier
	add si, 2
	jmp tryNextSlot
storedSequenceNumberInSet:
endStoreSequenceNumberInSet:
	popa 
	ret

; in: none
; out: none
emptySequenceNumberSet:
	pusha
	lea si, sequenceNumbersAdjacent
	mov cx, 10
	xor ax, ax
emptyNextSlot:
	mov ds:[si], ax
	add si, 2
	loop emptyNextSlot
	popa
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

sequenceNumber	dw 1

sequenceNumbersAdjacent resw 10

printBuf resb 256

buf:

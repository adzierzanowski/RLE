org 100h

start:
	mov dx, info
	call printstr
	
	menu:
		; clear strings 
		mov bx, input
		call wipe
		mov bx, output
		call wipe
		
		; reset input char counter
		mov [inputlen], word 0
		
		mov dx, menutxt
		call printstr
		
		mov ah, 0
		int 16h
		
		cmp al, "c"
		je cls
		
		cmp al, "q"
		je exit
		
		cmp al, "e"
		je encode
		
		mov dx, errmsg1
		call printstr
		
		jmp menu
		
	cls:
		; clear screen
		mov ax, 3
		int 10h
		jmp menu
		
	encode:
		; encode
		mov dx, msg1
		call printstr
		
		getstr:
			mov dx, msg2
			call printstr
		
			mov ax, 1000
			sub ax, [inputlen]
			call printnum

			mov dx, msg6
			call printstr
		
			mov dx, msg5
			call printstr
			
			mov dx, buffer
			mov ah, 10
			int 21h

			call movbuf

			cmp [inputlen], word 1000
			jg error3
			
			mov dx, msg4
			mov ah, 9
			int 21h
			
			mov ah, 0
			int 16h
			
			cmp al, "y"
			je getstr
		
		mov dx, newline
		call printstr
		
		mov dx, msg5
		call printstr
		
		mov dx, input
		call printstr

		call rle
		
		mov dx, output
		call printstr
		
		mov dx, newline
		call printstr
		
		jmp menu
		
		error3:
			mov dx, errmsg3
			call printstr
			jmp menu
	
	exit:
		; quit the program
		mov dx, exitmsg
		call printstr
	
		mov ax, 4c00h
		int 21h

char     db    0
lastflag db    0
buffer   db    255, 0
         times 256  db '$'
input    times 1001 db '$'
inputlen dw    0
output   times 2000 db '$'

menutxt  db    10, 13, "Menu:"
         db    10, 13, "    e - encode a string"
         db    10, 13, "    c - clear screen"
	     db    10, 13, "    q - quit", 10, 13, ">>> $"

msg1     db    "Encode a string.$"
msg2     db    10, 13, 10, 13, "Write your string [$"
msg3     db    "<<< $"
msg4     db    10, 13, "Do you want to write more chars? [y/n]$"
msg5     db    10, 13, ">>> $"
msg6     db    " characters left]: $"

errmsg1  db    "Not a valid option. Please repeat..", 10, 13, 36
errmsg2  db    "Error: empty input.", 10, 13, 36
errmsg3  db    ">>> Error: Maximum input length exceeded.", 10, 13, 36

exitmsg  db    "Bye.", 10, 13, 36
		
info     db    10, 13, "Run-Length Encoding$"
	 
newline  db    10, 13, 36
	 
printstr:
	; prints a string at DX
	push ax
	mov ah, 9
	int 21h
	pop ax
	ret
	
rle:
	; encodes input and writes to output
	
	; BX = char occurence counter
	xor bx, bx
	
	mov cx, [inputlen]
	
	inc cx
	
	cmp cx, 1
	je rleerr1

	mov dx, newline
	mov ah, 9
	int 21h
	
	xor si, si
	xor di, di
	
	mov al, [input + si]
	mov [char], al
	
	run:
		mov al, [input + si]
		cmp al, [char]
		
		jne newchar
		
		inc bx
		jmp endrun
		
		newchar:
			push ax
			push cx
			
			xor cx, cx
			mov ax, bx
			getcount:
				xor dx, dx
				mov bx, 10
				div bx

				push dx
				inc cx
				
				cmp ax, 0
				jne getcount
			
			putcount:
				pop dx
				
				add dl, 48
				mov [output + di], dl
				
				inc di
				loop putcount
				
			mov al, [char]
			mov [output + di], al
			inc di
			
			pop cx
			pop ax
			
			mov [char], al
			mov bx, 1
		
		endrun:
			inc si
			loop run
	
	mov dx, msg3
	mov ah, 9
	int 21h
	
	jmp endrle
	
	rleerr1:
		mov dx, errmsg2
		mov ah, 9
		int 21h
	
	endrle:
		ret
		
wipe:
	; clears the string at BX

	xor di, di
	mov al, 36

	wipenext:
		cmp [bx + di], al
		je endwipe
	
	mov [bx + di], al
	inc di
	jmp wipenext
	
	endwipe:
		ret
		
movbuf:
	; appends buffer to input var
	
	xor ch, ch
	mov cl, [buffer + 1]
	push cx
	
	mov si, buffer
	add si, 2
	mov bx, [inputlen]
	
	mov di, input
	add di, bx
	
	rep movsb	

	pop cx
	add [inputlen], cx
	
	ret
	
printnum:
	; prints the decimal value of AX
	
	xor cx, cx

	getnum:
		xor dx, dx
		mov bx, 10
		div bx

		push dx
		inc cx
		
		cmp ax, 0
		jne getnum
			
	putnum:
		pop dx
		
		add dl, 48
		mov ah, 2
		int 21h
		
		loop putnum
		
	ret

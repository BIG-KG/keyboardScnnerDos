.model tiny
.code 
.186
org 100h


main proc

	mov ax, 00              ;zero segment -> es
    mov es, ax
    mov bx, 08h * 4         ; calculate 09h interraption location in memory
    mov ax, es:[bx]
    mov Delta, ax
    mov ax, es:[bx + 2]  
    mov segm,  ax   

    cli
    mov es:[bx], offset DrawRegisterRamk ; New9hInterrupt -> 09h 
    mov ax, cs
    mov es:[bx + 2], ax
    sti

    mov ax, 3100h
    mov dx, offset endProg
    shr dx, 4
    inc dx
    int 21h

endp main


DrawRegisterRamk proc


	push dx		;|
	push cx		;|saving regs to load after interrupt 
	push bx		;|
	push ax		;|
	push bp		;|
	push di		;|
	push es		;|

	mov cs:SaveRegValue, 	 ax ;|saving regs to wright in rsmk
	mov cs:SaveRegValue + 2, bx ;|
	mov cs:SaveRegValue + 4, cx ;|


	;mov al,      218
	;mov oneLine , al
	;mov al,      196
	;mov oneLine + 1 , al
	;mov al,      191
	;mov oneLine + 2, al
	;mov al,      179
	;mov oneLine + 3, al
	;mov al,      0
	;mov oneLine + 4, al
	;mov al,      179
	;mov oneLine + 5, al
	;mov al,      192
	;mov oneLine + 6, al
	;mov al,      196
	;mov oneLine + 7, al
	;mov al,      217
	;mov oneLine + 8, al






	xor bp, bp	
	mov ax, 	0				;ramk parametrs
	mov bx, 	2
	mov cx, 	10
	mov dx,		6
	mov di, 	offset oneLine	

	call draw_ramk

	call writRegisters

	pop es		;|
	pop di		;|reload registers after interrapt
	pop bp		;|
	pop ax		;|
	pop bx		;|
	pop cx		;|
	pop dx		;|



OurJmp   db 0eah
Delta    dw 0
segm     dw 0

ZXstring		db "ZX $"

SaveRegValue	dw  0,  0,   0,   0
TranslatedNum	db  0, 	0,	 0,   0,   24h
oneLine     	db  218, 196, 191, 179, 0, 179, 192, 196, 217


;------------------------------
;	Wright 		AX, BX, CX, DX registers
;	INPUT:		AX, BX, CX, DX
;	OUNPUT: 	TranslatedNum:
;	DESTR:    
;------------------------------
writRegisters proc

	xor bx, bx

	wrightReg:

	;wrighting AX string
	add	bl,       'A'
	mov cs:ZXstring, bl
	sub bl,       'A'
	push bx
	mov ax,		2
	add bx, 	3
	mov di, 	offset ZXstring
	call wrightSign
	pop bx

	;wrighting AX value
	shl  bx, 	1
	add  bx,    offset SaveRegValue
	mov  ax, 	cs:[bx]
	sub  bx, 	offset SaveRegValue 
	shr  bx,	1
	push bx
	call registerToBytes
	mov  ax,	5
	add  bx, 	3
	mov  di, 	offset TranslatedNum
	call wrightSign
	pop bx

	inc bx
	cmp bx, 3
	jne wrightReg

	ret

endp

registerToBytes proc

	push ax
	push bx
	push di

	mov  di, offset TranslatedNum
	add  di, 3


	StartTranslate:
	mov	 bl, 	01111b
	and  bl, 	al

	cmp  bl, 	10
	jge  hexPart

	add bl,		'0'
	mov cs:[di],	bl
	jmp EndOfNumberCheck


	hexPart:
	sub  bl, 	10
	add  bl,	'A'
	mov  cs:[di],	bl 

	EndOfNumberCheck:
	shr ax, 	4
	dec di
	cmp di, 	offset TranslatedNum	
	jge StartTranslate		

	pop di
	pop bx
	pop ax

	ret
registerToBytes endp

; ax - xleft
; bx - yleft
; cx - xleft
; dx - yleft
; di - sourese of mode




draw_ramk:
	push bx; start draw window

	push bx
	push dx
	push cx
	call Drawline
	pop  cx
	pop  dx
	pop  bx

	add di, 3
	jmp checkLineNum
	
    drawCurrLine:
	push dx
	push cx
	push bx
	call Drawline
	pop  bx
	pop  cx
	pop  dx
		
    checkLineNum:
	inc bx
	
	cmp bx, dx
	jl drawCurrLine
	
	add di, 3
	push dx
	push cx
	push bx
	call Drawline
	pop  bx
	pop  cx
	pop  dx

	pop bx

	ret
	
;===========================================
;  Write to videomem, source - di
;
;  Entery: AX - oX, BX - oY, Di - sign data sourse
;  Exit  : None
;  Destr : AX, BX, CX, ES, DI
;===========================================
wrightSign:

	push ax
	push bx
	push cx

	; Target part of videomem(abx) = (bx * 80 + ax) *2
	imul bx, 80		; bx *= 80
	add  bx, ax		; bx += ax                           
	shl  bx, 1		; bx = (bx * 80 + ax) * 2

	mov  ax, 0b800h	; videosegment -> es
	mov  es, ax

	jmp testWrightSign


	CopySign:
	mov es:[bx], cl	
	add bx, 	 2
	inc di

	testWrightSign:
	mov cl,		 cs:[di]
	cmp cl,      '$'
	jne CopySign

	pop cx
	pop bx
	pop ax

	ret



;===========================================
;  
;
;  Entery: AX - oX, BX - oY, Bi - frameData
;  Exit  : None
;  Destr : AX, BX, CX, DX, ES 
;===========================================


Drawline proc

	push dx
	push bx

	mov  dx, 0b800h; di - symbol sourse
	mov  es, dx
	mov  dx, bx
	imul bx, 80;bx - current copyng symbol
	add  bx, ax
	imul bx, 2

	imul dx, 80; dx - max copying symbol
	add  dx, cx
	imul dx, 2

	mov cl, 	 cs:[di]
	mov es:[bx], cl

	mov cl, 	cs:[di + 1]	

	jmp Check
	
    Do:
	mov es:[bx], cl
	
		
    Check:
	add bx,		2
	cmp dx, 	bx
	jg  Do

	mov cl, 	cs:[di + 2]
	mov es:[bx], cl
	add bx,		2

	pop bx
	pop dx
	
	ret
	
	endp



endProg:
end main
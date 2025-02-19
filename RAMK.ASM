.model tiny
.code 
.186
org 100h


.data
ZXstring		db "ZX $"

TranslatedNum	db  0, 	0,	 0,   0,   24h
oneLine     	db  218, 196, 191, 179, 0, 179, 192, 196, 217

.code

;------------------------------
;	Translete number to hex sign
;	INPUT:		AX - translating number
;	OUNPUT: 	TranslatedNum:
;	DESTR:    
;------------------------------

main proc

	xor bp, bp	
	mov ax, 	0				;ramk parametrs
	mov bx, 	2
	mov cx, 	10
	mov dx,		6
	mov di, 	offset oneLine	

	call draw_ramk
	mov ax, 	0FFFFh
	mov bx,		0h
	call writRegisters

	mov ax, 4c00h
	int 21h

	mov di, 	offset oneLine

	ret

main endp

;------------------------------
;	Wright 		AX, BX, CX, DX registers
;	INPUT:		AX, BX, CX, DX
;	OUNPUT: 	TranslatedNum:
;	DESTR:    
;------------------------------
writRegisters proc

	push cx
	push bx
	push ax

	;wrighting AX string
	mov ZXstring, 'A'
	mov ax,		2
	mov bx, 	3
	mov di, 	offset ZXstring
	call wrightSign

	;wrighting AX value
	pop ax
	call registerToBytes
	mov  ax,	5
	mov  bx, 	3
	mov  di, 	offset TranslatedNum
	call wrightSign

;=======================================

	;wrighting BX string
	mov ZXstring, 'B'
	mov ax,		2
	mov bx, 	4
	mov di, 	offset ZXstring
	call wrightSign

	;wrighting BX value
	pop ax	
	call registerToBytes
	mov  ax,	5
	mov  bx, 	4
	mov  di, 	offset TranslatedNum
	call wrightSign

;=======================================

	;wrighting CX string
	mov ZXstring, 'C'
	mov ax,		2
	mov bx, 	5
	mov di, 	offset ZXstring
	call wrightSign

	;wrighting CX value
	pop ax	
	call registerToBytes
	mov  ax,	5
	mov  bx, 	5
	mov  di, 	offset TranslatedNum
	call wrightSign


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
	mov [di],	bl
	jmp EndOfNumberCheck


	hexPart:
	sub  bl, 	10
	add  bl,	'A'
	mov  [di],	bl 

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
;  Destr : AX, BX, CX ES, DI
;===========================================
wrightSign:

	push ax
	push bx

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
	mov cl,		 [di]
	cmp cl,      '$'
	jne CopySign

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

	mov cl, 	[di]
	mov es:[bx], cl

	mov cl, 	[di + 1]	

	jmp Check
	
    Do:
	mov es:[bx], cl
	
		
    Check:
	add bx,		2
	cmp dx, 	bx
	jg  Do

	mov cl, 	[di + 2]
	mov es:[bx], cl
	add bx,		2

	pop bx
	pop dx
	
	ret
	
	endp

end main
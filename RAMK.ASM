.model tiny
.code 
.186
org 100h
locals

xStart equ 0
yStart equ 2
xSize  equ 11
ySize  equ 6


main proc

	mov ax, 00              ;zero segment -> es
    mov es, ax
    mov bx, 08h * 4         ; calculate 09h interruption location in memory
    mov ax, es:[bx]
    mov Delta08, ax
    mov ax, es:[bx + 2]  
    mov segm08,  ax   

    cli
    mov es:[bx], offset New08HInterrapt ; New9hInterrupt -> 09h 
    mov ax, cs
    mov es:[bx + 2], ax
    sti
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	mov bx, 09h * 4         ; calculate 09h interraption location in memory
    mov ax, es:[bx]
    mov Delta09, ax
    mov ax, es:[bx + 2]  
    mov segm09,  ax   

    cli
    mov es:[bx], offset new09HINterrapt ; New9hInterrupt -> 09h 
    mov ax, cs
    mov es:[bx + 2], ax
    sti


    mov ax, 3100h
    mov dx, offset endProg
    shr dx, 4
    inc dx
    int 21h

endp main





;=======================================
; 	Info   : line lenth 11x6 from buffer si to vmem coord di 
;	Entery : SI - start of the drawing array; DI - start in vmem
;	Destroy: AX, CX, ES, DI, SI
;	Output : None
;=======================================
DrawFromBuffer proc

	push 0b800h
	pop  es

	cld

	mov ax, ySize		 ;set oY counter

	@@Do:	
	mov cx, xSize		 ;set oX counter
	repnz movsw

	sub di, xSize * 2	 ;go to the start of column
	add di, 160          ;go to the next string
	dec ax
	jnz  @@Do
	ret

DrawFromBuffer endp

;=======================================
; 	Info   : line lenth 11x6 from VMEMcoord si to mem start di 
;	Entery : DI - start of the drawing array; SI - start in vmem
;	Destroy: AX, CX, DI, SI, DS, ES
;	Output : None
;=======================================
SaveTobuffer proc

	push cs
	pop  es

	push 0b800h
	pop  ds

	cld

	mov ax, ySize					;set oY counter				

	@@Do:
	mov cx, xSize					;set oX counter
	repnz movsw 

	sub si, xSize * 2				;go to the start of column
	add si, 160						;go to the next string
	dec ax
	jnz  @@Do
	ret

SaveTobuffer endp 
;=======================================
; 	Info   : compare second buffer and vmem delta go to first buffer 
;	Entery : DI - start of vmem, SI - start of second, 
;			 BX - delta betwen firs and secod buff( &second - &first)
			 
;	Destroy: AX, CX, DX, 
;	Output : None
;=======================================
compareVmemBuff proc

	push 0b800h
	pop  es
	cld

	mov  dx, ySize						;set oY counter

	@@startline:
	mov  cx, xSize						;set oX counter

	@@compareSimb:
	cmpsw							;compare pixel from buf2 & vmem
	je @@equlal	

	mov ax, 		 es:[di - 2]		;|if it differ -> save difference to buf1
	sub si,          bx				;|				
	mov ds:[si - 2], ax				;|
	add si,   		 bx				;|

	@@equlal:
	dec cx							
	jnz @@compareSimb

	sub di,          xSize*2			;go to th start of next line
	add di,          160

	dec dx
	jnz @@startline
	ret
compareVmemBuff endp


new09HINterrapt proc

	push ax         ;   save ax, es
    push es  
    push bx 


    in  al, 60h          ; 60h port -> al -> es:[bx] videoSeg bx coord
    mov bl, cs:PreviousKey; check previos key, if is not 'I' => not need to change
	cmp bl, 17h
	jne SaveCurrenKey

	cmp al, 18h				;if currKey = 'O' => goto turning on
	je  TurnOn	
	cmp al, 21h				;if currKey = 'O' => goto turning ons	
	je  TurnOff
	jmp SaveCurrenKey

	TurnOff:
	mov bl, 0
	cmp bl, cs:NeedTodrawRamkFlag
	je  SaveCurrenKey
	mov bl, 1
	mov cs:NeedTodrawRamkFlag, bl
	jmp SaveCurrenKey

	TurnOn:
	mov bl, 2
	cmp bl, cs:NeedTodrawRamkFlag
	je  SaveCurrenKey
	mov bl, 3
	mov cs:NeedTodrawRamkFlag, bl

	SaveCurrenKey:
	mov cs:PreviousKey, al


	pop bx
	pop es
	pop ax


OurJmp09   db 0eah
Delta09    dw 0
segm09     dw 0


New08HInterrapt proc

	push dx		;|
	mov  dl, cs:NeedTodrawRamkFlag
	cmp  dl, 0			;If not need to save ramk -> not save any other registers
	jne  @@DrawRamk
	jmp  cs:@@NOdrawingRamk
	@@DrawRamk:

	push cx		;|saving regs to load after interrupt 
	push bx		;|
	push ax		;|
	push bp		;|
	push di		;|
	push es		;|
	push ds		;|
	push si

	push cs
	pop  ds

	cmp  dl, 1
	je   @@endOfDrawing
	cmp  dl, 3
	je   @@savecurrentVmem

	@@noTsaveVmem:

	mov cs:SaveRegValue, 	 ax ;|saving regs to wright in rsmk
	mov cs:SaveRegValue + 2, bx ;|
	mov cs:SaveRegValue + 4, cx ;|
	mov cs:SaveRegValue + 6, dx ;|

	mov  di, (xStart + yStart * 80)* 2	;di - start of vmem
	mov  si, offset secondBuffer 
	mov  bx, offset secondBuffer 		;bx - difference betwen buffers addres
	sub  bx, offset firstBuffer
	call compareVmemBuff


	xor bp, 	bp	
	mov ax, 	xStart				;ramk parametrs
	mov bx, 	yStart
	mov cx, 	(xSize + xStart - 1)
	mov dx,		(ySize + yStart - 1)
	mov di, 	offset oneLine	

	call draw_ramk

	call writRegisters


	mov  si, (xStart + yStart * 80)* 2  ;If need to start draw(3)
	mov  di, offset secondBuffer
	push ds 
	push es
	call SaveTobuffer
	pop  es
	pop  ds
	jmp @@startOfEndPoping


	@@savecurrentVmem:
	mov  si, (xStart + yStart * 80)* 2					;If need to start draw(3)
	mov  di, offset firstBuffer
	push ds 
	push es
	call SaveTobuffer
	pop  es
	pop  ds
	mov  dl,  2
	mov NeedTodrawRamkFlag, dl
	jmp @@startOfEndPoping




	@@endOfDrawing:
	mov  di, 2
	imul di, 160
	mov  si, offset firstBuffer
	call DrawFromBuffer
	mov dl,  0
	mov NeedTodrawRamkFlag, dl
	

	@@startOfEndPoping:
	pop si
	pop ds		;|
	pop es		;|
	pop di		;|reload registers after interrapt
	pop bp		;|
	pop ax		;|
	pop bx		;|
	pop cx		;|
	@@NOdrawingRamk:
	pop dx		;|



OurJmp08   db 0eah
Delta08  dw 0
segm08   dw 0

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
	cmp bx, 4
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

	push ax
	push bx
	push dx
	push di
	call Drawline
	pop  di
	pop  dx
	pop  bx
	pop  ax

	add di, 3
	jmp checkLineNum
	
    drawCurrLine:
	push ax
	push bx
	push dx
	push di
	call Drawline
	pop  di
	pop  dx
	pop  bx
	pop  ax
		
    checkLineNum:
	inc bx
	
	cmp bx, dx
	jl drawCurrLine
	
	add di, 3
	push ax
	push bx
	push dx
	push di
	call Drawline
	pop  di
	pop  dx
	pop  bx
	pop  ax

	pop bx

	ret
	
;===========================================
;  Write to videomem, source - di
;
;  Entery: AX - oX, BX - oY, Di - sign data sourse
;  Exit  : None
;  Destr : AX, BX, CX, ES, DI, DS
;===========================================
wrightSign:

	push ax
	push bx
	push di
	push si
	push ds

	; Target part of videomem(abx) = (bx * 80 + ax) *2
	imul bx, 80		; bx *= 80
	add  bx, ax		; bx += ax                           
	shl  bx, 1		; bx = (bx * 80 + ax) * 2

	mov  ax, cs
	mov  ds, ax 

	mov  ax, 0b800h	; videosegment -> es
	mov  es, ax

	mov ah, 7
	mov si, di
	mov di, bx
	cld

	jmp testWrightSign


	CopySign:
	stosw

	testWrightSign:
	lodsb
	cmp al,      '$'
	jne CopySign

	pop ds
	pop si
	pop di
	pop bx
	pop ax

	ret



;===========================================
;  
;
;  Entery: AX - oX, BX - oY, Bi - frameData
;  Exit  : None
;  Destr : AX, BX, DX, SI, ES 
;===========================================


Drawline proc
	push es
	push si
	mov  si, di

	mov  dx, 0b800h; di - symbol sourse
	mov  es, dx

	mov  dx, bx
	imul bx, 80;bx - current copyng symbol
	add  bx, ax
	imul bx, 2

	mov  di, bx  

	imul dx, 80; dx - max copying symbol
	add  dx, cx
	imul dx, 2

	mov  ah, 7

	mov al, 	 cs:[si]
	mov es:[di], ax
	add di, 2

	mov al, 	 cs:[si + 1]	

	jmp Check
	
    Do:
	stosw
	
		
    Check:
	cmp dx, 	di
	jg  Do

	mov al, 	cs:[si + 2]
	mov es:[di], ax

	pop si
	pop es
	ret
	
	endp

.data

firstBuffer     dw 66 DUP (0000011100000001b);
secondBuffer    dw 66 DUP (0); 

ZXstring		db "ZX $"
NeedTodrawRamkFlag db 0
PreviousKey db  3

SaveRegValue	dw  0,  0,   0,   0
TranslatedNum	db  0, 	0,	 0,   0,   24h
oneLine     	db  218, 196, 191, 179, 0, 179, 192, 196, 217

endProg:
end main
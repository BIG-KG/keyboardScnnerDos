.model tiny
.code 
.186
org 100h

.data


.code

main proc


    mov ax, 00              ;zero segment -> es
    mov es, ax
    mov bx, 09h * 4         ; calculate 09h interraption location in memory
    mov ax, es:[bx]
    mov Delta, ax
    mov ax, es:[bx + 2]  
    mov segm,  ax   

    cli
    mov es:[bx], offset New9hInterrupt ; New9hInterrupt -> 09h 
    mov ax, cs
    mov es:[bx + 2], ax
    sti

    mov ax, 3100h
    mov dx, offset endProg
    shr dx, 4
    inc dx
    int 21h

    endp


New9hInterrupt proc
    push ax         ;   save ax, es
    push es  
    push bx 

    mov ax, 0b800h      ;   videoseg -> es
    mov es, ax

    mov bx, 4 * 80 * 2  ;   target drawing Position -> bx
    add bx, 4 * 2

    in al, 60h          ; 60h port -> al -> es:[bx] videoSeg bx coord
    mov es:[bx], al

    ;in al, 61h          ;blink tokeyboard port 
    ;mov ah, al          ;\
    ;or al, 80h          ;\
    ;out 61h, al         ;\
    ;xchg ah, al         ;\
    ;out 61h, al         ;\
    ;mov al, 20h         ;\
    ;out 20h, al         ;\

    pop bx              ;return bx, es, ax to state before programm start
    pop es
    pop ax


    

OurJmp   db 0eah
Delta    dw 0
segm     dw 0













endProg:

end main
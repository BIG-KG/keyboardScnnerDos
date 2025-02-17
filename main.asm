.model tiny
.code 
.186
org 100h

.data


.code

main: proc

    mov ax, 00
    mov es, ax
    mov bx, 09h * 4
    mov es:[bx], offset New9hInterrupt


New9hInterrupt: proc

    mov ax, 


    endp

                


end main
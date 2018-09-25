testA20:
   pusha
   mov ax, [0x7dfe]
   mov dx, ax
   call printh	
   push bx
   mov bx, 0xffff
   mov es, bx
   pop bx

   mov bx, 0x7e0e
   mov dx, [es:bx]

   cmp ax, dx
   je .cont
   
   popa
   mov ax, 1
   ret

   .cont:
      mov ax, [0x7dff]
      mov dx, ax
      push bx
      mov bx, 0xffff
      mov es, bx
      pop bx
      mov bx, 0x7e0f
      mov dx, [es: bx]
      cmp ax, dx
      je .exit
      popa
      mov ax, 1
      ret

   .exit:
      popa
      ret

enableA20:
   pusha 

   ;BIOS METHOD OF ENABLING A20 LINE
   mov ax, 0x2401
   int 0x15
   call testA20
   cmp ax, 1
   je .done
   ret 


   ;KEYBOARD METHOD OF ENABLING A20 LINE
   cli
   call waitC
   mov al, 0xad
   out 0x64, al

   call waitC
   mov al, 0xd0
   out 0x64, al

   call waitD
   in al, 0x60		;read port on keyboard
   push ax
   
   call waitC
   mov al, 0xd1		;sending data
   out 0x64, al

   call waitC
   pop ax
   or al, 2
   out 0x60, al

   call waitC
   mov al, 0xae 	;enable keyboard
   out 0x64, al

   call waitC
   sti
   call testA20
   cmp ax, 1
   je .done
   ret

   
   ;CHIPSET METHOD OF ENABLING A20 LINE
   in al, 0x92
   or al, 2
   out 0x92, al
   call testA20
   cmp al, 1
   je .done
   ret

   .done:
      popa
      ret

waitC:
   in al, 0x64
   test al, 2
   jnz waitC
   ret

waitD:
   in al, 0x64
   test al, 1
   jz waitD
   ret

checklong:
   pusha
   pushfd		;push eflag register to stack
   pop eax		;pop eax
   mov ecx, eax		

   xor eax, 1 << 21 	;if the 21st bit is not 1, make 1
   
   push eax
   popfd

   pushfd
   pop eax

   xor eax, ecx		;compare flipped and original
   jz .done
   
   mov eax, 0x80000000	
   cpuid
   cmp eax, 0x80000001
   jb .done

   mov eax, 0x80000001
   cpuid
   test edx, 1 << 29
   jz .done
   mov si, YES_LM
   call printf
   popa 
   ret

   .done:
      popa
      mov si, NO_LM
      call printf
      jmp $

NO_LM: db "CPU does not support long mode.", 0x0a, 0x0d, 0
YES_LM: db "CPU DOES support long mode." , 0x0a, 0x0d, 0

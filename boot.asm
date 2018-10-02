[org 0x7C00]		 ;Set memory start space
[bits 16]

section .data

section .bss

section .text
   global main

main:

cli			 ;disable interupts
jmp 0x0000:ZeroSeg	 ;go to start of memory to begin
ZeroSeg:
   xor ax, ax		 ;set ax to 0
   mov ss, ax
   mov ds, ax
   mov es, ax
   mov fs, ax
   mov gs, ax
   mov sp, main		 ;move stack pointer to main
   cld			 ;clear direction flag
   sti			 ;re-enable interupts 

push ax			 ;move ax to the stack
xor ax, ax		 ;clear ax
mov dl, 0x80		 ;set for HDD
int 0x13		 ;reset disk, just in case
pop ax			 ;reset ax
mov si, WELCOME_ST	 ;move string to SI register
call printf		 ;print string
call readDisk		 ;read sector 2 from disk


call enableA20
jmp sec2
jmp $			 ;infinite loop

%include "print.asm"
%include "a20.asm"

readDisk:		 ;read disk function
   pusha		 ;push all registers to stack
   mov ah, 0x02	  	 ;set register to read from drive
   mov dl, 0x80          ;set for HDD (80).  FDD is 00
   mov ch, 0             ;first cylinder
   mov dh, 0             ;first head
   mov al, 1             ;read 1 sector only
   mov cl, 2	  	 ;read 2nd sector
   push bx		 ;push bx to stack
   mov bx, 0		 ;set bx to 0
   mov es, bx            ;mov bx to es
   pop bx                ;restore bx from stack
   mov bx, 0x7c00 + 512  ;set memory location as boot location, plus 512
   int 0x13		 ;BIOS interrup for reading from disk
   jc disk_err	 	 ;if error, goto error function
   mov si, DISK_SUCCESS
   call printf
   popa			 ;restore all from stack
   ret			 ;return to normal function

disk_err:		 ;disk error function
   mov si, DISK_ERR_MSG  ;load disk error message
   call printf
   jmp $       		 ;infinite loop

DISK_ERR_MSG: db "Error reading from disk", 0x0a, 0x0d, 0 ;disk error message
DISK_SUCCESS: db "Success reading from disk", 0x0a, 0x0d, 0 ;disk success
WELCOME_ST: db "Aaron Liske's OS Project", 0x0a, 0x0d, 0 ;string and new line
times 510-($-$$) db 0	 ;padding for proper boot sector size
dw 0xaa55		 ;boot sector 'magic' number
%include "longmode.asm"
%include "gdt.asm"
TEST_STR: db "Reading Code in 2nd Sector", 0x0a, 0x0d, 0 ;confirmation of 2nd sector load
sec2:
   call checklong	 ;see if CPU can support long mode.  If not, end.	
   
   cli
   
   mov edi, 0x1000  	 ;set location for paging
   mov cr3, edi
   xor eax, eax		 ;clear out eax
   mov ecx, 4096	 ;set counter register
   rep stosd		 ;keep looping until all memory for paging is clear
   mov edi, 0x1000	 ;reset location
   
			 ;Page map level 4 table at 0x1000
			 ;Page directory pointer at 0x2000
			 ;Page directory table at 0x3000
                         ;Page table 0x4000
   mov dword [edi], 0x2003	;set up structure pointers
   add edi, 0x1000
   mov dword [edi], 0x3003
   add edi, 0x1000
   mov dword [edi], 0x4003
   add edi, 0x1000

   mov dword ebx, 3	 ;map first 2MB
   mov ecx, 512
   
   .setEntry:
      mov dword [edi], ebx
      add ebx, 0x1000
      add edi, 8
      loop .setEntry
   mov eax, cr4
   or eax, 1 << 5 	 ;set 5th bit of cr4
   mov cr4, eax		 ;inform processor of PAE

   mov ecx, 0xc0000080
   rdmsr		 ;IA32 EFER Enable long mode
   or eax, 1 << 8
   wrmsr

   mov eax, cr0		 ;get control register 0
   or eax, 1 << 31	 ;enable paging
   or eax, 1 << 0	 ;enable protected mode
   mov cr0, eax          ;put bits 0 and 31 back, enabled

   lgdt[GDT.Pointer]
   jmp GDT.Code:LongMode
   [bits 64]
   LongMode:
      VID_MEM equ 0xb8000
      ;mov edi, VID_MEM
      ;mov rax, 0x2f202f202f202f20
      ;mov ecx, 500
      ;rep stosq
	  [EXTERN __printf]
      hlt

times 512 db 0

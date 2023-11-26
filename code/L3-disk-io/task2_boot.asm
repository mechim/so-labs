org 7c00h            ; Set the origin of the code to memory address 7c00h

mov     ah, 00       ; Set up AH register for BIOS Reset Disk System
int     13h          ; Call BIOS interrupt 13h to reset the disk system

mov     ax, 0000h    ; Set AX register to 0000h
mov     es, ax       ; Set ES (Extra Segment) register to the value in AX
mov     bx, 7e00h    ; Set BX register to memory address 7e00h

mov     ah, 02h      ; Set up AH register for BIOS Read Sector
mov     al, 4        ; Set AL register to 4 sectors to read
mov     ch, 0        ; Set CH register to 0 (cylinder number)
mov     cl, 2        ; Set CL register to 2 (starting sector number)
mov     dh, 0        ; Set DH register to 0 (head number)
mov     dl, 0        ; Set DL register to 0 (drive number)
int     13h          ; Call BIOS interrupt 13h to read sectors

jmp     0000h:7e00h  ; Jump to the memory address specified (for program execution)

times 510-($-$$) db 0   ; Fill the remaining space up to 510 bytes with zeros
dw 0AA55h              ; Add the boot signature at the end of the boot sector


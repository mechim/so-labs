org 7c00h                ; Set the origin of the code to memory address 7c00h

section .data
    to_write_str    dd "@@@FAF-211 Arteom KALAMAGHIN###" ; Define a string to write
    to_write_len    equ $ - to_write_str - 1            ; Calculate the length of the string

    first_track     equ 28      ; Define track numbers for writing to disk
    first_sector    equ 8       ; Define sector numbers for writing to disk

    last_track      equ 30      ; Define track numbers for reading from disk
    last_sector     equ 1       ; Define sector numbers for reading from disk

section .bss
    in_buffer       resb 512    ; Reserve memory for an input buffer
    out_buffer      resb 512    ; Reserve memory for an output buffer

section .text
    global          _start      ; Entry point for the program

_start:
    write:
        mov     di, in_buffer       ; Set di to point to the input buffer

        mov     cx, 11              ; Initialize cx register for loop iteration
        push    cx                  ; Push the value of cx onto the stack
        fill_buffer:
            pop     cx              ; Pop the value of cx from the stack
            dec     cx              ; Decrement cx
            jz      zeros           ; Jump to zeros if cx is zero

            push    cx              ; Push cx onto the stack

            mov     si, to_write_str ; Set si to point to the string to write
            mov     cx, to_write_len ; Set cx to the length of the string

            jmp     copy_string_to_buffer ; Jump to copy_string_to_buffer label

            zeros:
                push    di          ; Push di onto the stack
                sub     di, in_buffer ; Calculate the offset in the buffer

                cmp     di, 512     ; Compare di with buffer size
                je      write_to_disk ; Jump to write_to_disk if the buffer is full

                pop     di          ; Pop di from the stack
                mov     byte [di], 30h ; Store '0' character in the buffer
                inc     di          ; Increment di
                jmp     zeros       ; Jump back to zeros

copy_string_to_buffer:
    mov     al, [si]             ; Move the byte from [si] into al
    mov     [di], al             ; Move the byte in al to [di]

    inc     si                    ; Increment si
    inc     di                    ; Increment di

    dec     cx                    ; Decrement cx
    jnz     copy_string_to_buffer ; Jump back if cx is not zero

    jmp     fill_buffer           ; Jump back to fill_buffer label

write_to_disk:
    mov     ax, 0            ; Set AX register to 0
    mov     es, ax           ; Set ES (Extra Segment) register to the value in AX
    mov     bx, in_buffer    ; Set BX register to the memory address of in_buffer

    mov     ah, 03h          ; Set up AH register for BIOS Write Sector
    mov     al, 1            ; Set AL register to 1 sector to write
    mov     ch, first_track  ; Set CH register to first_track (cylinder number)
    mov     cl, first_sector ; Set CL register to first_sector (starting sector number)
    mov     dh, 0            ; Set DH register to 0 (head number)
    mov     dl, 0            ; Set DL register to 0 (drive number)

    int     13h              ; Call BIOS interrupt 13h to write sectors to disk
    jc      io_error          ; Jump to io_error label if carry flag is set (indicating an error)

    mov     ax, 0            ; Reset AX register to 0
    mov     es, ax           ; Reset ES register to 0 (clears ES)
    mov     bx, in_buffer    ; Set BX register to the memory address of in_buffer (possibly redundant)

    mov     ah, 03h          ; Set up AH register for another BIOS Write Sector
    mov     al, 1            ; Set AL register to 1 sector to write
    mov     ch, last_track   ; Set CH register to last_track (cylinder number)
    mov     cl, last_sector  ; Set CL register to last_sector (starting sector number)
    mov     dh, 0            ; Set DH register to 0 (head number)
    mov     dl, 0            ; Set DL register to 0 (drive number)

    int     13h              ; Call BIOS interrupt 13h to write sectors to disk
    jc      io_error          ; Jump to io_error label if carry flag is set (indicating an error)

    jmp     read_from_disk   ; Jump to the read_from_disk section to read from disk

read_from_disk:
    mov     ax, 0            ; Set AX register to 0
    mov     es, ax           ; Set ES register to 0 (clears ES)
    mov     bx, out_buffer   ; Set BX register to the memory address of out_buffer

    mov     ah, 02h          ; Set up AH register for BIOS Read Sector
    mov     al, 1            ; Set AL register to 1 sector to read
    mov     ch, first_track  ; Set CH register to first_track (cylinder number)
    mov     cl, first_sector ; Set CL register to first_sector (starting sector number)
    mov     dh, 0            ; Set DH register to 0 (head number)
    mov     dl, 0            ; Set DL register to 0 (drive number)

    int     13h              ; Call BIOS interrupt 13h to read sectors from disk
    jc      io_error          ; Jump to io_error label if carry flag is set (indicating an error)

    jmp     print_buffer     ; Jump to the print_buffer section to print the buffer

io_error:
    ; Push ASCII values for the string "ERROR" in reverse order
    push    52h     ; R
    push    4fh     ; O
    push    52h     ; R
    push    52h     ; R
    push    45h     ; E

    mov     cx, 5     ; Set loop counter to 5
    print_error:
        mov     ah, 0eh  ; Set up AH register for BIOS teletype output
        pop     bx       ; Pop a character from the stack into BX
        mov     al, bl   ; Move the character to AL register for output
        int     10h      ; Call BIOS interrupt 10h to print the character

        dec     cx       ; Decrement loop counter
        jnz     print_error ; Jump to print_error if CX is not zero

    jmp     _end        ; Jump to _end label to end the program

print_buffer:
    mov     bh, 0       ; Set BH register to 0
    mov     dh, 0       ; Set DH register to 0
    mov     dl, 0       ; Set DL register to 0

    mov     ax, 0       ; Clear AX register
    mov     es, ax      ; Set ES (Extra Segment) register to 0
    mov     bp, out_buffer  ; Set BP register to the memory address of out_buffer
    mov     bl, 07h     ; Set BL register to display attribute (color)
    mov     cx, 512     ; Set CX register to the size of the buffer (512 bytes)

    mov     ax, 1301h   ; Set up AH for BIOS video scroll function
    int     10h         ; Call BIOS interrupt 10h to scroll the screen

_end:

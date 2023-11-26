org 7e00h                   ; Set the origin of the code to memory address 7e00h

section .text
    global _start           ; Entry point for the program

_start:
    call    reset_memory    ; Call the function to reset memory
    xor     sp, sp          ; Clear the stack pointer

    ; print options listing string

    call    get_cursor_pos  ; Call function to get cursor position

    mov     ax, 0           ; Set AX register to 0
    mov     es, ax          ; Set ES (Extra Segment) register to 0
    mov     bp, opt_str     ; Set BP register to point to opt_str (options listing string)

    mov     bl, 07h         ; Set BL register for display attribute (color)
    mov     cx, opt_len     ; Set CX register to opt_len (length of the options string)

    mov     ax, 1301h       ; Set up AH for BIOS video scroll function
    int     10h             ; Call BIOS interrupt 10h to display the options

    mov     ah, 0eh         ; Set up AH register for BIOS teletype output
    mov     al, 3ah         ; Set AL register to ASCII character ':'
    int     10h             ; Print the character

    mov     al, 20h         ; Set AL register to ASCII character ' '
    int     10h             ; Print a space character

    ; read user's choice

    mov     ah, 00h         ; Set AH register for BIOS keyboard input function
    int     16h             ; Call BIOS interrupt 16h to read a character from keyboard

    ; execute chosen operation

    cmp     al, '1'         ; Compare the entered character with '1'
    je      option1         ; Jump to label 'option1' if equal

    cmp     al, '2'         ; Compare the entered character with '2'
    je      option2         ; Jump to label 'option2' if equal

    cmp     al, '3'         ; Compare the entered character with '3'
    je      option3         ; Jump to label 'option3' if equal

    jmp     _error          ; Jump to label '_error' if none of the options match

; 2.1 BEGINNING

option1:
    ; display the key read

    mov     ah, 0eh       ; Set up AH register for BIOS teletype output
    int     10h           ; Print the character in AL (previously read)

    mov     al, 2eh       ; Set AL register to ASCII character '.'
    int     10h           ; Print the character

    ; print "STRING = "

    call    get_cursor_pos ; Call function to get cursor position

    inc     dh            ; Increment DH (row position)
    mov     dl, 0         ; Set DL (column position) to 0

    mov     ax, 0         ; Set AX register to 0
    mov     es, ax        ; Set ES (Extra Segment) register to 0
    mov     bp, in_awaits_str1  ; Set BP register to point to in_awaits_str1

    mov     bl, 07h       ; Set BL register for display attribute (color)
    mov     cx, str1_awaits_len1 ; Set CX register to str1_awaits_len1 (length of the string)

    mov     ax, 1301h     ; Set up AH for BIOS video scroll function
    int     10h           ; Call BIOS interrupt 10h to display "STRING = "

    ; read user input (str)

    call    read_input    ; Call function to read user input

    ; save the string to its own buffer

    mov     si, storage_buffer ; Set SI to point to storage_buffer
    mov     di, string    ; Set DI to point to string buffer

    char_copy_loop:
         mov     al, [si]        ; Move the byte from address pointed by SI to AL
         mov     [di], al        ; Move the byte in AL to the address pointed by DI
         inc     si              ; Increment SI
         inc     di              ; Increment DI

         cmp     byte [si], 0    ; Compare the byte at SI with 0 (end of string marker)
         jne     char_copy_loop  ; Jump back to char_copy_loop if not end of string

         ; print "N = "

         call    get_cursor_pos  ; Get cursor position

         inc     dh              ; Increment DH (row position)
         mov     dl, 0           ; Set DL (column position) to 0

         mov     ax, 0           ; Set AX register to 0
         mov     es, ax          ; Set ES (Extra Segment) register to 0
         mov     si, in_awaits_str1 ; Set SI to point to in_awaits_str1
         add     si, str1_awaits_len1 ; Point SI to the end of in_awaits_str1
         mov     bp, si          ; Set BP to point to the end of in_awaits_str1

         mov     bl, 07h         ; Set BL register for display attribute (color)
         mov     cx, str1_awaits_len2 ; Set CX register to str1_awaits_len2 (length of the string)

         mov     ax, 1301h       ; Set up AH for BIOS video scroll function
         int     10h             ; Call BIOS interrupt 10h to print "N = "

         ; read user input (n)

         call    read_input      ; Call function to read user input

         ; convert ascii read to an integer

         mov     di, nhts        ; Set DI to point to nhts
         mov     si, storage_buffer ; Set SI to point to storage_buffer
         call    atoi            ; Convert ASCII characters to integer

         ; read HTS

         call    read_hts_address ; Call function to read HTS address

         ; prepare writing buffer

         mov     si, string      ; Set SI to point to string
         call    fill_storage_buffer ; Call function to fill storage buffer

         ; calculate the number of sectors to write

         xor     dx, dx          ; Clear DX register
         mov     ax, [storage_curr_size] ; Move value from storage_curr_size to AX
         mov     bx, 512         ; Set BX to 512 (sector size)
         div     bx              ; Divide AX by BX, quotient in AX, remainder in DX

         ; write to the floppy

         push    ax              ; Save AX on the stack

         mov     ax, 0           ; Clear AX register
	 mov     es, ax          ; Set ES register to 0 (clears ES)
   	 mov     bx, storage_buffer ; Set BX to point to storage_buffer

    	 pop     ax              ; Restore AX from the stack

    	 mov     ah, 03h         ; Set up AH register for BIOS Write Sector
	 inc     al              ; Increment AL
    	 mov     ch, [nhts + 4] ; Set CH to nhts + 4
   	 mov     cl, [nhts + 6] ; Set CL to nhts + 6
   	 mov     dh, [nhts + 2] ; Set DH to nhts + 2
 	 mov     dl, 0           ; Set DL to 0

    	 int     13h             ; Call BIOS interrupt 13h to write sectors

   	    ; print error code
    
    call    display_error_code

    ; print string read

    mov     si, string     ; Set SI to point to string
    call    print_buff 

    jmp     _terminate

; 2.2 BEGINNING

option2:
    ; display the key read

    mov     ah, 0eh       ; Set up AH register for BIOS teletype output
    int     10h           ; Print the character in AL (previously read)

    mov     al, 2eh       ; Set AL register to ASCII character '.'
    int     10h           ; Print the character

    ; read RAM address XXXX:YYYY "

    call    read_ram_address  ; Call function to read RAM address

    ; read HTS

    call    read_hts_address  ; Call function to read HTS address

    ; print "N = "

    call    get_cursor_pos    ; Get cursor position

    inc     dh              ; Increment DH (row position)
    mov     dl, 0           ; Set DL (column position) to 0

    mov     ax, 0           ; Set AX register to 0
    mov     es, ax          ; Set ES (Extra Segment) register to 0
    mov     si, in_awaits_str1 ; Set SI to point to in_awaits_str1
    add     si, str1_awaits_len1 ; Point SI to the end of in_awaits_str1
    mov     bp, si          ; Set BP to point to the end of in_awaits_str1

    mov     bl, 07h         ; Set BL register for display attribute (color)
    mov     cx, str1_awaits_len2 ; Set CX register to str1_awaits_len2 (length of the string)

    mov     ax, 1301h       ; Set up AH for BIOS video scroll function
    int     10h             ; Call BIOS interrupt 10h to print "N = "

    ; read user input (n)

    call    read_input      ; Call function to read user input

    ; convert ascii read to an integer

    mov     di, nhts        ; Set DI to point to nhts
    mov     si, storage_buffer ; Set SI to point to storage_buffer
    call    atoi            ; Convert ASCII characters to integer

    ; read data from floppy

    mov     es, [address]  ; Set ES to the value stored at [address]
    mov     bx, [address + 2] ; Set BX to the value stored at [address + 2]

    mov     ah, 02h        ; Set up AH for BIOS Read Sector
    mov     al, [nhts]     ; Set AL to value at nhts
    mov     ch, [nhts + 4] ; Set CH to value at nhts + 4
    mov     cl, [nhts + 6] ; Set CL to value at nhts + 6
    mov     dh, [nhts + 2] ; Set DH to value at nhts + 2
    mov     dl, 0          ; Set DL to 0 (drive number)

    int     13h            ; Call BIOS interrupt 13h to read sectors

    ; print error code
    
    call    display_error_code

    ; print the data read

    call    get_cursor_pos   ; Get cursor position

    inc     dh              ; Increment DH (row position)
    mov     dl, 0           ; Set DL (column position) to 0

    mov     es, [address]
    mov     bp, [address + 2]

    mov     bl, 07h
    mov     cx, 512

    mov     ax, 1301h
    int     10h

    ; call    paginated_output

    jmp     _terminate      ; Jump to _terminate label to end the program

; 2.3 BEGINNING

option3:
    ; display the key read

    mov     ah, 0eh       ; Set up AH register for BIOS teletype output
    int     10h           ; Print the character in AL (previously read)

    mov     al, 2eh       ; Set AL register to ASCII character '.'
    int     10h           ; Print the character

    ; read RAM address XXXX:YYYY "

    call    read_ram_address  ; Call function to read RAM address

    ; read HTS

    call    read_hts_address  ; Call function to read HTS address

    ; print "N = "

    call    get_cursor_pos    ; Get cursor position

    inc     dh              ; Increment DH (row position)
    mov     dl, 0           ; Set DL (column position) to 0

    mov     ax, 0           ; Set AX register to 0
    mov     es, ax          ; Set ES (Extra Segment) register to 0
    mov     si, in_awaits_str1 ; Set SI to point to in_awaits_str1
    add     si, str1_awaits_len1 ; Point SI to the end of in_awaits_str1
    mov     bp, si          ; Set BP to point to the end of in_awaits_str1

    mov     bl, 07h         ; Set BL register for display attribute (color)
    mov     cx, str1_awaits_len2 ; Set CX register to str1_awaits_len2 (length of the string)

    mov     ax, 1301h       ; Set up AH for BIOS video scroll function
    int     10h             ; Call BIOS interrupt 10h to print "N = "

    ; read user input (n)

    call    read_input      ; Call function to read user input

    ; convert ascii read to an integer

    mov     di, nhts        ; Set DI to point to nhts
    mov     si, storage_buffer ; Set SI to point to storage_buffer
    call    atoi            ; Convert ASCII characters to integer
    
     ; print the data to write

    call    get_cursor_pos  ; Call a routine to get the current cursor position

    inc     dh              ; Increment the value in DH (row position) to move the cursor down by one row
    mov     dl, 0           ; Move the column position (DL) to the beginning (column 0)

    mov     es, [address]   ; Load the segment part of the memory address into ES
    mov     bp, [address + 2] ; Load the offset part of the memory address into BP

    mov     bl, 07h         ; Set the display attribute for the text to white on black background
    mov     cx, [nhts]      ; Load the number of sectors to display from memory into CX

    mov     ax, 1301h       ; Set the video function number to write string at a specified position
    int     10h             ; Call the BIOS video interrupt to execute the function specified in AX

    ; calculate the number of sectors to write

    xor     dx, dx          ; Clear DX register
    mov     ax, [nhts]      ; Move value from nhts to AX
    mov     bx, 512         ; Set BX to 512 (sector size)
    div     bx              ; Divide AX by BX, quotient in AX, remainder in DX

    ; write data to floppy

    mov     es, [address]  ; Set ES to the value stored at [address]
    mov     bx, [address + 2] ; Set BX to the value stored at [address + 2]

    mov     ah, 03h        ; Set up AH for BIOS Write Sector
    inc     al             ; Increment AL
    mov     ch, [nhts + 4] ; Set CH to value at nhts + 4
    mov     cl, [nhts + 6] ; Set CL to value at nhts + 6
    mov     dh, [nhts + 2] ; Set DH to value at nhts + 2
    mov     dl, 0
    int     13h

    call    display_error_code

    jmp     _terminate


; Complex I/O subprocesses

read_input:
    mov     si, storage_buffer  ; Set SI to point to the storage buffer
    call    get_cursor_pos      ; Get the cursor position for typing

typing:
    mov     ah, 00h            ; Read a key from the keyboard
    int     16h                ; BIOS interrupt for keyboard input

    cmp     al, 08h            ; Check if Backspace key is pressed
    je      hdl_backspace      ; If Backspace, jump to handle backspace

    cmp     al, 0dh            ; Check if Enter key is pressed
    je      hdl_enter          ; If Enter, jump to handle enter

    cmp     si, storage_buffer + 256  ; Check if the buffer is full
    je      typing             ; If full, continue typing

    mov     [si], al           ; Store the character in the buffer
    inc     si                 ; Move to the next position in the buffer

    mov     ah, 0eh            ; Print the character just typed
    int     10h                ; BIOS interrupt for screen output
    jmp     typing             ; Continue typing

hdl_backspace:
    cmp     si, storage_buffer ; Check if the buffer is empty
    je      typing             ; If empty, continue typing

    dec     si                 ; Move back in the buffer
    mov     byte [si], 0      ; Erase the character

    call    get_cursor_pos     ; Get the cursor position

    cmp     dl, 0              ; Check if at the start of a line
    je      prev_line          ; If at the start, jump to previous line

    mov     ah, 02h            ; Move the cursor back by one position
    dec     dl
    int     10h                ; BIOS interrupt for cursor movement

    mov     ah, 0ah            ; Print a space to erase the character
    mov     al, 20h
    int     10h                ; BIOS interrupt for screen output

    jmp     typing             ; Continue typing

prev_line:
    mov     ah, 02h            ; Move to the previous line
    dec     dh
    mov     dl, 79             ; Move to the last column
    int     10h                ; BIOS interrupt for cursor movement

    mov     ah, 0ah            ; Print a space to erase the character
    mov     al, 20h
    int     10h                ; BIOS interrupt for screen output

    jmp     typing             ; Continue typing

hdl_enter:
    cmp     si, storage_buffer ; Check if the buffer is empty
    je      typing             ; If empty, continue typing

    mov     byte [si], 0       ; Null-terminate the buffer

    ret                         ; Return from the subroutine

; paginated output for 2.2

paginated_output:
    mov     es, [address]       ; Set ES to the value at [address]
    mov     bp, [address + 2]   ; Set BP to the value at [address + 2]

    mov     ax, [nhts]          ; Move value from nhts to AX
    mov     cx, 512             ; Set CX to 512 (sector size)

    imul    ax, cx              ; Multiply AX by CX and store in pag_output_len
    mov     [pag_output_len], ax ; Store the result in pag_output_len

    xor     cx, cx              ; Clear CX register

paginated_output_loop:
        ; advance page

        inc     word [page_num] ; Increment the value at page_num

        mov     ah, 05h         ; Set AH for BIOS set active page
        mov     al, [page_num]  ; Set AL with the page number
        int     10h             ; Call BIOS interrupt 10h to set active page

        ; print 80*25 = 2000 characters from the data read

        mov     bh, [page_num]  ; Set BH with the page number
        mov     dh, 0           ; Set DH to 0 (row)
        mov     dl, 0           ; Set DL to 0 (column)

        push    cx              ; Preserve CX register value

        mov     bl, 07h         ; Set BL for display attribute (color)
        mov     cx, 2000        ; Set CX to 2000 characters to print

        mov     ax, 1301h       ; Set up AH for BIOS video scroll function
        int     10h             ; Call BIOS interrupt 10h to print characters

        ; advance pointers and counters

        pop     cx              ; Restore CX register value
        add     cx, 2000        ; Increment CX by 2000
        add     bp, 2000        ; Increment BP by 2000

        ; wait for page advance signal (spacebar press)

        wait_for_page_advance_signal:
            mov     ah, 00h     ; Read a key from the keyboard
            int     16h         ; BIOS interrupt for keyboard input

            cmp     al, 20h     ; Compare with ASCII space character
            jne     wait_for_page_advance_signal ; If not space, continue waiting

        cmp     cx, [pag_output_len]  ; Compare CX with pag_output_len
        jl      paginated_output_loop ; If less, continue paginated output

        ret                         ; Return from the subroutine

; In. number conversions

atoi:
    atoi_conv_loop:
        cmp     byte [si], 0   ; Compare the byte at SI with 0
        je      atoi_conv_done ; If it's null, jump to atoi_conv_done

        xor     ax, ax         ; Clear AX register
        mov     al, [si]       ; Move byte at SI to AL
        sub     al, '0'        ; Convert ASCII to integer by subtracting '0'

        mov     bx, [di]       ; Move value at DI to BX
        imul    bx, 10         ; Multiply BX by 10
        add     bx, ax         ; Add the value in AX to BX
        mov     [di], bx       ; Store the result in DI

        inc     si             ; Increment SI to point to the next character

        jmp     atoi_conv_loop ; Jump to the beginning of the loop

    atoi_conv_done:
        ret                     ; Return from the subroutine

atoh:
    atoh_conv_loop:
        cmp     byte [si], 0   ; Compare the byte at SI with 0
        je      atoh_conv_done ; If it's null, jump to atoh_conv_done

        xor     ax, ax         ; Clear AX register
        mov     al, [si]       ; Move byte at SI to AL
        cmp     al, 65         ; Compare AL with ASCII 'A' (65)
        jl      conv_digit     ; If less than 'A', jump to conv_digit

        conv_letter:
            sub     al, 55    ; Convert ASCII letter to hexadecimal value
            jmp     atoh_finish_iteration ; Jump to atoh_finish_iteration

        conv_digit:
            sub     al, 48    ; Convert ASCII digit to integer

        atoh_finish_iteration:
            mov     bx, [di]  ; Move value at DI to BX
            imul    bx, 16    ; Multiply BX by 16
            add     bx, ax    ; Add the value in AX to BX
            mov     [di], bx  ; Store the result in DI

            inc     si        ; Increment SI to point to the next character

        jmp     atoh_conv_loop ; Jump to the beginning of the loop

    atoh_conv_done:
        ret                     ; Return from the subroutine

; With this subprocess, copy the string n times in a separate buffer to write on floppy

fill_storage_buffer:
    push    si          ; Preserve SI register
    mov     cx, 0       ; Initialize CX register to 0

    ; Find the end of the string in SI
    find_end:
        cmp     byte [si], 0  ; Compare the byte at SI with 0
        je      end_found     ; If it's null, jump to end_found

        inc     si            ; Move to the next character
        inc     cx            ; Increment CX (string length)

        jmp     find_end      ; Continue searching for the end of the string

    end_found:
        pop     si            ; Restore SI register
        mov     di, storage_buffer  ; Set DI to point to storage_buffer

    ; Copy string from SI to DI (storage_buffer)
    copy_string_to_buffer_loop:
        push    cx            ; Preserve CX
        push    si            ; Preserve SI

        rep     movsb         ; Move string from SI to DI

        pop     si            ; Restore SI
        pop     cx            ; Restore CX

        dec     word [nhts]  ; Decrement word at nhts (number of characters)
        add     word [storage_curr_size], cx  ; Add CX to storage_curr_size

        cmp     word [nhts], 0  ; Compare word at nhts with 0
        jg      copy_string_to_buffer_loop  ; If greater, continue copying

    ; Calculate padding with null characters to align to sector size
    push    di                 ; Preserve DI
    sub     di, storage_buffer ; Calculate the offset between DI and storage_buffer
    mov     ax, di             ; Move DI offset to AX
    pop     di                 ; Restore DI

    xor     dx, dx             ; Clear DX register
    mov     bx, 512            ; Set BX to 512 (sector size)
    div     bx                 ; Divide AX by BX (calculate number of sectors)
    
    mov     cx, 0              ; Initialize CX to 0

    ; Fill the remaining space with null characters to align to sector size
    nulls:
        mov     byte [edi], 0  ; Store null character at DI

        inc     di             ; Move to the next position
        inc     cx             ; Increment CX

        cmp     cx, dx         ; Compare CX with DX (number of sectors)
        jl      nulls          ; If less, continue filling with nulls

    return:
        ret                    ; Return from the subroutine

; Useful stuff

break_line:
    call    get_cursor_pos     ; Call subroutine to get cursor position

    inc     dh                 ; Increment DH (move to the next line)
    mov     dl, 0              ; Move cursor to the start of the line

    mov     ax, 0              ; Clear AX register
    mov     es, ax             ; Set ES to 0 (video memory segment)
    mov     bp, prompt_start   ; Set BP to the prompt_start address (string)

    mov     bl, 07h            ; Set BL for display attribute (color)
    mov     cx, 0              ; Set CX to 0 (to display the entire string)

    mov     ax, 1301h          ; Set up AH for BIOS video scroll function
    int     10h                ; Call BIOS interrupt 10h to print the prompt

    ret                         ; Return from the subroutine

break_line_with_prompt:
    call    get_cursor_pos     ; Call subroutine to get cursor position

    inc     dh                 ; Increment DH (move to the next line)
    mov     dl, 0              ; Move cursor to the start of the line

    mov     ax, 0              ; Clear AX register
    mov     es, ax             ; Set ES to 0 (video memory segment)
    mov     bp, prompt_start   ; Set BP to the prompt_start address (string)

    mov     bl, 07h            ; Set BL for display attribute (color)
    mov     cx, prompt_start_len ; Set CX to prompt_start_len (length of prompt)

    mov     ax, 1301h          ; Set up AH for BIOS video scroll function
    int     10h                ; Call BIOS interrupt 10h to print the prompt

    ret                         ; Return from the subroutine

get_cursor_pos:
    mov     ah, 03h            ; Set AH for BIOS video services - get cursor position
    mov     bh, [page_num]     ; Set BH with the page number
    int     10h                ; Call BIOS interrupt 10h to get cursor position

    ret                         ; Return from the subroutine

display_error_code:
    push    ax                  ; Push the value of AX register onto the stack

    call    get_cursor_pos      ; Call a function to get the cursor position

    inc     dh                  ; Increment DH (move cursor down one row)
    mov     dl, 0               ; Move cursor to the beginning of the line

    mov     ax, 0               ; Clear AX register
    mov     es, ax              ; Set ES register to 0 (segment address)
    mov     bp, err_code_msg    ; Set BP to point to the error code message

    mov     bl, 07h             ; Set BL to 07h (text attribute color)
    mov     cx, err_code_msg_len; Set CX to the length of the error code message

    mov     ax, 1301h           ; AH = 13h (write string), AL = 01h (to cursor)
    int     10h                 ; Video Services - Write String at Cursor

    pop     ax                  ; Restore the value of AX from the stack

    mov     al, '0'             ; Convert the error code to ASCII character
    add     al, ah              ; Add the error code to '0' to get its ASCII value
    mov     ah, 0eh             ; Set AH register for BIOS teletype
    int     10h                 ; Invoke BIOS interrupt to display the error code character

    ret                         ; Return from the subroutine

; Addresses reading subprocesses

read_ram_address:
    ; print "SEGMENT (XXXX) = "
    call    get_cursor_pos    ; Call subroutine to get cursor position

    inc     dh                ; Increment DH (move to the next line)
    mov     dl, 0             ; Move cursor to the start of the line

    mov     ax, 0             ; Clear AX register
    mov     es, ax            ; Set ES to 0 (video memory segment)
    mov     bp, in_awaits_str2 ; Set BP to the in_awaits_str2 address (string)

    mov     bl, 07h           ; Set BL for display attribute (color)
    mov     cx, str2_awaits_len1 ; Set CX to str2_awaits_len1 (length of the string)

    mov     ax, 1301h         ; Set up AH for BIOS video scroll function
    int     10h               ; Call BIOS interrupt 10h to print the prompt

    ; read user input (segment)
    call    read_input        ; Call subroutine to read user input

    ; convert ascii read to a hex
    mov     di, address       ; Set DI to address (for segment)
    mov     si, storage_buffer ; Set SI to storage_buffer (user input)
    call    atoh              ; Convert ASCII input to hexadecimal

    ; print "OFFSET (YYYY) = "
    call    get_cursor_pos    ; Call subroutine to get cursor position

    inc     dh                ; Increment DH (move to the next line)
    mov     dl, 0             ; Move cursor to the start of the line

    mov     ax, 0             ; Clear AX register
    mov     es, ax            ; Set ES to 0 (video memory segment)
    mov     si, in_awaits_str2 ; Set SI to the in_awaits_str2 address (string)
    add     si, str2_awaits_len1 ; Add the length of the first prompt to SI
    mov     bp, si            ; Set BP to the updated SI position (string)

    mov     bl, 07h           ; Set BL for display attribute (color)
    mov     cx, str2_awaits_len2 ; Set CX to str2_awaits_len2 (length of the string)

    mov     ax, 1301h         ; Set up AH for BIOS video scroll function
    int     10h               ; Call BIOS interrupt 10h to print the prompt

    ; read user input (offset)
    call    read_input        ; Call subroutine to read user input

    ; convert ascii read to a hex
    mov     di, address + 2   ; Set DI to address + 2 (for offset)
    mov     si, storage_buffer ; Set SI to storage_buffer (user input)
    call    atoh              ; Convert ASCII input to hexadecimal

    ret                        ; Return from the subroutine

read_hts_address:
    ; print "{H, T, S} (one value per line):"
    call    get_cursor_pos     ; Call subroutine to get cursor position

    inc     dh                 ; Increment DH (move to the next line)
    mov     dl, 0              ; Move cursor to the start of the line

    mov     ax, 0              ; Clear AX register
    mov     es, ax             ; Set ES to 0 (video memory segment)
    mov     si, in_awaits_str1 ; Set SI to in_awaits_str1 address (string)
    add     si, str1_awaits_len1 ; Add length of first prompt
    add     si, str1_awaits_len2 ; Add length of second prompt
    mov     bp, si             ; Set BP to the updated SI position (string)

    mov     bl, 07h            ; Set BL for display attribute (color)
    mov     cx, str1_awaits_len3 ; Set CX to str1_awaits_len3 (length of the string)

    mov     ax, 1301h          ; Set up AH for BIOS video scroll function
    int     10h                ; Call BIOS interrupt 10h to print the prompt

    ; read user input (h)
    call    break_line_with_prompt ; Call subroutine to move cursor and print prompt
    call    read_input         ; Call subroutine to read user input

    ; convert ascii read to an integer
    mov     di, nhts + 2       ; Set DI to nhts + 2 (for 'H')
    mov     si, storage_buffer ; Set SI to storage_buffer (user input)
    call    atoi               ; Convert ASCII input to an integer

    ; read user input (t)
    call    break_line_with_prompt ; Move cursor and print the prompt
    call    read_input         ; Read user input

    ; convert ascii read to an integer
    mov     di, nhts + 4       ; Set DI to nhts + 4 (for 'T')
    mov     si, storage_buffer ; Set SI to storage_buffer (user input)
    call    atoi               ; Convert ASCII input to an integer

    ; read user input (s)
    call    break_line_with_prompt ; Move cursor and print the prompt
    call    read_input         ; Read user input

    ; convert ascii read to an integer
    mov     di, nhts + 6       ; Set DI to nhts + 6 (for 'S')
    mov     si, storage_buffer ; Set SI to storage_buffer (user input)
    call    atoi               ; Convert ASCII input to an integer

    ret                         ; Return from the subroutine

; Trailer subprocesses

_error:
    call    get_cursor_pos   ; Get cursor position
    call    break_line      ; Move cursor to the next line

    push    52h             ; Push ASCII values onto the stack ('R', 'R', 'E')
    push    52h
    push    45h
    mov     cx, 3           ; Set CX to 3 (number of characters to print)

    print_err_loop:
        mov     ah, 0eh     ; Set AH for BIOS teletype function
        pop     bx          ; Pop the ASCII value from the stack into BX
        mov     al, bl      ; Move ASCII value to AL
        int     10h         ; Display character at cursor position

        dec     cx          ; Decrement CX (loop counter)
        jnz     print_err_loop  ; Jump if CX is not zero to continue printing characters

    jmp _terminate          ; Jump to _terminate label

_terminate:
    wait_for_confirm:
        mov     ah, 00h     ; Set AH for BIOS keyboard input function
        int     16h         ; Wait for keypress

        cmp     al, 0dh     ; Compare the entered key with carriage return (Enter key)
        jne     wait_for_confirm  ; If not Enter, wait for another keypress

    inc     word [page_num] ; Increment the value at page_num address

    mov     ah, 05h        ; Set AH for BIOS function to move cursor
    mov     al, [page_num] ; Move current page number to AL
    int     10h            ; Call BIOS interrupt for scrolling

    jmp     _start         ; Jump to the _start label to restart the program

; Debug subprocesses

conv_check:
    ; Print space character
    mov     ah, 0eh    ; Set AH register to 0eh (function code for BIOS teletype)
    mov     al, 20h    ; Set AL register to 20h (ASCII code for space character)
    int     10h       ; Invoke BIOS interrupt to print the space character

    ; Print '>'
    mov     ah, 0eh    ; Set AH register to 0eh (function code for BIOS teletype)
    mov     al, 3eh    ; Set AL register to 3eh (ASCII code for '>') character
    int     10h       ; Invoke BIOS interrupt to print the '>' character

    ; Print '>'
    mov     ah, 0eh    ; Set AH register to 0eh (function code for BIOS teletype)
    mov     al, 3eh    ; Set AL register to 3eh (ASCII code for '>') character
    int     10h       ; Invoke BIOS interrupt to print the '>' character

    ; Print space character
    mov     ah, 0eh    ; Set AH register to 0eh (function code for BIOS teletype)
    mov     al, 20h    ; Set AL register to 20h (ASCII code for space character)
    int     10h       ; Invoke BIOS interrupt to print the space character

    ; Compare values in memory
    mov     ax, [di]        ; Load the value at address DI into AX register
    mov     bx, [test_result] ; Load the value at memory location test_result into BX register

    xor     ax, bx          ; Perform an XOR operation between AX and BX
    jnz     incorrect       ; Jump to 'incorrect' label if the result is not zero (values are different)

correct:
    ; Print 'S'
    mov     ah, 0eh    ; Set AH register to 0eh (function code for BIOS teletype)
    mov     al, 53h    ; Set AL register to 53h (ASCII code for 'S')
    int     10h       ; Invoke BIOS interrupt to print the 'S' character

    jmp     check_end       ; Unconditional jump to the 'check_end' label

incorrect:
    ; Print 'E'
    mov     ah, 0eh    ; Set AH register to 0eh (function code for BIOS teletype)
    mov     al, 45h    ; Set AL register to 45h (ASCII code for 'E')
    int     10h       ; Invoke BIOS interrupt to print the 'E' character

check_end:
    ret                     ; Return from the subroutine

print_buff:
    push    si              ; Preserve SI register

    mov     cx, 0           ; Initialize CX to 0 (counter)

find_buffer_end:
    cmp     byte [si], 0    ; Compare byte in memory pointed by SI to check for end of buffer
    je      buffer_end_found ; If it's the end of buffer (null termination), jump to buffer_end_found

    inc     si              ; Move to the next byte in the buffer
    inc     cx              ; Increment the counter (CX) for each character

    jmp     find_buffer_end ; Repeat loop to check for end of buffer

buffer_end_found:
    pop     si              ; Restore SI register
    push    cx              ; Preserve CX register

    call    get_cursor_pos  ; Get the current cursor position

    inc     dh              ; Increment DH to move the cursor down by one row
    mov     dl, 0           ; Set DL to the start of the line (column 0)

    mov     ax, 0           ; Clear AX register
    mov     es, ax          ; Load ES with 0
    mov     bp, si          ; Point BP to the current location in the buffer (SI)

    mov     bl, 07h         ; Set the display attribute for the text to white on black background
    pop     cx              ; Restore CX (counter)

    mov     ax, 1301h       ; Set the video function number to write string at a specified position
    int     10h             ; Call the BIOS video interrupt to execute the function specified in AX

    ret                     ; Return from the subroutine

; Data declaration and initialization

reset_memory:
    ; Initialize pag_output_len to 0
    mov     word [pag_output_len], 0

    ; Reset disk system - (BIOS Interrupt 13h - Reset Disk System)
    mov     ah, 00h
    int     13h

    ; Reset various buffers and memory spaces
    mov     si, storage_buffer
    mov     di, storage_buffer + 512
    call    clear_buffer      ; Call subroutine to clear the buffer

    ; Clear 'string' buffer
    mov     si, string
    mov     di, string + 256
    call    clear_buffer      ; Call subroutine to clear the buffer

    ; Clear 'nhts' buffer
    mov     si, nhts
    mov     di, nhts + 8
    call    clear_buffer      ; Call subroutine to clear the buffer

    ; Clear 'address' buffer
    mov     si, address
    mov     di, address + 4
    call    clear_buffer      ; Call subroutine to clear the buffer

    ; Clear 'pag_output_len' buffer
    mov     si, pag_output_len
    mov     di, pag_output_len + 4
    call    clear_buffer      ; Call subroutine to clear the buffer

    ; Reset 'storage_curr_size' buffer
    mov     si, storage_curr_size
    mov     di, storage_curr_size + 4
    call    clear_buffer     ; Call subroutine to reset the buffer

    ; Reset 'storage_buffer' buffer
    mov     si, storage_buffer
    mov     di, storage_buffer + 1
    call    clear_buffer     ; Call subroutine to reset the buffer

    ; Reset CPU registers
    call    reset_registers   ; Call subroutine to reset CPU registers

    ret                       ; Return from the subroutine

reset_registers:
    xor     ax, ax
    xor     bx, bx
    xor     cx, cx
    xor     dx, dx
    xor     si, si
    xor     di, di
    xor     bp, bp

    ret

clear_buffer:
    clear_buffer_loop:
        mov     byte [si], 0
        inc     si

        cmp     si, di
        jl      clear_buffer_loop

    ret

section .data
    opt_str              dd "1. KBD-->FLP | 2. FLP-->RAM | 3. RAM-->FLP"
    opt_len              equ 42

    in_awaits_str1       dd "STRING = N = {H, T, S} (one value per line)", 3ah
    str1_awaits_len1     equ 9
    str1_awaits_len2     equ 4
    str1_awaits_len3     equ 31

    in_awaits_str2       dd "SEGMENT (XXXX) = OFFSET (YYYY) = "
    str2_awaits_len1     equ 17
    str2_awaits_len2     equ 16

    err_code_msg         dd "EC="
    err_code_msg_len     equ 3

    prompt_start         dd ">>> "
    prompt_start_len     equ 4

    page_num             dw 0
    test_result          dw 10000

    pag_output_len       dw 0
    
section .bss
    string              resb 256
    nhts                resb 8
    address             resb 4
    storage_curr_size   resb 4
    storage_buffer      resb 1

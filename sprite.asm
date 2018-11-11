	;; Paul's sprite stuff!
	;; Uses RSXs


	org &8000          ; will change later

	; -- INSTALL RSXs
	ld hl,rsx_work_space	;address of a 4 byte workspace useable by Kernel
	ld bc,jump_table		;address of command name table and routine handlers
	jp &bcd1		        ;Install RSX's

	; -- RSX DEFINITION

.rsx_work_space           	;Space for kernel to use
	defs 4

.jump_table
	defw name_table      ;address pointing to RSX commands 
	jp RSX_GET           ;routine for COMMAND1 RSX
	jp RSX_PUT           ;routine for COMMAND2 RSX

	;; the table of RSX function names
	;; the names must be in capitals.

.name_table
	defb "GE","T"+&80     ;the last letter of each RSX name must have bit 7 set to 1.
	defb "PU","T"+&80     ;This is used by the Kernel to identify the end of the name.    
	defb 0                ;end of name table marker

	; ---------------------------------------------------------------------------

.RSX_GET                  ; Mode 0: 1 byte = 2 pixels (4 bytes = 8px) (32 bytes = 8x8, 64 = 8x16)
	ld de, spritespace    ; put DE at start of sprite memory
	ld hl, &c000          ; start position of sprite - should be provided by something else

	push hl               ; remember start position

	call get_copy_loop    ; first 7 rows
	call get_copy_noloop  ; first 8th row

	ld bc, &50            ; delta to top of next character
	pop hl                ; get start original location
	add hl, bc            ; change hl to top of lower character position

	call get_copy_loop    ; second 7 rows
	jp get_copy_noloop    ; last row (jp to save an instruction)
	ret

.get_copy_loop        	  ; main loop to copy from screen to RAM
	ld b, 7               ; do this 7 times
	
.get_copy_loop_work
	ldi                   ; do four copies in a row  (HL into DE)
	ldi
	ldi
	ldi
	push bc               ; remember b
	ld bc, &7FC
	add hl, bc            ; go to start of next line on screen
	pop bc
	djnz get_copy_loop_work ; do loop until b = 0
	ret

.get_copy_noloop
	ldi                   ; do four copies in a row  (HL into DE)
	ldi
	ldi
	ldi
	ret

	; ---------------------------------------------------------------------------

.RSX_PUT
	ld hl, spritespace    ; put HL at start of sprite memory
	ld de, &c000          ; put DE at start position of screen memory

	push de               ; remember start video position

	call put_copy_loop
	call put_copy_noloop

	pop de               ; get original video ram location
	ex de, hl            ; HL now screen memory, DE now sprite memory
	ld bc, &50
	add hl, bc
	ex de, hl            ; HL now sprite and DE now screen

	call put_copy_loop
	jp put_copy_noloop

	ret

.put_copy_loop
	ld b, 7               ; do this 7 times
	
.put_copy_loop_work
	ldi
	ldi
	ldi
	ldi
	push bc         ; remember b
	ex de, hl       ; HL now screen memory, DE now sprite memory
	ld bc, &7FC     ; next line
	add hl, bc
	ex de, hl       ; HL now sprite and DE now screen
	pop bc
	djnz put_copy_loop_work ; do loop until b = 0
	ret

.put_copy_noloop
	ldi
	ldi
	ldi
	ldi
	ret

	; ---------------------------------------------------------------------------

.spritespace          ; blank space for sprites
	defs 100

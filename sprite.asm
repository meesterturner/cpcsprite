	;; Paul's sprite stuff!
	;; Uses RSXs


	org &8000
	
	; -- INITIALISE LOOKUP TABLE BEFORE INSTALLING RSX
	call BUILD_SCREEN_LINE_LOOKUP
	
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
	cp 1				  ; Have we got 1 parameter (sprite number)
	jp nz, ERRORCONDITION ; Exit if not
	ld b, (IX+0)          ; get 8 bit version of 16 bit parameter (IX+0 is LSB)
	call CALC_SPRITE_MEM  ; calc sprite location
	
	ld de, (spritememloc) ; put DE at start of sprite memory
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
	cp 3				  ; Have we got 3 parameters (sprite number, x char, y char)
	jp nz, ERRORCONDITION ; Exit if not
	
	ld L, (IX+0)
	ld H, (IX+1)
	ld (sprite_user_y), HL
	
	ld L, (IX+2)
	ld H, (IX+3)
	ld (sprite_user_x), HL
	
	ld b, (IX+4)          ; get 8 bit version of 16 bit parameter (IX+0 is LSB)
	call CALC_SPRITE_MEM  ; calc sprite data location
	call CALC_SPRITE_SCREEN ; calc sprite screen location
	
	ld hl, (spritememloc) ; put HL at start of sprite memory
	ld de, (spritescreenmemloc) ; put DE at start position of screen memory

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

.ERRORCONDITION
	ld hl, errortext
.errorcondition_text_loop
	ld a, (hl)
	or a
	ret z
	call &bb5a
	inc hl
	jr errorcondition_text_loop
	
.errortext
	defb "Incorrect parameter count", 0
	
	; ---------------------------------------------------------------------------

.spritememloc
	defs 2            ; Used as storage for where a sprite lives...

.CALC_SPRITE_MEM      ; sprite number in B (1-255) / returns via .spritememloc
	push hl
	push de
	ld hl, spritespace
	ld de, 64
	
.calc_add_loop_work
	djnz calc_add_loop ; If not 0, add 64 bytes and move on
	ld (spritememloc), hl
	pop de
	pop hl
	ret
	
.calc_add_loop
	add hl, de        ; each sprite is 64 bytes
	jp calc_add_loop_work

	; ---------------------------------------------------------------------------
.spritescreenmemloc   ; output for where sprite will start
	defs 2
.sprite_user_x        ; input for x position (characters)
	defs 2
.sprite_user_y        ; input for y position (characters)
	defs 2
	
.CALC_SPRITE_SCREEN
	push hl
	ld hl, &c000           ; first byte of screen ram
	ld a, (sprite_user_y)  ; 1-24
	ld bc, &50 ; next line
	
.calc_sprite_y_work
	dec a
	cp 0                   ; if zero, no calc required
	jr z, calc_sprite_x    ; ... so go to the x
	add hl, bc
	jp calc_sprite_y_work     ; goto top of loop
	
.calc_sprite_x
	ld a, (sprite_user_x)
	ld bc, &4             ; next character (8 pixels, 4 bytes)
	
.calc_sprite_x_work
	dec a
	cp 0
	jr z, calc_sprite_pos_done
	add hl, bc
	jp calc_sprite_x_work ; go again!
	
.calc_sprite_pos_done
	ld (spritescreenmemloc), hl
	pop hl
	ret
	
	; ---------------------------------------------------------------------------
	
.BUILD_SCREEN_LINE_LOOKUP
	ld a, 25				; number of blocks
	ld hl, &c000			; start of screen memory
	ld ix, spritelinelookup	; start of lookup table
.build_screen_block
	push hl					; remember start of this block
	ld b, 8					; do this block of 8 lines
.build_screen_eight_work
	ld (ix+0), l			; insert into lookup table
	ld (ix+1), h
	inc ix					; move in lookup table
	inc ix
	djnz build_screen_next_line ; decrease B, if not another line, try another block
	jp build_screen_next_block
.build_screen_next_line
	push bc
	ld bc, &800
	add hl, bc				; go to next pixel line
	pop bc
	jr build_screen_eight_work
.build_screen_next_block
	pop hl					; get start of block back
	dec a
	cp 0
	ret z
	ld bc, &50
	add hl, bc				; go to start of next block
	jr build_screen_block

.spritelinelookup
	defs 400			; 200 lines x 16 bit address
	; ---------------------------------------------------------------------------
	
.spritespace          ; blank space for sprites
	defs 4

    ; -------------------------------------------
    ; Paul's Z80 CPC Sprite Routine
    ; Includes RSXs to use from Locomotive BASIC
    ; -------------------------------------------

    org &8000
    
    ; -- INITIALISE LOOKUP TABLE BEFORE INSTALLING RSX
    call BUILD_SCREEN_LINE_LOOKUP
    
    ; -- INSTALL RSXs
    ld hl,rsx_work_space            ; Address of a 4 byte workspace useable by Kernel
    ld bc,jump_table                ; Address of command name table and routine handlers
    jp &bcd1                        ; Install RSX's

    ; -- RSX DEFINITION

.rsx_work_space                     ; Space for kernel to use
    defs 4

.jump_table
    defw name_table                 ; Address pointing to RSX commands 
    jp RSX_GET                      ; Routine for |GET RSX
    jp RSX_PUT                      ; Routine for |PUT RSX

.name_table                         ; RSX Name Table
    defb "GE","T"+&80               ; The last letter of each RSX name must have bit 7 set to 1.
    defb "PU","T"+&80               ; This is used by the Kernel to identify the end of the name.    
    defb 0                          ; End of name table marker

    ; ---------------------------------------------------------------------------

.RSX_GET                            ; Mode 0: 1 byte = 2 pixels (4 bytes = 8px) (32 bytes = 8x8, 64 = 8x16)
    cp 1                            ; Have we got 1 parameter (sprite number)
    jp nz, ERRORCONDITION           ; Exit if not
    ld b, (IX+0)                    ; get 8 bit version of 16 bit parameter (IX+0 is LSB)
    call CALC_SPRITE_MEM            ; calc sprite location
    
    ld de, (spritememloc)           ; put DE at start of sprite memory
    ld hl, &c000                    ; start position of sprite - should be provided by something else

    push hl                         ; remember start position

    call get_copy_loop              ; first 8 rows

    ld bc, &50                      ; delta to top of next character
    pop hl                          ; get start original location
    add hl, bc                      ; change hl to top of lower character position

    ;jp get_copy_loop               ; second 8 rows (jp not needed as it's the next line)

.get_copy_loop                      ; main loop to copy from screen to RAM
    ld b, 7                         ; do this 7 times
    
.get_copy_loop_work
    ldi                             ; do four copies in a row  (HL into DE)
    ldi
    ldi
    ldi
    push bc                         ; remember b
    ld bc, &7FC
    add hl, bc                      ; go to start of next line on screen
    pop bc
    djnz get_copy_loop_work         ; do loop until b = 0

.get_copy_noloop
    ldi                             ; do four copies in a row  (HL into DE)
    ldi
    ldi
    ldi
    ret

    ; ---------------------------------------------------------------------------

.RSX_PUT
    cp 3                            ; Have we got 3 parameters (sprite number, x char, y char)
    jp nz, ERRORCONDITION           ; Exit if not
    
    ld L, (IX+0)
    ld H, (IX+1)
    ld (sprite_user_y), HL
    
    ld L, (IX+2)
    ld H, (IX+3)
    ld (sprite_user_x), HL
    
    ld b, (IX+4)                    ; get 8 bit version of 16 bit parameter (IX+0 is LSB)
    call CALC_SPRITE_MEM            ; calc sprite data location
    call CALC_SPRITE_SCREEN         ; calc sprite screen location (value in HL and posted to memory)
    ; DE contains X offset.... HL is start of screen memory
    
    ex de, hl                       ; put calc screen memory location into DE
    ld hl, (spritememloc)           ; put HL at start of sprite memory

.put_copy_loop
    ld b, 16
     
.put_copy_loop_work
    ldi
    ldi
    ldi
    ldi
    
    djnz put_copy_next_line
    ret
    
.put_copy_next_line                 ; This works out where the next line should go in memory
    push hl                         ; but because we're using the lookup table every time
    ld hl, (sprite_user_y)          ; the speed might not be the greatest any more :-/ 
    inc hl                          ; But the "missing line" issue is eradicated!!
    ld (sprite_user_y), hl
    
    call CALC_SPRITE_SCREEN
    ex de, hl
    pop hl
    jp put_copy_loop_work           ; back to top of loop [150 = 10 * 15] = 364
    
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
    defs 2                          ; Used as storage for where a sprite lives...

.CALC_SPRITE_MEM                    ; sprite number in B (1-255) / returns via .spritememloc
    push hl
    push de
    ld hl, spritespace
    ld de, 64
    
.calc_add_loop_work
    djnz calc_add_loop              ; If not 0, add 64 bytes and move on
    ld (spritememloc), hl
    pop de
    pop hl
    ret
    
.calc_add_loop
    add hl, de                      ; each sprite is 64 bytes
    jp calc_add_loop_work

    ; ---------------------------------------------------------------------------
.spritescreenmemloc                 ; output for where sprite will start
    defs 2
.sprite_user_x                      ; input for x position (pixels / 2 [1-80])
    defs 2
.sprite_user_y                      ; input for y position (pixels [1-200])
    defs 2
    
.CALC_SPRITE_SCREEN                 ; With help from http://cpctech.cpc-live.com/docs/scraddr.html
    ld hl, (sprite_user_y)          ; 1-200
    dec hl                          ; decrease by one
    add hl, hl                      ; multiply by two to get the correct offset in the lookup
    ld de, spritelinelookup         ; add in position of the lookup table
    add hl, de
    
    ld a,(hl)                       ; Read from table (first byte into a,
    inc hl                          ; second into h, then a into l)
    ld h,(hl)
    ld l,a  
    
    ld de, (sprite_user_x)          ; add in x position(1-80)-1
    add hl, de
    dec hl
    ld (spritescreenmemloc), hl     ; return it through the memory location
    ret 
    
    ; ---------------------------------------------------------------------------
    
.BUILD_SCREEN_LINE_LOOKUP
    ld a, 25                        ; number of blocks
    ld hl, &c000                    ; start of screen memory
    ld ix, spritelinelookup         ; start of lookup table
.build_screen_block
    push hl                         ; remember start of this block
    ld b, 8                         ; do this block of 8 lines
.build_screen_eight_work
    ld (ix+0), l                    ; insert into lookup table
    ld (ix+1), h
    inc ix                          ; move in lookup table
    inc ix
    djnz build_screen_next_line     ; decrease B, if not another line, try another block
    jp build_screen_next_block
.build_screen_next_line
    push bc
    ld bc, &800
    add hl, bc                      ; go to next pixel line
    pop bc
    jr build_screen_eight_work
.build_screen_next_block
    pop hl                          ; get start of block back
    dec a
    cp 0
    ret z
    ld bc, &50
    add hl, bc                      ; go to start of next block
    jr build_screen_block

.spritelinelookup
    defs 400                        ; 200 lines x 16 bit address
    ; ---------------------------------------------------------------------------
    
.spritespace                        ; blank space for sprites
    defs 4

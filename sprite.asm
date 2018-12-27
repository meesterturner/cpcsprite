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
    ld a, (IX+0)                    ; get 8 bit version of 16 bit parameter (IX+0 is LSB)
    call CALC_SPRITE_MEM            ; calc sprite location
    ex de, hl                       ; put sprite location into DE
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
    ld (sprite_user_y + 1), HL
    
    ld L, (IX+2)
    ld H, (IX+3)
    ld (sprite_user_x + 1), HL
    
    ld a, (IX+4)                    ; get 8 bit version of 16 bit parameter (IX+0 is LSB)
    call CALC_SPRITE_MEM            ; calc sprite data location
    push hl                         ; remember this data location....
    call CALC_SPRITE_SCREEN         ; calc sprite screen location (value in HL)
    
    call FIND_ROW_GROUP_BOUNDARY    ; After this, DE contains Y offset.... HL is start of screen memory
    ld a, e                         ; Get Y offset back into A (need A to contain current line number)
    ex de, hl                       ; put calc screen memory location into DE
    pop hl                          ; get back sprite memory location into HL

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
    inc a
.put_copy_compare                   ; sneaky self-modifying code for speed (put_copy_compare + 1)
    cp 255                          ; is it a boundary line?
    jp z, put_calc_next_line        ; yep, it is, jump to firmware call
                                    ; else manually add &7FC to current location
    ex de, hl                       ; swap DE & HL so DE is *temp* sprite memory, HL is *temp* screen                           
    push de
    ld de, &7FC
    add hl, de
    pop de
    ex de, hl                       ; Swap DE & HL back (DE screen, HL sprite memory)
    jp put_copy_loop_work           ; back to top of loop
    
.put_calc_next_line
    ex de, hl                       ; swap DE & HL so DE is *temp* sprite memory, HL is *temp* screen
    ld l, a                         ; Next line number into L
    ld h, 0                         ; Zero H
    push af
    push de
    call CALC_SPRITE_SCREEN_HL      ; Returns using HL
    ld a, (put_copy_compare + 1)    ; just in case we cross another boundary...
    add a, 8
    ld (put_copy_compare + 1), a
    pop de
    pop af
    ex de, hl                       ; Swap DE & HL back (DE screen, HL sprite memory)
    jp put_copy_loop_work           ; back to top of loop
    
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

.CALC_SPRITE_MEM                    ; sprite number in A (1-255) / returns via HL
    ld hl, spritespace
    ld de, 64
    
.calc_add_loop_work
    dec a
    or a                            ; are we 0?
    ret z                           ; return if we are
    add hl, de                      ; If not 0, add 64 bytes and move on
    jp calc_add_loop_work           ; top of loop
    
    ; ---------------------------------------------------------------------------
    
.CALC_SPRITE_SCREEN                 ; With help from http://cpctech.cpc-live.com/docs/scraddr.html
.sprite_user_y                      ; input for y position (pixels [1-200]) - Self Modifying (sprite_user_y + 1)
    ld hl, &FFFF                    ; 1-200
.CALC_SPRITE_SCREEN_HL              ; Label to skip above line
    dec hl                          ; decrease by one
    add hl, hl                      ; multiply by two to get the correct offset in the lookup
    ld de, spritelinelookup         ; add in position of the lookup table
    add hl, de
    
    ld a,(hl)                       ; Read from table (first byte into a,
    inc hl                          ; second into h, then a into l)
    ld h,(hl)
    ld l,a  
.sprite_user_x                      ; input for x position (pixels / 2 [1-80]) - Self Modifying (sprite_user_x + 1)
    ld de, &ffff                    ; add in x position(1-80)-1
    add hl, de
    dec hl
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
    
    ; ---------------------------------------------------------------------------
.FIND_ROW_GROUP_BOUNDARY            ; Used when putting across character line boundaries                
    push hl
    ld de, (sprite_user_y + 1)      ; E should contain pixel line
    ld hl, spritelineboundarylookup
.find_boundary_loop_work
    ld a, (hl)                      ; Load line from table
    cp e                            ; ... compare it to the line we want
    jp c, ignore_this_boundary      ; if a < e, then ignore it
    jp z, ignore_this_boundary      ; If a = e, then ignore it
    
.store_line_boundary
    ld (put_copy_compare + 1), a
    pop hl
    ret
    
.ignore_this_boundary               
    inc hl
    jp find_boundary_loop_work
    
.spritelineboundarylookup
    defb 9, 17, 25, 33, 41, 49, 57, 65, 73, 81
    defb 89, 97, 105, 113, 121, 129, 137, 145, 153, 161
    defb 169, 177, 185, 193, 201
    
    ; ---------------------------------------------------------------------------
    
.spritelinelookup
    defs 400                        ; 200 lines x 16 bit address
    ; ---------------------------------------------------------------------------
    
.spritespace                        ; blank space for sprites
    defs 4

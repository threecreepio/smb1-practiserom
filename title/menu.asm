SettablesCount   = $4
MenuTextPtr      = $C3
MenuTextLen      = $C2

.pushseg
.segment "MENUWRAM"
MenuSelectedItem: .byte $00
MenuSelectedSubitem: .byte $00
Settables:
SettablesWorld: .byte $00
SettablesLevel: .byte $00
SettablesPUP:   .byte $00
SettablesRule:  .byte $00
.popseg

; names for each selection type
MenuTitles:
.byte "WORLD   "
.byte "LEVEL   "
.byte "P-UP    "
.byte "RULE    "

; ppu position to draw each title
.define MenuTitleLocations \
    $20CA + ($40 * 0), \
    $20CA + ($40 * 1), \
    $20CA + ($40 * 2), \
    $20CA + ($40 * 3)

; ppu position to draw each value
.define MenuValueLocations \
    $20D3 + ($40 * 0) - 0, \
    $20D3 + ($40 * 1) - 0, \
    $20D3 + ($40 * 2) - 3, \
    $20D3 + ($40 * 3) - 3

; which routines to use to change each menu items value
UpdateSelectedValueJE:
    tya
    jsr JumpEngine
    .word UpdateValueWorldNumber ; world
    .word UpdateValueLevelNumber ; level
    .word UpdateValuePUps        ; p-up
    .word UpdateValueFramerule   ; framerule

; which routines to use to draw each menu items value
DrawMenuValueJE:
    tya
    jsr JumpEngine
    .word DrawValueNumber        ; world
    .word DrawValueNumber        ; level
    .word DrawValueString_PUp    ; p-up
    .word DrawValueFramerule     ; framerule

; ===========================================================================
;  Redraw menu
; ---------------------------------------------------------------------------
DrawMenu:
MenuReset:
    @Temp = $10
    ldy #(SettablesCount-1)                  ; get number of menu items
:   sty @Temp                                ; store the current menu item
    jsr @DrawMenuTitle                       ; draw the title of the menu item
    ldy @Temp                                ; restore the menu item
    jsr DrawMenuValueJE                      ; draw the value of the menu item
    ldy @Temp                                ; restore the menu item
    dey                                      ; and decrement it
    bpl :-                                   ; if not done, keep drawing
    rts                                      ; otherwise, exit
@DrawMenuTitle:
    clc                                      ;
    lda VRAM_Buffer1_Offset                  ; get current vram offset position
    tax                                      ;
    adc #3+5                                 ; advance it based on how many bytes we will write
    sta VRAM_Buffer1_Offset                  ; and save it back
    lda MenuTitleLocationsHi,y               ; set ppu location of the current item's title
    sta VRAM_Buffer1+0,x                     ;
    lda MenuTitleLocationsLo,y               ;
    sta VRAM_Buffer1+1,x                     ;
    lda #5                                   ; store length of the title
    sta VRAM_Buffer1+2,x                     ;
    tya                                      ; copy the menu item index to A
    rol a                                    ; and multiply it by 8, the offsets of the title strings
    rol a                                    ;
    rol a                                    ;
    tay                                      ; and copy that back to Y
    lda MenuTitles+0,y                       ; then write the title screen to the buffer
    sta VRAM_Buffer1+3,x                     ;
    lda MenuTitles+1,y                       ;
    sta VRAM_Buffer1+4,x                     ;
    lda MenuTitles+2,y                       ;
    sta VRAM_Buffer1+5,x                     ;
    lda MenuTitles+3,y                       ;
    sta VRAM_Buffer1+6,x                     ;
    lda MenuTitles+4,y                       ;
    sta VRAM_Buffer1+7,x                     ;
    lda #0                                   ; and end the buffer with null
    sta VRAM_Buffer1+8,x                     ;
    rts                                      ;
; ===========================================================================

; ===========================================================================
;  Menu main loop
; ---------------------------------------------------------------------------
MenuNMI:
    jsr DrawSelectionMarkers                 ; reposition the selection markers
    clc                                      ;
    lda PressedButtons                       ; check current inputs
    bne @READINPUT                           ; if any buttons are held, check them
    rts                                      ; otherwise there's nothing to do
@READINPUT:                                  ;
    and #Right_Dir|Left_Dir|Down_Dir|Up_Dir  ; are we holding a direction?
    beq @SELECT                              ; if not, check for select
    ldy MenuSelectedItem                     ; we are, get the current selected item
    jsr UpdateSelectedValueJE                ; update the value
    jmp @RenderMenu                          ; redraw the menu and exit
@SELECT:                                     ;
    lda PressedButtons                       ; check current inputs
    cmp #Select_Button                       ; are we holding select?
    bne @START                               ; if not, check for start
    ldx #0                                   ; we are changing selected menu item
    stx MenuSelectedSubitem                  ; clear selected subitem
    inc MenuSelectedItem                     ; and advance to the next item
    lda MenuSelectedItem                     ; then check if we've reached the final item
    cmp #SettablesCount                      ;
    bne :+                                   ; no - skip ahead
    stx MenuSelectedItem                     ; yes - clear the selected item
:   rts                                      ; and exit
@START:                                      ;
    cmp #Start_Button                        ; are we holding start?
    bne @DONE                                ; no - nothing to do, exit
    lda #0                                   ; yes - check held buttons
    ldx HeldButtons                          ;
    cpx #A_Button                            ; check if we're holding A
    bcc :+                                   ; nope - skip ahead
    lda #1                                   ; yes - set hard mode flag
:   sta PrimaryHardMode                      ; save hard mode flag
    jmp TStartGame                           ; and start the game
@RenderMenu:                                 ;
    ldy MenuSelectedItem                     ; get the current selected item
    jsr DrawMenu                             ; and redraw it
@DONE:                                       ;
    rts                                      ; done
; ===========================================================================


; ===========================================================================
;  Position the "cursors" of the menu at the correct location
; ---------------------------------------------------------------------------
DrawSelectionMarkers:
    lda #$00                                 ; set palette attributes for sprites
    sta Sprite_Attributes + (1 * SpriteLen)  ;
    lda #$21                                 ;
    sta Sprite_Attributes + (2 * SpriteLen)  ;
    lda #$2E                                 ; main coin sprite for sprite 1
    sta Sprite_Tilenumber + (1 * SpriteLen)  ;
    lda #$27                                 ; set solid background for sprite 2
    sta Sprite_Tilenumber + (2 * SpriteLen)  ;
    lda #$1E                                 ; get initial Y position
    ldy MenuSelectedItem                     ; get current menu item
:   clc                                      ;
    adc #$10                                 ; add 16px per menu item
    dey                                      ; decrement loop value
    bpl :-                                   ; and loop until done
    sta Sprite_Y_Position + (1 * SpriteLen)  ; reposition sprite 1 (floating coin)
    sta Sprite_Y_Position + (2 * SpriteLen)  ; reposition sprite 2 (background color)
    lda #$A9                                 ; get initial X position
    sta Sprite_X_Position + (1 * SpriteLen)  ; reposition sprite 1 (floating coin)
    sbc #$8                                  ; offset by 8px for the background color
    ldy MenuSelectedSubitem                  ; get which subitem is selected
:   sec                                      ; then offset by another 8px per subitem
    sbc #$8                                  ;
    dey                                      ; decrement loop value
    bpl :-                                   ; and loop until done
    sta Sprite_X_Position + (2 * SpriteLen)  ; reposition sprite 2 (background color)
    rts                                      ; done
; ===========================================================================

; update selected world value
UpdateValueWorldNumber:
    ldx WorldCount         ; get number of worlds
    lda HeldButtons        ; check held buttons
    and #B_Button          ; are we holding B?
    beq :+                 ; no - skip ahead
    ldx #$FF               ; otherwise allow selecting any value
:   jmp UpdateValueShared  ; update selected menu item

; update selected level value
UpdateValueLevelNumber:
    ldx LevelCount         ; get number of levels per world
    lda HeldButtons        ; check held buttons
    and #B_Button          ; are we holding B?
    beq :+                 ; no - skip ahead
    ldx #$FF               ; otherwise allow selecting any value
:   jmp UpdateValueShared  ; update selected menu item

; update selected powerup value
UpdateValuePUps:
    ldx #6                 ; there are 6 total states
    jmp UpdateValueShared  ; update selected menu item

; ===========================================================================
; Update a single byte menu item
; ---------------------------------------------------------------------------
; Input:  Y   = menu item index
;         X   = maximum allowed value
; ---------------------------------------------------------------------------
UpdateValueShared:
    @Max = $0
    stx @Max                          ; temp store max value
    clc                               ;
    lda PressedButtons                ; get current inputs
    and #Down_Dir|Left_Dir            ; check if we're pressing decrementing direction
    bne @Decrement                    ; yes - skip ahead to decrement
@Increment:                           ; no - we are incrementing
    lda Settables,y                   ; get current value of the menu item
    adc #1                            ; increment it
    cmp @Max                          ; check if we're beyond the maximum value
    bcc @Store                        ; no - skip ahead to store
    lda #0                            ; yes - set to 0
    beq @Store                        ; and store
@Decrement:                           ;
    lda Settables,y                   ; get current value of the menu item
    beq @Wrap                         ; if it's 0, wrap around
    sec                               ;
    sbc #1                            ; otherwise, decrement it
    bvc @Store                        ; skip ahead to store
@Wrap:                                ;
    lda @Max                          ; wrap around to the maximum value + 1
    sec                               ; and decrement it by 1
    sbc #1                            ;
@Store:                               ;
    sta Settables,y                   ; store the new value
    rts                               ;
; ===========================================================================

; ===========================================================================
; Modify the selected framerule
; ---------------------------------------------------------------------------
UpdateValueFramerule:
    clc                               ;
    ldx MenuSelectedSubitem           ; get selected digit offset
    lda PressedButtons                ; check inputs
    and #Right_Dir|Left_Dir           ; are we pressing left/right
    beq @update_value                 ; no - skip to check if we're changing value
    dex                               ; yes - we are changing which digit is selected
    lda PressedButtons                ; get buttons again
    cmp #Right_Dir                    ; are we pressing right?
    beq @store_selected               ; yes - store X as new selected digit
    inx                               ; no - we are pressing left, increment twice to offset dex
    inx                               ;
@store_selected:                      ;
    txa                               ;
    and #%11                          ; mask to valid framerule value
    sta MenuSelectedSubitem           ; and update selected digit
    rts                               ; done - exit
@update_value:
    ldy MathFrameruleDigitStart,x     ; get the digit we're changing
    lda PressedButtons                ; and check inputs
    cmp #Up_Dir                       ; are we pressing up?
    beq @increase                     ; yes - increment digit
    dey                               ; no - decrement digit
    bpl @store_value                  ; if we didn't underflow, store value
    ldy #9                            ; otherwise wrap back around to 9
    bne @store_value                  ; and store value
@increase:
    iny                               ; we're increment, so, increment Y
    cpy #$A                           ; check if we overflowed
    bne @store_value                  ; no - store value
    ldy #0                            ; yes - wrap back around to 0
@store_value:
    tya                               ;
    sta MathFrameruleDigitStart,x     ; and save the new digit
    rts                               ; exit!
; ===========================================================================

; ===========================================================================
; Draws a menu item to screen
; ---------------------------------------------------------------------------
DrawValueNumber:
    clc                               ;
    lda VRAM_Buffer1_Offset           ; get current vram update offset
    tax                               ;
    adc #4                            ; offset it based on how much we're writing
    sta VRAM_Buffer1_Offset           ; and store it back
    lda MenuValueLocationsHi,y        ; get the ppu location of this menu item, and write to vram buffer
    sta VRAM_Buffer1+0,x              ;
    lda MenuValueLocationsLo,y        ;
    sta VRAM_Buffer1+1,x              ;
    lda #1                            ; we're writing 1 number
    sta VRAM_Buffer1+2,x              ;
    lda Settables,y                   ; get the value of the settable item
    adc #1                            ; and increment it, since we display 1-based numbers
    sta VRAM_Buffer1+3,x              ; store the number to be drawn
    lda #0                            ; and mark the end of the buffer
    sta VRAM_Buffer1+4,x              ;
    rts                               ;
; ===========================================================================

; ===========================================================================
; Draws the four digit framerule to screen
; ---------------------------------------------------------------------------
DrawValueFramerule:
    clc                               ;
    lda VRAM_Buffer1_Offset           ; get current vram update offset
    tax                               ;
    adc #7                            ; offset it based on how much we're writing
    sta VRAM_Buffer1_Offset           ; and store it back
    lda MenuValueLocationsHi, y       ; get the ppu location of this menu item, and write to vram buffer
    sta VRAM_Buffer1+0, x             ;
    lda MenuValueLocationsLo, y       ;
    sta VRAM_Buffer1+1, x             ;
    lda #4                            ; we're writing 4 numbers
    sta VRAM_Buffer1+2, x             ;
    lda MathFrameruleDigitStart+0     ; copy each of the four digits to vram buffer
    sta VRAM_Buffer1+3+3, x           ;
    lda MathFrameruleDigitStart+1     ;
    sta VRAM_Buffer1+3+2, x           ;
    lda MathFrameruleDigitStart+2     ;
    sta VRAM_Buffer1+3+1, x           ;
    lda MathFrameruleDigitStart+3     ;
    sta VRAM_Buffer1+3+0, x           ;
    lda #0                            ; and mark the end of the buffer
    sta VRAM_Buffer1+3+4, x           ;
    rts                               ;
; ===========================================================================

; ===========================================================================
; Draws a string from a pointer to screen
; ---------------------------------------------------------------------------
DrawValueString:
    clc                               ;
    lda VRAM_Buffer1_Offset           ; get current vram update offset
    tax                               ;
    adc MenuTextLen                   ; offset it based on string length
    adc #3                            ; and add 3 for the header
    sta VRAM_Buffer1_Offset           ; and store it back
    lda MenuValueLocationsHi,y        ; get the ppu location of this menu item, and write to vram buffer
    sta VRAM_Buffer1+0,x              ;
    lda MenuValueLocationsLo,y        ;
    sta VRAM_Buffer1+1,x              ;
    lda MenuTextLen                   ; write the string length to vram buffer
    sta VRAM_Buffer1+2,x              ;
    ldy #0                            ; prepare iterator
@CopyNext:                            ;
    lda (MenuTextPtr),y               ; copy a byte of the string to vram
    sta VRAM_Buffer1+3,x              ;
    inx                               ; increment vram offset
    iny                               ; increment string read offset
    cpy MenuTextLen                   ; check if we're done
    bcc @CopyNext                     ; no - copy next byte
    lda #0                            ; and mark the end of the buffer
    sta VRAM_Buffer1+4, x             ;
    rts                               ;
; ===========================================================================

; ===========================================================================
; Draws a powerup state to screen
; ---------------------------------------------------------------------------
DrawValueString_PUp:
    lda Settables,y                   ; get the selected powerup state
    asl a                             ; get offset into pointer table
    tax                               ;
    lda @Strings,x                    ; copy string pointer to menu text pointer
    sta MenuTextPtr                   ;
    lda @Strings+1,x                  ;
    sta MenuTextPtr+1                 ;
    lda #5                            ; set fixed string length
    sta MenuTextLen                   ;
    jmp DrawValueString               ; and draw the string

@Strings:
.word @Str0
.word @Str1
.word @Str2
.word @Str3
.word @Str4
.word @Str5

@Str0: .byte "NONE "
@Str1: .byte " BIG "
@Str2: .byte "FIRE "
@Str3: .byte "NONE!"
@Str4: .byte " BIG!"
@Str5: .byte "FIRE!"
; ===========================================================================

; pointers to menu values
MenuValueLocationsLo: .lobytes MenuValueLocations
MenuValueLocationsHi: .hibytes MenuValueLocations
MenuTitleLocationsLo: .lobytes MenuTitleLocations
MenuTitleLocationsHi: .hibytes MenuTitleLocations

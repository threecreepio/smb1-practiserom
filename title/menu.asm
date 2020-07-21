
Title_Setup:
    jsr ReadJoypads ; read an extra time to prevent presses on the first frame
    inc OperMode_Task
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    ;sta PPU_CTRL_REG2

    lda #$3F
    sta PPU_ADDRESS
    lda #$00
    sta PPU_ADDRESS
    ldx #0
@WRITE_PAL:
    clc
    lda PALETTE,x
    sta PPU_DATA
    inx
    cpx #(PALETTEEND-PALETTE)
    bne @WRITE_PAL

    ldx #0
    lda #$20
    sta PPU_ADDRESS
    lda #$00
    sta PPU_ADDRESS
@WRITE_L1:
    lda BG_L1, x
    sta PPU_DATA
    inx
    bne @WRITE_L1
@WRITE_L2:
    lda BG_L2, x
    sta PPU_DATA
    inx
    bne @WRITE_L2
@WRITE_L3:
    lda BG_L3, x
    sta PPU_DATA
    inx
    bne @WRITE_L3
@WRITE_L4:
    lda BG_L4, x
    sta PPU_DATA
    inx
    bne @WRITE_L4

    ldy #0
    sty MenuSelectedItem
    jsr DrawSelectedValueJE
    iny
    sty MenuSelectedItem
    jsr DrawSelectedValueJE
    iny
    sty MenuSelectedItem
    jsr DrawSelectedValueJE
    iny
    sty MenuSelectedItem
    jsr DrawSelectedValueJE
    ldy #0
    sty MenuSelectedItem

    rts


TitleMain:
    jsr DrawSelectionMarkers
    lda PressedButtons
    clc
    cmp #0
    bne @READINPUT
    rts
@READINPUT:
    and #%00001111
    beq @SELECT
    jsr UpdateSelectedValueJE
    jmp RenderMenu
@SELECT:
    lda PressedButtons
    cmp #%00100000
    bne @START
    ldx #0
    stx MenuSelectedSubitem
    inc MenuSelectedItem
    lda MenuSelectedItem
    cmp #SettablesCount
    bne @SELECT2
    stx MenuSelectedItem
@SELECT2:
    jmp RenderMenu
@START:
    cmp #%00010000
    bne @DONE
    ldx HeldButtons
    cpx #%10000000
    lda #0
    bcc @START2
    lda #1
@START2:
    sta PrimaryHardMode
    jmp TStartGame
@DONE:
    rts
RenderMenu:
    jsr DrawSelectedValueJE
    rts



UpdateSelectedValueJE:
    lda MenuSelectedItem
    jsr JumpEngine
    .word UpdateValueNormal
    .word UpdateValueNormal
    .word UpdateValueNormal
    .word UpdateValueFramerule

DrawSelectedValueJE:
    ldy MenuSelectedItem
    tya
    jsr JumpEngine
    .word DrawValueNormal
    .word DrawValueNormal
    .word DrawValueNormal
    .word DrawValueFramerule

UpdateValueNormal:
    clc
    ldy MenuSelectedItem
    lda PressedButtons
    and #%000110
    bne @Decrement
@Increment:
    lda Settables, y
    adc #1
    cmp MaxSettableValues, y
    bcc @Store
    lda #0
    bvc @Store
@Decrement:
    lda Settables, y
    beq @Wrap
    sbc #0
    bvc @Store
@Wrap:
    lda MaxSettableValues, y
    sbc #0
@Store:
    sta Settables, y

DrawValueNormal:
    clc
    ldy MenuSelectedItem
    lda VRAM_Buffer1_Offset
    tax
    adc #4
    sta VRAM_Buffer1_Offset
    lda SettableRenderLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda SettableRenderLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #1
    sta VRAM_Buffer1+2, x
    lda Settables, y
    adc #1
    sta VRAM_Buffer1+3, x
    lda #0
    sta VRAM_Buffer1+4, x
    rts


DrawSelectionMarkers:
    ; set y position
    lda #$1E
    ldy MenuSelectedItem
@Increment:
    clc
    adc #$10
    dey
    bpl @Increment
    sta Sprite_Y_Position + (1 * SpriteLen)
    adc #$6
    sta Sprite_Y_Position + (2 * SpriteLen)
    ; set x position
    lda #$A8
    sta Sprite_X_Position + (1 * SpriteLen)
    sbc #$8
    ldy MenuSelectedSubitem
@Decrement:
    clc
    sbc #$7
    dey
    bpl @Decrement
    sta Sprite_X_Position + (2 * SpriteLen)
    lda #$CE
    sta Sprite_Tilenumber + (1 * SpriteLen)
    lda #$00
    sta Sprite_Attributes + (1 * SpriteLen)
    lda #$8A
    sta Sprite_Tilenumber + (2 * SpriteLen)
    lda #$21
    sta Sprite_Attributes + (2 * SpriteLen)
    rts










SelectedDigit = $700

UpdateValueFramerule:
    clc
    ldx MenuSelectedSubitem
    lda PressedButtons
    and #%00000011
    beq @update_value

    lda PressedButtons
    cmp #%00000001 ; right
    bne @check_left
    dex
@check_left:
    cmp #%00000010 ; left
    bne @store_selected
    inx
@store_selected:
    txa
    bpl @not_under
    lda #3
@not_under:
    cmp #4
    bcc @not_over
    lda #0
@not_over:
    sta MenuSelectedSubitem
    rts
@update_value:
    lda MathFrameruleDigitStart, x
    tay
    lda PressedButtons
    cmp #%00001000
    beq @increase
    dey
    bpl @store_value
    ldy #8
@increase:
    iny
    cpy #$A
    bne @store_value
    ldy #0
@store_value:
    tya
    sta MathFrameruleDigitStart, x

DrawValueFramerule:
    clc
    ldy MenuSelectedItem
    lda VRAM_Buffer1_Offset
    tax
    adc #7
    sta VRAM_Buffer1_Offset
    lda SettableRenderLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda SettableRenderLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #4
    sta VRAM_Buffer1+2, x
    lda MathFrameruleDigitStart+0
    sta VRAM_Buffer1+3+3, x
    lda MathFrameruleDigitStart+1
    sta VRAM_Buffer1+3+2, x
    lda MathFrameruleDigitStart+2
    sta VRAM_Buffer1+3+1, x
    lda MathFrameruleDigitStart+3
    sta VRAM_Buffer1+3+0, x
    lda #0
    sta VRAM_Buffer1+3+4, x
    rts

    ldy MenuSelectedItem
    lda SettableRenderLocationsHi, y
    sta PPU_ADDRESS
    lda SettableRenderLocationsLo, y
    sta PPU_ADDRESS
    lda MathFrameruleDigitStart+0
    sta PPU_DATA
    lda MathFrameruleDigitStart+1
    sta PPU_DATA
    lda MathFrameruleDigitStart+2
    sta PPU_DATA
    lda MathFrameruleDigitStart+3
    sta PPU_DATA
    rts

.define SettableRenderLocations $20D3, $2113, $2153, $2190
SettableRenderLocationsLo: .lobytes SettableRenderLocations
SettableRenderLocationsHi: .hibytes SettableRenderLocations

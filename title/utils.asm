B10Add:
    adc MathDigits,x
    sta MathDigits,x
B10Carry:
    lda #9
    cmp MathDigits,x
    bcc @B10CarryOne
    cmp MathDigits+1,x
    bcc @B10NextCarry
    rts
@B10NextCarry:
    inx
@B10CarryOne:
    lda MathDigits,x
    clc
    sbc #9
    sta MathDigits,x
    inc MathDigits+1,x
    bvc B10Carry
    rts


B10DivBy10:
    ldx #$00
@Continue:
    cmp #$0a
    bcc @Done
    sbc #$0a
    inx
    sec
    bcs @Continue
@Done:
    rts

WriteVRAMBufferToScreen:
    lda VRAM_Buffer1_Offset
    beq @Skip
    ldy #>(VRAM_Buffer1)
    sty $1
    ldy #<(VRAM_Buffer1)
    sty $0
    ldy #0
@KeepWriting:
    jsr WriteBufferPtrToScreen
    lda ($0),y
    beq @Done
    clc
    tya
    adc $0
    sta $0
    lda $1
    adc #$0
    sta $1
    ldy #0
    bvc @KeepWriting
@Done:
    lda #0
    sta VRAM_Buffer1
    sta VRAM_Buffer1_Offset
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
@Skip:
    rts

WriteBufferPtrToScreen:
    lda ($0),y
    cmp #$1F
    bcc @Done
    sta PPU_ADDRESS
    iny
    lda ($0),y
    sta PPU_ADDRESS
    iny
    lda ($0),y
    tax
    beq @Done
@Continue:
    iny
    lda ($0),y
    sta PPU_DATA
    dex
    bne @Continue
    iny
@Done:
    rts

ReadJoypadsCurrent:
    lda #$01
    sta JOYPAD_PORT
    sta HeldButtons
    lsr a
    sta JOYPAD_PORT
@KeepReading:
    lda JOYPAD_PORT
    lsr a
    rol HeldButtons
    bcc @KeepReading
    rts

ReadJoypads:
    jsr ReadJoypadsCurrent
    lda HeldButtons
    eor #%11111111
    and LastReadButtons
    sta ReleasedButtons
    lda LastReadButtons
    eor #%11111111
    and HeldButtons
    sta PressedButtons
    lda HeldButtons
    sta LastReadButtons
    rts

JumpEngine:
    sty $00
    asl          ;shift bit from contents of A
    tay
    pla          ;pull saved return address from stack
    sta $04      ;save to indirect
    pla
    sta $05
    iny
    lda ($04),y  ;load pointer from indirect
    sta $06      ;note that if an RTS is performed in next routine
    iny          ;it will return to the execution before the sub
    lda ($04),y  ;that called this routine
    sta $07
    dey
    dey
    tya
    ldy $00
    jmp ($06)    ;jump to the address we loaded


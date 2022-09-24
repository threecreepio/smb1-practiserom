
; ===========================================================================
;  Base 10 addition
; ---------------------------------------------------------------------------
; Input:
;   X - offset into base10 value list to add
;   A - value to add
; ---------------------------------------------------------------------------
B10Add:
    clc                        ;
    adc MathDigits,x           ; add value to digit
    sta MathDigits,x           ; store result
:   cmp #10                    ; compare against 10
    bcc @Done                  ; if less than 10, we're done
    lda #0                     ; otherwise, set to 0
    sta MathDigits,x           ; store result
    inx                        ; move to next digit
    bmi @Done                  ; if no more digits, we're done
    lda MathDigits,x           ; get next digit
    adc #0                     ; add our carry
    sta MathDigits,x           ; store result
    bcc :-                     ; and keep going until we don't have a carry
@Done:                         ;
    rts                        ;
; ===========================================================================

; ===========================================================================
;  Divide A value by 10
; ---------------------------------------------------------------------------
;  Example:
;  lda #145
;  jsr B10DivideBy10
;  ; A = 5   (remainder)
;  ; X = 14  (quotient)
; ---------------------------------------------------------------------------
B10DivBy10:
    ldx #$00                  ; clear result
:   cmp #$0a                  ; compare current value against 10
    bcc @Done                 ; if lower, then we are finished
    sbc #$0a                  ; otherwise subtract 10
    inx                       ; and increment result
    bne :-                    ; keep looping
@Done:                        ;
    rts                       ; done
; ===========================================================================

; ================================================================
;  6502 multiply by 10
; ----------------------------------------------------------------
MultiplyBy10:
    asl                       ; multiply by 2
    sta $0                    ; store in temp value
    asl                       ; multiply by 4
    asl                       ;
    clc                       ;
    adc $0                    ; add temp value, so, (A*2*4)+(A*2)
    rts                       ; done
; ================================================================

;; copied code from smb1
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


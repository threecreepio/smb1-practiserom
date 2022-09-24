; # MMC1 Startup code
;
; This is used for normal level hacks.
;

; include the menu screen
.include "title.asm"

.segment "INES"
INES_MAPPER = 1 << 4
INES_BATTERY = %00000010
INES_VERTICAL_MIRROR = %00000001
; MMC1 INES header
.byte $4E,$45,$53,$1A ; NES
.byte 16              ; prg banks
.byte 1               ; chr banks
.byte INES_MAPPER | INES_BATTERY | INES_VERTICAL_MIRROR

.segment "PRACTISE_PRG1"
; ================================================================
;  Boot game into title screen
; ----------------------------------------------------------------
ColdTitleReset:
    sei                  ; 6502 init
    cld                  ;
    ldx #$FF             ;
    txs                  ; clear stack
    stx $8000            ; reset mapper
    lda #BANKNR_TITLE    ; set initial prg bank to title screen
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    lda #0               ; set initial chr bank
    sta $A000            ;
    lsr                  ;
    sta $A000            ;
    lsr                  ;
    sta $A000            ;
    lsr                  ;
    sta $A000            ;
    lsr                  ;
    sta $A000            ;
    lda #$2              ; enable bankswitching
    sta $8000            ;
    lsr                  ;
    sta $8000            ;
    lsr                  ;
    sta $8000            ;
    lsr                  ;
    sta $8000            ;
    lsr                  ;
    sta $8000            ;
    jmp TitleResetInner  ; and prepare the title screen
; ================================================================

; the following code is copied to battery backed ram
.segment "PRACTISE_WRAMCODE"
; ================================================================
;  Handle loading new level banks
; ----------------------------------------------------------------
BANK_LEVELBANK_RTS:
    rts                  ; this is not done for simple romhacks
; ================================================================

; ================================================================
;  Load into game bank and return control
; ----------------------------------------------------------------
BANK_GAME_RTS:
    pha                  ; push our current A value to not disturb it
    lda #0               ; get the bank with the game
    jmp BANK_RTS         ; and load it
; ================================================================

; ================================================================
;  Load into title screen and return control
; ----------------------------------------------------------------
BANK_TITLE_RTS:
    pha                  ; push our current A value to not disturb it
    lda #BANKNR_TITLE    ; get the bank with the title screen
    jmp BANK_RTS         ; and load it
; ================================================================

; ================================================================
;  Load into 'A' bank and return control
; ----------------------------------------------------------------
BANK_RTS:
    sta $E000            ; MMC1 bankswitching to A
    lsr                  ;
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    lsr                  ;
    sta $E000            ;
    pla                  ; restore previous A value
    rts                  ; and return
; ================================================================

; interrupt handlers
.segment "PRACTISE_VEC"
.word TitleNMI
.word ColdTitleReset
.word $ff00

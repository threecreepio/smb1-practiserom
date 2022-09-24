; # GreatEd Startup code
;
; This is used for hacks made with greated
;

.segment "PRACTISE_PRG0"
TitleReset2:
    lda #%10000000     ; enable battery backed wram
    sta $A001          ;
; include title file
.include "title.asm"

.segment "INES"
; MMC3 INES header
INES_MAPPER = 4 << 4
INES_BATTERY = %00000010
INES_VERTICAL_MIRROR = %00000001
.byte $4E,$45,$53,$1A ; NES
.byte 9               ; prg banks
.byte 1               ; chr banks
.byte INES_MAPPER | INES_BATTERY | INES_VERTICAL_MIRROR

;.segment "PRACTISE_PRG0"
;TitleMMC3NMI:
;    jsr BANK_GAME_RTS
;    jmp RELOCATE_NonMaskableInterrupt

.segment "PRACTISE_PRG2"
; ================================================================
;  Boot game into title screen
; ----------------------------------------------------------------
ColdTitleReset:
    sei                       ; 6502 init
    cld                       ;
    ldx #$FF                  ; clear stack
    txs                       ;
    lda #$10                  ; init greated mapper state
    ldx #$06                  ;
    stx $8000                 ;
    sta $8001                 ;
    jmp TitleReset2           ; and prepare the title screen
; ----------------------------------------------------------------

; the following code is copied to battery backed ram
.segment "PRACTISE_WRAMCODE"

;BANK_GAME_NMI:
;    lda IsPlaying
;    bne @InGameMode
;    jsr BANK_TITLE_RTS
;    jmp TitleNMI
;@InGameMode:
;    jsr BANK_GAME_RTS
;    jmp RELOCATE_NonMaskableInterrupt

; ================================================================
;  Handle loading new level banks
; ----------------------------------------------------------------
BANK_LEVELBANK_RTS:
    pha                     ; save whatever A value we were called with
    lda #7                  ; set mmc state
    sta $8000               ;
PATCHER_LDA_LEVELBANK = *   ; GreatEd stores the bank in varying locations
    lda $07F7               ; so this code is replaced at patch time
    sta $8001               ; set bank
    pla                     ; restore the A value we were called with
    rts                     ;
; ================================================================

; ================================================================
;  Load into game bank and return control
; ----------------------------------------------------------------
BANK_GAME_RTS:
    pha                     ; push our current A value to not disturb it
    lda #6                  ; set mmc3 state for game mode
    sta $8000               ;
    lda #0                  ;
    sta $8001               ;
    lda #7                  ;
    sta $8000               ;
    lda #1                  ;
    sta $8001               ;
    pla                     ; restore previous A value
    rts                     ;
; ================================================================

; ================================================================
;  Load into title screen and return control
; ----------------------------------------------------------------
BANK_TITLE_RTS:
    pha                     ; push our current A value to not disturb it
    lda #6                  ; set mmc3 state for title mode
    sta $8000               ;
    lda #$E                 ;
    sta $8001               ;
    lda #7                  ;
    sta $8000               ;
    lda #$F                 ;
    sta $8001               ;
    pla                     ; restore previous A value
    rts                     ;
; ================================================================

; interrupt handlers
.segment "PRACTISE_VEC"
.word TitleNMI
.word ColdTitleReset
.word $ff00

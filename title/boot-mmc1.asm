.segment "PRACTISE_PRG0"
TitleReset2:
.include "title.asm"

INES_MAPPER = 1 << 4
INES_BATTERY = %00000010
INES_VERTICAL_MIRROR = %00000001

.segment "INES"
.byte $4E,$45,$53,$1A ; NES
.byte 16 ; prg
.byte 1  ; chr
.byte INES_MAPPER | INES_BATTERY | INES_VERTICAL_MIRROR

.segment "PRACTISE_PRG1"
ColdTitleReset:
    sei
    cld
    ldx #$FF
    stx $8000
    txs

    ; set title screen bank
    lda #BANKNR_TITLE
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000

    ; set chr
    lda #0
    sta $A000
    lsr
    sta $A000
    lsr
    sta $A000
    lsr
    sta $A000
    lsr
    sta $A000

    ; enable bank switching
    lda #$2
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000

    ; title screen reset
    jmp TitleReset2

.segment "PRACTISE_WRAMCODE"
BANK_LEVELBANK_RTS:
    rts
BANK_STORE_RTS:
    sta PREVIOUS_BANK
BANK_GAME_RTS:
    pha
    lda PREVIOUS_BANK
    jmp BANK_RTS

BANK_TITLE_RTS:
    pha
    lda #BANKNR_TITLE

BANK_RTS:
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    pla
    rts

.segment "PRACTISE_VEC"
.word TitleNMI
.word ColdTitleReset
.word $ff00

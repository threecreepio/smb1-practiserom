.segment "PRACTISE_PRG0"
TitleReset2:
    ; enable battery backed wram
    lda #%10000000
    sta $A001
.include "title.asm"

INES_MAPPER = 4 << 4
INES_BATTERY = %00000010
INES_VERTICAL_MIRROR = %00000001

.segment "INES"
.byte $4E,$45,$53,$1A ; NES
.byte 9 ; prg
.byte 1  ; chr
.byte INES_MAPPER | INES_BATTERY | INES_VERTICAL_MIRROR

.segment "PRACTISE_PRG0"
TitleMMC3NMI:
    jsr BANK_GAME_RTS
    jmp RELOCATE_NonMaskableInterrupt

.segment "PRACTISE_PRG2"
ColdTitleReset:
    sei
    cld
    ldx #$FF
    txs
    lda #$10
    ldx #$06
    stx $8000
    sta $8001
    jmp TitleReset2

.segment "PRACTISE_WRAMCODE"

BANK_GAME_NMI:
    lda IsPlaying
    bne @InGameMode
    jsr BANK_TITLE_RTS
    jmp TitleNMI
@InGameMode:
    jsr BANK_GAME_RTS
    jmp RELOCATE_NonMaskableInterrupt

BANK_LEVELBANK_RTS:
    pha
    lda #7
    sta $8000
    ; GreatEd stores the bank in varying
    ; locations for SOME reason.. so this is
    ; replaced at patch time.
PATCHER_LDA_LEVELBANK = *
    lda $07F7
    sta $8001
    pla
    rts

BANK_STORE_RTS:
BANK_GAME_RTS:
    pha
    ; switch $8000 to SMB1
    lda #6
    sta $8000
    lda #0
    sta $8001
    lda #7
    sta $8000
    lda #1
    sta $8001
    pla
    rts

BANK_TITLE_RTS:
    pha
    lda #6
    sta $8000
    lda #$E
    sta $8001
    lda #7
    sta $8000
    lda #$F
    sta $8001
    pla
    rts

.segment "PRACTISE_VEC"
.word TitleNMI
.word ColdTitleReset
.word $ff00

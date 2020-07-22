.p02
.org $8000
.segment "TITLEPRG"
.include "ascii.asm"
.include "../const.inc"
.import GL_ENTER
.import GetAreaDataAddrs
.import LoadAreaPointer
.import OutputNumbers

;; header for wram, change this value to clear out wram
WRAMSaveHeader = $6000
ROMSaveHeader:
.byte "P200721"
ROMSaveHeaderLen = * - ROMSaveHeader - 1

;; these settings are intended to be changed by the patcher.
ROMSettings:
; max values for world, level, powerups
MaxSettableValues:
.byte $8
.byte $4
.byte $4







;; WRAM SPACE
HeldButtons = $60f0
ReleasedButtons = $60f2
LastReadButtons = $60f4
PressedButtons = $60f6
LevelEnding = $6101
LevelEndingITC = $6102
LevelStarting = $6103
PendingScoreDrawPosition = $6104
CachedITC = $6105
SettableTypes: .byte $0, $0, $0, $1
SettablesCount = $4
Settables = $7000
MenuSelectedItem = $7106
MenuSelectedSubitem = $7107
MathDigits = $7200
MathFrameruleDigitStart = $7200
MathFrameruleDigitEnd = MathFrameruleDigitStart + 5
MathInGameFrameruleDigitStart = MathFrameruleDigitEnd
MathInGameFrameruleDigitEnd = MathInGameFrameruleDigitStart + 5
;; $7E00-$7FFF -- relocated bank switching code (starts at 7FA4) 
RelocatedCodeLocation = $7E00

.res $C000 - *, $FF
ColdTitleReset:
TitleReset:
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
    lda #2
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000

    ldx #$00
    stx PPU_CTRL_REG1
    stx PPU_CTRL_REG2
    jsr InitializeMemory
    jsr ForceClearWRAM
    lda #8
    sta MathFrameruleDigitStart
:   lda PPU_STATUS
    bpl :-
HotReset2:
:   lda PPU_STATUS
    bpl :-
    jsr Title_Setup
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    lda #%10011000
    sta Mirror_PPU_CTRL_REG1
    sta PPU_CTRL_REG1
:   jmp :- ; infinite loop until NMI

HotReset:
    jsr InitializeMemory
    jsr InitBankSwitchingCode
    jmp HotReset2

TitleNMI:
    lda Mirror_PPU_CTRL_REG1  ;disable NMIs in mirror reg
    and #%01111111            ;save all other bits
    sta Mirror_PPU_CTRL_REG1
    sta PPU_CTRL_REG1

    bit PPU_STATUS
    jsr WriteVRAMBufferToScreen
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG

    lda #$02
    sta SPR_DMA

    jsr ReadJoypads
    jsr TitleMain       ; run title application

    lda #%00011010
    sta PPU_CTRL_REG2
    lda Mirror_PPU_CTRL_REG1
    ora #%10000000            ;reactivate NMIs
    sta Mirror_PPU_CTRL_REG1
    sta PPU_CTRL_REG1
    rti                       ;we are done until the next frame!

RestoreScroll:
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    rts

TitleMoveSpritesOffscreen:
    ldy #$04                ;this routine moves all but sprite 0
    lda #$f8                ;off the screen
@SprInitLoop:
    sta Sprite_Y_Position,y ;write 248 into OAM data's Y coordinate
    iny                     ;which will move it off the screen
    iny
    iny
    iny
    bne @SprInitLoop
    rts

InitializeMemory:
    ldx #0
    lda #0
@clear:
    sta $0000, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    sta $6000, x
    sta $6100, x
    sta $6200, x
    sta $6300, x
    inx
    bne @clear
    rts

InitializeWRAM:
    ldx #ROMSaveHeaderLen
@Verify:
    lda ROMSaveHeader, x
    cmp WRAMSaveHeader, x
    bne ForceClearWRAM
    dex
    bpl @Verify
    rts

ForceClearWRAM:
    lda #$60
    sta $1
    ldy #0
    sty $0
    ldx #$80
    lda #$00
@keep_copying:
    sta ($0),y
    iny
    bne @keep_copying
    ldy #0
    inc $1
    cpx $1
    bne @keep_copying
    ldx #ROMSaveHeaderLen
@Sign:
    lda ROMSaveHeader, x
    sta WRAMSaveHeader, x
    dex
    bpl @Sign
    rts

.include "practise.asm"
.include "menu.asm"
.include "utils.asm"
.include "background.asm"
.include "bankswitching.asm"
.include "rng.asm"

.res $FFFA - *, $FF
.word TitleNMI
.word ColdTitleReset
.word ColdTitleReset

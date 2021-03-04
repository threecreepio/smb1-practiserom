.p02
.linecont +
.include "ascii.asm"
.include "../const.inc"
.import GL_ENTER
.import GetAreaDataAddrs
.import LoadAreaPointer
.import PlayerEndWorld
.import NonMaskableInterrupt

;; WRAM SPACE
.segment "TEMPWRAM"
WRAMSaveHeader: .byte $00, $00, $00, $00, $00
HeldButtons: .byte $00
ReleasedButtons: .byte $00
LastReadButtons: .byte $00
PressedButtons: .byte $00
CachedChangeAreaTimer: .byte $00
LevelEnding: .byte $00
IsPlaying: .byte $00
EnteringFromMenu: .byte $00
PendingScoreDrawPosition: .byte $00
CachedITC: .byte $00
PREVIOUS_BANK: .byte $00

.segment "MENUWRAM"
MathDigits:
MathFrameruleDigitStart:
  .byte $00, $00, $00, $00, $00 ; selected framerule
MathFrameruleDigitEnd:
MathInGameFrameruleDigitStart:
  .byte $00, $00, $00, $00, $00 ; ingame framerule
MathInGameFrameruleDigitEnd:

;; $7E00-$7FFF -- relocated bank switching code (starts at 7FA4) 
RelocatedCodeLocation = $7E00

.segment "PRACTISE_PRG0"
TitleReset3:
    ldx #$00
    stx PPU_CTRL_REG1
    stx PPU_CTRL_REG2
    jsr InitializeMemory
    jsr ForceClearWRAM
    lda #9
    sta MathFrameruleDigitStart
:   lda PPU_STATUS
    bpl :-
HotReset2:
    ldx #$00
    stx PPU_CTRL_REG1
    stx PPU_CTRL_REG2
    ldx #$FF
    txs
:   lda PPU_STATUS
    bpl :-
    jsr InitBankSwitchingCode
    jsr ReadJoypads     ; read here to prevent a held button at startup from registering
    jsr PrepareScreen   ; load in palette and background
    jsr MenuReset
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    lda #%10011000
    sta Mirror_PPU_CTRL_REG1
    sta PPU_CTRL_REG1
:   jmp :- ; infinite loop until NMI

HotReset:
    lda #0
    sta SND_MASTERCTRL_REG
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
    sta IsPlaying
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    lda #$02
    sta SPR_DMA
    jsr ReadJoypads
    jsr MenuNMI
    lda #%00011010
    sta PPU_CTRL_REG2
    lda Mirror_PPU_CTRL_REG1
    ora #%10000000            ;reactivate NMIs
    sta Mirror_PPU_CTRL_REG1
    sta PPU_CTRL_REG1
    rti                       ;we are done until the next frame!

PrepareScreen:
    ; copy palettes
    lda #$3F
    sta PPU_ADDRESS
    lda #$00
    sta PPU_ADDRESS
    ldx #0
@CopyPaletteData:
    clc
    lda MenuPalette,x
    sta PPU_DATA
    inx
    cpx #(MenuPaletteEnd-MenuPalette)
    bne @CopyPaletteData
    ; copy background
    ldx #0
    ldy #0
    lda #$20
    sta PPU_ADDRESS
    stx PPU_ADDRESS

@WriteNextPage:
    lda MenuBackground+1, x
    beq @DoneDrawingMenu
    sta $1
    lda MenuBackground, x
    sta $0
@WriteNextCharacter:
    lda ($0), y
    sta PPU_DATA
    iny
    bne @WriteNextCharacter
    inx
    inx
    bne @WriteNextPage
@DoneDrawingMenu:
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

ROMSaveHeader:
.byte $03, $20, $07, $21, $03
ROMSaveHeaderLen = * - ROMSaveHeader - 1

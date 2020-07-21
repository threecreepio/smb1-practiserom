.p02
.org $8000
.segment "TITLEPRG"
.include "ascii.asm"
.include "../const.inc"
.import GL_ENTER
.import GetAreaDataAddrs
.import LoadAreaPointer


MenuSelectedItem = $40
MenuSelectedSubitem = $41

;; WRAM SPACE
;; $6000-$6001 -- version header
HeldButtons = $60f0
ReleasedButtons = $60f2
LastReadButtons = $60f4
PressedButtons = $60f6

SettablesCount = $4
Settables = $7100
MaxSettableValues: .byte $F, $F, $4

LevelEnding = $7001
LevelEndingITC = $7002
LevelStarting = $7003
MathDigits = $7200
MathFrameruleDigitStart = $7200
MathFrameruleDigitEnd = MathFrameruleDigitStart + 5
MathInGameFrameruleDigitStart = MathFrameruleDigitEnd
MathInGameFrameruleDigitEnd = MathInGameFrameruleDigitStart + 5
 
;; $7E00-$7FFF -- relocated bank switching code (starts at 7FA4) 
RelocatedCodeLocation = $8000 - (RelocatedCode_End - RelocatedCode_Start)

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
@clear:
    lda #$00
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
    bne @clear;
    rts

.include "practise.asm"



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
    ; copy bank switching code into wram so it's
    ; useable from the original game without too many modifications
    jsr InitBankSwitchingCode
:   lda PPU_STATUS
    bpl :-
:   lda PPU_STATUS
    bpl :-
HotReset2:
    jsr Title_Setup
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    lda #%00011010
    sta PPU_CTRL_REG2
    lda #%10011000
    sta Mirror_PPU_CTRL_REG1
    sta PPU_CTRL_REG1
:   jmp :- ; infinite loop until NMI

HotReset:
    jsr InitializeMemory
    jsr InitBankSwitchingCode
    jmp HotReset2

.include "menu.asm"
.include "utils.asm"
.include "background.asm"
.include "bankswitching.asm"
.include "rng.asm"

.res $FFFA - *, $FF
.word TitleNMI
.word ColdTitleReset
.word ColdTitleReset

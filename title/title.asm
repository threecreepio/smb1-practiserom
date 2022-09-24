; # Main menu screen code
;
; This contains all the code used for the practise rom.
;
; It is included from the "boot" files.
;

.p02
.linecont +
.include "ascii.asm"
.include "../const.inc"

; import some pointers from the smb rom
.import GL_ENTER
.import GetAreaDataAddrs
.import LoadAreaPointer
.import PlayerEndWorld
.import NonMaskableInterrupt

; Temporary WRAM space
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

; Persistent WRAM space
.segment "MENUWRAM"
MathDigits:
MathFrameruleDigitStart:
  .byte $00, $00, $00, $00, $00 ; selected framerule
MathFrameruleDigitEnd:
MathInGameFrameruleDigitStart:
  .byte $00, $00, $00, $00, $00 ; ingame framerule
MathInGameFrameruleDigitEnd:

; $7E00-$7FFF - relocated bank switching code
RelocatedCodeLocation = $7E00

.segment "PRACTISE_PRG0"
; ================================================================
;  Full reset of title screen
; ----------------------------------------------------------------
TitleResetInner:
    ldx #$00                           ; disable ppu
    stx PPU_CTRL_REG1                  ;
    stx PPU_CTRL_REG2                  ;
    jsr InitializeMemory               ; clear memory
    jsr ForceClearWRAM                 ; clear all wram state
    lda #8                             ; set starting framerule
    sta MathFrameruleDigitStart        ;
:   lda PPU_STATUS                     ; wait for vblank
    bpl :-                             ;
HotReset2:                             ;
    ldx #$00                           ; disable ppu again (this is called when resetting to the menu)
    stx PPU_CTRL_REG1                  ;
    stx PPU_CTRL_REG2                  ;
    ldx #$FF                           ; clear stack
    txs                                ;
:   lda PPU_STATUS                     ; wait for vblank
    bpl :-                             ;
    jsr InitBankSwitchingCode          ; copy bankswitching code to wram
    jsr ReadJoypads                    ; read controller to prevent a held button at startup from registering
    jsr PrepareScreen                  ; load in palette and background
    jsr MenuReset                      ; reset main menu
    lda #0                             ; clear scroll registers
    sta PPU_SCROLL_REG                 ;
    sta PPU_SCROLL_REG                 ;
    lda #%10011000                     ; enable ppu
    sta Mirror_PPU_CTRL_REG1           ;
    sta PPU_CTRL_REG1                  ;
:   jmp :-                             ; infinite loop until NMI
; ================================================================

; ================================================================
;  Hot reset back to the title screen
; ----------------------------------------------------------------
HotReset:
    lda #0                             ; kill any playing sounds
    sta SND_MASTERCTRL_REG             ;
    jsr InitializeMemory               ; clear memory
    jmp HotReset2                      ; then jump to the shared reset code
; ================================================================

; ================================================================
;  Handle NMI interrupts while in the title screen
; ----------------------------------------------------------------
TitleNMI:
    lda Mirror_PPU_CTRL_REG1           ; disable nmi
    and #%01111111                     ;
    sta Mirror_PPU_CTRL_REG1           ; and update ppu state
    sta PPU_CTRL_REG1                  ;
    bit PPU_STATUS                     ; flip ppu status
    jsr WriteVRAMBufferToScreen        ; write any pending vram updates
    lda #0                             ; disable playing state
    sta IsPlaying                      ;
    sta PPU_SCROLL_REG                 ; clear scroll registers
    sta PPU_SCROLL_REG                 ;
    lda #$02                           ; copy sprites
    sta SPR_DMA                        ;
    jsr ReadJoypads                    ; read controller state
    jsr MenuNMI                        ; and run menu code
    lda #%00011010                     ; set ppu mask state for menu
    sta PPU_CTRL_REG2                  ;
    lda Mirror_PPU_CTRL_REG1           ; get ppu mirror state
    ora #%10000000                     ; and reactivate nmi
    sta Mirror_PPU_CTRL_REG1           ; update ppu state
    sta PPU_CTRL_REG1                  ;
    rti                                ; and we are done for the frame

; ================================================================
;  Sets up the all the fixed graphics for the title screen
; ----------------------------------------------------------------
PrepareScreen:
    lda #$3F                           ; move ppu to palette memory
    sta PPU_ADDRESS                    ;
    lda #$00                           ;
    sta PPU_ADDRESS                    ;
    ldx #0                             ;
:   lda MenuPalette,x                  ; and copy the menu palette
    sta PPU_DATA                       ;
    inx                                ;
    cpx #(MenuPaletteEnd-MenuPalette)  ;
    bne :-                             ;
    lda #$20                           ; move ppu to nametable 0
    sta PPU_ADDRESS                    ;
    ldx #0                             ;
    stx PPU_ADDRESS                    ;
:   lda BGDATA+$000,x                  ; and copy every page of menu data
    sta PPU_DATA                       ;
    inx                                ;
    bne :-                             ;
:   lda BGDATA+$100,x                  ;
    sta PPU_DATA                       ;
    inx                                ;
    bne :-                             ;
:   lda BGDATA+$200,x                  ;
    sta PPU_DATA                       ;
    inx                                ;
    bne :-                             ;
:   lda BGDATA+$300,x                  ;
    sta PPU_DATA                       ;
    inx                                ;
    bne :-                             ;
    rts                                ;
; ================================================================

; ================================================================
;  Clear RAM and temporary WRAM
; ----------------------------------------------------------------
InitializeMemory:
    lda #0                             ; clear A and X
    ldx #0                             ;
:   sta $0000,x                        ; clear relevant memory addresses
    sta $0200,x                        ;
    sta $0300,x                        ;
    sta $0400,x                        ;
    sta $0500,x                        ;
    sta $0600,x                        ;
    sta $0700,x                        ;
    sta $6000,x                        ;
    inx                                ; and loop for 256 bytes
    bne :-                             ;
    rts                                ;
; ================================================================

; ================================================================
;  Reinitialize WRAM if needed
; ----------------------------------------------------------------
InitializeWRAM:
    ldx #ROMSaveHeaderLen              ; get length of the magic wram header
:   lda ROMSaveHeader,x                ; check every byte of the header
    cmp WRAMSaveHeader,x               ; does it match?
    bne ForceClearWRAM                 ; no - clear wram
    dex                                ; yes - check next byte
    bpl :-                             ;
    rts                                ;
; ================================================================

; ================================================================
;  Clear WRAM state
; ----------------------------------------------------------------
ForceClearWRAM:
    @Ptr = $0
    lda #$60                           ; set starting address to $6000
    sta @Ptr+1                         ;
    ldy #0                             ;
    sty @Ptr+0                         ;
    ldx #$80                           ; and mark ending address at $8000
    lda #$00                           ; clear A
:   sta (@Ptr),y                       ; clear one byte of WRAM
    iny                                ; and advance
    bne :-                             ; for 256 bytes
    inc @Ptr+1                         ; then advance to the next page
    cpx @Ptr+1                         ; check if we are at the ending page
    bne :-                             ; no - keep clearing data
    ldx #ROMSaveHeaderLen              ; otherwise copy the magic wram header
:   lda ROMSaveHeader,x                ;
    sta WRAMSaveHeader,x               ;
    dex                                ;
    bpl :-                             ;
    rts                                ;
; ================================================================

; include all of the relevant title files
.include "practise.asm"
.include "menu.asm"
.include "utils.asm"
.include "background.asm"
.include "bankswitching.asm"
.include "rng.asm"

; magic save header for WRAM
ROMSaveHeader:
.byte $03, $20, $07, $21, $03
ROMSaveHeaderEnd:
ROMSaveHeaderLen = ROMSaveHeaderEnd-ROMSaveHeader

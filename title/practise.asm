
StatusSizes:
.byte $1, $0, $0, $1
StatusPowers:
.byte $0, $1, $2, $2

TStartGame:
    ldx #(MathFrameruleDigitEnd - MathFrameruleDigitStart)
@KeepCopying:
    lda MathFrameruleDigitStart, x
    sta MathInGameFrameruleDigitStart, x
    dex
    bpl @KeepCopying
    clc
    
    lda #%00000000
    sta PPU_CTRL_REG1
    sta Mirror_PPU_CTRL_REG1
    lda #%00000000
    sta PPU_CTRL_REG2

    lda #1
    sta LevelStarting

    lda #$00
    sta $4015
    lda #Silence             ;silence music
    sta EventMusicQueue

    ldx Settables
    stx WorldNumber
    ldx Settables+1
    stx LevelNumber

    ldx Settables+2
    lda StatusSizes,x
    sta PlayerSize
    lda StatusPowers,x
    sta PlayerStatus

    lda #$7F
    sta NumberofLives

    inc FetchNewGameTimerFlag ;set game timer flag to reload

    ; set the startup mode to enter the game immediately
    lda #1
    sta OperMode
    lda #0
    sta OperMode_Task
    sta GameEngineSubroutine
    sta TimerControl          ;also set flag for timers to count again
    sta GameEngineSubroutine  ;reset task for game core
    jmp BANK_AdvanceToLevel




PractiseNMI:
    lda LevelStarting
    bne @Next
    lda #$14
    cmp IntervalTimerControl
    bne @CheckForRestartLevel
    clc
    lda #1
    ldx #(MathInGameFrameruleDigitStart - MathDigits)
    jsr B10Add

@CheckForRestartLevel:
    lda JoypadBitMask
    and #(Select_Button | Start_Button)
    beq @Next
    lda HeldButtons
    jsr ReadJoypads

    cmp #(Up_Dir | Select_Button)
    bne @CheckForReset
    lda #0
    sta PPU_CTRL_REG1
    sta PPU_CTRL_REG2
    jsr InitializeMemory
    jmp TStartGame
@CheckForReset:
    cmp #(Down_Dir | Select_Button)
    bne @CheckForNext
    lda #0
    sta PPU_CTRL_REG1
    sta PPU_CTRL_REG2
    jmp HotReset
@CheckForNext:
@Next:


    rts

PractiseWriteBottomStatusLine:
    jsr PractisePrintScore
PractiseWriteBottomStatusLine2:
    ldx VRAM_Buffer1_Offset
    lda #$20                ;write address for world-area number on screen
    sta VRAM_Buffer1,x
    lda #$73
    sta VRAM_Buffer1+1,x
    lda #$03                ;write length for it
    sta VRAM_Buffer1+2,x
    ldy WorldNumber         ;first the world number
    iny
    tya
    sta VRAM_Buffer1+3,x
    lda #$28                ;next the dash
    sta VRAM_Buffer1+4,x
    jsr LoadIntervalTimerControlForStatusLine
    sta VRAM_Buffer1+5,x    
    lda #$00                ;put null terminator on
    sta VRAM_Buffer1+6,x
    txa                     ;move the buffer offset up by 6 bytes
    clc
    adc #$06
    sta VRAM_Buffer1_Offset

    inc ScreenRoutineTask
    rts


PractisePrintScoreLen = 12
PractiseEnterStage:
    lda LevelStarting
    beq @Done
    clc
    lda FrameCounter
    sbc #5
    sta FrameCounter
    jsr RNGQuickResume
    lda #0
    sta LevelStarting
@Done:
    lda #0
    sta LevelEnding

PractisePrintScore:
    clc
    ldy VRAM_Buffer1_Offset
    lda #$20                ;write address for world-area number on screen
    sta VRAM_Buffer1,y
    lda #$63
    sta VRAM_Buffer1+1,y
    lda #PractisePrintScoreLen                ;write length for it
    sta VRAM_Buffer1+2,y
    lda #$00                ;put null terminator on
    sta VRAM_Buffer1+3+PractisePrintScoreLen,y
    lda #$2E
    sta VRAM_Buffer1+3+8, y
    lda #$24
    sta VRAM_Buffer1+3+7, y
    sta VRAM_Buffer1+3+6, y
    sta VRAM_Buffer1+3+5, y

    sta VRAM_Buffer1+3+0, y
    lda MathInGameFrameruleDigitStart+3
    sta VRAM_Buffer1+3+1, y
    lda MathInGameFrameruleDigitStart+2
    sta VRAM_Buffer1+3+2,y
    lda MathInGameFrameruleDigitStart+1
    sta VRAM_Buffer1+3+3,y
    lda MathInGameFrameruleDigitStart+0
    sta VRAM_Buffer1+3+4,y

    lda FrameCounter
    jsr B10DivBy10
    sta VRAM_Buffer1+3+11, y
    txa
    jsr B10DivBy10
    sta VRAM_Buffer1+3+10, y
    txa
    sta VRAM_Buffer1+3+9, y

    tya
    adc #(3+PractisePrintScoreLen)
    sta VRAM_Buffer1_Offset
@PractisePrintScoreRTS:
    ldx ObjectOffset
    rts

PractiseDelayToAreaEnd:
    lda #1
    sta LevelEnding
    lda IntervalTimerControl
    sta LevelEndingITC
    rts

LoadIntervalTimerControlForStatusLine:
    lda LevelEnding
    beq @UseITC
    lda LevelEndingITC
    rts
@UseITC:
    lda IntervalTimerControl
    rts

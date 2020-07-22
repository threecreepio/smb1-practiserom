
StatusSizes:
.byte $1, $0, $0, $1
StatusPowers:
.byte $0, $1, $2, $2

PendingScoreDrawPosition = $7200

TStartGame:
    ; copy bank switching code into wram so the game can call back
    ; to the practise rom!
    jsr InitBankSwitchingCode

    ldx #(MathFrameruleDigitEnd - MathFrameruleDigitStart)
@KeepCopying:
    lda MathFrameruleDigitStart, x
    sta MathInGameFrameruleDigitStart, x
    dex
    bpl @KeepCopying
    clc
    
    lda #%00000000
    sta PendingScoreDrawPosition
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

    ; update framerule counter
    lda #$14
    cmp IntervalTimerControl
    bne @ClearPractisePrintScore
    clc
    lda #1
    ldx #(MathInGameFrameruleDigitStart - MathDigits)
    jsr B10Add

@ClearPractisePrintScore:
    ; check if the new status line has been printed
    jsr ClearPractisePrintScore

@CheckInput:
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

; print world number
PractiseWriteBottomStatusLine:
    jsr PractisePrintScore
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
@Done:
    inc ScreenRoutineTask
    rts


ClearPractisePrintScore:
    lda VRAM_Buffer1_Offset
    bne @SkipClear
    sta PendingScoreDrawPosition
@SkipClear:
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
    ; CONTINUE TO PRINT SCORE

; print framerules and frame counter
PractisePrintScore:
    ldy PendingScoreDrawPosition
    bne @RefreshBuffer

    ; set ppu address
    ldy VRAM_Buffer1_Offset
    lda #$20
    sta VRAM_Buffer1,y
    lda #$63
    sta VRAM_Buffer1+1,y

    ; write length of practise score
    lda #PractisePrintScoreLen
    sta VRAM_Buffer1+2,y

    ; put null terminator on
    lda #$00
    sta VRAM_Buffer1+3+PractisePrintScoreLen,y

    iny
    iny
    iny
    sty PendingScoreDrawPosition

    ; append length to buffer offset
    clc
    adc #(3+PractisePrintScoreLen)
    sta VRAM_Buffer1_Offset

    lda #$2E
    sta VRAM_Buffer1+8, y
    lda #$24
    sta VRAM_Buffer1+7, y
    sta VRAM_Buffer1+6, y
    sta VRAM_Buffer1+5, y
    sta VRAM_Buffer1+0, y
@RefreshBuffer:
    lda MathInGameFrameruleDigitStart+3
    sta VRAM_Buffer1+1,y
    lda MathInGameFrameruleDigitStart+2
    sta VRAM_Buffer1+2,y
    lda MathInGameFrameruleDigitStart+1
    sta VRAM_Buffer1+3,y
    lda MathInGameFrameruleDigitStart+0
    sta VRAM_Buffer1+4,y

    lda FrameCounter
    jsr B10DivBy10
    sta VRAM_Buffer1+11,y
    txa
    jsr B10DivBy10
    sta VRAM_Buffer1+10,y
    txa
    sta VRAM_Buffer1+9,y
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

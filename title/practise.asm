
;; Player size + power-up state depending on selected powerups
StatusSizes:
.byte $1, $0, $0, $0, $1, $1
StatusPowers:
.byte $0, $1, $2, $0, $1, $2

;; Load into the game from the menu
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
    sta EnteringFromMenu

    lda #$00
    sta $4015
    lda #Silence             ;silence music
    sta EventMusicQueue

    ldx SettablesWorld
    stx WorldNumber
    ldx SettablesLevel
    stx LevelNumber

    ldx SettablesPUP
    lda StatusSizes,x
    sta PlayerSize
    lda StatusPowers,x
    sta PlayerStatus

    lda #$2
    sta NumberofLives

    lda #$4
    sta IntervalTimerControl

    inc FetchNewGameTimerFlag ;set game timer flag to reload

    ; set the startup mode to enter the game immediately
    lda #1
    sta OperMode
    sta IsPlaying
    lda #0
    sta OperMode_Task
    sta GameEngineSubroutine
    sta TimerControl          ;also set flag for timers to count again
    sta GameEngineSubroutine  ;reset task for game core
    jmp BANK_AdvanceToLevel

CheckStarflag:
    lda LevelEnding
    bne @Done
    lda StarFlagTaskControl
    cmp #4
    bne @Done
    lda #1
    sta LevelEnding
    lda IntervalTimerControl
    sta CachedITC
    clc
    jsr ChangeTopStatusXToRemains
    jsr PractisePrintScore
@Done:
    rts

CheckAreaTimer:
    lda CachedChangeAreaTimer
    bne @Done
    lda ChangeAreaTimer
    beq @Done
    sta CachedChangeAreaTimer
    lda IntervalTimerControl
@Store2:
    sta CachedITC
    clc
    jsr ChangeTopStatusXToRemains
    jsr PractisePrintScore
@Done:
    rts

CheckJumpingState:
    lda JumpSwimTimer
    cmp #$20
    bne @Done
    jsr PractisePrintScore
@Done:
    rts

;; Game enters here at the start of every frame
PractiseNMI:
    lda EnteringFromMenu
    bne @Done
@ClearPractisePrintScore:
    ; check if the new status line has been printed
    lda VRAM_Buffer1_Offset
    bne @IncrementFrameruleCounter
    sta PendingScoreDrawPosition
@IncrementFrameruleCounter:
    jsr IncrementFrameruleCounter
    jsr CheckStarflag
    jsr CheckJumpingState
    jsr CheckAreaTimer
@CheckUpdateSockfolder:
    tya
    and #3
    cmp #2
    bne @CheckInput
    jsr UpdateSockfolder
@CheckInput:
    lda JoypadBitMask
    and #(Select_Button | Start_Button)
    beq @Done
    lda HeldButtons
    jsr ReadJoypads
@CheckForRestartLevel:
    cmp #(Up_Dir | Select_Button)
    bne @CheckForReset
    lda #0
    sta PPU_CTRL_REG1
    sta PPU_CTRL_REG2
    jsr InitializeMemory
    jmp TStartGame
@CheckForReset:
    cmp #(Down_Dir | Select_Button)
    bne @Done
    lda #0
    sta PPU_CTRL_REG1
    sta PPU_CTRL_REG2
    jmp HotReset
@Done:
    rts

IncrementFrameruleCounter:
    ; update framerule counter
    lda TimerControl
    bne @Done
    ldy IntervalTimerControl
    cpy #1
    bne @Done
    clc
    lda #1
    ldx #(MathInGameFrameruleDigitStart - MathDigits)
    jsr B10Add
@Done:
    rts

;; Game enters here when writing the "MARIO" / "TIME" text
;; at the top of the screen.
PractiseWriteTopStatusLine:
    lda #(TopStatusTextEnd-TopStatusText+1)
    tax
    adc VRAM_Buffer1_Offset
    ldy VRAM_Buffer1_Offset
    sta VRAM_Buffer1_Offset
    ldx #0
@CopyData:
    lda TopStatusText, x
    sta VRAM_Buffer1, y
    iny
    inx
    cpx #(TopStatusTextEnd-TopStatusText)
    bne @CopyData
    lda #0
    sta VRAM_Buffer1, y
    inc ScreenRoutineTask
    rts

TopStatusText:
  .byte $20, $43,  21, "RULE x SOCKS TO FRAME"
  .byte $20, $59,   4, "TIME"
  .byte $20, $73,   2, $2e, $29  ; coin that shows next to the coin counter
  .byte $23, $c0, $7f, $aa       ; tile attributes for the top row, sets palette
  .byte $23, $c4, $01, %11100000 ; set palette for the flashing coin
TopStatusTextEnd:
   .byte $00


;; Game enters here when updating the bottom status line
;; Which has the game score, coin counter, timer
PractiseWriteBottomStatusLine:
    lda LevelEnding
    bne @Done
    lda IntervalTimerControl
    sta CachedITC
@Done:
    jsr PractisePrintScore
    inc ScreenRoutineTask
    rts


;; Game enters here when a new level is loaded.
;; Used to clear some state and move sprite-0.
PractiseEnterStage:
    lda #3
    sta NumberofLives
    lda #152
    sta $203
    lda EnteringFromMenu
    beq @Done
    sec
    lda FrameCounter
    sbc #6
    sta FrameCounter
    jsr RNGQuickResume
    lda #0
    sta EnteringFromMenu
@Done:
    lda #0
    sta CachedChangeAreaTimer
    sta LevelEnding
    jsr PractisePrintScore
    rts

ChangeTopStatusXToRemains:
    clc
    lda VRAM_Buffer1_Offset
    tay
    adc #4
    sta VRAM_Buffer1_Offset
    lda #$20
    sta VRAM_Buffer1+0, y
    lda #$48
    sta VRAM_Buffer1+1, y
    lda #1
    sta VRAM_Buffer1+2, y
    lda #$1B
    sta VRAM_Buffer1+3, y
    lda #0
    sta VRAM_Buffer1+4, y
    rts

;; Game enters here when the bottom status line should update.
PractisePrintScore:
    ; We keep the last spot that we wrote our text here.
    ; That way can keep updating it until the game has a chance to render.
    clc
    ldy PendingScoreDrawPosition
    bne @RefreshBufferX
    ldy VRAM_Buffer1_Offset
    iny
    iny
    iny
    sty PendingScoreDrawPosition
    jsr @PrintRule
    jsr @PrintFramecounter
    ldx ObjectOffset
    rts
@RefreshBufferX:
    jsr @PrintRuleDataAtY
    tya
    adc #9
    tay
    jsr @PrintFramecounterDataAtY
    ldx ObjectOffset
    rts

;; Prints the current framerule counter
@PrintRule:
    lda VRAM_Buffer1_Offset
    tay
    adc #(3+6)
    sta VRAM_Buffer1_Offset
    lda #$20
    sta VRAM_Buffer1,y
    lda #$63
    sta VRAM_Buffer1+1,y
    lda #$06
    sta VRAM_Buffer1+2,y
    iny
    iny
    iny
    lda #0
    sta VRAM_Buffer1+6,y
    lda #$24
    sta VRAM_Buffer1+4,y

@PrintRuleDataAtY:
    lda CachedITC
    sta VRAM_Buffer1+5,y
    lda MathInGameFrameruleDigitStart+3
    sta VRAM_Buffer1+0,y
    lda MathInGameFrameruleDigitStart+2
    sta VRAM_Buffer1+1,y
    lda MathInGameFrameruleDigitStart+1
    sta VRAM_Buffer1+2,y
    lda MathInGameFrameruleDigitStart+0
    sta VRAM_Buffer1+3,y
    rts



;; Prints the current framecounter value
@PrintFramecounter:
    lda VRAM_Buffer1_Offset
    tay
    adc #(3+3)
    sta VRAM_Buffer1_Offset
    lda #$20
    sta VRAM_Buffer1,y
    lda #$75
    sta VRAM_Buffer1+1,y
    lda #$03
    sta VRAM_Buffer1+2,y
    iny
    iny
    iny
    lda #0
    sta VRAM_Buffer1+3,y
@PrintFramecounterDataAtY:
    lda FrameCounter
    jsr B10DivBy10
    sta VRAM_Buffer1+2,y
    txa
    jsr B10DivBy10
    sta VRAM_Buffer1+1,y
    txa
    sta VRAM_Buffer1+0,y
    rts


;; Prints the current sockfolder numbers
SockfolderData = $2
UpdateSockfolder:
    ldx VRAM_Buffer1_Offset
    bne @skip
    lda SprObject_X_MoveForce
    sta SockfolderData+1
    lda Player_X_Position
    sta SockfolderData+0
    lda Player_Y_Position
    eor #$FF
    lsr a
    lsr a
    lsr a
    bcc @sock1
    pha
    clc
    lda #$80
    adc SockfolderData+1
    sta SockfolderData+1
    lda SockfolderData+0
    adc #$02
    sta SockfolderData+0
    pla
@sock1:
    sta SockfolderData+2
    asl a
    asl a
    adc SockfolderData+2
    adc SockfolderData+0
    sta SockfolderData+0

    ; place sockfolder in vram
    lda #$20
    sta VRAM_Buffer1,x
    lda #$6A
    sta VRAM_Buffer1+1,x
    lda #8
    sta VRAM_Buffer1+2,x
    lda #(8+3)
    sta VRAM_Buffer1_Offset
    lda #$24
    sta VRAM_Buffer1+3+2,x
    sta VRAM_Buffer1+3+5,x

    lda SockfolderData+0
    and #$0F
    sta VRAM_Buffer1+3+0,x
    lda SockfolderData+1
    lsr
    lsr
    lsr
    lsr
    sta VRAM_Buffer1+3+1,x

    ; x move force
    lda Player_X_MoveForce
    tay
    and #$0F
    sta VRAM_Buffer1+3+4,x ; Y
    tya
    lsr
    lsr
    lsr
    lsr
    sta VRAM_Buffer1+3+3,x ; Y

    ; pointer for where pipes direct player
    lda AreaPointer
    tay
    and #$0F
    sta VRAM_Buffer1+3+7,x ; X
    tya
    lsr
    lsr
    lsr
    lsr
    sta VRAM_Buffer1+3+6,x ; X

    lda #0
    sta VRAM_Buffer1+3+8,x
@skip:
    rts


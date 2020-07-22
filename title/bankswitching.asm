InitBankSwitchingCode:
    ldx #(RelocatedCode_End-RelocatedCode_Start)
:   lda RelocatedCode_Start-1,x
    sta RelocatedCodeLocation-1,x
    dex
    bne :-
    rts

;; this code is copied into WRAM
RelocatedCode_Start:

.export BANK_PractiseNMI
BANK_PractiseNMI =  RelocatedCodeLocation + (* - RelocatedCode_Start)
jsr BANK_TITLE_RTS
jsr PractiseNMI
jmp BANK_GAME_RTS

.export BANK_PractiseReset
BANK_PractiseReset =  RelocatedCodeLocation + (* - RelocatedCode_Start)
jsr BANK_TITLE_RTS
jsr TitleReset
jmp BANK_GAME_RTS

.export BANK_PractiseWriteBottomStatusLine
BANK_PractiseWriteBottomStatusLine =  RelocatedCodeLocation + (* - RelocatedCode_Start)
jsr BANK_TITLE_RTS
jsr PractiseWriteBottomStatusLine
jmp BANK_GAME_RTS

.export BANK_PractisePrintScore
BANK_PractisePrintScore =  RelocatedCodeLocation + (* - RelocatedCode_Start)
jsr BANK_TITLE_RTS
jsr PractisePrintScore
jmp BANK_GAME_RTS

.export BANK_PractiseEnterStage
BANK_PractiseEnterStage =  RelocatedCodeLocation + (* - RelocatedCode_Start)
jsr BANK_TITLE_RTS
jsr PractiseEnterStage
jmp BANK_GAME_RTS

.export BANK_PractiseDelayToAreaEnd
BANK_PractiseDelayToAreaEnd =  RelocatedCodeLocation + (* - RelocatedCode_Start)
sta EnemyIntervalTimer,x
jsr BANK_TITLE_RTS
jsr PractiseDelayToAreaEnd
ldx ObjectOffset
jmp BANK_GAME_RTS

.export BANK_ProcJumping
BANK_ProcJumping =  RelocatedCodeLocation + (* - RelocatedCode_Start)
sta JumpSwimTimer
jsr BANK_TITLE_RTS
jsr PractisePrintScore
jmp BANK_GAME_RTS

.export BANK_EndAreaPoints
BANK_EndAreaPoints =  RelocatedCodeLocation + (* - RelocatedCode_Start)
lda #4
jsr OutputNumbers
ldx ObjectOffset
rts

; scan through levels skipping over any autocontrol stages
BANK_AdvanceToLevel =  RelocatedCodeLocation + (* - RelocatedCode_Start)
    jsr BANK_GAME_RTS
    ldx #0
    stx $0
    stx AreaNumber
    ldx LevelNumber
    beq @LevelFound
@NextArea:
    jsr LoadAreaPointer
    jsr GetAreaDataAddrs
    inc AreaNumber
    lda PlayerEntranceCtrl
    and #%00000100
    beq @AreaOK
    inc $0
    bvc @NextArea
@AreaOK:
    dex 
    bne @NextArea
@LevelFound:
    clc
    lda LevelNumber
    adc $0
    sta AreaNumber
    lda #0
    sta SND_DELTA_REG+1
    jsr LoadAreaPointer
    jsr GetAreaDataAddrs
    lda #$a5
    jmp GL_ENTER

BANK_GAME_RTS =  RelocatedCodeLocation + (* - RelocatedCode_Start)
BANK_GAME_RTS_CODE:
    pha
    lda #BANKNR_SMB
    jmp BANK_RTS

BANK_TITLE_RTS =  RelocatedCodeLocation + (* - RelocatedCode_Start)
BANK_TITLE_RTS_CODE:
    pha
    lda #BANKNR_TITLE

BANK_RTS =  RelocatedCodeLocation + (* - RelocatedCode_Start)
BANK_RTS_CODE:
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
RelocatedCode_End:
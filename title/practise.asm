; ===========================================================================
;  Start the game!
; ---------------------------------------------------------------------------
TStartGame:
    @FRDigits = (MathFrameruleDigitEnd-MathFrameruleDigitStart-1)
    jsr InitBankSwitchingCode                    ; copy utility code to WRAM
    ldx #@FRDigits                               ; set up framerule digits
@KeepCopying:                                    ;
    lda MathFrameruleDigitStart, x               ; copy each framerule digit from the menu
    sta MathInGameFrameruleDigitStart, x         ;
    dex                                          ;
    bpl @KeepCopying                             ;
    clc                                          ;
    lda #1                                       ; set flag indicating we are entering from the menu
    sta EnteringFromMenu                         ;
    sta OperMode                                 ; set starting opermode to "gamemode"
    sta IsPlaying                                ; mark that we are in game mode
    lsr a                                        ; clear A
    sta OperMode_Task                            ; clear opermode task value
    sta GameEngineSubroutine                     ; clear game engine task
    sta TimerControl                             ; mark the game as running
    sta PendingScoreDrawPosition                 ; clear pending status bar draw flag
    sta PPU_CTRL_REG1                            ; diable rendering
    sta Mirror_PPU_CTRL_REG1                     ;
    sta PPU_CTRL_REG2                            ;
    sta $4015                                    ; silence music
    sta EventMusicQueue                          ; stop music queue
    ldx SettablesWorld                           ; copy menu world number
    stx WorldNumber                              ;
    ldx SettablesLevel                           ; copy menu level number
    stx LevelNumber                              ;
    ldx SettablesPUP                             ; get menu powerup state
    lda @StatusSizes,x                           ; get player size based on menu state
    sta PlayerSize                               ; and update player size
    lda @StatusPowers,x                          ; get player power state based on menu state
    sta PlayerStatus                             ; and update player status
    lda #$2                                      ; give player 3 lives
    sta NumberofLives                            ;
    lda #$4                                      ; set the interval timer to a hardcoded value
    sta IntervalTimerControl                     ;
    inc FetchNewGameTimerFlag                    ; tell the game to reload the game timer
    jmp BANK_AdvanceToLevel                      ; transition to the wram code to start the game
@StatusSizes:
.byte $1, $0, $0, $0, $1, $1
@StatusPowers:
.byte $0, $1, $2, $0, $1, $2
; ===========================================================================

; ===========================================================================
;  Practise routine per frame routine
; ---------------------------------------------------------------------------
PractiseNMI:
    lda EnteringFromMenu                         ; are we currently entering from the menu?
    beq @ClearPractisePrintScore                 ; no - then we can run our routine
    rts                                          ; otherwise, we're loading, so just return
@ClearPractisePrintScore:                        ;
    lda VRAM_Buffer1_Offset                      ; check if we have pending ppu draws
    bne @IncrementFrameruleCounter               ; yes - skip ahead
    sta PendingScoreDrawPosition                 ; no - clear pending vram address for framerule drawing
@IncrementFrameruleCounter:                      ;
    jsr IncrementFrameruleCounter                ; increment the base10 framerule counter
    jsr CheckForLevelEnd                         ; run level transition handler
    jsr CheckJumpingState                        ; run jump handler
    jsr CheckAreaTimer                           ; run area transition timing handler
@CheckUpdateStatusbarValues:                     ;
    lda FrameCounter                             ; get current frame counter
    and #3                                       ; and just make sure we're in a specific 4 frame spot
    cmp #2                                       ;
    bne @CheckInput                              ; if not, skip ahead
    jsr RedrawHighFreqStatusbar                  ; otherwise update status bar
@CheckInput:                                     ;
    lda JoypadBitMask                            ; get current joypad state
    and #(Select_Button | Start_Button)          ; mask out all but select and start
    beq @Done                                    ; neither are held - nothing more to do here
    jsr ReadJoypads                              ; re-read joypad state, to avoid filtering from the game
@CheckForRestartLevel:                           ;
    cmp #(Up_Dir | Select_Button)                ; check if select + up are held
    bne @CheckForReset                           ; no - skip ahead
    lda #0                                       ; yes - we are restarting the level
    sta PPU_CTRL_REG1                            ; disable screen rendering
    sta PPU_CTRL_REG2                            ;
    jsr InitializeMemory                         ; clear memory
    jmp TStartGame                               ; and start the game
@CheckForReset:                                  ;
    cmp #(Down_Dir | Select_Button)              ; check if select + down are held
    bne @Done                                    ; no - skip ahead
    lda #0                                       ; yes - we are returning to the title screen
    sta PPU_CTRL_REG1                            ; disable screen rendering
    sta PPU_CTRL_REG2                            ;
    jmp HotReset                                 ; and reset the game
@Done:                                           ;
    rts                                          ;
; ===========================================================================

; ===========================================================================
;  Handle new area loading loading
; ---------------------------------------------------------------------------
PractiseEnterStage:
    @FRDigitCount = MathFrameruleDigitEnd - MathFrameruleDigitStart - 1
    lda #3                                       ; set life counter so we can't lose the game
    sta NumberofLives                            ;
    lda #152                                     ; position spr0
    sta $203                                     ;
    lda EnteringFromMenu                         ; check if we're entering from the menu
    beq @SaveToMenu                              ; no, the player beat a level, update the menu state
    sec                                          ; yes, the player is starting a new game
    lda FrameCounter                             ; we need to offset the frame counter a little bit
    sbc #6                                       ;
    sta FrameCounter                             ;
    jsr RNGQuickResume                           ; and load the rng state
    dec EnteringFromMenu                         ; then mark that we've entered from the menu, so this doesn't happen again
    beq @Shared                                  ; and skip ahead to avoid saving the state for no reason
@SaveToMenu:                                     ;
    lda LevelEnding                              ; check if we are transitioning to a new level
    beq @Shared                                  ; no - skip ahead and enter the game
    ldx #@FRDigitCount                           ; yes - copy the framerule to the menu
:   lda MathInGameFrameruleDigitStart,x          ;
    sta MathFrameruleDigitStart,x                ;
    dex                                          ;
    bpl :-                                       ;
    lda WorldNumber                              ; copy current world and level to the menu
    sta SettablesWorld                           ;
    lda LevelNumber                              ;
    sta SettablesLevel                           ;
    lda PlayerSize                               ; get player powerup state
    asl a                                        ; shift up a couple of bits to make room for powerup state
    asl a                                        ;
    ora PlayerStatus                             ; combine with powerup state
    tax                                          ; copy to X
    lda @PUpStates,x                             ; and get the menu selection values from the players current state
    sta SettablesPUP                             ; and write to menu powerup state
@Shared:                                         ;
    lda #0                                       ; clear out some starting state
    sta CachedChangeAreaTimer                    ;
    sta LevelEnding                              ;
    jmp RedrawLowFreqStatusbar                   ; and update the status line
@PUpStates:
.byte $3                                         ; size = 0, status = 0. big vuln. mario
.byte $1                                         ; size = 0, status = 1. big super mario
.byte $2                                         ; size = 0, status = 2. big fire mario
.byte $0                                         ; size = 1, status = 0. small vuln. mario
.byte $5                                         ; size = 1, status = 1. small super mario
.byte $6                                         ; size = 1, status = 2. small fire mario
; ===========================================================================

; ===========================================================================
;  Handle level transitions
; ---------------------------------------------------------------------------
CheckForLevelEnd:
    lda LevelEnding                              ; have we already detected the level end?
    bne @Done                                    ; if so - exit
    lda ScreenRoutineTask
    cmp #7
    beq @LevelEnding
    lda StarFlagTaskControl                      ; check the current starflag state
    cmp #4                                       ; are we in the final starflag task?
    bne @Done                                    ; no - exit
    lda IntervalTimerControl                     ; cache the current interval timer
    sta CachedITC                                ;
    clc                                          ;
    jsr ChangeTopStatusXToRemains                ; change the 'X' in the title to 'R'
    jsr RedrawLowFreqStatusbar                   ; and redraw the status bar
@LevelEnding:
    inc LevelEnding                              ; yes - mark the level end as ended
@Done:                                           ;
    rts                                          ;
; ===========================================================================

; ===========================================================================
;  Handle area transitions (pipes, etc)
; ---------------------------------------------------------------------------
CheckAreaTimer:
    lda CachedChangeAreaTimer                    ; have we already handled the area change?
    bne @Done                                    ; yes - exit
    lda ChangeAreaTimer                          ; no - check if we should handle it
    beq @Done                                    ; no - exit
    sta CachedChangeAreaTimer                    ; yes - cache the timer value
    lda IntervalTimerControl                     ; get the interval timer
@Store2:                                         ;
    sta CachedITC                                ; and cache it as well
    clc                                          ;
    jsr ChangeTopStatusXToRemains                ; change the 'X' in the title to 'R'
    jsr RedrawLowFreqStatusbar                   ; and redraw the status bar
@Done:                                           ;
    rts                                          ;
; ===========================================================================

; ===========================================================================
;  Handle player jumping
; ---------------------------------------------------------------------------
CheckJumpingState:
    lda JumpSwimTimer                            ; check jump timer
    cmp #$20                                     ; is it the max value (player just jumped)
    bne @Done                                    ; no - exit
    jsr RedrawLowFreqStatusbar                   ; yes - redraw the status bar
@Done:                                           ;
    rts                                          ; done!
; ===========================================================================

; ===========================================================================
;  Advance to the next base 10 framerule digit
; ---------------------------------------------------------------------------
IncrementFrameruleCounter:
    @DigitOffset = (MathInGameFrameruleDigitStart-MathDigits)
    lda TimerControl                             ; check if the game is running
    bne @Done                                    ; no - exit
    ldy IntervalTimerControl                     ; get the interval timer
    cpy #1                                       ; are we at the end of the interval?
    bne @Done                                    ; no - exit
    clc                                          ;
    lda #1                                       ; we want to add 1 to the digits
    ldx #@DigitOffset                            ; get the offset to the digit we are incrementing
    jmp B10Add                                   ; and run base 10 addition
@Done:                                           ;
    rts                                          ;
; ===========================================================================

; ===========================================================================
;  Handle when the game wants to redraw the MARIO / TIME text at the top
; ---------------------------------------------------------------------------
PractiseWriteTopStatusLine:
    clc                                          ;
    ldy VRAM_Buffer1_Offset                      ; get current vram offset
    lda #(@TopStatusTextEnd-@TopStatusText+1)    ; get text length
    adc VRAM_Buffer1_Offset                      ; add to vram offset
    sta VRAM_Buffer1_Offset                      ; and store new offset
    ldx #0                                       ;
@CopyData:                                       ;
    lda @TopStatusText,x                         ; copy bytes of the status bar text to vram
    sta VRAM_Buffer1,y                           ;
    iny                                          ; advance vram offset
    inx                                          ; advance text offset
    cpx #(@TopStatusTextEnd-@TopStatusText)      ; check if we're at the end
    bne @CopyData                                ; if not, loop
    lda #0                                       ; then set null terminator at the end
    sta VRAM_Buffer1,y                           ;
    inc ScreenRoutineTask                        ; and advance the screen routine task
    rts                                          ; done
@TopStatusText:                                  ;
  .byte $20, $43,  21, "RULE x SOCKS TO FRAME"   ;
  .byte $20, $59,   4, "TIME"                    ;
  .byte $20, $73,   2, $2e, $29                  ; coin that shows next to the coin counter
  .byte $23, $c0, $7f, $aa                       ; tile attributes for the top row, sets palette
  .byte $23, $c4, $01, %11100000                 ; set palette for the flashing coin
@TopStatusTextEnd:
   .byte $00
; ===========================================================================

; ===========================================================================
;  Handle the game requesting redrawing the bottom status bar
; ---------------------------------------------------------------------------
PractiseWriteBottomStatusLine:
    lda LevelEnding                              ; are we transitioning to a new level?
    bne :+                                       ; yes, don't update the itc value
    lda IntervalTimerControl                     ; no, get the current interval timer
    sta CachedITC                                ; and store it in the cached value
:   jsr RedrawLowFreqStatusbar                   ; redraw the status bar
    inc ScreenRoutineTask                        ; and advance to the next smb screen routine
    rts                                          ;
; ===========================================================================

; ===========================================================================
;  Place an "R" instead of "x" in the title screen during level transitions
; ---------------------------------------------------------------------------
ChangeTopStatusXToRemains:
    clc                                          ;
    lda VRAM_Buffer1_Offset                      ; get current vram offset
    tay                                          ;
    adc #4                                       ; and advance it by 4
    sta VRAM_Buffer1_Offset                      ; store the new offset
    lda #$20                                     ; write the ppu address to update
    sta VRAM_Buffer1+0, y                        ;
    lda #$48                                     ;
    sta VRAM_Buffer1+1, y                        ;
    lda #1                                       ; we are writing a single byte
    sta VRAM_Buffer1+2, y                        ;
    lda #'R'                                     ; and that byte is an R
    sta VRAM_Buffer1+3, y                        ;
    lda #0                                       ; set the null terminator
    sta VRAM_Buffer1+4, y                        ;
    rts                                          ; and finish
; ===========================================================================

; ===========================================================================
;  Redraw the status bar portion that updates less often
; ---------------------------------------------------------------------------
RedrawLowFreqStatusbar:
    clc                                          ;
    ldy PendingScoreDrawPosition                 ; check if we have a pending draw that hasn't been sent to the ppu
    bne @RefreshBufferX                          ; yes - skip ahead and refresh the buffer to avoid overloading the ppu
    ldy VRAM_Buffer1_Offset                      ; no - get the current buffer offset
    iny                                          ; increment past the ppu location
    iny                                          ;
    iny                                          ;
    sty PendingScoreDrawPosition                 ; and store it as our pending position
    jsr @PrintRule                               ; draw the current framerule value
    jsr @PrintFramecounter                       ; draw the current framecounter value
    ldx ObjectOffset                             ; load object offset, our caller might expect it to be unchanged
    rts                                          ; and exit
@RefreshBufferX:                                 ;
    jsr @PrintRuleDataAtY                        ; refresh pending framerule value
    tya                                          ; get the buffer offset we're drawing to
    adc #9                                       ; and shift over to the framecounter position
    tay                                          ;
    jsr @PrintFramecounterDataAtY                ; and then refresh the pending frame ounter value
    ldx ObjectOffset                             ; load object offset, our caller might expect it to be unchanged
    rts                                          ; and exit
; ---------------------------------------------------------------------------
;  Copy current framerule number to VRAM
; ---------------------------------------------------------------------------
@PrintRule:
    lda VRAM_Buffer1_Offset                      ; get the current buffer offset
    tay                                          ;
    adc #(3+6)                                   ; shift over based on length of the framerule text
    sta VRAM_Buffer1_Offset                      ; store the ppu location of the framerule counter
    lda #$20                                     ;
    sta VRAM_Buffer1,y                           ;
    lda #$63                                     ;
    sta VRAM_Buffer1+1,y                         ;
    lda #$06                                     ; store the number of digits to draw
    sta VRAM_Buffer1+2,y                         ;
    iny                                          ; increment past the ppu location
    iny                                          ;
    iny                                          ;
    lda #0                                       ; place our null terminator
    sta VRAM_Buffer1+6,y                         ;
    lda #$24                                     ; and write a space past the framerule (masks out smb1 '0' after the score)
    sta VRAM_Buffer1+4,y                         ;
@PrintRuleDataAtY:
    lda CachedITC                                ; get the interval timer for when we entered the room
    sta VRAM_Buffer1+5,y                         ; and store it in the buffer
    lda MathInGameFrameruleDigitStart+3          ; then copy the framerule numbers into the buffer
    sta VRAM_Buffer1+0,y                         ;
    lda MathInGameFrameruleDigitStart+2          ;
    sta VRAM_Buffer1+1,y                         ;
    lda MathInGameFrameruleDigitStart+1          ;
    sta VRAM_Buffer1+2,y                         ;
    lda MathInGameFrameruleDigitStart+0          ;
    sta VRAM_Buffer1+3,y                         ;
    rts                                          ;
; ---------------------------------------------------------------------------
;  Copy current frame number to VRAM
; ---------------------------------------------------------------------------
@PrintFramecounter:
    lda VRAM_Buffer1_Offset                      ; get current vram offset
    tay                                          ;
    adc #(3+3)                                   ; add 3 for vram offset, 3 for values to draw
    sta VRAM_Buffer1_Offset                      ; save new vram offset
    lda #$20                                     ; store the ppu location of the frame number
    sta VRAM_Buffer1,y                           ;
    lda #$75                                     ;
    sta VRAM_Buffer1+1,y                         ;
    lda #$03                                     ; store the number of digits to draw
    sta VRAM_Buffer1+2,y                         ;
    iny                                          ; advance y to the end of the buffer to write
    iny                                          ;
    iny                                          ;
    lda #0                                       ; place our null terminator
    sta VRAM_Buffer1+3,y                         ;
@PrintFramecounterDataAtY:                       ;
    lda FrameCounter                             ; get the current frame number
    jsr B10DivBy10                               ; divide by 10
    sta VRAM_Buffer1+2,y                         ; store remainder in vram buffer
    txa                                          ; get the result of the divide
    jsr B10DivBy10                               ; divide by 10
    sta VRAM_Buffer1+1,y                         ; store remainder in vram buffer
    txa                                          ; get the result of the divide
    sta VRAM_Buffer1+0,y                         ; and store it in vram
    rts                                          ;
; ===========================================================================

; ===========================================================================
;  Update and draw status bar values
; ---------------------------------------------------------------------------
RedrawHighFreqStatusbar:
    @SockSubX = $2                               ; memory locations that sockfolder is stored in
    @SockX    = $3                               ;
    lda VRAM_Buffer1_Offset                      ; check if there are pending ppu updates
    beq :+                                       ; no - skip ahead to update status bar
    rts                                          ; yes - don't overload the ppu
:   jsr RecalculateSockfolder                    ; calculate new sockfolder value

    ldx #0                                       ; clear X
    lda #$20                                     ; write ppu location of status bar to vram buffer
    sta VRAM_Buffer1+0,x                         ;
    lda #$6A                                     ;
    sta VRAM_Buffer1+1,x                         ;
    lda #8                                       ; write number of bytes to draw
    sta VRAM_Buffer1+2,x                         ;
    lda #(8+3)                                   ; and update vram buffer offset to new location
    sta VRAM_Buffer1_Offset                      ;
    lda #$24                                     ; write spaces to a couple of locations
    sta VRAM_Buffer1+3+2,x                       ;
    sta VRAM_Buffer1+3+5,x                       ;
    lda #0                                       ; write null terminator
    sta VRAM_Buffer1+3+8,x                       ;

    lda @SockX                                   ; get sockfolder x position
    and #$0F                                     ; mask off the high nibble
    sta VRAM_Buffer1+3+0,x                       ; and write that byte to the vram buffer
    lda @SockSubX                                ; get sockfolder subpixel x position
    lsr                                          ; and shift down to the low nibble
    lsr                                          ;
    lsr                                          ;
    lsr                                          ;
    sta VRAM_Buffer1+3+1,x                       ; and write that byte to the vram buffer
    lda Player_X_MoveForce                       ; get the current player subpixel
    tay                                          ; copy to Y
    and #$0F                                     ; mask off the high nibble
    sta VRAM_Buffer1+3+4,x ; Y                   ; and write that byte to the vram buffer
    tya                                          ; restore full value from Y
    lsr                                          ; and shift down to the low nibble
    lsr                                          ;
    lsr                                          ;
    lsr                                          ;
    sta VRAM_Buffer1+3+3,x ; Y                   ; and write that byte to the vram buffer
    lda AreaPointer                              ; get the pointer to where warp pipes direct player
    tay                                          ; copy to Y
    and #$0F                                     ; mask off the high nibble
    sta VRAM_Buffer1+3+7,x ; X                   ; and write that byte to the vram buffer
    tya                                          ; restore full value from Y
    lsr                                          ; and shift down to the low nibble
    lsr                                          ;
    lsr                                          ;
    lsr                                          ;
    sta VRAM_Buffer1+3+6,x ; X                   ; and write that byte to the vram buffer
@skip:                                           ;
    rts                                          ;
; ===========================================================================


; ===========================================================================
;  Calculate the current sockfolder value
; ---------------------------------------------------------------------------
; Sockfolder is effectively calculated by the following formula:
;  Player_X_Position + ((0xFF - Player_Y_Position) / MaximumYSpeed) * MaximumXSpeed
;
; So that will give you the position that mario would be when he reaches the
; bottom of the screen assuming the player is falling at full speed.
;
; Here's a little javascript snippet that creates a 16 bit lookup table of sockfolder values:
;
;; // NTSC:
;; let max_x_speed = 0x0280; // maximum x speed in subpixels
;; let max_y_speed = 0x04;   // maximum y speed in pixels
;; // PAL:
;; //let max_x_speed = 0x0300; // maximum x speed in subpixels
;; //let max_y_speed = 0x05;   // maximum y speed in pixels
;;
;; let values = [];
;; for (let i=0xFF; i>=0x00; --i) {
;;     let value = Math.floor(i/max_y_speed)*max_x_speed;
;;     let format = Math.round(value).toString(16).padStart(4,'0');
;;     values.push('$' + format);
;; };
;;
;; let items_per_row = 0x8;
;; for (let i=0; i<(values.length/items_per_row); ++i) {
;;     let start = i * items_per_row;
;;     let end = (i * items_per_row) + items_per_row;
;;     let line = values.slice(start, end).join(',')
;;     console.log('.byte ' + line + ' ; range ' +  start.toString(16) + ' to ' + (end-1).toString(16));
;; }
;
; ---------------------------------------------------------------------------
RecalculateSockfolder:
    @DataTemp = $4                               ; temp value used for some maths
    @DataSubX = $2                               ; sockfolder subpixel x value
    @DataX    = $3                               ; sockfolder pixel x value
    lda SprObject_X_MoveForce                    ; get subpixel x position
    sta @DataSubX                                ; and store it in our temp data
    lda Player_X_Position                        ; get x position
    sta @DataX                                   ; and store it in our temp data
    lda Player_Y_Position                        ; get y position
    eor #$FF                                     ; invert the bits, now $FF is the top of the screen
    lsr a                                        ; divide pixel position by 8
    lsr a                                        ;
    lsr a                                        ;
    bcc @sock1                                   ; if we're on the top half of tile 'tile', we will land 2.5 pixels later.
    pha                                          ; so store the current value
    clc                                          ;
    lda @DataSubX                                ; get subpixel x position
    lda #$80                                     ; and increase it by half
    sta @DataSubX                                ; and store it back
    lda @DataX                                   ; get x position
    adc #$02                                     ; and add 2 + carry value
    sta @DataX                                   ; and store it back
    pla                                          ; then restore our original value
@sock1:                                          ;
    sta @DataTemp                                ; store this in our temp value
    asl a                                        ; multiply by 4
    asl a                                        ;
    adc @DataTemp                                ; and add the temp value
    adc @DataX                                   ; then add our x position
    sta @DataX                                   ; and store it back
    rts                                          ;
; ===========================================================================

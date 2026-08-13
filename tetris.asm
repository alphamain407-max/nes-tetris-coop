.inesprg 2
.ineschr 1
.inesmap 0
.inesmir 1

;;;;;;;;;;;;;;;;

.rsset $0000
fall_timer      .rs 1
fall_thresold   .rs 1
piece_x         .rs 1
piece_y         .rs 1
piece_index     .rs 1
piece_rotation  .rs 1
p1x             .rs 1
p1y             .rs 1
p1i             .rs 1
p1r             .rs 1
p2x             .rs 1
p2y             .rs 1
p2i             .rs 1
p2r             .rs 1
p1d             .rs 1
oam_ptr         .rs 1
oam_limit       .rs 1
tile_index      .rs 1
p2d             .rs 1
sleep           .rs 1
; Low byte and high byte for background rendering
bgr_lo          .rs 1
bgr_hi          .rs 1
; Controllers
ctrl1           .rs 4 ; 4 is purposeful for P1/P2 indexing
ctrl2           .rs 1
ctrl1prev       .rs 4
ctrl2prev       .rs 1
p1dl .rs 1
; DAS stuff (Expanded to 5 to safely allow X=4 offset for Player 2)
dastmr          .rs 1 ; DAS timer
dasbool         .rs 1 ; Bool whether piece was sliding or not
dasbool2        .rs 1 ; Whether piece moved for the first time
p2dl .rs 1
dastemp         .rs 1
p2das           .rs 4
; Temporary variable(s)
temp            .rs 1
temp2           .rs 1
temp3           .rs 1
p1dl2           .rs 1
p2dl2           .rs 1
; ONLY FOR USE DURING VBLANK.
vbtemp          .rs 1
vbtemp2         .rs 1

; Check X and Y for collision check
chx             .rs 1
chy             .rs 1
lx              .rs 1
ly              .rs 1

; Piece index being checked
pci             .rs 1
; Piece index being merged
mpi             .rs 1

; The line index currently being rendered
rli             .rs 1
rbool           .rs 1 ; Whether a board re-render is needed

; Cleared line indexes
clearedLines    .rs 4
lineCounter     .rs 1
lineIndex       .rs 1
lineBase        .rs 1
clearedBool     .rs 1

; More booleans!
animBool        .rs 1
copyBool        .rs 1

; Which piece did the line clear? ($00 = P1, $04 = P2)
lineClearIndex  .rs 1
; Frame counter
frameCounter    .rs 1
lineClearAnimFrameIndex .rs 1

; COUNTER
ctr             .rs 1
vbctr           .rs 1 ; for VBLANK

; Randoms
randSeed        .rs 1

; Spawn flags for delayed coordinate resets
spawn_flag      .rs 1

; Next pieces
p1ni            .rs 1
p2ni            .rs 1

; APU Pointers (MUST be in Zero Page for indirect addressing)
music_ptr_lo    .rs 1
music_ptr_hi    .rs 1
apu_sp          .rs 1
call_ptr_hi .rs 1
call_ptr_lo .rs 1

; Score
score_56 .rs 1
score_34 .rs 1
score_12 .rs 1

; Lines
lines_hi .rs 1
lines_12 .rs 1

; level
level .rs 1
start_level .rs 1
level_updated .rs 1
level_temp .rs 1

; Player amount
players .rs 1

; Render parity (i'm going insane)
render_parity .rs 1

.rsset $0200
ty .rs 1 ; Tile Y
ti .rs 1 ; Tile Index
ta .rs 1 ; Tile Attributes
tx .rs 1 ; Tile X

; Page 3 - APU Variables
.rsset $0300
apu_playing     .rs 1
apu_timer       .rs 1
apu_tempo       .rs 1
delay_counter .rs 1

;;;;;;;;;;;;;;;;

.prg 0

vblankwait:
	BIT $2002
	BPL vblankwait
	RTS

;;;;;;;;

RESET:
	SEI
	CLD
	LDX #$40
	STX $4017
	LDX #$FF
	TXS
	INX
	STX $2000
	STX $2001
	STX $4010

;;;;;;;;

	JSR vblankwait

;;;;;;;;

clrmem:
	LDA #$00
	STA $0000, X
	STA $0100, X
	STA $0300, X
	STA $0500, X
	STA $0600, X
	STA $0700, X
	STA $0200, X
	STA $0400, X
	INX
	BNE clrmem

;;;;;;;;

	JSR vblankwait

;;;;;;;;

LoadPalette:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00
LoadPaletteLoop:
	LDA palette, X
	STA $2007
	INX
	CPX #$20
	BNE LoadPaletteLoop

;;;;;;;;
ResetGame:
	LDX #$00
ClearStuff:
	LDA #$25
	STA $0400, X
	LDA #$FE
	STA $0200, X
	INX
	BNE ClearStuff
fillboardbottom:
	LDX #$0C
	LDA #$22
:
	STA $04EF, X
	DEX
	BNE :-
	STA <randSeed
	LDA #LOW(music_data)
	STA <music_ptr_lo
	LDA #HIGH(music_data)
	STA <music_ptr_hi
MenuInit:
	JSR vblankwait
	LDX #$00
	STX $2000
	STX $2001
	LDA #$02
	STA $4014
	LDA $2002
ClearVRAM:    
	LDA #$20        ; Start at VRAM address $2000 (Name Table 0)
	STA $2006
	LDA #$00
	STA $2006

	LDA #$00        ; Tile $00 (usually blank/empty tile)
	LDX #$10        ; Clear 16 pages of 256 bytes = 4,096 bytes ($2000–$2FFF)
	LDY #$00
ClearLoop:
	STA $2007       ; Auto-increments PPU address by 1
	DEY
	BNE ClearLoop
	DEX
	BNE ClearLoop
	LDA $2002
	LDA #$20
	STA $2006
	STX $2006
PrintString:
	LDA pressStart, X
	STA $2007
	INX
	CPX #$0B
	BNE PrintString
	LDX #$00
	LDA $2002
	LDA #$20
	STA $2006
	STA $2006
PrintString2:
	LDA startLv, X
	STA $2007
	INX
	CPX #$08
	BNE PrintString2
	LDA $2002
	STY $2005
	STY $2005
	LDA #$1E
	STA $2001
MenuLoop:
	BIT $2002
	BPL NotVBlankYet
	LDA #$20
	STA $2006
	LDA #$29
	STA $2006
	LDX <start_level
	JSR GeneralNumToVRAM
	LDA $2002
	LDA #$00
	STA $2005
	STA $2005
NotVBlankYet:
	JSR RandGen
	JSR ReadControllers
	LDA <ctrl1
	TAX
	AND #%01010000
	CMP #%01010000
	BEQ MainGameInit2Players
	TXA
	AND #%00010000
	BNE MainGameInit
	TXA
	AND #%00001000
	BEQ CheckDown
	LDA <ctrl1prev
	AND #%00001000
	BNE SaveButtons
	INC <start_level
	LDA <start_level
	CMP #$64
	BCC SaveButtons
	LDA #$00
	STA <start_level
	JMP SaveButtons
CheckDown:
	LDA <ctrl1
	AND #%00000100
	BEQ SaveButtons
	LDA <ctrl1prev
	AND #%00000100
	BNE SaveButtons
	DEC <start_level
	BPL SaveButtons
	LDA #$63
	STA <start_level
SaveButtons:
	LDA <ctrl1
	STA <ctrl1prev
	JMP MenuLoop
MainGameInit2Players:
	INC <players
MainGameInit:
	JSR vblankwait
	LDA #$00
	STA $2000
	STA $2001
	LDA #LOW(thebg)
	STA <bgr_lo
	LDA #HIGH(thebg)
	STA <bgr_hi
	JSR RenderScreen
	LDA <start_level
	STA <level
	JSR LevelInit
	LDA #%10000000 
	STA $2000
	LDA #%00011110
	STA $2001
	JSR APU_Init
	LDA #$05
	STA <p1x
	LDA #$01
	STA <sleep
	STA <rbool
	STA <p1y
	STA <p2y
	JSR RandGen
	AND #$07
	TAX
	LDA mod7tbl, X
	STA <p1ni
	JSR RandGen
	AND #$07
	TAX
	LDA mod7tbl, X
	STA <p2ni
	JSR RandGen
	AND #$07
	TAX
	LDA mod7tbl, X
	STA <p1i
	JSR RandGen
	AND #$07
	TAX
	LDA mod7tbl, X
	STA <p2i
	LDA #$08
	STA <p2x
	LDA #$00
	STA <score_56
	STA <score_34
	STA <score_12
	STA <lines_hi
	STA <lines_12
	STA <p1r
	STA <p2r
Main:
	JSR RandGen
	JSR CalculateLevel
	LDA #$00
	STA <oam_ptr
	STA <temp2
	STA <temp3
	LDA #$10
	STA <oam_limit
	INC <sleep
Wait:
	JSR FrameSyncLoop
	JSR APU_Update       ; Update sound on every frame
	; If animating a line clear, DO NOT spawn pieces yet.
	LDA <clearedBool
	BEQ :++
:
	JMP NoSpawns
:
	LDA <animBool
	BNE :--
	; --- Handle delayed spawning ---
	LDA <spawn_flag
	BEQ :--
	AND #$01
	BEQ CheckP2Spawn
	LDA <players
	BEQ :+
	LDX #$01
	STX <p1y
	STX <chy
	STX <p1x
	STX <chx
	BNE :++
:
	LDX #$05
	STX <p1x
	STX <chx
	LDX #$01
	STX <p1y
	STX <chy
:
	DEX
	STX <p1r
	LDA <p1ni
	STA <p1i
	JSR CollisionCheckP1
	BEQ P1RandLoop
	JMP Lose
P1RandLoop:
	JSR RandGen
	AND #$07
	CMP #$07
	BEQ P1RandLoop
	CMP <p1i
	BNE :+
P1RandLoop2:
	JSR RandGen
	AND #$07
	CMP #$07
	BEQ P1RandLoop2
:
	STA <p1ni
	LDA <p1dl
	STA <p1dl2
CheckP2Spawn:
	LDA <spawn_flag
	AND #$02
	BEQ SpawnsDone
	LDX #$01
	STX <p2y
	STX <chy
	DEX
	STX <p2r
	LDX #$08
	STX <p2x
	STX <chx
	LDA <p2ni
	STA <p2i
	JSR CollisionCheckP2
	BEQ P2RandLoop
	JMP Lose
P2RandLoop:
	JSR RandGen
	AND #$07
	CMP #$07
	BEQ P2RandLoop
	CMP <p2i
	BNE :+
P2RandLoop2:
	JSR RandGen
	AND #$07
	CMP #$07
	BEQ P2RandLoop2
:
	STA <p2ni
	LDA <p2dl
	STA <p2dl2
SpawnsDone:
	LDA #$00
	STA <spawn_flag
NoSpawns:
	
	; FIX: Check if animation just finished
	LDA <animBool
	BEQ :+
	LDA #$00
	STA <animBool
	JSR ShiftBoard     ; Shift tiles down in RAM
	LDA #$01
	STA <rbool          ; Tell NMI to redraw the board
	LDA #$00
	STA <rli            ; Reset rendering index
bk:
	INC <sleep
	JMP Wait           ; Wait for the redraw to finish
:
	LDA <clearedBool
	BNE bk           ; Freeze gameplay while animating

	; --- NEW GRAVITY & DOWN BUTTON LOGIC ---
	; Read Down button (Bit 2 = %00000100) for P1 and P2
	LDA <ctrl1
	AND #%00000100
	STA <p1d
	LDA <players
	BEQ :+
	LDA <ctrl2
	AND #%00000100
	STA <p2d
:
	; Normal gravity timer
	LDX <fall_timer
	INX
	STX <fall_timer
	CPX <fall_thresold
	BNE CheckSoftDrop
	
	; Normal Drop (Both pieces)
	LDX #$00
	STX <fall_timer
	LDA <players
	BNE DoP2Drop
	JMP DoP1Drop

CheckSoftDrop:
	; If neither is holding Down, branch to the drop cleanup checks
	LDA <p1d
	BNE :+
	LDX #$00
	STX <p1dl2
:
	LDA <p2d
	BNE :+
	LDX #$00
	STX <p2dl2
:
	ORA <p1d
	BEQ CheckSoftDrop_End

	; Soft drop speed: Drop exactly 1 block every 2 frames
	LDA <frameCounter
	AND #$01
	BEQ SkipDrops
CheckSoftDrop_End:
	LDA <players
	BNE DoP2Drop
	JMP DoP1Drop

DoP2Drop:
	; Only drop P2 if fall_timer triggered OR p2d is pressed
	LDA <p2dl2
	BNE :+
	LDA <p2d
	BNE :++
	LDA #$00
	STA <p2dl2
:
	LDA <fall_timer
	BEQ :++
	BNE DoP1Drop
:
	LDA #$01
	STA <p2dl
:
	LDX <p2x
	STX <chx
	LDX <p2y
	INX
	STX <chy
	JSR CollisionCheckP2
	LDY #$04
	CMP #$00
	BNE DoMerge
	STY <temp3
	JSR CollisionCheckAP
	BNE DoP1Drop
	LDX <chy
	STX <p2y

DoP1Drop:
	; Only drop P1 if fall_timer triggered OR p1d is pressed
	LDA <p1dl2
	BNE :+
	LDA <p1d
	BNE :++
	LDA #$00
	STA <p1dl2
:
	LDA <fall_timer
	BEQ :++
	BNE SkipDrops
:
	LDA #$01
	STA <p1dl
:
	LDX <p1x
	STX <chx
	LDX <p1y
	INX
	STX <chy
	JSR CollisionCheckP1
	LDY #$00
	CMP #$00
	BNE DoMerge     ; If there's a collision below, merge instead of falling
	STY <temp3
	LDA <players
	BEQ :+
	JSR CollisionCheckAP
	BNE SkipDrops
:
	LDX <chy
	STX <p1y         ; Safe to fall, update Y

SkipDrops:
	JMP lol

DoMerge:
	JSR MergePieceToBoard
	STY <temp2
	JSR LineCheck
	LDY <temp2
	LDA <clearedBool
	BEQ :+
	STY <lineClearIndex
	LDY <level
	INY
	STY <level_temp
AddLoop:
	JSR AddScore
	DEC <level_temp
	BNE AddLoop
AddLines:
	LDA <lines_hi
	CMP #$09
	BNE justAdd
	LDA <lines_12
	CMP #$63
	BEQ noClamp
justAdd:
	LDA <lines_12
	CLC
	ADC <clearedBool
	CMP #$64
	BCC noFix
	SEC
	SBC #$64
	INC <lines_hi
noFix:
	STA <lines_12
	LDA <lines_hi
	CMP #$0A
	BCC noClamp
	LDA #$09
	STA <lines_hi
	LDA #$63
	STA <lines_12
noClamp:
	LDY <lineClearIndex
:
	LDX #$01
	CPY #$04
	BNE :+
	
	; P2 Merge
	LDA <spawn_flag
	ORA #$02
	STA <spawn_flag
	LDA <clearedBool
	BNE lol
	JMP DoP1Drop
:
	; P1 Merge
	LDA <spawn_flag
	ORA #$01
	STA <spawn_flag

lol:
	LDA <frameCounter
	AND #$01
	STA <render_parity
	BNE RenderSwapped
RenderNormal:
	JSR RenderActivePiecesSub
	JSR RenderNextPiecesSub
	JMP :+
RenderSwapped:
	JSR RenderNextPiecesSub
	JSR RenderActivePiecesSub
:
	JSR ReadControllers
	LDX #$00
	STX <temp3
CCLoop:
	LDX <temp3
	LDA <ctrl1, X
	AND #%00000011    ; Check L/R (Bit 0 = Right, Bit 1 = Left)
	BEQ NoLR
	JMP CheckLR
	
NoLR:
	; Reset DAS state if L/R are released
	LDA #$00
	STA <dastmr, X
	STA <dasbool, X
	STA <dasbool2, X
	JMP CheckRotate

CheckLR:
	LDA <dasbool2, X
	BEQ okMove        ; 0 means first press
	
	LDA <dasbool, X
	BNE slide         ; 1 means autorepeat phase
	
	; Delay phase
	LDY <dastmr, X
	INY
	STY <dastmr, X
	CPY #$10          ; DAS Delay Frames
	BNE lr_done
	
	LDA #$01
	STA <dasbool, X
	JMP okMove
	
slide:
	; Autorepeat Phase
	LDY <dastmr, X
	INY
	STY <dastmr, X
	CPY #$10          ; DAS Repeat Rate 
	BNE lr_done
	
	LDA #$0C
	STA <dastmr, X    ; Reset timer
	JMP okMove
	
lr_done:
	JMP CheckRotate
	
okMove:
	LDA #$01
	STA <dasbool2, X
	
	LDA <ctrl1, X
	AND #%00000001
	BEQ LeftMove
	
RightMove:
	LDY <p1x, X
	INY
	STY <chx
	LDY <p1y, X
	STY <chy
	CPX #$00
	BNE :+
	JSR CollisionCheckP1
	JMP :++
:
	JSR CollisionCheckP2
:
	BNE MoveBlocked
	LDA <players
	BEQ :+
	JSR CollisionCheckAP
	BNE MoveBlocked
:
	LDX <temp3
	INC <p1x, X
	JMP MoveSuccess
	
LeftMove:
	LDY <p1x, X
	DEY
	STY <chx
	LDY <p1y, X
	STY <chy
	CPX #$00
	BNE :+
	JSR CollisionCheckP1
	JMP :++
:
	JSR CollisionCheckP2
:
	BNE MoveBlocked
	LDA <players
	BEQ :+
	JSR CollisionCheckAP
	BNE MoveBlocked
:
	LDX <temp3
	DEC <p1x, X
	
MoveSuccess:
	LDX <temp3
	LDA <dasbool, X
	BEQ :+
	LDA #$0A          ; Set delay so DAS repeats correctly
	STA <dastmr, X
:
	JMP CheckRotate
	
MoveBlocked:
	LDX <temp3
	LDA <dasbool, X
	BEQ :+
	LDA #$0A
	STA <dastmr, X
:
	JMP CheckRotate

CheckRotate:
	LDX <temp3
	LDA <ctrl1, X
	AND #%11000000
	BEQ NextPlayer
	
RotateButton:
	LDA <ctrl1, X
	AND #%10000000
	BNE PressedA
PressedB:
	LDA <ctrl1prev, X
	AND #%01000000
	BNE NextPlayer
	LDA <p1r, X
	PHA                 ; Push old rotation onto Stack AFTER validating press
	SEC
	SBC #01
	AND #03
	JMP TryRotate
PressedA:
	LDA <ctrl1prev, X
	AND #%10000000
	BNE NextPlayer
	LDA <p1r, X
	PHA                 ; Push old rotation onto Stack AFTER validating press
	CLC
	ADC #01
	AND #03
	
TryRotate:
	STA <p1r, X         ; Apply tentative new rotation
	TXA
	PHA                 ; Push X (Player Index) onto Stack
	
	; Seed chx/chy with current pos for collision routine
	LDY <p1x, X
	STY <chx
	LDY <p1y, X
	STY <chy
	
	CPX #$00
	BNE :+
	JSR CollisionCheckP1
	JMP :++
:
	JSR CollisionCheckP2
:
	BNE RotateBlocked
	LDA <players
	BEQ :+
	; Active piece collision
	JSR CollisionCheckAP
	BNE RotateBlocked
:
	; Rotation Success!
	PLA
	TAX
	PLA                 ; Pop and discard old rotation
	JMP NextPlayer
	
RotateBlocked:
	PLA
	TAX                 ; Restore X
	PLA                 ; Pull old rotation from stack
	STA <p1r, X         ; Restore original rotation value
	; Fall through to NextPlayer

NextPlayer:
	LDA <players
	BEQ :+
	LDA <temp3
	BNE :++
	LDA #$04
	STA <temp3
	LDA <ctrl1
	STA <ctrl1prev
	JMP CCLoop
:
	LDA <ctrl1
	STA <ctrl1prev
	JMP Main
:
	LDA <ctrl2
	STA <ctrl2prev
	JMP Main
RenderActivePiecesSub:
	; Render P1 Active Piece
	LDX <p1y
	STX <piece_y
	LDX <p1x
	STX <piece_x
	LDX <p1i
	STX <piece_index
	LDX <p1r
	STX <piece_rotation
	JSR RenderPiece
	LDA <players
	BNE :+
	RTS
:
	; Render P2 Active Piece
	LDX <p2x
	STX <piece_x
	LDX <p2y
	STX <piece_y
	LDX <p2i
	STX <piece_index
	LDX <p2r
	STX <piece_rotation
	JSR RenderPiece
	RTS

RenderNextPiecesSub:
	; Render P1 Next Piece
	LDX #$11
	STX <piece_x
	LDX #$03
	STX <piece_y
	LDX <p1ni
	STX <piece_index
	LDX #$00
	STX <piece_rotation
	JSR RenderPiece
	LDA <players
	BNE :+
	RTS
:
	; Render P2 Next Piece
	LDX #$11
	STX <piece_x
	LDX #$09
	STX <piece_y
	LDX <p2ni
	STX <piece_index
	LDX #$00
	STX <piece_rotation
RenderPiece:
	LDX <piece_index
	LDA piece_tile_tbl, X
	STA <tile_index
	LDA sl5tbl, X
	LDX <piece_rotation
	CLC
	ADC sl3tbl, X
	TAX ; X now holds index
	LDY <oam_ptr
RenderPieceLoop:
	LDA <piece_y
	CLC
	ADC pieces, X
	ASL A
	ASL A
	ASL A
	CLC
	ADC #47
	STA ty, Y
	LDA <tile_index
	STA ti, Y
	LDA <piece_x
	CLC
	ADC pieces+1, X
	ASL A
	ASL A
	ASL A
	CLC
	ADC #80
	STA tx, Y
	LDA #$00
	STA ta, Y
	INY
	INY
	INY
	INY
	INX
	INX
	CPY <oam_limit
	BNE RenderPieceLoop
	STY <oam_ptr
	TYA
	CLC
	ADC #$10
	STA <oam_limit
	RTS
FrameSyncLoop:
	LDA <sleep
	BNE FrameSyncLoop
	RTS
Lose:
	LDA #$00
	STA $4015
	JSR RenderActivePiecesSub
	JSR RenderNextPiecesSub
	JSR ReadControllers
	LDA <ctrl1
	AND #%10000000
	BEQ Lose
	JMP ResetGame
RenderScreen:
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006
	LDY #$00
MainRenderLoop:
	LDA [bgr_lo], Y
	CMP #$FF
	BEQ RenderScreenEnd
	CMP #$80
	BCS LiteralParse
RepeatParse:
	TAX
	INX
	INY
	LDA [bgr_lo], Y
RepeatLoop:
	STA $2007
	DEX
	BNE RepeatLoop
	BEQ AdvancePointer
LiteralParse:
	SEC
	SBC #$80
	TAX
	INX
LiteralLoop:
	INY
	LDA [bgr_lo], Y
	STA $2007
	DEX
	BNE LiteralLoop
AdvancePointer:
	INY
	BPL MainRenderLoop
	TYA
	LDY #$00
	CLC
	ADC <bgr_lo
	STA <bgr_lo
	BCC MainRenderLoop
	INC <bgr_hi
	JMP MainRenderLoop
RenderScreenEnd:
	RTS

; =========================================================================
; DPCM-SAFE CONTROLLER READING (Fixes Shared Bus Glitch)
; =========================================================================
ReadControllers:
	JSR ReadJoypadsOnce
	; Backup first read
	LDA <ctrl1
	STA <temp
	LDA <ctrl2
	STA <temp2
	; Read again
	JSR ReadJoypadsOnce
	; Compare results. If they don't match, a DPCM fetch corrupted the read, so try again.
	LDA <ctrl1
	CMP <temp
	BNE ReadControllers
	LDA <ctrl2
	CMP <temp2
	BNE ReadControllers
	RTS

ReadJoypadsOnce:
	LDA #$01
	STA $4016
	LSR A
	STA $4016
	LDX #$08
RCLoop:
	LDA $4016
	LSR A
	ROL <ctrl1
	LDA $4017
	LSR A
	ROL <ctrl2
	DEX
	BNE RCLoop
	RTS

MergePieceToBoard:
	LDX p1y, Y         ; Get piece Y coordinate
	DEX                ; Subtract 1 for rendering baseline
	LDA <rbool         ; Has a render already been requested this frame?
	BEQ SetRli         ; If not, just set it
	CPX <rli           
	BCS SkipRli        ; If new rli >= current rli, skip overwriting to preserve the higher starting point
SetRli:
	STX <rli
SkipRli:
	LDA #$01
	STA <rbool         ; Flag board for rendering
	LDX #$00
	STX <ctr
	LDX <p1i, Y
	LDA piece_tile_tbl, X
	STA <tile_index
	LDA sl5tbl, X
	LDX <p1r, Y
	CLC
	ADC sl3tbl, X
	TAX
	LDA #$00
MergeLoop:
	STA <ctr
	STX <temp
	; 1. Calculate Block Y
	LDA p1y, Y
	CLC
	ADC pieces, X         ; A = Block Y
	BMI SkipMergeBlock    ; If Y < 0 (above screen), safely skip this block
	TAX                   ; X = Block Y
	
	LDA mul12tbl, X       ; A = Block Y * 12
	LDX <temp
	CLC
	ADC p1x, Y
	CLC
	ADC pieces+1, X       ; A = (Block Y * 12) + Block X
	TAX                   ; X = Flat RAM Offset
	LDA <tile_index
	STA $0400, X          ; Store to Board RAM
SkipMergeBlock:
	; Advance pointers for next block
	LDX <temp
	INX
	INX
	LDA <ctr
	CLC
	ADC #02
	CMP #08
	BNE MergeLoop
	RTS

CollisionCheckP1:
	; 1. Calculate the base offset for the current piece and rotation
	LDX <p1i
	LDY <p1r
	JMP :+
CollisionCheckP2:
	LDX <p2i
	LDY <p2r
:
	LDA sl5tbl, X
	CLC
	ADC sl3tbl, Y
	STA <temp           ; temp = starting offset in `pieces` array

	LDY #$00            ; Y = block counter (0 to 3)
CheckLoop:
	LDX <temp           ; X = current block offset
	
	; 2. Calculate Block X and check horizontal boundaries
	LDA <chx
	CLC
	ADC pieces+1, X
	BMI CollisionFound  ; If X < 0 (left wall)
	CMP #$0C
	BCS CollisionFound  ; If X >= 12 (right wall)
	PHA                 ; Push Block X onto stack safely
	
	; 3. Calculate Block Y and check vertical boundaries
	LDA <chy
	CLC
	ADC pieces, X
	TAX                 ; X = Block Y
	
	; 4. Check Board RAM for collision
	PLA                 ; Pull Block X into A
	CLC
	ADC mul12tbl, X     ; A = Block X + (Block Y * 12)
	TAX                 ; X = Flat RAM Offset
	LDA $0400, X        ; Read cell from board RAM
	CMP #$25
	BNE CollisionFound  ; If not $25, space is occupied!
	JMP NextBlock

NextBlock:
	; 5. Advance to next block coordinate pair
	LDA <temp
	CLC
	ADC #$02
	STA <temp
	
	INY
	CPY #$04
	BNE CheckLoop

	; No collisions found
	LDA #$00
	RTS

CollisionFound:
	LDA #$01
	RTS

CollisionCheckAP:
	; 1. Calculate Active Piece Base Offset -> pci
	LDX <temp3
	LDY <p1i, X
	LDA sl5tbl, Y       ; Active piece index offset
	LDY <p1r, X
	CLC
	ADC sl3tbl, Y       ; Active piece rotation offset
	STA <pci

	; 2. Calculate Other Player data
	LDA <temp3
	EOR #$04            ; Swap between 0 (P1) and 4 (P2)
	TAX
	
	LDY <p1i, X
	LDA sl5tbl, Y       ; Other piece index offset
	LDY <p1r, X
	CLC
	ADC sl3tbl, Y       ; Other piece rotation offset
	STA <mpi
	
	LDA p1x, X
	STA <lx
	LDA p1y, X
	STA <ly

	; 3. Compare all 4 blocks against all 4 blocks (16 checks)
	LDA #$00
	STA <temp           ; Active block counter
AP_OuterLoop:
	LDA #$00
	STA <temp2          ; Other block counter
AP_InnerLoop:
	; Compare absolute X coordinates
	LDA <pci
	CLC
	ADC <temp
	TAX
	LDA <chx
	CLC
	ADC pieces+1, X     ; A = Active Block X
	STA <ctr            ; Store temporarily
	
	LDA <mpi
	CLC
	ADC <temp2
	TAX
	LDA <lx
	CLC
	ADC pieces+1, X     ; A = Other Block X
	CMP <ctr
	BNE NextAPBlock     ; If X doesn't match, skip Y check

	; Compare absolute Y coordinates
	LDA <pci
	CLC
	ADC <temp
	TAX
	LDA <chy
	CLC
	ADC pieces, X       ; A = Active Block Y
	STA <ctr            ; Store temporarily
	
	LDA <mpi
	CLC
	ADC <temp2
	TAX
	LDA <ly
	CLC
	ADC pieces, X       ; A = Other Block Y
	CMP <ctr
	BEQ APCollision     ; Both X and Y match! Collision confirmed.

NextAPBlock:
	LDA <temp2
	CLC
	ADC #$02            ; Advance 2 bytes (Y, X pair)
	STA <temp2
	CMP #$08            ; 4 blocks * 2 bytes = 8
	BNE AP_InnerLoop

	LDA <temp
	CLC
	ADC #$02
	STA <temp
	CMP #$08
	BNE AP_OuterLoop

	; No collision found
	LDA #$00
	RTS

APCollision:
	LDA #$01
	RTS
LineCheck:
	LDX <p1y, Y
	DEX
	STX <lineBase
	LDY #$FF
	STY <lineClearAnimFrameIndex
	INY
	STY <clearedBool
LineCheckLoop:
	LDX <lineBase
	STY <lineIndex
	LDA mul12tbl, X
	TAX
	LDY #$0C
LineCmpLoop:
	LDA $0400, X
	CMP #$25
	BEQ NextLine
	INX
	DEY
	BNE LineCmpLoop
LineNeedsClearing:
	LDX <lineBase
	CPX #20
	BCS NextLine
	CPX #00
	BPL :+
NextLine:
	LDX #$FF
	BMI :++
:
	INC <clearedBool
:
	LDY <lineIndex
	STX <clearedLines, Y
	INC <lineBase
	INY
	CPY #04
	BNE LineCheckLoop
	RTS

ShiftBoard:
	LDY #$00
	STY <animBool
	DEY
	STY <lineClearAnimFrameIndex
:
	INY
	LDX <clearedLines, Y
	BMI :+
	LDA mul12tbl, X
	TAX
	DEX
ShiftLoop:
	LDA $0400, X
	STA $040C, X
	DEX
	CPX #$FF
	BNE ShiftLoop
:
	CPY #03
	BNE :--
	RTS
TempJump:
	JMP SkipRenderAll
;;;;;;;;
NMI:
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA $2002            ; Reset latch

	; Perform Sprite DMA
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014
	LDA $2002
	
	; Flush VRAM updates queued during Main logic
RenderBoard:
	; 1. Check if we are currently animating a line clear
	LDA <copyBool
	BNE RenderLineClearAnim

	; 2. Check if the board needs rendering
	LDA <rbool
	BEQ TempJump
	LDA <rli
	CMP #21
	BMI :+
	
	; 3. Board finished rendering. Turn off rendering.
	LDA #$00
	STA <rbool
	; 4. If a line was cleared, trigger the animation on the NEXT frame
	LDA <clearedBool
	STA <copyBool
	LDA <lineClearIndex
	ASL A
	ASL A
	TAX
	LDA <render_parity
	BEQ NotSwapped1
	LDA <players
	BEQ OneSwapped
	TXA
	CLC
	ADC #$20
	TAX
	JMP NotSwapped1
OneSwapped:
	LDX #$10
NotSwapped1:
	TXA
	TAY
	LDA #$25
	STA ti, Y
	STA ti+4, Y
	STA ti+8, Y
	STA ti+12, Y
	JMP SkipRenderAll
:
	JSR CopyRowToBoard
	JSR CopyRowToBoard
	JSR CopyRowToBoard
	JSR CopyRowToBoard
	JMP SkipRenderAllNoRemoveFlash
RenderLineClearAnim:
	LDA <frameCounter
	AND #$03
	BNE tmp
	LDA <clearedBool
	CMP #$04
	BNE noFlash
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$01
	STA $2006
	LDA #$30
	STA $2007
noFlash:
	INC <lineClearAnimFrameIndex
	
	; FIX: Check if we hit frame 6 BEFORE doing any VRAM math
	LDA <lineClearAnimFrameIndex
	CMP #06
	BNE DoAnimRender
	
	; Animation complete, reset variables and skip
	LDA #$00
	STA <lineClearAnimFrameIndex
	STA <clearedBool
	STA <copyBool
	INC <animBool
tmp:
	JMP SkipRenderAll

DoAnimRender:
	LDY #$00
AnimLoop:
	; Left cascade
	LDA clearedLines, Y
	BMI NextAnimLine
	ASL A
	TAX
	LDA vramBoardRowTable, X
	STA <vbtemp
	STA $2006
	LDA vramBoardRowTable+1, X
	STA <vbtemp2
	LDX <lineClearAnimFrameIndex
	CLC
	ADC leftCascadeTable, X
	STA $2006
	LDA #$25
	STA $2007
	
	; Right cascade
	LDA $2002
	LDA <vbtemp
	STA $2006
	LDA <vbtemp2
	CLC
	ADC rightCascadeTable, X
	STA $2006
	LDA #$25
	STA $2007
NextAnimLine:
	INY
	CPY #04
	BNE AnimLoop
	JMP SkipRenderAllNoRemoveFlash
SkipRenderAll:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$01
	STA $2006
	LDA #$00
	STA $2007
SkipRenderAllNoRemoveFlash:
	JSR ScoreToVRAM
	JSR LinesToVRAM
	LDA <level_updated
	BEQ :+
	JSR LevelInit
:
	JSR LevelToVRAM
	LDA $2002
	; Reset Scroll Registers after VRAM access
	LDA #%10000000       ; Enable NMI, select Nametable $2000
	STA $2000
	LDA #$00
	STA $2005
	STA $2005
	STA <sleep           ; Signal frame timing complete
	INC <frameCounter
	PLA
	TAY
	PLA
	TAX
	PLA
	RTI

CopyRowToBoard:
	LDA $2002
	LDA <rli
	CMP #21
	BPL RenderDone
	TAX
	LDY mul12tbl, X
	TXA
	ASL A
	TAX
	LDA vramBoardRowTable, X
	STA $2006
	LDA vramBoardRowTable+1, X
	STA $2006
	LDX #$0C
CopyLoop:
	LDA $0400, Y
	STA $2007
	INY
	DEX
	BNE CopyLoop
RenderDone:
	INC <rli
	RTS
CalculateLevel:
	LDX <lines_12
	LDA BCDDispTable, X
	LSR A
	LSR A
	LSR A
	LSR A
	STA <temp
	LDA <lines_hi
	ASL A
	ASL A
	ASL A
	ASL A
	ORA <temp
ConvToBCD:
	TAX
	AND #$F0
	LSR A
	STA <temp
	LSR A
	LSR A
	CLC
	ADC <temp
	STA <temp
	TXA
	AND #$0F
	CLC
	ADC <temp
	LDX #$00
	CMP <start_level
	BCS :+
	RTS
:
	CMP <level
	BEQ NotNewLevel
	INX
NotNewLevel:
	STX <level_updated
	STA <level
	RTS
ScoreToVRAM:
	LDX #$00
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$4E
	STA $2006
ConvLoop:
	LDA <score_56, X
	AND #$F0
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$40
	STA $2007
	LDA <score_56, X
	AND #$0F
	CLC
	ADC #$40
	STA $2007
	INX
	CPX #$03
	BNE ConvLoop
	RTS
LinesToVRAM:
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$55
	STA $2006
	LDA <lines_hi
	CLC
	ADC #$40
	STA $2007
	LDX <lines_12
GeneralNumToVRAM:
	LDA BCDDispTable, X
	TAX
	AND #$F0
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$40
	STA $2007
	TXA
	AND #$0F
	CLC
	ADC #$40
	STA $2007
	RTS
LevelToVRAM:
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$5B
	STA $2006
	LDX <level
	JSR GeneralNumToVRAM
	RTS
RandGen:
	LDA <randSeed
	LSR A
	BCC Skip
	EOR #$8E
Skip:
	STA <randSeed
	RTS
LevelInit:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$04
	STA $2006
	LDA <level
	CMP #10
	BCC Fine
SubLoop:
	SEC
	SBC #10
	CMP #10
	BCS SubLoop
Fine:
	ASL A
	ASL A
	PHA
	TAX
	LDY #$04
PaletteLoop1:
	LDA piece_color_tbl, X
	STA $2007
	INX
	DEY
	BNE PaletteLoop1
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$10
	STA $2006
	PLA
	TAX
	LDY #$04
PaletteLoop2:
	LDA piece_color_tbl, X
	STA $2007
	INX
	DEY
	BNE PaletteLoop2
	LDX <level
	CPX #30
	BCC :+
	LDX #29
:
	LDA dropSpeedTable, X
	STA <fall_thresold
	LDA #$00
	STA <fall_timer
	RTS
AddScore:
	; --- 1. If score is already 999999, don't add ---
	LDA <score_56
	CMP #$99
	BNE :+
	LDA <score_12
	CMP #$99
	BNE :+
	LDA <score_34
	CMP #$99
	BEQ @exit                 ; Score is 999999, exit early
:
	LDA <clearedBool
	ASL A
	TAY
	DEY
	DEY

	; --- 2. Add score_12 (Lowest bytes) ---
	LDA <score_12
	CLC
	ADC scoreAddTable+1, Y
	PHP
	TAX
	AND #$0F
	CMP #$0A
	BCC :+
	TXA
	ADC #$05
	TAX
:
	TXA
	PLP
	BCS :+
	CMP #$A0
	BCC :++
:
	ADC #$5F
	SEC                       ; Ensure Carry is set if upper nibble overflowed
:
	STA <score_12             ; Store BCD score_12 (STA preserves C flag)

	; --- 3. Add score_34 (Middle bytes) ---
	LDA <score_34
	ADC scoreAddTable, Y      ; Uses Carry from score_12
	PHP
	TAX
	AND #$0F
	CMP #$0A
	BCC :+
	TXA
	ADC #$05
	TAX
:
	TXA
	PLP
	BCS :+
	CMP #$A0
	BCC :++
:
	ADC #$5F
	SEC                       ; Ensure Carry is set if upper nibble overflowed
:
	STA <score_34             ; Store BCD score_34 (STA preserves C flag)

	; --- 4. Add score_56 (Highest bytes) ---
	LDA <score_56
	ADC #$00                  ; Uses Carry from score_34
	PHP
	TAX
	AND #$0F
	CMP #$0A
	BCC :+
	TXA
	ADC #$05
	TAX
:
	TXA
	PLP
	BCS ClampScore
	CMP #$A0
	BCS ClampScore
	STA <score_56             ; Normal store if score <= 999999
@exit:
	RTS

; --- Helper: Clamp score to 999999 ---
ClampScore:
	LDA #$99
	STA <score_56
	STA <score_12
	STA <score_34
	RTS
	
	
; =========================================================================
; APU UPDATE ENGINE (Parses raw binary sequence output)
; =========================================================================
APU_Init:
	LDA #$0F
	STA $4015            ; Enable all 4 standard channels
	LDA #$00
	STA delay_counter    ; Clear delay timer
	LDA #$01
	STA apu_playing
	RTS

APU_Update:
	LDA apu_playing
	BEQ apu_done

	; If delay_counter > 0, decrement and wait for next frame
	LDA delay_counter
	BEQ read_loop
	DEC delay_counter
	RTS

read_loop:
	LDY #$00
	LDA [music_ptr_lo], Y
	CMP #$FF
	BEQ end_frame
	CMP #$FE
	BEQ loop_music
	CMP #$FD
	BEQ handle_delay

	TAX                  ; A = Register offset
	INY
	LDA [music_ptr_lo], Y ; Read Value
	STA $4000, X         ; Write to APU hardware

	; Advance pointer by 2 bytes
	LDA <music_ptr_lo
	CLC
	ADC #$02
	STA <music_ptr_lo
	BCC read_loop
	INC <music_ptr_hi
	JMP read_loop

handle_delay:
	INY
	LDA [music_ptr_lo], Y ; Read delay frame count
	STA delay_counter

	; Advance pointer by 2 bytes past $FD [count]
	LDA <music_ptr_lo
	CLC
	ADC #$02
	STA <music_ptr_lo
	BCC delay_done
	INC <music_ptr_hi
delay_done:
	RTS

end_frame:
	; Advance pointer by 1 byte past the $FF end-marker
	INC <music_ptr_lo
	BNE apu_done
	INC <music_ptr_hi
apu_done:
	RTS

loop_music:
	LDA #LOW(music_data)
	STA <music_ptr_lo
	LDA #HIGH(music_data)
	STA <music_ptr_hi
	JMP read_loop
;;;;;;;;

; Data (ignore)

.org $A000

palette:
	.byte $0F, $00, $3C, $30
	.byte $0F, $30, $21, $12
	.byte $0F, $0F, $0F, $0F
	.byte $0F, $0F, $0F, $0F
	.byte $0F, $30, $21, $12
	.byte $0F, $0F, $0F, $0F
	.byte $0F, $0F, $0F, $0F
	.byte $0F, $0F, $0F, $0F

scoreAddTable:
	.byte $00, $40
	.byte $01, $00
	.byte $03, $00
	.byte $12, $00
	
BCDDispTable:
	.byte $0, $1, $2, $3, $4, $5, $6, $7
	.byte $8, $9, $10, $11, $12, $13, $14, $15
	.byte $16, $17, $18, $19, $20, $21, $22, $23
	.byte $24, $25, $26, $27, $28, $29, $30, $31
	.byte $32, $33, $34, $35, $36, $37, $38, $39
	.byte $40, $41, $42, $43, $44, $45, $46, $47
	.byte $48, $49, $50, $51, $52, $53, $54, $55
	.byte $56, $57, $58, $59, $60, $61, $62, $63
	.byte $64, $65, $66, $67, $68, $69, $70, $71
	.byte $72, $73, $74, $75, $76, $77, $78, $79
	.byte $80, $81, $82, $83, $84, $85, $86, $87
	.byte $88, $89, $90, $91, $92, $93, $94, $95
	.byte $96, $97, $98, $99
pieces:
	; =========================================================================
	; 1. I PIECE
	; =========================================================================
	; Rotation 0 (Vertical)
	.byte $FF, $00,  $00, $00,  $01, $00,  $02, $00
	; Rotation 1 (Horizontal)
	.byte $FF, $FF,  $FF, $00,  $FF, $01,  $FF, $02
	; Rotation 2 (Vertical)
	.byte $FF, $00,  $00, $00,  $01, $00,  $02, $00
	; Rotation 3 (Horizontal)
	.byte $FF, $FF,  $FF, $00,  $FF, $01,  $FF, $02

	; =========================================================================
	; 2. J PIECE
	; =========================================================================
	; Rotation 0 (Pointing Up)
	.byte $FF, $00,  $00, $00,  $01, $00,  $01, $FF
	; Rotation 1 (Pointing Right)
	.byte $FF, $FF,  $00, $FF,  $00, $00,  $00, $01
	; Rotation 2 (Pointing Down)
	.byte $FF, $00,  $00, $00,  $01, $00,  $FF, $01
	; Rotation 3 (Pointing Left)
	.byte $FF, $FF,  $FF, $00,  $FF, $01,  $00, $01

	; =========================================================================
	; 3. L PIECE
	; =========================================================================
	; Rotation 0 (Pointing Up)
	.byte $FF, $00,  $00, $00,  $01, $00,  $01, $01
	; Rotation 1 (Pointing Right)
	.byte $FF, $FF,  $FF, $00,  $FF, $01,  $00, $FF
	; Rotation 2 (Pointing Down)
	.byte $FF, $00,  $00, $00,  $01, $00,  $FF, $FF
	; Rotation 3 (Pointing Left)
	.byte $FF, $01,  $00, $FF,  $00, $00,  $00, $01

	; =========================================================================
	; 4. O PIECE (Square)
	; =========================================================================
	; Rotation 0
	.byte $FF, $00,  $FF, $01,  $00, $00,  $00, $01
	; Rotation 1
	.byte $FF, $00,  $FF, $01,  $00, $00,  $00, $01
	; Rotation 2
	.byte $FF, $00,  $FF, $01,  $00, $00,  $00, $01
	; Rotation 3
	.byte $FF, $00,  $FF, $01,  $00, $00,  $00, $01

	; =========================================================================
	; 5. S PIECE
	; =========================================================================
	; Rotation 0 (Horizontal)
	.byte $FF, $00,  $FF, $01,  $00, $FF,  $00, $00
	; Rotation 1 (Vertical)
	.byte $FF, $00,  $00, $00,  $00, $01,  $01, $01
	; Rotation 2 (Horizontal)
	.byte $FF, $00,  $FF, $01,  $00, $FF,  $00, $00
	; Rotation 3 (Vertical)
	.byte $FF, $00,  $00, $00,  $00, $01,  $01, $01

	; =========================================================================
	; 6. T PIECE
	; =========================================================================
	; Rotation 0 (Pointing Down)
	.byte $FF, $FF,  $FF, $00,  $FF, $01,  $00, $00
	; Rotation 1 (Pointing Left)
	.byte $FF, $00,  $00, $00,  $01, $00,  $00, $FF
	; Rotation 2 (Pointing Up)
	.byte $FF, $00,  $00, $FF,  $00, $00,  $00, $01
	; Rotation 3 (Pointing Right)
	.byte $FF, $00,  $00, $00,  $01, $00,  $00, $01

	; =========================================================================
	; 7. Z PIECE
	; =========================================================================
	; Rotation 0 (Horizontal)
	.byte $FF, $FF,  $FF, $00,  $00, $00,  $00, $01
	; Rotation 1 (Vertical)
	.byte $FF, $01,  $00, $00,  $00, $01,  $01, $00
	; Rotation 2 (Horizontal)
	.byte $FF, $FF,  $FF, $00,  $00, $00,  $00, $01
	; Rotation 3 (Vertical)
	.byte $FF, $01,  $00, $00,  $00, $01,  $01, $00
piece_tile_tbl:
	.byte $30, $32, $31, $33, $32, $30, $31
piece_color_tbl:
	.byte $0F, $30, $21, $12
	.byte $0F, $30, $29, $1A
	.byte $0F, $30, $24, $14
	.byte $0F, $30, $2A, $12
	.byte $0F, $30, $2B, $15
	.byte $0F, $30, $22, $2B
	.byte $0F, $30, $00, $16
	.byte $0F, $30, $05, $13
	.byte $0F, $30, $16, $12
	.byte $0F, $30, $27, $16
dropSpeedTable:
	.byte   $3A, $34, $2E, $28, $22, $1C, $16, $10  ; Levels 0–7  (originally $30–$0D)
	.byte   $0A, $07, $06, $06, $06, $05, $05, $05  ; Levels 8–15 (originally $08–$04)
	.byte   $04, $04, $04, $02, $02, $02, $02, $02  ; Levels 16–23 (originally $03–$02)
	.byte   $02, $02, $02, $02, $02, $01            ; Levels 24–29 (Levels 28 & 29 unchanged at $01)
sl5tbl:
	.byte $00, $20, $40, $60, $80, $A0, $C0
sl3tbl:
	.byte $00, $08, $10, $18
mod7tbl:
	.byte 0, 1, 2, 3, 4, 5, 6, 0
mul12tbl:
	.byte 0, 12, 24, 36, 48, 60, 72
	.byte 84, 96, 108, 120, 132, 144
	.byte 156, 168, 180, 192, 204, 216
	.byte 228, 240, 252
pressStart:
	.byte $1B, $28, $1D, $2B, $2B, $25, $2B, $1F, $2C, $28, $1F
startLv:
	.byte $2B, $1F, $2C, $28, $1F, $25, $29, $2A
vramBoardRowTable:
	.byte $20, $CA, $20, $EA, $21, $0A
	.byte $21, $2A, $21, $4A, $21, $6A
	.byte $21, $8A, $21, $AA, $21, $CA
	.byte $21, $EA, $22, $0A, $22, $2A
	.byte $22, $4A, $22, $6A, $22, $8A
	.byte $22, $AA, $22, $CA, $22, $EA
	.byte $23, $0A, $23, $2A, $23, $4A
leftCascadeTable:
	.byte 5, 4, 3, 2, 1, 0
rightCascadeTable:
	.byte 6, 7, 8, 9, 10, 11
thebg:
	.incbin "C:\Users\Admin\Downloads\nametable_smart_rle_778B.bin"
	.byte $FF
	
music_data:
	.incbin "F:\SSS\TXT2MUSIC\music.bin"
;;;;;;;;
.prg 1
.org $FFFA

	.dw NMI
	.dw RESET
	.dw 0

;;;;;;;;;;;;;;;;

.chr 0
	.incbin "C:\Users\Admin\Downloads\tiles_1184B.bin"
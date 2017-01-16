;==============================================================================
; Test 4
; Castle with moat and drawbridge using reflected playfield
;
; Copyright 2017 James O'Reilly
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;		 http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;==============================================================================

		processor 6502
		include vcs.h	; this lib is included with DASM

;==============================================================================
; CONSTANTS
;
PF_REFLECT	= #%00000001	; Mirror the playfield. D0=1

FRAME_SPEED	= 25		; Num of frames per playfield

BG_COLOR	= $00		; Black

CASTLE_COLOR	= $09		; Medium Gray
CASTLE_BYTES	= 11
CASTLE_SLINES	= 8

DOOR_COLOR	= $F3		; Dark Brown
DOOR_SLINES	= 32

DIRT_COLOR	= $F3		; Dark Brown

WATER_DK_COLOR	= $A8		; Medium Teal
WATER_LT_COLOR	= $AA		; Light Teal
WATER_SLINES	= 5

BRIDGE_COLOR	= $F5		; Medium Brown
BRIDGE_SLINES	= 24

GRASS_COLOR	= $B3
GRASS_SLINES	= 43

;==============================================================================
; VARIBLES
;
		SEG.U Variables
		ORG $80

		SEG

;==============================================================================
; START
;
		ORG $F000	; Starting location of ROM
Start		SEI		; Disable any interrupts

;==============================================================================
; RESET
;
Reset		CLD		; Clear BCD math bit

		LDX #$FF
		TXS		; Set stack to beginning	

		LDA #0		; Loop backwards from $FF to $00
.ClearLoop	STA $00,X	; and clear each memory location
		DEX
		BNE .ClearLoop

;==============================================================================
; INIT
;
Initialize	LDA BG_COLOR
		STA COLUBK
		
		LDA #PF_REFLECT
		STA CTRLPF

;==============================================================================
; MAIN LOOP
;
MainLoop	JSR VerticalSync
		JSR VerticalBlank
		JSR FrameSetup
		JSR Scanline
		JSR OverScan
		JMP MainLoop

;==============================================================================
; V-SYNC (3 Scanlines)
;
; Reset TV Signal to indicate new frame
; D1 but must be enabled here which is 00000010 (e.g 2 in dec.)
;
VerticalSync	LDA #0
		STA VBLANK

		LDA #2
		STA VSYNC	; Begin VSYNC period

		STA WSYNC	; Halt 6502 until end of scanline 1
		STA WSYNC	; Halt 6502 until end of scanline 2
		RTS

;==============================================================================
; V-BLANK (37 Scanlines)
;
; Start a timer for enough cycles to approximate 36 scanlines
; Ideally, we're putting logic here instead.
; At 228 clock counts per scan line, we get 36 * 228 = 8208
; therefore 6502 instruction count would be 8208 / 3 = 2736
; 42 * 64 = 2688 (close enough, we'll fix it on the last line)
;
VerticalBlank	LDA #42
		STA TIM64T	; Start the timer with 42 ticks

		LDA #0
		STA WSYNC	; Halt 6502 until end of scanline 3
		STA VSYNC	; End VSYNC period
		RTS

;==============================================================================
; FRAME SETUP
;
FrameSetup	LDA #CASTLE_COLOR
		STA COLUPF

		RTS
		; V-BLANK is finished at start of Scanline
		
;==============================================================================
; SCANLINE (192 Scanlines)
;
Scanline	LDA INTIM	; Loop until the V-Blank timer finishes
		BNE Scanline
		
		LDA #0		; End V-BLANK period with 0
		STA WSYNC	; Halt 6502 until end of scanline
		STA VBLANK	; Begin drawing to screen again

		;==================================
		; Castle Top
		;
		LDX #CASTLE_BYTES
.CTLoop		LDA BGCData_CT,X	; Fetch BG Color
		STA COLUBK		;   and set it

		LDA PFData0_CT,X	; Fetch PF0 data
		STA PF0			;   and set it

		LDA PFData1_CT,X	; Fetch PF1 data
		STA PF1			;   and set it

		LDA PFData2_CT,X	; Fetch PF2 data
		STA PF2			;   and set it

		LDY #CASTLE_SLINES
.CTSLLoop	STA WSYNC	; Halt 6502 until end of scanline
		DEY		; Next scanline
		BNE .CTSLLoop	; Keep rendering scanlines until "pixel" is done
		
		DEX		; Next "pixel" row
		BNE .CTLoop	; Keep rendering rows until screen is finished

		;==================================
		; Castle Door
		;
		LDA #%11000000
		STA PF0
		LDA #%11111111
		STA PF1
		LDA #%00111111
		STA PF2
		
		LDA #DOOR_COLOR
		STA COLUBK

		LDY #DOOR_SLINES
.CDLoop		STA WSYNC
		DEY
		BNE .CDLoop
		
		;==================================
		; Dirt Line
		;
		LDA #DIRT_COLOR
		STA COLUPF
		STA COLUBK

		STA WSYNC
		
		;==================================
		; Moat
		;
		LDA #%11110000
		STA PF0

		LDA #WATER_DK_COLOR
		STA COLUPF

		LDA #BRIDGE_COLOR
		STA COLUBK

		LDY #WATER_SLINES
.WTRLoop	STA WSYNC
		DEY
		BNE .WTRLoop
		
		;==================================
		; Bridge
		;
		LDA #WATER_LT_COLOR
		STA COLUPF

		LDY #BRIDGE_SLINES
.BRGLoop	STA WSYNC
		DEY
		BNE .BRGLoop

		;==================================
		; Grass
		;
		LDA #GRASS_COLOR
		STA COLUBK

		LDA #0
		STA PF0
		STA PF1
		STA PF2

		LDY #GRASS_SLINES
.GRSLoop	STA WSYNC
		DEY
		BNE .GRSLoop

		;==================================
		; End
		;
		LDA #2
		STA VBLANK	; Suppress drawing to screen
		RTS

;==============================================================================
; OVERSCAN (30 Scanlines)
;
OverScan	LDX #30		; x = 30; 
		LDA #2
.OSLoop		STA WSYNC	; Halt 6502 until end of scanline
		DEX		; x--
		BNE .OSLoop	; if x !== 0 goto .OSLoop
		RTS

;==============================================================================
; DATA
;

BGCData_CT	.byte $B3,$7D,$7B,$79
		.byte $77,$75,$75,$73
		.byte $73,$71,$71,$71
		
PFData0_CT	.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%10100000
		.byte #%00000000
		.byte #%00000000

PFData1_CT	.byte #%11111111
		.byte #%11111111
		.byte #%11111111
		.byte #%11111111
		.byte #%11111110
		.byte #%10001010
		.byte #%10001110
		.byte #%10010101
		.byte #%10000000
		.byte #%01000000
		.byte #%00000000
		.byte #%00000000

PFData2_CT	.byte #%11111111
		.byte #%11111111
		.byte #%11111111
		.byte #%11111111
		.byte #%11010101
		.byte #%11000000
		.byte #%11000000
		.byte #%11000000
		.byte #%10100000
		.byte #%00000000
		.byte #%00000000
		.byte #%00000000

;==============================================================================
; INTERRUPT VECTORS
;
		org $FFFC	; 6502 looks here to start execution

		.word Start	; NMI
		.word Start	; Reset
		.word Start	; IRQ

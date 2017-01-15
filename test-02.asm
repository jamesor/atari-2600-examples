;==============================================================================
; Test 2
; Gradient Background
;
; Copyright 2017 James O'Reilly
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
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
BLACK		= $00
FIRST_COLOR	= $7F
COLOR_STEPS	= 15

;==============================================================================
; VARIBLES
;
		SEG.U Variables
		ORG $80

stopColor	ds 1

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
Initialize	LDA #BLACK
		STA COLUBK
		
		LDA #FIRST_COLOR
		SBC #COLOR_STEPS
		STA stopColor

;==============================================================================
; MAIN LOOP
;
MainLoop	JSR VerticalSync
		JSR VerticalBlank
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
; 43 * 64 = 2752 (close enough, we'll fix it on the last line)
;
VerticalBlank	LDA #43
		STA TIM64T	; Start the timer with 43 ticks

		LDA #0
		STA WSYNC	; Halt 6502 until end of scanline 3
		STA VSYNC	; End VSYNC period
		RTS

;==============================================================================
; SCANLINE (192 Scanlines)
;
Scanline	LDA INTIM	; Loop until the V-Blank timer finishes
		BNE Scanline
		
		LDA #0		; End V-BLANK period with 0
		STA WSYNC	; Halt 6502 until end of scanline
		STA VBLANK	; Begin drawing to screen again

		LDA #FIRST_COLOR
.SLLoop		STA COLUBK	; Set the current color as background color
		STA WSYNC	; 12 scanlines of the same color
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		STA WSYNC
		
		SBC #$01	; Step down to next color
		CMP stopColor	; Check to see if we are on the last color
		BNE .SLLoop	; And do it again if we aren't

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
; INTERRUPT VECTORS
;
		org $FFFC	; 6502 looks here to start execution

		.word Start	; NMI
		.word Start	; Reset
		.word Start	; IRQ

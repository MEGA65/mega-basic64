.if 0
		XXX - When performing a syntax or other errors, check if we have
		saved ZP variables, and if so, restore them.
		XXX - Canvas set tile command
		XXx - Tile edit pixel command
		XXX - How to implement functions as BASIC extension
.endif

		
;-------------------------------------------------------------------------------
;BASIC interface 
;-------------------------------------------------------------------------------
	.code
	.org		$07FF			;start 2 before load address so
						;we can inject it into the binary
						
	.byte		$01, $08		;load address
	
	.word		_basNext, $000A		;BASIC next addr and this line #
	.byte		$9E			;SYS command
	.asciiz		"2061"			;2061 and line end
_basNext:
	.word		$0000			;BASIC prog terminator
	.assert         * = $080D, error, "BASIC Loader incorrect!"
bootstrap:
		JMP	init

		;;  C64 BASIC extension vectors
		tokenise_vector		=	$0304
		untokenise_vector	=	$0306
		execute_vector		=	$0308
		
;-------------------------------------------------------------------------------
init:
		;; Get acces to DMAgic etc
		LDA	#$47
		STA	$D02F
		LDA	#$53
		STA	$D02F
		
		;; Install $C000 block (and preloaded tiles)
		;; (This also does most of the work initialising the screen)
		lda 	#>c000blockdmalist
		sta	$d701
		lda	#<c000blockdmalist
		sta	$d705
		;; Now patch the screen update by filling the canvas display
		;; with spaces. The canvas screen is 80*50 * 2 bytes per char,
		;; so 8000 bytes in total.  We only need to fill the top 25 rows,
		;; however.
		LDA	#$20
		LDX	#$00
@spaceLoop:
		STA	$E000, X
		STA	$E100, X
		STA	$E200, X
		STA 	$E300, X
		STA	$E400, X
		STA	$E500, X
		STA	$E600, X
		STA	$E700, X
		STA	$E800, X
		STA	$E900, X
		STA	$EA00, X
		STA	$EB00, X
		STA 	$EC00, X
		STA	$ED00, X
		STA	$EE00, X
		STA	$EF00, X
		INX
		INX
		BNE	@spaceLoop

		;; enable wedge
		jsr 	megabasic_enable

		;; Then make the demo tile set available for use
		jsr 	tileset_point_to_start_of_area
		jsr 	tileset_install

		;; Finally, set up the raster interrupt to happen at raster
		;; $100 (just below bottom of text area).
		SEI	
		LDA	#<raster_irq
		STA	$0314
		LDA	#>raster_irq
		STA	$0315		
		LDA	#$7F
		STA	$DC0D
		STA	$DC0E
		LDA	#$9B
		STA	$D011
		LDA	#$00
		STA	$D012
		LDA	#$81
		STA	$D01A
		CLI

		;; XXX And setup NMI ($0318) and BRK ($0316) catchers?
		;; (Model of $FE47 in C64 KERNAL).
		
		rts

c000blockdmalist:
		;; Install pre-prepared tileset @ $12000+
		.byte $0A,$00 	; F011A list follows
		;; Normal F011A list
		.byte $04 ; copy + chained request
		.word preloaded_tiles_length ; set size
		.word preloaded_tiles  ; starting at $4000
		.byte $00   ; of bank $0
		.word $2000 ; destination address is $2000
		.byte $01   ; of bank $1 ( = $12000)
		.word $0000 ; modulo (unused)		

		;; Clear $A000-$FFFF out (so that we can put screen data
		;; at $A000-$BFFF and $E000-$FFFF). This obviously has to
		;; happen BEFORE we copy our code into $C000 :)
		.byte $0A,$00 	; F011A list follows		
		;; Normal F011A list
		.byte $07 ; fill + chained
		.word $10000-$A000 ; size of copy 
		.word $0000 ; source address = fill value
		.byte $00   ; of bank $0
		.word $A000 ; destination address is $A000
		.byte $00   ; of bank $0
		.word $0000 ; modulo (unused)

		;; Clear colour RAM at $FF80800-$FF847FF to go with the above
		.byte $81,$FF  	; destination is $FFxxxxx
		.byte $0A,$00 	; F011A list follows
		;; Normal F011A list
		.byte $07 ; fill + chained
		.word $4000 ; size of copy is 16KB
		.word $0000 ; source address = fill value
		.byte $00   ; of bank $0
		.word $0800 ; destination address is $0800
		.byte $08   ; of bank $0
		.word $0000 ; modulo (unused)
		;;  Clear option $81 from above
		.byte $81,$00
		
		;; Copy MEGA BASIC code to $C000+
		.byte $0A,$00 	; F011A list follows		
		;; Normal F011A list
		.byte $00 ; copy + end of list chain
		.word $1000 ; size of copy is 4KB
		.word c000block ; source address
		.byte $00   ; of bank $0
		.word $C000 ; destination address is $C000
		.byte $00   ; of bank $0
		.word $0000 ; modulo (unused)		


preloaded_tiles:
		;; 		.incbin "bin/megabanner.tiles" 
		.incbin "bin/vehicle_console.tiles" 
preloaded_tiles_end:	
		preloaded_tiles_length = preloaded_tiles_end - preloaded_tiles
		
;-------------------------------------------------------------------------------
		;; Routines that get installed at $C000
;-------------------------------------------------------------------------------
c000block:	
		.org $C000

		;; Jump-table of functions

		;; $C000 - Initialise MEGA BASIC
		jmp	megabasic_enable
		;; $C003 - Clear a canvas
		jmp	canvas_clear_region
		;; $C006 - Stamp a canvas
		jmp	megabasic_stamp_canvas
		;;  $C009 - Select canvas specified in A as primary
		jmp	canvas_set_source
		;; $C00C - Setup source canvas region
		JMP	canvas_setup_region
		;; $C00F - Setup target canvas and position
		jmp	canvas_setup_target
		;; $C012 - Stash ZP values
		JMP	zp_scratch_stash
		;; $C015 - Restore ZP values
		JMP	zp_scratch_restore

canvas_set_source:
		;;  Find canvas and set active region to match dimensions
		STA	source_canvas
		JSR 	canvas_prepare_pointers
		LDA	$07
		STA	source_canvas_x2
		LDA	$08
		STA	source_canvas_y2
		RTS

canvas_setup_region:
		STX	source_canvas_x1
		STY	source_canvas_y1
		STA	source_canvas_x2
		STZ	source_canvas_y2
		RTS
		
canvas_setup_target:
		STA	target_canvas
		STX	target_canvas_x
		STY	target_canvas_y
		RTS
		
megabasic_enable:

		;;  Copy C64 tokens to start of our token list
		;; (but don't copy end of token list)
		LDX	#(($A19C -1) - $A09E + 1)
@tokencopy:
		lda	$A09E,x
		sta	tokenlist,x
		dex
		cpx 	#$ff
		bne 	@tokencopy
		
		;; install vector
		lda #<megabasic_tokenise
		sta tokenise_vector
		lda #>megabasic_tokenise
		sta tokenise_vector+1

		;; Install new detokenise routine
		lda #<megabasic_detokenise
		sta untokenise_vector
		lda #>megabasic_detokenise
		sta untokenise_vector+1

		;; Install new execute routine
		lda #<megabasic_execute
		sta execute_vector
		lda #>megabasic_execute
		sta execute_vector+1

		;; Install hooks for IO access
		;; (This is to add hooks for the M65 buffered UARTs as
		;; well as accelerated C65 internal floppy access)
		;; $031A = open logical file
		;; $031C = close logical file
		;; $031E = open channel for input
		;; $0320 = open channel for output
		;; $0322 = close input and output channels
		;; $0324 = input character from channel
		;; $0326 = output character to channel ($FFD2)
		;; $032A = get charater from input device (similar to $0324)
		lda	#<megabasic_open_vector
		STA	$031A
		LDA	#>megabasic_open_vector
		STA	$031B
		lda	#<megabasic_close_vector
		STA	$031C
		LDA	#>megabasic_close_vector
		STA	$031D
		lda	#<megabasic_openin_vector
		STA	$031E
		LDA	#>megabasic_openin_vector
		STA	$031F
		lda	#<megabasic_openout_vector
		STA	$0320
		LDA	#>megabasic_openout_vector
		STA	$0321
		lda	#<megabasic_chrin_vector
		STA	$0324
		LDA	#>megabasic_chrin_vector
		STA	$0325
		lda	#<megabasic_chrout_vector
		STA	$0326
		LDA	#>megabasic_chrout_vector
		STA	$0327
		lda	#<megabasic_getchar_vector
		STA	$032A
		LDA	#>megabasic_getchar_vector
		STA	$032B
		

		lda 	#<welcomeText
		ldy 	#>welcomeText
		JSR	$AB1E
		
		RTS

welcomeText:	
		.byte $93,$11,"    **** MEGA65 MEGA BASIC V0.1 ****",$0D
		.byte $11," 55296 GRAPHIC 38911 PROGRAM BYTES FREE",$0D
		.byte $00
		
megabasic_disable:
		RTS

megabasic_chrout_vector:
		PHA
		LDA	$9A
		STA	$0400
		CMP	#$02
		lbne	$F1CB
		;; RS232 output
		;; First, make UART visible
		SEI
		JSR	enable_viciv
		PLA
		;; Check which UART
		inc	$042a
		LDX	$B6
		STX	$0429
		CPX	#$01	; UART1?
		BNE	@uart2
		STA	$D0E0
		CLI
		CLC
		RTS
@uart2:		STA	$D0E8
		CLI
		CLC
		RTS
		
megabasic_chrin_vector:
		LDA	$99
		STA	$0401
		CMP	#$02
		lbne	$F157
		;; RS232 input
read_from_buffereduart:
		SEI
		;; First, make UART visible
		JSR	enable_viciv
		;; Check which UART
		;; XXX - Check for empty buffer
		LDX	$AB
		CPX	#$01	; UART1?
		BNE	@uart2
		LDA	$D0E0
		CLI
		CLC
		RTS
@uart2:		LDA	$D0E8
		CLI
		CLC
		RTS

megabasic_getchar_vector:	
		LDA	$99
		STA	$0402
		CMP	#$02
		lbne	$F13E
		;; RS232 input
		;; Return fake byte corresponding to channel
		jmp	read_from_buffereduart
		
megabasic_openin_vector:
		;; Trap KERNAL set input channel vector
		;; Check if RS232, if so, do nothing, else do normal.
		;; (our buffered UARTs require no special handling)

		jsr	$f30f	; Find file
		lbne	$f701	; file not found
		jsr	$f31f	; Get file details from table
		LDA	$BA	; Get device # of the file
		STA	$0403
		CMP	#$02	; Is it RS232?
		lbne	$f219	; not RS232, so return to KERNAL routine

		;; Is RS232, so all we need to do is save input device #	
		STA	$99
		;; XXX - Do we need to put the secondary device (from $B9)
		;; anywhere?  Probably do... $AB = RS232 byte input buffer in
		;; C64, so we can override that
		LDA	$B9
		STA	$AB
		CLC
		RTS


megabasic_openout_vector:
		;; Trap KERNAL set output channel vector
		;; Check if RS232, if so, do nothing, else do normal.
		;; (our buffered UARTs require no special handling)

		jsr	$f30f	; Find file
		lbne	$f701	; file not found
		jsr	$f31f	; Get file details from table
		LDA	$BA	; Get device # of the file
		STA	$0404
		CMP	#$02	; Is it RS232?
		lbne	$f25b	; not RS232, so return to KERNAL routine

		;; Is RS232, so all we need to do is save input device #
		STA	$9A
		;; XXX - Do we need to put the secondary device (from $B9)
		;; anywhere?  Probably do. $B6 normally holds RS232 output
		;; byte buffer, so we can re-use that
		LDA	$B9
		STA	$B6
		CLC
		RTS

		
megabasic_close_vector:
		;; Our job is simply to trap CLOSE on device 2, the RS232 interface,
		;; so that the old BASIC behaviour of trashing variables etc doesn't
		;; happen

		JSR	$F314	; Look up file ID from accumulator
		lbne	$F296	; If not found, report error (jumping back to kernal close routine)
		JSR	$F31F	; Get file details from file table
		TXA
		PHA
		LDA	$BA
		STA	$0405
		CMP	#$02
		lbne	$F29D	; if not RS232, then jump back into KERNAL close routine
		;; Ok, so it was RS232.  Jump to KERNAL routine to delete the logical file entry
		PLA
		JMP	$F2F2
		
megabasic_open_vector:
		;; Check if device is RS232
		LDA	$BA
		STA	$0406
		CMP	#$02
		BNE	@notRS232
		
		;; Device is RS232
		;; C64 BASIC normally allows setting serial parameters via filename.
		;; For now, we just hardcode these to match the expected use case.
		;; At present we allow access only the 2 buffered UARTs, and not the
		;; C65 UART which would still need an RX buffer and interrupts.
		;; In contrast, the buffered UARTs are very simple to drive, allowing
		;; bytes to just be pushed and popped to/from the TX/RX queues, and with
		;; an RX buffer of 1KB for each, can be ignored for considerable periods
		;; of time in most cases.
		;; The secondary address is used to select the UART:
		;; 0 = C65 UART (currently not supported)
		;; 1 = buffered UART 0
		;; 2 = buffered UART 2 (there is no buffered UART 1)
		LDA	$B9
		STA	$0428		
		CMP	#$01
		beq	@secondaryOK
		CMP	#$02
		beq	@secondaryOK
		;; Bad secondary address
		;; Is this a sensible error?
		jmp megabasic_perform_illegal_quantity_error
@secondaryOK:
		;; Secondary ID is okay
		;; Make sure file not already open, and not too many files open		
		LDX	$B8	; try to find this file number
		JSR	$FE0F	; Find file
		lbeq	$F6FE	; FILE ALREADY OPEN error
		LDX	$98 	; get number of open files
		CPX	#$0A	; 10 files already open?
		lbcs	$f6fb	; TOO MANY FILES error

		;; All is now set for us to open the file
		INC	$98	; Increment open file count
		;; Save logical file number
		LDA	$B8
		STA	$0259, X
		;; Save device number
		LDA	$BA
		STA	$0263, X 
		;; Save secondary address
		LDA	$B9
		STA	$026D, X

		;; Finally, set the baud rate of the UARTs to the correct values
		;; Set registers to 50000000/baud
		;; 50000000/2000000=25=$19
		;; Buffered UART0 = 2000000bps
		JSR	enable_viciv
		LDA	#<$0019
		STA	$D0EE
		LDA	#>$0019
		STA	$D0EF
		;; Buffered UART2 = 115200bps
		;; 50000000/115200=434=$1B2
		LDA	#<$01B2
		STA	$D0E6
		LDA	#>$01B2
		STA	$D0E7
		
		;; return with success
		jmp	$F3D3

@notRS232:
		JMP	$F34A

		
		;; Works on modified version of the ROM tokeniser, but with extended
		;; token list.
		;; Original C64 ROM routine is from $A57C to $A612.
		;; The BASIC keyword list is at $A09E to $A19F.
		;; $A5BC is the part that reads a byte from the token list.
		;; The main complication is that the token list is already $FF bytes
		;; long, so we can't extend it an keep using an 8-bit offset.
		;; We can replace the SBC $A09E,Y with a JSR to a new routine that can
		;; handle >256 bytes of token list.  But life is not that easy, either,
		;; because Y is used in all sorts of other places in that routine.

		;; We will need two pages of tokens, so $A5AE needs to reset access to the low-page
		;; of tokens, as well as Y=0, $0B=0
		
megabasic_tokenise:

		;; Get the basic execute pointer low byte
		LDX	$7A
		;; Set the save index
		LDY	#$04
		;; Clear the quote/data flag
		STY	$0F

@tokeniseNextChar:
		;; Get hi page flag for tokenlist scanning, so that if we INC it, it will
		;; point back to the first page.  As we start with offset = $FF, the first
		;; increment will do this. Since offsets are pre-incremented, this means
		;; that it will switch to the low page at the outset, and won't switch again
		;; until a full page has been stepped through.
		PHA
		LDA 	#$FF
		STA	token_hi_page_flag
		PLA
		
		;; Read a byte from the input buffer
		LDA	$0200,X
		;; If bit 7 is clear, try to tokenise
		BPL	@tryTokenise
		;; Now check for PI (char $FF)
		CMP	#$FF 	; = PI
		BEQ	@gotToken_a5c9
		;; Not PI, but bit 7 is set, so just skip over it, and don't store
		INX
		BNE	@tokeniseNextChar
@tryTokenise:
		;; Now look for some common things
		;; Is it a space?
		CMP	#$20	; space
		BEQ	@gotToken_a5c9
		;; Not space, so save byte as search character
		STA	$08
		CMP	#$22	; quote marks
		BEQ	@foundQuotes_a5ee
		BIT	$0F	; Check quote/data mode
		BVS	@gotToken_a5c9 ; If data mode, accept as is
		CMP	#$3F	       ; Is it a "?" (short cut for PRINT)
		BNE	@notQuestionMark
		LDA	#$99	; Token for PRINT
		BNE	@gotToken_a5c9 ; Accept the print token (branch always taken, because $99 != $00)
@notQuestionMark:
		;; Check for 0-9, : or ;
		CMP 	#$30
		BCC	@notADigit
		CMP	#$3C
		BCC	@gotToken_a5c9
@notADigit:
		;; Remember where we are upto in the BASIC line of text
		STY	$71
		;; Now reset the pointer into tokenlist
		LDY	#$00
		;; And the token number minus $80 we are currently considering.
		;; We start with token #0, since we search from the beginning.
		STY	$0B
		;; Decrement Y from $00 to $FF, because the inner loop increments before processing
		;; (Y here represents the offset in the tokenlist)
		DEY
		;; Save BASIC execute pointer
		STX	$7A
		;; Decrement X also, because the inner loop pre-increments
		DEX
@compareNextChar_a5b6:
		;; Advance pointer in tokenlist
		jsr tokenListAdvancePointer
		;; Advance pointer in BASIC text
		INX
@compareProgramTextAndToken:
		;; Read byte of basic program
		LDA	$0200, X
		;; Now subtract the byte from the token list.
		;; If the character matches, we will get $00 as result.
		;; If the character matches, but was ORd with $80, then $80 will be the
		;; result.  This allows efficient detection of whether we have found the
		;; end of a keyword.
		bit 	token_hi_page_flag
		bmi	@useTokenListHighPage
		SEC
		SBC	tokenlist, Y
		jmp	@dontUseHighPage
@useTokenListHighPage:
		SEC
		SBC	tokenlist+$100,Y
@dontUseHighPage:
		;; If zero, then compare the next character
		BEQ	@compareNextChar_a5b6
		;; If $80, then it is the end of the token, and we have matched the token
		CMP	#$80
		BNE	@tokenDoesntMatch
		;; A = $80, so if we add the token number stored in $0B, we get the actual
		;; token number
		ORA	$0B
@tokeniseNextProgramCharacter:
		;; Restore the saved index into the BASIC program line
		LDY	$71
@gotToken_a5c9:
		;; We have worked out the token, so record it.
		INX
		INY
		STA	$0200 - 5, Y
		;; Now check for end of line (token == $00)
		LDA	$0200 - 5, Y
		BEQ @tokeniseEndOfLine_a609

		;; Now think about what we have to do with the token
		SEC
		SBC	#$3A
		BEQ	@tokenIsColon_a5dc
		CMP	#($83 - $3A) ; (=$49) Was it the token for DATA?
		BNE	@tokenMightBeREM_a5de
@tokenIsColon_a5dc:
		;; Token was DATA
		STA	$0F	; Store token - $3A (why?)
@tokenMightBeREM_a5de:
		SEC
		SBC	#($8F - $3A) ; (=$55) Was it the token for REM?
		BNE	@tokeniseNextChar
		;; Was REM, so say we are searching for end of line (== $00)
		;; (which is conveniently in A now) 
		STA	$08	
@label_a5e5:
		;; Read the next BASIC program byte
		LDA	$0200, X
		BEQ	@gotToken_a5c9
		;; Does the next character match what we are searching for?
		CMP	$08
		;; Yes, it matches, so indicate we have the token
		BEQ	@gotToken_a5c9

@foundQuotes_a5ee:
		;; Not a match yet, so advance index for tokenised output
		INY
		;; And write token to output
		STA	$0200 - 5, Y
		;; Increment read index of basic program
		INX
		;; Read the next BASIC byte (X should never be zero)
		BNE	@label_a5e5

@tokenDoesntMatch:
		;; Restore BASIC execute pointer to start of the token we are looking at,
		;; so that we can see if the next token matches
		LDX	$7A
		;; Increase the token ID number, since the last one didn't match
		INC	$0B
		;; Advance pointer in tokenlist from the end of the last token to the start
		;; of the next token, ready to compare the BASIC program text with this token.
@advanceToNextTokenLoop:
		jsr 	tokenListAdvancePointer
		jsr 	tokenListReadByteMinus1
		BPL	@advanceToNextTokenLoop
		;; Check if we have reached the end of the token list
		jsr	tokenListReadByte
		;; If not, see if the program text matches this token
		BNE	@compareProgramTextAndToken

		;; We reached the end of the token list without a match,
		;; so copy this character to the output, and 
		LDA	$0200, X
		;; Then advance to the next character of the BASIC text
		;; (BPL acts as unconditional branch, because only bytes with bit 7
		;; cleared can get here).
		BPL	@tokeniseNextProgramCharacter
@tokeniseEndOfLine_a609:
		;; Write end of line marker (== $00), which is conveniently in A already
		STA	$0200 - 3, Y
		;; Decrement BASIC execute pointer high byte
		DEC	$7B
		;; ... and set low byte to $FF
		LDA	#$FF
		STA	$7A
		RTS

tokenListAdvancePointer:	
		INY
		BNE	@dontAdvanceTokenListPage
		PHP
		PHA
		LDA	token_hi_page_flag
		EOR	#$FF
		STA	token_hi_page_flag
		;; XXX Why on earth do we need these three NOPs here to correctly parse the extra
		;; tokens? If you remove one, then the first token no longer parses, and the later
		;; ones get parsed with token number one less than it should be!
		NOP
		NOP
		NOP
		PLA
		PLP
@dontAdvanceTokenListPage:
		PHP
		PHX
		PHA
		tya
		tax
		bit	token_hi_page_flag
		bmi	@page2
		jmp	@done
@page2:		
		@done:
		
		PLA
		PLX
		PLP
		RTS

tokenListReadByte:	
		bit 	token_hi_page_flag
		bmi	@useTokenListHighPage
		LDA	tokenlist, Y
		RTS
@useTokenListHighPage:
		LDA	tokenlist+$100,Y
		RTS		

tokenListReadByteMinus1:	
		bit 	token_hi_page_flag
		bmi	@useTokenListHighPage
		LDA	tokenlist - 1, Y
		RTS
@useTokenListHighPage:
		LDA	tokenlist - 1 + $100,Y
		RTS		
		
megabasic_detokenise:
		;; The C64 detokenise routine lives at $A71A-$A741.
		;; The routine is quite simple, reading through the token list,
		;; decrementing the token number each time the end of at token is
		;; found.  The only complications for us, is that we need to change
		;; the parts where the token bytes are read from the list to allow
		;; the list to be two pages long.

		;; Print non-tokens directly
		bpl 	jump_to_a6f3
		;; Print PI directly
		cmp	#$ff
		beq	jump_to_a6f3
		;; If in quote mode, print directly
		bit	$0f
		bmi 	jump_to_a6f3

		;; At this point, we know it to be a token

		;; Tokens are $80-$FE, so subtract #$7F, to renormalise them
		;; to the range $01-$7F
		SEC
		SBC	#$7F
		;; Put the normalised token number into the X register, so that
		;; we can easily count down
		TAX
		STY	$49 	; and store it somewhere necessary, apparently

		;; Now get ready to find the string and output it.
		;; Y is used as the offset in the token list, and gets pre-incremented
		;; so we start with it equal to $00 - $01 = $FF
		LDY	#$FF
		;; Set token_hi_page_flag to $FF, so that when Y increments for the first
		;; time, it increments token_hi_page_flag, making it $00 for the first page of
		;; the token list.
		STY	token_hi_page_flag

		
@detokeniseSearchLoop:
		;; Decrement token index by 1
		DEX
		;; If X = 0, this is the token, so read the bytes out
		beq	@thisIsTheToken
		;; Since it is not this token, we need to skip over it
@detokeniseSkipLoop:
		jsr tokenListAdvancePointer
		jsr tokenListReadByte
		BPL	@detokeniseSkipLoop
		;; Found end of token, loop to see if the next token is it
		BMI	@detokeniseSearchLoop
@thisIsTheToken:
		jsr tokenListAdvancePointer
		jsr tokenListReadByte
		;; If it is the last byte of the token, return control to the LIST
		;; command routine from the BASIC ROM
		BMI	jump_list_command_finish_printing_token_a6ef
		;; As it is not the end of the token, print it out
		JSR	$AB47
		BNE	@thisIsTheToken

		;; This can only be reached if the next byte in the token list is $00
		;; This could only happen in C64 BASIC if the token ID following the
		;; last is attempted to be detokenised.
		;; This is the source of the REM SHIFT+L bug, as SHIFT+L gives the
		;; character code $CC, which is exactly the token ID required, and
		;; the C64 BASIC ROM code here simply fell through the FOR routine.
		;; Actually, understanding this, makes it possible to write a program
		;; that when LISTed, actually causes code to be executed!
		;; However, this vulnerability appears not possible to be exploited,
		;; because $0201, the next byte to be read from the input buffer during
		;; the process, always has $00 in it when the FOR routine is run,
		;; causing a failure when attempting to execute the FOR command.
		;; Were this not the case, REM (SHIFT+L)I=1TO10:GOTO100, when listed
		;; would actually cause GOTO100 to be run, thus allowing LIST to
		;; actually run code. While still not a very strong form of source
		;; protection, it could have been a rather fun thing to try.

		;; Instead of having this error, we will just cause the character to
		;; be printed normally.
		LDY	$49
jump_to_a6f3:	
		JMP 	$A6F3
jump_list_command_finish_printing_token_a6ef:
		JMP	$A6EF

megabasic_execute:		
		JSR	$0073
		;; Is it a MEGA BASIC primary keyword?
		CMP	#$CC
		BCC	@basic2_token
		CMP	#token_first_sub_command
		BCC	megabasic_execute_token
		;; Handle PI
		CMP	#$FF
		BEQ	@basic2_token
		;; Else, it must be a MEGA BASIC secondary keyword
		;; You can't use those alone, so ILLEGAL DIRECT ERROR
		jmp megabasic_perform_illegal_direct_error
@basic2_token:
		;; $A7E7 expects Z flag set if ==$00, so update it
		CMP	#$00
		JMP	$A7E7

megabasic_execute_token:
		;; Normalise index of new token
		SEC
		SBC 	#$CC
		ASL
		;; Clip it to make sure we don't have any overflow of the jump table
		AND	#$0E
		TAX
		PHX
		;; Get next token/character ready
		JSR	$0073
		PLX
		JMP 	(newtoken_jumptable,X)

		;; Tokens are $CC-$FE, so to be safe, we need to have a jump
newtoken_jumptable:
		.word 	megabasic_perform_fast
		.word 	megabasic_perform_slow
		.word	megabasic_perform_canvas ; canvas operations, including copy/stamping, clearing, creating new
		.word	megabasic_perform_colour ; set colours
		.word	megabasic_perform_tile ; "TILE" command, used for TILESET and other purposes
		.word	megabasic_perform_syntax_error ; "SET" SYNTAXERROR: Used only with TILE to make TILESET
		.word 	megabasic_perform_syntax_error
		.word 	megabasic_perform_syntax_error
		.word 	megabasic_perform_syntax_error

		basic2_main_loop 	=	$A7AE

tokenlist:
		;; Reserve space for C64 BASIC token list, less the end $00 marker
		.res ($A19C - $A09E + 1), $00
		;; End of list marker (remove to enable new tokens)
				;.byte $00
		;; Now we have our new tokens
		;; extra_token_count must be correctly set to the number of tokens
		;; (This lists only the number of tokens that are good for direct use.
		;; Keywords found only within statements are not in this tally.)
		extra_token_count = 5
		token_fast = $CC + 0
		.byte "FAS",'T'+$80
		token_slow = $CC + 1
		.byte "SLO",'W'+$80

		token_canvas = $CC + 2
		.byte "CANVA",'S'+$80
		token_colour = $CC + 3
		.byte "COLOU",'R'+$80
		token_tile = $CC + 4
		.byte "TIL",'E'+$80

		token_first_sub_command = token_tile + 1
		
		;; These tokens are keywords used within other
		;; commands, not as executable commands. These
		;; will all generate syntax errors.
		token_text = token_first_sub_command + 0
		.byte "TEX",'T'+$80
		token_sprite = token_first_sub_command + 1
		.byte "SPRIT",'E'+$80
		token_screen = token_first_sub_command + 2
		.byte "SCREE",'N'+$80 
		token_border = token_first_sub_command + 3
		.byte "BORDE",'R'+$80
		token_set = token_first_sub_command + 4
		.byte "SE",'T'+$80
		token_delete = token_first_sub_command + 5
		.byte "DELET",'E'+$80
		token_stamp = token_first_sub_command + 6
		.byte "STAM",'P'+$80
		token_at = token_first_sub_command + 7
		.byte "A",'T'+$80
		token_from = token_first_sub_command + 8
		.byte "FRO",'M'+$80
		;; And the end byte
		.byte $00		

		;; Quick reference to C64 BASIC tokens
		token_clr	=	$9C
		token_cont	=	$9A
		token_new	=	$A2
		token_on	=	$91
		token_stop	=	$90
		token_to	=	$A4

megabasic_perform_tile:
		;; Valid syntax options:
		;; TILE SET LOAD <"filename"> [,device]
		CMP	#token_set
		lbne	megabasic_perform_syntax_error
		JSR	$0073
		CMP	#$93 	; Token for "LOAD" keyword
		lbne	megabasic_perform_syntax_error 
		JSR	$0073
		;; Convienently the LOAD command has a routine we
		;; can call that gets the filename and device + ,1
		;; options.
		LDA	#$00 	; Set LOAD/VERIFY flag for LOAD
		STA	$0A
		JSR	$E1D4

		;; XXX - Not yet implemented
		
		jmp	basic2_main_loop

megabasic_perform_fast:
		jsr	enable_viciv
		LDA	#$40
		TSB	$D054
		TSB	d054_bits
		JMP	basic2_main_loop		
		
megabasic_perform_slow:
		jsr	enable_viciv
		LDA	#$40
		TRB	$D054
		TRB	d054_bits
		JMP	basic2_main_loop		

megabasic_perform_canvas_new:
		;; CANVAS n NEW x,y
		;; At this point NEW is the current token

		;;  Save ZP variables
		jsr	zp_scratch_stash

		;; Check if canvas id already exists
		lda	source_canvas
		;; CANVAS 0 is special, and always exists at a fixed address
		LBEQ	megabasic_perform_illegal_quantity_error
		jsr	canvas_find
		LBCS	megabasic_perform_file_open_error
		
		;; Skip NEW
		JSR	$0073

		;; Parse x,y into source_canvas_x1,y1
		jsr	parse_xy

		;; Calculate required memory
		;; = (2*x) * y * 2 = 4 * x * y
		lda	source_canvas_x1
		asl
		sta	$d770
		LDA 	source_canvas_y1
		asl
		sta	$d774
		LDA 	#$00
		STA	$d771
		sta	$D772
		sta	$D773
		sta	$D775
		sta	$d776
		sta	$D777
		lda	source_canvas_x1
		bpl	@noXbit7
		inc	$d771
@noXbit7:	lda	source_canvas_y1
		bpl	@noYbit7
		inc	$D775
@noYbit7:
		;; Find end of canvas list
		jsr	tileset_point_to_start_of_area
@canvasListTraverse:
		jsr	tileset_follow_pointer
		LDZ	#$00
		NOP
		NOP
		LDA	($03),Z
		BNE	@canvasListTraverse

		;; Pointer $03-$07 now points to start of free
		;; graphics memory.  We can use upto $1F7FF.
		
		
		;; Check available memory.
		;; We need 64 bytes for header, plus the computed
		;; bytes for the rows.
		LDA	$03
		CLC
		ADC	$D778
		STA	$08
		LDA	$04
		ADC	$D779
		STA	$09
		LDA	$05
		ADC	$D77A
		STA	$0A
		;; Add $40 for the header
		LDA	$08
		CLC
		ADC	#$40
		STA	$08
		LDA	$09
		ADC	#$00
		STA	$09
		LDA	$0A
		ADC	#$00
		STA	$0A
		;; now check that result is <= $1F7FF
		CMP	#$01
		LBNE	megabasic_perform_out_of_memory_error
		LDA	$09
		CMP	#>$F800
		LBCS	megabasic_perform_out_of_memory_error
		
		;; Memory space is okay.		

		;; Create header
		LDX	#$00
		LDZ	#$00
@installMagicLoop:
		LDA	canvas_magicstring,x
		NOP
		NOP
		STA	($03),Z
		INX
		INZ
		CPX	#$0F
		BNE	@installMagicLoop
		;; Store canvas number at offset 15
		LDA	source_canvas
		NOP
		NOP
		STA	($03),Z

		LDA	source_canvas_x1
		LDZ	#16
		NOP
		NOP
		STA	($03),Z
		LDA	source_canvas_y1
		LDZ	#17
		NOP
		NOP
		STA	($03),Z

		;; Set offset to screen RAM rows (always $40) in 18-20
		LDZ	#18
		LDA	#$40
		NOP
		NOP
		STA	($03), Z
		INZ
		LDA	#$00
		NOP
		NOP
		STA	($03), Z
		INZ
		LDA	#$00
		NOP
		NOP
		STA	($03), Z
		;; Set offset to colour RAM rows in 21-24
		LDZ	#21
		LDA	$D778
		CLC
		ADC	#$40
		NOP
		NOP
		STA	($03),Z
		INZ
		LDA	$D779
		ADC	#$00
		NOP
		NOP
		STA	($03),Z
		INZ
		LDA	$D77A
		ADC	#$00
		NOP
		NOP
		STA	($03),Z

		;; Set length of screenram/colour ram row slab in 25-26
		LDZ	#24
		LDA	$D778
		NOP
		NOP
		STA	($03),Z
		INZ
		LDA	$D779
		NOP
		NOP
		STA	($03),Z
		
		
		;; Set length field
		;; (Use multiplier output + $40 for header)
		LDZ	#61
		LDA	$D778
		CLC
		ADC	#$40
		NOP
		NOP
		STA	($03), Z
		INZ
		LDA	$D779
		ADC	#$00
		NOP
		NOP
		STA	($03), Z
		INZ
		LDA	$D77A
		ADC	#$00
		NOP
		NOP
		STA	($03), Z		
		LDZ	#$00
		
		;; Initialise canvas by clearing it
		lda	source_canvas
		jsr	canvas_prepare_pointers
		jsr	canvas_clear_region

		jsr	zp_scratch_restore
		jmp	basic2_main_loop
		
megabasic_perform_canvas_delete:
		JSR	$0073
		jsr	zp_scratch_stash

		lda	source_canvas
		;; CANVAS 0 is special, and can't be deleted
		LBEQ	megabasic_perform_illegal_quantity_error
		jsr	canvas_find
		bcs	@canvasExists
		;; If canvas exists, silently do nothing
		;; (that way it is always save to DELETE a canvas
		;; if you are not sure it exists, e.g., before
		;; calling CANVAS n NEW
		jsr	zp_scratch_restore
		jmp	basic2_main_loop
@canvasExists:		

		;; Pointer at $03 points to the canvas's header
		;; We need to work out the region to copy down.
		;; The target will be the start of the canvas.
		;; The source will be the start of the following
		;; canvas

		LDA	$03
		STA	canvas_delete_dmalist_dest_lsb
		LDA	$04
		STA	canvas_delete_dmalist_dest_msb

		;; Get source by following to the next pointer
		jsr	tileset_follow_pointer

		LDA	$03
		STA	canvas_delete_dmalist_source_lsb
		LDA	$04
		STA	canvas_delete_dmalist_source_msb

		;; Work out size
		LDA	canvas_delete_dmalist_source_msb
		SEC
		SBC	canvas_delete_dmalist_dest_msb
		sta	canvas_delete_dmalist_size_msb
		LDA	canvas_delete_dmalist_source_lsb
		SBC	canvas_delete_dmalist_dest_lsb
		sta	canvas_delete_dmalist_size_lsb
		
		;; Call DMA job to actually shuffle 
		LDA 	#>canvas_delete_dmalist
		STA	$D701
		LDA	#<canvas_delete_dmalist
		STA	$D705

		;; Then write an empty header at the end of the chain
		LDA	canvas_delete_dmalist_dest_lsb
		CLC
		ADC	canvas_delete_dmalist_size_lsb
		STA	$03
		LDA	canvas_delete_dmalist_dest_msb
		ADC	canvas_delete_dmalist_size_msb
		STA	$04
		LDZ	#$63
		LDA	#$00
@eraseHeaderLoop:
		NOP
		NOP
		STA	($03), Z
		DEZ
		bpl	@eraseHeaderLoop

		
		jsr	zp_scratch_restore
		jmp	basic2_main_loop
		
canvas_delete_dmalist:	
		;; Install pre-prepared tileset @ $12000+
		.byte $0A,$00 	; F011A list follows
		;; Normal F011A list
		.byte $00 ; copy + end of chain
canvas_delete_dmalist_size_lsb:	.byte 0
canvas_delete_dmalist_size_msb:	.byte 0
canvas_delete_dmalist_source_lsb:	.byte 0
canvas_delete_dmalist_source_msb:	.byte 0
		.byte $01   ; always bank 1 for now
canvas_delete_dmalist_dest_lsb:	.byte 0
canvas_delete_dmalist_dest_msb:	.byte 0
		.byte $01   ; always bank 1 for now
		.word $0000 ; modulo (unused)		
		
		
megabasic_perform_colour:
		;; What are we being asked to colour?
		SEC
		SBC	#token_text
		LBMI	megabasic_perform_undefined_function
		CMP	#token_stamp-token_text
		LBCS	megabasic_perform_undefined_function
		;; Okey, we have a valid colour target
		STA	colour_target
		;; Advance to next token
		JSR	$0073
		
		;; All options then require a colour number,
		;; how it is interpretted depends on the target

		;; Evaluate expression
		JSR	$AD8A
		;; Convert FAC to integer in $14-$15
		JSR	$B7F7

		;; Handle the simple cases
		LDA	colour_target
		LDX	#$20
		CMP	#(token_border-token_text)
		BEQ	set_vic_register
		LDX	#$21
		CMP	#(token_screen-token_text)
		BEQ	set_vic_register
		CMP	#(token_text-token_text)
		BNE	@mustBeSpriteColour
@settingTextColour:
		;; Here we are setting the text colour
		;; (this is just a convenience from using CHR$
		;; codes to set the text colour)
		LDA	$14
		STA	$286
		JMP	basic2_main_loop
@mustBeSpriteColour:
		;; Syntax is:
		;; COLOUR SPRITE <n> COLOUR <m> = <r>,<g>,<b>
		;; Where, n is the sprite #, m is the colour ID (0-15), and R,G and B are the RGB values

		;; For now just say undefined function
		JMP	megabasic_perform_undefined_function
		
set_vic_register:	
		JSR	enable_viciv
		LDA	$14
		STA	$D000,X
		;; Re-force video mode in case it was a hot register
		JSR	update_viciv_registers

		JMP	basic2_main_loop

megabasic_perform_load_error:
		LDX	#$1D
		JMP	$A437
		
megabasic_perform_syntax_error:
		LDX	#$0B
		JMP	$A437

megabasic_perform_illegal_direct_error:
		LDX	#$15
		JMP	$A437

megabasic_perform_illegal_quantity_error:
		LDX	#$0E
		JMP	$A437

megabasic_perform_file_open_error:
		LDX	#$02
		JMP	$A437

megabasic_perform_out_of_memory_error:
		LDX	#$10
		JMP	$A437
		
megabasic_perform_canvas:

		;; All CANVAS statement variants require a canvas number
		jsr	$0079
		
		;; Evaluate expression
		JSR	$AD8A
		;; Convert FAC to integer in $14-$15
		JSR	$B7F7
		LDA	$15
		BEQ	@canvasIDNotInvalid
		jmp	megabasic_perform_illegal_quantity_error
@canvasIDNotInvalid:
		LDA	$14
		sta	source_canvas

		;; Get current token 
		JSR	$0079
		;; CANVAS0STOP stops rendering of canvas 0 to screen
		cmp	#token_stop
		BNE	@notCanvasStop
		LDA	source_canvas
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	#$01
		STA	canvas_pause_drawing
		JSR	$0073
		jmp	basic2_main_loop
@notCanvasStop:
		;; CANVAS0CONT resumes rendering of canvas 0 to screen
		cmp	#token_cont
		BNE	@notCanvasRun
		LDA	source_canvas
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	#$00
		STA	canvas_pause_drawing
		JSR	$0073
		jmp	basic2_main_loop
@notCanvasRun:
		CMP	#token_stamp
		LBEQ	megabasic_perform_canvas_stamp
		CMP	#token_delete
		LBEQ	megabasic_perform_canvas_delete
		CMP	#token_clr
		LBEQ	megabasic_perform_canvas_clear
		CMP	#token_new
		LBEQ	megabasic_perform_canvas_new
		CMP	#token_set
		LBEQ	megabasic_perform_canvas_settile
		;; Else, its bad
		JMP	megabasic_perform_undefined_function

megabasic_perform_canvas_clear:

		jsr	zp_scratch_stash
				
		;; CANVAS s CLEAR [from x1,y1 TO x2,y2]
		LDA	source_canvas
		JSR	get_canvas_dimensions

		;; Then work out which part of the canvas will be
		;; cleared
		JSR	$0073
		jsr	parse_from_xy_to_xy

		;; Get pointers to start of screen and colour RAM areas for the canvas
		lda	source_canvas
		jsr	canvas_prepare_pointers
		;; Adjust them for the region we need to clear
		jsr	canvas_adjust_source_pointers_for_from_xy_to_xy

		;; Do actual clearing
		jsr	canvas_clear_region
		
		;; All done, restore saved ZP
		jSR	zp_scratch_restore		
		jmp 	basic2_main_loop

canvas_clear_region:	

		;; If nothing to do, skip the hard work
		LDA	source_canvas_x2
		BEQ	@copiedLastLine
		
@stampLineLoop:
		;; $07 = source width (not reduced by X offset)
		;; $08 = source height (not reduced by Y offset)
		;; $09 = target width (reduced by X offset)
		;; $0A = target height (reduced by Y offset)
		;; source_canvas_x2 = number of tiles per row to copy
		;; source_canvas_y2 = number of rows to copy
		;; uint16_t $20 = row advance for source
		;; uint16_t $22 = row advance for target
		;; uint32_t $10 = source screen RAM rows
		;; uint32_t $14 = source colour RAM rows
		;; uint32_t $18 = target screen RAM rows
		;; uint32_t $1C = target colour RAM rows

		;; Have we done all the lines?
		LDA	source_canvas_y2
		BEQ	@copiedLastLine

		;; Another line to copy

		;; Point to beginning of line (corrected for X offsets)
		LDZ	#$00
		;; Get the # of tiles in the row that we have to copy
		LDX	source_canvas_x2

@stampTileLoop:
		;; Clear the tile:
		;; screen ram = $20 $00 (show a SPACE character)
		;; colour bytes = $00 $00
		LDA	#$20 
		NOP
		NOP
		STA	($10), Z
		LDA	#$00		
		NOP
		NOP
		STA	($14), Z
		INZ
		NOP
		NOP
		STA	($10), Z
		LDA	#$00		
		NOP
		NOP
		STA	($14), Z

		INZ
		DEX
		BNE	@stampTileLoop

		jsr	canvas_pointer_advance_to_next_line

		;; See if more to do
		jmp	@stampLineLoop
		
@copiedLastLine:
		LDZ	#$00

		RTS
		
megabasic_perform_canvas_stamp:
		;; CANVAS s STAMP [from x1,y1 TO x2,y2] ON CANVAS t [AT x3,y3]
		;; Minimal example:
		;; CANVAS 1 STAMP ON CANVAS 0
		;; (with default tileset, should display MEGA65 banner at top of screen)

		;; Get the token after "STAMP"
				
		;; At this point we have only CANVAS STAMP, and
		;; the source canvas in source_canvas

		jsr	zp_scratch_stash
		
		;; Get the size of the canvas
		LDA	source_canvas
		JSR	get_canvas_dimensions

		;; Then work out which part of the canvas will be
		;; copied.
		JSR	$0073
		jsr	parse_from_xy_to_xy
		;; Get next token ready (should be TO)
		JSR	$0079

		;; check that next tokens are ON CANVAS (or just CANVAS to save space and typing)
		JSR	$0079
		CMP	#token_canvas
		BEQ	@skipOn
		CMP	#token_on
		LBNE	megabasic_perform_syntax_error
		jsr 	$0073
		CMP	#token_canvas
		LBNE	megabasic_perform_syntax_error
@skipOn:
		;; Next should be the destination canvas
		JSR	$0073
		JSR	$AD8A
		JSR	$B7F7
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		STA	target_canvas
		jsr	canvas_find
		BCS	@foundCanvas2
		jmp	megabasic_perform_illegal_quantity_error
@foundCanvas2:		
		;; Finally, look for optional AT X,Y
		jsr 	parse_at_xy

		;; We now have all that we need to do a token stamping
		;; 1. We know the source and target canvases exist
		;; 2. We know the source region to copy from
		;; 3. We know the target location to draw into

		;; Now we need to get pointers to the various structures,
		;; and iterate through the copy.
		jsr	megabasic_stamp_canvas

		;; All done, restore saved ZP
		JSR	zp_scratch_restore
		JMP	basic2_main_loop

get_canvas_dimensions:
		jsr	canvas_find
		BCS	@foundCanvas
		jmp	megabasic_perform_illegal_quantity_error
@foundCanvas:
		;; $03-$06 pointer now points to canvas header
		;; (unless special case of canvas 0)
		;; Get dimensions of canvas
		LDA	#0
		sta	source_canvas_x1
		sta	source_canvas_y1
		LDA	source_canvas
		BNE	@notCanvas0
		;; Is canvas 0, so dimensions are fixed: 80x50
		lda	#80
		sta	source_canvas_x2
		lda	#50
		sta	source_canvas_y2
		jmp	@gotCanvasSize
@notCanvas0:
		;; Read canvas size from canvas header block
		LDZ	#16
		NOP
		NOP
		LDA	($03),Z
		STA	source_canvas_x2
		INZ
		NOP
		NOP
		LDA	($03),Z
		STA	source_canvas_y2
		LDZ	#$00
@gotCanvasSize:
		RTS
		
parse_from_xy_to_xy:	
		;; Get token following STAMP
		JSR	$0079
		cmp	#token_from
		lbne	@stampAll
		;; We are being given a region to copy
		JSR	$0073
		;; get X1
		JSR	$AD8A
		JSR	$B7F7
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		cmp	source_canvas_x2
		lbcs	megabasic_perform_illegal_quantity_error
		STA	source_canvas_x1
		;; get comma between X1 and Y1
		jsr 	$0079
		CMP	#$2C
		LBNE	megabasic_perform_syntax_error
		jsr	$0073
		;; get Y1
		JSR	$AD8A
		JSR	$B7F7		
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		cmp	source_canvas_y2
		lbcs	megabasic_perform_illegal_quantity_error
		STA	source_canvas_y1
		;; Check for TO keyword between coordinate pairs
		JSR	$0079
		CMP	#token_to
		LBNE	megabasic_perform_syntax_error
		JSR	$0073
		;; get X2
		JSR	$AD8A
		JSR	$B7F7
		INW	$14
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		cmp	source_canvas_x2
		lbcs	megabasic_perform_illegal_quantity_error
		STA	source_canvas_x2
		;; get comma between X2 and Y2
		jsr 	$0079
		CMP	#$2C
		LBNE	megabasic_perform_syntax_error
		jsr	$0073
		;; get Y2
		JSR	$AD8A
		JSR	$B7F7
		INW	$14
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		cmp	source_canvas_y2
		lbcs	megabasic_perform_illegal_quantity_error
		STA	source_canvas_y2
		RTS
@stampAll:
		RTS

parse_xy:
		;; get X
		JSR	$AD8A
		JSR	$B7FB
		LDA	$15
		CMP	#$00
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		STA	source_canvas_x1
		;; get comma between X1 and Y1
		jsr 	$0079
		CMP	#$2C
		LBNE	megabasic_perform_syntax_error
		jsr	$0073
		;; get Y
		JSR	$AD8A
		JSR	$B7FB
		LDA	$15
		CMP	#$00
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		STA	source_canvas_y1
		RTS		
		
parse_at_xy:	
		LDA	#$00
		STA	target_canvas_x
		STA	target_canvas_y
		jsr	$0079
		CMP	#token_at
		BNE	@noAt
		;; Parse AT X,y
		JSR	$0073
		;; get X
		JSR	$AD8A
		JSR	$B7FB
@checkNegativeX:
		LDA	$15
		CMP	#$FF
		BNE	@notNegX
		;; X is negative, so we can increment X to normalise it, and
		;; at the same time increment X1 of the source. It is only
		;; illegal quantity if after doing this that there is no region to copy
		LDA	source_canvas_x1
		CMP	source_canvas_x2
		LBEQ	megabasic_perform_illegal_quantity_error
		INC	source_canvas_x1
		INW	$14
		jmp	@checkNegativeX
@notNegX:
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		STA	target_canvas_x
		;; get comma between X1 and Y1
		jsr 	$0079
		CMP	#$2C
		LBNE	megabasic_perform_syntax_error
		jsr	$0073
		;; get Y
		JSR	$AD8A
		JSR	$B7FB
@checkNegativeY:
		LDA	$15
		CMP	#$FF
		BNE	@notNegY
		;; Y is negative, so we can increment Y to normalise it, and
		;; at the same time increment Y1 of the source. It is only
		;; illegal quantity if after doing this that there is no region to copy
		LDA	source_canvas_y1
		CMP	source_canvas_y2
		LBEQ	megabasic_perform_illegal_quantity_error
		INC	source_canvas_y1
		INW	$14
		jmp	@checkNegativeY
@notNegY:
		LDA	$15
		LBNE	megabasic_perform_illegal_quantity_error
		LDA	$14
		STA	target_canvas_y
@noAt:
		RTS
		
megabasic_stamp_canvas:

		;; CANVAS stamping (copying)
		;; We copy from source_canvas to target_canvas.
		;; Copy is of source_canvas_{x1,y1} to _{x2,y2}, inclusive,
		;; and target is at target_canvas_{x,y}.
		;; The source canvas coordinates are assumed to be valid.
		;; Target canvas dimensions will be deduced and applied
		;; For the copy, we want to do each line in turn.
		;; We need pointers to the four locations, all of
		;; which need to be 32-bit pointers, so that we
		;; can access outside the first 64KB.

		;; Get pointers to, and size of everything
		
		;; Get target pointers
		;; (canvas_prepare_pointers writes to source_canvas pointers,
		;; so after the call we copy those pointers ($00-$17) to the
		;; target pointers ($18-$1F)
		lda	target_canvas
		jsr	canvas_prepare_pointers
		;; Then copy to $18-$1F
		LDX	#$10
		LDY	#$18
		jsr	copy_32bit_pointer
		LDX	#$14
		LDY	#$1C
		jsr	copy_32bit_pointer
		;; (and canvas dimensions)
		LDX	#$07
		LDY	#$09
		jsr	copy_32bit_pointer

		;; Then get source canvas, and do the same
		lda	source_canvas
		jsr	canvas_prepare_pointers

		jsr	canvas_adjust_source_pointers_for_from_xy_to_xy
		jsr	canvas_adjust_target_pointers_for_at_xy

		;; Clip copy to fit destination canvas
		LDA	source_canvas_x2
		CMP	$09
		BCC	@notTooWide
		LDA	$09
		STA	source_canvas_x2
@notTooWide:
		LDA	source_canvas_y2
		CMP	$0A
		BCC	@notTooHigh
		LDA	$0A
		STA	source_canvas_y2
@notTooHigh:

		;; If nothing to do, skip the hard work
		LDA	source_canvas_x2
		BEQ	@copiedLastLine
		
@stampLineLoop:
		;; $07 = source width (not reduced by X offset)
		;; $08 = source height (not reduced by Y offset)
		;; $09 = target width (reduced by X offset)
		;; $0A = target height (reduced by Y offset)
		;; source_canvas_x2 = number of tiles per row to copy
		;; source_canvas_y2 = number of rows to copy
		;; uint16_t $20 = row advance for source
		;; uint16_t $22 = row advance for target
		;; uint32_t $10 = source screen RAM rows
		;; uint32_t $14 = source colour RAM rows
		;; uint32_t $18 = target screen RAM rows
		;; uint32_t $1C = target colour RAM rows

		;; Have we done all the lines?
		LDA	source_canvas_y2
		BEQ	@copiedLastLine

		;; Another line to copy

		;; Point to beginning of line (corrected for X offsets)
		LDZ	#$00
		;; Get the # of tiles in the row that we have to copy
		LDX	source_canvas_x2

@stampTileLoop:
		;; Check if the tile needs stamping ($FFFF = transparent)
		NOP
		NOP
		LDA	($10), Z
		INZ
		NOP
		NOP
		AND	($10), Z
		DEZ
		CMP	#$FF
		beq	@dontCopyThisTile
		;; Copy the tile
		LDY #$01
@copyByteLoop:
		NOP
		NOP
		LDA	($10), Z
		NOP
		NOP
		STA	($18), Z
		NOP
		NOP
		LDA	($14), Z
		NOP
		NOP
 		STA	($1C), Z 
		INZ
		DEY
		BPL	@copyByteLoop
		DEZ
		DEZ

@dontCopyThisTile:
		INZ
		INZ
@copiedTile:
		DEX
		BNE	@stampTileLoop

		jsr	canvas_pointer_advance_to_next_line

		;; See if more to do
		jmp	@stampLineLoop
		
@copiedLastLine:
		LDZ	#$00
		RTS

canvas_pointer_advance_to_next_line:	
		;; Decrement count of lines left to copy
		dec	source_canvas_y2
		;; Advance pointers to next lines
		LDX	#$10
		LDY	#$20
		jsr	add_16bit_value
		LDX	#$14
		LDY	#$20
		jsr	add_16bit_value
		LDX	#$18
		LDY	#$22
		jsr	add_16bit_value
		LDX	#$1c
		LDY	#$22
		jsr	add_16bit_value
		
		RTS
		
canvas_prepare_pointers:
		;; Get pointers to screen and colour RAM for
		;; source and target canvases into $10-$17,
		;; and width and height into $07,$08
		
		;; Put target screen ram in $10-$13
		;; skip header, and save pointer

		PHA
		jsr	canvas_find
		PLA
		BNE	@targetNotCanvas0
		;; Canvas 0 has set addresses
		LDX	#$10
		jsr	get_canvas0_pointers
		lda	#80
		sta	$07
		LDA	#50
		sta	$08
		jmp 	@gotTargetPointers
@targetNotCanvas0:
		;;  Canvas dimensions 
		lda	canvas_width
		sta	$07		
		lda	canvas_height
		sta 	$08
		
		;; screen RAM rows are at header+64
		JSR	tileset_advance_by_64
		LDX	#$03
		LDY	#$10
		jsr	copy_32bit_pointer
		jsr	tileset_retreat_by_64

		;; colour RAM rows are at header + *(unsigned short*)&header[21]
		LDX	#$03
		LDY	#$14
		jsr	copy_32bit_pointer

		LDZ	#21
		LDA	$14
		CLC
		NOP
		NOP
		ADC	($03),Z
		STA	$14
		INZ
		LDA	$15
		CLC
		NOP
		NOP
		ADC	($03),Z
		STA	$15
		INZ
		LDA	$16
		CLC
		NOP
		NOP
		ADC	($03),Z
		STA	$16
@gotTargetPointers:
		LDZ	#$00
		RTS		

canvas_adjust_source_pointers_for_from_xy_to_xy:	
		;; The pointers are currently to the start of the
		;; regions.  We need to advance them to the first
		;; line in the source and targets, and then advance
		;; them by the X offset in each.
		;; After that, we can subtract the start offsets,
		;; and process as though copy is from 0,0 to 0,0,
		;; with normalised width and height.
		;; The fast way is to multiply the row number by the
		;; row length. We can use the hardware multiplier for
		;; this.
		jsr 	enable_viciv ; make multiplier registers visible

		; source width*2 = row bytes		
		LDA	$07	
		ASL
		STA	$D770
		STA	$20	; low byte of row advance for source
		ROL
		AND	#$01
		STA	$21	; high byte of row advance for source
		STA	$D771
		;; start row
		LDA	source_canvas_y1
		STA	$D774
		;; Zero out unused upper byteese
		LDA	#$00
		STA 	$D772
		STA	$D773
		STA	$D776
		STA	$D777
		;; XXX - Wait for multiplier to finish
		;; Get multplier result and add X offset
		LDX 	#$00
@ll2:		LDA	$D778, X
		STA	$0B, X
		INX
		CPX	#4
		BNE	@ll2
		;; Now add 2*(X position of start of copy) to get offset within row
		LDA	source_canvas_x1
		ASL
		CLC
		ADC	$0B
		STA	$0B
		PHP
		LDA	source_canvas_x1
		ASL
		ROL
		AND	#$01
		PLP
		ADC	$0C
		STA	$0C
		LDA	$0D
		ADC	#$00
		STA	$0D
		LDA	#$00
		STA	$0E
		;; $0B-$0E contains the amount to add to the source canvas pointers
		LDX	#$10
		LDY	#$0B
		jsr	add_32bit_value	; X=X+Y
		LDX	#$14
		LDY	#$0B
		jsr	add_32bit_value		
		;; Normalise source canvas positions
		LDA	source_canvas_y2
		SEC
		SBC	source_canvas_y1
		STA	source_canvas_y2
		LDA	source_canvas_x2
		SEC
		SBC	source_canvas_x1
		STA	source_canvas_x2

		RTS

canvas_adjust_target_pointers_for_at_xy:	

		; target width*2 = row bytes		
		LDA	$09	
		ASL
		STA	$D770
		STA	$22	; low byte of row advance for dest
		ROL
		AND	#$01
		STA	$23	; high byte of row advance for dest
		STA	$D771
		;; start row
		LDA	target_canvas_y
		STA	$D774
		;; XXX - Wait for multiplier to finish
		;; Get multplier result and add X offset
		LDX 	#$00
@ll3:		LDA	$D778, X
		STA	$0B, X
		INX
		CPX	#4
		BNE	@ll3
		;; Now add 2*(X position of start of copy) to get offset within row
		LDA	target_canvas_x
		ASL
		CLC
		ADC	$0B
		STA	$0B
		PHP
		LDA	target_canvas_x
		ASL
		ROL
		AND	#$01
		PLP
		ADC	$0C
		STA	$0C
		LDA	$0D
		ADC	#$00
		STA	$0D
		LDA	#$00
		STA	$0E
		;; $0B-$0E contains the amount to add to the target canvas pointers
		LDX	#$18
		LDY	#$0B
		jsr	add_32bit_value	; X=X+Y
		LDX	#$1C
		LDY	#$0B
		jsr	add_32bit_value		
		;; Normalise target canvas positions
		;; Subtract target X offset from target width
		LDA	$09
		SEC
		SBC	target_canvas_x
		STA	$09
		;; Subtract target Y offset from target height
		LDA	$0A
		SEC
		SBC	target_canvas_y
		STA	$0A

		RTS
		
add_32bit_value:
		;; X=X+Y
		CLC
		LDA	$00, X
		ADC	$00, Y
		STA	$00, X
		INX
		INY
		LDA	$00, X
		ADC	$00, Y
		STA	$00, X
		INX
		INY
		LDA	$00, X
		ADC	$00, Y
		STA	$00, X
		INX
		INY
		LDA	$00, X
		ADC	$00, Y
		STA	$00, X
		RTS

add_16bit_value:
		;; X=X+Y
		CLC
		LDA	$00, X
		ADC	$00, Y
		STA	$00, X
		INX
		INY
		LDA	$00, X
		ADC	$00, Y
		STA	$00, X
		INX
		INY
		LDA	$00, X
		ADC	#0
		STA	$00, X
		INX
		INY
		LDA	$00, X
		ADC	#0
		STA	$00, X
		RTS
		
get_canvas0_pointers:
		;; Canvas 0 screen RAM is at $000E000,
		;; colour RAM at $FF82800
		LDA	#<$E000
		STA	$00,X
		LDA	#>$E000
		STA	$01, X
		LDA	#$00
		STA	$02, X
		STA	$03, X
		LDA	#<$2800
		STA	$04, X
		LDa	#>$2800
		STA	$05, X
		LDA	#<$0FF8
		STA	$06, X
		LDA	#>$0FF8
		STA	$07, X
		RTS
		
copy_32bit_pointer:
		;; Copy 4 bytes from $00XX to $00YY
		LDA	$00,X
		STA	$00,Y
		INX
		INY
		LDA	$00,X
		STA	$00,Y
		INX
		INY
		LDA	$00,X
		STA	$00,Y
		INX
		INY
		LDA	$00,X
		STA	$00,Y
		RTS		
		
megabasic_perform_canvas_settile:
		;; FALL THROUGH
megabasic_perform_undefined_function:
		LDX	#$1B
		JMP	$A437		

enable_viciv:
		LDA	#$47
		STA	$D02F
		LDA	#$53
		STA	$D02F

		RTS

update_viciv_registers:	

		;; Enable extended attributes / 8-bit colour register values
		LDA	#$20
		TSB	$D031
		
		;; Force 80 character virtual lines (80*2 for 16-bit char mode)
		LDA	#<80*2
		STA	$D058
		LDA	#>80
		STA	$D059
		;; Screen RAM start address ($0000A000)
		LDA	#$A0
		STA	$D061
		LDA	#$00
		STA	$D060
		STA	$D062
		STA	$D063
		;; Colour RAM start address ($0800)
		STA	$D064
		LDA	#$08
		STA	$D065
		;; Update $D054 bits
		LDA	$D054
		AND	#$EA
		ORA	d054_bits
		STA	$D054
		RTS
				
		
; -------------------------------------------------------------
; Tileset operations
; -------------------------------------------------------------

canvas_find:
		sta	search_canvas
		jsr 	tileset_point_to_start_of_area
		;; Are we looking for canvas 0?
		;; If yes, this is the special case. Always direct
		;; mapped at $E000, 80x50, and has no header structure
		lda	search_canvas
		CMP	#$00
		BNE	@canvasSearchLoop
		;; Set pointer to start of data
		LDA	#$00
		STA	$03
		STA	$05
		STA	$06
		LDA	#$E0
		STA	$04

		;; Set canvas size
		LDA	#80
		STA	canvas_width
		LDA	#50
		STA	canvas_height
		
		SEC
		RTS
@canvasSearchLoop:
		;; Find the next canvas (or first, skipping tileset header)
			jsr 	tileset_follow_pointer

		;; (We assume all following sections are valid, after having been installed.
		;; XXX - We sould check the magic string, just be to safe, anyway, though.)
		LDA	section_size+0
		ORA	section_size+1
		ORA	section_size+2
		BEQ	@endOfSectionList

		;; Found a section. Is the the one we want?
		LDZ	#15
		NOP
		NOP
		LDA	($03),Z
		LDZ	#0
		CMP	search_canvas
		BNE	@canvasSearchLoop
		BEQ	@foundCanvas
@endOfSectionList:		
		CLC
		RTS
@foundCanvas:
		;; Okay, we found it.
		;; Copy width and height out
		LDZ	#16
		NOP
		NOP
		LDA	($03),Z
		STA	canvas_width
		INZ
		NOP
		NOP
		LDA	($03),Z
		STA	canvas_height
		LDZ	#$00
		SEC
		RTS		
		
tileset_install:
		;; Sanity check the tile set that is in memory at 32-bit pointer
		;; in $03, and fix tile numbers in any canvases, so that they are
		;; correct for the tileset location.

		;; Check magic string
		LDZ 	#$00
		LDX	#$00
@magicCheckLoop:
		NOP
		NOP		
		LDA 	($03),Z
		beq	@magicOk
		CMP 	tileset_magic,X
		bne	@magicBad
		INZ
		INX
		CPX	#$10
		BNE	@magicCheckLoop
		BEQ	@magicOk
@magicBad:
		LDZ	#$00
		RTS		
@magicOk:
		;; Fix the first tile number.
		;; As we currently use a fixed location at $12000, and
		;; the header = 64 bytes + $300 of palette, the first tile
		;; will be at $12340 = $48D.
		LDZ #20
		lda #<($12000+$40+$300)
		NOP
		NOP
		STA ($03),Z
		INZ
		LDA #>($12000+$40+$300)
		NOP
		NOP
		STA ($03),Z
		LDZ	#$00

		;; Install the supplied palette.
		jsr tileset_install_palette

@sectionPrepareLoop:
		;; Then follow pointer to next section
		jsr 	tileset_follow_pointer
		LDA	section_size+0
		ORA	section_size+1
		ORA	section_size+2
		BEQ	@endOfSectionList

		;; There is another section to prepare
		jsr	tileset_install_section

		;; See if there are any more
		jmp	@sectionPrepareLoop
		
@endOfSectionList:

		RTS

tileset_install_section:
		;; At the moment the only sections that are allowed are
		;; screens (called CANVASes in MEGA BASIC)
		;; We thus must check for the magic string "MEGA65 SCREEN00",
		;; and can complain if it isn't found

		LDZ	#$00
		LDX	#$00
@magicCheckLoop:
		NOP
		NOP
		LDA	($03),Z
		beq	@emptySection
		CMP	canvas_magicstring,X
		bne	@badMagic
		INZ
		INX
		CPX	#15
		bne	@magicCheckLoop
		beq	@magicOk
@badMagic:
		;; Bad section - give a LOAD ERROR
		jmp	megabasic_perform_load_error
@emptySection:
		;; Empty section, so nothing to do
		;; (This relies on having an empty 64 byte block at end
		;; of the tileset file.)
		RTS
@magicOk:
		;; Now we have the CANVAS, we need to add the first tile number
		;; to all tile numbers in the screen RAM section
		;; so we need to look through *(unsigned short *)header[25] bytes
		;; at section + (header + 0x40) bytes, and add the first tile number
		;; (for now hardcoded at $12340/$40 = $048D) to them.
		LDZ	#25
		NOP
		NOP
		LDA	($03),Z
		STA	section_size+0
		INZ
		NOP
		NOP
		LDA	($03),Z
		STA	section_size+1
		LDZ	#$00
		jsr	tileset_stash_pointer		
		jsr	tileset_advance_by_64
@patchTileNumberLoop:
		;; It is nice to allow canvases to contain
		;; references to text characters when loaded. To do this
		;; we need to patch the values to be <$100, so that they
		;; aren't interpretted as full-colour character tiles.
		;; We do this by checking the bottom nybl of the hibh byte
		;; of the tile number. If zero, we don't patch it. If non-zero,
		;; we assume it is a tile number, and then patch it by $48D - $100
		;; (since the $100 offset was there already)

		;; Peek to see if we need to patch this tile
		INZ
		NOP
		NOP
		LDA	($03),Z
		DEZ
		AND	#$1F
		CMP	#$00
		bne	@doPatchTile
@tileVacant:
		INZ
		INZ
		jmp	@donePatchingTile
@doPatchTile:

		;;  But don't patch if the tile is $FFFF, which means not used.
		NOP
		NOP
		LDA	($03),Z
		INZ
		NOP
		NOP
		AND	($03),Z
		DEZ
		CMP	#$FF 	; true if tile is $FFFF = unused
		beq	@tileVacant
		
		NOP
		NOP
		LDA	($03),Z
		CLC
		ADC	#<($048D-$100)
		NOP
		NOP
		STA	($03),Z
		INZ
		NOP
		NOP
		LDA	($03),Z
		ADC	#>($048D-$100)
		NOP
		NOP
		STA	($03),Z
		INZ
@donePatchingTile:
		;; IF Z has wrapped to 0, then inc $04
		CPZ	#$00
		bne	@pointerOk
		inc	$04
@pointerOk:
		
		;; Decrement count of remaining bytes by 2
		lda	section_size+0
		SEC
		SBC	#$02
		STA	section_size+0
		LDA	section_size+1
		SBC	#$00
		STA	section_size+1
		ORA	section_size+0
		BNE	@patchTileNumberLoop

		;; When done, rewind back to where we were
		jsr	tileset_restore_pointer
		
		RTS
		

canvas_magicstring:
		.byte "MEGA65 SCREEN00",0
		
tileset_read_section_size:	
		LDZ	#61
		NOP
		NOP
		LDA	($03),Z
		STA	section_size+0
		INZ
		NOP
		NOP
		LDA	($03),Z
		STA	section_size+1
		INZ
		NOP
		NOP
		LDA	($03),Z
		STA	section_size+2

		LDZ	#$00
		RTS

tileset_point_to_start_of_area:	
		LDA 	#$00
		STA 	$06
		LDA 	#$01
		STA 	$05

		;; Lower 16 bits we start with pointing at $2000
		LDA 	#$20
		STA 	$04
		LDA 	#$00
		STA 	$03
		RTS

tileset_stash_pointer:
		LDX	#$03
@l1:		LDA	$03,X
		STA	stashed_pointer,X
		DEX
		BPL	@l1
		RTS

tileset_restore_pointer:
		LDX	#$03
@l1:		LDA	stashed_pointer,X
		STA	$03,X
		DEX
		BPL	@l1
		RTS
		
tileset_follow_pointer:
		;; Follow the pointer in the section, by adding
		;; the section length to the current pointer
		jsr	tileset_read_section_size
		;; FALL-THROUGH to tileset_advance_by_section_size

tileset_advance_by_section_size:	
		;; Add length to current pointer
		;; (Offsets are 24 bit, so we don't bother touching the
		;; 4th byte of the pointer.)
		lda	section_size+0
		CLC
		ADC	$03
		STA	$03
		lda	section_size+1
		ADC	$04
		STA	$04
		lda	section_size+2
		ADC	$05
		STA	$05
		RTS

tileset_advance_by_64:
		;; Add length to current pointer
		;; (Offsets are 24 bit, so we don't bother touching the
		;; 4th byte of the pointer.)
		lda	#$40
		CLC
		ADC	$03
		STA	$03
		lda	#$00
		ADC	$04
		STA	$04
		lda	#$00
		ADC	$05
		STA	$05
		RTS
		
tileset_retreat_by_64:
		;; Deduct 64 from current pointer
		;; (Offsets are 24 bit, so we don't bother touching the
		;; 4th byte of the pointer.)
		lda	$03
		SEC
		SBC	#$40
		STA	$03
		lda	$04
		SBC	#$00
		STA	$04
		LDA	$05
		SBC	#$00
		STA	$05
		RTS
		

tileset_retreat_by_section_size:	
		;; Add length to current pointer
		;; (Offsets are 24 bit, so we don't bother touching the
		;; 4th byte of the pointer.)
		LDA	$03
		SEC
		SBC	section_size+0
		STA	$03
		LDA	$04
		SBC	section_size+1
		STA	$04
		LDA	$05
		SBC	section_size+2
		STA	$05
		RTS

tileset_install_palette:
		;; Install palette from current tileset
		jsr	enable_viciv
		
		;; Advance to red palette
		lda 	#$40
		sta 	section_size+0
		lda	#$00
		sta	section_size+1
		sta	section_size+2
		jsr	tileset_advance_by_section_size
		LDZ	#$00
		LDX	#$00
@redloop:
		NOP
		NOP
		LDA	($03),Z
		STA	$D100,X
		INZ
		INX
		bne 	@redloop
		lda	#$00
		sta	section_size+0
		lda	#$01
		sta	section_size+1
		jsr	tileset_advance_by_section_size
@greenloop:
		NOP
		NOP
		LDA	($03),Z
		STA	$D200,X
		INZ
		INX
		bne 	@greenloop
		jsr	tileset_advance_by_section_size
@blueloop:
		NOP
		NOP
		LDA	($03),Z
		STA	$D300,X
		INZ
		INX
		bne 	@blueloop

		;; Now step back to start of section.
		;; (We have stepped forward $40 for header, and over 2x $100 for palettes)
		lda	#<$240
		sta	section_size
		lda	#>$240
		sta	section_size+1
		jsr 	tileset_retreat_by_section_size

		LDZ	#$00
		RTS				
		
tileset_magic:
		.byte "MEGA65 TILESET00",0

raster_irq:
		;; MEGA BASIC raster IRQ
		;; This happens at the bottom of the screen,
		;; and copies $E000-$FFFF to $A000 for screen RAM,
		;; and also the colour RAM from $FF82800-$FF847FF to
		;; $FF80800, and then merges in any required changes
		;; from the BASIC screen (char data from $0400 and
		;; colour data from $FF80000).
		;; We need to know if the MEGA BASIC screen is in 40 or
		;; 80 column mode, so that we know how to arrange memory.
		;; (Later we will allow the BASIC screen to be 80x50 also,
		;; which will obviate that, but we aren't there just yet).

		;; Do the initial copies using DMA
		;; (Oh, I am so glad we have DMA, and that we have the
		;; options header to allow setting all the source and destination
		;; locations etc.)
		;; XXX - This DMA *MUST* happen at 50MHz, or there won't be enough
		;; raster time.  But we allow people to use SLOW and FAST commands
		;; to control things in BASIC.  This means SLOW and FAST must use
		;; the VIC-IV speed control register, not the POKE0,65 trick, since
		;; there is no way to READ that, and thus restore it after.

		PHZ
		
		;; Remember current speed setting
		LDA	$D054
		PHA
		;; Enable 50MHz fast mode
		LDA	#$40
		TSB	$D054
		TSB	$D031	

		;; Clear raster IRQ
		INC	$D019

		lda	canvas_pause_drawing
		BNE	@dontDrawCanvas0

		;; Copy CANVAS 0 stored copy to display copy
		lda 	#>canvas0copylist
		STA	$D701
		LDA	#<canvas0copylist
		STA	$D705
		;; Go through BASIC screen, and copy and non-space
		;; characters, and also overwrite any characters <$100

		jsr 	merge_basic_screen_to_display_canvas

@dontDrawCanvas0:
		jsr	update_viciv_registers

		;; XXX $D06B - sprite 16 colour enables
		;; XXX $D06C-E - sprite pointer address
		
		;; Restore CPU speed and set $D054 video settings
		PLA
		AND	#$EA
		ORA	d054_bits		
		STA	$D054

		;; Chain to normal IRQ routine
		;; XXX - We should do this first, so that changing case with SHIFT-C=
		;; happens first, so that when it messes up the VIC-IV registers via touching
		;; hot reg $D016, we can fix it up without waiting for a whole frame.
		;; Else, we need two IRQ routines, the other at top of screen that all it does
		;; is fix the VIC-IV registers.
		PLZ
		JMP	$EA31

canvas0copylist:	
		;; Copy CANVAS 0 screen RAM from $E000 to $A000 for combining with BASIC scree
		.byte $0A,$00 	; F011A list follows		
		;; Normal F011A list
		.byte $04 ; fill + chained
		.word 80*50*2 ; size of copy 
		.word $E000 ; source address = fill value
		.byte $00   ; of bank $0
		.word $A000 ; destination address is $A000
		.byte $00   ; of bank $0
		.word $0000 ; modulo (unused)

		;; Copy colour RAM from $FF82800 down to $FF80800
		.byte $80,$FF  	; source is $FFxxxxx
		.byte $81,$FF  	; destination is $FFxxxxx
		.byte $0A,$00 	; F011A list follows
		;; Normal F011A list
		.byte $00 ; copy + end of chain
		.word 80*50*2 ; size of copy is 4000 bytes
		.word $2800 ; source address = fill value
		.byte $08   ; of bank $0
		.word $0800 ; destination address is $0800
		.byte $08   ; of bank $0
		.word $0000 ; modulo (unused)

merge_basic_screen_to_display_canvas:
		;; Merge BASIC screen onto display canvas.
		;; Because of the expansion of bytes this is a bit fiddly.
		;; Ideally we need to copy line by line, because the line steppings are different
		;; from source to destination

		;; Thus we need 4 pointers:
		;; 1. BASIC 2 screen RAM ($0B-$0C)
		;; 2. BASIC 2 colour RAM ($09-$0A)
		;; 3. MEGA BASIC display canvas screen RAM  ($07-$08)
		;; 4. MEGA BASIC display canvas colour RAM  ($03-$06)
		;; We need to thus first save $03-$0C to a scratch space
		jsr	zp_scratch_stash_b

		;; We also need to bank out the BASIC ROM
		LDA	$01
		AND	#$FE
		STA	$01

		;; 16-bit pointer to BASIC screen RAM
		LDA	#<$0400
		STA	$0B
		LDA	#>$0400
		STA	$0C
		;; 16-bit pointer to canvas screen RAM
		LDA	#<$A000
		STA	$07
		LDA	#>$A000
		STA	$08
		;; 16-bit pointer to BASIC 2 colour RAM
		LDA	#<$D800
		STA	$09
		LDA	#>$D800
		STA	$0A
		;; Set 32-bit pointer to canvas colour RAM
		LDA 	#<$0800
		STA	$03
		LDA	#>$0800
		STA	$04
		LDA	#<$0FF8
		STA	$05
		LDA 	#>$0FF8
		STA	$06

.if 1
		
		;;  X = line number
		LDX	#$00
@screenLineLoop:
		;; Y = BASIC 2 position on line
		LDY	#$00
		;; Z = Display canvas position on line ( = Y * 2)
		LDZ	#$00		
@screenCopyCheckLoop:
		;; Is BASIC 2 char other than space?
		;; If not space, then it should replace the tile
		LDA	($0B), Y
		CMP	#$20
		BEQ	@dontReplaceTile
@replaceTileWithChar:
		;; Replace screen RAM bytes
		;; low byte = char
		LDA	($0B), Y
		STA	($07), Z
		;; high byte = more char bits (must be zero), and some VIC-IV attributes, that
		;; are zero for bytes copied from BASIC 2 screeen
		LDA	#$00
		INZ
		STA	($07), Z
		DEZ
		;; Replace colour RAM bytes (trickier as not direct mapped)
		;; Extended attributes in first byte (zero when copied from BASIC 2 screen)
		LDA	#$00
		NOP
		NOP
		STA	($03),Z
		;; Colour goes in 2nd byte
		INZ
		LDA	($09), Y
		NOP
		NOP
		STA	($03),Z
		DEZ
@dontReplaceTile:
		INZ
		INZ
		INY
		;; At end of BASIC 2 line?
		CPY	#40
		BNE	@screenCopyCheckLoop
		;; Advance the various pointers
		;; canvas display colour RAM
		LDA	$03
		CLC
		ADC	#80*2
		STA	$03
		LDA	$04
		ADC	#$00
		STA	$04
		;; Display canvas screen RAM
		LDA	$07
		CLC
		ADC	#80*2
		STA	$07
		LDA	$08
		ADC	#0
		STA	$08
		;; BASIC 2 colour RAM
		LDA	$09
		CLC
		ADC	#40
		STA	$09
		LDA	$0A
		ADC	#0
		STA	$0A
		;; BASIC 2 screen RAM
		LDA	$0B
		CLC
		ADC	#40
		STA	$0B
		LDA	$0C
		ADC	#0
		STA	$0C
				
		INX
		CPX	#25
		BNE	@screenLineLoop

.endif
		
		;; Always end with Z=0, to avoid crazy behaviour from 6502 code
		LDZ	#$00
		
		jsr	zp_scratch_restore_b
		
		;; Put BASIC ROM back
		LDA	$01
		ORA	#$01
		STA	$01
		
		RTS

		;; We use $03-$22 in ZP as scratch space for some
		;; things.  To be compatible, we save it first, and
		;; restore it again after.
		
zp_scratch_stash:	
		LDX	#$00
@c:		LDA	$03, X
		STA	merge_scratch, X
		INX
		CPX	#$20
		BNE	@c
		RTS

zp_scratch_restore:
		;; Restore ZP bytes
		LDX	#$00
@c2:		LDA	merge_scratch, X
		STA	$03, X
		INX
		CPX	#$20
		BNE	@c2
		RTS
		
zp_scratch_stash_b:	
		LDX	#$00
@c:		LDA	$03, X
		STA	merge_scratch_b, X
		INX
		CPX	#$20
		BNE	@c
		RTS

zp_scratch_restore_b:
		;; Restore ZP bytes
		LDX	#$00
@c2:		LDA	merge_scratch_b, X
		STA	$03, X
		INX
		CPX	#$20
		BNE	@c2
		RTS
		

; -------------------------------------------------------------
; Variables and scratch space	
; -------------------------------------------------------------

d054_bits:
		;; $01 = sixteen bit character mode
		;; $04 = full colour for chars >$FF
		;; $10 = sprite H640
		;; $40 = 50MHz enable
		;; $80 = Alhpa blender enable
		.byte $85
		
		;; Flag to indicate which half of token list we are in.
token_hi_page_flag:
		.byte $00

		;; If non-zero, then we don't update the visible canvas.
		;; This allows slow off-screen scene preparation, without glitching
canvas_pause_drawing:
		.byte $00
		
		;; Where a colour is being put
colour_target:
		.byte $00

		;; 24-bit length of a tileset section
section_size:
		.byte 0,0,0
		;; Temporary storage for a 32-bit pointer
stashed_pointer:
		.byte 0,0,0,0

merge_scratch:
		.res $20,0

merge_scratch_b:
		.res $20,0		

		;; For CANVAS stamping (copying)
source_canvas:	.byte 0
source_canvas_x1:	.byte 0
source_canvas_y1:	.byte 0
source_canvas_x2:	.byte 0
source_canvas_y2:	.byte 0
target_canvas:	.byte 0
target_canvas_x:	.byte 0
target_canvas_y:	.byte 0

search_canvas:		.byte 0
canvas_width:		.byte 0
canvas_height:		.byte 0

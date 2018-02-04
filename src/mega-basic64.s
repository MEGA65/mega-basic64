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
		lda 	#>c000blockdmalist
		sta	$d701
		lda	#<c000blockdmalist
		sta	$d705

		;; enable wedge
		jsr 	megabasic_enable

		;; Then make the demo tile set available for use
		jsr 	tileset_point_to_start_of_area
		jsr 	tileset_install
		
		rts

c000blockdmalist:
		.byte $0A,$00 	; F011A list follows
		;; Normal F011A list
		.byte $04 ; copy + chained request
		.word preloaded_tiles_length ; set size
		.word preloaded_tiles  ; starting at $4000
		.byte $00   ; of bank $0
		.word $2000 ; destination address is $2000
		.byte $01   ; of bank $1 ( = $12000)
		.word $0000 ; modulo (unused)		
		
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
		.incbin "bin/megabanner.tiles"
preloaded_tiles_end:	
		preloaded_tiles_length = preloaded_tiles_end - preloaded_tiles
		
;-------------------------------------------------------------------------------
		;; Routines that get installed at $C000
;-------------------------------------------------------------------------------
c000block:	
		.org $C000

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
		;; And the end byte
		.byte $00		


megabasic_perform_tile:
		;; Valid syntax options:
		;; TILE SET LOAD <"filename"> [,device]
		CMP	#token_set
		bne	megabasic_perform_syntax_error
		JSR	$0073
		CMP	#$93 	; Token for "LOAD" keyword
		bne	megabasic_perform_syntax_error
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
		LDA	#65
		STA	$00
		JMP	basic2_main_loop		
		
megabasic_perform_slow:
		LDA	#64
		STA	$00
		JMP	basic2_main_loop		
		
megabasic_perform_colour:
		;; What are we being asked to colour?
		SEC
		SBC	#token_text
		BMI	megabasic_perform_undefined_function
		CMP	#token_stamp-token_text
		BCS	megabasic_perform_undefined_function
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

		JMP	basic2_main_loop

		
megabasic_perform_screen:

megabasic_perform_load_error:
		LDX	#$1D
		JMP	$A437
		
megabasic_perform_syntax_error:
		LDX	#$0B
		JMP	$A437

megabasic_perform_illegal_direct_error:
		LDX	#$15
		JMP	$A437

megabasic_perform_canvas:
		;; FALL THROUGH for unimplemented commands
megabasic_perform_undefined_function:
		LDX	#$1B
		JMP	$A437		

enable_viciv:
		LDA	#$47
		STA	$D02F
		LDA	#$53
		STA	$D02F
		;; Enable extended attributes / 8-bit colour register values
		LDA	#$20
		STA	$D031
		RTS

; -------------------------------------------------------------
; Tileset operations
; -------------------------------------------------------------
		
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
		INC	$D020
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
		INX
		AND	#$1F
		CMP	#$00
		bne	@doPatchTile
		INZ
		jmp	@donePatchingTile
@doPatchTile:
		
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
		
		

; -------------------------------------------------------------
; Variables and scratch space	
; -------------------------------------------------------------

		;; Flag to indicate which half of token list we are in.
token_hi_page_flag:
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

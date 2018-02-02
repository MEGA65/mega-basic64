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
		lda 	#$47
		sta	$d02f
		lda	#$53
		sta 	$d02f
		
		;; Install $C000 block
		lda 	#>c000blockdmalist
		sta	$d701
		lda	#<c000blockdmalist
		sta	$d705

		;; enable wedge
		jsr megabasic_enable
		rts

c000blockdmalist:
		.byte $0A,$00 	; F011A list follows
		;; Normal F011A list
		.byte $00 ; copy + last request in chain
		.word $1000 ; size of copy is 16KB
		.word c000block ; starting at $4000
		.byte $00   ; of bank $0
		.word $C000 ; destination address is $8000
		.byte $00   ; of bank $F
		.word $0000 ; modulo (unused)		


;-------------------------------------------------------------------------------
		;; Routines that get installed at $C000
;-------------------------------------------------------------------------------
c000block:	
		.org $C000

megabasic_enable:
		;; Copy C64 tokenise routine
		LDX #($A612-$A57C+1)
@tokenisecopy:
		lda $a57c,x
		sta c64_tokenise,x
		dex
		cpx	#$ff
		bne @tokenisecopy

.if 1
		;;  Copy C64 tokens to start of our token list
		;; (but don't copy end of token list)
		LDX	#(($A19C -1) - $A09E + 1)
@tokencopy:
		lda	$A09E,x
		sta	tokenlist,x
		dex
		cpx 	#$ff
		bne 	@tokencopy
.endif
		
		;; install vector
		lda #<c64_tokenise
		sta tokenise_vector
		lda #>c64_tokenise
		sta tokenise_vector+1

		;; Patch the tokenise routine
		
		;; $A5AE resets Y to 0 (start of token list), and stores it also in $0B
		;; 		LDY #$00
		;; 		STY $0B
		lda	#$4c
		sta 	addr_of_a5ae+0
		lda	#<mega_a5ae
		sta 	addr_of_a5ae+1
		lda	#>mega_a5ae
		sta 	addr_of_a5ae+2
		
		
		;; $A5BC does SBC tokenlist,Y
		;; 		SBC $A09E,Y
		lda	#$4c
		sta 	addr_of_a5bc+0
		lda	#<mega_a5bc
		sta 	addr_of_a5bc+1
		lda	#>mega_a5bc
		sta 	addr_of_a5bc+2

		;; $A5F9 skips to the next word in the token list.
		;; 	@l	INY
		;; 		LDA tokenlist-1,y
		;; 		BPL @l
		lda	#$4c
		sta 	addr_of_a5f9+0
		lda	#<mega_a5f9
		sta 	addr_of_a5f9+1
		lda	#>mega_a5f9
		sta 	addr_of_a5f9+2

		;; $A5FF branches to $A5B8 if the end of the token list has not yet been reached.
		;; 		LDA tokenlist,y
		;; 		BNE $A5B8
		lda	#$4c
		sta 	addr_of_a5ff+0
		lda	#<mega_a5ff
		sta 	addr_of_a5ff+1
		lda	#>mega_a5ff
		sta 	addr_of_a5ff+2

		
		RTS

megabasic_disable:
		RTS

megabasic_tokenise:
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
		addr_of_a5ae	=	c64_tokenise + $A5AE - $A57C
		addr_of_a5b8	=	c64_tokenise + $A5B8 - $A57C
		addr_of_a5bc	=	c64_tokenise + $A5BC - $A57C
		addr_of_a5f9	=	c64_tokenise + $A5F9 - $A57C
		addr_of_a5ff	=	c64_tokenise + $A5FF - $A57C

mega_a5ae:
		LDY #$00
		STY $0B
		STY token_hi_page_flag
		jmp addr_of_a5ae+4

mega_a5bc:
		;; XXX - This routine assumes that no token crosses the page boundary.
		;; We purposely structure our token list to ensure this is true.

		;; Make sure we don't try to go over the end of the page
		cpy #$ff
		bne @notendofpage
		sty token_hi_page_flag
		ldy #$00
@notendofpage:
		bit token_hi_page_flag
		bne @readfromhi

		SEC
		SBC tokenlist,y
		
		jmp addr_of_a5bc+3
@readfromhi:
		SEC
		SBC tokenlist+$100,y
		jmp addr_of_a5bc+3

mega_a5f9:
@l:
		INY
		beq @readfromhi
		bit token_hi_page_flag
		bne @readfromhi
 		LDA tokenlist-1,y
 		BPL @l
		jmp addr_of_a5ff
@readfromhi:
		;; Set token high page flag if we stepped over
		LDA #$01
		sta token_hi_page_flag
 		LDA tokenlist+$100-1,y
 		BPL @l
		jmp addr_of_a5ff		

mega_a5ff:
		bit token_hi_page_flag
		bne @readfromhi
		LDA tokenlist,y
		BNE jmp_to_addr_of_A5B8
		jmp addr_of_a5ff+3
@readfromhi:
		LDA tokenlist+$100,y
		BNE jmp_to_addr_of_A5B8
		jmp addr_of_a5ff+3

jmp_to_addr_of_A5B8:
		jmp addr_of_a5b8

token_hi_page_flag:
		.byte $00
		
tokenlist:
		;; Reserve space for C64 BASIC token list, less the end $00 marker
		.res ($A19C - $A09E + 1), $00
		;; Have a 1 letter token, so that no token crosses the page boundary
		 .byte $DC	; GBP symbol (now a token :)
		;; Now we have our new tokens
		.byte $53,$43,$52,$45,$45,$CE ; "SCREEN"
		;; And the end byte
		.byte $00
		
c64_tokenise:
		.res ($A612 - $A57C + 1), $EA
		

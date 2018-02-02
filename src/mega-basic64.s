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

		;; Patch the tokenise routine

		;; install vector
		lda #<c64_tokenise
		sta tokenise_vector
		lda #>c64_tokenise
		sta tokenise_vector+1
		
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



c64_tokenise:
		.res ($A612 - $A57C + 1), $EA
		

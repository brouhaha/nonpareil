; HP classic calculator instruction encoding test
; Eric Smith <eric@brouhaha.com>
; 19-JUL-2004

; The Classic series architecture as originated in the HP-35 and HP-80
; originally defined any instruction of the form xxxx110100 to be a
; "clear status" instruction.  This was implemented in the CTC chip,
; HP part number 1818-0012.  In practice, the only opcode used for
; this instruction was 0000110100, though I believe that other
; combinations of the upper four bits would work as well with the
; early CTC chip.

; The HP-55 and HP-65 needed more than the eight pages of ROMs
; supported by the earlier models.  A new "quad ROM" was designed that
; supported the use of two ROM groups, by implementing the "delayed
; select group" instruction.  At the same time, a "delayed select rom"
; instruction was added to simplify jumps between ROM pages.

; The encodings chosen for the "delayed select" instructions are some
; of the "clear status" encodings with nonzero upper bits.  In
; particular, "delayed select rom n" is encoded as nnn1110100, and
; "delayed select group n" is encoded as 10n0110100.  Possibly there
; may have been provision for four groups encoded as 1nn0110100, but
; no Classic series calculator was produced with more than 4K words of
; memory, so such a feature was not used in practice.

; These newer models always use a newer CTC, HP part number 1818-0078,
; which I believe was modified to treat the nonzero encodings as a "no
; operation" rather than clearing the status bits.  (The actual
; "delayed select" instructions are implemented by the ROM chips.)
; Later production of the HP-35, HP-45, and HP-80 also use the new
; CTC.

; This source file may be assembled with uasm from the Nonpareil
; package to demonstrate the instruction encodings.

; http://nonpareil.brouhaha.com/

	.arch classic

	.rom @00

	clear status

	delayed select rom 0
	delayed select rom 1
	delayed select rom 2
	delayed select rom 3
	delayed select rom 4
	delayed select rom 5
	delayed select rom 6
	delayed select rom 7
	
	delayed select group 0
	delayed select group 1
		
	.symtab

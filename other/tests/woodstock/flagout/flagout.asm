; Woodstock flag 0 output test
; Copyright 2005 Eric L. Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

        .rom 0

loop:	0 -> s flagout 0	; clear flag output
	nop
	nop
	nop
	1 -> s flagout 0	; set flag output
	go to loop	

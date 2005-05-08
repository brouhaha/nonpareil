; Woodstock keyboard scancode test
; Copyright 2005 Eric L. Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

        .rom 0

	nop
	binary
	display off
	reset twf		   ; set fourteen-digit display mode
	display toggle
	
	0 -> c[w]		; initially display "ooo"
	p <- 2
	load constant 12
	load constant 12
	load constant 12
	c -> a[w]
	jsb disp

loop:	0 -> s key 15		; wait for key press
kwait:	if 0 = s key 15
	  then go to kwait

	0 -> a[w]
	keys -> a		; get keycode into a[xs]

test7:	a -> b[x]
	a + b -> a[x]
	if n/c go to test6
	p <- 5
	load constant 2
	p <- 5
	a + c -> a[p]

test6:	a -> b[x]
	a + b -> a[x]
	if n/c go to test5
	p <- 5
	load constant 1
	p <- 5
	a + c -> a[p]

test5:	a -> b[x]
	a + b -> a[x]
	if n/c go to test4
	p <- 4
	load constant 4
	p <- 4
	a + c -> a[p]

test4:	a -> b[x]
	a + b -> a[x]
	if n/c go to test3
	p <- 4
	load constant 2
	p <- 4
	a + c -> a[p]

test3:	a -> b[x]
	a + b -> a[x]
	if n/c go to test2
	p <- 4
	load constant 1
	p <- 4
	a + c -> a[p]

test2:	a -> b[x]
	a + b -> a[x]
	if n/c go to test1
	p <- 3
	load constant 4
	p <- 3
	a + c -> a[p]

test1:	a -> b[x]
	a + b -> a[x]
	if n/c go to test0
	p <- 3
	load constant 2
	p <- 3
	a + c -> a[p]

test0:	a -> b[x]
	a + b -> a[x]
	if n/c go to testd
	p <- 3
	load constant 1
	p <- 3
	a + c -> a[p]

testd:	shift right a[w]
	shift right a[w]
	shift right a[w]
	jsb disp

rwait:	0 -> s key 15		; wait for key release
	if 1 = s key 15
	  then go to rwait
	go to loop


; enter disp with three digits to display in a[x]
disp:	0 -> a[ms]
	a - 1 -> a[ms]
	shift left a[w]
	shift left a[w]
	shift left a[w]
	0 -> a[x]
	a - 1 -> a[x]
	0 -> b[w]
	return

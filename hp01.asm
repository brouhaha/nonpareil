; HP-01 partial ROM sources from United States Patent 4,158,285
; Copyright 2004 Eric L. Smith <eric@brouhaha.com>
; $Id$
; Keyed in by Eric Smith on 21-Jan-2004 - any errors are probably mine.

; The code from the patent almost certainly does not match released
; code in production HP-01 watches, for two reasons:

; The keyboard layout shown in the patent differs from the production
; HP-01.

; The HP-01 is reported to two "quads" of ROM (2048 words), but the
; patent listings include nine ROMs (2304 words).  The patent listings
; have a fair amount of empty space near the end of some of the ROMs,
; so the code was probably rearranged to fit in two quads at a later
; date.

; This source code has not yet been checked against the object code in
; the patent listing.


	file	cri0

	entry	getkey
	entry	prekey
	entry	awake
	entry	cnvint
	entry	cnvex
	entry	keyrel

pon	goto	pwron
9	a=a+1	xs
	nop
8	a=a+1	xs
7	a=a+1	xs
	nop
6	a=a+1	xs
5	a=a+1	xs
	nop
4	a=a+1	xs
	nop
3	a=a+1	xs
2	a=a+1	xs
	nop
1	a=a+1	xs
0	dspoff
ret	return
memory	goromd	6
	gotox	memory
alarm	goromd	6
	gotox	alarm
time	goromd	6
	gotox	time
pm	goromd	5
	gotox	pm
=	goromd	7
	gotox	equals
%	a=a+1	x
x	a=a+1	x
	nop
-	a=a+1	x
+	goromd	7
	gotox	oprtrs
c	dspoff
	goto	clear
m	goto	memory
->	dspoff
	goto	prefix
a	goto	alarm
/	p=	0
spchk	dspoff
	? s4=	0
	goyes	ret
	goromd	5
	gotox	fcns
prefix	a=a+1	xs
	gonc	*-1
	s4=	1
	goto	prekey
readcl	goromd	1
	gotox	readcl
t	goto	time
d	goromd	6
	gotox	date
	a=a+1	xs
	p=	1
	goto	spchk
am	goromd	5
	gotox	am
p	goto	pm
s	goromd	6
	gotox	stwtch
r	goto	rkey
wakeup	s5=	1
	a=c	s
	a=a-1	s
	a=a-1	s
	a=a-1	s
	gonc	*+2
	goto	cnvdsp
	a=a-1	s
	gonc	*+2
	goto	cnvdsp
	s5=	0
	goromd	8
	gotox	swcalc
dspon	a=dsp
getkey	s4=	0
prekey	dspon
awake	? s9=	0
	goyes	keyrel
	? s11=	0
	goyes	keyrel
	? s12=	0
	goyes	keyrel
	dsscwp
	? s0=	0
	goyes	*+2
	goto	*-2
	enscwp
	goto	*+4
keyrel	? s0=	0
	goyes	*+2
	goto	*-2
	a=a+1	xs
	gonc	*-1
sleep	sleep
	dsscwp
	gokeys
clear	? s8=	0
	goyes	clall
	goto	clent
pwron	dsscwp
	swstop
	sw+
	s1-7=	0
	clrreg
	al=a
	sw=a
	m=c
	altog
	clrs=a
	cl=a
clall	f=a(p)
	s6=	0
	c=0
	cd ex
clent	c=0
	s8-15=	0
	s15=	1
cnvdsp	goromd	1
	gotox	cnvdsp
rkey	a=c	s
	a=a-1	s
	a=a-1	s
	a=a-1	s
	gonc	dspon
	goromd	6
	gotox	swsprs
cnvint	p=	11
	a(p)=	1
	a=a-1	s
	gonc	entchk
	a=a+1	s
	gonc	*+4
	a=sw
	ac ex	wp
	goto	cnvex
	a=a+1	s
	gonc	entchk
	gosub	readcl
	goto	cnvex
entchk	? s15=	0
	goyes	entry
	goto	cnvex
	a(p)=	0
entry	c=a+c	p
	gonc	*+3
	? c#0	p
	goyes	*-4
	p=	2
zrblnk	a=0	p
	p=p+1
	c=a+c	p
	gonc	*+3
	? c#0	p
	goyes	zrblnk
	c=0	m
	? s13=	0
	goyes	*+2
	goto	*+3
	? s14=	0
	goyes	decint
timdat	p=	5
	c=a+c	p
	gonc	hmschk
	? c#0	p
	goyes	hmschk
	a sl	wp
	p=	8
	a sl	wp
	a sr
	a sr
h:m:s	a sr
	a sr
	a sr
h:m	p=	10
	ac ex	wp
	? c#0	wp
	goyes	*+3
	c=0	s
	c=c+1	s
	p=	5
	gosub	timchk
	p=	3
	gosub	timchk
	s13=	0
	goto	cnvex
timchk	a(p)=	5
	p=p+1
	? a>=c	p
	goyes	ret
cnverr	blink
	a=dsk
	c=0	m
	goromd	1
	gotox	dspon
hmschk	a ls	wp
	p=	8
	c=a+c	p
	gonc	h:m
	a sl	wp
	a=0	s
	? s14=	0
	goyes	h:m:s
datein	gosub	swapmd
	p=	10
	ac ex	wp
	a=0
	a(p)=	3
	a(p)=	2
	a(p)=	1
	a(p)=	3
	p=	8
	ac ex	m
	? a>=c	wp
	goyes	cnverr
	c=0	wp
	? a>=c	m
	goyes	cnverr
	ac ex	m
	gosub	zrchk
	p=	10
	gosub	zrchk
	goromd	4
	gotox	datdec
zrchk	? c#0	p
	goyes	ret
	p=p-1
	? c=0	p
	goyes	cnverr
	return
swapmd	goromd	1
	gotox	swapmd
decint	p=	10
	a=a+b	p
	gonc	pos
	? a#0	m
	goyes	*+3
	c=0
	goto	cnvex
	c=c-1	x
	a sl	m
	? a#0	p
	goyes	decex
	goto	*-4
	c=c+1	x
pos	p=p-1
	a=a+b	p
	gonc	*-3
	a sl	wp
decex	ac ex	m
cnvex	a=0
	b=0
	s15=	1
	return
	end

	file	cri1

	entry	cnvdsp
	entry	swapmd
	entry	readcl
	entry	dspon
	entry	sign

cnvdsp	a=0
	b=0
	p=	0
	s4=	0
	s10=	0
	a=c	s
decchk	a=a-1	s
	gonc	intchk
decdsp	a=0	s
	a(p)=	6
	? a>=c	x
	goyes	fixpt
	a=0	x
	a=a-1	x
	p=	0
	a(p)=	5
	a=a-c	x
	gonc	scovck
fixpt	a=c	m
	a=c	x
	? a#0	xs
	goyes	*+4
	a=a+1	x
	legal
	goto	*+4
	a sr	m
	a=a+1	x
	gonc	*-2
	p=	3
	gosub	dsprnd
	p=	10
	goto	*+3
	p=p-1
	a=a-1	x
	? a#0	x
	goyes	*-3
	a sr	wp
	a(p)=	.
	p=	3
	goto	spress
scovck	? a#0	x
	goyes	*+2
	s4=	1
sci	a=c	m
	a=c	x
	p=	6
	gosub	dsprnd
	ac ex	x
	p=	6
	? c=0	xs
	goyes	*+4
	c=-c	x
	a(p)=	-
	goto	*+2
	a(p)=	blank
	ac ex	x
	a sl	wp
	a sl	wp
	a sl	wp
	a sl	wp
	p=	9
	a sr	wp
	a(p)=	.
	p=	6
spress	? a#0	p
	goyes	signfx
	a(p)=	blank
	p=p+1
	p=p+1
	goto	spress
dsprnd	ab ex	m
	a(p)=	5
	a=a+b	ms
	b=0	m
	? a#0	s
	goyes	*+2
	return
	a sr	ms
	a=a+1	x
	? s4=	0
	goyes	*-4
	goto	fixpt
intchk	a=a-1	s
	gonc	swchk
intdsp	a=c
	p=	5
	ab ex	wp
	? a#0	m
	goyes	hrs
	ab ex	wp
	s4=	1
	a sl
	a sl
	goto	hmssft
h:m	ab ex	wp
	p=	10
	? a#0	p
	goyes	colins
	a(p)=	blank
	goto	*-3
hrs	ab ex	wp
	p=	7
	ab ex	wp
	? a#0	m
	goyes	h:m
	ab ex	wp
hmssft	a sl
	a sl
	a sl
	p=	8
	a sr	wp
	a(p)=	:
colins	p=	5
	a sr	wp
	? s4=	0
	goyes	*+3
	a(p)=	.
	goto	*+2
	a(p)=	:
signfx	gosub	sign
cndsex	dsp=a
	a=c	s
	a=a-1	s
	a=a-1	s
	a=a-1	s
	gonc	*+3
	dsp=sw
	goto	*+4
	a=a-1	s
	gonc	*+2
	dsp=cl
	a=dsp
	? s13=	0
	goyes	*+2
	dsp=al
	? s5=	0
	goyes	*+2
	goto	*+2
dspon	dspon
	s5=	0
keyent	goromd	2
	gotox	keyent
sign	p=	11
	a(p)=	5
	p=	11
	? a>=c	s
	goyes	*+3
	a(p)=	-
	return
	a(p)=	blank
	return
swchk	a=a-1	s
	gonc	clkchk
	a=sw
	ac ex
	ac ex	s
	goto	intdsp
clkchk	a=a-1	s
	gonc	timchk
	gosub	readcl
	goto	timdsp
readcl	a=cl
	cl=a
	a sl
	a sl
	c=0	m
	p=	7
	ac ex	wp
	return
timchk	a=a-1	s
	gonc	datchk
timdsp	a=0
	p=	5
	? s1=	0
	goyes	12mode
	p=	7
12ret	a=c	wp
	a sl
	a sl
	a sl
	a sl
	p=	9
	a sr	wp
	a(p)=	:
	p=	6
	a sr	wp
	a(p)=	blank
	p=	3
	? s10=	0
	goyes	*+3
	a(p)=	.
	goto	*+2
	a(p)=	blank
leadzr	p=	11
	? a#0	p
	goyes	*+2
	a(p)=	blank
	p=	0
	goto	cndsex
12mode	a=c	m
	ab ex	m
	b=0	wp
	p=	7
	a(p)=	1
	a(p)=	2
	ab ex
	a=a-b
	gonc	pm
	a=a+b
pmret	? a#0
	goyes	12ret
	a=a+b
	legal
	goto	12ret
pm	s10=	1
	goto	pmret
datchk	a=a-1	s
	gonc	negchk
	a=c
	gosub	swapmd
	a sl
	p=	9
	a sr	wp
	a(p)=	-
	p=	6
	a sr	wp
	a(p)=	-
	p=	3
	? a#0	p
	goyes	*+3
	a(p)=	blank
	goto	leadzr
	a(p)=	.
	goto	leadzr
swapmd	? s2=	0
	goyes	*+2
	return
	p=	8
	ab ex	m
	ab ex	wp
	p=	7
	b sr	m
	a sl	m
	a sr	wp
	b sr	m
	a sl	m
	a sr	wp
	a=a+b	m
	return
negchk	a=a-1	s
	a=a-1	s
	a=a-1	s
	gonc	decdsp
	goto	intdsp
	fillto	end
	end

	file	cri2

	entry	keyent

keyent	p=	2
	a(p)=	8
	p=	2
	b=a	xs
	a=0	x
	s4=	0
	gosub	awake
	s8-15=	0
	s8=	1
	a=0	m
	b=0	m
	c=0
	? p#	0
	goyes	*+4
	p=	11
	a(p)=	blank
	goto	datent
	? p#	1
	goyes	zerchk
	p=	11
	a(p)=	blank
	? a#0	xs
	goyes	*+2
	goto	timent
dphit	p=	2
	a(p)=	.
	s10=	1
zerret	p=	2
digits	c=b	xs
	? c=0	xs
	goyes	keylp
	c=c-1	xs
	bc ex	xs
	c=b	xs
	? c#0	xs
	goyes	shftlp
lstdig	? s10=	0
	goyes	*+2
	goto	shftlp
	s10=	1
	goto	keylp
zerchk	p=	11
	a(p)=	blank
	? a#0	xs
	goyes	zerret
	s15=	1
cnvdsp	goromd	1
	gotox	cnvdsp
getkey	goromd	0
	gotox	getkey
awake	goromd	0
	gotox	awake
	c=c-1	xs
shftlp	p=p+1
	a sl	wp
	? c#0	xs
	goyes	*-4
	p=p-1
	? s10=	0
	goyes	*+2
	goto	*+2
	a(p)=	.
	a(p)=	blank
	? p#	1
	goyes	*-2
keylp	a=0	x
	p=	2
	dsp=a
	gosub	getkey
	? p#	2
	goyes	*+2
	goto	digits
	? s10=	0
	goyes	*+2
	goto	keylp
	? p#	1
	goyes	datent
	? a#0	xs
	goyes	dphit
timent	p=	2
	a(p)=	2
	? a>=b	xs
	goyes	keylp
	c=c+1	s
	gonc	*+3
	c=c-1	s
	c=c-1	s
	s13=	1
	p=	2
	a(p)=	5
	? a>=b	xs
	goyes	*+2
	goto	tdfix
	p=	2
	a(p)=	2
	a=a-b	xs
	b=0
	goto	*+4
	p=	10
	a sr	m
	a(p)=	blank
	a=a+1	xs
	gonc	*-4
	p=	5
	goto	colon
datent	? c#0	s
	goyes	keylp
	p=	2
	a(p)=	5
	? a>=b	xs
	goyes	keylp
	ac ex	s
	p=	11
	a(p)=	5
	ac ex	s
	s14=	1
tdfix	ab ex	xs
	a=a-b	xs
	a=a-1	xs
	? a#0	xs
	goyes	*+2
	goto	twodig
	a sr	m
	? s14=	0
	goyes	*+3
	p=	10
	a(p)=	blank
twodig	p=	2
	a(p)=	3
	ab ex	xs
	p=	8
	? s13=	0
	goyes	*+3
colon	a(p)=	:
	goto	*+2
dash	a(p)=	-
	a(p)=	0
	a(p)=	0
dspfix	a(p)=	blank
	? p#	1
	goyes	*-2
tdloop	a=0	x
	p=	2
	dsp=a
	gosub	getkey
	? p#	2
	goyes	spchar
	? b=0	xs
	goyes	dspful
	p=	5
	a sl	wp
	a sl	wp
	a sl	wp
dspful	p=p+1
	p=p+1
	a sl	wp
	p=p-1
	p=p-1
	goto	dspfix
spchar	? b=0	xs
	goyes	tdloop
	? s13=	0
	goyes	datsp
timsp	? p#	1
	goyes	tdloop
	? a#0	xs
	goyes	dphit
	b=0
	p=	5
	goto	colon
datsp	? p#	0
	goyes	tdloop
	b=0
	p=	5
	goto	dash
	fillto	end
	end

	file	cri3

	entry	decto
	entry	decdat
	entry	dectim
	entry	day/yr
	entry	inc
	entry	divstp
	entry	thms

decto	p=	0
	a=0
	a=c	s
	? a#0	s
	goyes	*+2
	return
	a=a+1	s
	gonc	*+2
	return
	a=a-1	s
	a=a+c	s
	? a#0	s
	goyes	dectim
decdat	? c=0	xs
	goyes	*+3
	c=0	m
	c=0	x
	a(p)=	4
	a(p)=	5
	a(p)=	7
	a(p)=	3
	a(p)=	0
	a(p)=	4
	a(p)=	8
	? a>=c	x
	goyes	*+3
	goto	datovf
	c sr	m
	c=c+1	x
	? a>=c	x
	goyes	*-3
	? a>=c	m
	goyes	*+3
datovf	blink
	ac ex
	c=0	wp
	a=0
	ac ex	m
	a sr	m
	gosub	inc
	p=	9
	gosub	day/yr
	p=	4
	gosub	divstp
	p=	6
	gosub	divstp
	gosub	divstp
	? c=0	m
	goyes	ntlpyr
	p=	8
	gosub	inc
	? a#0	p
	goyes	ntlpyr
	ab ex
	a=0
	p=	9
	a(p)=	6
	p=	9
	? a>=b
	goyes	add30
	a(p)=	3
	a(p)=	1
	goto	month
ntlpyr	a=0	wp
	ab ex
	a=0
	p=	9
	a(p)=	5
	a(p)=	9
	p=	9
	? a>=b
	goyes	add30
	a(p)=	3
	a(p)=	2
	goto	month
add30	a(p)=	3
	a(p)=	0
month	a=a+b
	p=	10
	ab ex
	a=0
	a(p)=	3
	a(p)=	0
	a(p)=	5
	a(p)=	6
	ab ex
	p=	8
	gosub	divstp
	gosub	divstp
	p=	10
	gosub	inc
	a sr
	p=	8
	ac ex	wp
	ac ex	s
	ac ex
	? s14=	0
	goyes	ret
	s14=	0
	goromd	0
	goto	cnvex
day/yr	ab ex
	a(p)=	3
	a(p)=	6
	a(p)=	5
	a(p)=	2
	a(p)=	5
	ab ex
	return
inc	ab ex
	a=0
	a(p)=	1
	a=a+b
ret	return
	c=c+1	p
divstp	a=a-b	ms
	gonc	*-2
	a=a+b	ms
	p=p-1
	a sl	ms
	return
dectim	a(p)=	4
	? c#0	xs
	goyes	notovf
	? a>=c	x
	goyes	notovf
timovf	a=a-1	m
	p=	3
	a=0	p
	ac ex	s
	ac ex
	a=c	x
	blink
notovf	bc ex
	c=0
	a=a-b	x
	p=	4
	c=b	m
	c sr
ptrlp	a=a-1	x
	gonc	ptrpos
	gosub	thms
	p=p-1
	p=p-1
cnvsec	gosub	thms
	a=0
	p=	0
	a(p)=	3
	a=a-b	x
	? a#0	xs
	goyes	*+2
	goto	xschk
	ac ex
	a sl
	ac ex
	a=0
xschk	? b=0	xs
	goyes	*+2
	a=a-1	x
align	a=a-1	x
	gonc	alinlp
	p=	11
	a(p)=	4
	a=a-b	s
	? a#0	s
	goyes	*+2
	goto	*+4
	a=a+1	s
	a=a+1	s
	gonc	tody
	a=0
	? b=0	xs
	goyes	hms1
	c sr
	goto	hms1
tody	a=0
	? b=0	xs
	goyes	hmchk
	p=	0
	a=c	p
	c=a+c
	c sr
secrnd	p=	3
	gosub	hmsrnd
	goto	minrnd
ptrpos	p=p+1
	? p#	11
	goyes	ptrlp
	gosub	thms
	goto	cnvsec
thms	a=c	wp
	c sr	wp
	c=c+c	wp
	c=c+c	wp
	c=a-c	wp
	return
alinlp	c sr
	? c#0
	goyes	align
	goto	texit
nohmov	c=0	wp
	goto	texit
hmchk	p=	7
	ac ex	wp
	? c=0
	goyes	hms
	ac ex	wp
	p=	3
	a=0
	a(p)=	3
	p=p+1
	? a>=c	p
	goyes	nohmov
	c=0	wp
	gosub	hmsinc
minrnd	gosub	hmsrnd
texit	bc ex	s
	? b=0	s
	goyes	ret
	a=0
	goto	timovf
hms	ac ex	wp
hms1	p=	1
	a=c	p
	c=a+c
	c=0	wp
	goto	secrnd
hmsrnd	a=0
	a(p)=	5
	p=p+1
	? a>=c	p
	goyes	ret
	c=0	p
hmsinc	p=p+1
	a=0
	a=a+1	p
	c=a+c
	p=p+1
	return
	fillto	end
	end

	file	cri4

	entry	todec
	entry	datdec
	entry	timdec
	entry	norm
	entry	mltstp

todec	a=c	s
	? a#0	s
	goyes	*+2
	return
	a=a+1	s
	gonc	*+2
	return
	a=a-1	s
	a=a+c	s
	gonc	timdec
datdec	p=	6
	c sr	wp
	p=	3
	? c=0	p
	goyes	*+3
	p=	6
	c=c+1	p
	a=0
	p=	7
	a(p)=	3
	a=a-1
	p=	8
	? a>=c	wp
	goyes	janfeb
	a=0
	p=	7
	a(p)=	1
	p=	4
	a(p)=	1
	goto	*+4
janfeb	a=0
	a(p)=	1
	a(p)=	3
	c=a+c
	a=0
	b=0
	p=	10
	gosub	day/yr
	p=	4
	gosub	mltstp
	gosub	mltstp
	gosub	mltstp
	? a#0
	goyes	*+2
	goto	*+4
	a=a-1
	p=	5
	a=0	wp
	ab ex
	a=0
	p=	6
	a(p)=	3
	a(p)=	0
	a(p)=	6
	ab ex
	a=0
	p=	6
	a(p)=	4
	a(p)=	2
	a(p)=	9
	ab ex
	a=a-b
	a sl
	a sl
	c sr	m
	c sr	m
	c sr	m
	p=	5
	a=0	wp
	c=0	wp
	a=a+c	m
	p=	0
	a(p)=	4
	ac ex	x
	gosub	norm
	? s14=	0
	goyes	ret
	goromd	3
	gotox	decto
day/yr	goromd	3
	gotx	day/yr
mltstp	a sr
	goto	*+2
	a=a+b
	c=c-1	p
	gonc	*-2
	p=p+1
ret	return
timdec	p=	10
	? c#0	wp
	goyes	*+2
	return
	a=0	wp
	p=	0
	a(p)=	5
	ac ex	m
	ac ex	x
	p=	2
ptrlp	p=p+1
	c=c-1	x
	a sl
	? a#0	s
	goyes	cnvrt
	? p#	8
	goyes	ptrlp
cnvrt	a sr
	bc ex	x
	ac ex	m
	c=0	x
	gosub	thms
	gosub	thrs
	p=p+1
	p=p+1
	c=a+c	wp
	gosub	thms
	gosub	thrs
	a=a+c
	bc ex	x
	gosub	norm
	return
thms	goromd	3
	gotox	thms
thrs	a=a+c	wp
	c sr	wp
	? c#0	wp
	goyes	*-3
	return
norm	p=	10
	? a#0	wp
	goyes	normlp
	c=0	m
	c=0	x
	return
	a sl
	c=c-1	x
normlp	? a#0	p
	goyes	*+2
	goto	*-4
	b=0
	a=0	s
	p=	3
	b=a	wp
	a=a+b
	a=0	wp
	? a#0	s
	goyes	*+2
	goto	*+3
	a sr
	c=c+1	x
	ac ex	m
	return
	fillto	end
	end

	file	cri5
	entry	fcns
	entry	opfcns
	entry	->t
	entry	am
	entry	pm
	entry	exit
	entry	alexit
	entry	align

fmtchg	a=c	s
	a=a+c	s
	gonc	tmofdy
	? a#0	s
	goyes	rsta
datchg	gosub	cnvint
	? s2=	0
	goyes	*+3
	s2=	0
	goto	cnvdsp
	s2=	1
	goto	cnvdsp
tmofdy	p=	11
	a(p)=	2
	? a>=c	s
	goyes	rsta
timchg	? s1=	0
	goyes	*+3
	s1=	0
	goto	cnvdsp
	s1=	1
	goto	cnvdsp
fcns	? p#	1
	goyes	ret
	? a#0	xs
	goyes	fmtchg
	s4=	1
	goto	*+4
opfcns	a=a-1	x
	gonc	21chk
	s4=	0
	a=c	s
	a=a+c	s
	gonc	rsta
	? a#0	s
	goyes	rsta
	gosub	cnvint
	gosub	datdec
	gosub	align
	p=	6
	gosub	inc
	p=	10
	? s4=	0
	doyes	dy
dw	ab ex
	a=0
	a(p)=	7
	ab ex
	gosub	divstp
	? p#	4
	goyes	*-2
	a sr
	? a#0	m
	goyes	*+2
	a=a+b
	ac ex
exit	s8-15=	0
alexit	s8=	1
	s15=	1
	goto	cnvdsp
align	a=0
	p=	0
	a(p)=	4
	a=a-c	x
	a=c	m
	goto	*+3
	a sr	m
	a=a-1	x
	? a#0	x
	goyes	*-3
ret	return
dy	c=0
	c=c+1	x
	c=c+1	x
	gosub	day/yr
	gosub	divstp
	gosub	divstp
	gosub	divstp
	p=	8
	a sr
	? c=0	m
	goyes	*+2
	gosub	inc
	p=	7
	a=0	wp
	gosub	norm
	goto	exit
21chk	a=a-1	x
	gonc	exchk
21	a=c	s
	a=a+c	s
	gonc	rsta
	? a#0	s
	goyes	rsta
	? s15=	0
	goyes	*+2
	goto	rsta
	gosub	cnvint
	p=	4
	c=c+1	p
	legal
	goto	cnvdsp
exchk	a=a-1	x
	gonc	cs
exch	gsoub	cnvint
	cd ex
	goto	exit
cs	p=	11
	a(p)=	7
	? a>=c	s
	goyes	plus
chs	? s15=	0
	goyes	*+3
	? c=0	wp
	goyes	*+2
	c=-c-1	s
	gosub	sign
	dsp=a
modex	? s15=	0
	goyes	keyex
cnvdsp	goromd	1
	gotox	cnvdsp
plus	p=	11
	a(p)=	2
	a=a-c	s
	gonc	swchk
rsta	a=dsp
keyex	p=	2
	a=0	x
getkey	goromd	0
	gotox	getkey
swchk	? a#0	s
	goyes	chs
	a=sw
	a=a+1	s
	ac ex
	goto	chs
->t	a=c	s
	a=a+c	s
	gonc	*+4
	? a#0	s
	goyes	*+2
	goto	rsta
	gosub	cnvint
	? c#0	s
	goyes	*+3
	c=c+1	s
	legal
	goto	tohms
	a=c	s
	a=a+1	s
	gonc	*+3
	c=c-1	s
tohms	gosub	decto
	a=c	s
	a=a+c	s
	gonc	*+2
	goto	exit
	c=0	s
	c=c+1	s
	legal
	goto	exit
am	dspoff
	s4=	1
	goto	ap
pm	dspoff
	? s4=0
	goyes	ap
t->	? c=0	s
	goyes	getkey
	a=c	s
	a=a+1	s
	gonc	*+2
	goto	rsta
	a=c	s
	a=a+c	s
	? a#0	s
	goyes	*+2
	goto	rsta
	gosub	cnvint
	gosub	timdec
	a=c	s
	a=a+c	s
	gonc	*+3
	c=c+1	s
	legal
	goto	exit
	c=0	s
	goto	exit
ap	gosub	timchk
	? s7=	0
	goyes	rsta
	? s1=	0
	goyes	*+2
	goto	*+3
	? s15=	0
	goyes	*+3
	gosub	cnvint
	goto	mod24
	gosub	cnvint
	c=c+c	s
	gonc	*+2
	goto	mod24
	c=0	s
	p=	7
	a(p)=	1
	a(p)=	2
	bc ex	wp
	? s4=	0
	goyes	pmchk
amchk	a=a-c	m
	? a#0	m
	goyes	*+2
	c=0	m
fixtim	bc ex	wp
mod24	gosub	timmod
	p=	11
	a(p)=	4
	ac ex
	goto	exit
pmchk	? c#0	m
	goyes	*+2
	goto	fixtim
	a=a-1	m
	? a>=c	m
	goyes	*+2
	goto	fixtim
	a=a+1	m
	c=a+c	m
	legal
	goto	fixtim
gimchk	goromd	6
	gotox	timchk
timmod	goromd	6
	gotox	timmod
inc	goromd	3
	gotox	inc
datdec	goromd	4
	gotox	datdec
timdec	goromd	4
	gotox	timdec
decto	goromd	3
	gotox	decto
divstp	goromd	3
	gotox	divstp
day/yr	goromd	3
	gotox	day/yr
norm	goromd	4
	gotox	norm
cnvint	goromd	0
	gotox	cnvint
sign	goromd	1
	gotox	sign
	fillto	end
	end

	file	cri6
	entry	memory
	entry	retmem
	entry	stwtch
	entry	retsw
	entry	date
	entry	retdat
	entry	alarm
	entry	retal
	entry	time
	entry	rettim
	entry	rcltim
	entry	timmod
	entry	timchk
	entry	error
	entry	swsprs

memory	dspoff
	? s4=	0
	goyes	rclmem
	? s6=	0
	goyes	stomem
	s7=	0
	s9=	1
eqops	goromd	7
	gotox	eqops
stomem	gosub	cnvint
retmem	a=c	s
	a=a-1	s
	a=a-1	s
	a=a-1	s
	gonc	*+3
	c=c-1	s
	legal
	goto	*+4
	a=a-1	s
	gonc	*+2
	c=c+1	s
	m=c
rclmem	c=m
exit	goromd	5
	gotox	exit
stwtch	dspoff
	? s4=	0
	goyes	onchk
	? s6=	0
	goyes	stosw
	s7=	0
	s9=	1
	s11=	1
	goto	eqops
stosw	gosub	cnvint
retsw	p=	11
	a(p)=	4
	? a>=c	s
	goyes	timint
fixerr	ac ex	wp
error	blink
cnvdsp	goromd	1
	gotox	cnvdsp
timint	? c=0
	goyes	*+3
	? c=0	s
	goyes	error
	a=0
	p=	7
	ac ex	wp
	? c#0	m
	goyes	fixerr
	a=a+c	m
	swstop
	s3=	0
	? a#0
	goyes	*+3
	sw+
	goto	*-2
	sw-
	sw=a
swex	c=0	s
	c=c+1	s
	c=c+1	s
	legal
	goto	exit
onchk	c=c-1	s
	c=c-1	s
	c=c-1	s
	gonc	swex
	? s3=	0
	goyes	*+4
	swstop
	s3=	0
	goto	swex
	swstrt
	s3=	1
	goto	swex
date	dspoff
	? s4=	0
	goyes	rcldat
	? s6=	0
	goyes	stodat
	s7=	0
	s11=	1
	s12=	1
	goto	eqops
stodat	gosub	cnvint
retdat	p=	11
	a(p)=	5
	a=a-c	s
	? a#0	s
	goyes	error
	gosub	datdec
	gosub	align
	ac ex
	a=cl
	p=	5
	ac ex
	ac ex	wp
	cl=a
	nop
rcldat	a=0
	p=	0
	a(p)=	4
	a(p)=	5
	ac ex
	p=	5
	s14=	0
	a=cl
	cl=a
	a=0	wp
	ac ex	m
	gosub	decto
	goto	exit
alarm	dspoff
	? s4=	0
	goyes	rclal
	? s6=	0
	goyes	stoal
	s7=	0
	s11=	1
	goto	eqops
stoal	gosub	snvint
retal	gosub	timchk
	? s7=	0
	goyes	error
	gosub	timmod
	a sr
	a sr
	? s13=	0
	goyes	*+3
	altog
	goto	*+2
	al=a
rclal	a=al
	a sl
	a sl
	p=	11
	a(p)=	4
	ac ex
	s8-15=	0
	s3=	1
	goromd	5
	gotox	alexit
time	dspoff
	? s4=	0
	goyes	rcltim
	? s6=	0
	goyes	stotim
	goromd	8
	gotox	tupdat
stotim	gosub	cnvint
rettim	gosub	timchk
	? s7=	0
	goyes	error
	gosub	timmod
	a sr
	a sr
	ac ex
	p=	5
	a=cl
	ac ex	wp
	clrs=a
rcltim	p=	11
	a(p)=	3
	ac ex	s
	goto	exit
timmod	a=0
	b=0
	bc ex
	p=	10
	a(p)=	2
	a(p)=	4
	ab ex
	p=	9
	goto	*+2
	c=c+1	p
modlp	a=a-b	m
	gonc	*-2
	a=a+b	m
	p=p-1
	b sr
	? p#	5
	goyes	modlp
	p=	10
	? a#0	wp
	goyes	*+2
	return
	b=a	s
	a=a+b	b
	gonc	ret
	b=0	s
	a=0	s
	a sr
	p=	0
	a=0	p
	ab ex
	p=	4
	? b=0	wp
	goyes	24comp
	p=	5
	a(p)=	3
	a(p)=	6
	? b=0	x
	goyes	24comp
	a=a-1	m
	p=	2
	a(p)=	6
24comp	a=a-b
	a sl
	c=-c-1
ret	return
timchk	s7=	1
	a=c	s
	a=a+c	s
	? a#0	s
	goyes	*+3
notim	s7=	0
	return
	a=c	s
	a=a+1	s
	gonc	*-3
	goto	notim
swsprs	? s3=	0
	goyes	*+5
	a=sw
	a=a+1	s
	sc ex
	goto	cnvdsp
	a=0
	sw=a
	sw+
	goto	cnvdsp
cnvint	goromd	0
	gotox	cnvint
datdec	goromd	4
	gotox	datdec
align	goromd	5
	gotox	align
decto	goromd	3
	gotox	decto
	fillto	end
	end

	file	cri7

	entry	equals
	entry	oprtrs
	entry	opret
	entry	eqops
	entry	opset

equals	dspoff
	? s4=	0
	goyes	*+3
	goromd	5
	gotox	->t
	s7=	0
	goto	eqops
oprtrs	dspoff
	? s4=	0
	goyes	*+3
	goromd	5
	gotox	opfcns
	s7=	1
eqops	dsp=a
	gosub	cnvint
	cd ex
	gosub	cnvint
	cd ex
	a=dsp
	? s7=	0
	goyes	eqop1
	? s6=	0
	goyes	*+4
	? s8=	0
	goyes	*+4
	goto	eqop2
	cd ex
	c=d
	p=	0
	f=a(p)
	goto	opex
eqop1	? s6=	0
	goyes	*+2
eqop2	cd ex
	bc ex
	c=d
	a=0	ms
	a sl	x
	a sl	x
	p=	0
	a(p)=f
	s10=	1
	s4=	0
matlp	p=	11
	a=c	s
	a=a+c	s
gonc	nocry
	? a#0	s
	goyes	*+2
	goto	toddat
	a=a+1	s
	a=a+1	s
	gonc	ti
dec	a(p)=	3
	goto	shift
ti	a(p)=	2
	goto	shift
nocry	a=a-1	s
	gonc	*+2
	goto	dec
	a=a+c	s
	gonc	*+2
	goto	toddat
	a=a+c	s
	gonc	ti
toddat	p=	10
shift	bc ex
	? s10=	0
	goyes	mat
	s10=	0
	a sr	ms
	p=p-1
	? p#	2
	goyes	*-3
	goto	matlp
mat	p=	0
	a=a-1	p
	gonc	minus
plmick	a=a-1	m
	gonc	twotod
	? a#0	p
	goyes	*+4
	a=a-1	s
	gonc	errex
	goto	decex
	a=a-1	s
	a=a-1	s
	a=a-1	s
	a=a-1	s
	gonc	errex
	goto	datex
twotod	a=a-1	m
	gonc	onedat
	a=a-1	s
	gonc	*+2
	goto	errex
	? a#0	p
	goyes	*+2
	goto	tiex
	a=a-1	s
	gonc	todex
errex	bc ex
	? s=	0
	goyes	error
	cd ex
	bc ex
error	goromd	6
	gotox	error
onedat	a=a-1	s
	gonc	*+4
	a=a-1	m
	gonc	datex
	goto	errex
	a=a-1	s
	gonc	*+3
todex	s10=	1
	goto	tiex
	a=a-1	s
	gonc	*+2
	goto	tiex
	a=a-1	m
	gonc	decex
tiex	s4=	1
	goto	decex
minus	? a#0	p
	goyes	*+2
	goto	plmick
	p=	11
muldiv	a=a-1	p
	gonc	*+2
	goto	errex
	a=a-1	p
	gonc	*+2
	goto	errex
	? p#	11
	goyes	*+3
	p=	3
	goto	muldiv
	? s3=	0
	goyes	decex
	p=	11
	a(p)=	2
	a=a-b	s
	? a#0	s
	goyes	decex
	a=a-1	m
	a=a-1	m
	gonc	decex
	s9=	1
	s11=	1
	s12=	1
	goto	decex
datex	s10=	1
decex	gosub	opset
	ab ex
	dsp=a
	gosub	todec
	a=dsp
	ac ex
	dsp=a
	gosub	todec
	a=dsp
	ac ex
	ab ex
	goromd	8
	gotox	operat
opret	s6=	0
	gosub	decto
	? s10=	0
	goyes	modret
	? s4=0
	goyes	modret
	gosub	timmod
	p=	11
	a(p)=	4
	ac ex
modret	? s12=	0
	goyes	nmas
	? s11=	0
	goyes	timret
	? s9=	0
	goyes	*+2
	goto	cnvdsp
	goromd	6
	gotox	retdat
timret	? s9=	0
	goyes	rettim
	ab ex
	a=cl
	p=	5
	b=0	wp
	a=a+b
	c sr
	c sr
	ac ex	wp
	cl=a
;			finish
	goromd	6
	gotox	rcltim
rettim	goromd	6
	gotox	rettim
nmas	? s11=	0
	goyes	nomem
	? s9=	0
	goyes	*+3
	goromd	6
	gotox	retsw
	goromd	6
	gotox	retal
nomem	? s9=	0
	goyes	*+3
	goromd	6
	gotox	retmem
eqopex	? s7=	0
	goyes	*+4
	cd ex
	c=d
opex	s6=	1
	s8-15=	0
	s15=	1
cnvdsp	goromd	1
	gotox	cnvdsp
opset	p=	0
	a(p)=f
	? s7=	0
	goyes	*+3
	p=	2
	f=a(p)
	p=	0
	s6=	0
	s8=	0
	a=a-1	p
	gonc	*+2
	return
	a=a-1	p
	gonc	*+2
	goto	ctone
	s8=	1
	a=a-1	p
	gonc	*+2
	return
ctone	s6=	1
	return
cnvint	goromd	0
	gotox	cnvint
todec	goromd	4
	gotox	todec
decto	goromd	3
	gotox	decto
norm	goromd	4
	gotox	norm
timmod	goromd	6
	gotox	timmod
	fillto	end
	end

	file	cri8

	entry	operat
	entry	swcalc
	entry	tupdat

nowup	a=dsp
	dsscwp
	goromd	0
	gotox	keyrel
swcalc	? s9=	0
	goyes	nowup
	? s11=	0
	goyes	nowup
	? s12=	0
	goyes	nowup
	a=sw
	a=a+1	s
	ac ex
	gosub	todec
	s10=	0
	s4=	0
	a=0
	b=0
	gosub	opset
	bc ex
	c=d
operat	p=	0
	? s8=	0
	goyes	plsmin
	? s6=	0
	goyes	mul
zrchk	? c#0	m
	goyes	div
	a(p)=	3
	p=	0
	f=a(p)
	bc ex
	gosub	decto
	cd ex
	s6=	1
	s8=	1
error	goromd	6
	gotox	error
div	gosub	fixsgn
	c=a-c	x
	c=a+c	s
	gonc	*+2
	c=0	s
	bc ex	wp
	a=0	s
	gosub	divstp
	? p#	0
	goyes	*-2
	a=c
	bc ex	x
	goto	opex
mul	gosub	fixsgn
	c=a+c	x
	c=a+c	s
	gonc	*+2
	c=0	s
	p=	3
	ab ex	m
	a=0
	gosub	mltstp
	? p#	11
	goyes	*-2
	c=c+1	x
	a sr
	goto	opex
plsmin	gosub	fixsgn
	? s6=	0
	goyes	add
sub	c=-c-1	s
add	a=a+1	xs
	c=c+1	xs
	? a>=c	x
	goyes	*+2
	ac ex
	ac ex	m
	? c=0	m
	goyes	*+2
	ac ex
	bc ex	m
eqlexp	? a>=c	x
	goyes	fixexp
	b sr
	a=a+1	x
	? b=0
	goyes	*+2
	goto	eqlexp
fixexp	c=c-1	xs
	a=0	x
	a=a-c	s
	? a#0	s
	goyes	diff
	a=a+b
	c=c+1	x
	a sr
	goto	opex
diff	? a>=b	m
	goyes	*+3
	c=-c-1	s
	ab ex
	b=0	s
	a=a-b
opex	gosub	norm
	? c#0	m
	goyes	*+2
	c=0
	a=0
	p=	2
	a(p)=	5
	a=a-1	x
	? a>=c	x
	goyes	oflchk
	a=0
	a=a-1	xs
	? a>=c	x
	goyes	zrres
	goto	result
mntovf	? a>=c	m
	goyes	result
	goto	oflow
oflchk	a=0	xs
	a=a-1	m
	p=	6
	a(p)=	4
	a=a-1	x
	? a>=c	x
	goyes	result
	a=a+1	x
	? a>=c	x
	goyes	mntovf
oflow	ac ex	x
	ac ex	m
	blink
	goto	result
zrres	c=0
result	? s10=0
	goyes	decti
	p=	11
	a(p)=	5
	ac ex	s
	? s4=	0
	goyes	opret
	? a#0	s
	goyes	inc
	goto	dec
decti	? s4=	0
	goyes	opret
	? c=0	s
	goyes	*+3
dec	c=c-1	s
	legal
	goto	opret
inc	c=c+1	s
opret	goromd	7
	gotox	opret
fixlp	p=	10
fixsgn	c=c+c	s
	gonc	*+3
	? c#0	s
	goyes	*+3
	c=0	s
	goto	*+3
	c=0	s
	c=c-1	s
	bc ex	s
	? p#	10
	goyes	fixlp
	a=0
	ab ex
	return
tupdat	gosub	cnvint
	s7=	0
	goto	dtloop
exchk	? s7=	0
	goyes	noex
	goto	normeq
nrmeq1	cd ex
normeq	s7=	0
	s12=	1
	goromd	7
	gotox	eqops
noex	s7=	1
	cd ex
dtloop	p=	11
	a(p)=	2
	? a>=c	s
	goyes	yexit
	p=	11
	a(p)=	7
	? a>=c	s
	goyes	exchk
yexit	? s7=	0
	goyes	*+3
	s7=	0
	cd ex
	p=	11
	a(p)=	3
	a=a-c	s
	? a#0	s
	goyes	stchk
	a(p)=f
	? a#0	p
	goyes	normeq
	cd ex
ctdec	gosub	todec
	ac ex
	dsp=a
	c=0
	p=	7
	a=cl		start
	a sl
	a sl
	ac ex	wp
	gosub	timdec
	bc ex
	a=dsp
	ac ex
	gosub	opset
	s10=	1
	s4=	1
	s12=	1
	s9=	1
	goto	operat
stchk	cd ex
	p=	11
	a(p)=	3
	a=a-c	s
	? a#0	s
	goyes	nrmeq1
	a(p)=f
	a=a-1	p
	gonc	*+2
	goto	*+3
	a=a-1	p
	gonc	nrmeq1
	c=d
	goto	ctdec
todec	goromd	4
	gotox	todec
decto	goromd	3
	gotox	decto
divstp	goromd	3
	gotox	divstp
mltstp	goromd	4
	gotox	mltstp
norm	goromd	4
	gotox	norm
opset	goromd	7
	gotox	opset
cnvint	goromd	0
	gotox	cnvint
timdec	goromd	4
	gotox	timdec
	fillto	end
	end

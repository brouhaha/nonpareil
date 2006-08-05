; 21 ROM source code reconstructed from disassembly
; Copyright 2005, 2006 Eric L. Smith <eric@brouhaha.com>
; $Id$
;
; Verified to match 21 ROM/anode driver part number 1818-0129

; s 2 = stack lift enabled
; s 3 = radian angle mode (hardware switch)
; s 5 = power
; s 9 = dp hit
; s 13 = shift key
; s 14 = exponent entry

	.arch woodstock

	.rom 0

	a + 1 -> a[w]
	a + 1 -> a[w]
	f exchange a[x]
	m1 exchange c
$kclx:	0 -> c[w]
L0005:	0 -> s 2
L0006:	clear status
L0007:	display off
	jsb $ovrf3
	if c[m] # 0
	  then go to L0014
	0 -> c[w]
L0014:	0 -> b[w]
	jsb L0111
	f -> a[x]
	if 0 = s 1
	  then go to fix1
	jsb round
sci1:	a - 1 -> a[xs]
	if a[xs] # 0
	  then go to sci2
	c -> a[w]
	go to sci4

L0027:	0 -> a[wp]
L0030:	jsb $dmeex
	jsb $getkey
	p <- 1
	shift left a[wp]
	p <- 3
	shift left a[wp]
deeex4:	p <- 4
	shift right a[wp]
	shift right a[wp]
	a exchange c[w]
	c -> a[x]
	if c[xs] = 0
	  then go to L0047
	0 -> c[xs]
	0 - c -> c[x]
L0047:	jsb L0276
	a exchange c[ms]
	p <- 4
	jsb $ovrf3
	if p = 12
	  then go to L0006
	go to L0030

$errmsg:
	jsb $err5
	a exchange c[w]
	load constant 14			; E
	load constant 10			; r
	load constant 10			; r
	load constant 12			; o
	load constant 10			; r
	a exchange c[w]
	0 -> b[m]
	clear status
	go to outpu2

dige4:	if 1 = s 9
	  then go to dige5
	shift right b[m]
	go to dige5

fix9:	jsb zappo
	a exchange b[x]
	go to fix6

push:	if 0 = s 2
	  then go to push1
	c -> stack
push1:	1 -> s 2
$err5:	0 -> c[w]
	p <- 12
	jsb zappo
	0 -> a[s]
	a -> b[w]
L0111:	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	a + 1 -> a[s]
	a + 1 -> a[s]
	a exchange b[w]
	return

fix1:	a + c -> a[x]
	jsb round
	if a[xs] # 0
	  then go to fix2
	jsb zappo
	a exchange b[x]
	p <- 1
	if a[p] # 0
	  then go to fix8
fix4:	a - 1 -> a[x]
	if n/c go to fix5
fix6:	0 -> a[x]
	a exchange b[x]
outpu2:	0 -> s 5
	if 0 = s 5
	  then go to $outp3a
$L0140:	jsb L0364
	jsb push
L0142:	if 1 = s 14
	  then go to L0334
	jsb wait2
	binary
	p <- 1
dige2:	a + 1 -> a[p]
	if n/c go to dige3
	shift left a[wp]
	p + 1 -> p
	if p # 13
	  then go to dige2
dige5:	p - 1 -> p
dige6:	p - 1 -> p
	a exchange c[w]
	c -> a[w]
	c - 1 -> c[wp]
	a exchange c[x]
	decimal
	if a[m] # 0
	  then go to dige7
	0 -> a[ms]
dige8:	a exchange c[ms]
L0170:	0 -> s 14
	jsb $getkey
	if p = 2
	  then go to L0170
	go to L0142

round4:	if p = 2
	  then go to round2
	p - 1 -> p
rounda:	a - 1 -> a[x]
	if n/c go to round4
	go to round2

round:	p <- 12
	a + 1 -> a[x]
	if n/c go to rounda
round2:	0 -> a[w]
	c -> a[wp]
	a + c -> a[m]
	if n/c go to round3
	a + 1 -> a[s]
	shift right a[ms]
	a + 1 -> a[x]
	if 1 = s 1
	  then go to round3
	p - 1 -> p
round3:	a -> b[x]
	return

kdsp:	0 -> s 9
L0223:	jsb $getkey
	if p = 2
	  then go to L0223
	0 -> s 1
	if 1 = s 9
	  then go to L0232
	1 -> s 1
L0232:	f exchange a[x]
	go to L0006

dige3:	a - 1 -> a[p]
L0235:	if p # 3
	  then go to dige4
	1 -> s 9
	0 -> a[x]
	go to dige6

fix2:	shift right a[m]
	a + 1 -> a[x]
	if n/c go to fix2
	0 -> a[x]
	f -> a[x]
	p <- 12
fix3:	p - 1 -> p
	a - 1 -> a[x]
	if n/c go to fix3
	0 -> a[wp]
	if a[m] # 0
	  then go to fix9
fix8:	p <- 4
	jsb round2
	go to sci1

kshift:	clear status
	1 -> s 13
	go to L0007

sci2:	jsb zappo
	a exchange b[x]
	a exchange c[x]
	if c[xs] = 0
	  then go to sci3
	0 - c -> c[x]
	c - 1 -> c[xs]
sci3:	a exchange c[x]
sci4:	jsb $dmeex
	go to outpu2

L0276:	p <- 13
L0277:	p - 1 -> p
	c + 1 -> c[x]
	if b[p] = 0
	  then go to L0277
	p <- 12
L0304:	c - 1 -> c[x]
	if c[p] # 0
	  then go to L0320
	p - 1 -> p
	if 1 = s 14
	  then go to L0304
	shift left a[m]
	go to L0304

zappo:	0 -> a[wp]		; f you routine
	binary
	a - 1 -> a[wp]
	decimal
L0320:	return

fix5:	shift right b[m]
	go to fix4

kchs:	if 1 = s 13
	  then go to $ksqrt
	if 0 = s 14
	  then go to L0362
	p <- 4
	a exchange c[p]
	0 - c - 1 -> c[p]
	a exchange c[p]
	go to deeex4

L0334:	if c[m] # 0
	 then go to L0341
	jsb $err5
	c + 1 -> c[p]
	c -> a[p]
L0341:	p <- 4
	if b[wp] = 0
	  then go to L0027
	go to L0170

dige7:	jsb L0276
	go to dige8

$ovrf3:	select rom 01	; go to overf3

	nop

$dmeex:	p <- 4			; make mask and move exp over
	shift left a[wp]
	shift left a[wp]
	0 -> b[wp]
	a exchange b[p]
	a + 1 -> a[p]
	a + 1 -> a[p]
	a exchange b[p]
	return

L0362:	0 - c - 1 -> c[s]
$getkey:	0 -> s 13
L0364:	c -> a[s]
	display toggle
$wait:	0 -> s 15
	p <- 7
wait1:	p - 1 -> p
	if p # 0
	  then go to wait1
	if 1 = s 15
	  then go to $wait
	hi i'm woodstock
wait2:	if 0 = s 15
	  then go to wait2

	.rom 1

	display off
	p <- 0
	0 -> a[p]
	keys -> rom address

L0404:	select rom 00	; go to L0005

ksin:	1 -> s 6
ktan:	0 -> s 3
	jsb $nrm25
	if 0 = s 13
	  then go to $L1622
	if 0 = s 6
	  then go to $atan
	0 - c - 1 -> c[s]
	a exchange c[s]
	select rom 03	; go to $asin

krdn:	if 1 = s 13
	  then go to kr-p
	down rotate
	go to $retrn

k.:	1 -> s 9
	p <- 2
	return

keex:	if 1 = s 13
	  then go to kpi
	1 -> s 14
	return

L0432:	stack -> a
L0433:	c -> stack
	a exchange c[w]
	return

$trig3:	if 0 = s 7
	  then go to $retrn
	0 -> a[w]
	a + 1 -> a[p]
	if c[m] = 0
	  then go to L0703
	m2 exchange c
	jsb L0734
	m2 -> c
	jsb $mpy21
	jsb overf3
	go to L0705

$add3:	p <- 12
	0 -> b[w]
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a >= c[x]
	  then go to add4
	a exchange c[w]
add4:	a exchange c[m]
	if c[m] = 0
	  then go to add5
	a exchange c[w]
add5:	b exchange c[m]
add6:	if a >= c[x]
	  then go to $add1
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	  then go to $add1
	go to add6

$push:	select rom 00	; go to push

k25:	go to krcl		; RCL/10^x
k24:	go to klog		; STO/LOG
k23:	go to L0773		; e^x/LN
k22:	go to krdn		; RDN/->P

k21:	if 0 = s 13
	  then go to $kxexy	; x<>y/->R
	jsb $nrm25
	1 -> s 7
	0 -> s 13
	jsb L0432
	go to kcos

L0513:	p <- 12
	c + c -> c[xs]
	if n/c go to L0554
	0 -> c[w]
	return

$$sqrt: select rom 03	; go to $sqrt

atc11:	0 -> c[w]
	p <- 11
	load constant 7
	load constant 8
	load constant 5
	load constant 3
	load constant 9
	load constant 8
	load constant 1
	load constant 6
	load constant 3
	load constant 5
	p <- 12
	return

$kxexy:	jsb L0432
	go to $retrn

k44:	a + 1 -> a[p]			; 9
k43:	a + 1 -> a[p]			; 8
k42:	go to krow5			; 7 - always taken

k41:	jsb L0760			; -
	0 - c - 1 -> c[s]
L0546:	jsb $add3
L0547:	if 0 = s 13
	  then go to $retrn
	jsb overf3
	m1 exchange c
	go to $retrn

L0554:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	return

krow6:	a + 1 -> a[p]
k64:	a + 1 -> a[p]		; 3
k63:	a + 1 -> a[p]		; 2
k62:	go to kdigit		; 1 - always taken

k61:	jsb L0760		; *
	jsb $mpy21
	go to L0547

kr-p:	1 -> s 7
	if c[s] = 0
	  then go to L0573
	1 -> s 4
L0573:	m2 exchange c
	m2 -> c
	y -> a
	if a[m] # 0
	  then go to L0602
	if c[m] = 0
	  then go to $retrn
L0602:	p <- 12
	jsb L0734
	jsb overf3
	m2 exchange c
	jsb L0732
	jsb L0432
	jsb L0732
	stack -> a
	jsb $add3
	a - 1 -> a[xs]
	a - 1 -> a[xs]
	if a[xs] # 0
	  then go to $ksqrt
	jsb overf3
	go to L0700

k74:	select rom 00	; go to kdsp

k73:	go to k.

k72:	return			; 0

k71:	p <- 12			; /
	jsb L0760
	go to L0671

kpi:	jsb $push
	jsb atc11
	c + c -> c[w]
	c + c -> c[w]
$retrn:	1 -> s 2
	delayed rom 00	; go to L0235

	go to ktan

ksto:	m1 exchange c
	go to krcl2

krow5:	a + 1 -> a[p]
k54:	a + 1 -> a[p]		; 6
k53:	a + 1 -> a[p]		; 5
k52:	go to krow6		; 4 - always taken

k51:	jsb L0760		; +
	go to L0546

krcl:	1 -> s 8
	if 1 = s 13
	  then go to $10tox
	jsb $push
krcl2:	m1 -> c
	go to $retrn

kclr:	if 0 = s 13
	  then go to $kclx
	clear regs
	go to $retrn

k15:	select rom 00	; go to kshift

k14:	go to ktan			; tan/tan^-1	

kcos:	1 -> s 10			; cos/cos^-1
k12:	go to ksin			; sin/sin^-1

k11:	if 1 = s 13			; 1/x / y^x
	  then go to kytox
	0 -> a[w]
	p <- 12
	a + 1 -> a[p]
L0671:	1 -> s 8
	jsb L0734
	go to L0547

$ksqrt:	jsb $nrm25
	jsb $$sqrt
	if 0 = s 7
	  then go to $retrn
L0700:	c -> stack
	m2 exchange c
	go to ktan

L0703:	m2 exchange c
	a exchange c[w]
L0705:	y -> a
	jsb $mpy21
	jsb overf3
	if 0 = s 4
	  then go to L0713
	0 - c - 1 -> c[s]
L0713:	stack -> a
	c -> stack
	m2 -> c
	jsb $mpy21
	go to $retrn

k34:	go to kclr			; CLx/CLR
k33:	go to keex			; EEX/pi
k32:	select rom 00	; go to kchs

$nrm25:	select rom 02	; go to nrm25

k31:	if 1 = s 13			; ENTER
	  then go to $getkey
	c -> stack
	go to L0404

kdigit:	a + 1 -> a[p]			
	return

L0732:	c -> a[w]
$mpy21:	select rom 02	; go to mpy21

L0734:	a - c -> c[x]
	select rom 02	; go to div21

$outp3a: p <- 12
outpu3:	b exchange c[p]
	0 - c - 1 -> c[p]
	b exchange c[p]
	p - 1 -> p
	if p = 4
	  then go to $L0140
	go to outpu3

L0746:	stack -> a
	return

overf3:	if c[xs] = 0
	  then go to overf4
	c - 1 -> c[x]
	c + 1 -> c[xs]
	c - 1 -> c[xs]
	if n/c go to L0513
	c + 1 -> c[x]
overf4:	return

L0760:	if 0 = s 13
	  then go to L0746
	m1 exchange c
	c -> a[w]
	m1 -> c
	return

kytox:	jsb L0432
	1 -> s 10
klog:	if 0 = s 13
	  then go to ksto
	1 -> s 6
L0773:	1 -> s 8
	if 0 = s 13
	  then go to $exp21

; the following matches on inst after ln in 25:

	0 -> a[w]
	a - c -> a[m]

	.rom 2
	
	if n/c go to err
	shift right a[w]
	c - 1 -> c[s]
	if n/c go to err
	p <- 12
ln25:	c + 1 -> c[s]
ln26:	a -> b[w]
	jsb eca22
	a - 1 -> a[p]
	if n/c go to ln25
	a exchange b[wp]
	a + b -> a[s]
	if n/c go to ln24
	p <- 7
	jsb pqo23
	p <- 8
	jsb pmu22
	p <- 9
	jsb pmu21
	jsb lncd3
	p <- 10
	jsb pmu21
	jsb lncd2
	p <- 11
	jsb pmu21
	jsb lncd1
	jsb pmu21
	jsb lnc2
	jsb pmu21
	jsb lnc10
	a exchange c[w]
	a - c -> c[w]
	if b[xs] = 0
	  then go to ln27
	a - c -> c[w]
ln27:	a exchange b[w]
ln28:	p - 1 -> p
	shift left a[w]
	if p # 1
	  then go to ln28
	a exchange c[w]
	if c[s] = 0
	  then go to ln29
	0 - c - 1 -> c[m]
ln29:	c + 1 -> c[x]
	p <- 11
	jsb mpy27
	if 1 = s 10
	  then go to xty22
	if 0 = s 6
	  then go to $retrn
	jsb lnc10
	jsb mpy22
	go to retur2

pqo21:	select rom 03	; go to pqo11

pmu21:	shift right a[w]
pmu22:	b exchange c[w]
	go to L1073
	
L1072:	a + b -> a[w]
L1073:	c - 1 -> c[s]
	if n/c go to L1072
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
$pqo23:	go to pqo23

pre21:	a exchange c[w]
	a -> b[w]
	c -> a[m]
	c + c -> c[xs]
	if n/c go to pre24
	c + 1 -> c[xs]
L1107:	shift right a[w]
	c + 1 -> c[x]
	if n/c go to L1107
	go to pre26

$10tox:	jsb ln10b
ytox29:	jsb mpy21
$exp21:	jsb ln10b
	jsb pre21
	jsb lnc2
	p <- 11
	jsb pqo21
	jsb lncd1
	p <- 10
	jsb pqo21
	jsb lncd2
	p <- 9
	jsb pqo21
	jsb lncd3
	p <- 8
	jsb pqo21
	jsb pqo21
	jsb pqo21
	p <- 6
	0 -> a[wp]
	p <- 13
	b exchange c[w]
	a exchange c[w]
	load constant 6
	go to exp23

lncd1:	p <- 9
	load constant 3
	load constant 1
	load constant 0
	load constant 1
	load constant 7
	load constant 9
lnc8:	load constant 8
	load constant 0
	load constant 5
	load constant 5
	if p = 0
	  then go to lncb
	go to nrm27

ln10b:	c -> a[w]
lnc10:	0 -> c[w]
	p <- 12
	load constant 2
	load constant 3
	load constant 0
	load constant 2
	load constant 5
	go to lnc7

ln24:	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to ln26

lncd2:	p <- 7
lnc6:	load constant 3
	load constant 3
	load constant 0
lnc7:	load constant 8
	load constant 5
	load constant 0
	if p = 13
	  then go to lncret
lnca:	load constant 9		; lnca label not used?
lncb:	load constant 3
lncret:	go to nrm27

exp29:	jsb eca22
	a + 1 -> a[p]
exp22:	a -> b[w]
	c - 1 -> c[s]
	if n/c go to exp29
	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
exp23:	a exchange c[w]
	a - 1 -> a[s]
	if n/c go to exp22
	a exchange b[w]
	a + 1 -> a[p]
	jsb $norm
retur2: select rom 01	; go to $retrn

pre23:	if 0 = s 8
	  then go to pre24
	a + 1 -> a[x]
pre29:	if a[xs] # 0
	  then go to pre27
pre24:	a - b -> a[ms]
	if n/c go to pre23
	a + b -> a[ms]
	shift left a[w]
	c - 1 -> c[x]
	if n/c go to pre29
pre25:	shift right a[w]
	0 -> c[wp]
	a exchange c[x]
pre26:	if c[s] = 0
	  then go to pre28
	a exchange b[w]
	a - b -> a[w]
	0 - c - 1 -> c[w]
pre28:	shift right a[w]
pqo23:	b exchange c[w]
	0 -> c[w]
	c - 1 -> c[m]
	if 0 = s 8
	  then go to pqo28
	load constant 4
	c + 1 -> c[m]
	if n/c go to pqo24
pqo27:	load constant 6
pqo28:	if p # 1
	  then go to pqo27
	shift right c[w]
pqo24:	shift right c[w]
	return

mpy26:	a + b -> a[w]
mpy27:	c - 1 -> c[p]
	if n/c go to mpy26
mpy28:	shift right a[w]
	p + 1 -> p
	if p # 13
	  then go to mpy27
	c + 1 -> c[x]
$norm:	0 -> a[s]
	p <- 12
	0 -> b[w]
nrm23:	if a[p] # 0
	  then go to nrm24
	shift left a[w]
	c - 1 -> c[x]
	if a[w] # 0
	  then go to nrm23
	0 -> c[w]
nrm24:	a -> b[x]
	a + b -> a[w]
	if a[s] # 0
	  then go to mpy28
	a exchange c[m]
nrm25:	c -> a[w]
	0 -> b[w]
nrm27:	p <- 12
nrm26:	return		; nrm26 label not used

lncd3:	p <- 5
	go to lnc6

xty22:	stack -> a	; modified from 25
	go to ytox29

mpy21:	p <- 3
mpy22:	a + c -> c[x]
div21:	a - c -> c[s]
	if n/c go to div22
	0 - c -> c[s]
div22:	0 -> b[w]
	a exchange b[m]
	0 -> a[w]
	if p # 12
	  then go to mpy27
	if c[m] # 0
	  then go to div23
err:	if 1 = s 8
	  then go to $errmsg
	b -> c[wp]
	a - 1 -> a[m]
	c + 1 -> c[xs]
div23:	b exchange c[wp]
	a exchange c[m]
	select rom 03	; go to div15

lnc2:	load constant 6
	load constant 9
	load constant 3
	load constant 1
	load constant 4
	load constant 7
	load constant 1
	go to lnc8

pre27:	a + 1 -> a[m]
	if n/c go to pre25
eca21:	shift right a[wp]
eca22:	a - 1 -> a[s]
	if n/c go to eca21
	0 -> a[s]
	a + b -> a[w]
	return

	.rom 3

tan15:	a exchange b[w]
	jsb tnm11
	jsb stacka
	jsb tnm11
	jsb stacka
	if 0 = s 10
	  then go to tan31
	a exchange c[w]
tan31:	if 0 = s 6
	  then go to asn12
	if c[s] = 0
	  then go to tan32
	1 -> s 4
tan32:	0 -> c[s]
	jsb div11
$asin:	jsb cstack	; $asin label not used
	jsb mpy11
	jsb add10
	jsb $sqrt
	jsb stacka
asn12:	jsb div11
	if 0 = s 13
	  then go to $trig3
$atan:	0 -> a[w]
	a + 1 -> a[p]
	a -> b[m]
	a exchange c[m]
atn12:	c - 1 -> c[x]
	shift right b[wp]
	if c[xs] = 0
	  then go to atn12
atn13:	shift right a[wp]
	c + 1 -> c[x]
	if n/c go to atn13
	shift right a[w]
	shift right b[w]
	jsb cstack
atn14:	b exchange c[w]
	go to atn18

add10:	0 -> a[w]
	a + 1 -> a[p]
add11:	select rom 01	; go to $add3

sqt12:	p - 1 -> p
	a + b -> a[ms]
	if n/c go to sqt18
	select rom 00	; go to $err5

tnm11:	jsb cstack
	a exchange c[w]
	if c[p] = 0
	  then go to tnm12
	0 - c -> c[w]
tnm12:	c -> a[w]
	b -> c[x]
	go to add15

pmu11:	select rom 02	; go to pmu21

pqo11:	shift left a[w]
pqo12:	shift right b[ms]
	b exchange c[w]
	go to pqo16
	
pqo15:	c + 1 -> c[s]
pqo16:	a - b -> a[w]
	if n/c go to pqo15
	a + b -> a[w]
pqo13:	select rom 02	; go to $pqo23

pre11:	select rom 02	; go to pre21

sqt15:	c + 1 -> c[p]
sqt16:	a - c -> a[w]
	if n/c go to sqt15
	a + c -> a[w]
	shift left a[w]
	p - 1 -> p
sqt17:	shift right c[wp]
	if p # 0
	  then go to sqt16
	0 -> c[p]
	go to tnm12

stacka:	a exchange c[w]
	m2 -> c
	a exchange c[w]
	return

$atc1:	select rom 01	; go to atc1

$sqrt:	b exchange c[w]		; missing c->a[w], 0->b[w]
	p <- 4
	go to sqt14

atn15:	shift right b[wp]
atn16:	a - 1 -> a[s]
	if n/c go to atn15
	c + 1 -> c[s]
	a exchange b[wp]
	a + c -> c[wp]
	a exchange b[w]
atn18:	a -> b[w]
	a - c -> a[wp]
	if n/c go to atn16
	jsb stacka
	shift right a[w]
	a exchange c[wp]
	a exchange b[w]
	shift left a[wp]
	jsb cstack
	a + 1 -> a[s]
	a + 1 -> a[s]
	if n/c go to atn14
	0 -> c[w]
	0 -> b[x]
	shift right a[ms]
	jsb div14
	c - 1 -> c[p]
	jsb stacka
	a exchange c[w]
	p <- 4
atn17:	jsb pqo13	; atn17 label not used
	p <- 6
	jsb pmu11
	p <- 8
	jsb pmu11
	p <- 2
	load constant 8
	p <- 10
	jsb pmu11
	jsb atcd1
	jsb pmu11
	jsb $atc1
	shift left a[w]
	jsb pmu11
	b -> c[w]
atn19:	jsb add15	; atn19 label not used
	jsb $atc1
	c + c -> c[w]
	if 1 = s 10
	  then go to atan1
	if 0 = s 4
	  then go to atan2
	c + c -> c[w]
	a exchange c[w]
	c -> a[s]
atan1:	a exchange c[w]
	0 - c - 1 -> c[s]
	jsb add11
$atan9:	jsb $atc1	; $atan9 label not used
	c + c -> c[w]
atan2:	a exchange c[w]
	if 1 = s 3
	  then go to atan34
	a exchange c[w]
	jsb div11

; following differs from 25:

$L1622:	0 -> c[w]
	c - 1 -> c[p]
	c + 1 -> c[x]
	if 0 = s 13
	  then go to L1633
	jsb mpy11
atan34:	if 1 = s 7
	  then go to $kxexy
	select rom 01	; go to L0433

L1633:	if 1 = s 3		; equiv. tan + 1 in 25
	  then go to L1641
	jsb div11
	jsb $atc1
	c + c -> c[w]
	jsb mpy11

L1641:	jsb $atc1		; load pi/4
	c + c -> c[w]		; pi/2
	c + c -> c[w]		; pi
	c + c -> c[w]		; 2*pi
	jsb pre11
	jsb $atc1
	p <- 10
	jsb pqo11
	jsb atcd1
	p <- 8
	jsb pqo12
	p <- 2
	load constant 8
	p <- 6
	jsb pqo11
	p <- 4
	jsb pqo11
	jsb pqo11
	a exchange b[w]
	shift right c[w]
	p <- 13
	load constant 5
	go to tan14

$add1:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] # 0
	  then go to add13
	select rom 02	; go to L0700

add13:	if a >= b[m]
	  then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
add15:	select rom 02	; go to $norm

tan18:	shift right b[wp]
	shift right b[wp]
tan19:	c - 1 -> c[s]
	if n/c go to tan18
	a + c -> c[wp]
	a - b -> a[wp]
	b exchange c[wp]
tan13:	b -> c[w]
	a - 1 -> a[s]
	if n/c go to tan19
	a exchange c[wp]
	jsb stacka
	if b[s] = 0
	  then go to tan15
	shift left a[w]
tan14:	a exchange c[wp]
	jsb cstack
	shift right b[wp]
	c - 1 -> c[s]
	b exchange c[s]
	go to tan13

mpy11:	select rom 01	; go to $mpy21

div11:	select rom 01	; go to L0734

sqt18:	a + b -> a[x]
	if n/c go to sqt14
	c - 1 -> c[p]
sqt14:	c + 1 -> c[s]
	if p # 0
	  then go to sqt12
	a exchange c[x]
	0 -> a[x]
	if c[p] # 0
	  then go to sqt13
	shift right a[w]
sqt13:	shift right c[w]
	b exchange c[x]
	0 -> c[x]
	p <- 12
	go to sqt17

cstack:	m2 exchange c
	m2 -> c
	return

div14:	c + 1 -> c[p]
div15:	a - b -> a[ms]
	if n/c go to div14
	a + b -> a[ms]
	shift left a[ms]
div16:	p - 1 -> p	; div16 label not used
	if p # 0
	  then go to div15
	go to tnm12

atcd1:	p <- 6
	load constant 8
	load constant 6
	load constant 5
	load constant 2
	load constant 4
	load constant 9
	return

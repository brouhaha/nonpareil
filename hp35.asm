; HP-35 ROM code disassembled from dump by Peter Monta
; Copyright 2004 Eric L. Smith <eric@brouhaha.com>
; $Id$

; Much of the code is similar to the HP-45 ROM source code, so labels
; have been copied from that.
;
; Some conditional branch instructions ("if no carry go to") may
; effectively be unconditional, but there is no general way to
; automatically detect this.

	.rom @00

	jsb l00067
	go to l00277
	
l00002:	0 -> s8
	go to l00005
	
l00004:	1 -> s5
l00005:	1 -> s9
	1 -> s2
	select rom 2		; -> l02010
	
l00010:	jsb l00264
	go to l00376
	
l00012:	go to l00027
	
l00013:	go to l00060

	stack -> a
	go to l00331
	0 -> a[w]
	a + 1 -> a[p]
l00020:	0 -> b[w]
	select rom 1		; -> asn12
	
dig6:	a + 1 -> a[x]
dig5:	a + 1 -> a[x]
dig4:	a + 1 -> a[x]
	if no carry go to dig3
	
	jsb l00232
l00027:	c exchange m
	m -> c
	go to l00077

dig3:	a + 1 -> a[x]
dig2:	a + 1 -> a[x]
dig1:	a + 1 -> a[x]
	return

l00036:	3 -> p
	0 - c -> c[x]
l00040:	stack -> a
	go to l00020
	
l00042:	go to l00164
	
l00043:	3 -> p
	return
	
	no operation
	
L00046:	go to l00040

l00047:	1 -> s5
	1 -> s1
	go to l00056
	
l00052:	1 -> s9
	go to l00047
	
l00054:	1 -> s10
	go to l00302
	
l00056:	0 -> b[w]
	select rom 1		; -> l01060
	
l00060:	down rotate
	go to l00333

dig9:	a + 1 -> a[x]
dig8:	a + 1 -> a[x]
dig7:	a + 1 -> a[x]
	if no carry go to dig6	; unconditional?
	go to sub0
	
l00067:	clear registers
	jsb of12
l00071:	go to fst2zx

l00072:	go to eex2
	
l00073:	shift right a[w]
	1 -> s3
	go to l00166
	
l00076:	c -> stack
l00077:	clear status
	shift right a[w]
	jsb fst2zx
l00102:	a -> b[w]
	0 -> a[xs]
	shift left a[ms]
l00105:	a - 1 -> a[x]
	if no carry go to l00340
	if c[xs] = 0
	     then go to l00346
	a exchange b[ms]
	13 -> p
	go to l00346
	
eex7:	p - 1 -> p
	c + 1 -> c[x]
eex8:	if b[p] = 0
	     then go to eex7
	1 -> s11
	shift right a[ms]
	a exchange c[m]
	if s4 = 0
	     then go to den1
	jsb of14
	go to fst2zx
	
of11:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	a + b -> a[x]
	if no carry go to of13

of12:	0 -> c[w]
of13:	clear status
	c -> a[w]
of14:	12 -> p
	a -> b[x]
	c -> a[x]
	if c[xs] = 0
	     then go to of15
	0 - c -> c[x]
	c - 1 -> c[xs]
	if no carry go to of11
	5 -> p
of15:	a exchange c[x]
	if s4 = 0
	     then go to l00102
	a exchange b[x]
	0 -> b[x]
	jsb dsp1
	shift left a[x]
eex3:	shift right a[w]
	if p # 12
	     then go to den7
	a exchange c[wp]
	go to eex4
	
l00164:	jsb l00264
	select rom 1		; -> l01166
	
l00166:	if s4 = 0
	     then go to chs3
	a exchange c[wp]
	0 - c - 1 -> c[xs]
eex4:	c -> a[w]
	if c[xs] = 0
	     then go to eex5
	0 -> c[xs]
	0 - c -> c[x]
eex5:	13 -> p
eex6:	shift left a[ms]
	c - 1 -> c[x]
	if a[s] >= 1
	     then go to eex8
	if a[ms] >= 1
	     then go to eex6
	0 -> c[x]
den1:	jsb dsp1
	shift right a[ms]
den7:	c -> a[s]
den2:	if p # 12
	     then go to den4
	b -> c[w]
	c + 1 -> c[w]
	1 -> p
den3:	shift left a[wp]
	p + 1 -> p
	if c[p] = 0
	     then go to den3
den4:	a exchange c[w]
	if p # 3
	     then go to den5
	0 -> c[x]
	1 -> s6
	go to eex4

sub0:	0 - c - 1 -> c[s]
l00232:	stack -> a
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
	     then go to l00276
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	     then go to l00276
	go to add6

fst3:	0 -> a[ms]
	if s3 = 0
	     then go to l00264
	a - 1 -> a[s]
	0 - c - 1 -> c[s]
l00264:	if s7 = 0
	     then go to fst5
	c -> stack
fst5:	1 -> s7
	0 -> c[w]
	c - 1 -> c[w]
	0 - c -> c[s]
	c + 1 -> c[s]
	b exchange c[w]
	return

l00276:	select rom 1		; go to add12

l00277:	jsb of12
	1 -> s5
	go to fst2zx

l00302:	shift right a[w]
dsp7:	c -> a[s]
l00304:	0 -> s8
	go to dsp8

dsp2:	c + 1 -> c[xs]
dsp3:	1 -> s8
	if s5 = 0
	     then go to dsp5
	c + 1 -> c[x]
	if no carry go to dsp2
dsp4:	display toggle
dsp5:	if s0 = 0
	     then go to dsp3
dsp8:	0 -> s0
dsp6:	p - 1 -> p
	if p # 12
	     then go to dsp6
	display off
	if s8 = 0
	     then go to dsp4
	shift left a[w]
	0 -> s5
	keys -> rom address

l00331:	c -> stack
	a exchange c[w]
l00333:	jsb of13
	1 -> s7
fst2zx:	jsb dsp1
	jsb fst3
	go to den2

l00340:	shift right a[ms]
	p - 1 -> p
	if p # 2
	     then go to l00105
	12 -> p
	0 -> a[w]
l00346:	0 -> a[ms]
	a + 1 -> a[p]
	a + 1 -> a[p]
	2 -> p
l00352:	p + 1 -> p
	a - 1 -> a[p]
	if no carry go to l00357
	if b[p] = 0
	     then go to l00352
l00357:	a + 1 -> a[p]
	a exchange b[w]
	return

eex2:	1 -> s4
	if s11 = 0
	     then go to dig1
	go to eex3

chs3:	0 - c - 1 -> c[s]
dsp1:	0 -> s10
	go to dsp7

den5:	if s6 = 0
	     then go to den6
	p - 1 -> p
den6:	shift right b[wp]
	jsb eex4
l00376:	m -> c
	go to l00333

	.symtab

	.rom @01

	go to tan13

tan15:	a exchange b[w]
	jsb tnm11
	stack -> a
	jsb tnm11
	stack -> a
	if s9 = 0
	     then go to tan16
	a exchange c[w]
tan16:	if s5 = 0
	     then go to asn12
	0 -> c[s]
	jsb div11
l01015:	c -> stack
	jsb mpy11
	jsb add10
	jsb sqt11
	stack -> a
asn12:	jsb div11
	if s10 = 0
	     then go to rtn12
atn11:	0 -> a[w]
	a + 1 -> a[p]
	a -> b[m]
	a exchange c[m]
atn12:	c - 1 -> c[x]
	shift right b[wp]
	if c[xs] = 0
	     then go to atn12
atn13:	shift right a[wp]
	c + 1 -> c[x]
	if no carry go to atn13
	shift right a[w]
	shift right b[w]
	c -> stack
atn14:	b exchange c[w]
	go to atn18

sqt11:	b exchange c[w]
	4 -> p
	go to sqt14

tnm11:	c -> stack
	a exchange c[w]
	if c[p] = 0
	     then go to tnm12
	0 - c -> c[w]
tnm12:	c -> a[w]
	b -> c[x]
	go to add15

	c -> a[w]
	if s1 = 0
	     then go to sqt11
	if s10 = 0
	     then go to l01155
	if s5 = 0
	     then go to atn11
	0 - c - 1 -> c[s]
	a exchange c[s]
	go to l01015

atn15:	shift right b[wp]
atn16:	a - 1 -> a[s]
	if no carry go to atn15
	c + 1 -> c[s]
	a exchange b[wp]
	a + c -> c[wp]
	a exchange b[w]
atn18:	a -> b[w]
	a - c -> a[wp]
	if no carry go to atn16
	stack -> a
	shift right a[w]
	a exchange c[wp]
	a exchange b[w]
	shift left a[wp]
	c -> stack
	a + 1 -> a[s]
	a + 1 -> a[s]
	if no carry go to atn14
	0 -> c[w]
	0 -> b[x]
	shift right a[ms]
	jsb div14
	c - 1 -> c[p]
	stack -> a
	a exchange c[w]
	4 -> p
	jsb pqo13
	6 -> p
	jsb pmu11
	8 -> p
	jsb pmu11
	2 -> p
	load constant 8
	10 -> p
	jsb pmu11
	jsb atcd1
	jsb pmu11
	jsb atc1
	shift left a[w]
	jsb pmu11
	b -> c[w]
	jsb add15
	jsb atc1
	c + c -> c[w]
	jsb div11
	if s9 = 0
	     then go to l01154
	0 - c - 1 -> c[s]
	jsb add10
l01154:	0 -> s1
l01155:	0 -> c[w]
	c - 1 -> c[p]
	c + 1 -> c[x]
	if s1 = 0
	     then go to mpy11
	jsb div11
	jsb atc1
	c + c -> c[w]
	jsb mpy11
	jsb atc1
	c + c -> c[w]
	c + c -> c[w]
	jsb rtn11
	c + c -> c[w]
	jsb pre11
	jsb atc1
	10 -> p
	jsb pqo11
	jsb atcd1
	8 -> p
	jsb pqo12
	2 -> p
	load constant 8
	6 -> p
	jsb pqo11
	4 -> p
	jsb pqo11
	jsb pqo11
	a exchange b[w]
	shift right c[w]
	13 -> p
	load constant 5
	go to tan14

atcd1:	6 -> p
	load constant 8
	load constant 6
	load constant 5
	load constant 2
	load constant 4
	load constant 9
rtn11:	if s1 = 0
	     then go to rtn12
	return

add10:	0 -> a[w]
	a + 1 -> a[p]
	select rom 0		; -> l00233

pmu11:	select rom 2		; -> pmu21

pqo11:	shift left a[w]
pqo12:	shift right b[ms]
	b exchange c[w]
	go to pqo16

pqo15:	c + 1 -> c[s]
pqo16:	a - b -> a[w]
	if no carry go to pqo15
	a + b -> a[w]
pqo13:	select rom 2		; -> l02245

mpy11:	select rom 2		; -> mpy21

div11:	a - c -> c[x]
	select rom 2		; -> l02250

sqt15:	c + 1 -> c[p]
sqt16:	a - c -> a[w]
	if no carry go to sqt15
	a + c -> a[w]
	shift left a[w]
	p - 1 -> p
sqt17:	shift right c[wp]
	if p # 0
	     then go to sqt16
	go to tnm12

div14:	c + 1 -> c[p]
div15:	a - b -> a[ms]
	if no carry go to div14
	a + b -> a[ms]
	shift left a[ms]
	p - 1 -> p
	if p # 0
	     then go to div15
	go to tnm12

sqt12:	p - 1 -> p
	a + b -> a[ms]
	if no carry go to sqt18
	select rom 0		; -> l00277

add12:	c - 1 -> c[xs]		; (from rom 00276)
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] >= 1
	     then go to add13
	select rom 2		; -> l02306

add13:	if a >= b[m]
	     then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
add15:	select rom 2		; -> nrm21

atc1:	0 -> c[w]
	11 -> p
	load constant 7		; load pi/4
	load constant 8
	load constant 5
	load constant 3
	load constant 9
	load constant 8
	load constant 1
	load constant 6
	load constant 3
	load constant 5
	12 -> p
	return

rtn12:	select rom 0		; -> l00333

sqt18:	a + b -> a[x]
	if no carry go to sqt14
	c - 1 -> c[p]
sqt14:	c + 1 -> c[s]
	if p # 0
	     then go to sqt12
	a exchange c[x]
	0 -> a[x]
	if c[p] >= 1
	     then go to sqt13
	shift right a[w]
sqt13:	shift right c[w]
	b exchange c[x]
	0 -> c[x]
	12 -> p
	go to sqt17

pre11:	select rom 2		; -> pre21

tan18:	shift right b[wp]
	shift right b[wp]
tan19:	c - 1 -> c[s]
	if no carry go to tan18
	a + c -> c[wp]
	a - b -> a[wp]
	b exchange c[wp]
tan13:	b -> c[w]
	a - 1 -> a[s]
	if no carry go to tan19
	a exchange c[wp]
	stack -> a
	if b[s] = 0
	     then go to tan15
	shift left a[w]
tan14:	a exchange c[wp]
	c -> stack
	shift right b[wp]
	c - 1 -> c[s]
	b exchange c[s]

	.symtab

	.rom @02

err21:	select rom 0		; -> l00001

ln24:	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to ln26
	
xty22:	stack -> a
	jsb mpy21
	c -> a[w]
	if s8 = 0
	     then go to exp21
	0 -> a[w]
	a - c -> a[m]
	if no carry go to err21
	shift right a[w]
	c - 1 -> c[s]
	if no carry go to err21
ln25:	c + 1 -> c[s]
ln26:	a -> b[w]
	jsb eca22
	a - 1 -> a[p]
	if no carry go to ln25
	a exchange b[wp]
	a + b -> a[s]
	if no carry go to ln24
	7 -> p
	jsb pqo23
	8 -> p
	jsb pmu22
	9 -> p
	jsb pmu21
	jsb lncd3
	10 -> p
	jsb pmu21
	jsb lncd2
	11 -> p
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
	11 -> p
	jsb mpy27
	if s9 = 0
	     then go to xty22
	if s5 = 0
	     then go to rtn21
	jsb lnc10
	jsb mpy22
	go to rtn21

exp21:	jsb lnc10
	jsb pre21
	jsb lnc2
	11 -> p
	jsb pqo21
	jsb lncd1
	10 -> p
	jsb pqo21
	jsb lncd2
	9 -> p
	jsb pqo21
	jsb lncd3
	8 -> p
	jsb pqo21
	jsb pqo21
	jsb pqo21
	6 -> p
	0 -> a[wp]
	13 -> p
	b exchange c[w]
	a exchange c[w]
	load constant 6
	go to exp23

pre23:	if s2 = 0
	     then go to pre24
	a + 1 -> a[x]
pre29:	if a[xs] >= 1
	     then go to pre27
pre24:	a - b -> a[ms]
	if no carry go to pre23
	a + b -> a[ms]
	shift left a[w]
	c - 1 -> c[x]
	if no carry go to pre29
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
	if s2 = 0
	     then go to pqo28
	load constant 4
	c + 1 -> c[m]
	if no carry go to pqo24
pqo27:	load constant 6
pqo28:	if p # 1
	     then go to pqo27
	shift right c[w]
pqo24:	shift right c[w]
nrm26:	if s2 = 0
	     then go to rtn21
	return

lncd2:	7 -> p
lnc6:	load constant 3
	load constant 3
	load constant 0
lnc7:	load constant 8
	load constant 5
	load constant 0
	load constant 9
	go to lnc9

exp29:	jsb eca22
	a + 1 -> a[p]
exp22:	a -> b[w]
	c - 1 -> c[s]
	if no carry go to exp29
	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
exp23:	a exchange c[w]
	a - 1 -> a[s]
	if no carry go to exp22
	a exchange b[w]
	a + 1 -> a[p]
	jsb nrm21
rtn21:	select rom 1		; -> rtn11

eca21:	shift right a[wp]
eca22:	a - 1 -> a[s]
	if no carry go to eca21
	0 -> a[s]
	a + b -> a[w]
	return

pqo21:	select rom 1		; -> pqo11

pmu21:	shift right a[w]
pmu22:	b exchange c[w]
	go to pmu24

pmu23:	a + b -> a[w]
pmu24:	c - 1 -> c[s]
	if no carry go to pmu23
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	go to pqo23

mpy21:	3 -> p
mpy22:	a + c -> c[x]
	a - c -> c[s]
	if no carry go to div22
	0 - c -> c[s]
div22:	a exchange b[m]
	0 -> a[w]
	if p # 12
	     then go to mpy27
	if c[m] >= 1
	     then go to div23
	if s1 = 0
	     then go to err21
	b -> c[wp]
	a - 1 -> a[m]
	c + 1 -> c[xs]
div23:	b exchange c[wp]
	a exchange c[m]
	select rom 1		; -> l01271

lnc2:	0 -> s8
	load constant 6
	load constant 9
	load constant 3
	load constant 1
	load constant 4
	load constant 7
	load constant 1
	go to lnc8

pre27:	a + 1 -> a[m]
	if no carry go to pre25
myp26:	a + b -> a[w]
mpy27:	c - 1 -> c[p]
	if no carry go to myp26
mpy28:	shift right a[w]
	p + 1 -> p
	if p # 13
	     then go to mpy27
	c + 1 -> c[x]
nrm21:	0 -> a[s]
	12 -> p
	0 -> b[w]
nrm23:	if a[p] >= 1
	     then go to nrm24
	shift left a[w]
	c - 1 -> c[x]
	if a[w] >= 1
	     then go to nrm23
	0 -> c[w]
nrm24:	a -> b[x]
	a + b -> a[w]
	if a[s] >= 1
	     then go to mpy28
	a exchange c[m]
	c -> a[w]
	0 -> b[w]
nrm27:	12 -> p
	go to nrm26

lncd1:	9 -> p
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
lnc9:	load constant 3
	go to nrm27

pre21:	a exchange c[w]
	a -> b[w]
	c -> a[m]
	c + c -> c[xs]
	if no carry go to pre24
	c + 1 -> c[xs]
pre22:	shift right a[w]
	c + 1 -> c[x]
	if no carry go to pre22
	go to pre26

lnc10:	0 -> c[w]
	12 -> p
	load constant 2
	load constant 3
	load constant 0
	load constant 2
	load constant 5
	go to lnc7

lncd3:	5 -> p
	go to lnc6

	.symtab

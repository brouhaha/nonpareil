; 35 ROM "v2" code
; Copyright 2023 Eric Smith <spacewar@gmail.com>
; Based on ROM dump by Peter Monta
; This ROM version has known bugs in exponential and trigonometric functions.
;
; Some of the code is similar to the 45 ROM source code, so labels
; have been copied from that.
;
; Some conditional branch instructions ("if no carry go to") may
; effectively be unconditional, but there is no general way to
; automatically detect this.

	.arch classic

; start of ROM @00

key_clr:
	jsb clr		; JSB used as unconditional goto

l00001:	go to l00277

key_e_to_x:
        0 -> s8
key_ln:
	go to l00005

key_log:
        1 -> s5
l00005:	1 -> s9
key_y_to_x:
	1 -> s2
	select rom go to l02010

key_rcl:
        jsb l00124
	go to l00102

key_sto:
        go to sto

key_rdn:
        go to rdn

key_x_exch_y:
        stack -> a
	go to l00331

key_1_over_x:
        0 -> a[w]
	a + 1 -> a[p]
l00020:	0 -> b[w]
	select rom go to asn12

dig6:	a + 1 -> a[x]
dig5:	a + 1 -> a[x]
dig4:	a + 1 -> a[x]
	if no carry go to dig3

key_add:
        jsb l00232

sto:	c exchange m
	m -> c
	go to l00077

dig3:	a + 1 -> a[x]
dig2:	a + 1 -> a[x]
dig1:	a + 1 -> a[x]
	return

key_mult:
        3 -> p
	0 - c -> c[x]
l00040:	stack -> a
	go to l00020

key_pi:
        go to l00164

key_decimal:
        11 -> p
key_0:	return

	no operation

key_div:
        go to l00040

l00047:	1 -> s5
key_tan:
        1 -> s1
	go to key_sqrt

key_cos:
        1 -> s9
key_sin:
	go to l00047

key_arc:
        1 -> s10
	go to l00302

key_sqrt:
        0 -> b[w]
	select rom go to l01060

rdn:	down rotate
	go to l00333

dig9:	a + 1 -> a[x]
dig8:	a + 1 -> a[x]
dig7:	a + 1 -> a[x]
	if no carry go to dig6	; unconditional?

key_sub:
        go to sub0

clr:	clear registers
key_cls:
	jsb of12
	go to l00335

key_eex:
        go to eex2

key_chs:
        shift right a[w]
	1 -> s3
	go to l00340

key_enter:
        c -> stack
l00077:	clear status
	shift right a[w]
	go to l00335

l00102:	m -> c
	go to l00333

l00104:	a -> b[w]
	0 -> a[xs]
	shift left a[ms]
l00107:	a - 1 -> a[x]
	if no carry go to l00207
	if c[xs] = 0
	    then go to l00215
	a exchange b[ms]
	13 -> p
	go to l00215

l00116:	a exchange b[w]
	0 -> a[w]
	if s3 = 0
	    then go to l00124
	a - 1 -> a[s]
	0 - c - 1 -> c[s]
l00124:	if s7 = 0
	    then go to l00127
	c -> stack
l00127:	1 -> s7
	0 -> c[w]
	c - 1 -> c[x]
	a exchange c[s]
	if p # 11
	    then go to l00107
	jsb l00107
l00136:	1 -> s6
l00137:	jsb l00345
	shift right a[ms]
	if p # 12
	    then go to l00136
l00143:	b exchange c[w]
	c + 1 -> c[w]
	1 -> p
l00146:	shift left a[wp]
	p + 1 -> p
	if c[p] = 0
	    then go to l00146
	c - 1 -> c[w]
	b exchange c[w]
	a exchange c[m]
	if p # 3
	    then go to l00257
l00157:	a exchange c[m]
l00160:	0 -> a[x]
	if s4 = 0
	    then go to l00137
	go to l00172

l00164:	jsb l00124
	select rom go to l01166

eex2:	1 -> s4
	if s11 = 0
	    then go to dig1
	shift right a[w]	; eex3 in later ROM
l00172:	jsb l00345
	a -> b[x]
	shift right a[w]
	a -> b[xs]
	a - b -> a[x]
	a exchange c[x]
	if b[xs] = 0
	    then go to l00203
	0 - c -> c[x]
l00203:	a - c -> c[x]
	c -> a[x]
	jsb of14
	go to l00335

l00207:	shift right a[ms]
	p - 1 -> p
	if p # 2
	    then go to l00107
	12 -> p
	0 -> a[w]
l00215:	0 -> a[ms]
	a + 1 -> a[p]
	a + 1 -> a[p]
	2 -> p
l00221:	p + 1 -> p
	a - 1 -> a[p]
	if no carry go to l00226
	if b[p] = 0
	    then go to l00221
l00226:	a + 1 -> a[p]
	a exchange b[w]
	return

sub0:	0 - c - 1 -> c[s]
l00232:	stack -> a
l00233:	0 -> b[w]
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

l00257:	c -> a[m]
	if s6 = 0
	    then go to l00264
	p - 1 -> p
	c - 1 -> c[x]
l00264:	shift right b[wp]
	12 -> p
	if c[m] = 0
	    then go to l00160
	c + 1 -> c[x]
	1 -> s11
l00272:	if a[p] >= 1
	    then go to l00157
	shift left a[m]
	go to l00272

l00276:	select rom go to add12

l00277:	jsb of12
	1 -> s5
	go to l00335

l00302:	shift right a[w]
dsp7:	c -> a[s]
	0 -> s8
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
l00333:	jsb l00375
	1 -> s7
l00335:	jsb l00345
	jsb l00116
	go to l00143

l00340:	if s4 = 0
	    then go to l00344
	a + b -> a[xs]
	if no carry go to l00373
l00344:	0 - c - 1 -> c[s]
l00345:	0 -> s10
	go to dsp7

of11:	a exchange c[xs]
	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	if a[xs] >= 1
	    then go to l00375

of12:	0 -> c[w]
of13:	clear status
	c -> a[w]
of14:	12 -> p
	if c[xs] = 0
	    then go to of15
	0 - c -> c[x]
	c - 1 -> c[xs]
	if no carry go to of11
	5 -> p
of15:	a exchange c[x]
	if s4 = 0
	    then go to l00104
	a exchange b[x]
l00373:	0 -> b[x]
	go to l00172

l00375:	if c[m] >= 1
	    then go to of13
	go to of12

; start of ROM @01

; PC wraps to here from 01377
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

l01060:	c -> a[w]
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
	c + 1 -> c[p]
	jsb l01267
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
l01166:	jsb atc1
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
	select rom go to l00233

pmu11:	select rom go to pmu21

pqo11:	shift left a[w]
pqo12:	shift right b[ms]
	b exchange c[w]
	go to pqo16

pqo15:	c + 1 -> c[s]
pqo16:	a - b -> a[w]
	if no carry go to pqo15
	a + b -> a[w]
pqo13:	select rom go to l02245

mpy11:	select rom go to mpy21

div11:	a - c -> c[x]
	select rom go to l02250

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
l01267:	p - 1 -> p
	if p # 0
l01271:	    then go to div15
	go to tnm12

sqt12:	p - 1 -> p
	a + b -> a[ms]
	if no carry go to sqt18
	select rom go to l00277

add12:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] >= 1
	    then go to add13
	select rom go to l02306

add13:	if a >= b[m]
	    then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
add15:	select rom go to nrm21

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

rtn12:	select rom go to l00333

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

pre11:	select rom go to pre21

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
; wraps to 01000

; start of ROM @02

err21:	select rom go to l00001

ln24:	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to ln26

xty22:	stack -> a
	jsb mpy21
l02010:	c -> a[w]
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
	a -> b[s]
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
	    then go to l02224
	jsb lnc10
	jsb mpy22
	go to l02224

exp21:	jsb lnc10
	jsb pre21
	0 -> b[ms]
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
	0 - c - 1 -> c[x]
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
	    then go to l02224
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
	0 -> a[w]
	a + 1 -> a[p]
	jsb mpy26
l02224:	select rom go to rtn11

eca21:	shift right a[wp]
eca22:	a - 1 -> a[s]
	if no carry go to eca21
	a + b -> a[wp]
	a exchange b[s]
	return

pqo21:	select rom go to pqo11

pmu21:	shift right a[w]
pmu22:	b exchange c[w]
	go to pmu24

pmu23:	a + b -> a[w]
pmu24:	c - 1 -> c[s]
	if no carry go to pmu23
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
l02245:	go to pqo23

mpy21:	3 -> p
mpy22:	a + c -> c[x]
l02250:	a - c -> c[s]
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
	select rom go to l01271		; -> div15

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
mpy26:	a + b -> a[w]
mpy27:	c - 1 -> c[p]
l02306:	if no carry go to mpy26
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

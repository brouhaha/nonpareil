; HP-45 ROM 00 source from United States Patent 4,001,569
; keyed in by Eric Smith on 3/9/95 - any errors are probably mine

	.rom @00

pwo1:	jsb	pwo2

tms5:	select rom 6

tms2:	jsb frac
	a exchange b[w]
	a + 1 -> a[m]
	a -> b[xs]
	a - 1 -> a[xs]
	a + b -> a[w]
	0 -> a[x]
	jsb mlop
	jsb mlop
	0 -> a[x]
	jsb norm
	go to tms4

dmdtz4:	if s8 # 1
	     then go to dmt2
tdms:	jsb mode
	a exchange c[w]
	c -> a[w]
	go to tms2

pwo3:	select rom 5

tpl4:	jsb mode
	a exchange c[w]
	select rom 4

ret1:	select rom 1

trc1z1:	if s3 # 1
	     then go to ret1
	c -> stack
	0 -> c[w]
	c -> data address
	no operation
	data -> c
	a exchange c[w]
	jsb div1
	jsb exch
	jsb mul1
	jsb exch
	0 -> a[s]
	data -> c
	if c[s] = 0
	     then go to trc2
	a - 1 -> a[s]
	jsb trc2

pwo2:	go to pwo3

sqt1:	select rom 1

trc2:	a exchange c[w]
	if s8 # 1
	     then go to reg9z4
	0 - c - 1 -> c[s]
	jsb reg9z4

sqrtz3:	if s1 #  1
	     then go to sqt1
	if s10 # 1
	     then go to tn12
	go to mag1z1

tanx:	select rom 1

sn12:	c -> a[w]
	select rom 1

mag1z1:	a exchange c[w]
	c -> a[w]
	c + 1 -> c[xs]
	if no carry go to mag3
	if c[x] = 0
	     then go to mag3
	0 -> c[w]
	0 -> p
	load constant 5
	12 -> p
	a + c -> c[x]
	if no carry go to mag4
mag3:	if s10 # 1
	     then go to rom1
	a exchange c[w]
	go to sn12

frac:	0 -> c[x]
	0 -> p
	load constant 5
	a - c -> a[x]
	if a[x] >= 1
	     then go to frc1
	go to err2

dmt2:	jsb frac
	jsb mlp0
	0 -> b[w]
	a exchange b[wp]
	a exchange b[w]
	shift left a[w]
	jsb mlp2
	1 -> s7
	jsb norm
	0 -> c[w]
	load constant 3
	load constant 6
	12 -> p
	jsb div1
	jsb mod0
	go to fst0

rtfg:	c + 1 -> c[x]
	c + 1 -> c[p]
	if no carry go to dvml

tms4:	0 -> c[w]
	2 -> p
	load constant 4
	a exchange c[w]
	go to tms5

tn12:	select rom 1

tpol:	1 -> s7
	if s4 # 1
	     then go to tpl3
	c + c -> c[w]
	a + c -> c[s]
	if a[m] >= 1
	     then go to tpl2
	0 - c - 1 -> c[s]
tpl2:	jsb sub1
tpl3:	1 -> s1
	go to tpl4

rom1:	select rom 1

drg1z1:	if s8 # 1
	     then go to tpol
drg0:	jsb mode
	1 -> s1
	if s10 # 1
	     then go to mag1z1
	go to regx

fst0:	a exchange c[w]
fst1:	select rom 3

gtfd:	c - 1 -> c[x]
	c - 1 -> c[x]
	1 -> s7
dtfr:	c - 1 -> c[p]
dvml:	if s10 # 1
	     then go to div1
	go to mul1

mod0:	0 -> s10
mode:	1 -> s7
	0 -> s4
	1 -> s6
	m -> c
	if c[s] = 0
	     then go to mod2
	1 -> s4
mod2:	c + 1 -> c[s]
	if no carry go to mod3
	0 -> s6
mod3:	0 -> c[w]
	c + 1 -> c[x]
	if s1 # 1
	     then go to degr
	if s4 # 1
	     then go to ret0
	0 -> s7
	if s6 # 1
	     then go to dtfr
	go to rtfg

add3z1:	go to add3

mldv:	if s10 # 1
	     then go to mul1
div1:	1 -> s11
div0:	0 -> s1
	0 -> b[w]
	go to divx

mul1:	1 -> s11
mul0:	0 -> s1
mulx:	select rom 1

divx:	select rom 1

sub1:	1 -> s11
sub0:	0 - c - 1 -> c[s]
add0zx:	0 -> s1
	0 -> s2
add3:	0 -> b[w]
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
	     then go to add7
add8:	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	     then go to add7
	go to add6

add7:	select rom 1

err2z1:	go to err2

degr:	if s6 # 1
	     then go to ret0
	0 -> s7
	if s4 # 1
	     then go to dtfr
	go to gtfd

exch:	stack -> a
	c -> stack
	return

norm:	1 -> s11
	select rom 1

pii2:	select rom 1

frc1:	b exchange c[m]
frc2:	shift right b[w]
	a + 1 -> a[x]
	if no carry go to frc2
	0 -> a[w]
	6 -> p
	return

pii4:	if s11 # 1
	     then go to pirt
	c + c -> c[w]
	1 -> s7
	go to mldv

pirt:	select rom 1

pii4z1:	12 -> p
	go to pii4

retnz1:	if s11 # 1
	     then go to rtrn
	1 -> s11
	if s7 # 1
	     then go to pii2
	0 -> s11
ret0:	return

mlop:	0 -> b[w]
mlp0:	a exchange b[wp]
	shift right b[w]
mlp2:	10 -> p
mlp3:	a + b -> a[w]
	p - 1 -> p
	if p # 4
	     then go to mlp3
	return

mag4:	0 -> c[w]
	c + 1 -> c[p]
	if s10 # 1
	     then go to tanx
	go to tn12

reg9:	if s1 # 1
	     then go to fst1
reg9z4:	a exchange c[w]
regx:	0 -> c[w]
	c - 1 -> c[p]
	c -> data address
	0 -> c[w]
	c -> data
	go to fst0

rtrn:	if s3 # 1
	     then go to reg9
	if s10 # 1
	     then go to ret5
ret4:	select rom 4

ret5:	select rom 5

err2:	select rom 2

	.symtab

; HP-45 ROM 01 source from United States Patent 4,001,569
; keyed in by Eric Smith on 3/9/95 - any errors are probably mine

	.rom @01

	b exchange c[s]
	go to tan13

tan15:	a exchange b[w]
	jsb tnm11
	data -> c
	a exchange c[w]
	jsb tnm11
	data -> c
	a exchange c[w]
tanx:	if s9 # 1
	     then go to tan16
	a exchange c[w]
tan16:	if s5 # 1
	     then go to asn12
	if c[s] >= 1
	     then go to tan17
	0 -> s8
tan17:	0 -> c[s]
	jsb div11
asn11:	c -> data
	jsb mpy11
	jsb add10
	jsb sqt11
	data -> c
	select rom 0

asn1z0:	a exchange c[w]
asn12:	jsb div11
	if s10 # 1
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
	c -> data
atn14:	b exchange c[w]
	go to atn18

sqt11:	b exchange c[w]
	4 -> p
	go to sqt14

tnm11:	c -> data
	a exchange c[w]
	if c[p] = 0
	     then go to tnm12
	0 - c -> c[w]
tnm12:	c -> a[w]
	b -> c[x]
	go to add15

tanxz0:	go to tanx

tploxj:	select rom 0

sin12:	if s5 # 1
	     then go to atn11
	0 - c - 1 -> c[s]
	a exchange c[s]
	go to asn11

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
	a exchange c[w]
	data -> c
	shift right c[w]
	a exchange c[s]
	a exchange b[w]
	shift left a[wp]
	c -> data
	a + 1 -> a[s]
	a + 1 -> a[s]
	if no carry go to atn14
	0 -> c[w]
	0 -> b[x]
	shift right a[ms]
	jsb div14
	a - 1 -> a[p]
	data -> c
	4 -> p
atn17:	jsb pqo13
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
tan12:	jsb atc1
	c + c -> c[w]
	if s10 # 1
	     then go to rom0
	if s9 # 1
	     then go to rom0
	a exchange c[w]
	0 - c - 1 -> c[s]
	jsb add11
	jsb atc1
	c + c -> c[w]
rom0:	select rom 0

lpi11:	jsb atc1
	c + 1 -> c[w]
	c + 1 -> c[w]
	jsb rtn11
	c + 1 -> c[w]
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
rtn11:	if s1 # 1
	     then go to rtn12
	return

add10:	0 -> a[w]
	a + 1 -> a[p]
add11:	select rom 0

pmu11:	select rom 2

pqo11:	shift left a[w]
pqo12:	shift right b[ms]
	b exchange c[w]
	go to pqo16

pqo15:	c + 1 -> c[s]
pqo16:	a - b -> a[w]
	if no carry go to pqo15
	a + b -> a[w]
pqo13:	select rom 2

mpy11:	select rom 2

div11:	a - c -> c[x]
	select rom 2

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
div16:	p - 1 -> p
	if p # 0
	     then go to div15
	go to tnm12

sqt12:	p - 1 -> p
	a + b -> a[ms]
	if no carry go to sqt18
	select rom 0

add12:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] >= 1
	     then go to add13
	select rom 2

add13:	if a >= b[m]
	     then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
add15:	select rom 2
atc1:	0 -> c[w]
	11 -> p
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
	select rom 0

	return

rtn12:	select rom 0

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

pre11:	select rom 2

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
	a exchange c[s]
	data -> c
	a exchange c[w]
	if b[s] = 0
	     then go to tan15
	shift left a[w]
tan14:	a exchange c[wp]
	c -> data
	shift right b[wp]
	c - 1 -> c[s]

	.symtab

; HP-45 ROM 02 source from United States Patent 4,001,569
; keyed in by Eric Smith on 3/9/95 - any errors are probably mine

	.rom @02

err21:	select rom 6
ln24:	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to ln26

xty22:	stack -> a
	jsb mpy21

xty21:	c -> a[w]
	if s8 # 1
	     then go to exp21
ln22:	0 -> a[w]
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
	if s9 # 1
	     then go to xty22
	if s5 # 1
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

pre23:	if s2 # 1
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
	if s2 # 1
	     then go to pqo28
	load constant 4
	c + 1 -> c[m]
	if no carry go to pqo24
pqo27:	load constant 6
pqo28:	if p # 1
	     then go to pqo27
	shift right c[w]
pqo24:	shift right c[w]
nrm26:	if s2 # 1
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
rtn21:	select rom 1

eca21:	shift right a[wp]
eca22:	a - 1 -> a[s]
	if no carry go to eca21
	0 -> a[s]
	a + b -> a[w]
	return

pqo21:	select rom 1

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
div21:	a - c -> c[s]
	if no carry go to div22
	0 - c -> c[s]
div22:	a exchange b[m]
	0 -> a[w]
	if p # 12
	     then go to mpy27
	if c[m] >= 1
	     then go to div23
	if s1 # 1
	     then go to err21
	select rom 5
	go to nrm25

	no operation

div23:	b exchange c[wp]
	a exchange c[m]
	select rom 1

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
	if no carry go to mpy26
mpy28:	shift right a[w]
	p + 1 -> p
	if p # 13
	     then go to mpy27
nrm20:	c + 1 -> c[x]
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
nrm25:	c -> a[w]
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

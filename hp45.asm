; HP-45 ROM source code from United States Patent 4,001,569
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

	.rom @03

prfx:	select rom 4		; unsure of label

	no operation

fix1:	go to fix2

exp0:	go to exp1		; unsure of label

lnnn:	go to lnn2z4		; unsure of label

	no operation
invx:	go to inv1

lexx:	select rom 2

perc:	select rom 4

rnd0:	select rom 6

rcal:	go to rcl0		; unsure of label

stor:	go to str0

rold:	down rotate
	go to fst1zx

exc1:	stack -> a
	c -> stack
	go to fstxzj

fst2z5:	go to ent2

dig6:	a + 1 -> a[w]
dig5:	a + 1 -> a[w]
dig4:	a + 1 -> a[w]
	if no carry go to dig3

addd:	select rom 4

fix3:	jsb dsp0z4
	shift left a[w]
	go to fmt1

dig3:	a + 1 -> a[w]
dig2:	a + 1 -> a[w]
dig1:	a + 1 -> a[w]
	return

mult:	select rom 4

tkra:	keys -> rom address

sig1:	0 -> s8
	select rom 4

sigp:	go to sig1

dcpt:	3 -> p
dig0:	return

dvid:	select rom 4

divd:	go to dvid

tan2:	1 -> s5
tang:	jsb sav9
	go to sqt1z4

coss:	go to cos2

sinn:	go to tan2

tpol:	select rom 4

	no operation

sqar:	jsb save
	go to mul0

	no operation

sqt2:	select rom 0

dig9:	a + 1 -> a[w]
dig8:	a + 1 -> a[w]
dig7:	a + 1 -> a[w]
	if no carry go to dig6

subt:	select rom 4

	no operation

clrx:	jsb ofl2
	go to fst2zx

eexx:	go to eex2

chs1:	go to chs2

clok:	0 -> b[w]
	select rom 7

ent1:	c -> stack
ent2:	jsb ofl3
	go to fst2zx

sqt0:	jsb save
sqt1z4:	0 -> s9
sqt1:	go to sqt2

inv1:	jsb save
	0 -> a[w]
	a + 1 -> a[p]
	if no carry go to div0
mul0:	select rom 4

div0:	select rom 4

fix2:	0 -> s9
	go to fix3

cos2:	jsb sav9
cos2z4:	1 -> s9
trecz4:	1 -> s5
	go to sqt2

frmt:	shift left a[w]
	a + 1 -> a[w]
fmt1:	shift left a[w]
	c exchange m
	a exchange c[x]
	c exchange m
fstpz4:	go to fstp

	no operation
	no operation

exp1:	0 -> s8
lnn2z4:	1 -> s9
	jsb save
nty1z4:	1 -> s2
	go to lexx

sci2z4:	jsb dsp0z4
	go to frmt

sav1:	1 -> s3
save:	0 -> s10
	select rom 6

sav2:	select rom 6

sav9:	1 -> s1
	go to save

rcl0:	1 -> s9
	go to str1

str0:	0 -> s9
str1:	1 -> s2
	jsb dsp0z4
	jsb chk0
	jsb sav2
	if s9 # 1
	     then go to str2
	jsb fst4
	go to fstxzj

str2:	c -> data
fstp:	if s7 # 1
	     then go to ent2
	go to fst1zx

chk0:	0 -> p
	if a[p] >= 1
	     then go to retnzx
fstpz5:	go to fstp

asmdz4:	jsb dsp0z4
	jsb chk0
	select rom 4

	no operation
	no operation

fstxzj:	a exchange c[w]
fst1zx:	jsb ofl3
fst1zj:	1 -> s7
fst2zx:	jsb dsp1
	jsb fst3
	go to den2

chs3:	0 - c - 1 -> c[s]
dsp1:	0 -> s10
	go to dsp7
dsp0z4:	shift right a[w]
dsp7:	c -> a[s]
	0 -> s8
	go to dsp8
dsp2:	c + 1 -> c[xs]
dsp3:	1 -> s8
	if s5 # 1
	     then go to dsp5
	c + 1 -> c[x]
	if no carry go to dsp2
dsp4:	display toggle
dsp5:	if s0 # 1
	     then go to dsp3
dsp8:	0 -> s0
dsp6:	p - 1 -> p
	if p # 12
	     then go to dsp6
	display off
	if s8 # 1
	     then go to dsp4
	shift left a[w]
	0 -> s5
	if s10 # 1
	     then go to tkra
	select rom 4

	no operation

ofl1:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	a + b -> a[x]
	if no carry go to ofl3
ofl2:	0 -> c[w]
ofl3:	clear status
	c -> a[w]
ofl4:	12 -> p
	a -> b[x]
	c -> a[x]
	if c[xs] = 0
	     then go to ofl5
	0 - c -> c[x]
	c - 1 -> c[xs]
	if no carry go to ofl1
ofl5:	a exchange c[x]
	if s4 # 1
	     then go to rnd0
	a exchange b[x]
	0 -> b[x]
	jsb dsp1
	if p # 12
	     then go to dsp0z4
	shift left a[x]
	go to eex3
eex2:	1 -> s4
	if s11 # 1
	     then go to dig1
eex3:	shift right a[w]
	a exchange c[wp]
	go to eex4

chs2:	shift right a[w]
	if s4 # 1
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

den5:	if s6 # 1
	     then go to den6
	p - 1 -> p
den6:	shift right b[wp]
	jsb eex4
eex7:	p - 1 -> p
	c + 1 -> c[x]
eex8:	if b[p] = 0
	     then go to eex7
	1 -> s11
	shift right a[ms]
	a exchange c[m]
	if s4 # 1
	     then go to den1
eex9:	jsb ofl4
	go to fst2zx

fst3:	0 -> a[ms]
fst4:	if s7 # 1
	     then go to fst5
	c -> stack
fst5:	1 -> s7
	0 -> c[w]
	c - 1 -> c[w]
	0 - c -> c[s]
	c + 1 -> c[s]
	b exchange c[w]
retnzx:	return

	.symtab

	.rom @04

prfx:	no operation
prfxz3:	go to pfx1

sci1:	go to sci2

tenx:	go to tnx2

logg:	go to log2

tnx3:	select rom 6

xtoy:	jsb save
	go to xty1

dpct:	go to dpc1

percz3:	go to pct1

dmst:	0 -> s8
tdms:	go to tdm1

stdd:	go to std1

dmsd:	select rom 0

fact:	jsb save
	go to fac2

tdm1:	jsb save
	go to dmsd

dig6:	go to dsp0
dig5:	go to dsp0
dig4:	go to dsp0

sig2:	select rom 5

addd:	no operation
adddz3:	go to amd1

tpolz0:	go to tpl3

	no operation

dig3:	go to dsp0
dig2:	go to dsp0
dig1:	go to dsp0

	no operation

mult:	no operation
multz3:	go to amd4

std1:	jsb sav1
	select rom 5

sigmz3:	go to sgma

dspt:	go to piii

dig0:	go to cons
	no operation

divdz3:	go to amd5

atn2:	1 -> s5
atan:	jsb sav9
	go to sqt1

acos:	go to acs1

asin:	go to atn2

trec:	go to trc1

tpolz3:	go to tpl1

sqrt:	jsb save
	go to sqt1

	no operation
	no operation

dig9:	a + 1 -> a[w]
dig8:	a + 1 -> a[w]
dig7:	if no carry go to con1

tpl6:	select rom 5

subt:	no operation
subtz3:	go to amd2

cler:	jsb save
	go to clr2

grad:	a + 1 -> a[w]
radn:	if no carry go to mode

clok:	no operation
	no operation
degr:	a - 1 -> a[w]
mode:	0 -> p
	go to shft

sqt1:	select rom 3

pct1:	jsb sav1
	0 -> s8
c100:	down rotate
	c -> stack
	c - 1 -> c[x]
	c - 1 -> c[x]
	if s8 # 1
mul0z3:	     then go to mul0
div0z3:	go to div0

acs1:	jsb sav9
	select rom 3

trc2:	select rom 3

shft:	shift left a[w]
	p + 1 -> p
	if p # 13
	     then go to shft
mrg0:	c exchange m
	a exchange c[p]
mreg:	c exchange m
	select rom 3

	no operation
	no operation

log2:	1 -> s5
	select rom 3

xty1:	jsb exch
	select rom 3

sci2:	0 -> s10
	select rom 3

sav9:	1 -> s1
	go to save

sav1:	1 -> s3
save:	1 -> s10
	select rom 6

savx:	select rom 6

adr9:	select rom 6

sav2:	1 -> s10
	1 -> s3
	go to savx

amd1:	1 -> s6
	1 -> s4
	go to amd7

amd2:	0 -> s6
amd3:	1 -> s4
	go to amd7

amd4:	1 -> s6
	go to amd6

con1:	a + 1 -> a[w]
cons:	select rom 6

piii:	select rom 6

amd5:	0 -> s6
amd6:	0 -> s4
amd7:	if s2 # 1
	     then go to amd8
	0 -> s10
	select rom 3

am13:	0 -> s10
	select rom 5

	no operation

amd9z3:	go to amd9

	no operation

fst1:	select rom 3

amd8:	jsb save
	stack -> a
	go to am13

dsp0:	0 -> s10
	go to dspx

pfx1:	1 -> s10
dspx:	0 -> s9
	select rom 3

exch:	stack -> a
exc1:	c -> stack
	a exchange c[w]
	return

amd9:	if s9 # 1
	     then go to am12
am10:	jsb sav1
am11:	a exchange c[w]
	go to am13

am12:	jsb sav2
	c -> data
	go to am11

trc1:	jsb sav9
	stack -> a
	1 -> s3
	0 -> s10
	go to trc2

dpc1:	jsb sav1
	down rotate
	c -> stack
	jsb sub1
	go to c100

	no operation
	no operation

rcxy:	select rom 5

tkraz3:	keys -> rom address

div0:	0 -> s3
	go to div1

mul0:	0 -> s3
mul1:	select rom 1

div1:	select rom 1

sub1:	0 - c - 1 -> c[s]
add1:	select rom 0

tpl1:	jsb sav9
	1 -> s3
	0 -> s4
	if c[s] = 0
	     then go to tpl2
	1 -> s4
tpl2:	down rotate
	jsb exc1
	if a[m] >= 1
	     then go to tpl6
	0 -> c[wp]
	c + 1 -> c[p]
	jsb tpl6

tpl3:	0 -> s1
	jsb exch
	c -> a[w]
	jsb mul1
	c -> data
	jsb rest
	jsb adr9
	jsb mul1
	data -> c
	jsb add1
	a - 1 -> a[xs]
	a - 1 -> a[xs]
	a - 1 -> a[xs]
	if no carry go to tpl5
	c - 1 -> c[xs]
	jsb reg9

tpl5:	c -> a[w]
	jsb sqt1
	go to reg9	

tnx2:	jsb save
	1 -> s2
	go to tnx3

rest:	0 -> c[w]
	c -> data address
	no operation
	data -> c
	return

sgma:	if s9 # 1
	     then go to sig1
	go to rcxy

sig1:	jsb sav1
	go to sig2

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

reg9:	select rom 0

	no operation
	no operation
	no operation

clr2:	select rom 5

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

retnzx:	return

fac2:	select rom 6

	.symtab

	.rom @05

err2:	select rom 6

adr5:	c + 1 -> c[p]
adr6:	c + 1 -> c[p]
adr7:	c + 1 -> c[p]
adr8:	c + 1 -> c[p]
adr9:	c + 1 -> c[p]
adr0:	a - c -> c[w]
	c -> data address
	no operation
	data -> c
	if s4 # 1
	     then go to retnzx
	a exchange c[w]
	if s8 # 1
	     then go to add1
	go to sub1

fst2:	select rom 3

	no operation
	no operation
	no operation
	no operation

pwo2z0:	go to pwo2

sgmaz4:	1 -> s4
	0 -> s10
	jsb mul1
	jsb adr6
	jsb stor
	jsb rest
	c -> a[w]
	jsb adr7
	go to sig1

	no operation
	no operation
	no operation

stddz4:	go to stdd

sig1:	jsb stor
	jsb yget
	jsb adr8
	jsb stor
	0 -> c[w]
	c + 1 -> c[p]
	c -> a[w]
	jsb adr5
	jsb stor
	go to fst2

rest:	0 -> c[w]
	c -> data address
	no operation
	data -> c
	return

yget:	down rotate
	c -> stack
	c -> a[w]
	return

tploz4:	0 -> s8
	0 -> s9
tpl0zj:	jsb div1

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

sqt1:	select rom 3

stdd:	0 -> s10
	0 -> s4
	jsb adr7
	c -> a[w]
	jsb mul1
	jsb adr5
	if c[s] >= 1
	     then go to err2
	jsb div1
	jsb adr6
	a exchange c[w]
	jsb sub1
	c -> stack
	jsb adr5
	a exchange c[w]
	0 -> c[w]
	c + 1 -> c[p]
	jsb sub1
	stack -> a
	jsb div1
	jsb sqt1
	c -> stack
	jsb adr7
	c -> a[w]
	jsb adr5
	jsb div0
rcxy:	0 -> s4
	if s7 # 1
	     then go to rxy1
	c -> stack
rxy1:	c -> a[w]
	jsb adr8
	c -> stack
	c -> a[w]
	jsb adr7
	go to fst1

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

am10:	jsb stor
	a exchange c[w]
	select rom 3

	no operation
	no operation
	no operation

amd0z4:	jsb dcod		; unsure of label
	if s9 # 1
	     then go to am10
fst1:	select rom 3

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

rcxyz4:	go to rcxy

div0:	0 -> s3
	go to div1

mul0:	0 -> s3
mul1:	select rom 1

div1:	select rom 1

sub1:	0 - c - 1 -> c[s]
add1:	select rom 0

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

dvof:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	select rom 2

dvofz2:	go to dvof

ofl1:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	a + b -> a[x]
	if no carry go to stor
	0 -> c[w]
stor:	c -> a[w]
ofl4:	12 -> p
	a -> b[x]
	c -> a[x]
	if c[xs] = 0
	     then go to ofl5
	0 - c -> c[x]
	c - 1 -> c[xs]
	if no carry go to ofl1
ofl5:	a exchange c[ms]
	data -> c
	a exchange c[w]
	c -> data
	return

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

dcod:	if s4 # 1
	     then go to dcd1
	if s6 # 1
	     then go to sub1
	go to add1

dcd1:	if s6 # 1
	     then go to div1
	go to mul1

pwo2:	0 -> c[w]
	c - 1 -> c[s]
	2 -> p
	load constant 2
	c exchange m
	0 -> c[w]
clr2:	0 -> a[w]
	12 -> p
clr3:	c - 1 -> c[p]
	c -> data address
	a exchange c[w]
	c -> stack
	c -> data
	a exchange c[w]
	c + 1 -> c[p]
	c + 1 -> c[p]
	if no carry go to clr3
	go to fst1

clr1z4:	0 -> c[w]
	load constant 6
	go to clr2

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

retnzx:	return

	.symtab

	.rom @06

factz4:	go to fact

err2z1:	go to errr

tdmsz0:	clear status
	go to tdmszj

oflw:	c + 1 -> c[xs]
	go to fst1

tenxzj:	jsb tnx3
errr:	0 -> c[w]
	clear status
	1 -> s5
rnd0z3:	c -> a[w]
	m -> c
	a exchange c[w]
	go to rndx

rnd3:	shift right a[ms]
	a + 1 -> a[x]
	if no carry go to rnd3
rnd4:	13 -> p
rnd5:	a exchange b[xs]
	a -> b[xs]
rnd6:	p - 1 -> p
	if p # 2
	     then go to rnd7
rnof:	0 -> a[w]
	a - 1 -> a[x]
rndx:	0 -> b[w]
	1 -> s8
	1 -> p
	a -> b[xs]
	c -> a[m]
	shift left a[ms]
	if a[p] >= 1
	     then go to rnd4
	0 -> s8
	14 -> p
	c -> a[x]
	if c[xs] >= 1
	     then go to rnd3
rnd1:	p - 1 -> p
	if p # 2
	     then go to rnd2
	go to rnof

rnd2:	a - 1 -> a[x]
	if no carry go to rnd1
	go to rnd5

rnd7:	a - 1 -> a[xs]
	if no carry go to rnd6
	a -> b[p]
	p - 1 -> p
	0 -> a[wp]
	c -> a[x]
	a + b -> a[ms]
	if no carry go to rnd8
	shift right a[ms]
	a + 1 -> a[s]
	a + 1 -> a[x]
	if s8 # 1
	     then go to rnd9
rnd8:	p + 1 -> p
rnd9:	shift right a[ms]
	0 -> b[ms]
	a - 1 -> a[xs]
	if a[xs] >= 1
	     then go to rn10
	go to rnof

rn10:	a + 1 -> a[xs]
	a exchange b[w]
	a + 1 -> a[p]
	a + 1 -> a[p]
rn11:	shift left a[ms]
	a - 1 -> a[xs]
	if no carry go to rn11
	0 -> a[wp]
	a - 1 -> a[wp]
	shift right a[ms]
	a exchange b[w]
	if s8 # 1
	     then go to rnrt
	a exchange c[x]
	0 -> b[x]
	if c[xs] = 0
	     then go to rtrn
	0 - c -> c[x]
	c - 1 -> c[xs]
rtrn:	a exchange c[x]
rnrt:	if s5 # 1
	     then go to ret3
	go to fst2

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

savezx:	go to save

sav2zx:	go to sav2

adr9z4:	c -> a[w]
	0 -> c[w]
	c - 1 -> c[p]
	c -> data address
	a exchange c[w]
	c -> a[w]
	go to svrt

	no operation
	no operation
	no operation
	no operation
	no operation
	no operation

consz4:	go to cons

piiiz4:	jsb push
	clear status
	select rom 1

push:	if s7 # 1
	     then go to pret
	c -> stack
pret:	0 -> c[w]
	return

	no operation

lstxzj:	0 -> s10
	jsb sav2zx
fst1:	select rom 3

tdmszj:	jsb rndx
fst2:	select rom 3

cons:	shift left a[w]
	shift left a[w]
	jsb push
	a - 1 -> a[xs]
	if no carry go to con7
	go to lstxzj

con7:	a - 1 -> a[xs]
	if no carry go to con8
	load constant 2
	load constant 5
	load constant 4
	go to fst1

con8:	a - 1 -> a[xs]
	if no carry go to con9
	load constant 4
	load constant 5
	load constant 3
	load constant 5
	load constant 9
	load constant 2
	load constant 3
	load constant 7
	c - 1 -> c[x]
	jsb fst1

con9:	load constant 3
	load constant 7
	load constant 8
	load constant 5
	load constant 4
	load constant 1
	load constant 1
	load constant 7
	load constant 8
	load constant 4
	go to fst1

sav2:	0 -> p
sav1:	shift left a[w]
	p + 1 -> p
	if p # 12
	     then go to sav1
	0 -> a[s]
	a exchange c[w]
	c -> data address
	0 -> s2
	data -> c
	a exchange c[w]
	0 -> s11
	0 -> b[w]
	if s1 # 1
	     then go to svrt
	go to adr9z4

save:	a -> b[w]
	a exchange c[w]
	0 -> c[w]
	c -> data address
	b -> c[w]
	a exchange c[w]
	c -> data
	go to sav2zx

fact:	if c[s] >= 1
	     then go to errr
	if c[xs] >= 1
	     then go to errr
fac0:	if c[x] >= 1
	     then go to fac1
	p - 1 -> p
	go to fact1
fac1:	p - 1 -> p
	if p # 3
	     then go to fac2
	go to oflw

fac2:	c - 1 -> c[x]
	jsb fac0
nrm20:	select rom 2

fact1:	if c[wp] >= 1
	     then go to errr
	a exchange c[x]
	11 -> p
	if c[x] = 0
	     then go to fact2
	c - 1 -> c[x]
	if c[x] >= 1
	     then go to oflw
	shift left a[w]
fact2:	a exchange c[w]
	0 -> a[w]
	a + 1 -> a[p]
	0 - c -> c[w]
	if no carry go to nrm20
	a exchange c[w]
	shift right c[w]
	c + 1 -> c[s]
fact3:	12 -> p
	a -> b[ms]
fact4:	a + c -> a[w]
	if no carry go to fact4
	a - c -> a[w]
	shift left a[w]
fact5:	a + c -> a[w]
	if no carry go to fact5
	a + 1 -> a[s]
	a exchange b[w]
	jsb shft
	11 -> p
	jsb shft
	b -> c[w]
	0 -> b[wp]
	shift right b[w]
	a exchange b[w]
	a + b -> a[ms]
	if no carry go to fact3
	a exchange c[w]
	b exchange c[x]
fact6:	c + 1 -> c[x]
fact7:	jsb nrm20
tnx3:	0 -> s8
	select rom 2

shft:	if b[p] = 0
	     then go to shfr
	shift right b[wp]
	a + 1 -> a[x]
shfr:	return

svrt:	if s10 # 1
	     then go to ret3
ret4:	select rom 4

ret3:	select rom 3

	no operation

	.symtab

	.rom @07

	.symtab

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


; HP-80 ROM source code from United States Patent 3,863,060
; Copyright 2004 Eric L. Smith <eric@brouhaha.com>
; $Id$
; Keyed in by Eric Smith on 15-Jan-2004 - any errors are probably mine.
; May not match released code in actual HP-80 calculators.
;
; Has not yet been checked.  Especially need to go over the Certificate
; of Correction to the patent.

	.rom @00

power1:	jsb power2
	go to erz
dig3:	a + 1 -> a[x]
dig2:	a + 1 -> a[x]
dig1:	a + 1 -> a[x]
	if no carry go to dig0
mul1:	stack -> a
	select rom 1
ms1:	down rotate
	go to ms2
ytx:	select rom 1
stor1:	go to stor2
rdown1:	down rotate
	go to owfl3	; $$$ target L0017 in listing wrong, actual L0117?
xey:	stack -> a
	go to xey1
	no operation
	no operation
dig6:	a + 1 -> a[x]
dig5:	a + 1 -> a[x]
dig4:	a + 1 -> a[x]
	if no carry go to dig3
pls1:	stack -> a
	select rom 1
fv1:	1 -> s11
	go to n1
pv1:	go to n1
pmt1:	1 -> s10
ror1:	go to n1
	return
n1:	if s7 # 1
	     then go to n2
	select rom 3
xey1:	select rom 1
sum1:	select rom 1
dp1:	1 -> s5
dig0:	select rom 1
	no operation
div1:	stack -> a
	select rom 1
date:	select rom 6
	no operation
sod1:	select rom 4
trnd1:	select rom 4
prc1:	stack -> a
	select rom 1
pre:	1 -> s7
	go to stor3
n2:	1 -> s7
	go to owfl3
dig9:	a + 1 -> a[x]
dig8:	a + 1 -> a[x]
dig7:	a + 1 -> a[x]
	if no carry go to dig6
min1:	0 - c - 1 -> c[s]
	jsb pls1
clr1:	0 -> c[w]
	jsb clr2
chs1:	go to chs2
rcl1:	if s8 # 1
	     then go to rcl3
	go to rcl4
enter1:	c -> stack
	0 -> s11
	0 -> s10
	0 -> s7
stor3:	0 -> s4
	go to owfl1	; $$$ target addr missing in listing
clr2:	if s7 # 1
	     then go to clr3
	if s4 # 1
	     then go to clr4
	go to clr3
clr4:	c -> stack
	c -> stack
	go to enter1
rcl3:	c -> stack
rcl4:	m -> c
owfl7:	0 -> s7
owfl3:	1 -> s4
owfl1:	0 -> s8
owfl4:	c -> a[w]
owfl5:	a -> b[w]
	12 -> p
	0 -> c[ms]
	c + 1 -> c[p]
	c + 1 -> c[p]
	if c[xs] = 0
	     then go to msk1
	0 - c - 1 -> c[x]
	if c[xs] = 0
	     then go to msk2
erz:	1 -> s5
	a + b -> a[xs]
	if no carry go to owfl2
	0 -> c[w]
	jsb owfl1
owfl2:	0 -> c[w]
	c - 1 -> c[wp]
	0 -> c[xs]
	a exchange c[s]
	go to owfl1
dis4:	0 -> s4
dis3:	0 -> s9
	12 -> p
dis5:	0 -> s0
dis6:	p - 1 -> p
	if p # 12
	     then go to dis6
	display off
	if s9 # 1
	     then go to dis7
	0 -> s5
	shift left a[x]
tkr:	keys -> rom address
dis9:	1 -> s9
	1 -> p
	if s5 # 1
	     then go to dis10
	c + 1 -> c[wp]
	if no carry go to dis9
dis7:	display toggle
dis10:	if s0 # 1
	     then go to dis9
	go to dis5
scint9:	a -> b[x]
	go to scint4
msk1:	jsb sround
	0 -> a[x]
	a + 1 -> a[x]	; $$$ extra "0" before a[x] in listing
	shift left a[x]
	a exchange b[w]
	if a >= b[x]	; $$$ was '<=' in listing
	     then go to scint9
	a -> b[x]
msk11:	a - 1 -> a[x]
	if no carry go to msk12
msk14:	if p # 3
	     then go to msk13
msk15:	select rom 1
msk28:	p - 1 -> p
	go to msk14
clr3:	0 -> s7
	0 -> s4
	go to owfl4
msk2:	c -> a[x]
	jsb sround
	a + 1 -> a[x]
msk21:	a - 1 -> a[x]
	if no carry go to msk22
msk13:	c - 1 -> c[x]
	if no carry go to msk28
	go to msk15
msk22:	shift right a[m]
	jsb msk21
msk12:	p - 1 -> p
	shift right c[m]
	jsb msk11
sround:	select rom 1
	return
ms2:	select rom 1
scint3:	if a >= b[xs]
	     then go to scint4
scint2:	a + 1 -> a[x]
	a - 1 -> a[xs]
scint4:	0 -> c[x]
	3 -> p
scint7:	if p # 12
	     then go to scint5
scint6:	b exchange c[w]
dis1:	0 -> s6
	jsb dis3
	0 -> a[ms]
dent1:	if s4 # 1
	     then go to dent2
	c -> stack
dent2:	0 -> s6
	go to dent3
power2:	clear registers
	clear status
	1 -> s2
	go to clr4
dent8:	a + 1 -> a[x]
	if b[m] = 0
	     then go to dent18
	if p # 3
	     then go to dent5
	0 -> c[w]
	c + 1 -> c[s]
	c + 1 -> c[s]
	13 -> p
dent5:	shift right c[wp]
dent19:	if b[m] = 0
	     then go to dent10
	12 -> p
	if a[p] >= 1
	     then go to dent10
	0 -> a[x]
dent11:	a - 1 -> a[x]
	if a[p] >= 1
	     then go to dent10
	shift left a[m]
	go to dent11
dent10:	a -> b[x]
	b exchange c[w]
	a exchange c[w]
	0 -> s5
	jsb dis4
	b exchange c[w]
	0 -> c[x]
	c + 1 -> c[ms]
dent12:	0 -> p
	c - 1 -> c[p]
dent4:	p + 1 -> p
	c - 1 -> c[p]
	if no carry go to dent6
	shift left a[wp]
	go to dent4
dent6:	a exchange b[x]
	a -> b[w]
	if s5 # 1
	     then go to dent7
	1 -> s6
	go to dent10
dent7:	if s6 # 1
	     then go to dent8
	p - 1 -> p
	if p # 2
	     then go to dent5
	go to dent19
dent18:	shift right c[w]
	b exchange c[w]
	jsb dis4
dent3:	0 -> c[w]
	0 -> b[w]
	13 -> p
	load constant 3
	0 -> s8
	c - 1 -> c[x]
	b exchange c[x]
	go to dent12
scint5:	if a[p] >= 1
	     then go to scint6	; $$$ source ahd label l0363, prob. bogus?
	c - 1 -> c[p]
	p + 1 -> p
	go to scint7
chs2: 	0 - c - 1 -> c[s]
	c -> a[s]
	c -> a[x]
	go to dis3
	no operation
	no operation
	no operation
stor2:	c exchange m
	m -> c
	go to stor3

	.symtab

	.rom @01

	no operation
	no operation
r3:	1 -> s1
r2:	go to r12
r1:	1 -> s1
	go to r13
xty:	0 -> s9
	select rom 2
smul11:	jsb mpy
	go to r13
sqr1:	select rom 2
xty11:	1 -> s8
	if s7 # 1
	     then go to xty12
	0 -> s7
	jsb sqr
	go to r13
retr4:	select rom 4
r6:	go to r11
r5:	1 -> s1
r4:	1 -> s3
	go to r13
xty12:	jsb xty
	go to r14
	0 -> s7
add11:	jsb add
	go to r13
dig10:	0 -> s7
	select rom 0
ret11:	return
dig11:	if s4 # 1
	     then go to dig14
	go to dig10
	no operation
xey:	go to msi7
sum11:	go to sum12
r0:	go to r13
	if s7 # 1
	     then go to dig10
	go to dig11
sdiv11:	0 -> s7
	go to di
prc2:	c -> stack
	if s7 # 1
	     then go to prc4
	go to prc3
prc11:	a exchange c[w]
	go to prc2
dig14:	clear status
tkrr1:	keys -> rom address
r9:	no operation
r8:	no operation
r7:	1 -> s1
r11:	1 -> s3
r12:	1 -> s2
	go to r13
prc3:	0 -> s7
	jsb sub
	down rotate
	c -> stack
	c - 1 -> c[x]
	c - 1 -> c[x]
di:	jsb div
	jsb r13
prc4:	jsb mpy
	c - 1 -> c[x]
	c - 1 -> c[x]
	jsb r13
r100:	down rotate
	c - 1 -> c[x]
	c - 1 -> c[x]
one:	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	a exchange c[w]
	go to rtn16
r14:	stack -> a
r13:	select rom 0
msk20:	0 -> c[s]
	0 -> c[xs]
	c + c -> c[p]
	if no carry go to msk16
	b -> c[wp]
	c + 1 -> c[w]
	if c[s] = 0
	     then go to msk16
	shift right c[ms]
	shift right b[ms]
msk16:	a exchange c[w]
	c -> a[s]
	go to mskr0
sum12:	if s7 # 1
	     then go to sum13
	if s4 # 1
	     then go to sum14
	select rom 3
r:	0 -> c[x]
	if s3 # 1
	     then go to rnd1
	c + 1 -> c[x]
	c + c -> c[x]
	c + c -> c[x]
rn3:	if s2 # 1
	     then go to rnd1
	if s1 # 1
	     then go to rnd3
	go to scin
sub:	0 - c - 1 -> c[s]
add:	a -> b[w]
add1:	a + 1 -> a[xs]
	a + 1 -> a[xs]
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a >= c[x]
	     then go to add4
	a exchange c[w]
add4:	if a[m] >= 1
	     then go to add2
	go to add7
add3:	shift right a[m]
	if a[m] >= 1
	     then go to add5
add7:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a exchange c[s]
	a - c -> a[s]
	if a[s] >= 1
	     then go to add8
	a + c -> a[ms]
	a - c -> a[s]
	select rom 2
add8:	a - c -> c[m]
	if no carry go to add9
	0 - c -> c[ms]
add9:	c -> a[m]
add10:	select rom 2
	no operation
	no operation
	no operation
	c + 1 -> c[p]
	0 -> c[x]
	c - 1 -> c[wp]
	b exchange c[w]
	a exchange c[w]
	p - 1 -> p
	go to msk20
	no operation
	no operation
	no operation
	no operation
rnd1:	if s1 # 1
	     then go to rnd2
	c + 1 -> c[x]
rnd2:	if s2 # 1
	     then go to rnd4
rnd3:	c + 1 -> c[x]
	c + 1 -> c[x]
rnd4:	select rom 0
	go to r
scin:	select rom 0
msi1:	down rotate
	if s7 # 1
	     then go to msi2
	0 -> s7
	jsb rot1
	c -> stack
	go to smul11	; $$$ was smull11 in listing
mskr0:	0 -> s6
	select rom 0
sum14:	0 - c - 1 -> c[s]
	0 -> s7
	1 -> s4
sum13:	stack -> a
	0 -> s8
	c -> stack
	jsb add
	down rotate
	c -> a[w]
	jsb mpy
	if s4 # 1
	     then go to sum16
	0 - c - 1 -> c[s]
sum16:	stack -> a
	c -> stack
	a exchange c[w]
	jsb one
	if s4 # 1
	     then go to sum15
	c - 1 -> c[s]
sum15:	jsb add
	down rotate
	stack -> a
	jsb add
	c -> stack
	down rotate
	down rotate
	go to r13
msi4:	jsb one
	jsb sub
	b exchange c[w]
	down rotate
	a exchange c[w]
	jsb div
	1 -> s8
	jsb sqr
	stack -> a
msi7:	c -> stack
	a exchange c[w]
	go to r13
csn:	down rotate
	down rotate
	0 - c - 1 -> c[s]
	down rotate
	down rotate
	go to rtn16
	no operation
rot1:	b exchange c[w]
	down rotate
	stack -> a
	b exchange c[w]
	c -> stack
	b -> c[w]
rtn16:	display off
	go to rtn9
rtn8:	if s4 # 1
	     then go to retr4	; $$$ most of line missing in listing
retr3:	select rom 3
div:	a exchange c[ms]
	go to div12
mpy:	select rom 2
div12:	a - c -> c[x]
	select rom 2
msi2:	stack -> a
	jsb rot1
	c -> stack
	a exchange c[w]
	jsb div
	down rotate
	jsb mpy
	stack -> a
	jsb sub
	jsb rot1
	go to msi4
rtn9:	if s7 # 1
	     then go to ret11
	go to rtn8
add2:	a exchange c[w]
add5:	if a >= c[x]
	     then go to add7
	a + 1 -> a[x]
	if no carry go to add3
sqr:	if c[m] >= 1
	     then go to sqr1
	return
	no operation		; $$$ line missing in listing

	.symtab

	.rom @02

err21:	select rom 0
pmu23:	a + b -> a[w]
pmu24:	c - 1 -> c[s]
	if no carry go to pmu23
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	go to pqo23
xty21:	stack -> a
	c -> stack
	a exchange c[w]
ln22:	0 -> a[w]
	1 -> s6
	a - c -> a[m]
	if no carry go to err21
	shift right a[w]
	c - 1 -> c[s]
	if no carry go to err21
ln25:	c + 1 -> c[s]
ln26:	a -> b[w]
	go to eca22
eca21:	shift right a[wp]
eca22:	a - 1 -> a[s]
	if no carry go to eca21
	0 -> a[s]
	a + b -> a[w]
	if s6 # 1
	     then go to exp29
	a - 1 -> a[p]
	if no carry go to ln25
	a exchange b[wp]
	shift left a[wp]
	a + b -> a[s]
	if no carry go to ln24
	7 -> p
	go to pqo23
pre23:	a + 1 -> a[x]
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
	0 -> s8
	go to pqo23
pqo15:	c + 1 -> c[s]
pqo16:	a - b -> a[w]
	if no carry go to pqo15
	a + b -> a[w]
pqo23:	b exchange c[w]
	0 -> c[w]
	c - 1 -> c[m]
	load constant 4
	c + 1 -> c[m]
pqo24:	shift right c[w]
	if p # 5
	     then go to exp35
	6 -> p
	0 -> a[wp]
	13 -> p
	b exchange c[w]
	a exchange c[w]
	load constant 6
	go to exp23
exp32:	if p # 11
	     then go to exp31
lnc2:	load constant 6
	load constant 9
	load constant 3
	load constant 1
	load constant 4
	load constant 7
	load constant 1
	load constant 8
	load constant 0
	load constant 5
	load constant 6
	11 -> p
	go to ln35
exp29:	a + 1 -> a[p]
exp22:	a -> b[w]
	c - 1 -> c[s]
	if no carry go to eca22
	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
exp23:	a exchange c[w]
	a - 1 -> a[s]
	if no carry go to exp22
	a exchange b[w]
	a + 1 -> a[p]
	if no carry go to nrm21
pqo21:	shift right c[ms]
	shift left a[w]
	go to pqo16
exp34:	if p # 9
	     then go to exp33
lncd2:	7 -> p
	load constant 3
	load constant 3
	load constant 0
	load constant 8
	load constant 5
	9 -> p
	go to ln35
exp33:	if p # 10
	     then go to exp32
lncd1:	9 -> p
	load constant 3
	load constant 1
	load constant 0
	load constant 1
	load constant 7
	load constant 9
	load constant 8
	load constant 1
	10 -> p
	go to ln35
mpy26:	a + b -> a[ms]
mpy27:	c - 1 -> c[p]
	if no carry go to mpy26
mpy28:	shift right a[w]
	p + 1 -> p
	if p # 13
	     then go to mpy27
	c + 1 -> c[x]
nrm21:	0 -> a[s]
	12 -> p
nrm23:	if a[p] >= 1
	     then go to nrm24
	shift left a[w]
	c - 1 -> c[x]
	if a[w] >= 1
	     then go to nrm23
	0 -> c[w]
nrm24:	a exchange c[x]
	c + c -> c[xs]
	if no carry go to nrm29
	a + 1 -> a[ms]
nrm29:	a exchange c[x]
	if a[s] >= 1
	     then go to mpy28
	a exchange c[m]
nrm25:	c -> a[w]
	if s8 # 1
	     then go to nrm26
	if s6 # 1
	     then go to exp31
	0 -> s6
	if s9 # 1
	     then go to xty32
	0 -> c[w]
	p - 1 -> p
	load constant 5
	go to mpy21
exp31:	if p # 12
	     then go to ln35
lnc10:	0 -> c[w]
	load constant 2
	load constant 3
	load constant 0
	load constant 2
	load constant 5
	load constant 8
	load constant 5
	load constant 0
	load constant 9
	load constant 3
	12 -> p
	a exchange c[w]
	if s6 # 1
	     then go to pre21
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
	display toggle
	11 -> p
	go to mpy27
pre21:	a -> b[w]
	c -> a[m]
	c + c -> c[xs]
	if no carry go to pre24
	c + 1 -> c[xs]
pre22:	shift right a[w]
	c + 1 -> c[x]
	if no carry go to pre22
	go to pre26
exp35:	if p # 8
	     then go to exp34
lncd3:	5 -> p
	load constant 3
	load constant 3
	8 -> p
ln35:	b exchange c[w]
	if s6 # 1
	     then go to pqo21
	shift right a[w]
	p + 1 -> p
	p + 1 -> p
	go to pmu24
nrm26:	select rom 1
pre27:	a + 1 -> a[m]
	if no carry go to pre25
ln24:	a exchange b[s]
	shift right c[ms]
	a + 1 -> a[s]
	if no carry go to ln26
xty32:	down rotate
	c -> stack
mpy21:	3 -> p
mpy22:	a + c -> c[x]
div21:	a - c -> c[s]
	if no carry go to div22
	0 - c -> c[s]
div22:	a exchange b[w]
	0 -> a[w]
	a -> b[s]
	if p # 12
	     then go to mpy27
	if b[m] = 0
	     then go to err21
div23:	a exchange c[wp]
	go to div15
div14:	c + 1 -> c[p]
div15:	a - b -> a[ms]
	if no carry go to div14
	a + b -> a[ms]
	shift left a[ms]
div16:	p - 1 -> p
	if p # 0
	     then go to div15
	c -> a[s]
	a exchange c[w]
	go to nrm21

	.symtab

	.rom @03

fvr47:	jsb one
	a exchange c[w]
	jsb div
	go to fvr48
xty:	1 -> s8
	select rom 1
ln:	0 -> s8
	go to sqr1
sqr:	1 -> s8
sqr1:	select rom 1
n46:	jsb mpy
	jsb one
	if s11 # 1
	     then go to n42
	jsb add
n44:	jsb ln
	down rotate
	jsb ln
	jsb one
	go to n48
fvr48:	stack -> a
	c -> stack
	jsb s12
	go to p47
fv40:	0 -> s11
	go to fv46
pv40:	go to pv41
pmt40:	go to pmt42
ror40:	go to fvr
	no operation
n40:	c -> a[w]
	down rotate
	go to n41
n5:	if s4 # 1
	     then go to selr4
tkrr3:	keys -> rom address
	no operation
cash1:	down rotate
	c exchange m
	down rotate
	c -> stack
	jsb r100
	jsb add
	stack -> a
	c -> stack
	a exchange c[w]
	jsb one
	jsb add
	jsb xty
	down rotate
	c -> stack
	down rotate
	down rotate
	a exchange c[w]
	jsb div
	m -> c
	jsb add
r13:	0 -> s10
	0 -> s11
	go to r14
	no operation
n42:	a exchange c[w]
	jsb sub
	a exchange b[w]
	jsb div
	go to n44
	no operation
r100:	select rom 1
pv41:	0 -> s11
	go to pv42
one:	select rom 1
pv46:	1 -> s11
pv42:	jsb csn
pv49:	jsb r100
	jsb add
	jsb rot1
	go to pv48
r14:	select rom 0
pv48:	jsb xty
	jsb one
	a exchange c[w]
pv43:	if s10 # 1
	     then go to pv44
	jsb sub
	down rotate
	down rotate
	down rotate
	if s11 # 1
	     then go to pv45
n48:	a exchange c[w]
pv45:	jsb div
	stack -> a
pv44:	stack -> a
	stack -> a
p47:	jsb mpy
	go to r13
cash:	if s10 # 1
	     then go to cash1
	0 -> s4
	select rom 4
fvr49:	c + 1 -> c[x]
	jsb div
	jsb one
	jsb add
	stack -> a
	go to fvr43
sub:	select rom 1
add:	select rom 1
add1:	select rom 1
fvr:	if s11 # 1
	     then go to fv42
	0 -> s11
	if s10 # 1
	     then go to fvr1
fvr3:	jsb csn
	0 - c - 1 -> c[s]
fvr2:	c -> stack
	stack -> a
	down rotate
fvr43:	jsb div
	c exchange m
	down rotate
	c -> stack
	jsb one
	jsb add
	a exchange b[w]
	jsb mpy
	c exchange m
	stack -> a
	c -> stack
	jsb csn
	down rotate
	jsb sub
	jsb add
	c exchange m
	jsb div
	c exchange m
fvr44:	down rotate
	c exchange m
	stack -> a
	jsb one
	jsb add
	c -> stack
	c -> stack
	b -> c[w]
	c exchange m
	jsb xty
	down rotate
	c -> stack
	jsb mpy
	b -> c[w]
	down rotate
	down rotate
	jsb div
	down rotate
	down rotate
	jsb one
	jsb sub
	m -> c
	jsb div
	down rotate
	down rotate
	jsb sub
	stack -> a
	c -> stack
	b exchange c[w]
	jsb add
	down rotate
	b exchange c[w]
	down rotate
	b exchange c[w]
	jsb div
	m -> c
	jsb mpy
	c exchange m
	jsb add
	c exchange m
	c -> a[w]
	jsb ten6
	if a[xs] >= 1
	     then go to fvr46
	go to fvr44
fvr9:	jsb mpy		; $$$ was fvr49 in listing
	jsb s12
	c + 1 -> c[x]
	1 -> s11
	go to fvr49
fvr1:	stack -> a
	a exchange c[w]
	jsb div
	stack -> a
	c -> stack
	a exchange c[w]
	jsb one
	a exchange c[w]
	jsb div
	jsb xty
	jsb one
	jsb sub
	c + 1 -> c[x]
	c + 1 -> c[x]
	jsb r13
pmt42:	if s11 # 1	; $$$ was pnt42 in listing
	     then go to pv46
fv46:	if s10 # 1
	     then go to pv49
	0 - c - 1 -> c[s]
	jsb pv49
	no operation
csn:	select rom 1
fvr46:	if s11 # 1
	     then go to r13
	down rotate
	down rotate
	down rotate
	go to fvr47
rot1:	select rom 1
s12:	0 -> c[w]
	c + 1 -> c[p]
	c + 1 -> c[s]
	c + c -> c[wp]
	shift right c[ms]
	c + 1 -> c[s]
	return
fv42:	if s10 # 1
	     then go to fvr4
	go to fvr2
div:	select rom 1
trn16:	return
mpy:	select rom 1
fvr4:	a exchange c[w]
	down rotate
	c -> stack
	c -> stack
	c -> stack
	go to fvr9
ten6:	m -> c
	c + 1 -> c[x]
	c + 1 -> c[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	return
selr4:	select rom 4
n41:	jsb div
	jsb r100	; $$$ was r1000 in listing
	jsb add
	down rotate
	stack -> a
	stack -> a
	b exchange c[w]
	a exchange c[w]
	if s10 # 1
	     then go to n44
	go to n46

	.symtab

	.rom @04

error:	select rom 0
	no operation
	no operation
xty:	select rom 3
retur1:	return
sod2:	jsb down3
	1 -> s7
	0 -> s4
	jsb one
	jsb add
	go to sod3
sta1:	stack -> a
	c -> stack
	return
down3:	down rotate
down2:	down rotate
	down rotate
	return
	if s5 # 1
	     then go to retur1
	select rom 5
sod:	if s7 # 1
	     then go to sod2
	go to sod6
fv:	go to error
	no operation
pv:	select rom 5
pmt:	go to dnote1
r:	1 -> s5
	select rom 5
n:	go to error
sod6:	if s4 # 1
	     then go to sod1
sod3:	down rotate
sod5:	0 -> s4
	stack -> a
	down rotate
	c -> a[w]
	jsb down2
	jsb sub
	jsb sta1
	jsb one
	go to sod4
depr:	go to sod
trnd1:	if s7 # 1
	     then go to trnd5
	if s4 # 1
	     then go to trnd3
	0 -> s4
	go to trnd8
trnd5:	1 -> s7
	if s4 # 1
	     then go to trnd4
	0 -> s4
	down rotate
	go to trnd2
r13:	select rom 3
l360:	a exchange c[w]
	0 -> c[w]
	load constant 3
	load constant 6
	c + 1 -> c[x]
	c + 1 -> c[x]
	return
dnote4:	jsb sub
	jsb sta1
	select rom 5
r100:	select rom 1
trnd6:	down rotate
	go to r13
one:	select rom 1
trnd4:	1 -> s7
	jsb sta1
	a exchange c[w]
	jsb one
	jsb add
	down rotate
	c -> stack
	jsb mpy
	down rotate
	b exchange c[w]
	down rotate
trnd9:	a exchange b[w]
	jsb add
	down rotate
	stack -> a
	jsb add
	c -> stack
	jsb down2
	go to r13
sod4:	jsb add
	m -> c
	jsb mpy
	jsb add
	jsb sta1
	b -> c[w]
	jsb mpy
	jsb sta1
	a exchange c[w]
	go to r13
inter:	c exchange m
	jsb r100
	m -> c
	a exchange c[w]
	c exchange m
	go to inter1
sub:	select rom 1
add:	select rom 1
add1:	select rom 1
trnd3:	jsb sta1
	c -> stack
	jsb div
	down rotate
	jsb one
	jsb add
	b -> c[w]
	down rotate
	jsb mpy
	stack -> a
	jsb div
	jsb add
	down rotate
	c -> stack
	jsb sub
	jsb add
	a exchange b[w]
	jsb add
	jsb down3
	jsb one
	jsb sub
	stack -> a
	jsb div
	jsb add
	down rotate
	a exchange b[w]
	jsb sub
	stack -> a
	jsb sta1
	b -> c[w]
	jsb mpy
	stack -> a
	jsb add
	0 - c - 1 -> c[s]
	c exchange m
	0 -> c[w]
	c -> stack
	m -> c
	c -> stack
	go to trnd6
trnd2:	jsb one
	jsb add
	c -> stack
	c -> stack
trnd8:	stack -> a
	stack -> a
	c -> a[w]
	jsb down2
	jsb mpy
	m -> c
	jsb add
	jsb sta1
	go to trnd6
inter1:	m -> c
	jsb div
	down rotate
	stack -> a
	jsb sub
	jsb sta1
	b -> c[w]
	jsb sub
	c exchange m
	jsb one
	jsb add
	c -> stack
	c exchange m
	jsb xty
	c exchange m
	jsb one
	jsb sub
	jsb sta1
	jsb mpy
	down rotate
	jsb one
	jsb add
	jsb sta1
	a exchange c[w]
	jsb xty
	stack -> a
	c exchange m
	jsb one
	jsb sub
	m -> c
	jsb mpy
	c exchange m
	jsb one
	jsb sub
	down rotate
	0 - c - 1 -> c[s]
	c -> stack
	jsb mpy
	down rotate
	stack -> a
	stack -> a
	c exchange m
	jsb sub
	m -> c
	jsb mpy
	go to r13
dnote3:	jsb mpy
	c exchange m
	stack -> a
	jsb sta1
	jsb l360
	12 -> p
	jsb div
	down rotate
	jsb l360
	load constant 5
	12 -> p
	jsb div
	jsb sta1
	jsb sub
	jsb down2
	stack -> a
	a exchange c[w]
	c -> stack
	go to dnote4
div:	select rom 1
	no operation
mpy:	select rom 1
ten6:	select rom 1
sod1:	0 -> s4
	c exchange m
	down rotate
	c -> stack
	c -> stack
	jsb one
	jsb add
	b exchange c[w]
	jsb mpy
	c exchange m
	a exchange c[w]
	jsb div
	c exchange m
	go to sod5
sel4:	keys -> rom address
dnote1:	0 -> s4
	c exchange m
	jsb r100
	a exchange c[w]
	c -> stack
	jsb div
	stack -> a
	down rotate
	c exchange m
	go to dnote3	; $$$ was dnote in listing

	.symtab

	.rom @05

	no operation
	no operation
xty:	select rom 4
s182:	down rotate
	c -> stack
	a exchange c[w]
	c -> stack
	0 -> c[w]
	load constant 1
	load constant 8
	load constant 2
	load constant 5
	load constant 0
s185:	c + 1 -> c[x]
	c + 1 -> c[x]
	12 -> p
retr5:	return
s180:	0 -> c[w]
	load constant 1
	load constant 8
	go to s185
	if s10 # 1
	     then go to sel6
	return
sel6:	select rom 6
	no operation
	no operation
bond1:	1 -> s5
	jsb one
	go to bond3
bondr1:	jsb sta1
	1 -> s11
	a -> b[w]
	c -> a[w]
	jsb add1
	a exchange b[w]
	jsb div
	c exchange m
	jsb r100
	a exchange c[w]
	jsb div
	jsb s182
	jsb div
	if c[xs] >= 1
	     then go to bondr2
	jsb down2
	m -> c
bon2:	down rotate
bondr3:	m -> c
	jsb one
	jsb add
	jsb sta1
	a exchange c[w]
	go to bondr7
dnote2:	stack -> a
r13:	0 -> s5
	select rom 3
down3:	down rotate
down2:	down rotate
	down rotate
	return
sta2:	down rotate
sta1:	stack -> a
	c -> stack
	return
	no operation
r100:	select rom 4
dnote5:	1 -> s5
	go to dnote6
one:	select rom 4
dnote6:	m -> c
	jsb mpy
	jsb r100
	a exchange c[w]
	jsb div
	jsb sta2
	m -> c
	jsb mpy
	jsb r100
	a exchange c[w]
	jsb div
	down rotate
	if s11 # 1
	     then go to dnote2
	go to r13
it1:	down rotate
	c -> a[w]
it2:	if a[xs] >= 1
	     then go to retr5
	a - 1 -> a[x]
	shift left a[m]
	go to it2
bondr2:	stack -> a
	m -> c
	jsb add
	jsb sta1
	jsb s180
	jsb div
	jsb one
	jsb sub
	b exchange c[w]
	c exchange m
	0 - c - 1 -> c[s]
	jsb mpy
	jsb one
	go to bondr8
sub:	select rom 1
add:	select rom 1
add1:	select rom 1
bond3:	c + c -> c[w]
	jsb div
	c exchange m
	jsb r100
	jsb s182
	jsb div
	if c[xs] >= 1
	     then go to bond2
	jsb sta2
	jsb one
	c + c -> c[w]
	a exchange c[w]
	jsb add
	b -> c[w]
	jsb div
	down rotate
	stack -> a
	down rotate
	0 - c - 1 -> c[s]
	jsb xty
	jsb it1
	a exchange c[w]
	jsb one
	jsb add
	jsb xty
	jsb down3
	jsb sta1
	jsb sub
	jsb add
	m -> c
	jsb mpy
	down rotate
	jsb s185
	down rotate
	c -> a[w]
	m -> c
	jsb mpy
	down rotate
	stack -> a
	jsb div
	stack -> a
	jsb add
	down rotate
	jsb sub
	go to r13
bond2:	jsb sta2
	jsb s180
	jsb div
	down rotate
	jsb mpy
	jsb one
	c + c -> c[w]
	jsb add
	c exchange m
	jsb one
	jsb s185
	jsb add
	b -> c[w]
	c exchange m
	jsb div
	jsb add
	jsb down3
	jsb one
	jsb sub
	c exchange m
	jsb mpy
	down rotate
	go to bondr6
bondr7:	jsb xty
	jsb one
	jsb sub
	jsb rot1
	jsb down3
	jsb sub
	jsb rot1
	down rotate
	a exchange c[w]
	jsb div
	m -> c
	jsb mpy
	jsb sta1
	jsb add
	stack -> a
	jsb down2
	b -> c[w]
	jsb sta2
	m -> c
	jsb add
	c exchange m
	b -> c[w]
	jsb s185
	jsb s185
	jsb s185
	if c[m] = 0
	     then go to bon1
	if c[xs] = 0
	     then go to bondr3
bon1:	if s11 # 1
	     then go to bondr4
	0 -> s11
 	down rotate
	c -> stack
	jsb it1
	a exchange c[w]
	jsb one
	jsb sub
	go to bondr9
rot1:	select rom 1
bondr8:	jsb add
	stack -> a
	jsb div
	jsb one
	jsb sub
	m -> c
	jsb div
	go to bondr5
	no operation
	no operation
div:	select rom 1
	no operation
mpy:	select rom 1
bondr9:	b -> c[w]
	jsb mpy
	m -> c
	jsb mpy
	jsb down2
	c -> a[w]
	jsb down2
	jsb mpy
	jsb one
	c + c -> c[w]
	a exchange c[w]
	jsb add
	b -> c[w]
	jsb div
	jsb sta1
	jsb mpy
	down rotate
	stack -> a
	jsb mpy
	c -> stack
	go to bon2
bondr4:	m ->c
bondr5:	jsb s185
	c -> a[w]
bondr6:	jsb add
	go to r13

	.symtab

	.rom @06

err71:	select rom 0
da8:	1 -> s4
	go to da12
dm6:	if p # 9
	     then go to dm7
	return
dm3:	a exchange b[w]
dm1:	if p # 2
	     then go to dm4
	a + 1 -> a[m]
	c - 1 -> c[m]
	if c[x] = 0
	     then go to dm2
	a + 1 -> a[m]
	c - 1 -> c[m]
dm2:	return
yc1:	load constant 3
	load constant 6
	load constant 5
	if s4 # 1
	     then go to yc2
	a + 1 -> a[x]
	return
yc2:	load constant 2
	load constant 5
	return
	no operation
	no operation
dd6:	jsb dm3
	a exchange b[w]
	a + c -> c[m]
dd8:	p - 1 -> p
	if p # 0
	     then go to dd6
	0 -> c[x]
	c -> a[w]
	if s7 # 1
	     then go to da4
dn1:	stack -> a
	a exchange c[w]
	go to dn3
	if s7 # 1
	     then go to da1
	if s4 # 1
	     then go to da3
da1:	0 -> s7
	c -> stack
	c -> stack
da3:	stack -> a
	if s7 # 1
	     then go to da13
	c -> stack
da13:	a exchange c[w]
	go to da5
dm5:	if p # 6
	     then go to dm6
	return
	no operation
da7:	a - c -> c[ms]
	if no carry go to da11
	0 - c -> c[ms]
da11:	b exchange c[w]
	stack -> a
	down rotate
	0 - c - 1 -> c[s]
	jsb add63
	0 -> a[s]
	0 -> c[w]
	5 -> p
	load constant 1
	load constant 8
	a exchange c[w]
	if a >= b[ms]
	     then go to da10
da9:	c -> stack
	b -> c[w]
add62:	jsb add61
	0 -> s5
	0 -> s7
	select rom 0
dd4:	p + 1 -> p
	c - 1 -> c[x]
	if no carry go to dd3
	a exchange c[w]
	if b[m] = 0
	     then go to err71
	jsb dm3
	a + c -> c[m]
	a exchange b[w]
	if s4 # 1
	     then go to dd5
	go to dd8
dd5:	if a >= b[m]
	     then go to dd8
	go to err71
dy1:	0 -> a[w]
	b exchange c[wp]
	jsb yc1
	8 -> p
	b exchange c[wp]
	go to mu3
da10:	b -> c[w]
	jsb add61
	go to da9
add61:	0 -> a[w]
add63:	1 -> s5
	1 -> s7
	12 -> p
	select rom 1
mu1:	a + b -> a[w]
mu2:	c - 1 -> c[p]
	if no carry go to mu1
mu3:	shift right b[w]
	p - 1 -> p
	if p # 3
	     then go to mu2
	a - 1 -> a[w]
	if no carry go to dy2
	a + 1 -> a[w]
dy2:	a + 1 -> a[x]
dd1:	p + 1 -> p
	shift right c[w]
	if p # 9
	     then go to dd1
	load constant 3
	4 -> p
	b exchange c[wp]
dd2:	shift right c[w]
	p - 1 -> p
	if p # 14
	     then go to dd2
	if c[x] = 0
	     then go to err71
dd3:	if p # 12
	     then go to dd4
	go to err71
	no operation
dm4:	if p # 4
	     then go to dm5
	return
dm7:	if p # 11
	     then go to dm8
	return
dm8:	a + 1 -> a[m]
	c + 1 -> c[m]
	return
da4:	c - 1 -> c[p]
	down rotate
	if s9 # 1
	     then go to da6
	if s4 # 1
	     then go to da8
	0 -> s9
	go to da12
dn2:	0 -> p
	shift right c[m]
dn3:	c + 1 -> c[p]
	if no carry go to dn2
	if c[x] >= 1
	     then go to err71
	if c[s] = 0
	     then go to dn4
	0 - c -> c[m]
dn4:	a + c -> a[ms]
	7 -> p
	0 -> c[w]
	load constant 7
	load constant 3
	load constant 0
	load constant 5
	if a >= c[ms]
	     then go to err71
	8 -> p
	jsb yc1
	0 -> b[w]
	b exchange c[w]
	if a[m] >= 1
	     then go to dn11
	go to err71
dn11:	a + 1 -> a[m]
dn15:	shift right b[w]
	p - 1 -> p
	go to dn6
dn5:	c + 1 -> c[p]
dn6:	a - b -> a[w]
	if no carry go to dn5
	a + b -> a[w]
	if p # 0
	     then go to dn15
	if a[m] >= 1
	     then go to dn12
	a + b -> a[w]
	c - 1 -> c[x]
dn12:	if c[x] >= 1
	     then go to dn7
	a - 1 -> a[w]
dn7:	4 -> p
	load constant 3
	0 -> p
	b exchange c[w]
	0 -> c[w]
	a exchange c[x]
dn8:	p + 1 -> p
	a + 1 -> a[x]
	0 -> c[m]
	jsb dm1
	a - b -> a[m]
	if no carry go to dn13
	go to dn14
dn13:	if a[m] >= 1
	     then go to dn8
dn14:	a + b -> a[m]
	a + c -> a[m]
	shift left a[m]
	a + 1 -> a[m]
	a exchange b[x]
	0 -> c[w]	; $$$ arrow missing in listing
	c - 1 -> c[xs]
	a + c -> a[w]
	a exchange b[w]
	13 -> p
dn9:	p - 1 -> p
	shift left a[w]
	if p # 7
	     then go to dn9
	a + b -> a[w]
dn10:	p + 1 -> p
	shift left a[w]
	if p # 12
	     then go to dn10
	a + 1 -> a[x]
	a exchange c[w]
	go to add62
da6:	if s4 # 1
	     then go to da7
da5:	0 -> s4
da12:	c - 1 -> c[x]
	if no carry go to da2
	shift right c[m]
	0 -> c[x]	; $$$ field selector missing in listing
da2:	if c[x] >= 1
	     then go to err71
	0 -> b[w]
	c -> a[w]
	8 -> p
	0 -> c[wp]
	load constant 2
	load constant 1
	8 -> p
	if a >= c[wp]
	     then go to err71
	load constant 1
	load constant 9
	8 -> p
	a - c -> c[wp]
	if no carry go to dy1

	.symtab

; HP-55 ROM sources from United States Patent 4,009,379
; Copyright 1995, 2003 Eric L. Smith <eric@brouhaha.com>
; $Id$
; Keyed in by Eric Smith on 8-Mar-1995 - any errors are probably mine.
; Five typos corrected on 30-Mar-2003, found by Peter Monta by OCRing
;     the listing in the patent
; May not match released code in actual HP-55 calculators.

; HP-55 ROM 00

	.arch classic

	.rom @00

	jsb start

mpy:	delayed select rom 5
	go to @117

stoy:	delayed select rom 2
	go to @173

ttx:	1 -> s5
etx:	12 -> p
	select rom 2

start0:	c + 1 -> c[p]
	jsb clr5
	12 -> p
start3:	load constant 5
	load constant 0
	if p # 14
	     then go to start3
	a exchange c[w]
	shift left a[w]
	12 -> p
	load constant 2
	load constant 3
	11 -> p
	go to start5

log:	jsb stox
	if s6 # 1
	     then go to ttx
log1:	1 -> s5
ln1:	1 -> s10
	1 -> s9
	12 -> p
	delayed select rom 2
	go to @002

ln:	jsb stox
	if s6 # 1
	     then go to etx
	go to ln1

start5:	c + 1 -> c[x]
start4:	c -> data address
	a exchange c[w]
	go to start6

sin0:	c -> stack
sin:	1 -> s5
	jsb rr
	go to tan

sqrt2:	0 -> s1
sqrt3:	0 -> s2
	12 -> p
	0 -> b[w]
	select rom 6

hmsa4:	a -> b[w]
	go to hmsa3

ofl:	delayed select rom 5
	go to @021

sqrt:	jsb tst9
	jsb stox
	if s4 # 1
	     then go to sqrt1
xsq:	c -> a[w]
	jsb mpy
	go to eof

mode:	6 -> p
	c exchange m
	return

con:	delayed select rom 2
	go to @0140

grd:	jsb mode
	load constant 9
	go to rad1

rcly:	delayed select rom 2
	go to @0150

	no operation

lstx:	jsb tst9
	if s7 # 1
	     then go to lstx1
	c -> stack
lstx1:	jsb rclx
	go to eof

ninty:	c -> a[w]
	0 -> c[w]
	12 -> p
	c - 1 -> c[p]
	c + 1 -> c[x]
	if no carry go to subout

	no operation

sqrt0:	go to sqrt

clr:	jsb clr0
	go to eof

	no operation

notgrd:	0 - c -> c[p]
	0 - c -> c[p]
	if no carry go to notrad
	c exchange m
	go to trig2

stox:	select rom 2

div:	delayed select rom 5
	go to @035

start:	jsb start1
	1 -> s6
	jsb clr0
	12 -> p
	go to start0

tst9:	select rom 5

hmsa2:	0 -> s5
	1 -> s4
	stack -> a
	jsb add
	jsb ofl
	go to hmsa4

trig1:	c exchange m
	6 -> p
	c + 1 -> c[p]
	c - 1 -> c[p]
	if no carry go to notgrd
	c exchange m
	a - 1 -> a[x]
	a - 1 -> a[x]
	jsb torad
again:	jsb rclx
	jsb mpy
	jsb ofl
	c -> stack
	jsb rcly
	stack -> a
	c -> stack
	a exchange c[w]
cos:	1 -> s9
	go to sin

tan:	c -> a[w]
	if s4 # 1
	     then go to trig1
trig2:	jsb rr
	jsb stoy
	go to trig3

sqrt1:	if c[s] >= 1
	     then go to err0
	jsb sqrt2

eof:	select rom 1

ehms:	if s5 # 1
	     then go to eof
	if s10 # 1
	     then go to hmsa2
	0 -> s10
	stack -> a
	c -> stack
	a -> b[w]
	go to hmsa3

deg:	jsb mode
	load constant 0
	go to rad1

rclx:	delayed select rom 2
	go to @216

start1:	clear status
	clear registers
clr0:	0 -> c[w]
clr5:	c + 1 -> c[x]
	12 -> p
	if s6 # 1
	     then go to clr1
	c + 1 -> c[p]
clr1:	11 -> p
clr2:	c -> data address
	b exchange c[w]
	c -> data
	c -> stack
	b exchange c[w]
	c + 1 -> c[p]
	if no carry go to clr2
	b -> c[w]
	return

notrad:	c exchange m
	jsb ninty
	jsb div
torad:	jsb hpi
	jsb mpy
	jsb ofl
	go to trig2

hmsa:	jsb stox
hmsadd:	if s4 # 1
	     then go to hmsa1
	0 - c - 1 -> c[s]
hmsa1:	0 -> s4
	1 -> s5
	1 -> s10
	no operation
	b exchange c[w]
hmsa3:	delayed select group 1
	select rom 2

rad:	jsb mode
	load constant 1
rad1:	c exchange m
	delayed select rom 2
	go to @023

pi:	jsb tst9
	if s7 # 1
	     then go to pi1
	c -> stack
pi1:	jsb hpi
	c + c -> c[w]
	if no carry go to eof

add:	delayed select rom 5
	go to @230

subout:	select rom 1

	no operation

hpi:	0 -> s1
	select rom 6

fto:	jsb rr
	if s10 # 1
	     then go to trig10
	if s9 # 1
	     then go to again
	jsb rclx
	jsb mpy
	no operation
trig10:	c -> stack
	0 -> s9
	jsb rcly
	go to eof

rr:	1 -> s3
	0 -> s11
	1 -> s8
	return

start6:	c -> data
	a exchange c[w]
	c + 1 -> c[p]
	if no carry go to start4
	clear registers
	go to start7

trig3:	stack -> a
	1 -> s1
	if s9 # 1
	     then go to satest
	go to sqrt3

msd:	select rom 4

satest:	a exchange c[w]
	0 -> c[x]
	0 -> p
	load constant 5
	0 - c -> c[x]
	a exchange c[w]
	if c[xs] = 0
	     then go to sqrt3
	if a >= c[x]
	     then go to sa
	go to sqrt3

sa:	c -> a[w]
	if s4 # 1
	     then go to fto
ito:	delayed select rom 3
	go to @215

start7:	10 -> p
	load constant 1
	7 -> p
	load constant 2
	delayed select rom 2
	go to @066

err0:	delayed select rom 3
	go to @302

	.symtab

; HP-55 ROM 01

	.rom @01

	1 -> s1
	go to eop

fix1:	0 -> c[xs]
	jsb fix2

	no operation

dec14:	c - 1 -> c[p]
	if no carry go to dec15

rs50:	jsb rr1
	if s8 # 1
	     then go to rs
rs52:	b -> c[w]
	go to rs51

switch:	delayed select rom 2
	go to @203

digent:	delayed select rom 5
	go to @135

decode:	c - 1 -> c[p]
	if no carry go to dec1
digit:	c exchange m
digit9:	if c[s] >= 1
	     then go to gtd
	c exchange m
	go to digit1

drr1:	if s3 # 1
	     then go to rr
	if s11 # 1
	     then go to drr4
dec16:	delayed select rom 5
	go to @316

dec1:	c exchange m
	if c[s] = 0
	     then go to dec1a
	jsb clpx1
dec1a:	c exchange m
	c - 1 -> c[p]
	if no carry go to dec2

r1:	jsb dec10
pct:	go to pct1

digit2:	if s1 # 1
	     then go to digent
fixdig:	a exchange c[w]
	c exchange m
	8 -> p
	0 - c -> c[xs]
	if no carry go to fxd1
	load constant 1
	go to fxd3

	no operation

dec2:	c - 1 -> c[p]
	if no carry go to dec3
	jsb dec10
fix:	go to fix4

eop1:	b -> c[w]
	go to eof1

ofl:	delayed select rom 5
	go to @021

eoo:	c exchange m
eop:	jsb rr
	if s9 # 1
	     then go to eop1
	go to eof1

digit1:	jsb tst46
	if s2 # 1
	     then go to digit2
	delayed select rom 3
	go to @366

dec3:	c - 1 -> c[p]
	if no carry go to dec4
r3:	jsb dec10
rcl:	jsb tst6
	jsb clpx
	c exchange m
	0 -> c[xs]
	c + 1 -> c[xs]
	1 -> s2
	go to eoo

stoy:	delayed select rom 2
	go to @173

mpy:	select rom 5

dec4:	c - 1 -> c[p]
	if no carry go to trans
r4:	jsb dec10
clx:	0 -> b[w]
	jsb tst46
	clear status
	go to eop

dp2:	if s7 # 1
	     then go to dp3
	b exchange c[w]
	c -> stack
dp3:	1 -> s9
	go to dp99

stox:	select rom 2

dec13:	c - 1 -> c[p]
	if no carry go to dec14
rr:	0 -> s8
rr1:	0 -> s3
	0 -> s11
	return

	no operation

tst9:	select rom 5

gtd:	c - 1 -> c[s]
	if c[s] = 0
	     then go to gtd2
gtd1:	a exchange c[w]
	c exchange m
	0 -> p
	c -> a[p]
	c + c -> c[p]
	if no carry go to gtd3
	a exchange c[p]
	c exchange m
	a exchange c[w]
	jsb clpx1
	go to digit9

dp99:	0 -> c[w]
	0 -> a[w]
	12 -> p
	c - 1 -> c[wp]
	c + 1 -> c[s]
	c + 1 -> c[s]
	b exchange c[w]
	go to dp4

pct1:	jsb tst9
	jsb stox
	jsb tst46
	stack -> a
	a exchange c[w]
	c -> stack
	c - 1 -> c[x]
	c - 1 -> c[x]
	jsb mpy
	go to eof

flip:	stack -> a
	c -> stack
	return

eof:	clear status
	jsb ofl
	1 -> s7
eof1:	delayed select group 1
	go to @201

sub:	delayed select rom 5
	go to @227

cb1:	if s4 # 1
	     then go to bch
	if c[m] >= 1
	     then go to nobch
bch:	c exchange m
	c -> a[x]
	1 -> p
bch1:	shift left a[w]
	p + 1 -> p
	if p # 4
	     then go to bch1
	a exchange c[wp]
	12 -> p
	if c[p] = 0
	     then go to bch2
	c - 1 -> c[m]
bch2:	c exchange m
	go to nobch

drr3:	if s11 # 1
	     then go to rom0
	go to drr5

dec10:	0 -> p
	c - 1 -> c[p]
	c - 1 -> c[p]
	if no carry go to dec11

drr2:	select rom 4

dec11:	c - 1 -> c[p]
	if no carry go to dec12

drr4:	select rom 2

dec12:	c - 1 -> c[p]
	if no carry go to dec13

drr5:	select rom 3

trans:	a exchange c[w]
	c exchange m
	a exchange c[x]
	0 -> s8
	go to gtd5

gtd7:	if s4 # 1
	     then go to bch
	go to gtd8

rs:	jsb tst9
	jsb clpx
rs51:	c exchange m
	delayed select group 1
	select rom 2

dec15:	c - 1 -> c[p]
	if no carry go to dec16

dp:	jsb tst6
dp10:	if s2 # 1
	     then go to dp5
dp12:	jsb switch
	2 -> p
	load constant 2
	if a >= c[xs]
	     then go to dp1
	a + c -> a[xs]
gtd3:	jsb switch
	go to eop

subout:	if s8 # 1
	     then go to drr1
	if s3 # 1
	     then go to drr2
	go to drr3

fxd1:	load constant 0
fxd3:	delayed select rom 2
	go to @154

rom0:	delayed select rom 0
	go to @330

tst46:	0 -> s8
	select rom 3

gtd2:	a exchange c[w]
	c exchange m
	shift left a[wp]
	0 -> p
	c -> a[p]
	a exchange c[w]
gtd5:	c exchange m
	a exchange c[w]
	jsb tst9
gtd4:	jsb stoy
	jsb flip
	if s6 # 1
	     then go to gtd7
gtd8:	jsb sub
	if s6 # 1
	     then go to cb1
	if c[s] = 0
	     then go to bch
nobch:	jsb flip
	a exchange c[w]
	jsb rcly
lvit:	delayed select rom 2
	go to @023

tst6:	0 -> s8
	select rom 3

	no operation

clpx1:	0 -> c[s]
clpx:	select rom 3

dp1:	jsb switch
dp5:	jsb clpx
	if s9 # 1
	     then go to dp2
dp4:	1 -> s7
	go to eop

rcly:	delayed select rom 2
	go to @150

fix4:	c exchange m
	if s6 # 1
	     then go to fix1
	0 -> c[xs]
	c + 1 -> c[xs]
fix2:	c exchange m
	jsb clpx

	.symtab

; HP-55 ROM 02

	.rom @02

con51:	jsb mpy
	go to con52

ln5:	if c[m] = 0
	     then go to error
	if c[s] >= 1
	     then go to error
	if s9 # 1
	     then go to zero
xty20:	1 -> s2
xty21:	c -> a[w]
	if s10 # 1
	     then go to exp22
	0 -> a[w]
	a - c -> a[m]
	shift right a[w]
	c - 1 -> c[s]
	select rom 7

add:	delayed select rom 5
	go to @230

lvit:	jsb rr
	jsb clpx
	b exchange c[w]
	go to eop

ytx1:	c -> stack
	a exchange c[w]
	1 -> s10
	12 -> p
	go to xty20

div:	select rom 5

xey1:	jsb tst9
	jsb tst46
	stack -> a
	c -> stack
	a exchange c[w]
	go to eof

con1:	delayed select group 1
	go to @270

ytx:	jsb tst9
	jsb stox
	jsb tst46
	stack -> a
	if a[s] >= 1
	     then go to err2
	if a[m] >= 1
	     then go to ytx1
	go to ln5

ld40:	0 -> c[w]
	12 -> p
	load constant 4
	c + 1 -> c[x]
	return

xey:	go to xey1

mpy:	delayed select rom 5
	go to @117

	c exchange m
	clear status
eop:	select rom 1

	no operation

zero:	a exchange c[w]
	go to eof
exp22:	if s5 # 1
	     then go to exp21
exp23:	delayed select rom 7
	go to @011

	no operation

exp21:	select rom 7

chs1:	b -> c[w]
	0 - c - 1 -> c[s]
	jsb lvit
g:	jsb clpx
	1 -> s4
	go to eop

	no operation

error:	if s9 # 1
	     then go to err2
	0 -> s9
	go to err0

err2:	a exchange c[w]
	c -> stack
err3:	a exchange c[w]
err0:	delayed select rom 3
	go to @302

chs:	jsb tst46
	jsb clpx
	if s9 # 1
	     then go to chs1
	a exchange c[w]
	if s10 # 1
	     then go to chs2
	0 - c - 1 -> c[xs]
	c -> a[w]
	delayed select rom 5
	go to @152

stox:	0 -> s1
stox1:	0 -> s2
	go to save

con:	jsb rr
	jsb switch
	0 -> p
	go to con0

tst9:	select rom 5

sqrt:	delayed select rom 0
	go to @053

	no operation

rcly:	1 -> s1
	go to rclx1

ofl:	delayed select rom 5
	go to @021

fxd3:	shift left a[w]
	p - 1 -> p
	if p # 0
	     then go to fxd3
	7 -> p
	a exchange c[p]
	c exchange m
	a exchange c[w]
	jsb rr
	jsb tst9
	go to lvit

	no operation
	no operation

sub:	delayed select rom 5
	go to @227

stoy:	1 -> s1
	go to stox1

pr:	a exchange c[w]
	delayed select rom 0
	go to @047

chs2:	0 - c - 1 -> c[s]
	c -> a[w]
	go to eop

switch:	c exchange m
	a exchange c[w]
	c exchange m
	go to subout

eof:	select rom 1

con50:	if s4 # 1
	     then go to con53
	jsb mpy
	go to eof

con53:	jsb div
	go to eof

rclx:	0 -> s1
rclx1:	1 -> s2
save:	b exchange c[w]
	0 -> c[w]
	c + 1 -> c[x]
	12 -> p
	load constant 2
	if s1 # 1
	     then go to save1
	load constant 1
save1:	c -> data address
	if s2 # 1
	     then go to save2
	data -> c
	if s1 # 1
	     then go to subout
	a exchange c[w]
	stack -> a
	a exchange c[w]
	data -> c
	c -> stack
save5:	b -> c[w]
	go to subout

rp1:	jsb div
	c -> stack
	c - 1 -> c[xs]
	if c[xs] = 0
	     then go to rp6
	go to rp11

	no operation

rr:	1 -> s3
	0 -> s11
	0 -> s8
	return

	no operation

rp11:	0 - c - 1 -> c[xs]
	if c[xs] = 0
	     then go to rp5
	c - 1 -> c[xs]
	if c[xs] >= 1
	     then go to rp10
	c - 1 -> c[xs]
rp5:	jsb mpy
rp10:	0 -> c[w]
	c + 1 -> c[p]
	jsb add
	jsb sqrt
rp6:	0 -> a[s]
	jsb rclx
	jsb mpy
	stack -> a
	c -> stack
	a exchange c[w]
	jsb ofl
	delayed select rom 0
	go to @201

save4:	b -> c[w]
	c -> data
subout:	select rom 1

save2:	if s1 # 1
	     then go to save4
	b -> c[w]
	a -> b[w]
	stack -> a
	a exchange c[w]
	c -> data
	c -> stack
	a exchange b[w]
	go to save5

	no operation

tst46:	select rom 3

con0:	c -> a[p]
	jsb switch
	jsb tst9
	jsb stox
	b exchange c[w]
	m -> c
	0 -> a[w]
	0 -> p
	c -> a[p]
	0 -> c[w]
	a - 1 -> a[x]
	if no carry go to con1

rp:	b -> c[w]
	jsb stoy
	stack -> a
	1 -> s10
	if s4 # 1
	     then go to pr
	if c[w] >= 1
	     then go to rp1
	if a[w] >= 1
	     then go to rp2
	c -> stack
	go to eof

rp2:	a -> b[w]
	delayed select rom 3
	go to @210

clpx:	select rom 3

conout:	a exchange b[w]
	if s5 # 1
	     then go to con50
	jsb ld40
	jsb add
	0 -> c[w]
	12 -> p
	load constant 1
	load constant 8
	if s4 # 1
	     then go to con51
	jsb div
con52:	jsb ld40
	jsb sub
	go to eof


	.symtab

; HP-55 ROM 03

	.rom @03

; wrapped around from end of rom 03

	go to sa1

	a exchange c[w]
	12 -> p
	load constant 1
	c + 1 -> c[x]
	c -> data address
	c exchange m
	a exchange c[w]
	c exchange m
	jsb tst9
	c exchange m
	c - 1 -> c[xs]
	if no carry go to sa2
store:	c exchange m
	c -> data
	go to eof

clock:	jsb rr
	jsb tst9
	delayed select group 1
	go to @077

rdn1:	jsb tst9
	jsb tst46
	down rotate
	go to eof

eex1:	jsb clpx
	if s9 # 1
	     then go to eex2
	b exchange c[w]
	if a[m] >= 1
	     then go to eex3
eex4:	12 -> p
	0 -> a[w]
	0 -> c[w]
	a + 1 -> a[p]
	c - 1 -> c[wp]
	load constant 2
	go to eex3

inv:	go to inv1

notgrd:	c - 1 -> c[p]
	c + 1 -> c[p]
	if no carry go to trig22
	c exchange m
	jsb ninty
	jsb mpy
togrd:	jsb hpi
	jsb div
	go to trig23

div:	delayed select rom 5
	go to @035

hpi:	delayed select rom 0
	go to @312

rdn:	go to rdn1

	no operation

eex3:	0 -> c[x]
	1 -> s10
eop0:	b exchange c[w]
eop:	select rom 1

sa7:	c - 1 -> c[xs]
	if no carry go to stodiv
stompy:	jsb sabeg
	jsb mpy
	go to saend

stodiv:	c exchange m
	if c[w] = 0
	     then go to err0
	jsb sabeg1
	jsb div
	go to saend

	no operation

sto:	go to sto1

ctda:	0 -> a[w]
	0 -> p
	c -> a[p]
ctda1:	shift left a[w]
	p + 1 -> p
	if p # 12
	     then go to ctda1
	a exchange c[w]
	c -> data address
	a exchange c[w]
	return

	no operation

eex:	if s6 # 1
	     then go to eex1
xft:	jsb tst9
	jsb stox
xft0:	delayed select group 1
	select rom 2

add:	delayed select rom 5
	go to @230

rcly:	delayed select rom 2
	go to @150

stox:	select rom 2

out3:	if s1 # 1
	     then go to out2
out5:	0 -> s9
out2:	if s2 # 1
	     then go to subout
	go to eof

	no operation

tst9:	select rom 5

sa5:	c - 1 -> c[xs]
	if no carry go to sa6
stoadd:	jsb sabeg
	jsb add
saend:	jsb ofl
	data -> c
	a exchange c[w]
	c -> data
	a exchange c[w]
	go to eof

rclx:	delayed select rom 2
	go to @216

sa4:	c - 1 -> c[xs]
	if no carry go to sa5

rcldp:	jsb ctda
recall:	c exchange m
	if s7 # 1
	     then go to recll1
	c -> stack
	go to recll1

inv1:	jsb tst9
	jsb stox
	jsb tst46
	if c[w] = 0
	     then go to err0
	0 -> a[w]
	12 -> p
	a + 1 -> a[p]
	jsb div
	go to eof

sa2:	c - 1 -> c[xs]
	if no carry go to sa3
	go to recall

recll1:	data -> c
eof:	select rom 1

rp2:	jsb rr
	jsb hpi
	if b[s] = 0
	     then go to ito
	c - 1 -> c[s]
ito:	jsb rr
	c -> stack
	c -> a[w]
	jsb rcly
	if s10 # 1
	     then go to trig20
	jsb rclx
	if c[s] = 0
	     then go to trig20
	jsb hpi
trig50:	c + c -> c[w]
	if a[s] >= 1
	     then go to trig21
	c - 1 -> c[s]
trig21:	jsb add
trig20:	a exchange c[w]
	c -> a[w]
	c exchange m
	6 -> p
	c + 1 -> c[p]
	c - 1 -> c[p]
	if no carry go to notgrd
	c exchange m
	a + 1 -> a[x]
	a + 1 -> a[x]
	jsb togrd

eex2:	if s7 # 1
	     then go to eex5
	b exchange c[w]
	c -> stack
eex5:	1 -> s9
	go to eex4

subout:	delayed select rom 1
	go to @311

rr:	1 -> s3
	1 -> s11
	1 -> s8
	return

sa3:	c - 1 -> c[xs]
	if no carry go to sa4

stodp:	jsb ctda
	go to store

sa6:	c - 1 -> c[xs]
	if no carry go to sa7
stosub:	jsb sabeg
	jsb sub
	go to saend

ofl:	delayed select rom 5
	go to @021

	no operation

err1:	jsb rr
	jsb rcly
	jsb rclx
err0:	c exchange m
	12 -> p
	0 -> c[p]
	c exchange m
	clear status
	1 -> s5
	go to eop0

trig22:	c exchange m
trig23:	jsb ofl
	0 -> s9
	if s10 # 1
	     then go to eof
	stack -> a
	c -> stack
	0 -> a[s]
	a exchange c[w]
	go to eof

mpy:	delayed select rom 5
	go to @117

tst46:	if s4 # 1
	     then go to tst6
yes:	select rom 0

	no operation

ninty:	delayed select rom 0
	go to @114

out:	if s2 # 1
	     then go to out3
	go to out5

sub:	delayed select rom 5
	go to @227

sabeg:	c exchange m
sabeg1:	c -> a[w]
	data -> c
	a exchange c[w]
	c -> data
	return

sto1:	jsb tst46
	jsb clpx
	c exchange m
	0 -> c[xs]
	1 -> s2
	c exchange m
	go to eop

	no operation

tst6:	if s6 # 1
	      then go to subout
	go to yes

clpx:	0 -> s6
	0 -> s2
	0 -> s4
	0 -> s1
	go to subout

sa:	jsb rr
	c exchange m
	a exchange c[w]
	c exchange m
	0 -> p
	c -> a[p]
	a exchange c[w]
sa1:	shift left a[w]
	p + 1 -> p
	if p # 11

; wraps back to top of rom 3


	.symtab

; HP-55 ROM 04

	.rom @04

; wrapped around from end of rom 04

	return

fit5:	jsb rclx
	jsb mpy
	stack -> a
	jsb add
	c -> stack
fit3:	jsb stat
	jsb r1
	c -> a[w]
	jsb mpy
	jsb r0
	jsb echk3
	jsb div
	jsb r2
	jsb sub
	if s6 # 1
	     then go to fit0
	jsb echk1
	jsb stk
	jsb stoy
lin11:	jsb stat
	jsb r5
	c -> a[w]
	jsb r1
	jsb mpy
	jsb stk
	jsb stat
	jsb r3
	c -> a[w]
	jsb r2
	jsb mpy
	stack -> a
	jsb sub
	jsb r0
	jsb div
	c -> stack
	go to lin12

sigp0:	delayed select rom 5
	go to @054

retin1:	if s7 # 1
	     then go to sigp
	c - 1 -> c[xs]
	if c[xs] >= 1
	     then go to sigp
recsig:	jsb exx
	jsb r3
	jsb stk
	jsb exx
	go to rsig1

stat:	a exchange c[w]
	go to exx

fit:	jsb tst9
	0 -> s4
	1 -> s7
	jsb stox
	jsb stoy
	go to fit3

n:	if s4 # 1
	     then go to n1
	0 -> s4
	jsb exx
	jsb r0
	0 -> a[w]
	a + 1 -> a[p]
	if no carry go to cumy

ofl:	delayed select rom 5
	go to @021

div:	delayed select rom 5
	go to @035

f:	jsb clpx
	1 -> s6
	go to eop

tst46:	delayed select rom 3
	go to @325

n1:	c -> stack
	jsb rcly
	go to ent2

retin:	go to retin1

mpy:	select rom 5

stk:	stack -> a
	c -> stack
	return

ent:	go to ent1

y1:	jsb why
	jsb r3
	1 -> s7
	go to cumy

x1:	jsb rclx
	jsb exx
	jsb r1
	1 -> s4
	go to cumy

stox:	select rom 2

stoy:	delayed select rom 2
	go to @173

echk3:	if c[s] >= 1
	     then go to err1
echk1:	if c[m] = 0
	     then go to err1
	return

tst9:	select rom 5

std:	0 -> a[w]
	a + 1 -> a[p]
	jsb sub
	jsb echk2
	jsb stk
	jsb stoy
	jsb stat
	jsb r3
	c -> a[w]
	jsb mpy
	jsb r0
	jsb div
	jsb r4
	jsb sub
	jsb stk
	go to fit3

lin0:	jsb r1
lin1:	jsb stk
	jsb rcly
	a -> b[w]
	jsb stk
	b -> c[w]
	a exchange c[w]
	jsb div
	if s4 # 1
	     then go to lin2
	0 -> c[s]
	jsb sqrt
lin2:	jsb ofl
	if s7 # 1
	     then go to eof
	0 -> s7
	go to lin1
rsig1:	jsb r1
eof:	select rom 1

lin12:	jsb stat
	jsb r1
	c -> a[w]
	jsb r3
	jsb mpy
	jsb r0
	jsb div
	jsb r5
	jsb sub
	if s7 # 1
	     then go to fit5
	jsb stk
	a exchange c[w]
	go to lin1

sub:	0 - c - 1 -> c[s]
add:	select rom 5

rcly:	delayed select rom 2
	go to @150

rclx:	delayed select rom 2
	go to @216

clpx:	delayed select rom 3
	go to @361

sqrt:	delayed select rom 0
	go to @053

why:	stack -> a
	a exchange c[w]
	c -> stack
exx:	c -> a[w]
	12 -> p
	return

fit0:	if s4 # 1
	     then go to fit1
	go to lin1

rr:	0 -> s3
	0 -> s11
	1 -> s8
	return

ent1:	jsb tst9
	jsb tst46
	c -> stack
ent2:	b exchange c[w]
	clear status
eop:	delayed select rom 1
	go to @071

r5:	c - 1 -> c[p]
r4:	c - 1 -> c[p]
r3:	c - 1 -> c[p]
r2:	c - 1 -> c[p]
r1:	c - 1 -> c[p]
r0:	a - c -> c[w]
	c -> data address
	no operation
	data -> c
	return

err1:	select rom 3

xy:	if s7 # 1
	     then go to n
	0 -> s7
	jsb rclx
	jsb exx
	jsb r5
	a exchange c[w]
	stack -> a
	go to xya

sigp:	jsb stoy
	0 -> s7
	1 -> s10
y2:	jsb why
	jsb r4
x2a:	a exchange c[w]
	c -> a[w]
xya:	jsb mpy
	data -> c
cumy:	a exchange c[w]
	if s6 # 1
	     then go to cumy1
	0 - c - 1 -> c[s]
cumy1:	jsb add
	jsb ofl
	c -> data
	if s10 # 1
	     then go to xy
	if s7 # 1
	     then go to y1
	if s4 # 1
	     then go to x1
x2:	jsb rclx
	jsb exx
	jsb r2
	0 -> s10
	go to x2a

fit1:	jsb echk1
	if s7 # 1
	     then go to fit2
	0 -> s7
	go to lin11

ms1:	jsb rr
	jsb tst9
	jsb stox
	jsb stoy
	1 -> s7
	jsb stat
	jsb r0
	if s6 # 1
	     then go to std
mean:	jsb echk3
	jsb stk
	jsb stoy
	jsb stat
	jsb r3
	jsb stk
	jsb stat
	go to lin0

fit2:	stack -> a
	jsb div
	c -> stack
	jsb rcly
	go to eof

echk2:	if c[s] = 0
	     then go to err1

; wraps back to top of rom 4
	.symtab

; HP-55 ROM 05

	.rom @05

ent10:	c - 1 -> c[w]
	if p # 3
	     then go to ent13
	go to ent14
ent13:	if s7 # 1
	     then go to ent12
	p - 1 -> p
ent12:	shift right c[wp]
ent14:	0 -> a[x]
	b exchange c[w]
	go to eop

ofl1:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	a + b -> a[x]
	if no carry go to halt
ofl2:	0 -> c[w]
ofl:	c -> a[w]
ofl4:	12 -> p
	a -> b[x]
	c -> a[x]
	if c[xs] = 0
	     then go to ofl5
	0 - c -> c[x]
	c - 1 -> c[xs]
	if no carry go to ofl1
ofl5:	a exchange c[x]
	c -> a[w]
	go to subout

div:	12 -> p
div2:	0 -> b[w]
	0 -> s1
	0 -> s2
div3:	delayed select rom 6
	go to @246

hpi1:	c + c -> c[w]
	if no carry go to subout
div1:	jsb setup
	if s2 # 1
	     then go to div9
	if c[xs] >= 1
	     then go to div9
	load constant 7
	go to add11

sigp:	jsb rr
	jsb tst9
	0 -> s7
	if s2 # 1
	     then go to sigp1
	1 -> s7
	go to sigp1

mpy1:	jsb setup
	if s2 # 1
	     then go to mpy9
	if c[xs] >= 1
	     then go to mpy9
	load constant 6
	go to add11

set8:	1 -> s8
ldis:	delayed select group 1
	select rom 1

mpy9:	c exchange m
	jsb tst9
	jsb tst6
	jsb stox
	stack -> a
	jsb mpy
	go to eof

	no operation

add1:	jsb setup
	go to add8

chk0:	c -> a[p]
	go to chk

sigp1:	0 -> s4
	jsb stox
	m -> c
	jsb sigp2
sigp2:	delayed select rom 4
	go to @251

mpy:	0 - c -> c[x]
	3 -> p
	go to div2

sub1:	jsb setup
	go to sub8

	no operation

ent2:	c -> a[wp]
	b exchange c[w]
	go to ent15

add10:	load constant 4
add11:	c exchange m
eop:	delayed select rom 1
	go to @071

stox:	select rom 2

digent:	1 -> p
	if s9 # 1
	     then go to ent1
	if s10 # 1
	     then go to ent2
	shift left a[wp]
	0 -> p
	go to chk0

tst9:	if s9 # 1
	     then go to tst9a
unw:	1 -> s7
	0 -> s9
	0 -> s10
chk:	a exchange c[w]
	if c[m] = 0
	     then go to ofl2
	c -> a[w]
	if c[xs] = 0
	     then go to unw7
	select rom 6

unw7:	0 -> b[x]
	a exchange b[x]
	13 -> p
unw8:	if b[p] = 0
	     then go to unw1
unw5:	a - 1 -> a[x]
	p - 1 -> p
	if p # 2
	     then go to unw3
	go to unw9

div9:	c exchange m
	jsb tst9
	jsb stox
	if c[w] = 0
	     then go to err0
	stack -> a
div10:	jsb div
eof:	select rom 4

tst6:	delayed select rom 3
	go to @356

setup:	2 -> p
	c exchange m
	return

err0:	delayed select rom 3
	go to @302

sub8:	if s2 # 1
	     then go to sub9
	if c[xs] = 0
	     then go to sub10
sub9:	c exchange m
	jsb tst9
	jsb tst6
	jsb stox
	stack -> a
	jsb sub
	go to eof

sub10:	load constant 5
	go to add11

sub:	0 - c - 1 -> c[s]
add:	0 -> s1
	0 -> s2
	12 -> p
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
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	     then go to add7
	go to add6

unw3:	if c[p] >= 1
	     then go to unw9
	shift left a[m]
	go to unw5

add8:	if s2 # 1
	     then go to add9
	if c[xs] = 0
	     then go to add10
add9:	c exchange m
	jsb tst9
	jsb tst6
	jsb stox
	stack -> a
	jsb add
	go to eof

add7:	select rom 6

unw1:	p - 1 -> p
	if c[p] >= 1
	     then go to unw2
	shift left a[m]
	go to unw8

tst9a:	b exchange c[w]
	if c[m] >= 1
	     then go to subout
	0 -> c[w]
subout:	select rom 1

unw2:	if b[p] = 0
	     then go to unw4
unw9:	a + c -> a[x]
	a exchange c[w]
	go to isit

rr:	1 -> s3
	1 -> s11
	0 -> s8
	return

halt:	c exchange m
halt1:	0 -> c[p]
	c exchange m
	go to ofl

qpi1:	if s1 # 1
	     then go to hpi1
	select rom 6

	12 -> p
	go to qpi1

unw4:	a + 1 -> a[x]
	p - 1 -> p
	go to unw2

isit:	a exchange b[x]
isit1:	0 -> b[x]
	if s9 # 1
	     then go to ofl
	if c[xs] = 0
	     then go to eop
	0 - c -> c[x]
	if c[xs] = 0
	     then go to eop
neg:	jsb rr
	jsb unw
	go to eof

ent1:	b exchange c[w]
	1 -> s9
	if s7 # 1
	     then go to ent5
	0 -> s7
	c -> stack
ent5:	a exchange b[wp]
	0 -> a[s]
	0 -> c[w]
	c - 1 -> c[w]
	0 - c -> c[s]
	c + 1 -> c[s]
ent15:	c + 1 -> c[w]
ent11:	if c[p] >= 1
	     then go to ent10
	shift left a[wp]
	p + 1 -> p
	go to ent11

slrn3:	jsb rr
	jsb tst9
	b exchange c[w]
	go to set8
	.symtab

; HP-55 ROM 06

	.rom @06

; wrapped around from end of rom 06

	go to tan13
tan15:	a exchange b[w]
	jsb tnm11
	stack -> a
	jsb tnm11
	stack -> a
	if s9 # 1
	     then go to tan16
	a exchange c[w]
tan16:	if s5 # 1
	     then go to asn12
	0 -> c[s]
	jsb div11
asn11:	c -> stack
	jsb mpy11
	jsb add10
	jsb sqt11
	stack -> a
asn12:	jsb div11
	if s4 # 1
	     then go to tout
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

sin11:	c -> a[w]
	if s1 # 1
	     then go to sqt11
	if s4 # 1
	     then go to lpi11
	if s5 # 1
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
	jsb atc1
	c + c -> c[w]
	jsb div11
	if s9 # 1
	     then go to atn19
	0 - c - 1 -> c[s]
	jsb add10
atn19:	jsb atc1
	c + c -> c[w]
	jsb mpy11
itout:	delayed select rom 3
	go to @215

	0 - c -> c[x]
	delayed select rom 7
	go to @016

tout:	delayed select rom 0
	go to @314

lpi11:	jsb atc1
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
rtn11:	if s1 # 1
	     then go to rtn12
	return

add10:	0 -> a[w]
	a + 1 -> a[p]
add11:	select rom 5

pmu11:	select rom 7

pqo11:	shift left a[w]
pqo12:	shift right b[ms]
	b exchange c[w]
	go to pqo16

pqo15:	c + 1 -> c[s]
pqo16:	a - b -> a[w]
	if no carry go to pqo15
	a + b -> a[w]
pqo13:	select rom 7

mpy11:	select rom 7

div11:	a - c -> c[x]
	select rom 7

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
	select rom 3

add12:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] >= 1
	     then go to add13
	select rom 7

add13:	if a >= b[m]
	     then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
add15:	select rom 7

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
	select rom 5

	return

rtn12:	select rom 3

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

pre11:	select rom 7

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

; wraps back to top of rom 6
	.symtab

; HP-55 ROM 07

	.rom @07

	no operation

ln24:	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to ln26

xty22:	stack -> a
	jsb mpy21
xty21:	select rom 2

	jsb lnc10
	0 -> b[w]
	jsb mpy21
	c -> a[w]
	go to exp21
	c - 1 -> c[xs]
	delayed select rom 5
	go to @161

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
rtn21:	select rom 6

eca21:	shift right a[wp]
eca22:	a - 1 -> a[s]
	if no carry go to eca21
	0 -> a[s]
	a + b -> a[w]
	return

pqo21:	select rom 6

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
	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	if no carry go to nrm25
	no operation
div23:	b exchange c[wp]
	a exchange c[m]
	select rom 6

lnc2:	0 -> s10
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

; HP-55 ROM 10

	.rom @10

bst:	select rom 1
rs1:	c + 1 -> c[p]
pct:	c + 1 -> c[p]
inv:	c + 1 -> c[p]
ytx:	c + 1 -> c[p]
	no operation
sig:	c + 1 -> c[p]
	if no carry go to r1

gto:	c exchange m
	go to gto1
rcl:	c + 1 -> c[p]
sto:	c + 1 -> c[p]
g:	c + 1 -> c[p]
	no operation
f:	c + 1 -> c[p]
	if no carry go to r3

prog2:	delayed select rom 1
	go to @343
six:	c + 1 -> c[p]
fiv:	c + 1 -> c[p]
fou:	c + 1 -> c[p]
	if no carry go to thr
add:	load constant 8
	go to r3

gto1:	delayed select rom 1
	go to @143
thr:	c + 1 -> c[p]
two:	c + 1 -> c[p]
one:	c + 1 -> c[p]
	if no carry go to r0
mpy:	load constant 8
	go to r2

	no operation
dp1:	c + 1 -> c[p]
	if no carry go to rs1
dp:	go to dp1
zer:	go to r0
	no operation
div:	load constant 8
	go to r1

sst:	1 -> s5
	go to bst
fmt:	c + 1 -> c[p]
rdn:	c + 1 -> c[p]
xey:	c + 1 -> c[p]
	no operation
fit:	c + 1 -> c[p]
	if no carry go to r2

dis30:	shift right a[m]
	jsb dis31
nin:	c + 1 -> c[p]
eig:	c + 1 -> c[p]
sev:	c + 1 -> c[p]
	if no carry go to six
sub:	load constant 8
	go to r4

clx:	c + 1 -> c[p]
	no operation
eex:	c + 1 -> c[p]
chs:	c + 1 -> c[p]
	no operation
	no operation
ent:	c + 1 -> c[p]
r4:	c + 1 -> c[xs]
r3:	c + 1 -> c[xs]
r2:	c + 1 -> c[xs]
r1:	c + 1 -> c[xs]
r0:	1 -> p
	if s3 # 1
	     then go to run
prog:	c -> a[x]
	c exchange m
	if c[s] = 0
	     then go to stff
	c - 1 -> c[s]
	if c[s] = 0
	     then go to prog2
	c exchange m
	0 -> c[x]
	load constant 5
	if a >= c[x]
	     then go to stff10
	a + c -> a[x]
	a - c -> c [x]
	shift right a[ms]
	shift left a[x]
	shift left a[w]
	c -> a[x]
	0 -> c[w]
	c - 1 -> c[ms]
	c - 1 -> c[p]
	no operation
prog3:	a - 1 -> a[xs]
prog1:	5 -> p
	load constant 0
	load constant 2
	0 -> a[s]
	b exchange c[w]
wat0:	11 -> p
	c exchange m
	0 -> c[p]
wat1:	0 -> s0
wat2:	p - 1 -> p
	if p # 11
	     then go to wat2
	display off
	if c[p] = 0
	     then go to wat3
	if s5 # 1
	     then go to wat13
	go to srun
wat13:	c exchange m
	if s9 # 1
	     then go to wat14
tkr:	1 -> p
	0 -> c[x]
	keys -> rom address
wat14:	b exchange c[w]
	go to tkr

wat3:	display toggle
wat7:	if s0 # 1
	     then go to wat4
	go to wat1

wat4:	0 -> c[p]
	c + 1 -> c[p]
	0 -> s3
	0 -> s11
	rom address -> buffer
wat6:	if s5 # 1
	     then go to wat5
	p - 1 -> p
	if p # 11
	     then go to wat6
	c + 1 -> c[s]
	if no carry go to wat6
	go to wat3

dis1:	a + c -> a[wp]
	a - c -> a[wp]
	if no carry go to dis17
	13 -> p
dis31:	a + 1 -> a[x]
	if no carry go to dis30
	go to dis76

	no operation

srun:	0 -> c[s]
	c exchange m
	clear status
	1 -> s7
disp:	if s9 # 1
	     then go to dis99
dis70:	0 -> s8
	go to wat0
dis99:	c -> a[w]
	m -> c
dis50:	a -> b[w]
	1 -> s9
	8 -> p
dis0:	p - 1 -> p
	shift right c[w]
	if p # 1
	     then go to dis0
	if c[p] >= 1
	     then go to dis2
	if a[xs] >= 1
	     then go to dis1
	if a[p] >= 1
	     then go to dis17
	13 -> p
dis10:	p - 1 -> p
	a - 1 -> a[x]
	if no carry go to dis10
	go to dis76

dis71:	0 -> s9
	go to dis70

run:	shift right c[x]
	select rom 1

inrun:	if s8 # 1
	     then go to wat7
	go to srun

dis2:	0 -> s9
	0 -> c[p]
	12 -> p
dis76:	0 -> c[ms]
	c + 1 -> c[p]
	c + 1 -> c[p]
dis11:	p - 1 -> p
	if p # 2
	     then go to dis12
	0 -> c[x]
	a exchange c[w]
	if s9 # 1
	     then go to dis62
	a - 1 -> a[x]
	jsb dis62

dis53:	c + 1 -> c[p]
	if no carry go to dis15
	go to dis54

dis12:	c - 1 -> c[x]
	if no carry go to dis11
	0 -> c[wp]
	c - 1 -> c[wp]
	a exchange c[w]
	c + c -> c[p]
	if no carry go to dis15
dis54:	p + 1 -> p
	if p # 13
	     then go to dis53
	p - 1 -> p
	0 -> c[m]
	c + 1 -> c[p]
	if s9 # 1
	     then go to dis60
	shift right a[ms]
	a - 1 -> a[x]
dis60:	c + 1 -> c[x]
dis65:	a + 1 -> a[x]
dis62:	c + 1 -> c[xs]
	if no carry go to dis63
	0 - c -> c[x]
dis61:	a exchange c[w]
	b exchange c[w]
	go to dis71

dis63:	c - 1 -> c[xs]
	if c[xs] = 0
	     then go to dis61
dis17:	a exchange b[w]
	m -> c
	8 -> p
	load constant 1
	load constant 9
	go to dis50

stff10:	c exchange m
stff:	select rom 1

wat5:	if s11 # 1
	     then go to rop
	jsb futz
inclk:	select rom 3

rop:	if s3 # 1
	     then go to inrun
inlrn:	if s8 # 1
	     then go to slrn
	go to wat7

futz:	0 -> c[s]
	c exchange m
	if s9 # 1
	     then go to futz1
	return

futz1:	b exchange c[w]
	return

slrn:	jsb futz
slrn2:	delayed select group 0
	select rom 5

dis15:	if s9 # 1
	     then go to dis65
	0 -> c[xs]
	jsb dis62
	.symtab

; HP-55 ROM 11

	.rom @11

	no operation

bst1:	c exchange m
	if s3 # 1
	     then go to bstr
	c -> a[w]
	0 -> c[w]
	c + 1 -> c[m]
	4 -> p
	if s5 # 1
	     then go to bst2
	0 -> s5
	a + c -> a[wp]
sst2:	a exchange c[w]
	c exchange m
	go to ldis

bst2:	a - c -> a[wp]
	jsb sst2

ldis4:	1 -> p
	a exchange c[w]
	if c[p] = 0
	     then go to ldis6
	0 - c - 1 -> c[x]
	0 -> c[xs]
ldis6:	c -> a[x]
	go to ldis5

pkx1:	shift right c[w]
	p - 1 -> p
	go to pkx2

ldis2:	shift right c[w]
	p - 1 -> p
	go to ldis1

bstr:	if s5 # 1
	     then go to bstr1
sstr:	0 -> s5
	go to sstr1

skc2:	a - c -> a[wp]
	if no carry go to skc1
	12 -> p
	0 -> c[wp]
	c - 1 -> c[wp]
	4 -> p
	go to skc50

	no operation

ikc12:	0 -> c[x]
ikc3:	if p # 1
	     then go to ikc2
ikc5:	if c[x] = 0
	     then go to ikc4
	c - 1 -> c[x]
	p + 1 -> p
	go to ikc5

ikc2:	c + 1 -> c[x]
	shift left a[w]
	p - 1 -> p
	go to ikc3

ikc4:	data -> c
	a exchange c[p]
	p - 1 -> p
	a exchange c[p]
	c -> data
	jsb fix
ldis:	jsb skc
	data -> c
ldis1:	if p # 1
	     then go to ldis2
	go to ldis49

ldis51:	c -> a[x]
	0 -> c[x]
	1 -> p
	load constant 5
	0 -> a[xs]
	a - c -> a[x]
	if no carry go to ldis3
	a + c -> a[x]
	shift right c[x]
	if a >= c[p]
	     then go to ldis4
	go to ldis5

ldis3:	a - 1 -> a[xs]
ldis5:	m -> c
	c -> a[m]
	shift left a[m]
	0 -> c[w]
	c - 1 -> c[ms]
	c + 1 -> c[x]
	if s11 # 1
	     then go to ldis9
	0 -> c[x]
ldis9:	c - 1 -> c[x]
	c exchange m
	0 -> c[s]
	c exchange m
ldis10:	select rom 0

clpx:	0 -> c[s]
	0 -> s6
	0 -> s4
clpx1:	0 -> s2
	0 -> s1
	return

gto1:	0 -> c[s]
	c + 1 -> c[s]
	c + 1 -> c[s]
	c exchange m
	if s3 # 1
	     then go to gtorun
	m -> c
	c + 1 -> c[m]
	c -> a[m]
	4 -> p
	c + c -> c[p]
	if no carry go to gto3
	load constant 0
	load constant 0
	go to stff2

gto3:	shift left a[m]
	0 -> c[w]
	c - 1 -> c[w]
	0 -> c[xs]
	0 -> a[xs]
	a - 1 -> a[xs]
	jsb ldis10

ldis49:	if s11 # 1
	     then go to ldis50
	go to ldis51

gtorun:	jsb clpx1
eop:	if s9 # 1
	     then go to eop1
	go to eof
eop1:	b exchange c[w]
eof:	c exchange m
eof7:	12 -> p
	if s8 # 1
	     then go to eof8
go_:	11 -> p
	0 -> s0
	if s0 # 1
	     then go to eof2
	if c[p] >= 1
	     then go to eof3
	12 -> p
	go to stop1

eof8:	if c[p] = 0
	     then go to stop1
	c + 1 -> c[m]
	c + 1 -> c[p]
	c - 1 -> c[p]
	if no carry go to go_
stop1:	0 -> c[p]
	c exchange m
	delayed select rom 0
	go to @224

eof2:	0 -> c[p]
eof3:	display toggle
	c exchange m
	if s9 # 1
	     then go to go1
	go to go2

sstr1:	12 -> p
	load constant 9
	c exchange m
	go to go2

bstr1:	jsb clpx
	4 -> p
	0 -> c[wp]
	c exchange m
	go to eop

go1:	b exchange c[w]
go2:	jsb skc
	if s11 # 1
	     then go to go4
	delayed select group 0
	go to @007

go4:	data -> c
pkx2:	if p # 1
	     then go to pkx1
	jsb fix
run:	1 -> p
decode:	delayed select group 0
	go to @020

skc50:	a exchange c[wp]
	c -> a[wp]
	15 -> p
skc3:	p - 1 -> p
	p - 1 -> p
	c + 1 -> c[m]
	if no carry go to skc3
	shift right c[w]
	c + 1 -> c[s]
	c + 1 -> c[s]
	shift right c[w]
	0 -> c[x]
	c + 1 -> c[x]
	c -> data address
	0 -> c[x]
	c - 1 -> c[x]
	c - 1 -> c[x]
	c - 1 -> c[x]
	a exchange c[w]
	shift left a[x]
	0 -> a[xs]
	shift left a[w]
	shift left a[w]
	a exchange c[w]
	c - 1 -> c[s]
	c - 1 -> c[s]
skc6:	c - 1 -> c[s]
	if no carry go to skc5
skc8:	a + 1 -> a[m]
skc9:	c exchange m
	a exchange c[w]
fixin:	c exchange m
	return

skc5:	a + c -> a[m]
	if no carry go to skc6
skc10:	a exchange c[wp]
	3 -> p
	load constant 7
	4 -> p
	a - 1 -> a[m]
	c + 1 -> c[s]
	c + 1 -> c[s]
skc1:	c + 1 -> c[s]
	if no carry go to skc2
	a exchange c[w]
	0 -> c[wp]
	c -> a[m]
	go to skc7

prog2:	c exchange m
	if a[xs] >= 1
	     then go to stff10
	shift left a[x]
	shift right a[w]
stff10:	c exchange m
stff:	c + 1 -> c[m]
stff2:	c exchange m
	shift right a[x]
	jsb skc
	if s11 # 1
	     then go to ikc12
	go to ldis

ldis50:	jsb fix
	go to ldis51

skc:	0 -> s11
	c exchange m
	a exchange c[w]
	c exchange m
skc7:	0 -> c[w]
	4 -> p
	a exchange c[wp]
	if c[m] >= 1
	     then go to skc10
skc4:	a exchange c[wp]
	1 -> s11
	go to skc9

	no operation

fix:	select rom 2
	.symtab

; HP-55 ROM 12

	.rom @12

fix:	c exchange m
	5 -> p
	c - 1 -> c[p]
	delayed select rom 1
	go to @322

hms7:	c + 1 -> c[x]
	shift right a[w]
	0 -> b[w]
	a -> b[x]
	a + b -> a[w]
	if a[s] >= 1
	     then go to hms7
	go to hms6

hms9:	if b[xs] = 0
	     then go to hms4
	go to hms2

con4:	a - 1 -> a[x]
	if no carry go to con5
lbmkg:	load constant 4
	load constant 5
	load constant 3
	load constant 5
	load constant 9
	load constant 2
	load constant 3
	load constant 7
	go to out2

con3:	a - 1 -> a[x]
	if no carry go to con4
btuj:	load constant 1
	load constant 0
	load constant 5
	load constant 5
	load constant 0
	load constant 5
	load constant 5
	load constant 8
	load constant 5
	load constant 3
	0 -> p
	load constant 3
	go to out

con2:	12 -> p
	a - 1 -> a[x]
	if no carry go to con3
dr:	load constant 1
	load constant 7
	load constant 4
	load constant 5
	load constant 3
	load constant 2
	load constant 9
	load constant 2
	load constant 5
	load constant 2
out1:	c - 1 -> c[x]
out2:	c - 1 -> c[x]
out:	delayed select group 0
	go to @361

con7:	a - 1 -> a[x]
	if no carry go to con8
inmm:	load constant 2
	load constant 5
	load constant 4
	c + 1 -> c[x]
	if no carry go to out

con8:	a - 1 -> a[x]
	if no carry go to gall
ftm:	load constant 3
	load constant 0
	load constant 4
	load constant 8
	go to out2

con6:	a - 1 -> a[x]
	if no carry go to con7
fc:	1 -> s5
	go to out

rs2:	c - 1 -> c[p]
	if c[p] = 0
	     then go to eof7
	load constant 9
	go to eof7

rs1:	1 -> s8
	load constant 1
eof7:	delayed select rom 1
	go to @202

	no operation
	no operation

xft0:	12 -> p
	if c[s] >= 1
	     then go to err1
	if c[xs] >= 1
	     then go to err1
	c -> a[w]
xft2:	a -> b[w]
	shift left a[ms]
	if a[wp] >= 1
	     then go to xft1
	a + 1 -> a[x]
	if a >= c[x]
	     then go to xft3
	c + 1 -> c[xs]
	if no carry go to eof

con5:	a - 1 -> a[x]
	if no carry go to con6
lbfn:	load constant 4
	load constant 4
	load constant 4
	load constant 8
	load constant 2
	load constant 2
	load constant 1
	load constant 6
	load constant 1
	load constant 5
	go to out

co1:	load constant 6
	delayed select rom 0
	go to @221

	no operation
	no operation
	no operation
	no operation

c0:	c exchange m
	8 -> p
	load constant 0
	go to co1

err1:	delayed select group 0
	go to @120

hhms:	if b[w] = 0
	     then go to ehms0
	12 -> p
	b -> c[x]
	go to hms1

ehms:	delayed select group 0
	select rom 0

xft1:	a - 1 -> a[x]
	if no carry go to xft2
	go to err1

xft3:	0 -> c[w]
	c + 1 -> c[p]
	shift right c[w]
	c + 1 -> c[s]
	b exchange c[w]
xft10:	if b[p] = 0
	     then go to xft8
	shift right b[wp]
	c + 1 -> c[x]
xft8:	0 -> a[w]
	a - c -> a[p]
	if no carry go to xft4
	shift left a[w]
xft5:	a + b -> a[w]
	if no carry go to xft5
xft4:	a - c -> a[s]
	if no carry go to xft6
	shift right a[wp]
	a + 1 -> a[w]
	c + 1 -> c[x]
xft7:	a + b -> a[w]
	if no carry go to xft7
xft6:	a exchange b[wp]
	c - 1 -> c[p]
	if no carry go to xft10
	c - 1 -> c[s]
	if no carry go to xft10
	shift left a[w]
	a -> b[x]
	a + b -> a[wp]
	0 -> c[ms]
	a + c -> a[w]
	a exchange c[ms]
eof:	delayed select group 0
	go to @207

hmsd:	shift right c[wp]
	a + c -> c[wp]
hmsm:	c -> a[wp]
	shift right c[wp]
	c + c -> c[wp]
	c + c -> c[wp]
	a - c -> c[wp]
	if s4 # 1
	     then go to hms8
	return

con1:	a - 1 -> a[x]
	if no carry go to con2
	1 -> s7
	go to hhms

rs10:	12 -> p
	if c[p] = 0
	     then go to rs1
	if s8 # 1
	     then go to rs2
	0 -> s8
	go to eof7

hms8:	a + c -> a[wp]
	shift right c[wp]
	if c[wp] >= 1
	     then go to hms8
	return

hms1:	c + 1 -> c[x]
	c + 1 -> c[x]
	if c[xs] >= 1
	     then go to hms9
hms4:	p - 1 -> p
	if p # 0
	     then go to hms3
ehms0:	b -> c[w]
	go to ehms

hms3:	c - 1 -> c[x]
	if no carry go to hms4
hms2:	0 -> c[w]
	b -> c[m]
hhms1:	if s4 # 1
	     then go to hms5
	p + 1 -> p
	p + 1 -> p
	jsb hmsm
	p - 1 -> p
	p - 1 -> p
	jsb hmsm
	c -> a[w]
	b -> c[w]
	12 -> p
	if a[p] >= 1
	     then go to hms6
	c - 1 -> c[x]
	shift left a[w]
hms6:	a exchange c[m]
	go to ehms

hms5:	0 -> a[w]
	jsb hmsd
	p + 1 -> p
	p + 1 -> p
	jsb hmsd
	shift left a[w]
	a + c -> c[w]
	0 -> a[w]
	c -> a[x]
	a + c -> a[w]
	b -> c[w]
	if a[s] >= 1
	     then go to hms7
	go to hms6

	no operation

gall:	load constant 3
	load constant 7
	load constant 8
	load constant 5
	load constant 4
	load constant 1
	load constant 1
	load constant 7
	load constant 8
	load constant 4
	go to out

	.symtab

; HP-55 ROM 13

	.rom @13

	go to clx2
wat6:	go to wat5
	go to clx2
	go to clx2
	go to clx2
del15:	go to del14
	go to clx2
del14:	go to del13
	go to clx2
del13:	go to del12
	go to clx2
	go to clx2
	go to clx2
del12:	go to del11
	go to clx2
clx1:	if s6 # 1
	     then go to wat6
	go to stop
six:	go to six1
fiv:	go to fiv1
fou:	go to fou1
del11:	go to del10
	go to clx2
nin1:	load constant 9
	go to proc
del10:	go to del9
thr:	go to thr1
two:	go to two1
one:	go to one1
del9:	go to del8
	go to clx2
eig1:	load constant 8
	go to proc
del8:	go to del7
rs:	go to rs1
	go to clx2
zer:	go to zer1
del7:	go to del6
	go to clx2
del6:	go to del5
	go to clx2
del5:	go to del4
	go to clx2
	go to clx2
	go to clx2
del4:	go to del3
	go to clx2
sev1:	load constant 7
	go to proc
del3:	go to del2
nin:	go to nin1
eig:	go to eig1
sev:	go to sev1
del2:	go to del1
	go to clx2
clx3:	1 -> s6
clx:	0 -> a[w]
clx2:	jsb clx1
eex:	go to eex1
	go to clx2
six1:	load constant 6
	go to proc
	go to clx2
init:	0 -> b[w]
init9:	c -> a[w]
	0 -> c[w]
	c - 1 -> c[m]
	8 -> p
init4:	load constant 6
	load constant 0
	if p # 4
	     then go to init4
	load constant 0
	b exchange c[ms]
	b -> c[ms]
	c + 1 -> c[s]
	shift right c[ms]
	c + 1 -> c[x]
	if a[s] >= 1
	     then go to clx3
	if a[xs] >= 1
	     then go to init1
	a - 1 -> a[x]
	if no carry go to init2
okdp:	shift right a[w]
	shift right a[w]
	shift right a[w]
	shift right a[w]
	shift right a[wp]
	shift right a[wp]
	7 -> p
	if a >= c[p]
	     then go to clx3
	5 -> p
	if a >= c[p]
	     then go to clx3
stop:	1 -> s6
	jsb tstblk
wats:	0 -> s8
wat1:	0 -> s0
wat2:	p - 1 -> p
	if p # 11
	     then go to wat2
wat4:	if s0 # 1
	     then go to wat3
	if s8 # 1
	     then go to wat1
	keys -> rom address

exit:	jsb out
	a -> b[w]
	0 -> c[p]
exit1:	c -> data address
	a exchange c[w]
	data -> c
	a exchange c[w]
	jsb out
	a exchange c[w]
	c -> data
	a exchange c[w]
	c + 1 -> c[p]
	if no carry go to exit1
	b -> c[w]
done:	select rom 2

eex2:	jsb see1
	go to star

fiv1:	load constant 5
	go to proc

fou1:	load constant 4
	go to proc

thr1:	load constant 3
	go to proc

wat3:	1 -> s8
	0 -> s11
	if s11 # 1
	     then go to exit
	go to wat1

rs1:	if s6 # 1
	     then go to stop
start:	clear status
	go to del15

eex1:	b exchange c[w]
	0 - c - 1 -> c[x]
	b exchange c[w]
	if s6 # 1
wat5:	     then go to eex2
	go to stop

out:	12 -> p
	if a[w] >= 1
	     then go to out5
out2:	11 -> p
	return

out5:	if a[p] >= 1
	     then go to out2
	3 -> p
	shift left a[wp]
	shift left a[wp]
	shift left a[w]
	shift left a[w]
	a + 1 -> a[x]
	12 -> p
out1:	shift left a[m]
	if a[p] >= 1
	     then go to out2
	a - 1 -> a[x]
	display off
	go to out1

del1:	go to test

proc1:	c -> data
ohno:	a exchange c[w]
star:	1 -> p
	a + 1 -> a[wp]
	if no carry go to nocary
	4 -> p
	a + 1 -> a[p]
	if no carry go to del15
	5 -> p
	a + 1 -> a[p]
	if a >= c[p]
	     then go to carry1
	go to del10


carry1:	0 -> a[p]
	6 -> p
	a + 1 -> a[p]
	if no carry go to del7
	7 -> p
	a + 1 -> a[p]
	if a >= c[p]
	     then go to carry2
	go to del2

carry2:	0 -> a[p]
	8 -> p
	a + 1 -> a[p]
	if no carry go to loop
	9 -> p
	a + 1 -> a[p]
	jsb oops

test:	if s7 # 1
	     then go to watr
	11 -> p
	clear status
	keys -> rom address

proc:	c -> data address
	a exchange c[w]
	if s6 # 1
	     then go to proc1
	data -> c
	12 -> p
	if c[p] >= 1
	     then go to init9
	a exchange c[w]
	go to stop

watr:	0 -> s0
	if s0 # 1
	     then go to clk1
	if s8 # 1
	     then go to wat8
	1 -> s7
clk2:	go to wat6

clk1:	1 -> s8
wat9:	go to wat8

loop:	10 -> p
over:	p - 1 -> p
	if p # 8
oops:	     then go to over
wat7:	go to wat6

wat8:	go to wat7

init2:	shift left a[ms]
	a - 1 -> a[x]
	if no carry go to clx3
	go to okdp

init3:	if a[ms] >= 1
	     then go to init1
	go to clx

init1:	shift right a[ms]
	a + 1 -> a[x]
	if no carry go to init3
	go to okdp

in:	delayed select group 0
	go to @020

	no operation

nocary:	jsb tstblk
	go to del10

two1:	load constant 2
	go to proc

one1:	load constant 1
	go to proc

zer1:	load constant 0
	go to proc

tstblk:	9 -> p
	if a[p] >=1
	     then go to see
blind:	b exchange c[p]
	b -> c[p]
see1:	return
see:	0 -> b[p]
	go to see1


	.symtab


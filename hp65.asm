; HP-65 partial ROM sources from United States Patent 4,099,246
; Copyright 2004 Eric L. Smith <eric@brouhaha.com>
; $Id$
; Keyed in by Eric Smith on 18-Jan-2004 - any errors are probably mine.
; May not match released code in actual HP-65 calculators.

; HP-65 ROM 00

	.rom @00

dummy:	jsb pwo0
sto4:	go to sto4s
	no operation
	no operation
	go to dec7
sto6:	go to sto6s
tnx1:	jsb tnx2
sto23:	a - 1 -> a[p]
	a - 1 -> a[p]
	if no carry go to sto13
	go to min20
	no operation
rcl18:	a - 1 -> a[p]
	if no carry go to rcl19
	jsb rcl6
rcl8:	go to rcl8s
rcl7:	go to rcl7s
sto31:	c - 1 -> c[p]
	if no carry go to sto32
	jsb clrst
	go to sto30
rcl6:	go to rcl6s
	go to nosfx2
rcl4:	go to rcl4s
lstx2:	data -> c
	go to frtn11
rcl8s:	a + 1 -> a[x]
rcl7s:	a + 1 -> a[x]
rcl6s:	a + 1 -> a[x]
rcl5:	a + 1 -> a[x]
rcl4s:	a + 1 -> a[x]
rcl3:	a + 1 -> a[x]
rcl2:	a + 1 -> a[x]
rcl1:	a + 1 -> a[x]
	if s3 # 1
	     then go to rcl23
	go to min20
sto7:	go to sto7s
ufcn10:	if s8 # 1
	     then go to ufcn11
	go to wait40
	no operation
sto8s:	a + 1 -> a[x]
sto7s:	a + 1 -> a[x]
sto6s:	a + 1 -> a[x]
sto5:	a + 1 -> a[x]
sto4s:	a + 1 -> a[x]
sto3:	a + 1 -> a[x]
sto2:	a + 1 -> a[x]
sto1:	a + 1 -> a[x]
	if s3 # 1
	     then go to sto22
	go to min20
sto8:	go to sto8s
rcl25:	a - 1 -> a[p]
	a - 1 -> a[p]
	if no carry go to rcl12
	go to min20
sto18:	a - 1 -> a[p]
	if no carry go to sto19
	jsb sto6
lstx0:	0 -> c[m]
	c exchange m
	0 -> s11
	0 -> f1
	if s11 # 1
	     then go to lstx1
	c -> stack
lstx1:	0 -> c[w]
	c -> data address
	go to lstx2
rcl14:	a - 1 -> a[p]
	if no carry go to rcl15
	jsb rcl2
rcl15:	a - 1 -> a[p]
	if no carry go to rcl16
	jsb rcl3
	go to tnx1
sdgt2:	5 -> p
	if c[p] = 0
	     then go to sdgt3
	c - 1 -> c[p]
	if c[p] = 0
	     then go to sto11
	c - 1 -> c[p]
	2 -> p
	jsb adrs3
	go to sto10
adrs4:	0 -> b[w]
adrs1:	shift left a[w]
	p + 1 -> p
	if p # 12
	     then go to adrs1
	a exchange c[w]
	c -> data address
	a exchange c[w]
	return
rcl17:	a - 1 -> a[p]
	if no carry go to rcl18
	jsb rcl5
sdgt4:	select rom 4
sto15:	a - 1 -> a[p]
	if no carry go to sto16
	jsb sto3
rcl19:	a - 1 -> a[p]
	if no carry go to rcl20
	jsb rcl7
sto11:	jsb clrm
	if s3 # 1
	     then go to sto12
	a + 1 -> a[p]
	if no carry go to sto23
	go to min20
sto14:	a - 1 -> a[p]
	if no carry go to sto15
	jsb sto2
adrs3:	1 -> s4
adrs0:	if a[xs] >= 1
	     then go to adrs4
	if s4 # 1
	     then go to nosfx1
nosfx2:	jsb clrm
nosfx3:	0 -> f7
nosfx1:	select rom 2
rcl12:	jsb mdl0
	a - 1 -> a[p]
	if no carry go to rcl14
	jsb rcl1
sto32:	c - 1 -> c[p]
	if no carry go to sto36
	jsb clrst
	jsb mpy20
	go to sqx1
rcl20:	jsb rcl8
sdgt3:	if s3 # 1
	     then go to sdgt4
	select rom 5
fact0:	select rom 3
clrm:	0 -> c [m]
	c exchange m
	2 -> p
	return
ufcn11:	1 -> s10
wait40:	select rom 1
mdl0:	1 -> f7
	memory delete
	0 -> s11
mdl1:	0 -> f5
	if s11 # 1
	     then go to mdl1
	0 -> f5
	return
sdgt1:	4 -> p
	if c[p] = 0
	     then go to sdgt2
rcl10:	jsb clrm
	if s3 # 1
	     then go to rcl11
	a + 1 -> a[p]
	if no carry go to rcl25
	go to min20
sto20:	jsb sto8
	go to frtn11
sqx1:	c -> a[w]
mpy20:	select rom 6
dvd20:	select rom 6
dec7:	12 -> p
	if c[p] = 0
	     then go to nosfx2
	load constant 2
	c exchange m
	go to wait40
frac2:	shift left a[m]
	a - 1 -> a[x]
	p + 1 -> p
frac1:	if p # 12
	     then go to frac2
	a exchange c[w]
	c -> a[w]
	0 -> a[x]
	delayed select group 1
	go to @145
clrst:	0 -> c[m]
	c exchange m
	12 -> p
clrst1:	c -> a[w]
	data -> c
	a exchange c[w]
	c -> data
	return
sto19:	a - 1 -> a[p]
	if no carry go to sto20
	jsb sto7
pwo0:	delayed select group 1
	select rom 2
	no operation
	no operation
gdgt2:	a - 1 -> a[xs]
	if no carry go to gdgt3
	go to fact0
gdgt3:	select rom 5
	go to frac1
	go to nosfx2
sto13:	jsb mdl0
	a - 1 -> a[p]
	if no carry go to sto14
	jsb sto1
sto36:	jsb clrst
	jsb dvd20
sto22:	jsb clrm
	0 -> p
sto12:	jsb adrs0
	c -> data
frtn11:	select rom 2
frtn10:	select rom 2
rcl23:	jsb clrm
	0 -> p
rcl11:	jsb adrs0
	0 -> s11
	0 -> f1
	if s11 # 1
	     then go to rcl22
	c -> stack
rcl22:	data -> c
	go to frtn11
min20:	select rom 4
	jsb clrst1
	a exchange c[w]
	go to wait40
	no operation
	no operation
	no operation
sto16:	a - 1 -> a[p]
	if no carry go to sto17
	jsb sto4
	go to nosfx2
sto17:	a - 1 -> a[p]
	if no carry go to sto18
	jsb sto5
	no operation
	no operation
	buffer -> rom address
	go to dummy
tnx2:	1 -> s2
	c -> a[w]
	select rom 7
	no operation
sto10:	5 -> p
	c - 1 -> c[p]
	if no carry go to sto31
	jsb clrst
	0 - c - 1 -> c[s]
sto30:	select rom 5
rcl16:	a - 1 -> a[p]
	if no carry go to rcl17
	jsb rcl4

	.symtab

; HP-65 ROM 01

	.rom @01

dec6:	6 -> p
	if c[p] >= 1
	     then go to dec8
	select rom 0
dsz6:	select rom 4
fdgt8:	a + 1 -> a[xs]
	if no carry go to doct0
	delayed select group 1
	select rom 1
dsz5:	if a[m] >= 1
	     then go to dsz10
	go to dsz7
entr2:	if c[m] = 0
	     then go to entr1
	delayed select group 1
	select rom 2
	no operation
	jsb wait3
	go to wait40
dsz3:	if c[m] = 0
	     then go to dsz4
	shift right c[m]
	c - 1 -> c[x]
dsz2:	if c[x] >= 1
	     then go to dsz3
dsz4:	if c[s] >= 1
	     then go to dsz13
	a - c -> a[m]
	if no carry go to dsz5
	0 - c - 1 -> c[s]
dsz8:	c -> data
	b exchange c[w]
	jsb dsz12
wait30:	0 -> s11
	0 -> f0
	if s11 # 1
	     then go to wait10
	delayed select group 1
	select rom 1
	no operation
	go to entr2
wait11:	c + 1 -> c[xs]
wait4:	0 -> s10
	if s5 # 1
	     then go to wait13
	c + 1 -> c[x]
	if no carry go to wait11
	go to wait17
ptr5:	1 -> s6
	a exchange c[w]
	select rom 3
fix5:	p - 1 -> p
	c + 1 -> c[x]
	jsb fix7
dec8:	select rom 5
	no operation
fix3:	0 -> c[xs]
fix4:	13 -> p
	c - 1 -> c[x]
fix7:	if b[p] = 0
	     then go to fix5
	12 -> p
fix6:	if a[p] >= 1
	     then go to fix2
	shift left a[m]
	c - 1 -> c[x]
	jsb fix6
rtp3:	if s4 # 1
	     then go to rtp4
	c + c -> c[w]
	a + c -> c[s]
	if a[m] >= 1
	     then go to rtp5
	0 - c - 1 -> c[s]
	jsb rtp5
dsz10:	if a[p] >= 1
	     then go to dsz7
	shift left a[m]
	a - 1 -> a[x]
dsz7:	a exchange c[w]
	jsb dsz8
dsz11:	a + 1 -> a[p]
	a + 1 -> a[x]
	jsb dsz7
dec5:	7 -> p
	if c[p] = 0
	     then go to dec6
	select rom 5
	go to wait29
wait16:	0 -> s3
	1 -> f2
	1 -> p
	c exchange m
	0 -> s11
	0 -> f3
	if s3 # 1
	     then go to wait2
	if s11 # 1
	     then go to wait33
wait36:	c exchange m
	delayed select group 1
	select rom 3
fix1:	c + 1 -> c[xs]
	if no carry go to fix3
	0 - c -> c[x]
	jsb fix4
wait2:	if s11 # 1
	     then go to wait35
	if c[p] = 0
	     then go to dsci50
	c - 1 -> c[p]
	if c[p] = 0
	     then go to dsci50
wait39:	load constant 2
	delayed select group 1
	select rom 0
entr1:	delayed select rom 2
	go to @103
rtp4:	select rom 3
fix0:	a exchange c[w]
	c -> a[w]
	if a[m] >= 1
	     then go to fix1
	0 -> a[m]
fix2:	a exchange c[m]
frtn5:	select rom 2
	jsb wait3
	if s3 # 1
	     then go to wait32
	select rom 4
fidgt8:	a + 1 -> a[xs]
	if no carry go to odec0
ptr0:	stack -> a
	1 -> s1
	1 -> s4
	1 -> s5
	go to ptr5
wait44:	0 -> c[m]
	jsb wait39
	no operation
	no operation
doct0:	select rom 3
dsci50:	delayed select group 1
	select rom 0
wait10:	if s8 # 1
	     then go to wait16
wait1:	12 -> p
	if s0 # 1
	     then go to wait4
wait31:	p + 1 -> p
	if p # 12
	     then go to wait31
	0 -> s0
	if s10 # 1
	     then go to wait28
	go to wait1
dsz12:	c exchange m
	if b[m] = 0
	     then go to dsz6
dsz9:	select rom 2
dec7:	select rom 0
wait28:	if s5 # 1
	     then go to wait6
	go to wait29
mpy20:	select rom 6
dvd20:	select rom 6
	no operation
	go to dvd20
dsz0:	b exchange c[w]
	0 -> c[w]
	12 -> p
	c - 1 -> c[p]
	c - 1 -> c[p]
	c -> data address
	0 -> b[m]
	data -> c
dsz1:	c -> a[w]
	0 -> c[m]
	c + 1 -> c[p]
	jsb dsz2
dsz13:	a + c -> a[m]
	if no carry go to dsz7
	go to dsz11
rtp5:	0 -> s1
	select rom 3
	3 -> p
	if c[p] >= 1
	     then go to dsz0
	go to dec5
wait3:	12 -> p
	1 -> f3
	display off
	c exchange m
	shift left a[w]
	return
wait41:	c exchange m
	go to wait42
odec0:	select rom 3
wait42:	delayed select group 1
	go to @312
wait8:	jsb wait3
	1 -> f7
	if s3 # 1
	     then go to wait7
	select rom 4
wait7:	select rom 2
	go to rtp3
wait45:	0 -> c[m]
	jsb dsci50
wait33:	if c[p] >= 1
	     then go to wait34
	load constant 1
wait43:	0 -> c[m]
	jsb wait36
wait9:	if s9 # 1
	     then go to wait1
	0 -> s9
wait23:	1 -> s10
wait17:	display toggle
	go to wait1
wait6:	if s8 # 1
	     then go to wait8
	go to wait41
wait29:	1 -> f3
	clear status
wait25:	go to wait10
wait34:	c - 1 -> c[p]
	c - 1 -> c[p]
	if c[p] >= 1
	     then go to wait37
	load constant 3
	go to wait43
wait13:	if s8 # 1
	     then go to wait30
	pointer advance
	display toggle
	c exchange m
	shift left a[w]
wait40:	0 -> s11
wait27:	0 -> f5
	if s11 # 1
	     then go to wait27
	0 -> f5
wait32:	select rom 2
wait35:	if c[p] = 0
	     then go to wait38
	c - 1 -> c[p]
	if c[p] = 0
	     then go to wait45
	c - 1 -> c[p]
	if c[p] >= 1
	     then go to wait44
wait37:	c + 1 -> c[p]
	c + 1 -> c[p]
wait38:	c exchange m
	go to wait9

	.symtab

; HP-65 ROM 02

	.rom @02

noop:	go to noop1
sto4:	go to fcn60
dig3:	select rom 5
dig2:	select rom 5
dig1:	select rom 5
sto6:	go to fcn60
mpy:	go to arth2
xney:	select rom 5
g:	go to fcn50
rup:	go to rup1
rcl:	go to fcn50
sto:	go to fcn50
fi:	go to fcn50
rdn:	go to rdn1
f:	go to fcn50
rcl8:	go to fcn60
rcl7:	go to fcn60
excg:	go to excg0
dig6:	select rom 5
dig5:	select rom 5
dig4:	select rom 5
rcl6:	go to fcn60
pls:	go to arth1
rcl4:	go to fcn60
e:	go to fcn40
xeqy:	select rom 5
d:	go to fcn40
	go to fcn40	; label "c" in listing
	go to fcn40	; label "b" in listing
rcl5:	go to fcn60
	go to fcn40	; label "a" in listing
rcl3:	go to fcn60
rcl2:	go to fcn60
rcl1:	go to fcn60
	go to data0	; label "data" in listing
dec:	go to dec0
dig0:	select rom 5
sto7:	go to fcn60
dvd:	go to arth3
entr2:	select rom 1
sst:	go to fcn50
xgty:	select rom 5
rtn:	go to fcn50
lbl:	go to fcn50
gto:	go to fcn50
sto5:	go to fcn60
dsp:	go to fcn50
sto3:	go to fcn60
sto2:	go to fcn60
sto1:	go to fcn60
dig9:	select rom 5
dig8:	select rom 5
dig7:	select rom 5
sto8:	go to fcn60
mns:	go to arth0
xley:	select rom 5
clx:	go to clr10
	no operation
eex:	go to eex0
chs:	go to chs0
lstx:	select rom 0
	no operation
entr:	go to entr2
mrk:	c exchange m
	go to bnds3
data0:	0 -> c[m]
	delayed select group 1
entr1:	c exchange m
	c -> stack
	go to clr23
	go to data6
den7:	shift right b[wp]
	jsb den5
	go to sdgt9
den13:	if s1 # 1
	     then go to den12
	if s7 # 1
	     then go to den9
	a exchange c[x]
	shift right a[w]
	1 -> p
	c -> a[wp]
	go to den17
clsts1:	clear status
	return
	no operation
	no operation
den16:	shift right b[w]
den9:	b exchange c[w]
	c + 1 -> c[w]
	0 -> p
den3:	if c[p] >= 1
	     then go to den2
	p + 1 -> p
	shift left a[wp]
	go to den3
chs1:	c exchange m
	shift right a[w]
	if s7 # 1
	     then go to chs2
	a exchange c[x]
	0 - c - 1 -> c[xs]
	a exchange c[x]
	go to den17
arth4:	select rom 5
den2:	c - 1 -> c[w]
	b exchange c[w]
	if p # 3
	     then go to den4
	0 -> a[wp]
den5:	shift right a[ms]
den17:	c -> a[s]
den15:	if s7 # 1
	     then go to den14
	0 -> b[x]
den14:	1 -> s9
	0 -> f3
	1 -> f1
	select rom 1
clsts0:	if s8 # 1
	     then go to clsts1
	clear status
	1 -> s8
	return
	jsb clsts0
	select rom 1
bnds0:	if c[xs] = 0
	     then go to bnds5
	c + 1 -> c[xs]
	if c[xs] = 0
	     then go to bnds2
	c + 1 -> c[xs]
	if c[xs] = 0
	     then go to uflw
oflw:	0 -> c[m]
	0 -> c[x]
	c - 1 -> c[m]
	c - 1 -> c[x]
	shift right c[x]
bnds4:	clear status
	go to bnds6
rdn1:	c exchange m
	go to roll1
bnds3:	select rom 1
sdgt9:	jsb clsts0
	3 -> p
	select rom 5
data2:	clear status
	1 -> s8
	1 -> s10
	go to bnds3
chs2:	0 - c - 1 -> c[s]
	c -> a[s]
	0 -> f3
	1 -> s9
	go to bnds0
clr10:	0 -> c[m]
clr11:	c exchange m
	0 -> c[w]
clr23:	0 -> f1
clr24:	jsb clsts0
	go to bnds5
noop1:	0 -> c[m]
	c exchange m
	go to clr24
den12:	0 -> s11
	0 -> f1
	if s11 # 1
	     then go to rset2
	c -> stack
rset2:	0 -> c[w]
	12 -> p
	c - 1 -> c[wp]
	c + 1 -> c[s]
	c + 1 -> c[s]
	b exchange c[w]
	0 -> c[w]
	if s2 # 1
	     then go to den16
	go to den9
data1:	if s9 # 1
	     then go to data2
bnds6:	1 -> f3
	go to clr24
dec2:	select rom 1
dec0:	if c[m] >= 1
	     then go to dec2
dec1:	1 -> s2
	if s1 # 1
	     then go to dig0
	go to eex1
eex0:	if c[m] >= 1
	     then go to entr2
eex2:	1 -> s7
	if s1 # 1
	     then go to dig1
eex1:	c exchange m
	shift right a[w]
	jsb den17
arth3:	a + 1 -> a[x]
arth2:	a + 1 -> a[x]
arth1:	a + 1 -> a[x]
arth0:	jsb clsts0
	if c[m] = 0
	     then go to arth4
	select rom 4
	keys -> rom address
	no operation
err3:	1 -> f3
	go to bnds0
excg0:	c exchange m
	stack -> a
	c -> stack
	a exchange c[w]
frtn1:	1 -> f1
frtn2:	jsb clsts0
	go to bnds0
bnds2:	if c[x] = 0
	     then go to uflw
	c - 1 -> c[xs]
bnds5:	if c[m] >= 1
	     then go to bnds7
	0 -> c[w]
bnds7:	if p # 14
	     then go to bnds3
	select rom 0
rup1:	c exchange m
	down rotate
	down rotate
roll1:	down rotate
	go to frtn1
fcn50:	select rom 4
	go to frtn2
fcn40:	select rom 4
uflw:	0 -> c[w]
	jsb bnds4
data6:	if s1 # 1
	     then go to bnds4
	0 -> f1
	go to bnds4
fcn60:	select rom 0
den6:	shift left a[w]
	1 -> s1
	go to den5
	buffer -> rom address
	go to noop
den4:	if s1 # 1
	     then go to den6
	if s2 # 1
	     then go to den7
	p - 1 -> p
	0 -> b[p]
	jsb den5
chs0:	if c[m] = 0
	     then go to chs1
	go to entr2

	.symtab

; HP-65 ROM 03

	.rom @03

fmod3:	c - 1 -> c[x]
	c - 1 -> c[x]
	c -> a[w]
	jsb fmod4
fdgt8:	select rom 1
	go to dmst2
	no operation
	no operation
tanx:	select rom 6
pi21:	0 -> s10
pi20:	12 -> p
	0 -> c[w]
	load constant 1
	load constant 5
	load constant 7
	load constant 0
	load constant 7
	load constant 9
	load constant 6
	load constant 3
	load constant 2
	load constant 7
	12 -> p
	return
ret:	select rom 6
	if s4 # 1
	     then go to ret
	delayed select group 1
	select rom 1
fmod1:	a - 1 -> a[p]
	if no carry go to fmod3
	c - 1 -> c[x]
	jsb ld90
	jsb dvd30
fmod4:	jsb pi20
	jsb mpy30
	go to fmod2
tdms3:	c - 1 -> c[x]
	jsb ld91
	jsb mpy30
	go to tdms2
doct0:	jsb int6
	delayed select group 1
	select rom 2
sqt2:	select rom 6
fidgt7:	a + 1 -> a[xs]
	if no carry go to fidgt8
	go to dmsm0
	c -> a[w]
	if s1 # 1
	     then go to sqt2
	jsb adr9
	if s7 # 1
	     then go to fmod0
	go to mag0
	no operation
sin12:	c -> a[w]
	select rom 6
	jsb adr9
	go to mag0
dmst2:	1 -> s10
	12 -> p
	jsb dvd30
	if s6 # 1
	     then go to dmst5
	0 -> s6
	stack -> a
	c -> stack
	a exchange c[w]
	1 -> s4
	go to dmst0
dmst6:	jsb mod10
	a - 1 -> a[p]
	if no carry go to dmst3
	c - 1 -> c[x]
	jsb ld91
	jsb dvd30
	jsb pi21
	go to mpy30
rtp9:	jsb rtp13
	jsb mpy30
	data -> c
	jsb add10
	delayed select group 1
	select rom 1
	no operation
tdms1:	a - 1 -> a[p]
	if no carry go to tdms3
tdms2:	delayed select group 1
	select rom 1
int0:	jsb int6
	go to frtn14
dmst4:	c + 1 -> c[x]
	jsb ld90
	0 -> s10
	go to dvd30
fmod0:	jsb mod10
	a - 1 -> a[p]
	if no carry go to fmod1
	go to fmod2
	no operation
mag4:	0 -> c[w]
	c + 1 -> c[p]
	if s7 # 1
	     then go to tanx
	select rom 6
dmsm0:	0 - c - 1 -> c[s]
dmsp0:	1 -> s6
dmst0:	delayed select group 1
	select rom 1
fidgt6:	0 -> s7
	a + 1 -> a[xs]
	if no carry go to fidgt7
	go to dmst0
odec0:	jsb int6
	delayed select group 1
	select rom 2
lpi11:	select rom 6
	if s6 # 1
	     then go to rmod0
	go to rtp3
int4:	c - 1 -> c[x]
int2:	p - 1 -> p
	if c[x] >= 1
	     then go to int3
int5:	0 -> c[wp]
	a exchange c[x]
	c -> a[x]
	go to int7
fidgt8:	select rom 1
int6:	12 -> p
	c -> a[w]
	if c[xs] = 0
	     then go to int2
	0 -> c[w]
int7:	return
sub10:	0 - c - 1 -> c[s]
add10:	select rom 5
	go to fact0
fdgt7:	a + 1 -> a[xs]
	if no carry go to fdgt8
	go to dmsp0
	go to doct0
wait50:	select rom 1
rmod3:	c + 1 -> c[x]
	c + 1 -> c[x]
	c -> a[x]
	jsb rmod5
int3:	if p # 2
	     then go to int4
	go to int5
ptr3:	delayed select group 1
	select rom 1
fdgt6:	a + 1 -> a[xs]
	if no carry go to fdgt7
tdms0:	jsb mod10
	a - 1 -> a[p]
	if no carry go to tdms1
	c + 1 -> c[x]
	jsb ld91
	jsb mpy30
	jsb pi20
	jsb dvd30
	go to tdms2
mpy30:	select rom 6
dvd30:	select rom 6
mod11:	a exchange c[w]
mod10:	c exchange m
	c -> a[x]
	c exchange m
	0 -> p
	0 -> s1
	1 -> s10
	return
dmst5:	if s4 # 1
	     then go to dmst6
	0 -> s4
	1 -> s10
	stack -> a
	12 -> p
	jsb add10
	go to tdms2
fact0:	jsb int6
	delayed select group 1
	select rom 0
rtp5:	jsb sub10
rmod0:	jsb mod11
	a - 1 -> a[p]
	if no carry go to rmod2
rmod6:	if s6 # 1
	     then go to frtn14
	delayed select group 1
	select rom 1
ptr2:	jsb dvd30
	stack -> a
	c -> stack
	jsb mpy30
	go to ptr3
	go to odec0
frac0:	jsb int6
	select rom 0
nosfx4:	select rom 0
	jsb mpy30
	delayed select group 1
	select rom 1
rtp3:	select rom 1
ld91:	1 -> s10
ld90:	c -> a[w]
	12 -> p
	0 -> c[w]
	c - 1 -> c[p]
	return
	go to rtp9
frtn14:	select rom 2
frtn13:	select rom 2
dmst3:	a - 1 -> a[p]
	if no carry go to dmst4
	go to frtn14
exit:	select rom 5
	if s10 # 1
	     then go to exit
	return
fmod2:	c -> a[w]
	0 -> b[w]
	12 -> p
	0 -> s10
	1 -> s1
mag0:	c + 1 -> c[xs]
	if no carry go to mag3
	if c[x] = 0
	     then go to mag3
	0 -> c[w]
	0 -> p
	load constant 5
	12 -> p
	a + c -> c[x]
	if no carry go to mag4
mag3:	if s7 # 1
	     then go to lpi11
	a exchange c[w]
	go to sin12
rtp13:	c -> a[w]
adr9:	b exchange c[w]
	c - 1 -> c[p]
	c -> data address
	b exchange c[w]
	0 -> b[w]
	return
rmod2:	a - 1 -> a[p]
	if no carry go to rmod3
	c + 1 -> c[x]
	jsb ld90
	jsb mpy30
rmod5:	jsb pi20
	jsb dvd30
	go to rmod6

	.symtab

; HP-65 ROM 04

	.rom @04

noop:	go to fcn19
	no operation
dig3:	select rom 5
dig2:	select rom 5
dig1:	select rom 5
	go to pad0
mpy:	go to fcn19
xney:	go to fcn19
g:	go to p3
rup:	go to fcn19
rcl:	go to p4
sto:	go to p5
fi:	go to p6
rdn:	go to fcn19
f:	go to p7
fcn21:	1 -> f5
fcn2:	select rom 1
excg:	go to fcn19
dig6:	select rom 5
dig5:	select rom 5
dig4:	select rom 5
	no operation
pls:	go to fcn19
	go to ufcn9
e:	go to fcn19
xeqy:	go to fcn19
d:	go to fcn19
	go to fcn19	; label "c" in listing
	go to fcn19	; label "b" in listing
	no operation
	go to fcn19	; label "a" in listing
fcn27:	if p # 14
	     then go to fcn28
	jsb lstx
	go to fcn19	; label "data" in listing
dec:	go to fcn19
dig0:	select rom 5
ufcn10:	select rom 0
dvd:	go to fcn19
rsetp:	return
sst:	go to p8
xgty:	go to fcn19
rtn:	go to p9
lbl:	go to p10
gto:	go to p11
	no operation
dsp:	go to fcn0
	go to fcn8
arth4:	delayed select group 1
	select rom 0
dig9:	select rom 5
dig8:	select rom 5
dig7:	select rom 5
	no operation
mns:	go to fcn19
xley:	go to fcn19
clx:	if c[m] >= 1
	     then go to clr20
eex:	go to fcn19
chs:	go to fcn19
lstx:	go to fcn19
fcn25:	jsb rup
entr:	go to fcn19
fcn11:	if p # 12
	     then go to fcn23
	jsb xney
ufcn4:	if s9 # 1
	     then go to ufcn5
	mark and search
	c + 1 -> c[s]
ufcn7:	c + 1 -> c[s]
	clear status
	1 -> s10
	jsb ufcn6
fcn23:	if p # 13
	     then go to fcn27
	a - 1 -> a[xs]
	if no carry go to fcn24
	jsb excg
	no operation
fcn7:	c + 1 -> c[p]
	if s8 # 1
	     then go to fcn8
fcn26:	c exchange m
	clear status
	1 -> s8
	go to rtn7
mcirc0:	0 -> s11
mcirc1:	0 -> f5
	if s11 # 1
	     then go to mcirc1
	0 -> f5
	return
clr20:	3 -> p
	if c[p] = 0
	     then go to clr23
	memory delete
	jsb mcirc0
clr21:	memory delete
	jsb arstr2
	go to fcn20
	11 -> p
	if c[p] >= 1
	     then go to ufcn3
	10 -> p
	if c[p] >= 1
	     then go to ufcn8
	select rom 5
	go to pad2
p3:	p - 1 -> p
p4:	p - 1 -> p
p5:	p - 1 -> p
p6:	p - 1 -> p
p7:	p - 1 -> p
	0 -> c[m]
p8:	p - 1 -> p
p9:	p - 1 -> p
p10:	p - 1 -> p
p11:	p - 1 -> p
fcn0:	if p # 8
	     then go to fcn1
	jsb arstr1
	1 -> s9
	pointer advance
	if s3 # 1
	     then go to fcn2
	go to fcn20
fcn9:	if p # 10
	     then go to fcn10
	jsb xeqy
	go to lbr1
fcn19:	jsb arstr2
fcn22:	if s3 # 1
	     then go to fcn21
	go to fcn13
	no operation
rtn2:	mark and search
	clear status
	1 -> s8
	c + 1 -> c[s]
	0 -> c[m]
	c exchange m
	jsb mcirc0
rtn7:	select rom 1
fcn4:	if p # 9
	     then go to fcn7
	if s3 # 1
	     then go to rtn0
	go to fcn8
fcn24:	a - 1 -> a[xs]
	if no carry go to fcn25
	jsb rdn
clr23:	delayed select group 1
	select rom 2
pad1:	1 -> f1
pad0:	pointer advance
	jsb mcirc0
pad3:	pointer advance
	jsb mcirc0
pad2:	select rom 2
rtn0:	if s8 # 1
	     then go to rtn1
	if c[s] = 0
	     then go to rtn2
	c - 1 -> c[s]
	if c[s] = 0
	     then go to rtn3
	go to rtn6
rtn5:	search for label
	jsb mcirc0
	1 -> f7
	jsb rsetp
rtn6:	search for label
	jsb mcirc0
	go to rtn3
ufcn3:	search for label
ufcn9:	jsb mcirc0
	go to ufcn9
fcn3:	if s3 # 1
	     then go to fcn15
	memory delete
	jsb mcirc0
fcn15:	1 -> f7
	if p # 9
	     then go to fcn9
	jsb xgty
fcn10:	if p # 11
	     then go to fcn11
	jsb xley
arstr2:	0 -> c[m]
arstr1:	c exchange m
arstr0:	shift right a[w]
	c -> a[s]
	return
ufcn5:	search for label
	go to ufcn7
	go to pad0
fcn1:	if c[m] = 0
	     then go to fcn4
	c - 1 -> c[m]
	if c[m] = 0
	     then go to fcn3
fcn6:	0 -> c[m]
	0 -> f7
	go to fcn4
	keys -> rom address
	5 -> p
	if c[p] = 0
	     then go to arth4
	0 -> c[m]
	shift left a[x]
	shift left a[x]
	c + 1 -> c[p]
sto36:	c + 1 -> c[p]
	a - 1 -> a[xs]
	if no carry go to sto36
	c exchange m
	go to rtn7
rtn1:	if s9 # 1
	     then go to rtn5
rtn3:	0 -> c[ms]
	c exchange m
	select rom 1
fcn8:	jsb arstr1
fcn16:	if s3 # 1
	     then go to rtn7
fcn13:	memory insert
fcn20:	jsb mcirc0
fnc5:	1 -> f3
	go to rtn7
	jsb arstr2
	go to fcn13
lbr1:	buffer -> rom address
	go to noop
ufcn0:	0 -> f5
	if c[m] = 0
	     then go to ufcn1
	10 -> p
	if c[p] = 0
	     then go to ufcn2
ufcn8:	0 -> c[m]
	c exchange m
	go to ufcn10
fcn28:	if p # 15
	     then go to fcn6
	jsb noop
ufcn2:	11 -> p
	if c[p] >= 1
	     then go to ufcn3
ufcn1:	0 -> c[ms]
	if s8 # 1
	     then go to ufcn4
	mark and search
	clear status
ufcn6:	1 -> s8
	go to ufcn9

	.symtab

; HP-65 ROM 05

	.rom @05

dummy:	no operation
err2:	go to err1
dig4:	a + 1 -> a[x]
dig3:	a + 1 -> a[x]
dig2:	a + 1 -> a[x]
	if no carry go to dig1
mpy:	go to mpy1
fnl1:	select rom 7
xney:	jsb setrl2
	a - c -> a[w]
	data -> c
	if a[w] >= 1
	     then go to frtn9
	go to rl2
inx1:	0 -> a[w]
	a + 1 -> a[p]
div2:	0 -> b[w]
fnl3:	select rom 6
dig7:	a + 1 -> a[x]
dig6:	a + 1 -> a[x]
dig5:	a + 1 -> a[x]
	if no carry go to dig4
add1:	go to add8
fdgt5:	a + 1 -> a[xs]
	if no carry go to fdgt6
	go to tan2
xeqy:	jsb setrl2
	a - c -> a[w]
	data -> c
	if a[w] >= 1
	     then go to rl2
	go to frtn9
fdgt3:	a + 1 -> a[xs]
	if no carry go to fdgt4
tan1:	1 -> s1
	go to sqt1
dig1:	a + 1 -> a[x]
	if no carry go to dig10
div1:	go to mpy3
fidgt4:	a + 1 -> a[xs]
	if no carry go to fidgt5
	go to cos1
xgty:	jsb setrl0
	0 - c - 1 -> c[s]
	jsb add3
	data -> c
	go to rl4
fnl2:	select rom 3
rl4:	if a[ms] >= 1
	     then go to rl5
	go to rl2
dig9:	a + 1 -> a[x]
dig8: 	a + 1 -> a[x]
	if no carry go to dig7
sub1:	go to add2
	go to frac1
xley:	jsb setrl0
	a exchange c[w]
	0 - c - 1 -> c[s]
	jsb add3
	data -> c
rl5:	a + 1 -> a[s]
	if no carry go to frtn9
	go to rl2
fdgt1:	a +  1 -> a[xs]
	if no carry go to fdgt2
log1:	1 -> s5
	go to ln1
sdgt7:	delayed select group 1
	select rom 1
dig10:	if c[m] = 0
	     then go to dig11
	select rom 2
dig12:	select rom 2
fidgt1:	a + 1 -> a[xs]
	if no carry go to fidgt2
	select rom 0
gdgt15:	a - b -> a[xs]
	13 -> p
	go to gdgt12
fdgt4:	a + 1 -> a[xs]
	if no carry go to fdgt5
cos1:	1 -> s9
tan2:	1 -> s5
	go to tan1
gdgt1:	0 -> c[m]
	c exchange m
	go to gdgt17
	jsb savx1
	select rom 3
	go to fnl2
fidgt2:	a + 1 -> a[xs]
	if no carry go to fidgt3
	go to log2
gdgt4:	a - 1 -> a[xs]
	if no carry go to abs0
	stack -> a
	c -> stack
	a exchange c[w]
ytx1:	1 -> s6
ytx2:	1 -> s2
	go to fnl1
fidgt5:	a + 1 -> a[xs]
	if no carry go to fidgt6
	go to tan2
	jsb savx3
	buffer -> rom address
	go to dummy
	go to sdgt5
fidgt6:	select rom 3
gdgt17:	0 -> b[w]
	a - 1 -> a[xs]
	if no carry go to gdgt20
	0 -> f1
	if s11 # 1
	     then go to pi2
	c -> stack
pi2:	select rom 6
gdgt10:	a - 1 -> a[xs]
	if no carry go to gdgt11
	14 -> p
	go to gdgt12
gdgt11:	a - 1 -> a[xs]
	if no carry go to gdgt13
	go to gdgt14
sdgt6:	6 -> p
	if c[p] = 0
	     then go to sdgt7
	jsb savx1
	a + 1 -> a[xs]
	if no carry go to fidgt1
	select rom 0
	go to sto34
mpy1:	3 -> p
	0 - c -> c[x]
mpy3:	stack -> a
	go to div2
	go to gdgt16
	go to add3
sdgt5:	7 -> p
	if c[p] = 0
	     then go to sdgt6
	jsb savx1
	a + 1 -> a[xs]
	if no carry go to fdgt1
sqt1:	0 -> b[w]
	jsb fnl2
sdgt0:	shift left a[x]
	shift left a[x]
	if c[p] >= 1
	     then go to gdgt10
	select rom 0
fdgt6:	select rom 3
add2:	0 - c - 1 -> c[s]
add8:	stack -> a
add3:	0 -> b[w]
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a>= c[x]
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
	no operation
fdgt2:	a + 1 -> a[xs]
	if no carry go to fdgt3
ln1:	1 -> s6
log2:	1 -> s9
	go to ytx2
savx1:	0 -> c[m]
savx3:	c exchange m
savx2:	0 -> b[w]
	b exchange c[w]
	c -> data address
	b exchange c[w]
	c -> data
	12 -> p
	return
add7:	select rom 6
err1:	clear status
	0 -> c[w]
	1 -> s5
	go to err3
rl2:	select rom 4
gdgt2:	select rom 0
frac1:	jsb savx1
	select rom 3
gdgt14:	15 -> p
gdgt12:	select rom 4
	go to gdgt3
fidgt3:	1 -> s7
	a + 1 -> a[xs]
	if no carry go to fidgt4
	go to tan1
sdgt8:	select rom 4
err3:	select rom 2
	go to add3
	go to sto34
gdgt20:	jsb savx2
	go to gdgt2
abs0:	0 -> c[s]
frtn8:	select rom 2
frtn9:	select rom 2
frtn10:	select rom 2
gdgt3:	a - 1 -> a[xs]
	if no carry go to gdgt4
	go to inx1
	if s4 # 1
	     then go to frtn8
	return
dig11:	c exchange m
	if s3 # 1
	     then go to dig12
dig13:	select rom 4
	no operation
gdgt13:	2 -> p
	b exchange c[w]
	load constant 5
	b exchange c[w]
	if a >= b[xs]
	     then go to gdgt15
	if s3 # 1
	     then go to gdgt1
gdgt16:	0 -> c[m]
	c exchange m
	go to dig13
setrl0:	0 -> s1
	0 -> s2
setrl2:	c exchange m
	0 -> b[w]
	b exchange c[w]
	c - 1 -> c[s]
	shift right c[w]
	c -> data address
	b -> c[w]
	stack -> a
	c -> data
setrl1:	a exchange c[w]
	c -> stack
	1 -> s4
	return
sto33:	jsb add3
sto34:	14 -> p
	go to frtn8

	.symtab

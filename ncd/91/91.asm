; 91 ROM source code reconstructed from disassembly
; Copyright 2022 Eric Smith <spacewar@gmail.com>

; status bits
;   s 0
;   s 1
;   s 2
;   s 3  - hardware flag 2 - PICK flags
;   s 4
;   s 5  - hardware flag 1 - NORM switch, paper advance
;   s 6
;   s 7
;   s 8
;   s 9
;   s 10
;   s 11 - DEG mode
;   s 12 - NORM mode
;   s 13 - shift
;   s 14
;   s 15 - hardware flag - ACT keyboard scanner

	.arch woodstock
	.org @0000

	reset twf
	p <- 0
	a + 1 -> a[p]
	a + 1 -> a[p]
	f exchange a[x]
	c -> data address
	clear data registers
	m2 exchange c
L0010:	0 -> c[w]
	display off
	0 -> s 11
	1 -> s 9
L0014:	1 -> s 8
	go to L0040

; slide switch handling from the a -> rom address instruction after L0144
; pin 5, KA: 0024 - MAN
; pin 6, KB: 0023 - not used
; pin 7, KC: 0022 - DEG
; pin 8, KD: 0021 - RAD
; pin 9, KE: 0020 - switch common, driven by ACT flag out
; ?      0025
; note F!, s 5 (ACT 3) is NORM,     
;      F2, s 3 (ACT 4) is from PIC
; XXX if MAN mode, how are DEG and RAD read?

L0016:	1 -> s 15
	go to L0022

	go to L0016		; at 0020

	1 -> s 0		; at 0021

L0022:	1 -> s 11
	go to L0372

	go to L0371		; at 0024

	1 -> s 0		; at 0025
	go to L0372


L0027:	0 -> a[xs]
	go to L0262

L0031:	if 1 = s 6
	  then go to L0331
	1 -> s 6
	0 -> a[x]
	go to L0056

L0036:	0 -> s 8
L0037:	0 -> s 9
L0040:	jsb S0156
	m1 exchange c
	m1 -> c
	delayed rom @02
	jsb S1267
	if 0 = s 11
	  then go to L0051
	if 1 = s 12
	  then go to L0754
L0051:	0 -> s 4
	0 -> s 6
	0 -> s 7
	0 -> s 10
	0 -> s 13
L0056:	delayed rom @03
	jsb S1641
L0060:	if p = 9
	  then go to L0550
	0 -> s 10
	m1 -> c
	if 1 = s 7
	  then go to L0102
	0 -> c[w]
	m1 exchange c
	if 1 = s 8
	  then go to L0073
	c -> stack
L0073:	a exchange b[x]
	0 -> a[w]
	a - 1 -> a[w]
	a exchange b[x]
	0 -> b[ms]
	0 -> c[w]
	0 -> s 8
L0102:	if p = 12
	  then go to L0336
	1 -> s 9
	1 -> s 7
	if p = 13
	  then go to L0146
	if p = 5
	  then go to L0367
	jsb S0215
	if 1 = s 6
	  then go to L0254
	shift left a[x]
	shift left a[x]
	p <- 3
L0120:	a + 1 -> a[p]
	if n/c go to L0227
	shift left a[wp]
	p + 1 -> p
	go to L0120

L0125:	jsb S0207		; wait for keyboard cycle
	1 -> s 0		; enable flag output
L0127:	if 0 = s 15
	  then go to L0127

	0 -> s 5

	a exchange c[x]
	b exchange c[w]

	keys -> a		; read status of slide switches as keycodes
	     			;   a[1] = column
				;   a[2] = row (unused in -91)
	0 -> a[xs]		; set digit 2 to 1, to ignore row and limit
	a + 1 -> a[xs]		;    range of a[2:1] to @20..24
	0 -> s 11

	0 -> s 12		; copy s5 (F1, NORM) to s12
	if 0 = s 5
	  then go to L0144
	1 -> s 12
L0144:

	jsb S0207		; wait for keyboard cycle
	a -> rom address	; dispatch slide switches

L0146:	if c[m] # 0
	  then go to L0031
	0 -> a[w]
	0 -> b[w]
	p <- 12
	a + 1 -> a[p]
	1 -> s 6
	go to L0236

S0156:	if c[m] # 0
	  then go to S0161
	0 -> c[w]
S0161:	p <- 12
	decimal
	if c[xs] = 0
	  then go to L0172
	c - 1 -> c[x]
	c + 1 -> c[xs]
	c - 1 -> c[xs]
	if n/c go to L0203
	c + 1 -> c[x]
L0172:	return

L0173:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
L0176:	p <- 13
	return

L0200:	0 -> s 11
L0201:	0 -> s 9
	go to L0014

L0203:	c + c -> c[xs]
	if n/c go to L0173
	0 -> c[w]
	go to L0176


; wait for keybaord cycle
S0207:	0 -> s 0		; disable flag output
L0210:	0 -> s 15
	if 1 = s 15
	  then go to L0210
L0213:	p <- 12
	return


S0215:	b -> c[w]
	p <- 0
L0217:	p - 1 -> p
	c - 1 -> c[s]
	if n/c go to L0217
	shift left a[wp]
	shift right a[w]
	a exchange c[w]
	c -> a[w]
	return

L0227:	a - 1 -> a[p]
	p - 1 -> p
	0 -> c[wp]
	if p = 2
	  then go to L0244
	if 1 = s 4
	  then go to L0241
L0236:	b exchange c[s]
	c + 1 -> c[s]
	b exchange c[s]
L0241:	a exchange c[p]
	c -> a[p]
	p - 1 -> p
L0244:	0 -> a[wp]
	a - 1 -> a[wp]
	shift right a[x]
	if 0 = s 6
	  then go to L0252
	0 -> a[x]
L0252:	a exchange b[x]
	go to L0273

L0254:	b -> c[x]
	a exchange b[x]
	shift left a[x]
	a exchange c[xs]
	p <- 0
	a exchange b[p]
L0262:	p <- 2
	a exchange b[x]
	b -> c[x]
L0265:	p + 1 -> p
	c + 1 -> c[p]
	if n/c go to L0271
	go to L0265

L0271:	c - 1 -> c[p]
	0 -> c[xs]
L0273:	decimal
	if b[xs] = 0
	  then go to L0277
	0 - c -> c[x]
L0277:	p <- 12
	b -> c[s]
	c - 1 -> c[x]
L0302:	if c[s] = 0
	  then go to L0310
	c + 1 -> c[x]
	c - 1 -> c[s]
	p - 1 -> p
	go to L0302

L0310:	shift right a[wp]
	shift left a[w]
	a exchange c[ms]
	0 -> a[x]
	delayed rom @04
	jsb S2075
	a exchange c[ms]
L0317:	0 -> c[s]
	decimal
	if b[p] = 0
	  then go to L0324
	0 - c - 1 -> c[s]
L0324:	jsb S0156
	0 -> s 11
	if p = 13
	  then go to L0040
	m1 exchange c
L0331:	a exchange b[x]
	go to L0056

L0333:	c + 1 -> c[p]
L0334:	b exchange c[w]
	go to L0317

L0336:	if 1 = s 6
	  then go to L0347
	if c[m] = 0
	  then go to L0331
	b exchange c[w]
	if c[p] = 0
	  then go to L0333
	0 -> c[p]
	go to L0334

L0347:	jsb S0215
	a exchange b[x]
	if a[xs] # 0
	  then go to L0027
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	if n/c go to L0262
L0356:	display off
	if 0 = s 11
	  then go to L0125
	a exchange c[x]
	c -> data address
	register -> c 15
L0364:	m1 -> c
L0365:	0 -> s 11
	go to L0037

L0367:	1 -> s 4
	go to L0331

; The slide switch handling from 0016 to 0026 jumps to either L0371 or
; L0372.
L0371:	1 -> s 15
L0372:	0 -> c[w]		; read keycode from PIK (reg 0xff)
	c - 1 -> c[w]
	c -> data address
	register -> c 15
	a exchange c[x]
	p <- 0
	0 -> a[p]
	a -> rom address	; in 0400-0777 page

L0402:	m1 exchange c
	c -> stack
	jsb S0765
	load constant 5
	load constant 9
	load constant 1
	load constant 4
	load constant 8
	m1 exchange c
	go to L0736

L0414:	decimal
	0 - c - 1 -> c[s]
	binary
	go to L0736

	go to L0461		; key 020 - multiply

	jsb S0766		; key 021 - subtract
	delayed rom @04
	go to L2000

	jsb S0772		; key 024 - divide
	delayed rom @04
	go to L2226

	nop

	jsb S0766		; key 030 - add
	go to L0746

L0432:	jsb S0774
	a exchange b[x]
	if 1 = s 9
	  then go to L0762
	0 -> s 11
	go to L0762

	jsb S0444		; key 040 - 9
	a + 1 -> a[p]		; key 041 - 6
L0442:	a + 1 -> a[p]
L0443:	a + 1 -> a[p]
S0444:	a + 1 -> a[p]		; key 044 - 3
L0445:	a + 1 -> a[p]
L0446:	a + 1 -> a[p]
	return

	jsb S0642		; key 050 - fix, sci
	if 0 = s 13
	  then go to L0455
	c + 1 -> c[p]
L0454:	c + 1 -> c[p]
L0455:	c + 1 -> c[p]
	0 -> s 13
	go to L0472

	nop

L0461:	jsb S0772
	delayed rom @04
	go to L2011

L0464:	jsb S0765
	delayed rom @04
	go to L2034

x_pi:	select rom go to op_pi

	jsb S0642		; key 070 - f
	1 -> s 13
L0472:	delayed rom @02
	go to L1051

L0474:	load constant 6
	m1 exchange c
	0 -> c[w]
	go to L0576

	jsb S0444		; key 100 - 8
	go to L0442		; key 101 - 5

L0502:	p <- 0
	go to L0505

	go to L0445		; key 104 - 2

L0505:	a + c -> c[p]
	if n/c go to L0515
	select rom go to L2510

	jsb S0772		; key 110 - sto, pi
	if 1 = s 13
	  then go to x_pi
	1 -> s 10
	go to x_rcl_sto		; sto

L0515:	p <- 3
	load constant 11
	go to L0631

	go to L0744		; key 120 - y^x, ->H.MS

	jsb S0765		; key 121 - tan, tan^-1
	delayed rom @11
	go to L4525

	jsb S0765		; key 124 - lin. est., L.R.
	delayed rom @10
	go to L4246

	nop

	jsb S0765		; key 130 - roll up
	load constant 7
	load constant 11
	load constant 1
	m1 exchange c
	down rotate
	down rotate
	go to L0735

	nop

L0541:	jsb S0765
	delayed rom @05
	go to L2722

	jsb S0642		; key 144 - rcl, last x
	if 1 = s 13
	  then go to x_lastx
x_rcl_sto:
	select rom go to L2550

L0550:	select rom go to L4151

L0551:	jsb S0774
	if 1 = s 13
	  then go to L1535
	load constant 2
	load constant 3
	load constant 4
	go to L0662

	nop

L0561:	jsb S0765
	delayed rom @06
	go to L3122

L0564:	if 0 = s 13		; key 164 - decimal, eng
	  then go to L1001
	jsb S0642
	go to L0454

	p <- 9			; key 170 - sigma+, sigma-
	return

L0572:	load constant 11
	load constant 1
	m1 exchange c
	c -> stack
L0576:	jsb S0713
	select rom go to L0200

L0600:	go to L0564

L0601:	go to L0564

L0602:	m1 -> c
	decimal
	return			; key 204 - 0

S0605:	jsb S0774
	load constant 12
	select rom go to L1210

L0610:	if 1 = s 13
	  then go to L0675
	if 1 = s 9
	  then go to L0010
	jsb S0765
	jsb S0677
	go to L0474

L0617:	go to L0742

L0620:	go to L0561		; key 220 - x^2, H.MS-

	jsb S0765		; key 221 - cos, cos^-1
	delayed rom @11
	go to L4707

	jsb S0765		; key 224 - %sigma, factorial
	delayed rom @06
	go to L3073

	nop

	go to L0665		; key 203 - ln, log

L0631:	select rom go to L3232

L0632:	load constant 13
	load constant 12
	m1 exchange c
	if c[m] = 0
	  then go to L0736
	go to L0414

	go to L0610		; key 240 - clear x, clear

	go to L0551		; key 241 - enter^

S0642:	0 -> s 10
	go to S0772

	a exchange c[w]		; key 244 - x<>y
	stack -> a
	a exchange c[w]
	go to L0402

	jsb S0774		; key 250 - chs
	if 1 = s 13
	  then go to L1723
	if 1 = s 7
	  then go to L0213
	load constant 3
	load constant 1
	go to L0632

	jsb S0444		; key 260 - 7
	go to L0443		; key 261 - 4

L0662:	load constant 2
	go to L0572

	go to L0446		; key 264 - 1

L0665:	jsb S0765
	delayed rom @05
	go to L2654

	jsb S0774		; key 270 - eex
	if 1 = s 13
	  then go to L1603
	p <- 13
	return

L0675:	jsb S0765
	select rom go to L3277

S0677:	select rom go to S3300

	go to L0464		; key 300 - sqrt, H.MS+

	jsb S0765		; key 301 - sin, sin^-1
	delayed rom @10
	go to L4374

	jsb S0765		; key 304 - %, delta%
	delayed rom @06
	go to L3006

x_lastx:
	select rom go to op_lastx

	jsb S0765		; key 310 - e^x, 10^x
	delayed rom @05
	go to L2622

S0713:	m1 exchange c
S0714:	a exchange b[x]
S0715:	if 1 = s 11
	  then go to L1457
	go to L0602

	go to L0541		; key 320 - 1/x, H.MS->

	jsb S0765		; key 321 - p->r, std. dev.
	delayed rom @10
	go to L4316

	jsb S0765		; key 324 - r->p, mean
	delayed rom @10
	go to L4115

L0727:	go to S0714

L0730:	jsb S0765		; key 330 - roll down
	load constant 7
	load constant 11
	load constant 5
	m1 exchange c
L0735:	down rotate
L0736:	jsb S0713
	go to L0742

L0740:	go to L0730

L0741:	go to L0730

L0742:	delayed rom @00
	go to L0036

L0744:	jsb S0765
	select rom go to L2746

L0746:	delayed rom @04
	go to L2205

	jsb S0774		; key 350 - print x
	a exchange b[x]
	if 1 = s 9
	  then go to L0761
L0754:	p <- 3
	load constant 6
	load constant 1
	load constant 8
	load constant 6
L0761:	1 -> s 11
L0762:	1 -> s 9
	jsb S0715
	select rom go to L0365

S0765:	0 -> s 10
S0766:	0 -> s 4
	0 -> s 6
	0 -> s 7
	0 -> s 8
S0772:	p <- 5
	0 -> b[p]
S0774:	0 -> c[w]
	c - 1 -> c[w]
	p <- 7
	load constant 12
	0 -> c[wp]
L1001:	p <- 5
	return

L1003:	p <- 2
	load constant 14
	load constant 14
	load constant 14
	go to L1130

L1010:	p - 1 -> p
	a + 1 -> a[p]
	if n/c go to L1020
	go to L1104

L1014:	p <- 13
	load constant 14
L1016:	p <- 0
	select rom go to L1420

L1020:	a - 1 -> a[p]
	.legal
	go to L1104

	nop

L1023:	f exchange a[x]
	b exchange c[w]
	p <- 5
	c - 1 -> c[p]
	if n/c go to L1060
L1030:	b exchange c[w]
	select rom go to L0432

L1032:	1 -> s 2
	c - 1 -> c[p]
	if n/c go to L1030
	1 -> s 1
	go to  L1030

L1037:	a + 1 -> a[x]
	if n/c go to L1200
	a + c -> c[m]
	if n/c go to L1200
	go to L1315

L1044:	a - 1 -> a[p]
L1045:	p - 1 -> p
	c + 1 -> c[s]
	decimal
	go to L1155

L1051:	a exchange b[x]
	b exchange c[p]
	delayed rom @03
	jsb S1641
	if p = 0
	  then go to L1023
	select rom go to L0060

L1060:	0 -> s 1
	0 -> s 2
	c - 1 -> c[p]
	if n/c go to L1032
	go to L1030

L1065:	c - 1 -> c[x]
	c + 1 -> c[xs]
	p <- 2
	0 -> a[w]
	go to L1325

L1072:	c - 1 -> c[x]
	if n/c go to L1144
	if a[xs] # 0
	  then go to L1157
L1076:	a - 1 -> a[x]
L1077:	binary
	c + 1 -> c[s]
	a + 1 -> a[p]
	if n/c go to L1164
	go to L1165

L1104:	if p = 2
	  then go to L1110
	a - 1 -> a[x]
	if n/c go to L1010
L1110:	c -> a[x]
	p <- 0
	c + 1 -> c[p]
	c - 1 -> c[p]
	if n/c go to L1137
	if 1 = s 2
	  then go to L1003
L1117:	shift right a[w]
	p <- 12
	a exchange c[w]
	if b[p] = 0
	  then go to L1014
	p <- 13
	load constant 11
	go to L1016

L1127:	load constant 11
L1130:	a exchange c[ms]
	0 -> c[ms]
	c - 1 -> c[ms]
	delayed rom @03
	jsb S1765
	pick print 3
	go to L1117

L1137:	p <- 2
	if c[xs] # 0
	  then go to L1127
	load constant 12
	go to L1130

L1144:	c - 1 -> c[x]
	if n/c go to L1360
	if a[xs] # 0
	  then go to L1155
	a - 1 -> a[x]
	binary
	a + 1 -> a[p]
	if n/c go to L1167
	go to L1170

L1155:	a + 1 -> a[x]
	if n/c go to L1077
L1157:	a + 1 -> a[x]
	binary
	a + 1 -> a[p]
	if n/c go to L1044
	go to L1045

L1164:	a - 1 -> a[p]
L1165:	p - 1 -> p
	go to L1362

L1167:	a - 1 -> a[p]
L1170:	p - 1 -> p
	c + 1 -> c[s]
	decimal
	go to L1076

L1174:	c + 1 -> c[s]
	if n/c go to L1233
	p <- 1
	c + 1 -> c[p]
L1200:	p <- 2
	go to L1323

L1202:	b exchange c[s]
	c + 1 -> c[s]
	b exchange c[s]
	p - 1 -> p
	shift right a[w]
	go to L1254

L1210:	load constant 2
	load constant 13
	load constant 0
	load constant 12
	load constant 10
	p <- 5
	if b[p] = 0
	  then go to L1225
	b exchange c[p]
	c - 1 -> c[p]
	b exchange c[p]
	if b[p] = 0
	  then go to L0502
L1225:	p <- 0
	a exchange c[p]
	c -> a[p]
	select rom go to L0631

	nop
	nop

L1233:	if p = 2
	  then go to L1236
	p - 1 -> p
L1236:	c - 1 -> c[x]
	if n/c go to L1174
	0 -> a[x]
L1241:	binary
	c + 1 -> c[s]
	decimal
	b exchange c[s]
	0 -> c[w]
	a exchange c[w]
	c -> a[wp]
	a + c -> a[w]
	binary
	if a[s] # 0
	  then go to L1202
L1254:	b -> c[s]
	0 -> a[wp]
	a - 1 -> a[wp]
	p <- 13
L1260:	p - 1 -> p
	c - 1 -> c[s]
	if n/c go to L1260
	shift right a[wp]
	shift left a[w]
	shift right a[x]
	go to L1371

S1267:	decimal
	0 -> a[w]
	0 -> b[ms]
	p <- 12
	f -> a[x]
	if c[s] = 0
	  then go to L1301
	a - 1 -> a[p]
	a exchange b[p]
	0 -> c[s]
L1301:	p - 1 -> p
	a - 1 -> a[x]
	if n/c go to L1301
	0 -> a[x]
	c -> a[m]
	if 1 = s 2
	  then go to L1323
	f -> a[x]
	if c[xs] = 0
	  then go to L1236
	a + c -> a[x]
	if n/c go to L1037
L1315:	0 -> a[x]
L1316:	c + 1 -> c[x]
	shift right a[w]
	if c[x] = 0
	  then go to L1241
	go to L1316

L1323:	0 -> c[m]
	a exchange c[m]
L1325:	c -> a[wp]
	0 -> a[x]
	a + c -> a[m]
	if n/c go to L1340
	a + 1 -> a[s]
	shift right a[w]
	c + 1 -> c[x]
	c - 1 -> c[xs]
	if c[x] = 0
	  then go to L1065
	c + 1 -> c[xs]
L1340:	0 -> a[wp]
	binary
	a - 1 -> a[wp]
	decimal
	0 -> a[x]
	if c[xs] = 0
	  then go to L1353
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	0 - c -> c[x]
	a exchange c[xs]
L1353:	c -> a[x]
	p <- 11
	0 -> c[xs]
	if 0 = s 1
	  then go to L1362
L1360:	c - 1 -> c[x]
	if n/c go to L1072
L1362:	c + 1 -> c[s]
	b exchange c[s]
	a exchange c[x]
	shift right a[wp]
	shift left a[w]
	a exchange c[x]
	binary
L1371:	select rom go to S0772

L1372:	0 -> s 4
	delayed rom @00
	jsb S0156
	m1 exchange c
	if 0 = s 11
	  then go to L1763
	if 0 = s 12
	  then go to L1763
S1402:	0 -> c[x]
	p <- 2
	return

L1405:	b exchange c[x]
	decimal
	c + 1 -> c[p]
	if n/c go to L1412
	1 -> s 4
L1412:	b exchange c[x]
	0 -> s 0
	0 -> s 5
	if 1 = s 5
	  then go to L1730
	go to L1763

L1420:	shift right c[w]
	c - 1 -> c[s]
L1422:	shift right c[w]
	c - 1 -> c[s]
	c + 1 -> c[p]
	if n/c go to L1710
	go to L1422

S1427:	load constant 13
S1430:	load constant 8
S1431:	go to L1461

S1432:	b exchange c[x]
S1433:	binary
	p <- 0
	c + 1 -> c[p]
S1436:	c -> data address
	b exchange c[x]
	data -> c
	delayed rom @02
	jsb S1267
	load constant 6
	load constant 1
S1445:	if 1 = s 3
	  then go to L1763
	return

S1450:	load constant 14
	load constant 2
	load constant 9
	load constant 12
	load constant 0
	load constant 10
	a exchange b[x]
L1457:	if 0 = s 9
	  then go to S1506
L1461:	jsb S1765
	jsb S1773
	pick print 6
S1464:	jsb S1567
	if 1 = s 3
	  then go to L1720
	p <- 0
	b -> c[w]
	a -> b[w]
L1472:	p - 1 -> p
	c - 1 -> c[s]
	if n/c go to L1472
	b exchange c[w]
	load constant 10
	p + 1 -> p
	c -> a[p]
	0 -> a[x]
	f -> a[x]
	select rom go to L1104

L1504:	pick print 3
L1505:	return

S1506:	p <- 11
L1507:	load constant 0
	if p # 6
	  then go to L1507
	jsb S1765
	jsb S1773
	pick print 6
	jsb S1567
	go to L1720

S1517:	delayed rom @02
	jsb S1267
	0 -> c[w]
	c - 1 -> c[w]
	p <- 4
	0 -> c[wp]
	b -> c[x]
	jsb S1765
	jsb S1773
	pick print 2
	jsb S1567
	if 1 = s 3
	  then go to L1555
	go to S1464

L1535:	jsb S1450
	down rotate
	down rotate
	1 -> s 4
	m1 exchange c
	jsb S1402
	load constant 2
L1544:	b exchange c[x]
	y -> a
	a exchange c[w]
	jsb S1517
	b exchange c[x]
	c + 1 -> c[xs]
	b exchange c[x]
	m1 -> c
	jsb S1517
L1555:	if 0 = s 4
	  then go to L1763
	0 -> s 4
	m1 -> c
	down rotate
	down rotate
	m1 exchange c
	b exchange c[x]
	c + 1 -> c[xs]
	if n/c go to L1544
S1567:	p <- 5
L1570:	0 -> s 3
	pick print home?
	if 0 = s 3
	  then go to L1505
	c - 1 -> c[s]
	if n/c go to L1570
	p - 1 -> p
	if p # 0
	  then go to L1570
	load constant 15
	go to L1504

L1603:	jsb S1450
	0 -> c[w]
	p <- 0
	load constant 9
	jsb S1433
	p <- 5
	load constant 0
	load constant 3
	load constant 4
	jsb S1431
	jsb S1432
	load constant 6
	jsb S1431
	jsb S1432
	load constant 6
	jsb S1427
	jsb S1432
	load constant 2
	jsb S1431
	jsb S1432
	load constant 2
	jsb S1427
	jsb S1432
	load constant 6
	load constant 4
	jsb S1430
	go to L1763

L1636:	m1 -> c
	if 1 = s 11
	  then go to L0365
S1641:	b -> c[w]
	0 -> s 11
	0 -> c[x]
	p <- 12
	if c[p] # 0
	  then go to L1651
	c + 1 -> c[xs]
	c + 1 -> c[xs]
L1651:	p <- 0
L1652:	p - 1 -> p
	c - 1 -> c[s]
	if n/c go to L1652
	0 -> c[ms]
	load constant 3
	b exchange c[w]
L1660:	jsb S1765
	display toggle
	hi i'm woodstock
	binary
	0 -> s 0
L1665:	pick key?
	if 1 = s 3
	  then go to L0356
	0 -> s 5
	if 1 = s 5
	  then go to L1665
	display off
	b exchange c[w]
	0 -> c[w]
	c - 1 -> c[w]
	p <- 7
	0 -> c[wp]
L1701:	jsb S1773
	if 1 = s 5
	  then go to L1636
	pick print 0
	jsb S1765
	go to L1701

	nop

L1710:	c - 1 -> c[p]
	p <- 2
	c + 1 -> c[p]
	c - 1 -> c[p]
	if n/c go to L1716
	load constant 14
L1716:	jsb S1765
	pick print 3
L1720:	m1 -> c
	decimal
	return

L1723:	jsb S1450
	0 -> s 4
	0 -> c[w]
	p <- 2
	load constant 13
L1730:	jsb S1436
	0 -> c[w]
	c - 1 -> c[w]
	p <- 4
	load constant 14
	load constant 14
	b -> c[x]
	p <- 1
	load constant 14
	if 0 = s 4
	  then go to L1751
	p <- 1
	load constant 10
	decimal
	c + 1 -> c[p]
	c - 1 -> c[p]
	binary
L1751:	jsb S1765
	jsb S1773
	pick print 3
	jsb S1464
	jsb S1445
	b -> c[w]
	binary
	p <- 0
	c + 1 -> c[p]
	if n/c go to L1405
L1763:	m1 -> c
	select rom go to L0365

S1765:	0 -> s 3
L1766:	pick print cr?
	if 0 = s 3
	  then go to L1766
	0 -> s 3
	return

S1773:	0 -> s 3
L1774:	pick print home?
	if 0 = s 3
	  then go to L1774
	return

L2000:	jsb S2363
	jsb S2312
	jsb S2027
	0 - c - 1 -> c[s]
L2004:	jsb S2044
	go to L2043

	nop

L2007:	go to S2075

	nop

L2011:	if 1 = s 13
	  then go to L3017
	jsb S2362
	load constant 10
	jsb S2313
	stack -> a
L2017:	jsb S2327
	go to L2043

S2021:	if c[m] = 0
	  then go to L3216
	stack -> a
S2024:	jsb S2027
S2025:	jsb S2160
	go to S2334

S2027:	m2 exchange c		; copy x to LASTx
	m2 -> c
	return

S2032:	p <- 12
	go to L2266

L2034:	if 1 = s 13
	  then go to L2740

L2036:	load constant 14
	load constant 9
	load constant 6
	jsb S2313
	jsb S2110
L2043:	select rom go to L3044
S2044:	stack -> a
S2045:	jsb S2032
	go to S2334

S2047:	a + c -> c[x]
	p <- 3
	a - c -> c[s]
	if n/c go to L2054
	0 - c -> c[s]
L2054:	0 -> a[w]
S2055:	select rom go to L2456

L2056:	shift right a[wp]
L2057:	a - 1 -> a[s]
	if n/c go to L2056
	0 -> a[s]
	a + b -> a[w]
	a + 1 -> a[p]
	if n/c go to L2251
	shift right a[wp]
	a + 1 -> a[p]
	if n/c go to L2254
L2070:	if a >= b[m]
	  then go to L2074
	0 - c - 1 -> c[s]
	a exchange b[w]
L2074:	a - b -> a[w]
S2075:	p <- 12
	if a[wp] # 0
	  then go to L3701
	0 -> c[x]
L2101:	return

L2102:	a exchange c[s]
	jsb S2055
	jsb S2202
	0 -> c[m]
	delayed rom @06
	go to L3257

S2110:	if c[s] # 0
	  then go to L3216
	jsb S2027
S2113:	0 -> a[w]
	a exchange c[m]
	jsb S2117
	go to L2153

S2117:	a -> b[w]
	b exchange c[w]
	c + c -> c[w]
	c + c -> c[w]
	a + c -> c[w]
	b exchange c[w]
	0 -> c[ms]
	c -> a[w]
	c + c -> c[x]
	if n/c go to L2132
	c - 1 -> c[m]
L2132:	c + c -> c[x]
	a + c -> c[x]
	p <- 0
	if c[p] # 0
	  then go to L2140
	shift right b[w]
L2140:	shift right c[w]
	a exchange c[x]
	0 -> c[w]
	a exchange b[w]
	p <- 13
	load constant 5
	shift right c[w]
	select rom go to L3150

S2150:	if 0 = s 4
	  then go to L2153
	0 - c - 1 -> c[s]
L2153:	jsb S2075
	jsb S2334
	select rom go to S0156

L2156:	jsb S2024
	go to L2043

S2160:	0 -> b[w]
	b exchange c[m]
L2162:	a - c -> c[s]
	if n/c go to L2165
	0 - c -> c[s]
L2165:	a - c -> c[x]
	0 -> a[x]
	0 -> a[s]
S2170:	0 -> c[m]
	p <- 12
	go to L2315

L2173:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] # 0
	  then go to L2070
	a + b -> a[w]
S2202:	if a[s] # 0
	  then go to L3165
	return

L2205:	jsb S2364
	load constant 11
	jsb S2313
	jsb S2027
	go to L2004

L2212:	a exchange b[w]
	stack -> a
L2214:	a exchange c[w]
	jsb S2027
	jsb S2047
	0 -> c[m]
	delayed rom @07
	go to L3633

L2222:	b exchange c[w]
	jsb S2170
	jsb S2334
	go to L2043

L2226:	if 1 = s 13
	  then go to L3027
	jsb S2361
	load constant 9
	jsb S2313
	jsb S2021
	go to L2043

L2235:	0 -> a[w]
	jsb S2376
	p + 1 -> p
	if p = 13
	  then go to L2243
	p + 1 -> p
L2243:	jsb S2376
	shift left a[w]
	a + c -> a[w]
	b exchange c[w]
	jsb S2202
L2250:	go to L2153

L2251:	a -> b[w]
	c - 1 -> c[s]
	if n/c go to L2057
L2254:	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	a - 1 -> a[s]
	if n/c go to L2251
	a exchange b[w]
	a + 1 -> a[p]
L2264:	jsb S2150
	go to L2043

L2266:	0 -> b[w]
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a >= c[x]
	  then go to L2276
	a exchange c[w]
L2276:	a exchange c[m]
	if c[m] = 0
	  then go to L2302
	a exchange c[w]
L2302:	b exchange c[m]
L2303:	if a >= c[x]
	  then go to L2173
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	  then go to L2173
	go to L2303

S2312:	load constant 8
S2313:	select rom go to S0714

L2314:	c + 1 -> c[p]
L2315:	a - b -> a[w]
	if n/c go to L2314
	a + b -> a[w]
	p - 1 -> p
	if p # 2
	  then go to L2351
	a + 1 -> a[ms]
	b exchange c[x]
	0 -> c[x]
	go to L2347

S2327:	jsb S2027
S2330:	0 -> b[w]
	a exchange b[m]
L2332:	jsb S2047
	jsb S2202
S2334:	p <- 12
	0 -> b[w]
	a -> b[x]
	a + b -> a[wp]
	if n/c go to L2343
	c + 1 -> c[x]
	a + 1 -> a[p]
L2343:	a exchange c[m]
	c -> a[w]
	return

L2346:	a - 1 -> a[ms]
L2347:	if a >= b[w]
	  then go to L2346
L2351:	shift left a[w]
	if p # 13
	  then go to L2315
	0 -> a[w]
	a exchange c[w]
	a exchange c[s]
	b exchange c[x]
	go to S2075

S2361:	c + 1 -> c[p]
S2362:	c + 1 -> c[p]
S2363:	c + 1 -> c[p]
S2364:	c + 1 -> c[p]
	if 0 = s 10
	  then go to L2372
L2367:	c + 1 -> c[p]
	if b[p] = 0
	  then go to L2547
L2372:	0 -> c[p]
	p <- 2
	return

L2375:	go to L2367

S2376:	shift right c[wp]
	a + c -> c[wp]
S2400:	c -> a[wp]
	shift right c[wp]
	c + c -> c[wp]
	c + c -> c[wp]
	a - c -> c[wp]
	if 0 = s 8
	  then go to L2525
	0 -> a[w]
	c -> a[x]
	a + c -> c[w]
	0 -> c[x]
	return

S2414:	load constant 7
	load constant 5
	load constant 9
	load constant 12
	load constant 2
	load constant 14
	return

L2423:	load constant 11
	load constant 9
	load constant 13
	load constant 6
	load constant 7
	1 -> s 8
L2431:	jsb S2533
	jsb S2535
L2433:	b exchange c[w]
	jsb S2571
L2435:	select rom go to L0036

L2436:	jsb S2414
	c + 1 -> c[w]
	jsb S2533
	jsb S2535
	0 - c - 1 -> c[s]
L2443:	b exchange c[w]
	jsb S2571
	stack -> a
	c -> stack
	a exchange b[w]
	jsb S2571
	delayed rom @04
	jsb S2044
	1 -> s 8
	go to L2433

L2455:	a + b -> a[w]
L2456:	c - 1 -> c[p]
	if n/c go to L2455
	if p = 12
	  then go to L3167
	p + 1 -> p
	shift right a[w]
	go to L2456

L2465:	if b[xs] = 0
	  then go to L2604
	go to L2763

op_pi:	p <- 3
	load constant 9
	jsb S2533
	jsb S2650
	delayed rom @12
	jsb trc10		; get pi/4
	c + c -> c[w]		; multiply by 4
	c + c -> c[w]
	shift right c[w]	; position appropriately
	c + 1 -> c[m]		; round
	0 -> c[x]		; clear exponent
	go to l2435

L2504:	jsb S2414
	go to L2431

L2506:	jsb S2774
	p <- 5
L2510:	0 -> s 10
	delayed rom @00
	go to L0060

L2513:	m1 exchange c
	jsb S2650
	m1 exchange c
	load constant 4
	jsb S2533
	delayed rom @06
	jsb S3157
	a exchange c[w]
	go to L2435

L2524:	select rom go to L4125

L2525:	a + c -> a[wp]
	shift right c[wp]
	if c[wp] # 0
	  then go to L2525
	return

S2532:	load constant 2
S2533:	delayed rom @01
	go to S0714

S2535:	delayed rom @04
	go to S2027

L2537:	if 0 = s 10
	  then go to L3216
	stack -> a
	if a[m] # 0
	  then go to L3427
L2544:	c -> stack
	a exchange c[w]
	go to L2615

L2547:	b exchange c[p]
L2550:	a exchange b[x]		; 2550 - sto, rcl
	delayed rom @03
	jsb S1641
	0 -> c[w]
	if p = 5
	  then go to L2506
	if 1 = s 10
	  then go to L3217
	if p = 9
	  then go to L2524
	if p # 0
	  then go to L2510
	delayed rom @01
	jsb S0605
	if b[p] = 0
	  then go to L2513
	go to L2510

S2571:	if b[m] = 0
	  then go to L2604
	p <- 12
	b -> c[x]
	c + 1 -> c[x]
	c + 1 -> c[x]
	if c[xs] # 0
	  then go to L2465
L2601:	p - 1 -> p
	if p # 0
	  then go to L2761
L2604:	b -> c[w]
	return

L2606:	load constant 5
	load constant 4
	load constant 13
	jsb S2533
	y -> a
	if a[w] # 0
	  then go to L3033
L2615:	select rom go to L3216

L2616:	b exchange c[w]
	delayed rom @07
	jsb lnc10
	select rom go to L2222

L2622:	if 1 = s 13
	  then go to L3306
	load constant 9
	load constant 7
	jsb S2532
	0 -> a[w]
	jsb S2535
	a exchange c[m]
	select rom go to L3633

L2633:	load constant 0
	load constant 3
	load constant 5
	1 -> s 6
	go to L2661

L2640:	p + 1 -> p
	jsb S2400
	p - 1 -> p
L2643:	p - 1 -> p
	jsb S2400
	c -> a[w]
	b -> c[w]
	select rom go to L2250

S2650:	if 1 = s 8		; check stack lift disable
	  then go to L2653
	c -> stack
L2653:	return

L2654:	load constant 14
	if 1 = s 13
	  then go to L2633
	load constant 3
	load constant 4
L2661:	jsb S2533
L2662:	p <- 12
	if c[w] = 0
	  then go to L2537
	if c[s] # 0
	  then go to L3736
	jsb S2535
L2670:	if c[x] = 0
	  then go to L2775
	c + 1 -> c[x]
	0 -> a[w]
	a - c -> a[m]
	if c[x] = 0
	  then go to L3657
L2677:	shift right a[wp]
	a -> b[s]
	p <- 13
L2702:	p - 1 -> p
	a - 1 -> a[s]
	if n/c go to L2702
	a exchange b[s]
	0 -> c[ms]
	select rom go to L3710

op_lastx:
	load constant 14
	load constant 3
	load constant 0
	load constant 2
	load constant 9
	load constant 6
	jsb S2533
	jsb S2650
	m2 -> c
	go to L2435

L2722:	if 1 = s 13
	  then go to L2504
	load constant 1
	load constant 15
	load constant 9
	load constant 5
	load constant 8
	jsb S2533
	0 -> a[w]
	p <- 12
	a + 1 -> a[p]
	if c[m] # 0
	  then go to L2156
	go to L2615

L2740:	jsb S2414
	c - 1 -> c[w]
	c - 1 -> c[w]
	jsb S2533
	jsb S2535
	go to L2443

L2746:	if 1 = s 13
	  then go to L2423
	load constant 4
	load constant 11
	jsb S2532
	stack -> a
	c -> stack
	a exchange c[w]
	1 -> s 6
	1 -> s 10
	go to L2662

L2761:	c - 1 -> c[x]
	if n/c go to L2601
L2763:	0 -> c[w]
	b -> c[m]
	if 0 = s 8
	  then go to L2235
	p + 1 -> p
	if p # 13
	  then go to L2640
	jsb S2400
	go to L2643

S2774:	select rom go to L2375

L2775:	c -> a[w]
	a - 1 -> a[p]
	if a[m] # 0
	  then go to L3670
	0 -> c[w]
	go to L3257

S3003:	load constant 8
S3004:	delayed rom @01
	go to S0714

L3006:	if 1 = s 13
	  then go to L2606
	p <- 3
	load constant 13
	jsb S3004
	y -> a
	a - 1 -> a[x]
	a - 1 -> a[x]
L3016:	select rom go to L2017

L3017:	jsb S3300
	jsb S3003
	0 -> c[w]
	p <- 0
	load constant 10
	binary
	go to L3353

S3026:	select rom go to S2027

L3027:	jsb S3300
	jsb S3004
	0 -> b[w]
	go to L3352

L3033:	jsb S3026
	delayed rom @10
	jsb S4040
	y -> a
L3037:	a exchange c[w]
	a + 1 -> a[x]
	a + 1 -> a[x]
	delayed rom @04
	jsb S2025
L3044:	delayed rom @00
	go to L0036

L3046:	a - 1 -> a[p]
	if n/c go to L3111
	a exchange b[p]
	p <- 3
	load constant 0
	jsb S3004
	jsb S3157
	0 - c - 1 -> c[s]
L3056:	delayed rom @04
	jsb S2045
L3060:	delayed rom @00
	jsb S0156
	c -> data
	m1 -> c
	0 -> s 8
	go to L3363

S3066:	p + 1 -> p
S3067:	c - 1 -> c[x]
	if p # 12
	  then go to S3066
	return

L3073:	if 1 = s 13
	  then go to L3170
	load constant 3
	load constant 5
	load constant 8
	jsb S3004
	a exchange c[w]
	0 -> c[w]
	c -> data address
	register -> c 11
	a exchange c[w]
	if a[w] # 0
	  then go to L3275
	go to L3216

L3111:	a - 1 -> a[p]
	if n/c go to L3322
	a exchange b[p]
	p <- 3
	jsb S3003
	jsb S3157
	delayed rom @04
	jsb S2330
	go to l3060

L3122:	if 1 = s 13
	  then go to L2436
	load constant 5
	load constant 11
	load constant 6
	jsb S3004
	c -> a[w]
	go to L3016

L3132:	a - 1 -> a[p]
	if n/c go to L3046
	a exchange b[p]
	p <- 3
	load constant 12
	jsb S3004
	jsb S3157
	go to L3056

L3142:	c + 1 -> c[p]
L3143:	a - c -> a[w]
	if n/c go to L3142
	a + c -> a[w]
	shift left a[w]
	p - 1 -> p
L3150:	shift right c[wp]
	if p # 0
	  then go to L3143
	0 -> c[p]
	a exchange c[w]
	b exchange c[w]
	return

S3157:	b exchange c[x]
	c -> data address
	data -> c
	a exchange c[w]
	m1 -> c
	return

L3165:	c + 1 -> c[x]
	shift right a[w]
L3167:	return

L3170:	load constant 13
	load constant 1
	load constant 12
	jsb S3004
	p <- 12
	if c[s] # 0
	  then go to L3216
	if c[xs] # 0
	  then go to L3216
	c -> a[w]
L3202:	a -> b[w]
	shift left a[ms]
	if a[wp] # 0
	  then go to L3214
	jsb S3026
	a + 1 -> a[x]
	if a >= c[x]
	  then go to L3544
	c + 1 -> c[xs]
	if n/c go to L3044
L3214:	a - 1 -> a[x]
	if n/c go to L3202
L3216:	select rom go to L4617

L3217:	if p # 0
	  then go to L2510
	delayed rom @01
	jsb S0605
	a exchange b[p]
	a - 1 -> a[p]
	if n/c go to L3132
	a exchange b[p]
	jsb S3004
	jsb S3157
	go to L3060

L3232:	p <- 0
	shift left a[x]
	shift left a[x]
	a exchange c[p]
	a exchange c[xs]
	p <- 5
	return

L3241:	a + b -> a[w]
L3242:	c - 1 -> c[p]
	if n/c go to L3241
	if c[s] # 0
	  then go to L3417
	if p = 12
	  then go to L3447
	0 -> c[w]
	jsb S3066
L3252:	jsb S3364
	0 -> a[s]
	if 0 = s 7
	  then go to L3257
	0 - c - 1 -> c[s]
L3257:	if 1 = s 10
	  then go to L2212
	if 1 = s 6
	  then go to L2616
	select rom go to L2264

lncd1:	p <- 9			; ln(1.1)
	load constant 3
	load constant 1
	load constant 0
	load constant 1
	load constant 7
	load constant 9
	load constant 8
	select rom go to L4675

L3275:	jsb S3026
	go to L3037

L3277:	go to L3334

S3300:	load constant 3
	load constant 3
	load constant 8
	load constant 0
	load constant 1
	return

L3306:	load constant 1
	load constant 12
	load constant 3
	load constant 12
	jsb S3003
	a exchange c[w]
	delayed rom @07
	jsb lnc10
	b exchange c[w]
	0 -> c[w]
	delayed rom @04
	go to L2214

L3322:	a exchange b[p]
	p <- 3
	load constant 4
	jsb S3004
	jsb S3157
	if c[m] = 0
	  then go to L3216
	delayed rom @04
	jsb S2025
	go to L3060

L3334:	p <- 6
	load constant 12
	load constant 14
	load constant 0
	load constant 8
	load constant 9
	load constant 9
	0 -> s 9
	jsb S3004
	clear regs
	m1 exchange c
	0 -> c[w]
	m2 exchange c
	binary
L3352:	0 -> c[w]
L3353:	0 -> b[w]
	p <- 0
L3355:	c -> data address
	b exchange c[w]
	c -> data
	b exchange c[w]
	c + 1 -> c[p]
	if n/c go to L3355
L3363:	select rom go to L0364

S3364:	delayed rom @04
	go to S2075

L3366:	p <- 11			; load ln(2)
	load constant 6
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
	go to L3625

load33:	load constant 3
	load constant 3
	return

S3406:	select rom go to L2007

lncd3:	p <- 5			; ln(1.001)
	jsb load33
	load constant 3
	load constant 0
	load constant 8
	load constant 4
	p <- 9
	return

L3417:	c - 1 -> c[s]
	p + 1 -> p
L3421:	b exchange c[w]
	jsb S3502
	shift right a[w]
	b exchange c[w]
	delayed rom @06
	go to L3242

L3427:	if a[s] # 0
	  then go to L2544
	a exchange c[w]
	delayed rom @04
	jsb S2027
	0 -> c[w]
L3435:	select rom go to L0036

L3436:	c + 1 -> c[s]
S3437:	a - b -> a[w]
	if n/c go to L3436
	a + b -> a[w]
	shift left a[w]
	shift right c[ms]
	b exchange c[w]
	p - 1 -> p
	return

L3447:	if c[x] = 0
	  then go to L3252
	c - 1 -> c[w]
	b exchange c[w]
	0 -> b[m]
	jsb lnc10
	a exchange c[w]
	a - c -> c[w]
	if b[xs] = 0
	  then go to L3462
	a - c -> c[w]
L3462:	a exchange c[w]
	b exchange c[w]
	if c[xs] = 0
	  then go to L3467
	0 - c - 1 -> c[w]
L3467:	a exchange c[wp]
L3470:	p - 1 -> p
	shift left a[w]
	if p # 1
	  then go to L3470
	p <- 12
	if a[p] # 0
	  then go to L3654
	shift left a[m]
L3500:	a exchange c[w]
	select rom go to L2102

S3502:	0 -> c[w]
	if p = 12
	  then go to L3366
	c - 1 -> c[w]
	load constant 4
	c + 1 -> c[w]
	0 -> c[s]
	shift right c[w]
	if p = 10
	  then go to lncd1
	if p = 9
	  then go to lncd2
	if p = 8
	  then go to lncd3
	if p = 7
	  then go to lncd4
	if p = 6
	  then go to lncd5
	p + 1 -> p
	return

lncd2:	p <- 7
	jsb load33
	load constant 0
	load constant 8
	load constant 5
	load constant 3
	load constant 1
	load constant 7
	p <- 10
	return

l3540:	if a[x] # 0
	  then go to l3745
	a exchange b[w]
	select rom go to L2544

L3544:	0 -> c[w]
	c + 1 -> c[p]
	shift right c[w]
	c + 1 -> c[s]
	b exchange c[w]
L3551:	if b[p] = 0
	  then go to L3555
	shift right b[wp]
	c + 1 -> c[x]
L3555:	0 -> a[w]
	a - c -> a[p]
	if n/c go to L3563
	shift left a[w]
L3561:	a + b -> a[w]
	if n/c go to L3561
L3563:	a - c -> a[s]
	if n/c go to L3572
	shift right a[wp]
	a + 1 -> a[w]
	c + 1 -> c[x]
L3570:	a + b -> a[w]
	if n/c go to L3570
L3572:	a exchange b[wp]
	c - 1 -> c[p]
	if n/c go to L3551
	c - 1 -> c[s]
	if n/c go to L3551
	shift left a[w]
	a -> b[x]
	a + b -> a[wp]
	0 -> c[ms]
	a + c -> a[w]
	a exchange c[ms]
	go to L3435

lnc10:	0 -> c[w]		; ln(10)
	p <- 12
	load constant 2
	load constant 3
	load constant 0
	load constant 2
	load constant 5
	load constant 8
	load constant 5
	load constant 0
	load constant 9
	load constant 2
	load constant 9
	load constant 9
	load constant 4
L3625:	p <- 12
	return

lncd5:	p <- 1		; ln(1.00001)
	jsb load33
	p <- 7
	return

L3633:	b exchange c[w]
	jsb lnc10
	b exchange c[w]
	1 -> s 8
	delayed rom @11
	jsb S4573
	b exchange c[w]
L3642:	jsb S3502
	b exchange c[w]
	jsb S3437
	if p # 5
	  then go to L3642
	p <- 13
	load constant 7
	a exchange c[s]
	b exchange c[w]
	select rom go to L2254

L3654:	a + 1 -> a[x]
	p - 1 -> p
	go to L3500

L3657:	1 -> s 7
	jsb S3406
	go to L3675

L3662:	1 -> s 4
L3663:	0 -> c[s]		; maybe trg120
L3664:	b exchange c[w]		; maybe trg130
	c -> stack
	b exchange c[w]
	select rom go to L2670

L3670:	jsb S3406
	delayed rom @04
	jsb S2160
	a + c -> a[s]
	a - 1 -> a[s]
L3675:	0 -> c[x]
	select rom go to L2677

L3677:	a + 1 -> a[s]
	c - 1 -> c[x]
L3701:	if a[p] # 0
	  then go to L2101
	shift left a[wp]
	go to L3677

L3705:	shift right a[w]
	c + 1 -> c[p]
L3707:	a exchange b[s]
L3710:	a -> b[w]
	binary
	a + c -> a[s]
	m1 exchange c
	a exchange c[s]
	shift left a[w]
L3716:	shift right a[w]
	c - 1 -> c[s]
	if n/c go to L3716
	decimal
	m1 exchange c
	a + b -> a[w]
	shift left a[w]
	a - 1 -> a[s]
	if n/c go to L3705
	c -> a[s]
	a - 1 -> a[s]
	a + c -> a[s]
	if n/c go to L3763
L3733:	a exchange b[w]
	shift left a[w]
	go to L3421

L3736:	if 0 = s 10
	  then go to L3216
	stack -> a
	a -> b[w]
	if a[xs] # 0
	  then go to L2544
	a + 1 -> a[x]
L3745:	a - 1 -> a[x]
	shift left a[ms]
	if a[m] # 0
	  then go to L3540
	if a[x] # 0
	  then go to L3663
	a exchange c[s]
	c -> a[s]
	c + c -> c[s]
	c + c -> c[s]
	a + c -> c[s]
	if c[s] = 0
	  then go to L3664
	go to l3662

L3763:	if p = 1
	  then go to L3733
	  c + 1 -> c[s]
	p - 1 -> p
	a exchange b[w]
	a exchange b[s]
	shift left a[w]
	go to L3707

lncd4:	p <- 3			; ln(1.0001)
	jsb load33
	jsb load33
	p <- 8
	return

L4000:	p <- 3
	jsb S4325
	b exchange c[w]
	jsb S4144
	register -> c 10
	b exchange c[w]
	if b[m] = 0
	  then go to L4617
	m2 exchange c
	register -> c 13
L4012:	a exchange c[w]
	register -> c 10
	jsb S4022
	if 0 = s 13
	  then go to L4141
	jsb S4110
	register -> c 11
	go to L4012

S4022:	if c[m] = 0
 	 then go to L4617
	select rom go to S2025

L4025:	jsb S4044
	1 -> s 7
	m1 exchange c
	go to L4256

L4031:	a exchange c[w]
	m1 -> c
	a exchange c[w]
	jsb S4022
	select rom go to L0036

L4036:	0 -> s 10
	return

S4040:	a exchange c[w]
S4041:	if 0 = s 13
	  then go to S4044
S4043:	0 - c - 1 -> c[s]
S4044:	select rom go to S2045

L4045:	a exchange c[w]
	m2 -> c
	jsb S4327
	m1 exchange c
L4051:	register -> c 15
	a exchange c[w]
	register -> c 11
	jsb S4327
	a exchange c[w]
	register -> c 13
	if c[w] = 0
	  then go to L4071
	jsb s4022
	a exchange c[w]
	register -> c 12
	jsb s4043
	a exchange c[w]
	register -> c 13
	jsb s4327
	a exchange c[w]
L4071:	register -> c 10
	jsb s4022
	a exchange c[w]
	m1 exchange c
	if 1 = s 8
	  then go to l4025
	jsb S4022
	jsb S4147
	load constant 8
	go to L4143

L4103:	load constant 14
	load constant 1
	load constant 14
	go to L4253

	nop

S4110:	0 -> s 13
	jsb S4155
	stack -> a
	c -> stack
	return

L4115:	if 1 = s 13
	  then go to L4000
	load constant 7
	load constant 10
	load constant 14
	load constant 8
	jsb S4325
	select rom go to L5525

L4125:	jsb S4364
	load constant 7
	load constant 8
	load constant 0
	load constant 6
	jsb S4326
	m2 exchange c
	jsb S4144
	register -> c 13
	stack -> a
	c -> stack
	register -> c 11
L4141:	jsb S4147
	load constant 4
L4143:	select rom go to L1544

S4144:	0 -> c[w]
	c -> data address
	return

S4147:	delayed rom @02
	go to L1372

L4151:	jsb S4364
	load constant 6
	load constant 2
	go to L4330

S4155:	select rom go to S0156

L4156:	register -> c 14
	jsb S4040
	jsb S4365
	y -> a
	m2 -> c
	jsb S4327
	a exchange c[w]
	register -> c 15
	jsb S4040
	jsb S4365
	0 -> c[w]
	p <- 12
	c + 1 -> c[p]
	a exchange c[w]
	register -> c 10
	jsb S4040
	jsb S4365
	delayed rom @00
	go to L0201

L4201:	p <- 4
	load constant 3
	jsb S4326
	jsb S4144
	p <- 12
	c + 1 -> c[p]
	a exchange c[w]
	register -> c 10
	jsb S4043
	b exchange c[w]
	b -> c[w]
	m1 exchange c
	if b[m] = 0
	  then go to L4617
	if b[s] = 0
	  then go to L4617
	m2 exchange c
	register -> c 13
L4223:	c -> a[w]
	jsb S4327
	register -> c 10
	jsb S4022
	register -> c 12
	if 0 = s 13
	  then go to L4233
	register -> c 14
L4233:	jsb S4043
	m1 -> c
	jsb S4022
	0 -> c[s]
	delayed rom @04
	jsb S2113
	if 0 = s 13
	  then go to L4141
	jsb S4110
	register -> c 11
	go to L4223

L4246:	if 1 = s 13
	  then go to L4103
	p <- 3
	load constant 1
	1 -> s 8
L4253:	jsb S4326
	m1 exchange c
	jsb S4144
L4256:	register -> c 11
	c -> a[w]
	jsb S4327
	a exchange c[w]
	register -> c 10
	jsb S4022
	a exchange c[w]
	register -> c 12
	jsb S4043
	if 1 = s 7
	  then go to L4031
	if c[m] = 0
	  then go to L4617
	m1 exchange c
	m2 exchange c
	register -> c 11
	a exchange c[w]
	register -> c 13
	jsb S4327
	a exchange c[w]
	register -> c 10
	jsb S4022
	a exchange c[w]
	register -> c 15
	jsb S4043
	a exchange c[w]
	if 1 = s 8
	  then go to L4045
	m1 -> c
	jsb S4022
	jsb S4110
	go to L4051

L4316:	if 1 = s 13
	  then go to L4201
	load constant 8
	load constant 6
	load constant 14
	jsb S4325
	select rom go to L4725

S4325:	load constant 4
S4326:	select rom go to L0727

S4327:	select rom go to S2330

L4330:	if 1 = s 13
	  then go to L4333
	load constant 12
L4333:	jsb S4326
	m2 exchange c
	jsb S4144
	register -> c 11
	a exchange c[w]
	m2 -> c
	jsb S4041
	jsb S4365
	m2 -> c
	c -> a[w]
	jsb S4327
	a exchange c[w]
	register -> c 12
	jsb S4040
	jsb S4365
	register -> c 13
	y -> a
	jsb S4040
	jsb S4365
	y -> a
	a exchange c[w]
	c -> a[w]
	jsb S4327
	a exchange c[w]
	go to L4156

S4364:	select rom go to S0765

S4365:	jsb S4155
	c -> data
	return

L4370:	a exchange c[w]
	jsb S4147
	load constant 6
	go to L4143

L4374:	1 -> s 6
	load constant 12
	load constant 2
	load constant 9
L4400:	load constant 13
L4401:	if 0 = s 13
	  then go to L4405
	p - 1 -> p
	load constant 5
L4405:	delayed rom @01
	jsb S0714
	if 1 = s 13
	  then go to L5553
	c -> a[w]
L4412:	delayed rom @04
	jsb S2027
	a exchange c[w]
	0 -> a[w]		; compare trg100 in 41C
	0 -> b[w]
	a exchange c[m]
	if c[s] = 0
	  then go to L4427
	1 -> s 7
	if 1 = s 10
	  then go to L4426
	1 -> s 4
L4426:	0 -> c[s]		; maybe trg120
L4427:	b exchange c[w]		; maybe trg130
	if 1 = s 0
	  then go to L5050
	if 0 = s 15
	  then go to L4440
	a exchange c[w]
	c -> a[w]
	shift right c[w]
	a - c -> a[w]
L4440:	jsb S4702		; mabye trg135
	b exchange c[w]
	c - 1 -> c[x]
	if c[xs] # 0
	  then go to L4451
	c - 1 -> c[x]
	if n/c go to L4451
	c + 1 -> c[x]
	shift right a[w]
L4451:	b exchange c[w]		; maybe trg140
L4452:	m1 exchange c		; maybe trg150
	m1 -> c
	c + c -> c[w]
	c + c -> c[w]
	c + c -> c[w]
	shift right c[w]
	b exchange c[w]
	if c[xs] # 0
	  then go to L4501
	jsb S4573
	0 -> c[w]
	b exchange c[w]
	m1 -> c
	c + c -> c[w]
	shift left a[w]
	if 0 = s 0
	  then go to L4475
	shift right a[w]
	shift right c[w]
L4475:	b exchange c[w]		; maybe trg160
L4476:	a - b -> a[w]		; maybe trg170
	if n/c go to L4541
	a + b -> a[w]
L4501:	b exchange c[w]		; mabye trg180
	m1 -> c
	b exchange c[w]
	if 0 = s 0
	  then go to L4775
	if c[x] # 0
	  then go to L4774
	shift left a[w]
	go to L4775		; trg270

L4512:	shift right a[w]
L4513:	c - 1 -> c[x]
	if n/c go to L4512
L4515:	0 -> c[x]
L4516:	if c[s] = 0
	  then go to L4523
	a exchange b[w]
	a - b -> a[w]
	0 - c - 1 -> c[x]
L4523:	0 -> c[ms]
	return

L4525:	load constant 2
	load constant 10
	load constant 6
	go to L4400

L4531:	c + 1 -> c[xs]
	a exchange c[s]
	if a[w] # 0
	  then go to L5541
L4535:	a exchange b[w]
	stack -> a
	b exchange c[w]
	select rom go to L5141

L4541:	if 0 = s 10
	  then go to L4761
	0 -> s 10
L4544:	if 1 = s 4
	  then go to L4567
	1 -> s 4
	go to L4476

L4550:	m2 -> c
	jsb S4731
	stack -> a
	c -> stack
	m1 -> c
	select rom go to L5556

L4556:	a exchange c[w]
	shift left a[x]
	a exchange c[w]
	shift left a[w]
	if 0 = s 8
	  then go to L4665
	if c[xs] # 0
	  then go to L4606
	go to L4665

L4567:	0 -> s 4
	go to L4476

L4571:	c + 1 -> c[x]
	shift right a[w]
S4573:	if c[xs] = 0
	  then go to L4717
	if a[s] # 0
	  then go to L4571
	0 - c -> c[x]
	if c[xs] = 0
	  then go to L4513
	0 -> c[m]
	0 -> a[w]
	c + c -> c[x]
	if n/c go to L4515
L4606:	0 -> c[wp]
	if c[s] # 0
	  then go to L4615
	c - 1 -> c[w]
	0 -> c[xs]
	if 1 = s 4
	  then go to L4616
L4615:	0 -> c[s]
L4616:	select rom go to L0617

L4617:	m1 exchange c
	binary
	0 -> c[w]
	c - 1 -> c[w]
	c -> data address
	c -> a[w]
	if 0 = s 11
	  then go to L4640
	p <- 6
	0 -> c[wp]
	load constant 8
	load constant 4
	load constant 1
	p <- 1
	load constant 13
	delayed rom @03
	jsb S1506
L4640:	p <- 11
L4641:	p - 1 -> p
	register -> c 15
	if p # 12
	  then go to L4641
	a exchange c[w]
	p <- 12
	load constant 14
	load constant 10
	load constant 10
	load constant 12
	load constant 10
	0 -> b[w]
	a exchange c[w]
	1 -> s 11
	select rom go to L1660

L4660:	0 -> c[w]
	0 -> a[w]
	a + 1 -> a[p]
L4663:	select rom go to L2264

L4664:	c + 1 -> c[x]
L4665:	a - b -> a[w]
	if n/c go to L4664
	a + b -> a[w]
	c - 1 -> c[m]
	if n/c go to L4556
	go to L4516

L4673:	1 -> s 7
	go to L4476

L4675:	load constant 0
	load constant 4
	load constant 3
	p <- 11
	return

S4702:	0 -> c[w]		; load 180/4
	p <- 12
	load constant 4
L4705:	load constant 5
	select rom go to L5707

L4707:	load constant 3
	load constant 0
	load constant 3
	load constant 12
	jsb S4715
	go to L4401

S4715:	1 -> s 6
	select rom go to S5317

L4717:	a exchange c[w]
	shift left a[wp]
	shift left a[wp]
	shift left a[wp]
	a exchange c[w]
	go to l4665

L4725:	1 -> s 13
	jsb S4715
	stack -> a
	go to L4412

S4731:	select rom go to L2332

L4732:	shift right a[wp]
	shift right a[wp]
L4734:	a - 1 -> a[s]
	if n/c go to L4732
	0 -> a[s]
	m1 exchange c
	a exchange c[w]
	a - c -> c[w]
	a + b -> a[w]
	m1 exchange c
L4744:	a -> b[w]
	c -> a[s]
	c - 1 -> c[p]
	if n/c go to L4734
	a exchange c[w]
	shift left a[m]
	a exchange c[w]
	if c[m] = 0
	  then go to L5020
	c - 1 -> c[s]
	0 -> a[s]
	shift right a[w]
	go to L4744

L4761:	1 -> s 10
	if 0 = s 6
	  then go to L4544
	if 0 = s 7
	  then go to L4673
	0 -> s 7
	go to L4476

L4770:	if 0 = s 13
	  then go to L4660
	0 -> c[w]
	select rom go to L5374

L4774:	c + 1 -> c[x]		; maybe trg260
L4775:	if c[xs] # 0		; maybe trg270
	  then go to L5003
	a - b -> a[w]
	if n/c go to L5170
	a + b -> a[w]
L5002:	jsb S5074		; maybe trg280
L5003:	0 -> a[s]
	if 1 = s 0
	  then go to L5417
	b exchange c[w]
	m1 -> c
	b exchange c[w]
	jsb S5167
	0 -> a[s]
L5013:	m1 exchange c
	jsb trc10
	jsb S5054
	select rom go to L5417

L5017:	c + 1 -> c[x]
L5020:	c - 1 -> c[s]		; compare trg400 in 41C
	if n/c go to L5017
	0 -> c[s]
	m1 exchange c
	a exchange c[w]
	a - 1 -> a[w]
	m1 -> c
	if 1 = s 10
	  then go to L5033
	0 - c -> c[x]		; compare trg415 in 41C
	a exchange b[w]
L5033:	if b[w] = 0		; compare trg420 in 41C
	  then go to L5426
	jsb S5167
	0 -> a[s]
	if 0 = s 6
	  then go to L4663
	a -> b[w]
	p <- 1
	a + b -> a[p]
	if n/c go to L5335
	shift left a[w]
	go to L5117

	nop

L5050:	jsb trc10
	select rom go to L4452

S5052:	p <- 0
	select rom go to L2054

S5054:	a exchange b[w]
S5055:	jsb S5052
	m1 -> c
	go to S5201

L5060:	a -> b[w]
	if b[w] = 0
	  then go to L5306
	a - 1 -> a[p]
	if a[w] # 0
	  then go to L5623
	a exchange b[w]
	if 0 = s 6
	  then go to L5305
	jsb S5317
	0 -> c[w]
	go to L5306

S5074:	select rom go to S2075

L5075:	b exchange c[w]
	jsb S5167
	select rom go to L5500

S5100:	0 -> b[w]
	b exchange c[x]
	p <- 12
	b -> c[w]
	c + c -> c[x]
	if n/c go to L5252
	b -> c[w]
	jsb S5377
L5110:	a + 1 -> a[p]
	if n/c go to L5114
	p + 1 -> p
	go to L5110

L5114:	jsb S5201
L5115:	0 -> b[w]
S5116:	select rom go to S2117

L5117:	a + 1 -> a[ms]
	if n/c go to L5336
	go to l5331

L5122:	p <- 12			; trg315
	m1 -> c
	if 1 = s 10
	  then go to L5257
	if 0 = s 13
	  then go to L4663
	b exchange c[w]
	m2 -> c
	jsb S5152
	c -> stack
	jsb S5326
L5135:	if 0 = s 4		; compare trg500 in 41C
	  then go to L5140
	0 - c - 1 -> c[s]
L5140:	select rom go to L4141

L5141:	c -> stack
	b exchange c[w]
	jsb S5174
	jsb S5100
	a exchange b[w]
	a exchange c[w]
	select rom go to L4550

S5150:	delayed rom @04
	jsb S2334

S5152:	if 0 = s 7
	  then go to L5155
	0 - c - 1 -> c[s]
L5155:	select rom go to S0156

L5156:	p - 1 -> p
	if p # 0
	  then go to L5253
	b -> c[w]
	go to L5115

S5163:	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	0 - c -> c[x]
S5167:	select rom go to S2170

L5170:	a exchange b[w]		; maybe trg250
	a - b -> a[w]
	jsb S5317
	go to L5002

S5174:	m1 exchange c
	b -> c[w]
	jsb S5052
	m1 -> c
	c + c -> c[x]
S5201:	select rom go to S2202

L5202:	0 -> c[w]
	a -> b[w]
	b exchange c[w]
	shift right a[w]
	a + 1 -> a[p]
	0 - c -> c[wp]
	if n/c go to L5221
	a exchange b[w]
	a exchange c[w]
	jsb S5074
	m1 exchange c
	a exchange c[w]
	jsb S5055
	c - 1 -> c[x]
	jsb S5116
L5221:	b exchange c[w]
	a exchange b[w]
	m2 -> c
	a exchange c[w]
	jsb S5264
	0 -> a[s]
	if c[xs] # 0
	  then go to L5235
	a exchange b[w]
L5232:	jsb S5163
	0 -> a[s]
	jsb S5317
L5235:	p <- 12
	m1 exchange c
	m1 -> c
	0 -> c[ms]
L5241:	c + 1 -> c[x]
	if c[x] = 0
	  then go to L5404
	c + 1 -> c[s]
	p - 1 -> p
	if p # 6
	  then go to L5241
	m1 -> c
	go to L5313

L5252:	b -> c[w]
L5253:	c - 1 -> c[x]
	if n/c go to L5156
	b -> c[w]
	go to L5110

L5257:	if 1 = s 6
	  then go to L5372
	a exchange b[w]
	jsb S5163
	select rom go to L2264

S5264:	delayed rom @04
	go to L2162

trc10:	p <- 12			; load pi/4
	0 -> c[w]
	load constant 7
	load constant 8
	load constant 5
	load constant 3
	load constant 9
	load constant 8
	load constant 1
	load constant 6
	load constant 3
	load constant 3
	load constant 9
	load constant 7
	select rom go to L4705

L5305:	jsb trc10
L5306:	delayed rom @13
	jsb S5660
	0 -> c[w]
L5311:	delayed rom @06
	jsb S3067
L5313:	b exchange c[w]
	jsb trc10
	delayed rom @13
	go to L5722

S5317:	if 1 = s 10
	  then go to L4036
	1 -> s 10
	return

S5323:	if 0 = s 13
	  then go to L4660
	b exchange c[w]
S5326:	a exchange b[w]
	m2 -> c
	select rom go to S4731

L5331:	a + 1 -> a[s]
	shift right a[w]
	a -> b[w]
	c + 1 -> c[x]
L5335:	shift left a[w]
L5336:	a exchange c[ms]
	jsb S5174
	jsb S5100
	if 0 = s 13
	  then go to L5512
	b exchange c[w]
	a exchange b[w]
	m2 -> c
	a exchange c[w]
	jsb S5264
	a exchange c[w]
	m1 exchange c
	a + c -> c[x]
	c -> stack
	m1 -> c
	a exchange c[w]
	jsb S5150
	stack -> a
	c -> stack
	m2 -> c
	a exchange c[x]
	0 -> a[x]
	shift right a[w]
	m1 exchange c
	jsb S5054
	delayed rom @04
	jsb S2334
	go to L5135

L5372:	jsb S5323
	jsb S5152
L5374:	c -> stack
	m2 -> c
	go to L5135

S5377:	shift right a[w]
S5400:	c + 1 -> c[x]
S5401:	if c[x] # 0
	  then go to S5377
	return

L5404:	m1 exchange c
	0 -> c[w]
	c + 1 -> c[s]
	shift right c[w]
	go to L5644

L5411:	p <- 6
	jsb six_fill
	p <- 0
	load constant 9
	p <- 10
	return

L5417:	c - 1 -> c[x]
	m1 exchange c
	m1 -> c
	c + 1 -> c[x]
	if n/c go to L5440
	shift left a[w]
	go to L5442

L5426:	0 -> c[w]
	if 1 = s 6
	  then go to L4770
	c - 1 -> c[w]
	0 -> c[xs]
	0 -> c[s]
L5434:	select rom go to L2435

L5435:	p - 1 -> p		; maybe trg305
	if p = 6
	  then go to L5122
L5440:	c + 1 -> c[x]		; mabye trg310
	if n/c go to L5435
L5442:	0 -> c[w]		; maybe trg330
	b exchange c[w]
L5444:	jsb S5601
	b exchange c[w]
	delayed rom @07
	jsb S3437
	if p # 6
	  then go to L5444
	b exchange c[w]
	m1 exchange c
	shift right a[w]
	shift right a[w]
	0 -> c[w]
	p <- 12
	load constant 1
	m1 exchange c
	p <- 13
	load constant 6
	delayed rom @11
	go to L4744

L5466:	p <- 8
	jsb six_fill
	p <- 4
	load constant 8
	p <- 11
	return

S5474:	select rom go to S2075

S5475:	delayed rom @04
	go to S2170

L5477:	shift right a[wp]	; mabye trg350, but 67/97 has TWO shfit right a[wp] here
L5500:	a - 1 -> a[s]
	if n/c go to L5477
	0 -> a[s]
	0 -> c[x]
	m1 exchange c
	p <- 7
L5506:	b exchange c[w]
	jsb S5601
	b exchange c[w]
	go to L5712

L5512:	b exchange c[w]
	a exchange b[w]
	m1 -> c
	a exchange c[w]
	a - c -> c[x]
	0 -> a[x]
	shift right a[w]
	jsb S5475
	0 -> c[s]
	delayed rom @11
	go to L4663

L5525:	y -> a
	jsb S5663
	if c[m] = 0
	  then go to L4531
	if c[s] = 0
	  then go to L5536
	1 -> s 7
	1 -> s 10
	0 -> c[s]
L5536:	delayed rom @04
	jsb S2160
	0 -> a[s]
L5541:	delayed rom @00
	jsb S0161
	if p # 13
	  then go to L4535
	if c[w] # 0
	  then go to L5553
	stack -> a
	m2 -> c
	c -> stack
	0 -> c[w]
L5553:	0 -> a[w]
	0 -> b[w]
	c -> a[m]
L5556:	if c[s] = 0
	  then go to L5570
	1 -> s 4
	if 0 = s 13
	  then go to L5570
	if 0 = s 10
	  then go to L5570
	0 -> s 10
	1 -> s 7
	0 -> s 4
L5570:	p <- 12
	if c[xs] = 0
	  then go to L5620
	jsb S5661
	if 0 = s 6
	  then go to L5235
	jsb S5400
	delayed rom @12
	go to L5202

S5601:	0 -> c[w]
	c - 1 -> c[w]
	0 -> c[s]
	if p = 12
	  then go to L5673
	if p = 11
	  then go to L5466
	if p = 10
	  then go to L5411
	if p # 9
	  then go to L5665
	p <- 4
	jsb six_fill
	p <- 9
	return

L5620:	if c[x] = 0
	  then go to L5060
	a exchange b[w]
L5623:	if 1 = s 6
	  then go to L4617
	jsb S5661
	delayed rom @12
	go to L5232

L5630:	a exchange c[w]
	m1 exchange c
	c + 1 -> c[p]
	c -> a[s]
	m1 exchange c
L5635:	shift right b[w]
	shift right b[w]
	a - 1 -> a[s]
	if n/c go to L5635
	0 -> a[s]
	a + b -> a[w]
	a exchange c[w]
L5644:	a -> b[w]
	a - c -> a[w]
	if n/c go to L5630
	m1 exchange c
	c + 1 -> c[s]
	m1 exchange c
	a exchange b[w]
	shift left a[w]
	p - 1 -> p
	if p = 6
	  then go to L5075
	go to L5644

S5660:	a exchange c[w]
S5661:	if 0 = s 13
	  then go to L5710
S5663:	delayed rom @04
	go to S2027

L5665:	if p = 8
	  then go to L5774
	p <- 0
L5670:	load constant 7
	p <- 7
	return

L5673:	p <- 10
	load constant 6
	load constant 6
	load constant 8		; compare to atcd1 in 25.asm
	load constant 6
	load constant 5
	load constant 2
	load constant 4
	load constant 9
	load constant 1
	load constant 1
	load constant 6
L5707:	p <- 12
L5710:	return

L5711:	a + b -> a[w]
L5712:	c - 1 -> c[p]
	if n/c go to L5711
	shift right a[w]
	0 -> c[p]
	if c[m] = 0
	  then go to L5311
	p + 1 -> p
	go to L5506

L5722:	c + c -> c[w]
	shift right c[w]
	b exchange c[w]
	if 0 = s 10
	  then go to L5740
	jsb S5401
	b exchange c[w]
	a exchange c[w]
	a - c -> c[w]
	a exchange c[w]
	b exchange c[w]
	0 -> c[w]
	jsb S5474
	0 -> a[s]
L5740:	if 0 = s 7
	  then go to L5744
	jsb S5401
	a + b -> a[w]
L5744:	0 -> c[s]
	if 1 = s 0
	  then go to L5760
	c + 1 -> c[x]
	c + 1 -> c[x]
	jsb S5475
	0 -> a[s]
	if 1 = s 15
	  then go to L5760
	a -> b[w]
	shift right b[w]
	a - b -> a[w]
L5760:	delayed rom @04
	jsb S2150
	if 1 = s 13
	  then go to L5434
	stack -> a
	c -> stack
	0 -> a[s]
	select rom go to L4370

six_fill:
	load constant 6		; fill word to end with sixes
	if p = 0
	  then go to L5670
	go to six_fill

L5774:	p <- 2
	jsb six_fill
	p <- 8
	return

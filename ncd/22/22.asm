; 22 ROM disassembly
; Copyright 2006, 2009 Eric Smith <eric@brouhaha.com>
; $Id$
;
; Verified to match 22 ROM part numbers:	
;     1818-0163 (addresses 0000-3777) ROM/anode driver
;     1818-0164 (addresses 4000-5777) ROM

; s 0 = RCL pending
; s 2 = stack lift enable
; s 3 = END mode (hardware)
; s 4 = shift
; s 5 = battery OK (hardware)
; s 6 = decimal point flag (for digit entry)
; s 13 = STO pending
; s 15 = key pressed (hardware)

; m2 [12] = n flag
; m2 [11] = i flag
; m2 [10] = PMT flag
; m2 [ 9] = PV flag
; m2 [ 8] = FV flag

; reg 0-9 = user registers
; reg 5 = sigma xy
; reg 6 = sigma y
; reg 7 = stat n
; reg 8 = sigma x^2
; reg 9 = sigma x
; reg 10 = n
; reg 11 = i
; reg 12 = PMT
; reg 13 = PV
; reg 14 = FV
; reg 15 = ???

	.arch woodstock

	a + 1 -> a[w]
	a + 1 -> a[w]
	f exchange a[x]
	m1 exchange c
	0 -> c[w]
	c -> data address
	clear data registers
	m2 exchange c
op_clx:	0 -> c[w]		; Clear X function
L0011:	0 -> s 2
L0012:	clear status
	decimal
	display off
	jsb L0046
	if c[m] # 0
	  then go to L0021
	0 -> c[w]
L0021:	0 -> b[w]
	jsb L0154
	f -> a[x]
	if 0 = s 1
	  then go to L0174
	jsb round
L0027:	a - 1 -> a[xs]
	if a[xs] # 0
	  then go to L0034
	c -> a[w]
	go to L0044
	
L0034:	jsb zappo
	a exchange b[x]
	a exchange c[x]
	if c[xs] = 0
	  then go to L0043
	0 - c -> c[x]
	c - 1 -> c[xs]
L0043:	a exchange c[x]
L0044:	jsb L0163
	go to L0211
	
L0046:	if c[xs] = 0
	  then go to L0055
	c - 1 -> c[x]
	c + 1 -> c[xs]
	c - 1 -> c[xs]
	if n/c go to L0056
	c + 1 -> c[x]
L0055:	return

L0056:	p <- 12
	c + c -> c[xs]
	if n/c go to L0063
	0 -> c[w]
	return

L0063:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	return

op_enter:	c -> stack		; ENTER^ function
	go to L0011

	nop
	nop
	nop

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

round4:	if p = 2
	  then go to round2
	p - 1 -> p
rounda:	a - 1 -> a[x]
	if n/c go to round4
	go to round2

L0121:	jsb L0364		; shift key comes here - get next key
	0 -> s 1		;   returns here if it was a digit
	if p # 2
	  then go to L0130
	1 -> s 1
	p <- 0
	a - 1 -> a[p]
L0130:	f exchange a[x]
	go to L0012

zappo:	0 -> a[wp]
	binary
	a - 1 -> a[wp]
	decimal
	return

key_32:	if 0 = s 4		; keycode 32 - CHS/%Sigma
	  then go to op_chs
	delayed rom 07
	go to op_pct_sigma

L0143:	if 0 = s 2
	  then go to L0146
	c -> stack
L0146:	1 -> s 2
L0147:	0 -> c[w]
	p <- 12
	jsb zappo
	0 -> a[s]
	a -> b[w]
L0154:	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	a + 1 -> a[s]
	a + 1 -> a[s]
	a exchange b[w]
	return

L0163:	p <- 4
	shift left a[wp]
	shift left a[wp]
	0 -> b[wp]
	a exchange b[p]
	a + 1 -> a[p]
	a + 1 -> a[p]
	a exchange b[p]
	return

L0174:	a + c -> a[x]
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
L0211:	0 -> s 5		; check for low battery
	if 0 = s 5
	  then go to L0256	;   low, invert decimals in display
L0214:	jsb L0364		; wait for key and dispatch
L0215:	jsb L0143		;   returns here if it was a digit
L0216:	jsb L0376
L0217:	binary
	p <- 1
L0221:	a + 1 -> a[p]
	if n/c go to L0332
	shift left a[wp]
	p + 1 -> p
	if p # 13
	  then go to L0221
L0227:	p - 1 -> p
L0230:	p - 1 -> p
	a exchange c[w]
	c -> a[w]
	c - 1 -> c[wp]
	a exchange c[x]
	decimal
	if a[m] # 0
	  then go to L0312
	0 -> a[ms]
L0241:	a exchange c[ms]
L0242:	jsb L0363
	if p = 2
	  then go to L0242
	if 1 = s 6
	  then go to L0217
	if c[m] # 0
	  then go to L0217
	if a[p] # 0
	  then go to L0254
	go to L0242

L0254:	jsb L0147
	go to L0216

L0256:	p <- 12			; low battery, invert decimals in display
L0257:	b exchange c[p]
	0 - c - 1 -> c[p]
	b exchange c[p]
	p - 1 -> p
	if p = 4
	  then go to L0214
	go to L0257

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
	go to L0027

fix9:	jsb zappo
	a exchange b[x]
	go to fix6

fix5:	shift right b[m]
	go to fix4

L0312:	p <- 13
L0313:	p - 1 -> p
	c + 1 -> c[x]
	if b[p] = 0
	  then go to L0313
	p <- 12
L0320:	c - 1 -> c[x]
	if c[p] # 0
	  then go to L0241
	p - 1 -> p
	shift left a[m]
	go to L0320

L0326:	if 1 = s 6
	  then go to L0227
	shift right b[m]
	go to L0227

L0332:	a - 1 -> a[p]
	if p # 3
	  then go to L0326
	0 -> a[x]
	if 1 = s 6
	  then go to L0230
	decimal
	p <- 1
	a + 1 -> a[p]
	a exchange b[w]
	jsb L0154
	a exchange c[x]
L0346:	c -> a[x]
	jsb L0163
L0350:	jsb L0363
	if 1 = s 6
	  then go to L0350
	c + 1 -> c[x]
	jsb L0046
	if p # 12
	  then go to L0346
	go to L0012

L0360:	1 -> s 2
	go to L0012

op_chs:	0 - c - 1 -> c[s]	; CHS function
L0363:	0 -> s 4
L0364:	c -> a[s]
	display toggle
L0366:	0 -> s 15
	p <- 7
L0370:	p - 1 -> p
	if p # 0
	  then go to L0370
	if 1 = s 15
	  then go to L0366
	hi i'm woodstock
L0376:	if 0 = s 15
	  then go to L0376
	display off
	p <- 0
	0 -> a[p]
	keys -> rom address

add3:	p <- 12
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
	  then go to add1
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	  then go to add1
	go to add6

add1:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] # 0
	  then go to add13
	a + b -> a[w]
	if a[s] # 0
	  then go to L0715
	return

add13:	if a >= b[m]
	  then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
	0 -> b[w]
	go to L0512

op_decimal:
	1 -> s 6		; decimal function
	p <- 2
	return

L0455:	delayed rom 00
	go to L0363

op_multiply:
	a + c -> c[x]		; general multiply subroutine
	0 -> s 10
	jsb L0651
	p <- 3
	jsb L0531
L0464:	p <- 12
	0 -> b[w]
	a -> b[x]
	a + b -> a[wp]
	if n/c go to L0474
	shift right a[wp]
	c + 1 -> c[x]
	a + 1 -> a[p]
L0474:	a exchange c[m]
	c -> a[w]
	0 -> b[w]
	return

	go to key_24_x		; keycode 24 - RCL/s
	go to key_23_x		; keycode 23 - STO/xbar
	go to key_22_x		; keycode 22 - RDN/yhat
	go to key_21		; keycode 21 - x<>y/L.R.

	clear status		; keycode 25 - shift
	1 -> s 4
	delayed rom 00
	go to L0121

L0510:	if a[s] # 0
	  then go to L0711
L0512:	p <- 12
	if a[wp] # 0
	  then go to L0633
	0 -> c[x]
L0516:	return

op_divide:
	p <- 12
	if c[m] = 0
	  then go to L0734
	a - c -> c[x]
	jsb L0651
	b exchange c[wp]
	a exchange c[m]
	jsb L0744
	go to L0464

L0530:	a + b -> a[w]		; $$$ mpy26?
L0531:	c - 1 -> c[p]		; $$$ mpy27?
	if n/c go to L0530
	if p = 12
	  then go to L0510
	p + 1 -> p
	shift right a[w]
	go to L0531

L0540:	a + 1 -> a[p]		; keycode 44 - 9
	a + 1 -> a[p]		; keycode 43 - 8
	.legal
	go to L0637		; keycode 42 - 7

	if 1 = s 4		; keycode 41 - subtract/ln
	  then go to op_ln

	jsb L0576
	0 - c - 1 -> c[s]
L0547:	jsb op_add
	go to L0567

L0551:	a + 1 -> a[p]		; digit entry
	return

op_subtract:
	0 - c - 1 -> c[s]
op_add:	jsb add3
	jsb L0464
	return

L0557:	a + 1 -> a[p]
	a + 1 -> a[p]		; keycode 64 - 3
	a + 1 -> a[p]		; keycode 63 - 2
	.legal
	go to L0551		; keycode 62 - 1

	if 1 = s 4		; keycode 61 - multiply/y^x
	  then go to op_y_to_x

	jsb L0576
	jsb op_multiply
L0567:	if 0 = s 13
	  then go to L0757
	delayed rom 00
	jsb L0046
	c -> data
	m1 -> c
	go to L0757

L0576:	if 0 = s 13
	  then go to L0610
	jsb L0455
	m1 exchange c
	a exchange c[w]
	c -> data address
	data -> c
	a exchange c[w]
	m1 -> c
	return

L0610:	stack -> a
	return

L0612:	delayed rom 00
	jsb L0143
	data -> c
	go to L0757

key_24_x:
	delayed rom 06		; keycode 24 - RCL/s
	go to key_24

	select rom 07 (key_74)	; keycode 74 - Sigma+/Sigma-
	go to op_decimal	; keycode 73 - decimal
	return			; keycode 72 - 0

	if 1 = s 4		; keycode 71 - divide/sqrt
	  then go to op_sqrt

	jsb L0576
	1 -> s 8
	jsb op_divide
	go to L0567

L0631:	a + 1 -> a[s]
	c - 1 -> c[x]
L0633:	if a[p] # 0
	  then go to L0516
	shift left a[wp]
	go to L0631

L0637:	a + 1 -> a[p]
	a + 1 -> a[p]		; keycode 54 - 6
	a + 1 -> a[p]		; keycode 53 - 5
	.legal
	go to L0557		; keycode 52 - 4

	if 1 = s 4		; keycode 51 - addition/e^x
	  then go to op_e_to_x

	jsb L0576
	go to L0547

key_33_x:	delayed rom 07		; keycode 33 - %/Delta%
	go to key_33

L0651:	0 -> b[w]
	a exchange b[m]
L0653:	a - c -> c[s]
	if n/c go to L0656
	0 - c -> c[s]
L0656:	0 -> a[w]
	return

	select rom 04 (key_14_x)	; keycode 14 - PV/INT
	select rom 04 (key_13_x)	; keycode 13 - PMT/ACC
	select rom 04 (key_12_x)	; keycode 12 - i/12div
	select rom 04 (key_11_x)	; keycode 11 - n/12*
	select rom 04 (key_15_x)	; keycode 15 - FV/BAL

key_21:	if 1 = s 4		; keycode 21 - x<>y/L.R.
	  then go to op_lr

	stack -> a		; x<>y
	c -> stack
	a exchange c[w]
	go to L0757

key_23_x:
	delayed rom 06		; keycode 23 - STO/xbar
	go to key_23

L0675:	p <- 1
	0 -> a[wp]
	jsb L0455
	if p = 2
	  then go to L0215
	a exchange c[w]
	c -> data address
	a exchange c[w]
	if 1 = s 0
	  then go to L0612
	c -> data
	go to L0757

L0711:	if 0 = s 8
	  then go to L0715
	if 1 = s 10
	  then go to L0717
L0715:	c + 1 -> c[x]
	shift right a[w]
L0717:	return

	go to key_33_x		; keycode 33 - %/Delta%

	delayed rom 00		; keycode 32 - CHS/%Sigma
	go to key_32

	go to key_31		; keycode 31 - ENTER^/RESET

	delayed rom 03		; keycode 34 - CLx/CLEAR
	go to key_34

key_31:	if 1 = s 4		; keycode 31 - ENTER^/RESET
	  then go to op_reset

	delayed rom 00
	go to op_enter

key_22_x:
	delayed rom 07		; keycode 22 - RDN/yhat
	go to key_22

L0734:	if 1 = s 8
	  then go to L1132
	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	c -> a[w]
	return

L0743:	c + 1 -> c[p]
L0744:	a - b -> a[ms]
	if n/c go to L0743
	a + b -> a[ms]
	shift left a[w]
	p - 1 -> p
	if p # 13
	  then go to L0744
	c -> a[w]
	0 -> a[s]
	b exchange c[x]
	go to L0512

L0757:	select rom 00 (L0360)

L0760:	delayed rom 00
	jsb L0147
	a exchange c[w]
	load constant 14	; E
	load constant 10	; r
	load constant 10	; r
	load constant 12	; o
	load constant 10	; r
	a exchange c[w]
	0 -> b[m]
	clear status
	delayed rom 00
	jsb L0211		; does not return

op_y_to_x:
	m1 exchange c
	stack -> a
	a exchange c[w]
	jsb y_to_x
L1001:	delayed rom 00
	go to L0360

; logarithm
ln:	0 -> s 10
	go to L1007

; y to x
y_to_x:	1 -> s 10
	0 -> s 6
L1007:	0 -> s 8
	0 -> s 9
L1011:	p <- 12
	if c[m] = 0
	  then go to L1125
	if c[s] # 0
	  then go to L1140
L1016:	if c[x] = 0
	  then go to L1176
	c + 1 -> c[x]
	0 -> a[w]
	a - c -> a[m]
	if c[x] = 0
	  then go to L1222
L1025:	shift right a[wp]
	a -> b[s]
	p <- 13
L1030:	p - 1 -> p
	a - 1 -> a[s]
	if n/c go to L1030
	a exchange b[s]
	a -> b[s]
	0 -> c[ms]
	go to L1041

L1037:	shift right a[w]
	c + 1 -> c[p]
L1041:	a exchange b[s]
	a -> b[w]
	binary
	a + c -> a[s]
	m2 exchange c
	a exchange c[s]
	shift left a[w]
L1050:	shift right a[w]
	c - 1 -> c[s]
	if n/c go to L1050
	decimal
	m2 exchange c
	a + b -> a[w]
	shift left a[w]
	a - 1 -> a[s]
	if n/c go to L1037
	c -> a[s]
	a - 1 -> a[s]
	a + c -> a[s]
	if n/c go to L1227
L1065:	a exchange b[w]
	shift left a[w]
	go to L1072

L1070:	c - 1 -> c[s]
	p + 1 -> p
L1072:	b exchange c[w]
	jsb L1326
	shift right a[w]
	b exchange c[w]
	go to L1100

L1077:	a + b -> a[w]
L1100:	c - 1 -> c[p]
	if n/c go to L1077
	if c[s] # 0
	  then go to L1070
	if p = 12
	  then go to L1242
	0 -> c[w]
L1107:	p + 1 -> p
	c - 1 -> c[x]
	if p # 12
	  then go to L1107
L1113:	delayed rom 01
	jsb L0512
	0 -> a[s]
	if 0 = s 9
	  then go to L1121
	c - 1 -> c[s]
L1121:	if 1 = s 10
	  then go to L1632
	delayed rom 01
	go to L0464

L1125:	if 0 = s 10
	  then go to L1132
	m1 exchange c
	if c[m] # 0
	  then go to L1134
L1132:	delayed rom 06
	go to L3344

L1134:	if c[s] # 0
	  then go to L1132
	0 -> c[w]
	return

L1140:	0 -> c[s]
	if 0 = s 10
	  then go to L1132
	m1 exchange c
	a exchange c[w]
	a -> b[w]
	if a[xs] # 0
	  then go to L1132
	a + 1 -> a[x]
L1151:	a - 1 -> a[x]
	shift left a[ms]
	if a[m] # 0
	  then go to L1173
	if a[x] # 0
	  then go to L1167
	a exchange c[s]
	c -> a[s]
	c + c -> c[s]
	c + c -> c[s]
	a + c -> c[s]
	if c[s] = 0
	  then go to L1170
	1 -> s 6
L1167:	0 -> c[s]
L1170:	b exchange c[w]
	m1 exchange c
	go to L1016

L1173:	if a[x] # 0
	  then go to L1151
	go to L1132

L1176:	c -> a[w]
	a - 1 -> a[p]
	if a[m] # 0
	  then go to L1205
	0 -> c[w]
	0 -> a[w]
	go to L1121

L1205:	delayed rom 01
	jsb L0512
	0 -> b[w]
	b exchange c[m]
	0 -> c[w]
	a exchange c[s]
	delayed rom 01
	jsb L0744
	binary
	a + c -> a[s]
	a - 1 -> a[s]
	0 -> c[w]
	go to L1025

L1222:	1 -> s 9
	delayed rom 01
	jsb L0512
	0 -> c[x]
	go to L1025

L1227:	if p = 1
	  then go to L1065
	c + 1 -> c[s]
	a exchange b[w]
	a -> b[s]
	shift left a[w]
	c -> a[s]
	binary
	a + b -> a[s]
	p - 1 -> p
	go to L1041

L1242:	if c[x] = 0		; compare L4273 in 67/97
	  then go to L1113
	c - 1 -> c[w]
	b exchange c[w]
	0 -> b[m]
	jsb lnc10
	a exchange c[w]
	a - c -> c[w]
	if b[xs] = 0
	  then go to L1255
	a - c -> c[w]
L1255:	a exchange c[w]
	b exchange c[w]
	if c[xs] = 0
	  then go to L1262
	0 - c - 1 -> c[w]
L1262:	a exchange c[wp]
L1263:	p - 1 -> p
	shift left a[w]
	if p # 1
	  then go to L1263
	p <- 12
	if a[p] # 0
	  then go to L1302
	shift left a[m]
L1273:	a exchange c[w]
	a exchange c[s]
	delayed rom 01
	jsb L0531
	0 -> a[s]
	0 -> c[m]
	go to L1121

L1302:	a + 1 -> a[x]
	p - 1 -> p
	go to L1273

lnc10:	0 -> c[w]
	p <- 12			; lnc10 in -41
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
	p <- 12
	return

L1326:	0 -> c[w]
	if p = 12
	  then go to L1362
	c - 1 -> c[w]
	load constant 4
	c + 1 -> c[w]
	0 -> c[s]
	shift right c[w]
	p + 1 -> p
	if p = 11
	  then go to L1400
	if p = 10
	  then go to L1415
	if p = 9
	  then go to L1430
	if p = 8
	  then go to L1441
	if p = 7
	  then go to L1450
	return

op_ln:	jsb ln
	go to L1001

op_sqrt:
	a exchange c[w]
	delayed rom 07
	go to L3564

	nop
	nop
	nop

L1362:	p <- 11
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
	p <- 12
	return

L1400:	p <- 9
	load constant 3
	load constant 1
	load constant 0
	load constant 1
	load constant 7
	load constant 9
	load constant 8
	load constant 0
	load constant 4
	load constant 3
	p <- 11
	return

L1415:	p <- 7
	load constant 3
	load constant 3
	load constant 0
	load constant 8
	load constant 5
	load constant 3
	load constant 1
	load constant 7
	p <- 10
	return

L1430:	p <- 5
	load constant 3
	load constant 3
	load constant 3
	load constant 0
	load constant 8
	load constant 4
	p <- 9
	return

L1441:	p <- 3
	load constant 3
	load constant 3
	load constant 3
	load constant 3
	p <- 8
	return

L1450:	p <- 1
	load constant 3
	load constant 3
	p <- 7
	return

e_to_x:	0 -> a[w]		; e^x
	a exchange c[m]
L1457:	b exchange c[w]
	delayed rom 02
	jsb lnc10
	b exchange c[w]
	go to L1466

L1464:	c + 1 -> c[x]		;	 compare L3573 in 67/97
	shift right a[w]
L1466:	if c[xs] = 0
	  then go to L1527
	if a[s] # 0
	  then go to L1464
	0 - c -> c[x]
	if c[xs] = 0
	  then go to L1514
	0 -> c[m]
	0 -> a[w]
	c + c -> c[x]
	if n/c go to L1516
L1501:	0 -> c[wp]
	if c[s] # 0
	  then go to L1510
	c - 1 -> c[w]
	0 -> c[xs]
	if 1 = s 6
	  then go to L1511
L1510:	0 -> c[s]
L1511:	c -> a[w]
	return

L1513:	shift right a[w]		; compare L3623 in 67/97
L1514:	c - 1 -> c[x]
	if n/c go to L1513
L1516:	0 -> c[x]
	go to L1543

L1520:	a exchange c[w]
	shift left a[x]
	a exchange c[w]
	shift left a[w]
	if c[xs] # 0
	  then go to L1501
	go to L1536

L1527:	a exchange c[w]
	shift left a[wp]
	shift left a[wp]
	shift left a[wp]
	a exchange c[w]
	go to L1536

L1535:	c + 1 -> c[x]
L1536:	a - b -> a[w]
	if n/c go to L1535
	a + b -> a[w]
	c - 1 -> c[m]
	if n/c go to L1520
L1543:	if c[s] = 0
	  then go to L1550
	a exchange b[w]
	a - b -> a[w]
	0 - c - 1 -> c[x]
L1550:	0 -> c[ms]
	b exchange c[w]
	p <- 12
L1553:	delayed rom 02
	jsb L1326
	b exchange c[w]
	go to L1560

L1557:	c + 1 -> c[s]
L1560:	a - b -> a[w]
	if n/c go to L1557
	a + b -> a[w]
	shift left a[w]
	shift right c[ms]
	b exchange c[w]
	p - 1 -> p
	if p # 5
	  then go to L1553
	p <- 13
	load constant 7
	a exchange c[s]
	b exchange c[w]
	go to L1601

L1576:	a -> b[w]
	c - 1 -> c[s]
	if n/c go to L1621
L1601:	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	a - 1 -> a[s]
	if n/c go to L1576
	a exchange b[w]
	a + 1 -> a[p]
	if 0 = s 6
	  then go to L1614
	c - 1 -> c[s]
L1614:	delayed rom 01
	jsb L0512
	delayed rom 01
	go to L0464

L1620:	shift right a[wp]
L1621:	a - 1 -> a[s]
	if n/c go to L1620
	0 -> a[s]
	a + b -> a[w]
	a + 1 -> a[p]
	if n/c go to L1576
	shift right a[wp]
	a + 1 -> a[p]
	if n/c go to L1601
L1632:	a exchange b[w]
	a exchange c[w]
	m1 exchange c
	a + c -> c[x]
	delayed rom 01
	jsb L0653
	p <- 3
	1 -> s 8
	delayed rom 01
	jsb L0531
	0 -> s 8
	0 -> c[m]
	go to L1457

op_e_to_x:
	jsb e_to_x
	delayed rom 00
	go to L0360

	nop

op_reset:
	m1 exchange c		; RESET function
	jsb L1767
	m1 -> c
L1656:	delayed rom 00
	go to L0012

L1660:	1 -> s 10
	0 -> s 8
	0 -> s 6
	0 -> s 9
	p <- 12
	display toggle
	if c[xs] = 0
	  then go to L1734
	c -> a[w]
	0 -> b[w]
	a -> b[m]
	0 -> a[s]
L1674:	a + 1 -> a[x]
	if n/c go to L1710
	if c[s] # 0
	  then go to L1744
	p <- 12
	shift right b[w]
	a exchange b[w]
	a + 1 -> a[p]
	a exchange b[w]
	a exchange c[s]
	0 -> c[wp]
	go to L1720

L1710:	shift right b[w]
	a + 1 -> a[s]
	if n/c go to L1674
	0 -> a[w]
	a exchange c[m]
	delayed rom 02
	go to L1113

L1717:	c + 1 -> c[p]
L1720:	a - b -> a[w]
	if n/c go to L1717
	a + b -> a[w]
	shift left a[w]
	p - 1 -> p
	if p # 0
	  then go to L1720
	0 -> a[w]
	a exchange c[w]
	p <- 12
	delayed rom 02
	go to L1025

L1734:	0 -> a[w]
	a + 1 -> a[p]
	delayed rom 01
	jsb add3
	delayed rom 01
	jsb L0464
	delayed rom 02
	go to L1011

L1744:	p <- 12
	delayed rom 02
	go to L1222

op_lr:	1 -> s 14		; linear regression
	delayed rom 07
	go to L3576

key_34:	if 0 = s 4		; keycode 34 - CLx/CLEAR
	  then go to op_clx

	0 -> c[w]		; CLEAR function
	c -> stack
	c -> stack
	c -> stack
	jsb L1767
	c -> register 0
	c -> register 1
	c -> register 2
	c -> register 3
	c -> register 4
	go to L1656

L1767:	0 -> c[w]		; common part of RESET and CLEAR functions
	m2 exchange c
	0 -> c[w]
	c -> register 5
	c -> register 6
	c -> register 7
	c -> register 8
	c -> register 9
	return

con12:	a exchange c[w]		; load constant 12
	0 -> c[w]
	p <- 12
	c + 1 -> c[p]
	c + 1 -> c[p]
	shift right c[w]
	c + 1 -> c[p]
	c + 1 -> c[x]
	return

L2011:	delayed rom 00
	go to L0046

L2013:	delayed rom 00
	go to L0143

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

; keycode 11 - n/12*
key_11:	if 0 = s 0		; RCL pending?
	  then go to op_n

; recall n
	jsb L2013
	register -> c 10
L2031:	delayed rom 00
	go to L0360

; store or compute n
op_n:	m2 exchange c		; check n flag
	p <- 12
	if c[p] = 0
	  then go to L2051	; clear, so compute

store_n:
	m2 exchange c
	if 0 = s 4		; shifted?
	  then go to L2046

	jsb con12		; yes, multiply by 12
	delayed rom 01
	jsb op_multiply		; multiply
	jsb L2011

L2046:	c -> register 10
L2047:	delayed rom 00
	go to L0011

L2051:	jsb L2344
	if c[xs] # 0
	  then go to L2060
	c + 1 -> c[p]
	p <- 12
	c + 1 -> c[p]
	if n/c go to store_n

; compute n
L2060:	jsb L2362
	p <- 9
	jsb L2373
	if c[xs] = 0
	  then go to L2520
	p <- 8
	jsb L2373
	if c[xs] = 0
	  then go to L2437
	delayed rom 05
	go to L2414

; keycode 12 - i/12div
key_12:	if 0 = s 0		; RCL pending?
	  then go to op_i

; recall i
	jsb L2013
	register -> c 11
	go to L2031

; store or compute i
op_i:	m2 exchange c		; i function
	p <- 11
	if c[p] = 0
	  then go to L2115

L2104:	m2 exchange c
	if 0 = s 4		; shifted?
	  then go to sto_i

	jsb con12		; yes, divide by 12
	delayed rom 01
	jsb op_divide
	jsb L2011

sto_i:	c -> register 11
	go to L2047

L2115:	jsb L2344
	if c[xs] # 0
	  then go to L2124
	c + 1 -> c[p]
	p <- 11
	c + 1 -> c[p]
	if n/c go to L2104

; compute i
L2124:	jsb L2366
	p <- 9
	jsb L2373
	if c[xs] = 0
	  then go to L2611
	p <- 8
	jsb L2373
	if c[xs] = 0
	  then go to L2557
	delayed rom 05
	go to L2533

; PMT function
op_pmt:	if 0 = s 0		; RCL pending?
	  then go to L2144

; recall PMT
	jsb L2013
	register -> c 12
	go to L2031

; store or compute PMT
L2144:	m2 exchange c
	p <- 10
	if c[p] = 0
	  then go to L2153

store_pmt:
	m2 exchange c
	c -> register 12
	go to L2047

L2153:	jsb L2344
	if c[xs] # 0
	  then go to L2162
	c + 1 -> c[p]
	p <- 10
	c + 1 -> c[p]
	if n/c go to store_pmt

; compute PMT
L2162:	jsb L2362
	jsb L2366
	p <- 9
	jsb L2373
	if c[xs] = 0
	  then go to L3133
	delayed rom 06
	go to L3151

; PV function
op_pv:	if 0 = s 0		; RCL pending?
	  then go to L2177

; recall PV
	jsb L2013
	register -> c 13
	go to L2031

; store or compute PV
L2177:	m2 exchange c
	1 -> s 12
	p <- 9
	if c[p] = 0
	  then go to L2207

store_pv:
	m2 exchange c		; store pv
	c -> register 13
	go to L2047

L2207:	jsb L2344
	if c[xs] # 0
	  then go to L2216
	c + 1 -> c[p]
	p <- 9
	c + 1 -> c[p]
	if n/c go to store_pv

; compute PV
L2216:	jsb L2362
	jsb L2366
	p <- 8
	jsb L2373
	if c[xs] = 0
	  then go to L3230
	delayed rom 06
	go to L3176

; FV function
op_fv:	if 0 = s 0		; RCL pending?
	  then go to L2233

; recall FV
	jsb L2013
	register -> c 14
	go to L2031

; store or compute FV
L2233:	m2 exchange c
	p <- 8
	if c[p] = 0
	  then go to L2242

store_fv:
	m2 exchange c
	c -> register 14
	go to L2047

L2242:	jsb L2344
	if c[xs] # 0
	  then go to L2251
	c + 1 -> c[p]
	p <- 8
	c + 1 -> c[p]
	if n/c go to store_fv

L2251:	jsb L2362
	jsb L2366
	p <- 9
	jsb L2373
	if c[xs] = 0
	  then go to L3267
	delayed rom 06
	go to L3221

key_14_x:
	go to key_14		; keycode 14 - PV/INT

key_13_x:
	go to key_13		; keycode 13 - PMT/ACC

key_12_x:
	go to key_12		; keycode 12 - i/12div

key_11_x:
	go to key_11		; keycode 11 - n/12*

key_15_x:
	go to key_15		; keycode 15 - FV/BAL

; keycode 13 - PMT/ACC
key_13:	if 1 = s 4		; shifted?
	  then go to op_acc
	go to op_pmt

; keycode 14 - PV/INT
key_14:	if 1 = s 4
	  then go to op_int
	go to op_pv

; keycode 15 - FV/BAL
key_15:	if 1 = s 4
	  then go to op_bal
	go to op_fv

op_acc:	1 -> s 11		; ACC function
op_bal:	m2 -> c			; BAL function
	jsb L2362
	p - 1 -> p
	if c[p] = 0
	  then go to L2371
	p - 1 -> p
	if c[p] = 0
	  then go to L2371
	p <- 12
	1 -> s 12
	delayed rom 05
	go to L2442

L2314:	c -> register 10
	if 1 = s 11
	  then go to L2321
	delayed rom 07
	go to L3522

L2321:	register -> c 8
	a exchange c[w]
	0 -> c[w]
	c + 1 -> c[p]
	delayed rom 01
	jsb op_subtract
	c -> register 7
	delayed rom 07
	go to L3456

op_int:	m2 -> c			; INT function
	jsb L2366
	jsb L2362
	p <- 9
	if c[p] = 0
	  then go to L2371
	p <- 12
	delayed rom 07
	go to L3415

	nop

L2344:	0 -> c[xs]
	p <- 3
	if c[p] = 0
	  then go to L2361
	c - 1 -> c[p]
	if c[p] = 0
	  then go to L2360
	c - 1 -> c[p]
	if c[p] = 0
	  then go to L2357
	c + 1 -> c[xs]
L2357:	c + 1 -> c[p]
L2360:	c + 1 -> c[p]
L2361:	return

L2362:	p <- 11
L2363:	if c[p] = 0
	  then go to L2370
	return

L2366:	p <- 12
	go to L2363

L2370:	m2 exchange c
L2371:	delayed rom 06
	go to L3344

L2373:	0 -> c[xs]
	if c[p] = 0
	  then go to L2377
	c + 1 -> c[xs]
L2377:	return

x24_add:
	delayed rom 01		; add
	go to op_add

x24_sub:
	delayed rom 01		; subtract
	go to op_subtract

x24_mul:
	delayed rom 01		; multiply
	go to op_multiply

x24_div:
	delayed rom 01		; divide
	go to op_divide

x24_ln:
	delayed rom 02
	go to ln

x24_y_to_x:
	delayed rom 02
	go to y_to_x

L2414:	jsb L2773
	register -> c 11
	if c[wp] = 0
	  then go to L2371
	jsb L2763
	jsb x24_add
	jsb x24_ln
	c -> register 15
	register -> c 14
	a exchange c[w]
	register -> c 13
	if c[wp] = 0
	  then go to L2371
	jsb x24_div
	jsb x24_ln
	if c[wp] = 0
	  then go to L2512
	register -> c 15
	go to L2504

L2437:	jsb L2773
	if 0 = s 3
	  then go to L2444
L2442:	register -> c 12
	go to L2450

L2444:	jsb L2763
	jsb x24_add
	register -> c 12
	jsb x24_mul
L2450:	c -> register 15
	jsb L2763
	jsb x24_add
	jsb x24_ln
	if 1 = s 14
	  then go to L2522
	if c[m] = 0
	  then go to L2514
	0 - c - 1 -> c[s]
	m1 exchange c
	register -> c 13
L2463:	a exchange c[w]
	register -> c 11
	jsb x24_mul
	register -> c 15
	if c[wp] = 0
	  then go to L2371
	c + 1 -> c[x]
	c + 1 -> c[x]
	jsb x24_div
	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	if 1 = s 14
	  then go to L2527
	jsb x24_sub
L2502:	jsb x24_ln
	m1 -> c
L2504:	jsb x24_div
	if 1 = s 12
	  then go to L2314
	delayed rom 00
	jsb L0046
	c -> register 10
L2512:	delayed rom 00
	go to L0360

L2514:	register -> c 13
L2515:	a exchange c[w]
	register -> c 12
	go to L2504

L2520:	1 -> s 14
	go to L2437

L2522:	if c[m] = 0
	  then go to L2531
	m1 exchange c
	register -> c 14
	go to L2463

L2527:	jsb x24_add
	go to L2502

L2531:	register -> c 14
	go to L2515

L2533:	jsb L2773
	register -> c 10
	if c[wp] = 0
	  then go to L2371
	0 -> a[w]
	a + 1 -> a[p]
	jsb x24_div
	m1 exchange c
	register -> c 14
	a exchange c[w]
	register -> c 13
	if c[wp] = 0
	  then go to L2371
	jsb x24_div
	jsb x24_y_to_x
	0 -> c[w]
	c + 1 -> c[p]
	jsb x24_sub
	delayed rom 06
	go to L3125

L2557:	jsb L2772
	register -> c 10
	if 0 = s 3
	  then go to L2566
	c -> register 9
	register -> c 13
	go to L2577

L2566:	a exchange c[w]
	0 -> c[w]
	c + 1 -> c[p]
	jsb x24_sub
	c -> register 9
	register -> c 13
	a exchange c[w]
	register -> c 12
	jsb x24_sub
L2577:	c -> register 15
	jsb L2760
	a exchange c[w]
	register -> c 12
	jsb L2760
	jsb x24_div
	c -> register 15
	register -> c 9
	jsb L2760
	go to L2656

L2611:	jsb L2772
	register -> c 10
	if 0 = s 3
	  then go to L2620
	c -> register 9
	register -> c 14
	go to L2631

L2620:	a exchange c[w]
	0 -> c[w]
	c + 1 -> c[p]
	jsb x24_add
	c -> register 9
	register -> c 14
	a exchange c[w]
	register -> c 12
	jsb x24_add
L2631:	c -> register 15
	register -> c 9
	a exchange c[w]
	register -> c 12
	jsb x24_mul
	register -> c 15
	jsb x24_sub
	if c[w] = 0
	  then go to L2512
	register -> c 15
	jsb L2760
	a exchange c[w]
	register -> c 12
	jsb L2760
	jsb x24_div
	0 - c - 1 -> c[s]
	c -> register 15
	register -> c 9
	jsb L2760
	0 - c - 1 -> c[s]
	c -> register 9
L2656:	0 -> s 0
	p <- 12
	0 -> a[w]
	a + 1 -> a[s]
	a + 1 -> a[p]
	a + 1 -> a[p]
	shift right a[w]
	register -> c 15
	jsb x24_mul
	register -> c 9
	a exchange c[w]
	jsb x24_div
	if c[xs] = 0
	  then go to L2720
	jsb x24_add
	if c[xs] = 0
	  then go to L2725
	0 -> a[w]
	a + 1 -> a[p]
	register -> c 9
	jsb x24_div
	0 - c - 1 -> c[s]
	m1 exchange c
	register -> c 15
	0 -> c[s]
	jsb x24_y_to_x
	0 -> c[w]
	c + 1 -> c[p]
	jsb x24_sub
L2713:	c -> register 11
	if 0 = s 0
	  then go to L3016
	delayed rom 06
	go to L3121

L2720:	0 -> a[w]
	a + 1 -> a[p]
	register -> c 15
	jsb x24_div
	go to L2713

L2725:	register -> c 9
	a exchange c[w]
	register -> c 15
	jsb x24_sub
	jsb x24_add
	c -> register 11
	register -> c 9
	jsb x24_div
	c + 1 -> c[x]
	c + 1 -> c[x]
	c + 1 -> c[x]
	if c[xs] = 0
	  then go to L2743
	1 -> s 0
L2743:	0 -> a[w]
	a + 1 -> a[p]
	register -> c 9
	jsb x24_add
	register -> c 9
	jsb x24_mul
	register -> c 11
	a exchange c[w]
	jsb x24_div
	go to L2713

	nop
	nop
	nop

L2760:	if c[wp] = 0
	  then go to L2371
	return

L2763:	register -> c 11
	c - 1 -> c[x]
	c - 1 -> c[x]
	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	return

L2772:	1 -> s 7
L2773:	m2 exchange c
	display toggle
	p <- 12
	0 -> s 3
	return

x30_add:
	delayed rom 01		; add
	go to op_add

x30_sub:
	delayed rom 01		; subtract
	go to op_subtract

x30_mul:
	delayed rom 01		; multiply
	go to op_multiply

x30_div:
	delayed rom 01		; divide
	go to op_divide

L3010:	delayed rom 03
	go to L1660

L3012:	delayed rom 05
	go to L2763

L3014:	delayed rom 00
	go to L0046

L3016:	register -> c 9
	0 - c - 1 -> c[s]
	m1 exchange c
	register -> c 11
	if c[w] = 0
	  then go to L3121
	jsb L3010
	c -> register 8
	0 -> a[w]
	a + 1 -> a[p]
	register -> c 11
	jsb x30_add
	m1 exchange c
	register -> c 9
	a exchange c[w]
	register -> c 8
	jsb x30_mul
	register -> c 11
	jsb x30_mul
	m1 -> c
	jsb x30_div
	m1 exchange c
	0 -> a[w]
	a + 1 -> a[p]
	register -> c 8
	jsb x30_sub
	c -> register 8
	m1 -> c
	jsb x30_sub
	m1 exchange c
	register -> c 15
	a exchange c[w]
	register -> c 11
	jsb x30_mul
	register -> c 8
	jsb x30_sub
	m1 -> c
	jsb x30_div
	c -> register 8
	0 -> a[w]
	a + 1 -> a[p]
	jsb x30_sub
	register -> c 11
	jsb x30_mul
	c -> register 11
	register -> c 8
	jsb x30_mul
	0 -> a[w]
	jsb L3103
	register -> c 8
	0 -> a[w]
	jsb L3105
	go to L3016

L3103:	a + 1 -> a[x]
	a + 1 -> a[x]
L3105:	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	if c[m] = 0
	  then go to L3121
	if c[xs] = 0
	  then go to L3120
	a + c -> a[x]
	if n/c go to L3121
L3120:	return

L3121:	0 -> c[w]
	c -> register 9
	c -> register 8
	register -> c 11
L3125:	c + 1 -> c[x]
	c + 1 -> c[x]
	jsb L3014
	c -> register 11
L3131:	delayed rom 00
	go to L0360

L3133:	jsb L3373
	register -> c 11
	if c[w] = 0
	  then go to L3167
	if 0 = s 3
	  then go to L3143
	register -> c 14
	go to L3150

L3143:	jsb L3012
	jsb x30_add
	register -> c 14
	a exchange c[w]
	jsb x30_div
L3150:	go to L3303

L3151:	jsb L3373
	register -> c 11
	if c[w] = 0
	  then go to L3171
	if 0 = s 3
	  then go to L3161
	register -> c 13
	go to L3166

L3161:	jsb L3012
	jsb x30_add
	register -> c 13
	a exchange c[w]
	jsb x30_div
L3166:	go to L3244

L3167:	register -> c 14
	go to L3172

L3171:	register -> c 13
L3172:	a exchange c[w]
	register -> c 10
	jsb x30_div
	go to L3206

L3176:	jsb L3374
	register -> c 10
	0 - c - 1 -> c[s]
	m1 exchange c
	jsb L3012
	jsb L3010
	register -> c 14
L3205:	jsb x30_mul
L3206:	jsb L3014
	if 1 = s 14
	  then go to L3217
	if 1 = s 12
	  then go to L3215
	c -> register 14
	go to L3131

L3215:	c -> register 13
	go to L3131

L3217:	c -> register 12
	go to L3131

L3221:	jsb L3374
	register -> c 10
	m1 exchange c
	jsb L3012
	jsb L3010
	register -> c 13
	go to L3205

L3230:	jsb L3374
L3231:	register -> c 11
	if c[m] = 0
	  then go to L3317
	if 0 = s 3
	  then go to L3240
	register -> c 12
	go to L3244

L3240:	jsb L3012
	jsb x30_add
	register -> c 12
	jsb x30_mul
L3244:	c -> register 15
	register -> c 10
	0 - c - 1 -> c[s]
	m1 exchange c
	jsb L3012
	jsb L3010
	0 -> a[w]
	a + 1 -> a[p]
	jsb x30_sub
	m1 exchange c
	jsb L3012
	a exchange c[w]
L3260:	m1 -> c
	if 1 = s 14
	  then go to L3264
	a exchange c[w]
L3264:	jsb x30_div
	register -> c 15
	go to L3205

L3267:	jsb L3374
	register -> c 11
	if c[m] = 0
	  then go to L3317
	if 0 = s 3
	  then go to L3277
	register -> c 12
	go to L3303

L3277:	jsb L3012
	jsb x30_add
	register -> c 12
	jsb x30_mul
L3303:	c -> register 15
	register -> c 10
	m1 exchange c
	jsb L3012
	jsb L3010
	0 -> c[w]
	c + 1 -> c[p]
	jsb x30_sub
	m1 exchange c
	jsb L3012
	a exchange c[w]
	go to L3260

L3317:	register -> c 10
	a exchange c[w]
	register -> c 12
	go to L3205

key_23:	if 1 = s 4		; keycode 23 - STO/xbar
	  then go to L3336
	1 -> s 13		; STO function
	0 -> s 0
L3327:	delayed rom 01
	go to L0675

key_24:	if 1 = s 4		; keycode 24 - RCL/s
	  then go to op_s

	1 -> s 0		; RCL function
	0 -> s 13
	go to L3327

L3336:	1 -> s 8		; xbar function
	register -> c 9
	a exchange c[w]
	register -> c 7
	jsb x30_div
	go to L3131

L3344:	0 -> c[w]
	display off
	if 1 = s 7
	  then go to L3354
	if 0 = s 11
	  then go to L3361
	c -> register 7
	go to L3357

L3354:	c -> register 8
	c -> register 9
	c -> register 11
L3357:	delayed rom 01
	go to L0760

L3361:	if 0 = s 12
	  then go to L3357
	if 0 = s 8
	  then go to L3357
	m2 exchange c
	go to L3357

	nop
	nop
	nop
	nop

L3373:	1 -> s 14
L3374:	m2 exchange c
	p <- 12
	0 -> s 3
	return

x34_add:
	delayed rom 01		; add
	go to op_add

x34_rev_sub:
	a exchange c[w]		; reverse subtract
x34_sub:
	delayed rom 01		; subtract
	go to op_subtract

x34_mul:
	delayed rom 01		; multiply
	go to op_multiply

x34_div:
	delayed rom 01		; divide
	go to op_divide

L3411:	delayed rom 05
	go to L2763

L3413:	delayed rom 03
	go to L1660

L3415:	register -> c 10
	a exchange c[w]
	0 -> c[w]
	load constant 3
	load constant 6
	c + 1 -> c[x]
	c + 1 -> c[x]
	p <- 12
	jsb x34_div
	register -> c 13
	jsb x34_mul
	register -> c 11
	c - 1 -> c[x]
	c - 1 -> c[x]
	jsb x34_mul
	c -> register 15
	0 -> c[w]
	0 -> a[w]
	load constant 3
	load constant 6
	c + 1 -> c[x]
	c + 1 -> c[x]
	c -> a[w]
	load constant 5
	p <- 12
	jsb x34_div
	register -> c 15
	jsb x34_mul
	c -> stack
	register -> c 13
	c -> stack
	register -> c 15
	go to L3716

L3456:	register -> c 7
	a exchange c[w]
	register -> c 9
	jsb x34_sub
	m1 exchange c
	jsb L3411
	jsb L3413
	0 -> a[w]
	a + 1 -> a[p]
	jsb x34_sub
	c -> register 15
	register -> c 9
	a exchange c[w]
	register -> c 10
	jsb x34_sub
	m1 exchange c
	jsb L3411
	jsb L3413
	a + 1 -> a[x]
	a + 1 -> a[x]
	register -> c 11
	jsb x34_div
	register -> c 15
	jsb x34_mul
	c -> register 15
	register -> c 9
	a exchange c[w]
	register -> c 7
	jsb x34_sub
	register -> c 15
	jsb x34_sub
	0 -> c[w]
	c -> register 7
L3517:	register -> c 12
	jsb x34_mul
	go to L3716

L3522:	register -> c 9
	a exchange c[w]
	register -> c 10
	jsb x34_sub
	m1 exchange c
	jsb L3411
	jsb L3413
	0 -> a[w]
	a + 1 -> a[p]
	jsb x34_sub
	a + 1 -> a[x]
	a + 1 -> a[x]
	register -> c 11
	jsb x34_div
	go to L3517

op_s:	1 -> s 8		; s function
	register -> c 9
	c -> a[w]
	jsb x34_mul
	register -> c 7
	jsb x34_div
	register -> c 8
	jsb x34_rev_sub
	m1 exchange c
	if 1 = s 12
	  then go to L3601
	0 -> a[w]
	a + 1 -> a[p]
	register -> c 7
	jsb x34_rev_sub
	m1 -> c
	a exchange c[w]
	jsb x34_div
	0 - c - 1 -> c[s]
L3564:	0 -> c[w]
	p <- 12
	load constant 5
	c - 1 -> c[x]
	p <- 12
	m1 exchange c
	a exchange c[w]
	delayed rom 02
	jsb y_to_x
	go to L3716

L3576:	m2 exchange c		; yhat function
	1 -> s 12
	go to op_s

L3601:	register -> c 9
	a exchange c[w]
	register -> c 6
	jsb x34_mul
	register -> c 7
	jsb x34_div
	register -> c 5
	jsb x34_rev_sub
	m1 -> c
	jsb x34_div
	if 1 = s 14
	  then go to L3741
	go to L3737

	nop
	nop
	nop

key_74:	c -> a[w]		; keycode 74 - Sigma+/Sigma-
	m1 exchange c
	register -> c 9		; get sigma x
	if 0 = s 4
	  then go to L3630
	jsb x34_rev_sub
	go to L3631

L3630:	jsb x34_add
L3631:	jsb L3776
	c -> register 9		; store updated sigma x

	m1 -> c			; compute x^2
	c -> a[w]
	jsb x34_mul

	register -> c 8		; get sigma x^2
	if 0 = s 4
	  then go to L3643
	jsb x34_rev_sub
	go to L3644

L3643:	jsb x34_add
L3644:	jsb L3776
	c -> register 8		; store updated sigma x^2

	y -> a			; compute xy
	m1 -> c
	jsb x34_mul

	register -> c 5		; get sigma xy
	if 0 = s 4
	  then go to L3656
	jsb x34_rev_sub
	go to L3657

L3656:	jsb x34_add
L3657:	jsb L3776
	c -> register 5		; store updated sigma xy

	y -> a			; get y

	register -> c 6		; get sigma y
	if 0 = s 4
	  then go to L3667
	jsb x34_rev_sub
	go to L3670

L3667:	jsb x34_add
L3670:	jsb L3776
	c -> register 6		; store updated sigma y

	0 -> a[w]
	a + 1 -> a[p]
	register -> c 7		; get stat n
	if 0 = s 4
	  then go to L3701
	jsb x34_rev_sub
	go to L3702

L3701:	jsb x34_add
L3702:	jsb L3776
	c -> register 7		; store updated stat n

	delayed rom 00
	go to L0011

key_33:	stack -> a		; keycode 33 - %/Delta%
	a exchange c[w]
	c -> stack
	if 1 = s 4
	  then go to L3720
	jsb x34_mul		; % function
	c - 1 -> c[x]
	c - 1 -> c[x]
L3716:	delayed rom 00
	go to L0360

L3720:	1 -> s 8		; Delta% function
	jsb x34_sub
	down rotate
	c -> stack
L3724:	c - 1 -> c[x]
	c - 1 -> c[x]
	jsb x34_div
	go to L3716

key_22:	if 1 = s 4		; keycode 22 - RDN/yhat
	  then go to L3576
	down rotate		; RDN function
	go to L3716

op_pct_sigma:
	c -> a[w]		; %Sigma function
	register -> c 9
	go to L3724

L3737:	m2 -> c
	jsb x34_mul
L3741:	m2 exchange c
	register -> c 9
	a exchange c[w]
	register -> c 5
	jsb x34_mul
	register -> c 7
	jsb x34_div
	c -> register 15
	register -> c 6
	a exchange c[w]
	register -> c 8
	jsb x34_mul
	register -> c 7
	jsb x34_div
	register -> c 15
	jsb x34_sub
	m1 -> c
	jsb x34_div
	m2 -> c
	if 1 = s 14
	  then go to L3773
	jsb x34_add
L3767:	0 -> c[w]
	m2 exchange c
	a exchange c[w]
	go to L3716

L3773:	jsb L3776
	c -> stack
	go to L3767

L3776:	delayed rom 00
	go to L0046

; 27 ROM disassembly
; Copyright 2006, 2008 Eric Smith <eric@brouhaha.com>
; $Id$
;
; Verified to match 27 ROM part numbers:	
;     5061-0430-2 (addresses 0000-3777) ROM/anode driver
;     5061-0459   (addresses 4000-5777) ROM/RAM

; s 1 = stack lift disable?
; s 3 = radian angle mode (hardware switch)
; s 5 = power
; s 10 = RCL prefix (s11 also set)
; s 11 = STO/RCL prefix
; s 13 = f prefix (s 14 set also)
; s 14 = prefix (f or g)

; m2:
;	digit 12: trig mode
;	digits ?-?: TVM flags
;	digit 0: ?

; reg 0-9 = user reg
; reg 4 = stat
; reg 5 = stat
; reg 6 = stat
; reg 15 = LASTx

	.arch woodstock

	display off
	1 -> s 2
	a + 1 -> a[w]
	a + 1 -> a[w]
	f exchange a[x]
	c -> data address
	clear data registers
	m2 exchange c
	0 -> c[w]
	go to L0251

L0012:	jsb L0171		; decimal/lastx/pi key
	1 -> s 0
	if 1 = s 7
	  then go to L0201
	if 1 = s 9
	  then go to L0201
	0 -> s 11
	0 -> s 12
	go to L0377

L0023:	if 1 = s 10		; f prefix key
	  then go to L0127
	clear status
L0026:	1 -> s 13
	go to L0265

L0030:	if 1 = s 11		; arithmetic keys
	  then go to L0252	;   register arithmetic?
L0032:	stack -> a
L0033:	clear status
	decimal
	c -> register 15
	return
	
L0037:	jsb L0171		; RCL/PV/NPV key
	clear status			; RCL
	1 -> s 10
L0042:	1 -> s 11
L0043:	go to L0201

L0044:	jsb L0171		; x<>y/n/r key
	stack -> a		; x<>y
	c -> stack
	a exchange c[w]
	go to done_x1

L0051:	1 -> s 1
L0052:	clear status
	1 -> s 13
	go to L0376

L0055:	0 - c - 1 -> c[s]
	c -> a[s]
	if 0 = s 9
	  then go to L0655
	go to L0201

L0062:	jsb L0171		; xbar/SCI/s key
	jsb L0032
	select rom @10 (L4065)

L0065:	jsb L0171		; %/ENG/Delta% key
	jsb L0033
	delayed rom 04
	go to L2223

L0071:	a exchange c[x]
	p <- 1
	if c[xs] = 0
	  then go to L0076
	0 - c -> c[wp]
L0076:	a exchange c[x]
	return

	go to L0037		; keycode 24 - RCL/PV/NPV key
	go to L0273		; keycode 23 - STO/PMT/N.D. key
	go to L0226		; keycode 22 - RDN/i/VAR key
	go to L0044		; keycode 21 - x<>y/n/r key

L0104:	jsb L0171		; keycode 25 - y^x/FV/IRR key
	select rom 06 (L3106)

L0106:	jsb L0171		; EEX/Clr Reg/RAD key
	if 1 = s 7
	  then go to L0201
	if 0 = s 9
          then go to L0052
	if c[m] = 0
          then go to L0051
	p <- 12
L0116:	if b[p] = 0
	  then go to L0153
L0120:	clear status
	jsb L0231
	0 -> a[wp]
	m1 exchange c
	m1 -> c
L0125:	1 -> s 7
	go to L0201

L0127:	clear status
	1 -> s 0
	go to L0026

L0132:	select rom 04 (L2133)

op_pmt:	b exchange c[w]		; f PMT function
	register -> c 12
	jsb L0237
	p <- 5
	go to L0276

	a + 1 -> a[x]		; keycode 44 - 9/->R/->P key
L0141:	a + 1 -> a[x]		; keycode 43 - 8/log/10^x key
	if n/c go to L0237	; keycode 42 - 7/ln/e^x key

	jsb L0030		; keycode 41 - subtract
	delayed rom 05
	jsb L2477
done_x0:
	go to done

L0147:	jsb L0171		; ENTER^/Clr Prefix/RESET key
	c -> stack
L0151:	1 -> s 1
	go to L0250

L0153:	if p = 5
	  then go to L0125
	p - 1 -> p
	go to L0116

L0157:	a + 1 -> a[x]
L0160:	a + 1 -> a[x]		; keycode 64 - 3/n!/1/x
L0161:	a + 1 -> a[x]		; keycode 63 - 2/sqrt/x^2
	if n/c go to L0376	; keycode 62 - 1/H.MS+/M.MS-

	1 -> s 8		; keycode 61 - multiply
	jsb L0030
	select rom 02 (L1166)

L0166:	jsb L0171		; sigma+/sigma-/%sigma key
	jsb L0033
	select rom @10 (L4171)

L0171:	if 1 = s 13		; is it an f-prefixed function?
	  then go to L1722	;   yes, go do it
	if 1 = s 14		; is it a g-prefixed function?
	  then go to L1775	;   yes, go to it
	return

L0176:	0 -> s 5
	if 0 = s 5
	  then go to L0576
L0201:	display toggle
L0202:	0 -> s 15
	p <- 8
L0204:	p - 1 -> p
	if p # 1
	  then go to L0204
	if 1 = s 15
	  then go to L0202
	hi i'm woodstock	; nop?
L0212:	if 0 = s 15
	  then go to L0212
	display off
	binary
	0 -> a[wp]
	keys -> rom address	; main dispatch

	go to L0166		; keycode 74 - sigma+/sigma-/%sigma
	go to L0012		; keycode 73 - decimal/Lastx/pi
	go to L0377		; keycode 72 - zero/->H.MS/->H

	1 -> s 6		; keycode 71 - divide key
	jsb L0030
	select rom 04 (L2226)

L0226:	jsb L0171		; RDN/i/VAR key
	down rotate
done_x1:
	go to done

L0231:	p <- 4
	b exchange c[p]
	load constant 2
	p <- 4
	b exchange c[p]
	return

L0237:	a + 1 -> a[x]
	a + 1 -> a[x]		; keycode 54 - 6/tan/atan
	a + 1 -> a[x]		; keycode 53 - 5/cos/acos
	.legal
	go to L0157		; keycode 52 - 4/sin/asin

	1 -> s 4		; keycode 51 - add
	jsb L0030
	delayed rom 05
	jsb L2500
done:	0 -> s 1
L0250:	clear status
L0251:	select rom 01 (L0652)

L0252:	if 0 = s 10		; register arithmetic
	  then go to L0256
	0 -> s 10
	1 -> s 3
L0256:	1 -> s 12
	go to L0201

	go to L0023		; keycode 14 - f prefix
	go to L0065		; keycode 13 - %/ENG/Delta%
	go to L0062		; keycode 12 - xbar/SCI/s
	go to L0270		; keycode 11 - yhat/FIX/L.R. key

	clear status		; keycode 15 - g prefix
L0265:	1 -> s 14		;    f prefix enters here
	jsb L0201		; get another key
	select rom 02 (L1270)

L0270:	jsb L0171		; yhat/FIX/L.R. key
	jsb L0033
	select rom @10 (L4273)

L0273:	jsb L0171		; STO/PMT/N.D. key
	clear status
	go to L0042

L0276:	if 1 = s 0
	  then go to L1546
	m2 -> c
	if c[p] # 0
	  then go to L0315
	0 -> c[xs]
	c - 1 -> c[x]
	c - 1 -> c[x]
	c - 1 -> c[x]
	if c[xs] = 0
	  then go to L0327
	m2 exchange c
	c + 1 -> c[x]
	load constant 1
	m2 exchange c
L0315:	b -> c[w]
L0316:	c -> data
	go to done

	go to L0106		; keycode 33 - EEX/Clr Reg/RAD
	go to L0360		; keycode 32 - CHS/Clr Sigma/DEG
L0322:	return			; right half of enter key
	go to L0147		; keycode 31 - ENTER^/Clr Prefix/RESET

	jsb L0171		; keycode 34 - CLx/Clr Stack/GRD
	0 -> c[w]
	go to L0151

L0327:	p <- 7
	if c[p] = 0
	  then go to L0334
	jsb L0141
	jsb L0141
L0334:	p <- 6
	if c[p] = 0
	  then go to L0340
	jsb L0141
L0340:	p <- 5
	if c[p] = 0
	  then go to L0344
	jsb L0157
L0344:	p <- 4
	if c[p] = 0
	  then go to L0350
	jsb L0161
L0350:	p <- 3
	if c[p] = 0
	  then go to L0354
	a + 1 -> a[x]
L0354:	shift left a[x]
	b exchange c[w]
	jsb L0033
	select rom 05 (L2760)

L0360:	decimal			; CHS/Clear Statusigma/DEG key
	jsb L0171
	if c[m] = 0
	  then go to L0201
	if 0 = s 7
	  then go to L0055
	if 1 = s 9
	  then go to L0055
	p <- 4
	a exchange c[p]
	0 - c - 1 -> c[p]
	a exchange c[p]
	delayed rom 03
	go to L1676

L0376:	a + 1 -> a[x]
L0377:	if 1 = s 14		; digit key - is it prefixed?
	  then go to L0322	;   yes, return (?)
	if 1 = s 7
	  then go to L0443
	if 1 = s 11		; STO/RCL prefix?
	  then go to L1514	;   yes
	if 1 = s 12
	  then go to L0322
	if 1 = s 1
	  then go to L0414
	if 1 = s 9
	  then go to L0423
	c -> stack
L0414:	0 -> s 1
	1 -> s 9
	jsb L0753
	0 -> a[ms]
	a - 1 -> a[m]
	0 -> a[xs]
	a - 1 -> a[xs]
L0423:	p <- 1
L0424:	shift left a[wp]
	p + 1 -> p
	if p = 13
	  then go to L0474
	a + 1 -> a[p]
	if n/c go to L0473
	go to L0424

L0433:	1 -> s 3
	c + c -> c[xs]
	if n/c go to overf2
	0 -> c[w]
	return

L0440:	0 -> a[p]
	a - 1 -> a[wp]
L0442:	select rom 00 (L0043)

L0443:	if 1 = s 9
	  then go to L0442
	p <- 1
	shift left a[wp]
	p <- 3
	shift left a[wp]
L0451:	p <- 4
	shift right a[wp]
	shift right a[wp]
	decimal
	jsb L0470
	p <- 1
	if a[wp] # 0
	  then go to L0645
L0461:	jsb L0470
	jsb L0774
	go to L0442

L0464:	p <- 12
L0465:	b exchange c[x]
	jsb L0617
	go to L0574

L0470:	select rom 00 (L0071)

L0471:	jsb L0617
	go to L0566

L0473:	a - 1 -> a[p]
L0474:	p - 1 -> p
	if p = 2
	  then go to L0440
	if 1 = s 0
	  then go to L0504
	if p = 12
	  then go to L0504
	shift right b[m]
L0504:	a exchange c[w]
	c -> a[w]
	p - 1 -> p
	c - 1 -> c[wp]
	if a[m] # 0
	  then go to L0717
L0512:	a exchange c[w]
	if 1 = s 13
	  then go to L0120
	go to L0442

L0516:	if a[s] # 0
	  then go to L0710
	go to L0640

L0521:	a - 1 -> a[x]
	a - 1 -> a[x]
	a - 1 -> a[x]
	if a[xs] # 0
	  then go to L0771
	go to L0564

L0527:	if b[p] = 0
	  then go to L0532
	go to L0512

L0532:	a + 1 -> a[x]
	p - 1 -> p
	go to L0527

L0535:	decimal			; overf3
	if c[xs] = 0
	  then go to L0545
	c - 1 -> c[x]
	c + 1 -> c[xs]
	c - 1 -> c[xs]
	if n/c go to L0433
	c + 1 -> c[x]
L0545:	return			; overf4

overf2:	p <- 12			; mark as bad news
	0 -> c[wp]		; overflow
	c - 1 -> c[wp]		; all 9s
	0 -> c[xs]		; postiive exp
	return

L0553:	m2 -> c
	a exchange c[x]
	if a[xs] # 0
	  then go to L0471
	p <- 10
	jsb L0617
L0561:	c -> a[x]
	jsb L0470
	0 -> a[xs]
L0564:	if a[x] # 0
	  then go to L0521
L0566:	c -> a[x]
	jsb L0470
	delayed rom 00
	jsb L0231
	jsb L0774
	m1 -> c
L0574:	clear status
	select rom 00 (L0176)

L0576:	p <- 12
	decimal
	b exchange c[w]
L0601:	0 - c - 1 -> c[p]
	p - 1 -> p
	if p # 4
	  then go to L0601
	b exchange c[w]
	go to L0442

L0607:	if c[x] = 0
	  then go to L0465
	if p = 3
	 then go to L0703
	shift right b[m]
	c - 1 -> c[x]
	p - 1 -> p
	go to L0607

L0617:	p - 1 -> p
	if p = 2
	  then go to L0626
	if c[x] = 0
	  then go to L0626
	c - 1 -> c[x]
	if n/c go to L0617
L0626:	0 -> c[w]
	a exchange c[wp]
	c -> a[wp]
	a + c -> a[w]
	0 -> a[wp]
	m1 -> c
	if a[w] # 0
	  then go to L0516
	if 1 = s 13
	  then go to L0703
L0640:	binary
	a - 1 -> a[wp]
	decimal
	c -> a[s]
	return

L0645:	m1 -> c
	a + c -> c[x]
	jsb L0535
	if 0 = s 3
	  then go to L0461
L0652:	if c[m] # 0
	  then go to L0655
	0 -> c[w]
L0655:	jsb L0535
	m1 exchange c
L0657:	m1 -> c
	jsb L0753
	c -> a[m]
	0 -> a[x]
	f -> a[x]
	if 1 = s 0
	  then go to L0705
	if 0 = s 2
	  then go to L0553
	a exchange b[x]
	if c[xs] = 0
	  then go to L0607
	1 -> s 13
L0674:	shift right a[wp]
	p - 1 -> p
	c + 1 -> c[x]
	if c[x] = 0
	  then go to L0464
	if p # 2
	  then go to L0674
L0703:	1 -> s 0
	go to L0657

L0705:	p <- 4
	jsb L0626
	go to L0566

L0710:	if 0 = s 2
	  then go to L0757
	if 1 = s 0
	  then go to L0757
	p - 1 -> p
	shift right b[m]
	go to L0764

L0717:	decimal
	p <- 12
L0721:	if a[p] # 0
	  then go to L0527
	a - 1 -> a[x]
	shift left a[m]
	go to L0721

error:	0 -> b[w]
	0 -> a[w]
	0 -> s 1
	p <- 13
	load constant 15	; blank
	load constant 14	; E
	load constant 10	; r
	load constant 10	; r
	load constant 12	; o
	load constant 10	; r
	display off
L0741:	load constant 15	; blank
	if p # 0
	  then go to L0741
	a exchange c[w]
	if 0 = s 9
	  then go to L0574
	c -> register 11
	c -> register 12
	c -> register 14
	go to L0574

L0753:	0 -> a[ms]
	0 -> b[w]
	a + 1 -> a[s]
	select rom 03 (L1757)

L0757:	c + 1 -> c[x]
	c - 1 -> c[xs]
	if c[xs] = 0
	  then go to L0766
	c + 1 -> c[xs]
L0764:	shift right a[w]
	go to L0640

L0766:	m1 -> c
	c -> a[w]
	go to L0566

L0771:	c - 1 -> c[x]
	shift right b[m]
	go to L0561

L0774:	p <- 4
	shift left a[wp]
	shift left a[wp]
	return

; @1000 g-shfited digit jump table, referenced from routine at L1270
	go to op_to_h		; ->H
	go to op_hms_minus	; H.MS-
	go to op_square		; square
	go to L1034		; 1/x
	go to op_inv_trig	; asin
	go to op_inv_trig	; acos
	go to op_inv_trig	; atan
	select rom 07 (op_e_to_x)	; e^x
	select rom 07 (op_10_to_x)	; 10^x

L1011:	y -> a			; ->P
	jsb L1277
	if c[m] = 0
	  then go to L1244
	if c[s] = 0
	  then go to L1307
	go to L1304

; @1020: f-shifted digit jump table, referenced from routine at L1270
	go to op_to_hms		; ->H.MS
	go to op_hms_plus	; H.MS+
	go to op_sqrt		; square root
	go to op_factorial	; factorial
	go to op_sin		; sin
	go to op_cos		; cos
	go to op_tan		; tan
	go to op_ln		; ln
	go to op_log		; log

	jsb L1277		; ->R
	delayed rom @13
	go to L5443

L1034:	jsb L1314
	c -> a[w]
	register -> c 15
	delayed rom 04
	go to L2226

L1041:	delayed rom @13
	go to L5673

op_to_hms:
	1 -> s 4
op_to_h:
	b exchange c[w]
	jsb L1163
	go to done_x4

L1047:	select rom @12 (L5050)

L1050:	delayed rom 05
	go to L2455

op_hms_minus:
	0 - c - 1 -> c[s]
op_hms_plus:
	b exchange c[w]
	jsb L1163
	stack -> a
	c -> stack
	a exchange b[w]
	jsb L1163
	stack -> a
	jsb L1076
	1 -> s 4
	go to op_to_h

L1065:	jsb chk_arg
	0 -> a[w]
	a exchange c[m]
	jsb sqrt_sub
	jsb L1333
	go to L1050

op_sqrt:
	jsb L1065
	go to done_x4

	nop

L1076:	select rom 04 (L2077)

op_factorial:
	p <- 12
	jsb chk_arg
	if c[xs] # 0
	  then go to error
	c -> a[w]
L1104:	a -> b[w]
	shift left a[ms]
	if a[wp] # 0
	  then go to L1115
	a + 1 -> a[x]
	if a >= c[x]
	  then go to L1122
	c + 1 -> c[xs]
	if n/c go to done_x4
L1115:	a - 1 -> a[x]
	if n/c go to L1104
	delayed rom 01
	go to error

	nop

L1122:	0 -> c[w]
	c + 1 -> c[p]
	shift right c[w]
	c + 1 -> c[s]
	b exchange c[w]
L1127:	if b[p] = 0
	  then go to L1133
	shift right b[wp]
	c + 1 -> c[x]
L1133:	0 -> a[w]
	a - c -> a[p]
	if n/c go to L1141
	shift left a[w]
L1137:	a + b -> a[w]
	if n/c go to L1137
L1141:	a - c -> a[s]
	if n/c go to L1150
	shift right a[wp]
	a + 1 -> a[w]
	c + 1 -> c[x]
L1146:	a + b -> a[w]
	if n/c go to L1146
L1150:	a exchange b[wp]
	c - 1 -> c[p]
	if n/c go to L1127
	c - 1 -> c[s]
	if n/c go to L1127
	shift left a[w]
	a -> b[x]
	0 -> c[ms]
	a + c -> a[w]
	a exchange c[ms]
	go to done_x4

L1163:	delayed rom 03
	go to L1575

op_square:
	c -> a[w]
L1166:	delayed rom 05		; multiply function
	jsb L2415
done_x5:
	go to done_x4

sqrt_sub:
	a -> b[w]		; square root???
	b exchange c[w]
	c + c -> c[w]
	c + c -> c[w]
	a + c -> c[w]
	b exchange c[w]
	0 -> c[ms]
	c -> a[w]
	c + c -> c[x]
	if n/c go to sqr30
	c - 1 -> c[m]
sqr30:	c + c -> c[x]
	a + c -> c[x]
	p <- 0
	if c[p] # 0
	  then go to sqr50
	shift right b[w]
sqr50:	shift right c[w]
	a exchange c[x]
	0 -> c[w]
	a exchange b[w]
	p <- 13
	load constant 5
	shift right c[w]
	go to sqr100

op_log:	1 -> s 6
op_ln:	delayed rom 06
	jsb L3056
done_x4:
	select rom 03 (done_x3)

sqr60:	c + 1 -> c[p]
sqr70:	a - c -> a[w]
	if n/c go to sqr60
	a + c -> a[w]
	shift left a[w]
	p - 1 -> p
sqr100:	shift right c[wp]
	if p # 0
	  then go to sqr70
	0 -> c[p]
	a exchange c[w]
	b exchange c[w]
	return

	nop

L1244:	c + 1 -> c[xs]
	a exchange c[s]
	if a[w] # 0
	  then go to L1312
L1250:	a exchange b[w]
	stack -> a
	b exchange c[w]
	c -> stack
	b exchange c[w]
	delayed rom 05
	jsb L2654
	delayed rom @12
	go to L5002

	nop

chk_arg:
	if c[m] # 0
	  then go to L1265
	0 -> c[w]
L1265:	if c[s] # 0
	  then go to error
	return

L1270:	shift left a[x]		; f- and g- shifted digit functions
	if 0 = s 13
	  then go to L1274
	a + 1 -> a[xs]
L1274:	delayed rom 00
	jsb L0033
	a -> rom address

L1277:	delayed rom 07
	go to L3751

op_inv_trig:
	1 -> s 13
	a + 1 -> a[xs]
	a -> rom address

L1304:	1 -> s 7
	1 -> s 10
	0 -> c[s]
L1307:	delayed rom 05
	jsb L2541
	0 -> a[s]
L1312:	delayed rom @12
	go to L5036

L1314:	select rom 04 (L2315)

; both trig and inverse trig come here.
; S13=1 for inverse trig
op_cos:	1 -> s 10
op_sin:	1 -> s 6
op_tan:	jsb L1277
	if 1 = s 13
	  then go to L1047
	delayed rom @13
	go to L5450

L1324:	0 -> c[w]
	if 1 = s 6
	  then go to L0132
	c - 1 -> c[w]
	0 -> c[xs]
	0 -> c[s]
	go to done_x4

L1333:	delayed rom 05
	go to L2745

L1335:	c + 1 -> c[x]
L1336:	c - 1 -> c[s]
	if n/c go to L1335
	0 -> c[s]
	m1 exchange c
	a exchange c[w]
	a - 1 -> a[w]
	m1 -> c
	if 1 = s 10
	  then go to L1351
	0 - c -> c[x]
	a exchange b[w]
L1351:	if b[w] = 0
	  then go to L1324
	delayed rom 05
	jsb L2506
	0 -> a[s]
	if 0 = s 6
	  then go to L1041
	a -> b[w]
	p <- 1
	a + b -> a[p]
	if n/c go to L1373
	shift left a[w]
	a + 1 -> a[ms]
	if n/c go to L1374
	a + 1 -> a[s]
	shift right a[w]
	a -> b[w]
	c + 1 -> c[x]
L1373:	shift left a[w]
L1374:	a exchange c[ms]
	delayed rom 05
	jsb L2654
	delayed rom 07
	jsb L3707
	if 0 = s 13
	  then go to L1440
	b exchange c[w]
	a exchange b[w]
	register -> c 15
	a exchange c[w]
	delayed rom 05
	jsb L2543
	a exchange c[w]
	m1 exchange c
	a + c -> c[x]
	c -> stack
	m1 -> c
	a exchange c[w]
	delayed rom 07
	jsb L3402
	stack -> a
	c -> stack
	register -> c 15
	a exchange c[x]
	0 -> a[x]
	shift right a[w]
	m1 exchange c
	delayed rom 05
	jsb L2426
	delayed rom 05
	jsb L2455
	delayed rom @13
	go to L5715

	nop

L1437:	go to L1627

L1440:	b exchange c[w]
	a exchange b[w]
	m1 -> c
	a exchange c[w]
	a - c -> c[x]
	0 -> a[x]
	shift right a[w]
	delayed rom 05
	jsb L2506
	0 -> c[s]
	delayed rom @13
	go to L5673

L1454:	c - 1 -> c[x]
	if n/c go to L1605
L1456:	0 -> c[w]
	b -> c[m]
	if 0 = s 4
	  then go to L1726
	p + 1 -> p
	if p # 13
	  then go to L1467
	jsb L1552
	go to L1472

L1467:	p + 1 -> p
	jsb L1552
	p - 1 -> p
L1472:	p - 1 -> p
	jsb L1552
	c -> a[w]
	b -> c[w]
	go to L1742

	nop

	go to op_pv		; f PV function
	go to op_pmt_x		; f PMT function
	go to op_i		; f i function
	go to op_n		; f n function

op_fv:	b exchange c[w]		; f FV function
	register -> c 14
	a + 1 -> a[x]
	p <- 3
	go to L1675

L1511:	jsb L1765
	c + 1 -> c[xs]
	if n/c go to L1750

L1514:	a exchange c[x]		; digit has completed a STO/RCL sequence
	c -> data address
	a exchange c[x]
	if 1 = s 12
	  then go to L1745
	if 0 = s 10
	  then go to L0316
L1523:	jsb L1753
	data -> c
	go to done_x2

	nop
	nop
	nop
	nop

op_pmt_x:
	select rom 00 (op_pmt)	; f PMT function

L1533:	delayed rom @13
	jsb trc10
	c + c -> c[w]
	c + c -> c[w]
	shift right c[w]
	c + 1 -> c[m]
	0 -> c[x]
	return

L1543:	c + 1 -> c[x]
	c + 1 -> c[x]
done_x2:
	select rom 00 (done_x0)

L1546:	b -> c[w]
	go to L1523

L1550:	shift right c[wp]
	a + c -> c[wp]
L1552:	c -> a[wp]
	shift right c[wp]
	c + c -> c[wp]
	c + c -> c[wp]
	a - c -> c[wp]
	if 0 = s 4
	  then go to L1651
	0 -> a[w]
	c -> a[x]
	a + c -> c[w]
	0 -> c[x]
	return

op_sigma_minus_x:
	select rom @10 (op_sigma_minus)	; f SIGMA- function

op_pv:	b exchange c[w]		; f PV function
	register -> c 13
	delayed rom 00
	jsb L0160
	p <- 4
	go to L1675

L1575:	if b[m] = 0
	  then go to L1610
	p <- 12
	b -> c[x]
	c + 1 -> c[x]
	c + 1 -> c[x]
	if c[xs] # 0
	  then go to L1656
L1605:	p - 1 -> p
	if p # 0
	  then go to L1454
L1610:	b -> c[w]
	return

op_clr_sigma:
	c -> a[w]		; f CLR Sigma function
	0 -> c[w]
	c -> register 4
	c -> register 5
	c -> register 6
	go to L1644

	go to op_sigma_minus_x	; f SIGMA- function
	go to op_lastx		; f LASTx function

op_pi:	jsb L1753		; g Pi function
	jsb L1533
	go to done_x2

op_clr_reg:
	clear data registers	; f CLR Reg function
done_x3:
	go to done_x2

L1627:	if c[xs] # 0
	  then go to L1640
	if 1 = s 0
	  then go to L1642
	0 -> c[w]
	c - 1 -> c[w]
	p <- 9
	c + 1 -> c[wp]
	c - 1 -> c[x]
L1640:	delayed rom @11
	go to L4526
L1642:	delayed rom @11
	go to L4457

L1644:	c -> register 7
	c -> register 8
	c -> register 9
L1647:	a exchange c[w]
	go to done_x2

L1651:	a + c -> a[wp]
	shift right c[wp]
	if c[wp] # 0
	  then go to L1651
	return

L1656:	if b[xs] = 0
	  then go to L1610
	go to L1456

L1661:	go to L1747		; f ENG function
	go to L1511		; f SCI function

L1663:	jsb L1765		; f FIX function
	1 -> s 2
	go to L1750

op_n:	b exchange c[w]		; f n function
	register -> c 10
	p <- 7
	go to L1675

op_i:	b exchange c[w]		; f i function
	register -> c 11
L1674:	p <- 6
L1675:	select rom 00 (L0276)

L1676:	p <- 3
	if a[wp] # 0
	  then go to L0451
	delayed rom 00
	go to L0201

L1703:	a + 1 -> a[x]
	a + 1 -> a[x]
	0 -> c[w]
	display off
	c -> register 11
	if 0 = s 9
	  then go to L1644
	c -> register 12
	c -> register 14
	go to L1647

op_lastx:
	jsb L1753		; f LASTx function
	register -> c 15
	go to done_x2

	go to op_clr_reg	; f CLR Reg function
	go to op_clr_sigma	; f CLR Sigma function

L1722:	keys -> rom address	; execute f-prefixed function

	go to done_x2		; f CLR Prefix function

	clear regs		; f CLR Stack function
	go to done_x2

L1726:	0 -> a[w]
	jsb L1550
	p + 1 -> p
	if p = 13
	  then go to L1734
	p + 1 -> p
L1734:	jsb L1550
	shift left a[w]
	a + c -> a[w]
	b exchange c[w]
	delayed rom 05
	jsb L2661
L1742:	delayed rom 05
	go to L2674

L1744:	select rom 05 (L2745)

L1745:	delayed rom 04
	go to L2375

L1747:	jsb L1765
L1750:	f exchange a[x]
L1751:	m2 exchange c
	go to done_x2

L1753:	if 1 = s 1
	  then go to L1756
	c -> stack
L1756:	return

L1757:	a + 1 -> a[s]
	a exchange b[s]
	p <- 12
	a + 1 -> a[p]
	a -> b[p]
	return

L1765:	clear status
	1 -> s 12
	delayed rom 00
	jsb L0201
	0 -> s 2
	m2 exchange c
	0 -> c[xs]
	return

L1775:	clear status			; execute g-prefixed functions
	decimal
	keys -> rom address

op_nd:	delayed rom 00			; g N.D. function
	jsb L0032
	if c[s] = 0
	  then go to L2005
	1 -> s 9
L2005:	c -> a[w]
	jsb L2273
	jsb L2315
	c + c -> c[w]
	jsb L2137
	0 - c - 1 -> c[s]
	delayed rom 07
	jsb L3765
	m1 exchange c
	delayed rom 03
	jsb L1533
	c + c -> c[w]
	delayed rom 02
	jsb L1065
	c -> a[w]
	jsb L2315
	a exchange c[w]
	jsb L2137
	m1 -> c
	jsb L2273
	c -> stack
	c -> register 14
	jsb L2354
	load constant 2
	load constant 3
	load constant 1
	load constant 6
	load constant 4
	load constant 1
	load constant 9
	a exchange c[w]
	register -> c 15
	if 0 = s 9
	  then go to L2050
	0 - c - 1 -> c[s]
L2050:	jsb L2273
	jsb L2315
	jsb L2077
	jsb L2315
	a exchange c[w]
	jsb L2137
	c -> register 13
	jsb L2176
	load constant 3
	load constant 3
	load constant 0
	load constant 2
	load constant 7
	load constant 4
	load constant 4
	load constant 3
L2070:	c -> a[w]
	register -> c 13
	jsb L2273
	jsb L2175
	load constant 8
	go to L2105

L2076:	select rom 05 (L2477)

L2077:	select rom 05 (L2500)

	go to op_npv		; g NPV function
	go to op_nd		; g N.D. function
	go to op_var		; g VAR function

	select rom @10 (op_r_x)	; g r function
	select rom @10 (op_irr)	; g IRR function

L2105:	0 - c - 1 -> c[s]

L2106:	load constant 2
	load constant 1
	load constant 2
	load constant 5
	load constant 5
	load constant 9
	load constant 8
	jsb L2351
	jsb L2273
	jsb L2175
	load constant 7
	load constant 8
	load constant 1
	load constant 4
	load constant 7
	load constant 7
	load constant 9
	load constant 4
	jsb L2351
	jsb L2273
	go to L2230

L2133:	if 0 = s 13
	  then go to L2260
	0 -> c[w]
	go to L2312

L2137:	delayed rom 05
	go to L2422

op_npv:	c -> register 15	; g NPV function
	register -> c 8
	c -> a[w]
	jsb L2315
	jsb L2077
	c -> register 8
	0 - c - 1 -> c[s]
	m1 exchange c
	register -> c 11
	c -> a[w]
	jsb L2360
	jsb L2137
	m1 -> c
	delayed rom 06
	jsb L3337
	register -> c 15
	jsb L2273
	register -> c 9
	jsb L2077
	c -> register 9
	register -> c 13
	jsb L2076
done_x6:
	select rom 02 (done_x5)

op_pct_sigma:
	c -> register 15	; g %Sigman function
	c -> a[w]
	register -> c 5
	go to L2372

	nop

L2175:	m1 exchange c
L2176:	0 -> c[w]
	p <- 12
	load constant 1
	return

L2202:	load constant 3
	jsb L2351
	jsb L2273
	register -> c 14
	jsb L2273
	if 0 = s 9
	  then go to L2214
	jsb L2315
	a exchange c[w]
	jsb L2076
L2214:	delayed rom @10
	go to L4140

op_var:	1 -> s 7		; g VAR function

op_s_x:	select rom @10 (op_s)	; g s function

	go to op_pct_sigma	; g %Sigma function

	select rom 03 (op_pi)	; g Pi function

	nop

L2223:	y -> a
	jsb L2273
	jsb L2360
L2226:	jsb L2137		; division function
	go to done_x6

L2230:	m1 exchange c
	jsb L2354
	load constant 3
	load constant 5
	load constant 6
	load constant 5
	load constant 6
	load constant 3
	load constant 7
	load constant 8
	load constant 2
	0 - c - 1 -> c[s]
	jsb L2351
	jsb L2273
	m1 exchange c
	jsb L2354
	load constant 3
	load constant 1
	load constant 9
	load constant 3
	load constant 8
	load constant 1
	load constant 5
	go to L2202

L2260:	select rom @13 (L5661)

	go to op_delta_pct	; g Delta % function

	go to op_s_x		; g s function

	delayed rom @10		; g L.R. function
	go to op_lr

L2265:	if 1 = s 6
	  then go to L2301
	a exchange b[w]
	delayed rom 05
	jsb L2502
	select rom @13 (L5673)

L2273:	delayed rom 05
	go to L2415

get_mode:
	m2 exchange c
	p <- 12
	0 -> c[p]
L2300:	return

L2301:	if 0 = s 13
	  then go to L2260
	b exchange c[w]
	a exchange b[w]
	register -> c 15
	delayed rom 05
	jsb L2417
	delayed rom 07
	jsb L3404
L2312:	c -> stack
	register -> c 15
	select rom @13 (L5715)

L2315:	select rom 05 (L2716)

op_rad:	jsb get_mode
	go to L2326

	go to op_rad		; g RAD function

	jsb get_mode		; g DEG function
	go to L2350

	go to op_reset		; g RESET function

op_grd:	jsb get_mode		; g GRD function
	c + 1 -> c[p]
L2326:	c + 1 -> c[p]
	if n/c go to L2350
L2330:	if 0 = s 3
	  then go to L2300
	a exchange c[w]
	0 -> b[w]
	p <- 13
	load constant 15
	load constant 0
	load constant 11
	select rom 01 (L0741)

op_reset:
	m2 exchange c		; g RESET function
	p <- 12
	b exchange c[p]
	0 -> c[m]
	b exchange c[p]
	p <- 0
	0 -> c[p]
L2350:	select rom 03 (L1751)

L2351:	c -> a[w]
	m1 -> c
	select rom 05 (L2754)

L2354:	0 -> c[w]
	p <- 12
	c - 1 -> c[x]
	return

L2360:	jsb L2315
	c + 1 -> c[x]
	c + 1 -> c[x]
	return

op_delta_pct:
	c -> register 15	; g Delta % function
	y -> a
	a exchange c[w]
	jsb L2076
	y -> a
	a exchange c[w]
L2372:	jsb L2137
	delayed rom 03
	go to L1543

L2375:	decimal
	c -> register 15
	a exchange c[w]
	c -> data address
	data -> c
	if 0 = s 4
	  then go to L2535
	jsb L2500
L2405:	if 1 = s 3
	  then go to done_x7
	jsb L2534
	c -> data
	register -> c 15
	delayed rom 04
	jsb L2330
	go to done_x7

L2415:	0 -> b[w]
	a exchange b[m]
L2417:	jsb L2621
	jsb L2661
	go to L2455

L2422:	if c[m] = 0
	  then go to error_x0
	jsb L2541
	go to L2455

L2426:	a exchange b[w]
L2427:	jsb L2552
	m1 -> c
	go to L2661

L2432:	a exchange c[w]
	a exchange c[s]
	jsb L2555
	jsb L2661
	0 -> c[m]
	delayed rom 06
	go to L3050

L2441:	c -> a[w]
	jsb L2716
	jsb L2500
	delayed rom 06
	jsb L3056
	if 0 = s 11
	  then go to L2451
	0 - c - 1 -> c[s]
L2451:	c -> a[w]
	m1 -> c
	a exchange c[w]
	go to L2645

L2455:	p <- 12
	0 -> b[w]
	a -> b[x]
	a + b -> a[wp]
	if n/c go to L2465
	shift right a[wp]
	c + 1 -> c[x]
	a + 1 -> a[p]
L2465:	a exchange c[m]
	c -> a[w]
	return

L2470:	jsb L2745
	jsb L2541
L2472:	a + c -> a[s]
	a - 1 -> a[s]
L2474:	0 -> c[x]
	delayed rom 06
	go to L3074

L2477:	0 - c - 1 -> c[s]	; subtraction function
L2500:	jsb add3		; addition function
	go to L2455

L2502:	0 -> a[w]
	a + 1 -> a[s]
	shift right a[w]
	0 - c -> c[x]
L2506:	0 -> c[m]
	p <- 12
	go to L2512
L2511:	c + 1 -> c[p]
L2512:	a - b -> a[w]
	if n/c go to L2511
	a + b -> a[w]
	shift left a[w]
	p - 1 -> p
	if p # 2
	  then go to L2526
	b exchange c[x]
	0 -> c[x]
	a - 1 -> a[ms]
	if n/c go to L2512
	p <- 13
L2526:	if p # 13
	  then go to L2512
	0 -> a[w]
	a exchange c[w]
	a exchange c[s]
	go to L2726

L2534:	select rom 01 (L0535)

L2535:	if 0 = s 8
	  then go to L2630
	jsb L2415
	go to L2405

L2541:	0 -> b[w]
	b exchange c[m]
L2543:	a - c -> c[s]
	if n/c go to L2546
	0 - c -> c[s]
L2546:	a - c -> c[x]
	0 -> a[x]
	0 -> a[s]
	go to L2506

L2552:	p <- 0
	go to L2626

L2554:	a + b -> a[w]
L2555:	c - 1 -> c[p]
L2556:	if n/c go to L2554
	if p = 12
	  then go to L2566
	p + 1 -> p
	shift right a[w]
	go to L2555

L2564:	c + 1 -> c[x]
	shift right a[w]
L2566:	return

L2567:	jsb add3
	jsb L2455
	jsb L2534
	c -> data
	return

add3:	p <- 12			; add routine
	0 -> b[w]		; zap
	a + 1 -> a[xs]		; offset exp
	a + 1 -> a[xs]		; can handle +- 200 exp
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a >= c[x]		; compare epxs
	  then go to add4
	a exchange c[w]		; smaller in c
add4:	a exchange c[m]		; smaller in am
	if c[m] = 0		; look for zero
	  then go to add5
	a exchange c[w]		; smaller in cm, answer exp c
add5:	b exchange c[m]		; smaller in b, extend to 13
add6:	if a >= c[x]		; when exps are equel
	  then go to add1
	shift right b[w]	; line up smaller number
	a + 1 -> a[x]		; up smaller exp
	if b[w] = 0		; fall out of b
	  then go to add1
	go to add6

L2621:	a + c -> c[x]
	p <- 3
	a - c -> c[s]
	if n/c go to L2626
	0 - c -> c[s]
L2626:	0 -> a[w]
	go to L2555

L2630:	if 1 = s 3
	  then go to L2633
	a exchange c[w]
L2633:	if 0 = s 6
	  then go to L2667
	jsb L2422
	go to L2405

L2637:	register -> c 14
L2640:	c -> a[w]
	register -> c 11
	if c[m] # 0
	  then go to L2676
	register -> c 12
L2645:	jsb L2422
done_x7:
	select rom 00 (done)

	nop
	nop

L2651:	1 -> s 11
	register -> c 13
	go to L2640

L2654:	m1 exchange c
	b -> c[w]
	jsb L2552
	m1 -> c
	c + c -> c[x]
L2661:	if a[s] # 0
	  then go to L2564
	return

L2664:	1 -> s 7
	jsb L2745
	go to L2474

L2667:	jsb L2477
	go to L2405

L2671:	if 0 = s 4
	  then go to L2674
	0 - c - 1 -> c[s]
L2674:	jsb L2745
	go to L2455

L2676:	register -> c 12
	jsb L2422
	jsb L2774
	jsb L2415
	jsb L2716
	if 1 = s 11
	  then go to L2713
	jsb L2500
L2706:	select rom @11 (L4707)

L2707:	jsb L2621
	0 -> c[m]
	delayed rom 07
	go to L3770

L2713:	a exchange c[w]
	jsb L2477
	go to L2706

L2716:	0 -> c[w]
	c + 1 -> c[s]
	shift right c[w]
	return

L2722:	a + 1 -> a[x]
	p - 1 -> p
	go to L2432

error_x0:	select rom 01 (error)

L2726:	b exchange c[x]
	go to L2745

add1:	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] # 0
	  then go to add13
	a + b -> a[w]
	if n/c go to L2661
add13:	if a >= b[m]
	  then go to add14
	0 - c - 1 -> c[s]
	a exchange b[w]
add14:	a - b -> a[w]
L2745:	p <- 12
	if a[wp] # 0
	  then go to L2764
	0 -> c[x]
L2751:	return

	nop
	nop

L2754:	jsb add3
	jsb L2455
	register -> c 13
	return

L2760:	delayed rom @11
	go to L4424

L2762:	a + 1 -> a[s]
	c - 1 -> c[x]
L2764:	if a[p] # 0
	  then go to L2751
	shift left a[wp]
	go to L2762

	nop
	nop
	nop
	nop

L2774:	register -> c 11
	c - 1 -> c[x]
	c - 1 -> c[x]
	return

L3000:	if c[x] = 0
	  then go to L3043
	c - 1 -> c[w]
	b exchange c[w]
	0 -> b[m]
	jsb lnc10
	a exchange c[w]
	a - c -> c[w]
	if b[xs] = 0
	  then go to L3013
	a - c -> c[w]
L3013:	a exchange c[w]
	b exchange c[w]
	if c[xs] = 0
	  then go to L3020
	0 - c - 1 -> c[w]
L3020:	a exchange c[wp]
L3021:	p - 1 -> p
	shift left a[w]
	if p # 1
	  then go to L3021
	p <- 12
	if a[p] # 0
	  then go to L2722
	shift left a[m]
	select rom 05 (L2432)

L3032:	a + b -> a[w]
L3033:	c - 1 -> c[p]
	if n/c go to L3032
	if c[s] # 0
	  then go to L3154
	if p = 12
	  then go to L3000
	0 -> c[w]
	jsb L3261
L3043:	jsb L3355
	0 -> a[s]
	if 0 = s 7
	  then go to L3050
	c - 1 -> c[s]
L3050:	if 1 = s 10
	  then go to L3303
	if 1 = s 6		; base 10 log?
	  then go to logb10	;   yes, adjust
L3054:	select rom 05 (L2455)

; Entry point: logarithm (s6=0 for natural log, 1 for log base 10)

L3055:	jsb L3276
L3056:	p <- 12
	0 -> s 4
	0 -> s 7
	if c[m] = 0
	  then go to L3315
	if c[s] # 0
	  then go to L3174
L3065:	if c[x] = 0
	  then go to L3330
	c + 1 -> c[x]
	0 -> a[w]
	a - c -> a[m]
	if c[x] = 0
	  then go to L2664
L3074:	shift right a[wp]
	a -> b[s]
	p <- 13
L3077:	p - 1 -> p
	a - 1 -> a[s]
	if n/c go to L3077
	a exchange b[s]
	a -> b[s]
	0 -> c[ms]
	go to L3115

L3106:	jsb L3273
	jsb L3056
	stack -> a
	delayed rom 00
	go to done

L3113:	shift right a[w]
	c + 1 -> c[p]
L3115:	a exchange b[s]
	a -> b[w]
	binary
	a + c -> a[s]
	m2 exchange c
	a exchange c[s]
	shift left a[w]
L3124:	shift right a[w]
	c - 1 -> c[s]
	if n/c go to L3124
	decimal
	m2 exchange c
	a + b -> a[w]
	shift left a[w]
	a - 1 -> a[s]
	if n/c go to L3113
	c -> a[s]
	a - 1 -> a[s]
	a + c -> a[s]
	if n/c go to L3144
L3141:	a exchange b[w]
	shift left a[w]
	go to L3156

L3144:	if p = 1
	  then go to L3141
	c + 1 -> c[s]
	p - 1 -> p
	a exchange b[w]
	a exchange b[s]
	shift left a[w]
	go to L3115

L3154:	c - 1 -> c[s]
	p + 1 -> p
L3156:	b exchange c[w]
	delayed rom 07
	jsb L3557
	shift right a[w]
	b exchange c[w]
	go to L3033

L3164:	if a[x] # 0
	  then go to L3205
	go to L3324

L3167:	if a[s] # 0
	  then go to L3324
	a exchange c[w]
	0 -> c[w]
	return

L3174:	if 0 = s 10
	  then go to error_x0
	a exchange c[w]
	m1 -> c
	a exchange c[w]
	a -> b[w]
	if a[xs] # 0
	  then go to L3324
	a + 1 -> a[x]
L3205:	a - 1 -> a[x]
	shift left a[ms]
	if a[m] # 0
	  then go to L3164
	if a[x] # 0
	  then go to L3223
	a exchange c[s]
	c -> a[s]
	c + c -> c[s]
	c + c -> c[s]
	a + c -> c[s]
	if c[s] = 0
	  then go to L3065
	1 -> s 4
L3223:	0 -> c[s]
	go to L3065

L3225:	0 -> b[w]
	a -> b[m]
	0 -> a[s]
L3230:	if a[x] # 0
	  then go to L3252
	if c[s] # 0
	  then go to L3266
	binary
	a + 1 -> a[s]
	decimal
	a exchange b[w]
	a + 1 -> a[s]
	shift right a[w]
	a exchange b[w]
	a exchange c[s]
	0 -> c[x]
	delayed rom 05
	jsb L2506
	binary
	delayed rom 05
	go to L2472

L3252:	a + 1 -> a[x]
	shift right b[w]
	a + 1 -> a[s]
	p - 1 -> p
	if p = 2
	  then go to L3325
	go to L3230

L3261:	p + 1 -> p
L3262:	c - 1 -> c[x]
	if p # 12
	  then go to L3261
	return

L3266:	a exchange b[s]
	shift right a[w]
	1 -> s 7
	0 -> c[w]
	go to L3115

L3273:	delayed rom 00
	jsb L0033
	y -> a
L3276:	1 -> s 6
	1 -> s 10
	m1 exchange c
	a exchange c[w]
	return

L3303:	a exchange b[w]
	a exchange c[w]
	m1 -> c
	select rom 05 (L2707)

logb10:	b exchange c[w]		; convert ln result to log base 10
	jsb lnc10
	b exchange c[w]
	delayed rom 05
	jsb L2506
	go to L3054

L3315:	if 0 = s 10
	  then go to error_x0
	a exchange c[w]
	m1 -> c
	a exchange c[w]
	if a[m] # 0
	  then go to L3167
L3324:	select rom 05 (error_x0)

L3325:	0 -> a[w]
	a exchange c[m]
	go to L3043

L3330:	c -> a[w]
	a - 1 -> a[p]
	if a[m] # 0
	  then go to L2470
	0 -> c[w]
	0 -> a[w]
	go to L3050

L3337:	jsb L3276
	p <- 12
	c -> a[w]
	a + 1 -> a[x]
	if a[xs] # 0
	  then go to L3225
	0 -> a[w]
	a + 1 -> a[p]
	delayed rom 05
	jsb add3
	jsb L3054
L3352:	go to L3056

L3353:	go to L3055

L3354:	go to L3337

L3355:	delayed rom 05
	go to L2745

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
	p <- 12
	return

	nop
	nop

L3402:	delayed rom 05
	jsb L2455
L3404:	if 1 = s 7
	  then go to L3533
	go to L3534

	nop

op_e_to_x:
	go to L3544

op_10_to_x:
	jsb L3455
	go to done_x8

L3413:	b exchange c[w]
L3414:	jsb L3557
	b exchange c[w]
	jsb L3661
	if p # 5
	  then go to L3414
	p <- 13
	load constant 7
	a exchange c[s]
	b exchange c[w]
	go to L3431

L3426:	a -> b[w]
	c - 1 -> c[s]
	if n/c go to L3444
L3431:	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	a - 1 -> a[s]
	if n/c go to L3426
	a exchange b[w]
	a + 1 -> a[p]
	delayed rom 05
	go to L2671

L3443:	shift right a[wp]	; eca21?
L3444:	a - 1 -> a[s]		; eca22?
	if n/c go to L3443
	0 -> a[s]
	a + b -> a[w]
	a + 1 -> a[p]
	if n/c go to L3426
	shift right a[wp]
	a + 1 -> a[p]
	if n/c go to L3431
L3455:	a exchange c[w]
	jsb L3531
	0 -> s 4
	b exchange c[w]
	0 -> c[w]
	a exchange c[w]
	delayed rom 05
	go to L2707

L3465:	c + 1 -> c[x]
	shift right a[w]
L3467:	if c[xs] = 0
	  then go to L3743
	if a[s] # 0
	  then go to L3465
	0 - c -> c[x]
	if c[xs] = 0
	  then go to L3516
	0 -> c[m]
	0 -> a[w]
	c + c -> c[x]
	if n/c go to L3520
L3502:	0 -> c[wp]
	if c[s] # 0
	  then go to L3511
	c - 1 -> c[w]
	0 -> c[xs]
	if 1 = s 4
	  then go to L3512
L3511:	0 -> c[s]
L3512:	0 -> s 8
	c -> a[w]
	return

L3515:	shift right a[w]
L3516:	c - 1 -> c[x]
	if n/c go to L3515
L3520:	0 -> c[x]
L3521:	if c[s] = 0
	  then go to L3526
	a exchange b[w]
	a - b -> a[w]
	0 - c - 1 -> c[x]
L3526:	0 -> c[ms]
	return

	nop

L3531:	delayed rom 06
	go to lnc10

L3533:	0 - c - 1 -> c[s]
L3534:	select rom 01 (L0535)

L3535:	c + 1 -> c[x]
L3536:	a - b -> a[w]
	if n/c go to L3535
	a + b -> a[w]
	c - 1 -> c[m]
	if n/c go to L3546
	go to L3521

L3544:	jsb L3765
done_x8:
	select rom 00 (done_x0)

L3546:	a exchange c[w]
	shift left a[x]
	a exchange c[w]
	shift left a[w]
	if 0 = s 8
	  then go to L3536
	if c[xs] # 0
	  then go to L3502
	go to L3536

L3557:	0 -> c[w]
	if p = 12
	  then go to lnc2
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

lncd1:	p <- 9			; ln(1.1)
	load constant 3		; compare lnc40 in -41
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

lncd2:	p <- 7			; ln(1.01)
	load constant 3		; compare lnc50 in -41
	load constant 3
	load constant 0
	load constant 8
	load constant 5
	load constant 3
	load constant 1
	load constant 7
	p <- 10
	return

lncd3:	p <- 5			; ln(1.001)
	load constant 3		; compare lnc60 in -41
	load constant 3
	load constant 3
	load constant 0
	load constant 8
	load constant 4
	p <- 9
	return

lncd4:	p <- 3			; ln(1.0001)
	load constant 3		; compare lnc70 in -41
	load constant 3
	load constant 3
	load constant 3
	p <- 8
	return

lncd5:	p <- 1			; ln(1.00001)
	load constant 3		; compare lnc80 in -41
	load constant 3
	p <- 7
	return

L3660:	c + 1 -> c[s]
L3661:	a - b -> a[w]
	if n/c go to L3660
	a + b -> a[w]
	shift left a[w]
	shift right c[ms]
	b exchange c[w]
	p - 1 -> p
	return

lnc2:	p <- 11			; load ln(2)
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

L3707:	0 -> b[w]
	b exchange c[x]
	p <- 12
	b -> c[w]
	c + c -> c[x]
	if n/c go to L3736
	b -> c[w]
	delayed rom @12
	jsb L5336
L3720:	a + 1 -> a[p]
	if n/c go to L3724
	p + 1 -> p
	go to L3720

L3724:	delayed rom 05
	jsb L2661
L3726:	0 -> b[w]
	delayed rom 02
	go to sqrt_sub

L3731:	p - 1 -> p
	if p # 0
	  then go to L3737
	b -> c[w]
	go to L3726

L3736:	b -> c[w]
L3737:	c - 1 -> c[x]
	if n/c go to L3731
	b -> c[w]
	go to L3720

L3743:	a exchange c[w]
	shift left a[wp]
	shift left a[wp]
	shift left a[wp]
	a exchange c[w]
	go to L3536

L3751:	b exchange c[w]
	m2 -> c
	p <- 12
	if c[p] = 0
	  then go to L3763
	c - 1 -> c[p]
	c - 1 -> c[p]
	if n/c go to L3762
	1 -> s 12
L3762:	1 -> s 14
L3763:	b exchange c[w]
	return

L3765:	0 -> a[w]
	0 -> s 4
	a exchange c[m]
L3770:	b exchange c[w]
	jsb L3531
	b exchange c[w]
	1 -> s 8
	jsb L3467
	if 1 = s 8
	  then go to L3413
	return

L4000:	if 1 = s 12
	  then go to L4266
	register -> c 14
	if 1 = s 6
	  then go to L4275
	jsb L4020
	if 1 = s 13
	  then go to L4136
	c -> register 13
	if 1 = s 4
	  then go to L4014
	c -> stack
L4014:	1 -> s 13
	go to L4053

L4016:	register -> c 7
	go to L4045

L4020:	select rom @11 (L4421)

op_lr:	c -> register 15	; g L.R. function
	stack -> a
L4023:	jsb L4375
L4024:	jsb L4261
	m1 exchange c
	if 0 = s 6
	  then go to L4033
	register -> c 8
	go to L4034

L4032:	select rom 00 (L0033)

L4033:	register -> c 6
L4034:	jsb L4311
L4035:	c -> a[w]
	if 1 = s 13
	  then go to L4016
	register -> c 4
	jsb L4303
	if c[w] = 0
	  then go to error_x1
	c + 1 -> c[p]
L4045:	jsb L4261
	m1 -> c
	jsb L4075
	if 1 = s 14
	  then go to L4000
	c -> register 14
L4053:	jsb L4375
	if 0 = s 13
	  then go to L4315
	register -> c 9
	go to L4024

L4060:	m1 exchange c
	jsb L4307
	m1 exchange c
	go to L4343

	nop

L4065:	jsb L4101
	register -> c 4
	jsb L4020
	c -> stack
	jsb L4375
	register -> c 4
	jsb L4020
	go to done_x9

L4075:	select rom 04 (L2076)

L4076:	select rom 04 (L2077)

L4077:	register -> c 6
	return

L4101:	register -> c 7
	go to L4376

	nop

op_r_x:	go to op_r		; g r function

op_irr:	jsb L4314		; g IRR function
L4106:	c -> register 11
	register -> c 13
	display toggle
	0 -> s 9
	if c[m] = 0
	  then go to error_x1
	0 - c - 1 -> c[s]
	c -> register 14
	jsb L4362
	0 -> c[x]
	m1 exchange c
	0 -> c[w]
	c -> register 12
L4123:	c -> register 15
	register -> c 11
	c -> a[w]
	register -> c 12
	jsb L4261
	register -> c 14
	go to L4323

L4132:	if 1 = s 13
	  then go to L4077
	register -> c 8
	return

L4136:	if 1 = s 4
	  then go to L4155
L4140:	0 -> c[w]
	c -> register 13
	c -> register 14
	a exchange c[w]
done_x9:
	select rom 03 (done_x2)

L4145:	register -> c 4
	c -> a[w]
	jsb L4314
	jsb L4370
	delayed rom 04
	jsb L2330
	delayed rom 00
	go to L0151

L4155:	m1 exchange c
	register -> c 13
	c -> a[w]
	register -> c 15
	jsb L4261
	m1 -> c
	jsb L4076
	go to L4140

L4165:	0 - c - 1 -> c[s]
L4166:	select rom 05 (L2567)

op_sigma_minus:
	jsb L4032		; f SIGMA- function
	1 -> s 4
L4171:	m1 exchange c
	1 -> s 13
	jsb L4375
L4174:	m1 -> c
	jsb L4370
	m1 -> c
	c -> a[w]
	jsb L4261
	jsb L4132
	jsb L4367
	if 0 = s 13
	  then go to L4145
	y -> a
	m1 -> c
	a exchange c[w]
	m1 exchange c
	m1 -> c
	jsb L4261
	register -> c 9
	jsb L4367
	0 -> s 13
	jsb L4101
	go to L4174

op_s:	c -> register 15	; g s function
	stack -> a
	jsb L4101
L4223:	jsb L4261
	register -> c 4
	jsb L4020
	jsb L4132
	a exchange c[w]
	jsb L4075
	0 -> c[s]
	m1 exchange c
	register -> c 4
	c -> a[w]
	jsb L4314
	jsb L4075
	m1 -> c
	a exchange c[w]
	jsb L4020
	if 1 = s 7
	  then go to L4245
	jsb L4373
L4245:	if 1 = s 13
	  then go to done_x9
	c -> stack
	1 -> s 13
	jsb L4375
	go to L4223

L4253:	0 -> c[s]
	jsb L4373
	register -> c 13
	a exchange c[w]
	jsb L4020
	go to L4140

L4261:	delayed rom 05
	go to L2415

op_r:	c -> register 15	; g r function
	1 -> s 12
	go to L4023

L4266:	c -> register 13
	jsb L4101
	0 -> s 12
	1 -> s 6
	go to L4024

L4273:	1 -> s 4
	go to L4023

L4275:	jsb L4261
	if c[m] # 0
	  then go to L4253
	jsb L4314
	a exchange c[w]
	go to L4140

L4303:	if c[xs] # 0
	  then go to error_x1
	if c[m] = 0
	  then go to error_x1
L4307:	p <- 12
L4310:	c - 1 -> c[p]
L4311:	if c[s] # 0
	  then go to error_x1
	return

L4314:	select rom 04 (L2315)

L4315:	register -> c 7
	jsb L4261
	m1 exchange c
	register -> c 9
	1 -> s 14
	go to L4035

L4323:	jsb L4076
	c -> register 12
	register -> c 11
	c -> a[w]
	register -> c 14
	jsb L4261
	register -> c 15
	c -> data address
	data -> c
	if 1 = s 9
	  then go to L4343
	if c[s] # 0
	  then go to L4060
	if c[m] = 0
	  then go to L4060
	1 -> s 9
L4343:	jsb L4076
	c -> register 14
	jsb L4362
L4346:	shift right c[wp]
	p - 1 -> p
	if p # 0
	  then go to L4346
	c -> a[w]
	register -> c 15
	a - c -> c[x]
	if c[x] = 0
	  then go to L4600
	a - c -> c[x]
	c + 1 -> c[x]
	if n/c go to L4123
L4362:	register -> c 10
	jsb L4303
	if c[x] = 0
	  then go to L4377
	go to L4310

L4367:	a exchange c[w]
L4370:	if 1 = s 4
	  then go to L4165
	go to L4166

L4373:	delayed rom 02
	go to L1065

L4375:	register -> c 5
L4376:	c -> a[w]
L4377:	return

L4400:	jsb L4666
	jsb L4753
	jsb L4714
	go to L4447

L4404:	a + c -> c[x]
	if n/c go to L4672
	go to L4621

	go to error_x1

L4410:	1 -> s 11
	1 -> s 12
	go to L4400

	go to L4705

L4414:	select rom 05 (L2415)
	
	go to L4636

	select rom @12 (L5017)
	
	go to error_x1
	go to error_x1

L4421:	select rom 05 (L2422)
	
	go to error_x1
	go to L4457

L4424:	a -> rom address

	go to L4500
	go to L4632
	go to error_x1

error_x1:
	delayed rom 01
	go to error

	go to error_x1
	go to L4754
	go to L4740
	go to L4400
	select rom 03 (L1437)
	go to L4442
	go to L4410

	1 -> s 11
L4442:	jsb L4666
	0 - c - 1 -> c[s]
	jsb L4753
	jsb L4714
	a exchange c[w]
L4447:	jsb L4476
	if c[m] = 0
	  then go to L4730
	jsb L4703
	if 1 = s 11
	  then go to L4637
	jsb L4421
	go to L4722

L4457:	register -> c 10
L4460:	c -> a[w]
	jsb L4714
	a exchange c[w]
	jsb L4421
	if 0 = s 0
	  then go to L4520
	0 - c - 1 -> c[s]
	m1 exchange c
	register -> c 9
	c -> a[w]
	0 -> a[s]
	go to L4522

L4474:	register -> c 14
	go to L4735

L4476:	select rom 05 (L2477)

L4477:	select rom 05 (L2500)

L4500:	register -> c 10
	0 - c - 1 -> c[s]
	c -> register 8
	register -> c 14
	0 - c - 1 -> c[s]
L4505:	jsb L4725
	jsb L4421
	c -> register 9
	jsb L4714
	p <- 11
	load constant 2
	jsb L4414
	register -> c 8
	jsb L4711
	a exchange c[w]
	go to L4763

L4520:	jsb L4775
	jsb L4421
L4522:	m1 -> c
	jsb L4752
	jsb L4714
	jsb L4476
L4526:	if 0 = s 0
	  then go to L4702
L4530:	c -> register 11
	c + 1 -> c[s]
	p <- 12
	c - 1 -> c[p]
	if c[w] = 0
	  then go to L4702
	register -> c 8
	0 - c - 1 -> c[s]
	jsb L4753
	c -> register 7
	display toggle
	register -> c 8
	jsb L4414
	register -> c 11
	jsb L4414
	m1 exchange c
	register -> c 11
	c -> a[w]
	jsb L4714
	jsb L4477
	m1 -> c
	a exchange c[w]
	jsb L4421
	register -> c 7
	jsb L4477
	jsb L4714
	jsb L4476
	m1 exchange c
	register -> c 9
	c -> a[w]
	register -> c 11
	jsb L4414
	jsb L4714
	jsb L4476
	register -> c 7
	jsb L4477
	m1 -> c
	if c[m] = 0
	  then go to L4622
	go to L4613

L4600:	register -> c 11
	jsb L4725
	jsb L4414
	m1 exchange c
	c -> a[w]
	register -> c 14
	jsb L4414
	m1 -> c
	jsb L4476
	register -> c 14
	a exchange c[w]
L4613:	jsb L4421
	0 -> c[w]
	p <- 0
	load constant 6
	if a[xs] # 0
	  then go to L4404
L4621:	register -> c 11
L4622:	jsb L4414
	if c[m] = 0
	  then go to L4672
	register -> c 11
	jsb L4477
	if 1 = s 9
	  then go to L4106
	go to L4530

L4632:	register -> c 10
	c -> register 8
	register -> c 13
	go to L4505

L4636:	select rom 05 (L2637)

L4637:	a exchange c[w]
	jsb L4421
	if 0 = s 12
	  then go to L4715
L4643:	register -> c 14
	go to L4716

L4645:	jsb L4714
	jsb L4477
	m1 exchange c
	register -> c 8
	c -> a[w]
	register -> c 9
	jsb L4476
	jsb L4477
	m1 -> c
	jsb L4421
	c + 1 -> c[x]
	c + 1 -> c[x]
	c + 1 -> c[x]
	if c[xs] # 0
	  then go to L5555
	register -> c 8
	go to L4747

L4666:	jsb L4703
L4667:	c -> a[w]
	register -> c 10
	return

L4672:	jsb L4714
	jsb L4477
	register -> c 11
	jsb L4414
L4676:	if 0 = s 9
	  then go to L4702
	jsb L4714
	jsb L4476
L4702:	select rom 03 (L1703)

L4703:	delayed rom 05
	go to L2774

L4705:	jsb L4776
	jsb L4421
L4707:	jsb L4751
	go to L4757

L4711:	if c[m] = 0
	  then go to error_x1
	return

L4714:	select rom 04 (L2315)

L4715:	register -> c 13
L4716:	jsb L4414
L4717:	select rom @13 (done_x11)

L4720:	register -> c 10
	c -> a[w]
L4722:	register -> c 12
	go to L4716

L4724:	register -> c 14
L4725:	c -> a[w]
	register -> c 12
	return

L4730:	if 0 = s 11
	  then go to L4720
	if 1 = s 12
	  then go to L4474
	register -> c 13
L4735:	jsb L4667
	jsb L4421
	go to L4717

L4740:	jsb L4666
	0 - c - 1 -> c[s]
	jsb L4753
	go to L4643

L4744:	jsb L4714
	c -> a[w]
	register -> c 9
L4747:	jsb L4421
	go to L4530

L4751:	select rom 06 (L3352)

L4752:	select rom 06 (L3353)

L4753:	select rom 06 (L3354)

L4754:	jsb L4666
	jsb L4753
	go to L4715

L4757:	m1 exchange c
	jsb L4703
	delayed rom 05
	go to L2441

L4763:	jsb L4421
	if c[xs] = 0
	  then go to L4744
	jsb L4477
	register -> c 8
	1 -> s 0
	if a[xs] # 0
	  then go to L4460
	c -> a[w]
	go to L4645

L4775:	m1 exchange c
L4776:	register -> c 14
	c -> a[w]
	register -> c 13
	return

L5002:	delayed rom 07
	jsb L3707
	a exchange b[w]
	a exchange c[w]
	register -> c 15
	delayed rom 05
	jsb L2417
	stack -> a
	c -> stack
	m1 -> c
	go to L5053

	nop
	nop

L5017:	delayed rom 05
	go to L2651

L5021:	a -> b[w]
	if b[w] = 0
	  then go to L5137
	a - 1 -> a[p]
	if a[w] # 0
	  then go to L5217
	0 -> c[w]
	if 0 = s 6
	  then go to L5131
	jsb togs10
	go to L5137

L5034:	delayed rom 02
	go to L1250

L5036:	delayed rom 01
	jsb L0535
	if 0 = s 3
	  then go to L5034
	if c[w] # 0
	  then go to L5050
	stack -> a
	register -> c 15
	c -> stack
	0 -> c[w]
L5050:	0 -> a[w]
	0 -> b[w]
	c -> a[m]
L5053:	if c[s] = 0
	  then go to L5064
	1 -> s 4
	if 0 = s 13
	  then go to L5065
	if 0 = s 10
	  then go to L5065
	0 -> s 10
	1 -> s 7
L5064:	0 -> s 4
L5065:	p <- 12
	if c[xs] = 0
	  then go to L5214
	if 0 = s 13
	  then go to L5072		; what's the point?
L5072:	if 0 = s 6
	  then go to L5227
	jsb L5337
	0 -> c[w]
	a -> b[w]
	b exchange c[w]
	shift right a[w]
	a + 1 -> a[p]
	0 - c -> c[wp]
	if n/c go to L5116
	a exchange b[w]
	a exchange c[w]
	jsb L5343
	m1 exchange c
	a exchange c[w]
	delayed rom 05
	jsb L2427
	c - 1 -> c[x]
	delayed rom 02
	jsb sqrt_sub
L5116:	b exchange c[w]
	a exchange b[w]
	register -> c 15
	a exchange c[w]
	delayed rom 05
	jsb L2543
	0 -> a[s]
	if c[xs] # 0
	  then go to L5227
	a exchange b[w]
	go to L5223

L5131:	delayed rom @13
	jsb trc10
	a exchange c[w]
	0 -> c[w]
L5135:	delayed rom 06
	jsb L3262
L5137:	b exchange c[w]
	delayed rom @13
	jsb trc10
	c + c -> c[w]
	shift right c[w]
	b exchange c[w]
	if 0 = s 10
	  then go to L5160
	jsb L5340
	b exchange c[w]
	a exchange c[w]
	a - c -> c[w]
	a exchange c[w]
	b exchange c[w]
	0 -> c[w]
	jsb L5343
	0 -> a[s]
L5160:	if 0 = s 7
	  then go to L5164
	jsb L5340
	a + b -> a[w]
L5164:	0 -> c[s]
	if 1 = s 12
	  then go to L5202
	c + 1 -> c[x]
	c + 1 -> c[x]
	delayed rom 05
	jsb L2506
	0 -> a[s]
	if 1 = s 14
	  then go to L5202
	a -> b[w]
	shift right b[w]
	a - b -> a[w]
	jsb L5343
L5202:	delayed rom 05
	jsb L2671
	if 1 = s 13
	  then go to done_x10
	stack -> a
	c -> stack
	a exchange c[w]
	0 -> c[s]
done_x10:
	delayed rom 00
	go to done

L5214:	if c[x] = 0
	  then go to L5021
	a exchange b[w]
L5217:	if 1 = s 6
	  then go to error_x1
	if 0 = s 13
	  then go to L5223
L5223:	delayed rom 05
	jsb L2502
	0 -> a[s]
	jsb togs10
L5227:	p <- 12
	m1 exchange c
	m1 -> c
	0 -> c[ms]
L5233:	c + 1 -> c[x]
	if c[x] = 0
	  then go to L5244
	c + 1 -> c[s]
	p - 1 -> p
	if p # 6
	  then go to L5233
	m1 -> c
	go to L5137

L5244:	m1 exchange c
	0 -> c[w]
	c + 1 -> c[s]
	shift right c[w]
	go to L5265

L5251:	a exchange c[w]
	m1 exchange c
	c + 1 -> c[p]
	c -> a[s]
	m1 exchange c
L5256:	shift right b[w]
	shift right b[w]
	a - 1 -> a[s]
	if n/c go to L5256
	0 -> a[s]
	a + b -> a[w]
	a exchange c[w]
L5265:	a -> b[w]
	a - c -> a[w]
	if n/c go to L5251
	m1 exchange c
	c + 1 -> c[s]
	m1 exchange c
	a exchange b[w]
	shift left a[w]
	p - 1 -> p
	if p # 6
	  then go to L5265
	b exchange c[w]
	delayed rom 05
	jsb L2506
	go to L5305

L5304:	shift right a[wp]
L5305:	a - 1 -> a[s]
	if n/c go to L5304
	0 -> a[s]
	0 -> c[x]
	m1 exchange c
	p <- 7
L5313:	b exchange c[w]
	jsb L5344
	b exchange c[w]
	go to L5320
L5317:	a + b -> a[w]
L5320:	c - 1 -> c[p]
	if n/c go to L5317
	shift right a[w]
	0 -> c[p]
	if c[m] = 0
	  then go to L5135
	p + 1 -> p
	go to L5313

togs10:	if 1 = s 10		; toggle s 10
	  then go to clrs10
	1 -> s 10
	return
clrs10:	0 -> s 10
	return

L5336:	shift right a[w]
L5337:	c + 1 -> c[x]
L5340:	if c[x] # 0
	  then go to L5336
	return

L5343:	select rom 03 (L1744)

L5344:	0 -> c[w]
	c - 1 -> c[w]
	0 -> c[s]
	if p = 12
	  then go to L5365
	if p = 11
	  then go to L5406
	if p = 10
	  then go to L5414
	if p = 9
	  then go to L5774
	if p = 8
	  then go to L5551
	p <- 0
L5362:	load constant 7
	p <- 7
	return

L5365:	p <- 10
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
	go to L5441

L5402:	load constant 6		; fill word to end with sixes
	if p = 0
	  then go to L5362
	go to L5402

L5406:	p <- 8
	jsb L5402
	p <- 4
	load constant 8
	p <- 11
	return

L5414:	p <- 6
	jsb L5402
	p <- 0
	load constant 9
	p <- 10
	return

trc10:	p <- 12
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
	load constant 5
L5441:	p <- 12
	return

L5443:	1 -> s 13
	1 -> s 6
	1 -> s 10
	stack -> a
	a exchange c[w]
L5450:	if c[m] # 0
	  then go to L5453
	0 -> c[w]
L5453:	0 -> a[w]
	0 -> b[w]
	a exchange c[m]
	if c[s] = 0
	  then go to L5465
	1 -> s 7
	if 1 = s 10
	  then go to L5464
	1 -> s 4
L5464:	0 -> c[s]
L5465:	b exchange c[w]
	if 1 = s 12
	  then go to L5665
	if 0 = s 14
	  then go to L5476
	a exchange c[w]
	c -> a[w]
	shift right c[w]
	a - c -> a[w]
L5476:	jsb L5623
	b exchange c[w]
	c - 1 -> c[x]
	if c[xs] # 0
	  then go to L5507
	c - 1 -> c[x]
	if n/c go to L5507
	c + 1 -> c[x]
	shift right a[w]
L5507:	b exchange c[w]
L5510:	m1 exchange c
	m1 -> c
	c + c -> c[w]
	c + c -> c[w]
	c + c -> c[w]
	shift right c[w]
	b exchange c[w]
	if c[xs] # 0
	  then go to L5540
	delayed rom 07
	jsb L3467
	0 -> c[w]
	b exchange c[w]
	m1 -> c
	c + c -> c[w]
	shift left a[w]
	if 0 = s 12
	  then go to L5534
	shift right a[w]
	shift right c[w]
L5534:	b exchange c[w]
L5535:	a - b -> a[w]
	if n/c go to L5722
	a + b -> a[w]
L5540:	b exchange c[w]
	m1 -> c
	b exchange c[w]
	if 0 = s 12
	  then go to L5570
	if c[x] # 0
	  then go to L5567
	shift left a[w]
	go to L5570

L5551:	p <- 2
	jsb L5402
	p <- 8
	return

L5555:	register -> c 8
	delayed rom 05
	jsb L2422
	delayed rom @11
	go to L4676

L5562:	a exchange b[w]
	a - b -> a[w]
	delayed rom @12
	jsb togs10
	go to L5575

L5567:	c + 1 -> c[x]
L5570:	if c[xs] # 0
	  then go to L5577
	a - b -> a[w]
	if n/c go to L5562
	a + b -> a[w]
L5575:	delayed rom 05
	jsb L2745
L5577:	0 -> a[s]
	if 1 = s 12
	  then go to L5614
	b exchange c[w]
	m1 -> c
	b exchange c[w]
	delayed rom 05
	jsb L2506
	0 -> a[s]
	m1 exchange c
	jsb trc10
	delayed rom 05
	jsb L2426
L5614:	c - 1 -> c[x]
	m1 exchange c
	m1 -> c
	c + 1 -> c[x]
	if n/c go to L5633
	shift left a[w]
	go to L5635

L5623:	0 -> c[w]
	p <- 12
	load constant 4
	load constant 5
	go to L5441

L5630:	p - 1 -> p
	if p = 6
	  then go to L5676
L5633:	c + 1 -> c[x]
	if n/c go to L5630
L5635:	0 -> c[w]
	b exchange c[w]
L5637:	delayed rom @12
	jsb L5344
	b exchange c[w]
	delayed rom 07
	jsb L3661
	if p # 6
	  then go to L5637
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
	go to L5754

L5661:	go to L5670

L5662:	1 -> s 7
	go to L5535

L5664:	select rom 04 (L2265)

L5665:	jsb trc10
	go to L5510

	nop

L5670:	0 -> c[w]
	0 -> a[w]
	a + 1 -> a[p]
L5673:	delayed rom 05
	jsb L2671
	go to done_x11

L5676:	p <- 12
	m1 -> c
	if 1 = s 10
	  then go to L5664
	if 0 = s 13
	  then go to L5673
	b exchange c[w]
	register -> c 15
	delayed rom 07
	jsb L3404
	c -> stack
	register -> c 15
	a exchange b[w]
	delayed rom 05
	jsb L2417
L5715:	if 0 = s 4
	  then go to done_x11
	0 - c - 1 -> c[s]
done_x11:
	delayed rom 00
	go to done

L5722:	if 0 = s 10
	  then go to L5733
	0 -> s 10
L5725:	if 1 = s 4
	  then go to L5731
	1 -> s 4
	go to L5535

L5731:	0 -> s 4
	go to L5535

L5733:	1 -> s 10
	if 0 = s 6
	  then go to L5725
	if 0 = s 7
	  then go to L5662
	0 -> s 7
	go to L5535

L5742:	shift right a[wp]
	shift right a[wp]
L5744:	a - 1 -> a[s]
	if n/c go to L5742
	0 -> a[s]
	m1 exchange c
	a exchange c[w]
	a - c -> c[w]
	a + b -> a[w]
	m1 exchange c
L5754:	a -> b[w]
	c -> a[s]
	c - 1 -> c[p]
	if n/c go to L5744
	a exchange c[w]
	shift left a[m]
	a exchange c[w]
	if c[m] = 0
	  then go to L5771
	c - 1 -> c[s]
	0 -> a[s]
	shift right a[w]
	go to L5754

L5771:	delayed rom 02
	go to L1336

	nop

L5774:	p <- 4
	jsb L5402
	p <- 9
	return

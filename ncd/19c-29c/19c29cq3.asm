; 19c/29c ROM disassembly - part two
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$
;

	.arch woodstock

; External references:
L0004	.equ	@0004
incpc	.equ	@0017
L0040	.equ	@0040
L0053	.equ	@0053
L0055	.equ	@0055
L0061	.equ	@0061
L0062	.equ	@0062
L0063	.equ	@0063
L0067	.equ	@0067
L0070	.equ	@0070
L0101	.equ	@0101

L1367	.equ	@1367
S1372	.equ	@1372
L1374	.equ	@1374
L1375	.equ	@1375
L1376	.equ	@1376
L1400	.equ	@1400
L1401	.equ	@1401

S2235	.equ	@2235
L2260	.equ	@2260
L2313	.equ	@2313
S2363	.equ	@2363
divax0	.equ	@2415
S2436	.equ	@2436
L2471	.equ	@2471
L2472	.equ	@2472
L2545	.equ	@2545
L2612	.equ	@2612
L2632	.equ	@2632
S3000	.equ	@3000	; reciprocal
percent	.equ	@3026	; percent
S3036	.equ	@3036	; multiply
mulax	.equ	@3037
S3115	.equ	@3115
S3117	.equ	@3117	; divide
addax	.equ	@3173	; add
S3237	.equ	@3237
S3261	.equ	@3261
L3335	.equ	@3335
L3344	.equ	@3344
L3472	.equ	@3472
L3545	.equ	@3545
L4036	.equ	@4036	; logs (natural or base 10)
L4350	.equ	@4350	; rect to polar
L4400	.equ	@4400	; inv trig
trc10	.equ	@5042	; load pi/4
L5063	.equ	@5063	; polar to rect
L5070	.equ	@5070	; trig
L5736	.equ	@5736	; set angle mode
L5750	.equ	@5750	; pause


; Entry points from model-specific part:
;	L6021
;	L6303 - reset
;	L7201 - (19c only)
;	L7253 - (19c only)
;	L7316 - (19c only) print sixbit message
;	L7352 - (19c only)

; Entry points from math ROM:
;	L6171
;	L6546

	.org @6000	; bank 0

; addr 6000: dispatch table for 0x0x..0xfx
        go to L6034	; 0x00..0x0f
        go to L6030	; 0x10..0x1f
        go to L6034	; 0x20..0x2f
        go to L6034	; 0x30..0x3f

        a + 1 -> a[xs]	; 0x40..0x4f
        a + 1 -> a[xs]	; 0x50..0x5f
        legal go to L6032	; 0x60..0x6f
        go to op_gsb	; 0x70..0x7f GSB
        go to op_gto	; 0x80..0x8f GTO
        go to op_rcl	; 0x90..0x9f RCL
        go to op_sto	; 0xa0..0axf STO
        go to op_sto_minus	; 0xb0..0xbf STO minus
        go to op_sto_plus	; 0xc0..0xcf STO plus
        go to op_sto_times	; 0xd0..0xdf STO times
        go to op_sto_divide	; 0xe0..0xef STO divide

L6017:  delayed rom @00	; 0xf0..0xff LBL
        go to L0061

L6021:  m1 -> c
        c -> a[x]
        0 -> a[xs]
        b -> c[w]
        p <- 12
        0 -> s 11
        a -> rom address

L6030:  delayed rom @16
        go to L7163

L6032:  delayed rom @16
        go to L7041

L6034:  decimal
        shift left a[x]
        delayed rom @15
        a -> rom address

op_gsb: 1 -> s 8
op_gto: p <- 1
        a exchange c[w]
        load constant 15
L6044:  p <- 1
        0 -> a[w]
L6046:  c -> a[wp]
        if a[s] # 0
          then go to L6057
        shift left a[w]
        shift left a[w]
        c -> a[wp]
        shift left a[w]
        shift left a[w]
        go to L6046

L6057:  m2 -> c
        if c[x] # 0		; compare to code @6110 in 67/97
          then go to L6064
        delayed rom @00
        jsb incpc
L6064:  p <- 1
L6065:  p - 1 -> p
        p - 1 -> p
        c - 1 -> c[xs]
        if n/c go to L6065
        c -> data address
        b exchange c[w]
        data -> c
        b exchange c[w]
        a exchange b[w]
L6076:  if a >= b[p]		; is the byte a[p:p-1] a label?
          then go to L6153	;   yes
L6100:  p + 1 -> p		; no, advance byte position (toward left)
        p + 1 -> p
        if p # 0		; end of word?
          then go to L6076	;   no, look at next byte
        go to L6141		;   yes, advance to next word

L6105:  c -> data address	; get word addressed by c into a
        a exchange c[w]
        data -> c
        a exchange c[w]
        if a[w] # 0		; is word all zero?
          then go to L6114	;   no, check for label
        go to L6141		;   yes, advance to next word

L6114:  p <- 1			; unrolled byte tests
        if a >= b[p]
          then go to L6153
        p <- 3
        if a >= b[p]
          then go to L6153
        p <- 5
        if a >= b[p]
          then go to L6153
        p <- 7
        if a >= b[p]
          then go to L6153
        p <- 9
        if a >= b[p]
          then go to L6153
        p <- 11
        if a >= b[p]
          then go to L6153
        p <- 13
        if a >= b[p]
          then go to L6153

L6141:  p <- 0			; advance to next word
        c - 1 -> c[p]		; decrement word address
        if n/c go to L6105	; if addr >= 0, resume search
        if 1 = s 6		; second pass?
          then go to $error	;   yes, label search failed
        load constant 13	; no, start second pass
        1 -> s 6
        go to L6105

L6151:  p + 1 -> p
        go to L6100

L6153:  p - 1 -> p		; possible label match
        a - b -> a[p]
        if a[p] # 0
          then go to L6151

L6157:  c + 1 -> c[xs]		; label found
        p - 1 -> p
        p - 1 -> p
        if p # 12
          then go to L6157
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        decimal
        0 - c - 1 -> c[xs]
L6171:  c -> a[w]
        m2 -> c
        if 0 = s 8		; GSB?
          then go to L6214	;   no

        a exchange c[w]
        p <- 11
        shift left a[wp]
        shift left a[wp]
        shift left a[wp]
        a exchange c[w]
        if 1 = s 2
          then go to L6214
        1 -> s 2
        if 1 = s 1
          then go to L6214
L6210:  0 -> s 15
        if 1 = s 15
          then go to L6210
        0 -> c[w]

L6214:  a exchange c[x]		; GTO
        m2 exchange c
        delayed rom @00
        go to L0055

op_sto_divide:
        jsb S6264
        delayed rom @05
        jsb divax0
        go to L6230

op_sto_minus:
        jsb S6264
        0 - c - 1 -> c[s]
L6226:  delayed rom @06
        jsb addax
L6230:  delayed rom @05
        jsb S2436
        if 1 = s 11
          then go to $error
        go to L6244

op_sto_plus:
        jsb S6264
        go to L6226

op_sto_times:
        jsb S6264
        delayed rom @06
        jsb mulax
        go to L6230

op_sto: jsb S6264
L6244:  c -> data
        delayed rom @00
        go to L0061

op_rcl: jsb S6264
        if 0 = s 9
          then go to L6253
        c -> stack
L6253:  a exchange b[w]
L6254:  p <- 1
        load constant 1
        c -> data address
        register -> c 15
        jsb S6352
        c -> register 15
        delayed rom @00
        go to L0067

S6264:  if 1 = s 11
          then go to L6271
        m1 -> c
        p <- 1
        0 -> c[p]
L6271:  c -> data address
        data -> c
        a exchange b[w]
        a exchange c[w]
        decimal
        0 -> s 11
        return

L6300:  0 -> c[w]
        m2 exchange c
        go to L6017

; reset entry point

L6303:  hi i'm woodstock	; nop?
        0 -> c[w]
        m1 exchange c
        0 -> c[w]
        m2 exchange c
        clear status
        binary
        delayed rom @04
        jsb S2235		; get status register into C
        c -> a[w]		; save into A
        jsb S6360		; get cold start constant into C
        a - c -> a[m]
        if a[m] # 0		; match?
          then go to L6334	;   no, need cold start
        p <- 0
        0 -> c[p]
        jsb S6352
        c -> register 14
        0 -> c[x]
        p <- 1
        load constant 1
        c -> data address
        clear data registers
        delayed rom @00
        go to L0061

L6334:  0 -> c[w]		; cold start
        p <- 1
        load constant 3
        p <- 1
        delayed rom @02
        jsb S1372		; clear registers from 0x2f..0x00
        0 -> c[w]
        jsb S6360		; get cold start constant into C
        p <- 2
        load constant 2
        jsb S6352		; select RAM chip 0x20
        c -> register 14	; write status register
        delayed rom @02
        go to L1374		; error exit

S6352:  a exchange c[w]		; select RAM chip 0x20
        p <- 1
        load constant 2
        c -> data address
        a exchange c[w]
        return

S6360:  p <- 12			; get cold start constant in c
        load constant 3
        load constant 4
        load constant 9
        load constant 3
        load constant 4
        load constant 2
        load constant 8
        load constant 4
        return

        nop
        nop
        nop
        nop
        nop
        nop

        go to stop		; 0x00 = R/S
        go to enter		; 0x01 = ENTER^
        go to $chs		; 0x02 = CHS
        go to $eex		; 0x03 = EEX
        go to clx		; 0x04 = CLx
        go to clrreg		; 0x05 = CLEAR REGS
        go to clrsig		; 0x06 = CLEAR SIGMA

        1 -> s 8		; 0x07 = GSB i
        1 -> s 10		; 0x08 = GTO i
        go to indir		; 0x09 = RCL i
        go to indir		; 0x0a = STO i
        go to indir		; 0x0b = STO - i
        go to indir		; 0x0c = STO + i
        go to indir		; 0x0d = STO * i
        go to indir		; 0x0e = STO / i

        delayed rom @06		; 0x0f = RCL Sigma
        go to L3335

square: delayed rom @06
        jsb S3115
done70: delayed rom @00
        go to L0070

abs:    0 -> c[s]
        go to done70

$chs:   delayed rom @17		; chs
        go to chs

$eex:   delayed rom @17		; eex
        go to L7646

        delayed rom @00
        go to L0101

L6435:  delayed rom @02
        go to L1375

        nop

        go to tohms	; 0x20 = ->HMS
        go to int	; 0x21 = INT
        go to sqrt	; 0x22 = sqrt
        go to L6512	; 0x23 = y^x
        go to sin	; 0x24 = sin
        go to cos	; 0x25 = cos
        go to tan	; 0x26 = tan
        go to L6517	; 0x27 = ln
        go to L6516	; 0x28 = log
        go to L6510	; 0x29 = ->R
        go to lastx	; 0x2a = LASTx
        go to L6555	; 0x2b = x<=y
        go to L6560	; 0x2c = x>y
        go to L6544	; 0x2d = x!=y
        go to L6537	; 0x2e = x=y
        go to L6435	; 0x2f = spare
        go to toh	; 0x30 = ->H
        go to frac	; 0x31 = FRAC
        go to square	; 0x32 = x^2
        go to abs	; 0x33 = ABS
        go to arcsin	; 0x34 = arcsin
        go to arccos	; 0x35 = arccos
        go to arctan	; 0x36 = arctan
        go to L6504	; 0x37 = e^x
        go to L6577	; 0x38 = 10^x
        go to L6506	; 0x39 = ->P
        go to pi	; 0x3a = pi
        go to L6566	; 0x3b = x<0
        go to L6567	; 0x3c = x>0
        go to L6546	; 0x3d = x!=0
        go to L6541	; 0x3e = x=0

        delayed rom @03	; 0x3f = spare
        go to L1400

sqrt:   delayed rom @06
        jsb S3261
        go to done70

L6504:  delayed rom @07		; e^x
        go to L3472

L6506:  delayed rom @10		; ->P
        go to L4350

L6510:  delayed rom @12		; ->R
        go to L5063

L6512:  stack -> a
        c -> stack
        a exchange c[w]
        1 -> s 10
L6516:  1 -> s 6		; log base 10
L6517:  1 -> s 8		; natural log
        delayed rom @10
        go to L4036

cos:    1 -> s 10
sin:    1 -> s 6
tan:    delayed rom @12
        go to L5070

clrsig: 0 -> c[w]
        c -> data address
        c -> register 10
        c -> register 11
        c -> register 12
        c -> register 13
        c -> register 14
        c -> register 15
        go to L6553

L6537:  y -> a			; test X equal to Y?
        a - c -> c[w]
L6541:  if c[w] = 0		; test X equal to zero?
          then go to L6553
        go to L6550

L6544:  y -> a			; test X not equal to Y?
        a - c -> c[w]
L6546:  if c[w] # 0		; test X not equal to zero? (also part of ISZ/DSZ)
          then go to L6553
L6550:  delayed rom @00		; advance PC
        jsb incpc
        0 -> s 11
L6553:  delayed rom @00		; back to main loop
        go to L0061

L6555:  y -> a
        1 -> s 13
        go to L6562

L6560:  y -> a
        a exchange c[w]
L6562:  0 - c - 1 -> c[s]
        delayed rom @06
        jsb addax
        go to L6567

L6566:  0 - c - 1 -> c[s]
L6567:  if c[m] # 0
          then go to L6574
        if 1 = s 13
          then go to L6553
        go to L6550

L6574:  if c[s] = 0
          then go to L6553
        go to L6550

L6577:  1 -> s 8		; 10^x
        delayed rom @07
        go to L3545

arccos: 1 -> s 10
arcsin: 1 -> s 6
arctan: 1 -> s 13
        delayed rom @11
        go to L4400

int:    jsb S6741
        0 -> c[wp]
        a exchange c[x]
        go to done70

frac:   jsb S6741
        0 -> a[x]
        delayed rom @06
        jsb S3237
        c - 1 -> c[x]
        a exchange c[m]
        go to done70

indir:  0 -> c[w]		; indirect operations - get R0
        binary
        c -> data address
        data -> c
        p <- 12			; shift mantissa right eight digits
L6627:  p - 1 -> p
        shift right c[m]
        if p # 4
          then go to L6627
        if c[xs] = 0		; negative exponent?
          then go to L6636
        0 -> c[w]		;   yes, underflow to zero
L6636:  if 1 = s 10		; GTO or GSB?
          then go to L6767	;   yes
        jsb chk2dg		; check for two digit number
        c -> a[m]		; check for reg # too large
        load constant 3
        load constant 0
        if a >= c[m]
          then go to $error
        go to L6651

L6647:  binary
        c + 1 -> c[x]
L6651:  decimal			; convert decimal reg # in A to binary in C
        a - 1 -> a[m]
        if n/c go to L6647
        1 -> s 11
        delayed rom @14
        a -> rom address

chk2dg: if c[x] = 0		; check for range 0-99, adjust
          then go to L6666
        c - 1 -> c[x]
S6662:  if c[x] = 0
          then go to L6667
$error: delayed rom @02
        go to L1374

L6666:  shift right c[m]
L6667:  return

L6670:  shift right c[m]
        jsb S6662
        shift right c[w]
        shift right c[w]
        c - 1 -> c[xs]
        shift right c[w]
        delayed rom @14
        go to L6044

stop:   delayed rom @00
        go to L0040

tohms:  1 -> s 8		; ->HMS
toh:    delayed rom @06		; ->H
        go to L3344

clrreg: delayed rom @00
        go to L0004

enter:  b -> c[w]
        c -> stack
L6711:  0 -> s 9
        delayed rom @00
        go to L0062

lastx:  jsb S6724		; Last X
        p <- 1
        load constant 1
        c -> data address
        register -> c 15
L6721:  b exchange c[w]
        delayed rom @14
        go to L6254

S6724:  if 0 = s 9
          then go to L6727
        c -> stack
L6727:  return

pi:     jsb S6724
        delayed rom @12		; get pi/4
        jsb trc10
        c + c -> c[w]
        c + c -> c[w]
        shift right c[w]
        c + 1 -> c[m]
        0 -> c[x]
        go to L6721

S6741:  c -> a[w]
        if c[xs] = 0
          then go to L6746
        c + 1 -> c[x]
        return

L6746:  c + 1 -> c[x]
L6747:  if c[x] = 0
          then go to L6756
        c - 1 -> c[x]
        shift left a[m]
        p - 1 -> p
        if a[m] # 0
          then go to L6747
L6756:  return

clx:    if 0 = s 12
          then go to L6762
        1 -> s 14
L6762:  delayed rom @04
        jsb S2235
        0 -> c[w]
        c -> register 15
        go to L6711

L6767:  if c[s] = 0		; indirect GTO or GSB
          then go to L6670
        jsb chk2dg
        shift right c[w]
        shift right c[w]
        shift right c[w]
        b exchange c[w]
        m2 -> c
        delayed rom @04
        jsb S2363
        rotate left a
        rotate left a
        0 -> a[xs]
        b exchange c[w]
        decimal
        delayed rom @04
        go to L2313

        delayed rom @00
        go to L0101

        delayed rom @00
        go to L0067

S7014:  a exchange c[x]
        c -> a[w]
        p <- 0
        load constant 10
        decimal
        if a >= c[x]
          then go to L7025
        b -> c[w]
        return

L7025:  shift left a[w]
        b -> c[w]
        a -> rom address

sigmap: delayed rom @05
        go to L2472

        go to L7070		; 0x1a = decimal
        go to sub		; 0x1b = minus
        go to add		; 0x1c = plus
        go to mult		; 0x1d = times
        go to divide		; 0x1e = divide

        delayed rom @03		; 0x1f = spare???
        go to L1401

L7041:  jsb S7014
        delayed rom @04
        jsb S2235
        p <- 13
        load constant 3
L7046:  c - 1 -> c[s]
        a - 1 -> a[xs]
        if n/c go to L7046
        shift left a[x]
        shift left a[x]
        a exchange c[xs]
        c -> register 14
        b exchange c[w]
L7056:  delayed rom @15
        go to L6721

xexchy: stack -> a
        c -> stack
        a exchange c[w]
        go to L7056

L7064:  delayed rom @04		; x bar
        go to L2260

L7066:  delayed rom @05		; s
        go to L2545

L7070:  delayed rom @17		; decimal
        go to L7627

rtn:    b exchange c[w]		; return
        m2 -> c
        if 1 = s 1
          then go to L7100
        if 0 = s 2
          then go to L6300
L7100:  0 -> c[s]
        shift right c[w]
        shift right c[w]
        shift right c[w]
        if c[w] # 0
          then go to L7755
L7106:  delayed rom @00
        go to L0053

pause:  delayed rom @13
        go to L5750

        go to xexchy		; 0x4a = x exchange y
        go to rolldn		; 0x4b = roll down
        go to L7161		; 0x4c = spare
        go to L7142		; 0x4d = spare
        go to sigmap		; 0x4e = Sigma+
        go to setang		; 0x4f = DEG

mult:   delayed rom @06
        jsb S3036
        go to don70b

percent_x:
        delayed rom @06
        go to percent

divide: decimal
        b -> c[w]
        delayed rom @06
        jsb S3117
        go to don70b

        go to L7064		; 0x5a = x bar
        go to L7066		; 0x5b = s
        go to pause		; 0x5c = PAUSE
        nop			; 0x5d = spare
        go to sigmam		; 0x5e = Sigma-
        go to setang		; 0x5f = RAD

sigmam: delayed rom @05
        go to L2471

L7142:  delayed rom @02
        go to L1376

sub:    0 - c - 1 -> c[s]
add:    stack -> a
        delayed rom @06
        jsb addax
don70b: delayed rom @00
        go to L0070

        go to percent_x		; 0x6a = percent
        go to recip		; 0x6b = 1/x
        1 -> s 13		; 0x6c = DSZ
        go to isz		; 0x6d = ISZ
        go to rtn		; 0x6e = RTN

setang: delayed rom @13		; 0x6f = GRD (DEG and RAD jump here as well)
        go to L5736

L7161:  delayed rom @02
        go to L1367

L7163:  jsb S7014
        delayed rom @17
        go to L7400

rolldn: down rotate
        go to L7056

recip:  delayed rom @06
        jsb S3000
        go to don70b

isz:    0 -> c[w]		; isz, or dsz if s13=1
        c -> data address
        data -> c
        a exchange c[w]
        delayed rom @05
        go to L2612

L7201:	b exchange c[w]
        binary
        0 -> c[w]
        p <- 13
        load constant 2
        load constant 3
        b exchange c[w]
        p <- 0
        go to L7214

L7212:  shift right b[m]
        a - 1 -> a[p]
L7214:  if a[p] # 0
          then go to L7212
        p <- 1
        a + 1 -> a[p]
        if n/c go to L7244
L7221:  p <- 12
        shift right b[wp]
L7223:  p - 1 -> p
        if b[p] = 0
          then go to L7223
        shift right a[wp]
        a exchange c[w]
        load constant 7
        a exchange c[w]
        p <- 12
L7233:  if b[p] = 0
          then go to L7236
        return

L7236:  a + 1 -> a[p]
        if n/c go to L7241
        a + 1 -> a[p]
L7241:  a - 1 -> a[p]
        p - 1 -> p
        go to L7233

L7244:  a - 1 -> a[p]
        p <- 4
        shift left a[wp]
        b exchange c[w]
        load constant 2
        b exchange c[w]
        go to L7221

; This routine is the 19C equivalent of the 29C routine at S0331
L7253:	p <- 0
        if a[p] # 0
          then go to L7304
        a - 1 -> a[p]
        jsb S7310
        c - 1 -> c[p]
L7261:  b exchange c[w]
        p <- 1
        load constant 2
        c -> data address
        register -> c 15
        a exchange b[p]
L7267:  p - 1 -> p
        0 -> s 3
        pick key?
        if 1 = s 3
          then go to L7303
        if p # 4
          then go to L7267
        p <- 0
        a + 1 -> a[p]
        if n/c go to L7267
        p <- 0
        a exchange b[p]
L7303:  return

L7304:  0 -> a[p]
        jsb S7310
        c + 1 -> c[p]
        if n/c go to L7261
S7310:  p <- 13
L7311:  p - 1 -> p
        if b[p] = 0
          then go to L7311
        b -> c[w]
        return

; Entry point - print sixbit message

L7316:	p <- 2
        display off

L7320:  p + 1 -> p

L7321:  0 -> s 3
        pick print cr?
        if 1 = s 3
          then go to L7346
        c + 1 -> c[s]
        if n/c go to L7321

        if p # 2
          then go to L7320

        pick print cr?
        if 1 = s 3
          then go to L7346

        pick print home?
        if 1 = s 3
          then go to L7340

        go to L7320

L7340:  if 0 = s 8
          then go to L7344
        if 0 = s 10
          then go to L7346
L7344:  delayed rom @05		; display error (don't try to print!)
        go to L2632

L7346:  p <- 13
        0 -> s 3
        load constant 15
        return

; 19C keyboard dispatch - PICK keycode in C[2:1]
L7352:	decimal
        p <- 1
        0 - c - 1 -> c[xs]
        c - 1 -> c[xs]
        c -> a[xs]
        if c[p] = 0
          then go to L7762
        c - 1 -> c[p]
        if c[p] = 0
          then go to L7367
        c + c -> c[p]
        if n/c go to L7375
        load constant 1
L7367:  p <- 2
        load constant 8
        binary
        a + c -> a[xs]
L7373:  delayed rom @17
        go to L7762

L7375:  load constant 1
        go to L7373

        nop

L7400:  if 1 = s 12
          then go to L7417
L7402:  if 0 = s 9
          then go to L7405
        c -> stack
L7405:  1 -> s 9
        0 -> c[w]
        binary
        c - 1 -> c[w]
        0 -> c[s]
        f exchange a[x]
        0 -> a[x]
        f exchange a[x]
        1 -> s 12
        go to L7422

L7417:  jsb S7542
        if 1 = s 4
          then go to L7510
L7422:  p <- 1
L7423:  c + 1 -> c[p]
        if n/c go to L7451
        shift left a[w]
        p + 1 -> p
        if p # 13
          then go to L7423
L7431:  p - 1 -> p
        a exchange c[wp]
L7433:  p - 1 -> p
        c -> a[w]
        c - 1 -> c[wp]
        a exchange c[x]
        if a[m] # 0
          then go to L7465
L7441:  a exchange c[ms]
L7442:  b exchange c[w]
        b -> c[w]
L7444:  jsb S7603
        b -> c[w]
L7446:  jsb S7747
        delayed rom @00
        go to L0063

L7451:  c - 1 -> c[p]
        if p # 3
          then go to L7457
        1 -> s 7
        0 -> c[x]
        go to L7433

L7457:  if 1 = s 7
          then go to L7431
        f exchange a[x]
        a + 1 -> a[x]
        f exchange a[x]
        go to L7431

L7465:  jsb S7467
        go to L7441

S7467:  a exchange b[x]
        decimal
        0 -> a[x]
        f -> a[x]
        a + c -> c[x]
        p <- 12
L7475:  if c[p] # 0
          then go to L7505
        c - 1 -> c[x]
        p - 1 -> p
        if 1 = s 4
          then go to L7475
        shift left a[m]
        go to L7475

L7505:  a exchange b[x]
        binary
        return

L7510:  p <- 0
        a exchange c[p]
        c -> a[w]
        p <- 2
        shift left a[wp]
        p <- 3
        shift right a[wp]
        b -> c[ms]
L7520:  a exchange c[w]
        c -> a[x]
        decimal
        if c[xs] = 0
          then go to L7527
        0 -> c[xs]
        0 - c -> c[x]
L7527:  jsb S7467
        a exchange c[ms]
        delayed rom @05
        jsb S2436
        if p # 13
          then go to L7442
        0 -> s 12
        1 -> s 14
        b exchange c[w]
        b -> c[w]
        go to L7446

S7542:  p <- 1
        binary
        load constant 1
        c -> data address
        register -> c 14
        a exchange c[p]
        f exchange a[x]
        a exchange c[p]
        p <- 13
        if c[s] = 0
          then go to L7601
        c - 1 -> c[s]
        if c[s] # 0
          then go to L7562
L7560:  1 -> s 7
        go to L7601

L7562:  c - 1 -> c[s]
        if c[s] # 0
          then go to L7567
        1 -> s 4
        go to L7560

L7567:  decimal
        c + 1 -> c[s]
        if n/c go to L7575
        1 -> s 4
L7573:  1 -> s 7
        go to L7600

L7575:  c + 1 -> c[s]
        if c[s] = 0
          then go to L7573
L7600:  load constant 9
L7601:  binary
        return

S7603:  if 0 = s 4
          then go to L7607
        p <- 3
        shift left a[wp]
L7607:  f -> a[x]
        binary
        if 0 = s 7
          then go to L7617
        a + 1 -> a[s]
        if 0 = s 4
          then go to L7617
        a + 1 -> a[s]
L7617:  p <- 1
        load constant 1
        c -> data address
        a exchange c[w]
        c -> register 14
        a exchange c[w]
        c -> a[s]
        return

L7627:  if 1 = s 12		; decimal entry
          then go to L7635
        1 -> s 7
        p <- 0
        0 -> a[p]
        go to L7402

L7635:  jsb S7542
        1 -> s 7
        a exchange c[w]
        b -> c[w]
        if 0 = s 4
          then go to L7444
        p <- 3
        shift right a[wp]
        go to L7444

L7646:  if 1 = s 12		; eex
          then go to L7671
        if 0 = s 9
          then go to L7653
        c -> stack
L7653:  1 -> s 9
        0 -> c[w]
        1 -> s 12
        binary
        p <- 12
        load constant 1
        c -> a[w]
        a - 1 -> a[wp]
        0 -> a[x]
        1 -> s 7
        1 -> s 4
        f exchange a[x]
        f -> a[x]
        go to L7442

L7671:  jsb S7542
        a exchange c[w]
        b -> c[w]
        if 1 = s 4
          then go to L7446
        if c[m] = 0
          then go to L7653
        f -> a[x]
        p <- 0
        load constant 8
        p <- 0
        if a >= c[p]
          then go to L7444
        p <- 3
        0 -> a[wp]
        1 -> s 4
        1 -> s 7
        go to L7444

chs:    if 0 = s 12		; chs
          then go to L7732
        jsb S7542
        a exchange c[w]
        b -> c[w]
        decimal
        if 1 = s 4
          then go to L7741
        if c[m] = 0
          then go to L7446
        0 - c - 1 -> c[s]
        b exchange c[s]
        b -> c[s]
        c -> a[s]
        go to L7444

L7732:  if c[m] = 0
          then go to L7737
        0 - c - 1 -> c[s]
        delayed rom @15
        go to L6721

L7737:  delayed rom @00
        go to L0061

L7741:  p <- 3
        shift right a[wp]
        a exchange c[xs]
        0 - c - 1 -> c[xs]
        a exchange c[xs]
        go to L7520

S7747:  p <- 1
        load constant 2
        c -> data address
        b -> c[w]
        c -> register 15
        return

L7755:  m2 exchange c
        if 1 = s 1
          then go to L7106
        delayed rom @00
        go to L0061

L7762:  shift right a[x]
        shift right a[x]
        p <- 1
        c -> a[p]
        shift left a[x]
        0 -> c[x]
        0 -> s 3
        0 -> s 13
        binary
        delayed rom @01
        a -> rom address

        nop
        nop
        nop

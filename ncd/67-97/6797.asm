; 67/97 common ROM disassembly
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

; External references:
clr_reg_x .equ	@0002
getpc	.equ	@0004
incpc	.equ	@0022
incpc9	.equ	@0024
L0026	.equ	@0026
run_stop .equ	@0046
halt	.equ	@0061
L0063	.equ	@0063
L0073	.equ	@0073
L0074	.equ	@0074
L0076	.equ	@0076
L0100	.equ	@0100
op_done_b	.equ	@0102
op_done	.equ	@0103
L0114	.equ	@0114
L0124	.equ	@0124
L0125	.equ	@0125
err0	.equ	@1372
L1373	.equ	@1373
op_prstk .equ	@1374
op_preg	.equ	@1375
L1367	.equ	@1367
op_space .equ	@1400
op_prtx	.equ	@1404

; Entry points
;	S2007
;	S2261
;	S2362
;	$over0
;	incpc0
;	L5616
;       del
;	execute
;	get_reg_3f

; Entry points for bank 1:
;	S3764
;	L3766
;	L3767
;	L3770
;	op_wdata_x
;	L3774
;	L3775

; CRC flags:
buffer_ready  .equ 0
prog_mode     .equ 1
crc_f2        .equ 2    ; purpose unknown
crc_f3        .equ 3    ; not used in 67
crc_f4        .equ 4    ; default function in 67, purpose unknown in 97
merge         .equ 5
pause         .equ 6
crc_f7        .equ 7    ; purpose unknown
crc_f8        .equ 8    ; purpose unknown
motor_on      .equ 9
card_present  .equ 10
write_mode    .equ 11

	.bank 0
	.org @2000	; from ROM/RAM p/n 1818-0550

L2000:  p <- 6
        0 -> c[w]
        load constant 9
        go to L2014

L2004:  if 0 = s 12
          then go to L2000
        0 -> b[w]
S2007:  p <- 1
        load constant 3
        c -> data address
        0 -> s 3
        register -> c 14
L2014:  decimal
        jsb S2137
        if 1 = s 3
          then go to L2023
        p <- 4
        if c[p] # 0
          then go to L2066
L2023:  jsb S2162
        a exchange c[x]
        c -> a[x]
        p <- 5
        if c[p] = 0
          then go to L2060
        p <- 6
        a + 1 -> a[xs]
L2033:  a - 1 -> a[x]
        if n/c go to L2050
        a - 1 -> a[x]
        c - 1 -> c[p]
        if n/c go to L2055
        c - 1 -> c[s]
L2041:  c - 1 -> c[s]
        0 -> c[p]
L2043:  a - 1 -> a[x]
L2044:  a + 1 -> a[x]
        a + c -> a[x]
        a exchange c[x]
        go to L2060

L2050:  a - 1 -> a[x]
        if n/c go to L2053
        go to L2044

L2053:  a - 1 -> a[x]
        if n/c go to L2033
L2055:  c - 1 -> c[p]
        if n/c go to L2043
        go to L2041

L2060:  c + 1 -> c[xs]
        if n/c go to L2063
        0 - c -> c[x]
L2063:  binary
        0 -> s 3
        return

L2066:  p <- 6
        b -> c[x]
        if c[xs] = 0
          then go to L2124
        p <- 12
L2073:  c + 1 -> c[m]
        if c[p] = 0
          then go to L2107
        c - 1 -> c[p]
        c + 1 -> c[x]
        if n/c go to L2073
        jsb S2162
        if 0 = s 3
          then go to L2105
        c - 1 -> c[m]
L2105:  c + 1 -> c[xs]
        if n/c go to L2063
L2107:  c + 1 -> c[x]
        if n/c go to L2004
        jsb S2233
        if 0 = s 3
          then go to L2004
        c - 1 -> c[m]
        if n/c go to L2105
L2116:  if 1 = s 3
          then go to L2105
        jsb S2162
        if 0 = s 3
          then go to L2105
        c + 1 -> c[x]
L2124:  if c[x] = 0
          then go to L2116
        if c[s] = 0
          then go to L2133
        c - 1 -> c[s]
L2131:  c - 1 -> c[x]
        if n/c go to L2124
L2133:  if c[p] = 0
          then go to L2000
        c - 1 -> c[p]
        if n/c go to L2131
S2137:  c -> a[w]
        0 -> c[w]
        p <- 3
        0 -> a[wp]
        p <- 6
        a exchange c[wp]
        c -> a[p]
L2146:  c - 1 -> c[s]
        a - 1 -> a[p]
        if n/c go to L2146
        c -> a[s]
        p <- 12
L2153:  c - 1 -> c[p]
        a - 1 -> a[s]
        if n/c go to L2153
        return

L2157:  c - 1 -> c[s]
        p <- 6
        c + 1 -> c[p]
S2162:  p <- 3
        c -> a[w]
L2164:  c + 1 -> c[s]
        a - 1 -> a[p]
        if n/c go to L2164
        c - 1 -> c[s]
        0 -> s 3
        p <- 12
        a exchange b[wp]
        a -> b[wp]
        if b[m] = 0
          then go to L2232
        if c[s] = 0
          then go to L2232
        0 - c -> c[s]
        c - 1 -> c[s]
        a exchange c[s]
L2203:  0 -> a[p]
        p - 1 -> p
        a - 1 -> a[s]
        if n/c go to L2203
        a + b -> a[m]
        0 -> a[wp]
        a exchange b[w]
        a -> b[s]
        a -> b[x]
        a exchange b[w]
        if a[m] # 0
          then go to L2232
        shift left a[ms]
L2220:  a + 1 -> a[s]
        shift right a[ms]
        1 -> s 3
        if a[xs] # 0
          then go to L2231
        a + 1 -> a[x]
        if a[xs] # 0
          then go to L2157
        go to L2232

L2231:  a + 1 -> a[x]
L2232:  return

S2233:  0 -> s 3
        a exchange b[w]
        a -> b[w]
        a + b -> a[m]
        if n/c go to L2232
        0 -> a[ms]
        go to L2220

L2242:  if a[x] # 0
          then go to L2245
        a + 1 -> a[x]
L2245:  a - 1 -> a[x]
        a - c -> a[x]
        if n/c go to L2257
        p <- 2
        load constant 1
        load constant 0
        load constant 4
        a - c -> a[x]
        if n/c go to L2257
        a - c -> a[x]
L2257:  a + 1 -> a[x]
        a exchange c[x]
L2261:  decimal
        if c[x] = 0
          then go to L2321
        0 -> c[ms]
        c - 1 -> c[x]
        c -> a[w]
        p <- 2
        load constant 2
        load constant 2
        load constant 4
L2273:  a - c -> a[x]
        if n/c go to L2273
        a exchange c[w]
        0 - c -> c[x]
        c - 1 -> c[x]
        a exchange c[x]
        shift left a[w]
        shift left a[w]
        shift left a[w]
        p <- 3
        load constant 7
        go to L2311

L2307:  binary
        a + 1 -> a[x]
L2311:  decimal
        a - c -> a[ms]
        if n/c go to L2307
        a + c -> a[ms]
        shift left a[x]
        a + 1 -> a[xs]
        shift right a[w]
        a exchange c[w]
L2321:  c -> a[w]
        delayed rom @14
        go to L6240

L2324:  p <- 13
        load constant 2
        load constant 3
        load constant 2
        go to L2376

L2331:  1 -> s 7
        jsb S2356
        if 0 = s 3
          then go to L2351
        p <- 1
        load constant 3
        jsb S2356
        if 0 = s 3
          then go to L2351
        0 -> c[x]
        load constant 10
        p <- 0
        0 -> s 7
        jsb S2356
        if 1 = s 3
          then go to L2360
L2351:  m1 exchange c
        b -> c[w]
        m1 exchange c
        delayed rom @14
        go to L6354

S2356:  delayed rom @15
        go to S6716

L2360:  delayed rom @02
        go to L1373

S2362:  decimal
        0 -> c[ms]
        0 -> a[w]
        p <- 1
        if c[p] = 0
          then go to L2412
        c - 1 -> c[p]
        if c[p] = 0
          then go to L2324
        p <- 13
        load constant 1
        load constant 2
L2376:  a exchange c[ms]
        p <- 11
        load constant 7
        p <- 0
L2402:  a - c -> a[ms]
        c - 1 -> c[p]
        if n/c go to L2402
        p <- 11
        load constant 1
L2407:  a - c -> a[ms]
        c - 1 -> c[xs]
        if n/c go to L2407
L2412:  p <- 10
        binary
        a - 1 -> a[wp]
        return

S2416:  if c[m] = 0
          then go to err0_x
        delayed rom @06
        go to S3120

S2422:  delayed rom @06
        go to L3260

S2424:  a exchange c[w]
S2425:  if 0 = s 13
          then go to L2430
S2427:  0 - c - 1 -> c[s]
L2430:  delayed rom @06
        go to addax

; Store register, dealing with overflow if necessary
sto_over:
	jsb $over0
        c -> data
        return

mul_x:  delayed rom @06
        go to mul

$over0: if c[m] # 0
          then go to overf3
        0 -> c[w]
overf3: if c[xs] = 0		; positive exp
          then go to overf4	; zero exp sign, os good
        decimal
        c - 1 -> c[x]		; offset for -100
        c + 1 -> c[xs]
        c - 1 -> c[xs]		; look for 9
        if n/c go to overf1	; bad here
        c + 1 -> c[x]		; unoffset
overf4: return

overf1: p <- 12			; mark as bad news
        c + c -> c[xs]		; too positive or too neg
        if n/c go to overf2	; positive
        0 -> c[w]		; underflow
        go to L2464

overf2: 0 -> c[wp]		; overflow
        c - 1 -> c[wp]		; all 9s
        0 -> c[xs]		; positive exp
        1 -> s 3		; mark as too big or small
L2464:  p <- 13
        return

; select statistical registers (secondary registers
sel_stat_reg:
	p <- 1
        load constant 3
        c -> data address
        return

op_sigma_minus:			; 0x25 Sigma-
	1 -> s 13
op_sigma_plus:			; 0x05 Sigma+
	m2 exchange c
        jsb sel_stat_reg
        register -> c 4
        a exchange c[w]
        m2 -> c
        jsb S2425
        jsb sto_over
        m2 -> c
        c -> a[w]
        jsb mul_x
        a exchange c[w]
        register -> c 5
        jsb S2424
        jsb sto_over
        register -> c 6
        y -> a
        jsb S2424
        jsb sto_over
        y -> a
        a exchange c[w]
        c -> a[w]
        jsb mul_x
        a exchange c[w]
        register -> c 7
        jsb S2424
        jsb sto_over
        y -> a
        m2 -> c
        jsb mul_x
        a exchange c[w]
        register -> c 8
        jsb S2424
        jsb sto_over
        0 -> c[w]
        p <- 12
        c + 1 -> c[p]
        a exchange c[w]
        register -> c 9
        jsb S2424
        jsb sto_over
        0 -> s 3
        delayed rom @00
        go to L0100

op_std_dev:			; 0x23 std dev
	m1 exchange c	
        jsb sel_stat_reg
        0 -> c[w]
        p <- 12
        c + 1 -> c[p]
        a exchange c[w]
        register -> c 9
        jsb S2427
        b exchange c[w]
        b -> c[w]
        m1 exchange c
        if b[m] = 0
          then go to err0_x
        if b[s] = 0
          then go to err0_x
        m2 exchange c
        register -> c 6
L2567:  c -> a[w]
        jsb mul_x
        register -> c 9
        jsb S2416
        register -> c 5
        if 1 = s 13
          then go to L2577
        register -> c 7
L2577:  jsb S2427
        m1 -> c
        jsb S2416
        0 -> c[s]
        jsb S2422
        if 1 = s 13
          then go to L3001
        1 -> s 13
        jsb $over0
        stack -> a
        c -> stack
        register -> c 4
        go to L2567

op_mean:			; 0x22 mean
	b exchange c[w]
        jsb sel_stat_reg
        register -> c 9
        b exchange c[w]
        if b[m] = 0
          then go to err0_x
        m2 exchange c
        register -> c 6
L2624:  a exchange c[w]
        register -> c 9
        jsb S2416
        if 1 = s 13
          then go to L3001
        1 -> s 13
        stack -> a
        c -> stack
        register -> c 4
        go to L2624

;------------------------------------------------------------------
; Start of math package (almost same as 67/97)
;------------------------------------------------------------------

S2636:  0 -> a[w]		; 1/x
        p <- 12
        a + 1 -> a[p]
        if c[m] = 0
          then go to err0_x
        delayed rom @06
        go to L3117

L2645:  0 -> c[w]		; isz, or dsz if ???
        p <- 12
        c + 1 -> c[p]
        a exchange c[w]
        jsb S2424
        jsb sto_over
        if c[xs] = 0
          then go to L2656
        0 -> c[w]
L2656:  delayed rom @15
        go to op_x_ne_0

; increment PC
incpc0: p <- 1			; get PC (reg 3D)
        load constant 3
        c -> data address
        register -> c 13
	
        c - 1 -> c[xs]		; decrement (advance) byte
        if n/c go to incpc8	;   if no underflow, done

        p <- 2			; wrap to byte 6
        load constant 6
	
        p <- 0			; decrement (advance) low nib of addr
        c - 1 -> c[p]		;   if no underflow, done
        if n/c go to incpc8	;   
        load constant 15

        p <- 1			; inspect high nib of addr
        if c[p] = 0		; already zero?  (should never happen?)
          then go to incpc7
        c - 1 -> c[p]		; decrement (advance) high nib of addr
        if c[p] # 0		;   if not zero, done
          then go to incpc8
        1 -> s 3		; set wrap flag
incpc7: load constant 2		; force back to beginning
incpc8: delayed rom @00
        go to incpc9

op_percent:
	y -> a			; percent
        a - 1 -> a[x]		; reduce exponent by 2
        a - 1 -> a[x]
        delayed rom @06
        jsb mulax
L2713:  delayed rom @00
        go to op_done

op_pct_chg:			; 0x24 %CH
	y -> a
        1 -> s 13
        if a[w] # 0
          then go to L2723
        delayed rom @02
        go to err0

L2723:  m2 exchange c		; save Lastx
        m2 -> c
        jsb S2424
        y -> a
        a exchange c[w]
        a + 1 -> a[x]
        a + 1 -> a[x]
        delayed rom @06
        jsb S3120
        go to L2713

        nop
        nop
        nop

xft130: 0 -> c[w]		; part of factorial code, compare L1122 in 27
        c + 1 -> c[p]
        shift right c[w]
        c + 1 -> c[s]
        b exchange c[w]
xft140: if b[p] = 0
          then go to xft150
        shift right b[wp]
        c + 1 -> c[x]
xft150: 0 -> a[w]
        a - c -> a[p]
        if n/c go to xft170
        shift left a[w]
xft160: a + b -> a[w]
        if n/c go to xft160
xft170: a - c -> a[s]
        if n/c go to xft190
        shift right a[wp]
        a + 1 -> a[w]
        c + 1 -> c[x]
xft180: a + b -> a[w]
        if n/c go to xft180
xft190: a exchange b[wp]
        c - 1 -> c[p]
        if n/c go to xft140
        c - 1 -> c[s]
        if n/c go to xft140
        shift left a[w]
        a -> b[x]
        0 -> c[ms]
        a + b -> a[wp]
        a + c -> a[w]
        a exchange c[ms]
L3001:  delayed rom @00
        go to op_done

op_fact:
	p <- 12			; 0x21 n!
        if c[s] # 0
          then go to err0_x
        if c[xs] # 0
          then go to err0_x
        c -> a[w]
xft110: a -> b[w]
        shift left a[ms]
        if a[wp] # 0
          then go to xft120
        jsb save_lastx
        a + 1 -> a[x]
        if a >= c[x]
          then go to xft130
        c + 1 -> c[xs]
        if n/c go to L3001
xft120: a - 1 -> a[x]
        if n/c go to xft110
err0_x: delayed rom @02
        go to err0

mulxy:  stack -> a		; multiply Y
mulax:  jsb save_lastx
mul:    0 -> b[w]		; compare L2415 in 27
        a exchange b[m]
S3033:  jsb S3047
        jsb S3104
S3035:  p <- 12			; compare L2455 in 27
        0 -> b[w]
        a -> b[x]
        a + b -> a[wp]
        if n/c go to L3044
        c + 1 -> c[x]
        a + 1 -> a[p]
L3044:  a exchange c[m]
        c -> a[w]
        return

S3047:  a + c -> c[x]		; compare L2621 in 27
        p <- 3
        a - c -> c[s]
        if n/c go to L3054
        0 - c -> c[s]
L3054:  0 -> a[w]
        go to mpy100

S3056:  p <- 0
        go to L3054

mpy90:  a + b -> a[w]		; add multiplicand to partial product
mpy100: c - 1 -> c[p]
        if n/c go to mpy90
        if p = 12
          then go to L3072
        p + 1 -> p
        shift right a[w]
        go to mpy100

L3070:  c + 1 -> c[x]
        shift right a[w]
L3072:  return

S3073:  a exchange b[w]
S3074:  jsb S3056
        m1 -> c
        go to S3104

S3077:  m1 exchange c		; compare L2654 in 27
        b -> c[w]
        jsb S3056
        m1 -> c
        c + c -> c[x]
S3104:  if a[s] # 0		; compare L2661 in 27
          then go to L3070
        return

save_lastx:
	m2 exchange c
        m2 -> c
        return

S3112:  c -> a[w]		; square
        go to mulax

S3114:  if c[m] = 0		; divide
          then go to err0_x
        stack -> a
L3117:  jsb save_lastx
S3120:  jsb S3122
        go to S3035

S3122:  0 -> b[w]
        b exchange c[m]
S3124:  a - c -> c[s]
        if n/c go to L3127
        0 - c -> c[s]
L3127:  a - c -> c[x]
        0 -> a[x]
        0 -> a[s]
S3132:  0 -> c[m]
        p <- 12
        go to div140

div130: c + 1 -> c[p]
div140: a - b -> a[w]
        if n/c go to div130
        a + b -> a[w]
        p - 1 -> p
        if p # 2
          then go to L3153
        a + 1 -> a[ms]
        b exchange c[x]
        0 -> c[x]
        go to L3151

L3150:  a - 1 -> a[ms]
L3151:  if a >= b[w]
          then go to L3150
L3153:  shift left a[w]
        if p # 13
          then go to div140
        0 -> a[w]
        a exchange c[w]
        a exchange c[s]
        b exchange c[x]
        go to S3235

S3163:  0 -> a[w]
        a + 1 -> a[s]
        0 - c -> c[x]
        shift right a[w]
        go to S3132

addxy:  stack -> a		; add Y
addax:  jsb add
        go to S3035

add:    p <- 12			; add routine
        0 -> b[w]		; zap
        a + 1 -> a[xs]		; offset exp
        a + 1 -> a[xs]		; can handle +- 200 exp
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        if a >= c[x]		; compare exps
          then go to add4
        a exchange c[w]		; smaller in c
add4:   a exchange c[m]		; smaller in am
        if c[m] = 0		; look for zero
          then go to add5
        a exchange c[w]		; smaller in cm, answer exp c
add5:   b exchange c[m]		; smaller in b, extend to 13
add6:   if a >= c[x]		; when exps are equal
          then go to add1
        shift right b[w]	; line up smaller number
        a + 1 -> a[x]		; up smaller exp
        if b[w] = 0		; fall out of b
          then go to add1
        go to add6

add1:   c - 1 -> c[xs]
        c - 1 -> c[xs]
        0 -> a[x]
        a - c -> a[s]
        if a[s] # 0
          then go to add13
        a + b -> a[w]
        if n/c go to S3104
add13:  if a >= b[m]
          then go to add14
        0 - c - 1 -> c[s]
        a exchange b[w]
add14:  a - b -> a[w]

S3235:  p <- 12
        if a[wp] # 0
          then go to L3244
        0 -> c[x]
L3241:  return

L3242:  delayed rom @10
        go to L4015

L3244:  if a[p] # 0
          then go to L3241
        shift left a[wp]
        go to L3242

S3250:  if 0 = s 4
          then go to L3253
        0 - c - 1 -> c[s]
L3253:  jsb S3235
        go to S3035

sqrt:  if c[s] # 0		; square root
          then go to err0_x
        jsb save_lastx
L3260:  0 -> a[w]
        a exchange c[m]
        jsb sqrt_sub
        go to L3253

sqrt_sub:
	a -> b[w]			; compare L1171 in 27
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
sqr30:  c + c -> c[x]
        a + c -> c[x]
        p <- 0
        if c[p] # 0
          then go to sqr50
        shift right b[w]
sqr50:  shift right c[w]
        a exchange c[x]
        0 -> c[w]
        a exchange b[w]
        p <- 13
        load constant 5
        shift right c[w]
        go to sqr100

sqr60:  c + 1 -> c[p]
sqr70:  a - c -> a[w]
        if n/c go to sqr60
        a + c -> a[w]
        shift left a[w]
        p - 1 -> p
sqr100: shift right c[wp]
        if p # 0
          then go to sqr70
        0 -> c[p]
        a exchange c[w]
        b exchange c[w]
        return

op_rcl_sigma:			; 0x0f RCL Sigma
	m2 exchange c
        p <- 1
        load constant 3
        c -> data address
        register -> c 6
        stack -> a
        c -> stack
        register -> c 4
        go to L3001

; H/HMS conversions - to H if s8=0, to HMS if s8=1
hms_conv:  b exchange c[w]
        jsb S3372
        go to L3001

; HMS+
hms_plus:
	jsb save_lastx
        go to L3352

        jsb save_lastx
        0 - c - 1 -> c[s]
L3352:  b exchange c[w]
        jsb S3372
        stack -> a
        c -> stack
        a exchange b[w]
        jsb S3372
        jsb addxy
        delayed rom @05
        jsb $over0
        1 -> s 8
        go to hms_conv

hmsm20: a + c -> a[wp]
        shift right c[wp]
        if c[wp] # 0
          then go to hmsm20
        return

S3372:  if b[m] = 0			; compare L1575 in 27
          then go to hms120
        p <- 12
        b -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
        if c[xs] # 0
          then go to L3450
hms110: p - 1 -> p
        if p # 0
          then go to hms130
hms120:  b -> c[w]
        return

hms130: c - 1 -> c[x]			; compare L1454 in 27
        if n/c go to hms110
hms140: 0 -> c[w]
        b -> c[m]
        if 0 = s 8
          then go to hrs100
        p + 1 -> p
        if p # 13
          then go to hms150
        jsb hmsmp
        go to hms160

hms150: p + 1 -> p			; compare L1467 in 27
        jsb hmsmp
        p - 1 -> p
hms160: p - 1 -> p
        jsb hmsmp
        c -> a[w]
        b -> c[w]
        go to L3446

hrs100: 0 -> a[w]			; compare L1726 in 27
        jsb hmsdv
        p + 1 -> p
        if p = 13
          then go to hrs120
        p + 1 -> p
hrs120: jsb hmsdv
        shift left a[w]
        a + c -> a[w]
        b exchange c[w]
        delayed rom @06
        jsb S3104
L3446:  delayed rom @06
        go to L3253

L3450:  if b[xs] = 0
          then go to hms120
        go to hms140

hmsdv:  shift right c[wp]		; compare L1550 in 27
        a + c -> c[wp]
hmsmp:  c -> a[wp]
        shift right c[wp]
        c + c -> c[wp]
        c + c -> c[wp]
        a - c -> c[wp]
        if 0 = s 8
          then go to hmsm20
        0 -> a[w]
        c -> a[x]
        a + c -> c[w]
        0 -> c[x]
        return

op_e_to_x:
	0 -> a[w]		; e^x
        delayed rom @06
        jsb save_lastx
        a exchange c[m]
L3475:  b exchange c[w]
        delayed rom @10
        jsb lnc10
        b exchange c[w]
        1 -> s 8
        jsb S3575
        b exchange c[w]
L3504:  jsb S3664
        b exchange c[w]
        jsb S3563
        if p # 5
          then go to L3504
        p <- 13
        load constant 7
        a exchange c[s]
        b exchange c[w]
        go to L3521

L3516:  a -> b[w]			; compare L3426 in 27
        c - 1 -> c[s]
        if n/c go to L3535
L3521:  shift right a[wp]
        a exchange c[w]
        shift left a[ms]
        a exchange c[w]
        a - 1 -> a[s]
        if n/c go to L3516
        a exchange b[w]
        a + 1 -> a[p]
        delayed rom @06
        jsb S3250
        go to L3621

L3534:  shift right a[wp]		; eca21? compare L3443 in 27
L3535:  a - 1 -> a[s]			; eca22? compare L3444 in 27
        if n/c go to L3534
        0 -> a[s]
        a + b -> a[w]
        a + 1 -> a[p]
        if n/c go to L3516
        shift right a[wp]
        a + 1 -> a[p]
        if n/c go to L3521

L3546:  a exchange c[w]
        delayed rom @10
        jsb lnc10
        b exchange c[w]
        0 -> c[w]
L3553:  a exchange c[w]
        delayed rom @06
        jsb save_lastx
        delayed rom @06
        jsb S3047
        0 -> c[m]
        go to L3475

L3562:  c + 1 -> c[s]			; compare L3660 in 27
S3563:  a - b -> a[w]
        if n/c go to L3562
        a + b -> a[w]
        shift left a[w]
        shift right c[ms]
        b exchange c[w]
        p - 1 -> p
        return

L3573:  c + 1 -> c[x]			; compare L3465 in 27
        shift right a[w]
S3575:  if c[xs] = 0
          then go to L3636
        if a[s] # 0
          then go to L3573
        0 - c -> c[x]
        if c[xs] = 0
          then go to L3624
        0 -> c[m]
        0 -> a[w]
        c + c -> c[x]
        if n/c go to L3626
L3610:  0 -> c[wp]
        if c[s] # 0
          then go to L3620
        c - 1 -> c[w]
        0 -> c[xs]
        1 -> s 3
        if 1 = s 4
          then go to L3621
L3620:  0 -> c[s]
L3621:  delayed rom @00
        go to op_done

L3623:  shift right a[w]		; compare L3515 in 27
L3624:  c - 1 -> c[x]
        if n/c go to L3623
L3626:  0 -> c[x]
L3627:  if c[s] = 0
          then go to L3634
        a exchange b[w]
        a - b -> a[w]
        0 - c - 1 -> c[x]
L3634:  0 -> c[ms]
        return

L3636:  a exchange c[w]
        shift left a[wp]
        shift left a[wp]
        shift left a[wp]
        a exchange c[w]
        go to L3645

L3644:  c + 1 -> c[x]			; compare L3535 in 27
L3645:  a - b -> a[w]
        if n/c go to L3644
        a + b -> a[w]
        c - 1 -> c[m]
        if n/c go to L3653
        go to L3627

L3653:  a exchange c[w]			; compare L3546 in 27
        shift left a[x]
        a exchange c[w]
        shift left a[w]
        if 0 = s 8
          then go to L3645
        if c[xs] # 0
          then go to L3610
        go to L3645

S3664:  0 -> c[w]			; compare L3557 in 27
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

lncd2:  p <- 7			; ln(1.01)
        jsb load33		; compare lnc50 in -41
        load constant 0
        load constant 8
        load constant 5
        load constant 3
        load constant 1
        load constant 7
        p <- 10
        return

lncd3:  p <- 5			; ln(1.001)
        jsb load33		; compare lnc60 in -41
        load constant 3
        load constant 0
        load constant 8
        load constant 4
        p <- 9
        return

lncd4:  p <- 3			; ln(1.0001)
        jsb load33		; compare lnc70 in -41
        jsb load33
        p <- 8
        return

lncd5:  p <- 1			; ln(1.00001)
        jsb load33		; compare lnc80 in -41
        p <- 7
        return

load33: load constant 3
        load constant 3
        return

lncd1:  p <- 9			; ln(1.1)
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

        nop

; Block of entry points to the model-specific bank 1 ROM

S3764:  bank toggle
        bank toggle		; not used
L3766:  bank toggle
L3767:  bank toggle
L3770:  bank toggle
L3771:	bank toggle		; used only in 97 - key decode

op_wdata_x:
	bank toggle		; WDATA

        bank toggle		; not used
L3774:  bank toggle
L3775:  bank toggle
        bank toggle		; not used


lnc2:   p <- 11			; load ln(2)

	.org @4000	; from ROM/RAM p/n 1818-0551

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

L4015:  binary
        a + 1 -> a[s]
        decimal
        c - 1 -> c[x]
        delayed rom @06
        go to L3244

lnc10:  0 -> c[w]		; ln(10)
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

; logarithm (s6=0 for natural log, s6=1 for log base 10)

L4044:  p <- 12
        if c[w] = 0
          then go to L4173
        if c[s] # 0
          then go to L4213
        delayed rom @06
        jsb save_lastx
L4053:  if c[x] = 0		; compare L3065 in 27
          then go to L4251
        c + 1 -> c[x]
        0 -> a[w]
        a - c -> a[m]
        if c[x] = 0
          then go to L4267
L4062:  shift right a[wp]
        a -> b[s]
        p <- 13
L4065:  p - 1 -> p
        a - 1 -> a[s]
        if n/c go to L4065
        a exchange b[s]
        0 -> c[ms]
        go to L4076

L4073:  shift right a[w]	; compare L3113 in 27
        c + 1 -> c[p]
L4075:  a exchange b[s]
L4076:  a -> b[w]
        binary
        a + c -> a[s]
        m1 exchange c
        a exchange c[s]
        shift left a[w]
L4104:  shift right a[w]
        c - 1 -> c[s]
        if n/c go to L4104
        decimal
        m1 exchange c
        a + b -> a[w]
        shift left a[w]
        a - 1 -> a[s]
        if n/c go to L4073
        c -> a[s]
        a - 1 -> a[s]
        a + c -> a[s]
        if n/c go to L4124
L4121:  a exchange b[w]
        shift left a[w]
        go to L4136

L4124:  if p = 1			; compare L3144 in 27
          then go to L4121
        c + 1 -> c[s]
        p - 1 -> p
        a exchange b[w]
        a exchange b[s]
        shift left a[w]
        go to L4075

L4134:  c - 1 -> c[s]			; compare L3154 in 27
        p + 1 -> p
L4136:  b exchange c[w]
        delayed rom @07
        jsb S3664
        shift right a[w]
        b exchange c[w]
        go to L4145

L4144:  a + b -> a[w]
L4145:  c - 1 -> c[p]
        if n/c go to L4144
        if c[s] # 0
          then go to L4134
        if p = 12
          then go to L4273
        0 -> c[w]
        jsb S4345
L4155:  delayed rom @06
        jsb S3235
        0 -> a[s]
        if 0 = s 7
          then go to L4163
        0 - c - 1 -> c[s]
L4163:  if 1 = s 10
          then go to L4744
        if 1 = s 6		; base 10 log?
          then go to logb10	;   yes, adjust
L4167:  delayed rom @06
        jsb S3035
L4171:  delayed rom @00
        go to op_done

L4173:  if 0 = s 10
          then go to L4202
        stack -> a
        if a[m] # 0
          then go to L4204
L4200:  c -> stack
        a exchange c[w]
L4202:  delayed rom @02
        go to err0

L4204:  if a[s] # 0
          then go to L4200
        a exchange c[w]
        delayed rom @06
        jsb save_lastx
        0 -> c[w]
        go to L4171

L4213:  if 0 = s 10
          then go to L4202
        stack -> a
        a -> b[w]
        if a[xs] # 0
          then go to L4200
        a + 1 -> a[x]
L4222:  a - 1 -> a[x]
        shift left a[ms]
        if a[m] # 0
          then go to L4245
        if a[x] # 0
          then go to L4240
        a exchange c[s]
        c -> a[s]
        c + c -> c[s]
        c + c -> c[s]
        a + c -> c[s]
        if c[s] = 0
          then go to L4241
        1 -> s 4
L4240:  0 -> c[s]
L4241:  b exchange c[w]
        c -> stack
        b exchange c[w]
        go to L4053

L4245:  if a[x] # 0
          then go to L4222
        a exchange b[w]
        go to L4200

L4251:  c -> a[w]
        a - 1 -> a[p]
        if a[m] # 0
          then go to L4257
        0 -> c[w]
        go to L4163

L4257:  delayed rom @06
        jsb S3235
        delayed rom @06
        jsb S3122
        a + c -> a[s]
        a - 1 -> a[s]
L4265:  0 -> c[x]
        go to L4062

L4267:  1 -> s 7
        delayed rom @06
        jsb S3235
        go to L4265

L4273:  if c[x] = 0
          then go to L4155
        c - 1 -> c[w]
        b exchange c[w]
        0 -> b[m]
        jsb lnc10
        a exchange c[w]
        a - c -> c[w]
        if b[xs] = 0
          then go to L4306
        a - c -> c[w]
L4306:  a exchange c[w]
        b exchange c[w]
        if c[xs] = 0
          then go to L4313
        0 - c - 1 -> c[w]
L4313:  a exchange c[wp]
L4314:  p - 1 -> p
        shift left a[w]
        if p # 1
          then go to L4314
        p <- 12
        if a[p] # 0
          then go to L4334
        shift left a[m]
L4324:  a exchange c[w]
        a exchange c[s]
        delayed rom @06
        jsb mpy100
        delayed rom @06
        jsb S3104
        0 -> c[m]
        go to L4163

L4334:  a + 1 -> a[x]
        p - 1 -> p
        go to L4324

logb10: b exchange c[w]		; convert ln result to log base 10
        jsb lnc10
        b exchange c[w]
        delayed rom @06
        jsb S3132
        go to L4167

S4345:  p + 1 -> p
S4346:  c - 1 -> c[x]
        if p # 12
          then go to S4345
        return

op_r_to_p:			; 0x09 R->P: rectangular to polar conversion
	y -> a
        m2 exchange c		; save Lastx
        m2 -> c
        if c[m] = 0
          then go to L4463
        if c[s] = 0
          then go to L4364
        1 -> s 7
        1 -> s 10
        0 -> c[s]
L4364:  delayed rom @06
        jsb S3122
        0 -> a[s]
L4367:  delayed rom @05
        jsb overf3
        0 -> s 3
        if p # 13
          then go to L4467
        if c[w] # 0
          then go to inv_trig
        stack -> a
        m2 -> c
        c -> stack
        0 -> c[w]

; Entry point: inverse trig functions
; s 6 set for arcsin
; s 10 set for arccos
; neither set for arctan

inv_trig:
	0 -> a[w]
        0 -> b[w]
        c -> a[m]
L4405:  if c[s] = 0
          then go to L4417
        1 -> s 4
        if 0 = s 13
          then go to L4417
        if 0 = s 10
          then go to L4417
        0 -> s 10
        1 -> s 7
        0 -> s 4
L4417:  p <- 12
        if c[xs] = 0
          then go to L4616
        jsb S4511
        if 0 = s 6
          then go to L4630
        jsb S4740
        0 -> c[w]
        a -> b[w]
        b exchange c[w]
        shift right a[w]
        a + 1 -> a[p]
        0 - c -> c[wp]
        if n/c go to L4450
        a exchange b[w]
        a exchange c[w]
        delayed rom @06
        jsb S3235
        m1 exchange c
        a exchange c[w]
        delayed rom @06
        jsb S3074
        c - 1 -> c[x]
        delayed rom @06
        jsb sqrt_sub
L4450:  b exchange c[w]
        a exchange b[w]
        m2 -> c
        a exchange c[w]
        delayed rom @06
        jsb S3124
        0 -> a[s]
        if c[xs] # 0
          then go to L4630
        a exchange b[w]
        go to L4624

L4463:  c + 1 -> c[xs]
        a exchange c[s]
        if a[w] # 0
          then go to L4367
L4467:  a exchange b[w]
        stack -> a
        b exchange c[w]
        c -> stack
        b exchange c[w]
        delayed rom @06
        jsb S3077
        delayed rom @13
        jsb S5544
        a exchange b[w]
        a exchange c[w]
        m2 -> c
        delayed rom @06
        jsb S3033
        stack -> a
        c -> stack
        m1 -> c
        go to L4405

S4511:  if 0 = s 13
          then go to L4515
        m2 exchange c		; save Lastx
        m2 -> c
L4515:  return

L4516:  a -> b[w]
        if b[w] = 0
          then go to L4534
        a - 1 -> a[p]
        if a[w] # 0
          then go to L4621
        a exchange c[w]
        if 0 = s 6
          then go to L4532
        jsb toggle_s10
        0 -> c[w]
        go to L4534

L4532:  delayed rom @12
        jsb trc10
L4534:  a exchange c[w]
        jsb S4511
        0 -> c[w]
L4537:  delayed rom @10
        jsb S4346
L4541:  b exchange c[w]
        delayed rom @12
        jsb trc10
        c + c -> c[w]
        shift right c[w]
        b exchange c[w]
        if 0 = s 10
          then go to L4563
        jsb S4741
        b exchange c[w]
        a exchange c[w]
        a - c -> c[w]
        a exchange c[w]
        b exchange c[w]
        0 -> c[w]
        delayed rom @06
        jsb S3235
        0 -> a[s]
L4563:  if 0 = s 7
          then go to L4567
        jsb S4741
        a + b -> a[w]
L4567:  0 -> c[s]
        if 1 = s 0
          then go to L4604
        c + 1 -> c[x]
        c + 1 -> c[x]
        delayed rom @06
        jsb S3132
        0 -> a[s]
        if 1 = s 14
          then go to L4604
        a -> b[w]
        shift right b[w]
        a - b -> a[w]
L4604:  delayed rom @06
        jsb S3250
        if 1 = s 13
          then go to L4171
        stack -> a
        c -> stack
        0 -> a[s]
        a exchange c[w]
        delayed rom @00
        go to op_done

L4616:  if c[x] = 0
          then go to L4516
        a exchange b[w]
L4621:  if 1 = s 6
          then go to L4202
        jsb S4511
L4624:  delayed rom @06
        jsb S3163
        0 -> a[s]
        jsb toggle_s10
L4630:  p <- 12
        m1 exchange c
        m1 -> c
        0 -> c[ms]
L4634:  c + 1 -> c[x]
        if c[x] = 0
          then go to L4645
        c + 1 -> c[s]
        p - 1 -> p
        if p # 6
          then go to L4634
        m1 -> c
        go to L4541

L4645:  m1 exchange c
        0 -> c[w]
        c + 1 -> c[s]
        shift right c[w]
        go to L4666

L4652:  a exchange c[w]
        m1 exchange c
        c + 1 -> c[p]
        c -> a[s]
        m1 exchange c
L4657:  shift right b[w]
        shift right b[w]
        a - 1 -> a[s]
        if n/c go to L4657
        0 -> a[s]
        a + b -> a[w]
        a exchange c[w]
L4666:  a -> b[w]
        a - c -> a[w]
        if n/c go to L4652
        m1 exchange c
        c + 1 -> c[s]
        m1 exchange c
        a exchange b[w]
        shift left a[w]
        p - 1 -> p
        if p # 6
          then go to L4666
        b exchange c[w]
        delayed rom @06
        jsb S3132
        go to L4706

L4705:  shift right a[wp]
L4706:  a - 1 -> a[s]
        if n/c go to L4705
        0 -> a[s]
        0 -> c[x]
        m1 exchange c
        p <- 7
L4714:  b exchange c[w]
        jsb S4750
        b exchange c[w]
        go to L4721

L4720:  a + b -> a[w]
L4721:  c - 1 -> c[p]
        if n/c go to L4720
        shift right a[w]
        0 -> c[p]
        if c[m] = 0
          then go to L4537
        p + 1 -> p
        go to L4714


toggle_s10:			; compare brts10 in 41C
	if 1 = s 10
          then go to clear_s10
        1 -> s 10
        return

clear_s10:
	0 -> s 10
        return


S4737:  shift right a[w]
S4740:  c + 1 -> c[x]
S4741:  if c[x] # 0
          then go to S4737
        return

L4744:  a exchange b[w]
        stack -> a
        delayed rom @07
        go to L3553

S4750:  0 -> c[w]
        c - 1 -> c[w]
        0 -> c[s]
        if p = 12
          then go to L4771
        if p = 11
          then go to L5012
        if p = 10
          then go to L5020
        if p = 9
          then go to L5026
        if p = 8
          then go to L5032
        p <- 0
L4766:  load constant 7
        p <- 7
        return

L4771:  p <- 10
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
        go to L5062

S5006:  load constant 6		; fill word to end with sixes
        if p = 0
          then go to L4766
        go to S5006

L5012:  p <- 8
        jsb S5006
        p <- 4
        load constant 8
        p <- 11
        return

L5020:  p <- 6
        jsb S5006
        p <- 0
        load constant 9
        p <- 10
        return

L5026:  p <- 4
        jsb S5006
        p <- 9
        return

L5032:  p <- 2
        jsb S5006
        p <- 8
        return

S5036:  0 -> c[w]		; load 180/4
        p <- 12
        load constant 4
        load constant 5
        go to L5062

trc10:  p <- 12			; load pi/4
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
L5062:  p <- 12
        return


op_p_to_r:
	1 -> s 13		; polar to rectangular conversion
        1 -> s 6
        1 -> s 10
        stack -> a
        go to L5072

; trigonometric functions (SIN, COS, TAN)
trig:   c -> a[w]
L5072:  m2 exchange c		; save Lastx
        m2 -> c
        a exchange c[w]
        0 -> a[w]		; compare trg100 in 41C
        0 -> b[w]
        a exchange c[m]
        if c[s] = 0
          then go to trg130
        1 -> s 7
        if 1 = s 10
          then go to trg120
        1 -> s 4
trg120: 0 -> c[s]
trg130: b exchange c[w]
        if 1 = s 0
          then go to trg240
        if 0 = s 14
          then go to trg135
        a exchange c[w]
        c -> a[w]
        shift right c[w]
        a - c -> a[w]
trg135: jsb S5036
        b exchange c[w]
        c - 1 -> c[x]
        if c[xs] # 0
          then go to trg140
        c - 1 -> c[x]
        if n/c go to trg140
        c + 1 -> c[x]
        shift right a[w]
trg140: b exchange c[w]
trg150: m1 exchange c
        m1 -> c
        c + c -> c[w]
        c + c -> c[w]
        c + c -> c[w]
        shift right c[w]
        b exchange c[w]
        if c[xs] # 0
          then go to trg180
        delayed rom @07
        jsb S3575
        0 -> c[w]
        b exchange c[w]
        m1 -> c
        c + c -> c[w]
        shift left a[w]
        if 0 = s 0
          then go to trg160
        shift right a[w]
        shift right c[w]
trg160: b exchange c[w]
trg170: a - b -> a[w]
        if n/c go to trg190
        a + b -> a[w]
trg180: b exchange c[w]
        m1 -> c
        b exchange c[w]
        if 0 = s 0
          then go to trg270
        if c[x] # 0
          then go to trg260
        shift left a[w]
        go to trg270

trg190: if 0 = s 10
          then go to trg220
        0 -> s 10
trg200:  if 1 = s 4
          then go to trg210
        1 -> s 4
        go to trg170

trg210: 0 -> s 4
        go to trg170

trg220: 1 -> s 10
        if 0 = s 6
          then go to trg200
        if 0 = s 7
          then go to trg230
        0 -> s 7
        go to trg170

trg230: 1 -> s 7
        go to trg170

trg240: jsb trc10
        go to trg150

trg250: a exchange b[w]
        a - b -> a[w]
        delayed rom @11
        jsb toggle_s10
        go to trg280

trg260: c + 1 -> c[x]
trg270: if c[xs] # 0
          then go to L5234
        a - b -> a[w]
        if n/c go to trg250
        a + b -> a[w]
trg280: delayed rom @06
        jsb S3235			; maybe equiv shf10 in 41C?
L5234:  0 -> a[s]
        if 1 = s 0
          then go to L5251
        b exchange c[w]
        m1 -> c
        b exchange c[w]
        delayed rom @06
        jsb S3132
        0 -> a[s]
        m1 exchange c
        jsb trc10
        delayed rom @06
        jsb S3073
L5251:  c - 1 -> c[x]
        m1 exchange c
        m1 -> c
        c + 1 -> c[x]
        if n/c go to trg310
        shift left a[w]
        go to trg330

L5260:  0 -> c[w]
        0 -> a[w]
        a + 1 -> a[p]
L5263:  delayed rom @06
        jsb S3250
        go to L5310

trg315: p <- 12
        m1 -> c
        if 1 = s 10
          then go to L5521
        if 0 = s 13
          then go to L5263
        b exchange c[w]
        m2 -> c
        delayed rom @13
        jsb S5602
        c -> stack
        m2 -> c
        a exchange b[w]
        delayed rom @06
        jsb S3033
L5305:  if 0 = s 4			; compare trg500 in 41C
          then go to L5310
        0 - c - 1 -> c[s]
L5310:  delayed rom @00
        go to op_done

trg305: p - 1 -> p
        if p = 6
          then go to trg315
trg310: c + 1 -> c[x]
        if n/c go to trg305
trg330: 0 -> c[w]
        b exchange c[w]
L5321:  delayed rom @11
        jsb S4750
        b exchange c[w]
        delayed rom @07
        jsb S3563
        if p # 6
          then go to L5321
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
        go to trg370

trg350: shift right a[wp]
        shift right a[wp]
trg360: a - 1 -> a[s]
        if n/c go to trg350
        0 -> a[s]
        m1 exchange c
        a exchange c[w]
        a - c -> c[w]
        a + b -> a[w]
        m1 exchange c
trg370: a -> b[w]
        c -> a[s]
        c - 1 -> c[p]
        if n/c go to trg360
        a exchange c[w]
        shift left a[m]
        a exchange c[w]
        if c[m] = 0
          then go to L5373
        c - 1 -> c[s]
        0 -> a[s]
        shift right a[w]
        go to trg370

L5372:  c + 1 -> c[x]
L5373:  c - 1 -> c[s]			; compare trg400 in 41C
        if n/c go to L5372
        0 -> c[s]
        m1 exchange c
        a exchange c[w]
        a - 1 -> a[w]
        m1 -> c
        if 1 = s 10
          then go to L5406
        0 - c -> c[x]			; compare trg415 in 41C
        a exchange b[w]
L5406:  if b[w] = 0			; compare trg420 in 41C
          then go to L5504
        delayed rom @06
        jsb S3132
        0 -> a[s]
        if 0 = s 6
          then go to L5263
        a -> b[w]
        p <- 1
        a + b -> a[p]
        if n/c go to L5430
        shift left a[w]
        a + 1 -> a[ms]
        if n/c go to L5431
        a + 1 -> a[s]
        shift right a[w]
        a -> b[w]
        c + 1 -> c[x]
L5430:  shift left a[w]
L5431:  a exchange c[ms]
        delayed rom @06
        jsb S3077
        jsb S5544
        if 0 = s 13
          then go to L5470
        b exchange c[w]
        a exchange b[w]
        m2 -> c
        a exchange c[w]
        delayed rom @06
        jsb S3124
        a exchange c[w]
        m1 exchange c
        a + c -> c[x]
        c -> stack
        m1 -> c
        a exchange c[w]
        jsb S5600
        stack -> a
        c -> stack
        m2 -> c
        a exchange c[x]
        0 -> a[x]
        shift right a[w]
        m1 exchange c
        delayed rom @06
        jsb S3073
        delayed rom @06
        jsb S3035
        go to L5542

L5470:  b exchange c[w]
        a exchange b[w]
        m1 -> c
        a exchange c[w]
        a - c -> c[x]
        0 -> a[x]
        shift right a[w]
        delayed rom @06
        jsb S3132
        0 -> c[s]
        delayed rom @12
        go to L5263

L5504:  0 -> c[w]
        if 1 = s 6
          then go to L5515
        c - 1 -> c[w]
        0 -> c[xs]
        1 -> s 3
        0 -> c[s]
        delayed rom @00
        go to op_done

L5515:  if 0 = s 13
          then go to L5260
        0 -> c[w]
        go to L5540

L5521:  if 1 = s 6
          then go to L5530
        a exchange b[w]
        delayed rom @06
        jsb S3163
        delayed rom @12
        go to L5263

L5530:  if 0 = s 13
          then go to L5260
        b exchange c[w]
        a exchange b[w]
        m2 -> c
        delayed rom @06
        jsb S3033
        jsb S5602
L5540:  c -> stack
        m2 -> c
L5542:  delayed rom @12
        go to L5305

S5544:  0 -> b[w]			; compare L3707 in 27
        b exchange c[x]
        p <- 12
        b -> c[w]
        c + c -> c[x]
        if n/c go to L5566
        b -> c[w]
        delayed rom @11
        jsb S4737
L5555:  a + 1 -> a[p]			; compare L3720 in 27
        if n/c go to L5561
        p + 1 -> p
        go to L5555

L5561:  delayed rom @06			; compare L3724 in 27
        jsb S3104
L5563:  0 -> b[w]			; compare L3726 in 27
        delayed rom @06
        go to sqrt_sub

L5566:  b -> c[w]			; compare L3736 in 27
L5567:  c - 1 -> c[x]
        if n/c go to L5573
        b -> c[w]
        go to L5555

L5573:  p - 1 -> p			; compare L3731 in 27
        if p # 0
          then go to L5567
        b -> c[w]
        go to L5563

S5600:  delayed rom @06
        jsb S3035
S5602:  if 0 = s 7			; compare trg500 in 41C
          then go to L5605
        0 - c - 1 -> c[s]
L5605:  delayed rom @05
        go to $over0

        rotate left a			; unused duplicate of code at S5710?
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        return

L5616:  p <- 1
        if 0 = s 3
          then go to L5625
        0 -> c[x]
        load constant 1
        c -> data
        go to L5706

L5625:  c -> data address
        b exchange c[w]
        m1 exchange c
        data -> c
        b exchange c[ms]
        b -> c[x]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        decimal
        0 - c - 1 -> c[xs]
        binary
        go to L5646

L5642:  p + 1 -> p
        p + 1 -> p
        shift left a[wp]
        shift left a[wp]
L5646:  c - 1 -> c[xs]
        if n/c go to L5642
        data -> c
        a exchange c[w]
        rotate left a
        rotate left a
        shift right a[wp]
        shift right a[wp]
        c -> a[p]
        p - 1 -> p
        c -> a[p]
        b -> c[w]
        go to L5672

L5663:  c -> a[w]
        c -> data address
        data -> c
        p <- 11
        a exchange c[wp]
        rotate left a
        rotate left a
L5672:  a exchange c[w]
        p <- 0
        c -> data
        a exchange c[w]
        c - 1 -> c[p]
        if n/c go to L5663
        p <- 1
        c - 1 -> c[p]
        if c[p] # 0
          then go to L5663
L5704:  m1 -> c
        b exchange c[w]
L5706:  delayed rom @00
        go to L0125

S5710:  rotate left a			; rotate A left six digits
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        return

; delete a program step

del:    if 0 = s 11			; program mode?
          then go to L5706		;   no, don't delete
        b exchange c[w]
        m1 exchange c
        delayed rom @00
        jsb getpc
        if c[x] = 0
          then go to L5704
        p <- 1
L5730:  p - 1 -> p
        p - 1 -> p
        c - 1 -> c[xs]
        if n/c go to L5730
        c -> a[w]
        c -> data address
        data -> c
        a exchange c[w]
        shift left a[wp]
        shift left a[wp]
        p <- 1
        c -> a[wp]
        go to L5760

L5745:  c -> data address
        b exchange c[wp]
        data -> c
        a exchange c[wp]
        jsb S5710			; rotate A left 12 digits
        jsb S5710			;    (= rotate A right 2 digits)
        c -> data address
        b -> c[wp]
        a exchange c[w]
        c -> data
        b -> c[w]
L5760:  c - 1 -> c[wp]
        if c[p] # 0
          then go to L5745
        a exchange c[w]
        c -> data address
        shift right c[w]
        shift right c[w]
        c -> data
        m1 -> c
        b exchange c[w]
        0 -> s 3
        delayed rom @02
        go to L1367

        nop
        nop
        nop

;------------------------------------------------------------------
; End of math package (almost same as 19C/29C)
;------------------------------------------------------------------

	.org @6000	; from ROM/RAM p/n 1818-0232 (67)
			; and ROM p/n 1818-0233 (97)

; addr 6000: dispatch table for 0x0x..0xfx
        go to L6034		; 0x00..0x0f misc
        go to L6041		; 0x10..0x1f digit entry, divide
        go to L6034		; 0x20..0x2f misc
        go to L6046		; 0x30..0x3f misc
        go to L6046		; 0x40..0x4f misc
        go to L6030		; 0x50..0x5f compares, F? 0-3, ISZ, DSZ
        go to L6040		; 0x60..0x6f DSP 0-9, DSP (i), CF 0-3
        go to L6326		; 0x70..0x7f RCL n
        go to L6266		; 0x80..0x8f STO / n, STO / (i), SF 0-3
        go to L6321		; 0x90..0x9f STO n
        go to L6274		; 0xa0..0xaf STO - n
        go to op_gsb		; 0xb0..0xbf GSB n
        go to L6307		; 0xc0..0xcf STO + n
        go to op_gto		; 0xd0..0xdf GTO n
        go to L6313		; 0xe0..0xef STO * n

L6017:  delayed rom @00		; 0xf0..0xff LBL
        go to L0074

; execute user instruction in low order byte of m1
execute:
	m1 -> c	
        c -> a[x]
        0 -> a[xs]
        b -> c[w]
        p <- 12
        0 -> s 3
        a -> rom address		; @6000-63777

; 0x50..0x5f compares, F? 0-3, ISZ, DSZ

L6030:  m1 exchange c
        delayed rom @17
        jsb get_reg_3f
        m1 -> c

L6034:  decimal			; 0x00..0x0f, 0x20..0x2f misc
        shift left a[x]
        delayed rom @15
        a -> rom address		; @6400-6777

; 0x60..0x6f DSP 0-9, DSP (i), CF 0-3

L6040:  1 -> s 6

; 0x00..0x0f digit entry, divide

L6041:  p <- 0
        load constant 10	; check for 0-9
        p <- 0
        delayed rom @17
        go to L7476

; 0x30..0x4f misc

L6046:  decimal
        shift left a[x]
        delayed rom @16
        a -> rom address	; dispatch table at T7060

op_gsb: 1 -> s 8		; GSB n
        p <- 1
        a + 1 -> a[p]
        a + 1 -> a[p]
op_gto: p <- 1			; GTO n
        a + 1 -> a[p]
        a + 1 -> a[p]
        p <- 0
        b -> c[w]
        m1 exchange c
        a + 1 -> a[p]
        if n/c go to L6071
        1 -> s 10
        delayed rom @15
        go to S6673

L6071:  a - 1 -> a[p]
        a exchange c[w]
L6073:  p <- 1
        c -> a[w]
        shift left a[w]
        shift left a[w]
        a exchange c[xs]
L6100:  shift left a[w]
        shift left a[w]
        c -> a[x]
        p - 1 -> p
        if p # 5
          then go to L6100
        delayed rom @00
        jsb getpc
        if c[x] # 0		; compare to code @6060 in 19c/29c
          then go to L6114
        delayed rom @00
        jsb incpc
L6114:  p <- 1
L6115:  p - 1 -> p
        p - 1 -> p
        c - 1 -> c[xs]
        if n/c go to L6115
L6121:  c -> data address
        b exchange c[w]
        data -> c
        b exchange c[w]
        a exchange b[w]
L6126:  if a >= b[p]		; is the byte a[p:p-1] a label?
          then go to L6205	;   yes
L6130:  p + 1 -> p		; no, advance byte position (toward left)
        p + 1 -> p
        if p # 0		; end of word?
          then go to L6126	;   no, look at next byte
        go to L6171		;   yes, advance to next word

L6135:  c -> data address	; get word addressed by c into a
        a exchange c[w]
        data -> c
        a exchange c[w]
        if a[w] # 0		; is word all zero?
          then go to L6144	;   no, check for label
        go to L6171		;   yes, advance to next word

L6144:  p <- 1			; unrolled byte tests
        if a >= b[p]
          then go to L6205
        p <- 3
        if a >= b[p]
          then go to L6205
        p <- 5
        if a >= b[p]
          then go to L6205
        p <- 7
        if a >= b[p]
          then go to L6205
        p <- 9
        if a >= b[p]
          then go to L6205
        p <- 11
        if a >= b[p]
          then go to L6205
        p <- 13
        if a >= b[p]
          then go to L6205

L6171:  p <- 1			; advance to next word
        c - 1 -> c[wp]		; decrement word address
        if c[p] # 0		; if addr >= 0x10
          then go to L6135	;   resume search
        if 1 = s 6		; second pass?
          then go to L6765	;   yes, label search failed
        load constant 2		;   no, start second pass
        1 -> s 6
        go to L6135

        p <- 9
        a exchange b[w]
        go to L6121

L6205:  a exchange b[p]		; possible label match
        if a >= b[p]
          then go to L6212
        a exchange b[p]
        go to L6130

L6212:  a exchange b[p]
        p - 1 -> p
        if a >= b[p]
          then go to L6220
L6216:  p + 1 -> p
        go to L6130

L6220:  a exchange b[p]
        if a >= b[p]
          then go to L6225
        a exchange b[p]
        go to L6216

L6225:  c + 1 -> c[xs]		; label found
        p - 1 -> p
        p - 1 -> p
        if p # 12
          then go to L6225
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        decimal
        0 - c - 1 -> c[xs]
        c -> a[w]
L6240:  m1 -> c
        b exchange c[w]
        delayed rom @00
        jsb getpc
        if 0 = s 8		; GSB?
          then go to L6262	;   no

        a exchange c[w]		; yes, push subroutine stack
        p <- 11
        shift left a[wp]
        shift left a[wp]
        shift left a[wp]
        a exchange c[w]
        if 1 = s 2		; running?
          then go to L6262	;   yes
        1 -> s 2		; start running
        if 1 = s 1		; single-step?
          then go to L6262	;   yes
        0 -> c[w]		;   no - from keyboard, GSB clears stack

L6262:  a exchange c[x]		; replace PC with new value
        c -> register 13	; write PC back to mem
        delayed rom @00
        go to L0063

L6266:  jsb S6335		; 0x80..0x8f STO / n, STO / (i), SF 0-3
        if 1 = s 12
          then go to op_sf
        delayed rom @05
        jsb S2416
        go to L6302

L6274:  jsb S6335
        if 1 = s 12
          then go to op_gsb
        0 - c - 1 -> c[s]
L6300:  delayed rom @06
        jsb addax
L6302:  delayed rom @05
        jsb $over0
        if 1 = s 3
          then go to L6765
        go to L6322

L6307:  jsb S6335
        if 1 = s 12
          then go to op_gto
        go to L6300

L6313:  jsb S6335
        if 1 = s 12
          then go to L6017
        delayed rom @06
        jsb mul
        go to L6302

L6321:  jsb S6350		; 0x90..0x9f STO n
L6322:  c -> data
        m1 -> c
        delayed rom @00
        go to L0073

L6326:  jsb S6350		; 0x70..0x7f RCL n
L6327:  if 0 = s 9		; stack lift if enabled
          then go to L6332
        c -> stack
L6332:  a exchange c[w]
        delayed rom @00
        go to op_done

S6335:  a exchange c[x]
        c -> a[x]
        p <- 0
        c + 1 -> c[p]
        if n/c go to L6344
        delayed rom @15
        go to S6673

L6344:  load constant 10
        1 -> s 12
        if a >= c[x]
          then go to L6362
S6350:  b -> c[w]
        m1 exchange c
        p <- 1
        0 -> c[p]
L6354:  c -> data address
        data -> c
        a exchange b[w]
        a exchange c[w]
        decimal
        0 -> s 12
L6362:  return


clear_return_stack:
	0 -> c[w]
        c -> register 13
        go to L6017


op_pause:			; 0x20 PAUSE
	crc sf pause		; set pause flag
        0 -> s 12
        1 -> s 9		; enable stack lift
        delayed rom @00
        go to L0125

L6373:  if 1 = s 3
          then go to L7256
        delayed rom @00
        go to L0114

        nop

; addr 6400: dispatch table for 0x00..0x0f
        go to op_rs		; 0x00 R/S
        go to op_1_over_x	; 0x01 1/x
        go to op_x_squared	; 0x02 x^2
        go to op_sqrt		; 0x03 sqrt(x)
        go to op_percent_x	; 0x04 %
        go to op_sigma_plus_x	; 0x05 Sigma+
        go to op_y_to_x		; 0x06 y^x
        go to op_ln		; 0x07 ln
        go to op_e_to_x_x	; 0x08 e^x
        go to op_r_to_p_x	; 0x09 R->P
        go to op_sin		; 0x0a sin
        go to op_cos		; 0x0b cos
        go to op_tan		; 0x0c tan
        go to op_p_to_r_x	; 0x0d R<-P
        go to op_rtn_x		; 0x0e RTN

        delayed rom @06		; 0x0f RCL Sigma
        go to op_rcl_sigma

op_1_over_x:
	delayed rom @05		; 0x01 1/x
        jsb S2636
        go to L6426

op_x_squared:
	delayed rom @06		; 0x02 x^2
        jsb S3112
L6426:  delayed rom @00
        go to op_done

op_abs: m2 exchange c		; 0x26 ABS - save Lastx
        m2 -> c
        0 -> c[s]		; make positive
        go to L6426

op_pause_x:
	delayed rom @14		; 0x20 PAUSE
        go to op_pause

op_percent_x:
	delayed rom @05		; 0x04 %
        go to op_percent

; addr 6440: dispatch table for 0x20..0x3f
        go to op_pause_x	; 0x20 PAUSE
        go to op_fact_x		; 0x21 n!
        go to op_mean_x		; 0x22 mean
        go to op_std_dev_x	; 0x23 std dev
        go to op_pct_chg_x	; 0x24 %CH
        go to op_sigma_minus_x	; 0x25 Sigma-
        go to op_abs		; 0x26 ABS
        go to op_log		; 0x27 Log
        go to op_10_to_x	; 0x28 10^x
        go to op_int		; 0x29 INT
        go to op_arcsin		; 0x2a arcsin
        go to op_arccos		; 0x2b arccos
        go to op_arctan		; 0x2c arctan
        go to op_frac		; 0x2d FRAC
        go to op_rnd		; 0x2e RND

        delayed rom @00		; 0x2f spare - NOP
        go to L0074

op_sqrt:
	delayed rom @06		; 0x03 sqrt(x)
        jsb sqrt
        go to L6426

op_sigma_plus_x:
	delayed rom @05		; 0x05 Sigma+
        go to op_sigma_plus

op_e_to_x_x:
	delayed rom @07		; 0x08 e^x
        go to op_e_to_x

op_r_to_p_x:
	delayed rom @10		; 0x09 R->P
        go to op_r_to_p

op_p_to_r_x:
	delayed rom @12		; 0x0d R<-P
        go to op_p_to_r

op_y_to_x:
	stack -> a		; 0x06 y^x
        c -> stack
        a exchange c[w]
        1 -> s 10
op_log: 1 -> s 6		; 0x27 Log
op_ln:  1 -> s 8		; 0x07 Ln
        delayed rom @10
        go to L4044

op_cos: 1 -> s 10		; 0x0b cos
op_sin: 1 -> s 6		; 0x0a sin
op_tan: delayed rom @12		; 0x0c tan
        go to trig

op_rnd: b exchange c[w]		; 0x2e RND
        1 -> s 12
        delayed rom @00
        go to L0026

op_rtn_x:
	delayed rom @16		; 0x0e RTN
        go to op_rtn

op_fact_x:
	delayed rom @06		; 0x21 n!
        go to op_fact

; addr 6520: dispatch table for 0x50..0x5f
        go to op_x_ne_y		; 0x50 x!=y
        go to op_x_eq_y		; 0x51 x=y
        go to op_x_gt_y		; 0x52 x>y
        go to op_x_ne_0		; 0x53 x!=0
        go to op_x_eq_0		; 0x54 x=0
        go to op_x_gt_0		; 0x55 x>0
        go to op_x_lt_0		; 0x56 x<0
        go to op_x_le_y		; 0x57 x<=y

        p + 1 -> p		; 0x58 F? 0
        p + 1 -> p		; 0x59 F? 1
        p + 1 -> p		; 0x5a F? 2
        go to op_flag_test		; 0x5b F? 3

        1 -> s 4		; 0x5c ISZ
        go to op_isz_dsz	; 0x5d ISZ (i)

        1 -> s 4		; 0x5e DSZ
        1 -> s 13		; 0x5f DSZ (i)


; ISZ (s13=0) or DSZ (s13=1)
; arg is I if s4=1, (i) if s4=0

op_isz_dsz:  0 -> c[w]
        c -> data address
        register -> c 15
        if 0 = s 4
          then go to L6550
        a exchange c[w]
L6546:  delayed rom @05
        go to L2645

L6550:  jsb S6676
        go to L6546

op_x_eq_y:			; 0x51 x=y
	y -> a
        a - c -> c[w]
op_x_eq_0:			; 0x54 x=0
	if c[w] = 0
          then go to noskip
        go to skip

op_x_ne_y:			; 0x50 x!=y
	y -> a
        a - c -> c[w]
op_x_ne_0:			; 0x53 x!=0
	if c[w] # 0
          then go to noskip
skip:   delayed rom @00
        jsb incpc
        0 -> s 3
noskip: m1 -> c
        delayed rom @00
        go to L0073

op_x_le_y:			; 0x57 x<=y
	y -> a
        1 -> s 13
        go to L6576

op_x_gt_y:			; 0x52 x>y
	y -> a
        a exchange c[w]
L6576:  0 - c - 1 -> c[s]
        delayed rom @06
        jsb addax
        go to op_x_gt_0

op_x_lt_0:			; 0x56 x<0
	0 - c - 1 -> c[s]
op_x_gt_0:			; 0x55 x>0
	if c[m] # 0
          then go to L6610
        if 1 = s 13
          then go to noskip
        go to skip

L6610:  if c[s] = 0
          then go to noskip
        go to skip


; On entry, P contains (3 - flag number)
op_flag_test:			; 0x58..0x5b F? 0-3
	register -> c 14
        c -> a[w]
        if p = 2		; if flag 0-1, don't clear the flag
          then go to L6624
        if p = 3
          then go to L6624
        load constant 0
        p + 1 -> p
        c -> data
L6624:  if a[p] # 0
          then go to noskip
        go to skip

L6627:  shift right c[m]
        shift right c[m]
        jsb S6740
        jsb S6716
        a exchange c[w]
        delayed rom @17
        go to L7462

op_mean_x:
	delayed rom @05		; 0x22 mean
        go to op_mean

op_std_dev_x:
	delayed rom @05		; 0x23 std dev
        go to op_std_dev

op_pct_chg_x:
	delayed rom @05		; 0x24 %CH
        go to op_pct_chg

op_10_to_x:
	1 -> s 8		; 0x28 10^x
        delayed rom @07
        go to L3546

op_sigma_minus_x:
	delayed rom @05		; 0x25 Sigma-
        go to op_sigma_minus

op_arccos:
	1 -> s 10		; 0x2b arccos
op_arcsin:
	1 -> s 6		; 0x2a arcsin
op_arctan:
	1 -> s 13		; 0x2c arctan
        delayed rom @11
        go to inv_trig

op_int:
	jsb S6671		; 0x29 INT
        0 -> c[wp]
        a exchange c[x]
        go to L6426

op_frac:
	jsb S6671		; 0x2d FRAC
        0 -> a[x]
        delayed rom @06
        jsb S3235
        c - 1 -> c[x]
        a exchange c[m]
        go to L6426

S6671:  delayed rom @16
        go to L7036

; indirect (s10=1 for GTO/GSB)
S6673:  0 -> c[w]		; get I register
        c -> data address
        register -> c 15
S6676:  p <- 7
L6677:  p - 1 -> p
        shift right c[m]
        if p # 0
          then go to L6677
        if c[xs] = 0
          then go to L6706
        0 -> c[w]
L6706:  if 1 = s 10
          then go to L6773
        if 1 = s 6
          then go to L6627
        shift right c[m]
        jsb S6735
        delayed rom @04
        go to L2331

S6716:  0 -> s 3
        if c[m] = 0
          then go to L6731
        decimal
        c - 1 -> c[m]
        if 1 = s 7
          then go to S6726
        binary
S6726:  c + 1 -> c[p]
        if n/c go to S6716
        1 -> s 3
L6731:  return

S6732:  if c[x] = 0
          then go to L6743
        c - 1 -> c[x]
S6735:  if c[x] = 0
          then go to L6744
        c - 1 -> c[x]
S6740:  if c[x] = 0
          then go to L6745
        go to L6767

L6743:  shift right c[m]
L6744:  shift right c[m]
L6745:  p <- 0
        return

; GSB/GTO ind label
L6747:  shift right c[m]
        jsb S6735		; get indirect value, two digits
        p <- 1
        load constant 15
        jsb S6726
        c - 1 -> c[x]
        if 0 = s 3
          then go to L6073	; start looking for the label
        load constant 11
        p <- 0
        jsb S6716
        c - 1 -> c[x]
        if 0 = s 3
          then go to L6073	; start looking for the label
L6765:  m1 -> c
        b exchange c[w]
L6767:  delayed rom @02
        go to L1373

op_rs:  delayed rom @00		; 0x00 R/S
        go to run_stop

; GTO/GSB indirect (label or rapid reverse)
L6773:  if c[s] = 0
          then go to L6747

; GTO/GSB indirect negative (rapid-reverse branch)
        jsb S6732		; get indirect value, three digits
        shift right c[w]
        shift right c[w]
        shift right c[w]
        b exchange c[w]
        delayed rom @00
        jsb getpc
        delayed rom @04
        jsb S2362
        rotate left a
        rotate left a
        rotate left a
        b exchange c[w]
        decimal
        delayed rom @04
        go to L2242

op_fix:				; 0x34 FIX
	jsb get_display_mode
        load constant 2
        load constant 2
        go to L7027

op_eng:				; 0x33 ENG
	jsb get_display_mode
        load constant 4
        go to L7026

op_sci:				; 0x36 SCI
	jsb get_display_mode
        load constant 0
L7026:  load constant 0
L7027:  c -> register 14
        delayed rom @00
        go to L0114

op_done_b_x:  delayed rom @00
        go to op_done_b

op_prtx_x:	
	delayed rom @03		; 0x35 PRTx
        go to op_prtx

L7036:  jsb save_lastx_2
        c -> a[w]
        if c[xs] = 0
          then go to L7044
        c + 1 -> c[x]
        return

L7044:  c + 1 -> c[x]
L7045:  if c[x] = 0
          then go to L7054
        c - 1 -> c[x]
        shift left a[m]
        p - 1 -> p
        if a[m] # 0
          then go to L7045
L7054:  return

op_merge:			; 0x45 MERGE
	crc sf merge		; set merge flag
        delayed rom @00
        go to L0125

; addr 7060: dispatch table for 0x30..0x4f
        go to op_x_exch_y	; 0x30 x<>y
        go to op_roll_down	; 0x31 RDN
        go to op_clx		; 0x32 CLx
        go to op_eng		; 0x33 ENG
        go to op_fix		; 0x34 FIX
        go to op_prtx_x		; 0x35 PRTx
        go to op_sci		; 0x36 SCI
        go to op_plus		; 0x37 +
        go to op_minus		; 0x38 -
        go to op_multiply	; 0x39 *
        go to op_deg_to_rad	; 0x3a D->R
        go to op_rad_to_deg	; 0x3b D<-R
        go to op_h_to_hms	; 0x3c H->HMS
        go to op_hms_to_h	; 0x3d H<-HMS
        go to op_sto_ind	; 0x3e STO (i)
        go to op_rcl_ind	; 0x3f RCL (i)
        go to op_hms_plus	; 0x40 HMS+
        go to op_space_x	; 0x41 SPACE
        go to op_prstk_x	; 0x42 PRSTK
        go to op_lastx		; 0x43 LASTx
        go to op_wdata_x2	; 0x44 WDATA
        go to op_merge		; 0x45 MERGE
        go to op_x_exch_i	; 0x46 x<>I
        go to op_roll_up	; 0x47 R^
        go to op_pi		; 0x48 Pi
        go to op_deg		; 0x49 DEG
        go to op_rad		; 0x4a RAD
        go to op_grad		; 0x4b GRAD
        go to op_pri_exch_sec	; 0x4c P<>S
        go to op_clr_reg	; 0x4d CLREG
        go to op_preg_x		; 0x4e PREG
        go to L7313		; 0x4f spare

op_preg_x:
	delayed rom @02		; 0x4e PREG
        go to op_preg

op_h_to_hms:			; 0x3c H->HMS
	1 -> s 8
op_hms_to_h:			; 0x3d H<-HMS
	jsb save_lastx_2
        delayed rom @06
        go to hms_conv

op_rcl_ind:			; 0x3f RCL (i)
	delayed rom @15
        jsb S6673
        delayed rom @14
        go to L6327

op_plus:			; 0x37 +
	jsb save_lastx_2
        go to L7136

op_minus:			; 0x38 -
	jsb save_lastx_2
        0 - c - 1 -> c[s]	; negate
L7136:  stack -> a
        delayed rom @06
        jsb addax
        go to op_done_x


op_multiply:			; 0x39 *
	delayed rom @06
        jsb mulxy
        go to op_done_x


save_lastx_2:  m2 exchange c
        m2 -> c
        return

op_hms_plus:			; 0x40 HMS+
	b exchange c[w]
        delayed rom @06
        go to hms_plus

op_lastx:			; 0x43 LASTx
	jsb cond_stack_lift
        m2 -> c
        go to op_done_x


op_wdata_x2:
	delayed rom @07		; 0x44 WDATA
        go to op_wdata_x


op_x_exch_i:			; 0x46 x<>I
	0 -> c[w]
        c -> data address
        register -> c 15	; get I into C
        b exchange c[w]		; move I into B, X into C
        c -> register 15	; save prev X into I
        go to op_done_b_x


cond_stack_lift:
	if 0 = s 9		; stack lift if enabled
          then go to L7171
        c -> stack
L7171:  return


op_pi:  jsb cond_stack_lift	; 0x48 Pi
        delayed rom @12		; get pi/4
        jsb trc10
        c + c -> c[w]		; multiply by 4
        c + c -> c[w]
        shift right c[w]	; position appropriately
        c + 1 -> c[m]		; round
        0 -> c[x]		; clear exponent
        go to op_done_x


op_rad: 1 -> s 0		; 0x4a RAD
        go to L7206

op_deg: 0 -> s 0		; 0x49 DEG
L7206:  0 -> s 14
        go to L7313

op_grad:			; 0x4b GRAD
	0 -> s 0
        1 -> s 14
        go to L7313

op_clr_reg:			; 0x4d CLREG
	delayed rom @00
        go to clr_reg_x

op_pri_exch_sec:		; 0x4c P<>S - save X in m1
	m1 exchange c
        0 -> c[w]		; start at address 0
L7217:  p <- 1			; block 0
        0 -> c[p]
        c -> data address
        b exchange c[w]
        data -> c
        a exchange c[w]
        b -> c[w]
        load constant 3		; block 3
        c -> data address
        data -> c
        a exchange c[w]
        c -> data
        b -> c[w]
        c -> data address
        a exchange c[w]
        c -> data
        b -> c[w]
        c + 1 -> c[p]
        if n/c go to L7217

        m1 exchange c		; restore X from m1
        delayed rom @00
        go to L0073


op_x_exch_y:			; 0x30 x<>y
	stack -> a
        c -> stack
        a exchange c[w]
        go to op_done_x


op_clx: 0 -> b[w]		; 0x32 CLx
        0 -> s 9		; disable stack lift
        crc fs?c crc_f8		; clear f8, purpose unknown
        if 0 = s 12
          then go to L6373
L7256:  crc sf crc_f8		; set f8, purpose unknown
        delayed rom @00
        go to L0076


; get display mode, in preparation for changing it 
get_display_mode:
	b exchange c[w]
        delayed rom @17
        jsb get_reg_3f
        register -> c 14
        p <- 5
        return


op_rtn: b exchange c[w]		; 0x0e RTN
        p <- 1			; get stack register
        load constant 3
        c -> data address
        register -> c 13
        if 1 = s 1		; single-step?
          then go to L7300	;   yes, do it
        if 0 = s 2		; running?
          then go to clear_return_stack	;   no, kill return stack
L7300:  0 -> c[s]		; shift stack to the right
        shift right c[w]
        shift right c[w]
        shift right c[w]
        if c[w] # 0		; stack empty?
          then go to L7310
halt_x: delayed rom @00		;   yes, halt
        go to halt

L7310:  c -> data		; no, write stack back to memory
        if 1 = s 1		; single-step?
          then go to halt_x	;   yes, halt
L7313:  delayed rom @00		; return to main loop
        go to L0074


L7315:  decimal
        b -> c[w]
        delayed rom @06
        jsb S3114
        go to op_done_x


op_deg_to_rad:			; 0x3a D->R
	jsb save_lastx_2
        a exchange c[w]
        delayed rom @12
        jsb S5036
        c + 1 -> c[x]
        c + 1 -> c[x]
        delayed rom @06
        jsb S3122
        0 -> a[s]
        m1 exchange c
        delayed rom @12
        jsb trc10
L7336:  delayed rom @06
        jsb S3073
        delayed rom @06
        jsb S3035
        go to op_done_x


op_rad_to_deg:			; 0x3b D<-R
	jsb save_lastx_2
        0 -> a[w]
        a exchange c[m]
        b exchange c[w]
        delayed rom @12
        jsb trc10
        b exchange c[w]
        c + 1 -> c[x]
        c + 1 -> c[x]
        delayed rom @06
        jsb S3132
        0 -> a[s]
        m1 exchange c
        delayed rom @12
        jsb S5036
        go to L7336

op_sto_ind:			; 0x3e STO (i)
	delayed rom @15
        jsb S6673
        delayed rom @14
        go to L6322

op_roll_up:			; 0x47 R^
	down rotate
        down rotate
op_roll_down:			; 0x31 RDN
	down rotate

op_done_x:
	delayed rom @00
        go to op_done

op_space_x:
	delayed rom @03		; 0x41 SPACE
        go to op_space

op_prstk_x:
	delayed rom @02		; 0x42 PRSTK
        go to op_prstk


S7400:  jsb get_reg_3f
        p <- 5
        if c[p] # 0
          then go to L7405
        1 -> s 4
L7405:  p <- 11
        if c[p] = 0
          then go to L7411
        1 -> s 7
L7411:  p <- 6
        return


; 0x6a..0x6f: CF 0-3, illegal, DSP (i)
L7413:  a + 1 -> a[p]
        if n/c go to op_cf
        delayed rom @15		; do DSP indirect
        go to S6673

; CF 0-3
op_cf:  jsb S7430
        load constant 0
        go to L7425

; SF 0-3
op_sf:  a + 1 -> a[w]
        jsb S7430
        load constant 1

; CF/SF finish
L7425:  c -> register 14	; write back status register
L7426:  delayed rom @00
        go to L0074

; CF/SF common
S7430:  jsb get_reg_3f
        register -> c 14
        p <- 12
        shift left a[x]
        shift left a[x]
L7435:  p + 1 -> p
        a + 1 -> a[xs]
        if n/c go to L7435
        return


L7441:  shift left a[x]		; 0x1a..0x1f, 0x6a..0x6f decimal, ENTER, CHS,
                                ; EEX, divide, CF0-3, DSP (i)
        a + 1 -> a[xs]
        a -> rom address		; @7400-7777

L7444:  b exchange c[w]
        0 - c - 1 -> c[s]
        delayed rom @00
        go to op_done

L7450:  delayed rom @16
        go to L7315

        go to L7733
        go to L7773
        go to L7747
        go to L7713
        go to L7450
        go to L7426

; 0x60..0x6f DSP 0-9, DSP (i), CF 0-3

L7460:  if a >= c[p]		; 0x60..0x69?
          then go to L7413	;   no

; DSP 0-9
L7462:  jsb get_reg_3f
        register -> c 14
        p <- 6
        load constant 5
        p <- 6
L7467:  shift left a[w]
        c - 1 -> c[p]
        if n/c go to L7467
        a exchange c[p]
        c -> register 14
        delayed rom @00
        go to L0114

; 0x10..0x1f digit entry, divide,
; 0x60..0x6f DSP 0-9, DSP (i), CF 0-3, continued

L7476:  if 1 = s 6		; 0x60..0x6f?
          then go to L7460	;   yes
        if a >= c[p]		; 0x10..0x19, 0x60..0x69?
          then go to L7441	;   no
        if 1 = s 12
          then go to L7506
        jsb S7651
        go to L7507

L7506:  jsb S7400
L7507:  if 1 = s 4
          then go to L7566
        if c[s] = 0
          then go to L7643
        if 0 = s 7
          then go to L7516
        c + 1 -> c[p]
L7516:  p <- 10
        c - 1 -> c[s]
        shift left a[x]
        shift left a[x]
        if c[p] # 0
          then go to L7532
        if a[xs] # 0
          then go to L7535
        c + 1 -> c[m]
        if 1 = s 7
          then go to L7542
        go to L7546

L7532:  if 1 = s 7
          then go to L7546
        go to L7544

L7535:  if 0 = s 7
          then go to L7545
        c + 1 -> c[p]
        p <- 9
        go to L7545

L7542:  p <- 9
        load constant 1
L7544:  p <- 7
L7545:  c + 1 -> c[p]
L7546:  c -> register 15
        shift right c[wp]
        c + 1 -> c[s]
        p <- 2
L7552:  c - 1 -> c[s]
L7553:  p + 1 -> p
        shift left a[wp]
        if c[s] # 0
          then go to L7552
        if c[xs] = 0
          then go to L7563
        c - 1 -> c[xs]
        if n/c go to L7553
L7563:  a exchange b[wp]
        register -> c 15
        go to L7574

L7566:  p <- 1
        a exchange c[x]
        shift left a[wp]
        p <- 0
        c -> a[p]
        a exchange c[x]
L7574:  c -> register 15
        c -> a[x]
        p <- 7
L7577:  shift right c[w]
        p - 1 -> p
        if p # 0
          then go to L7577
        decimal
        if b[m] = 0
          then go to L7643
        a - 1 -> a[xs]
        a -> b[x]
        if c[xs] = 0
          then go to L7615
        0 -> c[xs]
        0 - c -> c[x]
        c - 1 -> c[x]
L7615:  if a[xs] # 0
          then go to L7620
        go to L7622

L7620:  0 -> a[xs]
        0 - c -> c[x]
L7622:  a + c -> a[x]
        a exchange c[w]
        if a[xs] # 0
          then go to L7637
        if c[xs] = 0
          then go to L7637
        0 -> c[w]
        if b[xs] = 0
          then go to L7645
L7633:  b exchange c[w]
        0 -> s 12
        crc sf crc_f8		; set f8, purpose unknown
        go to L7643

L7637:  if b[xs] = 0
          then go to L7642
        0 - c -> c[x]
L7642:  b exchange c[x]
L7643:  delayed rom @00
        go to L0124

L7645:  c - 1 -> c[w]
        0 -> c[xs]
        b exchange c[s]
        go to L7633


S7651:  1 -> s 12
        if 0 = s 9		; stack lift from B if enabled
          then go to L7656
        b -> c[w]
        c -> stack
L7656:  1 -> s 9		; enable stack lift
        jsb get_reg_3f
        register -> c 14
        p <- 0
        load constant 1
        crc fs?c pause		; test pause flag
        if 1 = s 3		; was set?
          then go to L7671	;   yes, need to set it again
        if 1 = s 2		; running?
          then go to L7673
        go to L7672

L7671:  crc sf pause		; set pause flag (was cleared by test above)
L7672:  c -> register 14
L7673:  0 -> c[w]
        0 -> s 3
        b exchange c[w]
        0 -> c[w]
        c + 1 -> c[xs]
        load constant 10
        p <- 5
        load constant 2
        load constant 2
        p <- 6
        return


get_reg_3f:
	p <- 1
        load constant 3
        c -> data address
        register -> c 15
        return


L7713:  if 0 = s 12
          then go to L7721
        jsb get_reg_3f
        p <- 10
        if c[p] # 0
          then go to L7727
L7721:  jsb S7651
        b exchange c[w]
        p <- 12
        load constant 1
        b exchange c[w]
        c - 1 -> c[s]
L7727:  p <- 5
        load constant 0
        load constant 0
        go to L7740

L7733:  if 1 = s 12
          then go to L7742
        jsb S7651
        p <- 11
L7737:  c + 1 -> c[p]
L7740:  c -> register 15
        go to L7643

L7742:  jsb get_reg_3f
        p <- 11
        if c[p] = 0
          then go to L7737
        go to L7740

L7747:  decimal
        if 0 = s 12
          then go to L7444
        jsb S7400
        if 1 = s 4
          then go to L7763
        b exchange c[w]
        if c[m] = 0
          then go to L7761
        0 - c - 1 -> c[s]
L7761:  b exchange c[w]
        go to L7643

L7763:  p <- 2
        c - 1 -> c[xs]
        if c[xs] = 0
          then go to L7771
        load constant 1
        go to L7574

L7771:  load constant 3
        go to L7574

L7773:  b -> c[w]
        c -> stack
        0 -> s 9		; disable stack lift
        delayed rom @00
        go to L0076

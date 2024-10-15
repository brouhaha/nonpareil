; 19c/29c common ROM disassembly
; Copyright 2008 Eric Smith <eric@brouhaha.com>
; $Id: 19c29c.asm 1285 2009-09-17 05:36:27Z eric $
;

	.arch woodstock

; External references
incpc9	.equ	@0021
L0061	.equ	@0061
L0062	.equ	@0062
L0065	.equ	@0065
L0070	.equ	@0070
L0616	.equ	@0616
L1370	.equ	@1370
S1371	.equ	@1371
L1373	.equ	@1373
err0	.equ	@1374
L1402	.equ	@1402

L6171	.equ	@6171
L6546	.equ	@6546

; entry points:
;	S2000
;	S2235	; get status register (addr 0x1e) into C
;	L2260	; x 	L2313
;	L2326
;	S2363
;	divax0
;	S2436
;	L2471	; Sigma-
;	L2472	; Sigma+
;	L2545	; s
;	L2612	; isz/dsz	
;	L2625	; display/print Error (19c only)
;	L2632	; display Error
;	S3000	; 1/x
;	L3006	; advance PC
;	percent	; percent
;	mulxy	; multiply by Y
;	mulax	; multiply by A
;	S3115	; square
;	S3117	; divide
;	addyx	; add Y (not used)
;	addax	; add A
;	S3237
;	sqrt	; square root
;	rcl_sigma	; RCL Sigma
;	hms_conv	; ->HMS, ->H
;	e_to_x	; e^x
;	L3545	; 10^x (entery with s8=1)
;	S3760
;	L4036	; logarithm
;	r_to_p	; rectangular to polar conversion
;	inv_trig	; inverse trig functions
;	p_to_r	; polar to rectangular conversion
;	trig	; trig functions
;	L5605
;	L5662
;	L5736	; set trig angle mode
;	L5750

	.bank 0
	.org @2000

; Entry point

S2000:  jsb S2235
        a exchange c[w]
        jsb S2205
        shift right a[x]
        shift right a[x]
        f exchange a[x]
        a -> b[s]
        decimal
        a - 1 -> a[s]
        if n/c go to L2042
        c -> a[w]
        if a[xs] # 0		; SCI or ENG?
          then go to L2031	;   yes
        p <- 1
        load constant 1
        load constant 0
        if a >= c[x]
          then go to L2037	; large exponent, force SCI
        b exchange c[x]
        0 -> a[x]
        f -> a[x]
        a + c -> a[x]
        if a >= b[x]
          then go to L2045
        go to L2047

L2031:  0 -> a[x]
        f -> a[x]
        a + 1 -> a[x]
        a + c -> a[x]
        if n/c go to L2037	; negative exponent, force SCI
        go to L2047

L2037:  0 -> c[s]
        c + 1 -> c[s]
        b exchange c[s]
L2042:  0 -> a[x]
        f -> a[x]
        go to L2047

L2045:  a exchange b[x]
        a - 1 -> a[x]
L2047:  register -> c 14
        jsb S2213
        if b[s] = 0
          then go to L2177
L2053:  p - 1 -> p
L2054:  jsb S2221
        if c[s] = 0
          then go to L2071
        if b[s] = 0
          then go to L2202
        c + 1 -> c[x]
        if c[xs] = 0
          then go to L2070
        c - 1 -> c[xs]
        if c[xs] = 0
          then go to L2173
        c + 1 -> c[xs]
L2070:  shift right c[ms]
L2071:  jsb S2227
        if b[s] = 0
          then go to L2150
        a exchange b[s]
        a - 1 -> a[s]
        if a[s] # 0		; ENG mode?
          then go to L2103	;   yes
        if a[xs] # 0		; exponent negative
          then go to L2130	;   yes
        go to L2133

L2103:  0 -> a[s]
        b exchange c[x]
        0 -> c[x]
        p <- 2
        load constant 1
        c - 1 -> c[x]
        a + c -> a[x]
        0 -> c[x]
        load constant 3		; divide exponent by 3 by repeated subtraction
L2114:  a - c -> a[x]
        if n/c go to L2114
        a + c -> a[x]		; restore from underflow
        shift right c[x]
L2120:  a - c -> a[x]
        if n/c go to L2120
        a + c -> a[x]
        b -> c[x]
L2124:  a - 1 -> a[x]
        if n/c go to L2136
        if c[xs] = 0
          then go to L2132
L2130:  0 - c -> c[x]
        c - 1 -> c[xs]
L2132:  c -> a[x]
L2133:  p <- 3
        shift left a[wp]
        go to L2162

L2136:  c - 1 -> c[x]
        a + 1 -> a[s]
        if n/c go to L2124
L2141:  if c[ms] = 0
          then go to L2037
L2143:  shift right a[w]
        c + 1 -> c[x]
        if c[x] # 0
          then go to L2143
        go to L2157

L2150:  if a[xs] # 0
          then go to L2141
        go to L2155

L2153:  a + 1 -> a[s]
        a - 1 -> a[x]
L2155:  if a[x] # 0
          then go to L2153
L2157:  binary
        0 -> a[x]
        a - 1 -> a[x]
L2162:  rotate left a
        f exchange a[x]
        shift right a[w]
        f -> a[x]
        register -> c 14
        c -> a[s]
        b exchange c[w]
        b -> c[w]
        return

L2173:  register -> c 14
        c -> a[w]
        0 -> a[s]
        go to L2133

L2177:  if c[xs] # 0
          then go to L2054
        go to L2053

L2202:  c + 1 -> c[x]
        p - 1 -> p
        go to L2070

S2205:  p <- 1
        load constant 1
        c -> data address
        b -> c[w]
        c -> register 14
        return

S2213:  0 -> c[s]
        p <- 13
L2215:  p - 1 -> p
        a - 1 -> a[x]
        if n/c go to L2215
        return

S2221:  0 -> a[w]
        c -> a[wp]
        a + c -> a[ms]
        0 -> a[wp]
        a exchange c[ms]
        return

S2227:  c -> a[ms]
        binary
        a - 1 -> a[wp]
        c -> a[x]
        decimal
        return

; Entry point: get status register (addr 0x1e) into C

S2235:  p <- 1
        load constant 2
        c -> data address
        register -> c 14
        return

S2242:  0 -> s 14		; get trig mode
        m1 exchange c
        jsb S2235
        if c[p] = 0
          then go to L2255
        c - 1 -> c[x]
        if c[p] = 0
          then go to L2254
        1 -> s 14
        go to L2255

L2254:  1 -> s 0
L2255:  m1 -> c
        p <- 12
        return

; Entry point

L2260:  b exchange c[w]		; x bar
        delayed rom @05
        jsb S2465
        register -> c 10
        b exchange c[w]
        if b[m] = 0
          then go to L3034
        register -> c 13
L2270:  a exchange c[w]
        register -> c 10
        delayed rom @05
        jsb divax0
        if 1 = s 13
          then go to L3032
        1 -> s 13
        stack -> a
        c -> stack
        register -> c 11
        go to L2270

S2303:  c + 1 -> c[x]
        if c[xs] = 0
          then go to L2311
        0 -> c[x]
        p <- 0
        load constant 2
L2311:  c - 1 -> c[x]
        return

; Entry point

L2313:  jsb S2303
        if a[x] # 0
          then go to L2317
        a + 1 -> a[x]
L2317:  a - 1 -> a[x]
        a - c -> a[x]
        if n/c go to L2324
        a - 1 -> a[x]
        a - 1 -> a[x]
L2324:  a + 1 -> a[x]
        a exchange c[x]

; Entry point

L2326:  decimal
        if c[x] = 0
          then go to L2360
        0 -> c[xs]
        0 -> c[ms]
        jsb S2303
        c + 1 -> c[x]
        0 - c - 1 -> c[x]
        a exchange c[x]
        0 -> a[ms]
        shift left a[x]
        shift left a[w]
        shift left a[w]
        p <- 3
        load constant 7
        go to L2350

L2346:  binary
        a + 1 -> a[x]
L2350:  decimal
        a - c -> a[ms]
        if n/c go to L2346
        a + c -> a[ms]
        shift left a[x]
        a exchange c[w]
        load constant 2
        shift right c[w]
L2360:  c -> a[w]
        delayed rom @14
        go to L6171

; Entry point

S2363:  decimal
        0 -> c[ms]
        0 -> a[w]
        if c[x] = 0
          then go to L2411
        p <- 13
        load constant 1
        load constant 0
        load constant 6
        a exchange c[ms]
        p <- 11
        load constant 7
        p <- 0
L2400:  a - c -> a[ms]
        c - 1 -> c[p]
        if n/c go to L2400
        p <- 11
        load constant 1
L2405:  a - c -> a[ms]
        c - 1 -> c[xs]
        if n/c go to L2405
        shift left a[ms]
L2411:  p <- 11
        binary
        a - 1 -> a[wp]
        return

; Entry point
divax0: if c[m] = 0
          then go to L3034
        delayed rom @06
        go to L3122

S2421:  delayed rom @06
        go to L3263

S2423:  a exchange c[w]
S2424:  if 0 = s 13
          then go to L2427
S2426:  0 - c - 1 -> c[s]
L2427:  delayed rom @06
        go to addax

S2431:  jsb S2436
        c -> data
        return

S2434:  delayed rom @06
        go to mulax

; Entry point

S2436:  if c[m] # 0
          then go to S2441
        0 -> c[w]
S2441:  if c[xs] = 0
          then go to L2451
        decimal
        c - 1 -> c[x]
        c + 1 -> c[xs]
        c - 1 -> c[xs]
        if n/c go to L2452
        c + 1 -> c[x]
L2451:  return

L2452:  p <- 12
        c + c -> c[xs]
        if n/c go to L2457
        0 -> c[w]
        go to L2463

L2457:  0 -> c[wp]
        c - 1 -> c[wp]
        0 -> c[xs]
        1 -> s 11
L2463:  p <- 13
        return

S2465:  p <- 1
        load constant 0
        c -> data address
        return

; Entry points

L2471:  1 -> s 13		; Sigma-
L2472:  m1 exchange c		; Sigma+
        jsb S2465
        register -> c 11
        a exchange c[w]
        m1 -> c
        jsb S2424
        jsb S2431
        m1 -> c
        c -> a[w]
        jsb S2434
        a exchange c[w]
        register -> c 12
        jsb S2423
        jsb S2431
        register -> c 13
        y -> a
        jsb S2423
        jsb S2431
        y -> a
        a exchange c[w]
        c -> a[w]
        jsb S2434
        a exchange c[w]
        register -> c 14
        jsb S2423
        jsb S2431
        y -> a
        m1 -> c
        jsb S2434
        a exchange c[w]
        register -> c 15
        jsb S2423
        jsb S2431
        0 -> c[w]
        p <- 12
        c + 1 -> c[p]
        a exchange c[w]
        register -> c 10
        jsb S2423
        jsb S2431
        0 -> s 11
        delayed rom @00
        go to L0065

; Entry point

L2545:  m1 exchange c		; s
        jsb S2465
        0 -> c[w]
        p <- 12
        c + 1 -> c[p]
        a exchange c[w]
        register -> c 10
        jsb S2426
        b exchange c[w]
        b -> c[w]
        m1 exchange c
        if b[m] = 0
          then go to L3034
        if b[s] = 0
          then go to L3034
        register -> c 13
L2565:  c -> a[w]
        jsb S2434
        register -> c 10
        jsb divax0
        register -> c 12
        if 1 = s 13
          then go to L2575
        register -> c 14
L2575:  jsb S2426
        m1 -> c
        jsb divax0
        0 -> c[s]
        jsb S2421
        if 1 = s 13
          then go to L3032
        1 -> s 13
        jsb S2436
        stack -> a
        c -> stack
        register -> c 11
        go to L2565

; Entry point

L2612:  0 -> c[w]		; isz, or dsz if s13=1
        p <- 12			; construct constant 1.0
        c + 1 -> c[p]
        a exchange c[w]
        jsb S2423		; add/sub based on s13
        jsb S2431		; write back to register 0
        if c[xs] = 0
          then go to L2623
        0 -> c[w]
L2623:  delayed rom @15		; skip if result is zero
        go to L6546

; Entry point - display/print error

L2625:  jsb S2741		; get status reg, check printer mode
        p <- 4			; if status[4] # 0, MAN mode, display only
        if c[p] # 0
          then go to L2632
        jsb S2712		; print error

; Entry point - display error

L2632:  0 -> b[w]
        0 -> c[w]
        0 -> s 2
        p <- 13
        load constant 14	; E
        load constant 10	; r
        load constant 10	; r
        load constant 12	; o
        load constant 10	; r
        binary
        c - 1 -> c[wp]
        a exchange c[w]

        display off		; turn on display
        display toggle

        p <- 2			; loop 1024 times for delay
        load constant 4
L2652:  c - 1 -> c[x]
        if n/c go to L2652

        display toggle		; flush PICK keyboard buffer
        a exchange b[w]
        a - 1 -> a[p]
L2657:  jsb get_pick_keycode
        a - 1 -> a[p]
        if n/c go to L2657
        a exchange b[w]
        display toggle

L2664:  1 -> s 0		; enable program mode key (19C)
        0 -> s 3
        if 1 = s 3		; program mode?
          then go to L2674
        0 -> s 0		; disable program mode key (19C)

        pick key?		; key pressed?
        if 0 = s 3
          then go to L2664	;   no, loop

L2674:  0 -> s 0		; disable program mode key (19C)
        nop
        0 -> s 3
        pick key?		; key pressed?
        if 1 = s 3
          then go to L2706
        1 -> s 0		; enable program mode key (19C)
        nop
        if 1 = s 3		; program mode?
          then go to L2674

L2706:  display toggle		; key was pressed
        jsb get_pick_keycode		; get keycode from PIK
        delayed rom @00
        go to L0062

S2712:  0 -> c[w]		; print "ERROR"?
        binary
        p <- 11
        c - 1 -> c[w]
        load constant 14
        load constant 15
        load constant 11
        load constant 14
        load constant 15
        load constant 8
        load constant 5
        load constant 1
        load constant 4
        load constant 3
        load constant 1
        load constant 4
        delayed rom @03		; print sixbit message
        go to L1402

; 11 111111 111011 111011 111011 111000 010100 010100 001100 010100
;      end   blank  blank  blank    E      R      R      O      R


get_pick_keycode:
	0 -> c[w]		; get keycode from PIK
        c - 1 -> c[w]
        c -> data address
        register -> c 15
        return

; get printer mode switch, save in status register
	
S2741:  delayed rom @04		; get status register
        jsb S2235
        0 -> s 0		; disable printer mode switch
        0 -> a[w]
L2745:  0 -> s 15
        if 1 = s 15		; wait for keycode register to be empty
          then go to L2745	;   (not column 2 time)
        1 -> s 0		; enable printer mode switch
L2751:  p <- 4
        if 0 = s 15		; wait for keycode register to fill
          then go to L2751
        keys -> a		; get keycode - a[x] = 0rrr rccc 0000
        shift left a[x]		; a[xs] = rccc
        a exchange c[wp]	; c[xs] = rccc
        c + c -> c[xs]		; a[xs] = ccc0
        c + c -> c[xs]		; a[xs] = cc00 - carry set if ccc was 4..7
        if n/c go to L2764
        load constant 1		; if col was 4..7 (MAN mode), set c[4] = 1
        go to L2771

L2764:  p <- 3			; set c[3] = 1 (assume TRACE mode)
        load constant 1
        c + c -> c[xs]		; if col was 2 or 3, (NORM mode) set c[3] to 0
        if n/c go to L2771
        c - 1 -> c[m]		; set c[3] = 0
L2771:  a exchange c[x]		; write updated status register back
        c -> register 14

        delayed rom @04		; get status register
        jsb S2235

        p <- 3
        0 -> s 0		; disable printer mode switch
        return

;------------------------------------------------------------------
; Start of math package (almost same as 67/97)
;------------------------------------------------------------------

; Entry point: 1/x

S3000:  0 -> a[w]		; compare 67/97 S2636
        p <- 12
        a + 1 -> a[p]
        if c[m] = 0
          then go to L3034
        go to L3122

; Entry point: advance PC

L3006:  m2 -> c
        c - 1 -> c[xs]
        if n/c go to incpc8
        p <- 2
        load constant 6
        p <- 0
        c - 1 -> c[p]
        if n/c go to incpc8
        p <- 1
        if c[p] = 0
          then go to incpc7
        1 -> s 11
incpc7: load constant 2
        load constant 13
incpc8: delayed rom @00
        go to incpc9

; Entry point: percent

percent:
	y -> a
        a - 1 -> a[x]
        a - 1 -> a[x]
        jsb mulax
L3032:  delayed rom @00
        go to L0070

; following not in 67/97
L3034:  delayed rom @02
        go to err0
; above not in 67/97

; 67/97 has additional code here for %change and factorial

; Entry points

mulxy:  stack -> a		; multiply
mulax:  0 -> b[w]
        a exchange b[m]
S3041:  jsb S3055
        jsb S3112
S3043:  p <- 12
        0 -> b[w]
        a -> b[x]
        a + b -> a[wp]
        if n/c go to L3052
        c + 1 -> c[x]
        a + 1 -> a[p]
L3052:  a exchange c[m]
        c -> a[w]
        return

S3055:  a + c -> c[x]
        p <- 3
        a - c -> c[s]
        if n/c go to L3062
        0 - c -> c[s]
L3062:  0 -> a[w]
        go to mpy100

S3064:  p <- 0
        go to L3062

mpy90:  a + b -> a[w]
mpy100: c - 1 -> c[p]
        if n/c go to mpy90
        if p = 12
          then go to L3100
        p + 1 -> p
        shift right a[w]
        go to mpy100

L3076:  c + 1 -> c[x]
        shift right a[w]
L3100:  return

S3101:  a exchange b[w]
S3102:  jsb S3064
        m1 -> c
        go to S3112

S3105:  m1 exchange c
        b -> c[w]
        jsb S3064
        m1 -> c
        c + c -> c[x]
S3112:  if a[s] # 0
          then go to L3076
        return

; 67/97 has a subroutine to save lastx here

; Entry point: square

S3115:  c -> a[w]
        go to mulax

; Entry point

S3117:  if c[m] = 0		; divide
          then go to L3034
        stack -> a
L3122:  jsb S3124
        go to S3043

S3124:  0 -> b[w]
        b exchange c[m]
S3126:  a - c -> c[s]
        if n/c go to L3131
        0 - c -> c[s]
L3131:  a - c -> c[x]
        0 -> a[x]
        0 -> a[s]
S3134:  0 -> c[m]
        p <- 12
        go to div140

div130: c + 1 -> c[p]
div140: a - b -> a[w]
        if n/c go to div130
        a + b -> a[w]
        p - 1 -> p
        if p # 2
          then go to L3155
        a + 1 -> a[ms]
        b exchange c[x]
        0 -> c[x]
        go to L3153

L3152:  a - 1 -> a[ms]
L3153:  if a >= b[w]
          then go to L3152
L3155:  shift left a[w]
        if p # 13
          then go to div140
        0 -> a[w]
        a exchange c[w]
        a exchange c[s]
        b exchange c[x]
        go to S3237

S3165:  0 -> a[w]
        a + 1 -> a[s]
        0 - c -> c[x]
        shift right a[w]
        go to S3134

; Entry point

addxy:  stack -> a
addax:  jsb add
        go to S3043

add:    p <- 12
        0 -> b[w]
        a + 1 -> a[xs]
        a + 1 -> a[xs]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        if a >= c[x]
          then go to add4
        a exchange c[w]
add4:   a exchange c[m]
        if c[m] = 0
          then go to add5
        a exchange c[w]
add5:   b exchange c[m]
add6:   if a >= c[x]
          then go to add1
        shift right b[w]
        a + 1 -> a[x]
        if b[w] = 0
          then go to add1
        go to add6

add1:   c - 1 -> c[xs]
        c - 1 -> c[xs]
        0 -> a[x]
        a - c -> a[s]
        if a[s] # 0
          then go to add13
        a + b -> a[w]
        if n/c go to S3112
add13:  if a >= b[m]
          then go to add14
        0 - c - 1 -> c[s]
        a exchange b[w]
add14:  a - b -> a[w]

; Entry point
; normalize a 13-digit floating point result
; compare S3235 in 67/97, L2745 in 27
S3237:  p <- 12
        if a[wp] # 0
          then go to L3250
        0 -> c[x]
L3243:  return

; The 67/97 originally didn't have the binary and decimal set, so they
; were added later as a patch routine. Here they're inline.
L3244:  binary
        a + 1 -> a[s]
        decimal
        c - 1 -> c[x]
L3250:  if a[p] # 0
          then go to L3243
        shift left a[wp]
        go to L3244

S3254:  if 0 = s 4
          then go to L3257
        0 - c - 1 -> c[s]
L3257:  jsb S3237
        go to S3043

; Entry point: square root

sqrt:	if c[s] # 0
          then go to L3034
L3263:  0 -> a[w]
        a exchange c[m]
        jsb sqrt_sub
        go to L3257

sqrt_sub:
	a -> b[w]
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

; Entry point
; rcl_sigma code slightly different than 67/97 due to stat registers
; being in RAM block 0 rather than block 3

rcl_sigma:
	0 -> c[w]
        c -> data address
        register -> c 13
        stack -> a
        c -> stack
        register -> c 11
        go to L3032

; Entry point

; H/HMS conversions - to H if s8=0, to HMS if s8=1
hms_conv:
	b exchange c[w]
        jsb hms_conv_sub
        go to L3032

; following code not in 67/97
        p <- 0
        a exchange c[p]
        if c[xs] # 0
          then go to L3360
        a exchange c[x]
        shift left a[x]
        a exchange c[x]
        delayed rom @01
        go to L0616
; above code not in 67/97

L3360:  0 -> c[xs]
        0 -> s 8
        delayed rom @04
        go to L2326

        nop
        nop

hmsm20: a + c -> a[wp]
        shift right c[wp]
        if c[wp] # 0
          then go to hmsm20
        return

hms_conv_sub:
	if b[m] = 0
          then go to hms120
        p <- 12
        b -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
        if c[xs] # 0
          then go to L3451
hms110: p - 1 -> p
        if p # 0
          then go to hms130
hms120: b -> c[w]
        return

hms130: c - 1 -> c[x]
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

hms150: p + 1 -> p
        jsb hmsmp
        p - 1 -> p
hms160: p - 1 -> p
        jsb hmsmp
        c -> a[w]
        b -> c[w]
        go to L3447

hrs100: 0 -> a[w]
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
        jsb S3112
L3447:  delayed rom @06
        go to L3257

L3451:  if b[xs] = 0
          then go to hms120
        go to hms140

hmsdv:  shift right c[wp]
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

; entry for e^x

e_to_x: 0 -> a[w]
        a exchange c[m]
L3474:  b exchange c[w]
        delayed rom @10
        jsb lnc10
        b exchange c[w]
        1 -> s 8
        jsb S3572
        b exchange c[w]
L3503:  jsb S3661
        b exchange c[w]
        jsb S3560
        if p # 5
          then go to L3503
        p <- 13
        load constant 7
        a exchange c[s]
        b exchange c[w]
        go to L3520

L3515:  a -> b[w]
        c - 1 -> c[s]
        if n/c go to L3534
L3520:  shift right a[wp]
        a exchange c[w]
        shift left a[ms]
        a exchange c[w]
        a - 1 -> a[s]
        if n/c go to L3515
        a exchange b[w]
        a + 1 -> a[p]
        delayed rom @06
        jsb S3254
        go to L3616

L3533:  shift right a[wp]
L3534:  a - 1 -> a[s]
        if n/c go to L3533
        0 -> a[s]
        a + b -> a[w]
        a + 1 -> a[p]
        if n/c go to L3515
        shift right a[wp]
        a + 1 -> a[p]
        if n/c go to L3520

; Entry point

L3545:  a exchange c[w]
        delayed rom @10
        jsb lnc10
        b exchange c[w]
        0 -> c[w]
L3552:  a exchange c[w]
        delayed rom @06
        jsb S3055
        0 -> c[m]
        go to L3474

L3557:  c + 1 -> c[s]
S3560:  a - b -> a[w]
        if n/c go to L3557
        a + b -> a[w]
        shift left a[w]
        shift right c[ms]
        b exchange c[w]
        p - 1 -> p
        return

L3570:  c + 1 -> c[x]
        shift right a[w]
S3572:  if c[xs] = 0
          then go to L3633
        if a[s] # 0
          then go to L3570
        0 - c -> c[x]
        if c[xs] = 0
          then go to L3621
        0 -> c[m]
        0 -> a[w]
        c + c -> c[x]
        if n/c go to L3623
L3605:  0 -> c[wp]
        if c[s] # 0
          then go to L3615
        c - 1 -> c[w]
        0 -> c[xs]
        1 -> s 11
        if 1 = s 4
          then go to L3616
L3615:  0 -> c[s]
L3616:  delayed rom @00
        go to L0070

L3620:  shift right a[w]
L3621:  c - 1 -> c[x]
        if n/c go to L3620
L3623:  0 -> c[x]
L3624:  if c[s] = 0
          then go to L3631
        a exchange b[w]
        a - b -> a[w]
        0 - c - 1 -> c[x]
L3631:  0 -> c[ms]
        return

L3633:  a exchange c[w]
        shift left a[wp]
        shift left a[wp]
        shift left a[wp]
        a exchange c[w]
        go to L3642

L3641:  c + 1 -> c[x]
L3642:  a - b -> a[w]
        if n/c go to L3641
        a + b -> a[w]
        c - 1 -> c[m]
        if n/c go to L3650
        go to L3624

L3650:  a exchange c[w]
        shift left a[x]
        a exchange c[w]
        shift left a[w]
        if 0 = s 8
          then go to L3642
        if c[xs] # 0
          then go to L3605
        go to L3642

S3661:  0 -> c[w]
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

; following code not in 67/97
; Entry point

S3760:  a exchange c[w]
        p <- 1
        load constant 1
        c -> data address
        register -> c 14
        decimal
        p <- 13
        c + c -> c[s]
        if n/c go to L3773
        load constant 9
        go to L3774

L3773:  load constant 0
L3774:  a exchange c[w]
        binary
        return

; above code not in 67/97

; 67/97 has a block of bank select instructions inserted here

lnc2:   p <- 11			; load ln(2)
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

; 67/97 has code inserted here

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

; Entry point: logarithm (s6=0 for natural log, 1 for log base 10)

L4036:  p <- 12
        if c[w] = 0
          then go to L4163
        if c[s] # 0
          then go to L4201
; 67/97 saves LASTx here
L4043:  if c[x] = 0
          then go to L4237
        c + 1 -> c[x]
        0 -> a[w]
        a - c -> a[m]
        if c[x] = 0
          then go to L4255
L4052:  shift right a[wp]
        a -> b[s]
        p <- 13
L4055:  p - 1 -> p
        a - 1 -> a[s]
        if n/c go to L4055
        a exchange b[s]
        0 -> c[ms]
        go to L4066

L4063:  shift right a[w]
        c + 1 -> c[p]
L4065:  a exchange b[s]
L4066:  a -> b[w]
        binary
        a + c -> a[s]
        m1 exchange c
        a exchange c[s]
        shift left a[w]
L4074:  shift right a[w]
        c - 1 -> c[s]
        if n/c go to L4074
        decimal
        m1 exchange c
        a + b -> a[w]
        shift left a[w]
        a - 1 -> a[s]
        if n/c go to L4063
        c -> a[s]
        a - 1 -> a[s]
        a + c -> a[s]
        if n/c go to L4114
L4111:  a exchange b[w]
        shift left a[w]
        go to L4126

L4114:  if p = 1
          then go to L4111
        c + 1 -> c[s]
        p - 1 -> p
        a exchange b[w]
        a exchange b[s]
        shift left a[w]
        go to L4065

L4124:  c - 1 -> c[s]
        p + 1 -> p
L4126:  b exchange c[w]
        delayed rom @07
        jsb S3661
        shift right a[w]
        b exchange c[w]
        go to L4135

L4134:  a + b -> a[w]
L4135:  c - 1 -> c[p]
        if n/c go to L4134
        if c[s] # 0
          then go to L4124
        if p = 12
          then go to L4261
        0 -> c[w]
        jsb S4333
L4145:  delayed rom @06
        jsb S3237
        0 -> a[s]
        if 0 = s 7
          then go to L4153
        0 - c - 1 -> c[s]
L4153:  if 1 = s 10
          then go to L4734
        if 1 = s 6		; base 10 log?
          then go to logb10	;   yes, adjust
L4157:  delayed rom @06
        jsb S3043
L4161:  delayed rom @00
        go to L0070

L4163:  if 0 = s 10
          then go to L4172
        stack -> a
        if a[m] # 0
          then go to L4174
L4170:  c -> stack
        a exchange c[w]
L4172:  delayed rom @02
        go to err0

L4174:  if a[s] # 0
          then go to L4170
        a exchange c[w]
; 67/97 saves LASTx here
        0 -> c[w]
        go to L4161

L4201:  if 0 = s 10
          then go to L4172
        stack -> a
        a -> b[w]
        if a[xs] # 0
          then go to L4170
        a + 1 -> a[x]
L4210:  a - 1 -> a[x]
        shift left a[ms]
        if a[m] # 0
          then go to L4233
        if a[x] # 0
          then go to L4226
        a exchange c[s]
        c -> a[s]
        c + c -> c[s]
        c + c -> c[s]
        a + c -> c[s]
        if c[s] = 0
          then go to L4227
        1 -> s 4
L4226:  0 -> c[s]
L4227:  b exchange c[w]
        c -> stack
        b exchange c[w]
        go to L4043

L4233:  if a[x] # 0
          then go to L4210
        a exchange b[w]
        go to L4170

L4237:  c -> a[w]
        a - 1 -> a[p]
        if a[m] # 0
          then go to L4245
        0 -> c[w]
        go to L4153

L4245:  delayed rom @06
        jsb S3237
        delayed rom @06
        jsb S3124
        a + c -> a[s]
        a - 1 -> a[s]
L4253:  0 -> c[x]
        go to L4052

L4255:  1 -> s 7
        delayed rom @06
        jsb S3237
        go to L4253

L4261:  if c[x] = 0
          then go to L4145
        c - 1 -> c[w]
        b exchange c[w]
        0 -> b[m]
        jsb lnc10
        a exchange c[w]
        a - c -> c[w]
        if b[xs] = 0
          then go to L4274
        a - c -> c[w]
L4274:  a exchange c[w]
        b exchange c[w]
        if c[xs] = 0
          then go to L4301
        0 - c - 1 -> c[w]
L4301:  a exchange c[wp]
L4302:  p - 1 -> p
        shift left a[w]
        if p # 1
          then go to L4302
        p <- 12
        if a[p] # 0
          then go to L4322
        shift left a[m]
L4312:  a exchange c[w]
        a exchange c[s]
        delayed rom @06
        jsb mpy100
        delayed rom @06
        jsb S3112
        0 -> c[m]
        go to L4153

L4322:  a + 1 -> a[x]
        p - 1 -> p
        go to L4312

logb10: b exchange c[w]		; convert ln result to log base 10
        jsb lnc10
        b exchange c[w]
        delayed rom @06
        jsb S3134
        go to L4157

S4333:  p + 1 -> p
S4334:  c - 1 -> c[x]
        if p # 12
          then go to S4333
        return

; following subroutine not present in 67/97

S4340:  p <- 1
        load constant 1
        c -> data address
        m1 -> c
        c -> register 15
        delayed rom @04
        go to L2255

        nop

; Entry point: rectangular to polar conversion

r_to_p: y -> a
        delayed rom @04
        jsb S2242
        if c[m] = 0
          then go to L4462
        if c[s] = 0
          then go to L4362
        1 -> s 7
        1 -> s 10
        0 -> c[s]
L4362:  delayed rom @06
        jsb S3124
        0 -> a[s]
L4365:  delayed rom @05
        jsb S2441
        0 -> s 11
        if p # 13
          then go to L4466
        if c[w] # 0
          then go to inv_trig
        stack -> a
        register -> c 15
        c -> stack
        0 -> c[w]

; Entry point: inverse trig functions
; s 6 set for arcsin
; s 10 set for arccos
; neither set for arctan

inv_trig:
	0 -> a[w]
        delayed rom @04
        jsb S2242
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
          then go to L4607
; 67/97 has call to conditionally save X to LASTx here
        if 0 = s 6
          then go to L4620
        jsb S4730
        0 -> c[w]
        a -> b[w]
        b exchange c[w]
        shift right a[w]
        a + 1 -> a[p]
        0 - c -> c[wp]
        if n/c go to L4447
        a exchange b[w]
        a exchange c[w]
        delayed rom @06
        jsb S3237
        m1 exchange c
        a exchange c[w]
        delayed rom @06
        jsb S3102
        c - 1 -> c[x]
        delayed rom @06
        jsb sqrt_sub
L4447:  b exchange c[w]
        a exchange b[w]
        register -> c 15
        a exchange c[w]
        delayed rom @06
        jsb S3126
        0 -> a[s]
        if c[xs] # 0
          then go to L4620
        a exchange b[w]
        go to L4614

L4462:  c + 1 -> c[xs]
        a exchange c[s]
        if a[w] # 0
          then go to L4365
L4466:  a exchange b[w]
        stack -> a
        b exchange c[w]
        c -> stack
        b exchange c[w]
        delayed rom @06
        jsb S3105
        delayed rom @13
        jsb S5533
        a exchange b[w]
        a exchange c[w]
        register -> c 15
        delayed rom @06
        jsb S3041
        stack -> a
        c -> stack
        m1 -> c
        go to L4405

; 67/97 has a subroutine inserted here to conditionally save lastx

L4510:  a -> b[w]
        if b[w] = 0
          then go to L4526	; has part of 67/97 inverse trig fix
        a - 1 -> a[p]
        if a[w] # 0
          then go to L4612
        a exchange b[w]		; missing second part of 67/97 inverse trig fix, which replaces this with "a exchange c[w]"
        if 0 = s 6
          then go to L4524
        jsb toggle_s10
        0 -> c[w]
        go to L4526

L4524:  delayed rom @12
        jsb trc10
L4526:  a exchange c[w]
; 67/97 has call to conditionally save X to LASTx here
        0 -> c[w]
L4530:  delayed rom @10
        jsb S4334
L4532:  b exchange c[w]
        delayed rom @12
        jsb trc10
        c + c -> c[w]
        shift right c[w]
        b exchange c[w]
        if 0 = s 10
          then go to L4554
        jsb S4731
        b exchange c[w]
        a exchange c[w]
        a - c -> c[w]
        a exchange c[w]
        b exchange c[w]
        0 -> c[w]
        delayed rom @06
        jsb S3237
        0 -> a[s]
L4554:  if 0 = s 7
          then go to L4560
        jsb S4731
        a + b -> a[w]
L4560:  0 -> c[s]
        if 1 = s 0
          then go to L4575
        c + 1 -> c[x]
        c + 1 -> c[x]
        delayed rom @06
        jsb S3134
        0 -> a[s]
        if 1 = s 14
          then go to L4575
        a -> b[w]
        shift right b[w]
        a - b -> a[w]
L4575:  delayed rom @06
        jsb S3254
        if 1 = s 13
          then go to L4161
        stack -> a
        c -> stack
        0 -> a[s]
        a exchange c[w]
        delayed rom @00
        go to L0070

L4607:  if c[x] = 0
          then go to L4510
        a exchange b[w]
L4612:  if 1 = s 6
          then go to L4172
L4614:  delayed rom @06
        jsb S3165
        0 -> a[s]
        jsb toggle_s10
L4620:  p <- 12
        m1 exchange c
        m1 -> c
        0 -> c[ms]
L4624:  c + 1 -> c[x]
        if c[x] = 0
          then go to L4635
        c + 1 -> c[s]
        p - 1 -> p
        if p # 6
          then go to L4624
        m1 -> c
        go to L4532

L4635:  m1 exchange c
        0 -> c[w]
        c + 1 -> c[s]
        shift right c[w]
        go to L4656

L4642:  a exchange c[w]
        m1 exchange c
        c + 1 -> c[p]
        c -> a[s]
        m1 exchange c
L4647:  shift right b[w]
        shift right b[w]
        a - 1 -> a[s]
        if n/c go to L4647
        0 -> a[s]
        a + b -> a[w]
        a exchange c[w]
L4656:  a -> b[w]
        a - c -> a[w]
        if n/c go to L4642
        m1 exchange c
        c + 1 -> c[s]
        m1 exchange c
        a exchange b[w]
        shift left a[w]
        p - 1 -> p
        if p # 6
          then go to L4656
        b exchange c[w]
        delayed rom @06
        jsb S3134
        go to L4676

L4675:  shift right a[wp]
L4676:  a - 1 -> a[s]
        if n/c go to L4675
        0 -> a[s]
        0 -> c[x]
        m1 exchange c
        p <- 7
L4704:  b exchange c[w]
        jsb S4740
        b exchange c[w]
        go to L4711

L4710:  a + b -> a[w]
L4711:  c - 1 -> c[p]
        if n/c go to L4710
        shift right a[w]
        0 -> c[p]
        if c[m] = 0
          then go to L4530
        p + 1 -> p
        go to L4704

toggle_s10:			; compare brts10 in 41C
	if 1 = s 10
          then go to clear_s10
        1 -> s 10
        return
clear_s10:
	0 -> s 10
        return

S4727:  shift right a[w]
S4730:  c + 1 -> c[x]
S4731:  if c[x] # 0
          then go to S4727
        return

L4734:  a exchange b[w]
        stack -> a
        delayed rom @07
        go to L3552

S4740:  0 -> c[w]
        c - 1 -> c[w]
        0 -> c[s]
        if p = 12
          then go to L4766
        if p = 11
          then go to L5007
        if p = 10
          then go to L5017
        if p = 9
          then go to L5025
        if p = 8
          then go to L5031
        p <- 0
L4756:  load constant 7
        p <- 7
        return

        nop
        nop
        nop
        nop
        nop

L4766:  p <- 10
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
        go to L5061

S5003:  load constant 6		; fill word to end with sixes
        if p = 0
          then go to L4756
        go to S5003

L5007:  p <- 8
        jsb S5003
        p <- 0
        load constant 5
        p <- 4
        load constant 8
        p <- 11
        return

L5017:  p <- 6
        jsb S5003
        p <- 0
        load constant 9
        p <- 10
        return

L5025:  p <- 4
        jsb S5003
        p <- 9
        return

L5031:  p <- 2
        jsb S5003
        p <- 8
        return

S5035:  0 -> c[w]		; load 180/4
        p <- 12
        load constant 4
        load constant 5
        go to L5061

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
L5061:  p <- 12
        return

; Entry point: polar to rectangular conversion

p_to_r: 1 -> s 13
        1 -> s 6
        1 -> s 10
        stack -> a
        go to L5071

; Entry point: trigonometric functions
; s 6 set for sin
; s 10 set for cos
; neither set for tan

trig:   c -> a[w]
L5071:  delayed rom @04
        jsb S2242
        delayed rom @10
        jsb S4340
        a exchange c[w]
        0 -> a[w]
        0 -> b[w]
        a exchange c[m]
        if c[s] = 0
          then go to L5110
        1 -> s 7
        if 1 = s 10
          then go to L5107
        1 -> s 4
L5107:  0 -> c[s]
L5110:  b exchange c[w]
        if 1 = s 0
          then go to L5216
        if 0 = s 14
          then go to L5121
        a exchange c[w]
        c -> a[w]
        shift right c[w]
        a - c -> a[w]
L5121:  jsb S5035
        b exchange c[w]
        c - 1 -> c[x]
        if c[xs] # 0
          then go to L5132
        c - 1 -> c[x]
        if n/c go to L5132
        c + 1 -> c[x]
        shift right a[w]
L5132:  b exchange c[w]
L5133:  m1 exchange c
        m1 -> c
        c + c -> c[w]
        c + c -> c[w]
        c + c -> c[w]
        shift right c[w]
        b exchange c[w]
        if c[xs] # 0
          then go to L5163
        delayed rom @07
        jsb S3572
        0 -> c[w]
        b exchange c[w]
        m1 -> c
        c + c -> c[w]
        shift left a[w]
        if 0 = s 0
          then go to L5157
        shift right a[w]
        shift right c[w]
L5157:  b exchange c[w]
L5160:  a - b -> a[w]
        if n/c go to L5174
        a + b -> a[w]
L5163:  b exchange c[w]
        m1 -> c
        b exchange c[w]
        if 0 = s 0
          then go to L5226
        if c[x] # 0
          then go to L5225
        shift left a[w]
        go to L5226

L5174:  if 0 = s 10
          then go to L5205
        0 -> s 10
L5177:  if 1 = s 4
          then go to L5203
        1 -> s 4
        go to L5160

L5203:  0 -> s 4
        go to L5160

L5205:  1 -> s 10
        if 0 = s 6
          then go to L5177
        if 0 = s 7
          then go to L5214
        0 -> s 7
        go to L5160

L5214:  1 -> s 7
        go to L5160

L5216:  jsb trc10
        go to L5133

L5220:  a exchange b[w]
        a - b -> a[w]
        delayed rom @11
        jsb toggle_s10
        go to L5233

L5225:  c + 1 -> c[x]
L5226:  if c[xs] # 0
          then go to L5235
        a - b -> a[w]
        if n/c go to L5220
        a + b -> a[w]
L5233:  delayed rom @06
        jsb S3237
L5235:  0 -> a[s]
        if 1 = s 0
          then go to L5252
        b exchange c[w]
        m1 -> c
        b exchange c[w]
        delayed rom @06
        jsb S3134
        0 -> a[s]
        m1 exchange c
        jsb trc10
        delayed rom @06
        jsb S3101
L5252:  c - 1 -> c[x]
        m1 exchange c
        m1 -> c
        c + 1 -> c[x]
        if n/c go to L5316
        shift left a[w]
        go to L5320

L5261:  0 -> c[w]
        0 -> a[w]
        a + 1 -> a[p]
L5264:  delayed rom @06
        jsb S3254
        go to L5311

L5267:  p <- 12
        m1 -> c
        if 1 = s 10
          then go to L5510
        if 0 = s 13
          then go to L5264
        b exchange c[w]
        register -> c 15
        delayed rom @13
        jsb S5571
        c -> stack
        register -> c 15
        a exchange b[w]
        delayed rom @06
        jsb S3041
L5306:  if 0 = s 4
          then go to L5311
        0 - c - 1 -> c[s]
L5311:  delayed rom @00
        go to L0070

L5313:  p - 1 -> p
        if p = 6
          then go to L5267
L5316:  c + 1 -> c[x]
        if n/c go to L5313
L5320:  0 -> c[w]
        b exchange c[w]
L5322:  delayed rom @11
        jsb S4740
        b exchange c[w]
        delayed rom @07
        jsb S3560
        if p # 6
          then go to L5322
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
          then go to L5374
        c - 1 -> c[s]
        0 -> a[s]
        shift right a[w]
        go to trg370

L5373:  c + 1 -> c[x]
L5374:  c - 1 -> c[s]
        if n/c go to L5373
        0 -> c[s]
        m1 exchange c
        a exchange c[w]
        a - 1 -> a[w]
        m1 -> c
        if 1 = s 10
          then go to L5407
        0 - c -> c[x]
        a exchange b[w]
L5407:  if b[w] = 0
          then go to L5473
        delayed rom @06
        jsb S3134
        0 -> a[s]
        if 0 = s 6
          then go to L5264
        a exchange c[w]
; code diverges from 67/97 here:
        c -> register 14
        a exchange c[w]
        a exchange b[w]
        delayed rom @06
        jsb S3105
        jsb S5533
        b exchange c[w]
        a exchange b[w]
        if 0 = s 13
          then go to L5460
        register -> c 15
        a exchange c[w]
        delayed rom @06
        jsb S3126
        a exchange c[w]
        m1 exchange c
        a + c -> c[x]
        c -> stack
        m1 -> c
        a exchange c[w]
        jsb S5567
        stack -> a
        c -> stack
        register -> c 15
        a exchange c[s]
        register -> c 14
        a exchange c[w]
        m1 exchange c
        delayed rom @06
        jsb S3101
        delayed rom @06
        jsb S3043
        go to L5531

L5460:  m1 -> c
        a exchange c[w]
        a - c -> c[x]
        a exchange c[w]
        register -> c 14
        a exchange c[w]
        delayed rom @06
        jsb S3134
        0 -> c[s]
        delayed rom @12
        go to L5264

L5473:  0 -> c[w]			; compare 67/97 L5504
        if 1 = s 6
          then go to L5504
        c - 1 -> c[w]
        0 -> c[xs]
        1 -> s 11
        0 -> c[s]
        delayed rom @00
        go to L0070

L5504:  if 0 = s 13
          then go to L5261
        0 -> c[w]
        go to L5527

L5510:  if 1 = s 6
          then go to L5517
        a exchange b[w]
        delayed rom @06
        jsb S3165
        delayed rom @12
        go to L5264

L5517:  if 0 = s 13
          then go to L5261
        b exchange c[w]
        a exchange b[w]
        register -> c 15
        delayed rom @06
        jsb S3041
        jsb S5571
L5527:  c -> stack
        register -> c 15
L5531:  delayed rom @12
        go to L5306

S5533:  0 -> b[w]
        b exchange c[x]
        p <- 12
        b -> c[w]
        c + c -> c[x]
        if n/c go to L5555
        b -> c[w]
        delayed rom @11
        jsb S4727
L5544:  a + 1 -> a[p]
        if n/c go to L5550
        p + 1 -> p
        go to L5544

L5550:  delayed rom @06
        jsb S3112
L5552:  0 -> b[w]
        delayed rom @06
        go to sqrt_sub

L5555:  b -> c[w]
L5556:  c - 1 -> c[x]
        if n/c go to L5562
        b -> c[w]
        go to L5544

L5562:  p - 1 -> p
        if p # 0
          then go to L5556
        b -> c[w]
        go to L5552

S5567:  delayed rom @06
        jsb S3043
S5571:  if 0 = s 7
          then go to L5574
        0 - c - 1 -> c[s]
L5574:  delayed rom @05
        go to S2436

; rotate A left six digits - compare 67/97 S5710
S5576:  rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        return

; Entry point

L5605:  p <- 1			; compare 67/97 L5625
        c -> data address
        b exchange c[w]
        data -> c
        b exchange c[ms]
        b -> c[x]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        decimal
        0 - c - 1 -> c[xs]
        binary
        go to L5626

L5622:  p + 1 -> p		; compare 67/97 L5642
        p + 1 -> p
        shift left a[wp]
        shift left a[wp]
L5626:  c - 1 -> c[xs]
        if n/c go to L5622
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
        go to L5652

L5643:  c -> a[w]			; compare 67/97 L5663
        c -> data address
        data -> c
        p <- 11
        a exchange c[wp]
        rotate left a
        rotate left a
L5652:  a exchange c[w]			; compare 67/97 L5672
        p <- 0
        c -> data
        a exchange c[w]
        c - 1 -> c[p]
        if n/c go to L5643
        delayed rom @02
        go to L1370

; Entry point

L5662:  b exchange c[w]
        m1 exchange c
        m2 -> c
        if c[x] = 0
          then go to L5771
        p <- 1
L5670:  p - 1 -> p			; compare 67/97 L5730
        p - 1 -> p
        c - 1 -> c[xs]
        if n/c go to L5670
        c -> a[w]
        c -> data address
        data -> c
        a exchange c[w]
        shift left a[wp]
        shift left a[wp]
        p <- 1
        c -> a[wp]
        go to L5721

L5705:  c -> data address		; compare 67/97 L5745
        p <- 1
        b exchange c[wp]
        data -> c
        a exchange c[wp]
        jsb S5576
        jsb S5576
        c -> data address
        b -> c[wp]
        a exchange c[w]
        c -> data
        b -> c[w]
L5721:  p <- 0			; compare 67/97 L5760, which doesn't have p <- 0
        c - 1 -> c[wp]
        if n/c go to L5705
        a exchange c[w]
        c -> data address
        shift right c[w]
        shift right c[w]
        c -> data
        m1 -> c
        b exchange c[w]
        0 -> s 11
        delayed rom @02
        go to L1373

;------------------------------------------------------------------
; End of math package (almost same as 67/97)
;------------------------------------------------------------------

; Entry point: set trig angle mode

L5736:  delayed rom @04		; get status register
        jsb S2235
        shift right a[w]
        load constant 3
        p <- 0
L5743:  c - 1 -> c[p]
        a - 1 -> a[xs]
        if n/c go to L5743
        c -> data
        go to L5771

; Entry point

L5750:  if 0 = s 12
          then go to L5755
        delayed rom @07
        jsb S3760
        go to L5757

L5755:  delayed rom @04
        jsb S2000
L5757:  delayed rom @02
        jsb S1371
        display off
        display toggle
        0 -> c[w]
        p <- 2
        load constant 6
L5766:  c - 1 -> c[w]
        if n/c go to L5766
        display off
L5771:  delayed rom @00
        go to L0061

        nop
        nop
        nop
        nop
        nop

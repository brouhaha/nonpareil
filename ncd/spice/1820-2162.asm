; 1820-2162, 1MA4-0003 CPU ROM disassembly - quad 0 (@0000-@1777)
; used in 32E, 34C, 38C
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

         .arch woodstock

; externals:
L02000   .equ @02000
L02001   .equ @02001	; calculator-specific reset entry
L02002   .equ @02002
L02004   .equ @02004	; calculator-specific error_p entry
L02005   .equ @02005

	 .org @0000

; reset entry
         select rom go to L02001


; fixed entry points - note that some calculators bypass these and
; jump/call directly to the targets
x-ad2-10:  go to ad2-10
x-ad1-10:  go to ad1-10
x-ad2-13:  go to ad2-13
x-mp2-10:  go to mp2-10
x-mp1-10:  go to mp1-10
x-mp2-13:  go to mp2-13
x-dv2-10:  go to dv2-10
x-dv1-10:  go to dv1-10
x-dv2-13:  go to dv2-13
x-x/y13:   go to x/y13
x-sqr13:   go to sqr13


ad2-10:  0 -> b[w]
         a exchange b[m]
ad1-10:  m1 exchange c
         m1 -> c
         0 -> c[x]
ad2-13:  0 -> b[s]
         0 -> c[s]
         m1 exchange c
         p <- 1
add10:   p - 1 -> p
         a + 1 -> a[xs]
         c + 1 -> c[xs]
         if p # 12
           then go to add10
         b exchange c[w]
         if c[w] = 0
           then go to add60
         m1 exchange c
         a exchange b[w]
         if c[w] = 0
           then go to add60
add30:   if a >= b[x]
           then go to add90
add65:   a - b -> a[s]
         if a[s] # 0
           then go to add40
         go to add50

add40:   0 - c -> c[w]
         c -> a[s]
         if a >= b[x]
           then go to add50
         m1 exchange c
         a exchange c[w]
         shift left a[w]
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         a - 1 -> a[x]
         a exchange b[w]
add50:   if a >= b[x]
           then go to add60
         a + 1 -> a[x]
         shift right c[w]
         a exchange c[s]
         c -> a[s]
         p - 1 -> p
         if p # 13
           then go to add50
         0 -> c[w]
add60:   a exchange c[w]
         m1 -> c
         b exchange c[w]
         a + b -> a[w]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
; fall into mpy150

mpy150:  a exchange c[w]
         m1 exchange c
         m1 -> c
         if c[s] = 0
           then go to shf40
         a + 1 -> a[x]
         shift right c[w]
shf40:   a exchange c[w]
shf10:   p <- 12
         if a[wp] # 0
           then go to shf20
nrm10:   b exchange c[w]
nrm11:   a exchange c[w]
         p <- 12
         c -> a[w]
         c + c -> c[x]
         if n/c go to nrm20
         c + 1 -> c[m]
         if n/c go to nrm20
         b -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[p]
nrm30:   b -> c[s]
         a exchange b[w]
         if c[m] # 0
           then go to nrm40
         0 -> c[w]
         0 -> a[s]
nrm40:   return

nrm20:   b -> c[x]
         go to nrm30

shf20:   if a[p] # 0
           then go to nrm10
         c - 1 -> c[x]
         shift left a[wp]
         go to shf20

add90:   m1 exchange c
         a exchange b[w]
         if a >= b[x]
           then go to add45
         go to add30

add45:   a exchange c[w]
         m1 exchange c
         if a >= c[w]
           then go to add55
         m1 exchange c
         a exchange c[w]
         go to add65

add55:   m1 exchange c
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         go to add65

mp2-10:  0 -> b[w]
         a exchange b[m]
mp1-10:  m1 exchange c
         m1 -> c
         0 -> c[x]
mp2-13:  0 -> b[s]
         0 -> c[s]
         m1 exchange c
         a + c -> c[x]
         a - c -> c[s]
         if n/c go to mpy110
         0 - c -> c[s]
mpy110:  0 -> a[w]
         m1 exchange c
         p <- 13
mpy120:  p + 1 -> p
         shift right a[w]
         go to mpy140

mpy130:  a + b -> a[w]
mpy140:  c - 1 -> c[p]
         if n/c go to mpy130
         if p # 12
           then go to mpy120
         m1 -> c
         go to mpy150

dv2-10:  0 -> b[w]
         a exchange b[m]
dv1-10:  m1 exchange c
         m1 -> c
         0 -> c[x]
dv2-13:  0 -> b[s]
         0 -> c[s]
         if c[m] = 0
           then go to err0
         m1 exchange c
         a - c -> c[x]
         a - c -> c[s]
         if n/c go to div110
         0 - c -> c[s]
div110:  m1 exchange c
         a exchange c[w]
         a exchange b[w]
div15:   if a >= b[w]
           then go to div120
         m1 exchange c
         shift left a[w]
         c - 1 -> c[x]
         m1 exchange c
div120:  p <- 12
         0 -> c[w]
         go to div140

div130:  c + 1 -> c[p]
div140:  a - b -> a[w]
         if n/c go to div130
         a + b -> a[w]
         shift left a[w]
         p - 1 -> p
         if p # 13
           then go to div140
         a exchange c[w]
         m1 -> c
         go to nrm10

err0:    p <- 0
         delayed rom @04
         go to L02004

sqr10:   0 -> b[w]
         b exchange c[m]
         a exchange c[w]
sqr13:   if a[s] # 0
           then go to err0
         0 -> b[s]
         if b[w] = 0
           then go to L00347
         b -> c[w]
         a exchange b[w]
         c + c -> c[w]
         c + c -> c[w]
         a + c -> c[w]
         b exchange c[w]
         0 -> c[ms]
         c -> a[w]
         c + c -> c[w]
         0 - c -> c[m]
         c + c -> c[x]
         a + c -> c[x]
         p <- 0
         if c[p] # 0
           then go to sqr50
         shift right b[w]
sqr50:   shift right c[w]
         a exchange c[x]
         0 -> c[w]
         a exchange b[w]
         p <- 13
         load constant 5
         shift right c[w]
         go to sqr100

sqr60:   c + 1 -> c[p]
sqr70:   a - c -> a[w]
         if n/c go to sqr60
         a + c -> a[w]
         shift left a[w]
         if p = 0
           then go to L00345
         p - 1 -> p
sqr100:  shift right c[wp]
         0 -> c[p]
         go to sqr70

L00345:  a exchange c[w]
         go to nrm11

L00347:  0 -> a[w]
         0 -> c[w]
         go to nrm11

1/x10:   0 -> b[w]
         b exchange c[m]
         a exchange c[w]
1/x13:  0 -> c[w]
         m1 exchange c
         0 -> c[w]
         p <- 12
         load constant 1
x/y13:   b exchange c[w]
         a exchange c[w]
         m1 exchange c
         a exchange c[w]
         go to dv2-13

subone:  0 -> c[w]
         0 - c - 1 -> c[s]
subon1:  p <- 12
         load constant 1
         go to ad1-10

addone:  0 -> c[w]
         go to subon1

lnc30:   load constant 6
         load constant 9
         load constant 3
         load constant 1
         load constant 4
         load constant 7
         load constant 1
         load constant 8
         load constant 0
         load constant 5
         load constant 5
         c - 1 -> c[wp]
         p <- 12
         return

x-stscr: go to stscr
L00415:  go to S00535
L00416:  go to S00515
L00417:  go to S00532

S00420:  register -> c 6
         a exchange c[s]
         p <- 12
         b exchange c[wp]
         c -> register 6
         register -> c 9
         p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[wp]
         a exchange c[x]
         c -> register 9
         go to L00511

rcscr:   b exchange c[w]
         m1 exchange c
         register -> c 9
         c -> a[m]
         a -> b[m]
         shift right b[m]
         shift right b[m]
         shift right b[m]
         p <- 8
         b exchange c[wp]
         b exchange c[x]
         c -> register 9
         register -> c 6
         b exchange c[w]
         register -> c 7
         c -> register 6
         register -> c 8
         c -> register 7
         a exchange c[m]
         shift right c[w]
         shift right c[w]
         shift right c[w]
         b exchange c[s]
         m1 exchange c
         b exchange c[w]
         return

stscr:   register -> c 7
         c -> register 8
         register -> c 6
         c -> register 7
         b -> c[w]
         a exchange c[s]
         c -> a[s]
         c -> register 6
         register -> c 9
         a exchange c[m]
         p <- 11
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[m]
         c -> register 9
         a exchange c[wp]
L00511:  shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         return

S00515:  register -> c 7
         p <- 8
L00517:  b exchange c[w]
         m1 exchange c
         register -> c 9
L00522:  p - 1 -> p
         shift right c[w]
         if p # 2
           then go to L00522
         b exchange c[s]
         a exchange c[w]
         m1 exchange c
         return

S00532:  register -> c 8
         p <- 11
         go to L00517

S00535:  register -> c 6
         p <- 5
         go to L00517


; ln
S00540:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S00543:  0 -> s 6
         go to L00651

L00545:  0 -> s 6
         0 -> s 8
         0 -> b[s]
         a exchange c[w]
         c -> a[w]
L00552:  c + c -> c[x]
         if n/c go to L00616
         if a[s] # 0
           then go to L00621
         a exchange c[w]
         jsb S00565
L00560:  p <- 12
         a exchange c[w]
         0 -> c[ms]
         c -> a[w]
         go to L00612

S00565:  a exchange b[w]
         a -> b[w]
         m1 exchange c
         m1 -> c
L00571:  shift right a[w]
         if a[w] # 0
           then go to L00577
         m1 -> c
         a exchange c[w]
         return

L00577:  c + 1 -> c[x]
         if n/c go to L00571
         p <- 12
         a + 1 -> a[p]
         a exchange b[w]
S00604:  delayed rom @00
         go to div15

L00606:  if p = 6
           then go to L01752
         p - 1 -> p
         c + 1 -> c[s]
L00612:  c + 1 -> c[x]
         if n/c go to L00606
         a exchange b[w]
         go to ln300

L00616:  delayed rom @00
         jsb addone
         go to L00651

L00621:  1 -> s 8
         go to L00560

ln220:   p <- 12
         b -> c[w]
         c - 1 -> c[p]
         a exchange c[w]
         if a[w] # 0
           then go to L00633
         delayed rom @02
         go to ln560

L00633:  if a[p] # 0
           then go to L00640
         c - 1 -> c[x]
         shift left a[w]
         go to L00633

L00640:  m1 exchange c
         jsb S00604
         go to L00560

ln10:    0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S00646:  1 -> s 6
         if b[m] = 0
           then go to L01756
L00651:  0 -> s 8
         0 -> b[s]		; ln13
         if a[s] # 0
           then go to err0
         if b[m] = 0
           then go to err0
         a exchange c[x]
         c -> a[x]
         if c[x] = 0
           then go to ln220
         a + c -> a[x]
         if n/c go to ln140
         0 - c - 1 -> c[x]
         1 -> s 8
ln140:   0 -> a[ms]
         a exchange c[ms]
         0 -> a[w]
         p <- 12
         a - b -> a[wp]
         c - 1 -> c[p]
ln310:   c + 1 -> c[p]
ln300:   a -> b[w]
         m1 exchange c
         m1 -> c
         go to ln330

ln320:   shift right a[w]
ln330:   c - 1 -> c[s]
         if n/c go to ln320
         m1 -> c
         a + b -> a[w]
         a - 1 -> a[s]
         if n/c go to ln310
         c + 1 -> c[s]
         a exchange b[w]
         shift left a[w]
         p - 1 -> p
         if p # 5
           then go to ln300
         a exchange c[w]
         a -> b[w]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[w]
         p <- 0
         load constant 7
         0 - c -> c[x]
         if b[x] = 0
           then go to ln420
         p <- 6
ln460:   shift right a[w]
         b exchange c[w]	; ln430
ln431:   delayed rom @02
         jsb lnc20
         b exchange c[w]
         delayed rom @02
         jsb pmul
         if c[m] = 0
           then go to ln530
         if p # 13
           then go to ln460
         0 -> b[w]
         p <- 0
         a -> b[p]
         a + b -> a[w]
         shift right a[w]
         b exchange c[w]
         delayed rom @03	; ln500
         jsb lnc10
         if s 8 = 1
           then go to ln570
         a exchange b[w]
         a - b -> a[w]
         a exchange b[w]
         a + b -> a[w]
         a exchange b[w]
ln570:   p <- 3
ln520:   delayed rom @02
         jsb pmul
         if c[m] = 0
           then go to ln530
         shift right a[w]
         go to ln520

ln540:   shift right a[w]
         delayed rom @02
         go to ln550

ln530:   if a[s] # 0
           then go to ln540
         c - 1 -> c[x]
ln550:   0 -> c[ms]
         if s 8 = 0
           then go to ln560
         0 - c - 1 -> c[s]
ln560:   delayed rom @00
         jsb shf10
         if s 6 = 0
           then go to L01040
         delayed rom @01
         jsb rcscr
         delayed rom @00
         jsb mp2-13
ytox50:  m1 -> c
ytox60:  if c[s] = 0
           then go to exp13
         a - 1 -> a[x]
         b exchange c[w]
         go to ytox60

ln420:   shift right a[w]
ln400:   jsb lnap
         a exchange b[w]
         p <- 6
         delayed rom @01
         go to ln431

pmul1:   a + b -> a[w]
pmul:    c - 1 -> c[p]
         if n/c go to pmul1
         0 -> c[p]
         c + 1 -> c[x]
         p + 1 -> p
L01040:  return

exp10:   0 -> b[w]
         b exchange c[m]
         a exchange c[w]
exp13:   1 -> s 8
         if a[s] # 0
           then go to exp110
         0 -> s 8
exp110:  0 -> a[ms]
         a exchange b[w]
         b -> c[w]
         c + c -> c[x]
         if n/c go to exp200
         b -> c[w]
         if a[s] # 0
           then go to exp120
         p <- 13
exp130:  p - 1 -> p
         if p = 5
           then go to exp500
         c + 1 -> c[x]
         if n/c go to exp130
exp400:  jsb lnc20
         b exchange c[w]
         go to exp420

exp200:  delayed rom @03
         jsb lnc10
         p <- 6
         go to exp220

exp120:  a exchange b[w]
         a + 1 -> a[x]
         shift right b[w]
         go to exp110

exp210:  c + 1 -> c[m]
exp220:  a - b -> a[w]
         if n/c go to exp210
         a + b -> a[w]
         shift left a[w]
         c - 1 -> c[x]
         if n/c go to exp230
         p <- 5
         if c[p] = 0
           then go to exp240
         c - 1 -> c[p]
         if c[p] # 0
           then go to exp300
         c + 1 -> c[p]
exp240:  p <- 12
         go to exp430

exp230:  a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[p] = 0
           then go to exp220
exp300:  0 -> c[w]
         p <- 12
         c - 1 -> c[wp]
         c -> a[w]
         p <- 2
         load constant 1
         if s 8 = 0
           then go to exp700
         0 - c - 1 -> c[x]
exp700:  a exchange b[w]
         c -> a[w]
exp710:  if s 4 = 0
           then go to S01151
         delayed rom @01
         jsb stscr
         delayed rom @00
         jsb subone
         delayed rom @01
         jsb S00420
S01151:  a exchange b[w]
         delayed rom @00
         go to nrm11

lnc20:   0 -> c[w]
         if p = 12
           then go to lnc30
         c - 1 -> c[m]
         load constant 4
         c + 1 -> c[m]
         if p = 10
           then go to lnc40
         if p = 9
           then go to lnc50
         if p = 8
           then go to lnc60
         if p = 7
           then go to lnc70
         if p = 6
           then go to lnc80
         p <- 0
         load constant 3
         p <- 6
         return

exp410:  c + 1 -> c[p]
exp420:  a - b -> a[w]
         if n/c go to exp410
         a + b -> a[w]
         if p = 6
           then go to exp510
         shift left a[w]
         c - 1 -> c[x]
         p - 1 -> p
exp430:  b exchange c[w]
         go to exp400

exp500:  b exchange c[w]
exp510:  if s 4 = 0
           then go to exp570
         jsb lnap
         a exchange c[w]
         a exchange b[w]
exp570:  p <- 13
         load constant 6
         p <- 5
exp550:  if c[m] = 0
           then go to exp600
         p + 1 -> p
exp560:  if c[p] = 0
           then go to exp520
         c - 1 -> c[p]
         a -> b[w]
         m1 exchange c
         m1 -> c
         go to exp530

exp520:  c + 1 -> c[x]
         shift right a[w]
         c - 1 -> c[s]
         if n/c go to exp550
         shift right c[w]
         shift right c[w]
         shift right c[w]
         a + 1 -> a[p]
         a exchange b[w]
         c -> a[w]
         if s 8 = 0
           then go to exp710
         delayed rom @00
         jsb 1/x13
         go to exp710

exp540:  shift right b[w]
exp530:  c - 1 -> c[s]
         if n/c go to exp540
         a + b -> a[w]
         a + 1 -> a[s]
         m1 -> c
         go to exp560

lnap:    m1 exchange c
         m1 -> c
         a -> b[w]
         b exchange c[w]
         c + c -> c[w]
         c + c -> c[w]
         a + c -> c[w]
         a exchange b[w]
lnap1:   shift right c[w]
         if c[w] # 0
           then go to lnap2
         m1 -> c
         a exchange c[w]
         return

lnap2:   a + 1 -> a[x]
         if n/c go to lnap1
         0 - c -> c[w]
         0 -> c[s]
         m1 exchange c
         c + 1 -> c[x]
         delayed rom @00
         go to div110

exp600:  a exchange b[w]
         0 -> c[ms]
         c -> a[w]
         if s 8 = 0
           then go to exp740
         0 - c - 1 -> c[s]
         delayed rom @01
         jsb S00565
exp740:  if s 4 = 0
           then go to L01326
         delayed rom @01
         jsb stscr
L01326:  delayed rom @00
         jsb addone
         go to S01151

xy_to_x:			; xy^x in 41C
	 0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         jsb stscr
         y -> a
         m2 -> c
         if a[s] # 0
           then go to L01771
         go to yx13

yx12:    if c[x] = 0
           then go to err0
         c - 1 -> c[x]
yx11:    shift left a[ms]
         if a[m] # 0
           then go to yx12
         if c[x] # 0
           then go to yx13
         a exchange c[s]
         c -> a[s]
         c + c -> c[s]
         c + c -> c[s]
         a + c -> c[s]
         if c[s] = 0
           then go to yx13
         1 -> s 7
yx13:    y -> a
         0 -> a[s]
         a exchange c[w]
         0 -> s 4
         delayed rom @01
         jsb ln10
         stack -> a
         if s 7 = 0
           then go to L01375
         0 - c - 1 -> c[s]
L01375:  delayed rom @04
         go to L02002


; @01377
crc_check_quad_0:
         rom check


S01400:  select rom go to x-ad2-10
S01401:  select rom go to x-ad1-10
         select rom go to x-ad2-13
S01403:  select rom go to x-mp2-10
         select rom go to x-mp1-10
         select rom go to x-mp2-13
S01406:  select rom go to x-dv2-10


; factorial
xft100:  p <- 12		; this instrunction not in 41C
         if c[s] # 0
           then go to err0
         if c[xs] # 0
           then go to err0
         c -> a[w]
xft110:  a -> b[w]
         shift left a[ms]
         if a[wp] # 0
           then go to xft120
         a + 1 -> a[x]
         if a >= c[x]
           then go to xft130
         c + 1 -> c[xs]
         return

xft120:  a - 1 -> a[x]
         if n/c go to xft110
         delayed rom @00
         go to err0

xft130:  0 -> c[w]
         c + 1 -> c[p]
         shift right c[w]
         c + 1 -> c[s]
         b exchange c[w]
xft140:  if b[p] = 0
           then go to xft150
         shift right b[wp]
         c + 1 -> c[x]
xft150:  0 -> a[w]
         a - c -> a[p]
         if n/c go to xft170
         shift left a[w]
xft160:  a + b -> a[w]
         if n/c go to xft160
xft170:  a - c -> a[s]
         if n/c go to xft190
         shift right a[wp]
         a + 1 -> a[w]
         c + 1 -> c[x]
xft180:  a + b -> a[w]
         if n/c go to xft180
xft190:  a exchange b[wp]
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
         return

L01474:  0 -> s 13		; Sigma+
         go to L01477

L01476:  1 -> s 13		; Sigma-
L01477:  jsb S01642
         0 -> c[w]
         p <- 12
         load constant 1
         jsb S01566
         c -> register 0
         register -> c 1
         c -> a[w]
         m2 -> c
         jsb S01566
         c -> register 1
         m2 -> c
         c -> a[w]
         jsb S01403
         register -> c 2
         jsb S01621
         c -> register 2
         y -> a
         register -> c 3
         a exchange c[w]
         jsb S01566
         c -> register 3
         y -> a
         a exchange c[w]
         c -> a[w]
         jsb S01403
         register -> c 4
         jsb S01621
         c -> register 4
         m2 -> c
         y -> a
         jsb S01403
         register -> c 5
         jsb S01621
         c -> register 5
         jsb S01640
         delayed rom @04
         go to L02005

L01545:  jsb S01642
         register -> c 3
         a exchange c[w]
         if c[m] # 0
           then go to L01555
         p <- 3
         delayed rom @04
         go to L02004

L01555:  jsb S01406
         jsb S01572
         jsb S01630
         jsb S01642
         register -> c 1
         a exchange c[w]
         jsb S01406
         delayed rom @04
         go to L02000

S01566:  if s 13 = 0
           then go to L01571
         0 - c - 1 -> c[s]
L01571:  jsb S01400
S01572:  if c[m] # 0
           then go to L01575
         0 -> c[w]
L01575:  decimal
         p <- 12
         if c[xs] = 0
           then go to L01606
         c - 1 -> c[x]
         c + 1 -> c[xs]
         c - 1 -> c[xs]
         if n/c go to L01607
         c + 1 -> c[x]
L01606:  return

L01607:  c + c -> c[xs]
         if n/c go to L01613
         0 -> c[w]
         go to L01617

L01613:  0 -> c[wp]
         c - 1 -> c[wp]
         0 -> c[xs]
         p - 1 -> p
L01617:  p - 1 -> p
         return

S01621:  if s 13 = 0
           then go to L01626
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
L01626:  jsb S01401
         go to S01572

S01630:  c -> a[w]
         if s 9 = 1
           then go to L01635
         m2 -> c
         c -> stack
L01635:  a exchange c[w]
         c -> stack
         return

S01640:  m2 -> c
         c -> register 10
S01642:  jsb S01645
         c -> a[w]
         return

S01645:  0 -> c[w]
         c -> data address
         data -> c
         return

lnc10:   p <- 12
         load constant 2	; ln(10)
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
         b exchange c[w]
         return

lnc40:   load constant 3	; part of ln(1.1), after 0.095
         load constant 1
         load constant 0
         load constant 1
         load constant 7
         load constant 9
         load constant 8
         load constant 0
         load constant 4
         load constant 3
         load constant 2
         p <- 11
         return

lnc50:   p <- 8			; part of ln(1.01), after 0.009950
         load constant 3
         load constant 3
         load constant 0
         load constant 8
         load constant 5
         load constant 3
         load constant 1
         load constant 6
         load constant 8
         p <- 10
         return

lnc60:   p <- 6			; part of ln(1.001), after 0.000999500
         load constant 3
         load constant 3
         load constant 3
         load constant 0
         load constant 8
         load constant 3
         load constant 5
         p <- 9
         return

lnc70:   p <- 4			; part of ln(1.0001), after 0.000999500
         load constant 3
         load constant 3
         load constant 3
         load constant 3
         load constant 1
         p <- 8
         return

lnc80:   p <- 2			; part of ln(1.00001), after 0.000099994000
         load constant 3
         load constant 3
         load constant 3
         p <- 7
         return

L01752:  a exchange b[w]
         b exchange c[w]
         delayed rom @02
         go to ln400

L01756:  delayed rom @01
         jsb rcscr
         if c[m] = 0
           then go to err0
         m1 -> c
         if c[s] # 0
           then go to err0
         0 -> a[w]
         0 -> b[w]
         delayed rom @02
         go to exp710

L01771:  a exchange c[m]
         if c[xs] # 0
           then go to err0
         delayed rom @02
         go to yx11

         nop

         .check			; CRC, quad 0 (@0000..@1777)
;        .dw @0533		; CRC, quad 0 (@0000..@1777)

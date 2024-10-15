; 32E model-specific firmware, uses 1820-2162 CPU ROM
; Copyright 2022-2023 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

; HP-32E Q function reverse-engineered by mike-stgt:
;     https://forum.hp41.org/viewtopic.php?f=10&t=427

	 .copyright "Copyright 2022-2023 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

         .arch woodstock

         .include "1820-2162.inc"

; S bits:
; 0   SCI or ENG display format
; 1   ENG display format
; 2   digit entry has exponent
; 3   digit entry has decimal (hardware: unused)
; 4   general flag; in display formatting, exponent to be shown
; 5   hardware: CRC check failure
; 6   general flag
; 7
; 8   general flag
; 9   stack lift disable
; 10  general flag
; 11  digit entry
; 12  RAD
; 13  general flag
; 14  RAD, GRD
; 15  hardware - key pressed

; P register values in main loop:
; 1   STO /
; 2   STO *
; 3   STO +
; 4   STO -
; 5   STO
; 6   RCL
; 7   ENG
; 8   SCI
; 9   FIX
; 10  f shift
; 11  g shift
; 12  no prefix

	 .org @2000

L02000:  go to L02023

L02001:  go to reset_x

L02002:  go to L02066

error_0: p <- 0			; error 0
error_p:
         go to error_p_x	; error entry from CPU ROM


ml_disable_stack_lift:
         1 -> s 9		; disable stack lift
         m2 exchange c
         go to L02027


reset_x: display off
         clear status
         clear regs
         0 -> c[w]
         delayed rom @05
         jsb S02671
         clear data registers
         load constant 4
         a exchange c[w]
         f exchange a[x]
L02022:  down rotate		; unshifted key 22 - Rdn
L02023:  delayed rom @03
         jsb S01572
         m2 exchange c
         0 -> s 9		; enable stack lift

; main loop, four entry points depending on what needs to be done
L02027:  jsb clear_digit_entry_etc
L02030:  jsb format_display
L02031:  jsb clear_flags
L02032:  delayed rom @06
         jsb get_key
         m2 -> c
         0 -> a[x]
         if p = 11
           then go to L03237	; g-shifted key dispatch
         if p = 10
           then go to L02477	; f-shifted key dispatch
         keys -> rom address	; unshifted key dispatch

L02043:  0 -> s 1
         go to L02233

L02045:  p <- 10		; unshifted key 14 - f shift
         go to L02031

L02047:  delayed rom @00
         jsb mp2-10
         go to L02335

L02052:  delayed rom @03	; Sigma+
         go to L01474

L02054:  delayed rom @07	; unshifted key 33 - EEX
         go to L03573

L02056:  delayed rom @07	; unshifted key 32 - CHS
         go to L03634

         go to L02073		; unshifted key 15 - g shift

         go to L02045		; unshifted key 14 - f shift

         go to L02121		; unshifted key 13 - y^x

         go to L02075		; unshifted key 12 - 1/x

         delayed rom @00	; unhifted key 11 - sqrt
         jsb sqr10
L02066:  a exchange c[w]
         m2 -> c
         c -> register 10
         a exchange c[w]
         go to L02000

L02073:  p <- 11		; unshifted key 15 - g shift
         go to L02031

L02075:  delayed rom @00	; unshifted key 12 - 1/x
         jsb 1/x10
         go to L02002

         go to L02123		; unshifted key 74 - percent

         go to L02213		; unshifted key 73 - decimal

         go to L02260		; unshifted key 72 - 0

         if p # 5		; unshifted key 71 - divide
           then go to L03117
         p <- 1			; STO prefix, change to STO /
         go to L02031


clear_digit_entry_etc:
         0 -> s 11		; not in digit entry
         0 -> s 2		; digit entry does not have decimal
         0 -> s 3		; digit entry does not have decimal

clear_flags:
         0 -> s 4
         0 -> s 6
         0 -> s 7
         0 -> s 8
         0 -> s 10
         0 -> s 13
         return


L02121:  delayed rom @02	; unshifted key 13 - y^x
         go to L01331

L02123:  y -> a			; unshifted key 74 - percent
         c - 1 -> c[x]
         c - 1 -> c[x]
L02126:  delayed rom @00
         jsb mp2-10
         go to L02002

L02131:  0 -> c[w]		; unshifted key 34 - CLx
         go to ml_disable_stack_lift

error_2: p <- 2
         go to error_p

L02135:  a + 1 -> a[x]		; unshfited key 44 - 9
         1 -> s 6
         go to L02241

         go to L02170		; unshifted key 54 - 6

L02141:  go to L02316		; unshifted key 53 - 5

         go to L02317		; unshifted key 52 - 4

         if p # 5		; unshifted key 51 - plus
           then go to L02150
         p <- 3			; STO prefix, change to STO +
         go to L02031

L02147:  0 - c - 1 -> c[s]	; minus
L02150:  stack -> a
         delayed rom @00
         jsb ad2-10
         go to L02002

L02154:  p <- 6			; unshifted key 24 - RCL
         go to L02031

L02156:  p <- 5			; unshifted key 23 - STO
         go to L02031

         go to L02131		; unshifted key 34 - CLx

         go to L02054		; unshifted key 33 - EEX

         go to L02056		; unshifted key 32 - CHS

         if p = 5		; unshifted key 31 - ENTER^
           then go to L02175	;   if STO prefix, run self-test
L02165:  c -> stack
         go to ml_disable_stack_lift

L02167:  a + 1 -> a[x]
L02170:  a + 1 -> a[x]		; unshifted key 54 - 6
         if s 10 = 1
           then go to error_2
         1 -> s 8
         go to L02141

L02175:  if s 10 = 0		; STO ENTER^: self test
           then go to L03723
         go to L02165

L02200:  if p = 12		; unshifted key 25 - Sigma+
           then go to L02052
         if s 10 = 1
           then go to L02052
         if p # 6
           then go to L02052
         register -> c 3	; RCL Sigma
         delayed rom @03
         jsb S01630
         register -> c 1
         go to L02000

L02213:  if p = 12		; unshifted key 73 - decimal
           then go to L03630	; . with no prefix
         if p = 9
           then go to L03630	; FIX .
         go to L02247

         go to L02200		; unshifted key 25 - Sigma+

         go to L02154		; unshifted key 24 - RCL

         go to L02156		; unshifted key 23 - STO

         go to L02022		; unshifted key 22 - Rdn

         stack -> a		; unshifted key 21 - x<>y
         c -> stack
         a exchange c[w]
         go to L02000

error_1: p <- 1
         go to error_p


; set ENG display format
L02232:  1 -> s 1

; set SCI display format
L02233:  1 -> s 0

; store FIX/SCI/ENG digit count
L02234:  f exchange a[x]
         go to L02027


L02236:  stack -> a		; multiplication
         go to L02126

         go to L02135		; unshifted key 44 - 9

L02241:  a + 1 -> a[x]		; unshifted key 43 - 8
         if n/c go to L02167	; unshifted key 42 - 7

         if p # 5		; unshifted key 41 - minus
           then go to L02147
         p <- 4			; STO prefix, change to STO -
         go to L02031


; decimal key, continued
L02247:  if p = 8		; SCI .
           then go to L03630
         if p = 7		; ENG .
           then go to L03630
         if s 10 = 1
           then go to L03630
         1 -> s 10
         go to L02032

L02257:  a + 1 -> a[x]
L02260:  if p = 12		; unshifted key 72 - 0
           then go to L03432

         if p = 9
           then go to L02364	; set FIX
         if p = 8
           then go to L02043	; set SCI
         if p = 7
           then go to L02232	; set ENG

         if s 6 = 1
           then go to error_2
         if s 10 = 1
           then go to L02302
         a + 1 -> a[x]
L02275:  binary
         a + 1 -> a[x]
         decimal
         a + 1 -> a[xs]
         if n/c go to L02275
L02302:  a exchange c[w]
         c -> data address
         data -> c
         a exchange c[w]
         if p = 6
           then go to L03304
         if p = 5
           then go to L02341
         if p = 4
           then go to L02346
         go to L02327

         nop
L02316:  a + 1 -> a[x]		; unshifted key 53 - 5
L02317:  a + 1 -> a[x]		; unshifted key 52 - 4
         a + 1 -> a[x]		; unshifted key 64 - 3
         a + 1 -> a[x]		; unshifted key 63 - 2
         if n/c go to L02257	; unshifted key 62 - 1

         if p # 5		; unshifted key 61 - times
           then go to L02236
         p <- 2
         go to L02031

L02327:  if p = 3
           then go to L02347
         if p = 2
           then go to L02047
         delayed rom @00
         jsb dv2-10
L02335:  delayed rom @03
         jsb S01572
         if p = 10
           then go to error_1
L02341:  c -> data
         0 -> c[w]
         c -> data address
         m2 -> c
         go to L02000

L02346:  0 - c - 1 -> c[s]
L02347:  delayed rom @00
         jsb ad2-10
         go to L02335


error_p_x:
         0 -> c[w]
         c -> data address
         binary
         c - 1 -> c[w]

         0 -> a[xs]		; copy P to a[xs]
L02357:  if p = 0
           then go to L03266
         a + 1 -> a[xs]
         p - 1 -> p
         go to L02357


L02364:  0 -> s 0	; set fix mode
         0 -> s 1
         go to L02234


format_display:
         m2 -> c
         b exchange c[w]
         if s 11 = 1		; in digit entry?
           then go to L03373
         decimal
         b -> c[w]
         0 -> s 4		; assume no exponent display
         c -> a[w]
         if s 0 = 1		; SCI or ENG
           then go to L02427
         if c[xs] # 0
           then go to L02421
         p <- 1
         load constant 1
         load constant 0
         if a >= c[x]
           then go to L02427	; large exponent, force SCI
         0 -> a[x]
         f -> a[x]
         a + b -> a[x]
         if a >= c[x]
           then go to L02416
         go to L02432

L02416:  c - 1 -> c[x]
         c -> a[x]
         go to L02432


L02421:  0 -> a[x]
         f -> a[x]
         a + 1 -> a[x]
         a + c -> a[x]
         if n/c go to L02427	; negative exponent, force SCI
         go to L02432


; display formatting, SCI or ENG
L02427:  1 -> s 4		; display exponent
         0 -> a[x]
         f -> a[x]

L02432:  b -> c[w]
         0 -> c[s]
         p <- 12
L02435:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L02435
         if s 4 = 1		; exponent to be displayed?
           then go to L02445	;   yes
         if c[xs] = 0
           then go to L02445
         p + 1 -> p
L02445:  0 -> a[w]
         c -> a[wp]
         a + c -> a[ms]
         0 -> a[wp]
         a exchange c[ms]
         go to L02737


L02453:  delayed rom @03	; f-shifted key 25 - Sigma-
         go to L01476

L02455:  1 -> s 8		; f-shifted key 54 - ->H.MS
         delayed rom @12
         go to L05121

         go to L02467		; f-shifted key 15 - g

         go to L02471		; f-shifted key 14 - f

         p - 1 -> p		; f-shifted key 13 - ENG
         p - 1 -> p		; f-shifted key 12 - SCI
         p - 1 -> p		; f-shifted key 11 - FIX
L02465:  delayed rom @04
         go to L02031

L02467:  p <- 11		; f-shifted key 15 - g
         go to L02465

L02471:  p <- 10		; f-shifted key 14 - f
         go to L02465

L02473:  b -> c[w]
         c -> a[w]
         0 -> a[s]
         go to L02764


L02477:  keys -> rom address	; f-shifted key dispatch

         go to L02530		; f-shifted key 74 - %Sigma

         go to L02656		; f-shifted key 73 - LOG

         go to L02535		; f-shifted key 72 - LN

         1 -> s 4		; f-shifted key 71 - ->gal
L02504:  jsb S02554		; g-shifted key 71 - ->ltr
         load constant 3
         load constant 7
         load constant 8
         load constant 5
         load constant 4
         load constant 1
         load constant 1
         load constant 7
         load constant 8
         load constant 4
L02517:  if s 4 = 1		; conversion direction?
           then go to L02525
         delayed rom @00
         jsb mp2-10
L02523:  delayed rom @04
         go to L02002

L02525:  delayed rom @00
         jsb dv2-10
         go to L02523

L02530:  a exchange c[w]	; f-shifted key 74 - %Sigma
         a + 1 -> a[x]
         a + 1 -> a[x]
         register -> c 1
         go to L02525

L02535:  delayed rom @01	; f-shifted key 72 - LN
         jsb S00540
         go to L02523

         go to L02455		; f-shifted key 54 - ->H.MS

         go to L02776		; f-shifted key 53 - ->RAD

         go to L02701		; f-shifted key 52 - ->R

         jsb S02554		; f-shifted key 51 - ->degF
         load constant 1
         load constant 8
         delayed rom @00
         jsb mp2-10
         jsb S02626
         delayed rom @00
         jsb ad1-10
         go to L02523

S02554:  c -> a[w]
S02555:  0 -> c[w]
         p <- 12
         return

         go to L02603		; f-shifted key 34 - CLR Sigma

         go to L02574		; f-shifted key 33 - CLR REG

         go to L02565		; f-shifted key 32 - CLR ALL

         p <- 12		; f-shifted key 31 - CLR PREFIX
         go to L02465

L02565:  clear regs		; f-shifted key 32 - CLR ALL
         jsb S02671
         clear data registers
         m2 exchange c
         m2 -> c
L02572:  delayed rom @04
         go to L02027

L02574:  jsb S02671		; f-shifted key 33 - CLR REG
         c -> register 11
         c -> register 12
         c -> register 13
         c -> register 14
         c -> register 15
         go to L02572

L02603:  0 -> c[w]		; f-shifted key 34 - CLR Sigma
         c -> register 0
         c -> register 1
         c -> register 2
         c -> register 3
         c -> register 4
         c -> register 5
         go to L02572

L02613:  c + 1 -> c[x]
         p - 1 -> p
         go to L02752

L02616:  delayed rom @03	; f-shifted key 24 - mean
         go to L01545

         go to L02453		; f-shifted key 25 - Sigma-

         go to L02616		; f-shifted key 24 - mean

         select rom go to L05623	; f-shifted key 23 - L.R.

         select rom go to L05624	; f-shifted key 22 - lin est y

         delayed rom @12	; f-shifted key 21 - Q
         go to L05274

S02626:  0 -> c[w]
         c + 1 -> c[x]
         p <- 12
         load constant 3
         load constant 2
         return

L02634:  1 -> s 7		; f-shifted key 64 - TANH
L02635:  1 -> s 4		; f-shifted key 62 - SINH
L02636:  delayed rom @13	; f-shifted key 63 - COSH
         go to L05512

         go to L02654		; f-shifted key 44 - TAN

         go to L02653		; f-shifted key 43 - COS

         go to L02652		; f-shifted key 42 - SIN

         1 -> s 4		; f-shifted key 41 - ->in
L02644:  jsb S02554		; g-shifted key 41 - ->mm
         c + 1 -> c[x]
         load constant 2
         load constant 5
         load constant 4
         go to L02517

L02652:  1 -> s 10		; f-shifted key 42 - SIN
L02653:  1 -> s 6		; f-shifted key 43 - COS
L02654:  delayed rom @11	; f-shifted key 44 - TAN
         go to L04474

L02656:  delayed rom @01	; f-shifted key 73 - LOG
         jsb S00540
         0 -> c[w]
         m1 exchange c
         m1 -> c
         delayed rom @03
         jsb S01651
         b exchange c[w]
         delayed rom @00
         jsb dv2-13
         go to L02523

S02671:  0 -> c[w]
         p <- 1
         load constant 1
         c -> data address
         clear data registers
         0 -> c[w]
         c -> data address
         return

L02701:  delayed rom @11		; f-shifted key 52 - ->R
         go to L04470


; even more ENG mode display formatting
L02703:  a - 1 -> a[p]
L02704:  a - 1 -> a[x]
         if n/c go to L02707
         go to L02764

L02707:  a + 1 -> a[s]
         decimal
         c - 1 -> c[x]
         p - 1 -> p
         binary
         a + 1 -> a[p]
         if n/c go to L02703
         go to L02704


         nop

         go to L02634		; f-shifted key 64 - TANH

         go to L02636		; f-shifted key 63 - COSH

         go to L02635		; f-shifted key 62 - SINH

         1 -> s 4		; f-shifted key 61 - ->lbm
L02724:  jsb S02554		; g-shifted key 61 - ->kg
         c - 1 -> c[x]
         load constant 4
         load constant 5
         load constant 3
         load constant 5
         load constant 9
         load constant 2
         load constant 3
         load constant 7
         go to L02517


; display formatting continued
L02737:  if c[s] = 0
           then go to L02753
         if s 4 = 0
           then go to L02613
         c + 1 -> c[x]
         if c[xs] = 0
           then go to L02752
         c - 1 -> c[xs]
         if c[xs] = 0
           then go to L02473
         c + 1 -> c[xs]
L02752:  shift right c[ms]
L02753:  c -> a[ms]
         binary
         a - 1 -> a[wp]
         c -> a[x]
         decimal
         if s 4 = 0		; exponent to be displayed?
           then go to L03361	;   no
         if s 1 = 1		; ENG mode?
           then go to L03201	;   yes
L02764:  if c[xs] = 0		; exponent negative?
           then go to L02771	;   no
         decimal
         0 - c -> c[x]
         c - 1 -> c[xs]
L02771:  a exchange c[x]
         delayed rom @07
         jsb S03657
         delayed rom @06
         go to L03373


L02776:  delayed rom @06	; f-shifted key 53 - ->RAD
         go to L03011

S03000:  select rom go to x-ad2-10

         select rom go to x-ad1-10

         select rom go to x-ad2-13

S03003:  select rom go to x-mp2-10

S03004:  select rom go to x-mp1-10

         select rom go to x-mp2-13

S03006:  select rom go to x-dv2-10

S03007:  select rom go to x-dv1-10

S03010:  select rom go to x-dv2-13

L03011:  0 -> a[w]		; f-shifted key 53 - ->RAD
         jsb S03022
         b exchange c[w]
         m2 -> c
         jsb S03004
         jsb S03174
         jsb S03007
L03020:  delayed rom @04
         go to L02002

S03022:  delayed rom @10
         go to S04232

L03024:  c -> a[w]		; g-shifted key 53 - ->DEG
         jsb S03174
         jsb S03003
         jsb S03022
         jsb S03010
         go to L03020

L03032:  a exchange c[m]
         a exchange b[x]
         return

L03035:  0 -> a[w]		; g-shifted key 73 - 10^x
         delayed rom @03
         jsb S01651
         m2 -> c
         jsb S03004
         delayed rom @02
         jsb S01044
         go to L03020

L03045:  delayed rom @03	; g-shifted key 25 - factorial, n!
         jsb xft100		; factorial
         go to L03020

S03050:  0 -> a[w]
         p <- 12
         a + 1 -> a[p]
         return

L03054:  1 -> s 6

; inverse trigonometric functions
;   SIN-1 - s6 = 1
;   COS-1 - s10 = 1
;   TAN-1
L03055:  1 -> s 13
         delayed rom @10
         go to L04065

         go to L03067		; g-shifted key 15 - g

         go to L03076		; g-shifted key 14 - f

         go to L03351		; g-shifted key 13 - LSTx

         go to L03260		; g-shifted key 12 - pi

         c -> a[w]		; s-shifted key 11 - x^2
         jsb S03003
         go to L03020

L03067:  p <- 11		; g-shifted key 15 - g
L03070:  delayed rom @04
         go to L02031


; stack lift if enabled
S03072:  if s 9 = 1
           then go to L03075
         c -> stack
L03075:  return


L03076:  p <- 10		; g-shifted key 14 - f
         go to L03070

         go to L03244		; g-shifted key 74 - Delta%

         go to L03035		; g-shifted key 73 - 10^x

         go to L03114		; g-shifted key 72 - e^x

         select rom go to L02504	; g-shifted key 71 - ->ltr

L03104:  0 -> s 12		; g-shifted key 34 - DEG
         0 -> s 14
         go to L03172

L03107:  0 -> s 12		; g-shifted key 33 - GRD
         go to L03112

L03111:  1 -> s 12		; g-shifted key 32 - RAD
L03112:  1 -> s 14
         go to L03172

L03114:  delayed rom @02	; g-shifted key 72 - e^x
         jsb S01041
         go to L03020

L03117:  if c[m] = 0		; divide
           then go to error_0
         stack -> a
         jsb S03006
         go to L03020

S03124:  m2 -> c
         c -> a[w]
         0 -> b[w]
         b exchange c[m]
         delayed rom @01
         jsb S00470
         m2 -> c
         jsb S03004
S03134:  delayed rom @13
         jsb S05562
         delayed rom @01
         go to S00470

         go to L03316		; g-shifted key 54 - ->H

         go to L03024		; g-shifted key 53 - ->DEG

         go to L03156		; g-shifted key 52 - ->P

         c -> a[w]		; g-shifted key 51 - ->degC
         delayed rom @05
         jsb S02626
         0 - c - 1 -> c[s]
         jsb S03000
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 8
         jsb S03007
         go to L03020

L03156:  delayed rom @10	; g-shifted key 52 - ->P
         go to L04000

         go to L03104		; g-shifted key 34 - DEG

         go to L03107		; g-shifted key 33 - GRD

         go to L03111		; g-shifted key 32 - RAD

         a exchange c[w]	; g-shifted key 31 - MANT
         0 -> b[w]		; no decimals or specials
         display toggle
L03166:  0 -> s 15		; wait for key release
         if s 15 = 1
           then go to L03166
         display off
L03172:  delayed rom @04
         go to L02027


S03174:  0 -> c[w]
         p <- 12
         load constant 9
         c + 1 -> c[x]
         return


; display formatting in ENG mode
L03201:  b exchange c[x]
         a + 1 -> a[xs]
         a - 1 -> a[x]
         p <- 1
         0 -> c[x]
         load constant 3	; divide exponent by 3 by repeated subtraction
L03207:  a - c -> a[x]
         if n/c go to L03207
         a + c -> a[x]		; restore from underflow
         shift right c[x]
L03213:  a - c -> a[x]
         if n/c go to L03213
         go to L03232


L03216:  delayed rom @13	; g-shifted key 63 - COSH-1
         go to L05424

         go to L03045		; g-shifted key 25 - factorial, n!

         go to L03230		; g-shifted key 24 - std dev

         go to L03226		; g-shifted key 23 - r

         go to L03231		; g-shifted key 22 - lin est x

         delayed rom @15	; g-shifted key 21 - Q-1
         go to L06523

L03226:  delayed rom @13	; g-shifted key 23 - r
         go to L05630

L03230:  select rom go to L05631	; g-shifted key 24 - std dev

L03231:  select rom go to L05632	; g-shifted key 22 - lin est x


; display formatting in ENG mode, continued
L03232:  a + c -> a[x]
         b -> c[x]
         p <- 12
         delayed rom @05
         go to L02704


L03237:  keys -> rom address	; g-shifted key dispatch

         go to L03055		; g-shifted key 44 - TAN-1

         1 -> s 10		; g-shifted key 43 - COS-1
         go to L03054		; g-shifted key 42 - SIN-1

         select rom go to L02644	; g-shifted key 41 - ->mm

L03244:  y -> a			; g-shifted key 74 - Delta%
         a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         jsb S03000
         a exchange c[w]
         y -> a
         a exchange c[w]
         c - 1 -> c[x]
         c - 1 -> c[x]
         jsb S03007
         go to L03020

L03260:  jsb S03072		; g-shifted key 12 - pi
         jsb S03022
         c + c -> c[w]
         c + 1 -> c[m]
         0 -> c[x]
         go to L03357


L03266:  shift left a[w]
         shift left a[w]
         p <- 4
         a exchange c[p]
         p <- 11
         load constant 14	; E
         load constant 10	; r
         load constant 10	; r
         load constant 12	; o
         load constant 10	; r
         a exchange c[w]
         0 -> b[w]
         jsb get_key
         go to L03172


L03304:  if s 9 = 1		; stack lift if not disabled
           then go to L03307
         c -> stack
L03307:  0 -> c[w]
         c -> data address
         a exchange c[w]
         go to L03357


L03313:  c -> a[s]
         b exchange c[w]
         return

L03316:  delayed rom @12	; g-shifted key 54 - ->H
         go to L05121

         go to L03326		; g-shifted key 64 - TANH-1

         go to L03216		; g-shifted key 63 - COSH-1

         go to L03324		; g-shifted key 62 - SINH-1

         select rom go to L02724	; g-shifted key 61 - ->kg

L03324:  delayed rom @13	; g-shifted key 62 - SINH-1
         go to L05471

L03326:  delayed rom @13	; g-shifted key 64 - TANH-1
         go to L05441


get_key:
         display off
         decimal
         display toggle
L03333:  0 -> s 15
         if s 15 = 1
           then go to L03333
L03336:  if s 15 = 0
           then go to L03336
         display off
         return


L03342:  if c[ms] = 0
           then go to L02427
L03344:  shift right a[w]
         c + 1 -> c[x]
         if c[x] = 0
           then go to L03371
         go to L03344

L03351:  jsb S03072		; g-shifted key 13 - LSTx
         register -> c 10
         go to L03357


; CHS while not in digit entry
L03354:  if c[m] = 0
           then go to L02030
         0 - c - 1 -> c[s]
L03357:  delayed rom @04
         go to L02000


; display formatting, part 3

; display with expoennt, but not in ENG mode
L03361:  0 -> a[s]
         if a[xs] # 0
           then go to L03342
         go to L03367

L03365:  a + 1 -> a[s]
         a - 1 -> a[x]
L03367:  if a[x] # 0
           then go to L03365
L03371:  binary
         a - 1 -> a[x]
L03373:  0 -> c[w]
         a exchange c[s]
         c -> a[s]
         binary
         a + 1 -> a[xs]
         if n/c go to L03427
L03401:  a - 1 -> a[xs]
         if b[s] = 0
           then go to L03406
         p <- 12
         load constant 4
L03406:  p <- 13
L03407:  p - 1 -> p
         a - 1 -> a[s]
         if n/c go to L03407
L03412:  c + 1 -> c[p]
         if p = 12
           then go to L03313
         p + 1 -> p
         if p = 12
           then go to L03313
         p + 1 -> p
         if p = 12
           then go to L03313
         p + 1 -> p
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L03412
L03427:  p <- 5
         load constant 6
         go to L03401


; digit key with no prefix
L03432:  if s 11 = 0		; already in digit entry?
           then go to L03444	;   no, start
         b exchange c[w]
         b -> c[w]
         0 -> c[x]
         binary
         if s 2 = 1
           then go to L03514
         a exchange c[m]
         go to L03446

; starting digit entry with a digit
L03444:  jsb stack_lift_start_entry
         c - 1 -> c[m]

L03446:  shift left a[x]
         shift left a[x]
         p <- 3
         shift left a[wp]
L03452:  c + 1 -> c[p]
         if n/c go to L03463
         shift left a[m]
         p + 1 -> p
         if p # 12
           then go to L03452
         c + 1 -> c[p]
         if n/c go to L03463
         go to L03476

L03463:  c - 1 -> c[p]
         if p # 3
           then go to L03471
         1 -> s 3		; have decimal
         0 -> c[x]
         go to L03477

L03471:  if s 3 = 1
           then go to L03474
         a + 1 -> a[s]
L03474:  p - 1 -> p
         shift right a[m]
L03476:  a + c -> c[wp]
L03477:  c -> a[m]
         c -> a[x]
         p - 1 -> p
         a - 1 -> a[wp]
         if c[m] = 0
           then go to L03506
         jsb S03553
L03506:  if s 2 = 0
           then go to L03511
         jsb S03657
L03511:  m2 exchange c
         delayed rom @04
         go to L02030

L03514:  a exchange c[x]
         p <- 5
         shift right a[wp]
         shift right a[wp]
         p <- 0
         a exchange c[p]
         shift left a[x]
         p <- 4
         shift right a[wp]
L03525:  a exchange c[x]
         c -> a[x]
         decimal
         if c[xs] = 0
           then go to L03534
         0 -> c[xs]
         0 - c -> c[x]
L03534:  jsb S03553
         delayed rom @03
         jsb S01572
         if p # 12
           then go to L02000
         go to L03506



; lift stack if not disabled, then start digit entry
stack_lift_start_entry:  if s 9 = 1
           then go to start_digit_entry
         c -> stack

start_digit_entry:
         0 -> s 9	; enable stack lift
         1 -> s 11	; digit entry started
         0 -> c[w]	; start entry from zero
         c -> a[ms]	; will count no. digits left of decimal - 1
         binary
         return


S03553:  decimal
         a -> b[w]
         0 -> a[x]
         rotate left a
         a exchange b[ms]
         a exchange c[m]
         a + c -> c[x]
         p <- 12
L03563:  if c[p] # 0
           then go to L03032
         c - 1 -> c[x]
         p - 1 -> p
         if s 2 = 1
           then go to L03563
         shift left a[m]
         go to L03563


; EEX
L03573:  if s 11 = 1		; digit entry already started?
           then go to L03606	;   yes
	   	      		
         jsb stack_lift_start_entry	;   no, started digit entry with EEX
L03576:  p <- 12		; make the mantissa 1.
         load constant 1
         c -> a[w]
         a - 1 -> a[wp]		; display only one mantissa digit
L03602:  0 -> a[x]		; display exponent
         1 -> s 2		; have exponent
         1 -> s 3		; have decimal
         go to L03506

L03606:  if s 2 = 1		; already have exponent?
           then go to L03623	;   yes
         if c[m] = 0		; is the mantissa zero?
           then go to L03626	;   yes, make the mantissa 1.
         p <- 5
         a exchange c[m]
         c -> a[m]
         0 -> c[wp]
         if c[m] = 0
           then go to L03623
         m2 -> c
         if b[wp] = 0		; more than 7 mantissa digits?
           then go to L03602	;   no
L03623:  p <- 12		;   yes, clear prefix
         delayed rom @04	;        and return to main loop
         go to L02031


; had zero in mantissa when EEX pressed
L03626:  jsb start_digit_entry
         go to L03576		; make the mantissa 1.


; FIX/SCI/ENG .
L03630:  1 -> s 3
         if s 11 = 1
           then go to L03623
         go to L03444


; CHS
L03634:  if s 11 = 0		; digit entry in progress?
           then go to L03354	;   no
         if s 2 = 1		; have exponent?
           then go to L03647	;   yes

; CHS in mantissa entry
         if c[m] = 0		; if mantissa is zero, ignore
           then go to L03643
         0 - c - 1 -> c[s]
L03643:  binary
         a - 1 -> a[x]
         nop
         go to L03511


; CHS in exponent entry
L03647:  p <- 5
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         a exchange c[xs]
         0 - c - 1 -> c[xs]
         c -> a[xs]
         go to L03525


S03657:  p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         return


S03664:  p <- 0
L03665:  c -> a[w]
         c -> data address
         data -> c
         a - c -> a[w]
         if a[w] # 0
           then go to error_9
         c - 1 -> c[p]
         if n/c go to L03665
         clear data registers
L03676:  0 -> c[x]
         p <- 12
         c + 1 -> c[p]
         m2 exchange c
         m2 -> c
         return

S03704:  if s 5 = 0
           then go to L03676
         go to error_9


L03707:  0 -> c[w]
         m2 exchange c
error_9: p <- 9
         delayed rom @04
         go to error_p


S03714:  p <- 0
L03715:  c -> data address
         c -> data
         c - 1 -> c[p]
         if n/c go to L03715
         return


crc_check_quad_1:
         rom check


; self-test
L03723:  clear regs
         binary
         c + 1 -> c[w]
         m2 exchange c
         0 -> c[w]
         m2 exchange c
         m1 exchange c
         m1 exchange c
         down rotate
         down rotate
         down rotate
         stack -> a
         f exchange a[x]
         f exchange a[x]
         a exchange b[w]
         b exchange c[w]
         c - 1 -> c[w]
         if c[w] # 0
           then go to L03707
         p <- 12
         c + 1 -> c[p]
         m2 exchange c
         m2 -> c
         p <- 0
         load constant 15
         jsb S03714
         jsb S03664
         p <- 1
         load constant 1
         load constant 3
         jsb S03714
         load constant 3
         jsb S03664
         0 -> s 5
         delayed rom @02
         jsb crc_check_quad_0
         jsb S03704
         jsb crc_check_quad_1
         jsb S03704
         delayed rom @12
         jsb crc_check_quad_2
         jsb S03704
         delayed rom @12
         go to L05357


	 .dw @1142		; CRC, quad 1 (@2000..@3777)


L04000:  m2 -> c		; g-shifted key 52 - ->P
         stack -> a
         if c[m] = 0
           then go to L04050
         if c[s] = 0
           then go to L04011
         1 -> s 7
         1 -> s 10
         0 -> c[s]
L04011:  delayed rom @00
         jsb dv2-10
         if c[m] # 0
           then go to L04016
         0 -> a[w]
L04016:  delayed rom @01
         jsb S00470
         delayed rom @01
         jsb S00535
         delayed rom @00
         jsb mp2-13
         delayed rom @00
         jsb addone
         delayed rom @00
         jsb sqr13
         m2 -> c
         0 -> c[s]
         delayed rom @00
         jsb mp1-10
         c -> stack
         delayed rom @01
         jsb S00535
         a exchange c[w]
         c -> a[w]
         go to L04070

S04042:  if s 10 = 1
           then go to L04046
         1 -> s 10
         return

L04046:  0 -> s 10
         return

L04050:  a exchange c[w]
         1 -> s 7
         if c[s] = 0
           then go to L04055
         1 -> s 4
L04055:  0 -> c[s]
         c -> stack
         if c[m] = 0
           then go to L04373
topol3:  0 -> a[w]
         go to brt200

L04063:  jsb S04042
         go to topol3

L04065:  0 -> b[w]
         c -> a[w]
         a exchange b[m]
L04070:  if c[s] = 0
           then go to L04102
         1 -> s 4
         if s 13 = 0
           then go to L04102
         if s 10 = 0
           then go to L04102
         0 -> s 10
         1 -> s 7
         0 -> s 4
L04102:  p <- 12
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L04110
         go to L04261

L04110:  if a[x] # 0
           then go to brt170
         b -> c[w]
         if b[w] = 0
           then go to topol3
         p <- 12
         c - 1 -> c[p]
         if c[w] # 0
           then go to brt170
         if s 6 = 1
           then go to L04063
         jsb trc10
         0 -> a[w]
         a - 1 -> a[x]
         a exchange c[w]
         go to brt200

brt170:  if s 6 = 1
           then go to L04375
L04132:  delayed rom @00	; brt160 ?
         jsb 1/x13
         jsb S04042		; brts10 ?
brt290:  a exchange b[w]
         b -> c[w]
         p <- 12
         0 -> c[ms]
brt300:  c + 1 -> c[x]
         if c[x] = 0
           then go to brt310
         c + 1 -> c[s]
         p - 1 -> p
         if p # 6
           then go to brt300
         b exchange c[w]
         go to brt200

brt310:  m1 exchange c
         0 -> c[w]
         c + 1 -> c[s]
         shift right c[w]
         go to brt340

brt320:  a exchange c[w]
         m1 exchange c
         c + 1 -> c[p]
         c -> a[s]
         m1 exchange c
brt330:  shift right b[w]
         shift right b[w]
         a - 1 -> a[s]
         if n/c go to brt330
         0 -> a[s]
         a + b -> a[w]
         a exchange c[w]
brt340:  a -> b[w]
         a - c -> a[w]
         if n/c go to brt320
         m1 exchange c
         c + 1 -> c[s]
         m1 exchange c
         a exchange b[w]
         shift left a[w]
         p - 1 -> p
         if p # 6
           then go to brt340
         b exchange c[w]
         delayed rom @00
         jsb div120
         a exchange b[w]
         m1 exchange c
         0 -> c[x]
         p <- 7
brt350:  b exchange c[w]
         jsb trc30
         b exchange c[w]
         go to brt370

brt360:  a + b -> a[w]
brt370:  c - 1 -> c[p]
         if n/c go to brt360
         shift right a[w]
         0 -> c[p]
         if c[m] = 0
           then go to brt190
         p + 1 -> p
         go to brt350

S04232:  0 -> c[w]
         m1 exchange c
         jsb trc10
         c + c -> c[w]
         shift right c[w]
         return

trc10:   p <- 12
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
         p <- 12
         return

L04261:  if s 6 = 0
           then go to brt290
         delayed rom @01
         jsb S00470
         delayed rom @01
         jsb S00470
         delayed rom @00
         jsb addone
         delayed rom @01
         jsb S00420
         delayed rom @00
         jsb subone
         delayed rom @01
         jsb S00436
         delayed rom @00
         jsb mp2-13
         0 -> a[s]
         delayed rom @00
         jsb sqr13
         delayed rom @01
         jsb S00436
         delayed rom @00
         jsb x/y13
         0 -> a[s]
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L04132
         go to brt290

L04316:  p + 1 -> p
brt190:  c - 1 -> c[x]
         if p # 12
           then go to L04316
brt200:  0 -> c[ms]
         delayed rom @00
         jsb shf10
         if s 10 = 0
           then go to brt220
         jsb S04232
         0 - c - 1 -> c[s]
         a exchange c[s]
         0 -> c[s]
         delayed rom @00
         jsb ad2-13
brt220:  if s 7 = 0
           then go to brt240
         jsb S04232
         delayed rom @00
         jsb ad2-13
brt240:  if s 12 = 1
           then go to brt250
         jsb S04232
         a + 1 -> a[x]
         a + 1 -> a[x]
         delayed rom @00
         jsb dv2-13
         if s 14 = 1
           then go to brt250
         0 -> c[w]
         p <- 12
         load constant 9
         c - 1 -> c[x]
         delayed rom @00
         jsb mp1-10
brt250:  if s 4 = 0
           then go to brt260
         0 - c - 1 -> c[s]
brt260:  if s 13 = 1
           then go to L04373
         delayed rom @03
         jsb S01572
         stack -> a
         c -> stack
         a exchange c[w]
L04373:  delayed rom @04
         go to L02002

L04375:  delayed rom @04
         go to error_0

trc30:   0 -> c[w]
         c - 1 -> c[w]
         0 -> c[s]
         if p = 12
           then go to trc90
         if p = 11
           then go to trc50
         if p = 10
           then go to trc60
         if p = 9
           then go to trc70
         if p = 8
           then go to trc80
         p <- 0
trc35:   load constant 7
         p <- 7
         return

trc90:   p <- 10
         load constant 6
         load constant 6
         load constant 8
         load constant 6
         load constant 5
         load constant 2
         load constant 4
         load constant 9
         load constant 1
         load constant 1
         load constant 6
         p <- 12
         return

trcs10:  load constant 6
         if p = 0
           then go to trc35
         go to trcs10

trc50:   p <- 8
         jsb trcs10
         p <- 0
         load constant 5
         p <- 4
         load constant 8
         p <- 11
         return

trc60:   p <- 6
         jsb trcs10
         p <- 0
         load constant 9
         p <- 10
         return

trc70:   p <- 4
         jsb trcs10
         p <- 9
         return

trc80:   p <- 2
         jsb trcs10
         p <- 8
         return

L04470:  1 -> s 13		; f-shifted key 52 - ->R
         1 -> s 6
         stack -> a
         a exchange c[w]

; trigonomtric functions
;   ->R - s6 = 1 and s13 = 1
;   SIN - s10 = 1
;   COS - s6 = 1
;   TAN
L04474:  0 -> a[w]
         0 -> b[w]
         a exchange c[m]
         if c[s] = 0
           then go to L04510
         1 -> s 7
         if s 6 = 0
           then go to L04506
         if s 10 = 0
           then go to L04507
L04506:  1 -> s 4
L04507:  0 -> c[s]
L04510:  b exchange c[w]
         if s 12 = 1
           then go to L04624
         if s 14 = 0
           then go to L04521
         a exchange c[w]
         c -> a[w]
         shift right c[w]
         a - c -> a[w]
L04521:  0 -> c[w]
         p <- 12
         load constant 4
         load constant 5
         b exchange c[w]
         c - 1 -> c[x]
         if c[xs] # 0
           then go to L04535
         c - 1 -> c[x]
         if n/c go to L04535
         c + 1 -> c[x]
         shift right a[w]
L04535:  b exchange c[w]
L04536:  m1 exchange c
         m1 -> c
         c + c -> c[w]
         c + c -> c[w]
         c + c -> c[w]
         shift right c[w]
         b exchange c[w]
         if c[xs] # 0
           then go to L04571
L04547:  a - b -> a[w]
         if n/c go to L04547
         a + b -> a[w]
         shift left a[w]
         c - 1 -> c[x]
         if n/c go to L04547
         0 -> c[w]
         b exchange c[w]
         m1 -> c
         c + c -> c[w]
         if s 12 = 0
           then go to L04565
         shift right a[w]
         shift right c[w]
L04565:  b exchange c[w]
L04566:  a - b -> a[w]
         if n/c go to L04602
         a + b -> a[w]
L04571:  b exchange c[w]
         m1 -> c
         b exchange c[w]
         if s 12 = 0
           then go to L04635
         if c[x] # 0
           then go to L04634
         shift left a[w]
         go to L04635

L04602:  if s 10 = 1
           then go to L04613
         1 -> s 10
L04605:  if s 4 = 1
           then go to L04611
         1 -> s 4
         go to L04566

L04611:  0 -> s 4
         go to L04566

L04613:  0 -> s 10
         if s 6 = 0
           then go to L04605
         if s 7 = 0
           then go to L04622
         0 -> s 7
         go to L04566

L04622:  1 -> s 7
         go to L04566

L04624:  delayed rom @10
         jsb trc10
         go to L04536

L04627:  a exchange b[w]
         a - b -> a[w]
         delayed rom @10
         jsb S04042
         go to L04642

L04634:  c + 1 -> c[x]
L04635:  if c[xs] # 0
           then go to L04642
         a - b -> a[w]
         if n/c go to L04627
         a + b -> a[w]
L04642:  c - 1 -> c[x]
         delayed rom @00
         jsb shf10
         if s 12 = 1
           then go to L04660
         m1 -> c
         c + c -> c[w]
         c - 1 -> c[x]
         delayed rom @00
         jsb dv1-10
         delayed rom @10
         jsb S04232
         delayed rom @00
         jsb mp2-13
L04660:  m1 exchange c
         a exchange c[w]
         c -> a[w]
         c + 1 -> c[x]
         if n/c go to L04673
         a exchange b[w]
         shift left a[w]
         go to L04676

L04670:  p - 1 -> p
         if p = 6
           then go to L04760
L04673:  c + 1 -> c[x]
         if n/c go to L04670
         a exchange b[w]
L04676:  0 -> c[w]
L04677:  b exchange c[w]
         delayed rom @10
         jsb trc30
         b exchange c[w]
         go to L04705

L04704:  c + 1 -> c[s]
L04705:  a - b -> a[w]
         if n/c go to L04704
         a + b -> a[w]
         p - 1 -> p
         shift right c[ms]
         shift left a[w]
         if p # 6
           then go to L04677
         m1 exchange c
         shift right a[w]
         shift right a[w]
         0 -> c[w]
         p <- 12
         load constant 1
         m1 exchange c
         p <- 0
         load constant 6
         load constant 6
         go to L04742

L04730:  shift right a[wp]
         shift right a[wp]
L04732:  a - 1 -> a[s]
         if n/c go to L04730
         0 -> a[s]
         m1 exchange c
         a exchange c[w]
         a - c -> c[w]
         a + b -> a[w]
         m1 exchange c
L04742:  a -> b[w]
         c -> a[s]
         c - 1 -> c[p]
         if n/c go to L04732
         a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[m] = 0
           then go to L05043
         c - 1 -> c[s]
         c - 1 -> c[x]
         0 -> a[s]
         shift right a[w]
         go to L04742

L04760:  m1 -> c
         if s 13 = 1
           then go to L05063
         if s 10 = 0
           then go to L05063
         delayed rom @00
         jsb 1/x13
         delayed rom @12
         go to L05063

L04771:  m2 -> c
         m1 exchange c
         m1 -> c
         0 -> c[x]
         delayed rom @12
         go to L05022

         nop

S05000:  select rom go to x-ad2-10

S05001:  select rom go to x-ad1-10

         select rom go to x-ad2-13

         select rom go to x-mp2-10

         select rom go to x-mp1-10

S05005:  select rom go to x-mp2-13

         select rom go to x-dv2-10

S05007:  select rom go to x-dv1-10

S05010:  select rom go to x-dv2-13

S05011:  select rom go to x-x/y13

S05012:  select rom go to x-sqr13

S05013:  select rom go to x-stscr

S05014:  select rom go to L00415

S05015:  select rom go to L00416

S05016:  select rom go to L00417

S05017:  select rom go to S00420

S05020:  delayed rom @03
         go to S01572

L05022:  jsb S05011
         c -> stack
         jsb S05014
         jsb S05005
         if s 10 = 0
           then go to L05033
         stack -> a
         c -> stack
         a exchange c[w]
L05033:  jsb S05020
         if s 7 = 0
           then go to L05037
         0 - c - 1 -> c[s]
L05037:  stack -> a
         c -> stack
         a exchange c[w]
         go to L05102

L05043:  0 -> c[s]
         m1 exchange c
         a exchange c[w]
         m1 -> c
         a - 1 -> a[w]
         if s 13 = 1
           then go to L05054
         if s 10 = 1
           then go to L05056
L05054:  0 - c -> c[x]
         a exchange b[w]
L05056:  if b[m] = 0
           then go to L05107
         m1 exchange c
         delayed rom @00
         jsb div15
L05063:  if s 6 = 0
           then go to L05102
         jsb S05013
         a exchange c[w]
         c -> a[w]
         m1 exchange c
         b -> c[w]
         jsb S05005
         delayed rom @00
         jsb addone
         jsb S05012
         if s 13 = 1
           then go to L04771
         delayed rom @00
         jsb 1/x13
L05102:  if s 4 = 0
           then go to L05105
         0 - c - 1 -> c[s]
L05105:  delayed rom @04
         go to L02002

L05107:  0 -> c[w]
         p <- 12
         c - 1 -> c[wp]
         p <- 2
         load constant 1
         c -> a[w]
         a -> b[w]
         if s 6 = 0
           then go to L05105
         go to L05063

L05121:  b exchange c[w]	; g-shifted key 54 - ->H
         jsb S05131
         go to L05105

L05124:  a + c -> a[wp]
         shift right c[wp]
         if c[wp] # 0
           then go to L05124
         return

S05131:  if b[m] = 0
           then go to L05144
         p <- 12
         b -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[x]
         if c[xs] # 0
           then go to L05205
L05141:  p - 1 -> p
         if p # 0
           then go to L05146
L05144:  b -> c[w]
         return

L05146:  c - 1 -> c[x]
         if n/c go to L05141
L05150:  0 -> c[w]
         b -> c[m]
         if s 8 = 0
           then go to L05171
         p + 1 -> p
         if p # 13
           then go to L05161
         jsb S05212
         go to L05164

L05161:  p + 1 -> p
         jsb S05212
         p - 1 -> p
L05164:  p - 1 -> p
         jsb S05212
         c -> a[w]
         b -> c[w]
         go to L05203

L05171:  0 -> a[w]
         jsb S05210
         p + 1 -> p
         if p = 13
           then go to L05177
         p + 1 -> p
L05177:  jsb S05210
         shift left a[w]
         a + c -> a[w]
         b exchange c[w]
L05203:  delayed rom @00
         go to mpy150

L05205:  if b[xs] = 0
           then go to L05144
         go to L05150

S05210:  shift right c[wp]
         a + c -> c[wp]
S05212:  c -> a[wp]
         shift right c[wp]
         c + c -> c[wp]
         c + c -> c[wp]
         a - c -> c[wp]
         if s 8 = 0
           then go to L05124
         0 -> a[w]
         c -> a[x]
         a + c -> c[w]
         0 -> c[x]
         return

L05226:  jsb S05014
         if a[s] # 0
           then go to error_3
         jsb S05015
         if a[s] # 0
           then go to error_3
         delayed rom @03
         jsb S01642
         0 -> b[w]
         a exchange b[m]
         delayed rom @00
         jsb subone
         jsb S05013
         jsb S05016
L05244:  jsb S05014
         jsb S05011
         delayed rom @03
         jsb S01645
         jsb S05007
         jsb S05012
         if s 4 = 1
           then go to L05730
         jsb S05020
         delayed rom @03
         jsb S01630
         1 -> s 4
         jsb S05015
         go to L05244


crc_check_quad_2:
         rom check


L05263:  jsb S05016
         jsb S05010
         jsb S05020
         delayed rom @03
         jsb S01630
         0 -> a[w]
         0 -> b[w]
         delayed rom @13
         go to L05752

L05274:  0 -> s 13		; f-shifted key 21 - Q
         c -> register 10
         c -> a[w]
         0 -> a[s]
         if c[s] = 0
           then go to L05303
         1 -> s 13
L05303:  0 -> c[w]
         p <- 13		; compare to +/- 1.28 to determine which
         load constant 9	;   approximation to use
         load constant 1
         load constant 2
         load constant 8
         jsb S05000
         if a[s] # 0
           then go to L05345
         m2 -> c
         0 -> c[s]
         m2 exchange c
         delayed rom @06
         jsb S03124
         delayed rom @14
         jsb S06174
         jsb S05017
         delayed rom @15
         jsb S06425
         delayed rom @02
         jsb S01044
         jsb S05014
         jsb S05011
         delayed rom @15
         jsb S06501
         jsb S05005
         if s 13 = 1
           then go to L05343
         delayed rom @15
         jsb S06425
         delayed rom @00
         jsb addone
L05343:  delayed rom @04
         go to L02000

L05345:  delayed rom @06
         jsb S03124
         delayed rom @14
         jsb S06020
         delayed rom @05
         jsb S02555
         c - 1 -> c[x]
         load constant 5
         jsb S05001
         go to L05343


; more self-test
L05357:  delayed rom @15
         jsb crc_check_quad_3
         delayed rom @07
         jsb S03704
         0 -> c[w]
         p <- 12
L05365:  load constant 2
         if p # 2
           then go to L05365
         b exchange c[w]
         b -> c[w]
         c + c -> c[m]
         c + c -> c[m]
         a exchange c[w]
         delayed rom @06
         jsb get_key
         select rom go to L00000


S05400:  select rom go to x-ad2-10

S05401:  select rom go to x-ad1-10

S05402:  select rom go to x-ad2-13

S05403:  select rom go to x-mp2-10

S05404:  select rom go to x-mp1-10

S05405:  select rom go to x-mp2-13

         select rom go to x-dv2-10

S05407:  select rom go to x-dv1-10

S05410:  select rom go to x-dv2-13

S05411:  select rom go to x-x/y13

S05412:  select rom go to x-sqr13

S05413:  select rom go to x-stscr

S05414:  select rom go to L00415

S05415:  select rom go to L00416

S05416:  select rom go to L00417

S05417:  select rom go to S00420

S05420:  delayed rom @01
         go to L00545

         delayed rom @02
         go to S01044

L05424:  jsb S05621		; g-shifted key 63 - COSH-1
         jsb S05611
         jsb S05413
         m2 -> c
         jsb S05621
         jsb S05400
         jsb S05414
         jsb S05405
         jsb S05412
         jsb S05774
         jsb S05420
L05437:  delayed rom @04
         go to L02002

L05441:  jsb S05567		; g-shifted key 64 - TANH-1
         if s 6 = 1
           then go to L05437
         c -> a[w]
         p <- 12
         a - 1 -> a[p]
         if a[wp] # 0
           then go to L05455
         0 -> c[w]
         c - 1 -> c[wp]
         0 -> c[xs]
         go to L05541

L05455:  c -> a[w]
         jsb S05400
         0 -> a[s]
         jsb S05413
         m2 -> c
         0 -> c[s]
         jsb S05621
         jsb S05612
         jsb S05414
         jsb S05410
         jsb S05420
         go to L05540

L05471:  jsb S05567		; g-shifted key 62 - SINH-1
         if s 6 = 1
           then go to L05437
         c -> a[w]
         jsb S05617
         delayed rom @00
         jsb addone
         jsb S05412
         delayed rom @00
         jsb addone
         jsb S05414
         jsb S05410
         m2 -> c
         0 -> c[s]
         jsb S05401
         jsb S05420
         go to L05541

; hyperbolic functions
;   SINH - s4 = 1
;   COSH
;   TANH - s7 = 1
L05512:  jsb S05567
         if s 4 = 1
           then go to L05522
         if s 6 = 0
           then go to L05524
         jsb S05621
         a exchange c[w]
         go to L05437

L05522:  if s 6 = 1
           then go to L05437
L05524:  0 -> c[s]
         delayed rom @02
         jsb S01041
         jsb S05413
         if s 4 = 0
           then go to L05550
         jsb S05415
         jsb S05410
         jsb S05415
         jsb S05402
         if s 7 = 1
           then go to L05546
L05540:  jsb S05562
L05541:  c -> a[w]
         m2 -> c
         c -> a[s]
         a exchange c[w]
         go to L05437

L05546:  jsb S05417
         jsb S05413
L05550:  delayed rom @00
         jsb 1/x13
         jsb S05774
         if s 7 = 1
           then go to L05557
         jsb S05562
         go to L05437

L05557:  jsb S05415
         jsb S05410
         go to L05541

S05562:  0 -> c[w]
         p <- 12
         c - 1 -> c[x]
         load constant 5
         go to S05404

S05567:  if c[w] = 0
           then go to L05601
         if c[xs] = 0
           then go to L05602
         a exchange c[x]
         p <- 0
         load constant 5
         0 - c -> c[x]
         if a >= c[x]
           then go to L05602
L05601:  1 -> s 6
L05602:  m2 -> c
         return

S05604:  delayed rom @03
         go to S01645


error_3: p <- 3
         delayed rom @04
         go to error_p


S05611:  a exchange c[w]
S05612:  0 - c - 1 -> c[s]
         nop
         go to S05400

S05615:  c -> a[w]
         0 - c - 1 -> c[s]
S05617:  jsb S05403
         go to S05413

S05621:  delayed rom @06
         go to S03050

L05623:  1 -> s 6		; f-shifted key 23 - L.R.
L05624:  1 -> s 8		; f-shifted key 22 - lin est y
         go to L05632

         delayed rom @03
         go to S01642

L05630:  1 -> s 4		; g-shifted key 23 - r
L05631:  1 -> s 10		; g-shifted key 24 - std dev
L05632:  jsb S05604		; g-shifted key 22 - lin est x
         jsb S05621
         jsb S05611
         if c[s] # 0
           then go to error_3
         if c[m] = 0
           then go to error_3
         0 -> s 13
         0 -> s 7
         register -> c 3
         0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 1
         jsb S05617
         register -> c 5
         c -> a[w]
L05652:  jsb S05604
         jsb S05403
         jsb S05774
         jsb S05417
         if s 13 = 1
           then go to L05666
         1 -> s 13
         register -> c 3
         jsb S05615
         register -> c 4
         c -> a[w]
         go to L05652

L05666:  if s 7 = 1
           then go to L05676
         1 -> s 7
         register -> c 1
         jsb S05615
         register -> c 2
         c -> a[w]
         go to L05652

L05676:  if s 4 = 1
           then go to L05732
         if s 10 = 1
           then go to L05226
         if s 6 = 1
           then go to L05750
         if s 8 = 1
           then go to L05750
         jsb S05416
         jsb S05764
         register -> c 3
         0 - c - 1 -> c[s]
         jsb S05401
         jsb S05414
         jsb S05405
         jsb S05417
         jsb S05416
         register -> c 1
L05720:  jsb S05404
         jsb S05774
         jsb S05416
         jsb S05411
         jsb S05604
         jsb S05407
         if s 6 = 0
           then go to L05437
L05730:  delayed rom @04
         go to L02000

L05732:  jsb S05414
         jsb S05415
         jsb S05405
         if a[s] # 0
           then go to error_3
         if c[m] = 0
           then go to error_3
         m2 -> c
         delayed rom @06
         jsb S03072
         jsb S05412
         jsb S05416
         jsb S05410
         go to L05730

L05750:  jsb S05414
         jsb S05764
L05752:  register -> c 1
         0 - c - 1 -> c[s]
         jsb S05401
         jsb S05416
         jsb S05405
         jsb S05413
         jsb S05413
         jsb S05416
         register -> c 3
         go to L05720

S05764:  if b[m] = 0
           then go to error_3
         if s 6 = 1
           then go to L05263
         jsb S05604
         c -> a[w]
         m2 -> c
         go to S05403

S05774:  jsb S05414
         go to S05402

         nop

	 .dw @1672			; CRC, quad 2 (@4000..@5777)

S06000:  delayed rom @00
         go to mp2-13

S06002:  select rom go to x-ad2-13

S06003:  0 -> c[w]
S06004:  m1 exchange c
S06005:  delayed rom @05
         go to S02555

S06007:  delayed rom @01
         go to S00535

S06011:  select rom go to x-x/y13

S06012:  delayed rom @01
         go to S00515

S06014:  0 -> c[w]
         0 - c - 1 -> c[s]
         c + 1 -> c[x]
         if n/c go to S06004
S06020:  jsb S06007
         jsb S06003
         load constant 5	; Q constant a7
         load constant 9
         load constant 2
         load constant 8
         load constant 8
         load constant 5
         load constant 7
         load constant 2
         load constant 4
         load constant 4
         load constant 3
         load constant 8
         jsb S06002
         jsb S06005
         c + 1 -> c[x]
         jsb S06004
         load constant 4	; Q constant a6
         load constant 8
         load constant 6
         load constant 9
         load constant 5
         load constant 9
         load constant 9
         load constant 3
         load constant 0
         load constant 6
         load constant 9
         load constant 2
         jsb S06011
         jsb S06007
         jsb S06002
         jsb S06003
         load constant 2	; Q constant a5
         load constant 6
         load constant 2
         load constant 4
         load constant 3
         load constant 3
         load constant 1
         load constant 2
         load constant 1
         load constant 6
         load constant 7
         load constant 9
         jsb S06002
         jsb S06014
         load constant 2	; Q constant a4
         load constant 9
         load constant 8
         load constant 2
         load constant 1
         load constant 3
         load constant 5
         load constant 5
         load constant 7
         load constant 8
         load constant 0
         load constant 8
         jsb S06011
         jsb S06007
         jsb S06002
         jsb S06003
         load constant 5	; Q constant a3
         load constant 7
         load constant 5
         load constant 8
         load constant 8
         load constant 5
         load constant 4
         load constant 8
         load constant 0
         load constant 4
         load constant 5
         load constant 8
         jsb S06002
         delayed rom @01
         jsb S00470
         jsb S06012
         delayed rom @15
         jsb S06474
         jsb S06004
         load constant 3	; Q constant a2
         load constant 9
         load constant 9
         load constant 9
         load constant 0
         load constant 3
         load constant 4
         load constant 3
         load constant 8
         load constant 5
         load constant 0
         load constant 4
         jsb S06000
         jsb S06007
         jsb S06011
         delayed rom @15	; Q constant a1 is derived from Q constant b1
         jsb S06501
         p <- 3
         load constant 4
         load constant 4
         load constant 4
         jsb S06002
         delayed rom @01
         jsb S00532
         go to S06000

S06174:  jsb S06012
         jsb S06003
         load constant 3	; Q constant bq
         load constant 9
         load constant 9
         load constant 0
         load constant 1
         load constant 9
         load constant 4
         load constant 1
         load constant 7
         load constant 0
         load constant 1
         load constant 1
         jsb S06002
         0 -> c[w]
         c + 1 -> c[x]
         jsb S06004
         load constant 3	; Q constant bp
         load constant 0
         load constant 7
         load constant 8
         load constant 9
         load constant 9
         load constant 3
         load constant 3
         load constant 0
         load constant 3
         load constant 4
         jsb S06011
         jsb S06012
         jsb S06002
         0 -> c[w]
         c - 1 -> c[x]
         jsb S06004
         load constant 7	; Q constant b10
         load constant 4
         load constant 2
         load constant 3
         load constant 8
         load constant 0
         load constant 9
         load constant 2
         load constant 4
         load constant 0
         load constant 2
         load constant 7
         jsb S06002
         jsb S06014
         load constant 1	; Q cosntant b9
         load constant 5
         load constant 1
         load constant 5
         load constant 0
         load constant 8
         load constant 9
         load constant 7
         load constant 2
         load constant 4
         load constant 5
         load constant 1
         jsb S06011
         jsb S06003
         load constant 4	; Q constant b8
         load constant 8
         load constant 3
         load constant 8
         load constant 5
         load constant 9
         load constant 1
         load constant 2
         load constant 8
         load constant 0
         load constant 8
         jsb S06002
         jsb S06012
         jsb S06002
         jsb S06003
         load constant 5	; Q constant b7
         load constant 2
         load constant 9
         load constant 3
         load constant 3
         load constant 0
         load constant 3
         load constant 2
         load constant 4
         load constant 9
         load constant 2
         load constant 6
         jsb S06011
         delayed rom @15
         jsb S06474
         jsb S06004
         load constant 1	; Q constant b6
         load constant 5
         load constant 1
         load constant 6
         load constant 7
         load constant 9
         load constant 1
         load constant 1
         load constant 6
         load constant 6
         load constant 3
         load constant 5
         jsb S06002
         jsb S06012
         jsb S06002
         jsb S06003
         load constant 1	; Q constant b5
         load constant 9
         load constant 8
         load constant 6
         load constant 1
         load constant 5
         load constant 3
         load constant 8
         load constant 1
         load constant 3
         load constant 6
         load constant 4
         jsb S06011
         jsb S06012
         jsb S06002
         0 -> c[w]
         p <- 0
         load constant 4
         0 - c -> c[x]
         jsb S06004
         delayed rom @15
         go to L06431

S06400:  select rom go to x-ad2-10

S06401:  select rom go to x-ad1-10

S06402:  select rom go to x-ad2-13

         select rom go to x-mp2-10

S06404:  select rom go to x-mp1-10

S06405:  select rom go to x-mp2-13

         select rom go to x-dv2-10

         select rom go to x-dv1-10

S06410:  select rom go to x-dv2-13

S06411:  select rom go to x-x/y13

S06412:  select rom go to x-sqr13

S06413:  select rom go to x-stscr

S06414:  select rom go to L00415

S06415:  select rom go to L00416

S06416:  select rom go to L00417

S06417:  select rom go to S00420

S06420:  delayed rom @02
         go to S01044

S06422:  0 -> c[w]
S06423:  delayed rom @14
         go to S06004

S06425:  a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         return

L06431:  load constant 3	; Q constant b4
         load constant 9
         load constant 8
         load constant 0
         load constant 6
         load constant 4
         load constant 7
         load constant 9
         load constant 4
         jsb S06402
         jsb S06422
         load constant 1	; Q constant b3
         p <- 6
         load constant 6
         load constant 1
         load constant 5
         load constant 3
         load constant 0
         load constant 2
         jsb S06411
         jsb S06415
         jsb S06402
         0 -> c[w]
         0 - c - 1 -> c[s]
         p <- 0			; Q constant b2
         load constant 8
         0 - c -> c[x]
         jsb S06423
         load constant 3
         load constant 8
         load constant 0
         load constant 5
         load constant 2
         go to S06402

S06473:  c -> a[w]
S06474:  0 -> c[w]
         p <- 12
         0 - c - 1 -> c[s]
         c - 1 -> c[x]
         return

S06501:  0 -> c[w]
         c - 1 -> c[x]
         m1 exchange c
         0 -> c[w]
         p <- 12
         load constant 3	; Q constant b1
         load constant 9
         load constant 8
         load constant 9
         load constant 4
         load constant 2
         load constant 2
         load constant 8
         load constant 0
         load constant 3
         load constant 8
         load constant 5
         return

L06523:  if c[s] = 0		; g-shifted key 21 - Q-1
           then go to L06527
L06525:  delayed rom @04
         go to error_0

L06527:  if c[xs] # 0
           then go to L06550
         if c[w] = 0
           then go to L06541
         delayed rom @06
         jsb S03050
         a - c -> c[w]
         if c[w] # 0
           then go to L06525
         1 -> s 8
L06541:  c - 1 -> c[w]
         0 -> c[xs]
         if s 8 = 0
           then go to L06546
         0 -> c[s]
L06546:  delayed rom @04
         go to L02002

L06550:  c -> register 10
         0 -> s 13
         jsb S06473
         load constant 9
         jsb S06400
         if c[s] = 0
           then go to L06625
         m2 -> c
         jsb S06473
         load constant 1
         jsb S06400
         if a[s] # 0
           then go to L06634
         m2 -> c
         jsb S06473
         load constant 5
         jsb S06400
         0 - c - 1 -> c[s]
         m2 exchange c
         jsb S06501
         jsb S06410
         jsb S06413
L06576:  jsb S06414
         jsb S06405
         delayed rom @06
         jsb S03134
         delayed rom @14
         jsb S06020
         m2 -> c
         jsb S06401
         jsb S06417
         jsb S06415
         jsb S06420
         jsb S06414
         jsb S06405
         jsb S06501
         jsb S06410
         jsb S06425
         jsb S06417
         jsb S06416
         jsb S06414
         jsb S06402
         jsb S06413
         jsb S06747
         go to L06576

L06625:  delayed rom @06
         jsb S03050
         m2 -> c
         0 - c - 1 -> c[s]
         jsb S06400
         m2 exchange c
         go to L06635

L06634:  1 -> s 13
L06635:  m2 -> c
         delayed rom @01
         jsb S00540
         jsb S06422
         0 - c - 1 -> c[s]
         load constant 2
         jsb S06404
         jsb S06412
         jsb S06413
         jsb S06423
         load constant 8
         jsb S06401
         delayed rom @14
         jsb S06014
         load constant 9
         load constant 4
         jsb S06411
         jsb S06414
         jsb S06402
         jsb S06423
         load constant 1
         load constant 3
         c + 1 -> c[x]
         jsb S06401
         0 -> c[w]
         0 - c - 1 -> c[s]
         jsb S06423
         load constant 6
         load constant 1
         jsb S06411
         jsb S06414
         jsb S06402
         jsb S06413
         jsb S06414
         jsb S06405
         delayed rom @06
         jsb S03134
         jsb S06417
         jsb S06413
         jsb S06415
         jsb S06420
         display toggle
         jsb S06413
L06710:  delayed rom @14
         jsb S06174
         delayed rom @00
         jsb 1/x13
         jsb S06425
         jsb S06413
         jsb S06415
         jsb S06501
         jsb S06410
         m2 -> c
         jsb S06404
         jsb S06414
         jsb S06402
         jsb S06416
         jsb S06405
         jsb S06413
         delayed rom @00
         jsb addone
         jsb S06416
         jsb S06410
         jsb S06413
         delayed rom @01
         jsb S00543
         jsb S06423
         load constant 2
         jsb S06404
         0 -> a[s]
         jsb S06412
         jsb S06417
         jsb S06747
         go to L06710

S06747:  jsb S06413
         jsb S06416
         if b[m] = 0
           then go to L06763
         if a[xs] # 0
           then go to L06756
         go to L06761

L06756:  p <- 1
         a + 1 -> a[p]
         if n/c go to L06763
L06761:  display toggle
         go to S06415

L06763:  display off
         jsb S06415
         a exchange b[w]
         delayed rom @00
         jsb nrm11
         if s 13 = 0
           then go to L06773
         0 - c - 1 -> c[s]
L06773:  delayed rom @04
         go to L02000


crc_check_quad_3:
         rom check


         nop

	 .dw @1475			; CRC, half of quad 3 (@6000..@6777

         .fillto @10000
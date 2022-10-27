; 31E model-specific firmware, uses 1820-2105 CPU ROM
; Copyright 2022 Eric Smith <spacewar@gmail.com>

	.arch woodstock

	.include "1820-2105.inc"

; flags:
shft    .equ 6
rad     .equ 12
grad    .equ 14		; with s12 = 0

	.bank 0
	.org @2000

         jsb S02062
         jsb S02262
L02002:  delayed rom @00
         jsb S00054
L02004:  delayed rom @06
         go to L03000

fn_grd:  1 -> s grad
         go to L02076

fn_to_mm:
         delayed rom @07
         jsb S03605
         a -> rom address

fn_to_deg_c:
         jsb S02062
         0 - c - 1 -> c[s]
         jsb S02165
         jsb S02064
         go to L02022

         jsb S02062
         jsb S02262
L02022:  delayed rom @00
         jsb S00137
         go to L02004

S02025:  jsb S02062
         c - 1 -> c[x]
         load constant 4
         load constant 5
         load constant 3
         load constant 5
         load constant 9
         load constant 2
         load constant 3
         load constant 7
         return

         jsb S02062
         delayed rom @00
         jsb S00054
         jsb S02064
         jsb S02165
         go to L02004

L02046:  1 -> s 10
         if 0 = s shft
           then go to L02125
         if 0 = s 7
           then go to L02174
         0 -> s 7
         go to L02370

L02055:  0 - c - 1 -> c[s]
L02056:  jsb S02170
         go to L02243

         jsb S02025
         go to L02022

S02062:  m2 exchange c
         m2 -> c
S02064:  a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 8
         p <- 12
         return

fn_rad:  1 -> s rad
         go to L02212

fn_deg:  0 -> s grad
L02076:  0 -> s rad
         go to L02212

L02100:  1 -> s shft
L02101:  1 -> s 13
         delayed rom @03
         go to L01420

L02104:  delayed rom @03
         jsb S01756
         go to L02343

fn_to_deg:
         jsb S02176
         0 -> a[w]
         a exchange c[m]
         b exchange c[w]
         delayed rom @03
         jsb S01756
         b exchange c[w]
         delayed rom @02
         go to L01345

         1 -> s 10
         go to L02100

L02122:  if 0 = s 10
           then go to L02046
         0 -> s 10
L02125:  if s 4 = 1
           then go to L02172
         1 -> s 4
         go to L02370

fn_lstx: m2 -> c
L02132:  m1 exchange c
         if 0 = s 2
           then go to L02136
         c -> stack
L02136:  m1 -> c
         go to L02004

         go to L02101

L02141:  delayed rom @00
         jsb S00054
         go to L02243

S02144:  binary
         if s 4 = 1
           then go to L02157
         if 0 = s 2
           then go to L02152
         c -> stack
L02152:  1 -> s 2
         1 -> s 4
         0 -> a[ms]
         a - 1 -> a[m]
         0 -> c[w]
L02157:  return

L02160:  1 -> s shft
L02161:  c -> a[w]
         go to L02303

fn_to_kg:
         jsb S02025
         go to L02002

S02165:  load constant 3
         load constant 2
         c + 1 -> c[x]
S02170:  delayed rom @00
         go to S00230

L02172:  0 -> s 4
         go to L02370

L02174:  1 -> s 7
         go to L02370

S02176:  delayed rom @00
         go to S00132

         1 -> s 10
         go to L02160

fn_mant_clr_prefix:
         delayed rom @07
         jsb S03612
         c -> a[w]
         0 -> b[w]
         display toggle
L02207:  0 -> s 15
         if s 15 = 1
           then go to L02207
L02212:  delayed rom @06
         go to L03015

L02214:  0 -> s 0
         go to L02212

         nop
         nop
         go to L02161

L02221:  shift right a[x]
         shift right a[x]
         a exchange c[w]
         c -> data address
         data -> c
         if p = 13
           then go to L02132
         a exchange c[w]
         if p = 12
           then go to L02247
         if p = 11
           then go to L02056
         if p = 10
           then go to L02055
         if p = 9
           then go to L02141
         delayed rom @00
         jsb S00137
L02243:  delayed rom @00
         jsb S00006
         if s 11 = 1
           then go to L03412
L02247:  c -> data
         m1 -> c
         go to L02004

fn_pi:   delayed rom @03
         jsb S01756			; get pi/4
         c + c -> c[w]			; multiply by four
         c + c -> c[w]
         shift right c[w]
         c + 1 -> c[m]
         0 -> c[x]
         go to L02132

S02262:  load constant 2
         load constant 5
         load constant 4
         c + 1 -> c[x]
         return

L02267:  p + 1 -> p
         return

fn_to_rad:
         jsb S02176
         delayed rom @02
         go to L01356

         nop

fn_to_rect:
         delayed rom @07
         jsb S03605
         1 -> s 13
         1 -> s shft
         1 -> s 10
         stack -> a
L02303:  m2 exchange c
         a exchange c[w]
         0 -> a[w]
         0 -> b[w]
         a exchange c[m]
         if c[s] = 0
           then go to L02317
         1 -> s 7
         if s 10 = 1
           then go to L02316
         1 -> s 4
L02316:  0 -> c[s]
L02317:  b exchange c[w]
         if s rad = 1
           then go to L02104
         if 0 = s grad
           then go to L02330
         a exchange c[w]
         c -> a[w]
         shift right c[w]
         a - c -> a[w]
L02330:  delayed rom @01
         jsb S00442
         b exchange c[w]
         c - 1 -> c[x]
         if c[xs] # 0
           then go to L02342
         c - 1 -> c[x]
         if n/c go to L02342
         c + 1 -> c[x]
         shift right a[w]
L02342:  b exchange c[w]
L02343:  m1 exchange c
         m1 -> c
         c + c -> c[w]
         c + c -> c[w]
         c + c -> c[w]
         shift right c[w]
         b exchange c[w]
	 if c[xs] # 0
           then go to L02373
         delayed rom @01
         jsb S00553
         0 -> c[w]
         b exchange c[w]
         m1 -> c
         c + c -> c[w]
         shift left a[w]
         if 0 = s rad
           then go to L02367
         shift right a[w]
         shift right c[w]
L02367:  b exchange c[w]
L02370:  a - b -> a[w]
         if n/c go to L02122
         a + b -> a[w]
L02373:  b exchange c[w]
         m1 -> c
         b exchange c[w]
         if 0 = s rad
           then go to L02504
         if c[x] # 0
           then go to L02503
         shift left a[w]
         go to L02504

L02404:  p <- 12
         m1 -> c
         if s 10 = 1
           then go to L02717
         if 0 = s 13
           then go to L02542
         b exchange c[w]
         m2 -> c
         delayed rom @05
         jsb S02754
         c -> stack
         m2 -> c
         a exchange b[w]
         delayed rom @00
         jsb S00056
L02423:  if 0 = s 4
           then go to L02426
         0 - c - 1 -> c[s]
L02426:  delayed rom @06
         go to L03000

L02430:  p - 1 -> p
         if p = 6
           then go to L02404
L02433:  c + 1 -> c[x]
         if n/c go to L02430
L02435:  0 -> c[w]
         b exchange c[w]
L02437:  delayed rom @01
         jsb S00403
         b exchange c[w]
         delayed rom @01
         jsb S00541
         if p # 6
           then go to L02437
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
         go to L02557

S02461:  0 -> b[w]
         b exchange c[x]
         p <- 12
         b -> c[w]
         c + c -> c[x]
         if n/c go to L02740
         b -> c[w]
         delayed rom @03
         jsb S01751
L02472:  a + 1 -> a[p]
         if n/c go to L02476
         p + 1 -> p
         go to L02472

L02476:  delayed rom @00
         jsb S00127
L02500:  0 -> b[w]
         delayed rom @00
         go to S00325

L02503:  c + 1 -> c[x]
L02504:  if c[xs] # 0
           then go to L02513
         a - b -> a[w]
         if n/c go to L02761
         a + b -> a[w]
L02511:  delayed rom @00
         jsb S00274
L02513:  0 -> a[s]
         if s rad = 1
           then go to L02530
         b exchange c[w]
         m1 -> c
         b exchange c[w]
         delayed rom @00
         jsb S00160
         m1 exchange c
         delayed rom @03
         jsb S01756
         delayed rom @00
         jsb S00116
L02530:  c - 1 -> c[x]
         m1 exchange c
         m1 -> c
         c + 1 -> c[x]
         if n/c go to L02433
         shift left a[w]
         go to L02435

L02537:  0 -> c[w]
         0 -> a[w]
         a + 1 -> a[p]
L02542:  delayed rom @00
         jsb S00311
         go to L02426

L02545:  shift right a[wp]
         shift right a[wp]
L02547:  a - 1 -> a[s]
         if n/c go to L02545
         0 -> a[s]
         m1 exchange c
         a exchange c[w]
         a - c -> c[w]
         a + b -> a[w]
         m1 exchange c
L02557:  a -> b[w]
         c -> a[s]
         c - 1 -> c[p]
         if n/c go to L02547
         a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[m] = 0
           then go to L02575
         c - 1 -> c[s]
         0 -> a[s]
         shift right a[w]
         go to L02557

L02574:  c + 1 -> c[x]
L02575:  c - 1 -> c[s]
         if n/c go to L02574
         0 -> c[s]
         m1 exchange c
         a exchange c[w]
         a - 1 -> a[w]
         m1 -> c
         if s 10 = 1
           then go to L02610
         0 - c -> c[x]
         a exchange b[w]
L02610:  if b[w] = 0
           then go to L02704
         delayed rom @00
         jsb S00160
         if 0 = s shft
           then go to L02542
         a -> b[w]
         p <- 1
         a + b -> a[p]
         if n/c go to L02631
         shift left a[w]
         a + 1 -> a[ms]
         if n/c go to L02632
         a + 1 -> a[s]
         shift right a[w]
         a -> b[w]
         c + 1 -> c[x]
L02631:  shift left a[w]
L02632:  a exchange c[ms]
         delayed rom @00
         jsb S00122
         jsb S02461
         if 0 = s 13
           then go to L02671
         b exchange c[w]
         a exchange b[w]
         m2 -> c
         a exchange c[w]
         delayed rom @00
         jsb S00152
         a exchange c[w]
         m1 exchange c
         a + c -> c[x]
         c -> stack
         m1 -> c
         a exchange c[w]
         jsb S02752
         stack -> a
         c -> stack
         m2 -> c
         a exchange c[x]
         0 -> a[x]
         shift right a[w]
         m1 exchange c
         delayed rom @00
         jsb S00116
         delayed rom @00
         jsb S00060
         go to L02737

L02671:  b exchange c[w]
         a exchange b[w]
         m1 -> c
         a exchange c[w]
         a - c -> c[x]
         0 -> a[x]
         shift right a[w]
         delayed rom @00
         jsb S00160
         0 -> c[s]
         go to L02542

L02704:  0 -> c[w]
         if s shft = 1
           then go to L02713
         c - 1 -> c[w]
         0 -> c[xs]
         0 -> c[s]
         go to L02426

L02713:  if 0 = s 13
           then go to L02537
         0 -> c[m]
         go to L02735

L02717:  if s shft = 1
           then go to L02725
         a exchange b[w]
         delayed rom @00
         jsb S00215
         go to L02542

L02725:  if 0 = s 13
           then go to L02537
         b exchange c[w]
         a exchange b[w]
         m2 -> c
         delayed rom @00
         jsb S00056
         jsb S02754
L02735:  c -> stack
         m2 -> c
L02737:  go to L02423

L02740:  b -> c[w]
L02741:  c - 1 -> c[x]
         if n/c go to L02745
         b -> c[w]
         go to L02472

L02745:  p - 1 -> p
         if p # 0
           then go to L02741
         b -> c[w]
         go to L02500

S02752:  delayed rom @00
         jsb S00060
S02754:  if 0 = s 7
           then go to L02757
         0 - c - 1 -> c[s]
L02757:  delayed rom @00
         go to S00006

L02761:  a exchange b[w]
         a - b -> a[w]
         delayed rom @03
         jsb S01743
         go to L02511

L02766:  p <- 5
         a exchange c[w]
         0 - c - 1 -> c[p]
         a exchange c[w]
         delayed rom @06
         go to L03264

fn_fix:  delayed rom @00
         jsb S00316
         go to L02426

fn_clr_stk:
         clear regs
L03000:  go to L03014

L03001:  go to L03211

L03002:  p <- 0				; cold start
         load constant 4
         a exchange c[w]
         f exchange a[x]
fn_clear_all:
         0 -> c[w]
         m2 exchange c
         clear regs
fn_clear_reg:
         clear data registers
L03012:  0 -> s 2
         go to L03015

L03014:  1 -> s 2
L03015:  delayed rom @07
         jsb S03605
         display off
         delayed rom @00
         jsb S00006
         m1 exchange c
         m1 -> c
         jsb S03035
         if s 0 = 1
           then go to L03222
         if c[xs] # 0
           then go to L03045
L03031:  c - 1 -> c[x]
         if n/c go to L03214
         0 -> c[x]
         go to L03225

S03035:  0 -> a[w]
         f -> a[x]
         p <- 12
         0 -> c[s]
L03041:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L03041
L03044:  return

L03045:  0 -> a[x]
         c -> a[m]
L03047:  shift right a[w]
         c + 1 -> c[x]
         if n/c go to L03047
         go to L03227

L03053:  if s 8 = 1
           then go to L03057
         c + 1 -> c[s]
         p - 1 -> p
L03057:  if c[xs] # 0
           then go to L03066
         c + 1 -> c[x]
         if c[xs] = 0
           then go to L03067
         p <- 2
         go to L03222

L03066:  c + 1 -> c[x]
L03067:  shift right a[ms]
         go to L03241

S03071:  rotate left a
         a + b -> a[x]
L03073:  if a[s] # 0
           then go to L02157
         a - 1 -> a[x]
         shift left a[ms]
         go to L03073

L03100:  if s 9 = 1
           then go to L03262
         delayed rom @04
         jsb S02144
         p <- 3
L03105:  a + 1 -> a[p]
         if n/c go to L03112
         shift left a[wp]
         p + 1 -> p
         go to L03105

L03112:  a - 1 -> a[p]
         if p = 3
           then go to L03135
         if p = 13
           then go to L03122
         if s 3 = 1
           then go to L03122
         a + 1 -> a[s]
L03122:  0 -> a[x]
         a -> b[w]
         p - 1 -> p
         if b[m] = 0
           then go to L03132
         decimal
         jsb S03071
         shift right a[ms]
L03132:  c -> a[s]
         a exchange c[w]
         a exchange b[w]
L03135:  binary
         p - 1 -> p
         0 -> a[wp]
         a - 1 -> a[wp]
L03141:  m1 exchange c
L03142:  m1 -> c
         0 -> b[w]
         b exchange c[w]
         a exchange c[s]
         c -> a[s]
         p <- 12
         if b[s] = 0
           then go to L03155
         load constant 4
         p <- 13
L03154:  p - 1 -> p
L03155:  c - 1 -> c[s]
         if n/c go to L03154
L03157:  c + 1 -> c[p]
         jsb S03166
         jsb S03166
         jsb S03166
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L03157
S03166:  if p # 12
           then go to L02267
         if a[x] # 0
           then go to L03174
         p <- 5
         load constant 6
L03174:  b exchange c[w]
L03175:  0 -> a[x]
         decimal
         display toggle
L03200:  0 -> s 15
         if s 15 = 1
           then go to L03200
L03203:  if 0 = s 15
           then go to L03203
         if p # 3
           then go to L03445
         m1 -> c
         go to L03015

L03211:  p <- 0
         delayed rom @07
         go to L03412

L03214:  if p = 2
           then go to L03217
         p - 1 -> p
L03217:  c + 1 -> c[s]
         if n/c go to L03031
         jsb S03035
L03222:  1 -> s 8
         m1 -> c
         0 -> c[s]
L03225:  0 -> a[w]
         c -> a[m]
L03227:  0 -> b[w]
         a -> b[wp]
         a + b -> a[w]
         0 -> a[wp]
         if a[w] # 0
           then go to L03237
         if c[m] # 0
           then go to L03222
L03237:  if a[s] # 0
           then go to L03053
L03241:  c -> a[s]
         if c[xs] = 0
           then go to L03246
         0 - c -> c[x]
         c - 1 -> c[xs]
L03246:  binary
         a - 1 -> a[wp]
         if 0 = s 8
           then go to L03142
         c -> a[x]
         p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         go to L03142

L03260:  0 -> b[x]
         go to L03301

L03262:  p <- 4
         shift left a[wp]
L03264:  a -> b[w]
         p <- 5
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         a exchange b[x]
         p <- 1
         if b[xs] = 0
           then go to L03301
         a - b -> a[wp]
         if n/c go to L03260
         a -> b[wp]
         0 -> a[x]
L03301:  jsb S03071
         a exchange c[x]
         0 -> b[x]
         a exchange b[w]
         delayed rom @00
         jsb S00006
         if p = 13
           then go to L03014
         go to L03141

S03312:  rom checksum		; computes checksum of quad 1 (@2000-@3777) and returns

L03313:  clear regs
         c + 1 -> c[w]
         m1 exchange c
         0 -> c[w]
         m1 exchange c
         m2 exchange c
         m2 exchange c
         down rotate
         down rotate
         down rotate
         down rotate
         b exchange c[w]
         a exchange b[w]
         f exchange a[x]
         f exchange a[x]
         a - 1 -> a[w]
         if a[w] # 0
           then go to L03402
         p <- 12
         c + 1 -> c[p]
L03337:  c -> data address
         c -> data
         p + 1 -> p
         c + 1 -> c[x]
         if p # 2
           then go to L03337
         c - 1 -> c[x]
L03346:  c -> data address
         a exchange c[w]
         data -> c
         a exchange c[w]
         a - c -> a[w]
         if a[w] # 0
           then go to L03402
         c - 1 -> c[x]
         if n/c go to L03346
         p <- 12

         delayed rom @00	; checksum quad 0 (@0000-@1777, in 1820-2105 CPU chip)
         jsb S00002
         jsb S03377

         jsb S03312		; checksum quad 1 (@2000-@3777)
         jsb S03377

         p <- 3
L03366:  load constant 2
         if p # 3
           then go to L03366
         c -> a[w]
         c + c -> c[w]
         c + c -> c[w]
         a exchange c[w]
         clear data registers
         go to L03174

S03377:  c + 1 -> c[p]
         if 0 = s 5
           then go to L03044
L03402:  0 -> c[x]
         m1 exchange c
         p <- 5
         go to L03412

key_25:  jsb S03612                   ; key 25 (@220): f
         1 -> s shft
         go to L03763

L03411:  p <- 12
L03412:  0 -> c[w]
         binary
         c - 1 -> c[w]
         0 -> b[w]
L03416:  p + 1 -> p
         c + 1 -> c[xs]
         if p # 1
           then go to L03416
         p <- 8
         load constant 14
         load constant 10
         load constant 10
         load constant 12
         load constant 10
         a exchange c[w]
         shift left a[w]
         shift left a[w]
         shift left a[w]
         go to L03763

L03435:  if s 9 = 1
           then go to L03141
         if c[m] = 0
           then go to L03665
         p <- 5
         if b[wp] = 0
           then go to L03673
         go to L03746

L03445:  display off
         keys -> rom address

fn_10_to_x:
         jsb S03605
         1 -> s 8
         delayed rom @01
         go to L00523

key_14:  if s shft = 1			; key 14 (@061): unshifted e^x,    shifted 10^x
           then go to fn_10_to_x
         jsb S03605			; e^x
         delayed rom @01
         go to L00447

         go to key_15			; key 15 (@060): unshifted ln,     shifted log
         go to key_14			; key 14 (@061): unshifted e^x,    shifted 10^x
         go to key_13			; key 13 (@062): unshifted y^x,    shifted pi
         go to key_12			; key 12 (@063): unshifted 1/x,    shifted SCI

key11:   if 0 = s shft			; key 11 (@064): unshifted sqrt,   shifted FIX
           then go to fn_fix
         jsb S03612			; sqrt
         go to L03472

fn_sci:  jsb S03612
         p <- 11
L03472:  1 -> s 10
         go to L03763

key_34:  if s shft = 1			; key 34 (@160): unshifted CLx, shifted CLEAR STK
           then go to fn_clr_stk
         0 -> c[w]
         go to L03572

         go to key_74			; key 74 (@100): unshifted %,       shifted ->kg
         go to key_73			; key 73 (@101): unshifted .,       shifted ->degC
         go to key_72			; key 72 (@102): unshifted 0,       shifted ->mm

         if s shft = 1			; key 71 (@103): unshifted divide,  shifted ->RAD
           then go to fn_to_rad
         if s 7 = 1			; divide
           then go to L03755
L03507:  delayed rom @00
         jsb S00142
         go to L03656

key_24:  if s shft = 1			; key 24 (@221): unshifted RCL,      shifted LSTx
           then go to fn_lstx

         jsb S03612			; RCL
         p <- 13
L03516:  1 -> s 7
         go to L03763

L03520:  a + 1 -> a[xs]
key_72:  if s shft = 1			; key 72 (@102): unshifted 0,       shifted ->mm
           then go to fn_to_mm
L03523:  if s 7 = 1
           then go to L02221
         if 0 = s 10
           then go to L03100
         shift right a[x]
         shift right a[x]
         f exchange a[x]
         1 -> s 0
         if p = 11
           then go to L03015
         delayed rom @04
         go to L02214

L03537:  a + 1 -> a[xs]
         a + 1 -> a[xs]			; key 54 (@140): unshifted 6,     shifted TAN-1
         a + 1 -> a[xs]			; key 53 (@141): unshifted 5,     shifted COS-1
         if n/c go to L03715		; key 52 (@142): unshifted 4,     shifted SIN-1

         if s shft = 1			; key 51 (@143): unshifted plus,  shifted ->P
           then go to fn_to_polar
         if 0 = s 7			; plus
           then go to L03551
         if p = 12
           then go to L03762
L03551:  m2 exchange c
         m2 -> c
         go to L03654

key_15:  if s shft = 1			; key 15 (@060): unshifted ln,     shifted log
           then go to fn_log
         jsb S03605			; ln
         go to L03576

         go to key_34			; key 34 (@160): unshifted CLx, shifted CLEAR STK
         go to key_33			; key 33 (@161): unshifted EEX, shifted CLEAR REG
         go to key_32			; key 32 (@162): unshifted CHS, shifted CLEAR ALL

         if s shft = 1			; key 31 (@163): unshited ENTER^, shifted MATN/CLEAR PREFIX
           then go to fn_mant_clr_prefix
         if 0 = s 7			; ENTER^
           then go to L03571
         if p = 12
           then go to L03313
L03571:  c -> stack
L03572:  delayed rom @06
         go to L03012

fn_log:  jsb S03605
L03575:  1 -> s shft
L03576:  1 -> s 8
         delayed rom @02
         go to L01000

key_12:  if s shft = 1			; key 12 (@063): unshifted 1/x,    shifted SCI
           then go to fn_sci
         delayed rom @00		; 1/x
         go to L00035

S03605:  0 -> s 3
         0 -> s 4
         0 -> s 8
         0 -> s 9
         0 -> s 13
S03612:  0 -> s shft
         0 -> s 7
         0 -> s 10
         0 -> s 11
         p <- 12
         return

         go to key_25                   ; key 25 (@220): f
         go to key_24			; key 24 (@221): unshifted RCL,      shifted LSTx
         go to key_23			; key 23 (@222): unshifted STO,      shifted GRD
         go to key_22			; key 22 (@223): unhifted roll down, shifted RAD

         if s shft = 1			; key 21 (@224): unshifted x<>y,     shifted DEG
           then go to fn_deg
         jsb S03634			; x<>y
         go to L03656

key_74:  if s shft = 1			; key 74 (@100): unshifted %,       shifted ->kg
           then go to fn_to_kg
         delayed rom @00		; %
         go to L00044

S03634:  stack -> a
         c -> stack
         a exchange c[w]
         return

         a + 1 -> a[xs]			; key 44 (@240): unshifted 9,  shifted TAN
         a + 1 -> a[xs]			; key 43 (@241): unshifted 8,  shifted COS
         if n/c go to L03537		; key 42 (@242): unshifted 7,  shifted SIN

         if s shft = 1			; key 41 (@243): unshifted minus, shifted ->R
           then go to fn_to_rect
         if 0 = s 7			; minus
           then go to L03651
         if p = 12
           then go to L03761
L03651:  m2 exchange c
         m2 -> c
         0 - c - 1 -> c[s]
L03654:  delayed rom @00
         jsb S00222
L03656:  delayed rom @06
         go to L03000

key_33:  if s shft = 1			; key 33 (@161): unshifted EEX, shifted CLEAR REG
           then go to fn_clear_reg
         jsb S03612			; EEX
         if s 4 = 1
           then go to L03435
L03665:  delayed rom @04
         jsb S02144
         0 -> b[w]
         load constant 1
         c -> a[w]
         a - 1 -> a[wp]
L03673:  1 -> s 9
         p <- 5
         a exchange b[wp]
         if a[m] # 0
           then go to L03141
         a exchange b[wp]
         0 -> s 9
         go to L03763

key_73:  if s shft = 1			; key 73 (@101): unshifted .,       shifted ->degC
           then go to fn_to_deg_c
         jsb S03612			; .
         1 -> s 3
         if 0 = s 4
           then go to L03523
         go to L03763

fn_to_polar:
         jsb S03605
         delayed rom @02
         go to L01371

L03715:  if s 7 = 1
           then go to L03411
         a + 1 -> a[xs]
         a + 1 -> a[xs]			; key 64 (@320): unshifted 3,   shifted ->lbm
         a + 1 -> a[xs]			; key 63 (@321): unshifted 2,   shifted ->degF
         if n/c go to L03520		; key 62 (@322): unshifted 1,   shifted ->in

         if s shft = 1			; key 61 (@323): unshifted times, shifted ->DEG
           then go to fn_to_deg
         if 0 = s 7			; multiply
           then go to L03731
         if p = 12
           then go to L03760
L03731:  delayed rom @00
         jsb S00052
         go to L03656

key_32:  if s shft = 1			; key 32 (@162): unshifted CHS, shifted CLEAR ALL
           then go to fn_clear_all
         jsb S03612			; CHS
         if s 9 = 1
           then go to L02766
         if c[m] = 0
           then go to L03763
         0 - c - 1 -> c[s]
         if 0 = s 4
           then go to L03000
L03746:  a - 1 -> a[x]
         delayed rom @06
         go to L03141

key_23:  if s shft = 1			; key 23 (@222): unshifted STO,      shifted GRD
           then go to fn_grd

         jsb S03612			; STO
         go to L03516

L03755:  if p # 12
           then go to L03507
         p - 1 -> p
L03760:  p - 1 -> p
L03761:  p - 1 -> p
L03762:  p - 1 -> p
L03763:  delayed rom @06
         go to L03175

key_22:  if s shft = 1			; key 22 (@223): unhifted roll down, shifted RAD
           then go to fn_rad
         down rotate			; roll down
         go to L03656

key_13:  if s shft = 1			; key 13 (@062): unshifted y^x,    shifted pi
           then go to fn_pi
         jsb S03605			; y^x
         1 -> s 10
         jsb S03634
         go to L03575

	 .dw @0547			; CRC


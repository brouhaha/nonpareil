	.arch woodstock

	.include "1820-2105.inc"

; flags:
; f  s4=1 s6=1
; g  s4=1 s6=0

	.bank 0
	.org @2000

L02000:  1 -> s 13
         1 -> s 6
         1 -> s 10
         stack -> a
         go to L02006

L02005:  c -> a[w]
L02006:  m2 exchange c
         a exchange c[w]
         0 -> a[w]
         0 -> b[w]
         a exchange c[m]
         if c[s] = 0
           then go to L02022
         1 -> s 7
         if s 10 = 1
           then go to L02021
         1 -> s 4
L02021:  0 -> c[s]
L02022:  b exchange c[w]
         if s 12 = 1
           then go to L02131
         if 0 = s 14
           then go to L02033
         a exchange c[w]
         c -> a[w]
         shift right c[w]
         a - c -> a[w]
L02033:  delayed rom @01
         jsb S00442
         b exchange c[w]
         c - 1 -> c[x]
         if c[xs] # 0
           then go to L02045
         c - 1 -> c[x]
         if n/c go to L02045
         c + 1 -> c[x]
         shift right a[w]
L02045:  b exchange c[w]
L02046:  m1 exchange c
         m1 -> c
         c + c -> c[w]
         c + c -> c[w]
         c + c -> c[w]
         shift right c[w]
         b exchange c[w]
         if c[xs] # 0
           then go to L02076
         delayed rom @01
         jsb S00553
         0 -> c[w]
         b exchange c[w]
         m1 -> c
         c + c -> c[w]
         shift left a[w]
         if 0 = s 12
           then go to L02072
         shift right a[w]
         shift right c[w]
L02072:  b exchange c[w]
L02073:  a - b -> a[w]
         if n/c go to L02107
         a + b -> a[w]
L02076:  b exchange c[w]
         m1 -> c
         b exchange c[w]
         if 0 = s 12
           then go to L02142
         if c[x] # 0
           then go to L02141
         shift left a[w]
         go to L02142

L02107:  if 0 = s 10
           then go to L02120
         0 -> s 10
L02112:  if s 4 = 1
           then go to L02116
         1 -> s 4
         go to L02073

L02116:  0 -> s 4
         go to L02073

L02120:  1 -> s 10
         if 0 = s 6
           then go to L02112
         if 0 = s 7
           then go to L02127
         0 -> s 7
         go to L02073

L02127:  1 -> s 7
         go to L02073

L02131:  delayed rom @03
         jsb S01756
         go to L02046

L02134:  a exchange b[w]
         a - b -> a[w]
         delayed rom @03
         jsb S01743
         go to L02147

L02141:  c + 1 -> c[x]
L02142:  if c[xs] # 0
           then go to L02151
         a - b -> a[w]
         if n/c go to L02134
         a + b -> a[w]
L02147:  delayed rom @00
         jsb S00274
L02151:  0 -> a[s]
         if s 12 = 1
           then go to L02166
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
L02166:  c - 1 -> c[x]
         m1 exchange c
         m1 -> c
         c + 1 -> c[x]
         if n/c go to L02232
         shift left a[w]
         go to L02234

L02175:  0 -> c[w]
         0 -> a[w]
         a + 1 -> a[p]
L02200:  delayed rom @00
         jsb S00311
         go to L02225

L02203:  p <- 12
         m1 -> c
         if s 10 = 1
           then go to L02433
         if 0 = s 13
           then go to L02200
         b exchange c[w]
         m2 -> c
         delayed rom @05
         jsb S02517
         c -> stack
         m2 -> c
         a exchange b[w]
         delayed rom @00
         jsb S00056
L02222:  if 0 = s 4
           then go to L02225
         0 - c - 1 -> c[s]
L02225:  delayed rom @06
         go to L03000

L02227:  p - 1 -> p
         if p = 6
           then go to L02203
L02232:  c + 1 -> c[x]
         if n/c go to L02227
L02234:  0 -> c[w]
         b exchange c[w]
L02236:  delayed rom @01
         jsb S00403
         b exchange c[w]
         delayed rom @01
         jsb S00541
         if p # 6
           then go to L02236
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
         go to L02272

L02260:  shift right a[wp]
         shift right a[wp]
L02262:  a - 1 -> a[s]
         if n/c go to L02260
         0 -> a[s]
         m1 exchange c
         a exchange c[w]
         a - c -> c[w]
         a + b -> a[w]
         m1 exchange c
L02272:  a -> b[w]
         c -> a[s]
         c - 1 -> c[p]
         if n/c go to L02262
         a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[m] = 0
           then go to L02310
         c - 1 -> c[s]
         0 -> a[s]
         shift right a[w]
         go to L02272

L02307:  c + 1 -> c[x]
L02310:  c - 1 -> c[s]
         if n/c go to L02307
         0 -> c[s]
         m1 exchange c
         a exchange c[w]
         a - 1 -> a[w]
         m1 -> c
         if s 10 = 1
           then go to L02323
         0 - c -> c[x]
         a exchange b[w]
L02323:  if b[w] = 0
           then go to L02416
         delayed rom @00
         jsb S00160
         if 0 = s 6
           then go to L02200
         a exchange b[w]
         a exchange c[w]
         delayed rom @13
         jsb S05765
         b -> c[w]
         c -> register 1
         a exchange c[w]
         delayed rom @00
         jsb S00122
         delayed rom @05
         jsb S02461
         b exchange c[w]
         a exchange b[w]
         if 0 = s 13
           then go to L02402
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
         delayed rom @05
         jsb S02515
         stack -> a
         c -> stack
         m2 -> c
         a exchange c[s]
         register -> c 1
         a exchange c[w]
         m1 exchange c
         delayed rom @00
         jsb S00116
         delayed rom @00
         jsb S00060
         nop
         jsb S02524
         go to L02453

L02402:  m1 -> c
         a exchange c[w]
         a - c -> c[x]
         a exchange c[w]
         register -> c 1
         a exchange c[w]
         delayed rom @00
         jsb S00160
         0 -> c[s]
         jsb S02524
L02414:  delayed rom @04
         go to L02200

L02416:  0 -> c[w]
         if s 6 = 1
           then go to L02427
         c - 1 -> c[w]
         0 -> c[xs]
         1 -> s 11
         0 -> c[s]
L02425:  delayed rom @06
         go to L03000

L02427:  if 0 = s 13
           then go to L02175
         0 -> c[w]
         go to L02451

L02433:  if s 6 = 1
           then go to L02441
         a exchange b[w]
         delayed rom @00
         jsb S00215
         go to L02414

L02441:  if 0 = s 13
           then go to L02175
         b exchange c[w]
         a exchange b[w]
         m2 -> c
         delayed rom @00
         jsb S00056
         jsb S02517
L02451:  c -> stack
         m2 -> c
L02453:  delayed rom @04
         go to L02222

         nop
         nop
         nop
         nop

S02461:  0 -> b[w]
         b exchange c[x]
         p <- 12
         b -> c[w]
         c + c -> c[x]
         if n/c go to L02503
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

L02503:  b -> c[w]
L02504:  c - 1 -> c[x]
         if n/c go to L02510
         b -> c[w]
         go to L02472

L02510:  p - 1 -> p
         if p # 0
           then go to L02504
         b -> c[w]
         go to L02500

S02515:  delayed rom @00
         jsb S00060
S02517:  if 0 = s 7
           then go to L02522
         0 - c - 1 -> c[s]
L02522:  delayed rom @00
         go to S00006

S02524:  b exchange c[w]
         0 -> c[x]
         c -> data address
         b exchange c[w]
         return

L02531:  jsb S02637
         delayed rom @02
         go to L01356

L02534:  jsb S02637
         0 -> a[w]
         a exchange c[m]
         b exchange c[w]
         delayed rom @03
         jsb S01756
         b exchange c[w]
         delayed rom @02
         go to L01345

L02545:  jsb S02637
         b exchange c[w]
         jsb S02556
         go to L02425

L02551:  a + c -> a[wp]
         shift right c[wp]
         if c[wp] # 0
           then go to L02551
         return

S02556:  if b[m] = 0
           then go to L02571
         p <- 12
         b -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[x]
         if c[xs] # 0
           then go to L02634
L02566:  p - 1 -> p
         if p # 0
           then go to L02573
L02571:  b -> c[w]
         return

L02573:  c - 1 -> c[x]
         if n/c go to L02566
L02575:  0 -> c[w]
         b -> c[m]
         if 0 = s 8
           then go to L02616
         p + 1 -> p
         if p # 13
           then go to L02606
         jsb S02763
         go to L02611

L02606:  p + 1 -> p
         jsb S02763
         p - 1 -> p
L02611:  p - 1 -> p
         jsb S02763
         c -> a[w]
         b -> c[w]
         go to L02632

L02616:  0 -> a[w]
         jsb S02761
         p + 1 -> p
         if p = 13
           then go to L02624
         p + 1 -> p
L02624:  jsb S02761
         shift left a[w]
         a + c -> a[w]
         b exchange c[w]
         delayed rom @00
         jsb S00127
L02632:  delayed rom @00
         go to L00314

L02634:  if b[xs] = 0
           then go to L02571
         go to L02575

S02637:  delayed rom @00
         go to S00132

L02641:  delayed rom @12
         go to L05314

S02643:  rom checksum

L02644:  0 -> c[w]
         c -> data address
         0 -> s 3
         if s 3 = 1
           then go to L02660
         c -> register 9
         c -> register 10
         c -> register 11
         c -> register 12
         c -> register 13
         c -> register 14
         c -> register 15
L02660:  register -> c 8
         c -> a[xs]
         delayed rom @14
         go to L06357

L02664:  0 -> s 3
         if 0 = s 3
           then go to L03341
         0 -> b[w]
         m1 -> c
         c -> a[w]
         display off
         display toggle
L02674:  0 -> s 15
         if s 15 = 1
           then go to L02674
L02677:  0 -> c[x]
         p <- 2
         load constant 6
L02702:  c - 1 -> c[x]
         if n/c go to L02702
         display off
         delayed rom @06
         go to L03032

L02707:  if s 4 = 1
           then go to L03616
         if 0 = s 6
           then go to L02731
         if 0 = s 7
           then go to L02726
L02715:  if s 14 = 1
           then go to L03354
         a exchange c[p]
         a exchange c[wp]
         shift left a[wp]
         shift right c[wp]
         a exchange c[p]
L02724:  delayed rom @07
         go to L03433

L02726:  if s 8 = 1
           then go to L02715
         go to L02724

L02731:  if s 8 = 1
           then go to L02740
         if s 10 = 1
           then go to L03704
         if 0 = s 7
           then go to L03616
         go to L02715

L02740:  if s 10 = 1
           then go to L03326
         if s 13 = 1
           then go to L03352
         1 -> s 10
         delayed rom @07
         go to L03742

L02747:  if c[p] # 0
           then go to L02754
         p <- 5
         if c[p] = 0
           then go to L03131
L02754:  p <- 10
         shift right c[wp]
         shift right c[wp]
         delayed rom @06
         go to L03337

S02761:  shift right c[wp]
         a + c -> c[wp]
S02763:  c -> a[wp]
         shift right c[wp]
         c + c -> c[wp]
         c + c -> c[wp]
         a - c -> c[wp]
         if 0 = s 8
           then go to L02551
         0 -> a[w]
         c -> a[x]
         a + c -> c[w]
         0 -> c[x]
         return

         nop
L03000:  go to L03022

L03001:  go to L03346

L03002:  display off
         clear status
         0 -> c[w]
         p <- 1
         c + 1 -> c[p]
L03007:  c -> data address
         clear data registers
         c - 1 -> c[p]
         if n/c go to L03007
         p <- 0
         load constant 4
         c -> a[x]
         f exchange a[x]
         clear regs
         m2 exchange c
         0 -> c[w]
L03022:  delayed rom @00
         jsb S00006
         m1 exchange c
         if 0 = s 11
           then go to L03031
         0 -> s 2
         0 -> s 1
L03031:  clear status
L03032:  0 -> s 12
L03033:  jsb S03072
L03034:  jsb S03070
         if s 2 = 1
           then go to L03276
         0 -> s 1
         0 -> s 11
         0 -> s 3
         if 0 = s 3
           then go to L03273
         delayed rom @10
         jsb S04372
L03046:  display off
         display toggle
L03050:  0 -> s 15
         if s 15 = 1
           then go to L03050
L03053:  0 -> s 1
         0 -> s 3
         if 0 = s 3
           then go to L03063
         if 0 = s 11
           then go to L03065
         0 -> s 11
         go to L03032

L03063:  if 0 = s 11
           then go to L03272
L03065:  if s 15 = 1
           then go to L03400
         go to L03053

S03070:  delayed rom @07
         go to S03412

S03072:  if s 2 = 1
           then go to S03076
         if 0 = s 1
           then go to L03110
S03076:  register -> c 8
         p <- 3
         decimal
         c + 1 -> c[p]
         if n/c go to L03107
         p <- 4
         c + 1 -> c[p]
         c + c -> c[p]
         if n/c go to L03111
L03107:  c -> register 8
L03110:  return

L03111:  register -> c 8
         c + 1 -> c[p]
         p <- 3
         load constant 0
         go to L03107

L03116:  if s 2 = 1
           then go to L03131
         if s 1 = 1
           then go to L03032
         1 -> s 2
         0 -> s 12
L03124:  jsb S03362
         if c[x] # 0
           then go to L03164
         jsb S03076
         go to L03124

L03131:  jsb S03076
L03132:  0 -> s 2
         go to L03341

fn_bst:  jsb S03362
         if c[x] = 0
           then go to L03164
         decimal
         p <- 1
         c - 1 -> c[wp]
         register -> c 8
         p <- 3
         c - 1 -> c[p]
         if n/c go to L03150
         p <- 4
         c - 1 -> c[p]
L03150:  c -> register 8
         jsb S03362
         go to L03164

fn_sst:  1 -> s 1
         jsb S03362
         if c[x] = 0
           then go to L03162
         0 -> s 3
         if s 3 = 1
           then go to L03164
L03162:  jsb S03076
         jsb S03362
L03164:  a exchange b[w]
         c -> a[x]
         p <- 1
L03167:  shift left a[w]
         p + 1 -> p
         if p # 12
           then go to L03167
         p <- 10
         binary
         a - 1 -> a[wp]
         if c[x] # 0
           then go to L03222
         b exchange c[w]
         0 -> b[w]
L03202:  display off
         display toggle
         0 -> s 3
         if 0 = s 3
           then go to L03050
L03207:  0 -> s 15
         if s 15 = 1
           then go to L03207
         display off
         if s 4 = 1
           then go to L03341
         a exchange c[w]
         jsb S03362
         a exchange b[w]
         jsb S03230
         go to L03310

L03222:  jsb S03230
         delayed rom @10
         jsb S04040
         go to L03202

S03226:  delayed rom @11
         go to L04651

S03230:  jsb S03226
         0 -> c[xs]
L03232:  rotate left a
         rotate left a
         c - 1 -> c[x]
         if n/c go to L03232
         a exchange c[w]
         return

L03240:  b exchange c[x]
         jsb S03076
         jsb S03362
         if c[x] = 0
           then go to L03273
         jsb S03226
         a exchange b[w]
         p <- 1
L03250:  shift left a[w]
         p + 1 -> p
         if p # 13
           then go to L03250
         0 -> c[xs]
L03255:  if c[x] = 0
           then go to L03265
         c - 1 -> c[x]
         shift right a[w]
         shift right a[w]
         p - 1 -> p
         p - 1 -> p
         go to L03255

L03265:  a exchange b[p]
         p - 1 -> p
         a exchange b[p]
         b exchange c[w]
         c -> data
L03272:  jsb S03070
L03273:  1 -> s 11
         jsb S03362
         go to L03164

L03276:  jsb S03362
         if c[x] = 0
           then go to L03314
         if s 12 = 1
           then go to L03305
         if s 15 = 1
           then go to L03132
L03305:  a exchange b[w]
         jsb S03230
         display toggle
L03310:  a exchange b[w]
L03311:  jsb S03070
         delayed rom @14
         go to L06060

L03314:  register -> c 8
         p <- 6
         if c[p] # 0
           then go to L03323
         p <- 5
         if c[p] = 0
           then go to L03132
L03323:  c -> a[xs]
         delayed rom @14
         go to L06357

L03326:  if s 7 = 1
           then go to L03433
         c -> a[x]
L03331:  p <- 4
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         register -> c 8
         a exchange c[wp]
L03337:  a exchange c[xs]
L03340:  c -> register 8
L03341:  0 -> s 12
         go to L03034

L03343:  m1 exchange c
         1 -> s 9
         go to L03032

L03346:  p <- 0
L03347:  delayed rom @11
         jsb S04703
         go to L03032

L03352:  p <- 4
         go to L03347

L03354:  p <- 2
         go to L03347

L03356:  p <- 1
         a + c -> c[p]
         delayed rom @07
         go to L03433

S03362:  register -> c 8
         p <- 4
         shift right c[wp]
         shift right c[wp]
         shift right c[wp]
         return

L03370:  delayed rom @15
         jsb S06410
         c -> register 8
         0 -> s 12
         go to L03124

         nop
         nop
         nop
L03400:  display off
         register -> c 8
         p <- 1
         if s 13 = 1
           then go to L03407
         jsb S03412
         0 -> c[wp]
L03407:  binary
         0 -> s 13
         keys -> rom address

S03412:  0 -> s 4
         0 -> s 6
         0 -> s 7
         0 -> s 8
         0 -> s 10
         0 -> s 13
         0 -> s 14
         return

key_74:  load constant 10		; key 74 (@100): unshifted R/S,    f-shifted PAUSE, g-shifted %
         load constant 11
L03424:  p <- 1
         if 0 = s 4
           then go to L03433
         c + 1 -> c[p]
         if s 6 = 1
           then go to L03433
         c + 1 -> c[p]
L03433:  jsb S03412
         0 -> s 3
         if 0 = s 3
           then go to L03240
         delayed rom @06
         go to L03311

key_15:  jsb S03412			; key 15 (@060): g
         go to L03445

key_14:  jsb S03412			; key 14 (@061): f
         1 -> s 6
L03445:  1 -> s 4
L03446:  0 -> c[wp]
L03447:  1 -> s 13
         c -> register 8
         delayed rom @06
         go to L03046

L03453:  jsb S03412
         1 -> s 7
         1 -> s 8
         go to L03446

         nop

         go to key_15			; key 15 (@060): g
         go to key_14			; key 14 (@061): f
         go to key_13			; key 13 (@062): unshifted GTO, f-shifted ENG, g-shifted NOP
         go to key_12			; key 12 (@063): unshifted GSB, f-shifted SCI, g-shifted ENG

         if 0 = s 4			; key 11 (@064): unshifted SST, f-shifted FIX, g-shifted BST
           then go to fn_sst
         if 0 = s 6
           then go to fn_bst
         load constant 15		; FIX
L03471:  jsb S03412
         1 -> s 6
         load constant 0
         go to L03447

L03475:  load constant 5
         load constant 0
         go to L03433

         go to key_74			; key 74 (@100): unshifted R/S,    f-shifted PAUSE, g-shifted %
         go to key_73			; key 73 (@101): unshfited .,      f-shifted LSTx,  g-shfited pi
         go to key_72			; key 72 (@102): unshifted 0,      f-shifted sqrt,  g-shfited x^2

         jsb S03645			; key 71 (@103): unshifted divide, f-shifted x=y,   g-shifted x=0
         c + 1 -> c[x]
L03505:  c + 1 -> c[x]
L03506:  c + 1 -> c[x]
L03507:  c + 1 -> c[x]
         if p # 1
           then go to L03424
         go to L03742

key_12:  if 0 = s 4			; key 12 (@063): unshifted GSB, f-shifted SCI, g-shifted ENG
           then go to L03521
         if 0 = s 6
           then go to L03475
         load constant 14
         go to L03471

L03521:  jsb S03412
         1 -> s 10
         go to L03446

key_13:  if 0 = s 4			; key 13 (@062): unshifted GTO, f-shifted ENG, g-shifted NOP
           then go to L03453
         if 0 = s 6
           then go to L03532
         load constant 13
         go to L03471

L03532:  load constant 15
         load constant 11
         go to L03433

L03535:  c + 1 -> c[x]
         1 -> s 14
L03537:  c + 1 -> c[x]
         c + 1 -> c[x]			; key 54 (@0140): unshifted 6,      f-shifted ->H.MS,     g-shifted ->H
         if n/c go to L03715		; key 53 (@0141): unshifted 5,      f-shifted ->RAD,      g-shifted ->DEG
         go to L03717			; key 52 (@0142): unshifted 4,      f-shifted ->R,        g-shifted ->P

         jsb S03645			; key 51 (@0143): unshifted minus,  f-shifted x<=y,       g-shifted x<0
         go to L03506

key_34:  load constant 13		; key 34 (@0160): unshifted CLx,    f-shifted CLR STK,    g-shifted ABS
         load constant 15
         go to L03424

key_33:  load constant 13		; key 33 (@0161): unshifted EEX,    f-shifted CLR REG,    g-shifted FRAC
         go to L03771

key_32:  if 0 = s 4			; key 32 (@0162): unshifted CHS,    f-shifted CLR PRGM,   g-shifted INT
           then go to L03556
         if s 6 = 1
           then go to L02644
L03556:  load constant 13
         go to L03634

         go to key_34			; key 34 (@0160): unshifted CLx,    f-shifted CLR STK,    g-shifted ABS
         go to key_33			; key 33 (@0161): unshifted EEX,    f-shifted CLR REG,    g-shifted FRAC
         go to key_32			; key 32 (@0162): unshifted CHS,    f-shifted CLR PRGM,   g-shifted INT

         if s 4 = 1			; key 31 (@0163): unshifted ENTER^, f-shifted CLR PREFIX, g-shifted MANT
           then go to L03576
         if 0 = s 6
           then go to L03573
         if s 7 = 1
           then go to L03573
         if s 8 = 1
           then go to L02641
L03573:  load constant 14
         load constant 13
         go to L03433

L03576:  if 0 = s 6
           then go to L02664
         jsb S03412
         go to L03446

key_25:  if s 4 = 1			; key 25 (@220): unshifted Sigma+, f-shifted Sigma-,    g-shifted std dev
           then go to L03613
         if 0 = s 6
           then go to L03613
         if 0 = s 7
           then go to L03613
         load constant 9
L03611:  load constant 15
         go to L03433

L03613:  load constant 13
         load constant 12
         go to L03424

L03616:  load constant 10
         go to L03424

         go to key_25			; key 25 (@220): unshifted Sigma+, f-shifted Sigma-,    g-shifted std dev
         go to key_24			; key 24 (@221): unshifted RCL,    f-shifted L.R.,      g-shifted mean
         go to key_23			; key 23 (@222): unshifted STO,    f-shifted r,         g-shfited GRD
         go to key_22			; key 22 (@223): unshifted Rdn,    f-shifted lin est y, g-shifted RAD

         if 0 = s 4			; key 21 (@224): unshifted x<>y,   f-shifted lin est x, g-shifted DEG
           then go to L03633
         if s 6 = 1
           then go to L03633
         load constant 15		; DEG
L03631:  load constant 10
         go to L03433

L03633:  load constant 8
L03634:  load constant 13
         go to L03424

L03636:  load constant 13
         go to L03631

         c + 1 -> c[x]			; key 44 (@240): unshifted 9, f-shifted TAN, g-shifted TAN-1
         if n/c go to L03535		; key 43 (@241): unshifted 8, f-shifted COS, g-shifted COS-1
         go to L03537			; key 42 (@242): unshifted 7, f-shifted SIN, g-shifted SIN-1

         jsb S03645			; key 41 (@243): unshifted minus, f-shifted x<=y, g-shifted x<0
         go to L03507

S03645:  if s 4 = 1
           then go to L03655
         if 0 = s 6
           then go to L03655
         if s 7 = 1
           then go to L03655
         if s 8 = 1
           then go to L03660
L03655:  load constant 10
         load constant 11
         return

L03660:  jsb S03412
         1 -> s 7
         shift right c[wp]
         return

key_73:  if s 4 = 1			; key 73 (@101): unshfited .,      f-shifted LSTx,  g-shfited pi
           then go to L03701
         if s 6 = 1
           then go to L03701
         if 0 = s 7
           then go to L03701
         if 0 = s 8
           then go to L03701
         if s 10 = 1
           then go to L03701
         jsb S03412
         1 -> s 8
         go to L03446

L03701:  load constant 10
         load constant 10
         go to L03424

L03704:  if s 7 = 1
           then go to L03712
         if s 13 = 1
           then go to L03352
         1 -> s 7
         go to L03742

L03712:  if c[wp] = 0
           then go to L03352
         go to L03773

L03715:  c + 1 -> c[x]
         1 -> s 13
L03717:  c + 1 -> c[x]
         c + 1 -> c[x]			; key 64 (@320): unshifted 3,      f-shfited y^x,       g-shifted 1/x
         c + 1 -> c[x]			; key 63 (@321): unshifted 2,      f-shifted LOG,       g-shifted 10^x
         if n/c go to L03725		; key 62 (@322): unshifted 1,      f-shifted LN,        g-shifted e^x

         jsb S03645			; key 61 (@0323): unshifted times, f-shifted x#y,       g-shifted x#0
         go to L03505

L03725:  c + 1 -> c[x]
key_72:  delayed rom @05		; key 72 (@102): unshifted 0,      f-shifted sqrt,  g-shfited x^2
         go to L02707

key_24:  if 0 = s 4			; key 24 (@221): unshifted RCL,    f-shifted L.R.,      g-shifted mean
           then go to L03735
         load constant 12
         load constant 11
         go to L03424

L03735:  jsb S03412
         1 -> s 7
         load constant 0
         load constant 10
L03741:  1 -> s 6
L03742:  p <- 1
         a exchange c[wp]
         shift left a[wp]
         a exchange c[wp]
         go to L03447

key_23:  if 0 = s 4			; key 23 (@222): unshifted STO,    f-shifted r,         g-shfited GRD
           then go to L03755
         if 0 = s 6
           then go to L03636
         load constant 8		; GRD
         go to L03611

L03755:  jsb S03412
         load constant 0
         load constant 11
         1 -> s 8
         go to L03741

key_22:  if 0 = s 4			; key 22 (@223): unshifted Rdn,    f-shifted lin est y, g-shifted RAD
           then go to L03770
         if s 6 = 1
           then go to L03770
         load constant 14		; RAD
         go to L03631

L03770:  load constant 8
L03771:  load constant 14
         go to L03424

L03773:  a exchange c[p]
         load constant 5
         delayed rom @06
         go to L03356

         go to L04212

         go to L04024

         go to L04021

         go to L04023

         go to L04011

         go to L04015

         p <- 9
         jsb S04211
         jsb S04232
         go to L04024

L04011:  p <- 9
         jsb S04211
         jsb S04324
         go to L04024

L04015:  p <- 9
         jsb S04211
         jsb S04247
         go to L04024

L04021:  jsb S04206
         go to L04024

L04023:  jsb S04340
L04024:  p <- 3
         go to L04066

L04026:  jsb S04242
L04027:  load constant 3
         load constant 2
         go to L04067

         go to L04346

         go to L04140

         c - 1 -> c[p]
         c - 1 -> c[p]
         c - 1 -> c[p]
         if n/c go to L04067
S04040:  a exchange c[m]
         binary
         p <- 10
         load constant 9
         0 -> c[xs]
         c -> a[x]
         p <- 1
         load constant 10
         load constant 10
         p <- 0
         if a >= c[p]
           then go to L04077
         p <- 1
         if a >= c[p]
           then go to L04075
         load constant 5
         p <- 1
         if a >= c[p]
           then go to L04127
         p <- 7
         jsb S04324
L04065:  p <- 4
L04066:  jsb S04122
L04067:  c -> a[m]
         0 -> c[w]
         p <- 10
         load constant 6
         b exchange c[w]
         return

L04075:  a - c -> a[p]
         a -> rom address

L04077:  p <- 1
         if a >= c[p]
           then go to L04152
         load constant 8
         p <- 1
         if a >= c[p]
           then go to L04366
         load constant 10
         p <- 9
         jsb S04327
         load constant 7
         load constant 1
         p <- 3
         jsb S04123
         c -> a[wp]
         shift right a[x]
         a + 1 -> a[xs]
         p <- 6
         a -> rom address

S04122:  shift left a[wp]
S04123:  shift left a[wp]
         shift left a[wp]
         a exchange c[wp]
         return

L04127:  a - c -> a[p]
         if a[wp] # 0
           then go to L04135
         jsb S04342
         jsb S04247
         go to L04067

L04135:  p <- 7
         jsb S04247
         go to L04065

L04140:  jsb S04143
L04141:  jsb S04327
         go to L04067

S04143:  p <- 9
         0 -> c[wp]
         c - 1 -> c[wp]
         p <- 3
         a exchange c[p]
         p <- 6
         return

L04152:  a - c -> a[p]
         load constant 3
         p <- 1
         if a >= c[p]
           then go to L04221
         if a[p] # 0
           then go to L04200
L04161:  p <- 4
         load constant 7
         load constant 1
         load constant 7
         shift left a[wp]
         c -> a[xs]
L04167:  p <- 4
         a -> rom address

         nop
         go to L04353

         go to L04356

         c - 1 -> c[p]
         c - 1 -> c[p]
         c - 1 -> c[p]
         if n/c go to L04067
L04200:  jsb S04210
         p <- 1
         a - 1 -> a[p]
         if a[p] # 0
           then go to L04370
         go to L04161

S04206:  p <- 6
         go to S04211

S04210:  p <- 7
S04211:  load constant 1
L04212:  load constant 4
L04213:  p - 1 -> p
         return

         go to L04302

         go to L04306

         jsb S04210
         go to L04141

L04221:  load constant 7
         p <- 1
         a + c -> a[p]
         shift left a[x]
         jsb S04342
         p <- 4
         a -> rom address

L04230:  jsb S04210
         go to L04264

S04232:  load constant 1
         load constant 1
         go to L04213

         go to L04301

         go to L04305

         p <- 7
         jsb S04332
         go to L04270

S04242:  p <- 9
         0 -> c[wp]
         c - 1 -> c[wp]
         p <- 4
         return

S04247:  load constant 1
         load constant 2
         go to L04213

         go to L04141

         go to L04351

         go to L04267

         go to L04026

         go to L04263

         jsb S04242
L04260:  load constant 3
         load constant 4
         go to L04067

L04263:  jsb S04242
L04264:  load constant 3
         load constant 3
         go to L04067

L04267:  jsb S04242
L04270:  jsb S04335
         go to L04067

         go to L04306

         go to L04347

         go to L04322

         go to L04361

         go to L04230

         jsb S04210
         go to L04260

L04301:  jsb S04210
L04302:  load constant 2
         load constant 1
         go to L04067

L04305:  jsb S04210
L04306:  load constant 2
         load constant 2
         go to L04067

         nop
         go to L04302

         go to L04320

         go to L04270

         go to L04027

         go to L04264

         go to L04260

L04320:  jsb S04324
         go to L04067

L04322:  jsb S04210
         go to L04270

S04324:  load constant 1
         load constant 3
         go to L04213

S04327:  load constant 2
         load constant 3
         go to L04213

S04332:  load constant 2
         load constant 4
         go to L04213

S04335:  load constant 2
         load constant 5
         go to L04213

S04340:  p <- 6
         go to L04343

S04342:  p <- 7
L04343:  load constant 1
         load constant 5
         go to L04213

L04346:  jsb S04143
L04347:  jsb S04332
         go to L04067

L04351:  jsb S04210
         go to L04347

L04353:  load constant 7
         load constant 3
         go to L04067

L04356:  load constant 7
         load constant 4
         go to L04067

L04361:  jsb S04242
         load constant 3
         load constant 1
         go to L04067

S04365:  rom checksum

L04366:  shift left a[x]
         go to L04167

L04370:  jsb S04342
         go to L04161

S04372:  m1 -> c
         b exchange c[w]
         if s 12 = 1
           then go to L04544
         decimal
         register -> c 8
         0 -> s 0
         0 -> s 14
         if c[xs] = 0
           then go to L04411
         c - 1 -> c[xs]
         1 -> s 0
         if c[xs] = 0
           then go to L04411
         1 -> s 14
L04411:  b -> c[w]
         c -> a[w]
         if s 0 = 1
           then go to L04444
         if c[xs] # 0
           then go to L04432
         p <- 1
         load constant 1
         load constant 0
         if a >= c[x]
           then go to L04443
         0 -> a[x]
         f -> a[x]
         a + b -> a[x]
         if a >= c[x]
           then go to L04440
         go to L04446

L04432:  0 -> a[x]
         f -> a[x]
         a + 1 -> a[x]
         a + c -> a[x]
         if n/c go to L04443
         go to L04446

L04440:  c - 1 -> c[x]
         c -> a[x]
         go to L04446

L04443:  1 -> s 0
L04444:  0 -> a[x]
         f -> a[x]
L04446:  b -> c[w]
         0 -> c[s]
         p <- 12
L04451:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L04451
         if s 0 = 1
           then go to L04461
         if c[xs] = 0
           then go to L04461
         p + 1 -> p
L04461:  0 -> a[w]
         c -> a[wp]
         a + c -> a[ms]
         0 -> a[wp]
         a exchange c[ms]
         if c[s] = 0
           then go to L04502
         if 0 = s 0
           then go to L04523
         c + 1 -> c[x]
         if c[xs] = 0
           then go to L04501
         c - 1 -> c[xs]
         if c[xs] = 0
           then go to L04526
         c + 1 -> c[xs]
L04501:  shift right c[ms]
L04502:  c -> a[ms]
         binary
         a - 1 -> a[wp]
         c -> a[x]
         decimal
         if 0 = s 0
           then go to L04532
         if s 14 = 1
           then go to L04615
L04513:  if c[xs] = 0
           then go to L04520
         decimal
         0 - c -> c[x]
         c - 1 -> c[xs]
L04520:  a exchange c[x]
         jsb S04762
         go to L04544

L04523:  c + 1 -> c[x]
         p - 1 -> p
         go to L04501

L04526:  b -> c[w]
         c -> a[w]
         0 -> a[s]
         go to L04513

L04532:  0 -> a[s]
         if a[xs] # 0
           then go to L04606
         go to L04540

L04536:  a + 1 -> a[s]
         a - 1 -> a[x]
L04540:  if a[x] # 0
           then go to L04536
L04542:  binary
         a - 1 -> a[x]
L04544:  0 -> c[w]
         a exchange c[s]
         c -> a[s]
         binary
         a + 1 -> a[xs]
         if n/c go to L04603
L04552:  a - 1 -> a[xs]
         if b[s] = 0
           then go to L04557
         p <- 12
         load constant 4
L04557:  p <- 13
L04560:  p - 1 -> p
         a - 1 -> a[s]
         if n/c go to L04560
L04563:  c + 1 -> c[p]
         if p = 12
           then go to L04600
         p + 1 -> p
         if p = 12
           then go to L04600
         p + 1 -> p
         if p = 12
           then go to L04600
         p + 1 -> p
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L04563
L04600:  c -> a[s]
         b exchange c[w]
         return

L04603:  p <- 5
         load constant 6
         go to L04552

L04606:  if c[ms] = 0
           then go to L04443
L04610:  shift right a[w]
         c + 1 -> c[x]
         if c[x] # 0
           then go to L04610
         go to L04542

L04615:  b exchange c[x]
         a + 1 -> a[xs]
         a - 1 -> a[x]
         p <- 1
         0 -> c[x]
         load constant 3
L04623:  a - c -> a[x]
         if n/c go to L04623
         a + c -> a[x]
         shift right c[x]
L04627:  a - c -> a[x]
         if n/c go to L04627
         a + c -> a[x]
         b -> c[x]
         p <- 12
         go to L04636

L04635:  a - 1 -> a[p]
L04636:  a - 1 -> a[x]
         if n/c go to L04641
         go to L04513

L04641:  a + 1 -> a[s]
         decimal
         c - 1 -> c[x]
         p - 1 -> p
         binary
         a + 1 -> a[p]
         if n/c go to L04635
         go to L04636

L04651:  c -> a[x]
         p <- 2
         load constant 8
         load constant 0
         load constant 7
         p <- 1
L04657:  binary
         c + 1 -> c[xs]
         if n/c go to L04664
         0 -> a[wp]
         go to L04672

L04664:  decimal
         a - c -> a[wp]
         if n/c go to L04657
         a + c -> a[wp]
         if a[wp] # 0
           then go to L04674
L04672:  binary
         c - 1 -> c[xs]
L04674:  shift right c[x]
         shift right c[x]
         c -> data address
         data -> c
         a exchange c[w]
         decimal
         return

S04703:  0 -> c[w]
         c -> data address
         binary
         c - 1 -> c[w]
         0 -> a[xs]
L04710:  if p = 0
           then go to L04715
         a + 1 -> a[xs]
         p - 1 -> p
         go to L04710

L04715:  shift left a[w]
         shift left a[w]
         p <- 4
         a exchange c[p]
         p <- 11
         load constant 14
         load constant 10
         load constant 10
         load constant 12
         load constant 10
         a exchange c[w]
         0 -> b[w]
         0 -> s 1
         0 -> s 2
S04733:  display off
         display toggle
L04735:  0 -> s 15
         if s 15 = 1
           then go to L04735
L04740:  0 -> s 3
         if s 3 = 1
           then go to L04745
         if 0 = s 15
           then go to L04740
L04745:  if s 15 = 1
           then go to L04752
         0 -> s 3
         if s 3 = 1
           then go to L04740
L04752:  display toggle
         return

L04754:  p <- 3
         delayed rom @06
         go to L03347

L04757:  jsb S04733
         delayed rom @06
         go to L03002

S04762:  p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         return

         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
L05000:  if 0 = s 12
           then go to L05007
         jsb S05136
         if s 4 = 1
           then go to L05074
         a exchange c[m]
         go to L05011

L05007:  jsb S05124
         c - 1 -> c[m]
L05011:  shift left a[x]
         shift left a[x]
         p <- 3
         shift left a[wp]
L05015:  c + 1 -> c[p]
         if n/c go to L05026
         shift left a[m]
         p + 1 -> p
         if p # 12
           then go to L05015
         c + 1 -> c[p]
         if n/c go to L05026
         go to L05041

L05026:  c - 1 -> c[p]
         if p # 3
           then go to L05034
         1 -> s 7
         0 -> c[x]
         go to L05042

L05034:  if s 7 = 1
           then go to L05037
         a + 1 -> a[s]
L05037:  p - 1 -> p
         shift right a[m]
L05041:  a + c -> c[wp]
L05042:  c -> a[m]
         c -> a[x]
         p - 1 -> p
         a - 1 -> a[wp]
         if c[m] = 0
           then go to L05051
         jsb S05155
L05051:  m1 exchange c
         jsb S05061
         if 0 = s 4
           then go to L05057
         delayed rom @11
         jsb S04762
L05057:  delayed rom @06
         go to L03033

S05061:  register -> c 8
         p <- 11
         0 -> c[p]
         if 0 = s 7
           then go to L05072
         c + 1 -> c[p]
         if 0 = s 4
           then go to L05072
         c + 1 -> c[p]
L05072:  c -> register 8
         return

L05074:  a exchange c[x]
         p <- 5
         shift right a[wp]
         shift right a[wp]
         p <- 0
         a exchange c[p]
         shift left a[x]
         p <- 4
         shift right a[wp]
L05105:  a exchange c[x]
         c -> a[x]
         decimal
         if c[xs] = 0
           then go to L05114
         0 -> c[xs]
         0 - c -> c[x]
L05114:  jsb S05155
         delayed rom @00
         jsb S00006
         if p # 13
           then go to L05051
         0 -> s 2
L05122:  delayed rom @06
         go to L03000

S05124:  if s 9 = 1
           then go to S05130
         m1 -> c
         c -> stack
S05130:  0 -> s 9
         1 -> s 12
         0 -> c[w]
         c -> a[ms]
         binary
         return

S05136:  m1 -> c
         b exchange c[w]
         register -> c 8
         p <- 11
         if c[p] = 0
           then go to L05151
         c - 1 -> c[p]
         1 -> s 7
         if c[p] = 0
           then go to L05151
         1 -> s 4
L05151:  b -> c[w]
         binary
         0 -> c[x]
         return

S05155:  decimal
         a -> b[w]
         0 -> a[x]
         rotate left a
         a exchange b[ms]
         a exchange c[m]
         a + c -> c[x]
         p <- 12
L05165:  if c[p] # 0
           then go to L05175
         c - 1 -> c[x]
         p - 1 -> p
         if s 4 = 1
           then go to L05165
         shift left a[m]
         go to L05165

L05175:  a exchange c[m]
         a exchange b[x]
         return

L05200:  if s 12 = 1
           then go to L05213
         jsb S05124
L05203:  p <- 12
         load constant 1
         c -> a[w]
         a - 1 -> a[wp]
L05207:  0 -> a[x]
         1 -> s 4
         1 -> s 7
         go to L05051

L05213:  jsb S05136
         if s 4 = 1
           then go to L05234
         if c[m] = 0
           then go to L05245
         a exchange c[m]
         c -> a[m]
         p <- 5
         0 -> c[wp]
         if c[m] = 0
           then go to L05234
         p <- 13
         load constant 7
         if a >= c[s]
           then go to L05234
         b -> c[w]
         go to L05207

L05234:  jsb S05237
L05235:  m1 exchange c
         go to L05057

S05237:  b -> c[w]
S05240:  0 -> a[x]
         if s 4 = 1
           then go to L05244
         a - 1 -> a[x]
L05244:  return

L05245:  jsb S05130
         go to L05203

L05247:  if s 12 = 1
           then go to L05253
         1 -> s 7
         go to L05007

L05253:  jsb S05136
         1 -> s 7
         jsb S05237
         jsb S05061
         go to L05057

L05260:  if 0 = s 12
           then go to L05305
         jsb S05136
         decimal
         if s 4 = 1
           then go to L05275
         if c[m] = 0
           then go to L05051
         0 - c - 1 -> c[s]
         binary
         jsb S05240
         b -> c[x]
         go to L05235

L05275:  p <- 5
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         a exchange c[xs]
         0 - c - 1 -> c[xs]
         c -> a[xs]
         go to L05105

L05305:  m1 -> c
         if c[m] = 0
           then go to L05057
         decimal
         0 - c - 1 -> c[s]
         nop
         go to L05122

L05314:  clear regs
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
         delayed rom @15
         go to L06657

L05336:  register -> c 2
         0 -> s 13
L05340:  c -> a[w]
         delayed rom @13
         jsb S05762
         delayed rom @00
         jsb S00137
         delayed rom @13
         jsb S05771
         register -> c 2
         delayed rom @00
         jsb S00137
         if c[s] # 0
           then go to L04754
         delayed rom @00
         jsb S00321
         if s 13 = 1
           then go to L05122
         1 -> s 13
         delayed rom @00
         jsb S00006
         jsb S05367
         delayed rom @13
         jsb S05754
         go to L05340

S05367:  c -> a[w]
         if s 9 = 1
           then go to L05374
         m1 -> c
         c -> stack
L05374:  a exchange c[w]
         c -> stack
         return

         nop
L05400:  register -> c 2
         if c[m] = 0
           then go to L04754
         a exchange c[w]
         register -> c 5
L05405:  a exchange c[w]
         register -> c 2
         jsb S05433
         if s 13 = 1
           then go to L05122
         1 -> s 13
         jsb S05435
         jsb S05742
         register -> c 3
         go to L05405

S05417:  delayed rom @00
         go to L00224

S05421:  delayed rom @00
         go to L00227

S05423:  delayed rom @00
         go to S00230

S05425:  delayed rom @00
         go to S00054

S05427:  delayed rom @00
         go to L00003

S05431:  delayed rom @00
         go to S00321

S05433:  delayed rom @00
         go to S00137

S05435:  delayed rom @00
         go to S00006

S05437:  delayed rom @00
         jsb S00006
         c -> a[w]
         jsb S05765
         a exchange c[w]
         c -> data
         return

L05446:  1 -> s 13
L05447:  m2 exchange c
         register -> c 3
         a exchange c[w]
         m2 -> c
         delayed rom @00
         jsb S00225
         jsb S05427
         m2 -> c
         c -> a[w]
         jsb S05425
         register -> c 4
         jsb S05417
         jsb S05427
         register -> c 5
         y -> a
         jsb S05417
         jsb S05427
         y -> a
         a exchange c[w]
         c -> a[w]
         jsb S05425
         register -> c 6
         jsb S05417
         jsb S05427
         y -> a
         m2 -> c
         jsb S05425
         register -> c 7
         jsb S05417
         jsb S05427
         jsb S05744
         jsb S05417
         jsb S05427
         delayed rom @06
         go to L03343

L05512:  1 -> s 4
         go to L05520

L05514:  1 -> s 7
         go to L05517

L05516:  1 -> s 4
L05517:  1 -> s 6
L05520:  jsb S05744
         1 -> s 13
         jsb S05417
         if c[s] # 0
           then go to L04754
         if c[m] = 0
           then go to L04754
         register -> c 4
L05530:  a exchange c[w]
         register -> c 2
         jsb S05425
         jsb S05437
         if s 8 = 1
           then go to L05562
         jsb S05771
         register -> c 3
L05540:  c -> a[w]
L05541:  jsb S05425
         jsb S05762
         jsb S05417
         jsb S05435
         if s 8 = 1
           then go to L05574
         if c[m] # 0
           then go to L05555
         if 0 = s 4
           then go to L04754
         if s 6 = 1
           then go to L04754
L05555:  c -> register 1
         1 -> s 8
         jsb S05771
         register -> c 6
         go to L05530

L05562:  if s 10 = 1
           then go to L05567
         jsb S05771
         register -> c 5
         go to L05540

L05567:  jsb S05771
         register -> c 3
         c -> a[w]
         register -> c 5
         go to L05541

L05574:  if s 10 = 1
           then go to L05603
         c -> register 2
         1 -> s 10
         jsb S05771
         register -> c 7
         go to L05530

L05603:  c -> register 3
         jsb S05771
         jsb S05744
         jsb S05417
         jsb S05437
         if s 4 = 1
           then go to L05703
         if 0 = s 6
           then go to L05626
         if s 7 = 1
           then go to L05650
         register -> c 3
         a exchange c[w]
         register -> c 1
         jsb S05433
         jsb S05435
         jsb S05742
         0 -> a[w]
         go to L05653

L05626:  register -> c 1
         c -> a[w]
         register -> c 2
         if c[m] = 0
           then go to L04754
         jsb S05425
         jsb S05435
         jsb S05431
         jsb S05435
         b exchange c[w]
         m1 -> c
         delayed rom @14
         jsb S06324
         a exchange b[w]
         register -> c 3
         a exchange c[w]
         jsb S05433
         go to L05677

L05650:  jsb S05740
         m1 -> c
         c -> a[w]
L05653:  jsb S05771
         register -> c 2
         jsb S05425
         register -> c 3
         jsb S05421
         jsb S05751
         jsb S05425
         jsb S05437
         jsb S05771
         register -> c 5
         c -> a[w]
         jsb S05754
         jsb S05425
         jsb S05762
         jsb S05423
         register -> c 1
         jsb S05433
L05674:  jsb S05771
         register -> c 2
         jsb S05433
L05677:  jsb S05771
         a exchange c[w]
         delayed rom @06
         go to L03000

L05703:  if 0 = s 6
           then go to L05336
         register -> c 3
         if c[w] = 0
           then go to L04754
         jsb S05735
         jsb S05771
         register -> c 2
         c -> a[w]
         m2 -> c
         jsb S05425
         register -> c 5
         jsb S05421
         jsb S05754
         jsb S05425
         jsb S05437
         jsb S05771
         m1 -> c
         c -> a[w]
         register -> c 3
         jsb S05425
         jsb S05762
         jsb S05423
         m1 -> c
         jsb S05433
         go to L05674

S05735:  m1 exchange c
L05736:  m2 exchange c
         return

S05740:  m1 -> c
         go to L05736

S05742:  delayed rom @12
         go to S05367

S05744:  0 -> a[w]
         p <- 12
         a + 1 -> a[p]
         register -> c 2
         return

S05751:  jsb S05765
         register -> c 3
         return

S05754:  jsb S05765
         register -> c 1
         return

         jsb S05765
         register -> c 2
         return

S05762:  jsb S05765
         data -> c
         return

S05765:  0 -> c[x]
         p <- 1
         load constant 1
         go to L05772

S05771:  0 -> c[x]
L05772:  c -> data address
         return

         nop
         nop
         nop
         jsb S06055
         go to L06110

         go to L06116

         go to L06116

         nop
         nop
         p <- 0
         if a >= c[p]
           then go to L06421
         0 -> a[s]
         go to L06334

         go to L06122

         go to L06124

         go to L06126

         go to L06134

         go to L06136

         go to L06141

         go to L06147

         go to L06170

         go to L06167

         go to L06165

         go to L06213

         go to L06161

         go to L06156

         go to L06207

         go to L06206

         go to L06210

         go to L06330

         go to L06304

         go to L06262

         go to L06265

         go to L06251

         go to L06244

         go to L06144

         go to L06173

         go to L06175

         go to L06152

         go to L06216

         go to L06163

         go to L06157

         go to L06201

         go to L06200

         go to L06202

         go to L06313

         go to L06154

         go to L06273

S06055:  go to L06274

         go to L06253

         go to L06246

L06060:  0 -> c[xs]
         c -> a[x]
         binary
         p <- 1
         load constant 10
         load constant 10
         p <- 1
         if a >= c[p]
           then go to L06106
         p <- 0
         if a >= c[p]
           then go to L06425
         p <- 1
         load constant 5
         p <- 1
         if a >= c[p]
           then go to L06352
         if a[wp] # 0
           then go to L06104
         0 -> s 2
L06104:  delayed rom @06
         go to L03331

L06106:  a - c -> a[p]
         a -> rom address

L06110:  p <- 0
         if a >= c[p]
           then go to L06116
         m1 -> c
         delayed rom @12
         go to L05000

L06116:  shift left a[x]
         decimal
         m1 -> c
         a -> rom address

L06122:  delayed rom @12
         go to L05247

L06124:  delayed rom @06
         go to L03116

L06126:  jsb S06221
         0 - c - 1 -> c[s]
L06130:  delayed rom @00
         jsb S00222
L06132:  delayed rom @06
         go to L03000

L06134:  jsb S06221
         go to L06130

L06136:  delayed rom @00
         jsb S00052
         go to L06132

L06141:  delayed rom @00
         jsb S00142
         go to L06132

L06144:  delayed rom @00
         jsb S00135
         go to L06132

L06147:  delayed rom @00
         jsb S00316
         go to L06132

L06152:  delayed rom @00
         go to L00035

L06154:  delayed rom @00
         go to L00044

L06156:  1 -> s 8
L06157:  delayed rom @05
         go to L02545

L06161:  delayed rom @05
         go to L02531

L06163:  delayed rom @05
         go to L02534

L06165:  jsb S06223
         1 -> s 10
L06167:  1 -> s 6
L06170:  1 -> s 8
         delayed rom @02
         go to L01000

L06173:  delayed rom @01
         go to L00447

L06175:  1 -> s 8
         delayed rom @01
         go to L00523

L06200:  1 -> s 10
L06201:  1 -> s 6
L06202:  1 -> s 13
         jsb S06227
         delayed rom @03
         go to L01420

L06206:  1 -> s 10
L06207:  1 -> s 6
L06210:  jsb S06227
         delayed rom @04
         go to L02005

L06213:  jsb S06227
         delayed rom @04
         go to L02000

L06216:  jsb S06227
         delayed rom @02
         go to L01371

S06221:  delayed rom @00
         go to S00132

S06223:  stack -> a
         c -> stack
         a exchange c[w]
         return

S06227:  b exchange c[w]
         register -> c 8
         0 -> s 12
         if c[s] = 0
           then go to L06242
         c - 1 -> c[s]
         if c[s] = 0
           then go to L06241
         1 -> s 14
         go to L06242

L06241:  1 -> s 12
L06242:  b exchange c[w]
         return

L06244:  y -> a
         a - c -> c[w]
L06246:  if c[w] = 0
           then go to L06260
         go to L06255

L06251:  y -> a
         a - c -> c[w]
L06253:  if c[w] # 0
           then go to L06260
L06255:  delayed rom @06
         jsb S03076
         0 -> s 11
L06260:  delayed rom @06
         go to L03032

L06262:  y -> a
         1 -> s 13
         go to L06267

L06265:  y -> a
         a exchange c[w]
L06267:  0 - c - 1 -> c[s]
         delayed rom @00
         jsb S00230
         go to L06274

L06273:  0 - c - 1 -> c[s]
L06274:  if c[m] # 0
           then go to L06301
         if s 13 = 1
           then go to L06260
         go to L06255

L06301:  if c[s] = 0
           then go to L06260
         go to L06255

L06304:  0 -> s 12
         delayed rom @10
         jsb S04372
         display off
         display toggle
         delayed rom @05
         go to L02677

L06313:  jsb S06324
         delayed rom @03
         jsb S01756
         c + c -> c[w]
         c + c -> c[w]
         shift right c[w]
         c + 1 -> c[m]
         0 -> c[x]
         go to L06132

S06324:  if s 9 = 1
           then go to L06327
         c -> stack
L06327:  return

L06330:  jsb S06324
         m2 -> c
         go to L06132

L06333:  a + 1 -> a[s]
L06334:  a - 1 -> a[p]
         if n/c go to L06333
         p <- 1
         a + c -> a[p]
         if n/c go to L06342
L06341:  a + 1 -> a[xs]
L06342:  a + 1 -> a[p]
         if n/c go to L06341
         register -> c 8
         a exchange c[xs]
         c -> register 8
         rotate left a
         f exchange a[x]
         go to L06260

L06352:  a - c -> a[p]
         register -> c 8
         c -> a[xs]
         if a[wp] # 0
           then go to L06373
L06357:  p <- 10
         if s 1 = 1
           then go to L06367
         if s 2 = 1
           then go to L06370
         0 -> c[wp]
         delayed rom @06
         go to L03337

L06367:  0 -> s 2
L06370:  p <- 6
         delayed rom @05
         go to L02747

L06373:  p <- 10
         if s 1 = 1
           then go to L06403
         if s 2 = 1
           then go to L06403
         0 -> c[wp]
         delayed rom @06
         go to L03370

L06403:  delayed rom @06
         jsb S03076
         jsb S06410
         delayed rom @06
         go to L03340

S06410:  1 -> s 2
         a exchange c[m]
         a exchange c[xs]
         shift left a[x]
         p <- 10
         shift left a[wp]
         shift left a[wp]
         a exchange c[m]
         return

L06421:  shift left a[x]
         m1 -> c
         decimal
         a -> rom address

L06425:  p <- 1
         load constant 8
         p <- 1
         if a >= c[p]
           then go to L06421
         load constant 14
         p <- 1
         a exchange c[p]
         shift right c[x]
         c -> data address
         data -> c
         b exchange c[w]
         go to L06421

L06442:  0 -> a[s]
         go to L06450

L06444:  0 -> a[s]
         go to L06451

L06446:  0 -> a[s]
         a + 1 -> a[s]
L06450:  a + 1 -> a[s]
L06451:  register -> c 8
         a exchange c[s]
         c -> register 8
         go to L06655

L06455:  jsb S06546
         0 -> a[x]
         delayed rom @00
         jsb S00274
         c - 1 -> c[x]
         a exchange c[m]
         go to L06764

L06464:  a exchange b[w]
         delayed rom @00
         jsb S00137
         go to L06576

L06470:  delayed rom @13
         go to L05512

         go to L06446

         go to L06611

         go to L06505

         go to L06501

         go to L06503

         0 -> c[w]
         go to L06510

L06501:  delayed rom @12
         go to L05260

L06503:  delayed rom @12
         go to L05200

L06505:  delayed rom @13
         go to L05447

L06507:  c -> stack
L06510:  delayed rom @06
         go to L03343

         go to L06442

         go to L06613

         go to L06523

         go to L06507

         go to L06644

         clear regs
         m1 exchange c
         m1 -> c
         go to L06764

L06523:  delayed rom @13
         go to L05446

L06525:  delayed rom @14
         jsb S06223
         go to L06764

L06530:  down rotate
         go to L06764

         go to L06444

         go to L06655

         go to L06470

         go to L06542

         go to L06455

         jsb S06774
         0 -> c[s]
         go to L06764

L06542:  jsb S06546
         0 -> c[wp]
         a exchange c[x]
         go to L06764

S06546:  jsb S06774
         c -> a[w]
         p <- 12
         if c[xs] = 0
           then go to L06555
         c + 1 -> c[x]
         return

L06555:  c + 1 -> c[x]
L06556:  if c[x] = 0
           then go to L06565
         c - 1 -> c[x]
         shift left a[m]
         p - 1 -> p
         if a[m] # 0
           then go to L06556
L06565:  return

L06566:  delayed rom @13
         go to L05516

L06570:  delayed rom @13
         go to L05514

L06572:  0 - c - 1 -> c[s]
L06573:  a exchange b[w]
         delayed rom @00
         jsb S00230
L06576:  delayed rom @00
         jsb S00006
         if s 11 = 1
           then go to L06621
L06602:  c -> data
         m1 -> c
         go to L06764

L06605:  a exchange b[w]
         delayed rom @00
         jsb S00054
         go to L06576

L06611:  delayed rom @13
         go to L05517

L06613:  delayed rom @13
         go to L05400

         go to L06525

         go to L06530

         delayed rom @13
         go to L05520

L06621:  p <- 1
         delayed rom @06
         go to L03347

S06624:  rom checksum

S06625:  if s 5 = 1
           then go to L06746
S06627:  0 -> c[x]
         p <- 12
         c + 1 -> c[p]
         m1 exchange c
         m1 -> c
         return

         go to L06566

         go to L06570

         register -> c 5
         delayed rom @12
         jsb S05367
         register -> c 3
         go to L06764

L06644:  0 -> c[w]
         c -> register 0
         c -> register 1
         c -> register 2
         c -> register 3
         c -> register 4
         c -> register 5
         c -> register 6
         c -> register 7
L06655:  delayed rom @06
         go to L03032

L06657:  if a[w] # 0
           then go to L06744
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         m1 exchange c
         m1 -> c
         p <- 0
         load constant 15
         jsb S06766
         jsb S06732
         jsb S06627
         p <- 1
         load constant 1
         load constant 3
         jsb S06766
         load constant 3
         jsb S06732
         jsb S06627
         0 -> s 5
         delayed rom @00
         jsb S00002
         jsb S06625
         delayed rom @05
         jsb S02643
         jsb S06625
         delayed rom @10
         jsb S04365
         jsb S06625
         jsb S06624
         jsb S06625
         0 -> c[w]
         p <- 12
L06720:  load constant 2
         if p # 2
           then go to L06720
         b exchange c[w]
         b -> c[w]
         c + c -> c[m]
         c + c -> c[m]
         a exchange c[w]
         delayed rom @11
         go to L04757

S06732:  p <- 0
L06733:  c -> a[w]
         c -> data address
         data -> c
         a - c -> a[w]
         if a[w] # 0
           then go to L06746
         c - 1 -> c[p]
         if n/c go to L06733
         return

L06744:  0 -> c[w]
         m1 exchange c
L06746:  p <- 9
         delayed rom @06
         go to L03347

         nop
         go to L06760

         go to L06602

         go to L06572

         go to L06573

         go to L06605

         go to L06464

L06760:  if s 9 = 1
           then go to L06763
         c -> stack
L06763:  b exchange c[w]
L06764:  delayed rom @06
         go to L03000

S06766:  p <- 0
L06767:  c -> data address
         c -> data
         c - 1 -> c[p]
         if n/c go to L06767
         return

S06774:  m2 exchange c
         m2 -> c
         return

         .dw @0053

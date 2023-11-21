; 1820-2122, 1MA4-0002 CPU ROM disassembly - quad 0 (@0000-@1777)
; used in 37E, 38E
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

	 .arch woodstock

; externals:
L04000   .equ @04000
L05176   .equ @05176
L05350   .equ @05350

	 .org @0000

         display off
         a + 1 -> a[x]
         a + 1 -> a[x]
         f exchange a[x]
         p <- 1
         jsb S00044
         c + 1 -> c[p]
         c -> data address
         clear data registers
L00011:  0 -> c[w]
         c -> data address
         p <- 2
         load constant 13
         clear data registers
         c -> register 8
         clear regs
L00020:  clear status
L00021:  0 -> s 1
L00022:  jsb S00311
         m2 exchange c
         0 -> c[w]
         c -> data address
         m2 -> c
         if s 2 = 0
           then go to L00263
L00031:  delayed rom @12
         go to L05350

L00033:  if s 0 = 0
           then go to L00020
L00035:  clear status
         1 -> s 0
         go to L00021

         nop
         nop
         nop

S00043:  rom checksum

S00044:  c + 1 -> c[p]
         c -> data address
         clear data registers
         return

S00050:  0 -> a[w]
         f -> a[x]
         c -> a[m]
         m1 exchange c
         m1 -> c
         p <- 12
         0 -> c[s]
L00057:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L00057
         if p = 1
           then go to L00077
         if c[xs] # 0
           then go to L00115
L00066:  c - 1 -> c[x]
         if n/c go to L00072
         0 -> a[x]
         go to L00121

L00072:  if p = 2
           then go to L00075
         p - 1 -> p
L00075:  c + 1 -> c[s]
         if n/c go to L00066
L00077:  m1 -> c
         0 -> c[s]
         p <- 1
         if c[xs] = 0
           then go to L00105
         0 - c -> c[wp]
L00105:  p <- 5
         c -> a[w]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         1 -> s 9
         p <- 2
         go to L00134

L00115:  0 -> a[x]
L00116:  shift right a[w]
         c + 1 -> c[x]
         if n/c go to L00116
L00121:  0 -> b[w]
         a -> b[wp]
         a exchange b[w]
         a + b -> a[w]
         if a[ms] # 0
           then go to L00137
         if c[m] # 0
           then go to L00077
L00131:  if a[s] # 0
           then go to L01771
L00133:  c -> a[s]
L00134:  binary
         a - 1 -> a[wp]
         return

L00137:  0 -> a[wp]
         if a[w] # 0
           then go to L00131
         p - 1 -> p
         a exchange b[w]
         go to L00121

L00145:  1 -> s 6
         if s 7 = 1
           then go to L00264
L00150:  shift left a[x]
         shift left a[x]
L00152:  m2 -> c
         jsb S00363
         p <- 3
L00155:  a + 1 -> a[p]
         if n/c go to L00162
         shift left a[wp]
         p + 1 -> p
         go to L00155

L00162:  a - 1 -> a[p]
         if p = 3
           then go to L00264
         if p = 13
           then go to L00172
         if s 6 = 1
           then go to L00172
         a + 1 -> a[s]
L00172:  a -> b[w]
         p - 1 -> p
         p - 1 -> p
         a - 1 -> a[wp]
         a exchange b[w]
         rotate left a
         p <- 12
         shift right a[ms]
         c -> a[s]
         decimal
         if a[ms] # 0
           then go to L00256
         0 -> a[w]
L00207:  a exchange c[w]
         a exchange b[w]
         go to L00253

S00212:  m2 -> c
         b exchange c[w]
         0 -> c[w]
         if s 9 = 0
           then go to L00221
         p <- 5
         load constant 6
L00221:  a exchange c[s]
         c -> a[s]
         p <- 12
         if b[s] = 0
           then go to L00231
         load constant 4
         p <- 13
L00230:  p - 1 -> p
L00231:  c - 1 -> c[s]
         if n/c go to L00230
L00233:  c + 1 -> c[p]
         if p = 12
           then go to L01015
         p + 1 -> p
         if p = 12
           then go to L01015
         p + 1 -> p
         if p = 12
           then go to L01015
         p + 1 -> p
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L00233
L00250:  if c[m] = 0
           then go to L00264
         0 - c - 1 -> c[s]
L00253:  0 -> s 0
         m2 exchange c
         go to L00264

L00256:  if a[p] # 0
           then go to L00207
         a - 1 -> a[x]
         shift left a[m]
         go to L00256

L00263:  jsb S00050
L00264:  if s 2 = 1
           then go to L00031
         jsb S00212
L00267:  0 -> a[x]
L00270:  0 -> s 12
L00271:  decimal
         display off
         display toggle
L00274:  0 -> s 15
         if s 15 = 1
           then go to L00274
L00277:  if s 15 = 0
           then go to L00277
         display off
         if p # 3
           then go to L00400
L00304:  m2 -> c
         if s 4 = 0
           then go to L00033
         delayed rom @12
         go to L05176

S00311:  p <- 12
         if c[m] = 0
           then go to L00376
         decimal
         if c[xs] = 0
           then go to L00324
         c - 1 -> c[x]
         c + 1 -> c[xs]
         c - 1 -> c[xs]
         if n/c go to L00325
         c + 1 -> c[x]
L00324:  return

L00325:  c + c -> c[xs]
         if n/c go to L00331
         p <- 13
         go to L00376

L00331:  0 -> c[wp]
         c - 1 -> c[wp]
         0 -> c[xs]
         0 -> s 2
         p <- 13
         return

L00337:  p <- 7
L00340:  0 -> c[w]
         0 -> s 2
         binary
         c - 1 -> c[w]
         0 -> b[w]
L00345:  p + 1 -> p
         c + 1 -> c[xs]
         if p # 8
           then go to L00345
         load constant 14
         load constant 10
         load constant 10
         load constant 12
         load constant 10
L00356:  a exchange c[w]
         shift left a[w]
         shift left a[w]
         shift left a[w]
         go to L00267

S00363:  binary
         if s 7 = 1
           then go to L00377
         if s 0 = 1
           then go to L00371
         c -> stack
L00371:  0 -> s 9
         1 -> s 7
         0 -> a[ms]
         a - 1 -> a[m]
         0 -> s 1
L00376:  0 -> c[w]
L00377:  return

L00400:  delayed rom @10
         go to L04000

L00402:  load constant 6
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

S00420:  0 -> b[w]
         a exchange b[m]
S00422:  m1 exchange c
         m1 -> c
         0 -> c[x]
S00425:  0 -> b[s]
         0 -> c[s]
         p <- 12
         m1 exchange c
         p <- 1
L00432:  p - 1 -> p
         a + 1 -> a[xs]
         c + 1 -> c[xs]
         if p # 12
           then go to L00432
         b exchange c[w]
         if c[w] = 0
           then go to L00502
         m1 exchange c
         a exchange b[w]
         if c[w] = 0
           then go to L00502
L00446:  if a >= b[x]
           then go to L00606
L00450:  a - b -> a[s]
         if a[s] # 0
           then go to L00454
         go to L00470

L00454:  0 - c -> c[w]
         c -> a[s]
         if a >= b[x]
           then go to L00470
         m1 exchange c
         a exchange c[w]
         shift left a[w]
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         a - 1 -> a[x]
         a exchange b[w]
L00470:  if a >= b[x]
           then go to L00502
         a + 1 -> a[x]
         shift right c[w]
         a exchange c[s]
         c -> a[s]
         p - 1 -> p
         if p # 13
           then go to L00470
         0 -> a[w]
L00502:  a exchange c[w]
         m1 -> c
         b exchange c[w]
         a + b -> a[w]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
L00511:  a exchange c[w]
         m1 exchange c
         m1 -> c
         if c[s] = 0
           then go to L00520
         a + 1 -> a[x]
         shift right c[w]
L00520:  a exchange c[w]
S00521:  p <- 12
         if a[wp] # 0
           then go to L00550
L00524:  b exchange c[w]
L00525:  a exchange c[w]
         p <- 12
         c -> a[w]
         c + c -> c[x]
         if n/c go to L00546
         c + 1 -> c[m]
         if n/c go to L00546
         b -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[p]
L00537:  b -> c[s]
         a exchange b[w]
         if c[m] # 0
           then go to L00545
         0 -> c[w]
         0 -> a[s]
L00545:  return

L00546:  b -> c[x]
         go to L00537

L00550:  if a[p] # 0
           then go to L00524
         c - 1 -> c[x]
         shift left a[wp]
         go to L00550

S00555:  0 -> b[w]
         a exchange b[m]
S00557:  m1 exchange c
         m1 -> c
         0 -> c[x]
S00562:  0 -> b[s]
         0 -> c[s]
         m1 exchange c
         a + c -> c[x]
         a - c -> c[s]
         if n/c go to L00571
         0 - c -> c[s]
L00571:  0 -> a[w]
         m1 exchange c
         p <- 13
L00574:  p + 1 -> p
         shift right a[w]
         go to L00600

L00577:  a + b -> a[w]
L00600:  c - 1 -> c[p]
         if n/c go to L00577
         if p # 12
           then go to L00574
         m1 -> c
         go to L00511

L00606:  m1 exchange c
         a exchange b[w]
         if a >= b[x]
           then go to L00613
         go to L00446

L00613:  a exchange c[w]
         m1 exchange c
         if a >= c[w]
           then go to L00622
         m1 exchange c
         a exchange c[w]
         go to L00450

L00622:  m1 exchange c
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         go to L00450

S00627:  0 -> b[w]
         a exchange b[m]
S00631:  m1 exchange c
         m1 -> c
         0 -> c[x]
S00634:  0 -> b[s]
         0 -> c[s]
         if c[m] = 0
           then go to L00337
         m1 exchange c
         a - c -> c[x]
         a - c -> c[s]
         if n/c go to L00645
         0 - c -> c[s]
L00645:  m1 exchange c
         a exchange c[w]
         a exchange b[w]
L00650:  if a >= b[w]
           then go to L00656
         m1 exchange c
         shift left a[w]
         c - 1 -> c[x]
         m1 exchange c
L00656:  p <- 12
         0 -> c[w]
         go to L00662

L00661:  c + 1 -> c[p]
L00662:  a - b -> a[w]
         if n/c go to L00661
         a + b -> a[w]
         shift left a[w]
         p - 1 -> p
         if p # 13
           then go to L00662
         a exchange c[w]
         m1 -> c
         go to L00524

S00674:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S00677:  0 -> c[w]
         m1 exchange c
         0 -> c[w]
         p <- 12
         load constant 1
S00704:  b exchange c[w]
         a exchange c[w]
         m1 exchange c
         a exchange c[w]
         go to S00634

S00711:  0 -> c[w]
         0 - c - 1 -> c[s]
L00713:  p <- 12
         load constant 1
         go to S00422

S00716:  0 -> c[w]
         go to L00713

S00720:  0 -> a[w]
         p <- 12
         f -> a[x]
L00723:  if p = 2
           then go to L00762
         p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L00723
         c -> a[w]
         a + c -> a[x]
         if n/c go to L00763
         c -> a[x]
L00734:  p + 1 -> p
         if p = 13
           then go to L00376
         a + 1 -> a[x]
         if n/c go to L00734
         go to L00747

L00742:  p - 1 -> p
L00743:  if p = 2
           then go to L00762
         a - 1 -> a[x]
         if n/c go to L00742
L00747:  0 -> b[w]
         a -> b[wp]
         a + b -> a[m]
         if n/c go to L00760
         0 -> a[s]
         a + 1 -> a[s]
         c + 1 -> c[x]
         shift right a[w]
         p - 1 -> p
L00760:  0 -> a[wp]
         a exchange c[m]
L00762:  return

L00763:  c -> a[x]
         go to L00743

S00765:  b exchange c[w]
         m1 exchange c
         register -> c 8
         c -> a[m]
         a -> b[m]
         shift right b[m]
         shift right b[m]
         shift right b[m]
         p <- 8
         b exchange c[wp]
         b exchange c[x]
         c -> register 8
         register -> c 5
         b exchange c[w]
         register -> c 6
         c -> register 5
         register -> c 7
         c -> register 6
         a exchange c[m]
         shift right c[w]
         shift right c[w]
         shift right c[w]
         b exchange c[s]
         m1 exchange c
L01015:  b exchange c[w]
         return

S01017:  register -> c 5
         a exchange c[s]
         p <- 12
         b exchange c[wp]
         c -> register 5
         register -> c 8
         p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[wp]
         a exchange c[x]
         c -> register 8
         go to L01056

S01035:  register -> c 6
         c -> register 7
         register -> c 5
         c -> register 6
         b -> c[w]
         a exchange c[s]
         c -> a[s]
         c -> register 5
         register -> c 8
         a exchange c[m]
         p <- 11
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[m]
         c -> register 8
         a exchange c[wp]
L01056:  shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         return

S01062:  0 -> s 6
L01063:  0 -> s 8
         0 -> b[s]
         a exchange c[w]
         c -> a[w]
         c + c -> c[x]
         if n/c go to L01140
         if a[s] # 0
           then go to L01146
         a exchange c[w]
         jsb S01102
L01075:  p <- 12
         a exchange c[w]
         0 -> c[ms]
         c -> a[w]
         go to L01127

S01102:  a exchange b[w]
         a -> b[w]
         m1 exchange c
         m1 -> c
L01106:  shift right a[w]
         if a[w] # 0
           then go to L01114
         m1 -> c
         a exchange c[w]
         return

L01114:  c + 1 -> c[x]
         if n/c go to L01106
         p <- 12
         a + 1 -> a[p]
         a exchange b[w]
S01121:  delayed rom @01
         go to L00650

L01123:  if p = 6
           then go to L01143
         p - 1 -> p
         c + 1 -> c[s]
L01127:  c + 1 -> c[x]
         if n/c go to L01123
         a exchange b[w]
         go to L01222

S01133:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         1 -> s 6
         go to L01063

L01140:  delayed rom @01
         jsb S00716
         go to L01175

L01143:  a exchange b[w]
         b exchange c[w]
         go to L01344

L01146:  1 -> s 8
         go to L01075

L01150:  p <- 12
         b -> c[w]
         c - 1 -> c[p]
         a exchange c[w]
         if a[w] # 0
           then go to L01157
         go to L01325

L01157:  if a[p] # 0
           then go to L01164
         c - 1 -> c[x]
         shift left a[w]
         go to L01157

L01164:  m1 exchange c
         jsb S01121
         go to L01075

S01167:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S01172:  1 -> s 6
         if b[m] = 0
           then go to L01757
L01175:  0 -> s 8
         0 -> b[s]
         if a[s] # 0
           then go to L00337
         if b[m] = 0
           then go to L00337
         a exchange c[x]
         c -> a[x]
         if c[x] = 0
           then go to L01150
         a + c -> a[x]
         if n/c go to L01213
         0 - c - 1 -> c[x]
         1 -> s 8
L01213:  0 -> a[ms]
         a exchange c[ms]
         0 -> a[w]
         p <- 12
         a - b -> a[wp]
         c - 1 -> c[p]
L01221:  c + 1 -> c[p]
L01222:  a -> b[w]
         m1 exchange c
         m1 -> c
         go to L01227

L01226:  shift right a[w]
L01227:  c - 1 -> c[s]
         if n/c go to L01226
         m1 -> c
         a + b -> a[w]
         a - 1 -> a[s]
         if n/c go to L01221
         c + 1 -> c[s]
         a exchange b[w]
         shift left a[w]
         p - 1 -> p
         if p # 5
           then go to L01222
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
           then go to L01343
         p <- 6
L01257:  shift right a[w]
         b exchange c[w]
L01261:  delayed rom @03
         jsb S01556
         b exchange c[w]
         jsb S01361
         if c[m] = 0
           then go to L01316
         if p # 13
           then go to L01257
         0 -> b[w]
         p <- 0
         a -> b[p]
         a + b -> a[w]
         shift right a[w]
         b exchange c[w]
         delayed rom @03
         jsb S01536
         if s 8 = 1
           then go to L01310
         a exchange b[w]
         a - b -> a[w]
         a exchange b[w]
         a + b -> a[w]
         a exchange b[w]
L01310:  p <- 3
L01311:  jsb S01361
         if c[m] = 0
           then go to L01316
         shift right a[w]
         go to L01311

L01316:  if a[s] # 0
           then go to L01351
         c - 1 -> c[x]
L01321:  0 -> c[ms]
         if s 8 = 0
           then go to L01325
         0 - c - 1 -> c[s]
L01325:  delayed rom @01
         jsb S00521
         if s 6 = 0
           then go to L01366
         delayed rom @01
         jsb S00765
         delayed rom @01
         jsb S00562
         m1 -> c
L01336:  if c[s] = 0
           then go to L01421
         a - 1 -> a[x]
         b exchange c[w]
         go to L01336

L01343:  shift right a[w]
L01344:  delayed rom @03
         jsb S01676
         a exchange b[w]
         p <- 6
         go to L01261

L01351:  shift right a[w]
         go to L01321

S01353:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         0 -> s 6
         go to L01175

L01360:  a + b -> a[w]
S01361:  c - 1 -> c[p]
         if n/c go to L01360
         0 -> c[p]
         c + 1 -> c[x]
         p + 1 -> p
L01366:  return

L01367:  p <- 6
         load constant 3
         load constant 3
         load constant 3
         load constant 0
         load constant 8
         load constant 3
         load constant 5
         p <- 9
         return

L01401:  load constant 3
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

S01416:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
L01421:  1 -> s 8
         if a[s] # 0
           then go to L01425
         0 -> s 8
L01425:  0 -> a[ms]
         a exchange b[w]
         b -> c[w]
         c + c -> c[x]
         if n/c go to L01446
         b -> c[w]
         if a[s] # 0
           then go to L01451
         p <- 13
L01436:  p - 1 -> p
         if p = 5
           then go to L01625
         c + 1 -> c[x]
         if n/c go to L01436
L01443:  jsb S01556
         b exchange c[w]
         go to L01613

L01446:  jsb S01536
         p <- 6
         go to L01456

L01451:  a exchange b[w]
         a + 1 -> a[x]
         shift right b[w]
         go to L01425

L01455:  c + 1 -> c[m]
L01456:  a - b -> a[w]
         if n/c go to L01455
         a + b -> a[w]
         shift left a[w]
         c - 1 -> c[x]
         if n/c go to L01475
         p <- 5
         if c[p] = 0
           then go to L01473
         c - 1 -> c[p]
         if c[p] # 0
           then go to L01502
         c + 1 -> c[p]
L01473:  p <- 12
         go to L01623

L01475:  a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[p] = 0
           then go to L01456
L01502:  0 -> c[w]
         p <- 12
         c - 1 -> c[wp]
         c -> a[w]
         p <- 2
         load constant 1
         if s 8 = 0
           then go to L01513
         0 - c - 1 -> c[x]
L01513:  a exchange b[w]
         c -> a[w]
L01515:  if s 1 = 0
           then go to L01525
         delayed rom @02
         jsb S01035
         delayed rom @01
         jsb S00711
         delayed rom @02
         jsb S01017
L01525:  a exchange b[w]
         delayed rom @01
         go to L00525

L01530:  p <- 2
         load constant 3
         load constant 3
         load constant 3
         p <- 7
         return

S01536:  p <- 12
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
         b exchange c[w]
         return

S01556:  0 -> c[w]
         if p = 12
           then go to L00402
         c - 1 -> c[m]
         load constant 4
         c + 1 -> c[m]
         if p = 10
           then go to L01401
         if p = 9
           then go to L01743
         if p = 8
           then go to L01367
         if p = 7
           then go to L01602
         if p = 6
           then go to L01530
         p <- 0
         load constant 3
         p <- 6
         return

L01602:  p <- 4
         load constant 3
         load constant 3
         load constant 3
         load constant 3
         load constant 1
         p <- 8
         return

L01612:  c + 1 -> c[p]
L01613:  a - b -> a[w]
         if n/c go to L01612
         a + b -> a[w]
         if p = 6
           then go to L01626
         shift left a[w]
         c - 1 -> c[x]
         p - 1 -> p
L01623:  b exchange c[w]
         go to L01443

L01625:  b exchange c[w]
L01626:  if s 1 = 0
           then go to L01633
         jsb S01676
         a exchange c[w]
         a exchange b[w]
L01633:  p <- 13
         load constant 6
         p <- 5
L01636:  if c[m] = 0
           then go to L01724
         p + 1 -> p
L01641:  if c[p] = 0
           then go to L01650
         c - 1 -> c[p]
         a -> b[w]
         m1 exchange c
         m1 -> c
         go to L01670

L01650:  c + 1 -> c[x]
         shift right a[w]
         c - 1 -> c[s]
         if n/c go to L01636
         shift right c[w]
         shift right c[w]
         shift right c[w]
         a + 1 -> a[p]
         a exchange b[w]
         c -> a[w]
         if s 8 = 0
           then go to L01515
         delayed rom @01
         jsb S00677
         go to L01515

L01667:  shift right b[w]
L01670:  c - 1 -> c[s]
         if n/c go to L01667
         a + b -> a[w]
         a + 1 -> a[s]
         m1 -> c
         go to L01641

S01676:  m1 exchange c
         m1 -> c
         a -> b[w]
         b exchange c[w]
         c + c -> c[w]
         c + c -> c[w]
         a + c -> c[w]
         a exchange b[w]
L01706:  shift right c[w]
         if c[w] # 0
           then go to L01714
         m1 -> c
         a exchange c[w]
         return

L01714:  a + 1 -> a[x]
         if n/c go to L01706
         0 - c -> c[w]
         0 -> c[s]
         m1 exchange c
         c + 1 -> c[x]
         delayed rom @01
         go to L00645

L01724:  a exchange b[w]
         0 -> c[ms]
         c -> a[w]
         if s 8 = 0
           then go to L01734
         0 - c - 1 -> c[s]
         delayed rom @02
         jsb S01102
L01734:  if s 1 = 0
           then go to L01740
         delayed rom @02
         jsb S01035
L01740:  delayed rom @01
         jsb S00716
         go to L01525

L01743:  p <- 8
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

L01757:  delayed rom @01
         jsb S00765
         if c[m] = 0
           then go to L00337
         m1 -> c
         if c[s] # 0
           then go to L00337
         0 -> a[w]
         0 -> b[w]
         go to L01515

L01771:  c + 1 -> c[s]
         p - 1 -> p
         shift right a[w]
         delayed rom @00
         go to L00133

         nop

	 .dw @0116		; CRC, bank 0 quad 0 (@00000..@01777)

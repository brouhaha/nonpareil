; 1820-2162, 1MA4-0003 CPU ROM disassembly - quad 0 (@0000-@1777)
; used in 32E, 34C, 38C
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

         .arch woodstock

; externals:
L02000   .equ @02000
L02001   .equ @02001
L02002   .equ @02002
L02004   .equ @02004
L02005   .equ @02005

	 .org @0000

L00000:  select rom go to L02001

L00001:  go to S00014

L00002:  go to S00016

L00003:  go to S00021

L00004:  go to S00171

L00005:  go to S00173

L00006:  go to S00176

L00007:  go to S00222

L00010:  go to S00224

L00011:  go to S00227

L00012:  go to S00362

L00013:  go to S00275

S00014:  0 -> b[w]
         a exchange b[m]
S00016:  m1 exchange c
         m1 -> c
         0 -> c[x]
S00021:  0 -> b[s]
         0 -> c[s]
         m1 exchange c
         p <- 1
L00025:  p - 1 -> p
         a + 1 -> a[xs]
         c + 1 -> c[xs]
         if p # 12
           then go to L00025
         b exchange c[w]
         if c[w] = 0
           then go to L00075
         m1 exchange c
         a exchange b[w]
         if c[w] = 0
           then go to L00075
L00041:  if a >= b[x]
           then go to L00150
L00043:  a - b -> a[s]
         if a[s] # 0
           then go to L00047
         go to L00063

L00047:  0 - c -> c[w]
         c -> a[s]
         if a >= b[x]
           then go to L00063
         m1 exchange c
         a exchange c[w]
         shift left a[w]
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         a - 1 -> a[x]
         a exchange b[w]
L00063:  if a >= b[x]
           then go to L00075
         a + 1 -> a[x]
         shift right c[w]
         a exchange c[s]
         c -> a[s]
         p - 1 -> p
         if p # 13
           then go to L00063
         0 -> c[w]
L00075:  a exchange c[w]
         m1 -> c
         b exchange c[w]
         a + b -> a[w]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
S00104:  a exchange c[w]
         m1 exchange c
         m1 -> c
         if c[s] = 0
           then go to L00113
         a + 1 -> a[x]
         shift right c[w]
L00113:  a exchange c[w]
S00114:  p <- 12
         if a[wp] # 0
           then go to L00143
L00117:  b exchange c[w]
S00120:  a exchange c[w]
         p <- 12
         c -> a[w]
         c + c -> c[x]
         if n/c go to L00141
         c + 1 -> c[m]
         if n/c go to L00141
         b -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[p]
L00132:  b -> c[s]
         a exchange b[w]
         if c[m] # 0
           then go to L00140
         0 -> c[w]
         0 -> a[s]
L00140:  return

L00141:  b -> c[x]
         go to L00132

L00143:  if a[p] # 0
           then go to L00117
         c - 1 -> c[x]
         shift left a[wp]
         go to L00143

L00150:  m1 exchange c
         a exchange b[w]
         if a >= b[x]
           then go to L00155
         go to L00041

L00155:  a exchange c[w]
         m1 exchange c
         if a >= c[w]
           then go to L00164
         m1 exchange c
         a exchange c[w]
         go to L00043

L00164:  m1 exchange c
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         go to L00043

S00171:  0 -> b[w]
         a exchange b[m]
S00173:  m1 exchange c
         m1 -> c
         0 -> c[x]
S00176:  0 -> b[s]
         0 -> c[s]
         m1 exchange c
         a + c -> c[x]
         a - c -> c[s]
         if n/c go to L00205
         0 - c -> c[s]
L00205:  0 -> a[w]
         m1 exchange c
         p <- 13
L00210:  p + 1 -> p
         shift right a[w]
         go to L00214

L00213:  a + b -> a[w]
L00214:  c - 1 -> c[p]
         if n/c go to L00213
         if p # 12
           then go to L00210
         m1 -> c
         go to S00104

S00222:  0 -> b[w]
         a exchange b[m]
S00224:  m1 exchange c
         m1 -> c
         0 -> c[x]
S00227:  0 -> b[s]
         0 -> c[s]
         if c[m] = 0
           then go to L00267
         m1 exchange c
         a - c -> c[x]
         a - c -> c[s]
         if n/c go to L00240
         0 - c -> c[s]
L00240:  m1 exchange c
         a exchange c[w]
         a exchange b[w]
S00243:  if a >= b[w]
           then go to S00251
         m1 exchange c
         shift left a[w]
         c - 1 -> c[x]
         m1 exchange c
S00251:  p <- 12
         0 -> c[w]
         go to L00255

L00254:  c + 1 -> c[p]
L00255:  a - b -> a[w]
         if n/c go to L00254
         a + b -> a[w]
         shift left a[w]
         p - 1 -> p
         if p # 13
           then go to L00255
         a exchange c[w]
         m1 -> c
         go to L00117

L00267:  p <- 0
         delayed rom @04
         go to L02004

S00272:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S00275:  if a[s] # 0
           then go to L00267
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
           then go to L00322
         shift right b[w]
L00322:  shift right c[w]
         a exchange c[x]
         0 -> c[w]
         a exchange b[w]
         p <- 13
         load constant 5
         shift right c[w]
         go to L00342

L00332:  c + 1 -> c[p]
L00333:  a - c -> a[w]
         if n/c go to L00332
         a + c -> a[w]
         shift left a[w]
         if p = 0
           then go to L00345
         p - 1 -> p
L00342:  shift right c[wp]
         0 -> c[p]
         go to L00333

L00345:  a exchange c[w]
         go to S00120

L00347:  0 -> a[w]
         0 -> c[w]
         go to S00120

S00352:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S00355:  0 -> c[w]
         m1 exchange c
         0 -> c[w]
         p <- 12
         load constant 1
S00362:  b exchange c[w]
         a exchange c[w]
         m1 exchange c
         a exchange c[w]
         go to S00227

S00367:  0 -> c[w]
         0 - c - 1 -> c[s]
L00371:  p <- 12
         load constant 1
         go to S00016

S00374:  0 -> c[w]
         go to L00371

L00376:  load constant 6
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

L00414:  go to S00470

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

S00436:  b exchange c[w]
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

S00470:  register -> c 7
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
         go to S00243

L00606:  if p = 6
           then go to L01752
         p - 1 -> p
         c + 1 -> c[s]
L00612:  c + 1 -> c[x]
         if n/c go to L00606
         a exchange b[w]
         go to L00676

L00616:  delayed rom @00
         jsb S00374
         go to L00651

L00621:  1 -> s 8
         go to L00560

L00623:  p <- 12
         b -> c[w]
         c - 1 -> c[p]
         a exchange c[w]
         if a[w] # 0
           then go to L00633
         delayed rom @02
         go to L01006

L00633:  if a[p] # 0
           then go to L00640
         c - 1 -> c[x]
         shift left a[w]
         go to L00633

L00640:  m1 exchange c
         jsb S00604
         go to L00560

S00643:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S00646:  1 -> s 6
         if b[m] = 0
           then go to L01756
L00651:  0 -> s 8
         0 -> b[s]
         if a[s] # 0
           then go to L00267
         if b[m] = 0
           then go to L00267
         a exchange c[x]
         c -> a[x]
         if c[x] = 0
           then go to L00623
         a + c -> a[x]
         if n/c go to L00667
         0 - c - 1 -> c[x]
         1 -> s 8
L00667:  0 -> a[ms]
         a exchange c[ms]
         0 -> a[w]
         p <- 12
         a - b -> a[wp]
         c - 1 -> c[p]
L00675:  c + 1 -> c[p]
L00676:  a -> b[w]
         m1 exchange c
         m1 -> c
         go to L00703

L00702:  shift right a[w]
L00703:  c - 1 -> c[s]
         if n/c go to L00702
         m1 -> c
         a + b -> a[w]
         a - 1 -> a[s]
         if n/c go to L00675
         c + 1 -> c[s]
         a exchange b[w]
         shift left a[w]
         p - 1 -> p
         if p # 5
           then go to L00676
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
           then go to L01024
         p <- 6
L00733:  shift right a[w]
         b exchange c[w]
L00735:  delayed rom @02
         jsb S01154
         b exchange c[w]
         delayed rom @02
         jsb S01033
         if c[m] = 0
           then go to L00777
         if p # 13
           then go to L00733
         0 -> b[w]
         p <- 0
         a -> b[p]
         a + b -> a[w]
         shift right a[w]
         b exchange c[w]
         delayed rom @03
         jsb S01651
         if s 8 = 1
           then go to L00765
         a exchange b[w]
         a - b -> a[w]
         a exchange b[w]
         a + b -> a[w]
         a exchange b[w]
L00765:  p <- 3
L00766:  delayed rom @02
         jsb S01033
         if c[m] = 0
           then go to L00777
         shift right a[w]
         go to L00766

L00774:  shift right a[w]
         delayed rom @02
         go to L01002

L00777:  if a[s] # 0
           then go to L00774
         c - 1 -> c[x]
L01002:  0 -> c[ms]
         if 0 = s 8
           then go to L01006
         0 - c - 1 -> c[s]
L01006:  delayed rom @00
         jsb S00114
         if 0 = s 6
           then go to L01040
         delayed rom @01
         jsb S00436
         delayed rom @00
         jsb S00176
L01016:  m1 -> c
L01017:  if c[s] = 0
           then go to S01044
         a - 1 -> a[x]
         b exchange c[w]
         go to L01017

L01024:  shift right a[w]
L01025:  jsb S01264
         a exchange b[w]
         p <- 6
         delayed rom @01
         go to L00735

L01032:  a + b -> a[w]
S01033:  c - 1 -> c[p]
         if n/c go to L01032
         0 -> c[p]
         c + 1 -> c[x]
         p + 1 -> p
L01040:  return

S01041:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S01044:  1 -> s 8
         if a[s] # 0
           then go to L01050
         0 -> s 8
L01050:  0 -> a[ms]
         a exchange b[w]
         b -> c[w]
         c + c -> c[x]
         if n/c go to L01071
         b -> c[w]
         if a[s] # 0
           then go to L01075
         p <- 13
L01061:  p - 1 -> p
         if p = 5
           then go to L01213
         c + 1 -> c[x]
         if n/c go to L01061
L01066:  jsb S01154
         b exchange c[w]
         go to L01201

L01071:  delayed rom @03
         jsb S01651
         p <- 6
         go to L01102

L01075:  a exchange b[w]
         a + 1 -> a[x]
         shift right b[w]
         go to L01050

L01101:  c + 1 -> c[m]
L01102:  a - b -> a[w]
         if n/c go to L01101
         a + b -> a[w]
         shift left a[w]
         c - 1 -> c[x]
         if n/c go to L01121
         p <- 5
         if c[p] = 0
           then go to L01117
         c - 1 -> c[p]
         if c[p] # 0
           then go to L01126
         c + 1 -> c[p]
L01117:  p <- 12
         go to L01211

L01121:  a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[p] = 0
           then go to L01102
L01126:  0 -> c[w]
         p <- 12
         c - 1 -> c[wp]
         c -> a[w]
         p <- 2
         load constant 1
         if 0 = s 8
           then go to L01137
         0 - c - 1 -> c[x]
L01137:  a exchange b[w]
         c -> a[w]
L01141:  if 0 = s 4
           then go to S01151
         delayed rom @01
         jsb S00470
         delayed rom @00
         jsb S00367
         delayed rom @01
         jsb S00420
S01151:  a exchange b[w]
         delayed rom @00
         go to S00120

S01154:  0 -> c[w]
         if p = 12
           then go to L00376
         c - 1 -> c[m]
         load constant 4
         c + 1 -> c[m]
         if p = 10
           then go to L01671
         if p = 9
           then go to L01706
         if p = 8
           then go to L01722
         if p = 7
           then go to L01734
         if p = 6
           then go to L01744
         p <- 0
         load constant 3
         p <- 6
         return

L01200:  c + 1 -> c[p]
L01201:  a - b -> a[w]
         if n/c go to L01200
         a + b -> a[w]
         if p = 6
           then go to L01214
         shift left a[w]
         c - 1 -> c[x]
         p - 1 -> p
L01211:  b exchange c[w]
         go to L01066

L01213:  b exchange c[w]
L01214:  if 0 = s 4
           then go to L01221
         jsb S01264
         a exchange c[w]
         a exchange b[w]
L01221:  p <- 13
         load constant 6
         p <- 5
L01224:  if c[m] = 0
           then go to L01312
         p + 1 -> p
L01227:  if c[p] = 0
           then go to L01236
         c - 1 -> c[p]
         a -> b[w]
         m1 exchange c
         m1 -> c
         go to L01256

L01236:  c + 1 -> c[x]
         shift right a[w]
         c - 1 -> c[s]
         if n/c go to L01224
         shift right c[w]
         shift right c[w]
         shift right c[w]
         a + 1 -> a[p]
         a exchange b[w]
         c -> a[w]
         if 0 = s 8
           then go to L01141
         delayed rom @00
         jsb S00355
         go to L01141

L01255:  shift right b[w]
L01256:  c - 1 -> c[s]
         if n/c go to L01255
         a + b -> a[w]
         a + 1 -> a[s]
         m1 -> c
         go to L01227

S01264:  m1 exchange c
         m1 -> c
         a -> b[w]
         b exchange c[w]
         c + c -> c[w]
         c + c -> c[w]
         a + c -> c[w]
         a exchange b[w]
L01274:  shift right c[w]
         if c[w] # 0
           then go to L01302
         m1 -> c
         a exchange c[w]
         return

L01302:  a + 1 -> a[x]
         if n/c go to L01274
         0 - c -> c[w]
         0 -> c[s]
         m1 exchange c
         c + 1 -> c[x]
         delayed rom @00
         go to L00240

L01312:  a exchange b[w]
         0 -> c[ms]
         c -> a[w]
         if 0 = s 8
           then go to L01322
         0 - c - 1 -> c[s]
         delayed rom @01
         jsb S00565
L01322:  if 0 = s 4
           then go to L01326
         delayed rom @01
         jsb S00470
L01326:  delayed rom @00
         jsb S00374
         go to S01151

L01331:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         jsb S00470
         y -> a
         m2 -> c
         if a[s] # 0
           then go to L01771
         go to L01363

L01343:  if c[x] = 0
           then go to L00267
         c - 1 -> c[x]
L01346:  shift left a[ms]
         if a[m] # 0
           then go to L01343
         if c[x] # 0
           then go to L01363
         a exchange c[s]
         c -> a[s]
         c + c -> c[s]
         c + c -> c[s]
         a + c -> c[s]
         if c[s] = 0
           then go to L01363
         1 -> s 7
L01363:  y -> a
         0 -> a[s]
         a exchange c[w]
         0 -> s 4
         delayed rom @01
         jsb S00643
         stack -> a
         if 0 = s 7
           then go to L01375
         0 - c - 1 -> c[s]
L01375:  delayed rom @04
         go to L02002

S01377:  rom checksum

S01400:  select rom go to L00001

S01401:  select rom go to L00002

         select rom go to L00003

S01403:  select rom go to L00004

         select rom go to L00005

         select rom go to L00006

S01406:  select rom go to L00007

S01407:  p <- 12
         if c[s] # 0
           then go to L00267
         if c[xs] # 0
           then go to L00267
         c -> a[w]
L01415:  a -> b[w]
         shift left a[ms]
         if a[wp] # 0
           then go to L01426
         a + 1 -> a[x]
         if a >= c[x]
           then go to L01432
         c + 1 -> c[xs]
         return

L01426:  a - 1 -> a[x]
         if n/c go to L01415
         delayed rom @00
         go to L00267

L01432:  0 -> c[w]
         c + 1 -> c[p]
         shift right c[w]
         c + 1 -> c[s]
         b exchange c[w]
L01437:  if b[p] = 0
           then go to L01443
         shift right b[wp]
         c + 1 -> c[x]
L01443:  0 -> a[w]
         a - c -> a[p]
         if n/c go to L01451
         shift left a[w]
L01447:  a + b -> a[w]
         if n/c go to L01447
L01451:  a - c -> a[s]
         if n/c go to L01460
         shift right a[wp]
         a + 1 -> a[w]
         c + 1 -> c[x]
L01456:  a + b -> a[w]
         if n/c go to L01456
L01460:  a exchange b[wp]
         c - 1 -> c[p]
         if n/c go to L01437
         c - 1 -> c[s]
         if n/c go to L01437
         shift left a[w]
         a -> b[x]
         0 -> c[ms]
         a + b -> a[wp]
         a + c -> a[w]
         a exchange c[ms]
         return

L01474:  0 -> s 13
         go to L01477

L01476:  1 -> s 13
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

S01566:  if 0 = s 13
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

S01621:  if 0 = s 13
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

S01651:  p <- 12
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

L01671:  load constant 3
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

L01706:  p <- 8
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

L01722:  p <- 6
         load constant 3
         load constant 3
         load constant 3
         load constant 0
         load constant 8
         load constant 3
         load constant 5
         p <- 9
         return

L01734:  p <- 4
         load constant 3
         load constant 3
         load constant 3
         load constant 3
         load constant 1
         p <- 8
         return

L01744:  p <- 2
         load constant 3
         load constant 3
         load constant 3
         p <- 7
         return

L01752:  a exchange b[w]
         b exchange c[w]
         delayed rom @02
         go to L01025

L01756:  delayed rom @01
         jsb S00436
         if c[m] = 0
           then go to L00267
         m1 -> c
         if c[s] # 0
           then go to L00267
         0 -> a[w]
         0 -> b[w]
         delayed rom @02
         go to L01141

L01771:  a exchange c[m]
         if c[xs] # 0
           then go to L00267
         delayed rom @02
         go to L01346

         nop

         .dw @0533			; CRC, quad 0 (@0000..@1777)

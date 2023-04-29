; 34C model-specific firmware, uses 1820-2162 CPU ROM
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

         .arch woodstock

         .include "1820-2162.inc"

; flags:
; f  s7=1
; g  s14=1

	 .bank 0
	 .org @2000

L02000:  go to L02015

L02001:  bank toggle

L02002:  go to L02010

L02003:  p <- 0
L02004:  bank toggle

L02005:  1 -> s 9
         m2 exchange c
         go to L02025

L02010:  c -> a[w]
         jsb S02032
         m2 exchange c
         c -> data
         a exchange c[w]
L02015:  delayed rom @03
         jsb S01572
         m2 exchange c
         if p # 10
           then go to L02024
         0 -> s 1
         0 -> s 2
L02024:  0 -> s 9
L02025:  0 -> s 11
         a exchange b[w]
         bank toggle

         nop
L02031:  bank toggle

S02032:  delayed rom @17
         go to S07402

L02034:  a exchange b[x]
         jsb S02032
         if s 1 = 1
           then go to L02042
         if 0 = s 2
           then go to L02057
L02042:  register -> c 14
         p <- 12
         delayed rom @05
         jsb S02765
         register -> c 15
         p <- 6
         0 -> a[wp]
L02051:  jsb S02230
         if c[x] = 0
           then go to L02057
         if c[xs] = 0
           then go to L02177
         go to L02051

L02057:  a exchange b[x]
         p <- 0
         load constant 4
         p <- 0
         if a >= c[p]
           then go to L02066
         go to L02071

L02066:  load constant 6
         p <- 0
         a + c -> a[p]
L02071:  1 -> s 10
         delayed rom @15
         jsb S06772
         a -> b[x]
         jsb S02032
         if s 1 = 1
           then go to L02107
         if s 2 = 1
           then go to L02107
         0 -> c[w]
         0 -> a[w]
         c -> register 14
         c -> register 15
         go to L02120

L02107:  delayed rom @15
         go to L06745

L02111:  c -> a[w]
         register -> c 14
         p <- 1
         jsb S02227
         a exchange c[w]
         b -> c[x]
         c -> register 15
L02120:  decimal
         0 -> s 11
         if s 13 = 1
           then go to L02242
         0 -> s 0
         register -> c 14
L02126:  p <- 6
         c -> a[wp]
         p <- 3
         a exchange c[w]
         b -> c[x]
         load constant 3
         c -> register 14
         0 -> c[w]
         c -> register 3
         c -> register 4
         m2 -> c
         c -> register 1
         y -> a
         a - c -> c[w]
         if c[w] # 0
           then go to L02225
         if a[w] # 0
           then go to L02220
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         p <- 0
         load constant 7
         0 - c -> c[x]
L02156:  c -> register 2
         c -> register 5
         m2 exchange c
         0 -> a[x]
L02162:  jsb S02323
L02163:  b -> c[x]
         c -> register 15
         0 -> s 11
         if s 1 = 1
           then go to L02173
         if s 2 = 1
           then go to L02175
         1 -> s 2
L02173:  if 0 = s 4
           then go to L02031
L02175:  delayed rom @15
         go to L06775

L02177:  a exchange c[w]
         m1 exchange c
         0 -> c[x]
         p <- 0
         load constant 3
         p <- 0
         if s 13 = 1
           then go to L02213
         if a >= c[p]
           then go to L02215
L02211:  p <- 5
         go to L02004

L02213:  if a >= c[p]
           then go to L02211
L02215:  m1 -> c
         a exchange c[w]
         go to L02051

L02220:  p <- 6
         a + 1 -> a[p]
         if n/c go to L02225
         a - 1 -> a[p]
         a - 1 -> a[p]
L02225:  a exchange c[w]
         go to L02156

S02227:  a + 1 -> a[p]
S02230:  shift right c[w]
         a exchange c[s]
         rotate left a
         shift right c[w]
         a exchange c[s]
         rotate left a
         shift right c[w]
         a exchange c[s]
         rotate left a
         return

L02242:  a exchange b[x]
         p <- 6
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         register -> c 14
         p <- 3
         c -> a[wp]
         a exchange c[w]
         c -> register 14
         jsb S02371
         y -> a
         0 -> c[w]
         m2 exchange c
         c -> register 8
         c -> stack
         a exchange c[w]
         c -> register 7
         0 - c - 1 -> c[s]
         delayed rom @00
         jsb ad2-10
         0 -> c[w]
         c -> register 12
         c -> register 11
         if b[m] = 0
           then go to L03565
         load constant 5
         c - 1 -> c[x]
         delayed rom @00
         jsb mp1-10
         register -> c 7
         delayed rom @00
         jsb ad1-10
         m2 exchange c
         0 -> a[x]
L02306:  a + 1 -> a[x]
         a + 1 -> a[x]
         register -> c 12
         b exchange c[w]
         jsb S02032
         b exchange c[w]
         c -> register 0
         jsb S02323
         shift right b[w]
         shift right b[w]
         shift right b[w]
         shift right b[w]
         go to L02163

S02323:  a + 1 -> a[x]
         register -> c 15
         a exchange c[ms]
         m2 -> c
         delayed rom @03
         jsb S01572
         c -> stack
         c -> stack
         c -> stack
         m2 exchange c
         register -> c 14
         b exchange c[w]
         b -> c[w]
         jsb S02230
         p <- 6
         b -> c[wp]
         c -> register 14
L02344:  a exchange c[w]
         return

L02346:  p <- 9
         go to L02004

L02350:  p <- 0
L02351:  c -> data address
         c -> data
         c + 1 -> c[p]
         if n/c go to L02351
         m1 -> c
L02356:  c -> data address
         a exchange c[w]
         data -> c
         a - c -> c[w]
         if c[w] # 0
           then go to L02346
         a exchange c[w]
         c + 1 -> c[p]
         if n/c go to L02356
         clear data registers
         go to L02376

S02371:  0 -> c[w]
         p <- 1
         load constant 3
         c -> data address
         p <- 12
L02376:  0 -> c[w]
         return

S02400:  select rom @00 (x-ad2-10)

S02401:  select rom @00 (x-ad1-10)

S02402:  select rom @00 (x-ad2-13)

S02403:  select rom @00 (x-mp2-10)

S02404:  select rom @00 (x-mp1-10)

S02405:  select rom @00 (x-mp2-13)

         select rom @00 (x-dv2-10)

S02407:  select rom @00 (x-dv1-10)

         select rom @00 (x-dv2-13)

S02411:  delayed rom @17
         go to S07402

S02413:  select rom @01 (x-stscr)

S02414:  select rom @01 (L00415)

S02415:  select rom @01 (L00416)

L02416:  0 - c - 1 -> c[x]
L02417:  a exchange b[w]
         a + c -> a[x]
S02421:  delayed rom @04
         go to S02371

S02423:  jsb S02421
         m2 -> c
S02425:  if c[m] # 0
           then go to L02432
         0 -> c[x]
         c + 1 -> c[x]
         c - 1 -> c[xs]
L02432:  0 -> c[ms]
         load constant 5
         b exchange c[w]
         0 -> c[w]
         p <- 1
         c + 1 -> c[p]
         c -> data address
         register -> c 15
         shift right c[w]
         0 -> a[w]
         a - 1 -> a[wp]
         0 -> a[p]
         if c[xs] # 0
           then go to L02453
         if b[xs] = 0
           then go to L02463
L02452:  0 -> b[x]
L02453:  f -> a[x]
L02454:  a exchange c[w]
         c + 1 -> c[x]
         c - 1 -> c[x]
         if c[p] = 0
           then go to L02416
         0 -> c[p]
         go to L02417

L02463:  if a >= b[x]
           then go to L02452
         go to L02454

L02466:  jsb S02421
         c -> register 0
         m2 -> c
         c -> register 13
         jsb S02425
         a exchange c[w]
         m2 exchange c
         p <- 12
         0 -> c[w]
         load constant 2
         c -> register 10
         c + c -> c[w]
         c -> register 15
         jsb S02411
         m2 -> c
         c -> register 11
         register -> c 9
         0 -> c[s]
L02510:  0 -> c[x]
         c -> register 9
         0 -> c[w]
         c -> register 10
         c -> register 12
         jsb S02421
         register -> c 11
         c -> a[w]
         register -> c 13
         jsb S02400
         c -> register 12
         register -> c 7
         0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 8
         jsb S02400
         register -> c 12
         jsb S02404
         delayed rom @03
         jsb S01572
         c -> register 12
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
L02540:  c -> register 14
         0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 10
         jsb S02400
         if c[s] # 0
           then go to L03017
         jsb S02404
         register -> c 10
         jsb S02407
         c -> register 11
         register -> c 10
         c -> a[w]
         jsb S02400
         register -> c 14
         jsb S02401
         register -> c 11
         jsb S02404
         register -> c 15
         jsb S02407
         0 -> c[w]
         load constant 2
         load constant 5
         c - 1 -> c[x]
         jsb S02404
         m2 exchange c
         register -> c 7
         jsb S02712
         m2 -> c
         jsb S02404
         m2 exchange c
         m2 -> c
         c -> a[w]
         register -> c 7
         jsb S02400
         m2 exchange c
         jsb S02712
         c -> register 11
         0 -> a[x]
L02607:  a + 1 -> a[x]
         1 -> s 4
         delayed rom @04
         go to L02306

L02613:  jsb S02423
         a exchange c[w]
         c -> register 9
         register -> c 11
         m2 exchange c
         c -> register 11
         0 -> a[x]
         a + 1 -> a[x]
         if n/c go to L02607
L02624:  jsb S02423
         register -> c 9
         jsb S02400
         c -> register 9
         register -> c 14
         c -> a[w]
         0 - c - 1 -> c[s]
         jsb S02403
         register -> c 15
         jsb S02401
         register -> c 15
         jsb S02407
         0 -> c[w]
         load constant 1
         load constant 5
         jsb S02404
         jsb S02411
         jsb S02413
         jsb S02421
         register -> c 9
         jsb S02404
         m2 exchange c
         c -> a[w]
         register -> c 11
         jsb S02400
         jsb S02411
         jsb S02414
         jsb S02405
         register -> c 10
         b exchange c[s]
         m1 exchange c
         register -> c 9
         b exchange c[s]
         m1 exchange c
         jsb S02402
         jsb S02413
         register -> c 9
         a exchange c[x]
         c -> register 9
         a exchange b[s]
         b exchange c[w]
         c -> register 10
         m2 -> c
         c -> a[w]
         register -> c 12
         jsb S02400
         c -> register 12
         m2 exchange c
         jsb S02421
         load constant 2
         c -> a[w]
         register -> c 14
         jsb S02400
         go to L02540

S02712:  0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 8
         go to S02400

L02716:  0 -> c[w]
         c - 1 -> c[x]
         m1 exchange c
         0 -> c[w]
         load constant 9
         load constant 1
         load constant 8
         load constant 9
         load constant 3
         load constant 8
         load constant 5
         load constant 3
         load constant 3
         load constant 2
         load constant 0
         load constant 7
         jsb S02402
         jsb S02415
         a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         jsb S02402
         delayed rom @01
         jsb S00420
         jsb S02415
         0 -> c[w]
         0 - c - 1 -> c[s]
         c - 1 -> c[x]
         p <- 12
         load constant 5
         jsb S02401
         jsb S02413
         delayed rom @06
         go to L03324

L02760:  jsb S02415
         delayed rom @02
         jsb S01151
         delayed rom @04
         go to L02002

S02765:  if c[p] # 0
           then go to L02775
         p <- 11
         if c[p] # 0
           then go to L02775
         p <- 10
         if c[p] = 0
           then go to L02344
L02775:  p <- 8
         delayed rom @04
         go to L02004

S03000:  select rom @00 (x-ad2-10)

S03001:  select rom @00 (x-ad1-10)

S03002:  select rom @00 (x-ad2-13)

S03003:  select rom @00 (x-mp2-10)

S03004:  select rom @00 (x-mp1-10)

S03005:  select rom @00 (x-mp2-13)

S03006:  select rom @00 (x-dv2-10)

S03007:  select rom @00 (x-dv1-10)

S03010:  delayed rom @01
         go to S00470

S03012:  delayed rom @17
         go to S07402

S03014:  select rom @01 (L00415)

S03015:  delayed rom @04
         go to S02371

L03017:  m2 -> c
         c -> a[w]
         register -> c 10
         jsb S03006
         m2 exchange c
         register -> c 15
         c -> a[w]
         jsb S03012
         register -> c 11
         a exchange c[w]
         0 - c - 1 -> c[s]
         jsb S03006
         register -> c 11
         0 - c - 1 -> c[s]
         jsb S03001
         m2 -> c
         jsb S03001
         0 -> c[w]
         load constant 5
         c - 1 -> c[x]
         jsb S03004
         register -> c 11
         jsb S03001
         c -> register 11
         jsb S03014
         jsb S03015
         data -> c
         m2 exchange c
         register -> c 10
         jsb S03007
         register -> c 13
         0 - c - 1 -> c[s]
         jsb S03001
         m2 -> c
         jsb S03001
         register -> c 13
         m2 exchange c
         m1 exchange c
         register -> c 15
         c -> stack
         jsb S03012
         jsb S03010
         m2 -> c
         c -> a[w]
         m1 -> c
         jsb S03000
         a exchange c[w]
         stack -> a
         a exchange c[w]
         0 - c - 1 -> c[s]
         jsb S03007
         jsb S03322
         jsb S03002
         0 -> c[w]
         load constant 5
         c - 1 -> c[x]
         jsb S03004
         m2 -> c
         jsb S03001
         jsb S03010
         register -> c 11
         m2 exchange c
         jsb S03015
         register -> c 10
         c + c -> c[m]
         if n/c go to L03124
         c + 1 -> c[s]
         shift right c[ms]
         c + 1 -> c[x]
L03124:  c -> a[w]
         c -> register 10
         0 - c - 1 -> c[s]
         jsb S03003
         0 - c - 1 -> c[s]
         c -> register 15
         delayed rom @00
         jsb addone
         0 - c - 1 -> c[s]
         c -> stack
         m2 -> c
         y -> a
         a exchange c[w]
         jsb S03006
         m2 -> c
         jsb S03001
         m2 exchange c
         jsb S03012
         m2 -> c
         c -> register 11
         stack -> a
         0 -> b[w]
         a exchange b[m]
         jsb S03014
         delayed rom @00
         jsb dv2-13
         jsb S03014
         jsb S03002
         m2 exchange c
         a -> b[s]
         b -> c[w]
         c -> register 10
         register -> c 9
         a exchange c[x]
         c -> a[x]
         c -> register 9
         m2 -> c
         0 - c - 1 -> c[s]
         jsb S03001
         c -> a[w]
         register -> c 9
         c -> stack
         jsb S03015
         a exchange c[w]
         c -> register 11
         register -> c 13
         0 - c - 1 -> c[s]
         c -> a[w]
         m2 -> c
         jsb S03000
         c -> register 12
         m2 -> c
         c -> register 13
         1 -> s 7
         1 -> s 8
         0 -> c[w]
         c -> register 9
         stack -> a
         p <- 12
         0 -> a[wp]
         rotate left a
         p <- 1
         load constant 3
         c -> stack
         load constant 6
         p <- 1
         c -> a[p]
         1 -> s 6
         if a >= c[wp]
           then go to L03234
         a exchange c[w]
         0 -> s 6
L03234:  m2 exchange c
L03235:  if s 7 = 1
           then go to L03241
         0 -> s 8
         go to L03242

L03241:  0 -> s 7
L03242:  register -> c 9
         c -> a[w]
         0 -> c[w]
         p <- 12
         load constant 4
         jsb S03003
         0 -> c[w]
         load constant 3
         jsb S03001
         c -> register 9
         register -> c 11
         y -> a
         a exchange c[w]
         c -> data address
         data -> c
         0 - c - 1 -> c[s]
         jsb S03000
         register -> c 12
         jsb S03001
         c -> register 14
         jsb S03012
         register -> c 11
         c -> a[w]
         jsb S03015
         a exchange c[w]
         c -> a[w]
         c + c -> c[ms]
         a + c -> a[ms]
         if a[s] # 0
           then go to L03370
         go to L03372

L03301:  clear regs
         c + 1 -> c[w]
         m2 exchange c
         0 -> c[w]
         m2 exchange c
         m1 exchange c
         m1 exchange c
         down rotate
         down rotate
         down rotate
         down rotate
         b exchange c[w]
         a exchange b[w]
         f exchange a[x]
         f exchange a[x]
         delayed rom @07
         go to L03601

S03322:  delayed rom @01
         go to S00436

L03324:  delayed rom @01
         jsb S00532
         delayed rom @01
         jsb S00543
         jsb S03322
         jsb S03005
         jsb S03322
         jsb S03002
         delayed rom @02
         jsb S01044
         jsb S03010
         delayed rom @17
         jsb S07700
         0 -> b[w]
         b exchange c[m]
         c -> a[w]
L03344:  jsb S03010
         if b[m] = 0
           then go to L02760
         m2 -> c
         jsb S03001
         delayed rom @07
         go to L03765

         nop
S03354:  rom checksum

S03355:  bank toggle

         go to L03301

         nop
S03360:  bank toggle

         return

         nop
S03363:  bank toggle

         return

         nop
S03366:  bank toggle

         return

L03370:  a + 1 -> a[x]
         shift right a[ms]
L03372:  register -> c 14
         0 -> c[s]
         0 - c - 1 -> c[s]
         jsb S03000
         if c[s] = 0
           then go to L03440
         0 -> s 7
         1 -> s 8
         y -> a
         m2 -> c
         if a >= c[x]
           then go to L03436
         a exchange c[w]
         c -> data address
         a exchange c[w]
         data -> c
         0 - c - 1 -> c[s]
         a exchange c[w]
         c + 1 -> c[w]
         c -> data address
         data -> c
         delayed rom @00
         jsb ad2-10
         register -> c 9
         delayed rom @00
         jsb mp1-10
         register -> c 14
         delayed rom @00
         jsb dv1-10
         0 -> c[w]
         load constant 2
         0 - c - 1 -> c[s]
         delayed rom @00
         jsb ad1-10
         if c[s] = 0
           then go to L03440
L03436:  1 -> s 7
         1 -> s 8
L03440:  y -> a
         register -> c 11
         a exchange c[w]
         c -> data address
         a exchange c[w]
         c -> data
         register -> c 14
         c -> a[w]
         register -> c 9
         delayed rom @00
         jsb dv2-10
         register -> c 11
         delayed rom @00
         jsb ad1-10
         c -> register 11
         stack -> a
         if 0 = s 8
           then go to L03511
         m2 -> c
         a exchange c[w]
         c + 1 -> c[x]
         c -> stack
         if a >= c[x]
           then go to L03235
         stack -> a
         if s 6 = 1
           then go to L03501
         a exchange c[w]
         register -> c 11
         a exchange c[w]
         c -> data address
         a exchange c[w]
         c -> data
L03501:  delayed rom @17
         jsb S07402
         register -> c 9
         c + 1 -> c[s]
         if n/c go to L03507
         c - 1 -> c[s]
L03507:  delayed rom @05
         go to L02510

L03511:  register -> c 7
         c -> stack
         0 - c - 1 -> c[s]
         a exchange c[w]
         register -> c 8
         c -> stack
         delayed rom @00
         jsb ad2-10
         register -> c 13
         m2 exchange c
         register -> c 11
         m1 exchange c
         delayed rom @17
         jsb S07402
         delayed rom @01
         jsb S00470
         m2 -> c
         c -> a[w]
         m1 -> c
         delayed rom @00
         jsb ad2-10
         delayed rom @01
         jsb S00535
         delayed rom @00
         jsb mp2-13
         m2 exchange c
         delayed rom @01
         jsb S00535
         0 -> a[s]
         register -> c 11
         delayed rom @00
         jsb mp1-10
         m2 -> c
         p <- 12
         0 -> c[ms]
         load constant 5
         p <- 1
         c - 1 -> c[p]
         if n/c go to L03561
         c - 1 -> c[xs]
L03561:  delayed rom @00
         jsb ad1-10
         delayed rom @03
         jsb S01572
L03565:  c -> stack
         delayed rom @17
         jsb S07402
         delayed rom @15
         go to L06423

S03572:  if s 5 = 1
           then go to L02346
S03574:  m2 exchange c
         p <- 12
         c + 1 -> c[p]
         m2 exchange c
         return

L03601:  a - 1 -> a[w]
         if a[w] # 0
           then go to L02346
         jsb S03574
         binary
         p <- 1
         load constant 1
         load constant 15
         c -> stack
         c -> stack
L03613:  load constant 5
         if p # 13
           then go to L03613
         c -> stack
         c + c -> c[w]
         down rotate
         down rotate
         0 -> s 4
         jsb S03734
         b exchange c[w]
         a exchange c[w]
         down rotate
         c -> a[w]
         down rotate
         c + c -> c[w]
         a - c -> a[w]
         if a[w] # 0
           then go to L02346
         down rotate
         b -> c[w]
         1 -> s 4
         jsb S03734
         a - c -> a[w]
         0 -> c[w]
         p <- 2
         load constant 1
         load constant 15
         a - c -> a[w]
         if a[w] # 0
           then go to L02346
         down rotate
         stack -> a
         a - c -> a[w]
         if a[w] # 0
           then go to L02346
         0 -> c[w]
         p <- 1
         load constant 2
         jsb S03727
         p <- 1
         load constant 3
         jsb S03727
         c - 1 -> c[w]
         c -> data address
         jsb S03574
         delayed rom @02
         jsb S01377
         jsb S03572
         delayed rom @06
         jsb S03354
         delayed rom @13
         jsb S05400
         delayed rom @15
         jsb S06460
         jsb S03572
         delayed rom @06
         jsb S03355
         jsb S03572
         delayed rom @06
         jsb S03360
         jsb S03572
         delayed rom @06
         jsb S03363
         jsb S03572
L03713:  load constant 2
         if p # 12
           then go to L03713
         b exchange c[w]
         b -> c[w]
         c + c -> c[w]
         c + c -> c[w]
         a exchange c[w]
         delayed rom @06
         jsb S03366
         delayed rom @04
         go to L02001

S03727:  jsb S03574
         m1 exchange c
         m1 -> c
         delayed rom @04
         go to L02350

S03734:  c -> data address
         b exchange c[w]
         data -> c
         a + c -> a[w]
         a exchange c[w]
         if s 4 = 1
           then go to L03762
         a + b -> a[w]
L03744:  a exchange c[w]
         down rotate
         down rotate
         down rotate
         c -> data
         0 -> c[w]
         data -> c
         down rotate
         c -> data
         b -> c[w]
         c - 1 -> c[x]
         if n/c go to S03734
         down rotate
         return

L03762:  a - b -> a[w]
         nop
         go to L03744

L03765:  delayed rom @01
         jsb S00515
         delayed rom @00
         jsb dv2-13
         delayed rom @01
         jsb S00420
         delayed rom @00
         jsb subone
         delayed rom @06
         go to L03344

	 .dw @0671			; CRC, bank 0 quad 1 (@02000..@03777)

S04000:  delayed rom @01
         go to S00470

S04002:  select rom @00 (x-ad2-13)

S04003:  delayed rom @01
         go to S00436

L04005:  if c[m] = 0
           then go to L04047
         if c[s] = 0
           then go to L04014
         1 -> s 7
         1 -> s 10
         0 -> c[s]
L04014:  m2 exchange c
         c -> a[w]
         delayed rom @00
         jsb mp2-10
         jsb S04000
         y -> a
         a exchange c[w]
         c -> a[w]
         delayed rom @00
         jsb mp2-10
         jsb S04003
         jsb S04002
         delayed rom @11
         jsb S04763
         stack -> a
         c -> stack
         m2 -> c
         delayed rom @00
         jsb dv2-10
         if c[m] # 0
           then go to L04070
         0 -> a[w]
         go to L04070

S04043:  if s 10 = 1
           then go to L04772
         1 -> s 10
         return

L04047:  stack -> a
         a exchange c[w]
         1 -> s 7
         if c[s] = 0
           then go to L04055
         1 -> s 4
L04055:  0 -> c[s]
         c -> stack
         if c[m] = 0
           then go to L05101
L04061:  0 -> a[w]
         go to L04316

L04063:  jsb S04043
         go to L04061

L04065:  0 -> b[w]
         c -> a[w]
         a exchange b[m]
L04070:  if c[s] = 0
           then go to L04102
         1 -> s 4
         if 0 = s 13
           then go to L04102
         if 0 = s 10
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
           then go to L04130
         b -> c[w]
         if b[w] = 0
           then go to L04061
         p <- 12
         c - 1 -> c[p]
         if c[w] # 0
           then go to L04130
         if s 6 = 1
           then go to L04063
         jsb S04240
         0 -> a[w]
         a - 1 -> a[x]
         a exchange c[w]
         go to L04316

L04130:  if s 6 = 1
           then go to L04367
L04132:  delayed rom @00
         jsb 1/x13
         jsb S04043
L04135:  a exchange b[w]
         b -> c[w]
         p <- 12
         0 -> c[ms]
L04141:  c + 1 -> c[x]
         if c[x] = 0
           then go to L04152
         c + 1 -> c[s]
         p - 1 -> p
         if p # 6
           then go to L04141
         b exchange c[w]
         go to L04316

L04152:  m1 exchange c
         0 -> c[w]
         c + 1 -> c[s]
         shift right c[w]
         go to L04173

L04157:  a exchange c[w]
         m1 exchange c
         c + 1 -> c[p]
         c -> a[s]
         m1 exchange c
L04164:  shift right b[w]
         shift right b[w]
         a - 1 -> a[s]
         if n/c go to L04164
         0 -> a[s]
         a + b -> a[w]
         a exchange c[w]
L04173:  a -> b[w]
         a - c -> a[w]
         if n/c go to L04157
         m1 exchange c
         c + 1 -> c[s]
         m1 exchange c
         a exchange b[w]
         shift left a[w]
         p - 1 -> p
         if p # 6
           then go to L04173
         b exchange c[w]
         delayed rom @00
         jsb div120
         a exchange b[w]
         m1 exchange c
         0 -> c[x]
         p <- 7
L04215:  b exchange c[w]
         jsb S04371
         b exchange c[w]
         go to L04222

L04221:  a + b -> a[w]
L04222:  c - 1 -> c[p]
         if n/c go to L04221
         shift right a[w]
         0 -> c[p]
         if c[m] = 0
           then go to L04313
         p + 1 -> p
         go to L04215

S04232:  0 -> c[w]
         m1 exchange c
         jsb S04240
         c + c -> c[w]
         shift right c[w]
         return

S04240:  p <- 12
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

L04261:  if 0 = s 6
           then go to L04135
         jsb S04000
         jsb S04000
         delayed rom @00
         jsb addone
         delayed rom @01
         jsb S00420
         delayed rom @00
         jsb subone
         jsb S04003
         delayed rom @00
         jsb mp2-13
         0 -> a[s]
         delayed rom @00
         jsb sqr13
         jsb S04003
         delayed rom @00
         jsb x/y13
         0 -> a[s]
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L04132
         go to L04135

L04312:  p + 1 -> p
L04313:  c - 1 -> c[x]
         if p # 12
           then go to L04312
L04316:  0 -> c[ms]
         delayed rom @00
         jsb shf10
         if 0 = s 10
           then go to L04330
         jsb S04232
         0 - c - 1 -> c[s]
         a exchange c[s]
         0 -> c[s]
         jsb S04002
L04330:  if 0 = s 7
           then go to L04334
         jsb S04232
         jsb S04002
L04334:  if s 12 = 1
           then go to L04353
         jsb S04232
         a + 1 -> a[x]
         a + 1 -> a[x]
         delayed rom @00
         jsb dv2-13
         if s 14 = 1
           then go to L04353
         0 -> c[w]
         p <- 12
         load constant 9
         c - 1 -> c[x]
         delayed rom @00
         jsb mp1-10
L04353:  if 0 = s 4
           then go to L04356
         0 - c - 1 -> c[s]
L04356:  if s 13 = 1
           then go to L05101
         0 -> s 7
         0 -> s 4
         delayed rom @12
         go to L05031

L04364:  p <- 3
         delayed rom @04
         go to L02004

L04367:  delayed rom @04
         go to L02003

S04371:  0 -> c[w]
         c - 1 -> c[w]
         0 -> c[s]
         if p = 12
           then go to L04412
         if p = 11
           then go to L04434
         if p = 10
           then go to L04444
         if p = 9
           then go to L04452
         if p = 8
           then go to L04456
         p <- 0
L04407:  load constant 7
         p <- 7
         return

L04412:  p <- 10
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

S04430:  load constant 6
         if p = 0
           then go to L04407
         go to S04430

L04434:  p <- 8
         jsb S04430
         p <- 0
         load constant 5
         p <- 4
         load constant 8
         p <- 11
         return

L04444:  p <- 6
         jsb S04430
         p <- 0
         load constant 9
         p <- 10
         return

L04452:  p <- 4
         jsb S04430
         p <- 9
         return

L04456:  p <- 2
         jsb S04430
         p <- 8
         return

L04462:  1 -> s 13
         1 -> s 6
         stack -> a
         a exchange c[w]
L04466:  0 -> a[w]
         0 -> b[w]
         a exchange c[m]
         if c[s] = 0
           then go to L04502
         1 -> s 7
         if 0 = s 6
           then go to L04500
         if 0 = s 10
           then go to L04501
L04500:  1 -> s 4
L04501:  0 -> c[s]
L04502:  b exchange c[w]
         if s 12 = 1
           then go to L04616
         if 0 = s 14
           then go to L04513
         a exchange c[w]
         c -> a[w]
         shift right c[w]
         a - c -> a[w]
L04513:  0 -> c[w]
         p <- 12
         load constant 4
         load constant 5
         b exchange c[w]
         c - 1 -> c[x]
         if c[xs] # 0
           then go to L04527
         c - 1 -> c[x]
         if n/c go to L04527
         c + 1 -> c[x]
         shift right a[w]
L04527:  b exchange c[w]
L04530:  m1 exchange c
         m1 -> c
         c + c -> c[w]
         c + c -> c[w]
         c + c -> c[w]
         shift right c[w]
         b exchange c[w]
         if c[xs] # 0
           then go to L04563
L04541:  a - b -> a[w]
         if n/c go to L04541
         a + b -> a[w]
         shift left a[w]
         c - 1 -> c[x]
         if n/c go to L04541
         0 -> c[w]
         b exchange c[w]
         m1 -> c
         c + c -> c[w]
         if 0 = s 12
           then go to L04557
         shift right a[w]
         shift right c[w]
L04557:  b exchange c[w]
L04560:  a - b -> a[w]
         if n/c go to L04574
         a + b -> a[w]
L04563:  b exchange c[w]
         m1 -> c
         b exchange c[w]
         if 0 = s 12
           then go to L04627
         if c[x] # 0
           then go to L04626
         shift left a[w]
         go to L04627

L04574:  if s 10 = 1
           then go to L04605
         1 -> s 10
L04577:  if s 4 = 1
           then go to L04603
         1 -> s 4
         go to L04560

L04603:  0 -> s 4
         go to L04560

L04605:  0 -> s 10
         if 0 = s 6
           then go to L04577
         if 0 = s 7
           then go to L04614
         0 -> s 7
         go to L04560

L04614:  1 -> s 7
         go to L04560

L04616:  delayed rom @10
         jsb S04240
         go to L04530

L04621:  a exchange b[w]
         a - b -> a[w]
         delayed rom @10
         jsb S04043
         go to L04634

L04626:  c + 1 -> c[x]
L04627:  if c[xs] # 0
           then go to L04634
         a - b -> a[w]
         if n/c go to L04621
         a + b -> a[w]
L04634:  c - 1 -> c[x]
         delayed rom @00
         jsb shf10
         if s 12 = 1
           then go to L04652
         m1 -> c
         c + c -> c[w]
         c - 1 -> c[x]
         delayed rom @00
         jsb dv1-10
         delayed rom @10
         jsb S04232
         delayed rom @00
         jsb mp2-13
L04652:  m1 exchange c
         a exchange c[w]
         c -> a[w]
         c + 1 -> c[x]
         if n/c go to L04665
         a exchange b[w]
         shift left a[w]
         go to L04670

L04662:  p - 1 -> p
         if p = 6
           then go to L04752
L04665:  c + 1 -> c[x]
         if n/c go to L04662
         a exchange b[w]
L04670:  0 -> c[w]
L04671:  b exchange c[w]
         delayed rom @10
         jsb S04371
         b exchange c[w]
         go to L04677

L04676:  c + 1 -> c[s]
L04677:  a - b -> a[w]
         if n/c go to L04676
         a + b -> a[w]
         p - 1 -> p
         shift right c[ms]
         shift left a[w]
         if p # 6
           then go to L04671
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
         go to L04734

L04722:  shift right a[wp]
         shift right a[wp]
L04724:  a - 1 -> a[s]
         if n/c go to L04722
         0 -> a[s]
         m1 exchange c
         a exchange c[w]
         a - c -> c[w]
         a + b -> a[w]
         m1 exchange c
L04734:  a -> b[w]
         c -> a[s]
         c - 1 -> c[p]
         if n/c go to L04724
         a exchange c[w]
         shift left a[m]
         a exchange c[w]
         if c[m] = 0
           then go to L05041
         c - 1 -> c[s]
         c - 1 -> c[x]
         0 -> a[s]
         shift right a[w]
         go to L04734

L04752:  m1 -> c
         if s 13 = 1
           then go to L05061
         if 0 = s 10
           then go to L05061
         delayed rom @00
         jsb 1/x13
         delayed rom @12
         go to L05061

S04763:  c - 1 -> c[xs]
         c - 1 -> c[xs]
         if c[xs] # 0
           then go to L05012
         c + 1 -> c[xs]
         c + 1 -> c[xs]
         return

L04772:  0 -> s 10
         return

L04774:  m2 -> c
         m1 exchange c
         m1 -> c
         0 -> c[x]
         go to L05020

S05001:  select rom @00 (x-ad1-10)

S05002:  select rom @00 (x-ad2-13)

S05003:  select rom @00 (x-mp2-10)

S05004:  select rom @00 (x-mp1-10)

S05005:  select rom @00 (x-mp2-13)

         select rom @00 (x-dv2-10)

S05007:  select rom @00 (x-dv1-10)

S05010:  select rom @00 (x-dv2-13)

S05011:  select rom @00 (x-x/y13)

L05012:  select rom @00 (x-sqr13)

S05013:  select rom @01 (x-stscr)

S05014:  select rom @01 (L00415)

S05015:  select rom @01 (L00416)

S05016:  delayed rom @03
         go to S01572

L05020:  jsb S05011
         c -> stack
         jsb S05014
         jsb S05005
         if 0 = s 10
           then go to L05031
         stack -> a
         c -> stack
         a exchange c[w]
L05031:  jsb S05016
         if 0 = s 7
           then go to L05035
         0 - c - 1 -> c[s]
L05035:  stack -> a
         c -> stack
         a exchange c[w]
         go to L05076

L05041:  0 -> c[s]
         m1 exchange c
         a exchange c[w]
         m1 -> c
         a - 1 -> a[w]
         if s 13 = 1
           then go to L05052
         if s 10 = 1
           then go to L05054
L05052:  0 - c -> c[x]
         a exchange b[w]
L05054:  if b[m] = 0
           then go to L05103
         m1 exchange c
         delayed rom @00
         jsb div15
L05061:  if 0 = s 6
           then go to L05076
         jsb S05013
         jsb S05014
         jsb S05005
         delayed rom @00
         jsb addone
         delayed rom @11
         jsb S04763
         if s 13 = 1
           then go to L04774
         delayed rom @00
         jsb 1/x13
L05076:  if 0 = s 4
           then go to L05101
         0 - c - 1 -> c[s]
L05101:  delayed rom @04
         go to L02002

L05103:  0 -> c[w]
         p <- 12
         c - 1 -> c[wp]
         p <- 2
         load constant 1
         c -> a[w]
         a -> b[w]
         if 0 = s 6
           then go to L05101
         go to L05061

L05115:  b exchange c[w]
         if b[m] = 0
           then go to L05131
         p <- 12
         b -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[x]
         if c[xs] # 0
           then go to L05173
L05126:  p - 1 -> p
         if p # 0
           then go to L05133
L05131:  b -> c[w]
         go to L05101

L05133:  c - 1 -> c[x]
         if n/c go to L05126
L05135:  0 -> c[w]
         b -> c[m]
         if s 8 = 1
           then go to L05156
         p + 1 -> p
         if p # 13
           then go to L05146
         jsb S05200
         go to L05151

L05146:  p + 1 -> p
         jsb S05200
         p - 1 -> p
L05151:  p - 1 -> p
         jsb S05200
         c -> a[w]
         b -> c[w]
         go to L05170

L05156:  0 -> a[w]
         jsb S05176
         p + 1 -> p
         if p = 13
           then go to L05164
         p + 1 -> p
L05164:  jsb S05176
         shift left a[w]
         a + c -> a[w]
         b exchange c[w]
L05170:  delayed rom @00
         jsb mpy150
         go to L05101

L05173:  if b[xs] = 0
           then go to L05131
         go to L05135

S05176:  shift right c[wp]
         a + c -> c[wp]
S05200:  c -> a[wp]
         shift right c[wp]
         c + c -> c[wp]
         c + c -> c[wp]
         a - c -> c[wp]
         if s 8 = 1
           then go to L05373
         0 -> a[w]
         c -> a[x]
         a + c -> c[w]
         0 -> c[x]
         return

L05214:  0 -> a[w]
         delayed rom @10
         jsb S04232
         b exchange c[w]
         m2 -> c
         jsb S05004
         jsb S05234
         jsb S05007
         go to L05101

L05225:  c -> a[w]
         jsb S05234
         jsb S05003
         delayed rom @10
         jsb S04232
         jsb S05010
         go to L05101

S05234:  0 -> c[w]
         p <- 12
         load constant 9
         c + 1 -> c[x]
         return

L05241:  jsb S05322
         0 -> a[w]
         p <- 12
         a + 1 -> a[p]
         a exchange c[w]
         delayed rom @13
         jsb S05717
         if c[s] # 0
           then go to L04364
         if c[m] = 0
           then go to L04364
         register -> c 3
         0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 1
         jsb S05003
         jsb S05320
         register -> c 5
L05263:  c -> a[w]
         jsb S05322
         jsb S05003
         jsb S05324
         jsb S05002
         delayed rom @01
         jsb S00420
         if s 7 = 1
           then go to L05302
         1 -> s 7
         jsb S05322
         register -> c 1
         jsb S05315
         register -> c 2
         go to L05263

L05302:  jsb S05014
         if s 4 = 1
           then go to L05330
         if s 8 = 1
           then go to L05417
         1 -> s 8
         jsb S05322
         register -> c 3
         jsb S05315
         register -> c 4
         go to L05263

S05315:  c -> a[w]
         0 - c - 1 -> c[s]
         jsb S05003
S05320:  jsb S05326
         jsb S05013
S05322:  delayed rom @03
         go to S01645

S05324:  jsb S05326
         go to S05014

S05326:  delayed rom @17
         go to S07402

L05330:  if b[m] = 0
           then go to L04364
         if 0 = s 6
           then go to L05343
         jsb S05015
         jsb S05010
         jsb S05016
         delayed rom @03
         jsb S01630
         0 -> a[w]
         go to L05345

L05343:  m2 -> c
         c -> a[w]
L05345:  jsb S05322
         jsb S05003
         register -> c 1
         0 - c - 1 -> c[s]
         jsb S05001
         jsb S05326
         jsb S05015
         jsb S05005
         jsb S05013
         jsb S05015
         jsb S05322
         register -> c 3
         jsb S05004
         jsb S05324
         jsb S05002
         jsb S05015
         jsb S05011
         jsb S05322
         jsb S05007
         if s 6 = 1
           then go to L05436
         go to L05101

L05373:  a + c -> a[wp]
         shift right c[wp]
         if c[wp] # 0
           then go to L05373
         return

S05400:  rom checksum

S05401:  select rom @00 (x-ad1-10)

         select rom @00 (x-ad2-13)

S05403:  select rom @00 (x-mp2-10)

S05404:  select rom @00 (x-mp1-10)

S05405:  select rom @00 (x-mp2-13)

S05406:  select rom @00 (x-dv2-10)

S05407:  select rom @00 (x-dv1-10)

S05410:  select rom @00 (x-dv2-13)

S05411:  select rom @00 (x-x/y13)

S05412:  select rom @00 (x-sqr13)

S05413:  select rom @01 (x-stscr)

S05414:  select rom @01 (L00415)

S05415:  select rom @01 (L00416)

S05416:  select rom @01 (L00417)

L05417:  if 0 = s 6
           then go to L05440
         jsb S05415
         jsb S05405
         if a[s] # 0
           then go to L04364
         if c[m] = 0
           then go to L04364
         m2 -> c
         if s 9 = 1
           then go to L05433
         c -> stack
L05433:  jsb S05412
         jsb S05416
         jsb S05410
L05436:  delayed rom @04
         go to L02000

L05440:  if a[s] # 0
           then go to L04364
         jsb S05415
         if a[s] # 0
           then go to L04364
         jsb S05565
         0 -> b[w]
         a exchange b[m]
         delayed rom @00
         jsb subone
         jsb S05473
         jsb S05413
         jsb S05415
L05455:  jsb S05414
         jsb S05411
         jsb S05475
         jsb S05407
         jsb S05412
         if s 6 = 1
           then go to L05436
         jsb S05551
         delayed rom @03
         jsb S01630
         1 -> s 6
         jsb S05473
         jsb S05416
         go to L05455

S05473:  delayed rom @17
         go to S07402

S05475:  delayed rom @03
         go to S01645

L05477:  jsb S05565
         0 -> c[w]
         p <- 12
         load constant 1
         jsb S05545
         c -> register 0
         register -> c 1
         c -> a[w]
         m2 -> c
         jsb S05545
         c -> register 1
         m2 -> c
         c -> a[w]
         jsb S05403
         register -> c 2
         jsb S05553
         c -> register 2
         y -> a
         register -> c 3
         a exchange c[w]
         jsb S05545
         c -> register 3
         y -> a
         a exchange c[w]
         c -> a[w]
         jsb S05403
         register -> c 4
         jsb S05553
         c -> register 4
         m2 -> c
         y -> a
         jsb S05403
         register -> c 5
         jsb S05553
         c -> register 5
         jsb S05562
         delayed rom @04
         go to L02005

S05545:  if 0 = s 4
           then go to S05550
         0 - c - 1 -> c[s]
S05550:  jsb S05720
S05551:  delayed rom @03
         go to S01572

S05553:  if 0 = s 4
           then go to L05560
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
L05560:  jsb S05401
         go to S05551

S05562:  jsb S05473
         m2 -> c
         c -> data
S05565:  delayed rom @03
         go to S01642

L05567:  register -> c 4
         a exchange c[w]
         jsb S05406
         delayed rom @00
         jsb subone
         jsb S05413
         register -> c 1
         c -> a[w]
         register -> c 5
         jsb S05717
         jsb S05414
         jsb S05405
         jsb S05413
         register -> c 5
         c -> a[w]
         register -> c 2
         jsb S05717
         jsb S05414
         jsb S05410
         jsb S05551
         c -> a[w]
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         jsb S05717
         c -> register 3
         c -> a[w]
         jsb S05710
         jsb S05717
         if c[s] = 0
           then go to L05661
         register -> c 3
         0 -> c[s]
         c -> a[w]
         c -> register 3
         jsb S05710
         jsb S05720
         jsb S05413
         register -> c 3
         c -> a[w]
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         jsb S05720
         jsb S05414
         jsb S05410
         jsb S05413
         jsb S05710
         0 - c -> c[x]
         0 - c - 1 -> c[s]
         jsb S05401
         if c[s] = 0
           then go to L05701
         jsb S05414
         m2 -> c
         0 - c - 1 -> c[s]
         jsb S05404
         go to L05675

L05661:  register -> c 3
         c -> a[w]
         jsb S05710
         0 - c -> c[x]
         jsb S05717
         if c[s] = 0
           then go to L05701
         register -> c 3
         c -> a[w]
         m2 -> c
         0 - c - 1 -> c[s]
         jsb S05403
L05675:  jsb S05551
         c -> register 3
         1 -> s 0
         go to L05727

L05701:  m2 -> c
         c + 1 -> c[x]
         c + 1 -> c[x]
         c + 1 -> c[x]
         0 - c - 1 -> c[s]
         nop
         go to L05675

S05710:  0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         p <- 0
         load constant 3
         0 - c -> c[x]
         return

S05717:  0 - c - 1 -> c[s]
S05720:  delayed rom @00
         go to ad2-10

L05722:  register -> c 4
         c -> register 3
         register -> c 2
         c -> register 1
         0 -> s 0
L05727:  m2 -> c
         c -> register 4
         register -> c 5
         c -> register 2
         c -> a[w]
         register -> c 1
         jsb S05717
         c -> register 5
         register -> c 3
         c -> a[w]
         register -> c 4
         jsb S05406
         0 -> c[w]
         c + 1 -> c[p]
         c + 1 -> c[m]
         0 - c - 1 -> c[s]
         jsb S05401
         register -> c 5
         m1 exchange c
         m1 -> c
         0 -> c[x]
         jsb S05411
         c -> a[w]
         register -> c 2
         jsb S05550
         c -> register 5
         c -> a[w]
         register -> c 2
         a - c -> c[w]
         if c[w] = 0
           then go to L05770
         delayed rom @14
         go to L06334

L05770:  register -> c 1
         c -> a[w]
         register -> c 2
         jsb S05717
         register -> c 2
         delayed rom @14
         go to L06276

	 .dw @1255			; CRC, bank 0 quad 2 (@04000..05777)

         nop

         go to L06024

         go to L06352

         go to L06007

         go to L06011

         delayed rom @05
         go to L02624

L06007:  delayed rom @05
         go to L02466

L06011:  delayed rom @05
         go to L02613

S06013:  select rom @01 (x-stscr)

S06014:  select rom @01 (L00415)

S06015:  select rom @01 (L00416)

L06016:  c -> a[w]
         shift left a[x]
         display off
         m2 -> c
         decimal
         a -> rom address

L06024:  if c[w] = 0
           then go to L06364
         register -> c 4
         if c[w] = 0
           then go to L06246
         c -> a[w]
         m2 -> c
         a - c -> c[s]
         if c[s] = 0
           then go to L06040
L06036:  delayed rom @13
         go to L05722

L06040:  0 -> a[s]
         0 - c - 1 -> c[s]
         jsb S06222
         if c[s] # 0
           then go to L06230
         if c[w] = 0
           then go to L06230
         register -> c 3
         if c[w] = 0
           then go to L06064
         register -> c 14
         p <- 3
         c -> a[p]
         load constant 3
         p <- 3
         a + 1 -> a[p]
         if a >= c[p]
           then go to L06063
         a exchange c[p]
L06063:  c -> register 14
L06064:  register -> c 4
         c -> register 3
         register -> c 2
         c -> register 1
         register -> c 5
         c -> register 2
         m2 -> c
         c -> register 4
L06074:  register -> c 4
         c -> a[w]
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         c + 1 -> c[m]
         delayed rom @00
         jsb mp2-10
         jsb S06013
         register -> c 3
         c -> a[w]
         register -> c 4
         0 - c - 1 -> c[s]
         jsb S06222
         if c[w] = 0
           then go to L06265
         jsb S06014
         delayed rom @00
         jsb dv2-13
         jsb S06226
         c -> a[w]
         0 -> b[w]
         a exchange b[m]
         jsb S06013
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         c + 1 -> c[x]
         c + 1 -> c[x]
         0 - c - 1 -> c[s]
         jsb S06224
         if c[s] = 0
           then go to L06265
L06135:  register -> c 2
         c -> a[w]
         register -> c 1
         0 - c - 1 -> c[s]
         jsb S06222
         jsb S06013
         jsb S06015
         delayed rom @00
         jsb mp2-13
         register -> c 2
         jsb S06224
         jsb S06013
         jsb S06015
         m1 exchange c
         a - c -> c[s]
         if c[s] = 0
           then go to L06214
         jsb S06014
         0 -> c[w]
         c + 1 -> c[s]
         c - 1 -> c[w]
L06162:  delayed rom @00
         jsb mp1-10
         jsb S06226
         c -> register 5
         c -> a[w]
         register -> c 2
         a - c -> c[w]
         if c[w] # 0
           then go to L06212
         jsb S06015
         0 -> c[w]
         p <- 12
         load constant 3
         delayed rom @00
         jsb dv1-10
         register -> c 2
         jsb S06224
         jsb S06226
         c -> register 5
         c -> a[w]
         register -> c 2
         a - c -> c[w]
         if c[w] = 0
           then go to L06411
L06212:  register -> c 5
         go to L06253

L06214:  jsb S06014
         0 -> c[w]
         p <- 12
         load constant 1
         c + 1 -> c[m]
         if n/c go to L06162
S06222:  delayed rom @00
         go to ad2-10

S06224:  delayed rom @00
         go to ad1-10

S06226:  delayed rom @03
         go to S01572

L06230:  register -> c 3
         if c[w] = 0
           then go to L06243
         register -> c 14
         p <- 3
         if c[p] = 0
           then go to L06406
         c - 1 -> c[p]
         c -> register 14
         delayed rom @17
         go to L07535

L06243:  m2 -> c
         c -> register 3
         go to L06074

L06246:  m2 -> c
         c -> register 4
L06250:  0 -> c[w]
         c -> register 3
         register -> c 1
L06253:  c -> register 5
         jsb S06260
L06255:  1 -> s 4
         delayed rom @04
         go to L02162

S06260:  m2 exchange c
         register -> c 14
         b exchange c[x]
         0 -> a[x]
         return

L06265:  0 -> a[w]
         a + 1 -> a[x]
         a + 1 -> a[x]
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         b exchange c[w]
         jsb S06013
         go to L06135

L06276:  if c[m] # 0
           then go to L06305
         a exchange c[s]
         0 - c - 1 -> c[xs]
L06302:  c + 1 -> c[x]
         c + 1 -> c[p]
         if n/c go to L06325
L06305:  if a[s] # 0
           then go to L06314
         if c[s] # 0
           then go to L06316
L06311:  c + 1 -> c[m]
         if n/c go to L06325
         go to L06302

L06314:  if c[s] # 0
           then go to L06311
L06316:  c - 1 -> c[p]
         if c[m] = 0
           then go to L06323
         c + 1 -> c[p]
         if n/c go to L06324
L06323:  c - 1 -> c[x]
L06324:  c - 1 -> c[m]
L06325:  jsb S06226
         c -> register 5
         c -> a[w]
         register -> c 1
         a - c -> c[w]
         if c[w] = 0
           then go to L06371
L06334:  register -> c 3
         m2 exchange c
         register -> c 5
         c -> a[w]
         register -> c 1
         a - c -> c[w]
         if c[w] # 0
           then go to L06346
         if 0 = s 0
           then go to L06354
L06346:  register -> c 5
         jsb S06260
         a + 1 -> a[x]
         if n/c go to L06255
L06352:  if c[w] = 0
           then go to L06364
L06354:  m2 -> c
         c -> a[w]
         register -> c 4
         a - c -> c[s]
         if c[s] # 0
           then go to L06036
         delayed rom @13
         go to L05567

L06364:  m2 -> c
         c -> stack
         register -> c 5
         c -> stack
         go to L06376

L06371:  m2 -> c
         c -> stack
         register -> c 1
         c -> stack
         register -> c 2
L06376:  m2 exchange c
         nop
L06400:  jsb S06433
         if c[w] # 0
           then go to L06775
         0 -> s 2
         0 -> s 1
         go to L06721

L06406:  register -> c 4
         c -> stack
         register -> c 1
L06411:  c -> stack
         register -> c 2
         m2 exchange c
         jsb S06433
         if c[w] # 0
           then go to L07224
         if s 2 = 1
           then go to L07224
         p <- 6
         go to L06562

L06423:  m2 -> c
         delayed rom @03
         jsb S01572
         m2 exchange c
         if p # 10
           then go to L06400
         0 -> s 2
         go to L06400

S06433:  0 -> b[w]
         0 -> s 9
         p <- 6
         register -> c 14
         b exchange c[wp]
         c -> a[w]
         register -> c 15
         delayed rom @04
         jsb S02230
         p <- 1
         c - 1 -> c[p]
         if n/c go to L06451
         0 -> c[p]
         0 -> s 2
L06451:  c -> register 15
         a exchange c[w]
         p <- 9
         b exchange c[wp]
         c -> register 14
         register -> c 15
         return

S06460:  rom checksum

L06461:  decimal
         0 -> c[x]
         c -> data address
         register -> c 15
         delayed rom @16
         jsb S07263
         c -> a[w]
         if c[s] # 0
           then go to L06520
         if c[x] = 0
           then go to L06515
         0 -> c[w]
         p <- 13
         load constant 10
         load constant 1
         load constant 2
         a - 1 -> a[x]
         if a[x] # 0
           then go to L06737
         if a >= c[m]
           then go to L06737
         binary
         a exchange c[w]
         p <- 11
         if c[p] = 0
           then go to L06514
         a + 1 -> a[s]
L06514:  if n/c go to L06516
L06515:  shift left a[w]
L06516:  rotate left a
         go to L06764

L06520:  0 -> c[s]
         shift left a[w]
         if c[x] = 0
           then go to L06534
         rotate left a
         c - 1 -> c[x]
         if c[x] = 0
           then go to L06534
         rotate left a
         c - 1 -> c[x]
         if c[x] # 0
           then go to L06737
L06534:  rotate left a
         1 -> s 7
         go to L06766

         nop
L06540:  0 -> c[x]
         p <- 0
         load constant 5
         a exchange c[x]
         0 -> c[x]
         p <- 1
         load constant 1
         c -> data address
         register -> c 15
         if c[x] = 0
           then go to L06556
         0 -> c[xs]
         if a >= c[x]
           then go to L06561
L06556:  m2 -> c
         decimal
         return

L06561:  p <- 2
L06562:  delayed rom @04
         go to L02004

L06564:  jsb S06716
L06565:  delayed rom @03
         jsb S01572
         if p # 10
           then go to L06720
         p <- 1
         go to L06562

L06573:  if c[xs] # 0
           then go to L06635
         delayed rom @16
         jsb S07263
         c -> a[w]
         m2 -> c
         a - c -> a[w]
         if c[s] # 0
           then go to L06612
         if a[w] # 0
           then go to L06630
         delayed rom @03
         jsb xft100		; factorial
L06610:  delayed rom @04
         go to L02002

L06612:  if a[w] # 0
           then go to L06621
L06614:  p <- 12
         0 -> c[wp]
         c + 1 -> c[p]
         c + 1 -> c[xs]
         if n/c go to L06610
L06621:  if c[x] = 0
           then go to L06635
         c - 1 -> c[x]
         if c[x] = 0
           then go to L06635
         0 -> c[w]
         go to L06610

L06630:  if c[x] = 0
           then go to L06635
         c - 1 -> c[x]
         if c[x] # 0
           then go to L06614
L06635:  delayed rom @17
         jsb S07700
         c -> a[w]
         m2 -> c
         jsb S06716
         delayed rom @00
         jsb addone
         delayed rom @01
         jsb S00470
         delayed rom @01
         jsb S00535
         delayed rom @00
         jsb mp2-13
         0 -> c[w]
         load constant 1
         load constant 2
         c + 1 -> c[x]
         delayed rom @00
         jsb mp1-10
         delayed rom @01
         jsb S00470
         0 -> c[w]
         p <- 12
         c + 1 -> c[x]
         load constant 5
         load constant 5
         delayed rom @00
         jsb ad1-10
         delayed rom @17
         jsb S07664
         load constant 4
         load constant 9
         delayed rom @00
         jsb x/y13
         delayed rom @17
         jsb S07725
         load constant 3
         load constant 0
         load constant 3
         load constant 4
         load constant 8
         delayed rom @17
         go to L07730

L06710:  delayed rom @00
         jsb mp2-10
         go to L06565

L06713:  delayed rom @00
         jsb dv2-10
         go to L06565

S06716:  delayed rom @00
         go to ad2-10

L06720:  c -> data
L06721:  m2 -> c
L06722:  delayed rom @04
         go to L02000

L06724:  delayed rom @10
         jsb S04232
         c + c -> c[w]
         c + 1 -> c[m]
         0 -> c[x]
         go to L06722

L06732:  delayed rom @17
         go to L07420

L06734:  1 -> s 13
L06735:  delayed rom @04
         go to L02034

L06737:  p <- 4
         go to L06562

L06741:  stack -> a
         delayed rom @00
         jsb dv2-10
         go to L06610

L06745:  bank toggle

         delayed rom @04
         go to L02111

         nop
L06751:  bank toggle

         go to L06735

L06753:  bank toggle

         go to L06734

L06755:  bank toggle

         delayed rom @14
         go to L06016

L06760:  bank toggle

         go to L06461

L06762:  bank toggle

         go to L06564

L06764:  bank toggle

         go to L06710

L06766:  bank toggle

         go to L06713

         bank toggle

         go to L06732

S06772:  bank toggle

         return

         nop
L06775:  bank toggle

         go to L06724

         bank toggle

         jsb S07230
         m2 -> c
         decimal
         shift left a[x]
         a -> rom address

L07005:  jsb S07041
         0 -> a[x]
         delayed rom @00
         jsb shf10
         c - 1 -> c[x]
L07012:  delayed rom @04
         go to L02002

         go to L07047

         go to L07152

         delayed rom @17
         go to L07417

L07020:  y -> a
L07021:  0 - c - 1 -> c[s]
         jsb S07345
         if c[s] # 0
           then go to L06755
         go to L07224

L07026:  if c[s] # 0
           then go to L06755
         go to L07141

L07031:  delayed rom @02
         jsb S01041
         go to L07012

         go to L07372

         go to L07031

         delayed rom @01
         jsb S00540
         go to L07012

S07041:  c -> a[w]
         p <- 12
         if c[xs] = 0
           then go to L07300
         c + 1 -> c[x]
         return

L07047:  if s 9 = 1
           then go to L07052
         c -> stack
L07052:  data -> c
         go to L07362

         go to L07331

         go to L07200

         delayed rom @01
         jsb S00540
         0 -> c[w]
         m1 exchange c
         m1 -> c
         delayed rom @03
         jsb S01651
         b exchange c[w]
         delayed rom @00
         jsb dv2-13
         go to L07012

L07071:  jsb S07160
         delayed rom @10
         go to L04005

         go to L07226

         go to L07321

         delayed rom @00
         jsb sqr10
         go to L07012

L07101:  y -> a
         a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         jsb S07345
         a exchange c[w]
         go to L07121

S07110:  delayed rom @15
         go to L06540

L07112:  delayed rom @15
         go to L06753

         go to L07250

         go to L07071

         jsb S07160
         delayed rom @11
         go to L04462

L07121:  y -> a
         a exchange c[w]
         c - 1 -> c[x]
         c - 1 -> c[x]
         delayed rom @00
         jsb dv1-10
         go to L07012

L07130:  1 -> s 6
L07131:  jsb S07110
         delayed rom @12
         go to L05241

         go to L07130

         go to L07351

         go to L07232

L07137:  y -> a
         a - c -> c[w]
L07141:  if c[w] = 0
           then go to L06755
         go to L07224

L07144:  y -> a
L07145:  0 - c - 1 -> c[s]
         jsb S07345
L07147:  if c[s] = 0
           then go to L06755
         go to L07224

L07152:  delayed rom @15
         go to L06751

         go to L07247

         1 -> s 8
         delayed rom @12
         go to L05115

S07160:  delayed rom @17
         jsb S07411
         if c[s] = 0
           then go to L07171
         1 -> s 14
         c - 1 -> c[s]
         if c[s] # 0
           then go to L07171
         1 -> s 12
L07171:  jsb S07230
         m2 -> c
         return

         go to L07101

         go to L07242

         1 -> s 10
         go to L07216

L07200:  0 -> a[w]
         delayed rom @03
         jsb S01651
         m2 -> c
         delayed rom @00
         jsb mp1-10
         delayed rom @02
         jsb S01016
         go to L07012

L07211:  jsb S07263
         go to L07012

         nop
         go to L07311

         go to L07241

L07216:  1 -> s 6
         go to L07236

L07220:  y -> a
         a - c -> c[w]
L07222:  if c[w] # 0
           then go to L06755
L07224:  delayed rom @04
         go to L02024

L07226:  delayed rom @02
         go to L01331

S07230:  delayed rom @17
         go to S07402

L07232:  delayed rom @12
         go to L05225

         go to L07131

         go to L07243

L07236:  jsb S07160
         delayed rom @11
         go to L04466

L07241:  1 -> s 10
L07242:  1 -> s 6
L07243:  1 -> s 13
         jsb S07160
         delayed rom @10
         go to L04065

L07247:  1 -> s 6
L07250:  1 -> s 4
         go to L07131

L07252:  down rotate
         go to L07362

         go to L07323

         go to L07147

         go to L07020

         0 - c - 1 -> c[s]
L07260:  stack -> a
         jsb S07345
         go to L07012

S07263:  jsb S07041
         0 -> c[wp]
         if c[m] = 0
           then go to L07270
         a exchange c[x]
L07270:  return

L07271:  jsb S07110
         delayed rom @13
         go to L05477

         go to L07211

         go to L07026

         go to L07144

         go to L07260

L07300:  c + 1 -> c[x]
L07301:  if c[x] = 0
           then go to L07310
         c - 1 -> c[x]
         shift left a[m]
         p - 1 -> p
         if a[m] # 0
           then go to L07301
L07310:  return

L07311:  jsb S07110
         delayed rom @03
         go to L01545

         go to L07005

         go to L07141

         go to L07137

         stack -> a
         go to L07326

L07321:  c -> a[w]
         go to L07326

L07323:  y -> a
         c - 1 -> c[x]
         c - 1 -> c[x]
L07326:  delayed rom @00
         jsb mp2-10
         go to L07012

L07331:  delayed rom @00
         jsb 1/x10
         go to L07012

         go to L07343

         go to L07222

         go to L07220

         if c[m] # 0
           then go to L06741
         delayed rom @04
         go to L02003

L07343:  0 -> c[s]
         go to L07012

S07345:  delayed rom @00
         go to ad2-10

L07347:  delayed rom @15
         go to L06760

L07351:  delayed rom @12
         go to L05214

         nop
         go to L07347

         go to L07252

         go to L07364

         stack -> a
         c -> stack
         a exchange c[w]
L07362:  delayed rom @04
         go to L02000

L07364:  0 -> c[w]
         c -> data address
         register -> c 15
         m2 exchange c
         delayed rom @15
         go to L06720

L07372:  delayed rom @15
         go to L06573

         go to L07112

         1 -> s 4
         go to L07271

         delayed rom @15
         go to L06762

S07401:  select rom @00 (x-ad1-10)

S07402:  0 -> c[w]
         p <- 1
         c + 1 -> c[p]
         c + 1 -> c[p]
         c -> data address
         data -> c
         return

S07411:  0 -> c[x]
         p <- 1
         load constant 1
S07414:  c -> data address
         register -> c 15
         return

L07417:  1 -> s 4
L07420:  decimal
         0 -> c[w]
         jsb S07414
         jsb S07662
         jsb S07510
         c -> register 6
         0 -> a[s]
         a exchange c[x]
L07430:  if c[xs] = 0
           then go to L07436
         shift right a[m]
         c + 1 -> c[x]
         if n/c go to L07430
         shift left a[m]
L07436:  0 -> c[x]
         a exchange c[ms]
         c -> a[w]
         c - 1 -> c[x]
         c -> register 7
         p <- 7
         0 -> a[wp]
         jsb S07514
         jsb S07662
         jsb S07510
         c -> register 8
         0 -> a[x]
         jsb S07515
         if c[m] # 0
           then go to L07457
         0 -> c[w]
         c + 1 -> c[p]
L07457:  if s 4 = 1
           then go to L07462
         0 - c - 1 -> c[s]
L07462:  a exchange c[w]
         register -> c 6
         jsb S07527
         c -> register 6
         c -> a[w]
         register -> c 7
         a exchange c[s]
         c -> a[s]
         jsb S07527
         a exchange c[w]
         0 -> c[x]
         c -> data address
         a exchange c[w]
         c -> register 15
         jsb S07402
         register -> c 8
         c -> a[w]
         register -> c 6
         if s 4 = 1
           then go to L07021
         delayed rom @16
         go to L07145

S07510:  b exchange c[w]
         jsb S07402
         b exchange c[w]
         return

S07514:  a + 1 -> a[x]
S07515:  a + 1 -> a[x]
         p <- 12
L07517:  if a[p] # 0
           then go to L07524
         shift left a[m]
         a - 1 -> a[x]
         if n/c go to L07517
L07524:  a exchange c[w]
         return

S07526:  0 - c - 1 -> c[s]
S07527:  delayed rom @00
         go to ad2-10

S07531:  delayed rom @01
         go to S00535

S07533:  delayed rom @03
         go to S01572

L07535:  register -> c 5
         c -> a[w]
         register -> c 2
         jsb S07526
         jsb S07641
         m2 -> c
         c -> a[w]
         register -> c 4
         jsb S07526
         jsb S07531
         jsb S07656
         jsb S07641
         register -> c 3
         c -> a[w]
         register -> c 4
         jsb S07526
         jsb S07641
         register -> c 1
         c -> a[w]
         register -> c 2
         jsb S07652
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S07646
         jsb S07644
         delayed rom @01
         jsb S00420
         register -> c 5
         c -> a[w]
         register -> c 1
         jsb S07652
         0 -> b[s]
         if b[w] = 0
           then go to L07606
         jsb S07646
         jsb S07654
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S07650
         jsb S07644
         go to L07607

L07606:  jsb S07650
L07607:  jsb S07624
         if c[w] # 0
           then go to L07616
         jsb S07650
         jsb S07624
         if c[w] = 0
           then go to L06406
L07616:  register -> c 5
         a - c -> c[w]
         if c[w] = 0
           then go to L06406
         delayed rom @14
         go to L06250

S07624:  0 -> c[w]
         p <- 12
         c - 1 -> c[x]
         load constant 5
         jsb S07660
         register -> c 2
         jsb S07401
         jsb S07533
         c -> register 1
         c -> a[w]
         register -> c 2
         a - c -> c[w]
         return

S07641:  delayed rom @01
         go to S00470

S07643:  jsb S07531
S07644:  delayed rom @00
         go to ad2-13

S07646:  delayed rom @01
         go to S00515

S07650:  delayed rom @01
         go to S00532

S07652:  jsb S07526
         jsb S07531
S07654:  delayed rom @00
         go to dv2-13

S07656:  delayed rom @00
         go to x/y13

S07660:  delayed rom @00
         go to mp1-10

S07662:  delayed rom @16
         go to S07263

S07664:  0 -> c[w]
         0 - c - 1 -> c[s]
         c + 1 -> c[x]
         c + 1 -> c[x]
         m1 exchange c
         0 -> c[w]
         p <- 10
         load constant 5
         load constant 9
         load constant 2
         p <- 12
         return

S07700:  m2 -> c
         0 - c - 1 -> c[s]
         c -> a[w]
         0 -> c[w]
         p <- 12
         load constant 3
         jsb S07527
         if c[s] = 0
           then go to L07713
         delayed rom @00
         jsb subone
L07713:  delayed rom @16
         jsb S07041
         0 -> c[wp]
         if c[m] = 0
           then go to L07721
         a exchange c[x]
L07721:  if c[s] = 0
           then go to L07724
         0 -> c[w]
L07724:  return

S07725:  0 -> c[w]
         c + 1 -> c[x]
         return

L07730:  jsb S07401
         jsb S07643
         jsb S07664
         load constant 5
         load constant 3
         jsb S07656
         jsb S07725
         load constant 6
         load constant 5
         load constant 3
         load constant 5
         load constant 1
         jsb S07401
         jsb S07641
         jsb S07646
         0 -> c[w]
         p <- 12
         load constant 7
         jsb S07660
         delayed rom @01
         jsb S00436
         jsb S07644
         0 -> c[w]
         0 - c - 1 -> c[s]
         m1 exchange c
         0 -> c[w]
         load constant 8
         load constant 4
         load constant 8
         jsb S07656
         0 -> c[w]
         load constant 4
         c - 1 -> c[x]
         jsb S07401
         jsb S07643
         jsb S07646
         jsb S07654
         delayed rom @05
         go to L02716

         .dw @0667			; CRC, bank 0 quad 3 (@06000..@07777)

	 .bank 1
	 .org @2000

L12000:  go to L12014

L12001:  bank toggle

L12002:  go to L12167

         p <- 0
L12004:  bank toggle

L12005:  go to L12173

L12006:  c -> a[w]
         delayed rom @16
         jsb S17252
         m2 exchange c
         c -> data
         a exchange c[w]
L12014:  delayed rom @13
         jsb S15711
         m2 exchange c
         if p # 10
           then go to L12023
L12021:  0 -> s 1
         0 -> s 2
L12023:  0 -> s 9
L12024:  0 -> s 11
L12025:  a exchange b[w]
         go to L12033

         bank toggle

         go to L12033

         bank toggle

         go to L12200

L12033:  jsb S12106
         a exchange b[w]
L12035:  jsb S12365
         if s 2 = 1
           then go to L13415
         0 -> s 1
         1 -> s 12
         0 -> s 3
         if 0 = s 3
           then go to L12177
         delayed rom @14
         jsb S16370
         0 -> s 4
         p <- 12
         0 -> a[x]
         0 -> c[x]
L12053:  display off
         display toggle
L12055:  0 -> s 15
         if s 15 = 1
           then go to L12055
L12060:  0 -> s 1
         0 -> s 3
         if 0 = s 3
           then go to L12070
         if s 12 = 1
           then go to L12072
         1 -> s 12
         go to L12024

L12070:  if s 12 = 1
           then go to L12176
L12072:  if s 15 = 1
           then go to L12401
         go to L12060

L12075:  b exchange c[w]
         0 -> a[w]
         jsb S12373
         jsb S12112
         delayed rom @14
         go to L16000

L12103:  1 -> s 9
         m2 exchange c
         go to L12024

S12106:  if s 2 = 1
           then go to S12112
         if 0 = s 1
           then go to L12136
S12112:  jsb S12157
         c -> a[x]
         jsb S12162
         a - c -> a[x]
         if a[x] # 0
           then go to S12122
         0 -> c[x]
         go to L12135

S12122:  binary
         p <- 2
         if c[x] = 0
           then go to L12137
L12126:  c -> a[xs]
         load constant 7
         if a >= c[xs]
           then go to L12143
         a exchange c[xs]
         c + 1 -> c[xs]
L12134:  p <- 13
L12135:  c -> register 15
L12136:  return

L12137:  load constant 1
         load constant 1
         load constant 14
         go to L12134

L12143:  p <- 0
         if c[p] = 0
           then go to L12152
         c - 1 -> c[p]
         p <- 2
         load constant 1
         go to L12134

L12152:  p <- 2
         load constant 1
         load constant 0
         load constant 14
         go to L12134

S12157:  p <- 1
         load constant 1
         go to L12164

S12162:  p <- 1
         load constant 2
L12164:  c -> data address
         register -> c 15
         return

L12167:  delayed rom @07
         jsb S13445
         go to L12006

         p <- 4
L12173:  delayed rom @12
         jsb S15301
         go to L12024

L12176:  jsb S12365
L12177:  0 -> s 12
L12200:  jsb S12162
         jsb S12244
         if c[x] # 0
           then go to L12367
         0 -> b[w]
         a - 1 -> a[p]
         load constant 6
         b exchange c[w]
L12210:  0 -> a[x]
         0 -> c[x]
         p <- 12
         display off
         display toggle
         0 -> s 3
         if 0 = s 3
           then go to L12055
L12220:  0 -> s 15
         if s 15 = 1
           then go to L12220
         display off
         jsb S12234
         c -> a[w]
         m1 exchange c
         a exchange c[w]
         if s 6 = 1
           then go to L12035
         delayed rom @07
         go to L13441

S12234:  jsb S12162
         c -> data address
         a exchange c[x]
         data -> c
         a - 1 -> a[xs]
L12241:  a - 1 -> a[xs]
         if n/c go to L12362
         return

S12244:  a exchange c[w]
         m1 exchange c
         a exchange c[w]
         0 -> c[ms]
         0 -> a[w]
         if c[x] = 0
           then go to L12304
         p <- 12
         load constant 1
         load constant 0
         a + 1 -> a[p]
         load constant 4
         a exchange c[ms]
         decimal
L12262:  a + c -> a[ms]
         c - 1 -> c[xs]
         if n/c go to L12262
         p <- 10
         load constant 7
         p <- 0
L12270:  decimal
         a - c -> a[ms]
         c - 1 -> c[p]
         if n/c go to L12270
         p <- 1
         if c[p] # 0
           then go to L12304
         p <- 12
         load constant 1
         load constant 0
         load constant 5
         a + c -> a[ms]
L12304:  binary
         p <- 9
         a - 1 -> a[wp]
         return

L12310:  1 -> s 1
         jsb S12162
         0 -> s 3
         if s 3 = 1
           then go to L12317
L12315:  jsb S12112
         go to L12200

L12317:  if c[x] # 0
           then go to L12200
         0 -> s 11
L12322:  if c[w] = 0
           then go to L12315
         p <- 5
         if c[p] = 0
           then go to L12344
         delayed rom @16
         jsb S17257
         go to L12200

L12332:  0 -> s 3
         if s 3 = 1
           then go to L12000
         jsb S12157
         m1 exchange c
         jsb S12162
         if c[x] = 0
           then go to L12176
         delayed rom @14
         go to L16066

L12344:  jsb S12244
         a - 1 -> a[p]
         load constant 6
         b exchange c[ms]
         display off
         display toggle
L12352:  0 -> s 15
         if 0 = s 15
           then go to L13415
         go to L12352

L12356:  jsb S12112
L12357:  0 -> s 2
         0 -> s 11
         go to L12035

L12362:  shift right c[w]
         shift right c[w]
         go to L12241

S12365:  delayed rom @06
         go to S13216

L12367:  jsb S12234
         delayed rom @10
         jsb S14376
         go to L12210

S12373:  jsb S12157
         c -> a[w]
         0 -> c[x]
         p <- 2
         delayed rom @12
         go to L15366

L12401:  binary
         display off
         keys -> rom address

key_14:  if 0 = s 7			; key 14 (@061): f
           then go to L12411
         p <- 12
         0 -> a[x]
         jsb S12701
L12411:  jsb S12703
         1 -> s 7
         go to L12424

key_15:  p <- 12			; key 15 (@060): g
         0 -> a[x]
         jsb S12701
         1 -> s 14
         go to L12424

key_25:  p <- 9				; key 25 (@220): h
         jsb S12701
         0 -> a[x]
L12424:  a exchange c[x]
         0 -> s 4
         delayed rom @06
         go to L13040

L12430:  jsb S12435
         go to L12456

S12432:  p <- 13
S12433:  delayed rom @06
         go to S13305

S12435:  p <- 3
         go to S12433

key_13:  if s 7 = 1			; key 13 (@062): unshifted GSB, f-shifted ENG, g-shifted GRD, h-shifted LBL
           then go to L13055
         if s 14 = 1
           then go to L13070
         if p = 9
           then go to L13314
         jsb S12433
         p <- 5
         nop
         nop
L12451:  a + 1 -> a[x]
L12452:  a + 1 -> a[x]
L12453:  a + 1 -> a[x]
L12454:  a + 1 -> a[x]
L12455:  a + 1 -> a[x]
L12456:  a + 1 -> a[x]
         if n/c go to L12640

         go to key_15			; key 15 (@060): g

         go to key_14			; key 14 (@061): f

         go to key_13			; key 13 (@062): unshifted GSB, f-shifted ENG, g-shifted GRD, h-shifted LBL

         go to key_12x			; key 12 (@063): unshifted B,   f-shifted SCI, g-shifted RAD, h-shifted RTN

         nop				; key 11 (@064): unshifted A,   f-shifted FIX, g-shifted DEG, h-shifted DSP I
         nop
         delayed rom @06
         go to key_11

L12470:  jsb S12432
         go to L12721

key_43:  if s 7 = 1			; key 43 (@241): unshifted 8, f-shifted COS, g-shifted COS-1, h-shifted mean
           then go to L12476
         if p = 1
           then go to L13344
L12476:  a + 1 -> a[x]
         if n/c go to L12642

         go to key_74			; key 74 (@100): unshifted R/S, f-shifted Sigma+, g-shifted Sigma-, h-shifted PSE
         go to key_73			; key 73 (@101): unshifted .,   f-shifted solve,     h-shifted pi
         go to key_72			; key 72 (@012): unshifted 0,   f-shifted integrate, h-shifted LSTx

         if s 7 = 1			; key 71 (@013): unshifted divide, f-shifted x=y, g-shifted x=0, h-shifted F?
           then go to L12453
         if s 14 = 1
           then go to L12453
         if p = 9
           then go to L13032
         if s 6 = 1
           then go to L12610
         jsb S12735
         go to L12453

key_33:  if s 7 = 1			; key 33 (@161): unshfited EEX, f-shifted CLR REG,   h-shifted FRAC
           then go to L13141
         if p = 9
           then go to L12454
         p <- 1
         load constant 12
         go to L12575

key_12x: delayed rom @06		; key 12 (@063): unshifted B,   f-shifted SCI, g-shifted RAD, h-shifted RTN
         go to key_12

key_32:  if s 7 = 1			; key 32 (@162): unshifted CHS, f-shifted CLR PRGM,  h-shifted INT
           then go to L13605
         if p = 9
           then go to L12455
         p <- 1
         load constant 11
         go to L12575

L12535:  jsb S12435
         go to L12454

key_42:  a + 1 -> a[x]
L12540:  a + 1 -> a[x]			; key 54 (@140): unshifted 6, f-shifted ->H.MS, g-shfited ->H,     h-shifted L.R.
L12541:  a + 1 -> a[x]			; key 53 (@141): unshifted 5, f-shifted ->DEG,  g-shifted ->RAD,   h-shifted r
L12542:  if n/c go to L12711		; key 52 (@142): unshifted 4, f-shfited ->RECT, g-shifted ->POLAR, h-shifted lin est

         if s 7 = 1			; key 51 (@143): unshifted add, f-shifted x>y, g-shifted x>0, h-shifted SF
           then go to L12455
         if s 14 = 1
           then go to L12455
         if p = 9
           then go to L13024
         if s 6 = 1
           then go to L12705
         jsb S12735
         go to L12455

L12555:  jsb S12735
         0 -> s 4
         go to L12747

         go to key_34			; key 34 (@160): unshfited CLx, f-shifted CLR Sigma, h-shifted ABS
         go to key_33			; key 33 (@161): unshfited EEX, f-shifted CLR REG,   h-shifted FRAC
         go to key_32			; key 32 (@162): unshifted CHS, f-shifted CLR PRGM,  h-shifted INT

         if s 14 = 1			; key 31 (@163): unshfited ENTER^, f-shifted CLR PREFIX, g-shifted MEM, h-shifted MANT
           then go to L13644
         if s 7 = 1
           then go to L13575
         if p = 9
           then go to L13562
         if s 6 = 1
           then go to L13355
         p <- 1
         load constant 10
L12575:  load constant 11
         delayed rom @06
         go to L13014

key_74:  if s 7 = 1			; key 74 (@100): unshifted R/S, f-shifted Sigma+, g-shifted Sigma-, h-shifted PSE
           then go to L13267
         if s 14 = 1
           then go to L12451
         if p = 9
           then go to L12451
         jsb S12735
         go to L12451

L12610:  jsb S12435
         go to L12453

key_44:  if s 7 = 1			; key 44 (@240): unshifted 9, f-shifted TAN, g-shifted TAN-1, h-shifted std dev
           then go to L12616
         if p = 1
           then go to L13341
L12616:  a + 1 -> a[x]
         if n/c go to key_43

         go to key_25			; key 25 (@220): h
         go to key_24			; key 24 (@221): unshifted RCL,  f-shifted (i),  g-shifted ISG, h-shifted SST
         go to key_23			; key 23 (@222): unshifted STO,  f-shifted I,    g-shifted DSE, h-shifted BST
         go to key_22			; key 22 (@223): unshifted GTO,  f-shifted Rup,  g-shifted Rdn, h-shfited DEL

         nop				; key 21 (@224): unshifted x<>y, f-shifted x<>I,                h-shfited x<>(i)
         nop
         0 -> a[x]
         if s 7 = 1
           then go to L12452
         if p = 9
           then go to L12452
         jsb S12735
         go to L12452

L12635:  jsb S12433
         p <- 2
         go to L12540

L12640:  go to key_44			; key 44 (@240): unshifted 9, f-shifted TAN, g-shifted TAN-1, h-shifted std dev
L12641:  go to key_43			; key 43 (@241): unshifted 8, f-shifted COS, g-shifted COS-1, h-shifted mean
L12642:  go to key_42			; key 42 (@242): unshifted 7, f-shifted SIN, g-shfited SIN-1, h-shfited Delta%

         if s 7 = 1			; key 41 (@243): unshifted subtract, f-shifted x<=y, g-shfited x<0, h-shifted %
           then go to L12456
         if s 14 = 1
           then go to L12456
         if p = 9
           then go to L12456
         if s 6 = 1
           then go to L12430
         jsb S12735
         go to L12456

key_73:  if s 14 = 1			; key 73 (@101): unshifted .,   f-shifted solve,     h-shifted pi
           then go to L12667
         if p = 2
           then go to L13120
         if s 10 = 1
           then go to L13124
         if s 7 = 1
           then go to L13132
         if p = 9
           then go to L13136
L12667:  p <- 1
         load constant 4
         go to L12575

key_34:  if s 7 = 1			; key 34 (@160): unshfited CLx, f-shifted CLR Sigma, h-shifted ABS
           then go to L13145
         if p = 9
           then go to L12453
         p <- 1
         load constant 13
         go to L12575

S12701:  delayed rom @06
         go to L13307

S12703:  delayed rom @06
         go to L13311

L12705:  jsb S12435
         go to L12455

L12707:  delayed rom @06		; key 62 (@322): unshifted 1, f-shifted ln,   g-shfited e^x,  h-shifted x!
         go to L13060

L12711:  if s 7 = 1
           then go to L12717
         if p = 13
           then go to L13772
         if p = 4
           then go to L13772
L12717:  a + 1 -> a[x]
L12720:  a + 1 -> a[x]			; key 64 (@320): unshifted 3, f-shifted sqrt, g-shifted x^2,  h-shifted y^x
L12721:  a + 1 -> a[x]			; key 63 (@321): unshifted 2, f-shifted log,  g-shifted 10^x, h-shifted 1/x
L12722:  if n/c go to L12707		; key 62 (@322): unshifted 1, f-shifted ln,   g-shfited e^x,  h-shifted x!

         if s 7 = 1			; key 61 (@323): multiply, f-shifted x#y, g-shifted x#0, h-shfited CF
           then go to L12454
         if s 14 = 1
           then go to L12454
         if p = 9
           then go to L13027
         if s 6 = 1
           then go to L12535
         jsb S12735
         go to L12454

S12735:  0 -> s 7
         0 -> s 14
         0 -> s 4
         p <- 12
         0 -> a[x]
         return

key_72:  if s 7 = 1			; key 72 (@012): unshifted 0,   f-shifted integrate, h-shifted LSTx
           then go to L12470
         if s 14 = 1
           then go to L12555
L12747:  delayed rom @06
         go to L13061

key_24:  if s 7 = 1			; key 24 (@221): unshifted RCL,  f-shifted (i),  g-shifted ISG, h-shifted SST
           then go to L13150
         if s 14 = 1
           then go to L13204
         if p = 3
           then go to L13151
         if p = 9
           then go to L12310
         go to L12635

key_23:  if s 7 = 1			; key 23 (@222): unshifted STO,  f-shifted I,    g-shifted DSE, h-shifted BST
           then go to L13162
         if s 14 = 1
           then go to L13210
         if p = 9
           then go to L13372
         jsb S12433
         p <- 2
         1 -> s 6
         go to L12641

key_22:  if s 14 = 1			; key 22 (@223): unshifted GTO,  f-shifted Rup,  g-shifted Rdn, h-shfited DEL
           then go to L12452
         if s 7 = 1
           then go to L13213
         if p = 9
           then go to L13324
         jsb S13305
         p <- 5
         1 -> s 10
         delayed rom @05
         go to L12452

L13007:  p <- 1
         load constant 4
         load constant 8
         go to L13014

L13013:  a exchange c[x]
L13014:  jsb S13221
         if p # 6
           then go to L13441
         go to L13317

L13020:  p <- 1
         load constant 4
         load constant 9
         go to L13014

L13024:  p <- 1
         load constant 1
         go to L13034

L13027:  p <- 1
         load constant 2
         go to L13034

L13032:  p <- 1
         load constant 3
L13034:  load constant 8
         a exchange c[x]
         p <- 4
L13037:  1 -> s 4
L13040:  0 -> a[xs]
L13041:  delayed rom @04
         go to L12053

L13043:  shift left a[x]
         go to L13037

L13045:  jsb S13304
         delayed rom @05
         go to L12541

S13050:  p <- 1
         go to S13305

L13052:  jsb S13050
         delayed rom @05
         go to L12542

L13055:  jsb S13050
L13056:  delayed rom @05
         go to L12720

L13060:  a + 1 -> a[x]		; key 62 (@322): unshifted 1, f-shifted ln,   g-shfited e^x,  h-shifted x!
L13061:  if p # 6
           then go to L13070
         if c[x] = 0
           then go to L13014
         c - 1 -> c[x]
         shift left a[x]
         go to L13041

L13070:  if a[xs] # 0
           then go to L13043
         if s 4 = 1
           then go to L13013
         a + 1 -> a[x]
         shift left a[x]
         if s 7 = 1
           then go to L13110
         if s 14 = 1
           then go to L13112
L13102:  p + 1 -> p
         a - 1 -> a[x]
         if p # 13
           then go to L13102
         a exchange c[x]
         go to L13014

L13110:  p <- 11
         go to L13102

L13112:  p <- 10
         go to L13102

L13114:  p <- 1
         load constant 2
L13116:  load constant 7
         go to L13014

L13120:  p <- 1
         a + 1 -> a[p]
         p <- 0
         go to L13040

L13124:  jsb S13304
         0 -> a[x]
         0 -> c[x]
         load constant 2
         p <- 6
         go to L13040

L13132:  jsb S13305
         p <- 13
         delayed rom @05
         go to L12722

L13136:  p <- 1
         load constant 4
         go to L13160

L13141:  p <- 1
         load constant 1
         load constant 6
         go to L13014

L13145:  p <- 1
         load constant 1
         go to L13116

L13150:  a exchange c[x]
L13151:  1 -> s 4
         if p = 2
           then go to L12456
         if p = 3
           then go to L12456
         p <- 1
         load constant 6
L13160:  load constant 10
         go to L13014

L13162:  a exchange c[x]
         1 -> s 4
         if s 6 = 1
           then go to L12455
         if s 10 = 1
           then go to L13176
         if p = 5
           then go to L13201
         p <- 1
         load constant 6
L13174:  load constant 11
         go to L13014

L13176:  p <- 1
         load constant 9
         go to L13174

L13201:  p <- 1
         load constant 7
         go to L13174

L13204:  p <- 1
         load constant 0
         load constant 14
         go to L13014

L13210:  p <- 1
         load constant 7
         go to L13160

L13213:  p <- 1
         load constant 5
         go to L13174

S13216:  0 -> s 8
         0 -> s 12
         0 -> s 13
S13221:  0 -> s 4
         go to L13307

key_11:  if s 7 = 1			; key 11 (@064): unshifted A,   f-shifted FIX, g-shifted DEG, h-shifted DSP I
           then go to L13045
         if s 14 = 1
           then go to L13007
         if p = 9
           then go to L13276
         if p = 13
           then go to L13302
         if p = 7
           then go to L12456
         if p = 13
           then go to L12456
         if p = 5
           then go to L12456
L13241:  p <- 1
         load constant 15
         p <- 1
         a exchange c[p]
         1 -> s 4
         p <- 5
         delayed rom @05
         go to L12456

key_12:  if s 7 = 1		; key 12 (@063): unshifted B,   f-shifted SCI, g-shifted RAD, h-shifted RTN
           then go to L13052
         if s 14 = 1
           then go to L13020
         if p = 9
           then go to L13114
         if p = 13
           then go to L13301
         if p = 7
           then go to L12455
         if p = 5
           then go to L12455
         a + 1 -> a[x]
         if n/c go to L13241
L13267:  if p # 2
           then go to L12451
         if s 6 = 1
           then go to L12451
         p <- 1
         load constant 5
         go to L13160

L13276:  p <- 1
         load constant 9
         go to L13160

L13301:  a + 1 -> a[x]
L13302:  a + 1 -> a[x]
         if n/c go to L13056
S13304:  p <- 0
S13305:  0 -> a[x]
         a + 1 -> a[xs]
L13307:  0 -> s 6
         0 -> s 10
L13311:  0 -> s 7
         0 -> s 14
         return

L13314:  jsb S13305
         p <- 7
         go to L13061

L13317:  delayed rom @14
         go to L16252

L13321:  p <- 4
         delayed rom @04
         go to L12173

L13324:  0 -> s 3
         if s 3 = 1
           then go to L12024
         delayed rom @04
         jsb S12162
         if c[x] = 0
           then go to L12176
         delayed rom @04
         go to L12332

L13335:  c -> register 15
         0 -> s 11
         delayed rom @04
         go to L12035

L13341:  p <- 0
         load constant 9
         go to L13346

L13344:  p <- 0
         load constant 8
L13346:  p <- 1
         0 -> s 3
         if 0 = s 3
           then go to L12642
         p <- 0
         delayed rom @16
         go to L17327

L13355:  bank toggle

         nop
         jsb S13377
L13360:  bank toggle

         delayed rom @13
         jsb S15776
         bank toggle

         delayed rom @15
         jsb S16744
         bank toggle

         delayed rom @12
         jsb S15330
         go to L13360

L13372:  delayed rom @12
         go to L15031

         p <- 2
         delayed rom @04
         go to L12173

S13377:  rom checksum

L13400:  0 -> s 11
         display off
         delayed rom @14
         jsb S16370
         display toggle
L13405:  0 -> c[x]
         p <- 2
         load constant 6
L13410:  c - 1 -> c[x]
         if n/c go to L13410
         display off
         delayed rom @04
         go to L12024

L13415:  jsb S13755
         if c[x] = 0
           then go to L13422
         if c[xs] # 0
           then go to L13424
L13422:  delayed rom @16
         go to L17224

L13424:  if s 11 = 1
           then go to L13430
         if s 15 = 1
           then go to L12357
L13430:  a exchange b[w]
         display toggle
         delayed rom @04
         jsb S12234
         a exchange b[w]
L13435:  delayed rom @06
         jsb S13216
         delayed rom @16
         go to L17340

L13441:  0 -> s 3
         if 0 = s 3
           then go to L12075
         go to L13435

S13445:  display off
         binary
         clear status
         clear regs
         m1 exchange c
         b -> c[w]
         m2 exchange c
         b -> c[w]
         p <- 1
         load constant 2
         c -> data address
         a exchange c[w]
         c -> data
         c -> register 14
         c -> register 15
         p <- 1
         load constant 1
         load constant 15
         c -> data address
         data -> c
         0 -> c[s]
         p <- 4
         c -> a[wp]
         p <- 9
         0 -> c[wp]
         p <- 4
         a exchange c[w]
         c -> a[wp]
         p <- 12
         load constant 14
         load constant 10
         load constant 14
         a - c -> a[w]
         if a[w] # 0
           then go to L13521
         c -> register 15
         c -> a[w]
         shift right a[w]
         shift right a[w]
         shift right a[w]
         shift right a[w]
         f exchange a[x]
         0 -> c[w]
         return

L13521:  p <- 4
         load constant 4
         0 -> c[wp]
         c -> data
         p <- 0
         load constant 4
         a exchange c[x]
         f exchange a[x]
         0 -> c[w]
         p <- 1
         load constant 1
         load constant 14
L13535:  0 -> a[w]
         c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
         c - 1 -> c[x]
         if n/c go to L13535
         0 -> c[w]
         c - 1 -> c[w]
         p <- 12
         load constant 13
         load constant 10
         p <- 9
         load constant 14
         load constant 10
         load constant 10
         load constant 12
         load constant 10
         a exchange c[w]
         delayed rom @12
         go to S15330

L13562:  0 -> s 3
         if 0 = s 3
           then go to L13575
         0 -> b[w]
         m2 -> c
L13567:  c -> a[w]
         display toggle
L13571:  0 -> s 15
         if s 15 = 1
           then go to L13571
         go to L13405

L13575:  p <- 12
         0 -> s 7
         0 -> s 6
         0 -> s 8
         0 -> s 4
         0 -> a[x]
         delayed rom @04
         go to L12053

L13605:  jsb S13755
         0 -> c[w]
         c -> register 14
         0 -> s 3
         c -> register 15
         if s 3 = 1
           then go to L13636
         jsb S13775
         0 -> a[w]
         p <- 0
         if c[x] = 0
           then go to L13636
L13621:  c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
         c + 1 -> c[p]
         c + 1 -> c[p]
         c - 1 -> c[p]
         if n/c go to L13621
         p <- 1
         if c[p] = 0
           then go to L13641
         0 -> c[x]
         c -> register 15
L13636:  m2 -> c
         delayed rom @04
         go to L12000

L13641:  0 -> c[x]
         load constant 1
         go to L13621

L13644:  0 -> c[w]
         p <- 11
         load constant 6
         p <- 5
         load constant 6
         load constant 1
         b exchange c[w]
         jsb S13775
         c -> a[w]
         if c[x] = 0
           then go to L13701
         p <- 1
         load constant 1
         load constant 5
         p <- 1
         if a >= c[wp]
           then go to L13701
         if a[p] # 0
           then go to L13731
         load constant 0
         load constant 11
         p <- 1
         a - c -> a[wp]
         if n/c go to L13735
         a + c -> a[wp]
         a - 1 -> a[wp]
         p <- 4
         0 -> b[wp]
         go to L13735

L13701:  a exchange c[w]
         delayed rom @04
         jsb S12244
         0 -> a[wp]
         0 -> c[w]
         p <- 11
         load constant 7
         a exchange c[w]
         decimal
         a - c -> c[m]
         shift right c[w]
         p <- 3
         load constant 9
L13716:  p <- 12
         load constant 13
         load constant 14
         p <- 8
         load constant 15
         load constant 15
         load constant 10
         load constant 14
         load constant 15
         binary
         go to L13567

L13731:  p <- 0
         load constant 4
         p <- 0
         a + c -> a[p]
L13735:  0 -> a[m]
         shift left a[w]
         shift left a[m]
         shift left a[m]
         shift left a[m]
         shift left a[m]
         shift left a[m]
         shift left a[x]
         0 -> c[w]
         p <- 8
         load constant 7
         a exchange c[m]
         a - c -> a[m]
         shift left a[w]
         a exchange c[w]
         go to L13716

S13755:  delayed rom @04
         go to S12162

L13757:  jsb S13755
         if s 2 = 1
           then go to L12356
         if s 1 = 1
           then go to L12024
         1 -> s 2
         0 -> s 11
         if c[x] = 0
           then go to L12322
         delayed rom @04
         go to L12200

L13772:  p <- 7
         delayed rom @04
         go to L12173

S13775:  delayed rom @04
         go to S12157

	 .dw @0167			; CRC, bank 1 quad 1 (@12000..@13777)

         go to L14023

         go to L14131

         go to L14374

         go to L14061

         go to L14075

         go to L14120

         go to L14124

         go to L14123

         go to L14051

         go to L14050

         go to L14052

         go to L14111

         go to L14113

         go to L14042

         go to L14115

L14017:  load constant 1
         load constant 3
L14021:  delayed rom @11
         go to L14753

L14023:  load constant 1
         load constant 3
L14025:  p <- 8
L14026:  load constant 2
         load constant 5
         go to L14021

         nop
         go to L14133

         go to L14264

         go to L14142

         go to L14150

         go to L14156

         p <- 4
         load constant 7
         go to L14154

L14042:  load constant 7
L14043:  load constant 1
         p <- 8
L14045:  load constant 2
         load constant 3
         go to L14021

L14050:  jsb S14127
L14051:  go to L14045

L14052:  load constant 4
         go to L14043

         go to L14057

         go to L14164

         go to L14372

L14057:  0 -> a[xs]
         go to L14311

L14061:  p <- 0
         load constant 8
         p <- 0
         if a >= c[p]
           then go to L14213
         p <- 6
         load constant 1
         load constant 3
L14071:  p <- 8
L14072:  load constant 1
         load constant 4
         go to L14021

L14075:  p <- 0
         load constant 9
         p <- 0
         if a >= c[p]
           then go to L14577
         c - 1 -> c[p]
         if a >= c[p]
           then go to L14603
         p <- 6
         load constant 1
         load constant 2
         go to L14071

L14111:  load constant 5
         go to L14043

L14113:  load constant 6
         go to L14043

L14115:  load constant 2
         load constant 2
         go to L14021

L14120:  load constant 1
         load constant 1
         go to L14071

L14123:  jsb S14127
L14124:  load constant 2
         load constant 4
         go to L14021

S14127:  delayed rom @11
         go to L14737

L14131:  delayed rom @11
         go to L14444

L14133:  p <- 4
         load constant 4
L14135:  load constant 1
L14136:  shift left a[x]
L14137:  shift left a[x]
         p <- 7
         go to L14315

L14142:  if a >= c[p]
           then go to L14634
         p <- 4
         load constant 3
         load constant 3
         go to L14137

L14150:  if a >= c[p]
           then go to L14637
         p <- 4
         load constant 3
L14154:  load constant 4
         go to L14136

L14156:  a - c -> c[p]
         if c[p] = 0
           then go to L14643
         p <- 4
         load constant 2
         go to L14135

L14164:  load constant 1
         load constant 3
         delayed rom @11
         go to L14747

L14170:  jsb S14172
         go to L14023

S14172:  p <- 4
S14173:  load constant 1
         load constant 1
         p <- 6
         return

L14177:  p <- 6
         load constant 5
L14201:  load constant 1
         p <- 3
         a exchange c[p]
         load constant 8
         p <- 3
         a - c -> c[p]
         if n/c go to L14025
L14210:  p <- 6
         load constant 6
         go to L14201

L14213:  p <- 6
         load constant 7
         go to L14201

L14216:  p <- 4
         load constant 7
         load constant 3
         p <- 7
         go to L14026

L14223:  jsb S14235
         load constant 4
         load constant 7
         load constant 4
         go to L14021

L14230:  jsb S14235
L14231:  load constant 4
         load constant 2
         load constant 4
         go to L14021

S14235:  p <- 8
         load constant 2
         load constant 4
         load constant 1
         return

L14242:  p <- 7
         load constant 1
         load constant 5
         p <- 4
         go to L14045

L14247:  jsb S14262
         go to L14021

L14251:  jsb S14262
         c + 1 -> c[p]
L14253:  c + 1 -> c[p]
L14254:  c + 1 -> c[p]
         if n/c go to L14021
L14256:  jsb S14262
         go to L14254

L14260:  jsb S14262
         go to L14253

S14262:  delayed rom @11
         go to L14607

L14264:  if a >= c[p]
           then go to L14631
         p <- 4
         load constant 3
         load constant 2
         go to L14137

L14272:  p <- 7
         load constant 2
         load constant 2
         p <- 4
         jsb S14173
         go to L14021

L14300:  jsb S14172
         p <- 7
         go to L14026

L14303:  load constant 10
         if a >= c[x]
           then go to L14362
         p <- 6
         a - 1 -> a[xs]
         shift left a[wp]
L14311:  shift left a[wp]
         a exchange c[w]
         c -> a[w]
         p <- 6
L14315:  a + 1 -> a[xs]
         if n/c go to L14322
L14317:  p <- 8
         c -> a[wp]
         go to L14021

L14322:  a + 1 -> a[xs]
         if n/c go to L14327
         load constant 1
         load constant 4
         go to L14317

L14327:  a + 1 -> a[xs]
         if n/c go to L14334
         load constant 1
L14332:  load constant 5
         go to L14317

L14334:  load constant 2
         go to L14332

         nop
         nop
         go to L14170

         go to L14177

         go to L14210

         go to L14213

         go to L14216

         go to L14223

         go to L14230

         go to L14242

         go to L14365

         go to L14300

         go to L14247

         go to L14256

         go to L14260

         go to L14251

         go to L14272

         jsb S14172
         p <- 7
         go to L14017

L14362:  a + 1 -> a[xs]
         c + 1 -> c[p]
         a -> rom address

L14365:  p <- 8
         load constant 2
         load constant 3
         load constant 1
         go to L14231

L14372:  delayed rom @11
         go to L14745

L14374:  delayed rom @11
         go to L14524

S14376:  a exchange c[ms]
         0 -> b[w]
         p <- 9
         b exchange c[p]
         load constant 6
         p <- 9
         b exchange c[p]
         c - 1 -> c[p]
         c -> a[w]
         p <- 3
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[w]
         0 -> a[xs]
         p <- 0
         load constant 12
         go to L14555

         go to L14652

         go to L14676

         go to L14700

         go to L14702

         go to L14657

         go to L14704

         go to L14710

         go to L14717

         go to L14723

         go to L14726

         go to L14662

         go to L14665

         go to L14670

         go to L14673

         go to L14732

         load constant 1
         load constant 2
         p <- 7
         delayed rom @10
         go to L14017

L14444:  load constant 7
         load constant 3
         p <- 0
         load constant 8
         p <- 0
         if a >= c[p]
           then go to L14177
         c - 1 -> c[x]
         if a >= c[p]
           then go to L14507
         c - 1 -> c[x]
         if a >= c[p]
           then go to L14514
         p <- 6
         load constant 7
         load constant 3
         p <- 0
         c - 1 -> c[x]
         c - 1 -> c[x]
         if a >= c[p]
           then go to L14472
         go to L14505

L14472:  p <- 1
         load constant 1
         load constant 3
         p <- 0
         a - c -> c[p]
         p <- 4
         a exchange c[w]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[w]
L14505:  delayed rom @10
         go to L14071

L14507:  jsb S14517
         load constant 4
L14511:  p <- 7
         delayed rom @10
         go to L14072

L14514:  jsb S14517
         load constant 3
         go to L14511

S14517:  p <- 6
         load constant 15
         load constant 15
         load constant 3
         return

L14524:  p <- 0
         load constant 8
         p <- 0
         if a >= c[p]
           then go to L14210
         c - 1 -> c[p]
         c - 1 -> c[p]
         if a >= c[p]
           then go to L14546
         p <- 6
         load constant 7
         load constant 2
         p <- 0
         c - 1 -> c[x]
         c - 1 -> c[x]
         if a >= c[p]
           then go to L14472
         go to L14505

L14546:  p <- 7
         load constant 2
         load constant 5
         p <- 4
         load constant 1
         load constant 2
         go to L14753

L14555:  p <- 0
         if a >= c[p]
           then go to L14620
         c - 1 -> c[p]
         if a >= c[p]
           then go to L14574
         c - 1 -> c[p]
         if a >= c[p]
           then go to L14571
L14566:  p <- 6
         delayed rom @10
         a -> rom address

L14571:  a - 1 -> a[xs]
         a - 1 -> a[xs]
         if n/c go to L14566
L14574:  p <- 4
         a + 1 -> a[xs]
         a -> rom address

L14577:  p <- 4
         load constant 1
         load constant 2
         go to L14747

L14603:  p <- 4
         load constant 1
         load constant 1
         go to L14747

L14607:  p <- 8
         load constant 2
         load constant 3
         load constant 4
         load constant 1
         load constant 2
         load constant 4
         p <- 6
         return

L14620:  p <- 1
         if a[p] # 0
           then go to L14303
         shift left a[x]
         a + 1 -> a[xs]
         a + 1 -> a[xs]
         p <- 4
         delayed rom @10
         a -> rom address

L14631:  p <- 4
         load constant 5
         go to L14641

L14634:  p <- 4
         load constant 6
         go to L14641

L14637:  p <- 4
         load constant 7
L14641:  delayed rom @10
         go to L14135

L14643:  p <- 7
         load constant 1
         load constant 5
         p <- 4
         load constant 2
         load constant 2
         go to L14753

L14652:  load constant 1
         load constant 2
         p <- 6
         delayed rom @10
         go to L14023

L14657:  load constant 7
L14660:  load constant 3
         go to L14753

L14662:  load constant 3
         load constant 1
         go to L14753

L14665:  load constant 3
         load constant 2
         go to L14753

L14670:  load constant 3
         load constant 3
         go to L14753

L14673:  load constant 3
         load constant 4
         go to L14753

L14676:  delayed rom @10
         go to L14177

L14700:  delayed rom @10
         go to L14210

L14702:  delayed rom @10
         go to L14213

L14704:  load constant 2
         load constant 2
         p <- 7
         go to L14511

L14710:  p <- 8
         load constant 2
         load constant 4
L14713:  load constant 1
         load constant 4
         load constant 2
         go to L14660

L14717:  p <- 8
         load constant 1
L14721:  load constant 3
         go to L14713

L14723:  p <- 8
         load constant 2
         go to L14721

L14726:  p <- 8
         load constant 2
         load constant 2
         go to L14713

L14732:  load constant 1
         load constant 2
         p <- 7
         delayed rom @10
         go to L14115

L14737:  p <- 4
         a exchange b[p]
         a + 1 -> a[p]
         a exchange b[p]
         p <- 6
         return

L14745:  load constant 2
         load constant 4
L14747:  p <- 7
         load constant 1
         load constant 5
         go to L14753

L14753:  p <- 8
         c + 1 -> c[p]
         if n/c go to L14762
         load constant 15
L14757:  a exchange c[w]
         0 -> c[w]
         return

L14762:  c - 1 -> c[p]
         b exchange c[w]
         p <- 7
         load constant 3
         p <- 5
         load constant 3
         b exchange c[w]
         go to L14757

         p <- 6
         delayed rom @04
         go to L12173

         nop
         nop
         nop
S15000:  delayed rom @04
         go to S12162

S15002:  delayed rom @04
         go to S12157

S15004:  c - 1 -> c[xs]
         if c[xs] = 0
           then go to L15011
L15007:  c -> register 15
         return

L15011:  p <- 2
         load constant 7
         p <- 0
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L15024
         p <- 1
         if c[p] = 0
           then go to L15026
         0 -> c[x]
         go to L15007

L15024:  c - 1 -> c[p]
         if n/c go to L15007
L15026:  load constant 1
         load constant 0
         go to L15007

L15031:  jsb S15000
         if c[x] = 0
           then go to L15037
         jsb S15004
L15035:  delayed rom @13
         go to L15740

L15037:  jsb S15002
         c -> a[x]
         jsb S15000
         a exchange c[x]
         c -> register 15
         go to L15035

L15045:  if s 6 = 1
           then go to L15277
         1 -> s 6
         p <- 2
         load constant 1
         load constant 1
         load constant 14
         0 -> s 7
         c -> data address
         p <- 1
         if a >= c[wp]
           then go to L15275
L15061:  a exchange c[w]
         m1 exchange c
         b exchange c[w]
         data -> c
         a exchange c[w]
         go to L15162

L15067:  m1 exchange c
         b exchange c[w]
         a exchange c[w]
         m1 exchange c
         go to L15166

S15074:  binary
         p <- 1
         a exchange c[w]
         0 -> c[p]
         0 -> a[w]
         a - 1 -> a[w]
L15102:  c -> a[wp]
         shift left a[w]
         shift left a[w]
         c -> a[wp]
         shift left a[w]
         shift left a[w]
         c -> a[wp]
         if a[s] # 0
           then go to L15102
         a exchange b[w]
         jsb S15002
         if c[x] = 0
           then go to L15277
         m1 exchange c
         jsb S15000
         if c[x] # 0
           then go to L15127
         p <- 2
         load constant 1
         load constant 1
         load constant 14
L15127:  a exchange c[w]
         m1 -> c
         a exchange c[w]
         p <- 1
         a - c -> a[p]
         if a[p] # 0
           then go to L15211
         c -> a[p]
         p <- 0
         if a >= c[p]
           then go to L15213
L15142:  a exchange b[w]
         m1 exchange c
         m1 -> c
         p <- 12
L15146:  p + 1 -> p
         p + 1 -> p
         c - 1 -> c[xs]
         if n/c go to L15146
         p - 1 -> p
         m1 -> c
L15154:  c -> data address
         b exchange c[w]
         m1 exchange c
         data -> c
         b exchange c[w]
         a exchange b[w]
L15162:  if s 7 = 1
           then go to L15261
L15164:  if a[p] # 0
           then go to L15215
L15166:  p - 1 -> p
         a - b -> a[p]
         if a[p] # 0
           then go to L15251
         0 -> c[xs]
         c + 1 -> c[xs]
L15174:  if p = 0
           then go to L15202
         c + 1 -> c[xs]
         p - 1 -> p
         p - 1 -> p
         go to L15174

L15202:  c -> a[x]
         0 -> s 7
         0 -> s 6
         if 0 = s 10
           then go to L15356
         delayed rom @15
         go to L16772

L15211:  0 -> a[p]
         go to L15142

L15213:  1 -> s 7
         go to L15142

L15215:  p + 1 -> p
         p + 1 -> p
         if p # 0
           then go to L15164
         0 -> c[xs]
         c + 1 -> c[xs]
         if c[p] # 0
           then go to L15226
         c - 1 -> c[x]
L15226:  c - 1 -> c[x]
         m1 exchange c
         a exchange c[w]
         m1 exchange c
         p <- 1
         a - c -> a[p]
         if a[p] # 0
           then go to L15245
         c -> a[p]
         p <- 0
         if a >= c[p]
           then go to L15247
L15242:  a exchange b[w]
         p <- 1
         go to L15154

L15245:  0 -> a[p]
         go to L15242

L15247:  1 -> s 7
         go to L15242

L15251:  p + 1 -> p
         if 0 = s 7
           then go to L15215
         a exchange b[w]
         a exchange c[w]
         m1 exchange c
         a exchange c[w]
         go to L15267

L15261:  a exchange b[w]
         a exchange c[w]
         m1 exchange c
         a exchange c[w]
L15265:  if b[p] = 0
           then go to L15067
L15267:  p + 1 -> p
         p + 1 -> p
         c + 1 -> c[xs]
         if a >= c[xs]
           then go to L15265
         go to L15045

L15275:  1 -> s 7
         go to L15061

L15277:  delayed rom @06
         go to L13321

S15301:  0 -> c[w]
         binary
         c - 1 -> c[w]
         0 -> a[xs]
L15305:  if p = 0
           then go to L15312
         a + 1 -> a[xs]
         p - 1 -> p
         go to L15305

L15312:  shift left a[w]
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
S15330:  display off
         display toggle
L15332:  0 -> s 15
         if s 15 = 1
           then go to L15332
         0 -> s 12
         0 -> s 3
         if s 3 = 1
           then go to L15342
         1 -> s 12
L15342:  0 -> s 3
         if 0 = s 3
           then go to L15350
         if 0 = s 12
           then go to L15352
         go to L15354

L15350:  if 0 = s 12
           then go to L15354
L15352:  if 0 = s 15
           then go to L15342
L15354:  0 -> s 12
         display off
L15356:  return

S15357:  rotate left a
         rotate left a
         rotate left a
         rotate left a
         rotate left a
         rotate left a
         return

L15366:  load constant 7
         a - c -> c[x]
         if c[x] = 0
           then go to L15277
         a exchange c[w]
         delayed rom @04
         jsb S12122
         return

L15376:  if 0 = s 11
           then go to L15405
         jsb S15467
         if s 6 = 1
           then go to L15543
         a exchange c[m]
         go to L15407

L15405:  jsb S15506
         c - 1 -> c[m]
L15407:  p <- 3
         shift left a[wp]
L15411:  c + 1 -> c[p]
         if n/c go to L15422
         shift left a[m]
         p + 1 -> p
         if p # 12
           then go to L15411
         c + 1 -> c[p]
         if n/c go to L15422
         go to L15435

L15422:  c - 1 -> c[p]
         if p # 3
           then go to L15430
         1 -> s 7
         0 -> c[x]
         go to L15436

L15430:  if s 7 = 1
           then go to L15433
         a + 1 -> a[s]
L15433:  p - 1 -> p
         shift right a[m]
L15435:  a + c -> c[wp]
L15436:  c -> a[m]
         p - 1 -> p
         a - 1 -> a[wp]
         if c[m] = 0
           then go to L15444
         jsb S15520
L15444:  m2 exchange c
         data -> c
         p <- 9
         0 -> c[p]
         if 0 = s 7
           then go to L15456
         c + 1 -> c[p]
         if 0 = s 6
           then go to L15456
         c + 1 -> c[p]
L15456:  c -> data
         if 0 = s 6
           then go to L15465
         p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
L15465:  delayed rom @04
         go to L12025

S15467:  m2 -> c
         b exchange c[w]
         jsb S15702
         p <- 9
         if c[p] = 0
           then go to L15502
         1 -> s 7
         c - 1 -> c[p]
         if c[p] = 0
           then go to L15502
         1 -> s 6
L15502:  b -> c[w]
         0 -> c[x]
L15504:  binary
         return

S15506:  if s 9 = 1
           then go to S15512
         m2 -> c
         c -> stack
S15512:  0 -> s 9
         1 -> s 11
         jsb S15702
         0 -> c[w]
         c -> a[ms]
         go to L15504

S15520:  decimal
         a -> b[w]
         0 -> a[x]
         rotate left a
         a exchange b[ms]
         a exchange c[m]
         a + c -> c[x]
         p <- 12
L15530:  if c[p] # 0
           then go to L15540
         c - 1 -> c[x]
         p - 1 -> p
         if s 6 = 1
           then go to L15530
         shift left a[m]
         go to L15530

L15540:  a exchange c[m]
         a exchange b[x]
         return

L15543:  p <- 4
         shift left a[wp]
         jsb S15704
L15546:  a exchange c[x]
         c -> a[x]
         decimal
         if c[xs] = 0
           then go to L15555
         0 -> c[xs]
         0 - c -> c[x]
L15555:  jsb S15520
         jsb S15711
         if p = 12
           then go to L15444
         m2 exchange c
         delayed rom @04
         go to L12021

L15564:  jsb S15702
         if s 11 = 1
           then go to L15600
         jsb S15506
L15570:  p <- 12
         load constant 1
         c -> a[w]
         a - 1 -> a[wp]
L15574:  0 -> a[x]
         1 -> s 6
         1 -> s 7
         go to L15444

L15600:  jsb S15467
         if s 6 = 1
           then go to L15621
         if c[m] = 0
           then go to L15631
         p <- 5
         a exchange c[m]
         c -> a[m]
         0 -> c[wp]
         if c[m] = 0
           then go to L15621
         p <- 13
         load constant 7
         if a >= c[s]
           then go to L15621
         m2 -> c
         go to L15574

L15621:  jsb S15623
         go to L15465

S15623:  m2 -> c
S15624:  0 -> a[x]
         if s 6 = 1
           then go to L15630
         a - 1 -> a[x]
L15630:  return

L15631:  jsb S15512
         go to L15570

L15633:  if s 11 = 1
           then go to L15640
         1 -> s 7
         0 -> a[x]
         go to L15405

L15640:  jsb S15467
         1 -> s 7
         jsb S15623
         if 0 = s 6
           then go to L15444
         jsb S15704
         go to L15444

L15647:  if 0 = s 11
           then go to L15672
         jsb S15467
         decimal
         if s 6 = 1
           then go to L15665
         if c[m] = 0
           then go to L15444
         0 - c - 1 -> c[s]
         binary
         jsb S15624
         b -> c[x]
         m2 exchange c
         go to L15465

L15665:  jsb S15704
         a exchange c[xs]
         0 - c - 1 -> c[xs]
         c -> a[xs]
         go to L15546

L15672:  m2 -> c
         if c[m] = 0
           then go to L15465
         decimal
         0 - c - 1 -> c[s]
         nop
         delayed rom @04
         go to L12000

S15702:  delayed rom @04
         go to S12157

S15704:  p <- 5
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         return

S15711:  if c[m] # 0
           then go to L15714
         0 -> c[w]
L15714:  decimal
         p <- 12
         if c[xs] = 0
           then go to L15725
         c - 1 -> c[x]
         c + 1 -> c[xs]
         c - 1 -> c[xs]
         if n/c go to L15726
         c + 1 -> c[x]
L15725:  return

L15726:  c + c -> c[xs]
         if n/c go to L15732
         0 -> c[w]
         go to L15736

L15732:  0 -> c[wp]
         c - 1 -> c[wp]
         0 -> c[xs]
         p - 1 -> p
L15736:  p - 1 -> p
         return

L15740:  0 -> s 3
         if 0 = s 3
           then go to L15747
         1 -> s 6
         0 -> s 11
L15745:  delayed rom @04
         go to L12200

L15747:  delayed rom @06
         jsb S13216
         go to L15745

         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
S15776:  rom checksum

         .dw @0602			; CRC, bank 1 quad 2 (@14000..@15777)

L16000:  c -> a[x]
         c -> data address
         data -> c
         p <- 0
         c -> a[ms]
         a exchange c[x]
         shift left a[w]
         shift left a[w]
         a exchange b[w]
         c - 1 -> c[xs]
         if n/c go to L16017
L16013:  p + 1 -> p
         p + 1 -> p
         shift left a[w]
         shift left a[w]
L16017:  c - 1 -> c[xs]
         if n/c go to L16013
         0 -> c[xs]
         c + 1 -> c[xs]
         p + 1 -> p
         shift right b[wp]
         shift right b[wp]
         a exchange b[w]
         a + b -> a[wp]
         a exchange c[w]
         c -> data
         jsb S16064
         p <- 1
         a - c -> a[p]
         if a[p] # 0
           then go to L16047
         c -> a[p]
         p <- 0
         a - c -> c[p]
         if c[p] # 0
           then go to L16053
         jsb S16243
         delayed rom @04
         go to L12200

L16047:  p <- 0
         if a[p] # 0
           then go to L16053
         a - 1 -> a[x]
L16053:  a -> b[x]
         p <- 11
         0 -> a[wp]
         rotate left a
         rotate left a
         a exchange b[w]
         a - 1 -> a[x]
         a exchange c[w]
         go to L16000

S16064:  delayed rom @04
         go to S12157

L16066:  c - 1 -> c[xs]
         p <- 1
         go to L16073

L16071:  p + 1 -> p
         p + 1 -> p
L16073:  c - 1 -> c[xs]
         if n/c go to L16071
         c -> data address
         b exchange c[w]
         data -> c
         a exchange c[w]
         shift left a[wp]
         shift left a[wp]
         shift right a[w]
         shift right a[w]
         m1 exchange c
         a exchange b[w]
L16107:  p <- 1
         a - c -> a[p]
         if a[p] # 0
           then go to L16161
         c -> a[p]
         p <- 0
         a exchange c[w]
         if a >= c[p]
           then go to L16172
         a exchange c[w]
L16121:  a - 1 -> a[p]
         m1 exchange c
         a exchange c[w]
         c -> data address
         a exchange c[w]
         data -> c
         a exchange c[w]
         delayed rom @12
         jsb S15357
         delayed rom @12
         jsb S15357
         p <- 11
         a exchange b[wp]
         p <- 0
         if s 12 = 1
           then go to L16211
         c + 1 -> c[p]
L16142:  c -> data address
         a exchange c[w]
         c -> data
         m1 -> c
         if s 12 = 1
           then go to L16152
         a - 1 -> a[x]
         if n/c go to L16107
L16152:  a exchange c[w]
         p <- 1
         load constant 0
         load constant 14
         a exchange c[w]
         0 -> s 12
         go to L16107

L16161:  p <- 0
         if a[p] # 0
           then go to L16121
         p <- 1
         0 -> a[p]
         p <- 0
         a - 1 -> a[p]
         1 -> s 12
         go to L16121

L16172:  c -> data address
         a - 1 -> a[xs]
         if a[xs] # 0
           then go to L16207
         0 -> c[w]
L16177:  c -> data
         jsb S16064
         jsb S16215
         jsb S16241
         jsb S16215
         jsb S16243
         delayed rom @04
         go to L12024

L16207:  b exchange c[w]
         go to L16177

L16211:  p <- 1
         load constant 1
         load constant 0
         go to L16142

S16215:  c - 1 -> c[xs]
         if c[xs] = 0
           then go to L16222
L16220:  c -> register 15
         return

L16222:  p <- 2
         load constant 7
         p <- 0
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L16237
         p <- 1
         if c[p] = 0
           then go to L16235
         0 -> c[x]
         go to L16220

L16235:  load constant 1
         go to L16220

L16237:  c - 1 -> c[p]
         if n/c go to L16220
S16241:  delayed rom @04
         go to S12162

S16243:  jsb S16241
         b exchange c[x]
         0 -> c[w]
         c -> register 14
         b exchange c[x]
         c -> register 15
         return

L16252:  if a[x] # 0
           then go to L16255
         go to L16354

L16255:  0 -> s 11
         decimal
         0 -> c[w]
         p <- 2
         load constant 2
         load constant 1
         load constant 1
         a - c -> a[x]
         if n/c go to L16342
         a + c -> a[x]
         p <- 2
         load constant 1
         load constant 0
         load constant 5
         a exchange c[x]
         if a >= c[x]
           then go to L16344
         a exchange c[x]
         a - c -> a[x]
L16300:  0 -> c[x]
         p <- 0
         load constant 7
L16303:  binary
         c + 1 -> c[m]
         decimal
         a - c -> a[x]
         if n/c go to L16303
         a + c -> a[x]
         binary
         p <- 0
         if a[p] # 0
           then go to L16317
         a + c -> a[x]
         c - 1 -> c[m]
L16317:  0 -> a[m]
         a - 1 -> a[m]
         a - c -> c[m]
         shift right c[w]
         shift right c[w]
         shift right c[w]
         shift left a[w]
         shift left a[w]
         a exchange c[p]
         p <- 1
         if 0 = s 11
           then go to L16334
         a + 1 -> a[p]
L16334:  jsb S16064
         if c[x] = 0
           then go to L16342
         p <- 1
         a - c -> c[wp]
         if n/c go to L16347
L16342:  delayed rom @06
         go to L13321

L16344:  a exchange c[x]
         1 -> s 11
         go to L16300

L16347:  if c[wp] # 0
           then go to L16354
         c + 1 -> c[xs]
         a - c -> c[xs]
         if n/c go to L16342
L16354:  if s 7 = 1
           then go to L16665
         jsb S16241
L16357:  if s 1 = 1
           then go to L16365
         if s 2 = 1
           then go to L16365
         0 -> c[w]
         c -> register 14
L16365:  a exchange c[x]
         delayed rom @06
         go to L13335

S16370:  m2 -> c
         b exchange c[w]
         if s 11 = 1
           then go to L16616
         jsb S16064
         p <- 3
         if c[p] = 0
           then go to L16405
         1 -> s 4
         c - 1 -> c[p]
         if c[p] = 0
           then go to L16405
         1 -> s 6
L16405:  decimal
         0 -> a[x]
         f -> a[x]
         0 -> c[x]
         p <- 0
         load constant 10
         if a >= c[x]
           then go to L16505
L16415:  b -> c[w]
         a exchange b[x]
         if s 4 = 1
           then go to L16456
         if a[xs] # 0
           then go to L16444
         0 -> c[x]
         p <- 1
         c + 1 -> c[p]
         if a >= c[x]
           then go to L16455
         a + b -> a[x]
         if a >= c[x]
           then go to L16452
L16433:  jsb S16507
         if c[xs] = 0
           then go to L16437
         p + 1 -> p
L16437:  jsb S16516
         0 -> a[s]
         if a[xs] # 0
           then go to L16476
         go to L16612

L16444:  a exchange b[x]
         a -> b[x]
         a + 1 -> a[x]
         a + c -> a[x]
         if n/c go to L16455
         go to L16433

L16452:  c - 1 -> c[x]
         c -> a[x]
         go to L16433

L16455:  1 -> s 4
L16456:  a exchange b[x]
         jsb S16507
         jsb S16516
         if s 6 = 1
           then go to L16554
L16463:  if c[xs] = 0
           then go to L16470
         decimal
         0 - c -> c[x]
         c - 1 -> c[xs]
L16470:  a exchange c[x]
         p <- 5
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         go to L16616

L16476:  if c[ms] = 0
           then go to L16455
L16500:  shift right a[w]
         c + 1 -> c[x]
         if c[x] # 0
           then go to L16500
         go to L16614

L16505:  0 -> a[x]
         go to L16415

S16507:  m2 -> c
         0 -> c[s]
         p <- 12
L16512:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L16512
         return

S16516:  0 -> a[w]
         c -> a[wp]
         a + c -> a[ms]
         0 -> a[wp]
         a exchange c[ms]
         if c[s] = 0
           then go to L16543
         if 0 = s 4
           then go to L16551
         c + 1 -> c[x]
         if c[xs] = 0
           then go to L16542
         c - 1 -> c[xs]
         if c[xs] # 0
           then go to L16541
         m2 -> c
         c -> a[w]
         0 -> a[s]
         go to L16547

L16541:  c + 1 -> c[xs]
L16542:  shift right c[ms]
L16543:  c -> a[ms]
         binary
         a - 1 -> a[wp]
         c -> a[x]
L16547:  decimal
         return

L16551:  c + 1 -> c[x]
         p - 1 -> p
         go to L16542

L16554:  b exchange c[x]
         a + 1 -> a[xs]
         a - 1 -> a[x]
         p <- 1
         0 -> c[x]
         load constant 3
L16562:  a - c -> a[x]
         if n/c go to L16562
         a + c -> a[x]
         shift right c[x]
L16566:  a - c -> a[x]
         if n/c go to L16566
         a + c -> a[x]
         b -> c[x]
         p <- 12
         go to L16575

L16574:  a - 1 -> a[p]
L16575:  a - 1 -> a[x]
         if n/c go to L16600
         go to L16463

L16600:  a + 1 -> a[s]
         decimal
         c - 1 -> c[x]
         p - 1 -> p
         binary
         a + 1 -> a[p]
         if n/c go to L16574
         go to L16575

L16610:  a + 1 -> a[s]
         a - 1 -> a[x]
L16612:  if a[x] # 0
           then go to L16610
L16614:  binary
         a - 1 -> a[x]
L16616:  binary
         0 -> c[w]
         a exchange c[s]
         c -> a[s]
         a + 1 -> a[xs]
         if n/c go to L16652
L16624:  a - 1 -> a[xs]
         if b[s] = 0
           then go to L16631
         p <- 12
         load constant 4
L16631:  p <- 13
L16632:  p - 1 -> p
         a - 1 -> a[s]
         if n/c go to L16632
L16635:  c + 1 -> c[p]
         if p = 12
           then go to L16655
         p + 1 -> p
         if p = 12
           then go to L16655
         p + 1 -> p
         if p = 12
           then go to L16655
         p + 1 -> p
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L16635
L16652:  p <- 5
         load constant 6
         go to L16624

L16655:  c -> a[s]
         b exchange c[w]
         0 -> a[x]
         0 -> s 6
         0 -> s 4
         return

L16663:  delayed rom @12
         jsb S15074
L16665:  delayed rom @04
         jsb S12162
         0 -> s 11
         0 -> s 9
         if s 4 = 1
           then go to L16357
         if s 1 = 1
           then go to L16710
         if s 2 = 1
           then go to L16710
         1 -> s 2
         0 -> c[w]
         c -> register 14
         a exchange c[x]
         c -> register 15
         delayed rom @04
         go to L12200

L16706:  delayed rom @04
         go to L12035

L16710:  a exchange b[w]
         register -> c 14
         p <- 9
         if c[p] # 0
           then go to L16723
         p <- 8
         if c[p] # 0
           then go to L16723
         p <- 7
         if c[p] = 0
           then go to L17305
L16723:  p <- 8
         delayed rom @04
         go to L12173

L16726:  delayed rom @04
         jsb S12112
         delayed rom @04
         go to L12023

L16732:  delayed rom @14
         go to L16252

L16734:  delayed rom @16
         go to L17211

L16736:  delayed rom @07
         go to L13400

L16740:  delayed rom @17
         go to L17747

L16742:  delayed rom @07
         go to L13757

S16744:  rom checksum

L16745:  bank toggle

         delayed rom @04
         jsb S12112
         go to L16745

L16751:  bank toggle

         go to L16734

L16753:  bank toggle

         go to L16736

L16755:  bank toggle

         go to L16726

L16757:  1 -> s 4
L16760:  bank toggle

         go to L16740

L16762:  bank toggle

         go to L16742

L16764:  bank toggle

         go to L16663

L16766:  bank toggle

         go to L16732

L16770:  bank toggle

         nop
L16772:  bank toggle

         delayed rom @12
         go to S15074

L16775:  bank toggle

         go to L16706

L16777:  bank toggle

L17000:  delayed rom @12
         go to L15376

L17002:  delayed rom @13
         go to L15633

L17004:  delayed rom @13
         go to L15647

L17006:  delayed rom @13
         go to L15564

S17010:  jsb S17140
         shift left a[x]
         shift left a[x]
         p <- 10
L17014:  p + 1 -> p
         a - 1 -> a[xs]
         if n/c go to L17014
         return

L17020:  jsb S17010
         if c[p] = 0
           then go to L16726
L17023:  delayed rom @04
         go to L12023

L17025:  jsb S17010
         0 -> c[p]
L17027:  c -> register 15
         go to L17023

L17031:  jsb S17010
         load constant 1
         go to L17027

L17034:  0 -> c[w]
         c -> data address
         c -> register 15
         jsb S17140
         if c[x] # 0
           then go to L17045
         p <- 1
         load constant 1
         load constant 15
L17045:  0 -> c[xs]
         if c[x] # 0
           then go to L17056
         go to L17201

L17051:  0 -> a[w]
         c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
L17056:  c - 1 -> c[x]
         if n/c go to L17051
         go to L17201

L17061:  jsb S17140
         if c[x] = 0
           then go to L17075
         0 -> c[xs]
         a exchange c[x]
         0 -> c[x]
         p <- 0
         load constant 6
         if a >= c[x]
           then go to L17045
L17073:  p <- 2
         go to L17122

L17075:  p <- 0
         load constant 6
         go to L17045

L17100:  m2 -> c
         down rotate
         down rotate
         down rotate
         delayed rom @04
         go to L12000

L17106:  load constant 8
         p <- 0
         if a >= c[p]
           then go to L17031
         c - 1 -> c[p]
         if a >= c[p]
           then go to L17061
         c - 1 -> c[p]
         if a >= c[p]
           then go to L17034
         delayed rom @15
         go to L16751

L17122:  delayed rom @04
         go to L12173

L17124:  load constant 8
         p <- 0
         if a >= c[p]
           then go to L17025
         c - 1 -> c[p]
         if a >= c[p]
           then go to L17224
         c - 1 -> c[p]
         if a >= c[p]
           then go to L17201
         delayed rom @15
         go to L16753

S17140:  delayed rom @04
         go to S12157

L17142:  load constant 8
         p <- 0
         if a >= c[p]
           then go to L17020
L17146:  jsb S17140
         p <- 3
         load constant 2
         go to L17170

L17152:  load constant 9
         p <- 0
         if a >= c[p]
           then go to L17206
         c - 1 -> c[p]
         if a >= c[p]
           then go to L17203
L17161:  jsb S17140
         p <- 3
         load constant 1
         go to L17170

L17165:  jsb S17140
         p <- 3
         0 -> c[p]
L17170:  f exchange a[x]
         f -> a[x]
         shift left a[w]
         shift left a[w]
         shift left a[w]
         shift left a[w]
         p <- 4
         a exchange c[p]
L17200:  c -> register 15
L17201:  delayed rom @04
         go to L12024

L17203:  jsb S17140
         0 -> c[s]
         go to L17200

L17206:  jsb S17140
         0 -> c[s]
         go to L17214

L17211:  jsb S17140
         0 -> c[s]
         c + 1 -> c[s]
L17214:  c + 1 -> c[s]
         if n/c go to L17200
L17216:  m2 -> c
         c -> stack
L17220:  delayed rom @04
         go to L12103

L17222:  0 -> c[w]
         go to L17220

L17224:  jsb S17252
         0 -> s 9
         if s 1 = 1
           then go to L17236
         if s 2 = 1
           then go to L17237
         0 -> c[w]
         c -> register 14
L17234:  delayed rom @06
         go to L13335

L17236:  0 -> s 2
L17237:  0 -> s 11
         jsb S17257
         if c[x] # 0
           then go to L17247
         if c[w] # 0
           then go to L17237
         0 -> s 2
         go to L17325

L17247:  if c[xs] = 0
           then go to L16755
         go to L17234

S17252:  0 -> c[x]
         p <- 1
         load constant 2
         c -> data address
         return

S17257:  register -> c 14
         c -> a[w]
         register -> c 15
         jsb S17301
         jsb S17301
         c - 1 -> c[xs]
         if n/c go to L17267
         0 -> c[xs]
L17267:  jsb S17301
         p <- 9
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         c -> register 15
         a exchange c[w]
         c -> register 14
         a exchange c[w]
         return

S17301:  shift right c[w]
         a exchange c[s]
         shift left a[w]
         return

L17305:  delayed rom @04
         jsb S12112
         c -> a[w]
         register -> c 14
         jsb S17301
         a + 1 -> a[xs]
         jsb S17301
         jsb S17301
         a exchange b[x]
         a exchange c[w]
         c -> register 15
         register -> c 14
         p <- 6
         a exchange c[wp]
         a exchange c[w]
         c -> register 14
L17325:  delayed rom @04
         go to L12035

L17327:  a exchange c[p]
         p <- 1
         load constant 4
         p <- 1
         if a >= c[p]
           then go to L17161
         go to L17146

L17336:  0 -> c[w]
         return

L17340:  binary
         0 -> c[xs]
         c -> a[x]
         p <- 0
         a + 1 -> a[p]
         display off
         if a[p] # 0
           then go to L17360
         p <- 1
         load constant 10
         p <- 1
         if a >= c[p]
           then go to L17357
         shift left a[x]
         go to L17000

L17357:  p <- 0
L17360:  a - 1 -> a[p]
         0 -> c[x]
         c -> data address
         load constant 12
         p <- 0
         if a >= c[p]
           then go to L16777
         c - 1 -> c[p]
         c - 1 -> c[p]
         if a >= c[p]
           then go to L17441
         delayed rom @17
         a -> rom address

         nop
         nop
         nop
         go to L17775

         go to L17452

         go to L17454

         go to L17456

         go to L17460

         go to L17462

         go to L17465

         go to L17464

         go to L17473

         go to L17472

         go to L17534

         go to L17540

         go to L17542

         go to L17545

         1 -> s 4
         go to L17437

         go to L17775

         go to L17444

         go to L17446

         go to L17450

         go to L17725

         go to L17626

         go to L17644

         go to L17734

         go to L17716

         go to L17654

         go to L17550

         go to L17554

         go to L17560

         go to L17564

         1 -> s 4
L17437:  delayed rom @15
         go to L16663

L17441:  a + 1 -> a[xs]
         c + 1 -> c[p]
         a -> rom address

L17444:  delayed rom @16
         go to L17031

L17446:  delayed rom @16
         go to L17025

L17450:  delayed rom @16
         go to L17020

L17452:  delayed rom @16
         go to L17106

L17454:  delayed rom @16
         go to L17124

L17456:  delayed rom @16
         go to L17142

L17460:  delayed rom @16
         go to L17152

L17462:  delayed rom @16
         go to L17165

L17464:  1 -> s 4
L17465:  jsb S17476
L17466:  jsb S17742
         data -> c
L17470:  delayed rom @04
         go to L12000

L17472:  1 -> s 4
L17473:  jsb S17476
L17474:  c -> data
         go to L17470

S17476:  a exchange c[x]
         0 -> a[x]
         p <- 0
         a exchange c[p]
L17502:  0 -> c[x]
         if 0 = s 4
           then go to L17513
         p <- 0
         load constant 5
         p <- 0
         if a >= c[x]
           then go to L17532
         load constant 10
L17513:  binary
         a + c -> a[x]
L17515:  jsb S17740
         if c[x] = 0
           then go to L17523
         0 -> c[xs]
         if a >= c[x]
           then go to L17073
L17523:  a exchange c[x]
L17524:  c -> data address
         data -> c
         a exchange c[w]
         m2 -> c
         decimal
         return

L17532:  load constant 11
         go to L17513

L17534:  jsb S17476
L17535:  0 - c - 1 -> c[s]
L17536:  delayed rom @15
         go to L16762

L17540:  jsb S17476
         go to L17536

L17542:  jsb S17476
L17543:  delayed rom @15
         go to L16764

L17545:  jsb S17476
L17546:  delayed rom @15
         go to L16766

L17550:  if a >= c[p]
           then go to L17216
         jsb S17570
         go to L17535

L17554:  if a >= c[p]
           then go to L17004
         jsb S17570
         go to L17536

L17560:  if a >= c[p]
           then go to L17006
         jsb S17570
         go to L17543

L17564:  if a >= c[p]
           then go to L17222
         jsb S17570
         go to L17546

S17570:  register -> c 15
         0 -> c[s]
         jsb S17755
         c - 1 -> c[x]
         if c[xs] # 0
           then go to L17613
         if c[x] # 0
           then go to L17073
         c -> a[w]
         0 -> c[w]
         p <- 12
         load constant 2
         if a >= c[w]
           then go to L17620
         shift left a[w]
         shift left a[w]
         rotate left a
         1 -> s 4
         go to L17502

L17613:  c -> a[w]
         0 -> a[x]
         shift left a[w]
         rotate left a
         go to L17515

L17620:  a - c -> a[w]
         if a[w] # 0
           then go to L17073
         p <- 0
         load constant 15
         go to L17524

L17626:  if a >= c[p]
           then go to L17100
         shift right a[x]
         jsb S17476
         register -> c 3
         c -> a[w]
         if s 9 = 1
           then go to L17640
         m2 -> c
         c -> stack
L17640:  a exchange c[w]
         c -> stack
         register -> c 1
         go to L17470

L17644:  if a >= c[p]
           then go to L17650
         jsb S17570
         go to L17466

L17650:  register -> c 15
         a exchange c[w]
         m2 -> c
         go to L17466

L17654:  if a >= c[p]
           then go to L16757
         register -> c 15
         jsb S17755
         if c[s] # 0
           then go to L17677
         if c[x] # 0
           then go to L17673
L17664:  c -> a[w]
         shift left a[w]
         rotate left a
         jsb S17740
         register -> c 15
         delayed rom @16
         go to L17170

L17673:  0 -> c[w]
         p <- 12
         load constant 9
         go to L17664

L17677:  c -> a[w]
         0 -> c[w]
         p <- 13
         binary
         load constant 9
         load constant 6
         if a[x] # 0
           then go to L17712
         if a >= c[m]
           then go to L17712
         go to L17713

L17712:  c -> a[m]
L17713:  shift right c[w]
         a + c -> c[m]
         if n/c go to L17664
L17716:  if a >= c[p]
           then go to L17722
         jsb S17570
         go to L17474

L17722:  register -> c 15
         m2 -> c
         go to L17474

L17725:  if a >= c[p]
           then go to L17002
         decimal
         m2 -> c
         jsb S17742
         delayed rom @15
         go to L16775

L17734:  if a >= c[p]
           then go to L16760
         delayed rom @15
         go to L16770

S17740:  delayed rom @04
         go to S12157

S17742:  m2 -> c
         if s 9 = 1
           then go to L17746
         c -> stack
L17746:  return

L17747:  0 -> c[x]
         c -> data address
         jsb S17570
         c -> data
         a exchange c[w]
         go to L17470

S17755:  c -> a[w]
         p <- 12
         decimal
         if c[xs] # 0
           then go to L17336
         c + 1 -> c[x]
L17763:  if c[x] = 0
           then go to L17772
         c - 1 -> c[x]
         shift left a[m]
         p - 1 -> p
         if a[m] # 0
           then go to L17763
L17772:  0 -> c[wp]
         a exchange c[x]
         return

L17775:  delayed rom @04
         go to L12023

	 .dw @1053			; CRC, bank 1 quad 3 (@16000..@17777)

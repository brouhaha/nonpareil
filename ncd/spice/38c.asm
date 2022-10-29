; 38C model-specific firmware, uses 1820-2162 CPU ROM
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

	 .arch woodstock

         .include "1820-2162.inc"

	 .bank 0
	 .org @2000

L02000:  go to L02006

L02001:  bank toggle

L02002:  go to L02044

L02003:  p <- 0
L02004:  bank toggle

L02005:  go to L02013

L02006:  bank toggle

L02007:  return

L02010:  bank toggle

         delayed rom @11
         go to L04455

L02013:  bank toggle

         delayed rom @03
         jsb S01572
         bank toggle

         go to L02053

S02020:  bank toggle

         delayed rom @15
         go to L06717

L02023:  bank toggle

         delayed rom @06
         go to L03231

L02026:  bank toggle

L02027:  delayed rom @06
         go to L03004

L02031:  bank toggle

L02032:  p <- 6
         go to L02004

L02034:  bank toggle

S02035:  rom checksum

L02036:  bank toggle

         nop
S02040:  bank toggle

L02041:  jsb S02367
         go to L02110

L02043:  bank toggle

L02044:  c -> a[w]
         0 -> c[w]
         c -> data address
         m2 -> c
         c -> register 10
         a exchange c[w]
         go to L02006

L02053:  p <- 2
         load constant 10
         load constant 10
         p <- 1
         shift left a[x]
         if a >= c[xs]
           then go to L02076
         if a >= c[p]
           then go to L03017
         if 0 = s 0
           then go to L03230
         p <- 9
         load constant 2
         load constant 5
         p <- 6
         load constant 7
         p <- 4
         shift left a[wp]
         go to L02350

L02076:  if a >= c[p]
           then go to L02164
         a + 1 -> a[xs]
         if n/c go to L02117
         p <- 9
         load constant 2
         load constant 2
         if s 0 = 1
           then go to L02343
         jsb S02320
L02110:  data -> c
L02111:  if s 9 = 1
           then go to L02006
         m2 exchange c
         c -> stack
L02115:  m2 -> c
         go to L02006

L02117:  a + 1 -> a[xs]
         if n/c go to L02140
         jsb S02337
         if s 0 = 1
           then go to L02343
         jsb S02320
L02125:  m2 -> c
L02126:  clear status
L02127:  jsb S02132
         c -> data
         go to L02010

S02132:  delayed rom @03
         jsb S01572
         if p # 10
           then go to L02007
         p <- 1
         go to L02004

L02140:  load constant 7
         p <- 1
         if a >= c[p]
           then go to L02164
         shift left a[w]
         a exchange c[xs]
         shift right a[w]
         a exchange c[x]
         if s 0 = 1
           then go to L02270
         c + 1 -> c[xs]
         if n/c go to L02305
         jsb S02374
         delayed rom @00
         jsb S00222
L02157:  jsb S02132
         c -> data
L02161:  m2 -> c
         clear status
         go to L02010

L02164:  p <- 4
         if s 0 = 1
           then go to L02026
         jsb S02377
         p <- 0
L02171:  delayed rom @05
         a -> rom address

L02173:  a + 1 -> a[p]
         if n/c go to L02204
         p <- 6
         load constant 2
         load constant 2
         if s 0 = 1
           then go to L02347
         jsb S02353
         go to L02110

L02204:  a + 1 -> a[p]
         if n/c go to L02214
         p <- 6
         load constant 2
         load constant 4
         if 0 = s 0
           then go to L02565
         go to L02347

L02214:  a + 1 -> a[p]
         if n/c go to L02245
         p <- 6
         jsb S02340
         if s 0 = 1
           then go to L02347
         jsb S02353
         go to L02125

L02224:  p <- 2
         load constant 5
         a - c -> a[xs]
         if n/c go to L02265
         a + c -> a[xs]
         p <- 7
         load constant 2
         load constant 2
         if 0 = s 0
           then go to L02041
L02236:  p <- 4
         load constant 1
         0 -> c[p]
L02241:  c + 1 -> c[p]
         a - 1 -> a[xs]
         if n/c go to L02241
         go to L02031

L02245:  a + 1 -> a[p]
         if n/c go to L02224
         a - 1 -> a[p]
         p <- 2
         load constant 7
         if a >= c[xs]
           then go to L02164
         p <- 6
         load constant 2
         load constant 5
         if s 0 = 1
           then go to L02347
         shift right a[x]
         a - 1 -> a[xs]
         jsb S02377
         go to L02171

L02265:  p <- 7
         jsb S02340
         go to L02027

L02270:  jsb S02337
         p <- 6
         load constant 8
         load constant 1
         p <- 6
L02275:  c - 1 -> c[p]
         c + 1 -> c[xs]
         if n/c go to L02275
         go to L02347

L02301:  c + 1 -> c[xs]
         if n/c go to L02313
         jsb S02374
         go to L02315

L02305:  c + 1 -> c[xs]
         if n/c go to L02301
         jsb S02374
         delayed rom @00
         jsb S00171
         go to L02157

L02313:  jsb S02374
         0 - c - 1 -> c[s]
L02315:  delayed rom @00
         jsb S00014
         go to L02157

S02320:  shift right a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
L02324:  p <- 1
         a + 1 -> a[p]
         register -> c 14
         shift right c[x]
         c + 1 -> c[xs]
         shift right c[x]
         if a >= c[wp]
           then go to L02032
L02334:  a exchange c[x]
L02335:  c -> data address
         return

S02337:  p <- 9
S02340:  load constant 2
         load constant 1
         return

L02343:  p <- 6
         load constant 7
         load constant 3
         shift left a[x]
L02347:  p <- 3
L02350:  shift left a[wp]
         a exchange c[wp]
         go to L02031

S02353:  shift right a[x]
         shift right a[x]
         0 -> c[x]
         p <- 0
         load constant 7
         a - c -> a[x]
         if n/c go to L02324
         a + c -> a[x]
         a - 1 -> a[x]
         if n/c go to L02334
         c - 1 -> c[x]
         if n/c go to L02335
S02367:  a exchange c[x]
         0 - c - 1 -> c[xs]
         shift right c[x]
         shift right c[x]
         go to L02335

S02374:  jsb S02353
         data -> c
         a exchange c[w]
S02377:  m2 -> c
         decimal
         return

L02402:  shift right a[x]
         a -> rom address

L02404:  delayed rom @04
         go to L02023

L02406:  if s 7 = 1
           then go to L03076
         0 - c - 1 -> c[s]
L02411:  delayed rom @04
         go to L02006

         go to L02563

         go to L02646

         go to L02572

         go to L02650

         go to L02575

L02420:  delayed rom @06
         go to L03031

L02422:  0 - c - 1 -> c[s]
L02423:  stack -> a
         delayed rom @00
         jsb S00014
         go to L02601

L02427:  stack -> a
L02430:  delayed rom @00
         jsb S00171
         go to L02601

L02433:  if c[m] = 0
           then go to L02003
         stack -> a
         delayed rom @00
         jsb S00222
         go to L02601

L02441:  delayed rom @06
         go to L03370

L02443:  delayed rom @01
         jsb S00540
         go to L02601

L02446:  delayed rom @02
         jsb S01041
         go to L02601

L02451:  delayed rom @06
         go to L03201

L02453:  delayed rom @14
         jsb S06365
         m2 -> c
         0 -> s 7
         delayed rom @02
         go to L01331

L02461:  0 -> c[w]
         go to L02513

L02463:  delayed rom @03
         jsb S01407
         go to L02601

L02466:  delayed rom @06
         go to L03357

L02470:  delayed rom @14
         go to L06127

L02472:  delayed rom @14
         go to L06273

L02474:  delayed rom @14
         go to L06312

L02476:  delayed rom @14
         go to L06262

L02500:  delayed rom @04
         go to L02043

L02502:  c - 1 -> c[x]
         c - 1 -> c[x]
         y -> a
         go to L02430

L02506:  delayed rom @06
         go to L03313

L02510:  delayed rom @06
         go to L03321

L02512:  c -> stack
L02513:  delayed rom @04
         go to L02013

L02515:  down rotate
         go to L02612

L02517:  delayed rom @07
         go to L03524

L02521:  0 -> c[w]
         delayed rom @07
         go to L03507

L02524:  delayed rom @07
         go to L03504

L02526:  delayed rom @07
         go to L03653

L02530:  delayed rom @07
         go to L03576

L02532:  delayed rom @15
         go to L06412

L02534:  delayed rom @15
         go to L06566

L02536:  delayed rom @15
         go to L06600

L02540:  0 -> s 10
         if s 9 = 1
           then go to L02544
         c -> stack
L02544:  delayed rom @06
         jsb S03330
         c -> stack
         1 -> s 10
         register -> c 13
         0 - c - 1 -> c[s]
         c -> stack
         delayed rom @06
         jsb S03332
         go to L02411

L02556:  delayed rom @10
         go to L04040

L02560:  1 -> s 12
         delayed rom @11
         go to L04462

L02563:  delayed rom @12
         go to L05273

L02565:  shift right a[x]
         shift right a[x]
         f exchange a[x]
         delayed rom @04
         go to L02034

L02572:  0 -> s 10
L02573:  delayed rom @12
         go to L05147

L02575:  delayed rom @12
         go to L05157

         delayed rom @00
         jsb S00352
L02601:  delayed rom @04
         go to L02044

L02603:  delayed rom @03
         go to L01476

L02605:  delayed rom @03
         go to L01474

L02607:  stack -> a
         c -> stack
         a exchange c[w]
L02612:  delayed rom @04
         go to L02006

L02614:  delayed rom @00
         jsb S00272
         go to L02601

         delayed rom @06
         jsb S03303
         register -> c 15
         a exchange c[w]
         delayed rom @00
         jsb S00222
         go to L02644

L02626:  0 -> b[w]
         b exchange c[m]
L02630:  y -> a
         a exchange c[w]
         c - 1 -> c[x]
         c - 1 -> c[x]
         delayed rom @00
         jsb S00224
         go to L02601

         delayed rom @06
         jsb S03303
         register -> c 14
         delayed rom @00
         jsb S00171
L02644:  delayed rom @04
         go to L02111

L02646:  delayed rom @13
         go to L05575

L02650:  1 -> s 10
         go to L02573

         go to L02603

         go to L02470

         go to L02605

         go to L02565

         go to L02500

         go to L02420

L02660:  delayed rom @07
         go to L03400

L02662:  0 - c - 1 -> c[s]
         y -> a
         delayed rom @00
         jsb S00014
         if c[s] = 0
           then go to L02034
L02670:  delayed rom @07
         go to L03413

         go to L02703

         go to L02506

         go to L02517

         go to L02532

         go to L02512

         go to L02777

L02700:  delayed rom @14
         jsb S06062
         go to L02601

L02703:  0 -> c[w]
         c -> data address
         register -> c 10
         go to L02644

         go to L02614

         go to L02453

         go to L02423

         go to L02451

         go to L02510

         go to L02660

         go to L02540

         go to L02406

         go to L02777

L02720:  delayed rom @14
         jsb S06033
         go to L02601

L02723:  delayed rom @14
         jsb S06033
         m1 -> c
         go to L02601

         go to L02626

         go to L02446

         go to L02422

         go to L02515

         go to L02521

         go to L02466

         go to L02560

         go to L02607

         go to L02777

L02740:  y -> a
         a exchange c[w]
         0 - c - 1 -> c[s]
         delayed rom @00
         jsb S00014
         a exchange c[w]
         go to L02630

         go to L02534

         go to L02723

         go to L02427

         go to L02720

         go to L02524

         go to L02526

         go to L02700

         go to L02461

         go to L02777

         go to L02441

         go to L02472

         go to L02474

         go to L02463

         go to L02404

         go to L02662

         go to L02670

         go to L02536

         go to L02476

         go to L02433

         go to L02443

         go to L02530

         go to L02740

         go to L02556

         go to L02502

L02777:  if s 1 = 1
           then go to L02402
         p <- 2
         load constant 11
         a - c -> a[xs]
L03004:  binary
         if s 0 = 1
           then go to L02236
         delayed rom @04
         jsb S02367
         m2 -> c
L03012:  clear status
         1 -> s 9
         1 -> s 1
         delayed rom @04
         go to L02127

L03017:  a + 1 -> a[p]
         if a[p] # 0
           then go to L02173
         if s 0 = 1
           then go to L02347
         if 0 = s 7
           then go to L03036
         if s 8 = 1
           then go to L03133
         go to L03036

L03031:  1 -> s 6
         if s 7 = 1
           then go to L02036
         shift left a[x]
         shift left a[x]
L03036:  m2 -> c
         jsb S03114
         p <- 3
L03041:  a + 1 -> a[p]
         if n/c go to L03046
         shift left a[wp]
         p + 1 -> p
         go to L03041

L03046:  a - 1 -> a[p]
         if p = 3
           then go to L02036
         if p = 13
           then go to L03056
         if s 6 = 1
           then go to L03056
         a + 1 -> a[s]
L03056:  a -> b[w]
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
           then go to L03107
         0 -> a[w]
L03073:  a exchange c[w]
         a exchange b[w]
         go to L03103

L03076:  if s 8 = 1
           then go to L03172
         if c[m] = 0
           then go to L02036
         0 - c - 1 -> c[s]
L03103:  0 -> s 9
         m2 exchange c
         delayed rom @04
         go to L02036

L03107:  if a[p] # 0
           then go to L03073
         a - 1 -> a[x]
         shift left a[m]
         go to L03107

S03114:  binary
         if s 7 = 1
           then go to L02007
         if s 9 = 1
           then go to L03122
         c -> stack
L03122:  0 -> s 8
         1 -> s 7
         0 -> a[ms]
         a - 1 -> a[m]
         0 -> s 1
         0 -> c[w]
         return

L03131:  0 -> b[x]
         go to L03155

L03133:  p <- 4
         m2 -> c
         shift left a[wp]
L03136:  a -> b[w]
         decimal
         p <- 5
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         a -> b[x]
         0 -> a[x]
         p <- 1
         if b[xs] = 0
           then go to L03155
         a - b -> a[wp]
         if n/c go to L03131
         a -> b[wp]
         0 -> a[x]
L03155:  rotate left a
         a + b -> a[x]
L03157:  if a[s] # 0
           then go to L03164
         a - 1 -> a[x]
         shift left a[ms]
         go to L03157

L03164:  a exchange c[x]
         a exchange b[w]
         jsb S03355
         if p # 12
           then go to L02006
         go to L03103

L03172:  p <- 5
         a exchange c[p]
         0 - c - 1 -> c[p]
         a exchange c[p]
         go to L03136

L03177:  0 -> s 7
         1 -> s 9
L03201:  if s 7 = 1
           then go to L03220
         jsb S03114
         0 -> b[w]
         p <- 12
         c + 1 -> c[p]
         c -> a[p]
         p <- 5
L03211:  a exchange b[wp]
         1 -> s 8
         if a[m] # 0
           then go to L03103
         0 -> s 8
         a exchange b[wp]
         go to L03103

L03220:  if c[m] = 0
           then go to L03177
         delayed rom @04
         jsb S02040
         p <- 5
         if b[wp] = 0
           then go to L03211
         go to L03103

L03230:  shift right a[x]
L03231:  load constant 0
         load constant 7
         b exchange c[x]
         p <- 1
         register -> c 14
         0 -> c[wp]
         decimal
         a - 1 -> a[x]
         if n/c go to L03246
         0 -> s 2
L03243:  c -> register 14
L03244:  delayed rom @04
         go to L02034

L03246:  if 0 = s 2
           then go to L03253
         a - 1 -> a[x]
         if n/c go to L03253
         go to L03243

L03253:  a - 1 -> a[x]
         if n/c go to L03260
         load constant 6
         load constant 15
         go to L03243

L03260:  binary
         c - 1 -> c[wp]
L03262:  binary
         c - 1 -> c[x]
         decimal
         a - b -> a[wp]
         if n/c go to L03262
         a + b -> a[wp]
         shift left a[x]
         a exchange c[p]
         c -> a[x]
         shift left a[x]
         shift left a[x]
         a exchange c[x]
         p <- 4
         if a >= c[xs]
           then go to L02004
         a exchange c[x]
         go to L03243

S03303:  0 -> c[w]
         c -> data address
         p <- 12
         load constant 1
         load constant 2
         c + 1 -> c[x]
         c -> a[w]
         return

L03313:  jsb S03303
         register -> c 15
         m2 -> c
         delayed rom @00
         jsb S00171
         go to L03012

L03321:  jsb S03303
         register -> c 14
         m2 -> c
         a exchange c[w]
         delayed rom @00
         jsb S00222
         go to L03012

S03330:  0 -> c[w]
         c -> data address
S03332:  register -> c 15
         c -> a[w]
         register -> c 14
         delayed rom @00
         jsb S00171
         register -> c 13
         0 - c - 1 -> c[s]
         delayed rom @00
         jsb S00173
         0 -> c[w]
         load constant 3
         load constant 6
         if s 10 = 1
           then go to L03351
         load constant 5
L03351:  p <- 0
         load constant 4
         delayed rom @00
         jsb S00224
S03355:  delayed rom @03
         go to S01572

L03357:  0 -> c[w]
         c -> data address
         c -> register 0
         c -> register 1
         c -> register 2
         c -> register 3
         c -> register 4
         c -> register 5
         go to L03244

L03370:  0 -> c[w]
         c -> data address
         data -> c
         p <- 2
         if c[m] = 0
           then go to L02004
         delayed rom @03
         go to L01545

L03400:  0 -> c[w]
         p <- 0
         bank toggle

         nop
L03404:  bank toggle

L03405:  p <- 9
         delayed rom @04
         go to L02004

L03410:  bank toggle

S03411:  delayed rom @10
         go to S04012

L03413:  bank toggle

S03414:  if c[s] # 0
           then go to L02032
         c - 1 -> c[x]
         if n/c go to L03422
         0 -> c[x]
         shift right c[m]
L03422:  if c[x] # 0
           then go to L02032
         p <- 10
         if c[wp] # 0
           then go to L02032
         p <- 1
         load constant 1
         c -> data address
         0 -> c[x]
         load constant 8
         a exchange c[w]
         register -> c 14
         0 -> c[ms]
         c + 1 -> c[s]
         shift right c[w]
         c + 1 -> c[xs]
         shift right c[w]
L03443:  binary
         a + 1 -> a[x]
         decimal
         a - c -> a[m]
         if n/c go to L03443
         binary
         a - c -> c[x]
         if n/c go to L03470
         a exchange c[x]
         c -> a[x]
         p <- 1
         if a[p] # 0
           then go to L03501
         load constant 0
         load constant 10
         p <- 1
         a - c -> c[wp]
         if n/c go to L03501
         load constant 0
         load constant 6
         go to L03501

L03470:  if c[x] # 0
           then go to L02032
         p <- 1
         load constant 1
         load constant 13
         c -> a[x]
         p <- 1
         load constant 0
         load constant 11
L03501:  c -> data address
         data -> c
         go to L03574

L03504:  jsb S03411
         delayed rom @15
         jsb S06405
L03507:  b exchange c[w]
         b -> c[w]
         jsb S03414
         m2 -> c
         c -> data
         0 -> c[w]
         c -> data address
         b exchange c[w]
         c -> register 15
         jsb S03542
         b exchange c[w]
         0 -> c[w]
         go to L03612

L03524:  jsb S03411
         jsb S03414
         m2 exchange c
         if s 9 = 1
           then go to L03532
         c -> stack
L03532:  jsb S03411
         delayed rom @14
         jsb S06207
L03535:  c -> data
         delayed rom @04
         go to L02115

S03540:  jsb S03411
         jsb S03414
S03542:  0 -> c[x]
         p <- 0
         binary
         load constant 9
         a - c -> a[x]
         p <- 0
         load constant 7
         b exchange c[x]
         b -> c[x]
         p <- 1
         go to L03556

L03555:  c + 1 -> c[x]
L03556:  a - b -> a[wp]
         if n/c go to L03555
         a + b -> a[wp]
         c -> data address
         data -> c
         a exchange c[w]
         p <- 2
         load constant 6
         go to L03572

L03567:  rotate left a
         rotate left a
         c - 1 -> c[xs]
L03572:  c - 1 -> c[wp]
         if n/c go to L03567
L03574:  decimal
         return

L03576:  jsb S03540
         b exchange c[w]
         m2 -> c
         if c[s] # 0
           then go to L02032
         jsb S03641
         c - 1 -> c[x]
         if n/c go to L03610
         0 -> c[x]
         shift right c[m]
L03610:  if c[x] # 0
           then go to L02032
L03612:  p <- 12
         a exchange c[wp]
         p <- 10
         if a[wp] # 0
           then go to L02032
         a exchange c[wp]
         b exchange c[w]
L03621:  rotate left a
L03622:  rotate left a
         c - 1 -> c[xs]
         if n/c go to L03621
         a exchange c[w]
         go to L03535

S03627:  0 -> a[s]
         p <- 10
         0 -> a[wp]
         p <- 12
         if a[p] # 0
           then go to L03637
         shift left a[m]
         go to L03640

L03637:  a + 1 -> a[x]
L03640:  a exchange c[w]
S03641:  p <- 12
         1 -> s 13
         if c[w] = 0
           then go to L03651
         0 -> s 13
         c - 1 -> c[p]
         if c[w] = 0
           then go to L03652
L03651:  c + 1 -> c[p]
L03652:  return

L03653:  jsb S03540
         jsb S03627
         delayed rom @04
         go to L02111

L03657:  jsb S03773
         jsb S03765
         binary
         p <- 1
         load constant 1
         load constant 15
         c -> stack
         c -> stack
L03667:  load constant 5
         if p # 13
           then go to L03667
         delayed rom @15
         jsb S06737
         b exchange c[w]
         a exchange c[w]
         down rotate
         c -> a[w]
         down rotate
         c + c -> c[w]
         jsb S03772
         down rotate
         b -> c[w]
         1 -> s 4
         delayed rom @15
         jsb S06744
         a - c -> a[w]
         0 -> c[w]
         p <- 2
         load constant 1
         load constant 15
         jsb S03772
         down rotate
         stack -> a
         jsb S03772
         0 -> c[w]
         p <- 1
         load constant 2
         load constant 3
         jsb S03765
         m1 exchange c
         m1 -> c
         p <- 0
L03731:  c -> data address
         c -> data
         c - 1 -> c[p]
         if n/c go to L03731
         m1 -> c
L03736:  c -> data address
         a exchange c[w]
         data -> c
         jsb S03772
         c - 1 -> c[p]
         if n/c go to L03736
         jsb S03765
         delayed rom @02
         jsb S01377
         jsb S03763
         delayed rom @04
         jsb S02035
         delayed rom @10
         jsb S04371
         delayed rom @04
         jsb S02020
         jsb S03763
         delayed rom @16
         jsb S07377
         jsb S03763
         go to L03410

S03763:  if s 5 = 1
           then go to L03405
S03765:  m2 exchange c
         p <- 12
         c + 1 -> c[p]
         m2 exchange c
         return

S03772:  a - c -> a[w]
S03773:  if a[w] # 0
           then go to L03405
         return

         nop

	 .dw @1410			; CRC, bank 0 quad 1 (@00000..@03777)

S04000:  select rom go to L00001

S04001:  select rom go to L00002

S04002:  select rom go to L06403

S04003:  select rom go to L00004

S04004:  select rom go to L00005

S04005:  select rom go to L06006

         nop

L04007:  go to S04356

L04010:  select rom go to L00011

S04011:  select rom go to L06012

S04012:  0 -> c[w]
         c -> data address
         register -> c 15
         return

         p <- 6
         go to L04140

S04020:  register -> c 8
         delayed rom @07
         go to S03414

S04023:  jsb S04020
         m1 exchange c
S04025:  delayed rom @07
         jsb S03542
         delayed rom @07
         jsb S03627
         a exchange c[w]
         go to S04011

S04033:  0 -> c[w]
         p <- 1
         load constant 1
         c -> data address
         return

L04040:  display off
         0 -> s 1
         0 -> s 10
         jsb S04011
         c -> register 8
L04045:  0 -> s 8
         0 -> s 11
         0 -> s 14
         0 -> c[w]
         c -> register 6
         c -> register 7
L04053:  jsb S04023
         m1 -> c
         a exchange c[w]
         if s 14 = 1
           then go to L04142
         jsb S04003
         if c[m] = 0
           then go to L04074
         1 -> s 14
         if c[s] = 0
           then go to L04070
         0 - c - 1 -> c[s]
         1 -> s 8
L04070:  c -> register 6
L04071:  c -> register 7
         register -> c 8
         c -> register 5
L04074:  register -> c 8
         if s 10 = 1
           then go to L04126
         jsb S04002
         c -> register 8
         0 - c - 1 -> c[s]
         a exchange c[w]
         jsb S04012
         jsb S04000
         b exchange c[w]
         register -> c 15
         c -> a[w]
         jsb S04011
         a exchange c[w]
         if b[s] = 0
           then go to L04053
         c -> register 8
         register -> c 6
         if c[m] = 0
           then go to L05071
         1 -> s 10
         if 0 = s 11
           then go to L04045
         register -> c 5
         jsb S04002
         go to L04225

L04126:  jsb S04005
         c -> register 8
         if c[s] = 0
           then go to L04053
         register -> c 6
         if c[m] = 0
           then go to L05071
         if s 11 = 1
           then go to L04224
         p <- 7
L04140:  delayed rom @04
         go to L02004

L04142:  if 0 = s 8
           then go to L04145
         0 - c - 1 -> c[s]
L04145:  jsb S04003
         register -> c 6
         jsb S04001
         c -> register 6
         if s 11 = 1
           then go to L04167
         if c[s] = 0
           then go to L04157
         1 -> s 11
         go to L04074

L04157:  0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 7
         jsb S04000
         if c[s] = 0
           then go to L04074
         register -> c 6
         go to L04071

L04167:  if c[s] # 0
           then go to L04074
         jsb S04012
         m1 exchange c
         jsb S04011
         m1 -> c
         c -> register 8
         0 -> c[w]
         c -> register 6
L04200:  jsb S04023
         register -> c 6
         jsb S04000
         c -> register 6
         register -> c 8
         jsb S04002
         c -> register 8
         if c[s] # 0
           then go to L04200
         register -> c 6
         c -> a[w]
         jsb S04033
         0 -> c[w]
         p <- 12
         load constant 5
         c - 1 -> c[x]
         jsb S04003
         c -> register 15
         p <- 3
         go to L04140

L04224:  register -> c 5
L04225:  c -> a[w]
         jsb S04033
         if a[x] # 0
           then go to L04232
         shift right a[m]
L04232:  shift right a[m]
         register -> c 14
         p <- 11
         a exchange c[wp]
         p <- 9
         a exchange c[wp]
         c -> register 14
         m2 -> c
         if s 9 = 1
           then go to L04245
         c -> stack
L04245:  jsb S04011
         0 -> s 11
         c -> register 8
         m2 exchange c
L04251:  0 -> c[w]
         c -> register 5
         c -> register 7
L04254:  display toggle
         jsb S04023
         m1 -> c
         jsb S04003
         register -> c 7
         jsb S04001
         c -> register 7
         jsb S04023
         a exchange c[w]
         jsb S04005
         0 -> c[w]
         load constant 5
         c - 1 -> c[x]
         jsb S04004
         m2 -> c
         jsb S04001
         m1 exchange c
         jsb S04020
         jsb S04025
         m1 -> c
         jsb S04003
         m1 exchange c
         jsb S04020
         c -> a[w]
         jsb S04011
         m1 -> c
         jsb S04003
         register -> c 5
         jsb S04001
         c -> register 5
         jsb S04023
         m2 -> c
         jsb S04000
         m2 exchange c
         register -> c 8
         jsb S04002
         c -> register 8
         c -> a[w]
         if s 11 = 1
           then go to L04475
         register -> c 5
         m1 exchange c
         jsb S04033
         register -> c 14
         a exchange c[w]
         p <- 9
         0 -> a[wp]
         shift left a[w]
         if c[x] # 0
           then go to L04337
         shift right c[m]
L04337:  a exchange c[w]
         if a >= c[m]
           then go to L04344
L04342:  jsb S04011
         go to L04254

L04344:  m2 -> c
         c -> register 15
         jsb S04012
         m1 -> c
         c -> register 14
         1 -> s 11
         jsb S04011
         register -> c 7
         c -> register 6
         go to L04251

S04356:  0 -> c[w]
         c -> data address
         register -> c 14
         c - 1 -> c[x]
         c - 1 -> c[x]
         if c[s] = 0
           then go to L04437
         if c[xs] # 0
           then go to L04437
L04367:  p <- 5
         go to L04140

S04371:  rom checksum

         nop
         nop
         nop
         nop
         nop
         nop

S04400:  select rom go to L00001

S04401:  select rom go to L00002

S04402:  select rom go to L06403

S04403:  select rom go to L00004

S04404:  select rom go to L00005

S04405:  select rom go to L00006

S04406:  select rom go to L00007

S04407:  select rom go to L04010

S04410:  select rom go to S04011

S04411:  select rom go to S04012

S04412:  select rom go to L06013

S04413:  select rom go to L06014

S04414:  select rom go to L06015

S04415:  select rom go to L06016

S04416:  select rom go to L06017

S04417:  delayed rom @10
         go to S04025

S04421:  delayed rom @00
         go to S00367

         nop
S04424:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         go to S04413

S04430:  register -> c 9
         p <- 11
         0 -> c[wp]
         if c[s] = 0
           then go to L04437
         c + 1 -> c[x]
         shift right c[ms]
L04437:  return

S04440:  1 -> s 4
         display off
         display toggle
         delayed rom @01
         go to S00646

S04445:  m1 exchange c
         m1 -> c
         0 -> c[x]
S04450:  delayed rom @00
         go to S00362

S04452:  jsb S04430
S04453:  delayed rom @07
         go to S03414

L04455:  jsb S04411
         m2 -> c
         c -> register 14
         decimal
         0 -> s 12
L04462:  jsb S04411
         jsb S04453
         delayed rom @10
         jsb S04356
         jsb S04402
         0 -> s 1
         m2 -> c
         if s 9 = 1
           then go to L04533
         c -> stack
         go to L04533

L04475:  0 - c - 1 -> c[s]
         c -> a[w]
         jsb S04411
         jsb S04400
         if c[s] = 0
           then go to L04342
         register -> c 14
         c -> a[w]
         jsb S04410
         register -> c 6
         0 - c - 1 -> c[s]
         jsb S04406
         m2 exchange c
         register -> c 5
         c -> a[w]
         register -> c 7
         jsb S04406
         m2 -> c
         jsb S04401
         delayed rom @00
         jsb S00355
         jsb S04413
         register -> c 8
         c -> a[w]
         register -> c 7
         0 - c - 1 -> c[s]
         jsb S04406
         jsb S04440
         display off
         0 -> s 12
L04533:  jsb S04413
         1 -> s 9
L04535:  0 -> s 15
         if s 15 = 1
           then go to L04535
L04540:  0 -> a[w]
         0 -> b[w]
         0 -> s 11
         jsb S04413
         jsb S04415
         p <- 0
         0 -> b[p]
         jsb S04413
         jsb S04411
         a exchange c[w]
         if s 12 = 1
           then go to L04556
         0 -> c[w]
         c -> register 14
L04556:  shift left a[ms]
         if a[x] # 0
           then go to L04562
         shift right a[ms]
L04562:  jsb S04410
         register -> c 9
         p <- 11
         c -> a[wp]
         a exchange c[w]
         c -> register 9
         if s 15 = 1
           then go to L05065
         jsb S04452
         jsb S04417
         if s 13 = 1
           then go to L05074
         a exchange c[w]
         0 - c - 1 -> c[s]
         jsb S04424
         jsb S04415
         jsb S04440
         display off
         m2 exchange c
         jsb S04416
         jsb S04405
         if c[xs] = 0
           then go to L04613
         c + c -> c[x]
         if n/c go to L04765
L04613:  jsb S04413
         jsb S04416
         jsb S04413
         jsb S04421
         if c[m] = 0
           then go to L04625
         jsb S04416
         jsb S04407
         jsb S04413
         go to L04632

L04625:  jsb S04452
         jsb S04417
         a exchange c[w]
         0 - c - 1 -> c[s]
         jsb S04424
L04632:  jsb S04452
         0 - c - 1 -> c[s]
         b exchange c[w]
         jsb S04414
         jsb S04404
         jsb S04416
         delayed rom @00
         jsb S00021
         m1 exchange c
         jsb S04413
         if s 12 = 1
           then go to L04772
         jsb S04452
         jsb S04417
         jsb S04411
         m1 -> c
         jsb S04403
         0 - c - 1 -> c[s]
         a exchange c[w]
         register -> c 14
         a exchange c[w]
         c -> register 14
         m2 -> c
         jsb S04403
         register -> c 14
         jsb S04401
         c -> register 14
         jsb S04416
         jsb S04413
         jsb S04452
         jsb S04417
         a exchange b[w]
         jsb S04416
         jsb S04401
         jsb S04413
         jsb S04415
         jsb S04421
         if c[m] = 0
           then go to L04704
         jsb S04412
         jsb S04450
         go to L04720

L04704:  jsb S04412
         jsb S04452
         jsb S04417
         a exchange c[w]
         c -> register 7
         jsb S04402
         register -> c 7
         jsb S04404
         0 -> c[w]
         load constant 5
         c - 1 -> c[x]
         jsb S04404
L04720:  jsb S04413
         jsb S04452
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         jsb S04412
         jsb S04405
         jsb S04411
         register -> c 14
         jsb S04401
         c -> register 14
L04733:  jsb S04410
         jsb S04430
         delayed rom @14
         jsb S06207
         c -> a[w]
         if c[s] = 0
           then go to L04556
         jsb S04415
         if s 12 = 1
           then go to L05125
         if b[m] = 0
           then go to L05065
         jsb S04411
         register -> c 14
         jsb S04445
         delayed rom @10
         jsb S04033
         register -> c 15
         jsb S04401
         0 -> c[wp]
         load constant 1
         load constant 5
         a exchange c[x]
         c -> a[x]
         delayed rom @12
         go to L05030

L04765:  c - 1 -> c[xs]
         c - 1 -> c[xs]
         if c[xs] # 0
           then go to L05131
         go to L04613

L04772:  jsb S04416
L04773:  jsb S04413
         display off
         go to L04733

         nop
         nop

S05000:  select rom go to L00001

S05001:  select rom go to L00002

S05002:  select rom go to L00003

S05003:  select rom go to L06404

S05004:  select rom go to L00005

S05005:  select rom go to L00006

S05006:  select rom go to L04007

S05007:  select rom go to L04010

S05010:  select rom go to S04011

S05011:  select rom go to S04012

S05012:  select rom go to L06013

S05013:  select rom go to L06014

S05014:  select rom go to L06015

S05015:  select rom go to L06016

S05016:  select rom go to L06017

S05017:  select rom go to S00420

S05020:  select rom go to S04421

S05021:  m1 exchange c
         0 -> s 3
S05023:  select rom go to S04424

S05024:  jsb S05001
         jsb S05014
         delayed rom @00
         go to S00362

L05030:  c + c -> c[x]
         if n/c go to L05037
L05032:  0 -> c[x]
         c -> a[w]
         a -> b[w]
L05035:  a exchange b[m]
         go to L05054

L05037:  if a[x] # 0
           then go to L05045
         a exchange b[m]
         if a >= c[m]
           then go to L05035
         go to L05032

L05045:  p <- 1
         0 -> c[x]
         load constant 1
         a - c -> c[x]
         if n/c go to L05053
         go to L05054

L05053:  1 -> s 12
L05054:  jsb S05014
         jsb S05007
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S05012
         jsb S05002
         jsb S05013
         if 0 = s 12
           then go to L04540
L05065:  jsb S05014
L05066:  jsb S05020
         c + 1 -> c[x]
         c + 1 -> c[x]
L05071:  jsb S05142
         c -> register 14
         go to L05245

L05074:  display off
         display toggle
         if s 12 = 1
           then go to L05113
         jsb S05015
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
         jsb S05011
         register -> c 14
         jsb S05024
         c -> a[w]
         jsb S05011
         a exchange c[w]
         c -> register 14
L05113:  jsb S05010
         delayed rom @11
         jsb S04452
         b exchange c[w]
         jsb S05015
         jsb S05024
         jsb S05013
         jsb S05015
         delayed rom @11
         go to L04773

L05125:  jsb S05256
L05126:  jsb S05142
         c -> register 13
         go to L05245

L05131:  a exchange c[x]
         if s 12 = 1
           then go to L05126
         jsb S05016
         jsb S05020
         jsb S05142
         c -> register 14
         delayed rom @07
         go to L03622

S05142:  b exchange c[w]
         jsb S05011
         b -> c[w]
         delayed rom @03
         go to S01572

L05147:  jsb S05011
         0 -> s 12
         0 - c - 1 -> c[s]
         m1 exchange c
         register -> c 12
         c -> a[w]
         register -> c 11
         go to L05167

L05157:  0 -> s 10
         1 -> s 12
         jsb S05011
         m1 exchange c
         register -> c 12
         0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 13
L05167:  0 - c - 1 -> c[s]
         b exchange c[w]
         jsb S05010
         b exchange c[w]
         c -> register 6
         a exchange c[w]
         c -> register 7
         jsb S05006
         jsb S05021
         m1 -> c
         0 -> b[w]
         b exchange c[m]
         c -> a[w]
         if b[m] = 0
           then go to L05221
         1 -> s 4
         1 -> s 6
         delayed rom @17
         jsb S07761
         jsb S05017
         jsb S05006
         delayed rom @00
         jsb S00224
         jsb S05010
         jsb S05017
         go to L05222

L05221:  jsb S05003
L05222:  register -> c 7
         jsb S05004
         jsb S05017
         if s 10 = 1
           then go to L05231
         register -> c 8
         jsb S05004
L05231:  if s 3 = 1
           then go to L05235
         jsb S05013
         jsb S05253
L05235:  if s 10 = 1
           then go to L05260
         jsb S05012
         jsb S05002
         if 0 = s 12
           then go to L05126
         jsb S05142
         c -> register 11
L05245:  m2 exchange c
         if s 9 = 1
           then go to L05251
         c -> stack
L05251:  delayed rom @04
         go to L02161

S05253:  jsb S05006
         delayed rom @15
         jsb S06405
S05256:  jsb S05012
         go to S05005

L05260:  jsb S05017
         jsb S05011
         register -> c 13
         0 - c - 1 -> c[s]
         jsb S05001
         jsb S05012
         jsb S05373
         0 - c - 1 -> c[s]
         jsb S05142
         c -> register 12
         go to L05245

L05273:  jsb S05011
         register -> c 13
         0 -> s 10
         c -> a[w]
         register -> c 11
         jsb S05000
         jsb S05013
         jsb S05011
         register -> c 12
         0 - c - 1 -> c[s]
         m1 exchange c
         jsb S05006
         jsb S05023
         jsb S05021
         if s 3 = 1
           then go to L05315
         jsb S05253
         jsb S05013
L05315:  jsb S05015
         jsb S05011
         register -> c 11
         jsb S05367
         m1 exchange c
         register -> c 7
         if c[m] = 0
           then go to L05365
         jsb S05015
         jsb S05005
         0 - c - 1 -> c[s]
         c -> a[s]
         if c[s] = 0
           then go to L05347
         if c[m] = 0
           then go to L05362
         1 -> s 10
         jsb S05015
         jsb S05011
         register -> c 13
         0 - c - 1 -> c[s]
         jsb S05367
         jsb S05015
         jsb S05005
         if c[s] # 0
           then go to L04367
L05347:  delayed rom @17
         jsb S07760
         jsb S05013
         jsb S05016
         delayed rom @17
         jsb S07760
         jsb S05014
         jsb S05007
         if s 10 = 1
           then go to L05362
         0 - c - 1 -> c[s]
L05362:  jsb S05142
         c -> register 15
         go to L05245

L05365:  m1 -> c
         go to L05362

S05367:  jsb S05004
         jsb S05014
         jsb S05002
         jsb S05016
S05373:  if c[m] = 0
           then go to L04367
         go to S05007

L05376:  a exchange c[w]
         register -> c 12
S05400:  select rom go to L00001

S05401:  select rom go to L00002

         nop

S05403:  register -> c 12
S05404:  select rom go to L00005

S05405:  load constant 2
S05406:  select rom go to L00007

S05407:  select rom go to L00010

S05410:  select rom go to S04011

S05411:  select rom go to S04012

S05412:  select rom go to L06013

S05413:  select rom go to L06014

S05414:  jsb S05411
         0 - c - 1 -> c[s]
         delayed rom @15
         go to S06405

S05420:  c -> a[w]
         p <- 1
         load constant 2
         c -> data address
         a exchange c[w]
         c -> register 5
S05426:  0 -> c[w]
         c -> data address
         if s 14 = 1
           then go to L05450
L05432:  register -> c 13
         if s 11 = 1
           then go to L05376
         go to L05453

S05436:  c -> a[w]
         p <- 1
         load constant 2
         c -> data address
         a exchange c[w]
         c -> register 6
S05444:  0 -> c[w]
         c -> data address
         if s 14 = 1
           then go to L05432
L05450:  register -> c 11
         if 0 = s 11
           then go to L05376
L05453:  c -> a[w]
         0 -> b[w]
         a exchange b[m]
         return

S05457:  jsb S05436
         jsb S05420
         jsb S05410
         register -> c 5
         0 - c - 1 -> c[s]
         jsb S05404
         if c[s] # 0
           then go to L04367
         c -> register 7
         register -> c 6
         c -> a[w]
         register -> c 5
         c -> register 6
         0 -> c[w]
         jsb S05405
S05476:  jsb S05411
         jsb S05403
         m1 exchange c
         jsb S05410
         m1 -> c
         c -> register 5
         jsb S05404
         register -> c 7
         jsb S05401
         delayed rom @00
         jsb S00275
         register -> c 5
S05512:  c -> a[s]
S05513:  register -> c 5
         go to S05401

L05515:  0 -> c[w]
         c - 1 -> c[w]
         load constant 4
         c + 1 -> c[m]
         p <- 0
         load constant 7
         jsb S05401
         if c[s] = 0
           then go to L04367
         0 -> c[w]
         load constant 1
         c -> register 15
L05531:  register -> c 15
         if c[m] = 0
           then go to L04367
         delayed rom @00
         jsb S00352
         jsb S05413
         jsb S05444
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S05413
         jsb S05426
         if b[w] = 0
           then go to L04367
         jsb S05412
         delayed rom @00
         jsb S00362
         if a[s] # 0
           then go to L04367
         delayed rom @01
         jsb S00646
         delayed rom @12
         go to L05066

S05557:  c -> register 6
         0 -> c[w]
         load constant 2
         c -> a[w]
         jsb S05411
         jsb S05406
S05565:  jsb S05413
         register -> c 7
         delayed rom @01
         go to S00643

S05571:  if b[m] = 0
           then go to L04367
S05573:  delayed rom @11
         go to S04445

L05575:  0 -> s 3
         1 -> s 11
         if 0 = s 3
           then go to L05602
         0 -> s 11
L05602:  0 -> s 12
         0 -> s 14
         jsb S05414
         register -> c 15
         if c[s] # 0
           then go to L04367
         jsb S05403
         if c[m] = 0
           then go to L05531
         jsb S05414
         if c[s] = 0
           then go to L05515
         jsb S05403
         jsb S05420
         jsb S05436
         m1 exchange c
         jsb S05410
         m1 -> c
         c -> register 7
         register -> c 6
         jsb S05401
         0 - c - 1 -> c[s]
         jsb S05512
         c -> register 5
         register -> c 6
         0 - c - 1 -> c[s]
         a exchange c[w]
         register -> c 7
         jsb S05400
         register -> c 5
         jsb S05571
         if c[m] = 0
           then go to L05071
         if c[s] = 0
           then go to L05646
         1 -> s 14
L05646:  jsb S05414
         jsb S05457
         c -> register 5
         register -> c 6
         jsb S05571
         if c[s] # 0
           then go to L05705
         if c[m] = 0
           then go to L05705
         jsb S05557
         c -> a[w]
         jsb S05411
         a exchange c[w]
         c -> register 14
L05664:  m2 exchange c
         display toggle
         if s 9 = 1
           then go to L05671
         c -> stack
L05671:  jsb S05414
         m1 exchange c
         jsb S05410
         m1 -> c
         c -> register 5
         delayed rom @00
         jsb S00374
         register -> c 5
         if a[s] # 0
           then go to L05715
         a exchange c[s]
         go to L05762

L05705:  1 -> s 12
         jsb S05426
         jsb S05410
         register -> c 5
         jsb S05571
         if c[s] # 0
           then go to L04367
         go to L05664

L05715:  jsb S05404
         0 -> c[w]
         load constant 6
         jsb S05407
         jsb S05411
         jsb S05407
         jsb S05403
         jsb S05420
         jsb S05410
         jsb S05513
         c -> register 7
         jsb S05436
         jsb S05410
         jsb S05513
         if s 12 = 1
           then go to L05736
         c -> register 6
L05736:  register -> c 7
         jsb S05404
         0 - c - 1 -> c[s]
         c -> register 7
         if c[s] # 0
           then go to L05762
         jsb S05411
         delayed rom @00
         jsb S00352
         register -> c 15
         0 - c - 1 -> c[s]
         jsb S05401
         0 -> c[w]
         load constant 3
         jsb S05407
         jsb S05476
         register -> c 6
         if 0 = s 12
           then go to L05774
         jsb S05407
L05762:  if 0 = s 12
           then go to L05775
         if c[s] # 0
           then go to L05767
         m2 exchange c
L05767:  m2 -> c
         jsb S05557
         c -> register 6
         delayed rom @17
         go to L07417

L05774:  jsb S05573
L05775:  delayed rom @17
         go to L07507

	 .dw @1731			; CRC, bank 0 quad 2 (@04000..@05777)

L06000:  0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         delayed rom @01
         go to S00515

L06006:  go to S06207

L06007:  c -> a[x]
         go to L06107

         select rom go to S04012

L06012:  go to S06365

L06013:  go to S06240

L06014:  go to S06217

L06015:  go to L06025

L06016:  go to L06000

L06017:  0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         delayed rom @01
         go to S00532

L06025:  0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         delayed rom @01
         go to S00535

S06033:  p <- 12
         c -> a[w]
         if c[xs] # 0
           then go to L06056
L06037:  shift left a[m]
         p - 1 -> p
         if a[m] # 0
           then go to L06053
L06043:  0 -> c[wp]
         a exchange c[x]
         m1 exchange c
         0 -> c[x]
         c - 1 -> c[x]
         a exchange c[s]
         delayed rom @00
         go to S00114

L06053:  c - 1 -> c[x]
         if n/c go to L06037
         go to L06043

L06056:  0 -> c[w]
         m1 exchange c
         a exchange c[w]
         return

S06062:  0 -> a[w]
         p <- 12
         f -> a[x]
L06065:  if p = 2
           then go to L06126
         p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L06065
         c -> a[w]
         a + c -> a[x]
         if n/c go to L06007
         c -> a[x]
L06076:  p + 1 -> p
         if p = 13
           then go to L06104
         a + 1 -> a[x]
         if n/c go to L06076
         go to L06113

L06104:  0 -> c[w]
         return

L06106:  p - 1 -> p
L06107:  if p = 2
           then go to L06126
         a - 1 -> a[x]
         if n/c go to L06106
L06113:  0 -> b[w]
         a -> b[wp]
         a + b -> a[m]
         if n/c go to L06124
         0 -> a[s]
         a + 1 -> a[s]
         c + 1 -> c[x]
         shift right a[w]
         p - 1 -> p
L06124:  0 -> a[wp]
         a exchange c[m]
L06126:  return

L06127:  jsb S06206
         jsb S06217
         jsb S06225
         jsb S06252
         jsb S06240
         jsb S06256
         jsb S06170
         c -> a[w]
         jsb S06365
         a exchange c[w]
         c -> register 6
         jsb S06206
         jsb S06217
         jsb S06160
         jsb S06252
         jsb S06240
         jsb S06256
         jsb S06170
         delayed rom @03
         jsb S01572
         delayed rom @03
         jsb S01630
         register -> c 6
         delayed rom @04
         go to L02006

S06160:  jsb S06373
         register -> c 3
         jsb S06246
         jsb S06217
         jsb S06373
         c -> a[w]
         register -> c 4
         go to L06234

S06170:  if a[s] # 0
           then go to L06562
         delayed rom @00
         go to S00275

S06174:  jsb S06373
         register -> c 1
         a exchange c[w]
         register -> c 3
         jsb S06247
         jsb S06217
         jsb S06373
         c -> a[w]
         register -> c 5
         go to L06234

S06206:  jsb S06373
S06207:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @00
         go to S00367

S06214:  0 - c - 1 -> c[s]
         delayed rom @00
         jsb S00016
S06217:  0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         delayed rom @01
         go to S00470

S06225:  jsb S06373
         register -> c 1
         jsb S06246
         jsb S06217
         jsb S06373
         c -> a[w]
         register -> c 2
L06234:  jsb S06250
         jsb S06240
S06236:  delayed rom @00
         go to S00021

S06240:  0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         delayed rom @01
         go to S00436

S06246:  c -> a[w]
S06247:  0 - c - 1 -> c[s]
S06250:  delayed rom @00
         go to S00171

S06252:  jsb S06373
S06253:  m1 exchange c
         m1 -> c
         0 -> c[x]
S06256:  if c[m] = 0
           then go to L06562
         delayed rom @00
         go to S00227

L06262:  jsb S06373
         register -> c 5
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         register -> c 1
         jsb S06253
         delayed rom @04
         go to L02111

L06273:  jsb S06174
         jsb S06217
         m2 -> c
         a exchange c[w]
         jsb S06373
         jsb S06250
         register -> c 3
         jsb S06214
         jsb S06225
         jsb S06362
         delayed rom @01
         jsb S00420
         jsb S06373
         register -> c 1
         go to L06330

L06312:  jsb S06225
         jsb S06217
         m2 -> c
         a exchange c[w]
         jsb S06373
         jsb S06250
         register -> c 1
         jsb S06214
         jsb S06174
         jsb S06362
         delayed rom @01
         jsb S00420
         jsb S06373
         register -> c 3
L06330:  delayed rom @00
         jsb S00173
         jsb S06240
         jsb S06236
         jsb S06240
         jsb S06256
         jsb S06252
         c -> a[w]
         jsb S06365
         a exchange c[w]
         c -> register 6
         jsb S06225
         jsb S06217
         jsb S06160
         jsb S06362
         jsb S06170
         jsb S06217
         jsb S06174
         jsb S06240
         jsb S06256
         delayed rom @03
         jsb S01572
         c -> stack
         register -> c 6
         delayed rom @04
         go to L02044

S06362:  jsb S06240
         delayed rom @00
         go to S00176

S06365:  p <- 1
         0 -> c[w]
         load constant 2
         c -> data address
         0 -> c[w]
         return

S06373:  0 -> c[w]
         c -> data address
         data -> c
         return

         nop
L06400:  p <- 3
L06401:  delayed rom @04
         go to L02004

L06403:  go to S06405

L06404:  go to L06410

S06405:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
L06410:  delayed rom @00
         go to S00374

L06412:  0 -> s 15
         0 -> s 3
         if s 15 = 1
           then go to L06412
         jsb S06554
         m2 -> c
         c -> register 5
         if c[m] = 0
           then go to L06400
         if c[s] # 0
           then go to L06400
         delayed rom @14
         jsb S06033
         if c[m] # 0
           then go to L06400
         0 -> c[w]
         c -> data address
         register -> c 13
         jsb S06556
         c -> register 13
         register -> c 12
         jsb S06556
         c -> register 12
         0 -> c[w]
         m2 exchange c
         if s 9 = 1
           then go to L06446
         c -> stack
L06446:  m2 -> c
         c -> stack
L06450:  register -> c 14
         c - 1 -> c[x]
         c - 1 -> c[x]
         a exchange c[w]
         register -> c 13
         delayed rom @00
         jsb S00171
         jsb S06556
         a exchange c[w]
         if s 3 = 1
           then go to L06467
         register -> c 15
         if c[m] # 0
           then go to L06467
         0 -> a[w]
L06467:  register -> c 12
         b exchange c[w]
         jsb S06554
         a exchange c[w]
         c -> register 6
         a exchange c[w]
         a exchange b[s]
         m2 -> c
         jsb S06550
         m2 exchange c
         register -> c 6
         a exchange c[w]
         0 -> c[w]
         c -> data address
         register -> c 12
         jsb S06550
         a exchange c[w]
         jsb S06554
         a exchange c[w]
         c -> register 6
         stack -> a
         jsb S06550
         c -> stack
         register -> c 6
         c -> a[w]
         0 -> c[w]
         c -> data address
         register -> c 13
         jsb S06550
         c -> register 13
         register -> c 15
         jsb S06405
         c -> register 15
         jsb S06554
         register -> c 5
         delayed rom @14
         jsb S06207
         c -> register 5
         if s 15 = 1
           then go to L06546
         if c[m] = 0
           then go to L06546
         display toggle
         0 -> c[x]
         c -> data address
         if c[s] = 0
           then go to L06450
L06546:  delayed rom @04
         go to L02115

S06550:  delayed rom @00
         jsb S00014
         delayed rom @03
         go to S01572

S06554:  delayed rom @14
         go to S06365

S06556:  delayed rom @14
         go to S06062

L06560:  p <- 8
         go to L06401

L06562:  p <- 2
         go to L06401

         p <- 9
         go to L06401

L06566:  1 -> s 10
L06567:  y -> a
         jsb S06554
         0 -> s 11
         0 -> s 3
         0 -> s 12
         0 -> s 13
         a exchange c[w]
         p <- 12
         go to L06777

L06600:  0 -> s 10
         delayed rom @14
         jsb S06033
         if c[m] # 0
           then go to L06560
         go to L06567

L06606:  delayed rom @16
         jsb S07263
         stack -> a
         c -> stack
         a exchange c[w]
         delayed rom @04
         go to L02044

L06615:  m1 exchange c
         stack -> a
         register -> c 5
         c -> a[w]
         0 -> c[w]
         c -> data address
         m1 -> c
         m2 exchange c
         c -> register 10
         p <- 5
         a + 1 -> a[p]
         jsb S06677
         delayed rom @00
         jsb S00222
         delayed rom @14
         jsb S06033
         jsb S06676
         delayed rom @00
         jsb S00171
         if c[x] # 0
           then go to L06714
         if c[m] = 0
           then go to L06714
L06644:  c -> a[w]
L06645:  p - 1 -> p
         rotate left a
         if p # 7
           then go to L06645
         m2 -> c
         binary
         c - 1 -> c[s]
         if c[x] # 0
           then go to L06657
         shift right c[w]
L06657:  p <- 4
         load constant 15
         a exchange c[w]
         a exchange c[p]
         delayed rom @10
         jsb S04033
         p <- 11
         load constant 3
         p <- 9
         load constant 3
         clear status
         b exchange c[w]
         0 -> s 1
         delayed rom @07
         go to L03404

S06676:  c -> a[w]
S06677:  0 -> c[w]
         p <- 12
         load constant 7
         return

L06703:  shift right c[w]
         if s 11 = 1
           then go to L06710
         if 0 = s 13
           then go to L07363
L06710:  if a >= c[p]
           then go to L07360
         delayed rom @16
         go to L07363

L06714:  load constant 7
         p <- 12
         go to L06644

L06717:  clear regs
         c + 1 -> c[w]
         m2 exchange c
         0 -> c[w]
         m2 exchange c
         m1 exchange c
         m1 exchange c
         down rotate
         down rotate
         down rotate
         b exchange c[w]
         a exchange b[w]
         f exchange a[x]
         f exchange a[x]
         delayed rom @07
         go to L03657

S06737:  c -> stack
         c + c -> c[w]
         down rotate
         down rotate
         0 -> s 4
S06744:  c -> data address
         b exchange c[w]
         data -> c
         a + c -> a[w]
         a exchange c[w]
         if s 4 = 1
           then go to L06772
         a + b -> a[w]
L06754:  a exchange c[w]
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
         if n/c go to S06744
         down rotate
         return

L06772:  a - b -> a[w]
         nop
         go to L06754

L06775:  c -> register 7
         m2 -> c
L06777:  if c[s] # 0
           then go to L06560
L07001:  jsb S07127
         p <- 4
         if c[wp] # 0
           then go to L06560
         jsb S07137
         0 -> c[w]
         p <- 11
         load constant 3
         if s 12 = 1
           then go to L06703
         p <- 11
         if a >= c[m]
           then go to L07022
         a - 1 -> a[m]
         p <- 4
         0 -> a[wp]
         p <- 12
L07022:  load constant 1
         a + c -> a[w]
         jsb S07247
         jsb S07173
         a exchange c[w]
         jsb S07265
         jsb S07223
         jsb S07266
         jsb S07230
         jsb S07255
         jsb S07154
         jsb S07265
L07036:  c -> register 5
         jsb S07163
         a - c -> c[x]
         0 -> c[m]
         jsb S07373
         jsb S07154
         jsb S07266
         jsb S07205
         load constant 1
         load constant 2
         load constant 1
         load constant 5
         jsb S07265
         jsb S07205
         jsb S07212
         p <- 8
         load constant 4
         jsb S07220
         jsb S07226
         jsb S07266
         jsb S07343
         jsb S07343
         jsb S07165
L07065:  jsb S07250
         jsb S07173
         a exchange c[w]
         jsb S07265
         jsb S07223
         jsb S07266
         register -> c 5
         jsb S07265
         jsb S07154
         jsb S07265
         jsb S07205
         jsb S07236
         jsb S07226
         jsb S07127
         p <- 11
         jsb S07117
         load constant 0
         load constant 4
         if a >= c[m]
           then go to L07300
         register -> c 8
         c - 1 -> c[m]
         p <- 3
         0 -> c[p]
         jsb S07172
         go to L07065

S07117:  shift right a[w]
         register -> c 8
         a exchange c[wp]
         p <- 9
         a exchange c[wp]
         c -> register 8
S07125:  c -> a[w]
         go to L07201

S07127:  c - 1 -> c[x]
         if n/c go to L07134
         0 -> c[x]
         shift right c[wp]
         go to L07276

L07134:  if c[x] # 0
           then go to L06560
         go to L07276

S07137:  if s 3 = 1
           then go to L07276
         c -> a[m]
         p <- 10
         shift left a[wp]
         shift left a[wp]
         jsb S07343
         a exchange c[m]
         shift left a[m]
         shift left a[m]
         a exchange c[wp]
         a exchange c[w]
         go to L07276

S07154:  jsb S07205
         load constant 4
         load constant 7
         load constant 8
         load constant 1
         load constant 6
         load constant 4
S07163:  p <- 0
         go to L07221

S07165:  shift right a[w]
         p <- 11
         register -> c 8
         a exchange c[wp]
         a exchange c[x]
S07172:  c -> register 8
S07173:  register -> c 8
         a exchange c[w]
         shift left a[m]
         shift left a[m]
S07177:  shift left a[m]
         shift left a[m]
L07201:  shift left a[m]
         0 -> a[x]
         a + 1 -> a[x]
         0 -> a[s]
S07205:  0 -> c[w]
         p <- 0
         load constant 2
         p <- 12
         return

S07212:  c -> register 6
         load constant 3
         load constant 6
         if s 12 = 1
           then go to L07222
         load constant 5
S07220:  load constant 2
L07221:  load constant 5
L07222:  return

S07223:  jsb S07173
         load constant 4
         0 -> c[x]
S07226:  delayed rom @00
         go to S00222

S07230:  register -> c 8
         p <- 9
         0 -> c[wp]
         jsb S07125
         jsb S07236
         go to L07252

S07236:  load constant 3
         load constant 0
         if s 12 = 1
           then go to L07245
         load constant 6
         p <- 7
         load constant 1
L07245:  c - 1 -> c[x]
         return

S07247:  jsb S07165
S07250:  c + c -> c[x]
         jsb S07212
L07252:  delayed rom @00
         jsb S00171
         go to S07266

S07255:  register -> c 8
         p <- 7
         0 -> c[wp]
         a exchange c[w]
         jsb S07177
         go to L07272

S07263:  c -> register 6
         register -> c 7
S07265:  0 - c - 1 -> c[s]
S07266:  delayed rom @14
         jsb S06033
         m1 -> c
         a exchange c[w]
L07272:  register -> c 6
S07273:  delayed rom @00
         jsb S00014
         c -> register 6
L07276:  c -> a[w]
         return

L07300:  jsb S07230
         jsb S07127
         jsb S07343
         p <- 7
         jsb S07117
         load constant 1
         load constant 4
         p <- 12
         if a >= c[m]
           then go to L07315
         load constant 9
         load constant 9
         go to L07321

L07315:  load constant 8
         load constant 7
         p <- 5
         load constant 1
L07321:  a + c -> c[m]
         jsb S07137
         c - 1 -> c[x]
         delayed rom @00
         jsb S00114
         c -> a[w]
         display toggle
         if s 11 = 1
           then go to L07346
         y -> a
         jsb S07372
         1 -> s 11
L07335:  if s 10 = 1
           then go to L06775
         c -> a[w]
         m2 -> c
         jsb S07273
         go to L07036

S07343:  shift right a[m]
         shift right a[m]
         return

L07346:  if 0 = s 10
           then go to L06615
         m2 -> c
         jsb S07372
         jsb S07263
         1 -> s 12
         stack -> a
         c -> stack
         a exchange c[w]
         go to L07001

L07360:  p <- 9
         1 -> s 13
         0 -> a[p]
L07363:  jsb S07247
         jsb S07230
         jsb S07255
         if 0 = s 11
           then go to L06606
         0 -> s 11
         go to L07335

S07372:  a - c -> c[w]
S07373:  if c[w] # 0
           then go to L06560
         register -> c 5
         return

S07377:  rom checksum

S07400:  select rom go to L00001

S07401:  select rom go to S05002

S07402:  jsb S07411
         register -> c 12
S07404:  select rom go to L00005

S07405:  select rom go to L00006

         nop

S07407:  select rom go to L04010

S07410:  select rom go to S04011

S07411:  select rom go to S04012

S07412:  select rom go to L06013

S07413:  select rom go to L06014

S07414:  select rom go to L06015

S07415:  select rom go to L06016

S07416:  select rom go to L06017

L07417:  m1 exchange c
         jsb S07411
         m1 -> c
         c -> register 14
         delayed rom @13
         jsb S05414
         1 -> s 4
         delayed rom @13
         jsb S05565
         jsb S07411
         register -> c 14
         0 - c - 1 -> c[s]
         delayed rom @15
         jsb S06405
         jsb S07412
         if b[m] = 0
           then go to L07442
         jsb S07505
         go to L07445

L07442:  jsb S07411
         delayed rom @14
         jsb S06207
L07445:  m2 -> c
         0 - c - 1 -> c[s]
         jsb S07404
         delayed rom @13
         jsb S05457
         delayed rom @13
         jsb S05420
         jsb S07410
         register -> c 5
         delayed rom @11
         jsb S04445
         m2 -> c
         jsb S07404
         jsb S07411
         register -> c 14
         delayed rom @00
         jsb S00224
         a exchange c[w]
         jsb S07410
         a exchange c[w]
         c -> register 6
         jsb S07411
         delayed rom @14
         jsb S06207
         delayed rom @00
         jsb S00355
         jsb S07413
         register -> c 7
         delayed rom @01
         jsb S00643
         go to L07554

S07504:  jsb S07415
S07505:  delayed rom @00
         go to S00362

L07507:  if c[s] # 0
           then go to L07513
         delayed rom @13
         jsb S05557
L07513:  c -> register 5
         delayed rom @13
         jsb S05444
         m1 exchange c
         register -> c 12
         0 - c - 1 -> c[s]
         c -> a[w]
         jsb S07410
         m1 -> c
         c -> register 6
         jsb S07400
         register -> c 6
         delayed rom @11
         jsb S04445
         m2 exchange c
         register -> c 5
         0 - c - 1 -> c[s]
         c -> a[w]
         m2 -> c
         jsb S07400
         register -> c 5
         if a[s] # 0
           then go to L07554
         jsb S07411
         register -> c 14
         0 - c - 1 -> c[s]
         c -> a[w]
         m2 -> c
         jsb S07400
         m2 -> c
         if a[s] # 0
           then go to L07554
         register -> c 14
L07554:  1 -> s 4
         0 -> b[w]
         b exchange c[m]
         c -> a[w]
L07560:  jsb S07413
         display toggle
         delayed rom @13
         jsb S05414
         jsb S07413
         jsb S07415
         delayed rom @01
         jsb S00646
         jsb S07413
         delayed rom @13
         jsb S05444
         jsb S07412
         jsb S07405
         jsb S07504
         jsb S07413
         jsb S07416
         jsb S07413
         a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         delayed rom @00
         jsb S00374
         jsb S07416
         if c[m] = 0
           then go to L07613
         jsb S07407
         go to L07616

L07613:  jsb S07411
         delayed rom @14
         jsb S06207
L07616:  jsb S07413
         jsb S07402
         jsb S07416
         jsb S07401
         jsb S07413
         delayed rom @13
         jsb S05426
         jsb S07412
         jsb S07401
         jsb S07413
         jsb S07416
         if c[m] = 0
           then go to L07723
         jsb S07413
         delayed rom @13
         jsb S05414
         jsb S07416
         jsb S07401
         jsb S07413
         jsb S07415
         a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         delayed rom @00
         jsb S00374
         jsb S07412
         if b[m] = 0
           then go to L07731
         jsb S07505
L07653:  jsb S07402
         jsb S07413
         delayed rom @13
         jsb S05426
         register -> c 15
         jsb S07404
         jsb S07412
         jsb S07401
         jsb S07504
         if 0 = s 12
           then go to L07673
         jsb S07413
         delayed rom @13
         jsb S05414
         jsb S07412
         jsb S07401
L07673:  if c[s] # 0
           then go to L07743
         0 -> c[w]
         load constant 1
         load constant 1
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L07752
L07704:  c -> a[w]
         a -> b[w]
L07706:  0 -> s 8
L07707:  jsb S07414
         jsb S07407
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S07412
         jsb S07401
         delayed rom @03
         jsb S01572
         if p # 12
           then go to L07723
         if 0 = s 8
           then go to L07560
L07723:  if 0 = s 14
           then go to L07727
         delayed rom @00
         jsb S00355
L07727:  delayed rom @12
         go to L05066

L07731:  delayed rom @13
         jsb S05414
         register -> c 15
         0 - c - 1 -> c[s]
         jsb S07404
         0 -> c[w]
         load constant 2
         delayed rom @00
         jsb S00224
         go to L07653

L07743:  0 -> c[x]
         1 -> s 8
         p <- 1
         load constant 1
         a - c -> c[x]
         if n/c go to L07707
         go to L07706

L07752:  if a[x] # 0
           then go to L07743
         c -> a[m]
         if a >= b[m]
           then go to L07704
         go to L07706

S07760:  0 -> s 6
S07761:  0 -> s 8
         0 -> b[s]
         a exchange c[w]
         c -> a[w]
         c + 1 -> c[x]
         delayed rom @01
         go to L00552

         nop
         nop
         nop
         nop
         nop
         nop
         nop

	 .dw @0360			; CRC, bank 0 quad 3 (@6000..@7777)

	 .bank 1
	 .org @2000

S12000:  rom checksum

L12001:  bank toggle

L12002:  go to L12046

         nop
L12004:  bank toggle

L12005:  go to L12204

L12006:  bank toggle

         go to L12071

L12010:  bank toggle

         go to L12073

         nop
S12013:  bank toggle

         go to L12132

L12015:  binary
         bank toggle

L12017:  return

L12020:  bank toggle

         jsb S12000
         go to L12006

L12023:  bank toggle

         delayed rom @07
         go to L13743

L12026:  bank toggle

         delayed rom @06
         a -> rom address

         bank toggle

         delayed rom @06
         go to L13077

         bank toggle

         go to L12125

         bank toggle

         go to L12105

         bank toggle

         jsb S12232
         go to L12006

         bank toggle

L12044:  delayed rom @07
         go to L13763

L12046:  display off
         jsb S12373
         a + 1 -> a[x]
         a + 1 -> a[x]
         f exchange a[x]
         jsb S12160
         a exchange c[w]
         register -> c 14
         p <- 8
         c -> a[x]
         a - c -> a[wp]
         if a[wp] # 0
           then go to L12135
         p <- 1
         0 -> c[wp]
         c -> register 14
         clear regs
         c -> data address
         c -> register 10
L12071:  clear status
L12072:  0 -> s 1
L12073:  jsb S12013
         m2 exchange c
         if p # 10
           then go to L12100
         0 -> s 2
L12100:  jsb S12373
         m2 -> c
         if s 2 = 1
           then go to L13651
         jsb S12272
L12105:  if s 2 = 1
           then go to L13651
         jsb S12232
L12110:  0 -> a[x]
L12111:  0 -> s 12
         decimal
         display off
         display toggle
L12115:  0 -> s 15
         if s 15 = 1
           then go to L12115
L12120:  if 0 = s 15
           then go to L12120
         display off
         if p # 3
           then go to L12400
L12125:  m2 -> c
L12126:  if s 0 = 1
           then go to L13521
         if 0 = s 9
           then go to L12071
L12132:  clear status
         1 -> s 9
         go to L12072

L12135:  jsb S12170
         p <- 1
         load constant 1
         jsb S12174
         0 -> c[w]
         jsb S12160
         p <- 2
         load constant 13
         c -> register 14
         0 -> c[w]
         m2 exchange c
         clear regs
         0 -> c[w]
         c - 1 -> c[w]
         p <- 8
         load constant 13
         load constant 10
         load constant 15
         go to L12216

S12160:  p <- 8
L12161:  load constant 14
         load constant 3
         load constant 2
         load constant 13
         load constant 8
         load constant 5
         return

S12170:  0 -> c[x]
S12171:  p <- 0
         binary
         0 -> a[w]
S12174:  c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
         c + 1 -> c[p]
         if n/c go to S12174
         return

L12203:  p <- 4
L12204:  0 -> c[w]
         0 -> s 2
         binary
         c - 1 -> c[w]
         0 -> b[w]
L12211:  p - 1 -> p
         c + 1 -> c[xs]
         if p # 13
           then go to L12211
         p <- 8
L12216:  load constant 14
         load constant 10
         load constant 10
         load constant 12
         load constant 10
         a exchange c[w]
         shift left a[w]
         shift left a[w]
         shift left a[w]
L12227:  jsb S12373
         p <- 3
         go to L12110

S12232:  m2 -> c
         b exchange c[w]
         0 -> c[w]
         if 0 = s 8
           then go to L12241
         p <- 5
         load constant 6
L12241:  a exchange c[s]
         c -> a[s]
         p <- 12
         if b[s] = 0
           then go to L12251
         load constant 4
         p <- 13
L12250:  p - 1 -> p
L12251:  c - 1 -> c[s]
         if n/c go to L12250
L12253:  c + 1 -> c[p]
         if p = 12
           then go to L12270
         p + 1 -> p
         if p = 12
           then go to L12270
         p + 1 -> p
         if p = 12
           then go to L12270
         p + 1 -> p
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L12253
L12270:  b exchange c[w]
         return

S12272:  0 -> a[w]
         f -> a[x]
         c -> a[m]
         m1 exchange c
         m1 -> c
         p <- 12
         0 -> c[s]
L12301:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L12301
         if p = 1
           then go to L12321
         if c[xs] # 0
           then go to L12337
L12310:  c - 1 -> c[x]
         if n/c go to L12314
         0 -> a[x]
         go to L12343

L12314:  if p = 2
           then go to L12317
         p - 1 -> p
L12317:  c + 1 -> c[s]
         if n/c go to L12310
L12321:  m1 -> c
         0 -> c[s]
         p <- 1
         if c[xs] = 0
           then go to L12327
         0 - c -> c[wp]
L12327:  p <- 5
         c -> a[w]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         1 -> s 8
         p <- 2
         go to L12356

L12337:  0 -> a[x]
L12340:  shift right a[w]
         c + 1 -> c[x]
         if n/c go to L12340
L12343:  0 -> b[w]
         a -> b[wp]
         a exchange b[w]
         a + b -> a[w]
         if a[ms] # 0
           then go to L12361
         if c[m] # 0
           then go to L12321
L12353:  if a[s] # 0
           then go to L12367
L12355:  c -> a[s]
L12356:  binary
         a - 1 -> a[wp]
         return

L12361:  0 -> a[wp]
         if a[w] # 0
           then go to L12353
         p - 1 -> p
         a exchange b[w]
         go to L12343

L12367:  c + 1 -> c[s]
         p - 1 -> p
         shift right a[w]
         go to L12355

S12373:  p <- 1
         0 -> c[w]
         load constant 1
         c -> data address
         return

L12400:  binary
         0 -> c[w]
         keys -> rom address

L12403:  a - 1 -> a[x]
L12404:  a - 1 -> a[x]
L12405:  a - 1 -> a[x]
L12406:  a - 1 -> a[x]
         p <- 4
L12410:  a - 1 -> a[x]
L12411:  a - 1 -> a[x]
L12412:  0 -> s 14
L12413:  shift left a[x]
L12414:  delayed rom @04
         go to L12111

L12416:  if p = 10
           then go to L12526
         if p = 8
           then go to L12451
         p <- 11
         go to L12633

L12424:  a + 1 -> a[x]
L12425:  if p = 5
           then go to L12444
         if p = 1
           then go to L12660
         if p = 4
           then go to L12444
         a + 1 -> a[x]
         shift left a[x]
         if p # 2
           then go to L12440
         p <- 12
L12440:  p + 1 -> p
         a - 1 -> a[x]
         if p # 13
           then go to L12440
L12444:  0 -> s 14
L12445:  delayed rom @07
         go to L13525

L12447:  p <- 7
         go to L12541

L12451:  p <- 1
         load constant 11
         go to L12556

L12454:  a - 1 -> a[p]
         if s 14 = 1
           then go to L12023
         go to L12445

         go to L12472

         go to L12664

         go to L12701

         a + 1 -> a[x]
         nop
         nop
         if p # 2
           then go to L12703
         p <- 8
         go to L12534

L12472:  if p # 2
           then go to L12677
         p <- 10
         go to L12574

L12476:  p <- 10
         go to L12633

         go to L12752

         go to L12742

         go to L12425

         if p = 8
           then go to L12670
         if p = 10
           then go to L12516
         if p = 9
           then go to L12406
         p <- 1
         load constant 13
L12513:  load constant 9
L12514:  a exchange c[x]
         go to L12444

L12516:  p <- 8
         go to L12535

L12520:  if p # 1
           then go to L12710
         1 -> s 14
         go to L12414

L12524:  p <- 7
         go to L12425

L12526:  p <- 1
         load constant 11
         go to L12614

L12531:  if p = 8
           then go to L13617
L12533:  a + 1 -> a[x]
L12534:  a + 1 -> a[x]
L12535:  a + 1 -> a[x]
         if p = 4
           then go to L12203
         a + 1 -> a[x]
L12541:  a + 1 -> a[x]
         if n/c go to L12717
         if p = 8
           then go to L13670
         if p = 10
           then go to L12737
         if p = 9
           then go to L12404
         p <- 1
         load constant 10
         go to L12513

L12554:  p <- 1
         load constant 10
L12556:  load constant 8
         go to L12514

         go to L12775

         go to L12575

         go to L12576

         if p = 9
           then go to L12020
         if p # 10
           then go to L12577
         if 0 = s 0
           then go to L13665
L12571:  p <- 12
         go to L12633

L12573:  a + 1 -> a[x]
L12574:  a + 1 -> a[x]
L12575:  a + 1 -> a[x]
L12576:  a + 1 -> a[x]
L12577:  a + 1 -> a[x]
L12600:  if p = 10
           then go to L12605
         if p = 8
           then go to L12605
         p <- 12
L12605:  p - 1 -> p
         go to L12715

L12607:  p <- 1
         load constant 12
         go to L12556

L12612:  p <- 1
         load constant 10
L12614:  load constant 7
         go to L12514

L12616:  p <- 2
         go to L12633

         go to L12673

         go to L12476

         go to L12573

         go to L12416

         nop
         nop
         if p = 10
           then go to L12612
         if p = 8
           then go to L12554
         p <- 9
L12633:  0 -> a[x]
         go to L12412

L12635:  if p = 8
           then go to L13164
         go to L12534

         go to L12531

         go to L12635

         go to L12654

         if p = 8
           then go to L13517
         if p = 10
           then go to L12734
         if p = 9
           then go to L12403
         p <- 1
         load constant 11
         go to L12513

L12654:  if p # 8
           then go to L12535
         p <- 1
         go to L12633

L12660:  if a[p] # 0
           then go to L12454
         a + 1 -> a[x]
         if n/c go to L12413
L12664:  if p # 2
           then go to L12700
         p <- 10
         go to L12577

L12670:  p <- 1
         load constant 13
         go to L12556

L12673:  if p = 11
           then go to L12616
         p <- 8
         go to L12633

L12677:  a + 1 -> a[x]
L12700:  a + 1 -> a[x]
L12701:  a + 1 -> a[x]
         a + 1 -> a[x]
L12703:  if p = 11
           then go to L12524
         if p = 9
           then go to L12447
         a + 1 -> a[x]
L12710:  if p = 10
           then go to L12715
         if p = 8
           then go to L12715
         p <- 12
L12715:  a + 1 -> a[x]
         if n/c go to L12533
L12717:  a + 1 -> a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
         if n/c go to L12424
         if p = 8
           then go to L12574
         if p = 10
           then go to L12607
         if p = 9
           then go to L12405
         p <- 1
         load constant 12
         go to L12513

L12734:  p <- 1
         load constant 12
         go to L12614

L12737:  p <- 1
         load constant 13
         go to L12614

L12742:  if p = 9
           then go to L12760
         if p = 4
           then go to L12203
         if p # 11
           then go to L12520
         p <- 5
         go to L12411

L12752:  if p # 2
           then go to L12600
         if 0 = s 0
           then go to L12010
         delayed rom @04
         go to L12125

L12760:  p <- 5
         go to L12410

L12762:  clear regs
         m2 exchange c
L12764:  load constant 8
         if p # 12
           then go to L12764
         c -> a[w]
         a + c -> c[w]
         c + c -> c[w]
         b exchange c[w]
         delayed rom @04
         go to L12227

L12775:  register -> c 14
         if p = 8
           then go to L13030
         if p # 10
           then go to L12574
         if s 0 = 1
           then go to L13521
         b exchange c[w]
         delayed rom @04
         jsb S12170
         b exchange c[w]
         shift right c[x]
         c + 1 -> c[xs]
         shift right c[x]
         go to L13022

S13014:  c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
         return

L13021:  jsb S13014
L13022:  c - 1 -> c[p]
         if n/c go to L13021
         clear regs
         m2 exchange c
L13026:  0 -> s 0
         register -> c 14
L13030:  if 0 = s 0
           then go to L13051
         nop
         nop
         shift right c[x]
         c + 1 -> c[xs]
         shift right c[x]
         p <- 0
         0 -> a[w]
L13041:  jsb S13014
         c + 1 -> c[p]
         if n/c go to L13041
         p <- 13
         load constant 0
         load constant 0
         p <- 2
         load constant 13
L13051:  p <- 1
         0 -> c[wp]
         c -> register 14
L13054:  0 -> s 2
         delayed rom @04
         go to L12125

L13057:  jsb S13225
L13060:  load constant 3
         go to L13260

L13062:  jsb S13221
         go to L13377

L13064:  jsb S13265
L13065:  load constant 5
L13066:  load constant 1
         go to L13077

L13070:  jsb S13225
         go to L13200

L13072:  jsb S13265
         go to L13250

L13074:  jsb S13225
L13075:  load constant 7
L13076:  load constant 4
L13077:  a exchange c[w]
         0 -> c[w]
         p <- 10
         load constant 6
         if 0 = s 13
           then go to L13107
         p <- 8
         load constant 3
L13107:  p <- 0
         load constant 7
         b exchange c[w]
         register -> c 14
         0 -> a[x]
         p <- 1
         if c[wp] = 0
           then go to L13140
         p <- 0
         c + 1 -> c[p]
         if n/c go to L13123
         go to L13137

L13123:  p <- 1
         a exchange c[p]
         shift right a[x]
         a + 1 -> a[x]
         p <- 0
         go to L13134

L13131:  decimal
         a + b -> a[x]
         binary
L13134:  c + 1 -> c[p]
         if n/c go to L13131
         decimal
L13137:  a + 1 -> a[x]
L13140:  p <- 13
         a exchange c[ms]
L13142:  p + 1 -> p
         shift left a[w]
         if p # 10
           then go to L13142
         a exchange c[wp]
         a exchange c[m]
         load constant 9
         a exchange c[m]
         return

L13153:  jsb S13225
         go to L13342

L13155:  jsb S13225
         go to L13337

L13157:  jsb S13265
         go to L13060

L13161:  jsb S13265
L13162:  load constant 2
         go to L13066

L13164:  register -> c 14
         p <- 1
         c -> a[x]
         if c[wp] # 0
           then go to L13427
         shift right a[x]
         a exchange c[p]
         c + 1 -> c[p]
         shift right c[wp]
         delayed rom @07
         go to L13432

         jsb S13265
L13200:  load constant 7
         go to L13066

L13202:  jsb S13265
         go to L13337

L13204:  jsb S13221
         go to L13357

L13206:  jsb S13265
L13207:  load constant 6
         go to L13066

L13211:  jsb S13225
         go to L13207

L13213:  jsb S13225
         go to L13357

L13215:  load constant 3
         go to L13076

         jsb S13221
         go to L13277

S13221:  p <- 9
         load constant 2
         load constant 2
         1 -> s 13
S13225:  p <- 7
         load constant 2
         load constant 5
         go to L13270

L13231:  jsb S13265
         go to L13257

L13233:  jsb S13225
         go to L13257

L13235:  jsb S13265
         go to L13075

         jsb S13221
         go to L13317

L13241:  jsb S13225
         go to L13377

L13243:  jsb S13265
         go to L13377

L13245:  jsb S13225
         go to L13162

L13247:  jsb S13225
L13250:  load constant 2
         go to L13260

         go to L13074

         go to L13233

         go to L13235

         go to L13231

         go to L13075

L13257:  load constant 7
L13260:  load constant 3
         go to L13077

L13262:  jsb S13225
L13263:  load constant 3
         go to L13066

S13265:  p <- 7
         load constant 2
         load constant 4
L13270:  p <- 4
         return

         go to L13262

         go to L13303

         go to L13204

         go to L13305

         go to L13263

L13277:  shift left a[x]
         shift left a[x]
         delayed rom @04
         go to L12026

L13303:  jsb S13225
         go to L13277

L13305:  jsb S13265
         go to L13277

         go to L13161

         go to L13245

         go to L13065

         go to L13321

         go to L13325

         go to L13361

         go to L13363

         go to L13322

L13317:  a + 1 -> a[x]
         if n/c go to L13277
L13321:  jsb S13225
L13322:  load constant 3
L13323:  load constant 2
         go to L13077

L13325:  jsb S13225
         go to L13317

         go to L13341

         go to L13153

         go to L13345

         go to L13057

         go to L13155

         go to L13157

         go to L13202

         go to L13060

L13337:  a + 1 -> a[x]
         if n/c go to L13317
L13341:  jsb S13265
L13342:  load constant 2
L13343:  go to L13323

L13344:  jsb S13265
L13345:  load constant 4
         go to L13066

         go to L13344

         go to L13206

         go to L13207

         go to L13211

         go to L13213

         go to L13062

         go to L13365

         go to L13215

L13357:  a + 1 -> a[x]
         if n/c go to L13337
L13361:  jsb S13265
         go to L13322

L13363:  jsb S13265
         go to L13317

L13365:  jsb S13265
         go to L13357

         go to L13064

         go to L13070

         go to L13200

         go to L13247

         go to L13241

         go to L13072

         go to L13243

         go to L13250

L13377:  a + 1 -> a[x]
         delayed rom @06
         go to L13357

         bank toggle

         go to L13420

L13404:  bank toggle

         if 0 = s 2
           then go to L12571
         go to L13751

         bank toggle

         delayed rom @05
         go to L12762

         bank toggle

L13414:  if c[m] = 0
           then go to L13440
         jsb S13642
         go to L13440

L13420:  load constant 11
         delayed rom @04
         jsb S12171
         c -> register 7
         c -> register 8
         c -> register 9
         go to L13440

L13427:  c - 1 -> c[p]
         if n/c go to L13442
         c + 1 -> c[x]
L13432:  load constant 6
L13433:  c -> register 14
         if s 0 = 1
           then go to L13521
         jsb S13456
         jsb S13447
L13440:  delayed rom @04
         go to L12125

L13442:  shift left a[x]
         a + 1 -> a[p]
         if n/c go to L13433
         0 -> c[wp]
         go to L13433

S13447:  0 -> s 0
S13450:  display toggle
L13451:  0 -> s 15
         if s 15 = 1
           then go to L13451
         display off
         return

S13456:  1 -> s 0
         a exchange c[w]
         m1 exchange c
         0 -> s 13
         jsb S13471
         jsb S13513
         0 -> c[w]
         c - 1 -> c[m]
         if s 11 = 1
           then go to L13077
         go to L13663

S13471:  register -> c 14
S13472:  a exchange c[x]
         p <- 1
         shift left a[x]
         shift right a[wp]
         a exchange c[x]
         1 -> s 11
         if c[x] = 0
           then go to L13506
         0 -> s 11
         c - 1 -> c[x]
         c + 1 -> c[p]
         c -> data address
L13506:  a exchange c[x]
         data -> c
         return

L13511:  shift right c[w]
         shift right c[w]
S13513:  a - 1 -> a[xs]
         if n/c go to L13511
         a exchange c[x]
         return

L13517:  if s 0 = 1
           then go to L13026
L13521:  binary
         jsb S13456
         delayed rom @05
         go to L12571

L13525:  if 0 = s 0
           then go to L12015
         a -> b[w]
         jsb S13567
         if s 10 = 1
           then go to L13563
L13533:  c -> register 14
         jsb S13471
         if 0 = s 10
           then go to L13540
         0 -> c[w]
L13540:  p <- 1
         a exchange b[w]
S13542:  b exchange c[w]
         go to L13550

L13544:  shift left a[w]
         shift left a[w]
         p + 1 -> p
         p + 1 -> p
L13550:  c - 1 -> c[xs]
         if n/c go to L13544
         a exchange b[wp]
         if p = 1
           then go to L13560
         p - 1 -> p
         p - 1 -> p
         a exchange b[wp]
L13560:  b exchange c[w]
         c -> data
         go to L13521

L13563:  c - 1 -> c[xs]
         if n/c go to L13533
         delayed rom @04
         go to L12203

S13567:  binary
         0 -> s 10
         register -> c 14
S13572:  p <- 1
         c - 1 -> c[wp]
         if n/c go to L13603
         load constant 6
         go to L13601

L13577:  c + 1 -> c[p]
         c + 1 -> c[x]
L13601:  c -> register 14
         return

L13603:  c -> a[x]
         a + c -> a[p]
         a + c -> a[p]
         if n/c go to L13577
         shift left a[x]
         shift left a[x]
         a - c -> a[xs]
         if a[xs] # 0
           then go to L13615
         1 -> s 10
L13615:  0 -> c[p]
         go to L13601

L13617:  if s 0 = 1
           then go to L13647
         1 -> s 12
L13622:  register -> c 14
         p <- 1
         if c[wp] # 0
           then go to S13627
         jsb S13572
S13627:  jsb S13456
         jsb S13447
         register -> c 14
         m1 exchange c
         a exchange c[w]
         if 0 = s 12
           then go to L13661
         jsb S13642
         m1 -> c
         jsb S13472
         go to L13662

S13642:  jsb S13567
         if 0 = s 10
           then go to L12017
         0 -> c[wp]
         go to L13601

L13647:  jsb S13642
         go to L13521

L13651:  jsb S13567
         if s 10 = 1
           then go to L13051
         if 0 = s 15
           then go to L13660
         if 0 = s 7
L13657:    then go to L13054
L13660:  display toggle
L13661:  jsb S13471
L13662:  jsb S13513
L13663:  delayed rom @04
         go to L12015

L13665:  m2 -> c
         0 -> b[w]
         go to L13740

L13670:  0 -> c[w]
         p <- 2
         load constant 13
         p <- 9
         c + 1 -> c[p]
         c -> a[w]
         load constant 7
         b exchange c[w]
         register -> c 14
         a - c -> a[xs]
         decimal
L13703:  a + b -> a[m]
         a - 1 -> a[xs]
         if n/c go to L13703
         shift right c[x]
         shift right c[x]
         c -> a[x]
         p <- 0
         load constant 6
         a + c -> a[x]
         p <- 4
         a + 1 -> a[x]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         0 -> c[w]
         p <- 11
         load constant 6
         p <- 5
         load constant 6
         b exchange c[w]
         a exchange c[w]
         p <- 12
         load constant 13
         load constant 9
         p <- 8
         load constant 15
         load constant 15
         load constant 10
         load constant 9
L13740:  c -> a[w]
         jsb S13450
         go to L13751

L13743:  if s 7 = 1
           then go to L13747
         delayed rom @04
         jsb S12272
L13747:  delayed rom @04
         jsb S12232
L13751:  0 -> c[x]
         binary
         p <- 2
         load constant 6
         display off
         display toggle
L13757:  c - 1 -> c[x]
         if n/c go to L13757
         display off
         go to L13440

L13763:  binary
         if s 2 = 1
           then go to L13774
         0 -> s 7
         0 -> s 6
         1 -> s 2
         if s 12 = 1
           then go to L13054
         go to L13622

L13774:  jsb S13642
         delayed rom @06
         go to L13054

	 .dw @0506			; CRC, bank 1 quad 1 (@12000..@13777)

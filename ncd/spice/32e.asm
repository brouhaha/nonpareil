; 31E model-specific firmware, uses 1820-2162 CPU ROM
; Copyright 2022 Eric Smith <spacewar@gmail.com>

         .arch woodstock

         .include "1820-2162.inc"

	 .org @2000

L02000:  go to L02023

L02001:  go to L02010

L02002:  go to L02066

L02003:  p <- 0
L02004:  go to L02352

L02005:  1 -> s 9
         m2 exchange c
         go to L02027

L02010:  display off
         clear status
         clear regs
         0 -> c[w]
         delayed rom @05
         jsb S02671
         clear data registers
         load constant 4
         a exchange c[w]
         f exchange a[x]
L02022:  down rotate
L02023:  delayed rom @03
         jsb S01572
         m2 exchange c
         0 -> s 9
L02027:  jsb S02107
L02030:  jsb S02367
L02031:  jsb S02112
L02032:  delayed rom @06
         jsb S03330
         m2 -> c
         0 -> a[x]
         if p = 11
           then go to L03237
         if p = 10
           then go to L02477
         keys -> rom address

L02043:  0 -> s 1
         go to L02233

L02045:  p <- 10
         go to L02031

L02047:  delayed rom @00
         jsb S00171
         go to L02335

L02052:  delayed rom @03
         go to L01474

L02054:  delayed rom @07
         go to L03573

L02056:  delayed rom @07
         go to L03634

         go to L02073

         go to L02045

         go to L02121

         go to L02075

         delayed rom @00
         jsb S00272
L02066:  a exchange c[w]
         m2 -> c
         c -> register 10
         a exchange c[w]
         go to L02000

L02073:  p <- 11
         go to L02031

L02075:  delayed rom @00
         jsb S00352
         go to L02002

         go to L02123

         go to L02213

         go to L02260

         if p # 5
           then go to L03117
         p <- 1
         go to L02031

S02107:  0 -> s 11
         0 -> s 2
         0 -> s 3
S02112:  0 -> s 4
         0 -> s 6
         0 -> s 7
         0 -> s 8
         0 -> s 10
         0 -> s 13
         return

L02121:  delayed rom @02
         go to L01331

L02123:  y -> a
         c - 1 -> c[x]
         c - 1 -> c[x]
L02126:  delayed rom @00
         jsb S00171
         go to L02002

L02131:  0 -> c[w]
         go to L02005

L02133:  p <- 2
         go to L02004

L02135:  a + 1 -> a[x]
         1 -> s 6
         go to L02241

         go to L02170

L02141:  go to L02316

         go to L02317

         if p # 5
           then go to L02150
         p <- 3
         go to L02031

L02147:  0 - c - 1 -> c[s]
L02150:  stack -> a
         delayed rom @00
         jsb S00014
         go to L02002

L02154:  p <- 6
         go to L02031

L02156:  p <- 5
         go to L02031

         go to L02131

         go to L02054

         go to L02056

         if p = 5
           then go to L02175
L02165:  c -> stack
         go to L02005

L02167:  a + 1 -> a[x]
L02170:  a + 1 -> a[x]
         if s 10 = 1
           then go to L02133
         1 -> s 8
         go to L02141

L02175:  if 0 = s 10
           then go to L03723
         go to L02165

L02200:  if p = 12
           then go to L02052
         if s 10 = 1
           then go to L02052
         if p # 6
           then go to L02052
         register -> c 3
         delayed rom @03
         jsb S01630
         register -> c 1
         go to L02000

L02213:  if p = 12
           then go to L03630
         if p = 9
           then go to L03630
         go to L02247

         go to L02200

         go to L02154

         go to L02156

         go to L02022

         stack -> a
         c -> stack
         a exchange c[w]
         go to L02000

L02230:  p <- 1
         go to L02004

L02232:  1 -> s 1
L02233:  1 -> s 0
L02234:  f exchange a[x]
         go to L02027

L02236:  stack -> a
         go to L02126

         go to L02135

L02241:  a + 1 -> a[x]
         if n/c go to L02167
         if p # 5
           then go to L02147
         p <- 4
         go to L02031

L02247:  if p = 8
           then go to L03630
         if p = 7
           then go to L03630
         if s 10 = 1
           then go to L03630
         1 -> s 10
         go to L02032

L02257:  a + 1 -> a[x]
L02260:  if p = 12
           then go to L03432
         if p = 9
           then go to L02364
         if p = 8
           then go to L02043
         if p = 7
           then go to L02232
         if s 6 = 1
           then go to L02133
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
L02316:  a + 1 -> a[x]
L02317:  a + 1 -> a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
         if n/c go to L02257
         if p # 5
           then go to L02236
         p <- 2
         go to L02031

L02327:  if p = 3
           then go to L02347
         if p = 2
           then go to L02047
         delayed rom @00
         jsb S00222
L02335:  delayed rom @03
         jsb S01572
         if p = 10
           then go to L02230
L02341:  c -> data
         0 -> c[w]
         c -> data address
         m2 -> c
         go to L02000

L02346:  0 - c - 1 -> c[s]
L02347:  delayed rom @00
         jsb S00014
         go to L02335

L02352:  0 -> c[w]
         c -> data address
         binary
         c - 1 -> c[w]
         0 -> a[xs]
L02357:  if p = 0
           then go to L03266
         a + 1 -> a[xs]
         p - 1 -> p
         go to L02357

L02364:  0 -> s 0
         0 -> s 1
         go to L02234

S02367:  m2 -> c
         b exchange c[w]
         if s 11 = 1
           then go to L03373
         decimal
         b -> c[w]
         0 -> s 4
         c -> a[w]
         if s 0 = 1
           then go to L02427
         if c[xs] # 0
           then go to L02421
         p <- 1
         load constant 1
         load constant 0
         if a >= c[x]
           then go to L02427
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
         if n/c go to L02427
         go to L02432

L02427:  1 -> s 4
         0 -> a[x]
         f -> a[x]
L02432:  b -> c[w]
         0 -> c[s]
         p <- 12
L02435:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L02435
         if s 4 = 1
           then go to L02445
         if c[xs] = 0
           then go to L02445
         p + 1 -> p
L02445:  0 -> a[w]
         c -> a[wp]
         a + c -> a[ms]
         0 -> a[wp]
         a exchange c[ms]
         go to L02737

L02453:  delayed rom @03
         go to L01476

L02455:  1 -> s 8
         delayed rom @12
         go to L05121

         go to L02467

         go to L02471

         p - 1 -> p
         p - 1 -> p
         p - 1 -> p
L02465:  delayed rom @04
         go to L02031

L02467:  p <- 11
         go to L02465

L02471:  p <- 10
         go to L02465

L02473:  b -> c[w]
         c -> a[w]
         0 -> a[s]
         go to L02764

L02477:  keys -> rom address

         go to L02530

         go to L02656

         go to L02535

         1 -> s 4
L02504:  jsb S02554
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
L02517:  if s 4 = 1
           then go to L02525
         delayed rom @00
         jsb S00171
L02523:  delayed rom @04
         go to L02002

L02525:  delayed rom @00
         jsb S00222
         go to L02523

L02530:  a exchange c[w]
         a + 1 -> a[x]
         a + 1 -> a[x]
         register -> c 1
         go to L02525

L02535:  delayed rom @01
         jsb S00540
         go to L02523

         go to L02455

         go to L02776

         go to L02701

         jsb S02554
         load constant 1
         load constant 8
         delayed rom @00
         jsb S00171
         jsb S02626
         delayed rom @00
         jsb S00016
         go to L02523

S02554:  c -> a[w]
S02555:  0 -> c[w]
         p <- 12
         return

         go to L02603

         go to L02574

         go to L02565

         p <- 12
         go to L02465

L02565:  clear regs
         jsb S02671
         clear data registers
         m2 exchange c
         m2 -> c
L02572:  delayed rom @04
         go to L02027

L02574:  jsb S02671
         c -> register 11
         c -> register 12
         c -> register 13
         c -> register 14
         c -> register 15
         go to L02572

L02603:  0 -> c[w]
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

L02616:  delayed rom @03
         go to L01545

         go to L02453

         go to L02616

         select rom go to L05623

         select rom go to L05624

         delayed rom @12
         go to L05274

S02626:  0 -> c[w]
         c + 1 -> c[x]
         p <- 12
         load constant 3
         load constant 2
         return

L02634:  1 -> s 7
L02635:  1 -> s 4
L02636:  delayed rom @13
         go to L05512

         go to L02654

         go to L02653

         go to L02652

         1 -> s 4
L02644:  jsb S02554
         c + 1 -> c[x]
         load constant 2
         load constant 5
         load constant 4
         go to L02517

L02652:  1 -> s 10
L02653:  1 -> s 6
L02654:  delayed rom @11
         go to L04474

L02656:  delayed rom @01
         jsb S00540
         0 -> c[w]
         m1 exchange c
         m1 -> c
         delayed rom @03
         jsb S01651
         b exchange c[w]
         delayed rom @00
         jsb S00227
         go to L02523

S02671:  0 -> c[w]
         p <- 1
         load constant 1
         c -> data address
         clear data registers
         0 -> c[w]
         c -> data address
         return

L02701:  delayed rom @11
         go to L04470

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
         go to L02634

         go to L02636

         go to L02635

         1 -> s 4
L02724:  jsb S02554
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

L02737:  if c[s] = 0
           then go to L02753
         if 0 = s 4
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
         if 0 = s 4
           then go to L03361
         if s 1 = 1
           then go to L03201
L02764:  if c[xs] = 0
           then go to L02771
         decimal
         0 - c -> c[x]
         c - 1 -> c[xs]
L02771:  a exchange c[x]
         delayed rom @07
         jsb S03657
         delayed rom @06
         go to L03373

L02776:  delayed rom @06
         go to L03011

S03000:  select rom go to L00001

         select rom go to L00002

         select rom go to L00003

S03003:  select rom go to L00004

S03004:  select rom go to L00005

         select rom go to L00006

S03006:  select rom go to L00007

S03007:  select rom go to L00010

S03010:  select rom go to L00011

L03011:  0 -> a[w]
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

L03024:  c -> a[w]
         jsb S03174
         jsb S03003
         jsb S03022
         jsb S03010
         go to L03020

L03032:  a exchange c[m]
         a exchange b[x]
         return

L03035:  0 -> a[w]
         delayed rom @03
         jsb S01651
         m2 -> c
         jsb S03004
         delayed rom @02
         jsb S01044
         go to L03020

L03045:  delayed rom @03
         jsb S01407
         go to L03020

S03050:  0 -> a[w]
         p <- 12
         a + 1 -> a[p]
         return

L03054:  1 -> s 6
L03055:  1 -> s 13
         delayed rom @10
         go to L04065

         go to L03067

         go to L03076

         go to L03351

         go to L03260

         c -> a[w]
         jsb S03003
         go to L03020

L03067:  p <- 11
L03070:  delayed rom @04
         go to L02031

S03072:  if s 9 = 1
           then go to L03075
         c -> stack
L03075:  return

L03076:  p <- 10
         go to L03070

         go to L03244

         go to L03035

         go to L03114

         select rom go to L02504

L03104:  0 -> s 12
         0 -> s 14
         go to L03172

L03107:  0 -> s 12
         go to L03112

L03111:  1 -> s 12
L03112:  1 -> s 14
         go to L03172

L03114:  delayed rom @02
         jsb S01041
         go to L03020

L03117:  if c[m] = 0
           then go to L02003
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

         go to L03316

         go to L03024

         go to L03156

         c -> a[w]
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

L03156:  delayed rom @10
         go to L04000

         go to L03104

         go to L03107

         go to L03111

         a exchange c[w]
         0 -> b[w]
         display toggle
L03166:  0 -> s 15
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

L03201:  b exchange c[x]
         a + 1 -> a[xs]
         a - 1 -> a[x]
         p <- 1
         0 -> c[x]
         load constant 3
L03207:  a - c -> a[x]
         if n/c go to L03207
         a + c -> a[x]
         shift right c[x]
L03213:  a - c -> a[x]
         if n/c go to L03213
         go to L03232

L03216:  delayed rom @13
         go to L05424

         go to L03045

         go to L03230

         go to L03226

         go to L03231

         delayed rom @15
         go to L06523

L03226:  delayed rom @13
         go to L05630

L03230:  select rom go to L05631

L03231:  select rom go to L05632

L03232:  a + c -> a[x]
         b -> c[x]
         p <- 12
         delayed rom @05
         go to L02704

L03237:  keys -> rom address

         go to L03055

         1 -> s 10
         go to L03054

         select rom go to L02644

L03244:  y -> a
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

L03260:  jsb S03072
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
         load constant 14
         load constant 10
         load constant 10
         load constant 12
         load constant 10
         a exchange c[w]
         0 -> b[w]
         jsb S03330
         go to L03172

L03304:  if s 9 = 1
           then go to L03307
         c -> stack
L03307:  0 -> c[w]
         c -> data address
         a exchange c[w]
         go to L03357

L03313:  c -> a[s]
         b exchange c[w]
         return

L03316:  delayed rom @12
         go to L05121

         go to L03326

         go to L03216

         go to L03324

         select rom go to L02724

L03324:  delayed rom @13
         go to L05471

L03326:  delayed rom @13
         go to L05441

S03330:  display off
         decimal
         display toggle
L03333:  0 -> s 15
         if s 15 = 1
           then go to L03333
L03336:  if 0 = s 15
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

L03351:  jsb S03072
         register -> c 10
         go to L03357

L03354:  if c[m] = 0
           then go to L02030
         0 - c - 1 -> c[s]
L03357:  delayed rom @04
         go to L02000

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

L03432:  if 0 = s 11
           then go to L03444
         b exchange c[w]
         b -> c[w]
         0 -> c[x]
         binary
         if s 2 = 1
           then go to L03514
         a exchange c[m]
         go to L03446

L03444:  jsb S03542
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
         1 -> s 3
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
L03506:  if 0 = s 2
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

S03542:  if s 9 = 1
           then go to S03545
         c -> stack
S03545:  0 -> s 9
         1 -> s 11
         0 -> c[w]
         c -> a[ms]
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

L03573:  if s 11 = 1
           then go to L03606
         jsb S03542
L03576:  p <- 12
         load constant 1
         c -> a[w]
         a - 1 -> a[wp]
L03602:  0 -> a[x]
         1 -> s 2
         1 -> s 3
         go to L03506

L03606:  if s 2 = 1
           then go to L03623
         if c[m] = 0
           then go to L03626
         p <- 5
         a exchange c[m]
         c -> a[m]
         0 -> c[wp]
         if c[m] = 0
           then go to L03623
         m2 -> c
         if b[wp] = 0
           then go to L03602
L03623:  p <- 12
         delayed rom @04
         go to L02031

L03626:  jsb S03545
         go to L03576

L03630:  1 -> s 3
         if s 11 = 1
           then go to L03623
         go to L03444

L03634:  if 0 = s 11
           then go to L03354
         if s 2 = 1
           then go to L03647
         if c[m] = 0
           then go to L03643
         0 - c - 1 -> c[s]
L03643:  binary
         a - 1 -> a[x]
         nop
         go to L03511

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
           then go to L03711
         c - 1 -> c[p]
         if n/c go to L03665
         clear data registers
L03676:  0 -> c[x]
         p <- 12
         c + 1 -> c[p]
         m2 exchange c
         m2 -> c
         return

S03704:  if 0 = s 5
           then go to L03676
         go to L03711

L03707:  0 -> c[w]
         m2 exchange c
L03711:  p <- 9
         delayed rom @04
         go to L02004

S03714:  p <- 0
L03715:  c -> data address
         c -> data
         c - 1 -> c[p]
         if n/c go to L03715
         return

S03722:  rom checksum

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
         jsb S01377
         jsb S03704
         jsb S03722
         jsb S03704
         delayed rom @12
         jsb S05262
         jsb S03704
         delayed rom @12
         go to L05357

	 .dw @1142			; CRC, quad 1 (@2000..@3777)

L04000:  m2 -> c
         stack -> a
         if c[m] = 0
           then go to L04050
         if c[s] = 0
           then go to L04011
         1 -> s 7
         1 -> s 10
         0 -> c[s]
L04011:  delayed rom @00
         jsb S00222
         if c[m] # 0
           then go to L04016
         0 -> a[w]
L04016:  delayed rom @01
         jsb S00470
         delayed rom @01
         jsb S00535
         delayed rom @00
         jsb S00176
         delayed rom @00
         jsb S00374
         delayed rom @00
         jsb S00275
         m2 -> c
         0 -> c[s]
         delayed rom @00
         jsb S00173
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
L04061:  0 -> a[w]
         go to L04322

L04063:  jsb S04042
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
         go to L04322

L04130:  if s 6 = 1
           then go to L04375
L04132:  delayed rom @00
         jsb S00355
         jsb S04042
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
         go to L04322

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
         jsb S00251
         a exchange b[w]
         m1 exchange c
         0 -> c[x]
         p <- 7
L04215:  b exchange c[w]
         jsb S04377
         b exchange c[w]
         go to L04222

L04221:  a + b -> a[w]
L04222:  c - 1 -> c[p]
         if n/c go to L04221
         shift right a[w]
         0 -> c[p]
         if c[m] = 0
           then go to L04317
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
         delayed rom @01
         jsb S00470
         delayed rom @01
         jsb S00470
         delayed rom @00
         jsb S00374
         delayed rom @01
         jsb S00420
         delayed rom @00
         jsb S00367
         delayed rom @01
         jsb S00436
         delayed rom @00
         jsb S00176
         0 -> a[s]
         delayed rom @00
         jsb S00275
         delayed rom @01
         jsb S00436
         delayed rom @00
         jsb S00362
         0 -> a[s]
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L04132
         go to L04135

L04316:  p + 1 -> p
L04317:  c - 1 -> c[x]
         if p # 12
           then go to L04316
L04322:  0 -> c[ms]
         delayed rom @00
         jsb S00114
         if 0 = s 10
           then go to L04335
         jsb S04232
         0 - c - 1 -> c[s]
         a exchange c[s]
         0 -> c[s]
         delayed rom @00
         jsb S00021
L04335:  if 0 = s 7
           then go to L04342
         jsb S04232
         delayed rom @00
         jsb S00021
L04342:  if s 12 = 1
           then go to L04361
         jsb S04232
         a + 1 -> a[x]
         a + 1 -> a[x]
         delayed rom @00
         jsb S00227
         if s 14 = 1
           then go to L04361
         0 -> c[w]
         p <- 12
         load constant 9
         c - 1 -> c[x]
         delayed rom @00
         jsb S00173
L04361:  if 0 = s 4
           then go to L04364
         0 - c - 1 -> c[s]
L04364:  if s 13 = 1
           then go to L04373
         delayed rom @03
         jsb S01572
         stack -> a
         c -> stack
         a exchange c[w]
L04373:  delayed rom @04
         go to L02002

L04375:  delayed rom @04
         go to L02003

S04377:  0 -> c[w]
         c - 1 -> c[w]
         0 -> c[s]
         if p = 12
           then go to L04420
         if p = 11
           then go to L04442
         if p = 10
           then go to L04452
         if p = 9
           then go to L04460
         if p = 8
           then go to L04464
         p <- 0
L04415:  load constant 7
         p <- 7
         return

L04420:  p <- 10
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

S04436:  load constant 6
         if p = 0
           then go to L04415
         go to S04436

L04442:  p <- 8
         jsb S04436
         p <- 0
         load constant 5
         p <- 4
         load constant 8
         p <- 11
         return

L04452:  p <- 6
         jsb S04436
         p <- 0
         load constant 9
         p <- 10
         return

L04460:  p <- 4
         jsb S04436
         p <- 9
         return

L04464:  p <- 2
         jsb S04436
         p <- 8
         return

L04470:  1 -> s 13
         1 -> s 6
         stack -> a
         a exchange c[w]
L04474:  0 -> a[w]
         0 -> b[w]
         a exchange c[m]
         if c[s] = 0
           then go to L04510
         1 -> s 7
         if 0 = s 6
           then go to L04506
         if 0 = s 10
           then go to L04507
L04506:  1 -> s 4
L04507:  0 -> c[s]
L04510:  b exchange c[w]
         if s 12 = 1
           then go to L04624
         if 0 = s 14
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
         if 0 = s 12
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
         if 0 = s 12
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
         if 0 = s 6
           then go to L04605
         if 0 = s 7
           then go to L04622
         0 -> s 7
         go to L04566

L04622:  1 -> s 7
         go to L04566

L04624:  delayed rom @10
         jsb S04240
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
         jsb S00114
         if s 12 = 1
           then go to L04660
         m1 -> c
         c + c -> c[w]
         c - 1 -> c[x]
         delayed rom @00
         jsb S00224
         delayed rom @10
         jsb S04232
         delayed rom @00
         jsb S00176
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
         jsb S04377
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
         if 0 = s 10
           then go to L05063
         delayed rom @00
         jsb S00355
         delayed rom @12
         go to L05063

L04771:  m2 -> c
         m1 exchange c
         m1 -> c
         0 -> c[x]
         delayed rom @12
         go to L05022

         nop

S05000:  select rom go to L00001

S05001:  select rom go to L00002

         select rom go to L00003

         select rom go to L00004

         select rom go to L00005

S05005:  select rom go to L00006

         select rom go to L00007

S05007:  select rom go to L00010

S05010:  select rom go to L00011

S05011:  select rom go to L00012

S05012:  select rom go to L00013

S05013:  select rom go to L00414

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
         if 0 = s 10
           then go to L05033
         stack -> a
         c -> stack
         a exchange c[w]
L05033:  jsb S05020
         if 0 = s 7
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
         jsb S00243
L05063:  if 0 = s 6
           then go to L05102
         jsb S05013
         a exchange c[w]
         c -> a[w]
         m1 exchange c
         b -> c[w]
         jsb S05005
         delayed rom @00
         jsb S00374
         jsb S05012
         if s 13 = 1
           then go to L04771
         delayed rom @00
         jsb S00355
L05102:  if 0 = s 4
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
         if 0 = s 6
           then go to L05105
         go to L05063

L05121:  b exchange c[w]
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
         if 0 = s 8
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
         go to S00104

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
         if 0 = s 8
           then go to L05124
         0 -> a[w]
         c -> a[x]
         a + c -> c[w]
         0 -> c[x]
         return

L05226:  jsb S05014
         if a[s] # 0
           then go to L05606
         jsb S05015
         if a[s] # 0
           then go to L05606
         delayed rom @03
         jsb S01642
         0 -> b[w]
         a exchange b[m]
         delayed rom @00
         jsb S00367
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

S05262:  rom checksum

L05263:  jsb S05016
         jsb S05010
         jsb S05020
         delayed rom @03
         jsb S01630
         0 -> a[w]
         0 -> b[w]
         delayed rom @13
         go to L05752

L05274:  0 -> s 13
         c -> register 10
         c -> a[w]
         0 -> a[s]
         if c[s] = 0
           then go to L05303
         1 -> s 13
L05303:  0 -> c[w]
         p <- 13
         load constant 9
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
         jsb S00374
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

L05357:  delayed rom @15
         jsb S06775
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
         jsb S03330
         select rom go to L00000

S05400:  select rom go to L00001

S05401:  select rom go to L00002

S05402:  select rom go to L00003

S05403:  select rom go to L00004

S05404:  select rom go to L00005

S05405:  select rom go to L00006

         select rom go to L00007

S05407:  select rom go to L00010

S05410:  select rom go to L00011

S05411:  select rom go to L00012

S05412:  select rom go to L00013

S05413:  select rom go to L00414

S05414:  select rom go to L00415

S05415:  select rom go to L00416

S05416:  select rom go to L00417

S05417:  select rom go to S00420

S05420:  delayed rom @01
         go to L00545

         delayed rom @02
         go to S01044

L05424:  jsb S05621
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

L05441:  jsb S05567
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

L05471:  jsb S05567
         if s 6 = 1
           then go to L05437
         c -> a[w]
         jsb S05617
         delayed rom @00
         jsb S00374
         jsb S05412
         delayed rom @00
         jsb S00374
         jsb S05414
         jsb S05410
         m2 -> c
         0 -> c[s]
         jsb S05401
         jsb S05420
         go to L05541

L05512:  jsb S05567
         if s 4 = 1
           then go to L05522
         if 0 = s 6
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
         if 0 = s 4
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
         jsb S00355
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

L05606:  p <- 3
         delayed rom @04
         go to L02004

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

L05623:  1 -> s 6
L05624:  1 -> s 8
         go to L05632

         delayed rom @03
         go to S01642

L05630:  1 -> s 4
L05631:  1 -> s 10
L05632:  jsb S05604
         jsb S05621
         jsb S05611
         if c[s] # 0
           then go to L05606
         if c[m] = 0
           then go to L05606
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
         if 0 = s 6
           then go to L05437
L05730:  delayed rom @04
         go to L02000

L05732:  jsb S05414
         jsb S05415
         jsb S05405
         if a[s] # 0
           then go to L05606
         if c[m] = 0
           then go to L05606
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
           then go to L05606
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
         go to S00176

S06002:  select rom go to L00003

S06003:  0 -> c[w]
S06004:  m1 exchange c
S06005:  delayed rom @05
         go to S02555

S06007:  delayed rom @01
         go to S00535

S06011:  select rom go to L00012

S06012:  delayed rom @01
         go to S00515

S06014:  0 -> c[w]
         0 - c - 1 -> c[s]
         c + 1 -> c[x]
         if n/c go to S06004
S06020:  jsb S06007
         jsb S06003
         load constant 5
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
         load constant 4
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
         load constant 2
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
         load constant 2
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
         load constant 5
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
         load constant 3
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
         delayed rom @15
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
         load constant 3
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
         load constant 3
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
         load constant 7
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
         load constant 1
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
         load constant 4
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
         load constant 5
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
         load constant 1
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
         load constant 1
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

S06400:  select rom go to L00001

S06401:  select rom go to L00002

S06402:  select rom go to L00003

         select rom go to L00004

S06404:  select rom go to L00005

S06405:  select rom go to L00006

         select rom go to L00007

         select rom go to L00010

S06410:  select rom go to L00011

S06411:  select rom go to L00012

S06412:  select rom go to L00013

S06413:  select rom go to L00414

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

L06431:  load constant 3
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
         load constant 1
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
         p <- 0
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
         load constant 3
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

L06523:  if c[s] = 0
           then go to L06527
L06525:  delayed rom @04
         go to L02003

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
         if 0 = s 8
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
         jsb S00355
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
         jsb S00374
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
         jsb S00120
         if 0 = s 13
           then go to L06773
         0 - c - 1 -> c[s]
L06773:  delayed rom @04
         go to L02000

S06775:  rom checksum

         nop

	 .dw @1475			; CRC, half of quad 3 (@6000..@6777

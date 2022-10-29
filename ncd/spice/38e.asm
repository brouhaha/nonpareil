; 37E model-specific firmware, uses 1820-2162 CPU ROM
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

	 .arch woodstock

         .include "1820-2122.inc"

	 .bank 0
	 .org @2000

; Note that code from @02000 through @02777 is nearly identical between 37E and 38E

         go to L02161

         go to L02373

         go to L02024

         go to L02137

         1 -> s 10
         jsb S02103
         jsb S02126
         delayed rom @02
         jsb S01133
         register -> c 2
         jsb S02263
         jsb S02051
         register -> c 3
         jsb S02263
         jsb S02022
         jsb S02100
         c -> register 4
         go to L02040

S02022:  delayed rom @01
         go to S00765

L02024:  jsb S02102
         jsb S02126
         delayed rom @02
         jsb S01133
         register -> c 4
         jsb S02263
         jsb S02051
         register -> c 3
         jsb S02263
         jsb S02022
         jsb S02100
         c -> register 2
L02040:  0 - c - 1 -> c[s]
L02041:  delayed rom @07
         jsb S03460
L02043:  delayed rom @00
         jsb S00311
         c -> data
         clear status
         delayed rom @00
         go to L00022

S02051:  delayed rom @02
         jsb S01017
         jsb S02126
         if s 10 = 1
           then go to L02057
         0 - c - 1 -> c[s]
L02057:  if c[m] = 0
           then go to L02064
         delayed rom @01
         jsb S00631
         go to L02072

L02064:  0 -> c[w]
         c -> data address
         data -> c
L02067:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
L02072:  if 0 = s 11
L02073:    then go to L03465
         jsb S02124
         jsb S02126
         jsb S02263
         jsb S02022
S02100:  delayed rom @01
         go to S00425

S02102:  0 -> s 10
S02103:  0 -> s 3
         1 -> s 11
         0 -> s 12
         0 -> s 14
         0 -> s 13
         if 0 = s 3
           then go to L02113
         0 -> s 11
L02113:  0 -> c[w]
         c -> data address
         data -> c
         if s 10 = 1
           then go to S02121
         0 - c - 1 -> c[s]
S02121:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S02124:  delayed rom @02
         go to S01035

S02126:  register -> c 1
         c - 1 -> c[x]
         c - 1 -> c[x]
         if c[s] = 0
           then go to L03465
         if c[xs] # 0
           then go to L03465
L02135:  p <- 2
         go to L02267

L02137:  jsb S02102
         jsb S02126
         delayed rom @02
         jsb S01133
         register -> c 4
         jsb S02263
         register -> c 2
         delayed rom @01
         jsb S00422
         jsb S02051
         if c[m] = 0
           then go to L02135
         jsb S02156
         c -> register 3
         go to L02040

S02156:  jsb S02022
         delayed rom @01
         go to S00704

L02161:  jsb S02102
         register -> c 2
         jsb S02226
         jsb S02235
         if c[s] = 0
           then go to L02202
         if c[m] = 0
           then go to L02202
         1 -> s 10
         register -> c 4
         0 - c - 1 -> c[s]
         jsb S02226
         jsb S02235
         if c[m] = 0
           then go to L02202
         if c[s] # 0
           then go to L02135
L02202:  delayed rom @02
         jsb S01062
         if 0 = s 10
           then go to L02211
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
L02211:  jsb S02124
         jsb S02126
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @02
         jsb S01062
         jsb S02156
         m1 exchange c
L02222:  0 -> c[w]
         c -> data address
         m1 -> c
         go to L02041

S02226:  a exchange c[w]
         jsb S02126
         delayed rom @01
         jsb S00555
         jsb S02124
         register -> c 3
         go to L02067

S02235:  jsb S02022
         jsb S02100
         jsb S02124
         register -> c 2
         a exchange c[w]
         register -> c 4
         delayed rom @01
         jsb S00420
         jsb S02022
         if s 10 = 1
           then go to L02253
         m1 exchange c
         0 - c - 1 -> c[s]
         m1 exchange c
L02253:  if c[m] = 0
           then go to L02135
         delayed rom @01
         jsb S00634
         m1 exchange c
         jsb S02126
         if c[m] = 0
           then go to L02222
S02263:  delayed rom @01
         go to S00557

S02265:  rom checksum

L02266:  p <- 5
L02267:  delayed rom @00
         go to L00340

L02271:  p <- 4
         go to L02267

S02273:  p <- 12
         c -> a[w]
         if c[xs] # 0
           then go to L02316
L02277:  shift left a[m]
         p - 1 -> p
         if a[m] # 0
           then go to L02313
L02303:  0 -> c[wp]
         a exchange c[x]
         m1 exchange c
         0 -> c[x]
         c - 1 -> c[x]
         a exchange c[s]
         delayed rom @01
         go to S00521

L02313:  c - 1 -> c[x]
         if n/c go to L02277
         go to L02303

L02316:  0 -> c[w]
         m1 exchange c
         a exchange c[w]
         return

S02322:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
L02325:  delayed rom @06
         go to L03070

L02327:  0 -> c[w]
         load constant 5
         c - 1 -> c[s]
         c + 1 -> c[m]
         p <- 0
         load constant 3
         0 - c -> c[x]
         delayed rom @01
         jsb S00422
         if c[s] = 0
           then go to L02135
         0 -> c[w]
         load constant 1
         c -> register 0
L02345:  0 -> c[w]
         c -> data address
         data -> c
         if c[m] = 0
           then go to L02135
         delayed rom @01
         jsb S00674
         jsb S02124
         delayed rom @05
         jsb S02632
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S02124
         delayed rom @05
         jsb S02644
         if b[m] = 0
           then go to L02135
         jsb S02156
         delayed rom @02
         jsb S01172
         delayed rom @06
         go to L03253

L02373:  jsb S02102
         delayed rom @05
         jsb S02624
         data -> c
         if c[s] # 0
           then go to L02135
         jsb S02663
         if c[m] = 0
           then go to L02345
         jsb S02624
         if c[s] = 0
           then go to L02327
         jsb S02663
         jsb S02643
         jsb S02631
         c -> register 7
         register -> c 6
         jsb S02727
         0 - c - 1 -> c[s]
         jsb S02725
         c -> register 5
         register -> c 6
         0 - c - 1 -> c[s]
         a exchange c[w]
         register -> c 7
         jsb S02653
         if c[m] = 0
           then go to L02135
         jsb S02670
         if c[m] = 0
           then go to L03257
         if c[s] = 0
           then go to L02435
         1 -> s 14
L02435:  jsb S02624
         jsb S02700
         c -> register 5
         register -> c 6
         if b[m] = 0
           then go to L02135
         jsb S02671
         if c[s] # 0
           then go to L02453
         if c[m] = 0
           then go to L02453
         jsb S02731
         c -> register 1
         go to L02460

L02453:  1 -> s 12
         jsb S02644
         if b[m] = 0
           then go to L02135
         jsb S02670
L02460:  m2 exchange c
         display toggle
         if s 0 = 1
           then go to L02465
         c -> stack
L02465:  jsb S02624
         c -> register 5
         jsb S02627
         register -> c 5
         if c[s] = 0
           then go to L03110
         if a[s] # 0
           then go to L02477
         a exchange c[s]
         go to L02543

L02477:  jsb S02666
         jsb S02745
         load constant 6
         jsb S02661
         data -> c
         jsb S02661
         jsb S02663
         jsb S02643
         jsb S02726
         c -> register 7
         jsb S02631
         jsb S02726
         if s 12 = 1
           then go to L02516
         c -> register 6
L02516:  register -> c 7
         jsb S02666
         0 - c - 1 -> c[s]
         c -> register 7
         if c[s] # 0
           then go to L02543
         jsb S02745
         data -> c
         delayed rom @01
         jsb S00674
         data -> c
         0 - c - 1 -> c[s]
         jsb S02727
         jsb S02745
         load constant 3
         jsb S02661
         jsb S02716
         register -> c 6
         if 0 = s 12
           then go to L02573
         jsb S02661
L02543:  if 0 = s 12
           then go to L02574
         if c[s] # 0
           then go to L02550
         m2 exchange c
L02550:  m2 -> c
         jsb S02731
         c -> register 1
         c -> register 5
         jsb S02624
         1 -> s 1
         jsb S02741
         register -> c 1
         jsb S02626
         delayed rom @01
         jsb S00765
         if b[m] = 0
           then go to L02751
         jsb S02674
         go to L02754

S02567:  0 - c - 1 -> c[s]
         c -> a[w]
         m2 -> c
         go to S02653

L02573:  jsb S02671
L02574:  if c[s] # 0
           then go to L02577
         jsb S02731
L02577:  c -> register 5
         jsb S02632
         c -> register 6
         register -> c 3
         0 - c - 1 -> c[s]
         jsb S02727
         register -> c 6
         jsb S02671
         m2 exchange c
         register -> c 5
         jsb S02567
         register -> c 5
         if a[s] # 0
           then go to L02623
         register -> c 1
         jsb S02567
         m2 -> c
         if a[s] # 0
           then go to L02623
         register -> c 1
L02623:  go to L02776

S02624:  jsb S02745
         data -> c
S02626:  0 - c - 1 -> c[s]
S02627:  delayed rom @07
         go to S03553

S02631:  c -> register 6
S02632:  if s 14 = 1
           then go to L02646
L02634:  register -> c 4
         if 0 = s 11
           then go to L02651
S02637:  c -> a[w]
         0 -> b[w]
         a exchange b[m]
         return

S02643:  c -> register 5
S02644:  if s 14 = 1
           then go to L02634
L02646:  register -> c 2
         if 0 = s 11
           then go to S02637
L02651:  a exchange c[w]
         register -> c 3
S02653:  delayed rom @01
         go to S00420

S02655:  delayed rom @02
         go to S01035

         delayed rom @01
         go to S00555

S02661:  delayed rom @01
         go to S00631

S02663:  register -> c 3
         go to S02666

S02665:  0 - c - 1 -> c[s]
S02666:  delayed rom @01
         go to S00557

S02670:  register -> c 5
S02671:  m1 exchange c
         m1 -> c
         0 -> c[x]
S02674:  delayed rom @01
         go to S00704

S02676:  delayed rom @04
         go to L02325

S02700:  c -> register 5
         jsb S02632
         c -> register 6
         jsb S02644
         register -> c 6
         jsb S02665
         if c[s] # 0
           then go to L02135
         c -> register 7
         register -> c 5
         jsb S02637
         jsb S02745
         load constant 2
         jsb S02661
S02716:  jsb S02663
         c -> register 5
         jsb S02666
         register -> c 7
         jsb S02727
         jsb S02676
         register -> c 5
S02725:  c -> a[s]
S02726:  register -> c 5
S02727:  delayed rom @01
         go to S00422

S02731:  c -> register 5
         0 -> s 1
         jsb S02745
         load constant 2
         c -> a[w]
         data -> c
         delayed rom @01
         jsb S00627
S02741:  jsb S02655
         register -> c 6
S02743:  delayed rom @02
         go to S01167

S02745:  0 -> c[w]
         c -> data address
         p <- 12
         return

L02751:  jsb S02624
         0 - c - 1 -> c[s]
         c -> a[s]
L02754:  m2 -> c
         jsb S02665
         jsb S02700
         jsb S02643
         jsb S02670
         m2 -> c
         jsb S02666
         register -> c 1
         jsb S02661
         c -> register 5
         jsb S02624
         0 - c - 1 -> c[s]
         c -> a[s]
         delayed rom @01
         jsb S00677
         jsb S02655
         register -> c 6
         jsb S02743
L02776:  jsb S02637
         1 -> s 1
         go to L03110

L03001:  delayed rom @14
         go to L06150

S03003:  bank toggle

         delayed rom @01
         jsb S00677
L03006:  bank toggle

         return

L03010:  bank toggle

         go to L03001

L03012:  bank toggle

         delayed rom @04
         jsb S02126
         go to L03006

         nop
         bank toggle

         delayed rom @01
         jsb S00711
         go to L03006

S03023:  delayed rom @02
         go to S01035

         bank toggle

         delayed rom @01
         jsb S00425
         go to L03006

         nop
         nop
         bank toggle

         delayed rom @01
         jsb S00562
         go to L03006

S03037:  delayed rom @01
         go to S00765

         bank toggle

         delayed rom @01
         jsb S00634
         go to L03006

L03045:  bank toggle

         jsb S03023
         go to L03006

L03050:  bank toggle

         jsb S03037
         go to L03006

         bank toggle

         jsb S03341
         go to L03006

         bank toggle

         jsb S03321
         go to L03006

         bank toggle

         jsb S03336
         go to L03006

         nop
L03065:  bank toggle

         jsb S03351
         go to L03006

L03070:  bank toggle

         delayed rom @16
         jsb S07045
         go to L03006

         bank toggle

         delayed rom @16
         jsb S07213
         nop
         nop
         bank toggle

         delayed rom @02
         jsb S01172
         bank toggle

         delayed rom @00
         jsb S00311
         go to L03006

L03110:  jsb S03023
         display toggle
         jsb S03302
         jsb S03023
         jsb S03321
         delayed rom @02
         jsb S01172
         jsb S03023
         delayed rom @05
         jsb S02632
         jsb S03037
         delayed rom @01
         jsb S00562
         jsb S03274
         jsb S03023
         jsb S03336
         jsb S03023
         jsb S03346
         jsb S03336
         if c[m] = 0
           then go to L03140
         delayed rom @01
         jsb S00634
         go to L03143

L03140:  jsb S03302
         0 - c - 1 -> c[s]
         c -> a[s]
L03143:  jsb S03023
         jsb S03277
         jsb S03336
         jsb S03344
         jsb S03023
         delayed rom @05
         jsb S02644
         jsb S03037
         jsb S03344
         jsb S03023
         jsb S03336
         if c[m] = 0
           then go to L03247
         jsb S03023
         jsb S03302
         jsb S03336
         jsb S03344
         jsb S03023
         jsb S03321
         jsb S03346
         jsb S03037
         if b[m] = 0
           then go to L03262
         jsb S03275
L03173:  jsb S03277
         jsb S03023
         delayed rom @05
         jsb S02644
         0 -> c[w]
         c -> data address
         data -> c
         jsb S03300
         jsb S03037
         jsb S03344
         jsb S03274
         if 0 = s 12
           then go to L03214
         jsb S03023
         jsb S03302
         jsb S03037
         jsb S03344
L03214:  if c[s] # 0
           then go to L03304
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 1
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L03313
L03226:  c -> a[w]
         a -> b[w]
L03230:  0 -> s 8
L03231:  jsb S03341
         delayed rom @01
         jsb S00634
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S03037
         jsb S03344
         if c[xs] = 0
           then go to L03245
         c + 1 -> c[xs]
         if c[xs] # 0
           then go to L03253
L03245:  if 0 = s 8
           then go to L03110
L03247:  if 0 = s 14
           then go to L03253
         delayed rom @01
         jsb S00677
L03253:  jsb S03346
         0 - c - 1 -> c[s]
         c + 1 -> c[x]
         c + 1 -> c[x]
L03257:  c -> register 1
         delayed rom @04
         go to L02043

L03262:  jsb S03302
         data -> c
         0 - c - 1 -> c[s]
         jsb S03300
         0 -> c[w]
         p <- 12
         load constant 2
         delayed rom @01
         jsb S00631
         go to L03173

S03274:  jsb S03321
S03275:  delayed rom @01
         go to S00704

S03277:  register -> c 3
S03300:  delayed rom @01
         go to S00557

S03302:  delayed rom @05
         go to S02624

L03304:  0 -> c[x]
         1 -> s 8
         p <- 1
         load constant 1
         a - c -> c[x]
         if n/c go to L03231
         go to L03230

L03313:  if a[x] # 0
           then go to L03304
         c -> a[m]
         if a >= b[m]
           then go to L03226
         go to L03230

S03321:  register -> c 6
         p <- 8
L03323:  b exchange c[w]
         m1 exchange c
         register -> c 8
L03326:  p - 1 -> p
         shift right c[w]
         if p # 2
           then go to L03326
         b exchange c[s]
         a exchange c[w]
         m1 exchange c
         return

S03336:  register -> c 7
         p <- 11
         go to L03323

S03341:  register -> c 5
         p <- 5
         go to L03323

S03344:  delayed rom @01
         go to S00425

S03346:  a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
S03351:  delayed rom @01
         go to S00716

L03353:  c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
L03357:  c - 1 -> c[p]
         if n/c go to L03353
         clear regs
         c -> register 14
         c -> register 15
         m2 exchange c
         delayed rom @15
         go to L06566

S03367:  display toggle
L03370:  0 -> s 15
         if s 15 = 1
           then go to L03370
         display off
         return

         nop
         nop
         nop
L03400:  register -> c 11
         jsb S03444
         c -> register 5
         register -> c 13
         jsb S03444
         go to L03425

L03406:  jsb S03626
         jsb S03576
         jsb S03432
         jsb S03447
         jsb S03600
         jsb S03453
         jsb S03606
         c -> register 5
         jsb S03626
         jsb S03576
         jsb S03612
         jsb S03447
         jsb S03600
         jsb S03453
         jsb S03606
L03425:  jsb S03457
         c -> stack
         register -> c 5
L03430:  delayed rom @00
         go to L00020

S03432:  register -> c 11
         jsb S03602
         jsb S03576
         register -> c 12
L03436:  c -> a[w]
         register -> c 10
         jsb S03604
         jsb S03600
S03442:  delayed rom @01
         go to S00425

S03444:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S03447:  register -> c 10
S03450:  m1 exchange c
         m1 -> c
         0 -> c[x]
S03453:  if c[m] = 0
           then go to L02266
         delayed rom @01
         go to S00634

S03457:  jsb S03752
S03460:  m2 exchange c
         if s 0 = 1
           then go to L03464
         c -> stack
L03464:  m2 -> c
L03465:  return

L03466:  jsb S03617
         jsb S03576
         m2 -> c
         a exchange c[w]
         register -> c 10
         jsb S03604
         register -> c 13
         jsb S03573
         jsb S03432
         jsb S03570
         delayed rom @02
         jsb S01017
         register -> c 11
         go to L03521

L03504:  jsb S03432
         jsb S03576
         m2 -> c
         a exchange c[w]
         register -> c 10
         jsb S03604
         register -> c 11
         jsb S03573
         jsb S03617
         jsb S03570
         delayed rom @02
         jsb S01017
         register -> c 13
L03521:  delayed rom @01
         jsb S00557
         jsb S03600
         jsb S03442
         jsb S03600
         jsb S03453
         jsb S03447
         c -> register 5
         jsb S03432
         jsb S03576
         jsb S03612
         jsb S03570
         jsb S03606
         jsb S03576
         jsb S03617
         jsb S03600
         jsb S03453
         jsb S03752
         c -> stack
         register -> c 5
         go to L03551

L03546:  stack -> a
         c -> stack
         a exchange c[w]
L03551:  delayed rom @14
         go to L06150

S03553:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         go to S00716

L03560:  register -> c 15
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         register -> c 11
         jsb S03450
         jsb S03460
         go to L03430

S03570:  jsb S03600
         delayed rom @01
         go to S00562

S03573:  0 - c - 1 -> c[s]
         delayed rom @01
         jsb S00422
S03576:  delayed rom @02
         go to S01035

S03600:  delayed rom @01
         go to S00765

S03602:  c -> a[w]
S03603:  0 - c - 1 -> c[s]
S03604:  delayed rom @01
         go to S00555

S03606:  if a[s] # 0
           then go to L02266
         delayed rom @04
         go to L02325

S03612:  register -> c 13
         jsb S03602
         jsb S03576
         register -> c 14
         go to L03436

S03617:  register -> c 11
         a exchange c[w]
         register -> c 13
         jsb S03603
         jsb S03576
         register -> c 15
         go to L03436

S03626:  register -> c 10
S03627:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         go to S00711

L03634:  0 -> s 15
         0 -> s 3
         if s 15 = 1
           then go to L03634
         c -> register 5
         if c[m] = 0
           then go to L02271
         if c[s] # 0
           then go to L02271
         delayed rom @04
         jsb S02273
         if c[m] # 0
           then go to L02271
         register -> c 2
         jsb S03754
         c -> register 2
         register -> c 3
         jsb S03754
         c -> register 3
         0 -> c[w]
         jsb S03460
         c -> stack
L03662:  register -> c 1
         c - 1 -> c[x]
         c - 1 -> c[x]
         a exchange c[w]
         register -> c 2
         jsb S03604
         jsb S03754
         if s 3 = 1
           then go to L03703
         a exchange c[w]
         0 -> c[w]
         c -> data address
         data -> c
         a exchange c[w]
         if a[m] # 0
           then go to L03703
         0 -> c[w]
L03703:  c -> register 6
         a exchange c[w]
         register -> c 3
         a exchange c[s]
         m2 -> c
         jsb S03750
         m2 exchange c
         register -> c 6
         a exchange c[w]
         register -> c 3
         jsb S03750
         c -> register 6
         stack -> a
         jsb S03750
         c -> stack
         register -> c 6
         a exchange c[w]
         register -> c 2
         jsb S03750
         c -> register 2
         0 -> c[w]
         c -> data address
         data -> c
         jsb S03553
         c -> register 0
         register -> c 5
         jsb S03627
         c -> register 5
         if s 15 = 1
           then go to L03746
         if c[m] = 0
           then go to L03746
         display toggle
         if c[s] = 0
           then go to L03662
L03746:  m2 -> c
         go to L03430

S03750:  delayed rom @01
         jsb S00420
S03752:  delayed rom @00
         go to S00311

S03754:  delayed rom @01
         go to S00720

L03756:  a exchange c[xs]
         c + 1 -> c[xs]
         c + 1 -> c[xs]
         0 -> a[w]
L03762:  c -> data address
         a exchange c[w]
         c -> data
         a exchange c[w]
         c + 1 -> c[x]
         c + 1 -> c[xs]
         if n/c go to L03762
         0 -> c[w]
         c -> data address
         p <- 2
         load constant 13
         delayed rom @12
         go to L05146

	 .dw @0225			; CRC, bank 0 quad 1 (@02000..@03777)

L04000:  binary
         0 -> c[w]
         keys -> rom address

L04003:  a - 1 -> a[x]
L04004:  a - 1 -> a[x]
L04005:  a - 1 -> a[x]
L04006:  a - 1 -> a[x]
         p <- 4
L04010:  a - 1 -> a[x]
L04011:  a - 1 -> a[x]
L04012:  0 -> s 14
L04013:  shift left a[x]
L04014:  delayed rom @00
         go to L00270

L04016:  if p = 10
           then go to L04126
         if p = 8
           then go to L04051
         p <- 11
         go to L04231

L04024:  a + 1 -> a[x]
L04025:  if p = 5
           then go to L04044
         if p = 1
           then go to L04260
         if p = 4
           then go to L04044
         a + 1 -> a[x]
         shift left a[x]
         if p # 2
           then go to L04040
         p <- 12
L04040:  p + 1 -> p
         a - 1 -> a[x]
         if p # 13
           then go to L04040
L04044:  0 -> s 14
L04045:  delayed rom @12
         go to L05064

L04047:  p <- 7
         go to L04141

L04051:  p <- 1
         load constant 11
         go to L04156

L04054:  a - 1 -> a[p]
         if s 14 = 1
           then go to L05376
         go to L04045

         go to L04070

         go to L04264

         go to L04301

         a + 1 -> a[x]
         if p # 2
           then go to L04303
         p <- 8
         go to L04134

L04070:  if p # 2
           then go to L04277
         p <- 10
         go to L04174

L04074:  p <- 10
         go to L04231

L04076:  p <- 7
         go to L04025

         go to L04375

         go to L04342

         go to L04025

         if p = 8
           then go to L04270
         if p = 10
           then go to L04116
         if p = 9
           then go to L04006
         p <- 1
         load constant 13
L04113:  load constant 9
L04114:  a exchange c[x]
         go to L04044

L04116:  p <- 8
         go to L04135

L04120:  if p # 1
           then go to L04310
         1 -> s 14
         go to L04014

L04124:  p <- 12
         go to L04231

L04126:  p <- 1
         load constant 11
         go to L04214

L04131:  if p = 8
           then go to L05247
L04133:  a + 1 -> a[x]
L04134:  a + 1 -> a[x]
L04135:  a + 1 -> a[x]
         if p = 4
           then go to L05125
         a + 1 -> a[x]
L04141:  a + 1 -> a[x]
         if n/c go to L04317
         if p = 8
           then go to L04557
         if p = 10
           then go to L04337
         if p = 9
           then go to L04004
         p <- 1
         load constant 10
         go to L04113

L04154:  p <- 1
         load constant 10
L04156:  load constant 8
         go to L04114

         go to L04354

         go to L04175

         go to L04176

         if p = 9
           then go to L04401
         if p # 10
           then go to L04177
         if s 4 = 1
           then go to L04124
         delayed rom @15
         go to L06405

L04173:  a + 1 -> a[x]
L04174:  a + 1 -> a[x]
L04175:  a + 1 -> a[x]
L04176:  a + 1 -> a[x]
L04177:  a + 1 -> a[x]
L04200:  if p = 10
           then go to L04205
         if p = 8
           then go to L04205
         p <- 12
L04205:  p - 1 -> p
         go to L04315

L04207:  p <- 1
         load constant 12
         go to L04156

L04212:  p <- 1
         load constant 10
L04214:  load constant 7
         go to L04114

L04216:  p <- 2
         go to L04231

         go to L04273

         go to L04074

         go to L04173

         go to L04016

         if p = 10
           then go to L04212
         if p = 8
           then go to L04154
         p <- 9
L04231:  0 -> a[x]
         go to L04012

L04233:  if p = 8
           then go to L05130
         go to L04134

L04236:  p <- 5
         go to L04010

         go to L04131

         go to L04233

         go to L04254

         if p = 8
           then go to L05173
         if p = 10
           then go to L04334
         if p = 9
           then go to L04003
         p <- 1
         load constant 11
         go to L04113

L04254:  if p # 8
           then go to L04135
         p <- 1
         go to L04231

L04260:  if a[p] # 0
           then go to L04054
         a + 1 -> a[x]
         if n/c go to L04013
L04264:  if p # 2
           then go to L04300
         p <- 10
         go to L04177

L04270:  p <- 1
         load constant 13
         go to L04156

L04273:  if p = 11
           then go to L04216
         p <- 8
         go to L04231

L04277:  a + 1 -> a[x]
L04300:  a + 1 -> a[x]
L04301:  a + 1 -> a[x]
         a + 1 -> a[x]
L04303:  if p = 11
           then go to L04076
         if p = 9
           then go to L04047
         a + 1 -> a[x]
L04310:  if p = 10
           then go to L04315
         if p = 8
           then go to L04315
         p <- 12
L04315:  a + 1 -> a[x]
         if n/c go to L04133
L04317:  a + 1 -> a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
         if n/c go to L04024
         if p = 8
           then go to L04352
         if p = 10
           then go to L04207
         if p = 9
           then go to L04005
         p <- 1
         load constant 12
         go to L04113

L04334:  p <- 1
         load constant 12
         go to L04214

L04337:  p <- 1
         load constant 13
         go to L04214

L04342:  if p = 9
           then go to L04236
         if p = 4
           then go to L05125
         if p # 11
           then go to L04120
         p <- 5
         go to L04011

L04352:  p <- 8
         go to L04174

L04354:  register -> c 8
         if p = 8
           then go to L04561
         if p # 10
           then go to L04174
         if s 4 = 1
           then go to L05176
         clear data registers
         p <- 1
         0 -> c[wp]
         c -> register 8
         shift right c[x]
         shift right c[x]
         load constant 1
         0 -> a[w]
         delayed rom @06
         go to L03357

L04375:  if p # 2
           then go to L04200
         delayed rom @06
         go to L03045

L04401:  clear regs
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
         a - 1 -> a[w]
         if a[w] # 0
           then go to L04541
         jsb S04470
         a exchange c[w]
         p <- 2
         load constant 13
         c -> register 8
         a exchange c[w]
         load constant 1
         jsb S04470
         p <- 1
         load constant 2
         load constant 3
         jsb S04472
         p <- 12
         delayed rom @00
         jsb S00043
         jsb S04536
         delayed rom @04
         jsb S02265
         jsb S04536
         jsb S04523
         jsb S04536
         delayed rom @14
         jsb S06203
         jsb S04536
         delayed rom @06
         jsb S03003
         jsb S04536
         p <- 3
L04457:  load constant 2
         if p # 3
           then go to L04457
         b exchange c[w]
L04463:  load constant 8
         if p # 3
           then go to L04463
         delayed rom @00
         go to L00356

S04470:  p <- 0
         load constant 15
S04472:  p <- 12
         c + 1 -> c[p]
         p <- 0
         m1 exchange c
         m1 -> c
L04477:  c -> data address
         c -> data
         c - 1 -> c[p]
         if n/c go to L04477
         m1 -> c
L04504:  c -> data address
         a exchange c[w]
         data -> c
         a exchange c[w]
         a - c -> a[w]
         if a[w] # 0
           then go to L04541
         c - 1 -> c[p]
         if n/c go to L04504
         clear data registers
         return

L04517:  jsb S04625
L04520:  load constant 3
         go to L04660

L04522:  a -> rom address

S04523:  rom checksum

L04524:  jsb S04621
         go to L04777

L04526:  jsb S04665
L04527:  load constant 5
L04530:  load constant 1
         return

L04532:  jsb S04625
         go to L04600

L04534:  jsb S04665
         go to L04650

S04536:  c + 1 -> c[p]
         if 0 = s 5
           then go to L04661
L04541:  p <- 12
         0 -> c[x]
         m2 exchange c
         delayed rom @00
         go to L00340

L04546:  jsb S04625
L04547:  load constant 7
L04550:  go to L04667

L04551:  jsb S04625
         go to L04742

L04553:  jsb S04625
         go to L04737

L04555:  jsb S04665
         go to L04520

L04557:  delayed rom @14
         go to L06330

L04561:  if 0 = s 4
           then go to L05203
         c -> a[x]
         shift right c[x]
         c + 1 -> c[xs]
         shift right c[x]
         delayed rom @07
         go to L03756

L04571:  jsb S04665
L04572:  load constant 2
         go to L04530

L04574:  0 -> s 4
         register -> c 8
         go to L04561

         jsb S04665
L04600:  load constant 7
         go to L04530

L04602:  jsb S04665
         go to L04737

L04604:  jsb S04621
         go to L04757

L04606:  jsb S04665
L04607:  load constant 6
         go to L04530

L04611:  jsb S04625
         go to L04607

L04613:  jsb S04625
         go to L04757

L04615:  load constant 3
         go to L04550

         jsb S04621
         go to L04677

S04621:  p <- 9
         load constant 2
         load constant 2
         1 -> s 13
S04625:  p <- 7
         load constant 2
         load constant 5
         go to L04670

L04631:  jsb S04665
         go to L04657

L04633:  jsb S04625
         go to L04657

L04635:  jsb S04665
         go to L04547

         jsb S04621
         go to L04717

L04641:  jsb S04625
         go to L04777

L04643:  jsb S04665
         go to L04777

L04645:  jsb S04625
         go to L04572

L04647:  jsb S04625
L04650:  load constant 2
         go to L04660

         go to L04546

         go to L04633

         go to L04635

         go to L04631

         go to L04547

L04657:  load constant 7
L04660:  load constant 3
L04661:  return

L04662:  jsb S04625
L04663:  load constant 3
         go to L04530

S04665:  p <- 7
         load constant 2
L04667:  load constant 4
L04670:  p <- 4
         return

         go to L04662

         go to L04703

         go to L04604

         go to L04705

         go to L04663

L04677:  shift left a[x]
         shift left a[x]
         delayed rom @13
         go to L05727

L04703:  jsb S04625
         go to L04677

L04705:  jsb S04665
         go to L04677

         go to L04571

         go to L04645

         go to L04527

         go to L04721

         go to L04725

         go to L04761

         go to L04763

         go to L04722

L04717:  a + 1 -> a[x]
         if n/c go to L04677
L04721:  jsb S04625
L04722:  load constant 3
L04723:  load constant 2
         return

L04725:  jsb S04625
         go to L04717

         go to L04741

         go to L04551

         go to L04745

         go to L04517

         go to L04553

         go to L04555

         go to L04602

         go to L04520

L04737:  a + 1 -> a[x]
         if n/c go to L04717
L04741:  jsb S04665
L04742:  load constant 2
         go to L04723

L04744:  jsb S04665
L04745:  load constant 4
         go to L04530

         go to L04744

         go to L04606

         go to L04607

         go to L04611

         go to L04613

         go to L04524

         go to L04765

         go to L04615

L04757:  a + 1 -> a[x]
         if n/c go to L04737
L04761:  jsb S04665
         go to L04722

L04763:  jsb S04665
         go to L04717

L04765:  jsb S04665
         go to L04757

         go to L04526

         go to L04532

         go to L04600

         go to L04647

         go to L04641

         go to L04534

         go to L04643

         go to L04650

L04777:  a + 1 -> a[x]
         delayed rom @11
         go to L04757

S05002:  1 -> s 4
S05003:  a exchange c[w]
         m1 exchange c
         0 -> s 13
         jsb S05313
         jsb S05165
         0 -> c[w]
         c - 1 -> c[m]
         if s 11 = 1
           then go to L05063
         go to L05362

S05015:  a exchange c[w]
         0 -> c[w]
         p <- 10
         load constant 6
         if 0 = s 13
           then go to L05025
         p <- 8
         load constant 3
L05025:  p <- 0
         load constant 7
         b exchange c[w]
         register -> c 8
         p <- 1
         0 -> a[x]
         a exchange c[p]
         shift right a[x]
         if c[wp] = 0
           then go to L05051
         a + 1 -> a[x]
         a + 1 -> a[x]
         c + 1 -> c[x]
         p <- 0
         go to L05047

L05044:  decimal
         a + b -> a[x]
         binary
L05047:  c + 1 -> c[p]
         if n/c go to L05044
L05051:  p <- 13
         a exchange c[ms]
L05053:  shift left a[w]
         p + 1 -> p
         if p # 10
           then go to L05053
         a exchange c[wp]
         a exchange c[m]
         load constant 9
         a exchange c[m]
L05063:  return

L05064:  if 0 = s 4
           then go to L05362
         a -> b[w]
         jsb S05211
         if s 10 = 1
           then go to L05123
L05072:  c -> register 8
         jsb S05313
         if 0 = s 10
           then go to L05077
         0 -> c[w]
L05077:  p <- 1
         a exchange b[w]
         b exchange c[w]
         go to L05107

L05103:  shift left a[w]
         shift left a[w]
         p + 1 -> p
         p + 1 -> p
L05107:  c - 1 -> c[xs]
         if n/c go to L05103
         a exchange b[wp]
         if p = 1
           then go to L05117
         p - 1 -> p
         p - 1 -> p
         a exchange b[wp]
L05117:  b exchange c[w]
         c -> data
         jsb S05170
         go to L05176

L05123:  c - 1 -> c[xs]
         if n/c go to L05072
L05125:  p <- 3
         delayed rom @00
         go to L00340

L05130:  register -> c 8
         p <- 1
         if c[wp] = 0
           then go to L05154
         c - 1 -> c[p]
         if n/c go to L05146
         load constant 6
         c + 1 -> c[p]
         c + 1 -> c[p]
         if n/c go to L05145
         p <- 1
         load constant 1
         go to L05146

L05145:  c - 1 -> c[x]
L05146:  c -> register 8
         if s 4 = 1
           then go to L05176
         jsb S05002
         jsb S05302
         go to L05206

L05154:  c -> a[x]
         shift right a[x]
         a exchange c[p]
         shift right c[wp]
         c + 1 -> c[x]
         load constant 6
         go to L05146

L05163:  shift right c[w]
         shift right c[w]
S05165:  a - 1 -> a[xs]
         if n/c go to L05163
         a exchange c[x]
S05170:  0 -> c[x]
         c -> data address
         return

L05173:  if s 4 = 1
           then go to L04574
         1 -> s 4
L05176:  binary
         jsb S05003
         jsb S05015
         delayed rom @10
         go to L04124

L05203:  p <- 1
         jsb S05276
L05205:  0 -> s 2
L05206:  m2 -> c
         delayed rom @00
         go to L00033

S05211:  binary
         0 -> s 10
         register -> c 8
         c -> a[x]
L05215:  p <- 1
         if a[wp] # 0
           then go to L05223
L05220:  c + 1 -> c[p]
L05221:  c -> register 8
L05222:  return

L05223:  0 -> a[p]
         if a[wp] # 0
           then go to L05231
         load constant 15
         load constant 14
         go to L05215

L05231:  c -> a[x]
         a + c -> a[p]
         a + c -> a[p]
         if n/c go to L05220
         a - 1 -> a[x]
         shift left a[x]
         shift left a[x]
         a - c -> a[xs]
         if a[xs] # 0
           then go to L05244
         1 -> s 10
L05244:  c - 1 -> c[x]
         0 -> c[p]
         go to L05221

L05247:  if s 4 = 1
           then go to L05300
         1 -> s 12
L05252:  register -> c 8
         p <- 1
         if c[wp] # 0
           then go to L05260
         c + 1 -> c[p]
         c -> register 8
L05260:  jsb S05002
         jsb S05302
         register -> c 8
         m1 exchange c
         a exchange c[w]
         if 0 = s 12
           then go to L05360
         jsb S05273
         m1 -> c
         jsb S05314
         go to L05361

S05273:  jsb S05211
         if 0 = s 10
           then go to L05222
S05276:  0 -> c[wp]
         go to L05221

L05300:  jsb S05273
         go to L05176

S05302:  jsb S05015
         0 -> s 4
         delayed rom @06
         go to S03367

L05306:  p <- 2
         load constant 6
         load constant 0
         load constant 8
         go to L05331

S05313:  register -> c 8
S05314:  a exchange c[x]
         p <- 1
         shift left a[x]
         shift right a[wp]
         a exchange c[x]
         1 -> s 11
         if c[x] = 0
           then go to L05332
         0 -> s 11
         if c[wp] = 0
           then go to L05306
         c - 1 -> c[x]
         c + 1 -> c[p]
L05331:  c -> data address
L05332:  a exchange c[x]
         data -> c
         return

L05335:  a + 1 -> a[p]
         if a[p] # 0
           then go to L05446
         if s 4 = 1
           then go to L05710
         if 0 = s 7
           then go to L05346
         if s 9 = 1
           then go to L05470
L05346:  delayed rom @00
         go to L00152

L05350:  jsb S05211
         if s 10 = 1
           then go to L05203
         if 0 = s 15
           then go to L05357
         if 0 = s 7
           then go to L05205
L05357:  display toggle
L05360:  jsb S05313
L05361:  jsb S05165
L05362:  p <- 2
         load constant 10
         load constant 10
         p <- 1
         shift left a[x]
         if a >= c[xs]
           then go to L05750
         if a >= c[p]
           then go to L05335
         if s 4 = 1
           then go to L05501
         shift right a[x]
L05376:  load constant 0
         load constant 7
         b exchange c[x]
         p <- 1
         register -> c 8
         0 -> c[wp]
         decimal
         a - 1 -> a[x]
         if n/c go to L05606
         0 -> s 2
L05410:  c -> register 8
         delayed rom @00
         go to L00304

S05413:  p <- 9
S05414:  load constant 2
         load constant 1
         return

         delayed rom @07
         go to L03400

L05421:  c + 1 -> c[xs]
         if n/c go to L05472
         jsb S05441
         go to L05474

L05425:  a exchange c[w]
         register -> c 8
         shift right c[x]
         c + 1 -> c[xs]
         shift right c[x]
         if a >= c[wp]
           then go to L05435
         go to L05554

L05435:  delayed rom @00
         go to L00340

         delayed rom @07
         go to L03466

S05441:  data -> c
         a exchange c[w]
S05443:  m2 -> c
         decimal
         return

L05446:  a + 1 -> a[p]
         if n/c go to L05734
         p <- 6
         load constant 2
         load constant 2
         if s 4 = 1
           then go to L05710
         jsb S05714
         go to L05762

         delayed rom @07
         go to L03504

L05461:  p <- 4
         if s 4 = 1
           then go to L04522
         jsb S05443
         p <- 0
         delayed rom @15
         a -> rom address

L05470:  delayed rom @14
         go to L06002

L05472:  jsb S05441
         0 - c - 1 -> c[s]
L05474:  delayed rom @01
         jsb S00420
         go to L05671

         delayed rom @06
         go to L03050

L05501:  p <- 9
         load constant 2
         load constant 5
         p <- 6
         load constant 7
         p <- 4
         shift left a[wp]
         go to L05711

L05511:  c + 1 -> c[xs]
         if n/c go to L05421
         jsb S05441
         delayed rom @01
         jsb S00555
         go to L05671

         delayed rom @15
         go to L06475

L05521:  a + 1 -> a[p]
         if n/c go to L05564
         a - 1 -> a[p]
         p <- 2
         load constant 7
         if a >= c[xs]
           then go to L05461
         p <- 6
         load constant 2
         load constant 5
         if s 4 = 1
           then go to L05710
         jsb S05443
         a -> rom address

         0 - c - 1 -> c[s]
         y -> a
         delayed rom @01
         jsb S00420
         if c[s] = 0
           then go to L05206
         go to L05557

S05546:  p <- 1
         load constant 1
         load constant 3
         go to L05720

S05552:  shift right a[x]
         shift right a[x]
L05554:  a exchange c[x]
         c -> data address
         return

L05557:  if c[m] = 0
           then go to L05206
         delayed rom @12
         jsb S05273
         go to L05746

L05564:  p <- 2
         load constant 5
         a - c -> a[xs]
         if n/c go to L05725
         a + c -> a[xs]
         p <- 7
         load constant 2
         load constant 2
         jsb S05552
         if 0 = s 4
           then go to L05762
L05577:  p <- 4
         load constant 1
         0 -> c[p]
L05602:  c + 1 -> c[p]
         c - 1 -> c[x]
         if n/c go to L05602
         return

L05606:  if 0 = s 2
           then go to L05613
         a - 1 -> a[x]
         if n/c go to L05613
         go to L05410

L05613:  a - 1 -> a[x]
         if n/c go to L05617
         c + 1 -> c[p]
         if n/c go to L05410
L05617:  binary
         c - 1 -> c[wp]
L05621:  binary
         c - 1 -> c[x]
         decimal
         a - b -> a[wp]
         if n/c go to L05621
         a + b -> a[wp]
         shift left a[x]
         a exchange c[p]
         c -> a[x]
         shift left a[x]
         shift left a[x]
         a exchange c[x]
         if a >= c[xs]
           then go to L05125
         a exchange c[x]
         go to L05410

L05641:  a + 1 -> a[xs]
         if n/c go to L05651
         jsb S05413
         if s 4 = 1
           then go to L05704
         jsb S05546
L05647:  m2 -> c
         go to L05671

L05651:  load constant 7
         p <- 1
         if a >= c[p]
           then go to L05461
         shift left a[w]
         a exchange c[xs]
         shift right a[w]
         a exchange c[x]
         if s 4 = 1
           then go to L05673
         jsb S05714
         c + 1 -> c[xs]
         if n/c go to L05511
         jsb S05441
         delayed rom @01
         jsb S00627
L05671:  delayed rom @14
         go to L06154

L05673:  jsb S05413
         p <- 6
         load constant 8
         load constant 1
         p <- 6
L05700:  c - 1 -> c[p]
         c + 1 -> c[xs]
         if n/c go to L05700
         go to L05710

L05704:  p <- 6
         load constant 7
         load constant 3
         shift left a[x]
L05710:  p <- 3
L05711:  shift left a[wp]
         a exchange c[wp]
         return

S05714:  shift right a[x]
         p <- 1
         load constant 0
         load constant 9
L05720:  shift right a[x]
         p <- 1
         a + c -> c[wp]
         if n/c go to L05425
         go to L05435

L05725:  p <- 7
         jsb S05414
L05727:  jsb S05552
         if s 4 = 1
           then go to L05577
         delayed rom @15
         go to L06457

L05734:  a + 1 -> a[p]
         if n/c go to L05767
         p <- 6
         load constant 2
         load constant 4
         if s 4 = 1
           then go to L05710
         shift right a[x]
L05744:  shift right a[x]
         f exchange a[x]
L05746:  delayed rom @12
         go to L05206

L05750:  if a >= c[p]
           then go to L05461
         a + 1 -> a[xs]
         if n/c go to L05641
         p <- 9
         load constant 2
         load constant 2
         if s 4 = 1
           then go to L05704
         jsb S05546
L05762:  data -> c
         delayed rom @07
         jsb S03460
         delayed rom @00
         go to L00020

L05767:  a + 1 -> a[p]
         if n/c go to L05521
         p <- 6
         jsb S05414
         if s 4 = 1
           then go to L05710
         jsb S05714
         go to L05647

         .dw @0471			; CRC, bank 0 quad 2 (@04000..@05777)

L06000:  0 -> b[x]
         go to L06024

L06002:  p <- 4
         m2 -> c
         shift left a[wp]
L06005:  a -> b[w]
         decimal
         p <- 5
         shift right a[wp]
         shift right a[wp]
         shift right a[wp]
         a -> b[x]
         0 -> a[x]
         p <- 1
         if b[xs] = 0
           then go to L06024
         a - b -> a[wp]
         if n/c go to L06000
         a -> b[wp]
         0 -> a[x]
L06024:  rotate left a
         a + b -> a[x]
L06026:  if a[s] # 0
           then go to L06033
         a - 1 -> a[x]
         shift left a[ms]
         go to L06026

L06033:  a exchange c[x]
         a exchange b[w]
         delayed rom @00
         jsb S00311
         if p = 13
           then go to L07257
L06041:  delayed rom @00
         go to L00253

L06043:  p <- 5
         a exchange c[p]
         0 - c - 1 -> c[p]
         a exchange c[p]
         go to L06005

L06050:  0 -> s 7
         1 -> s 0
L06052:  if s 7 = 1
           then go to L06072
         delayed rom @00
         jsb S00363
         0 -> b[w]
         p <- 12
         c + 1 -> c[p]
         c -> a[p]
         p <- 5
L06063:  a exchange b[wp]
         1 -> s 9
         if a[m] # 0
           then go to L06041
         0 -> s 9
         a exchange b[wp]
         go to L06041

L06072:  if c[m] = 0
           then go to L06050
         delayed rom @00
         jsb S00212
         p <- 5
         if b[wp] = 0
           then go to L06063
         go to L06041

L06102:  delayed rom @04
         jsb S02121
         0 -> s 7
         y -> a
         m2 -> c
         if a[s] # 0
           then go to L06112
         go to L06136

L06112:  a exchange c[m]
         if c[xs] # 0
           then go to L06175
         go to L06121

L06116:  if c[x] = 0
           then go to L06175
         c - 1 -> c[x]
L06121:  shift left a[ms]
         if a[m] # 0
           then go to L06116
         if c[x] # 0
           then go to L06136
         a exchange c[s]
         c -> a[s]
         c + c -> c[s]
         c + c -> c[s]
         a + c -> c[s]
         if c[s] = 0
           then go to L06136
         1 -> s 7
L06136:  y -> a
         0 -> a[s]
         a exchange c[w]
         0 -> s 1
         delayed rom @02
         jsb S01167
         if 0 = s 7
           then go to L06147
         0 - c - 1 -> c[s]
L06147:  stack -> a
L06150:  delayed rom @16
         go to L07171

L06152:  p <- 13
         go to L06176

L06154:  clear status
L06155:  jsb S06317
         if s 8 = 1
           then go to L06302
         m2 exchange c
         delayed rom @00
         go to L00022

L06163:  delayed rom @02
         jsb S01353
         go to L06150

L06166:  0 -> s 1
         delayed rom @03
         jsb S01416
         go to L06150

L06172:  delayed rom @04
         jsb S02322
         go to L06150

L06175:  p <- 7
L06176:  delayed rom @00
         go to L00340

L06200:  delayed rom @01
         jsb S00674
         go to L06150

S06203:  rom checksum

L06204:  stack -> a
         delayed rom @01
         jsb S00420
         go to L06150

L06210:  stack -> a
         jsb S06245
         go to L06150

L06213:  y -> a
         delayed rom @01
         jsb S00627
         go to L06147

L06217:  c - 1 -> c[x]
         c - 1 -> c[x]
         y -> a
         jsb S06245
         go to L06150

L06224:  0 -> b[w]
         b exchange c[m]
L06226:  y -> a
         a exchange c[w]
         c - 1 -> c[x]
         c - 1 -> c[x]
         delayed rom @01
         jsb S00631
         go to L06150

L06235:  y -> a
         a exchange c[w]
         0 - c - 1 -> c[s]
         delayed rom @01
         jsb S00420
         a exchange c[w]
         go to L06226

S06244:  c -> a[w]
S06245:  delayed rom @01
         go to S00555

L06247:  c -> a[w]
         register -> c 11
         jsb S06306
         m2 -> c
         jsb S06244
         register -> c 12
         jsb S06310
         y -> a
         register -> c 13
         jsb S06306
         y -> a
         a exchange c[w]
         jsb S06244
         register -> c 14
         jsb S06310
         y -> a
         m2 -> c
         jsb S06245
         register -> c 15
         jsb S06310
         0 -> a[w]
         a + 1 -> a[s]
         shift right a[w]
         register -> c 10
         jsb S06306
         if 0 = s 8
           then go to L06471
L06302:  p <- 6
         go to L06176

L06304:  p <- 1
         go to L06176

S06306:  0 -> b[w]
         a exchange b[m]
S06310:  if 0 = s 13
           then go to L06315
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
L06315:  delayed rom @01
         jsb S00422
S06317:  delayed rom @00
         jsb S00311
         if c[m] = 0
           then go to L06326
         if p # 13
           then go to L06326
         1 -> s 8
L06326:  c -> data
         return

L06330:  0 -> c[w]
         p <- 2
         load constant 13
         p <- 9
         c + 1 -> c[p]
         c -> a[w]
         load constant 7
         b exchange c[w]
         register -> c 8
         a - c -> a[xs]
         decimal
L06343:  a + b -> a[m]
         a - 1 -> a[xs]
         if n/c go to L06343
         shift right c[x]
         shift right c[x]
         c -> a[x]
         p <- 0
         load constant 7
         a + c -> a[x]
         p <- 4
         a + 1 -> a[x]
         a - 1 -> a[x]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[w]
         p <- 12
         load constant 13
         load constant 9
         p <- 8
         load constant 15
         load constant 15
         load constant 10
         load constant 9
         a exchange c[w]
         0 -> c[w]
         p <- 11
         load constant 6
         p <- 5
         load constant 6
         b exchange c[w]
L06402:  delayed rom @06
         jsb S03367
         go to L06503

L06405:  m2 -> c
         0 -> b[w]
         c -> a[w]
         go to L06402

S06411:  c -> data address
         m2 -> c
         if s 0 = 1
           then go to L06416
         c -> stack
L06416:  data -> c
L06417:  a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 2
         c + 1 -> c[x]
         return

L06426:  delayed rom @14
         go to L06224

L06430:  shift right a[x]
         delayed rom @13
         go to L05744

L06433:  binary
         if s 2 = 1
           then go to L06445
         0 -> s 7
         0 -> s 6
         1 -> s 2
         if s 12 = 1
           then go to L06447
         delayed rom @12
         go to L05252

L06445:  delayed rom @12
         jsb S05273
L06447:  0 -> s 2
L06450:  delayed rom @12
         go to L05206

L06452:  0 -> c[x]
         jsb S06600
         delayed rom @01
         jsb S00555
L06456:  m2 exchange c
L06457:  m2 -> c
         clear status
         1 -> s 0
         1 -> s 1
         delayed rom @14
         go to L06155

L06465:  stack -> a
         c -> stack
         a exchange c[w]
         go to L06556

L06471:  delayed rom @16
         jsb S07173
L06473:  delayed rom @00
         go to L00035

L06475:  if s 7 = 1
           then go to L06501
         delayed rom @00
         jsb S00050
L06501:  delayed rom @00
         jsb S00212
L06503:  0 -> c[x]
         binary
         p <- 2
         load constant 6
         display off
         display toggle
L06511:  c - 1 -> c[x]
         if n/c go to L06511
         display off
         delayed rom @00
         go to L00304

L06516:  delayed rom @07
         go to L03634

L06520:  1 -> s 13
L06521:  delayed rom @14
         go to L06247

L06523:  1 -> s 10
L06524:  y -> a
         0 -> s 11
         0 -> s 3
         0 -> s 12
         0 -> s 13
         a exchange c[w]
         p <- 12
         delayed rom @16
         go to L07377

L06535:  0 -> s 10
         delayed rom @04
         jsb S02273
         if c[m] # 0
           then go to L06152
         go to L06524

L06543:  delayed rom @17
         jsb S07663
         select rom go to L03546

L06546:  c -> stack
         go to L06473

L06550:  shift right a[x]
         delayed rom @04
         a -> rom address

L06553:  if s 7 = 1
           then go to L06645
         0 - c - 1 -> c[s]
L06556:  delayed rom @00
         go to L00020

L06560:  0 -> c[w]
         c -> register 0
         c -> register 1
         c -> register 2
         c -> register 3
         c -> register 4
L06566:  p <- 1
         load constant 2
         c -> data address
         clear data registers
         c - 1 -> c[x]
         c -> data address
L06574:  0 -> c[w]
         c -> register 15
         go to L06450

         select rom go to L06200

S06600:  c -> data address
         m2 -> c
         go to L06417

L06603:  0 - c - 1 -> c[s]
L06604:  delayed rom @14
         go to L06204

L06606:  0 -> c[w]
         c -> register 10
         c -> register 11
         c -> register 12
         c -> register 13
         c -> register 14
         go to L06574

L06615:  delayed rom @07
         go to L03406

         0 -> c[x]
         jsb S06411
         delayed rom @01
         jsb S00627
         go to L06556

L06624:  delayed rom @04
         jsb S02273
         go to L06671

L06627:  delayed rom @04
         jsb S02273
         m1 -> c
         go to L06671

L06633:  delayed rom @06
         go to L03012

L06635:  0 -> c[w]
         go to L06473

         0 -> c[x]
         c + 1 -> c[x]
         jsb S06411
         delayed rom @01
         jsb S00555
         go to L06556

L06645:  if s 9 = 1
           then go to L06043
         select rom go to L00250

L06650:  down rotate
         go to L06556

         go to L06520

         go to L06615

         go to L06521

         go to L06430

         go to L06433

         delayed rom @00
         go to L00145

L06661:  0 -> c[x]
         c + 1 -> c[x]
         jsb S06600
         delayed rom @01
         jsb S00627
         go to L06456

L06667:  delayed rom @01
         jsb S00720
L06671:  select rom go to L07272

         select rom go to L07273

         go to L06452

         select rom go to L07275

         go to L06516

         go to L06546

L06677:  shift left a[x]
         shift left a[x]
         if s 1 = 1
           then go to L06550
         delayed rom @13
         go to L05727

L06705:  delayed rom @14
         go to L06172

         go to L06705

         go to L06721

         go to L06604

         go to L06723

         go to L06661

         go to L06560

         select rom go to L07316

         go to L06553

L06717:  a + 1 -> a[p]
         if n/c go to L06677
L06721:  delayed rom @14
         go to L06102

L06723:  delayed rom @14
         go to L06052

L06725:  delayed rom @07
         go to L03560

         go to L06426

         go to L06741

         go to L06603

         go to L06650

         select rom go to L07334

         go to L06606

         select rom go to L07336

         go to L06465

L06737:  a + 1 -> a[p]
         if n/c go to L06717
L06741:  delayed rom @14
         go to L06166

L06743:  delayed rom @14
         go to L06210

L06745:  delayed rom @14
         go to L06213

         go to L06523

         go to L06627

         go to L06743

         go to L06624

         select rom go to L07354

         select rom go to L07355

         go to L06667

         go to L06635

L06757:  a + 1 -> a[p]
         if n/c go to L06737
L06761:  delayed rom @14
         go to L06163

L06763:  delayed rom @14
         go to L06235

L06765:  delayed rom @14
         go to L06217

         go to L06535

         go to L06725

         go to L06745

         go to L06761

         select rom go to L07374

         go to L06763

         go to L06633

         go to L06765

         a + 1 -> a[p]
         delayed rom @15
         go to L06757

S07002:  jsb S07342
         register -> c 1
         jsb S07372
         register -> c 2
         0 - c - 1 -> c[s]
         jsb S07372
         0 -> c[w]
         load constant 3
         load constant 6
         if s 10 = 1
           then go to L07016
         load constant 5
L07016:  p <- 0
         1 -> s 10
         load constant 4
         delayed rom @01
         jsb S00631
         delayed rom @00
         go to S00311

L07025:  jsb S07342
         delayed rom @01
         jsb S00716
L07030:  b exchange c[w]
         b -> c[w]
         jsb S07045
         m2 -> c
         c -> data
         0 -> c[w]
         c -> data address
         b exchange c[w]
         c -> data
         jsb S07212
         b exchange c[w]
         0 -> c[w]
         go to L07240

S07045:  if c[s] # 0
           then go to L06304
         c - 1 -> c[x]
         if n/c go to L07367
         shift right c[m]
L07052:  p <- 10
         0 -> c[x]
         if c[wp] # 0
           then go to L06304
         p <- 0
         load constant 8
         a exchange c[w]
         register -> c 8
         0 -> c[ms]
         c + 1 -> c[s]
         shift right c[w]
         c + 1 -> c[xs]
         shift right c[w]
L07067:  binary
         a + 1 -> a[x]
         decimal
         a - c -> a[m]
         if n/c go to L07067
         binary
         a - c -> c[x]
         if n/c go to L07105
         a exchange c[x]
         c -> a[x]
         c -> data address
         data -> c
L07103:  decimal
         return

L07105:  if c[x] # 0
           then go to L06304
         p <- 1
         load constant 1
         load constant 13
         c -> a[x]
         register -> c 4
         go to L07103

L07115:  stack -> a
         jsb S07173
         register -> c 5
         p <- 5
         load constant 1
         jsb S07204
         delayed rom @01
         jsb S00627
         delayed rom @04
         jsb S02273
         jsb S07204
         delayed rom @01
         jsb S00555
         if c[x] # 0
           then go to L07351
         if c[m] = 0
           then go to L07351
L07136:  c -> a[w]
L07137:  p - 1 -> p
         rotate left a
         if p # 7
           then go to L07137
         m2 -> c
         binary
         c - 1 -> c[s]
         if c[x] # 0
           then go to L07151
         shift right c[w]
L07151:  p <- 4
         load constant 15
         a exchange c[w]
         a exchange c[p]
         0 -> c[w]
         p <- 11
         load constant 3
         p <- 9
         load constant 3
         clear status
         b exchange c[w]
         0 -> s 1
         if s 2 = 1
           then go to L06503
         delayed rom @10
         go to L04124

L07171:  jsb S07173
         go to L07257

S07173:  m1 exchange c
         jsb S07327
         m1 -> c
         m2 exchange c
         c -> register 14
         0 -> c[w]
         c -> data address
         m2 -> c
         return

S07204:  c -> a[w]
         0 -> c[w]
         p <- 12
         load constant 7
         return

S07211:  jsb S07342
S07212:  jsb S07045
S07213:  0 -> c[x]
         p <- 0
         binary
         load constant 9
         a - c -> a[x]
         p <- 0
         load constant 7
         delayed rom @06
         go to L03065

L07224:  jsb S07211
         b exchange c[w]
         m2 -> c
         if c[s] # 0
           then go to L06304
         jsb S07306
         c - 1 -> c[x]
         if n/c go to L07236
         0 -> c[x]
         shift right c[m]
L07236:  if c[x] # 0
           then go to L06304
L07240:  p <- 12
         a exchange c[wp]
         p <- 10
         if a[wp] # 0
           then go to L06304
         a exchange c[wp]
         b exchange c[w]
L07247:  rotate left a
         rotate left a
         c - 1 -> c[xs]
         if n/c go to L07247
         a exchange c[w]
         go to L07303

L07255:  register -> c 14
L07256:  jsb S07340
L07257:  delayed rom @00
         go to L00020

L07261:  shift right c[w]
         if s 11 = 1
           then go to L07266
         if 0 = s 13
           then go to L07763
L07266:  if a >= c[p]
           then go to L07760
         delayed rom @17
         go to L07763

L07272:  go to L07171

L07273:  jsb S07327
         go to L07255

L07275:  jsb S07342
         jsb S07045
         jsb S07340
         jsb S07342
         delayed rom @01
         jsb S00711
L07303:  c -> data
         m2 -> c
         go to L07257

S07306:  p <- 12
         if c[w] = 0
           then go to L07314
         c - 1 -> c[p]
         if c[w] = 0
           then go to L07315
L07314:  c + 1 -> c[p]
L07315:  return

L07316:  0 -> s 10
         jsb S07340
         jsb S07002
         c -> stack
         register -> c 2
         0 - c - 1 -> c[s]
         c -> stack
         jsb S07002
         go to L07257

S07327:  0 -> c[w]
         p <- 1
         load constant 1
         c -> data address
         return

L07334:  0 -> c[w]
         go to L07030

L07336:  delayed rom @06
         go to L03010

S07340:  delayed rom @07
         go to S03460

S07342:  0 -> c[w]
         c -> data address
         data -> c
         c -> a[w]
         0 -> b[w]
         a exchange b[m]
         return

L07351:  load constant 7
         p <- 12
         go to L07136

L07354:  go to L07025

L07355:  jsb S07211
         0 -> a[s]
         p <- 10
         0 -> a[wp]
         0 -> c[w]
         c + 1 -> c[x]
         delayed rom @01
         jsb S00521
         jsb S07306
         go to L07256

L07367:  if c[x] # 0
           then go to L06304
         go to L07052

S07372:  delayed rom @01
         go to S00557

L07374:  go to L07224

L07375:  c -> register 7
         m2 -> c
L07377:  if c[s] # 0
           then go to L06152
L07401:  jsb S07527
         p <- 4
         if c[wp] # 0
           then go to L06152
         jsb S07537
         0 -> c[w]
         p <- 11
         load constant 3
         if s 12 = 1
           then go to L07261
         p <- 11
         if a >= c[m]
           then go to L07422
         a - 1 -> a[m]
         p <- 4
         0 -> a[wp]
         p <- 12
L07422:  load constant 1
         a + c -> a[w]
         jsb S07647
         jsb S07573
         a exchange c[w]
         jsb S07665
         jsb S07623
         jsb S07666
         jsb S07630
         jsb S07655
         jsb S07554
         jsb S07665
L07436:  c -> register 5
         jsb S07563
         a - c -> c[x]
         0 -> c[m]
         jsb S07773
         jsb S07554
         jsb S07666
         jsb S07605
         load constant 1
         load constant 2
         load constant 1
         load constant 5
         jsb S07665
         jsb S07605
         jsb S07612
         p <- 8
         load constant 4
         jsb S07620
         jsb S07626
         jsb S07666
         jsb S07743
         jsb S07743
         jsb S07565
L07465:  jsb S07650
         jsb S07573
         a exchange c[w]
         jsb S07665
         jsb S07623
         jsb S07666
         register -> c 5
         jsb S07665
         jsb S07554
         jsb S07665
         jsb S07605
         jsb S07636
         jsb S07626
         jsb S07527
         p <- 11
         jsb S07517
         load constant 0
         load constant 4
         if a >= c[m]
           then go to L07700
         register -> c 8
         c - 1 -> c[m]
         p <- 3
         0 -> c[p]
         jsb S07572
         go to L07465

S07517:  shift right a[w]
         register -> c 8
         a exchange c[wp]
         p <- 9
         a exchange c[wp]
         c -> register 8
S07525:  c -> a[w]
         go to L07601

S07527:  c - 1 -> c[x]
         if n/c go to L07534
         0 -> c[x]
         shift right c[wp]
         go to L07676

L07534:  if c[x] # 0
           then go to L06152
         go to L07676

S07537:  if s 3 = 1
           then go to L07676
         c -> a[m]
         p <- 10
         shift left a[wp]
         shift left a[wp]
         jsb S07743
         a exchange c[m]
         shift left a[m]
         shift left a[m]
         a exchange c[wp]
         a exchange c[w]
         go to L07676

S07554:  jsb S07605
         load constant 4
         load constant 7
         load constant 8
         load constant 1
         load constant 6
         load constant 4
S07563:  p <- 0
         go to L07621

S07565:  shift right a[w]
         p <- 11
         register -> c 8
         a exchange c[wp]
         a exchange c[x]
S07572:  c -> register 8
S07573:  register -> c 8
         a exchange c[w]
         shift left a[m]
         shift left a[m]
S07577:  shift left a[m]
         shift left a[m]
L07601:  shift left a[m]
         0 -> a[x]
         a + 1 -> a[x]
         0 -> a[s]
S07605:  0 -> c[w]
         p <- 0
         load constant 2
         p <- 12
         return

S07612:  c -> register 6
         load constant 3
         load constant 6
         if s 12 = 1
           then go to L07622
         load constant 5
S07620:  load constant 2
L07621:  load constant 5
L07622:  return

S07623:  jsb S07573
         load constant 4
         0 -> c[x]
S07626:  delayed rom @01
         go to S00627

S07630:  register -> c 8
         p <- 9
         0 -> c[wp]
         jsb S07525
         jsb S07636
         go to L07652

S07636:  load constant 3
         load constant 0
         if s 12 = 1
           then go to L07645
         load constant 6
         p <- 7
         load constant 1
L07645:  c - 1 -> c[x]
         return

S07647:  jsb S07565
S07650:  c + c -> c[x]
         jsb S07612
L07652:  delayed rom @01
         jsb S00555
         go to S07666

S07655:  register -> c 8
         p <- 7
         0 -> c[wp]
         a exchange c[w]
         jsb S07577
         go to L07672

S07663:  c -> register 6
         register -> c 7
S07665:  0 - c - 1 -> c[s]
S07666:  delayed rom @04
         jsb S02273
         m1 -> c
         a exchange c[w]
L07672:  register -> c 6
S07673:  delayed rom @01
         jsb S00420
         c -> register 6
L07676:  c -> a[w]
         return

L07700:  jsb S07630
         jsb S07527
         jsb S07743
         p <- 7
         jsb S07517
         load constant 1
         load constant 4
         p <- 12
         if a >= c[m]
           then go to L07715
         load constant 9
         load constant 9
         go to L07721

L07715:  load constant 8
         load constant 7
         p <- 5
         load constant 1
L07721:  a + c -> c[m]
         jsb S07537
         c - 1 -> c[x]
         delayed rom @01
         jsb S00521
         c -> a[w]
         display toggle
         if s 11 = 1
           then go to L07746
         y -> a
         jsb S07772
         1 -> s 11
L07735:  if s 10 = 1
           then go to L07375
         c -> a[w]
         m2 -> c
         jsb S07673
         go to L07436

S07743:  shift right a[m]
         shift right a[m]
         return

L07746:  if 0 = s 10
           then go to L07115
         m2 -> c
         jsb S07772
         jsb S07663
         1 -> s 12
         stack -> a
         c -> stack
         a exchange c[w]
         go to L07401

L07760:  p <- 9
         1 -> s 13
         0 -> a[p]
L07763:  jsb S07647
         jsb S07630
         jsb S07655
         if 0 = s 11
           then go to L06543
         0 -> s 11
         go to L07735

S07772:  a - c -> c[w]
S07773:  if c[w] # 0
           then go to L06152
         register -> c 5
         return

         .dw @0424			; CRC, bank 0 quad 3 (@06000..@07777)

	 .bank 1
	 .org @2000

L12000:  p <- 1
L12001:  delayed rom @00
         go to L00340

L12003:  p <- 0
         go to L12001

S12005:  delayed rom @06
         go to S13022

S12007:  delayed rom @06
         go to S13070

S12011:  delayed rom @06
         go to S13045

S12013:  delayed rom @06
         go to S13061

S12015:  delayed rom @06
         go to S13074

S12017:  delayed rom @06
         go to S13050

L12021:  m1 exchange c
         delayed rom @07
         jsb S13761
         m1 -> c
         c -> register 3
         0 -> c[w]
         c -> data address
         jsb S12013
         delayed rom @06
         jsb S13033
         if c[xs] = 0
           then go to L12037
         c + c -> c[x]
         if n/c go to L12371
L12037:  jsb S12011
         jsb S12013
         jsb S12011
         delayed rom @06
         jsb S13017
         if c[m] = 0
           then go to L12051
         jsb S12013
         jsb S12165
         go to L12061

L12051:  m2 -> c
         jsb S12007
         jsb S12015
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
         0 -> b[w]
         a exchange b[m]
L12061:  0 -> c[w]
         c -> data address
         jsb S12011
         m2 -> c
         jsb S12007
         0 - c - 1 -> c[s]
         b exchange c[w]
         0 -> c[w]
         c -> data address
         delayed rom @06
L12073:  jsb S13053
         delayed rom @06
         jsb S13030
         jsb S12013
         delayed rom @06
         jsb S13025
         m1 exchange c
         jsb S12011
         if s 12 = 1
           then go to L12310
         m2 -> c
         jsb S12007
         jsb S12015
         0 -> c[w]
         c -> data address
         m1 -> c
         delayed rom @06
         jsb S13026
         0 - c - 1 -> c[s]
         m1 exchange c
         register -> c 1
         a exchange c[w]
S12121:  m1 -> c
         c -> register 1
         delayed rom @07
         jsb S13761
         register -> c 3
         delayed rom @06
         jsb S13026
         0 -> c[w]
         c -> data address
         register -> c 1
         jsb S12005
         c -> register 1
         jsb S12013
         jsb S12011
         m2 -> c
         jsb S12007
         jsb S12015
         0 -> c[w]
         c -> data address
         a exchange b[w]
         jsb S12013
         jsb S12005
         jsb S12011
         delayed rom @06
         jsb S13056
         delayed rom @06
         jsb S13017
         if c[m] = 0
           then go to L12167
         jsb S12017
         jsb S12161
         go to L12211

S12161:  a exchange c[w]
         m1 exchange c
         a exchange c[w]
         b exchange c[w]
S12165:  delayed rom @06
         go to L13041

L12167:  jsb S12017
         m2 -> c
         jsb S12007
         jsb S12015
         0 -> c[w]
         c -> data address
         a exchange c[w]
         c -> register 7
         delayed rom @06
         jsb S13062
         register -> c 7
         delayed rom @06
         jsb S13030
         0 -> c[w]
         load constant 5
         c - 1 -> c[x]
         delayed rom @06
         jsb S13030
L12211:  jsb S12011
         m2 -> c
         jsb S12007
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         0 -> c[w]
         c -> data address
         jsb S12017
         delayed rom @06
         jsb S13033
         register -> c 1
         jsb S12005
         c -> register 1
L12227:  m2 -> c
         delayed rom @06
         jsb S13014
         m2 exchange c
         m2 -> c
         if c[s] = 0
           then go to L13234
         if s 12 = 1
           then go to L13255
         delayed rom @06
         jsb S13056
         if b[m] = 0
           then go to L13265
         register -> c 1
         m1 exchange c
         m1 -> c
         0 -> c[x]
         jsb S12161
         delayed rom @07
         jsb S13771
         register -> c 15
         jsb S12005
         p <- 12
         0 -> c[wp]
         c -> data address
         load constant 1
         load constant 5
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
S12265:  if n/c go to L12272
L12266:  0 -> c[x]
         c -> a[w]
         a -> b[w]
         go to L12314

L12272:  if a[x] # 0
S12273:    then go to L12302
         a exchange b[m]
         if a >= c[m]
           then go to L12300
         go to L12266

L12300:  a exchange b[m]
         go to L12314

L12302:  p <- 1
         0 -> c[x]
         load constant 1
         a - c -> c[x]
         if n/c go to L12313
         go to L12314

L12310:  jsb S12013
         jsb S12011
         go to L12227

L12313:  1 -> s 12
L12314:  delayed rom @06
         jsb S13053
         jsb S12165
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S12017
S12322:  delayed rom @06
         jsb S13025
         jsb S12011
         if s 12 = 1
           then go to L13265
         delayed rom @06
         go to L13202

L12331:  display off
         display toggle
         if s 12 = 1
           then go to L12350
         delayed rom @06
         jsb S13056
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
         register -> c 1
         jsb S12005
         delayed rom @06
         jsb S13053
         jsb S12161
         c -> register 1
L12350:  m2 -> c
         jsb S12007
         b exchange c[w]
         0 -> c[w]
         c -> data address
         delayed rom @06
         jsb S13056
         jsb S12005
         delayed rom @06
         jsb S13053
         jsb S12161
         jsb S12011
         delayed rom @06
         jsb S13056
         jsb S12011
         display off
         go to L12227

L12371:  c - 1 -> c[xs]
         c - 1 -> c[xs]
         if c[xs] = 0
           then go to L12037
         0 -> c[wp]
         c - 1 -> c[wp]
         p <- 2
         load constant 1
         if s 12 = 1
           then go to L13260
         delayed rom @06
         jsb S13061
         delayed rom @06
         jsb S13017
         delayed rom @06
         jsb S13104
         c -> register 1
         m2 exchange c
         go to L12441

L12414:  c -> register 1
         m2 exchange c
         if s 0 = 1
           then go to L12421
         c -> stack
L12421:  m2 -> c
         delayed rom @06
         go to L13262

L12424:  delayed rom @00
         go to L00304

L12426:  register -> c 6
         c -> a[w]
         delayed rom @07
         jsb S13771
         0 -> c[w]
         p <- 12
         load constant 5
         c - 1 -> c[x]
         delayed rom @06
         jsb S13026
         c -> register 15
L12441:  p <- 4
         delayed rom @00
         go to L00340

L12444:  0 -> b[s]
         if a[s] # 0
           then go to L13370
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
           then go to L12467
         shift right b[w]
L12467:  shift right c[w]
         a exchange c[x]
         0 -> c[w]
         a exchange b[w]
         p <- 13
         load constant 5
         shift right c[w]
         go to L12505

L12477:  c + 1 -> c[p]
L12500:  a - c -> a[w]
         if n/c go to L12477
         a + c -> a[w]
         shift left a[w]
         p - 1 -> p
L12505:  shift right c[wp]
         if p # 0
           then go to L12500
         0 -> c[p]
         a exchange b[w]
         delayed rom @01
         go to L00520

L12514:  b exchange c[x]
         0 -> c[w]
         p <- 1
         go to L12521

L12520:  c + 1 -> c[x]
L12521:  a - b -> a[wp]
         if n/c go to L12520
         a + b -> a[wp]
         load constant 2
         c -> data address
         data -> c
         a exchange c[w]
         p <- 2
         load constant 6
         go to L12536

L12533:  rotate left a
         rotate left a
         c - 1 -> c[xs]
L12536:  c - 1 -> c[wp]
         if n/c go to L12533
         decimal
         delayed rom @06
         go to L13006

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
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S13003:  bank toggle

         jsb S13047
         nop
L13006:  bank toggle

         return

L13010:  bank toggle

         go to L13247

S13012:  bank toggle

         go to L13376

S13014:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S13017:  bank toggle

S13020:  0 -> b[w]
         a exchange b[m]
S13022:  m1 exchange c
         m1 -> c
         0 -> c[x]
S13025:  bank toggle

S13026:  0 -> b[w]
         a exchange b[m]
S13030:  m1 exchange c
         m1 -> c
         0 -> c[x]
S13033:  bank toggle

S13034:  0 -> b[w]
         a exchange b[m]
         m1 exchange c
         m1 -> c
         0 -> c[x]
L13041:  bank toggle

S13042:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S13045:  bank toggle

         go to L13274

S13047:  rom checksum

S13050:  bank toggle

         p <- 12
         go to L13306

S13053:  bank toggle

L13054:  a + 1 -> a[p]
         return

S13056:  bank toggle

S13057:  delayed rom @07
         go to S13767

S13061:  bank toggle

S13062:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
L13065:  bank toggle

         delayed rom @05
         go to L12514

S13070:  bank toggle

         delayed rom @05
         go to L12444

         nop
S13074:  bank toggle

L13075:  a exchange c[w]
L13076:  1 -> s 1
         display off
         display toggle
         bank toggle

         0 -> s 13
         go to L13114

S13104:  bank toggle

         display off
         if 0 = s 11
           then go to L12021
         go to L13175

         0 -> b[w]
         b exchange c[m]
         go to L13075

L13114:  0 -> a[s]
         p <- 10
         0 -> a[wp]
         p <- 12
         if a[p] # 0
           then go to L13124
         shift left a[m]
         go to L13125

L13124:  a + 1 -> a[x]
L13125:  if a[w] # 0
           then go to L13131
         1 -> s 13
         go to L13054

L13131:  a - 1 -> a[p]
         if a[w] # 0
           then go to L13054
         return

L13135:  0 - c - 1 -> c[s]
         c -> a[w]
         jsb S13057
         data -> c
         jsb S13020
         if c[s] = 0
           then go to L13627
         0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         register -> c 3
         a exchange c[w]
         jsb S13057
         register -> c 6
         jsb S13034
         0 - c - 1 -> c[s]
         m2 exchange c
         register -> c 7
         a exchange c[w]
         register -> c 5
         jsb S13034
         m2 -> c
         jsb S13022
         jsb S13003
         jsb S13045
         register -> c 6
         a exchange c[w]
         register -> c 7
         0 - c - 1 -> c[s]
         jsb S13034
         go to L13076

L13175:  jsb S13045
L13176:  0 -> s 12
L13177:  0 -> s 15
         if s 15 = 1
           then go to L13177
L13202:  if s 15 = 1
           then go to L13265
L13204:  0 -> s 11
         0 -> a[w]
         0 -> b[w]
         jsb S13045
         jsb S13056
         p <- 0
         0 -> b[p]
         jsb S13045
         jsb S13057
         data -> c
         jsb S13070
         if s 10 = 1
           then go to L12003
         jsb S13057
         data -> c
         m2 exchange c
         if s 12 = 1
           then go to L13231
         0 -> c[w]
         c -> register 1
         go to L13234

L13231:  if s 0 = 1
           then go to L13234
         c -> stack
L13234:  m2 -> c
         jsb S13070
         jsb S13074
         jsb S13057
         if s 13 = 1
           then go to L12331
         a exchange c[w]
         0 - c - 1 -> c[s]
         jsb S13042
         jsb S13056
         go to L13076

L13247:  register -> c 1
         jsb S13012
         jsb S13062
         jsb S13045
         1 -> s 12
         go to L13204

L13255:  jsb S13056
         jsb S13050
         jsb S13033
L13260:  jsb S13104
         c -> register 2
L13262:  0 -> s 0
         delayed rom @00
         go to L00020

L13265:  jsb S13053
         jsb S13017
         c + 1 -> c[x]
         c + 1 -> c[x]
         jsb S13104
         c -> register 1
         go to L13262

L13274:  m2 -> c
         if s 4 = 1
           then go to L12424
         c -> register 1
         decimal
         jsb S13012
         jsb S13062
         jsb S13045
         jsb S13057
         go to L13176

L13306:  if c[s] # 0
           then go to L13370
         if c[xs] # 0
           then go to L13370
         c -> a[w]
L13313:  a -> b[w]
         shift left a[ms]
         if a[wp] # 0
           then go to L13366
         a + 1 -> a[x]
         if a >= c[x]
           then go to L13324
         c + 1 -> c[xs]
         if n/c go to L13010
L13324:  0 -> c[w]
         c + 1 -> c[p]
         shift right c[w]
         c + 1 -> c[s]
         b exchange c[w]
L13331:  if b[p] = 0
           then go to L13335
         shift right b[wp]
         c + 1 -> c[x]
L13335:  0 -> a[w]
         a - c -> a[p]
         if n/c go to L13343
         shift left a[w]
L13341:  a + b -> a[w]
         if n/c go to L13341
L13343:  a - c -> a[s]
         if n/c go to L13352
         shift right a[wp]
         a + 1 -> a[w]
         c + 1 -> c[x]
L13350:  a + b -> a[w]
         if n/c go to L13350
L13352:  a exchange b[wp]
         c - 1 -> c[p]
         if n/c go to L13331
         c - 1 -> c[s]
         if n/c go to L13331
L13357:  shift left a[w]
         a -> b[x]
         0 -> c[ms]
         a + b -> a[wp]
         a + c -> a[w]
         a exchange c[ms]
         go to L13010

L13366:  a - 1 -> a[x]
S13367:  if n/c go to L13313
L13370:  p <- 7
         delayed rom @00
         go to L00340

         nop
         nop
         nop
L13376:  display off
         0 -> s 9
L13400:  jsb S13767
         data -> c
         jsb S13603
         if s 10 = 1
           then go to L12000
         jsb S13767
L13406:  c -> register 5
L13407:  0 -> s 8
         0 -> s 11
         0 -> s 14
         0 -> c[w]
         c -> register 6
         c -> register 7
L13415:  register -> c 5
         jsb S13603
         m1 exchange c
         jsb S13605
         jsb S13767
         m1 -> c
         a exchange c[w]
         if s 14 = 1
           then go to L13531
         jsb S13607
         if c[m] = 0
           then go to L13446
         1 -> s 14
         if c[s] = 0
           then go to L13436
         0 - c - 1 -> c[s]
         1 -> s 8
L13436:  c -> register 6
L13437:  c -> register 7
         register -> c 5
         a exchange c[w]
         jsb S13771
         a exchange c[w]
         c -> register 15
         jsb S13767
L13446:  register -> c 5
         if s 9 = 1
           then go to L13474
         delayed rom @06
         jsb S13062
         c -> register 5
         0 - c - 1 -> c[s]
         a exchange c[w]
         jsb S13767
         data -> c
S13460:  jsb S13611
         if c[s] = 0
           then go to L13415
         data -> c
         c -> register 5
         register -> c 6
L13466:  if c[m] = 0
           then go to L12414
         if s 11 = 1
           then go to L13524
         1 -> s 9
         go to L13407

L13474:  delayed rom @06
         jsb S13014
         c -> register 5
         if c[s] = 0
           then go to L13415
         register -> c 6
         if c[m] = 0
           then go to L12414
L13504:  if 0 = s 11
           then go to L12003
         jsb S13771
         register -> c 15
L13510:  c -> a[w]
         jsb S13767
         shift right a[m]
         if a[x] # 0
           then go to L13516
         shift right a[m]
L13516:  register -> c 8
         p <- 11
         a exchange c[wp]
         a exchange c[x]
         c -> register 8
         go to L13615

L13524:  jsb S13771
         register -> c 15
         delayed rom @06
         jsb S13062
         go to L13510

L13531:  if 0 = s 8
           then go to L13534
         0 - c - 1 -> c[s]
L13534:  jsb S13607
         register -> c 6
         jsb S13613
         c -> register 6
         if s 11 = 1
           then go to L13556
         if c[s] = 0
           then go to L13546
         1 -> s 11
         go to L13446

L13546:  0 - c - 1 -> c[s]
         c -> a[w]
         register -> c 7
         jsb S13611
         if c[s] = 0
           then go to L13446
         register -> c 6
         go to L13437

L13556:  if c[s] # 0
           then go to L13446
L13560:  jsb S13767
         data -> c
         c -> register 5
         0 -> c[w]
         c -> register 6
         register -> c 5
L13566:  jsb S13603
         jsb S13605
         jsb S13767
         register -> c 6
         jsb S13611
         c -> register 6
         register -> c 5
         delayed rom @06
         jsb S13062
         c -> register 5
         if c[s] = 0
           then go to L12426
         go to L13566

S13603:  delayed rom @06
         go to S13070

S13605:  delayed rom @06
         go to S13074

S13607:  delayed rom @06
         go to S13026

S13611:  delayed rom @06
         go to S13020

S13613:  delayed rom @06
         go to S13022

L13615:  m2 -> c
         if s 0 = 1
           then go to L13621
         c -> stack
L13621:  jsb S13767
         c -> register 1
         c -> register 5
         c -> register 7
         0 -> s 11
         m2 exchange c
L13627:  register -> c 1
         display toggle
         jsb S13603
         m1 exchange c
         m1 -> c
L13634:  jsb S13605
         m1 -> c
         jsb S13607
         jsb S13767
         register -> c 5
         jsb S13613
         c -> register 5
         register -> c 1
         jsb S13603
         jsb S13605
         jsb S13767
         a exchange c[w]
         delayed rom @06
         jsb S13014
         0 -> c[w]
         p <- 12
         load constant 5
         c - 1 -> c[x]
         delayed rom @06
         jsb S13030
         m2 -> c
         jsb S13613
         m1 exchange c
         register -> c 1
         jsb S13603
         jsb S13605
         m1 -> c
         jsb S13607
         m1 exchange c
         jsb S13767
         register -> c 1
         jsb S13603
         c -> a[w]
         jsb S13767
         m1 -> c
         jsb S13607
         register -> c 7
         jsb S13613
         c -> register 7
         register -> c 1
         jsb S13603
         jsb S13605
         m2 -> c
         jsb S13611
         m2 exchange c
         jsb S13767
         register -> c 1
         delayed rom @06
         jsb S13062
         c -> register 1
         c -> a[w]
         if s 11 = 1
           then go to L13135
         register -> c 8
         a exchange c[w]
         shift left a[ms]
         0 -> a[s]
         0 -> a[x]
         p <- 12
         if a[p] # 0
           then go to L13733
         shift left a[m]
         go to L13734

L13733:  a + 1 -> a[x]
L13734:  a exchange c[w]
         0 - c - 1 -> c[s]
         jsb S13611
         if c[s] # 0
           then go to L13627
         register -> c 5
         c -> register 6
         register -> c 7
         a exchange c[w]
         jsb S13771
         m2 -> c
         c -> register 15
         jsb S13767
         1 -> s 11
         c -> register 5
         c -> register 7
         jsb S13761
         a exchange c[w]
L13756:  c -> register 3
         jsb S13767
         go to L13627

S13761:  0 -> c[w]
         c + 1 -> c[xs]
L13763:  c + 1 -> c[xs]
         shift right c[w]
L13765:  c -> data address
         return

S13767:  0 -> c[w]
         go to L13765

S13771:  0 -> c[w]
         go to L13763

         nop
         nop
         nop
         nop

	 .dw @0662			; CRC, bank 1 quad 1 (@12000..@13777)

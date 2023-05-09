; 37E model-specific firmware, uses 1820-2162 CPU ROM
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

	 .copyright "Copyright 2022 Eric Smith <spacewar@gmail.com>"
	 .license "GPL-v3.0-only"

         .arch woodstock

         .include "1820-2122.inc"

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
         jsb S03501
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
L02072:  if s 11 = 0
           then go to L03506
         jsb S02124
         jsb S02126
         jsb S02263
         jsb S02022
S02100:  delayed rom @01
         go to S00425

S02102:  0 -> s 10
S02103:  0 -> s 3
         0 -> s 12
         0 -> s 13
         0 -> s 14
         1 -> s 11
         if s 3 = 0
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
           then go to L03506
         if c[xs] # 0
           then go to L03506
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
         if s 10 = 0
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
         go to L03337

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
         go to L03233

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
           then go to L03237
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
           then go to L03070
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
         if s 12 = 0
           then go to L02573
         jsb S02661
L02543:  if s 12 = 0
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
         go to S03567

S02631:  c -> register 6
S02632:  if s 14 = 1
           then go to L02646
L02634:  register -> c 4
         if s 11 = 0
           then go to L02651
S02637:  c -> a[w]
         0 -> b[w]
         a exchange b[m]
         return

S02643:  c -> register 5
S02644:  if s 14 = 1
           then go to L02634
L02646:  register -> c 2
         if s 11 = 0
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
         go to L03070


; factorial
xft100: if c[s] # 0
           then go to L03063
         if c[xs] # 0
           then go to L03063
         c -> a[w]
xft110:  a -> b[w]
         shift left a[ms]
         if a[wp] # 0
           then go to xft120
         a + 1 -> a[x]
         if a >= c[x]
           then go to xft130
         c + 1 -> c[xs]
         if n/c go to L03066
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
         go to L03066		; in some othe rmodels, return instruction

xft120:  a - 1 -> a[x]
         if n/c go to xft110
L03063:  p <- 7
         delayed rom @00
         go to L00340		; err0?

L03066:  delayed rom @00
         go to L00020

L03070:  jsb S03264
         display toggle
         jsb S03262
         jsb S03264
         jsb S03270
         delayed rom @02
         jsb S01172
         jsb S03264
         delayed rom @05
         jsb S02632
         jsb S03266
         delayed rom @01
         jsb S00562
         jsb S03254
         jsb S03264
         jsb S03305
         jsb S03264
         jsb S03315
         jsb S03305
         if c[m] = 0
           then go to L03120
         delayed rom @01
         jsb S00634
         go to L03123

L03120:  jsb S03262
         0 - c - 1 -> c[s]
         c -> a[s]
L03123:  jsb S03264
         jsb S03257
         jsb S03305
         jsb S03313
         jsb S03264
         delayed rom @05
         jsb S02644
         jsb S03266
         jsb S03313
         jsb S03264
         jsb S03305
         if c[m] = 0
           then go to L03227
         jsb S03264
         jsb S03262
         jsb S03305
         jsb S03313
         jsb S03264
         jsb S03270
         jsb S03315
         jsb S03266
         if b[m] = 0
           then go to L03242
         jsb S03255
L03153:  jsb S03257
         jsb S03264
         delayed rom @05
         jsb S02644
         0 -> c[w]
         c -> data address
         data -> c
         jsb S03260
         jsb S03266
         jsb S03313
         jsb S03254
         if s 12 = 0
           then go to L03174
         jsb S03264
         jsb S03262
         jsb S03266
         jsb S03313
L03174:  if c[s] # 0
           then go to L03322
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 1
         a exchange c[x]
         c -> a[x]
         c + c -> c[x]
         if n/c go to L03331
L03206:  c -> a[w]
         a -> b[w]
L03210:  0 -> s 8
L03211:  jsb S03310
         delayed rom @01
         jsb S00634
         0 - c - 1 -> c[s]
         c -> a[s]
         jsb S03266
         jsb S03313
         if c[xs] = 0
           then go to L03225
         c + 1 -> c[xs]
         if c[xs] # 0
           then go to L03233
L03225:  if s 8 = 0
           then go to L03070
L03227:  if s 14 = 0
           then go to L03233
         delayed rom @01
         jsb S00677
L03233:  jsb S03315
         0 - c - 1 -> c[s]
         c + 1 -> c[x]
         c + 1 -> c[x]
L03237:  c -> register 1
         delayed rom @04
         go to L02043

L03242:  jsb S03262
         data -> c
         0 - c - 1 -> c[s]
         jsb S03260
         0 -> c[w]
         p <- 12
         load constant 2
         delayed rom @01
         jsb S00631
         go to L03153

S03254:  jsb S03270
S03255:  delayed rom @01
         go to S00704

S03257:  register -> c 3
S03260:  delayed rom @01
         go to S00557

S03262:  delayed rom @05
         go to S02624

S03264:  delayed rom @02
         go to S01035

S03266:  delayed rom @01
         go to S00765

S03270:  register -> c 6
         p <- 8
L03272:  b exchange c[w]
         m1 exchange c
         register -> c 8
L03275:  p - 1 -> p
         shift right c[w]
         if p # 2
           then go to L03275
         b exchange c[s]
         a exchange c[w]
         m1 exchange c
         return

S03305:  register -> c 7
         p <- 11
         go to L03272

S03310:  register -> c 5
         p <- 5
         go to L03272

S03313:  delayed rom @01
         go to S00425

S03315:  a exchange c[s]
         0 - c - 1 -> c[s]
         a exchange c[s]
         delayed rom @01
         go to S00716

L03322:  0 -> c[x]
         1 -> s 8
         p <- 1
         load constant 1
         a - c -> c[x]
         if n/c go to L03211
         go to L03210

L03331:  if a[x] # 0
           then go to L03322
         c -> a[m]
         if a >= b[m]
           then go to L03206
         go to L03210

L03337:  0 -> b[s]
         p <- 7
         if a[s] # 0
           then go to L02267
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
           then go to L03363
         shift right b[w]
L03363:  shift right c[w]
         a exchange c[x]
         0 -> c[w]
         a exchange b[w]
         p <- 13
         load constant 5
         shift right c[w]
         delayed rom @07
         go to L03406

         nop
         nop
         nop
         nop
L03400:  c + 1 -> c[p]
L03401:  a - c -> a[w]
         if n/c go to L03400
         a + c -> a[w]
         shift left a[w]
         p - 1 -> p
L03406:  shift right c[wp]
         if p # 0
           then go to L03401
         0 -> c[p]
         a exchange b[w]
         delayed rom @01
         go to L00520

L03415:  register -> c 13
         jsb S03465
         jsb S03500
         c -> stack
         register -> c 11
         jsb S03465
L03423:  delayed rom @00
         go to L00020

L03425:  jsb S03642
         jsb S03613
         jsb S03450
         jsb S03470
         jsb S03615
         jsb S03474
         jsb S03622
         c -> register 5
         jsb S03642
         jsb S03613
         jsb S03626
         jsb S03470
         jsb S03615
         jsb S03474
         jsb S03622
         jsb S03500
         c -> stack
         register -> c 5
         go to L03423

S03450:  register -> c 11
         jsb S03617
         jsb S03613
         register -> c 12
L03454:  c -> a[w]
         register -> c 10
         jsb S03620
         jsb S03615
S03460:  m1 exchange c
         0 - c - 1 -> c[s]
         m1 exchange c
S03463:  delayed rom @01
         go to S00425

S03465:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
S03470:  register -> c 10
S03471:  m1 exchange c
         m1 -> c
         0 -> c[x]
S03474:  if c[m] = 0
           then go to L02266
         delayed rom @01
         go to S00634

S03500:  jsb S03766
S03501:  m2 exchange c
         if s 0 = 1
           then go to L03505
         c -> stack
L03505:  m2 -> c
L03506:  return

         jsb S03633
         jsb S03613
         m2 -> c
         a exchange c[w]
         register -> c 10
         jsb S03620
         register -> c 13
         jsb S03607
         jsb S03450
         jsb S03604
         delayed rom @02
         jsb S01017
         register -> c 11
         go to L03542

L03525:  jsb S03450
         jsb S03613
         m2 -> c
         a exchange c[w]
         register -> c 10
         jsb S03620
         register -> c 11
         jsb S03607
         jsb S03633
         jsb S03604
         delayed rom @02
         jsb S01017
         register -> c 13
L03542:  delayed rom @01
         jsb S00557
         jsb S03615
         jsb S03463
         jsb S03615
         jsb S03474
         jsb S03470
         c -> register 5
         jsb S03450
         jsb S03613
         jsb S03626
         jsb S03604
         jsb S03622
         jsb S03613
         jsb S03633
         jsb S03615
         jsb S03474
         jsb S03766
         c -> stack
         register -> c 5
         go to L03423

S03567:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         go to S00716

         register -> c 15
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         register -> c 11
         jsb S03471
         jsb S03501
         go to L03423

S03604:  jsb S03615
         delayed rom @01
         go to S00562

S03607:  m1 exchange c
         m1 -> c
         0 -> c[x]
         jsb S03460
S03613:  delayed rom @02
         go to S01035

S03615:  delayed rom @01
         go to S00765

S03617:  c -> a[w]
S03620:  delayed rom @01
         go to S00555

S03622:  if a[s] # 0
           then go to L02266
         delayed rom @04
         go to L02325

S03626:  register -> c 13
         jsb S03617
         jsb S03613
         register -> c 14
         go to L03454

S03633:  register -> c 11
         a exchange c[w]
         register -> c 13
         jsb S03620
         jsb S03613
         register -> c 15
         go to L03454

S03642:  register -> c 10
S03643:  0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         go to S00711

L03650:  0 -> s 15
         0 -> s 3
         if s 15 = 1
           then go to L03650
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
         jsb S03770
         c -> register 2
         register -> c 3
         jsb S03770
         c -> register 3
         0 -> c[w]
         jsb S03501
         c -> stack
L03676:  register -> c 1
         c - 1 -> c[x]
         c - 1 -> c[x]
         a exchange c[w]
         register -> c 2
         jsb S03620
         jsb S03770
         if s 3 = 1
           then go to L03717
         a exchange c[w]
         0 -> c[w]
         c -> data address
         data -> c
         a exchange c[w]
         if a[m] # 0
           then go to L03717
         0 -> c[w]
L03717:  c -> register 6
         a exchange c[w]
         register -> c 3
         a exchange c[s]
         m2 -> c
         jsb S03764
         m2 exchange c
         register -> c 6
         a exchange c[w]
         register -> c 3
         jsb S03764
         c -> register 6
         stack -> a
         jsb S03764
         c -> stack
         register -> c 6
         a exchange c[w]
         register -> c 2
         jsb S03764
         c -> register 2
         0 -> c[w]
         c -> data address
         data -> c
         jsb S03567
         c -> register 0
         register -> c 5
         jsb S03643
         c -> register 5
         if s 15 = 1
           then go to L03762
         if c[m] = 0
           then go to L03762
         display toggle
         if c[s] = 0
           then go to L03676
L03762:  m2 -> c
         go to L03423

S03764:  delayed rom @01
         jsb S00420
S03766:  delayed rom @00
         go to S00311

S03770:  delayed rom @01
         go to S00720

         nop
         nop
         nop
         nop
         nop

         .dw @0105			; CRC, bank 0 quad 1 (@02000..@03777)

L04000:  keys -> rom address

L04001:  go to L04006

L04002:  jsb S04371
         delayed rom @01
         jsb S00627
         go to L04011

L04006:  jsb S04371
         delayed rom @01
         jsb S00555
L04011:  m2 exchange c
         m2 -> c
L04013:  1 -> s 1
         clear status
         1 -> s 0
         go to L04046

L04017:  a + 1 -> a[x]
L04020:  if s 13 = 1
           then go to L04271
         if s 12 = 1
           then go to L04332
         if s 11 = 1
           then go to L04201
         if s 10 = 1
           then go to L04033
         jsb S04173
         delayed rom @00
         go to L00150

L04033:  jsb S04335
         a exchange c[w]
         data -> c
         a exchange c[w]
         if p # 11
           then go to L04232
         0 - c - 1 -> c[s]
L04042:  delayed rom @01
         jsb S00420
L04044:  0 -> s 1
         clear status
L04046:  delayed rom @00
         jsb S00311
         c -> data
         m2 -> c
         if p = 13
           then go to L04726
         delayed rom @00
         go to L00022

L04056:  0 -> c[w]
         go to L04170

         a + 1 -> a[x]          ; key 15 - FV      y^x
         a + 1 -> a[x]          ; key 14 - PMT     sqrt
         a + 1 -> a[x]          ; key 13 - PV      1/x
         a + 1 -> a[x]          ; key 12 - i       12/
L04064:  0 -> c[x]		; key 11 - n       12x
         jsb S04342
         if s 11 = 1
           then go to L04202
         shift left a[x]
         if s 13 = 1
           then go to L04500
         if s 14 = 0
           then go to L04123
         if a[x] # 0
           then go to L04255
         go to L04265

         go to L04330		; key 74 - Sigma+  Sigma-

         go to L04347		; key 73 - .

         go to L04020		; key 72 - 0

         if s 13 = 1		; key 71 - /       n!
           then go to L04737
         if s 12 = 0
           then go to L04431
         p - 1 -> p
L04110:  p - 1 -> p
L04111:  p - 1 -> p
L04112:  0 -> s 12
         1 -> s 10
L04114:  delayed rom @00
         go to L00271

L04116:  if s 13 = 1
           then go to L04534
         delayed rom @11
         go to L04420

L04122:  a + 1 -> a[p]
L04123:  if s 1 = 0
           then go to L04013
         delayed rom @04
         a -> rom address

L04127:  down rotate
         go to L04306

L04131:  if s 10 = 1
           then go to L04731
         if s 11 = 1
           then go to L04731
         if s 12 = 1
           then go to L04731
         a + 1 -> a[x]
         a + 1 -> a[x]		; key 54 - 6
         a + 1 -> a[x]          ; key 53 - 5
         if n/c go to L04317	; key 52 - 4

         if s 13 = 1		; key 51 - +       std dev
           then go to L04733
         if s 12 = 0
           then go to L04511
         go to L04112

L04150:  if s 13 = 0
           then go to L04056
         delayed rom @00
         go to L00011

L04154:  if s 13 = 1
           then go to L04646
         delayed rom @11
         go to L04523

         go to L04150		; key 34 - CLx     CL ALL

         go to L04273		; key 33 - x<>y    Rdn

         go to L04301		; key 32 - CHS     CL FIN

         if s 13 = 1            ; key 31 - ENTER^  AMORT
           then go to L04310
         if s 12 = 1
           then go to L04543	; STO ENTER^ self test
         c -> stack
L04170:  1 -> s 0
L04171:  delayed rom @00
         go to L00033

S04173:  p <- 12
         0 -> s 14
         0 -> s 10
         0 -> s 11
         0 -> s 12
         return

L04201:  jsb S04335
L04202:  jsb S04365
         a exchange c[w]
         go to L04306

L04205:  if p # 9
           then go to L04042
         delayed rom @01
         jsb S00627
         go to L04044

L04212:  0 -> s 11
         1 -> s 14
         go to L04114

L04215:  jsb S04173
         delayed rom @00
         go to L00250

         go to L04250		; key 25 - f

         go to L04154		; key 24 - %T      PRICE

         go to L04116		; key 23 - %       Delta%

         go to L04312		; key 22 - RCL     LN

         if s 13 = 1		; key 21 - STO     e^x
           then go to L04504
         0 -> s 1
         jsb S04173
         1 -> s 12
         go to L04114

L04232:  if p # 10
           then go to L04205
         delayed rom @01
         jsb S00555
         go to L04044

L04237:  a + 1 -> a[x]
         a + 1 -> a[x]		; key 44 - 9
         a + 1 -> a[x]		; key 43 - 8
         if n/c go to L04131	; key 42 - 7

         if s 13 = 1		; key 41 - -       mean
           then go to L04436
         if s 12 = 0
           then go to L04510
         go to L04111

L04250:  if s 11 = 1		; key 25 - f
           then go to L04212
         jsb S04173
         1 -> s 13
         go to L04114

L04255:  p <- 1
         a - 1 -> a[p]
         if a[x] # 0
           then go to L04122
         jsb S04365
         delayed rom @01
         jsb S00555
         go to L04306

L04265:  jsb S04365
         delayed rom @01
         jsb S00627
         go to L04306

L04271:  f exchange a[x]
         go to L04171

L04273:  if s 13 = 1
           then go to L04127
         stack -> a
         c -> stack
         a exchange c[w]
         go to L04306

L04301:  if s 13 = 1
           then go to L04355
         if s 7 = 1
           then go to L04215
         0 - c - 1 -> c[s]
L04306:  delayed rom @00
         go to L00020

L04310:  delayed rom @07
         go to L03650

L04312:  if s 13 = 1
           then go to L04501
         jsb S04173
         1 -> s 11
         go to L04114

L04317:  a + 1 -> a[x]
         a + 1 -> a[x]		; key 64 - 3
         a + 1 -> a[x]		; key 63 - 2
         if n/c go to L04017	; key 62 - 1

         if s 13 = 1		; key 61 - /       n!
           then go to L04735
         if s 12 = 0
           then go to L04515
         go to L04110

L04330:  delayed rom @11
         go to L04671

L04332:  jsb S04335
         c -> data
         go to L04306

S04335:  0 -> c[x]
         c - 1 -> c[x]
         shift right c[x]
         shift right c[x]
         binary
S04342:  a + c -> c[x]
         c -> data address
         m2 -> c
         decimal
         return

L04347:  binary
         if s 13 = 1
           then go to L04237
         jsb S04173
         delayed rom @00
         go to L00145

L04355:  0 -> c[w]
         c -> register 0
         c -> register 1
         c -> register 2
         c -> register 3
         c -> register 4
         m2 -> c
         go to L04171

S04365:  if s 0 = 1
           then go to L04370
         c -> stack
L04370:  data -> c
S04371:  a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 2
         c + 1 -> c[x]
         return

         select rom go to L04001

         select rom go to L04002

         go to L04520

         go to L04425

         delayed rom @04
         jsb S02121
         0 -> s 7
         y -> a
         m2 -> c
         if a[s] # 0
           then go to L04440
         go to L04464

L04414:  stack -> a
         delayed rom @01
         jsb S00627
         go to L04476

L04420:  c - 1 -> c[x]
         c - 1 -> c[x]
         y -> a
         jsb S04762
         go to L04476

L04425:  0 -> s 1
         delayed rom @04
         jsb S02322
         go to L04476

L04431:  if c[m] # 0
           then go to L04414
L04433:  p <- 7
L04434:  delayed rom @00
         go to L00340

L04436:  delayed rom @07
         go to L03415

L04440:  a exchange c[m]
         if c[xs] # 0
           then go to L04433
         go to L04447

L04444:  if c[x] = 0
           then go to L04433
         c - 1 -> c[x]
L04447:  shift left a[ms]
         if a[m] # 0
           then go to L04444
         if c[x] # 0
           then go to L04464
         a exchange c[s]
         c -> a[s]
         c + c -> c[s]
         c + c -> c[s]
         a + c -> c[s]
         if c[s] = 0
           then go to L04464
         1 -> s 7
L04464:  y -> a
         0 -> a[s]
         a exchange c[w]
         0 -> s 1
         delayed rom @02
         jsb S01167
         stack -> a
         if s 7 = 0
           then go to L04476
         0 - c - 1 -> c[s]
L04476:  delayed rom @00
         go to L00020

L04500:  a -> rom address

L04501:  delayed rom @02
         jsb S01353
         go to L04476

L04504:  0 -> s 1
         delayed rom @03
         jsb S01416
         go to L04476

L04510:  0 - c - 1 -> c[s]
L04511:  stack -> a
         delayed rom @01
         jsb S00420
         go to L04476

L04515:  stack -> a
         jsb S04762
         go to L04476

L04520:  delayed rom @01
         jsb S00674
         go to L04476

L04523:  0 -> b[w]
         b exchange c[m]
L04525:  y -> a
         a exchange c[w]
         c - 1 -> c[x]
         c - 1 -> c[x]
         delayed rom @01
         jsb S00631
         go to L04476

L04534:  y -> a
         a exchange c[w]
         0 - c - 1 -> c[s]
         delayed rom @01
         jsb S00420
         a exchange c[w]
         go to L04525


; STO ENTER^ self test
         L04543:  binary
         clear regs
         c + 1 -> c[x]
         m2 exchange c
         p <- 12
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
         a - 1 -> a[x]
         if a[w] # 0
           then go to L04642
         0 -> c[w]
         c + 1 -> c[p]
         p <- 0
L04572:  c -> data address
         c -> data
         c + 1 -> c[p]
         if n/c go to L04572
L04576:  c -> data address
         a exchange c[w]
         data -> c
         a exchange c[w]
         a - c -> a[w]
         if a[w] # 0
           then go to L04642
         c + 1 -> c[p]
         if n/c go to L04576
         p <- 12
         c + 1 -> c[p]
         clear data registers
         0 -> s 5
         delayed rom @00
         jsb S00043
         if s 5 = 1
           then go to L04727
         c + 1 -> c[p]
         delayed rom @04
         jsb S02265
         if s 5 = 1
           then go to L04727
         c + 1 -> c[p]
         jsb S04645
         if s 5 = 1
           then go to L04727
         p <- 3
L04631:  load constant 2
         if p # 3
           then go to L04631
         b exchange c[w]
L04635:  load constant 8
         if p # 3
           then go to L04635
         delayed rom @00
         go to L00356

L04642:  p <- 12
         0 -> c[x]
         go to L04727

S04645:  rom checksum

L04646:  y -> a
         a exchange c[w]
         c - 1 -> c[x]
         c - 1 -> c[x]
         0 - c - 1 -> c[s]
         0 -> b[w]
         b exchange c[m]
         a exchange c[w]
         delayed rom @01
         jsb S00716
         if c[m] = 0
           then go to L04433
         m2 -> c
         m1 exchange c
         m1 -> c
         0 -> c[x]
         delayed rom @01
         jsb S00704
         go to L04476

L04671:  c -> a[w]
         register -> c 11
         jsb S04741
         m2 -> c
         jsb S04761
         register -> c 12
         jsb S04743
         y -> a
         register -> c 13
         jsb S04741
         y -> a
         a exchange c[w]
         jsb S04761
         register -> c 14
         jsb S04743
         y -> a
         m2 -> c
         jsb S04762
         register -> c 15
         jsb S04743
         0 -> a[w]
         a + 1 -> a[s]
         shift right a[w]
         register -> c 10
         jsb S04741
         m2 exchange c
         m2 -> c
         if s 8 = 0
           then go to L04170
L04726:  p <- 6
L04727:  m2 exchange c
         go to L04434

L04731:  p <- 3
         go to L04434

L04733:  delayed rom @07
         go to L03425

L04735:  delayed rom @07
         go to L03525

L04737:  delayed rom @06
         go to xft100		; factorial

S04741:  0 -> b[w]
         a exchange b[m]
S04743:  if s 13 = 0
           then go to L04750
         a exchange c[w]
         0 - c - 1 -> c[s]
         a exchange c[w]
L04750:  delayed rom @01
         jsb S00422
         delayed rom @00
         jsb S00311
         if p # 13
           then go to L04757
         1 -> s 8
L04757:  c -> data
         return

S04761:  c -> a[w]
S04762:  delayed rom @01
         go to S00555

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

         .dw @0247			; CRC, half of quad 2 (@04000..@04777)

; 92 ROM disassembly
; Copyright 2022 Eric Smith <spacewar@gmail.com>

; 1818-0345 ROM0      unbanked,  0000- 1777
; 1818-0346 ROM1/RAM  bank 0,   02000-03777, RAM 0x00-0x0f
; 1818-0347 ROM2/RAM  bank 0,   04000-05777, RAM 0x10-0x1f
; 1818-0350 ROM3      unbanked,  6000- 7777
; 1818-0349 ROM5/RAM  bank 1,   12000-13777, RAM 0x20-0x2f
; 1818-0351 ROM6/RAM  bank 1,   14000-15777, RAM 0x30-0x3f

	.arch woodstock

	.bank 0
	.org @0000

         reset twf		; fourteen-digit display (Topcat)

         a + 1 -> a[x]		; two decimal places
         a + 1 -> a[x]
         f exchange a[x]
         0 -> a[x]

L00005:  c -> data address	; clear dsta registers 0x00..0x3f
         clear data registers
         p <- 1
         c + 1 -> c[p]
         c -> data address
         clear data registers
         c + 1 -> c[p]
         c -> data address
         clear data registers
         go to L00235

L00017:  go to L00042

; slide switch handling from the a -> rom address instruction at L00041
; pin 5, KA: 0024 - 365
; pin 6, KB: 0023 - not used
; pin 7, KC: 0022 - MAN
; pin 8, KD: 0021 - NORM
; pin 9, KE: 0020 - switch common, driven by ACT flag out
; note F!, s 5 (ACT 3) is NORM
;      F2, s 3 (ACT 4) is from PICK

				;                     S0 S15 S11 
         1 -> s 0		; at 0020  ALL  360   1   1   1  
         1 -> s 15		; at 0021  NORM 360   0   1   1  
         1 -> s 11		; at 0022  MAN  360   0   0   1  
         go to L00026					         
							         
         1 -> s 0		; at 0024  ALL  365   1   1   0  
         1 -> s 15		; at 0025  NORM 365   0   1   0  
				; at 0026  MAN  365   0   0   0  

L00026:  0 -> c[w]		; address PICK
         c - 1 -> c[w]
         c -> data address
         register -> c 15	; read PICK keycode
         shift right c[x]
         p <- 0
L00034:  if c[p] # 0
           then go to L00272
         a exchange c[x]
         b -> c[w]
         return

L00041:  a -> rom address	; dispatch slide switches, 0020 through 0026

L00042:  jsb S00366
         delayed rom @10
         jsb S04250
         1 -> s 4
         if s 1 = 1
           then go to L00064
         delayed rom @05
         go to L02530

L00052:  jsb S00366
         p <- 2
         load constant 6
         load constant 10
         load constant 14
         1 -> s 4
         if s 1 = 1
           then go to L00101
         delayed rom @05
         go to L02543

L00064:  jsb S00206
         delayed rom @10
         bank toggle

L00067:  jsb S00366
         p <- 2
         load constant 11
         load constant 6
         load constant 14
         1 -> s 4
         if s 1 = 1
           then go to L00114
         delayed rom @05
         go to L02561

L00101:  jsb S00206
         delayed rom @10
         go to L04020

L00104:  m1 -> c
         a exchange b[x]
         go to S00275

S00107:  0 -> s 3
L00110:  pick print home?
         if 0 = s 3
           then go to L00110
         go to L00135

L00114:  jsb S00206
         delayed rom @10
         bank toggle

L00117:  jsb S00366
         1 -> s 4
         p <- 1
         load constant 3
         load constant 8
         if s 1 = 1
           then go to L00137
         delayed rom @05
         go to L02424

S00130:  0 -> s 3
         display off
L00132:  pick print cr?
         if 0 = s 3
           then go to L00132
L00135:  0 -> s 3
         return

L00137:  jsb S00206
         delayed rom @12
         bank toggle

S00142:  p <- 5
L00143:  0 -> s 3
         pick print home?
         if 0 = s 3
           then go to L00156
         c - 1 -> c[s]
         if n/c go to L00143
         p - 1 -> p
         if p # 0
           then go to L00143
         load constant 15
         pick print 3
L00156:  return

; wait for "keyboard" release
S00157:  0 -> s 0		; disable slide switches
L00160:  0 -> s 15
         if s 15 = 1
           then go to L00160
         p <- 12
         return

L00165:  jsb S00157		; wait for keyboard release
         1 -> s 0		; enable slide switches to ACT key scanner
L00167:  if 0 = s 15		; wait for "keypress"
           then go to L00167
         0 -> s 5
         a exchange c[x]
         b exchange c[w]
         keys -> a		; read status of slide switches as keycodes
	 			;   a[1] = column
				;   a[0] = row (unused in -92)
         0 -> a[xs]		; set digit 2 to 1, to ignore row and limit
         a + 1 -> a[xs]		;   range of a[2:1] to @20..26

         0 -> s 10		; copy s5 to s10
         if 0 = s 5
           then go to L00203
         1 -> s 10
L00203:  jsb S00157		; wait for keyboard release
         0 -> s 11
         go to L00041

S00206:  delayed rom @03
         go to L01725

L00210:  m2 -> c
         if s 15 = 1
           then go to L01353
         go to S00275

L00214:  go to L00067

L00215:  go to L00052

L00216:  go to L00117

L00217:  jsb S00366
         p <- 1
         load constant 3
         load constant 4
         1 -> s 4
         if s 1 = 1
           then go to L00230
         delayed rom @05
         go to L02437

L00230:  jsb S00206
         delayed rom @12
         go to L05031

L00233:  delayed rom @06
         go to L03026

L00235:  c + 1 -> c[p]		; continue clearing data registers
         c -> data address
         clear data registers

         c - 1 -> c[p]		; init reg 0x27 to 01000000000002
         p <- 13
         load constant 1
         shift right c[w]
         c -> register 7

L00245:  0 -> c[w]
         0 -> s 0
L00247:  1 -> s 8
         0 -> s 1
         0 -> s 2
L00252:  delayed rom @05
         jsb S02407
         m2 exchange c
         m2 -> c
         delayed rom @04
         jsb S02137
         if s 0 = 1
           then go to L00467
         0 -> s 4
         0 -> s 6
         1 -> s 7
         0 -> s 12
         0 -> s 13
L00267:  jsb S00275
         delayed rom @01
         go to L00400

L00272:  c - 1 -> c[p]
         c + 1 -> c[xs]
         if n/c go to L00034
S00275:  b -> c[w]
         0 -> c[x]
         jsb S00157
         if c[p] # 0
           then go to L00304
         c + 1 -> c[xs]
         c + 1 -> c[xs]
L00304:  p <- 0
L00305:  p - 1 -> p
         c - 1 -> c[s]
         if n/c go to L00305
         0 -> c[ms]
         load constant 3
         b exchange c[w]
L00313:  jsb S00130
         display toggle
         hi i'm woodstock
         binary
L00317:  pick key?
         if s 3 = 1
           then go to L01337
         0 -> s 5
         if s 5 = 1
           then go to L00317
         display off
         b exchange c[w]
         0 -> c[w]
         c - 1 -> c[w]
         p <- 11
         0 -> c[wp]
L00333:  jsb S00107
         if s 5 = 1
           then go to L00210
         pick print 6
         jsb S00130
         go to L00333

S00341:  jsb S00157
S00342:  jsb S00130
         jsb S00107
L00344:  pick print 6
         jsb S00142
         m2 -> c
         decimal
         return

L00351:  jsb S00130
         go to L00344

L00353:  a exchange c[w]
         1 -> s 15
         0 -> s 1
         0 -> s 2
         go to L00313

L00360:  p <- 11
L00361:  load constant 0
         if p # 8
           then go to L00361
         load constant 14
         go to S00342

S00366:  delayed rom @07
         go to L03624

S00370:  p <- 4
         load constant 2
         load constant 5
         load constant 3
         load constant 4
         load constant 14
         return

         nop

L00400:  a -> rom address

         go to L00433

L00402:  go to L00540

         select rom go to L02404

L00404:  go to L00760

         go to L00655

L00406:  go to L00570

L00407:  go to L00657

         go to L00526

L00411:  go to L00442

L00412:  select rom go to L04013

         select rom go to L06414

         select rom go to L06415

         select rom go to L02016

         select rom go to L00017

L00417:  0 -> s 13
         go to L00422

L00421:  1 -> s 13
L00422:  1 -> s 12
         p <- 5
         0 -> c[p]
         b exchange c[p]
         0 -> s 1
         0 -> s 2
L00430:  a exchange b[x]
         delayed rom @00
         go to L00267

L00433:  jsb S00762
         p <- 1
         load constant 1
         load constant 1
         jsb S00620
         delayed rom @12
         go to L05314

L00442:  a exchange c[w]
         stack -> a
         a exchange c[w]
         m2 exchange c
         c -> stack
         jsb S00762
         p <- 4
         load constant 2
         load constant 0
         load constant 6
         load constant 5
         load constant 12
         go to L00667

S00457:  load constant 1
S00460:  p <- 4
         load constant 2
         load constant 9
         load constant 6
         load constant 8
         load constant 12
         return

L00467:  delayed rom @07
         go to L03663

S00471:  if s 0 = 1
           then go to L00475
         decimal
         return

L00475:  delayed rom @10
         jsb S04337
         display off
         go to S00617

         go to L00623

L00502:  go to L00542

         select rom go to L02504

         select rom go to L02505

         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         p <- 5
         if 0 = s 12
           then go to L00523
         delayed rom @13
         go to L05520

L00523:  p <- 0
L00524:  delayed rom @06
         go to L03117

L00526:  p <- 5
         if 0 = s 12
           then go to L00524
         if c[p] # 0
           then go to L00524
         load constant 2
         b exchange c[w]
         go to L00430

L00536:  delayed rom @06
         go to L03353

L00540:  delayed rom @04
         go to L02071

L00542:  delayed rom @04
         go to L02065

L00544:  if 0 = s 7
           then go to L00566
         jsb S00762
         p <- 4
         load constant 2
         load constant 4
         load constant 14
         load constant 6
         load constant 12
         m1 exchange c
         if c[m] = 0
           then go to L00564
         decimal
         0 - c - 1 -> c[s]
         m2 exchange c
         binary
L00564:  jsb S00621
         go to L00641

L00566:  p <- 12
         go to L00524

L00570:  jsb S00762
         p <- 2
         load constant 9
         load constant 8
         load constant 9
         m2 exchange c
         down rotate
         down rotate
         go to L00665

         go to L00604

         go to L00604

         go to L00604

L00604:  select rom go to L03605

L00605:  go to L00764

L00606:  go to L00544

L00607:  go to L00536

L00610:  go to L00643

L00611:  go to L00417

L00612:  go to L00421

         select rom go to L00214

         select rom go to L00215

         select rom go to L00216

         select rom go to L00217

S00617:  a exchange b[x]
S00620:  m1 exchange c
S00621:  delayed rom @07
         go to L03562

L00623:  jsb S00762
         p <- 2
         load constant 2
         load constant 0
         load constant 4
         jsb S00620
         c + 1 -> c[x]
         c + 1 -> c[x]
         c -> a[w]
         delayed rom @13
         jsb S05671
         register -> c 1
         delayed rom @07
         jsb S03466
L00641:  delayed rom @03
         go to L01531

L00643:  if s 12 = 1
           then go to L01072
L00645:  jsb S00762
         p <- 2
         load constant 1
         load constant 2
         load constant 15
L00652:  jsb S00620
         delayed rom @12
         go to L05032

L00655:  delayed rom @07
         go to L03657

L00657:  jsb S00762
         p <- 2
         load constant 9
         load constant 8
         load constant 5
         m2 exchange c
L00665:  down rotate
         m2 exchange c
L00667:  jsb S00620
L00670:  delayed rom @03
         go to L01532

L00672:  register -> c 9
         jsb S00754
         if s 10 = 1
           then go to L01443
         p <- 0
         load constant 12
         jsb S00471
         register -> c 12
         jsb S00754
         jsb S00460
         jsb S00471
         register -> c 13
         jsb S00754
         p <- 4
         load constant 2
         load constant 6
         load constant 10
         load constant 6
         delayed rom @04
         go to L02164

L00716:  register -> c 12
         c -> a[w]
         register -> c 14
         delayed rom @07
         jsb S03653
         c -> register 14
         register -> c 9
         c -> a[w]
         register -> c 6
         delayed rom @07
         jsb S03543
         if c[s] = 0
           then go to L00735
         delayed rom @05
         go to L02706

L00735:  register -> c 14
         jsb S00754
         if s 10 = 1
           then go to L01616
         jsb S00457
         jsb S00617
         if s 8 = 1
           then go to L00746
         c -> stack
L00746:  register -> c 14
         c -> stack
         register -> c 13
         delayed rom @15
         jsb S06542
         go to L00670

S00754:  delayed rom @04
         go to S02137

L00756:  delayed rom @15
         go to L06704

L00760:  delayed rom @06
         go to L03165

S00762:  delayed rom @07
         go to S03622

L00764:  jsb S00762
         p <- 0
         load constant 8
         jsb S00620
         c - 1 -> c[x]
         c - 1 -> c[x]
         y -> a
         delayed rom @07
         jsb S03422
         go to L00641

         nop
         nop

         go to L01305

         select rom go to L00402

         select rom go to L07003

         go to L01034

         select rom go to L04005

         go to L01176

         select rom go to L05407

         go to L01315

         select rom go to L05411

         select rom go to L00412

         select rom go to L06413

         go to L01070

         go to L01147

         go to L01367

L01016:  p <- 13
         delayed rom @06
         go to L03117

L01021:  a + 1 -> a[p]
         delayed rom @01
         go to L00523

S01024:  delayed rom @07
         go to L03624

L01026:  delayed rom @16
         go to L07017

L01030:  delayed rom @16
         go to L07032

L01032:  select rom go to L05433

L01033:  select rom go to L05434

L01034:  0 -> c[w]
         m2 exchange c
         jsb S01153
         0 -> s 9
         p <- 11
         0 -> c[wp]
         p <- 7
         load constant 2
         load constant 4
         load constant 3
         load constant 10
         load constant 8
         load constant 3
         load constant 6
         load constant 6
         if 0 = s 15
           then go to L01057
         delayed rom @00
         jsb S00342
L01057:  m2 -> c
         c -> stack
         c -> stack
         c -> stack
         delayed rom @00
         go to L00005

S01065:  m1 exchange c
S01066:  delayed rom @07
         go to L03562

L01070:  delayed rom @15
         go to L06453

L01072:  p <- 5
         if c[p] # 0
           then go to L00645
         load constant 1
         delayed rom @07
         go to L03414

         go to L01253

         select rom go to L00502

         go to L01026

         go to L01030

         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         if n/c go to L01021
         jsb S01153
         load constant 10
         load constant 5
         load constant 4
         load constant 11
         load constant 14
         load constant 9
         jsb S01065
         delayed rom @17
         go to L07506

L01127:  jsb S01153
         load constant 3
         load constant 10
         load constant 12
         load constant 5
         load constant 2
         m1 exchange c
         jsb S01066
         if s 8 = 1
           then go to L01142
         c -> stack
L01142:  0 -> c[w]
         c -> data address
         register -> c 15
         delayed rom @03
         go to L01532

L01147:  delayed rom @03
         go to L01540

S01151:  delayed rom @13
         go to S05655

S01153:  delayed rom @07
         go to S03622

L01155:  jsb S01153
         p <- 1
         load constant 4
         load constant 8
         jsb S01065
         y -> a
         a exchange c[w]
         delayed rom @07
         jsb S03543
         c + 1 -> c[x]
         c + 1 -> c[x]
         y -> a
         a exchange c[w]
         delayed rom @07
         jsb S03466
         delayed rom @03
         go to L01531

L01176:  delayed rom @13
         go to L05740

         select rom go to L02601

         select rom go to L03202

         select rom go to L03203

         select rom go to L02604

         go to L01155

         go to L01016

         go to L01127

         go to L01327

         go to L01032

         go to L01033

         go to L01273

         go to L01262

         go to L01231

         jsb S01024
         jsb S01355
         load constant 14
         if s 13 = 1
           then go to L01417
         jsb S01065
         jsb S01151
         jsb S01371
         delayed rom @07
         jsb S03422
         delayed rom @05
         go to L02442

L01231:  jsb S01024
         jsb S01355
         load constant 10
         if s 13 = 1
           then go to L01426
         jsb S01065
         jsb S01371
         delayed rom @07
         jsb S03466
         m2 exchange c
         jsb S01151
         delayed rom @05
         go to L02427

L01246:  jsb S01066
         0 -> s 0
         0 -> s 9
         delayed rom @00
         go to L00247

L01253:  jsb S01153
         p <- 1
         load constant 2
         load constant 1
         jsb S01065
         delayed rom @12
         go to L05073

L01262:  jsb S01153
         p <- 3
         load constant 12
         load constant 6
         load constant 10
         load constant 14
         jsb S01065
         delayed rom @11
         go to L04464

L01273:  jsb S01153
         p <- 4
         load constant 3
         load constant 13
         load constant 9
         load constant 10
         load constant 6
         jsb S01065
         delayed rom @11
         go to L04542

L01305:  jsb S01153
         p <- 2
         load constant 3
         load constant 10
         load constant 6
         jsb S01065
         delayed rom @12
         go to L05325

L01315:  jsb S01153
         load constant 10
         load constant 4
         load constant 13
         load constant 7
         load constant 2
         load constant 12
         jsb S01065
         delayed rom @17
         go to L07523

L01327:  jsb S01153
         p <- 2
         load constant 1
         load constant 3
         load constant 3
         1 -> s 4
         delayed rom @01
         go to L00652

L01337:  display off
         if 0 = s 15
           then go to L00165
         a exchange c[x]
L01343:  0 -> c[w]		; address the PICK (0xff)
         binary
         c - 1 -> c[w]
         c -> data address
         register -> c 15	; get PICK key code
         0 -> c[w]
         c -> data address
         register -> c 14

L01353:  delayed rom @03
         go to L01527

S01355:  p <- 3
         load constant 7
         load constant 2
         load constant 15
         1 -> s 4
         return

L01363:  0 -> s 13
         jsb S01151
         delayed rom @16
         go to L07271

L01367:  delayed rom @04
         go to L02151

S01371:  c -> a[w]
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 2
         c + 1 -> c[x]
         return

         go to L01707

         select rom go to L00402

         go to L01763

         select rom go to L00404

         select rom go to L02005

         select rom go to L00406

         select rom go to L00407

         go to L01664

         select rom go to L00411

         select rom go to L00412

         go to L01721

         go to L01723

         go to L01646

         delayed rom @04
         go to L02030

L01417:  jsb S01574
         register -> c 3
         delayed rom @02
         jsb S01371
         delayed rom @07
         jsb S03466
         go to L01434

L01426:  jsb S01574
         register -> c 1
         delayed rom @02
         jsb S01371
         delayed rom @07
         jsb S03422
L01434:  jsb S01667
         delayed rom @05
         go to L02413

S01437:  delayed rom @16
         go to S07067

S01441:  delayed rom @04
         go to S02137

L01443:  p <- 1
         load constant 1
         load constant 10
         jsb S01765
         register -> c 11
         jsb S01441
         delayed rom @10
         jsb S04266
         jsb S01765
         register -> c 12
         jsb S01441
         delayed rom @10
         jsb S04256
         jsb S01765
         register -> c 13
         jsb S01441
         delayed rom @00
         jsb S00370
         jsb S01765
         register -> c 8
         c -> a[w]
         register -> c 11
         delayed rom @07
         jsb S03653
         c -> register 8
         delayed rom @04
         go to L02167

         nop
         nop

         go to L01565

         select rom  go to L00502

         go to L01761

         go to L01563

         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
         a + 1 -> a[p]
L01515:  f exchange a[x]
         a exchange b[x]
         jsb S01576
         if 0 = s 15
           then go to L01526
         if 0 = s 9
           then go to L01526
         delayed rom @07
         jsb S03676
L01526:  m1 -> c
L01527:  jsb S01556
         go to L01535

L01531:  jsb S01767
L01532:  0 -> s 1
         0 -> s 2
L01534:  0 -> s 8
L01535:  0 -> s 9
         delayed rom @00
         go to L00252

L01540:  jsb S01554
         jsb S01675
         if s 13 = 1
           then go to L01656
         jsb S01673
         jsb S01437
         c -> register 5
L01547:  delayed rom @15
         jsb S06523
         0 -> s 8
L01552:  0 -> s 0
         go to L01535

S01554:  delayed rom @07
         go to L03624

S01556:  select rom go to S00157

L01557:  jsb S01574
         jsb S01670
         register -> c 6
         go to L01661

L01563:  delayed rom @16
         go to L07004

L01565:  jsb S01576
         p <- 1
         load constant 2
         load constant 12
         jsb S01673
         delayed rom @12
         go to L05256

S01574:  delayed rom @15
         go to S06546

S01576:  delayed rom @07
         go to S03622

         select rom go to L03601

         select rom go to L03602

         select rom go to L03603

         select rom go to L03604

         select rom go to L00605

         select rom go to L00606

         select rom go to L00607

         select rom go to L00610

         select rom go to L00611

         select rom go to L00612

         select rom go to L02613

         select rom go to L02614

         select rom go to L02615

         select rom go to L02616

L01616:  load constant 1
         delayed rom @10
         jsb S04256
         jsb S01667
         register -> c 14
         c -> stack
         register -> c 8
         m2 exchange c
         jsb S01672
         register -> c 8
         jsb S01441
         delayed rom @10
         jsb S04265
         jsb S01672
         c -> stack
         register -> c 13
         delayed rom @15
         jsb S06523
         go to L01532

L01641:  0 -> s 8
L01642:  jsb S01556
L01643:  0 -> s 1
         0 -> s 2
         go to L01535

L01646:  jsb S01554
         jsb S01702
         if s 13 = 1
           then go to L01557
         jsb S01673
         jsb S01437
         c -> register 6
         go to L01547

L01656:  jsb S01574
         jsb S01670
         register -> c 5
L01661:  delayed rom @15
         jsb S06523
         go to L01534

L01664:  load constant 10
         a exchange c[x]
         go to L01515

S01667:  m2 exchange c
S01670:  delayed rom @13
         go to S05655

S01672:  a exchange b[x]
S01673:  delayed rom @07
         go to S03563

S01675:  p <- 2
         load constant 6
         load constant 8
         load constant 7
         return

S01702:  p <- 2
         load constant 6
         load constant 8
         load constant 11
         return

L01707:  jsb S01576
         p <- 1
         load constant 2
         load constant 6
         jsb S01673
         delayed rom @12
         go to L05233

L01716:  jsb S01767
         1 -> s 8
         go to L01643

L01721:  delayed rom @15
         go to L06514

L01723:  delayed rom @15
         go to L06477

L01725:  if 0 = s 10
           then go to L01751
         p <- 13
         load constant 14
         load constant 5
         load constant 10
         load constant 3
         load constant 5
         load constant 15
         load constant 4
         load constant 12
L01740:  0 -> s 1
L01741:  0 -> s 2
         0 -> s 12
         0 -> s 13
         0 -> s 9
         if 0 = s 15
           then go to L01774
         delayed rom @00
         go to S00342

L01751:  p <- 11
         load constant 14
         load constant 14
         load constant 8
         load constant 3
         load constant 2
         load constant 9
         go to L01740

L01761:  delayed rom @16
         go to L07041

L01763:  delayed rom @16
         go to L07052

S01765:  delayed rom @01
         go to S00471

S01767:  m1 exchange c
         0 -> c[w]
         c -> data address
         register -> c 14
         c -> register 15
L01774:  m1 -> c
         return

         nop
         nop

L02000:  load constant 15
L02001:  delayed rom @07
         jsb S03476
         delayed rom @03
         go to L01552

L02005:  jsb S02140
         jsb S02056
         delayed rom @17
         jsb S07562
         if a[w] # 0
           then go to L03026
         register -> c 15
         p <- 5
         go to L02310

L02016:  jsb S02140
         p <- 5
         load constant 3
         load constant 5
         load constant 6
         load constant 9
         load constant 9
         load constant 4
         delayed rom @05
         go to L02572

L02030:  jsb S02140
         p <- 5
         load constant 9
         load constant 8
         load constant 12
         load constant 10
         load constant 4
         jsb S02056
         jsb S02063
         go to L02162

L02042:  register -> c 3
         c -> a[w]
         register -> c 9
         jsb S02142
         register -> c 8
         jsb S02123
         register -> c 10
         jsb S02257
         delayed rom @05
         go to L02720

S02054:  delayed rom @00
         go to L00104

S02056:  delayed rom @07
         go to S03563

         nop

L02061:  delayed rom @10
         jsb S04337
S02063:  1 -> s 14
         bank toggle

L02065:  jsb S02054
         jsb S02365
         delayed rom @02
         a -> rom address

L02071:  jsb S02054
         jsb S02365
         delayed rom @03
         a -> rom address

L02075:  data -> c
         c -> register 15
         0 -> s 1
         0 -> s 2
         0 -> s 10
         0 -> s 11
         1 -> s 9
         register -> c 6
         c -> a[w]
         register -> c 5
         jsb S02142
         if c[s] # 0
           then go to L03026
         jsb S02305
         jsb S02301
         jsb S02303
         jsb S02301
         return

S02117:  0 -> a[w]
         a + 1 -> a[s]
         shift right a[w]
         return

S02123:  delayed rom @07
         go to S03466

S02125:  p <- 5
S02126:  load constant 4
         load constant 0
         load constant 15
         load constant 6
         if 0 = s 11
           then go to L02777
         load constant 12
         load constant 3
         return

S02137:  bank toggle

S02140:  delayed rom @07
         go to S03622

S02142:  select rom go to S03543

S02143:  p <- 13
         load constant 12
         load constant 0
         jsb S02126
         delayed rom @03
         go to L01741

L02151:  jsb S02140
         p <- 5
         load constant 1
         load constant 13
         load constant 5
         load constant 8
         jsb S02056
         jsb S02117
         jsb S02123
L02162:  delayed rom @03
         go to L01531

L02164:  load constant 14
         delayed rom @01
         jsb S00471
L02167:  if 0 = s 0
           then go to L02175
         delayed rom @07
         jsb S03643
         delayed rom @06
         jsb S03076
L02175:  delayed rom @01
         go to L00716

L02177:  shift left a[w]
         a - 1 -> a[s]
         a - 1 -> a[s]
         if n/c go to L02211
         load constant 0
         load constant 1
         load constant 6
         load constant 0
         load constant 12
         go to L02336

L02211:  a - 1 -> a[s]
         if n/c go to L02221
         load constant 5
         load constant 2
         load constant 10
         load constant 10
         load constant 2
         go to L02336

L02221:  a - 1 -> a[s]
         if n/c go to L02232
         load constant 0
         load constant 3
         load constant 6
         load constant 10
         load constant 2
         load constant 9
         go to L02337

L02232:  a - 1 -> a[s]
         if n/c go to L02261
         load constant 5
         load constant 3
         load constant 9
         load constant 10
         load constant 10
         load constant 6
         go to L02337

S02243:  0 -> c[w]
         p <- 12
         if 0 = s 10
           then go to L02255
         load constant 3
         load constant 6
         if s 11 = 1
           then go to L02254
         load constant 5
L02254:  p <- 0
L02255:  load constant 2
         return

S02257:  delayed rom @07
         go to S03422

L02261:  a - 1 -> a[s]
         if n/c go to L02272
         load constant 0
         load constant 2
         load constant 13
         load constant 9
         load constant 11
         load constant 13
         go to L02337

L02272:  load constant 0
         load constant 2
         load constant 12
         load constant 3
         load constant 5
         load constant 4
         go to L02337

S02301:  delayed rom @16
         go to L07073

S02303:  register -> c 5
         go to S02306

S02305:  register -> c 6
S02306:  1 -> s 7
         bank toggle

L02310:  load constant 1
         a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 7
         jsb S02123
         jsb S02306
         0 -> c[w]
         p <- 12
         load constant 7
         jsb S02257
         jsb S02140
         p <- 8
         if a[xs] # 0
           then go to L02331
         if a[m] # 0
           then go to L02177
L02331:  load constant 0
         load constant 2
         load constant 12
         load constant 10
         load constant 8
L02336:  load constant 12
L02337:  delayed rom @00
         jsb S00342
         delayed rom @14
         jsb S06226
         a exchange c[w]
         shift left a[w]
         a exchange c[w]
         p <- 11
         shift right c[wp]
         load constant 12
         p <- 8
         shift right c[wp]
         load constant 12
         p <- 3
         load constant 14
         load constant 14
         load constant 14
         load constant 14
         p <- 13
         if c[p] # 0
           then go to L02001
         go to L02000

S02365:  p <- 1
         a - 1 -> a[p]
         a - 1 -> a[p]
         if a[p] # 0
           then go to L02374
         0 -> s 12
         0 -> s 13
L02374:  a + 1 -> a[p]
         p <- 0
         return

         nop

L02400:  bank toggle

         nop
         nop
         nop

L02404:  jsb S02621
         load constant 11
         go to L02463

S02407:  bank toggle

L02410:  jsb S02416
         jsb S02576
         data -> c
L02413:  jsb S02520
         delayed rom @03
         go to L01534

S02416:  delayed rom @15
         go to S06546

         nop

S02421:  select rom go to S03422

L02422:  delayed rom @01
         go to L00672

L02424:  if s 13 = 1
           then go to L02431
         jsb S02474
L02427:  c -> register 1
         go to L02443

L02431:  jsb S02416
         jsb S02576
         register -> c 1
         go to L02413

S02435:  delayed rom @04
         go to L02075

L02437:  if s 13 = 1
           then go to L02751
         jsb S02474
L02442:  c -> register 3
L02443:  jsb S02520
L02444:  0 -> s 8
         delayed rom @03
         go to L01552

         nop
         nop
         nop
         nop
         nop
         nop
         nop

L02456:  load constant 8
         load constant 12
         jsb S02474
         0 -> s 9
L02462:  bank toggle

L02463:  load constant 0
         load constant 3
         load constant 7
         load constant 2
         load constant 9
         jsb S02474
         jsb S02435
         1 -> s 1
         go to L02641

S02474:  delayed rom @07
         go to S03563

L02476:  jsb S02416
         jsb S02576
         register -> c 2
         go to L02413

S02502:  delayed rom @12
         go to S05002

L02504:  go to L02632

L02505:  jsb S02621
         p <- 2
         load constant 10
         load constant 6
         load constant 5
         jsb S02474
         jsb S02435
         1 -> s 2
         go to L02641

S02516:  delayed rom @07
         go to S03466

S02520:  1 -> s 1
         0 -> s 2
         delayed rom @15
         go to S06523

L02524:  a exchange c[w]
         1 -> s 6
         1 -> s 9
         go to L02462

L02530:  if s 13 = 1
           then go to L02566
         jsb S02474
         c -> register 4
         go to L02443

         nop
         nop
         nop
         nop
         nop

S02542:  select rom go to S03543

L02543:  if s 13 = 1
           then go to L02476
         jsb S02474
         c -> register 2
         go to L02443

L02550:  0 -> s 13
         delayed rom @00
         go to L00067

L02553:  0 -> s 13
         delayed rom @00
         go to L00052

L02556:  0 -> s 13
         delayed rom @00
         go to L00117

L02561:  if s 13 = 1
           then go to L02410
         jsb S02474
         c -> register 0
         go to L02443

L02566:  jsb S02416
         jsb S02576
         register -> c 4
         go to L02413

L02572:  jsb S02474
         jsb S02435
         1 -> s 10
         go to L02641

S02576:  delayed rom @13
         go to L05654

         nop

L02601:  jsb S02621
         load constant 3
         go to L02456

L02604:  jsb S02621
         load constant 7
         load constant 1
         load constant 2
         jsb S02474
         y -> a
         go to L02524

L02613:  go to L02550

L02614:  go to L02553

L02615:  go to L02556

L02616:  0 -> s 13
         delayed rom @00
         go to L00217

S02621:  select rom go to S03622

         nop

         select rom go to L03624

S02624:  delayed rom @07
         go to S03653

S02626:  0 -> c[s]
S02627:  jsb S02407
S02630:  delayed rom @04
         go to L02061

L02632:  jsb S02621
         p <- 2
         load constant 11
         load constant 0
         load constant 14
         jsb S02474
         jsb S02435
L02641:  0 -> c[w]
         c -> register 9
         c -> register 14
         if s 10 = 1
           then go to L02755
         register -> c 2
         c -> a[w]
         register -> c 15
         jsb S02542
         c -> register 10
         jsb S02627
         c -> register 13
         register -> c 2
         jsb S02627
         c -> register 11
         register -> c 3
         if c[w] = 0
           then go to L03026
         delayed rom @04
         jsb S02306
         b exchange c[w]
         c -> stack
         b exchange c[w]
         jsb S02624
         y -> a
         jsb S02624
         stack -> a
         c -> stack
         jsb S02502
         jsb S02624
         stack -> a
         jsb S02421
         jsb S02502
         c + 1 -> c[p]
         jsb S02516
         jsb S02407
         c -> register 8
L02706:  if s 1 = 1
           then go to L02042
         if s 2 = 1
           then go to L03763
         if s 10 = 1
           then go to L02761
         register -> c 10
         c -> a[w]
         register -> c 3
         jsb S02516
L02720:  jsb S02627
         c -> register 12
         display toggle
         register -> c 13
         c -> a[w]
         register -> c 12
         jsb S02542
         c -> register 13
         if 0 = s 2
           then go to L02737
         register -> c 11
         c -> a[w]
         register -> c 12
         jsb S02542
         c -> register 11
L02737:  register -> c 9
         c -> a[w]
         jsb S02502
         jsb S02624
         c -> register 9
         register -> c 5
         jsb S02542
         if c[s] = 0
           then go to L02422
         go to L02706

L02751:  jsb S02416
         jsb S02576
         register -> c 3
         go to L02413

L02755:  c -> register 8
         register -> c 2
         jsb S02626
         c -> register 13
L02761:  register -> c 1
         c - 1 -> c[x]
         c - 1 -> c[x]
         c -> a[w]
         register -> c 13
         jsb S02421
         jsb S02630
         c -> register 11
         register -> c 4
         0 -> c[s]
         c -> a[w]
         register -> c 11
         jsb S02542
         go to L02720

L02777:  load constant 13
         load constant 7
         return

L03002:  if s 6 = 1
           then go to L03274
         1 -> s 6
         0 -> a[x]
         go to L03275

L03007:  load constant 12	; o   - tail end of display error
         load constant 10	; r
         0 -> b[w]
         delayed rom @00
         go to L00353

         nop
         nop
         nop
         nop
         nop
         nop

S03022:  bank toggle

         nop

S03024:  1 -> s 7
S03025:  bank toggle

L03026:  binary
         0 -> c[w]
         c -> data address
         register -> c 14
         m2 exchange c
         0 -> c[w]
         c - 1 -> c[w]
         c -> data address
         c -> a[w]
         if 0 = s 15
           then go to L03057
         p <- 11
         0 -> c[wp]
         p <- 7
         load constant 2
         load constant 8
         load constant 9
         load constant 10
         load constant 6
         load constant 0
         load constant 14
         load constant 6
         delayed rom @00
         jsb S00341
         decimal
L03057:  p <- 11
L03060:  p - 1 -> p
         register -> c 15
         if p # 12
           then go to L03060
         a exchange c[w]
         load constant 14	; E
         load constant 10	; r
         load constant 10	; r
         go to L03007

L03071:  1 -> s 4
         go to L03274

S03073:  1 -> s 7
S03074:  1 -> s 14
         bank toggle

S03076:  delayed rom @00
         go to L00360

L03100:  delayed rom @00
         go to L00245

S03102:  delayed rom @07
         go to S03563

         nop
         nop
         nop

L03107:  jsb S03341
         load constant 15
         load constant 1
         load constant 2
         jsb S03102
         bank toggle

         delayed rom @00
         go to L00252

L03117:  0 -> s 12
         0 -> s 1
         0 -> s 2
         0 -> s 13
         m2 -> c
         if 0 = s 7
           then go to L03142
         0 -> c[w]
         m2 exchange c
         if s 8 = 1
           then go to L03133
         c -> stack
L03133:  a exchange b[x]
         0 -> a[w]
         a - 1 -> a[w]
         a exchange b[x]
         0 -> b[ms]
         0 -> c[w]
         0 -> s 8
L03142:  if p = 12
           then go to L03277
         1 -> s 9
         0 -> s 7
         if p = 13
           then go to L03343
         if p = 5
           then go to L03071
         jsb S03370
         if s 6 = 1
           then go to L03324
         shift left a[x]
         shift left a[x]
         p <- 3
L03160:  a + 1 -> a[p]
         if n/c go to L03212
         shift left a[wp]
         p + 1 -> p
         go to L03160

L03165:  if s 9 = 1
           then go to L03100
         jsb S03341
         delayed rom @13
         jsb S05677
         m1 exchange c
         0 -> c[w]
         m2 exchange c
L03175:  delayed rom @02
         go to L01246

         nop
         nop
         nop

L03202:  go to L03107

L03203:  jsb S03341
         load constant 8
         load constant 10
         jsb S03102
         jsb S03022
L03210:  delayed rom @03
         go to L01531

L03212:  a - 1 -> a[p]
         p - 1 -> p
         0 -> c[wp]
         if p = 2
           then go to L03227
         if s 4 = 1
           then go to L03224
L03221:  b exchange c[s]
         c + 1 -> c[s]
         b exchange c[s]
L03224:  a exchange c[p]
         c -> a[p]
         p - 1 -> p
L03227:  0 -> a[wp]
         a - 1 -> a[wp]
         shift right a[x]
         if 0 = s 6
           then go to L03235
         0 -> a[x]
L03235:  a exchange b[x]
L03236:  decimal
         if b[xs] = 0
           then go to L03242
         0 - c -> c[x]
L03242:  p <- 12
         b -> c[s]
         c - 1 -> c[x]
L03245:  if c[s] = 0
           then go to L03253
         c + 1 -> c[x]
         c - 1 -> c[s]
         p - 1 -> p
         go to L03245

L03253:  shift right a[wp]
         shift left a[w]
         a exchange c[ms]
         0 -> a[x]
         jsb S03074
         a exchange c[ms]
L03261:  0 -> c[s]
         decimal
         if b[p] = 0
           then go to L03266
         0 - c - 1 -> c[s]
L03266:  delayed rom @05
         jsb S02407
         m2 exchange c
         m2 -> c
         if p = 13
           then go to L03655
L03274:  a exchange b[x]
L03275:  delayed rom @00
         go to L00267

L03277:  if 0 = s 6
           then go to L03312
         jsb S03370
         a exchange b[x]
         if a[xs] # 0
           then go to L03310
         a + 1 -> a[xs]
         a + 1 -> a[xs]
         if n/c go to L03332
L03310:  0 -> a[xs]
         go to L03332

L03312:  if c[m] = 0
           then go to L03274
         b exchange c[w]
         if c[p] = 0
           then go to L03322
         0 -> c[p]
L03320:  b exchange c[w]
         go to L03261

L03322:  c + 1 -> c[p]
         if n/c go to L03320
L03324:  b -> c[x]
         a exchange b[x]
         shift left a[x]
         a exchange c[xs]
         p <- 0
         a exchange b[p]
L03332:  p <- 2
         a exchange b[x]
         b -> c[x]
L03335:  p + 1 -> p
         c + 1 -> c[p]
         if n/c go to L03365
         go to L03335

S03341:  delayed rom @07
         go to S03622

L03343:  if c[m] # 0
           then go to L03002
         0 -> a[w]
         0 -> b[w]
         p <- 12
         a + 1 -> a[p]
         1 -> s 6
         go to L03221

L03353:  jsb S03341
         load constant 10
         load constant 0
         load constant 12
         load constant 5
         load constant 0
         load constant 9
         m1 exchange c
         c -> stack
         go to L03175

L03365:  c - 1 -> c[p]
         0 -> c[xs]
         go to L03236

S03370:  b -> c[w]
         p <- 0
L03372:  p - 1 -> p
         c - 1 -> c[s]
         if n/c go to L03372
         shift left a[wp]
         shift right a[w]
         a exchange c[w]
         c -> a[w]
         return

L03402:  if s 13 = 1
           then go to L03607
         p <- 5
         if c[p] # 0
           then go to L03607
         shift left a[x]
         c + 1 -> c[p]
L03411:  c + 1 -> c[p]
         a - 1 -> a[xs]
         if n/c go to L03411
L03414:  b exchange c[w]
         a exchange b[x]
         delayed rom @00
         go to L00267

S03420:  1 -> s 14
         bank toggle

S03422:  1 -> s 7
         bank toggle

         nop
         nop
         nop
         nop
         nop
         nop

         1 -> s 7
S03433:  bank toggle

L03434:  jsb S03622
         p <- 1
         load constant 3
         load constant 14
         jsb S03563
         stack -> a
         jsb S03422
L03443:  delayed rom @03
         go to L01531

L03445:  pick print cr?
         if 0 = s 3
           then go to L03445
         pick print 3
         go to L03525

L03452:  c - 1 -> c[s]
         c - 1 -> c[s]
L03454:  c - 1 -> c[s]
         p <- 0
         shift right c[w]
         c - 1 -> c[s]
L03460:  shift right c[w]
         c - 1 -> c[s]
         c + 1 -> c[p]
         if n/c go to L03470
         go to L03460

         nop

S03466:  1 -> s 7
         bank toggle

L03470:  c - 1 -> c[p]
         p <- 2
         c + 1 -> c[p]
         c - 1 -> c[p]
         if n/c go to S03476
         load constant 14
S03476:  0 -> s 3
L03477:  pick print cr?
         if 0 = s 3
           then go to L03477
         pick print 3
         go to L03556

         1 -> s 7
L03505:  bank toggle

L03506:  p - 1 -> p
         a + 1 -> a[p]
         if n/c go to L03513
         if 0 = s 3
           then go to L03514
L03513:  a - 1 -> a[p]
L03514:  if p = 2
           then go to L03520
         a - 1 -> a[x]
         if n/c go to L03506
L03520:  c -> a[x]
         p <- 0
         c + 1 -> c[p]
         c - 1 -> c[p]
         if n/c go to L03667
L03525:  shift right a[w]
         p <- 12
         a exchange c[w]
         c - 1 -> c[s]
         if b[p] = 0
           then go to L03454
         go to L03452

L03534:  load constant 4
         load constant 1
L03536:  1 -> s 15
         1 -> s 9
         jsb S03564
         delayed rom @03
         go to L01552

S03543:  1 -> s 7
         bank toggle

L03545:  load constant 12
L03546:  a exchange c[ms]
         0 -> c[ms]
         c - 1 -> c[ms]
         0 -> s 3
         go to L03445

S03553:  1 -> s 7
L03554:  1 -> s 14
         bank toggle

L03556:  0 -> s 3
         go to L03566

         1 -> s 7
L03561:  bank toggle

L03562:  m1 exchange c
S03563:  a exchange b[x]
S03564:  if s 15 = 1
           then go to L03674
L03566:  m2 -> c
L03567:  decimal
         return

L03571:  jsb S03622
         p <- 1
         load constant 3
         load constant 3
         jsb S03563
         stack -> a
         jsb S03543
         go to L03443

L03601:  go to L03753

L03602:  go to L03571

L03603:  go to L03434

L03604:  go to L03610

L03605:  if s 12 = 1
           then go to L03402
L03607:  a -> rom address

L03610:  jsb S03622
         p <- 1
         load constant 3
         load constant 10
         jsb S03563
         if c[w] = 0
           then go to L03026
         stack -> a
         jsb S03466
         go to L03443

S03622:  0 -> s 12
         0 -> s 13
L03624:  0 -> s 4
         0 -> s 6
         0 -> s 7
         p <- 5
         0 -> b[p]
         m2 -> c
         m1 exchange c
S03633:  0 -> c[w]
         c -> data address
         m2 exchange c
         c -> register 14
         m2 exchange c
L03640:  p <- 1
         load constant 3
         c -> data address
S03643:  0 -> c[w]
         binary
         c - 1 -> c[w]
         p <- 7
         load constant 12
         0 -> c[wp]
         p <- 5
         go to L03567

S03653:  1 -> s 7
         bank toggle

L03655:  if 0 = s 15
           then go to L03210
L03657:  jsb S03622
         a exchange b[x]
         if s 9 = 1
           then go to L03536
L03663:  p <- 4
         load constant 1
         load constant 0
         go to L03534

L03667:  p <- 2
         if c[xs] # 0
           then go to L03545
         load constant 11
         go to L03546

L03674:  if 0 = s 9
           then go to S03076
S03676:  0 -> s 3
L03677:  pick print cr?
         display off
         if 0 = s 3
           then go to L03677
         0 -> s 3
L03704:  pick print home?
         if 0 = s 3
           then go to L03704
         0 -> s 3
         pick print 6
         p <- 5
L03712:  0 -> s 3
         pick print home?
         if 0 = s 3
           then go to L03725
         c - 1 -> c[s]
         if n/c go to L03712
         p - 1 -> p
         if p # 0
           then go to L03712
         load constant 15
         pick print 3
L03725:  if s 3 = 1
           then go to L03566
         p <- 0
         b -> c[w]
         a -> b[w]
         f -> a[x]
         decimal
         a - 1 -> a[p]
         a + 1 -> a[p]
         if n/c go to L03740
         1 -> s 3
L03740:  binary
L03741:  p - 1 -> p
         c - 1 -> c[s]
         if n/c go to L03741
         b exchange c[w]
         load constant 10
         p + 1 -> p
         c -> a[p]
         0 -> a[x]
         f -> a[x]
         go to L03514

L03753:  jsb S03622
         p <- 1
         load constant 2
         load constant 15
         jsb S03563
         stack -> a
         jsb S03653
         go to L03443

L03763:  register -> c 1
         c - 1 -> c[x]
L03765:  c - 1 -> c[x]
         c -> a[w]
         register -> c 3
         jsb S03466
         register -> c 11
         jsb S03422
         delayed rom @05
         go to L02720

         nop
         nop
         nop

         delayed rom @07
         go to S03676

S04002:  m1 exchange c
         register -> c 1
         go to L04176

L04005:  jsb S04016
         c -> data address
         register -> c 13
         go to L04044

L04011:  load constant 0
         go to L04176

L04013:  go to L04021

S04014:  delayed rom @13
         go to S05474

S04016:  delayed rom @07
         go to S03622

L04020:  bank toggle

L04021:  jsb S04016
         delayed rom @13
         jsb S05677
         load constant 13
         delayed rom @07
         jsb S03563
         clear data registers
         0 -> c[w]
         p <- 12
         load constant 1
         c + 1 -> c[x]
         c + 1 -> c[x]
         c -> register 7
         0 -> c[w]
         c -> data address
         c -> register 13
         m2 -> c
         delayed rom @03
         go to L01642

L04044:  if c[xs] # 0
           then go to L04142
         if c[m] # 0
           then go to L04112
         jsb S04016
         jsb S04014
         jsb S04016
         p <- 1
         load constant 3
         load constant 4
         jsb S04215
         p <- 1
         load constant 3
         load constant 8
         jsb S04002
         p <- 2
         load constant 6
         load constant 10
         load constant 14
         jsb S04212
         p <- 2
         load constant 11
         load constant 6
         load constant 14
         jsb S04174
         jsb S04250
         jsb S04220
L04077:  jsb S04207
         0 -> s 9
         0 -> s 14
         1 -> s 15
         delayed rom @07
         jsb S03563
         0 -> c[w]
         c -> data address
         register -> c 14
         delayed rom @03
         go to L01552

L04112:  jsb S04016
         jsb S04014
         jsb S04016
         delayed rom @16
         jsb S07124
         jsb S04215
         delayed rom @16
         jsb S07133
         jsb S04212
         delayed rom @16
         jsb S07367
         jsb S04174
         p <- 2
         load constant 3
         load constant 0
         load constant 7
         jsb S04223
         p <- 2
         load constant 3
         load constant 0
         load constant 11
         jsb S04226
         jsb S04241
         go to L04172

L04142:  jsb S04016
         jsb S04014
         jsb S04016
         if 0 = s 10
           then go to L04152
         delayed rom @15
         jsb S06571
         jsb S04226
L04152:  delayed rom @15
         jsb S06670
         jsb S04220
         delayed rom @15
         jsb S06576
         jsb S04223
         delayed rom @15
         jsb S06773
         jsb S04231
         delayed rom @15
         jsb S06553
         jsb S04174
         delayed rom @15
         jsb S06563
         jsb S04212
         jsb S04273
L04172:  jsb S04002
         go to L04077

S04174:  m1 exchange c
         data -> c
L04176:  delayed rom @04
         jsb S02137
         m1 exchange c
         1 -> s 15
         1 -> s 9
         a exchange b[x]
         delayed rom @07
         jsb S03563
L04206:  jsb S04337
S04207:  0 -> c[w]
         delayed rom @07
         go to L03640

S04212:  m1 exchange c
         register -> c 2
         go to L04176

S04215:  m1 exchange c
         register -> c 3
         go to L04176

S04220:  m1 exchange c
         register -> c 4
         go to L04176

S04223:  m1 exchange c
         register -> c 5
         go to L04176

S04226:  m1 exchange c
         register -> c 6
         go to L04176

S04231:  m1 exchange c
         register -> c 7
         p <- 13
         decimal
         c + c -> c[s]
         if n/c go to L04011
         load constant 9
         go to L04176

S04241:  load constant 11
         load constant 4
         load constant 13
         load constant 9
L04245:  load constant 1
L04246:  load constant 4
         return

S04250:  p <- 4
         load constant 1
         load constant 10
         load constant 5
         load constant 9
         go to L04246

S04256:  p <- 4
         load constant 1
         load constant 10
         load constant 9
         load constant 8
         load constant 12
L04264:  return

S04265:  load constant 1
S04266:  p <- 4
         load constant 3
         load constant 13
         load constant 3
         go to L04245

S04273:  p <- 4
         load constant 1
         load constant 12
         load constant 3
         load constant 10
         load constant 9
         return

L04302:  m2 exchange c
         binary
         m1 -> c
L04305:  c + 1 -> c[xs]
         m1 exchange c
L04307:  m2 -> c
         c -> data address
         data -> c
         delayed rom @04
         jsb S02137
         m1 -> c
         delayed rom @07
         jsb S03676
         if s 3 = 1
           then go to L04077
         jsb S04337
         p <- 0
         c + 1 -> c[p]
         if n/c go to L04302
         p <- 1
         if c[p] # 0
           then go to L04077
         c + 1 -> c[p]
         m2 exchange c
         m1 -> c
         p <- 4
         load constant 14
         load constant 11
         go to L04305

S04337:  0 -> s 3
         pick key?
         if 0 = s 3
           then go to L04264
         delayed rom @02
         go to L01343

L04345:  m2 exchange c
         delayed rom @13
         jsb S05655
         delayed rom @15
         jsb S06523
         delayed rom @03
         go to L01532

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

S04400:  register -> c 14
         c -> data address
         data -> c
         m2 exchange c
S04404:  display toggle
         delayed rom @13
         go to S05663

S04407:  1 -> s 7
S04410:  delayed rom @07
         go to L03554

S04412:  0 -> c[w]
         c -> register 12
         c -> register 13
         c -> register 15
L04416:  c -> register 14
L04417:  m2 -> c
         c -> data address
         data -> c
         jsb S04775
         jsb S04404
         register -> c 13
         m1 exchange c
         register -> c 12
         jsb S04410
         m2 exchange c
         c - 1 -> c[x]
         if n/c go to L04435
L04433:  m2 exchange c
         return

L04435:  m2 exchange c
         c -> register 13
         a exchange c[w]
         c -> register 12
         a exchange c[w]
         jsb S04534
         b exchange c[w]
         register -> c 13
         b exchange c[w]
         c -> register 13
         register -> c 12
         a exchange c[w]
         c -> register 12
         if 0 = s 2
           then go to L04417
         register -> c 15
         m1 exchange c
         register -> c 14
         jsb S04410
         jsb S04534
         c -> register 15
         a exchange c[w]
         go to L04416

L04464:  jsb S04504
         register -> c 1
         c - 1 -> c[x]
         c - 1 -> c[x]
         jsb S04775
         jsb S04410
         c -> register 11
         a exchange c[w]
         c -> register 10
         if a[s] # 0
           then go to L04532
         jsb S04412
         delayed rom @07
         jsb S03420
L04502:  delayed rom @10
         go to L04345

S04504:  jsb S04404
         0 -> s 2
         register -> c 3
         c -> register 12
         delayed rom @14
         jsb S06226
         if c[s] # 0
           then go to L04532
         a exchange c[w]
         rotate left a
         rotate left a
         rotate left a
         if a[ms] # 0
           then go to L04532
         p <- 1
         load constant 6
         load constant 9
         a exchange c[w]
         p <- 1
         c -> register 8
         a + c -> a[wp]
         if n/c go to L04433
L04532:  delayed rom @06
         go to L03026

S04534:  b exchange c[w]
         register -> c 11
         m1 exchange c
         register -> c 10
S04540:  delayed rom @07
         go to L03505

L04542:  jsb S04504
         jsb S04777
         c -> register 11
L04545:  register -> c 11
         c -> a[w]
         delayed rom @07
         jsb S03653
         c -> register 11
         0 -> c[w]
         c -> register 14
         c -> register 15
L04555:  jsb S04400
         c -> register 13
         register -> c 3
         c -> register 10
L04561:  register -> c 15
         0 -> s 4
L04563:  c -> register 9
L04564:  register -> c 15
         jsb S04775
         jsb S04407
         c -> register 15
         register -> c 8
         a exchange c[w]
         register -> c 14
         c + 1 -> c[x]
         c -> register 14
         if a >= c[x]
           then go to L04726
         if 0 = s 2
           then go to L04532
         if 0 = s 4
           then go to L04545
         jsb S04777
         jsb S04775
         go to L04623

L04606:  p <- 1
         if c[p] = 0
           then go to L04612
         0 -> s 4
L04612:  0 - c - 1 -> c[x]
         jsb S04777
         jsb S04410
         b exchange c[w]
         register -> c 11
         m1 exchange c
         register -> c 10
         delayed rom @07
         jsb S03433
L04623:  c -> register 11
         if c[xs] # 0
           then go to L04627
         0 - c - 1 -> c[x]
L04627:  a exchange c[w]
         c -> register 10
         delayed rom @10
         jsb S04337
         p <- 1
         load constant 1
         load constant 2
         p <- 1
         a + c -> a[wp]
         if n/c go to L04532
         if 0 = s 4
           then go to L04655
         register -> c 8
         m2 exchange c
         jsb S04412
         m1 exchange c
         register -> c 15
         b exchange c[w]
         register -> c 14
         a exchange c[w]
         if c[m] # 0
           then go to L04676
L04655:  register -> c 10
         a exchange c[w]
         register -> c 11
         1 -> s 7
         jsb S04670
         c + 1 -> c[x]
         c + 1 -> c[x]
         delayed rom @05
         jsb S02407
         c -> register 1
         go to L04502

S04670:  jsb S04777
S04671:  delayed rom @07
         go to L03561

L04673:  0 -> c[x]
         c -> a[w]
         go to L04612

L04676:  jsb S04540
         b exchange c[w]
         register -> c 9
         delayed rom @12
         jsb S05121
         jsb S04671
         jsb S04670
         jsb S04777
         m1 exchange c
L04707:  b exchange c[w]
         m1 exchange c
         a exchange c[w]
         jsb S04540
         0 -> c[m]
         p <- 12
         load constant 7
         if c[xs] = 0
           then go to L04673
         0 - c - 1 -> c[x]
         if c[x] # 0
           then go to L04606
         if a >= c[m]
           then go to L04673
         go to L04612

L04726:  register -> c 10
         a exchange c[w]
         register -> c 11
         delayed rom @07
         jsb S03422
         c -> register 10
         jsb S04400
         if c[m] = 0
           then go to L04764
         a exchange c[w]
         register -> c 13
         delayed rom @07
         jsb S03466
         if c[s] = 0
           then go to L04746
         1 -> s 2
L04746:  register -> c 10
         if a[xs] # 0
           then go to L04761
         if a >= c[x]
           then go to L04555
L04753:  if s 4 = 1
           then go to L04564
         1 -> s 4
         if a[s] # 0
           then go to L04564
         go to L04561

L04761:  0 - c -> c[x]
         if a >= c[x]
           then go to L04753
L04764:  register -> c 9
         if s 4 = 1
           then go to L04563
         jsb S04775
         load constant 5
         shift right c[m]
         jsb S04407
         go to L04563

         nop

S04775:  0 -> a[w]
         a exchange c[m]
S04777:  b exchange c[w]
         0 -> c[w]
         m1 exchange c
S05002:  0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         return

S05006:  jsb S05115
S05007:  jsb S05121
         if 0 = s 4
           then go to L05015
L05012:  b exchange c[w]
         0 - c - 1 -> c[s]
         b exchange c[w]
L05015:  if 0 = s 2
           then go to S04410
         delayed rom @07
         jsb S03553
         jsb S05027
         c -> data
         return

S05024:  0 -> s 2
S05025:  delayed rom @13
         go to S05671

S05027:  delayed rom @05
         go to S02407

L05031:  bank toggle

L05032:  jsb S05024
         1 -> s 2
         m2 -> c
         a exchange c[w]
         register -> c 1
         jsb S05006
         m2 -> c
         jsb S05125
         b exchange c[w]
         register -> c 2
         jsb S05007
         y -> a
         register -> c 3
         jsb S05006
         y -> a
         a exchange c[w]
         jsb S05125
         b exchange c[w]
         register -> c 4
         jsb S05007
         y -> a
         m2 -> c
         jsb S05126
         b exchange c[w]
         register -> c 5
         jsb S05007
         jsb S05002
         a exchange c[w]
         jsb S05025
         data -> c
         jsb S05006
         delayed rom @03
         go to L01716

L05073:  jsb S05024
         register -> c 3
         jsb S05134
         jsb S05027
         m2 exchange c
         register -> c 1
         jsb S05134
L05102:  jsb S05027
         m1 exchange c
         delayed rom @13
         jsb S05655
         c -> stack
         m1 -> c
         if s 0 = 1
           then go to L05375
L05112:  delayed rom @03
         go to L01532

S05114:  c -> a[w]
S05115:  0 -> b[w]
         a exchange b[m]
         a exchange b[w]
         return

S05121:  m1 exchange c
         m1 -> c
         0 -> c[x]
         return

S05125:  c -> a[w]
S05126:  jsb S05115
S05127:  m1 exchange c
         m1 -> c
         0 -> c[x]
S05132:  delayed rom @07
         go to S03433

S05134:  1 -> s 7
         a exchange c[w]
         jsb S05115
S05137:  jsb S05025
         data -> c
         jsb S05121
S05142:  delayed rom @07
         go to L03505

S05144:  jsb S05024
         data -> c
         a exchange c[w]
         jsb S05002
         1 -> s 4
         delayed rom @07
         jsb S03543
         if c[m] = 0
           then go to L04532
         data -> c
         jsb S05114
         register -> c 5
         jsb S05127
         c -> register 11
         a exchange c[w]
         c -> register 10
         register -> c 1
         jsb S05114
         register -> c 3
         jsb S05127
         jsb S05226
         c -> register 13
         a exchange c[w]
         c -> register 12
         jsb S05025
         data -> c
         jsb S05114
         register -> c 2
         jsb S05127
         c -> register 11
         a exchange c[w]
         c -> register 10
         register -> c 1
         jsb S05114
L05206:  jsb S05127
         jsb S05226
         c -> register 15
         a exchange c[w]
         c -> register 14
         jsb S05025
         data -> c
         jsb S05114
         register -> c 4
         jsb S05127
         c -> register 11
         a exchange c[w]
         c -> register 10
         register -> c 3
         jsb S05114
         jsb S05127
S05226:  b exchange c[w]
         register -> c 11
         m1 exchange c
         register -> c 10
         go to L05012

L05233:  jsb S05144
         b exchange c[w]
         register -> c 15
         m1 exchange c
         register -> c 14
         jsb S05132
         delayed rom @06
         jsb S03025
         m1 exchange c
         register -> c 13
         b exchange c[w]
         register -> c 12
         a exchange c[w]
         1 -> s 7
         jsb S05142
         m2 exchange c
         delayed rom @13
         jsb S05655
         go to L05112

L05256:  jsb S05144
         1 -> s 1
L05260:  b exchange c[w]
         jsb S05137
         b exchange c[w]
         data -> c
         a exchange c[w]
         c -> register 10
         b exchange c[w]
         c -> register 11
         jsb S05002
         a exchange c[w]
         jsb S05006
         m1 exchange c
         register -> c 11
         b exchange c[w]
         register -> c 10
         a exchange c[w]
         jsb S05142
         delayed rom @06
         jsb S03024
         jsb S05027
         if 0 = s 1
           then go to L05102
         m2 exchange c
         0 -> s 1
         register -> c 14
         a exchange c[w]
         register -> c 15
         go to L05260

L05314:  jsb S05144
         0 -> s 12
         m2 -> c
         go to L05337

S05320:  b exchange c[w]
         register -> c 15
         m1 exchange c
         register -> c 14
         go to S05142

L05325:  jsb S05144
         1 -> s 12
         register -> c 12
         a exchange c[w]
         register -> c 13
         1 -> s 7
         jsb S05320
         jsb S05027
         m2 exchange c
         0 -> c[w]
L05337:  c -> register 10
         register -> c 14
         a exchange c[w]
         register -> c 15
         b exchange c[w]
         register -> c 3
         jsb S05127
         c -> register 11
         register -> c 10
         a exchange c[w]
         c -> register 10
         jsb S05025
         data -> c
         jsb S05126
         b exchange c[w]
         register -> c 1
         jsb S05007
         b exchange c[w]
         register -> c 13
         m1 exchange c
         register -> c 12
         jsb S05132
         jsb S05226
         jsb S05320
         1 -> s 7
         b exchange c[w]
         jsb S05137
         if 0 = s 12
           then go to L05543
         go to L05102

L05375:  down rotate
         down rotate
         1 -> s 6
         go to L05423

L05401:  load constant 3
         load constant 4
         go to L05734

S05404:  data -> c
         a exchange c[w]
         go to L05563

L05407:  0 -> s 2
         go to L05741

L05411:  jsb S05431
         jsb S05474
         jsb S05504
         p <- 2
         load constant 5
         jsb S05516
         jsb S05504
         p <- 2
         load constant 6
         jsb S05516
L05423:  jsb S05504
         p <- 2
         if s 12 = 1
           then go to L05724
         load constant 7
         go to L05726

S05431:  delayed rom @07
         go to S03622

L05433:  go to L05445

L05434:  jsb S05431
         jsb S05677
         p <- 1
         load constant 0
         load constant 4
         jsb S05601
         jsb S05671
         clear data registers
         go to L05472

L05445:  jsb S05431
         jsb S05677
         load constant 6
         jsb S05601
         0 -> c[w]
         c -> data address
         c -> register 0
         c -> register 1
         c -> register 2
         c -> register 3
         c -> register 4
         c -> register 5
         c -> register 6
         c -> register 7
         c -> register 8
         c -> register 9
         jsb S05557
         clear data registers
         go to L05472

         load constant 8
         jsb S05516
L05472:  delayed rom @03
         go to L01642

S05474:  load constant 3
         load constant 11
         load constant 13
         load constant 11
         load constant 1
         load constant 4
         1 -> s 15
         go to S05601

S05504:  down rotate
         down rotate
         down rotate
         m2 exchange c
         m2 -> c
         go to L05514

         delayed rom @10
         jsb S04337
L05514:  delayed rom @04
         go to S02137

S05516:  delayed rom @07
         go to S03676

L05520:  delayed rom @07
         jsb S03633
         binary
         b -> c[p]
         c - 1 -> c[p]
         if n/c go to L05530
         jsb S05545
         go to L05536

L05530:  c - 1 -> c[p]
         if n/c go to L05603
         jsb S05545
         load constant 4
         p <- 1
         load constant 2
L05536:  jsb S05720
         m2 -> c
         if 0 = s 13
           then go to L05625
         data -> c
L05543:  delayed rom @03
         go to L01532

S05545:  if 0 = s 13
           then go to S05674
         if s 8 = 1
           then go to L05554
         m2 exchange c
         c -> stack
         m2 exchange c
L05554:  load constant 13
         load constant 12
         return

S05557:  0 -> c[w]
L05560:  c + 1 -> c[xs]
         shift right c[w]
         c -> data address
L05563:  m2 -> c
         return

L05565:  c + 1 -> c[p]
L05566:  c + 1 -> c[p]
         c + 1 -> c[p]
L05570:  p <- 0
         a exchange c[p]
         c -> data address
         a exchange c[x]
         shift left a[x]
         shift left a[x]
         a exchange c[x]
         p <- 1
         load constant 12
S05601:  delayed rom @07
         go to S03563

L05603:  c + 1 -> c[xs]
         c - 1 -> c[p]
         if n/c go to L05613
         jsb S05545
         load constant 11
         p <- 1
         load constant 1
         go to L05536

L05613:  c - 1 -> c[p]
         if n/c go to L05631
         jsb S05674
         load constant 15
         jsb S05720
         jsb S05404
         delayed rom @07
         jsb S03653
L05623:  delayed rom @05
         jsb S02407
L05625:  c -> data
         m2 -> c
L05627:  delayed rom @03
         go to L01641

L05631:  c + 1 -> c[xs]
         c - 1 -> c[p]
         if n/c go to L05643
         jsb S05674
         load constant 3
         jsb S05720
         jsb S05404
         delayed rom @07
         jsb S03543
         go to L05623

L05643:  c - 1 -> c[p]
         if n/c go to L05711
         jsb S05674
         load constant 14
         jsb S05720
         jsb S05404
         delayed rom @07
         jsb S03422
         go to L05623

L05654:  1 -> s 9
S05655:  if s 8 = 1
           then go to S05663
         0 -> c[w]
         c -> data address
         register -> c 14
         c -> stack
S05663:  0 -> c[w]
         c + 1 -> c[xs]
         if n/c go to L05672
L05666:  c - 1 -> c[xs]
         if n/c go to L05565
         go to L05566

S05671:  0 -> c[w]
L05672:  c + 1 -> c[xs]
         if n/c go to L05560
S05674:  load constant 7
         load constant 4
         return

S05677:  load constant 9
         load constant 0
         load constant 14
         load constant 0
         load constant 2
         return

L05705:  if s 1 = 1
           then go to L05765
         delayed rom @07
         bank toggle

L05711:  jsb S05674
         load constant 10
         jsb S05720
         jsb S05404
         delayed rom @07
         jsb S03466
         go to L05623

S05720:  p <- 4
         c - 1 -> c[xs]
         if n/c go to L05666
         go to L05570

L05724:  load constant 9
         load constant 4
L05726:  jsb S05516
         jsb S05504
         p <- 2
         if s 12 = 1
           then go to L05401
         load constant 8
L05734:  jsb S05516
         if 0 = s 6
           then go to L04077
         go to L05627

L05740:  1 -> s 2
L05741:  jsb S05431
         jsb S05474
         jsb S05431
         load constant 12
         load constant 12
         if 0 = s 2
           then go to L05751
         load constant 4
L05751:  p <- 1
         load constant 12
         m1 exchange c
         0 -> c[w]
         if 0 = s 2
           then go to L05761
         p <- 1
         load constant 2
L05761:  m2 exchange c
         delayed rom @10
         go to L04307

         nop

L05765:  delayed rom @11
         bank toggle

         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop

S06000:  p <- 10
         if s 11 = 1
           then go to L06004
         p <- 9
L06004:  a + c -> a[x]
         0 -> c[wp]
         delayed rom @07
         go to S03422

L06010:  1 -> s 4
         a + c -> c[w]
         jsb S06226
         p <- 9
         go to L06166

S06015:  0 -> s 4
         if a[w] # 0
           then go to L06010
S06020:  register -> c 15
         if 0 = s 11
           then go to L06234
L06023:  register -> c 9
         delayed rom @17
         jsb S07765
         jsb S06000
         c -> register 12
         register -> c 10
         a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 1
         load constant 5
         a - c -> c[m]
         if c[m] # 0
           then go to L06056
         p <- 12
         load constant 2
         load constant 9
         a exchange c[w]
         register -> c 11
         a - c -> a[m]
         if a[m] # 0
           then go to L06056
         if s 11 = 1
           then go to L06056
         p <- 11
         c - 1 -> c[p]
         c -> register 11
L06056:  register -> c 10
         delayed rom @17
         jsb S07752
         jsb S06000
         delayed rom @04
         jsb S02306
         a exchange b[w]
         register -> c 12
         jsb S06117
         register -> c 11
         a exchange c[w]
         if 0 = s 11
           then go to S06117
         if s 3 = 1
           then go to S06117
         1 -> s 3
         c -> register 12
         0 -> c[w]
         p <- 12
         load constant 3
         c + 1 -> c[p]
         a - c -> c[m]
         if c[m] # 0
           then go to L06107
         a - 1 -> a[p]
L06107:  0 -> c[w]
         p <- 12
         load constant 3
         a - c -> c[m]
         if c[m] # 0
           then go to L06116
         0 -> s 3
L06116:  register -> c 12
S06117:  delayed rom @07
         go to S03653

S06121:  p <- 12
         a exchange c[w]
         a + 1 -> a[x]
         if a[p] # 0
           then go to S06130
         shift left a[m]
         a - 1 -> a[x]
S06130:  a exchange c[w]
S06131:  delayed rom @17
         go to S07562

S06133:  if a[w] # 0
           then go to L06762
         go to S06020

L06136:  jsb S06225
         a exchange c[w]
         register -> c 4
         jsb S06226
         p <- 8
         a - c -> a[wp]
         if n/c go to L06154
L06145:  delayed rom @06
         go to L03026

L06147:  p <- 11
         c - 1 -> c[p]
         a - c -> a[w]
         1 -> s 2
         go to L06255

L06154:  if a[wp] # 0
           then go to L06235
         0 -> c[wp]
         a - c -> a[w]
         if n/c go to L06162
         go to L06145

L06162:  if a[m] # 0
           then go to L06235
         go to L06145

S06165:  p <- 5
L06166:  c - 1 -> c[p]
         if n/c go to L06234
         p + 1 -> p
         go to L06166

S06172:  p <- 5
L06173:  c + 1 -> c[p]
         if n/c go to L06234
         p + 1 -> p
         go to L06173

L06177:  if a >= c[w]
           then go to L06270
         m2 exchange c
         jsb S06172
         m2 exchange c
         b exchange c[w]
         go to L06267

L06206:  if 0 = s 2
           then go to L06215
         jsb S06172
L06211:  m2 exchange c
L06212:  jsb S06165
         m2 exchange c
         go to L06271

L06215:  if a >= c[w]
           then go to L06220
         go to L06211

L06220:  b exchange c[w]
         jsb S06172
         m2 exchange c
         jsb S06165
         go to L06212

S06225:  register -> c 5
S06226:  c - 1 -> c[x]
         if n/c go to L06232
         0 -> c[x]
         shift right c[w]
L06232:  if c[x] # 0
           then go to L06762
L06234:  return

L06235:  0 -> c[w]
         a exchange c[wp]
         c + c -> c[w]
         m2 exchange c
         jsb S06225
         0 -> s 2
         a exchange c[w]
         a -> b[w]
         0 -> c[w]
         p <- 11
         load constant 6
         a + c -> a[w]
         load constant 5
         c + c -> c[w]
         if a >= c[w]
           then go to L06147
L06255:  register -> c 4
         jsb S06226
         a exchange c[w]
         p <- 8
         a -> b[wp]
         b -> c[wp]
         if a >= b[w]
           then go to L06206
         if s 2 = 1
           then go to L06177
L06267:  jsb S06165
L06270:  b exchange c[w]
L06271:  c -> register 14
         b exchange c[w]
L06273:  jsb S06121
         jsb S06015
         if s 4 = 1
           then go to L06273
         c -> register 8
         register -> c 14
L06301:  jsb S06121
         jsb S06015
         if s 4 = 1
           then go to L06301
         0 - c - 1 -> c[s]
         c -> register 14
         register -> c 4
         a exchange c[w]
         jsb S06130
         jsb S06020
         a exchange c[w]
         register -> c 14
         jsb S06117
         register -> c 14
         a exchange c[w]
         c -> register 14
         register -> c 8
         jsb S06117
         register -> c 14
         a exchange c[w]
         delayed rom @07
         jsb S03466
         m2 exchange c
         a exchange c[w]
         0 -> c[w]
         p <- 0
         load constant 7
         delayed rom @06
         jsb S03073
         c -> register 10
         m2 -> c
         jsb S06117
         c -> register 3
         register -> c 10
         if 0 = s 10
           then go to L07337
         register -> c 6
         jsb S06131
         jsb S06133
         c -> register 3
         register -> c 15
         c -> register 8
         register -> c 4
         jsb S06131
         jsb S06133
         m2 exchange c
         register -> c 15
         c -> register 14
         register -> c 5
         jsb S06131
         jsb S06133
         c -> register 9
         m2 -> c
         c -> register 13
L06367:  register -> c 15
         c -> a[w]
         register -> c 14
         delayed rom @16
         go to L07176

L06374:  delayed rom @13
         go to L05705

         nop
         nop

L06400:  c -> stack
         jsb S06657
         delayed rom @04
         jsb S02125
         jsb S06726
         register -> c 14
         jsb S06724
         0 -> s 0
         delayed rom @03
         go to L01531

         nop

L06413:  go to L06432

L06414:  go to L06441

L06415:  jsb S06561
         jsb S06563
         if s 2 = 1
           then go to L07150
         if s 13 = 1
           then go to L06636
         jsb S06551
         c -> register 2
L06425:  1 -> s 2
         0 -> s 1
         jsb S06764
         delayed rom @05
         go to L02444

L06432:  jsb S06561
         jsb S06773
         if s 13 = 1
           then go to L06631
         jsb S06551
         c -> register 7
         go to L06425

L06441:  jsb S06561
         delayed rom @10
         jsb S04273
         if s 2 = 1
           then go to L07142
         if s 13 = 1
           then go to L06637
         jsb S06551
         c -> register 1
         go to L06425

L06453:  jsb S06561
         if s 13 = 1
           then go to L06603
         if 0 = s 10
           then go to L06474
         jsb S06665
         jsb S06551
         delayed rom @17
         jsb S07560
         jsb S06511
         c -> register 6
L06466:  m2 -> c
         delayed rom @17
         jsb S07562
         jsb S06511
         c -> register 4
         go to L06425

L06474:  jsb S06670
         jsb S06551
         go to L06466

L06477:  jsb S06561
         jsb S06576
         if s 13 = 1
           then go to L06633
         jsb S06551
         delayed rom @17
         jsb S07562
         jsb S06511
         c -> register 5
         go to L06425

S06511:  if a[w] # 0
           then go to L06762
         return

L06514:  jsb S06561
         jsb S06553
         if s 13 = 1
           then go to L06640
         jsb S06551
         c -> register 0
         go to L06425

S06523:  p <- 0
L06524:  m2 exchange c
         0 -> c[w]
         c -> data address
         0 -> s 4
         c + 1 -> c[p]
         c -> register 13
         0 -> s 12
         if 0 = s 13
           then go to L06540
         0 -> s 1
         0 -> s 2
         0 -> s 13
L06540:  m2 -> c
L06541:  return

S06542:  p <- 3
         go to L06524

L06544:  jsb S06670
         go to L06634

S06546:  p <- 7
         load constant 15
         load constant 7
S06551:  delayed rom @07
         go to S03563

S06553:  p <- 4
         load constant 2
         load constant 4
         load constant 6
         load constant 8
         go to L06574

S06561:  delayed rom @16
         go to L07121

S06563:  p <- 4
         load constant 1
         load constant 10
         load constant 9
         load constant 10
         go to L06601

S06571:  p <- 2
         load constant 15
         load constant 6
L06574:  load constant 12
         return

S06576:  p <- 2
         load constant 5
         load constant 9
L06601:  load constant 4
         return

L06603:  if 0 = s 10
           then go to L06544
         jsb S06665
         jsb S06546
         jsb S06663
         register -> c 6
         jsb S06657
         jsb S06571
         jsb S06624
         c -> stack
         register -> c 4
         jsb S06657
         jsb S06670
         jsb S06624
         jsb S06764
         delayed rom @03
         go to L01641

S06624:  if 0 = s 0
           then go to L06540
         a exchange b[x]
         1 -> s 9
         go to S06551

L06631:  a + 1 -> a[x]
L06632:  a + 1 -> a[x]
L06633:  a + 1 -> a[x]
L06634:  a + 1 -> a[x]
L06635:  a + 1 -> a[x]
L06636:  a + 1 -> a[x]
L06637:  a + 1 -> a[x]
L06640:  a exchange c[x]
         p <- 1
         load constant 3
         c -> data address
         a exchange c[x]
         jsb S06546
         data -> c
         if 0 = s 12
           then go to L06655
L06651:  jsb S06764
L06652:  jsb S06663
         delayed rom @03
         go to L01534

L06655:  jsb S06542
         go to L06652

S06657:  m2 exchange c
         m2 -> c
S06661:  delayed rom @04
         go to S02137

S06663:  delayed rom @13
         go to S05655

S06665:  load constant 15
         load constant 6
         load constant 12
S06670:  p <- 2
         load constant 11
L06672:  load constant 1
         go to L06601

S06674:  p <- 3
         load constant 13
         load constant 9
         go to L06672

L06700:  if 0 = s 10
           then go to L06703
         jsb S06743
L06703:  1 -> s 8
L06704:  m2 -> c
         0 -> s 13
         0 -> s 1
         1 -> s 2
         0 -> s 12
         go to L06651

S06712:  m2 -> c
         c -> stack
         jsb S06661
         1 -> s 8
         p <- 2
         load constant 3
         load constant 7
         load constant 13
         go to S06726

S06723:  c -> stack
S06724:  jsb S06657
         jsb S06674
S06726:  1 -> s 9
         decimal
         a exchange b[x]
         if 0 = s 0
           then go to L06540
         go to S06551

S06734:  register -> c 13
         c -> register 14
         jsb S06663
         register -> c 3
         c -> register 8
         register -> c 9
         c -> register 15
S06743:  register -> c 11
         c -> register 3
         return

L06746:  c -> register 1
         m2 exchange c
         if s 12 = 1
           then go to L06700
         jsb S06734
         if 0 = s 11
           then go to L06703
         register -> c 1
L06756:  jsb S06723
         1 -> s 12
         delayed rom @14
         go to L06367

L06762:  delayed rom @06
         go to L03026

S06764:  p <- 2
         go to L06524

         nop
         nop
         nop
         nop
         nop

S06773:  load constant 9
         load constant 0
         load constant 13
         load constant 3
         load constant 8
         go to L07374

S07001:  delayed rom @05
         go to S02407

L07003:  go to L07103

L07004:  jsb S07120
         delayed rom @10
         jsb S04241
         if s 13 = 1
           then go to L06637
         jsb S07101
         c -> register 1
L07013:  delayed rom @15
         jsb S06542
         delayed rom @05
         go to L02444

L07017:  jsb S07120
         jsb S07124
         if s 13 = 1
           then go to L06635
         jsb S07101
         if c[w] = 0
           then go to L06762
         if c[s] # 0
           then go to L06762
         c -> register 3
         go to L07013

L07032:  jsb S07120
         jsb S07367
         if s 13 = 1
           then go to L06640
         jsb S07101
         c -> register 0
         go to L07013

L07041:  jsb S07120
         jsb S07063
         load constant 7
         if s 13 = 1
           then go to L06633
         jsb S07101
         jsb S07067
         c -> register 5
         go to L07013

L07052:  jsb S07120
         jsb S07063
         load constant 11
         if s 13 = 1
           then go to L06632
         jsb S07101
         jsb S07067
         c -> register 6
         go to L07013

S07063:  p <- 2
S07064:  load constant 3
         load constant 0
         return

S07067:  if c[s] # 0
           then go to L06762
         delayed rom @04
         jsb S02306
L07073:  if a[w] # 0
           then go to L06762
         if b[w] = 0
           then go to L06762
         m2 -> c
         return

S07101:  delayed rom @07
         go to S03563

L07103:  jsb S07120
         jsb S07133
         if s 13 = 1
           then go to L06636
         jsb S07101
         c -> register 2
         go to L07013

S07112:  c -> a[w]
         delayed rom @04
         jsb S02243
         jsb S07361
         c -> data
         return

S07120:  0 -> s 12
L07121:  0 -> a[x]
         delayed rom @07
         go to L03624

S07124:  load constant 3
         load constant 11
         load constant 13
         load constant 11
         load constant 6
         load constant 8
         return

S07133:  load constant 9
         load constant 4
         load constant 3
         load constant 0
         load constant 12
         load constant 10
         return

L07142:  1 -> s 1
L07143:  delayed rom @04
         jsb S02143
         jsb S07152
         delayed rom @14
         go to L06136

L07150:  0 -> s 1
         go to L07143

S07152:  jsb S07120
         p <- 5
         if 0 = s 10
           then go to L07167
         jsb S07064
         load constant 3
         load constant 5
         load constant 2
         load constant 8
L07163:  if 0 = s 15
           then go to L06541
         delayed rom @00
         go to L00351

L07167:  load constant 9
         load constant 4
         load constant 3
         load constant 3
         load constant 2
         load constant 9
         go to L07163

L07176:  jsb S07356
         c -> register 11
         register -> c 15
         c -> a[w]
         register -> c 8
         jsb S07356
         c -> register 10
L07205:  register -> c 11
         jsb S07356
         c -> register 12
         register -> c 10
         jsb S07112
         register -> c 11
         jsb S07112
         register -> c 12
         jsb S07112
         delayed rom @13
         jsb S05663
         data -> c
         c -> a[w]
         if 0 = s 10
           then go to L07226
         register -> c 7
         jsb S07363
L07226:  c -> register 14
         register -> c 12
         jsb S07365
         jsb S07001
         m2 exchange c
         register -> c 11
         c -> a[w]
         if 0 = s 1
           then go to L07273
         register -> c 14
         jsb S07365
         c -> register 8
         register -> c 7
         c -> a[w]
         register -> c 2
         jsb S07356
         register -> c 8
         jsb S07357
         c -> register 8
         m2 -> c
         c -> a[w]
         register -> c 2
         jsb S07357
         register -> c 11
         jsb S07363
         register -> c 8
         a exchange c[w]
         jsb S07361
         jsb S07001
         delayed rom @15
         go to L06746

L07265:  if 0 = s 10
           then go to L07271
         delayed rom @15
         jsb S06743
L07271:  0 -> s 11
         go to L07326

L07273:  register -> c 1
         jsb S07365
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         c + 1 -> c[x]
         c + 1 -> c[x]
         jsb S07357
         register -> c 14
         a exchange c[w]
         c -> register 15
         register -> c 10
         jsb S07365
         register -> c 7
         jsb S07357
         register -> c 15
         jsb S07361
         a + 1 -> a[x]
         a + 1 -> a[x]
         m2 -> c
         jsb S07356
         jsb S07001
         c -> register 2
         if s 12 = 1
           then go to L07265
         delayed rom @15
         jsb S06734
L07326:  delayed rom @15
         jsb S06712
         register -> c 2
         m2 exchange c
         if 0 = s 11
           then go to L06704
         m2 -> c
         delayed rom @15
         go to L06756

L07337:  if c[w] # 0
           then go to L06374
         m2 -> c
         c -> register 11
         0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         c -> register 10
         c -> a[w]
         c + 1 -> c[p]
         c -> register 13
         1 -> s 12
         delayed rom @13
         jsb S05655
         go to L07205

S07356:  0 - c - 1 -> c[s]
S07357:  delayed rom @07
         go to S03653

S07361:  delayed rom @07
         go to S03466

S07363:  c - 1 -> c[x]
         c - 1 -> c[x]
S07365:  delayed rom @07
         go to S03422

S07367:  p <- 4
         load constant 2
         load constant 12
         load constant 3
         load constant 4
L07374:  load constant 14
         return

         nop

L07377:  register -> c 10
         jsb S07752
         jsb S07452
         jsb S07427
         register -> c 11
         jsb S07434
         c -> register 11
         a - 1 -> a[x]
         a - 1 -> a[x]
         register -> c 10
         jsb S07437
         register -> c 9
         0 - c -> c[x]
         jsb S07437
         c - 1 -> c[x]
         if n/c go to L07473
         a - 1 -> a[p]
L07420:  register -> c 13
         a exchange c[w]
         a - c -> a[w]
         return

S07424:  register -> c 9
         c - 1 -> c[x]
         c - 1 -> c[x]
S07427:  delayed rom @04
         go to S02306

S07431:  register -> c 12
S07432:  a exchange b[w]
         go to S07437

S07434:  a exchange b[w]
S07435:  a exchange c[w]
S07436:  0 - c - 1 -> c[s]
S07437:  delayed rom @07
         go to S03653

S07441:  register -> c 9
S07442:  a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 4
         p <- 0
         load constant 2
S07450:  delayed rom @07
         go to S03466

S07452:  delayed rom @07
         go to S03422

S07454:  0 -> a[m]
         c -> register 15
         0 -> c[x]
         p <- 0
         load constant 5
         a - c -> a[x]
S07462:  if a[w] # 0
           then go to L06762
         register -> c 15
         c -> a[w]
         return

S07467:  register -> c 9
         p <- 9
         delayed rom @14
         go to L06166

L07473:  0 -> c[w]
         load constant 1
         load constant 4
         a - c -> c[m]
         if n/c go to L07744
         p + 1 -> p
         a - 1 -> a[p]
         if n/c go to L07420
L07503:  shift left a[m]
         0 -> a[x]
         go to L07420

L07506:  jsb S07560
         jsb S07462
         m2 -> c
         jsb S07437
         jsb S07427
         b -> c[w]
         c -> a[w]
         jsb S07454
         jsb S07545
         c -> register 12
         jsb S07667
         delayed rom @05
         go to L02400

L07523:  jsb S07560
         jsb S07462
         0 -> s 3
         jsb S07542
         c -> register 8
         m2 -> c
         jsb S07562
         jsb S07462
         register -> c 14
         jsb S07436
         jsb S07542
         register -> c 8
         jsb S07436
         delayed rom @15
         go to L06400

S07542:  c -> register 14
         delayed rom @14
         go to L06023

S07545:  p <- 12
         0 -> c[wp]
         load constant 4
         load constant 7
         load constant 8
         load constant 1
         load constant 6
         load constant 4
         p <- 0
         load constant 5
         go to S07437

S07560:  y -> a
         a exchange c[w]
S07562:  c -> register 13
         display toggle
         decimal
         if c[s] # 0
           then go to L06762
         delayed rom @14
         jsb S06226
         p <- 4
         if c[wp] # 0
           then go to L06762
         0 -> a[w]
         p <- 10
         a exchange c[wp]
         c + 1 -> c[x]
         c -> register 10
         shift left a[w]
         shift left a[w]
         a exchange c[m]
         a exchange c[wp]
         a exchange c[x]
         c -> register 11
         shift left a[w]
         shift left a[w]
         a exchange c[m]
         c + 1 -> c[x]
         c + 1 -> c[x]
         c -> register 9
         register -> c 10
         a exchange c[w]
         0 -> c[w]
         p <- 11
         load constant 3
         p <- 11
         if a >= c[m]
           then go to L07632
         b exchange c[w]
         jsb S07467
         c -> register 9
         p <- 12
         b exchange c[w]
L07632:  load constant 1
         a + c -> c[w]
         c -> register 10
         register -> c 9
         jsb S07765
         jsb S07452
         jsb S07427
         b exchange c[w]
         c -> register 12
         jsb S07424
         register -> c 12
         jsb S07434
         c -> register 12
         jsb S07441
         jsb S07427
         jsb S07431
         c -> register 12
         register -> c 10
         jsb S07752
         jsb S07452
         jsb S07427
         jsb S07431
         register -> c 11
         jsb S07437
         c -> register 12
         0 - c - 1 -> c[s]
         jsb S07545
         jsb S07454
         c -> register 15
S07667:  register -> c 12
         jsb S07765
         p <- 12
         load constant 1
         load constant 2
         load constant 1
         load constant 5
         load constant 0
         jsb S07436
         jsb S07765
         p <- 8
         load constant 4
         jsb S07773
         jsb S07450
         jsb S07427
         b exchange c[w]
L07707:  c -> register 9
         jsb S07765
         jsb S07452
         jsb S07427
         b exchange c[w]
         c -> register 10
         jsb S07424
         register -> c 10
         jsb S07434
         c -> register 10
         jsb S07441
         jsb S07427
         register -> c 10
         jsb S07432
         register -> c 12
         jsb S07435
         c -> register 11
         jsb S07753
         jsb S07450
         jsb S07427
         b exchange c[w]
         c -> register 10
         jsb S07442
         c + 1 -> c[x]
         c + 1 -> c[x]
         if c[xs] = 0
           then go to L07377
         jsb S07467
         go to L07707

L07744:  p <- 11
         c + 1 -> c[p]
         delayed rom @14
         jsb S06172
         a exchange c[m]
         go to L07503

S07752:  a exchange c[w]
S07753:  0 -> c[w]
         p <- 12
         load constant 3
         load constant 0
         load constant 6
         p <- 7
         load constant 1
         p <- 0
         load constant 1
         return

S07765:  a exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 3
         load constant 6
         load constant 5
S07773:  load constant 2
         load constant 5
         p <- 0
         load constant 2
         return

; bank 1
	.bank 1
	.org @2000

L12000:  p <- 9
         load constant 3
         load constant 1
         load constant 0
         load constant 1
         load constant 7
         load constant 9
         load constant 8
         load constant 0
         load constant 4
         load constant 3
         p <- 11
         return

L12015:  c + 1 -> c[s]
         if n/c go to L12225
         p <- 1
         c + 1 -> c[p]
         if n/c go to L12204
L12022:  b exchange c[s]
         c + 1 -> c[s]
         b exchange c[s]
         p - 1 -> p
         shift right a[w]
         go to L12246

L12030:  p <- 5
         load constant 3
         load constant 3
         load constant 3
         load constant 0
         load constant 8
         load constant 4
         p <- 9
         return

L12041:  a + 1 -> a[x]
         if n/c go to L12204
         a + c -> c[m]
         if n/c go to L12204
         go to L12170

L12046:  c + 1 -> c[x]
L12047:  if c[x] = 0
           then go to L12751
         c - 1 -> c[x]
         shift left a[m]
         p - 1 -> p
         if a[m] # 0
           then go to L12047
         a exchange c[x]
         b exchange c[w]
         0 -> c[w]
         0 -> a[w]
L12062:  if 0 = s 14
           then go to L13114
         go to L12117

         0 -> a[w]
         p <- 12
         f -> a[x]
L12070:  if p = 2
           then go to L12117
         p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L12070
         c -> a[w]
         if c[xs] = 0
           then go to L12342
L12100:  p + 1 -> p
         if p = 13
           then go to L12116
         a + 1 -> a[x]
         if n/c go to L12100
         go to L12346

L12106:  binary
         a + 1 -> a[s]
         decimal
         c - 1 -> c[x]
L12112:  if a[p] # 0
           then go to L13336
         shift left a[wp]
         go to L12106

L12116:  0 -> c[w]
L12117:  0 -> s 14
         0 -> s 7
         bank toggle

L12122:  a exchange c[w]
         shift left a[x]
         a exchange c[w]
         shift left a[w]
         if c[xs] # 0
           then go to L13262
         go to L12275

L12131:  p <- 3
         load constant 3
         load constant 3
         load constant 3
         load constant 3
         p <- 8
         return

         0 -> a[w]
         0 -> b[ms]
         p <- 12
         f -> a[x]
         if c[s] = 0
           then go to L12152
         decimal
         a - 1 -> a[p]
         a exchange b[p]
         0 -> c[s]
L12152:  binary
L12153:  p - 1 -> p
         a - 1 -> a[x]
         if n/c go to L12153
         0 -> a[x]
         c -> a[m]
         decimal
         if p = 1
           then go to L12204
         f -> a[x]
         if c[xs] = 0
           then go to L12230
         a + c -> a[x]
         if n/c go to L12041
L12170:  0 -> a[x]
L12171:  c + 1 -> c[x]
         shift right a[w]
         if c[x] = 0
           then go to L12233
         go to L12171

L12176:  c + 1 -> c[x]
         shift right a[w]
         p - 1 -> p
L12201:  0 -> a[wp]
         a exchange c[m]
L12203:  go to L12117

L12204:  0 -> c[m]
         a exchange c[m]
         a + c -> a[m]
         0 -> a[x]
         if c[xs] = 0
           then go to L12216
         a + 1 -> a[xs]
         a + 1 -> a[xs]
         0 - c -> c[x]
         a exchange c[xs]
L12216:  c -> a[x]
         p <- 11
         0 -> c[xs]
         c + 1 -> c[s]
         b exchange c[s]
         binary
         go to L12256

L12225:  if p = 2
           then go to L12230
         p - 1 -> p
L12230:  c - 1 -> c[x]
         if n/c go to L12015
         0 -> a[x]
L12233:  binary
         c + 1 -> c[s]
         decimal
         b exchange c[s]
         0 -> c[w]
         a exchange c[w]
         c -> a[wp]
         a + c -> a[w]
         binary
         if a[s] # 0
           then go to L12022
L12246:  b -> c[s]
         0 -> a[wp]
         a - 1 -> a[wp]
         p <- 13
L12252:  p - 1 -> p
         c - 1 -> c[s]
         if n/c go to L12252
         shift right a[x]
L12256:  a exchange c[x]
         shift right a[wp]
         shift left a[w]
         a exchange c[x]
         p <- 5
         0 -> b[p]
         0 -> c[w]
         c - 1 -> c[w]
         p <- 7
         load constant 12
         0 -> c[wp]
         p <- 5
         go to L12117

         nop

L12274:  c + 1 -> c[x]
L12275:  a - b -> a[w]
         if n/c go to L12274
         a + b -> a[w]
         c - 1 -> c[m]
         if n/c go to L12122
         select rom go to L13303

L12303:  p <- 1
         load constant 3
         load constant 3
         p <- 7
         return

         1 -> s 14
         c -> a[w]
         decimal
         p <- 12
         if c[xs] = 0
           then go to L12046
         0 -> b[w]
         go to L12062

L12320:  p <- 7
         load constant 3
         load constant 3
         load constant 0
         load constant 8
         load constant 5
         load constant 3
         load constant 1
         load constant 7
         p <- 10
         return

L12333:  if s 9 = 1
           then go to L13125
         if 0 = s 2
           then go to L12062
         delayed rom @10
         go to L14310

L12341:  p - 1 -> p
L12342:  if p = 2
           then go to L12203
         a - 1 -> a[x]
         if n/c go to L12341
L12346:  0 -> a[s]
         0 -> a[x]
         0 -> b[w]
         a -> b[wp]
         a + b -> a[w]
         if a[s] # 0
           then go to L12176
         go to L12201

L12356:  a exchange c[w]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[w]
         go to L12275

L12364:  a -> b[w]
L12365:  if c[x] # 0
           then go to L12737
         if c[s] # 0
           then go to L12403
         binary
         a + 1 -> a[s]
         decimal
         a exchange b[w]
         a + 1 -> a[s]
         shift right a[w]
         a exchange b[w]
         go to L12436

L12401:  stack -> a
         go to L12470

L12403:  a exchange b[s]
         shift right a[w]
         1 -> s 8
         0 -> c[w]
         go to L12572

         1 -> s 14
S12411:  if c[m] # 0
           then go to L12414
         0 -> c[w]
L12414:  p <- 12
         decimal
         if c[xs] = 0
           then go to L12425
         c - 1 -> c[x]
         c + 1 -> c[xs]
         c - 1 -> c[xs]
         if n/c go to L12472
         c + 1 -> c[x]
L12425:  delayed rom @04
         go to L12062

L12427:  0 -> c[wp]
         c - 1 -> c[wp]
         0 -> c[xs]
L12432:  p <- 13
         go to L12425

L12434:  0 -> c[w]
         jsb S12757
L12436:  a exchange c[s]
         m1 exchange c
         delayed rom @07
         jsb S13523
         binary
         a + c -> a[s]
         a - 1 -> a[s]
L12445:  0 -> c[x]
L12446:  shift right a[wp]
         a -> b[s]
         p <- 13
L12451:  p - 1 -> p
         a - 1 -> a[s]
         if n/c go to L12451
         a exchange b[s]
         a -> b[s]
         0 -> c[ms]
         go to L12572

L12460:  a + 1 -> a[x]
         p - 1 -> p
         go to L12726

         jsb S12476
         if s 9 = 1
           then go to L12401
         delayed rom @06
         jsb S13340
L12470:  delayed rom @03
         go to L01531

L12472:  c + c -> c[xs]
         if n/c go to L12427
         0 -> c[w]
         go to L12432

S12476:  p <- 12
         0 -> s 8
         if c[m] = 0
           then go to L12764
         if c[s] = 0
           then go to L12530
         if 0 = s 9
           then go to L13767
         if a[xs] # 0
           then go to L13767
         a + 1 -> a[x]
L12511:  a - 1 -> a[x]
         shift left a[ms]
         if a[m] # 0
           then go to L13765
         if a[x] # 0
           then go to L12527
         a exchange c[s]
         c -> a[s]
         c + c -> c[s]
         c + c -> c[s]
         a + c -> c[s]
         if c[s] = 0
           then go to L12530
         1 -> s 4
L12527:  0 -> c[s]
L12530:  if c[x] = 0
           then go to L12666
         0 -> a[w]
         c -> a[m]
         go to L12557

L12535:  jsb S12757
L12536:  m1 exchange c
         m1 -> c
         0 -> a[s]
         c + 1 -> c[x]
         p <- 12
         if c[xs] # 0
           then go to L12364
         0 -> c[w]
         m1 exchange c
         b exchange c[w]
         0 -> c[w]
         c + 1 -> c[p]
         delayed rom @07
         jsb S13556
L12554:  p <- 12
         if c[x] = 0
           then go to L12667
L12557:  0 -> b[w]
         a exchange b[w]
         a - b -> a[wp]
         c + 1 -> c[x]
         if c[x] # 0
           then go to L12446
         1 -> s 8
         jsb S12757
         go to L12445

L12570:  shift right a[w]
         c + 1 -> c[p]
L12572:  a exchange b[s]
         a -> b[w]
         binary
         a + c -> a[s]
         m1 exchange c
         a exchange c[s]
         shift left a[w]
L12601:  shift right a[w]
         c - 1 -> c[s]
         if n/c go to L12601
         decimal
         m1 exchange c
         a + b -> a[w]
         shift left a[w]
         a - 1 -> a[s]
         if n/c go to L12570
         c -> a[s]
         a - 1 -> a[s]
         a + c -> a[s]
         if n/c go to L12621
L12616:  a exchange b[w]
         shift left a[w]
         go to L12633

L12621:  if p = 1
           then go to L12616
         c + 1 -> c[s]
         p - 1 -> p
         a exchange b[w]
         a exchange b[s]
         shift left a[w]
         go to L12572

L12631:  c - 1 -> c[s]
         p + 1 -> p
L12633:  b exchange c[w]
         delayed rom @06
         jsb S13354
         shift right a[w]
         b exchange c[w]
         go to L12642

L12641:  a + b -> a[w]
L12642:  c - 1 -> c[p]
         if n/c go to L12641
         if c[s] # 0
           then go to L12631
         if p = 12
           then go to L12677
         0 -> c[w]
L12651:  p + 1 -> p
         c - 1 -> c[x]
         if p # 12
           then go to L12651
L12655:  jsb S12757
         0 -> a[s]
         if 0 = s 8
           then go to L12662
         0 - c - 1 -> c[s]
L12662:  if 0 = s 12
           then go to L12333
         delayed rom @10
         go to L14243

L12666:  c -> a[w]
L12667:  a -> b[w]
         a - 1 -> a[p]
         if a[m] # 0
           then go to L12434
         if a[x] # 0
           then go to L12535
         0 -> c[w]
         go to L12662

L12677:  if c[x] = 0
           then go to L12655
         c - 1 -> c[w]
         jsb S12772
         a exchange c[w]
         a - c -> c[w]
         if b[xs] = 0
           then go to L12710
         a - c -> c[w]
L12710:  a exchange c[w]
         b exchange c[w]
         if c[xs] = 0
           then go to L12715
         0 - c - 1 -> c[w]
L12715:  a exchange c[wp]
L12716:  p - 1 -> p
         shift left a[w]
         if p # 1
           then go to L12716
         p <- 12
         if a[p] # 0
           then go to L12460
         shift left a[m]
L12726:  a exchange c[w]
         m1 exchange c
         m1 -> c
         0 -> c[ms]
         a exchange c[s]
         m1 exchange c
         delayed rom @06
         jsb S13325
         go to L12662

L12737:  c + 1 -> c[x]
         shift right b[w]
         binary
         a + 1 -> a[s]
         decimal
         p - 1 -> p
         if p # 2
           then go to L12365
         m1 -> c
         go to L12655

L12751:  0 -> c[wp]
         a exchange c[x]
         b exchange c[w]
         0 -> c[w]
         a exchange c[s]
         c - 1 -> c[x]
S12757:  delayed rom @06
         go to S13076

L12761:  a exchange c[w]
         m1 -> c
         go to S12757

L12764:  if 0 = s 9
           then go to L13767
         if a[m] # 0
           then go to L13120
L12770:  delayed rom @00
         go to L00233

S12772:  b exchange c[w]
         0 -> b[m]
         0 -> c[w]
         p <- 12
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
L13013:  p <- 12
         return

S13015:  0 -> a[w]
         a exchange c[m]
L13017:  delayed rom @05
         jsb S12772
         b exchange c[w]
         go to L13247

         0 -> a[w]
         a exchange c[m]
         1 -> s 7
         1 -> s 14
S13027:  if c[s] # 0
           then go to L13767
         0 -> a[s]
         a -> b[w]
         b exchange c[w]
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
           then go to L13052
         shift right b[w]
L13052:  shift right c[w]
         a exchange c[x]
         0 -> c[w]
         a exchange b[w]
         p <- 13
         load constant 5
         shift right c[w]
         go to L13070

L13062:  c + 1 -> c[p]
L13063:  a - c -> a[w]
         if n/c go to L13062
         a + c -> a[w]
         shift left a[w]
         p - 1 -> p
L13070:  shift right c[wp]
         if p # 0
           then go to L13063
         0 -> c[p]
         a exchange c[w]
         b exchange c[w]
S13076:  p <- 12
         if a[wp] # 0
           then go to L12112
         0 -> c[s]
         0 -> c[x]
         go to L13336

L13104:  c + 1 -> c[s]
S13105:  a - b -> a[w]
         if n/c go to L13104
         a + b -> a[w]
         shift left a[w]
         shift right c[ms]
         b exchange c[w]
         p - 1 -> p
L13114:  return

         jsb S13015
         delayed rom @03
         go to L01531

L13120:  if a[s] # 0
           then go to L13767
         0 -> a[w]
         0 -> c[w]
         go to L13202

L13125:  b exchange c[w]
         m2 -> c
         delayed rom @07
         jsb S13430
         a exchange b[w]
         m1 -> c
         go to L13017

L13134:  p <- 11
         load constant 6
         load constant 9
         load constant 3
         load constant 1
         load constant 4
         load constant 7
         load constant 1
         load constant 8
         load constant 0
         load constant 5
         load constant 6
         go to L13013

L13151:  shift right a[wp]
L13152:  a - 1 -> a[s]
         if n/c go to L13151
         0 -> a[s]
         a + b -> a[w]
         a + 1 -> a[p]
         if n/c go to L13163
         shift right a[wp]
         a + 1 -> a[p]
         if n/c go to L13166
L13163:  a -> b[w]
         c - 1 -> c[s]
         if n/c go to L13152
L13166:  shift right a[wp]
         a exchange c[w]
         shift left a[ms]
         a exchange c[w]
         a - 1 -> a[s]
         if n/c go to L13163
         a exchange b[w]
         a + 1 -> a[p]
         if 0 = s 4
           then go to L13201
         0 - c - 1 -> c[s]
L13201:  jsb S13076
L13202:  if 0 = s 12
           then go to S13340
         delayed rom @10
         go to L14261

L13206:  0 - c -> c[w]
         c -> a[s]
         if a >= b[x]
           then go to L13222
         m1 exchange c
         a exchange c[w]
         shift left a[w]
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         a - 1 -> a[x]
         a exchange b[w]
L13222:  if a >= b[x]
           then go to L13234
         a + 1 -> a[x]
         shift right c[w]
         a exchange c[s]
         c -> a[s]
         p - 1 -> p
         if p # 13
           then go to L13222
         0 -> a[w]
L13234:  a exchange c[w]
         m1 -> c
         b exchange c[w]
         a + b -> a[w]
         c - 1 -> c[xs]
         c - 1 -> c[xs]
L13242:  if a[s] # 0
           then go to L13334
         go to S13076

L13245:  c + 1 -> c[x]
         shift right a[w]
L13247:  if c[xs] = 0
           then go to L12356
         if a[s] # 0
           then go to L13245
         0 - c -> c[x]
         if c[xs] = 0
           then go to L13300
         0 -> c[m]
         0 -> a[w]
         c + c -> c[x]
         if n/c go to L13302
L13262:  0 -> c[wp]
         0 -> a[w]
         if c[s] # 0
           then go to L13273
         c - 1 -> c[w]
         a - 1 -> a[wp]
         0 -> c[xs]
         if s 4 = 1
           then go to L13274
L13273:  0 -> c[s]
L13274:  p <- 13
         go to L13202

         nop

L13277:  shift right a[w]
L13300:  c - 1 -> c[x]
         if n/c go to L13277
L13302:  0 -> c[x]
L13303:  if c[s] = 0
           then go to L13310
         a exchange b[w]
         a - b -> a[w]
         0 - c - 1 -> c[x]
L13310:  0 -> c[ms]
         b exchange c[w]
L13312:  jsb S13354
         b exchange c[w]
         jsb S13105
         if p # 5
           then go to L13312
         p <- 13
         load constant 7
         a exchange c[s]
         b exchange c[w]
         go to L13166

L13324:  a + b -> a[w]
S13325:  c - 1 -> c[p]
         if n/c go to L13324
         if p # 12
           then go to L13450
         a -> b[w]
         m1 -> c
         go to L13242

L13334:  c + 1 -> c[x]
         shift right a[w]
L13336:  if 0 = s 7
           then go to L13352
S13340:  p <- 12
         a exchange c[wp]
         c + c -> c[x]
         if n/c go to L13350
         c + 1 -> c[m]
         if n/c go to L13350
         c + 1 -> c[p]
         a + 1 -> a[x]
L13350:  a exchange c[x]
         c -> a[w]
L13352:  delayed rom @04
         go to L12062

S13354:  0 -> c[w]
         if p = 12
           then go to L13134
         c - 1 -> c[w]
         load constant 4
         c + 1 -> c[w]
         0 -> c[s]
         shift right c[w]
         if p = 10
           then go to L12000
         if p = 9
           then go to L12320
         if p = 8
           then go to L12030
         if p = 7
           then go to L12131
         if p = 6
           then go to L12303
         p + 1 -> p
         return

L13400:  jsb S13425
L13401:  go to S13422

L13402:  go to S13556

L13403:  go to L13563

L13404:  go to S13435

L13405:  go to L13507

L13406:  go to S13502

L13407:  go to S13541

L13410:  go to L13615

L13411:  go to S13456

L13412:  go to S13463

L13413:  go to L13651

L13414:  go to L13771

L13415:  go to S13621

L13416:  go to L13627

S13417:  go to L13635

L13420:  go to L13641

L13421:  go to S13645

S13422:  delayed rom @06
         go to S13340

         1 -> s 14
S13425:  0 -> b[w]
         a exchange b[s]
         a exchange b[x]
S13430:  m1 exchange c
         m1 -> c
         0 -> c[x]
         go to S13435

         1 -> s 14
S13435:  a exchange b[w]
         m1 exchange c
         a + c -> c[x]
         a - c -> c[s]
         if n/c go to L13443
         0 - c -> c[s]
L13443:  0 -> a[w]
         m1 exchange c
         0 -> c[s]
         0 -> b[s]
         p <- 13
L13450:  p + 1 -> p
         shift right a[w]
         delayed rom @06
         go to S13325

S13454:  jsb S13471
         go to S13422

S13456:  0 -> a[w]
         p <- 12
         a + 1 -> a[p]
         0 -> b[w]
         return

S13463:  0 -> c[w]
         p <- 1
         load constant 3
L13466:  c -> data address
         return

         1 -> s 14
S13471:  if c[m] = 0
           then go to L12770
         0 -> b[w]
         a exchange b[s]
         a exchange b[x]
         m1 exchange c
         m1 -> c
         0 -> c[x]
         go to L13511

S13502:  0 -> a[w]
         a exchange c[m]
         b exchange c[w]
         return

         1 -> s 14
L13507:  if c[m] = 0
           then go to L12770
L13511:  m1 exchange c
         a exchange b[w]
         a - c -> c[s]
         if n/c go to L13516
         0 - c -> c[s]
L13516:  a - c -> c[x]
         0 -> a[w]
         a exchange b[w]
         m1 exchange c
         b exchange c[w]
S13523:  0 -> c[w]
         0 -> a[s]
         0 -> b[s]
         p <- 12
         go to L13531

L13530:  c + 1 -> c[p]
L13531:  a - b -> a[w]
         if n/c go to L13530
         a + b -> a[w]
         if p = 0
           then go to L12761
         shift left a[w]
         p - 1 -> p
         go to L13531

S13541:  m1 exchange c
         m1 -> c
         0 -> c[x]
         return

         1 -> s 14
S13546:  m1 exchange c
         m1 -> c
         0 - c - 1 -> c[s]
L13551:  0 -> b[w]
         a exchange b[m]
         a exchange b[w]
         m1 exchange c
         0 -> c[x]
S13556:  0 -> c[s]
         m1 exchange c
         go to L13566

         nop

         1 -> s 14
L13563:  0 -> c[s]
         m1 exchange c
         0 - c - 1 -> c[s]
L13566:  0 -> a[s]
         a exchange b[w]
         p <- 12
         a + 1 -> a[xs]
         a + 1 -> a[xs]
         c + 1 -> c[xs]
         c + 1 -> c[xs]
         b exchange c[w]
         if c[w] = 0
           then go to L13234
         m1 exchange c
         a exchange b[w]
         if c[w] = 0
           then go to L13234
L13604:  if a >= b[x]
           then go to L13677
L13606:  a - b -> a[s]
         if a[s] # 0
           then go to L13206
         delayed rom @06
         go to L13222

L13613:  jsb S13546
         go to S13422

L13615:  0 -> c[w]
         p <- 12
         c + 1 -> c[p]
         return

S13621:  a exchange c[w]
         c -> a[w]
         c -> register 13
         b -> c[w]
         c -> register 12
         return

L13627:  a exchange c[w]
         c -> a[w]
         c -> register 15
         b -> c[w]
         c -> register 14
         return

L13635:  register -> c 10
         m1 exchange c
         register -> c 11
         return

L13641:  register -> c 12
         m1 exchange c
         register -> c 13
         return

S13645:  register -> c 14
         m1 exchange c
         register -> c 15
         return

L13651:  0 -> c[w]
         p <- 1
         load constant 1
         go to L13466

         1 -> s 14
S13656:  m1 exchange c
         m1 -> c
         go to L13551

L13661:  a exchange c[w]
         m1 exchange c
         if a >= c[w]
           then go to L13670
         m1 exchange c
         a exchange c[w]
         go to L13606

L13670:  m1 exchange c
         a exchange c[w]
         m1 exchange c
         a exchange b[w]
         go to L13606

L13675:  jsb S13656
         go to S13422

L13677:  m1 exchange c
         a exchange b[w]
         if a >= b[x]
           then go to L13661
         go to L13604

S13704:  delayed rom @10
         jsb S14062
         m2 exchange c
         c -> register 11
         return

         jsb S13704
         delayed rom @10
         jsb S14172
         jsb S13456
         jsb S13621
         register -> c 7
         c -> register 9
         0 -> c[w]
         c -> register 8
         register -> c 15
         jsb S13502
         delayed rom @13
         jsb S15762
         0 -> s 2
         1 -> s 11
         1 -> s 13
         delayed rom @13
         go to L15453

L13733:  delayed rom @13
         jsb S15762
         jsb S13463
         data -> c
         jsb S13541
         jsb S13435
         b exchange c[w]
         jsb S13645
         jsb S13556
         jsb S13422
         delayed rom @05
         jsb S12411
         c -> register 2
         delayed rom @13
         jsb S15752
         delayed rom @13
         jsb S15762
         jsb S13463
         data -> c
         jsb S13541
         jsb S13435
         jsb S13422
         m2 exchange c
         register -> c 2
         delayed rom @02
         go to L01363

L13765:  if a[x] # 0
           then go to L12511
L13767:  delayed rom @00
         go to L00233

L13771:  a exchange c[w]
         c -> a[w]
         c -> register 11
         b -> c[w]
         c -> register 10
         return

         nop

S14000:  select rom go to L13401

S14001:  select rom go to L13402

S14002:  select rom go to L13403

S14003:  select rom go to L13404

S14004:  select rom go to L13405

S14005:  select rom go to L13406

S14006:  select rom go to L13407

S14007:  select rom go to L13410

S14010:  select rom go to L13411

S14011:  select rom go to L13412

S14012:  select rom go to L13413

S14013:  select rom go to L13414

S14014:  select rom go to L13415

S14015:  select rom go to L13416

S14016:  select rom go to S13417

S14017:  select rom go to L13420

S14020:  select rom go to L13421

         jsb S14172
         jsb S14201
         jsb S14011
         register -> c 4
         jsb S14006
         jsb S14003
         b exchange c[w]
         if 0 = s 10
           then go to L14033
         jsb S14151
L14033:  jsb S14015
         jsb S14011
         data -> c
         jsb S14005
         jsb S14012
         jsb S14017
         jsb S14003
         b exchange c[w]
         jsb S14011
         jsb S14020
         jsb S14001
         c -> register 2
L14047:  0 - c - 1 -> c[s]
L14050:  jsb S14000
         delayed rom @05
         jsb S12411
         c -> data
         m2 exchange c
         m2 -> c
         if 0 = s 11
           then go to L14762
         delayed rom @01
         go to L00756

S14062:  0 -> c[w]
         p <- 1
         load constant 2
         c -> data address
         return

         jsb S14172
         jsb S14201
         jsb S14011
         if 0 = s 10
           then go to L14075
         jsb S14151
L14075:  jsb S14015
         jsb S14011
         data -> c
         jsb S14005
         jsb S14012
         jsb S14017
         jsb S14003
         b exchange c[w]
         jsb S14011
         register -> c 2
         jsb S14006
         jsb S14001
         b exchange c[w]
         jsb S14020
         jsb S14004
         c -> register 4
         go to L14047

         nop

         jsb S14172
         0 -> s 1
         0 -> s 2
         jsb S14203
         jsb S14011
         if 0 = s 10
           then go to L14127
         jsb S14151
L14127:  register -> c 4
         jsb S14006
         jsb S14003
         b exchange c[w]
         jsb S14015
         register -> c 2
         jsb S14005
         jsb S14012
         jsb S14017
         jsb S14003
         b exchange c[w]
         jsb S14011
         jsb S14020
         jsb S14001
         c -> register 0
         go to L14047

S14147:  delayed rom @12
         go to S15347

S14151:  jsb S14013
         jsb S14010
         register -> c 15
         jsb S14006
         jsb S14001
         b exchange c[w]
         jsb S14016
         jsb S14003
         go to L14276

L14162:  jsb S14010
         jsb S14014
L14164:  m2 -> c
         if 0 = s 1
           then go to L14170
         0 - c - 1 -> c[s]
L14170:  jsb S14005
         return

S14172:  jsb S14011
         0 -> s 11
         register -> c 1
         c - 1 -> c[x]
         c - 1 -> c[x]
         c -> register 15
         return

S14201:  0 -> s 2
S14202:  1 -> s 1
S14203:  jsb S14005
S14204:  jsb S14012
         jsb S14015
         jsb S14007
         jsb S14006
         c - 1 -> c[wp]
         jsb S14001
         jsb S14374
         jsb S14011
         register -> c 3
         if 0 = s 2
           then go to L14224
         jsb S14005
         jsb S14007
         jsb S14006
         jsb S14002
         jsb S14000
L14224:  if 0 = s 1
           then go to L14227
         0 - c - 1 -> c[s]
L14227:  m2 exchange c
         jsb S14012
         jsb S14020
         if c[m] = 0
           then go to L14162
         a exchange c[w]
         m1 exchange c
         delayed rom @12
         jsb S15347
         1 -> s 12
         delayed rom @05
         go to L12536

L14243:  b exchange c[w]
         jsb S14062
         jsb S14015
S14246:  jsb S14012
         m2 -> c
         jsb S14006
         jsb S14003
         b exchange c[w]
         jsb S14013
         b exchange c[w]
         0 -> s 14
         1 -> s 12
         delayed rom @06
         go to L13017

L14261:  b exchange c[w]
         jsb S14014
         jsb S14062
         jsb S14014
         jsb S14012
         if a[m] # 0
           then go to L14300
         jsb S14010
L14271:  jsb S14020
         jsb S14004
         if s 1 = 1
           then go to L14276
         0 - c - 1 -> c[s]
L14276:  b exchange c[w]
         return

L14300:  if p = 13
           then go to L15253
         jsb S14010
         jsb S14017
         jsb S14002
         if a[m] # 0
           then go to L14325
         go to L14164

L14310:  b exchange c[w]
         jsb S14016
         jsb S14004
         b exchange c[w]
         jsb S14013
         jsb S14010
         jsb S14017
         jsb S14002
         b exchange c[w]
         jsb S14016
         jsb S14004
         b exchange c[w]
         go to L14271

L14325:  b exchange c[w]
         b -> c[w]
         c + 1 -> c[x]
         if c[xs] = 0
           then go to L14271
         jsb S14017
         a exchange c[w]
         m1 exchange c
         jsb S14147
         1 -> s 2
         delayed rom @05
         go to L12554

L14341:  jsb S14246
         jsb S14062
         jsb S14015
         register -> c 11
         jsb S14006
         jsb S14003
         b exchange c[w]
         jsb S14014
         delayed rom @13
         jsb S15752
         jsb S14020
         jsb S14002
         b exchange c[w]
         jsb S14012
         jsb S14020
         jsb S14004
         b exchange c[w]
         jsb S14062
         jsb S14017
         jsb S14002
         b exchange c[w]
         delayed rom @13
         go to L15530

S14370:  jsb S14010
         jsb S14006
         c + 1 -> c[x]
         jsb S14001
S14374:  if c[s] # 0
           then go to L15253
         display toggle
         return

S14400:  select rom go to L13401

S14401:  select rom go to L13402

S14402:  select rom go to L13403

S14403:  select rom go to L13404

S14404:  select rom go to L13405

S14405:  select rom go to L13406

S14406:  select rom go to L13407

S14407:  select rom go to L13410

S14410:  select rom go to L13411

S14411:  select rom go to L13412

S14412:  delayed rom @07
         go to L13613

S14414:  1 -> s 1
         0 -> s 3
         m2 exchange c
         jsb S14411
         m2 exchange c
         c -> register 10
         register -> c 8
         m2 exchange c
         register -> c 9
         c -> register 11
         if 0 = s 2
           then go to L14526
         jsb S14410
         jsb S14407
         a + c -> a[w]
         register -> c 3
         jsb S14406
         jsb S14404
         b exchange c[w]
         data -> c
         jsb S14406
         jsb S14401
         b exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 3
         jsb S14406
         jsb S14402
         b exchange c[w]
         0 -> c[w]
         p <- 12
         load constant 6
         jsb S14406
         jsb S14404
         b exchange c[w]
         jsb S14765
         jsb S14406
         jsb S14403
         jsb S14400
         c -> register 10
         jsb S14405
         register -> c 8
         jsb S14406
         jsb S14401
         jsb S14400
         m2 exchange c
         register -> c 9
         jsb S14405
         register -> c 10
         jsb S14406
         jsb S14401
         jsb S14400
         c -> register 11
         jsb S14410
         register -> c 3
         jsb S14406
         jsb S14404
         b exchange c[w]
         register -> c 3
         jsb S14406
         jsb S14402
         b exchange c[w]
         0 -> c[w]
         m1 exchange c
         0 -> c[w]
         p <- 12
         load constant 3
         jsb S14404
         b exchange c[w]
         jsb S14765
         jsb S14406
         jsb S14403
         jsb S14400
         c -> register 10
L14526:  m2 -> c
         if c[m] # 0
           then go to L14561
         register -> c 11
         if c[m] # 0
           then go to L14535
L14534:  return

L14535:  jsb S14405
         a exchange b[s]
         register -> c 10
         if c[m] = 0
           then go to L14534
         a - c -> c[s]
         if c[s] # 0
           then go to L14534
         a exchange b[s]
         register -> c 10
         jsb S14406
         jsb S14404
         b exchange c[w]
         jsb S14407
         c + c -> c[w]
         jsb S14406
         jsb S14404
         1 -> s 3
         0 -> s 1
         go to L14663

L14561:  register -> c 11
         if c[w] # 0
           then go to L14606
         register -> c 10
         c -> a[w]
         m2 -> c
         a - c -> c[s]
         if c[s] # 0
           then go to L14534
         jsb S14407
         c + c -> c[w]
         jsb S14405
         register -> c 10
         jsb S14406
         jsb S14403
         b exchange c[w]
         m2 -> c
         jsb S14406
         jsb S14404
         0 -> s 1
         go to L14663

L14606:  jsb S14405
         m2 -> c
         jsb S14406
         jsb S14403
         if c[s] = 0
           then go to L14663
         0 -> s 1
         jsb S14400
         c -> register 14
         register -> c 10
         jsb S14405
         register -> c 10
         jsb S14406
         jsb S14403
         b exchange c[w]
         register -> c 14
         jsb S14406
         jsb S14402
         delayed rom @06
         jsb S13027
         b exchange c[w]
         register -> c 10
         b exchange c[s]
         register -> c 10
         jsb S14406
         jsb S14401
         b exchange c[w]
         m2 -> c
         a exchange c[w]
         a - b -> a[s]
         a exchange c[w]
         if c[s] = 0
           then go to L14660
         register -> c 11
         jsb S14406
         a exchange c[w]
         m1 exchange c
         b exchange c[w]
         m1 exchange c
         jsb S14404
         1 -> s 3
         go to L14663

L14660:  m2 -> c
         jsb S14406
         jsb S14404
L14663:  go to S14400

L14664:  m2 exchange c
         jsb S14731
         c -> register 12
         register -> c 8
         a exchange c[w]
         jsb S14765
         jsb S14412
         register -> c 8
         delayed rom @07
         jsb S13454
         c -> register 13
         1 -> s 2
         jsb S14414
         if s 1 = 1
           then go to L14714
         jsb S14731
         c -> register 14
         register -> c 13
         jsb S14412
         if c[s] = 0
           then go to L14714
         register -> c 14
         c -> register 12
         go to L14727

L14714:  register -> c 12
         a exchange c[w]
         register -> c 13
         jsb S14412
         if c[s] = 0
           then go to L15425
         register -> c 13
         go to L14726

L14724:  m2 exchange c
         jsb S14731
L14726:  c -> register 12
L14727:  delayed rom @13
         go to L15425

S14731:  m2 exchange c
         jsb S14407
         c + c -> c[w]
         jsb S14405
         jsb S14411
         register -> c 3
         jsb S14406
         jsb S14404
         jsb S14400
         m2 exchange c
         delayed rom @12
         jsb S15347
         1 -> s 9
         delayed rom @05
         go to S12476

L14750:  jsb S14411
         register -> c 3
         jsb S14405
         delayed rom @13
         jsb S15762
         delayed rom @07
         jsb S13417
         jsb S14403
         delayed rom @13
         go to L15605

L14762:  1 -> s 4
         delayed rom @03
         go to L01434

S14765:  delayed rom @12
         go to S15366

         delayed rom @07
         jsb S13704
         1 -> s 11
         delayed rom @12
         go to L15143

L14774:  register -> c 13
         c -> register 12
         go to L14727

         nop

S15000:  select rom go to L13401

S15001:  select rom go to L13402

         select rom go to L13403

S15003:  select rom go to L13404

S15004:  select rom go to L13405

S15005:  select rom go to L13406

S15006:  select rom go to L13407

S15007:  select rom go to L13410

S15010:  select rom go to L13411

S15011:  select rom go to L13412

S15012:  b exchange c[w]
         select rom go to L13414

S15014:  select rom go to L13415

         select rom go to L13416

S15016:  select rom go to S13417

S15017:  select rom go to L13420

S15020:  delayed rom @07
         go to L13613

S15022:  delayed rom @07
         go to L13400

S15024:  delayed rom @07
         go to L13675

S15026:  delayed rom @07
         go to S13454

S15030:  delayed rom @11
         go to S14414

         delayed rom @10
         jsb S14172
         0 -> s 1
         delayed rom @10
         jsb S14370
         register -> c 2
L15040:  jsb S15005
         if 0 = s 10
           then go to L15047
         register -> c 4
         jsb S15006
         jsb S15001
         b exchange c[w]
L15047:  register -> c 15
         jsb S15006
         jsb S15003
         b exchange c[w]
         register -> c 4
         jsb S15006
         jsb S15001
         jsb S15012
         register -> c 2
         jsb S15005
         jsb S15011
         data -> c
         jsb S15006
         jsb S15001
         b exchange c[w]
         jsb S15016
         jsb S15004
         jsb S15012
         register -> c 15
         if c[m] # 0
           then go to L15101
         b exchange c[w]
L15075:  0 - c - 1 -> c[s]
L15076:  c -> register 3
         delayed rom @10
         go to L14050

L15101:  jsb S15006
         jsb S15003
         if s 1 = 1
           then go to L15106
         0 - c - 1 -> c[s]
L15106:  if c[s] = 0
           then go to L15117
         if s 1 = 1
           then go to L15253
         jsb S15011
         data -> c
         0 - c - 1 -> c[s]
         1 -> s 1
         go to L15040

L15117:  jsb S15012
         register -> c 15
         jsb S15005
         b exchange c[w]
         jsb S15347
         jsb S15345
         b exchange c[w]
         jsb S15014
         jsb S15016
         a exchange c[w]
         m1 exchange c
         jsb S15347
         jsb S15345
         b exchange c[w]
         jsb S15017
         jsb S15004
         if 0 = s 1
           then go to L15076
         go to L15075

         0 -> s 11
L15143:  jsb S15010
         jsb S15007
         c - 1 -> c[x]
         jsb S15020
         jsb S15011
         register -> c 3
         jsb S15020
         if c[s] = 0
           then go to L15253
         jsb S15010
         jsb S15014
         register -> c 2
         c -> register 8
         jsb S15011
         data -> c
         c -> register 9
         register -> c 4
         if 0 = s 11
           then go to L15176
         register -> c 2
         0 - c - 1 -> c[s]
         c -> register 8
         register -> c 9
         a exchange c[w]
         register -> c 7
         c -> register 9
         jsb S15355
L15176:  jsb S15361
         a exchange c[w]
         register -> c 3
         jsb S15022
         register -> c 8
         jsb S15024
         register -> c 9
         jsb S15024
         if c[m] = 0
           then go to L15723
         m2 exchange c
         jsb S15366
         a exchange c[w]
         register -> c 8
         if 0 = s 10
           then go to L15217
         jsb S15024
L15217:  c -> register 8
         register -> c 9
         if s 10 = 1
           then go to L15224
         jsb S15024
L15224:  c -> register 9
         a exchange c[w]
         register -> c 8
         jsb S15020
         m2 exchange c
         jsb S15026
         0 -> s 13
         if c[s] = 0
           then go to L15240
         delayed rom @13
         jsb S15767
         1 -> s 13
L15240:  jsb S15010
         register -> c 3
         jsb S15020
         jsb S15366
         jsb S15022
         jsb S15355
         0 -> s 2
         jsb S15030
         m2 exchange c
         if 0 = s 1
           then go to L15255
L15253:  delayed rom @00
         go to L00233

L15255:  jsb S15366
         if c[m] = 0
           then go to L14724
         if 0 = s 3
           then go to L14664
         m2 exchange c
         c -> register 12
         1 -> s 2
         jsb S15030
         if s 1 = 1
           then go to L15271
         c -> register 12
L15271:  register -> c 12
         delayed rom @11
         jsb S14731
         c -> register 13
         jsb S15007
         jsb S15020
         c -> register 15
         1 -> s 2
         delayed rom @10
         jsb S14202
         b exchange c[w]
         jsb S15000
         jsb S15011
         register -> c 12
         jsb S15022
         jsb S15355
         jsb S15366
         jsb S15022
         0 - c - 1 -> c[s]
         c -> register 10
         0 -> s 2
         jsb S15030
         register -> c 12
         jsb S15022
         register -> c 13
         jsb S15026
         c -> register 14
         register -> c 3
         a exchange c[w]
         jsb S15007
         jsb S15020
         if c[m] = 0
           then go to L14774
         jsb S15010
         jsb S15026
         m2 exchange c
         register -> c 14
         jsb S15347
         1 -> s 9
         delayed rom @05
         jsb S12476
         c -> register 12
         delayed rom @13
         go to L15425

S15345:  delayed rom @05
         go to L12536

S15347:  0 -> s 2
         0 -> s 12
         0 -> s 9
         0 -> s 4
         0 -> s 8
         return

S15355:  jsb S15007
         c + c -> c[w]
         display toggle
         go to S15026

S15361:  m1 exchange c
         0 -> c[w]
         c -> data address
         m1 -> c
         c -> register 12
S15366:  0 -> c[w]
         c -> data address
         register -> c 12
         m1 exchange c
         0 -> c[w]
         p <- 1
         load constant 3
         c -> data address
         m1 exchange c
         return

S15400:  select rom go to L13401

S15401:  select rom go to L13402

S15402:  select rom go to L13403

S15403:  select rom go to L13404

S15404:  select rom go to L13405

S15405:  select rom go to L13406

S15406:  select rom go to L13407

S15407:  select rom go to L13410

S15410:  select rom go to L13411

S15411:  select rom go to L13412

S15412:  select rom go to L13413

S15413:  select rom go to L13414

S15414:  select rom go to L13415

S15415:  select rom go to L13416

S15416:  select rom go to S13417

S15417:  select rom go to L13420

S15420:  select rom go to L13421

S15421:  delayed rom @10
         go to S14062

S15423:  delayed rom @12
         go to S15366

L15425:  jsb S15411
         if 0 = s 11
           then go to L15442
         if 0 = s 13
           then go to L15442
         jsb S15410
         register -> c 12
         delayed rom @07
         jsb S13454
         c -> register 12
         jsb S15767
         0 -> s 13
         1 -> s 3
L15442:  register -> c 12
         jsb S15405
         jsb S15414
L15445:  jsb S15410
         jsb S15417
         jsb S15402
         0 - c - 1 -> c[s]
         b exchange c[w]
         1 -> s 2
L15453:  1 -> s 1
         delayed rom @10
         jsb S14204
         jsb S15411
         display toggle
         jsb S15413
         register -> c 9
         jsb S15405
         jsb S15412
         jsb S15417
         jsb S15403
         b exchange c[w]
         jsb S15411
         jsb S15417
         jsb S15404
         b exchange c[w]
         register -> c 8
         jsb S15406
         jsb S15401
         b exchange c[w]
         jsb S15415
         if 0 = s 11
           then go to L15550
         jsb S15412
         jsb S15420
         if c[m] = 0
           then go to L15521
         jsb S15752
         b exchange c[w]
         jsb S15400
         m2 exchange c
         jsb S15420
         a exchange c[w]
         m1 exchange c
         b exchange c[w]
         0 -> s 1
         if 0 = s 1
           then go to L14341
L15521:  jsb S15752
         jsb S15415
         register -> c 11
         0 - c - 1 -> c[s]
         jsb S15406
         jsb S15403
         jsb S15761
L15530:  jsb S15414
         jsb S15752
         jsb S15420
         jsb S15402
         0 - c - 1 -> c[s]
         b exchange c[w]
         jsb S15415
         jsb S15411
         jsb S15416
         jsb S15401
         b exchange c[w]
         jsb S15413
         if 0 = s 13
           then go to L15550
         delayed rom @07
         go to L13733

L15550:  jsb S15423
         jsb S15405
         jsb S15416
         jsb S15403
         b exchange c[w]
         jsb S15420
         jsb S15401
         b exchange c[w]
         if a[m] # 0
           then go to L15563
         go to L15723

L15563:  jsb S15415
         register -> c 3
         jsb S15405
         jsb S15407
         jsb S15406
         jsb S15402
         b exchange c[w]
         jsb S15412
         jsb S15414
         jsb S15411
         jsb S15416
         jsb S15402
         b exchange c[w]
         jsb S15412
         jsb S15420
         if c[m] = 0
           then go to L14750
         jsb S15404
L15605:  b exchange c[w]
         jsb S15411
         if 0 = s 11
           then go to L15627
         jsb S15413
         register -> c 3
         jsb S15405
         jsb S15421
         jsb S15420
         jsb S15403
         b exchange c[w]
         jsb S15417
         jsb S15401
         b exchange c[w]
         jsb S15411
         jsb S15416
         jsb S15401
         b exchange c[w]
L15627:  jsb S15423
         jsb S15406
         jsb S15403
         b exchange c[w]
         jsb S15412
         jsb S15413
         jsb S15411
         register -> c 3
         jsb S15405
         register -> c 8
         jsb S15406
         jsb S15403
         b exchange c[w]
         jsb S15412
         jsb S15416
         jsb S15401
         b exchange c[w]
         jsb S15411
         jsb S15420
         jsb S15404
         if s 3 = 1
           then go to L15661
         b exchange c[w]
         jsb S15412
         jsb S15417
         jsb S15402
L15661:  m1 exchange c
         a exchange c[w]
         jsb S15410
         jsb S15404
         m1 exchange c
         a exchange c[w]
         jsb S15410
         jsb S15402
         b exchange c[w]
         jsb S15411
         jsb S15417
         jsb S15403
         b exchange c[w]
         jsb S15413
         jsb S15417
         jsb S15402
         b exchange c[w]
         jsb S15417
         jsb S15404
         0 -> c[s]
         b exchange c[w]
         register -> c 10
         c -> register 12
         register -> c 11
         c -> register 13
         0 -> c[w]
         p <- 2
         load constant 9
         load constant 9
         m1 exchange c
         jsb S15407
         jsb S15402
         if c[s] = 0
           then go to L15445
L15723:  if 0 = s 13
           then go to L15732
         jsb S15410
         jsb S15417
         jsb S15404
         b exchange c[w]
         jsb S15414
L15732:  jsb S15410
         jsb S15417
         jsb S15402
         0 - c - 1 -> c[s]
         if 0 = s 11
           then go to L15745
         b exchange c[w]
         jsb S15407
         c + c -> c[w]
         jsb S15406
         jsb S15403
L15745:  c -> register 1
         c + 1 -> c[x]
         c + 1 -> c[x]
         delayed rom @10
         go to L14050

S15752:  jsb S15421
         jsb S15410
         register -> c 11
         jsb S15406
         jsb S15402
L15757:  b exchange c[w]
         return

S15761:  b exchange c[w]
S15762:  jsb S15407
         c + c -> c[w]
         jsb S15406
         jsb S15404
         go to L15757

S15767:  register -> c 8
         a exchange c[w]
         register -> c 9
         c -> register 8
         a exchange c[w]
         c -> register 9
         return

         nop
         nop

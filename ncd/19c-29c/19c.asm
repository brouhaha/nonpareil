; 19c ROM disassembly - model specific code, @0000-@1777
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

; External references
S2000	.equ	@2000
S2235	.equ	@2235
S2363	.equ	@2363
S2436	.equ	@2436
L2625	.equ	@2625
L2632	.equ	@2632
S2741	.equ	@2741
S2773	.equ	@2773
incpc0	.equ	@3006
L3347	.equ	@3347
S3760	.equ	@3760
L5605	.equ	@5605
L5662	.equ	@5662
L6021	.equ	@6021
L6303	.equ	@6303
L7201	.equ	@7201
L7253	.equ	@7253
L7316	.equ	@7316
L7352	.equ	@7352
S7761	.equ	@7761

L16335	.equ	@6335
S16740	.equ	@6740
L17571	.equ	@7571

; Misc. Entry points:
;
;	L0004 - cold start
;	incpc
;	incpc9

	.bank 0
	.org @0000

        reset twf
        0 -> s 0
        delayed rom @14
        go to L6303

L0004:  delayed rom @02
        go to L1103

S0006:  c -> a[x]
        c -> data address
        data -> c
        a exchange c[w]
L0012:  rotate left a
        rotate left a
        c - 1 -> c[xs]
        if n/c go to L0012
        return

incpc:  delayed rom @06
        go to incpc0

incpc9: m2 exchange c
        m2 -> c
        return

L0024:  1 -> s 1
        m2 -> c
        1 -> s 0
        if c[x] = 0
          then go to L0034
        0 -> s 3
        if 1 = s 3
          then go to L0035
L0034:  jsb incpc
L0035:  delayed rom @02
        jsb S1140
        go to L0266

L0040:  if 1 = s 2
          then go to L0053
        if 1 = s 1
          then go to L0061
        go to L0372

L0045:  1 -> s 2
        m2 -> c
        if c[x] # 0
          then go to L0052
        jsb incpc
L0052:  go to L0035

L0053:  0 -> s 2
        jsb incpc
L0055:  1 -> s 9
L0056:  jsb S0257
        0 -> s 12
        go to L0115

L0061:  1 -> s 9
L0062:  0 -> s 12
L0063:  jsb S0257
        go to L0114

L0065:  0 -> s 9
        go to L0073

L0067:  b exchange c[w]
L0070:  1 -> s 9
        delayed rom @05
        jsb S2436
L0073:  b exchange c[w]
        if 0 = s 11
          then go to L0101
        jsb S0252
        0 -> s 2
        0 -> s 1
L0101:  0 -> s 12
        jsb S0257
        c -> a[w]
        c -> register 15
        p <- 1
        load constant 1
        c -> data address
        b -> c[w]
        c -> register 15
        a -> b[w]
        go to L0235

L0114:  jsb S0252
L0115:  0 -> s 0
        binary
        delayed rom @02
        jsb S1141
        b -> c[w]
        if 1 = s 2
          then go to L0204
        0 -> s 1
L0125:  0 -> s 11
        0 -> c[s]
        m1 exchange c
        0 -> s 3
        1 -> s 0
        b -> c[w]
        if 0 = s 3
          then go to L0265
        if 0 = s 12
          then go to L0142
        delayed rom @07
        jsb S3760
        go to L0144

L0142:  delayed rom @04
        jsb S2000
L0144:  delayed rom @02
        jsb S1371
L0146:  hi i'm woodstock
        display off
        display toggle
L0151:  1 -> s 0
        0 -> s 1
        0 -> s 3
        if 0 = s 3
          then go to L0163
        if 0 = s 11
          then go to L0165
        0 -> s 11
        b exchange c[w]
        go to L0062

L0163:  if 0 = s 11
          then go to L0265
L0165:  0 -> s 0
        0 -> s 5
        if 1 = s 5
          then go to L0173
        jsb S0375
        jsb S0375
L0173:  0 -> s 3
        pick key?
        if 0 = s 3
          then go to L0151
        display off
        b exchange c[w]
        jsb S0227
        delayed rom @16
        go to L7352

L0204:  0 -> s 3
        if 1 = s 12
          then go to L0212
        pick key?
        if 1 = s 3
          then go to L0224
L0212:  m2 -> c
        jsb S0006
        display toggle
L0215:  a exchange c[w]
        m1 exchange c
        delayed rom @05
        jsb S2773
        delayed rom @03
        go to L1647

L0223:  jsb S0252
L0224:  jsb S0227
        0 -> s 2
        go to L0056

S0227:  0 -> c[x]
        binary
        c - 1 -> c[x]
        c -> data address
        register -> c 15
        return

L0235:  a -> b[w]
        0 -> s 14
        delayed rom @05
        jsb S2773
        if c[p] # 0
          then go to L1452
        go to L0114

L0244:  0 -> s 11
        jsb incpc
        if 1 = s 11
          then go to L1164
        delayed rom @13
        go to L5605

S0252:  if 1 = s 2
          then go to incpc
        if 1 = s 1
          then go to incpc
        return

S0257:  p <- 1
        load constant 2
        c -> data address
        register -> c 15
        b exchange c[w]
        return

L0265:  b exchange c[w]
L0266:  m2 -> c
        delayed rom @04
        jsb S2363
        m1 -> c
        a exchange c[ms]
        m1 exchange c
        m2 -> c
        if c[x] # 0
          then go to L0303
        m1 -> c
        a exchange c[ms]
        0 -> c[w]
        go to L0334

L0303:  jsb S0006
        delayed rom @03
        jsb S1772
        a exchange c[w]
        0 -> a[xs]
        a - 1 -> a[xs]
        p <- 8
        m1 -> c
        a exchange c[wp]
        jsb S0365
        p <- 6
        jsb S0363
        p <- 3
        shift right c[wp]
        load constant 15
        a exchange c[w]
        0 -> c[w]
        load constant 7
        p <- 2
        if a >= c[p]
          then go to L0332
        0 -> c[p]
        go to L0334

L0332:  a exchange c[p]
        load constant 3
L0334:  p <- 11
        0 -> s 0
        1 -> s 11
        load constant 2
        b exchange c[w]
        display off
        display toggle
L0343:  0 -> s 15
        if 1 = s 15
          then go to L0343
        1 -> s 0
        display off
        0 -> s 3
        if 0 = s 3
          then go to L0146
        b exchange c[w]
        m2 -> c
        jsb S0006
        if 1 = s 1
          then go to L0215
        if 1 = s 2
          then go to L1735
        go to L0055

S0363:  shift right c[wp]
        load constant 15
S0365:  if c[p] # 0
          then go to L0371
        load constant 15
        load constant 15
L0371:  return

L0372:  1 -> s 2
        0 -> s 12
        go to L0115

S0375:  delayed rom @16
        go to L7253

        nop

; keycode decode table
        c + 1 -> c[x]
        c + 1 -> c[x]
        if n/c go to L0462
        go to L0577

        go to L0554

        go to L0723

        go to L0656

        go to L0670

        go to L0505

        go to L0731

        go to L0734

        go to L0712

        go to L0550		; key 16 - f

        nop
        go to L0542

        go to L0452

L0420:  c + 1 -> c[x]
        c + 1 -> c[x]
        if n/c go to L0733
        go to L0623

        go to L0514

        go to L0725

        go to L0640

        go to L0445

        go to L0463

L0431:  c + 1 -> c[x]
        if n/c go to L0466
        go to L0610

        go to L0700

        go to L0450

        go to L0727

        if 0 = s 4
          then go to L0503
        if 1 = s 6
          then go to L0114
        delayed rom @02
        go to L1313

L0445:  load constant 4
        load constant 10
        go to L0766

L0450:  delayed rom @02
        go to L1006

L0452:  if 1 = s 4
          then go to L0532
        load constant 8
        jsb S0566
        1 -> s 8
        go to L0520

L0460:  load constant 5
        go to L0573

L0462:  c + 1 -> c[x]
L0463:  c + 1 -> c[x]
        1 -> s 13
        go to L0431

L0466:  c + 1 -> c[x]
        if n/c go to L0420
L0470:  c + 1 -> c[p]
L0471:  c + 1 -> c[p]
L0472:  c + 1 -> c[p]
L0473:  c + 1 -> c[p]
        1 -> s 8
        go to L0616

L0476:  c + 1 -> c[x]
L0477:  c + 1 -> c[x]
L0500:  c + 1 -> c[x]
L0501:  c + 1 -> c[x]
L0502:  c + 1 -> c[x]
L0503:  c + 1 -> c[x]
        if n/c go to L0775
L0505:  if 0 = s 4
          then go to L0775
        if 1 = s 6
          then go to L0460
        load constant 6
        load constant 11
        go to L0775

L0514:  if 1 = s 4
          then go to L0522
        load constant 7
        jsb S0566
L0520:  1 -> s 7
        go to L0616

L0522:  if 1 = s 6
          then go to L0527
        load constant 6
        load constant 14
        go to L0775

L0527:  load constant 4
L0530:  jsb S0566
        go to L0615

L0532:  if 1 = s 6
          then go to L0540
        load constant 15
        jsb S0566
        1 -> s 10
        go to L0616

L0540:  load constant 5
        go to L0530

L0542:  if 0 = s 4
          then go to L0024
        if 0 = s 6
          then go to L1164
        load constant 6
        go to L0530

L0550:  jsb S0566		; key 16 - f
        1 -> s 6
L0552:  1 -> s 4
        go to L0616

L0554:  if 0 = s 4
          then go to L0560
L0556:  jsb S0566
        go to L0552

L0560:  if 0 = s 7
          then go to L0556
        jsb S0566
        1 -> s 7
        m1 exchange c
        go to L0552

S0566:  delayed rom @02
        go to S1141

L0570:  if 1 = s 6
          then go to L0575
        load constant 6
L0573:  load constant 12
        go to L0775

L0575:  load constant 4
        go to L0573

L0577:  if 1 = s 4
          then go to L0620
        if 0 = s 6
          then go to L0764
        if 0 = s 10
          then go to L0764
        load constant 0
L0606:  load constant 15
        go to L0775

L0610:  if 1 = s 4
          then go to L0570
        load constant 10
        jsb S0566
L0614:  1 -> s 7
L0615:  1 -> s 6
L0616:  1 -> s 13
        go to L0776

L0620:  if 0 = s 6
          then go to L1155
        go to L0764

L0623:  if 1 = s 4
          then go to L0631
        load constant 9
        jsb S0566
        1 -> s 10
        go to L0614

L0631:  if 1 = s 6
          then go to L0636
        load constant 6
L0634:  load constant 13
        go to L0775

L0636:  load constant 4
        go to L0634

L0640:  if 1 = s 7
          then go to L0650
        if 0 = s 4
          then go to L0653
        if 1 = s 6
          then go to L0653
        load constant 9
        m1 exchange c
L0650:  m1 exchange c
        shift right c[x]
        go to L0775

L0653:  load constant 4
        load constant 11
        go to L0766

L0656:  if 1 = s 4
          then go to L0664
        if 0 = s 12
          then go to L0500
        1 -> s 3
        go to L0500

L0664:  if 1 = s 6
          then go to L0476
        load constant 4
        go to L0606

L0670:  if 1 = s 4
          then go to L0674
        1 -> s 3
        go to L0501

L0674:  if 1 = s 6
          then go to L0477
        load constant 5
        go to L0606

L0700:  if 1 = s 4
          then go to L0706
        if 0 = s 12
          then go to L0502
        1 -> s 3
        go to L0502

L0706:  if 1 = s 6
          then go to L1125
        load constant 6
        go to L0606

L0712:  if 1 = s 4
          then go to L0720
L0714:  1 -> s 3
L0715:  load constant 1
        load constant 15
        go to L0766

L0720:  if 1 = s 6
          then go to L0715
        go to L0714

L0723:  delayed rom @02
        go to L1002

L0725:  delayed rom @02
        go to L1012

L0727:  delayed rom @02
        go to L1016

L0731:  delayed rom @02
        go to L1047

L0733:  c + 1 -> c[x]
L0734:  if 1 = s 4
          then go to L0747
        if 1 = s 7
          then go to L0755
        if 1 = s 6
          then go to L0751
        if 1 = s 8
          then go to L1151
        if 1 = s 10
          then go to L0755
L0746:  1 -> s 3
L0747:  c + 1 -> c[p]
        if n/c go to L0766
L0751:  if 0 = s 8
          then go to L0755
        if 1 = s 13
          then go to L0746
L0755:  a exchange c[wp]
        m1 exchange c
        a + c -> c[wp]
        m1 exchange c
        a exchange c[wp]
        m1 -> c
        go to L0775

L0764:  load constant 4
        load constant 14
L0766:  p <- 1
        if 0 = s 4
          then go to L0775
        if 1 = s 6
          then go to L0774
        c + 1 -> c[p]
L0774:  c + 1 -> c[p]
L0775:  jsb S0566
L0776:  if 1 = s 13
          then go to L0125
        delayed rom @03
        go to L1725

L1002:  jsb S1027
        if p = 1
          then go to L0473
        go to L1024

L1006:  jsb S1027
        if p = 1
          then go to L0472
        go to L1023

L1012:  jsb S1027
        if p = 1
          then go to L0471
        go to L1022

L1016:  jsb S1027
        if p = 1
          then go to L0470
        c + 1 -> c[p]
L1022:  c + 1 -> c[p]
L1023:  c + 1 -> c[p]
L1024:  c + 1 -> c[p]
L1025:  delayed rom @01
        go to L0766

S1027:  if 0 = s 4
          then go to L1035
L1031:  load constant 1
        load constant 10
        p <- 0
        return

L1035:  if 0 = s 6
          then go to L1031
        if 0 = s 7
          then go to L1031
        if 1 = s 10
          then go to L1031
        if 1 = s 8
          then go to L1031
        m1 exchange c
        return

L1047:  if 0 = s 4
          then go to L1054
L1051:  load constant 1
        load constant 10
        go to L1025

L1054:  if 1 = s 7
          then go to L1060
L1056:  1 -> s 3
        go to L1051

L1060:  if 0 = s 6
          then go to L1070
        jsb S1075
        1 -> s 6
        p <- 0
        load constant 10
L1066:  delayed rom @01
        go to L0616

L1070:  if 0 = s 8
          then go to L1056
        jsb S1075
        1 -> s 10
        go to L1066

S1075:  m1 exchange c
        1 -> s 8
        go to L1146

L1100:  0 -> s 0
        delayed rom @16
        go to L7201

L1103:  p <- 1
        load constant 1
        load constant 14
        p <- 1
        jsb S1372
L1110:  delayed rom @00
        go to L0061

S1112:  a exchange c[w]
        binary
        0 -> c[w]
        a - 1 -> a[wp]
L1116:  a exchange c[w]
        c -> data address
        a exchange c[w]
        c -> data
        a - 1 -> a[wp]
        if n/c go to L1116
        return

L1125:  1 -> s 0
        p <- 1
        load constant 2
        load constant 14
        0 -> s 3
        if 1 = s 3
          then go to L0114
        p <- 0
        jsb S1112
        m2 exchange c
        go to L1110

S1140:  0 -> s 14
S1141:  0 -> s 4
        0 -> s 6
        0 -> s 8
        0 -> s 0
        0 -> s 13
L1146:  0 -> s 7
        0 -> s 10
        return

L1151:  a exchange c[x]
        m1 exchange c
        delayed rom @06
        go to L3347

L1155:  1 -> s 0
        nop
        0 -> s 3
        if 1 = s 3
          then go to L0114
        delayed rom @13
        go to L5662

L1164:  1 -> s 11
L1165:  jsb S1170
        delayed rom @00
        go to L0035

S1170:  p <- 2
        load constant 6
        load constant 2
        load constant 13
        c -> a[w]
        m2 -> c
        if c[x] # 0
          then go to L1203
L1200:  p <- 1
        load constant 2
        go to L1216

L1203:  c + 1 -> c[xs]
        if a >= c[xs]
          then go to L1216
        0 -> c[xs]
        p <- 0
        c + 1 -> c[p]
        if a >= c[p]
          then go to L1216
        0 -> c[w]
        if 1 = s 11
          then go to L1200
L1216:  m2 exchange c
        m2 -> c
        return

L1221:  0 -> s 14
        delayed rom @05
        go to L2625

        delayed rom @05
        go to L2632

L1226:  jsb S1365
        0 -> c[w]
        p <- 12
        load constant 3
        load constant 7
        load constant 11
        load constant 5
        load constant 7
        load constant 0
        load constant 11
        load constant 4
        p <- 1
        load constant 1
        c -> data address
        a exchange c[w]
        b -> c[w]
        c -> register 14
        delayed rom @03
        jsb S1765
        1 -> s 8
        delayed rom @03
        go to L1472

L1254:  jsb S1365
        1 -> s 8
        1 -> s 10
        0 -> c[w]
        p <- 12
        load constant 15
        load constant 14
        p <- 3
        load constant 9
        go to L1303

L1266:  m1 -> c
        jsb S1332
        p <- 3
        c - 1 -> c[p]
        if n/c go to L1300
        1 -> s 0
        delayed rom @15
        jsb S16740
        if 1 = s 13
          then go to L1635
L1300:  p <- 10
        c + 1 -> c[p]
        c + 1 -> c[w]
L1303:  c -> data address
        m1 exchange c
        data -> c
        b exchange c[w]
        m1 -> c
L1310:  delayed rom @03
        go to L1507

L1312:  1 -> s 8
L1313:  m2 -> c
        if c[x] # 0
          then go to L1324
L1316:  0 -> s 11
        delayed rom @00
        jsb incpc
        if 1 = s 11
          then go to L0056
        jsb S1332
L1324:  delayed rom @00
        jsb S0006
        delayed rom @03
        jsb S1765
        delayed rom @03
        go to L1640

S1332:  0 -> s 3
        pick key?
        if 1 = s 3
          then go to L0223
        return

L1337:  jsb S1365
        0 -> c[w]
        p <- 0
        load constant 9
        1 -> s 7
        m1 exchange c
L1345:  m1 -> c
        p <- 0
        c + 1 -> c[p]
        if c[p] = 0
          then go to L1635
        c -> data address
        m1 exchange c
        data -> c
        b exchange c[w]
        m1 -> c
        p <- 1
        c - 1 -> c[p]
        a exchange c[w]
        delayed rom @03
        jsb S1772
        go to L1310

S1365:  delayed rom @03
        go to S1431

; Entry point jump table

L1367:  go to L1337
L1370:  go to L1312
S1371:  go to L1100
S1372:  go to S1112	; clear registers from a-1 down to 0x00
L1373:  go to L1165
L1374:  go to L1221	; display "Error"
L1375:  go to L1226
L1376:  go to L1254
        nop
L1400:  go to L1441
L1401:  go to L1452
S1402:  0 -> s 11		; print sixbit message
        go to L1405

S1404:  1 -> s 11		; print digits etc.
L1405:  jsb S1611

S1406:  pick print home?	; wait for printer in home position?
        if 0 = s 3
          then go to S1406
	
L1411:  p - 1 -> p
L1412:  c - 1 -> c[s]
        if n/c go to L1412
        if p # 13
          then go to L1411
        if 1 = s 11
          then go to L1437
        pick print 6
        return

S1422:  binary			; set up to print blanks using PRINT 3
        0 -> c[w]		; fill word with 'f' from 13..p+1
        c - 1 -> c[w]		;   and 'e' from p..0
L1425:  load constant 14
        if p # 13
          then go to L1425
        return

S1431:  p <- 9
        jsb S1422
        jsb S1611
        1 -> s 11
        jsb S1406
S1436:  jsb S1611

L1437:  pick print 3
        return

L1441:  jsb S1431
L1442:  pick print home?
        if 0 = s 3
          then go to L1442
        0 -> s 15
        if 1 = s 15
          then go to L1441
        delayed rom @00
        go to L0063

L1452:  0 -> s 8
        p <- 4
        jsb S1422
        p <- 2
        if 1 = s 12
          then go to L1463
        load constant 13
        load constant 13
        load constant 13
L1463:  jsb S1404
        0 -> s 6
        if 0 = s 12
          then go to L1512
L1467:  delayed rom @07
        jsb S3760
        go to L1514

L1472:  p <- 10
        c -> data address
        b exchange c[w]
        register -> c 14
        down rotate
        down rotate
        down rotate
        c -> register 14
        b exchange c[w]
        0 -> c[wp]
        p <- 11
        shift right c[wp]
        load constant 14
L1507:  jsb S1775
        jsb S1402
        1 -> s 8
L1512:  delayed rom @04
        jsb S2000
L1514:  delayed rom @02
        jsb S1371
        if a[s] # 0
          then go to L1522
        a - b -> a[s]
        a - b -> a[s]
L1522:  0 -> s 11
        0 -> c[w]
        c - 1 -> c[w]
        p <- 1
        a + 1 -> a[p]
        if n/c go to L1554
        a - 1 -> a[p]
        1 -> s 11
        a + b -> a[w]
        delayed rom @04
        jsb S2235
        p <- 12
L1536:  p - 1 -> p
        if b[p] = 0
          then go to L1536
L1541:  p - 1 -> p
        if p = 1
          then go to L1570
        if c[xs] = 0
          then go to L1570
        c - 1 -> c[xs]
        a + 1 -> a[p]
        if n/c go to L1552
        go to L1541

L1552:  a - 1 -> a[p]
        if n/c go to L1541
L1554:  a - 1 -> a[p]
        p <- 3
        a exchange c[wp]
        0 -> b[wp]
        a + b -> a[w]
        shift right c[wp]
        load constant 15
        if c[xs] = 0
          then go to L1614
        load constant 11
L1566:  jsb S1611
        pick print 3
L1570:  p <- 0
L1571:  shift right a[w]
        a - 1 -> a[s]
        a - 1 -> a[s]
        a + 1 -> a[p]
        if n/c go to L1577
        go to L1571

L1577:  a - 1 -> a[p]
        a exchange c[w]
L1601:  jsb S1611
        pick print 3
        if 0 = s 11
          then go to L1616
        p <- 2
        jsb S1422
        0 -> s 11
        go to L1601

S1611:  0 -> s 0		; print sixbit message
        delayed rom @16
        go to L7316

L1614:  load constant 12
        go to L1566

L1616:  if 1 = s 6
          then go to L1717
L1620:  0 -> s 12
        if 0 = s 8
          then go to L0063
        if 1 = s 10
          then go to L1266
        if 1 = s 7
          then go to L1345
        jsb S1767
        shift left a[m]
        shift left a[m]
        jsb S1765
        if c[m] # 0
          then go to L1472
L1635:  jsb S1431
        0 -> s 8
        go to L1620

L1640:  0 -> a[xs]
        if a[x] # 0
          then go to L1652
        if 1 = s 6
          then go to L0056
        1 -> s 6
        go to L1653

L1647:  if c[p] = 0
          then go to L1761
        go to L1653

L1652:  0 -> s 6
L1653:  display off
        delayed rom @05
        jsb S2741
        b exchange c[w]
        jsb S1767
        jsb S1772
        p <- 3
        if b[p] = 0
          then go to L1670
        c -> a[w]
        p <- 8
        jsb S1422
        go to L1674

L1670:  if 1 = s 8
          then go to L0061
        delayed rom @17
        jsb S7761
L1674:  jsb S1404
        a exchange c[w]
        jsb S1775
        jsb S1611
        pick print 6
        m2 -> c
        delayed rom @04
        jsb S2363
        p <- 3
L1705:  a - 1 -> a[xs]
        rotate left a
        p - 1 -> p
        if p # 0
          then go to L1705
        a - 1 -> a[w]
        a exchange c[w]
        jsb S1436
        if 1 = s 8
          then go to L0035
L1717:  delayed rom @00
        jsb S0257
        if 0 = s 4
          then go to L1760
        delayed rom @02
        go to L1316

L1725:  jsb S1766
        if 1 = s 11
          then go to L0244
        if c[x] = 0
          then go to L0045
        if 1 = s 3
          then go to L1760
        go to L1736

L1735:  0 -> s 2
L1736:  delayed rom @05
        jsb S2741
        p <- 4
        if c[p] # 0
          then go to L1760
        jsb S1767
        jsb S1772
        jsb S1775
        1 -> s 6
        jsb S1402
        if 1 = s 12
          then go to L1467
        if 1 = s 14
          then go to L1512
        p <- 7
        jsb S1422
        jsb S1436
        jsb S1436
L1760:  0 -> s 6
L1761:  0 -> s 14
        0 -> s 0
        delayed rom @14
        go to L6021

S1765:  a exchange c[w]
S1766:  m1 exchange c
S1767:  m1 -> c
        c -> a[w]
        return

S1772:  1 -> s 0
        delayed rom @14
        go to L16335

S1775:  1 -> s 0
        delayed rom @17
        go to L17571


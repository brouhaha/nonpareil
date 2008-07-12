; 29c ROM disassembly - model specific code, @0000-@1777
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

; External references
S2000	.equ	@2000
L2326	.equ	@2326
S2363	.equ	@2363
S2436	.equ	@2436
incpc0	.equ	@3006
S3760	.equ	@3760
L5605	.equ	@5605
L5662	.equ	@5662
L6021	.equ	@6021
L6303	.equ	@6303

; Misc. Entry points:
;
;	L0004 - cold start
;	incpc
;	incpc9

;	L0616

; Main loop entry points:

;	L0040
;	L0053
;	L0055
;	L0061
;	L0062
;	L0063
;	L0065
;	L0067
;	L0070
;	L0101

; Jump table entry points:
	
;	L1367
;	L1370
;	S1371
;	S1372	clear registers from a-1 down to 0x00
;	L1373
;	L1374	display "Error"
;	L1375
;	L1376
;	L1400
;	L1401
;	L1402

	.bank 0
	.org @0000

        nop			; 19C: reset twf
        nop			; 19C: 0 -> s 0
        delayed rom @14
        go to L6303

L0004:  delayed rom @02
        go to L1133

S0006:  c -> a[x]		; get program byte
        c -> data address
        data -> c
        a exchange c[w]
L0012:  rotate left a
        rotate left a
        c - 1 -> c[xs]
        if n/c go to L0012
        return

incpc:  delayed rom @06		; advance PC
        go to incpc0

incpc9: m2 exchange c
        m2 -> c
        return

L0024:  1 -> s 1
        m2 -> c
        if c[x] = 0
          then go to L0034
        nop
        0 -> s 3
        if 1 = s 3
          then go to L0035
L0034:  jsb incpc		; advance PC
L0035:  delayed rom @02
        jsb S1167
        go to L0234

L0040:  if 1 = s 2
          then go to L0053
        if 1 = s 1
          then go to L0061
        1 -> s 2
        0 -> s 12
        m2 -> c
        if c[x] # 0
          then go to L0052
        jsb incpc		; advance PC
L0052:  go to L0035

L0053:  0 -> s 2
        jsb incpc		; advance PC
L0055:  1 -> s 9
L0056:  jsb S0323
        0 -> s 12
        go to L0115

L0061:  1 -> s 9
L0062:  0 -> s 12
L0063:  jsb S0323
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
        jsb S0315
        0 -> s 2
        0 -> s 1
L0101:  0 -> s 12
        jsb S0323
        c -> a[w]
        c -> register 15
        p <- 1
        load constant 1
        c -> data address
        b -> c[w]
        c -> register 15
        a -> b[w]
        b -> c[w]
L0114:  jsb S0315
L0115:  binary
        delayed rom @02
        jsb S1167
        b -> c[w]
        if 1 = s 2
          then go to L0223
        0 -> s 1
L0124:  0 -> s 11
        0 -> c[s]
        m1 exchange c
        b -> c[w]
        0 -> s 3
        if 0 = s 3
          then go to L0232
        if 0 = s 12
          then go to L0140
        delayed rom @07
        jsb S3760
        go to L0142

L0140:  delayed rom @04
        jsb S2000
L0142:  delayed rom @02
        jsb S1371
L0144:  hi i'm woodstock
        display off
        display toggle
L0147:  0 -> s 15
        if 1 = s 15
          then go to L0147
L0152:  0 -> s 1		; idle loop
        0 -> s 3
        if 0 = s 3
          then go to L0163
        if 0 = s 11
          then go to L0165
        0 -> s 11
        b exchange c[w]
        go to L0062

L0163:  if 0 = s 11
          then go to L0232
L0165:  0 -> s 5
        if 1 = s 5
          then go to L0173
        jsb S0331
        jsb S0331
        nop
L0173:  if 0 = s 15		; key pressed?
          then go to L0152	;   no, back to top of idle loop

L0175:  display off		; main key dispatch
        b exchange c[w]
        keys -> a
        0 -> s 13
        binary

; Convert hardware keycode in A[2:1] to keycode table offset in A[2:1]:
; multiply hardware keycode row by 5 and add to hardware keycode column.

; user     hardware  jump
; keycode  keycode   address
; -------  --------  -------
;    11      0263
;    12      0262
;    13      0261
;    14      0260
;    15      0264


        0 -> c[x]
L0203:  c + 1 -> c[x]
        a - 1 -> a[xs]
        if n/c go to L0203
        c - 1 -> c[x]
        0 -> a[xs]
        shift right a[x]
        a + c -> a[x]
        c + c -> c[x]
        c + c -> c[x]
        a + c -> a[x]
        shift left a[x]

        p <- 1
        m1 -> c
        0 -> c[x]
        delayed rom @01		; keyboard table @0400-@0777
        a -> rom address

L0223:  if 1 = s 12
          then go to L0306
        0 -> s 15
        if 0 = s 15
          then go to L0306
        0 -> s 2
        go to L0056

L0232:  b exchange c[w]
        1 -> s 11
L0234:  m2 -> c
        delayed rom @04		; compute decimal program line number?
        jsb S2363
        m1 -> c
        a exchange c[ms]
        m1 exchange c
        m2 -> c
        if c[x] # 0
          then go to L0251
        m1 -> c
        a exchange c[ms]
        0 -> c[w]
        go to L0254

L0251:  jsb S0006		; get program byte
        delayed rom @03
        jsb S1650		; decode program step into keycodes for display
L0254:  p <- 11
        load constant 2
        b exchange c[w]
        display off
        display toggle
L0261:  0 -> s 15
        if 1 = s 15
          then go to L0261
        display off
        0 -> s 3
        if 0 = s 3
          then go to L0144
        b exchange c[w]
        m2 -> c
        jsb S0006		; get program byte
        if 1 = s 1
          then go to L0311
        if 1 = s 2
          then go to L0311
        go to L0055

L0300:  0 -> s 11
        jsb incpc		; advance PC
        if 1 = s 11
          then go to L1301
        delayed rom @13
        go to L5605

L0306:  m2 -> c
        jsb S0006		; get program byte
        display toggle
L0311:  a exchange c[w]
        m1 exchange c
        delayed rom @14
        go to L6021

S0315:  if 1 = s 2
          then go to L0321
        if 0 = s 1
          then go to L0322
L0321:  go to incpc		; advance PC

L0322:  return

S0323:  p <- 1
        load constant 2
        c -> data address
        register -> c 15
        b exchange c[w]
        return

S0331:  p <- 0
        if a[p] # 0
          then go to L0361
        a - 1 -> a[p]
        jsb S0365
        c - 1 -> c[p]
L0337:  b exchange c[w]
        p <- 1
        load constant 2
        c -> data address
        register -> c 15
        a exchange b[p]
L0345:  p - 1 -> p
        0 -> s 15
        if 1 = s 15
          then go to L0175
        if p # 4
          then go to L0345
        p <- 0
        a + 1 -> a[p]
        if n/c go to L0345
        p <- 0
        a exchange b[p]
        return

L0361:  0 -> a[p]
        jsb S0365
        c + 1 -> c[p]
        if n/c go to L0337
S0365:  p <- 13
L0366:  p - 1 -> p
        if b[p] = 0
          then go to L0366
        b -> c[w]
        return

        nop
        nop
        nop
        nop
        nop

S0400:  delayed rom @02
        go to S1167

L0402:  if 0 = s 4
          then go to L0407
L0404:  load constant 1
        load constant 10
        go to L0553

L0407:  if 0 = s 7
          then go to L0404
        if 0 = s 6
          then go to L0575
        jsb S0763
        1 -> s 6
        p <- 0
        load constant 10
        go to L0616

L0420:  c + 1 -> c[x]
L0421:  c + 1 -> c[x]
        1 -> s 13
        go to L0463

; keyboard table row 2
        go to L0701		; key 24 - RCL/unused/ISZ
        go to L0666		; key 23 - STO/unused/DSZ
        go to L0714		; key 22 - RDN/s/i
        go to L0551		; key 21 - x<>y/xbar/%

        if 0 = s 4		; key 25 - Sigma+/Sigma-/DEL
          then go to L0651
        if 0 = s 6
          then go to L1312
        go to L0655

        nop

; keyboard table row 4
        c + 1 -> c[x]		; key 44 - 9/->R/->P
        c + 1 -> c[x]		; key 43 - 8/log/10^x
	.legal
        go to L0420		; key 42 - 7/ln/e^x
        go to L0453		; key 41 - minus/x<=y/x<0

L0442:  c + 1 -> c[x]

; keyboard table row 6
        c + 1 -> c[x]		; key 64 - 3/y^x/ABS
        c + 1 -> c[x]		; key 63 - 2/sqrt(x)/x^2
        if n/c go to L0732	; key 62 - 1/INT/FRAC
        delayed rom @02		; key 61 - times/x!=y/x>=0
        go to L1010

L0450:  load constant 5
L0451:  load constant 12
        go to L0562

L0453:  delayed rom @02		; key 41 - minus/x<=y/x<0
        go to L1000

; keyboard table row 7
        go to L0542		; key 74 - R/S/PAUSE/1/x
        go to L0402		; key 73 - decimal/LASTx/pi
        go to L0733		; key 72 - 0/->H.MS/->
        delayed rom @02		; key 71 - divide/x=y/x=0
        go to L1014

; keyboard table row 5
        go to L0421		; key 54 - 6/tan/arctan
L0463:  c + 1 -> c[x]		; key 53 - 5/cos/arccos
	.legal
        go to L0442		; key 52 - 4/sin/arcsin
        delayed rom @02		; key 51 - plus/x>y/x>=0
        go to L1004

; keyboard table row 1
        go to L0645		; key 14 - f
        go to L0627		; key 13 - GTO/ENG/LBL
        go to L0611		; key 12 - GSB/SCI/RTN
        go to L0602		; key 11 - SST/FIX/BST

        if 1 = s 4		; key 15 - g
          then go to L0477
        if 1 = s 7
          then go to L0662
L0477:  jsb S0400
        go to L0647

; keyboard table row 3
        go to L0524		; key 33 - EEX/CLR REG/RAD
        go to L0516		; key 32 - CHS/CLR PRGM/GRD
        nop
        go to L0513		; key 31 - ENTER^/CLR PREFIX/unused

        if 0 = s 4		; key 34 - CLx/CLR Sigma/DEG
          then go to L0535
        if 1 = s 6
          then go to L0533
        load constant 4
        go to L0531

L0513:  if 1 = s 4		; key 31 - ENTER^/CLR PREFIX/unused
          then go to L0114
        go to L0540

L0516:  if 0 = s 4		; key 32 - CHS/CLR PRGM/GRD
          then go to L0537
        if 1 = s 6
          then go to L1154
        load constant 6
        go to L0531

L0524:  if 0 = s 4		; key 33 - EEX/CLR REG/RAD
          then go to L0536
        if 1 = s 6
          then go to L0534
        load constant 5
L0531:  load constant 15
        go to L0562

L0533:  c + 1 -> c[x]
L0534:  c + 1 -> c[x]
L0535:  c + 1 -> c[x]
L0536:  c + 1 -> c[x]
L0537:  c + 1 -> c[x]
L0540:  c + 1 -> c[x]
        if n/c go to L0562
L0542:  if 0 = s 4
          then go to L0562
        if 1 = s 6
          then go to L0450
        load constant 6
        load constant 11
        go to L0562

L0551:  load constant 4		; key 21 - x<>y/xbar/%
        load constant 10
L0553:  p <- 1
        if 0 = s 4
          then go to L0562
        if 1 = s 6
          then go to L0561
        c + 1 -> c[p]
L0561:  c + 1 -> c[p]
L0562:  jsb S0400
L0563:  if 1 = s 13
          then go to L0124
        c -> a[w]
        m1 exchange c
        jsb S0400
        0 -> s 3
        if 0 = s 3
          then go to L0300
        delayed rom @14
        go to L6021

L0575:  if 0 = s 8
          then go to L0404
        jsb S0763
        1 -> s 10
        go to L0616

L0602:  if 0 = s 4		; key 11 - SST/FIX/BST
L0603:    then go to L0024	; unshifted - SST
        if 0 = s 6
          then go to L1301
        load constant 4
L0607:  jsb S0400
        go to L0673

L0611:  if 1 = s 4		; key 12 - GSB/SCI/RTN
          then go to L0620
        load constant 7
        jsb S0400
L0615:  1 -> s 7
L0616:  1 -> s 13
        go to L0563

L0620:  if 1 = s 6
          then go to L0625
        load constant 6
        load constant 14
        go to L0562

L0625:  load constant 5
        go to L0607

L0627:  if 1 = s 4		; key 13 - GTO/ENG/LBL
          then go to L0635
        load constant 8
        jsb S0400
        1 -> s 8
        go to L0615

L0635:  if 1 = s 6
          then go to L0643
        load constant 15
        jsb S0400
        1 -> s 10
        go to L0616

L0643:  load constant 6
        go to L0607

L0645:  jsb S0400		; key 14 - f
        1 -> s 6
L0647:  1 -> s 4
        go to L0616

L0651:  if 0 = s 6
          then go to L0655
        if 1 = s 10
          then go to L0660
L0655:  load constant 4
        load constant 14
        go to L0553

L0660:  load constant 0
        go to L0531

L0662:  jsb S0400
        1 -> s 7
        m1 exchange c
        go to L0647

L0666:  if 1 = s 4		; key 23 - STO/unused/DSZ
          then go to L0675
L0670:  load constant 10
        jsb S0400
L0672:  1 -> s 7
L0673:  1 -> s 6
        go to L0616

L0675:  if 1 = s 6
          then go to L0670
        load constant 6
        go to L0451

L0701:  if 0 = s 4		; key 24 - RCL/unused/ISZ
          then go to L0710
        if 1 = s 6
          then go to L0710
        load constant 6
        load constant 13
        go to L0562

L0710:  load constant 9
        jsb S0400
        1 -> s 10
        go to L0672

L0714:  if 1 = s 7		; key 22 - RDN/s/i
          then go to L0724
        if 0 = s 4
          then go to L0727
        if 1 = s 6
          then go to L0727
        load constant 9
        m1 exchange c
L0724:  m1 exchange c
        shift right c[x]
        go to L0562

L0727:  load constant 4
        load constant 11
        go to L0553

L0732:  c + 1 -> c[x]
L0733:  if 1 = s 4
          then go to L0745
        if 1 = s 7
          then go to L0747
        if 1 = s 6
          then go to L0756
        if 1 = s 8
          then go to L1045
        if 1 = s 10
          then go to L0747
L0745:  c + 1 -> c[p]
        if n/c go to L0553
L0747:  a exchange c[wp]
        m1 exchange c
        a + c -> c[wp]
        m1 exchange c
        a exchange c[wp]
        m1 -> c
        go to L0562

L0756:  if 0 = s 8
          then go to L0747
        if 1 = s 13
          then go to L0745
        go to L0747

S0763:  m1 exchange c
        0 -> s 7
        1 -> s 8
        0 -> s 10
        return

L0770:  c + 1 -> c[p]
L0771:  c + 1 -> c[p]
L0772:  c + 1 -> c[p]
L0773:  c + 1 -> c[p]
        1 -> s 8
        go to L0616

        nop
        nop

L1000:  jsb S1025		; key 41 - minus/x<=y/x<0
        if p = 1
          then go to L0773
        go to L1022

L1004:  jsb S1025		; key 51 - plus/x>y/x>=0
        if p = 1
          then go to L0772
        go to L1021

L1010:  jsb S1025		; key 61 - times/x!=y/x>=0
        if p = 1
          then go to L0771
        go to L1020

L1014:  jsb S1025		; key 71 - divide/x=y/x=0
        if p = 1
          then go to L0770
        c + 1 -> c[p]
L1020:  c + 1 -> c[p]
L1021:  c + 1 -> c[p]
L1022:  c + 1 -> c[p]
        delayed rom @01
        go to L0553

S1025:  if 0 = s 4
          then go to L1033
L1027:  load constant 1
        load constant 10
        p <- 0
        return

L1033:  if 0 = s 6
          then go to L1027
        if 0 = s 7
          then go to L1027
        if 1 = s 10
          then go to L1027
        if 1 = s 8
          then go to L1027
        m1 exchange c
        return

L1045:  a exchange c[x]
        m1 exchange c
        p <- 0
        a exchange c[p]
        if c[xs] # 0
          then go to L1306
        a exchange c[x]
        shift left a[x]
        a exchange c[x]
        delayed rom @01
        go to L0616

L1060:  b exchange c[w]
        binary
        0 -> c[w]
        p <- 13
        load constant 2
        load constant 9
        b exchange c[w]
        p <- 0
        go to L1073

L1071:  shift right b[m]
        a - 1 -> a[p]
L1073:  if a[p] # 0
          then go to L1071
        p <- 1
        a + 1 -> a[p]
        if n/c go to L1116
L1100:  p <- 12
L1101:  if b[p] = 0
          then go to L1110
        a + 1 -> a[p]
        if n/c go to L1106
        return

L1106:  a - 1 -> a[p]
        return

L1110:  a + 1 -> a[p]
        if n/c go to L1113
        a + 1 -> a[p]
L1113:  a - 1 -> a[p]
        p - 1 -> p
        go to L1101

L1116:  a - 1 -> a[p]
        p <- 4
        shift left a[wp]
        b exchange c[w]
        load constant 2
        b exchange c[w]
        go to L1100

L1125:  delayed rom @00
        go to L0061

S1127:  0 -> c[w]
        m2 exchange c
        m2 -> c
        return

L1133:  p <- 1
        load constant 1
        load constant 14
        p <- 1
        jsb S1141
        go to L1125

; clear registers from a-1 downto 0x00

S1141:  a exchange c[w]
        binary
        0 -> c[w]
        a - 1 -> a[wp]
L1145:  a exchange c[w]
        c -> data address
        a exchange c[w]
        c -> data
        a - 1 -> a[wp]
        if n/c go to L1145
        return

L1154:  0 -> s 3
        if 1 = s 3
          then go to L0114
        0 -> c[w]
        p <- 1
        load constant 2
        load constant 14
        p <- 0
        jsb S1372
        jsb S1127
        go to L1125

S1167:  0 -> s 4		; reset key parser flags
        0 -> s 0
        0 -> s 14
        0 -> s 6
        0 -> s 7
        0 -> s 8
        0 -> s 10
        0 -> s 13
        return

S1200:  p <- 2
        load constant 6
        load constant 2
        load constant 13
        c -> a[w]
        m2 -> c
        if c[x] # 0
          then go to L1213
L1210:  p <- 1
        load constant 2
        go to L1226

L1213:  c + 1 -> c[xs]
        if a >= c[xs]
          then go to L1226
        0 -> c[xs]
        p <- 0
        c + 1 -> c[p]
        if a >= c[p]
          then go to L1226
        0 -> c[w]
        if 1 = s 11
          then go to L1210
L1226:  m2 exchange c
        m2 -> c
        return

L1231:  0 -> a[w]
        0 -> c[w]
        0 -> s 1
        0 -> s 2
        p <- 13
        load constant 14	; E
        load constant 10	; r
        load constant 10	; r
        load constant 12	; o
        load constant 10	; r
        binary
        c - 1 -> c[wp]
        a exchange c[w]
        b exchange c[w]
        display off
        display toggle
        p <- 2
        load constant 4
L1253:  c - 1 -> c[x]
        if n/c go to L1253
        display toggle
L1256:  c - 1 -> c[wp]
        if n/c go to L1256
        display toggle
L1261:  0 -> s 15
        if 1 = s 15
          then go to L1261
L1264:  0 -> s 3
        if 1 = s 3
          then go to L1271
        if 0 = s 15
          then go to L1264
L1271:  if 1 = s 15
          then go to L1276
        0 -> s 3
        if 1 = s 3
          then go to L1271
L1276:  display toggle
        delayed rom @00
        go to L0062

L1301:  1 -> s 11
L1302:  jsb S1200
        1 -> s 11
        delayed rom @00
        go to L0035

L1306:  0 -> c[xs]
        0 -> s 8
        delayed rom @04
        go to L2326

L1312:  0 -> s 3
        if 1 = s 3
          then go to L0114
        delayed rom @13
        go to L5662

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

; Entry point jump table

L1367:  nop
L1370:  go to L1125
S1371:  go to L1060
S1372:  go to S1141	; clear registers from a-1 down to 0x00
L1373:  go to L1302
L1374:  go to L1231	; display "Error"

L1375:  nop
L1376:  nop
        nop
L1400:  nop
L1401:  nop
L1402:  nop		; print sixbit message (no printer)
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        go to L1702

        c - 1 -> c[p]
        c - 1 -> c[p]
L1415:  c - 1 -> c[p]
        if n/c go to L1563
        nop

; keycode decode table, indexed by 15-row:

        go to L1546		; row 15
        c + 1 -> c[m]		; row 14
        c + 1 -> c[m]		; row 13
        c + 1 -> c[m]		; row 12
        if n/c go to L1637	; row 11
        c - 1 -> c[xs]		; row 10
        if n/c go to L1646	; row 9
        go to L1627		; row 8
        go to L1626		; row 7
        go to L1520		; row 6
        go to L1523		; row 5
        go to L1541		; row 4
        go to L1470		; row 3
        go to L1472		; row 2
        go to L1464		; row 1
        go to L1452		; row 0
	
        go to L1631

        c - 1 -> c[w]
        c - 1 -> c[w]
        if n/c go to L1634
        c - 1 -> c[w]
        c - 1 -> c[w]
        if n/c go to L1635
        c - 1 -> c[w]
        c - 1 -> c[w]
        if n/c go to L1563
L1452:  c - 1 -> c[p]
        if c[s] = 0
          then go to L1462
        c - 1 -> c[p]
        p <- 3
        load constant 7
        load constant 1
        p <- 6
L1462:  a - 1 -> a[w]
        if n/c go to L1507
L1464:  jsb S1713
        if c[s] = 0
          then go to L1615
        go to L1500

L1470:  c + 1 -> c[xs]
        a + 1 -> a[p]
L1472:  if c[s] # 0
          then go to L1477
        c + 1 -> c[w]
        c + 1 -> c[w]
        if n/c go to L1503
L1477:  a + 1 -> a[p]
L1500:  a + 1 -> a[p]
        load constant 7
        c - 1 -> c[w]
L1503:  p <- 1
        a exchange c[p]
        0 - c - 1 -> c[p]
        a exchange c[p]
L1507:  shift left a[w]
        a -> rom address

        nop
L1512:  c - 1 -> c[w]
        if n/c go to L1563
L1514:  c + 1 -> c[w]
        if n/c go to L1537
        go to L1701

        go to L1514

L1520:  if c[s] = 0
          then go to L1612
        c + 1 -> c[xs]
L1523:  if c[s] = 0
          then go to L1611
        go to L1544

S1526:  p <- 3
S1527:  load constant 1
        load constant 4
        return

        c - 1 -> c[w]
        if n/c go to L1563
L1534:  load constant 7
        go to L1702

        go to L1701

L1537:  c + 1 -> c[w]
        if n/c go to L1557
L1541:  if c[s] = 0
          then go to L1610
        jsb S1713
L1544:  load constant 2
        go to L1503

L1546:  p <- 6
        load constant 1
        load constant 5
        go to L1627

        go to L1512

        go to L1534

        go to L1703

        go to L1702

        go to L1415

L1557:  c + 1 -> c[p]
        p <- 3
        load constant 1
        load constant 5
L1563:  0 -> c[s]
L1564:  if c[s] = 0
          then go to S1571
        jsb S1571
        load constant 3
        return

S1571:  a exchange c[w]
        shift left a[w]
        shift right a[x]
        a - 1 -> a[xs]
        shift left a[w]
        shift left a[w]
        p <- 0
        a - 1 -> a[p]
        m1 -> c
        p <- 11
        a exchange c[wp]
        a exchange c[w]
        0 -> c[w]
        p <- 3
        return

L1610:  c - 1 -> c[xs]
L1611:  c - 1 -> c[xs]
L1612:  c - 1 -> c[xs]
        p <- 6
        jsb S1527
L1615:  p <- 1
        load constant 0
        load constant 10
        p <- 0
        if c[s] = 0
          then go to L1624
        a - c -> a[p]
L1624:  a exchange c[p]
        go to L1564

L1626:  c - 1 -> c[xs]
L1627:  c - 1 -> c[xs]
        if n/c go to L1615
L1631:  load constant 7
        load constant 2
        go to L1563

L1634:  c + 1 -> c[p]
L1635:  c + 1 -> c[p]
        if n/c go to L1563
L1637:  c + 1 -> c[m]
        c + 1 -> c[m]
        p <- 6
        load constant 2
        load constant 3
        p <- 2
        load constant 1
L1646:  c + 1 -> c[m]
        if n/c go to L1615

; decode program step into keycodes
S1650:  0 -> c[w]
        c - 1 -> c[w]
        p <- 0
        load constant 10
        jsb S1526
        load constant 4
        if a >= c[p]		; LSD > 9?
          then go to L1661	;   yes, c[s] = f
        0 -> c[s]		;   no, c[s] = 0
L1661:  load constant 2
        p <- 1
        0 -> a[xs]
        a + 1 -> a[xs]
        a exchange c[p]
        0 - c - 1 -> c[p]
        a exchange c[p]
        a -> rom address	; decode row dispatch, table at @1410
				;   indexed by 15-row

L1671:  load constant 7
L1672:  jsb S1713
        go to L1702

L1674:  c - 1 -> c[xs]
        if n/c go to L1415
L1676:  p <- 3
        load constant 2
        load constant 4
L1701:  c + 1 -> c[w]
L1702:  c + 1 -> c[w]
L1703:  c + 1 -> c[w]
        if n/c go to L1563
L1705:  c + 1 -> c[m]
        if n/c go to L1415
L1707:  p <- 3
L1710:  load constant 2
        load constant 3
        go to L1563

S1713:  p <- 3
        load constant 15
        load constant 15
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
        go to L1671

        c - 1 -> c[w]
        c - 1 -> c[w]
        c - 1 -> c[w]
        if n/c go to L1672
        c - 1 -> c[w]
        if n/c go to L1702
        c - 1 -> c[xs]
        if n/c go to L1674
        go to L1705

        go to L1707

        c - 1 -> c[m]
        c - 1 -> c[m]
        c - 1 -> c[m]
        if n/c go to L1710
        go to L1676

        nop


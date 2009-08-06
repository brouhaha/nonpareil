; 19C ROM disassembly - bank 1
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$
;
	.arch woodstock

; Entry points:
;
;	S16740
;	L16335
;	L17571

	.bank 1
	.org @6000

; addr 16000: mnemonic table, high digit
         go to m_op_0x		; 0x
         go to m_op_1x		; 1x
         go to m_op_2x_x	; 2x
         go to m_op_3x_x	; 3x
         go to m_op_4x		; 4x
         go to m_op_5x		; 5x
         go to m_op_6x		; 6x
         go to m_gsb		; 7x GSB
         go to m_gto		; 8x GTO
         go to m_rcl		; 9x RCL
         go to m_sto		; ax STO
         go to m_sto_minus	; bx STO-
         go to m_sto_plus	; cx STO+
         go to m_sto_times		; dx STO*
         go to m_sto_divide		; ex STO/

m_op_fx: if 1 = s 11
           then go to L16215
         p <- 13
         load constant 1
         load constant 0
         load constant 1		; 'L'
         load constant 11		; 'B'
         load constant 1		; 'L'
         jsb S16104
         load constant 1
         load constant 4
         go to S16065

m_op_4x: if 1 = s 11
           then go to L16262
         p <- 13
         load constant 2
         load constant 6
         load constant 4		; 'X'
         load constant 15		; 'I'
         load constant 5		; 'F'
         go to S16065

m_op_5x: if 1 = s 11
           then go to L16317
         load constant 0	; SCI
         load constant 15		; 'I'
         load constant 12		; 'C'
         load constant 6		; 'S'
         p <- 5
         go to L16064

m_op_6x: if 1 = s 11
           then go to L16264
         load constant 0	; ENG
         load constant 2		; 'G'
         load constant 0		; 'N'
         load constant 14		; 'E'
         p <- 5
         c + 1 -> c[p]
L16064:  c + 1 -> c[p]
S16065:  p <- 3
         shift left a[wp]
         a exchange c[x]
         c -> a[x]
         shift left a[wp]
         shift left a[wp]
         a exchange c[p]
         p <- 2
         load constant 4
         p <- 4
         if 0 = s 11
           then go to L16102
         load constant 10
L16102:  return

S16103:  p <- 6
S16104:  load constant 2
         load constant 5
         return

S16107:  load constant 7		; 'T'
         load constant 6		; 'S'
         load constant 4
         load constant 5
         load constant 3
         load constant 1
         p <- 6
         return

m_sto:   0 -> c[w]
         load constant 0
         load constant 3		; 'O'
         jsb S16107
         p <- 8
         shift right c[wp]
         shift right c[wp]
         p <- 4
         0 -> c[p]
         go to L16171

m_sto_divide:
         load constant 2
         load constant 12		; divide symbol
         jsb S16107
         c + 1 -> c[p]
L16135:  c + 1 -> c[p]
L16136:  c + 1 -> c[p]
L16137:  if 1 = s 11
           then go to L16177
         0 -> c[s]
         go to S16065

m_sto_minus:
         load constant 3	; STO-
         c + 1 -> c[s]
         load constant 11		; '-'
         jsb S16107
         go to L16137

m_sto_plus:
         load constant 3
         c + 1 -> c[s]
         load constant 12		; '+'
         jsb S16107
         go to L16136

m_sto_times:
         load constant 2
         load constant 15		; small x
         jsb S16107
         go to L16135

m_rcl:   load constant 0
         0 -> c[w]
         load constant 1		; 'L'
         load constant 12		; 'C'
         load constant 5		; 'R'
         p <- 6
         load constant 5
         load constant 5
L16171:  if 0 = s 11
           then go to S16065
         p <- 12
         load constant 3
         load constant 10
         go to S16065

L16177:  p <- 13
         if c[p] # 0
           then go to L16204
         load constant 8
         go to L16205

L16204:  load constant 12
L16205:  load constant 3
         shift right c[wp]
         load constant 10
         p <- 9
         a exchange c[wp]
         shift left a[wp]
         a exchange c[wp]
         go to S16065

L16215:  load constant 9
         load constant 8
         load constant 4
         load constant 8
         p <- 12
         shift left a[x]
         a -> rom address

L16224:  load constant 11
         load constant 14
L16226:  load constant 0
         p <- 13
         load constant 4
         return

L16232:  p <- 10
         go to L16226

m_gto:   0 -> c[w]
         load constant 0
         load constant 3		; 'O'
         load constant 7		; 'T'
         load constant 2		; 'G'
         p <- 6
         load constant 1
         load constant 4
         go to S16065

m_gsb:   0 -> c[w]
         load constant 0
         load constant 11		; 'B'
         load constant 6		; 'S'
         load constant 2		; 'G'
         p <- 6
         load constant 1
         load constant 3
         go to S16065

m_op_2x_x:
	 delayed rom @16
         go to m_op_2x

m_op_3x_x:
         delayed rom @16
         go to m_op_3x

L16262:  0 -> c[w]
         go to L16266

L16264:  0 -> c[w]
         jsb S16103
L16266:  shift left a[x]
         p <- 12
         delayed rom @17
         a -> rom address

m_op_1x: 0 -> c[w]
         if 1 = s 11
           then go to L16315
         jsb S16065
         p <- 4
         load constant 0
         c -> a[p]
         0 -> c[x]
L16302:  shift left a[w]
         p + 1 -> p
         if p # 10
           then go to L16302
         a exchange c[p]
         p <- 12
         load constant 15
         load constant 14
         p <- 9
         load constant 14
         return

L16315:  delayed rom @15
         go to L16475

L16317:  0 -> c[w]
         p <- 6
         load constant 1
         load constant 6
         p <- 12
         shift left a[x]
         delayed rom @15
         a -> rom address

m_op_0x: 0 -> c[w]
         shift left a[x]
         if 1 = s 11
           then go to L16373
         delayed rom @15
         a -> rom address

; entry point called by subroutine at S1772 in 19c.asm
L16335:  0 -> c[w]
         1 -> s 11
         p <- 0
         load constant 10
         p <- 0
         a - c -> a[p]
         if n/c go to L16346
         0 -> s 11
         a + c -> a[p]
L16346:  0 -> c[p]
         p <- 8
         load constant 1
         load constant 6
         load constant 1
         load constant 3
; decode opcode to mnemonic - dispatch high digit via table @16000
         p <- 12
         0 -> a[xs]
         a -> rom address	; table at @16000

         nop
         go to L16370

         go to L16375

         return

         go to L16224

         go to L16232

         load constant 9
         load constant 0
         return

L16370:  0 -> c[m]
         load constant 3
         go to L16376

L16373:  delayed rom @15
         go to L16721

L16375:  load constant 11
L16376:  load constant 14
         return

; @16400:
         go to m_r_s		; 0x00 - R/S
         go to m_enter		; 0x01 - ENTER^
         go to m_chs		; 0x02 - CHS
         go to m_eex		; 0x03 - EEX
         go to m_clx		; 0x04 - CLx
         go to m_clrg		; 0x05 - CLR REG
         go to L16427		; 0x06 - CLR Sigma
         go to L16527		; 0x07 - GSB i
         go to L16542		; 0x08 - GTO i
         go to L16552		; 0x09 - RCL i

m_eex:   load constant 2	; EEX
         load constant 4		; 'X'
         load constant 14		; 'E'
         load constant 14		; 'E'
         jsb S16652
         go to cm_plus_3

m_chs:   load constant 1	; CHS
         load constant 3		; 'H'
         load constant 12		; 'C'
         jsb S16652
         load constant 1
         load constant 6		; 'S'
         go to cm_plus_2

L16427:  load constant 2
         load constant 8
         load constant 1
         load constant 12
         p <- 6
         load constant 1
         load constant 6
         jsb S16652
         go to cm_plus_4

         go to L16621
         go to L16452
         go to L16626
         go to L16766
         go to L16636
         go to m_prtx

         p <- 6
         load constant 1
         load constant 6
         return

L16452:  p <- 10
         load constant 11
         jsb S16651
         go to cm_plus_1

m_enter: load constant 0	; ENT^
         load constant 7		; 'T'
         load constant 0		; 'N'
         load constant 14		; 'E'
         jsb S16652
         load constant 3
         load constant 13		; up arrow character
         go to cm_plus_1

m_r_s:   load constant 2
         load constant 11		; '/'
         load constant 5		; 'R'
         jsb S16646
         load constant 1
         load constant 6		; 'S'
         go to cm_plus_4

L16475:  load constant 15	; +
         load constant 14
         load constant 12		; '+'
         p <- 12
         shift left a[x]
         a + 1 -> a[xs]
         a -> rom address

m_clrg:  load constant 0	; CLRG
         load constant 5		; 'R'
         load constant 1		; 'L'
         load constant 12		; 'C'
         p <- 6
         load constant 1
         load constant 6
         load constant 2
         load constant 3
         load constant 1
         load constant 2
         return

; @16520
         go to L16641		; 0x5a - x bar
         go to L16701		; 0x5b - s
         go to L16706		; 0x5c - PAUSE
         nop   			; 0x5d - spare
         go to L16714		; 0x5e - Sigma-
         delayed rom @17	; 0x5f - RAD
         go to m_rad

L16527:  load constant 0
         load constant 11
         load constant 6
         load constant 2
         p <- 6
         load constant 1
         load constant 3
L16536:  jsb S16653
         load constant 2
         load constant 15
         go to cm_plus_2

L16542:  load constant 0
         load constant 3
         load constant 7
         load constant 2
         p <- 6
         load constant 1
         load constant 4
         go to L16536

L16552:  load constant 0
         load constant 1
         load constant 12
         load constant 5
         p <- 6
         load constant 5
         load constant 5
         go to L16536

L16562:  load constant 0
         load constant 3
         p <- 8
         load constant 0
         load constant 0
         load constant 4
         load constant 5
         return

L16572:  load constant 2
         load constant 12
         p <- 6
         c + 1 -> c[p]
L16576:  c + 1 -> c[p]
         return

L16600:  load constant 2
         load constant 15
         p <- 6
         go to L16576

L16604:  load constant 2
         load constant 8
         load constant 12
         load constant 5
         load constant 0
         load constant 0
         load constant 5
         load constant 5
         load constant 3
         load constant 5
         load constant 4
         load constant 12
         return

L16621:  load constant 15
         load constant 14
         load constant 10
         jsb S16646
         go to cm_plus_3

L16626:  jsb S16650
         go to cm_plus_1

m_clx:   load constant 2	; Clx
         load constant 4		; 'x'
         load constant 1		; 'L'
         load constant 12		; 'C'
         jsb S16652
         go to cm_plus_4

L16636:  load constant 11
         jsb S16646
         go to cm_plus_1

L16641:  load constant 11
         load constant 14
         load constant 6
         jsb S16653
         go to cm_plus_1

S16646:  c + 1 -> c[m]
S16647:  c + 1 -> c[m]
S16650:  c + 1 -> c[m]
S16651:  c + 1 -> c[m]
S16652:  c + 1 -> c[m]
S16653:  c + 1 -> c[m]
L16654:  p <- 4
         a exchange c[w]
         shift left a[wp]
         a exchange c[w]
         p <- 2
         return

         c + 1 -> c[m]
cm_plus_5:  c + 1 -> c[m]
cm_plus_4:  c + 1 -> c[m]
cm_plus_3:  c + 1 -> c[m]
cm_plus_2:  c + 1 -> c[m]
cm_plus_1:  c + 1 -> c[m]
         return

m_prtx:  load constant 0	; PRTX
         load constant 7		; 'T'
         load constant 5		; 'R'
         load constant 4		; 'P'
         jsb S16646
         load constant 3
         load constant 4		; 'X'
         go to cm_plus_5

L16701:  load constant 3
         load constant 14
         load constant 6
         jsb S16653
         go to cm_plus_2

L16706:  load constant 0
         load constant 14
         load constant 6
         load constant 4
         jsb S16646
         go to cm_plus_4

L16714:  load constant 11
         load constant 11
         load constant 8
         jsb S16651
         go to cm_plus_5

L16721:  load constant 3
         load constant 12
         load constant 7
         load constant 6
         load constant 4
         load constant 5
         load constant 4
         load constant 1
         load constant 1
         load constant 2
         load constant 2
         load constant 15
         p <- 12
         a - 1 -> a[xs]
         a -> rom address

; entry point called by code after L1266 in 19c.asm
S16740:  p <- 9
         if c[p] = 0
           then go to L17362
         c - 1 -> c[p]
         if c[p] = 0
           then go to L17370
         c + c -> c[p]
         if n/c go to L16754
         load constant 1
         p <- 3
         load constant 3
         return

L16754:  1 -> s 13
         return

         nop
         nop
         go to L16562

         go to L16773

         return

         go to L16600

         go to L16572

         go to L16604

L16766:  load constant 11
         load constant 14
         load constant 15
         jsb S16647
         go to cm_plus_1

L16773:  load constant 3
         load constant 11
         p <- 6
         c - 1 -> c[p]
         return

L17000:  load constant 9
         load constant 8
         load constant 4
         jsb S17344
         go to x_cm_plus_3

L17005:  load constant 4
         load constant 5
         load constant 5
         jsb S17344
         load constant 1
         load constant 12
         go to x_cm_plus_2

L17014:  p <- 10
         load constant 15
         load constant 6
         jsb S17345
         go to x_cm_plus_2

L17021:  p <- 10
         load constant 10
         load constant 7
         jsb S17345
         go to x_cm_plus_4

L17026:  load constant 6
         load constant 4
         load constant 4
         jsb S17344
         go to x_cm_plus_3

L17033:  load constant 0
         load constant 2
         load constant 3
         load constant 1
         go to L17212

; @17040
         go to L17242
         go to L17252
         go to L17026
         go to L17260
         go to L17014
         go to L17264
         go to L17021
         go to L17052
         go to L17033
         go to L17055

L17052:  p <- 10
         load constant 1
         go to L17315

L17055:  load constant 4
         load constant 5
         go to L17110

; @17060
         go to L17165
         go to L17005
         go to L17000
         go to L17072
         go to L17172
         go to L17214
         go to L17201
         go to L17312
         go to L17206
         go to L17106

L17072:  load constant 0
         load constant 6
         load constant 11
         load constant 10
         jsb S17344
         go to x_cm_plus_4

         go to m_lastx		; 0x2a - LASTx
         go to L17113
         return
         go to L17326
         go to L17335
         go to L17302

L17106:  load constant 4
         load constant 4
L17110:  load constant 7
         jsb S17346
         go to x_cm_plus_4

L17113:  p <- 10
         load constant 3
L17115:  p <- 4
         c - 1 -> c[p]
         return

; @17120
         go to m_pi		; 0x3a - pi
         go to L17317		; 0x3b - x<0?
         go to L17323
         go to L17325
         go to L17333
         go to L17232

m_op_3x: 0 -> c[w]
         delayed rom @14
         jsb S16103
         p <- 12
         shift left a[x]
         if 1 = s 11
           then go to L17147
         a -> rom address

m_op_2x: 0 -> c[w]
         p <- 6
         load constant 1
         load constant 6
         p <- 12
         shift left a[x]
         if 1 = s 11
           then go to L17147
         a -> rom address

L17147:  p <- 12
         load constant 9
         load constant 0
         load constant 2
         load constant 4
         p <- 4
         load constant 4
         load constant 1
         load constant 2
         load constant 6
         a + 1 -> a[xs]
         a + 1 -> a[xs]
         p <- 12
         a -> rom address

L17165:  load constant 5
         load constant 3
         load constant 7
         jsb S17343
         go to x_cm_plus_2

L17172:  p <- 10
         load constant 15
         load constant 6
L17175:  jsb S17345
         load constant 2
         load constant 2
         go to x_cm_plus_2

L17201:  p <- 10
         load constant 10
         load constant 7
         c + 1 -> c[xs]
         if n/c go to L17220
L17206:  load constant 13
         load constant 9
         load constant 0
         load constant 1
L17212:  jsb S17346
         go to x_cm_plus_3

L17214:  load constant 0
         load constant 6
         load constant 3
         load constant 12
L17220:  c + 1 -> c[xs]
         if n/c go to L17175

m_pi:    load constant 1	; Pi
         load constant 15		; 'i'
         load constant 4		; 'P'
         load constant 0
         jsb S17344
         load constant 0
         load constant 0
         go to x_cm_plus_1

L17232:  load constant 0
         load constant 12
         load constant 4
         load constant 6
         jsb S17344
         load constant 0
         load constant 0
         go to x_cm_plus_3

L17242:  load constant 5
         load constant 1
         load constant 3
         load constant 7
         jsb S17343
         load constant 1
         load constant 6
         go to x_cm_plus_2

L17252:  load constant 0
         load constant 7
         load constant 0
         load constant 15
         jsb S17344
         go to x_cm_plus_2

L17260:  load constant 5
         load constant 9
         jsb S17344
         go to x_cm_plus_4

L17264:  load constant 0
         load constant 6
         load constant 3
         load constant 12
         jsb S17345
         go to x_cm_plus_3

m_lastx: load constant 0	; LSTx
         load constant 7		; 'T'
         load constant 6		; 'S'
         load constant 1		; 'L'
         jsb S17344
         load constant 3
         load constant 4		; 'x'
         go to x_cm_plus_1

L17302:  load constant 0
         load constant 6
         load constant 5
         load constant 4
         jsb S17344
         load constant 1
         load constant 7
         go to x_cm_plus_3

L17312:  load constant 5
         load constant 9
         load constant 14
L17315:  jsb S17346
         go to x_cm_plus_2

L17317:  load constant 11
         load constant 0
         load constant 9
         go to L17115

L17323:  load constant 11
         return

L17325:  load constant 11
L17326:  p <- 10
         load constant 1
         p <- 4
         load constant 5
         return

L17333:  load constant 11
         go to L17336

L17335:  load constant 9
L17336:  load constant 0
         load constant 0
         p <- 4
         load constant 6
         return

S17343:  c + 1 -> c[m]
S17344:  c + 1 -> c[m]
S17345:  c + 1 -> c[m]
S17346:  c + 1 -> c[m]
         c + 1 -> c[m]
         c + 1 -> c[m]
         delayed rom @15
         go to L16654

         c + 1 -> c[m]
         c + 1 -> c[m]
x_cm_plus_4:  c + 1 -> c[m]
x_cm_plus_3:  c + 1 -> c[m]
x_cm_plus_2:  c + 1 -> c[m]
x_cm_plus_1:  c + 1 -> c[m]
         return

L17362:  p <- 10
         load constant 15
         load constant 10
         p <- 3
         load constant 5
         return

L17370:  p <- 10
         load constant 15
         load constant 2
         p <- 3
         load constant 9
         return

         nop
         nop

m_x_exch_y:
	 load constant 9
         load constant 0		; 'Y'
         load constant 7		; exch
         load constant 4		; 'X'
L17404:  jsb S17566
         go to xx_cm_plus_1

m_rdn:   load constant 2	; Rv
         load constant 14		; down arrow character
         load constant 5		; 'R'
         jsb S17566
         go to xx_cm_plus_2

L17413:  load constant 0
         load constant 7
         load constant 5
         load constant 4
         p <- 1
         load constant 3
         load constant 8
L17422:  p <- 6
         load constant 1
         load constant 6
         jsb S17563
         go to xx_cm_plus_5

L17427:  load constant 0
         load constant 14
         load constant 5
         load constant 4
         c + 1 -> c[m]
         p <- 1
         load constant 1
         load constant 2
         go to L17422

L17440:  load constant 11
         load constant 12
         load constant 8
         jsb S17564
         go to xx_cm_plus_5

m_deg:   load constant 0	; DEG
         load constant 2		; 'G'
         load constant 14		; 'E'
         c + 1 -> c[xs]
         load constant 13		; 'D'
         go to L17533

S17453:  if a[p] # 0
           then go to S17457
         load constant 14
         load constant 14
S17457:  shift right c[wp]
         load constant 14
         return

         c + 1 -> c[m]
xx_cm_plus_5:  c + 1 -> c[m]
xx_cm_plus_4:  c + 1 -> c[m]
xx_cm_plus_3:  c + 1 -> c[m]
xx_cm_plus_2:  c + 1 -> c[m]
xx_cm_plus_1:  c + 1 -> c[m]
         return

m_recip: load constant 14	; 1/x
         load constant 11		; '/'
         load constant 1		; '1'
         jsb S17561
         load constant 3
         load constant 4		; 'X'
         go to xx_cm_plus_4

; @17500
         go to m_x_exch_y	; 0x49 - x<>y
         go to m_rdn		; 0x4a - RDN
         go to L17413		; 0x4b - ???
L17503:  go to L17427		; 0x4c - ???
         go to L17440		; 0x4d - Sigma+
         go to m_deg		; 0x4f - DEG

m_dsz:   load constant 2	; DSZ
         load constant 5		; 'Z'
         load constant 6		; 'S'
         load constant 13		; 'D'
         jsb S17563
         go to xx_cm_plus_5

m_isz:   load constant 2	; ISZ
         load constant 5		; 'Z'
         load constant 6		; 'S'
         load constant 15		; 'I'
         jsb S17562
         go to xx_cm_plus_5

m_rtn:   p <- 10		; RTN
         load constant 7		; 'T'
         load constant 5		; 'R'
         jsb S17566
         go to xx_cm_plus_3

m_rad:   load constant 0	; RAD
         load constant 13		; 'D'
         load constant 10		; 'A'
         load constant 5		; 'R'
L17533:  p <- 6
         load constant 2
         load constant 5
         jsb S17565
         go to xx_cm_plus_3

; @17540
         go to m_percent	; 0x6a - %
         go to m_recip		; 0x6b - 1/x
         go to m_dsz		; 0x6c - DSZ
         go to m_isz		; 0x6d - ISZ
         go to m_rtn		; 0x6e - RTN

m_grad:  load constant 0	; 0x6f - GRAD
         load constant 10		; 'A'
         load constant 5		; 'R'
         load constant 2		; 'G'
         jsb S17565
         load constant 1
         load constant 13		; 'D'
         go to xx_cm_plus_2

m_percent:
         load constant 3	; %
         load constant 14
         load constant 8		; '%'
         go to L17404

S17561:  c + 1 -> c[m]
S17562:  c + 1 -> c[m]
S17563:  c + 1 -> c[m]
S17564:  c + 1 -> c[m]
S17565:  c + 1 -> c[m]
S17566:  c + 1 -> c[m]
         delayed rom @15
         go to L16654

; entry point called by subroutine at S1775 in 19c.asm
L17571:  1 -> s 11
         c -> a[w]
         shift left a[w]
         c - 1 -> c[s]
         if n/c go to L17600
L17576:  a exchange c[s]
         go to L17605

L17600:  if c[s] # 0
           then go to L17604
         0 -> s 11
         go to L17576

L17604:  c + 1 -> c[s]
L17605:  shift left a[w]
         shift left a[w]
         shift left a[w]
         a + 1 -> a[w]
         f exchange a[x]
         f -> a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
         a + 1 -> a[x]
         a exchange c[ms]
         if c[xs] # 0
           then go to L17663
         p <- 0
         load constant 14
         jsb S17741
         p <- 9
         f exchange a[x]
         if a[p] # 0
           then go to L17636
         jsb S17741
         jsb S17747
         p <- 1
         load constant 15
         load constant 11
         go to L17645

L17636:  p <- 0
         load constant 12
         p <- 9
         jsb S17750
         jsb S17741
         jsb S17745
         jsb S17747
L17645:  jsb S17741
         p <- 10
         jsb S17750
         jsb S17745
         p <- 13
         jsb S17741
         jsb S17750
         p <- 11
         jsb S17750
         jsb S17741
         jsb S17745
         p <- 12
         jsb S17745
         go to L17727

L17663:  p <- 9
         if a[p] # 0
           then go to L17674
         jsb S17741
         jsb S17747
         p <- 1
         load constant 14
         load constant 12
         go to L17701

L17674:  p <- 9
         jsb S17750
         jsb S17745
         jsb S17741
         jsb S17747
L17701:  p <- 10
         jsb S17750
         jsb S17741
         jsb S17745
         p <- 13
         jsb S17750
         jsb S17741
         p <- 11
         jsb S17750
         jsb S17745
         jsb S17741
         p <- 12
         jsb S17745
         p <- 9
         c -> a[p]
         jsb S17750
         jsb S17741
         jsb S17745
         p <- 11
         c -> a[p]
         a - 1 -> a[p]
         jsb S17745
L17727:  p <- 13
L17730:  load constant 15
         if p # 6
           then go to L17730
         if 1 = s 11
           then go to L17737
         load constant 7
         go to L17740

L17737:  load constant 11
L17740:  return

S17741:  a exchange c[w]
         shift left a[w]
         a exchange c[w]
         return

S17745:  load constant 1
         go to L17751

S17747:  p <- 12
S17750:  load constant 4
L17751:  p + 1 -> p
         go to L17754

L17753:  a + c -> c[x]
L17754:  a - c -> a[p]
         if n/c go to L17753
         a + c -> a[p]
         f exchange a[x]
         return

         0 -> a[w]
         a - 1 -> a[w]
         p <- 8
         c -> a[wp]
         a exchange c[w]
         p <- 4
         jsb S17457
         p <- 6
         jsb S17453
         p <- 8
         jsb S17453
         return

         nop
         nop
         nop

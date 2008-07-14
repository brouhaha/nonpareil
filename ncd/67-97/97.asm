; 97 ROM disassembly - quad 0 (@0000-@1777)
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

;Entry points:
;	clr_reg_x	(from common)
;	getpc	(from common)
;	incpc	(from common)
;	incpc9	(from common)
;	L0026	(from common)
;	sst	(from b1) - not referenced in 67
;	run_stop	(from common)
;	halt	(from common)
;	L0063	(from common)
;	L0073	(from common, b1q2)
;	L0074	(from common)
;	L0076	(from common)
;	L0100	(from common)
;	op_done_b	(from common)
;	op_done	(from common)
;	L0114	(from common)
;	L0124	(from common)
;	L0125	(from common, b1)
;	L0142   (from b1) - not referenced in 67
;	prt_prgm (from b1)
;	clr_prgm (from b1)
;	del_x   (from b1)
;	bst   (from b1)
;	L1367	(from common)
;	err0	(from common, b1)
;	L1373	(from common)
;	op_prstk	(from common)
;	op_preg	(from common)
;	op_space	(from common)
;	op_prtx	(from common)
;	L1545   (from b1) - not referenced in 67
;	L1554   (from b1) - not referenced in 67

; External references to common:
S2007	.equ	@2007
L2261	.equ	@2261
S2362	.equ	@2362
$over0	.equ	@2437
incpc0	.equ	@2660
L5616	.equ	@5616
del	.equ	@5717
execute	.equ	@6021
S7706	.equ	@7706

; External references to b1:

S3764	.equ	@3764
S3766	.equ	@3766
L3770	.equ	@3770
L3771	.equ	@3771	; not referenced in 67
S3775	.equ	@3775

; CRC flags:
buffer_ready  .equ 0
prog_mode     .equ 1
man_mode      .equ 2    ; printer mode MAN
norm_mode     .equ 3	; printer mode NORM
crc_f4        .equ 4    ; tied to KE keyboard return line
merge         .equ 5
pause         .equ 6
crc_f7        .equ 7    ; purpose unknown
crc_f8        .equ 8    ; purpose unknown
motor_on      .equ 9
card_present  .equ 10
write_mode    .equ 11

	.bank 0
	.org @0000	; From ROM/anode driver p/n 1818-0267

        delayed rom @01
        go to reset0

clr_reg_x:
	delayed rom @01
        go to clr_reg

; ------------------------------------------------------------------
; code matches 67 after this point
; ------------------------------------------------------------------

; get the PC value (and return stack) into c
getpc:  p <- 1
        load constant 3
        c -> data address
        register -> c 13
        return

; get the instruction at PC into A
get_inst:
	c -> a[x]
        c -> data address
        data -> c
        a exchange c[w]
L0015:  rotate left a
        rotate left a
        c - 1 -> c[xs]
        if n/c go to L0015
        return

incpc:  delayed rom @05
        go to incpc0

incpc9: c -> register 13
        return

L0026:  m2 exchange c
        delayed rom @04
        jsb S2007
        b exchange c[w]
        c -> a[s]
        a exchange c[w]
        go to op_done

sst:	1 -> s 1		; set SST flag
        jsb getpc
        if c[x] = 0
          then go to L0043
        if 0 = s 11
          then go to L0044
L0043:  jsb incpc
L0044:  0 -> s 13
        go to L0301


run_stop:
	if 1 = s 2		; running?
          then go to halt	;   yes, halt
        if 1 = s 1		; doing an SST?
          then go to op_done	;   yes, done
        1 -> s 2		; start running
        0 -> s 12
        jsb getpc		; at step 0?
        if c[x] # 0
          then go to L0060
        jsb incpc		;   yes, advance to step 1
L0060:  go to L0044


halt:   0 -> s 2		; halt with PC at next step
        jsb incpc
	
; reenter here from GTO/GSB
L0063:  1 -> s 9		; enable stack lift
L0064:  binary
        crc fs?c pause		; clear pause flag
        crc fs?c merge		; clear merge flag
        0 -> s 12
        delayed rom @02
        jsb clear_misc_flags
        go to L0135

L0073:  b exchange c[w]
L0074:  b -> c[w]
        1 -> s 9		; eanble stack lift
L0076:  0 -> s 12
        go to L0124

L0100:  0 -> s 9		; disable stack lift
        go to L0106

op_done_b:
	b exchange c[w]
op_done:
	1 -> s 9		; enable stack lift
        delayed rom @05
        jsb $over0
L0106:  b exchange c[w]
        if 0 = s 3
          then go to L0114
        jsb inc_pc_if_running
        0 -> s 2		; clear run
        0 -> s 1		; clear SST
L0114:  0 -> s 12

; ------------------------------------------------------------------
; code matches 67 before this point
; ------------------------------------------------------------------

        0 -> s 3		; check mode switches, print x if
        crc fs?c man_mode	;   in TRACE mode
        if 1 = s 3
          then go to L0124
        crc fs?c norm_mode
        if 0 = s 3
          then go to op_prtx

; ------------------------------------------------------------------
; code matches 67 after this point
; ------------------------------------------------------------------

L0124:  crc fs?c merge		; clear merge flag
L0125:  binary
        0 -> s 3
        delayed rom @02
        jsb clear_misc_flags
        crc fs?c pause		; test pause flag
        if 1 = s 3		; set?
          then go to L0240	;   yes
        jsb inc_pc_if_running
L0135:  b -> c[w]
        if 1 = s 2
          then go to L0213
        0 -> c[w]
        0 -> s 1
        0 -> s 3

; ------------------------------------------------------------------
; code matches 67 before this point
; ------------------------------------------------------------------

        pick key?		; check for key pressed
        if 1 = s 3
          then go to L0233

; ------------------------------------------------------------------
; code matches 67 after this point - addresses different
; ------------------------------------------------------------------

        0 -> c[s]
        m1 exchange c
        if 1 = s 11
          then go to L0301

L0152:  delayed rom @17
        jsb S7706
        a exchange b[w]
        a -> b[w]
        if 1 = s 12
          then go to L0162
        delayed rom @04
        jsb S2007
L0162:  delayed rom @02
        jsb S1017

; ------------------------------------------------------------------
; code matches 67 before this point - addresses different
; ------------------------------------------------------------------

L0164:  if 0 = s 5		; paper advance button pressed?
          then go to key_paper_adv	;   yes

; ------------------------------------------------------------------
; code matches 67 after this point - addresses different
; ------------------------------------------------------------------

        hi i'm woodstock
        display off
        display toggle

; ------------------------------------------------------------------
; code matches 67 before this point - addresses different
; this is the main wait-for-key loop
; ------------------------------------------------------------------

L0171:  crc fs?c man_mode	; reset MAN and NORM, hardware will
        crc fs?c norm_mode	;   set them appropriately
        nop

; ------------------------------------------------------------------
; code matches 67 after this point - address @0167
; ------------------------------------------------------------------

        0 -> s 3		; test pause flag
        crc fs?c pause
        if 1 = s 3		; set?
          then go to L0244	;   yes

        0 -> s 1

        crc fs?c prog_mode	; in program mode?
        if 1 = s 3
          then go to L0211

        if 0 = s 11
          then go to L0213
        0 -> s 11
        b exchange c[w]
        go to L0076

L0211:  if 0 = s 11
          then go to L0277

; ------------------------------------------------------------------
; code matches 67 before this point - addresses different
; ------------------------------------------------------------------

L0213:  0 -> s 5		; paper advance button pressed?
        if 0 = s 5
          then go to key_paper_adv	;   yes
	
        if 1 = s 2
          then go to L0266
L0220:  0 -> s 3		; card inserted?
        crc fs?c card_present
        if 1 = s 3
          then go to L1310

        pick key?		; check for key pressed
        if 0 = s 3
          then go to L0171
        display off
        0 -> s 3
        b exchange c[w]
        m1 exchange c
L0233:  a exchange c[w]
        p <- 1
        jsb get_pick_keycode
        delayed rom @07
        go to L3771

; ------------------------------------------------------------------
; code matches 67 after this point - addresses different
; ------------------------------------------------------------------

L0240:  0 -> c[w]
        m1 exchange c
        crc sf pause		; set pause flag again (was cleared in
				;   test after L0125)
        go to L0152


; here to process a pause
L0244:  crc sf pause		; set pause flag again (was cleared in
				;   test after L0171)
        p + 1 -> p		; increment pause counter 1

; 67 has four nop instructions inserted here

        if p # 13		; pause counter 1 at limit?
          then go to L0220	;   no, loop

        m1 exchange c		; get pause counter 2
        c + 1 -> c[s]		; increment pause counter 2
        if n/c go to L0257	;   not at limit

        crc fs?c pause		; at limit, clear pause flag
        m1 exchange c		; restore pause counter 2
        0 -> s 3
        go to op_done		; done with pause

L0257:  m1 exchange c		; restore pause counter 2
        go to L0220		; loop


; ------------------------------------------------------------------
; code matches 67 before this point
; ------------------------------------------------------------------

; get keycode from PICK
; assumes caller already checked that there is at least one keycode available
get_pick_keycode:
	0 -> c[w]
        c - 1 -> c[w]
        c -> data address
        register -> c 15
        return

L0266:  0 -> s 3
        pick key?		; check for key pressed
        if 0 = s 3
          then go to L0337
        go to L0274

L0273:  jsb inc_pc_if_running
L0274:  jsb get_pick_keycode
        0 -> s 2
        go to L0064


; ------------------------------------------------------------------
; code matches 67 after this point - addresses different (L0315)
; ------------------------------------------------------------------

L0277:  b exchange c[w]
        1 -> s 11
L0301:  jsb getpc
        delayed rom @01
        go to L0527

L0304:  jsb get_inst
        delayed rom @07
        jsb S3764
        delayed rom @01
        go to L0476

L0311:  if 1 = s 11
          then go to L0164
        b exchange c[w]
        jsb getpc
        if 1 = s 1
          then go to L0340
        if 1 = s 2
          then go to L0340
        go to L0063

; ------------------------------------------------------------------
; code matches 67 before this point - addresses different
; ------------------------------------------------------------------

insert:  0 -> s 3		; increment pc
        jsb incpc
        if 1 = s 3		; pc wrapped?
          then go to bst	;   yes
        delayed rom @13
        go to L5616

S0330:  0 -> s 3		; check for key pressed
        pick key?
        if 1 = s 3
          then go to L0273
        return

        jsb incpc
        0 -> s 2
L0337:  jsb getpc		; get PC
L0340:  jsb get_inst		; get instruction at PC
        display toggle
        a exchange c[w]		; store instruction into m1
        m1 exchange c

        0 -> s 3		; check printer mode
        crc fs?c man_mode
        if 1 = s 3
          then go to L1610
        crc fs?c norm_mode
        if 1 = s 3
          then go to L1610
	
; OK, were in trace mode

        jsb getpc		; get PC
        jsb get_inst		; get instruction at PC
        delayed rom @03
        go to L1724

prt_prgm:
        jsb getpc
        if c[x] # 0
          then go to L0367
L0362:  0 -> s 3
        jsb incpc
        if 1 = s 3
          then go to L0064
        jsb S0330
L0367:  jsb get_inst
        delayed rom @03
        go to L1714

; ------------------------------------------------------------------
; following code matches 67 at address S0116
; ------------------------------------------------------------------

inc_pc_if_running:
	if 1 = s 2		; running?
          then go to L0376	;   yes, increment pc
        if 0 = s 1		; SST?
          then go to L0377	;   no, don't increment pc
L0376:  go to incpc		; return via incpc

L0377:  return

; ------------------------------------------------------------------
; preceding code matches 67 at different address
; ------------------------------------------------------------------

        nop
reset0: go to reset1		; could have been a jsb

; ------------------------------------------------------------------
; following code almost matches 67 at address @1001
; ------------------------------------------------------------------

reset2: reset twf
        c -> data address
        clear data registers
        crc sf crc_f4
        p <- 1
        load constant 3
        c -> data address
        clear data registers
L0412:  register -> c 14
        if c[w] # 0
          then go to L0425
        0 -> c[w]
        p <- 7
        load constant 1		; RAD mode
        load constant 2		; 2 digits
        load constant 2		; FIX mode (22)
        load constant 2
        nop			; 67 doesn't have this nop
        c -> register 14
L0425:  jsb S0440
        p <- 1
        c + 1 -> c[p]
        c -> data address
        clear data registers
        c + 1 -> c[p]
        c -> data address
        clear data registers
        clear status
L0436:  delayed rom @00
        go to L0074

S0440:  delayed rom @00
        jsb getpc
        0 -> c[w]
        c -> register 13
        return

clr_reg:
	0 -> c[w]
        p <- 0
        jsb S0451
        go to L0436

S0451:  a exchange c[w]
        binary
        0 -> c[w]
        a - 1 -> a[p]
L0455:  a exchange c[w]
        c -> data address
        a exchange c[w]
        c -> data
        a - 1 -> a[p]
        if n/c go to L0455
        return

; ------------------------------------------------------------------
; preceding code matches 67 at different address
; ------------------------------------------------------------------

clr_prgm:
        0 -> c[w]
        p <- 1
        load constant 2
        jsb S0451
        p <- 1
        load constant 1
        jsb S0451
        jsb S0440
        c -> register 14
        go to L0412

L0476:  0 -> a[w]
        p <- 8
        c -> a[wp]
        m1 -> c
        jsb S0554
        p <- 5
        jsb S0554
        p <- 2
        load constant 15
        p <- 2
        jsb S0560
        a exchange c[w]

; ------------------------------------------------------------------
; following code matches 67 at @1105
; ------------------------------------------------------------------

        b exchange c[w]
        display off
        display toggle

L0515:  0 -> s 3		; wait for key release
L0516:  p - 1 -> p
        crc fs?c crc_f4
        if p # 5
          then go to L0516
        if 1 = s 3
          then go to L0515

        display off
L0525:  delayed rom @00
        go to L0311

; ------------------------------------------------------------------
; following code matches 67 at L1117
; ------------------------------------------------------------------

L0527:  delayed rom @04
        jsb S2362
        m1 -> c
        a exchange c[ms]
        if 1 = s 13
          then go to L0540
        0 -> c[x]
        delayed rom @02
        jsb clear_misc_flags
L0540:  m1 exchange c
        register -> c 13
        if c[x] # 0
          then go to L0304
        m1 -> c
        0 -> c[x]
        c - 1 -> c[x]
        a exchange c[w]
        a exchange c[x]
        b exchange c[w]
        0 -> b[w]
        go to L0525

; ------------------------------------------------------------------
; preceding code matches 67 at different address
; ------------------------------------------------------------------

S0554:  if a[p] # 0
          then go to S0560
        shift right a[wp]
        return

S0560:  shift right a[wp]
        p - 1 -> p
        load constant 8
        a exchange c[p]
        0 -> a[p]
        p + 1 -> p
        a - c -> c[p]
        if n/c go to L0573
        a exchange c[p]
        0 -> a[p]
        return

L0573:  0 -> a[p]
        p + 1 -> p
        c - 1 -> c[p]
        c -> a[p]
        return

del_x:  delayed rom @13
        go to del

; ------------------------------------------------------------------
; following code almost matches 67 at L0370
; clear C, M1, M2, and proceed with initialization
; ------------------------------------------------------------------

reset1: hi i'm woodstock
        0 -> c[w]
        m2 exchange c
        0 -> c[w]
        m1 exchange c
        0 -> c[w]
        go to reset2

; ------------------------------------------------------------------
; preceding code almost matches 67 at different address
; ------------------------------------------------------------------

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

; ------------------------------------------------------------------
; following code matches 67 at address S1143
; ------------------------------------------------------------------

S1000:  c -> a[x]
        if b[s] = 0
          then go to L1004
S1003:  a - 1 -> a[xs]
L1004:  p <- 12
        shift right c[wp]
L1006:  if c[xs] = 0
          then go to L1013
        shift right a[m]
        c - 1 -> c[xs]
        if n/c go to L1006
L1013:  shift right c[wp]
        shift right c[wp]
        shift right c[wp]
        return

S1017:  jsb S1000
        p <- 3
        shift left a[w]
        0 -> c[m]
L1023:  if c[s] = 0
          then go to L1031
        p + 1 -> p
        a - 1 -> a[p]
        c - 1 -> c[s]
        if n/c go to L1023
L1031:  if c[xs] = 0
          then go to L1036
        c - 1 -> c[xs]
        p + 1 -> p
        go to L1031

L1036:  shift right a[wp]
        load constant 3
        b exchange c[w]
        return


clear_misc_flags:
	0 -> s 4
        0 -> s 6
        0 -> s 7
        0 -> s 8
        0 -> s 10
        0 -> s 13
        return


S1051:  p <- 2
        load constant 6
        load constant 2
        c -> a[w]
        p <- 1
        load constant 3
        c -> data address
        register -> c 13
        if c[x] = 0
          then go to L1071
        c + 1 -> c[xs]
        if a >= c[xs]
          then go to L1100
        0 -> c[xs]
        c + 1 -> c[p]
        if n/c go to L1100
L1071:  p <- 1
L1072:  c + 1 -> c[p]
        if a >= c[p]
          then go to L1100
        0 -> c[p]
        if 1 = s 3
          then go to L1072
L1100:  c -> register 13
        return

; ------------------------------------------------------------------
; preceding code matches 67 at different address
; ------------------------------------------------------------------

prt_reg:  delayed rom @03
        jsb S1631
        1 -> s 8
        1 -> s 10
        0 -> c[w]
        p <- 12
        load constant 15
        load constant 14
        p <- 3
        load constant 9
        go to L1141

L1115:  m1 -> c
        c -> data address
        data -> c
        b exchange c[w]
        c -> data
        m1 -> c
        delayed rom @00
        jsb S0330
        p <- 3
        c - 1 -> c[p]
        if n/c go to L1136
        if 1 = s 13
          then go to L1710
        load constant 5
        p <- 12
        load constant 3
        1 -> s 13
L1136:  p <- 10
        c + 1 -> c[p]
        c + 1 -> c[w]
L1141:  c -> data address
        m1 exchange c
        data -> c
        b exchange c[w]
        c -> data
        m1 -> c
        delayed rom @03
        go to L1670

        delayed rom @04
        go to L2261

prstk:  delayed rom @03
        jsb S1631
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
        1 -> s 8
        delayed rom @03
        go to L1704

L1172:  0 -> s 3
        crc fs?c man_mode
        if 1 = s 3
          then go to L1177
        jsb S1266

; ------------------------------------------------------------------
; matches L1247 in 67:
; ------------------------------------------------------------------

L1177:  0 -> a[w]
        0 -> c[w]
        0 -> s 2		; halt
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
        m1 exchange c
        p <- 2
        load constant 4
L1221:  c - 1 -> c[x]
        if n/c go to L1221
        display toggle
        a exchange b[w]
        a - 1 -> a[p]
L1226:  delayed rom @00
        jsb get_pick_keycode
        a - 1 -> a[p]
        if n/c go to L1226
        a exchange b[w]
        display toggle
        m1 exchange c
        0 -> s 3
L1236:  crc fs?c prog_mode
        if 0 = s 3
          then go to L1250

        0 -> s 5		; paper advance button pressed?
        if 0 = s 5
          then go to L1257

        0 -> s 3		; check for key pressed
        pick key?
        if 0 = s 3
          then go to L1236

L1250:  crc fs?c prog_mode

        0 -> s 5		; paper advance button pressed?
        if 0 = s 5
          then go to L1257
	
        pick key?		; check for key pressed
        if 0 = s 3
          then go to L1250
	
L1257:  display toggle
        b exchange c[w]
        crc fs?c buffer_ready	; clear card reader buffer ready flag
        delayed rom @00		; discard keycode
        jsb get_pick_keycode
        delayed rom @00
        go to L0064

S1266:  0 -> c[w]
        binary
        p <- 11
        c - 1 -> c[w]
        load constant 14
        load constant 15
        load constant 11
        load constant 14
        load constant 15
        load constant 8
        load constant 5
        load constant 1
        load constant 4
        load constant 3
        load constant 1
        load constant 4
        delayed rom @03
        go to S1613

; ------------------------------------------------------------------
; code matches 67 at L1324
; ------------------------------------------------------------------

; card insertion detected in main loop

L1310:  jsb clear_misc_flags
        delayed rom @07
        go to L3770


L1313:  p <- 2			; wait for printer to home
        display off

L1315:  p + 1 -> p

L1316:  0 -> s 3
        pick print cr?
        if 1 = s 3
          then go to L1346
        c + 1 -> c[s]
        if n/c go to L1316

        if p # 2
          then go to L1315

        pick print cr?
        if 1 = s 3
          then go to L1346

        pick print home?
        if 1 = s 3
          then go to L1335

        go to L1315

L1335:  if 0 = s 8
          then go to L1177
        if 0 = s 10
          then go to L1346

        m1 -> c
        c -> data address
        data -> c
        b exchange c[w]
        go to L1177

L1346:  p <- 13
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

; ------------------------------------------------------------------
; code almost matches 67 after this point
; ------------------------------------------------------------------

bst:    1 -> s 3
L1367:  jsb S1051
        delayed rom @00
        go to L0044

err0:   b exchange c[w]
L1373:  go to L1172

op_prstk:
	go to prstk

op_preg:
	go to prt_reg

        nop
        nop

op_space:
	jsb S1631
        jsb S1442
        delayed rom @00
        go to L0124

op_prtx:
	crc fs?c crc_f8
        binary
        0 -> s 8
        0 -> c[w]
        c - 1 -> c[w]
        p <- 4
        jsb S1622
        p <- 2
        if 1 = s 12
          then go to L1421
        load constant 13
        load constant 13
        load constant 13
L1421:  jsb S1633
        0 -> s 6
L1423:  delayed rom @17
        jsb S7706
        a exchange b[w]
        a -> b[w]
        if 1 = s 12
          then go to L1433
L1431:  delayed rom @04
        jsb S2007
L1433:  jsb S1444
        if 1 = s 6
          then go to L1607
L1436:  0 -> s 12
        if 0 = s 8
          then go to L0124
        go to L1675

S1442:  delayed rom @02		; wait for printer to home
        go to L1313

S1444:  c -> a[x]
        delayed rom @02
        jsb S1003
        a exchange c[m]
        a exchange c[w]
        0 -> c[ms]
        c - 1 -> c[ms]
        p <- 0
        if a[p] # 0
          then go to L1464
        p <- 2
        if c[xs] = 0
          then go to L1541
        load constant 11
L1462:  jsb S1442
        pick print 3
L1464:  register -> c 14
        p <- 4
L1466:  shift right c[w]
        p - 1 -> p
        if p # 0
          then go to L1466
        if c[p] = 0
          then go to L1476
        if a[p] # 0
          then go to L1534
L1476:  a exchange c[m]
        0 -> c[s]
        p <- 13
        if b[s] = 0
          then go to L1543
        load constant 11
        go to L1510

L1505:  shift right c[w]
        p - 1 -> p
        c - 1 -> c[s]
L1510:  a - 1 -> a[s]
        if n/c go to L1505
        if p # 2
          then go to L1516
        p <- 4
        load constant 14
L1516:  p <- 1
L1517:  p + 1 -> p
        a - 1 -> a[xs]
        if n/c go to L1517
        shift right c[wp]
        load constant 10
        shift right c[w]
        c - 1 -> c[s]
        shift right c[w]
        jsb S1442
        pick print 3
        return

L1532:  a - 1 -> a[s]
        a + 1 -> a[xs]
L1534:  if a >= c[xs]
          then go to L1476
        if a[s] # 0
          then go to L1532
        go to L1476

L1541:  load constant 12
        go to L1462

L1543:  load constant 14
        go to L1510

; ------------------------------------------------------------------
; code matches 67 at L1755 - not used in 97?
; ------------------------------------------------------------------

        c - 1 -> c[xs]
        0 -> s 8
        b exchange c[w]
        m1 exchange c
        b exchange c[w]
        delayed rom @04
        go to L2261

; ------------------------------------------------------------------
; code matches 67 before this point
; ------------------------------------------------------------------
	
        c -> a[w]
        m1 exchange c
        delayed rom @02
        jsb clear_misc_flags
        if 1 = s 11		; program mode?
          then go to insert	;   yes, go insert the instruction
        if 1 = s 3
          then go to L1611

        crc fs?c man_mode	; MAN mode?
        if 1 = s 3
          then go to L1610	;   yes, don't print

        delayed rom @07		; decode keycode?
        jsb S3764
        delayed rom @07
        jsb S3775
        1 -> s 6
        jsb S1613
        if 1 = s 12
          then go to L1423
        0 -> s 3
        crc fs?c crc_f8
        if 1 = s 3
          then go to L1423
        p <- 2
        jsb S1622
        jsb S1442
        pick print 3
L1607:  0 -> s 6

L1610:  crc fs?c crc_f8
L1611:  delayed rom @14
        go to execute		; execute the instruction


S1613:  jsb S1442
        0 -> s 3
L1615:  pick print home?
        if 0 = s 3
          then go to L1615
        pick print 6
        return


S1622:  binary			; set up to print blanks using PRINT 3
        0 -> c[w]		; fill word with 'f' from 13..p+1, 
        c - 1 -> c[w]		;   and 'e' from p..0
L1625:  load constant 14
        if p # 13
          then go to L1625
        return

S1631:  p <- 7			; load c with 'fffffffeeeeeee'
        jsb S1622
S1633:  jsb S1442		; wait for printer to home
        0 -> s 3
L1635:  pick print home?
        if 0 = s 3
          then go to L1635
        pick print 3
        return

key_paper_adv:
	b exchange c[w]
        jsb S1631
        jsb S1442
        delayed rom @00
        go to L0135

L1647:  jsb S1442
        pick print 3
        if 0 = s 4
          then go to L1610
        0 -> s 3
        delayed rom @00
        go to L0362

L1656:  p <- 10
        b exchange c[w]
        down rotate
        down rotate
        down rotate
        b exchange c[w]
        0 -> c[wp]
        p <- 11
        shift right c[wp]
        load constant 14
L1670:  delayed rom @07
        jsb S3775
        jsb S1613
        1 -> s 8
        go to L1431

L1675:  if 1 = s 10
          then go to L1115
        m1 -> c
        c -> a[w]
        shift left a[m]
        shift left a[m]
        a exchange c[w]
L1704:  m1 exchange c
        m1 -> c
        if c[m] # 0
          then go to L1656
L1710:  jsb S1631
        0 -> s 8
        jsb S1442
        go to L1436

L1714:  0 -> a[xs]
        if a[x] # 0
          then go to L1723
        if 1 = s 6
          then go to L0064
        1 -> s 6
        go to L1724

L1723:  0 -> s 6
L1724:  crc fs?c man_mode
        delayed rom @07
        jsb S3764

        0 -> s 3
        crc fs?c man_mode
        if 1 = s 3
          then go to L1737
	
        delayed rom @07
        jsb S3775
        jsb S1613
        go to L1747

L1737:  delayed rom @07
        jsb S3766
        jsb S1633
        a exchange c[w]
        delayed rom @07
        jsb S3775
        jsb S1442
        pick print 6
L1747:  delayed rom @00
        jsb getpc
        delayed rom @04
        jsb S2362
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        a - 1 -> a[x]
        rotate left a
        a exchange b[x]
        a exchange c[w]
        go to L1647

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

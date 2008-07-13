; 67 ROM disassembly - quad 0 (@0000-@1777)
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$

	.arch woodstock

; Entry points:
;	clr_reg_x	(from common)
;	getpc	(from common)
;	incpc	(from common)
;	incpc9	(from common)
;	L0026	(from common)
;	run_stop	(from common)
;	halt	(from common)
;	L0063	(from common)
;	L0073	(from common, b1)
;	L0074	(from common)
;	L0076	(from common)
;	L0100	(from common)
;	op_done_b	(from common)
;	op_done	(from common)
;	L0114	(from common)
;	L0124	(from common)
;	L0125	(from common)
;	L0363	(from b1)

;	L1340	(from b1)
;	L1363	(from b1)

;	L1367	(from common)
;	err0	(from common, b1)
;	L1373	(from common)
;	op_prstk	(from common)
;	op_preg	(from common)
;	op_space	(from common)
;	op_prtx	(from common)

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

; External references to 67 bank 1:
S3764	.equ	@3764
L3766	.equ	@3766
L3767	.equ	@3767	; not referenced in 97
L3770	.equ	@3770
L3774	.equ	@3774	; not referenced in 97
L3775	.equ	@3775

; CRC flags:
buffer_ready  .equ 0
prog_mode     .equ 1
crc_f2        .equ 2    ; purpose unknown
crc_f3        .equ 3    ; not used in 67
default_fn    .equ 4	; used for entirely different purpose in 97
merge         .equ 5
pause         .equ 6
crc_f7        .equ 7    ; purpose unknown
crc_f8        .equ 8    ; purpose unknown
motor_on      .equ 9
card_present  .equ 10
write_mode    .equ 11

	.bank 0
	.org @0000	; From ROM/anode driver p/n 1818-0268

        nop
        go to reset0

clr_reg_x:
	delayed rom @02
        go to clr_reg

; ------------------------------------------------------------------
; code matches 97 after this point
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

sst:    1 -> s 1		; set SST flag
        jsb getpc
        if c[x] = 0
          then go to L0043
        if 0 = s 11
          then go to L0044
L0043:  jsb incpc
L0044:  0 -> s 13
        go to L0317


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
        1 -> s 9		; enable stack lift
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
; code matches 97 before this point
; ------------------------------------------------------------------

        go to L0124

; ------------------------------------------------------------------
; following code matches 97 at address S0372
; ------------------------------------------------------------------

inc_pc_if_running:
	if 1 = s 2		; running?
          then go to L0122	;   yes, increment pc
        if 0 = s 1		; SST?
          then go to L0123	;   no, don't increment pc
L0122:  go to incpc		; return via incpc

L0123:  return

; ------------------------------------------------------------------
; preceding code matches 97 at different address
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; code matches 97 after this point
; ------------------------------------------------------------------

L0124:  crc fs?c merge		; clear merge flag
L0125:  binary
        0 -> s 3
        delayed rom @02
        jsb clear_misc_flags
        crc fs?c pause		; test pause flag
        if 1 = s 3		; set?
          then go to L0257	;   yes
        jsb inc_pc_if_running
L0135:  b -> c[w]
        if 1 = s 2		; running?
          then go to L0304
        0 -> c[w]
        0 -> s 1
L0142:  0 -> s 3

; ------------------------------------------------------------------
; 97 has code inserted here to test and branch if key pressed
; following code matches 97 starting at address 0146
; ------------------------------------------------------------------

        0 -> c[s]
        m1 exchange c
        if 1 = s 11
          then go to L0317
L0147:  delayed rom @17
        jsb S7706
        a exchange b[w]
        a -> b[w]
        if 1 = s 12
          then go to L0157
        delayed rom @04
        jsb S2007
L0157:  delayed rom @02
        jsb S1162

; ------------------------------------------------------------------
; 97 has two instructions inserted at this point
; ------------------------------------------------------------------

L0161:  hi i'm woodstock
        display off
        display toggle

; ------------------------------------------------------------------
; code matches 97 before this point - addresses different
; ------------------------------------------------------------------

L0164:  0 -> s 15		; wait for key release
        if 1 = s 15
          then go to L0164

; ------------------------------------------------------------------
; code matches 97 after this point - addresses different
; ------------------------------------------------------------------

L0167:  0 -> s 3		; test pause flag
        crc fs?c pause
        if 1 = s 3		; set?
          then go to L0263	;   yes
        0 -> s 1
        crc fs?c prog_mode	; in program mode?
        if 1 = s 3
          then go to L0204
        if 0 = s 11
          then go to L0206
        0 -> s 11
        b exchange c[w]
        go to L0076

L0204:  if 0 = s 11
          then go to L0315

; ------------------------------------------------------------------
; code matches 97 before this point - addresses different
; ------------------------------------------------------------------

L0206:  0 -> s 3		; card inserted?
        crc fs?c card_present
        if 1 = s 3
          then go to L1324	;   yes

        if 0 = s 15		; if no key, loop
          then go to L0167
        display off
        b exchange c[w]
        crc sf crc_f2		; set F2, flag purpose unknown

        keys -> a		; get hardware keycode and remap
        0 -> c[x]
        a exchange c[xs]
        shift right a[x]
        p <- 0
        load constant 5
L0225:  a + c -> a[x]
        c - 1 -> c[xs]
        if n/c go to L0225
        a - c -> a[x]
        shift left a[x]

        0 -> c[x]		; prepare to add 0100, 0200, or 0300
        p <- 2			;   for offset to appropriate shifted
        load constant 4		;   key table

        0 -> s 3

        if 0 = s 4		; unshfited?
          then go to L0254	;    yes
        if 0 = s 6
          then go to L0254	;    yes

        a + c -> a[xs]
        if 1 = s 8		; h shift?
          then go to L0251
        a + c -> a[xs]
        if 1 = s 7		; g shift?
          then go to L0251
        a + c -> a[xs]

L0251:  m1 exchange c
        delayed rom @01
        a -> rom address	; shifted key tables:
				;   f 0705-0766
				;   g 0605-0666
				;   h 0505-0566

L0254:  m1 exchange c
        delayed rom @03
        a -> rom address	; unshifted key table 1405-1466

; ------------------------------------------------------------------
; code matches 97 after this point - addresses different
; ------------------------------------------------------------------

L0257:  0 -> c[w]
        m1 exchange c
        crc sf pause		; set pause flag again (was cleared in
				;   test after L0125)
        go to L0147


; here to process a pause
L0263:  crc sf pause		; set pause flag again (was cleared in
				;   test after L0167
        p + 1 -> p		; increment pause counter 1

; 97 does not have the following four nop instructions;
; possibly there were four instructions here in earlier revision
; of 67 code
        nop
        nop
        nop
        nop

        if p # 13		; pause counter 1 at limit?
          then go to L0206	;   no, loop

        m1 exchange c		; get pause counter 2
        c + 1 -> c[s]		; increment pause counter 2
        if n/c go to L0302	;   not at limit

        crc fs?c pause		; at limit, clear pause flag
        m1 exchange c		; restore pause counter 2
        0 -> s 3
        go to op_done		; done with pause

L0302:  m1 exchange c		; restore pause counter 2
        go to L0206		; loop


; ------------------------------------------------------------------
; code matches 97 before this point
; ------------------------------------------------------------------

L0304:  0 -> s 15		; key pressed?
        if 0 = s 15
          then go to L0353	;   no, clear F2 and continue running
	
        0 -> s 3		; test F2
        crc fs?c crc_f2
        if 1 = s 3
          then go to L0351	;   set, keep it set and continue running

        0 -> s 2		;   clear, halt
        go to L0064


; ------------------------------------------------------------------
; code matches 97 after this point - addresses different (L0277)
; ------------------------------------------------------------------

L0315:  b exchange c[w]
        1 -> s 11
L0317:  jsb getpc
        delayed rom @02
        go to L1117

L0322:  jsb get_inst
        delayed rom @07
        jsb S3764
        delayed rom @02
        go to L1077

L0327:  if 1 = s 11
          then go to L0161
        b exchange c[w]
        jsb getpc
        if 1 = s 1
          then go to L0355
        if 1 = s 2
          then go to L0355
        go to L0063

; ------------------------------------------------------------------
; code matches 97 before this point - addresses different
; ------------------------------------------------------------------

insert: 0 -> s 3		; increment pc
        jsb incpc
        if 1 = s 3		; pc wrapped?
          then go to bst	;   yes
        crc fs?c default_fn	; clear default function flag
        nop
        0 -> s 3
        delayed rom @13
        go to L5616


L0351:  crc sf crc_f2		; set f2, was cleared in code following L0304
        go to L0354

L0353:  crc fs?c crc_f2		; clear f2, purpose unknown
L0354:  jsb getpc		; get PC
L0355:  jsb get_inst		; get instruction at PC
        display toggle
        a exchange c[w]		; store instruction into m1
        m1 exchange c
        delayed rom @14		; execute instruction
        go to execute

L0363:  if 0 = s 8
          then go to L0124
        jsb inc_pc_if_running
        0 -> s 2
        go to L0064

; ------------------------------------------------------------------
; following code almost matches 97 at L0602
; clear C, M1, M2, and proceed with initialization
; ------------------------------------------------------------------

reset0: 0 -> c[w]
        m1 exchange c
        0 -> c[w]
        m2 exchange c
        0 -> c[w]
        delayed rom @02
        go to reset1

; ------------------------------------------------------------------
; preceding code almost matches 97 at different address
; ------------------------------------------------------------------

        nop

; addr 0400

        nop
op_2e:  c + 1 -> c[x]
op_2d:  c + 1 -> c[x]
        legal go to op_2c

op_3d:  c + 1 -> c[x]
op_3c:  c + 1 -> c[x]
op_3b:  c + 1 -> c[x]
op_3a:  c + 1 -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
op_37:  c + 1 -> c[x]
op_36:  c + 1 -> c[x]
op_35:  c + 1 -> c[x]
op_34:  c + 1 -> c[x]
op_33:  c + 1 -> c[x]
op_32:  c + 1 -> c[x]
op_31:  c + 1 -> c[x]
op_30:  load constant 3
        go to got_op

op_4e:  c + 1 -> c[x]
        c + 1 -> c[x]
op_4c:  c + 1 -> c[x]
        legal go to op_4b

op_48:  c + 1 -> c[x]
op_47:  c + 1 -> c[x]
op_46:  c + 1 -> c[x]
op_45:  c + 1 -> c[x]
op_44:  c + 1 -> c[x]
op_43:  c + 1 -> c[x]
        legal go to op_42

op_40:  load constant 4

; now we have a user opcode in C, do something with it
got_op: c -> a[w]
        m1 exchange c
        delayed rom @02
        jsb clear_misc_flags
        if 1 = s 11		; program mode?
          then go to insert	;   yes, go insert the instruction
        delayed rom @14		;   no, execute it immediately
        go to execute

L0447:  delayed rom @03
        go to L1747

L0451:  1 -> s 13
        delayed rom @00
        go to L0142

key_f_x:
	delayed rom @03
        go to key_f

key_g_x:
	delayed rom @03
        go to key_g

L0460:  delayed rom @03
        go to L1670

L0462:  delayed rom @03
        go to L1717

op_bst: delayed rom @02
        go to bst

del_x:  delayed rom @13
        go to del

L0470:  delayed rom @03
        go to L1421

op_clr_prgm_x:
	delayed rom @02
        go to op_clr_prgm

key_h_x:
	delayed rom @03
        go to key_h

        nop
        nop

; address 0500:

        go to L0533

        go to L0724

        go to L0532

        go to L0525

        go to L0526

; ------------------------------------------------------------------
; addresses 0505..0566:  h shifted key table
; ------------------------------------------------------------------

        go to key_h_x		; h-shifted key 35: h
        go to L0567		; h-shifted key 34: RC I
        go to L0572		; h-shifted key 33: ST I
        go to key_g_x		; h-shifted key 32: g
        go to key_f_x		; h-shifted key 31: f

op_22:  c + 1 -> c[x]
op_21:  c + 1 -> c[x]
op_20:  load constant 2
        go to got_op

        nop

        go to del_x		; h-shifted key 44: DEL
op_4b:  c + 1 -> c[x]		; h-shifted key 43: GRD (0x4b)
        c + 1 -> c[x]		; h-shifted key 42: RAD (0x4a)
        c + 1 -> c[x]		; h-shifted key 41: DEG (0x49)
        legal go to op_48

        go to op_47		; h-shifted key 54: R^
L0525:  go to op_31		; h-shifted key 53: Rv
L0526:  go to op_30		; h-shifted key 52: x<>y
        go to L0600		; h-shifted key 51: SF

        nop

        go to op_26		; h-shifted key 64: ABS
L0532:  go to op_06		; h-shifted key 63: y^x
L0533:  go to op_01		; h-shifted key 62: 1/x
        go to L0602		; h-shifted key 61: CF

        nop

        go to op_4e		; h-shifted key 74: REG
        go to op_48		; h-shifted key 73: Pi
        go to op_20		; h-shifted key 72: PAUSE
        go to L0574		; h-shifted key 71: F?

op_42:  c + 1 -> c[x]

        c + 1 -> c[x]		; h-shifted key 84: SPACE (0x41)
        legal go to op_40	; h-shifted key 83: H.MS+
        go to op_43		; h-shifted key 82: LSTx
        go to op_21		; h-shifted key 81: n!

L0547:  c + 1 -> c[x]
L0550:  c + 1 -> c[x]
L0551:  c + 1 -> c[x]
L0552:  load constant 5
        delayed rom @03
        go to L1472

        go to op_bst		; h-shifted key 25: BST
        go to op_46		; h-shifted key 24: x<>I
        go to op_33		; h-shifted key 23: ENG
        go to op_0e		; h-shifted key 22: RTN
        go to op_25		; h-shifted key 21: Sigma-

        c + 1 -> c[x]		; h-shifted key 15: ?
        c + 1 -> c[x]		; h-shifted key 14: ?
        c + 1 -> c[x]		; h-shifted key 13: ?
        c + 1 -> c[x]		; h-shifted key 12: ?
        legal go to L0460	; h-shifted key 11: ?

L0567:  load constant 7
L0570:  load constant 15
        go to got_op

L0572:  load constant 9
        go to L0570

L0574:  1 -> s 10
        load constant 5
L0576:  0 -> s 4
        go to L0451

L0600:  load constant 8
        go to L0576

L0602:  load constant 6
        go to L0576

        nop

; ------------------------------------------------------------------
; addresses 0605..0666:  g shifted key table
; ------------------------------------------------------------------

        go to key_h_x		; g-shifted key 35: h
        go to L0551		; g-shifted key 34: ISZ (i)
        go to L0547		; g-shifted key 33: DSZ (i)
        go to key_g_x		; g-shifted key 32: g
        go to key_f_x		; g-shifted key 31: f

op_2a:  c + 1 -> c[x]
op_29:  c + 1 -> c[x]
op_28:  c + 1 -> c[x]
op_27:  c + 1 -> c[x]
        legal go to op_26

        go to op_32		; g-shifted key 44: CLx
        c + 1 -> c[x]		; g-shifted key 43: unused, treat as EEX
        legal go to L0470	; g-shifted key 42: unused, treat as CHS
        go to op_45		; g-shifted key 41: MERGE

        nop

        go to op_02		; g-shifted key 54: x^2
        go to op_28		; g-shifted key 53: 10^x
        go to op_08		; g-shifted key 52: e^x
op_51:  c + 1 -> c[x]		; g-shifted key 51: x=y
        legal go to op_50

op_2c:  c + 1 -> c[x]		; g-shifted key 64: TAN^-1 (0x2c)
        c + 1 -> c[x]		; g-shifted key 63: COS^-1 (0x2b)
        legal go to op_2a	; g-shifted key 62: SIN^-1 (0x2a)

op_50:  load constant 5		; g-shifted key 61: x!=y (0x50)
        go to got_op

        go to op_3c		; g-shifted key 74: H->H.MS
        go to op_3a		; g-shifted key 73: D->R
        go to op_09		; g-shifted key 72: R->P
        c + 1 -> c[x]		; g-shifted key 71: x<=y (0x57)
        legal go to op_56

        go to op_42		; g-shifted key 84: STK
        go to op_2d		; g-shifted key 83: FRAC
        go to op_24		; g-shifted key 82: %CH
op_52:  c + 1 -> c[x]		; g-shifted key 81: x>y (0x52)
        legal go to op_51

op_26:  c + 1 -> c[x]
op_25:  c + 1 -> c[x]
op_24:  c + 1 -> c[x]
op_23:  c + 1 -> c[x]
        legal go to op_22

        go to L0700		; g-shifted key 25: LBL f
        go to L0462		; g-shifted key 24: ?
        go to op_36		; g-shifted key 23: SCI
        go to L0703		; g-shifted key 22: GSB f
        go to op_23		; g-shifted key 21: s

        c + 1 -> c[x]		; g-shifted key 15: ?
        c + 1 -> c[x]		; g-shifted key 14: ?
        c + 1 -> c[x]		; g-shifted key 13: ?
        c + 1 -> c[x]		; g-shifted key 12: ?
        legal go to L0460	; g-shifted key 11: ?

        nop
        nop
L0671:  load constant 15
L0672:  delayed rom @02
        jsb clear_misc_flags
        1 -> s 7
        go to L0451

L0676:  load constant 11
        go to L0672

L0700:  load constant 14
L0701:  0 -> s 4
        go to L0451

L0703:  load constant 10
        go to L0701

; ------------------------------------------------------------------
; addresses 0705..0766:  f shifted key table
; ------------------------------------------------------------------

        go to key_h_x		; f-shifted key 35: h
        go to L0552		; f-shifted key 34: ISZ
        go to L0550		; f-shifted key 33: DSZ
        go to key_g_x		; f-shifted key 32: g
        go to key_f_x		; f-shifted key 31: f

op_0a:  c + 1 -> c[x]
op_09:  c + 1 -> c[x]
op_08:  c + 1 -> c[x]
op_07:  c + 1 -> c[x]
        legal go to op_06

        go to op_clr_prgm_x	; f-shifted key 44: CL PRGM
        c + 1 -> c[x]		; f-shifted key 43: CL REG (0x4d)
        legal go to op_4c	; f-shifted key 42: P<>S
        go to op_44		; f-shifted key 41: W/DATA

        nop

L0724:  go to op_03		; f-shifted key 54: sqrt(x)
        go to op_27		; f-shifted key 53: LOG
        go to op_07		; f-shifted key 52: LN
op_54:  c + 1 -> c[x]		; f-shifted key 51: x=0 (0x54)
        legal go to op_53

op_0c:  c + 1 -> c[x]		; f-shifted key 64: TAN (0x0c)
        c + 1 -> c[x]		; f-shifted key 63: COS (0x0b)
        legal go to op_0a	; f-shifted key 62: SIN
op_53:  c + 1 -> c[x]		; f-shifted key 61: x!=0 (0x53)
        legal go to op_52

        go to op_3d		; f-shifted key 74: H<-H.MS
        go to op_3b		; f-shifted key 73: D<-R
        go to op_0d		; f-shifted key 72: R<-P
op_56:  c + 1 -> c[x]		; f-shifted key 71: x<0 (0x56)
        legal go to op_55

        go to op_35		; f-shifted key 84: PRTx
        go to op_29		; f-shifted key 83: INT
        go to op_04		; f-shifted key 82: %
op_55:  c + 1 -> c[x]		; f-shifted key 81: x>0 (0x55)
        legal go to op_54

        nop
op_0f:  c + 1 -> c[x]
op_0e:  c + 1 -> c[x]
op_0d:  c + 1 -> c[x]
        legal go to op_0c

        go to L0671		; f-shifted key 25: LBL
        go to op_2e		; f-shifted key 24: RND
        go to op_34		; f-shifted key 23: FIX
        go to L0676		; f-shifted key 22: GSB
        go to op_22		; f-shifted key 21: x bar (mean)

        c + 1 -> c[x]		; f-shifted key 15: e
        c + 1 -> c[x]		; f-shifted key 14: d
        c + 1 -> c[x]		; f-shifted key 13: c
        c + 1 -> c[x]		; f-shifted key 12: b
        legal go to L0447	; f-shifted key 11: a

op_06:  c + 1 -> c[x]
op_05:  c + 1 -> c[x]
op_04:  c + 1 -> c[x]
op_03:  c + 1 -> c[x]
op_02:  c + 1 -> c[x]
op_01:  c + 1 -> c[x]
        load constant 0
        go to got_op

        nop

; ------------------------------------------------------------------
; following code almost matches 97 at address @0402
; ------------------------------------------------------------------

reset1: hi i'm woodstock
        reset twf
        c -> data address
        clear data registers
        p <- 1
        load constant 3
        c -> data address
        clear data registers

; enter here from CLR PRGM operation

L1010:  register -> c 14	; is status reg zero (never been set)?
        if c[w] # 0
          then go to L1023	;   no, skip status reg init

        crc sf default_fn	; set CRC default function flag
        0 -> c[w]
        p <- 7
        load constant 1		; RAD mode
        load constant 2		; 2 digits
        load constant 2		; FIX mode (22)
        load constant 2
; 97 has nop here
        c -> register 14	; write status reg

L1023:  jsb S1036

        p <- 1			; clear program
        c + 1 -> c[p]
        c -> data address
        clear data registers
        c + 1 -> c[p]
        c -> data address
        clear data registers

        clear status
L1034:  delayed rom @00
        go to L0074

S1036:  delayed rom @00
        jsb getpc
        0 -> c[w]
        c -> register 13
        return


clr_reg:
	0 -> c[w]
        p <- 0
        jsb clr_16_reg
        go to L1034


; Clear a block of 16 registers, enter with addr 0xn0 in C,
; will clear 0xn0..0xnf.
clr_16_reg:
	a exchange c[w]
        binary
        0 -> c[w]
        a - 1 -> a[p]
L1053:  a exchange c[w]
        c -> data address
        a exchange c[w]
        c -> data
        a - 1 -> a[p]
        if n/c go to L1053
        return

; ------------------------------------------------------------------
; preceding code matches 97 at different address
; ------------------------------------------------------------------

op_clr_prgm:
	if 0 = s 11		; program mode?
          then go to L0125	;   no, don't clear
        0 -> c[w]
        crc sf default_fn	; set CRC default function flag

        p <- 1			; clear the program registers the hard way
        load constant 2		; (strange, we're going to do it again
        jsb clr_16_reg		;  later using "clear data registers")
        p <- 1
        load constant 1
        jsb clr_16_reg

        jsb S1036
        c -> register 14
        go to L1010


L1077:  a exchange c[w]
        m1 -> c
        p <- 10
        a exchange c[wp]
        a exchange c[w]
        0 -> c[w]

; ------------------------------------------------------------------
; following code matches 67 at @0512
; ------------------------------------------------------------------

        b exchange c[w]
        display off
        display toggle

        0 -> s 3		; wait for key release
L1111:  0 -> s 15
        if 1 = s 15
          then go to L1111

        display off
L1115:  delayed rom @00
        go to L0327

L1117:  delayed rom @04
        jsb S2362
        m1 -> c
        a exchange c[ms]
        if 1 = s 13
          then go to L1127
        0 -> c[x]
        jsb clear_misc_flags
L1127:  m1 exchange c
        register -> c 13
        if c[x] # 0
          then go to L0322
        m1 -> c
        0 -> c[x]
        c - 1 -> c[x]
        a exchange c[w]
        a exchange c[x]
        b exchange c[w]
        0 -> b[w]
        go to L1115

; ------------------------------------------------------------------
; preceding code matches 97 at different address
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; following code matches 67 at address S1000
; ------------------------------------------------------------------

S1143:  c -> a[x]
        if b[s] = 0
          then go to L1147
        a - 1 -> a[xs]
L1147:  p <- 12
        shift right c[wp]
L1151:  if c[xs] = 0
          then go to L1156
        shift right a[m]
        c - 1 -> c[xs]
        if n/c go to L1151
L1156:  shift right c[wp]
        shift right c[wp]
        shift right c[wp]
        return

S1162:  jsb S1143
        p <- 3
        shift left a[w]
        0 -> c[m]
L1166:  if c[s] = 0
          then go to L1174
        p + 1 -> p
        a - 1 -> a[p]
        c - 1 -> c[s]
        if n/c go to L1166
L1174:  if c[xs] = 0
          then go to L1201
        c - 1 -> c[xs]
        p + 1 -> p
        go to L1174

L1201:  shift right a[wp]
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


S1214:  p <- 2
        load constant 6
        load constant 2
        c -> a[w]
        p <- 1
        load constant 3
        c -> data address
        register -> c 13
        if c[x] = 0
          then go to L1234
        c + 1 -> c[xs]
        if a >= c[xs]
          then go to L1243
        0 -> c[xs]
        c + 1 -> c[p]
        if n/c go to L1243
L1234:  p <- 1
L1235:  c + 1 -> c[p]
        if a >= c[p]
          then go to L1243
        0 -> c[p]
        if 1 = s 3
          then go to L1235
L1243:  c -> register 13
        return

; ------------------------------------------------------------------
; preceding code matches 97 at different address
; ------------------------------------------------------------------

        delayed rom @04
        go to L2261

; ------------------------------------------------------------------
; matches L1177 in 97:
; ------------------------------------------------------------------

L1247:  0 -> a[w]
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
L1271:  c - 1 -> c[x]
        if n/c go to L1271
        display toggle
L1274:  c - 1 -> c[wp]
        if n/c go to L1274
        display toggle
L1277:  0 -> s 15
        if 1 = s 15
          then go to L1277
        m1 exchange c
L1303:  0 -> s 3		; in program mode?
        crc fs?c prog_mode
        if 0 = s 3
          then go to L1312
        0 -> s 3
        if 0 = s 15
          then go to L1303

L1312:  crc fs?c prog_mode	; in program mode?
        if 1 = s 15
          then go to L1317
        if 0 = s 3
          then go to L1312

L1317:  display toggle
        b exchange c[w]
        crc fs?c buffer_ready	; clear card reader buffer ready flag
        delayed rom @00
        go to L0064

; ------------------------------------------------------------------
; code matches 97 at L1310
; ------------------------------------------------------------------

; card insertion detected in main loop

L1324:  jsb clear_misc_flags
        delayed rom @07
        go to L3770


prstk:  1 -> s 6
        down rotate
        down rotate
        down rotate
        b exchange c[w]
        0 -> c[w]
        p <- 0
        load constant 3
        m1 exchange c
        0 -> s 12
prtx:   binary
        display off
        delayed rom @17
        jsb S7706
        a exchange b[w]
        a -> b[w]
        if 1 = s 12
          then go to L1353
        delayed rom @04
        jsb S2007
L1353:  jsb S1162
        display toggle
        m1 exchange c
        if 1 = s 4
          then go to L1764
        if 1 = s 6
          then go to L1766
        delayed rom @07
        go to L3766

        nop
        nop

; ------------------------------------------------------------------
; code almost matches 97 after this point
; ------------------------------------------------------------------

bst:    1 -> s 3
L1367:  jsb S1214
        delayed rom @00
        go to L0044

err0:   b exchange c[w]
L1373:  go to L1247

op_prstk:
	go to prstk

op_preg:
	delayed rom @07
        go to L3775

        nop

op_space:
	delayed rom @00
        go to L0124

prtx_x:
	delayed rom @02
        go to prtx

op_prtx:
	go to prtx_x

; ------------------------------------------------------------------
; addresses 1405-1466: unshifted key table 
; ------------------------------------------------------------------

        go to key_h		; unshifted key 35: h
        go to key_rcl		; unshifted key 34: RCL
        go to key_sto		; unshifted key 33: STO
        go to key_g		; unshifted key 32: g
        go to key_f		; unshifted key 31: f

L1412:  c + 1 -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
        if n/c go to L1637

        go to L1504		; unshifted key 44: CLx
L1420:  c + 1 -> c[x]		; unshifted key 43: EEX
L1421:  c + 1 -> c[x]		; unshifted key 42: CHS
        if n/c go to L1451	; unshifted key 41: ENTER^

        nop

        c + 1 -> c[x]		; unshifted key 54: 9
        c + 1 -> c[x]		; unshifted key 53: 8
        if n/c go to L1430	; unshifted key 52: 7
        go to L1547		; unshifted key 51: -

L1430:  c + 1 -> c[x]

        c + 1 -> c[x]		; unshifted key 64: 6
        c + 1 -> c[x]		; unshifted key 63: 5
        if n/c go to L1412	; unshifted key 62: 4
        go to L1530		; unshifted key 61: +

        nop

        c + 1 -> c[x]		; unshifted key 74: 3
        c + 1 -> c[x]		; unshifted key 73: 2
        if n/c go to L1612	; unshifted key 72: 1
        go to L1544		; unshifted key 71: *

        nop

        go to L1506		; unshifted key 84: R/S
        go to L1624		; unshifted key 83: .
        go to L1613		; unshifted key 82: 0
        go to L1552		; unshifted key 81: /

L1447:  c + 1 -> c[x]
        if n/c go to L1420
L1451:  c + 1 -> c[x]
L1452:  load constant 1
        go to L1474

        nop

        go to sst_x		; unshifted key 25: SST
        go to L1713		; unshifted key 24: (i)
        go to L1510		; unshifted key 23: DSP
        go to L1513		; unshifted key 22: GTO
        go to L1520		; unshifted key 21: Sigma+

        c + 1 -> c[x]		; unshifted key 15: E (default fcn x<>y)
        c + 1 -> c[x]		; unshifted key 14: D (default fcn RDN)
        c + 1 -> c[x]		; unshifted key 13: C (default fcn y^x)
        c + 1 -> c[x]		; unshifted key 12: B (default fcn sqrt(x))
        if n/c go to L1660	; unshifted key 11: A (default fcn 1/x)

L1467:  c + 1 -> c[x]
L1470:  c + 1 -> c[x]
        c + 1 -> c[x]
L1472:  c + 1 -> c[x]
        c + 1 -> c[x]
L1474:  c + 1 -> c[x]
        c + 1 -> c[x]
L1476:  p <- 8
L1477:  c + 1 -> c[x]
        p - 1 -> p
        if p # 0
          then go to L1477
        go to L1566

L1504:  delayed rom @01
        go to op_32

L1506:  load constant 0
        go to L1566

L1510:  jsb S1740
        load constant 6
        go to L1570

L1513:  jsb S1740
        1 -> s 7
        1 -> s 10
        load constant 13
        go to L1570

L1520:  if 0 = s 4
          then go to op_05
        if 0 = s 10
          then go to op_05
        delayed rom @01
        go to op_0f

sst_x:  delayed rom @00
        go to sst

L1530:  load constant 12
L1531:  p + 1 -> p
        if 0 = s 4
          then go to op_37
        if 0 = s 7
          then go to op_37
        if 1 = s 8
          then go to op_37
L1540:  1 -> s 8
        p - 1 -> p
        load constant 0
        go to L1570

L1544:  load constant 14
        c + 1 -> c[x]
        if n/c go to L1550
L1547:  load constant 10
L1550:  c + 1 -> c[x]
        if n/c go to L1531
L1552:  if 0 = s 4
          then go to L1447
        if 0 = s 7
          then go to L1447
        if 1 = s 6
          then go to L1447
        load constant 8
        go to L1540

key_rcl:
	jsb S1740
        load constant 7		; MSD of RCL is 7
        1 -> s 10
        go to L1711

L1566:  delayed rom @01
        go to got_op

L1570:  delayed rom @01
        go to L0451

key_f:  if 1 = s 4
          then go to L1600
        if 1 = s 6
          then go to L1600
        jsb S1741
        go to L1601

L1600:  jsb S1740
L1601:  1 -> s 4
        1 -> s 6
        go to L1570

key_g:  jsb S1740
        1 -> s 7
        go to L1601

key_h:  jsb S1740
        1 -> s 8
        go to L1601

L1612:  c + 1 -> c[x]
L1613:  if 1 = s 4
          then go to L1654
        if 0 = s 6
          then go to L1643
        if 1 = s 7
          then go to L1656
        if 1 = s 10
          then go to L1476
        go to L1474

L1624:  if 1 = s 4
          then go to L1452
        if 1 = s 6
          then go to L1452
        if 0 = s 10
          then go to L1452
        1 -> s 8
        p <- 2
        load constant 15
        load constant 15
        go to L1570

L1637:  if 1 = s 4
          then go to L1654
        if 1 = s 6
          then go to L1656
L1643:  if 0 = s 8
          then go to L1654
        c + 1 -> c[xs]
        if c[xs] # 0
          then go to L1755
        a exchange c[w]
        shift left a[x]
        a exchange c[w]
        go to L1570

L1654:  if c[p] # 0
          then go to L1566
L1656:  load constant 1
        go to L1566

L1660:  if 1 = s 8
          then go to L1670
        if 1 = s 7
          then go to L1474
        if 1 = s 6
          then go to L1670
        if 1 = s 10
          then go to L1474
L1670:  0 -> s 3
        crc fs?c default_fn	; default functions enabled?
        if 1 = s 3		;   yes
          then go to L1676
        load constant 11
        go to L1474

; here when A-E are pressed and default function flag was set
L1676:  load constant 4
        p <- 1
        crc sf default_fn	; set default function flag again
        c -> a[x]
        shift left a[x]
        0 -> c[x]
        delayed rom @01
        a -> rom address	; @0400-0777?

key_sto:
	jsb S1740
        load constant 9		; MSD of STO is 9
        1 -> s 7
L1711:  1 -> s 4
        go to L1570

L1713:  if 1 = s 4
          then go to L1721
        if 0 = s 6
          then go to L1727
L1717:  load constant 3
        go to L1467

L1721:  if 1 = s 8
          then go to L1467
        load constant 3
        if 1 = s 10
          then go to L1467
        go to L1470

L1727:  if c[p] = 0
          then go to L1717
        c + 1 -> c[p]
        if n/c go to L1734
        go to L1717

L1734:  c - 1 -> c[p]
        if 1 = s 8
          then go to L1717
        go to L1467

S1740:  0 -> s 10
S1741:  0 -> s 4
        0 -> s 6
        0 -> s 7
        0 -> s 8
        0 -> s 13
        return

L1747:  if 1 = s 10
          then go to L1753
        load constant 10
        go to L1474

L1753:  load constant 12
        go to L1474

; ------------------------------------------------------------------
; code matches 97 at L1545
; ------------------------------------------------------------------

L1755:  c - 1 -> c[xs]
        0 -> s 8
        b exchange c[w]
        m1 exchange c
        b exchange c[w]
        delayed rom @04
        go to L2261

; ------------------------------------------------------------------
; code matches 97 before this point
; ------------------------------------------------------------------

L1764:  delayed rom @07
        go to L3774

L1766:  delayed rom @07
        go to L3767

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

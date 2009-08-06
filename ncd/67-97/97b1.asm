; 97 ROM disassembly - bank 1
; Copyright 2007, 2008, 2009 Eric Smith <eric@brouhaha.com>
; $Id$
;
	.arch woodstock

; External references:
sst	.equ	@0035
L0073	.equ	@0073
L0125	.equ	@0125
L0142	.equ	@0142
prt_prgm .equ	@0357
clr_prgm .equ	@0464
del_x	.equ	@0600
bst	.equ	@1366
err0	.equ	@1372
L1545	.equ	@1545
L1554	.equ	@1554

; CRC flags:
buffer_ready  .equ 0
prog_mode     .equ 1
trace_mode    .equ 2    ; printer mode TRACE
norm_mode     .equ 3	; printer mode NORM
crc_f4        .equ 4
merge         .equ 5
pause         .equ 6
crc_f7        .equ 7    ; purpose unknown
crc_f8        .equ 8    ; purpose unknown
motor_on      .equ 9
card_present  .equ 10
write_mode    .equ 11

	.bank 1
	.org @2000	; from ROM/RAM p/n 1818-0229

; bank 1 quad 1: printer mnemonics

; addr 12000: mnemonic table, high digit
        go to m_op_0x
        go to m_op_1x
        go to m_op_2x
        go to m_op_3x
        go to m_op_4x
        go to m_op_5x
        go to m_op_6x	; DSP n, CF n, spare, DSP (i)
        go to m_op_7x	; RCL n, RCL A-E, RCL I
        go to m_op_8x	; STO div 0-9, SF n, spare, STO div i
        go to m_op_9x	; STO 0-9, STO A-E, STO I
        go to m_op_ax	; STO - 0-9, GSB f a-e, STO - (i)
        go to m_op_bx	; GSB 0-9, GSB A-E, GSB (i)
        go to m_op_cx	; STO + 0-9, GTO f a-e, STO + (i)
        go to m_op_dx	; GTO 0-9, GTO A-E, GTO (i)
        go to m_op_ex	; STO * 0-9, LBL f a-e, STO * (i)

m_op_fx:		; LBL 0-9, LBL A-E, spare
        jsb m_lbl_common
        p <- 6
        load constant 2
        load constant 1
        jsb S12061
        p <- 13
        load constant 1
        go to L12060

m_op_4x:
	p <- 6
        load constant 1
        load constant 6
m_op_3x:
	p <- 3
        load constant 8
        p <- 12

        shift left a[x]			; table at %13000 (30 at 13060, etc.)
        delayed rom @06
        a -> rom address

m_op_5x:
	load constant 9
        load constant 0
        load constant 0
        load constant 4
        p <- 6
        load constant 1
        load constant 6
        load constant 11
        load constant 0
        load constant 2
        load constant 6
        p <- 10
        shift left a[x]
        delayed rom @07
        a -> rom address	; table at %13520

L12057:  0 -> c[s]
L12060:  return

S12061:  p <- 3
        shift left a[wp]
        a exchange c[x]
        c -> a[x]
        shift left a[wp]
        shift left a[wp]
        a exchange c[p]
        c -> a[x]
        shift left a[x]
        p <- 2
        load constant 10
        a - c -> c[xs]
        if n/c go to L12102
        p <- 2
        load constant 4
        c + 1 -> c[s]
        return

L12102:  p <- 4
        a + 1 -> a[xs]
        if n/c go to L12112
        load constant 4
        load constant 5
        load constant 2
        c - 1 -> c[s]
        return

L12112:  load constant 1
        a exchange c[p]
        load constant 9
        load constant 1
        p <- 3
        a - c -> c[p]
        return

m_op_9x:
	load constant 0			; char 0x03 = 'O'
        load constant 3
        jsb m_sto_common		; get "ST"
        p <- 8
        shift right c[wp]
        shift right c[wp]
L12127:  jsb S12061
        c + 1 -> c[s]
        if n/c go to L12057
        c - 1 -> c[xs]
        c + 1 -> c[m]
        if n/c go to L12057

m_op_8x:
	load constant 2			; char 0x2c = divide symbol
        load constant 12
        jsb m_sto_common		; get "ST"
        load constant 10
        load constant 4
        jsb S12061
        if c[s] # 0
          then go to L12057

        p <- 12				; SF 0-3
        load constant 1				; character 0x15 = 'F'
        load constant 5
        load constant 6				; character 0x06 = 'S'
        jsb S12234
        load constant 1
        go to m_flag_common

m_op_ax:
	load constant 3				; character 0x3b = '-'
        load constant 11
        jsb m_sto_common		; get "ST"
        load constant 12
        load constant 5
        jsb S12061
        if c[s] # 0
          then go to L12057

        p <- 12				; GSB a-e
        jsb m_gsb_common
        load constant 2
        load constant 3
        go to lc_suffix

m_op_cx:
	load constant 3			; char 0x3c = '+'
        load constant 12
        jsb m_sto_common		; get "ST"
        load constant 13
        load constant 5
        jsb S12061
        if c[s] # 0
          then go to L12057

        p <- 12				; GTO a-e
        jsb m_gto_common
        load constant 2
        load constant 2
        go to lc_suffix

m_op_ex:
	load constant 2			; char 0x2f = multiply symbol
        load constant 15
        jsb m_sto_common		; get "ST"
        load constant 11
        load constant 5
        jsb S12061
        if c[s] # 0
          then go to L12057

        p <- 12				; LBL a-e
        jsb m_lbl_common
        load constant 2
        load constant 1
        c + 1 -> c[s]
lc_suffix:
	load constant 1
        load constant 6
        c + 1 -> c[xs]
        if n/c go to L12060

m_sto_common:
	load constant 7			; 'T'
        load constant 6			; 'S'
        load constant 3
        load constant 5
        return

S12234:  load constant 0
        load constant 1
        load constant 6
        load constant 2
        return

m_op_dx:
	jsb m_gto_common
        p <- 6
        load constant 2
        load constant 2
L12245:  jsb S12061
        go to L12057

m_op_bx:
	jsb m_gsb_common
        p <- 6
        load constant 2			; character 0x02 = 'G'
        load constant 3
        go to L12245

m_gto_common:
        load constant 0
        load constant 3			; character 0x03 = 'O'
        load constant 7			; character 0x07 = 'T'
L12257: load constant 2
        return

m_gsb_common:
        load constant 0
        load constant 11		; character 0x0b = 'B'
        load constant 6			; character 0x06 = 'S'
        go to L12257

m_op_7x:
	load constant 0
        load constant 1			; 'L'
        load constant 12		; 'C'
        load constant 5			; 'R'
        p <- 6
        load constant 3
        load constant 6
        go to L12127

m_op_6x:
	load constant 0
        load constant 4			; 'P'
        load constant 6			; 'S'
        load constant 13		; 'D'
        p <- 6
        load constant 14
        load constant 3
        jsb S12061
        if c[s] # 0
          then go to L12057

        p <- 12				; CF 0-3
        load constant 1				; character 0x15 = 'F'
        load constant 5
        load constant 12			; character 0x0c = 'C'
        jsb S12234
        load constant 2
m_flag_common:
	load constant 0
        c - 1 -> c[p]
        a exchange c[x]
        p <- 2
        load constant 4
        load constant 10
        p <- 1
        a - c -> c[p]
        if n/c go to L12057

m_op_1x:
	load constant 15
        load constant 14
        load constant 14
        jsb S12061
        c - 1 -> c[s]
        c - 1 -> c[s]
        if n/c go to L12336
        go to L12057

L12336:  0 -> a[x]
        0 -> c[ms]
        p <- 3
        load constant 8
        load constant 3
        a exchange c[x]
        shift right a[x]
        go to m_op_0x

; decode opcode to mnemonic - dispatch high digit via table @12000
m_decode:  0 -> c[w]
        p <- 12
        0 -> a[xs]
        a -> rom address

m_lbl_common:
        load constant 0
        load constant 1			; character 0x01 = 'L'
        load constant 11		; character 0x0b = 'B'
        load constant 1			; character 0x01 = 'L'
        return

L12357:  load constant 1
        load constant 12
        load constant 5
        p <- 6
        load constant 3
        load constant 6
L12365:  load constant 4
        load constant 5
        load constant 2
        load constant 15
        return

m_op_2x:
	p <- 6
        load constant 1
        load constant 6

m_op_0x:
	p <- 12
        shift left a[x]
        a -> rom address

; addr 12400: mnemonic table 0x
        go to m_rs
        go to m_recip
        go to m_square
        go to m_sqrt
        go to m_percent
        go to m_sigma_plus
        go to m_y_to_x
        go to m_ln
        go to m_exp
        go to m_r_to_p
        go to m_sin
        go to m_cos
        go to m_tan
        go to m_p_to_r
        go to m_rtn

m_rcl_sigma:
        load constant 0
        load constant 1			; 'L'
        load constant 12		; 'C'
        load constant 5			; 'R'
        p <- 6
        load constant 3
        load constant 6
        jsb S12504
        load constant 3
        load constant 8
        go to cm_plus_6

m_eex:  load constant 2		; EEX
        load constant 4			; 'X'
        load constant 14		; 'E'
        load constant 14		; 'E'
        jsb S12507
        go to cm_plus_3

; addr 12440: mnemonic table 2x
        go to m_pse
        go to m_factorial
        go to m_mean
        go to m_s
        go to m_percent_change
        go to m_sigma_minus
        go to m_abs
        go to m_log10
        go to m_10_to_x
        go to m_int
        go to m_asin
        go to m_acos
        go to m_atan
        go to m_frac

m_rnd:
        load constant 0
        load constant 13		; character 0x0d = 'D'
        load constant 0			; character 0x00 = 'N'
        load constant 5			; character 0x05 = 'R'
        jsb S12507
        go to cm_plus_4

m_int:  load constant 0
        load constant 7			; character 0x07 = 'T'
        load constant 0			; character 0x00 = 'N'
        load constant 15		; character 0x0f = 'I'
        jsb S12506
        go to cm_plus_4

        go to m_decimal		; 0x1a decimal
        go to m_enter		; 0x1b ENT^
        go to m_chs		; 0x1c CHS
        go to m_eex		; 0x1d EEX

        load constant 11	; 0x1e divide
        load constant 14
        load constant 12
        jsb S12507
        go to cm_plus_4

S12503:  c + 1 -> c[m]
S12504:  c + 1 -> c[m]
S12505:  c + 1 -> c[m]
S12506:  c + 1 -> c[m]
S12507:  c + 1 -> c[m]
        c + 1 -> c[m]
L12511:  p <- 4
        a exchange c[w]
        shift left a[wp]
        a exchange c[w]
        p <- 2
        return

m_sigma_minus:
	load constant 11
        load constant 11		; character 0x3b = '-'
        load constant 8			; character 0x28 = sigma
        jsb S12504

cm_plus_6:  c + 1 -> c[m]
cm_plus_5:  c + 1 -> c[m]
cm_plus_4:  c + 1 -> c[m]
cm_plus_3:  c + 1 -> c[m]
cm_plus_2:  c + 1 -> c[m]
cm_plus_1:  c + 1 -> c[m]
        return

m_percent_change:
	load constant 1
        load constant 3			; character 0x13 = 'H'
        load constant 12		; character 0x0c = 'C'
        load constant 8			; character 0x08 = '%'
        jsb S12504
        go to cm_plus_5

m_abs:  load constant 0
        load constant 6			; character 0x06 = 'S'
        load constant 11		; character 0x0b = 'B'
        load constant 10		; character 0x0a = 'A'
        jsb S12506
        go to cm_plus_1

m_rs:   load constant 2			; char 0x2b = '/'
        load constant 11
        load constant 5			; 'R'
        jsb S12504
        load constant 1
        load constant 6			; 'S'
        go to cm_plus_1

m_y_to_x:
	load constant 5
        load constant 9			; character 0x19 = superscript 'x'
        load constant 0			; character 0x10 = 'Y'
        jsb S12506
        go to cm_plus_1

m_ln:   load constant 0
        load constant 0			; character 0x00 = 'N'
        load constant 1			; character 0x01 = 'L'
        jsb S12506
        go to cm_plus_2

m_exp:  load constant 5
        load constant 9			; character 0x19 = superscript 'x'
        load constant 14		; character 0x1e = 'e'
        jsb S12506
        go to cm_plus_3

m_r_to_p:
	load constant 4
        load constant 4			; character 0x04 = 'P'
        load constant 7			; character 0x17 = right arrow
        jsb S12506
        go to cm_plus_4

m_asin: jsb S12626
m_sin:  load constant 0
        load constant 0			; 'N'
        load constant 15		; 'I'
        load constant 6			; 'S'
        jsb S12505
        go to cm_plus_1

m_acos: jsb S12626
m_cos:  load constant 0
        load constant 6			; 'S'
        load constant 3			; 'O'
        load constant 12		; 'C'
        jsb S12505
        go to cm_plus_2

m_atan: jsb S12626
m_tan:  load constant 0
        load constant 0			; 'N'
        load constant 10		; 'A'
        load constant 7			; 'T'
        jsb S12505
        go to cm_plus_3

S12626:  p <- 1
        load constant 2
        load constant 2
        p <- 12
        return

m_p_to_r:
	load constant 4
        load constant 5			; character 0x05 = 'R'
        load constant 7			; character 0x17 = right arrow
        jsb S12505
        go to cm_plus_4

m_factorial:
	load constant 2
        load constant 10		; character 0x2a = '!'
        load constant 0			; character 0x00 = 'N'
        jsb S12504
        go to cm_plus_2

m_square:
	load constant 9
        load constant 8			; character 0x18 = superscript 2
        load constant 4			; character 0x24 = 'X'
        jsb S12504
        go to cm_plus_3

m_sqrt:	load constant 6
        load constant 4			; character 0x14 = square root
        load constant 4			; character 0x24 = 'X'
        jsb S12504
        go to cm_plus_4

m_percent:
	load constant 3
        load constant 14
        load constant 8			; character 0x08 = '%'
        jsb S12504
        go to cm_plus_5

m_sigma_plus:
        load constant 11
        load constant 12		; character 0x3c = '+'
        load constant 8			; character 0x28 = sigma
        jsb S12504
        go to cm_plus_6

m_rtn:  load constant 0
        load constant 0			; character 0x00 = 'N'
        load constant 7			; character 0x07 = 'T'
        load constant 5			; character 0x05 = 'R'
        jsb S12507
        go to cm_plus_4

m_log10:
	load constant 0
        load constant 2			; character 0x02 = 'G'
        load constant 3			; character 0x03 = 'O'
        load constant 1			; character 0x01 = 'L'
        jsb S12506
        go to cm_plus_2

m_10_to_x:
	load constant 13
        load constant 9			; character 0x19 = superscript 'x'
        load constant 0			; character 0x30 = '0'
        load constant 1			; character 0x31 = '1'
        jsb S12506
        go to cm_plus_3

m_recip:
	load constant 14
        load constant 11
        load constant 1
        jsb S12504
        load constant 3
        load constant 4
        go to cm_plus_2

m_mean: load constant 11
        load constant 14
        load constant 6			; character 0x26 = x bar
        jsb S12504
        go to cm_plus_3

m_s:    load constant 3
        load constant 14
        load constant 6			; character 0x06 = 'S'
        jsb S12504
        go to cm_plus_4

m_frac:	load constant 4
        load constant 5			; character 0x05 = 'R'
        load constant 5			; character 0x15 = 'F'
        jsb S12505
        load constant 1
        load constant 12
        go to cm_plus_4

m_pse:  load constant 0
        load constant 14		; character 0x0e = 'E'
        load constant 6			; character 0x06 = 'S'
        load constant 4			; character 0x04 = 'P'
        jsb S12504
        go to cm_plus_1

m_decimal:
	load constant 15	; decimal
        load constant 10
        load constant 14
        jsb S12503
        go to cm_plus_2

m_enter:
	load constant 0		; ENT^
        load constant 7			; 'T'
        load constant 0			; 'N'
        load constant 14		; 'E'
        jsb S12507
        load constant 3
        load constant 13		; up arrow character
        go to cm_plus_1

m_chs:  load constant 1		; CHS
        load constant 3			; 'H'
        load constant 12		; 'C'
        jsb S12507
        load constant 1
        load constant 6			; 'S'
        nop
        nop
        nop
        go to xx_cm_plus_2

S13000:  c + 1 -> c[m]
S13001:  c + 1 -> c[m]
S13002:  c + 1 -> c[m]
S13003:  c + 1 -> c[m]
S13004:  c + 1 -> c[m]
S13005:  c + 1 -> c[m]
        delayed rom @05
        go to L12511

m_r_to_d:
	jsb S13141		; R->D
        load constant 5
        p <- 1
        load constant 13

        c + 1 -> c[m]
xx_cm_plus_5:  c + 1 -> c[m]
xx_cm_plus_4:  c + 1 -> c[m]
xx_cm_plus_3:  c + 1 -> c[m]
xx_cm_plus_2:  c + 1 -> c[m]
xx_cm_plus_1:  c + 1 -> c[m]
        return

m_lastx:
	load constant 0		; LSTx
        load constant 7			; 'T'
        load constant 6			; 'S'
        load constant 1			; 'L'
        jsb S13000
        load constant 3
        load constant 4			; 'x'
        go to xx_cm_plus_3

m_x_exch_y:
	load constant 9		; x<>y
        load constant 0			; 'Y'
        load constant 7			; exchange character
        load constant 4			; 'x'
        jsb S13002
        go to xx_cm_plus_1

m_clx:  load constant 2		; CLx
        load constant 4			; 'x'
        load constant 1			; 'L'
        load constant 12		; 'C'
        jsb S13001
        go to xx_cm_plus_1

m_prtx: load constant 0		; PRTX
        load constant 7			; 'T'
        load constant 5			; 'R'
        load constant 4			; 'P'
        jsb S13005
        load constant 3
        load constant 4			; 'X'
        go to xx_cm_plus_4

        nop

; addr 13060:
        go to m_x_exch_y	; 0x30 x<>y
        go to m_roll_down	; 0x31 Rv
        go to m_clx		; 0x32 CLx
        go to m_eng		; 0x33 ENG
        go to m_fix		; 0x34 FIX
        go to m_prtx		; 0x35 PRTX
        go to m_sci		; 0x36 SCI
        go to m_plus		; 0x37 +
        go to m_minus		; 0x38 -
        go to m_times		; 0x39 *
        go to m_d_to_r		; 0x3a D->R
        go to m_r_to_d		; 0x3b R->D
        go to m_to_hms		; 0x3c ->HMS
        go to m_hms_to		; 0x3d HMS->
        go to m_sto_ind		; 0x3e STOi
        go to m_rcl_ind		; 0x3f RCLi
        go to m_hms_plus	; 0x40 HMS+
        go to m_spc		; 0x41 SPC
        go to m_prst		; 0x42 PRST
        go to m_lastx		; 0x43 LSTx
        go to m_wdta		; 0x44 WDTA
        go to m_mrg		; 0x45 MRG
        go to m_x_exch_i	; 0x46 x<>I
        go to m_roll_up		; 0x47 R^
        go to m_pi		; 0x48 Pi
        go to m_deg		; 0x49 DEG
        go to m_rad		; 0x4a RAD
        go to m_grad		; 0x4b GRAD
        go to m_p_exch_s	; 0x4c P<>S
        go to m_clrg		; 0x4d CLRG

        load constant 0		; 0x4e PREG
        load constant 14		; 'E'
        load constant 5			; 'R'
        load constant 4			; 'P'
        jsb S13005
        load constant 1
        load constant 2			; 'G'
        go to xx_cm_plus_3

m_sci:  load constant 0		; SCI
        load constant 15		; 'I'
        load constant 12		; 'C'
        load constant 6			; 'S'
        jsb S13005
        go to xx_cm_plus_2

m_plus: load constant 15	; +
        load constant 14
        load constant 12		; '+'
        jsb S13001
        go to xx_cm_plus_5

S13141:  p <- 6
        load constant 1
        load constant 6
        load constant 4
        load constant 0
        load constant 1
        p <- 12
        load constant 1
        load constant 7
        return

m_eng:  load constant 0		; ENG
        load constant 2			; 'G'
        load constant 0			; 'N'
        load constant 14		; 'E'
        jsb S13005
        go to xx_cm_plus_3

m_fix:  load constant 4		; FIX
        load constant 15		; 'I'
        load constant 5			; 'F'
        jsb S13005
        load constant 3
        load constant 4			; 'X'
        go to xx_cm_plus_1

m_minus:
	load constant 15	; -
        load constant 14
        load constant 11		; '-'
        jsb S13002
        go to xx_cm_plus_5

m_roll_down:
	load constant 2		; Rv
        load constant 14		; down arrow character
        load constant 5			; 'R'
        jsb S13003
        go to xx_cm_plus_1

m_times:
	load constant 11	; *
        load constant 14
        load constant 15		; times character
        jsb S13003
        go to xx_cm_plus_5

m_d_to_r:
	jsb S13141		; D->R
        load constant 13
        p <- 1
        load constant 5
        go to xx_cm_plus_5

m_rcl_ind:
	0 -> c[w]		; RCLi
        load constant 0
        delayed rom @04
        go to L12357

m_hms_to:
	jsb S13141		; HMS->
        p <- 12
        load constant 4
        load constant 6			; 'S'
        load constant 1			; 'M'
        load constant 3			; 'H'
        jsb S13003
        load constant 2
        load constant 7			; right arrow character
        go to xx_cm_plus_5

m_to_hms:
	jsb S13141		; ->HMS
        p <- 12
        load constant 5
        load constant 1			; 'M'
        load constant 3			; 'H'
        load constant 7			; right arrow character
        jsb S13003
        load constant 1
        load constant 6			; 'S'
        go to xx_cm_plus_4

m_spc:  load constant 0		; SPC
        load constant 12		; 'C'
        load constant 4			; 'P'
        load constant 6			; 'S'
        jsb S13005
        go to xx_cm_plus_1

m_prst:
	load constant 0		; PRST
        load constant 6			; 'S'
        load constant 5			; 'R'
        load constant 4			; 'P'
        jsb S13005
        load constant 1
        load constant 7			; 'T'
        go to xx_cm_plus_4

m_deg:	load constant 0		; DEG
        load constant 2			; 'G'
        load constant 14		; 'E'
        load constant 13		; 'D'
        jsb S13004
        go to xx_cm_plus_1

m_rad:	load constant 0		; RAD
        load constant 13		; 'D'
        load constant 10		; 'A'
        load constant 5			; 'R'
        jsb S13004
        go to xx_cm_plus_2

m_grad:	load constant 0		; GRAD
        load constant 10		; 'A'
        load constant 5			; 'R'
        load constant 2			; 'G'
        jsb S13004
        load constant 1
        load constant 13		; 'D'
        go to xx_cm_plus_3

m_pi:	load constant 1		; Pi
        load constant 15		; 'i'
        load constant 4			; 'P'
        jsb S13004
        go to xx_cm_plus_4

m_roll_up:
	load constant 2		; R^
        load constant 13		; up arrow character
        load constant 5			; 'R'
        jsb S13003
        go to xx_cm_plus_1

m_x_exch_i:
	load constant 8		; x<>I
        load constant 15		; 'I'
        load constant 7			; exchange character
        load constant 4			; 'x'
        jsb S13002
        go to xx_cm_plus_1

m_p_exch_s:
	load constant 2		; P<>S
        load constant 7			; exchange characater
        load constant 4			; 'P'
        jsb S13001
        load constant 1
        load constant 6			; 'S'
        go to xx_cm_plus_1

m_clrg:	load constant 0		; CLRG
        load constant 5			; 'R'
        load constant 1			; 'L'
        load constant 12		; 'C'
        jsb S13001
        load constant 1
        load constant 2			; 'G'
        go to xx_cm_plus_3

m_hms_plus:
	load constant 4		; HMS+
        load constant 6			; 'S'
        load constant 1			; 'M'
        load constant 3			; 'H'
        jsb S13001
        load constant 4
        load constant 12		; '+'
        go to xx_cm_plus_5

m_wdta:	load constant 0		; WDTA
        load constant 7			; 'T'
        load constant 13		; 'D'
        load constant 9			; 'W'
        jsb S13000
        load constant 1
        load constant 10		; 'A'
        go to xx_cm_plus_1

m_mrg:  load constant 4		; MRG
        load constant 5			; 'R'
        load constant 1			; 'M'
        jsb S13000
        load constant 1
        load constant 2			; 'G'
        go to xx_cm_plus_2

m_sto_ind:
	0 -> c[w]		; STOi
        load constant 0
        load constant 3			; 'O'
        load constant 7			; 'T'
        load constant 6			; 'S'
        p <- 6
        load constant 3
        load constant 5
        delayed rom @04
        go to L12365

m_compare_0_common:  p <- 4
        load constant 12
        p <- 12
        load constant 11
        return

L13413:  jsb S13472

x_cm_plus_5:  c + 1 -> c[m]
x_cm_plus_4:  c + 1 -> c[m]
x_cm_plus_3:  c + 1 -> c[m]		; x=y? jumps directly here
x_cm_plus_2:  c + 1 -> c[m]
x_cm_plus_1:  c + 1 -> c[m]
x_cm_plus_0:  return

m_f_test_0:
	jsb S13435
        go to x_cm_plus_0

m_f_test_1:
	jsb S13434
        go to x_cm_plus_1

m_f_test_2:
	jsb S13433
        go to x_cm_plus_2

m_f_test_3:
	jsb S13432
        go to x_cm_plus_3

S13432:  c + 1 -> c[s]
S13433:  c + 1 -> c[s]
S13434:  c + 1 -> c[s]
S13435:  0 -> c[m]
        shift right c[ms]
        shift right c[ms]
        load constant 5
        p <- 8
        load constant 1
        load constant 6
        load constant 2
        load constant 3
        p <- 12
        load constant 7
        return

m_x_eq_0:
	jsb m_compare_0_common
        go to x_cm_plus_3

m_x_ne_0:
	load constant 1			; character 0x21 = not equal
        jsb m_compare_0_common
        go to x_cm_plus_2

m_x_ne_y:
	load constant 1			; character 0x21 = not equal
        go to x_cm_plus_2

m_x_gt_0:
	load constant 2			; character 0x22 = '>'
        jsb m_compare_0_common
        go to x_cm_plus_4

m_x_lt_0:
	load constant 9			; character 0x29 = '<'
        jsb m_compare_0_common
        go to x_cm_plus_5

m_x_gt_y:
	load constant 2			; character 0x22 = '>'
        go to x_cm_plus_4

m_x_le_y:
	load constant 3			; character 0x23 = less than or equal
        go to x_cm_plus_5

S13472:  p <- 12
        load constant 2
        load constant 5
        load constant 6
        load constant 15
        load constant 1
        load constant 6
        load constant 2
        load constant 6
        load constant 4
        p <- 1
        load constant 15
        p <- 9
        return

S13510:  c + 1 -> c[m]
        c - 1 -> c[xs]
        return

S13513:  if a[p] # 0
          then go to S13744
        load constant 14
        load constant 14
        go to L13752

; addr 13520: mnemonic table 5x
        go to m_x_ne_y
        go to x_cm_plus_3		; x=y? already nearly done
        go to m_x_gt_y
        go to m_x_ne_0
        go to m_x_eq_0
        go to m_x_gt_0
        go to m_x_lt_0
        go to m_x_le_y
        go to m_f_test_0
        go to m_f_test_1
        go to m_f_test_2
        go to m_f_test_3

        jsb S13510		; ISZ I
        go to L13413		; ISZ i

        jsb S13510		; DSZ I
        jsb S13472		; DSZ i
        load constant 13
        p <- 5
        load constant 5
        go to x_cm_plus_5

L13544:  0 -> s 3
        c - 1 -> c[s]
        if n/c go to L13550
        1 -> s 3
L13550:  c -> a[w]
        shift left a[w]
        a exchange c[s]
        shift left a[w]
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
          then go to L13631
        p <- 0
        load constant 14
        jsb S13710
        p <- 9
        if a[p] # 0
          then go to L13602
        jsb S13710
        p <- 1
        load constant 15
        load constant 11
        go to L13613

L13602:  p <- 0
        load constant 12
        p <- 9
        f exchange a[x]
        jsb S13716
        jsb S13710
        jsb S13714
        p <- 13
        jsb S13716
L13613:  jsb S13710
        p <- 10
        jsb S13716
        jsb S13714
        p <- 12
        jsb S13710
        jsb S13716
        p <- 11
        jsb S13716
        jsb S13710
        jsb S13714
        p <- 12
        jsb S13714
        go to L13676

L13631:  p <- 9
        if a[p] # 0
          then go to L13642
        jsb S13710
        p <- 1
        load constant 14
        load constant 12
        f exchange a[x]
        go to L13650

L13642:  p <- 9
        jsb S13716
        jsb S13714
        jsb S13710
        p <- 13
        jsb S13716
L13650:  p <- 10
        jsb S13716
        jsb S13710
        jsb S13714
        p <- 12
        jsb S13716
        jsb S13710
        p <- 11
        jsb S13716
        jsb S13714
        jsb S13710
        p <- 12
        jsb S13714
        p <- 9
        c -> a[p]
        jsb S13716
        jsb S13710
        jsb S13714
        p <- 11
        c -> a[p]
        a - 1 -> a[p]
        jsb S13714
L13676:  p <- 13
L13677:  load constant 15
        if p # 6
          then go to L13677
        if 1 = s 3
          then go to L13706
        load constant 7
        go to L13707

L13706:  load constant 11
L13707:  return

S13710:  a exchange c[w]
        shift left a[w]
        a exchange c[w]
        return

S13714:  load constant 1
        go to L13717

S13716:  load constant 4
L13717:  p + 1 -> p
        go to L13722

L13721:  a + c -> c[x]
L13722:  a - c -> a[p]
        if n/c go to L13721
        a + c -> a[p]
        f exchange a[x]
        return

L13727:  0 -> a[w]
        a - 1 -> a[w]
        p <- 8
        c -> a[wp]
        a exchange c[w]
        p <- 4
        jsb S13744
        p <- 6
        jsb S13513
        p <- 9
        load constant 14
        jsb S13513
        return

S13744:  load constant 8
        p + 1 -> p
        a - c -> c[p]
        if n/c go to L13755
        a exchange c[p]
        c -> a[p]
L13752:  shift right c[wp]
        load constant 14
        return

L13755:  shift right c[wp]
        load constant 11
        return

        nop
        nop
        nop
        nop
        nop

; ------------------------------------------------------------------
; Bank switch entry points

        delayed rom @04		; from S3764 - mnemonic decode
        go to m_decode

        go to L13727		; form L3766

        select rom @13 (L15771)	; from L3767

        select rom @13 (L15772)	; from L3770

        select rom @13 (L15773)	; from L3771 - key decode

        select rom @13 (L15774)	; from L3772 - WDATA

        select rom @13 (L15775)	; not used

        select rom @13 (L15776)	; from L3774

        go to L13544		; from L3775

        nop			; 3777

	.bank 1
	.org @4000	; from ROM/RAM p/n 1818-0230

        nop

; addr 14001: unshifted keyboard table, MSD 0x10..0xe0

        go to L14175		; hw 0x10 - CLx       - 0x32
        go to L14075		; hw 0x20 - divide
L14003: c + 1 -> c[x]		; hw 0x30 - roll down - 0x31
        legal go to op_30	; hw 0x40 - x<>y      - 0x30
        go to L14365		; hw 0x50 - decimal
        go to op_bst		; hw 0x60 - BST       - n/a
        go to L14354		; hw 0x70 - 0
        go to op_sst		; hw 0x80 - SST       - n/a
        go to L14160		; hw 0x90 - Sigma+
L14012: c + 1 -> c[x]		; hw 0xa0 - %         - 0x04
        c + 1 -> c[x]		; hw 0xb0 - sqrt(x)   - 0x03
        c + 1 -> c[x]		; hw 0xc0 - x^2       - 0x02
        c + 1 -> c[x]		; hw 0xd0 - 1/x       - 0x01
        load constant 0		; hw 0xe0 - R/S       - 0x00
        go to L14371

        nop

; addr 14021: unshifted keyboard table, MSD 0x11..0xe1

        go to L14373		; hw 0x11 - multiply
        go to L14376		; hw 0x21 - subtract
        go to L14367		; hw 0x31 - add
L14024: c + 1 -> c[x]		; hw 0x41 - 6
        c + 1 -> c[x]		; hw 0x51 - 5
        legal go to L14325	; hw 0x61 - 4
L14027: c + 1 -> c[x]		; hw 0x71 - P->R       - 0x0d
        c + 1 -> c[x]		; hw 0x81 - tan        - 0x0c
        c + 1 -> c[x]		; hw 0x91 - cos        - 0x0b
        c + 1 -> c[x]		; hw 0xa1 - sin        - 0x0a
        c + 1 -> c[x]		; hw 0xb1 - R->P       - 0x09
        c + 1 -> c[x]		; hw 0xc1 - e^x        - 0x08
        c + 1 -> c[x]		; hw 0xd1 - ln         - 0x07
        c + 1 -> c[x]		; hw 0xe1 - y^x        - 0x06
L14037: c + 1 -> c[x]
        legal go to L14012

L14041: if 1 = s 4
          then go to L14052
        if 0 = s 6
          then go to L14055
        if 0 = s 7
          then go to L14055
        if 1 = s 10
          then go to L14302
        go to L14300

L14052: if 1 = s 6
          then go to L14055
        go to L14277

L14055: load constant 7
        go to L14277

L14057: c + 1 -> c[x]
        legal go to L14024

L14061: c + 1 -> c[x]
        legal go to L14216

op_39:	c + 1 -> c[x]
	c + 1 -> c[x]
op_37:  c + 1 -> c[x]
op_36:	c + 1 -> c[x]
        legal go to op_35	

op_33: c + 1 -> c[x]
L14071: c + 1 -> c[x]
        legal go to L14003

op_30:  load constant 3
        go to L14371

L14075: delayed rom @11
        go to L14554

L14077: c + 1 -> c[x]
        legal go to L14270

; addr 14101: unshifted keyboard table, MSD 0x14..0xe4

        go to L14267		; hw 0x14 - EEX
        go to L14314		; hw 0x24 - CHS
        go to L14320		; hw 0x34 - ENTER^
        c + 1 -> c[x]		; hw 0x44 - 3
        c + 1 -> c[x]		; hw 0x54 - 2
        if n/c go to L14353	; hw 0x64 - 1
        go to L14253		; hw 0x74 - RCL
        go to L14250		; hw 0x84 - DSP
        go to L14232		; hw 0x94 - f
        c + 1 -> c[x]		; hw 0xa4 - E
        c + 1 -> c[x]		; hw 0xb4 - D
        c + 1 -> c[x]		; hw 0xc4 - C
        c + 1 -> c[x]		; hw 0xd4 - B
        if 1 = s 6		; hw 0xe4 - A
          then go to L14124
        if 1 = s 4
          then go to L14304
        if 1 = s 7
          then go to L14304
L14124: load constant 11
        go to L14304

L14126: if 1 = s 4
          then go to L14152
        if 0 = s 6
          then go to L14136
        if 1 = s 7
          then go to L14147
L14134: load constant 3
        go to L14277

L14136: if c[p] = 0
          then go to L14134
        c + 1 -> c[p]
        if n/c go to L14143
        go to L14134

L14143: c - 1 -> c[p]
        if 1 = s 8
          then go to L14134
        go to L14277

L14147: if 1 = s 10
          then go to L14301
        go to L14277

L14152: if 1 = s 6
          then go to L14277
        load constant 3
        if 1 = s 8
          then go to L14277
        go to L14300

L14160: if 0 = s 4
          then go to L14037
        if 0 = s 8
          then go to L14037
        go to L14061

L14165: jsb S14272
        1 -> s 7
        load constant 11
        go to L14274

L14171: jsb S14272
        1 -> s 7
        load constant 15
        go to L14274

L14175: if 1 = s 12
          then go to L15763
        delayed rom @13
        go to L15757

; addr 14201: unshifted keyboard table, MSD 0x18..0xe8

        go to L14264		; hw 0x18 - PRTx
op_34: c + 1 -> c[x]		; hw 0x28 - FIX  - 0x34
        if n/c go to op_33	; hw 0x38 - ENG  - 0x33
        c + 1 -> c[x]		; hw 0x48 - 9
        c + 1 -> c[x]		; hw 0x58 - 8
        legal go to L14057	; hw 0x68 - 7
        go to op_36		; hw 0x78 - SCI  - 0x36
        go to L14126		; hw 0x88 - (i)
        go to L14225		; hw 0x98 - STO
        go to L14041		; hw 0xa8 - I
        go to L14171		; hw 0xb8 - LBL
        go to L14165		; hw 0xc8 - GSB
        go to L14220		; hw 0xd8 - GTO
L14216: c + 1 -> c[x]		; hw 0xe8 - RTN  - 0x0e
        legal go to L14027

L14220: jsb S14272
        1 -> s 7
        1 -> s 10
        load constant 13
        go to L14274

L14225: jsb S14272
        1 -> s 4
        1 -> s 7
        load constant 9
        go to L14274

L14232: if 1 = s 4
          then go to L14243
        if 1 = s 6
          then go to L14243
        if 0 = s 7
          then go to L14243
        jsb S14272
        1 -> s 6
        go to L14245

L14243: jsb S14272
        load constant 2
L14245: 1 -> s 4
        1 -> s 10
        go to L14274

L14250: jsb S14272
        load constant 6
        go to L14274

L14253: jsb S14272
        1 -> s 4
        1 -> s 8
        load constant 7
        go to L14274

op_sst: delayed rom @00
        go to sst

op_bst: delayed rom @02
        go to bst

L14264: 1 -> s 3
op_35:	c + 1 -> c[x]
        legal go to op_34
L14267: 1 -> s 3
L14270: c + 1 -> c[x]
        if n/c go to L14317
S14272: delayed rom @11
        go to L14620

L14274: 1 -> s 13
        delayed rom @00
        go to L0142

L14277: c + 1 -> c[x]
L14300: c + 1 -> c[x]
L14301: c + 1 -> c[x]
L14302: c + 1 -> c[x]
        c + 1 -> c[x]
L14304: c + 1 -> c[x]
        c + 1 -> c[x]
L14306: p <- 8
L14307: c + 1 -> c[x]
        p - 1 -> p
        if p # 0
          then go to L14307
        go to L14371

L14314: if 0 = s 12
          then go to L14317
        1 -> s 3
L14317: c + 1 -> c[x]
L14320: c + 1 -> c[x]
        if n/c go to L14323
L14322: 1 -> s 3
L14323: load constant 1
        go to L14304

L14325: c + 1 -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
        c + 1 -> c[x]
        if 1 = s 4
          then go to L14346
        if 1 = s 6
          then go to L14350
L14335: if 0 = s 8
          then go to L14346
        c + 1 -> c[xs]
        if c[xs] # 0
          then go to L15755
        a exchange c[w]
        shift left a[x]
        a exchange c[w]
        go to L14274

L14346: if c[p] # 0
          then go to L14371
L14350: load constant 1
        1 -> s 3
        go to L14371

L14353: c + 1 -> c[x]
L14354: if 1 = s 4
          then go to L14346
        if 0 = s 6
          then go to L14335
        if 1 = s 7
          then go to L14350
        if 1 = s 10
          then go to L14306
        go to L14304

L14365: delayed rom @11
        go to L14627

L14367: delayed rom @11
        go to L14460

L14371: delayed rom @03
        go to L1554

L14373: load constant 14
        c + 1 -> c[x]
        if n/c go to L14377
L14376: load constant 10
L14377: c + 1 -> c[x]
        legal go to L14461

; addr 14401: unshifted keyboard table, MSD 0x10..0xe0

        go to op_4c		; shifted hw 0x10 - P<>S    - 0x4c
op_48:	c + 1 -> c[x]		; shifted hw 0x20 - Pi      - 0x48
        c + 1 -> c[x]		; shifted hw 0x30 - roll up - 0x47
        c + 1 -> c[x]		; shifted hw 0x40 - X<>I    - 0x46
        legal go to op_45	; shifted hw 0x50 - MERGE   - 0x45
        go to L14446		; shifted hw 0x60 - DSZ
        go to op_44		; shifted hw 0x70 - WDATA   - 0x44
        go to L14447		; shifted hw 0x80 - ISZ
op_25:	c + 1 -> c[x]		; shifted hw 0x90 - Sigma-  - 0x25
        c + 1 -> c[x]		; shifted hw 0xa0 - %CH     - 0x24
        c + 1 -> c[x]		; shifted hw 0xb0 - std dev - 0x23
        c + 1 -> c[x]		; shifted hw 0xc0 - mean    - 0x22
        c + 1 -> c[x]		; shifted hw 0xd0 - N!      - 0x21
        legal go to L14541	; shifted hw 0xe0 - PAUSE   - 0x20

op_prt_prgm:
	delayed rom @00
        go to prt_prgm

; addr 14421: unshifted keyboard table, MSD 0x11..0xe1

        c + 1 -> c[x]		; shifted hw 0x11 - x<=y
        legal go to L14454	; shifted hw 0x21 - x<0
        go to L14552		; shifted hw 0x31 - HMS+
L14424: c + 1 -> c[x]		; shifted hw 0x41 - x>0
        c + 1 -> c[x]		; shifted hw 0x51 - x=0
        legal go to L14456	; shifted hw 0x61 - x!=0
op_2d:	c + 1 -> c[x]		; shifted hw 0x71 - FRAC   - 0x2d
        c + 1 -> c[x]		; shifted hw 0x81 - arctan - 0x2c
        c + 1 -> c[x]		; shifted hw 0x91 - arccos - 0x2b
L14432: c + 1 -> c[x]		; shifted hw 0xa1 - arcsin - 0x2a
        c + 1 -> c[x]		; shifted hw 0xb1 - INT    - 0x29
        c + 1 -> c[x]		; shifted hw 0xc1 - 10^x   - 0x28
        c + 1 -> c[x]		; shifted hw 0xd1 - LOG    - 0x27
        c + 1 -> c[x]		; shifted hw 0xe1 - ABS    - 0x26
        legal go to op_25

op_3d:	c + 1 -> c[x]
op_3c:	c + 1 -> c[x]
op_3b:	c + 1 -> c[x]
op_3a:	c + 1 -> c[x]
        delayed rom @10
        go to op_39

L14446: 0 -> s 10
L14447: 0 -> s 4
        1 -> s 6
        1 -> s 7
        load constant 5
        go to L14475

L14454: c + 1 -> c[x]
        legal go to L14424

L14456: c + 1 -> c[x]
        legal go to L14604

L14460: load constant 12
L14461: p + 1 -> p
        if 0 = s 4
          then go to op_37
        if 0 = s 7
          then go to op_37
        if 1 = s 6
          then go to op_37
L14470: 1 -> s 6
        p - 1 -> p
        load constant 0
        go to L14641

L14474: 0 -> s 6
L14475: delayed rom @10
        go to L14274

op_4d: c + 1 -> c[x]

op_4c:	c + 1 -> c[x]

; addr 14501: unshifted keyboard table, MSD 0x14..0xe4

        c + 1 -> c[x]		; shifted hw 0x14 - GRAD    - 0x4b
        c + 1 -> c[x]		; shifted hw 0x24 - RAD     - 0x4a
        legal go to op_49	; shifted hw 0x34 - DEG     - 0x49
        go to op_clr_prgm	; shifted hw 0x44 - CL PRGM
        go to op_4d		; shifted hw 0x54 - CL REG  - 0x4d
        go to op_del		; shifted hw 0x64 - DEL
        go to op_3d		; shifted hw 0x74 - H.MS->H - 0x3d
        go to op_43		; shifted hw 0x84 - LASTx   - 0x43
        go to L14474		; shifted hw 0x94 - f
        c + 1 -> c[x]		; shifted hw 0xa4 - e
        c + 1 -> c[x]		; shifted hw 0xb4 - d
        c + 1 -> c[x]		; shifted hw 0xc4 - c
        c + 1 -> c[x]		; shifted hw 0xd4 - b
        if 1 = s 6		; shifted hw 0xe4 - a
          then go to L14522

        load constant 11
        p + 1 -> p
L14522: c - 1 -> c[p]
        0 -> s 6
        go to L14432

op_49:	c + 1 -> c[x]
        legal go to op_48

L14527: load constant 8
L14530: 0 -> s 10
L14531: 0 -> s 4
        1 -> s 6
        1 -> s 8
        go to L14475

L14535: load constant 6
        go to L14530

L14537: load constant 5
        go to L14531

L14541: if 0 = s 6
          then go to L14371
        load constant 2
L14544: delayed rom @10
        go to L14371

L14546: 1 -> s 3
        go to L14551

L14550: c + 1 -> c[x]
L14551: c + 1 -> c[x]
L14552: load constant 4
        go to L14544

L14554: if 0 = s 4
          then go to L14077
        if 0 = s 7
          then go to L14077
        if 1 = s 6
          then go to L14077
        load constant 8
        go to L14470

op_clr_prgm:
	if 0 = s 11		; program mode?
          then go to L14642	;   no, don't clear
        delayed rom @01
        go to clr_prgm

op_50: load constant 5
        go to L14544

L14572: c + 1 -> c[x]
        if n/c go to op_4d

op_del: delayed rom @01
        go to del_x

op_45:	c + 1 -> c[x]
op_44:	c + 1 -> c[x]
op_43:	c + 1 -> c[x]

; addr 14601: unshifted keyboard table, MSD 0x14..0xe4

        legal go to L14550	; shifted hw 0x18 - PRSTK    - 0x42
        go to L14546		; shifted hw 0x28 - SPACE    - 0x41
        go to L14572		; shifted hw 0x38 - PRREG    - 0x4e
L14604: c + 1 -> c[x]		; shifted hw 0x48 - x>y      - 0x52
        c + 1 -> c[x]		; shifted hw 0x58 - x=y      - 0x51
        legal go to op_50	; shifted hw 0x68 - x!=y     - 0x50
        go to op_prt_prgm	; shifted hw 0x78 - PRT PRGM - n/a
        go to op_3a		; shifted hw 0x88 - D->R     - 0x3a
        go to op_3c		; shifted hw 0x98 - H->H.MS  - 0x3c
        go to op_3b		; shifted hw 0xa8 - R->D     - 0x3b
        go to L14527		; shifted hw 0xb8 - STF
        go to L14537		; shifted hw 0xc8 - F?
        go to L14535		; shifted hw 0xd8 - CLF
        c + 1 -> c[x]		; shifted hw 0xe8 - RND      - 0x2e
        legal go to op_2d

L14620: 0 -> s 4
        0 -> s 6
        0 -> s 7
        0 -> s 8
        0 -> s 10
        0 -> s 13
        return

L14627: if 1 = s 4
          then go to L14322
        if 1 = s 6
          then go to L14322
        if 0 = s 10
          then go to L14322
        1 -> s 8
        p <- 2
        load constant 15
        load constant 15
L14641: go to L14475

L14642: delayed rom @00
        go to L0125

; ------------------------------------------------------------------
; separate source file contains card reader code from
; 14644..15735.  Code in 67 and 97 is almost identical.
; ------------------------------------------------------------------

m97	.equ 1
	.include "6797cr.asm"

; ------------------------------------------------------------------
; hardware keycode to opcode mapping
; ------------------------------------------------------------------

; Hardware keycodes are 0xYZ where Y is 0, 1, 4, or 8 and Z is 1..e.

; Move the high digit of the hardware keycode from C[2] to C[0].
; Leave the low digit in C[1] unchanged.

L15736: go to L15740

L15737: c + 1 -> c[x]
L15740: c - 1 -> c[xs]
        if n/c go to L15737

; Move the keycode from C[1:0] to A[2:1]

        a exchange c[w]
        shift left a[x]

        0 -> s 3
        if 0 = s 4
          then go to L15751
        if 1 = s 10
          then go to L15753
L15751: delayed rom @10		; unshifted keycode table 14000-14377
        a -> rom address

L15753: delayed rom @11		; shifted keycode table 14400-14777
        a -> rom address

; ------------------------------------------------------------------

L15755: delayed rom @03
        go to L1545


L15757: crc fs?c crc_f8		; copy crc_f8 to s3 (enter with s3=0)
        if 0 = s 3
          then go to L15764
        crc sf crc_f8
L15763: 1 -> s 3
L15764: delayed rom @10
        go to L14071

; ------------------------------------------------------------------
; fill

        nop
        nop
        nop

; ------------------------------------------------------------------
; Entry points from bank 0 by way of bank 1 quad 1:

L15771: nop
L15772: go to L15776		; from L3770

L15773: go to L15736		; from L3771 - key decode

L15774: delayed rom @12		; from L3772 - WDATA
L15775: go to wdata

L15776: delayed rom @12		; from L3774 - card inserted
        go to card_inserted


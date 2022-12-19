; 67/97 ROM disassembly - bank 1 card reader code
; Copyright 2007, 2008, 2022 Eric Smith <spacewar@gmail.com>
;
; ------------------------------------------------------------------
; This code resides at 12644..13732 in 67,
;                      14644..15735 in 97
;
; Entry points:
;   card_inserted - from main loop
;              if program mode, write program to card(s)
;              if run mode, read program or data card(s)
;   wdata - write data registers to card(s)
; ------------------------------------------------------------------


; ------------------------------------------------------------------
; select RAM block 3

selbk3: p <- 1
        load constant 3
        c -> data address
        return

; ------------------------------------------------------------------

Scr2650: b exchange c[w]
        jsb selbk3		; select RAM block 3
        b -> c[w]
        c -> register 15
        a -> b[w]
        register -> c 12
        a exchange c[w]
        register -> c 11
        if 0 = s 8
          then go to Lcr2670
        if a >= c[m]
          then go to Lcr2670
        c - 1 -> c[m]
        c -> register 11
        register -> c 15
        go to Lcr2677

Lcr2670: c - 1 -> c[m]
        c -> register 11
        register -> c 15
        c -> data address
        b exchange c[w]
        c -> data
        b exchange c[w]
Lcr2677: p <- 3
        return

; ------------------------------------------------------------------

Lcr2701: if c[p] # 0
          then go to Lcr3251
Lcr2703: 1 -> s 6
Lcr2704: 0 -> s 12
        1 -> s 10
        go to Lcr2710

Lcr2707: 1 -> s 12
Lcr2710: delayed rom address Scr3607
        jsb Scr3607
        0 -> c[w]
        c -> data address
        register -> c 15
        0 -> c[s]
        if c[xs] = 0
          then go to Lcr2721
        0 -> c[w]
Lcr2721: shift right c[m]
        p - 1 -> p
        if p # 4
          then go to Lcr2721
        if c[x] # 0
          then go to Lcr2731
        shift right c[m]
        go to Lcr2735

Lcr2731: c - 1 -> c[x]
        if c[x] = 0
          then go to Lcr2735
        load constant 9
Lcr2735: jsb selbk3		; select RAM block 3
        if 1 = s 4
          then go to Lcr2741
        c -> register 12
Lcr2741: p <- 4
        load constant 2
        load constant 5
        c -> register 11
        b -> c[w]
        p <- 3
        load constant 5
        p <- 0
        load constant 15

Lcr2752: delayed rom address crc_read_56
        jsb crc_read_56
        if 0 = s 12
          then go to Lcr2760
        1 -> s 4
        jsb Scr2650
Lcr2760: c - 1 -> c[x]
        c - 1 -> c[p]
        if n/c go to Lcr2752
        load constant 9
        p <- 1
        if 1 = s 12
          then go to Lcr2770
        load constant 3
Lcr2770: a exchange c[w]
        jsb selbk3		; select RAM block 3
        register -> c 11
        p <- 4
        c - 1 -> c[p]
        p <- 3
        load constant 9
        c -> register 11
        a exchange c[w]
Lcr3001: jsb crc_read_56
        delayed rom address Scr2650
        jsb Scr2650
        c - 1 -> c[x]
        c - 1 -> c[p]
        if n/c go to Lcr3001
        jsb Scr3370
        jsb wait_no_card_x
        delayed rom address selbk3
        jsb selbk3		; select RAM block 3
        p <- 0
        register -> c 14
        load constant 1
        c -> register 14
        if 0 = s 4
          then go to Lcr3301
        if 1 = s 10
          then go to card_done
        if 1 = s 7
          then go to Lcr2703
        go to Lcr3301

; ------------------------------------------------------------------
; jump extenders

get_user_status_x:
	delayed rom address get_user_status
        go to get_user_status

check_zero_regs_x:
	delayed rom address check_zero_regs
        go to check_zero_regs

; ------------------------------------------------------------------

; write program to card
wprgm:  crc sf write_mode		; set write mode
        jsb get_user_status_x
        load constant 3		; mark header for program sets 001-112

        p <- 1			; set s7 if all prog steps 113-224 are R/S
        load constant 1
        load constant 15
        jsb check_zero_regs_x

        p <- 1
        load constant 2

        jsb Scr3341
        jsb write_16_reg
        if 1 = s 7		; second card needed?
          then go to card_done	;   no

        delayed rom address card_prompt
        jsb card_prompt		; prompt for card

        jsb get_user_status_x
        load constant 4		; mark header for program sets 113-224
        p <- 1
        load constant 1
        jsb Scr3341
        jsb write_16_reg	; write 16 reg

card_done_x:
	delayed rom address card_done
        go to card_done

; ------------------------------------------------------------------
; WDATA entry point

wdata:  m1 exchange c
        crc sf write_mode	; set write mode
        binary
        display off
        delayed rom address card_prompt
        jsb card_prompt		; prompt for card
        jsb get_user_status_x
        load constant 1		; mark header for primary registers

        p <- 1			; set s7 if all secondary registers are zero
        load constant 3
        load constant 9
        jsb check_zero_regs_x

        jsb Scr3341
        jsb write_16_reg	; write 16 registers
        if 1 = s 7		; second card needed?
          then go to card_done	;   no

        delayed rom address card_prompt
        jsb card_prompt		; prompt for card

        jsb get_user_status_x
        load constant 2		; mark header for secondary registers
        p <- 1
        load constant 3
        jsb Scr3341
        jsb write_16_reg	; write 16 registers
        go to card_done_x

; ------------------------------------------------------------------

wait_no_card_x:
	delayed rom address wait_no_card
        go to wait_no_card

; ------------------------------------------------------------------
; write a set of registers to a card
; 

write_16_reg:
	crc fs?c crc_f7

        p <- 11			; delay - returns in binary with p=0
        jsb delay2

        c -> a[w]
        jsb sel_crc		; select CRC
        c -> data		; write C to buffer
        jsb Scr3167
        a exchange c[w]
        c - 1 -> c[p]

Lcr3125: c -> data address	; get register from memory (addr in C[1:0])
        b exchange c[w]		; move reg addr, checksum into B
        data -> c

        0 -> a[w]		; split reg into b[13:7] and c[13:7]
        p <- 6
        c -> a[wp]
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        rotate left a
        0 -> c[wp]
        a exchange b[w]		; move reg addr, checksum into A

        a + b -> a[w]		; update checksum in A[13:7]
        a + c -> a[w]

        jsb sel_crc		; select CRC
        c -> data		; write c[13:7] to buffer
        jsb Scr3201		; wait

        b exchange c[w]		; write b[13:7] to buffer
        c -> data
        jsb Scr3201		; wait

        a exchange c[w]		; move reg addr, checksum into C
        c - 1 -> c[p]		; more to do
        if n/c go to Lcr3125	;   yes, loop

        c -> data		; write checksum in C to buffer
        jsb Scr3201		; wait

        go to wait_no_card_x	; wait for card to exit, and return

; ------------------------------------------------------------------
; select CRC, register address 0x99
; works regardless of binary or decimal mod mode

sel_crc:
	p <- 1
        load constant 9
        load constant 9
        c -> data address
        return

; ------------------------------------------------------------------
; wait for CRC buffer to be be ready, with timeout
	
Scr3167: 0 -> s 3
        0 -> c[w]		; init loop counter
        decimal
Lcr3172: crc fs?c buffer_ready	; buffer ready?
        if 1 = s 3
          then go to Lcr3205	; delay and return
        c + 1 -> c[x]
        if n/c go to Lcr3172
        delayed rom address cr_error
        go to cr_error

; wait for CRC buffer to be ready for write, no timeout

Scr3201: 0 -> s 3
Lcr3202: crc fs?c buffer_ready	; buffer ready?
        if 0 = s 3
          then go to Lcr3202
Lcr3205: binary
        p <- 0
        0 -> s 3
        crc fs?c crc_f7		; check CRC status
        if 1 = s 3
          then go to Lcr3406	;    maybe an error?
        return

; ------------------------------------------------------------------
; Entry point - main loop detected card inserted

card_inserted:
	m1 exchange c
        p <- 1

        0 -> s 3		; copy merge flag to s8
        crc fs?c merge
        if 0 = s 3
          then go to Lcr3223
        1 -> s 8
	
Lcr3223: crc fs?c write_mode	; assume reading
        if 1 = s 11		; program mode?
          then go to wprgm	;   yes, write program to card

; read program or data cards

read_card:
	jsb Scr3341
        crc fs?c buffer_ready	; clear buffer ready flag
        jsb sel_crc		; select CRC
        jsb Scr3167		; wait for data avail
        register -> c 11	; get header data
        p <- 5
        0 -> c[wp]
        b exchange c[w]
        b -> c[w]

        c - 1 -> c[s]		; 1?
        if c[s] = 0
          then go to Lcr2707

        c - 1 -> c[s]		; 2?
        if c[s] = 0
          then go to Lcr2704

        c - 1 -> c[s]		; 3?
        if c[s] = 0
          then go to Lcr3254

        go to Lcr3305		; 0 or 4..f, assume it was 4

Lcr3251: c - 1 -> c[p]
        c - 1 -> c[p]
        if n/c go to Lcr3305
Lcr3254: 1 -> s 4
        delayed rom address Scr3551
        jsb Scr3551

Lcr3257: jsb crc_read_56		; read one reg from CRC

        delayed rom address Scr3664 ; write to program memory, rotating if
        jsb Scr3664		;   necessary for MERGE

        p <- 3
        c - 1 -> c[p]
        if n/c go to Lcr3257

        jsb Scr3370
        jsb wait_no_card_x
        if 1 = s 8
          then go to Lcr3273
        delayed rom address Scr3505
        jsb Scr3505
Lcr3273: if 0 = s 4
          then go to Lcr3301
        if 1 = s 10
          then go to card_done
        if 1 = s 7
          then go to Lcr3304
Lcr3301: delayed rom address card_prompt
        jsb card_prompt		; prompt for card
        go to read_card

Lcr3304: 1 -> s 6
Lcr3305: delayed rom address Scr3551
        jsb Scr3551
        1 -> s 10
        p <- 1
        c - 1 -> c[p]
        if n/c go to Lcr3257
Lcr3313: 0 -> c[w]
        go to Lcr3336

; ------------------------------------------------------------------
; read one 56-bit register from CRC
crc_read_56:
	a exchange c[w]
        if 1 = s 6
          then go to Lcr3313
        jsb sel_crc		; select CRC
        jsb Scr3167		; wait for data ready
        register -> c 11	; get 28 bits
        p <- 6
        0 -> c[wp]
        a + c -> a[w]
        b exchange c[w]
        jsb Scr3167		; wait for data ready
        p <- 6
        register -> c 11	; get 28 bits
        b exchange c[wp]
        0 -> c[wp]
        a + c -> a[w]
        b exchange c[w]
Lcr3336: a exchange c[w]
        p <- 3
        return

; ------------------------------------------------------------------
Scr3341: display off
        crc fs?c crc_f7
        crc sf motor_on
        crc fs?c buffer_ready	; clear buffer ready flag
	
        p <- 6
        jsb delay		; delay
	
        crc fs?c buffer_ready	; clear buffer ready flag
        c -> a[w]
        jsb Scr3167
        a exchange c[w]
	
        p <- 4			; delay
        jsb delay2
	
        crc fs?c buffer_ready; clear buffer ready flag

        p <- 10			; delay and return
        go to delay1

; ------------------------------------------------------------------
; delay

delay:	p - 1 -> p
delay1:	nop
        nop
delay2: nop
        binary
        if p # 0
          then go to delay
        return

; ------------------------------------------------------------------
Scr3370: if 1 = s 6
          then go to Lcr3405
        a exchange c[w]
        jsb sel_crc		; select CRC
        jsb Scr3167		; wait for data ready
        p <- 6
        register -> c 11	; get 28 bits
        a -> b[w]
        b exchange c[w]
        a -> b[wp]
        a - b -> a[w]
        if a[w] # 0
          then go to Lcr3410
Lcr3405: return

Lcr3406: p <- 6
        a exchange c[w]
Lcr3410: if c[p] = 0
          then go to cr_error_wait
        0 -> a[w]
        0 -> c[x]
        1 -> s 6
        1 -> s 7
        1 -> s 13
        c - 1 -> c[p]
        c - 1 -> c[p]
        if n/c go to Lcr3424
        delayed rom address Lcr2707
        go to Lcr2707

Lcr3424: delayed rom address Lcr2701
        go to Lcr2701

; ------------------------------------------------------------------
; get user status formatted for card header
; on return:
;   p=13
;   c[13] ready for card ID to set (1=primary reg, 2=secondary reg,
;                                   3=prog 001-112, 4=prog 113-224)
;   c[12]
;   c[11] = user flags
;   c[10] = trig mode
;   c[9] = display digits
;   c[8:7] = display mode (00=sci, 22=fix, 40=eng)
;   c[6:0] = 0 (not part of header)

get_user_status:
	p <- 1			; get status register
        load constant 3
        c -> data address
        register -> c 14
        c -> a[w]

Lcr3433: shift left a[w]
        p - 1 -> p
        if p # 9
          then go to Lcr3433

        0 -> c[s]		; user flags
        p <- 4
Lcr3441: p - 1 -> p
        c + c -> c[s]
        if c[p] = 0
          then go to Lcr3446
        c + 1 -> c[s]
Lcr3446: if p # 0
          then go to Lcr3441

        a exchange c[m]
        p <- 12
        0 -> c[p]
        if 0 = s 14
          then go to Lcr3456
        load constant 2
Lcr3456: if 0 = s 0
          then go to Lcr3461
        load constant 1
Lcr3461: p <- 8
        0 -> c[wp]
        shift right c[w]
        shift right c[w]
        p <- 13
        return

; ------------------------------------------------------------------
; check whether a range of registers contain any non-zero values,
; in order to determine whether a second card is necessary

; on entry:
;   c[1:0] = highest addr to check
; on return:
;   if all registers are zero:
;     s7 = 1
;     p = 11
;     c[12] = 1
;     c[x] = 0
;   if some registers are non-zero
;     s7 unchanged
;     p = 0
;     c[x] = 0

check_zero_regs:
	p <- 0
Lcr3470: c -> data address
        a exchange c[w]
        data -> c
        a exchange c[w]
        if a[w] # 0
          then go to Lcr3503
        c - 1 -> c[p]
        if n/c go to Lcr3470

        1 -> s 7		; all zero!
        p <- 12
        load constant 1

Lcr3503: 0 -> c[x]
        return

; ------------------------------------------------------------------
Scr3505: if 1 = s 6
          then go to Lcr3273
        p <- 1
        load constant 3
        c -> data address
        register -> c 15
        a exchange c[w]
        shift left a[w]
        shift left a[w]
        p <- 8
Lcr3517: shift right a[m]
        p - 1 -> p
        if p # 3
          then go to Lcr3517
        0 -> a[wp]
        a exchange c[w]
Lcr3525: c + c -> c[s]
        if n/c go to Lcr3530
        c + 1 -> c[p]
Lcr3530: p - 1 -> p
        if p # 13
          then go to Lcr3525
        p <- 7
        0 -> s 0
        0 -> s 14
        if c[p] = 0
          then go to Lcr3546
        1 -> s 0
        c - 1 -> c[p]
        if c[p] = 0
          then go to Lcr3546
        0 -> s 0
        1 -> s 14
Lcr3546: load constant 1
        c -> register 14
        return

; ------------------------------------------------------------------
Scr3551: p <- 1			; get return stack
        load constant 3
        c -> data address
        register -> c 13
        if c[x] = 0
          then go to Lcr3563
        if 1 = s 8
          then go to Lcr3567
        0 -> c[w]
        c -> register 13
Lcr3563: p <- 2
        load constant 7
        load constant 2
        load constant 15
Lcr3567: p <- 1
        c - 1 -> c[xs]
        if n/c go to Lcr3573
        c - 1 -> c[wp]
Lcr3573: c -> a[xs]
        p <- 2
        load constant 5
Lcr3576: a - 1 -> a[xs]
        c - 1 -> c[xs]
        if n/c go to Lcr3576
        a exchange c[xs]
        0 - c -> c[xs]
        b exchange c[ms]
        p <- 3
        load constant 15
        c -> register 15
Scr3607: p <- 12
        if c[p] = 0
          then go to Lcr3613
        1 -> s 7
Lcr3613: return

; ------------------------------------------------------------------
; get keycode from PICK (97 only)
; assumes caller already checked that there is at least one keycode available
; ------------------------------------------------------------------

	.if m97
get_pick_keycode_b1:
	0 -> c[w]
        c - 1 -> c[w]
        c -> data address
        register -> c 15
        return
	.endif

; ------------------------------------------------------------------
; prompt for card
; ------------------------------------------------------------------

card_prompt:
	if 1 = s 13
          then go to cr_error_wait
        0 -> b[w]
        p <- 13
        load constant 11	; 'C'
        load constant 10	; 'r'
        load constant 13	; 'd'
        0 -> c[wp]
        c -> a[w]
        a - 1 -> a[wp]
        display toggle
        0 -> s 3

	.if m97

card_wait:
	pick key?		; key pressed?
        if 0 = s 3
          then go to card_wait_no_key	; no
        jsb get_pick_keycode_b1	; yes, get keycode and abort
        go to card_done

	.else

card_wait_key_reset:
	0 -> s 15		; reset key scanner
        if 1 = s 15		; key still pressed?
          then go to card_wait_key_reset	;   yes, loop

card_wait:
        if 1 = s 15		; key pressed?
          then go to card_done	;   yes, abort

	.endif

card_wait_no_key:
	crc fs?c card_present	; card inserted?
        if 0 = s 3
          then go to card_wait	;   no, loop
        return

card_done:
	if 1 = s 13		; card reader done
          then go to cr_error_wait
        m1 -> c
        0 -> s 3
        delayed rom address L0073
        go to L0073

; ------------------------------------------------------------------
; wait for card inserted condition to go away

wait_no_card:
	0 -> s 3
        crc fs?c crc_f7
        crc fs?c card_present		; card inserted?
        if 1 = s 3
          then go to wait_no_card_x	; slow branch back to wait_no_card
        crc fs?c motor_on		; stop motor
        crc fs?c buffer_ready		; clear buffer ready flag
        return

; ------------------------------------------------------------------
cr_error_wait:
	jsb wait_no_card

cr_error:
	crc fs?c motor_on		; stop motor
        m1 -> c
        delayed rom address err0
        go to err0

; ------------------------------------------------------------------
; write to program memory, rotating if necessary for MERGE

Scr3664:
	.if m97
	b exchange c[w]
        b -> c[w]
	.else
	b exchange c[w]
        crc fs?c default_fn
        b -> c[w]
        0 -> s 3
	.endif

        c -> data address
        p <- 1
        if c[p] = 0
          then go to Lcr3732
        p <- 0
        go to Lcr3702

Lcr3676: rotate left a
        rotate left a
        p + 1 -> p
        p + 1 -> p
Lcr3702: c - 1 -> c[xs]
        if n/c go to Lcr3676
        data -> c
        a exchange c[wp]
        a exchange c[p]
        a exchange c[w]
        c -> data
        b -> c[w]
        c - 1 -> c[x]
        c -> data address
        data -> c
        if p = 0
          then go to Lcr3721
        p - 1 -> p
        a exchange c[wp]
Lcr3721: a exchange c[w]
        b -> c[w]
        p <- 1
        c - 1 -> c[wp]
        if c[p] = 0
          then go to Lcr3732
        a exchange c[w]
        c -> data
        a exchange c[w]
Lcr3732: return

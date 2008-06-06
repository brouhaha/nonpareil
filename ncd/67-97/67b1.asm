; 67 ROM disassembly - bank 1
; Copyright 2007, 2008 Eric Smith <eric@brouhaha.com>
; $Id$
;

	.arch woodstock

; External references, mainframe:
L0073	.equ	@0073
L0363	.equ	@0363
L1340	.equ	@1340
L1363	.equ	@1363
err0	.equ	@1372

; CRC flags:
buffer_ready  .equ 0
prog_mode     .equ 1
crc_f2        .equ 2    ; purpose unknown
crc_f3        .equ 3    ; not used in 67
default_fn    .equ 4
merge         .equ 5
pause         .equ 6
crc_f7        .equ 7    ; purpose unknown
crc_f8        .equ 8    ; purpose unknown
motor_on      .equ 9
card_present  .equ 10
write_mode    .equ 11

	.bank 1
	.org @2000	; from ROM/RAM p/n 1818-0231

; ------------------------------------------------------------------
; addr 12000: dispatch table for keycode decode (low digit?)

        go to L12023		; 
        go to cm_plus_4		; 
        c + 1 -> c[m]		; 
        legal go to L12222	; 
        go to L12247		; 
        go to L12230		; 
        go to L12235		; 
        go to L12216		; 
        jsb S12215		; 
        go to L12226		; 
        return			; 
        go to L12224		; 
        go to S12223		; 
        go to L12250		; 
        go to L12233		; 

        load constant 2		; 
        jsb cm_plus_3
L12021: c - 1 -> c[w]
        return

L12023: jsb S12160
L12024: load constant 8
        go to S12223

L12026: if c[s] = 0
          then go to L12430
        jsb S12317
        go to L12250

        go to L12212

L12033: c - 1 -> c[w]
L12034: c - 1 -> c[w]
        if n/c go to L12203
L12036: load constant 8
        go to L12021

; addr 12040: dispatch table

        go to L12176

        go to L12200

        c - 1 -> c[m]
        if n/c go to L12231
        go to L12247

        go to L12205

        go to L12207

        c - 1 -> c[m]
        if n/c go to L12166
        go to L12211

        return

        go to L12224

        go to S12223

        go to L12212

        c - 1 -> c[m]
        if n/c go to L12221
        c - 1 -> c[w]
        if n/c go to L12165
        go to L12170

        jsb cm_plus_4
        go to L12174

        go to L12024

        go to L12173

        c + 1 -> c[p]
        jsb S12215
        go to L12156

        c + 1 -> c[m]
        if n/c go to L12163
        c + 1 -> c[m]
        if n/c go to L12116
        c - 1 -> c[m]
        if n/c go to L12220
        go to L12212

        go to L12024

        go to L12143

        go to L12247

        c - 1 -> c[m]
        if n/c go to L12145
        go to L12221

        go to L12222

        go to L12163

        go to L12033

        go to L12034

        go to L12203

        c - 1 -> c[w]
        if n/c go to L12202
L12116: c + 1 -> c[w]
        if n/c go to L12163
        c + 1 -> c[p]
        jsb S12214
        go to L12147

        c + 1 -> c[p]
        jsb S12214
        c + 1 -> c[p]
        c - 1 -> c[m]
        if n/c go to L12150
        c - 1 -> c[w]		; 0xb?
        c - 1 -> c[w]		; 0xc?
        c - 1 -> c[w]		; 0xd?
        if n/c go to L12153	; 0xe?  flag
        c - 1 -> c[m]
        if n/c go to L12140
        c - 1 -> c[m]
        c - 1 -> c[w]
L12140: load constant 3
        jsb S12223
        go to cm_plus_1

L12143: jsb S12240
        go to L12024

L12145: jsb S12240
        go to L12033

L12147: c + 1 -> c[p]
L12150: c + 1 -> c[p]
        c + 1 -> c[m]
        if n/c go to L12021
L12153: jsb S12223
        jsb S12366
        go to L12247

L12156: c + 1 -> c[p]
        c - 1 -> c[w]
S12160: 0 -> c[m]
L12161: c - 1 -> c[m]
        return

L12163: c + 1 -> c[w]
        if n/c go to L12250
L12165: jsb cm_plus_4
L12166: c - 1 -> c[p]
        if n/c go to L12224
L12170: jsb S12160
        load constant 4
        go to S12223

L12173: c + 1 -> c[m]
L12174: load constant 2
        go to L12224

L12176: load constant 7
        go to cm_plus_3

L12200: jsb cm_plus_3
        go to L12036

L12202: jsb S12237
L12203: load constant 4
        go to L12224

L12205: jsb cm_plus_3
        go to L12231

L12207: jsb cm_plus_3
        go to S12223

L12211: c - 1 -> c[m]
L12212: load constant 8
        go to L12224

S12214: c - 1 -> c[p]
S12215: c - 1 -> c[p]
L12216: c - 1 -> c[p]
        return

L12220: jsb cm_plus_3
L12221: jsb S12214
L12222: c - 1 -> c[p]
S12223: c + 1 -> c[w]
L12224: c + 1 -> c[w]
        return

L12226: c + 1 -> c[m]
        if n/c go to L12250
L12230: jsb S12160
L12231: load constant 2
        go to L12021

L12233: load constant 2
        go to cm_plus_4

L12235: jsb cm_plus_4
        go to L12224

S12237: c - 1 -> c[m]
S12240: c - 1 -> c[m]
        c - 1 -> c[m]
        if n/c go to L12161
L12243: if c[s] = 0
          then go to S12366
        jsb S12317
        c + 1 -> c[p]
L12247: c + 1 -> c[p]
L12250: c + 1 -> c[p]
        return

L12252: jsb S12310
        go to cm_plus_2

L12254: if c[s] = 0
          then go to L12260
        jsb S12317
        go to L12247

L12260: jsb cm_plus_3
        go to L12272

L12262: jsb cm_plus_3
        c + 1 -> c[s]
        if n/c go to ret
        c - 1 -> c[w]
L12266: c + 1 -> c[p]
        if n/c go to cm_plus_2
L12270: if c[s] # 0
          then go to S12317
L12272: jsb S12310
        go to L12266

L12274: jsb S12313
        go to cm_plus_2

L12276: jsb S12160
        if c[s] = 0
          then go to L12332
        return

L12302: if c[s] = 0
          then go to L12306
        jsb S12313
        go to cm_plus_3

L12306: jsb S12366
        go to L12250

S12310: p <- 7				; f prefix for row 2
        load constant 3
        load constant 1
S12313: p <- 4
        load constant 2
        p <- 6
        return

S12317: p <- 7				; STO prefix (might get turned into f or g?)
        load constant 3
        load constant 3
        go to L12373

; ------------------------------------------------------------------

L12323: jsb cm_plus_4
        c + 1 -> c[s]
        if n/c go to ret
        c + 1 -> c[m]
        if n/c go to L12250
L12330: jsb cm_plus_4
L12331: c + 1 -> c[m]
L12332: load constant 6
        load constant 2
        p <- 1
        shift left a[x]
        a -> rom address		; @12000-12017

        nop			; fill

; ------------------------------------------------------------------
; addr 12340: dispatch table for keycode decode, high digit of op

        go to L12331		; 0x00..0x0f
        go to L12276		; 0x10..0x1f
        c + 1 -> c[m]		; 0x20..0x2f
        if n/c go to L12331	; 0x30..0x3f
        go to L12330		; 0x40..0x4f
        go to L12331		; 0x50..0x55
        go to L12302		; 0x60..06xf
        go to L12323		; 0x70..0x7f
        go to L12243		; 0x80..0x8f
        go to L12262		; 0x90..0x9f
        go to L12270		; 0xa0..0xaf
        go to L12252		; 0xb0..0xbf
        go to L12026		; 0xc0..0xcf
        go to L12274		; 0xd0..0xdf
        go to L12254		; 0xe0..0xef

        jsb S12310		; 0xf0..0xff
        c + 1 -> c[m]
cm_plus_4: c + 1 -> c[m]
cm_plus_3: c + 1 -> c[m]
cm_plus_2: c + 1 -> c[m]
cm_plus_1: c + 1 -> c[m]
ret:	return

; ------------------------------------------------------------------

S12366: load constant 0			; set up for flag keycodes (h SF)
        c - 1 -> c[p]
        p <- 7
        load constant 3
        load constant 5
L12373: p <- 4
        load constant 5
        load constant 1
        p <- 4
        return

; ------------------------------------------------------------------

L12400: a exchange c[p]		; decode inst with LSD 0-9
        c -> a[p]
        c + 1 -> c[s]
        c + 1 -> c[s]
L12404: p <- 4			; decode all inst
        load constant 3
        load constant 0
        load constant 14
        a exchange c[xs]
        delayed rom @04
        a -> rom address	; @12340-12357

; ------------------------------------------------------------------

L12413: a + 1 -> a[p]		; decode inst with LSD 0xa..0xf
        if n/c go to L12421
        load constant 4
        p <- 1
        load constant 2
        go to L12425

L12421: a - c -> c[p]
        p <- 1
        load constant 1
        0 -> c[s]
L12425: a - 1 -> a[p]
        nop
        go to L12404		; rejoin the decode for LSD 0x0..0x9

; ------------------------------------------------------------------

L12430: p <- 7
        load constant 2
        load constant 2
        c + 1 -> c[m]
        return

; ------------------------------------------------------------------
; Entry point

L12435: 0 -> c[w]
        c - 1 -> c[w]
L12437: p <- 5
        jsb S12452
        jsb S12633
        c - 1 -> c[p]
        if n/c go to L12437
L12444: m1 exchange c
L12445: display off
        b exchange c[w]
        0 -> s 12
        delayed rom @00
        go to L0363

; ------------------------------------------------------------------

S12452: p - 1 -> p
L12453: nop
L12454: 0 -> s 15
        if 1 = s 15
          then go to L12467
        1 -> s 10
        crc fs?c crc_f2		; flag purpose unknown
        if 0 = s 13
          then go to L12506
        display off
        if 1 = s 6
          then go to L12526
        go to L12444

L12467: if 0 = s 10
          then go to L12506
        1 -> s 8
        if 1 = s 4
          then go to L12617
        p <- 0
L12475: p - 1 -> p
        if b[p] = 0
          then go to L12475
        load constant 3
        p + 1 -> p
        b exchange c[p]
        b -> c[p]
        1 -> s 13
        go to L12454

L12506: nop
        nop
        c - 1 -> c[xs]
        if n/c go to L12453
        if p # 0
          then go to S12452
        return

; ------------------------------------------------------------------
; Entry point

L12515: 0 -> c[ms]
        c - 1 -> c[ms]
        jsb S12452
        jsb S12633
        jsb S12452
        jsb S12633
        jsb S12452
        jsb S12633
        jsb S12452
L12526: 0 -> s 13
        p <- 0
        c - 1 -> c[p]
        if n/c go to L12534
        m1 exchange c
        go to L12445

L12534: m1 exchange c
        down rotate
        down rotate
        down rotate
L12540: display off
        b exchange c[w]
        delayed rom @02
        go to L1340

; ------------------------------------------------------------------
; Entry point:

L12544: 1 -> s 4
        display off
        jsb selbk3		; select RAM block 3
        b exchange c[w]
        c -> register 15
        binary
        0 -> c[w]
        p <- 13
        load constant 9
        p <- 5
        load constant 15
        load constant 15
        a exchange c[w]
L12561: a -> b[w]
        shift right a[w]
        shift right a[w]
        shift right a[w]
        0 -> c[w]
        c - 1 -> c[w]
        a exchange c[ms]
        b -> c[w]
        0 -> b[w]
        display toggle
        p <- 0
        jsb S12452
        c -> data address
        m1 exchange c
        data -> c
        go to L12540

; ------------------------------------------------------------------
; Entry point

L12601: p <- 0
        jsb S12452
        c -> data address
        display off
        a exchange c[w]
        data -> c
        m1 exchange c
        c -> data
        a + 1 -> a[m]
        a + 1 -> a[w]
        a - 1 -> a[s]
        if n/c go to L12561
        if 0 = s 7
          then go to L12622
L12617: jsb selbk3		; select RAM block 3
        register -> c 15
        go to L12445

L12622: a exchange c[w]
        1 -> s 7
        p <- 4
        load constant 2
        load constant 0
        p <- 13
        load constant 5
        a exchange c[w]
        go to L12561

; ------------------------------------------------------------------

S12633: p - 1 -> p
        if b[p] = 0
          then go to S12633
        b exchange c[p]
        p <- 0
        return

        nop
        nop
        nop

; ------------------------------------------------------------------
; separate source file contains card reader code from
; 12644..13732.  Code in 67 and 97 is almost identical.
; ------------------------------------------------------------------

m97	.equ 0	
	.include "6797cr.asm"

; ------------------------------------------------------------------
; jump extenders
; ------------------------------------------------------------------

L13733: delayed rom @05
        go to L12435

L13735: delayed rom @05
        go to L12515

L13737: delayed rom @05
        go to L12601

L13741: delayed rom @05
        go to L12544

; ------------------------------------------------------------------
; Entry point for user op to keycode decode

L13743: c - 1 -> c[w]
        p <- 1
        a exchange c[xs]
        load constant 0
        load constant 10
        p <- 0
        if a >= c[p]		; low digit of inst >= 0xa?
          then go to L12413	;    yes, special
        delayed rom @05		;    no, handle the 0-9 case
        go to L12400

; ------------------------------------------------------------------
; fill

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

; ------------------------------------------------------------------
; Bank switch entry points

        0 -> c[w]		; from S3764 - keycode decode
        go to L13743

        go to L13733		; from L3766

        go to L13735		; from L3767

        delayed rom @06		; from L3770 - card inserted
        go to card_inserted

        delayed rom @06		; from L3772 - WDATA
        go to wdata

        go to L13737		; from L3774

        go to L13741		; from L3775

        nop

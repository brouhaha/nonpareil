; ROM source code from U.S. Patent 4,177,520 and other sources
; Copyright 2004, 2006 Eric L. Smith <eric@brouhaha.com>
; $Id$
;
; Verified to match 25 and 25C ROM part numbers:
;     1818-0168 (addresses 0000-1777) ROM/anode driver
;     1818-0154 (addresses 2000-3777) ROM
;
; Extra column of space characters inserted before mnemonic.
; Semicolons inserted before comments.
; Nops inserted on lines with no instruction.
;
; ASCII at one time contained a left arrow character, but it was
; replaced by an underscore.  The left arrow character as been replaced
; by the digraph "<-".
;
; Some instances of "if n/c go to" have been replaced with "go to" in order
; to avoid assembler warnings.

	.arch woodstock

        .rom 0                     ; SUQASH NSQ9  FEB 27,75
        go to pwo                  ; power on starts here
chs1:   a exchange c[p ]           ; p = 4
        0 - c - 1 -> c[p ]
        a exchange c[p ]
        go to deeex4
qdedp:  go to dedp                 ; connection                  005
dige7:  jsb delook                 ; normalize this mess
        go to dige8
dchs:   go to chs                  ;                             010
deeex:  jsb push                   ; push old number  :  eex     011
        m2 -> c                    ; get old normalized
        if 0 # c[m ]               ; is it non zero
          then go to deeex1
deeex2: 1 -> s eex    7            ; mark as exp
        0 -> a[wp]                 ; p= 4 or something
        if 0 # a[m ]               ; check for erasing digits
          then go to deeex6        ; ok
        jsb demask                 ; new mask
        p <- 12
        0 -> c[w ]                 ; zap
        c + 1 -> c[p ]             ; a one
        b exchange c[p ]           ; copy into digits
        b -> c[p ]                 ; again
        m2 exchange c              ; save normalized
deeex1: jsb deb                    ; put in dp in b
        p <- 4
        if 0 = b[wp]               ; no dp under exp
          then go to deeex2
        go to deout
digent: if 1 = s eex    7          ; digit entry                 035
          then go to deeex3        ; new dig is in a0, old is
dige0:  jsb push
dige1:  b -> c[w ]                 ; copy old digits
        p <- 1
dige2:  c + 1 -> c[p ]             ; check for f
        if n/c go to dige3         ; nope
        shift left a[w ]           ; move over new digit
        p + 1 -> p                 ; next place
        if p # 13                  ; at left of display
          then go to dige2         ; nope
dige5:  p - 1 -> p
        a exchange c[wp]
dige6:  p - 1 -> p                 ; back up
        c -> a[w ]                 ; copy
        c - 1 -> c[wp]             ; f you
        a exchange c[x ]           ; a is fff, c is 000
        decimal
        if 0 # a[m ]               ; any signifacence
          then go to dige7         ; yes
        0 -> a[ms]                 ; zappo
dige8:  a exchange c[ms]           ; swap back
dige9:  m2 exchange c              ; save normalized in m2
dige10: a exchange b[w ]
deout1: jsb deb                    ; make dp mask etc
deout:  a exchange b[w ]
deout2: if 1 = s stop   1
          then go to $go           ; keep running
        a exchange b[w ]
$ncode: if 0 = s runpgm 3          ; loading
          then go to $sst4
        delayed rom 1
        go to $plain
deeex3: p <- 0                     ; new eex digits           b29
        a exchange b[p ]           ; dp# to a0, new dig to b0
        a exchange b[w ]           ; old digs, and new dig in a
        p <- 1
        shift left a[wp]           ; new to 1
        p <- 3
        shift left a[wp]           ; old,new to 32
deeex4: p <- 4
        shift right a[wp]          ; signnewold to 321
        shift right a[wp]          ; go 210
deeex6: m2 -> c                    ; get old value
        a exchange c[w ]
        c -> a[x ]                 ; copy new exp
        decimal
        if 0 = c[xs]               ; is it positive
          then go to deeex5
        0 -> c[xs]                 ; the old signed mag to tens
        0 - c -> c[x ]             ; trick
deeex5: a exchange c[ms]           ; disp in a, real in c
        jsb deb0                   ; put up dp
        jsb $dmeex                 ; move exp left
        a exchange c[ms]           ; disp man into c, real in a
        jsb delook                 ; normalize c
        a exchange c[ms]
        jsb $over0                 ; check size
        m2 exchange c              ; save value
        if 1 = s over   11         ; any correction
          then go to $qthr3
        go to deout                ;                          e
delook: a exchange b[x ]           ; save exp:  normalize entrb13
        0 -> a[x ]
        f -> a[x]                  ; get dp#
        a + c -> c[x ]             ; correct exp
        p <- 12
delok1: if 0 # c[p ]
          then go to deb2          ; fini
        c - 1 -> c[x ]             ; down exp
        p - 1 -> p                 ; next digit
        if 1 = s eex    7          ; in enter exp
          then go to delok1
        shift left a[m ]           ; normalize mantissa
        go to delok1               ;                          e
chs:    a exchange b[w ]           ; digits,dp# to a  :chs herb9
        p <- 4
        if 1 = s eex    7
          then go to chs1
        0 - c - 1 -> c[s ]
        c -> a[s ]                 ; copy sign
        if 0 = s firdig 8          ; chs to old value
          then go to $qthr4
        go to dige9                ;                          e
$dmeex: p <- 4                     ; make mask and move exp ovb8
        0 -> a[p ]
        a + 1 -> a[p ]
        a + 1 -> a[p ]             ; a two for minus sign
        a -> b[p ]                 ; into b
        shift left a[wp]
        shift left a[wp]           ; exp to 432
        return                     ;                         e
dige4:  if 1 = s dp     6          ; was dp hit
          then go to dige5         ; yes
        f exchange a[x]
        a + 1 -> a[x ]             ; move dp right
        f exchange a[x]
        go to dige5                ; always
	nop	    
clrpgm: 0 -> c[w ]                 ; clear program            b10
        c -> data address          ; turn on chip
        c -> register 9
        c -> register 10
        c -> register 11
        c -> register 12
        c -> register 13
        c -> register 14
        c -> register 15
        return                     ;                          e
dedp:   if 0 = s eex    7          ; handle dp here
          then go to dedp1
        clear status               ; fix dp after dp prob
dedp1:  1 -> s dp     6            ; decimal point here
        if 0 = s firdig 8          ; first digit
          then go to dige0         ; yes
        go to deout1
er/s:   if 0 = s runpgm 3          ; r/s key here                221
          then go to $er/s         ; loading
        if 1 = s f      9
          then go to $qthr1        ; yes
        if 1 = s g      10
          then go to $qthr1
        0 -> s bst    4
        1 -> s stop   1            ; turn me on
        delayed rom 3
        go to $er/s2
deb3:   shift right b[m ]          ; move dp right
        go to deb1
	nop	    
pwo:    c -> data address         ; power on here
        clear data regs
        c + 1 -> c[x ]            ; start at fixed two
        c + 1 -> c[xs]
        c + 1 -> c[s ]            ; start as degree
        c + c -> c[w]             ; double
        m1 exchange c             ; start as fixed, deg, step 00
        0 -> c[w ]
outpu0: m2 exchange c             ; save zero value
$outpu: display off               ; start of output              247
        decimal
        0 -> b[w ]
        0 -> a[w ]
        f exchange a[x]           ; start dp num at zero
        jsb deb                   ; make b mask, a = 0
        m1 -> c                   ; get status
        c -> a[x ]                ; get num of digits
        0 -> a[xs]                ; clear
        delayed rom 2
        go to $outpz
overf2: p <- 12                   ; mark as bad news
        0 -> c[wp]                ; overflow
        c - 1 -> c[wp]            ; all 9s
        0 -> c[xs]                ; positive exp
        return
overf1: 1 -> s over   11          ; mark as too big ro small
        c + c -> c[xs]            ; too positive or too neg
        if n/c go to overf2       ; positive
overf5: 0 -> c[w ]                ; underflow
        return
$pause: if 0 = s stop   1         ; continuation of pause keyb9
          then go to $ncode       ; regular output
        display toggle
        0 -> c[w ]
pause2: c + 1 -> c[w ]            ; count to 100
        c + 1 -> c[w ]            ; half time
        if 0 = c[m ]
          then go to pause2
        go to deout2              ; finished                 e
$overf: m2 -> c                   ; overflow/underflow       b13
$over0: decimal                   ; other entry point
        p <- 0                    ; mark as uncorrected
        if 0 = c[m ]              ; if no signif
          then go to overf5
overf3: if 0 = c[xs]              ; positive exp
          then go to overf4       ; zero exp sign, so good
        c - 1 -> c[x ]            ; offset for -100
        c + 1 -> c[xs]
        c - 1 -> c[xs]            ; look for 9
        if n/c go to overf1       ; bad here
        c + 1 -> c[x ]            ; unoffset
overf4: return                    ;                          e
echs:   if 0 = s f      9         ; chs key her                  322
          then go to $echs1
        0 -> a[w ]                ; step zero
        if 1 = s runpgm 3         ; if running
          then go to $qgto2       ; put to top of memory
        jsb clrpgm                ; clear program here
        delayed rom 3
        go to $qgto2              ; to top of memory
dige3:  c - 1 -> c[p ]            ; correct non f digit
        if p # 3                  ; off end on right
          then go to dige4        ; no
        1 -> s dp     6
        0 -> c[x ]                ; no new digit
        go to dige6
deb0:   a exchange b[w ]          ;                          b14
deb:    0 -> a[w ]                ; make new b mask here
        a + 1 -> a[s ]            ; a one for dp
        shift right a[w ]
        a + 1 -> a[s ]
        a + 1 -> a[s ]            ; a two for minus sign
        a exchange b[ms]          ; mask into b, ax still in s
        f -> a[x]                 ; get dp#
        p <- 0
deb1:   a - 1 -> a[p ]
        if n/c go to deb3
deb2:   a exchange b[x ]          ; restore a x
        0 -> b[x ]                ; clear out the 9
        return                    ;                          e
push:   if 1 = s firdig 8         ; to shove or not to shove
          then go to push2        ; that is the question
        0 -> c[w ]
        m2 exchange c
        if 0 = s push   2
          then go to push1
        c -> stack                ; shove
push1:  1 -> s push   2           ; protect new number
demask: 0 -> c[w ]                ; new sets of fs for new number
        binary
        c - 1 -> c[w ]            ; f you
        f exchange a[x]           ; new digit in f
        0 -> a[w ]                ; zp
        f exchange a[x]           ; zap to dp#, new digit in a
        0 -> c[s]                 ; start as positive
        b exchange c[w ]
push2:  1 -> s firdig 8
        return
        .rom 1                    ; SQUASH NSQ11  JULY 29,75
esto1:  if 1 = s op     4         ; is it an arith op        b21
          then go to k-.
        a exchange b[w ]
        p <- 0
        a exchange c[w ]
        load constant 12
        p <- 0
        a exchange c[p ]
        a + c -> a[p ]            ; make code into a0
        jsb eshove
        if 1 = s runpgm 3
          then go to ercl2
        shift left a[w ]
        p <- 1
        load constant 4
        p <- 1
        a + c -> a[p ]            ; display code in a1
        a + 1 -> a[x ]            ; a one
        shift left a[w ]
        shift left a[w ]
        go to ercl2               ;                          e
eeng:   c + 1 -> c[x ]            ; eng 7                    b14
$esci:  c + 1 -> c[x ]            ; sci 6
$efix:  c + 1 -> c[x ]
        a exchange b[w ]
        c -> a[p ]                ; copy value p=0
        jsb k4                    ; count to four
        jsb eshov1
        if 1 = s runpgm 3
          then go to egto2        ; running
        shift left a[w ]          ; 320->431
        shift left a[w ]          ; 431->542
        shift right a[x ]         ; 2->1  0 into 2
        a + 1 -> a[xs]            ; a one
        if n/c go to egto1        ; always                   e
zap:    0 -> c[w ]                ; f u time
        c - 1 -> c[w ]
        p <- 3
        return
$error: binary                    ; the one and only error   b16 047
        0 -> c[w ]                ; zap
        m2 exchange c             ; make x vlaue zero
        m2 -> c
        c - 1 -> c[w ]            ; f u
        0 -> s push   2           ; unprotect zero
        p <- 12
        load constant 14          ; E
        load constant 10          ; r
        load constant 10          ; r
        load constant 12          ; o
        load constant 10          ; r
$err1:  clear status              ; overflow in reg here
        a exchange c[w ]          ; put  up error
        0 -> c[w ]
        0 -> b[w ]                ; no mask
        select rom 3              ;                          e   067
$wait:  0 -> s key    15          ; wait here for key up     b8
        p <- 7
wait1:  p - 1 -> p
        if p # 0
          then go to wait1
        if 1 = s key    15
          then go to $wait
        return                    ;                          e
krcl:   go to ercl                ; recall key                   100
ksto:   go to esto                ; store key                    101
kroll:  c + 1 -> c[x ]            ; roll down key                102
kxexy:  if n/c go to kyexy1       ; x exchange y key             103
ksig+:  c + 1 -> c[x ]            ; sigma plus key               104
        if n/c go to kroll        ; always
ercl:   jsb zap                   ;                          b13
        load constant 2
        load constant 4
        jsb crap
        p <- 3
        load constant 11
ercl2:  jsb efirst                ; wait for more news
ercl3:  if 1 = s big    13
          then go to ercl4        ; digit is 8 or 9
        c -> a[x ]
        shift left a[x ]
        shift right c[w ]
        go to egto3               ;                          e
$size:  c -> a[w ]                ; small angle trig here    b13
        if 1 = s cos    7
          then go to size1        ; dont handle cos
        if 0 = c[xs]              ; posit exp
          then go to size1
        0 -> c[w ]                ; zap
        p <- 0
        load constant 5
        a exchange c[w ]
        a + c -> a[x ]            ; look for less 10-5
        if n/c go to size2        ; too small so fix
        c -> a[w ]                ; copy again
size1:  return                    ;                          e
k9:     c + 1 -> c[x ]            ; 9 key                        140
k8:     if n/c go to k7.          ; 8 key                        141
k7:     go to k6.                 ; 7 key                        142
k-:     if 1 = s sto    14        ; minus key                    143
          then go to esto1
k-.:    p <- 1
        load constant 15          ; for plain other keys
        go to eplai3
size2:  if 0 = s f      9
          then go to $retu        ; non arc
        c -> a[w ]                ; copy
        delayed rom 7
        go to $ata31              ; arc trig fix july 29
k5.:    1 -> s small  0           ; not smaller than 4
        c + 1 -> c[x ]
k3.:    c + 1 -> c[x ]
k3:     c + 1 -> c[x ]            ; 3 key                        160
k2:     c + 1 -> c[x ]            ; 2 key                        161
k1:     if n/c go to k1.          ; 1 key                        162
k*:     c + 1 -> c[x ]            ; * key                        163
        if n/c go to k+           ; always
$plain: 0 -> s f      9           ; start encode here
        0 -> s g      10
        go to plain
egto:   if 1 = s f      9         ; gto key here             b24
          then go to eeng         ; format
        jsb zap
        load constant 1
        load constant 3
        jsb crap
        jsb efirst
        if 1 = s small  0
          then go to eplai1       ; bigger than 4
        a exchange b[w ]
        c -> a[p ]                ; p=0  copy digit
        jsb eshov1                ; digit to c3
        if 1 = s runpgm 3         ; running
          then go to egto2
        shift left a[w ]          ; 431
egto1:  shift left a[w ]          ; to 542
egto2:  jsb efirst
        a exchange c[x ]
        0 -> c[x ]
egto3:  shift right c[w ]         ; 3->2
        shift right c[x ]         ; 2->1
        a + c -> c[x ]            ; total code
ethru:  delayed rom 3
        go to $thru               ;                          e
kr/s:   select rom 0              ; r/s key                      220
k.:     go to k..                 ; . key                        221
k0:     return                    ; 0 key                        222
k/:     c + 1 -> c[x ]            ; 0 key                        223
        if n/c go to k*           ; always
ercl4:  clear status              ; reset digit entry
        go to eplai1
ef:     jsb zap                   ; f key
        load constant 1
        load constant 4
        clear status
        1 -> s f      9           ; mark as f
        go to eg1
k7.:    1 -> s big    13
        c + 1 -> c[x ]
k6.:    c + 1 -> c[x ]
k6:     c + 1 -> c[x ]            ; 6 key                        240
k5:     if n/c go to k5.          ; 5 key                        241
k4:     go to k3.                 ; 4 key                        242
k+:     c + 1 -> c[x ]            ; + key                        243
        if n/c go to k-           ; always
kyexy1: c + 1 -> c[x ]
        if n/c go to kclx         ; always
k1.:    c + 1 -> c[x ]            ; end of digit count up
        return
crap:   if 1 = s runpgm 3         ; twist my arm
          then go to crap2
        b exchange c[w ]
        0 -> a[w ]
crap2:  a exchange b[w ]
        0 -> c[w ]
        return
kf:     go to ef                  ; f key   gold                 260
kgto:   go to egto                ; gto key                      261
kbst:   select rom 3              ; bst key                      262
bsst:   select rom 3              ; sst key                      263
kg:     jsb zap                   ; g kye  blue              b23 264
        load constant 1
        load constant 5
        clear status
        1 -> s g      10          ; mark as g key
eg1:    jsb crap                  ; which display
plain:  0 -> s sto    14          ; start keycode building here
        jsb efirs1                ; wait for countdown return
eplai1: p <- 1
        load constant 12          ; plain digit
eplai3: p <- 1
        if 1 = s g      10
          then go to eplai2
        if 0 = s f      9
          then go to ethru
        c - 1 -> c[p ]
eplai2: c - 1 -> c[p ]
        if n/c go to ethru        ; always
esto:   jsb zap                   ; store key here           b10
        load constant 2
        load constant 3
        jsb crap
        clear status
        1 -> s sto    14          ; mark as store
        p <- 3
        load constant 10
        jsb efirs1                ; wait
        go to ercl3               ;                          e
keex:   go to eeex                ; eex key                      320
kchs:   select rom 0              ; chs key                      321
        nop                       ; royal hole                   322
kenter: go to eenter              ; enter key                    323
kclx:   c + 1 -> c[x ]            ; clx key                      324
eeex:   c + 1 -> c[x ]
$echs1:  c + 1 -> c[x ]
eent1:  c + 1 -> c[x ]
$er/s:  c + 1 -> c[x ]
k..:    c + 1 -> c[x ]
        1 -> s op     4           ; mark as not arith op
        go to k/                  ; always
eenter: if 1 = s f      9         ; enter key here           b12
          then go to eent2
        if 0 = s g      10
          then go to eent1
eent2:  if 1 = s runpgm 3         ; running
          then go to $qthr1       ; go form the output
displ5: 0 -> s runpgm 3           ; try to clear switch
        if 0 = s runpgm 3
          then go to $sst4        ; switch changed to prgm
        if 0 = s key    15
          then go to displ5       ; no key
        go to displ3
efirst: clear status              ; display loop
efirs1: display toggle            ; display loop
displ1: jsb $wait                 ; wait for the key to come up
        hi i'm woodstock
        if 1 = s runpgm 3
          then go to displ5       ; running
displ6: if 1 = s runpgm 3
          then go to $outpu       ; switch changed to run
        if 0 = s key    15
          then go to displ6       ; no key
displ3: display off
        binary
        p <- 0                    ; set pointer
        0 -> c[x ]                ; put new code here
        a exchange b[w ]
        0 -> s big    13
        keys -> rom address       ; go do it                 e
        nop
eshov1: a exchange c[w ]
eshove: shift left a[w ]          ; 0->1                     b5
        shift left a[w ]          ; 1->2
        shift left a[w ]          ; 2->3
        a exchange c[w ]
        return                    ;                          e
        .rom 2                    ; SQUASH NSQ14  AUG   6,75
f0:0:   go to fslice              ; 0,0                          000
        go to fslice              ; 0,1                          001
        go to fslice              ; 0,2                          002
        go to fslice              ; 0,3                          003
        go to fslice              ; 0,4                          004
        go to ffix                ; 0,5                          005
        go to fsci                ; 0,6                          006
        go to feng                ; 0,7                          007
fvoid:  delayed rom 1
        go to $error
        1 -> s f      9           ; 0,10                         012
        1 -> s g      10          ; 0,11                         013
        go to frow                ; 0,12                         014
        1 -> s f      9           ; 0,13                         015
        1 -> s g      10          ; 0,14                         016
        go to fplain              ; 0,15                         017
        go to fsto                ; 1,10  store                  020
        go to frcl                ; 1,11 recall                  021
        c + 1 -> c[p ]            ; 1,12  store -                022
        c + 1 -> c[p ]            ; 1,13  store +                023
        c + 1 -> c[p ]            ; 1,14  store *                024
        decimal                   ; 1,15                         025
        0 - c - 1 -> c[p ]        ; invert
        c - 1 -> c[p ]
        c - 1 -> c[p ]
        p <- 5
        load constant 1
        p <- 9
fsto:   load constant 2           ; p= 6 or 9
        load constant 3
fsto1:  a exchange c[w ]
        go to fsto2
frcl:   load constant 2
        load constant 4
        go to fsto1
        jsb f25                   ; 2,3   25                     043
        c + 1 -> c[xs]            ; 2,4    22                    044
        if n/c go to f21          ; 2,5    21                    045
        c + 1 -> c[xs]            ; 2,6    34                    046
        c + 1 -> c[xs]            ; 2,7    33                    047
        c + 1 -> c[xs]            ; 2,8    32                    050
        if n/c go to f31          ; 2,9    31                    051
        c + 1 -> c[xs]            ; 2,10   74                    052
        jsb f73                   ; 2,11     73                  053
        c + 1 -> c[p ]            ; 2,12   71                    054
        c + 1 -> c[p ]            ; 2,13   61                    055
        c + 1 -> c[p ]            ; 2,14   51                    056
        c + 1 -> c[p ]            ; 2,15   41                    057
f31:    c + 1 -> c[p ]            ;        31
f21:    c + 1 -> c[p ]            ;        21
f11:    c + 1 -> c[xs]            ;        11
        c + 1 -> c[p ]            ;        10
        a exchange c[w ]
        go to fthru
$form:  display off               ; key cooridinates
        c -> a[x ]                ; start here, code in c10 c2-0
        0 -> c[ms]
        binary
        c - 1 -> c[ms]            ; f you
        p <- 6
        0 -> s f      9
        0 -> s g      10
        0 -> s top    14
        jsb fgo0                  ; only ret on eng,fix,sci
        1 -> s top    14          ; mark as possible format
fslice: shift left a[x ]          ; move to other digit
        0 -> a[xs]
        decimal
        a + 1 -> a[x ]            ; force decimal correction
        binary
        if 0 # a[xs]
          then go to fstoop       ; store op
fgto:   if 1 = s top    14        ; gto here
          then go to feng1        ; but really formatting
        load constant 1           ; p=  6
        load constant 3
        p <- 3
        a exchange c[w ]
        shift left a[wp]
        go to fsto3
fstoop: 0 -> c[p ]                ; store op here
        a -> rom address          ; go to which op
feng1:  shift right c[wp]         ; format continues
        load constant 1           ; p=6
        p <- 9
        jsb ff1                   ; load a 2 (f)
        a exchange c[ms]          ; up display
        0 -> a[xs]
fsto2:  p <- 3
fsto3:  shift left a[wp]
fthru:  binary                    ; end of formatting
        m1 -> c                   ; finish formatting
        delayed rom 3
        go to $fthr0
feng:   c + 1 -> c[p ]
fsci:   c + 1 -> c[p ]
ffix:   c + 1 -> c[p ]
        c + 1 -> c[p ]
        return
fplain: jsb ff?
        0 - c - 1 -> c[x ]        ; invert last digit
        c -> a[x ]
        shift left a[x ]          ; 0->1
        0 -> a[xs]
        p <- 3
        0 -> c[wp]
fgo2:   a + 1 -> a[xs]            ; land in f2:*
fgo1:   a + 1 -> a[xs]            ; land in f1:*
fgo0:   a -> rom address          ; land in f0:*
ff?:    if 0 = s g      10        ; load f or g
          then go to ff3
        if 1 = s f      9
          then go to ff1
fg1:    load constant 1           ; make a g
        load constant 5
        go to ff2
ff1:    load constant 1           ; make a f
        load constant 4
ff2:    load constant 15
ff3:    return
f25:    c + 1 -> c[xs]
f73:    c + 1 -> c[xs]            ; 73
        c + 1 -> c[xs]            ; 72
        return
	nop
	nop
frow:   jsb ff?
        a exchange c[w ]
        shift left a[x ]
        0 -> a[xs]
        go to fsto2
$outpz: 0 -> s top    14          ; fix aug 6,75
        c - 1 -> c[xs]            ; check for zero
        if n/c go to sci0
        1 -> s top    14          ; mark as engineering
        a + 1 -> a[x ]
        a + 1 -> a[x ]
        if n/c go to sci0.5       ; always
sci0:   c - 1 -> c[xs]            ; check for sci
        if n/c go to fix1         ; nope
sci0.5: m2 -> c                   ; get value again
        jsb round
sci1:   a - 1 -> a[xs]            ; check for 10 to 100
        if 0 # a[xs]
          then go to sci2         ; nope
        c -> a[w]                 ; no rounding
        go to sci4
sci2:   jsb zappo                 ; blank rest of display
        a exchange b[x ]
        if 0 = s top    14        ; if scientific
          then go to sci5
        a -> b[x ]                ; engineering format here
        b exchange c[x ]
        if 0 = c[xs]
          then go to eng1
        0 -> c[xs]                ; negative correction
        c - 1 -> c[x ]
eng1:   c - 1 -> c[x ]            ; start of  mod loop
        if n/c go to eng2
eng5:   b -> c[x ]                ; nod 0
sci5:   a exchange c[x ]          ; scientific again
        if 0 = c[xs]
          then go to sci3         ; tens comp to signed mag
        0 - c -> c[x ]
        c - 1 -> c[xs]
sci3:   a exchange c[x ]          ; put display up
sci4:   0 -> b [x ]
        delayed rom 0
        jsb $dmeex                ; mask b reg and move a exp over
outpu2: c -> a[s ]                ; copy sign
        clear status              ; mark as run
        0 -> s power  5
        if 1 = s power  5         ; ok, so leave
          then go to $pause
        p <- 12
outpu3: b exchange c[p ]
        0 - c - 1 -> c[p ]        ; invert dps
        b exchange c[p ]
        p - 1 -> p                ; count over
        if p = 4
          then go to $pause
        go to outpu3
eng2:   c - 1 -> c[x ]            ; mod 1
        if n/c go to eng3
        go to eng4
eng3:   c - 1 -> c[x ]            ; mod 2
        if n/c go to eng1
        a - 1 -> a[x ]
        shift right b[m ]         ; mod 2
eng4:   a - 1 -> a[x ]
        shift right b[m ]         ; mod 1
        go to eng5
zappo:  binary                    ; f you routine
        0 -> a[wp]
        a - 1 -> a[wp]
        decimal
        return
fix1:   m2 -> c                   ; get value:  fixed format
        a + c -> a[x ]            ; exp + num of digits
        1 -> s big    13          ; mark as fixed
        jsb round
        if 0 # a[xs]              ; negative exp
          then go to fix2
        jsb zappo
        a exchange b[x ]
        p <- 1
        if 0 # a[p ]              ; look at exp
          then go to fix8         ; too big for fixed ever
fix4:   a - 1 -> a[x ]            ; count down exp
        if n/c go to fix5
fix6:   0 -> a[x ]
        a exchange b[x ]          ; fff to a, 000 to b[x]
        go to outpu2              ; that is all
fix5:   shift right b[m ]         ; move dp right
        go to fix4
fix2:   shift right a[m ]         ; neg exp fixed format
        a + 1 -> a[x ]            ; up your exp
        if n/c go to fix2
        m1 exchange c             ; swap status and value
        c -> a[x ]                ; get num of digits
        m1 exchange c             ; swap status and value
        0 -> a[xs]
        p <- 12
fix3:   p - 1 -> p                ; move p right
        a - 1 -> a[x ]            ; counting down num of digits
        if n/c go to fix3         ; loop
        0 -> a[wp]                ; erase covered digits
        if 0 # a[m ]              ; is display zero
          then go to fix9         ; nope
fix8:   p <- 4                    ; yes, so full sci
        jsb round2
        go to sci1
fix9:   jsb zappo
        a exchange b[x ]
        go to fix6
round4: if p = 2                  ; off end of display
          then go to round2       ; yes
round1: p - 1 -> p                ; move p right
rounda: a - 1 -> a[x ]            ; down num of digits
        if n/c go to round4
        go to round2              ; am at right place
round:  p <- 12                   ; round off routine
        a + 1 -> a[x ]            ; check for -1
        if n/c go to rounda       ; no
round2: 0 -> a[w ]
        c -> a[wp]
        a + c -> a[m ]            ; double junk
        if n/c go to round3
        a + 1 -> a[s ]
        shift right a[ms]
        a + 1 -> a[x ]            ; up the exp
        if 0 = s big    13        ; sci ro eng
          then go to round3
        p - 1 -> p                ; fixed format only
round3: a -> b[x ]                ; copy exp of display
        return
        .rom 3                    ; SQUASH NSQ12, AUG  1,75
q3:0:   go to qgto                ; 0   right angle slice        000
        go to qgto                ; 1                            001
        go to qgto                ; 2                            002
        go to qgto                ; 3                            003
        go to qgto                ; 4                            004
        go to qgto                ; 5                            005
        go to qgto                ; 6                            006
        go to qgto                ; 7                            007
        go to qgto                ; 8                            010
        go to qgto                ; 9                            011
        go to qsto                ; 10                           012
        go to qrcl                ; 11                           013
        go to qstoop              ; 12                           014
        go to qstoop              ; 13                           015
        go to qstoop              ; 14                           016
        go to qstoop              ; 15  storage arith            017
q4:0:   go to qslice              ; 0                            020
        go to qslice              ; 1                            021
        go to qslice              ; 2                            022
        go to qslice              ; 3                            023
        go to qslice              ; 4                            024
        c + 1 -> c[xs]            ; fix notation                 025
        c + 1 -> c[xs]            ; sci notation                 026
        if n/c go to qeng         ; eng notation                 027
qstoop: delayed rom 5
        go to $vally
        c + 1 -> c[xs]            ; f digits                     032
        select rom 5              ; g digits                     033
        select rom 0              ; digits                       034
        c + 1 -> c[xs]            ; f others                     035
        c + 1 -> c[xs]            ; g others                     036
        delayed rom 4             ; plain others                 037
        go to $qplan
$fthr0: if 0 # c[m ]              ; at zero                  b23
          then go to fthru1
        0 -> a[w ]
        a - 1 -> a[w ]            ; f u
fthru1: p <- 2
        a exchange c[w ]
fthru2: p + 1 -> p                ; move step # into place
        shift left a[w ]
        if p # 11
          then go to fthru2
        a exchange c[wp]          ; bring up rest of display
        0 -> c[w ]                ; zap
        b exchange c[w ]          ; save digits, make zero mask
        if 0 = s runpgm 3
          then go to $plain       ; loading
        display toggle            ; turn on display
        delayed rom 1
        jsb $wait                 ; wait for key to come up
        display off
        if 1 = s bst     4
          then go to $outpu       ; bst, so dont execute
        b exchange c[w ]          ; recover digits
        go to $go                 ; executing                e
erro9:  jsb errtst                ; maybe dec step #             070
        select rom 0              ; encode                       071
fetch:  m1 -> c                   ; memory fetch             b14
        c -> a[w ]                ; copy
        0 -> c[w ]
        p <- 0
        load constant 8           ; start at reg 9
        p <- 3
        load constant 7           ; # steps per word
        p <- 0
        decimal
        a - 1 -> a[m ]            ; offset
        if n/c go to fetch1       ; check for zero
        0 -> s stop   1           ; stop running
        register -> c 9           ; fix aug 1,75
        return                    ;                          e
qgto:   if p = 13                 ; execute gto here         b14
          then go to qeng1
        a exchange b[w ]          ; recover code into a10
        shift left a[w ]          ; 10 to 21
        0 -> a[ms]                ; zap all the shit
        shift left a[w ]          ; 21 to 32
        shift left a[w ]          ; 32 to 43
$qgto2: m1 -> c                   ; get status
        a exchange c[m ]          ; stick new step# in
        if 0 # c[m ]              ; is step zero
          then go to qgto1        ; no
        0 -> s stop   1           ; stop running
qgto1:  m1 exchange c             ; save
        go to $qthr1              ;                          e
$thru:  if 1 = s runpgm 3         ;                          b15
          then go to execut       ; running
        b exchange c[w ]          ; code now in b10
        jsb $inc                  ; go to next step
        jsb fetch                 ; set reg, and p
        a exchange b[w ]          ; step in a10
thru1:  c + 1 -> c[m ]
        if n/c go to thru2
        data -> c                 ; get register
        a exchange c[p ]          ; insert low order
        p + 1 -> p
        a exchange c[p ]          ; insert high order
        p - 1 -> p
        c -> data
        go to sst1                ;                          e
fetch2: decimal                   ;                          b9
        a - c -> a[m ]            ; minus seven
        if n/c go to fetch1
        c -> data address         ; turn on right reg
        a exchange c[w ]          ; copy
        c -> a[w ]
fetch3: a + 1 -> a[m ]            ; up neg step num
        if n/c go to fetch4
        return                    ; pointer is set           e
mlop:   0 -> b[w ]                ; part of h.ms             b9
mlp0:   a exchange b[wp]
        shift right b[w ]
mlp2:   p <- 10
mlp3:   a + b -> a[w ]
        p - 1 -> p
        if p # 4                  ; count to 6
          then go to mlp3
        return                    ;                          e
dec:    decimal                   ; decrement step #         b6
        m1 -> c
        if 0 = c[m ]
          then go to inc1
        c - 1 -> c[m ]
        if n/c go to inc1         ; always                   e
go3:    shift right c[w ]         ; move right
        p - 1 -> p
        go to go2
ebst:   if 1 = s f      9         ; bst key here             b5
          then go to $esci
        jsb dec
        1 -> s bst    4
        go to $sst4               ;                          e
qrcl:   m2 exchange c             ; recall key               b5
        if 0 = s push   2
          then go to qrcl1
        c -> stack                ; shove it
qrcl1:  go to qthru               ;                          e
errtst: if 0 = s stop   1         ; if executing             b5
          then go to erro1        ; no
        jsb dec                   ; yes, so back one
erro1:  0 ->s stop    1           ; turn off executing
        return                    ;                          e
qslice: a -> b[x ]                ; save                     b7
qslic1: shift right c[x ]         ; move dig over
        c -> data address         ; address register
        data -> c                 ; fetch register
        shift left a[x ]
        0 -> a[xs]                ; just in case
        a -> rom address          ;                          e
qeng1:  m1 -> c                   ; get status word          b6
        shift right a[x ]         ; move digit into 0
        a exchange b[xs]          ; get eng0,sci1,fix2
        a exchange c[x ]          ; into status word
        m1 exchange c             ; restore status
        go to $qthr1              ;                          e
$er/s2: m1 -> c                   ; status word
        if 0 # c[m ]              ; not at start
          then go to er/s3
        c + 1 -> c[m ]            ; start at one
        m1 exchange c             ; save
er/s3:  go to $sst4               ; go fetch and run
qeng:   p <- 13                   ; set as marker            b4
        b exchange c[xs]          ; store count
        0 -> c[xs]
        go to qslic1              ;                          e
thru2:  shift left a[w ]          ;                          b3
        shift left a[w ]          ; move step into position
        go to thru1               ;                          e
qsto:   m2 -> c                   ; store key here           b3
        c -> data
        go to qthru               ;                          e
fetch4: p + 1 -> p
        p + 1 -> p
        go to fetch3
sst2:   shift right c[w ]
        p - 1 -> p
        go to sst3
	nop
kbst1:  go to ebst                ;                              263
esst:   if 1 = s f      9         ;                          b13 264
          then go to $efix
        0 -> s bst    4
        if 1 = s runpgm 3         ; if running
          then go to $er/s2       ; go check for zero
        jsb $inc
$sst4:  jsb fetch
sst1:   data -> c
sst3:   if p # 0
          then go to sst2
        0 -> c[xs]
        delayed rom 2
        go to $form               ;                          e
fetch1: binary                    ;                          b8
        c + 1 -> c[p ]            ; next register
        if n/c go to fetch2
        m1 -> c                   ; that was last reg
        0 -> c[m ]                ; set to zero
        m1 exchange c             ; store zero step#
fetch5: 0 -> s stop   1           ; stop
        go to $qthr1              ;                          e
$h.ms:  delayed rom 4             ; to hours,minutes,seconds b8
        jsb $dms10
        a exchange b[w ]
        jsb mlop                  ; p=6
        jsb mlop                  ; p=4
        delayed rom 6
        jsb $norm                 ; normal
        go to $retu               ;                          e
h:      delayed rom 4             ; to hours                 b16 321
        jsb $dms10
        jsb mlp0
        0 -> b[w ]
        a exchange b[wp]          ; p=4
        a exchange b[w ]
        shift left a[w ]
        jsb mlp2
        delayed rom 6
        jsb $norm
        0 -> c[w ]
        load constant 3
        load constant 6
        p <- 12                   ; set for divide
        delayed rom 5
        jsb $divid
$retu:  m2 exchange c             ; save value
qthru:  1 -> s push   2           ; function finish
$qthr1: clear status              ; end of execution             343
        delayed rom 0
        jsb $overf                ; check for size
$qthr4: m2 exchange c             ; save value
        if p # 12                 ; any correction
          then go to qthru2
$qthr3: jsb errtst
qthru2: if 0 = s stop   1         ; run or stop
          then go to $outpu       ; stop
$go:    if 1 = s key    15        ; is there a key down
          then go to fetch5       ; go turn off
        display toggle
        jsb fetch                 ; turn on reg, set p
        jsb $inc
        data -> c                 ; get register
go2:    if p # 0
          then go to go3
        0 -> c[ms]
        display off
execut: 0 -> c[xs]                ; code is in c10:  execute it
        c -> a[x ]
        a + 1 -> a[xs]
        a -> rom address          ; jump, jump, jump
$inc:   decimal                   ; increment step #
        m1 -> c
        c + 1 -> c[m ]
inc1:   m1 exchange c
        binary
        return
        .rom 4                    ; SQUASH NSQ11,9 JULY 29,75
q0:0:   go to minus               ; 0  -                         000
        go to plus                ; 1  +                         001
        go to time                ; 2  *                         002
        go to div0                ; 3  /                         003
        select rom 0              ; 4  .                         004
        go to qr/s                ; 5  r/s                       005
        go to qenter              ; 6  enter                     006
        select rom 0              ; 7  chs                       007
        select rom 0              ; 8  eex                       010
        go to qclx                ; 9  clx                       011
        go to qxexy               ; 10  x ex y                   012
        go to qroll               ; 11  roll down                013
        go to sig+                ; 12  sig +                    014
	go to erro                ; 13  no way                   015
	go to erro                ; 14  no way                   016
        go to erro                ; 15  no way                   017
q1:0:   1 -> s f      9           ; 0  x < 0     g others        020
        go to x>=0                ; 1  x>= 0                     021
        1 -> s f      9           ; 2  x # 0                     022
        go to x=0                 ; 3  x = 0                     023
        go to pi                  ; 4  pi                        024
        go to qthru1              ; 5  nop                       025
        go to erro                ; 6  no way                    026
        a + 1 -> a[s ]            ; 7  deg                       027
        a + 1 -> a[s ]            ; 8  rad                       030
        if n/c go to rad          ; 9  grd                       031
        go to percen              ; 10  percent key              032
        go to 1/x                 ; 11  1 / x                    033
        go to qthru1              ; 12  undefined                034
qenter: c -> stack                ; shove
qent1:  0 -> s push   2
        go to qthru1
q2:0:   1 -> s f      9           ; 0  x < y   f other           040
        go to x>=y                ; 1  x >= y                    041
        1 -> s f      9           ; 2  x # y                     042
        go to x=y                 ; 3  x = y                     043
        go to lastx               ; 4  last x                    044
        go to pause               ; 5  nop    pause              045
	go to erro		  ; 6  no way                    046
	go to erro                ; 7  no way                    047
        go to qclrrg              ; 8  clear registers           050
        go to qclr                ; 9  clear stack               051
        go to mean                ; 10  mean                     052
        go to stddev              ; 11  standard dev             053
        go to sig-                ; 12  sig -                    054
1/x:    0 -> a[w ]                ; 1 / x key
        a + 1 -> a[p ]            ; a one
        if n/c go to div1         ; always
$qplan: shift left a[x ]          ; others
        a exchange c[xs]          ; get either 0,1,2
        m2 -> c                   ; get x
        p <- 12
        decimal
        0 -> a[s ]                ; for trig mode
        0 -> s f      9
        a -> rom address          ; go jump
stddev: jsb shove                 ;                          b29
        register -> c 7           ; standard deviation
        c -> a[w ]                ; copy
        jsb mpy                   ; r7**2
        jsb overf4                ; check size
        register -> c 3           ; count
        1 -> s err    8
        p <- 12
        jsb div
        jsb overf4
        register -> c 6
        a exchange c[w ]
        jsb sub
        m2 exchange c             ; save this term
        register -> c 3           ; count
        c -> a[w ]
        0 -> c[w ]
        c + 1 -> c[p ]            ; a one
        jsb sub                   ; subtract one
        0 -> a[w ]
        a + 1 -> a[p ]            ; a one
        jsb div
        m2 -> c                   ; get term
        jsb mpy
        jsb overf4
        0 -> c[s ]
        delayed rom 7
        jsb $sqrt
        go to qrcl                ;                          e
dms11:  shift right b[w ]         ; part of hms              b6
        a + 1 -> a[x ]
        if n/c go to dms11        ; loop on exponenet
        0 -> a[w ]
        p <- 6
        return                    ;                          e
percen: y -> a                    ; percent key              b6
        c -> register 8           ; save lastx, what a waste
        c - 1 -> c[x ]
        c - 1 -> c[x ]            ; divide by 100
perce1: jsb mpy
        go to ret                 ;                          e
part:   0 -> a[w ]                ;                              141
        if 0 # c[xs]
          then go to part2        ; all fractional
        a exchange c[w ]
        a -> b[x ]                ; save exp
part1:  p - 1 -> p                ; p starts at 12
        if p = 2
          then go to part3        ; all integer
        a - 1 -> a[x ]            ; dec exp
        if n/c go to part1        ; loop
        a exchange c[wp]          ; int to a, frac to c
part3:  b -> c[x ]                ; exp now in cx
        0 -> a[x ]                ; zap
        a exchange c[ms]          ; int in c, frac in am
        if 0 = s f      9 
          then go to ret          ; int out here
        delayed rom 6
        jsb $norm                 ; normalize
part2:  if 1 = s f      9
          then go to ret
        0 -> c[w ]                ; integer
        go to ret
minus:  c -> register 8           ; save last x              b5
        0 - c - 1 -> c[s ]
minus1: stack -> a
        jsb add
        go to qrcl                ;                          e
time:   stack -> a                ; times key
time1:  c -> register 8           ; save last x
        jsb mpy
	go to qrcl
	nop
	nop
	nop
	nop
	nop
qr/s:   0 -> s stop   1           ; r/s key, turn off
        go to qthru1
plus:   c -> register 8           ; save last x
        go to minus1
sig-:   c -> a[w ]                ; sigma minus              b7
        c -> register 8           ; save lastx, what a waste
        0 - c - 1 -> c[s ]
        m2 exchange c             ; change sign of x
        m2 -> c
        1 -> s g      10          ; mark as sig -
        go to sig+2               ;                          e
overf4: delayed rom 0             ;                          b5
        jsb $over0
        if p = 12
          then go to qrcl         ; correction
        return                    ;                          e
mean:   jsb shove                 ;                          b7
        register -> c 7           ; mean
        a exchange c[w ]
        register -> c 3           ; get count
mean1:  1 -> s err    8
        jsb div
ret:    go to qrcl                ; function return          e   233
x=y:    y -> a                    ; x=y, x#y                 b9
        jsb sub
x=0:    if 0 # c[m ]              ; x=0, x#0
          then go to no
yes:    if 0 = s f      9
          then go to qthru1       ; true
yes1:   delayed rom 3             ; skip here
        jsb $inc
        go to qthru1              ;                          e
pause:  clear status              ; pause key
        select rom 0              ; output                       246
pi:     jsb shove
        delayed rom 5
        go to $pikey
sig+:   c -> a[w ]                ; sigma plus               b24
        c -> register 8           ; lastx, how dumb
        0 -> s g      10          ; mark as sig+
sig+2:  jsb mpy                   ; x**2
        1 -> s f      9           ; mark as sig+
        register -> c 6           ; get x**2 sum
        delayed rom 5
        jsb $qsto1                ; add into reg
        register -> c 7           ; get x sum
        delayed rom 5
        jsb $qsto+
        m2 -> c                   ; get x
        y -> a                    ; get y
        jsb mpy                   ; make xy
        register -> c 5           ; get sumxy
        delayed rom 5
        jsb $qsto1                ; add to sum xy
        y -> a                    ; copy y again
        a exchange c[w ]
        c -> a[w ]                ; copy y
        if 0 = s g      10        ; if not sigma minus
          then go to sig+1
        0 - c - 1 -> c[s ]        ; invert sign
sig+1:  select rom 5              ; fall over                e   301
x>=y:   y -> a                    ; x>=y x<y compairsons     b8
        a exchange c[w ]
        jsb sub                   ; subtract
x>=0:   if 0 = c[s ]              ; x>=0, x< 0
          then go to yes
no:     if 0 = s f      9
          then go to yes1         ; skip if false
        go to qthru1              ; true                     e
div0:   stack -> a                ; divide key
div1:   c -> register 8           ; save last x
        1 -> s firdig 8
	jsb div
	go to qrcl
qclr:   clear registers           ; clear stack key
qclx:   0 -> c[w ]
$qclx1: m2 exchange c             ; save value
        go to qent1
sub:    0 - c - 1 -> c[s ]
add:    delayed rom 5
        go to $add3
qxexy:  stack -> a                ; x ex y key here
        c -> stack                ; shove it
        a exchange c[w ]
        go to qrcl
mpy:    select rom 5              ;                              332
div:    select rom 5              ;                              333
qroll:  down rotate               ; roll down key happens here
        go to qrcl
lastx:  jsb shove                 ; last x key here
        register -> c 8           ; last x key
qrcl:   m2 exchange c             ; save value
$qthr:  1 -> s push   2
qthru1: select rom 3              ; end of executing             342
$dms10: c -> a[w ]                ; part of h.ms             b10
        b exchange c[m ]
        0 -> c[x ]
        p <- 0
        load constant 5
        a - c -> a[w ]
        if 0 # a[xs]
          then go to dms11        ; value is too big
erro:   delayed rom 1
        go to $error              ; error exit               e
qclrrg: 0 -> c[w ]                ; clear registers          b11
        c -> data address
        c -> register 0
        c -> register 1
        c -> register 2
        c -> register 3
        c -> register 4
        c -> register 5
        c -> register 6
        c -> register 7
        go to qthru1              ;                          e
rad:    m1 exchange c             ; get status  : set trig mode
        a exchange c[s ]          ; insert new code
        m1 exchange c             ; get status
        go to qthru1
shove:  if 0 = s push   2         ; to shove or not to shove
          then go to shove1
        c -> stack                ; cram it
shove1: return
        .rom 5                    ; SQUASH  NSQ11,9 JULY 29,75
z0:0:   go to h1                  ; 0,0  hours     g digit       000
        go to frac                ; 0,1   fractional part        001
        go to x**2                ; 0,2  x squared               002
        go to abs                 ; 0,3  abs                     003
        go to asin                ; 0,4  arcsin                  004
        go to acos                ; 0,5  arc cosine              005
        go to atan                ; 0,6  arc tangent             006
        go to exp                 ; 0,7  e to x                  007
        go to e10tox              ; 0,8  10 to x                 010
        go to polar               ; 0,9  polar                   011
h.ms1:  delayed rom 3
        go to $h.ms
        go to qsto-               ;                              014
        go to $qsto+              ; storage arith here           015
        go to qsto*               ;                              016
        go to qsto/               ;                              017
z1:0:   go to h.ms1               ; 1,0  hours.mins,sec          020
        go to int                 ; 1,1  integer part            021
        go to polar2              ; 1,2  square root             022
        go to ytox                ; 1,3  y to x                  023
        go to sin                 ; 1,4  sine                    024
        go to cos                 ; 1,5  cosine                  025
        go to tan                 ; 1,6  tangent                 026
        go to ln                  ; 1,7  ln                      027
        go to log                 ; 1,8  log                     030
        go to rect                ; 1,9  rectangular             031
overfz: delayed rom 0             ; in c, returns in c
        go to $over0
valley: shift left a[x ]          ; enter here                   034
        a exchange c[xs]          ; get 0 or 1
        m2 -> c                   ; get value
        c -> register 8           ; store last x
$vally: 0 -> b[w ]                ; zap                          040
        p <- 12
        clear status
        decimal
        a -> rom address          ; go to it (rom3)
	nop
$err5:  select rom 1              ; error exit                   046
qsto-3: if 0 = s f      9
          then go to retur5       ; store op exit
        return                    ; sig+-
$add3:  p <- 12                   ; add routine              b21 052
        0 -> b[w ]                ; zap
        a + 1 -> a[xs]            ; offset exp
        a + 1 -> a[xs]            ; can handle +-200 exp
        c + 1 -> c[xs]
        c + 1 -> c[xs]
        if a >= c[x ]             ; compare exps
          then go to add4
        a exchange c[w ]          ; smaller in c
add4:   a exchange c[m ]          ; smaller in am
        if 0 = c[m ]              ; look for zero
          then go to add5
        a exchange c[w ]          ; smaller in cm, answer exp c
add5:   b exchange c[m ]          ; smaller in b,extend to 13
add6:   if a >= c[x ]             ; when exps are equal
          then go to $add1
        shift right b[w ]         ; line up smaller number
        a + 1 -> a[x ]            ; up smaller exp
        if 0 = b[w ]              ; fall out of b
          then go to $add1
        go to add6                ; continue                 e
$what:  m1 exchange c             ; check on deg,rad,grd     b10
        c -> a[s ]                ; copy info
        m1 exchange c             ; restore status
        p <- 12
        a - 1 -> a[s ]
        if n/c go to what1
        0 -> a[w ]                ; grads
        a + 1 -> a[p ]            ; a one
        a + 1 -> a[x ]            ; a one
        if n/c go to what4        ; always                   e
e10tox: 1 -> s err    8           ; 10 to x
        select rom 6              ;                              112
exp:    1 -> s err    8           ; e to x key
        select rom 6              ;                              114
$qsto+: c -> a[w ]                ; store plus key
        m2 -> c                   ; get x
        go to $qsto1
sqrt:   select rom 7              ;                              120
atc11:  0 -> c[w ]                ; load pi/4                b14 121
	p <- 11
        load constant 7           ; 11
        load constant 8           ; 10
        load constant 5           ; 9
        load constant 3           ; 8
        load constant 9           ; 7
        load constant 8           ; 6
        load constant 1           ; 5
        load constant 6           ; 4
        load constant 3           ; 3
        load constant 5           ; 2
        p <- 12                   ; reset
        return                    ; that is all              e
frac:   1 -> s f      9           ; fractional part
int:    select rom 4              ; integer part                 140
	nop
	nop
qsto*:  c -> a[w ]                ; store times key
        m2 -> c
        jsb mpy11z
        go to qsto-2
qsto/:  c -> a[w ]                ; store divide key         b6
        m2 -> c
        p <- 12
        1 -> s err    8
        jsb $divid
        go to qsto-2              ;                          e
what1:  a - 1 -> a[s ]            ; keep counting
        if n/c go to what2
        1 -> s rad    13          ; mark as radians
        return
acos:   1 -> s cos    7           ; arc cosine               b12
asin:   1 -> s ntan   14          ; arc sin
atan:   jsb $what                 ; arc tangent
        1 -> s f      9           ; mark as arc
        delayed rom 1
        jsb $size
        p <- 12                   ; reset the pointer
        if 0 = s ntan   14
          then go to $atan        ; arctan
        0 - c - 1 -> c[s ]        ; jack with signs
        a exchange c[s ]
        delayed rom 7
        go to $asin               ;                          e
trig5:  m2 exchange c             ; save zero cosine         b13
        a exchange c[w ]          ; make sin = 1
trig6:  y -> a                    ; copy mag
        jsb mpy11z                ; r sin
        jsb overfz                ; check size
        if 0 = s correc 12
          then go to trig4
        0 - c - 1 -> c[s ]        ; invert sign
trig4:  stack -> a                ; get mag
        c -> stack                ; save r sin
        m2 -> c                   ; get cos
        jsb mpy11z                ; r cos
        go to $retrn              ; end of rect              e
polar2: jsb sqrt                  ; sqrt                     b6
        if 0 = s polar  10        ; was this sqrt
          then go to $retrn       ; yes, so leave
polar3: c -> stack                ; save mag
        m2 exchange c             ; get y/x
        go to atan                ;                          e
rect:   1 -> s polar  10          ; rectangular here         b15
        jsb xexy
cos:    1 -> s cos    7           ; cosine key
sin:    1 -> s ntan   14          ; sine key
tan:    jsb $what                 ; tangent key
        if 1 = s rad    13
          then go to piq          ; rads
        a exchange c[w ]
        jsb $divid
        jsb atc11                 ; get pi/4
        c + c -> c[w ]            ; pi/2
        jsb mpy11z
piq:    delayed rom 1
        jsb $size
        select rom 7              ;                          e   237
what2:  0 -> a[w ]                ; degrees
        a - 1 -> a[p ]
what4:  a + 1 -> a[x ]            ; a two or a one
        return
xexy:   stack -> a
        c -> stack
        a exchange c[w ]
        return
polar:  1 -> s polar  10          ; to polar                 b26
        if 0 = c[s ]              ; check x sign
          then go to polar1
        1 -> s correc 12          ; 2nd,3rd quad correction
polar1: m2 exchange c
        m2 -> c                   ; copy x
        y -> a                    ; copy y off of stack
        if 0 # a[m ]              ; check for both bieng zero
          then go to polar4
        if 0 = c[m ]              ; yes, both are zero
          then go to $retrn
polar4: p <- 12                   ; mark as divide
        jsb $divid                ; y / x
        jsb overfz                ; check size of answer
        m2 exchange c             ; x in c, y/x in m2
        jsb mpy11q                ; square x
        jsb xexy                  ; get y, save x*x
        jsb mpy11q                ; square y
        stack -> a                ; get x*x
        jsb $add3                 ; x*x+y*y
        a - 1 -> a[xs]            ; check for 10 to 200
        a - 1 -> a[xs]
        if 0 # a[xs]
          then go to polar2       ; ok, small enough
        jsb overfz                ; make all 9s
        go to polar3              ; continue                 e
sig++:  a exchange c[w ]          ; sigma plus cont              302
        register -> c 4           ; get sum of y
        jsb $qsto1                ; sum of y
        p <- 12
        0 -> c[w ]
        c + 1 -> c[p ]            ; a one
        if 0 = s g      10        ; if not sigma minus
          then go to sig+3
        0 - c - 1 -> c[s ]        ; make a minus one
sig+3:  a exchange c[w ]
        register -> c 3           ; get count
        jsb $qsto1                ; add to count
        delayed rom 4
        go to $qclx1
h1:     select rom 3              ;                              320
x**2:   jsb mpy11q                ; x squared key
abs:    0 -> c[s ]                ; abs function
        go to $retrn
$pikey: jsb atc11                 ; pi function here
        c + c -> c[w ]
        c + c -> c[w ]
$retrn: m2 exchange c             ; save answer
retur5: delayed rom 4
        go to $qthr
mpy11q: c -> a[w ]                ; copy
mpy11z: select rom 6              ;                              333
$divid: a - c -> c[x ]            ; divide routine starts here
        select rom 6              ;                              335
qsto-:  c -> a[w ]                ; store minus key          b15
        m2 -> c
        0 - c - 1 -> c[s ]
$qsto1: jsb $add3                 ; go and add
qsto-2: jsb overfz                ; check size
        c -> data                 ; save answer
        if p # 12                 ; if no correction
          then go to qsto-3       ; then ok
        0 -> c[w ]                ; zap
        binary
        c - 1 -> c[w ]            ; f u
        load constant 0
        load constant 11          ; f char
        delayed rom 1
        go to $err1               ; hit end of error routine e
$trig3: if 0 = s polar  10        ; cont of trig             b12
          then go to $retrn       ; end of forward trig
        0 -> a[w ]                ; zap
        a + 1 -> a[p ]            ; make a 1   p=12
        if 0 = c[m ]              ; check for zero cosine
          then go to trig5        ; yes
        m2 exchange c             ; save cos;get cotan: more rec
        jsb $divid                ; make tan
        m2 -> c                   ; copy cos
        jsb mpy11z                ; make sin
        jsb overfz                ; check its size
        go to trig6               ;                          e
ytox:   stack -> a                ; get value
        a exchange c[w ]
        1 -> s ytox   11          ; mark as y to x
log:    1 -> s log    6           ; mark as log
ln:     1 -> s err    8           ; mark as ln, log, exp
        0 -> a[w ]
        a - c -> a[m ]
        .rom 6                    ; SQUASH  NSQ9  FEB 27,75
        if n/c go to err          ;                          b54
        shift right a[w ]
        c - 1 -> c[s ]
        if n/c go to err
        p <- 12
ln25:   c + 1 -> c[s ]
ln26:   a -> b[w ]
        jsb eca22
        a - 1 -> a[p ]
        if n/c go to ln25
        a exchange b[wp]
        a + b -> a[s ]
        if n/c go to ln24
        p <- 7
        jsb pqo23                 ; returns 10^5 ln 1.00001
        p <- 8
        jsb pmu22                 ; returns 10^4 ln 1.0001
        p <- 9
        jsb pmu21
        jsb lncd3                 ; returns 10^3 ln 1.001
        p <- 10
        jsb pmu21
        jsb lncd2                 ; returns 10^2 ln 1.01
        p <- 11
        jsb pmu21
        jsb lncd1                 ; returns 10 ln 1.1
        jsb pmu21
        jsb lnc2                  ; returns ln 2
        jsb pmu21
        jsb lnc10                 ; returns ln 10
        a exchange c[w ]
        a - c -> c[w ]
        if 0 = b[xs]
          then go to ln27
        a - c -> c[w ]
ln27:   a exchange b[w ]
ln28:   p - 1 -> p
        shift left a[w ]
        if p # 1
          then go to ln28
        a exchange c[w ]
        if 0 = c[s ]
          then go to ln29
        0 - c - 1 -> c[m ]
ln29:   c + 1 -> c[x ]
        p <- 11
        jsb mpy27
        if 1 = s ytox   11        ; y to x
          then go to xty22        ; y to x
        if 0 = s log    6
          then go to $retrn       ; ln out here
        jsb lnc10                 ; load ln 10
        jsb mpy22
        go to retur2              ;                          e
pqo21:  select rom 7              ;                          b11 066
pmu21:  shift right a[w ]         ;                              067
pmu22:  b exchange c[w ]
        go to pmu24
pmu23:  a + b -> a[w ]
pmu24:  c - 1 -> c[s ]
        if n/c go to pmu23
        a exchange c[w ]
        shift left a[ms]
        a exchange c[w ]
        go to pqo23               ;                          e   100
pre21:  a exchange c[w ]          ;                          b10 101
        a -> b[w ]
        c -> a[m ]
        c + c -> c[xs]
        if n/c go to pre24
        c + 1 -> c[xs]
pre22:  shift right a[w ]
        c + 1 -> c[x ]
        if n/c go to pre22
        go to pre26               ;                          e
10tox:  jsb ln10b                 ;                          b25 113
ytox29: jsb mpy21
exp21:  jsb ln10b                 ;                              115
        jsb pre21
        jsb lnc2
        p <- 11
        jsb pqo21
        jsb lncd1
        p <- 10
        jsb pqo21
        jsb lncd2
        p <- 9
        jsb pqo21
        jsb lncd3
        p <- 8
        jsb pqo21
        jsb pqo21
        jsb pqo21
        p <- 6
        0 -> a[wp]
        p <- 13
        b exchange c[w ]
        a exchange c[w ]
        load constant 6
        go to exp23               ;                          e
lncd1:  p <- 9                    ; load 10 ln 1.1           b14
        load constant 3           ; 9
        load constant 1           ; 8
        load constant 0           ; 7
        load constant 1           ; 6
        load constant 7           ; 5
        load constant 9           ; 4
lnc8:   load constant 8           ; 3 4
        load constant 0           ; 2 3
        load constant 5           ; 1 2
        load constant 5           ; 0 1
        if p = 0
          then go to lncb
        go to nrm27               ;                          e
ln10b:  c -> a[w ]                ;                          b9
lnc10:  0 -> c[w ]
        p <- 12
        load constant 2           ; 12
        load constant 3           ; 11
        load constant 0           ; 10
        load constant 2           ; 9
        load constant 5           ; 8
        go to lnc7                ;                          e
ln24:   a exchange b[s ]          ;                          b5
        a + 1 -> a[s ]
        shift right c[ms]
        shift left a[wp]
        go to ln26                ;                          e
lncd2:  p <- 7                     ; load 10^2 ln 1.01        b12
lnc6:   load constant 3           ; 7 5
        load constant 3           ; 6 4
        load constant 0           ; 5 3
lnc7:   load constant 8           ; 4 2 7
        load constant 5           ; 3 1 6
        load constant 0           ; 2 0 5
        if p = 13
          then go to lncret
lnca:   load constant 9           ; 1   4
lncb:   load constant 3           ; 0   3
lncret: go to nrm27               ;                          e
exp29:  jsb eca22                 ;                          b14
        a + 1 -> a[p ]
exp22:  a -> b[w ]
        c - 1 -> c[s ]
        if n/c go to exp29
        shift right a[wp]
        a exchange c[w ]
        shift left a[ms]
exp23:  a exchange c[w ]
        a - 1 -> a[s ]
        if n/c go to exp22
        a exchange b[w ]
        a + 1 -> a[p ]
        jsb $norm
retur2: select rom 4              ;                              232
pre23:  if 0 = s err    8         ; trig                     b34
          then go to pre24
        a + 1 -> a[x ]
pre29:  if 0 # a[xs]
          then go to pre27
pre24:  a - b -> a[ms]
        if n/c go to pre23
        a + b -> a[ms]
        shift left a[w ]
        c - 1 -> c[x ]
        if n/c go to pre29
pre25:  shift right a[w ]
        0 -> c[wp]
        a exchange c[x ]
pre26:  if 0 = c[s ]
          then go to pre28
        a exchange b[w ]
        a - b -> a[w ]
        0 - c - 1 -> c[w ]
pre28:  shift right a[w ]
pqo23:  b exchange c[w ]
        0 -> c[w ]
        c - 1 -> c[m ]
        if 0 = s err    8         ; trig
          then go to pqo28
        load constant 4
        c + 1 -> c[m ]
        if n/c go to pqo24
pqo27:  load constant 6
pqo28:  if p # 1
          then go to pqo27
        shift right c[w ]
pqo24:  shift right c[w ]
        return                    ;                          e
mpy26:  a + b -> a[w ]            ;                          b27
mpy27:  c - 1 -> c[p ]
        if n/c go to mpy26        ;                              277
mpy28:  shift right a[w ]
        p + 1 -> p
        if p # 13
          then go to mpy27
        c + 1 -> c[x ]
$norm:  0 -> a[s ]                ; normalize here               305
        p <- 12
        0 -> b[w ]
nrm23:  if 0 # a[p ]
          then go to nrm24
        shift left a[w ]
        c - 1 -> c[x ]
        if 0 # a[w ]
          then go to nrm23
        0 -> c[w ]                ; nothing there
nrm24:  a -> b[x ]
        a + b -> a[w ]
        if 0 # a[s ]
          then go to mpy28
        a exchange c[m ]
nrm25:  c -> a[w ]                ;                              324
        0 -> b[w ]
nrm27:  p <- 12
nrm26:  return                    ;                          e
lncd3:  p <- 5                    ; load 10^3 ln 1.001       b2
        go to lnc6                ;                          e
xty22:  m2 -> c                   ; get x in y to x          b2
        go to ytox29              ;                          e
mpy21:  p <- 3                    ; multiply starts here     b20 334
mpy22:  a + c -> c[x ]
div21:  a - c -> c[s ]            ; divide starts here           336
        if n/c go to div22
        0 - c -> c[s ]
div22:  0 -> b[w ]
        a exchange b[m ]
        0 -> a[w ]
        if p # 12
          then go to mpy27
        if 0 # c[m ]
          then go to div23
err:    if 1 = s err    8         ; ln,log,ytox, div
          then go to $err5
        b -> c[wp]
        a - 1 -> a[m ]
        c + 1 -> c[xs]
div23:  b exchange c[wp]
        a exchange c[m ]
        select rom 7              ;                              357
lnc2:   load constant 6           ; 11   load ln 2           b8
        load constant 9           ; 10
        load constant 3           ; 9
        load constant 1           ; 8
        load constant 4           ; 7
        load constant 7           ; 6
        load constant 1           ; 5
        go to lnc8                ;                          e
pre27:  a + 1 -> a[m ]            ;                          b2
        if n/c go to pre25        ; always                   e
eca21:  shift right a[wp]         ;                          b6
eca22:  a - 1 -> a[s ]
        if n/c go to eca21
        0 -> a[s ]
        a + b -> a[w ]
        return                    ;                          e
        .rom 7                    ; SQUASH  NSQ11  JULY 29,75
tan15:  a exchange b[w ]          ;                          b39
        jsb tnm11
        jsb stacka
        jsb tnm11
        jsb stacka
        if 0 = s cos    7
          then go to tan31        ; sin,tan
        a exchange c[w ]          ; cos
tan31:  if 0 = s ntan   14
          then go to asn12        ; tan
        if 0 = c[s ]
          then go to tan32
        1 -> s correc 12
tan32:  0 -> c[s ]                ; sin, cos
        jsb div11
$asin:  jsb cstack
        jsb mpy11
        jsb add10                 ; subtract from 1
        jsb $sqrt
        jsb stacka
asn12:  jsb div11                 ; divide
        if 0 = s f      9
          then go to $trig3       ; forward exits here
$atan:  0 -> a[w ]                ; backwards trig here
        a + 1 -> a[p ]
        a -> b[m ]
        a exchange c[m ]
atn12:  c - 1 -> c[x ]
        shift right b[wp]
        if 0 = c[xs]
          then go to atn12
atn13:  shift right a[wp]
        c + 1 -> c[x ]
        if n/c go to atn13
        shift right a[w ]
        shift right b[w ]
        jsb cstack
atn14:  b exchange c[w ]
        go to atn18               ;                          e
add10:  0 -> a[w ]                ; add one routine          b3
        a + 1 -> a[p ]
add11:  select rom 5              ; add routine here         e   051
polarq: stack -> a                ;                          b4
        c -> stack
        a exchange c[w ]
        go to retur3              ;                          e
tnm11:  jsb cstack                ;                          b8
        a exchange c[w ]
        if 0 = c[p ]
          then go to tnm12
        0 - c -> c[w ]
tnm12:  c -> a[w ]
        b -> c[x ]
        go to add15               ;                          e
pmu11:  select rom 6              ;                          b10 066
pqo11:  shift left a[w ]          ;                              067
pqo12:  shift right b[ms]
        b exchange c[w ]
        go to pqo16
pqo15:  c + 1 -> c[s ]
pqo16:  a - b -> a[w ]
        if n/c go to pqo15
        a + b -> a[w ]
pqo13:  select rom 6              ;                          e   077
pre11:  select rom 6              ;                              100
sqt15:  c + 1 -> c[p ]            ;                          b11
sqt16:  a - c -> a[w ]
        if n/c go to sqt15
        a + c -> a[w ]
        shift left a[w ]
        p - 1 -> p
sqt17:  shift right c[wp]
        if p # 0
          then go to sqt16
        0 -> c[p ]                ; hardware fix
        go to tnm12               ;                          e
stacka: a exchange c[w ]          ; fake stack to a          b4
        m2 -> c
        a exchange c[w ]
        return
atc1:   select rom 5              ;                              120
$sqrt:  c -> a[w ]                ; enter sqrt                   121
        0 -> b[w ]
        b exchange c[w ]
        p <- 4
        go to sqt14               ;                          e
	nop
atn15:  shift right b[wp]         ;                          b70
atn16:  a - 1 -> a[s ]
        if n/c go to atn15
        c + 1 -> c[s ]
        a exchange b[wp]
        a + c -> c[wp]
        a exchange b[w ]
atn18:  a -> b[w ]
        a - c -> a[wp]
        if n/c go to atn16
        jsb stacka
        shift right a[w ]
        a exchange c[wp]
        a exchange b[w ]
        shift left a[wp]
        jsb cstack
        a + 1 -> a[s ]
        a + 1 -> a[s ]
        if n/c go to atn14
        0 -> c[w ]
        0 -> b[x ]
        shift right a[ms]
        jsb div14
        c - 1 -> c[p ]
        jsb stacka
        a exchange c[w ]
        p <- 4
atn17:  jsb pqo13
        p <- 6
        jsb pmu11
        p <- 8
        jsb pmu11
        p <- 2
        load constant 8
        p <- 10
        jsb pmu11
        jsb atcd1
        jsb pmu11
        jsb atc1
        shift left a[w ]
        jsb pmu11
        b -> c[w ]
atn19:  jsb add15                 ; normalize
$ata31: jsb atc1                  ; load pi/4
        c + c -> c[w ]            ; pi/2
        if 1 = s cos    7         ; cos arc
          then go to atan1
        if 0 = s correc 12        ; any polar correction
          then go to atan2        ; nope
        c + c -> c[w ]            ; make a pi
        a exchange c[w ]
        c -> a[s ]                ; pi will have odl sign
atan1:  a exchange c[w ]
        0 - c - 1 -> c[s ]        ; comp answer sign
        jsb add11                 ; add
$atan9: jsb atc1                  ; load pi/4
        c + c -> c[w ]            ; pi/2
atan2:  a exchange c[w ]
        if 1 = s rad    13        ; rad or degrees
          then go to atan34       ; rads
        a exchange c[w ]
        jsb div11                 ; divide by  pi /2
        delayed rom 5
        jsb $what
        jsb mpy11
atan34: if 1 = s polar  10        ; is this to polar
          then go to polarq
retur3: select rom 4              ;                              232
sqt12:  p - 1 -> p                ;                          b4
        a + b -> a[ms]
        if n/c go to sqt18
        delayed rom 1
        go to $error
$piq:   c -> a[w ]                ;                              240
        jsb atc1                  ; load pi/4
        c + c -> c[w ]            ; pi/2
        c + c -> c[w ]            ; pi/
        c + c -> c[w ]
        jsb pre11
        jsb atc1
        p <- 10
        jsb pqo11
        jsb atcd1
        p <- 8
        jsb pqo12
        p <- 2
        load constant 8
        p <- 6
        jsb pqo11
        p <- 4
        jsb pqo11
        jsb pqo11
        a exchange b[w ]
        shift right c[w ]
        p <- 13
        load constant 5
        go to tan14               ;                          e
$add1:  c - 1 -> c[xs]            ;                          b13
        c - 1 -> c[xs]
        0 -> a[x ]
        a - c -> a[s ]
        if 0 # a[s ]
          then go to add13
        select rom 6              ;                              276
add13:  if a >= b[m ]
          then go to add14
        0 - c - 1 -> c[s ]
        a exchange b[w ]
add14:  a - b -> a[w ]
add15:  select rom 6              ;                              304
tan18:  shift right b[wp]         ;                          b21
        shift right b[wp]
tan19:  c - 1 -> c[s ]
        if n/c go to tan18
        a + c -> c[wp]
        a - b -> a[wp]
        b exchange c[wp]
tan13:  b -> c[w ]
        a - 1 -> a[s ]
        if n/c go to tan19
        a exchange c[wp]
        jsb stacka
        if 0 = b[s ]
          then go to tan15
        shift left a[w ]
tan14:  a exchange c[wp]
        jsb cstack
        shift right b[wp]
        c - 1 -> c[s ]
        b exchange c[s ]
        go to tan13               ;                          e
mpy11:  select rom 5              ;                              332
div11:  select rom 5              ;                              333
sqt18:  a + b -> a[x ]            ;                          b16
        if n/c go to sqt14
        c - 1 -> c[p ]
sqt14:  c + 1 -> c[s ]
        if p # 0
          then go to sqt12
        a exchange c[x ]
        0 -> a[x ]
        if 0 # c[p ]
          then go to sqt13
        shift right a[w ]
sqt13:  shift right c[w ]
        b exchange c[x ]
        0 -> c[x ]
        p <- 12
        go to sqt17               ;                          e
cstack: m2 exchange c             ;                          b3
        m2 -> c
        return                    ;                          e
div14:  c + 1 -> c[p ]            ;                          b9
div15:  a - b -> a[ms]            ;                              360
        if n/c go to div14
        a + b -> a[ms]            ; correct back
        shift left a[ms]
div16:  p - 1 -> p                ; next digit
        if p # 0
          then go to div15
        go to tnm12               ;                          e
atcd1:  p <- 6                     ;                          b8
        load constant 8           ; 6
        load constant 6           ; 5
        load constant 5           ; 4
        load constant 2           ; 3
        load constant 4           ; 2
        load constant 9           ; 1
        return                    ;                          e

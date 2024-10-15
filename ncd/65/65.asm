; 65 firmware
; Copyright 2022 Eric Smith <spacewar@gmail.com>
; SPDX-License-Identifier: GPL-3.0-only

; Based in part on US patent 4,099,246, and in part
; on the work of Jacques Laporte.

	.arch classic

dummy_0:  jsb pwo0
sto4_0:   go to sto4s
          no operation
          no operation
r00004:   go to dec7_0
sto6_0:   go to sto6s
tnx1:     jsb tnx2
sto23:    a - 1 -> a[p]
          a - 1 -> a[p]
          if no carry go to sto13
          go to min20
          no operation
rcl18:    a - 1 -> a[p]
          if no carry go to rcl19
          jsb rcl6_0
rcl8_0:   go to rcl8s
rcl7_0:   go to rcl7s
sto31:    c - 1 -> c[p]
          if no carry go to sto32
          jsb clrst
          go to sto30
rcl6_0:   go to rcl6s
r00026:   go to nosfx2
rcl4_0:   go to rcl4s
lstx2:    data -> c
          go to frtn11
rcl8s:    a + 1 -> a[x]
rcl7s:    a + 1 -> a[x]
rcl6s:    a + 1 -> a[x]
rcl5_0:   a + 1 -> a[x]
rcl4s:    a + 1 -> a[x]
rcl3_0:   a + 1 -> a[x]
rcl2_0:   a + 1 -> a[x]
rcl1_0:   a + 1 -> a[x]
          if s3 # 1
               then go to rcl23
          go to min20
sto7_0:   go to sto7s
ufcn10_0: if s8 # 1
               then go to ufcn11
          go to wait40_0
          no operation
sto8s:    a + 1 -> a[x]
sto7s:    a + 1 -> a[x]
sto6s:    a + 1 -> a[x]
sto5_0:   a + 1 -> a[x]
sto4s:    a + 1 -> a[x]
sto3_0:   a + 1 -> a[x]
sto2_0:   a + 1 -> a[x]
sto1_0:   a + 1 -> a[x]
          if s3 # 1
               then go to sto22
          go to min20
sto8_0:   go to sto8s
rcl25:    a - 1 -> a[p]
          a - 1 -> a[p]
          if no carry go to rcl12
          go to min20
sto18:    a - 1 -> a[p]
          if no carry go to sto19
          jsb sto6_0
lstx0:    0 -> c[m]
          c exchange m
          0 -> s11
          0 -> f1
          if s11 # 1
               then go to lstx1
          c -> stack
lstx1:    0 -> c[w]
          c -> data address
          go to lstx2
rcl14:    a - 1 -> a[p]
          if no carry go to rcl15
          jsb rcl2_0
rcl15:    a - 1 -> a[p]
          if no carry go to rcl16
          jsb rcl3_0
r00115:   go to tnx1
sdgt2:    5 -> p
          if c[p] = 0
               then go to sdgt3
          c - 1 -> c[p]
          if c[p] = 0
               then go to sto11
          c - 1 -> c[p]
          2 -> p
          jsb adrs3
          go to sto10
adrs4:    0 -> b[w]
adrs1:    shift left a[w]
          p + 1 -> p
          if p # 12
               then go to adrs1
          a exchange c[w]
          c -> data address
          a exchange c[w]
          return
rcl17:    a - 1 -> a[p]
          if no carry go to rcl18
          jsb rcl5_0
sdgt4:    select rom 4   ; -> r04145
sto15:    a - 1 -> a[p]
          if no carry go to sto16
          jsb sto3_0
rcl19:    a - 1 -> a[p]
          if no carry go to rcl20
          jsb rcl7_0
sto11:    jsb clrm
          if s3 # 1
               then go to sto12
          a + 1 -> a[p]
          if no carry go to sto23
          go to min20
sto14:    a - 1 -> a[p]
          if no carry go to sto15
          jsb sto2_0
adrs3:    1 -> s4
adrs0:    if a[xs] >= 1
               then go to adrs4
          if s4 # 1
               then go to nosfx1
nosfx2:   jsb clrm
nosfx3:   0 -> f7
nosfx1:   select rom 2   ; -> r02174
rcl12:    jsb mdl0
          a - 1 -> a[p]
          if no carry go to rcl14
          jsb rcl1_0
sto32:    c - 1 -> c[p]
          if no carry go to sto36_0
          jsb clrst
          jsb mpy20_0
r00204:   go to sqx1
rcl20:    jsb rcl8_0
sdgt3:    if s3 # 1
               then go to sdgt4
          select rom 5   ; -> r05211
fact0_0:  select rom 3   ; -> r03212
clrm:     0 -> c[m]
          c exchange m
          2 -> p
          return
ufcn11:   1 -> s10
wait40_0: select rom 1   ; -> wait10
mdl0:     1 -> f7
          memory delete
          0 -> s11
mdl1:     0 -> f5
          if s11 # 1
               then go to mdl1
          0 -> f5
          return
sdgt1:    4 -> p
          if c[p] = 0
               then go to sdgt2
rcl10:    jsb clrm
          if s3 # 1
               then go to rcl11
          a + 1 -> a[p]
          if no carry go to rcl25
          go to min20
sto20:    jsb sto8_0
          go to frtn11
sqx1:     c -> a[w]
mpy20_0:  select rom 6   ; -> mpy11
dvd20_0:  select rom 6   ; -> div11
dec7_0:   12 -> p
          if c[p] = 0
               then go to nosfx2
          load constant 2
          c exchange m
          go to wait40_0
frac2:    shift left a[m]
          a - 1 -> a[x]
          p + 1 -> p
frac1_0:  if p # 12
               then go to frac2
          a exchange c[w]
          c -> a[w]
          0 -> a[x]
          delayed select group 1
          go to j10145
clrst:    0 -> c[m]
          c exchange m
          12 -> p
clrst1:   c -> a[w]
          data -> c
          a exchange c[w]
          c -> data
          return
sto19:    a - 1 -> a[p]
          if no carry go to sto20
          jsb sto7_0
pwo0:     delayed select group 1
          select rom 2   ; -> r12303
          no operation
          no operation
gdgt2_0:  a - 1 -> a[xs]
          if no carry go to gdgt3_0
          go to fact0_0
gdgt3_0:  select rom 5   ; -> r05311
r00311:   go to frac1_0
r00312:   go to nosfx2
sto13:    jsb mdl0
          a - 1 -> a[p]
          if no carry go to sto14
          jsb sto1_0
sto36_0:  jsb clrst
          jsb dvd20_0
sto22:    jsb clrm
          0 -> p
sto12:    jsb adrs0
          c -> data
frtn11:   select rom 2   ; -> frtn1
frtn10_0: select rom 2   ; -> frtn2
rcl23:    jsb clrm
          0 -> p
rcl11:    jsb adrs0
          0 -> s11
          0 -> f1
          if s11 # 1
               then go to rcl22
          c -> stack
rcl22:    data -> c
          go to frtn11
min20:    select rom 4   ; -> fcn13
r00342:   jsb clrst1
          a exchange c[w]
          go to wait40_0
          no operation
          no operation
          no operation
sto16:    a - 1 -> a[p]
          if no carry go to sto17
          jsb sto4_0
          go to nosfx2
sto17:    a - 1 -> a[p]
          if no carry go to sto18
          jsb sto5_0
          no operation
          no operation
r00361:   buffer -> rom address
          go to dummy_0
tnx2:     1 -> s2
          c -> a[w]
          select rom 7   ; -> lnc10
          no operation
sto10:    5 -> p
          c - 1 -> c[p]
          if no carry go to sto31
          jsb clrst
          0 - c - 1 -> c[s]
sto30:    select rom 5   ; -> sto33
rcl16:    a - 1 -> a[p]
          if no carry go to rcl17
          jsb rcl4_0
dec6:     6 -> p
          if c[p] >= 1
               then go to dec8
          select rom 0   ; -> r00004
dsz6:     select rom 4   ; -> r04005
fdgt8_1:  a + 1 -> a[xs]
          if no carry go to doct0_1
          delayed select group 1
          select rom 1   ; -> r11011
dsz5:     if a[m] >= 1
               then go to dsz10
          go to dsz7
entr2_1:  if c[m] = 0
               then go to entr1_1
          delayed select group 1
          select rom 2   ; -> r12020
          no operation
r01021:   jsb wait3
          go to wait40_1
dsz3:     if c[m] = 0
               then go to dsz4
          shift right c[m]
          c - 1 -> c[x]
dsz2:     if c[x] >= 1
               then go to dsz3
dsz4:     if c[s] >= 1
               then go to dsz13
          a - c -> a[m]
          if no carry go to dsz5
          0 - c - 1 -> c[s]
dsz8:     c -> data
          b exchange c[w]
          jsb dsz12
wait30:   0 -> s11
          0 -> f0
          if s11 # 1
               then go to wait10
          delayed select group 1
          select rom 1   ; -> r11047
          no operation
r01050:   go to entr2_1
wait11:   c + 1 -> c[xs]
wait4:    0 -> s10
          if s5 # 1
               then go to wait13
          c + 1 -> c[x]
          if no carry go to wait11
          go to wait17
ptr5:     1 -> s6
          a exchange c[w]
          select rom 3   ; -> r03063
fix5:     p - 1 -> p
          c + 1 -> c[x]
          jsb fix7
dec8:     select rom 5   ; -> r05067
          no operation
fix3:     0 -> c[xs]
fix4:     13 -> p
          c - 1 -> c[x]
fix7:     if b[p] = 0
               then go to fix5
          12 -> p
fix6:     if a[p] >= 1
               then go to fix2
          shift left a[m]
          c - 1 -> c[x]
          jsb fix6
rtp3_1:   if s4 # 1
               then go to rtp4
          c + c -> c[w]
          a + c -> c[s]
          if a[m] >= 1
               then go to rtp5_1
          0 - c - 1 -> c[s]
          jsb rtp5_1
dsz10:    if a[p] >= 1
               then go to dsz7
          shift left a[m]
          a - 1 -> a[x]
dsz7:     a exchange c[w]
          jsb dsz8
dsz11:    a + 1 -> a[p]
          a + 1 -> a[x]
          jsb dsz7
dec5:     7 -> p
          if c[p] = 0
               then go to dec6
          select rom 5   ; -> r05130
r01130:   go to wait29
wait16:   0 -> s3
          1 -> f2
          1 -> p
          c exchange m
          0 -> s11
          0 -> f3
          if s3 # 1
               then go to wait2
          if s11 # 1
               then go to wait33
wait36:   c exchange m
          delayed select group 1
          select rom 3   ; -> r13146
fix1:     c + 1 -> c[xs]
          if no carry go to fix3
          0 - c -> c[x]
          jsb fix4
wait2:    if s11 # 1
               then go to wait35
          if c[p] = 0
               then go to dsci50
          c - 1 -> c[p]
          if c[p] = 0
               then go to dsci50
wait39:   load constant 2
          delayed select group 1
          select rom 0   ; -> r10164
entr1_1:  delayed select rom 2
          go to entr1_2
rtp4:     select rom 3   ; -> r03167
fix0:     a exchange c[w]
          c -> a[w]
          if a[m] >= 1
               then go to fix1
          0 -> a[m]
fix2:     a exchange c[m]
frtn5:    select rom 2   ; -> bnds0
r01176:   jsb wait3
          if s3 # 1
               then go to wait32
          select rom 4   ; -> r04202
fidgt8_1: a + 1 -> a[xs]
          if no carry go to odec0_1
ptr0:     stack -> a
          1 -> s1
          1 -> s4
          1 -> s5
          go to ptr5
wait44:   0 -> c[m]
          jsb wait39
          no operation
          no operation
doct0_1:  select rom 3   ; -> r03216
dsci50:   delayed select group 1
          select rom 0   ; -> r10220
wait10:   if s8 # 1
               then go to wait16
wait1:    12 -> p
          if s0 # 1
               then go to wait4
wait31:   p + 1 -> p
          if p # 12
               then go to wait31
          0 -> s0
          if s10 # 1
               then go to wait28
          go to wait1
dsz12:    c exchange m
          if b[m] = 0
               then go to dsz6
dsz9:     select rom 2   ; -> clr24
dec7_1:   select rom 0   ; -> sto20
wait28:   if s5 # 1
               then go to wait6
          go to wait29
mpy20_1:  select rom 6   ; -> mpy11
dvd20_1:  select rom 6   ; -> div11
          no operation
r01247:   go to dvd20_1
dsz0:     b exchange c[w]
          0 -> c[w]
          12 -> p
          c - 1 -> c[p]
          c - 1 -> c[p]
          c -> data address
          0 -> b[m]
          data -> c
dsz1:     c -> a[w]
          0 -> c[m]
          c + 1 -> c[p]
          jsb dsz2
dsz13:    a + c -> a[m]
          if no carry go to dsz7
          go to dsz11
rtp5_1:   0 -> s1
          select rom 3   ; -> rtp5_3
r01271:   3 -> p
          if c[p] >= 1
               then go to dsz0
          go to dec5
wait3:    12 -> p
          1 -> f3
          display off
          c exchange m
          shift left a[w]
          return
wait41:   c exchange m
          go to wait42
odec0_1:  select rom 3   ; -> r03306
wait42:   delayed select group 1
          go to j11312
wait8:    jsb wait3
          1 -> f7
          if s3 # 1
               then go to wait7
          select rom 4   ; -> r04315
wait7:    select rom 2   ; -> r02316
r01316:   go to rtp3_1
wait45:   0 -> c[m]
          jsb dsci50
wait33:   if c[p] >= 1
               then go to wait34
          load constant 1
wait43:   0 -> c[m]
          jsb wait36
wait9:    if s9 # 1
               then go to wait1
r01330:   0 -> s9
wait23:   1 -> s10
wait17:   display toggle
          go to wait1
wait6:    if s8 # 1
               then go to wait8
          go to wait41
wait29:   1 -> f3
          clear status
wait25:   go to wait10
wait34:   c - 1 -> c[p]
          c - 1 -> c[p]
          if c[p] >= 1
               then go to wait37
          load constant 3
          go to wait43
wait13:   if s8 # 1
               then go to wait30
r01352:   pointer advance
          display toggle
          c exchange m
          shift left a[w]
wait40_1: 0 -> s11
wait27:   0 -> f5
          if s11 # 1
               then go to wait27
          0 -> f5
wait32:   select rom 2   ; -> r02364
wait35:   if c[p] = 0
               then go to wait38
          c - 1 -> c[p]
          if c[p] = 0
               then go to wait45
          c - 1 -> c[p]
          if c[p] >= 1
               then go to wait44
wait37:   c + 1 -> c[p]
          c + 1 -> c[p]
wait38:   c exchange m
          go to wait9
noop_2:   go to noop1
sto4_2:   go to fcn60
dig3_2:   select rom 5   ; -> dig3_5
dig2_2:   select rom 5   ; -> dig2_5
dig1_2:   select rom 5   ; -> r05005
sto6_2:   go to fcn60
mpy_2:    go to arth2
xney_2:   select rom 5   ; -> xney_5
g_2:      go to fcn50
rup_2:    go to rup1
rcl_2:    go to fcn50
sto_2:    go to fcn50
fi_2:     go to fcn50
rdn_2:    go to rdn1
f_2:      go to fcn50
rcl8_2:   go to fcn60
rcl7_2:   go to fcn60
excg_2:   go to excg0
dig6_2:   select rom 5   ; -> dig6_5
dig5_2:   select rom 5   ; -> dig5_5
dig4_2:   select rom 5   ; -> r05025
rcl6_2:   go to fcn60
pls_2:    go to arth1
rcl4_2:   go to fcn60
e_2:      go to fcn40
xeqy_2:   select rom 5   ; -> xeqy_5
d_2:      go to fcn40
c_2:      go to fcn40
b_2:      go to fcn40
rcl5_2:   go to fcn60
a_2:      go to fcn40
rcl3_2:   go to fcn60
rcl2_2:   go to fcn60
rcl1_2:   go to fcn60
data_2:   go to data0
dec_2:    go to dec0
dig0_2:   select rom 5   ; -> r05045
sto7_2:   go to fcn60
dvd_2:    go to arth3
entr2_2:  select rom 1   ; -> r01050
sst_2:    go to fcn50
xgty_2:   select rom 5   ; -> xgty_5
rtn_2:    go to fcn50
lbl_2:    go to fcn50
gto_2:    go to fcn50
sto5_2:   go to fcn60
dsp_2:    go to fcn50
sto3_2:   go to fcn60
sto2_2:   go to fcn60
sto1_2:   go to fcn60
dig9_2:   select rom 5   ; -> dig9_5
dig8_2:   select rom 5   ; -> dig8_5
dig7_2:   select rom 5   ; -> r05065
sto8_2:   go to fcn60
mns_2:    go to arth0
xley_2:   select rom 5   ; -> xley_5
clx_2:    go to clr10
          no operation
eex_2:    go to eex0
chs_2:    go to chs0
lstx_2:   select rom 0   ; -> lstx0
          no operation
entr_2:   go to entr2_2
mrk_2:    c exchange m
          go to bnds3
data0:    0 -> c[m]
          delayed select group 1   ; -> r12104
entr1_2:  c exchange m
          c -> stack
          go to clr23_2
r02106:   go to data6
den7:     shift right b[wp]
          jsb den5
r02111:   go to sdgt9
den13:    if s1 # 1
               then go to den12
          if s7 # 1
               then go to den9
          a exchange c[x]
          shift right a[w]
          1 -> p
          c -> a[wp]
          go to den17
clsts1:   clear status
          return
          no operation
          no operation
den16:    shift right b[w]
den9:     b exchange c[w]
          c + 1 -> c[w]
          0 -> p
den3:     if c[p] >= 1
               then go to den2
          p + 1 -> p
          shift left a[wp]
          go to den3
chs1:     c exchange m
          shift right a[w]
          if s7 # 1
               then go to chs2
          a exchange c[x]
          0 - c - 1 -> c[xs]
          a exchange c[x]
          go to den17
arth4_2:  select rom 5   ; -> r05151
den2:     c - 1 -> c[w]
          b exchange c[w]
          if p # 3
               then go to den4
          0 -> a[wp]
den5:     shift right a[ms]
den17:    c -> a[s]
den15:    if s7 # 1
               then go to den14
          0 -> b[x]
den14:    1 -> s9
          0 -> f3
          1 -> f1
          select rom 1   ; -> fix0
clsts0:   if s8 # 1
               then go to clsts1
          clear status
          1 -> s8
          return
r02174:   jsb clsts0
          select rom 1   ; -> r01176
bnds0:    if c[xs] = 0
               then go to bnds5
          c + 1 -> c[xs]
          if c[xs] = 0
               then go to bnds2
          c + 1 -> c[xs]
          if c[xs] = 0
               then go to uflw
oflw:     0 -> c[m]
          0 -> c[x]
          c - 1 -> c[m]
          c - 1 -> c[x]
          shift right c[x]
bnds4:    clear status
          go to bnds6
rdn1:     c exchange m
          go to roll1
bnds3:    select rom 1   ; -> wait10
sdgt9:    jsb clsts0
          3 -> p
          select rom 5   ; -> sdgt0
data2:    clear status
          1 -> s8
          1 -> s10
          go to bnds3
chs2:     0 - c - 1 -> c[s]
          c -> a[s]
          0 -> f3
          1 -> s9
          go to bnds0
clr10:    0 -> c[m]
clr11:    c exchange m
          0 -> c[w]
clr23_2:  0 -> f1
clr24:    jsb clsts0
          go to bnds5
noop1:    0 -> c[m]
          c exchange m
          go to clr24
den12:    0 -> s11
          0 -> f1
          if s11 # 1
               then go to rset2
          c -> stack
rset2:    0 -> c[w]
          12 -> p
          c - 1 -> c[wp]
          c + 1 -> c[s]
          c + 1 -> c[s]
          b exchange c[w]
          0 -> c[w]
          if s2 # 1
               then go to den16
          go to den9
data1:    if s9 # 1
               then go to data2
bnds6:    1 -> f3
          go to clr24
dec2:     select rom 1   ; -> r01271
dec0:     if c[m] >= 1
               then go to dec2
dec1:     1 -> s2
          if s1 # 1
               then go to dig0_2
          go to eex1
eex0:     if c[m] >= 1
               then go to entr2_2
eex2:     1 -> s7
          if s1 # 1
               then go to dig1_2
eex1:     c exchange m
          shift right a[w]
          jsb den17
arth3:    a + 1 -> a[x]
arth2:    a + 1 -> a[x]
arth1:    a + 1 -> a[x]
arth0:    jsb clsts0
          if c[m] = 0
               then go to arth4_2
          select rom 4   ; -> r04316
r02316:   keys -> rom address
          no operation
err3_2:   1 -> f3
          go to bnds0
excg0:    c exchange m
          stack -> a
          c -> stack
          a exchange c[w]
frtn1:    1 -> f1
frtn2:    jsb clsts0
r02330:   go to bnds0
bnds2:    if c[x] = 0
               then go to uflw
          c - 1 -> c[xs]
bnds5:    if c[m] >= 1
               then go to bnds7
          0 -> c[w]
bnds7:    if p # 14
               then go to bnds3
          select rom 0   ; -> r00342
rup1:     c exchange m
          down rotate
          down rotate
roll1:    down rotate
          go to frtn1
fcn50:    select rom 4   ; -> lbr1
r02350:   go to frtn2
fcn40:    select rom 4   ; -> ufcn0
uflw:     0 -> c[w]
          jsb bnds4
data6:    if s1 # 1
               then go to bnds4
          0 -> f1
          go to bnds4
fcn60:    select rom 0   ; -> r00361
den6:     shift left a[w]
          1 -> s1
          go to den5
r02364:   buffer -> rom address
          go to noop_2
den4:     if s1 # 1
               then go to den6
          if s2 # 1
               then go to den7
          p - 1 -> p
          0 -> b[p]
          jsb den5
chs0:     if c[m] = 0
               then go to chs1
          go to entr2_2
fmod3:    c - 1 -> c[x]
          c - 1 -> c[x]
          c -> a[w]
          jsb fmod4
fdgt8_3:  select rom 1   ; -> fdgt8_1
r03005:   go to dmst2
          no operation
          no operation
tanx_3:   select rom 6   ; -> tanx_6
pi21:     0 -> s10
pi20:     12 -> p
          0 -> c[w]
          load constant 1
          load constant 5
          load constant 7
          load constant 0
          load constant 7
          load constant 9
          load constant 6
          load constant 3
          load constant 2
          load constant 7
          12 -> p
          return
ret:      select rom 6   ; -> asn1z0
r03031:   if s4 # 1
               then go to ret
          delayed select group 1
          select rom 1   ; -> r11035
fmod1:    a - 1 -> a[p]
          if no carry go to fmod3
          c - 1 -> c[x]
          jsb ld90
          jsb dvd30
fmod4:    jsb pi20
          jsb mpy30
          go to fmod2
tdms3:    c - 1 -> c[x]
          jsb ld91
          jsb mpy30
          go to tdms2
doct0_3:  jsb int6
          delayed select group 1
          select rom 2   ; -> r12054
sqt2:     select rom 6   ; -> sqt11
fidgt7:   a + 1 -> a[xs]
          if no carry go to fidgt8_3
          go to dmsm0
r03060:   c -> a[w]
          if s1 # 1
               then go to sqt2
r03063:   jsb adr9
          if s7 # 1
               then go to fmod0
          go to mag0
          no operation
sin12_3:  c -> a[w]
          select rom 6   ; -> sin12_6
r03072:   jsb adr9
          go to mag0
dmst2:    1 -> s10
          12 -> p
          jsb dvd30
          if s6 # 1
               then go to dmst5
          0 -> s6
          stack -> a
          c -> stack
          a exchange c[w]
          1 -> s4
          go to dmst0
dmst6:    jsb mod10
          a - 1 -> a[p]
          if no carry go to dmst3
          c - 1 -> c[x]
          jsb ld91
          jsb dvd30
          jsb pi21
          go to mpy30
rtp9:     jsb rtp13
          jsb mpy30
          data -> c
          jsb add10_3
          delayed select group 1
          select rom 1   ; -> r11125
          no operation
tdms1:    a - 1 -> a[p]
          if no carry go to tdms3
tdms2:    delayed select group 1
          select rom 1   ; -> r11132
int0:     jsb int6
          go to frtn14
dmst4:    c + 1 -> c[x]
          jsb ld90
          0 -> s10
          go to dvd30
fmod0:    jsb mod10
          a - 1 -> a[p]
          if no carry go to fmod1
          go to fmod2
          no operation
mag4:     0 -> c[w]
          c + 1 -> c[p]
          if s7 # 1
               then go to tanx_3
          select rom 6   ; -> tan12
dmsm0:    0 - c - 1 -> c[s]
dmsp0:    1 -> s6
dmst0:    delayed select group 1
          select rom 1   ; -> r11156
fidgt6_3: 0 -> s7
          a + 1 -> a[xs]
          if no carry go to fidgt7
          go to dmst0
odec0_3:  jsb int6
          delayed select group 1
          select rom 2   ; -> r12165
lpi11_3:  select rom 6   ; -> lpi11_6
r03166:   if s6 # 1
r03167:        then go to rmod0
          go to rtp3_3
int4:     c - 1 -> c[x]
int2:     p - 1 -> p
          if c[x] >= 1
               then go to int3
int5:     0 -> c[wp]
          a exchange c[x]
          c -> a[x]
          go to int7
fidgt8_3: select rom 1   ; -> fidgt8_1
int6:     12 -> p
          c -> a[w]
          if c[xs] = 0
               then go to int2
          0 -> c[w]
int7:     return
sub10:    0 - c - 1 -> c[s]
add10_3:  select rom 5   ; -> r05212
r03212:   go to fact0_3
fdgt7:    a + 1 -> a[xs]
          if no carry go to fdgt8_3
          go to dmsp0
r03216:   go to doct0_3
wait50:   select rom 1   ; -> wait10
rmod3:    c + 1 -> c[x]
          c + 1 -> c[x]
          c -> a[w]
          jsb rmod5
int3:     if p # 2
               then go to int4
          go to int5
ptr3:     delayed select group 1
          select rom 1   ; -> r11231
fdgt6_3:  a + 1 -> a[xs]
          if no carry go to fdgt7
tdms0:    jsb mod10
          a - 1 -> a[p]
          if no carry go to tdms1
          c + 1 -> c[x]
          jsb ld91
          jsb mpy30
          jsb pi20
          jsb dvd30
          go to tdms2
mpy30:    select rom 6   ; -> mpy11
dvd30:    select rom 6   ; -> div11
mod11:    a exchange c[w]
mod10:    c exchange m
          c -> a[x]
          c exchange m
          0 -> p
          0 -> s1
          1 -> s10
          return
dmst5:    if s4 # 1
               then go to dmst6
          0 -> s4
          1 -> s10
          stack -> a
          12 -> p
          jsb add10_3
          go to tdms2
fact0_3:  jsb int6
          delayed select group 1
          select rom 0   ; -> r10271
rtp5_3:   jsb sub10
rmod0:    jsb mod11
          a - 1 -> a[p]
          if no carry go to rmod2
rmod6:    if s6 # 1
               then go to frtn14
          delayed select group 1
          select rom 1   ; -> r11301
ptr2:     jsb dvd30
          stack -> a
          c -> stack
          jsb mpy30
          go to ptr3
r03306:   go to odec0_3
frac0:    jsb int6
          select rom 0   ; -> r00311
nosfx4:   select rom 0   ; -> r00312
r03312:   jsb mpy30
          delayed select group 1
          select rom 1   ; -> r11315
rtp3_3:   select rom 1   ; -> r01316
ld91:     1 -> s10
ld90:     c -> a[w]
          12 -> p
          0 -> c[w]
          c - 1 -> c[p]
          return
r03324:   go to rtp9
frtn14:   select rom 2   ; -> frtn1
frtn13:   select rom 2   ; -> frtn2
dmst3:    a - 1 -> a[p]
          if no carry go to dmst4
          go to frtn14
exit:     select rom 5   ; -> r05333
r03333:   if s10 # 1
               then go to exit
          return
fmod2:    c -> a[w]
          0 -> b[w]
          12 -> p
          0 -> s10
          1 -> s1
mag0:     c + 1 -> c[xs]
          if no carry go to mag3
          if c[x] = 0
               then go to mag3
          0 -> c[w]
          0 -> p
          load constant 5
          12 -> p
          a + c -> c[x]
          if no carry go to mag4
mag3:     if s7 # 1
               then go to lpi11_3
          a exchange c[w]
          go to sin12_3
rtp13:    c -> a[w]
adr9:     b exchange c[w]
          c - 1 -> c[p]
          c -> data address
          b exchange c[w]
          0 -> b[w]
          return
rmod2:    a - 1 -> a[p]
          if no carry go to rmod3
          c + 1 -> c[x]
          jsb ld90
          jsb mpy30
rmod5:    jsb pi20
          jsb dvd30
          go to rmod6
noop_4:   go to fcn19
          no operation
dig3_4:   select rom 5   ; -> dig3_5
dig2_4:   select rom 5   ; -> dig2_5
dig1_4:   select rom 5   ; -> r05005
r04005:   go to pad0
mpy_4:    go to fcn19
xney_4:   go to fcn19
g_4:      go to p3
rup_4:    go to fcn19
rcl_4:    go to p4
sto_4:    go to p5
fi_4:     go to p6
rdn_4:    go to fcn19
f_4:      go to p7
fcn21:    1 -> f5
fcn2:     select rom 1   ; -> r01021
excg_4:   go to fcn19
dig6_4:   select rom 5   ; -> dig6_5
dig5_4:   select rom 5   ; -> dig5_5
dig4_4:   select rom 5   ; -> r05025
          no operation
pls_4:    go to fcn19
r04027:   go to ufcn9
e_4:      go to fcn19
xeqy_4:   go to fcn19
d_4:      go to fcn19
c_4:      go to fcn19
b_4:      go to fcn19
          no operation
a_4:      go to fcn19
fcn27:    if p # 14
               then go to fcn28
          jsb lstx_4
data_4:   go to fcn19
dec_4:    go to fcn19
dig0_4:   select rom 5   ; -> r05045
ufcn10_4: select rom 0   ; -> ufcn10_0
dvd_4:    go to fcn19
rsetp:    return
sst_4:    go to p8
xgty_4:   go to fcn19
rtn_4:    go to p9
lbl_4:    go to p10
gto_4:    go to p11
          no operation
dsp_4:    go to fcn0
          go to fcn8
arth4_4:  delayed select group 1
          select rom 0   ; -> r10062
dig9_4:   select rom 5   ; -> dig9_5
dig8_4:   select rom 5   ; -> dig8_5
dig7_4:   select rom 5   ; -> r05065
          no operation
mns_4:    go to fcn19
xley_4:   go to fcn19
clx_4:    if c[m] >= 1
               then go to clr20
eex_4:    go to fcn19
chs_4:    go to fcn19
lstx_4:   go to fcn19
fcn25:    jsb rup_4
entr_4:   go to fcn19
fcn11:    if p # 12
               then go to fcn23
          jsb xney_4
ufcn4:    if s9 # 1
               then go to ufcn5
          mark and search
          c + 1 -> c[s]
ufcn7:    c + 1 -> c[s]
          clear status
          1 -> s10
          jsb ufcn6
fcn23:    if p # 13
               then go to fcn27
          a - 1 -> a[xs]
          if no carry go to fcn24
          jsb excg_4
          no operation
fcn7:     c + 1 -> c[p]
          if s8 # 1
               then go to fcn8
fcn26:    c exchange m
          clear status
          1 -> s8
          go to rtn7
mcirc0:   0 -> s11
mcirc1:   0 -> f5
          if s11 # 1
               then go to mcirc1
          0 -> f5
          return
clr20:    3 -> p
          if c[p] = 0
               then go to clr23_4
          memory delete
          jsb mcirc0
clr21:    memory delete
          jsb arstr2
          go to fcn20
r04145:   11 -> p
          if c[p] >= 1
               then go to ufcn3
          10 -> p
          if c[p] >= 1
               then go to ufcn8
          select rom 5   ; -> r05154
r04154:   go to pad2
p3:       p - 1 -> p
p4:       p - 1 -> p
p5:       p - 1 -> p
p6:       p - 1 -> p
p7:       p - 1 -> p
          0 -> c[m]
p8:       p - 1 -> p
p9:       p - 1 -> p
p10:      p - 1 -> p
p11:      p - 1 -> p
fcn0:     if p # 8
               then go to fcn1
          jsb arstr1
          1 -> s9
          pointer advance
          if s3 # 1
               then go to fcn2
          go to fcn20
fcn9:     if p # 10
               then go to fcn10
          jsb xeqy_4
r04202:   go to lbr1
fcn19:    jsb arstr2
fcn22:    if s3 # 1
               then go to fcn21
          go to fcn13
          no operation
rtn2:     mark and search
          clear status
          1 -> s8
          c + 1 -> c[s]
          0 -> c[m]
          c exchange m
          jsb mcirc0
rtn7:     select rom 1   ; -> wait10
fcn4:     if p # 9
               then go to fcn7
          if s3 # 1
               then go to rtn0
          go to fcn8
fcn24:    a - 1 -> a[xs]
          if no carry go to fcn25
          jsb rdn_4
clr23_4:  delayed select group 1
          select rom 2   ; -> r12232
pad1:     1 -> f1
pad0:     pointer advance
          jsb mcirc0
pad3:     pointer advance
          jsb mcirc0
pad2:     select rom 2   ; -> clr24
rtn0:     if s8 # 1
               then go to rtn1
          if c[s] = 0
               then go to rtn2
          c - 1 -> c[s]
          if c[s] = 0
               then go to rtn3
          go to rtn6
rtn5:     search for label
          jsb mcirc0
          1 -> f7
          jsb rsetp
rtn6:     search for label
          jsb mcirc0
          go to rtn3
ufcn3:    search for label
ufcn9:    jsb mcirc0
          go to ufcn8
fcn3:     if s3 # 1
               then go to fcn15
          memory delete
          jsb mcirc0
fcn15:    1 -> f7
          if p # 9
               then go to fcn9
          jsb xgty_4
fcn10:    if p # 11
               then go to fcn11
          jsb xley_4
arstr2:   0 -> c[m]
arstr1:   c exchange m
arstr0:   shift right a[w]
          c -> a[s]
          return
ufcn5:    search for label
          go to ufcn7
r04304:   go to pad0
fcn1:     if c[m] = 0
               then go to fcn4
          c - 1 -> c[m]
          if c[m] = 0
r04311:        then go to fcn3
fcn6:     0 -> c[m]
          0 -> f7
          go to fcn4
r04315:   keys -> rom address
r04316:   5 -> p
r04317:   if c[p] = 0
               then go to arth4_4
          0 -> c[m]
          shift left a[x]
          shift left a[x]
          c + 1 -> c[p]
sto36_4:  c + 1 -> c[p]
          a - 1 -> a[xs]
          if no carry go to sto36_4
          c exchange m
          go to rtn7
rtn1:     if s9 # 1
               then go to rtn5
rtn3:     0 -> c[ms]
          c exchange m
          select rom 1   ; -> wait29
fcn8:     jsb arstr1
fcn16:    if s3 # 1
               then go to rtn7
fcn13:    memory insert
fcn20:    jsb mcirc0
fnc5:     1 -> f3
          go to rtn7
          jsb arstr2
          go to fcn13
lbr1:     buffer -> rom address
          go to noop_4
ufcn0:    0 -> f5
          if c[m] = 0
               then go to ufcn1
          10 -> p
          if c[p] = 0
               then go to ufcn2
ufcn8:    0 -> c[m]
          c exchange m
          go to ufcn10_4
fcn28:    if p # 15
               then go to fcn6
          jsb noop_4
ufcn2:    11 -> p
          if c[p] >= 1
               then go to ufcn3
ufcn1:    0 -> c[ms]
          if s8 # 1
               then go to ufcn4
          mark and search
          clear status
ufcn6:    1 -> s8
          go to ufcn9
dummy_5:  no operation
err2:     go to err1
dig4_5:   a + 1 -> a[x]
dig3_5:   a + 1 -> a[x]
dig2_5:   a + 1 -> a[x]
r05005:   if no carry go to dig1_5
mpy_5:    go to mpy1
fnl1:     select rom 7   ; -> xty21
xney_5:   jsb setrl2
          a - c -> a[w]
          data -> c
          if a[w] >= 1
               then go to frtn9
          go to rl2
inx1:     0 -> a[w]
          a + 1 -> a[p]
div2:     0 -> b[w]
fnl3:     select rom 6   ; -> r06022
dig7_5:   a + 1 -> a[x]
dig6_5:   a + 1 -> a[x]
dig5_5:   a + 1 -> a[x]
r05025:   if no carry go to dig4_5
add1:     go to add8
fdgt5:    a + 1 -> a[xs]
          if no carry go to fdgt6_5
          go to tan2
xeqy_5:   jsb setrl2
          a - c -> a[w]
          data -> c
          if a[w] >= 1
               then go to rl2
          go to frtn9
fdgt3:    a + 1 -> a[xs]
          if no carry go to fdgt4
tan1:     1 -> s1
          go to sqt1
dig1_5:   a + 1 -> a[x]
r05045:   if no carry go to dig10
div1:     go to mpy3
fidgt4:   a + 1 -> a[xs]
          if no carry go to fidgt5
          go to cos1
xgty_5:   jsb setrl0
          0 - c - 1 -> c[s]
          jsb add3
          data -> c
          go to rl4
fnl2:     select rom 3   ; -> r03060
rl4:      if a[ms] >= 1
               then go to rl5
          go to rl2
dig9_5:   a + 1 -> a[x]
dig8_5:   a + 1 -> a[x]
r05065:   if no carry go to dig7_5
sub1:     go to add2
r05067:   go to frac1_5
xley_5:   jsb setrl0
          a exchange c[w]
          0 - c - 1 -> c[s]
          jsb add3
          data -> c
rl5:      a + 1 -> a[s]
          if no carry go to frtn9
          go to rl2
fdgt1:    a + 1 -> a[xs]
          if no carry go to fdgt2
log1:     1 -> s5
          go to ln1
sdgt7:    delayed select group 1
          select rom 1   ; -> r11106
dig10:    if c[m] = 0
               then go to dig11
          select rom 2   ; -> r02111
dig12:    select rom 2   ; -> den13
fidgt1:   a + 1 -> a[xs]
          if no carry go to fidgt2
          select rom 0   ; -> r00115
gdgt15:   a - b -> a[xs]
          13 -> p
          go to gdgt12
fdgt4:    a + 1 -> a[xs]
          if no carry go to fdgt5
cos1:     1 -> s9
tan2:     1 -> s5
          go to tan1
gdgt1:    0 -> c[m]
          c exchange m
          go to gdgt17
r05130:   jsb savx1
          select rom 3   ; -> int0
r05132:   go to fnl2
fidgt2:   a + 1 -> a[xs]
          if no carry go to fidgt3
          go to log2
gdgt4:    a - 1 -> a[xs]
          if no carry go to abs0
          stack -> a
          c -> stack
          a exchange c[w]
ytx1:     1 -> s6
ytx2:     1 -> s2
          go to fnl1
fidgt5:   a + 1 -> a[xs]
          if no carry go to fidgt6_5
          go to tan2
r05151:   jsb savx3
          buffer -> rom address
          go to dummy_5
r05154:   go to sdgt5
fidgt6_5: select rom 3   ; -> fidgt6_3
gdgt17:   0 -> b[w]
          a - 1 -> a[xs]
          if no carry go to gdgt20
          0 -> f1
          if s11 # 1
               then go to pi2
          c -> stack
pi2:      select rom 6   ; -> lpi11_6
gdgt10:   a - 1 -> a[xs]
          if no carry go to gdgt11
          14 -> p
          go to gdgt12
gdgt11:   a - 1 -> a[xs]
          if no carry go to gdgt13
          go to gdgt14
sdgt6:    6 -> p
          if c[p] = 0
               then go to sdgt7
          jsb savx1
          a + 1 -> a[xs]
          if no carry go to fidgt1
          select rom 0   ; -> r00204
          go to sto34
mpy1:     3 -> p
          0 - c -> c[x]
mpy3:     stack -> a
          go to div2
r05211:   go to gdgt16
r05212:   go to add3
sdgt5:    7 -> p
          if c[p] = 0
               then go to sdgt6
          jsb savx1
          a + 1 -> a[xs]
          if no carry go to fdgt1
sqt1:     0 -> b[w]
          jsb fnl2
sdgt0:    shift left a[x]
          shift left a[x]
          if c[p] >= 1
               then go to gdgt10
          select rom 0   ; -> sdgt1
fdgt6_5:  select rom 3   ; -> fdgt6_3
add2:     0 - c - 1 -> c[s]
add8:     stack -> a
add3:     0 -> b[w]
          a + 1 -> a[xs]
          a + 1 -> a[xs]
          c + 1 -> c[xs]
          c + 1 -> c[xs]
          if a >= c[x]
               then go to add4
          a exchange c[w]
add4:     a exchange c[m]
          if c[m] = 0
               then go to add5
          a exchange c[w]
add5:     b exchange c[m]
add6:     if a >= c[x]
               then go to add7
          shift right b[w]
          a + 1 -> a[x]
          if b[w] = 0
               then go to add7
          go to add6
          no operation
fdgt2:    a + 1 -> a[xs]
          if no carry go to fdgt3
ln1:      1 -> s6
log2:     1 -> s9
          go to ytx2
savx1:    0 -> c[m]
savx3:    c exchange m
savx2:    0 -> b[w]
          b exchange c[w]
          c -> data address
          b exchange c[w]
          c -> data
          12 -> p
          return
add7:     select rom 6   ; -> add12
err1:     clear status
          0 -> c[w]
          1 -> s5
          go to err3_5
rl2:      select rom 4   ; -> r04304
gdgt2_5:  select rom 0   ; -> gdgt2_0
frac1_5:  jsb savx1
          select rom 3   ; -> frac0
gdgt14:   15 -> p
gdgt12:   select rom 4   ; -> r04311
r05311:   go to gdgt3_5
fidgt3:   1 -> s7
          a + 1 -> a[xs]
          if no carry go to fidgt4
          go to tan1
sdgt8:    select rom 4   ; -> r04317
err3_5:   select rom 2   ; -> err3_2
          go to add3
          go to sto34
gdgt20:   jsb savx2
          go to gdgt2_5
abs0:     0 -> c[s]
frtn8:    select rom 2   ; -> frtn1
frtn9:    select rom 2   ; -> frtn2
frtn10_5: select rom 2   ; -> r02330
gdgt3_5:  a - 1 -> a[xs]
          if no carry go to gdgt4
          go to inx1
r05333:   if s4 # 1
               then go to frtn8
          return
dig11:    c exchange m
          if s3 # 1
               then go to dig12
dig13:    select rom 4   ; -> fcn13
          no operation
gdgt13:   2 -> p
          b exchange c[w]
          load constant 5
          b exchange c[w]
          if a >= b[xs]
               then go to gdgt15
          if s3 # 1
               then go to gdgt1
gdgt16:   0 -> c[m]
          c exchange m
          go to dig13
setrl0:   0 -> s1
          0 -> s2
setrl2:   c exchange m
          0 -> b[w]
          b exchange c[w]
          c - 1 -> c[s]
          shift right c[w]
          c -> data address
          b -> c[w]
          stack -> a
          c -> data
setrl1:   a exchange c[w]
          c -> stack
          1 -> s4
          return
sto33:    jsb add3
sto34:    14 -> p
          go to frtn8
          b exchange c[s]
          go to tan13
tan15:    a exchange b[w]
          jsb tnm11
          data -> c
          a exchange c[w]
          jsb tnm11
          data -> c
          a exchange c[w]
tanx_6:   if s9 # 1
               then go to tan16
          a exchange c[w]
tan16:    if s5 # 1
               then go to asn12
          if c[s] >= 1
               then go to tan17
          0 -> s6
tan17:    0 -> c[s]
r06022:   jsb div11
asn11:    c -> data
          jsb mpy11
          jsb add10_6
          jsb sqt11
          data -> c
          select rom 3   ; -> r03031
asn1z0:   a exchange c[w]
asn12:    jsb div11
          if s7 # 1
               then go to rtn12
atn11:    0 -> a[w]
          a + 1 -> a[p]
          a -> b[m]
          a exchange c[m]
atn12:    c - 1 -> c[x]
          shift right b[wp]
          if c[xs] = 0
               then go to atn12
atn13:    shift right a[wp]
          c + 1 -> c[x]
          if no carry go to atn13
          shift right a[w]
          shift right b[w]
          c -> data
atn14:    b exchange c[w]
          go to atn18
sqt11:    b exchange c[w]
          4 -> p
          go to sqt14
tnm11:    c -> data
          a exchange c[w]
          if c[p] = 0
               then go to tnm12
          0 - c -> c[w]
tnm12:    c -> a[w]
          b -> c[x]
          go to add15
tanxz0:   no operation
tploxj:   select rom 3   ; -> r03072
sin12_6:  if s5 # 1
               then go to atn11
          0 - c - 1 -> c[s]
          a exchange c[s]
          go to asn11
atn15:    shift right b[wp]
atn16:    a - 1 -> a[s]
          if no carry go to atn15
          c + 1 -> c[s]
          a exchange b[wp]
          a + c -> c[wp]
          a exchange b[w]
atn18:    a -> b[w]
          a - c -> a[wp]
          if no carry go to atn16
          a exchange c[w]
          data -> c
          shift right c[w]
          a exchange c[s]
          a exchange b[w]
          shift left a[wp]
          c -> data
          a + 1 -> a[s]
          a + 1 -> a[s]
          if no carry go to atn14
          0 -> c[w]
          0 -> b[x]
          shift right a[ms]
          jsb div14
          a - 1 -> a[p]
          data -> c
          4 -> p
atn17:    jsb pqo13
          6 -> p
          jsb pmu11
          8 -> p
          jsb pmu11
          2 -> p
          load constant 8
          10 -> p
          jsb pmu11
          jsb atcd1
          jsb pmu11
          jsb atc1
          shift left a[w]
          jsb pmu11
          b -> c[w]
          jsb add15
tan12:    jsb atc1
          c + c -> c[w]
          if s7 # 1
               then go to rom0
          if s9 # 1
               then go to rom0
          a exchange c[w]
          0 - c - 1 -> c[s]
          jsb add11
          jsb atc1
          c + c -> c[w]
rom0:     select rom 3   ; -> r03166
lpi11_6:  jsb atc1
          c + c -> c[w]
          c + c -> c[w]
          jsb rtn11
          c + c -> c[w]
          jsb pre11
          jsb atc1
          10 -> p
          jsb pqo11
          jsb atcd1
          8 -> p
          jsb pqo12
          2 -> p
          load constant 8
          6 -> p
          jsb pqo11
          4 -> p
          jsb pqo11
          jsb pqo11
          a exchange b[w]
          shift right c[w]
          13 -> p
          load constant 5
          go to tan14
atcd1:    6 -> p
          load constant 8
          load constant 6
          load constant 5
          load constant 2
          load constant 4
          load constant 9
rtn11:    if s1 # 1
               then go to rtn12
          return
add10_6:  0 -> a[w]
          a + 1 -> a[p]
add11:    select rom 5   ; -> add3
pmu11:    select rom 7   ; -> pmu21
pqo11:    shift left a[w]
pqo12:    shift right b[ms]
          b exchange c[w]
          go to pqo16
pqo15:    c + 1 -> c[s]
pqo16:    a - b -> a[w]
          if no carry go to pqo15
          a + b -> a[w]
pqo13:    select rom 7   ; -> r07245
mpy11:    select rom 7   ; -> mpy21
div11:    a - c -> c[x]
          select rom 7   ; -> div21
sqt15:    c + 1 -> c[p]
sqt16:    a - c -> a[w]
          if no carry go to sqt15
          a + c -> a[w]
          shift left a[w]
          p - 1 -> p
sqt17:    shift right c[wp]
          if p # 0
               then go to sqt16
          go to tnm12
div14:    c + 1 -> c[p]
div15:    a - b -> a[ms]
          if no carry go to div14
          a + b -> a[ms]
          shift left a[ms]
div16:    p - 1 -> p
          if p # 0
r06271:        then go to div15
          go to tnm12
sqt12:    p - 1 -> p
          a + b -> a[ms]
          if no carry go to sqt18
          select rom 5   ; -> err1
add12:    c - 1 -> c[xs]
          c - 1 -> c[xs]
          0 -> a[x]
          a - c -> a[s]
          if a[s] >= 1
               then go to add13
          select rom 7   ; -> r07306
add13:    if a >= b[m]
               then go to add14
          0 - c - 1 -> c[s]
          a exchange b[w]
add14:    a - b -> a[w]
add15:    select rom 7   ; -> nrm21
atc1:     0 -> c[w]
          11 -> p
          load constant 7
          load constant 8
          load constant 5
          load constant 3
          load constant 9
          load constant 8
          load constant 1
          load constant 6
          load constant 3
          load constant 5
          12 -> p
          return
rtn12:    select rom 3   ; -> r03333
sqt18:    a + b -> a[x]
          if no carry go to sqt14
          c - 1 -> c[p]
sqt14:    c + 1 -> c[s]
          if p # 0
               then go to sqt12
          a exchange c[x]
          0 -> a[x]
          if c[p] >= 1
               then go to sqt13
          shift right a[w]
sqt13:    shift right c[w]
          b exchange c[x]
          0 -> c[x]
          12 -> p
          go to sqt17
pre11:    select rom 7   ; -> pre21
tan18:    shift right b[wp]
          shift right b[wp]
tan19:    c - 1 -> c[s]
          if no carry go to tan18
          a + c -> c[wp]
          a - b -> a[wp]
          b exchange c[wp]
tan13:    b -> c[w]
          a - 1 -> a[s]
          if no carry go to tan19
          a exchange c[s]
          data -> c
          a exchange c[w]
          if b[s] = 0
               then go to tan15
          shift left a[w]
tan14:    a exchange c[wp]
          c -> data
          shift right b[wp]
          c - 1 -> c[s]
err21:    select rom 5   ; -> err2
ln24:     a exchange b[s]
          a + 1 -> a[s]
          shift right c[ms]
          shift left a[wp]
          go to ln26
xty22:    stack -> a
          jsb mpy21
xty21:    c -> a[w]
          if s6 # 1
               then go to exp21
ln22:     0 -> a[w]
          a - c -> a[m]
          if no carry go to err21
          shift right a[w]
          c - 1 -> c[s]
          if no carry go to err21
ln25:     c + 1 -> c[s]
ln26:     a -> b[w]
          jsb eca22
          a - 1 -> a[p]
          if no carry go to ln25
          a exchange b[wp]
          a + b -> a[s]
          if no carry go to ln24
          7 -> p
          jsb pqo23
          8 -> p
          jsb pmu22
          9 -> p
          jsb pmu21
          jsb lncd3
          10 -> p
          jsb pmu21
          jsb lncd2
          11 -> p
          jsb pmu21
          jsb lncd1
          jsb pmu21
          jsb lnc2
          jsb pmu21
          jsb lnc10
          a exchange c[w]
          a - c -> c[w]
          if b[xs] = 0
               then go to ln27
          a - c -> c[w]
ln27:     a exchange b[w]
ln28:     p - 1 -> p
          shift left a[w]
          if p # 1
               then go to ln28
          a exchange c[w]
          if c[s] = 0
               then go to ln29
          0 - c - 1 -> c[m]
ln29:     c + 1 -> c[x]
          11 -> p
          jsb mpy27
          if s9 # 1
               then go to xty22
          if s5 # 1
               then go to rtn21
          jsb lnc10
          jsb mpy22
          go to rtn21
exp21:    jsb lnc10
          jsb pre21
          jsb lnc2
          11 -> p
          jsb pqo21
          jsb lncd1
          10 -> p
          jsb pqo21
          jsb lncd2
          9 -> p
          jsb pqo21
          jsb lncd3
          8 -> p
          jsb pqo21
          jsb pqo21
          jsb pqo21
          6 -> p
          0 -> a[wp]
          13 -> p
          b exchange c[w]
          a exchange c[w]
          load constant 6
          go to exp23
pre23:    if s2 # 1
               then go to pre24
          a + 1 -> a[x]
pre29:    if a[xs] >= 1
               then go to pre27
pre24:    a - b -> a[ms]
          if no carry go to pre23
          a + b -> a[ms]
          shift left a[w]
          c - 1 -> c[x]
          if no carry go to pre29
pre25:    shift right a[w]
          0 -> c[wp]
          a exchange c[x]
pre26:    if c[s] = 0
               then go to pre28
          a exchange b[w]
          a - b -> a[w]
          0 - c - 1 -> c[w]
pre28:    shift right a[w]
pqo23:    b exchange c[w]
          0 -> c[w]
          c - 1 -> c[m]
          if s2 # 1
               then go to pqo28
          load constant 4
          c + 1 -> c[m]
          if no carry go to pqo24
pqo27:    load constant 6
pqo28:    if p # 1
               then go to pqo27
          shift right c[w]
pqo24:    shift right c[w]
nrm26:    if s2 # 1
               then go to rtn21
          return
lncd2:    7 -> p
lnc6:     load constant 3
          load constant 3
          load constant 0
lnc7:     load constant 8
          load constant 5
          load constant 0
          load constant 9
          go to lnc9
exp29:    jsb eca22
          a + 1 -> a[p]
exp22:    a -> b[w]
          c - 1 -> c[s]
          if no carry go to exp29
          shift right a[wp]
          a exchange c[w]
          shift left a[ms]
exp23:    a exchange c[w]
          a - 1 -> a[s]
          if no carry go to exp22
          a exchange b[w]
          a + 1 -> a[p]
          jsb nrm21
rtn21:    select rom 6   ; -> rtn11
eca21:    shift right a[wp]
eca22:    a - 1 -> a[s]
          if no carry go to eca21
          0 -> a[s]
          a + b -> a[w]
          return
pqo21:    select rom 6   ; -> pqo11
pmu21:    shift right a[w]
pmu22:    b exchange c[w]
          go to pmu24
pmu23:    a + b -> a[w]
pmu24:    c - 1 -> c[s]
          if no carry go to pmu23
          a exchange c[w]
          shift left a[ms]
          a exchange c[w]
r07245:   go to pqo23
mpy21:    3 -> p
mpy22:    a + c -> c[x]
div21:    a - c -> c[s]
          if no carry go to div22
          0 - c -> c[s]
div22:    a exchange b[m]
          0 -> a[w]
          if p # 12
               then go to mpy27
          if c[m] >= 1
               then go to div23
          if s1 # 1
               then go to err21
          delayed select group 1
          select rom 0   ; -> r10265
r07265:   go to nrm25
div23:    b exchange c[wp]
          a exchange c[m]
          select rom 6   ; -> r06271
lnc2:     0 -> s6
          load constant 6
          load constant 9
          load constant 3
          load constant 1
          load constant 4
          load constant 7
          load constant 1
          go to lnc8
pre27:    a + 1 -> a[m]
          if no carry go to pre25
mpy26:    a + b -> a[w]
mpy27:    c - 1 -> c[p]
r07306:   if no carry go to mpy26
mpy28:    shift right a[w]
          p + 1 -> p
          if p # 13
               then go to mpy27
nrm20:    c + 1 -> c[x]
nrm21:    0 -> a[s]
          12 -> p
          0 -> b[w]
nrm23:    if a[p] >= 1
               then go to nrm24
          shift left a[w]
          c - 1 -> c[x]
          if a[w] >= 1
               then go to nrm23
          0 -> c[w]
nrm24:    a -> b[x]
          a + b -> a[w]
          if a[s] >= 1
               then go to mpy28
          a exchange c[m]
nrm25:    c -> a[w]
          0 -> b[w]
nrm27:    12 -> p
          go to nrm26
lncd1:    9 -> p
          load constant 3
          load constant 1
          load constant 0
          load constant 1
          load constant 7
          load constant 9
lnc8:     load constant 8
          load constant 0
          load constant 5
          load constant 5
lnc9:     load constant 3
          go to nrm27
pre21:    a exchange c[w]
          a -> b[w]
          c -> a[m]
          c + c -> c[xs]
          if no carry go to pre24
          c + 1 -> c[xs]
pre22:    shift right a[w]
          c + 1 -> c[x]
          if no carry go to pre22
          go to pre26
lnc10:    0 -> c[w]
          12 -> p
          load constant 2
          load constant 3
          load constant 0
          load constant 2
          load constant 5
          go to lnc7
lncd3:    5 -> p
          go to lnc6

j10000:   no operation	; target of buffer -> rom address at @10064
j10001:   0 -> c[m]
          c exchange m
          delayed select group 0
          select rom 4   ; -> r04005
          no operation
mpy_8:    if c[p] >= 1
               then go to j10213
          6 -> p
          if c[p] >= 1
               then go to j10211
          go to j10024
j10014:   if c[s] = 0
               then go to j10241
          go to j10375
j10017:   0 -> f4
          if s11 # 1
               then go to j10214
          1 -> f4
          go to j10001
j10024:   delayed select group 0
          select rom 0   ; -> r00026
pls_8:    go to j10036
j10027:   0 -> f6
          if s11 # 1
               then go to j10214
          1 -> f6
          go to j10001
j10034:   0 -> f4
          go to j10214
j10036:   if c[p] >= 1
               then go to j10054
          6 -> p
          if c[p] >= 1
               then go to j10017
          go to j10024
j10044:   1 -> f4
          go to j10214
dvd_8:    if c[p] >= 1
               then go to j10157
          6 -> p
          if c[p] >= 1
               then go to j10027
          go to j10024
j10054:   0 -> f4
          if s11 # 1
               then go to j10001
          1 -> f4
          go to j10214
          no operation
r10062:   0 -> s11
          7 -> p
          buffer -> rom address
          go to j10000
mns_8:    if c[p] >= 1
               then go to j10044
          6 -> p
          if c[p] >= 1
               then go to j10034
          go to j10024
c10074:   if b[p] = 0
               then go to j10100
          shift right b[wp]
          a + 1 -> a[x]
j10100:   return
c10101:   display off
          c -> a[x]
          c exchange m
          shift right a[x]
          shift right a[x]
          0 -> p
          if c[m] >= 1
               then go to j10112
          0 -> c[x]
j10112:   b exchange c[w]
          0 -> c[w]
          c - 1 -> c[w]
          c + 1 -> c[s]
          c + 1 -> c[s]
          c + 1 -> c[s]
          b exchange c[w]
          0 -> f2
          return
j10123:   p - 1 -> p
j10124:   a - 1 -> a[x]
          if no carry go to j10206
j10126:   0 -> a[w]
          c -> a[wp]
          a + c -> a[m]
          if no carry go to j10135
          a + 1 -> a[s]
          shift right a[ms]
          a + 1 -> a[x]
j10135:   a -> b[x]
          return
j10137:   0 -> c[w]
          c + 1 -> c[s]
          c + 1 -> c[m]
          shift right c[w]
          c -> a[w]
c10144:   c + 1 -> c[x]
j10145:   select rom 1   ; -> r11146
          no operation
j10147:   0 -> b[p]
          a - 1 -> a[xs]
j10151:   if a[xs] >= 1
               then go to j10231
j10153:   0 -> a[x]
          a - 1 -> a[x]
          a -> b[x]
          go to j10321
j10157:   0 -> f6
          if s11 # 1
               then go to j10001
          1 -> f6
          go to j10214
r10164:   jsb c10101
          a + c -> a[x]
          jsb c10266
          if a[xs] >= 1
               then go to j10364
          13 -> p
j10172:   p - 1 -> p
          shift right b[ms]
          a - 1 -> a[x]
          if no carry go to j10361
          jsb c10272
          go to j10151
j10200:   shift right b[m]
          if c[x] = 0
               then go to j10370
          go to j10366
          no operation
          no operation
j10206:   if p # 2
               then go to j10123
          go to j10126
j10211:   0 -> f6
          go to j10214
j10213:   1 -> f6
j10214:   0 -> c[m]
          c exchange m
          delayed select group 0
          select rom 1   ; -> wait10
r10220:   jsb c10101
          jsb c10266
          a - 1 -> a[xs]
          if a[x] >= 1
               then go to j10303
j10225:   0 -> b[m]
          shift right b[ms]
          c -> a[w]
          go to j10320
j10231:   p - 1 -> p
          if p # 2
               then go to j10147
j10234:   0 -> a[s]
          a + 1 -> a[s]
          a + 1 -> a[s]
          a -> b[s]
          go to j10225
j10241:   0 -> a[x]
          if a[wp] >= 1
               then go to j10375
          if p # 11
               then go to j10276
j10246:   a exchange c[w]
          0 -> a[w]
          a + 1 -> a[p]
          0 - c -> c[w]
          if no carry go to c10144
          a exchange c[w]
          shift right c[w]
          c + 1 -> c[s]
j10256:   12 -> p
          go to j10333
j10260:   0 -> c[wp]
          c - 1 -> c[wp]
          0 -> c[xs]
          delayed select group 0
          select rom 7   ; -> r07265
r10265:   go to j10260
c10266:   a + 1 -> a[x]
          12 -> p
          go to j10124
r10271:   go to j10014
c10272:   c exchange m
          c -> a[x]
          c exchange m
          return
j10276:   if p # 10
               then go to j10137
          shift left a[w]
          11 -> p
          go to j10246
j10303:   a + 1 -> a[xs]
          shift right b[ms]
          jsb c10307
j10306:   0 -> b[p]
c10307:   p + 1 -> p
          if p # 12
               then go to j10306
          a exchange c[x]
          if c[xs] = 0
               then go to j10317
          0 - c -> c[x]
          c - 1 -> c[xs]
j10317:   a exchange c[x]
j10320:   0 -> b[x]
j10321:   c -> a[s]
          if s5 # 1
               then go to j10331
          clear status
          1 -> s5
j10326:   delayed select group 0
          select rom 1   ; -> r01330
          no operation
j10331:   clear status
          go to j10326
j10333:   a -> b[ms]
j10334:   a + c -> a[w]
          if no carry go to j10334
          a - c -> a[w]
          shift left a[w]
j10340:   a + c -> a[w]
          if no carry go to j10340
          a + 1 -> a[s]
          a exchange b[w]
          jsb c10074
          11 -> p
          jsb c10074
          b -> c[w]
          0 -> b[wp]
          shift right b[w]
          a exchange b[w]
          a + b -> a[ms]
          if no carry go to j10256
          a exchange c[w]
          b exchange c[x]
          c + 1 -> c[x]
          jsb c10144
j10361:   if p # 3
               then go to j10172
          go to j10234
j10364:   jsb c10272
          b exchange c[x]
j10366:   shift right a[m]
          c + 1 -> c[x]
j10370:   a - 1 -> a[xs]
          if no carry go to j10200
          shift right b[ms]
          b exchange c[x]
          go to j10153
j10375:   select rom 1   ; -> r11376
          c exchange m
          go to j10326
j11000:   shift right a[w]
          a exchange c[m]
          go to j11264
j11003:   delayed select group 0
          select rom 3   ; -> r03005
j11005:   if s9 # 1
               then go to j11034
          go to j11102
          no operation
r11011:   1 -> s1
          1 -> s7
          1 -> s10
          1 -> s6
          c -> a[w]
          if c[s] = 0
               then go to j11021
          1 -> s4
j11021:   down rotate
          c -> stack
          a exchange c[w]
          if a[m] >= 1
               then go to c11070
          0 -> c[wp]
          c + 1 -> c[p]
          jsb c11070
j11031:   c exchange m
          go to j11350
          no operation
j11034:   select rom 2   ; -> r12035
r11035:   c -> stack
          0 -> c[w]
          c -> data address
          12 -> p
          data -> c
          a exchange c[w]
          0 -> b[w]
          0 -> s1
          1 -> s10
          go to j11277
r11047:   display off
          1 -> f7
          jsb c11247
          1 -> f7
          jsb c11247
          0 -> a[w]
          if s3 # 1
               then go to j11071
          0 -> f2
          pointer advance
          jsb c11250
          jsb c11250
          jsb c11250
          jsb c11250
          go to j11212
c11066:   memory initialize
          go to c11250
c11070:   jsb c11245
j11071:   jsb c11250
          jsb c11250
          0 -> f2
          0 -> f3
j11075:   0 -> s11
          0 -> f2
          if s11 # 1
               then go to j11177
          go to j11360
j11102:   shift right a[w]
          c -> a[s]
          delayed select group 0
          select rom 2   ; -> r02106
r11106:   12 -> p
          a exchange c[xs]
          c - 1 -> c[p]
          if c[p] = 0
               then go to j11116
          1 -> p
          load constant 3
          go to j11120
j11116:   1 -> p
          load constant 1
j11120:   0 -> c[m]
          c exchange m
          go to j11346
j11123:   c - 1 -> c[xs]
c11124:   select rom 3   ; -> r13125
r11125:   go to j11270
j11126:   0 -> s10
          c -> a[w]
          delayed select group 0
          select rom 5   ; -> r05132
r11132:   jsb c11220
          a exchange b[w]
          a + 1 -> a[m]
          a -> b[xs]
          a - 1 -> a[xs]
          a + b -> a[w]
          0 -> a[x]
          jsb c11326
          jsb c11326
          0 -> a[x]
j11144:   jsb c11261
          go to c11324
r11146:   go to j11144
j11147:   0 -> f2
          0 -> f5
          0 -> f0
          delayed select group 0
          select rom 4   ; -> r04154
r11154:   go to c11324
          go to j11216
r11156:   jsb c11220
          jsb c11327
          0 -> b[w]
          a exchange b[wp]
          a exchange b[w]
          shift left a[w]
          jsb c11331
          jsb c11261
          0 -> c[w]
          load constant 3
          load constant 6
          go to j11003
c11172:   c + 1 -> c[xs]
          if c[x] >= 1
               then go to j11123
          0 -> c[w]
          jsb c11124
j11177:   0 -> f0
          if s11 # 1
               then go to j11367
          1 -> f3
          go to j11075
j11204:   if s8 # 1
               then go to j11005
          go to j11102
j11207:   0 -> f0
          if s11 # 1
               then go to j11207
j11212:   1 -> f3
j11213:   0 -> s11
          0 -> f0
          if s11 # 1
j11216:        then go to j11352
          go to j11213
c11220:   c -> a[w]
          b exchange c[m]
          0 -> c[x]
          0 -> p
          load constant 5
          a - c -> a[x]
          if a[xs] >= 1
               then go to j11340
          go to r11376
r11231:   stack -> a
          c -> stack
          0 -> a[s]
          data -> c
          if c[s] = 0
               then go to j11240
          a - 1 -> a[s]
j11240:   a exchange c[w]
          if s6 # 1
               then go to c11172
          0 - c - 1 -> c[s]
          jsb c11172
c11245:   delayed select group 0
          select rom 1   ; -> r01247
c11247:   search for label
c11250:   p + 1 -> p
          if p # 12
               then go to c11250
          return
j11254:   c - 1 -> c[x]
j11255:   shift left a[w]
          if a[s] >= 1
               then go to j11000
          go to j11254
c11261:   if a[m] >= 1
               then go to j11255
          0 -> c[w]
j11264:   c -> a[w]
          12 -> p
          0 -> b[w]
          return
j11270:   a - 1 -> a[xs]
          a - 1 -> a[xs]
          a - 1 -> a[xs]
          if no carry go to j11126
          c - 1 -> c[xs]
r11275:   jsb c11324
j11276:   select rom 3   ; -> r13277
j11277:   delayed select group 0
          select rom 3   ; -> ptr2
r11301:   c -> a[w]
          0 -> s1
          stack -> a
          c -> stack
          a exchange c[w]
          c -> a[w]
          12 -> p
          delayed select group 0
          select rom 3   ; -> r03312
j11312:   if c[m] >= 1
               then go to j11031
          go to j11276
r11315:   c -> data
          0 -> c[w]
          c -> data address
          0 -> s4
          data -> c
          delayed select group 0
          select rom 3   ; -> r03324
c11324:   delayed select group 0
          select rom 2   ; -> frtn1
c11326:   0 -> b[w]
c11327:   a exchange b[wp]
          shift right b[w]
c11331:   10 -> p
j11332:   a + b -> a[w]
          p - 1 -> p
          if p # 4
               then go to j11332
          return
          no operation
j11340:   shift right b[w]
          a + 1 -> a[x]
          if no carry go to j11340
          0 -> a[w]
          6 -> p
          return
j11346:   delayed select group 0
          select rom 2   ; -> r02350
j11350:   delayed select group 0   ; -> r
          1 -> s0
j11352:   0 -> f3
          0 -> s11
          0 -> f2
          if s11 # 1
               then go to j11207
          1 -> f3
j11360:   0 -> a[w]
j11361:   a + 1 -> a[x]
          if a[x] >= 1
               then go to j11361
          pointer advance
          jsb c11250
          go to j11147
j11367:   a + 1 -> a[x]
          a + 1 -> a[x]
          if no carry go to j11075
          jsb c11066
          1 -> f2
          0 -> f5
          0 -> f2
r11376:   delayed select group 0
          select rom 7   ; -> err21

j12000:   no operation	 	; target of buffer -> rom address at @12100
j12001:   a - 1 -> a[x]
          a -> b[x]
          0 -> c[m]
          c + 1 -> c[m]
          jsb c12064
c12006:   12 -> p
          go to j12136
g_a:      go to dflt0
resetp:   search for label
          go to dflt3
j12013:   shift right a[w]
          jsb c12167
rdn_a:    go to dflt0
f_a:      go to dflt0
          no operation
r12020:   go to j12077
excg_a:   go to dflt0
          no operation
ytx:      go to dflt0
inx:      go to dflt0
j12025:   delayed select group 0
          select rom 4   ; -> r04027
          no operation
e_a:      go to dflt0
          no operation
d_a:      go to dflt0
c_a:      go to dflt0
b_a:      go to dflt0
r12035:   go to j12376
a_a:      go to dflt0
dflt0:    memory insert
          1 -> f7
dflt3:    0 -> s11
dflt1:    0 -> f5
          if s11 # 1
               then go to dflt1
          0 -> f5
          return
j12047:   0 -> p
          load constant 2
          go to j12300
rtn_a:    go to dflt0
lbl_a:    go to dflt0
r12054:   0 -> c[w]
          c + 1 -> c[xs]
          shift right c[x]
          if a >= c[x]
               then go to j12375
          go to j12171
sqt:      go to dflt0
j12063:   a - 1 -> a[x]
c12064:   jsb c12365
          if a[x] >= 1
               then go to j12063
          a exchange c[m]
          a exchange b[m]
          go to j12235
eex_a:    go to j12220
chs_a:    go to j12257
j12074:   memory initialize
          go to j12025
entr_a:   go to j12106
j12077:   7 -> p
          buffer -> rom address
          go to j12000
          no operation
          no operation
r12104:   delayed select rom 1
          go to j11204
j12106:   if c[p] >= 1
               then go to j12300
          6 -> p
          if c[p] >= 1
               then go to j12300
          3 -> p
          if c[p] >= 1
               then go to j12162
          go to c12167
j12117:   0 -> a[x]
          if a[wp] >= 1
               then go to j12375
          0 -> p
          a - 1 -> a[p]
          if a >= c[x]
               then go to j12371
          go to j12375
j12127:   c + c -> c[ms]
          c + c -> c[ms]
          c + c -> c[ms]
          shift right c[ms]
          c + 1 -> c[x]
          p - 1 -> p
          a - 1 -> a[x]
j12136:   0 -> a[ms]
          a exchange b[p]
          a + c -> c[ms]
          if a[x] >= 1
               then go to j12127
          b -> c[s]
          c -> a[ms]
          select rom 1   ; -> r11146
          no operation
          no operation
j12150:   c + 1 -> c[p]
j12151:   a - 1 -> a[m]
          if no carry go to j12150
          select rom 1   ; -> r11154
j12154:   0 -> a[m]
          0 -> c[wp]
j12156:   if a[x] >= 1
               then go to j12001
          a exchange b[m]
          go to j12151
j12162:   0 -> p
          load constant 1
          go to j12300
r12165:   go to j12117
          no operation
c12167:   delayed select group 0
          select rom 0   ; -> nosfx2
j12171:   0 -> a[x]
          if a[wp] >= 1
               then go to j12375
          go to j12177
j12175:   shift right a[m]
          p - 1 -> p
j12177:   if p # 2
               then go to j12175
          a exchange b[m]
          a exchange c[s]
          12 -> p
          c + 1 -> c[m]
j12205:   jsb c12365
          c -> a[m]
          a - 1 -> a[m]
          if a >= b[m]
               then go to j12154
          a + 1 -> a[x]
          if a >= c[x]
               then go to j12375
          go to j12205
j12216:   delayed select group 0
          select rom 1   ; -> wait10
j12220:   if c[p] >= 1
               then go to j12246
          6 -> p
          if c[p] >= 1
               then go to j12246
          3 -> p
          if c[p] >= 1
               then go to j12047
          go to c12167
          no operation
r12232:   7 -> p
          go to j12251
j12234:   c + 1 -> c[p]
j12235:   a - b -> a[m]
          if no carry go to j12234
          a + b -> a[ms]
          c + 1 -> c[x]
          a -> b[m]
          a exchange b[x]
          c -> a[m]
          p - 1 -> p
          go to j12156
j12246:   jsb clrc0
          c -> a[w]
          jsb c12362
j12251:   if c[p] >= 1
               then go to j12074
          6 -> p
          if c[p] >= 1
               then go to j12074
          go to c12167
j12257:   if c[p] >= 1
               then go to j12273
          6 -> p
          if c[p] >= 1
               then go to j12273
          3 -> p
          if c[p] = 0
               then go to j12013
          0 -> p
          load constant 0
          go to j12300
          no operation
j12273:   jsb c12347
          c -> stack
          c -> stack
          c -> stack
j12277:   b exchange c[w]
j12300:   0 -> c[m]
          c exchange m
          go to j12216
r12303:   clear registers
          1 -> f2
          1 -> f3
          clear status
          2 -> p
          load constant 2
          load constant 2
          load constant 1
          0 -> f5
          1 -> f7
          jsb lbl_a
          jsb a_a
          jsb g_a
          jsb inx
          jsb rtn_a
          jsb lbl_a
          jsb b_a
          jsb f_a
          jsb sqt
          jsb rtn_a
          jsb lbl_a
          jsb c_a
          jsb g_a
          jsb ytx
          jsb rtn_a
          jsb lbl_a
          jsb d_a
          jsb rdn_a
          jsb rtn_a
          jsb lbl_a
          jsb e_a
          jsb excg_a
          jsb rtn_a
          jsb resetp
          jsb clrc0
          go to j12357
c12347:   c exchange m
          0 -> c[w]
          c exchange m
clrc0:    12 -> p
clrc1:    0 -> b[w]
          b exchange c[w]
          return
j12356:   a exchange c[w]
j12357:   c -> data address
          a exchange c[w]
          c -> data
c12362:   a + 1 -> a[p]
          if no carry go to j12356
          go to j12277
c12365:   c + c -> c[m]
          c + c -> c[m]
          c + c -> c[m]
          return
j12371:   c -> a[x]
          0 -> c[w]
          a -> b[ms]
          jsb c12006
j12375:   select rom 1   ; -> r11376
j12376:   delayed select group 0
          go to data2
noop_b:   go to j13102
sto4_b:   go to j13105
dig3_b:   go to j13341
dig2_b:   go to j13342
dig1_b:   go to j13343
sto6_b:   go to j13110
mpy_b:    go to j13361
xney_b:   go to j13113
g_b:      go to c13242
rup_b:    go to j13117
rcl_b:    go to c13363
sto_b:    go to c13171
fi_b:     go to j13047
rdn_b:    go to j13130
f_b:      go to j13133
rcl8_b:   go to j13135
rcl7_b:   go to j13140
excg_b:   go to j13143
dig6_b:   go to j13336
dig5_b:   go to j13337
dig4_b:   go to j13340
rcl6_b:   go to j13122
pls_b:    go to j13173
rcl4_b:   go to j13175
e_b:      go to j13200
xeqy_b:   go to j13202
d_b:      go to j13250
c_b:      go to j13207
b_b:      go to j13211
rcl5_b:   go to j13213
a_b:      go to j13216
rcl3_b:   go to j13220
rcl2_b:   go to j13223
rcl1_b:   go to j13226
data_b:   go to j13231
dec_b:    go to j13233
dig0_b:   go to c13344
sto7_b:   go to j13235
dvd_b:    go to j13240
j13047:   load constant 3
sst_b:    go to j13342
xgty_b:   go to j13244
rtn_b:    go to j13246
lbl_b:    go to j13204
gto_b:    go to j13303
sto5_b:   go to j13254
dsp_b:    go to j13115
sto3_b:   go to j13257
sto2_b:   go to j13262
sto1_b:   go to j13265
dig9_b:   go to j13333
dig8_b:   go to j13334
dig7_b:   go to j13335
sto8_b:   go to j13373
mns_b:    go to j13275
xley_b:   go to j13301
clx_b:    go to j13252
          no operation
eex_b:    go to j13376
chs_b:    go to j13305
lstx_b:   go to j13330
          no operation
entr_b:   go to j13307
mrk_b:    1 -> s4
          jsb c13344
          go to c13344
j13102:   1 -> s4
          jsb c13242
          go to j13343
j13105:   1 -> s4
          jsb c13171
          go to j13340
j13110:   1 -> s4
          jsb c13171
          go to j13336
j13113:   1 -> s4
          jsb c13242
j13115:   load constant 2
          go to j13343
j13117:   1 -> s4
          jsb c13242
          go to j13333
j13122:   1 -> s4
          jsb c13363
          go to j13336
r13125:   go to j13365
j13126:   delayed select group 0
          select rom 1   ; -> r01130
j13130:   1 -> s4
          jsb c13242
          go to j13334
j13133:   load constant 3
          go to j13343
j13135:   1 -> s4
          jsb c13363
          go to j13334
j13140:   1 -> s4
          jsb c13363
          go to j13335
j13143:   1 -> s4
          jsb c13242
          go to j13335
r13146:   display off
          0 -> f2
          c -> a[w]
          a exchange b[w]
          1 -> s5
          memory full -> a
          0 -> p
          if a[p] >= 1
               then go to j13160
          0 -> s5
j13160:   0 -> a[w]
          a - 1 -> a[w]
          shift left a[m]
          shift left a[m]
          0 -> c[w]
          4 -> p
          0 -> s4
          buffer -> rom address
          go to noop_b
c13171:   load constant 3
          go to j13341
j13173:   load constant 6
          go to j13343
j13175:   1 -> s4
          jsb c13363
          go to j13340
j13200:   load constant 1
          go to j13337
j13202:   1 -> s4
          jsb c13242
j13204:   load constant 2
          go to j13341
          no operation
j13207:   load constant 1
          go to j13341
j13211:   load constant 1
          go to j13342
j13213:   1 -> s4
          jsb c13363
          go to j13337
j13216:   load constant 1
          go to j13343
j13220:   1 -> s4
          jsb c13363
          go to j13341
j13223:   1 -> s4
          jsb c13363
          go to j13342
j13226:   1 -> s4
          jsb c13363
          go to j13343
j13231:   load constant 8
          go to j13340
j13233:   load constant 8
          go to j13341
j13235:   1 -> s4
          jsb c13171
          go to j13335
j13240:   load constant 8
          go to j13343
c13242:   load constant 3
          go to j13337
j13244:   1 -> s4
          jsb c13242
j13246:   load constant 2
          go to j13340
j13250:   load constant 1
          go to j13340
j13252:   load constant 4
          go to j13340
j13254:   1 -> s4
          jsb c13171
          go to j13337
j13257:   1 -> s4
          jsb c13171
          go to j13341
j13262:   1 -> s4
          jsb c13171
          go to j13342
j13265:   1 -> s4
          jsb c13171
          go to j13343
j13270:   a - 1 -> a[xs]
c13271:   a exchange c[w]
          c -> stack
          a exchange c[w]
          select rom 1   ; -> r11275
j13275:   load constant 5
          go to j13343
r13277:   c exchange m
          go to j13126
j13301:   1 -> s4
          jsb c13242
j13303:   load constant 2
          go to j13342
j13305:   load constant 4
          go to j13342
j13307:   load constant 4
          go to j13343
j13311:   if s5 # 1
               then go to j13323
          c - 1 -> c[xs]
          0 -> a[xs]
          0 -> s11
          0 -> f2
          if s11 # 1
               then go to j13323
          c - 1 -> c[s]
          0 -> a[s]
j13323:   a exchange c[w]
          b exchange c[w]
          clear status
          delayed select group 0
          select rom 1   ; -> r01330
j13330:   1 -> s4
          jsb c13242
          go to c13344
j13333:   c + 1 -> c[m]
j13334:   c + 1 -> c[m]
j13335:   c + 1 -> c[m]
j13336:   c + 1 -> c[m]
j13337:   c + 1 -> c[m]
j13340:   c + 1 -> c[m]
j13341:   c + 1 -> c[m]
j13342:   c + 1 -> c[m]
j13343:   c + 1 -> c[m]
c13344:   if s4 # 1
               then go to j13311
          0 -> s4
          a exchange c[w]
          shift left a[m]
          shift left a[m]
          shift left a[m]
          7 -> p
          load constant 0
          load constant 0
          a exchange c[w]
          4 -> p
          return
j13361:   load constant 7
          go to j13343
c13363:   load constant 3
          go to j13340
j13365:   stack -> a
          a + 1 -> a[xs]
          if a[x] >= 1
               then go to j13270
          0 -> a[w]
          jsb c13271
j13373:   1 -> s4
          jsb c13171
          go to j13334
j13376:   load constant 4
          go to j13341

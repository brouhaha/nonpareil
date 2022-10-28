; 1820-2105, 1MA4-0001 CPU ROM disassembly - quad 0 (@0000-@1777)
; used in 31E, 33E, 33C
; Copyright 2022 Eric Smith <spacewar@gmail.com>

	.arch woodstock

; externals:
S02461	.equ @02461
L03000	.equ @03000
L03001	.equ @03001
L03002	.equ @03002

	.bank 0
	.org @0000

         delayed rom @06
         go to L03002

S00002:  rom checksum		; computes checksum of quad 0 (@0000-@1777) and returns

L00003:  jsb S00006
         c -> data
         return

S00006:  if c[m] # 0
           then go to S00011
         0 -> c[w]
S00011:  decimal
         p <- 12
         if c[xs] = 0
           then go to L00022
         c - 1 -> c[x]
         c + 1 -> c[xs]
         c - 1 -> c[xs]
         if n/c go to L00023
         c + 1 -> c[x]
L00022:  return

L00023:  c + c -> c[xs]
         if n/c go to L00027
         0 -> c[w]
         go to L00033

L00027:  0 -> c[wp]
         c - 1 -> c[wp]
         0 -> c[xs]
         1 -> s 11
L00033:  p <- 13
         return

L00035:  0 -> a[w]
         p <- 12
         a + 1 -> a[p]
         if c[m] = 0
           then go to L00401
         jsb S00145
         go to L00050

L00044:  y -> a			; percent
         a - 1 -> a[x]
         a - 1 -> a[x]
         jsb S00053
L00050:  delayed rom @06
         go to L03000

S00052:  stack -> a
S00053:  jsb S00132
S00054:  0 -> b[w]
         a exchange b[m]
S00056:  jsb S00072
         jsb S00127
S00060:  p <- 12
         0 -> b[w]
         a -> b[x]
         a + b -> a[wp]
         if n/c go to L00067
         c + 1 -> c[x]
         a + 1 -> a[p]
L00067:  a exchange c[m]
         c -> a[w]
         return

S00072:  a + c -> c[x]
         p <- 3
         a - c -> c[s]
         if n/c go to L00077
         0 - c -> c[s]
L00077:  0 -> a[w]
         go to S00104

S00101:  p <- 0
         go to L00077

L00103:  a + b -> a[w]
S00104:  c - 1 -> c[p]
         if n/c go to L00103
         if p = 12
           then go to L00115
         p + 1 -> p
         shift right a[w]
         go to S00104

L00113:  c + 1 -> c[x]
         shift right a[w]
L00115:  return

S00116:  a exchange b[w]
S00117:  jsb S00101
         m1 -> c
         go to S00127

S00122:  m1 exchange c
         b -> c[w]
         jsb S00101
         m1 -> c
         c + c -> c[x]
S00127:  if a[s] # 0
           then go to L00113
         return

S00132:  m2 exchange c
         m2 -> c
         return

S00135:  c -> a[w]
         go to S00053

S00137:  if c[m] = 0
           then go to L00401
         go to L00146

S00142:  if c[m] = 0
           then go to L00401
         stack -> a
S00145:  jsb S00132
L00146:  jsb S00150
         go to S00060

S00150:  0 -> b[w]
         b exchange c[m]
S00152:  a - c -> c[s]
         if n/c go to L00155
         0 - c -> c[s]
L00155:  a - c -> c[x]
         0 -> a[x]
         0 -> a[s]
S00160:  0 -> c[m]
         p <- 12
         if a >= b[w]
           then go to L00170
         c - 1 -> c[x]
         shift left a[w]
         go to L00170

L00167:  c + 1 -> c[p]
L00170:  a - b -> a[w]
         if n/c go to L00167
         a + b -> a[w]
         p - 1 -> p
         if p # 2
           then go to L00205
         a + 1 -> a[ms]
         b exchange c[x]
         0 -> c[x]
         go to L00203

L00202:  a - 1 -> a[ms]
L00203:  if a >= b[w]
           then go to L00202
L00205:  shift left a[w]
         if p # 13
           then go to L00170
         0 -> a[w]
         a exchange c[w]
         a exchange c[s]
         b exchange c[x]
         go to S00274

S00215:  0 -> a[w]
         a + 1 -> a[s]
         0 - c -> c[x]
         shift right a[w]
         go to S00160

S00222:  stack -> a
         go to S00230

L00224:  a exchange c[w]
S00225:  if 0 = s 13
           then go to S00230
L00227:  0 - c - 1 -> c[s]
S00230:  jsb S00232
         go to S00060

S00232:  p <- 12
         0 -> b[w]
         a + 1 -> a[xs]
         a + 1 -> a[xs]
         c + 1 -> c[xs]
         c + 1 -> c[xs]
         if a >= c[x]
           then go to L00243
         a exchange c[w]
L00243:  a exchange c[m]
         if c[m] = 0
           then go to L00247
         a exchange c[w]
L00247:  b exchange c[m]
L00250:  if a >= c[x]
           then go to L00257
         shift right b[w]
         a + 1 -> a[x]
         if b[w] = 0
           then go to L00257
         go to L00250

L00257:  c - 1 -> c[xs]
         c - 1 -> c[xs]
         0 -> a[x]
         a - c -> a[s]
         if a[s] # 0
           then go to L00267
         a + b -> a[w]
         if n/c go to S00127
L00267:  if a >= b[m]
           then go to L00273
         0 - c - 1 -> c[s]
         a exchange b[w]
L00273:  a - b -> a[w]
S00274:  p <- 12
         if a[wp] # 0
           then go to L00305
         0 -> c[x]
L00300:  return

L00301:  binary
         a + 1 -> a[s]
         decimal
         c - 1 -> c[x]
L00305:  if a[p] # 0
           then go to L00300
         shift left a[wp]
         go to L00301

S00311:  if 0 = s 4
           then go to L00314
         0 - c - 1 -> c[s]
L00314:  jsb S00274
         go to S00060

S00316:  if c[s] # 0
           then go to L00401
         jsb S00132
S00321:  0 -> a[w]
         a exchange c[m]
         jsb S00325
         go to L00314

S00325:  a -> b[w]
         b exchange c[w]
         c + c -> c[w]
         c + c -> c[w]
         a + c -> c[w]
         b exchange c[w]
         0 -> c[ms]
         c -> a[w]
         c + c -> c[x]
         if n/c go to L00340
         c - 1 -> c[m]
L00340:  c + c -> c[x]
         a + c -> c[x]
         p <- 0
         if c[p] # 0
           then go to L00346
         shift right b[w]
L00346:  shift right c[w]
         a exchange c[x]
         0 -> c[w]
         a exchange b[w]
         p <- 13
         load constant 5
         shift right c[w]
         go to L00364

L00356:  c + 1 -> c[p]
L00357:  a - c -> a[w]
         if n/c go to L00356
         a + c -> a[w]
         shift left a[w]
         p - 1 -> p
L00364:  shift right c[wp]
         if p # 0
           then go to L00357
         0 -> c[p]
         a exchange c[w]
         b exchange c[w]
         return

L00373:  jsb S00116
         jsb S00060
         go to L00050

L00376:  a exchange b[w]
         stack -> a
         go to L00527

L00401:  delayed rom @06
         go to L03001

S00403:  0 -> c[w]
         c - 1 -> c[w]
         0 -> c[s]
         if p = 12
           then go to L00424
         if p = 11
           then go to L01317
         if p = 10
           then go to L01327
         if p = 9
           then go to L01335
         if p = 8
           then go to L01341
         p <- 0
L00421:  load constant 7
         p <- 7
         return

L00424:  p <- 10
         load constant 6
         load constant 6
         load constant 8
         load constant 6
         load constant 5
         load constant 2
         load constant 4
         load constant 9
         load constant 1
         load constant 1
         load constant 6
L00440:  p <- 12
         return

S00442:  0 -> c[w]
         p <- 12
         load constant 4
         load constant 5
         go to L00440

L00447:  0 -> a[w]
         delayed rom @00
         jsb S00132
         a exchange c[m]
L00453:  b exchange c[w]
         jsb S00757
         b exchange c[w]
         1 -> s 8
         jsb S00553
         b exchange c[w]
L00461:  jsb S00642
         b exchange c[w]
         jsb S00541
         if p # 5
           then go to L00461
         p <- 13
         load constant 7
         a exchange c[s]
         b exchange c[w]
         go to L00476

L00473:  a -> b[w]
         c - 1 -> c[s]
         if n/c go to L00512
L00476:  shift right a[wp]
         a exchange c[w]
         shift left a[ms]
         a exchange c[w]
         a - 1 -> a[s]
         if n/c go to L00473
         a exchange b[w]
         a + 1 -> a[p]
         delayed rom @00
         jsb S00311
         go to L00577

L00511:  shift right a[wp]
L00512:  a - 1 -> a[s]
         if n/c go to L00511
         0 -> a[s]
         a + b -> a[w]
         a + 1 -> a[p]
         if n/c go to L00473
         shift right a[wp]
         a + 1 -> a[p]
         if n/c go to L00476
L00523:  a exchange c[w]
         jsb S00757
         b exchange c[w]
         0 -> c[w]
L00527:  a exchange c[w]
         delayed rom @00
         jsb S00132
         delayed rom @00
         jsb S00072
         0 -> c[m]
         go to L00453

L00536:  binary
         c + 1 -> c[s]
         decimal
S00541:  a - b -> a[w]
         if n/c go to L00536
         a + b -> a[w]
         shift left a[w]
         shift right c[ms]
         b exchange c[w]
         p - 1 -> p
         return

L00551:  c + 1 -> c[x]
         shift right a[w]
S00553:  if c[xs] = 0
           then go to L00614
         if a[s] # 0
           then go to L00551
         0 - c -> c[x]
         if c[xs] = 0
           then go to L00602
         0 -> c[m]
         0 -> a[w]
         c + c -> c[x]
         if n/c go to L00604
L00566:  0 -> c[wp]
         if c[s] # 0
           then go to L00576
         c - 1 -> c[w]
         0 -> c[xs]
         1 -> s 11
         if s 4 = 1
           then go to L00577
L00576:  0 -> c[s]
L00577:  delayed rom @06
         go to L03000

L00601:  shift right a[w]
L00602:  c - 1 -> c[x]
         if n/c go to L00601
L00604:  0 -> c[x]
L00605:  if c[s] = 0
           then go to L00612
         a exchange b[w]
         a - b -> a[w]
         0 - c - 1 -> c[x]
L00612:  0 -> c[ms]
         return

L00614:  a exchange c[w]
         shift left a[wp]
         shift left a[wp]
         shift left a[wp]
         a exchange c[w]
         go to L00623

L00622:  c + 1 -> c[x]
L00623:  a - b -> a[w]
         if n/c go to L00622
         a + b -> a[w]
         c - 1 -> c[m]
         if n/c go to L00631
         go to L00605

L00631:  a exchange c[w]
         shift left a[x]
         a exchange c[w]
         shift left a[w]
         if 0 = s 8
           then go to L00623
         if c[xs] # 0
           then go to L00566
         go to L00623

S00642:  0 -> c[w]
         if p = 12
           then go to L00741
         c - 1 -> c[w]
         load constant 4
         c + 1 -> c[w]
         0 -> c[s]
         shift right c[w]
         if p = 10
           then go to L00724
         if p = 9
           then go to L00666
         if p = 8
           then go to L00700
         if p = 7
           then go to L00710
         if p = 6
           then go to L00715
         p + 1 -> p
         return

L00666:  p <- 7
         jsb S00721
         load constant 0
         load constant 8
         load constant 5
         load constant 3
         load constant 1
         load constant 7
         p <- 10
         return

L00700:  p <- 5
         jsb S00721
         load constant 3
         load constant 0
         load constant 8
         load constant 4
         p <- 9
         return

L00710:  p <- 3
         jsb S00721
         jsb S00721
         p <- 8
         return

L00715:  p <- 1
         jsb S00721
         p <- 7
         return

S00721:  load constant 3
         load constant 3
         return

L00724:  p <- 9
         load constant 3
         load constant 1
         load constant 0
         load constant 1
         load constant 7
         load constant 9
         load constant 8
         load constant 0
         load constant 4
         load constant 3
         p <- 11
         return

L00741:  p <- 11
         load constant 6
         load constant 9
         load constant 3
         load constant 1
         load constant 4
         load constant 7
         load constant 1
         load constant 8
         load constant 0
         load constant 5
         load constant 6
         p <- 12
         return

S00757:  0 -> c[w]
         p <- 12
         load constant 2
         load constant 3
         load constant 0
         load constant 2
         load constant 5
         load constant 8
         load constant 5
         load constant 0
         load constant 9
         load constant 2
         load constant 9
         load constant 9
         load constant 4
         p <- 12
         return

L01000:  p <- 12
         if c[w] = 0
           then go to L01127
         if c[s] # 0
           then go to L01147
         delayed rom @00
         jsb S00132
L01007:  if c[x] = 0
           then go to L01205
         c + 1 -> c[x]
         0 -> a[w]
         a - c -> a[m]
         if c[x] = 0
           then go to L01226
L01016:  shift right a[wp]
         a -> b[s]
         p <- 13
L01021:  p - 1 -> p
         a - 1 -> a[s]
         if n/c go to L01021
         a exchange b[s]
         0 -> c[ms]
         go to L01032

L01027:  shift right a[w]
         c + 1 -> c[p]
L01031:  a exchange b[s]
L01032:  a -> b[w]
         binary
         a + c -> a[s]
         m1 exchange c
         a exchange c[s]
         shift left a[w]
L01040:  shift right a[w]
         c - 1 -> c[s]
         if n/c go to L01040
         decimal
         m1 exchange c
         a + b -> a[w]
         shift left a[w]
         a - 1 -> a[s]
         if n/c go to L01027
         c -> a[s]
         a - 1 -> a[s]
         a + c -> a[s]
         if n/c go to L01060
L01055:  a exchange b[w]
         shift left a[w]
         go to L01072

L01060:  if p = 1
           then go to L01055
         c + 1 -> c[s]
         p - 1 -> p
         a exchange b[w]
         a exchange b[s]
         shift left a[w]
         go to L01031

L01070:  c - 1 -> c[s]
         p + 1 -> p
L01072:  b exchange c[w]
         delayed rom @01
         jsb S00642
         shift right a[w]
         b exchange c[w]
         go to L01101

L01100:  a + b -> a[w]
L01101:  c - 1 -> c[p]
         if n/c go to L01100
         if c[s] # 0
           then go to L01070
         if p = 12
           then go to L01232
         0 -> c[w]
         jsb S01306
L01111:  delayed rom @00
         jsb S00274
         0 -> a[s]
         if 0 = s 7
           then go to L01117
         0 - c - 1 -> c[s]
L01117:  if s 10 = 1
           then go to L00376
         if s 6 = 1
           then go to L01277
L01123:  delayed rom @00
         jsb S00060
L01125:  delayed rom @06
         go to L03000

L01127:  if 0 = s 10
           then go to L00401
         stack -> a
         if a[m] # 0
           then go to L01140
L01134:  c -> stack
         a exchange c[w]
         delayed rom @01
         go to L00401

L01140:  if a[s] # 0
           then go to L01134
         a exchange c[w]
         delayed rom @00
         jsb S00132
         0 -> c[w]
         go to L01125

L01147:  if 0 = s 10
           then go to L00401
         stack -> a
         a -> b[w]
         if a[xs] # 0
           then go to L01134
         a + 1 -> a[x]
L01156:  a - 1 -> a[x]
         shift left a[ms]
         if a[m] # 0
           then go to L01201
         if a[x] # 0
           then go to L01174
         a exchange c[s]
         c -> a[s]
         c + c -> c[s]
         c + c -> c[s]
         a + c -> c[s]
         if c[s] = 0
           then go to L01175
         1 -> s 4
L01174:  0 -> c[s]
L01175:  b exchange c[w]
         c -> stack
         b exchange c[w]
         go to L01007

L01201:  if a[x] # 0
           then go to L01156
         a exchange b[w]
         go to L01134

L01205:  c -> a[w]
         a - 1 -> a[p]
         if a[m] # 0
           then go to L01213
         0 -> c[w]
         go to L01117

L01213:  delayed rom @00
         jsb S00274
         0 -> c[x]
         delayed rom @00
         jsb S00150
         if c[x] # 0
           then go to L01223
         c - 1 -> c[s]
L01223:  a exchange c[s]
L01224:  0 -> c[x]
         go to L01016

L01226:  1 -> s 7
         delayed rom @00
         jsb S00274
         go to L01224

L01232:  if c[x] = 0
           then go to L01111
         c - 1 -> c[w]
         b exchange c[w]
         0 -> b[m]
         delayed rom @01
         jsb S00757
         a exchange c[w]
         a - c -> c[w]
         if b[xs] = 0
           then go to L01246
         a - c -> c[w]
L01246:  a exchange c[w]
         b exchange c[w]
         if c[xs] = 0
           then go to L01253
         0 - c - 1 -> c[w]
L01253:  a exchange c[wp]
L01254:  p - 1 -> p
         shift left a[w]
         if p # 1
           then go to L01254
         p <- 12
         if a[p] # 0
           then go to L01274
         shift left a[m]
L01264:  a exchange c[w]
         a exchange c[s]
         delayed rom @00
         jsb S00104
         delayed rom @00
         jsb S00127
         0 -> c[m]
         go to L01117

L01274:  a + 1 -> a[x]
         p - 1 -> p
         go to L01264

L01277:  b exchange c[w]
         delayed rom @01
         jsb S00757
         b exchange c[w]
         delayed rom @00
         jsb S00160
         go to L01123

S01306:  p + 1 -> p
S01307:  c - 1 -> c[x]
         if p # 12
           then go to S01306
         return

S01313:  load constant 6
         if p = 0
           then go to L00421
         go to S01313

L01317:  p <- 8
         jsb S01313
         p <- 0
         load constant 5
         p <- 4
         load constant 8
         p <- 11
         return

L01327:  p <- 6
         jsb S01313
         p <- 0
         load constant 9
         p <- 10
         return

L01335:  p <- 4
         jsb S01313
         p <- 9
         return

L01341:  p <- 2
         jsb S01313
         p <- 8
         return

L01345:  c + 1 -> c[x]
         c + 1 -> c[x]
         delayed rom @00
         jsb S00160
         m1 exchange c
         delayed rom @01
         jsb S00442
L01354:  delayed rom @00
         go to L00373

L01356:  a exchange c[w]
         delayed rom @01
         jsb S00442
         c + 1 -> c[x]
         c + 1 -> c[x]
         delayed rom @00
         jsb S00150
         m1 exchange c
         delayed rom @03
         jsb S01756
         go to L01354

L01371:  y -> a
         m2 exchange c
         m2 -> c
         if c[m] = 0
           then go to L01500
         if c[s] = 0
           then go to L01403
         1 -> s 7
         1 -> s 10
         0 -> c[s]
L01403:  delayed rom @00
         jsb S00150
L01405:  delayed rom @00
         jsb S00011
         0 -> s 11
         if p # 13
           then go to L01504
         if c[w] # 0
           then go to L01420
         stack -> a
         m2 -> c
         c -> stack
         0 -> c[w]
L01420:  0 -> a[w]
         0 -> b[w]
         c -> a[m]
L01423:  if c[s] = 0
           then go to L01435
         1 -> s 4
         if 0 = s 13
           then go to L01435
         if 0 = s 10
           then go to L01435
         0 -> s 10
         1 -> s 7
         0 -> s 4
L01435:  p <- 12
         if c[xs] = 0
           then go to L01626
         jsb S01526
         if 0 = s 6
           then go to L01637
         jsb S01752
         0 -> c[w]
         a -> b[w]
         b exchange c[w]
         shift right a[w]
         a + 1 -> a[p]
         0 - c -> c[wp]
         if n/c go to L01466
         a exchange b[w]
         a exchange c[w]
         delayed rom @00
         jsb S00274
         m1 exchange c
         a exchange c[w]
         delayed rom @00
         jsb S00117
         c - 1 -> c[x]
         delayed rom @00
         jsb S00325
L01466:  b exchange c[w]
         a exchange b[w]
         m2 -> c
         a exchange c[w]
         delayed rom @00
         jsb S00152
         if c[xs] # 0
           then go to L01637
         a exchange b[w]
         go to L01634

L01500:  c + 1 -> c[xs]
         a exchange c[s]
         if a[w] # 0
           then go to L01405
L01504:  a exchange b[w]
         stack -> a
         b exchange c[w]
         c -> stack
         b exchange c[w]
         delayed rom @00
         jsb S00122
         delayed rom @05
         jsb S02461
         a exchange b[w]
         a exchange c[w]
         m2 -> c
         delayed rom @00
         jsb S00056
         stack -> a
         c -> stack
         m1 -> c
         go to L01423

S01526:  if s 13 = 1
           then go to S00132
         return

L01531:  a -> b[w]
         if b[w] = 0
           then go to L01546
         a - 1 -> a[p]
         if a[w] # 0
           then go to L01631
         a exchange c[w]
         if 0 = s 6
           then go to L01545
         jsb S01743
         0 -> c[w]
         go to L01546

L01545:  jsb S01756
L01546:  a exchange c[w]
         jsb S01526
         0 -> c[w]
L01551:  delayed rom @02
         jsb S01307
L01553:  b exchange c[w]
         jsb S01756
         c + c -> c[w]
         shift right c[w]
         b exchange c[w]
         if 0 = s 10
           then go to L01574
         jsb S01753
         b exchange c[w]
         a exchange c[w]
         a - c -> c[w]
         a exchange c[w]
         b exchange c[w]
         0 -> c[w]
         delayed rom @00
         jsb S00274
         0 -> a[s]
L01574:  if 0 = s 7
           then go to L01600
         jsb S01753
         a + b -> a[w]
L01600:  0 -> c[s]
         if s 12 = 1
           then go to L01614
         c + 1 -> c[x]
         c + 1 -> c[x]
         delayed rom @00
         jsb S00160
         if s 14 = 1
           then go to L01614
         a -> b[w]
         shift right b[w]
         a - b -> a[w]
L01614:  delayed rom @00
         jsb S00311
         if s 13 = 1
           then go to L01125
         stack -> a
         c -> stack
         0 -> a[s]
         a exchange c[w]
         delayed rom @06
         go to L03000

L01626:  if c[x] = 0
           then go to L01531
         a exchange b[w]
L01631:  if s 6 = 1
           then go to L00401
         jsb S01526
L01634:  delayed rom @00
         jsb S00215
         jsb S01743
L01637:  p <- 12
         m1 exchange c
         m1 -> c
         0 -> c[ms]
L01643:  c + 1 -> c[x]
         if c[x] = 0
           then go to L01654
         c + 1 -> c[s]
         p - 1 -> p
         if p # 6
           then go to L01643
         m1 -> c
         go to L01553

L01654:  m1 exchange c
         0 -> c[w]
         c + 1 -> c[s]
         shift right c[w]
         go to L01675

L01661:  a exchange c[w]
         m1 exchange c
         c + 1 -> c[p]
         c -> a[s]
         m1 exchange c
L01666:  shift right b[w]
         shift right b[w]
         a - 1 -> a[s]
         if n/c go to L01666
         0 -> a[s]
         a + b -> a[w]
         a exchange c[w]
L01675:  a -> b[w]
         a - c -> a[w]
         if n/c go to L01661
         m1 exchange c
         c + 1 -> c[s]
         m1 exchange c
         a exchange b[w]
         shift left a[w]
         p - 1 -> p
         if p # 6
           then go to L01675
         b exchange c[w]
         m1 -> c
         delayed rom @00
         jsb S00160
         0 -> a[s]
         go to L01720

L01716:  c + 1 -> c[x]
         shift right a[wp]
L01720:  if c[x] # 0
           then go to L01716
         m1 exchange c
         0 -> c[x]
         p <- 7
L01725:  b exchange c[w]
         delayed rom @01
         jsb S00403
         b exchange c[w]
         go to L01733

L01732:  a + b -> a[w]
L01733:  c - 1 -> c[p]
         if n/c go to L01732
         shift right a[w]
         0 -> c[p]
         if c[m] = 0
           then go to L01551
         p + 1 -> p
         go to L01725

S01743:  if s 10 = 1
           then go to L01747
         1 -> s 10
         return

L01747:  0 -> s 10
         return

S01751:  shift right a[w]
S01752:  c + 1 -> c[x]
S01753:  if c[x] # 0
           then go to S01751
         return

S01756:  p <- 12
         0 -> c[w]
         load constant 7
         load constant 8
         load constant 5
         load constant 3
         load constant 9
         load constant 8
         load constant 1
         load constant 6
         load constant 3
         load constant 3
         load constant 9
         load constant 7
         load constant 5
         p <- 12
         return

	 .dw @1653			; CRC, quad 0 (@0000..@1777)

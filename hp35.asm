; HP-35 ROM code disassembled from dump by Peter Monta
; $Id$

	.rom @00

	jsb l00067
	go to l00277
	
l00002:	0 -> s8
	go to l00005
	
l00004:	1 -> s5
l00005:	1 -> s9
	1 -> s2
	select rom 2		; -> l02010
	
l00010:	jsb l00264
	go to l00376
	
l00012:	go to l00027
	
l00013:	go to l00060

	stack -> a
	go to l00331
	0 -> a[w]
	a + 1 -> a[p]
l00020:	0 -> b[w]
	select rom 1		; -> l01022
	
l00022:	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	go to l00032		; conditional
	
	jsb l00232
l00027:	c exchange m
	m -> c
	go to l00077

l00032:	a + 1 -> a[x]
	a + 1 -> a[x]
l00034:	a + 1 -> a[x]
	return

l00036:	3 -> p
	0 - c -> c[x]
l00040:	stack -> a
	go to l00020
	
l00042:	go to l00164
	
l00043:	3 -> p
	return
	
	no operation
	
L00046:	go to l00040

l00047:	1 -> s5
	1 -> s1
	go to l00056
	
l00052:	1 -> s9
	go to l00047
	
l00054:	1 -> s10
	go to l00302
	
l00056:	0 -> b[w]
	select rom 1		; -> l01060
	
l00060:	down rotate
	go to l00333

l00062:	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	go to l00022		; conditional
	go to l00231
	
l00067:	clear registers
	jsb l00134
l00071:	go to l00335

l00072:	go to l00362
	
l00073:	shift right a[w]
	1 -> s3
	go to l00166
	
l00076:	c -> stack
l00077:	clear status
	shift right a[w]
	jsb l00335
l00102:	a -> b[w]
	0 -> a[xs]
	shift left a[ms]
l00105:	a - 1 -> a[x]
	go to l00340		; conditioinal
	if c[xs] = 0
	     then go to l00346
	a exchange b[ms]
	13 -> p
	go to l00346
	
l00114:	p - 1 -> p
	c + 1 -> c[x]
l00116:	if b[p] = 0
	     then go to l00114
	1 -> s11
	shift right a[ms]
	a exchange c[m]
	if s4 = 0
	     then go to l00207
	jsb l00137
	go to l00335
	
l00127:	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	a + b -> a[x]
	go to l00135		; conditional???

l00134:	0 -> c[w]
l00135:	clear status
	c -> a[w]
l00137:	12 -> p
	a -> b[x]
	c -> a[x]
	if c[xs] = 0
	     then go to l00150
	0 - c -> c[x]
	c - 1 -> c[xs]
	go to l00127
	5 -> p
l00150:	a exchange c[x]
	if s4 = 0
	     then go to l00102
	a exchange b[x]
	0 -> b[x]
	jsb l00367
	shift left a[x]
l00157:	shift right a[w]
	if p # 12
	     then go to l00211
	a exchange c[wp]
	go to l00172
	
l00164:	jsb l00264
	select rom 1		; -> l01166
	
l00166:	if s4 = 0
	     then go to l00366
	a exchange c[wp]
	0 - c - 1 -> c[xs]
l00172:	c -> a[w]
	if c[xs] = 0
	     then go to l00177
	0 -> c[xs]
	0 - c -> c[x]
l00177:	13 -> p
l00200:	shift left a[ms]
	c - 1 -> c[x]
	if a[s] >= 1
	     then go to l00116
	if a[ms] >= 1
	     then go to l00200
	0 -> c[x]
l00207:	jsb l00367
	shift right a[ms]
l00211:	c -> a[s]
l00212:	if p # 12
	     then go to l00223
	b -> c[w]
	c + 1 -> c[w]
	1 -> p
l00217:	shift left a[wp]
	p + 1 -> p
	if c[p] = 0
	     then go to l00217
l00223:	a exchange c[w]
	if p # 3
	     then go to l00371
	0 -> c[x]
	1 -> s6
	go to l00172

l00231:	0 - c - 1 -> c[s]
l00232:	stack -> a
	0 -> b[w]
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a >= c[x]
	     then go to l00243
	a exchange c[w]
l00243:	a exchange c[m]
	if c[m] = 0
	     then go to l00247
	a exchange c[w]
l00247:	b exchange c[m]
l00250:	if a >= c[x]
	     then go to l00276
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	     then go to l00276
	go to l00250

l00257:	0 -> a[ms]
	if s3 = 0
	     then go to l00264
	a - 1 -> a[s]
	0 - c - 1 -> c[s]
l00264:	if s7 = 0
	     then go to l00267
	c -> stack
l00267:	1 -> s7
	0 -> c[w]
	c - 1 -> c[w]
	0 - c -> c[s]
	c + 1 -> c[s]
	b exchange c[w]
	return

l00276:	select rom 1		; -> l01277

l00277:	jsb l00134
	1 -> s5
	go to l00335

l00302:	shift right a[w]
l00303:	c -> a[s]
l00304:	0 -> s8
	go to l00317

l00306:	c + 1 -> c[xs]
l00307:	1 -> s8
	if s5 = 0
	     then go to l00315
	c + 1 -> c[x]
	go to l00306		; conditional
l00314:	display toggle
l00315:	if s0 = 0
	     then go to l00307
l00317:	0 -> s0
l00320:	p - 1 -> p
	if p # 12
	     then go to l00320
	display off
	if s8 = 0
	     then go to l00314
	shift left a[w]
	0 -> s5
	keys -> rom address

l00331:	c -> stack
	a exchange c[w]
l00333:	jsb l00135
	1 -> s7
l00335:	jsb l00367
	jsb l00257
	go to l00212

l00340:	shift right a[ms]
	p - 1 -> p
	if p # 2
	     then go to l00105
	12 -> p
	0 -> a[w]
l00346:	0 -> a[ms]
	a + 1 -> a[p]
	a + 1 -> a[p]
	2 -> p
l00352:	p + 1 -> p
	a - 1 -> a[p]
	go to l00357
	if b[p] = 0
	     then go to l00352
l00357:	a + 1 -> a[p]
	a exchange b[w]
	return

l00362:	1 -> s4
	if s11 = 0
	     then go to l00034
	go to l00157

l00366:	0 - c - 1 -> c[s]
l00367:	0 -> s10
	go to l00303

l00371:	if s6 = 0
	     then go to l00374
	p - 1 -> p
l00374:	shift right b[wp]
	jsb l00172
l00376:	m -> c
	go to l00333

	.rom @01

	go to l01363

l01001:	a exchange b[w]
	jsb l01050
	stack -> a
	jsb l01050
	stack -> a
	if s9 = 0
	     then go to l01011
	a exchange c[w]
l01011:	if s5 = 0
	     then go to l01022
	0 -> c[s]
	jsb l01246
l01015:	c -> stack
	jsb l01245
	jsb l01230
	jsb l01045
	stack -> a
l01022:	jsb l01246
	if s10 = 0
	     then go to l01332
l01025:	0 -> a[w]
	a + 1 -> a[p]
	a -> b[m]
	a exchange c[m]
l01031:	c - 1 -> c[x]
	shift right b[wp]
	if c[xs] = 0
	     then go to l01031
l01035:	shift right a[wp]
	c + 1 -> c[x]
	go to l01035
	shift right a[w]
	shift right b[w]
	c -> stack
l01043:	b exchange c[w]
	go to l01101
l01045:	b exchange c[w]
	4 -> p
	go to l01336

l01050:	c -> stack
	a exchange c[w]
	if c[p] = 0
	     then go to l01055
	0 - c -> c[w]
l01055:	c -> a[w]
	b -> c[x]
	go to l01313

	c -> a[w]
	if s1 = 0
	     then go to l01045
	if s10 = 0
	     then go to l01155
	if s5 = 0
	     then go to l01025
	0 - c - 1 -> c[s]
	a exchange c[s]
	go to l01015

l01072:	shift right b[wp]
l01073:	a - 1 -> a[s]
	go to l01072
	c + 1 -> c[s]
	a exchange b[wp]
	a + c -> c[wp]
	a exchange b[w]
l01101:	a -> b[w]
	a - c -> a[wp]
	go to l01073
	stack -> a
	shift right a[w]
	a exchange c[wp]
	a exchange b[w]
	shift left a[wp]
	c -> stack
	a + 1 -> a[s]
	a + 1 -> a[s]
	go to l01043
	0 -> c[w]
	0 -> b[x]
	shift right a[ms]
	jsb l01262
	c - 1 -> c[p]
	stack -> a
	a exchange c[w]
	4 -> p
	jsb l01244
	6 -> p
	jsb l01233
	8 -> p
	jsb l01233
	2 -> p
	load constant 8
	10 -> p
	jsb l01233
	jsb l01216
	jsb l01233
	jsb l01314
	shift left a[w]
	jsb l01233
	b -> c[w]
	jsb l01313
	jsb l01314
	c + c -> c[w]
	jsb l01246
	if s9 = 0
	     then go to l01154
	0 - c - 1 -> c[s]
	jsb l01230
l01154:	0 -> s1
l01155:	0 -> c[w]
	c - 1 -> c[p]
	c + 1 -> c[x]
	if s1 = 0
	     then go to l01245
	jsb l01246
	jsb l01314
	c + c -> c[w]
	jsb l01245
	jsb l01314
	c + c -> c[w]
	c + c -> c[w]
	jsb l01225
	c + c -> c[w]
	jsb l01353
	jsb l01314
	10 -> p
	jsb l01234
	jsb l01216
	8 -> p
	jsb l01235
	2 -> p
	load constant 8
	6 -> p
	jsb l01234
	4 -> p
	jsb l01234
	jsb l01234
	a exchange b[w]
	shift right c[w]
	13 -> p
	load constant 5
	go to l01373

l01216:	6 -> p
	load constant 8
	load constant 6
	load constant 5
	load constant 2
	load constant 4
	load constant 9
l01225:	if s1 = 0
	     then go to l01332
	return

l01230:	0 -> a[w]
	a + 1 -> a[p]
	select rom 0		; -> l00233

l01233:	select rom 2		; -> l02234

l01234:	shift left a[w]
l01235:	shift right b[ms]
	b exchange c[w]
	go to l01241

l01240:	c + 1 -> c[s]
l01241:	a - b -> a[w]
	go to l01240		; conditional
	a + b -> a[w]
l01244:	select rom 2		; -> l02245

l01245:	select rom 2		; -> l02246

l01246:	a - c -> c[x]
	select rom 2		; -> l02250

l01250:	c + 1 -> c[p]
l01251:	a - c -> a[w]
	go to l01250		; conditional
	a + c -> a[w]
	shift left a[w]
	p - 1 -> p
l01256:	shift right c[wp]
	if p # 0
	     then go to l01251
	go to l01055

l01262:	c + 1 -> c[p]
l01263:	a - b -> a[ms]
	go to l01262		; conditional
	a + b -> a[ms]
	shift left a[ms]
	p - 1 -> p
	if p # 0
	     then go to l01263
	go to l01055

l01273:	p - 1 -> p
	a + b -> a[ms]
	go to l01333		; conditional
	select rom 0		; -> l00277

	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] >= 1
	     then go to l01306
	select rom 2		; -> l02306

l01306:	if a >= b[m]
	     then go to l01312
	0 - c - 1 -> c[s]
	a exchange b[w]
l01312:	a - b -> a[w]
l01313:	select rom 2		; -> l02314

l01314:	0 -> c[w]
	11 -> p
	load constant 7		; load pi/4
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

l01332:	select rom 0		; -> l00333

l01333:	a + b -> a[x]
	go to l01336		; conditional
	c - 1 -> c[p]
l01336:	c + 1 -> c[s]
	if p # 0
	     then go to l01273
	a exchange c[x]
	0 -> a[x]
	if c[p] >= 1
	     then go to l01346
	shift right a[w]
l01346:	shift right c[w]
	b exchange c[x]
	0 -> c[x]
	12 -> p
	go to l01256

l01353:	select rom 2		; -> l02354

l01354:	shift right b[wp]
	shift right b[wp]
l01356:	c - 1 -> c[s]
	go to l01354		; conditional
	a + c -> c[wp]
	a - b -> a[wp]
	b exchange c[wp]
l01363:	b -> c[w]
	a - 1 -> a[s]
	go to l01356		; conditional
	a exchange c[wp]
	stack -> a
	if b[s] = 0
	     then go to l01001
	shift left a[w]
l01373:	a exchange c[wp]
	c -> stack
	shift right b[wp]
	c - 1 -> c[s]
	b exchange c[s]

	.rom @02

l02000:	select rom 0		; -> l00001

l02001:	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to l02022
l02006:	stack -> a
	jsb l02246
	c -> a[w]
	if s8 = 0
	     then go to l02102
	0 -> a[w]
	a - c -> a[m]
	go to l02000		; conditional
	shift right a[w]
	c - 1 -> c[s]
	go to l02000		; conditional
l02021:	c + 1 -> c[s]
l02022:	a -> b[w]
	jsb l02226
	a - 1 -> a[p]
	go to l02021		; conditional
	a exchange b[wp]
	a + b -> a[s]
	go to l02001		; conditional
	7 -> p
	jsb l02155
	8 -> p
	jsb l02235
	9 -> p
	jsb l02234
	jsb l02376
	10 -> p
	jsb l02234
	jsb l02175
	11 -> p
	jsb l02234
	jsb l02337
	jsb l02234
	jsb l02271
	jsb l02234
	jsb l02366
	a exchange c[w]
	a - c -> c[w]
	if b[xs] = 0
	     then go to l02057
	a - c -> c[w]
l02057:	a exchange b[w]
l02060:	p - 1 -> p
	shift left a[w]
	if p # 1
	     then go to l02060
	a exchange c[w]
	if c[s] = 0
	     then go to l02070
	0 - c - 1 -> c[m]
l02070:	c + 1 -> c[x]
	11 -> p
	jsb l02305
	if s9 = 0
	     then go to l02006
	if s5 = 0
	     then go to l02224
	jsb l02366
	jsb l02247
	go to l02224

l02102:	jsb l02366
	jsb l02354
	jsb l02271
	11 -> p
	jsb l02233
	jsb l02337
	10 -> p
	jsb l02233
	jsb l02175
	9 -> p
	jsb l02233
	jsb l02376
	8 -> p
	jsb l02233
	jsb l02233
	jsb l02233
	6 -> p
	0 -> a[wp]
	13 -> p
	b exchange c[w]
	a exchange c[w]
	load constant 6
	go to l02216

l02131:	if s2 = 0
	     then go to l02136
	a + 1 -> a[x]
l02134:	if a[xs] >= 1
	     then go to l02302
l02136:	a - b -> a[ms]
	go to l02131		; conditional
	a + b -> a[ms]
	shift left a[w]
	c - 1 -> c[x]
	go to l02134		; conditional
l02144:	shift right a[w]
	0 -> c[wp]
	a exchange c[x]
l02147:	if c[s] = 0
	     then go to l02154
	a exchange b[w]
	a - b -> a[w]
	0 - c - 1 -> c[w]
l02154:	shift right a[w]
l02155:	b exchange c[w]
	0 -> c[w]
	c - 1 -> c[m]
	if s2 = 0
	     then go to l02166
	load constant 4
	c + 1 -> c[m]
	go to l02171		; conditional
l02165:	load constant 6
l02166:	if p # 1
	     then go to l02165
	shift right c[w]
l02171:	shift right c[w]
l02172:	if s2 = 0
	     then go to l02224
	return

l02175:	7 -> p
l02176:	load constant 3
	load constant 3
	load constant 0
l02201:	load constant 8
	load constant 5
	load constant 0
	load constant 9
	go to l02352

l02206:	jsb l02226
	a + 1 -> a[p]
l02210:	a -> b[w]
	c - 1 -> c[s]
	go to l02206		; conditional
	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
l02216:	a exchange c[w]
	a - 1 -> a[s]
	go to l02210		; conditional
	a exchange b[w]
	a + 1 -> a[p]
	jsb l02314
l02224:	select rom 1		; -> l01225

l02225:	shift right a[wp]
l02226:	a - 1 -> a[s]
	go to l02225		; conditional
	0 -> a[s]
	a + b -> a[w]
	return

l02233:	select rom 1		; -> l01234

l02234:	shift right a[w]
l02235:	b exchange c[w]
	go to l02240

l02237:	a + b -> a[w]
l02240:	c - 1 -> c[s]
	go to l02237		; conditional
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	go to l02155

l02246:	3 -> p
l02247:	a + c -> c[x]
	a - c -> c[s]
	go to l02253		; conditional
	0 - c -> c[s]
l02253:	a exchange b[m]
	0 -> a[w]
	if p # 12
	     then go to l02305
	if c[m] >= 1
	     then go to l02266
	if s1 = 0
	     then go to l02000
	b -> c[wp]
	a - 1 -> a[m]
	c + 1 -> c[xs]
l02266:	b exchange c[wp]
	a exchange c[m]
	select rom 1		; -> l01271

l02271:	0 -> s8
	load constant 6
	load constant 9
	load constant 3
	load constant 1
	load constant 4
	load constant 7
	load constant 1
	go to l02346

l02302:	a + 1 -> a[m]
	go to l02144		; conditional
l02304:	a + b -> a[w]
l02305:	c - 1 -> c[p]
	go to l02304		; conditional
l02307:	shift right a[w]
	p + 1 -> p
	if p # 13
	     then go to l02305
	c + 1 -> c[x]
l02314:	0 -> a[s]
	12 -> p
	0 -> b[w]
l02317:	if a[p] >= 1
	     then go to l02326
	shift left a[w]
	c - 1 -> c[x]
	if a[w] >= 1
	     then go to l02317
	0 -> c[w]
l02326:	a -> b[x]
	a + b -> a[w]
	if a[s] >= 1
	     then go to l02307
	a exchange c[m]
	c -> a[w]
	0 -> b[w]
l02335:	12 -> p
	go to l02172

l02337:	9 -> p
	load constant 3
	load constant 1
	load constant 0
	load constant 1
	load constant 7
	load constant 9
l02346:	load constant 8
	load constant 0
	load constant 5
	load constant 5
l02352:	load constant 3
	go to l02335

l02354:	a exchange c[w]
	a -> b[w]
	c -> a[m]
	c + c -> c[xs]
	go to l02136		; conditional
	c + 1 -> c[xs]
l02362:	shift right a[w]
	c + 1 -> c[x]
	go to l02362		; conditional
	go to l02147

l02366:	0 -> c[w]
	12 -> p
	load constant 2
	load constant 3
	load constant 0
	load constant 2
	load constant 5
	go to l02201

l02376:	5 -> p
	go to l02176

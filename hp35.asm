	.rom @00
	jsb @067
	go to @277
	0 -> s8
	go to @005
	1 -> s5
	1 -> s9
	1 -> s2
	select rom 2
	jsb @264
	go to @376
	go to @027
	go to @060
	stack -> a
	go to @331
	0 -> a[w]
	a + 1 -> a[p]
	0 -> b[w]
	select rom 1
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	go to @032
	jsb @232
	c exchange m
	m -> c
	go to @077
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	return
	3 -> p
	0 - c -> c[x]
	stack -> a
	go to @020
	go to @164
	3 -> p
	return
	no operation
	go to @040
	1 -> s5
	1 -> s1
	go to @056
	1 -> s9
	go to @047
	1 -> s10
	go to @302
	0 -> b[w]
	select rom 1
	down rotate
	go to @333
	a + 1 -> a[x]
	a + 1 -> a[x]
	a + 1 -> a[x]
	go to @022
	go to @231
	clear registers
	jsb @134
	go to @335
	go to @362
	shift right a[w]
	1 -> s3
	go to @166
	c -> stack
	clear status
	shift right a[w]
	jsb @335
	a -> b[w]
	0 -> a[xs]
	shift left a[ms]
	a - 1 -> a[x]
	go to @340
	if c[xs] = 0
	go to @346
	a exchange b[ms]
	13 -> p
	go to @346
	p - 1 -> p
	c + 1 -> c[x]
	if b[p] = 0
	go to @114
	1 -> s11
	shift right a[ms]
	a exchange c[m]
	if s4 = 0
	go to @207
	jsb @137
	go to @335
	0 -> c[wp]
	c - 1 -> c[wp]
	0 -> c[xs]
	a + b -> a[x]
	go to @135
	0 -> c[w]
	clear status
	c -> a[w]
	12 -> p
	a -> b[x]
	c -> a[x]
	if c[xs] = 0
	go to @150
	0 - c -> c[x]
	c - 1 -> c[xs]
	go to @127
	5 -> p
	a exchange c[x]
	if s4 = 0
	go to @102
	a exchange b[x]
	0 -> b[x]
	jsb @367
	shift left a[x]
	shift right a[w]
	if p # 12
	go to @211
	a exchange c[wp]
	go to @172
	jsb @264
	select rom 1
	if s4 = 0
	go to @366
	a exchange c[wp]
	0 - c - 1 -> c[xs]
	c -> a[w]
	if c[xs] = 0
	go to @177
	0 -> c[xs]
	0 - c -> c[x]
	13 -> p
	shift left a[ms]
	c - 1 -> c[x]
	if a[s] >= 1
	go to @116
	if a[ms] >= 1
	go to @200
	0 -> c[x]
	jsb @367
	shift right a[ms]
	c -> a[s]
	if p # 12
	go to @223
	b -> c[w]
	c + 1 -> c[w]
	1 -> p
	shift left a[wp]
	p + 1 -> p
	if c[p] = 0
	go to @217
	a exchange c[w]
	if p # 3
	go to @371
	0 -> c[x]
	1 -> s6
	go to @172
	0 - c - 1 -> c[s]
	stack -> a
	0 -> b[w]
	a + 1 -> a[xs]
	a + 1 -> a[xs]
	c + 1 -> c[xs]
	c + 1 -> c[xs]
	if a >= c[x]
	go to @243
	a exchange c[w]
	a exchange c[m]
	if c[m] = 0
	go to @247
	a exchange c[w]
	b exchange c[m]
	if a >= c[x]
	go to @276
	shift right b[w]
	a + 1 -> a[x]
	if b[w] = 0
	go to @276
	go to @250
	0 -> a[ms]
	if s3 = 0
	go to @264
	a - 1 -> a[s]
	0 - c - 1 -> c[s]
	if s7 = 0
	go to @267
	c -> stack
	1 -> s7
	0 -> c[w]
	c - 1 -> c[w]
	0 - c -> c[s]
	c + 1 -> c[s]
	b exchange c[w]
	return
	select rom 1
	jsb @134
	1 -> s5
	go to @335
	shift right a[w]
	c -> a[s]
	0 -> s8
	go to @317
	c + 1 -> c[xs]
	1 -> s8
	if s5 = 0
	go to @315
	c + 1 -> c[x]
	go to @306
	display toggle
	if s0 = 0
	go to @307
	0 -> s0
	p - 1 -> p
	if p # 12
	go to @320
	display off
	if s8 = 0
	go to @314
	shift left a[w]
	0 -> s5
	keys -> rom address
	c -> stack
	a exchange c[w]
	jsb @135
	1 -> s7
	jsb @367
	jsb @257
	go to @212
	shift right a[ms]
	p - 1 -> p
	if p # 2
	go to @105
	12 -> p
	0 -> a[w]
	0 -> a[ms]
	a + 1 -> a[p]
	a + 1 -> a[p]
	2 -> p
	p + 1 -> p
	a - 1 -> a[p]
	go to @357
	if b[p] = 0
	go to @352
	a + 1 -> a[p]
	a exchange b[w]
	return
	1 -> s4
	if s11 = 0
	go to @034
	go to @157
	0 - c - 1 -> c[s]
	0 -> s10
	go to @303
	if s6 = 0
	go to @374
	p - 1 -> p
	shift right b[wp]
	jsb @172
	m -> c
	go to @333
	.rom @01
	go to @363
	a exchange b[w]
	jsb @050
	stack -> a
	jsb @050
	stack -> a
	if s9 = 0
	go to @011
	a exchange c[w]
	if s5 = 0
	go to @022
	0 -> c[s]
	jsb @246
	c -> stack
	jsb @245
	jsb @230
	jsb @045
	stack -> a
	jsb @246
	if s10 = 0
	go to @332
	0 -> a[w]
	a + 1 -> a[p]
	a -> b[m]
	a exchange c[m]
	c - 1 -> c[x]
	shift right b[wp]
	if c[xs] = 0
	go to @031
	shift right a[wp]
	c + 1 -> c[x]
	go to @035
	shift right a[w]
	shift right b[w]
	c -> stack
	b exchange c[w]
	go to @101
	b exchange c[w]
	4 -> p
	go to @336
	c -> stack
	a exchange c[w]
	if c[p] = 0
	go to @055
	0 - c -> c[w]
	c -> a[w]
	b -> c[x]
	go to @313
	c -> a[w]
	if s1 = 0
	go to @045
	if s10 = 0
	go to @155
	if s5 = 0
	go to @025
	0 - c - 1 -> c[s]
	a exchange c[s]
	go to @015
	shift right b[wp]
	a - 1 -> a[s]
	go to @072
	c + 1 -> c[s]
	a exchange b[wp]
	a + c -> c[wp]
	a exchange b[w]
	a -> b[w]
	a - c -> a[wp]
	go to @073
	stack -> a
	shift right a[w]
	a exchange c[wp]
	a exchange b[w]
	shift left a[wp]
	c -> stack
	a + 1 -> a[s]
	a + 1 -> a[s]
	go to @043
	0 -> c[w]
	0 -> b[x]
	shift right a[ms]
	jsb @262
	c - 1 -> c[p]
	stack -> a
	a exchange c[w]
	4 -> p
	jsb @244
	6 -> p
	jsb @233
	8 -> p
	jsb @233
	2 -> p
	load constant 8
	10 -> p
	jsb @233
	jsb @216
	jsb @233
	jsb @314
	shift left a[w]
	jsb @233
	b -> c[w]
	jsb @313
	jsb @314
	c + c -> c[w]
	jsb @246
	if s9 = 0
	go to @154
	0 - c - 1 -> c[s]
	jsb @230
	0 -> s1
	0 -> c[w]
	c - 1 -> c[p]
	c + 1 -> c[x]
	if s1 = 0
	go to @245
	jsb @246
	jsb @314
	c + c -> c[w]
	jsb @245
	jsb @314
	c + c -> c[w]
	c + c -> c[w]
	jsb @225
	c + c -> c[w]
	jsb @353
	jsb @314
	10 -> p
	jsb @234
	jsb @216
	8 -> p
	jsb @235
	2 -> p
	load constant 8
	6 -> p
	jsb @234
	4 -> p
	jsb @234
	jsb @234
	a exchange b[w]
	shift right c[w]
	13 -> p
	load constant 5
	go to @373
	6 -> p
	load constant 8
	load constant 6
	load constant 5
	load constant 2
	load constant 4
	load constant 9
	if s1 = 0
	go to @332
	return
	0 -> a[w]
	a + 1 -> a[p]
	select rom 0
	select rom 2
	shift left a[w]
	shift right b[ms]
	b exchange c[w]
	go to @241
	c + 1 -> c[s]
	a - b -> a[w]
	go to @240
	a + b -> a[w]
	select rom 2
	select rom 2
	a - c -> c[x]
	select rom 2
	c + 1 -> c[p]
	a - c -> a[w]
	go to @250
	a + c -> a[w]
	shift left a[w]
	p - 1 -> p
	shift right c[wp]
	if p # 0
	go to @251
	go to @055
	c + 1 -> c[p]
	a - b -> a[ms]
	go to @262
	a + b -> a[ms]
	shift left a[ms]
	p - 1 -> p
	if p # 0
	go to @263
	go to @055
	p - 1 -> p
	a + b -> a[ms]
	go to @333
	select rom 0
	c - 1 -> c[xs]
	c - 1 -> c[xs]
	0 -> a[x]
	a - c -> a[s]
	if a[s] >= 1
	go to @306
	select rom 2
	if a >= b[m]
	go to @312
	0 - c - 1 -> c[s]
	a exchange b[w]
	a - b -> a[w]
	select rom 2
	0 -> c[w]
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
	select rom 0
	a + b -> a[x]
	go to @336
	c - 1 -> c[p]
	c + 1 -> c[s]
	if p # 0
	go to @273
	a exchange c[x]
	0 -> a[x]
	if c[p] >= 1
	go to @346
	shift right a[w]
	shift right c[w]
	b exchange c[x]
	0 -> c[x]
	12 -> p
	go to @256
	select rom 2
	shift right b[wp]
	shift right b[wp]
	c - 1 -> c[s]
	go to @354
	a + c -> c[wp]
	a - b -> a[wp]
	b exchange c[wp]
	b -> c[w]
	a - 1 -> a[s]
	go to @356
	a exchange c[wp]
	stack -> a
	if b[s] = 0
	go to @001
	shift left a[w]
	a exchange c[wp]
	c -> stack
	shift right b[wp]
	c - 1 -> c[s]
	b exchange c[s]
	.rom @02
	select rom 0
	a exchange b[s]
	a + 1 -> a[s]
	shift right c[ms]
	shift left a[wp]
	go to @022
	stack -> a
	jsb @246
	c -> a[w]
	if s8 = 0
	go to @102
	0 -> a[w]
	a - c -> a[m]
	go to @000
	shift right a[w]
	c - 1 -> c[s]
	go to @000
	c + 1 -> c[s]
	a -> b[w]
	jsb @226
	a - 1 -> a[p]
	go to @021
	a exchange b[wp]
	a + b -> a[s]
	go to @001
	7 -> p
	jsb @155
	8 -> p
	jsb @235
	9 -> p
	jsb @234
	jsb @376
	10 -> p
	jsb @234
	jsb @175
	11 -> p
	jsb @234
	jsb @337
	jsb @234
	jsb @271
	jsb @234
	jsb @366
	a exchange c[w]
	a - c -> c[w]
	if b[xs] = 0
	go to @057
	a - c -> c[w]
	a exchange b[w]
	p - 1 -> p
	shift left a[w]
	if p # 1
	go to @060
	a exchange c[w]
	if c[s] = 0
	go to @070
	0 - c - 1 -> c[m]
	c + 1 -> c[x]
	11 -> p
	jsb @305
	if s9 = 0
	go to @006
	if s5 = 0
	go to @224
	jsb @366
	jsb @247
	go to @224
	jsb @366
	jsb @354
	jsb @271
	11 -> p
	jsb @233
	jsb @337
	10 -> p
	jsb @233
	jsb @175
	9 -> p
	jsb @233
	jsb @376
	8 -> p
	jsb @233
	jsb @233
	jsb @233
	6 -> p
	0 -> a[wp]
	13 -> p
	b exchange c[w]
	a exchange c[w]
	load constant 6
	go to @216
	if s2 = 0
	go to @136
	a + 1 -> a[x]
	if a[xs] >= 1
	go to @302
	a - b -> a[ms]
	go to @131
	a + b -> a[ms]
	shift left a[w]
	c - 1 -> c[x]
	go to @134
	shift right a[w]
	0 -> c[wp]
	a exchange c[x]
	if c[s] = 0
	go to @154
	a exchange b[w]
	a - b -> a[w]
	0 - c - 1 -> c[w]
	shift right a[w]
	b exchange c[w]
	0 -> c[w]
	c - 1 -> c[m]
	if s2 = 0
	go to @166
	load constant 4
	c + 1 -> c[m]
	go to @171
	load constant 6
	if p # 1
	go to @165
	shift right c[w]
	shift right c[w]
	if s2 = 0
	go to @224
	return
	7 -> p
	load constant 3
	load constant 3
	load constant 0
	load constant 8
	load constant 5
	load constant 0
	load constant 9
	go to @352
	jsb @226
	a + 1 -> a[p]
	a -> b[w]
	c - 1 -> c[s]
	go to @206
	shift right a[wp]
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	a - 1 -> a[s]
	go to @210
	a exchange b[w]
	a + 1 -> a[p]
	jsb @314
	select rom 1
	shift right a[wp]
	a - 1 -> a[s]
	go to @225
	0 -> a[s]
	a + b -> a[w]
	return
	select rom 1
	shift right a[w]
	b exchange c[w]
	go to @240
	a + b -> a[w]
	c - 1 -> c[s]
	go to @237
	a exchange c[w]
	shift left a[ms]
	a exchange c[w]
	go to @155
	3 -> p
	a + c -> c[x]
	a - c -> c[s]
	go to @253
	0 - c -> c[s]
	a exchange b[m]
	0 -> a[w]
	if p # 12
	go to @305
	if c[m] >= 1
	go to @266
	if s1 = 0
	go to @000
	b -> c[wp]
	a - 1 -> a[m]
	c + 1 -> c[xs]
	b exchange c[wp]
	a exchange c[m]
	select rom 1
	0 -> s8
	load constant 6
	load constant 9
	load constant 3
	load constant 1
	load constant 4
	load constant 7
	load constant 1
	go to @346
	a + 1 -> a[m]
	go to @144
	a + b -> a[w]
	c - 1 -> c[p]
	go to @304
	shift right a[w]
	p + 1 -> p
	if p # 13
	go to @305
	c + 1 -> c[x]
	0 -> a[s]
	12 -> p
	0 -> b[w]
	if a[p] >= 1
	go to @326
	shift left a[w]
	c - 1 -> c[x]
	if a[w] >= 1
	go to @317
	0 -> c[w]
	a -> b[x]
	a + b -> a[w]
	if a[s] >= 1
	go to @307
	a exchange c[m]
	c -> a[w]
	0 -> b[w]
	12 -> p
	go to @172
	9 -> p
	load constant 3
	load constant 1
	load constant 0
	load constant 1
	load constant 7
	load constant 9
	load constant 8
	load constant 0
	load constant 5
	load constant 5
	load constant 3
	go to @335
	a exchange c[w]
	a -> b[w]
	c -> a[m]
	c + c -> c[xs]
	go to @136
	c + 1 -> c[xs]
	shift right a[w]
	c + 1 -> c[x]
	go to @362
	go to @147
	0 -> c[w]
	12 -> p
	load constant 2
	load constant 3
	load constant 0
	load constant 2
	load constant 5
	go to @201
	5 -> p
	go to @176

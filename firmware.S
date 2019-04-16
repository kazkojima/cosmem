;
; Mail box test
;
        .file   "firmware.S"
        .text
        .align  1
        .globl  start
        .type   start,@function
start:
	sex	r14
	;; r1 = 0xf000
	ldi	0xF0
	phi	r1
	ldi	0
	plo	r1
	;; r2 = mboxdat
	ldi	0
	phi	r2
	ldi	mboxdat
	plo	r2
	;; r3.0 = 8
	ldi	8
	plo	r3
loop:
	lda	r2
	str	r1
	inc	r1
	dec	r3
	glo	r3
	lsz
	br	loop
	;; r1 = 0xf008
	ldi	8
	plo	r1
	;; wait ready
wait:
	nop
	nop
	nop
	nop
	ldn	r1
	ani	1
	lsnz
	br	wait
	br	start

mboxdat:
	.byte	0xc3, 1, 2, 3, 4, 5, 6, 7

	.size   start,.-start


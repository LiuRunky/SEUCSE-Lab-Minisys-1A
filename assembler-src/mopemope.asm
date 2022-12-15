.data 0x0000
	pitch: .word 0x0b18e, 0x0a7a6, 0x09e25, 0x09560, 0x08d05, 0x08517, 0x7d9a, 0x768d, 0x6fed, 0x6993, 0x63a6, 0x5e03, 0x58c7, 0x53d3, 0x4f12, 0x4a9e, 0x4672, 0x427d, 0x3ec0, 0x3b3b, 0x37ec, 0x34c9, 0x31d3, 0x2f08
	length: .word 0x1059449, 0x082ca24, 0x416512, 0x20b289, 0x105944, 0x082ca2
	mope_p: .word 12, 9, 5, 12,    12, 14, 12, 10, 12,    12, 17, 15, 15, 14, 12, 10, 9, 10, 12,    12, 9, 5, 12,    12, 14, 12, 10, 12,    9, 10, 12, 12, 10, 9, 7, 5,    5, 5, 10
	mope_l: .word 3, 3, 3, 3,    4, 4, 4, 4, 3,    4, 4, 3, 4, 4, 3, 3, 3, 3, 2,    3, 3, 3, 3,    4, 4, 4, 4, 3,    4, 4, 3, 4, 4, 3, 3, 2,    3, 3, 3

.text 0x0000
start:
	#send "mope" to Display
	ori $t0, $zero, 0x309E
	sw $t0, 0xFC00($zero)
	nop
	nop
	sw $t0, 0xFC02($zero)
	nop
	nop

	#init music
	#$t0: total notes
	addi $t0, $zero, 39
	#$t1: current note
	addi $t1, $zero, 0
	#$t2: current pitch
	#$t3: current length

play:
	sw $t1, 0xFC62($zero)
	nop
	nop

	#read current pitch and length
	sll $t4, $t1, 2
	lw $t2, mope_p($t4)
	nop
	nop
	sll $t2, $t2, 2
	lw $t2, pitch($t2)
	nop
	nop
	lw $t3, mope_l($t4)
	nop
	nop
	sll $t3, $t3, 2
	lw $t3, length($t3)
	nop
	nop

	add $t7, $zero, $t3
	sw $t7, 0xFC00($zero)
	nop
	nop
	srl $t7, $t7, 16
	sw $t7, 0xFC02($zero)
	nop
	nop
	

	#set threshold
	#$t4: buzzer last half of length
	srl $t4, $t3, 1

	#set pitch
	addi $t5, $zero, 1
	sw $t5, 0xFC42($zero)
	nop
	nop
	sw $t2, 0xFC40($zero)
	nop
	nop

	addi $t5, $zero, 0
	j delay

back:
	addi $t1, $t1, 1
	beq $t1, $t0, end
	j play

delay:
	addi $t5, $t5, 1
	#reach threshold, disable buzzer
	beq $t5, $t4, close
	#reach length, prepare next note
	beq $t5, $t3, back
	j delay

close:
	sw $zero, 0xFC42($zero)
	nop
	nop
	j delay

end:
	j end
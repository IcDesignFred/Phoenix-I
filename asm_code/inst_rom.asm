
inst_rom.om:     file format elf32-tradbigmips

Disassembly of section .text:

00000000 <_start>:
   0:	3403eeff 	li	v1,0xeeff
   4:	a0030003 	sb	v1,3(zero)
   8:	00031a02 	srl	v1,v1,0x8
   c:	a0030002 	sb	v1,2(zero)
  10:	3403ccdd 	li	v1,0xccdd
  14:	a0030001 	sb	v1,1(zero)
  18:	00031a02 	srl	v1,v1,0x8
  1c:	a0030000 	sb	v1,0(zero)
  20:	80010003 	lb	at,3(zero)
  24:	90010002 	lbu	at,2(zero)
  28:	00000000 	nop
  2c:	3403aabb 	li	v1,0xaabb
  30:	a4030004 	sh	v1,4(zero)
  34:	94010004 	lhu	at,4(zero)
  38:	84010004 	lh	at,4(zero)
  3c:	34038899 	li	v1,0x8899
  40:	a4030006 	sh	v1,6(zero)
  44:	84010006 	lh	at,6(zero)
  48:	94010006 	lhu	at,6(zero)
  4c:	34034455 	li	v1,0x4455
  50:	00031c00 	sll	v1,v1,0x10
  54:	34636677 	ori	v1,v1,0x6677
  58:	ac030008 	sw	v1,8(zero)
  5c:	8c010008 	lw	at,8(zero)
  60:	00000000 	nop
  64:	88010005 	lwl	at,5(zero)
  68:	00000000 	nop
  6c:	98010008 	lwr	at,8(zero)
  70:	00000000 	nop
  74:	b8010002 	swr	at,2(zero)
  78:	a8010007 	swl	at,7(zero)
  7c:	8c010000 	lw	at,0(zero)
  80:	8c010004 	lw	at,4(zero)

00000084 <_loop>:
  84:	08000021 	j	84 <_loop>
  88:	00000000 	nop
Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	0000000a 	movz	zero,zero,zero
	...

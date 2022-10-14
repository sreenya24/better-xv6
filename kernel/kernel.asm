
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8f070713          	addi	a4,a4,-1808 # 80008940 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	dae78793          	addi	a5,a5,-594 # 80005e10 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb24f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f0278793          	addi	a5,a5,-254 # 80000fae <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	4d8080e7          	jalr	1240(ra) # 80002602 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8f650513          	addi	a0,a0,-1802 # 80010a80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b7a080e7          	jalr	-1158(ra) # 80000d0c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8e648493          	addi	s1,s1,-1818 # 80010a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	97690913          	addi	s2,s2,-1674 # 80010b18 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	93c080e7          	jalr	-1732(ra) # 80001afc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	284080e7          	jalr	644(ra) # 8000244c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	fce080e7          	jalr	-50(ra) # 800021a4 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	39a080e7          	jalr	922(ra) # 800025ac <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	85a50513          	addi	a0,a0,-1958 # 80010a80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b92080e7          	jalr	-1134(ra) # 80000dc0 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	84450513          	addi	a0,a0,-1980 # 80010a80 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b7c080e7          	jalr	-1156(ra) # 80000dc0 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72323          	sw	a5,-1882(a4) # 80010b18 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7b450513          	addi	a0,a0,1972 # 80010a80 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a38080e7          	jalr	-1480(ra) # 80000d0c <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	366080e7          	jalr	870(ra) # 80002658 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	78650513          	addi	a0,a0,1926 # 80010a80 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	abe080e7          	jalr	-1346(ra) # 80000dc0 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	76270713          	addi	a4,a4,1890 # 80010a80 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	73878793          	addi	a5,a5,1848 # 80010a80 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7a27a783          	lw	a5,1954(a5) # 80010b18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6f670713          	addi	a4,a4,1782 # 80010a80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6e648493          	addi	s1,s1,1766 # 80010a80 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6aa70713          	addi	a4,a4,1706 # 80010a80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72a23          	sw	a5,1844(a4) # 80010b20 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	66e78793          	addi	a5,a5,1646 # 80010a80 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7a323          	sw	a2,1766(a5) # 80010b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6da50513          	addi	a0,a0,1754 # 80010b18 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dc2080e7          	jalr	-574(ra) # 80002208 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	62050513          	addi	a0,a0,1568 # 80010a80 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	814080e7          	jalr	-2028(ra) # 80000c7c <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	fa078793          	addi	a5,a5,-96 # 80242418 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5e07aa23          	sw	zero,1524(a5) # 80010b40 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b9250513          	addi	a0,a0,-1134 # 80008100 <digits+0xc0>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	38f72023          	sw	a5,896(a4) # 80008900 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	584dad83          	lw	s11,1412(s11) # 80010b40 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	52e50513          	addi	a0,a0,1326 # 80010b28 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	70a080e7          	jalr	1802(ra) # 80000d0c <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3d050513          	addi	a0,a0,976 # 80010b28 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	660080e7          	jalr	1632(ra) # 80000dc0 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3b448493          	addi	s1,s1,948 # 80010b28 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	4f6080e7          	jalr	1270(ra) # 80000c7c <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	37450513          	addi	a0,a0,884 # 80010b48 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	4a0080e7          	jalr	1184(ra) # 80000c7c <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	4c8080e7          	jalr	1224(ra) # 80000cc0 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1007a783          	lw	a5,256(a5) # 80008900 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	53a080e7          	jalr	1338(ra) # 80000d60 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0d07b783          	ld	a5,208(a5) # 80008908 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0d073703          	ld	a4,208(a4) # 80008910 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2e6a0a13          	addi	s4,s4,742 # 80010b48 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	09e48493          	addi	s1,s1,158 # 80008908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	09e98993          	addi	s3,s3,158 # 80008910 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	974080e7          	jalr	-1676(ra) # 80002208 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	27850513          	addi	a0,a0,632 # 80010b48 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	434080e7          	jalr	1076(ra) # 80000d0c <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0207a783          	lw	a5,32(a5) # 80008900 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	02673703          	ld	a4,38(a4) # 80008910 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0167b783          	ld	a5,22(a5) # 80008908 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	24a98993          	addi	s3,s3,586 # 80010b48 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	00248493          	addi	s1,s1,2 # 80008908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	00290913          	addi	s2,s2,2 # 80008910 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	886080e7          	jalr	-1914(ra) # 800021a4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	21448493          	addi	s1,s1,532 # 80010b48 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fce7b423          	sd	a4,-56(a5) # 80008910 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	466080e7          	jalr	1126(ra) # 80000dc0 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	18e48493          	addi	s1,s1,398 # 80010b48 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	348080e7          	jalr	840(ra) # 80000d0c <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	3ea080e7          	jalr	1002(ra) # 80000dc0 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <increse>:
    kfree(p);
  }
}

void increse(uint64 pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	1000                	addi	s0,sp,32
    800009f2:	84aa                	mv	s1,a0
  // acquire the lock
  acquire(&kmem.lock);
    800009f4:	00010517          	auipc	a0,0x10
    800009f8:	18c50513          	addi	a0,a0,396 # 80010b80 <kmem>
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	310080e7          	jalr	784(ra) # 80000d0c <acquire>
  int pn = pa / PGSIZE;
  if (pa > PHYSTOP || refcnt[pn] < 1)
    80000a04:	4745                	li	a4,17
    80000a06:	076e                	slli	a4,a4,0x1b
    80000a08:	04976463          	bltu	a4,s1,80000a50 <increse+0x68>
    80000a0c:	00c4d793          	srli	a5,s1,0xc
    80000a10:	2781                	sext.w	a5,a5
    80000a12:	00279693          	slli	a3,a5,0x2
    80000a16:	00010717          	auipc	a4,0x10
    80000a1a:	18a70713          	addi	a4,a4,394 # 80010ba0 <refcnt>
    80000a1e:	9736                	add	a4,a4,a3
    80000a20:	4318                	lw	a4,0(a4)
    80000a22:	02e05763          	blez	a4,80000a50 <increse+0x68>
  {
    panic("increase ref cnt");
  }
  refcnt[pn]++;
    80000a26:	078a                	slli	a5,a5,0x2
    80000a28:	00010697          	auipc	a3,0x10
    80000a2c:	17868693          	addi	a3,a3,376 # 80010ba0 <refcnt>
    80000a30:	97b6                	add	a5,a5,a3
    80000a32:	2705                	addiw	a4,a4,1
    80000a34:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a36:	00010517          	auipc	a0,0x10
    80000a3a:	14a50513          	addi	a0,a0,330 # 80010b80 <kmem>
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	382080e7          	jalr	898(ra) # 80000dc0 <release>
}
    80000a46:	60e2                	ld	ra,24(sp)
    80000a48:	6442                	ld	s0,16(sp)
    80000a4a:	64a2                	ld	s1,8(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("increase ref cnt");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae8080e7          	jalr	-1304(ra) # 80000540 <panic>

0000000080000a60 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	e04a                	sd	s2,0(sp)
    80000a6a:	1000                	addi	s0,sp,32
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a6c:	03451793          	slli	a5,a0,0x34
    80000a70:	ebbd                	bnez	a5,80000ae6 <kfree+0x86>
    80000a72:	84aa                	mv	s1,a0
    80000a74:	00243797          	auipc	a5,0x243
    80000a78:	b3c78793          	addi	a5,a5,-1220 # 802435b0 <end>
    80000a7c:	06f56563          	bltu	a0,a5,80000ae6 <kfree+0x86>
    80000a80:	47c5                	li	a5,17
    80000a82:	07ee                	slli	a5,a5,0x1b
    80000a84:	06f57163          	bgeu	a0,a5,80000ae6 <kfree+0x86>
  // Fill with junk to catch dangling refs.
  // memset(pa, 1, PGSIZE);

  r = (struct run *)pa;

  acquire(&kmem.lock);
    80000a88:	00010517          	auipc	a0,0x10
    80000a8c:	0f850513          	addi	a0,a0,248 # 80010b80 <kmem>
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	27c080e7          	jalr	636(ra) # 80000d0c <acquire>
  int pn = (uint64)r / PGSIZE;
    80000a98:	00c4d793          	srli	a5,s1,0xc
    80000a9c:	2781                	sext.w	a5,a5
  if (refcnt[pn] < 1)
    80000a9e:	00279693          	slli	a3,a5,0x2
    80000aa2:	00010717          	auipc	a4,0x10
    80000aa6:	0fe70713          	addi	a4,a4,254 # 80010ba0 <refcnt>
    80000aaa:	9736                	add	a4,a4,a3
    80000aac:	4318                	lw	a4,0(a4)
    80000aae:	04e05463          	blez	a4,80000af6 <kfree+0x96>
    panic("kfree panic");
  refcnt[pn] -= 1;
    80000ab2:	377d                	addiw	a4,a4,-1
    80000ab4:	0007091b          	sext.w	s2,a4
    80000ab8:	078a                	slli	a5,a5,0x2
    80000aba:	00010697          	auipc	a3,0x10
    80000abe:	0e668693          	addi	a3,a3,230 # 80010ba0 <refcnt>
    80000ac2:	97b6                	add	a5,a5,a3
    80000ac4:	c398                	sw	a4,0(a5)
  int tmp = refcnt[pn];
  release(&kmem.lock);
    80000ac6:	00010517          	auipc	a0,0x10
    80000aca:	0ba50513          	addi	a0,a0,186 # 80010b80 <kmem>
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	2f2080e7          	jalr	754(ra) # 80000dc0 <release>

  if (tmp > 0)
    80000ad6:	03205863          	blez	s2,80000b06 <kfree+0xa6>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000ada:	60e2                	ld	ra,24(sp)
    80000adc:	6442                	ld	s0,16(sp)
    80000ade:	64a2                	ld	s1,8(sp)
    80000ae0:	6902                	ld	s2,0(sp)
    80000ae2:	6105                	addi	sp,sp,32
    80000ae4:	8082                	ret
    panic("kfree");
    80000ae6:	00007517          	auipc	a0,0x7
    80000aea:	59250513          	addi	a0,a0,1426 # 80008078 <digits+0x38>
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	a52080e7          	jalr	-1454(ra) # 80000540 <panic>
    panic("kfree panic");
    80000af6:	00007517          	auipc	a0,0x7
    80000afa:	58a50513          	addi	a0,a0,1418 # 80008080 <digits+0x40>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	a42080e7          	jalr	-1470(ra) # 80000540 <panic>
  memset(pa, 1, PGSIZE);
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4585                	li	a1,1
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	2fc080e7          	jalr	764(ra) # 80000e08 <memset>
  acquire(&kmem.lock);
    80000b14:	00010917          	auipc	s2,0x10
    80000b18:	06c90913          	addi	s2,s2,108 # 80010b80 <kmem>
    80000b1c:	854a                	mv	a0,s2
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	1ee080e7          	jalr	494(ra) # 80000d0c <acquire>
  r->next = kmem.freelist;
    80000b26:	01893783          	ld	a5,24(s2)
    80000b2a:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b2c:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b30:	854a                	mv	a0,s2
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	28e080e7          	jalr	654(ra) # 80000dc0 <release>
    80000b3a:	b745                	j	80000ada <kfree+0x7a>

0000000080000b3c <freerange>:
{
    80000b3c:	7139                	addi	sp,sp,-64
    80000b3e:	fc06                	sd	ra,56(sp)
    80000b40:	f822                	sd	s0,48(sp)
    80000b42:	f426                	sd	s1,40(sp)
    80000b44:	f04a                	sd	s2,32(sp)
    80000b46:	ec4e                	sd	s3,24(sp)
    80000b48:	e852                	sd	s4,16(sp)
    80000b4a:	e456                	sd	s5,8(sp)
    80000b4c:	e05a                	sd	s6,0(sp)
    80000b4e:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000b50:	6785                	lui	a5,0x1
    80000b52:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b56:	953a                	add	a0,a0,a4
    80000b58:	777d                	lui	a4,0xfffff
    80000b5a:	00e574b3          	and	s1,a0,a4
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b5e:	97a6                	add	a5,a5,s1
    80000b60:	02f5ea63          	bltu	a1,a5,80000b94 <freerange+0x58>
    80000b64:	892e                	mv	s2,a1
    refcnt[(uint64)p / PGSIZE] = 1;
    80000b66:	00010b17          	auipc	s6,0x10
    80000b6a:	03ab0b13          	addi	s6,s6,58 # 80010ba0 <refcnt>
    80000b6e:	4a85                	li	s5,1
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b70:	6a05                	lui	s4,0x1
    80000b72:	6989                	lui	s3,0x2
    refcnt[(uint64)p / PGSIZE] = 1;
    80000b74:	00c4d793          	srli	a5,s1,0xc
    80000b78:	078a                	slli	a5,a5,0x2
    80000b7a:	97da                	add	a5,a5,s6
    80000b7c:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	ede080e7          	jalr	-290(ra) # 80000a60 <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b8a:	87a6                	mv	a5,s1
    80000b8c:	94d2                	add	s1,s1,s4
    80000b8e:	97ce                	add	a5,a5,s3
    80000b90:	fef972e3          	bgeu	s2,a5,80000b74 <freerange+0x38>
}
    80000b94:	70e2                	ld	ra,56(sp)
    80000b96:	7442                	ld	s0,48(sp)
    80000b98:	74a2                	ld	s1,40(sp)
    80000b9a:	7902                	ld	s2,32(sp)
    80000b9c:	69e2                	ld	s3,24(sp)
    80000b9e:	6a42                	ld	s4,16(sp)
    80000ba0:	6aa2                	ld	s5,8(sp)
    80000ba2:	6b02                	ld	s6,0(sp)
    80000ba4:	6121                	addi	sp,sp,64
    80000ba6:	8082                	ret

0000000080000ba8 <kinit>:
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e406                	sd	ra,8(sp)
    80000bac:	e022                	sd	s0,0(sp)
    80000bae:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bb0:	00007597          	auipc	a1,0x7
    80000bb4:	4e058593          	addi	a1,a1,1248 # 80008090 <digits+0x50>
    80000bb8:	00010517          	auipc	a0,0x10
    80000bbc:	fc850513          	addi	a0,a0,-56 # 80010b80 <kmem>
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	0bc080e7          	jalr	188(ra) # 80000c7c <initlock>
  freerange(end, (void *)PHYSTOP);
    80000bc8:	45c5                	li	a1,17
    80000bca:	05ee                	slli	a1,a1,0x1b
    80000bcc:	00243517          	auipc	a0,0x243
    80000bd0:	9e450513          	addi	a0,a0,-1564 # 802435b0 <end>
    80000bd4:	00000097          	auipc	ra,0x0
    80000bd8:	f68080e7          	jalr	-152(ra) # 80000b3c <freerange>
}
    80000bdc:	60a2                	ld	ra,8(sp)
    80000bde:	6402                	ld	s0,0(sp)
    80000be0:	0141                	addi	sp,sp,16
    80000be2:	8082                	ret

0000000080000be4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bee:	00010497          	auipc	s1,0x10
    80000bf2:	f9248493          	addi	s1,s1,-110 # 80010b80 <kmem>
    80000bf6:	8526                	mv	a0,s1
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	114080e7          	jalr	276(ra) # 80000d0c <acquire>
  r = kmem.freelist;
    80000c00:	6c84                	ld	s1,24(s1)
  if (r)
    80000c02:	c4a5                	beqz	s1,80000c6a <kalloc+0x86>
  {
    int pn = (uint64)r / PGSIZE;
    80000c04:	00c4d793          	srli	a5,s1,0xc
    80000c08:	2781                	sext.w	a5,a5
    if(refcnt[pn]!=0){
    80000c0a:	00279693          	slli	a3,a5,0x2
    80000c0e:	00010717          	auipc	a4,0x10
    80000c12:	f9270713          	addi	a4,a4,-110 # 80010ba0 <refcnt>
    80000c16:	9736                	add	a4,a4,a3
    80000c18:	4318                	lw	a4,0(a4)
    80000c1a:	e321                	bnez	a4,80000c5a <kalloc+0x76>
      panic("refcnt kalloc");
    }
    refcnt[pn] = 1;
    80000c1c:	078a                	slli	a5,a5,0x2
    80000c1e:	00010717          	auipc	a4,0x10
    80000c22:	f8270713          	addi	a4,a4,-126 # 80010ba0 <refcnt>
    80000c26:	97ba                	add	a5,a5,a4
    80000c28:	4705                	li	a4,1
    80000c2a:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000c2c:	609c                	ld	a5,0(s1)
    80000c2e:	00010517          	auipc	a0,0x10
    80000c32:	f5250513          	addi	a0,a0,-174 # 80010b80 <kmem>
    80000c36:	ed1c                	sd	a5,24(a0)
  }
  release(&kmem.lock);
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	188080e7          	jalr	392(ra) # 80000dc0 <release>

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000c40:	6605                	lui	a2,0x1
    80000c42:	4595                	li	a1,5
    80000c44:	8526                	mv	a0,s1
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	1c2080e7          	jalr	450(ra) # 80000e08 <memset>
  return (void *)r;
}
    80000c4e:	8526                	mv	a0,s1
    80000c50:	60e2                	ld	ra,24(sp)
    80000c52:	6442                	ld	s0,16(sp)
    80000c54:	64a2                	ld	s1,8(sp)
    80000c56:	6105                	addi	sp,sp,32
    80000c58:	8082                	ret
      panic("refcnt kalloc");
    80000c5a:	00007517          	auipc	a0,0x7
    80000c5e:	43e50513          	addi	a0,a0,1086 # 80008098 <digits+0x58>
    80000c62:	00000097          	auipc	ra,0x0
    80000c66:	8de080e7          	jalr	-1826(ra) # 80000540 <panic>
  release(&kmem.lock);
    80000c6a:	00010517          	auipc	a0,0x10
    80000c6e:	f1650513          	addi	a0,a0,-234 # 80010b80 <kmem>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	14e080e7          	jalr	334(ra) # 80000dc0 <release>
  if (r)
    80000c7a:	bfd1                	j	80000c4e <kalloc+0x6a>

0000000080000c7c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c7c:	1141                	addi	sp,sp,-16
    80000c7e:	e422                	sd	s0,8(sp)
    80000c80:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c82:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c84:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c88:	00053823          	sd	zero,16(a0)
}
    80000c8c:	6422                	ld	s0,8(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret

0000000080000c92 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c92:	411c                	lw	a5,0(a0)
    80000c94:	e399                	bnez	a5,80000c9a <holding+0x8>
    80000c96:	4501                	li	a0,0
  return r;
}
    80000c98:	8082                	ret
{
    80000c9a:	1101                	addi	sp,sp,-32
    80000c9c:	ec06                	sd	ra,24(sp)
    80000c9e:	e822                	sd	s0,16(sp)
    80000ca0:	e426                	sd	s1,8(sp)
    80000ca2:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ca4:	6904                	ld	s1,16(a0)
    80000ca6:	00001097          	auipc	ra,0x1
    80000caa:	e3a080e7          	jalr	-454(ra) # 80001ae0 <mycpu>
    80000cae:	40a48533          	sub	a0,s1,a0
    80000cb2:	00153513          	seqz	a0,a0
}
    80000cb6:	60e2                	ld	ra,24(sp)
    80000cb8:	6442                	ld	s0,16(sp)
    80000cba:	64a2                	ld	s1,8(sp)
    80000cbc:	6105                	addi	sp,sp,32
    80000cbe:	8082                	ret

0000000080000cc0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cc0:	1101                	addi	sp,sp,-32
    80000cc2:	ec06                	sd	ra,24(sp)
    80000cc4:	e822                	sd	s0,16(sp)
    80000cc6:	e426                	sd	s1,8(sp)
    80000cc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cca:	100024f3          	csrr	s1,sstatus
    80000cce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cd8:	00001097          	auipc	ra,0x1
    80000cdc:	e08080e7          	jalr	-504(ra) # 80001ae0 <mycpu>
    80000ce0:	5d3c                	lw	a5,120(a0)
    80000ce2:	cf89                	beqz	a5,80000cfc <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ce4:	00001097          	auipc	ra,0x1
    80000ce8:	dfc080e7          	jalr	-516(ra) # 80001ae0 <mycpu>
    80000cec:	5d3c                	lw	a5,120(a0)
    80000cee:	2785                	addiw	a5,a5,1
    80000cf0:	dd3c                	sw	a5,120(a0)
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    mycpu()->intena = old;
    80000cfc:	00001097          	auipc	ra,0x1
    80000d00:	de4080e7          	jalr	-540(ra) # 80001ae0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d04:	8085                	srli	s1,s1,0x1
    80000d06:	8885                	andi	s1,s1,1
    80000d08:	dd64                	sw	s1,124(a0)
    80000d0a:	bfe9                	j	80000ce4 <push_off+0x24>

0000000080000d0c <acquire>:
{
    80000d0c:	1101                	addi	sp,sp,-32
    80000d0e:	ec06                	sd	ra,24(sp)
    80000d10:	e822                	sd	s0,16(sp)
    80000d12:	e426                	sd	s1,8(sp)
    80000d14:	1000                	addi	s0,sp,32
    80000d16:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	fa8080e7          	jalr	-88(ra) # 80000cc0 <push_off>
  if(holding(lk))
    80000d20:	8526                	mv	a0,s1
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f70080e7          	jalr	-144(ra) # 80000c92 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2a:	4705                	li	a4,1
  if(holding(lk))
    80000d2c:	e115                	bnez	a0,80000d50 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2e:	87ba                	mv	a5,a4
    80000d30:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d34:	2781                	sext.w	a5,a5
    80000d36:	ffe5                	bnez	a5,80000d2e <acquire+0x22>
  __sync_synchronize();
    80000d38:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d3c:	00001097          	auipc	ra,0x1
    80000d40:	da4080e7          	jalr	-604(ra) # 80001ae0 <mycpu>
    80000d44:	e888                	sd	a0,16(s1)
}
    80000d46:	60e2                	ld	ra,24(sp)
    80000d48:	6442                	ld	s0,16(sp)
    80000d4a:	64a2                	ld	s1,8(sp)
    80000d4c:	6105                	addi	sp,sp,32
    80000d4e:	8082                	ret
    panic("acquire");
    80000d50:	00007517          	auipc	a0,0x7
    80000d54:	35850513          	addi	a0,a0,856 # 800080a8 <digits+0x68>
    80000d58:	fffff097          	auipc	ra,0xfffff
    80000d5c:	7e8080e7          	jalr	2024(ra) # 80000540 <panic>

0000000080000d60 <pop_off>:

void
pop_off(void)
{
    80000d60:	1141                	addi	sp,sp,-16
    80000d62:	e406                	sd	ra,8(sp)
    80000d64:	e022                	sd	s0,0(sp)
    80000d66:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d68:	00001097          	auipc	ra,0x1
    80000d6c:	d78080e7          	jalr	-648(ra) # 80001ae0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d70:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d74:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d76:	e78d                	bnez	a5,80000da0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d78:	5d3c                	lw	a5,120(a0)
    80000d7a:	02f05b63          	blez	a5,80000db0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d7e:	37fd                	addiw	a5,a5,-1
    80000d80:	0007871b          	sext.w	a4,a5
    80000d84:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d86:	eb09                	bnez	a4,80000d98 <pop_off+0x38>
    80000d88:	5d7c                	lw	a5,124(a0)
    80000d8a:	c799                	beqz	a5,80000d98 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d94:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d98:	60a2                	ld	ra,8(sp)
    80000d9a:	6402                	ld	s0,0(sp)
    80000d9c:	0141                	addi	sp,sp,16
    80000d9e:	8082                	ret
    panic("pop_off - interruptible");
    80000da0:	00007517          	auipc	a0,0x7
    80000da4:	31050513          	addi	a0,a0,784 # 800080b0 <digits+0x70>
    80000da8:	fffff097          	auipc	ra,0xfffff
    80000dac:	798080e7          	jalr	1944(ra) # 80000540 <panic>
    panic("pop_off");
    80000db0:	00007517          	auipc	a0,0x7
    80000db4:	31850513          	addi	a0,a0,792 # 800080c8 <digits+0x88>
    80000db8:	fffff097          	auipc	ra,0xfffff
    80000dbc:	788080e7          	jalr	1928(ra) # 80000540 <panic>

0000000080000dc0 <release>:
{
    80000dc0:	1101                	addi	sp,sp,-32
    80000dc2:	ec06                	sd	ra,24(sp)
    80000dc4:	e822                	sd	s0,16(sp)
    80000dc6:	e426                	sd	s1,8(sp)
    80000dc8:	1000                	addi	s0,sp,32
    80000dca:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dcc:	00000097          	auipc	ra,0x0
    80000dd0:	ec6080e7          	jalr	-314(ra) # 80000c92 <holding>
    80000dd4:	c115                	beqz	a0,80000df8 <release+0x38>
  lk->cpu = 0;
    80000dd6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dda:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dde:	0f50000f          	fence	iorw,ow
    80000de2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	f7a080e7          	jalr	-134(ra) # 80000d60 <pop_off>
}
    80000dee:	60e2                	ld	ra,24(sp)
    80000df0:	6442                	ld	s0,16(sp)
    80000df2:	64a2                	ld	s1,8(sp)
    80000df4:	6105                	addi	sp,sp,32
    80000df6:	8082                	ret
    panic("release");
    80000df8:	00007517          	auipc	a0,0x7
    80000dfc:	2d850513          	addi	a0,a0,728 # 800080d0 <digits+0x90>
    80000e00:	fffff097          	auipc	ra,0xfffff
    80000e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>

0000000080000e08 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e08:	1141                	addi	sp,sp,-16
    80000e0a:	e422                	sd	s0,8(sp)
    80000e0c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e0e:	ca19                	beqz	a2,80000e24 <memset+0x1c>
    80000e10:	87aa                	mv	a5,a0
    80000e12:	1602                	slli	a2,a2,0x20
    80000e14:	9201                	srli	a2,a2,0x20
    80000e16:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e1a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e1e:	0785                	addi	a5,a5,1
    80000e20:	fee79de3          	bne	a5,a4,80000e1a <memset+0x12>
  }
  return dst;
}
    80000e24:	6422                	ld	s0,8(sp)
    80000e26:	0141                	addi	sp,sp,16
    80000e28:	8082                	ret

0000000080000e2a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e2a:	1141                	addi	sp,sp,-16
    80000e2c:	e422                	sd	s0,8(sp)
    80000e2e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e30:	ca05                	beqz	a2,80000e60 <memcmp+0x36>
    80000e32:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	0685                	addi	a3,a3,1
    80000e3c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e3e:	00054783          	lbu	a5,0(a0)
    80000e42:	0005c703          	lbu	a4,0(a1)
    80000e46:	00e79863          	bne	a5,a4,80000e56 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e4e:	fed518e3          	bne	a0,a3,80000e3e <memcmp+0x14>
  }

  return 0;
    80000e52:	4501                	li	a0,0
    80000e54:	a019                	j	80000e5a <memcmp+0x30>
      return *s1 - *s2;
    80000e56:	40e7853b          	subw	a0,a5,a4
}
    80000e5a:	6422                	ld	s0,8(sp)
    80000e5c:	0141                	addi	sp,sp,16
    80000e5e:	8082                	ret
  return 0;
    80000e60:	4501                	li	a0,0
    80000e62:	bfe5                	j	80000e5a <memcmp+0x30>

0000000080000e64 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e6a:	c205                	beqz	a2,80000e8a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e6c:	02a5e263          	bltu	a1,a0,80000e90 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e70:	1602                	slli	a2,a2,0x20
    80000e72:	9201                	srli	a2,a2,0x20
    80000e74:	00c587b3          	add	a5,a1,a2
{
    80000e78:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e7a:	0585                	addi	a1,a1,1
    80000e7c:	0705                	addi	a4,a4,1
    80000e7e:	fff5c683          	lbu	a3,-1(a1)
    80000e82:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e86:	fef59ae3          	bne	a1,a5,80000e7a <memmove+0x16>

  return dst;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  if(s < d && s + n > d){
    80000e90:	02061693          	slli	a3,a2,0x20
    80000e94:	9281                	srli	a3,a3,0x20
    80000e96:	00d58733          	add	a4,a1,a3
    80000e9a:	fce57be3          	bgeu	a0,a4,80000e70 <memmove+0xc>
    d += n;
    80000e9e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ea0:	fff6079b          	addiw	a5,a2,-1
    80000ea4:	1782                	slli	a5,a5,0x20
    80000ea6:	9381                	srli	a5,a5,0x20
    80000ea8:	fff7c793          	not	a5,a5
    80000eac:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000eae:	177d                	addi	a4,a4,-1
    80000eb0:	16fd                	addi	a3,a3,-1
    80000eb2:	00074603          	lbu	a2,0(a4)
    80000eb6:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000eba:	fee79ae3          	bne	a5,a4,80000eae <memmove+0x4a>
    80000ebe:	b7f1                	j	80000e8a <memmove+0x26>

0000000080000ec0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ec0:	1141                	addi	sp,sp,-16
    80000ec2:	e406                	sd	ra,8(sp)
    80000ec4:	e022                	sd	s0,0(sp)
    80000ec6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ec8:	00000097          	auipc	ra,0x0
    80000ecc:	f9c080e7          	jalr	-100(ra) # 80000e64 <memmove>
}
    80000ed0:	60a2                	ld	ra,8(sp)
    80000ed2:	6402                	ld	s0,0(sp)
    80000ed4:	0141                	addi	sp,sp,16
    80000ed6:	8082                	ret

0000000080000ed8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ed8:	1141                	addi	sp,sp,-16
    80000eda:	e422                	sd	s0,8(sp)
    80000edc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ede:	ce11                	beqz	a2,80000efa <strncmp+0x22>
    80000ee0:	00054783          	lbu	a5,0(a0)
    80000ee4:	cf89                	beqz	a5,80000efe <strncmp+0x26>
    80000ee6:	0005c703          	lbu	a4,0(a1)
    80000eea:	00f71a63          	bne	a4,a5,80000efe <strncmp+0x26>
    n--, p++, q++;
    80000eee:	367d                	addiw	a2,a2,-1
    80000ef0:	0505                	addi	a0,a0,1
    80000ef2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ef4:	f675                	bnez	a2,80000ee0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ef6:	4501                	li	a0,0
    80000ef8:	a809                	j	80000f0a <strncmp+0x32>
    80000efa:	4501                	li	a0,0
    80000efc:	a039                	j	80000f0a <strncmp+0x32>
  if(n == 0)
    80000efe:	ca09                	beqz	a2,80000f10 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f00:	00054503          	lbu	a0,0(a0)
    80000f04:	0005c783          	lbu	a5,0(a1)
    80000f08:	9d1d                	subw	a0,a0,a5
}
    80000f0a:	6422                	ld	s0,8(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret
    return 0;
    80000f10:	4501                	li	a0,0
    80000f12:	bfe5                	j	80000f0a <strncmp+0x32>

0000000080000f14 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f14:	1141                	addi	sp,sp,-16
    80000f16:	e422                	sd	s0,8(sp)
    80000f18:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f1a:	872a                	mv	a4,a0
    80000f1c:	8832                	mv	a6,a2
    80000f1e:	367d                	addiw	a2,a2,-1
    80000f20:	01005963          	blez	a6,80000f32 <strncpy+0x1e>
    80000f24:	0705                	addi	a4,a4,1
    80000f26:	0005c783          	lbu	a5,0(a1)
    80000f2a:	fef70fa3          	sb	a5,-1(a4)
    80000f2e:	0585                	addi	a1,a1,1
    80000f30:	f7f5                	bnez	a5,80000f1c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f32:	86ba                	mv	a3,a4
    80000f34:	00c05c63          	blez	a2,80000f4c <strncpy+0x38>
    *s++ = 0;
    80000f38:	0685                	addi	a3,a3,1
    80000f3a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f3e:	40d707bb          	subw	a5,a4,a3
    80000f42:	37fd                	addiw	a5,a5,-1
    80000f44:	010787bb          	addw	a5,a5,a6
    80000f48:	fef048e3          	bgtz	a5,80000f38 <strncpy+0x24>
  return os;
}
    80000f4c:	6422                	ld	s0,8(sp)
    80000f4e:	0141                	addi	sp,sp,16
    80000f50:	8082                	ret

0000000080000f52 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f52:	1141                	addi	sp,sp,-16
    80000f54:	e422                	sd	s0,8(sp)
    80000f56:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f58:	02c05363          	blez	a2,80000f7e <safestrcpy+0x2c>
    80000f5c:	fff6069b          	addiw	a3,a2,-1
    80000f60:	1682                	slli	a3,a3,0x20
    80000f62:	9281                	srli	a3,a3,0x20
    80000f64:	96ae                	add	a3,a3,a1
    80000f66:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f68:	00d58963          	beq	a1,a3,80000f7a <safestrcpy+0x28>
    80000f6c:	0585                	addi	a1,a1,1
    80000f6e:	0785                	addi	a5,a5,1
    80000f70:	fff5c703          	lbu	a4,-1(a1)
    80000f74:	fee78fa3          	sb	a4,-1(a5)
    80000f78:	fb65                	bnez	a4,80000f68 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f7a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f7e:	6422                	ld	s0,8(sp)
    80000f80:	0141                	addi	sp,sp,16
    80000f82:	8082                	ret

0000000080000f84 <strlen>:

int
strlen(const char *s)
{
    80000f84:	1141                	addi	sp,sp,-16
    80000f86:	e422                	sd	s0,8(sp)
    80000f88:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f8a:	00054783          	lbu	a5,0(a0)
    80000f8e:	cf91                	beqz	a5,80000faa <strlen+0x26>
    80000f90:	0505                	addi	a0,a0,1
    80000f92:	87aa                	mv	a5,a0
    80000f94:	4685                	li	a3,1
    80000f96:	9e89                	subw	a3,a3,a0
    80000f98:	00f6853b          	addw	a0,a3,a5
    80000f9c:	0785                	addi	a5,a5,1
    80000f9e:	fff7c703          	lbu	a4,-1(a5)
    80000fa2:	fb7d                	bnez	a4,80000f98 <strlen+0x14>
    ;
  return n;
}
    80000fa4:	6422                	ld	s0,8(sp)
    80000fa6:	0141                	addi	sp,sp,16
    80000fa8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000faa:	4501                	li	a0,0
    80000fac:	bfe5                	j	80000fa4 <strlen+0x20>

0000000080000fae <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e406                	sd	ra,8(sp)
    80000fb2:	e022                	sd	s0,0(sp)
    80000fb4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fb6:	00001097          	auipc	ra,0x1
    80000fba:	b1a080e7          	jalr	-1254(ra) # 80001ad0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fbe:	00008717          	auipc	a4,0x8
    80000fc2:	95a70713          	addi	a4,a4,-1702 # 80008918 <started>
  if(cpuid() == 0){
    80000fc6:	c139                	beqz	a0,8000100c <main+0x5e>
    while(started == 0)
    80000fc8:	431c                	lw	a5,0(a4)
    80000fca:	2781                	sext.w	a5,a5
    80000fcc:	dff5                	beqz	a5,80000fc8 <main+0x1a>
      ;
    __sync_synchronize();
    80000fce:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	afe080e7          	jalr	-1282(ra) # 80001ad0 <cpuid>
    80000fda:	85aa                	mv	a1,a0
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	11450513          	addi	a0,a0,276 # 800080f0 <digits+0xb0>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	5a6080e7          	jalr	1446(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000fec:	00000097          	auipc	ra,0x0
    80000ff0:	0d8080e7          	jalr	216(ra) # 800010c4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ff4:	00001097          	auipc	ra,0x1
    80000ff8:	7a6080e7          	jalr	1958(ra) # 8000279a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ffc:	00005097          	auipc	ra,0x5
    80001000:	e54080e7          	jalr	-428(ra) # 80005e50 <plicinithart>
  }

  scheduler();        
    80001004:	00001097          	auipc	ra,0x1
    80001008:	fee080e7          	jalr	-18(ra) # 80001ff2 <scheduler>
    consoleinit();
    8000100c:	fffff097          	auipc	ra,0xfffff
    80001010:	444080e7          	jalr	1092(ra) # 80000450 <consoleinit>
    printfinit();
    80001014:	fffff097          	auipc	ra,0xfffff
    80001018:	756080e7          	jalr	1878(ra) # 8000076a <printfinit>
    printf("\n");
    8000101c:	00007517          	auipc	a0,0x7
    80001020:	0e450513          	addi	a0,a0,228 # 80008100 <digits+0xc0>
    80001024:	fffff097          	auipc	ra,0xfffff
    80001028:	566080e7          	jalr	1382(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    8000102c:	00007517          	auipc	a0,0x7
    80001030:	0ac50513          	addi	a0,a0,172 # 800080d8 <digits+0x98>
    80001034:	fffff097          	auipc	ra,0xfffff
    80001038:	556080e7          	jalr	1366(ra) # 8000058a <printf>
    printf("\n");
    8000103c:	00007517          	auipc	a0,0x7
    80001040:	0c450513          	addi	a0,a0,196 # 80008100 <digits+0xc0>
    80001044:	fffff097          	auipc	ra,0xfffff
    80001048:	546080e7          	jalr	1350(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    8000104c:	00000097          	auipc	ra,0x0
    80001050:	b5c080e7          	jalr	-1188(ra) # 80000ba8 <kinit>
    kvminit();       // create kernel page table
    80001054:	00000097          	auipc	ra,0x0
    80001058:	326080e7          	jalr	806(ra) # 8000137a <kvminit>
    kvminithart();   // turn on paging
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	068080e7          	jalr	104(ra) # 800010c4 <kvminithart>
    procinit();      // process table
    80001064:	00001097          	auipc	ra,0x1
    80001068:	9b8080e7          	jalr	-1608(ra) # 80001a1c <procinit>
    trapinit();      // trap vectors
    8000106c:	00001097          	auipc	ra,0x1
    80001070:	706080e7          	jalr	1798(ra) # 80002772 <trapinit>
    trapinithart();  // install kernel trap vector
    80001074:	00001097          	auipc	ra,0x1
    80001078:	726080e7          	jalr	1830(ra) # 8000279a <trapinithart>
    plicinit();      // set up interrupt controller
    8000107c:	00005097          	auipc	ra,0x5
    80001080:	dbe080e7          	jalr	-578(ra) # 80005e3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001084:	00005097          	auipc	ra,0x5
    80001088:	dcc080e7          	jalr	-564(ra) # 80005e50 <plicinithart>
    binit();         // buffer cache
    8000108c:	00002097          	auipc	ra,0x2
    80001090:	f64080e7          	jalr	-156(ra) # 80002ff0 <binit>
    iinit();         // inode table
    80001094:	00002097          	auipc	ra,0x2
    80001098:	604080e7          	jalr	1540(ra) # 80003698 <iinit>
    fileinit();      // file table
    8000109c:	00003097          	auipc	ra,0x3
    800010a0:	5aa080e7          	jalr	1450(ra) # 80004646 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a4:	00005097          	auipc	ra,0x5
    800010a8:	eb4080e7          	jalr	-332(ra) # 80005f58 <virtio_disk_init>
    userinit();      // first user process
    800010ac:	00001097          	auipc	ra,0x1
    800010b0:	d28080e7          	jalr	-728(ra) # 80001dd4 <userinit>
    __sync_synchronize();
    800010b4:	0ff0000f          	fence
    started = 1;
    800010b8:	4785                	li	a5,1
    800010ba:	00008717          	auipc	a4,0x8
    800010be:	84f72f23          	sw	a5,-1954(a4) # 80008918 <started>
    800010c2:	b789                	j	80001004 <main+0x56>

00000000800010c4 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    800010c4:	1141                	addi	sp,sp,-16
    800010c6:	e422                	sd	s0,8(sp)
    800010c8:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ca:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010ce:	00008797          	auipc	a5,0x8
    800010d2:	8527b783          	ld	a5,-1966(a5) # 80008920 <kernel_pagetable>
    800010d6:	83b1                	srli	a5,a5,0xc
    800010d8:	577d                	li	a4,-1
    800010da:	177e                	slli	a4,a4,0x3f
    800010dc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010de:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010e2:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010e6:	6422                	ld	s0,8(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret

00000000800010ec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010ec:	7139                	addi	sp,sp,-64
    800010ee:	fc06                	sd	ra,56(sp)
    800010f0:	f822                	sd	s0,48(sp)
    800010f2:	f426                	sd	s1,40(sp)
    800010f4:	f04a                	sd	s2,32(sp)
    800010f6:	ec4e                	sd	s3,24(sp)
    800010f8:	e852                	sd	s4,16(sp)
    800010fa:	e456                	sd	s5,8(sp)
    800010fc:	e05a                	sd	s6,0(sp)
    800010fe:	0080                	addi	s0,sp,64
    80001100:	84aa                	mv	s1,a0
    80001102:	89ae                	mv	s3,a1
    80001104:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80001106:	57fd                	li	a5,-1
    80001108:	83e9                	srli	a5,a5,0x1a
    8000110a:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    8000110c:	4b31                	li	s6,12
  if (va >= MAXVA)
    8000110e:	04b7f263          	bgeu	a5,a1,80001152 <walk+0x66>
    panic("walk");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	ff650513          	addi	a0,a0,-10 # 80008108 <digits+0xc8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001122:	060a8663          	beqz	s5,8000118e <walk+0xa2>
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	abe080e7          	jalr	-1346(ra) # 80000be4 <kalloc>
    8000112e:	84aa                	mv	s1,a0
    80001130:	c529                	beqz	a0,8000117a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001132:	6605                	lui	a2,0x1
    80001134:	4581                	li	a1,0
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	cd2080e7          	jalr	-814(ra) # 80000e08 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000113e:	00c4d793          	srli	a5,s1,0xc
    80001142:	07aa                	slli	a5,a5,0xa
    80001144:	0017e793          	ori	a5,a5,1
    80001148:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    8000114c:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    8000114e:	036a0063          	beq	s4,s6,8000116e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001152:	0149d933          	srl	s2,s3,s4
    80001156:	1ff97913          	andi	s2,s2,511
    8000115a:	090e                	slli	s2,s2,0x3
    8000115c:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    8000115e:	00093483          	ld	s1,0(s2)
    80001162:	0014f793          	andi	a5,s1,1
    80001166:	dfd5                	beqz	a5,80001122 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001168:	80a9                	srli	s1,s1,0xa
    8000116a:	04b2                	slli	s1,s1,0xc
    8000116c:	b7c5                	j	8000114c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000116e:	00c9d513          	srli	a0,s3,0xc
    80001172:	1ff57513          	andi	a0,a0,511
    80001176:	050e                	slli	a0,a0,0x3
    80001178:	9526                	add	a0,a0,s1
}
    8000117a:	70e2                	ld	ra,56(sp)
    8000117c:	7442                	ld	s0,48(sp)
    8000117e:	74a2                	ld	s1,40(sp)
    80001180:	7902                	ld	s2,32(sp)
    80001182:	69e2                	ld	s3,24(sp)
    80001184:	6a42                	ld	s4,16(sp)
    80001186:	6aa2                	ld	s5,8(sp)
    80001188:	6b02                	ld	s6,0(sp)
    8000118a:	6121                	addi	sp,sp,64
    8000118c:	8082                	ret
        return 0;
    8000118e:	4501                	li	a0,0
    80001190:	b7ed                	j	8000117a <walk+0x8e>

0000000080001192 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    80001192:	57fd                	li	a5,-1
    80001194:	83e9                	srli	a5,a5,0x1a
    80001196:	00b7f463          	bgeu	a5,a1,8000119e <walkaddr+0xc>
    return 0;
    8000119a:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000119c:	8082                	ret
{
    8000119e:	1141                	addi	sp,sp,-16
    800011a0:	e406                	sd	ra,8(sp)
    800011a2:	e022                	sd	s0,0(sp)
    800011a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011a6:	4601                	li	a2,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	f44080e7          	jalr	-188(ra) # 800010ec <walk>
  if (pte == 0)
    800011b0:	c105                	beqz	a0,800011d0 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    800011b2:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    800011b4:	0117f693          	andi	a3,a5,17
    800011b8:	4745                	li	a4,17
    return 0;
    800011ba:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    800011bc:	00e68663          	beq	a3,a4,800011c8 <walkaddr+0x36>
}
    800011c0:	60a2                	ld	ra,8(sp)
    800011c2:	6402                	ld	s0,0(sp)
    800011c4:	0141                	addi	sp,sp,16
    800011c6:	8082                	ret
  pa = PTE2PA(*pte);
    800011c8:	83a9                	srli	a5,a5,0xa
    800011ca:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011ce:	bfcd                	j	800011c0 <walkaddr+0x2e>
    return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7fd                	j	800011c0 <walkaddr+0x2e>

00000000800011d4 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011d4:	715d                	addi	sp,sp,-80
    800011d6:	e486                	sd	ra,72(sp)
    800011d8:	e0a2                	sd	s0,64(sp)
    800011da:	fc26                	sd	s1,56(sp)
    800011dc:	f84a                	sd	s2,48(sp)
    800011de:	f44e                	sd	s3,40(sp)
    800011e0:	f052                	sd	s4,32(sp)
    800011e2:	ec56                	sd	s5,24(sp)
    800011e4:	e85a                	sd	s6,16(sp)
    800011e6:	e45e                	sd	s7,8(sp)
    800011e8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    800011ea:	c639                	beqz	a2,80001238 <mappages+0x64>
    800011ec:	8aaa                	mv	s5,a0
    800011ee:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    800011f0:	777d                	lui	a4,0xfffff
    800011f2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011f6:	fff58993          	addi	s3,a1,-1
    800011fa:	99b2                	add	s3,s3,a2
    800011fc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001200:	893e                	mv	s2,a5
    80001202:	40f68a33          	sub	s4,a3,a5
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    80001206:	6b85                	lui	s7,0x1
    80001208:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    8000120c:	4605                	li	a2,1
    8000120e:	85ca                	mv	a1,s2
    80001210:	8556                	mv	a0,s5
    80001212:	00000097          	auipc	ra,0x0
    80001216:	eda080e7          	jalr	-294(ra) # 800010ec <walk>
    8000121a:	cd1d                	beqz	a0,80001258 <mappages+0x84>
    if (*pte & PTE_V)
    8000121c:	611c                	ld	a5,0(a0)
    8000121e:	8b85                	andi	a5,a5,1
    80001220:	e785                	bnez	a5,80001248 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001222:	80b1                	srli	s1,s1,0xc
    80001224:	04aa                	slli	s1,s1,0xa
    80001226:	0164e4b3          	or	s1,s1,s6
    8000122a:	0014e493          	ori	s1,s1,1
    8000122e:	e104                	sd	s1,0(a0)
    if (a == last)
    80001230:	05390063          	beq	s2,s3,80001270 <mappages+0x9c>
    a += PGSIZE;
    80001234:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001236:	bfc9                	j	80001208 <mappages+0x34>
    panic("mappages: size");
    80001238:	00007517          	auipc	a0,0x7
    8000123c:	ed850513          	addi	a0,a0,-296 # 80008110 <digits+0xd0>
    80001240:	fffff097          	auipc	ra,0xfffff
    80001244:	300080e7          	jalr	768(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001248:	00007517          	auipc	a0,0x7
    8000124c:	ed850513          	addi	a0,a0,-296 # 80008120 <digits+0xe0>
    80001250:	fffff097          	auipc	ra,0xfffff
    80001254:	2f0080e7          	jalr	752(ra) # 80000540 <panic>
      return -1;
    80001258:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000125a:	60a6                	ld	ra,72(sp)
    8000125c:	6406                	ld	s0,64(sp)
    8000125e:	74e2                	ld	s1,56(sp)
    80001260:	7942                	ld	s2,48(sp)
    80001262:	79a2                	ld	s3,40(sp)
    80001264:	7a02                	ld	s4,32(sp)
    80001266:	6ae2                	ld	s5,24(sp)
    80001268:	6b42                	ld	s6,16(sp)
    8000126a:	6ba2                	ld	s7,8(sp)
    8000126c:	6161                	addi	sp,sp,80
    8000126e:	8082                	ret
  return 0;
    80001270:	4501                	li	a0,0
    80001272:	b7e5                	j	8000125a <mappages+0x86>

0000000080001274 <kvmmap>:
{
    80001274:	1141                	addi	sp,sp,-16
    80001276:	e406                	sd	ra,8(sp)
    80001278:	e022                	sd	s0,0(sp)
    8000127a:	0800                	addi	s0,sp,16
    8000127c:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000127e:	86b2                	mv	a3,a2
    80001280:	863e                	mv	a2,a5
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f52080e7          	jalr	-174(ra) # 800011d4 <mappages>
    8000128a:	e509                	bnez	a0,80001294 <kvmmap+0x20>
}
    8000128c:	60a2                	ld	ra,8(sp)
    8000128e:	6402                	ld	s0,0(sp)
    80001290:	0141                	addi	sp,sp,16
    80001292:	8082                	ret
    panic("kvmmap");
    80001294:	00007517          	auipc	a0,0x7
    80001298:	e9c50513          	addi	a0,a0,-356 # 80008130 <digits+0xf0>
    8000129c:	fffff097          	auipc	ra,0xfffff
    800012a0:	2a4080e7          	jalr	676(ra) # 80000540 <panic>

00000000800012a4 <kvmmake>:
{
    800012a4:	1101                	addi	sp,sp,-32
    800012a6:	ec06                	sd	ra,24(sp)
    800012a8:	e822                	sd	s0,16(sp)
    800012aa:	e426                	sd	s1,8(sp)
    800012ac:	e04a                	sd	s2,0(sp)
    800012ae:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	934080e7          	jalr	-1740(ra) # 80000be4 <kalloc>
    800012b8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012ba:	6605                	lui	a2,0x1
    800012bc:	4581                	li	a1,0
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	b4a080e7          	jalr	-1206(ra) # 80000e08 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c6:	4719                	li	a4,6
    800012c8:	6685                	lui	a3,0x1
    800012ca:	10000637          	lui	a2,0x10000
    800012ce:	100005b7          	lui	a1,0x10000
    800012d2:	8526                	mv	a0,s1
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	fa0080e7          	jalr	-96(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012dc:	4719                	li	a4,6
    800012de:	6685                	lui	a3,0x1
    800012e0:	10001637          	lui	a2,0x10001
    800012e4:	100015b7          	lui	a1,0x10001
    800012e8:	8526                	mv	a0,s1
    800012ea:	00000097          	auipc	ra,0x0
    800012ee:	f8a080e7          	jalr	-118(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f2:	4719                	li	a4,6
    800012f4:	004006b7          	lui	a3,0x400
    800012f8:	0c000637          	lui	a2,0xc000
    800012fc:	0c0005b7          	lui	a1,0xc000
    80001300:	8526                	mv	a0,s1
    80001302:	00000097          	auipc	ra,0x0
    80001306:	f72080e7          	jalr	-142(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    8000130a:	00007917          	auipc	s2,0x7
    8000130e:	cf690913          	addi	s2,s2,-778 # 80008000 <etext>
    80001312:	4729                	li	a4,10
    80001314:	80007697          	auipc	a3,0x80007
    80001318:	cec68693          	addi	a3,a3,-788 # 8000 <_entry-0x7fff8000>
    8000131c:	4605                	li	a2,1
    8000131e:	067e                	slli	a2,a2,0x1f
    80001320:	85b2                	mv	a1,a2
    80001322:	8526                	mv	a0,s1
    80001324:	00000097          	auipc	ra,0x0
    80001328:	f50080e7          	jalr	-176(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    8000132c:	4719                	li	a4,6
    8000132e:	46c5                	li	a3,17
    80001330:	06ee                	slli	a3,a3,0x1b
    80001332:	412686b3          	sub	a3,a3,s2
    80001336:	864a                	mv	a2,s2
    80001338:	85ca                	mv	a1,s2
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	f38080e7          	jalr	-200(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001344:	4729                	li	a4,10
    80001346:	6685                	lui	a3,0x1
    80001348:	00006617          	auipc	a2,0x6
    8000134c:	cb860613          	addi	a2,a2,-840 # 80007000 <_trampoline>
    80001350:	040005b7          	lui	a1,0x4000
    80001354:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001356:	05b2                	slli	a1,a1,0xc
    80001358:	8526                	mv	a0,s1
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f1a080e7          	jalr	-230(ra) # 80001274 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001362:	8526                	mv	a0,s1
    80001364:	00000097          	auipc	ra,0x0
    80001368:	622080e7          	jalr	1570(ra) # 80001986 <proc_mapstacks>
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6902                	ld	s2,0(sp)
    80001376:	6105                	addi	sp,sp,32
    80001378:	8082                	ret

000000008000137a <kvminit>:
{
    8000137a:	1141                	addi	sp,sp,-16
    8000137c:	e406                	sd	ra,8(sp)
    8000137e:	e022                	sd	s0,0(sp)
    80001380:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001382:	00000097          	auipc	ra,0x0
    80001386:	f22080e7          	jalr	-222(ra) # 800012a4 <kvmmake>
    8000138a:	00007797          	auipc	a5,0x7
    8000138e:	58a7bb23          	sd	a0,1430(a5) # 80008920 <kernel_pagetable>
}
    80001392:	60a2                	ld	ra,8(sp)
    80001394:	6402                	ld	s0,0(sp)
    80001396:	0141                	addi	sp,sp,16
    80001398:	8082                	ret

000000008000139a <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000139a:	715d                	addi	sp,sp,-80
    8000139c:	e486                	sd	ra,72(sp)
    8000139e:	e0a2                	sd	s0,64(sp)
    800013a0:	fc26                	sd	s1,56(sp)
    800013a2:	f84a                	sd	s2,48(sp)
    800013a4:	f44e                	sd	s3,40(sp)
    800013a6:	f052                	sd	s4,32(sp)
    800013a8:	ec56                	sd	s5,24(sp)
    800013aa:	e85a                	sd	s6,16(sp)
    800013ac:	e45e                	sd	s7,8(sp)
    800013ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    800013b0:	03459793          	slli	a5,a1,0x34
    800013b4:	e795                	bnez	a5,800013e0 <uvmunmap+0x46>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	892e                	mv	s2,a1
    800013ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013bc:	0632                	slli	a2,a2,0xc
    800013be:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    800013c2:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013c4:	6b05                	lui	s6,0x1
    800013c6:	0735e263          	bltu	a1,s3,8000142a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800013ca:	60a6                	ld	ra,72(sp)
    800013cc:	6406                	ld	s0,64(sp)
    800013ce:	74e2                	ld	s1,56(sp)
    800013d0:	7942                	ld	s2,48(sp)
    800013d2:	79a2                	ld	s3,40(sp)
    800013d4:	7a02                	ld	s4,32(sp)
    800013d6:	6ae2                	ld	s5,24(sp)
    800013d8:	6b42                	ld	s6,16(sp)
    800013da:	6ba2                	ld	s7,8(sp)
    800013dc:	6161                	addi	sp,sp,80
    800013de:	8082                	ret
    panic("uvmunmap: not aligned");
    800013e0:	00007517          	auipc	a0,0x7
    800013e4:	d5850513          	addi	a0,a0,-680 # 80008138 <digits+0xf8>
    800013e8:	fffff097          	auipc	ra,0xfffff
    800013ec:	158080e7          	jalr	344(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800013f0:	00007517          	auipc	a0,0x7
    800013f4:	d6050513          	addi	a0,a0,-672 # 80008150 <digits+0x110>
    800013f8:	fffff097          	auipc	ra,0xfffff
    800013fc:	148080e7          	jalr	328(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001400:	00007517          	auipc	a0,0x7
    80001404:	d6050513          	addi	a0,a0,-672 # 80008160 <digits+0x120>
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	138080e7          	jalr	312(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001410:	00007517          	auipc	a0,0x7
    80001414:	d6850513          	addi	a0,a0,-664 # 80008178 <digits+0x138>
    80001418:	fffff097          	auipc	ra,0xfffff
    8000141c:	128080e7          	jalr	296(ra) # 80000540 <panic>
    *pte = 0;
    80001420:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001424:	995a                	add	s2,s2,s6
    80001426:	fb3972e3          	bgeu	s2,s3,800013ca <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    8000142a:	4601                	li	a2,0
    8000142c:	85ca                	mv	a1,s2
    8000142e:	8552                	mv	a0,s4
    80001430:	00000097          	auipc	ra,0x0
    80001434:	cbc080e7          	jalr	-836(ra) # 800010ec <walk>
    80001438:	84aa                	mv	s1,a0
    8000143a:	d95d                	beqz	a0,800013f0 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000143c:	6108                	ld	a0,0(a0)
    8000143e:	00157793          	andi	a5,a0,1
    80001442:	dfdd                	beqz	a5,80001400 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001444:	3ff57793          	andi	a5,a0,1023
    80001448:	fd7784e3          	beq	a5,s7,80001410 <uvmunmap+0x76>
    if (do_free)
    8000144c:	fc0a8ae3          	beqz	s5,80001420 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001450:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001452:	0532                	slli	a0,a0,0xc
    80001454:	fffff097          	auipc	ra,0xfffff
    80001458:	60c080e7          	jalr	1548(ra) # 80000a60 <kfree>
    8000145c:	b7d1                	j	80001420 <uvmunmap+0x86>

000000008000145e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000145e:	1101                	addi	sp,sp,-32
    80001460:	ec06                	sd	ra,24(sp)
    80001462:	e822                	sd	s0,16(sp)
    80001464:	e426                	sd	s1,8(sp)
    80001466:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	77c080e7          	jalr	1916(ra) # 80000be4 <kalloc>
    80001470:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001472:	c519                	beqz	a0,80001480 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	990080e7          	jalr	-1648(ra) # 80000e08 <memset>
  return pagetable;
}
    80001480:	8526                	mv	a0,s1
    80001482:	60e2                	ld	ra,24(sp)
    80001484:	6442                	ld	s0,16(sp)
    80001486:	64a2                	ld	s1,8(sp)
    80001488:	6105                	addi	sp,sp,32
    8000148a:	8082                	ret

000000008000148c <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000148c:	7179                	addi	sp,sp,-48
    8000148e:	f406                	sd	ra,40(sp)
    80001490:	f022                	sd	s0,32(sp)
    80001492:	ec26                	sd	s1,24(sp)
    80001494:	e84a                	sd	s2,16(sp)
    80001496:	e44e                	sd	s3,8(sp)
    80001498:	e052                	sd	s4,0(sp)
    8000149a:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    8000149c:	6785                	lui	a5,0x1
    8000149e:	04f67863          	bgeu	a2,a5,800014ee <uvmfirst+0x62>
    800014a2:	8a2a                	mv	s4,a0
    800014a4:	89ae                	mv	s3,a1
    800014a6:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	73c080e7          	jalr	1852(ra) # 80000be4 <kalloc>
    800014b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014b2:	6605                	lui	a2,0x1
    800014b4:	4581                	li	a1,0
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	952080e7          	jalr	-1710(ra) # 80000e08 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800014be:	4779                	li	a4,30
    800014c0:	86ca                	mv	a3,s2
    800014c2:	6605                	lui	a2,0x1
    800014c4:	4581                	li	a1,0
    800014c6:	8552                	mv	a0,s4
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	d0c080e7          	jalr	-756(ra) # 800011d4 <mappages>
  memmove(mem, src, sz);
    800014d0:	8626                	mv	a2,s1
    800014d2:	85ce                	mv	a1,s3
    800014d4:	854a                	mv	a0,s2
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	98e080e7          	jalr	-1650(ra) # 80000e64 <memmove>
}
    800014de:	70a2                	ld	ra,40(sp)
    800014e0:	7402                	ld	s0,32(sp)
    800014e2:	64e2                	ld	s1,24(sp)
    800014e4:	6942                	ld	s2,16(sp)
    800014e6:	69a2                	ld	s3,8(sp)
    800014e8:	6a02                	ld	s4,0(sp)
    800014ea:	6145                	addi	sp,sp,48
    800014ec:	8082                	ret
    panic("uvmfirst: more than a page");
    800014ee:	00007517          	auipc	a0,0x7
    800014f2:	ca250513          	addi	a0,a0,-862 # 80008190 <digits+0x150>
    800014f6:	fffff097          	auipc	ra,0xfffff
    800014fa:	04a080e7          	jalr	74(ra) # 80000540 <panic>

00000000800014fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014fe:	1101                	addi	sp,sp,-32
    80001500:	ec06                	sd	ra,24(sp)
    80001502:	e822                	sd	s0,16(sp)
    80001504:	e426                	sd	s1,8(sp)
    80001506:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    80001508:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    8000150a:	00b67d63          	bgeu	a2,a1,80001524 <uvmdealloc+0x26>
    8000150e:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001510:	6785                	lui	a5,0x1
    80001512:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001514:	00f60733          	add	a4,a2,a5
    80001518:	76fd                	lui	a3,0xfffff
    8000151a:	8f75                	and	a4,a4,a3
    8000151c:	97ae                	add	a5,a5,a1
    8000151e:	8ff5                	and	a5,a5,a3
    80001520:	00f76863          	bltu	a4,a5,80001530 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001524:	8526                	mv	a0,s1
    80001526:	60e2                	ld	ra,24(sp)
    80001528:	6442                	ld	s0,16(sp)
    8000152a:	64a2                	ld	s1,8(sp)
    8000152c:	6105                	addi	sp,sp,32
    8000152e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001530:	8f99                	sub	a5,a5,a4
    80001532:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001534:	4685                	li	a3,1
    80001536:	0007861b          	sext.w	a2,a5
    8000153a:	85ba                	mv	a1,a4
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	e5e080e7          	jalr	-418(ra) # 8000139a <uvmunmap>
    80001544:	b7c5                	j	80001524 <uvmdealloc+0x26>

0000000080001546 <uvmalloc>:
  if (newsz < oldsz)
    80001546:	0ab66563          	bltu	a2,a1,800015f0 <uvmalloc+0xaa>
{
    8000154a:	7139                	addi	sp,sp,-64
    8000154c:	fc06                	sd	ra,56(sp)
    8000154e:	f822                	sd	s0,48(sp)
    80001550:	f426                	sd	s1,40(sp)
    80001552:	f04a                	sd	s2,32(sp)
    80001554:	ec4e                	sd	s3,24(sp)
    80001556:	e852                	sd	s4,16(sp)
    80001558:	e456                	sd	s5,8(sp)
    8000155a:	e05a                	sd	s6,0(sp)
    8000155c:	0080                	addi	s0,sp,64
    8000155e:	8aaa                	mv	s5,a0
    80001560:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001562:	6785                	lui	a5,0x1
    80001564:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001566:	95be                	add	a1,a1,a5
    80001568:	77fd                	lui	a5,0xfffff
    8000156a:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000156e:	08c9f363          	bgeu	s3,a2,800015f4 <uvmalloc+0xae>
    80001572:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001574:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001578:	fffff097          	auipc	ra,0xfffff
    8000157c:	66c080e7          	jalr	1644(ra) # 80000be4 <kalloc>
    80001580:	84aa                	mv	s1,a0
    if (mem == 0)
    80001582:	c51d                	beqz	a0,800015b0 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001584:	6605                	lui	a2,0x1
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	880080e7          	jalr	-1920(ra) # 80000e08 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001590:	875a                	mv	a4,s6
    80001592:	86a6                	mv	a3,s1
    80001594:	6605                	lui	a2,0x1
    80001596:	85ca                	mv	a1,s2
    80001598:	8556                	mv	a0,s5
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	c3a080e7          	jalr	-966(ra) # 800011d4 <mappages>
    800015a2:	e90d                	bnez	a0,800015d4 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800015a4:	6785                	lui	a5,0x1
    800015a6:	993e                	add	s2,s2,a5
    800015a8:	fd4968e3          	bltu	s2,s4,80001578 <uvmalloc+0x32>
  return newsz;
    800015ac:	8552                	mv	a0,s4
    800015ae:	a809                	j	800015c0 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015b0:	864e                	mv	a2,s3
    800015b2:	85ca                	mv	a1,s2
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f48080e7          	jalr	-184(ra) # 800014fe <uvmdealloc>
      return 0;
    800015be:	4501                	li	a0,0
}
    800015c0:	70e2                	ld	ra,56(sp)
    800015c2:	7442                	ld	s0,48(sp)
    800015c4:	74a2                	ld	s1,40(sp)
    800015c6:	7902                	ld	s2,32(sp)
    800015c8:	69e2                	ld	s3,24(sp)
    800015ca:	6a42                	ld	s4,16(sp)
    800015cc:	6aa2                	ld	s5,8(sp)
    800015ce:	6b02                	ld	s6,0(sp)
    800015d0:	6121                	addi	sp,sp,64
    800015d2:	8082                	ret
      kfree(mem);
    800015d4:	8526                	mv	a0,s1
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	48a080e7          	jalr	1162(ra) # 80000a60 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015de:	864e                	mv	a2,s3
    800015e0:	85ca                	mv	a1,s2
    800015e2:	8556                	mv	a0,s5
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	f1a080e7          	jalr	-230(ra) # 800014fe <uvmdealloc>
      return 0;
    800015ec:	4501                	li	a0,0
    800015ee:	bfc9                	j	800015c0 <uvmalloc+0x7a>
    return oldsz;
    800015f0:	852e                	mv	a0,a1
}
    800015f2:	8082                	ret
  return newsz;
    800015f4:	8532                	mv	a0,a2
    800015f6:	b7e9                	j	800015c0 <uvmalloc+0x7a>

00000000800015f8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800015f8:	7179                	addi	sp,sp,-48
    800015fa:	f406                	sd	ra,40(sp)
    800015fc:	f022                	sd	s0,32(sp)
    800015fe:	ec26                	sd	s1,24(sp)
    80001600:	e84a                	sd	s2,16(sp)
    80001602:	e44e                	sd	s3,8(sp)
    80001604:	e052                	sd	s4,0(sp)
    80001606:	1800                	addi	s0,sp,48
    80001608:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    8000160a:	84aa                	mv	s1,a0
    8000160c:	6905                	lui	s2,0x1
    8000160e:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001610:	4985                	li	s3,1
    80001612:	a829                	j	8000162c <freewalk+0x34>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001614:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001616:	00c79513          	slli	a0,a5,0xc
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	fde080e7          	jalr	-34(ra) # 800015f8 <freewalk>
      pagetable[i] = 0;
    80001622:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    80001626:	04a1                	addi	s1,s1,8
    80001628:	03248163          	beq	s1,s2,8000164a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000162c:	609c                	ld	a5,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    8000162e:	00f7f713          	andi	a4,a5,15
    80001632:	ff3701e3          	beq	a4,s3,80001614 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001636:	8b85                	andi	a5,a5,1
    80001638:	d7fd                	beqz	a5,80001626 <freewalk+0x2e>
    {
      panic("freewalk: leaf");
    8000163a:	00007517          	auipc	a0,0x7
    8000163e:	b7650513          	addi	a0,a0,-1162 # 800081b0 <digits+0x170>
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	efe080e7          	jalr	-258(ra) # 80000540 <panic>
    }
  }
  kfree((void *)pagetable);
    8000164a:	8552                	mv	a0,s4
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	414080e7          	jalr	1044(ra) # 80000a60 <kfree>
}
    80001654:	70a2                	ld	ra,40(sp)
    80001656:	7402                	ld	s0,32(sp)
    80001658:	64e2                	ld	s1,24(sp)
    8000165a:	6942                	ld	s2,16(sp)
    8000165c:	69a2                	ld	s3,8(sp)
    8000165e:	6a02                	ld	s4,0(sp)
    80001660:	6145                	addi	sp,sp,48
    80001662:	8082                	ret

0000000080001664 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001664:	1101                	addi	sp,sp,-32
    80001666:	ec06                	sd	ra,24(sp)
    80001668:	e822                	sd	s0,16(sp)
    8000166a:	e426                	sd	s1,8(sp)
    8000166c:	1000                	addi	s0,sp,32
    8000166e:	84aa                	mv	s1,a0
  if (sz > 0)
    80001670:	e999                	bnez	a1,80001686 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001672:	8526                	mv	a0,s1
    80001674:	00000097          	auipc	ra,0x0
    80001678:	f84080e7          	jalr	-124(ra) # 800015f8 <freewalk>
}
    8000167c:	60e2                	ld	ra,24(sp)
    8000167e:	6442                	ld	s0,16(sp)
    80001680:	64a2                	ld	s1,8(sp)
    80001682:	6105                	addi	sp,sp,32
    80001684:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80001686:	6785                	lui	a5,0x1
    80001688:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000168a:	95be                	add	a1,a1,a5
    8000168c:	4685                	li	a3,1
    8000168e:	00c5d613          	srli	a2,a1,0xc
    80001692:	4581                	li	a1,0
    80001694:	00000097          	auipc	ra,0x0
    80001698:	d06080e7          	jalr	-762(ra) # 8000139a <uvmunmap>
    8000169c:	bfd9                	j	80001672 <uvmfree+0xe>

000000008000169e <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  
  for (i = 0; i < sz; i += PGSIZE)
    8000169e:	ca55                	beqz	a2,80001752 <uvmcopy+0xb4>
{
    800016a0:	7139                	addi	sp,sp,-64
    800016a2:	fc06                	sd	ra,56(sp)
    800016a4:	f822                	sd	s0,48(sp)
    800016a6:	f426                	sd	s1,40(sp)
    800016a8:	f04a                	sd	s2,32(sp)
    800016aa:	ec4e                	sd	s3,24(sp)
    800016ac:	e852                	sd	s4,16(sp)
    800016ae:	e456                	sd	s5,8(sp)
    800016b0:	e05a                	sd	s6,0(sp)
    800016b2:	0080                	addi	s0,sp,64
    800016b4:	8b2a                	mv	s6,a0
    800016b6:	8aae                	mv	s5,a1
    800016b8:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    800016ba:	4901                	li	s2,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    800016bc:	4601                	li	a2,0
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	a2a080e7          	jalr	-1494(ra) # 800010ec <walk>
    800016ca:	c121                	beqz	a0,8000170a <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    800016cc:	6118                	ld	a4,0(a0)
    800016ce:	00177793          	andi	a5,a4,1
    800016d2:	c7a1                	beqz	a5,8000171a <uvmcopy+0x7c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016d4:	00a75993          	srli	s3,a4,0xa
    800016d8:	09b2                	slli	s3,s3,0xc
    *pte = (*pte) & (~PTE_W);
    800016da:	ffb77493          	andi	s1,a4,-5
    800016de:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);
    increse(pa);
    800016e0:	854e                	mv	a0,s3
    800016e2:	fffff097          	auipc	ra,0xfffff
    800016e6:	306080e7          	jalr	774(ra) # 800009e8 <increse>
    // if((mem = kalloc()) == 0)
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);

    if (mappages(new, i, PGSIZE, (uint64)pa, flags) != 0)
    800016ea:	3fb4f713          	andi	a4,s1,1019
    800016ee:	86ce                	mv	a3,s3
    800016f0:	6605                	lui	a2,0x1
    800016f2:	85ca                	mv	a1,s2
    800016f4:	8556                	mv	a0,s5
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	ade080e7          	jalr	-1314(ra) # 800011d4 <mappages>
    800016fe:	e515                	bnez	a0,8000172a <uvmcopy+0x8c>
  for (i = 0; i < sz; i += PGSIZE)
    80001700:	6785                	lui	a5,0x1
    80001702:	993e                	add	s2,s2,a5
    80001704:	fb496ce3          	bltu	s2,s4,800016bc <uvmcopy+0x1e>
    80001708:	a81d                	j	8000173e <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    8000170a:	00007517          	auipc	a0,0x7
    8000170e:	ab650513          	addi	a0,a0,-1354 # 800081c0 <digits+0x180>
    80001712:	fffff097          	auipc	ra,0xfffff
    80001716:	e2e080e7          	jalr	-466(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000171a:	00007517          	auipc	a0,0x7
    8000171e:	ac650513          	addi	a0,a0,-1338 # 800081e0 <digits+0x1a0>
    80001722:	fffff097          	auipc	ra,0xfffff
    80001726:	e1e080e7          	jalr	-482(ra) # 80000540 <panic>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000172a:	4685                	li	a3,1
    8000172c:	00c95613          	srli	a2,s2,0xc
    80001730:	4581                	li	a1,0
    80001732:	8556                	mv	a0,s5
    80001734:	00000097          	auipc	ra,0x0
    80001738:	c66080e7          	jalr	-922(ra) # 8000139a <uvmunmap>
  return -1;
    8000173c:	557d                	li	a0,-1
}
    8000173e:	70e2                	ld	ra,56(sp)
    80001740:	7442                	ld	s0,48(sp)
    80001742:	74a2                	ld	s1,40(sp)
    80001744:	7902                	ld	s2,32(sp)
    80001746:	69e2                	ld	s3,24(sp)
    80001748:	6a42                	ld	s4,16(sp)
    8000174a:	6aa2                	ld	s5,8(sp)
    8000174c:	6b02                	ld	s6,0(sp)
    8000174e:	6121                	addi	sp,sp,64
    80001750:	8082                	ret
  return 0;
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret

0000000080001756 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001756:	1141                	addi	sp,sp,-16
    80001758:	e406                	sd	ra,8(sp)
    8000175a:	e022                	sd	s0,0(sp)
    8000175c:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    8000175e:	4601                	li	a2,0
    80001760:	00000097          	auipc	ra,0x0
    80001764:	98c080e7          	jalr	-1652(ra) # 800010ec <walk>
  if (pte == 0)
    80001768:	c901                	beqz	a0,80001778 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000176a:	611c                	ld	a5,0(a0)
    8000176c:	9bbd                	andi	a5,a5,-17
    8000176e:	e11c                	sd	a5,0(a0)
}
    80001770:	60a2                	ld	ra,8(sp)
    80001772:	6402                	ld	s0,0(sp)
    80001774:	0141                	addi	sp,sp,16
    80001776:	8082                	ret
    panic("uvmclear");
    80001778:	00007517          	auipc	a0,0x7
    8000177c:	a8850513          	addi	a0,a0,-1400 # 80008200 <digits+0x1c0>
    80001780:	fffff097          	auipc	ra,0xfffff
    80001784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>

0000000080001788 <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001788:	cad1                	beqz	a3,8000181c <copyout+0x94>
{
    8000178a:	711d                	addi	sp,sp,-96
    8000178c:	ec86                	sd	ra,88(sp)
    8000178e:	e8a2                	sd	s0,80(sp)
    80001790:	e4a6                	sd	s1,72(sp)
    80001792:	e0ca                	sd	s2,64(sp)
    80001794:	fc4e                	sd	s3,56(sp)
    80001796:	f852                	sd	s4,48(sp)
    80001798:	f456                	sd	s5,40(sp)
    8000179a:	f05a                	sd	s6,32(sp)
    8000179c:	ec5e                	sd	s7,24(sp)
    8000179e:	e862                	sd	s8,16(sp)
    800017a0:	e466                	sd	s9,8(sp)
    800017a2:	1080                	addi	s0,sp,96
    800017a4:	8baa                	mv	s7,a0
    800017a6:	8aae                	mv	s5,a1
    800017a8:	8b32                	mv	s6,a2
    800017aa:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800017ac:	74fd                	lui	s1,0xfffff
    800017ae:	8ced                	and	s1,s1,a1
    if (va0 > MAXVA)
    800017b0:	4785                	li	a5,1
    800017b2:	179a                	slli	a5,a5,0x26
    800017b4:	0697e663          	bltu	a5,s1,80001820 <copyout+0x98>
    800017b8:	6c85                	lui	s9,0x1
    800017ba:	04000c37          	lui	s8,0x4000
    800017be:	0c05                	addi	s8,s8,1 # 4000001 <_entry-0x7bffffff>
    800017c0:	0c32                	slli	s8,s8,0xc
    800017c2:	a025                	j	800017ea <copyout+0x62>
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017c4:	409a84b3          	sub	s1,s5,s1
    800017c8:	0009061b          	sext.w	a2,s2
    800017cc:	85da                	mv	a1,s6
    800017ce:	9526                	add	a0,a0,s1
    800017d0:	fffff097          	auipc	ra,0xfffff
    800017d4:	694080e7          	jalr	1684(ra) # 80000e64 <memmove>

    len -= n;
    800017d8:	412989b3          	sub	s3,s3,s2
    src += n;
    800017dc:	9b4a                	add	s6,s6,s2
  while (len > 0)
    800017de:	02098d63          	beqz	s3,80001818 <copyout+0x90>
    if (va0 > MAXVA)
    800017e2:	058a0163          	beq	s4,s8,80001824 <copyout+0x9c>
    va0 = PGROUNDDOWN(dstva);
    800017e6:	84d2                	mv	s1,s4
    dstva = va0 + PGSIZE;
    800017e8:	8ad2                	mv	s5,s4
    if (cowfault(pagetable, va0) < 0)
    800017ea:	85a6                	mv	a1,s1
    800017ec:	855e                	mv	a0,s7
    800017ee:	00001097          	auipc	ra,0x1
    800017f2:	fc4080e7          	jalr	-60(ra) # 800027b2 <cowfault>
    800017f6:	02054963          	bltz	a0,80001828 <copyout+0xa0>
    pa0 = walkaddr(pagetable, va0);
    800017fa:	85a6                	mv	a1,s1
    800017fc:	855e                	mv	a0,s7
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	994080e7          	jalr	-1644(ra) # 80001192 <walkaddr>
    if (pa0 == 0)
    80001806:	cd1d                	beqz	a0,80001844 <copyout+0xbc>
    n = PGSIZE - (dstva - va0);
    80001808:	01948a33          	add	s4,s1,s9
    8000180c:	415a0933          	sub	s2,s4,s5
    80001810:	fb29fae3          	bgeu	s3,s2,800017c4 <copyout+0x3c>
    80001814:	894e                	mv	s2,s3
    80001816:	b77d                	j	800017c4 <copyout+0x3c>
  }
  return 0;
    80001818:	4501                	li	a0,0
    8000181a:	a801                	j	8000182a <copyout+0xa2>
    8000181c:	4501                	li	a0,0
}
    8000181e:	8082                	ret
      return -1;
    80001820:	557d                	li	a0,-1
    80001822:	a021                	j	8000182a <copyout+0xa2>
    80001824:	557d                	li	a0,-1
    80001826:	a011                	j	8000182a <copyout+0xa2>
      return -1;
    80001828:	557d                	li	a0,-1
}
    8000182a:	60e6                	ld	ra,88(sp)
    8000182c:	6446                	ld	s0,80(sp)
    8000182e:	64a6                	ld	s1,72(sp)
    80001830:	6906                	ld	s2,64(sp)
    80001832:	79e2                	ld	s3,56(sp)
    80001834:	7a42                	ld	s4,48(sp)
    80001836:	7aa2                	ld	s5,40(sp)
    80001838:	7b02                	ld	s6,32(sp)
    8000183a:	6be2                	ld	s7,24(sp)
    8000183c:	6c42                	ld	s8,16(sp)
    8000183e:	6ca2                	ld	s9,8(sp)
    80001840:	6125                	addi	sp,sp,96
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
    80001846:	b7d5                	j	8000182a <copyout+0xa2>

0000000080001848 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001848:	caa5                	beqz	a3,800018b8 <copyin+0x70>
{
    8000184a:	715d                	addi	sp,sp,-80
    8000184c:	e486                	sd	ra,72(sp)
    8000184e:	e0a2                	sd	s0,64(sp)
    80001850:	fc26                	sd	s1,56(sp)
    80001852:	f84a                	sd	s2,48(sp)
    80001854:	f44e                	sd	s3,40(sp)
    80001856:	f052                	sd	s4,32(sp)
    80001858:	ec56                	sd	s5,24(sp)
    8000185a:	e85a                	sd	s6,16(sp)
    8000185c:	e45e                	sd	s7,8(sp)
    8000185e:	e062                	sd	s8,0(sp)
    80001860:	0880                	addi	s0,sp,80
    80001862:	8b2a                	mv	s6,a0
    80001864:	8a2e                	mv	s4,a1
    80001866:	8c32                	mv	s8,a2
    80001868:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    8000186a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186c:	6a85                	lui	s5,0x1
    8000186e:	a01d                	j	80001894 <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001870:	018505b3          	add	a1,a0,s8
    80001874:	0004861b          	sext.w	a2,s1
    80001878:	412585b3          	sub	a1,a1,s2
    8000187c:	8552                	mv	a0,s4
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	5e6080e7          	jalr	1510(ra) # 80000e64 <memmove>

    len -= n;
    80001886:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000188a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000188c:	01590c33          	add	s8,s2,s5
  while (len > 0)
    80001890:	02098263          	beqz	s3,800018b4 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001894:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001898:	85ca                	mv	a1,s2
    8000189a:	855a                	mv	a0,s6
    8000189c:	00000097          	auipc	ra,0x0
    800018a0:	8f6080e7          	jalr	-1802(ra) # 80001192 <walkaddr>
    if (pa0 == 0)
    800018a4:	cd01                	beqz	a0,800018bc <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a6:	418904b3          	sub	s1,s2,s8
    800018aa:	94d6                	add	s1,s1,s5
    800018ac:	fc99f2e3          	bgeu	s3,s1,80001870 <copyin+0x28>
    800018b0:	84ce                	mv	s1,s3
    800018b2:	bf7d                	j	80001870 <copyin+0x28>
  }
  return 0;
    800018b4:	4501                	li	a0,0
    800018b6:	a021                	j	800018be <copyin+0x76>
    800018b8:	4501                	li	a0,0
}
    800018ba:	8082                	ret
      return -1;
    800018bc:	557d                	li	a0,-1
}
    800018be:	60a6                	ld	ra,72(sp)
    800018c0:	6406                	ld	s0,64(sp)
    800018c2:	74e2                	ld	s1,56(sp)
    800018c4:	7942                	ld	s2,48(sp)
    800018c6:	79a2                	ld	s3,40(sp)
    800018c8:	7a02                	ld	s4,32(sp)
    800018ca:	6ae2                	ld	s5,24(sp)
    800018cc:	6b42                	ld	s6,16(sp)
    800018ce:	6ba2                	ld	s7,8(sp)
    800018d0:	6c02                	ld	s8,0(sp)
    800018d2:	6161                	addi	sp,sp,80
    800018d4:	8082                	ret

00000000800018d6 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    800018d6:	c2dd                	beqz	a3,8000197c <copyinstr+0xa6>
{
    800018d8:	715d                	addi	sp,sp,-80
    800018da:	e486                	sd	ra,72(sp)
    800018dc:	e0a2                	sd	s0,64(sp)
    800018de:	fc26                	sd	s1,56(sp)
    800018e0:	f84a                	sd	s2,48(sp)
    800018e2:	f44e                	sd	s3,40(sp)
    800018e4:	f052                	sd	s4,32(sp)
    800018e6:	ec56                	sd	s5,24(sp)
    800018e8:	e85a                	sd	s6,16(sp)
    800018ea:	e45e                	sd	s7,8(sp)
    800018ec:	0880                	addi	s0,sp,80
    800018ee:	8a2a                	mv	s4,a0
    800018f0:	8b2e                	mv	s6,a1
    800018f2:	8bb2                	mv	s7,a2
    800018f4:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800018f6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f8:	6985                	lui	s3,0x1
    800018fa:	a02d                	j	80001924 <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    800018fc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001900:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001902:	37fd                	addiw	a5,a5,-1
    80001904:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001908:	60a6                	ld	ra,72(sp)
    8000190a:	6406                	ld	s0,64(sp)
    8000190c:	74e2                	ld	s1,56(sp)
    8000190e:	7942                	ld	s2,48(sp)
    80001910:	79a2                	ld	s3,40(sp)
    80001912:	7a02                	ld	s4,32(sp)
    80001914:	6ae2                	ld	s5,24(sp)
    80001916:	6b42                	ld	s6,16(sp)
    80001918:	6ba2                	ld	s7,8(sp)
    8000191a:	6161                	addi	sp,sp,80
    8000191c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191e:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001922:	c8a9                	beqz	s1,80001974 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001924:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001928:	85ca                	mv	a1,s2
    8000192a:	8552                	mv	a0,s4
    8000192c:	00000097          	auipc	ra,0x0
    80001930:	866080e7          	jalr	-1946(ra) # 80001192 <walkaddr>
    if (pa0 == 0)
    80001934:	c131                	beqz	a0,80001978 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001936:	417906b3          	sub	a3,s2,s7
    8000193a:	96ce                	add	a3,a3,s3
    8000193c:	00d4f363          	bgeu	s1,a3,80001942 <copyinstr+0x6c>
    80001940:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001942:	955e                	add	a0,a0,s7
    80001944:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001948:	daf9                	beqz	a3,8000191e <copyinstr+0x48>
    8000194a:	87da                	mv	a5,s6
      if (*p == '\0')
    8000194c:	41650633          	sub	a2,a0,s6
    80001950:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdbba4f>
    80001954:	95da                	add	a1,a1,s6
    while (n > 0)
    80001956:	96da                	add	a3,a3,s6
      if (*p == '\0')
    80001958:	00f60733          	add	a4,a2,a5
    8000195c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbba50>
    80001960:	df51                	beqz	a4,800018fc <copyinstr+0x26>
        *dst = *p;
    80001962:	00e78023          	sb	a4,0(a5)
      --max;
    80001966:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000196a:	0785                	addi	a5,a5,1
    while (n > 0)
    8000196c:	fed796e3          	bne	a5,a3,80001958 <copyinstr+0x82>
      dst++;
    80001970:	8b3e                	mv	s6,a5
    80001972:	b775                	j	8000191e <copyinstr+0x48>
    80001974:	4781                	li	a5,0
    80001976:	b771                	j	80001902 <copyinstr+0x2c>
      return -1;
    80001978:	557d                	li	a0,-1
    8000197a:	b779                	j	80001908 <copyinstr+0x32>
  int got_null = 0;
    8000197c:	4781                	li	a5,0
  if (got_null)
    8000197e:	37fd                	addiw	a5,a5,-1
    80001980:	0007851b          	sext.w	a0,a5
}
    80001984:	8082                	ret

0000000080001986 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001986:	7139                	addi	sp,sp,-64
    80001988:	fc06                	sd	ra,56(sp)
    8000198a:	f822                	sd	s0,48(sp)
    8000198c:	f426                	sd	s1,40(sp)
    8000198e:	f04a                	sd	s2,32(sp)
    80001990:	ec4e                	sd	s3,24(sp)
    80001992:	e852                	sd	s4,16(sp)
    80001994:	e456                	sd	s5,8(sp)
    80001996:	e05a                	sd	s6,0(sp)
    80001998:	0080                	addi	s0,sp,64
    8000199a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199c:	0022f497          	auipc	s1,0x22f
    800019a0:	63448493          	addi	s1,s1,1588 # 80230fd0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a4:	8b26                	mv	s6,s1
    800019a6:	00006a97          	auipc	s5,0x6
    800019aa:	65aa8a93          	addi	s5,s5,1626 # 80008000 <etext>
    800019ae:	04000937          	lui	s2,0x4000
    800019b2:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019b4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b6:	00237a17          	auipc	s4,0x237
    800019ba:	81aa0a13          	addi	s4,s4,-2022 # 802381d0 <tickslock>
    char *pa = kalloc();
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	226080e7          	jalr	550(ra) # 80000be4 <kalloc>
    800019c6:	862a                	mv	a2,a0
    if(pa == 0)
    800019c8:	c131                	beqz	a0,80001a0c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019ca:	416485b3          	sub	a1,s1,s6
    800019ce:	858d                	srai	a1,a1,0x3
    800019d0:	000ab783          	ld	a5,0(s5)
    800019d4:	02f585b3          	mul	a1,a1,a5
    800019d8:	2585                	addiw	a1,a1,1
    800019da:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019de:	4719                	li	a4,6
    800019e0:	6685                	lui	a3,0x1
    800019e2:	40b905b3          	sub	a1,s2,a1
    800019e6:	854e                	mv	a0,s3
    800019e8:	00000097          	auipc	ra,0x0
    800019ec:	88c080e7          	jalr	-1908(ra) # 80001274 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f0:	1c848493          	addi	s1,s1,456
    800019f4:	fd4495e3          	bne	s1,s4,800019be <proc_mapstacks+0x38>
  }
}
    800019f8:	70e2                	ld	ra,56(sp)
    800019fa:	7442                	ld	s0,48(sp)
    800019fc:	74a2                	ld	s1,40(sp)
    800019fe:	7902                	ld	s2,32(sp)
    80001a00:	69e2                	ld	s3,24(sp)
    80001a02:	6a42                	ld	s4,16(sp)
    80001a04:	6aa2                	ld	s5,8(sp)
    80001a06:	6b02                	ld	s6,0(sp)
    80001a08:	6121                	addi	sp,sp,64
    80001a0a:	8082                	ret
      panic("kalloc");
    80001a0c:	00007517          	auipc	a0,0x7
    80001a10:	80450513          	addi	a0,a0,-2044 # 80008210 <digits+0x1d0>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	b2c080e7          	jalr	-1236(ra) # 80000540 <panic>

0000000080001a1c <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a1c:	7139                	addi	sp,sp,-64
    80001a1e:	fc06                	sd	ra,56(sp)
    80001a20:	f822                	sd	s0,48(sp)
    80001a22:	f426                	sd	s1,40(sp)
    80001a24:	f04a                	sd	s2,32(sp)
    80001a26:	ec4e                	sd	s3,24(sp)
    80001a28:	e852                	sd	s4,16(sp)
    80001a2a:	e456                	sd	s5,8(sp)
    80001a2c:	e05a                	sd	s6,0(sp)
    80001a2e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a30:	00006597          	auipc	a1,0x6
    80001a34:	7e858593          	addi	a1,a1,2024 # 80008218 <digits+0x1d8>
    80001a38:	0022f517          	auipc	a0,0x22f
    80001a3c:	16850513          	addi	a0,a0,360 # 80230ba0 <pid_lock>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	23c080e7          	jalr	572(ra) # 80000c7c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	7d858593          	addi	a1,a1,2008 # 80008220 <digits+0x1e0>
    80001a50:	0022f517          	auipc	a0,0x22f
    80001a54:	16850513          	addi	a0,a0,360 # 80230bb8 <wait_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	224080e7          	jalr	548(ra) # 80000c7c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	0022f497          	auipc	s1,0x22f
    80001a64:	57048493          	addi	s1,s1,1392 # 80230fd0 <proc>
      initlock(&p->lock, "proc");
    80001a68:	00006b17          	auipc	s6,0x6
    80001a6c:	7c8b0b13          	addi	s6,s6,1992 # 80008230 <digits+0x1f0>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a70:	8aa6                	mv	s5,s1
    80001a72:	00006a17          	auipc	s4,0x6
    80001a76:	58ea0a13          	addi	s4,s4,1422 # 80008000 <etext>
    80001a7a:	04000937          	lui	s2,0x4000
    80001a7e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a80:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a82:	00236997          	auipc	s3,0x236
    80001a86:	74e98993          	addi	s3,s3,1870 # 802381d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a8a:	85da                	mv	a1,s6
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	1ee080e7          	jalr	494(ra) # 80000c7c <initlock>
      p->state = UNUSED;
    80001a96:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a9a:	415487b3          	sub	a5,s1,s5
    80001a9e:	878d                	srai	a5,a5,0x3
    80001aa0:	000a3703          	ld	a4,0(s4)
    80001aa4:	02e787b3          	mul	a5,a5,a4
    80001aa8:	2785                	addiw	a5,a5,1
    80001aaa:	00d7979b          	slliw	a5,a5,0xd
    80001aae:	40f907b3          	sub	a5,s2,a5
    80001ab2:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab4:	1c848493          	addi	s1,s1,456
    80001ab8:	fd3499e3          	bne	s1,s3,80001a8a <procinit+0x6e>
  }
}
    80001abc:	70e2                	ld	ra,56(sp)
    80001abe:	7442                	ld	s0,48(sp)
    80001ac0:	74a2                	ld	s1,40(sp)
    80001ac2:	7902                	ld	s2,32(sp)
    80001ac4:	69e2                	ld	s3,24(sp)
    80001ac6:	6a42                	ld	s4,16(sp)
    80001ac8:	6aa2                	ld	s5,8(sp)
    80001aca:	6b02                	ld	s6,0(sp)
    80001acc:	6121                	addi	sp,sp,64
    80001ace:	8082                	ret

0000000080001ad0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ad0:	1141                	addi	sp,sp,-16
    80001ad2:	e422                	sd	s0,8(sp)
    80001ad4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ad8:	2501                	sext.w	a0,a0
    80001ada:	6422                	ld	s0,8(sp)
    80001adc:	0141                	addi	sp,sp,16
    80001ade:	8082                	ret

0000000080001ae0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001ae0:	1141                	addi	sp,sp,-16
    80001ae2:	e422                	sd	s0,8(sp)
    80001ae4:	0800                	addi	s0,sp,16
    80001ae6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aec:	0022f517          	auipc	a0,0x22f
    80001af0:	0e450513          	addi	a0,a0,228 # 80230bd0 <cpus>
    80001af4:	953e                	add	a0,a0,a5
    80001af6:	6422                	ld	s0,8(sp)
    80001af8:	0141                	addi	sp,sp,16
    80001afa:	8082                	ret

0000000080001afc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001afc:	1101                	addi	sp,sp,-32
    80001afe:	ec06                	sd	ra,24(sp)
    80001b00:	e822                	sd	s0,16(sp)
    80001b02:	e426                	sd	s1,8(sp)
    80001b04:	1000                	addi	s0,sp,32
  push_off();
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	1ba080e7          	jalr	442(ra) # 80000cc0 <push_off>
    80001b0e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b10:	2781                	sext.w	a5,a5
    80001b12:	079e                	slli	a5,a5,0x7
    80001b14:	0022f717          	auipc	a4,0x22f
    80001b18:	08c70713          	addi	a4,a4,140 # 80230ba0 <pid_lock>
    80001b1c:	97ba                	add	a5,a5,a4
    80001b1e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	240080e7          	jalr	576(ra) # 80000d60 <pop_off>
  return p;
}
    80001b28:	8526                	mv	a0,s1
    80001b2a:	60e2                	ld	ra,24(sp)
    80001b2c:	6442                	ld	s0,16(sp)
    80001b2e:	64a2                	ld	s1,8(sp)
    80001b30:	6105                	addi	sp,sp,32
    80001b32:	8082                	ret

0000000080001b34 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b34:	1141                	addi	sp,sp,-16
    80001b36:	e406                	sd	ra,8(sp)
    80001b38:	e022                	sd	s0,0(sp)
    80001b3a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	fc0080e7          	jalr	-64(ra) # 80001afc <myproc>
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	27c080e7          	jalr	636(ra) # 80000dc0 <release>

  if (first) {
    80001b4c:	00007797          	auipc	a5,0x7
    80001b50:	d447a783          	lw	a5,-700(a5) # 80008890 <first.1>
    80001b54:	eb89                	bnez	a5,80001b66 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b56:	00001097          	auipc	ra,0x1
    80001b5a:	ce0080e7          	jalr	-800(ra) # 80002836 <usertrapret>
}
    80001b5e:	60a2                	ld	ra,8(sp)
    80001b60:	6402                	ld	s0,0(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret
    first = 0;
    80001b66:	00007797          	auipc	a5,0x7
    80001b6a:	d207a523          	sw	zero,-726(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001b6e:	4505                	li	a0,1
    80001b70:	00002097          	auipc	ra,0x2
    80001b74:	aa8080e7          	jalr	-1368(ra) # 80003618 <fsinit>
    80001b78:	bff9                	j	80001b56 <forkret+0x22>

0000000080001b7a <allocpid>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	e04a                	sd	s2,0(sp)
    80001b84:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b86:	0022f917          	auipc	s2,0x22f
    80001b8a:	01a90913          	addi	s2,s2,26 # 80230ba0 <pid_lock>
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	17c080e7          	jalr	380(ra) # 80000d0c <acquire>
  pid = nextpid;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	cfc78793          	addi	a5,a5,-772 # 80008894 <nextpid>
    80001ba0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba2:	0014871b          	addiw	a4,s1,1
    80001ba6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba8:	854a                	mv	a0,s2
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	216080e7          	jalr	534(ra) # 80000dc0 <release>
}
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <proc_pagetable>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	e04a                	sd	s2,0(sp)
    80001bca:	1000                	addi	s0,sp,32
    80001bcc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	890080e7          	jalr	-1904(ra) # 8000145e <uvmcreate>
    80001bd6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd8:	c121                	beqz	a0,80001c18 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bda:	4729                	li	a4,10
    80001bdc:	00005697          	auipc	a3,0x5
    80001be0:	42468693          	addi	a3,a3,1060 # 80007000 <_trampoline>
    80001be4:	6605                	lui	a2,0x1
    80001be6:	040005b7          	lui	a1,0x4000
    80001bea:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bec:	05b2                	slli	a1,a1,0xc
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	5e6080e7          	jalr	1510(ra) # 800011d4 <mappages>
    80001bf6:	02054863          	bltz	a0,80001c26 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bfa:	4719                	li	a4,6
    80001bfc:	05893683          	ld	a3,88(s2)
    80001c00:	6605                	lui	a2,0x1
    80001c02:	020005b7          	lui	a1,0x2000
    80001c06:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c08:	05b6                	slli	a1,a1,0xd
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	5c8080e7          	jalr	1480(ra) # 800011d4 <mappages>
    80001c14:	02054163          	bltz	a0,80001c36 <proc_pagetable+0x76>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret
    uvmfree(pagetable, 0);
    80001c26:	4581                	li	a1,0
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	a3a080e7          	jalr	-1478(ra) # 80001664 <uvmfree>
    return 0;
    80001c32:	4481                	li	s1,0
    80001c34:	b7d5                	j	80001c18 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c36:	4681                	li	a3,0
    80001c38:	4605                	li	a2,1
    80001c3a:	040005b7          	lui	a1,0x4000
    80001c3e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c40:	05b2                	slli	a1,a1,0xc
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	756080e7          	jalr	1878(ra) # 8000139a <uvmunmap>
    uvmfree(pagetable, 0);
    80001c4c:	4581                	li	a1,0
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	a14080e7          	jalr	-1516(ra) # 80001664 <uvmfree>
    return 0;
    80001c58:	4481                	li	s1,0
    80001c5a:	bf7d                	j	80001c18 <proc_pagetable+0x58>

0000000080001c5c <proc_freepagetable>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
    80001c68:	84aa                	mv	s1,a0
    80001c6a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c6c:	4681                	li	a3,0
    80001c6e:	4605                	li	a2,1
    80001c70:	040005b7          	lui	a1,0x4000
    80001c74:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c76:	05b2                	slli	a1,a1,0xc
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	722080e7          	jalr	1826(ra) # 8000139a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c80:	4681                	li	a3,0
    80001c82:	4605                	li	a2,1
    80001c84:	020005b7          	lui	a1,0x2000
    80001c88:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c8a:	05b6                	slli	a1,a1,0xd
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	70c080e7          	jalr	1804(ra) # 8000139a <uvmunmap>
  uvmfree(pagetable, sz);
    80001c96:	85ca                	mv	a1,s2
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	9ca080e7          	jalr	-1590(ra) # 80001664 <uvmfree>
}
    80001ca2:	60e2                	ld	ra,24(sp)
    80001ca4:	6442                	ld	s0,16(sp)
    80001ca6:	64a2                	ld	s1,8(sp)
    80001ca8:	6902                	ld	s2,0(sp)
    80001caa:	6105                	addi	sp,sp,32
    80001cac:	8082                	ret

0000000080001cae <freeproc>:
{
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	1000                	addi	s0,sp,32
    80001cb8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cba:	6d28                	ld	a0,88(a0)
    80001cbc:	c509                	beqz	a0,80001cc6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	da2080e7          	jalr	-606(ra) # 80000a60 <kfree>
  p->trapframe = 0;
    80001cc6:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cca:	68a8                	ld	a0,80(s1)
    80001ccc:	c511                	beqz	a0,80001cd8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cce:	64ac                	ld	a1,72(s1)
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	f8c080e7          	jalr	-116(ra) # 80001c5c <proc_freepagetable>
  p->pagetable = 0;
    80001cd8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cdc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ce0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ce8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cec:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cf0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cf4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cf8:	0004ac23          	sw	zero,24(s1)
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <allocproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d12:	0022f497          	auipc	s1,0x22f
    80001d16:	2be48493          	addi	s1,s1,702 # 80230fd0 <proc>
    80001d1a:	00236917          	auipc	s2,0x236
    80001d1e:	4b690913          	addi	s2,s2,1206 # 802381d0 <tickslock>
    acquire(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	fe8080e7          	jalr	-24(ra) # 80000d0c <acquire>
    if(p->state == UNUSED) {
    80001d2c:	4c9c                	lw	a5,24(s1)
    80001d2e:	cf81                	beqz	a5,80001d46 <allocproc+0x40>
      release(&p->lock);
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	08e080e7          	jalr	142(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d3a:	1c848493          	addi	s1,s1,456
    80001d3e:	ff2492e3          	bne	s1,s2,80001d22 <allocproc+0x1c>
  return 0;
    80001d42:	4481                	li	s1,0
    80001d44:	a889                	j	80001d96 <allocproc+0x90>
  p->pid = allocpid();
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	e34080e7          	jalr	-460(ra) # 80001b7a <allocpid>
    80001d4e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d50:	4785                	li	a5,1
    80001d52:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	e90080e7          	jalr	-368(ra) # 80000be4 <kalloc>
    80001d5c:	892a                	mv	s2,a0
    80001d5e:	eca8                	sd	a0,88(s1)
    80001d60:	c131                	beqz	a0,80001da4 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d62:	8526                	mv	a0,s1
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	e5c080e7          	jalr	-420(ra) # 80001bc0 <proc_pagetable>
    80001d6c:	892a                	mv	s2,a0
    80001d6e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d70:	c531                	beqz	a0,80001dbc <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d72:	07000613          	li	a2,112
    80001d76:	4581                	li	a1,0
    80001d78:	06048513          	addi	a0,s1,96
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	08c080e7          	jalr	140(ra) # 80000e08 <memset>
  p->context.ra = (uint64)forkret;
    80001d84:	00000797          	auipc	a5,0x0
    80001d88:	db078793          	addi	a5,a5,-592 # 80001b34 <forkret>
    80001d8c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d8e:	60bc                	ld	a5,64(s1)
    80001d90:	6705                	lui	a4,0x1
    80001d92:	97ba                	add	a5,a5,a4
    80001d94:	f4bc                	sd	a5,104(s1)
}
    80001d96:	8526                	mv	a0,s1
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret
    freeproc(p);
    80001da4:	8526                	mv	a0,s1
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	f08080e7          	jalr	-248(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001dae:	8526                	mv	a0,s1
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	010080e7          	jalr	16(ra) # 80000dc0 <release>
    return 0;
    80001db8:	84ca                	mv	s1,s2
    80001dba:	bff1                	j	80001d96 <allocproc+0x90>
    freeproc(p);
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	ef0080e7          	jalr	-272(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	ff8080e7          	jalr	-8(ra) # 80000dc0 <release>
    return 0;
    80001dd0:	84ca                	mv	s1,s2
    80001dd2:	b7d1                	j	80001d96 <allocproc+0x90>

0000000080001dd4 <userinit>:
{
    80001dd4:	1101                	addi	sp,sp,-32
    80001dd6:	ec06                	sd	ra,24(sp)
    80001dd8:	e822                	sd	s0,16(sp)
    80001dda:	e426                	sd	s1,8(sp)
    80001ddc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	f28080e7          	jalr	-216(ra) # 80001d06 <allocproc>
    80001de6:	84aa                	mv	s1,a0
  initproc = p;
    80001de8:	00007797          	auipc	a5,0x7
    80001dec:	b4a7b023          	sd	a0,-1216(a5) # 80008928 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001df0:	03400613          	li	a2,52
    80001df4:	00007597          	auipc	a1,0x7
    80001df8:	aac58593          	addi	a1,a1,-1364 # 800088a0 <initcode>
    80001dfc:	6928                	ld	a0,80(a0)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	68e080e7          	jalr	1678(ra) # 8000148c <uvmfirst>
  p->sz = PGSIZE;
    80001e06:	6785                	lui	a5,0x1
    80001e08:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e0a:	6cb8                	ld	a4,88(s1)
    80001e0c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e10:	6cb8                	ld	a4,88(s1)
    80001e12:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e14:	4641                	li	a2,16
    80001e16:	00006597          	auipc	a1,0x6
    80001e1a:	42258593          	addi	a1,a1,1058 # 80008238 <digits+0x1f8>
    80001e1e:	15848513          	addi	a0,s1,344
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	130080e7          	jalr	304(ra) # 80000f52 <safestrcpy>
  p->cwd = namei("/");
    80001e2a:	00006517          	auipc	a0,0x6
    80001e2e:	41e50513          	addi	a0,a0,1054 # 80008248 <digits+0x208>
    80001e32:	00002097          	auipc	ra,0x2
    80001e36:	210080e7          	jalr	528(ra) # 80004042 <namei>
    80001e3a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e3e:	478d                	li	a5,3
    80001e40:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	f7c080e7          	jalr	-132(ra) # 80000dc0 <release>
}
    80001e4c:	60e2                	ld	ra,24(sp)
    80001e4e:	6442                	ld	s0,16(sp)
    80001e50:	64a2                	ld	s1,8(sp)
    80001e52:	6105                	addi	sp,sp,32
    80001e54:	8082                	ret

0000000080001e56 <growproc>:
{
    80001e56:	1101                	addi	sp,sp,-32
    80001e58:	ec06                	sd	ra,24(sp)
    80001e5a:	e822                	sd	s0,16(sp)
    80001e5c:	e426                	sd	s1,8(sp)
    80001e5e:	e04a                	sd	s2,0(sp)
    80001e60:	1000                	addi	s0,sp,32
    80001e62:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	c98080e7          	jalr	-872(ra) # 80001afc <myproc>
    80001e6c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e6e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e70:	01204c63          	bgtz	s2,80001e88 <growproc+0x32>
  } else if(n < 0){
    80001e74:	02094663          	bltz	s2,80001ea0 <growproc+0x4a>
  p->sz = sz;
    80001e78:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e7a:	4501                	li	a0,0
}
    80001e7c:	60e2                	ld	ra,24(sp)
    80001e7e:	6442                	ld	s0,16(sp)
    80001e80:	64a2                	ld	s1,8(sp)
    80001e82:	6902                	ld	s2,0(sp)
    80001e84:	6105                	addi	sp,sp,32
    80001e86:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e88:	4691                	li	a3,4
    80001e8a:	00b90633          	add	a2,s2,a1
    80001e8e:	6928                	ld	a0,80(a0)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	6b6080e7          	jalr	1718(ra) # 80001546 <uvmalloc>
    80001e98:	85aa                	mv	a1,a0
    80001e9a:	fd79                	bnez	a0,80001e78 <growproc+0x22>
      return -1;
    80001e9c:	557d                	li	a0,-1
    80001e9e:	bff9                	j	80001e7c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ea0:	00b90633          	add	a2,s2,a1
    80001ea4:	6928                	ld	a0,80(a0)
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	658080e7          	jalr	1624(ra) # 800014fe <uvmdealloc>
    80001eae:	85aa                	mv	a1,a0
    80001eb0:	b7e1                	j	80001e78 <growproc+0x22>

0000000080001eb2 <fork>:
{
    80001eb2:	7139                	addi	sp,sp,-64
    80001eb4:	fc06                	sd	ra,56(sp)
    80001eb6:	f822                	sd	s0,48(sp)
    80001eb8:	f426                	sd	s1,40(sp)
    80001eba:	f04a                	sd	s2,32(sp)
    80001ebc:	ec4e                	sd	s3,24(sp)
    80001ebe:	e852                	sd	s4,16(sp)
    80001ec0:	e456                	sd	s5,8(sp)
    80001ec2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	c38080e7          	jalr	-968(ra) # 80001afc <myproc>
    80001ecc:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	e38080e7          	jalr	-456(ra) # 80001d06 <allocproc>
    80001ed6:	10050c63          	beqz	a0,80001fee <fork+0x13c>
    80001eda:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001edc:	048ab603          	ld	a2,72(s5)
    80001ee0:	692c                	ld	a1,80(a0)
    80001ee2:	050ab503          	ld	a0,80(s5)
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	7b8080e7          	jalr	1976(ra) # 8000169e <uvmcopy>
    80001eee:	04054863          	bltz	a0,80001f3e <fork+0x8c>
  np->sz = p->sz;
    80001ef2:	048ab783          	ld	a5,72(s5)
    80001ef6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001efa:	058ab683          	ld	a3,88(s5)
    80001efe:	87b6                	mv	a5,a3
    80001f00:	058a3703          	ld	a4,88(s4)
    80001f04:	12068693          	addi	a3,a3,288
    80001f08:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f0c:	6788                	ld	a0,8(a5)
    80001f0e:	6b8c                	ld	a1,16(a5)
    80001f10:	6f90                	ld	a2,24(a5)
    80001f12:	01073023          	sd	a6,0(a4)
    80001f16:	e708                	sd	a0,8(a4)
    80001f18:	eb0c                	sd	a1,16(a4)
    80001f1a:	ef10                	sd	a2,24(a4)
    80001f1c:	02078793          	addi	a5,a5,32
    80001f20:	02070713          	addi	a4,a4,32
    80001f24:	fed792e3          	bne	a5,a3,80001f08 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f28:	058a3783          	ld	a5,88(s4)
    80001f2c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f30:	0d0a8493          	addi	s1,s5,208
    80001f34:	0d0a0913          	addi	s2,s4,208
    80001f38:	150a8993          	addi	s3,s5,336
    80001f3c:	a00d                	j	80001f5e <fork+0xac>
    freeproc(np);
    80001f3e:	8552                	mv	a0,s4
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	d6e080e7          	jalr	-658(ra) # 80001cae <freeproc>
    release(&np->lock);
    80001f48:	8552                	mv	a0,s4
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	e76080e7          	jalr	-394(ra) # 80000dc0 <release>
    return -1;
    80001f52:	597d                	li	s2,-1
    80001f54:	a059                	j	80001fda <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001f56:	04a1                	addi	s1,s1,8
    80001f58:	0921                	addi	s2,s2,8
    80001f5a:	01348b63          	beq	s1,s3,80001f70 <fork+0xbe>
    if(p->ofile[i])
    80001f5e:	6088                	ld	a0,0(s1)
    80001f60:	d97d                	beqz	a0,80001f56 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f62:	00002097          	auipc	ra,0x2
    80001f66:	776080e7          	jalr	1910(ra) # 800046d8 <filedup>
    80001f6a:	00a93023          	sd	a0,0(s2)
    80001f6e:	b7e5                	j	80001f56 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f70:	150ab503          	ld	a0,336(s5)
    80001f74:	00002097          	auipc	ra,0x2
    80001f78:	8e4080e7          	jalr	-1820(ra) # 80003858 <idup>
    80001f7c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f80:	4641                	li	a2,16
    80001f82:	158a8593          	addi	a1,s5,344
    80001f86:	158a0513          	addi	a0,s4,344
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	fc8080e7          	jalr	-56(ra) # 80000f52 <safestrcpy>
  pid = np->pid;
    80001f92:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f96:	8552                	mv	a0,s4
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	e28080e7          	jalr	-472(ra) # 80000dc0 <release>
  acquire(&wait_lock);
    80001fa0:	0022f497          	auipc	s1,0x22f
    80001fa4:	c1848493          	addi	s1,s1,-1000 # 80230bb8 <wait_lock>
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	d62080e7          	jalr	-670(ra) # 80000d0c <acquire>
  np->parent = p;
    80001fb2:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	e08080e7          	jalr	-504(ra) # 80000dc0 <release>
  acquire(&np->lock);
    80001fc0:	8552                	mv	a0,s4
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	d4a080e7          	jalr	-694(ra) # 80000d0c <acquire>
  np->state = RUNNABLE;
    80001fca:	478d                	li	a5,3
    80001fcc:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fd0:	8552                	mv	a0,s4
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	dee080e7          	jalr	-530(ra) # 80000dc0 <release>
}
    80001fda:	854a                	mv	a0,s2
    80001fdc:	70e2                	ld	ra,56(sp)
    80001fde:	7442                	ld	s0,48(sp)
    80001fe0:	74a2                	ld	s1,40(sp)
    80001fe2:	7902                	ld	s2,32(sp)
    80001fe4:	69e2                	ld	s3,24(sp)
    80001fe6:	6a42                	ld	s4,16(sp)
    80001fe8:	6aa2                	ld	s5,8(sp)
    80001fea:	6121                	addi	sp,sp,64
    80001fec:	8082                	ret
    return -1;
    80001fee:	597d                	li	s2,-1
    80001ff0:	b7ed                	j	80001fda <fork+0x128>

0000000080001ff2 <scheduler>:
{
    80001ff2:	7139                	addi	sp,sp,-64
    80001ff4:	fc06                	sd	ra,56(sp)
    80001ff6:	f822                	sd	s0,48(sp)
    80001ff8:	f426                	sd	s1,40(sp)
    80001ffa:	f04a                	sd	s2,32(sp)
    80001ffc:	ec4e                	sd	s3,24(sp)
    80001ffe:	e852                	sd	s4,16(sp)
    80002000:	e456                	sd	s5,8(sp)
    80002002:	e05a                	sd	s6,0(sp)
    80002004:	0080                	addi	s0,sp,64
    80002006:	8792                	mv	a5,tp
  int id = r_tp();
    80002008:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000200a:	00779a93          	slli	s5,a5,0x7
    8000200e:	0022f717          	auipc	a4,0x22f
    80002012:	b9270713          	addi	a4,a4,-1134 # 80230ba0 <pid_lock>
    80002016:	9756                	add	a4,a4,s5
    80002018:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000201c:	0022f717          	auipc	a4,0x22f
    80002020:	bbc70713          	addi	a4,a4,-1092 # 80230bd8 <cpus+0x8>
    80002024:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002026:	498d                	li	s3,3
        p->state = RUNNING;
    80002028:	4b11                	li	s6,4
        c->proc = p;
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	0022fa17          	auipc	s4,0x22f
    80002030:	b74a0a13          	addi	s4,s4,-1164 # 80230ba0 <pid_lock>
    80002034:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002036:	00236917          	auipc	s2,0x236
    8000203a:	19a90913          	addi	s2,s2,410 # 802381d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002042:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002046:	10079073          	csrw	sstatus,a5
    8000204a:	0022f497          	auipc	s1,0x22f
    8000204e:	f8648493          	addi	s1,s1,-122 # 80230fd0 <proc>
    80002052:	a811                	j	80002066 <scheduler+0x74>
      release(&p->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	d6a080e7          	jalr	-662(ra) # 80000dc0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000205e:	1c848493          	addi	s1,s1,456
    80002062:	fd248ee3          	beq	s1,s2,8000203e <scheduler+0x4c>
      acquire(&p->lock);
    80002066:	8526                	mv	a0,s1
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	ca4080e7          	jalr	-860(ra) # 80000d0c <acquire>
      if(p->state == RUNNABLE) {
    80002070:	4c9c                	lw	a5,24(s1)
    80002072:	ff3791e3          	bne	a5,s3,80002054 <scheduler+0x62>
        p->state = RUNNING;
    80002076:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000207a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000207e:	06048593          	addi	a1,s1,96
    80002082:	8556                	mv	a0,s5
    80002084:	00000097          	auipc	ra,0x0
    80002088:	684080e7          	jalr	1668(ra) # 80002708 <swtch>
        c->proc = 0;
    8000208c:	020a3823          	sd	zero,48(s4)
    80002090:	b7d1                	j	80002054 <scheduler+0x62>

0000000080002092 <sched>:
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	a5c080e7          	jalr	-1444(ra) # 80001afc <myproc>
    800020a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	be8080e7          	jalr	-1048(ra) # 80000c92 <holding>
    800020b2:	c93d                	beqz	a0,80002128 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	0022f717          	auipc	a4,0x22f
    800020be:	ae670713          	addi	a4,a4,-1306 # 80230ba0 <pid_lock>
    800020c2:	97ba                	add	a5,a5,a4
    800020c4:	0a87a703          	lw	a4,168(a5)
    800020c8:	4785                	li	a5,1
    800020ca:	06f71763          	bne	a4,a5,80002138 <sched+0xa6>
  if(p->state == RUNNING)
    800020ce:	4c98                	lw	a4,24(s1)
    800020d0:	4791                	li	a5,4
    800020d2:	06f70b63          	beq	a4,a5,80002148 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020da:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020dc:	efb5                	bnez	a5,80002158 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020de:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020e0:	0022f917          	auipc	s2,0x22f
    800020e4:	ac090913          	addi	s2,s2,-1344 # 80230ba0 <pid_lock>
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	97ca                	add	a5,a5,s2
    800020ee:	0ac7a983          	lw	s3,172(a5)
    800020f2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f4:	2781                	sext.w	a5,a5
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	0022f597          	auipc	a1,0x22f
    800020fc:	ae058593          	addi	a1,a1,-1312 # 80230bd8 <cpus+0x8>
    80002100:	95be                	add	a1,a1,a5
    80002102:	06048513          	addi	a0,s1,96
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	602080e7          	jalr	1538(ra) # 80002708 <swtch>
    8000210e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	993e                	add	s2,s2,a5
    80002116:	0b392623          	sw	s3,172(s2)
}
    8000211a:	70a2                	ld	ra,40(sp)
    8000211c:	7402                	ld	s0,32(sp)
    8000211e:	64e2                	ld	s1,24(sp)
    80002120:	6942                	ld	s2,16(sp)
    80002122:	69a2                	ld	s3,8(sp)
    80002124:	6145                	addi	sp,sp,48
    80002126:	8082                	ret
    panic("sched p->lock");
    80002128:	00006517          	auipc	a0,0x6
    8000212c:	12850513          	addi	a0,a0,296 # 80008250 <digits+0x210>
    80002130:	ffffe097          	auipc	ra,0xffffe
    80002134:	410080e7          	jalr	1040(ra) # 80000540 <panic>
    panic("sched locks");
    80002138:	00006517          	auipc	a0,0x6
    8000213c:	12850513          	addi	a0,a0,296 # 80008260 <digits+0x220>
    80002140:	ffffe097          	auipc	ra,0xffffe
    80002144:	400080e7          	jalr	1024(ra) # 80000540 <panic>
    panic("sched running");
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	12850513          	addi	a0,a0,296 # 80008270 <digits+0x230>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	3f0080e7          	jalr	1008(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002158:	00006517          	auipc	a0,0x6
    8000215c:	12850513          	addi	a0,a0,296 # 80008280 <digits+0x240>
    80002160:	ffffe097          	auipc	ra,0xffffe
    80002164:	3e0080e7          	jalr	992(ra) # 80000540 <panic>

0000000080002168 <yield>:
{
    80002168:	1101                	addi	sp,sp,-32
    8000216a:	ec06                	sd	ra,24(sp)
    8000216c:	e822                	sd	s0,16(sp)
    8000216e:	e426                	sd	s1,8(sp)
    80002170:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002172:	00000097          	auipc	ra,0x0
    80002176:	98a080e7          	jalr	-1654(ra) # 80001afc <myproc>
    8000217a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b90080e7          	jalr	-1136(ra) # 80000d0c <acquire>
  p->state = RUNNABLE;
    80002184:	478d                	li	a5,3
    80002186:	cc9c                	sw	a5,24(s1)
  sched();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	f0a080e7          	jalr	-246(ra) # 80002092 <sched>
  release(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	c2e080e7          	jalr	-978(ra) # 80000dc0 <release>
}
    8000219a:	60e2                	ld	ra,24(sp)
    8000219c:	6442                	ld	s0,16(sp)
    8000219e:	64a2                	ld	s1,8(sp)
    800021a0:	6105                	addi	sp,sp,32
    800021a2:	8082                	ret

00000000800021a4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021a4:	7179                	addi	sp,sp,-48
    800021a6:	f406                	sd	ra,40(sp)
    800021a8:	f022                	sd	s0,32(sp)
    800021aa:	ec26                	sd	s1,24(sp)
    800021ac:	e84a                	sd	s2,16(sp)
    800021ae:	e44e                	sd	s3,8(sp)
    800021b0:	1800                	addi	s0,sp,48
    800021b2:	89aa                	mv	s3,a0
    800021b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	946080e7          	jalr	-1722(ra) # 80001afc <myproc>
    800021be:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	b4c080e7          	jalr	-1204(ra) # 80000d0c <acquire>
  release(lk);
    800021c8:	854a                	mv	a0,s2
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	bf6080e7          	jalr	-1034(ra) # 80000dc0 <release>

  // Go to sleep.
  p->chan = chan;
    800021d2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021d6:	4789                	li	a5,2
    800021d8:	cc9c                	sw	a5,24(s1)

  sched();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	eb8080e7          	jalr	-328(ra) # 80002092 <sched>

  // Tidy up.
  p->chan = 0;
    800021e2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	bd8080e7          	jalr	-1064(ra) # 80000dc0 <release>
  acquire(lk);
    800021f0:	854a                	mv	a0,s2
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	b1a080e7          	jalr	-1254(ra) # 80000d0c <acquire>
}
    800021fa:	70a2                	ld	ra,40(sp)
    800021fc:	7402                	ld	s0,32(sp)
    800021fe:	64e2                	ld	s1,24(sp)
    80002200:	6942                	ld	s2,16(sp)
    80002202:	69a2                	ld	s3,8(sp)
    80002204:	6145                	addi	sp,sp,48
    80002206:	8082                	ret

0000000080002208 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002208:	7139                	addi	sp,sp,-64
    8000220a:	fc06                	sd	ra,56(sp)
    8000220c:	f822                	sd	s0,48(sp)
    8000220e:	f426                	sd	s1,40(sp)
    80002210:	f04a                	sd	s2,32(sp)
    80002212:	ec4e                	sd	s3,24(sp)
    80002214:	e852                	sd	s4,16(sp)
    80002216:	e456                	sd	s5,8(sp)
    80002218:	0080                	addi	s0,sp,64
    8000221a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000221c:	0022f497          	auipc	s1,0x22f
    80002220:	db448493          	addi	s1,s1,-588 # 80230fd0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002224:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002226:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002228:	00236917          	auipc	s2,0x236
    8000222c:	fa890913          	addi	s2,s2,-88 # 802381d0 <tickslock>
    80002230:	a811                	j	80002244 <wakeup+0x3c>
      }
      release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	b8c080e7          	jalr	-1140(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000223c:	1c848493          	addi	s1,s1,456
    80002240:	03248663          	beq	s1,s2,8000226c <wakeup+0x64>
    if(p != myproc()){
    80002244:	00000097          	auipc	ra,0x0
    80002248:	8b8080e7          	jalr	-1864(ra) # 80001afc <myproc>
    8000224c:	fea488e3          	beq	s1,a0,8000223c <wakeup+0x34>
      acquire(&p->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	aba080e7          	jalr	-1350(ra) # 80000d0c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000225a:	4c9c                	lw	a5,24(s1)
    8000225c:	fd379be3          	bne	a5,s3,80002232 <wakeup+0x2a>
    80002260:	709c                	ld	a5,32(s1)
    80002262:	fd4798e3          	bne	a5,s4,80002232 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002266:	0154ac23          	sw	s5,24(s1)
    8000226a:	b7e1                	j	80002232 <wakeup+0x2a>
    }
  }
}
    8000226c:	70e2                	ld	ra,56(sp)
    8000226e:	7442                	ld	s0,48(sp)
    80002270:	74a2                	ld	s1,40(sp)
    80002272:	7902                	ld	s2,32(sp)
    80002274:	69e2                	ld	s3,24(sp)
    80002276:	6a42                	ld	s4,16(sp)
    80002278:	6aa2                	ld	s5,8(sp)
    8000227a:	6121                	addi	sp,sp,64
    8000227c:	8082                	ret

000000008000227e <reparent>:
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	e052                	sd	s4,0(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002290:	0022f497          	auipc	s1,0x22f
    80002294:	d4048493          	addi	s1,s1,-704 # 80230fd0 <proc>
      pp->parent = initproc;
    80002298:	00006a17          	auipc	s4,0x6
    8000229c:	690a0a13          	addi	s4,s4,1680 # 80008928 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a0:	00236997          	auipc	s3,0x236
    800022a4:	f3098993          	addi	s3,s3,-208 # 802381d0 <tickslock>
    800022a8:	a029                	j	800022b2 <reparent+0x34>
    800022aa:	1c848493          	addi	s1,s1,456
    800022ae:	01348d63          	beq	s1,s3,800022c8 <reparent+0x4a>
    if(pp->parent == p){
    800022b2:	7c9c                	ld	a5,56(s1)
    800022b4:	ff279be3          	bne	a5,s2,800022aa <reparent+0x2c>
      pp->parent = initproc;
    800022b8:	000a3503          	ld	a0,0(s4)
    800022bc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	f4a080e7          	jalr	-182(ra) # 80002208 <wakeup>
    800022c6:	b7d5                	j	800022aa <reparent+0x2c>
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6a02                	ld	s4,0(sp)
    800022d4:	6145                	addi	sp,sp,48
    800022d6:	8082                	ret

00000000800022d8 <exit>:
{
    800022d8:	7179                	addi	sp,sp,-48
    800022da:	f406                	sd	ra,40(sp)
    800022dc:	f022                	sd	s0,32(sp)
    800022de:	ec26                	sd	s1,24(sp)
    800022e0:	e84a                	sd	s2,16(sp)
    800022e2:	e44e                	sd	s3,8(sp)
    800022e4:	e052                	sd	s4,0(sp)
    800022e6:	1800                	addi	s0,sp,48
    800022e8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	812080e7          	jalr	-2030(ra) # 80001afc <myproc>
    800022f2:	89aa                	mv	s3,a0
  if(p == initproc)
    800022f4:	00006797          	auipc	a5,0x6
    800022f8:	6347b783          	ld	a5,1588(a5) # 80008928 <initproc>
    800022fc:	0d050493          	addi	s1,a0,208
    80002300:	15050913          	addi	s2,a0,336
    80002304:	02a79363          	bne	a5,a0,8000232a <exit+0x52>
    panic("init exiting");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	f9050513          	addi	a0,a0,-112 # 80008298 <digits+0x258>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	230080e7          	jalr	560(ra) # 80000540 <panic>
      fileclose(f);
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	412080e7          	jalr	1042(ra) # 8000472a <fileclose>
      p->ofile[fd] = 0;
    80002320:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002324:	04a1                	addi	s1,s1,8
    80002326:	01248563          	beq	s1,s2,80002330 <exit+0x58>
    if(p->ofile[fd]){
    8000232a:	6088                	ld	a0,0(s1)
    8000232c:	f575                	bnez	a0,80002318 <exit+0x40>
    8000232e:	bfdd                	j	80002324 <exit+0x4c>
  begin_op();
    80002330:	00002097          	auipc	ra,0x2
    80002334:	f32080e7          	jalr	-206(ra) # 80004262 <begin_op>
  iput(p->cwd);
    80002338:	1509b503          	ld	a0,336(s3)
    8000233c:	00001097          	auipc	ra,0x1
    80002340:	714080e7          	jalr	1812(ra) # 80003a50 <iput>
  end_op();
    80002344:	00002097          	auipc	ra,0x2
    80002348:	f9c080e7          	jalr	-100(ra) # 800042e0 <end_op>
  p->cwd = 0;
    8000234c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002350:	0022f497          	auipc	s1,0x22f
    80002354:	86848493          	addi	s1,s1,-1944 # 80230bb8 <wait_lock>
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	9b2080e7          	jalr	-1614(ra) # 80000d0c <acquire>
  reparent(p);
    80002362:	854e                	mv	a0,s3
    80002364:	00000097          	auipc	ra,0x0
    80002368:	f1a080e7          	jalr	-230(ra) # 8000227e <reparent>
  wakeup(p->parent);
    8000236c:	0389b503          	ld	a0,56(s3)
    80002370:	00000097          	auipc	ra,0x0
    80002374:	e98080e7          	jalr	-360(ra) # 80002208 <wakeup>
  acquire(&p->lock);
    80002378:	854e                	mv	a0,s3
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	992080e7          	jalr	-1646(ra) # 80000d0c <acquire>
  p->xstate = status;
    80002382:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002386:	4795                	li	a5,5
    80002388:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	a32080e7          	jalr	-1486(ra) # 80000dc0 <release>
  sched();
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	cfc080e7          	jalr	-772(ra) # 80002092 <sched>
  panic("zombie exit");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	f0a50513          	addi	a0,a0,-246 # 800082a8 <digits+0x268>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	19a080e7          	jalr	410(ra) # 80000540 <panic>

00000000800023ae <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023ae:	7179                	addi	sp,sp,-48
    800023b0:	f406                	sd	ra,40(sp)
    800023b2:	f022                	sd	s0,32(sp)
    800023b4:	ec26                	sd	s1,24(sp)
    800023b6:	e84a                	sd	s2,16(sp)
    800023b8:	e44e                	sd	s3,8(sp)
    800023ba:	1800                	addi	s0,sp,48
    800023bc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023be:	0022f497          	auipc	s1,0x22f
    800023c2:	c1248493          	addi	s1,s1,-1006 # 80230fd0 <proc>
    800023c6:	00236997          	auipc	s3,0x236
    800023ca:	e0a98993          	addi	s3,s3,-502 # 802381d0 <tickslock>
    acquire(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	93c080e7          	jalr	-1732(ra) # 80000d0c <acquire>
    if(p->pid == pid){
    800023d8:	589c                	lw	a5,48(s1)
    800023da:	01278d63          	beq	a5,s2,800023f4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	9e0080e7          	jalr	-1568(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023e8:	1c848493          	addi	s1,s1,456
    800023ec:	ff3491e3          	bne	s1,s3,800023ce <kill+0x20>
  }
  return -1;
    800023f0:	557d                	li	a0,-1
    800023f2:	a829                	j	8000240c <kill+0x5e>
      p->killed = 1;
    800023f4:	4785                	li	a5,1
    800023f6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023f8:	4c98                	lw	a4,24(s1)
    800023fa:	4789                	li	a5,2
    800023fc:	00f70f63          	beq	a4,a5,8000241a <kill+0x6c>
      release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	9be080e7          	jalr	-1602(ra) # 80000dc0 <release>
      return 0;
    8000240a:	4501                	li	a0,0
}
    8000240c:	70a2                	ld	ra,40(sp)
    8000240e:	7402                	ld	s0,32(sp)
    80002410:	64e2                	ld	s1,24(sp)
    80002412:	6942                	ld	s2,16(sp)
    80002414:	69a2                	ld	s3,8(sp)
    80002416:	6145                	addi	sp,sp,48
    80002418:	8082                	ret
        p->state = RUNNABLE;
    8000241a:	478d                	li	a5,3
    8000241c:	cc9c                	sw	a5,24(s1)
    8000241e:	b7cd                	j	80002400 <kill+0x52>

0000000080002420 <setkilled>:

void
setkilled(struct proc *p)
{
    80002420:	1101                	addi	sp,sp,-32
    80002422:	ec06                	sd	ra,24(sp)
    80002424:	e822                	sd	s0,16(sp)
    80002426:	e426                	sd	s1,8(sp)
    80002428:	1000                	addi	s0,sp,32
    8000242a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	8e0080e7          	jalr	-1824(ra) # 80000d0c <acquire>
  p->killed = 1;
    80002434:	4785                	li	a5,1
    80002436:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	986080e7          	jalr	-1658(ra) # 80000dc0 <release>
}
    80002442:	60e2                	ld	ra,24(sp)
    80002444:	6442                	ld	s0,16(sp)
    80002446:	64a2                	ld	s1,8(sp)
    80002448:	6105                	addi	sp,sp,32
    8000244a:	8082                	ret

000000008000244c <killed>:

int
killed(struct proc *p)
{
    8000244c:	1101                	addi	sp,sp,-32
    8000244e:	ec06                	sd	ra,24(sp)
    80002450:	e822                	sd	s0,16(sp)
    80002452:	e426                	sd	s1,8(sp)
    80002454:	e04a                	sd	s2,0(sp)
    80002456:	1000                	addi	s0,sp,32
    80002458:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	8b2080e7          	jalr	-1870(ra) # 80000d0c <acquire>
  k = p->killed;
    80002462:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	958080e7          	jalr	-1704(ra) # 80000dc0 <release>
  return k;
}
    80002470:	854a                	mv	a0,s2
    80002472:	60e2                	ld	ra,24(sp)
    80002474:	6442                	ld	s0,16(sp)
    80002476:	64a2                	ld	s1,8(sp)
    80002478:	6902                	ld	s2,0(sp)
    8000247a:	6105                	addi	sp,sp,32
    8000247c:	8082                	ret

000000008000247e <wait>:
{
    8000247e:	715d                	addi	sp,sp,-80
    80002480:	e486                	sd	ra,72(sp)
    80002482:	e0a2                	sd	s0,64(sp)
    80002484:	fc26                	sd	s1,56(sp)
    80002486:	f84a                	sd	s2,48(sp)
    80002488:	f44e                	sd	s3,40(sp)
    8000248a:	f052                	sd	s4,32(sp)
    8000248c:	ec56                	sd	s5,24(sp)
    8000248e:	e85a                	sd	s6,16(sp)
    80002490:	e45e                	sd	s7,8(sp)
    80002492:	e062                	sd	s8,0(sp)
    80002494:	0880                	addi	s0,sp,80
    80002496:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	664080e7          	jalr	1636(ra) # 80001afc <myproc>
    800024a0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024a2:	0022e517          	auipc	a0,0x22e
    800024a6:	71650513          	addi	a0,a0,1814 # 80230bb8 <wait_lock>
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	862080e7          	jalr	-1950(ra) # 80000d0c <acquire>
    havekids = 0;
    800024b2:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800024b4:	4a15                	li	s4,5
        havekids = 1;
    800024b6:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024b8:	00236997          	auipc	s3,0x236
    800024bc:	d1898993          	addi	s3,s3,-744 # 802381d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c0:	0022ec17          	auipc	s8,0x22e
    800024c4:	6f8c0c13          	addi	s8,s8,1784 # 80230bb8 <wait_lock>
    havekids = 0;
    800024c8:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ca:	0022f497          	auipc	s1,0x22f
    800024ce:	b0648493          	addi	s1,s1,-1274 # 80230fd0 <proc>
    800024d2:	a0bd                	j	80002540 <wait+0xc2>
          pid = pp->pid;
    800024d4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024d8:	000b0e63          	beqz	s6,800024f4 <wait+0x76>
    800024dc:	4691                	li	a3,4
    800024de:	02c48613          	addi	a2,s1,44
    800024e2:	85da                	mv	a1,s6
    800024e4:	05093503          	ld	a0,80(s2)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	2a0080e7          	jalr	672(ra) # 80001788 <copyout>
    800024f0:	02054563          	bltz	a0,8000251a <wait+0x9c>
          freeproc(pp);
    800024f4:	8526                	mv	a0,s1
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	7b8080e7          	jalr	1976(ra) # 80001cae <freeproc>
          release(&pp->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	8c0080e7          	jalr	-1856(ra) # 80000dc0 <release>
          release(&wait_lock);
    80002508:	0022e517          	auipc	a0,0x22e
    8000250c:	6b050513          	addi	a0,a0,1712 # 80230bb8 <wait_lock>
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	8b0080e7          	jalr	-1872(ra) # 80000dc0 <release>
          return pid;
    80002518:	a0b5                	j	80002584 <wait+0x106>
            release(&pp->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	8a4080e7          	jalr	-1884(ra) # 80000dc0 <release>
            release(&wait_lock);
    80002524:	0022e517          	auipc	a0,0x22e
    80002528:	69450513          	addi	a0,a0,1684 # 80230bb8 <wait_lock>
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	894080e7          	jalr	-1900(ra) # 80000dc0 <release>
            return -1;
    80002534:	59fd                	li	s3,-1
    80002536:	a0b9                	j	80002584 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002538:	1c848493          	addi	s1,s1,456
    8000253c:	03348463          	beq	s1,s3,80002564 <wait+0xe6>
      if(pp->parent == p){
    80002540:	7c9c                	ld	a5,56(s1)
    80002542:	ff279be3          	bne	a5,s2,80002538 <wait+0xba>
        acquire(&pp->lock);
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	7c4080e7          	jalr	1988(ra) # 80000d0c <acquire>
        if(pp->state == ZOMBIE){
    80002550:	4c9c                	lw	a5,24(s1)
    80002552:	f94781e3          	beq	a5,s4,800024d4 <wait+0x56>
        release(&pp->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	868080e7          	jalr	-1944(ra) # 80000dc0 <release>
        havekids = 1;
    80002560:	8756                	mv	a4,s5
    80002562:	bfd9                	j	80002538 <wait+0xba>
    if(!havekids || killed(p)){
    80002564:	c719                	beqz	a4,80002572 <wait+0xf4>
    80002566:	854a                	mv	a0,s2
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	ee4080e7          	jalr	-284(ra) # 8000244c <killed>
    80002570:	c51d                	beqz	a0,8000259e <wait+0x120>
      release(&wait_lock);
    80002572:	0022e517          	auipc	a0,0x22e
    80002576:	64650513          	addi	a0,a0,1606 # 80230bb8 <wait_lock>
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	846080e7          	jalr	-1978(ra) # 80000dc0 <release>
      return -1;
    80002582:	59fd                	li	s3,-1
}
    80002584:	854e                	mv	a0,s3
    80002586:	60a6                	ld	ra,72(sp)
    80002588:	6406                	ld	s0,64(sp)
    8000258a:	74e2                	ld	s1,56(sp)
    8000258c:	7942                	ld	s2,48(sp)
    8000258e:	79a2                	ld	s3,40(sp)
    80002590:	7a02                	ld	s4,32(sp)
    80002592:	6ae2                	ld	s5,24(sp)
    80002594:	6b42                	ld	s6,16(sp)
    80002596:	6ba2                	ld	s7,8(sp)
    80002598:	6c02                	ld	s8,0(sp)
    8000259a:	6161                	addi	sp,sp,80
    8000259c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000259e:	85e2                	mv	a1,s8
    800025a0:	854a                	mv	a0,s2
    800025a2:	00000097          	auipc	ra,0x0
    800025a6:	c02080e7          	jalr	-1022(ra) # 800021a4 <sleep>
    havekids = 0;
    800025aa:	bf39                	j	800024c8 <wait+0x4a>

00000000800025ac <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	84aa                	mv	s1,a0
    800025be:	892e                	mv	s2,a1
    800025c0:	89b2                	mv	s3,a2
    800025c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	538080e7          	jalr	1336(ra) # 80001afc <myproc>
  if(user_dst){
    800025cc:	c08d                	beqz	s1,800025ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025ce:	86d2                	mv	a3,s4
    800025d0:	864e                	mv	a2,s3
    800025d2:	85ca                	mv	a1,s2
    800025d4:	6928                	ld	a0,80(a0)
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	1b2080e7          	jalr	434(ra) # 80001788 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025de:	70a2                	ld	ra,40(sp)
    800025e0:	7402                	ld	s0,32(sp)
    800025e2:	64e2                	ld	s1,24(sp)
    800025e4:	6942                	ld	s2,16(sp)
    800025e6:	69a2                	ld	s3,8(sp)
    800025e8:	6a02                	ld	s4,0(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
    memmove((char *)dst, src, len);
    800025ee:	000a061b          	sext.w	a2,s4
    800025f2:	85ce                	mv	a1,s3
    800025f4:	854a                	mv	a0,s2
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	86e080e7          	jalr	-1938(ra) # 80000e64 <memmove>
    return 0;
    800025fe:	8526                	mv	a0,s1
    80002600:	bff9                	j	800025de <either_copyout+0x32>

0000000080002602 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002602:	7179                	addi	sp,sp,-48
    80002604:	f406                	sd	ra,40(sp)
    80002606:	f022                	sd	s0,32(sp)
    80002608:	ec26                	sd	s1,24(sp)
    8000260a:	e84a                	sd	s2,16(sp)
    8000260c:	e44e                	sd	s3,8(sp)
    8000260e:	e052                	sd	s4,0(sp)
    80002610:	1800                	addi	s0,sp,48
    80002612:	892a                	mv	s2,a0
    80002614:	84ae                	mv	s1,a1
    80002616:	89b2                	mv	s3,a2
    80002618:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	4e2080e7          	jalr	1250(ra) # 80001afc <myproc>
  if(user_src){
    80002622:	c08d                	beqz	s1,80002644 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002624:	86d2                	mv	a3,s4
    80002626:	864e                	mv	a2,s3
    80002628:	85ca                	mv	a1,s2
    8000262a:	6928                	ld	a0,80(a0)
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	21c080e7          	jalr	540(ra) # 80001848 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002634:	70a2                	ld	ra,40(sp)
    80002636:	7402                	ld	s0,32(sp)
    80002638:	64e2                	ld	s1,24(sp)
    8000263a:	6942                	ld	s2,16(sp)
    8000263c:	69a2                	ld	s3,8(sp)
    8000263e:	6a02                	ld	s4,0(sp)
    80002640:	6145                	addi	sp,sp,48
    80002642:	8082                	ret
    memmove(dst, (char*)src, len);
    80002644:	000a061b          	sext.w	a2,s4
    80002648:	85ce                	mv	a1,s3
    8000264a:	854a                	mv	a0,s2
    8000264c:	fffff097          	auipc	ra,0xfffff
    80002650:	818080e7          	jalr	-2024(ra) # 80000e64 <memmove>
    return 0;
    80002654:	8526                	mv	a0,s1
    80002656:	bff9                	j	80002634 <either_copyin+0x32>

0000000080002658 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002658:	715d                	addi	sp,sp,-80
    8000265a:	e486                	sd	ra,72(sp)
    8000265c:	e0a2                	sd	s0,64(sp)
    8000265e:	fc26                	sd	s1,56(sp)
    80002660:	f84a                	sd	s2,48(sp)
    80002662:	f44e                	sd	s3,40(sp)
    80002664:	f052                	sd	s4,32(sp)
    80002666:	ec56                	sd	s5,24(sp)
    80002668:	e85a                	sd	s6,16(sp)
    8000266a:	e45e                	sd	s7,8(sp)
    8000266c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000266e:	00006517          	auipc	a0,0x6
    80002672:	a9250513          	addi	a0,a0,-1390 # 80008100 <digits+0xc0>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	f14080e7          	jalr	-236(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267e:	0022f497          	auipc	s1,0x22f
    80002682:	aaa48493          	addi	s1,s1,-1366 # 80231128 <proc+0x158>
    80002686:	00236917          	auipc	s2,0x236
    8000268a:	ca290913          	addi	s2,s2,-862 # 80238328 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002690:	00006997          	auipc	s3,0x6
    80002694:	c2898993          	addi	s3,s3,-984 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    80002698:	00006a97          	auipc	s5,0x6
    8000269c:	c28a8a93          	addi	s5,s5,-984 # 800082c0 <digits+0x280>
    printf("\n");
    800026a0:	00006a17          	auipc	s4,0x6
    800026a4:	a60a0a13          	addi	s4,s4,-1440 # 80008100 <digits+0xc0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a8:	00006b97          	auipc	s7,0x6
    800026ac:	c58b8b93          	addi	s7,s7,-936 # 80008300 <states.0>
    800026b0:	a00d                	j	800026d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026b2:	ed86a583          	lw	a1,-296(a3)
    800026b6:	8556                	mv	a0,s5
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	ed2080e7          	jalr	-302(ra) # 8000058a <printf>
    printf("\n");
    800026c0:	8552                	mv	a0,s4
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	ec8080e7          	jalr	-312(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026ca:	1c848493          	addi	s1,s1,456
    800026ce:	03248263          	beq	s1,s2,800026f2 <procdump+0x9a>
    if(p->state == UNUSED)
    800026d2:	86a6                	mv	a3,s1
    800026d4:	ec04a783          	lw	a5,-320(s1)
    800026d8:	dbed                	beqz	a5,800026ca <procdump+0x72>
      state = "???";
    800026da:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	fcfb6be3          	bltu	s6,a5,800026b2 <procdump+0x5a>
    800026e0:	02079713          	slli	a4,a5,0x20
    800026e4:	01d75793          	srli	a5,a4,0x1d
    800026e8:	97de                	add	a5,a5,s7
    800026ea:	6390                	ld	a2,0(a5)
    800026ec:	f279                	bnez	a2,800026b2 <procdump+0x5a>
      state = "???";
    800026ee:	864e                	mv	a2,s3
    800026f0:	b7c9                	j	800026b2 <procdump+0x5a>
  }
}
    800026f2:	60a6                	ld	ra,72(sp)
    800026f4:	6406                	ld	s0,64(sp)
    800026f6:	74e2                	ld	s1,56(sp)
    800026f8:	7942                	ld	s2,48(sp)
    800026fa:	79a2                	ld	s3,40(sp)
    800026fc:	7a02                	ld	s4,32(sp)
    800026fe:	6ae2                	ld	s5,24(sp)
    80002700:	6b42                	ld	s6,16(sp)
    80002702:	6ba2                	ld	s7,8(sp)
    80002704:	6161                	addi	sp,sp,80
    80002706:	8082                	ret

0000000080002708 <swtch>:
    80002708:	00153023          	sd	ra,0(a0)
    8000270c:	00253423          	sd	sp,8(a0)
    80002710:	e900                	sd	s0,16(a0)
    80002712:	ed04                	sd	s1,24(a0)
    80002714:	03253023          	sd	s2,32(a0)
    80002718:	03353423          	sd	s3,40(a0)
    8000271c:	03453823          	sd	s4,48(a0)
    80002720:	03553c23          	sd	s5,56(a0)
    80002724:	05653023          	sd	s6,64(a0)
    80002728:	05753423          	sd	s7,72(a0)
    8000272c:	05853823          	sd	s8,80(a0)
    80002730:	05953c23          	sd	s9,88(a0)
    80002734:	07a53023          	sd	s10,96(a0)
    80002738:	07b53423          	sd	s11,104(a0)
    8000273c:	0005b083          	ld	ra,0(a1)
    80002740:	0085b103          	ld	sp,8(a1)
    80002744:	6980                	ld	s0,16(a1)
    80002746:	6d84                	ld	s1,24(a1)
    80002748:	0205b903          	ld	s2,32(a1)
    8000274c:	0285b983          	ld	s3,40(a1)
    80002750:	0305ba03          	ld	s4,48(a1)
    80002754:	0385ba83          	ld	s5,56(a1)
    80002758:	0405bb03          	ld	s6,64(a1)
    8000275c:	0485bb83          	ld	s7,72(a1)
    80002760:	0505bc03          	ld	s8,80(a1)
    80002764:	0585bc83          	ld	s9,88(a1)
    80002768:	0605bd03          	ld	s10,96(a1)
    8000276c:	0685bd83          	ld	s11,104(a1)
    80002770:	8082                	ret

0000000080002772 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002772:	1141                	addi	sp,sp,-16
    80002774:	e406                	sd	ra,8(sp)
    80002776:	e022                	sd	s0,0(sp)
    80002778:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000277a:	00006597          	auipc	a1,0x6
    8000277e:	bb658593          	addi	a1,a1,-1098 # 80008330 <states.0+0x30>
    80002782:	00236517          	auipc	a0,0x236
    80002786:	a4e50513          	addi	a0,a0,-1458 # 802381d0 <tickslock>
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	4f2080e7          	jalr	1266(ra) # 80000c7c <initlock>
}
    80002792:	60a2                	ld	ra,8(sp)
    80002794:	6402                	ld	s0,0(sp)
    80002796:	0141                	addi	sp,sp,16
    80002798:	8082                	ret

000000008000279a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000279a:	1141                	addi	sp,sp,-16
    8000279c:	e422                	sd	s0,8(sp)
    8000279e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a0:	00003797          	auipc	a5,0x3
    800027a4:	5e078793          	addi	a5,a5,1504 # 80005d80 <kernelvec>
    800027a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027ac:	6422                	ld	s0,8(sp)
    800027ae:	0141                	addi	sp,sp,16
    800027b0:	8082                	ret

00000000800027b2 <cowfault>:

int cowfault(pagetable_t pagetable, uint64 va)
{
  if (va >= MAXVA)
    800027b2:	57fd                	li	a5,-1
    800027b4:	83e9                	srli	a5,a5,0x1a
    800027b6:	06b7e863          	bltu	a5,a1,80002826 <cowfault+0x74>
{
    800027ba:	7179                	addi	sp,sp,-48
    800027bc:	f406                	sd	ra,40(sp)
    800027be:	f022                	sd	s0,32(sp)
    800027c0:	ec26                	sd	s1,24(sp)
    800027c2:	e84a                	sd	s2,16(sp)
    800027c4:	e44e                	sd	s3,8(sp)
    800027c6:	1800                	addi	s0,sp,48
    return -1;
  pte_t *pte = walk(pagetable, va, 0);
    800027c8:	4601                	li	a2,0
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	922080e7          	jalr	-1758(ra) # 800010ec <walk>
    800027d2:	89aa                	mv	s3,a0
  if (pte == 0)
    800027d4:	c939                	beqz	a0,8000282a <cowfault+0x78>
    return -1;
  if ((*pte & PTE_U) == 0 || (*pte & PTE_V) == 0)
    800027d6:	610c                	ld	a1,0(a0)
    800027d8:	0115f713          	andi	a4,a1,17
    800027dc:	47c5                	li	a5,17
    800027de:	04f71863          	bne	a4,a5,8000282e <cowfault+0x7c>
    return -1;
  uint64 pa1 = PTE2PA(*pte);
    800027e2:	81a9                	srli	a1,a1,0xa
    800027e4:	00c59913          	slli	s2,a1,0xc
  uint64 pa2 = (uint64)kalloc();
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <kalloc>
    800027f0:	84aa                	mv	s1,a0
  if (pa2 == 0)
    800027f2:	c121                	beqz	a0,80002832 <cowfault+0x80>
  {
    // panic("cow panic kalloc");
    return -1;
  }

  memmove((void *)pa2, (void *)pa1, PGSIZE);
    800027f4:	6605                	lui	a2,0x1
    800027f6:	85ca                	mv	a1,s2
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	66c080e7          	jalr	1644(ra) # 80000e64 <memmove>
  *pte = PA2PTE(pa2) | PTE_U | PTE_V | PTE_W | PTE_X | PTE_R;
    80002800:	80b1                	srli	s1,s1,0xc
    80002802:	04aa                	slli	s1,s1,0xa
    80002804:	01f4e493          	ori	s1,s1,31
    80002808:	0099b023          	sd	s1,0(s3)
  kfree((void *)pa1);
    8000280c:	854a                	mv	a0,s2
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	252080e7          	jalr	594(ra) # 80000a60 <kfree>
  return 0;
    80002816:	4501                	li	a0,0
}
    80002818:	70a2                	ld	ra,40(sp)
    8000281a:	7402                	ld	s0,32(sp)
    8000281c:	64e2                	ld	s1,24(sp)
    8000281e:	6942                	ld	s2,16(sp)
    80002820:	69a2                	ld	s3,8(sp)
    80002822:	6145                	addi	sp,sp,48
    80002824:	8082                	ret
    return -1;
    80002826:	557d                	li	a0,-1
}
    80002828:	8082                	ret
    return -1;
    8000282a:	557d                	li	a0,-1
    8000282c:	b7f5                	j	80002818 <cowfault+0x66>
    return -1;
    8000282e:	557d                	li	a0,-1
    80002830:	b7e5                	j	80002818 <cowfault+0x66>
    return -1;
    80002832:	557d                	li	a0,-1
    80002834:	b7d5                	j	80002818 <cowfault+0x66>

0000000080002836 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002836:	1141                	addi	sp,sp,-16
    80002838:	e406                	sd	ra,8(sp)
    8000283a:	e022                	sd	s0,0(sp)
    8000283c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	2be080e7          	jalr	702(ra) # 80001afc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002846:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000284a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002850:	00004697          	auipc	a3,0x4
    80002854:	7b068693          	addi	a3,a3,1968 # 80007000 <_trampoline>
    80002858:	00004717          	auipc	a4,0x4
    8000285c:	7a870713          	addi	a4,a4,1960 # 80007000 <_trampoline>
    80002860:	8f15                	sub	a4,a4,a3
    80002862:	040007b7          	lui	a5,0x4000
    80002866:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002868:	07b2                	slli	a5,a5,0xc
    8000286a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000286c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002870:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002872:	18002673          	csrr	a2,satp
    80002876:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002878:	6d30                	ld	a2,88(a0)
    8000287a:	6138                	ld	a4,64(a0)
    8000287c:	6585                	lui	a1,0x1
    8000287e:	972e                	add	a4,a4,a1
    80002880:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002882:	6d38                	ld	a4,88(a0)
    80002884:	00000617          	auipc	a2,0x0
    80002888:	13060613          	addi	a2,a2,304 # 800029b4 <usertrap>
    8000288c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000288e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002890:	8612                	mv	a2,tp
    80002892:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002894:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002898:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000289c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a0:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028a4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028a6:	6f18                	ld	a4,24(a4)
    800028a8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028ac:	6928                	ld	a0,80(a0)
    800028ae:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028b0:	00004717          	auipc	a4,0x4
    800028b4:	7ec70713          	addi	a4,a4,2028 # 8000709c <userret>
    800028b8:	8f15                	sub	a4,a4,a3
    800028ba:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028bc:	577d                	li	a4,-1
    800028be:	177e                	slli	a4,a4,0x3f
    800028c0:	8d59                	or	a0,a0,a4
    800028c2:	9782                	jalr	a5
}
    800028c4:	60a2                	ld	ra,8(sp)
    800028c6:	6402                	ld	s0,0(sp)
    800028c8:	0141                	addi	sp,sp,16
    800028ca:	8082                	ret

00000000800028cc <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028cc:	1101                	addi	sp,sp,-32
    800028ce:	ec06                	sd	ra,24(sp)
    800028d0:	e822                	sd	s0,16(sp)
    800028d2:	e426                	sd	s1,8(sp)
    800028d4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028d6:	00236497          	auipc	s1,0x236
    800028da:	8fa48493          	addi	s1,s1,-1798 # 802381d0 <tickslock>
    800028de:	8526                	mv	a0,s1
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	42c080e7          	jalr	1068(ra) # 80000d0c <acquire>
  ticks++;
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	04850513          	addi	a0,a0,72 # 80008930 <ticks>
    800028f0:	411c                	lw	a5,0(a0)
    800028f2:	2785                	addiw	a5,a5,1
    800028f4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	912080e7          	jalr	-1774(ra) # 80002208 <wakeup>
  release(&tickslock);
    800028fe:	8526                	mv	a0,s1
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	4c0080e7          	jalr	1216(ra) # 80000dc0 <release>
}
    80002908:	60e2                	ld	ra,24(sp)
    8000290a:	6442                	ld	s0,16(sp)
    8000290c:	64a2                	ld	s1,8(sp)
    8000290e:	6105                	addi	sp,sp,32
    80002910:	8082                	ret

0000000080002912 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002920:	00074d63          	bltz	a4,8000293a <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002924:	57fd                	li	a5,-1
    80002926:	17fe                	slli	a5,a5,0x3f
    80002928:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000292a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000292c:	06f70363          	beq	a4,a5,80002992 <devintr+0x80>
  }
}
    80002930:	60e2                	ld	ra,24(sp)
    80002932:	6442                	ld	s0,16(sp)
    80002934:	64a2                	ld	s1,8(sp)
    80002936:	6105                	addi	sp,sp,32
    80002938:	8082                	ret
      (scause & 0xff) == 9)
    8000293a:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    8000293e:	46a5                	li	a3,9
    80002940:	fed792e3          	bne	a5,a3,80002924 <devintr+0x12>
    int irq = plic_claim();
    80002944:	00003097          	auipc	ra,0x3
    80002948:	544080e7          	jalr	1348(ra) # 80005e88 <plic_claim>
    8000294c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000294e:	47a9                	li	a5,10
    80002950:	02f50763          	beq	a0,a5,8000297e <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002954:	4785                	li	a5,1
    80002956:	02f50963          	beq	a0,a5,80002988 <devintr+0x76>
    return 1;
    8000295a:	4505                	li	a0,1
    else if (irq)
    8000295c:	d8f1                	beqz	s1,80002930 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000295e:	85a6                	mv	a1,s1
    80002960:	00006517          	auipc	a0,0x6
    80002964:	9d850513          	addi	a0,a0,-1576 # 80008338 <states.0+0x38>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c22080e7          	jalr	-990(ra) # 8000058a <printf>
      plic_complete(irq);
    80002970:	8526                	mv	a0,s1
    80002972:	00003097          	auipc	ra,0x3
    80002976:	53a080e7          	jalr	1338(ra) # 80005eac <plic_complete>
    return 1;
    8000297a:	4505                	li	a0,1
    8000297c:	bf55                	j	80002930 <devintr+0x1e>
      uartintr();
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	01a080e7          	jalr	26(ra) # 80000998 <uartintr>
    80002986:	b7ed                	j	80002970 <devintr+0x5e>
      virtio_disk_intr();
    80002988:	00004097          	auipc	ra,0x4
    8000298c:	9ec080e7          	jalr	-1556(ra) # 80006374 <virtio_disk_intr>
    80002990:	b7c5                	j	80002970 <devintr+0x5e>
    if (cpuid() == 0)
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	13e080e7          	jalr	318(ra) # 80001ad0 <cpuid>
    8000299a:	c901                	beqz	a0,800029aa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000299c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029a0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029a2:	14479073          	csrw	sip,a5
    return 2;
    800029a6:	4509                	li	a0,2
    800029a8:	b761                	j	80002930 <devintr+0x1e>
      clockintr();
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	f22080e7          	jalr	-222(ra) # 800028cc <clockintr>
    800029b2:	b7ed                	j	8000299c <devintr+0x8a>

00000000800029b4 <usertrap>:
{
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	e04a                	sd	s2,0(sp)
    800029be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029c4:	1007f793          	andi	a5,a5,256
    800029c8:	e7b9                	bnez	a5,80002a16 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ca:	00003797          	auipc	a5,0x3
    800029ce:	3b678793          	addi	a5,a5,950 # 80005d80 <kernelvec>
    800029d2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	126080e7          	jalr	294(ra) # 80001afc <myproc>
    800029de:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029e0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e2:	14102773          	csrr	a4,sepc
    800029e6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e8:	14202773          	csrr	a4,scause
  if (r_scause() == 15)
    800029ec:	47bd                	li	a5,15
    800029ee:	02f70c63          	beq	a4,a5,80002a26 <usertrap+0x72>
    800029f2:	14202773          	csrr	a4,scause
  else if (r_scause() == 8)
    800029f6:	47a1                	li	a5,8
    800029f8:	04f70363          	beq	a4,a5,80002a3e <usertrap+0x8a>
  else if ((which_dev = devintr()) != 0)
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	f16080e7          	jalr	-234(ra) # 80002912 <devintr>
    80002a04:	892a                	mv	s2,a0
    80002a06:	c549                	beqz	a0,80002a90 <usertrap+0xdc>
  if (killed(p))
    80002a08:	8526                	mv	a0,s1
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	a42080e7          	jalr	-1470(ra) # 8000244c <killed>
    80002a12:	c171                	beqz	a0,80002ad6 <usertrap+0x122>
    80002a14:	a865                	j	80002acc <usertrap+0x118>
    panic("usertrap: not from user mode");
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	94250513          	addi	a0,a0,-1726 # 80008358 <states.0+0x58>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b22080e7          	jalr	-1246(ra) # 80000540 <panic>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a26:	143025f3          	csrr	a1,stval
    if ((cowfault(p->pagetable, r_stval())) < 0)
    80002a2a:	6928                	ld	a0,80(a0)
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	d86080e7          	jalr	-634(ra) # 800027b2 <cowfault>
    80002a34:	02055863          	bgez	a0,80002a64 <usertrap+0xb0>
      p->killed = 1;
    80002a38:	4785                	li	a5,1
    80002a3a:	d49c                	sw	a5,40(s1)
    80002a3c:	a025                	j	80002a64 <usertrap+0xb0>
    if (killed(p))
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	a0e080e7          	jalr	-1522(ra) # 8000244c <killed>
    80002a46:	ed1d                	bnez	a0,80002a84 <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002a48:	6cb8                	ld	a4,88(s1)
    80002a4a:	6f1c                	ld	a5,24(a4)
    80002a4c:	0791                	addi	a5,a5,4
    80002a4e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a58:	10079073          	csrw	sstatus,a5
    syscall();
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	2d4080e7          	jalr	724(ra) # 80002d30 <syscall>
  if (killed(p))
    80002a64:	8526                	mv	a0,s1
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	9e6080e7          	jalr	-1562(ra) # 8000244c <killed>
    80002a6e:	ed31                	bnez	a0,80002aca <usertrap+0x116>
  usertrapret();
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	dc6080e7          	jalr	-570(ra) # 80002836 <usertrapret>
}
    80002a78:	60e2                	ld	ra,24(sp)
    80002a7a:	6442                	ld	s0,16(sp)
    80002a7c:	64a2                	ld	s1,8(sp)
    80002a7e:	6902                	ld	s2,0(sp)
    80002a80:	6105                	addi	sp,sp,32
    80002a82:	8082                	ret
      exit(-1);
    80002a84:	557d                	li	a0,-1
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	852080e7          	jalr	-1966(ra) # 800022d8 <exit>
    80002a8e:	bf6d                	j	80002a48 <usertrap+0x94>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a90:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a94:	5890                	lw	a2,48(s1)
    80002a96:	00006517          	auipc	a0,0x6
    80002a9a:	8e250513          	addi	a0,a0,-1822 # 80008378 <states.0+0x78>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aec080e7          	jalr	-1300(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aaa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aae:	00006517          	auipc	a0,0x6
    80002ab2:	8fa50513          	addi	a0,a0,-1798 # 800083a8 <states.0+0xa8>
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	ad4080e7          	jalr	-1324(ra) # 8000058a <printf>
    setkilled(p);
    80002abe:	8526                	mv	a0,s1
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	960080e7          	jalr	-1696(ra) # 80002420 <setkilled>
    80002ac8:	bf71                	j	80002a64 <usertrap+0xb0>
  if (killed(p))
    80002aca:	4901                	li	s2,0
    exit(-1);
    80002acc:	557d                	li	a0,-1
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	80a080e7          	jalr	-2038(ra) # 800022d8 <exit>
  if (which_dev == 2)
    80002ad6:	4789                	li	a5,2
    80002ad8:	f8f91ce3          	bne	s2,a5,80002a70 <usertrap+0xbc>
    yield();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	68c080e7          	jalr	1676(ra) # 80002168 <yield>
    80002ae4:	b771                	j	80002a70 <usertrap+0xbc>

0000000080002ae6 <kerneltrap>:
{
    80002ae6:	7179                	addi	sp,sp,-48
    80002ae8:	f406                	sd	ra,40(sp)
    80002aea:	f022                	sd	s0,32(sp)
    80002aec:	ec26                	sd	s1,24(sp)
    80002aee:	e84a                	sd	s2,16(sp)
    80002af0:	e44e                	sd	s3,8(sp)
    80002af2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afc:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b00:	1004f793          	andi	a5,s1,256
    80002b04:	cb85                	beqz	a5,80002b34 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b06:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b0a:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b0c:	ef85                	bnez	a5,80002b44 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	e04080e7          	jalr	-508(ra) # 80002912 <devintr>
    80002b16:	cd1d                	beqz	a0,80002b54 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b18:	4789                	li	a5,2
    80002b1a:	06f50a63          	beq	a0,a5,80002b8e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b1e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b22:	10049073          	csrw	sstatus,s1
}
    80002b26:	70a2                	ld	ra,40(sp)
    80002b28:	7402                	ld	s0,32(sp)
    80002b2a:	64e2                	ld	s1,24(sp)
    80002b2c:	6942                	ld	s2,16(sp)
    80002b2e:	69a2                	ld	s3,8(sp)
    80002b30:	6145                	addi	sp,sp,48
    80002b32:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b34:	00006517          	auipc	a0,0x6
    80002b38:	89450513          	addi	a0,a0,-1900 # 800083c8 <states.0+0xc8>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	a04080e7          	jalr	-1532(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	8ac50513          	addi	a0,a0,-1876 # 800083f0 <states.0+0xf0>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	9f4080e7          	jalr	-1548(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002b54:	85ce                	mv	a1,s3
    80002b56:	00006517          	auipc	a0,0x6
    80002b5a:	8ba50513          	addi	a0,a0,-1862 # 80008410 <states.0+0x110>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	a2c080e7          	jalr	-1492(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b66:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	8b250513          	addi	a0,a0,-1870 # 80008420 <states.0+0x120>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	a14080e7          	jalr	-1516(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	8ba50513          	addi	a0,a0,-1862 # 80008438 <states.0+0x138>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	9ba080e7          	jalr	-1606(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	f6e080e7          	jalr	-146(ra) # 80001afc <myproc>
    80002b96:	d541                	beqz	a0,80002b1e <kerneltrap+0x38>
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	f64080e7          	jalr	-156(ra) # 80001afc <myproc>
    80002ba0:	4d18                	lw	a4,24(a0)
    80002ba2:	4791                	li	a5,4
    80002ba4:	f6f71de3          	bne	a4,a5,80002b1e <kerneltrap+0x38>
    yield();
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	5c0080e7          	jalr	1472(ra) # 80002168 <yield>
    80002bb0:	b7bd                	j	80002b1e <kerneltrap+0x38>

0000000080002bb2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	1000                	addi	s0,sp,32
    80002bbc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	f3e080e7          	jalr	-194(ra) # 80001afc <myproc>
  switch (n) {
    80002bc6:	4795                	li	a5,5
    80002bc8:	0497e163          	bltu	a5,s1,80002c0a <argraw+0x58>
    80002bcc:	048a                	slli	s1,s1,0x2
    80002bce:	00006717          	auipc	a4,0x6
    80002bd2:	8a270713          	addi	a4,a4,-1886 # 80008470 <states.0+0x170>
    80002bd6:	94ba                	add	s1,s1,a4
    80002bd8:	409c                	lw	a5,0(s1)
    80002bda:	97ba                	add	a5,a5,a4
    80002bdc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bde:	6d3c                	ld	a5,88(a0)
    80002be0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	64a2                	ld	s1,8(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret
    return p->trapframe->a1;
    80002bec:	6d3c                	ld	a5,88(a0)
    80002bee:	7fa8                	ld	a0,120(a5)
    80002bf0:	bfcd                	j	80002be2 <argraw+0x30>
    return p->trapframe->a2;
    80002bf2:	6d3c                	ld	a5,88(a0)
    80002bf4:	63c8                	ld	a0,128(a5)
    80002bf6:	b7f5                	j	80002be2 <argraw+0x30>
    return p->trapframe->a3;
    80002bf8:	6d3c                	ld	a5,88(a0)
    80002bfa:	67c8                	ld	a0,136(a5)
    80002bfc:	b7dd                	j	80002be2 <argraw+0x30>
    return p->trapframe->a4;
    80002bfe:	6d3c                	ld	a5,88(a0)
    80002c00:	6bc8                	ld	a0,144(a5)
    80002c02:	b7c5                	j	80002be2 <argraw+0x30>
    return p->trapframe->a5;
    80002c04:	6d3c                	ld	a5,88(a0)
    80002c06:	6fc8                	ld	a0,152(a5)
    80002c08:	bfe9                	j	80002be2 <argraw+0x30>
  panic("argraw");
    80002c0a:	00006517          	auipc	a0,0x6
    80002c0e:	83e50513          	addi	a0,a0,-1986 # 80008448 <states.0+0x148>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	92e080e7          	jalr	-1746(ra) # 80000540 <panic>

0000000080002c1a <fetchaddr>:
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	e04a                	sd	s2,0(sp)
    80002c24:	1000                	addi	s0,sp,32
    80002c26:	84aa                	mv	s1,a0
    80002c28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	ed2080e7          	jalr	-302(ra) # 80001afc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c32:	653c                	ld	a5,72(a0)
    80002c34:	02f4f863          	bgeu	s1,a5,80002c64 <fetchaddr+0x4a>
    80002c38:	00848713          	addi	a4,s1,8
    80002c3c:	02e7e663          	bltu	a5,a4,80002c68 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c40:	46a1                	li	a3,8
    80002c42:	8626                	mv	a2,s1
    80002c44:	85ca                	mv	a1,s2
    80002c46:	6928                	ld	a0,80(a0)
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	c00080e7          	jalr	-1024(ra) # 80001848 <copyin>
    80002c50:	00a03533          	snez	a0,a0
    80002c54:	40a00533          	neg	a0,a0
}
    80002c58:	60e2                	ld	ra,24(sp)
    80002c5a:	6442                	ld	s0,16(sp)
    80002c5c:	64a2                	ld	s1,8(sp)
    80002c5e:	6902                	ld	s2,0(sp)
    80002c60:	6105                	addi	sp,sp,32
    80002c62:	8082                	ret
    return -1;
    80002c64:	557d                	li	a0,-1
    80002c66:	bfcd                	j	80002c58 <fetchaddr+0x3e>
    80002c68:	557d                	li	a0,-1
    80002c6a:	b7fd                	j	80002c58 <fetchaddr+0x3e>

0000000080002c6c <fetchstr>:
{
    80002c6c:	7179                	addi	sp,sp,-48
    80002c6e:	f406                	sd	ra,40(sp)
    80002c70:	f022                	sd	s0,32(sp)
    80002c72:	ec26                	sd	s1,24(sp)
    80002c74:	e84a                	sd	s2,16(sp)
    80002c76:	e44e                	sd	s3,8(sp)
    80002c78:	1800                	addi	s0,sp,48
    80002c7a:	892a                	mv	s2,a0
    80002c7c:	84ae                	mv	s1,a1
    80002c7e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	e7c080e7          	jalr	-388(ra) # 80001afc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c88:	86ce                	mv	a3,s3
    80002c8a:	864a                	mv	a2,s2
    80002c8c:	85a6                	mv	a1,s1
    80002c8e:	6928                	ld	a0,80(a0)
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	c46080e7          	jalr	-954(ra) # 800018d6 <copyinstr>
    80002c98:	00054e63          	bltz	a0,80002cb4 <fetchstr+0x48>
  return strlen(buf);
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	2e6080e7          	jalr	742(ra) # 80000f84 <strlen>
}
    80002ca6:	70a2                	ld	ra,40(sp)
    80002ca8:	7402                	ld	s0,32(sp)
    80002caa:	64e2                	ld	s1,24(sp)
    80002cac:	6942                	ld	s2,16(sp)
    80002cae:	69a2                	ld	s3,8(sp)
    80002cb0:	6145                	addi	sp,sp,48
    80002cb2:	8082                	ret
    return -1;
    80002cb4:	557d                	li	a0,-1
    80002cb6:	bfc5                	j	80002ca6 <fetchstr+0x3a>

0000000080002cb8 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	eee080e7          	jalr	-274(ra) # 80002bb2 <argraw>
    80002ccc:	c088                	sw	a0,0(s1)
  // return 0;
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	64a2                	ld	s1,8(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret

0000000080002cd8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	1000                	addi	s0,sp,32
    80002ce2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	ece080e7          	jalr	-306(ra) # 80002bb2 <argraw>
    80002cec:	e088                	sd	a0,0(s1)
  // return 0;
}
    80002cee:	60e2                	ld	ra,24(sp)
    80002cf0:	6442                	ld	s0,16(sp)
    80002cf2:	64a2                	ld	s1,8(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret

0000000080002cf8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cf8:	7179                	addi	sp,sp,-48
    80002cfa:	f406                	sd	ra,40(sp)
    80002cfc:	f022                	sd	s0,32(sp)
    80002cfe:	ec26                	sd	s1,24(sp)
    80002d00:	e84a                	sd	s2,16(sp)
    80002d02:	1800                	addi	s0,sp,48
    80002d04:	84ae                	mv	s1,a1
    80002d06:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d08:	fd840593          	addi	a1,s0,-40
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	fcc080e7          	jalr	-52(ra) # 80002cd8 <argaddr>
  return fetchstr(addr, buf, max);
    80002d14:	864a                	mv	a2,s2
    80002d16:	85a6                	mv	a1,s1
    80002d18:	fd843503          	ld	a0,-40(s0)
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	f50080e7          	jalr	-176(ra) # 80002c6c <fetchstr>
}
    80002d24:	70a2                	ld	ra,40(sp)
    80002d26:	7402                	ld	s0,32(sp)
    80002d28:	64e2                	ld	s1,24(sp)
    80002d2a:	6942                	ld	s2,16(sp)
    80002d2c:	6145                	addi	sp,sp,48
    80002d2e:	8082                	ret

0000000080002d30 <syscall>:
[SYS_trace]   sys_trace,
};

void
syscall(void)
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	e04a                	sd	s2,0(sp)
    80002d3a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	dc0080e7          	jalr	-576(ra) # 80001afc <myproc>
    80002d44:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d46:	05853903          	ld	s2,88(a0)
    80002d4a:	0a893783          	ld	a5,168(s2)
    80002d4e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d52:	37fd                	addiw	a5,a5,-1
    80002d54:	475d                	li	a4,23
    80002d56:	00f76f63          	bltu	a4,a5,80002d74 <syscall+0x44>
    80002d5a:	00369713          	slli	a4,a3,0x3
    80002d5e:	00005797          	auipc	a5,0x5
    80002d62:	72a78793          	addi	a5,a5,1834 # 80008488 <syscalls>
    80002d66:	97ba                	add	a5,a5,a4
    80002d68:	639c                	ld	a5,0(a5)
    80002d6a:	c789                	beqz	a5,80002d74 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d6c:	9782                	jalr	a5
    80002d6e:	06a93823          	sd	a0,112(s2)
    80002d72:	a839                	j	80002d90 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d74:	15848613          	addi	a2,s1,344
    80002d78:	588c                	lw	a1,48(s1)
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	6d650513          	addi	a0,a0,1750 # 80008450 <states.0+0x150>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	808080e7          	jalr	-2040(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d8a:	6cbc                	ld	a5,88(s1)
    80002d8c:	577d                	li	a4,-1
    80002d8e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d90:	60e2                	ld	ra,24(sp)
    80002d92:	6442                	ld	s0,16(sp)
    80002d94:	64a2                	ld	s1,8(sp)
    80002d96:	6902                	ld	s2,0(sp)
    80002d98:	6105                	addi	sp,sp,32
    80002d9a:	8082                	ret

0000000080002d9c <sys_exit>:
#include "proc.h"
// #include "date.h"

uint64
sys_exit(void)
{
    80002d9c:	1101                	addi	sp,sp,-32
    80002d9e:	ec06                	sd	ra,24(sp)
    80002da0:	e822                	sd	s0,16(sp)
    80002da2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002da4:	fec40593          	addi	a1,s0,-20
    80002da8:	4501                	li	a0,0
    80002daa:	00000097          	auipc	ra,0x0
    80002dae:	f0e080e7          	jalr	-242(ra) # 80002cb8 <argint>
  exit(n);
    80002db2:	fec42503          	lw	a0,-20(s0)
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	522080e7          	jalr	1314(ra) # 800022d8 <exit>
  return 0;  // not reached
}
    80002dbe:	4501                	li	a0,0
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret

0000000080002dc8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dc8:	1141                	addi	sp,sp,-16
    80002dca:	e406                	sd	ra,8(sp)
    80002dcc:	e022                	sd	s0,0(sp)
    80002dce:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	d2c080e7          	jalr	-724(ra) # 80001afc <myproc>
}
    80002dd8:	5908                	lw	a0,48(a0)
    80002dda:	60a2                	ld	ra,8(sp)
    80002ddc:	6402                	ld	s0,0(sp)
    80002dde:	0141                	addi	sp,sp,16
    80002de0:	8082                	ret

0000000080002de2 <sys_fork>:

uint64
sys_fork(void)
{
    80002de2:	1141                	addi	sp,sp,-16
    80002de4:	e406                	sd	ra,8(sp)
    80002de6:	e022                	sd	s0,0(sp)
    80002de8:	0800                	addi	s0,sp,16
  return fork();
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	0c8080e7          	jalr	200(ra) # 80001eb2 <fork>
}
    80002df2:	60a2                	ld	ra,8(sp)
    80002df4:	6402                	ld	s0,0(sp)
    80002df6:	0141                	addi	sp,sp,16
    80002df8:	8082                	ret

0000000080002dfa <sys_wait>:

uint64
sys_wait(void)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e02:	fe840593          	addi	a1,s0,-24
    80002e06:	4501                	li	a0,0
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	ed0080e7          	jalr	-304(ra) # 80002cd8 <argaddr>
  return wait(p);
    80002e10:	fe843503          	ld	a0,-24(s0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	66a080e7          	jalr	1642(ra) # 8000247e <wait>
}
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	6105                	addi	sp,sp,32
    80002e22:	8082                	ret

0000000080002e24 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e24:	7179                	addi	sp,sp,-48
    80002e26:	f406                	sd	ra,40(sp)
    80002e28:	f022                	sd	s0,32(sp)
    80002e2a:	ec26                	sd	s1,24(sp)
    80002e2c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e2e:	fdc40593          	addi	a1,s0,-36
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	e84080e7          	jalr	-380(ra) # 80002cb8 <argint>
  addr = myproc()->sz;
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	cc0080e7          	jalr	-832(ra) # 80001afc <myproc>
    80002e44:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e46:	fdc42503          	lw	a0,-36(s0)
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	00c080e7          	jalr	12(ra) # 80001e56 <growproc>
    80002e52:	00054863          	bltz	a0,80002e62 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e56:	8526                	mv	a0,s1
    80002e58:	70a2                	ld	ra,40(sp)
    80002e5a:	7402                	ld	s0,32(sp)
    80002e5c:	64e2                	ld	s1,24(sp)
    80002e5e:	6145                	addi	sp,sp,48
    80002e60:	8082                	ret
    return -1;
    80002e62:	54fd                	li	s1,-1
    80002e64:	bfcd                	j	80002e56 <sys_sbrk+0x32>

0000000080002e66 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e66:	7139                	addi	sp,sp,-64
    80002e68:	fc06                	sd	ra,56(sp)
    80002e6a:	f822                	sd	s0,48(sp)
    80002e6c:	f426                	sd	s1,40(sp)
    80002e6e:	f04a                	sd	s2,32(sp)
    80002e70:	ec4e                	sd	s3,24(sp)
    80002e72:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e74:	fcc40593          	addi	a1,s0,-52
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	e3e080e7          	jalr	-450(ra) # 80002cb8 <argint>
  acquire(&tickslock);
    80002e82:	00235517          	auipc	a0,0x235
    80002e86:	34e50513          	addi	a0,a0,846 # 802381d0 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	e82080e7          	jalr	-382(ra) # 80000d0c <acquire>
  ticks0 = ticks;
    80002e92:	00006917          	auipc	s2,0x6
    80002e96:	a9e92903          	lw	s2,-1378(s2) # 80008930 <ticks>
  while(ticks - ticks0 < n){
    80002e9a:	fcc42783          	lw	a5,-52(s0)
    80002e9e:	cf9d                	beqz	a5,80002edc <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ea0:	00235997          	auipc	s3,0x235
    80002ea4:	33098993          	addi	s3,s3,816 # 802381d0 <tickslock>
    80002ea8:	00006497          	auipc	s1,0x6
    80002eac:	a8848493          	addi	s1,s1,-1400 # 80008930 <ticks>
    if(killed(myproc())){
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	c4c080e7          	jalr	-948(ra) # 80001afc <myproc>
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	594080e7          	jalr	1428(ra) # 8000244c <killed>
    80002ec0:	ed15                	bnez	a0,80002efc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ec2:	85ce                	mv	a1,s3
    80002ec4:	8526                	mv	a0,s1
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	2de080e7          	jalr	734(ra) # 800021a4 <sleep>
  while(ticks - ticks0 < n){
    80002ece:	409c                	lw	a5,0(s1)
    80002ed0:	412787bb          	subw	a5,a5,s2
    80002ed4:	fcc42703          	lw	a4,-52(s0)
    80002ed8:	fce7ece3          	bltu	a5,a4,80002eb0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002edc:	00235517          	auipc	a0,0x235
    80002ee0:	2f450513          	addi	a0,a0,756 # 802381d0 <tickslock>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	edc080e7          	jalr	-292(ra) # 80000dc0 <release>
  return 0;
    80002eec:	4501                	li	a0,0
}
    80002eee:	70e2                	ld	ra,56(sp)
    80002ef0:	7442                	ld	s0,48(sp)
    80002ef2:	74a2                	ld	s1,40(sp)
    80002ef4:	7902                	ld	s2,32(sp)
    80002ef6:	69e2                	ld	s3,24(sp)
    80002ef8:	6121                	addi	sp,sp,64
    80002efa:	8082                	ret
      release(&tickslock);
    80002efc:	00235517          	auipc	a0,0x235
    80002f00:	2d450513          	addi	a0,a0,724 # 802381d0 <tickslock>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	ebc080e7          	jalr	-324(ra) # 80000dc0 <release>
      return -1;
    80002f0c:	557d                	li	a0,-1
    80002f0e:	b7c5                	j	80002eee <sys_sleep+0x88>

0000000080002f10 <sys_kill>:

uint64
sys_kill(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f18:	fec40593          	addi	a1,s0,-20
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	d9a080e7          	jalr	-614(ra) # 80002cb8 <argint>
  return kill(pid);
    80002f26:	fec42503          	lw	a0,-20(s0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	484080e7          	jalr	1156(ra) # 800023ae <kill>
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	e426                	sd	s1,8(sp)
    80002f42:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f44:	00235517          	auipc	a0,0x235
    80002f48:	28c50513          	addi	a0,a0,652 # 802381d0 <tickslock>
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	dc0080e7          	jalr	-576(ra) # 80000d0c <acquire>
  xticks = ticks;
    80002f54:	00006497          	auipc	s1,0x6
    80002f58:	9dc4a483          	lw	s1,-1572(s1) # 80008930 <ticks>
  release(&tickslock);
    80002f5c:	00235517          	auipc	a0,0x235
    80002f60:	27450513          	addi	a0,a0,628 # 802381d0 <tickslock>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	e5c080e7          	jalr	-420(ra) # 80000dc0 <release>
  return xticks;
}
    80002f6c:	02049513          	slli	a0,s1,0x20
    80002f70:	9101                	srli	a0,a0,0x20
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	64a2                	ld	s1,8(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret

0000000080002f7c <sys_trace>:

uint64
sys_trace(void)
{
    80002f7c:	1101                	addi	sp,sp,-32
    80002f7e:	ec06                	sd	ra,24(sp)
    80002f80:	e822                	sd	s0,16(sp)
    80002f82:	1000                	addi	s0,sp,32
  int mask;
  int zero = 0;
  argint(zero, &mask);
    80002f84:	fec40593          	addi	a1,s0,-20
    80002f88:	4501                	li	a0,0
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	d2e080e7          	jalr	-722(ra) # 80002cb8 <argint>
  if(mask < 0) return -1;
    80002f92:	fec42783          	lw	a5,-20(s0)
    80002f96:	557d                	li	a0,-1
    80002f98:	0207c463          	bltz	a5,80002fc0 <sys_trace+0x44>
  struct proc* p = myproc();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	b60080e7          	jalr	-1184(ra) # 80001afc <myproc>
  if(mask == 0)
    80002fa4:	fec42603          	lw	a2,-20(s0)
    80002fa8:	e205                	bnez	a2,80002fc8 <sys_trace+0x4c>
    80002faa:	16850793          	addi	a5,a0,360
    80002fae:	1a450713          	addi	a4,a0,420
  {
    for(int i = 0; i<30; i++)
      p->trac[i] = 1;
    80002fb2:	4685                	li	a3,1
    80002fb4:	00d79023          	sh	a3,0(a5)
    for(int i = 0; i<30; i++)
    80002fb8:	0789                	addi	a5,a5,2
    80002fba:	fee79de3          	bne	a5,a4,80002fb4 <sys_trace+0x38>
      mask = mask>>1;
      if(mask%2 != 0)
        p->trac[i] = 1;
    }
  }
  return 0;
    80002fbe:	4501                	li	a0,0
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	6105                	addi	sp,sp,32
    80002fc6:	8082                	ret
    80002fc8:	16a50713          	addi	a4,a0,362
    80002fcc:	1a450693          	addi	a3,a0,420
        p->trac[i] = 1;
    80002fd0:	4585                	li	a1,1
    80002fd2:	a021                	j	80002fda <sys_trace+0x5e>
    for(int i = 1; i<30; i++)
    80002fd4:	0709                	addi	a4,a4,2
    80002fd6:	00d70b63          	beq	a4,a3,80002fec <sys_trace+0x70>
      mask = mask>>1;
    80002fda:	4016579b          	sraiw	a5,a2,0x1
    80002fde:	0007861b          	sext.w	a2,a5
      if(mask%2 != 0)
    80002fe2:	8b85                	andi	a5,a5,1
    80002fe4:	dbe5                	beqz	a5,80002fd4 <sys_trace+0x58>
        p->trac[i] = 1;
    80002fe6:	00b71023          	sh	a1,0(a4)
    80002fea:	b7ed                	j	80002fd4 <sys_trace+0x58>
  return 0;
    80002fec:	4501                	li	a0,0
    80002fee:	bfc9                	j	80002fc0 <sys_trace+0x44>

0000000080002ff0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ff0:	7179                	addi	sp,sp,-48
    80002ff2:	f406                	sd	ra,40(sp)
    80002ff4:	f022                	sd	s0,32(sp)
    80002ff6:	ec26                	sd	s1,24(sp)
    80002ff8:	e84a                	sd	s2,16(sp)
    80002ffa:	e44e                	sd	s3,8(sp)
    80002ffc:	e052                	sd	s4,0(sp)
    80002ffe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003000:	00005597          	auipc	a1,0x5
    80003004:	55058593          	addi	a1,a1,1360 # 80008550 <syscalls+0xc8>
    80003008:	00235517          	auipc	a0,0x235
    8000300c:	1e050513          	addi	a0,a0,480 # 802381e8 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	c6c080e7          	jalr	-916(ra) # 80000c7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003018:	0023d797          	auipc	a5,0x23d
    8000301c:	1d078793          	addi	a5,a5,464 # 802401e8 <bcache+0x8000>
    80003020:	0023d717          	auipc	a4,0x23d
    80003024:	43070713          	addi	a4,a4,1072 # 80240450 <bcache+0x8268>
    80003028:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000302c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003030:	00235497          	auipc	s1,0x235
    80003034:	1d048493          	addi	s1,s1,464 # 80238200 <bcache+0x18>
    b->next = bcache.head.next;
    80003038:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000303a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000303c:	00005a17          	auipc	s4,0x5
    80003040:	51ca0a13          	addi	s4,s4,1308 # 80008558 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003044:	2b893783          	ld	a5,696(s2)
    80003048:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000304a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000304e:	85d2                	mv	a1,s4
    80003050:	01048513          	addi	a0,s1,16
    80003054:	00001097          	auipc	ra,0x1
    80003058:	4c8080e7          	jalr	1224(ra) # 8000451c <initsleeplock>
    bcache.head.next->prev = b;
    8000305c:	2b893783          	ld	a5,696(s2)
    80003060:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003062:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003066:	45848493          	addi	s1,s1,1112
    8000306a:	fd349de3          	bne	s1,s3,80003044 <binit+0x54>
  }
}
    8000306e:	70a2                	ld	ra,40(sp)
    80003070:	7402                	ld	s0,32(sp)
    80003072:	64e2                	ld	s1,24(sp)
    80003074:	6942                	ld	s2,16(sp)
    80003076:	69a2                	ld	s3,8(sp)
    80003078:	6a02                	ld	s4,0(sp)
    8000307a:	6145                	addi	sp,sp,48
    8000307c:	8082                	ret

000000008000307e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000307e:	7179                	addi	sp,sp,-48
    80003080:	f406                	sd	ra,40(sp)
    80003082:	f022                	sd	s0,32(sp)
    80003084:	ec26                	sd	s1,24(sp)
    80003086:	e84a                	sd	s2,16(sp)
    80003088:	e44e                	sd	s3,8(sp)
    8000308a:	1800                	addi	s0,sp,48
    8000308c:	892a                	mv	s2,a0
    8000308e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003090:	00235517          	auipc	a0,0x235
    80003094:	15850513          	addi	a0,a0,344 # 802381e8 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c74080e7          	jalr	-908(ra) # 80000d0c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030a0:	0023d497          	auipc	s1,0x23d
    800030a4:	4004b483          	ld	s1,1024(s1) # 802404a0 <bcache+0x82b8>
    800030a8:	0023d797          	auipc	a5,0x23d
    800030ac:	3a878793          	addi	a5,a5,936 # 80240450 <bcache+0x8268>
    800030b0:	02f48f63          	beq	s1,a5,800030ee <bread+0x70>
    800030b4:	873e                	mv	a4,a5
    800030b6:	a021                	j	800030be <bread+0x40>
    800030b8:	68a4                	ld	s1,80(s1)
    800030ba:	02e48a63          	beq	s1,a4,800030ee <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030be:	449c                	lw	a5,8(s1)
    800030c0:	ff279ce3          	bne	a5,s2,800030b8 <bread+0x3a>
    800030c4:	44dc                	lw	a5,12(s1)
    800030c6:	ff3799e3          	bne	a5,s3,800030b8 <bread+0x3a>
      b->refcnt++;
    800030ca:	40bc                	lw	a5,64(s1)
    800030cc:	2785                	addiw	a5,a5,1
    800030ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d0:	00235517          	auipc	a0,0x235
    800030d4:	11850513          	addi	a0,a0,280 # 802381e8 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	ce8080e7          	jalr	-792(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    800030e0:	01048513          	addi	a0,s1,16
    800030e4:	00001097          	auipc	ra,0x1
    800030e8:	472080e7          	jalr	1138(ra) # 80004556 <acquiresleep>
      return b;
    800030ec:	a8b9                	j	8000314a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ee:	0023d497          	auipc	s1,0x23d
    800030f2:	3aa4b483          	ld	s1,938(s1) # 80240498 <bcache+0x82b0>
    800030f6:	0023d797          	auipc	a5,0x23d
    800030fa:	35a78793          	addi	a5,a5,858 # 80240450 <bcache+0x8268>
    800030fe:	00f48863          	beq	s1,a5,8000310e <bread+0x90>
    80003102:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003104:	40bc                	lw	a5,64(s1)
    80003106:	cf81                	beqz	a5,8000311e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003108:	64a4                	ld	s1,72(s1)
    8000310a:	fee49de3          	bne	s1,a4,80003104 <bread+0x86>
  panic("bget: no buffers");
    8000310e:	00005517          	auipc	a0,0x5
    80003112:	45250513          	addi	a0,a0,1106 # 80008560 <syscalls+0xd8>
    80003116:	ffffd097          	auipc	ra,0xffffd
    8000311a:	42a080e7          	jalr	1066(ra) # 80000540 <panic>
      b->dev = dev;
    8000311e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003122:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003126:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000312a:	4785                	li	a5,1
    8000312c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000312e:	00235517          	auipc	a0,0x235
    80003132:	0ba50513          	addi	a0,a0,186 # 802381e8 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	c8a080e7          	jalr	-886(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    8000313e:	01048513          	addi	a0,s1,16
    80003142:	00001097          	auipc	ra,0x1
    80003146:	414080e7          	jalr	1044(ra) # 80004556 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000314a:	409c                	lw	a5,0(s1)
    8000314c:	cb89                	beqz	a5,8000315e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000314e:	8526                	mv	a0,s1
    80003150:	70a2                	ld	ra,40(sp)
    80003152:	7402                	ld	s0,32(sp)
    80003154:	64e2                	ld	s1,24(sp)
    80003156:	6942                	ld	s2,16(sp)
    80003158:	69a2                	ld	s3,8(sp)
    8000315a:	6145                	addi	sp,sp,48
    8000315c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000315e:	4581                	li	a1,0
    80003160:	8526                	mv	a0,s1
    80003162:	00003097          	auipc	ra,0x3
    80003166:	fe0080e7          	jalr	-32(ra) # 80006142 <virtio_disk_rw>
    b->valid = 1;
    8000316a:	4785                	li	a5,1
    8000316c:	c09c                	sw	a5,0(s1)
  return b;
    8000316e:	b7c5                	j	8000314e <bread+0xd0>

0000000080003170 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	e426                	sd	s1,8(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000317c:	0541                	addi	a0,a0,16
    8000317e:	00001097          	auipc	ra,0x1
    80003182:	472080e7          	jalr	1138(ra) # 800045f0 <holdingsleep>
    80003186:	cd01                	beqz	a0,8000319e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003188:	4585                	li	a1,1
    8000318a:	8526                	mv	a0,s1
    8000318c:	00003097          	auipc	ra,0x3
    80003190:	fb6080e7          	jalr	-74(ra) # 80006142 <virtio_disk_rw>
}
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	64a2                	ld	s1,8(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret
    panic("bwrite");
    8000319e:	00005517          	auipc	a0,0x5
    800031a2:	3da50513          	addi	a0,a0,986 # 80008578 <syscalls+0xf0>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	39a080e7          	jalr	922(ra) # 80000540 <panic>

00000000800031ae <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	e04a                	sd	s2,0(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031bc:	01050913          	addi	s2,a0,16
    800031c0:	854a                	mv	a0,s2
    800031c2:	00001097          	auipc	ra,0x1
    800031c6:	42e080e7          	jalr	1070(ra) # 800045f0 <holdingsleep>
    800031ca:	c92d                	beqz	a0,8000323c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031cc:	854a                	mv	a0,s2
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	3de080e7          	jalr	990(ra) # 800045ac <releasesleep>

  acquire(&bcache.lock);
    800031d6:	00235517          	auipc	a0,0x235
    800031da:	01250513          	addi	a0,a0,18 # 802381e8 <bcache>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	b2e080e7          	jalr	-1234(ra) # 80000d0c <acquire>
  b->refcnt--;
    800031e6:	40bc                	lw	a5,64(s1)
    800031e8:	37fd                	addiw	a5,a5,-1
    800031ea:	0007871b          	sext.w	a4,a5
    800031ee:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031f0:	eb05                	bnez	a4,80003220 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031f2:	68bc                	ld	a5,80(s1)
    800031f4:	64b8                	ld	a4,72(s1)
    800031f6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031f8:	64bc                	ld	a5,72(s1)
    800031fa:	68b8                	ld	a4,80(s1)
    800031fc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031fe:	0023d797          	auipc	a5,0x23d
    80003202:	fea78793          	addi	a5,a5,-22 # 802401e8 <bcache+0x8000>
    80003206:	2b87b703          	ld	a4,696(a5)
    8000320a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000320c:	0023d717          	auipc	a4,0x23d
    80003210:	24470713          	addi	a4,a4,580 # 80240450 <bcache+0x8268>
    80003214:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003216:	2b87b703          	ld	a4,696(a5)
    8000321a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000321c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003220:	00235517          	auipc	a0,0x235
    80003224:	fc850513          	addi	a0,a0,-56 # 802381e8 <bcache>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	b98080e7          	jalr	-1128(ra) # 80000dc0 <release>
}
    80003230:	60e2                	ld	ra,24(sp)
    80003232:	6442                	ld	s0,16(sp)
    80003234:	64a2                	ld	s1,8(sp)
    80003236:	6902                	ld	s2,0(sp)
    80003238:	6105                	addi	sp,sp,32
    8000323a:	8082                	ret
    panic("brelse");
    8000323c:	00005517          	auipc	a0,0x5
    80003240:	34450513          	addi	a0,a0,836 # 80008580 <syscalls+0xf8>
    80003244:	ffffd097          	auipc	ra,0xffffd
    80003248:	2fc080e7          	jalr	764(ra) # 80000540 <panic>

000000008000324c <bpin>:

void
bpin(struct buf *b) {
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003258:	00235517          	auipc	a0,0x235
    8000325c:	f9050513          	addi	a0,a0,-112 # 802381e8 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	aac080e7          	jalr	-1364(ra) # 80000d0c <acquire>
  b->refcnt++;
    80003268:	40bc                	lw	a5,64(s1)
    8000326a:	2785                	addiw	a5,a5,1
    8000326c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000326e:	00235517          	auipc	a0,0x235
    80003272:	f7a50513          	addi	a0,a0,-134 # 802381e8 <bcache>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	b4a080e7          	jalr	-1206(ra) # 80000dc0 <release>
}
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret

0000000080003288 <bunpin>:

void
bunpin(struct buf *b) {
    80003288:	1101                	addi	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	e426                	sd	s1,8(sp)
    80003290:	1000                	addi	s0,sp,32
    80003292:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003294:	00235517          	auipc	a0,0x235
    80003298:	f5450513          	addi	a0,a0,-172 # 802381e8 <bcache>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	a70080e7          	jalr	-1424(ra) # 80000d0c <acquire>
  b->refcnt--;
    800032a4:	40bc                	lw	a5,64(s1)
    800032a6:	37fd                	addiw	a5,a5,-1
    800032a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032aa:	00235517          	auipc	a0,0x235
    800032ae:	f3e50513          	addi	a0,a0,-194 # 802381e8 <bcache>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	b0e080e7          	jalr	-1266(ra) # 80000dc0 <release>
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret

00000000800032c4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	e04a                	sd	s2,0(sp)
    800032ce:	1000                	addi	s0,sp,32
    800032d0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032d2:	00d5d59b          	srliw	a1,a1,0xd
    800032d6:	0023d797          	auipc	a5,0x23d
    800032da:	5ee7a783          	lw	a5,1518(a5) # 802408c4 <sb+0x1c>
    800032de:	9dbd                	addw	a1,a1,a5
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	d9e080e7          	jalr	-610(ra) # 8000307e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032e8:	0074f713          	andi	a4,s1,7
    800032ec:	4785                	li	a5,1
    800032ee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032f2:	14ce                	slli	s1,s1,0x33
    800032f4:	90d9                	srli	s1,s1,0x36
    800032f6:	00950733          	add	a4,a0,s1
    800032fa:	05874703          	lbu	a4,88(a4)
    800032fe:	00e7f6b3          	and	a3,a5,a4
    80003302:	c69d                	beqz	a3,80003330 <bfree+0x6c>
    80003304:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003306:	94aa                	add	s1,s1,a0
    80003308:	fff7c793          	not	a5,a5
    8000330c:	8f7d                	and	a4,a4,a5
    8000330e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003312:	00001097          	auipc	ra,0x1
    80003316:	126080e7          	jalr	294(ra) # 80004438 <log_write>
  brelse(bp);
    8000331a:	854a                	mv	a0,s2
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	e92080e7          	jalr	-366(ra) # 800031ae <brelse>
}
    80003324:	60e2                	ld	ra,24(sp)
    80003326:	6442                	ld	s0,16(sp)
    80003328:	64a2                	ld	s1,8(sp)
    8000332a:	6902                	ld	s2,0(sp)
    8000332c:	6105                	addi	sp,sp,32
    8000332e:	8082                	ret
    panic("freeing free block");
    80003330:	00005517          	auipc	a0,0x5
    80003334:	25850513          	addi	a0,a0,600 # 80008588 <syscalls+0x100>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	208080e7          	jalr	520(ra) # 80000540 <panic>

0000000080003340 <balloc>:
{
    80003340:	711d                	addi	sp,sp,-96
    80003342:	ec86                	sd	ra,88(sp)
    80003344:	e8a2                	sd	s0,80(sp)
    80003346:	e4a6                	sd	s1,72(sp)
    80003348:	e0ca                	sd	s2,64(sp)
    8000334a:	fc4e                	sd	s3,56(sp)
    8000334c:	f852                	sd	s4,48(sp)
    8000334e:	f456                	sd	s5,40(sp)
    80003350:	f05a                	sd	s6,32(sp)
    80003352:	ec5e                	sd	s7,24(sp)
    80003354:	e862                	sd	s8,16(sp)
    80003356:	e466                	sd	s9,8(sp)
    80003358:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000335a:	0023d797          	auipc	a5,0x23d
    8000335e:	5527a783          	lw	a5,1362(a5) # 802408ac <sb+0x4>
    80003362:	cff5                	beqz	a5,8000345e <balloc+0x11e>
    80003364:	8baa                	mv	s7,a0
    80003366:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003368:	0023db17          	auipc	s6,0x23d
    8000336c:	540b0b13          	addi	s6,s6,1344 # 802408a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003370:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003372:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003374:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003376:	6c89                	lui	s9,0x2
    80003378:	a061                	j	80003400 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000337a:	97ca                	add	a5,a5,s2
    8000337c:	8e55                	or	a2,a2,a3
    8000337e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003382:	854a                	mv	a0,s2
    80003384:	00001097          	auipc	ra,0x1
    80003388:	0b4080e7          	jalr	180(ra) # 80004438 <log_write>
        brelse(bp);
    8000338c:	854a                	mv	a0,s2
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	e20080e7          	jalr	-480(ra) # 800031ae <brelse>
  bp = bread(dev, bno);
    80003396:	85a6                	mv	a1,s1
    80003398:	855e                	mv	a0,s7
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	ce4080e7          	jalr	-796(ra) # 8000307e <bread>
    800033a2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033a4:	40000613          	li	a2,1024
    800033a8:	4581                	li	a1,0
    800033aa:	05850513          	addi	a0,a0,88
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	a5a080e7          	jalr	-1446(ra) # 80000e08 <memset>
  log_write(bp);
    800033b6:	854a                	mv	a0,s2
    800033b8:	00001097          	auipc	ra,0x1
    800033bc:	080080e7          	jalr	128(ra) # 80004438 <log_write>
  brelse(bp);
    800033c0:	854a                	mv	a0,s2
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	dec080e7          	jalr	-532(ra) # 800031ae <brelse>
}
    800033ca:	8526                	mv	a0,s1
    800033cc:	60e6                	ld	ra,88(sp)
    800033ce:	6446                	ld	s0,80(sp)
    800033d0:	64a6                	ld	s1,72(sp)
    800033d2:	6906                	ld	s2,64(sp)
    800033d4:	79e2                	ld	s3,56(sp)
    800033d6:	7a42                	ld	s4,48(sp)
    800033d8:	7aa2                	ld	s5,40(sp)
    800033da:	7b02                	ld	s6,32(sp)
    800033dc:	6be2                	ld	s7,24(sp)
    800033de:	6c42                	ld	s8,16(sp)
    800033e0:	6ca2                	ld	s9,8(sp)
    800033e2:	6125                	addi	sp,sp,96
    800033e4:	8082                	ret
    brelse(bp);
    800033e6:	854a                	mv	a0,s2
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	dc6080e7          	jalr	-570(ra) # 800031ae <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033f0:	015c87bb          	addw	a5,s9,s5
    800033f4:	00078a9b          	sext.w	s5,a5
    800033f8:	004b2703          	lw	a4,4(s6)
    800033fc:	06eaf163          	bgeu	s5,a4,8000345e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003400:	41fad79b          	sraiw	a5,s5,0x1f
    80003404:	0137d79b          	srliw	a5,a5,0x13
    80003408:	015787bb          	addw	a5,a5,s5
    8000340c:	40d7d79b          	sraiw	a5,a5,0xd
    80003410:	01cb2583          	lw	a1,28(s6)
    80003414:	9dbd                	addw	a1,a1,a5
    80003416:	855e                	mv	a0,s7
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	c66080e7          	jalr	-922(ra) # 8000307e <bread>
    80003420:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003422:	004b2503          	lw	a0,4(s6)
    80003426:	000a849b          	sext.w	s1,s5
    8000342a:	8762                	mv	a4,s8
    8000342c:	faa4fde3          	bgeu	s1,a0,800033e6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003430:	00777693          	andi	a3,a4,7
    80003434:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003438:	41f7579b          	sraiw	a5,a4,0x1f
    8000343c:	01d7d79b          	srliw	a5,a5,0x1d
    80003440:	9fb9                	addw	a5,a5,a4
    80003442:	4037d79b          	sraiw	a5,a5,0x3
    80003446:	00f90633          	add	a2,s2,a5
    8000344a:	05864603          	lbu	a2,88(a2)
    8000344e:	00c6f5b3          	and	a1,a3,a2
    80003452:	d585                	beqz	a1,8000337a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003454:	2705                	addiw	a4,a4,1
    80003456:	2485                	addiw	s1,s1,1
    80003458:	fd471ae3          	bne	a4,s4,8000342c <balloc+0xec>
    8000345c:	b769                	j	800033e6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	14250513          	addi	a0,a0,322 # 800085a0 <syscalls+0x118>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	124080e7          	jalr	292(ra) # 8000058a <printf>
  return 0;
    8000346e:	4481                	li	s1,0
    80003470:	bfa9                	j	800033ca <balloc+0x8a>

0000000080003472 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003472:	7179                	addi	sp,sp,-48
    80003474:	f406                	sd	ra,40(sp)
    80003476:	f022                	sd	s0,32(sp)
    80003478:	ec26                	sd	s1,24(sp)
    8000347a:	e84a                	sd	s2,16(sp)
    8000347c:	e44e                	sd	s3,8(sp)
    8000347e:	e052                	sd	s4,0(sp)
    80003480:	1800                	addi	s0,sp,48
    80003482:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003484:	47ad                	li	a5,11
    80003486:	02b7e863          	bltu	a5,a1,800034b6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000348a:	02059793          	slli	a5,a1,0x20
    8000348e:	01e7d593          	srli	a1,a5,0x1e
    80003492:	00b504b3          	add	s1,a0,a1
    80003496:	0504a903          	lw	s2,80(s1)
    8000349a:	06091e63          	bnez	s2,80003516 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000349e:	4108                	lw	a0,0(a0)
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	ea0080e7          	jalr	-352(ra) # 80003340 <balloc>
    800034a8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034ac:	06090563          	beqz	s2,80003516 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800034b0:	0524a823          	sw	s2,80(s1)
    800034b4:	a08d                	j	80003516 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034b6:	ff45849b          	addiw	s1,a1,-12
    800034ba:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034be:	0ff00793          	li	a5,255
    800034c2:	08e7e563          	bltu	a5,a4,8000354c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034c6:	08052903          	lw	s2,128(a0)
    800034ca:	00091d63          	bnez	s2,800034e4 <bmap+0x72>
      addr = balloc(ip->dev);
    800034ce:	4108                	lw	a0,0(a0)
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	e70080e7          	jalr	-400(ra) # 80003340 <balloc>
    800034d8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034dc:	02090d63          	beqz	s2,80003516 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034e0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800034e4:	85ca                	mv	a1,s2
    800034e6:	0009a503          	lw	a0,0(s3)
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	b94080e7          	jalr	-1132(ra) # 8000307e <bread>
    800034f2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034f4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034f8:	02049713          	slli	a4,s1,0x20
    800034fc:	01e75593          	srli	a1,a4,0x1e
    80003500:	00b784b3          	add	s1,a5,a1
    80003504:	0004a903          	lw	s2,0(s1)
    80003508:	02090063          	beqz	s2,80003528 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000350c:	8552                	mv	a0,s4
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	ca0080e7          	jalr	-864(ra) # 800031ae <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003516:	854a                	mv	a0,s2
    80003518:	70a2                	ld	ra,40(sp)
    8000351a:	7402                	ld	s0,32(sp)
    8000351c:	64e2                	ld	s1,24(sp)
    8000351e:	6942                	ld	s2,16(sp)
    80003520:	69a2                	ld	s3,8(sp)
    80003522:	6a02                	ld	s4,0(sp)
    80003524:	6145                	addi	sp,sp,48
    80003526:	8082                	ret
      addr = balloc(ip->dev);
    80003528:	0009a503          	lw	a0,0(s3)
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	e14080e7          	jalr	-492(ra) # 80003340 <balloc>
    80003534:	0005091b          	sext.w	s2,a0
      if(addr){
    80003538:	fc090ae3          	beqz	s2,8000350c <bmap+0x9a>
        a[bn] = addr;
    8000353c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003540:	8552                	mv	a0,s4
    80003542:	00001097          	auipc	ra,0x1
    80003546:	ef6080e7          	jalr	-266(ra) # 80004438 <log_write>
    8000354a:	b7c9                	j	8000350c <bmap+0x9a>
  panic("bmap: out of range");
    8000354c:	00005517          	auipc	a0,0x5
    80003550:	06c50513          	addi	a0,a0,108 # 800085b8 <syscalls+0x130>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	fec080e7          	jalr	-20(ra) # 80000540 <panic>

000000008000355c <iget>:
{
    8000355c:	7179                	addi	sp,sp,-48
    8000355e:	f406                	sd	ra,40(sp)
    80003560:	f022                	sd	s0,32(sp)
    80003562:	ec26                	sd	s1,24(sp)
    80003564:	e84a                	sd	s2,16(sp)
    80003566:	e44e                	sd	s3,8(sp)
    80003568:	e052                	sd	s4,0(sp)
    8000356a:	1800                	addi	s0,sp,48
    8000356c:	89aa                	mv	s3,a0
    8000356e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003570:	0023d517          	auipc	a0,0x23d
    80003574:	35850513          	addi	a0,a0,856 # 802408c8 <itable>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	794080e7          	jalr	1940(ra) # 80000d0c <acquire>
  empty = 0;
    80003580:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003582:	0023d497          	auipc	s1,0x23d
    80003586:	35e48493          	addi	s1,s1,862 # 802408e0 <itable+0x18>
    8000358a:	0023f697          	auipc	a3,0x23f
    8000358e:	de668693          	addi	a3,a3,-538 # 80242370 <log>
    80003592:	a039                	j	800035a0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003594:	02090b63          	beqz	s2,800035ca <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003598:	08848493          	addi	s1,s1,136
    8000359c:	02d48a63          	beq	s1,a3,800035d0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035a0:	449c                	lw	a5,8(s1)
    800035a2:	fef059e3          	blez	a5,80003594 <iget+0x38>
    800035a6:	4098                	lw	a4,0(s1)
    800035a8:	ff3716e3          	bne	a4,s3,80003594 <iget+0x38>
    800035ac:	40d8                	lw	a4,4(s1)
    800035ae:	ff4713e3          	bne	a4,s4,80003594 <iget+0x38>
      ip->ref++;
    800035b2:	2785                	addiw	a5,a5,1
    800035b4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035b6:	0023d517          	auipc	a0,0x23d
    800035ba:	31250513          	addi	a0,a0,786 # 802408c8 <itable>
    800035be:	ffffe097          	auipc	ra,0xffffe
    800035c2:	802080e7          	jalr	-2046(ra) # 80000dc0 <release>
      return ip;
    800035c6:	8926                	mv	s2,s1
    800035c8:	a03d                	j	800035f6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ca:	f7f9                	bnez	a5,80003598 <iget+0x3c>
    800035cc:	8926                	mv	s2,s1
    800035ce:	b7e9                	j	80003598 <iget+0x3c>
  if(empty == 0)
    800035d0:	02090c63          	beqz	s2,80003608 <iget+0xac>
  ip->dev = dev;
    800035d4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035d8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035dc:	4785                	li	a5,1
    800035de:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035e2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035e6:	0023d517          	auipc	a0,0x23d
    800035ea:	2e250513          	addi	a0,a0,738 # 802408c8 <itable>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	7d2080e7          	jalr	2002(ra) # 80000dc0 <release>
}
    800035f6:	854a                	mv	a0,s2
    800035f8:	70a2                	ld	ra,40(sp)
    800035fa:	7402                	ld	s0,32(sp)
    800035fc:	64e2                	ld	s1,24(sp)
    800035fe:	6942                	ld	s2,16(sp)
    80003600:	69a2                	ld	s3,8(sp)
    80003602:	6a02                	ld	s4,0(sp)
    80003604:	6145                	addi	sp,sp,48
    80003606:	8082                	ret
    panic("iget: no inodes");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	fc850513          	addi	a0,a0,-56 # 800085d0 <syscalls+0x148>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f30080e7          	jalr	-208(ra) # 80000540 <panic>

0000000080003618 <fsinit>:
fsinit(int dev) {
    80003618:	7179                	addi	sp,sp,-48
    8000361a:	f406                	sd	ra,40(sp)
    8000361c:	f022                	sd	s0,32(sp)
    8000361e:	ec26                	sd	s1,24(sp)
    80003620:	e84a                	sd	s2,16(sp)
    80003622:	e44e                	sd	s3,8(sp)
    80003624:	1800                	addi	s0,sp,48
    80003626:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003628:	4585                	li	a1,1
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	a54080e7          	jalr	-1452(ra) # 8000307e <bread>
    80003632:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003634:	0023d997          	auipc	s3,0x23d
    80003638:	27498993          	addi	s3,s3,628 # 802408a8 <sb>
    8000363c:	02000613          	li	a2,32
    80003640:	05850593          	addi	a1,a0,88
    80003644:	854e                	mv	a0,s3
    80003646:	ffffe097          	auipc	ra,0xffffe
    8000364a:	81e080e7          	jalr	-2018(ra) # 80000e64 <memmove>
  brelse(bp);
    8000364e:	8526                	mv	a0,s1
    80003650:	00000097          	auipc	ra,0x0
    80003654:	b5e080e7          	jalr	-1186(ra) # 800031ae <brelse>
  if(sb.magic != FSMAGIC)
    80003658:	0009a703          	lw	a4,0(s3)
    8000365c:	102037b7          	lui	a5,0x10203
    80003660:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003664:	02f71263          	bne	a4,a5,80003688 <fsinit+0x70>
  initlog(dev, &sb);
    80003668:	0023d597          	auipc	a1,0x23d
    8000366c:	24058593          	addi	a1,a1,576 # 802408a8 <sb>
    80003670:	854a                	mv	a0,s2
    80003672:	00001097          	auipc	ra,0x1
    80003676:	b4a080e7          	jalr	-1206(ra) # 800041bc <initlog>
}
    8000367a:	70a2                	ld	ra,40(sp)
    8000367c:	7402                	ld	s0,32(sp)
    8000367e:	64e2                	ld	s1,24(sp)
    80003680:	6942                	ld	s2,16(sp)
    80003682:	69a2                	ld	s3,8(sp)
    80003684:	6145                	addi	sp,sp,48
    80003686:	8082                	ret
    panic("invalid file system");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	f5850513          	addi	a0,a0,-168 # 800085e0 <syscalls+0x158>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	eb0080e7          	jalr	-336(ra) # 80000540 <panic>

0000000080003698 <iinit>:
{
    80003698:	7179                	addi	sp,sp,-48
    8000369a:	f406                	sd	ra,40(sp)
    8000369c:	f022                	sd	s0,32(sp)
    8000369e:	ec26                	sd	s1,24(sp)
    800036a0:	e84a                	sd	s2,16(sp)
    800036a2:	e44e                	sd	s3,8(sp)
    800036a4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036a6:	00005597          	auipc	a1,0x5
    800036aa:	f5258593          	addi	a1,a1,-174 # 800085f8 <syscalls+0x170>
    800036ae:	0023d517          	auipc	a0,0x23d
    800036b2:	21a50513          	addi	a0,a0,538 # 802408c8 <itable>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	5c6080e7          	jalr	1478(ra) # 80000c7c <initlock>
  for(i = 0; i < NINODE; i++) {
    800036be:	0023d497          	auipc	s1,0x23d
    800036c2:	23248493          	addi	s1,s1,562 # 802408f0 <itable+0x28>
    800036c6:	0023f997          	auipc	s3,0x23f
    800036ca:	cba98993          	addi	s3,s3,-838 # 80242380 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036ce:	00005917          	auipc	s2,0x5
    800036d2:	f3290913          	addi	s2,s2,-206 # 80008600 <syscalls+0x178>
    800036d6:	85ca                	mv	a1,s2
    800036d8:	8526                	mv	a0,s1
    800036da:	00001097          	auipc	ra,0x1
    800036de:	e42080e7          	jalr	-446(ra) # 8000451c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036e2:	08848493          	addi	s1,s1,136
    800036e6:	ff3498e3          	bne	s1,s3,800036d6 <iinit+0x3e>
}
    800036ea:	70a2                	ld	ra,40(sp)
    800036ec:	7402                	ld	s0,32(sp)
    800036ee:	64e2                	ld	s1,24(sp)
    800036f0:	6942                	ld	s2,16(sp)
    800036f2:	69a2                	ld	s3,8(sp)
    800036f4:	6145                	addi	sp,sp,48
    800036f6:	8082                	ret

00000000800036f8 <ialloc>:
{
    800036f8:	715d                	addi	sp,sp,-80
    800036fa:	e486                	sd	ra,72(sp)
    800036fc:	e0a2                	sd	s0,64(sp)
    800036fe:	fc26                	sd	s1,56(sp)
    80003700:	f84a                	sd	s2,48(sp)
    80003702:	f44e                	sd	s3,40(sp)
    80003704:	f052                	sd	s4,32(sp)
    80003706:	ec56                	sd	s5,24(sp)
    80003708:	e85a                	sd	s6,16(sp)
    8000370a:	e45e                	sd	s7,8(sp)
    8000370c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000370e:	0023d717          	auipc	a4,0x23d
    80003712:	1a672703          	lw	a4,422(a4) # 802408b4 <sb+0xc>
    80003716:	4785                	li	a5,1
    80003718:	04e7fa63          	bgeu	a5,a4,8000376c <ialloc+0x74>
    8000371c:	8aaa                	mv	s5,a0
    8000371e:	8bae                	mv	s7,a1
    80003720:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003722:	0023da17          	auipc	s4,0x23d
    80003726:	186a0a13          	addi	s4,s4,390 # 802408a8 <sb>
    8000372a:	00048b1b          	sext.w	s6,s1
    8000372e:	0044d593          	srli	a1,s1,0x4
    80003732:	018a2783          	lw	a5,24(s4)
    80003736:	9dbd                	addw	a1,a1,a5
    80003738:	8556                	mv	a0,s5
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	944080e7          	jalr	-1724(ra) # 8000307e <bread>
    80003742:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003744:	05850993          	addi	s3,a0,88
    80003748:	00f4f793          	andi	a5,s1,15
    8000374c:	079a                	slli	a5,a5,0x6
    8000374e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003750:	00099783          	lh	a5,0(s3)
    80003754:	c3a1                	beqz	a5,80003794 <ialloc+0x9c>
    brelse(bp);
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	a58080e7          	jalr	-1448(ra) # 800031ae <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000375e:	0485                	addi	s1,s1,1
    80003760:	00ca2703          	lw	a4,12(s4)
    80003764:	0004879b          	sext.w	a5,s1
    80003768:	fce7e1e3          	bltu	a5,a4,8000372a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000376c:	00005517          	auipc	a0,0x5
    80003770:	e9c50513          	addi	a0,a0,-356 # 80008608 <syscalls+0x180>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	e16080e7          	jalr	-490(ra) # 8000058a <printf>
  return 0;
    8000377c:	4501                	li	a0,0
}
    8000377e:	60a6                	ld	ra,72(sp)
    80003780:	6406                	ld	s0,64(sp)
    80003782:	74e2                	ld	s1,56(sp)
    80003784:	7942                	ld	s2,48(sp)
    80003786:	79a2                	ld	s3,40(sp)
    80003788:	7a02                	ld	s4,32(sp)
    8000378a:	6ae2                	ld	s5,24(sp)
    8000378c:	6b42                	ld	s6,16(sp)
    8000378e:	6ba2                	ld	s7,8(sp)
    80003790:	6161                	addi	sp,sp,80
    80003792:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003794:	04000613          	li	a2,64
    80003798:	4581                	li	a1,0
    8000379a:	854e                	mv	a0,s3
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	66c080e7          	jalr	1644(ra) # 80000e08 <memset>
      dip->type = type;
    800037a4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037a8:	854a                	mv	a0,s2
    800037aa:	00001097          	auipc	ra,0x1
    800037ae:	c8e080e7          	jalr	-882(ra) # 80004438 <log_write>
      brelse(bp);
    800037b2:	854a                	mv	a0,s2
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	9fa080e7          	jalr	-1542(ra) # 800031ae <brelse>
      return iget(dev, inum);
    800037bc:	85da                	mv	a1,s6
    800037be:	8556                	mv	a0,s5
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	d9c080e7          	jalr	-612(ra) # 8000355c <iget>
    800037c8:	bf5d                	j	8000377e <ialloc+0x86>

00000000800037ca <iupdate>:
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	e04a                	sd	s2,0(sp)
    800037d4:	1000                	addi	s0,sp,32
    800037d6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d8:	415c                	lw	a5,4(a0)
    800037da:	0047d79b          	srliw	a5,a5,0x4
    800037de:	0023d597          	auipc	a1,0x23d
    800037e2:	0e25a583          	lw	a1,226(a1) # 802408c0 <sb+0x18>
    800037e6:	9dbd                	addw	a1,a1,a5
    800037e8:	4108                	lw	a0,0(a0)
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	894080e7          	jalr	-1900(ra) # 8000307e <bread>
    800037f2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f4:	05850793          	addi	a5,a0,88
    800037f8:	40d8                	lw	a4,4(s1)
    800037fa:	8b3d                	andi	a4,a4,15
    800037fc:	071a                	slli	a4,a4,0x6
    800037fe:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003800:	04449703          	lh	a4,68(s1)
    80003804:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003808:	04649703          	lh	a4,70(s1)
    8000380c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003810:	04849703          	lh	a4,72(s1)
    80003814:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003818:	04a49703          	lh	a4,74(s1)
    8000381c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003820:	44f8                	lw	a4,76(s1)
    80003822:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003824:	03400613          	li	a2,52
    80003828:	05048593          	addi	a1,s1,80
    8000382c:	00c78513          	addi	a0,a5,12
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	634080e7          	jalr	1588(ra) # 80000e64 <memmove>
  log_write(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	bfe080e7          	jalr	-1026(ra) # 80004438 <log_write>
  brelse(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00000097          	auipc	ra,0x0
    80003848:	96a080e7          	jalr	-1686(ra) # 800031ae <brelse>
}
    8000384c:	60e2                	ld	ra,24(sp)
    8000384e:	6442                	ld	s0,16(sp)
    80003850:	64a2                	ld	s1,8(sp)
    80003852:	6902                	ld	s2,0(sp)
    80003854:	6105                	addi	sp,sp,32
    80003856:	8082                	ret

0000000080003858 <idup>:
{
    80003858:	1101                	addi	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	e426                	sd	s1,8(sp)
    80003860:	1000                	addi	s0,sp,32
    80003862:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003864:	0023d517          	auipc	a0,0x23d
    80003868:	06450513          	addi	a0,a0,100 # 802408c8 <itable>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	4a0080e7          	jalr	1184(ra) # 80000d0c <acquire>
  ip->ref++;
    80003874:	449c                	lw	a5,8(s1)
    80003876:	2785                	addiw	a5,a5,1
    80003878:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000387a:	0023d517          	auipc	a0,0x23d
    8000387e:	04e50513          	addi	a0,a0,78 # 802408c8 <itable>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	53e080e7          	jalr	1342(ra) # 80000dc0 <release>
}
    8000388a:	8526                	mv	a0,s1
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret

0000000080003896 <ilock>:
{
    80003896:	1101                	addi	sp,sp,-32
    80003898:	ec06                	sd	ra,24(sp)
    8000389a:	e822                	sd	s0,16(sp)
    8000389c:	e426                	sd	s1,8(sp)
    8000389e:	e04a                	sd	s2,0(sp)
    800038a0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038a2:	c115                	beqz	a0,800038c6 <ilock+0x30>
    800038a4:	84aa                	mv	s1,a0
    800038a6:	451c                	lw	a5,8(a0)
    800038a8:	00f05f63          	blez	a5,800038c6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038ac:	0541                	addi	a0,a0,16
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	ca8080e7          	jalr	-856(ra) # 80004556 <acquiresleep>
  if(ip->valid == 0){
    800038b6:	40bc                	lw	a5,64(s1)
    800038b8:	cf99                	beqz	a5,800038d6 <ilock+0x40>
}
    800038ba:	60e2                	ld	ra,24(sp)
    800038bc:	6442                	ld	s0,16(sp)
    800038be:	64a2                	ld	s1,8(sp)
    800038c0:	6902                	ld	s2,0(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret
    panic("ilock");
    800038c6:	00005517          	auipc	a0,0x5
    800038ca:	d5a50513          	addi	a0,a0,-678 # 80008620 <syscalls+0x198>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	c72080e7          	jalr	-910(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038d6:	40dc                	lw	a5,4(s1)
    800038d8:	0047d79b          	srliw	a5,a5,0x4
    800038dc:	0023d597          	auipc	a1,0x23d
    800038e0:	fe45a583          	lw	a1,-28(a1) # 802408c0 <sb+0x18>
    800038e4:	9dbd                	addw	a1,a1,a5
    800038e6:	4088                	lw	a0,0(s1)
    800038e8:	fffff097          	auipc	ra,0xfffff
    800038ec:	796080e7          	jalr	1942(ra) # 8000307e <bread>
    800038f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038f2:	05850593          	addi	a1,a0,88
    800038f6:	40dc                	lw	a5,4(s1)
    800038f8:	8bbd                	andi	a5,a5,15
    800038fa:	079a                	slli	a5,a5,0x6
    800038fc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038fe:	00059783          	lh	a5,0(a1)
    80003902:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003906:	00259783          	lh	a5,2(a1)
    8000390a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000390e:	00459783          	lh	a5,4(a1)
    80003912:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003916:	00659783          	lh	a5,6(a1)
    8000391a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000391e:	459c                	lw	a5,8(a1)
    80003920:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003922:	03400613          	li	a2,52
    80003926:	05b1                	addi	a1,a1,12
    80003928:	05048513          	addi	a0,s1,80
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	538080e7          	jalr	1336(ra) # 80000e64 <memmove>
    brelse(bp);
    80003934:	854a                	mv	a0,s2
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	878080e7          	jalr	-1928(ra) # 800031ae <brelse>
    ip->valid = 1;
    8000393e:	4785                	li	a5,1
    80003940:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003942:	04449783          	lh	a5,68(s1)
    80003946:	fbb5                	bnez	a5,800038ba <ilock+0x24>
      panic("ilock: no type");
    80003948:	00005517          	auipc	a0,0x5
    8000394c:	ce050513          	addi	a0,a0,-800 # 80008628 <syscalls+0x1a0>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	bf0080e7          	jalr	-1040(ra) # 80000540 <panic>

0000000080003958 <iunlock>:
{
    80003958:	1101                	addi	sp,sp,-32
    8000395a:	ec06                	sd	ra,24(sp)
    8000395c:	e822                	sd	s0,16(sp)
    8000395e:	e426                	sd	s1,8(sp)
    80003960:	e04a                	sd	s2,0(sp)
    80003962:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003964:	c905                	beqz	a0,80003994 <iunlock+0x3c>
    80003966:	84aa                	mv	s1,a0
    80003968:	01050913          	addi	s2,a0,16
    8000396c:	854a                	mv	a0,s2
    8000396e:	00001097          	auipc	ra,0x1
    80003972:	c82080e7          	jalr	-894(ra) # 800045f0 <holdingsleep>
    80003976:	cd19                	beqz	a0,80003994 <iunlock+0x3c>
    80003978:	449c                	lw	a5,8(s1)
    8000397a:	00f05d63          	blez	a5,80003994 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	c2c080e7          	jalr	-980(ra) # 800045ac <releasesleep>
}
    80003988:	60e2                	ld	ra,24(sp)
    8000398a:	6442                	ld	s0,16(sp)
    8000398c:	64a2                	ld	s1,8(sp)
    8000398e:	6902                	ld	s2,0(sp)
    80003990:	6105                	addi	sp,sp,32
    80003992:	8082                	ret
    panic("iunlock");
    80003994:	00005517          	auipc	a0,0x5
    80003998:	ca450513          	addi	a0,a0,-860 # 80008638 <syscalls+0x1b0>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	ba4080e7          	jalr	-1116(ra) # 80000540 <panic>

00000000800039a4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039a4:	7179                	addi	sp,sp,-48
    800039a6:	f406                	sd	ra,40(sp)
    800039a8:	f022                	sd	s0,32(sp)
    800039aa:	ec26                	sd	s1,24(sp)
    800039ac:	e84a                	sd	s2,16(sp)
    800039ae:	e44e                	sd	s3,8(sp)
    800039b0:	e052                	sd	s4,0(sp)
    800039b2:	1800                	addi	s0,sp,48
    800039b4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039b6:	05050493          	addi	s1,a0,80
    800039ba:	08050913          	addi	s2,a0,128
    800039be:	a021                	j	800039c6 <itrunc+0x22>
    800039c0:	0491                	addi	s1,s1,4
    800039c2:	01248d63          	beq	s1,s2,800039dc <itrunc+0x38>
    if(ip->addrs[i]){
    800039c6:	408c                	lw	a1,0(s1)
    800039c8:	dde5                	beqz	a1,800039c0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ca:	0009a503          	lw	a0,0(s3)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	8f6080e7          	jalr	-1802(ra) # 800032c4 <bfree>
      ip->addrs[i] = 0;
    800039d6:	0004a023          	sw	zero,0(s1)
    800039da:	b7dd                	j	800039c0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039dc:	0809a583          	lw	a1,128(s3)
    800039e0:	e185                	bnez	a1,80003a00 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039e2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039e6:	854e                	mv	a0,s3
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	de2080e7          	jalr	-542(ra) # 800037ca <iupdate>
}
    800039f0:	70a2                	ld	ra,40(sp)
    800039f2:	7402                	ld	s0,32(sp)
    800039f4:	64e2                	ld	s1,24(sp)
    800039f6:	6942                	ld	s2,16(sp)
    800039f8:	69a2                	ld	s3,8(sp)
    800039fa:	6a02                	ld	s4,0(sp)
    800039fc:	6145                	addi	sp,sp,48
    800039fe:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a00:	0009a503          	lw	a0,0(s3)
    80003a04:	fffff097          	auipc	ra,0xfffff
    80003a08:	67a080e7          	jalr	1658(ra) # 8000307e <bread>
    80003a0c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a0e:	05850493          	addi	s1,a0,88
    80003a12:	45850913          	addi	s2,a0,1112
    80003a16:	a021                	j	80003a1e <itrunc+0x7a>
    80003a18:	0491                	addi	s1,s1,4
    80003a1a:	01248b63          	beq	s1,s2,80003a30 <itrunc+0x8c>
      if(a[j])
    80003a1e:	408c                	lw	a1,0(s1)
    80003a20:	dde5                	beqz	a1,80003a18 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a22:	0009a503          	lw	a0,0(s3)
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	89e080e7          	jalr	-1890(ra) # 800032c4 <bfree>
    80003a2e:	b7ed                	j	80003a18 <itrunc+0x74>
    brelse(bp);
    80003a30:	8552                	mv	a0,s4
    80003a32:	fffff097          	auipc	ra,0xfffff
    80003a36:	77c080e7          	jalr	1916(ra) # 800031ae <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a3a:	0809a583          	lw	a1,128(s3)
    80003a3e:	0009a503          	lw	a0,0(s3)
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	882080e7          	jalr	-1918(ra) # 800032c4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a4a:	0809a023          	sw	zero,128(s3)
    80003a4e:	bf51                	j	800039e2 <itrunc+0x3e>

0000000080003a50 <iput>:
{
    80003a50:	1101                	addi	sp,sp,-32
    80003a52:	ec06                	sd	ra,24(sp)
    80003a54:	e822                	sd	s0,16(sp)
    80003a56:	e426                	sd	s1,8(sp)
    80003a58:	e04a                	sd	s2,0(sp)
    80003a5a:	1000                	addi	s0,sp,32
    80003a5c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a5e:	0023d517          	auipc	a0,0x23d
    80003a62:	e6a50513          	addi	a0,a0,-406 # 802408c8 <itable>
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	2a6080e7          	jalr	678(ra) # 80000d0c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a6e:	4498                	lw	a4,8(s1)
    80003a70:	4785                	li	a5,1
    80003a72:	02f70363          	beq	a4,a5,80003a98 <iput+0x48>
  ip->ref--;
    80003a76:	449c                	lw	a5,8(s1)
    80003a78:	37fd                	addiw	a5,a5,-1
    80003a7a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a7c:	0023d517          	auipc	a0,0x23d
    80003a80:	e4c50513          	addi	a0,a0,-436 # 802408c8 <itable>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	33c080e7          	jalr	828(ra) # 80000dc0 <release>
}
    80003a8c:	60e2                	ld	ra,24(sp)
    80003a8e:	6442                	ld	s0,16(sp)
    80003a90:	64a2                	ld	s1,8(sp)
    80003a92:	6902                	ld	s2,0(sp)
    80003a94:	6105                	addi	sp,sp,32
    80003a96:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a98:	40bc                	lw	a5,64(s1)
    80003a9a:	dff1                	beqz	a5,80003a76 <iput+0x26>
    80003a9c:	04a49783          	lh	a5,74(s1)
    80003aa0:	fbf9                	bnez	a5,80003a76 <iput+0x26>
    acquiresleep(&ip->lock);
    80003aa2:	01048913          	addi	s2,s1,16
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00001097          	auipc	ra,0x1
    80003aac:	aae080e7          	jalr	-1362(ra) # 80004556 <acquiresleep>
    release(&itable.lock);
    80003ab0:	0023d517          	auipc	a0,0x23d
    80003ab4:	e1850513          	addi	a0,a0,-488 # 802408c8 <itable>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	308080e7          	jalr	776(ra) # 80000dc0 <release>
    itrunc(ip);
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	ee2080e7          	jalr	-286(ra) # 800039a4 <itrunc>
    ip->type = 0;
    80003aca:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ace:	8526                	mv	a0,s1
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	cfa080e7          	jalr	-774(ra) # 800037ca <iupdate>
    ip->valid = 0;
    80003ad8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003adc:	854a                	mv	a0,s2
    80003ade:	00001097          	auipc	ra,0x1
    80003ae2:	ace080e7          	jalr	-1330(ra) # 800045ac <releasesleep>
    acquire(&itable.lock);
    80003ae6:	0023d517          	auipc	a0,0x23d
    80003aea:	de250513          	addi	a0,a0,-542 # 802408c8 <itable>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	21e080e7          	jalr	542(ra) # 80000d0c <acquire>
    80003af6:	b741                	j	80003a76 <iput+0x26>

0000000080003af8 <iunlockput>:
{
    80003af8:	1101                	addi	sp,sp,-32
    80003afa:	ec06                	sd	ra,24(sp)
    80003afc:	e822                	sd	s0,16(sp)
    80003afe:	e426                	sd	s1,8(sp)
    80003b00:	1000                	addi	s0,sp,32
    80003b02:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	e54080e7          	jalr	-428(ra) # 80003958 <iunlock>
  iput(ip);
    80003b0c:	8526                	mv	a0,s1
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	f42080e7          	jalr	-190(ra) # 80003a50 <iput>
}
    80003b16:	60e2                	ld	ra,24(sp)
    80003b18:	6442                	ld	s0,16(sp)
    80003b1a:	64a2                	ld	s1,8(sp)
    80003b1c:	6105                	addi	sp,sp,32
    80003b1e:	8082                	ret

0000000080003b20 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b20:	1141                	addi	sp,sp,-16
    80003b22:	e422                	sd	s0,8(sp)
    80003b24:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b26:	411c                	lw	a5,0(a0)
    80003b28:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b2a:	415c                	lw	a5,4(a0)
    80003b2c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b2e:	04451783          	lh	a5,68(a0)
    80003b32:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b36:	04a51783          	lh	a5,74(a0)
    80003b3a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b3e:	04c56783          	lwu	a5,76(a0)
    80003b42:	e99c                	sd	a5,16(a1)
}
    80003b44:	6422                	ld	s0,8(sp)
    80003b46:	0141                	addi	sp,sp,16
    80003b48:	8082                	ret

0000000080003b4a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b4a:	457c                	lw	a5,76(a0)
    80003b4c:	0ed7e963          	bltu	a5,a3,80003c3e <readi+0xf4>
{
    80003b50:	7159                	addi	sp,sp,-112
    80003b52:	f486                	sd	ra,104(sp)
    80003b54:	f0a2                	sd	s0,96(sp)
    80003b56:	eca6                	sd	s1,88(sp)
    80003b58:	e8ca                	sd	s2,80(sp)
    80003b5a:	e4ce                	sd	s3,72(sp)
    80003b5c:	e0d2                	sd	s4,64(sp)
    80003b5e:	fc56                	sd	s5,56(sp)
    80003b60:	f85a                	sd	s6,48(sp)
    80003b62:	f45e                	sd	s7,40(sp)
    80003b64:	f062                	sd	s8,32(sp)
    80003b66:	ec66                	sd	s9,24(sp)
    80003b68:	e86a                	sd	s10,16(sp)
    80003b6a:	e46e                	sd	s11,8(sp)
    80003b6c:	1880                	addi	s0,sp,112
    80003b6e:	8b2a                	mv	s6,a0
    80003b70:	8bae                	mv	s7,a1
    80003b72:	8a32                	mv	s4,a2
    80003b74:	84b6                	mv	s1,a3
    80003b76:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b78:	9f35                	addw	a4,a4,a3
    return 0;
    80003b7a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b7c:	0ad76063          	bltu	a4,a3,80003c1c <readi+0xd2>
  if(off + n > ip->size)
    80003b80:	00e7f463          	bgeu	a5,a4,80003b88 <readi+0x3e>
    n = ip->size - off;
    80003b84:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b88:	0a0a8963          	beqz	s5,80003c3a <readi+0xf0>
    80003b8c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b92:	5c7d                	li	s8,-1
    80003b94:	a82d                	j	80003bce <readi+0x84>
    80003b96:	020d1d93          	slli	s11,s10,0x20
    80003b9a:	020ddd93          	srli	s11,s11,0x20
    80003b9e:	05890613          	addi	a2,s2,88
    80003ba2:	86ee                	mv	a3,s11
    80003ba4:	963a                	add	a2,a2,a4
    80003ba6:	85d2                	mv	a1,s4
    80003ba8:	855e                	mv	a0,s7
    80003baa:	fffff097          	auipc	ra,0xfffff
    80003bae:	a02080e7          	jalr	-1534(ra) # 800025ac <either_copyout>
    80003bb2:	05850d63          	beq	a0,s8,80003c0c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	5f6080e7          	jalr	1526(ra) # 800031ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc0:	013d09bb          	addw	s3,s10,s3
    80003bc4:	009d04bb          	addw	s1,s10,s1
    80003bc8:	9a6e                	add	s4,s4,s11
    80003bca:	0559f763          	bgeu	s3,s5,80003c18 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bce:	00a4d59b          	srliw	a1,s1,0xa
    80003bd2:	855a                	mv	a0,s6
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	89e080e7          	jalr	-1890(ra) # 80003472 <bmap>
    80003bdc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003be0:	cd85                	beqz	a1,80003c18 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003be2:	000b2503          	lw	a0,0(s6)
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	498080e7          	jalr	1176(ra) # 8000307e <bread>
    80003bee:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf0:	3ff4f713          	andi	a4,s1,1023
    80003bf4:	40ec87bb          	subw	a5,s9,a4
    80003bf8:	413a86bb          	subw	a3,s5,s3
    80003bfc:	8d3e                	mv	s10,a5
    80003bfe:	2781                	sext.w	a5,a5
    80003c00:	0006861b          	sext.w	a2,a3
    80003c04:	f8f679e3          	bgeu	a2,a5,80003b96 <readi+0x4c>
    80003c08:	8d36                	mv	s10,a3
    80003c0a:	b771                	j	80003b96 <readi+0x4c>
      brelse(bp);
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	5a0080e7          	jalr	1440(ra) # 800031ae <brelse>
      tot = -1;
    80003c16:	59fd                	li	s3,-1
  }
  return tot;
    80003c18:	0009851b          	sext.w	a0,s3
}
    80003c1c:	70a6                	ld	ra,104(sp)
    80003c1e:	7406                	ld	s0,96(sp)
    80003c20:	64e6                	ld	s1,88(sp)
    80003c22:	6946                	ld	s2,80(sp)
    80003c24:	69a6                	ld	s3,72(sp)
    80003c26:	6a06                	ld	s4,64(sp)
    80003c28:	7ae2                	ld	s5,56(sp)
    80003c2a:	7b42                	ld	s6,48(sp)
    80003c2c:	7ba2                	ld	s7,40(sp)
    80003c2e:	7c02                	ld	s8,32(sp)
    80003c30:	6ce2                	ld	s9,24(sp)
    80003c32:	6d42                	ld	s10,16(sp)
    80003c34:	6da2                	ld	s11,8(sp)
    80003c36:	6165                	addi	sp,sp,112
    80003c38:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c3a:	89d6                	mv	s3,s5
    80003c3c:	bff1                	j	80003c18 <readi+0xce>
    return 0;
    80003c3e:	4501                	li	a0,0
}
    80003c40:	8082                	ret

0000000080003c42 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c42:	457c                	lw	a5,76(a0)
    80003c44:	10d7e863          	bltu	a5,a3,80003d54 <writei+0x112>
{
    80003c48:	7159                	addi	sp,sp,-112
    80003c4a:	f486                	sd	ra,104(sp)
    80003c4c:	f0a2                	sd	s0,96(sp)
    80003c4e:	eca6                	sd	s1,88(sp)
    80003c50:	e8ca                	sd	s2,80(sp)
    80003c52:	e4ce                	sd	s3,72(sp)
    80003c54:	e0d2                	sd	s4,64(sp)
    80003c56:	fc56                	sd	s5,56(sp)
    80003c58:	f85a                	sd	s6,48(sp)
    80003c5a:	f45e                	sd	s7,40(sp)
    80003c5c:	f062                	sd	s8,32(sp)
    80003c5e:	ec66                	sd	s9,24(sp)
    80003c60:	e86a                	sd	s10,16(sp)
    80003c62:	e46e                	sd	s11,8(sp)
    80003c64:	1880                	addi	s0,sp,112
    80003c66:	8aaa                	mv	s5,a0
    80003c68:	8bae                	mv	s7,a1
    80003c6a:	8a32                	mv	s4,a2
    80003c6c:	8936                	mv	s2,a3
    80003c6e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c70:	00e687bb          	addw	a5,a3,a4
    80003c74:	0ed7e263          	bltu	a5,a3,80003d58 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c78:	00043737          	lui	a4,0x43
    80003c7c:	0ef76063          	bltu	a4,a5,80003d5c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c80:	0c0b0863          	beqz	s6,80003d50 <writei+0x10e>
    80003c84:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c86:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c8a:	5c7d                	li	s8,-1
    80003c8c:	a091                	j	80003cd0 <writei+0x8e>
    80003c8e:	020d1d93          	slli	s11,s10,0x20
    80003c92:	020ddd93          	srli	s11,s11,0x20
    80003c96:	05848513          	addi	a0,s1,88
    80003c9a:	86ee                	mv	a3,s11
    80003c9c:	8652                	mv	a2,s4
    80003c9e:	85de                	mv	a1,s7
    80003ca0:	953a                	add	a0,a0,a4
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	960080e7          	jalr	-1696(ra) # 80002602 <either_copyin>
    80003caa:	07850263          	beq	a0,s8,80003d0e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cae:	8526                	mv	a0,s1
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	788080e7          	jalr	1928(ra) # 80004438 <log_write>
    brelse(bp);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4f4080e7          	jalr	1268(ra) # 800031ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc2:	013d09bb          	addw	s3,s10,s3
    80003cc6:	012d093b          	addw	s2,s10,s2
    80003cca:	9a6e                	add	s4,s4,s11
    80003ccc:	0569f663          	bgeu	s3,s6,80003d18 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cd0:	00a9559b          	srliw	a1,s2,0xa
    80003cd4:	8556                	mv	a0,s5
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	79c080e7          	jalr	1948(ra) # 80003472 <bmap>
    80003cde:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ce2:	c99d                	beqz	a1,80003d18 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ce4:	000aa503          	lw	a0,0(s5)
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	396080e7          	jalr	918(ra) # 8000307e <bread>
    80003cf0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf2:	3ff97713          	andi	a4,s2,1023
    80003cf6:	40ec87bb          	subw	a5,s9,a4
    80003cfa:	413b06bb          	subw	a3,s6,s3
    80003cfe:	8d3e                	mv	s10,a5
    80003d00:	2781                	sext.w	a5,a5
    80003d02:	0006861b          	sext.w	a2,a3
    80003d06:	f8f674e3          	bgeu	a2,a5,80003c8e <writei+0x4c>
    80003d0a:	8d36                	mv	s10,a3
    80003d0c:	b749                	j	80003c8e <writei+0x4c>
      brelse(bp);
    80003d0e:	8526                	mv	a0,s1
    80003d10:	fffff097          	auipc	ra,0xfffff
    80003d14:	49e080e7          	jalr	1182(ra) # 800031ae <brelse>
  }

  if(off > ip->size)
    80003d18:	04caa783          	lw	a5,76(s5)
    80003d1c:	0127f463          	bgeu	a5,s2,80003d24 <writei+0xe2>
    ip->size = off;
    80003d20:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d24:	8556                	mv	a0,s5
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	aa4080e7          	jalr	-1372(ra) # 800037ca <iupdate>

  return tot;
    80003d2e:	0009851b          	sext.w	a0,s3
}
    80003d32:	70a6                	ld	ra,104(sp)
    80003d34:	7406                	ld	s0,96(sp)
    80003d36:	64e6                	ld	s1,88(sp)
    80003d38:	6946                	ld	s2,80(sp)
    80003d3a:	69a6                	ld	s3,72(sp)
    80003d3c:	6a06                	ld	s4,64(sp)
    80003d3e:	7ae2                	ld	s5,56(sp)
    80003d40:	7b42                	ld	s6,48(sp)
    80003d42:	7ba2                	ld	s7,40(sp)
    80003d44:	7c02                	ld	s8,32(sp)
    80003d46:	6ce2                	ld	s9,24(sp)
    80003d48:	6d42                	ld	s10,16(sp)
    80003d4a:	6da2                	ld	s11,8(sp)
    80003d4c:	6165                	addi	sp,sp,112
    80003d4e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d50:	89da                	mv	s3,s6
    80003d52:	bfc9                	j	80003d24 <writei+0xe2>
    return -1;
    80003d54:	557d                	li	a0,-1
}
    80003d56:	8082                	ret
    return -1;
    80003d58:	557d                	li	a0,-1
    80003d5a:	bfe1                	j	80003d32 <writei+0xf0>
    return -1;
    80003d5c:	557d                	li	a0,-1
    80003d5e:	bfd1                	j	80003d32 <writei+0xf0>

0000000080003d60 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d60:	1141                	addi	sp,sp,-16
    80003d62:	e406                	sd	ra,8(sp)
    80003d64:	e022                	sd	s0,0(sp)
    80003d66:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d68:	4639                	li	a2,14
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	16e080e7          	jalr	366(ra) # 80000ed8 <strncmp>
}
    80003d72:	60a2                	ld	ra,8(sp)
    80003d74:	6402                	ld	s0,0(sp)
    80003d76:	0141                	addi	sp,sp,16
    80003d78:	8082                	ret

0000000080003d7a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d7a:	7139                	addi	sp,sp,-64
    80003d7c:	fc06                	sd	ra,56(sp)
    80003d7e:	f822                	sd	s0,48(sp)
    80003d80:	f426                	sd	s1,40(sp)
    80003d82:	f04a                	sd	s2,32(sp)
    80003d84:	ec4e                	sd	s3,24(sp)
    80003d86:	e852                	sd	s4,16(sp)
    80003d88:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d8a:	04451703          	lh	a4,68(a0)
    80003d8e:	4785                	li	a5,1
    80003d90:	00f71a63          	bne	a4,a5,80003da4 <dirlookup+0x2a>
    80003d94:	892a                	mv	s2,a0
    80003d96:	89ae                	mv	s3,a1
    80003d98:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9a:	457c                	lw	a5,76(a0)
    80003d9c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d9e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da0:	e79d                	bnez	a5,80003dce <dirlookup+0x54>
    80003da2:	a8a5                	j	80003e1a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003da4:	00005517          	auipc	a0,0x5
    80003da8:	89c50513          	addi	a0,a0,-1892 # 80008640 <syscalls+0x1b8>
    80003dac:	ffffc097          	auipc	ra,0xffffc
    80003db0:	794080e7          	jalr	1940(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003db4:	00005517          	auipc	a0,0x5
    80003db8:	8a450513          	addi	a0,a0,-1884 # 80008658 <syscalls+0x1d0>
    80003dbc:	ffffc097          	auipc	ra,0xffffc
    80003dc0:	784080e7          	jalr	1924(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc4:	24c1                	addiw	s1,s1,16
    80003dc6:	04c92783          	lw	a5,76(s2)
    80003dca:	04f4f763          	bgeu	s1,a5,80003e18 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dce:	4741                	li	a4,16
    80003dd0:	86a6                	mv	a3,s1
    80003dd2:	fc040613          	addi	a2,s0,-64
    80003dd6:	4581                	li	a1,0
    80003dd8:	854a                	mv	a0,s2
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	d70080e7          	jalr	-656(ra) # 80003b4a <readi>
    80003de2:	47c1                	li	a5,16
    80003de4:	fcf518e3          	bne	a0,a5,80003db4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003de8:	fc045783          	lhu	a5,-64(s0)
    80003dec:	dfe1                	beqz	a5,80003dc4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dee:	fc240593          	addi	a1,s0,-62
    80003df2:	854e                	mv	a0,s3
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	f6c080e7          	jalr	-148(ra) # 80003d60 <namecmp>
    80003dfc:	f561                	bnez	a0,80003dc4 <dirlookup+0x4a>
      if(poff)
    80003dfe:	000a0463          	beqz	s4,80003e06 <dirlookup+0x8c>
        *poff = off;
    80003e02:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e06:	fc045583          	lhu	a1,-64(s0)
    80003e0a:	00092503          	lw	a0,0(s2)
    80003e0e:	fffff097          	auipc	ra,0xfffff
    80003e12:	74e080e7          	jalr	1870(ra) # 8000355c <iget>
    80003e16:	a011                	j	80003e1a <dirlookup+0xa0>
  return 0;
    80003e18:	4501                	li	a0,0
}
    80003e1a:	70e2                	ld	ra,56(sp)
    80003e1c:	7442                	ld	s0,48(sp)
    80003e1e:	74a2                	ld	s1,40(sp)
    80003e20:	7902                	ld	s2,32(sp)
    80003e22:	69e2                	ld	s3,24(sp)
    80003e24:	6a42                	ld	s4,16(sp)
    80003e26:	6121                	addi	sp,sp,64
    80003e28:	8082                	ret

0000000080003e2a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e2a:	711d                	addi	sp,sp,-96
    80003e2c:	ec86                	sd	ra,88(sp)
    80003e2e:	e8a2                	sd	s0,80(sp)
    80003e30:	e4a6                	sd	s1,72(sp)
    80003e32:	e0ca                	sd	s2,64(sp)
    80003e34:	fc4e                	sd	s3,56(sp)
    80003e36:	f852                	sd	s4,48(sp)
    80003e38:	f456                	sd	s5,40(sp)
    80003e3a:	f05a                	sd	s6,32(sp)
    80003e3c:	ec5e                	sd	s7,24(sp)
    80003e3e:	e862                	sd	s8,16(sp)
    80003e40:	e466                	sd	s9,8(sp)
    80003e42:	e06a                	sd	s10,0(sp)
    80003e44:	1080                	addi	s0,sp,96
    80003e46:	84aa                	mv	s1,a0
    80003e48:	8b2e                	mv	s6,a1
    80003e4a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e4c:	00054703          	lbu	a4,0(a0)
    80003e50:	02f00793          	li	a5,47
    80003e54:	02f70363          	beq	a4,a5,80003e7a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e58:	ffffe097          	auipc	ra,0xffffe
    80003e5c:	ca4080e7          	jalr	-860(ra) # 80001afc <myproc>
    80003e60:	15053503          	ld	a0,336(a0)
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	9f4080e7          	jalr	-1548(ra) # 80003858 <idup>
    80003e6c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e6e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e72:	4cb5                	li	s9,13
  len = path - s;
    80003e74:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e76:	4c05                	li	s8,1
    80003e78:	a87d                	j	80003f36 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003e7a:	4585                	li	a1,1
    80003e7c:	4505                	li	a0,1
    80003e7e:	fffff097          	auipc	ra,0xfffff
    80003e82:	6de080e7          	jalr	1758(ra) # 8000355c <iget>
    80003e86:	8a2a                	mv	s4,a0
    80003e88:	b7dd                	j	80003e6e <namex+0x44>
      iunlockput(ip);
    80003e8a:	8552                	mv	a0,s4
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	c6c080e7          	jalr	-916(ra) # 80003af8 <iunlockput>
      return 0;
    80003e94:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e96:	8552                	mv	a0,s4
    80003e98:	60e6                	ld	ra,88(sp)
    80003e9a:	6446                	ld	s0,80(sp)
    80003e9c:	64a6                	ld	s1,72(sp)
    80003e9e:	6906                	ld	s2,64(sp)
    80003ea0:	79e2                	ld	s3,56(sp)
    80003ea2:	7a42                	ld	s4,48(sp)
    80003ea4:	7aa2                	ld	s5,40(sp)
    80003ea6:	7b02                	ld	s6,32(sp)
    80003ea8:	6be2                	ld	s7,24(sp)
    80003eaa:	6c42                	ld	s8,16(sp)
    80003eac:	6ca2                	ld	s9,8(sp)
    80003eae:	6d02                	ld	s10,0(sp)
    80003eb0:	6125                	addi	sp,sp,96
    80003eb2:	8082                	ret
      iunlock(ip);
    80003eb4:	8552                	mv	a0,s4
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	aa2080e7          	jalr	-1374(ra) # 80003958 <iunlock>
      return ip;
    80003ebe:	bfe1                	j	80003e96 <namex+0x6c>
      iunlockput(ip);
    80003ec0:	8552                	mv	a0,s4
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	c36080e7          	jalr	-970(ra) # 80003af8 <iunlockput>
      return 0;
    80003eca:	8a4e                	mv	s4,s3
    80003ecc:	b7e9                	j	80003e96 <namex+0x6c>
  len = path - s;
    80003ece:	40998633          	sub	a2,s3,s1
    80003ed2:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003ed6:	09acd863          	bge	s9,s10,80003f66 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003eda:	4639                	li	a2,14
    80003edc:	85a6                	mv	a1,s1
    80003ede:	8556                	mv	a0,s5
    80003ee0:	ffffd097          	auipc	ra,0xffffd
    80003ee4:	f84080e7          	jalr	-124(ra) # 80000e64 <memmove>
    80003ee8:	84ce                	mv	s1,s3
  while(*path == '/')
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	01279763          	bne	a5,s2,80003efc <namex+0xd2>
    path++;
    80003ef2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef4:	0004c783          	lbu	a5,0(s1)
    80003ef8:	ff278de3          	beq	a5,s2,80003ef2 <namex+0xc8>
    ilock(ip);
    80003efc:	8552                	mv	a0,s4
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	998080e7          	jalr	-1640(ra) # 80003896 <ilock>
    if(ip->type != T_DIR){
    80003f06:	044a1783          	lh	a5,68(s4)
    80003f0a:	f98790e3          	bne	a5,s8,80003e8a <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003f0e:	000b0563          	beqz	s6,80003f18 <namex+0xee>
    80003f12:	0004c783          	lbu	a5,0(s1)
    80003f16:	dfd9                	beqz	a5,80003eb4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f18:	865e                	mv	a2,s7
    80003f1a:	85d6                	mv	a1,s5
    80003f1c:	8552                	mv	a0,s4
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	e5c080e7          	jalr	-420(ra) # 80003d7a <dirlookup>
    80003f26:	89aa                	mv	s3,a0
    80003f28:	dd41                	beqz	a0,80003ec0 <namex+0x96>
    iunlockput(ip);
    80003f2a:	8552                	mv	a0,s4
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	bcc080e7          	jalr	-1076(ra) # 80003af8 <iunlockput>
    ip = next;
    80003f34:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	01279763          	bne	a5,s2,80003f48 <namex+0x11e>
    path++;
    80003f3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	ff278de3          	beq	a5,s2,80003f3e <namex+0x114>
  if(*path == 0)
    80003f48:	cb9d                	beqz	a5,80003f7e <namex+0x154>
  while(*path != '/' && *path != 0)
    80003f4a:	0004c783          	lbu	a5,0(s1)
    80003f4e:	89a6                	mv	s3,s1
  len = path - s;
    80003f50:	8d5e                	mv	s10,s7
    80003f52:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f54:	01278963          	beq	a5,s2,80003f66 <namex+0x13c>
    80003f58:	dbbd                	beqz	a5,80003ece <namex+0xa4>
    path++;
    80003f5a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f5c:	0009c783          	lbu	a5,0(s3)
    80003f60:	ff279ce3          	bne	a5,s2,80003f58 <namex+0x12e>
    80003f64:	b7ad                	j	80003ece <namex+0xa4>
    memmove(name, s, len);
    80003f66:	2601                	sext.w	a2,a2
    80003f68:	85a6                	mv	a1,s1
    80003f6a:	8556                	mv	a0,s5
    80003f6c:	ffffd097          	auipc	ra,0xffffd
    80003f70:	ef8080e7          	jalr	-264(ra) # 80000e64 <memmove>
    name[len] = 0;
    80003f74:	9d56                	add	s10,s10,s5
    80003f76:	000d0023          	sb	zero,0(s10)
    80003f7a:	84ce                	mv	s1,s3
    80003f7c:	b7bd                	j	80003eea <namex+0xc0>
  if(nameiparent){
    80003f7e:	f00b0ce3          	beqz	s6,80003e96 <namex+0x6c>
    iput(ip);
    80003f82:	8552                	mv	a0,s4
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	acc080e7          	jalr	-1332(ra) # 80003a50 <iput>
    return 0;
    80003f8c:	4a01                	li	s4,0
    80003f8e:	b721                	j	80003e96 <namex+0x6c>

0000000080003f90 <dirlink>:
{
    80003f90:	7139                	addi	sp,sp,-64
    80003f92:	fc06                	sd	ra,56(sp)
    80003f94:	f822                	sd	s0,48(sp)
    80003f96:	f426                	sd	s1,40(sp)
    80003f98:	f04a                	sd	s2,32(sp)
    80003f9a:	ec4e                	sd	s3,24(sp)
    80003f9c:	e852                	sd	s4,16(sp)
    80003f9e:	0080                	addi	s0,sp,64
    80003fa0:	892a                	mv	s2,a0
    80003fa2:	8a2e                	mv	s4,a1
    80003fa4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fa6:	4601                	li	a2,0
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	dd2080e7          	jalr	-558(ra) # 80003d7a <dirlookup>
    80003fb0:	e93d                	bnez	a0,80004026 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb2:	04c92483          	lw	s1,76(s2)
    80003fb6:	c49d                	beqz	s1,80003fe4 <dirlink+0x54>
    80003fb8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fba:	4741                	li	a4,16
    80003fbc:	86a6                	mv	a3,s1
    80003fbe:	fc040613          	addi	a2,s0,-64
    80003fc2:	4581                	li	a1,0
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	b84080e7          	jalr	-1148(ra) # 80003b4a <readi>
    80003fce:	47c1                	li	a5,16
    80003fd0:	06f51163          	bne	a0,a5,80004032 <dirlink+0xa2>
    if(de.inum == 0)
    80003fd4:	fc045783          	lhu	a5,-64(s0)
    80003fd8:	c791                	beqz	a5,80003fe4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fda:	24c1                	addiw	s1,s1,16
    80003fdc:	04c92783          	lw	a5,76(s2)
    80003fe0:	fcf4ede3          	bltu	s1,a5,80003fba <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fe4:	4639                	li	a2,14
    80003fe6:	85d2                	mv	a1,s4
    80003fe8:	fc240513          	addi	a0,s0,-62
    80003fec:	ffffd097          	auipc	ra,0xffffd
    80003ff0:	f28080e7          	jalr	-216(ra) # 80000f14 <strncpy>
  de.inum = inum;
    80003ff4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff8:	4741                	li	a4,16
    80003ffa:	86a6                	mv	a3,s1
    80003ffc:	fc040613          	addi	a2,s0,-64
    80004000:	4581                	li	a1,0
    80004002:	854a                	mv	a0,s2
    80004004:	00000097          	auipc	ra,0x0
    80004008:	c3e080e7          	jalr	-962(ra) # 80003c42 <writei>
    8000400c:	1541                	addi	a0,a0,-16
    8000400e:	00a03533          	snez	a0,a0
    80004012:	40a00533          	neg	a0,a0
}
    80004016:	70e2                	ld	ra,56(sp)
    80004018:	7442                	ld	s0,48(sp)
    8000401a:	74a2                	ld	s1,40(sp)
    8000401c:	7902                	ld	s2,32(sp)
    8000401e:	69e2                	ld	s3,24(sp)
    80004020:	6a42                	ld	s4,16(sp)
    80004022:	6121                	addi	sp,sp,64
    80004024:	8082                	ret
    iput(ip);
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	a2a080e7          	jalr	-1494(ra) # 80003a50 <iput>
    return -1;
    8000402e:	557d                	li	a0,-1
    80004030:	b7dd                	j	80004016 <dirlink+0x86>
      panic("dirlink read");
    80004032:	00004517          	auipc	a0,0x4
    80004036:	63650513          	addi	a0,a0,1590 # 80008668 <syscalls+0x1e0>
    8000403a:	ffffc097          	auipc	ra,0xffffc
    8000403e:	506080e7          	jalr	1286(ra) # 80000540 <panic>

0000000080004042 <namei>:

struct inode*
namei(char *path)
{
    80004042:	1101                	addi	sp,sp,-32
    80004044:	ec06                	sd	ra,24(sp)
    80004046:	e822                	sd	s0,16(sp)
    80004048:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000404a:	fe040613          	addi	a2,s0,-32
    8000404e:	4581                	li	a1,0
    80004050:	00000097          	auipc	ra,0x0
    80004054:	dda080e7          	jalr	-550(ra) # 80003e2a <namex>
}
    80004058:	60e2                	ld	ra,24(sp)
    8000405a:	6442                	ld	s0,16(sp)
    8000405c:	6105                	addi	sp,sp,32
    8000405e:	8082                	ret

0000000080004060 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004060:	1141                	addi	sp,sp,-16
    80004062:	e406                	sd	ra,8(sp)
    80004064:	e022                	sd	s0,0(sp)
    80004066:	0800                	addi	s0,sp,16
    80004068:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000406a:	4585                	li	a1,1
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	dbe080e7          	jalr	-578(ra) # 80003e2a <namex>
}
    80004074:	60a2                	ld	ra,8(sp)
    80004076:	6402                	ld	s0,0(sp)
    80004078:	0141                	addi	sp,sp,16
    8000407a:	8082                	ret

000000008000407c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000407c:	1101                	addi	sp,sp,-32
    8000407e:	ec06                	sd	ra,24(sp)
    80004080:	e822                	sd	s0,16(sp)
    80004082:	e426                	sd	s1,8(sp)
    80004084:	e04a                	sd	s2,0(sp)
    80004086:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004088:	0023e917          	auipc	s2,0x23e
    8000408c:	2e890913          	addi	s2,s2,744 # 80242370 <log>
    80004090:	01892583          	lw	a1,24(s2)
    80004094:	02892503          	lw	a0,40(s2)
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	fe6080e7          	jalr	-26(ra) # 8000307e <bread>
    800040a0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040a2:	02c92683          	lw	a3,44(s2)
    800040a6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040a8:	02d05863          	blez	a3,800040d8 <write_head+0x5c>
    800040ac:	0023e797          	auipc	a5,0x23e
    800040b0:	2f478793          	addi	a5,a5,756 # 802423a0 <log+0x30>
    800040b4:	05c50713          	addi	a4,a0,92
    800040b8:	36fd                	addiw	a3,a3,-1
    800040ba:	02069613          	slli	a2,a3,0x20
    800040be:	01e65693          	srli	a3,a2,0x1e
    800040c2:	0023e617          	auipc	a2,0x23e
    800040c6:	2e260613          	addi	a2,a2,738 # 802423a4 <log+0x34>
    800040ca:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040cc:	4390                	lw	a2,0(a5)
    800040ce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d0:	0791                	addi	a5,a5,4
    800040d2:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800040d4:	fed79ce3          	bne	a5,a3,800040cc <write_head+0x50>
  }
  bwrite(buf);
    800040d8:	8526                	mv	a0,s1
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	096080e7          	jalr	150(ra) # 80003170 <bwrite>
  brelse(buf);
    800040e2:	8526                	mv	a0,s1
    800040e4:	fffff097          	auipc	ra,0xfffff
    800040e8:	0ca080e7          	jalr	202(ra) # 800031ae <brelse>
}
    800040ec:	60e2                	ld	ra,24(sp)
    800040ee:	6442                	ld	s0,16(sp)
    800040f0:	64a2                	ld	s1,8(sp)
    800040f2:	6902                	ld	s2,0(sp)
    800040f4:	6105                	addi	sp,sp,32
    800040f6:	8082                	ret

00000000800040f8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f8:	0023e797          	auipc	a5,0x23e
    800040fc:	2a47a783          	lw	a5,676(a5) # 8024239c <log+0x2c>
    80004100:	0af05d63          	blez	a5,800041ba <install_trans+0xc2>
{
    80004104:	7139                	addi	sp,sp,-64
    80004106:	fc06                	sd	ra,56(sp)
    80004108:	f822                	sd	s0,48(sp)
    8000410a:	f426                	sd	s1,40(sp)
    8000410c:	f04a                	sd	s2,32(sp)
    8000410e:	ec4e                	sd	s3,24(sp)
    80004110:	e852                	sd	s4,16(sp)
    80004112:	e456                	sd	s5,8(sp)
    80004114:	e05a                	sd	s6,0(sp)
    80004116:	0080                	addi	s0,sp,64
    80004118:	8b2a                	mv	s6,a0
    8000411a:	0023ea97          	auipc	s5,0x23e
    8000411e:	286a8a93          	addi	s5,s5,646 # 802423a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004122:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004124:	0023e997          	auipc	s3,0x23e
    80004128:	24c98993          	addi	s3,s3,588 # 80242370 <log>
    8000412c:	a00d                	j	8000414e <install_trans+0x56>
    brelse(lbuf);
    8000412e:	854a                	mv	a0,s2
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	07e080e7          	jalr	126(ra) # 800031ae <brelse>
    brelse(dbuf);
    80004138:	8526                	mv	a0,s1
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	074080e7          	jalr	116(ra) # 800031ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004142:	2a05                	addiw	s4,s4,1
    80004144:	0a91                	addi	s5,s5,4
    80004146:	02c9a783          	lw	a5,44(s3)
    8000414a:	04fa5e63          	bge	s4,a5,800041a6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000414e:	0189a583          	lw	a1,24(s3)
    80004152:	014585bb          	addw	a1,a1,s4
    80004156:	2585                	addiw	a1,a1,1
    80004158:	0289a503          	lw	a0,40(s3)
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	f22080e7          	jalr	-222(ra) # 8000307e <bread>
    80004164:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004166:	000aa583          	lw	a1,0(s5)
    8000416a:	0289a503          	lw	a0,40(s3)
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	f10080e7          	jalr	-240(ra) # 8000307e <bread>
    80004176:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004178:	40000613          	li	a2,1024
    8000417c:	05890593          	addi	a1,s2,88
    80004180:	05850513          	addi	a0,a0,88
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	ce0080e7          	jalr	-800(ra) # 80000e64 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	fe2080e7          	jalr	-30(ra) # 80003170 <bwrite>
    if(recovering == 0)
    80004196:	f80b1ce3          	bnez	s6,8000412e <install_trans+0x36>
      bunpin(dbuf);
    8000419a:	8526                	mv	a0,s1
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	0ec080e7          	jalr	236(ra) # 80003288 <bunpin>
    800041a4:	b769                	j	8000412e <install_trans+0x36>
}
    800041a6:	70e2                	ld	ra,56(sp)
    800041a8:	7442                	ld	s0,48(sp)
    800041aa:	74a2                	ld	s1,40(sp)
    800041ac:	7902                	ld	s2,32(sp)
    800041ae:	69e2                	ld	s3,24(sp)
    800041b0:	6a42                	ld	s4,16(sp)
    800041b2:	6aa2                	ld	s5,8(sp)
    800041b4:	6b02                	ld	s6,0(sp)
    800041b6:	6121                	addi	sp,sp,64
    800041b8:	8082                	ret
    800041ba:	8082                	ret

00000000800041bc <initlog>:
{
    800041bc:	7179                	addi	sp,sp,-48
    800041be:	f406                	sd	ra,40(sp)
    800041c0:	f022                	sd	s0,32(sp)
    800041c2:	ec26                	sd	s1,24(sp)
    800041c4:	e84a                	sd	s2,16(sp)
    800041c6:	e44e                	sd	s3,8(sp)
    800041c8:	1800                	addi	s0,sp,48
    800041ca:	892a                	mv	s2,a0
    800041cc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041ce:	0023e497          	auipc	s1,0x23e
    800041d2:	1a248493          	addi	s1,s1,418 # 80242370 <log>
    800041d6:	00004597          	auipc	a1,0x4
    800041da:	4a258593          	addi	a1,a1,1186 # 80008678 <syscalls+0x1f0>
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	a9c080e7          	jalr	-1380(ra) # 80000c7c <initlock>
  log.start = sb->logstart;
    800041e8:	0149a583          	lw	a1,20(s3)
    800041ec:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041ee:	0109a783          	lw	a5,16(s3)
    800041f2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041f4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041f8:	854a                	mv	a0,s2
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	e84080e7          	jalr	-380(ra) # 8000307e <bread>
  log.lh.n = lh->n;
    80004202:	4d34                	lw	a3,88(a0)
    80004204:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004206:	02d05663          	blez	a3,80004232 <initlog+0x76>
    8000420a:	05c50793          	addi	a5,a0,92
    8000420e:	0023e717          	auipc	a4,0x23e
    80004212:	19270713          	addi	a4,a4,402 # 802423a0 <log+0x30>
    80004216:	36fd                	addiw	a3,a3,-1
    80004218:	02069613          	slli	a2,a3,0x20
    8000421c:	01e65693          	srli	a3,a2,0x1e
    80004220:	06050613          	addi	a2,a0,96
    80004224:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004226:	4390                	lw	a2,0(a5)
    80004228:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000422a:	0791                	addi	a5,a5,4
    8000422c:	0711                	addi	a4,a4,4
    8000422e:	fed79ce3          	bne	a5,a3,80004226 <initlog+0x6a>
  brelse(buf);
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	f7c080e7          	jalr	-132(ra) # 800031ae <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000423a:	4505                	li	a0,1
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	ebc080e7          	jalr	-324(ra) # 800040f8 <install_trans>
  log.lh.n = 0;
    80004244:	0023e797          	auipc	a5,0x23e
    80004248:	1407ac23          	sw	zero,344(a5) # 8024239c <log+0x2c>
  write_head(); // clear the log
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	e30080e7          	jalr	-464(ra) # 8000407c <write_head>
}
    80004254:	70a2                	ld	ra,40(sp)
    80004256:	7402                	ld	s0,32(sp)
    80004258:	64e2                	ld	s1,24(sp)
    8000425a:	6942                	ld	s2,16(sp)
    8000425c:	69a2                	ld	s3,8(sp)
    8000425e:	6145                	addi	sp,sp,48
    80004260:	8082                	ret

0000000080004262 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004262:	1101                	addi	sp,sp,-32
    80004264:	ec06                	sd	ra,24(sp)
    80004266:	e822                	sd	s0,16(sp)
    80004268:	e426                	sd	s1,8(sp)
    8000426a:	e04a                	sd	s2,0(sp)
    8000426c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000426e:	0023e517          	auipc	a0,0x23e
    80004272:	10250513          	addi	a0,a0,258 # 80242370 <log>
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	a96080e7          	jalr	-1386(ra) # 80000d0c <acquire>
  while(1){
    if(log.committing){
    8000427e:	0023e497          	auipc	s1,0x23e
    80004282:	0f248493          	addi	s1,s1,242 # 80242370 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004286:	4979                	li	s2,30
    80004288:	a039                	j	80004296 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000428a:	85a6                	mv	a1,s1
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffe097          	auipc	ra,0xffffe
    80004292:	f16080e7          	jalr	-234(ra) # 800021a4 <sleep>
    if(log.committing){
    80004296:	50dc                	lw	a5,36(s1)
    80004298:	fbed                	bnez	a5,8000428a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429a:	5098                	lw	a4,32(s1)
    8000429c:	2705                	addiw	a4,a4,1
    8000429e:	0007069b          	sext.w	a3,a4
    800042a2:	0027179b          	slliw	a5,a4,0x2
    800042a6:	9fb9                	addw	a5,a5,a4
    800042a8:	0017979b          	slliw	a5,a5,0x1
    800042ac:	54d8                	lw	a4,44(s1)
    800042ae:	9fb9                	addw	a5,a5,a4
    800042b0:	00f95963          	bge	s2,a5,800042c2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042b4:	85a6                	mv	a1,s1
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffe097          	auipc	ra,0xffffe
    800042bc:	eec080e7          	jalr	-276(ra) # 800021a4 <sleep>
    800042c0:	bfd9                	j	80004296 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042c2:	0023e517          	auipc	a0,0x23e
    800042c6:	0ae50513          	addi	a0,a0,174 # 80242370 <log>
    800042ca:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	af4080e7          	jalr	-1292(ra) # 80000dc0 <release>
      break;
    }
  }
}
    800042d4:	60e2                	ld	ra,24(sp)
    800042d6:	6442                	ld	s0,16(sp)
    800042d8:	64a2                	ld	s1,8(sp)
    800042da:	6902                	ld	s2,0(sp)
    800042dc:	6105                	addi	sp,sp,32
    800042de:	8082                	ret

00000000800042e0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042e0:	7139                	addi	sp,sp,-64
    800042e2:	fc06                	sd	ra,56(sp)
    800042e4:	f822                	sd	s0,48(sp)
    800042e6:	f426                	sd	s1,40(sp)
    800042e8:	f04a                	sd	s2,32(sp)
    800042ea:	ec4e                	sd	s3,24(sp)
    800042ec:	e852                	sd	s4,16(sp)
    800042ee:	e456                	sd	s5,8(sp)
    800042f0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042f2:	0023e497          	auipc	s1,0x23e
    800042f6:	07e48493          	addi	s1,s1,126 # 80242370 <log>
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	a10080e7          	jalr	-1520(ra) # 80000d0c <acquire>
  log.outstanding -= 1;
    80004304:	509c                	lw	a5,32(s1)
    80004306:	37fd                	addiw	a5,a5,-1
    80004308:	0007891b          	sext.w	s2,a5
    8000430c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000430e:	50dc                	lw	a5,36(s1)
    80004310:	e7b9                	bnez	a5,8000435e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004312:	04091e63          	bnez	s2,8000436e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004316:	0023e497          	auipc	s1,0x23e
    8000431a:	05a48493          	addi	s1,s1,90 # 80242370 <log>
    8000431e:	4785                	li	a5,1
    80004320:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004322:	8526                	mv	a0,s1
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	a9c080e7          	jalr	-1380(ra) # 80000dc0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000432c:	54dc                	lw	a5,44(s1)
    8000432e:	06f04763          	bgtz	a5,8000439c <end_op+0xbc>
    acquire(&log.lock);
    80004332:	0023e497          	auipc	s1,0x23e
    80004336:	03e48493          	addi	s1,s1,62 # 80242370 <log>
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	9d0080e7          	jalr	-1584(ra) # 80000d0c <acquire>
    log.committing = 0;
    80004344:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffe097          	auipc	ra,0xffffe
    8000434e:	ebe080e7          	jalr	-322(ra) # 80002208 <wakeup>
    release(&log.lock);
    80004352:	8526                	mv	a0,s1
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	a6c080e7          	jalr	-1428(ra) # 80000dc0 <release>
}
    8000435c:	a03d                	j	8000438a <end_op+0xaa>
    panic("log.committing");
    8000435e:	00004517          	auipc	a0,0x4
    80004362:	32250513          	addi	a0,a0,802 # 80008680 <syscalls+0x1f8>
    80004366:	ffffc097          	auipc	ra,0xffffc
    8000436a:	1da080e7          	jalr	474(ra) # 80000540 <panic>
    wakeup(&log);
    8000436e:	0023e497          	auipc	s1,0x23e
    80004372:	00248493          	addi	s1,s1,2 # 80242370 <log>
    80004376:	8526                	mv	a0,s1
    80004378:	ffffe097          	auipc	ra,0xffffe
    8000437c:	e90080e7          	jalr	-368(ra) # 80002208 <wakeup>
  release(&log.lock);
    80004380:	8526                	mv	a0,s1
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	a3e080e7          	jalr	-1474(ra) # 80000dc0 <release>
}
    8000438a:	70e2                	ld	ra,56(sp)
    8000438c:	7442                	ld	s0,48(sp)
    8000438e:	74a2                	ld	s1,40(sp)
    80004390:	7902                	ld	s2,32(sp)
    80004392:	69e2                	ld	s3,24(sp)
    80004394:	6a42                	ld	s4,16(sp)
    80004396:	6aa2                	ld	s5,8(sp)
    80004398:	6121                	addi	sp,sp,64
    8000439a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000439c:	0023ea97          	auipc	s5,0x23e
    800043a0:	004a8a93          	addi	s5,s5,4 # 802423a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043a4:	0023ea17          	auipc	s4,0x23e
    800043a8:	fcca0a13          	addi	s4,s4,-52 # 80242370 <log>
    800043ac:	018a2583          	lw	a1,24(s4)
    800043b0:	012585bb          	addw	a1,a1,s2
    800043b4:	2585                	addiw	a1,a1,1
    800043b6:	028a2503          	lw	a0,40(s4)
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	cc4080e7          	jalr	-828(ra) # 8000307e <bread>
    800043c2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043c4:	000aa583          	lw	a1,0(s5)
    800043c8:	028a2503          	lw	a0,40(s4)
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	cb2080e7          	jalr	-846(ra) # 8000307e <bread>
    800043d4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043d6:	40000613          	li	a2,1024
    800043da:	05850593          	addi	a1,a0,88
    800043de:	05848513          	addi	a0,s1,88
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	a82080e7          	jalr	-1406(ra) # 80000e64 <memmove>
    bwrite(to);  // write the log
    800043ea:	8526                	mv	a0,s1
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	d84080e7          	jalr	-636(ra) # 80003170 <bwrite>
    brelse(from);
    800043f4:	854e                	mv	a0,s3
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	db8080e7          	jalr	-584(ra) # 800031ae <brelse>
    brelse(to);
    800043fe:	8526                	mv	a0,s1
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	dae080e7          	jalr	-594(ra) # 800031ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004408:	2905                	addiw	s2,s2,1
    8000440a:	0a91                	addi	s5,s5,4
    8000440c:	02ca2783          	lw	a5,44(s4)
    80004410:	f8f94ee3          	blt	s2,a5,800043ac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004414:	00000097          	auipc	ra,0x0
    80004418:	c68080e7          	jalr	-920(ra) # 8000407c <write_head>
    install_trans(0); // Now install writes to home locations
    8000441c:	4501                	li	a0,0
    8000441e:	00000097          	auipc	ra,0x0
    80004422:	cda080e7          	jalr	-806(ra) # 800040f8 <install_trans>
    log.lh.n = 0;
    80004426:	0023e797          	auipc	a5,0x23e
    8000442a:	f607ab23          	sw	zero,-138(a5) # 8024239c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	c4e080e7          	jalr	-946(ra) # 8000407c <write_head>
    80004436:	bdf5                	j	80004332 <end_op+0x52>

0000000080004438 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	e04a                	sd	s2,0(sp)
    80004442:	1000                	addi	s0,sp,32
    80004444:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004446:	0023e917          	auipc	s2,0x23e
    8000444a:	f2a90913          	addi	s2,s2,-214 # 80242370 <log>
    8000444e:	854a                	mv	a0,s2
    80004450:	ffffd097          	auipc	ra,0xffffd
    80004454:	8bc080e7          	jalr	-1860(ra) # 80000d0c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004458:	02c92603          	lw	a2,44(s2)
    8000445c:	47f5                	li	a5,29
    8000445e:	06c7c563          	blt	a5,a2,800044c8 <log_write+0x90>
    80004462:	0023e797          	auipc	a5,0x23e
    80004466:	f2a7a783          	lw	a5,-214(a5) # 8024238c <log+0x1c>
    8000446a:	37fd                	addiw	a5,a5,-1
    8000446c:	04f65e63          	bge	a2,a5,800044c8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004470:	0023e797          	auipc	a5,0x23e
    80004474:	f207a783          	lw	a5,-224(a5) # 80242390 <log+0x20>
    80004478:	06f05063          	blez	a5,800044d8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000447c:	4781                	li	a5,0
    8000447e:	06c05563          	blez	a2,800044e8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004482:	44cc                	lw	a1,12(s1)
    80004484:	0023e717          	auipc	a4,0x23e
    80004488:	f1c70713          	addi	a4,a4,-228 # 802423a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000448e:	4314                	lw	a3,0(a4)
    80004490:	04b68c63          	beq	a3,a1,800044e8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004494:	2785                	addiw	a5,a5,1
    80004496:	0711                	addi	a4,a4,4
    80004498:	fef61be3          	bne	a2,a5,8000448e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000449c:	0621                	addi	a2,a2,8
    8000449e:	060a                	slli	a2,a2,0x2
    800044a0:	0023e797          	auipc	a5,0x23e
    800044a4:	ed078793          	addi	a5,a5,-304 # 80242370 <log>
    800044a8:	97b2                	add	a5,a5,a2
    800044aa:	44d8                	lw	a4,12(s1)
    800044ac:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044ae:	8526                	mv	a0,s1
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	d9c080e7          	jalr	-612(ra) # 8000324c <bpin>
    log.lh.n++;
    800044b8:	0023e717          	auipc	a4,0x23e
    800044bc:	eb870713          	addi	a4,a4,-328 # 80242370 <log>
    800044c0:	575c                	lw	a5,44(a4)
    800044c2:	2785                	addiw	a5,a5,1
    800044c4:	d75c                	sw	a5,44(a4)
    800044c6:	a82d                	j	80004500 <log_write+0xc8>
    panic("too big a transaction");
    800044c8:	00004517          	auipc	a0,0x4
    800044cc:	1c850513          	addi	a0,a0,456 # 80008690 <syscalls+0x208>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	070080e7          	jalr	112(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	1d050513          	addi	a0,a0,464 # 800086a8 <syscalls+0x220>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	060080e7          	jalr	96(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800044e8:	00878693          	addi	a3,a5,8
    800044ec:	068a                	slli	a3,a3,0x2
    800044ee:	0023e717          	auipc	a4,0x23e
    800044f2:	e8270713          	addi	a4,a4,-382 # 80242370 <log>
    800044f6:	9736                	add	a4,a4,a3
    800044f8:	44d4                	lw	a3,12(s1)
    800044fa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044fc:	faf609e3          	beq	a2,a5,800044ae <log_write+0x76>
  }
  release(&log.lock);
    80004500:	0023e517          	auipc	a0,0x23e
    80004504:	e7050513          	addi	a0,a0,-400 # 80242370 <log>
    80004508:	ffffd097          	auipc	ra,0xffffd
    8000450c:	8b8080e7          	jalr	-1864(ra) # 80000dc0 <release>
}
    80004510:	60e2                	ld	ra,24(sp)
    80004512:	6442                	ld	s0,16(sp)
    80004514:	64a2                	ld	s1,8(sp)
    80004516:	6902                	ld	s2,0(sp)
    80004518:	6105                	addi	sp,sp,32
    8000451a:	8082                	ret

000000008000451c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	e04a                	sd	s2,0(sp)
    80004526:	1000                	addi	s0,sp,32
    80004528:	84aa                	mv	s1,a0
    8000452a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000452c:	00004597          	auipc	a1,0x4
    80004530:	19c58593          	addi	a1,a1,412 # 800086c8 <syscalls+0x240>
    80004534:	0521                	addi	a0,a0,8
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	746080e7          	jalr	1862(ra) # 80000c7c <initlock>
  lk->name = name;
    8000453e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004542:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004546:	0204a423          	sw	zero,40(s1)
}
    8000454a:	60e2                	ld	ra,24(sp)
    8000454c:	6442                	ld	s0,16(sp)
    8000454e:	64a2                	ld	s1,8(sp)
    80004550:	6902                	ld	s2,0(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004556:	1101                	addi	sp,sp,-32
    80004558:	ec06                	sd	ra,24(sp)
    8000455a:	e822                	sd	s0,16(sp)
    8000455c:	e426                	sd	s1,8(sp)
    8000455e:	e04a                	sd	s2,0(sp)
    80004560:	1000                	addi	s0,sp,32
    80004562:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004564:	00850913          	addi	s2,a0,8
    80004568:	854a                	mv	a0,s2
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	7a2080e7          	jalr	1954(ra) # 80000d0c <acquire>
  while (lk->locked) {
    80004572:	409c                	lw	a5,0(s1)
    80004574:	cb89                	beqz	a5,80004586 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004576:	85ca                	mv	a1,s2
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffe097          	auipc	ra,0xffffe
    8000457e:	c2a080e7          	jalr	-982(ra) # 800021a4 <sleep>
  while (lk->locked) {
    80004582:	409c                	lw	a5,0(s1)
    80004584:	fbed                	bnez	a5,80004576 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004586:	4785                	li	a5,1
    80004588:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000458a:	ffffd097          	auipc	ra,0xffffd
    8000458e:	572080e7          	jalr	1394(ra) # 80001afc <myproc>
    80004592:	591c                	lw	a5,48(a0)
    80004594:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004596:	854a                	mv	a0,s2
    80004598:	ffffd097          	auipc	ra,0xffffd
    8000459c:	828080e7          	jalr	-2008(ra) # 80000dc0 <release>
}
    800045a0:	60e2                	ld	ra,24(sp)
    800045a2:	6442                	ld	s0,16(sp)
    800045a4:	64a2                	ld	s1,8(sp)
    800045a6:	6902                	ld	s2,0(sp)
    800045a8:	6105                	addi	sp,sp,32
    800045aa:	8082                	ret

00000000800045ac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045ac:	1101                	addi	sp,sp,-32
    800045ae:	ec06                	sd	ra,24(sp)
    800045b0:	e822                	sd	s0,16(sp)
    800045b2:	e426                	sd	s1,8(sp)
    800045b4:	e04a                	sd	s2,0(sp)
    800045b6:	1000                	addi	s0,sp,32
    800045b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ba:	00850913          	addi	s2,a0,8
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	74c080e7          	jalr	1868(ra) # 80000d0c <acquire>
  lk->locked = 0;
    800045c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045cc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045d0:	8526                	mv	a0,s1
    800045d2:	ffffe097          	auipc	ra,0xffffe
    800045d6:	c36080e7          	jalr	-970(ra) # 80002208 <wakeup>
  release(&lk->lk);
    800045da:	854a                	mv	a0,s2
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	7e4080e7          	jalr	2020(ra) # 80000dc0 <release>
}
    800045e4:	60e2                	ld	ra,24(sp)
    800045e6:	6442                	ld	s0,16(sp)
    800045e8:	64a2                	ld	s1,8(sp)
    800045ea:	6902                	ld	s2,0(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret

00000000800045f0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045f0:	7179                	addi	sp,sp,-48
    800045f2:	f406                	sd	ra,40(sp)
    800045f4:	f022                	sd	s0,32(sp)
    800045f6:	ec26                	sd	s1,24(sp)
    800045f8:	e84a                	sd	s2,16(sp)
    800045fa:	e44e                	sd	s3,8(sp)
    800045fc:	1800                	addi	s0,sp,48
    800045fe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004600:	00850913          	addi	s2,a0,8
    80004604:	854a                	mv	a0,s2
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	706080e7          	jalr	1798(ra) # 80000d0c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000460e:	409c                	lw	a5,0(s1)
    80004610:	ef99                	bnez	a5,8000462e <holdingsleep+0x3e>
    80004612:	4481                	li	s1,0
  release(&lk->lk);
    80004614:	854a                	mv	a0,s2
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	7aa080e7          	jalr	1962(ra) # 80000dc0 <release>
  return r;
}
    8000461e:	8526                	mv	a0,s1
    80004620:	70a2                	ld	ra,40(sp)
    80004622:	7402                	ld	s0,32(sp)
    80004624:	64e2                	ld	s1,24(sp)
    80004626:	6942                	ld	s2,16(sp)
    80004628:	69a2                	ld	s3,8(sp)
    8000462a:	6145                	addi	sp,sp,48
    8000462c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000462e:	0284a983          	lw	s3,40(s1)
    80004632:	ffffd097          	auipc	ra,0xffffd
    80004636:	4ca080e7          	jalr	1226(ra) # 80001afc <myproc>
    8000463a:	5904                	lw	s1,48(a0)
    8000463c:	413484b3          	sub	s1,s1,s3
    80004640:	0014b493          	seqz	s1,s1
    80004644:	bfc1                	j	80004614 <holdingsleep+0x24>

0000000080004646 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004646:	1141                	addi	sp,sp,-16
    80004648:	e406                	sd	ra,8(sp)
    8000464a:	e022                	sd	s0,0(sp)
    8000464c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000464e:	00004597          	auipc	a1,0x4
    80004652:	08a58593          	addi	a1,a1,138 # 800086d8 <syscalls+0x250>
    80004656:	0023e517          	auipc	a0,0x23e
    8000465a:	e6250513          	addi	a0,a0,-414 # 802424b8 <ftable>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	61e080e7          	jalr	1566(ra) # 80000c7c <initlock>
}
    80004666:	60a2                	ld	ra,8(sp)
    80004668:	6402                	ld	s0,0(sp)
    8000466a:	0141                	addi	sp,sp,16
    8000466c:	8082                	ret

000000008000466e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000466e:	1101                	addi	sp,sp,-32
    80004670:	ec06                	sd	ra,24(sp)
    80004672:	e822                	sd	s0,16(sp)
    80004674:	e426                	sd	s1,8(sp)
    80004676:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004678:	0023e517          	auipc	a0,0x23e
    8000467c:	e4050513          	addi	a0,a0,-448 # 802424b8 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	68c080e7          	jalr	1676(ra) # 80000d0c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004688:	0023e497          	auipc	s1,0x23e
    8000468c:	e4848493          	addi	s1,s1,-440 # 802424d0 <ftable+0x18>
    80004690:	0023f717          	auipc	a4,0x23f
    80004694:	de070713          	addi	a4,a4,-544 # 80243470 <disk>
    if(f->ref == 0){
    80004698:	40dc                	lw	a5,4(s1)
    8000469a:	cf99                	beqz	a5,800046b8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000469c:	02848493          	addi	s1,s1,40
    800046a0:	fee49ce3          	bne	s1,a4,80004698 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046a4:	0023e517          	auipc	a0,0x23e
    800046a8:	e1450513          	addi	a0,a0,-492 # 802424b8 <ftable>
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	714080e7          	jalr	1812(ra) # 80000dc0 <release>
  return 0;
    800046b4:	4481                	li	s1,0
    800046b6:	a819                	j	800046cc <filealloc+0x5e>
      f->ref = 1;
    800046b8:	4785                	li	a5,1
    800046ba:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046bc:	0023e517          	auipc	a0,0x23e
    800046c0:	dfc50513          	addi	a0,a0,-516 # 802424b8 <ftable>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	6fc080e7          	jalr	1788(ra) # 80000dc0 <release>
}
    800046cc:	8526                	mv	a0,s1
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6105                	addi	sp,sp,32
    800046d6:	8082                	ret

00000000800046d8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046d8:	1101                	addi	sp,sp,-32
    800046da:	ec06                	sd	ra,24(sp)
    800046dc:	e822                	sd	s0,16(sp)
    800046de:	e426                	sd	s1,8(sp)
    800046e0:	1000                	addi	s0,sp,32
    800046e2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046e4:	0023e517          	auipc	a0,0x23e
    800046e8:	dd450513          	addi	a0,a0,-556 # 802424b8 <ftable>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	620080e7          	jalr	1568(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    800046f4:	40dc                	lw	a5,4(s1)
    800046f6:	02f05263          	blez	a5,8000471a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046fa:	2785                	addiw	a5,a5,1
    800046fc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046fe:	0023e517          	auipc	a0,0x23e
    80004702:	dba50513          	addi	a0,a0,-582 # 802424b8 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	6ba080e7          	jalr	1722(ra) # 80000dc0 <release>
  return f;
}
    8000470e:	8526                	mv	a0,s1
    80004710:	60e2                	ld	ra,24(sp)
    80004712:	6442                	ld	s0,16(sp)
    80004714:	64a2                	ld	s1,8(sp)
    80004716:	6105                	addi	sp,sp,32
    80004718:	8082                	ret
    panic("filedup");
    8000471a:	00004517          	auipc	a0,0x4
    8000471e:	fc650513          	addi	a0,a0,-58 # 800086e0 <syscalls+0x258>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	e1e080e7          	jalr	-482(ra) # 80000540 <panic>

000000008000472a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000472a:	7139                	addi	sp,sp,-64
    8000472c:	fc06                	sd	ra,56(sp)
    8000472e:	f822                	sd	s0,48(sp)
    80004730:	f426                	sd	s1,40(sp)
    80004732:	f04a                	sd	s2,32(sp)
    80004734:	ec4e                	sd	s3,24(sp)
    80004736:	e852                	sd	s4,16(sp)
    80004738:	e456                	sd	s5,8(sp)
    8000473a:	0080                	addi	s0,sp,64
    8000473c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000473e:	0023e517          	auipc	a0,0x23e
    80004742:	d7a50513          	addi	a0,a0,-646 # 802424b8 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	5c6080e7          	jalr	1478(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    8000474e:	40dc                	lw	a5,4(s1)
    80004750:	06f05163          	blez	a5,800047b2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004754:	37fd                	addiw	a5,a5,-1
    80004756:	0007871b          	sext.w	a4,a5
    8000475a:	c0dc                	sw	a5,4(s1)
    8000475c:	06e04363          	bgtz	a4,800047c2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004760:	0004a903          	lw	s2,0(s1)
    80004764:	0094ca83          	lbu	s5,9(s1)
    80004768:	0104ba03          	ld	s4,16(s1)
    8000476c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004770:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004774:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004778:	0023e517          	auipc	a0,0x23e
    8000477c:	d4050513          	addi	a0,a0,-704 # 802424b8 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	640080e7          	jalr	1600(ra) # 80000dc0 <release>

  if(ff.type == FD_PIPE){
    80004788:	4785                	li	a5,1
    8000478a:	04f90d63          	beq	s2,a5,800047e4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000478e:	3979                	addiw	s2,s2,-2
    80004790:	4785                	li	a5,1
    80004792:	0527e063          	bltu	a5,s2,800047d2 <fileclose+0xa8>
    begin_op();
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	acc080e7          	jalr	-1332(ra) # 80004262 <begin_op>
    iput(ff.ip);
    8000479e:	854e                	mv	a0,s3
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	2b0080e7          	jalr	688(ra) # 80003a50 <iput>
    end_op();
    800047a8:	00000097          	auipc	ra,0x0
    800047ac:	b38080e7          	jalr	-1224(ra) # 800042e0 <end_op>
    800047b0:	a00d                	j	800047d2 <fileclose+0xa8>
    panic("fileclose");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	f3650513          	addi	a0,a0,-202 # 800086e8 <syscalls+0x260>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d86080e7          	jalr	-634(ra) # 80000540 <panic>
    release(&ftable.lock);
    800047c2:	0023e517          	auipc	a0,0x23e
    800047c6:	cf650513          	addi	a0,a0,-778 # 802424b8 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	5f6080e7          	jalr	1526(ra) # 80000dc0 <release>
  }
}
    800047d2:	70e2                	ld	ra,56(sp)
    800047d4:	7442                	ld	s0,48(sp)
    800047d6:	74a2                	ld	s1,40(sp)
    800047d8:	7902                	ld	s2,32(sp)
    800047da:	69e2                	ld	s3,24(sp)
    800047dc:	6a42                	ld	s4,16(sp)
    800047de:	6aa2                	ld	s5,8(sp)
    800047e0:	6121                	addi	sp,sp,64
    800047e2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047e4:	85d6                	mv	a1,s5
    800047e6:	8552                	mv	a0,s4
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	34c080e7          	jalr	844(ra) # 80004b34 <pipeclose>
    800047f0:	b7cd                	j	800047d2 <fileclose+0xa8>

00000000800047f2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047f2:	715d                	addi	sp,sp,-80
    800047f4:	e486                	sd	ra,72(sp)
    800047f6:	e0a2                	sd	s0,64(sp)
    800047f8:	fc26                	sd	s1,56(sp)
    800047fa:	f84a                	sd	s2,48(sp)
    800047fc:	f44e                	sd	s3,40(sp)
    800047fe:	0880                	addi	s0,sp,80
    80004800:	84aa                	mv	s1,a0
    80004802:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004804:	ffffd097          	auipc	ra,0xffffd
    80004808:	2f8080e7          	jalr	760(ra) # 80001afc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000480c:	409c                	lw	a5,0(s1)
    8000480e:	37f9                	addiw	a5,a5,-2
    80004810:	4705                	li	a4,1
    80004812:	04f76763          	bltu	a4,a5,80004860 <filestat+0x6e>
    80004816:	892a                	mv	s2,a0
    ilock(f->ip);
    80004818:	6c88                	ld	a0,24(s1)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	07c080e7          	jalr	124(ra) # 80003896 <ilock>
    stati(f->ip, &st);
    80004822:	fb840593          	addi	a1,s0,-72
    80004826:	6c88                	ld	a0,24(s1)
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	2f8080e7          	jalr	760(ra) # 80003b20 <stati>
    iunlock(f->ip);
    80004830:	6c88                	ld	a0,24(s1)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	126080e7          	jalr	294(ra) # 80003958 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000483a:	46e1                	li	a3,24
    8000483c:	fb840613          	addi	a2,s0,-72
    80004840:	85ce                	mv	a1,s3
    80004842:	05093503          	ld	a0,80(s2)
    80004846:	ffffd097          	auipc	ra,0xffffd
    8000484a:	f42080e7          	jalr	-190(ra) # 80001788 <copyout>
    8000484e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004852:	60a6                	ld	ra,72(sp)
    80004854:	6406                	ld	s0,64(sp)
    80004856:	74e2                	ld	s1,56(sp)
    80004858:	7942                	ld	s2,48(sp)
    8000485a:	79a2                	ld	s3,40(sp)
    8000485c:	6161                	addi	sp,sp,80
    8000485e:	8082                	ret
  return -1;
    80004860:	557d                	li	a0,-1
    80004862:	bfc5                	j	80004852 <filestat+0x60>

0000000080004864 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004864:	7179                	addi	sp,sp,-48
    80004866:	f406                	sd	ra,40(sp)
    80004868:	f022                	sd	s0,32(sp)
    8000486a:	ec26                	sd	s1,24(sp)
    8000486c:	e84a                	sd	s2,16(sp)
    8000486e:	e44e                	sd	s3,8(sp)
    80004870:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004872:	00854783          	lbu	a5,8(a0)
    80004876:	c3d5                	beqz	a5,8000491a <fileread+0xb6>
    80004878:	84aa                	mv	s1,a0
    8000487a:	89ae                	mv	s3,a1
    8000487c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487e:	411c                	lw	a5,0(a0)
    80004880:	4705                	li	a4,1
    80004882:	04e78963          	beq	a5,a4,800048d4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004886:	470d                	li	a4,3
    80004888:	04e78d63          	beq	a5,a4,800048e2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488c:	4709                	li	a4,2
    8000488e:	06e79e63          	bne	a5,a4,8000490a <fileread+0xa6>
    ilock(f->ip);
    80004892:	6d08                	ld	a0,24(a0)
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	002080e7          	jalr	2(ra) # 80003896 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000489c:	874a                	mv	a4,s2
    8000489e:	5094                	lw	a3,32(s1)
    800048a0:	864e                	mv	a2,s3
    800048a2:	4585                	li	a1,1
    800048a4:	6c88                	ld	a0,24(s1)
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	2a4080e7          	jalr	676(ra) # 80003b4a <readi>
    800048ae:	892a                	mv	s2,a0
    800048b0:	00a05563          	blez	a0,800048ba <fileread+0x56>
      f->off += r;
    800048b4:	509c                	lw	a5,32(s1)
    800048b6:	9fa9                	addw	a5,a5,a0
    800048b8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048ba:	6c88                	ld	a0,24(s1)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	09c080e7          	jalr	156(ra) # 80003958 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048c4:	854a                	mv	a0,s2
    800048c6:	70a2                	ld	ra,40(sp)
    800048c8:	7402                	ld	s0,32(sp)
    800048ca:	64e2                	ld	s1,24(sp)
    800048cc:	6942                	ld	s2,16(sp)
    800048ce:	69a2                	ld	s3,8(sp)
    800048d0:	6145                	addi	sp,sp,48
    800048d2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048d4:	6908                	ld	a0,16(a0)
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	3c6080e7          	jalr	966(ra) # 80004c9c <piperead>
    800048de:	892a                	mv	s2,a0
    800048e0:	b7d5                	j	800048c4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048e2:	02451783          	lh	a5,36(a0)
    800048e6:	03079693          	slli	a3,a5,0x30
    800048ea:	92c1                	srli	a3,a3,0x30
    800048ec:	4725                	li	a4,9
    800048ee:	02d76863          	bltu	a4,a3,8000491e <fileread+0xba>
    800048f2:	0792                	slli	a5,a5,0x4
    800048f4:	0023e717          	auipc	a4,0x23e
    800048f8:	b2470713          	addi	a4,a4,-1244 # 80242418 <devsw>
    800048fc:	97ba                	add	a5,a5,a4
    800048fe:	639c                	ld	a5,0(a5)
    80004900:	c38d                	beqz	a5,80004922 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004902:	4505                	li	a0,1
    80004904:	9782                	jalr	a5
    80004906:	892a                	mv	s2,a0
    80004908:	bf75                	j	800048c4 <fileread+0x60>
    panic("fileread");
    8000490a:	00004517          	auipc	a0,0x4
    8000490e:	dee50513          	addi	a0,a0,-530 # 800086f8 <syscalls+0x270>
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	c2e080e7          	jalr	-978(ra) # 80000540 <panic>
    return -1;
    8000491a:	597d                	li	s2,-1
    8000491c:	b765                	j	800048c4 <fileread+0x60>
      return -1;
    8000491e:	597d                	li	s2,-1
    80004920:	b755                	j	800048c4 <fileread+0x60>
    80004922:	597d                	li	s2,-1
    80004924:	b745                	j	800048c4 <fileread+0x60>

0000000080004926 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004926:	715d                	addi	sp,sp,-80
    80004928:	e486                	sd	ra,72(sp)
    8000492a:	e0a2                	sd	s0,64(sp)
    8000492c:	fc26                	sd	s1,56(sp)
    8000492e:	f84a                	sd	s2,48(sp)
    80004930:	f44e                	sd	s3,40(sp)
    80004932:	f052                	sd	s4,32(sp)
    80004934:	ec56                	sd	s5,24(sp)
    80004936:	e85a                	sd	s6,16(sp)
    80004938:	e45e                	sd	s7,8(sp)
    8000493a:	e062                	sd	s8,0(sp)
    8000493c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000493e:	00954783          	lbu	a5,9(a0)
    80004942:	10078663          	beqz	a5,80004a4e <filewrite+0x128>
    80004946:	892a                	mv	s2,a0
    80004948:	8b2e                	mv	s6,a1
    8000494a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000494c:	411c                	lw	a5,0(a0)
    8000494e:	4705                	li	a4,1
    80004950:	02e78263          	beq	a5,a4,80004974 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004954:	470d                	li	a4,3
    80004956:	02e78663          	beq	a5,a4,80004982 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000495a:	4709                	li	a4,2
    8000495c:	0ee79163          	bne	a5,a4,80004a3e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004960:	0ac05d63          	blez	a2,80004a1a <filewrite+0xf4>
    int i = 0;
    80004964:	4981                	li	s3,0
    80004966:	6b85                	lui	s7,0x1
    80004968:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000496c:	6c05                	lui	s8,0x1
    8000496e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004972:	a861                	j	80004a0a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004974:	6908                	ld	a0,16(a0)
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	22e080e7          	jalr	558(ra) # 80004ba4 <pipewrite>
    8000497e:	8a2a                	mv	s4,a0
    80004980:	a045                	j	80004a20 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004982:	02451783          	lh	a5,36(a0)
    80004986:	03079693          	slli	a3,a5,0x30
    8000498a:	92c1                	srli	a3,a3,0x30
    8000498c:	4725                	li	a4,9
    8000498e:	0cd76263          	bltu	a4,a3,80004a52 <filewrite+0x12c>
    80004992:	0792                	slli	a5,a5,0x4
    80004994:	0023e717          	auipc	a4,0x23e
    80004998:	a8470713          	addi	a4,a4,-1404 # 80242418 <devsw>
    8000499c:	97ba                	add	a5,a5,a4
    8000499e:	679c                	ld	a5,8(a5)
    800049a0:	cbdd                	beqz	a5,80004a56 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049a2:	4505                	li	a0,1
    800049a4:	9782                	jalr	a5
    800049a6:	8a2a                	mv	s4,a0
    800049a8:	a8a5                	j	80004a20 <filewrite+0xfa>
    800049aa:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	8b4080e7          	jalr	-1868(ra) # 80004262 <begin_op>
      ilock(f->ip);
    800049b6:	01893503          	ld	a0,24(s2)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	edc080e7          	jalr	-292(ra) # 80003896 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049c2:	8756                	mv	a4,s5
    800049c4:	02092683          	lw	a3,32(s2)
    800049c8:	01698633          	add	a2,s3,s6
    800049cc:	4585                	li	a1,1
    800049ce:	01893503          	ld	a0,24(s2)
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	270080e7          	jalr	624(ra) # 80003c42 <writei>
    800049da:	84aa                	mv	s1,a0
    800049dc:	00a05763          	blez	a0,800049ea <filewrite+0xc4>
        f->off += r;
    800049e0:	02092783          	lw	a5,32(s2)
    800049e4:	9fa9                	addw	a5,a5,a0
    800049e6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049ea:	01893503          	ld	a0,24(s2)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	f6a080e7          	jalr	-150(ra) # 80003958 <iunlock>
      end_op();
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	8ea080e7          	jalr	-1814(ra) # 800042e0 <end_op>

      if(r != n1){
    800049fe:	009a9f63          	bne	s5,s1,80004a1c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a02:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a06:	0149db63          	bge	s3,s4,80004a1c <filewrite+0xf6>
      int n1 = n - i;
    80004a0a:	413a04bb          	subw	s1,s4,s3
    80004a0e:	0004879b          	sext.w	a5,s1
    80004a12:	f8fbdce3          	bge	s7,a5,800049aa <filewrite+0x84>
    80004a16:	84e2                	mv	s1,s8
    80004a18:	bf49                	j	800049aa <filewrite+0x84>
    int i = 0;
    80004a1a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a1c:	013a1f63          	bne	s4,s3,80004a3a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a20:	8552                	mv	a0,s4
    80004a22:	60a6                	ld	ra,72(sp)
    80004a24:	6406                	ld	s0,64(sp)
    80004a26:	74e2                	ld	s1,56(sp)
    80004a28:	7942                	ld	s2,48(sp)
    80004a2a:	79a2                	ld	s3,40(sp)
    80004a2c:	7a02                	ld	s4,32(sp)
    80004a2e:	6ae2                	ld	s5,24(sp)
    80004a30:	6b42                	ld	s6,16(sp)
    80004a32:	6ba2                	ld	s7,8(sp)
    80004a34:	6c02                	ld	s8,0(sp)
    80004a36:	6161                	addi	sp,sp,80
    80004a38:	8082                	ret
    ret = (i == n ? n : -1);
    80004a3a:	5a7d                	li	s4,-1
    80004a3c:	b7d5                	j	80004a20 <filewrite+0xfa>
    panic("filewrite");
    80004a3e:	00004517          	auipc	a0,0x4
    80004a42:	cca50513          	addi	a0,a0,-822 # 80008708 <syscalls+0x280>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	afa080e7          	jalr	-1286(ra) # 80000540 <panic>
    return -1;
    80004a4e:	5a7d                	li	s4,-1
    80004a50:	bfc1                	j	80004a20 <filewrite+0xfa>
      return -1;
    80004a52:	5a7d                	li	s4,-1
    80004a54:	b7f1                	j	80004a20 <filewrite+0xfa>
    80004a56:	5a7d                	li	s4,-1
    80004a58:	b7e1                	j	80004a20 <filewrite+0xfa>

0000000080004a5a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a5a:	7179                	addi	sp,sp,-48
    80004a5c:	f406                	sd	ra,40(sp)
    80004a5e:	f022                	sd	s0,32(sp)
    80004a60:	ec26                	sd	s1,24(sp)
    80004a62:	e84a                	sd	s2,16(sp)
    80004a64:	e44e                	sd	s3,8(sp)
    80004a66:	e052                	sd	s4,0(sp)
    80004a68:	1800                	addi	s0,sp,48
    80004a6a:	84aa                	mv	s1,a0
    80004a6c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a6e:	0005b023          	sd	zero,0(a1)
    80004a72:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a76:	00000097          	auipc	ra,0x0
    80004a7a:	bf8080e7          	jalr	-1032(ra) # 8000466e <filealloc>
    80004a7e:	e088                	sd	a0,0(s1)
    80004a80:	c551                	beqz	a0,80004b0c <pipealloc+0xb2>
    80004a82:	00000097          	auipc	ra,0x0
    80004a86:	bec080e7          	jalr	-1044(ra) # 8000466e <filealloc>
    80004a8a:	00aa3023          	sd	a0,0(s4)
    80004a8e:	c92d                	beqz	a0,80004b00 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	154080e7          	jalr	340(ra) # 80000be4 <kalloc>
    80004a98:	892a                	mv	s2,a0
    80004a9a:	c125                	beqz	a0,80004afa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a9c:	4985                	li	s3,1
    80004a9e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aa2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aa6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aaa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aae:	00004597          	auipc	a1,0x4
    80004ab2:	c6a58593          	addi	a1,a1,-918 # 80008718 <syscalls+0x290>
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	1c6080e7          	jalr	454(ra) # 80000c7c <initlock>
  (*f0)->type = FD_PIPE;
    80004abe:	609c                	ld	a5,0(s1)
    80004ac0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ac4:	609c                	ld	a5,0(s1)
    80004ac6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004aca:	609c                	ld	a5,0(s1)
    80004acc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ad0:	609c                	ld	a5,0(s1)
    80004ad2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ad6:	000a3783          	ld	a5,0(s4)
    80004ada:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ade:	000a3783          	ld	a5,0(s4)
    80004ae2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ae6:	000a3783          	ld	a5,0(s4)
    80004aea:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aee:	000a3783          	ld	a5,0(s4)
    80004af2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004af6:	4501                	li	a0,0
    80004af8:	a025                	j	80004b20 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004afa:	6088                	ld	a0,0(s1)
    80004afc:	e501                	bnez	a0,80004b04 <pipealloc+0xaa>
    80004afe:	a039                	j	80004b0c <pipealloc+0xb2>
    80004b00:	6088                	ld	a0,0(s1)
    80004b02:	c51d                	beqz	a0,80004b30 <pipealloc+0xd6>
    fileclose(*f0);
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	c26080e7          	jalr	-986(ra) # 8000472a <fileclose>
  if(*f1)
    80004b0c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b10:	557d                	li	a0,-1
  if(*f1)
    80004b12:	c799                	beqz	a5,80004b20 <pipealloc+0xc6>
    fileclose(*f1);
    80004b14:	853e                	mv	a0,a5
    80004b16:	00000097          	auipc	ra,0x0
    80004b1a:	c14080e7          	jalr	-1004(ra) # 8000472a <fileclose>
  return -1;
    80004b1e:	557d                	li	a0,-1
}
    80004b20:	70a2                	ld	ra,40(sp)
    80004b22:	7402                	ld	s0,32(sp)
    80004b24:	64e2                	ld	s1,24(sp)
    80004b26:	6942                	ld	s2,16(sp)
    80004b28:	69a2                	ld	s3,8(sp)
    80004b2a:	6a02                	ld	s4,0(sp)
    80004b2c:	6145                	addi	sp,sp,48
    80004b2e:	8082                	ret
  return -1;
    80004b30:	557d                	li	a0,-1
    80004b32:	b7fd                	j	80004b20 <pipealloc+0xc6>

0000000080004b34 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b34:	1101                	addi	sp,sp,-32
    80004b36:	ec06                	sd	ra,24(sp)
    80004b38:	e822                	sd	s0,16(sp)
    80004b3a:	e426                	sd	s1,8(sp)
    80004b3c:	e04a                	sd	s2,0(sp)
    80004b3e:	1000                	addi	s0,sp,32
    80004b40:	84aa                	mv	s1,a0
    80004b42:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	1c8080e7          	jalr	456(ra) # 80000d0c <acquire>
  if(writable){
    80004b4c:	02090d63          	beqz	s2,80004b86 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b50:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b54:	21848513          	addi	a0,s1,536
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	6b0080e7          	jalr	1712(ra) # 80002208 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b60:	2204b783          	ld	a5,544(s1)
    80004b64:	eb95                	bnez	a5,80004b98 <pipeclose+0x64>
    release(&pi->lock);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	258080e7          	jalr	600(ra) # 80000dc0 <release>
    kfree((char*)pi);
    80004b70:	8526                	mv	a0,s1
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	eee080e7          	jalr	-274(ra) # 80000a60 <kfree>
  } else
    release(&pi->lock);
}
    80004b7a:	60e2                	ld	ra,24(sp)
    80004b7c:	6442                	ld	s0,16(sp)
    80004b7e:	64a2                	ld	s1,8(sp)
    80004b80:	6902                	ld	s2,0(sp)
    80004b82:	6105                	addi	sp,sp,32
    80004b84:	8082                	ret
    pi->readopen = 0;
    80004b86:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b8a:	21c48513          	addi	a0,s1,540
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	67a080e7          	jalr	1658(ra) # 80002208 <wakeup>
    80004b96:	b7e9                	j	80004b60 <pipeclose+0x2c>
    release(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	226080e7          	jalr	550(ra) # 80000dc0 <release>
}
    80004ba2:	bfe1                	j	80004b7a <pipeclose+0x46>

0000000080004ba4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ba4:	711d                	addi	sp,sp,-96
    80004ba6:	ec86                	sd	ra,88(sp)
    80004ba8:	e8a2                	sd	s0,80(sp)
    80004baa:	e4a6                	sd	s1,72(sp)
    80004bac:	e0ca                	sd	s2,64(sp)
    80004bae:	fc4e                	sd	s3,56(sp)
    80004bb0:	f852                	sd	s4,48(sp)
    80004bb2:	f456                	sd	s5,40(sp)
    80004bb4:	f05a                	sd	s6,32(sp)
    80004bb6:	ec5e                	sd	s7,24(sp)
    80004bb8:	e862                	sd	s8,16(sp)
    80004bba:	1080                	addi	s0,sp,96
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	8aae                	mv	s5,a1
    80004bc0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	f3a080e7          	jalr	-198(ra) # 80001afc <myproc>
    80004bca:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	13e080e7          	jalr	318(ra) # 80000d0c <acquire>
  while(i < n){
    80004bd6:	0b405663          	blez	s4,80004c82 <pipewrite+0xde>
  int i = 0;
    80004bda:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bdc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bde:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004be2:	21c48b93          	addi	s7,s1,540
    80004be6:	a089                	j	80004c28 <pipewrite+0x84>
      release(&pi->lock);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	1d6080e7          	jalr	470(ra) # 80000dc0 <release>
      return -1;
    80004bf2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bf4:	854a                	mv	a0,s2
    80004bf6:	60e6                	ld	ra,88(sp)
    80004bf8:	6446                	ld	s0,80(sp)
    80004bfa:	64a6                	ld	s1,72(sp)
    80004bfc:	6906                	ld	s2,64(sp)
    80004bfe:	79e2                	ld	s3,56(sp)
    80004c00:	7a42                	ld	s4,48(sp)
    80004c02:	7aa2                	ld	s5,40(sp)
    80004c04:	7b02                	ld	s6,32(sp)
    80004c06:	6be2                	ld	s7,24(sp)
    80004c08:	6c42                	ld	s8,16(sp)
    80004c0a:	6125                	addi	sp,sp,96
    80004c0c:	8082                	ret
      wakeup(&pi->nread);
    80004c0e:	8562                	mv	a0,s8
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	5f8080e7          	jalr	1528(ra) # 80002208 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c18:	85a6                	mv	a1,s1
    80004c1a:	855e                	mv	a0,s7
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	588080e7          	jalr	1416(ra) # 800021a4 <sleep>
  while(i < n){
    80004c24:	07495063          	bge	s2,s4,80004c84 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c28:	2204a783          	lw	a5,544(s1)
    80004c2c:	dfd5                	beqz	a5,80004be8 <pipewrite+0x44>
    80004c2e:	854e                	mv	a0,s3
    80004c30:	ffffe097          	auipc	ra,0xffffe
    80004c34:	81c080e7          	jalr	-2020(ra) # 8000244c <killed>
    80004c38:	f945                	bnez	a0,80004be8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c3a:	2184a783          	lw	a5,536(s1)
    80004c3e:	21c4a703          	lw	a4,540(s1)
    80004c42:	2007879b          	addiw	a5,a5,512
    80004c46:	fcf704e3          	beq	a4,a5,80004c0e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c4a:	4685                	li	a3,1
    80004c4c:	01590633          	add	a2,s2,s5
    80004c50:	faf40593          	addi	a1,s0,-81
    80004c54:	0509b503          	ld	a0,80(s3)
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	bf0080e7          	jalr	-1040(ra) # 80001848 <copyin>
    80004c60:	03650263          	beq	a0,s6,80004c84 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c64:	21c4a783          	lw	a5,540(s1)
    80004c68:	0017871b          	addiw	a4,a5,1
    80004c6c:	20e4ae23          	sw	a4,540(s1)
    80004c70:	1ff7f793          	andi	a5,a5,511
    80004c74:	97a6                	add	a5,a5,s1
    80004c76:	faf44703          	lbu	a4,-81(s0)
    80004c7a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c7e:	2905                	addiw	s2,s2,1
    80004c80:	b755                	j	80004c24 <pipewrite+0x80>
  int i = 0;
    80004c82:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c84:	21848513          	addi	a0,s1,536
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	580080e7          	jalr	1408(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004c90:	8526                	mv	a0,s1
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	12e080e7          	jalr	302(ra) # 80000dc0 <release>
  return i;
    80004c9a:	bfa9                	j	80004bf4 <pipewrite+0x50>

0000000080004c9c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c9c:	715d                	addi	sp,sp,-80
    80004c9e:	e486                	sd	ra,72(sp)
    80004ca0:	e0a2                	sd	s0,64(sp)
    80004ca2:	fc26                	sd	s1,56(sp)
    80004ca4:	f84a                	sd	s2,48(sp)
    80004ca6:	f44e                	sd	s3,40(sp)
    80004ca8:	f052                	sd	s4,32(sp)
    80004caa:	ec56                	sd	s5,24(sp)
    80004cac:	e85a                	sd	s6,16(sp)
    80004cae:	0880                	addi	s0,sp,80
    80004cb0:	84aa                	mv	s1,a0
    80004cb2:	892e                	mv	s2,a1
    80004cb4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	e46080e7          	jalr	-442(ra) # 80001afc <myproc>
    80004cbe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	04a080e7          	jalr	74(ra) # 80000d0c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cca:	2184a703          	lw	a4,536(s1)
    80004cce:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cd2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd6:	02f71763          	bne	a4,a5,80004d04 <piperead+0x68>
    80004cda:	2244a783          	lw	a5,548(s1)
    80004cde:	c39d                	beqz	a5,80004d04 <piperead+0x68>
    if(killed(pr)){
    80004ce0:	8552                	mv	a0,s4
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	76a080e7          	jalr	1898(ra) # 8000244c <killed>
    80004cea:	e949                	bnez	a0,80004d7c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cec:	85a6                	mv	a1,s1
    80004cee:	854e                	mv	a0,s3
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	4b4080e7          	jalr	1204(ra) # 800021a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf8:	2184a703          	lw	a4,536(s1)
    80004cfc:	21c4a783          	lw	a5,540(s1)
    80004d00:	fcf70de3          	beq	a4,a5,80004cda <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d04:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d06:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d08:	05505463          	blez	s5,80004d50 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004d0c:	2184a783          	lw	a5,536(s1)
    80004d10:	21c4a703          	lw	a4,540(s1)
    80004d14:	02f70e63          	beq	a4,a5,80004d50 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d18:	0017871b          	addiw	a4,a5,1
    80004d1c:	20e4ac23          	sw	a4,536(s1)
    80004d20:	1ff7f793          	andi	a5,a5,511
    80004d24:	97a6                	add	a5,a5,s1
    80004d26:	0187c783          	lbu	a5,24(a5)
    80004d2a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d2e:	4685                	li	a3,1
    80004d30:	fbf40613          	addi	a2,s0,-65
    80004d34:	85ca                	mv	a1,s2
    80004d36:	050a3503          	ld	a0,80(s4)
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	a4e080e7          	jalr	-1458(ra) # 80001788 <copyout>
    80004d42:	01650763          	beq	a0,s6,80004d50 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d46:	2985                	addiw	s3,s3,1
    80004d48:	0905                	addi	s2,s2,1
    80004d4a:	fd3a91e3          	bne	s5,s3,80004d0c <piperead+0x70>
    80004d4e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d50:	21c48513          	addi	a0,s1,540
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	4b4080e7          	jalr	1204(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	ffffc097          	auipc	ra,0xffffc
    80004d62:	062080e7          	jalr	98(ra) # 80000dc0 <release>
  return i;
}
    80004d66:	854e                	mv	a0,s3
    80004d68:	60a6                	ld	ra,72(sp)
    80004d6a:	6406                	ld	s0,64(sp)
    80004d6c:	74e2                	ld	s1,56(sp)
    80004d6e:	7942                	ld	s2,48(sp)
    80004d70:	79a2                	ld	s3,40(sp)
    80004d72:	7a02                	ld	s4,32(sp)
    80004d74:	6ae2                	ld	s5,24(sp)
    80004d76:	6b42                	ld	s6,16(sp)
    80004d78:	6161                	addi	sp,sp,80
    80004d7a:	8082                	ret
      release(&pi->lock);
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	042080e7          	jalr	66(ra) # 80000dc0 <release>
      return -1;
    80004d86:	59fd                	li	s3,-1
    80004d88:	bff9                	j	80004d66 <piperead+0xca>

0000000080004d8a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d8a:	1141                	addi	sp,sp,-16
    80004d8c:	e422                	sd	s0,8(sp)
    80004d8e:	0800                	addi	s0,sp,16
    80004d90:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d92:	8905                	andi	a0,a0,1
    80004d94:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004d96:	8b89                	andi	a5,a5,2
    80004d98:	c399                	beqz	a5,80004d9e <flags2perm+0x14>
      perm |= PTE_W;
    80004d9a:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d9e:	6422                	ld	s0,8(sp)
    80004da0:	0141                	addi	sp,sp,16
    80004da2:	8082                	ret

0000000080004da4 <exec>:

int
exec(char *path, char **argv)
{
    80004da4:	de010113          	addi	sp,sp,-544
    80004da8:	20113c23          	sd	ra,536(sp)
    80004dac:	20813823          	sd	s0,528(sp)
    80004db0:	20913423          	sd	s1,520(sp)
    80004db4:	21213023          	sd	s2,512(sp)
    80004db8:	ffce                	sd	s3,504(sp)
    80004dba:	fbd2                	sd	s4,496(sp)
    80004dbc:	f7d6                	sd	s5,488(sp)
    80004dbe:	f3da                	sd	s6,480(sp)
    80004dc0:	efde                	sd	s7,472(sp)
    80004dc2:	ebe2                	sd	s8,464(sp)
    80004dc4:	e7e6                	sd	s9,456(sp)
    80004dc6:	e3ea                	sd	s10,448(sp)
    80004dc8:	ff6e                	sd	s11,440(sp)
    80004dca:	1400                	addi	s0,sp,544
    80004dcc:	892a                	mv	s2,a0
    80004dce:	dea43423          	sd	a0,-536(s0)
    80004dd2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	d26080e7          	jalr	-730(ra) # 80001afc <myproc>
    80004dde:	84aa                	mv	s1,a0

  begin_op();
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	482080e7          	jalr	1154(ra) # 80004262 <begin_op>

  if((ip = namei(path)) == 0){
    80004de8:	854a                	mv	a0,s2
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	258080e7          	jalr	600(ra) # 80004042 <namei>
    80004df2:	c93d                	beqz	a0,80004e68 <exec+0xc4>
    80004df4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	aa0080e7          	jalr	-1376(ra) # 80003896 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dfe:	04000713          	li	a4,64
    80004e02:	4681                	li	a3,0
    80004e04:	e5040613          	addi	a2,s0,-432
    80004e08:	4581                	li	a1,0
    80004e0a:	8556                	mv	a0,s5
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	d3e080e7          	jalr	-706(ra) # 80003b4a <readi>
    80004e14:	04000793          	li	a5,64
    80004e18:	00f51a63          	bne	a0,a5,80004e2c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e1c:	e5042703          	lw	a4,-432(s0)
    80004e20:	464c47b7          	lui	a5,0x464c4
    80004e24:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e28:	04f70663          	beq	a4,a5,80004e74 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e2c:	8556                	mv	a0,s5
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	cca080e7          	jalr	-822(ra) # 80003af8 <iunlockput>
    end_op();
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	4aa080e7          	jalr	1194(ra) # 800042e0 <end_op>
  }
  return -1;
    80004e3e:	557d                	li	a0,-1
}
    80004e40:	21813083          	ld	ra,536(sp)
    80004e44:	21013403          	ld	s0,528(sp)
    80004e48:	20813483          	ld	s1,520(sp)
    80004e4c:	20013903          	ld	s2,512(sp)
    80004e50:	79fe                	ld	s3,504(sp)
    80004e52:	7a5e                	ld	s4,496(sp)
    80004e54:	7abe                	ld	s5,488(sp)
    80004e56:	7b1e                	ld	s6,480(sp)
    80004e58:	6bfe                	ld	s7,472(sp)
    80004e5a:	6c5e                	ld	s8,464(sp)
    80004e5c:	6cbe                	ld	s9,456(sp)
    80004e5e:	6d1e                	ld	s10,448(sp)
    80004e60:	7dfa                	ld	s11,440(sp)
    80004e62:	22010113          	addi	sp,sp,544
    80004e66:	8082                	ret
    end_op();
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	478080e7          	jalr	1144(ra) # 800042e0 <end_op>
    return -1;
    80004e70:	557d                	li	a0,-1
    80004e72:	b7f9                	j	80004e40 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffd097          	auipc	ra,0xffffd
    80004e7a:	d4a080e7          	jalr	-694(ra) # 80001bc0 <proc_pagetable>
    80004e7e:	8b2a                	mv	s6,a0
    80004e80:	d555                	beqz	a0,80004e2c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e82:	e7042783          	lw	a5,-400(s0)
    80004e86:	e8845703          	lhu	a4,-376(s0)
    80004e8a:	c735                	beqz	a4,80004ef6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e8c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e8e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e92:	6a05                	lui	s4,0x1
    80004e94:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e98:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e9c:	6d85                	lui	s11,0x1
    80004e9e:	7d7d                	lui	s10,0xfffff
    80004ea0:	ac3d                	j	800050de <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea2:	00004517          	auipc	a0,0x4
    80004ea6:	87e50513          	addi	a0,a0,-1922 # 80008720 <syscalls+0x298>
    80004eaa:	ffffb097          	auipc	ra,0xffffb
    80004eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb2:	874a                	mv	a4,s2
    80004eb4:	009c86bb          	addw	a3,s9,s1
    80004eb8:	4581                	li	a1,0
    80004eba:	8556                	mv	a0,s5
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	c8e080e7          	jalr	-882(ra) # 80003b4a <readi>
    80004ec4:	2501                	sext.w	a0,a0
    80004ec6:	1aa91963          	bne	s2,a0,80005078 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004eca:	009d84bb          	addw	s1,s11,s1
    80004ece:	013d09bb          	addw	s3,s10,s3
    80004ed2:	1f74f663          	bgeu	s1,s7,800050be <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004ed6:	02049593          	slli	a1,s1,0x20
    80004eda:	9181                	srli	a1,a1,0x20
    80004edc:	95e2                	add	a1,a1,s8
    80004ede:	855a                	mv	a0,s6
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	2b2080e7          	jalr	690(ra) # 80001192 <walkaddr>
    80004ee8:	862a                	mv	a2,a0
    if(pa == 0)
    80004eea:	dd45                	beqz	a0,80004ea2 <exec+0xfe>
      n = PGSIZE;
    80004eec:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004eee:	fd49f2e3          	bgeu	s3,s4,80004eb2 <exec+0x10e>
      n = sz - i;
    80004ef2:	894e                	mv	s2,s3
    80004ef4:	bf7d                	j	80004eb2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ef6:	4901                	li	s2,0
  iunlockput(ip);
    80004ef8:	8556                	mv	a0,s5
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	bfe080e7          	jalr	-1026(ra) # 80003af8 <iunlockput>
  end_op();
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	3de080e7          	jalr	990(ra) # 800042e0 <end_op>
  p = myproc();
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	bf2080e7          	jalr	-1038(ra) # 80001afc <myproc>
    80004f12:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f14:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f18:	6785                	lui	a5,0x1
    80004f1a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f1c:	97ca                	add	a5,a5,s2
    80004f1e:	777d                	lui	a4,0xfffff
    80004f20:	8ff9                	and	a5,a5,a4
    80004f22:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f26:	4691                	li	a3,4
    80004f28:	6609                	lui	a2,0x2
    80004f2a:	963e                	add	a2,a2,a5
    80004f2c:	85be                	mv	a1,a5
    80004f2e:	855a                	mv	a0,s6
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	616080e7          	jalr	1558(ra) # 80001546 <uvmalloc>
    80004f38:	8c2a                	mv	s8,a0
  ip = 0;
    80004f3a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f3c:	12050e63          	beqz	a0,80005078 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f40:	75f9                	lui	a1,0xffffe
    80004f42:	95aa                	add	a1,a1,a0
    80004f44:	855a                	mv	a0,s6
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	810080e7          	jalr	-2032(ra) # 80001756 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f4e:	7afd                	lui	s5,0xfffff
    80004f50:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f52:	df043783          	ld	a5,-528(s0)
    80004f56:	6388                	ld	a0,0(a5)
    80004f58:	c925                	beqz	a0,80004fc8 <exec+0x224>
    80004f5a:	e9040993          	addi	s3,s0,-368
    80004f5e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f62:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f64:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	01e080e7          	jalr	30(ra) # 80000f84 <strlen>
    80004f6e:	0015079b          	addiw	a5,a0,1
    80004f72:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f76:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f7a:	13596663          	bltu	s2,s5,800050a6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f7e:	df043d83          	ld	s11,-528(s0)
    80004f82:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f86:	8552                	mv	a0,s4
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	ffc080e7          	jalr	-4(ra) # 80000f84 <strlen>
    80004f90:	0015069b          	addiw	a3,a0,1
    80004f94:	8652                	mv	a2,s4
    80004f96:	85ca                	mv	a1,s2
    80004f98:	855a                	mv	a0,s6
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	7ee080e7          	jalr	2030(ra) # 80001788 <copyout>
    80004fa2:	10054663          	bltz	a0,800050ae <exec+0x30a>
    ustack[argc] = sp;
    80004fa6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004faa:	0485                	addi	s1,s1,1
    80004fac:	008d8793          	addi	a5,s11,8
    80004fb0:	def43823          	sd	a5,-528(s0)
    80004fb4:	008db503          	ld	a0,8(s11)
    80004fb8:	c911                	beqz	a0,80004fcc <exec+0x228>
    if(argc >= MAXARG)
    80004fba:	09a1                	addi	s3,s3,8
    80004fbc:	fb3c95e3          	bne	s9,s3,80004f66 <exec+0x1c2>
  sz = sz1;
    80004fc0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc4:	4a81                	li	s5,0
    80004fc6:	a84d                	j	80005078 <exec+0x2d4>
  sp = sz;
    80004fc8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fcc:	00349793          	slli	a5,s1,0x3
    80004fd0:	f9078793          	addi	a5,a5,-112
    80004fd4:	97a2                	add	a5,a5,s0
    80004fd6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004fda:	00148693          	addi	a3,s1,1
    80004fde:	068e                	slli	a3,a3,0x3
    80004fe0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fe4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fe8:	01597663          	bgeu	s2,s5,80004ff4 <exec+0x250>
  sz = sz1;
    80004fec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ff0:	4a81                	li	s5,0
    80004ff2:	a059                	j	80005078 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ff4:	e9040613          	addi	a2,s0,-368
    80004ff8:	85ca                	mv	a1,s2
    80004ffa:	855a                	mv	a0,s6
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	78c080e7          	jalr	1932(ra) # 80001788 <copyout>
    80005004:	0a054963          	bltz	a0,800050b6 <exec+0x312>
  p->trapframe->a1 = sp;
    80005008:	058bb783          	ld	a5,88(s7)
    8000500c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005010:	de843783          	ld	a5,-536(s0)
    80005014:	0007c703          	lbu	a4,0(a5)
    80005018:	cf11                	beqz	a4,80005034 <exec+0x290>
    8000501a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000501c:	02f00693          	li	a3,47
    80005020:	a039                	j	8000502e <exec+0x28a>
      last = s+1;
    80005022:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005026:	0785                	addi	a5,a5,1
    80005028:	fff7c703          	lbu	a4,-1(a5)
    8000502c:	c701                	beqz	a4,80005034 <exec+0x290>
    if(*s == '/')
    8000502e:	fed71ce3          	bne	a4,a3,80005026 <exec+0x282>
    80005032:	bfc5                	j	80005022 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005034:	4641                	li	a2,16
    80005036:	de843583          	ld	a1,-536(s0)
    8000503a:	158b8513          	addi	a0,s7,344
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	f14080e7          	jalr	-236(ra) # 80000f52 <safestrcpy>
  oldpagetable = p->pagetable;
    80005046:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000504a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000504e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005052:	058bb783          	ld	a5,88(s7)
    80005056:	e6843703          	ld	a4,-408(s0)
    8000505a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000505c:	058bb783          	ld	a5,88(s7)
    80005060:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005064:	85ea                	mv	a1,s10
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	bf6080e7          	jalr	-1034(ra) # 80001c5c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000506e:	0004851b          	sext.w	a0,s1
    80005072:	b3f9                	j	80004e40 <exec+0x9c>
    80005074:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005078:	df843583          	ld	a1,-520(s0)
    8000507c:	855a                	mv	a0,s6
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	bde080e7          	jalr	-1058(ra) # 80001c5c <proc_freepagetable>
  if(ip){
    80005086:	da0a93e3          	bnez	s5,80004e2c <exec+0x88>
  return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	bb55                	j	80004e40 <exec+0x9c>
    8000508e:	df243c23          	sd	s2,-520(s0)
    80005092:	b7dd                	j	80005078 <exec+0x2d4>
    80005094:	df243c23          	sd	s2,-520(s0)
    80005098:	b7c5                	j	80005078 <exec+0x2d4>
    8000509a:	df243c23          	sd	s2,-520(s0)
    8000509e:	bfe9                	j	80005078 <exec+0x2d4>
    800050a0:	df243c23          	sd	s2,-520(s0)
    800050a4:	bfd1                	j	80005078 <exec+0x2d4>
  sz = sz1;
    800050a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050aa:	4a81                	li	s5,0
    800050ac:	b7f1                	j	80005078 <exec+0x2d4>
  sz = sz1;
    800050ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b2:	4a81                	li	s5,0
    800050b4:	b7d1                	j	80005078 <exec+0x2d4>
  sz = sz1;
    800050b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ba:	4a81                	li	s5,0
    800050bc:	bf75                	j	80005078 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050be:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c2:	e0843783          	ld	a5,-504(s0)
    800050c6:	0017869b          	addiw	a3,a5,1
    800050ca:	e0d43423          	sd	a3,-504(s0)
    800050ce:	e0043783          	ld	a5,-512(s0)
    800050d2:	0387879b          	addiw	a5,a5,56
    800050d6:	e8845703          	lhu	a4,-376(s0)
    800050da:	e0e6dfe3          	bge	a3,a4,80004ef8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050de:	2781                	sext.w	a5,a5
    800050e0:	e0f43023          	sd	a5,-512(s0)
    800050e4:	03800713          	li	a4,56
    800050e8:	86be                	mv	a3,a5
    800050ea:	e1840613          	addi	a2,s0,-488
    800050ee:	4581                	li	a1,0
    800050f0:	8556                	mv	a0,s5
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	a58080e7          	jalr	-1448(ra) # 80003b4a <readi>
    800050fa:	03800793          	li	a5,56
    800050fe:	f6f51be3          	bne	a0,a5,80005074 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005102:	e1842783          	lw	a5,-488(s0)
    80005106:	4705                	li	a4,1
    80005108:	fae79de3          	bne	a5,a4,800050c2 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000510c:	e4043483          	ld	s1,-448(s0)
    80005110:	e3843783          	ld	a5,-456(s0)
    80005114:	f6f4ede3          	bltu	s1,a5,8000508e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005118:	e2843783          	ld	a5,-472(s0)
    8000511c:	94be                	add	s1,s1,a5
    8000511e:	f6f4ebe3          	bltu	s1,a5,80005094 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005122:	de043703          	ld	a4,-544(s0)
    80005126:	8ff9                	and	a5,a5,a4
    80005128:	fbad                	bnez	a5,8000509a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000512a:	e1c42503          	lw	a0,-484(s0)
    8000512e:	00000097          	auipc	ra,0x0
    80005132:	c5c080e7          	jalr	-932(ra) # 80004d8a <flags2perm>
    80005136:	86aa                	mv	a3,a0
    80005138:	8626                	mv	a2,s1
    8000513a:	85ca                	mv	a1,s2
    8000513c:	855a                	mv	a0,s6
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	408080e7          	jalr	1032(ra) # 80001546 <uvmalloc>
    80005146:	dea43c23          	sd	a0,-520(s0)
    8000514a:	d939                	beqz	a0,800050a0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000514c:	e2843c03          	ld	s8,-472(s0)
    80005150:	e2042c83          	lw	s9,-480(s0)
    80005154:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005158:	f60b83e3          	beqz	s7,800050be <exec+0x31a>
    8000515c:	89de                	mv	s3,s7
    8000515e:	4481                	li	s1,0
    80005160:	bb9d                	j	80004ed6 <exec+0x132>

0000000080005162 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005162:	7179                	addi	sp,sp,-48
    80005164:	f406                	sd	ra,40(sp)
    80005166:	f022                	sd	s0,32(sp)
    80005168:	ec26                	sd	s1,24(sp)
    8000516a:	e84a                	sd	s2,16(sp)
    8000516c:	1800                	addi	s0,sp,48
    8000516e:	892e                	mv	s2,a1
    80005170:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005172:	fdc40593          	addi	a1,s0,-36
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	b42080e7          	jalr	-1214(ra) # 80002cb8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000517e:	fdc42703          	lw	a4,-36(s0)
    80005182:	47bd                	li	a5,15
    80005184:	02e7eb63          	bltu	a5,a4,800051ba <argfd+0x58>
    80005188:	ffffd097          	auipc	ra,0xffffd
    8000518c:	974080e7          	jalr	-1676(ra) # 80001afc <myproc>
    80005190:	fdc42703          	lw	a4,-36(s0)
    80005194:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbba6a>
    80005198:	078e                	slli	a5,a5,0x3
    8000519a:	953e                	add	a0,a0,a5
    8000519c:	611c                	ld	a5,0(a0)
    8000519e:	c385                	beqz	a5,800051be <argfd+0x5c>
    return -1;
  if(pfd)
    800051a0:	00090463          	beqz	s2,800051a8 <argfd+0x46>
    *pfd = fd;
    800051a4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a8:	4501                	li	a0,0
  if(pf)
    800051aa:	c091                	beqz	s1,800051ae <argfd+0x4c>
    *pf = f;
    800051ac:	e09c                	sd	a5,0(s1)
}
    800051ae:	70a2                	ld	ra,40(sp)
    800051b0:	7402                	ld	s0,32(sp)
    800051b2:	64e2                	ld	s1,24(sp)
    800051b4:	6942                	ld	s2,16(sp)
    800051b6:	6145                	addi	sp,sp,48
    800051b8:	8082                	ret
    return -1;
    800051ba:	557d                	li	a0,-1
    800051bc:	bfcd                	j	800051ae <argfd+0x4c>
    800051be:	557d                	li	a0,-1
    800051c0:	b7fd                	j	800051ae <argfd+0x4c>

00000000800051c2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c2:	1101                	addi	sp,sp,-32
    800051c4:	ec06                	sd	ra,24(sp)
    800051c6:	e822                	sd	s0,16(sp)
    800051c8:	e426                	sd	s1,8(sp)
    800051ca:	1000                	addi	s0,sp,32
    800051cc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051ce:	ffffd097          	auipc	ra,0xffffd
    800051d2:	92e080e7          	jalr	-1746(ra) # 80001afc <myproc>
    800051d6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051d8:	0d050793          	addi	a5,a0,208
    800051dc:	4501                	li	a0,0
    800051de:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051e0:	6398                	ld	a4,0(a5)
    800051e2:	cb19                	beqz	a4,800051f8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e4:	2505                	addiw	a0,a0,1
    800051e6:	07a1                	addi	a5,a5,8
    800051e8:	fed51ce3          	bne	a0,a3,800051e0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ec:	557d                	li	a0,-1
}
    800051ee:	60e2                	ld	ra,24(sp)
    800051f0:	6442                	ld	s0,16(sp)
    800051f2:	64a2                	ld	s1,8(sp)
    800051f4:	6105                	addi	sp,sp,32
    800051f6:	8082                	ret
      p->ofile[fd] = f;
    800051f8:	01a50793          	addi	a5,a0,26
    800051fc:	078e                	slli	a5,a5,0x3
    800051fe:	963e                	add	a2,a2,a5
    80005200:	e204                	sd	s1,0(a2)
      return fd;
    80005202:	b7f5                	j	800051ee <fdalloc+0x2c>

0000000080005204 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005204:	715d                	addi	sp,sp,-80
    80005206:	e486                	sd	ra,72(sp)
    80005208:	e0a2                	sd	s0,64(sp)
    8000520a:	fc26                	sd	s1,56(sp)
    8000520c:	f84a                	sd	s2,48(sp)
    8000520e:	f44e                	sd	s3,40(sp)
    80005210:	f052                	sd	s4,32(sp)
    80005212:	ec56                	sd	s5,24(sp)
    80005214:	e85a                	sd	s6,16(sp)
    80005216:	0880                	addi	s0,sp,80
    80005218:	8b2e                	mv	s6,a1
    8000521a:	89b2                	mv	s3,a2
    8000521c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521e:	fb040593          	addi	a1,s0,-80
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	e3e080e7          	jalr	-450(ra) # 80004060 <nameiparent>
    8000522a:	84aa                	mv	s1,a0
    8000522c:	14050f63          	beqz	a0,8000538a <create+0x186>
    return 0;

  ilock(dp);
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	666080e7          	jalr	1638(ra) # 80003896 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005238:	4601                	li	a2,0
    8000523a:	fb040593          	addi	a1,s0,-80
    8000523e:	8526                	mv	a0,s1
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	b3a080e7          	jalr	-1222(ra) # 80003d7a <dirlookup>
    80005248:	8aaa                	mv	s5,a0
    8000524a:	c931                	beqz	a0,8000529e <create+0x9a>
    iunlockput(dp);
    8000524c:	8526                	mv	a0,s1
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	8aa080e7          	jalr	-1878(ra) # 80003af8 <iunlockput>
    ilock(ip);
    80005256:	8556                	mv	a0,s5
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	63e080e7          	jalr	1598(ra) # 80003896 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005260:	000b059b          	sext.w	a1,s6
    80005264:	4789                	li	a5,2
    80005266:	02f59563          	bne	a1,a5,80005290 <create+0x8c>
    8000526a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbba94>
    8000526e:	37f9                	addiw	a5,a5,-2
    80005270:	17c2                	slli	a5,a5,0x30
    80005272:	93c1                	srli	a5,a5,0x30
    80005274:	4705                	li	a4,1
    80005276:	00f76d63          	bltu	a4,a5,80005290 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000527a:	8556                	mv	a0,s5
    8000527c:	60a6                	ld	ra,72(sp)
    8000527e:	6406                	ld	s0,64(sp)
    80005280:	74e2                	ld	s1,56(sp)
    80005282:	7942                	ld	s2,48(sp)
    80005284:	79a2                	ld	s3,40(sp)
    80005286:	7a02                	ld	s4,32(sp)
    80005288:	6ae2                	ld	s5,24(sp)
    8000528a:	6b42                	ld	s6,16(sp)
    8000528c:	6161                	addi	sp,sp,80
    8000528e:	8082                	ret
    iunlockput(ip);
    80005290:	8556                	mv	a0,s5
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	866080e7          	jalr	-1946(ra) # 80003af8 <iunlockput>
    return 0;
    8000529a:	4a81                	li	s5,0
    8000529c:	bff9                	j	8000527a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000529e:	85da                	mv	a1,s6
    800052a0:	4088                	lw	a0,0(s1)
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	456080e7          	jalr	1110(ra) # 800036f8 <ialloc>
    800052aa:	8a2a                	mv	s4,a0
    800052ac:	c539                	beqz	a0,800052fa <create+0xf6>
  ilock(ip);
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	5e8080e7          	jalr	1512(ra) # 80003896 <ilock>
  ip->major = major;
    800052b6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052ba:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052be:	4905                	li	s2,1
    800052c0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800052c4:	8552                	mv	a0,s4
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	504080e7          	jalr	1284(ra) # 800037ca <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ce:	000b059b          	sext.w	a1,s6
    800052d2:	03258b63          	beq	a1,s2,80005308 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d6:	004a2603          	lw	a2,4(s4)
    800052da:	fb040593          	addi	a1,s0,-80
    800052de:	8526                	mv	a0,s1
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	cb0080e7          	jalr	-848(ra) # 80003f90 <dirlink>
    800052e8:	06054f63          	bltz	a0,80005366 <create+0x162>
  iunlockput(dp);
    800052ec:	8526                	mv	a0,s1
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	80a080e7          	jalr	-2038(ra) # 80003af8 <iunlockput>
  return ip;
    800052f6:	8ad2                	mv	s5,s4
    800052f8:	b749                	j	8000527a <create+0x76>
    iunlockput(dp);
    800052fa:	8526                	mv	a0,s1
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	7fc080e7          	jalr	2044(ra) # 80003af8 <iunlockput>
    return 0;
    80005304:	8ad2                	mv	s5,s4
    80005306:	bf95                	j	8000527a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005308:	004a2603          	lw	a2,4(s4)
    8000530c:	00003597          	auipc	a1,0x3
    80005310:	43458593          	addi	a1,a1,1076 # 80008740 <syscalls+0x2b8>
    80005314:	8552                	mv	a0,s4
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	c7a080e7          	jalr	-902(ra) # 80003f90 <dirlink>
    8000531e:	04054463          	bltz	a0,80005366 <create+0x162>
    80005322:	40d0                	lw	a2,4(s1)
    80005324:	00003597          	auipc	a1,0x3
    80005328:	42458593          	addi	a1,a1,1060 # 80008748 <syscalls+0x2c0>
    8000532c:	8552                	mv	a0,s4
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	c62080e7          	jalr	-926(ra) # 80003f90 <dirlink>
    80005336:	02054863          	bltz	a0,80005366 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000533a:	004a2603          	lw	a2,4(s4)
    8000533e:	fb040593          	addi	a1,s0,-80
    80005342:	8526                	mv	a0,s1
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	c4c080e7          	jalr	-948(ra) # 80003f90 <dirlink>
    8000534c:	00054d63          	bltz	a0,80005366 <create+0x162>
    dp->nlink++;  // for ".."
    80005350:	04a4d783          	lhu	a5,74(s1)
    80005354:	2785                	addiw	a5,a5,1
    80005356:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	46e080e7          	jalr	1134(ra) # 800037ca <iupdate>
    80005364:	b761                	j	800052ec <create+0xe8>
  ip->nlink = 0;
    80005366:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000536a:	8552                	mv	a0,s4
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	45e080e7          	jalr	1118(ra) # 800037ca <iupdate>
  iunlockput(ip);
    80005374:	8552                	mv	a0,s4
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	782080e7          	jalr	1922(ra) # 80003af8 <iunlockput>
  iunlockput(dp);
    8000537e:	8526                	mv	a0,s1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	778080e7          	jalr	1912(ra) # 80003af8 <iunlockput>
  return 0;
    80005388:	bdcd                	j	8000527a <create+0x76>
    return 0;
    8000538a:	8aaa                	mv	s5,a0
    8000538c:	b5fd                	j	8000527a <create+0x76>

000000008000538e <sys_dup>:
{
    8000538e:	7179                	addi	sp,sp,-48
    80005390:	f406                	sd	ra,40(sp)
    80005392:	f022                	sd	s0,32(sp)
    80005394:	ec26                	sd	s1,24(sp)
    80005396:	e84a                	sd	s2,16(sp)
    80005398:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000539a:	fd840613          	addi	a2,s0,-40
    8000539e:	4581                	li	a1,0
    800053a0:	4501                	li	a0,0
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	dc0080e7          	jalr	-576(ra) # 80005162 <argfd>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ac:	02054363          	bltz	a0,800053d2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800053b0:	fd843903          	ld	s2,-40(s0)
    800053b4:	854a                	mv	a0,s2
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	e0c080e7          	jalr	-500(ra) # 800051c2 <fdalloc>
    800053be:	84aa                	mv	s1,a0
    return -1;
    800053c0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053c2:	00054863          	bltz	a0,800053d2 <sys_dup+0x44>
  filedup(f);
    800053c6:	854a                	mv	a0,s2
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	310080e7          	jalr	784(ra) # 800046d8 <filedup>
  return fd;
    800053d0:	87a6                	mv	a5,s1
}
    800053d2:	853e                	mv	a0,a5
    800053d4:	70a2                	ld	ra,40(sp)
    800053d6:	7402                	ld	s0,32(sp)
    800053d8:	64e2                	ld	s1,24(sp)
    800053da:	6942                	ld	s2,16(sp)
    800053dc:	6145                	addi	sp,sp,48
    800053de:	8082                	ret

00000000800053e0 <sys_read>:
{
    800053e0:	7179                	addi	sp,sp,-48
    800053e2:	f406                	sd	ra,40(sp)
    800053e4:	f022                	sd	s0,32(sp)
    800053e6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053e8:	fd840593          	addi	a1,s0,-40
    800053ec:	4505                	li	a0,1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	8ea080e7          	jalr	-1814(ra) # 80002cd8 <argaddr>
  argint(2, &n);
    800053f6:	fe440593          	addi	a1,s0,-28
    800053fa:	4509                	li	a0,2
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	8bc080e7          	jalr	-1860(ra) # 80002cb8 <argint>
  if(argfd(0, 0, &f) < 0)
    80005404:	fe840613          	addi	a2,s0,-24
    80005408:	4581                	li	a1,0
    8000540a:	4501                	li	a0,0
    8000540c:	00000097          	auipc	ra,0x0
    80005410:	d56080e7          	jalr	-682(ra) # 80005162 <argfd>
    80005414:	87aa                	mv	a5,a0
    return -1;
    80005416:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005418:	0007cc63          	bltz	a5,80005430 <sys_read+0x50>
  return fileread(f, p, n);
    8000541c:	fe442603          	lw	a2,-28(s0)
    80005420:	fd843583          	ld	a1,-40(s0)
    80005424:	fe843503          	ld	a0,-24(s0)
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	43c080e7          	jalr	1084(ra) # 80004864 <fileread>
}
    80005430:	70a2                	ld	ra,40(sp)
    80005432:	7402                	ld	s0,32(sp)
    80005434:	6145                	addi	sp,sp,48
    80005436:	8082                	ret

0000000080005438 <sys_write>:
{
    80005438:	7179                	addi	sp,sp,-48
    8000543a:	f406                	sd	ra,40(sp)
    8000543c:	f022                	sd	s0,32(sp)
    8000543e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005440:	fd840593          	addi	a1,s0,-40
    80005444:	4505                	li	a0,1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	892080e7          	jalr	-1902(ra) # 80002cd8 <argaddr>
  argint(2, &n);
    8000544e:	fe440593          	addi	a1,s0,-28
    80005452:	4509                	li	a0,2
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	864080e7          	jalr	-1948(ra) # 80002cb8 <argint>
  if(argfd(0, 0, &f) < 0)
    8000545c:	fe840613          	addi	a2,s0,-24
    80005460:	4581                	li	a1,0
    80005462:	4501                	li	a0,0
    80005464:	00000097          	auipc	ra,0x0
    80005468:	cfe080e7          	jalr	-770(ra) # 80005162 <argfd>
    8000546c:	87aa                	mv	a5,a0
    return -1;
    8000546e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005470:	0007cc63          	bltz	a5,80005488 <sys_write+0x50>
  return filewrite(f, p, n);
    80005474:	fe442603          	lw	a2,-28(s0)
    80005478:	fd843583          	ld	a1,-40(s0)
    8000547c:	fe843503          	ld	a0,-24(s0)
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	4a6080e7          	jalr	1190(ra) # 80004926 <filewrite>
}
    80005488:	70a2                	ld	ra,40(sp)
    8000548a:	7402                	ld	s0,32(sp)
    8000548c:	6145                	addi	sp,sp,48
    8000548e:	8082                	ret

0000000080005490 <sys_close>:
{
    80005490:	1101                	addi	sp,sp,-32
    80005492:	ec06                	sd	ra,24(sp)
    80005494:	e822                	sd	s0,16(sp)
    80005496:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005498:	fe040613          	addi	a2,s0,-32
    8000549c:	fec40593          	addi	a1,s0,-20
    800054a0:	4501                	li	a0,0
    800054a2:	00000097          	auipc	ra,0x0
    800054a6:	cc0080e7          	jalr	-832(ra) # 80005162 <argfd>
    return -1;
    800054aa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054ac:	02054463          	bltz	a0,800054d4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	64c080e7          	jalr	1612(ra) # 80001afc <myproc>
    800054b8:	fec42783          	lw	a5,-20(s0)
    800054bc:	07e9                	addi	a5,a5,26
    800054be:	078e                	slli	a5,a5,0x3
    800054c0:	953e                	add	a0,a0,a5
    800054c2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800054c6:	fe043503          	ld	a0,-32(s0)
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	260080e7          	jalr	608(ra) # 8000472a <fileclose>
  return 0;
    800054d2:	4781                	li	a5,0
}
    800054d4:	853e                	mv	a0,a5
    800054d6:	60e2                	ld	ra,24(sp)
    800054d8:	6442                	ld	s0,16(sp)
    800054da:	6105                	addi	sp,sp,32
    800054dc:	8082                	ret

00000000800054de <sys_fstat>:
{
    800054de:	1101                	addi	sp,sp,-32
    800054e0:	ec06                	sd	ra,24(sp)
    800054e2:	e822                	sd	s0,16(sp)
    800054e4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800054e6:	fe040593          	addi	a1,s0,-32
    800054ea:	4505                	li	a0,1
    800054ec:	ffffd097          	auipc	ra,0xffffd
    800054f0:	7ec080e7          	jalr	2028(ra) # 80002cd8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800054f4:	fe840613          	addi	a2,s0,-24
    800054f8:	4581                	li	a1,0
    800054fa:	4501                	li	a0,0
    800054fc:	00000097          	auipc	ra,0x0
    80005500:	c66080e7          	jalr	-922(ra) # 80005162 <argfd>
    80005504:	87aa                	mv	a5,a0
    return -1;
    80005506:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005508:	0007ca63          	bltz	a5,8000551c <sys_fstat+0x3e>
  return filestat(f, st);
    8000550c:	fe043583          	ld	a1,-32(s0)
    80005510:	fe843503          	ld	a0,-24(s0)
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	2de080e7          	jalr	734(ra) # 800047f2 <filestat>
}
    8000551c:	60e2                	ld	ra,24(sp)
    8000551e:	6442                	ld	s0,16(sp)
    80005520:	6105                	addi	sp,sp,32
    80005522:	8082                	ret

0000000080005524 <sys_link>:
{
    80005524:	7169                	addi	sp,sp,-304
    80005526:	f606                	sd	ra,296(sp)
    80005528:	f222                	sd	s0,288(sp)
    8000552a:	ee26                	sd	s1,280(sp)
    8000552c:	ea4a                	sd	s2,272(sp)
    8000552e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005530:	08000613          	li	a2,128
    80005534:	ed040593          	addi	a1,s0,-304
    80005538:	4501                	li	a0,0
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	7be080e7          	jalr	1982(ra) # 80002cf8 <argstr>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005544:	10054e63          	bltz	a0,80005660 <sys_link+0x13c>
    80005548:	08000613          	li	a2,128
    8000554c:	f5040593          	addi	a1,s0,-176
    80005550:	4505                	li	a0,1
    80005552:	ffffd097          	auipc	ra,0xffffd
    80005556:	7a6080e7          	jalr	1958(ra) # 80002cf8 <argstr>
    return -1;
    8000555a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000555c:	10054263          	bltz	a0,80005660 <sys_link+0x13c>
  begin_op();
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	d02080e7          	jalr	-766(ra) # 80004262 <begin_op>
  if((ip = namei(old)) == 0){
    80005568:	ed040513          	addi	a0,s0,-304
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	ad6080e7          	jalr	-1322(ra) # 80004042 <namei>
    80005574:	84aa                	mv	s1,a0
    80005576:	c551                	beqz	a0,80005602 <sys_link+0xde>
  ilock(ip);
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	31e080e7          	jalr	798(ra) # 80003896 <ilock>
  if(ip->type == T_DIR){
    80005580:	04449703          	lh	a4,68(s1)
    80005584:	4785                	li	a5,1
    80005586:	08f70463          	beq	a4,a5,8000560e <sys_link+0xea>
  ip->nlink++;
    8000558a:	04a4d783          	lhu	a5,74(s1)
    8000558e:	2785                	addiw	a5,a5,1
    80005590:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	234080e7          	jalr	564(ra) # 800037ca <iupdate>
  iunlock(ip);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	3b8080e7          	jalr	952(ra) # 80003958 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a8:	fd040593          	addi	a1,s0,-48
    800055ac:	f5040513          	addi	a0,s0,-176
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	ab0080e7          	jalr	-1360(ra) # 80004060 <nameiparent>
    800055b8:	892a                	mv	s2,a0
    800055ba:	c935                	beqz	a0,8000562e <sys_link+0x10a>
  ilock(dp);
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	2da080e7          	jalr	730(ra) # 80003896 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c4:	00092703          	lw	a4,0(s2)
    800055c8:	409c                	lw	a5,0(s1)
    800055ca:	04f71d63          	bne	a4,a5,80005624 <sys_link+0x100>
    800055ce:	40d0                	lw	a2,4(s1)
    800055d0:	fd040593          	addi	a1,s0,-48
    800055d4:	854a                	mv	a0,s2
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	9ba080e7          	jalr	-1606(ra) # 80003f90 <dirlink>
    800055de:	04054363          	bltz	a0,80005624 <sys_link+0x100>
  iunlockput(dp);
    800055e2:	854a                	mv	a0,s2
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	514080e7          	jalr	1300(ra) # 80003af8 <iunlockput>
  iput(ip);
    800055ec:	8526                	mv	a0,s1
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	462080e7          	jalr	1122(ra) # 80003a50 <iput>
  end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	cea080e7          	jalr	-790(ra) # 800042e0 <end_op>
  return 0;
    800055fe:	4781                	li	a5,0
    80005600:	a085                	j	80005660 <sys_link+0x13c>
    end_op();
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	cde080e7          	jalr	-802(ra) # 800042e0 <end_op>
    return -1;
    8000560a:	57fd                	li	a5,-1
    8000560c:	a891                	j	80005660 <sys_link+0x13c>
    iunlockput(ip);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	4e8080e7          	jalr	1256(ra) # 80003af8 <iunlockput>
    end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	cc8080e7          	jalr	-824(ra) # 800042e0 <end_op>
    return -1;
    80005620:	57fd                	li	a5,-1
    80005622:	a83d                	j	80005660 <sys_link+0x13c>
    iunlockput(dp);
    80005624:	854a                	mv	a0,s2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	4d2080e7          	jalr	1234(ra) # 80003af8 <iunlockput>
  ilock(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	266080e7          	jalr	614(ra) # 80003896 <ilock>
  ip->nlink--;
    80005638:	04a4d783          	lhu	a5,74(s1)
    8000563c:	37fd                	addiw	a5,a5,-1
    8000563e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	186080e7          	jalr	390(ra) # 800037ca <iupdate>
  iunlockput(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	4aa080e7          	jalr	1194(ra) # 80003af8 <iunlockput>
  end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	c8a080e7          	jalr	-886(ra) # 800042e0 <end_op>
  return -1;
    8000565e:	57fd                	li	a5,-1
}
    80005660:	853e                	mv	a0,a5
    80005662:	70b2                	ld	ra,296(sp)
    80005664:	7412                	ld	s0,288(sp)
    80005666:	64f2                	ld	s1,280(sp)
    80005668:	6952                	ld	s2,272(sp)
    8000566a:	6155                	addi	sp,sp,304
    8000566c:	8082                	ret

000000008000566e <sys_unlink>:
{
    8000566e:	7151                	addi	sp,sp,-240
    80005670:	f586                	sd	ra,232(sp)
    80005672:	f1a2                	sd	s0,224(sp)
    80005674:	eda6                	sd	s1,216(sp)
    80005676:	e9ca                	sd	s2,208(sp)
    80005678:	e5ce                	sd	s3,200(sp)
    8000567a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000567c:	08000613          	li	a2,128
    80005680:	f3040593          	addi	a1,s0,-208
    80005684:	4501                	li	a0,0
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	672080e7          	jalr	1650(ra) # 80002cf8 <argstr>
    8000568e:	18054163          	bltz	a0,80005810 <sys_unlink+0x1a2>
  begin_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	bd0080e7          	jalr	-1072(ra) # 80004262 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000569a:	fb040593          	addi	a1,s0,-80
    8000569e:	f3040513          	addi	a0,s0,-208
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	9be080e7          	jalr	-1602(ra) # 80004060 <nameiparent>
    800056aa:	84aa                	mv	s1,a0
    800056ac:	c979                	beqz	a0,80005782 <sys_unlink+0x114>
  ilock(dp);
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	1e8080e7          	jalr	488(ra) # 80003896 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b6:	00003597          	auipc	a1,0x3
    800056ba:	08a58593          	addi	a1,a1,138 # 80008740 <syscalls+0x2b8>
    800056be:	fb040513          	addi	a0,s0,-80
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	69e080e7          	jalr	1694(ra) # 80003d60 <namecmp>
    800056ca:	14050a63          	beqz	a0,8000581e <sys_unlink+0x1b0>
    800056ce:	00003597          	auipc	a1,0x3
    800056d2:	07a58593          	addi	a1,a1,122 # 80008748 <syscalls+0x2c0>
    800056d6:	fb040513          	addi	a0,s0,-80
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	686080e7          	jalr	1670(ra) # 80003d60 <namecmp>
    800056e2:	12050e63          	beqz	a0,8000581e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e6:	f2c40613          	addi	a2,s0,-212
    800056ea:	fb040593          	addi	a1,s0,-80
    800056ee:	8526                	mv	a0,s1
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	68a080e7          	jalr	1674(ra) # 80003d7a <dirlookup>
    800056f8:	892a                	mv	s2,a0
    800056fa:	12050263          	beqz	a0,8000581e <sys_unlink+0x1b0>
  ilock(ip);
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	198080e7          	jalr	408(ra) # 80003896 <ilock>
  if(ip->nlink < 1)
    80005706:	04a91783          	lh	a5,74(s2)
    8000570a:	08f05263          	blez	a5,8000578e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570e:	04491703          	lh	a4,68(s2)
    80005712:	4785                	li	a5,1
    80005714:	08f70563          	beq	a4,a5,8000579e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005718:	4641                	li	a2,16
    8000571a:	4581                	li	a1,0
    8000571c:	fc040513          	addi	a0,s0,-64
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	6e8080e7          	jalr	1768(ra) # 80000e08 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005728:	4741                	li	a4,16
    8000572a:	f2c42683          	lw	a3,-212(s0)
    8000572e:	fc040613          	addi	a2,s0,-64
    80005732:	4581                	li	a1,0
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	50c080e7          	jalr	1292(ra) # 80003c42 <writei>
    8000573e:	47c1                	li	a5,16
    80005740:	0af51563          	bne	a0,a5,800057ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005744:	04491703          	lh	a4,68(s2)
    80005748:	4785                	li	a5,1
    8000574a:	0af70863          	beq	a4,a5,800057fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	3a8080e7          	jalr	936(ra) # 80003af8 <iunlockput>
  ip->nlink--;
    80005758:	04a95783          	lhu	a5,74(s2)
    8000575c:	37fd                	addiw	a5,a5,-1
    8000575e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005762:	854a                	mv	a0,s2
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	066080e7          	jalr	102(ra) # 800037ca <iupdate>
  iunlockput(ip);
    8000576c:	854a                	mv	a0,s2
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	38a080e7          	jalr	906(ra) # 80003af8 <iunlockput>
  end_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	b6a080e7          	jalr	-1174(ra) # 800042e0 <end_op>
  return 0;
    8000577e:	4501                	li	a0,0
    80005780:	a84d                	j	80005832 <sys_unlink+0x1c4>
    end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	b5e080e7          	jalr	-1186(ra) # 800042e0 <end_op>
    return -1;
    8000578a:	557d                	li	a0,-1
    8000578c:	a05d                	j	80005832 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578e:	00003517          	auipc	a0,0x3
    80005792:	fc250513          	addi	a0,a0,-62 # 80008750 <syscalls+0x2c8>
    80005796:	ffffb097          	auipc	ra,0xffffb
    8000579a:	daa080e7          	jalr	-598(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579e:	04c92703          	lw	a4,76(s2)
    800057a2:	02000793          	li	a5,32
    800057a6:	f6e7f9e3          	bgeu	a5,a4,80005718 <sys_unlink+0xaa>
    800057aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ae:	4741                	li	a4,16
    800057b0:	86ce                	mv	a3,s3
    800057b2:	f1840613          	addi	a2,s0,-232
    800057b6:	4581                	li	a1,0
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	390080e7          	jalr	912(ra) # 80003b4a <readi>
    800057c2:	47c1                	li	a5,16
    800057c4:	00f51b63          	bne	a0,a5,800057da <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c8:	f1845783          	lhu	a5,-232(s0)
    800057cc:	e7a1                	bnez	a5,80005814 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ce:	29c1                	addiw	s3,s3,16
    800057d0:	04c92783          	lw	a5,76(s2)
    800057d4:	fcf9ede3          	bltu	s3,a5,800057ae <sys_unlink+0x140>
    800057d8:	b781                	j	80005718 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057da:	00003517          	auipc	a0,0x3
    800057de:	f8e50513          	addi	a0,a0,-114 # 80008768 <syscalls+0x2e0>
    800057e2:	ffffb097          	auipc	ra,0xffffb
    800057e6:	d5e080e7          	jalr	-674(ra) # 80000540 <panic>
    panic("unlink: writei");
    800057ea:	00003517          	auipc	a0,0x3
    800057ee:	f9650513          	addi	a0,a0,-106 # 80008780 <syscalls+0x2f8>
    800057f2:	ffffb097          	auipc	ra,0xffffb
    800057f6:	d4e080e7          	jalr	-690(ra) # 80000540 <panic>
    dp->nlink--;
    800057fa:	04a4d783          	lhu	a5,74(s1)
    800057fe:	37fd                	addiw	a5,a5,-1
    80005800:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005804:	8526                	mv	a0,s1
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	fc4080e7          	jalr	-60(ra) # 800037ca <iupdate>
    8000580e:	b781                	j	8000574e <sys_unlink+0xe0>
    return -1;
    80005810:	557d                	li	a0,-1
    80005812:	a005                	j	80005832 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005814:	854a                	mv	a0,s2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	2e2080e7          	jalr	738(ra) # 80003af8 <iunlockput>
  iunlockput(dp);
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	2d8080e7          	jalr	728(ra) # 80003af8 <iunlockput>
  end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	ab8080e7          	jalr	-1352(ra) # 800042e0 <end_op>
  return -1;
    80005830:	557d                	li	a0,-1
}
    80005832:	70ae                	ld	ra,232(sp)
    80005834:	740e                	ld	s0,224(sp)
    80005836:	64ee                	ld	s1,216(sp)
    80005838:	694e                	ld	s2,208(sp)
    8000583a:	69ae                	ld	s3,200(sp)
    8000583c:	616d                	addi	sp,sp,240
    8000583e:	8082                	ret

0000000080005840 <sys_open>:

uint64
sys_open(void)
{
    80005840:	7131                	addi	sp,sp,-192
    80005842:	fd06                	sd	ra,184(sp)
    80005844:	f922                	sd	s0,176(sp)
    80005846:	f526                	sd	s1,168(sp)
    80005848:	f14a                	sd	s2,160(sp)
    8000584a:	ed4e                	sd	s3,152(sp)
    8000584c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000584e:	f4c40593          	addi	a1,s0,-180
    80005852:	4505                	li	a0,1
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	464080e7          	jalr	1124(ra) # 80002cb8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000585c:	08000613          	li	a2,128
    80005860:	f5040593          	addi	a1,s0,-176
    80005864:	4501                	li	a0,0
    80005866:	ffffd097          	auipc	ra,0xffffd
    8000586a:	492080e7          	jalr	1170(ra) # 80002cf8 <argstr>
    8000586e:	87aa                	mv	a5,a0
    return -1;
    80005870:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005872:	0a07c963          	bltz	a5,80005924 <sys_open+0xe4>

  begin_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	9ec080e7          	jalr	-1556(ra) # 80004262 <begin_op>

  if(omode & O_CREATE){
    8000587e:	f4c42783          	lw	a5,-180(s0)
    80005882:	2007f793          	andi	a5,a5,512
    80005886:	cfc5                	beqz	a5,8000593e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005888:	4681                	li	a3,0
    8000588a:	4601                	li	a2,0
    8000588c:	4589                	li	a1,2
    8000588e:	f5040513          	addi	a0,s0,-176
    80005892:	00000097          	auipc	ra,0x0
    80005896:	972080e7          	jalr	-1678(ra) # 80005204 <create>
    8000589a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000589c:	c959                	beqz	a0,80005932 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589e:	04449703          	lh	a4,68(s1)
    800058a2:	478d                	li	a5,3
    800058a4:	00f71763          	bne	a4,a5,800058b2 <sys_open+0x72>
    800058a8:	0464d703          	lhu	a4,70(s1)
    800058ac:	47a5                	li	a5,9
    800058ae:	0ce7ed63          	bltu	a5,a4,80005988 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	dbc080e7          	jalr	-580(ra) # 8000466e <filealloc>
    800058ba:	89aa                	mv	s3,a0
    800058bc:	10050363          	beqz	a0,800059c2 <sys_open+0x182>
    800058c0:	00000097          	auipc	ra,0x0
    800058c4:	902080e7          	jalr	-1790(ra) # 800051c2 <fdalloc>
    800058c8:	892a                	mv	s2,a0
    800058ca:	0e054763          	bltz	a0,800059b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058ce:	04449703          	lh	a4,68(s1)
    800058d2:	478d                	li	a5,3
    800058d4:	0cf70563          	beq	a4,a5,8000599e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d8:	4789                	li	a5,2
    800058da:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058de:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e6:	f4c42783          	lw	a5,-180(s0)
    800058ea:	0017c713          	xori	a4,a5,1
    800058ee:	8b05                	andi	a4,a4,1
    800058f0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f4:	0037f713          	andi	a4,a5,3
    800058f8:	00e03733          	snez	a4,a4
    800058fc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005900:	4007f793          	andi	a5,a5,1024
    80005904:	c791                	beqz	a5,80005910 <sys_open+0xd0>
    80005906:	04449703          	lh	a4,68(s1)
    8000590a:	4789                	li	a5,2
    8000590c:	0af70063          	beq	a4,a5,800059ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	046080e7          	jalr	70(ra) # 80003958 <iunlock>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	9c6080e7          	jalr	-1594(ra) # 800042e0 <end_op>

  return fd;
    80005922:	854a                	mv	a0,s2
}
    80005924:	70ea                	ld	ra,184(sp)
    80005926:	744a                	ld	s0,176(sp)
    80005928:	74aa                	ld	s1,168(sp)
    8000592a:	790a                	ld	s2,160(sp)
    8000592c:	69ea                	ld	s3,152(sp)
    8000592e:	6129                	addi	sp,sp,192
    80005930:	8082                	ret
      end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	9ae080e7          	jalr	-1618(ra) # 800042e0 <end_op>
      return -1;
    8000593a:	557d                	li	a0,-1
    8000593c:	b7e5                	j	80005924 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593e:	f5040513          	addi	a0,s0,-176
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	700080e7          	jalr	1792(ra) # 80004042 <namei>
    8000594a:	84aa                	mv	s1,a0
    8000594c:	c905                	beqz	a0,8000597c <sys_open+0x13c>
    ilock(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	f48080e7          	jalr	-184(ra) # 80003896 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005956:	04449703          	lh	a4,68(s1)
    8000595a:	4785                	li	a5,1
    8000595c:	f4f711e3          	bne	a4,a5,8000589e <sys_open+0x5e>
    80005960:	f4c42783          	lw	a5,-180(s0)
    80005964:	d7b9                	beqz	a5,800058b2 <sys_open+0x72>
      iunlockput(ip);
    80005966:	8526                	mv	a0,s1
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	190080e7          	jalr	400(ra) # 80003af8 <iunlockput>
      end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	970080e7          	jalr	-1680(ra) # 800042e0 <end_op>
      return -1;
    80005978:	557d                	li	a0,-1
    8000597a:	b76d                	j	80005924 <sys_open+0xe4>
      end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	964080e7          	jalr	-1692(ra) # 800042e0 <end_op>
      return -1;
    80005984:	557d                	li	a0,-1
    80005986:	bf79                	j	80005924 <sys_open+0xe4>
    iunlockput(ip);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	16e080e7          	jalr	366(ra) # 80003af8 <iunlockput>
    end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	94e080e7          	jalr	-1714(ra) # 800042e0 <end_op>
    return -1;
    8000599a:	557d                	li	a0,-1
    8000599c:	b761                	j	80005924 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059a2:	04649783          	lh	a5,70(s1)
    800059a6:	02f99223          	sh	a5,36(s3)
    800059aa:	bf25                	j	800058e2 <sys_open+0xa2>
    itrunc(ip);
    800059ac:	8526                	mv	a0,s1
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	ff6080e7          	jalr	-10(ra) # 800039a4 <itrunc>
    800059b6:	bfa9                	j	80005910 <sys_open+0xd0>
      fileclose(f);
    800059b8:	854e                	mv	a0,s3
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	d70080e7          	jalr	-656(ra) # 8000472a <fileclose>
    iunlockput(ip);
    800059c2:	8526                	mv	a0,s1
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	134080e7          	jalr	308(ra) # 80003af8 <iunlockput>
    end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	914080e7          	jalr	-1772(ra) # 800042e0 <end_op>
    return -1;
    800059d4:	557d                	li	a0,-1
    800059d6:	b7b9                	j	80005924 <sys_open+0xe4>

00000000800059d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d8:	7175                	addi	sp,sp,-144
    800059da:	e506                	sd	ra,136(sp)
    800059dc:	e122                	sd	s0,128(sp)
    800059de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	882080e7          	jalr	-1918(ra) # 80004262 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e8:	08000613          	li	a2,128
    800059ec:	f7040593          	addi	a1,s0,-144
    800059f0:	4501                	li	a0,0
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	306080e7          	jalr	774(ra) # 80002cf8 <argstr>
    800059fa:	02054963          	bltz	a0,80005a2c <sys_mkdir+0x54>
    800059fe:	4681                	li	a3,0
    80005a00:	4601                	li	a2,0
    80005a02:	4585                	li	a1,1
    80005a04:	f7040513          	addi	a0,s0,-144
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	7fc080e7          	jalr	2044(ra) # 80005204 <create>
    80005a10:	cd11                	beqz	a0,80005a2c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	0e6080e7          	jalr	230(ra) # 80003af8 <iunlockput>
  end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	8c6080e7          	jalr	-1850(ra) # 800042e0 <end_op>
  return 0;
    80005a22:	4501                	li	a0,0
}
    80005a24:	60aa                	ld	ra,136(sp)
    80005a26:	640a                	ld	s0,128(sp)
    80005a28:	6149                	addi	sp,sp,144
    80005a2a:	8082                	ret
    end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	8b4080e7          	jalr	-1868(ra) # 800042e0 <end_op>
    return -1;
    80005a34:	557d                	li	a0,-1
    80005a36:	b7fd                	j	80005a24 <sys_mkdir+0x4c>

0000000080005a38 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a38:	7135                	addi	sp,sp,-160
    80005a3a:	ed06                	sd	ra,152(sp)
    80005a3c:	e922                	sd	s0,144(sp)
    80005a3e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	822080e7          	jalr	-2014(ra) # 80004262 <begin_op>
  argint(1, &major);
    80005a48:	f6c40593          	addi	a1,s0,-148
    80005a4c:	4505                	li	a0,1
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	26a080e7          	jalr	618(ra) # 80002cb8 <argint>
  argint(2, &minor);
    80005a56:	f6840593          	addi	a1,s0,-152
    80005a5a:	4509                	li	a0,2
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	25c080e7          	jalr	604(ra) # 80002cb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a64:	08000613          	li	a2,128
    80005a68:	f7040593          	addi	a1,s0,-144
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	28a080e7          	jalr	650(ra) # 80002cf8 <argstr>
    80005a76:	02054b63          	bltz	a0,80005aac <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a7a:	f6841683          	lh	a3,-152(s0)
    80005a7e:	f6c41603          	lh	a2,-148(s0)
    80005a82:	458d                	li	a1,3
    80005a84:	f7040513          	addi	a0,s0,-144
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	77c080e7          	jalr	1916(ra) # 80005204 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a90:	cd11                	beqz	a0,80005aac <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	066080e7          	jalr	102(ra) # 80003af8 <iunlockput>
  end_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	846080e7          	jalr	-1978(ra) # 800042e0 <end_op>
  return 0;
    80005aa2:	4501                	li	a0,0
}
    80005aa4:	60ea                	ld	ra,152(sp)
    80005aa6:	644a                	ld	s0,144(sp)
    80005aa8:	610d                	addi	sp,sp,160
    80005aaa:	8082                	ret
    end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	834080e7          	jalr	-1996(ra) # 800042e0 <end_op>
    return -1;
    80005ab4:	557d                	li	a0,-1
    80005ab6:	b7fd                	j	80005aa4 <sys_mknod+0x6c>

0000000080005ab8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ab8:	7135                	addi	sp,sp,-160
    80005aba:	ed06                	sd	ra,152(sp)
    80005abc:	e922                	sd	s0,144(sp)
    80005abe:	e526                	sd	s1,136(sp)
    80005ac0:	e14a                	sd	s2,128(sp)
    80005ac2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac4:	ffffc097          	auipc	ra,0xffffc
    80005ac8:	038080e7          	jalr	56(ra) # 80001afc <myproc>
    80005acc:	892a                	mv	s2,a0
  
  begin_op();
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	794080e7          	jalr	1940(ra) # 80004262 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ad6:	08000613          	li	a2,128
    80005ada:	f6040593          	addi	a1,s0,-160
    80005ade:	4501                	li	a0,0
    80005ae0:	ffffd097          	auipc	ra,0xffffd
    80005ae4:	218080e7          	jalr	536(ra) # 80002cf8 <argstr>
    80005ae8:	04054b63          	bltz	a0,80005b3e <sys_chdir+0x86>
    80005aec:	f6040513          	addi	a0,s0,-160
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	552080e7          	jalr	1362(ra) # 80004042 <namei>
    80005af8:	84aa                	mv	s1,a0
    80005afa:	c131                	beqz	a0,80005b3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	d9a080e7          	jalr	-614(ra) # 80003896 <ilock>
  if(ip->type != T_DIR){
    80005b04:	04449703          	lh	a4,68(s1)
    80005b08:	4785                	li	a5,1
    80005b0a:	04f71063          	bne	a4,a5,80005b4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b0e:	8526                	mv	a0,s1
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	e48080e7          	jalr	-440(ra) # 80003958 <iunlock>
  iput(p->cwd);
    80005b18:	15093503          	ld	a0,336(s2)
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	f34080e7          	jalr	-204(ra) # 80003a50 <iput>
  end_op();
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	7bc080e7          	jalr	1980(ra) # 800042e0 <end_op>
  p->cwd = ip;
    80005b2c:	14993823          	sd	s1,336(s2)
  return 0;
    80005b30:	4501                	li	a0,0
}
    80005b32:	60ea                	ld	ra,152(sp)
    80005b34:	644a                	ld	s0,144(sp)
    80005b36:	64aa                	ld	s1,136(sp)
    80005b38:	690a                	ld	s2,128(sp)
    80005b3a:	610d                	addi	sp,sp,160
    80005b3c:	8082                	ret
    end_op();
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	7a2080e7          	jalr	1954(ra) # 800042e0 <end_op>
    return -1;
    80005b46:	557d                	li	a0,-1
    80005b48:	b7ed                	j	80005b32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b4a:	8526                	mv	a0,s1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	fac080e7          	jalr	-84(ra) # 80003af8 <iunlockput>
    end_op();
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	78c080e7          	jalr	1932(ra) # 800042e0 <end_op>
    return -1;
    80005b5c:	557d                	li	a0,-1
    80005b5e:	bfd1                	j	80005b32 <sys_chdir+0x7a>

0000000080005b60 <sys_exec>:

uint64
sys_exec(void)
{
    80005b60:	7145                	addi	sp,sp,-464
    80005b62:	e786                	sd	ra,456(sp)
    80005b64:	e3a2                	sd	s0,448(sp)
    80005b66:	ff26                	sd	s1,440(sp)
    80005b68:	fb4a                	sd	s2,432(sp)
    80005b6a:	f74e                	sd	s3,424(sp)
    80005b6c:	f352                	sd	s4,416(sp)
    80005b6e:	ef56                	sd	s5,408(sp)
    80005b70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b72:	e3840593          	addi	a1,s0,-456
    80005b76:	4505                	li	a0,1
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	160080e7          	jalr	352(ra) # 80002cd8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b80:	08000613          	li	a2,128
    80005b84:	f4040593          	addi	a1,s0,-192
    80005b88:	4501                	li	a0,0
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	16e080e7          	jalr	366(ra) # 80002cf8 <argstr>
    80005b92:	87aa                	mv	a5,a0
    return -1;
    80005b94:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b96:	0c07c363          	bltz	a5,80005c5c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b9a:	10000613          	li	a2,256
    80005b9e:	4581                	li	a1,0
    80005ba0:	e4040513          	addi	a0,s0,-448
    80005ba4:	ffffb097          	auipc	ra,0xffffb
    80005ba8:	264080e7          	jalr	612(ra) # 80000e08 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb0:	89a6                	mv	s3,s1
    80005bb2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bb4:	02000a13          	li	s4,32
    80005bb8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bbc:	00391513          	slli	a0,s2,0x3
    80005bc0:	e3040593          	addi	a1,s0,-464
    80005bc4:	e3843783          	ld	a5,-456(s0)
    80005bc8:	953e                	add	a0,a0,a5
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	050080e7          	jalr	80(ra) # 80002c1a <fetchaddr>
    80005bd2:	02054a63          	bltz	a0,80005c06 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bd6:	e3043783          	ld	a5,-464(s0)
    80005bda:	c3b9                	beqz	a5,80005c20 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bdc:	ffffb097          	auipc	ra,0xffffb
    80005be0:	008080e7          	jalr	8(ra) # 80000be4 <kalloc>
    80005be4:	85aa                	mv	a1,a0
    80005be6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bea:	cd11                	beqz	a0,80005c06 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bec:	6605                	lui	a2,0x1
    80005bee:	e3043503          	ld	a0,-464(s0)
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	07a080e7          	jalr	122(ra) # 80002c6c <fetchstr>
    80005bfa:	00054663          	bltz	a0,80005c06 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005bfe:	0905                	addi	s2,s2,1
    80005c00:	09a1                	addi	s3,s3,8
    80005c02:	fb491be3          	bne	s2,s4,80005bb8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c06:	f4040913          	addi	s2,s0,-192
    80005c0a:	6088                	ld	a0,0(s1)
    80005c0c:	c539                	beqz	a0,80005c5a <sys_exec+0xfa>
    kfree(argv[i]);
    80005c0e:	ffffb097          	auipc	ra,0xffffb
    80005c12:	e52080e7          	jalr	-430(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c16:	04a1                	addi	s1,s1,8
    80005c18:	ff2499e3          	bne	s1,s2,80005c0a <sys_exec+0xaa>
  return -1;
    80005c1c:	557d                	li	a0,-1
    80005c1e:	a83d                	j	80005c5c <sys_exec+0xfc>
      argv[i] = 0;
    80005c20:	0a8e                	slli	s5,s5,0x3
    80005c22:	fc0a8793          	addi	a5,s5,-64
    80005c26:	00878ab3          	add	s5,a5,s0
    80005c2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c2e:	e4040593          	addi	a1,s0,-448
    80005c32:	f4040513          	addi	a0,s0,-192
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	16e080e7          	jalr	366(ra) # 80004da4 <exec>
    80005c3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c40:	f4040993          	addi	s3,s0,-192
    80005c44:	6088                	ld	a0,0(s1)
    80005c46:	c901                	beqz	a0,80005c56 <sys_exec+0xf6>
    kfree(argv[i]);
    80005c48:	ffffb097          	auipc	ra,0xffffb
    80005c4c:	e18080e7          	jalr	-488(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c50:	04a1                	addi	s1,s1,8
    80005c52:	ff3499e3          	bne	s1,s3,80005c44 <sys_exec+0xe4>
  return ret;
    80005c56:	854a                	mv	a0,s2
    80005c58:	a011                	j	80005c5c <sys_exec+0xfc>
  return -1;
    80005c5a:	557d                	li	a0,-1
}
    80005c5c:	60be                	ld	ra,456(sp)
    80005c5e:	641e                	ld	s0,448(sp)
    80005c60:	74fa                	ld	s1,440(sp)
    80005c62:	795a                	ld	s2,432(sp)
    80005c64:	79ba                	ld	s3,424(sp)
    80005c66:	7a1a                	ld	s4,416(sp)
    80005c68:	6afa                	ld	s5,408(sp)
    80005c6a:	6179                	addi	sp,sp,464
    80005c6c:	8082                	ret

0000000080005c6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c6e:	7139                	addi	sp,sp,-64
    80005c70:	fc06                	sd	ra,56(sp)
    80005c72:	f822                	sd	s0,48(sp)
    80005c74:	f426                	sd	s1,40(sp)
    80005c76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	e84080e7          	jalr	-380(ra) # 80001afc <myproc>
    80005c80:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c82:	fd840593          	addi	a1,s0,-40
    80005c86:	4501                	li	a0,0
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	050080e7          	jalr	80(ra) # 80002cd8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c90:	fc840593          	addi	a1,s0,-56
    80005c94:	fd040513          	addi	a0,s0,-48
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	dc2080e7          	jalr	-574(ra) # 80004a5a <pipealloc>
    return -1;
    80005ca0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ca2:	0c054463          	bltz	a0,80005d6a <sys_pipe+0xfc>
  fd0 = -1;
    80005ca6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005caa:	fd043503          	ld	a0,-48(s0)
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	514080e7          	jalr	1300(ra) # 800051c2 <fdalloc>
    80005cb6:	fca42223          	sw	a0,-60(s0)
    80005cba:	08054b63          	bltz	a0,80005d50 <sys_pipe+0xe2>
    80005cbe:	fc843503          	ld	a0,-56(s0)
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	500080e7          	jalr	1280(ra) # 800051c2 <fdalloc>
    80005cca:	fca42023          	sw	a0,-64(s0)
    80005cce:	06054863          	bltz	a0,80005d3e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd2:	4691                	li	a3,4
    80005cd4:	fc440613          	addi	a2,s0,-60
    80005cd8:	fd843583          	ld	a1,-40(s0)
    80005cdc:	68a8                	ld	a0,80(s1)
    80005cde:	ffffc097          	auipc	ra,0xffffc
    80005ce2:	aaa080e7          	jalr	-1366(ra) # 80001788 <copyout>
    80005ce6:	02054063          	bltz	a0,80005d06 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cea:	4691                	li	a3,4
    80005cec:	fc040613          	addi	a2,s0,-64
    80005cf0:	fd843583          	ld	a1,-40(s0)
    80005cf4:	0591                	addi	a1,a1,4
    80005cf6:	68a8                	ld	a0,80(s1)
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	a90080e7          	jalr	-1392(ra) # 80001788 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d00:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d02:	06055463          	bgez	a0,80005d6a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d06:	fc442783          	lw	a5,-60(s0)
    80005d0a:	07e9                	addi	a5,a5,26
    80005d0c:	078e                	slli	a5,a5,0x3
    80005d0e:	97a6                	add	a5,a5,s1
    80005d10:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d14:	fc042783          	lw	a5,-64(s0)
    80005d18:	07e9                	addi	a5,a5,26
    80005d1a:	078e                	slli	a5,a5,0x3
    80005d1c:	94be                	add	s1,s1,a5
    80005d1e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d22:	fd043503          	ld	a0,-48(s0)
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	a04080e7          	jalr	-1532(ra) # 8000472a <fileclose>
    fileclose(wf);
    80005d2e:	fc843503          	ld	a0,-56(s0)
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	9f8080e7          	jalr	-1544(ra) # 8000472a <fileclose>
    return -1;
    80005d3a:	57fd                	li	a5,-1
    80005d3c:	a03d                	j	80005d6a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d3e:	fc442783          	lw	a5,-60(s0)
    80005d42:	0007c763          	bltz	a5,80005d50 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d46:	07e9                	addi	a5,a5,26
    80005d48:	078e                	slli	a5,a5,0x3
    80005d4a:	97a6                	add	a5,a5,s1
    80005d4c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005d50:	fd043503          	ld	a0,-48(s0)
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	9d6080e7          	jalr	-1578(ra) # 8000472a <fileclose>
    fileclose(wf);
    80005d5c:	fc843503          	ld	a0,-56(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	9ca080e7          	jalr	-1590(ra) # 8000472a <fileclose>
    return -1;
    80005d68:	57fd                	li	a5,-1
}
    80005d6a:	853e                	mv	a0,a5
    80005d6c:	70e2                	ld	ra,56(sp)
    80005d6e:	7442                	ld	s0,48(sp)
    80005d70:	74a2                	ld	s1,40(sp)
    80005d72:	6121                	addi	sp,sp,64
    80005d74:	8082                	ret
	...

0000000080005d80 <kernelvec>:
    80005d80:	7111                	addi	sp,sp,-256
    80005d82:	e006                	sd	ra,0(sp)
    80005d84:	e40a                	sd	sp,8(sp)
    80005d86:	e80e                	sd	gp,16(sp)
    80005d88:	ec12                	sd	tp,24(sp)
    80005d8a:	f016                	sd	t0,32(sp)
    80005d8c:	f41a                	sd	t1,40(sp)
    80005d8e:	f81e                	sd	t2,48(sp)
    80005d90:	fc22                	sd	s0,56(sp)
    80005d92:	e0a6                	sd	s1,64(sp)
    80005d94:	e4aa                	sd	a0,72(sp)
    80005d96:	e8ae                	sd	a1,80(sp)
    80005d98:	ecb2                	sd	a2,88(sp)
    80005d9a:	f0b6                	sd	a3,96(sp)
    80005d9c:	f4ba                	sd	a4,104(sp)
    80005d9e:	f8be                	sd	a5,112(sp)
    80005da0:	fcc2                	sd	a6,120(sp)
    80005da2:	e146                	sd	a7,128(sp)
    80005da4:	e54a                	sd	s2,136(sp)
    80005da6:	e94e                	sd	s3,144(sp)
    80005da8:	ed52                	sd	s4,152(sp)
    80005daa:	f156                	sd	s5,160(sp)
    80005dac:	f55a                	sd	s6,168(sp)
    80005dae:	f95e                	sd	s7,176(sp)
    80005db0:	fd62                	sd	s8,184(sp)
    80005db2:	e1e6                	sd	s9,192(sp)
    80005db4:	e5ea                	sd	s10,200(sp)
    80005db6:	e9ee                	sd	s11,208(sp)
    80005db8:	edf2                	sd	t3,216(sp)
    80005dba:	f1f6                	sd	t4,224(sp)
    80005dbc:	f5fa                	sd	t5,232(sp)
    80005dbe:	f9fe                	sd	t6,240(sp)
    80005dc0:	d27fc0ef          	jal	ra,80002ae6 <kerneltrap>
    80005dc4:	6082                	ld	ra,0(sp)
    80005dc6:	6122                	ld	sp,8(sp)
    80005dc8:	61c2                	ld	gp,16(sp)
    80005dca:	7282                	ld	t0,32(sp)
    80005dcc:	7322                	ld	t1,40(sp)
    80005dce:	73c2                	ld	t2,48(sp)
    80005dd0:	7462                	ld	s0,56(sp)
    80005dd2:	6486                	ld	s1,64(sp)
    80005dd4:	6526                	ld	a0,72(sp)
    80005dd6:	65c6                	ld	a1,80(sp)
    80005dd8:	6666                	ld	a2,88(sp)
    80005dda:	7686                	ld	a3,96(sp)
    80005ddc:	7726                	ld	a4,104(sp)
    80005dde:	77c6                	ld	a5,112(sp)
    80005de0:	7866                	ld	a6,120(sp)
    80005de2:	688a                	ld	a7,128(sp)
    80005de4:	692a                	ld	s2,136(sp)
    80005de6:	69ca                	ld	s3,144(sp)
    80005de8:	6a6a                	ld	s4,152(sp)
    80005dea:	7a8a                	ld	s5,160(sp)
    80005dec:	7b2a                	ld	s6,168(sp)
    80005dee:	7bca                	ld	s7,176(sp)
    80005df0:	7c6a                	ld	s8,184(sp)
    80005df2:	6c8e                	ld	s9,192(sp)
    80005df4:	6d2e                	ld	s10,200(sp)
    80005df6:	6dce                	ld	s11,208(sp)
    80005df8:	6e6e                	ld	t3,216(sp)
    80005dfa:	7e8e                	ld	t4,224(sp)
    80005dfc:	7f2e                	ld	t5,232(sp)
    80005dfe:	7fce                	ld	t6,240(sp)
    80005e00:	6111                	addi	sp,sp,256
    80005e02:	10200073          	sret
    80005e06:	00000013          	nop
    80005e0a:	00000013          	nop
    80005e0e:	0001                	nop

0000000080005e10 <timervec>:
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	e10c                	sd	a1,0(a0)
    80005e16:	e510                	sd	a2,8(a0)
    80005e18:	e914                	sd	a3,16(a0)
    80005e1a:	6d0c                	ld	a1,24(a0)
    80005e1c:	7110                	ld	a2,32(a0)
    80005e1e:	6194                	ld	a3,0(a1)
    80005e20:	96b2                	add	a3,a3,a2
    80005e22:	e194                	sd	a3,0(a1)
    80005e24:	4589                	li	a1,2
    80005e26:	14459073          	csrw	sip,a1
    80005e2a:	6914                	ld	a3,16(a0)
    80005e2c:	6510                	ld	a2,8(a0)
    80005e2e:	610c                	ld	a1,0(a0)
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	30200073          	mret
	...

0000000080005e3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e3a:	1141                	addi	sp,sp,-16
    80005e3c:	e422                	sd	s0,8(sp)
    80005e3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e40:	0c0007b7          	lui	a5,0xc000
    80005e44:	4705                	li	a4,1
    80005e46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e48:	c3d8                	sw	a4,4(a5)
}
    80005e4a:	6422                	ld	s0,8(sp)
    80005e4c:	0141                	addi	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plicinithart>:

void
plicinithart(void)
{
    80005e50:	1141                	addi	sp,sp,-16
    80005e52:	e406                	sd	ra,8(sp)
    80005e54:	e022                	sd	s0,0(sp)
    80005e56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	c78080e7          	jalr	-904(ra) # 80001ad0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e60:	0085171b          	slliw	a4,a0,0x8
    80005e64:	0c0027b7          	lui	a5,0xc002
    80005e68:	97ba                	add	a5,a5,a4
    80005e6a:	40200713          	li	a4,1026
    80005e6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e72:	00d5151b          	slliw	a0,a0,0xd
    80005e76:	0c2017b7          	lui	a5,0xc201
    80005e7a:	97aa                	add	a5,a5,a0
    80005e7c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e88:	1141                	addi	sp,sp,-16
    80005e8a:	e406                	sd	ra,8(sp)
    80005e8c:	e022                	sd	s0,0(sp)
    80005e8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	c40080e7          	jalr	-960(ra) # 80001ad0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e98:	00d5151b          	slliw	a0,a0,0xd
    80005e9c:	0c2017b7          	lui	a5,0xc201
    80005ea0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ea2:	43c8                	lw	a0,4(a5)
    80005ea4:	60a2                	ld	ra,8(sp)
    80005ea6:	6402                	ld	s0,0(sp)
    80005ea8:	0141                	addi	sp,sp,16
    80005eaa:	8082                	ret

0000000080005eac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	e426                	sd	s1,8(sp)
    80005eb4:	1000                	addi	s0,sp,32
    80005eb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	c18080e7          	jalr	-1000(ra) # 80001ad0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ec0:	00d5151b          	slliw	a0,a0,0xd
    80005ec4:	0c2017b7          	lui	a5,0xc201
    80005ec8:	97aa                	add	a5,a5,a0
    80005eca:	c3c4                	sw	s1,4(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6105                	addi	sp,sp,32
    80005ed4:	8082                	ret

0000000080005ed6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ed6:	1141                	addi	sp,sp,-16
    80005ed8:	e406                	sd	ra,8(sp)
    80005eda:	e022                	sd	s0,0(sp)
    80005edc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ede:	479d                	li	a5,7
    80005ee0:	04a7cc63          	blt	a5,a0,80005f38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ee4:	0023d797          	auipc	a5,0x23d
    80005ee8:	58c78793          	addi	a5,a5,1420 # 80243470 <disk>
    80005eec:	97aa                	add	a5,a5,a0
    80005eee:	0187c783          	lbu	a5,24(a5)
    80005ef2:	ebb9                	bnez	a5,80005f48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ef4:	00451693          	slli	a3,a0,0x4
    80005ef8:	0023d797          	auipc	a5,0x23d
    80005efc:	57878793          	addi	a5,a5,1400 # 80243470 <disk>
    80005f00:	6398                	ld	a4,0(a5)
    80005f02:	9736                	add	a4,a4,a3
    80005f04:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005f08:	6398                	ld	a4,0(a5)
    80005f0a:	9736                	add	a4,a4,a3
    80005f0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f18:	97aa                	add	a5,a5,a0
    80005f1a:	4705                	li	a4,1
    80005f1c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005f20:	0023d517          	auipc	a0,0x23d
    80005f24:	56850513          	addi	a0,a0,1384 # 80243488 <disk+0x18>
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	2e0080e7          	jalr	736(ra) # 80002208 <wakeup>
}
    80005f30:	60a2                	ld	ra,8(sp)
    80005f32:	6402                	ld	s0,0(sp)
    80005f34:	0141                	addi	sp,sp,16
    80005f36:	8082                	ret
    panic("free_desc 1");
    80005f38:	00003517          	auipc	a0,0x3
    80005f3c:	85850513          	addi	a0,a0,-1960 # 80008790 <syscalls+0x308>
    80005f40:	ffffa097          	auipc	ra,0xffffa
    80005f44:	600080e7          	jalr	1536(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	85850513          	addi	a0,a0,-1960 # 800087a0 <syscalls+0x318>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5f0080e7          	jalr	1520(ra) # 80000540 <panic>

0000000080005f58 <virtio_disk_init>:
{
    80005f58:	1101                	addi	sp,sp,-32
    80005f5a:	ec06                	sd	ra,24(sp)
    80005f5c:	e822                	sd	s0,16(sp)
    80005f5e:	e426                	sd	s1,8(sp)
    80005f60:	e04a                	sd	s2,0(sp)
    80005f62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f64:	00003597          	auipc	a1,0x3
    80005f68:	84c58593          	addi	a1,a1,-1972 # 800087b0 <syscalls+0x328>
    80005f6c:	0023d517          	auipc	a0,0x23d
    80005f70:	62c50513          	addi	a0,a0,1580 # 80243598 <disk+0x128>
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	d08080e7          	jalr	-760(ra) # 80000c7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f7c:	100017b7          	lui	a5,0x10001
    80005f80:	4398                	lw	a4,0(a5)
    80005f82:	2701                	sext.w	a4,a4
    80005f84:	747277b7          	lui	a5,0x74727
    80005f88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f8c:	14f71b63          	bne	a4,a5,800060e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f90:	100017b7          	lui	a5,0x10001
    80005f94:	43dc                	lw	a5,4(a5)
    80005f96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f98:	4709                	li	a4,2
    80005f9a:	14e79463          	bne	a5,a4,800060e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	479c                	lw	a5,8(a5)
    80005fa4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fa6:	12e79e63          	bne	a5,a4,800060e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005faa:	100017b7          	lui	a5,0x10001
    80005fae:	47d8                	lw	a4,12(a5)
    80005fb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fb2:	554d47b7          	lui	a5,0x554d4
    80005fb6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fba:	12f71463          	bne	a4,a5,800060e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc6:	4705                	li	a4,1
    80005fc8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fca:	470d                	li	a4,3
    80005fcc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fd0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005fd4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb1af>
    80005fd8:	8f75                	and	a4,a4,a3
    80005fda:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fdc:	472d                	li	a4,11
    80005fde:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005fe0:	5bbc                	lw	a5,112(a5)
    80005fe2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005fe6:	8ba1                	andi	a5,a5,8
    80005fe8:	10078563          	beqz	a5,800060f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fec:	100017b7          	lui	a5,0x10001
    80005ff0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ff4:	43fc                	lw	a5,68(a5)
    80005ff6:	2781                	sext.w	a5,a5
    80005ff8:	10079563          	bnez	a5,80006102 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ffc:	100017b7          	lui	a5,0x10001
    80006000:	5bdc                	lw	a5,52(a5)
    80006002:	2781                	sext.w	a5,a5
  if(max == 0)
    80006004:	10078763          	beqz	a5,80006112 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006008:	471d                	li	a4,7
    8000600a:	10f77c63          	bgeu	a4,a5,80006122 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	bd6080e7          	jalr	-1066(ra) # 80000be4 <kalloc>
    80006016:	0023d497          	auipc	s1,0x23d
    8000601a:	45a48493          	addi	s1,s1,1114 # 80243470 <disk>
    8000601e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	bc4080e7          	jalr	-1084(ra) # 80000be4 <kalloc>
    80006028:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000602a:	ffffb097          	auipc	ra,0xffffb
    8000602e:	bba080e7          	jalr	-1094(ra) # 80000be4 <kalloc>
    80006032:	87aa                	mv	a5,a0
    80006034:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006036:	6088                	ld	a0,0(s1)
    80006038:	cd6d                	beqz	a0,80006132 <virtio_disk_init+0x1da>
    8000603a:	0023d717          	auipc	a4,0x23d
    8000603e:	43e73703          	ld	a4,1086(a4) # 80243478 <disk+0x8>
    80006042:	cb65                	beqz	a4,80006132 <virtio_disk_init+0x1da>
    80006044:	c7fd                	beqz	a5,80006132 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006046:	6605                	lui	a2,0x1
    80006048:	4581                	li	a1,0
    8000604a:	ffffb097          	auipc	ra,0xffffb
    8000604e:	dbe080e7          	jalr	-578(ra) # 80000e08 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006052:	0023d497          	auipc	s1,0x23d
    80006056:	41e48493          	addi	s1,s1,1054 # 80243470 <disk>
    8000605a:	6605                	lui	a2,0x1
    8000605c:	4581                	li	a1,0
    8000605e:	6488                	ld	a0,8(s1)
    80006060:	ffffb097          	auipc	ra,0xffffb
    80006064:	da8080e7          	jalr	-600(ra) # 80000e08 <memset>
  memset(disk.used, 0, PGSIZE);
    80006068:	6605                	lui	a2,0x1
    8000606a:	4581                	li	a1,0
    8000606c:	6888                	ld	a0,16(s1)
    8000606e:	ffffb097          	auipc	ra,0xffffb
    80006072:	d9a080e7          	jalr	-614(ra) # 80000e08 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006076:	100017b7          	lui	a5,0x10001
    8000607a:	4721                	li	a4,8
    8000607c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000607e:	4098                	lw	a4,0(s1)
    80006080:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006084:	40d8                	lw	a4,4(s1)
    80006086:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000608a:	6498                	ld	a4,8(s1)
    8000608c:	0007069b          	sext.w	a3,a4
    80006090:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006094:	9701                	srai	a4,a4,0x20
    80006096:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000609a:	6898                	ld	a4,16(s1)
    8000609c:	0007069b          	sext.w	a3,a4
    800060a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060a4:	9701                	srai	a4,a4,0x20
    800060a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060aa:	4705                	li	a4,1
    800060ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060ae:	00e48c23          	sb	a4,24(s1)
    800060b2:	00e48ca3          	sb	a4,25(s1)
    800060b6:	00e48d23          	sb	a4,26(s1)
    800060ba:	00e48da3          	sb	a4,27(s1)
    800060be:	00e48e23          	sb	a4,28(s1)
    800060c2:	00e48ea3          	sb	a4,29(s1)
    800060c6:	00e48f23          	sb	a4,30(s1)
    800060ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060ce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d2:	0727a823          	sw	s2,112(a5)
}
    800060d6:	60e2                	ld	ra,24(sp)
    800060d8:	6442                	ld	s0,16(sp)
    800060da:	64a2                	ld	s1,8(sp)
    800060dc:	6902                	ld	s2,0(sp)
    800060de:	6105                	addi	sp,sp,32
    800060e0:	8082                	ret
    panic("could not find virtio disk");
    800060e2:	00002517          	auipc	a0,0x2
    800060e6:	6de50513          	addi	a0,a0,1758 # 800087c0 <syscalls+0x338>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	456080e7          	jalr	1110(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800060f2:	00002517          	auipc	a0,0x2
    800060f6:	6ee50513          	addi	a0,a0,1774 # 800087e0 <syscalls+0x358>
    800060fa:	ffffa097          	auipc	ra,0xffffa
    800060fe:	446080e7          	jalr	1094(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006102:	00002517          	auipc	a0,0x2
    80006106:	6fe50513          	addi	a0,a0,1790 # 80008800 <syscalls+0x378>
    8000610a:	ffffa097          	auipc	ra,0xffffa
    8000610e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006112:	00002517          	auipc	a0,0x2
    80006116:	70e50513          	addi	a0,a0,1806 # 80008820 <syscalls+0x398>
    8000611a:	ffffa097          	auipc	ra,0xffffa
    8000611e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006122:	00002517          	auipc	a0,0x2
    80006126:	71e50513          	addi	a0,a0,1822 # 80008840 <syscalls+0x3b8>
    8000612a:	ffffa097          	auipc	ra,0xffffa
    8000612e:	416080e7          	jalr	1046(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006132:	00002517          	auipc	a0,0x2
    80006136:	72e50513          	addi	a0,a0,1838 # 80008860 <syscalls+0x3d8>
    8000613a:	ffffa097          	auipc	ra,0xffffa
    8000613e:	406080e7          	jalr	1030(ra) # 80000540 <panic>

0000000080006142 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006142:	7119                	addi	sp,sp,-128
    80006144:	fc86                	sd	ra,120(sp)
    80006146:	f8a2                	sd	s0,112(sp)
    80006148:	f4a6                	sd	s1,104(sp)
    8000614a:	f0ca                	sd	s2,96(sp)
    8000614c:	ecce                	sd	s3,88(sp)
    8000614e:	e8d2                	sd	s4,80(sp)
    80006150:	e4d6                	sd	s5,72(sp)
    80006152:	e0da                	sd	s6,64(sp)
    80006154:	fc5e                	sd	s7,56(sp)
    80006156:	f862                	sd	s8,48(sp)
    80006158:	f466                	sd	s9,40(sp)
    8000615a:	f06a                	sd	s10,32(sp)
    8000615c:	ec6e                	sd	s11,24(sp)
    8000615e:	0100                	addi	s0,sp,128
    80006160:	8aaa                	mv	s5,a0
    80006162:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006164:	00c52d03          	lw	s10,12(a0)
    80006168:	001d1d1b          	slliw	s10,s10,0x1
    8000616c:	1d02                	slli	s10,s10,0x20
    8000616e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006172:	0023d517          	auipc	a0,0x23d
    80006176:	42650513          	addi	a0,a0,1062 # 80243598 <disk+0x128>
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	b92080e7          	jalr	-1134(ra) # 80000d0c <acquire>
  for(int i = 0; i < 3; i++){
    80006182:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006184:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006186:	0023db97          	auipc	s7,0x23d
    8000618a:	2eab8b93          	addi	s7,s7,746 # 80243470 <disk>
  for(int i = 0; i < 3; i++){
    8000618e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006190:	0023dc97          	auipc	s9,0x23d
    80006194:	408c8c93          	addi	s9,s9,1032 # 80243598 <disk+0x128>
    80006198:	a08d                	j	800061fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000619a:	00fb8733          	add	a4,s7,a5
    8000619e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061a2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061a4:	0207c563          	bltz	a5,800061ce <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061a8:	2905                	addiw	s2,s2,1
    800061aa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800061ac:	05690c63          	beq	s2,s6,80006204 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061b0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061b2:	0023d717          	auipc	a4,0x23d
    800061b6:	2be70713          	addi	a4,a4,702 # 80243470 <disk>
    800061ba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061bc:	01874683          	lbu	a3,24(a4)
    800061c0:	fee9                	bnez	a3,8000619a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061c2:	2785                	addiw	a5,a5,1
    800061c4:	0705                	addi	a4,a4,1
    800061c6:	fe979be3          	bne	a5,s1,800061bc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061ca:	57fd                	li	a5,-1
    800061cc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061ce:	01205d63          	blez	s2,800061e8 <virtio_disk_rw+0xa6>
    800061d2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061d4:	000a2503          	lw	a0,0(s4)
    800061d8:	00000097          	auipc	ra,0x0
    800061dc:	cfe080e7          	jalr	-770(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    800061e0:	2d85                	addiw	s11,s11,1
    800061e2:	0a11                	addi	s4,s4,4
    800061e4:	ff2d98e3          	bne	s11,s2,800061d4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061e8:	85e6                	mv	a1,s9
    800061ea:	0023d517          	auipc	a0,0x23d
    800061ee:	29e50513          	addi	a0,a0,670 # 80243488 <disk+0x18>
    800061f2:	ffffc097          	auipc	ra,0xffffc
    800061f6:	fb2080e7          	jalr	-78(ra) # 800021a4 <sleep>
  for(int i = 0; i < 3; i++){
    800061fa:	f8040a13          	addi	s4,s0,-128
{
    800061fe:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006200:	894e                	mv	s2,s3
    80006202:	b77d                	j	800061b0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006204:	f8042503          	lw	a0,-128(s0)
    80006208:	00a50713          	addi	a4,a0,10
    8000620c:	0712                	slli	a4,a4,0x4

  if(write)
    8000620e:	0023d797          	auipc	a5,0x23d
    80006212:	26278793          	addi	a5,a5,610 # 80243470 <disk>
    80006216:	00e786b3          	add	a3,a5,a4
    8000621a:	01803633          	snez	a2,s8
    8000621e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006220:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006224:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006228:	f6070613          	addi	a2,a4,-160
    8000622c:	6394                	ld	a3,0(a5)
    8000622e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006230:	00870593          	addi	a1,a4,8
    80006234:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006236:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006238:	0007b803          	ld	a6,0(a5)
    8000623c:	9642                	add	a2,a2,a6
    8000623e:	46c1                	li	a3,16
    80006240:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006242:	4585                	li	a1,1
    80006244:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006248:	f8442683          	lw	a3,-124(s0)
    8000624c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006250:	0692                	slli	a3,a3,0x4
    80006252:	9836                	add	a6,a6,a3
    80006254:	058a8613          	addi	a2,s5,88
    80006258:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000625c:	0007b803          	ld	a6,0(a5)
    80006260:	96c2                	add	a3,a3,a6
    80006262:	40000613          	li	a2,1024
    80006266:	c690                	sw	a2,8(a3)
  if(write)
    80006268:	001c3613          	seqz	a2,s8
    8000626c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006270:	00166613          	ori	a2,a2,1
    80006274:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006278:	f8842603          	lw	a2,-120(s0)
    8000627c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006280:	00250693          	addi	a3,a0,2
    80006284:	0692                	slli	a3,a3,0x4
    80006286:	96be                	add	a3,a3,a5
    80006288:	58fd                	li	a7,-1
    8000628a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000628e:	0612                	slli	a2,a2,0x4
    80006290:	9832                	add	a6,a6,a2
    80006292:	f9070713          	addi	a4,a4,-112
    80006296:	973e                	add	a4,a4,a5
    80006298:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000629c:	6398                	ld	a4,0(a5)
    8000629e:	9732                	add	a4,a4,a2
    800062a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062a2:	4609                	li	a2,2
    800062a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800062a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062ac:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800062b0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062b4:	6794                	ld	a3,8(a5)
    800062b6:	0026d703          	lhu	a4,2(a3)
    800062ba:	8b1d                	andi	a4,a4,7
    800062bc:	0706                	slli	a4,a4,0x1
    800062be:	96ba                	add	a3,a3,a4
    800062c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800062c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062c8:	6798                	ld	a4,8(a5)
    800062ca:	00275783          	lhu	a5,2(a4)
    800062ce:	2785                	addiw	a5,a5,1
    800062d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062e0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800062e4:	0023d917          	auipc	s2,0x23d
    800062e8:	2b490913          	addi	s2,s2,692 # 80243598 <disk+0x128>
  while(b->disk == 1) {
    800062ec:	4485                	li	s1,1
    800062ee:	00b79c63          	bne	a5,a1,80006306 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062f2:	85ca                	mv	a1,s2
    800062f4:	8556                	mv	a0,s5
    800062f6:	ffffc097          	auipc	ra,0xffffc
    800062fa:	eae080e7          	jalr	-338(ra) # 800021a4 <sleep>
  while(b->disk == 1) {
    800062fe:	004aa783          	lw	a5,4(s5)
    80006302:	fe9788e3          	beq	a5,s1,800062f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006306:	f8042903          	lw	s2,-128(s0)
    8000630a:	00290713          	addi	a4,s2,2
    8000630e:	0712                	slli	a4,a4,0x4
    80006310:	0023d797          	auipc	a5,0x23d
    80006314:	16078793          	addi	a5,a5,352 # 80243470 <disk>
    80006318:	97ba                	add	a5,a5,a4
    8000631a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000631e:	0023d997          	auipc	s3,0x23d
    80006322:	15298993          	addi	s3,s3,338 # 80243470 <disk>
    80006326:	00491713          	slli	a4,s2,0x4
    8000632a:	0009b783          	ld	a5,0(s3)
    8000632e:	97ba                	add	a5,a5,a4
    80006330:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006334:	854a                	mv	a0,s2
    80006336:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000633a:	00000097          	auipc	ra,0x0
    8000633e:	b9c080e7          	jalr	-1124(ra) # 80005ed6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006342:	8885                	andi	s1,s1,1
    80006344:	f0ed                	bnez	s1,80006326 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006346:	0023d517          	auipc	a0,0x23d
    8000634a:	25250513          	addi	a0,a0,594 # 80243598 <disk+0x128>
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	a72080e7          	jalr	-1422(ra) # 80000dc0 <release>
}
    80006356:	70e6                	ld	ra,120(sp)
    80006358:	7446                	ld	s0,112(sp)
    8000635a:	74a6                	ld	s1,104(sp)
    8000635c:	7906                	ld	s2,96(sp)
    8000635e:	69e6                	ld	s3,88(sp)
    80006360:	6a46                	ld	s4,80(sp)
    80006362:	6aa6                	ld	s5,72(sp)
    80006364:	6b06                	ld	s6,64(sp)
    80006366:	7be2                	ld	s7,56(sp)
    80006368:	7c42                	ld	s8,48(sp)
    8000636a:	7ca2                	ld	s9,40(sp)
    8000636c:	7d02                	ld	s10,32(sp)
    8000636e:	6de2                	ld	s11,24(sp)
    80006370:	6109                	addi	sp,sp,128
    80006372:	8082                	ret

0000000080006374 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006374:	1101                	addi	sp,sp,-32
    80006376:	ec06                	sd	ra,24(sp)
    80006378:	e822                	sd	s0,16(sp)
    8000637a:	e426                	sd	s1,8(sp)
    8000637c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000637e:	0023d497          	auipc	s1,0x23d
    80006382:	0f248493          	addi	s1,s1,242 # 80243470 <disk>
    80006386:	0023d517          	auipc	a0,0x23d
    8000638a:	21250513          	addi	a0,a0,530 # 80243598 <disk+0x128>
    8000638e:	ffffb097          	auipc	ra,0xffffb
    80006392:	97e080e7          	jalr	-1666(ra) # 80000d0c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006396:	10001737          	lui	a4,0x10001
    8000639a:	533c                	lw	a5,96(a4)
    8000639c:	8b8d                	andi	a5,a5,3
    8000639e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063a0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063a4:	689c                	ld	a5,16(s1)
    800063a6:	0204d703          	lhu	a4,32(s1)
    800063aa:	0027d783          	lhu	a5,2(a5)
    800063ae:	04f70863          	beq	a4,a5,800063fe <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063b2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063b6:	6898                	ld	a4,16(s1)
    800063b8:	0204d783          	lhu	a5,32(s1)
    800063bc:	8b9d                	andi	a5,a5,7
    800063be:	078e                	slli	a5,a5,0x3
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063c4:	00278713          	addi	a4,a5,2
    800063c8:	0712                	slli	a4,a4,0x4
    800063ca:	9726                	add	a4,a4,s1
    800063cc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063d0:	e721                	bnez	a4,80006418 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063d2:	0789                	addi	a5,a5,2
    800063d4:	0792                	slli	a5,a5,0x4
    800063d6:	97a6                	add	a5,a5,s1
    800063d8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063da:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063de:	ffffc097          	auipc	ra,0xffffc
    800063e2:	e2a080e7          	jalr	-470(ra) # 80002208 <wakeup>

    disk.used_idx += 1;
    800063e6:	0204d783          	lhu	a5,32(s1)
    800063ea:	2785                	addiw	a5,a5,1
    800063ec:	17c2                	slli	a5,a5,0x30
    800063ee:	93c1                	srli	a5,a5,0x30
    800063f0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063f4:	6898                	ld	a4,16(s1)
    800063f6:	00275703          	lhu	a4,2(a4)
    800063fa:	faf71ce3          	bne	a4,a5,800063b2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063fe:	0023d517          	auipc	a0,0x23d
    80006402:	19a50513          	addi	a0,a0,410 # 80243598 <disk+0x128>
    80006406:	ffffb097          	auipc	ra,0xffffb
    8000640a:	9ba080e7          	jalr	-1606(ra) # 80000dc0 <release>
}
    8000640e:	60e2                	ld	ra,24(sp)
    80006410:	6442                	ld	s0,16(sp)
    80006412:	64a2                	ld	s1,8(sp)
    80006414:	6105                	addi	sp,sp,32
    80006416:	8082                	ret
      panic("virtio_disk_intr status");
    80006418:	00002517          	auipc	a0,0x2
    8000641c:	46050513          	addi	a0,a0,1120 # 80008878 <syscalls+0x3f0>
    80006420:	ffffa097          	auipc	ra,0xffffa
    80006424:	120080e7          	jalr	288(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...

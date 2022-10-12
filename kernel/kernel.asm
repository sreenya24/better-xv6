
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
    80000066:	e4e78793          	addi	a5,a5,-434 # 80005eb0 <timervec>
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
    80001000:	ef4080e7          	jalr	-268(ra) # 80005ef0 <plicinithart>
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
    80001080:	e5e080e7          	jalr	-418(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001084:	00005097          	auipc	ra,0x5
    80001088:	e6c080e7          	jalr	-404(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    8000108c:	00002097          	auipc	ra,0x2
    80001090:	00e080e7          	jalr	14(ra) # 8000309a <binit>
    iinit();         // inode table
    80001094:	00002097          	auipc	ra,0x2
    80001098:	6ae080e7          	jalr	1710(ra) # 80003742 <iinit>
    fileinit();      // file table
    8000109c:	00003097          	auipc	ra,0x3
    800010a0:	654080e7          	jalr	1620(ra) # 800046f0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a4:	00005097          	auipc	ra,0x5
    800010a8:	f54080e7          	jalr	-172(ra) # 80005ff8 <virtio_disk_init>
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
    80001b74:	b52080e7          	jalr	-1198(ra) # 800036c2 <fsinit>
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
    80001e36:	2ba080e7          	jalr	698(ra) # 800040ec <namei>
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
    80001f62:	00003097          	auipc	ra,0x3
    80001f66:	820080e7          	jalr	-2016(ra) # 80004782 <filedup>
    80001f6a:	00a93023          	sd	a0,0(s2)
    80001f6e:	b7e5                	j	80001f56 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f70:	150ab503          	ld	a0,336(s5)
    80001f74:	00002097          	auipc	ra,0x2
    80001f78:	98e080e7          	jalr	-1650(ra) # 80003902 <idup>
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
    8000231c:	4bc080e7          	jalr	1212(ra) # 800047d4 <fileclose>
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
    80002334:	fdc080e7          	jalr	-36(ra) # 8000430c <begin_op>
  iput(p->cwd);
    80002338:	1509b503          	ld	a0,336(s3)
    8000233c:	00001097          	auipc	ra,0x1
    80002340:	7be080e7          	jalr	1982(ra) # 80003afa <iput>
  end_op();
    80002344:	00002097          	auipc	ra,0x2
    80002348:	046080e7          	jalr	70(ra) # 8000438a <end_op>
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

extern int devintr();

void
trapinit(void)
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
void
trapinithart(void)
{
    8000279a:	1141                	addi	sp,sp,-16
    8000279c:	e422                	sd	s0,8(sp)
    8000279e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a0:	00003797          	auipc	a5,0x3
    800027a4:	68078793          	addi	a5,a5,1664 # 80005e20 <kernelvec>
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
  if (pa2 == 0){
    800027f2:	c121                	beqz	a0,80002832 <cowfault+0x80>
    //panic("cow panic kalloc");
    return -1;
  }
 
  memmove((void *)pa2, (void *)pa1, PGSIZE);
    800027f4:	6605                	lui	a2,0x1
    800027f6:	85ca                	mv	a1,s2
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	66c080e7          	jalr	1644(ra) # 80000e64 <memmove>
  *pte = PA2PTE(pa2) | PTE_U | PTE_V | PTE_W | PTE_X|PTE_R;
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
void
usertrapret(void)
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
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
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
  w_sstatus(sstatus);
}

void
clockintr()
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
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002920:	00074d63          	bltz	a4,8000293a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002924:	57fd                	li	a5,-1
    80002926:	17fe                	slli	a5,a5,0x3f
    80002928:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000292a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000292c:	06f70363          	beq	a4,a5,80002992 <devintr+0x80>
  }
}
    80002930:	60e2                	ld	ra,24(sp)
    80002932:	6442                	ld	s0,16(sp)
    80002934:	64a2                	ld	s1,8(sp)
    80002936:	6105                	addi	sp,sp,32
    80002938:	8082                	ret
     (scause & 0xff) == 9){
    8000293a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000293e:	46a5                	li	a3,9
    80002940:	fed792e3          	bne	a5,a3,80002924 <devintr+0x12>
    int irq = plic_claim();
    80002944:	00003097          	auipc	ra,0x3
    80002948:	5e4080e7          	jalr	1508(ra) # 80005f28 <plic_claim>
    8000294c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000294e:	47a9                	li	a5,10
    80002950:	02f50763          	beq	a0,a5,8000297e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002954:	4785                	li	a5,1
    80002956:	02f50963          	beq	a0,a5,80002988 <devintr+0x76>
    return 1;
    8000295a:	4505                	li	a0,1
    } else if(irq){
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
    80002976:	5da080e7          	jalr	1498(ra) # 80005f4c <plic_complete>
    return 1;
    8000297a:	4505                	li	a0,1
    8000297c:	bf55                	j	80002930 <devintr+0x1e>
      uartintr();
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	01a080e7          	jalr	26(ra) # 80000998 <uartintr>
    80002986:	b7ed                	j	80002970 <devintr+0x5e>
      virtio_disk_intr();
    80002988:	00004097          	auipc	ra,0x4
    8000298c:	a8c080e7          	jalr	-1396(ra) # 80006414 <virtio_disk_intr>
    80002990:	b7c5                	j	80002970 <devintr+0x5e>
    if(cpuid() == 0){
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
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029c4:	1007f793          	andi	a5,a5,256
    800029c8:	e7b9                	bnez	a5,80002a16 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ca:	00003797          	auipc	a5,0x3
    800029ce:	45678793          	addi	a5,a5,1110 # 80005e20 <kernelvec>
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
  if(r_scause() == 8){
    800029f6:	47a1                	li	a5,8
    800029f8:	04f70363          	beq	a4,a5,80002a3e <usertrap+0x8a>
  } else if((which_dev = devintr()) != 0){
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	f16080e7          	jalr	-234(ra) # 80002912 <devintr>
    80002a04:	892a                	mv	s2,a0
    80002a06:	cd59                	beqz	a0,80002aa4 <usertrap+0xf0>
  if(killed(p))
    80002a08:	8526                	mv	a0,s1
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	a42080e7          	jalr	-1470(ra) # 8000244c <killed>
    80002a12:	c535                	beqz	a0,80002a7e <usertrap+0xca>
    80002a14:	a085                	j	80002a74 <usertrap+0xc0>
    panic("usertrap: not from user mode");
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	94250513          	addi	a0,a0,-1726 # 80008358 <states.0+0x58>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b22080e7          	jalr	-1246(ra) # 80000540 <panic>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a26:	143025f3          	csrr	a1,stval
   if ((cowfault(p->pagetable, r_stval()) )< 0)
    80002a2a:	6928                	ld	a0,80(a0)
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	d86080e7          	jalr	-634(ra) # 800027b2 <cowfault>
    80002a34:	fa055fe3          	bgez	a0,800029f2 <usertrap+0x3e>
     p->killed = 1;
    80002a38:	4785                	li	a5,1
    80002a3a:	d49c                	sw	a5,40(s1)
    80002a3c:	bf5d                	j	800029f2 <usertrap+0x3e>
    if(killed(p))
    80002a3e:	8526                	mv	a0,s1
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	a0c080e7          	jalr	-1524(ra) # 8000244c <killed>
    80002a48:	e921                	bnez	a0,80002a98 <usertrap+0xe4>
    p->trapframe->epc += 4;
    80002a4a:	6cb8                	ld	a4,88(s1)
    80002a4c:	6f1c                	ld	a5,24(a4)
    80002a4e:	0791                	addi	a5,a5,4
    80002a50:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a5a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	2d8080e7          	jalr	728(ra) # 80002d36 <syscall>
  if(killed(p))
    80002a66:	8526                	mv	a0,s1
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	9e4080e7          	jalr	-1564(ra) # 8000244c <killed>
    80002a70:	c911                	beqz	a0,80002a84 <usertrap+0xd0>
    80002a72:	4901                	li	s2,0
    exit(-1);
    80002a74:	557d                	li	a0,-1
    80002a76:	00000097          	auipc	ra,0x0
    80002a7a:	862080e7          	jalr	-1950(ra) # 800022d8 <exit>
  if(which_dev == 2)
    80002a7e:	4789                	li	a5,2
    80002a80:	04f90f63          	beq	s2,a5,80002ade <usertrap+0x12a>
  usertrapret();
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	db2080e7          	jalr	-590(ra) # 80002836 <usertrapret>
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6902                	ld	s2,0(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret
      exit(-1);
    80002a98:	557d                	li	a0,-1
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	83e080e7          	jalr	-1986(ra) # 800022d8 <exit>
    80002aa2:	b765                	j	80002a4a <usertrap+0x96>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002aa8:	5890                	lw	a2,48(s1)
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	8ce50513          	addi	a0,a0,-1842 # 80008378 <states.0+0x78>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ad8080e7          	jalr	-1320(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002abe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	8e650513          	addi	a0,a0,-1818 # 800083a8 <states.0+0xa8>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	ac0080e7          	jalr	-1344(ra) # 8000058a <printf>
    setkilled(p);
    80002ad2:	8526                	mv	a0,s1
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	94c080e7          	jalr	-1716(ra) # 80002420 <setkilled>
    80002adc:	b769                	j	80002a66 <usertrap+0xb2>
    yield();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	68a080e7          	jalr	1674(ra) # 80002168 <yield>
    80002ae6:	bf79                	j	80002a84 <usertrap+0xd0>

0000000080002ae8 <kerneltrap>:
{
    80002ae8:	7179                	addi	sp,sp,-48
    80002aea:	f406                	sd	ra,40(sp)
    80002aec:	f022                	sd	s0,32(sp)
    80002aee:	ec26                	sd	s1,24(sp)
    80002af0:	e84a                	sd	s2,16(sp)
    80002af2:	e44e                	sd	s3,8(sp)
    80002af4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b02:	1004f793          	andi	a5,s1,256
    80002b06:	cb85                	beqz	a5,80002b36 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b08:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b0c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b0e:	ef85                	bnez	a5,80002b46 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	e02080e7          	jalr	-510(ra) # 80002912 <devintr>
    80002b18:	cd1d                	beqz	a0,80002b56 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1a:	4789                	li	a5,2
    80002b1c:	06f50a63          	beq	a0,a5,80002b90 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b20:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b24:	10049073          	csrw	sstatus,s1
}
    80002b28:	70a2                	ld	ra,40(sp)
    80002b2a:	7402                	ld	s0,32(sp)
    80002b2c:	64e2                	ld	s1,24(sp)
    80002b2e:	6942                	ld	s2,16(sp)
    80002b30:	69a2                	ld	s3,8(sp)
    80002b32:	6145                	addi	sp,sp,48
    80002b34:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b36:	00006517          	auipc	a0,0x6
    80002b3a:	89250513          	addi	a0,a0,-1902 # 800083c8 <states.0+0xc8>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a02080e7          	jalr	-1534(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	8aa50513          	addi	a0,a0,-1878 # 800083f0 <states.0+0xf0>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	9f2080e7          	jalr	-1550(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002b56:	85ce                	mv	a1,s3
    80002b58:	00006517          	auipc	a0,0x6
    80002b5c:	8b850513          	addi	a0,a0,-1864 # 80008410 <states.0+0x110>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	a2a080e7          	jalr	-1494(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	8b050513          	addi	a0,a0,-1872 # 80008420 <states.0+0x120>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a12080e7          	jalr	-1518(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	8b850513          	addi	a0,a0,-1864 # 80008438 <states.0+0x138>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	9b8080e7          	jalr	-1608(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	f6c080e7          	jalr	-148(ra) # 80001afc <myproc>
    80002b98:	d541                	beqz	a0,80002b20 <kerneltrap+0x38>
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	f62080e7          	jalr	-158(ra) # 80001afc <myproc>
    80002ba2:	4d18                	lw	a4,24(a0)
    80002ba4:	4791                	li	a5,4
    80002ba6:	f6f71de3          	bne	a4,a5,80002b20 <kerneltrap+0x38>
    yield();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	5be080e7          	jalr	1470(ra) # 80002168 <yield>
    80002bb2:	b7bd                	j	80002b20 <kerneltrap+0x38>

0000000080002bb4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	1000                	addi	s0,sp,32
    80002bbe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	f3c080e7          	jalr	-196(ra) # 80001afc <myproc>
  switch (n) {
    80002bc8:	4795                	li	a5,5
    80002bca:	0497e163          	bltu	a5,s1,80002c0c <argraw+0x58>
    80002bce:	048a                	slli	s1,s1,0x2
    80002bd0:	00006717          	auipc	a4,0x6
    80002bd4:	8a070713          	addi	a4,a4,-1888 # 80008470 <states.0+0x170>
    80002bd8:	94ba                	add	s1,s1,a4
    80002bda:	409c                	lw	a5,0(s1)
    80002bdc:	97ba                	add	a5,a5,a4
    80002bde:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002be0:	6d3c                	ld	a5,88(a0)
    80002be2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be4:	60e2                	ld	ra,24(sp)
    80002be6:	6442                	ld	s0,16(sp)
    80002be8:	64a2                	ld	s1,8(sp)
    80002bea:	6105                	addi	sp,sp,32
    80002bec:	8082                	ret
    return p->trapframe->a1;
    80002bee:	6d3c                	ld	a5,88(a0)
    80002bf0:	7fa8                	ld	a0,120(a5)
    80002bf2:	bfcd                	j	80002be4 <argraw+0x30>
    return p->trapframe->a2;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	63c8                	ld	a0,128(a5)
    80002bf8:	b7f5                	j	80002be4 <argraw+0x30>
    return p->trapframe->a3;
    80002bfa:	6d3c                	ld	a5,88(a0)
    80002bfc:	67c8                	ld	a0,136(a5)
    80002bfe:	b7dd                	j	80002be4 <argraw+0x30>
    return p->trapframe->a4;
    80002c00:	6d3c                	ld	a5,88(a0)
    80002c02:	6bc8                	ld	a0,144(a5)
    80002c04:	b7c5                	j	80002be4 <argraw+0x30>
    return p->trapframe->a5;
    80002c06:	6d3c                	ld	a5,88(a0)
    80002c08:	6fc8                	ld	a0,152(a5)
    80002c0a:	bfe9                	j	80002be4 <argraw+0x30>
  panic("argraw");
    80002c0c:	00006517          	auipc	a0,0x6
    80002c10:	83c50513          	addi	a0,a0,-1988 # 80008448 <states.0+0x148>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	92c080e7          	jalr	-1748(ra) # 80000540 <panic>

0000000080002c1c <fetchaddr>:
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	e426                	sd	s1,8(sp)
    80002c24:	e04a                	sd	s2,0(sp)
    80002c26:	1000                	addi	s0,sp,32
    80002c28:	84aa                	mv	s1,a0
    80002c2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	ed0080e7          	jalr	-304(ra) # 80001afc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c34:	653c                	ld	a5,72(a0)
    80002c36:	02f4f863          	bgeu	s1,a5,80002c66 <fetchaddr+0x4a>
    80002c3a:	00848713          	addi	a4,s1,8
    80002c3e:	02e7e663          	bltu	a5,a4,80002c6a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c42:	46a1                	li	a3,8
    80002c44:	8626                	mv	a2,s1
    80002c46:	85ca                	mv	a1,s2
    80002c48:	6928                	ld	a0,80(a0)
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	bfe080e7          	jalr	-1026(ra) # 80001848 <copyin>
    80002c52:	00a03533          	snez	a0,a0
    80002c56:	40a00533          	neg	a0,a0
}
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	64a2                	ld	s1,8(sp)
    80002c60:	6902                	ld	s2,0(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret
    return -1;
    80002c66:	557d                	li	a0,-1
    80002c68:	bfcd                	j	80002c5a <fetchaddr+0x3e>
    80002c6a:	557d                	li	a0,-1
    80002c6c:	b7fd                	j	80002c5a <fetchaddr+0x3e>

0000000080002c6e <fetchstr>:
{
    80002c6e:	7179                	addi	sp,sp,-48
    80002c70:	f406                	sd	ra,40(sp)
    80002c72:	f022                	sd	s0,32(sp)
    80002c74:	ec26                	sd	s1,24(sp)
    80002c76:	e84a                	sd	s2,16(sp)
    80002c78:	e44e                	sd	s3,8(sp)
    80002c7a:	1800                	addi	s0,sp,48
    80002c7c:	892a                	mv	s2,a0
    80002c7e:	84ae                	mv	s1,a1
    80002c80:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	e7a080e7          	jalr	-390(ra) # 80001afc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c8a:	86ce                	mv	a3,s3
    80002c8c:	864a                	mv	a2,s2
    80002c8e:	85a6                	mv	a1,s1
    80002c90:	6928                	ld	a0,80(a0)
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	c44080e7          	jalr	-956(ra) # 800018d6 <copyinstr>
    80002c9a:	00054e63          	bltz	a0,80002cb6 <fetchstr+0x48>
  return strlen(buf);
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	2e4080e7          	jalr	740(ra) # 80000f84 <strlen>
}
    80002ca8:	70a2                	ld	ra,40(sp)
    80002caa:	7402                	ld	s0,32(sp)
    80002cac:	64e2                	ld	s1,24(sp)
    80002cae:	6942                	ld	s2,16(sp)
    80002cb0:	69a2                	ld	s3,8(sp)
    80002cb2:	6145                	addi	sp,sp,48
    80002cb4:	8082                	ret
    return -1;
    80002cb6:	557d                	li	a0,-1
    80002cb8:	bfc5                	j	80002ca8 <fetchstr+0x3a>

0000000080002cba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	e426                	sd	s1,8(sp)
    80002cc2:	1000                	addi	s0,sp,32
    80002cc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	eee080e7          	jalr	-274(ra) # 80002bb4 <argraw>
    80002cce:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cd0:	4501                	li	a0,0
    80002cd2:	60e2                	ld	ra,24(sp)
    80002cd4:	6442                	ld	s0,16(sp)
    80002cd6:	64a2                	ld	s1,8(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	e426                	sd	s1,8(sp)
    80002ce4:	1000                	addi	s0,sp,32
    80002ce6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	ecc080e7          	jalr	-308(ra) # 80002bb4 <argraw>
    80002cf0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cf2:	4501                	li	a0,0
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret

0000000080002cfe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cfe:	7179                	addi	sp,sp,-48
    80002d00:	f406                	sd	ra,40(sp)
    80002d02:	f022                	sd	s0,32(sp)
    80002d04:	ec26                	sd	s1,24(sp)
    80002d06:	e84a                	sd	s2,16(sp)
    80002d08:	1800                	addi	s0,sp,48
    80002d0a:	84ae                	mv	s1,a1
    80002d0c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d0e:	fd840593          	addi	a1,s0,-40
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	fca080e7          	jalr	-54(ra) # 80002cdc <argaddr>
  return fetchstr(addr, buf, max);
    80002d1a:	864a                	mv	a2,s2
    80002d1c:	85a6                	mv	a1,s1
    80002d1e:	fd843503          	ld	a0,-40(s0)
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	f4c080e7          	jalr	-180(ra) # 80002c6e <fetchstr>
}
    80002d2a:	70a2                	ld	ra,40(sp)
    80002d2c:	7402                	ld	s0,32(sp)
    80002d2e:	64e2                	ld	s1,24(sp)
    80002d30:	6942                	ld	s2,16(sp)
    80002d32:	6145                	addi	sp,sp,48
    80002d34:	8082                	ret

0000000080002d36 <syscall>:
[SYS_trace]   sys_trace,
};

void
syscall(void)
{
    80002d36:	1101                	addi	sp,sp,-32
    80002d38:	ec06                	sd	ra,24(sp)
    80002d3a:	e822                	sd	s0,16(sp)
    80002d3c:	e426                	sd	s1,8(sp)
    80002d3e:	e04a                	sd	s2,0(sp)
    80002d40:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	dba080e7          	jalr	-582(ra) # 80001afc <myproc>
    80002d4a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d4c:	05853903          	ld	s2,88(a0)
    80002d50:	0a893783          	ld	a5,168(s2)
    80002d54:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d58:	37fd                	addiw	a5,a5,-1
    80002d5a:	475d                	li	a4,23
    80002d5c:	00f76f63          	bltu	a4,a5,80002d7a <syscall+0x44>
    80002d60:	00369713          	slli	a4,a3,0x3
    80002d64:	00005797          	auipc	a5,0x5
    80002d68:	72478793          	addi	a5,a5,1828 # 80008488 <syscalls>
    80002d6c:	97ba                	add	a5,a5,a4
    80002d6e:	639c                	ld	a5,0(a5)
    80002d70:	c789                	beqz	a5,80002d7a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d72:	9782                	jalr	a5
    80002d74:	06a93823          	sd	a0,112(s2)
    80002d78:	a839                	j	80002d96 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d7a:	15848613          	addi	a2,s1,344
    80002d7e:	588c                	lw	a1,48(s1)
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	6d050513          	addi	a0,a0,1744 # 80008450 <states.0+0x150>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	802080e7          	jalr	-2046(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d90:	6cbc                	ld	a5,88(s1)
    80002d92:	577d                	li	a4,-1
    80002d94:	fbb8                	sd	a4,112(a5)
  }
}
    80002d96:	60e2                	ld	ra,24(sp)
    80002d98:	6442                	ld	s0,16(sp)
    80002d9a:	64a2                	ld	s1,8(sp)
    80002d9c:	6902                	ld	s2,0(sp)
    80002d9e:	6105                	addi	sp,sp,32
    80002da0:	8082                	ret

0000000080002da2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002daa:	fec40593          	addi	a1,s0,-20
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	f0a080e7          	jalr	-246(ra) # 80002cba <argint>
  exit(n);
    80002db8:	fec42503          	lw	a0,-20(s0)
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	51c080e7          	jalr	1308(ra) # 800022d8 <exit>
  return 0;  // not reached
}
    80002dc4:	4501                	li	a0,0
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret

0000000080002dce <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dce:	1141                	addi	sp,sp,-16
    80002dd0:	e406                	sd	ra,8(sp)
    80002dd2:	e022                	sd	s0,0(sp)
    80002dd4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	d26080e7          	jalr	-730(ra) # 80001afc <myproc>
}
    80002dde:	5908                	lw	a0,48(a0)
    80002de0:	60a2                	ld	ra,8(sp)
    80002de2:	6402                	ld	s0,0(sp)
    80002de4:	0141                	addi	sp,sp,16
    80002de6:	8082                	ret

0000000080002de8 <sys_fork>:

uint64
sys_fork(void)
{
    80002de8:	1141                	addi	sp,sp,-16
    80002dea:	e406                	sd	ra,8(sp)
    80002dec:	e022                	sd	s0,0(sp)
    80002dee:	0800                	addi	s0,sp,16
  return fork();
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	0c2080e7          	jalr	194(ra) # 80001eb2 <fork>
}
    80002df8:	60a2                	ld	ra,8(sp)
    80002dfa:	6402                	ld	s0,0(sp)
    80002dfc:	0141                	addi	sp,sp,16
    80002dfe:	8082                	ret

0000000080002e00 <sys_wait>:

uint64
sys_wait(void)
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e08:	fe840593          	addi	a1,s0,-24
    80002e0c:	4501                	li	a0,0
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	ece080e7          	jalr	-306(ra) # 80002cdc <argaddr>
  return wait(p);
    80002e16:	fe843503          	ld	a0,-24(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	664080e7          	jalr	1636(ra) # 8000247e <wait>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e34:	fdc40593          	addi	a1,s0,-36
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	e80080e7          	jalr	-384(ra) # 80002cba <argint>
  addr = myproc()->sz;
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	cba080e7          	jalr	-838(ra) # 80001afc <myproc>
    80002e4a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e4c:	fdc42503          	lw	a0,-36(s0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	006080e7          	jalr	6(ra) # 80001e56 <growproc>
    80002e58:	00054863          	bltz	a0,80002e68 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e5c:	8526                	mv	a0,s1
    80002e5e:	70a2                	ld	ra,40(sp)
    80002e60:	7402                	ld	s0,32(sp)
    80002e62:	64e2                	ld	s1,24(sp)
    80002e64:	6145                	addi	sp,sp,48
    80002e66:	8082                	ret
    return -1;
    80002e68:	54fd                	li	s1,-1
    80002e6a:	bfcd                	j	80002e5c <sys_sbrk+0x32>

0000000080002e6c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e6c:	7139                	addi	sp,sp,-64
    80002e6e:	fc06                	sd	ra,56(sp)
    80002e70:	f822                	sd	s0,48(sp)
    80002e72:	f426                	sd	s1,40(sp)
    80002e74:	f04a                	sd	s2,32(sp)
    80002e76:	ec4e                	sd	s3,24(sp)
    80002e78:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e7a:	fcc40593          	addi	a1,s0,-52
    80002e7e:	4501                	li	a0,0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	e3a080e7          	jalr	-454(ra) # 80002cba <argint>
  acquire(&tickslock);
    80002e88:	00235517          	auipc	a0,0x235
    80002e8c:	34850513          	addi	a0,a0,840 # 802381d0 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	e7c080e7          	jalr	-388(ra) # 80000d0c <acquire>
  ticks0 = ticks;
    80002e98:	00006917          	auipc	s2,0x6
    80002e9c:	a9892903          	lw	s2,-1384(s2) # 80008930 <ticks>
  while(ticks - ticks0 < n){
    80002ea0:	fcc42783          	lw	a5,-52(s0)
    80002ea4:	cf9d                	beqz	a5,80002ee2 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ea6:	00235997          	auipc	s3,0x235
    80002eaa:	32a98993          	addi	s3,s3,810 # 802381d0 <tickslock>
    80002eae:	00006497          	auipc	s1,0x6
    80002eb2:	a8248493          	addi	s1,s1,-1406 # 80008930 <ticks>
    if(killed(myproc())){
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	c46080e7          	jalr	-954(ra) # 80001afc <myproc>
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	58e080e7          	jalr	1422(ra) # 8000244c <killed>
    80002ec6:	ed15                	bnez	a0,80002f02 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ec8:	85ce                	mv	a1,s3
    80002eca:	8526                	mv	a0,s1
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	2d8080e7          	jalr	728(ra) # 800021a4 <sleep>
  while(ticks - ticks0 < n){
    80002ed4:	409c                	lw	a5,0(s1)
    80002ed6:	412787bb          	subw	a5,a5,s2
    80002eda:	fcc42703          	lw	a4,-52(s0)
    80002ede:	fce7ece3          	bltu	a5,a4,80002eb6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ee2:	00235517          	auipc	a0,0x235
    80002ee6:	2ee50513          	addi	a0,a0,750 # 802381d0 <tickslock>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	ed6080e7          	jalr	-298(ra) # 80000dc0 <release>
  return 0;
    80002ef2:	4501                	li	a0,0
}
    80002ef4:	70e2                	ld	ra,56(sp)
    80002ef6:	7442                	ld	s0,48(sp)
    80002ef8:	74a2                	ld	s1,40(sp)
    80002efa:	7902                	ld	s2,32(sp)
    80002efc:	69e2                	ld	s3,24(sp)
    80002efe:	6121                	addi	sp,sp,64
    80002f00:	8082                	ret
      release(&tickslock);
    80002f02:	00235517          	auipc	a0,0x235
    80002f06:	2ce50513          	addi	a0,a0,718 # 802381d0 <tickslock>
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	eb6080e7          	jalr	-330(ra) # 80000dc0 <release>
      return -1;
    80002f12:	557d                	li	a0,-1
    80002f14:	b7c5                	j	80002ef4 <sys_sleep+0x88>

0000000080002f16 <sys_kill>:

uint64
sys_kill(void)
{
    80002f16:	1101                	addi	sp,sp,-32
    80002f18:	ec06                	sd	ra,24(sp)
    80002f1a:	e822                	sd	s0,16(sp)
    80002f1c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f1e:	fec40593          	addi	a1,s0,-20
    80002f22:	4501                	li	a0,0
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	d96080e7          	jalr	-618(ra) # 80002cba <argint>
  return kill(pid);
    80002f2c:	fec42503          	lw	a0,-20(s0)
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	47e080e7          	jalr	1150(ra) # 800023ae <kill>
}
    80002f38:	60e2                	ld	ra,24(sp)
    80002f3a:	6442                	ld	s0,16(sp)
    80002f3c:	6105                	addi	sp,sp,32
    80002f3e:	8082                	ret

0000000080002f40 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f40:	1101                	addi	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	e426                	sd	s1,8(sp)
    80002f48:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f4a:	00235517          	auipc	a0,0x235
    80002f4e:	28650513          	addi	a0,a0,646 # 802381d0 <tickslock>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	dba080e7          	jalr	-582(ra) # 80000d0c <acquire>
  xticks = ticks;
    80002f5a:	00006497          	auipc	s1,0x6
    80002f5e:	9d64a483          	lw	s1,-1578(s1) # 80008930 <ticks>
  release(&tickslock);
    80002f62:	00235517          	auipc	a0,0x235
    80002f66:	26e50513          	addi	a0,a0,622 # 802381d0 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	e56080e7          	jalr	-426(ra) # 80000dc0 <release>
  return xticks;
}
    80002f72:	02049513          	slli	a0,s1,0x20
    80002f76:	9101                	srli	a0,a0,0x20
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	64a2                	ld	s1,8(sp)
    80002f7e:	6105                	addi	sp,sp,32
    80002f80:	8082                	ret

0000000080002f82 <sigalarm>:


uint64 sigalarm(void)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	1000                	addi	s0,sp,32
    int ticks;
    uint64 adrs;

    if(argint(0, &ticks) < 0)
    80002f8a:	fec40593          	addi	a1,s0,-20
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	d2a080e7          	jalr	-726(ra) # 80002cba <argint>
        return -1;
    80002f98:	57fd                	li	a5,-1
    if(argint(0, &ticks) < 0)
    80002f9a:	02054d63          	bltz	a0,80002fd4 <sigalarm+0x52>
    else if(argaddr(1, &adrs) < 0)
    80002f9e:	fe040593          	addi	a1,s0,-32
    80002fa2:	4505                	li	a0,1
    80002fa4:	00000097          	auipc	ra,0x0
    80002fa8:	d38080e7          	jalr	-712(ra) # 80002cdc <argaddr>
        return -1;
    80002fac:	57fd                	li	a5,-1
    else if(argaddr(1, &adrs) < 0)
    80002fae:	02054363          	bltz	a0,80002fd4 <sigalarm+0x52>

    myproc()->alarmticks = ticks;
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	b4a080e7          	jalr	-1206(ra) # 80001afc <myproc>
    80002fba:	fec42783          	lw	a5,-20(s0)
    80002fbe:	1af52223          	sw	a5,420(a0)
    myproc()->alarmhandler = adrs;
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	b3a080e7          	jalr	-1222(ra) # 80001afc <myproc>
    80002fca:	fe043783          	ld	a5,-32(s0)
    80002fce:	1af53823          	sd	a5,432(a0)

    return 0;
    80002fd2:	4781                	li	a5,0
}
    80002fd4:	853e                	mv	a0,a5
    80002fd6:	60e2                	ld	ra,24(sp)
    80002fd8:	6442                	ld	s0,16(sp)
    80002fda:	6105                	addi	sp,sp,32
    80002fdc:	8082                	ret

0000000080002fde <sigreturn>:

uint64 sigreturn(void)
{
    80002fde:	1101                	addi	sp,sp,-32
    80002fe0:	ec06                	sd	ra,24(sp)
    80002fe2:	e822                	sd	s0,16(sp)
    80002fe4:	e426                	sd	s1,8(sp)
    80002fe6:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	b14080e7          	jalr	-1260(ra) # 80001afc <myproc>
    80002ff0:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_trap, sizeof(struct trapframe));
    80002ff2:	12000613          	li	a2,288
    80002ff6:	1c053583          	ld	a1,448(a0)
    80002ffa:	6d28                	ld	a0,88(a0)
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	e68080e7          	jalr	-408(ra) # 80000e64 <memmove>
    kfree(p->alarm_trap);
    80003004:	1c04b503          	ld	a0,448(s1)
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	a58080e7          	jalr	-1448(ra) # 80000a60 <kfree>
    
    p->alarm_trap = 0; //Have to initialize
    80003010:	1c04b023          	sd	zero,448(s1)
    p->alarm_on = 0; //Have to initialize
    80003014:	1a04ac23          	sw	zero,440(s1)
    p->curticks = 0; //Have to initialize
    80003018:	1a04a423          	sw	zero,424(s1)

    return 0;
}
    8000301c:	4501                	li	a0,0
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <sys_trace>:

uint64
sys_trace(void)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0) return -1;
    80003030:	fec40593          	addi	a1,s0,-20
    80003034:	4501                	li	a0,0
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	c84080e7          	jalr	-892(ra) # 80002cba <argint>
    8000303e:	57fd                	li	a5,-1
    80003040:	02054463          	bltz	a0,80003068 <sys_trace+0x40>
  struct proc* p = myproc();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	ab8080e7          	jalr	-1352(ra) # 80001afc <myproc>
  if(mask == 0)
    8000304c:	fec42603          	lw	a2,-20(s0)
    80003050:	e20d                	bnez	a2,80003072 <sys_trace+0x4a>
    80003052:	16850793          	addi	a5,a0,360
    80003056:	1a450713          	addi	a4,a0,420
  {
    for(int i = 0; i<30; i++)
      p->trac[i] = 1;
    8000305a:	4685                	li	a3,1
    8000305c:	00d79023          	sh	a3,0(a5)
    for(int i = 0; i<30; i++)
    80003060:	0789                	addi	a5,a5,2
    80003062:	fee79de3          	bne	a5,a4,8000305c <sys_trace+0x34>
      mask = mask>>1;
      if(mask%2 != 0)
        p->trac[i] = 1;
    }
  }
  return 0;
    80003066:	4781                	li	a5,0
}
    80003068:	853e                	mv	a0,a5
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret
    80003072:	16a50713          	addi	a4,a0,362
    80003076:	1a450693          	addi	a3,a0,420
        p->trac[i] = 1;
    8000307a:	4585                	li	a1,1
    8000307c:	a021                	j	80003084 <sys_trace+0x5c>
    for(int i = 1; i<30; i++)
    8000307e:	0709                	addi	a4,a4,2
    80003080:	00d70b63          	beq	a4,a3,80003096 <sys_trace+0x6e>
      mask = mask>>1;
    80003084:	4016579b          	sraiw	a5,a2,0x1
    80003088:	0007861b          	sext.w	a2,a5
      if(mask%2 != 0)
    8000308c:	8b85                	andi	a5,a5,1
    8000308e:	dbe5                	beqz	a5,8000307e <sys_trace+0x56>
        p->trac[i] = 1;
    80003090:	00b71023          	sh	a1,0(a4)
    80003094:	b7ed                	j	8000307e <sys_trace+0x56>
  return 0;
    80003096:	4781                	li	a5,0
    80003098:	bfc1                	j	80003068 <sys_trace+0x40>

000000008000309a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000309a:	7179                	addi	sp,sp,-48
    8000309c:	f406                	sd	ra,40(sp)
    8000309e:	f022                	sd	s0,32(sp)
    800030a0:	ec26                	sd	s1,24(sp)
    800030a2:	e84a                	sd	s2,16(sp)
    800030a4:	e44e                	sd	s3,8(sp)
    800030a6:	e052                	sd	s4,0(sp)
    800030a8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030aa:	00005597          	auipc	a1,0x5
    800030ae:	4a658593          	addi	a1,a1,1190 # 80008550 <syscalls+0xc8>
    800030b2:	00235517          	auipc	a0,0x235
    800030b6:	13650513          	addi	a0,a0,310 # 802381e8 <bcache>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	bc2080e7          	jalr	-1086(ra) # 80000c7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030c2:	0023d797          	auipc	a5,0x23d
    800030c6:	12678793          	addi	a5,a5,294 # 802401e8 <bcache+0x8000>
    800030ca:	0023d717          	auipc	a4,0x23d
    800030ce:	38670713          	addi	a4,a4,902 # 80240450 <bcache+0x8268>
    800030d2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030d6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030da:	00235497          	auipc	s1,0x235
    800030de:	12648493          	addi	s1,s1,294 # 80238200 <bcache+0x18>
    b->next = bcache.head.next;
    800030e2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030e4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030e6:	00005a17          	auipc	s4,0x5
    800030ea:	472a0a13          	addi	s4,s4,1138 # 80008558 <syscalls+0xd0>
    b->next = bcache.head.next;
    800030ee:	2b893783          	ld	a5,696(s2)
    800030f2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030f4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030f8:	85d2                	mv	a1,s4
    800030fa:	01048513          	addi	a0,s1,16
    800030fe:	00001097          	auipc	ra,0x1
    80003102:	4c8080e7          	jalr	1224(ra) # 800045c6 <initsleeplock>
    bcache.head.next->prev = b;
    80003106:	2b893783          	ld	a5,696(s2)
    8000310a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000310c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003110:	45848493          	addi	s1,s1,1112
    80003114:	fd349de3          	bne	s1,s3,800030ee <binit+0x54>
  }
}
    80003118:	70a2                	ld	ra,40(sp)
    8000311a:	7402                	ld	s0,32(sp)
    8000311c:	64e2                	ld	s1,24(sp)
    8000311e:	6942                	ld	s2,16(sp)
    80003120:	69a2                	ld	s3,8(sp)
    80003122:	6a02                	ld	s4,0(sp)
    80003124:	6145                	addi	sp,sp,48
    80003126:	8082                	ret

0000000080003128 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003128:	7179                	addi	sp,sp,-48
    8000312a:	f406                	sd	ra,40(sp)
    8000312c:	f022                	sd	s0,32(sp)
    8000312e:	ec26                	sd	s1,24(sp)
    80003130:	e84a                	sd	s2,16(sp)
    80003132:	e44e                	sd	s3,8(sp)
    80003134:	1800                	addi	s0,sp,48
    80003136:	892a                	mv	s2,a0
    80003138:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000313a:	00235517          	auipc	a0,0x235
    8000313e:	0ae50513          	addi	a0,a0,174 # 802381e8 <bcache>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	bca080e7          	jalr	-1078(ra) # 80000d0c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000314a:	0023d497          	auipc	s1,0x23d
    8000314e:	3564b483          	ld	s1,854(s1) # 802404a0 <bcache+0x82b8>
    80003152:	0023d797          	auipc	a5,0x23d
    80003156:	2fe78793          	addi	a5,a5,766 # 80240450 <bcache+0x8268>
    8000315a:	02f48f63          	beq	s1,a5,80003198 <bread+0x70>
    8000315e:	873e                	mv	a4,a5
    80003160:	a021                	j	80003168 <bread+0x40>
    80003162:	68a4                	ld	s1,80(s1)
    80003164:	02e48a63          	beq	s1,a4,80003198 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003168:	449c                	lw	a5,8(s1)
    8000316a:	ff279ce3          	bne	a5,s2,80003162 <bread+0x3a>
    8000316e:	44dc                	lw	a5,12(s1)
    80003170:	ff3799e3          	bne	a5,s3,80003162 <bread+0x3a>
      b->refcnt++;
    80003174:	40bc                	lw	a5,64(s1)
    80003176:	2785                	addiw	a5,a5,1
    80003178:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000317a:	00235517          	auipc	a0,0x235
    8000317e:	06e50513          	addi	a0,a0,110 # 802381e8 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	c3e080e7          	jalr	-962(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    8000318a:	01048513          	addi	a0,s1,16
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	472080e7          	jalr	1138(ra) # 80004600 <acquiresleep>
      return b;
    80003196:	a8b9                	j	800031f4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003198:	0023d497          	auipc	s1,0x23d
    8000319c:	3004b483          	ld	s1,768(s1) # 80240498 <bcache+0x82b0>
    800031a0:	0023d797          	auipc	a5,0x23d
    800031a4:	2b078793          	addi	a5,a5,688 # 80240450 <bcache+0x8268>
    800031a8:	00f48863          	beq	s1,a5,800031b8 <bread+0x90>
    800031ac:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031ae:	40bc                	lw	a5,64(s1)
    800031b0:	cf81                	beqz	a5,800031c8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031b2:	64a4                	ld	s1,72(s1)
    800031b4:	fee49de3          	bne	s1,a4,800031ae <bread+0x86>
  panic("bget: no buffers");
    800031b8:	00005517          	auipc	a0,0x5
    800031bc:	3a850513          	addi	a0,a0,936 # 80008560 <syscalls+0xd8>
    800031c0:	ffffd097          	auipc	ra,0xffffd
    800031c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      b->dev = dev;
    800031c8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031cc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031d0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031d4:	4785                	li	a5,1
    800031d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d8:	00235517          	auipc	a0,0x235
    800031dc:	01050513          	addi	a0,a0,16 # 802381e8 <bcache>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	be0080e7          	jalr	-1056(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    800031e8:	01048513          	addi	a0,s1,16
    800031ec:	00001097          	auipc	ra,0x1
    800031f0:	414080e7          	jalr	1044(ra) # 80004600 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031f4:	409c                	lw	a5,0(s1)
    800031f6:	cb89                	beqz	a5,80003208 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031f8:	8526                	mv	a0,s1
    800031fa:	70a2                	ld	ra,40(sp)
    800031fc:	7402                	ld	s0,32(sp)
    800031fe:	64e2                	ld	s1,24(sp)
    80003200:	6942                	ld	s2,16(sp)
    80003202:	69a2                	ld	s3,8(sp)
    80003204:	6145                	addi	sp,sp,48
    80003206:	8082                	ret
    virtio_disk_rw(b, 0);
    80003208:	4581                	li	a1,0
    8000320a:	8526                	mv	a0,s1
    8000320c:	00003097          	auipc	ra,0x3
    80003210:	fd6080e7          	jalr	-42(ra) # 800061e2 <virtio_disk_rw>
    b->valid = 1;
    80003214:	4785                	li	a5,1
    80003216:	c09c                	sw	a5,0(s1)
  return b;
    80003218:	b7c5                	j	800031f8 <bread+0xd0>

000000008000321a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	1000                	addi	s0,sp,32
    80003224:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003226:	0541                	addi	a0,a0,16
    80003228:	00001097          	auipc	ra,0x1
    8000322c:	472080e7          	jalr	1138(ra) # 8000469a <holdingsleep>
    80003230:	cd01                	beqz	a0,80003248 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003232:	4585                	li	a1,1
    80003234:	8526                	mv	a0,s1
    80003236:	00003097          	auipc	ra,0x3
    8000323a:	fac080e7          	jalr	-84(ra) # 800061e2 <virtio_disk_rw>
}
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	64a2                	ld	s1,8(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
    panic("bwrite");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	33050513          	addi	a0,a0,816 # 80008578 <syscalls+0xf0>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2f0080e7          	jalr	752(ra) # 80000540 <panic>

0000000080003258 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	e04a                	sd	s2,0(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003266:	01050913          	addi	s2,a0,16
    8000326a:	854a                	mv	a0,s2
    8000326c:	00001097          	auipc	ra,0x1
    80003270:	42e080e7          	jalr	1070(ra) # 8000469a <holdingsleep>
    80003274:	c92d                	beqz	a0,800032e6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003276:	854a                	mv	a0,s2
    80003278:	00001097          	auipc	ra,0x1
    8000327c:	3de080e7          	jalr	990(ra) # 80004656 <releasesleep>

  acquire(&bcache.lock);
    80003280:	00235517          	auipc	a0,0x235
    80003284:	f6850513          	addi	a0,a0,-152 # 802381e8 <bcache>
    80003288:	ffffe097          	auipc	ra,0xffffe
    8000328c:	a84080e7          	jalr	-1404(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003290:	40bc                	lw	a5,64(s1)
    80003292:	37fd                	addiw	a5,a5,-1
    80003294:	0007871b          	sext.w	a4,a5
    80003298:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000329a:	eb05                	bnez	a4,800032ca <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000329c:	68bc                	ld	a5,80(s1)
    8000329e:	64b8                	ld	a4,72(s1)
    800032a0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032a2:	64bc                	ld	a5,72(s1)
    800032a4:	68b8                	ld	a4,80(s1)
    800032a6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032a8:	0023d797          	auipc	a5,0x23d
    800032ac:	f4078793          	addi	a5,a5,-192 # 802401e8 <bcache+0x8000>
    800032b0:	2b87b703          	ld	a4,696(a5)
    800032b4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032b6:	0023d717          	auipc	a4,0x23d
    800032ba:	19a70713          	addi	a4,a4,410 # 80240450 <bcache+0x8268>
    800032be:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032c0:	2b87b703          	ld	a4,696(a5)
    800032c4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032c6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032ca:	00235517          	auipc	a0,0x235
    800032ce:	f1e50513          	addi	a0,a0,-226 # 802381e8 <bcache>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	aee080e7          	jalr	-1298(ra) # 80000dc0 <release>
}
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6902                	ld	s2,0(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret
    panic("brelse");
    800032e6:	00005517          	auipc	a0,0x5
    800032ea:	29a50513          	addi	a0,a0,666 # 80008580 <syscalls+0xf8>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	252080e7          	jalr	594(ra) # 80000540 <panic>

00000000800032f6 <bpin>:

void
bpin(struct buf *b) {
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	1000                	addi	s0,sp,32
    80003300:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003302:	00235517          	auipc	a0,0x235
    80003306:	ee650513          	addi	a0,a0,-282 # 802381e8 <bcache>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	a02080e7          	jalr	-1534(ra) # 80000d0c <acquire>
  b->refcnt++;
    80003312:	40bc                	lw	a5,64(s1)
    80003314:	2785                	addiw	a5,a5,1
    80003316:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003318:	00235517          	auipc	a0,0x235
    8000331c:	ed050513          	addi	a0,a0,-304 # 802381e8 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	aa0080e7          	jalr	-1376(ra) # 80000dc0 <release>
}
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	64a2                	ld	s1,8(sp)
    8000332e:	6105                	addi	sp,sp,32
    80003330:	8082                	ret

0000000080003332 <bunpin>:

void
bunpin(struct buf *b) {
    80003332:	1101                	addi	sp,sp,-32
    80003334:	ec06                	sd	ra,24(sp)
    80003336:	e822                	sd	s0,16(sp)
    80003338:	e426                	sd	s1,8(sp)
    8000333a:	1000                	addi	s0,sp,32
    8000333c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000333e:	00235517          	auipc	a0,0x235
    80003342:	eaa50513          	addi	a0,a0,-342 # 802381e8 <bcache>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	9c6080e7          	jalr	-1594(ra) # 80000d0c <acquire>
  b->refcnt--;
    8000334e:	40bc                	lw	a5,64(s1)
    80003350:	37fd                	addiw	a5,a5,-1
    80003352:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003354:	00235517          	auipc	a0,0x235
    80003358:	e9450513          	addi	a0,a0,-364 # 802381e8 <bcache>
    8000335c:	ffffe097          	auipc	ra,0xffffe
    80003360:	a64080e7          	jalr	-1436(ra) # 80000dc0 <release>
}
    80003364:	60e2                	ld	ra,24(sp)
    80003366:	6442                	ld	s0,16(sp)
    80003368:	64a2                	ld	s1,8(sp)
    8000336a:	6105                	addi	sp,sp,32
    8000336c:	8082                	ret

000000008000336e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000336e:	1101                	addi	sp,sp,-32
    80003370:	ec06                	sd	ra,24(sp)
    80003372:	e822                	sd	s0,16(sp)
    80003374:	e426                	sd	s1,8(sp)
    80003376:	e04a                	sd	s2,0(sp)
    80003378:	1000                	addi	s0,sp,32
    8000337a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000337c:	00d5d59b          	srliw	a1,a1,0xd
    80003380:	0023d797          	auipc	a5,0x23d
    80003384:	5447a783          	lw	a5,1348(a5) # 802408c4 <sb+0x1c>
    80003388:	9dbd                	addw	a1,a1,a5
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	d9e080e7          	jalr	-610(ra) # 80003128 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003392:	0074f713          	andi	a4,s1,7
    80003396:	4785                	li	a5,1
    80003398:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000339c:	14ce                	slli	s1,s1,0x33
    8000339e:	90d9                	srli	s1,s1,0x36
    800033a0:	00950733          	add	a4,a0,s1
    800033a4:	05874703          	lbu	a4,88(a4)
    800033a8:	00e7f6b3          	and	a3,a5,a4
    800033ac:	c69d                	beqz	a3,800033da <bfree+0x6c>
    800033ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033b0:	94aa                	add	s1,s1,a0
    800033b2:	fff7c793          	not	a5,a5
    800033b6:	8f7d                	and	a4,a4,a5
    800033b8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800033bc:	00001097          	auipc	ra,0x1
    800033c0:	126080e7          	jalr	294(ra) # 800044e2 <log_write>
  brelse(bp);
    800033c4:	854a                	mv	a0,s2
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	e92080e7          	jalr	-366(ra) # 80003258 <brelse>
}
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	64a2                	ld	s1,8(sp)
    800033d4:	6902                	ld	s2,0(sp)
    800033d6:	6105                	addi	sp,sp,32
    800033d8:	8082                	ret
    panic("freeing free block");
    800033da:	00005517          	auipc	a0,0x5
    800033de:	1ae50513          	addi	a0,a0,430 # 80008588 <syscalls+0x100>
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	15e080e7          	jalr	350(ra) # 80000540 <panic>

00000000800033ea <balloc>:
{
    800033ea:	711d                	addi	sp,sp,-96
    800033ec:	ec86                	sd	ra,88(sp)
    800033ee:	e8a2                	sd	s0,80(sp)
    800033f0:	e4a6                	sd	s1,72(sp)
    800033f2:	e0ca                	sd	s2,64(sp)
    800033f4:	fc4e                	sd	s3,56(sp)
    800033f6:	f852                	sd	s4,48(sp)
    800033f8:	f456                	sd	s5,40(sp)
    800033fa:	f05a                	sd	s6,32(sp)
    800033fc:	ec5e                	sd	s7,24(sp)
    800033fe:	e862                	sd	s8,16(sp)
    80003400:	e466                	sd	s9,8(sp)
    80003402:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003404:	0023d797          	auipc	a5,0x23d
    80003408:	4a87a783          	lw	a5,1192(a5) # 802408ac <sb+0x4>
    8000340c:	cff5                	beqz	a5,80003508 <balloc+0x11e>
    8000340e:	8baa                	mv	s7,a0
    80003410:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003412:	0023db17          	auipc	s6,0x23d
    80003416:	496b0b13          	addi	s6,s6,1174 # 802408a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000341a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000341c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000341e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003420:	6c89                	lui	s9,0x2
    80003422:	a061                	j	800034aa <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003424:	97ca                	add	a5,a5,s2
    80003426:	8e55                	or	a2,a2,a3
    80003428:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000342c:	854a                	mv	a0,s2
    8000342e:	00001097          	auipc	ra,0x1
    80003432:	0b4080e7          	jalr	180(ra) # 800044e2 <log_write>
        brelse(bp);
    80003436:	854a                	mv	a0,s2
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	e20080e7          	jalr	-480(ra) # 80003258 <brelse>
  bp = bread(dev, bno);
    80003440:	85a6                	mv	a1,s1
    80003442:	855e                	mv	a0,s7
    80003444:	00000097          	auipc	ra,0x0
    80003448:	ce4080e7          	jalr	-796(ra) # 80003128 <bread>
    8000344c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000344e:	40000613          	li	a2,1024
    80003452:	4581                	li	a1,0
    80003454:	05850513          	addi	a0,a0,88
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	9b0080e7          	jalr	-1616(ra) # 80000e08 <memset>
  log_write(bp);
    80003460:	854a                	mv	a0,s2
    80003462:	00001097          	auipc	ra,0x1
    80003466:	080080e7          	jalr	128(ra) # 800044e2 <log_write>
  brelse(bp);
    8000346a:	854a                	mv	a0,s2
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	dec080e7          	jalr	-532(ra) # 80003258 <brelse>
}
    80003474:	8526                	mv	a0,s1
    80003476:	60e6                	ld	ra,88(sp)
    80003478:	6446                	ld	s0,80(sp)
    8000347a:	64a6                	ld	s1,72(sp)
    8000347c:	6906                	ld	s2,64(sp)
    8000347e:	79e2                	ld	s3,56(sp)
    80003480:	7a42                	ld	s4,48(sp)
    80003482:	7aa2                	ld	s5,40(sp)
    80003484:	7b02                	ld	s6,32(sp)
    80003486:	6be2                	ld	s7,24(sp)
    80003488:	6c42                	ld	s8,16(sp)
    8000348a:	6ca2                	ld	s9,8(sp)
    8000348c:	6125                	addi	sp,sp,96
    8000348e:	8082                	ret
    brelse(bp);
    80003490:	854a                	mv	a0,s2
    80003492:	00000097          	auipc	ra,0x0
    80003496:	dc6080e7          	jalr	-570(ra) # 80003258 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000349a:	015c87bb          	addw	a5,s9,s5
    8000349e:	00078a9b          	sext.w	s5,a5
    800034a2:	004b2703          	lw	a4,4(s6)
    800034a6:	06eaf163          	bgeu	s5,a4,80003508 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800034aa:	41fad79b          	sraiw	a5,s5,0x1f
    800034ae:	0137d79b          	srliw	a5,a5,0x13
    800034b2:	015787bb          	addw	a5,a5,s5
    800034b6:	40d7d79b          	sraiw	a5,a5,0xd
    800034ba:	01cb2583          	lw	a1,28(s6)
    800034be:	9dbd                	addw	a1,a1,a5
    800034c0:	855e                	mv	a0,s7
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	c66080e7          	jalr	-922(ra) # 80003128 <bread>
    800034ca:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034cc:	004b2503          	lw	a0,4(s6)
    800034d0:	000a849b          	sext.w	s1,s5
    800034d4:	8762                	mv	a4,s8
    800034d6:	faa4fde3          	bgeu	s1,a0,80003490 <balloc+0xa6>
      m = 1 << (bi % 8);
    800034da:	00777693          	andi	a3,a4,7
    800034de:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034e2:	41f7579b          	sraiw	a5,a4,0x1f
    800034e6:	01d7d79b          	srliw	a5,a5,0x1d
    800034ea:	9fb9                	addw	a5,a5,a4
    800034ec:	4037d79b          	sraiw	a5,a5,0x3
    800034f0:	00f90633          	add	a2,s2,a5
    800034f4:	05864603          	lbu	a2,88(a2)
    800034f8:	00c6f5b3          	and	a1,a3,a2
    800034fc:	d585                	beqz	a1,80003424 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fe:	2705                	addiw	a4,a4,1
    80003500:	2485                	addiw	s1,s1,1
    80003502:	fd471ae3          	bne	a4,s4,800034d6 <balloc+0xec>
    80003506:	b769                	j	80003490 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	09850513          	addi	a0,a0,152 # 800085a0 <syscalls+0x118>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	07a080e7          	jalr	122(ra) # 8000058a <printf>
  return 0;
    80003518:	4481                	li	s1,0
    8000351a:	bfa9                	j	80003474 <balloc+0x8a>

000000008000351c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000351c:	7179                	addi	sp,sp,-48
    8000351e:	f406                	sd	ra,40(sp)
    80003520:	f022                	sd	s0,32(sp)
    80003522:	ec26                	sd	s1,24(sp)
    80003524:	e84a                	sd	s2,16(sp)
    80003526:	e44e                	sd	s3,8(sp)
    80003528:	e052                	sd	s4,0(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000352e:	47ad                	li	a5,11
    80003530:	02b7e863          	bltu	a5,a1,80003560 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003534:	02059793          	slli	a5,a1,0x20
    80003538:	01e7d593          	srli	a1,a5,0x1e
    8000353c:	00b504b3          	add	s1,a0,a1
    80003540:	0504a903          	lw	s2,80(s1)
    80003544:	06091e63          	bnez	s2,800035c0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003548:	4108                	lw	a0,0(a0)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	ea0080e7          	jalr	-352(ra) # 800033ea <balloc>
    80003552:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003556:	06090563          	beqz	s2,800035c0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000355a:	0524a823          	sw	s2,80(s1)
    8000355e:	a08d                	j	800035c0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003560:	ff45849b          	addiw	s1,a1,-12
    80003564:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003568:	0ff00793          	li	a5,255
    8000356c:	08e7e563          	bltu	a5,a4,800035f6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003570:	08052903          	lw	s2,128(a0)
    80003574:	00091d63          	bnez	s2,8000358e <bmap+0x72>
      addr = balloc(ip->dev);
    80003578:	4108                	lw	a0,0(a0)
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	e70080e7          	jalr	-400(ra) # 800033ea <balloc>
    80003582:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003586:	02090d63          	beqz	s2,800035c0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000358a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000358e:	85ca                	mv	a1,s2
    80003590:	0009a503          	lw	a0,0(s3)
    80003594:	00000097          	auipc	ra,0x0
    80003598:	b94080e7          	jalr	-1132(ra) # 80003128 <bread>
    8000359c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000359e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035a2:	02049713          	slli	a4,s1,0x20
    800035a6:	01e75593          	srli	a1,a4,0x1e
    800035aa:	00b784b3          	add	s1,a5,a1
    800035ae:	0004a903          	lw	s2,0(s1)
    800035b2:	02090063          	beqz	s2,800035d2 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035b6:	8552                	mv	a0,s4
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	ca0080e7          	jalr	-864(ra) # 80003258 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035c0:	854a                	mv	a0,s2
    800035c2:	70a2                	ld	ra,40(sp)
    800035c4:	7402                	ld	s0,32(sp)
    800035c6:	64e2                	ld	s1,24(sp)
    800035c8:	6942                	ld	s2,16(sp)
    800035ca:	69a2                	ld	s3,8(sp)
    800035cc:	6a02                	ld	s4,0(sp)
    800035ce:	6145                	addi	sp,sp,48
    800035d0:	8082                	ret
      addr = balloc(ip->dev);
    800035d2:	0009a503          	lw	a0,0(s3)
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	e14080e7          	jalr	-492(ra) # 800033ea <balloc>
    800035de:	0005091b          	sext.w	s2,a0
      if(addr){
    800035e2:	fc090ae3          	beqz	s2,800035b6 <bmap+0x9a>
        a[bn] = addr;
    800035e6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035ea:	8552                	mv	a0,s4
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	ef6080e7          	jalr	-266(ra) # 800044e2 <log_write>
    800035f4:	b7c9                	j	800035b6 <bmap+0x9a>
  panic("bmap: out of range");
    800035f6:	00005517          	auipc	a0,0x5
    800035fa:	fc250513          	addi	a0,a0,-62 # 800085b8 <syscalls+0x130>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	f42080e7          	jalr	-190(ra) # 80000540 <panic>

0000000080003606 <iget>:
{
    80003606:	7179                	addi	sp,sp,-48
    80003608:	f406                	sd	ra,40(sp)
    8000360a:	f022                	sd	s0,32(sp)
    8000360c:	ec26                	sd	s1,24(sp)
    8000360e:	e84a                	sd	s2,16(sp)
    80003610:	e44e                	sd	s3,8(sp)
    80003612:	e052                	sd	s4,0(sp)
    80003614:	1800                	addi	s0,sp,48
    80003616:	89aa                	mv	s3,a0
    80003618:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000361a:	0023d517          	auipc	a0,0x23d
    8000361e:	2ae50513          	addi	a0,a0,686 # 802408c8 <itable>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	6ea080e7          	jalr	1770(ra) # 80000d0c <acquire>
  empty = 0;
    8000362a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000362c:	0023d497          	auipc	s1,0x23d
    80003630:	2b448493          	addi	s1,s1,692 # 802408e0 <itable+0x18>
    80003634:	0023f697          	auipc	a3,0x23f
    80003638:	d3c68693          	addi	a3,a3,-708 # 80242370 <log>
    8000363c:	a039                	j	8000364a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363e:	02090b63          	beqz	s2,80003674 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003642:	08848493          	addi	s1,s1,136
    80003646:	02d48a63          	beq	s1,a3,8000367a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000364a:	449c                	lw	a5,8(s1)
    8000364c:	fef059e3          	blez	a5,8000363e <iget+0x38>
    80003650:	4098                	lw	a4,0(s1)
    80003652:	ff3716e3          	bne	a4,s3,8000363e <iget+0x38>
    80003656:	40d8                	lw	a4,4(s1)
    80003658:	ff4713e3          	bne	a4,s4,8000363e <iget+0x38>
      ip->ref++;
    8000365c:	2785                	addiw	a5,a5,1
    8000365e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003660:	0023d517          	auipc	a0,0x23d
    80003664:	26850513          	addi	a0,a0,616 # 802408c8 <itable>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	758080e7          	jalr	1880(ra) # 80000dc0 <release>
      return ip;
    80003670:	8926                	mv	s2,s1
    80003672:	a03d                	j	800036a0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003674:	f7f9                	bnez	a5,80003642 <iget+0x3c>
    80003676:	8926                	mv	s2,s1
    80003678:	b7e9                	j	80003642 <iget+0x3c>
  if(empty == 0)
    8000367a:	02090c63          	beqz	s2,800036b2 <iget+0xac>
  ip->dev = dev;
    8000367e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003682:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003686:	4785                	li	a5,1
    80003688:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000368c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003690:	0023d517          	auipc	a0,0x23d
    80003694:	23850513          	addi	a0,a0,568 # 802408c8 <itable>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	728080e7          	jalr	1832(ra) # 80000dc0 <release>
}
    800036a0:	854a                	mv	a0,s2
    800036a2:	70a2                	ld	ra,40(sp)
    800036a4:	7402                	ld	s0,32(sp)
    800036a6:	64e2                	ld	s1,24(sp)
    800036a8:	6942                	ld	s2,16(sp)
    800036aa:	69a2                	ld	s3,8(sp)
    800036ac:	6a02                	ld	s4,0(sp)
    800036ae:	6145                	addi	sp,sp,48
    800036b0:	8082                	ret
    panic("iget: no inodes");
    800036b2:	00005517          	auipc	a0,0x5
    800036b6:	f1e50513          	addi	a0,a0,-226 # 800085d0 <syscalls+0x148>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	e86080e7          	jalr	-378(ra) # 80000540 <panic>

00000000800036c2 <fsinit>:
fsinit(int dev) {
    800036c2:	7179                	addi	sp,sp,-48
    800036c4:	f406                	sd	ra,40(sp)
    800036c6:	f022                	sd	s0,32(sp)
    800036c8:	ec26                	sd	s1,24(sp)
    800036ca:	e84a                	sd	s2,16(sp)
    800036cc:	e44e                	sd	s3,8(sp)
    800036ce:	1800                	addi	s0,sp,48
    800036d0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036d2:	4585                	li	a1,1
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	a54080e7          	jalr	-1452(ra) # 80003128 <bread>
    800036dc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036de:	0023d997          	auipc	s3,0x23d
    800036e2:	1ca98993          	addi	s3,s3,458 # 802408a8 <sb>
    800036e6:	02000613          	li	a2,32
    800036ea:	05850593          	addi	a1,a0,88
    800036ee:	854e                	mv	a0,s3
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	774080e7          	jalr	1908(ra) # 80000e64 <memmove>
  brelse(bp);
    800036f8:	8526                	mv	a0,s1
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	b5e080e7          	jalr	-1186(ra) # 80003258 <brelse>
  if(sb.magic != FSMAGIC)
    80003702:	0009a703          	lw	a4,0(s3)
    80003706:	102037b7          	lui	a5,0x10203
    8000370a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000370e:	02f71263          	bne	a4,a5,80003732 <fsinit+0x70>
  initlog(dev, &sb);
    80003712:	0023d597          	auipc	a1,0x23d
    80003716:	19658593          	addi	a1,a1,406 # 802408a8 <sb>
    8000371a:	854a                	mv	a0,s2
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	b4a080e7          	jalr	-1206(ra) # 80004266 <initlog>
}
    80003724:	70a2                	ld	ra,40(sp)
    80003726:	7402                	ld	s0,32(sp)
    80003728:	64e2                	ld	s1,24(sp)
    8000372a:	6942                	ld	s2,16(sp)
    8000372c:	69a2                	ld	s3,8(sp)
    8000372e:	6145                	addi	sp,sp,48
    80003730:	8082                	ret
    panic("invalid file system");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	eae50513          	addi	a0,a0,-338 # 800085e0 <syscalls+0x158>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e06080e7          	jalr	-506(ra) # 80000540 <panic>

0000000080003742 <iinit>:
{
    80003742:	7179                	addi	sp,sp,-48
    80003744:	f406                	sd	ra,40(sp)
    80003746:	f022                	sd	s0,32(sp)
    80003748:	ec26                	sd	s1,24(sp)
    8000374a:	e84a                	sd	s2,16(sp)
    8000374c:	e44e                	sd	s3,8(sp)
    8000374e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003750:	00005597          	auipc	a1,0x5
    80003754:	ea858593          	addi	a1,a1,-344 # 800085f8 <syscalls+0x170>
    80003758:	0023d517          	auipc	a0,0x23d
    8000375c:	17050513          	addi	a0,a0,368 # 802408c8 <itable>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	51c080e7          	jalr	1308(ra) # 80000c7c <initlock>
  for(i = 0; i < NINODE; i++) {
    80003768:	0023d497          	auipc	s1,0x23d
    8000376c:	18848493          	addi	s1,s1,392 # 802408f0 <itable+0x28>
    80003770:	0023f997          	auipc	s3,0x23f
    80003774:	c1098993          	addi	s3,s3,-1008 # 80242380 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003778:	00005917          	auipc	s2,0x5
    8000377c:	e8890913          	addi	s2,s2,-376 # 80008600 <syscalls+0x178>
    80003780:	85ca                	mv	a1,s2
    80003782:	8526                	mv	a0,s1
    80003784:	00001097          	auipc	ra,0x1
    80003788:	e42080e7          	jalr	-446(ra) # 800045c6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000378c:	08848493          	addi	s1,s1,136
    80003790:	ff3498e3          	bne	s1,s3,80003780 <iinit+0x3e>
}
    80003794:	70a2                	ld	ra,40(sp)
    80003796:	7402                	ld	s0,32(sp)
    80003798:	64e2                	ld	s1,24(sp)
    8000379a:	6942                	ld	s2,16(sp)
    8000379c:	69a2                	ld	s3,8(sp)
    8000379e:	6145                	addi	sp,sp,48
    800037a0:	8082                	ret

00000000800037a2 <ialloc>:
{
    800037a2:	715d                	addi	sp,sp,-80
    800037a4:	e486                	sd	ra,72(sp)
    800037a6:	e0a2                	sd	s0,64(sp)
    800037a8:	fc26                	sd	s1,56(sp)
    800037aa:	f84a                	sd	s2,48(sp)
    800037ac:	f44e                	sd	s3,40(sp)
    800037ae:	f052                	sd	s4,32(sp)
    800037b0:	ec56                	sd	s5,24(sp)
    800037b2:	e85a                	sd	s6,16(sp)
    800037b4:	e45e                	sd	s7,8(sp)
    800037b6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b8:	0023d717          	auipc	a4,0x23d
    800037bc:	0fc72703          	lw	a4,252(a4) # 802408b4 <sb+0xc>
    800037c0:	4785                	li	a5,1
    800037c2:	04e7fa63          	bgeu	a5,a4,80003816 <ialloc+0x74>
    800037c6:	8aaa                	mv	s5,a0
    800037c8:	8bae                	mv	s7,a1
    800037ca:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037cc:	0023da17          	auipc	s4,0x23d
    800037d0:	0dca0a13          	addi	s4,s4,220 # 802408a8 <sb>
    800037d4:	00048b1b          	sext.w	s6,s1
    800037d8:	0044d593          	srli	a1,s1,0x4
    800037dc:	018a2783          	lw	a5,24(s4)
    800037e0:	9dbd                	addw	a1,a1,a5
    800037e2:	8556                	mv	a0,s5
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	944080e7          	jalr	-1724(ra) # 80003128 <bread>
    800037ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037ee:	05850993          	addi	s3,a0,88
    800037f2:	00f4f793          	andi	a5,s1,15
    800037f6:	079a                	slli	a5,a5,0x6
    800037f8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037fa:	00099783          	lh	a5,0(s3)
    800037fe:	c3a1                	beqz	a5,8000383e <ialloc+0x9c>
    brelse(bp);
    80003800:	00000097          	auipc	ra,0x0
    80003804:	a58080e7          	jalr	-1448(ra) # 80003258 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003808:	0485                	addi	s1,s1,1
    8000380a:	00ca2703          	lw	a4,12(s4)
    8000380e:	0004879b          	sext.w	a5,s1
    80003812:	fce7e1e3          	bltu	a5,a4,800037d4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003816:	00005517          	auipc	a0,0x5
    8000381a:	df250513          	addi	a0,a0,-526 # 80008608 <syscalls+0x180>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	d6c080e7          	jalr	-660(ra) # 8000058a <printf>
  return 0;
    80003826:	4501                	li	a0,0
}
    80003828:	60a6                	ld	ra,72(sp)
    8000382a:	6406                	ld	s0,64(sp)
    8000382c:	74e2                	ld	s1,56(sp)
    8000382e:	7942                	ld	s2,48(sp)
    80003830:	79a2                	ld	s3,40(sp)
    80003832:	7a02                	ld	s4,32(sp)
    80003834:	6ae2                	ld	s5,24(sp)
    80003836:	6b42                	ld	s6,16(sp)
    80003838:	6ba2                	ld	s7,8(sp)
    8000383a:	6161                	addi	sp,sp,80
    8000383c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000383e:	04000613          	li	a2,64
    80003842:	4581                	li	a1,0
    80003844:	854e                	mv	a0,s3
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	5c2080e7          	jalr	1474(ra) # 80000e08 <memset>
      dip->type = type;
    8000384e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003852:	854a                	mv	a0,s2
    80003854:	00001097          	auipc	ra,0x1
    80003858:	c8e080e7          	jalr	-882(ra) # 800044e2 <log_write>
      brelse(bp);
    8000385c:	854a                	mv	a0,s2
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	9fa080e7          	jalr	-1542(ra) # 80003258 <brelse>
      return iget(dev, inum);
    80003866:	85da                	mv	a1,s6
    80003868:	8556                	mv	a0,s5
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	d9c080e7          	jalr	-612(ra) # 80003606 <iget>
    80003872:	bf5d                	j	80003828 <ialloc+0x86>

0000000080003874 <iupdate>:
{
    80003874:	1101                	addi	sp,sp,-32
    80003876:	ec06                	sd	ra,24(sp)
    80003878:	e822                	sd	s0,16(sp)
    8000387a:	e426                	sd	s1,8(sp)
    8000387c:	e04a                	sd	s2,0(sp)
    8000387e:	1000                	addi	s0,sp,32
    80003880:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003882:	415c                	lw	a5,4(a0)
    80003884:	0047d79b          	srliw	a5,a5,0x4
    80003888:	0023d597          	auipc	a1,0x23d
    8000388c:	0385a583          	lw	a1,56(a1) # 802408c0 <sb+0x18>
    80003890:	9dbd                	addw	a1,a1,a5
    80003892:	4108                	lw	a0,0(a0)
    80003894:	00000097          	auipc	ra,0x0
    80003898:	894080e7          	jalr	-1900(ra) # 80003128 <bread>
    8000389c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389e:	05850793          	addi	a5,a0,88
    800038a2:	40d8                	lw	a4,4(s1)
    800038a4:	8b3d                	andi	a4,a4,15
    800038a6:	071a                	slli	a4,a4,0x6
    800038a8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038aa:	04449703          	lh	a4,68(s1)
    800038ae:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038b2:	04649703          	lh	a4,70(s1)
    800038b6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038ba:	04849703          	lh	a4,72(s1)
    800038be:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038c2:	04a49703          	lh	a4,74(s1)
    800038c6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800038ca:	44f8                	lw	a4,76(s1)
    800038cc:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038ce:	03400613          	li	a2,52
    800038d2:	05048593          	addi	a1,s1,80
    800038d6:	00c78513          	addi	a0,a5,12
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	58a080e7          	jalr	1418(ra) # 80000e64 <memmove>
  log_write(bp);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00001097          	auipc	ra,0x1
    800038e8:	bfe080e7          	jalr	-1026(ra) # 800044e2 <log_write>
  brelse(bp);
    800038ec:	854a                	mv	a0,s2
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	96a080e7          	jalr	-1686(ra) # 80003258 <brelse>
}
    800038f6:	60e2                	ld	ra,24(sp)
    800038f8:	6442                	ld	s0,16(sp)
    800038fa:	64a2                	ld	s1,8(sp)
    800038fc:	6902                	ld	s2,0(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <idup>:
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	1000                	addi	s0,sp,32
    8000390c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000390e:	0023d517          	auipc	a0,0x23d
    80003912:	fba50513          	addi	a0,a0,-70 # 802408c8 <itable>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	3f6080e7          	jalr	1014(ra) # 80000d0c <acquire>
  ip->ref++;
    8000391e:	449c                	lw	a5,8(s1)
    80003920:	2785                	addiw	a5,a5,1
    80003922:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003924:	0023d517          	auipc	a0,0x23d
    80003928:	fa450513          	addi	a0,a0,-92 # 802408c8 <itable>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	494080e7          	jalr	1172(ra) # 80000dc0 <release>
}
    80003934:	8526                	mv	a0,s1
    80003936:	60e2                	ld	ra,24(sp)
    80003938:	6442                	ld	s0,16(sp)
    8000393a:	64a2                	ld	s1,8(sp)
    8000393c:	6105                	addi	sp,sp,32
    8000393e:	8082                	ret

0000000080003940 <ilock>:
{
    80003940:	1101                	addi	sp,sp,-32
    80003942:	ec06                	sd	ra,24(sp)
    80003944:	e822                	sd	s0,16(sp)
    80003946:	e426                	sd	s1,8(sp)
    80003948:	e04a                	sd	s2,0(sp)
    8000394a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000394c:	c115                	beqz	a0,80003970 <ilock+0x30>
    8000394e:	84aa                	mv	s1,a0
    80003950:	451c                	lw	a5,8(a0)
    80003952:	00f05f63          	blez	a5,80003970 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003956:	0541                	addi	a0,a0,16
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	ca8080e7          	jalr	-856(ra) # 80004600 <acquiresleep>
  if(ip->valid == 0){
    80003960:	40bc                	lw	a5,64(s1)
    80003962:	cf99                	beqz	a5,80003980 <ilock+0x40>
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6902                	ld	s2,0(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret
    panic("ilock");
    80003970:	00005517          	auipc	a0,0x5
    80003974:	cb050513          	addi	a0,a0,-848 # 80008620 <syscalls+0x198>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	bc8080e7          	jalr	-1080(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003980:	40dc                	lw	a5,4(s1)
    80003982:	0047d79b          	srliw	a5,a5,0x4
    80003986:	0023d597          	auipc	a1,0x23d
    8000398a:	f3a5a583          	lw	a1,-198(a1) # 802408c0 <sb+0x18>
    8000398e:	9dbd                	addw	a1,a1,a5
    80003990:	4088                	lw	a0,0(s1)
    80003992:	fffff097          	auipc	ra,0xfffff
    80003996:	796080e7          	jalr	1942(ra) # 80003128 <bread>
    8000399a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000399c:	05850593          	addi	a1,a0,88
    800039a0:	40dc                	lw	a5,4(s1)
    800039a2:	8bbd                	andi	a5,a5,15
    800039a4:	079a                	slli	a5,a5,0x6
    800039a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039a8:	00059783          	lh	a5,0(a1)
    800039ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039b0:	00259783          	lh	a5,2(a1)
    800039b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039b8:	00459783          	lh	a5,4(a1)
    800039bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039c0:	00659783          	lh	a5,6(a1)
    800039c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039c8:	459c                	lw	a5,8(a1)
    800039ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039cc:	03400613          	li	a2,52
    800039d0:	05b1                	addi	a1,a1,12
    800039d2:	05048513          	addi	a0,s1,80
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	48e080e7          	jalr	1166(ra) # 80000e64 <memmove>
    brelse(bp);
    800039de:	854a                	mv	a0,s2
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	878080e7          	jalr	-1928(ra) # 80003258 <brelse>
    ip->valid = 1;
    800039e8:	4785                	li	a5,1
    800039ea:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ec:	04449783          	lh	a5,68(s1)
    800039f0:	fbb5                	bnez	a5,80003964 <ilock+0x24>
      panic("ilock: no type");
    800039f2:	00005517          	auipc	a0,0x5
    800039f6:	c3650513          	addi	a0,a0,-970 # 80008628 <syscalls+0x1a0>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	b46080e7          	jalr	-1210(ra) # 80000540 <panic>

0000000080003a02 <iunlock>:
{
    80003a02:	1101                	addi	sp,sp,-32
    80003a04:	ec06                	sd	ra,24(sp)
    80003a06:	e822                	sd	s0,16(sp)
    80003a08:	e426                	sd	s1,8(sp)
    80003a0a:	e04a                	sd	s2,0(sp)
    80003a0c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a0e:	c905                	beqz	a0,80003a3e <iunlock+0x3c>
    80003a10:	84aa                	mv	s1,a0
    80003a12:	01050913          	addi	s2,a0,16
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	c82080e7          	jalr	-894(ra) # 8000469a <holdingsleep>
    80003a20:	cd19                	beqz	a0,80003a3e <iunlock+0x3c>
    80003a22:	449c                	lw	a5,8(s1)
    80003a24:	00f05d63          	blez	a5,80003a3e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a28:	854a                	mv	a0,s2
    80003a2a:	00001097          	auipc	ra,0x1
    80003a2e:	c2c080e7          	jalr	-980(ra) # 80004656 <releasesleep>
}
    80003a32:	60e2                	ld	ra,24(sp)
    80003a34:	6442                	ld	s0,16(sp)
    80003a36:	64a2                	ld	s1,8(sp)
    80003a38:	6902                	ld	s2,0(sp)
    80003a3a:	6105                	addi	sp,sp,32
    80003a3c:	8082                	ret
    panic("iunlock");
    80003a3e:	00005517          	auipc	a0,0x5
    80003a42:	bfa50513          	addi	a0,a0,-1030 # 80008638 <syscalls+0x1b0>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	afa080e7          	jalr	-1286(ra) # 80000540 <panic>

0000000080003a4e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a4e:	7179                	addi	sp,sp,-48
    80003a50:	f406                	sd	ra,40(sp)
    80003a52:	f022                	sd	s0,32(sp)
    80003a54:	ec26                	sd	s1,24(sp)
    80003a56:	e84a                	sd	s2,16(sp)
    80003a58:	e44e                	sd	s3,8(sp)
    80003a5a:	e052                	sd	s4,0(sp)
    80003a5c:	1800                	addi	s0,sp,48
    80003a5e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a60:	05050493          	addi	s1,a0,80
    80003a64:	08050913          	addi	s2,a0,128
    80003a68:	a021                	j	80003a70 <itrunc+0x22>
    80003a6a:	0491                	addi	s1,s1,4
    80003a6c:	01248d63          	beq	s1,s2,80003a86 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a70:	408c                	lw	a1,0(s1)
    80003a72:	dde5                	beqz	a1,80003a6a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a74:	0009a503          	lw	a0,0(s3)
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	8f6080e7          	jalr	-1802(ra) # 8000336e <bfree>
      ip->addrs[i] = 0;
    80003a80:	0004a023          	sw	zero,0(s1)
    80003a84:	b7dd                	j	80003a6a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a86:	0809a583          	lw	a1,128(s3)
    80003a8a:	e185                	bnez	a1,80003aaa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a8c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a90:	854e                	mv	a0,s3
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	de2080e7          	jalr	-542(ra) # 80003874 <iupdate>
}
    80003a9a:	70a2                	ld	ra,40(sp)
    80003a9c:	7402                	ld	s0,32(sp)
    80003a9e:	64e2                	ld	s1,24(sp)
    80003aa0:	6942                	ld	s2,16(sp)
    80003aa2:	69a2                	ld	s3,8(sp)
    80003aa4:	6a02                	ld	s4,0(sp)
    80003aa6:	6145                	addi	sp,sp,48
    80003aa8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aaa:	0009a503          	lw	a0,0(s3)
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	67a080e7          	jalr	1658(ra) # 80003128 <bread>
    80003ab6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ab8:	05850493          	addi	s1,a0,88
    80003abc:	45850913          	addi	s2,a0,1112
    80003ac0:	a021                	j	80003ac8 <itrunc+0x7a>
    80003ac2:	0491                	addi	s1,s1,4
    80003ac4:	01248b63          	beq	s1,s2,80003ada <itrunc+0x8c>
      if(a[j])
    80003ac8:	408c                	lw	a1,0(s1)
    80003aca:	dde5                	beqz	a1,80003ac2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003acc:	0009a503          	lw	a0,0(s3)
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	89e080e7          	jalr	-1890(ra) # 8000336e <bfree>
    80003ad8:	b7ed                	j	80003ac2 <itrunc+0x74>
    brelse(bp);
    80003ada:	8552                	mv	a0,s4
    80003adc:	fffff097          	auipc	ra,0xfffff
    80003ae0:	77c080e7          	jalr	1916(ra) # 80003258 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ae4:	0809a583          	lw	a1,128(s3)
    80003ae8:	0009a503          	lw	a0,0(s3)
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	882080e7          	jalr	-1918(ra) # 8000336e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003af4:	0809a023          	sw	zero,128(s3)
    80003af8:	bf51                	j	80003a8c <itrunc+0x3e>

0000000080003afa <iput>:
{
    80003afa:	1101                	addi	sp,sp,-32
    80003afc:	ec06                	sd	ra,24(sp)
    80003afe:	e822                	sd	s0,16(sp)
    80003b00:	e426                	sd	s1,8(sp)
    80003b02:	e04a                	sd	s2,0(sp)
    80003b04:	1000                	addi	s0,sp,32
    80003b06:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b08:	0023d517          	auipc	a0,0x23d
    80003b0c:	dc050513          	addi	a0,a0,-576 # 802408c8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	1fc080e7          	jalr	508(ra) # 80000d0c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b18:	4498                	lw	a4,8(s1)
    80003b1a:	4785                	li	a5,1
    80003b1c:	02f70363          	beq	a4,a5,80003b42 <iput+0x48>
  ip->ref--;
    80003b20:	449c                	lw	a5,8(s1)
    80003b22:	37fd                	addiw	a5,a5,-1
    80003b24:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b26:	0023d517          	auipc	a0,0x23d
    80003b2a:	da250513          	addi	a0,a0,-606 # 802408c8 <itable>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	292080e7          	jalr	658(ra) # 80000dc0 <release>
}
    80003b36:	60e2                	ld	ra,24(sp)
    80003b38:	6442                	ld	s0,16(sp)
    80003b3a:	64a2                	ld	s1,8(sp)
    80003b3c:	6902                	ld	s2,0(sp)
    80003b3e:	6105                	addi	sp,sp,32
    80003b40:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b42:	40bc                	lw	a5,64(s1)
    80003b44:	dff1                	beqz	a5,80003b20 <iput+0x26>
    80003b46:	04a49783          	lh	a5,74(s1)
    80003b4a:	fbf9                	bnez	a5,80003b20 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b4c:	01048913          	addi	s2,s1,16
    80003b50:	854a                	mv	a0,s2
    80003b52:	00001097          	auipc	ra,0x1
    80003b56:	aae080e7          	jalr	-1362(ra) # 80004600 <acquiresleep>
    release(&itable.lock);
    80003b5a:	0023d517          	auipc	a0,0x23d
    80003b5e:	d6e50513          	addi	a0,a0,-658 # 802408c8 <itable>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	25e080e7          	jalr	606(ra) # 80000dc0 <release>
    itrunc(ip);
    80003b6a:	8526                	mv	a0,s1
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	ee2080e7          	jalr	-286(ra) # 80003a4e <itrunc>
    ip->type = 0;
    80003b74:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b78:	8526                	mv	a0,s1
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	cfa080e7          	jalr	-774(ra) # 80003874 <iupdate>
    ip->valid = 0;
    80003b82:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b86:	854a                	mv	a0,s2
    80003b88:	00001097          	auipc	ra,0x1
    80003b8c:	ace080e7          	jalr	-1330(ra) # 80004656 <releasesleep>
    acquire(&itable.lock);
    80003b90:	0023d517          	auipc	a0,0x23d
    80003b94:	d3850513          	addi	a0,a0,-712 # 802408c8 <itable>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	174080e7          	jalr	372(ra) # 80000d0c <acquire>
    80003ba0:	b741                	j	80003b20 <iput+0x26>

0000000080003ba2 <iunlockput>:
{
    80003ba2:	1101                	addi	sp,sp,-32
    80003ba4:	ec06                	sd	ra,24(sp)
    80003ba6:	e822                	sd	s0,16(sp)
    80003ba8:	e426                	sd	s1,8(sp)
    80003baa:	1000                	addi	s0,sp,32
    80003bac:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	e54080e7          	jalr	-428(ra) # 80003a02 <iunlock>
  iput(ip);
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	f42080e7          	jalr	-190(ra) # 80003afa <iput>
}
    80003bc0:	60e2                	ld	ra,24(sp)
    80003bc2:	6442                	ld	s0,16(sp)
    80003bc4:	64a2                	ld	s1,8(sp)
    80003bc6:	6105                	addi	sp,sp,32
    80003bc8:	8082                	ret

0000000080003bca <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bca:	1141                	addi	sp,sp,-16
    80003bcc:	e422                	sd	s0,8(sp)
    80003bce:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bd0:	411c                	lw	a5,0(a0)
    80003bd2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bd4:	415c                	lw	a5,4(a0)
    80003bd6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bd8:	04451783          	lh	a5,68(a0)
    80003bdc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003be0:	04a51783          	lh	a5,74(a0)
    80003be4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003be8:	04c56783          	lwu	a5,76(a0)
    80003bec:	e99c                	sd	a5,16(a1)
}
    80003bee:	6422                	ld	s0,8(sp)
    80003bf0:	0141                	addi	sp,sp,16
    80003bf2:	8082                	ret

0000000080003bf4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bf4:	457c                	lw	a5,76(a0)
    80003bf6:	0ed7e963          	bltu	a5,a3,80003ce8 <readi+0xf4>
{
    80003bfa:	7159                	addi	sp,sp,-112
    80003bfc:	f486                	sd	ra,104(sp)
    80003bfe:	f0a2                	sd	s0,96(sp)
    80003c00:	eca6                	sd	s1,88(sp)
    80003c02:	e8ca                	sd	s2,80(sp)
    80003c04:	e4ce                	sd	s3,72(sp)
    80003c06:	e0d2                	sd	s4,64(sp)
    80003c08:	fc56                	sd	s5,56(sp)
    80003c0a:	f85a                	sd	s6,48(sp)
    80003c0c:	f45e                	sd	s7,40(sp)
    80003c0e:	f062                	sd	s8,32(sp)
    80003c10:	ec66                	sd	s9,24(sp)
    80003c12:	e86a                	sd	s10,16(sp)
    80003c14:	e46e                	sd	s11,8(sp)
    80003c16:	1880                	addi	s0,sp,112
    80003c18:	8b2a                	mv	s6,a0
    80003c1a:	8bae                	mv	s7,a1
    80003c1c:	8a32                	mv	s4,a2
    80003c1e:	84b6                	mv	s1,a3
    80003c20:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c22:	9f35                	addw	a4,a4,a3
    return 0;
    80003c24:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c26:	0ad76063          	bltu	a4,a3,80003cc6 <readi+0xd2>
  if(off + n > ip->size)
    80003c2a:	00e7f463          	bgeu	a5,a4,80003c32 <readi+0x3e>
    n = ip->size - off;
    80003c2e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c32:	0a0a8963          	beqz	s5,80003ce4 <readi+0xf0>
    80003c36:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c38:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c3c:	5c7d                	li	s8,-1
    80003c3e:	a82d                	j	80003c78 <readi+0x84>
    80003c40:	020d1d93          	slli	s11,s10,0x20
    80003c44:	020ddd93          	srli	s11,s11,0x20
    80003c48:	05890613          	addi	a2,s2,88
    80003c4c:	86ee                	mv	a3,s11
    80003c4e:	963a                	add	a2,a2,a4
    80003c50:	85d2                	mv	a1,s4
    80003c52:	855e                	mv	a0,s7
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	958080e7          	jalr	-1704(ra) # 800025ac <either_copyout>
    80003c5c:	05850d63          	beq	a0,s8,80003cb6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c60:	854a                	mv	a0,s2
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	5f6080e7          	jalr	1526(ra) # 80003258 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c6a:	013d09bb          	addw	s3,s10,s3
    80003c6e:	009d04bb          	addw	s1,s10,s1
    80003c72:	9a6e                	add	s4,s4,s11
    80003c74:	0559f763          	bgeu	s3,s5,80003cc2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c78:	00a4d59b          	srliw	a1,s1,0xa
    80003c7c:	855a                	mv	a0,s6
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	89e080e7          	jalr	-1890(ra) # 8000351c <bmap>
    80003c86:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c8a:	cd85                	beqz	a1,80003cc2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c8c:	000b2503          	lw	a0,0(s6)
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	498080e7          	jalr	1176(ra) # 80003128 <bread>
    80003c98:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9a:	3ff4f713          	andi	a4,s1,1023
    80003c9e:	40ec87bb          	subw	a5,s9,a4
    80003ca2:	413a86bb          	subw	a3,s5,s3
    80003ca6:	8d3e                	mv	s10,a5
    80003ca8:	2781                	sext.w	a5,a5
    80003caa:	0006861b          	sext.w	a2,a3
    80003cae:	f8f679e3          	bgeu	a2,a5,80003c40 <readi+0x4c>
    80003cb2:	8d36                	mv	s10,a3
    80003cb4:	b771                	j	80003c40 <readi+0x4c>
      brelse(bp);
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	fffff097          	auipc	ra,0xfffff
    80003cbc:	5a0080e7          	jalr	1440(ra) # 80003258 <brelse>
      tot = -1;
    80003cc0:	59fd                	li	s3,-1
  }
  return tot;
    80003cc2:	0009851b          	sext.w	a0,s3
}
    80003cc6:	70a6                	ld	ra,104(sp)
    80003cc8:	7406                	ld	s0,96(sp)
    80003cca:	64e6                	ld	s1,88(sp)
    80003ccc:	6946                	ld	s2,80(sp)
    80003cce:	69a6                	ld	s3,72(sp)
    80003cd0:	6a06                	ld	s4,64(sp)
    80003cd2:	7ae2                	ld	s5,56(sp)
    80003cd4:	7b42                	ld	s6,48(sp)
    80003cd6:	7ba2                	ld	s7,40(sp)
    80003cd8:	7c02                	ld	s8,32(sp)
    80003cda:	6ce2                	ld	s9,24(sp)
    80003cdc:	6d42                	ld	s10,16(sp)
    80003cde:	6da2                	ld	s11,8(sp)
    80003ce0:	6165                	addi	sp,sp,112
    80003ce2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce4:	89d6                	mv	s3,s5
    80003ce6:	bff1                	j	80003cc2 <readi+0xce>
    return 0;
    80003ce8:	4501                	li	a0,0
}
    80003cea:	8082                	ret

0000000080003cec <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cec:	457c                	lw	a5,76(a0)
    80003cee:	10d7e863          	bltu	a5,a3,80003dfe <writei+0x112>
{
    80003cf2:	7159                	addi	sp,sp,-112
    80003cf4:	f486                	sd	ra,104(sp)
    80003cf6:	f0a2                	sd	s0,96(sp)
    80003cf8:	eca6                	sd	s1,88(sp)
    80003cfa:	e8ca                	sd	s2,80(sp)
    80003cfc:	e4ce                	sd	s3,72(sp)
    80003cfe:	e0d2                	sd	s4,64(sp)
    80003d00:	fc56                	sd	s5,56(sp)
    80003d02:	f85a                	sd	s6,48(sp)
    80003d04:	f45e                	sd	s7,40(sp)
    80003d06:	f062                	sd	s8,32(sp)
    80003d08:	ec66                	sd	s9,24(sp)
    80003d0a:	e86a                	sd	s10,16(sp)
    80003d0c:	e46e                	sd	s11,8(sp)
    80003d0e:	1880                	addi	s0,sp,112
    80003d10:	8aaa                	mv	s5,a0
    80003d12:	8bae                	mv	s7,a1
    80003d14:	8a32                	mv	s4,a2
    80003d16:	8936                	mv	s2,a3
    80003d18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d1a:	00e687bb          	addw	a5,a3,a4
    80003d1e:	0ed7e263          	bltu	a5,a3,80003e02 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d22:	00043737          	lui	a4,0x43
    80003d26:	0ef76063          	bltu	a4,a5,80003e06 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d2a:	0c0b0863          	beqz	s6,80003dfa <writei+0x10e>
    80003d2e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d30:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d34:	5c7d                	li	s8,-1
    80003d36:	a091                	j	80003d7a <writei+0x8e>
    80003d38:	020d1d93          	slli	s11,s10,0x20
    80003d3c:	020ddd93          	srli	s11,s11,0x20
    80003d40:	05848513          	addi	a0,s1,88
    80003d44:	86ee                	mv	a3,s11
    80003d46:	8652                	mv	a2,s4
    80003d48:	85de                	mv	a1,s7
    80003d4a:	953a                	add	a0,a0,a4
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	8b6080e7          	jalr	-1866(ra) # 80002602 <either_copyin>
    80003d54:	07850263          	beq	a0,s8,80003db8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d58:	8526                	mv	a0,s1
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	788080e7          	jalr	1928(ra) # 800044e2 <log_write>
    brelse(bp);
    80003d62:	8526                	mv	a0,s1
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	4f4080e7          	jalr	1268(ra) # 80003258 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6c:	013d09bb          	addw	s3,s10,s3
    80003d70:	012d093b          	addw	s2,s10,s2
    80003d74:	9a6e                	add	s4,s4,s11
    80003d76:	0569f663          	bgeu	s3,s6,80003dc2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d7a:	00a9559b          	srliw	a1,s2,0xa
    80003d7e:	8556                	mv	a0,s5
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	79c080e7          	jalr	1948(ra) # 8000351c <bmap>
    80003d88:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d8c:	c99d                	beqz	a1,80003dc2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d8e:	000aa503          	lw	a0,0(s5)
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	396080e7          	jalr	918(ra) # 80003128 <bread>
    80003d9a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d9c:	3ff97713          	andi	a4,s2,1023
    80003da0:	40ec87bb          	subw	a5,s9,a4
    80003da4:	413b06bb          	subw	a3,s6,s3
    80003da8:	8d3e                	mv	s10,a5
    80003daa:	2781                	sext.w	a5,a5
    80003dac:	0006861b          	sext.w	a2,a3
    80003db0:	f8f674e3          	bgeu	a2,a5,80003d38 <writei+0x4c>
    80003db4:	8d36                	mv	s10,a3
    80003db6:	b749                	j	80003d38 <writei+0x4c>
      brelse(bp);
    80003db8:	8526                	mv	a0,s1
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	49e080e7          	jalr	1182(ra) # 80003258 <brelse>
  }

  if(off > ip->size)
    80003dc2:	04caa783          	lw	a5,76(s5)
    80003dc6:	0127f463          	bgeu	a5,s2,80003dce <writei+0xe2>
    ip->size = off;
    80003dca:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dce:	8556                	mv	a0,s5
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	aa4080e7          	jalr	-1372(ra) # 80003874 <iupdate>

  return tot;
    80003dd8:	0009851b          	sext.w	a0,s3
}
    80003ddc:	70a6                	ld	ra,104(sp)
    80003dde:	7406                	ld	s0,96(sp)
    80003de0:	64e6                	ld	s1,88(sp)
    80003de2:	6946                	ld	s2,80(sp)
    80003de4:	69a6                	ld	s3,72(sp)
    80003de6:	6a06                	ld	s4,64(sp)
    80003de8:	7ae2                	ld	s5,56(sp)
    80003dea:	7b42                	ld	s6,48(sp)
    80003dec:	7ba2                	ld	s7,40(sp)
    80003dee:	7c02                	ld	s8,32(sp)
    80003df0:	6ce2                	ld	s9,24(sp)
    80003df2:	6d42                	ld	s10,16(sp)
    80003df4:	6da2                	ld	s11,8(sp)
    80003df6:	6165                	addi	sp,sp,112
    80003df8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dfa:	89da                	mv	s3,s6
    80003dfc:	bfc9                	j	80003dce <writei+0xe2>
    return -1;
    80003dfe:	557d                	li	a0,-1
}
    80003e00:	8082                	ret
    return -1;
    80003e02:	557d                	li	a0,-1
    80003e04:	bfe1                	j	80003ddc <writei+0xf0>
    return -1;
    80003e06:	557d                	li	a0,-1
    80003e08:	bfd1                	j	80003ddc <writei+0xf0>

0000000080003e0a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e0a:	1141                	addi	sp,sp,-16
    80003e0c:	e406                	sd	ra,8(sp)
    80003e0e:	e022                	sd	s0,0(sp)
    80003e10:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e12:	4639                	li	a2,14
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	0c4080e7          	jalr	196(ra) # 80000ed8 <strncmp>
}
    80003e1c:	60a2                	ld	ra,8(sp)
    80003e1e:	6402                	ld	s0,0(sp)
    80003e20:	0141                	addi	sp,sp,16
    80003e22:	8082                	ret

0000000080003e24 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e24:	7139                	addi	sp,sp,-64
    80003e26:	fc06                	sd	ra,56(sp)
    80003e28:	f822                	sd	s0,48(sp)
    80003e2a:	f426                	sd	s1,40(sp)
    80003e2c:	f04a                	sd	s2,32(sp)
    80003e2e:	ec4e                	sd	s3,24(sp)
    80003e30:	e852                	sd	s4,16(sp)
    80003e32:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e34:	04451703          	lh	a4,68(a0)
    80003e38:	4785                	li	a5,1
    80003e3a:	00f71a63          	bne	a4,a5,80003e4e <dirlookup+0x2a>
    80003e3e:	892a                	mv	s2,a0
    80003e40:	89ae                	mv	s3,a1
    80003e42:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e44:	457c                	lw	a5,76(a0)
    80003e46:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e48:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4a:	e79d                	bnez	a5,80003e78 <dirlookup+0x54>
    80003e4c:	a8a5                	j	80003ec4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e4e:	00004517          	auipc	a0,0x4
    80003e52:	7f250513          	addi	a0,a0,2034 # 80008640 <syscalls+0x1b8>
    80003e56:	ffffc097          	auipc	ra,0xffffc
    80003e5a:	6ea080e7          	jalr	1770(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e5e:	00004517          	auipc	a0,0x4
    80003e62:	7fa50513          	addi	a0,a0,2042 # 80008658 <syscalls+0x1d0>
    80003e66:	ffffc097          	auipc	ra,0xffffc
    80003e6a:	6da080e7          	jalr	1754(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6e:	24c1                	addiw	s1,s1,16
    80003e70:	04c92783          	lw	a5,76(s2)
    80003e74:	04f4f763          	bgeu	s1,a5,80003ec2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e78:	4741                	li	a4,16
    80003e7a:	86a6                	mv	a3,s1
    80003e7c:	fc040613          	addi	a2,s0,-64
    80003e80:	4581                	li	a1,0
    80003e82:	854a                	mv	a0,s2
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	d70080e7          	jalr	-656(ra) # 80003bf4 <readi>
    80003e8c:	47c1                	li	a5,16
    80003e8e:	fcf518e3          	bne	a0,a5,80003e5e <dirlookup+0x3a>
    if(de.inum == 0)
    80003e92:	fc045783          	lhu	a5,-64(s0)
    80003e96:	dfe1                	beqz	a5,80003e6e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e98:	fc240593          	addi	a1,s0,-62
    80003e9c:	854e                	mv	a0,s3
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	f6c080e7          	jalr	-148(ra) # 80003e0a <namecmp>
    80003ea6:	f561                	bnez	a0,80003e6e <dirlookup+0x4a>
      if(poff)
    80003ea8:	000a0463          	beqz	s4,80003eb0 <dirlookup+0x8c>
        *poff = off;
    80003eac:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eb0:	fc045583          	lhu	a1,-64(s0)
    80003eb4:	00092503          	lw	a0,0(s2)
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	74e080e7          	jalr	1870(ra) # 80003606 <iget>
    80003ec0:	a011                	j	80003ec4 <dirlookup+0xa0>
  return 0;
    80003ec2:	4501                	li	a0,0
}
    80003ec4:	70e2                	ld	ra,56(sp)
    80003ec6:	7442                	ld	s0,48(sp)
    80003ec8:	74a2                	ld	s1,40(sp)
    80003eca:	7902                	ld	s2,32(sp)
    80003ecc:	69e2                	ld	s3,24(sp)
    80003ece:	6a42                	ld	s4,16(sp)
    80003ed0:	6121                	addi	sp,sp,64
    80003ed2:	8082                	ret

0000000080003ed4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ed4:	711d                	addi	sp,sp,-96
    80003ed6:	ec86                	sd	ra,88(sp)
    80003ed8:	e8a2                	sd	s0,80(sp)
    80003eda:	e4a6                	sd	s1,72(sp)
    80003edc:	e0ca                	sd	s2,64(sp)
    80003ede:	fc4e                	sd	s3,56(sp)
    80003ee0:	f852                	sd	s4,48(sp)
    80003ee2:	f456                	sd	s5,40(sp)
    80003ee4:	f05a                	sd	s6,32(sp)
    80003ee6:	ec5e                	sd	s7,24(sp)
    80003ee8:	e862                	sd	s8,16(sp)
    80003eea:	e466                	sd	s9,8(sp)
    80003eec:	e06a                	sd	s10,0(sp)
    80003eee:	1080                	addi	s0,sp,96
    80003ef0:	84aa                	mv	s1,a0
    80003ef2:	8b2e                	mv	s6,a1
    80003ef4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ef6:	00054703          	lbu	a4,0(a0)
    80003efa:	02f00793          	li	a5,47
    80003efe:	02f70363          	beq	a4,a5,80003f24 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f02:	ffffe097          	auipc	ra,0xffffe
    80003f06:	bfa080e7          	jalr	-1030(ra) # 80001afc <myproc>
    80003f0a:	15053503          	ld	a0,336(a0)
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	9f4080e7          	jalr	-1548(ra) # 80003902 <idup>
    80003f16:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f18:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f1c:	4cb5                	li	s9,13
  len = path - s;
    80003f1e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f20:	4c05                	li	s8,1
    80003f22:	a87d                	j	80003fe0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f24:	4585                	li	a1,1
    80003f26:	4505                	li	a0,1
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	6de080e7          	jalr	1758(ra) # 80003606 <iget>
    80003f30:	8a2a                	mv	s4,a0
    80003f32:	b7dd                	j	80003f18 <namex+0x44>
      iunlockput(ip);
    80003f34:	8552                	mv	a0,s4
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	c6c080e7          	jalr	-916(ra) # 80003ba2 <iunlockput>
      return 0;
    80003f3e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f40:	8552                	mv	a0,s4
    80003f42:	60e6                	ld	ra,88(sp)
    80003f44:	6446                	ld	s0,80(sp)
    80003f46:	64a6                	ld	s1,72(sp)
    80003f48:	6906                	ld	s2,64(sp)
    80003f4a:	79e2                	ld	s3,56(sp)
    80003f4c:	7a42                	ld	s4,48(sp)
    80003f4e:	7aa2                	ld	s5,40(sp)
    80003f50:	7b02                	ld	s6,32(sp)
    80003f52:	6be2                	ld	s7,24(sp)
    80003f54:	6c42                	ld	s8,16(sp)
    80003f56:	6ca2                	ld	s9,8(sp)
    80003f58:	6d02                	ld	s10,0(sp)
    80003f5a:	6125                	addi	sp,sp,96
    80003f5c:	8082                	ret
      iunlock(ip);
    80003f5e:	8552                	mv	a0,s4
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	aa2080e7          	jalr	-1374(ra) # 80003a02 <iunlock>
      return ip;
    80003f68:	bfe1                	j	80003f40 <namex+0x6c>
      iunlockput(ip);
    80003f6a:	8552                	mv	a0,s4
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	c36080e7          	jalr	-970(ra) # 80003ba2 <iunlockput>
      return 0;
    80003f74:	8a4e                	mv	s4,s3
    80003f76:	b7e9                	j	80003f40 <namex+0x6c>
  len = path - s;
    80003f78:	40998633          	sub	a2,s3,s1
    80003f7c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003f80:	09acd863          	bge	s9,s10,80004010 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003f84:	4639                	li	a2,14
    80003f86:	85a6                	mv	a1,s1
    80003f88:	8556                	mv	a0,s5
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	eda080e7          	jalr	-294(ra) # 80000e64 <memmove>
    80003f92:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f94:	0004c783          	lbu	a5,0(s1)
    80003f98:	01279763          	bne	a5,s2,80003fa6 <namex+0xd2>
    path++;
    80003f9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f9e:	0004c783          	lbu	a5,0(s1)
    80003fa2:	ff278de3          	beq	a5,s2,80003f9c <namex+0xc8>
    ilock(ip);
    80003fa6:	8552                	mv	a0,s4
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	998080e7          	jalr	-1640(ra) # 80003940 <ilock>
    if(ip->type != T_DIR){
    80003fb0:	044a1783          	lh	a5,68(s4)
    80003fb4:	f98790e3          	bne	a5,s8,80003f34 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003fb8:	000b0563          	beqz	s6,80003fc2 <namex+0xee>
    80003fbc:	0004c783          	lbu	a5,0(s1)
    80003fc0:	dfd9                	beqz	a5,80003f5e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fc2:	865e                	mv	a2,s7
    80003fc4:	85d6                	mv	a1,s5
    80003fc6:	8552                	mv	a0,s4
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	e5c080e7          	jalr	-420(ra) # 80003e24 <dirlookup>
    80003fd0:	89aa                	mv	s3,a0
    80003fd2:	dd41                	beqz	a0,80003f6a <namex+0x96>
    iunlockput(ip);
    80003fd4:	8552                	mv	a0,s4
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	bcc080e7          	jalr	-1076(ra) # 80003ba2 <iunlockput>
    ip = next;
    80003fde:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003fe0:	0004c783          	lbu	a5,0(s1)
    80003fe4:	01279763          	bne	a5,s2,80003ff2 <namex+0x11e>
    path++;
    80003fe8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fea:	0004c783          	lbu	a5,0(s1)
    80003fee:	ff278de3          	beq	a5,s2,80003fe8 <namex+0x114>
  if(*path == 0)
    80003ff2:	cb9d                	beqz	a5,80004028 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003ff4:	0004c783          	lbu	a5,0(s1)
    80003ff8:	89a6                	mv	s3,s1
  len = path - s;
    80003ffa:	8d5e                	mv	s10,s7
    80003ffc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ffe:	01278963          	beq	a5,s2,80004010 <namex+0x13c>
    80004002:	dbbd                	beqz	a5,80003f78 <namex+0xa4>
    path++;
    80004004:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004006:	0009c783          	lbu	a5,0(s3)
    8000400a:	ff279ce3          	bne	a5,s2,80004002 <namex+0x12e>
    8000400e:	b7ad                	j	80003f78 <namex+0xa4>
    memmove(name, s, len);
    80004010:	2601                	sext.w	a2,a2
    80004012:	85a6                	mv	a1,s1
    80004014:	8556                	mv	a0,s5
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	e4e080e7          	jalr	-434(ra) # 80000e64 <memmove>
    name[len] = 0;
    8000401e:	9d56                	add	s10,s10,s5
    80004020:	000d0023          	sb	zero,0(s10)
    80004024:	84ce                	mv	s1,s3
    80004026:	b7bd                	j	80003f94 <namex+0xc0>
  if(nameiparent){
    80004028:	f00b0ce3          	beqz	s6,80003f40 <namex+0x6c>
    iput(ip);
    8000402c:	8552                	mv	a0,s4
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	acc080e7          	jalr	-1332(ra) # 80003afa <iput>
    return 0;
    80004036:	4a01                	li	s4,0
    80004038:	b721                	j	80003f40 <namex+0x6c>

000000008000403a <dirlink>:
{
    8000403a:	7139                	addi	sp,sp,-64
    8000403c:	fc06                	sd	ra,56(sp)
    8000403e:	f822                	sd	s0,48(sp)
    80004040:	f426                	sd	s1,40(sp)
    80004042:	f04a                	sd	s2,32(sp)
    80004044:	ec4e                	sd	s3,24(sp)
    80004046:	e852                	sd	s4,16(sp)
    80004048:	0080                	addi	s0,sp,64
    8000404a:	892a                	mv	s2,a0
    8000404c:	8a2e                	mv	s4,a1
    8000404e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004050:	4601                	li	a2,0
    80004052:	00000097          	auipc	ra,0x0
    80004056:	dd2080e7          	jalr	-558(ra) # 80003e24 <dirlookup>
    8000405a:	e93d                	bnez	a0,800040d0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000405c:	04c92483          	lw	s1,76(s2)
    80004060:	c49d                	beqz	s1,8000408e <dirlink+0x54>
    80004062:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004064:	4741                	li	a4,16
    80004066:	86a6                	mv	a3,s1
    80004068:	fc040613          	addi	a2,s0,-64
    8000406c:	4581                	li	a1,0
    8000406e:	854a                	mv	a0,s2
    80004070:	00000097          	auipc	ra,0x0
    80004074:	b84080e7          	jalr	-1148(ra) # 80003bf4 <readi>
    80004078:	47c1                	li	a5,16
    8000407a:	06f51163          	bne	a0,a5,800040dc <dirlink+0xa2>
    if(de.inum == 0)
    8000407e:	fc045783          	lhu	a5,-64(s0)
    80004082:	c791                	beqz	a5,8000408e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	24c1                	addiw	s1,s1,16
    80004086:	04c92783          	lw	a5,76(s2)
    8000408a:	fcf4ede3          	bltu	s1,a5,80004064 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000408e:	4639                	li	a2,14
    80004090:	85d2                	mv	a1,s4
    80004092:	fc240513          	addi	a0,s0,-62
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	e7e080e7          	jalr	-386(ra) # 80000f14 <strncpy>
  de.inum = inum;
    8000409e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a2:	4741                	li	a4,16
    800040a4:	86a6                	mv	a3,s1
    800040a6:	fc040613          	addi	a2,s0,-64
    800040aa:	4581                	li	a1,0
    800040ac:	854a                	mv	a0,s2
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	c3e080e7          	jalr	-962(ra) # 80003cec <writei>
    800040b6:	1541                	addi	a0,a0,-16
    800040b8:	00a03533          	snez	a0,a0
    800040bc:	40a00533          	neg	a0,a0
}
    800040c0:	70e2                	ld	ra,56(sp)
    800040c2:	7442                	ld	s0,48(sp)
    800040c4:	74a2                	ld	s1,40(sp)
    800040c6:	7902                	ld	s2,32(sp)
    800040c8:	69e2                	ld	s3,24(sp)
    800040ca:	6a42                	ld	s4,16(sp)
    800040cc:	6121                	addi	sp,sp,64
    800040ce:	8082                	ret
    iput(ip);
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	a2a080e7          	jalr	-1494(ra) # 80003afa <iput>
    return -1;
    800040d8:	557d                	li	a0,-1
    800040da:	b7dd                	j	800040c0 <dirlink+0x86>
      panic("dirlink read");
    800040dc:	00004517          	auipc	a0,0x4
    800040e0:	58c50513          	addi	a0,a0,1420 # 80008668 <syscalls+0x1e0>
    800040e4:	ffffc097          	auipc	ra,0xffffc
    800040e8:	45c080e7          	jalr	1116(ra) # 80000540 <panic>

00000000800040ec <namei>:

struct inode*
namei(char *path)
{
    800040ec:	1101                	addi	sp,sp,-32
    800040ee:	ec06                	sd	ra,24(sp)
    800040f0:	e822                	sd	s0,16(sp)
    800040f2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040f4:	fe040613          	addi	a2,s0,-32
    800040f8:	4581                	li	a1,0
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	dda080e7          	jalr	-550(ra) # 80003ed4 <namex>
}
    80004102:	60e2                	ld	ra,24(sp)
    80004104:	6442                	ld	s0,16(sp)
    80004106:	6105                	addi	sp,sp,32
    80004108:	8082                	ret

000000008000410a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000410a:	1141                	addi	sp,sp,-16
    8000410c:	e406                	sd	ra,8(sp)
    8000410e:	e022                	sd	s0,0(sp)
    80004110:	0800                	addi	s0,sp,16
    80004112:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004114:	4585                	li	a1,1
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	dbe080e7          	jalr	-578(ra) # 80003ed4 <namex>
}
    8000411e:	60a2                	ld	ra,8(sp)
    80004120:	6402                	ld	s0,0(sp)
    80004122:	0141                	addi	sp,sp,16
    80004124:	8082                	ret

0000000080004126 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004126:	1101                	addi	sp,sp,-32
    80004128:	ec06                	sd	ra,24(sp)
    8000412a:	e822                	sd	s0,16(sp)
    8000412c:	e426                	sd	s1,8(sp)
    8000412e:	e04a                	sd	s2,0(sp)
    80004130:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004132:	0023e917          	auipc	s2,0x23e
    80004136:	23e90913          	addi	s2,s2,574 # 80242370 <log>
    8000413a:	01892583          	lw	a1,24(s2)
    8000413e:	02892503          	lw	a0,40(s2)
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	fe6080e7          	jalr	-26(ra) # 80003128 <bread>
    8000414a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000414c:	02c92683          	lw	a3,44(s2)
    80004150:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004152:	02d05863          	blez	a3,80004182 <write_head+0x5c>
    80004156:	0023e797          	auipc	a5,0x23e
    8000415a:	24a78793          	addi	a5,a5,586 # 802423a0 <log+0x30>
    8000415e:	05c50713          	addi	a4,a0,92
    80004162:	36fd                	addiw	a3,a3,-1
    80004164:	02069613          	slli	a2,a3,0x20
    80004168:	01e65693          	srli	a3,a2,0x1e
    8000416c:	0023e617          	auipc	a2,0x23e
    80004170:	23860613          	addi	a2,a2,568 # 802423a4 <log+0x34>
    80004174:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004176:	4390                	lw	a2,0(a5)
    80004178:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000417a:	0791                	addi	a5,a5,4
    8000417c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000417e:	fed79ce3          	bne	a5,a3,80004176 <write_head+0x50>
  }
  bwrite(buf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	096080e7          	jalr	150(ra) # 8000321a <bwrite>
  brelse(buf);
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	0ca080e7          	jalr	202(ra) # 80003258 <brelse>
}
    80004196:	60e2                	ld	ra,24(sp)
    80004198:	6442                	ld	s0,16(sp)
    8000419a:	64a2                	ld	s1,8(sp)
    8000419c:	6902                	ld	s2,0(sp)
    8000419e:	6105                	addi	sp,sp,32
    800041a0:	8082                	ret

00000000800041a2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a2:	0023e797          	auipc	a5,0x23e
    800041a6:	1fa7a783          	lw	a5,506(a5) # 8024239c <log+0x2c>
    800041aa:	0af05d63          	blez	a5,80004264 <install_trans+0xc2>
{
    800041ae:	7139                	addi	sp,sp,-64
    800041b0:	fc06                	sd	ra,56(sp)
    800041b2:	f822                	sd	s0,48(sp)
    800041b4:	f426                	sd	s1,40(sp)
    800041b6:	f04a                	sd	s2,32(sp)
    800041b8:	ec4e                	sd	s3,24(sp)
    800041ba:	e852                	sd	s4,16(sp)
    800041bc:	e456                	sd	s5,8(sp)
    800041be:	e05a                	sd	s6,0(sp)
    800041c0:	0080                	addi	s0,sp,64
    800041c2:	8b2a                	mv	s6,a0
    800041c4:	0023ea97          	auipc	s5,0x23e
    800041c8:	1dca8a93          	addi	s5,s5,476 # 802423a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041cc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ce:	0023e997          	auipc	s3,0x23e
    800041d2:	1a298993          	addi	s3,s3,418 # 80242370 <log>
    800041d6:	a00d                	j	800041f8 <install_trans+0x56>
    brelse(lbuf);
    800041d8:	854a                	mv	a0,s2
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	07e080e7          	jalr	126(ra) # 80003258 <brelse>
    brelse(dbuf);
    800041e2:	8526                	mv	a0,s1
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	074080e7          	jalr	116(ra) # 80003258 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	2a05                	addiw	s4,s4,1
    800041ee:	0a91                	addi	s5,s5,4
    800041f0:	02c9a783          	lw	a5,44(s3)
    800041f4:	04fa5e63          	bge	s4,a5,80004250 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f8:	0189a583          	lw	a1,24(s3)
    800041fc:	014585bb          	addw	a1,a1,s4
    80004200:	2585                	addiw	a1,a1,1
    80004202:	0289a503          	lw	a0,40(s3)
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	f22080e7          	jalr	-222(ra) # 80003128 <bread>
    8000420e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004210:	000aa583          	lw	a1,0(s5)
    80004214:	0289a503          	lw	a0,40(s3)
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	f10080e7          	jalr	-240(ra) # 80003128 <bread>
    80004220:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004222:	40000613          	li	a2,1024
    80004226:	05890593          	addi	a1,s2,88
    8000422a:	05850513          	addi	a0,a0,88
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	c36080e7          	jalr	-970(ra) # 80000e64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	fe2080e7          	jalr	-30(ra) # 8000321a <bwrite>
    if(recovering == 0)
    80004240:	f80b1ce3          	bnez	s6,800041d8 <install_trans+0x36>
      bunpin(dbuf);
    80004244:	8526                	mv	a0,s1
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	0ec080e7          	jalr	236(ra) # 80003332 <bunpin>
    8000424e:	b769                	j	800041d8 <install_trans+0x36>
}
    80004250:	70e2                	ld	ra,56(sp)
    80004252:	7442                	ld	s0,48(sp)
    80004254:	74a2                	ld	s1,40(sp)
    80004256:	7902                	ld	s2,32(sp)
    80004258:	69e2                	ld	s3,24(sp)
    8000425a:	6a42                	ld	s4,16(sp)
    8000425c:	6aa2                	ld	s5,8(sp)
    8000425e:	6b02                	ld	s6,0(sp)
    80004260:	6121                	addi	sp,sp,64
    80004262:	8082                	ret
    80004264:	8082                	ret

0000000080004266 <initlog>:
{
    80004266:	7179                	addi	sp,sp,-48
    80004268:	f406                	sd	ra,40(sp)
    8000426a:	f022                	sd	s0,32(sp)
    8000426c:	ec26                	sd	s1,24(sp)
    8000426e:	e84a                	sd	s2,16(sp)
    80004270:	e44e                	sd	s3,8(sp)
    80004272:	1800                	addi	s0,sp,48
    80004274:	892a                	mv	s2,a0
    80004276:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004278:	0023e497          	auipc	s1,0x23e
    8000427c:	0f848493          	addi	s1,s1,248 # 80242370 <log>
    80004280:	00004597          	auipc	a1,0x4
    80004284:	3f858593          	addi	a1,a1,1016 # 80008678 <syscalls+0x1f0>
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	9f2080e7          	jalr	-1550(ra) # 80000c7c <initlock>
  log.start = sb->logstart;
    80004292:	0149a583          	lw	a1,20(s3)
    80004296:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004298:	0109a783          	lw	a5,16(s3)
    8000429c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000429e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042a2:	854a                	mv	a0,s2
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	e84080e7          	jalr	-380(ra) # 80003128 <bread>
  log.lh.n = lh->n;
    800042ac:	4d34                	lw	a3,88(a0)
    800042ae:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042b0:	02d05663          	blez	a3,800042dc <initlog+0x76>
    800042b4:	05c50793          	addi	a5,a0,92
    800042b8:	0023e717          	auipc	a4,0x23e
    800042bc:	0e870713          	addi	a4,a4,232 # 802423a0 <log+0x30>
    800042c0:	36fd                	addiw	a3,a3,-1
    800042c2:	02069613          	slli	a2,a3,0x20
    800042c6:	01e65693          	srli	a3,a2,0x1e
    800042ca:	06050613          	addi	a2,a0,96
    800042ce:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042d0:	4390                	lw	a2,0(a5)
    800042d2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042d4:	0791                	addi	a5,a5,4
    800042d6:	0711                	addi	a4,a4,4
    800042d8:	fed79ce3          	bne	a5,a3,800042d0 <initlog+0x6a>
  brelse(buf);
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	f7c080e7          	jalr	-132(ra) # 80003258 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042e4:	4505                	li	a0,1
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	ebc080e7          	jalr	-324(ra) # 800041a2 <install_trans>
  log.lh.n = 0;
    800042ee:	0023e797          	auipc	a5,0x23e
    800042f2:	0a07a723          	sw	zero,174(a5) # 8024239c <log+0x2c>
  write_head(); // clear the log
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	e30080e7          	jalr	-464(ra) # 80004126 <write_head>
}
    800042fe:	70a2                	ld	ra,40(sp)
    80004300:	7402                	ld	s0,32(sp)
    80004302:	64e2                	ld	s1,24(sp)
    80004304:	6942                	ld	s2,16(sp)
    80004306:	69a2                	ld	s3,8(sp)
    80004308:	6145                	addi	sp,sp,48
    8000430a:	8082                	ret

000000008000430c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004318:	0023e517          	auipc	a0,0x23e
    8000431c:	05850513          	addi	a0,a0,88 # 80242370 <log>
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	9ec080e7          	jalr	-1556(ra) # 80000d0c <acquire>
  while(1){
    if(log.committing){
    80004328:	0023e497          	auipc	s1,0x23e
    8000432c:	04848493          	addi	s1,s1,72 # 80242370 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004330:	4979                	li	s2,30
    80004332:	a039                	j	80004340 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004334:	85a6                	mv	a1,s1
    80004336:	8526                	mv	a0,s1
    80004338:	ffffe097          	auipc	ra,0xffffe
    8000433c:	e6c080e7          	jalr	-404(ra) # 800021a4 <sleep>
    if(log.committing){
    80004340:	50dc                	lw	a5,36(s1)
    80004342:	fbed                	bnez	a5,80004334 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004344:	5098                	lw	a4,32(s1)
    80004346:	2705                	addiw	a4,a4,1
    80004348:	0007069b          	sext.w	a3,a4
    8000434c:	0027179b          	slliw	a5,a4,0x2
    80004350:	9fb9                	addw	a5,a5,a4
    80004352:	0017979b          	slliw	a5,a5,0x1
    80004356:	54d8                	lw	a4,44(s1)
    80004358:	9fb9                	addw	a5,a5,a4
    8000435a:	00f95963          	bge	s2,a5,8000436c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000435e:	85a6                	mv	a1,s1
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	e42080e7          	jalr	-446(ra) # 800021a4 <sleep>
    8000436a:	bfd9                	j	80004340 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000436c:	0023e517          	auipc	a0,0x23e
    80004370:	00450513          	addi	a0,a0,4 # 80242370 <log>
    80004374:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	a4a080e7          	jalr	-1462(ra) # 80000dc0 <release>
      break;
    }
  }
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000438a:	7139                	addi	sp,sp,-64
    8000438c:	fc06                	sd	ra,56(sp)
    8000438e:	f822                	sd	s0,48(sp)
    80004390:	f426                	sd	s1,40(sp)
    80004392:	f04a                	sd	s2,32(sp)
    80004394:	ec4e                	sd	s3,24(sp)
    80004396:	e852                	sd	s4,16(sp)
    80004398:	e456                	sd	s5,8(sp)
    8000439a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000439c:	0023e497          	auipc	s1,0x23e
    800043a0:	fd448493          	addi	s1,s1,-44 # 80242370 <log>
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	966080e7          	jalr	-1690(ra) # 80000d0c <acquire>
  log.outstanding -= 1;
    800043ae:	509c                	lw	a5,32(s1)
    800043b0:	37fd                	addiw	a5,a5,-1
    800043b2:	0007891b          	sext.w	s2,a5
    800043b6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043b8:	50dc                	lw	a5,36(s1)
    800043ba:	e7b9                	bnez	a5,80004408 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043bc:	04091e63          	bnez	s2,80004418 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043c0:	0023e497          	auipc	s1,0x23e
    800043c4:	fb048493          	addi	s1,s1,-80 # 80242370 <log>
    800043c8:	4785                	li	a5,1
    800043ca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	9f2080e7          	jalr	-1550(ra) # 80000dc0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043d6:	54dc                	lw	a5,44(s1)
    800043d8:	06f04763          	bgtz	a5,80004446 <end_op+0xbc>
    acquire(&log.lock);
    800043dc:	0023e497          	auipc	s1,0x23e
    800043e0:	f9448493          	addi	s1,s1,-108 # 80242370 <log>
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	926080e7          	jalr	-1754(ra) # 80000d0c <acquire>
    log.committing = 0;
    800043ee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043f2:	8526                	mv	a0,s1
    800043f4:	ffffe097          	auipc	ra,0xffffe
    800043f8:	e14080e7          	jalr	-492(ra) # 80002208 <wakeup>
    release(&log.lock);
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	9c2080e7          	jalr	-1598(ra) # 80000dc0 <release>
}
    80004406:	a03d                	j	80004434 <end_op+0xaa>
    panic("log.committing");
    80004408:	00004517          	auipc	a0,0x4
    8000440c:	27850513          	addi	a0,a0,632 # 80008680 <syscalls+0x1f8>
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	130080e7          	jalr	304(ra) # 80000540 <panic>
    wakeup(&log);
    80004418:	0023e497          	auipc	s1,0x23e
    8000441c:	f5848493          	addi	s1,s1,-168 # 80242370 <log>
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	de6080e7          	jalr	-538(ra) # 80002208 <wakeup>
  release(&log.lock);
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	994080e7          	jalr	-1644(ra) # 80000dc0 <release>
}
    80004434:	70e2                	ld	ra,56(sp)
    80004436:	7442                	ld	s0,48(sp)
    80004438:	74a2                	ld	s1,40(sp)
    8000443a:	7902                	ld	s2,32(sp)
    8000443c:	69e2                	ld	s3,24(sp)
    8000443e:	6a42                	ld	s4,16(sp)
    80004440:	6aa2                	ld	s5,8(sp)
    80004442:	6121                	addi	sp,sp,64
    80004444:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004446:	0023ea97          	auipc	s5,0x23e
    8000444a:	f5aa8a93          	addi	s5,s5,-166 # 802423a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000444e:	0023ea17          	auipc	s4,0x23e
    80004452:	f22a0a13          	addi	s4,s4,-222 # 80242370 <log>
    80004456:	018a2583          	lw	a1,24(s4)
    8000445a:	012585bb          	addw	a1,a1,s2
    8000445e:	2585                	addiw	a1,a1,1
    80004460:	028a2503          	lw	a0,40(s4)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	cc4080e7          	jalr	-828(ra) # 80003128 <bread>
    8000446c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000446e:	000aa583          	lw	a1,0(s5)
    80004472:	028a2503          	lw	a0,40(s4)
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	cb2080e7          	jalr	-846(ra) # 80003128 <bread>
    8000447e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004480:	40000613          	li	a2,1024
    80004484:	05850593          	addi	a1,a0,88
    80004488:	05848513          	addi	a0,s1,88
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	9d8080e7          	jalr	-1576(ra) # 80000e64 <memmove>
    bwrite(to);  // write the log
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	d84080e7          	jalr	-636(ra) # 8000321a <bwrite>
    brelse(from);
    8000449e:	854e                	mv	a0,s3
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	db8080e7          	jalr	-584(ra) # 80003258 <brelse>
    brelse(to);
    800044a8:	8526                	mv	a0,s1
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	dae080e7          	jalr	-594(ra) # 80003258 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b2:	2905                	addiw	s2,s2,1
    800044b4:	0a91                	addi	s5,s5,4
    800044b6:	02ca2783          	lw	a5,44(s4)
    800044ba:	f8f94ee3          	blt	s2,a5,80004456 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	c68080e7          	jalr	-920(ra) # 80004126 <write_head>
    install_trans(0); // Now install writes to home locations
    800044c6:	4501                	li	a0,0
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	cda080e7          	jalr	-806(ra) # 800041a2 <install_trans>
    log.lh.n = 0;
    800044d0:	0023e797          	auipc	a5,0x23e
    800044d4:	ec07a623          	sw	zero,-308(a5) # 8024239c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	c4e080e7          	jalr	-946(ra) # 80004126 <write_head>
    800044e0:	bdf5                	j	800043dc <end_op+0x52>

00000000800044e2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	e04a                	sd	s2,0(sp)
    800044ec:	1000                	addi	s0,sp,32
    800044ee:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044f0:	0023e917          	auipc	s2,0x23e
    800044f4:	e8090913          	addi	s2,s2,-384 # 80242370 <log>
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffd097          	auipc	ra,0xffffd
    800044fe:	812080e7          	jalr	-2030(ra) # 80000d0c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004502:	02c92603          	lw	a2,44(s2)
    80004506:	47f5                	li	a5,29
    80004508:	06c7c563          	blt	a5,a2,80004572 <log_write+0x90>
    8000450c:	0023e797          	auipc	a5,0x23e
    80004510:	e807a783          	lw	a5,-384(a5) # 8024238c <log+0x1c>
    80004514:	37fd                	addiw	a5,a5,-1
    80004516:	04f65e63          	bge	a2,a5,80004572 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000451a:	0023e797          	auipc	a5,0x23e
    8000451e:	e767a783          	lw	a5,-394(a5) # 80242390 <log+0x20>
    80004522:	06f05063          	blez	a5,80004582 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004526:	4781                	li	a5,0
    80004528:	06c05563          	blez	a2,80004592 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000452c:	44cc                	lw	a1,12(s1)
    8000452e:	0023e717          	auipc	a4,0x23e
    80004532:	e7270713          	addi	a4,a4,-398 # 802423a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004536:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004538:	4314                	lw	a3,0(a4)
    8000453a:	04b68c63          	beq	a3,a1,80004592 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000453e:	2785                	addiw	a5,a5,1
    80004540:	0711                	addi	a4,a4,4
    80004542:	fef61be3          	bne	a2,a5,80004538 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004546:	0621                	addi	a2,a2,8
    80004548:	060a                	slli	a2,a2,0x2
    8000454a:	0023e797          	auipc	a5,0x23e
    8000454e:	e2678793          	addi	a5,a5,-474 # 80242370 <log>
    80004552:	97b2                	add	a5,a5,a2
    80004554:	44d8                	lw	a4,12(s1)
    80004556:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004558:	8526                	mv	a0,s1
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	d9c080e7          	jalr	-612(ra) # 800032f6 <bpin>
    log.lh.n++;
    80004562:	0023e717          	auipc	a4,0x23e
    80004566:	e0e70713          	addi	a4,a4,-498 # 80242370 <log>
    8000456a:	575c                	lw	a5,44(a4)
    8000456c:	2785                	addiw	a5,a5,1
    8000456e:	d75c                	sw	a5,44(a4)
    80004570:	a82d                	j	800045aa <log_write+0xc8>
    panic("too big a transaction");
    80004572:	00004517          	auipc	a0,0x4
    80004576:	11e50513          	addi	a0,a0,286 # 80008690 <syscalls+0x208>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004582:	00004517          	auipc	a0,0x4
    80004586:	12650513          	addi	a0,a0,294 # 800086a8 <syscalls+0x220>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	fb6080e7          	jalr	-74(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004592:	00878693          	addi	a3,a5,8
    80004596:	068a                	slli	a3,a3,0x2
    80004598:	0023e717          	auipc	a4,0x23e
    8000459c:	dd870713          	addi	a4,a4,-552 # 80242370 <log>
    800045a0:	9736                	add	a4,a4,a3
    800045a2:	44d4                	lw	a3,12(s1)
    800045a4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045a6:	faf609e3          	beq	a2,a5,80004558 <log_write+0x76>
  }
  release(&log.lock);
    800045aa:	0023e517          	auipc	a0,0x23e
    800045ae:	dc650513          	addi	a0,a0,-570 # 80242370 <log>
    800045b2:	ffffd097          	auipc	ra,0xffffd
    800045b6:	80e080e7          	jalr	-2034(ra) # 80000dc0 <release>
}
    800045ba:	60e2                	ld	ra,24(sp)
    800045bc:	6442                	ld	s0,16(sp)
    800045be:	64a2                	ld	s1,8(sp)
    800045c0:	6902                	ld	s2,0(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret

00000000800045c6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045c6:	1101                	addi	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	e426                	sd	s1,8(sp)
    800045ce:	e04a                	sd	s2,0(sp)
    800045d0:	1000                	addi	s0,sp,32
    800045d2:	84aa                	mv	s1,a0
    800045d4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045d6:	00004597          	auipc	a1,0x4
    800045da:	0f258593          	addi	a1,a1,242 # 800086c8 <syscalls+0x240>
    800045de:	0521                	addi	a0,a0,8
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	69c080e7          	jalr	1692(ra) # 80000c7c <initlock>
  lk->name = name;
    800045e8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f0:	0204a423          	sw	zero,40(s1)
}
    800045f4:	60e2                	ld	ra,24(sp)
    800045f6:	6442                	ld	s0,16(sp)
    800045f8:	64a2                	ld	s1,8(sp)
    800045fa:	6902                	ld	s2,0(sp)
    800045fc:	6105                	addi	sp,sp,32
    800045fe:	8082                	ret

0000000080004600 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004600:	1101                	addi	sp,sp,-32
    80004602:	ec06                	sd	ra,24(sp)
    80004604:	e822                	sd	s0,16(sp)
    80004606:	e426                	sd	s1,8(sp)
    80004608:	e04a                	sd	s2,0(sp)
    8000460a:	1000                	addi	s0,sp,32
    8000460c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460e:	00850913          	addi	s2,a0,8
    80004612:	854a                	mv	a0,s2
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	6f8080e7          	jalr	1784(ra) # 80000d0c <acquire>
  while (lk->locked) {
    8000461c:	409c                	lw	a5,0(s1)
    8000461e:	cb89                	beqz	a5,80004630 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004620:	85ca                	mv	a1,s2
    80004622:	8526                	mv	a0,s1
    80004624:	ffffe097          	auipc	ra,0xffffe
    80004628:	b80080e7          	jalr	-1152(ra) # 800021a4 <sleep>
  while (lk->locked) {
    8000462c:	409c                	lw	a5,0(s1)
    8000462e:	fbed                	bnez	a5,80004620 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004630:	4785                	li	a5,1
    80004632:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004634:	ffffd097          	auipc	ra,0xffffd
    80004638:	4c8080e7          	jalr	1224(ra) # 80001afc <myproc>
    8000463c:	591c                	lw	a5,48(a0)
    8000463e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004640:	854a                	mv	a0,s2
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	77e080e7          	jalr	1918(ra) # 80000dc0 <release>
}
    8000464a:	60e2                	ld	ra,24(sp)
    8000464c:	6442                	ld	s0,16(sp)
    8000464e:	64a2                	ld	s1,8(sp)
    80004650:	6902                	ld	s2,0(sp)
    80004652:	6105                	addi	sp,sp,32
    80004654:	8082                	ret

0000000080004656 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004656:	1101                	addi	sp,sp,-32
    80004658:	ec06                	sd	ra,24(sp)
    8000465a:	e822                	sd	s0,16(sp)
    8000465c:	e426                	sd	s1,8(sp)
    8000465e:	e04a                	sd	s2,0(sp)
    80004660:	1000                	addi	s0,sp,32
    80004662:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004664:	00850913          	addi	s2,a0,8
    80004668:	854a                	mv	a0,s2
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	6a2080e7          	jalr	1698(ra) # 80000d0c <acquire>
  lk->locked = 0;
    80004672:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004676:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000467a:	8526                	mv	a0,s1
    8000467c:	ffffe097          	auipc	ra,0xffffe
    80004680:	b8c080e7          	jalr	-1140(ra) # 80002208 <wakeup>
  release(&lk->lk);
    80004684:	854a                	mv	a0,s2
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	73a080e7          	jalr	1850(ra) # 80000dc0 <release>
}
    8000468e:	60e2                	ld	ra,24(sp)
    80004690:	6442                	ld	s0,16(sp)
    80004692:	64a2                	ld	s1,8(sp)
    80004694:	6902                	ld	s2,0(sp)
    80004696:	6105                	addi	sp,sp,32
    80004698:	8082                	ret

000000008000469a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000469a:	7179                	addi	sp,sp,-48
    8000469c:	f406                	sd	ra,40(sp)
    8000469e:	f022                	sd	s0,32(sp)
    800046a0:	ec26                	sd	s1,24(sp)
    800046a2:	e84a                	sd	s2,16(sp)
    800046a4:	e44e                	sd	s3,8(sp)
    800046a6:	1800                	addi	s0,sp,48
    800046a8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046aa:	00850913          	addi	s2,a0,8
    800046ae:	854a                	mv	a0,s2
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	65c080e7          	jalr	1628(ra) # 80000d0c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b8:	409c                	lw	a5,0(s1)
    800046ba:	ef99                	bnez	a5,800046d8 <holdingsleep+0x3e>
    800046bc:	4481                	li	s1,0
  release(&lk->lk);
    800046be:	854a                	mv	a0,s2
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	700080e7          	jalr	1792(ra) # 80000dc0 <release>
  return r;
}
    800046c8:	8526                	mv	a0,s1
    800046ca:	70a2                	ld	ra,40(sp)
    800046cc:	7402                	ld	s0,32(sp)
    800046ce:	64e2                	ld	s1,24(sp)
    800046d0:	6942                	ld	s2,16(sp)
    800046d2:	69a2                	ld	s3,8(sp)
    800046d4:	6145                	addi	sp,sp,48
    800046d6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046d8:	0284a983          	lw	s3,40(s1)
    800046dc:	ffffd097          	auipc	ra,0xffffd
    800046e0:	420080e7          	jalr	1056(ra) # 80001afc <myproc>
    800046e4:	5904                	lw	s1,48(a0)
    800046e6:	413484b3          	sub	s1,s1,s3
    800046ea:	0014b493          	seqz	s1,s1
    800046ee:	bfc1                	j	800046be <holdingsleep+0x24>

00000000800046f0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046f0:	1141                	addi	sp,sp,-16
    800046f2:	e406                	sd	ra,8(sp)
    800046f4:	e022                	sd	s0,0(sp)
    800046f6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046f8:	00004597          	auipc	a1,0x4
    800046fc:	fe058593          	addi	a1,a1,-32 # 800086d8 <syscalls+0x250>
    80004700:	0023e517          	auipc	a0,0x23e
    80004704:	db850513          	addi	a0,a0,-584 # 802424b8 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	574080e7          	jalr	1396(ra) # 80000c7c <initlock>
}
    80004710:	60a2                	ld	ra,8(sp)
    80004712:	6402                	ld	s0,0(sp)
    80004714:	0141                	addi	sp,sp,16
    80004716:	8082                	ret

0000000080004718 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004718:	1101                	addi	sp,sp,-32
    8000471a:	ec06                	sd	ra,24(sp)
    8000471c:	e822                	sd	s0,16(sp)
    8000471e:	e426                	sd	s1,8(sp)
    80004720:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004722:	0023e517          	auipc	a0,0x23e
    80004726:	d9650513          	addi	a0,a0,-618 # 802424b8 <ftable>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	5e2080e7          	jalr	1506(ra) # 80000d0c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004732:	0023e497          	auipc	s1,0x23e
    80004736:	d9e48493          	addi	s1,s1,-610 # 802424d0 <ftable+0x18>
    8000473a:	0023f717          	auipc	a4,0x23f
    8000473e:	d3670713          	addi	a4,a4,-714 # 80243470 <disk>
    if(f->ref == 0){
    80004742:	40dc                	lw	a5,4(s1)
    80004744:	cf99                	beqz	a5,80004762 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004746:	02848493          	addi	s1,s1,40
    8000474a:	fee49ce3          	bne	s1,a4,80004742 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000474e:	0023e517          	auipc	a0,0x23e
    80004752:	d6a50513          	addi	a0,a0,-662 # 802424b8 <ftable>
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	66a080e7          	jalr	1642(ra) # 80000dc0 <release>
  return 0;
    8000475e:	4481                	li	s1,0
    80004760:	a819                	j	80004776 <filealloc+0x5e>
      f->ref = 1;
    80004762:	4785                	li	a5,1
    80004764:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004766:	0023e517          	auipc	a0,0x23e
    8000476a:	d5250513          	addi	a0,a0,-686 # 802424b8 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	652080e7          	jalr	1618(ra) # 80000dc0 <release>
}
    80004776:	8526                	mv	a0,s1
    80004778:	60e2                	ld	ra,24(sp)
    8000477a:	6442                	ld	s0,16(sp)
    8000477c:	64a2                	ld	s1,8(sp)
    8000477e:	6105                	addi	sp,sp,32
    80004780:	8082                	ret

0000000080004782 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004782:	1101                	addi	sp,sp,-32
    80004784:	ec06                	sd	ra,24(sp)
    80004786:	e822                	sd	s0,16(sp)
    80004788:	e426                	sd	s1,8(sp)
    8000478a:	1000                	addi	s0,sp,32
    8000478c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000478e:	0023e517          	auipc	a0,0x23e
    80004792:	d2a50513          	addi	a0,a0,-726 # 802424b8 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	576080e7          	jalr	1398(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    8000479e:	40dc                	lw	a5,4(s1)
    800047a0:	02f05263          	blez	a5,800047c4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047a4:	2785                	addiw	a5,a5,1
    800047a6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047a8:	0023e517          	auipc	a0,0x23e
    800047ac:	d1050513          	addi	a0,a0,-752 # 802424b8 <ftable>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	610080e7          	jalr	1552(ra) # 80000dc0 <release>
  return f;
}
    800047b8:	8526                	mv	a0,s1
    800047ba:	60e2                	ld	ra,24(sp)
    800047bc:	6442                	ld	s0,16(sp)
    800047be:	64a2                	ld	s1,8(sp)
    800047c0:	6105                	addi	sp,sp,32
    800047c2:	8082                	ret
    panic("filedup");
    800047c4:	00004517          	auipc	a0,0x4
    800047c8:	f1c50513          	addi	a0,a0,-228 # 800086e0 <syscalls+0x258>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	d74080e7          	jalr	-652(ra) # 80000540 <panic>

00000000800047d4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047d4:	7139                	addi	sp,sp,-64
    800047d6:	fc06                	sd	ra,56(sp)
    800047d8:	f822                	sd	s0,48(sp)
    800047da:	f426                	sd	s1,40(sp)
    800047dc:	f04a                	sd	s2,32(sp)
    800047de:	ec4e                	sd	s3,24(sp)
    800047e0:	e852                	sd	s4,16(sp)
    800047e2:	e456                	sd	s5,8(sp)
    800047e4:	0080                	addi	s0,sp,64
    800047e6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047e8:	0023e517          	auipc	a0,0x23e
    800047ec:	cd050513          	addi	a0,a0,-816 # 802424b8 <ftable>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	51c080e7          	jalr	1308(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    800047f8:	40dc                	lw	a5,4(s1)
    800047fa:	06f05163          	blez	a5,8000485c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047fe:	37fd                	addiw	a5,a5,-1
    80004800:	0007871b          	sext.w	a4,a5
    80004804:	c0dc                	sw	a5,4(s1)
    80004806:	06e04363          	bgtz	a4,8000486c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000480a:	0004a903          	lw	s2,0(s1)
    8000480e:	0094ca83          	lbu	s5,9(s1)
    80004812:	0104ba03          	ld	s4,16(s1)
    80004816:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000481a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000481e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004822:	0023e517          	auipc	a0,0x23e
    80004826:	c9650513          	addi	a0,a0,-874 # 802424b8 <ftable>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	596080e7          	jalr	1430(ra) # 80000dc0 <release>

  if(ff.type == FD_PIPE){
    80004832:	4785                	li	a5,1
    80004834:	04f90d63          	beq	s2,a5,8000488e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004838:	3979                	addiw	s2,s2,-2
    8000483a:	4785                	li	a5,1
    8000483c:	0527e063          	bltu	a5,s2,8000487c <fileclose+0xa8>
    begin_op();
    80004840:	00000097          	auipc	ra,0x0
    80004844:	acc080e7          	jalr	-1332(ra) # 8000430c <begin_op>
    iput(ff.ip);
    80004848:	854e                	mv	a0,s3
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	2b0080e7          	jalr	688(ra) # 80003afa <iput>
    end_op();
    80004852:	00000097          	auipc	ra,0x0
    80004856:	b38080e7          	jalr	-1224(ra) # 8000438a <end_op>
    8000485a:	a00d                	j	8000487c <fileclose+0xa8>
    panic("fileclose");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	e8c50513          	addi	a0,a0,-372 # 800086e8 <syscalls+0x260>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	cdc080e7          	jalr	-804(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000486c:	0023e517          	auipc	a0,0x23e
    80004870:	c4c50513          	addi	a0,a0,-948 # 802424b8 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	54c080e7          	jalr	1356(ra) # 80000dc0 <release>
  }
}
    8000487c:	70e2                	ld	ra,56(sp)
    8000487e:	7442                	ld	s0,48(sp)
    80004880:	74a2                	ld	s1,40(sp)
    80004882:	7902                	ld	s2,32(sp)
    80004884:	69e2                	ld	s3,24(sp)
    80004886:	6a42                	ld	s4,16(sp)
    80004888:	6aa2                	ld	s5,8(sp)
    8000488a:	6121                	addi	sp,sp,64
    8000488c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000488e:	85d6                	mv	a1,s5
    80004890:	8552                	mv	a0,s4
    80004892:	00000097          	auipc	ra,0x0
    80004896:	34c080e7          	jalr	844(ra) # 80004bde <pipeclose>
    8000489a:	b7cd                	j	8000487c <fileclose+0xa8>

000000008000489c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000489c:	715d                	addi	sp,sp,-80
    8000489e:	e486                	sd	ra,72(sp)
    800048a0:	e0a2                	sd	s0,64(sp)
    800048a2:	fc26                	sd	s1,56(sp)
    800048a4:	f84a                	sd	s2,48(sp)
    800048a6:	f44e                	sd	s3,40(sp)
    800048a8:	0880                	addi	s0,sp,80
    800048aa:	84aa                	mv	s1,a0
    800048ac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ae:	ffffd097          	auipc	ra,0xffffd
    800048b2:	24e080e7          	jalr	590(ra) # 80001afc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048b6:	409c                	lw	a5,0(s1)
    800048b8:	37f9                	addiw	a5,a5,-2
    800048ba:	4705                	li	a4,1
    800048bc:	04f76763          	bltu	a4,a5,8000490a <filestat+0x6e>
    800048c0:	892a                	mv	s2,a0
    ilock(f->ip);
    800048c2:	6c88                	ld	a0,24(s1)
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	07c080e7          	jalr	124(ra) # 80003940 <ilock>
    stati(f->ip, &st);
    800048cc:	fb840593          	addi	a1,s0,-72
    800048d0:	6c88                	ld	a0,24(s1)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	2f8080e7          	jalr	760(ra) # 80003bca <stati>
    iunlock(f->ip);
    800048da:	6c88                	ld	a0,24(s1)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	126080e7          	jalr	294(ra) # 80003a02 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048e4:	46e1                	li	a3,24
    800048e6:	fb840613          	addi	a2,s0,-72
    800048ea:	85ce                	mv	a1,s3
    800048ec:	05093503          	ld	a0,80(s2)
    800048f0:	ffffd097          	auipc	ra,0xffffd
    800048f4:	e98080e7          	jalr	-360(ra) # 80001788 <copyout>
    800048f8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048fc:	60a6                	ld	ra,72(sp)
    800048fe:	6406                	ld	s0,64(sp)
    80004900:	74e2                	ld	s1,56(sp)
    80004902:	7942                	ld	s2,48(sp)
    80004904:	79a2                	ld	s3,40(sp)
    80004906:	6161                	addi	sp,sp,80
    80004908:	8082                	ret
  return -1;
    8000490a:	557d                	li	a0,-1
    8000490c:	bfc5                	j	800048fc <filestat+0x60>

000000008000490e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000490e:	7179                	addi	sp,sp,-48
    80004910:	f406                	sd	ra,40(sp)
    80004912:	f022                	sd	s0,32(sp)
    80004914:	ec26                	sd	s1,24(sp)
    80004916:	e84a                	sd	s2,16(sp)
    80004918:	e44e                	sd	s3,8(sp)
    8000491a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000491c:	00854783          	lbu	a5,8(a0)
    80004920:	c3d5                	beqz	a5,800049c4 <fileread+0xb6>
    80004922:	84aa                	mv	s1,a0
    80004924:	89ae                	mv	s3,a1
    80004926:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004928:	411c                	lw	a5,0(a0)
    8000492a:	4705                	li	a4,1
    8000492c:	04e78963          	beq	a5,a4,8000497e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004930:	470d                	li	a4,3
    80004932:	04e78d63          	beq	a5,a4,8000498c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004936:	4709                	li	a4,2
    80004938:	06e79e63          	bne	a5,a4,800049b4 <fileread+0xa6>
    ilock(f->ip);
    8000493c:	6d08                	ld	a0,24(a0)
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	002080e7          	jalr	2(ra) # 80003940 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004946:	874a                	mv	a4,s2
    80004948:	5094                	lw	a3,32(s1)
    8000494a:	864e                	mv	a2,s3
    8000494c:	4585                	li	a1,1
    8000494e:	6c88                	ld	a0,24(s1)
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	2a4080e7          	jalr	676(ra) # 80003bf4 <readi>
    80004958:	892a                	mv	s2,a0
    8000495a:	00a05563          	blez	a0,80004964 <fileread+0x56>
      f->off += r;
    8000495e:	509c                	lw	a5,32(s1)
    80004960:	9fa9                	addw	a5,a5,a0
    80004962:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004964:	6c88                	ld	a0,24(s1)
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	09c080e7          	jalr	156(ra) # 80003a02 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000496e:	854a                	mv	a0,s2
    80004970:	70a2                	ld	ra,40(sp)
    80004972:	7402                	ld	s0,32(sp)
    80004974:	64e2                	ld	s1,24(sp)
    80004976:	6942                	ld	s2,16(sp)
    80004978:	69a2                	ld	s3,8(sp)
    8000497a:	6145                	addi	sp,sp,48
    8000497c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000497e:	6908                	ld	a0,16(a0)
    80004980:	00000097          	auipc	ra,0x0
    80004984:	3c6080e7          	jalr	966(ra) # 80004d46 <piperead>
    80004988:	892a                	mv	s2,a0
    8000498a:	b7d5                	j	8000496e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000498c:	02451783          	lh	a5,36(a0)
    80004990:	03079693          	slli	a3,a5,0x30
    80004994:	92c1                	srli	a3,a3,0x30
    80004996:	4725                	li	a4,9
    80004998:	02d76863          	bltu	a4,a3,800049c8 <fileread+0xba>
    8000499c:	0792                	slli	a5,a5,0x4
    8000499e:	0023e717          	auipc	a4,0x23e
    800049a2:	a7a70713          	addi	a4,a4,-1414 # 80242418 <devsw>
    800049a6:	97ba                	add	a5,a5,a4
    800049a8:	639c                	ld	a5,0(a5)
    800049aa:	c38d                	beqz	a5,800049cc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ac:	4505                	li	a0,1
    800049ae:	9782                	jalr	a5
    800049b0:	892a                	mv	s2,a0
    800049b2:	bf75                	j	8000496e <fileread+0x60>
    panic("fileread");
    800049b4:	00004517          	auipc	a0,0x4
    800049b8:	d4450513          	addi	a0,a0,-700 # 800086f8 <syscalls+0x270>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	b84080e7          	jalr	-1148(ra) # 80000540 <panic>
    return -1;
    800049c4:	597d                	li	s2,-1
    800049c6:	b765                	j	8000496e <fileread+0x60>
      return -1;
    800049c8:	597d                	li	s2,-1
    800049ca:	b755                	j	8000496e <fileread+0x60>
    800049cc:	597d                	li	s2,-1
    800049ce:	b745                	j	8000496e <fileread+0x60>

00000000800049d0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049d0:	715d                	addi	sp,sp,-80
    800049d2:	e486                	sd	ra,72(sp)
    800049d4:	e0a2                	sd	s0,64(sp)
    800049d6:	fc26                	sd	s1,56(sp)
    800049d8:	f84a                	sd	s2,48(sp)
    800049da:	f44e                	sd	s3,40(sp)
    800049dc:	f052                	sd	s4,32(sp)
    800049de:	ec56                	sd	s5,24(sp)
    800049e0:	e85a                	sd	s6,16(sp)
    800049e2:	e45e                	sd	s7,8(sp)
    800049e4:	e062                	sd	s8,0(sp)
    800049e6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049e8:	00954783          	lbu	a5,9(a0)
    800049ec:	10078663          	beqz	a5,80004af8 <filewrite+0x128>
    800049f0:	892a                	mv	s2,a0
    800049f2:	8b2e                	mv	s6,a1
    800049f4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f6:	411c                	lw	a5,0(a0)
    800049f8:	4705                	li	a4,1
    800049fa:	02e78263          	beq	a5,a4,80004a1e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049fe:	470d                	li	a4,3
    80004a00:	02e78663          	beq	a5,a4,80004a2c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a04:	4709                	li	a4,2
    80004a06:	0ee79163          	bne	a5,a4,80004ae8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a0a:	0ac05d63          	blez	a2,80004ac4 <filewrite+0xf4>
    int i = 0;
    80004a0e:	4981                	li	s3,0
    80004a10:	6b85                	lui	s7,0x1
    80004a12:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a16:	6c05                	lui	s8,0x1
    80004a18:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a1c:	a861                	j	80004ab4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a1e:	6908                	ld	a0,16(a0)
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	22e080e7          	jalr	558(ra) # 80004c4e <pipewrite>
    80004a28:	8a2a                	mv	s4,a0
    80004a2a:	a045                	j	80004aca <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a2c:	02451783          	lh	a5,36(a0)
    80004a30:	03079693          	slli	a3,a5,0x30
    80004a34:	92c1                	srli	a3,a3,0x30
    80004a36:	4725                	li	a4,9
    80004a38:	0cd76263          	bltu	a4,a3,80004afc <filewrite+0x12c>
    80004a3c:	0792                	slli	a5,a5,0x4
    80004a3e:	0023e717          	auipc	a4,0x23e
    80004a42:	9da70713          	addi	a4,a4,-1574 # 80242418 <devsw>
    80004a46:	97ba                	add	a5,a5,a4
    80004a48:	679c                	ld	a5,8(a5)
    80004a4a:	cbdd                	beqz	a5,80004b00 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a4c:	4505                	li	a0,1
    80004a4e:	9782                	jalr	a5
    80004a50:	8a2a                	mv	s4,a0
    80004a52:	a8a5                	j	80004aca <filewrite+0xfa>
    80004a54:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	8b4080e7          	jalr	-1868(ra) # 8000430c <begin_op>
      ilock(f->ip);
    80004a60:	01893503          	ld	a0,24(s2)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	edc080e7          	jalr	-292(ra) # 80003940 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a6c:	8756                	mv	a4,s5
    80004a6e:	02092683          	lw	a3,32(s2)
    80004a72:	01698633          	add	a2,s3,s6
    80004a76:	4585                	li	a1,1
    80004a78:	01893503          	ld	a0,24(s2)
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	270080e7          	jalr	624(ra) # 80003cec <writei>
    80004a84:	84aa                	mv	s1,a0
    80004a86:	00a05763          	blez	a0,80004a94 <filewrite+0xc4>
        f->off += r;
    80004a8a:	02092783          	lw	a5,32(s2)
    80004a8e:	9fa9                	addw	a5,a5,a0
    80004a90:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a94:	01893503          	ld	a0,24(s2)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	f6a080e7          	jalr	-150(ra) # 80003a02 <iunlock>
      end_op();
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	8ea080e7          	jalr	-1814(ra) # 8000438a <end_op>

      if(r != n1){
    80004aa8:	009a9f63          	bne	s5,s1,80004ac6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aac:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ab0:	0149db63          	bge	s3,s4,80004ac6 <filewrite+0xf6>
      int n1 = n - i;
    80004ab4:	413a04bb          	subw	s1,s4,s3
    80004ab8:	0004879b          	sext.w	a5,s1
    80004abc:	f8fbdce3          	bge	s7,a5,80004a54 <filewrite+0x84>
    80004ac0:	84e2                	mv	s1,s8
    80004ac2:	bf49                	j	80004a54 <filewrite+0x84>
    int i = 0;
    80004ac4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ac6:	013a1f63          	bne	s4,s3,80004ae4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aca:	8552                	mv	a0,s4
    80004acc:	60a6                	ld	ra,72(sp)
    80004ace:	6406                	ld	s0,64(sp)
    80004ad0:	74e2                	ld	s1,56(sp)
    80004ad2:	7942                	ld	s2,48(sp)
    80004ad4:	79a2                	ld	s3,40(sp)
    80004ad6:	7a02                	ld	s4,32(sp)
    80004ad8:	6ae2                	ld	s5,24(sp)
    80004ada:	6b42                	ld	s6,16(sp)
    80004adc:	6ba2                	ld	s7,8(sp)
    80004ade:	6c02                	ld	s8,0(sp)
    80004ae0:	6161                	addi	sp,sp,80
    80004ae2:	8082                	ret
    ret = (i == n ? n : -1);
    80004ae4:	5a7d                	li	s4,-1
    80004ae6:	b7d5                	j	80004aca <filewrite+0xfa>
    panic("filewrite");
    80004ae8:	00004517          	auipc	a0,0x4
    80004aec:	c2050513          	addi	a0,a0,-992 # 80008708 <syscalls+0x280>
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	a50080e7          	jalr	-1456(ra) # 80000540 <panic>
    return -1;
    80004af8:	5a7d                	li	s4,-1
    80004afa:	bfc1                	j	80004aca <filewrite+0xfa>
      return -1;
    80004afc:	5a7d                	li	s4,-1
    80004afe:	b7f1                	j	80004aca <filewrite+0xfa>
    80004b00:	5a7d                	li	s4,-1
    80004b02:	b7e1                	j	80004aca <filewrite+0xfa>

0000000080004b04 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b04:	7179                	addi	sp,sp,-48
    80004b06:	f406                	sd	ra,40(sp)
    80004b08:	f022                	sd	s0,32(sp)
    80004b0a:	ec26                	sd	s1,24(sp)
    80004b0c:	e84a                	sd	s2,16(sp)
    80004b0e:	e44e                	sd	s3,8(sp)
    80004b10:	e052                	sd	s4,0(sp)
    80004b12:	1800                	addi	s0,sp,48
    80004b14:	84aa                	mv	s1,a0
    80004b16:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b18:	0005b023          	sd	zero,0(a1)
    80004b1c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	bf8080e7          	jalr	-1032(ra) # 80004718 <filealloc>
    80004b28:	e088                	sd	a0,0(s1)
    80004b2a:	c551                	beqz	a0,80004bb6 <pipealloc+0xb2>
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	bec080e7          	jalr	-1044(ra) # 80004718 <filealloc>
    80004b34:	00aa3023          	sd	a0,0(s4)
    80004b38:	c92d                	beqz	a0,80004baa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	0aa080e7          	jalr	170(ra) # 80000be4 <kalloc>
    80004b42:	892a                	mv	s2,a0
    80004b44:	c125                	beqz	a0,80004ba4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b46:	4985                	li	s3,1
    80004b48:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b4c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b50:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b54:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b58:	00004597          	auipc	a1,0x4
    80004b5c:	bc058593          	addi	a1,a1,-1088 # 80008718 <syscalls+0x290>
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	11c080e7          	jalr	284(ra) # 80000c7c <initlock>
  (*f0)->type = FD_PIPE;
    80004b68:	609c                	ld	a5,0(s1)
    80004b6a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b6e:	609c                	ld	a5,0(s1)
    80004b70:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b74:	609c                	ld	a5,0(s1)
    80004b76:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b7a:	609c                	ld	a5,0(s1)
    80004b7c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b80:	000a3783          	ld	a5,0(s4)
    80004b84:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b88:	000a3783          	ld	a5,0(s4)
    80004b8c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b90:	000a3783          	ld	a5,0(s4)
    80004b94:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b98:	000a3783          	ld	a5,0(s4)
    80004b9c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ba0:	4501                	li	a0,0
    80004ba2:	a025                	j	80004bca <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ba4:	6088                	ld	a0,0(s1)
    80004ba6:	e501                	bnez	a0,80004bae <pipealloc+0xaa>
    80004ba8:	a039                	j	80004bb6 <pipealloc+0xb2>
    80004baa:	6088                	ld	a0,0(s1)
    80004bac:	c51d                	beqz	a0,80004bda <pipealloc+0xd6>
    fileclose(*f0);
    80004bae:	00000097          	auipc	ra,0x0
    80004bb2:	c26080e7          	jalr	-986(ra) # 800047d4 <fileclose>
  if(*f1)
    80004bb6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bba:	557d                	li	a0,-1
  if(*f1)
    80004bbc:	c799                	beqz	a5,80004bca <pipealloc+0xc6>
    fileclose(*f1);
    80004bbe:	853e                	mv	a0,a5
    80004bc0:	00000097          	auipc	ra,0x0
    80004bc4:	c14080e7          	jalr	-1004(ra) # 800047d4 <fileclose>
  return -1;
    80004bc8:	557d                	li	a0,-1
}
    80004bca:	70a2                	ld	ra,40(sp)
    80004bcc:	7402                	ld	s0,32(sp)
    80004bce:	64e2                	ld	s1,24(sp)
    80004bd0:	6942                	ld	s2,16(sp)
    80004bd2:	69a2                	ld	s3,8(sp)
    80004bd4:	6a02                	ld	s4,0(sp)
    80004bd6:	6145                	addi	sp,sp,48
    80004bd8:	8082                	ret
  return -1;
    80004bda:	557d                	li	a0,-1
    80004bdc:	b7fd                	j	80004bca <pipealloc+0xc6>

0000000080004bde <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bde:	1101                	addi	sp,sp,-32
    80004be0:	ec06                	sd	ra,24(sp)
    80004be2:	e822                	sd	s0,16(sp)
    80004be4:	e426                	sd	s1,8(sp)
    80004be6:	e04a                	sd	s2,0(sp)
    80004be8:	1000                	addi	s0,sp,32
    80004bea:	84aa                	mv	s1,a0
    80004bec:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	11e080e7          	jalr	286(ra) # 80000d0c <acquire>
  if(writable){
    80004bf6:	02090d63          	beqz	s2,80004c30 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bfa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bfe:	21848513          	addi	a0,s1,536
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	606080e7          	jalr	1542(ra) # 80002208 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c0a:	2204b783          	ld	a5,544(s1)
    80004c0e:	eb95                	bnez	a5,80004c42 <pipeclose+0x64>
    release(&pi->lock);
    80004c10:	8526                	mv	a0,s1
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	1ae080e7          	jalr	430(ra) # 80000dc0 <release>
    kfree((char*)pi);
    80004c1a:	8526                	mv	a0,s1
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	e44080e7          	jalr	-444(ra) # 80000a60 <kfree>
  } else
    release(&pi->lock);
}
    80004c24:	60e2                	ld	ra,24(sp)
    80004c26:	6442                	ld	s0,16(sp)
    80004c28:	64a2                	ld	s1,8(sp)
    80004c2a:	6902                	ld	s2,0(sp)
    80004c2c:	6105                	addi	sp,sp,32
    80004c2e:	8082                	ret
    pi->readopen = 0;
    80004c30:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c34:	21c48513          	addi	a0,s1,540
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	5d0080e7          	jalr	1488(ra) # 80002208 <wakeup>
    80004c40:	b7e9                	j	80004c0a <pipeclose+0x2c>
    release(&pi->lock);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	17c080e7          	jalr	380(ra) # 80000dc0 <release>
}
    80004c4c:	bfe1                	j	80004c24 <pipeclose+0x46>

0000000080004c4e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c4e:	711d                	addi	sp,sp,-96
    80004c50:	ec86                	sd	ra,88(sp)
    80004c52:	e8a2                	sd	s0,80(sp)
    80004c54:	e4a6                	sd	s1,72(sp)
    80004c56:	e0ca                	sd	s2,64(sp)
    80004c58:	fc4e                	sd	s3,56(sp)
    80004c5a:	f852                	sd	s4,48(sp)
    80004c5c:	f456                	sd	s5,40(sp)
    80004c5e:	f05a                	sd	s6,32(sp)
    80004c60:	ec5e                	sd	s7,24(sp)
    80004c62:	e862                	sd	s8,16(sp)
    80004c64:	1080                	addi	s0,sp,96
    80004c66:	84aa                	mv	s1,a0
    80004c68:	8aae                	mv	s5,a1
    80004c6a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	e90080e7          	jalr	-368(ra) # 80001afc <myproc>
    80004c74:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	094080e7          	jalr	148(ra) # 80000d0c <acquire>
  while(i < n){
    80004c80:	0b405663          	blez	s4,80004d2c <pipewrite+0xde>
  int i = 0;
    80004c84:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c86:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c88:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c8c:	21c48b93          	addi	s7,s1,540
    80004c90:	a089                	j	80004cd2 <pipewrite+0x84>
      release(&pi->lock);
    80004c92:	8526                	mv	a0,s1
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	12c080e7          	jalr	300(ra) # 80000dc0 <release>
      return -1;
    80004c9c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c9e:	854a                	mv	a0,s2
    80004ca0:	60e6                	ld	ra,88(sp)
    80004ca2:	6446                	ld	s0,80(sp)
    80004ca4:	64a6                	ld	s1,72(sp)
    80004ca6:	6906                	ld	s2,64(sp)
    80004ca8:	79e2                	ld	s3,56(sp)
    80004caa:	7a42                	ld	s4,48(sp)
    80004cac:	7aa2                	ld	s5,40(sp)
    80004cae:	7b02                	ld	s6,32(sp)
    80004cb0:	6be2                	ld	s7,24(sp)
    80004cb2:	6c42                	ld	s8,16(sp)
    80004cb4:	6125                	addi	sp,sp,96
    80004cb6:	8082                	ret
      wakeup(&pi->nread);
    80004cb8:	8562                	mv	a0,s8
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	54e080e7          	jalr	1358(ra) # 80002208 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cc2:	85a6                	mv	a1,s1
    80004cc4:	855e                	mv	a0,s7
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	4de080e7          	jalr	1246(ra) # 800021a4 <sleep>
  while(i < n){
    80004cce:	07495063          	bge	s2,s4,80004d2e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004cd2:	2204a783          	lw	a5,544(s1)
    80004cd6:	dfd5                	beqz	a5,80004c92 <pipewrite+0x44>
    80004cd8:	854e                	mv	a0,s3
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	772080e7          	jalr	1906(ra) # 8000244c <killed>
    80004ce2:	f945                	bnez	a0,80004c92 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ce4:	2184a783          	lw	a5,536(s1)
    80004ce8:	21c4a703          	lw	a4,540(s1)
    80004cec:	2007879b          	addiw	a5,a5,512
    80004cf0:	fcf704e3          	beq	a4,a5,80004cb8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cf4:	4685                	li	a3,1
    80004cf6:	01590633          	add	a2,s2,s5
    80004cfa:	faf40593          	addi	a1,s0,-81
    80004cfe:	0509b503          	ld	a0,80(s3)
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	b46080e7          	jalr	-1210(ra) # 80001848 <copyin>
    80004d0a:	03650263          	beq	a0,s6,80004d2e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d0e:	21c4a783          	lw	a5,540(s1)
    80004d12:	0017871b          	addiw	a4,a5,1
    80004d16:	20e4ae23          	sw	a4,540(s1)
    80004d1a:	1ff7f793          	andi	a5,a5,511
    80004d1e:	97a6                	add	a5,a5,s1
    80004d20:	faf44703          	lbu	a4,-81(s0)
    80004d24:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d28:	2905                	addiw	s2,s2,1
    80004d2a:	b755                	j	80004cce <pipewrite+0x80>
  int i = 0;
    80004d2c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d2e:	21848513          	addi	a0,s1,536
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	4d6080e7          	jalr	1238(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	084080e7          	jalr	132(ra) # 80000dc0 <release>
  return i;
    80004d44:	bfa9                	j	80004c9e <pipewrite+0x50>

0000000080004d46 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d46:	715d                	addi	sp,sp,-80
    80004d48:	e486                	sd	ra,72(sp)
    80004d4a:	e0a2                	sd	s0,64(sp)
    80004d4c:	fc26                	sd	s1,56(sp)
    80004d4e:	f84a                	sd	s2,48(sp)
    80004d50:	f44e                	sd	s3,40(sp)
    80004d52:	f052                	sd	s4,32(sp)
    80004d54:	ec56                	sd	s5,24(sp)
    80004d56:	e85a                	sd	s6,16(sp)
    80004d58:	0880                	addi	s0,sp,80
    80004d5a:	84aa                	mv	s1,a0
    80004d5c:	892e                	mv	s2,a1
    80004d5e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	d9c080e7          	jalr	-612(ra) # 80001afc <myproc>
    80004d68:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	fa0080e7          	jalr	-96(ra) # 80000d0c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d74:	2184a703          	lw	a4,536(s1)
    80004d78:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d7c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d80:	02f71763          	bne	a4,a5,80004dae <piperead+0x68>
    80004d84:	2244a783          	lw	a5,548(s1)
    80004d88:	c39d                	beqz	a5,80004dae <piperead+0x68>
    if(killed(pr)){
    80004d8a:	8552                	mv	a0,s4
    80004d8c:	ffffd097          	auipc	ra,0xffffd
    80004d90:	6c0080e7          	jalr	1728(ra) # 8000244c <killed>
    80004d94:	e949                	bnez	a0,80004e26 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d96:	85a6                	mv	a1,s1
    80004d98:	854e                	mv	a0,s3
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	40a080e7          	jalr	1034(ra) # 800021a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da2:	2184a703          	lw	a4,536(s1)
    80004da6:	21c4a783          	lw	a5,540(s1)
    80004daa:	fcf70de3          	beq	a4,a5,80004d84 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dae:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004db0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db2:	05505463          	blez	s5,80004dfa <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004db6:	2184a783          	lw	a5,536(s1)
    80004dba:	21c4a703          	lw	a4,540(s1)
    80004dbe:	02f70e63          	beq	a4,a5,80004dfa <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dc2:	0017871b          	addiw	a4,a5,1
    80004dc6:	20e4ac23          	sw	a4,536(s1)
    80004dca:	1ff7f793          	andi	a5,a5,511
    80004dce:	97a6                	add	a5,a5,s1
    80004dd0:	0187c783          	lbu	a5,24(a5)
    80004dd4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd8:	4685                	li	a3,1
    80004dda:	fbf40613          	addi	a2,s0,-65
    80004dde:	85ca                	mv	a1,s2
    80004de0:	050a3503          	ld	a0,80(s4)
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	9a4080e7          	jalr	-1628(ra) # 80001788 <copyout>
    80004dec:	01650763          	beq	a0,s6,80004dfa <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df0:	2985                	addiw	s3,s3,1
    80004df2:	0905                	addi	s2,s2,1
    80004df4:	fd3a91e3          	bne	s5,s3,80004db6 <piperead+0x70>
    80004df8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dfa:	21c48513          	addi	a0,s1,540
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	40a080e7          	jalr	1034(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004e06:	8526                	mv	a0,s1
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	fb8080e7          	jalr	-72(ra) # 80000dc0 <release>
  return i;
}
    80004e10:	854e                	mv	a0,s3
    80004e12:	60a6                	ld	ra,72(sp)
    80004e14:	6406                	ld	s0,64(sp)
    80004e16:	74e2                	ld	s1,56(sp)
    80004e18:	7942                	ld	s2,48(sp)
    80004e1a:	79a2                	ld	s3,40(sp)
    80004e1c:	7a02                	ld	s4,32(sp)
    80004e1e:	6ae2                	ld	s5,24(sp)
    80004e20:	6b42                	ld	s6,16(sp)
    80004e22:	6161                	addi	sp,sp,80
    80004e24:	8082                	ret
      release(&pi->lock);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	f98080e7          	jalr	-104(ra) # 80000dc0 <release>
      return -1;
    80004e30:	59fd                	li	s3,-1
    80004e32:	bff9                	j	80004e10 <piperead+0xca>

0000000080004e34 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e34:	1141                	addi	sp,sp,-16
    80004e36:	e422                	sd	s0,8(sp)
    80004e38:	0800                	addi	s0,sp,16
    80004e3a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e3c:	8905                	andi	a0,a0,1
    80004e3e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004e40:	8b89                	andi	a5,a5,2
    80004e42:	c399                	beqz	a5,80004e48 <flags2perm+0x14>
      perm |= PTE_W;
    80004e44:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e48:	6422                	ld	s0,8(sp)
    80004e4a:	0141                	addi	sp,sp,16
    80004e4c:	8082                	ret

0000000080004e4e <exec>:

int
exec(char *path, char **argv)
{
    80004e4e:	de010113          	addi	sp,sp,-544
    80004e52:	20113c23          	sd	ra,536(sp)
    80004e56:	20813823          	sd	s0,528(sp)
    80004e5a:	20913423          	sd	s1,520(sp)
    80004e5e:	21213023          	sd	s2,512(sp)
    80004e62:	ffce                	sd	s3,504(sp)
    80004e64:	fbd2                	sd	s4,496(sp)
    80004e66:	f7d6                	sd	s5,488(sp)
    80004e68:	f3da                	sd	s6,480(sp)
    80004e6a:	efde                	sd	s7,472(sp)
    80004e6c:	ebe2                	sd	s8,464(sp)
    80004e6e:	e7e6                	sd	s9,456(sp)
    80004e70:	e3ea                	sd	s10,448(sp)
    80004e72:	ff6e                	sd	s11,440(sp)
    80004e74:	1400                	addi	s0,sp,544
    80004e76:	892a                	mv	s2,a0
    80004e78:	dea43423          	sd	a0,-536(s0)
    80004e7c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	c7c080e7          	jalr	-900(ra) # 80001afc <myproc>
    80004e88:	84aa                	mv	s1,a0

  begin_op();
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	482080e7          	jalr	1154(ra) # 8000430c <begin_op>

  if((ip = namei(path)) == 0){
    80004e92:	854a                	mv	a0,s2
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	258080e7          	jalr	600(ra) # 800040ec <namei>
    80004e9c:	c93d                	beqz	a0,80004f12 <exec+0xc4>
    80004e9e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	aa0080e7          	jalr	-1376(ra) # 80003940 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea8:	04000713          	li	a4,64
    80004eac:	4681                	li	a3,0
    80004eae:	e5040613          	addi	a2,s0,-432
    80004eb2:	4581                	li	a1,0
    80004eb4:	8556                	mv	a0,s5
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	d3e080e7          	jalr	-706(ra) # 80003bf4 <readi>
    80004ebe:	04000793          	li	a5,64
    80004ec2:	00f51a63          	bne	a0,a5,80004ed6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ec6:	e5042703          	lw	a4,-432(s0)
    80004eca:	464c47b7          	lui	a5,0x464c4
    80004ece:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ed2:	04f70663          	beq	a4,a5,80004f1e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed6:	8556                	mv	a0,s5
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	cca080e7          	jalr	-822(ra) # 80003ba2 <iunlockput>
    end_op();
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	4aa080e7          	jalr	1194(ra) # 8000438a <end_op>
  }
  return -1;
    80004ee8:	557d                	li	a0,-1
}
    80004eea:	21813083          	ld	ra,536(sp)
    80004eee:	21013403          	ld	s0,528(sp)
    80004ef2:	20813483          	ld	s1,520(sp)
    80004ef6:	20013903          	ld	s2,512(sp)
    80004efa:	79fe                	ld	s3,504(sp)
    80004efc:	7a5e                	ld	s4,496(sp)
    80004efe:	7abe                	ld	s5,488(sp)
    80004f00:	7b1e                	ld	s6,480(sp)
    80004f02:	6bfe                	ld	s7,472(sp)
    80004f04:	6c5e                	ld	s8,464(sp)
    80004f06:	6cbe                	ld	s9,456(sp)
    80004f08:	6d1e                	ld	s10,448(sp)
    80004f0a:	7dfa                	ld	s11,440(sp)
    80004f0c:	22010113          	addi	sp,sp,544
    80004f10:	8082                	ret
    end_op();
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	478080e7          	jalr	1144(ra) # 8000438a <end_op>
    return -1;
    80004f1a:	557d                	li	a0,-1
    80004f1c:	b7f9                	j	80004eea <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f1e:	8526                	mv	a0,s1
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	ca0080e7          	jalr	-864(ra) # 80001bc0 <proc_pagetable>
    80004f28:	8b2a                	mv	s6,a0
    80004f2a:	d555                	beqz	a0,80004ed6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f2c:	e7042783          	lw	a5,-400(s0)
    80004f30:	e8845703          	lhu	a4,-376(s0)
    80004f34:	c735                	beqz	a4,80004fa0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f36:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f38:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f3c:	6a05                	lui	s4,0x1
    80004f3e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f42:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f46:	6d85                	lui	s11,0x1
    80004f48:	7d7d                	lui	s10,0xfffff
    80004f4a:	ac3d                	j	80005188 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f4c:	00003517          	auipc	a0,0x3
    80004f50:	7d450513          	addi	a0,a0,2004 # 80008720 <syscalls+0x298>
    80004f54:	ffffb097          	auipc	ra,0xffffb
    80004f58:	5ec080e7          	jalr	1516(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f5c:	874a                	mv	a4,s2
    80004f5e:	009c86bb          	addw	a3,s9,s1
    80004f62:	4581                	li	a1,0
    80004f64:	8556                	mv	a0,s5
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	c8e080e7          	jalr	-882(ra) # 80003bf4 <readi>
    80004f6e:	2501                	sext.w	a0,a0
    80004f70:	1aa91963          	bne	s2,a0,80005122 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004f74:	009d84bb          	addw	s1,s11,s1
    80004f78:	013d09bb          	addw	s3,s10,s3
    80004f7c:	1f74f663          	bgeu	s1,s7,80005168 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004f80:	02049593          	slli	a1,s1,0x20
    80004f84:	9181                	srli	a1,a1,0x20
    80004f86:	95e2                	add	a1,a1,s8
    80004f88:	855a                	mv	a0,s6
    80004f8a:	ffffc097          	auipc	ra,0xffffc
    80004f8e:	208080e7          	jalr	520(ra) # 80001192 <walkaddr>
    80004f92:	862a                	mv	a2,a0
    if(pa == 0)
    80004f94:	dd45                	beqz	a0,80004f4c <exec+0xfe>
      n = PGSIZE;
    80004f96:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f98:	fd49f2e3          	bgeu	s3,s4,80004f5c <exec+0x10e>
      n = sz - i;
    80004f9c:	894e                	mv	s2,s3
    80004f9e:	bf7d                	j	80004f5c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fa0:	4901                	li	s2,0
  iunlockput(ip);
    80004fa2:	8556                	mv	a0,s5
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	bfe080e7          	jalr	-1026(ra) # 80003ba2 <iunlockput>
  end_op();
    80004fac:	fffff097          	auipc	ra,0xfffff
    80004fb0:	3de080e7          	jalr	990(ra) # 8000438a <end_op>
  p = myproc();
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	b48080e7          	jalr	-1208(ra) # 80001afc <myproc>
    80004fbc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fbe:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fc2:	6785                	lui	a5,0x1
    80004fc4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004fc6:	97ca                	add	a5,a5,s2
    80004fc8:	777d                	lui	a4,0xfffff
    80004fca:	8ff9                	and	a5,a5,a4
    80004fcc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fd0:	4691                	li	a3,4
    80004fd2:	6609                	lui	a2,0x2
    80004fd4:	963e                	add	a2,a2,a5
    80004fd6:	85be                	mv	a1,a5
    80004fd8:	855a                	mv	a0,s6
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	56c080e7          	jalr	1388(ra) # 80001546 <uvmalloc>
    80004fe2:	8c2a                	mv	s8,a0
  ip = 0;
    80004fe4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fe6:	12050e63          	beqz	a0,80005122 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fea:	75f9                	lui	a1,0xffffe
    80004fec:	95aa                	add	a1,a1,a0
    80004fee:	855a                	mv	a0,s6
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	766080e7          	jalr	1894(ra) # 80001756 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ff8:	7afd                	lui	s5,0xfffff
    80004ffa:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ffc:	df043783          	ld	a5,-528(s0)
    80005000:	6388                	ld	a0,0(a5)
    80005002:	c925                	beqz	a0,80005072 <exec+0x224>
    80005004:	e9040993          	addi	s3,s0,-368
    80005008:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000500c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000500e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	f74080e7          	jalr	-140(ra) # 80000f84 <strlen>
    80005018:	0015079b          	addiw	a5,a0,1
    8000501c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005020:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005024:	13596663          	bltu	s2,s5,80005150 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005028:	df043d83          	ld	s11,-528(s0)
    8000502c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005030:	8552                	mv	a0,s4
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	f52080e7          	jalr	-174(ra) # 80000f84 <strlen>
    8000503a:	0015069b          	addiw	a3,a0,1
    8000503e:	8652                	mv	a2,s4
    80005040:	85ca                	mv	a1,s2
    80005042:	855a                	mv	a0,s6
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	744080e7          	jalr	1860(ra) # 80001788 <copyout>
    8000504c:	10054663          	bltz	a0,80005158 <exec+0x30a>
    ustack[argc] = sp;
    80005050:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005054:	0485                	addi	s1,s1,1
    80005056:	008d8793          	addi	a5,s11,8
    8000505a:	def43823          	sd	a5,-528(s0)
    8000505e:	008db503          	ld	a0,8(s11)
    80005062:	c911                	beqz	a0,80005076 <exec+0x228>
    if(argc >= MAXARG)
    80005064:	09a1                	addi	s3,s3,8
    80005066:	fb3c95e3          	bne	s9,s3,80005010 <exec+0x1c2>
  sz = sz1;
    8000506a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000506e:	4a81                	li	s5,0
    80005070:	a84d                	j	80005122 <exec+0x2d4>
  sp = sz;
    80005072:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005074:	4481                	li	s1,0
  ustack[argc] = 0;
    80005076:	00349793          	slli	a5,s1,0x3
    8000507a:	f9078793          	addi	a5,a5,-112
    8000507e:	97a2                	add	a5,a5,s0
    80005080:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005084:	00148693          	addi	a3,s1,1
    80005088:	068e                	slli	a3,a3,0x3
    8000508a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000508e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005092:	01597663          	bgeu	s2,s5,8000509e <exec+0x250>
  sz = sz1;
    80005096:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000509a:	4a81                	li	s5,0
    8000509c:	a059                	j	80005122 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000509e:	e9040613          	addi	a2,s0,-368
    800050a2:	85ca                	mv	a1,s2
    800050a4:	855a                	mv	a0,s6
    800050a6:	ffffc097          	auipc	ra,0xffffc
    800050aa:	6e2080e7          	jalr	1762(ra) # 80001788 <copyout>
    800050ae:	0a054963          	bltz	a0,80005160 <exec+0x312>
  p->trapframe->a1 = sp;
    800050b2:	058bb783          	ld	a5,88(s7)
    800050b6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050ba:	de843783          	ld	a5,-536(s0)
    800050be:	0007c703          	lbu	a4,0(a5)
    800050c2:	cf11                	beqz	a4,800050de <exec+0x290>
    800050c4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050c6:	02f00693          	li	a3,47
    800050ca:	a039                	j	800050d8 <exec+0x28a>
      last = s+1;
    800050cc:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050d0:	0785                	addi	a5,a5,1
    800050d2:	fff7c703          	lbu	a4,-1(a5)
    800050d6:	c701                	beqz	a4,800050de <exec+0x290>
    if(*s == '/')
    800050d8:	fed71ce3          	bne	a4,a3,800050d0 <exec+0x282>
    800050dc:	bfc5                	j	800050cc <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800050de:	4641                	li	a2,16
    800050e0:	de843583          	ld	a1,-536(s0)
    800050e4:	158b8513          	addi	a0,s7,344
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	e6a080e7          	jalr	-406(ra) # 80000f52 <safestrcpy>
  oldpagetable = p->pagetable;
    800050f0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050f4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050f8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050fc:	058bb783          	ld	a5,88(s7)
    80005100:	e6843703          	ld	a4,-408(s0)
    80005104:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005106:	058bb783          	ld	a5,88(s7)
    8000510a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000510e:	85ea                	mv	a1,s10
    80005110:	ffffd097          	auipc	ra,0xffffd
    80005114:	b4c080e7          	jalr	-1204(ra) # 80001c5c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005118:	0004851b          	sext.w	a0,s1
    8000511c:	b3f9                	j	80004eea <exec+0x9c>
    8000511e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005122:	df843583          	ld	a1,-520(s0)
    80005126:	855a                	mv	a0,s6
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	b34080e7          	jalr	-1228(ra) # 80001c5c <proc_freepagetable>
  if(ip){
    80005130:	da0a93e3          	bnez	s5,80004ed6 <exec+0x88>
  return -1;
    80005134:	557d                	li	a0,-1
    80005136:	bb55                	j	80004eea <exec+0x9c>
    80005138:	df243c23          	sd	s2,-520(s0)
    8000513c:	b7dd                	j	80005122 <exec+0x2d4>
    8000513e:	df243c23          	sd	s2,-520(s0)
    80005142:	b7c5                	j	80005122 <exec+0x2d4>
    80005144:	df243c23          	sd	s2,-520(s0)
    80005148:	bfe9                	j	80005122 <exec+0x2d4>
    8000514a:	df243c23          	sd	s2,-520(s0)
    8000514e:	bfd1                	j	80005122 <exec+0x2d4>
  sz = sz1;
    80005150:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005154:	4a81                	li	s5,0
    80005156:	b7f1                	j	80005122 <exec+0x2d4>
  sz = sz1;
    80005158:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000515c:	4a81                	li	s5,0
    8000515e:	b7d1                	j	80005122 <exec+0x2d4>
  sz = sz1;
    80005160:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005164:	4a81                	li	s5,0
    80005166:	bf75                	j	80005122 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005168:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000516c:	e0843783          	ld	a5,-504(s0)
    80005170:	0017869b          	addiw	a3,a5,1
    80005174:	e0d43423          	sd	a3,-504(s0)
    80005178:	e0043783          	ld	a5,-512(s0)
    8000517c:	0387879b          	addiw	a5,a5,56
    80005180:	e8845703          	lhu	a4,-376(s0)
    80005184:	e0e6dfe3          	bge	a3,a4,80004fa2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005188:	2781                	sext.w	a5,a5
    8000518a:	e0f43023          	sd	a5,-512(s0)
    8000518e:	03800713          	li	a4,56
    80005192:	86be                	mv	a3,a5
    80005194:	e1840613          	addi	a2,s0,-488
    80005198:	4581                	li	a1,0
    8000519a:	8556                	mv	a0,s5
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	a58080e7          	jalr	-1448(ra) # 80003bf4 <readi>
    800051a4:	03800793          	li	a5,56
    800051a8:	f6f51be3          	bne	a0,a5,8000511e <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800051ac:	e1842783          	lw	a5,-488(s0)
    800051b0:	4705                	li	a4,1
    800051b2:	fae79de3          	bne	a5,a4,8000516c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800051b6:	e4043483          	ld	s1,-448(s0)
    800051ba:	e3843783          	ld	a5,-456(s0)
    800051be:	f6f4ede3          	bltu	s1,a5,80005138 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051c2:	e2843783          	ld	a5,-472(s0)
    800051c6:	94be                	add	s1,s1,a5
    800051c8:	f6f4ebe3          	bltu	s1,a5,8000513e <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800051cc:	de043703          	ld	a4,-544(s0)
    800051d0:	8ff9                	and	a5,a5,a4
    800051d2:	fbad                	bnez	a5,80005144 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051d4:	e1c42503          	lw	a0,-484(s0)
    800051d8:	00000097          	auipc	ra,0x0
    800051dc:	c5c080e7          	jalr	-932(ra) # 80004e34 <flags2perm>
    800051e0:	86aa                	mv	a3,a0
    800051e2:	8626                	mv	a2,s1
    800051e4:	85ca                	mv	a1,s2
    800051e6:	855a                	mv	a0,s6
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	35e080e7          	jalr	862(ra) # 80001546 <uvmalloc>
    800051f0:	dea43c23          	sd	a0,-520(s0)
    800051f4:	d939                	beqz	a0,8000514a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051f6:	e2843c03          	ld	s8,-472(s0)
    800051fa:	e2042c83          	lw	s9,-480(s0)
    800051fe:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005202:	f60b83e3          	beqz	s7,80005168 <exec+0x31a>
    80005206:	89de                	mv	s3,s7
    80005208:	4481                	li	s1,0
    8000520a:	bb9d                	j	80004f80 <exec+0x132>

000000008000520c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000520c:	7179                	addi	sp,sp,-48
    8000520e:	f406                	sd	ra,40(sp)
    80005210:	f022                	sd	s0,32(sp)
    80005212:	ec26                	sd	s1,24(sp)
    80005214:	e84a                	sd	s2,16(sp)
    80005216:	1800                	addi	s0,sp,48
    80005218:	892e                	mv	s2,a1
    8000521a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000521c:	fdc40593          	addi	a1,s0,-36
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	a9a080e7          	jalr	-1382(ra) # 80002cba <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005228:	fdc42703          	lw	a4,-36(s0)
    8000522c:	47bd                	li	a5,15
    8000522e:	02e7eb63          	bltu	a5,a4,80005264 <argfd+0x58>
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	8ca080e7          	jalr	-1846(ra) # 80001afc <myproc>
    8000523a:	fdc42703          	lw	a4,-36(s0)
    8000523e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbba6a>
    80005242:	078e                	slli	a5,a5,0x3
    80005244:	953e                	add	a0,a0,a5
    80005246:	611c                	ld	a5,0(a0)
    80005248:	c385                	beqz	a5,80005268 <argfd+0x5c>
    return -1;
  if(pfd)
    8000524a:	00090463          	beqz	s2,80005252 <argfd+0x46>
    *pfd = fd;
    8000524e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005252:	4501                	li	a0,0
  if(pf)
    80005254:	c091                	beqz	s1,80005258 <argfd+0x4c>
    *pf = f;
    80005256:	e09c                	sd	a5,0(s1)
}
    80005258:	70a2                	ld	ra,40(sp)
    8000525a:	7402                	ld	s0,32(sp)
    8000525c:	64e2                	ld	s1,24(sp)
    8000525e:	6942                	ld	s2,16(sp)
    80005260:	6145                	addi	sp,sp,48
    80005262:	8082                	ret
    return -1;
    80005264:	557d                	li	a0,-1
    80005266:	bfcd                	j	80005258 <argfd+0x4c>
    80005268:	557d                	li	a0,-1
    8000526a:	b7fd                	j	80005258 <argfd+0x4c>

000000008000526c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000526c:	1101                	addi	sp,sp,-32
    8000526e:	ec06                	sd	ra,24(sp)
    80005270:	e822                	sd	s0,16(sp)
    80005272:	e426                	sd	s1,8(sp)
    80005274:	1000                	addi	s0,sp,32
    80005276:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005278:	ffffd097          	auipc	ra,0xffffd
    8000527c:	884080e7          	jalr	-1916(ra) # 80001afc <myproc>
    80005280:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005282:	0d050793          	addi	a5,a0,208
    80005286:	4501                	li	a0,0
    80005288:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000528a:	6398                	ld	a4,0(a5)
    8000528c:	cb19                	beqz	a4,800052a2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000528e:	2505                	addiw	a0,a0,1
    80005290:	07a1                	addi	a5,a5,8
    80005292:	fed51ce3          	bne	a0,a3,8000528a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005296:	557d                	li	a0,-1
}
    80005298:	60e2                	ld	ra,24(sp)
    8000529a:	6442                	ld	s0,16(sp)
    8000529c:	64a2                	ld	s1,8(sp)
    8000529e:	6105                	addi	sp,sp,32
    800052a0:	8082                	ret
      p->ofile[fd] = f;
    800052a2:	01a50793          	addi	a5,a0,26
    800052a6:	078e                	slli	a5,a5,0x3
    800052a8:	963e                	add	a2,a2,a5
    800052aa:	e204                	sd	s1,0(a2)
      return fd;
    800052ac:	b7f5                	j	80005298 <fdalloc+0x2c>

00000000800052ae <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ae:	715d                	addi	sp,sp,-80
    800052b0:	e486                	sd	ra,72(sp)
    800052b2:	e0a2                	sd	s0,64(sp)
    800052b4:	fc26                	sd	s1,56(sp)
    800052b6:	f84a                	sd	s2,48(sp)
    800052b8:	f44e                	sd	s3,40(sp)
    800052ba:	f052                	sd	s4,32(sp)
    800052bc:	ec56                	sd	s5,24(sp)
    800052be:	e85a                	sd	s6,16(sp)
    800052c0:	0880                	addi	s0,sp,80
    800052c2:	8b2e                	mv	s6,a1
    800052c4:	89b2                	mv	s3,a2
    800052c6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052c8:	fb040593          	addi	a1,s0,-80
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	e3e080e7          	jalr	-450(ra) # 8000410a <nameiparent>
    800052d4:	84aa                	mv	s1,a0
    800052d6:	14050f63          	beqz	a0,80005434 <create+0x186>
    return 0;

  ilock(dp);
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	666080e7          	jalr	1638(ra) # 80003940 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052e2:	4601                	li	a2,0
    800052e4:	fb040593          	addi	a1,s0,-80
    800052e8:	8526                	mv	a0,s1
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	b3a080e7          	jalr	-1222(ra) # 80003e24 <dirlookup>
    800052f2:	8aaa                	mv	s5,a0
    800052f4:	c931                	beqz	a0,80005348 <create+0x9a>
    iunlockput(dp);
    800052f6:	8526                	mv	a0,s1
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	8aa080e7          	jalr	-1878(ra) # 80003ba2 <iunlockput>
    ilock(ip);
    80005300:	8556                	mv	a0,s5
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	63e080e7          	jalr	1598(ra) # 80003940 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000530a:	000b059b          	sext.w	a1,s6
    8000530e:	4789                	li	a5,2
    80005310:	02f59563          	bne	a1,a5,8000533a <create+0x8c>
    80005314:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbba94>
    80005318:	37f9                	addiw	a5,a5,-2
    8000531a:	17c2                	slli	a5,a5,0x30
    8000531c:	93c1                	srli	a5,a5,0x30
    8000531e:	4705                	li	a4,1
    80005320:	00f76d63          	bltu	a4,a5,8000533a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005324:	8556                	mv	a0,s5
    80005326:	60a6                	ld	ra,72(sp)
    80005328:	6406                	ld	s0,64(sp)
    8000532a:	74e2                	ld	s1,56(sp)
    8000532c:	7942                	ld	s2,48(sp)
    8000532e:	79a2                	ld	s3,40(sp)
    80005330:	7a02                	ld	s4,32(sp)
    80005332:	6ae2                	ld	s5,24(sp)
    80005334:	6b42                	ld	s6,16(sp)
    80005336:	6161                	addi	sp,sp,80
    80005338:	8082                	ret
    iunlockput(ip);
    8000533a:	8556                	mv	a0,s5
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	866080e7          	jalr	-1946(ra) # 80003ba2 <iunlockput>
    return 0;
    80005344:	4a81                	li	s5,0
    80005346:	bff9                	j	80005324 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005348:	85da                	mv	a1,s6
    8000534a:	4088                	lw	a0,0(s1)
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	456080e7          	jalr	1110(ra) # 800037a2 <ialloc>
    80005354:	8a2a                	mv	s4,a0
    80005356:	c539                	beqz	a0,800053a4 <create+0xf6>
  ilock(ip);
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	5e8080e7          	jalr	1512(ra) # 80003940 <ilock>
  ip->major = major;
    80005360:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005364:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005368:	4905                	li	s2,1
    8000536a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000536e:	8552                	mv	a0,s4
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	504080e7          	jalr	1284(ra) # 80003874 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005378:	000b059b          	sext.w	a1,s6
    8000537c:	03258b63          	beq	a1,s2,800053b2 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005380:	004a2603          	lw	a2,4(s4)
    80005384:	fb040593          	addi	a1,s0,-80
    80005388:	8526                	mv	a0,s1
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	cb0080e7          	jalr	-848(ra) # 8000403a <dirlink>
    80005392:	06054f63          	bltz	a0,80005410 <create+0x162>
  iunlockput(dp);
    80005396:	8526                	mv	a0,s1
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	80a080e7          	jalr	-2038(ra) # 80003ba2 <iunlockput>
  return ip;
    800053a0:	8ad2                	mv	s5,s4
    800053a2:	b749                	j	80005324 <create+0x76>
    iunlockput(dp);
    800053a4:	8526                	mv	a0,s1
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	7fc080e7          	jalr	2044(ra) # 80003ba2 <iunlockput>
    return 0;
    800053ae:	8ad2                	mv	s5,s4
    800053b0:	bf95                	j	80005324 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053b2:	004a2603          	lw	a2,4(s4)
    800053b6:	00003597          	auipc	a1,0x3
    800053ba:	38a58593          	addi	a1,a1,906 # 80008740 <syscalls+0x2b8>
    800053be:	8552                	mv	a0,s4
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	c7a080e7          	jalr	-902(ra) # 8000403a <dirlink>
    800053c8:	04054463          	bltz	a0,80005410 <create+0x162>
    800053cc:	40d0                	lw	a2,4(s1)
    800053ce:	00003597          	auipc	a1,0x3
    800053d2:	37a58593          	addi	a1,a1,890 # 80008748 <syscalls+0x2c0>
    800053d6:	8552                	mv	a0,s4
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	c62080e7          	jalr	-926(ra) # 8000403a <dirlink>
    800053e0:	02054863          	bltz	a0,80005410 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800053e4:	004a2603          	lw	a2,4(s4)
    800053e8:	fb040593          	addi	a1,s0,-80
    800053ec:	8526                	mv	a0,s1
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	c4c080e7          	jalr	-948(ra) # 8000403a <dirlink>
    800053f6:	00054d63          	bltz	a0,80005410 <create+0x162>
    dp->nlink++;  // for ".."
    800053fa:	04a4d783          	lhu	a5,74(s1)
    800053fe:	2785                	addiw	a5,a5,1
    80005400:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	46e080e7          	jalr	1134(ra) # 80003874 <iupdate>
    8000540e:	b761                	j	80005396 <create+0xe8>
  ip->nlink = 0;
    80005410:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005414:	8552                	mv	a0,s4
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	45e080e7          	jalr	1118(ra) # 80003874 <iupdate>
  iunlockput(ip);
    8000541e:	8552                	mv	a0,s4
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	782080e7          	jalr	1922(ra) # 80003ba2 <iunlockput>
  iunlockput(dp);
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	778080e7          	jalr	1912(ra) # 80003ba2 <iunlockput>
  return 0;
    80005432:	bdcd                	j	80005324 <create+0x76>
    return 0;
    80005434:	8aaa                	mv	s5,a0
    80005436:	b5fd                	j	80005324 <create+0x76>

0000000080005438 <sys_dup>:
{
    80005438:	7179                	addi	sp,sp,-48
    8000543a:	f406                	sd	ra,40(sp)
    8000543c:	f022                	sd	s0,32(sp)
    8000543e:	ec26                	sd	s1,24(sp)
    80005440:	e84a                	sd	s2,16(sp)
    80005442:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005444:	fd840613          	addi	a2,s0,-40
    80005448:	4581                	li	a1,0
    8000544a:	4501                	li	a0,0
    8000544c:	00000097          	auipc	ra,0x0
    80005450:	dc0080e7          	jalr	-576(ra) # 8000520c <argfd>
    return -1;
    80005454:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005456:	02054363          	bltz	a0,8000547c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000545a:	fd843903          	ld	s2,-40(s0)
    8000545e:	854a                	mv	a0,s2
    80005460:	00000097          	auipc	ra,0x0
    80005464:	e0c080e7          	jalr	-500(ra) # 8000526c <fdalloc>
    80005468:	84aa                	mv	s1,a0
    return -1;
    8000546a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000546c:	00054863          	bltz	a0,8000547c <sys_dup+0x44>
  filedup(f);
    80005470:	854a                	mv	a0,s2
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	310080e7          	jalr	784(ra) # 80004782 <filedup>
  return fd;
    8000547a:	87a6                	mv	a5,s1
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	70a2                	ld	ra,40(sp)
    80005480:	7402                	ld	s0,32(sp)
    80005482:	64e2                	ld	s1,24(sp)
    80005484:	6942                	ld	s2,16(sp)
    80005486:	6145                	addi	sp,sp,48
    80005488:	8082                	ret

000000008000548a <sys_read>:
{
    8000548a:	7179                	addi	sp,sp,-48
    8000548c:	f406                	sd	ra,40(sp)
    8000548e:	f022                	sd	s0,32(sp)
    80005490:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005492:	fd840593          	addi	a1,s0,-40
    80005496:	4505                	li	a0,1
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	844080e7          	jalr	-1980(ra) # 80002cdc <argaddr>
  argint(2, &n);
    800054a0:	fe440593          	addi	a1,s0,-28
    800054a4:	4509                	li	a0,2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	814080e7          	jalr	-2028(ra) # 80002cba <argint>
  if(argfd(0, 0, &f) < 0)
    800054ae:	fe840613          	addi	a2,s0,-24
    800054b2:	4581                	li	a1,0
    800054b4:	4501                	li	a0,0
    800054b6:	00000097          	auipc	ra,0x0
    800054ba:	d56080e7          	jalr	-682(ra) # 8000520c <argfd>
    800054be:	87aa                	mv	a5,a0
    return -1;
    800054c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054c2:	0007cc63          	bltz	a5,800054da <sys_read+0x50>
  return fileread(f, p, n);
    800054c6:	fe442603          	lw	a2,-28(s0)
    800054ca:	fd843583          	ld	a1,-40(s0)
    800054ce:	fe843503          	ld	a0,-24(s0)
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	43c080e7          	jalr	1084(ra) # 8000490e <fileread>
}
    800054da:	70a2                	ld	ra,40(sp)
    800054dc:	7402                	ld	s0,32(sp)
    800054de:	6145                	addi	sp,sp,48
    800054e0:	8082                	ret

00000000800054e2 <sys_write>:
{
    800054e2:	7179                	addi	sp,sp,-48
    800054e4:	f406                	sd	ra,40(sp)
    800054e6:	f022                	sd	s0,32(sp)
    800054e8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054ea:	fd840593          	addi	a1,s0,-40
    800054ee:	4505                	li	a0,1
    800054f0:	ffffd097          	auipc	ra,0xffffd
    800054f4:	7ec080e7          	jalr	2028(ra) # 80002cdc <argaddr>
  argint(2, &n);
    800054f8:	fe440593          	addi	a1,s0,-28
    800054fc:	4509                	li	a0,2
    800054fe:	ffffd097          	auipc	ra,0xffffd
    80005502:	7bc080e7          	jalr	1980(ra) # 80002cba <argint>
  if(argfd(0, 0, &f) < 0)
    80005506:	fe840613          	addi	a2,s0,-24
    8000550a:	4581                	li	a1,0
    8000550c:	4501                	li	a0,0
    8000550e:	00000097          	auipc	ra,0x0
    80005512:	cfe080e7          	jalr	-770(ra) # 8000520c <argfd>
    80005516:	87aa                	mv	a5,a0
    return -1;
    80005518:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000551a:	0007cc63          	bltz	a5,80005532 <sys_write+0x50>
  return filewrite(f, p, n);
    8000551e:	fe442603          	lw	a2,-28(s0)
    80005522:	fd843583          	ld	a1,-40(s0)
    80005526:	fe843503          	ld	a0,-24(s0)
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	4a6080e7          	jalr	1190(ra) # 800049d0 <filewrite>
}
    80005532:	70a2                	ld	ra,40(sp)
    80005534:	7402                	ld	s0,32(sp)
    80005536:	6145                	addi	sp,sp,48
    80005538:	8082                	ret

000000008000553a <sys_close>:
{
    8000553a:	1101                	addi	sp,sp,-32
    8000553c:	ec06                	sd	ra,24(sp)
    8000553e:	e822                	sd	s0,16(sp)
    80005540:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005542:	fe040613          	addi	a2,s0,-32
    80005546:	fec40593          	addi	a1,s0,-20
    8000554a:	4501                	li	a0,0
    8000554c:	00000097          	auipc	ra,0x0
    80005550:	cc0080e7          	jalr	-832(ra) # 8000520c <argfd>
    return -1;
    80005554:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005556:	02054463          	bltz	a0,8000557e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	5a2080e7          	jalr	1442(ra) # 80001afc <myproc>
    80005562:	fec42783          	lw	a5,-20(s0)
    80005566:	07e9                	addi	a5,a5,26
    80005568:	078e                	slli	a5,a5,0x3
    8000556a:	953e                	add	a0,a0,a5
    8000556c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005570:	fe043503          	ld	a0,-32(s0)
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	260080e7          	jalr	608(ra) # 800047d4 <fileclose>
  return 0;
    8000557c:	4781                	li	a5,0
}
    8000557e:	853e                	mv	a0,a5
    80005580:	60e2                	ld	ra,24(sp)
    80005582:	6442                	ld	s0,16(sp)
    80005584:	6105                	addi	sp,sp,32
    80005586:	8082                	ret

0000000080005588 <sys_fstat>:
{
    80005588:	1101                	addi	sp,sp,-32
    8000558a:	ec06                	sd	ra,24(sp)
    8000558c:	e822                	sd	s0,16(sp)
    8000558e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005590:	fe040593          	addi	a1,s0,-32
    80005594:	4505                	li	a0,1
    80005596:	ffffd097          	auipc	ra,0xffffd
    8000559a:	746080e7          	jalr	1862(ra) # 80002cdc <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000559e:	fe840613          	addi	a2,s0,-24
    800055a2:	4581                	li	a1,0
    800055a4:	4501                	li	a0,0
    800055a6:	00000097          	auipc	ra,0x0
    800055aa:	c66080e7          	jalr	-922(ra) # 8000520c <argfd>
    800055ae:	87aa                	mv	a5,a0
    return -1;
    800055b0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055b2:	0007ca63          	bltz	a5,800055c6 <sys_fstat+0x3e>
  return filestat(f, st);
    800055b6:	fe043583          	ld	a1,-32(s0)
    800055ba:	fe843503          	ld	a0,-24(s0)
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	2de080e7          	jalr	734(ra) # 8000489c <filestat>
}
    800055c6:	60e2                	ld	ra,24(sp)
    800055c8:	6442                	ld	s0,16(sp)
    800055ca:	6105                	addi	sp,sp,32
    800055cc:	8082                	ret

00000000800055ce <sys_link>:
{
    800055ce:	7169                	addi	sp,sp,-304
    800055d0:	f606                	sd	ra,296(sp)
    800055d2:	f222                	sd	s0,288(sp)
    800055d4:	ee26                	sd	s1,280(sp)
    800055d6:	ea4a                	sd	s2,272(sp)
    800055d8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055da:	08000613          	li	a2,128
    800055de:	ed040593          	addi	a1,s0,-304
    800055e2:	4501                	li	a0,0
    800055e4:	ffffd097          	auipc	ra,0xffffd
    800055e8:	71a080e7          	jalr	1818(ra) # 80002cfe <argstr>
    return -1;
    800055ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ee:	10054e63          	bltz	a0,8000570a <sys_link+0x13c>
    800055f2:	08000613          	li	a2,128
    800055f6:	f5040593          	addi	a1,s0,-176
    800055fa:	4505                	li	a0,1
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	702080e7          	jalr	1794(ra) # 80002cfe <argstr>
    return -1;
    80005604:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005606:	10054263          	bltz	a0,8000570a <sys_link+0x13c>
  begin_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	d02080e7          	jalr	-766(ra) # 8000430c <begin_op>
  if((ip = namei(old)) == 0){
    80005612:	ed040513          	addi	a0,s0,-304
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	ad6080e7          	jalr	-1322(ra) # 800040ec <namei>
    8000561e:	84aa                	mv	s1,a0
    80005620:	c551                	beqz	a0,800056ac <sys_link+0xde>
  ilock(ip);
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	31e080e7          	jalr	798(ra) # 80003940 <ilock>
  if(ip->type == T_DIR){
    8000562a:	04449703          	lh	a4,68(s1)
    8000562e:	4785                	li	a5,1
    80005630:	08f70463          	beq	a4,a5,800056b8 <sys_link+0xea>
  ip->nlink++;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	2785                	addiw	a5,a5,1
    8000563a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	234080e7          	jalr	564(ra) # 80003874 <iupdate>
  iunlock(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	3b8080e7          	jalr	952(ra) # 80003a02 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005652:	fd040593          	addi	a1,s0,-48
    80005656:	f5040513          	addi	a0,s0,-176
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	ab0080e7          	jalr	-1360(ra) # 8000410a <nameiparent>
    80005662:	892a                	mv	s2,a0
    80005664:	c935                	beqz	a0,800056d8 <sys_link+0x10a>
  ilock(dp);
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	2da080e7          	jalr	730(ra) # 80003940 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000566e:	00092703          	lw	a4,0(s2)
    80005672:	409c                	lw	a5,0(s1)
    80005674:	04f71d63          	bne	a4,a5,800056ce <sys_link+0x100>
    80005678:	40d0                	lw	a2,4(s1)
    8000567a:	fd040593          	addi	a1,s0,-48
    8000567e:	854a                	mv	a0,s2
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	9ba080e7          	jalr	-1606(ra) # 8000403a <dirlink>
    80005688:	04054363          	bltz	a0,800056ce <sys_link+0x100>
  iunlockput(dp);
    8000568c:	854a                	mv	a0,s2
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	514080e7          	jalr	1300(ra) # 80003ba2 <iunlockput>
  iput(ip);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	462080e7          	jalr	1122(ra) # 80003afa <iput>
  end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	cea080e7          	jalr	-790(ra) # 8000438a <end_op>
  return 0;
    800056a8:	4781                	li	a5,0
    800056aa:	a085                	j	8000570a <sys_link+0x13c>
    end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	cde080e7          	jalr	-802(ra) # 8000438a <end_op>
    return -1;
    800056b4:	57fd                	li	a5,-1
    800056b6:	a891                	j	8000570a <sys_link+0x13c>
    iunlockput(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	4e8080e7          	jalr	1256(ra) # 80003ba2 <iunlockput>
    end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	cc8080e7          	jalr	-824(ra) # 8000438a <end_op>
    return -1;
    800056ca:	57fd                	li	a5,-1
    800056cc:	a83d                	j	8000570a <sys_link+0x13c>
    iunlockput(dp);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	4d2080e7          	jalr	1234(ra) # 80003ba2 <iunlockput>
  ilock(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	266080e7          	jalr	614(ra) # 80003940 <ilock>
  ip->nlink--;
    800056e2:	04a4d783          	lhu	a5,74(s1)
    800056e6:	37fd                	addiw	a5,a5,-1
    800056e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	186080e7          	jalr	390(ra) # 80003874 <iupdate>
  iunlockput(ip);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	4aa080e7          	jalr	1194(ra) # 80003ba2 <iunlockput>
  end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	c8a080e7          	jalr	-886(ra) # 8000438a <end_op>
  return -1;
    80005708:	57fd                	li	a5,-1
}
    8000570a:	853e                	mv	a0,a5
    8000570c:	70b2                	ld	ra,296(sp)
    8000570e:	7412                	ld	s0,288(sp)
    80005710:	64f2                	ld	s1,280(sp)
    80005712:	6952                	ld	s2,272(sp)
    80005714:	6155                	addi	sp,sp,304
    80005716:	8082                	ret

0000000080005718 <sys_unlink>:
{
    80005718:	7151                	addi	sp,sp,-240
    8000571a:	f586                	sd	ra,232(sp)
    8000571c:	f1a2                	sd	s0,224(sp)
    8000571e:	eda6                	sd	s1,216(sp)
    80005720:	e9ca                	sd	s2,208(sp)
    80005722:	e5ce                	sd	s3,200(sp)
    80005724:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005726:	08000613          	li	a2,128
    8000572a:	f3040593          	addi	a1,s0,-208
    8000572e:	4501                	li	a0,0
    80005730:	ffffd097          	auipc	ra,0xffffd
    80005734:	5ce080e7          	jalr	1486(ra) # 80002cfe <argstr>
    80005738:	18054163          	bltz	a0,800058ba <sys_unlink+0x1a2>
  begin_op();
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	bd0080e7          	jalr	-1072(ra) # 8000430c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005744:	fb040593          	addi	a1,s0,-80
    80005748:	f3040513          	addi	a0,s0,-208
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	9be080e7          	jalr	-1602(ra) # 8000410a <nameiparent>
    80005754:	84aa                	mv	s1,a0
    80005756:	c979                	beqz	a0,8000582c <sys_unlink+0x114>
  ilock(dp);
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	1e8080e7          	jalr	488(ra) # 80003940 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005760:	00003597          	auipc	a1,0x3
    80005764:	fe058593          	addi	a1,a1,-32 # 80008740 <syscalls+0x2b8>
    80005768:	fb040513          	addi	a0,s0,-80
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	69e080e7          	jalr	1694(ra) # 80003e0a <namecmp>
    80005774:	14050a63          	beqz	a0,800058c8 <sys_unlink+0x1b0>
    80005778:	00003597          	auipc	a1,0x3
    8000577c:	fd058593          	addi	a1,a1,-48 # 80008748 <syscalls+0x2c0>
    80005780:	fb040513          	addi	a0,s0,-80
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	686080e7          	jalr	1670(ra) # 80003e0a <namecmp>
    8000578c:	12050e63          	beqz	a0,800058c8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005790:	f2c40613          	addi	a2,s0,-212
    80005794:	fb040593          	addi	a1,s0,-80
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	68a080e7          	jalr	1674(ra) # 80003e24 <dirlookup>
    800057a2:	892a                	mv	s2,a0
    800057a4:	12050263          	beqz	a0,800058c8 <sys_unlink+0x1b0>
  ilock(ip);
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	198080e7          	jalr	408(ra) # 80003940 <ilock>
  if(ip->nlink < 1)
    800057b0:	04a91783          	lh	a5,74(s2)
    800057b4:	08f05263          	blez	a5,80005838 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057b8:	04491703          	lh	a4,68(s2)
    800057bc:	4785                	li	a5,1
    800057be:	08f70563          	beq	a4,a5,80005848 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057c2:	4641                	li	a2,16
    800057c4:	4581                	li	a1,0
    800057c6:	fc040513          	addi	a0,s0,-64
    800057ca:	ffffb097          	auipc	ra,0xffffb
    800057ce:	63e080e7          	jalr	1598(ra) # 80000e08 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057d2:	4741                	li	a4,16
    800057d4:	f2c42683          	lw	a3,-212(s0)
    800057d8:	fc040613          	addi	a2,s0,-64
    800057dc:	4581                	li	a1,0
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	50c080e7          	jalr	1292(ra) # 80003cec <writei>
    800057e8:	47c1                	li	a5,16
    800057ea:	0af51563          	bne	a0,a5,80005894 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057ee:	04491703          	lh	a4,68(s2)
    800057f2:	4785                	li	a5,1
    800057f4:	0af70863          	beq	a4,a5,800058a4 <sys_unlink+0x18c>
  iunlockput(dp);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	3a8080e7          	jalr	936(ra) # 80003ba2 <iunlockput>
  ip->nlink--;
    80005802:	04a95783          	lhu	a5,74(s2)
    80005806:	37fd                	addiw	a5,a5,-1
    80005808:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	066080e7          	jalr	102(ra) # 80003874 <iupdate>
  iunlockput(ip);
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	38a080e7          	jalr	906(ra) # 80003ba2 <iunlockput>
  end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	b6a080e7          	jalr	-1174(ra) # 8000438a <end_op>
  return 0;
    80005828:	4501                	li	a0,0
    8000582a:	a84d                	j	800058dc <sys_unlink+0x1c4>
    end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	b5e080e7          	jalr	-1186(ra) # 8000438a <end_op>
    return -1;
    80005834:	557d                	li	a0,-1
    80005836:	a05d                	j	800058dc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005838:	00003517          	auipc	a0,0x3
    8000583c:	f1850513          	addi	a0,a0,-232 # 80008750 <syscalls+0x2c8>
    80005840:	ffffb097          	auipc	ra,0xffffb
    80005844:	d00080e7          	jalr	-768(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005848:	04c92703          	lw	a4,76(s2)
    8000584c:	02000793          	li	a5,32
    80005850:	f6e7f9e3          	bgeu	a5,a4,800057c2 <sys_unlink+0xaa>
    80005854:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005858:	4741                	li	a4,16
    8000585a:	86ce                	mv	a3,s3
    8000585c:	f1840613          	addi	a2,s0,-232
    80005860:	4581                	li	a1,0
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	390080e7          	jalr	912(ra) # 80003bf4 <readi>
    8000586c:	47c1                	li	a5,16
    8000586e:	00f51b63          	bne	a0,a5,80005884 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005872:	f1845783          	lhu	a5,-232(s0)
    80005876:	e7a1                	bnez	a5,800058be <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005878:	29c1                	addiw	s3,s3,16
    8000587a:	04c92783          	lw	a5,76(s2)
    8000587e:	fcf9ede3          	bltu	s3,a5,80005858 <sys_unlink+0x140>
    80005882:	b781                	j	800057c2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005884:	00003517          	auipc	a0,0x3
    80005888:	ee450513          	addi	a0,a0,-284 # 80008768 <syscalls+0x2e0>
    8000588c:	ffffb097          	auipc	ra,0xffffb
    80005890:	cb4080e7          	jalr	-844(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005894:	00003517          	auipc	a0,0x3
    80005898:	eec50513          	addi	a0,a0,-276 # 80008780 <syscalls+0x2f8>
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	ca4080e7          	jalr	-860(ra) # 80000540 <panic>
    dp->nlink--;
    800058a4:	04a4d783          	lhu	a5,74(s1)
    800058a8:	37fd                	addiw	a5,a5,-1
    800058aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	fc4080e7          	jalr	-60(ra) # 80003874 <iupdate>
    800058b8:	b781                	j	800057f8 <sys_unlink+0xe0>
    return -1;
    800058ba:	557d                	li	a0,-1
    800058bc:	a005                	j	800058dc <sys_unlink+0x1c4>
    iunlockput(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	2e2080e7          	jalr	738(ra) # 80003ba2 <iunlockput>
  iunlockput(dp);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	2d8080e7          	jalr	728(ra) # 80003ba2 <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	ab8080e7          	jalr	-1352(ra) # 8000438a <end_op>
  return -1;
    800058da:	557d                	li	a0,-1
}
    800058dc:	70ae                	ld	ra,232(sp)
    800058de:	740e                	ld	s0,224(sp)
    800058e0:	64ee                	ld	s1,216(sp)
    800058e2:	694e                	ld	s2,208(sp)
    800058e4:	69ae                	ld	s3,200(sp)
    800058e6:	616d                	addi	sp,sp,240
    800058e8:	8082                	ret

00000000800058ea <sys_open>:

uint64
sys_open(void)
{
    800058ea:	7131                	addi	sp,sp,-192
    800058ec:	fd06                	sd	ra,184(sp)
    800058ee:	f922                	sd	s0,176(sp)
    800058f0:	f526                	sd	s1,168(sp)
    800058f2:	f14a                	sd	s2,160(sp)
    800058f4:	ed4e                	sd	s3,152(sp)
    800058f6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058f8:	f4c40593          	addi	a1,s0,-180
    800058fc:	4505                	li	a0,1
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	3bc080e7          	jalr	956(ra) # 80002cba <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005906:	08000613          	li	a2,128
    8000590a:	f5040593          	addi	a1,s0,-176
    8000590e:	4501                	li	a0,0
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	3ee080e7          	jalr	1006(ra) # 80002cfe <argstr>
    80005918:	87aa                	mv	a5,a0
    return -1;
    8000591a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000591c:	0a07c963          	bltz	a5,800059ce <sys_open+0xe4>

  begin_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	9ec080e7          	jalr	-1556(ra) # 8000430c <begin_op>

  if(omode & O_CREATE){
    80005928:	f4c42783          	lw	a5,-180(s0)
    8000592c:	2007f793          	andi	a5,a5,512
    80005930:	cfc5                	beqz	a5,800059e8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005932:	4681                	li	a3,0
    80005934:	4601                	li	a2,0
    80005936:	4589                	li	a1,2
    80005938:	f5040513          	addi	a0,s0,-176
    8000593c:	00000097          	auipc	ra,0x0
    80005940:	972080e7          	jalr	-1678(ra) # 800052ae <create>
    80005944:	84aa                	mv	s1,a0
    if(ip == 0){
    80005946:	c959                	beqz	a0,800059dc <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005948:	04449703          	lh	a4,68(s1)
    8000594c:	478d                	li	a5,3
    8000594e:	00f71763          	bne	a4,a5,8000595c <sys_open+0x72>
    80005952:	0464d703          	lhu	a4,70(s1)
    80005956:	47a5                	li	a5,9
    80005958:	0ce7ed63          	bltu	a5,a4,80005a32 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	dbc080e7          	jalr	-580(ra) # 80004718 <filealloc>
    80005964:	89aa                	mv	s3,a0
    80005966:	10050363          	beqz	a0,80005a6c <sys_open+0x182>
    8000596a:	00000097          	auipc	ra,0x0
    8000596e:	902080e7          	jalr	-1790(ra) # 8000526c <fdalloc>
    80005972:	892a                	mv	s2,a0
    80005974:	0e054763          	bltz	a0,80005a62 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005978:	04449703          	lh	a4,68(s1)
    8000597c:	478d                	li	a5,3
    8000597e:	0cf70563          	beq	a4,a5,80005a48 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005982:	4789                	li	a5,2
    80005984:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005988:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000598c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005990:	f4c42783          	lw	a5,-180(s0)
    80005994:	0017c713          	xori	a4,a5,1
    80005998:	8b05                	andi	a4,a4,1
    8000599a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000599e:	0037f713          	andi	a4,a5,3
    800059a2:	00e03733          	snez	a4,a4
    800059a6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059aa:	4007f793          	andi	a5,a5,1024
    800059ae:	c791                	beqz	a5,800059ba <sys_open+0xd0>
    800059b0:	04449703          	lh	a4,68(s1)
    800059b4:	4789                	li	a5,2
    800059b6:	0af70063          	beq	a4,a5,80005a56 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059ba:	8526                	mv	a0,s1
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	046080e7          	jalr	70(ra) # 80003a02 <iunlock>
  end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	9c6080e7          	jalr	-1594(ra) # 8000438a <end_op>

  return fd;
    800059cc:	854a                	mv	a0,s2
}
    800059ce:	70ea                	ld	ra,184(sp)
    800059d0:	744a                	ld	s0,176(sp)
    800059d2:	74aa                	ld	s1,168(sp)
    800059d4:	790a                	ld	s2,160(sp)
    800059d6:	69ea                	ld	s3,152(sp)
    800059d8:	6129                	addi	sp,sp,192
    800059da:	8082                	ret
      end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	9ae080e7          	jalr	-1618(ra) # 8000438a <end_op>
      return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7e5                	j	800059ce <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059e8:	f5040513          	addi	a0,s0,-176
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	700080e7          	jalr	1792(ra) # 800040ec <namei>
    800059f4:	84aa                	mv	s1,a0
    800059f6:	c905                	beqz	a0,80005a26 <sys_open+0x13c>
    ilock(ip);
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	f48080e7          	jalr	-184(ra) # 80003940 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a00:	04449703          	lh	a4,68(s1)
    80005a04:	4785                	li	a5,1
    80005a06:	f4f711e3          	bne	a4,a5,80005948 <sys_open+0x5e>
    80005a0a:	f4c42783          	lw	a5,-180(s0)
    80005a0e:	d7b9                	beqz	a5,8000595c <sys_open+0x72>
      iunlockput(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	190080e7          	jalr	400(ra) # 80003ba2 <iunlockput>
      end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	970080e7          	jalr	-1680(ra) # 8000438a <end_op>
      return -1;
    80005a22:	557d                	li	a0,-1
    80005a24:	b76d                	j	800059ce <sys_open+0xe4>
      end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	964080e7          	jalr	-1692(ra) # 8000438a <end_op>
      return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	bf79                	j	800059ce <sys_open+0xe4>
    iunlockput(ip);
    80005a32:	8526                	mv	a0,s1
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	16e080e7          	jalr	366(ra) # 80003ba2 <iunlockput>
    end_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	94e080e7          	jalr	-1714(ra) # 8000438a <end_op>
    return -1;
    80005a44:	557d                	li	a0,-1
    80005a46:	b761                	j	800059ce <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a48:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a4c:	04649783          	lh	a5,70(s1)
    80005a50:	02f99223          	sh	a5,36(s3)
    80005a54:	bf25                	j	8000598c <sys_open+0xa2>
    itrunc(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	ff6080e7          	jalr	-10(ra) # 80003a4e <itrunc>
    80005a60:	bfa9                	j	800059ba <sys_open+0xd0>
      fileclose(f);
    80005a62:	854e                	mv	a0,s3
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	d70080e7          	jalr	-656(ra) # 800047d4 <fileclose>
    iunlockput(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	134080e7          	jalr	308(ra) # 80003ba2 <iunlockput>
    end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	914080e7          	jalr	-1772(ra) # 8000438a <end_op>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	b7b9                	j	800059ce <sys_open+0xe4>

0000000080005a82 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a82:	7175                	addi	sp,sp,-144
    80005a84:	e506                	sd	ra,136(sp)
    80005a86:	e122                	sd	s0,128(sp)
    80005a88:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	882080e7          	jalr	-1918(ra) # 8000430c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a92:	08000613          	li	a2,128
    80005a96:	f7040593          	addi	a1,s0,-144
    80005a9a:	4501                	li	a0,0
    80005a9c:	ffffd097          	auipc	ra,0xffffd
    80005aa0:	262080e7          	jalr	610(ra) # 80002cfe <argstr>
    80005aa4:	02054963          	bltz	a0,80005ad6 <sys_mkdir+0x54>
    80005aa8:	4681                	li	a3,0
    80005aaa:	4601                	li	a2,0
    80005aac:	4585                	li	a1,1
    80005aae:	f7040513          	addi	a0,s0,-144
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	7fc080e7          	jalr	2044(ra) # 800052ae <create>
    80005aba:	cd11                	beqz	a0,80005ad6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	0e6080e7          	jalr	230(ra) # 80003ba2 <iunlockput>
  end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	8c6080e7          	jalr	-1850(ra) # 8000438a <end_op>
  return 0;
    80005acc:	4501                	li	a0,0
}
    80005ace:	60aa                	ld	ra,136(sp)
    80005ad0:	640a                	ld	s0,128(sp)
    80005ad2:	6149                	addi	sp,sp,144
    80005ad4:	8082                	ret
    end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	8b4080e7          	jalr	-1868(ra) # 8000438a <end_op>
    return -1;
    80005ade:	557d                	li	a0,-1
    80005ae0:	b7fd                	j	80005ace <sys_mkdir+0x4c>

0000000080005ae2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ae2:	7135                	addi	sp,sp,-160
    80005ae4:	ed06                	sd	ra,152(sp)
    80005ae6:	e922                	sd	s0,144(sp)
    80005ae8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	822080e7          	jalr	-2014(ra) # 8000430c <begin_op>
  argint(1, &major);
    80005af2:	f6c40593          	addi	a1,s0,-148
    80005af6:	4505                	li	a0,1
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	1c2080e7          	jalr	450(ra) # 80002cba <argint>
  argint(2, &minor);
    80005b00:	f6840593          	addi	a1,s0,-152
    80005b04:	4509                	li	a0,2
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	1b4080e7          	jalr	436(ra) # 80002cba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b0e:	08000613          	li	a2,128
    80005b12:	f7040593          	addi	a1,s0,-144
    80005b16:	4501                	li	a0,0
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	1e6080e7          	jalr	486(ra) # 80002cfe <argstr>
    80005b20:	02054b63          	bltz	a0,80005b56 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b24:	f6841683          	lh	a3,-152(s0)
    80005b28:	f6c41603          	lh	a2,-148(s0)
    80005b2c:	458d                	li	a1,3
    80005b2e:	f7040513          	addi	a0,s0,-144
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	77c080e7          	jalr	1916(ra) # 800052ae <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b3a:	cd11                	beqz	a0,80005b56 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	066080e7          	jalr	102(ra) # 80003ba2 <iunlockput>
  end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	846080e7          	jalr	-1978(ra) # 8000438a <end_op>
  return 0;
    80005b4c:	4501                	li	a0,0
}
    80005b4e:	60ea                	ld	ra,152(sp)
    80005b50:	644a                	ld	s0,144(sp)
    80005b52:	610d                	addi	sp,sp,160
    80005b54:	8082                	ret
    end_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	834080e7          	jalr	-1996(ra) # 8000438a <end_op>
    return -1;
    80005b5e:	557d                	li	a0,-1
    80005b60:	b7fd                	j	80005b4e <sys_mknod+0x6c>

0000000080005b62 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b62:	7135                	addi	sp,sp,-160
    80005b64:	ed06                	sd	ra,152(sp)
    80005b66:	e922                	sd	s0,144(sp)
    80005b68:	e526                	sd	s1,136(sp)
    80005b6a:	e14a                	sd	s2,128(sp)
    80005b6c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b6e:	ffffc097          	auipc	ra,0xffffc
    80005b72:	f8e080e7          	jalr	-114(ra) # 80001afc <myproc>
    80005b76:	892a                	mv	s2,a0
  
  begin_op();
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	794080e7          	jalr	1940(ra) # 8000430c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b80:	08000613          	li	a2,128
    80005b84:	f6040593          	addi	a1,s0,-160
    80005b88:	4501                	li	a0,0
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	174080e7          	jalr	372(ra) # 80002cfe <argstr>
    80005b92:	04054b63          	bltz	a0,80005be8 <sys_chdir+0x86>
    80005b96:	f6040513          	addi	a0,s0,-160
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	552080e7          	jalr	1362(ra) # 800040ec <namei>
    80005ba2:	84aa                	mv	s1,a0
    80005ba4:	c131                	beqz	a0,80005be8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	d9a080e7          	jalr	-614(ra) # 80003940 <ilock>
  if(ip->type != T_DIR){
    80005bae:	04449703          	lh	a4,68(s1)
    80005bb2:	4785                	li	a5,1
    80005bb4:	04f71063          	bne	a4,a5,80005bf4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bb8:	8526                	mv	a0,s1
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	e48080e7          	jalr	-440(ra) # 80003a02 <iunlock>
  iput(p->cwd);
    80005bc2:	15093503          	ld	a0,336(s2)
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	f34080e7          	jalr	-204(ra) # 80003afa <iput>
  end_op();
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	7bc080e7          	jalr	1980(ra) # 8000438a <end_op>
  p->cwd = ip;
    80005bd6:	14993823          	sd	s1,336(s2)
  return 0;
    80005bda:	4501                	li	a0,0
}
    80005bdc:	60ea                	ld	ra,152(sp)
    80005bde:	644a                	ld	s0,144(sp)
    80005be0:	64aa                	ld	s1,136(sp)
    80005be2:	690a                	ld	s2,128(sp)
    80005be4:	610d                	addi	sp,sp,160
    80005be6:	8082                	ret
    end_op();
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	7a2080e7          	jalr	1954(ra) # 8000438a <end_op>
    return -1;
    80005bf0:	557d                	li	a0,-1
    80005bf2:	b7ed                	j	80005bdc <sys_chdir+0x7a>
    iunlockput(ip);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	fac080e7          	jalr	-84(ra) # 80003ba2 <iunlockput>
    end_op();
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	78c080e7          	jalr	1932(ra) # 8000438a <end_op>
    return -1;
    80005c06:	557d                	li	a0,-1
    80005c08:	bfd1                	j	80005bdc <sys_chdir+0x7a>

0000000080005c0a <sys_exec>:

uint64
sys_exec(void)
{
    80005c0a:	7145                	addi	sp,sp,-464
    80005c0c:	e786                	sd	ra,456(sp)
    80005c0e:	e3a2                	sd	s0,448(sp)
    80005c10:	ff26                	sd	s1,440(sp)
    80005c12:	fb4a                	sd	s2,432(sp)
    80005c14:	f74e                	sd	s3,424(sp)
    80005c16:	f352                	sd	s4,416(sp)
    80005c18:	ef56                	sd	s5,408(sp)
    80005c1a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c1c:	e3840593          	addi	a1,s0,-456
    80005c20:	4505                	li	a0,1
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	0ba080e7          	jalr	186(ra) # 80002cdc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c2a:	08000613          	li	a2,128
    80005c2e:	f4040593          	addi	a1,s0,-192
    80005c32:	4501                	li	a0,0
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	0ca080e7          	jalr	202(ra) # 80002cfe <argstr>
    80005c3c:	87aa                	mv	a5,a0
    return -1;
    80005c3e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c40:	0c07c363          	bltz	a5,80005d06 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c44:	10000613          	li	a2,256
    80005c48:	4581                	li	a1,0
    80005c4a:	e4040513          	addi	a0,s0,-448
    80005c4e:	ffffb097          	auipc	ra,0xffffb
    80005c52:	1ba080e7          	jalr	442(ra) # 80000e08 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c56:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c5a:	89a6                	mv	s3,s1
    80005c5c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c5e:	02000a13          	li	s4,32
    80005c62:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c66:	00391513          	slli	a0,s2,0x3
    80005c6a:	e3040593          	addi	a1,s0,-464
    80005c6e:	e3843783          	ld	a5,-456(s0)
    80005c72:	953e                	add	a0,a0,a5
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	fa8080e7          	jalr	-88(ra) # 80002c1c <fetchaddr>
    80005c7c:	02054a63          	bltz	a0,80005cb0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c80:	e3043783          	ld	a5,-464(s0)
    80005c84:	c3b9                	beqz	a5,80005cca <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c86:	ffffb097          	auipc	ra,0xffffb
    80005c8a:	f5e080e7          	jalr	-162(ra) # 80000be4 <kalloc>
    80005c8e:	85aa                	mv	a1,a0
    80005c90:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c94:	cd11                	beqz	a0,80005cb0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c96:	6605                	lui	a2,0x1
    80005c98:	e3043503          	ld	a0,-464(s0)
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	fd2080e7          	jalr	-46(ra) # 80002c6e <fetchstr>
    80005ca4:	00054663          	bltz	a0,80005cb0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ca8:	0905                	addi	s2,s2,1
    80005caa:	09a1                	addi	s3,s3,8
    80005cac:	fb491be3          	bne	s2,s4,80005c62 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb0:	f4040913          	addi	s2,s0,-192
    80005cb4:	6088                	ld	a0,0(s1)
    80005cb6:	c539                	beqz	a0,80005d04 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cb8:	ffffb097          	auipc	ra,0xffffb
    80005cbc:	da8080e7          	jalr	-600(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc0:	04a1                	addi	s1,s1,8
    80005cc2:	ff2499e3          	bne	s1,s2,80005cb4 <sys_exec+0xaa>
  return -1;
    80005cc6:	557d                	li	a0,-1
    80005cc8:	a83d                	j	80005d06 <sys_exec+0xfc>
      argv[i] = 0;
    80005cca:	0a8e                	slli	s5,s5,0x3
    80005ccc:	fc0a8793          	addi	a5,s5,-64
    80005cd0:	00878ab3          	add	s5,a5,s0
    80005cd4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cd8:	e4040593          	addi	a1,s0,-448
    80005cdc:	f4040513          	addi	a0,s0,-192
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	16e080e7          	jalr	366(ra) # 80004e4e <exec>
    80005ce8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cea:	f4040993          	addi	s3,s0,-192
    80005cee:	6088                	ld	a0,0(s1)
    80005cf0:	c901                	beqz	a0,80005d00 <sys_exec+0xf6>
    kfree(argv[i]);
    80005cf2:	ffffb097          	auipc	ra,0xffffb
    80005cf6:	d6e080e7          	jalr	-658(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfa:	04a1                	addi	s1,s1,8
    80005cfc:	ff3499e3          	bne	s1,s3,80005cee <sys_exec+0xe4>
  return ret;
    80005d00:	854a                	mv	a0,s2
    80005d02:	a011                	j	80005d06 <sys_exec+0xfc>
  return -1;
    80005d04:	557d                	li	a0,-1
}
    80005d06:	60be                	ld	ra,456(sp)
    80005d08:	641e                	ld	s0,448(sp)
    80005d0a:	74fa                	ld	s1,440(sp)
    80005d0c:	795a                	ld	s2,432(sp)
    80005d0e:	79ba                	ld	s3,424(sp)
    80005d10:	7a1a                	ld	s4,416(sp)
    80005d12:	6afa                	ld	s5,408(sp)
    80005d14:	6179                	addi	sp,sp,464
    80005d16:	8082                	ret

0000000080005d18 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d18:	7139                	addi	sp,sp,-64
    80005d1a:	fc06                	sd	ra,56(sp)
    80005d1c:	f822                	sd	s0,48(sp)
    80005d1e:	f426                	sd	s1,40(sp)
    80005d20:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d22:	ffffc097          	auipc	ra,0xffffc
    80005d26:	dda080e7          	jalr	-550(ra) # 80001afc <myproc>
    80005d2a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d2c:	fd840593          	addi	a1,s0,-40
    80005d30:	4501                	li	a0,0
    80005d32:	ffffd097          	auipc	ra,0xffffd
    80005d36:	faa080e7          	jalr	-86(ra) # 80002cdc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d3a:	fc840593          	addi	a1,s0,-56
    80005d3e:	fd040513          	addi	a0,s0,-48
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	dc2080e7          	jalr	-574(ra) # 80004b04 <pipealloc>
    return -1;
    80005d4a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d4c:	0c054463          	bltz	a0,80005e14 <sys_pipe+0xfc>
  fd0 = -1;
    80005d50:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d54:	fd043503          	ld	a0,-48(s0)
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	514080e7          	jalr	1300(ra) # 8000526c <fdalloc>
    80005d60:	fca42223          	sw	a0,-60(s0)
    80005d64:	08054b63          	bltz	a0,80005dfa <sys_pipe+0xe2>
    80005d68:	fc843503          	ld	a0,-56(s0)
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	500080e7          	jalr	1280(ra) # 8000526c <fdalloc>
    80005d74:	fca42023          	sw	a0,-64(s0)
    80005d78:	06054863          	bltz	a0,80005de8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d7c:	4691                	li	a3,4
    80005d7e:	fc440613          	addi	a2,s0,-60
    80005d82:	fd843583          	ld	a1,-40(s0)
    80005d86:	68a8                	ld	a0,80(s1)
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	a00080e7          	jalr	-1536(ra) # 80001788 <copyout>
    80005d90:	02054063          	bltz	a0,80005db0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d94:	4691                	li	a3,4
    80005d96:	fc040613          	addi	a2,s0,-64
    80005d9a:	fd843583          	ld	a1,-40(s0)
    80005d9e:	0591                	addi	a1,a1,4
    80005da0:	68a8                	ld	a0,80(s1)
    80005da2:	ffffc097          	auipc	ra,0xffffc
    80005da6:	9e6080e7          	jalr	-1562(ra) # 80001788 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005daa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dac:	06055463          	bgez	a0,80005e14 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005db0:	fc442783          	lw	a5,-60(s0)
    80005db4:	07e9                	addi	a5,a5,26
    80005db6:	078e                	slli	a5,a5,0x3
    80005db8:	97a6                	add	a5,a5,s1
    80005dba:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dbe:	fc042783          	lw	a5,-64(s0)
    80005dc2:	07e9                	addi	a5,a5,26
    80005dc4:	078e                	slli	a5,a5,0x3
    80005dc6:	94be                	add	s1,s1,a5
    80005dc8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dcc:	fd043503          	ld	a0,-48(s0)
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	a04080e7          	jalr	-1532(ra) # 800047d4 <fileclose>
    fileclose(wf);
    80005dd8:	fc843503          	ld	a0,-56(s0)
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	9f8080e7          	jalr	-1544(ra) # 800047d4 <fileclose>
    return -1;
    80005de4:	57fd                	li	a5,-1
    80005de6:	a03d                	j	80005e14 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005de8:	fc442783          	lw	a5,-60(s0)
    80005dec:	0007c763          	bltz	a5,80005dfa <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005df0:	07e9                	addi	a5,a5,26
    80005df2:	078e                	slli	a5,a5,0x3
    80005df4:	97a6                	add	a5,a5,s1
    80005df6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005dfa:	fd043503          	ld	a0,-48(s0)
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	9d6080e7          	jalr	-1578(ra) # 800047d4 <fileclose>
    fileclose(wf);
    80005e06:	fc843503          	ld	a0,-56(s0)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	9ca080e7          	jalr	-1590(ra) # 800047d4 <fileclose>
    return -1;
    80005e12:	57fd                	li	a5,-1
}
    80005e14:	853e                	mv	a0,a5
    80005e16:	70e2                	ld	ra,56(sp)
    80005e18:	7442                	ld	s0,48(sp)
    80005e1a:	74a2                	ld	s1,40(sp)
    80005e1c:	6121                	addi	sp,sp,64
    80005e1e:	8082                	ret

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	c89fc0ef          	jal	ra,80002ae8 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	6d0c                	ld	a1,24(a0)
    80005ebc:	7110                	ld	a2,32(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	bd8080e7          	jalr	-1064(ra) # 80001ad0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	97aa                	add	a5,a5,a0
    80005f1c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	ba0080e7          	jalr	-1120(ra) # 80001ad0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5151b          	slliw	a0,a0,0xd
    80005f3c:	0c2017b7          	lui	a5,0xc201
    80005f40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f42:	43c8                	lw	a0,4(a5)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	b78080e7          	jalr	-1160(ra) # 80001ad0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f84:	0023d797          	auipc	a5,0x23d
    80005f88:	4ec78793          	addi	a5,a5,1260 # 80243470 <disk>
    80005f8c:	97aa                	add	a5,a5,a0
    80005f8e:	0187c783          	lbu	a5,24(a5)
    80005f92:	ebb9                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f94:	00451693          	slli	a3,a0,0x4
    80005f98:	0023d797          	auipc	a5,0x23d
    80005f9c:	4d878793          	addi	a5,a5,1240 # 80243470 <disk>
    80005fa0:	6398                	ld	a4,0(a5)
    80005fa2:	9736                	add	a4,a4,a3
    80005fa4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005fa8:	6398                	ld	a4,0(a5)
    80005faa:	9736                	add	a4,a4,a3
    80005fac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fb0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fb4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	4705                	li	a4,1
    80005fbc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005fc0:	0023d517          	auipc	a0,0x23d
    80005fc4:	4c850513          	addi	a0,a0,1224 # 80243488 <disk+0x18>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	240080e7          	jalr	576(ra) # 80002208 <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("free_desc 1");
    80005fd8:	00002517          	auipc	a0,0x2
    80005fdc:	7b850513          	addi	a0,a0,1976 # 80008790 <syscalls+0x308>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005fe8:	00002517          	auipc	a0,0x2
    80005fec:	7b850513          	addi	a0,a0,1976 # 800087a0 <syscalls+0x318>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	e04a                	sd	s2,0(sp)
    80006002:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006004:	00002597          	auipc	a1,0x2
    80006008:	7ac58593          	addi	a1,a1,1964 # 800087b0 <syscalls+0x328>
    8000600c:	0023d517          	auipc	a0,0x23d
    80006010:	58c50513          	addi	a0,a0,1420 # 80243598 <disk+0x128>
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	c68080e7          	jalr	-920(ra) # 80000c7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601c:	100017b7          	lui	a5,0x10001
    80006020:	4398                	lw	a4,0(a5)
    80006022:	2701                	sext.w	a4,a4
    80006024:	747277b7          	lui	a5,0x74727
    80006028:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602c:	14f71b63          	bne	a4,a5,80006182 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006030:	100017b7          	lui	a5,0x10001
    80006034:	43dc                	lw	a5,4(a5)
    80006036:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006038:	4709                	li	a4,2
    8000603a:	14e79463          	bne	a5,a4,80006182 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	479c                	lw	a5,8(a5)
    80006044:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006046:	12e79e63          	bne	a5,a4,80006182 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	12f71463          	bne	a4,a5,80006182 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	4705                	li	a4,1
    80006068:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606a:	470d                	li	a4,3
    8000606c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006070:	c7ffe6b7          	lui	a3,0xc7ffe
    80006074:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb1af>
    80006078:	8f75                	and	a4,a4,a3
    8000607a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607c:	472d                	li	a4,11
    8000607e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006080:	5bbc                	lw	a5,112(a5)
    80006082:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006086:	8ba1                	andi	a5,a5,8
    80006088:	10078563          	beqz	a5,80006192 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006094:	43fc                	lw	a5,68(a5)
    80006096:	2781                	sext.w	a5,a5
    80006098:	10079563          	bnez	a5,800061a2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	5bdc                	lw	a5,52(a5)
    800060a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060a4:	10078763          	beqz	a5,800061b2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800060a8:	471d                	li	a4,7
    800060aa:	10f77c63          	bgeu	a4,a5,800061c2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	b36080e7          	jalr	-1226(ra) # 80000be4 <kalloc>
    800060b6:	0023d497          	auipc	s1,0x23d
    800060ba:	3ba48493          	addi	s1,s1,954 # 80243470 <disk>
    800060be:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	b24080e7          	jalr	-1244(ra) # 80000be4 <kalloc>
    800060c8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ca:	ffffb097          	auipc	ra,0xffffb
    800060ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <kalloc>
    800060d2:	87aa                	mv	a5,a0
    800060d4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060d6:	6088                	ld	a0,0(s1)
    800060d8:	cd6d                	beqz	a0,800061d2 <virtio_disk_init+0x1da>
    800060da:	0023d717          	auipc	a4,0x23d
    800060de:	39e73703          	ld	a4,926(a4) # 80243478 <disk+0x8>
    800060e2:	cb65                	beqz	a4,800061d2 <virtio_disk_init+0x1da>
    800060e4:	c7fd                	beqz	a5,800061d2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800060e6:	6605                	lui	a2,0x1
    800060e8:	4581                	li	a1,0
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	d1e080e7          	jalr	-738(ra) # 80000e08 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060f2:	0023d497          	auipc	s1,0x23d
    800060f6:	37e48493          	addi	s1,s1,894 # 80243470 <disk>
    800060fa:	6605                	lui	a2,0x1
    800060fc:	4581                	li	a1,0
    800060fe:	6488                	ld	a0,8(s1)
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	d08080e7          	jalr	-760(ra) # 80000e08 <memset>
  memset(disk.used, 0, PGSIZE);
    80006108:	6605                	lui	a2,0x1
    8000610a:	4581                	li	a1,0
    8000610c:	6888                	ld	a0,16(s1)
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	cfa080e7          	jalr	-774(ra) # 80000e08 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006116:	100017b7          	lui	a5,0x10001
    8000611a:	4721                	li	a4,8
    8000611c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000611e:	4098                	lw	a4,0(s1)
    80006120:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006124:	40d8                	lw	a4,4(s1)
    80006126:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000612a:	6498                	ld	a4,8(s1)
    8000612c:	0007069b          	sext.w	a3,a4
    80006130:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006134:	9701                	srai	a4,a4,0x20
    80006136:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000613a:	6898                	ld	a4,16(s1)
    8000613c:	0007069b          	sext.w	a3,a4
    80006140:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006144:	9701                	srai	a4,a4,0x20
    80006146:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000614a:	4705                	li	a4,1
    8000614c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000614e:	00e48c23          	sb	a4,24(s1)
    80006152:	00e48ca3          	sb	a4,25(s1)
    80006156:	00e48d23          	sb	a4,26(s1)
    8000615a:	00e48da3          	sb	a4,27(s1)
    8000615e:	00e48e23          	sb	a4,28(s1)
    80006162:	00e48ea3          	sb	a4,29(s1)
    80006166:	00e48f23          	sb	a4,30(s1)
    8000616a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000616e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006172:	0727a823          	sw	s2,112(a5)
}
    80006176:	60e2                	ld	ra,24(sp)
    80006178:	6442                	ld	s0,16(sp)
    8000617a:	64a2                	ld	s1,8(sp)
    8000617c:	6902                	ld	s2,0(sp)
    8000617e:	6105                	addi	sp,sp,32
    80006180:	8082                	ret
    panic("could not find virtio disk");
    80006182:	00002517          	auipc	a0,0x2
    80006186:	63e50513          	addi	a0,a0,1598 # 800087c0 <syscalls+0x338>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3b6080e7          	jalr	950(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	64e50513          	addi	a0,a0,1614 # 800087e0 <syscalls+0x358>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a6080e7          	jalr	934(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	65e50513          	addi	a0,a0,1630 # 80008800 <syscalls+0x378>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	396080e7          	jalr	918(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	66e50513          	addi	a0,a0,1646 # 80008820 <syscalls+0x398>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	386080e7          	jalr	902(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800061c2:	00002517          	auipc	a0,0x2
    800061c6:	67e50513          	addi	a0,a0,1662 # 80008840 <syscalls+0x3b8>
    800061ca:	ffffa097          	auipc	ra,0xffffa
    800061ce:	376080e7          	jalr	886(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800061d2:	00002517          	auipc	a0,0x2
    800061d6:	68e50513          	addi	a0,a0,1678 # 80008860 <syscalls+0x3d8>
    800061da:	ffffa097          	auipc	ra,0xffffa
    800061de:	366080e7          	jalr	870(ra) # 80000540 <panic>

00000000800061e2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061e2:	7119                	addi	sp,sp,-128
    800061e4:	fc86                	sd	ra,120(sp)
    800061e6:	f8a2                	sd	s0,112(sp)
    800061e8:	f4a6                	sd	s1,104(sp)
    800061ea:	f0ca                	sd	s2,96(sp)
    800061ec:	ecce                	sd	s3,88(sp)
    800061ee:	e8d2                	sd	s4,80(sp)
    800061f0:	e4d6                	sd	s5,72(sp)
    800061f2:	e0da                	sd	s6,64(sp)
    800061f4:	fc5e                	sd	s7,56(sp)
    800061f6:	f862                	sd	s8,48(sp)
    800061f8:	f466                	sd	s9,40(sp)
    800061fa:	f06a                	sd	s10,32(sp)
    800061fc:	ec6e                	sd	s11,24(sp)
    800061fe:	0100                	addi	s0,sp,128
    80006200:	8aaa                	mv	s5,a0
    80006202:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006204:	00c52d03          	lw	s10,12(a0)
    80006208:	001d1d1b          	slliw	s10,s10,0x1
    8000620c:	1d02                	slli	s10,s10,0x20
    8000620e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006212:	0023d517          	auipc	a0,0x23d
    80006216:	38650513          	addi	a0,a0,902 # 80243598 <disk+0x128>
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	af2080e7          	jalr	-1294(ra) # 80000d0c <acquire>
  for(int i = 0; i < 3; i++){
    80006222:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006224:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006226:	0023db97          	auipc	s7,0x23d
    8000622a:	24ab8b93          	addi	s7,s7,586 # 80243470 <disk>
  for(int i = 0; i < 3; i++){
    8000622e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006230:	0023dc97          	auipc	s9,0x23d
    80006234:	368c8c93          	addi	s9,s9,872 # 80243598 <disk+0x128>
    80006238:	a08d                	j	8000629a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000623a:	00fb8733          	add	a4,s7,a5
    8000623e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006242:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006244:	0207c563          	bltz	a5,8000626e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006248:	2905                	addiw	s2,s2,1
    8000624a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000624c:	05690c63          	beq	s2,s6,800062a4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006250:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006252:	0023d717          	auipc	a4,0x23d
    80006256:	21e70713          	addi	a4,a4,542 # 80243470 <disk>
    8000625a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000625c:	01874683          	lbu	a3,24(a4)
    80006260:	fee9                	bnez	a3,8000623a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006262:	2785                	addiw	a5,a5,1
    80006264:	0705                	addi	a4,a4,1
    80006266:	fe979be3          	bne	a5,s1,8000625c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000626a:	57fd                	li	a5,-1
    8000626c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000626e:	01205d63          	blez	s2,80006288 <virtio_disk_rw+0xa6>
    80006272:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006274:	000a2503          	lw	a0,0(s4)
    80006278:	00000097          	auipc	ra,0x0
    8000627c:	cfe080e7          	jalr	-770(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006280:	2d85                	addiw	s11,s11,1
    80006282:	0a11                	addi	s4,s4,4
    80006284:	ff2d98e3          	bne	s11,s2,80006274 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006288:	85e6                	mv	a1,s9
    8000628a:	0023d517          	auipc	a0,0x23d
    8000628e:	1fe50513          	addi	a0,a0,510 # 80243488 <disk+0x18>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	f12080e7          	jalr	-238(ra) # 800021a4 <sleep>
  for(int i = 0; i < 3; i++){
    8000629a:	f8040a13          	addi	s4,s0,-128
{
    8000629e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062a0:	894e                	mv	s2,s3
    800062a2:	b77d                	j	80006250 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062a4:	f8042503          	lw	a0,-128(s0)
    800062a8:	00a50713          	addi	a4,a0,10
    800062ac:	0712                	slli	a4,a4,0x4

  if(write)
    800062ae:	0023d797          	auipc	a5,0x23d
    800062b2:	1c278793          	addi	a5,a5,450 # 80243470 <disk>
    800062b6:	00e786b3          	add	a3,a5,a4
    800062ba:	01803633          	snez	a2,s8
    800062be:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062c0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800062c4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c8:	f6070613          	addi	a2,a4,-160
    800062cc:	6394                	ld	a3,0(a5)
    800062ce:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062d0:	00870593          	addi	a1,a4,8
    800062d4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062d6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062d8:	0007b803          	ld	a6,0(a5)
    800062dc:	9642                	add	a2,a2,a6
    800062de:	46c1                	li	a3,16
    800062e0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062e2:	4585                	li	a1,1
    800062e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062e8:	f8442683          	lw	a3,-124(s0)
    800062ec:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062f0:	0692                	slli	a3,a3,0x4
    800062f2:	9836                	add	a6,a6,a3
    800062f4:	058a8613          	addi	a2,s5,88
    800062f8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062fc:	0007b803          	ld	a6,0(a5)
    80006300:	96c2                	add	a3,a3,a6
    80006302:	40000613          	li	a2,1024
    80006306:	c690                	sw	a2,8(a3)
  if(write)
    80006308:	001c3613          	seqz	a2,s8
    8000630c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006310:	00166613          	ori	a2,a2,1
    80006314:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006318:	f8842603          	lw	a2,-120(s0)
    8000631c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006320:	00250693          	addi	a3,a0,2
    80006324:	0692                	slli	a3,a3,0x4
    80006326:	96be                	add	a3,a3,a5
    80006328:	58fd                	li	a7,-1
    8000632a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000632e:	0612                	slli	a2,a2,0x4
    80006330:	9832                	add	a6,a6,a2
    80006332:	f9070713          	addi	a4,a4,-112
    80006336:	973e                	add	a4,a4,a5
    80006338:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000633c:	6398                	ld	a4,0(a5)
    8000633e:	9732                	add	a4,a4,a2
    80006340:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006342:	4609                	li	a2,2
    80006344:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006348:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000634c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006350:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006354:	6794                	ld	a3,8(a5)
    80006356:	0026d703          	lhu	a4,2(a3)
    8000635a:	8b1d                	andi	a4,a4,7
    8000635c:	0706                	slli	a4,a4,0x1
    8000635e:	96ba                	add	a3,a3,a4
    80006360:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006364:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006368:	6798                	ld	a4,8(a5)
    8000636a:	00275783          	lhu	a5,2(a4)
    8000636e:	2785                	addiw	a5,a5,1
    80006370:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006374:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006380:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006384:	0023d917          	auipc	s2,0x23d
    80006388:	21490913          	addi	s2,s2,532 # 80243598 <disk+0x128>
  while(b->disk == 1) {
    8000638c:	4485                	li	s1,1
    8000638e:	00b79c63          	bne	a5,a1,800063a6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006392:	85ca                	mv	a1,s2
    80006394:	8556                	mv	a0,s5
    80006396:	ffffc097          	auipc	ra,0xffffc
    8000639a:	e0e080e7          	jalr	-498(ra) # 800021a4 <sleep>
  while(b->disk == 1) {
    8000639e:	004aa783          	lw	a5,4(s5)
    800063a2:	fe9788e3          	beq	a5,s1,80006392 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063a6:	f8042903          	lw	s2,-128(s0)
    800063aa:	00290713          	addi	a4,s2,2
    800063ae:	0712                	slli	a4,a4,0x4
    800063b0:	0023d797          	auipc	a5,0x23d
    800063b4:	0c078793          	addi	a5,a5,192 # 80243470 <disk>
    800063b8:	97ba                	add	a5,a5,a4
    800063ba:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063be:	0023d997          	auipc	s3,0x23d
    800063c2:	0b298993          	addi	s3,s3,178 # 80243470 <disk>
    800063c6:	00491713          	slli	a4,s2,0x4
    800063ca:	0009b783          	ld	a5,0(s3)
    800063ce:	97ba                	add	a5,a5,a4
    800063d0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063d4:	854a                	mv	a0,s2
    800063d6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063da:	00000097          	auipc	ra,0x0
    800063de:	b9c080e7          	jalr	-1124(ra) # 80005f76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063e2:	8885                	andi	s1,s1,1
    800063e4:	f0ed                	bnez	s1,800063c6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063e6:	0023d517          	auipc	a0,0x23d
    800063ea:	1b250513          	addi	a0,a0,434 # 80243598 <disk+0x128>
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	9d2080e7          	jalr	-1582(ra) # 80000dc0 <release>
}
    800063f6:	70e6                	ld	ra,120(sp)
    800063f8:	7446                	ld	s0,112(sp)
    800063fa:	74a6                	ld	s1,104(sp)
    800063fc:	7906                	ld	s2,96(sp)
    800063fe:	69e6                	ld	s3,88(sp)
    80006400:	6a46                	ld	s4,80(sp)
    80006402:	6aa6                	ld	s5,72(sp)
    80006404:	6b06                	ld	s6,64(sp)
    80006406:	7be2                	ld	s7,56(sp)
    80006408:	7c42                	ld	s8,48(sp)
    8000640a:	7ca2                	ld	s9,40(sp)
    8000640c:	7d02                	ld	s10,32(sp)
    8000640e:	6de2                	ld	s11,24(sp)
    80006410:	6109                	addi	sp,sp,128
    80006412:	8082                	ret

0000000080006414 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006414:	1101                	addi	sp,sp,-32
    80006416:	ec06                	sd	ra,24(sp)
    80006418:	e822                	sd	s0,16(sp)
    8000641a:	e426                	sd	s1,8(sp)
    8000641c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000641e:	0023d497          	auipc	s1,0x23d
    80006422:	05248493          	addi	s1,s1,82 # 80243470 <disk>
    80006426:	0023d517          	auipc	a0,0x23d
    8000642a:	17250513          	addi	a0,a0,370 # 80243598 <disk+0x128>
    8000642e:	ffffb097          	auipc	ra,0xffffb
    80006432:	8de080e7          	jalr	-1826(ra) # 80000d0c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006436:	10001737          	lui	a4,0x10001
    8000643a:	533c                	lw	a5,96(a4)
    8000643c:	8b8d                	andi	a5,a5,3
    8000643e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006440:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006444:	689c                	ld	a5,16(s1)
    80006446:	0204d703          	lhu	a4,32(s1)
    8000644a:	0027d783          	lhu	a5,2(a5)
    8000644e:	04f70863          	beq	a4,a5,8000649e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006452:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006456:	6898                	ld	a4,16(s1)
    80006458:	0204d783          	lhu	a5,32(s1)
    8000645c:	8b9d                	andi	a5,a5,7
    8000645e:	078e                	slli	a5,a5,0x3
    80006460:	97ba                	add	a5,a5,a4
    80006462:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006464:	00278713          	addi	a4,a5,2
    80006468:	0712                	slli	a4,a4,0x4
    8000646a:	9726                	add	a4,a4,s1
    8000646c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006470:	e721                	bnez	a4,800064b8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006472:	0789                	addi	a5,a5,2
    80006474:	0792                	slli	a5,a5,0x4
    80006476:	97a6                	add	a5,a5,s1
    80006478:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000647a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000647e:	ffffc097          	auipc	ra,0xffffc
    80006482:	d8a080e7          	jalr	-630(ra) # 80002208 <wakeup>

    disk.used_idx += 1;
    80006486:	0204d783          	lhu	a5,32(s1)
    8000648a:	2785                	addiw	a5,a5,1
    8000648c:	17c2                	slli	a5,a5,0x30
    8000648e:	93c1                	srli	a5,a5,0x30
    80006490:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006494:	6898                	ld	a4,16(s1)
    80006496:	00275703          	lhu	a4,2(a4)
    8000649a:	faf71ce3          	bne	a4,a5,80006452 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000649e:	0023d517          	auipc	a0,0x23d
    800064a2:	0fa50513          	addi	a0,a0,250 # 80243598 <disk+0x128>
    800064a6:	ffffb097          	auipc	ra,0xffffb
    800064aa:	91a080e7          	jalr	-1766(ra) # 80000dc0 <release>
}
    800064ae:	60e2                	ld	ra,24(sp)
    800064b0:	6442                	ld	s0,16(sp)
    800064b2:	64a2                	ld	s1,8(sp)
    800064b4:	6105                	addi	sp,sp,32
    800064b6:	8082                	ret
      panic("virtio_disk_intr status");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	3c050513          	addi	a0,a0,960 # 80008878 <syscalls+0x3f0>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	080080e7          	jalr	128(ra) # 80000540 <panic>
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

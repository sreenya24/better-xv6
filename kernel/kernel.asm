
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b9813103          	ld	sp,-1128(sp) # 80008b98 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	ba070713          	addi	a4,a4,-1120 # 80008bf0 <timer_scratch>
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
    80000066:	03e78793          	addi	a5,a5,62 # 800060a0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb3587>
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
    8000012e:	4ee080e7          	jalr	1262(ra) # 80002618 <either_copyin>
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
    8000018e:	ba650513          	addi	a0,a0,-1114 # 80010d30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b7a080e7          	jalr	-1158(ra) # 80000d0c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b9648493          	addi	s1,s1,-1130 # 80010d30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	c2690913          	addi	s2,s2,-986 # 80010dc8 <cons+0x98>
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
    800001cc:	29a080e7          	jalr	666(ra) # 80002462 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	fe4080e7          	jalr	-28(ra) # 800021ba <sleep>
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
    80000216:	3b0080e7          	jalr	944(ra) # 800025c2 <either_copyout>
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
    8000022a:	b0a50513          	addi	a0,a0,-1270 # 80010d30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b92080e7          	jalr	-1134(ra) # 80000dc0 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	af450513          	addi	a0,a0,-1292 # 80010d30 <cons>
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
    80000276:	b4f72b23          	sw	a5,-1194(a4) # 80010dc8 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a6450513          	addi	a0,a0,-1436 # 80010d30 <cons>
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
    800002f6:	37c080e7          	jalr	892(ra) # 8000266e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	a3650513          	addi	a0,a0,-1482 # 80010d30 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	a1270713          	addi	a4,a4,-1518 # 80010d30 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	9e878793          	addi	a5,a5,-1560 # 80010d30 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a527a783          	lw	a5,-1454(a5) # 80010dc8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	9a670713          	addi	a4,a4,-1626 # 80010d30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	99648493          	addi	s1,s1,-1642 # 80010d30 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	95a70713          	addi	a4,a4,-1702 # 80010d30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	9ef72223          	sw	a5,-1564(a4) # 80010dd0 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	91e78793          	addi	a5,a5,-1762 # 80010d30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	98c7ab23          	sw	a2,-1642(a5) # 80010dcc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	98a50513          	addi	a0,a0,-1654 # 80010dc8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dd8080e7          	jalr	-552(ra) # 8000221e <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	8d050513          	addi	a0,a0,-1840 # 80010d30 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	814080e7          	jalr	-2028(ra) # 80000c7c <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0024a797          	auipc	a5,0x24a
    8000047c:	c6878793          	addi	a5,a5,-920 # 8024a0e0 <devsw>
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
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8a07a223          	sw	zero,-1884(a5) # 80010df0 <pr+0x18>
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
    80000584:	62f72823          	sw	a5,1584(a4) # 80008bb0 <panicked>
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
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	834dad83          	lw	s11,-1996(s11) # 80010df0 <pr+0x18>
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
    800005fe:	7de50513          	addi	a0,a0,2014 # 80010dd8 <pr>
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
    8000075c:	68050513          	addi	a0,a0,1664 # 80010dd8 <pr>
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
    80000778:	66448493          	addi	s1,s1,1636 # 80010dd8 <pr>
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
    800007d8:	62450513          	addi	a0,a0,1572 # 80010df8 <uart_tx_lock>
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
    80000804:	3b07a783          	lw	a5,944(a5) # 80008bb0 <panicked>
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
    8000083c:	3807b783          	ld	a5,896(a5) # 80008bb8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	38073703          	ld	a4,896(a4) # 80008bc0 <uart_tx_w>
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
    80000866:	596a0a13          	addi	s4,s4,1430 # 80010df8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	34e48493          	addi	s1,s1,846 # 80008bb8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	34e98993          	addi	s3,s3,846 # 80008bc0 <uart_tx_w>
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
    80000898:	98a080e7          	jalr	-1654(ra) # 8000221e <wakeup>
    
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
    800008d4:	52850513          	addi	a0,a0,1320 # 80010df8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	434080e7          	jalr	1076(ra) # 80000d0c <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2d07a783          	lw	a5,720(a5) # 80008bb0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	2d673703          	ld	a4,726(a4) # 80008bc0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2c67b783          	ld	a5,710(a5) # 80008bb8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	4fa98993          	addi	s3,s3,1274 # 80010df8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	2b248493          	addi	s1,s1,690 # 80008bb8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	2b290913          	addi	s2,s2,690 # 80008bc0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	89c080e7          	jalr	-1892(ra) # 800021ba <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	4c448493          	addi	s1,s1,1220 # 80010df8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	26e7bc23          	sd	a4,632(a5) # 80008bc0 <uart_tx_w>
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
    800009be:	43e48493          	addi	s1,s1,1086 # 80010df8 <uart_tx_lock>
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
    800009f8:	43c50513          	addi	a0,a0,1084 # 80010e30 <kmem>
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
    80000a1a:	43a70713          	addi	a4,a4,1082 # 80010e50 <refcnt>
    80000a1e:	9736                	add	a4,a4,a3
    80000a20:	4318                	lw	a4,0(a4)
    80000a22:	02e05763          	blez	a4,80000a50 <increse+0x68>
  {
    panic("increase ref cnt");
  }
  refcnt[pn]++;
    80000a26:	078a                	slli	a5,a5,0x2
    80000a28:	00010697          	auipc	a3,0x10
    80000a2c:	42868693          	addi	a3,a3,1064 # 80010e50 <refcnt>
    80000a30:	97b6                	add	a5,a5,a3
    80000a32:	2705                	addiw	a4,a4,1
    80000a34:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a36:	00010517          	auipc	a0,0x10
    80000a3a:	3fa50513          	addi	a0,a0,1018 # 80010e30 <kmem>
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
    80000a74:	0024b797          	auipc	a5,0x24b
    80000a78:	80478793          	addi	a5,a5,-2044 # 8024b278 <end>
    80000a7c:	06f56563          	bltu	a0,a5,80000ae6 <kfree+0x86>
    80000a80:	47c5                	li	a5,17
    80000a82:	07ee                	slli	a5,a5,0x1b
    80000a84:	06f57163          	bgeu	a0,a5,80000ae6 <kfree+0x86>
  // Fill with junk to catch dangling refs.
  // memset(pa, 1, PGSIZE);

  r = (struct run *)pa;

  acquire(&kmem.lock);
    80000a88:	00010517          	auipc	a0,0x10
    80000a8c:	3a850513          	addi	a0,a0,936 # 80010e30 <kmem>
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	27c080e7          	jalr	636(ra) # 80000d0c <acquire>
  int pn = (uint64)r / PGSIZE;
    80000a98:	00c4d793          	srli	a5,s1,0xc
    80000a9c:	2781                	sext.w	a5,a5
  if (refcnt[pn] < 1)
    80000a9e:	00279693          	slli	a3,a5,0x2
    80000aa2:	00010717          	auipc	a4,0x10
    80000aa6:	3ae70713          	addi	a4,a4,942 # 80010e50 <refcnt>
    80000aaa:	9736                	add	a4,a4,a3
    80000aac:	4318                	lw	a4,0(a4)
    80000aae:	04e05463          	blez	a4,80000af6 <kfree+0x96>
    panic("kfree panic");
  refcnt[pn] -= 1;
    80000ab2:	377d                	addiw	a4,a4,-1
    80000ab4:	0007091b          	sext.w	s2,a4
    80000ab8:	078a                	slli	a5,a5,0x2
    80000aba:	00010697          	auipc	a3,0x10
    80000abe:	39668693          	addi	a3,a3,918 # 80010e50 <refcnt>
    80000ac2:	97b6                	add	a5,a5,a3
    80000ac4:	c398                	sw	a4,0(a5)
  int tmp = refcnt[pn];
  release(&kmem.lock);
    80000ac6:	00010517          	auipc	a0,0x10
    80000aca:	36a50513          	addi	a0,a0,874 # 80010e30 <kmem>
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
    80000b18:	31c90913          	addi	s2,s2,796 # 80010e30 <kmem>
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
    80000b6a:	2eab0b13          	addi	s6,s6,746 # 80010e50 <refcnt>
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
    80000bbc:	27850513          	addi	a0,a0,632 # 80010e30 <kmem>
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	0bc080e7          	jalr	188(ra) # 80000c7c <initlock>
  freerange(end, (void *)PHYSTOP);
    80000bc8:	45c5                	li	a1,17
    80000bca:	05ee                	slli	a1,a1,0x1b
    80000bcc:	0024a517          	auipc	a0,0x24a
    80000bd0:	6ac50513          	addi	a0,a0,1708 # 8024b278 <end>
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
    80000bf2:	24248493          	addi	s1,s1,578 # 80010e30 <kmem>
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
    80000c12:	24270713          	addi	a4,a4,578 # 80010e50 <refcnt>
    80000c16:	9736                	add	a4,a4,a3
    80000c18:	4318                	lw	a4,0(a4)
    80000c1a:	e321                	bnez	a4,80000c5a <kalloc+0x76>
      panic("refcnt kalloc");
    }
    refcnt[pn] = 1;
    80000c1c:	078a                	slli	a5,a5,0x2
    80000c1e:	00010717          	auipc	a4,0x10
    80000c22:	23270713          	addi	a4,a4,562 # 80010e50 <refcnt>
    80000c26:	97ba                	add	a5,a5,a4
    80000c28:	4705                	li	a4,1
    80000c2a:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000c2c:	609c                	ld	a5,0(s1)
    80000c2e:	00010517          	auipc	a0,0x10
    80000c32:	20250513          	addi	a0,a0,514 # 80010e30 <kmem>
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
    80000c6e:	1c650513          	addi	a0,a0,454 # 80010e30 <kmem>
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
    80000fc2:	c0a70713          	addi	a4,a4,-1014 # 80008bc8 <started>
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
    80000ff4:	00002097          	auipc	ra,0x2
    80000ff8:	90e080e7          	jalr	-1778(ra) # 80002902 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ffc:	00005097          	auipc	ra,0x5
    80001000:	0e4080e7          	jalr	228(ra) # 800060e0 <plicinithart>
  }

  scheduler();        
    80001004:	00001097          	auipc	ra,0x1
    80001008:	004080e7          	jalr	4(ra) # 80002008 <scheduler>
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
    8000106c:	00002097          	auipc	ra,0x2
    80001070:	86e080e7          	jalr	-1938(ra) # 800028da <trapinit>
    trapinithart();  // install kernel trap vector
    80001074:	00002097          	auipc	ra,0x2
    80001078:	88e080e7          	jalr	-1906(ra) # 80002902 <trapinithart>
    plicinit();      // set up interrupt controller
    8000107c:	00005097          	auipc	ra,0x5
    80001080:	04e080e7          	jalr	78(ra) # 800060ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001084:	00005097          	auipc	ra,0x5
    80001088:	05c080e7          	jalr	92(ra) # 800060e0 <plicinithart>
    binit();         // buffer cache
    8000108c:	00002097          	auipc	ra,0x2
    80001090:	1f4080e7          	jalr	500(ra) # 80003280 <binit>
    iinit();         // inode table
    80001094:	00003097          	auipc	ra,0x3
    80001098:	894080e7          	jalr	-1900(ra) # 80003928 <iinit>
    fileinit();      // file table
    8000109c:	00004097          	auipc	ra,0x4
    800010a0:	838080e7          	jalr	-1992(ra) # 800048d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a4:	00005097          	auipc	ra,0x5
    800010a8:	144080e7          	jalr	324(ra) # 800061e8 <virtio_disk_init>
    userinit();      // first user process
    800010ac:	00001097          	auipc	ra,0x1
    800010b0:	d3e080e7          	jalr	-706(ra) # 80001dea <userinit>
    __sync_synchronize();
    800010b4:	0ff0000f          	fence
    started = 1;
    800010b8:	4785                	li	a5,1
    800010ba:	00008717          	auipc	a4,0x8
    800010be:	b0f72723          	sw	a5,-1266(a4) # 80008bc8 <started>
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
    800010d2:	b027b783          	ld	a5,-1278(a5) # 80008bd0 <kernel_pagetable>
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
    8000138a:	00008797          	auipc	a5,0x8
    8000138e:	84a7b323          	sd	a0,-1978(a5) # 80008bd0 <kernel_pagetable>
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
    800017f2:	12c080e7          	jalr	300(ra) # 8000291a <cowfault>
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
    80001950:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdb3d87>
    80001954:	95da                	add	a1,a1,s6
    while (n > 0)
    80001956:	96da                	add	a3,a3,s6
      if (*p == '\0')
    80001958:	00f60733          	add	a4,a2,a5
    8000195c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb3d88>
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
    8000199c:	00230497          	auipc	s1,0x230
    800019a0:	8e448493          	addi	s1,s1,-1820 # 80231280 <proc>
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
    800019ba:	ecaa0a13          	addi	s4,s4,-310 # 80238880 <ptable>
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
    800019f0:	1d848493          	addi	s1,s1,472
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
    80001a3c:	41850513          	addi	a0,a0,1048 # 80230e50 <pid_lock>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	23c080e7          	jalr	572(ra) # 80000c7c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	7d858593          	addi	a1,a1,2008 # 80008220 <digits+0x1e0>
    80001a50:	0022f517          	auipc	a0,0x22f
    80001a54:	41850513          	addi	a0,a0,1048 # 80230e68 <wait_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	224080e7          	jalr	548(ra) # 80000c7c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	00230497          	auipc	s1,0x230
    80001a64:	82048493          	addi	s1,s1,-2016 # 80231280 <proc>
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
    80001a82:	00237997          	auipc	s3,0x237
    80001a86:	dfe98993          	addi	s3,s3,-514 # 80238880 <ptable>
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
    80001ab2:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab4:	1d848493          	addi	s1,s1,472
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
    80001af0:	39450513          	addi	a0,a0,916 # 80230e80 <cpus>
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
    80001b18:	33c70713          	addi	a4,a4,828 # 80230e50 <pid_lock>
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
    80001b50:	f947a783          	lw	a5,-108(a5) # 80008ae0 <first.1>
    80001b54:	eb89                	bnez	a5,80001b66 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b56:	00001097          	auipc	ra,0x1
    80001b5a:	e48080e7          	jalr	-440(ra) # 8000299e <usertrapret>
}
    80001b5e:	60a2                	ld	ra,8(sp)
    80001b60:	6402                	ld	s0,0(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret
    first = 0;
    80001b66:	00007797          	auipc	a5,0x7
    80001b6a:	f607ad23          	sw	zero,-134(a5) # 80008ae0 <first.1>
    fsinit(ROOTDEV);
    80001b6e:	4505                	li	a0,1
    80001b70:	00002097          	auipc	ra,0x2
    80001b74:	d38080e7          	jalr	-712(ra) # 800038a8 <fsinit>
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
    80001b8a:	2ca90913          	addi	s2,s2,714 # 80230e50 <pid_lock>
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	17c080e7          	jalr	380(ra) # 80000d0c <acquire>
  pid = nextpid;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	f4c78793          	addi	a5,a5,-180 # 80008ae4 <nextpid>
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
    80001bfc:	06093683          	ld	a3,96(s2)
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
    80001cba:	7128                	ld	a0,96(a0)
    80001cbc:	c509                	beqz	a0,80001cc6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	da2080e7          	jalr	-606(ra) # 80000a60 <kfree>
  p->trapframe = 0;
    80001cc6:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001cca:	6ca8                	ld	a0,88(s1)
    80001ccc:	c511                	beqz	a0,80001cd8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cce:	68ac                	ld	a1,80(s1)
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	f8c080e7          	jalr	-116(ra) # 80001c5c <proc_freepagetable>
  p->pagetable = 0;
    80001cd8:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001cdc:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001ce0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce4:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001ce8:	16048023          	sb	zero,352(s1)
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
    80001d16:	56e48493          	addi	s1,s1,1390 # 80231280 <proc>
    80001d1a:	00237917          	auipc	s2,0x237
    80001d1e:	b6690913          	addi	s2,s2,-1178 # 80238880 <ptable>
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
    80001d3a:	1d848493          	addi	s1,s1,472
    80001d3e:	ff2492e3          	bne	s1,s2,80001d22 <allocproc+0x1c>
  return 0;
    80001d42:	4481                	li	s1,0
    80001d44:	a0a5                	j	80001dac <allocproc+0xa6>
  p->pid = allocpid();
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	e34080e7          	jalr	-460(ra) # 80001b7a <allocpid>
  p->state = USED;
    80001d4e:	4785                	li	a5,1
    80001d50:	cc9c                	sw	a5,24(s1)
  p->pid = nextpid++;
    80001d52:	00007717          	auipc	a4,0x7
    80001d56:	d9270713          	addi	a4,a4,-622 # 80008ae4 <nextpid>
    80001d5a:	431c                	lw	a5,0(a4)
    80001d5c:	0017869b          	addiw	a3,a5,1
    80001d60:	c314                	sw	a3,0(a4)
    80001d62:	d89c                	sw	a5,48(s1)
  p->priority = 60;
    80001d64:	03c00793          	li	a5,60
    80001d68:	d8dc                	sw	a5,52(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	e7a080e7          	jalr	-390(ra) # 80000be4 <kalloc>
    80001d72:	892a                	mv	s2,a0
    80001d74:	f0a8                	sd	a0,96(s1)
    80001d76:	c131                	beqz	a0,80001dba <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	e46080e7          	jalr	-442(ra) # 80001bc0 <proc_pagetable>
    80001d82:	892a                	mv	s2,a0
    80001d84:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001d86:	c531                	beqz	a0,80001dd2 <allocproc+0xcc>
  memset(&p->context, 0, sizeof(p->context));
    80001d88:	07000613          	li	a2,112
    80001d8c:	4581                	li	a1,0
    80001d8e:	06848513          	addi	a0,s1,104
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	076080e7          	jalr	118(ra) # 80000e08 <memset>
  p->context.ra = (uint64)forkret;
    80001d9a:	00000797          	auipc	a5,0x0
    80001d9e:	d9a78793          	addi	a5,a5,-614 # 80001b34 <forkret>
    80001da2:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da4:	64bc                	ld	a5,72(s1)
    80001da6:	6705                	lui	a4,0x1
    80001da8:	97ba                	add	a5,a5,a4
    80001daa:	f8bc                	sd	a5,112(s1)
}
    80001dac:	8526                	mv	a0,s1
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6902                	ld	s2,0(sp)
    80001db6:	6105                	addi	sp,sp,32
    80001db8:	8082                	ret
    freeproc(p);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	ef2080e7          	jalr	-270(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001dc4:	8526                	mv	a0,s1
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	ffa080e7          	jalr	-6(ra) # 80000dc0 <release>
    return 0;
    80001dce:	84ca                	mv	s1,s2
    80001dd0:	bff1                	j	80001dac <allocproc+0xa6>
    freeproc(p);
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	eda080e7          	jalr	-294(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	fe2080e7          	jalr	-30(ra) # 80000dc0 <release>
    return 0;
    80001de6:	84ca                	mv	s1,s2
    80001de8:	b7d1                	j	80001dac <allocproc+0xa6>

0000000080001dea <userinit>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	f12080e7          	jalr	-238(ra) # 80001d06 <allocproc>
    80001dfc:	84aa                	mv	s1,a0
  initproc = p;
    80001dfe:	00007797          	auipc	a5,0x7
    80001e02:	dca7bd23          	sd	a0,-550(a5) # 80008bd8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e06:	03400613          	li	a2,52
    80001e0a:	00007597          	auipc	a1,0x7
    80001e0e:	ce658593          	addi	a1,a1,-794 # 80008af0 <initcode>
    80001e12:	6d28                	ld	a0,88(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	678080e7          	jalr	1656(ra) # 8000148c <uvmfirst>
  p->sz = PGSIZE;
    80001e1c:	6785                	lui	a5,0x1
    80001e1e:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e20:	70b8                	ld	a4,96(s1)
    80001e22:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e26:	70b8                	ld	a4,96(s1)
    80001e28:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e2a:	4641                	li	a2,16
    80001e2c:	00006597          	auipc	a1,0x6
    80001e30:	40c58593          	addi	a1,a1,1036 # 80008238 <digits+0x1f8>
    80001e34:	16048513          	addi	a0,s1,352
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	11a080e7          	jalr	282(ra) # 80000f52 <safestrcpy>
  p->cwd = namei("/");
    80001e40:	00006517          	auipc	a0,0x6
    80001e44:	40850513          	addi	a0,a0,1032 # 80008248 <digits+0x208>
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	488080e7          	jalr	1160(ra) # 800042d0 <namei>
    80001e50:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001e54:	478d                	li	a5,3
    80001e56:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	f66080e7          	jalr	-154(ra) # 80000dc0 <release>
}
    80001e62:	60e2                	ld	ra,24(sp)
    80001e64:	6442                	ld	s0,16(sp)
    80001e66:	64a2                	ld	s1,8(sp)
    80001e68:	6105                	addi	sp,sp,32
    80001e6a:	8082                	ret

0000000080001e6c <growproc>:
{
    80001e6c:	1101                	addi	sp,sp,-32
    80001e6e:	ec06                	sd	ra,24(sp)
    80001e70:	e822                	sd	s0,16(sp)
    80001e72:	e426                	sd	s1,8(sp)
    80001e74:	e04a                	sd	s2,0(sp)
    80001e76:	1000                	addi	s0,sp,32
    80001e78:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	c82080e7          	jalr	-894(ra) # 80001afc <myproc>
    80001e82:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e84:	692c                	ld	a1,80(a0)
  if(n > 0){
    80001e86:	01204c63          	bgtz	s2,80001e9e <growproc+0x32>
  } else if(n < 0){
    80001e8a:	02094663          	bltz	s2,80001eb6 <growproc+0x4a>
  p->sz = sz;
    80001e8e:	e8ac                	sd	a1,80(s1)
  return 0;
    80001e90:	4501                	li	a0,0
}
    80001e92:	60e2                	ld	ra,24(sp)
    80001e94:	6442                	ld	s0,16(sp)
    80001e96:	64a2                	ld	s1,8(sp)
    80001e98:	6902                	ld	s2,0(sp)
    80001e9a:	6105                	addi	sp,sp,32
    80001e9c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e9e:	4691                	li	a3,4
    80001ea0:	00b90633          	add	a2,s2,a1
    80001ea4:	6d28                	ld	a0,88(a0)
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	6a0080e7          	jalr	1696(ra) # 80001546 <uvmalloc>
    80001eae:	85aa                	mv	a1,a0
    80001eb0:	fd79                	bnez	a0,80001e8e <growproc+0x22>
      return -1;
    80001eb2:	557d                	li	a0,-1
    80001eb4:	bff9                	j	80001e92 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eb6:	00b90633          	add	a2,s2,a1
    80001eba:	6d28                	ld	a0,88(a0)
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	642080e7          	jalr	1602(ra) # 800014fe <uvmdealloc>
    80001ec4:	85aa                	mv	a1,a0
    80001ec6:	b7e1                	j	80001e8e <growproc+0x22>

0000000080001ec8 <fork>:
{
    80001ec8:	7139                	addi	sp,sp,-64
    80001eca:	fc06                	sd	ra,56(sp)
    80001ecc:	f822                	sd	s0,48(sp)
    80001ece:	f426                	sd	s1,40(sp)
    80001ed0:	f04a                	sd	s2,32(sp)
    80001ed2:	ec4e                	sd	s3,24(sp)
    80001ed4:	e852                	sd	s4,16(sp)
    80001ed6:	e456                	sd	s5,8(sp)
    80001ed8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	c22080e7          	jalr	-990(ra) # 80001afc <myproc>
    80001ee2:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	e22080e7          	jalr	-478(ra) # 80001d06 <allocproc>
    80001eec:	10050c63          	beqz	a0,80002004 <fork+0x13c>
    80001ef0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ef2:	050ab603          	ld	a2,80(s5)
    80001ef6:	6d2c                	ld	a1,88(a0)
    80001ef8:	058ab503          	ld	a0,88(s5)
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	7a2080e7          	jalr	1954(ra) # 8000169e <uvmcopy>
    80001f04:	04054863          	bltz	a0,80001f54 <fork+0x8c>
  np->sz = p->sz;
    80001f08:	050ab783          	ld	a5,80(s5)
    80001f0c:	04fa3823          	sd	a5,80(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f10:	060ab683          	ld	a3,96(s5)
    80001f14:	87b6                	mv	a5,a3
    80001f16:	060a3703          	ld	a4,96(s4)
    80001f1a:	12068693          	addi	a3,a3,288
    80001f1e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f22:	6788                	ld	a0,8(a5)
    80001f24:	6b8c                	ld	a1,16(a5)
    80001f26:	6f90                	ld	a2,24(a5)
    80001f28:	01073023          	sd	a6,0(a4)
    80001f2c:	e708                	sd	a0,8(a4)
    80001f2e:	eb0c                	sd	a1,16(a4)
    80001f30:	ef10                	sd	a2,24(a4)
    80001f32:	02078793          	addi	a5,a5,32
    80001f36:	02070713          	addi	a4,a4,32
    80001f3a:	fed792e3          	bne	a5,a3,80001f1e <fork+0x56>
  np->trapframe->a0 = 0;
    80001f3e:	060a3783          	ld	a5,96(s4)
    80001f42:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f46:	0d8a8493          	addi	s1,s5,216
    80001f4a:	0d8a0913          	addi	s2,s4,216
    80001f4e:	158a8993          	addi	s3,s5,344
    80001f52:	a00d                	j	80001f74 <fork+0xac>
    freeproc(np);
    80001f54:	8552                	mv	a0,s4
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	d58080e7          	jalr	-680(ra) # 80001cae <freeproc>
    release(&np->lock);
    80001f5e:	8552                	mv	a0,s4
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	e60080e7          	jalr	-416(ra) # 80000dc0 <release>
    return -1;
    80001f68:	597d                	li	s2,-1
    80001f6a:	a059                	j	80001ff0 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001f6c:	04a1                	addi	s1,s1,8
    80001f6e:	0921                	addi	s2,s2,8
    80001f70:	01348b63          	beq	s1,s3,80001f86 <fork+0xbe>
    if(p->ofile[i])
    80001f74:	6088                	ld	a0,0(s1)
    80001f76:	d97d                	beqz	a0,80001f6c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f78:	00003097          	auipc	ra,0x3
    80001f7c:	9ee080e7          	jalr	-1554(ra) # 80004966 <filedup>
    80001f80:	00a93023          	sd	a0,0(s2)
    80001f84:	b7e5                	j	80001f6c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f86:	158ab503          	ld	a0,344(s5)
    80001f8a:	00002097          	auipc	ra,0x2
    80001f8e:	b5e080e7          	jalr	-1186(ra) # 80003ae8 <idup>
    80001f92:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f96:	4641                	li	a2,16
    80001f98:	160a8593          	addi	a1,s5,352
    80001f9c:	160a0513          	addi	a0,s4,352
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	fb2080e7          	jalr	-78(ra) # 80000f52 <safestrcpy>
  pid = np->pid;
    80001fa8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001fac:	8552                	mv	a0,s4
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	e12080e7          	jalr	-494(ra) # 80000dc0 <release>
  acquire(&wait_lock);
    80001fb6:	0022f497          	auipc	s1,0x22f
    80001fba:	eb248493          	addi	s1,s1,-334 # 80230e68 <wait_lock>
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	d4c080e7          	jalr	-692(ra) # 80000d0c <acquire>
  np->parent = p;
    80001fc8:	055a3023          	sd	s5,64(s4)
  release(&wait_lock);
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	df2080e7          	jalr	-526(ra) # 80000dc0 <release>
  acquire(&np->lock);
    80001fd6:	8552                	mv	a0,s4
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	d34080e7          	jalr	-716(ra) # 80000d0c <acquire>
  np->state = RUNNABLE;
    80001fe0:	478d                	li	a5,3
    80001fe2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fe6:	8552                	mv	a0,s4
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	dd8080e7          	jalr	-552(ra) # 80000dc0 <release>
}
    80001ff0:	854a                	mv	a0,s2
    80001ff2:	70e2                	ld	ra,56(sp)
    80001ff4:	7442                	ld	s0,48(sp)
    80001ff6:	74a2                	ld	s1,40(sp)
    80001ff8:	7902                	ld	s2,32(sp)
    80001ffa:	69e2                	ld	s3,24(sp)
    80001ffc:	6a42                	ld	s4,16(sp)
    80001ffe:	6aa2                	ld	s5,8(sp)
    80002000:	6121                	addi	sp,sp,64
    80002002:	8082                	ret
    return -1;
    80002004:	597d                	li	s2,-1
    80002006:	b7ed                	j	80001ff0 <fork+0x128>

0000000080002008 <scheduler>:
{
    80002008:	7139                	addi	sp,sp,-64
    8000200a:	fc06                	sd	ra,56(sp)
    8000200c:	f822                	sd	s0,48(sp)
    8000200e:	f426                	sd	s1,40(sp)
    80002010:	f04a                	sd	s2,32(sp)
    80002012:	ec4e                	sd	s3,24(sp)
    80002014:	e852                	sd	s4,16(sp)
    80002016:	e456                	sd	s5,8(sp)
    80002018:	e05a                	sd	s6,0(sp)
    8000201a:	0080                	addi	s0,sp,64
    8000201c:	8792                	mv	a5,tp
  int id = r_tp();
    8000201e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002020:	00779a93          	slli	s5,a5,0x7
    80002024:	0022f717          	auipc	a4,0x22f
    80002028:	e2c70713          	addi	a4,a4,-468 # 80230e50 <pid_lock>
    8000202c:	9756                	add	a4,a4,s5
    8000202e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002032:	0022f717          	auipc	a4,0x22f
    80002036:	e5670713          	addi	a4,a4,-426 # 80230e88 <cpus+0x8>
    8000203a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000203c:	498d                	li	s3,3
        p->state = RUNNING;
    8000203e:	4b11                	li	s6,4
        c->proc = p;
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	0022fa17          	auipc	s4,0x22f
    80002046:	e0ea0a13          	addi	s4,s4,-498 # 80230e50 <pid_lock>
    8000204a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000204c:	00237917          	auipc	s2,0x237
    80002050:	83490913          	addi	s2,s2,-1996 # 80238880 <ptable>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002054:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002058:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000205c:	10079073          	csrw	sstatus,a5
    80002060:	0022f497          	auipc	s1,0x22f
    80002064:	22048493          	addi	s1,s1,544 # 80231280 <proc>
    80002068:	a811                	j	8000207c <scheduler+0x74>
      release(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	d54080e7          	jalr	-684(ra) # 80000dc0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002074:	1d848493          	addi	s1,s1,472
    80002078:	fd248ee3          	beq	s1,s2,80002054 <scheduler+0x4c>
      acquire(&p->lock);
    8000207c:	8526                	mv	a0,s1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c8e080e7          	jalr	-882(ra) # 80000d0c <acquire>
      if(p->state == RUNNABLE) {
    80002086:	4c9c                	lw	a5,24(s1)
    80002088:	ff3791e3          	bne	a5,s3,8000206a <scheduler+0x62>
        p->state = RUNNING;
    8000208c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002090:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002094:	06848593          	addi	a1,s1,104
    80002098:	8556                	mv	a0,s5
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	7d6080e7          	jalr	2006(ra) # 80002870 <swtch>
        c->proc = 0;
    800020a2:	020a3823          	sd	zero,48(s4)
    800020a6:	b7d1                	j	8000206a <scheduler+0x62>

00000000800020a8 <sched>:
{
    800020a8:	7179                	addi	sp,sp,-48
    800020aa:	f406                	sd	ra,40(sp)
    800020ac:	f022                	sd	s0,32(sp)
    800020ae:	ec26                	sd	s1,24(sp)
    800020b0:	e84a                	sd	s2,16(sp)
    800020b2:	e44e                	sd	s3,8(sp)
    800020b4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	a46080e7          	jalr	-1466(ra) # 80001afc <myproc>
    800020be:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	bd2080e7          	jalr	-1070(ra) # 80000c92 <holding>
    800020c8:	c93d                	beqz	a0,8000213e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ca:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020cc:	2781                	sext.w	a5,a5
    800020ce:	079e                	slli	a5,a5,0x7
    800020d0:	0022f717          	auipc	a4,0x22f
    800020d4:	d8070713          	addi	a4,a4,-640 # 80230e50 <pid_lock>
    800020d8:	97ba                	add	a5,a5,a4
    800020da:	0a87a703          	lw	a4,168(a5)
    800020de:	4785                	li	a5,1
    800020e0:	06f71763          	bne	a4,a5,8000214e <sched+0xa6>
  if(p->state == RUNNING)
    800020e4:	4c98                	lw	a4,24(s1)
    800020e6:	4791                	li	a5,4
    800020e8:	06f70b63          	beq	a4,a5,8000215e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020f0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020f2:	efb5                	bnez	a5,8000216e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020f4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020f6:	0022f917          	auipc	s2,0x22f
    800020fa:	d5a90913          	addi	s2,s2,-678 # 80230e50 <pid_lock>
    800020fe:	2781                	sext.w	a5,a5
    80002100:	079e                	slli	a5,a5,0x7
    80002102:	97ca                	add	a5,a5,s2
    80002104:	0ac7a983          	lw	s3,172(a5)
    80002108:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000210a:	2781                	sext.w	a5,a5
    8000210c:	079e                	slli	a5,a5,0x7
    8000210e:	0022f597          	auipc	a1,0x22f
    80002112:	d7a58593          	addi	a1,a1,-646 # 80230e88 <cpus+0x8>
    80002116:	95be                	add	a1,a1,a5
    80002118:	06848513          	addi	a0,s1,104
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	754080e7          	jalr	1876(ra) # 80002870 <swtch>
    80002124:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002126:	2781                	sext.w	a5,a5
    80002128:	079e                	slli	a5,a5,0x7
    8000212a:	993e                	add	s2,s2,a5
    8000212c:	0b392623          	sw	s3,172(s2)
}
    80002130:	70a2                	ld	ra,40(sp)
    80002132:	7402                	ld	s0,32(sp)
    80002134:	64e2                	ld	s1,24(sp)
    80002136:	6942                	ld	s2,16(sp)
    80002138:	69a2                	ld	s3,8(sp)
    8000213a:	6145                	addi	sp,sp,48
    8000213c:	8082                	ret
    panic("sched p->lock");
    8000213e:	00006517          	auipc	a0,0x6
    80002142:	11250513          	addi	a0,a0,274 # 80008250 <digits+0x210>
    80002146:	ffffe097          	auipc	ra,0xffffe
    8000214a:	3fa080e7          	jalr	1018(ra) # 80000540 <panic>
    panic("sched locks");
    8000214e:	00006517          	auipc	a0,0x6
    80002152:	11250513          	addi	a0,a0,274 # 80008260 <digits+0x220>
    80002156:	ffffe097          	auipc	ra,0xffffe
    8000215a:	3ea080e7          	jalr	1002(ra) # 80000540 <panic>
    panic("sched running");
    8000215e:	00006517          	auipc	a0,0x6
    80002162:	11250513          	addi	a0,a0,274 # 80008270 <digits+0x230>
    80002166:	ffffe097          	auipc	ra,0xffffe
    8000216a:	3da080e7          	jalr	986(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000216e:	00006517          	auipc	a0,0x6
    80002172:	11250513          	addi	a0,a0,274 # 80008280 <digits+0x240>
    80002176:	ffffe097          	auipc	ra,0xffffe
    8000217a:	3ca080e7          	jalr	970(ra) # 80000540 <panic>

000000008000217e <yield>:
{
    8000217e:	1101                	addi	sp,sp,-32
    80002180:	ec06                	sd	ra,24(sp)
    80002182:	e822                	sd	s0,16(sp)
    80002184:	e426                	sd	s1,8(sp)
    80002186:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	974080e7          	jalr	-1676(ra) # 80001afc <myproc>
    80002190:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b7a080e7          	jalr	-1158(ra) # 80000d0c <acquire>
  p->state = RUNNABLE;
    8000219a:	478d                	li	a5,3
    8000219c:	cc9c                	sw	a5,24(s1)
  sched();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	f0a080e7          	jalr	-246(ra) # 800020a8 <sched>
  release(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	c18080e7          	jalr	-1000(ra) # 80000dc0 <release>
}
    800021b0:	60e2                	ld	ra,24(sp)
    800021b2:	6442                	ld	s0,16(sp)
    800021b4:	64a2                	ld	s1,8(sp)
    800021b6:	6105                	addi	sp,sp,32
    800021b8:	8082                	ret

00000000800021ba <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021ba:	7179                	addi	sp,sp,-48
    800021bc:	f406                	sd	ra,40(sp)
    800021be:	f022                	sd	s0,32(sp)
    800021c0:	ec26                	sd	s1,24(sp)
    800021c2:	e84a                	sd	s2,16(sp)
    800021c4:	e44e                	sd	s3,8(sp)
    800021c6:	1800                	addi	s0,sp,48
    800021c8:	89aa                	mv	s3,a0
    800021ca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	930080e7          	jalr	-1744(ra) # 80001afc <myproc>
    800021d4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	b36080e7          	jalr	-1226(ra) # 80000d0c <acquire>
  release(lk);
    800021de:	854a                	mv	a0,s2
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	be0080e7          	jalr	-1056(ra) # 80000dc0 <release>

  // Go to sleep.
  p->chan = chan;
    800021e8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021ec:	4789                	li	a5,2
    800021ee:	cc9c                	sw	a5,24(s1)

  sched();
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	eb8080e7          	jalr	-328(ra) # 800020a8 <sched>

  // Tidy up.
  p->chan = 0;
    800021f8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021fc:	8526                	mv	a0,s1
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	bc2080e7          	jalr	-1086(ra) # 80000dc0 <release>
  acquire(lk);
    80002206:	854a                	mv	a0,s2
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	b04080e7          	jalr	-1276(ra) # 80000d0c <acquire>
}
    80002210:	70a2                	ld	ra,40(sp)
    80002212:	7402                	ld	s0,32(sp)
    80002214:	64e2                	ld	s1,24(sp)
    80002216:	6942                	ld	s2,16(sp)
    80002218:	69a2                	ld	s3,8(sp)
    8000221a:	6145                	addi	sp,sp,48
    8000221c:	8082                	ret

000000008000221e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000221e:	7139                	addi	sp,sp,-64
    80002220:	fc06                	sd	ra,56(sp)
    80002222:	f822                	sd	s0,48(sp)
    80002224:	f426                	sd	s1,40(sp)
    80002226:	f04a                	sd	s2,32(sp)
    80002228:	ec4e                	sd	s3,24(sp)
    8000222a:	e852                	sd	s4,16(sp)
    8000222c:	e456                	sd	s5,8(sp)
    8000222e:	0080                	addi	s0,sp,64
    80002230:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002232:	0022f497          	auipc	s1,0x22f
    80002236:	04e48493          	addi	s1,s1,78 # 80231280 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000223a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000223c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000223e:	00236917          	auipc	s2,0x236
    80002242:	64290913          	addi	s2,s2,1602 # 80238880 <ptable>
    80002246:	a811                	j	8000225a <wakeup+0x3c>
      }
      release(&p->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	b76080e7          	jalr	-1162(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002252:	1d848493          	addi	s1,s1,472
    80002256:	03248663          	beq	s1,s2,80002282 <wakeup+0x64>
    if(p != myproc()){
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	8a2080e7          	jalr	-1886(ra) # 80001afc <myproc>
    80002262:	fea488e3          	beq	s1,a0,80002252 <wakeup+0x34>
      acquire(&p->lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	aa4080e7          	jalr	-1372(ra) # 80000d0c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002270:	4c9c                	lw	a5,24(s1)
    80002272:	fd379be3          	bne	a5,s3,80002248 <wakeup+0x2a>
    80002276:	709c                	ld	a5,32(s1)
    80002278:	fd4798e3          	bne	a5,s4,80002248 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000227c:	0154ac23          	sw	s5,24(s1)
    80002280:	b7e1                	j	80002248 <wakeup+0x2a>
    }
  }
}
    80002282:	70e2                	ld	ra,56(sp)
    80002284:	7442                	ld	s0,48(sp)
    80002286:	74a2                	ld	s1,40(sp)
    80002288:	7902                	ld	s2,32(sp)
    8000228a:	69e2                	ld	s3,24(sp)
    8000228c:	6a42                	ld	s4,16(sp)
    8000228e:	6aa2                	ld	s5,8(sp)
    80002290:	6121                	addi	sp,sp,64
    80002292:	8082                	ret

0000000080002294 <reparent>:
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	e052                	sd	s4,0(sp)
    800022a2:	1800                	addi	s0,sp,48
    800022a4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a6:	0022f497          	auipc	s1,0x22f
    800022aa:	fda48493          	addi	s1,s1,-38 # 80231280 <proc>
      pp->parent = initproc;
    800022ae:	00007a17          	auipc	s4,0x7
    800022b2:	92aa0a13          	addi	s4,s4,-1750 # 80008bd8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022b6:	00236997          	auipc	s3,0x236
    800022ba:	5ca98993          	addi	s3,s3,1482 # 80238880 <ptable>
    800022be:	a029                	j	800022c8 <reparent+0x34>
    800022c0:	1d848493          	addi	s1,s1,472
    800022c4:	01348d63          	beq	s1,s3,800022de <reparent+0x4a>
    if(pp->parent == p){
    800022c8:	60bc                	ld	a5,64(s1)
    800022ca:	ff279be3          	bne	a5,s2,800022c0 <reparent+0x2c>
      pp->parent = initproc;
    800022ce:	000a3503          	ld	a0,0(s4)
    800022d2:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	f4a080e7          	jalr	-182(ra) # 8000221e <wakeup>
    800022dc:	b7d5                	j	800022c0 <reparent+0x2c>
}
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6942                	ld	s2,16(sp)
    800022e6:	69a2                	ld	s3,8(sp)
    800022e8:	6a02                	ld	s4,0(sp)
    800022ea:	6145                	addi	sp,sp,48
    800022ec:	8082                	ret

00000000800022ee <exit>:
{
    800022ee:	7179                	addi	sp,sp,-48
    800022f0:	f406                	sd	ra,40(sp)
    800022f2:	f022                	sd	s0,32(sp)
    800022f4:	ec26                	sd	s1,24(sp)
    800022f6:	e84a                	sd	s2,16(sp)
    800022f8:	e44e                	sd	s3,8(sp)
    800022fa:	e052                	sd	s4,0(sp)
    800022fc:	1800                	addi	s0,sp,48
    800022fe:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	7fc080e7          	jalr	2044(ra) # 80001afc <myproc>
    80002308:	89aa                	mv	s3,a0
  if(p == initproc)
    8000230a:	00007797          	auipc	a5,0x7
    8000230e:	8ce7b783          	ld	a5,-1842(a5) # 80008bd8 <initproc>
    80002312:	0d850493          	addi	s1,a0,216
    80002316:	15850913          	addi	s2,a0,344
    8000231a:	02a79363          	bne	a5,a0,80002340 <exit+0x52>
    panic("init exiting");
    8000231e:	00006517          	auipc	a0,0x6
    80002322:	f7a50513          	addi	a0,a0,-134 # 80008298 <digits+0x258>
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	21a080e7          	jalr	538(ra) # 80000540 <panic>
      fileclose(f);
    8000232e:	00002097          	auipc	ra,0x2
    80002332:	68a080e7          	jalr	1674(ra) # 800049b8 <fileclose>
      p->ofile[fd] = 0;
    80002336:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000233a:	04a1                	addi	s1,s1,8
    8000233c:	01248563          	beq	s1,s2,80002346 <exit+0x58>
    if(p->ofile[fd]){
    80002340:	6088                	ld	a0,0(s1)
    80002342:	f575                	bnez	a0,8000232e <exit+0x40>
    80002344:	bfdd                	j	8000233a <exit+0x4c>
  begin_op();
    80002346:	00002097          	auipc	ra,0x2
    8000234a:	1aa080e7          	jalr	426(ra) # 800044f0 <begin_op>
  iput(p->cwd);
    8000234e:	1589b503          	ld	a0,344(s3)
    80002352:	00002097          	auipc	ra,0x2
    80002356:	98e080e7          	jalr	-1650(ra) # 80003ce0 <iput>
  end_op();
    8000235a:	00002097          	auipc	ra,0x2
    8000235e:	214080e7          	jalr	532(ra) # 8000456e <end_op>
  p->cwd = 0;
    80002362:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002366:	0022f497          	auipc	s1,0x22f
    8000236a:	b0248493          	addi	s1,s1,-1278 # 80230e68 <wait_lock>
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	99c080e7          	jalr	-1636(ra) # 80000d0c <acquire>
  reparent(p);
    80002378:	854e                	mv	a0,s3
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	f1a080e7          	jalr	-230(ra) # 80002294 <reparent>
  wakeup(p->parent);
    80002382:	0409b503          	ld	a0,64(s3)
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	e98080e7          	jalr	-360(ra) # 8000221e <wakeup>
  acquire(&p->lock);
    8000238e:	854e                	mv	a0,s3
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	97c080e7          	jalr	-1668(ra) # 80000d0c <acquire>
  p->xstate = status;
    80002398:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000239c:	4795                	li	a5,5
    8000239e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	a1c080e7          	jalr	-1508(ra) # 80000dc0 <release>
  sched();
    800023ac:	00000097          	auipc	ra,0x0
    800023b0:	cfc080e7          	jalr	-772(ra) # 800020a8 <sched>
  panic("zombie exit");
    800023b4:	00006517          	auipc	a0,0x6
    800023b8:	ef450513          	addi	a0,a0,-268 # 800082a8 <digits+0x268>
    800023bc:	ffffe097          	auipc	ra,0xffffe
    800023c0:	184080e7          	jalr	388(ra) # 80000540 <panic>

00000000800023c4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023c4:	7179                	addi	sp,sp,-48
    800023c6:	f406                	sd	ra,40(sp)
    800023c8:	f022                	sd	s0,32(sp)
    800023ca:	ec26                	sd	s1,24(sp)
    800023cc:	e84a                	sd	s2,16(sp)
    800023ce:	e44e                	sd	s3,8(sp)
    800023d0:	1800                	addi	s0,sp,48
    800023d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023d4:	0022f497          	auipc	s1,0x22f
    800023d8:	eac48493          	addi	s1,s1,-340 # 80231280 <proc>
    800023dc:	00236997          	auipc	s3,0x236
    800023e0:	4a498993          	addi	s3,s3,1188 # 80238880 <ptable>
    acquire(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	926080e7          	jalr	-1754(ra) # 80000d0c <acquire>
    if(p->pid == pid){
    800023ee:	589c                	lw	a5,48(s1)
    800023f0:	01278d63          	beq	a5,s2,8000240a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	9ca080e7          	jalr	-1590(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023fe:	1d848493          	addi	s1,s1,472
    80002402:	ff3491e3          	bne	s1,s3,800023e4 <kill+0x20>
  }
  return -1;
    80002406:	557d                	li	a0,-1
    80002408:	a829                	j	80002422 <kill+0x5e>
      p->killed = 1;
    8000240a:	4785                	li	a5,1
    8000240c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000240e:	4c98                	lw	a4,24(s1)
    80002410:	4789                	li	a5,2
    80002412:	00f70f63          	beq	a4,a5,80002430 <kill+0x6c>
      release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	9a8080e7          	jalr	-1624(ra) # 80000dc0 <release>
      return 0;
    80002420:	4501                	li	a0,0
}
    80002422:	70a2                	ld	ra,40(sp)
    80002424:	7402                	ld	s0,32(sp)
    80002426:	64e2                	ld	s1,24(sp)
    80002428:	6942                	ld	s2,16(sp)
    8000242a:	69a2                	ld	s3,8(sp)
    8000242c:	6145                	addi	sp,sp,48
    8000242e:	8082                	ret
        p->state = RUNNABLE;
    80002430:	478d                	li	a5,3
    80002432:	cc9c                	sw	a5,24(s1)
    80002434:	b7cd                	j	80002416 <kill+0x52>

0000000080002436 <setkilled>:

void
setkilled(struct proc *p)
{
    80002436:	1101                	addi	sp,sp,-32
    80002438:	ec06                	sd	ra,24(sp)
    8000243a:	e822                	sd	s0,16(sp)
    8000243c:	e426                	sd	s1,8(sp)
    8000243e:	1000                	addi	s0,sp,32
    80002440:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	8ca080e7          	jalr	-1846(ra) # 80000d0c <acquire>
  p->killed = 1;
    8000244a:	4785                	li	a5,1
    8000244c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	970080e7          	jalr	-1680(ra) # 80000dc0 <release>
}
    80002458:	60e2                	ld	ra,24(sp)
    8000245a:	6442                	ld	s0,16(sp)
    8000245c:	64a2                	ld	s1,8(sp)
    8000245e:	6105                	addi	sp,sp,32
    80002460:	8082                	ret

0000000080002462 <killed>:

int
killed(struct proc *p)
{
    80002462:	1101                	addi	sp,sp,-32
    80002464:	ec06                	sd	ra,24(sp)
    80002466:	e822                	sd	s0,16(sp)
    80002468:	e426                	sd	s1,8(sp)
    8000246a:	e04a                	sd	s2,0(sp)
    8000246c:	1000                	addi	s0,sp,32
    8000246e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	89c080e7          	jalr	-1892(ra) # 80000d0c <acquire>
  k = p->killed;
    80002478:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	942080e7          	jalr	-1726(ra) # 80000dc0 <release>
  return k;
}
    80002486:	854a                	mv	a0,s2
    80002488:	60e2                	ld	ra,24(sp)
    8000248a:	6442                	ld	s0,16(sp)
    8000248c:	64a2                	ld	s1,8(sp)
    8000248e:	6902                	ld	s2,0(sp)
    80002490:	6105                	addi	sp,sp,32
    80002492:	8082                	ret

0000000080002494 <wait>:
{
    80002494:	715d                	addi	sp,sp,-80
    80002496:	e486                	sd	ra,72(sp)
    80002498:	e0a2                	sd	s0,64(sp)
    8000249a:	fc26                	sd	s1,56(sp)
    8000249c:	f84a                	sd	s2,48(sp)
    8000249e:	f44e                	sd	s3,40(sp)
    800024a0:	f052                	sd	s4,32(sp)
    800024a2:	ec56                	sd	s5,24(sp)
    800024a4:	e85a                	sd	s6,16(sp)
    800024a6:	e45e                	sd	s7,8(sp)
    800024a8:	e062                	sd	s8,0(sp)
    800024aa:	0880                	addi	s0,sp,80
    800024ac:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	64e080e7          	jalr	1614(ra) # 80001afc <myproc>
    800024b6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024b8:	0022f517          	auipc	a0,0x22f
    800024bc:	9b050513          	addi	a0,a0,-1616 # 80230e68 <wait_lock>
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	84c080e7          	jalr	-1972(ra) # 80000d0c <acquire>
    havekids = 0;
    800024c8:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800024ca:	4a15                	li	s4,5
        havekids = 1;
    800024cc:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ce:	00236997          	auipc	s3,0x236
    800024d2:	3b298993          	addi	s3,s3,946 # 80238880 <ptable>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	0022fc17          	auipc	s8,0x22f
    800024da:	992c0c13          	addi	s8,s8,-1646 # 80230e68 <wait_lock>
    havekids = 0;
    800024de:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e0:	0022f497          	auipc	s1,0x22f
    800024e4:	da048493          	addi	s1,s1,-608 # 80231280 <proc>
    800024e8:	a0bd                	j	80002556 <wait+0xc2>
          pid = pp->pid;
    800024ea:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024ee:	000b0e63          	beqz	s6,8000250a <wait+0x76>
    800024f2:	4691                	li	a3,4
    800024f4:	02c48613          	addi	a2,s1,44
    800024f8:	85da                	mv	a1,s6
    800024fa:	05893503          	ld	a0,88(s2)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	28a080e7          	jalr	650(ra) # 80001788 <copyout>
    80002506:	02054563          	bltz	a0,80002530 <wait+0x9c>
          freeproc(pp);
    8000250a:	8526                	mv	a0,s1
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	7a2080e7          	jalr	1954(ra) # 80001cae <freeproc>
          release(&pp->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	8aa080e7          	jalr	-1878(ra) # 80000dc0 <release>
          release(&wait_lock);
    8000251e:	0022f517          	auipc	a0,0x22f
    80002522:	94a50513          	addi	a0,a0,-1718 # 80230e68 <wait_lock>
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	89a080e7          	jalr	-1894(ra) # 80000dc0 <release>
          return pid;
    8000252e:	a0b5                	j	8000259a <wait+0x106>
            release(&pp->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	88e080e7          	jalr	-1906(ra) # 80000dc0 <release>
            release(&wait_lock);
    8000253a:	0022f517          	auipc	a0,0x22f
    8000253e:	92e50513          	addi	a0,a0,-1746 # 80230e68 <wait_lock>
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	87e080e7          	jalr	-1922(ra) # 80000dc0 <release>
            return -1;
    8000254a:	59fd                	li	s3,-1
    8000254c:	a0b9                	j	8000259a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000254e:	1d848493          	addi	s1,s1,472
    80002552:	03348463          	beq	s1,s3,8000257a <wait+0xe6>
      if(pp->parent == p){
    80002556:	60bc                	ld	a5,64(s1)
    80002558:	ff279be3          	bne	a5,s2,8000254e <wait+0xba>
        acquire(&pp->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	7ae080e7          	jalr	1966(ra) # 80000d0c <acquire>
        if(pp->state == ZOMBIE){
    80002566:	4c9c                	lw	a5,24(s1)
    80002568:	f94781e3          	beq	a5,s4,800024ea <wait+0x56>
        release(&pp->lock);
    8000256c:	8526                	mv	a0,s1
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	852080e7          	jalr	-1966(ra) # 80000dc0 <release>
        havekids = 1;
    80002576:	8756                	mv	a4,s5
    80002578:	bfd9                	j	8000254e <wait+0xba>
    if(!havekids || killed(p)){
    8000257a:	c719                	beqz	a4,80002588 <wait+0xf4>
    8000257c:	854a                	mv	a0,s2
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	ee4080e7          	jalr	-284(ra) # 80002462 <killed>
    80002586:	c51d                	beqz	a0,800025b4 <wait+0x120>
      release(&wait_lock);
    80002588:	0022f517          	auipc	a0,0x22f
    8000258c:	8e050513          	addi	a0,a0,-1824 # 80230e68 <wait_lock>
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	830080e7          	jalr	-2000(ra) # 80000dc0 <release>
      return -1;
    80002598:	59fd                	li	s3,-1
}
    8000259a:	854e                	mv	a0,s3
    8000259c:	60a6                	ld	ra,72(sp)
    8000259e:	6406                	ld	s0,64(sp)
    800025a0:	74e2                	ld	s1,56(sp)
    800025a2:	7942                	ld	s2,48(sp)
    800025a4:	79a2                	ld	s3,40(sp)
    800025a6:	7a02                	ld	s4,32(sp)
    800025a8:	6ae2                	ld	s5,24(sp)
    800025aa:	6b42                	ld	s6,16(sp)
    800025ac:	6ba2                	ld	s7,8(sp)
    800025ae:	6c02                	ld	s8,0(sp)
    800025b0:	6161                	addi	sp,sp,80
    800025b2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025b4:	85e2                	mv	a1,s8
    800025b6:	854a                	mv	a0,s2
    800025b8:	00000097          	auipc	ra,0x0
    800025bc:	c02080e7          	jalr	-1022(ra) # 800021ba <sleep>
    havekids = 0;
    800025c0:	bf39                	j	800024de <wait+0x4a>

00000000800025c2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025c2:	7179                	addi	sp,sp,-48
    800025c4:	f406                	sd	ra,40(sp)
    800025c6:	f022                	sd	s0,32(sp)
    800025c8:	ec26                	sd	s1,24(sp)
    800025ca:	e84a                	sd	s2,16(sp)
    800025cc:	e44e                	sd	s3,8(sp)
    800025ce:	e052                	sd	s4,0(sp)
    800025d0:	1800                	addi	s0,sp,48
    800025d2:	84aa                	mv	s1,a0
    800025d4:	892e                	mv	s2,a1
    800025d6:	89b2                	mv	s3,a2
    800025d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025da:	fffff097          	auipc	ra,0xfffff
    800025de:	522080e7          	jalr	1314(ra) # 80001afc <myproc>
  if(user_dst){
    800025e2:	c08d                	beqz	s1,80002604 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025e4:	86d2                	mv	a3,s4
    800025e6:	864e                	mv	a2,s3
    800025e8:	85ca                	mv	a1,s2
    800025ea:	6d28                	ld	a0,88(a0)
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	19c080e7          	jalr	412(ra) # 80001788 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025f4:	70a2                	ld	ra,40(sp)
    800025f6:	7402                	ld	s0,32(sp)
    800025f8:	64e2                	ld	s1,24(sp)
    800025fa:	6942                	ld	s2,16(sp)
    800025fc:	69a2                	ld	s3,8(sp)
    800025fe:	6a02                	ld	s4,0(sp)
    80002600:	6145                	addi	sp,sp,48
    80002602:	8082                	ret
    memmove((char *)dst, src, len);
    80002604:	000a061b          	sext.w	a2,s4
    80002608:	85ce                	mv	a1,s3
    8000260a:	854a                	mv	a0,s2
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	858080e7          	jalr	-1960(ra) # 80000e64 <memmove>
    return 0;
    80002614:	8526                	mv	a0,s1
    80002616:	bff9                	j	800025f4 <either_copyout+0x32>

0000000080002618 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002618:	7179                	addi	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	e052                	sd	s4,0(sp)
    80002626:	1800                	addi	s0,sp,48
    80002628:	892a                	mv	s2,a0
    8000262a:	84ae                	mv	s1,a1
    8000262c:	89b2                	mv	s3,a2
    8000262e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	4cc080e7          	jalr	1228(ra) # 80001afc <myproc>
  if(user_src){
    80002638:	c08d                	beqz	s1,8000265a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000263a:	86d2                	mv	a3,s4
    8000263c:	864e                	mv	a2,s3
    8000263e:	85ca                	mv	a1,s2
    80002640:	6d28                	ld	a0,88(a0)
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	206080e7          	jalr	518(ra) # 80001848 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000264a:	70a2                	ld	ra,40(sp)
    8000264c:	7402                	ld	s0,32(sp)
    8000264e:	64e2                	ld	s1,24(sp)
    80002650:	6942                	ld	s2,16(sp)
    80002652:	69a2                	ld	s3,8(sp)
    80002654:	6a02                	ld	s4,0(sp)
    80002656:	6145                	addi	sp,sp,48
    80002658:	8082                	ret
    memmove(dst, (char*)src, len);
    8000265a:	000a061b          	sext.w	a2,s4
    8000265e:	85ce                	mv	a1,s3
    80002660:	854a                	mv	a0,s2
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	802080e7          	jalr	-2046(ra) # 80000e64 <memmove>
    return 0;
    8000266a:	8526                	mv	a0,s1
    8000266c:	bff9                	j	8000264a <either_copyin+0x32>

000000008000266e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000266e:	715d                	addi	sp,sp,-80
    80002670:	e486                	sd	ra,72(sp)
    80002672:	e0a2                	sd	s0,64(sp)
    80002674:	fc26                	sd	s1,56(sp)
    80002676:	f84a                	sd	s2,48(sp)
    80002678:	f44e                	sd	s3,40(sp)
    8000267a:	f052                	sd	s4,32(sp)
    8000267c:	ec56                	sd	s5,24(sp)
    8000267e:	e85a                	sd	s6,16(sp)
    80002680:	e45e                	sd	s7,8(sp)
    80002682:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	a7c50513          	addi	a0,a0,-1412 # 80008100 <digits+0xc0>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	efe080e7          	jalr	-258(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002694:	0022f497          	auipc	s1,0x22f
    80002698:	d4c48493          	addi	s1,s1,-692 # 802313e0 <proc+0x160>
    8000269c:	00236917          	auipc	s2,0x236
    800026a0:	34490913          	addi	s2,s2,836 # 802389e0 <ptable+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026a6:	00006997          	auipc	s3,0x6
    800026aa:	c1298993          	addi	s3,s3,-1006 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    800026ae:	00006a97          	auipc	s5,0x6
    800026b2:	c12a8a93          	addi	s5,s5,-1006 # 800082c0 <digits+0x280>
    printf("\n");
    800026b6:	00006a17          	auipc	s4,0x6
    800026ba:	a4aa0a13          	addi	s4,s4,-1462 # 80008100 <digits+0xc0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026be:	00006b97          	auipc	s7,0x6
    800026c2:	cc2b8b93          	addi	s7,s7,-830 # 80008380 <states.0>
    800026c6:	a00d                	j	800026e8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026c8:	ed06a583          	lw	a1,-304(a3)
    800026cc:	8556                	mv	a0,s5
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	ebc080e7          	jalr	-324(ra) # 8000058a <printf>
    printf("\n");
    800026d6:	8552                	mv	a0,s4
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	eb2080e7          	jalr	-334(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e0:	1d848493          	addi	s1,s1,472
    800026e4:	03248263          	beq	s1,s2,80002708 <procdump+0x9a>
    if(p->state == UNUSED)
    800026e8:	86a6                	mv	a3,s1
    800026ea:	eb84a783          	lw	a5,-328(s1)
    800026ee:	dbed                	beqz	a5,800026e0 <procdump+0x72>
      state = "???";
    800026f0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f2:	fcfb6be3          	bltu	s6,a5,800026c8 <procdump+0x5a>
    800026f6:	02079713          	slli	a4,a5,0x20
    800026fa:	01d75793          	srli	a5,a4,0x1d
    800026fe:	97de                	add	a5,a5,s7
    80002700:	6390                	ld	a2,0(a5)
    80002702:	f279                	bnez	a2,800026c8 <procdump+0x5a>
      state = "???";
    80002704:	864e                	mv	a2,s3
    80002706:	b7c9                	j	800026c8 <procdump+0x5a>
  }
}
    80002708:	60a6                	ld	ra,72(sp)
    8000270a:	6406                	ld	s0,64(sp)
    8000270c:	74e2                	ld	s1,56(sp)
    8000270e:	7942                	ld	s2,48(sp)
    80002710:	79a2                	ld	s3,40(sp)
    80002712:	7a02                	ld	s4,32(sp)
    80002714:	6ae2                	ld	s5,24(sp)
    80002716:	6b42                	ld	s6,16(sp)
    80002718:	6ba2                	ld	s7,8(sp)
    8000271a:	6161                	addi	sp,sp,80
    8000271c:	8082                	ret

000000008000271e <cps>:

int
cps()
{
    8000271e:	715d                	addi	sp,sp,-80
    80002720:	e486                	sd	ra,72(sp)
    80002722:	e0a2                	sd	s0,64(sp)
    80002724:	fc26                	sd	s1,56(sp)
    80002726:	f84a                	sd	s2,48(sp)
    80002728:	f44e                	sd	s3,40(sp)
    8000272a:	f052                	sd	s4,32(sp)
    8000272c:	ec56                	sd	s5,24(sp)
    8000272e:	e85a                	sd	s6,16(sp)
    80002730:	e45e                	sd	s7,8(sp)
    80002732:	e062                	sd	s8,0(sp)
    80002734:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002736:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000273a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000273c:	10079073          	csrw	sstatus,a5
//Enables interrupts on this processor.
// sti();
intr_off();

//Loop over process table looking for process with pid.
acquire(&ptable.lock);
    80002740:	00236517          	auipc	a0,0x236
    80002744:	14050513          	addi	a0,a0,320 # 80238880 <ptable>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	5c4080e7          	jalr	1476(ra) # 80000d0c <acquire>
printf("name \t pid \t state \t priority \n");
    80002750:	00006517          	auipc	a0,0x6
    80002754:	b8050513          	addi	a0,a0,-1152 # 800082d0 <digits+0x290>
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	e32080e7          	jalr	-462(ra) # 8000058a <printf>
for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    80002760:	00236497          	auipc	s1,0x236
    80002764:	29848493          	addi	s1,s1,664 # 802389f8 <ptable+0x178>
    80002768:	0023e997          	auipc	s3,0x23e
    8000276c:	89098993          	addi	s3,s3,-1904 # 8023fff8 <bcache+0x148>
  if(p->state == SLEEPING)
    80002770:	4909                	li	s2,2
	  printf("%s \t %d \t SLEEPING \t %d \n ", p->name,p->pid,p->priority);
	else if(p->state == RUNNING)
    80002772:	4a11                	li	s4,4
 	  printf("%s \t %d \t RUNNING \t %d \n ", p->name,p->pid,p->priority);
	else if(p->state == RUNNABLE)
    80002774:	4a8d                	li	s5,3
 	  printf("%s \t %d \t RUNNABLE \t %d \n ", p->name,p->pid,p->priority);
    80002776:	00006c17          	auipc	s8,0x6
    8000277a:	bbac0c13          	addi	s8,s8,-1094 # 80008330 <digits+0x2f0>
 	  printf("%s \t %d \t RUNNING \t %d \n ", p->name,p->pid,p->priority);
    8000277e:	00006b97          	auipc	s7,0x6
    80002782:	b92b8b93          	addi	s7,s7,-1134 # 80008310 <digits+0x2d0>
	  printf("%s \t %d \t SLEEPING \t %d \n ", p->name,p->pid,p->priority);
    80002786:	00006b17          	auipc	s6,0x6
    8000278a:	b6ab0b13          	addi	s6,s6,-1174 # 800082f0 <digits+0x2b0>
    8000278e:	a831                	j	800027aa <cps+0x8c>
    80002790:	ed44a683          	lw	a3,-300(s1)
    80002794:	ed04a603          	lw	a2,-304(s1)
    80002798:	855a                	mv	a0,s6
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	df0080e7          	jalr	-528(ra) # 8000058a <printf>
for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    800027a2:	1d848493          	addi	s1,s1,472
    800027a6:	03348f63          	beq	s1,s3,800027e4 <cps+0xc6>
  if(p->state == SLEEPING)
    800027aa:	85a6                	mv	a1,s1
    800027ac:	eb84a783          	lw	a5,-328(s1)
    800027b0:	ff2780e3          	beq	a5,s2,80002790 <cps+0x72>
	else if(p->state == RUNNING)
    800027b4:	01478e63          	beq	a5,s4,800027d0 <cps+0xb2>
	else if(p->state == RUNNABLE)
    800027b8:	ff5795e3          	bne	a5,s5,800027a2 <cps+0x84>
 	  printf("%s \t %d \t RUNNABLE \t %d \n ", p->name,p->pid,p->priority);
    800027bc:	ed44a683          	lw	a3,-300(s1)
    800027c0:	ed04a603          	lw	a2,-304(s1)
    800027c4:	8562                	mv	a0,s8
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	dc4080e7          	jalr	-572(ra) # 8000058a <printf>
    800027ce:	bfd1                	j	800027a2 <cps+0x84>
 	  printf("%s \t %d \t RUNNING \t %d \n ", p->name,p->pid,p->priority);
    800027d0:	ed44a683          	lw	a3,-300(s1)
    800027d4:	ed04a603          	lw	a2,-304(s1)
    800027d8:	855e                	mv	a0,s7
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	db0080e7          	jalr	-592(ra) # 8000058a <printf>
    800027e2:	b7c1                	j	800027a2 <cps+0x84>
}
release(&ptable.lock);
    800027e4:	00236517          	auipc	a0,0x236
    800027e8:	09c50513          	addi	a0,a0,156 # 80238880 <ptable>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	5d4080e7          	jalr	1492(ra) # 80000dc0 <release>
return 22;
}
    800027f4:	4559                	li	a0,22
    800027f6:	60a6                	ld	ra,72(sp)
    800027f8:	6406                	ld	s0,64(sp)
    800027fa:	74e2                	ld	s1,56(sp)
    800027fc:	7942                	ld	s2,48(sp)
    800027fe:	79a2                	ld	s3,40(sp)
    80002800:	7a02                	ld	s4,32(sp)
    80002802:	6ae2                	ld	s5,24(sp)
    80002804:	6b42                	ld	s6,16(sp)
    80002806:	6ba2                	ld	s7,8(sp)
    80002808:	6c02                	ld	s8,0(sp)
    8000280a:	6161                	addi	sp,sp,80
    8000280c:	8082                	ret

000000008000280e <chpr>:

int 
chpr(int pid, int priority)
{
    8000280e:	1101                	addi	sp,sp,-32
    80002810:	ec06                	sd	ra,24(sp)
    80002812:	e822                	sd	s0,16(sp)
    80002814:	e426                	sd	s1,8(sp)
    80002816:	e04a                	sd	s2,0(sp)
    80002818:	1000                	addi	s0,sp,32
    8000281a:	84aa                	mv	s1,a0
    8000281c:	892e                	mv	s2,a1
	struct proc *p;
	acquire(&ptable.lock);
    8000281e:	00236517          	auipc	a0,0x236
    80002822:	06250513          	addi	a0,a0,98 # 80238880 <ptable>
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	4e6080e7          	jalr	1254(ra) # 80000d0c <acquire>
	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    8000282e:	00236797          	auipc	a5,0x236
    80002832:	06a78793          	addi	a5,a5,106 # 80238898 <ptable+0x18>
    80002836:	0023d697          	auipc	a3,0x23d
    8000283a:	66268693          	addi	a3,a3,1634 # 8023fe98 <tickslock>
	  if(p->pid == pid){
    8000283e:	5b98                	lw	a4,48(a5)
    80002840:	00970763          	beq	a4,s1,8000284e <chpr+0x40>
	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    80002844:	1d878793          	addi	a5,a5,472
    80002848:	fed79be3          	bne	a5,a3,8000283e <chpr+0x30>
    8000284c:	a019                	j	80002852 <chpr+0x44>
			p->priority = priority;
    8000284e:	0327aa23          	sw	s2,52(a5)
			break;
		}
	}
	release(&ptable.lock);
    80002852:	00236517          	auipc	a0,0x236
    80002856:	02e50513          	addi	a0,a0,46 # 80238880 <ptable>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	566080e7          	jalr	1382(ra) # 80000dc0 <release>
	return pid;
}
    80002862:	8526                	mv	a0,s1
    80002864:	60e2                	ld	ra,24(sp)
    80002866:	6442                	ld	s0,16(sp)
    80002868:	64a2                	ld	s1,8(sp)
    8000286a:	6902                	ld	s2,0(sp)
    8000286c:	6105                	addi	sp,sp,32
    8000286e:	8082                	ret

0000000080002870 <swtch>:
    80002870:	00153023          	sd	ra,0(a0)
    80002874:	00253423          	sd	sp,8(a0)
    80002878:	e900                	sd	s0,16(a0)
    8000287a:	ed04                	sd	s1,24(a0)
    8000287c:	03253023          	sd	s2,32(a0)
    80002880:	03353423          	sd	s3,40(a0)
    80002884:	03453823          	sd	s4,48(a0)
    80002888:	03553c23          	sd	s5,56(a0)
    8000288c:	05653023          	sd	s6,64(a0)
    80002890:	05753423          	sd	s7,72(a0)
    80002894:	05853823          	sd	s8,80(a0)
    80002898:	05953c23          	sd	s9,88(a0)
    8000289c:	07a53023          	sd	s10,96(a0)
    800028a0:	07b53423          	sd	s11,104(a0)
    800028a4:	0005b083          	ld	ra,0(a1)
    800028a8:	0085b103          	ld	sp,8(a1)
    800028ac:	6980                	ld	s0,16(a1)
    800028ae:	6d84                	ld	s1,24(a1)
    800028b0:	0205b903          	ld	s2,32(a1)
    800028b4:	0285b983          	ld	s3,40(a1)
    800028b8:	0305ba03          	ld	s4,48(a1)
    800028bc:	0385ba83          	ld	s5,56(a1)
    800028c0:	0405bb03          	ld	s6,64(a1)
    800028c4:	0485bb83          	ld	s7,72(a1)
    800028c8:	0505bc03          	ld	s8,80(a1)
    800028cc:	0585bc83          	ld	s9,88(a1)
    800028d0:	0605bd03          	ld	s10,96(a1)
    800028d4:	0685bd83          	ld	s11,104(a1)
    800028d8:	8082                	ret

00000000800028da <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800028da:	1141                	addi	sp,sp,-16
    800028dc:	e406                	sd	ra,8(sp)
    800028de:	e022                	sd	s0,0(sp)
    800028e0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028e2:	00006597          	auipc	a1,0x6
    800028e6:	ace58593          	addi	a1,a1,-1330 # 800083b0 <states.0+0x30>
    800028ea:	0023d517          	auipc	a0,0x23d
    800028ee:	5ae50513          	addi	a0,a0,1454 # 8023fe98 <tickslock>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	38a080e7          	jalr	906(ra) # 80000c7c <initlock>
}
    800028fa:	60a2                	ld	ra,8(sp)
    800028fc:	6402                	ld	s0,0(sp)
    800028fe:	0141                	addi	sp,sp,16
    80002900:	8082                	ret

0000000080002902 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002902:	1141                	addi	sp,sp,-16
    80002904:	e422                	sd	s0,8(sp)
    80002906:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002908:	00003797          	auipc	a5,0x3
    8000290c:	70878793          	addi	a5,a5,1800 # 80006010 <kernelvec>
    80002910:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002914:	6422                	ld	s0,8(sp)
    80002916:	0141                	addi	sp,sp,16
    80002918:	8082                	ret

000000008000291a <cowfault>:

int cowfault(pagetable_t pagetable, uint64 va)
{
  if (va >= MAXVA)
    8000291a:	57fd                	li	a5,-1
    8000291c:	83e9                	srli	a5,a5,0x1a
    8000291e:	06b7e863          	bltu	a5,a1,8000298e <cowfault+0x74>
{
    80002922:	7179                	addi	sp,sp,-48
    80002924:	f406                	sd	ra,40(sp)
    80002926:	f022                	sd	s0,32(sp)
    80002928:	ec26                	sd	s1,24(sp)
    8000292a:	e84a                	sd	s2,16(sp)
    8000292c:	e44e                	sd	s3,8(sp)
    8000292e:	1800                	addi	s0,sp,48
    return -1;
  pte_t *pte = walk(pagetable, va, 0);
    80002930:	4601                	li	a2,0
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	7ba080e7          	jalr	1978(ra) # 800010ec <walk>
    8000293a:	89aa                	mv	s3,a0
  if (pte == 0)
    8000293c:	c939                	beqz	a0,80002992 <cowfault+0x78>
    return -1;
  if ((*pte & PTE_U) == 0 || (*pte & PTE_V) == 0)
    8000293e:	610c                	ld	a1,0(a0)
    80002940:	0115f713          	andi	a4,a1,17
    80002944:	47c5                	li	a5,17
    80002946:	04f71863          	bne	a4,a5,80002996 <cowfault+0x7c>
    return -1;
  uint64 pa1 = PTE2PA(*pte);
    8000294a:	81a9                	srli	a1,a1,0xa
    8000294c:	00c59913          	slli	s2,a1,0xc
  uint64 pa2 = (uint64)kalloc();
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	294080e7          	jalr	660(ra) # 80000be4 <kalloc>
    80002958:	84aa                	mv	s1,a0
  if (pa2 == 0)
    8000295a:	c121                	beqz	a0,8000299a <cowfault+0x80>
  {
    // panic("cow panic kalloc");
    return -1;
  }

  memmove((void *)pa2, (void *)pa1, PGSIZE);
    8000295c:	6605                	lui	a2,0x1
    8000295e:	85ca                	mv	a1,s2
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	504080e7          	jalr	1284(ra) # 80000e64 <memmove>
  *pte = PA2PTE(pa2) | PTE_U | PTE_V | PTE_W | PTE_X | PTE_R;
    80002968:	80b1                	srli	s1,s1,0xc
    8000296a:	04aa                	slli	s1,s1,0xa
    8000296c:	01f4e493          	ori	s1,s1,31
    80002970:	0099b023          	sd	s1,0(s3)
  kfree((void *)pa1);
    80002974:	854a                	mv	a0,s2
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	0ea080e7          	jalr	234(ra) # 80000a60 <kfree>
  return 0;
    8000297e:	4501                	li	a0,0
}
    80002980:	70a2                	ld	ra,40(sp)
    80002982:	7402                	ld	s0,32(sp)
    80002984:	64e2                	ld	s1,24(sp)
    80002986:	6942                	ld	s2,16(sp)
    80002988:	69a2                	ld	s3,8(sp)
    8000298a:	6145                	addi	sp,sp,48
    8000298c:	8082                	ret
    return -1;
    8000298e:	557d                	li	a0,-1
}
    80002990:	8082                	ret
    return -1;
    80002992:	557d                	li	a0,-1
    80002994:	b7f5                	j	80002980 <cowfault+0x66>
    return -1;
    80002996:	557d                	li	a0,-1
    80002998:	b7e5                	j	80002980 <cowfault+0x66>
    return -1;
    8000299a:	557d                	li	a0,-1
    8000299c:	b7d5                	j	80002980 <cowfault+0x66>

000000008000299e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000299e:	1141                	addi	sp,sp,-16
    800029a0:	e406                	sd	ra,8(sp)
    800029a2:	e022                	sd	s0,0(sp)
    800029a4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	156080e7          	jalr	342(ra) # 80001afc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029b8:	00004697          	auipc	a3,0x4
    800029bc:	64868693          	addi	a3,a3,1608 # 80007000 <_trampoline>
    800029c0:	00004717          	auipc	a4,0x4
    800029c4:	64070713          	addi	a4,a4,1600 # 80007000 <_trampoline>
    800029c8:	8f15                	sub	a4,a4,a3
    800029ca:	040007b7          	lui	a5,0x4000
    800029ce:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029d0:	07b2                	slli	a5,a5,0xc
    800029d2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d4:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029d8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029da:	18002673          	csrr	a2,satp
    800029de:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e0:	7130                	ld	a2,96(a0)
    800029e2:	6538                	ld	a4,72(a0)
    800029e4:	6585                	lui	a1,0x1
    800029e6:	972e                	add	a4,a4,a1
    800029e8:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ea:	7138                	ld	a4,96(a0)
    800029ec:	00000617          	auipc	a2,0x0
    800029f0:	13060613          	addi	a2,a2,304 # 80002b1c <usertrap>
    800029f4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800029f6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029f8:	8612                	mv	a2,tp
    800029fa:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a00:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a04:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a08:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a0c:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a0e:	6f18                	ld	a4,24(a4)
    80002a10:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a14:	6d28                	ld	a0,88(a0)
    80002a16:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a18:	00004717          	auipc	a4,0x4
    80002a1c:	68470713          	addi	a4,a4,1668 # 8000709c <userret>
    80002a20:	8f15                	sub	a4,a4,a3
    80002a22:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a24:	577d                	li	a4,-1
    80002a26:	177e                	slli	a4,a4,0x3f
    80002a28:	8d59                	or	a0,a0,a4
    80002a2a:	9782                	jalr	a5
}
    80002a2c:	60a2                	ld	ra,8(sp)
    80002a2e:	6402                	ld	s0,0(sp)
    80002a30:	0141                	addi	sp,sp,16
    80002a32:	8082                	ret

0000000080002a34 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a34:	1101                	addi	sp,sp,-32
    80002a36:	ec06                	sd	ra,24(sp)
    80002a38:	e822                	sd	s0,16(sp)
    80002a3a:	e426                	sd	s1,8(sp)
    80002a3c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a3e:	0023d497          	auipc	s1,0x23d
    80002a42:	45a48493          	addi	s1,s1,1114 # 8023fe98 <tickslock>
    80002a46:	8526                	mv	a0,s1
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	2c4080e7          	jalr	708(ra) # 80000d0c <acquire>
  ticks++;
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	19050513          	addi	a0,a0,400 # 80008be0 <ticks>
    80002a58:	411c                	lw	a5,0(a0)
    80002a5a:	2785                	addiw	a5,a5,1
    80002a5c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	7c0080e7          	jalr	1984(ra) # 8000221e <wakeup>
  release(&tickslock);
    80002a66:	8526                	mv	a0,s1
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	358080e7          	jalr	856(ra) # 80000dc0 <release>
}
    80002a70:	60e2                	ld	ra,24(sp)
    80002a72:	6442                	ld	s0,16(sp)
    80002a74:	64a2                	ld	s1,8(sp)
    80002a76:	6105                	addi	sp,sp,32
    80002a78:	8082                	ret

0000000080002a7a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002a7a:	1101                	addi	sp,sp,-32
    80002a7c:	ec06                	sd	ra,24(sp)
    80002a7e:	e822                	sd	s0,16(sp)
    80002a80:	e426                	sd	s1,8(sp)
    80002a82:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a84:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a88:	00074d63          	bltz	a4,80002aa2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a8c:	57fd                	li	a5,-1
    80002a8e:	17fe                	slli	a5,a5,0x3f
    80002a90:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a92:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a94:	06f70363          	beq	a4,a5,80002afa <devintr+0x80>
  }
}
    80002a98:	60e2                	ld	ra,24(sp)
    80002a9a:	6442                	ld	s0,16(sp)
    80002a9c:	64a2                	ld	s1,8(sp)
    80002a9e:	6105                	addi	sp,sp,32
    80002aa0:	8082                	ret
      (scause & 0xff) == 9)
    80002aa2:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002aa6:	46a5                	li	a3,9
    80002aa8:	fed792e3          	bne	a5,a3,80002a8c <devintr+0x12>
    int irq = plic_claim();
    80002aac:	00003097          	auipc	ra,0x3
    80002ab0:	66c080e7          	jalr	1644(ra) # 80006118 <plic_claim>
    80002ab4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ab6:	47a9                	li	a5,10
    80002ab8:	02f50763          	beq	a0,a5,80002ae6 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002abc:	4785                	li	a5,1
    80002abe:	02f50963          	beq	a0,a5,80002af0 <devintr+0x76>
    return 1;
    80002ac2:	4505                	li	a0,1
    else if (irq)
    80002ac4:	d8f1                	beqz	s1,80002a98 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ac6:	85a6                	mv	a1,s1
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	8f050513          	addi	a0,a0,-1808 # 800083b8 <states.0+0x38>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	aba080e7          	jalr	-1350(ra) # 8000058a <printf>
      plic_complete(irq);
    80002ad8:	8526                	mv	a0,s1
    80002ada:	00003097          	auipc	ra,0x3
    80002ade:	662080e7          	jalr	1634(ra) # 8000613c <plic_complete>
    return 1;
    80002ae2:	4505                	li	a0,1
    80002ae4:	bf55                	j	80002a98 <devintr+0x1e>
      uartintr();
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	eb2080e7          	jalr	-334(ra) # 80000998 <uartintr>
    80002aee:	b7ed                	j	80002ad8 <devintr+0x5e>
      virtio_disk_intr();
    80002af0:	00004097          	auipc	ra,0x4
    80002af4:	b14080e7          	jalr	-1260(ra) # 80006604 <virtio_disk_intr>
    80002af8:	b7c5                	j	80002ad8 <devintr+0x5e>
    if (cpuid() == 0)
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	fd6080e7          	jalr	-42(ra) # 80001ad0 <cpuid>
    80002b02:	c901                	beqz	a0,80002b12 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b04:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b08:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b0a:	14479073          	csrw	sip,a5
    return 2;
    80002b0e:	4509                	li	a0,2
    80002b10:	b761                	j	80002a98 <devintr+0x1e>
      clockintr();
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	f22080e7          	jalr	-222(ra) # 80002a34 <clockintr>
    80002b1a:	b7ed                	j	80002b04 <devintr+0x8a>

0000000080002b1c <usertrap>:
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b28:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b2c:	1007f793          	andi	a5,a5,256
    80002b30:	e7b9                	bnez	a5,80002b7e <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b32:	00003797          	auipc	a5,0x3
    80002b36:	4de78793          	addi	a5,a5,1246 # 80006010 <kernelvec>
    80002b3a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	fbe080e7          	jalr	-66(ra) # 80001afc <myproc>
    80002b46:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b48:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b4a:	14102773          	csrr	a4,sepc
    80002b4e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b50:	14202773          	csrr	a4,scause
  if (r_scause() == 15)
    80002b54:	47bd                	li	a5,15
    80002b56:	02f70c63          	beq	a4,a5,80002b8e <usertrap+0x72>
    80002b5a:	14202773          	csrr	a4,scause
  else if (r_scause() == 8)
    80002b5e:	47a1                	li	a5,8
    80002b60:	04f70363          	beq	a4,a5,80002ba6 <usertrap+0x8a>
  else if ((which_dev = devintr()) != 0)
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	f16080e7          	jalr	-234(ra) # 80002a7a <devintr>
    80002b6c:	892a                	mv	s2,a0
    80002b6e:	cd41                	beqz	a0,80002c06 <usertrap+0xea>
  if (killed(p))
    80002b70:	8526                	mv	a0,s1
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	8f0080e7          	jalr	-1808(ra) # 80002462 <killed>
    80002b7a:	c969                	beqz	a0,80002c4c <usertrap+0x130>
    80002b7c:	a0d9                	j	80002c42 <usertrap+0x126>
    panic("usertrap: not from user mode");
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	85a50513          	addi	a0,a0,-1958 # 800083d8 <states.0+0x58>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	9ba080e7          	jalr	-1606(ra) # 80000540 <panic>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8e:	143025f3          	csrr	a1,stval
    if ((cowfault(p->pagetable, r_stval())) < 0)
    80002b92:	6d28                	ld	a0,88(a0)
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	d86080e7          	jalr	-634(ra) # 8000291a <cowfault>
    80002b9c:	02055863          	bgez	a0,80002bcc <usertrap+0xb0>
      p->killed = 1;
    80002ba0:	4785                	li	a5,1
    80002ba2:	d49c                	sw	a5,40(s1)
    80002ba4:	a025                	j	80002bcc <usertrap+0xb0>
    if (killed(p))
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	8bc080e7          	jalr	-1860(ra) # 80002462 <killed>
    80002bae:	e531                	bnez	a0,80002bfa <usertrap+0xde>
    p->trapframe->epc += 4;
    80002bb0:	70b8                	ld	a4,96(s1)
    80002bb2:	6f1c                	ld	a5,24(a4)
    80002bb4:	0791                	addi	a5,a5,4
    80002bb6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc0:	10079073          	csrw	sstatus,a5
    syscall();
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	328080e7          	jalr	808(ra) # 80002eec <syscall>
  if (killed(p))
    80002bcc:	8526                	mv	a0,s1
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	894080e7          	jalr	-1900(ra) # 80002462 <killed>
    80002bd6:	e52d                	bnez	a0,80002c40 <usertrap+0x124>
  usertrapret();
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	dc6080e7          	jalr	-570(ra) # 8000299e <usertrapret>
  if((which_dev = devintr()) != 0){
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	e9a080e7          	jalr	-358(ra) # 80002a7a <devintr>
  if (which_dev == 2 && p->alarm_on == 0) 
    80002be8:	4789                	li	a5,2
    80002bea:	06f50963          	beq	a0,a5,80002c5c <usertrap+0x140>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret
      exit(-1);
    80002bfa:	557d                	li	a0,-1
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	6f2080e7          	jalr	1778(ra) # 800022ee <exit>
    80002c04:	b775                	j	80002bb0 <usertrap+0x94>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c06:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c0a:	5890                	lw	a2,48(s1)
    80002c0c:	00005517          	auipc	a0,0x5
    80002c10:	7ec50513          	addi	a0,a0,2028 # 800083f8 <states.0+0x78>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	976080e7          	jalr	-1674(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c20:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c24:	00006517          	auipc	a0,0x6
    80002c28:	80450513          	addi	a0,a0,-2044 # 80008428 <states.0+0xa8>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	95e080e7          	jalr	-1698(ra) # 8000058a <printf>
    setkilled(p);
    80002c34:	8526                	mv	a0,s1
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	800080e7          	jalr	-2048(ra) # 80002436 <setkilled>
    80002c3e:	b779                	j	80002bcc <usertrap+0xb0>
  if (killed(p))
    80002c40:	4901                	li	s2,0
    exit(-1);
    80002c42:	557d                	li	a0,-1
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	6aa080e7          	jalr	1706(ra) # 800022ee <exit>
  if (which_dev == 2)
    80002c4c:	4789                	li	a5,2
    80002c4e:	f8f915e3          	bne	s2,a5,80002bd8 <usertrap+0xbc>
    yield();
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	52c080e7          	jalr	1324(ra) # 8000217e <yield>
    80002c5a:	bfbd                	j	80002bd8 <usertrap+0xbc>
  if (which_dev == 2 && p->alarm_on == 0) 
    80002c5c:	1c84a783          	lw	a5,456(s1)
    80002c60:	f7d9                	bnez	a5,80002bee <usertrap+0xd2>
    p->alarm_on = 1;
    80002c62:	4785                	li	a5,1
    80002c64:	1cf4a423          	sw	a5,456(s1)
    struct trapframe *tf = kalloc();
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	f7c080e7          	jalr	-132(ra) # 80000be4 <kalloc>
    80002c70:	892a                	mv	s2,a0
    memmove(tf, p->trapframe, PGSIZE);
    80002c72:	6605                	lui	a2,0x1
    80002c74:	70ac                	ld	a1,96(s1)
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	1ee080e7          	jalr	494(ra) # 80000e64 <memmove>
    p->alarm_trap = tf;
    80002c7e:	1d24b823          	sd	s2,464(s1)
    p->curticks++;
    80002c82:	1bc4a783          	lw	a5,444(s1)
    80002c86:	2785                	addiw	a5,a5,1
    80002c88:	0007871b          	sext.w	a4,a5
    80002c8c:	1af4ae23          	sw	a5,444(s1)
    if (p->curticks >= p->ticks)
    80002c90:	1b84a783          	lw	a5,440(s1)
    80002c94:	f4f74de3          	blt	a4,a5,80002bee <usertrap+0xd2>
      p->trapframe->epc = p->alarmhandler;
    80002c98:	70bc                	ld	a5,96(s1)
    80002c9a:	1c04b703          	ld	a4,448(s1)
    80002c9e:	ef98                	sd	a4,24(a5)
}
    80002ca0:	b7b9                	j	80002bee <usertrap+0xd2>

0000000080002ca2 <kerneltrap>:
{
    80002ca2:	7179                	addi	sp,sp,-48
    80002ca4:	f406                	sd	ra,40(sp)
    80002ca6:	f022                	sd	s0,32(sp)
    80002ca8:	ec26                	sd	s1,24(sp)
    80002caa:	e84a                	sd	s2,16(sp)
    80002cac:	e44e                	sd	s3,8(sp)
    80002cae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb8:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002cbc:	1004f793          	andi	a5,s1,256
    80002cc0:	cb85                	beqz	a5,80002cf0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cc6:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002cc8:	ef85                	bnez	a5,80002d00 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	db0080e7          	jalr	-592(ra) # 80002a7a <devintr>
    80002cd2:	cd1d                	beqz	a0,80002d10 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd4:	4789                	li	a5,2
    80002cd6:	06f50a63          	beq	a0,a5,80002d4a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cda:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cde:	10049073          	csrw	sstatus,s1
}
    80002ce2:	70a2                	ld	ra,40(sp)
    80002ce4:	7402                	ld	s0,32(sp)
    80002ce6:	64e2                	ld	s1,24(sp)
    80002ce8:	6942                	ld	s2,16(sp)
    80002cea:	69a2                	ld	s3,8(sp)
    80002cec:	6145                	addi	sp,sp,48
    80002cee:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	75850513          	addi	a0,a0,1880 # 80008448 <states.0+0xc8>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	848080e7          	jalr	-1976(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	77050513          	addi	a0,a0,1904 # 80008470 <states.0+0xf0>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	838080e7          	jalr	-1992(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002d10:	85ce                	mv	a1,s3
    80002d12:	00005517          	auipc	a0,0x5
    80002d16:	77e50513          	addi	a0,a0,1918 # 80008490 <states.0+0x110>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	870080e7          	jalr	-1936(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d22:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d26:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d2a:	00005517          	auipc	a0,0x5
    80002d2e:	77650513          	addi	a0,a0,1910 # 800084a0 <states.0+0x120>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	858080e7          	jalr	-1960(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002d3a:	00005517          	auipc	a0,0x5
    80002d3e:	77e50513          	addi	a0,a0,1918 # 800084b8 <states.0+0x138>
    80002d42:	ffffd097          	auipc	ra,0xffffd
    80002d46:	7fe080e7          	jalr	2046(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	db2080e7          	jalr	-590(ra) # 80001afc <myproc>
    80002d52:	d541                	beqz	a0,80002cda <kerneltrap+0x38>
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	da8080e7          	jalr	-600(ra) # 80001afc <myproc>
    80002d5c:	4d18                	lw	a4,24(a0)
    80002d5e:	4791                	li	a5,4
    80002d60:	f6f71de3          	bne	a4,a5,80002cda <kerneltrap+0x38>
    yield();
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	41a080e7          	jalr	1050(ra) # 8000217e <yield>
    80002d6c:	b7bd                	j	80002cda <kerneltrap+0x38>

0000000080002d6e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d6e:	1101                	addi	sp,sp,-32
    80002d70:	ec06                	sd	ra,24(sp)
    80002d72:	e822                	sd	s0,16(sp)
    80002d74:	e426                	sd	s1,8(sp)
    80002d76:	1000                	addi	s0,sp,32
    80002d78:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	d82080e7          	jalr	-638(ra) # 80001afc <myproc>
  switch (n) {
    80002d82:	4795                	li	a5,5
    80002d84:	0497e163          	bltu	a5,s1,80002dc6 <argraw+0x58>
    80002d88:	048a                	slli	s1,s1,0x2
    80002d8a:	00006717          	auipc	a4,0x6
    80002d8e:	84e70713          	addi	a4,a4,-1970 # 800085d8 <states.0+0x258>
    80002d92:	94ba                	add	s1,s1,a4
    80002d94:	409c                	lw	a5,0(s1)
    80002d96:	97ba                	add	a5,a5,a4
    80002d98:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d9a:	713c                	ld	a5,96(a0)
    80002d9c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret
    return p->trapframe->a1;
    80002da8:	713c                	ld	a5,96(a0)
    80002daa:	7fa8                	ld	a0,120(a5)
    80002dac:	bfcd                	j	80002d9e <argraw+0x30>
    return p->trapframe->a2;
    80002dae:	713c                	ld	a5,96(a0)
    80002db0:	63c8                	ld	a0,128(a5)
    80002db2:	b7f5                	j	80002d9e <argraw+0x30>
    return p->trapframe->a3;
    80002db4:	713c                	ld	a5,96(a0)
    80002db6:	67c8                	ld	a0,136(a5)
    80002db8:	b7dd                	j	80002d9e <argraw+0x30>
    return p->trapframe->a4;
    80002dba:	713c                	ld	a5,96(a0)
    80002dbc:	6bc8                	ld	a0,144(a5)
    80002dbe:	b7c5                	j	80002d9e <argraw+0x30>
    return p->trapframe->a5;
    80002dc0:	713c                	ld	a5,96(a0)
    80002dc2:	6fc8                	ld	a0,152(a5)
    80002dc4:	bfe9                	j	80002d9e <argraw+0x30>
  panic("argraw");
    80002dc6:	00005517          	auipc	a0,0x5
    80002dca:	70250513          	addi	a0,a0,1794 # 800084c8 <states.0+0x148>
    80002dce:	ffffd097          	auipc	ra,0xffffd
    80002dd2:	772080e7          	jalr	1906(ra) # 80000540 <panic>

0000000080002dd6 <fetchaddr>:
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	e426                	sd	s1,8(sp)
    80002dde:	e04a                	sd	s2,0(sp)
    80002de0:	1000                	addi	s0,sp,32
    80002de2:	84aa                	mv	s1,a0
    80002de4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	d16080e7          	jalr	-746(ra) # 80001afc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002dee:	693c                	ld	a5,80(a0)
    80002df0:	02f4f863          	bgeu	s1,a5,80002e20 <fetchaddr+0x4a>
    80002df4:	00848713          	addi	a4,s1,8
    80002df8:	02e7e663          	bltu	a5,a4,80002e24 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dfc:	46a1                	li	a3,8
    80002dfe:	8626                	mv	a2,s1
    80002e00:	85ca                	mv	a1,s2
    80002e02:	6d28                	ld	a0,88(a0)
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	a44080e7          	jalr	-1468(ra) # 80001848 <copyin>
    80002e0c:	00a03533          	snez	a0,a0
    80002e10:	40a00533          	neg	a0,a0
}
    80002e14:	60e2                	ld	ra,24(sp)
    80002e16:	6442                	ld	s0,16(sp)
    80002e18:	64a2                	ld	s1,8(sp)
    80002e1a:	6902                	ld	s2,0(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret
    return -1;
    80002e20:	557d                	li	a0,-1
    80002e22:	bfcd                	j	80002e14 <fetchaddr+0x3e>
    80002e24:	557d                	li	a0,-1
    80002e26:	b7fd                	j	80002e14 <fetchaddr+0x3e>

0000000080002e28 <fetchstr>:
{
    80002e28:	7179                	addi	sp,sp,-48
    80002e2a:	f406                	sd	ra,40(sp)
    80002e2c:	f022                	sd	s0,32(sp)
    80002e2e:	ec26                	sd	s1,24(sp)
    80002e30:	e84a                	sd	s2,16(sp)
    80002e32:	e44e                	sd	s3,8(sp)
    80002e34:	1800                	addi	s0,sp,48
    80002e36:	892a                	mv	s2,a0
    80002e38:	84ae                	mv	s1,a1
    80002e3a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	cc0080e7          	jalr	-832(ra) # 80001afc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002e44:	86ce                	mv	a3,s3
    80002e46:	864a                	mv	a2,s2
    80002e48:	85a6                	mv	a1,s1
    80002e4a:	6d28                	ld	a0,88(a0)
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	a8a080e7          	jalr	-1398(ra) # 800018d6 <copyinstr>
    80002e54:	00054e63          	bltz	a0,80002e70 <fetchstr+0x48>
  return strlen(buf);
    80002e58:	8526                	mv	a0,s1
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	12a080e7          	jalr	298(ra) # 80000f84 <strlen>
}
    80002e62:	70a2                	ld	ra,40(sp)
    80002e64:	7402                	ld	s0,32(sp)
    80002e66:	64e2                	ld	s1,24(sp)
    80002e68:	6942                	ld	s2,16(sp)
    80002e6a:	69a2                	ld	s3,8(sp)
    80002e6c:	6145                	addi	sp,sp,48
    80002e6e:	8082                	ret
    return -1;
    80002e70:	557d                	li	a0,-1
    80002e72:	bfc5                	j	80002e62 <fetchstr+0x3a>

0000000080002e74 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	e426                	sd	s1,8(sp)
    80002e7c:	1000                	addi	s0,sp,32
    80002e7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	eee080e7          	jalr	-274(ra) # 80002d6e <argraw>
    80002e88:	c088                	sw	a0,0(s1)
  // return 0;
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
    80002e9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	ece080e7          	jalr	-306(ra) # 80002d6e <argraw>
    80002ea8:	e088                	sd	a0,0(s1)
  // return 0;
}
    80002eaa:	60e2                	ld	ra,24(sp)
    80002eac:	6442                	ld	s0,16(sp)
    80002eae:	64a2                	ld	s1,8(sp)
    80002eb0:	6105                	addi	sp,sp,32
    80002eb2:	8082                	ret

0000000080002eb4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002eb4:	7179                	addi	sp,sp,-48
    80002eb6:	f406                	sd	ra,40(sp)
    80002eb8:	f022                	sd	s0,32(sp)
    80002eba:	ec26                	sd	s1,24(sp)
    80002ebc:	e84a                	sd	s2,16(sp)
    80002ebe:	1800                	addi	s0,sp,48
    80002ec0:	84ae                	mv	s1,a1
    80002ec2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ec4:	fd840593          	addi	a1,s0,-40
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	fcc080e7          	jalr	-52(ra) # 80002e94 <argaddr>
  return fetchstr(addr, buf, max);
    80002ed0:	864a                	mv	a2,s2
    80002ed2:	85a6                	mv	a1,s1
    80002ed4:	fd843503          	ld	a0,-40(s0)
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	f50080e7          	jalr	-176(ra) # 80002e28 <fetchstr>
}
    80002ee0:	70a2                	ld	ra,40(sp)
    80002ee2:	7402                	ld	s0,32(sp)
    80002ee4:	64e2                	ld	s1,24(sp)
    80002ee6:	6942                	ld	s2,16(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret

0000000080002eec <syscall>:
[SYS_trace] 1,
};

void
syscall(void)
{
    80002eec:	7139                	addi	sp,sp,-64
    80002eee:	fc06                	sd	ra,56(sp)
    80002ef0:	f822                	sd	s0,48(sp)
    80002ef2:	f426                	sd	s1,40(sp)
    80002ef4:	f04a                	sd	s2,32(sp)
    80002ef6:	ec4e                	sd	s3,24(sp)
    80002ef8:	e852                	sd	s4,16(sp)
    80002efa:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	c00080e7          	jalr	-1024(ra) # 80001afc <myproc>
    80002f04:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002f06:	7124                	ld	s1,96(a0)
    80002f08:	74dc                	ld	a5,168(s1)
    80002f0a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f0e:	37fd                	addiw	a5,a5,-1
    80002f10:	4765                	li	a4,25
    80002f12:	00f76e63          	bltu	a4,a5,80002f2e <syscall+0x42>
    80002f16:	00399713          	slli	a4,s3,0x3
    80002f1a:	00005797          	auipc	a5,0x5
    80002f1e:	6d678793          	addi	a5,a5,1750 # 800085f0 <syscalls>
    80002f22:	97ba                	add	a5,a5,a4
    80002f24:	639c                	ld	a5,0(a5)
    80002f26:	c781                	beqz	a5,80002f2e <syscall+0x42>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002f28:	9782                	jalr	a5
    80002f2a:	f8a8                	sd	a0,112(s1)
    80002f2c:	a015                	j	80002f50 <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f2e:	86ce                	mv	a3,s3
    80002f30:	16090613          	addi	a2,s2,352
    80002f34:	03092583          	lw	a1,48(s2)
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	59850513          	addi	a0,a0,1432 # 800084d0 <states.0+0x150>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	64a080e7          	jalr	1610(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f48:	06093783          	ld	a5,96(s2)
    80002f4c:	577d                	li	a4,-1
    80002f4e:	fbb8                	sd	a4,112(a5)
  }

  if (p->tracemask >> num) {
    80002f50:	03892783          	lw	a5,56(s2)
    80002f54:	4137d7bb          	sraw	a5,a5,s3
    80002f58:	eb89                	bnez	a5,80002f6a <syscall+0x7e>
        printf("%d ", ar);                         
      }
        
    printf(") -> %d\n", p->trapframe->a0);
}
    80002f5a:	70e2                	ld	ra,56(sp)
    80002f5c:	7442                	ld	s0,48(sp)
    80002f5e:	74a2                	ld	s1,40(sp)
    80002f60:	7902                	ld	s2,32(sp)
    80002f62:	69e2                	ld	s3,24(sp)
    80002f64:	6a42                	ld	s4,16(sp)
    80002f66:	6121                	addi	sp,sp,64
    80002f68:	8082                	ret
	  printf("%d: syscall %s (", 
    80002f6a:	00399713          	slli	a4,s3,0x3
    80002f6e:	00005797          	auipc	a5,0x5
    80002f72:	68278793          	addi	a5,a5,1666 # 800085f0 <syscalls>
    80002f76:	97ba                	add	a5,a5,a4
    80002f78:	6ff0                	ld	a2,216(a5)
    80002f7a:	03092583          	lw	a1,48(s2)
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	57250513          	addi	a0,a0,1394 # 800084f0 <states.0+0x170>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	604080e7          	jalr	1540(ra) # 8000058a <printf>
      for(int i = 0; i<syscallNos[num]; i++)
    80002f8e:	00299713          	slli	a4,s3,0x2
    80002f92:	00006797          	auipc	a5,0x6
    80002f96:	b9678793          	addi	a5,a5,-1130 # 80008b28 <syscallNos>
    80002f9a:	97ba                	add	a5,a5,a4
    80002f9c:	439c                	lw	a5,0(a5)
    80002f9e:	04f05863          	blez	a5,80002fee <syscall+0x102>
    80002fa2:	4481                	li	s1,0
        printf("%d ", ar);                         
    80002fa4:	00005a17          	auipc	s4,0x5
    80002fa8:	564a0a13          	addi	s4,s4,1380 # 80008508 <states.0+0x188>
      for(int i = 0; i<syscallNos[num]; i++)
    80002fac:	00006797          	auipc	a5,0x6
    80002fb0:	b7c78793          	addi	a5,a5,-1156 # 80008b28 <syscallNos>
    80002fb4:	00e789b3          	add	s3,a5,a4
    80002fb8:	a015                	j	80002fdc <syscall+0xf0>
        else ar = p->trapframe->a0;
    80002fba:	06093783          	ld	a5,96(s2)
    80002fbe:	7bbc                	ld	a5,112(a5)
    80002fc0:	fcf42623          	sw	a5,-52(s0)
        printf("%d ", ar);                         
    80002fc4:	fcc42583          	lw	a1,-52(s0)
    80002fc8:	8552                	mv	a0,s4
    80002fca:	ffffd097          	auipc	ra,0xffffd
    80002fce:	5c0080e7          	jalr	1472(ra) # 8000058a <printf>
      for(int i = 0; i<syscallNos[num]; i++)
    80002fd2:	2485                	addiw	s1,s1,1
    80002fd4:	0009a783          	lw	a5,0(s3)
    80002fd8:	00f4db63          	bge	s1,a5,80002fee <syscall+0x102>
        if(i != 0)
    80002fdc:	dcf9                	beqz	s1,80002fba <syscall+0xce>
          argint(i, &ar);
    80002fde:	fcc40593          	addi	a1,s0,-52
    80002fe2:	8526                	mv	a0,s1
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	e90080e7          	jalr	-368(ra) # 80002e74 <argint>
    80002fec:	bfe1                	j	80002fc4 <syscall+0xd8>
    printf(") -> %d\n", p->trapframe->a0);
    80002fee:	06093783          	ld	a5,96(s2)
    80002ff2:	7bac                	ld	a1,112(a5)
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	51c50513          	addi	a0,a0,1308 # 80008510 <states.0+0x190>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	58e080e7          	jalr	1422(ra) # 8000058a <printf>
    80003004:	bf99                	j	80002f5a <syscall+0x6e>

0000000080003006 <sys_exit>:
#include "proc.h"
// #include "date.h"

uint64
sys_exit(void)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000300e:	fec40593          	addi	a1,s0,-20
    80003012:	4501                	li	a0,0
    80003014:	00000097          	auipc	ra,0x0
    80003018:	e60080e7          	jalr	-416(ra) # 80002e74 <argint>
  exit(n);
    8000301c:	fec42503          	lw	a0,-20(s0)
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	2ce080e7          	jalr	718(ra) # 800022ee <exit>
  return 0;  // not reached
}
    80003028:	4501                	li	a0,0
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	6105                	addi	sp,sp,32
    80003030:	8082                	ret

0000000080003032 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003032:	1141                	addi	sp,sp,-16
    80003034:	e406                	sd	ra,8(sp)
    80003036:	e022                	sd	s0,0(sp)
    80003038:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	ac2080e7          	jalr	-1342(ra) # 80001afc <myproc>
}
    80003042:	5908                	lw	a0,48(a0)
    80003044:	60a2                	ld	ra,8(sp)
    80003046:	6402                	ld	s0,0(sp)
    80003048:	0141                	addi	sp,sp,16
    8000304a:	8082                	ret

000000008000304c <sys_fork>:

uint64
sys_fork(void)
{
    8000304c:	1141                	addi	sp,sp,-16
    8000304e:	e406                	sd	ra,8(sp)
    80003050:	e022                	sd	s0,0(sp)
    80003052:	0800                	addi	s0,sp,16
  return fork();
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	e74080e7          	jalr	-396(ra) # 80001ec8 <fork>
}
    8000305c:	60a2                	ld	ra,8(sp)
    8000305e:	6402                	ld	s0,0(sp)
    80003060:	0141                	addi	sp,sp,16
    80003062:	8082                	ret

0000000080003064 <sys_wait>:

uint64
sys_wait(void)
{
    80003064:	1101                	addi	sp,sp,-32
    80003066:	ec06                	sd	ra,24(sp)
    80003068:	e822                	sd	s0,16(sp)
    8000306a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000306c:	fe840593          	addi	a1,s0,-24
    80003070:	4501                	li	a0,0
    80003072:	00000097          	auipc	ra,0x0
    80003076:	e22080e7          	jalr	-478(ra) # 80002e94 <argaddr>
  return wait(p);
    8000307a:	fe843503          	ld	a0,-24(s0)
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	416080e7          	jalr	1046(ra) # 80002494 <wait>
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret

000000008000308e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000308e:	7179                	addi	sp,sp,-48
    80003090:	f406                	sd	ra,40(sp)
    80003092:	f022                	sd	s0,32(sp)
    80003094:	ec26                	sd	s1,24(sp)
    80003096:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003098:	fdc40593          	addi	a1,s0,-36
    8000309c:	4501                	li	a0,0
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	dd6080e7          	jalr	-554(ra) # 80002e74 <argint>
  addr = myproc()->sz;
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	a56080e7          	jalr	-1450(ra) # 80001afc <myproc>
    800030ae:	6924                	ld	s1,80(a0)
  if(growproc(n) < 0)
    800030b0:	fdc42503          	lw	a0,-36(s0)
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	db8080e7          	jalr	-584(ra) # 80001e6c <growproc>
    800030bc:	00054863          	bltz	a0,800030cc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030c0:	8526                	mv	a0,s1
    800030c2:	70a2                	ld	ra,40(sp)
    800030c4:	7402                	ld	s0,32(sp)
    800030c6:	64e2                	ld	s1,24(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret
    return -1;
    800030cc:	54fd                	li	s1,-1
    800030ce:	bfcd                	j	800030c0 <sys_sbrk+0x32>

00000000800030d0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030d0:	7139                	addi	sp,sp,-64
    800030d2:	fc06                	sd	ra,56(sp)
    800030d4:	f822                	sd	s0,48(sp)
    800030d6:	f426                	sd	s1,40(sp)
    800030d8:	f04a                	sd	s2,32(sp)
    800030da:	ec4e                	sd	s3,24(sp)
    800030dc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030de:	fcc40593          	addi	a1,s0,-52
    800030e2:	4501                	li	a0,0
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	d90080e7          	jalr	-624(ra) # 80002e74 <argint>
  acquire(&tickslock);
    800030ec:	0023d517          	auipc	a0,0x23d
    800030f0:	dac50513          	addi	a0,a0,-596 # 8023fe98 <tickslock>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	c18080e7          	jalr	-1000(ra) # 80000d0c <acquire>
  ticks0 = ticks;
    800030fc:	00006917          	auipc	s2,0x6
    80003100:	ae492903          	lw	s2,-1308(s2) # 80008be0 <ticks>
  while(ticks - ticks0 < n){
    80003104:	fcc42783          	lw	a5,-52(s0)
    80003108:	cf9d                	beqz	a5,80003146 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000310a:	0023d997          	auipc	s3,0x23d
    8000310e:	d8e98993          	addi	s3,s3,-626 # 8023fe98 <tickslock>
    80003112:	00006497          	auipc	s1,0x6
    80003116:	ace48493          	addi	s1,s1,-1330 # 80008be0 <ticks>
    if(killed(myproc())){
    8000311a:	fffff097          	auipc	ra,0xfffff
    8000311e:	9e2080e7          	jalr	-1566(ra) # 80001afc <myproc>
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	340080e7          	jalr	832(ra) # 80002462 <killed>
    8000312a:	ed15                	bnez	a0,80003166 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000312c:	85ce                	mv	a1,s3
    8000312e:	8526                	mv	a0,s1
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	08a080e7          	jalr	138(ra) # 800021ba <sleep>
  while(ticks - ticks0 < n){
    80003138:	409c                	lw	a5,0(s1)
    8000313a:	412787bb          	subw	a5,a5,s2
    8000313e:	fcc42703          	lw	a4,-52(s0)
    80003142:	fce7ece3          	bltu	a5,a4,8000311a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003146:	0023d517          	auipc	a0,0x23d
    8000314a:	d5250513          	addi	a0,a0,-686 # 8023fe98 <tickslock>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	c72080e7          	jalr	-910(ra) # 80000dc0 <release>
  return 0;
    80003156:	4501                	li	a0,0
}
    80003158:	70e2                	ld	ra,56(sp)
    8000315a:	7442                	ld	s0,48(sp)
    8000315c:	74a2                	ld	s1,40(sp)
    8000315e:	7902                	ld	s2,32(sp)
    80003160:	69e2                	ld	s3,24(sp)
    80003162:	6121                	addi	sp,sp,64
    80003164:	8082                	ret
      release(&tickslock);
    80003166:	0023d517          	auipc	a0,0x23d
    8000316a:	d3250513          	addi	a0,a0,-718 # 8023fe98 <tickslock>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	c52080e7          	jalr	-942(ra) # 80000dc0 <release>
      return -1;
    80003176:	557d                	li	a0,-1
    80003178:	b7c5                	j	80003158 <sys_sleep+0x88>

000000008000317a <sys_kill>:

uint64
sys_kill(void)
{
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003182:	fec40593          	addi	a1,s0,-20
    80003186:	4501                	li	a0,0
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	cec080e7          	jalr	-788(ra) # 80002e74 <argint>
  return kill(pid);
    80003190:	fec42503          	lw	a0,-20(s0)
    80003194:	fffff097          	auipc	ra,0xfffff
    80003198:	230080e7          	jalr	560(ra) # 800023c4 <kill>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	6105                	addi	sp,sp,32
    800031a2:	8082                	ret

00000000800031a4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031a4:	1101                	addi	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	e426                	sd	s1,8(sp)
    800031ac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031ae:	0023d517          	auipc	a0,0x23d
    800031b2:	cea50513          	addi	a0,a0,-790 # 8023fe98 <tickslock>
    800031b6:	ffffe097          	auipc	ra,0xffffe
    800031ba:	b56080e7          	jalr	-1194(ra) # 80000d0c <acquire>
  xticks = ticks;
    800031be:	00006497          	auipc	s1,0x6
    800031c2:	a224a483          	lw	s1,-1502(s1) # 80008be0 <ticks>
  release(&tickslock);
    800031c6:	0023d517          	auipc	a0,0x23d
    800031ca:	cd250513          	addi	a0,a0,-814 # 8023fe98 <tickslock>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	bf2080e7          	jalr	-1038(ra) # 80000dc0 <release>
  return xticks;
}
    800031d6:	02049513          	slli	a0,s1,0x20
    800031da:	9101                	srli	a0,a0,0x20
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <sys_trace>:

uint64
sys_trace(void)
{
    800031e6:	1141                	addi	sp,sp,-16
    800031e8:	e406                	sd	ra,8(sp)
    800031ea:	e022                	sd	s0,0(sp)
    800031ec:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tracemask);
    800031ee:	fffff097          	auipc	ra,0xfffff
    800031f2:	90e080e7          	jalr	-1778(ra) # 80001afc <myproc>
    800031f6:	03850593          	addi	a1,a0,56
    800031fa:	4501                	li	a0,0
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	c78080e7          	jalr	-904(ra) # 80002e74 <argint>
  if (myproc()->tracemask < 0)
    80003204:	fffff097          	auipc	ra,0xfffff
    80003208:	8f8080e7          	jalr	-1800(ra) # 80001afc <myproc>
    8000320c:	5d08                	lw	a0,56(a0)
		return -1;

	return 0;
}
    8000320e:	957d                	srai	a0,a0,0x3f
    80003210:	60a2                	ld	ra,8(sp)
    80003212:	6402                	ld	s0,0(sp)
    80003214:	0141                	addi	sp,sp,16
    80003216:	8082                	ret

0000000080003218 <sys_cps>:

int
sys_cps(void)
{
    80003218:	1141                	addi	sp,sp,-16
    8000321a:	e406                	sd	ra,8(sp)
    8000321c:	e022                	sd	s0,0(sp)
    8000321e:	0800                	addi	s0,sp,16
  return cps();
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	4fe080e7          	jalr	1278(ra) # 8000271e <cps>
}
    80003228:	60a2                	ld	ra,8(sp)
    8000322a:	6402                	ld	s0,0(sp)
    8000322c:	0141                	addi	sp,sp,16
    8000322e:	8082                	ret

0000000080003230 <sys_chpr>:

int
sys_chpr(void)
{
    80003230:	1101                	addi	sp,sp,-32
    80003232:	ec06                	sd	ra,24(sp)
    80003234:	e822                	sd	s0,16(sp)
    80003236:	1000                	addi	s0,sp,32
  int pid, pr;
  argint(0, &pid);
    80003238:	fec40593          	addi	a1,s0,-20
    8000323c:	4501                	li	a0,0
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	c36080e7          	jalr	-970(ra) # 80002e74 <argint>
  if(pid < 0)
    80003246:	fec42783          	lw	a5,-20(s0)
    8000324a:	0207c763          	bltz	a5,80003278 <sys_chpr+0x48>
    return -1;
  argint(1, &pr);
    8000324e:	fe840593          	addi	a1,s0,-24
    80003252:	4505                	li	a0,1
    80003254:	00000097          	auipc	ra,0x0
    80003258:	c20080e7          	jalr	-992(ra) # 80002e74 <argint>
  if(pr < 0)
    8000325c:	fe842583          	lw	a1,-24(s0)
    80003260:	0005ce63          	bltz	a1,8000327c <sys_chpr+0x4c>
    return -1;

  return chpr(pid, pr);
    80003264:	fec42503          	lw	a0,-20(s0)
    80003268:	fffff097          	auipc	ra,0xfffff
    8000326c:	5a6080e7          	jalr	1446(ra) # 8000280e <chpr>
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret
    return -1;
    80003278:	557d                	li	a0,-1
    8000327a:	bfdd                	j	80003270 <sys_chpr+0x40>
    return -1;
    8000327c:	557d                	li	a0,-1
    8000327e:	bfcd                	j	80003270 <sys_chpr+0x40>

0000000080003280 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003280:	7179                	addi	sp,sp,-48
    80003282:	f406                	sd	ra,40(sp)
    80003284:	f022                	sd	s0,32(sp)
    80003286:	ec26                	sd	s1,24(sp)
    80003288:	e84a                	sd	s2,16(sp)
    8000328a:	e44e                	sd	s3,8(sp)
    8000328c:	e052                	sd	s4,0(sp)
    8000328e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003290:	00005597          	auipc	a1,0x5
    80003294:	51058593          	addi	a1,a1,1296 # 800087a0 <names+0xd8>
    80003298:	0023d517          	auipc	a0,0x23d
    8000329c:	c1850513          	addi	a0,a0,-1000 # 8023feb0 <bcache>
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	9dc080e7          	jalr	-1572(ra) # 80000c7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032a8:	00245797          	auipc	a5,0x245
    800032ac:	c0878793          	addi	a5,a5,-1016 # 80247eb0 <bcache+0x8000>
    800032b0:	00245717          	auipc	a4,0x245
    800032b4:	e6870713          	addi	a4,a4,-408 # 80248118 <bcache+0x8268>
    800032b8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032bc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032c0:	0023d497          	auipc	s1,0x23d
    800032c4:	c0848493          	addi	s1,s1,-1016 # 8023fec8 <bcache+0x18>
    b->next = bcache.head.next;
    800032c8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032ca:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032cc:	00005a17          	auipc	s4,0x5
    800032d0:	4dca0a13          	addi	s4,s4,1244 # 800087a8 <names+0xe0>
    b->next = bcache.head.next;
    800032d4:	2b893783          	ld	a5,696(s2)
    800032d8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032da:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032de:	85d2                	mv	a1,s4
    800032e0:	01048513          	addi	a0,s1,16
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	4c6080e7          	jalr	1222(ra) # 800047aa <initsleeplock>
    bcache.head.next->prev = b;
    800032ec:	2b893783          	ld	a5,696(s2)
    800032f0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032f2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032f6:	45848493          	addi	s1,s1,1112
    800032fa:	fd349de3          	bne	s1,s3,800032d4 <binit+0x54>
  }
}
    800032fe:	70a2                	ld	ra,40(sp)
    80003300:	7402                	ld	s0,32(sp)
    80003302:	64e2                	ld	s1,24(sp)
    80003304:	6942                	ld	s2,16(sp)
    80003306:	69a2                	ld	s3,8(sp)
    80003308:	6a02                	ld	s4,0(sp)
    8000330a:	6145                	addi	sp,sp,48
    8000330c:	8082                	ret

000000008000330e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000330e:	7179                	addi	sp,sp,-48
    80003310:	f406                	sd	ra,40(sp)
    80003312:	f022                	sd	s0,32(sp)
    80003314:	ec26                	sd	s1,24(sp)
    80003316:	e84a                	sd	s2,16(sp)
    80003318:	e44e                	sd	s3,8(sp)
    8000331a:	1800                	addi	s0,sp,48
    8000331c:	892a                	mv	s2,a0
    8000331e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003320:	0023d517          	auipc	a0,0x23d
    80003324:	b9050513          	addi	a0,a0,-1136 # 8023feb0 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	9e4080e7          	jalr	-1564(ra) # 80000d0c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003330:	00245497          	auipc	s1,0x245
    80003334:	e384b483          	ld	s1,-456(s1) # 80248168 <bcache+0x82b8>
    80003338:	00245797          	auipc	a5,0x245
    8000333c:	de078793          	addi	a5,a5,-544 # 80248118 <bcache+0x8268>
    80003340:	02f48f63          	beq	s1,a5,8000337e <bread+0x70>
    80003344:	873e                	mv	a4,a5
    80003346:	a021                	j	8000334e <bread+0x40>
    80003348:	68a4                	ld	s1,80(s1)
    8000334a:	02e48a63          	beq	s1,a4,8000337e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000334e:	449c                	lw	a5,8(s1)
    80003350:	ff279ce3          	bne	a5,s2,80003348 <bread+0x3a>
    80003354:	44dc                	lw	a5,12(s1)
    80003356:	ff3799e3          	bne	a5,s3,80003348 <bread+0x3a>
      b->refcnt++;
    8000335a:	40bc                	lw	a5,64(s1)
    8000335c:	2785                	addiw	a5,a5,1
    8000335e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003360:	0023d517          	auipc	a0,0x23d
    80003364:	b5050513          	addi	a0,a0,-1200 # 8023feb0 <bcache>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	a58080e7          	jalr	-1448(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    80003370:	01048513          	addi	a0,s1,16
    80003374:	00001097          	auipc	ra,0x1
    80003378:	470080e7          	jalr	1136(ra) # 800047e4 <acquiresleep>
      return b;
    8000337c:	a8b9                	j	800033da <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000337e:	00245497          	auipc	s1,0x245
    80003382:	de24b483          	ld	s1,-542(s1) # 80248160 <bcache+0x82b0>
    80003386:	00245797          	auipc	a5,0x245
    8000338a:	d9278793          	addi	a5,a5,-622 # 80248118 <bcache+0x8268>
    8000338e:	00f48863          	beq	s1,a5,8000339e <bread+0x90>
    80003392:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003394:	40bc                	lw	a5,64(s1)
    80003396:	cf81                	beqz	a5,800033ae <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003398:	64a4                	ld	s1,72(s1)
    8000339a:	fee49de3          	bne	s1,a4,80003394 <bread+0x86>
  panic("bget: no buffers");
    8000339e:	00005517          	auipc	a0,0x5
    800033a2:	41250513          	addi	a0,a0,1042 # 800087b0 <names+0xe8>
    800033a6:	ffffd097          	auipc	ra,0xffffd
    800033aa:	19a080e7          	jalr	410(ra) # 80000540 <panic>
      b->dev = dev;
    800033ae:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033b2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033b6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033ba:	4785                	li	a5,1
    800033bc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033be:	0023d517          	auipc	a0,0x23d
    800033c2:	af250513          	addi	a0,a0,-1294 # 8023feb0 <bcache>
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	9fa080e7          	jalr	-1542(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    800033ce:	01048513          	addi	a0,s1,16
    800033d2:	00001097          	auipc	ra,0x1
    800033d6:	412080e7          	jalr	1042(ra) # 800047e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033da:	409c                	lw	a5,0(s1)
    800033dc:	cb89                	beqz	a5,800033ee <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033de:	8526                	mv	a0,s1
    800033e0:	70a2                	ld	ra,40(sp)
    800033e2:	7402                	ld	s0,32(sp)
    800033e4:	64e2                	ld	s1,24(sp)
    800033e6:	6942                	ld	s2,16(sp)
    800033e8:	69a2                	ld	s3,8(sp)
    800033ea:	6145                	addi	sp,sp,48
    800033ec:	8082                	ret
    virtio_disk_rw(b, 0);
    800033ee:	4581                	li	a1,0
    800033f0:	8526                	mv	a0,s1
    800033f2:	00003097          	auipc	ra,0x3
    800033f6:	fe0080e7          	jalr	-32(ra) # 800063d2 <virtio_disk_rw>
    b->valid = 1;
    800033fa:	4785                	li	a5,1
    800033fc:	c09c                	sw	a5,0(s1)
  return b;
    800033fe:	b7c5                	j	800033de <bread+0xd0>

0000000080003400 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003400:	1101                	addi	sp,sp,-32
    80003402:	ec06                	sd	ra,24(sp)
    80003404:	e822                	sd	s0,16(sp)
    80003406:	e426                	sd	s1,8(sp)
    80003408:	1000                	addi	s0,sp,32
    8000340a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000340c:	0541                	addi	a0,a0,16
    8000340e:	00001097          	auipc	ra,0x1
    80003412:	470080e7          	jalr	1136(ra) # 8000487e <holdingsleep>
    80003416:	cd01                	beqz	a0,8000342e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003418:	4585                	li	a1,1
    8000341a:	8526                	mv	a0,s1
    8000341c:	00003097          	auipc	ra,0x3
    80003420:	fb6080e7          	jalr	-74(ra) # 800063d2 <virtio_disk_rw>
}
    80003424:	60e2                	ld	ra,24(sp)
    80003426:	6442                	ld	s0,16(sp)
    80003428:	64a2                	ld	s1,8(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret
    panic("bwrite");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	39a50513          	addi	a0,a0,922 # 800087c8 <names+0x100>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	10a080e7          	jalr	266(ra) # 80000540 <panic>

000000008000343e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	e04a                	sd	s2,0(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000344c:	01050913          	addi	s2,a0,16
    80003450:	854a                	mv	a0,s2
    80003452:	00001097          	auipc	ra,0x1
    80003456:	42c080e7          	jalr	1068(ra) # 8000487e <holdingsleep>
    8000345a:	c92d                	beqz	a0,800034cc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000345c:	854a                	mv	a0,s2
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	3dc080e7          	jalr	988(ra) # 8000483a <releasesleep>

  acquire(&bcache.lock);
    80003466:	0023d517          	auipc	a0,0x23d
    8000346a:	a4a50513          	addi	a0,a0,-1462 # 8023feb0 <bcache>
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	89e080e7          	jalr	-1890(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003476:	40bc                	lw	a5,64(s1)
    80003478:	37fd                	addiw	a5,a5,-1
    8000347a:	0007871b          	sext.w	a4,a5
    8000347e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003480:	eb05                	bnez	a4,800034b0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003482:	68bc                	ld	a5,80(s1)
    80003484:	64b8                	ld	a4,72(s1)
    80003486:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003488:	64bc                	ld	a5,72(s1)
    8000348a:	68b8                	ld	a4,80(s1)
    8000348c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000348e:	00245797          	auipc	a5,0x245
    80003492:	a2278793          	addi	a5,a5,-1502 # 80247eb0 <bcache+0x8000>
    80003496:	2b87b703          	ld	a4,696(a5)
    8000349a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000349c:	00245717          	auipc	a4,0x245
    800034a0:	c7c70713          	addi	a4,a4,-900 # 80248118 <bcache+0x8268>
    800034a4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034a6:	2b87b703          	ld	a4,696(a5)
    800034aa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034ac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034b0:	0023d517          	auipc	a0,0x23d
    800034b4:	a0050513          	addi	a0,a0,-1536 # 8023feb0 <bcache>
    800034b8:	ffffe097          	auipc	ra,0xffffe
    800034bc:	908080e7          	jalr	-1784(ra) # 80000dc0 <release>
}
    800034c0:	60e2                	ld	ra,24(sp)
    800034c2:	6442                	ld	s0,16(sp)
    800034c4:	64a2                	ld	s1,8(sp)
    800034c6:	6902                	ld	s2,0(sp)
    800034c8:	6105                	addi	sp,sp,32
    800034ca:	8082                	ret
    panic("brelse");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	30450513          	addi	a0,a0,772 # 800087d0 <names+0x108>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	06c080e7          	jalr	108(ra) # 80000540 <panic>

00000000800034dc <bpin>:

void
bpin(struct buf *b) {
    800034dc:	1101                	addi	sp,sp,-32
    800034de:	ec06                	sd	ra,24(sp)
    800034e0:	e822                	sd	s0,16(sp)
    800034e2:	e426                	sd	s1,8(sp)
    800034e4:	1000                	addi	s0,sp,32
    800034e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034e8:	0023d517          	auipc	a0,0x23d
    800034ec:	9c850513          	addi	a0,a0,-1592 # 8023feb0 <bcache>
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	81c080e7          	jalr	-2020(ra) # 80000d0c <acquire>
  b->refcnt++;
    800034f8:	40bc                	lw	a5,64(s1)
    800034fa:	2785                	addiw	a5,a5,1
    800034fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034fe:	0023d517          	auipc	a0,0x23d
    80003502:	9b250513          	addi	a0,a0,-1614 # 8023feb0 <bcache>
    80003506:	ffffe097          	auipc	ra,0xffffe
    8000350a:	8ba080e7          	jalr	-1862(ra) # 80000dc0 <release>
}
    8000350e:	60e2                	ld	ra,24(sp)
    80003510:	6442                	ld	s0,16(sp)
    80003512:	64a2                	ld	s1,8(sp)
    80003514:	6105                	addi	sp,sp,32
    80003516:	8082                	ret

0000000080003518 <bunpin>:

void
bunpin(struct buf *b) {
    80003518:	1101                	addi	sp,sp,-32
    8000351a:	ec06                	sd	ra,24(sp)
    8000351c:	e822                	sd	s0,16(sp)
    8000351e:	e426                	sd	s1,8(sp)
    80003520:	1000                	addi	s0,sp,32
    80003522:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003524:	0023d517          	auipc	a0,0x23d
    80003528:	98c50513          	addi	a0,a0,-1652 # 8023feb0 <bcache>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	7e0080e7          	jalr	2016(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003534:	40bc                	lw	a5,64(s1)
    80003536:	37fd                	addiw	a5,a5,-1
    80003538:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000353a:	0023d517          	auipc	a0,0x23d
    8000353e:	97650513          	addi	a0,a0,-1674 # 8023feb0 <bcache>
    80003542:	ffffe097          	auipc	ra,0xffffe
    80003546:	87e080e7          	jalr	-1922(ra) # 80000dc0 <release>
}
    8000354a:	60e2                	ld	ra,24(sp)
    8000354c:	6442                	ld	s0,16(sp)
    8000354e:	64a2                	ld	s1,8(sp)
    80003550:	6105                	addi	sp,sp,32
    80003552:	8082                	ret

0000000080003554 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003562:	00d5d59b          	srliw	a1,a1,0xd
    80003566:	00245797          	auipc	a5,0x245
    8000356a:	0267a783          	lw	a5,38(a5) # 8024858c <sb+0x1c>
    8000356e:	9dbd                	addw	a1,a1,a5
    80003570:	00000097          	auipc	ra,0x0
    80003574:	d9e080e7          	jalr	-610(ra) # 8000330e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003578:	0074f713          	andi	a4,s1,7
    8000357c:	4785                	li	a5,1
    8000357e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003582:	14ce                	slli	s1,s1,0x33
    80003584:	90d9                	srli	s1,s1,0x36
    80003586:	00950733          	add	a4,a0,s1
    8000358a:	05874703          	lbu	a4,88(a4)
    8000358e:	00e7f6b3          	and	a3,a5,a4
    80003592:	c69d                	beqz	a3,800035c0 <bfree+0x6c>
    80003594:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003596:	94aa                	add	s1,s1,a0
    80003598:	fff7c793          	not	a5,a5
    8000359c:	8f7d                	and	a4,a4,a5
    8000359e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800035a2:	00001097          	auipc	ra,0x1
    800035a6:	124080e7          	jalr	292(ra) # 800046c6 <log_write>
  brelse(bp);
    800035aa:	854a                	mv	a0,s2
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	e92080e7          	jalr	-366(ra) # 8000343e <brelse>
}
    800035b4:	60e2                	ld	ra,24(sp)
    800035b6:	6442                	ld	s0,16(sp)
    800035b8:	64a2                	ld	s1,8(sp)
    800035ba:	6902                	ld	s2,0(sp)
    800035bc:	6105                	addi	sp,sp,32
    800035be:	8082                	ret
    panic("freeing free block");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	21850513          	addi	a0,a0,536 # 800087d8 <names+0x110>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f78080e7          	jalr	-136(ra) # 80000540 <panic>

00000000800035d0 <balloc>:
{
    800035d0:	711d                	addi	sp,sp,-96
    800035d2:	ec86                	sd	ra,88(sp)
    800035d4:	e8a2                	sd	s0,80(sp)
    800035d6:	e4a6                	sd	s1,72(sp)
    800035d8:	e0ca                	sd	s2,64(sp)
    800035da:	fc4e                	sd	s3,56(sp)
    800035dc:	f852                	sd	s4,48(sp)
    800035de:	f456                	sd	s5,40(sp)
    800035e0:	f05a                	sd	s6,32(sp)
    800035e2:	ec5e                	sd	s7,24(sp)
    800035e4:	e862                	sd	s8,16(sp)
    800035e6:	e466                	sd	s9,8(sp)
    800035e8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035ea:	00245797          	auipc	a5,0x245
    800035ee:	f8a7a783          	lw	a5,-118(a5) # 80248574 <sb+0x4>
    800035f2:	cff5                	beqz	a5,800036ee <balloc+0x11e>
    800035f4:	8baa                	mv	s7,a0
    800035f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035f8:	00245b17          	auipc	s6,0x245
    800035fc:	f78b0b13          	addi	s6,s6,-136 # 80248570 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003600:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003602:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003604:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003606:	6c89                	lui	s9,0x2
    80003608:	a061                	j	80003690 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000360a:	97ca                	add	a5,a5,s2
    8000360c:	8e55                	or	a2,a2,a3
    8000360e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003612:	854a                	mv	a0,s2
    80003614:	00001097          	auipc	ra,0x1
    80003618:	0b2080e7          	jalr	178(ra) # 800046c6 <log_write>
        brelse(bp);
    8000361c:	854a                	mv	a0,s2
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	e20080e7          	jalr	-480(ra) # 8000343e <brelse>
  bp = bread(dev, bno);
    80003626:	85a6                	mv	a1,s1
    80003628:	855e                	mv	a0,s7
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	ce4080e7          	jalr	-796(ra) # 8000330e <bread>
    80003632:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003634:	40000613          	li	a2,1024
    80003638:	4581                	li	a1,0
    8000363a:	05850513          	addi	a0,a0,88
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	7ca080e7          	jalr	1994(ra) # 80000e08 <memset>
  log_write(bp);
    80003646:	854a                	mv	a0,s2
    80003648:	00001097          	auipc	ra,0x1
    8000364c:	07e080e7          	jalr	126(ra) # 800046c6 <log_write>
  brelse(bp);
    80003650:	854a                	mv	a0,s2
    80003652:	00000097          	auipc	ra,0x0
    80003656:	dec080e7          	jalr	-532(ra) # 8000343e <brelse>
}
    8000365a:	8526                	mv	a0,s1
    8000365c:	60e6                	ld	ra,88(sp)
    8000365e:	6446                	ld	s0,80(sp)
    80003660:	64a6                	ld	s1,72(sp)
    80003662:	6906                	ld	s2,64(sp)
    80003664:	79e2                	ld	s3,56(sp)
    80003666:	7a42                	ld	s4,48(sp)
    80003668:	7aa2                	ld	s5,40(sp)
    8000366a:	7b02                	ld	s6,32(sp)
    8000366c:	6be2                	ld	s7,24(sp)
    8000366e:	6c42                	ld	s8,16(sp)
    80003670:	6ca2                	ld	s9,8(sp)
    80003672:	6125                	addi	sp,sp,96
    80003674:	8082                	ret
    brelse(bp);
    80003676:	854a                	mv	a0,s2
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	dc6080e7          	jalr	-570(ra) # 8000343e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003680:	015c87bb          	addw	a5,s9,s5
    80003684:	00078a9b          	sext.w	s5,a5
    80003688:	004b2703          	lw	a4,4(s6)
    8000368c:	06eaf163          	bgeu	s5,a4,800036ee <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003690:	41fad79b          	sraiw	a5,s5,0x1f
    80003694:	0137d79b          	srliw	a5,a5,0x13
    80003698:	015787bb          	addw	a5,a5,s5
    8000369c:	40d7d79b          	sraiw	a5,a5,0xd
    800036a0:	01cb2583          	lw	a1,28(s6)
    800036a4:	9dbd                	addw	a1,a1,a5
    800036a6:	855e                	mv	a0,s7
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	c66080e7          	jalr	-922(ra) # 8000330e <bread>
    800036b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b2:	004b2503          	lw	a0,4(s6)
    800036b6:	000a849b          	sext.w	s1,s5
    800036ba:	8762                	mv	a4,s8
    800036bc:	faa4fde3          	bgeu	s1,a0,80003676 <balloc+0xa6>
      m = 1 << (bi % 8);
    800036c0:	00777693          	andi	a3,a4,7
    800036c4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036c8:	41f7579b          	sraiw	a5,a4,0x1f
    800036cc:	01d7d79b          	srliw	a5,a5,0x1d
    800036d0:	9fb9                	addw	a5,a5,a4
    800036d2:	4037d79b          	sraiw	a5,a5,0x3
    800036d6:	00f90633          	add	a2,s2,a5
    800036da:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800036de:	00c6f5b3          	and	a1,a3,a2
    800036e2:	d585                	beqz	a1,8000360a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e4:	2705                	addiw	a4,a4,1
    800036e6:	2485                	addiw	s1,s1,1
    800036e8:	fd471ae3          	bne	a4,s4,800036bc <balloc+0xec>
    800036ec:	b769                	j	80003676 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	10250513          	addi	a0,a0,258 # 800087f0 <names+0x128>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e94080e7          	jalr	-364(ra) # 8000058a <printf>
  return 0;
    800036fe:	4481                	li	s1,0
    80003700:	bfa9                	j	8000365a <balloc+0x8a>

0000000080003702 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003702:	7179                	addi	sp,sp,-48
    80003704:	f406                	sd	ra,40(sp)
    80003706:	f022                	sd	s0,32(sp)
    80003708:	ec26                	sd	s1,24(sp)
    8000370a:	e84a                	sd	s2,16(sp)
    8000370c:	e44e                	sd	s3,8(sp)
    8000370e:	e052                	sd	s4,0(sp)
    80003710:	1800                	addi	s0,sp,48
    80003712:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003714:	47ad                	li	a5,11
    80003716:	02b7e863          	bltu	a5,a1,80003746 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000371a:	02059793          	slli	a5,a1,0x20
    8000371e:	01e7d593          	srli	a1,a5,0x1e
    80003722:	00b504b3          	add	s1,a0,a1
    80003726:	0504a903          	lw	s2,80(s1)
    8000372a:	06091e63          	bnez	s2,800037a6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000372e:	4108                	lw	a0,0(a0)
    80003730:	00000097          	auipc	ra,0x0
    80003734:	ea0080e7          	jalr	-352(ra) # 800035d0 <balloc>
    80003738:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000373c:	06090563          	beqz	s2,800037a6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003740:	0524a823          	sw	s2,80(s1)
    80003744:	a08d                	j	800037a6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003746:	ff45849b          	addiw	s1,a1,-12
    8000374a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000374e:	0ff00793          	li	a5,255
    80003752:	08e7e563          	bltu	a5,a4,800037dc <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003756:	08052903          	lw	s2,128(a0)
    8000375a:	00091d63          	bnez	s2,80003774 <bmap+0x72>
      addr = balloc(ip->dev);
    8000375e:	4108                	lw	a0,0(a0)
    80003760:	00000097          	auipc	ra,0x0
    80003764:	e70080e7          	jalr	-400(ra) # 800035d0 <balloc>
    80003768:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000376c:	02090d63          	beqz	s2,800037a6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003770:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003774:	85ca                	mv	a1,s2
    80003776:	0009a503          	lw	a0,0(s3)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	b94080e7          	jalr	-1132(ra) # 8000330e <bread>
    80003782:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003784:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003788:	02049713          	slli	a4,s1,0x20
    8000378c:	01e75593          	srli	a1,a4,0x1e
    80003790:	00b784b3          	add	s1,a5,a1
    80003794:	0004a903          	lw	s2,0(s1)
    80003798:	02090063          	beqz	s2,800037b8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000379c:	8552                	mv	a0,s4
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	ca0080e7          	jalr	-864(ra) # 8000343e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037a6:	854a                	mv	a0,s2
    800037a8:	70a2                	ld	ra,40(sp)
    800037aa:	7402                	ld	s0,32(sp)
    800037ac:	64e2                	ld	s1,24(sp)
    800037ae:	6942                	ld	s2,16(sp)
    800037b0:	69a2                	ld	s3,8(sp)
    800037b2:	6a02                	ld	s4,0(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret
      addr = balloc(ip->dev);
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	e14080e7          	jalr	-492(ra) # 800035d0 <balloc>
    800037c4:	0005091b          	sext.w	s2,a0
      if(addr){
    800037c8:	fc090ae3          	beqz	s2,8000379c <bmap+0x9a>
        a[bn] = addr;
    800037cc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037d0:	8552                	mv	a0,s4
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	ef4080e7          	jalr	-268(ra) # 800046c6 <log_write>
    800037da:	b7c9                	j	8000379c <bmap+0x9a>
  panic("bmap: out of range");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	02c50513          	addi	a0,a0,44 # 80008808 <names+0x140>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5c080e7          	jalr	-676(ra) # 80000540 <panic>

00000000800037ec <iget>:
{
    800037ec:	7179                	addi	sp,sp,-48
    800037ee:	f406                	sd	ra,40(sp)
    800037f0:	f022                	sd	s0,32(sp)
    800037f2:	ec26                	sd	s1,24(sp)
    800037f4:	e84a                	sd	s2,16(sp)
    800037f6:	e44e                	sd	s3,8(sp)
    800037f8:	e052                	sd	s4,0(sp)
    800037fa:	1800                	addi	s0,sp,48
    800037fc:	89aa                	mv	s3,a0
    800037fe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003800:	00245517          	auipc	a0,0x245
    80003804:	d9050513          	addi	a0,a0,-624 # 80248590 <itable>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	504080e7          	jalr	1284(ra) # 80000d0c <acquire>
  empty = 0;
    80003810:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003812:	00245497          	auipc	s1,0x245
    80003816:	d9648493          	addi	s1,s1,-618 # 802485a8 <itable+0x18>
    8000381a:	00247697          	auipc	a3,0x247
    8000381e:	81e68693          	addi	a3,a3,-2018 # 8024a038 <log>
    80003822:	a039                	j	80003830 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003824:	02090b63          	beqz	s2,8000385a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003828:	08848493          	addi	s1,s1,136
    8000382c:	02d48a63          	beq	s1,a3,80003860 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003830:	449c                	lw	a5,8(s1)
    80003832:	fef059e3          	blez	a5,80003824 <iget+0x38>
    80003836:	4098                	lw	a4,0(s1)
    80003838:	ff3716e3          	bne	a4,s3,80003824 <iget+0x38>
    8000383c:	40d8                	lw	a4,4(s1)
    8000383e:	ff4713e3          	bne	a4,s4,80003824 <iget+0x38>
      ip->ref++;
    80003842:	2785                	addiw	a5,a5,1
    80003844:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003846:	00245517          	auipc	a0,0x245
    8000384a:	d4a50513          	addi	a0,a0,-694 # 80248590 <itable>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	572080e7          	jalr	1394(ra) # 80000dc0 <release>
      return ip;
    80003856:	8926                	mv	s2,s1
    80003858:	a03d                	j	80003886 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000385a:	f7f9                	bnez	a5,80003828 <iget+0x3c>
    8000385c:	8926                	mv	s2,s1
    8000385e:	b7e9                	j	80003828 <iget+0x3c>
  if(empty == 0)
    80003860:	02090c63          	beqz	s2,80003898 <iget+0xac>
  ip->dev = dev;
    80003864:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003868:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000386c:	4785                	li	a5,1
    8000386e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003872:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003876:	00245517          	auipc	a0,0x245
    8000387a:	d1a50513          	addi	a0,a0,-742 # 80248590 <itable>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	542080e7          	jalr	1346(ra) # 80000dc0 <release>
}
    80003886:	854a                	mv	a0,s2
    80003888:	70a2                	ld	ra,40(sp)
    8000388a:	7402                	ld	s0,32(sp)
    8000388c:	64e2                	ld	s1,24(sp)
    8000388e:	6942                	ld	s2,16(sp)
    80003890:	69a2                	ld	s3,8(sp)
    80003892:	6a02                	ld	s4,0(sp)
    80003894:	6145                	addi	sp,sp,48
    80003896:	8082                	ret
    panic("iget: no inodes");
    80003898:	00005517          	auipc	a0,0x5
    8000389c:	f8850513          	addi	a0,a0,-120 # 80008820 <names+0x158>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	ca0080e7          	jalr	-864(ra) # 80000540 <panic>

00000000800038a8 <fsinit>:
fsinit(int dev) {
    800038a8:	7179                	addi	sp,sp,-48
    800038aa:	f406                	sd	ra,40(sp)
    800038ac:	f022                	sd	s0,32(sp)
    800038ae:	ec26                	sd	s1,24(sp)
    800038b0:	e84a                	sd	s2,16(sp)
    800038b2:	e44e                	sd	s3,8(sp)
    800038b4:	1800                	addi	s0,sp,48
    800038b6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038b8:	4585                	li	a1,1
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	a54080e7          	jalr	-1452(ra) # 8000330e <bread>
    800038c2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038c4:	00245997          	auipc	s3,0x245
    800038c8:	cac98993          	addi	s3,s3,-852 # 80248570 <sb>
    800038cc:	02000613          	li	a2,32
    800038d0:	05850593          	addi	a1,a0,88
    800038d4:	854e                	mv	a0,s3
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	58e080e7          	jalr	1422(ra) # 80000e64 <memmove>
  brelse(bp);
    800038de:	8526                	mv	a0,s1
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	b5e080e7          	jalr	-1186(ra) # 8000343e <brelse>
  if(sb.magic != FSMAGIC)
    800038e8:	0009a703          	lw	a4,0(s3)
    800038ec:	102037b7          	lui	a5,0x10203
    800038f0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038f4:	02f71263          	bne	a4,a5,80003918 <fsinit+0x70>
  initlog(dev, &sb);
    800038f8:	00245597          	auipc	a1,0x245
    800038fc:	c7858593          	addi	a1,a1,-904 # 80248570 <sb>
    80003900:	854a                	mv	a0,s2
    80003902:	00001097          	auipc	ra,0x1
    80003906:	b48080e7          	jalr	-1208(ra) # 8000444a <initlog>
}
    8000390a:	70a2                	ld	ra,40(sp)
    8000390c:	7402                	ld	s0,32(sp)
    8000390e:	64e2                	ld	s1,24(sp)
    80003910:	6942                	ld	s2,16(sp)
    80003912:	69a2                	ld	s3,8(sp)
    80003914:	6145                	addi	sp,sp,48
    80003916:	8082                	ret
    panic("invalid file system");
    80003918:	00005517          	auipc	a0,0x5
    8000391c:	f1850513          	addi	a0,a0,-232 # 80008830 <names+0x168>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	c20080e7          	jalr	-992(ra) # 80000540 <panic>

0000000080003928 <iinit>:
{
    80003928:	7179                	addi	sp,sp,-48
    8000392a:	f406                	sd	ra,40(sp)
    8000392c:	f022                	sd	s0,32(sp)
    8000392e:	ec26                	sd	s1,24(sp)
    80003930:	e84a                	sd	s2,16(sp)
    80003932:	e44e                	sd	s3,8(sp)
    80003934:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003936:	00005597          	auipc	a1,0x5
    8000393a:	f1258593          	addi	a1,a1,-238 # 80008848 <names+0x180>
    8000393e:	00245517          	auipc	a0,0x245
    80003942:	c5250513          	addi	a0,a0,-942 # 80248590 <itable>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	336080e7          	jalr	822(ra) # 80000c7c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000394e:	00245497          	auipc	s1,0x245
    80003952:	c6a48493          	addi	s1,s1,-918 # 802485b8 <itable+0x28>
    80003956:	00246997          	auipc	s3,0x246
    8000395a:	6f298993          	addi	s3,s3,1778 # 8024a048 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000395e:	00005917          	auipc	s2,0x5
    80003962:	ef290913          	addi	s2,s2,-270 # 80008850 <names+0x188>
    80003966:	85ca                	mv	a1,s2
    80003968:	8526                	mv	a0,s1
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	e40080e7          	jalr	-448(ra) # 800047aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003972:	08848493          	addi	s1,s1,136
    80003976:	ff3498e3          	bne	s1,s3,80003966 <iinit+0x3e>
}
    8000397a:	70a2                	ld	ra,40(sp)
    8000397c:	7402                	ld	s0,32(sp)
    8000397e:	64e2                	ld	s1,24(sp)
    80003980:	6942                	ld	s2,16(sp)
    80003982:	69a2                	ld	s3,8(sp)
    80003984:	6145                	addi	sp,sp,48
    80003986:	8082                	ret

0000000080003988 <ialloc>:
{
    80003988:	715d                	addi	sp,sp,-80
    8000398a:	e486                	sd	ra,72(sp)
    8000398c:	e0a2                	sd	s0,64(sp)
    8000398e:	fc26                	sd	s1,56(sp)
    80003990:	f84a                	sd	s2,48(sp)
    80003992:	f44e                	sd	s3,40(sp)
    80003994:	f052                	sd	s4,32(sp)
    80003996:	ec56                	sd	s5,24(sp)
    80003998:	e85a                	sd	s6,16(sp)
    8000399a:	e45e                	sd	s7,8(sp)
    8000399c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000399e:	00245717          	auipc	a4,0x245
    800039a2:	bde72703          	lw	a4,-1058(a4) # 8024857c <sb+0xc>
    800039a6:	4785                	li	a5,1
    800039a8:	04e7fa63          	bgeu	a5,a4,800039fc <ialloc+0x74>
    800039ac:	8aaa                	mv	s5,a0
    800039ae:	8bae                	mv	s7,a1
    800039b0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039b2:	00245a17          	auipc	s4,0x245
    800039b6:	bbea0a13          	addi	s4,s4,-1090 # 80248570 <sb>
    800039ba:	00048b1b          	sext.w	s6,s1
    800039be:	0044d593          	srli	a1,s1,0x4
    800039c2:	018a2783          	lw	a5,24(s4)
    800039c6:	9dbd                	addw	a1,a1,a5
    800039c8:	8556                	mv	a0,s5
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	944080e7          	jalr	-1724(ra) # 8000330e <bread>
    800039d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039d4:	05850993          	addi	s3,a0,88
    800039d8:	00f4f793          	andi	a5,s1,15
    800039dc:	079a                	slli	a5,a5,0x6
    800039de:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039e0:	00099783          	lh	a5,0(s3)
    800039e4:	c3a1                	beqz	a5,80003a24 <ialloc+0x9c>
    brelse(bp);
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	a58080e7          	jalr	-1448(ra) # 8000343e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039ee:	0485                	addi	s1,s1,1
    800039f0:	00ca2703          	lw	a4,12(s4)
    800039f4:	0004879b          	sext.w	a5,s1
    800039f8:	fce7e1e3          	bltu	a5,a4,800039ba <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039fc:	00005517          	auipc	a0,0x5
    80003a00:	e5c50513          	addi	a0,a0,-420 # 80008858 <names+0x190>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	b86080e7          	jalr	-1146(ra) # 8000058a <printf>
  return 0;
    80003a0c:	4501                	li	a0,0
}
    80003a0e:	60a6                	ld	ra,72(sp)
    80003a10:	6406                	ld	s0,64(sp)
    80003a12:	74e2                	ld	s1,56(sp)
    80003a14:	7942                	ld	s2,48(sp)
    80003a16:	79a2                	ld	s3,40(sp)
    80003a18:	7a02                	ld	s4,32(sp)
    80003a1a:	6ae2                	ld	s5,24(sp)
    80003a1c:	6b42                	ld	s6,16(sp)
    80003a1e:	6ba2                	ld	s7,8(sp)
    80003a20:	6161                	addi	sp,sp,80
    80003a22:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a24:	04000613          	li	a2,64
    80003a28:	4581                	li	a1,0
    80003a2a:	854e                	mv	a0,s3
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	3dc080e7          	jalr	988(ra) # 80000e08 <memset>
      dip->type = type;
    80003a34:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a38:	854a                	mv	a0,s2
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	c8c080e7          	jalr	-884(ra) # 800046c6 <log_write>
      brelse(bp);
    80003a42:	854a                	mv	a0,s2
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	9fa080e7          	jalr	-1542(ra) # 8000343e <brelse>
      return iget(dev, inum);
    80003a4c:	85da                	mv	a1,s6
    80003a4e:	8556                	mv	a0,s5
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	d9c080e7          	jalr	-612(ra) # 800037ec <iget>
    80003a58:	bf5d                	j	80003a0e <ialloc+0x86>

0000000080003a5a <iupdate>:
{
    80003a5a:	1101                	addi	sp,sp,-32
    80003a5c:	ec06                	sd	ra,24(sp)
    80003a5e:	e822                	sd	s0,16(sp)
    80003a60:	e426                	sd	s1,8(sp)
    80003a62:	e04a                	sd	s2,0(sp)
    80003a64:	1000                	addi	s0,sp,32
    80003a66:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a68:	415c                	lw	a5,4(a0)
    80003a6a:	0047d79b          	srliw	a5,a5,0x4
    80003a6e:	00245597          	auipc	a1,0x245
    80003a72:	b1a5a583          	lw	a1,-1254(a1) # 80248588 <sb+0x18>
    80003a76:	9dbd                	addw	a1,a1,a5
    80003a78:	4108                	lw	a0,0(a0)
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	894080e7          	jalr	-1900(ra) # 8000330e <bread>
    80003a82:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a84:	05850793          	addi	a5,a0,88
    80003a88:	40d8                	lw	a4,4(s1)
    80003a8a:	8b3d                	andi	a4,a4,15
    80003a8c:	071a                	slli	a4,a4,0x6
    80003a8e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a90:	04449703          	lh	a4,68(s1)
    80003a94:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a98:	04649703          	lh	a4,70(s1)
    80003a9c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003aa0:	04849703          	lh	a4,72(s1)
    80003aa4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003aa8:	04a49703          	lh	a4,74(s1)
    80003aac:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ab0:	44f8                	lw	a4,76(s1)
    80003ab2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ab4:	03400613          	li	a2,52
    80003ab8:	05048593          	addi	a1,s1,80
    80003abc:	00c78513          	addi	a0,a5,12
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	3a4080e7          	jalr	932(ra) # 80000e64 <memmove>
  log_write(bp);
    80003ac8:	854a                	mv	a0,s2
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	bfc080e7          	jalr	-1028(ra) # 800046c6 <log_write>
  brelse(bp);
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	96a080e7          	jalr	-1686(ra) # 8000343e <brelse>
}
    80003adc:	60e2                	ld	ra,24(sp)
    80003ade:	6442                	ld	s0,16(sp)
    80003ae0:	64a2                	ld	s1,8(sp)
    80003ae2:	6902                	ld	s2,0(sp)
    80003ae4:	6105                	addi	sp,sp,32
    80003ae6:	8082                	ret

0000000080003ae8 <idup>:
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	1000                	addi	s0,sp,32
    80003af2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003af4:	00245517          	auipc	a0,0x245
    80003af8:	a9c50513          	addi	a0,a0,-1380 # 80248590 <itable>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	210080e7          	jalr	528(ra) # 80000d0c <acquire>
  ip->ref++;
    80003b04:	449c                	lw	a5,8(s1)
    80003b06:	2785                	addiw	a5,a5,1
    80003b08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b0a:	00245517          	auipc	a0,0x245
    80003b0e:	a8650513          	addi	a0,a0,-1402 # 80248590 <itable>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	2ae080e7          	jalr	686(ra) # 80000dc0 <release>
}
    80003b1a:	8526                	mv	a0,s1
    80003b1c:	60e2                	ld	ra,24(sp)
    80003b1e:	6442                	ld	s0,16(sp)
    80003b20:	64a2                	ld	s1,8(sp)
    80003b22:	6105                	addi	sp,sp,32
    80003b24:	8082                	ret

0000000080003b26 <ilock>:
{
    80003b26:	1101                	addi	sp,sp,-32
    80003b28:	ec06                	sd	ra,24(sp)
    80003b2a:	e822                	sd	s0,16(sp)
    80003b2c:	e426                	sd	s1,8(sp)
    80003b2e:	e04a                	sd	s2,0(sp)
    80003b30:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b32:	c115                	beqz	a0,80003b56 <ilock+0x30>
    80003b34:	84aa                	mv	s1,a0
    80003b36:	451c                	lw	a5,8(a0)
    80003b38:	00f05f63          	blez	a5,80003b56 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b3c:	0541                	addi	a0,a0,16
    80003b3e:	00001097          	auipc	ra,0x1
    80003b42:	ca6080e7          	jalr	-858(ra) # 800047e4 <acquiresleep>
  if(ip->valid == 0){
    80003b46:	40bc                	lw	a5,64(s1)
    80003b48:	cf99                	beqz	a5,80003b66 <ilock+0x40>
}
    80003b4a:	60e2                	ld	ra,24(sp)
    80003b4c:	6442                	ld	s0,16(sp)
    80003b4e:	64a2                	ld	s1,8(sp)
    80003b50:	6902                	ld	s2,0(sp)
    80003b52:	6105                	addi	sp,sp,32
    80003b54:	8082                	ret
    panic("ilock");
    80003b56:	00005517          	auipc	a0,0x5
    80003b5a:	d1a50513          	addi	a0,a0,-742 # 80008870 <names+0x1a8>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	9e2080e7          	jalr	-1566(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b66:	40dc                	lw	a5,4(s1)
    80003b68:	0047d79b          	srliw	a5,a5,0x4
    80003b6c:	00245597          	auipc	a1,0x245
    80003b70:	a1c5a583          	lw	a1,-1508(a1) # 80248588 <sb+0x18>
    80003b74:	9dbd                	addw	a1,a1,a5
    80003b76:	4088                	lw	a0,0(s1)
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	796080e7          	jalr	1942(ra) # 8000330e <bread>
    80003b80:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b82:	05850593          	addi	a1,a0,88
    80003b86:	40dc                	lw	a5,4(s1)
    80003b88:	8bbd                	andi	a5,a5,15
    80003b8a:	079a                	slli	a5,a5,0x6
    80003b8c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b8e:	00059783          	lh	a5,0(a1)
    80003b92:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b96:	00259783          	lh	a5,2(a1)
    80003b9a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b9e:	00459783          	lh	a5,4(a1)
    80003ba2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ba6:	00659783          	lh	a5,6(a1)
    80003baa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bae:	459c                	lw	a5,8(a1)
    80003bb0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bb2:	03400613          	li	a2,52
    80003bb6:	05b1                	addi	a1,a1,12
    80003bb8:	05048513          	addi	a0,s1,80
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	2a8080e7          	jalr	680(ra) # 80000e64 <memmove>
    brelse(bp);
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	878080e7          	jalr	-1928(ra) # 8000343e <brelse>
    ip->valid = 1;
    80003bce:	4785                	li	a5,1
    80003bd0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bd2:	04449783          	lh	a5,68(s1)
    80003bd6:	fbb5                	bnez	a5,80003b4a <ilock+0x24>
      panic("ilock: no type");
    80003bd8:	00005517          	auipc	a0,0x5
    80003bdc:	ca050513          	addi	a0,a0,-864 # 80008878 <names+0x1b0>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	960080e7          	jalr	-1696(ra) # 80000540 <panic>

0000000080003be8 <iunlock>:
{
    80003be8:	1101                	addi	sp,sp,-32
    80003bea:	ec06                	sd	ra,24(sp)
    80003bec:	e822                	sd	s0,16(sp)
    80003bee:	e426                	sd	s1,8(sp)
    80003bf0:	e04a                	sd	s2,0(sp)
    80003bf2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bf4:	c905                	beqz	a0,80003c24 <iunlock+0x3c>
    80003bf6:	84aa                	mv	s1,a0
    80003bf8:	01050913          	addi	s2,a0,16
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	c80080e7          	jalr	-896(ra) # 8000487e <holdingsleep>
    80003c06:	cd19                	beqz	a0,80003c24 <iunlock+0x3c>
    80003c08:	449c                	lw	a5,8(s1)
    80003c0a:	00f05d63          	blez	a5,80003c24 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c0e:	854a                	mv	a0,s2
    80003c10:	00001097          	auipc	ra,0x1
    80003c14:	c2a080e7          	jalr	-982(ra) # 8000483a <releasesleep>
}
    80003c18:	60e2                	ld	ra,24(sp)
    80003c1a:	6442                	ld	s0,16(sp)
    80003c1c:	64a2                	ld	s1,8(sp)
    80003c1e:	6902                	ld	s2,0(sp)
    80003c20:	6105                	addi	sp,sp,32
    80003c22:	8082                	ret
    panic("iunlock");
    80003c24:	00005517          	auipc	a0,0x5
    80003c28:	c6450513          	addi	a0,a0,-924 # 80008888 <names+0x1c0>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	914080e7          	jalr	-1772(ra) # 80000540 <panic>

0000000080003c34 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c34:	7179                	addi	sp,sp,-48
    80003c36:	f406                	sd	ra,40(sp)
    80003c38:	f022                	sd	s0,32(sp)
    80003c3a:	ec26                	sd	s1,24(sp)
    80003c3c:	e84a                	sd	s2,16(sp)
    80003c3e:	e44e                	sd	s3,8(sp)
    80003c40:	e052                	sd	s4,0(sp)
    80003c42:	1800                	addi	s0,sp,48
    80003c44:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c46:	05050493          	addi	s1,a0,80
    80003c4a:	08050913          	addi	s2,a0,128
    80003c4e:	a021                	j	80003c56 <itrunc+0x22>
    80003c50:	0491                	addi	s1,s1,4
    80003c52:	01248d63          	beq	s1,s2,80003c6c <itrunc+0x38>
    if(ip->addrs[i]){
    80003c56:	408c                	lw	a1,0(s1)
    80003c58:	dde5                	beqz	a1,80003c50 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c5a:	0009a503          	lw	a0,0(s3)
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	8f6080e7          	jalr	-1802(ra) # 80003554 <bfree>
      ip->addrs[i] = 0;
    80003c66:	0004a023          	sw	zero,0(s1)
    80003c6a:	b7dd                	j	80003c50 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c6c:	0809a583          	lw	a1,128(s3)
    80003c70:	e185                	bnez	a1,80003c90 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c72:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c76:	854e                	mv	a0,s3
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	de2080e7          	jalr	-542(ra) # 80003a5a <iupdate>
}
    80003c80:	70a2                	ld	ra,40(sp)
    80003c82:	7402                	ld	s0,32(sp)
    80003c84:	64e2                	ld	s1,24(sp)
    80003c86:	6942                	ld	s2,16(sp)
    80003c88:	69a2                	ld	s3,8(sp)
    80003c8a:	6a02                	ld	s4,0(sp)
    80003c8c:	6145                	addi	sp,sp,48
    80003c8e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c90:	0009a503          	lw	a0,0(s3)
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	67a080e7          	jalr	1658(ra) # 8000330e <bread>
    80003c9c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c9e:	05850493          	addi	s1,a0,88
    80003ca2:	45850913          	addi	s2,a0,1112
    80003ca6:	a021                	j	80003cae <itrunc+0x7a>
    80003ca8:	0491                	addi	s1,s1,4
    80003caa:	01248b63          	beq	s1,s2,80003cc0 <itrunc+0x8c>
      if(a[j])
    80003cae:	408c                	lw	a1,0(s1)
    80003cb0:	dde5                	beqz	a1,80003ca8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003cb2:	0009a503          	lw	a0,0(s3)
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	89e080e7          	jalr	-1890(ra) # 80003554 <bfree>
    80003cbe:	b7ed                	j	80003ca8 <itrunc+0x74>
    brelse(bp);
    80003cc0:	8552                	mv	a0,s4
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	77c080e7          	jalr	1916(ra) # 8000343e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cca:	0809a583          	lw	a1,128(s3)
    80003cce:	0009a503          	lw	a0,0(s3)
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	882080e7          	jalr	-1918(ra) # 80003554 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cda:	0809a023          	sw	zero,128(s3)
    80003cde:	bf51                	j	80003c72 <itrunc+0x3e>

0000000080003ce0 <iput>:
{
    80003ce0:	1101                	addi	sp,sp,-32
    80003ce2:	ec06                	sd	ra,24(sp)
    80003ce4:	e822                	sd	s0,16(sp)
    80003ce6:	e426                	sd	s1,8(sp)
    80003ce8:	e04a                	sd	s2,0(sp)
    80003cea:	1000                	addi	s0,sp,32
    80003cec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cee:	00245517          	auipc	a0,0x245
    80003cf2:	8a250513          	addi	a0,a0,-1886 # 80248590 <itable>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	016080e7          	jalr	22(ra) # 80000d0c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cfe:	4498                	lw	a4,8(s1)
    80003d00:	4785                	li	a5,1
    80003d02:	02f70363          	beq	a4,a5,80003d28 <iput+0x48>
  ip->ref--;
    80003d06:	449c                	lw	a5,8(s1)
    80003d08:	37fd                	addiw	a5,a5,-1
    80003d0a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d0c:	00245517          	auipc	a0,0x245
    80003d10:	88450513          	addi	a0,a0,-1916 # 80248590 <itable>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	0ac080e7          	jalr	172(ra) # 80000dc0 <release>
}
    80003d1c:	60e2                	ld	ra,24(sp)
    80003d1e:	6442                	ld	s0,16(sp)
    80003d20:	64a2                	ld	s1,8(sp)
    80003d22:	6902                	ld	s2,0(sp)
    80003d24:	6105                	addi	sp,sp,32
    80003d26:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d28:	40bc                	lw	a5,64(s1)
    80003d2a:	dff1                	beqz	a5,80003d06 <iput+0x26>
    80003d2c:	04a49783          	lh	a5,74(s1)
    80003d30:	fbf9                	bnez	a5,80003d06 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d32:	01048913          	addi	s2,s1,16
    80003d36:	854a                	mv	a0,s2
    80003d38:	00001097          	auipc	ra,0x1
    80003d3c:	aac080e7          	jalr	-1364(ra) # 800047e4 <acquiresleep>
    release(&itable.lock);
    80003d40:	00245517          	auipc	a0,0x245
    80003d44:	85050513          	addi	a0,a0,-1968 # 80248590 <itable>
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	078080e7          	jalr	120(ra) # 80000dc0 <release>
    itrunc(ip);
    80003d50:	8526                	mv	a0,s1
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	ee2080e7          	jalr	-286(ra) # 80003c34 <itrunc>
    ip->type = 0;
    80003d5a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d5e:	8526                	mv	a0,s1
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	cfa080e7          	jalr	-774(ra) # 80003a5a <iupdate>
    ip->valid = 0;
    80003d68:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d6c:	854a                	mv	a0,s2
    80003d6e:	00001097          	auipc	ra,0x1
    80003d72:	acc080e7          	jalr	-1332(ra) # 8000483a <releasesleep>
    acquire(&itable.lock);
    80003d76:	00245517          	auipc	a0,0x245
    80003d7a:	81a50513          	addi	a0,a0,-2022 # 80248590 <itable>
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	f8e080e7          	jalr	-114(ra) # 80000d0c <acquire>
    80003d86:	b741                	j	80003d06 <iput+0x26>

0000000080003d88 <iunlockput>:
{
    80003d88:	1101                	addi	sp,sp,-32
    80003d8a:	ec06                	sd	ra,24(sp)
    80003d8c:	e822                	sd	s0,16(sp)
    80003d8e:	e426                	sd	s1,8(sp)
    80003d90:	1000                	addi	s0,sp,32
    80003d92:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	e54080e7          	jalr	-428(ra) # 80003be8 <iunlock>
  iput(ip);
    80003d9c:	8526                	mv	a0,s1
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	f42080e7          	jalr	-190(ra) # 80003ce0 <iput>
}
    80003da6:	60e2                	ld	ra,24(sp)
    80003da8:	6442                	ld	s0,16(sp)
    80003daa:	64a2                	ld	s1,8(sp)
    80003dac:	6105                	addi	sp,sp,32
    80003dae:	8082                	ret

0000000080003db0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stats *st)
{
    80003db0:	1141                	addi	sp,sp,-16
    80003db2:	e422                	sd	s0,8(sp)
    80003db4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003db6:	411c                	lw	a5,0(a0)
    80003db8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dba:	415c                	lw	a5,4(a0)
    80003dbc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dbe:	04451783          	lh	a5,68(a0)
    80003dc2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003dc6:	04a51783          	lh	a5,74(a0)
    80003dca:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dce:	457c                	lw	a5,76(a0)
    80003dd0:	c5dc                	sw	a5,12(a1)
}
    80003dd2:	6422                	ld	s0,8(sp)
    80003dd4:	0141                	addi	sp,sp,16
    80003dd6:	8082                	ret

0000000080003dd8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dd8:	457c                	lw	a5,76(a0)
    80003dda:	0ed7e963          	bltu	a5,a3,80003ecc <readi+0xf4>
{
    80003dde:	7159                	addi	sp,sp,-112
    80003de0:	f486                	sd	ra,104(sp)
    80003de2:	f0a2                	sd	s0,96(sp)
    80003de4:	eca6                	sd	s1,88(sp)
    80003de6:	e8ca                	sd	s2,80(sp)
    80003de8:	e4ce                	sd	s3,72(sp)
    80003dea:	e0d2                	sd	s4,64(sp)
    80003dec:	fc56                	sd	s5,56(sp)
    80003dee:	f85a                	sd	s6,48(sp)
    80003df0:	f45e                	sd	s7,40(sp)
    80003df2:	f062                	sd	s8,32(sp)
    80003df4:	ec66                	sd	s9,24(sp)
    80003df6:	e86a                	sd	s10,16(sp)
    80003df8:	e46e                	sd	s11,8(sp)
    80003dfa:	1880                	addi	s0,sp,112
    80003dfc:	8b2a                	mv	s6,a0
    80003dfe:	8bae                	mv	s7,a1
    80003e00:	8a32                	mv	s4,a2
    80003e02:	84b6                	mv	s1,a3
    80003e04:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e06:	9f35                	addw	a4,a4,a3
    return 0;
    80003e08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e0a:	0ad76063          	bltu	a4,a3,80003eaa <readi+0xd2>
  if(off + n > ip->size)
    80003e0e:	00e7f463          	bgeu	a5,a4,80003e16 <readi+0x3e>
    n = ip->size - off;
    80003e12:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e16:	0a0a8963          	beqz	s5,80003ec8 <readi+0xf0>
    80003e1a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e1c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e20:	5c7d                	li	s8,-1
    80003e22:	a82d                	j	80003e5c <readi+0x84>
    80003e24:	020d1d93          	slli	s11,s10,0x20
    80003e28:	020ddd93          	srli	s11,s11,0x20
    80003e2c:	05890613          	addi	a2,s2,88
    80003e30:	86ee                	mv	a3,s11
    80003e32:	963a                	add	a2,a2,a4
    80003e34:	85d2                	mv	a1,s4
    80003e36:	855e                	mv	a0,s7
    80003e38:	ffffe097          	auipc	ra,0xffffe
    80003e3c:	78a080e7          	jalr	1930(ra) # 800025c2 <either_copyout>
    80003e40:	05850d63          	beq	a0,s8,80003e9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e44:	854a                	mv	a0,s2
    80003e46:	fffff097          	auipc	ra,0xfffff
    80003e4a:	5f8080e7          	jalr	1528(ra) # 8000343e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e4e:	013d09bb          	addw	s3,s10,s3
    80003e52:	009d04bb          	addw	s1,s10,s1
    80003e56:	9a6e                	add	s4,s4,s11
    80003e58:	0559f763          	bgeu	s3,s5,80003ea6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e5c:	00a4d59b          	srliw	a1,s1,0xa
    80003e60:	855a                	mv	a0,s6
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	8a0080e7          	jalr	-1888(ra) # 80003702 <bmap>
    80003e6a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e6e:	cd85                	beqz	a1,80003ea6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e70:	000b2503          	lw	a0,0(s6)
    80003e74:	fffff097          	auipc	ra,0xfffff
    80003e78:	49a080e7          	jalr	1178(ra) # 8000330e <bread>
    80003e7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e7e:	3ff4f713          	andi	a4,s1,1023
    80003e82:	40ec87bb          	subw	a5,s9,a4
    80003e86:	413a86bb          	subw	a3,s5,s3
    80003e8a:	8d3e                	mv	s10,a5
    80003e8c:	2781                	sext.w	a5,a5
    80003e8e:	0006861b          	sext.w	a2,a3
    80003e92:	f8f679e3          	bgeu	a2,a5,80003e24 <readi+0x4c>
    80003e96:	8d36                	mv	s10,a3
    80003e98:	b771                	j	80003e24 <readi+0x4c>
      brelse(bp);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	5a2080e7          	jalr	1442(ra) # 8000343e <brelse>
      tot = -1;
    80003ea4:	59fd                	li	s3,-1
  }
  return tot;
    80003ea6:	0009851b          	sext.w	a0,s3
}
    80003eaa:	70a6                	ld	ra,104(sp)
    80003eac:	7406                	ld	s0,96(sp)
    80003eae:	64e6                	ld	s1,88(sp)
    80003eb0:	6946                	ld	s2,80(sp)
    80003eb2:	69a6                	ld	s3,72(sp)
    80003eb4:	6a06                	ld	s4,64(sp)
    80003eb6:	7ae2                	ld	s5,56(sp)
    80003eb8:	7b42                	ld	s6,48(sp)
    80003eba:	7ba2                	ld	s7,40(sp)
    80003ebc:	7c02                	ld	s8,32(sp)
    80003ebe:	6ce2                	ld	s9,24(sp)
    80003ec0:	6d42                	ld	s10,16(sp)
    80003ec2:	6da2                	ld	s11,8(sp)
    80003ec4:	6165                	addi	sp,sp,112
    80003ec6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec8:	89d6                	mv	s3,s5
    80003eca:	bff1                	j	80003ea6 <readi+0xce>
    return 0;
    80003ecc:	4501                	li	a0,0
}
    80003ece:	8082                	ret

0000000080003ed0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ed0:	457c                	lw	a5,76(a0)
    80003ed2:	10d7e863          	bltu	a5,a3,80003fe2 <writei+0x112>
{
    80003ed6:	7159                	addi	sp,sp,-112
    80003ed8:	f486                	sd	ra,104(sp)
    80003eda:	f0a2                	sd	s0,96(sp)
    80003edc:	eca6                	sd	s1,88(sp)
    80003ede:	e8ca                	sd	s2,80(sp)
    80003ee0:	e4ce                	sd	s3,72(sp)
    80003ee2:	e0d2                	sd	s4,64(sp)
    80003ee4:	fc56                	sd	s5,56(sp)
    80003ee6:	f85a                	sd	s6,48(sp)
    80003ee8:	f45e                	sd	s7,40(sp)
    80003eea:	f062                	sd	s8,32(sp)
    80003eec:	ec66                	sd	s9,24(sp)
    80003eee:	e86a                	sd	s10,16(sp)
    80003ef0:	e46e                	sd	s11,8(sp)
    80003ef2:	1880                	addi	s0,sp,112
    80003ef4:	8aaa                	mv	s5,a0
    80003ef6:	8bae                	mv	s7,a1
    80003ef8:	8a32                	mv	s4,a2
    80003efa:	8936                	mv	s2,a3
    80003efc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003efe:	00e687bb          	addw	a5,a3,a4
    80003f02:	0ed7e263          	bltu	a5,a3,80003fe6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f06:	00043737          	lui	a4,0x43
    80003f0a:	0ef76063          	bltu	a4,a5,80003fea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f0e:	0c0b0863          	beqz	s6,80003fde <writei+0x10e>
    80003f12:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f14:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f18:	5c7d                	li	s8,-1
    80003f1a:	a091                	j	80003f5e <writei+0x8e>
    80003f1c:	020d1d93          	slli	s11,s10,0x20
    80003f20:	020ddd93          	srli	s11,s11,0x20
    80003f24:	05848513          	addi	a0,s1,88
    80003f28:	86ee                	mv	a3,s11
    80003f2a:	8652                	mv	a2,s4
    80003f2c:	85de                	mv	a1,s7
    80003f2e:	953a                	add	a0,a0,a4
    80003f30:	ffffe097          	auipc	ra,0xffffe
    80003f34:	6e8080e7          	jalr	1768(ra) # 80002618 <either_copyin>
    80003f38:	07850263          	beq	a0,s8,80003f9c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f3c:	8526                	mv	a0,s1
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	788080e7          	jalr	1928(ra) # 800046c6 <log_write>
    brelse(bp);
    80003f46:	8526                	mv	a0,s1
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	4f6080e7          	jalr	1270(ra) # 8000343e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f50:	013d09bb          	addw	s3,s10,s3
    80003f54:	012d093b          	addw	s2,s10,s2
    80003f58:	9a6e                	add	s4,s4,s11
    80003f5a:	0569f663          	bgeu	s3,s6,80003fa6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f5e:	00a9559b          	srliw	a1,s2,0xa
    80003f62:	8556                	mv	a0,s5
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	79e080e7          	jalr	1950(ra) # 80003702 <bmap>
    80003f6c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f70:	c99d                	beqz	a1,80003fa6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f72:	000aa503          	lw	a0,0(s5)
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	398080e7          	jalr	920(ra) # 8000330e <bread>
    80003f7e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f80:	3ff97713          	andi	a4,s2,1023
    80003f84:	40ec87bb          	subw	a5,s9,a4
    80003f88:	413b06bb          	subw	a3,s6,s3
    80003f8c:	8d3e                	mv	s10,a5
    80003f8e:	2781                	sext.w	a5,a5
    80003f90:	0006861b          	sext.w	a2,a3
    80003f94:	f8f674e3          	bgeu	a2,a5,80003f1c <writei+0x4c>
    80003f98:	8d36                	mv	s10,a3
    80003f9a:	b749                	j	80003f1c <writei+0x4c>
      brelse(bp);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	4a0080e7          	jalr	1184(ra) # 8000343e <brelse>
  }

  if(off > ip->size)
    80003fa6:	04caa783          	lw	a5,76(s5)
    80003faa:	0127f463          	bgeu	a5,s2,80003fb2 <writei+0xe2>
    ip->size = off;
    80003fae:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fb2:	8556                	mv	a0,s5
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	aa6080e7          	jalr	-1370(ra) # 80003a5a <iupdate>

  return tot;
    80003fbc:	0009851b          	sext.w	a0,s3
}
    80003fc0:	70a6                	ld	ra,104(sp)
    80003fc2:	7406                	ld	s0,96(sp)
    80003fc4:	64e6                	ld	s1,88(sp)
    80003fc6:	6946                	ld	s2,80(sp)
    80003fc8:	69a6                	ld	s3,72(sp)
    80003fca:	6a06                	ld	s4,64(sp)
    80003fcc:	7ae2                	ld	s5,56(sp)
    80003fce:	7b42                	ld	s6,48(sp)
    80003fd0:	7ba2                	ld	s7,40(sp)
    80003fd2:	7c02                	ld	s8,32(sp)
    80003fd4:	6ce2                	ld	s9,24(sp)
    80003fd6:	6d42                	ld	s10,16(sp)
    80003fd8:	6da2                	ld	s11,8(sp)
    80003fda:	6165                	addi	sp,sp,112
    80003fdc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fde:	89da                	mv	s3,s6
    80003fe0:	bfc9                	j	80003fb2 <writei+0xe2>
    return -1;
    80003fe2:	557d                	li	a0,-1
}
    80003fe4:	8082                	ret
    return -1;
    80003fe6:	557d                	li	a0,-1
    80003fe8:	bfe1                	j	80003fc0 <writei+0xf0>
    return -1;
    80003fea:	557d                	li	a0,-1
    80003fec:	bfd1                	j	80003fc0 <writei+0xf0>

0000000080003fee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fee:	1141                	addi	sp,sp,-16
    80003ff0:	e406                	sd	ra,8(sp)
    80003ff2:	e022                	sd	s0,0(sp)
    80003ff4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ff6:	4639                	li	a2,14
    80003ff8:	ffffd097          	auipc	ra,0xffffd
    80003ffc:	ee0080e7          	jalr	-288(ra) # 80000ed8 <strncmp>
}
    80004000:	60a2                	ld	ra,8(sp)
    80004002:	6402                	ld	s0,0(sp)
    80004004:	0141                	addi	sp,sp,16
    80004006:	8082                	ret

0000000080004008 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004008:	7139                	addi	sp,sp,-64
    8000400a:	fc06                	sd	ra,56(sp)
    8000400c:	f822                	sd	s0,48(sp)
    8000400e:	f426                	sd	s1,40(sp)
    80004010:	f04a                	sd	s2,32(sp)
    80004012:	ec4e                	sd	s3,24(sp)
    80004014:	e852                	sd	s4,16(sp)
    80004016:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004018:	04451703          	lh	a4,68(a0)
    8000401c:	4785                	li	a5,1
    8000401e:	00f71a63          	bne	a4,a5,80004032 <dirlookup+0x2a>
    80004022:	892a                	mv	s2,a0
    80004024:	89ae                	mv	s3,a1
    80004026:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004028:	457c                	lw	a5,76(a0)
    8000402a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000402c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000402e:	e79d                	bnez	a5,8000405c <dirlookup+0x54>
    80004030:	a8a5                	j	800040a8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004032:	00005517          	auipc	a0,0x5
    80004036:	85e50513          	addi	a0,a0,-1954 # 80008890 <names+0x1c8>
    8000403a:	ffffc097          	auipc	ra,0xffffc
    8000403e:	506080e7          	jalr	1286(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004042:	00005517          	auipc	a0,0x5
    80004046:	86650513          	addi	a0,a0,-1946 # 800088a8 <names+0x1e0>
    8000404a:	ffffc097          	auipc	ra,0xffffc
    8000404e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004052:	24c1                	addiw	s1,s1,16
    80004054:	04c92783          	lw	a5,76(s2)
    80004058:	04f4f763          	bgeu	s1,a5,800040a6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000405c:	4741                	li	a4,16
    8000405e:	86a6                	mv	a3,s1
    80004060:	fc040613          	addi	a2,s0,-64
    80004064:	4581                	li	a1,0
    80004066:	854a                	mv	a0,s2
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	d70080e7          	jalr	-656(ra) # 80003dd8 <readi>
    80004070:	47c1                	li	a5,16
    80004072:	fcf518e3          	bne	a0,a5,80004042 <dirlookup+0x3a>
    if(de.inum == 0)
    80004076:	fc045783          	lhu	a5,-64(s0)
    8000407a:	dfe1                	beqz	a5,80004052 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000407c:	fc240593          	addi	a1,s0,-62
    80004080:	854e                	mv	a0,s3
    80004082:	00000097          	auipc	ra,0x0
    80004086:	f6c080e7          	jalr	-148(ra) # 80003fee <namecmp>
    8000408a:	f561                	bnez	a0,80004052 <dirlookup+0x4a>
      if(poff)
    8000408c:	000a0463          	beqz	s4,80004094 <dirlookup+0x8c>
        *poff = off;
    80004090:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004094:	fc045583          	lhu	a1,-64(s0)
    80004098:	00092503          	lw	a0,0(s2)
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	750080e7          	jalr	1872(ra) # 800037ec <iget>
    800040a4:	a011                	j	800040a8 <dirlookup+0xa0>
  return 0;
    800040a6:	4501                	li	a0,0
}
    800040a8:	70e2                	ld	ra,56(sp)
    800040aa:	7442                	ld	s0,48(sp)
    800040ac:	74a2                	ld	s1,40(sp)
    800040ae:	7902                	ld	s2,32(sp)
    800040b0:	69e2                	ld	s3,24(sp)
    800040b2:	6a42                	ld	s4,16(sp)
    800040b4:	6121                	addi	sp,sp,64
    800040b6:	8082                	ret

00000000800040b8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040b8:	711d                	addi	sp,sp,-96
    800040ba:	ec86                	sd	ra,88(sp)
    800040bc:	e8a2                	sd	s0,80(sp)
    800040be:	e4a6                	sd	s1,72(sp)
    800040c0:	e0ca                	sd	s2,64(sp)
    800040c2:	fc4e                	sd	s3,56(sp)
    800040c4:	f852                	sd	s4,48(sp)
    800040c6:	f456                	sd	s5,40(sp)
    800040c8:	f05a                	sd	s6,32(sp)
    800040ca:	ec5e                	sd	s7,24(sp)
    800040cc:	e862                	sd	s8,16(sp)
    800040ce:	e466                	sd	s9,8(sp)
    800040d0:	e06a                	sd	s10,0(sp)
    800040d2:	1080                	addi	s0,sp,96
    800040d4:	84aa                	mv	s1,a0
    800040d6:	8b2e                	mv	s6,a1
    800040d8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040da:	00054703          	lbu	a4,0(a0)
    800040de:	02f00793          	li	a5,47
    800040e2:	02f70363          	beq	a4,a5,80004108 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040e6:	ffffe097          	auipc	ra,0xffffe
    800040ea:	a16080e7          	jalr	-1514(ra) # 80001afc <myproc>
    800040ee:	15853503          	ld	a0,344(a0)
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	9f6080e7          	jalr	-1546(ra) # 80003ae8 <idup>
    800040fa:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040fc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004100:	4cb5                	li	s9,13
  len = path - s;
    80004102:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004104:	4c05                	li	s8,1
    80004106:	a87d                	j	800041c4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004108:	4585                	li	a1,1
    8000410a:	4505                	li	a0,1
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	6e0080e7          	jalr	1760(ra) # 800037ec <iget>
    80004114:	8a2a                	mv	s4,a0
    80004116:	b7dd                	j	800040fc <namex+0x44>
      iunlockput(ip);
    80004118:	8552                	mv	a0,s4
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	c6e080e7          	jalr	-914(ra) # 80003d88 <iunlockput>
      return 0;
    80004122:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004124:	8552                	mv	a0,s4
    80004126:	60e6                	ld	ra,88(sp)
    80004128:	6446                	ld	s0,80(sp)
    8000412a:	64a6                	ld	s1,72(sp)
    8000412c:	6906                	ld	s2,64(sp)
    8000412e:	79e2                	ld	s3,56(sp)
    80004130:	7a42                	ld	s4,48(sp)
    80004132:	7aa2                	ld	s5,40(sp)
    80004134:	7b02                	ld	s6,32(sp)
    80004136:	6be2                	ld	s7,24(sp)
    80004138:	6c42                	ld	s8,16(sp)
    8000413a:	6ca2                	ld	s9,8(sp)
    8000413c:	6d02                	ld	s10,0(sp)
    8000413e:	6125                	addi	sp,sp,96
    80004140:	8082                	ret
      iunlock(ip);
    80004142:	8552                	mv	a0,s4
    80004144:	00000097          	auipc	ra,0x0
    80004148:	aa4080e7          	jalr	-1372(ra) # 80003be8 <iunlock>
      return ip;
    8000414c:	bfe1                	j	80004124 <namex+0x6c>
      iunlockput(ip);
    8000414e:	8552                	mv	a0,s4
    80004150:	00000097          	auipc	ra,0x0
    80004154:	c38080e7          	jalr	-968(ra) # 80003d88 <iunlockput>
      return 0;
    80004158:	8a4e                	mv	s4,s3
    8000415a:	b7e9                	j	80004124 <namex+0x6c>
  len = path - s;
    8000415c:	40998633          	sub	a2,s3,s1
    80004160:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004164:	09acd863          	bge	s9,s10,800041f4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004168:	4639                	li	a2,14
    8000416a:	85a6                	mv	a1,s1
    8000416c:	8556                	mv	a0,s5
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	cf6080e7          	jalr	-778(ra) # 80000e64 <memmove>
    80004176:	84ce                	mv	s1,s3
  while(*path == '/')
    80004178:	0004c783          	lbu	a5,0(s1)
    8000417c:	01279763          	bne	a5,s2,8000418a <namex+0xd2>
    path++;
    80004180:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004182:	0004c783          	lbu	a5,0(s1)
    80004186:	ff278de3          	beq	a5,s2,80004180 <namex+0xc8>
    ilock(ip);
    8000418a:	8552                	mv	a0,s4
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	99a080e7          	jalr	-1638(ra) # 80003b26 <ilock>
    if(ip->type != T_DIR){
    80004194:	044a1783          	lh	a5,68(s4)
    80004198:	f98790e3          	bne	a5,s8,80004118 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000419c:	000b0563          	beqz	s6,800041a6 <namex+0xee>
    800041a0:	0004c783          	lbu	a5,0(s1)
    800041a4:	dfd9                	beqz	a5,80004142 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041a6:	865e                	mv	a2,s7
    800041a8:	85d6                	mv	a1,s5
    800041aa:	8552                	mv	a0,s4
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	e5c080e7          	jalr	-420(ra) # 80004008 <dirlookup>
    800041b4:	89aa                	mv	s3,a0
    800041b6:	dd41                	beqz	a0,8000414e <namex+0x96>
    iunlockput(ip);
    800041b8:	8552                	mv	a0,s4
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	bce080e7          	jalr	-1074(ra) # 80003d88 <iunlockput>
    ip = next;
    800041c2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041c4:	0004c783          	lbu	a5,0(s1)
    800041c8:	01279763          	bne	a5,s2,800041d6 <namex+0x11e>
    path++;
    800041cc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ce:	0004c783          	lbu	a5,0(s1)
    800041d2:	ff278de3          	beq	a5,s2,800041cc <namex+0x114>
  if(*path == 0)
    800041d6:	cb9d                	beqz	a5,8000420c <namex+0x154>
  while(*path != '/' && *path != 0)
    800041d8:	0004c783          	lbu	a5,0(s1)
    800041dc:	89a6                	mv	s3,s1
  len = path - s;
    800041de:	8d5e                	mv	s10,s7
    800041e0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041e2:	01278963          	beq	a5,s2,800041f4 <namex+0x13c>
    800041e6:	dbbd                	beqz	a5,8000415c <namex+0xa4>
    path++;
    800041e8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041ea:	0009c783          	lbu	a5,0(s3)
    800041ee:	ff279ce3          	bne	a5,s2,800041e6 <namex+0x12e>
    800041f2:	b7ad                	j	8000415c <namex+0xa4>
    memmove(name, s, len);
    800041f4:	2601                	sext.w	a2,a2
    800041f6:	85a6                	mv	a1,s1
    800041f8:	8556                	mv	a0,s5
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	c6a080e7          	jalr	-918(ra) # 80000e64 <memmove>
    name[len] = 0;
    80004202:	9d56                	add	s10,s10,s5
    80004204:	000d0023          	sb	zero,0(s10)
    80004208:	84ce                	mv	s1,s3
    8000420a:	b7bd                	j	80004178 <namex+0xc0>
  if(nameiparent){
    8000420c:	f00b0ce3          	beqz	s6,80004124 <namex+0x6c>
    iput(ip);
    80004210:	8552                	mv	a0,s4
    80004212:	00000097          	auipc	ra,0x0
    80004216:	ace080e7          	jalr	-1330(ra) # 80003ce0 <iput>
    return 0;
    8000421a:	4a01                	li	s4,0
    8000421c:	b721                	j	80004124 <namex+0x6c>

000000008000421e <dirlink>:
{
    8000421e:	7139                	addi	sp,sp,-64
    80004220:	fc06                	sd	ra,56(sp)
    80004222:	f822                	sd	s0,48(sp)
    80004224:	f426                	sd	s1,40(sp)
    80004226:	f04a                	sd	s2,32(sp)
    80004228:	ec4e                	sd	s3,24(sp)
    8000422a:	e852                	sd	s4,16(sp)
    8000422c:	0080                	addi	s0,sp,64
    8000422e:	892a                	mv	s2,a0
    80004230:	8a2e                	mv	s4,a1
    80004232:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004234:	4601                	li	a2,0
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	dd2080e7          	jalr	-558(ra) # 80004008 <dirlookup>
    8000423e:	e93d                	bnez	a0,800042b4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004240:	04c92483          	lw	s1,76(s2)
    80004244:	c49d                	beqz	s1,80004272 <dirlink+0x54>
    80004246:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004248:	4741                	li	a4,16
    8000424a:	86a6                	mv	a3,s1
    8000424c:	fc040613          	addi	a2,s0,-64
    80004250:	4581                	li	a1,0
    80004252:	854a                	mv	a0,s2
    80004254:	00000097          	auipc	ra,0x0
    80004258:	b84080e7          	jalr	-1148(ra) # 80003dd8 <readi>
    8000425c:	47c1                	li	a5,16
    8000425e:	06f51163          	bne	a0,a5,800042c0 <dirlink+0xa2>
    if(de.inum == 0)
    80004262:	fc045783          	lhu	a5,-64(s0)
    80004266:	c791                	beqz	a5,80004272 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004268:	24c1                	addiw	s1,s1,16
    8000426a:	04c92783          	lw	a5,76(s2)
    8000426e:	fcf4ede3          	bltu	s1,a5,80004248 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004272:	4639                	li	a2,14
    80004274:	85d2                	mv	a1,s4
    80004276:	fc240513          	addi	a0,s0,-62
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	c9a080e7          	jalr	-870(ra) # 80000f14 <strncpy>
  de.inum = inum;
    80004282:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004286:	4741                	li	a4,16
    80004288:	86a6                	mv	a3,s1
    8000428a:	fc040613          	addi	a2,s0,-64
    8000428e:	4581                	li	a1,0
    80004290:	854a                	mv	a0,s2
    80004292:	00000097          	auipc	ra,0x0
    80004296:	c3e080e7          	jalr	-962(ra) # 80003ed0 <writei>
    8000429a:	1541                	addi	a0,a0,-16
    8000429c:	00a03533          	snez	a0,a0
    800042a0:	40a00533          	neg	a0,a0
}
    800042a4:	70e2                	ld	ra,56(sp)
    800042a6:	7442                	ld	s0,48(sp)
    800042a8:	74a2                	ld	s1,40(sp)
    800042aa:	7902                	ld	s2,32(sp)
    800042ac:	69e2                	ld	s3,24(sp)
    800042ae:	6a42                	ld	s4,16(sp)
    800042b0:	6121                	addi	sp,sp,64
    800042b2:	8082                	ret
    iput(ip);
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	a2c080e7          	jalr	-1492(ra) # 80003ce0 <iput>
    return -1;
    800042bc:	557d                	li	a0,-1
    800042be:	b7dd                	j	800042a4 <dirlink+0x86>
      panic("dirlink read");
    800042c0:	00004517          	auipc	a0,0x4
    800042c4:	5f850513          	addi	a0,a0,1528 # 800088b8 <names+0x1f0>
    800042c8:	ffffc097          	auipc	ra,0xffffc
    800042cc:	278080e7          	jalr	632(ra) # 80000540 <panic>

00000000800042d0 <namei>:

struct inode*
namei(char *path)
{
    800042d0:	1101                	addi	sp,sp,-32
    800042d2:	ec06                	sd	ra,24(sp)
    800042d4:	e822                	sd	s0,16(sp)
    800042d6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042d8:	fe040613          	addi	a2,s0,-32
    800042dc:	4581                	li	a1,0
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	dda080e7          	jalr	-550(ra) # 800040b8 <namex>
}
    800042e6:	60e2                	ld	ra,24(sp)
    800042e8:	6442                	ld	s0,16(sp)
    800042ea:	6105                	addi	sp,sp,32
    800042ec:	8082                	ret

00000000800042ee <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042ee:	1141                	addi	sp,sp,-16
    800042f0:	e406                	sd	ra,8(sp)
    800042f2:	e022                	sd	s0,0(sp)
    800042f4:	0800                	addi	s0,sp,16
    800042f6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042f8:	4585                	li	a1,1
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	dbe080e7          	jalr	-578(ra) # 800040b8 <namex>
}
    80004302:	60a2                	ld	ra,8(sp)
    80004304:	6402                	ld	s0,0(sp)
    80004306:	0141                	addi	sp,sp,16
    80004308:	8082                	ret

000000008000430a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	e04a                	sd	s2,0(sp)
    80004314:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004316:	00246917          	auipc	s2,0x246
    8000431a:	d2290913          	addi	s2,s2,-734 # 8024a038 <log>
    8000431e:	01892583          	lw	a1,24(s2)
    80004322:	02892503          	lw	a0,40(s2)
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	fe8080e7          	jalr	-24(ra) # 8000330e <bread>
    8000432e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004330:	02c92683          	lw	a3,44(s2)
    80004334:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004336:	02d05863          	blez	a3,80004366 <write_head+0x5c>
    8000433a:	00246797          	auipc	a5,0x246
    8000433e:	d2e78793          	addi	a5,a5,-722 # 8024a068 <log+0x30>
    80004342:	05c50713          	addi	a4,a0,92
    80004346:	36fd                	addiw	a3,a3,-1
    80004348:	02069613          	slli	a2,a3,0x20
    8000434c:	01e65693          	srli	a3,a2,0x1e
    80004350:	00246617          	auipc	a2,0x246
    80004354:	d1c60613          	addi	a2,a2,-740 # 8024a06c <log+0x34>
    80004358:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000435a:	4390                	lw	a2,0(a5)
    8000435c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000435e:	0791                	addi	a5,a5,4
    80004360:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004362:	fed79ce3          	bne	a5,a3,8000435a <write_head+0x50>
  }
  bwrite(buf);
    80004366:	8526                	mv	a0,s1
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	098080e7          	jalr	152(ra) # 80003400 <bwrite>
  brelse(buf);
    80004370:	8526                	mv	a0,s1
    80004372:	fffff097          	auipc	ra,0xfffff
    80004376:	0cc080e7          	jalr	204(ra) # 8000343e <brelse>
}
    8000437a:	60e2                	ld	ra,24(sp)
    8000437c:	6442                	ld	s0,16(sp)
    8000437e:	64a2                	ld	s1,8(sp)
    80004380:	6902                	ld	s2,0(sp)
    80004382:	6105                	addi	sp,sp,32
    80004384:	8082                	ret

0000000080004386 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004386:	00246797          	auipc	a5,0x246
    8000438a:	cde7a783          	lw	a5,-802(a5) # 8024a064 <log+0x2c>
    8000438e:	0af05d63          	blez	a5,80004448 <install_trans+0xc2>
{
    80004392:	7139                	addi	sp,sp,-64
    80004394:	fc06                	sd	ra,56(sp)
    80004396:	f822                	sd	s0,48(sp)
    80004398:	f426                	sd	s1,40(sp)
    8000439a:	f04a                	sd	s2,32(sp)
    8000439c:	ec4e                	sd	s3,24(sp)
    8000439e:	e852                	sd	s4,16(sp)
    800043a0:	e456                	sd	s5,8(sp)
    800043a2:	e05a                	sd	s6,0(sp)
    800043a4:	0080                	addi	s0,sp,64
    800043a6:	8b2a                	mv	s6,a0
    800043a8:	00246a97          	auipc	s5,0x246
    800043ac:	cc0a8a93          	addi	s5,s5,-832 # 8024a068 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043b2:	00246997          	auipc	s3,0x246
    800043b6:	c8698993          	addi	s3,s3,-890 # 8024a038 <log>
    800043ba:	a00d                	j	800043dc <install_trans+0x56>
    brelse(lbuf);
    800043bc:	854a                	mv	a0,s2
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	080080e7          	jalr	128(ra) # 8000343e <brelse>
    brelse(dbuf);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	076080e7          	jalr	118(ra) # 8000343e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	2a05                	addiw	s4,s4,1
    800043d2:	0a91                	addi	s5,s5,4
    800043d4:	02c9a783          	lw	a5,44(s3)
    800043d8:	04fa5e63          	bge	s4,a5,80004434 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043dc:	0189a583          	lw	a1,24(s3)
    800043e0:	014585bb          	addw	a1,a1,s4
    800043e4:	2585                	addiw	a1,a1,1
    800043e6:	0289a503          	lw	a0,40(s3)
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	f24080e7          	jalr	-220(ra) # 8000330e <bread>
    800043f2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043f4:	000aa583          	lw	a1,0(s5)
    800043f8:	0289a503          	lw	a0,40(s3)
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	f12080e7          	jalr	-238(ra) # 8000330e <bread>
    80004404:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004406:	40000613          	li	a2,1024
    8000440a:	05890593          	addi	a1,s2,88
    8000440e:	05850513          	addi	a0,a0,88
    80004412:	ffffd097          	auipc	ra,0xffffd
    80004416:	a52080e7          	jalr	-1454(ra) # 80000e64 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000441a:	8526                	mv	a0,s1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	fe4080e7          	jalr	-28(ra) # 80003400 <bwrite>
    if(recovering == 0)
    80004424:	f80b1ce3          	bnez	s6,800043bc <install_trans+0x36>
      bunpin(dbuf);
    80004428:	8526                	mv	a0,s1
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	0ee080e7          	jalr	238(ra) # 80003518 <bunpin>
    80004432:	b769                	j	800043bc <install_trans+0x36>
}
    80004434:	70e2                	ld	ra,56(sp)
    80004436:	7442                	ld	s0,48(sp)
    80004438:	74a2                	ld	s1,40(sp)
    8000443a:	7902                	ld	s2,32(sp)
    8000443c:	69e2                	ld	s3,24(sp)
    8000443e:	6a42                	ld	s4,16(sp)
    80004440:	6aa2                	ld	s5,8(sp)
    80004442:	6b02                	ld	s6,0(sp)
    80004444:	6121                	addi	sp,sp,64
    80004446:	8082                	ret
    80004448:	8082                	ret

000000008000444a <initlog>:
{
    8000444a:	7179                	addi	sp,sp,-48
    8000444c:	f406                	sd	ra,40(sp)
    8000444e:	f022                	sd	s0,32(sp)
    80004450:	ec26                	sd	s1,24(sp)
    80004452:	e84a                	sd	s2,16(sp)
    80004454:	e44e                	sd	s3,8(sp)
    80004456:	1800                	addi	s0,sp,48
    80004458:	892a                	mv	s2,a0
    8000445a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000445c:	00246497          	auipc	s1,0x246
    80004460:	bdc48493          	addi	s1,s1,-1060 # 8024a038 <log>
    80004464:	00004597          	auipc	a1,0x4
    80004468:	46458593          	addi	a1,a1,1124 # 800088c8 <names+0x200>
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	80e080e7          	jalr	-2034(ra) # 80000c7c <initlock>
  log.start = sb->logstart;
    80004476:	0149a583          	lw	a1,20(s3)
    8000447a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000447c:	0109a783          	lw	a5,16(s3)
    80004480:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004482:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004486:	854a                	mv	a0,s2
    80004488:	fffff097          	auipc	ra,0xfffff
    8000448c:	e86080e7          	jalr	-378(ra) # 8000330e <bread>
  log.lh.n = lh->n;
    80004490:	4d34                	lw	a3,88(a0)
    80004492:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004494:	02d05663          	blez	a3,800044c0 <initlog+0x76>
    80004498:	05c50793          	addi	a5,a0,92
    8000449c:	00246717          	auipc	a4,0x246
    800044a0:	bcc70713          	addi	a4,a4,-1076 # 8024a068 <log+0x30>
    800044a4:	36fd                	addiw	a3,a3,-1
    800044a6:	02069613          	slli	a2,a3,0x20
    800044aa:	01e65693          	srli	a3,a2,0x1e
    800044ae:	06050613          	addi	a2,a0,96
    800044b2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044b4:	4390                	lw	a2,0(a5)
    800044b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044b8:	0791                	addi	a5,a5,4
    800044ba:	0711                	addi	a4,a4,4
    800044bc:	fed79ce3          	bne	a5,a3,800044b4 <initlog+0x6a>
  brelse(buf);
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	f7e080e7          	jalr	-130(ra) # 8000343e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044c8:	4505                	li	a0,1
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	ebc080e7          	jalr	-324(ra) # 80004386 <install_trans>
  log.lh.n = 0;
    800044d2:	00246797          	auipc	a5,0x246
    800044d6:	b807a923          	sw	zero,-1134(a5) # 8024a064 <log+0x2c>
  write_head(); // clear the log
    800044da:	00000097          	auipc	ra,0x0
    800044de:	e30080e7          	jalr	-464(ra) # 8000430a <write_head>
}
    800044e2:	70a2                	ld	ra,40(sp)
    800044e4:	7402                	ld	s0,32(sp)
    800044e6:	64e2                	ld	s1,24(sp)
    800044e8:	6942                	ld	s2,16(sp)
    800044ea:	69a2                	ld	s3,8(sp)
    800044ec:	6145                	addi	sp,sp,48
    800044ee:	8082                	ret

00000000800044f0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044f0:	1101                	addi	sp,sp,-32
    800044f2:	ec06                	sd	ra,24(sp)
    800044f4:	e822                	sd	s0,16(sp)
    800044f6:	e426                	sd	s1,8(sp)
    800044f8:	e04a                	sd	s2,0(sp)
    800044fa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044fc:	00246517          	auipc	a0,0x246
    80004500:	b3c50513          	addi	a0,a0,-1220 # 8024a038 <log>
    80004504:	ffffd097          	auipc	ra,0xffffd
    80004508:	808080e7          	jalr	-2040(ra) # 80000d0c <acquire>
  while(1){
    if(log.committing){
    8000450c:	00246497          	auipc	s1,0x246
    80004510:	b2c48493          	addi	s1,s1,-1236 # 8024a038 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004514:	4979                	li	s2,30
    80004516:	a039                	j	80004524 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004518:	85a6                	mv	a1,s1
    8000451a:	8526                	mv	a0,s1
    8000451c:	ffffe097          	auipc	ra,0xffffe
    80004520:	c9e080e7          	jalr	-866(ra) # 800021ba <sleep>
    if(log.committing){
    80004524:	50dc                	lw	a5,36(s1)
    80004526:	fbed                	bnez	a5,80004518 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004528:	5098                	lw	a4,32(s1)
    8000452a:	2705                	addiw	a4,a4,1
    8000452c:	0007069b          	sext.w	a3,a4
    80004530:	0027179b          	slliw	a5,a4,0x2
    80004534:	9fb9                	addw	a5,a5,a4
    80004536:	0017979b          	slliw	a5,a5,0x1
    8000453a:	54d8                	lw	a4,44(s1)
    8000453c:	9fb9                	addw	a5,a5,a4
    8000453e:	00f95963          	bge	s2,a5,80004550 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004542:	85a6                	mv	a1,s1
    80004544:	8526                	mv	a0,s1
    80004546:	ffffe097          	auipc	ra,0xffffe
    8000454a:	c74080e7          	jalr	-908(ra) # 800021ba <sleep>
    8000454e:	bfd9                	j	80004524 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004550:	00246517          	auipc	a0,0x246
    80004554:	ae850513          	addi	a0,a0,-1304 # 8024a038 <log>
    80004558:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000455a:	ffffd097          	auipc	ra,0xffffd
    8000455e:	866080e7          	jalr	-1946(ra) # 80000dc0 <release>
      break;
    }
  }
}
    80004562:	60e2                	ld	ra,24(sp)
    80004564:	6442                	ld	s0,16(sp)
    80004566:	64a2                	ld	s1,8(sp)
    80004568:	6902                	ld	s2,0(sp)
    8000456a:	6105                	addi	sp,sp,32
    8000456c:	8082                	ret

000000008000456e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000456e:	7139                	addi	sp,sp,-64
    80004570:	fc06                	sd	ra,56(sp)
    80004572:	f822                	sd	s0,48(sp)
    80004574:	f426                	sd	s1,40(sp)
    80004576:	f04a                	sd	s2,32(sp)
    80004578:	ec4e                	sd	s3,24(sp)
    8000457a:	e852                	sd	s4,16(sp)
    8000457c:	e456                	sd	s5,8(sp)
    8000457e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004580:	00246497          	auipc	s1,0x246
    80004584:	ab848493          	addi	s1,s1,-1352 # 8024a038 <log>
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	782080e7          	jalr	1922(ra) # 80000d0c <acquire>
  log.outstanding -= 1;
    80004592:	509c                	lw	a5,32(s1)
    80004594:	37fd                	addiw	a5,a5,-1
    80004596:	0007891b          	sext.w	s2,a5
    8000459a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000459c:	50dc                	lw	a5,36(s1)
    8000459e:	e7b9                	bnez	a5,800045ec <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045a0:	04091e63          	bnez	s2,800045fc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045a4:	00246497          	auipc	s1,0x246
    800045a8:	a9448493          	addi	s1,s1,-1388 # 8024a038 <log>
    800045ac:	4785                	li	a5,1
    800045ae:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045b0:	8526                	mv	a0,s1
    800045b2:	ffffd097          	auipc	ra,0xffffd
    800045b6:	80e080e7          	jalr	-2034(ra) # 80000dc0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045ba:	54dc                	lw	a5,44(s1)
    800045bc:	06f04763          	bgtz	a5,8000462a <end_op+0xbc>
    acquire(&log.lock);
    800045c0:	00246497          	auipc	s1,0x246
    800045c4:	a7848493          	addi	s1,s1,-1416 # 8024a038 <log>
    800045c8:	8526                	mv	a0,s1
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	742080e7          	jalr	1858(ra) # 80000d0c <acquire>
    log.committing = 0;
    800045d2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045d6:	8526                	mv	a0,s1
    800045d8:	ffffe097          	auipc	ra,0xffffe
    800045dc:	c46080e7          	jalr	-954(ra) # 8000221e <wakeup>
    release(&log.lock);
    800045e0:	8526                	mv	a0,s1
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	7de080e7          	jalr	2014(ra) # 80000dc0 <release>
}
    800045ea:	a03d                	j	80004618 <end_op+0xaa>
    panic("log.committing");
    800045ec:	00004517          	auipc	a0,0x4
    800045f0:	2e450513          	addi	a0,a0,740 # 800088d0 <names+0x208>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
    wakeup(&log);
    800045fc:	00246497          	auipc	s1,0x246
    80004600:	a3c48493          	addi	s1,s1,-1476 # 8024a038 <log>
    80004604:	8526                	mv	a0,s1
    80004606:	ffffe097          	auipc	ra,0xffffe
    8000460a:	c18080e7          	jalr	-1000(ra) # 8000221e <wakeup>
  release(&log.lock);
    8000460e:	8526                	mv	a0,s1
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	7b0080e7          	jalr	1968(ra) # 80000dc0 <release>
}
    80004618:	70e2                	ld	ra,56(sp)
    8000461a:	7442                	ld	s0,48(sp)
    8000461c:	74a2                	ld	s1,40(sp)
    8000461e:	7902                	ld	s2,32(sp)
    80004620:	69e2                	ld	s3,24(sp)
    80004622:	6a42                	ld	s4,16(sp)
    80004624:	6aa2                	ld	s5,8(sp)
    80004626:	6121                	addi	sp,sp,64
    80004628:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000462a:	00246a97          	auipc	s5,0x246
    8000462e:	a3ea8a93          	addi	s5,s5,-1474 # 8024a068 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004632:	00246a17          	auipc	s4,0x246
    80004636:	a06a0a13          	addi	s4,s4,-1530 # 8024a038 <log>
    8000463a:	018a2583          	lw	a1,24(s4)
    8000463e:	012585bb          	addw	a1,a1,s2
    80004642:	2585                	addiw	a1,a1,1
    80004644:	028a2503          	lw	a0,40(s4)
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	cc6080e7          	jalr	-826(ra) # 8000330e <bread>
    80004650:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004652:	000aa583          	lw	a1,0(s5)
    80004656:	028a2503          	lw	a0,40(s4)
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	cb4080e7          	jalr	-844(ra) # 8000330e <bread>
    80004662:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004664:	40000613          	li	a2,1024
    80004668:	05850593          	addi	a1,a0,88
    8000466c:	05848513          	addi	a0,s1,88
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	7f4080e7          	jalr	2036(ra) # 80000e64 <memmove>
    bwrite(to);  // write the log
    80004678:	8526                	mv	a0,s1
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	d86080e7          	jalr	-634(ra) # 80003400 <bwrite>
    brelse(from);
    80004682:	854e                	mv	a0,s3
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	dba080e7          	jalr	-582(ra) # 8000343e <brelse>
    brelse(to);
    8000468c:	8526                	mv	a0,s1
    8000468e:	fffff097          	auipc	ra,0xfffff
    80004692:	db0080e7          	jalr	-592(ra) # 8000343e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004696:	2905                	addiw	s2,s2,1
    80004698:	0a91                	addi	s5,s5,4
    8000469a:	02ca2783          	lw	a5,44(s4)
    8000469e:	f8f94ee3          	blt	s2,a5,8000463a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046a2:	00000097          	auipc	ra,0x0
    800046a6:	c68080e7          	jalr	-920(ra) # 8000430a <write_head>
    install_trans(0); // Now install writes to home locations
    800046aa:	4501                	li	a0,0
    800046ac:	00000097          	auipc	ra,0x0
    800046b0:	cda080e7          	jalr	-806(ra) # 80004386 <install_trans>
    log.lh.n = 0;
    800046b4:	00246797          	auipc	a5,0x246
    800046b8:	9a07a823          	sw	zero,-1616(a5) # 8024a064 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	c4e080e7          	jalr	-946(ra) # 8000430a <write_head>
    800046c4:	bdf5                	j	800045c0 <end_op+0x52>

00000000800046c6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046c6:	1101                	addi	sp,sp,-32
    800046c8:	ec06                	sd	ra,24(sp)
    800046ca:	e822                	sd	s0,16(sp)
    800046cc:	e426                	sd	s1,8(sp)
    800046ce:	e04a                	sd	s2,0(sp)
    800046d0:	1000                	addi	s0,sp,32
    800046d2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046d4:	00246917          	auipc	s2,0x246
    800046d8:	96490913          	addi	s2,s2,-1692 # 8024a038 <log>
    800046dc:	854a                	mv	a0,s2
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	62e080e7          	jalr	1582(ra) # 80000d0c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046e6:	02c92603          	lw	a2,44(s2)
    800046ea:	47f5                	li	a5,29
    800046ec:	06c7c563          	blt	a5,a2,80004756 <log_write+0x90>
    800046f0:	00246797          	auipc	a5,0x246
    800046f4:	9647a783          	lw	a5,-1692(a5) # 8024a054 <log+0x1c>
    800046f8:	37fd                	addiw	a5,a5,-1
    800046fa:	04f65e63          	bge	a2,a5,80004756 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046fe:	00246797          	auipc	a5,0x246
    80004702:	95a7a783          	lw	a5,-1702(a5) # 8024a058 <log+0x20>
    80004706:	06f05063          	blez	a5,80004766 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000470a:	4781                	li	a5,0
    8000470c:	06c05563          	blez	a2,80004776 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004710:	44cc                	lw	a1,12(s1)
    80004712:	00246717          	auipc	a4,0x246
    80004716:	95670713          	addi	a4,a4,-1706 # 8024a068 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000471a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000471c:	4314                	lw	a3,0(a4)
    8000471e:	04b68c63          	beq	a3,a1,80004776 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004722:	2785                	addiw	a5,a5,1
    80004724:	0711                	addi	a4,a4,4
    80004726:	fef61be3          	bne	a2,a5,8000471c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000472a:	0621                	addi	a2,a2,8
    8000472c:	060a                	slli	a2,a2,0x2
    8000472e:	00246797          	auipc	a5,0x246
    80004732:	90a78793          	addi	a5,a5,-1782 # 8024a038 <log>
    80004736:	97b2                	add	a5,a5,a2
    80004738:	44d8                	lw	a4,12(s1)
    8000473a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000473c:	8526                	mv	a0,s1
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	d9e080e7          	jalr	-610(ra) # 800034dc <bpin>
    log.lh.n++;
    80004746:	00246717          	auipc	a4,0x246
    8000474a:	8f270713          	addi	a4,a4,-1806 # 8024a038 <log>
    8000474e:	575c                	lw	a5,44(a4)
    80004750:	2785                	addiw	a5,a5,1
    80004752:	d75c                	sw	a5,44(a4)
    80004754:	a82d                	j	8000478e <log_write+0xc8>
    panic("too big a transaction");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	18a50513          	addi	a0,a0,394 # 800088e0 <names+0x218>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	de2080e7          	jalr	-542(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004766:	00004517          	auipc	a0,0x4
    8000476a:	19250513          	addi	a0,a0,402 # 800088f8 <names+0x230>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	dd2080e7          	jalr	-558(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004776:	00878693          	addi	a3,a5,8
    8000477a:	068a                	slli	a3,a3,0x2
    8000477c:	00246717          	auipc	a4,0x246
    80004780:	8bc70713          	addi	a4,a4,-1860 # 8024a038 <log>
    80004784:	9736                	add	a4,a4,a3
    80004786:	44d4                	lw	a3,12(s1)
    80004788:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000478a:	faf609e3          	beq	a2,a5,8000473c <log_write+0x76>
  }
  release(&log.lock);
    8000478e:	00246517          	auipc	a0,0x246
    80004792:	8aa50513          	addi	a0,a0,-1878 # 8024a038 <log>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	62a080e7          	jalr	1578(ra) # 80000dc0 <release>
}
    8000479e:	60e2                	ld	ra,24(sp)
    800047a0:	6442                	ld	s0,16(sp)
    800047a2:	64a2                	ld	s1,8(sp)
    800047a4:	6902                	ld	s2,0(sp)
    800047a6:	6105                	addi	sp,sp,32
    800047a8:	8082                	ret

00000000800047aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047aa:	1101                	addi	sp,sp,-32
    800047ac:	ec06                	sd	ra,24(sp)
    800047ae:	e822                	sd	s0,16(sp)
    800047b0:	e426                	sd	s1,8(sp)
    800047b2:	e04a                	sd	s2,0(sp)
    800047b4:	1000                	addi	s0,sp,32
    800047b6:	84aa                	mv	s1,a0
    800047b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047ba:	00004597          	auipc	a1,0x4
    800047be:	15e58593          	addi	a1,a1,350 # 80008918 <names+0x250>
    800047c2:	0521                	addi	a0,a0,8
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	4b8080e7          	jalr	1208(ra) # 80000c7c <initlock>
  lk->name = name;
    800047cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047d4:	0204a423          	sw	zero,40(s1)
}
    800047d8:	60e2                	ld	ra,24(sp)
    800047da:	6442                	ld	s0,16(sp)
    800047dc:	64a2                	ld	s1,8(sp)
    800047de:	6902                	ld	s2,0(sp)
    800047e0:	6105                	addi	sp,sp,32
    800047e2:	8082                	ret

00000000800047e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047e4:	1101                	addi	sp,sp,-32
    800047e6:	ec06                	sd	ra,24(sp)
    800047e8:	e822                	sd	s0,16(sp)
    800047ea:	e426                	sd	s1,8(sp)
    800047ec:	e04a                	sd	s2,0(sp)
    800047ee:	1000                	addi	s0,sp,32
    800047f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047f2:	00850913          	addi	s2,a0,8
    800047f6:	854a                	mv	a0,s2
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	514080e7          	jalr	1300(ra) # 80000d0c <acquire>
  while (lk->locked) {
    80004800:	409c                	lw	a5,0(s1)
    80004802:	cb89                	beqz	a5,80004814 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004804:	85ca                	mv	a1,s2
    80004806:	8526                	mv	a0,s1
    80004808:	ffffe097          	auipc	ra,0xffffe
    8000480c:	9b2080e7          	jalr	-1614(ra) # 800021ba <sleep>
  while (lk->locked) {
    80004810:	409c                	lw	a5,0(s1)
    80004812:	fbed                	bnez	a5,80004804 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004814:	4785                	li	a5,1
    80004816:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004818:	ffffd097          	auipc	ra,0xffffd
    8000481c:	2e4080e7          	jalr	740(ra) # 80001afc <myproc>
    80004820:	591c                	lw	a5,48(a0)
    80004822:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004824:	854a                	mv	a0,s2
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	59a080e7          	jalr	1434(ra) # 80000dc0 <release>
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret

000000008000483a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000483a:	1101                	addi	sp,sp,-32
    8000483c:	ec06                	sd	ra,24(sp)
    8000483e:	e822                	sd	s0,16(sp)
    80004840:	e426                	sd	s1,8(sp)
    80004842:	e04a                	sd	s2,0(sp)
    80004844:	1000                	addi	s0,sp,32
    80004846:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004848:	00850913          	addi	s2,a0,8
    8000484c:	854a                	mv	a0,s2
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	4be080e7          	jalr	1214(ra) # 80000d0c <acquire>
  lk->locked = 0;
    80004856:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000485a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000485e:	8526                	mv	a0,s1
    80004860:	ffffe097          	auipc	ra,0xffffe
    80004864:	9be080e7          	jalr	-1602(ra) # 8000221e <wakeup>
  release(&lk->lk);
    80004868:	854a                	mv	a0,s2
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	556080e7          	jalr	1366(ra) # 80000dc0 <release>
}
    80004872:	60e2                	ld	ra,24(sp)
    80004874:	6442                	ld	s0,16(sp)
    80004876:	64a2                	ld	s1,8(sp)
    80004878:	6902                	ld	s2,0(sp)
    8000487a:	6105                	addi	sp,sp,32
    8000487c:	8082                	ret

000000008000487e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000487e:	7179                	addi	sp,sp,-48
    80004880:	f406                	sd	ra,40(sp)
    80004882:	f022                	sd	s0,32(sp)
    80004884:	ec26                	sd	s1,24(sp)
    80004886:	e84a                	sd	s2,16(sp)
    80004888:	e44e                	sd	s3,8(sp)
    8000488a:	1800                	addi	s0,sp,48
    8000488c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000488e:	00850913          	addi	s2,a0,8
    80004892:	854a                	mv	a0,s2
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	478080e7          	jalr	1144(ra) # 80000d0c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000489c:	409c                	lw	a5,0(s1)
    8000489e:	ef99                	bnez	a5,800048bc <holdingsleep+0x3e>
    800048a0:	4481                	li	s1,0
  release(&lk->lk);
    800048a2:	854a                	mv	a0,s2
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	51c080e7          	jalr	1308(ra) # 80000dc0 <release>
  return r;
}
    800048ac:	8526                	mv	a0,s1
    800048ae:	70a2                	ld	ra,40(sp)
    800048b0:	7402                	ld	s0,32(sp)
    800048b2:	64e2                	ld	s1,24(sp)
    800048b4:	6942                	ld	s2,16(sp)
    800048b6:	69a2                	ld	s3,8(sp)
    800048b8:	6145                	addi	sp,sp,48
    800048ba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048bc:	0284a983          	lw	s3,40(s1)
    800048c0:	ffffd097          	auipc	ra,0xffffd
    800048c4:	23c080e7          	jalr	572(ra) # 80001afc <myproc>
    800048c8:	5904                	lw	s1,48(a0)
    800048ca:	413484b3          	sub	s1,s1,s3
    800048ce:	0014b493          	seqz	s1,s1
    800048d2:	bfc1                	j	800048a2 <holdingsleep+0x24>

00000000800048d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048d4:	1141                	addi	sp,sp,-16
    800048d6:	e406                	sd	ra,8(sp)
    800048d8:	e022                	sd	s0,0(sp)
    800048da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048dc:	00004597          	auipc	a1,0x4
    800048e0:	04c58593          	addi	a1,a1,76 # 80008928 <names+0x260>
    800048e4:	00246517          	auipc	a0,0x246
    800048e8:	89c50513          	addi	a0,a0,-1892 # 8024a180 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	390080e7          	jalr	912(ra) # 80000c7c <initlock>
}
    800048f4:	60a2                	ld	ra,8(sp)
    800048f6:	6402                	ld	s0,0(sp)
    800048f8:	0141                	addi	sp,sp,16
    800048fa:	8082                	ret

00000000800048fc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048fc:	1101                	addi	sp,sp,-32
    800048fe:	ec06                	sd	ra,24(sp)
    80004900:	e822                	sd	s0,16(sp)
    80004902:	e426                	sd	s1,8(sp)
    80004904:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004906:	00246517          	auipc	a0,0x246
    8000490a:	87a50513          	addi	a0,a0,-1926 # 8024a180 <ftable>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	3fe080e7          	jalr	1022(ra) # 80000d0c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004916:	00246497          	auipc	s1,0x246
    8000491a:	88248493          	addi	s1,s1,-1918 # 8024a198 <ftable+0x18>
    8000491e:	00247717          	auipc	a4,0x247
    80004922:	81a70713          	addi	a4,a4,-2022 # 8024b138 <disk>
    if(f->ref == 0){
    80004926:	40dc                	lw	a5,4(s1)
    80004928:	cf99                	beqz	a5,80004946 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000492a:	02848493          	addi	s1,s1,40
    8000492e:	fee49ce3          	bne	s1,a4,80004926 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004932:	00246517          	auipc	a0,0x246
    80004936:	84e50513          	addi	a0,a0,-1970 # 8024a180 <ftable>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	486080e7          	jalr	1158(ra) # 80000dc0 <release>
  return 0;
    80004942:	4481                	li	s1,0
    80004944:	a819                	j	8000495a <filealloc+0x5e>
      f->ref = 1;
    80004946:	4785                	li	a5,1
    80004948:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000494a:	00246517          	auipc	a0,0x246
    8000494e:	83650513          	addi	a0,a0,-1994 # 8024a180 <ftable>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	46e080e7          	jalr	1134(ra) # 80000dc0 <release>
}
    8000495a:	8526                	mv	a0,s1
    8000495c:	60e2                	ld	ra,24(sp)
    8000495e:	6442                	ld	s0,16(sp)
    80004960:	64a2                	ld	s1,8(sp)
    80004962:	6105                	addi	sp,sp,32
    80004964:	8082                	ret

0000000080004966 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004966:	1101                	addi	sp,sp,-32
    80004968:	ec06                	sd	ra,24(sp)
    8000496a:	e822                	sd	s0,16(sp)
    8000496c:	e426                	sd	s1,8(sp)
    8000496e:	1000                	addi	s0,sp,32
    80004970:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004972:	00246517          	auipc	a0,0x246
    80004976:	80e50513          	addi	a0,a0,-2034 # 8024a180 <ftable>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	392080e7          	jalr	914(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    80004982:	40dc                	lw	a5,4(s1)
    80004984:	02f05263          	blez	a5,800049a8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004988:	2785                	addiw	a5,a5,1
    8000498a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000498c:	00245517          	auipc	a0,0x245
    80004990:	7f450513          	addi	a0,a0,2036 # 8024a180 <ftable>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	42c080e7          	jalr	1068(ra) # 80000dc0 <release>
  return f;
}
    8000499c:	8526                	mv	a0,s1
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6105                	addi	sp,sp,32
    800049a6:	8082                	ret
    panic("filedup");
    800049a8:	00004517          	auipc	a0,0x4
    800049ac:	f8850513          	addi	a0,a0,-120 # 80008930 <names+0x268>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	b90080e7          	jalr	-1136(ra) # 80000540 <panic>

00000000800049b8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049b8:	7139                	addi	sp,sp,-64
    800049ba:	fc06                	sd	ra,56(sp)
    800049bc:	f822                	sd	s0,48(sp)
    800049be:	f426                	sd	s1,40(sp)
    800049c0:	f04a                	sd	s2,32(sp)
    800049c2:	ec4e                	sd	s3,24(sp)
    800049c4:	e852                	sd	s4,16(sp)
    800049c6:	e456                	sd	s5,8(sp)
    800049c8:	0080                	addi	s0,sp,64
    800049ca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049cc:	00245517          	auipc	a0,0x245
    800049d0:	7b450513          	addi	a0,a0,1972 # 8024a180 <ftable>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	338080e7          	jalr	824(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    800049dc:	40dc                	lw	a5,4(s1)
    800049de:	06f05163          	blez	a5,80004a40 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049e2:	37fd                	addiw	a5,a5,-1
    800049e4:	0007871b          	sext.w	a4,a5
    800049e8:	c0dc                	sw	a5,4(s1)
    800049ea:	06e04363          	bgtz	a4,80004a50 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049ee:	0004a903          	lw	s2,0(s1)
    800049f2:	0094ca83          	lbu	s5,9(s1)
    800049f6:	0104ba03          	ld	s4,16(s1)
    800049fa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049fe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a02:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a06:	00245517          	auipc	a0,0x245
    80004a0a:	77a50513          	addi	a0,a0,1914 # 8024a180 <ftable>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	3b2080e7          	jalr	946(ra) # 80000dc0 <release>

  if(ff.type == FD_PIPE){
    80004a16:	4785                	li	a5,1
    80004a18:	04f90d63          	beq	s2,a5,80004a72 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a1c:	3979                	addiw	s2,s2,-2
    80004a1e:	4785                	li	a5,1
    80004a20:	0527e063          	bltu	a5,s2,80004a60 <fileclose+0xa8>
    begin_op();
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	acc080e7          	jalr	-1332(ra) # 800044f0 <begin_op>
    iput(ff.ip);
    80004a2c:	854e                	mv	a0,s3
    80004a2e:	fffff097          	auipc	ra,0xfffff
    80004a32:	2b2080e7          	jalr	690(ra) # 80003ce0 <iput>
    end_op();
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	b38080e7          	jalr	-1224(ra) # 8000456e <end_op>
    80004a3e:	a00d                	j	80004a60 <fileclose+0xa8>
    panic("fileclose");
    80004a40:	00004517          	auipc	a0,0x4
    80004a44:	ef850513          	addi	a0,a0,-264 # 80008938 <names+0x270>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	af8080e7          	jalr	-1288(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a50:	00245517          	auipc	a0,0x245
    80004a54:	73050513          	addi	a0,a0,1840 # 8024a180 <ftable>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	368080e7          	jalr	872(ra) # 80000dc0 <release>
  }
}
    80004a60:	70e2                	ld	ra,56(sp)
    80004a62:	7442                	ld	s0,48(sp)
    80004a64:	74a2                	ld	s1,40(sp)
    80004a66:	7902                	ld	s2,32(sp)
    80004a68:	69e2                	ld	s3,24(sp)
    80004a6a:	6a42                	ld	s4,16(sp)
    80004a6c:	6aa2                	ld	s5,8(sp)
    80004a6e:	6121                	addi	sp,sp,64
    80004a70:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a72:	85d6                	mv	a1,s5
    80004a74:	8552                	mv	a0,s4
    80004a76:	00000097          	auipc	ra,0x0
    80004a7a:	34c080e7          	jalr	844(ra) # 80004dc2 <pipeclose>
    80004a7e:	b7cd                	j	80004a60 <fileclose+0xa8>

0000000080004a80 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a80:	7139                	addi	sp,sp,-64
    80004a82:	fc06                	sd	ra,56(sp)
    80004a84:	f822                	sd	s0,48(sp)
    80004a86:	f426                	sd	s1,40(sp)
    80004a88:	f04a                	sd	s2,32(sp)
    80004a8a:	ec4e                	sd	s3,24(sp)
    80004a8c:	0080                	addi	s0,sp,64
    80004a8e:	84aa                	mv	s1,a0
    80004a90:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	06a080e7          	jalr	106(ra) # 80001afc <myproc>
  struct stats st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a9a:	409c                	lw	a5,0(s1)
    80004a9c:	37f9                	addiw	a5,a5,-2
    80004a9e:	4705                	li	a4,1
    80004aa0:	04f76763          	bltu	a4,a5,80004aee <filestat+0x6e>
    80004aa4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004aa6:	6c88                	ld	a0,24(s1)
    80004aa8:	fffff097          	auipc	ra,0xfffff
    80004aac:	07e080e7          	jalr	126(ra) # 80003b26 <ilock>
    stati(f->ip, &st);
    80004ab0:	fc040593          	addi	a1,s0,-64
    80004ab4:	6c88                	ld	a0,24(s1)
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	2fa080e7          	jalr	762(ra) # 80003db0 <stati>
    iunlock(f->ip);
    80004abe:	6c88                	ld	a0,24(s1)
    80004ac0:	fffff097          	auipc	ra,0xfffff
    80004ac4:	128080e7          	jalr	296(ra) # 80003be8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ac8:	46c1                	li	a3,16
    80004aca:	fc040613          	addi	a2,s0,-64
    80004ace:	85ce                	mv	a1,s3
    80004ad0:	05893503          	ld	a0,88(s2)
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	cb4080e7          	jalr	-844(ra) # 80001788 <copyout>
    80004adc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ae0:	70e2                	ld	ra,56(sp)
    80004ae2:	7442                	ld	s0,48(sp)
    80004ae4:	74a2                	ld	s1,40(sp)
    80004ae6:	7902                	ld	s2,32(sp)
    80004ae8:	69e2                	ld	s3,24(sp)
    80004aea:	6121                	addi	sp,sp,64
    80004aec:	8082                	ret
  return -1;
    80004aee:	557d                	li	a0,-1
    80004af0:	bfc5                	j	80004ae0 <filestat+0x60>

0000000080004af2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004af2:	7179                	addi	sp,sp,-48
    80004af4:	f406                	sd	ra,40(sp)
    80004af6:	f022                	sd	s0,32(sp)
    80004af8:	ec26                	sd	s1,24(sp)
    80004afa:	e84a                	sd	s2,16(sp)
    80004afc:	e44e                	sd	s3,8(sp)
    80004afe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b00:	00854783          	lbu	a5,8(a0)
    80004b04:	c3d5                	beqz	a5,80004ba8 <fileread+0xb6>
    80004b06:	84aa                	mv	s1,a0
    80004b08:	89ae                	mv	s3,a1
    80004b0a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b0c:	411c                	lw	a5,0(a0)
    80004b0e:	4705                	li	a4,1
    80004b10:	04e78963          	beq	a5,a4,80004b62 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b14:	470d                	li	a4,3
    80004b16:	04e78d63          	beq	a5,a4,80004b70 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b1a:	4709                	li	a4,2
    80004b1c:	06e79e63          	bne	a5,a4,80004b98 <fileread+0xa6>
    ilock(f->ip);
    80004b20:	6d08                	ld	a0,24(a0)
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	004080e7          	jalr	4(ra) # 80003b26 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b2a:	874a                	mv	a4,s2
    80004b2c:	5094                	lw	a3,32(s1)
    80004b2e:	864e                	mv	a2,s3
    80004b30:	4585                	li	a1,1
    80004b32:	6c88                	ld	a0,24(s1)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	2a4080e7          	jalr	676(ra) # 80003dd8 <readi>
    80004b3c:	892a                	mv	s2,a0
    80004b3e:	00a05563          	blez	a0,80004b48 <fileread+0x56>
      f->off += r;
    80004b42:	509c                	lw	a5,32(s1)
    80004b44:	9fa9                	addw	a5,a5,a0
    80004b46:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b48:	6c88                	ld	a0,24(s1)
    80004b4a:	fffff097          	auipc	ra,0xfffff
    80004b4e:	09e080e7          	jalr	158(ra) # 80003be8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b52:	854a                	mv	a0,s2
    80004b54:	70a2                	ld	ra,40(sp)
    80004b56:	7402                	ld	s0,32(sp)
    80004b58:	64e2                	ld	s1,24(sp)
    80004b5a:	6942                	ld	s2,16(sp)
    80004b5c:	69a2                	ld	s3,8(sp)
    80004b5e:	6145                	addi	sp,sp,48
    80004b60:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b62:	6908                	ld	a0,16(a0)
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	3c6080e7          	jalr	966(ra) # 80004f2a <piperead>
    80004b6c:	892a                	mv	s2,a0
    80004b6e:	b7d5                	j	80004b52 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b70:	02451783          	lh	a5,36(a0)
    80004b74:	03079693          	slli	a3,a5,0x30
    80004b78:	92c1                	srli	a3,a3,0x30
    80004b7a:	4725                	li	a4,9
    80004b7c:	02d76863          	bltu	a4,a3,80004bac <fileread+0xba>
    80004b80:	0792                	slli	a5,a5,0x4
    80004b82:	00245717          	auipc	a4,0x245
    80004b86:	55e70713          	addi	a4,a4,1374 # 8024a0e0 <devsw>
    80004b8a:	97ba                	add	a5,a5,a4
    80004b8c:	639c                	ld	a5,0(a5)
    80004b8e:	c38d                	beqz	a5,80004bb0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b90:	4505                	li	a0,1
    80004b92:	9782                	jalr	a5
    80004b94:	892a                	mv	s2,a0
    80004b96:	bf75                	j	80004b52 <fileread+0x60>
    panic("fileread");
    80004b98:	00004517          	auipc	a0,0x4
    80004b9c:	db050513          	addi	a0,a0,-592 # 80008948 <names+0x280>
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	9a0080e7          	jalr	-1632(ra) # 80000540 <panic>
    return -1;
    80004ba8:	597d                	li	s2,-1
    80004baa:	b765                	j	80004b52 <fileread+0x60>
      return -1;
    80004bac:	597d                	li	s2,-1
    80004bae:	b755                	j	80004b52 <fileread+0x60>
    80004bb0:	597d                	li	s2,-1
    80004bb2:	b745                	j	80004b52 <fileread+0x60>

0000000080004bb4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bb4:	715d                	addi	sp,sp,-80
    80004bb6:	e486                	sd	ra,72(sp)
    80004bb8:	e0a2                	sd	s0,64(sp)
    80004bba:	fc26                	sd	s1,56(sp)
    80004bbc:	f84a                	sd	s2,48(sp)
    80004bbe:	f44e                	sd	s3,40(sp)
    80004bc0:	f052                	sd	s4,32(sp)
    80004bc2:	ec56                	sd	s5,24(sp)
    80004bc4:	e85a                	sd	s6,16(sp)
    80004bc6:	e45e                	sd	s7,8(sp)
    80004bc8:	e062                	sd	s8,0(sp)
    80004bca:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bcc:	00954783          	lbu	a5,9(a0)
    80004bd0:	10078663          	beqz	a5,80004cdc <filewrite+0x128>
    80004bd4:	892a                	mv	s2,a0
    80004bd6:	8b2e                	mv	s6,a1
    80004bd8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bda:	411c                	lw	a5,0(a0)
    80004bdc:	4705                	li	a4,1
    80004bde:	02e78263          	beq	a5,a4,80004c02 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004be2:	470d                	li	a4,3
    80004be4:	02e78663          	beq	a5,a4,80004c10 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be8:	4709                	li	a4,2
    80004bea:	0ee79163          	bne	a5,a4,80004ccc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bee:	0ac05d63          	blez	a2,80004ca8 <filewrite+0xf4>
    int i = 0;
    80004bf2:	4981                	li	s3,0
    80004bf4:	6b85                	lui	s7,0x1
    80004bf6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bfa:	6c05                	lui	s8,0x1
    80004bfc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c00:	a861                	j	80004c98 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c02:	6908                	ld	a0,16(a0)
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	22e080e7          	jalr	558(ra) # 80004e32 <pipewrite>
    80004c0c:	8a2a                	mv	s4,a0
    80004c0e:	a045                	j	80004cae <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c10:	02451783          	lh	a5,36(a0)
    80004c14:	03079693          	slli	a3,a5,0x30
    80004c18:	92c1                	srli	a3,a3,0x30
    80004c1a:	4725                	li	a4,9
    80004c1c:	0cd76263          	bltu	a4,a3,80004ce0 <filewrite+0x12c>
    80004c20:	0792                	slli	a5,a5,0x4
    80004c22:	00245717          	auipc	a4,0x245
    80004c26:	4be70713          	addi	a4,a4,1214 # 8024a0e0 <devsw>
    80004c2a:	97ba                	add	a5,a5,a4
    80004c2c:	679c                	ld	a5,8(a5)
    80004c2e:	cbdd                	beqz	a5,80004ce4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c30:	4505                	li	a0,1
    80004c32:	9782                	jalr	a5
    80004c34:	8a2a                	mv	s4,a0
    80004c36:	a8a5                	j	80004cae <filewrite+0xfa>
    80004c38:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c3c:	00000097          	auipc	ra,0x0
    80004c40:	8b4080e7          	jalr	-1868(ra) # 800044f0 <begin_op>
      ilock(f->ip);
    80004c44:	01893503          	ld	a0,24(s2)
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	ede080e7          	jalr	-290(ra) # 80003b26 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c50:	8756                	mv	a4,s5
    80004c52:	02092683          	lw	a3,32(s2)
    80004c56:	01698633          	add	a2,s3,s6
    80004c5a:	4585                	li	a1,1
    80004c5c:	01893503          	ld	a0,24(s2)
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	270080e7          	jalr	624(ra) # 80003ed0 <writei>
    80004c68:	84aa                	mv	s1,a0
    80004c6a:	00a05763          	blez	a0,80004c78 <filewrite+0xc4>
        f->off += r;
    80004c6e:	02092783          	lw	a5,32(s2)
    80004c72:	9fa9                	addw	a5,a5,a0
    80004c74:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c78:	01893503          	ld	a0,24(s2)
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	f6c080e7          	jalr	-148(ra) # 80003be8 <iunlock>
      end_op();
    80004c84:	00000097          	auipc	ra,0x0
    80004c88:	8ea080e7          	jalr	-1814(ra) # 8000456e <end_op>

      if(r != n1){
    80004c8c:	009a9f63          	bne	s5,s1,80004caa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c90:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c94:	0149db63          	bge	s3,s4,80004caa <filewrite+0xf6>
      int n1 = n - i;
    80004c98:	413a04bb          	subw	s1,s4,s3
    80004c9c:	0004879b          	sext.w	a5,s1
    80004ca0:	f8fbdce3          	bge	s7,a5,80004c38 <filewrite+0x84>
    80004ca4:	84e2                	mv	s1,s8
    80004ca6:	bf49                	j	80004c38 <filewrite+0x84>
    int i = 0;
    80004ca8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004caa:	013a1f63          	bne	s4,s3,80004cc8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cae:	8552                	mv	a0,s4
    80004cb0:	60a6                	ld	ra,72(sp)
    80004cb2:	6406                	ld	s0,64(sp)
    80004cb4:	74e2                	ld	s1,56(sp)
    80004cb6:	7942                	ld	s2,48(sp)
    80004cb8:	79a2                	ld	s3,40(sp)
    80004cba:	7a02                	ld	s4,32(sp)
    80004cbc:	6ae2                	ld	s5,24(sp)
    80004cbe:	6b42                	ld	s6,16(sp)
    80004cc0:	6ba2                	ld	s7,8(sp)
    80004cc2:	6c02                	ld	s8,0(sp)
    80004cc4:	6161                	addi	sp,sp,80
    80004cc6:	8082                	ret
    ret = (i == n ? n : -1);
    80004cc8:	5a7d                	li	s4,-1
    80004cca:	b7d5                	j	80004cae <filewrite+0xfa>
    panic("filewrite");
    80004ccc:	00004517          	auipc	a0,0x4
    80004cd0:	c8c50513          	addi	a0,a0,-884 # 80008958 <names+0x290>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	86c080e7          	jalr	-1940(ra) # 80000540 <panic>
    return -1;
    80004cdc:	5a7d                	li	s4,-1
    80004cde:	bfc1                	j	80004cae <filewrite+0xfa>
      return -1;
    80004ce0:	5a7d                	li	s4,-1
    80004ce2:	b7f1                	j	80004cae <filewrite+0xfa>
    80004ce4:	5a7d                	li	s4,-1
    80004ce6:	b7e1                	j	80004cae <filewrite+0xfa>

0000000080004ce8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ce8:	7179                	addi	sp,sp,-48
    80004cea:	f406                	sd	ra,40(sp)
    80004cec:	f022                	sd	s0,32(sp)
    80004cee:	ec26                	sd	s1,24(sp)
    80004cf0:	e84a                	sd	s2,16(sp)
    80004cf2:	e44e                	sd	s3,8(sp)
    80004cf4:	e052                	sd	s4,0(sp)
    80004cf6:	1800                	addi	s0,sp,48
    80004cf8:	84aa                	mv	s1,a0
    80004cfa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cfc:	0005b023          	sd	zero,0(a1)
    80004d00:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	bf8080e7          	jalr	-1032(ra) # 800048fc <filealloc>
    80004d0c:	e088                	sd	a0,0(s1)
    80004d0e:	c551                	beqz	a0,80004d9a <pipealloc+0xb2>
    80004d10:	00000097          	auipc	ra,0x0
    80004d14:	bec080e7          	jalr	-1044(ra) # 800048fc <filealloc>
    80004d18:	00aa3023          	sd	a0,0(s4)
    80004d1c:	c92d                	beqz	a0,80004d8e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	ec6080e7          	jalr	-314(ra) # 80000be4 <kalloc>
    80004d26:	892a                	mv	s2,a0
    80004d28:	c125                	beqz	a0,80004d88 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d2a:	4985                	li	s3,1
    80004d2c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d30:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d34:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d38:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d3c:	00003597          	auipc	a1,0x3
    80004d40:	7fc58593          	addi	a1,a1,2044 # 80008538 <states.0+0x1b8>
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	f38080e7          	jalr	-200(ra) # 80000c7c <initlock>
  (*f0)->type = FD_PIPE;
    80004d4c:	609c                	ld	a5,0(s1)
    80004d4e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d52:	609c                	ld	a5,0(s1)
    80004d54:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d58:	609c                	ld	a5,0(s1)
    80004d5a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d5e:	609c                	ld	a5,0(s1)
    80004d60:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d64:	000a3783          	ld	a5,0(s4)
    80004d68:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d6c:	000a3783          	ld	a5,0(s4)
    80004d70:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d74:	000a3783          	ld	a5,0(s4)
    80004d78:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d7c:	000a3783          	ld	a5,0(s4)
    80004d80:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d84:	4501                	li	a0,0
    80004d86:	a025                	j	80004dae <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d88:	6088                	ld	a0,0(s1)
    80004d8a:	e501                	bnez	a0,80004d92 <pipealloc+0xaa>
    80004d8c:	a039                	j	80004d9a <pipealloc+0xb2>
    80004d8e:	6088                	ld	a0,0(s1)
    80004d90:	c51d                	beqz	a0,80004dbe <pipealloc+0xd6>
    fileclose(*f0);
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	c26080e7          	jalr	-986(ra) # 800049b8 <fileclose>
  if(*f1)
    80004d9a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d9e:	557d                	li	a0,-1
  if(*f1)
    80004da0:	c799                	beqz	a5,80004dae <pipealloc+0xc6>
    fileclose(*f1);
    80004da2:	853e                	mv	a0,a5
    80004da4:	00000097          	auipc	ra,0x0
    80004da8:	c14080e7          	jalr	-1004(ra) # 800049b8 <fileclose>
  return -1;
    80004dac:	557d                	li	a0,-1
}
    80004dae:	70a2                	ld	ra,40(sp)
    80004db0:	7402                	ld	s0,32(sp)
    80004db2:	64e2                	ld	s1,24(sp)
    80004db4:	6942                	ld	s2,16(sp)
    80004db6:	69a2                	ld	s3,8(sp)
    80004db8:	6a02                	ld	s4,0(sp)
    80004dba:	6145                	addi	sp,sp,48
    80004dbc:	8082                	ret
  return -1;
    80004dbe:	557d                	li	a0,-1
    80004dc0:	b7fd                	j	80004dae <pipealloc+0xc6>

0000000080004dc2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dc2:	1101                	addi	sp,sp,-32
    80004dc4:	ec06                	sd	ra,24(sp)
    80004dc6:	e822                	sd	s0,16(sp)
    80004dc8:	e426                	sd	s1,8(sp)
    80004dca:	e04a                	sd	s2,0(sp)
    80004dcc:	1000                	addi	s0,sp,32
    80004dce:	84aa                	mv	s1,a0
    80004dd0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	f3a080e7          	jalr	-198(ra) # 80000d0c <acquire>
  if(writable){
    80004dda:	02090d63          	beqz	s2,80004e14 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dde:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004de2:	21848513          	addi	a0,s1,536
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	438080e7          	jalr	1080(ra) # 8000221e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dee:	2204b783          	ld	a5,544(s1)
    80004df2:	eb95                	bnez	a5,80004e26 <pipeclose+0x64>
    release(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	fca080e7          	jalr	-54(ra) # 80000dc0 <release>
    kfree((char*)pi);
    80004dfe:	8526                	mv	a0,s1
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	c60080e7          	jalr	-928(ra) # 80000a60 <kfree>
  } else
    release(&pi->lock);
}
    80004e08:	60e2                	ld	ra,24(sp)
    80004e0a:	6442                	ld	s0,16(sp)
    80004e0c:	64a2                	ld	s1,8(sp)
    80004e0e:	6902                	ld	s2,0(sp)
    80004e10:	6105                	addi	sp,sp,32
    80004e12:	8082                	ret
    pi->readopen = 0;
    80004e14:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e18:	21c48513          	addi	a0,s1,540
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	402080e7          	jalr	1026(ra) # 8000221e <wakeup>
    80004e24:	b7e9                	j	80004dee <pipeclose+0x2c>
    release(&pi->lock);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	f98080e7          	jalr	-104(ra) # 80000dc0 <release>
}
    80004e30:	bfe1                	j	80004e08 <pipeclose+0x46>

0000000080004e32 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e32:	711d                	addi	sp,sp,-96
    80004e34:	ec86                	sd	ra,88(sp)
    80004e36:	e8a2                	sd	s0,80(sp)
    80004e38:	e4a6                	sd	s1,72(sp)
    80004e3a:	e0ca                	sd	s2,64(sp)
    80004e3c:	fc4e                	sd	s3,56(sp)
    80004e3e:	f852                	sd	s4,48(sp)
    80004e40:	f456                	sd	s5,40(sp)
    80004e42:	f05a                	sd	s6,32(sp)
    80004e44:	ec5e                	sd	s7,24(sp)
    80004e46:	e862                	sd	s8,16(sp)
    80004e48:	1080                	addi	s0,sp,96
    80004e4a:	84aa                	mv	s1,a0
    80004e4c:	8aae                	mv	s5,a1
    80004e4e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	cac080e7          	jalr	-852(ra) # 80001afc <myproc>
    80004e58:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	eb0080e7          	jalr	-336(ra) # 80000d0c <acquire>
  while(i < n){
    80004e64:	0b405663          	blez	s4,80004f10 <pipewrite+0xde>
  int i = 0;
    80004e68:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e6a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e6c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e70:	21c48b93          	addi	s7,s1,540
    80004e74:	a089                	j	80004eb6 <pipewrite+0x84>
      release(&pi->lock);
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	f48080e7          	jalr	-184(ra) # 80000dc0 <release>
      return -1;
    80004e80:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e82:	854a                	mv	a0,s2
    80004e84:	60e6                	ld	ra,88(sp)
    80004e86:	6446                	ld	s0,80(sp)
    80004e88:	64a6                	ld	s1,72(sp)
    80004e8a:	6906                	ld	s2,64(sp)
    80004e8c:	79e2                	ld	s3,56(sp)
    80004e8e:	7a42                	ld	s4,48(sp)
    80004e90:	7aa2                	ld	s5,40(sp)
    80004e92:	7b02                	ld	s6,32(sp)
    80004e94:	6be2                	ld	s7,24(sp)
    80004e96:	6c42                	ld	s8,16(sp)
    80004e98:	6125                	addi	sp,sp,96
    80004e9a:	8082                	ret
      wakeup(&pi->nread);
    80004e9c:	8562                	mv	a0,s8
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	380080e7          	jalr	896(ra) # 8000221e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ea6:	85a6                	mv	a1,s1
    80004ea8:	855e                	mv	a0,s7
    80004eaa:	ffffd097          	auipc	ra,0xffffd
    80004eae:	310080e7          	jalr	784(ra) # 800021ba <sleep>
  while(i < n){
    80004eb2:	07495063          	bge	s2,s4,80004f12 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004eb6:	2204a783          	lw	a5,544(s1)
    80004eba:	dfd5                	beqz	a5,80004e76 <pipewrite+0x44>
    80004ebc:	854e                	mv	a0,s3
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	5a4080e7          	jalr	1444(ra) # 80002462 <killed>
    80004ec6:	f945                	bnez	a0,80004e76 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ec8:	2184a783          	lw	a5,536(s1)
    80004ecc:	21c4a703          	lw	a4,540(s1)
    80004ed0:	2007879b          	addiw	a5,a5,512
    80004ed4:	fcf704e3          	beq	a4,a5,80004e9c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed8:	4685                	li	a3,1
    80004eda:	01590633          	add	a2,s2,s5
    80004ede:	faf40593          	addi	a1,s0,-81
    80004ee2:	0589b503          	ld	a0,88(s3)
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	962080e7          	jalr	-1694(ra) # 80001848 <copyin>
    80004eee:	03650263          	beq	a0,s6,80004f12 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ef2:	21c4a783          	lw	a5,540(s1)
    80004ef6:	0017871b          	addiw	a4,a5,1
    80004efa:	20e4ae23          	sw	a4,540(s1)
    80004efe:	1ff7f793          	andi	a5,a5,511
    80004f02:	97a6                	add	a5,a5,s1
    80004f04:	faf44703          	lbu	a4,-81(s0)
    80004f08:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f0c:	2905                	addiw	s2,s2,1
    80004f0e:	b755                	j	80004eb2 <pipewrite+0x80>
  int i = 0;
    80004f10:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f12:	21848513          	addi	a0,s1,536
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	308080e7          	jalr	776(ra) # 8000221e <wakeup>
  release(&pi->lock);
    80004f1e:	8526                	mv	a0,s1
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	ea0080e7          	jalr	-352(ra) # 80000dc0 <release>
  return i;
    80004f28:	bfa9                	j	80004e82 <pipewrite+0x50>

0000000080004f2a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f2a:	715d                	addi	sp,sp,-80
    80004f2c:	e486                	sd	ra,72(sp)
    80004f2e:	e0a2                	sd	s0,64(sp)
    80004f30:	fc26                	sd	s1,56(sp)
    80004f32:	f84a                	sd	s2,48(sp)
    80004f34:	f44e                	sd	s3,40(sp)
    80004f36:	f052                	sd	s4,32(sp)
    80004f38:	ec56                	sd	s5,24(sp)
    80004f3a:	e85a                	sd	s6,16(sp)
    80004f3c:	0880                	addi	s0,sp,80
    80004f3e:	84aa                	mv	s1,a0
    80004f40:	892e                	mv	s2,a1
    80004f42:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	bb8080e7          	jalr	-1096(ra) # 80001afc <myproc>
    80004f4c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f4e:	8526                	mv	a0,s1
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	dbc080e7          	jalr	-580(ra) # 80000d0c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f58:	2184a703          	lw	a4,536(s1)
    80004f5c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f60:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f64:	02f71763          	bne	a4,a5,80004f92 <piperead+0x68>
    80004f68:	2244a783          	lw	a5,548(s1)
    80004f6c:	c39d                	beqz	a5,80004f92 <piperead+0x68>
    if(killed(pr)){
    80004f6e:	8552                	mv	a0,s4
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	4f2080e7          	jalr	1266(ra) # 80002462 <killed>
    80004f78:	e949                	bnez	a0,8000500a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f7a:	85a6                	mv	a1,s1
    80004f7c:	854e                	mv	a0,s3
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	23c080e7          	jalr	572(ra) # 800021ba <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f86:	2184a703          	lw	a4,536(s1)
    80004f8a:	21c4a783          	lw	a5,540(s1)
    80004f8e:	fcf70de3          	beq	a4,a5,80004f68 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f94:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f96:	05505463          	blez	s5,80004fde <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f9a:	2184a783          	lw	a5,536(s1)
    80004f9e:	21c4a703          	lw	a4,540(s1)
    80004fa2:	02f70e63          	beq	a4,a5,80004fde <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fa6:	0017871b          	addiw	a4,a5,1
    80004faa:	20e4ac23          	sw	a4,536(s1)
    80004fae:	1ff7f793          	andi	a5,a5,511
    80004fb2:	97a6                	add	a5,a5,s1
    80004fb4:	0187c783          	lbu	a5,24(a5)
    80004fb8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fbc:	4685                	li	a3,1
    80004fbe:	fbf40613          	addi	a2,s0,-65
    80004fc2:	85ca                	mv	a1,s2
    80004fc4:	058a3503          	ld	a0,88(s4)
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	7c0080e7          	jalr	1984(ra) # 80001788 <copyout>
    80004fd0:	01650763          	beq	a0,s6,80004fde <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd4:	2985                	addiw	s3,s3,1
    80004fd6:	0905                	addi	s2,s2,1
    80004fd8:	fd3a91e3          	bne	s5,s3,80004f9a <piperead+0x70>
    80004fdc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fde:	21c48513          	addi	a0,s1,540
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	23c080e7          	jalr	572(ra) # 8000221e <wakeup>
  release(&pi->lock);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	dd4080e7          	jalr	-556(ra) # 80000dc0 <release>
  return i;
}
    80004ff4:	854e                	mv	a0,s3
    80004ff6:	60a6                	ld	ra,72(sp)
    80004ff8:	6406                	ld	s0,64(sp)
    80004ffa:	74e2                	ld	s1,56(sp)
    80004ffc:	7942                	ld	s2,48(sp)
    80004ffe:	79a2                	ld	s3,40(sp)
    80005000:	7a02                	ld	s4,32(sp)
    80005002:	6ae2                	ld	s5,24(sp)
    80005004:	6b42                	ld	s6,16(sp)
    80005006:	6161                	addi	sp,sp,80
    80005008:	8082                	ret
      release(&pi->lock);
    8000500a:	8526                	mv	a0,s1
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	db4080e7          	jalr	-588(ra) # 80000dc0 <release>
      return -1;
    80005014:	59fd                	li	s3,-1
    80005016:	bff9                	j	80004ff4 <piperead+0xca>

0000000080005018 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005018:	1141                	addi	sp,sp,-16
    8000501a:	e422                	sd	s0,8(sp)
    8000501c:	0800                	addi	s0,sp,16
    8000501e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005020:	8905                	andi	a0,a0,1
    80005022:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005024:	8b89                	andi	a5,a5,2
    80005026:	c399                	beqz	a5,8000502c <flags2perm+0x14>
      perm |= PTE_W;
    80005028:	00456513          	ori	a0,a0,4
    return perm;
}
    8000502c:	6422                	ld	s0,8(sp)
    8000502e:	0141                	addi	sp,sp,16
    80005030:	8082                	ret

0000000080005032 <exec>:

int
exec(char *path, char **argv)
{
    80005032:	de010113          	addi	sp,sp,-544
    80005036:	20113c23          	sd	ra,536(sp)
    8000503a:	20813823          	sd	s0,528(sp)
    8000503e:	20913423          	sd	s1,520(sp)
    80005042:	21213023          	sd	s2,512(sp)
    80005046:	ffce                	sd	s3,504(sp)
    80005048:	fbd2                	sd	s4,496(sp)
    8000504a:	f7d6                	sd	s5,488(sp)
    8000504c:	f3da                	sd	s6,480(sp)
    8000504e:	efde                	sd	s7,472(sp)
    80005050:	ebe2                	sd	s8,464(sp)
    80005052:	e7e6                	sd	s9,456(sp)
    80005054:	e3ea                	sd	s10,448(sp)
    80005056:	ff6e                	sd	s11,440(sp)
    80005058:	1400                	addi	s0,sp,544
    8000505a:	892a                	mv	s2,a0
    8000505c:	dea43423          	sd	a0,-536(s0)
    80005060:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	a98080e7          	jalr	-1384(ra) # 80001afc <myproc>
    8000506c:	84aa                	mv	s1,a0

  // printf("1\n");

  begin_op();
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	482080e7          	jalr	1154(ra) # 800044f0 <begin_op>

  if((ip = namei(path)) == 0){
    80005076:	854a                	mv	a0,s2
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	258080e7          	jalr	600(ra) # 800042d0 <namei>
    80005080:	c93d                	beqz	a0,800050f6 <exec+0xc4>
    80005082:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005084:	fffff097          	auipc	ra,0xfffff
    80005088:	aa2080e7          	jalr	-1374(ra) # 80003b26 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000508c:	04000713          	li	a4,64
    80005090:	4681                	li	a3,0
    80005092:	e5040613          	addi	a2,s0,-432
    80005096:	4581                	li	a1,0
    80005098:	8556                	mv	a0,s5
    8000509a:	fffff097          	auipc	ra,0xfffff
    8000509e:	d3e080e7          	jalr	-706(ra) # 80003dd8 <readi>
    800050a2:	04000793          	li	a5,64
    800050a6:	00f51a63          	bne	a0,a5,800050ba <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050aa:	e5042703          	lw	a4,-432(s0)
    800050ae:	464c47b7          	lui	a5,0x464c4
    800050b2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050b6:	04f70663          	beq	a4,a5,80005102 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050ba:	8556                	mv	a0,s5
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	ccc080e7          	jalr	-820(ra) # 80003d88 <iunlockput>
    end_op();
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	4aa080e7          	jalr	1194(ra) # 8000456e <end_op>
  }
  return -1;
    800050cc:	557d                	li	a0,-1
}
    800050ce:	21813083          	ld	ra,536(sp)
    800050d2:	21013403          	ld	s0,528(sp)
    800050d6:	20813483          	ld	s1,520(sp)
    800050da:	20013903          	ld	s2,512(sp)
    800050de:	79fe                	ld	s3,504(sp)
    800050e0:	7a5e                	ld	s4,496(sp)
    800050e2:	7abe                	ld	s5,488(sp)
    800050e4:	7b1e                	ld	s6,480(sp)
    800050e6:	6bfe                	ld	s7,472(sp)
    800050e8:	6c5e                	ld	s8,464(sp)
    800050ea:	6cbe                	ld	s9,456(sp)
    800050ec:	6d1e                	ld	s10,448(sp)
    800050ee:	7dfa                	ld	s11,440(sp)
    800050f0:	22010113          	addi	sp,sp,544
    800050f4:	8082                	ret
    end_op();
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	478080e7          	jalr	1144(ra) # 8000456e <end_op>
    return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	b7f9                	j	800050ce <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005102:	8526                	mv	a0,s1
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	abc080e7          	jalr	-1348(ra) # 80001bc0 <proc_pagetable>
    8000510c:	8b2a                	mv	s6,a0
    8000510e:	d555                	beqz	a0,800050ba <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005110:	e7042783          	lw	a5,-400(s0)
    80005114:	e8845703          	lhu	a4,-376(s0)
    80005118:	c735                	beqz	a4,80005184 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000511a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000511c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005120:	6a05                	lui	s4,0x1
    80005122:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005126:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000512a:	6d85                	lui	s11,0x1
    8000512c:	7d7d                	lui	s10,0xfffff
    8000512e:	a491                	j	80005372 <exec+0x340>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005130:	00004517          	auipc	a0,0x4
    80005134:	83850513          	addi	a0,a0,-1992 # 80008968 <names+0x2a0>
    80005138:	ffffb097          	auipc	ra,0xffffb
    8000513c:	408080e7          	jalr	1032(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005140:	874a                	mv	a4,s2
    80005142:	009c86bb          	addw	a3,s9,s1
    80005146:	4581                	li	a1,0
    80005148:	8556                	mv	a0,s5
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	c8e080e7          	jalr	-882(ra) # 80003dd8 <readi>
    80005152:	2501                	sext.w	a0,a0
    80005154:	1aa91c63          	bne	s2,a0,8000530c <exec+0x2da>
  for(i = 0; i < sz; i += PGSIZE){
    80005158:	009d84bb          	addw	s1,s11,s1
    8000515c:	013d09bb          	addw	s3,s10,s3
    80005160:	1f74f963          	bgeu	s1,s7,80005352 <exec+0x320>
    pa = walkaddr(pagetable, va + i);
    80005164:	02049593          	slli	a1,s1,0x20
    80005168:	9181                	srli	a1,a1,0x20
    8000516a:	95e2                	add	a1,a1,s8
    8000516c:	855a                	mv	a0,s6
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	024080e7          	jalr	36(ra) # 80001192 <walkaddr>
    80005176:	862a                	mv	a2,a0
    if(pa == 0)
    80005178:	dd45                	beqz	a0,80005130 <exec+0xfe>
      n = PGSIZE;
    8000517a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000517c:	fd49f2e3          	bgeu	s3,s4,80005140 <exec+0x10e>
      n = sz - i;
    80005180:	894e                	mv	s2,s3
    80005182:	bf7d                	j	80005140 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005184:	4901                	li	s2,0
  iunlockput(ip);
    80005186:	8556                	mv	a0,s5
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	c00080e7          	jalr	-1024(ra) # 80003d88 <iunlockput>
  end_op();
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	3de080e7          	jalr	990(ra) # 8000456e <end_op>
  p = myproc();
    80005198:	ffffd097          	auipc	ra,0xffffd
    8000519c:	964080e7          	jalr	-1692(ra) # 80001afc <myproc>
    800051a0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051a2:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800051a6:	6785                	lui	a5,0x1
    800051a8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800051aa:	97ca                	add	a5,a5,s2
    800051ac:	777d                	lui	a4,0xfffff
    800051ae:	8ff9                	and	a5,a5,a4
    800051b0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051b4:	4691                	li	a3,4
    800051b6:	6609                	lui	a2,0x2
    800051b8:	963e                	add	a2,a2,a5
    800051ba:	85be                	mv	a1,a5
    800051bc:	855a                	mv	a0,s6
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	388080e7          	jalr	904(ra) # 80001546 <uvmalloc>
    800051c6:	8c2a                	mv	s8,a0
  ip = 0;
    800051c8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051ca:	14050163          	beqz	a0,8000530c <exec+0x2da>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051ce:	75f9                	lui	a1,0xffffe
    800051d0:	95aa                	add	a1,a1,a0
    800051d2:	855a                	mv	a0,s6
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	582080e7          	jalr	1410(ra) # 80001756 <uvmclear>
  stackbase = sp - PGSIZE;
    800051dc:	7afd                	lui	s5,0xfffff
    800051de:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051e0:	df043783          	ld	a5,-528(s0)
    800051e4:	6388                	ld	a0,0(a5)
    800051e6:	c925                	beqz	a0,80005256 <exec+0x224>
    800051e8:	e9040993          	addi	s3,s0,-368
    800051ec:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051f0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051f2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	d90080e7          	jalr	-624(ra) # 80000f84 <strlen>
    800051fc:	0015079b          	addiw	a5,a0,1
    80005200:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005204:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005208:	13596963          	bltu	s2,s5,8000533a <exec+0x308>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000520c:	df043d83          	ld	s11,-528(s0)
    80005210:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005214:	8552                	mv	a0,s4
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	d6e080e7          	jalr	-658(ra) # 80000f84 <strlen>
    8000521e:	0015069b          	addiw	a3,a0,1
    80005222:	8652                	mv	a2,s4
    80005224:	85ca                	mv	a1,s2
    80005226:	855a                	mv	a0,s6
    80005228:	ffffc097          	auipc	ra,0xffffc
    8000522c:	560080e7          	jalr	1376(ra) # 80001788 <copyout>
    80005230:	10054963          	bltz	a0,80005342 <exec+0x310>
    ustack[argc] = sp;
    80005234:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005238:	0485                	addi	s1,s1,1
    8000523a:	008d8793          	addi	a5,s11,8
    8000523e:	def43823          	sd	a5,-528(s0)
    80005242:	008db503          	ld	a0,8(s11)
    80005246:	c911                	beqz	a0,8000525a <exec+0x228>
    if(argc >= MAXARG)
    80005248:	09a1                	addi	s3,s3,8
    8000524a:	fb3c95e3          	bne	s9,s3,800051f4 <exec+0x1c2>
  sz = sz1;
    8000524e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005252:	4a81                	li	s5,0
    80005254:	a865                	j	8000530c <exec+0x2da>
  sp = sz;
    80005256:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005258:	4481                	li	s1,0
  ustack[argc] = 0;
    8000525a:	00349793          	slli	a5,s1,0x3
    8000525e:	f9078793          	addi	a5,a5,-112
    80005262:	97a2                	add	a5,a5,s0
    80005264:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005268:	00148693          	addi	a3,s1,1
    8000526c:	068e                	slli	a3,a3,0x3
    8000526e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005272:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005276:	01597663          	bgeu	s2,s5,80005282 <exec+0x250>
  sz = sz1;
    8000527a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000527e:	4a81                	li	s5,0
    80005280:	a071                	j	8000530c <exec+0x2da>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005282:	e9040613          	addi	a2,s0,-368
    80005286:	85ca                	mv	a1,s2
    80005288:	855a                	mv	a0,s6
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	4fe080e7          	jalr	1278(ra) # 80001788 <copyout>
    80005292:	0a054c63          	bltz	a0,8000534a <exec+0x318>
  p->trapframe->a1 = sp;
    80005296:	060bb783          	ld	a5,96(s7)
    8000529a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000529e:	de843783          	ld	a5,-536(s0)
    800052a2:	0007c703          	lbu	a4,0(a5)
    800052a6:	cf11                	beqz	a4,800052c2 <exec+0x290>
    800052a8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052aa:	02f00693          	li	a3,47
    800052ae:	a039                	j	800052bc <exec+0x28a>
      last = s+1;
    800052b0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052b4:	0785                	addi	a5,a5,1
    800052b6:	fff7c703          	lbu	a4,-1(a5)
    800052ba:	c701                	beqz	a4,800052c2 <exec+0x290>
    if(*s == '/')
    800052bc:	fed71ce3          	bne	a4,a3,800052b4 <exec+0x282>
    800052c0:	bfc5                	j	800052b0 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800052c2:	4641                	li	a2,16
    800052c4:	de843583          	ld	a1,-536(s0)
    800052c8:	160b8513          	addi	a0,s7,352
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	c86080e7          	jalr	-890(ra) # 80000f52 <safestrcpy>
  oldpagetable = p->pagetable;
    800052d4:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800052d8:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800052dc:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052e0:	060bb783          	ld	a5,96(s7)
    800052e4:	e6843703          	ld	a4,-408(s0)
    800052e8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052ea:	060bb783          	ld	a5,96(s7)
    800052ee:	0327b823          	sd	s2,48(a5)
  p->priority = 20;
    800052f2:	47d1                	li	a5,20
    800052f4:	02fbaa23          	sw	a5,52(s7)
  proc_freepagetable(oldpagetable, oldsz);
    800052f8:	85ea                	mv	a1,s10
    800052fa:	ffffd097          	auipc	ra,0xffffd
    800052fe:	962080e7          	jalr	-1694(ra) # 80001c5c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005302:	0004851b          	sext.w	a0,s1
    80005306:	b3e1                	j	800050ce <exec+0x9c>
    80005308:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000530c:	df843583          	ld	a1,-520(s0)
    80005310:	855a                	mv	a0,s6
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	94a080e7          	jalr	-1718(ra) # 80001c5c <proc_freepagetable>
  if(ip){
    8000531a:	da0a90e3          	bnez	s5,800050ba <exec+0x88>
  return -1;
    8000531e:	557d                	li	a0,-1
    80005320:	b37d                	j	800050ce <exec+0x9c>
    80005322:	df243c23          	sd	s2,-520(s0)
    80005326:	b7dd                	j	8000530c <exec+0x2da>
    80005328:	df243c23          	sd	s2,-520(s0)
    8000532c:	b7c5                	j	8000530c <exec+0x2da>
    8000532e:	df243c23          	sd	s2,-520(s0)
    80005332:	bfe9                	j	8000530c <exec+0x2da>
    80005334:	df243c23          	sd	s2,-520(s0)
    80005338:	bfd1                	j	8000530c <exec+0x2da>
  sz = sz1;
    8000533a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000533e:	4a81                	li	s5,0
    80005340:	b7f1                	j	8000530c <exec+0x2da>
  sz = sz1;
    80005342:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005346:	4a81                	li	s5,0
    80005348:	b7d1                	j	8000530c <exec+0x2da>
  sz = sz1;
    8000534a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000534e:	4a81                	li	s5,0
    80005350:	bf75                	j	8000530c <exec+0x2da>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005352:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005356:	e0843783          	ld	a5,-504(s0)
    8000535a:	0017869b          	addiw	a3,a5,1
    8000535e:	e0d43423          	sd	a3,-504(s0)
    80005362:	e0043783          	ld	a5,-512(s0)
    80005366:	0387879b          	addiw	a5,a5,56
    8000536a:	e8845703          	lhu	a4,-376(s0)
    8000536e:	e0e6dce3          	bge	a3,a4,80005186 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005372:	2781                	sext.w	a5,a5
    80005374:	e0f43023          	sd	a5,-512(s0)
    80005378:	03800713          	li	a4,56
    8000537c:	86be                	mv	a3,a5
    8000537e:	e1840613          	addi	a2,s0,-488
    80005382:	4581                	li	a1,0
    80005384:	8556                	mv	a0,s5
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	a52080e7          	jalr	-1454(ra) # 80003dd8 <readi>
    8000538e:	03800793          	li	a5,56
    80005392:	f6f51be3          	bne	a0,a5,80005308 <exec+0x2d6>
    if(ph.type != ELF_PROG_LOAD)
    80005396:	e1842783          	lw	a5,-488(s0)
    8000539a:	4705                	li	a4,1
    8000539c:	fae79de3          	bne	a5,a4,80005356 <exec+0x324>
    if(ph.memsz < ph.filesz)
    800053a0:	e4043483          	ld	s1,-448(s0)
    800053a4:	e3843783          	ld	a5,-456(s0)
    800053a8:	f6f4ede3          	bltu	s1,a5,80005322 <exec+0x2f0>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053ac:	e2843783          	ld	a5,-472(s0)
    800053b0:	94be                	add	s1,s1,a5
    800053b2:	f6f4ebe3          	bltu	s1,a5,80005328 <exec+0x2f6>
    if(ph.vaddr % PGSIZE != 0)
    800053b6:	de043703          	ld	a4,-544(s0)
    800053ba:	8ff9                	and	a5,a5,a4
    800053bc:	fbad                	bnez	a5,8000532e <exec+0x2fc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053be:	e1c42503          	lw	a0,-484(s0)
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	c56080e7          	jalr	-938(ra) # 80005018 <flags2perm>
    800053ca:	86aa                	mv	a3,a0
    800053cc:	8626                	mv	a2,s1
    800053ce:	85ca                	mv	a1,s2
    800053d0:	855a                	mv	a0,s6
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	174080e7          	jalr	372(ra) # 80001546 <uvmalloc>
    800053da:	dea43c23          	sd	a0,-520(s0)
    800053de:	d939                	beqz	a0,80005334 <exec+0x302>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053e0:	e2843c03          	ld	s8,-472(s0)
    800053e4:	e2042c83          	lw	s9,-480(s0)
    800053e8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053ec:	f60b83e3          	beqz	s7,80005352 <exec+0x320>
    800053f0:	89de                	mv	s3,s7
    800053f2:	4481                	li	s1,0
    800053f4:	bb85                	j	80005164 <exec+0x132>

00000000800053f6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053f6:	7179                	addi	sp,sp,-48
    800053f8:	f406                	sd	ra,40(sp)
    800053fa:	f022                	sd	s0,32(sp)
    800053fc:	ec26                	sd	s1,24(sp)
    800053fe:	e84a                	sd	s2,16(sp)
    80005400:	1800                	addi	s0,sp,48
    80005402:	892e                	mv	s2,a1
    80005404:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005406:	fdc40593          	addi	a1,s0,-36
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	a6a080e7          	jalr	-1430(ra) # 80002e74 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005412:	fdc42703          	lw	a4,-36(s0)
    80005416:	47bd                	li	a5,15
    80005418:	02e7eb63          	bltu	a5,a4,8000544e <argfd+0x58>
    8000541c:	ffffc097          	auipc	ra,0xffffc
    80005420:	6e0080e7          	jalr	1760(ra) # 80001afc <myproc>
    80005424:	fdc42703          	lw	a4,-36(s0)
    80005428:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdb3da2>
    8000542c:	078e                	slli	a5,a5,0x3
    8000542e:	953e                	add	a0,a0,a5
    80005430:	651c                	ld	a5,8(a0)
    80005432:	c385                	beqz	a5,80005452 <argfd+0x5c>
    return -1;
  if(pfd)
    80005434:	00090463          	beqz	s2,8000543c <argfd+0x46>
    *pfd = fd;
    80005438:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000543c:	4501                	li	a0,0
  if(pf)
    8000543e:	c091                	beqz	s1,80005442 <argfd+0x4c>
    *pf = f;
    80005440:	e09c                	sd	a5,0(s1)
}
    80005442:	70a2                	ld	ra,40(sp)
    80005444:	7402                	ld	s0,32(sp)
    80005446:	64e2                	ld	s1,24(sp)
    80005448:	6942                	ld	s2,16(sp)
    8000544a:	6145                	addi	sp,sp,48
    8000544c:	8082                	ret
    return -1;
    8000544e:	557d                	li	a0,-1
    80005450:	bfcd                	j	80005442 <argfd+0x4c>
    80005452:	557d                	li	a0,-1
    80005454:	b7fd                	j	80005442 <argfd+0x4c>

0000000080005456 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005456:	1101                	addi	sp,sp,-32
    80005458:	ec06                	sd	ra,24(sp)
    8000545a:	e822                	sd	s0,16(sp)
    8000545c:	e426                	sd	s1,8(sp)
    8000545e:	1000                	addi	s0,sp,32
    80005460:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	69a080e7          	jalr	1690(ra) # 80001afc <myproc>
    8000546a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000546c:	0d850793          	addi	a5,a0,216
    80005470:	4501                	li	a0,0
    80005472:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005474:	6398                	ld	a4,0(a5)
    80005476:	cb19                	beqz	a4,8000548c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005478:	2505                	addiw	a0,a0,1
    8000547a:	07a1                	addi	a5,a5,8
    8000547c:	fed51ce3          	bne	a0,a3,80005474 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005480:	557d                	li	a0,-1
}
    80005482:	60e2                	ld	ra,24(sp)
    80005484:	6442                	ld	s0,16(sp)
    80005486:	64a2                	ld	s1,8(sp)
    80005488:	6105                	addi	sp,sp,32
    8000548a:	8082                	ret
      p->ofile[fd] = f;
    8000548c:	01a50793          	addi	a5,a0,26
    80005490:	078e                	slli	a5,a5,0x3
    80005492:	963e                	add	a2,a2,a5
    80005494:	e604                	sd	s1,8(a2)
      return fd;
    80005496:	b7f5                	j	80005482 <fdalloc+0x2c>

0000000080005498 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005498:	715d                	addi	sp,sp,-80
    8000549a:	e486                	sd	ra,72(sp)
    8000549c:	e0a2                	sd	s0,64(sp)
    8000549e:	fc26                	sd	s1,56(sp)
    800054a0:	f84a                	sd	s2,48(sp)
    800054a2:	f44e                	sd	s3,40(sp)
    800054a4:	f052                	sd	s4,32(sp)
    800054a6:	ec56                	sd	s5,24(sp)
    800054a8:	e85a                	sd	s6,16(sp)
    800054aa:	0880                	addi	s0,sp,80
    800054ac:	8b2e                	mv	s6,a1
    800054ae:	89b2                	mv	s3,a2
    800054b0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054b2:	fb040593          	addi	a1,s0,-80
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	e38080e7          	jalr	-456(ra) # 800042ee <nameiparent>
    800054be:	84aa                	mv	s1,a0
    800054c0:	14050f63          	beqz	a0,8000561e <create+0x186>
    return 0;

  ilock(dp);
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	662080e7          	jalr	1634(ra) # 80003b26 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054cc:	4601                	li	a2,0
    800054ce:	fb040593          	addi	a1,s0,-80
    800054d2:	8526                	mv	a0,s1
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	b34080e7          	jalr	-1228(ra) # 80004008 <dirlookup>
    800054dc:	8aaa                	mv	s5,a0
    800054de:	c931                	beqz	a0,80005532 <create+0x9a>
    iunlockput(dp);
    800054e0:	8526                	mv	a0,s1
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	8a6080e7          	jalr	-1882(ra) # 80003d88 <iunlockput>
    ilock(ip);
    800054ea:	8556                	mv	a0,s5
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	63a080e7          	jalr	1594(ra) # 80003b26 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054f4:	000b059b          	sext.w	a1,s6
    800054f8:	4789                	li	a5,2
    800054fa:	02f59563          	bne	a1,a5,80005524 <create+0x8c>
    800054fe:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdb3dcc>
    80005502:	37f9                	addiw	a5,a5,-2
    80005504:	17c2                	slli	a5,a5,0x30
    80005506:	93c1                	srli	a5,a5,0x30
    80005508:	4705                	li	a4,1
    8000550a:	00f76d63          	bltu	a4,a5,80005524 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000550e:	8556                	mv	a0,s5
    80005510:	60a6                	ld	ra,72(sp)
    80005512:	6406                	ld	s0,64(sp)
    80005514:	74e2                	ld	s1,56(sp)
    80005516:	7942                	ld	s2,48(sp)
    80005518:	79a2                	ld	s3,40(sp)
    8000551a:	7a02                	ld	s4,32(sp)
    8000551c:	6ae2                	ld	s5,24(sp)
    8000551e:	6b42                	ld	s6,16(sp)
    80005520:	6161                	addi	sp,sp,80
    80005522:	8082                	ret
    iunlockput(ip);
    80005524:	8556                	mv	a0,s5
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	862080e7          	jalr	-1950(ra) # 80003d88 <iunlockput>
    return 0;
    8000552e:	4a81                	li	s5,0
    80005530:	bff9                	j	8000550e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005532:	85da                	mv	a1,s6
    80005534:	4088                	lw	a0,0(s1)
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	452080e7          	jalr	1106(ra) # 80003988 <ialloc>
    8000553e:	8a2a                	mv	s4,a0
    80005540:	c539                	beqz	a0,8000558e <create+0xf6>
  ilock(ip);
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	5e4080e7          	jalr	1508(ra) # 80003b26 <ilock>
  ip->major = major;
    8000554a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000554e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005552:	4905                	li	s2,1
    80005554:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005558:	8552                	mv	a0,s4
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	500080e7          	jalr	1280(ra) # 80003a5a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005562:	000b059b          	sext.w	a1,s6
    80005566:	03258b63          	beq	a1,s2,8000559c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000556a:	004a2603          	lw	a2,4(s4)
    8000556e:	fb040593          	addi	a1,s0,-80
    80005572:	8526                	mv	a0,s1
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	caa080e7          	jalr	-854(ra) # 8000421e <dirlink>
    8000557c:	06054f63          	bltz	a0,800055fa <create+0x162>
  iunlockput(dp);
    80005580:	8526                	mv	a0,s1
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	806080e7          	jalr	-2042(ra) # 80003d88 <iunlockput>
  return ip;
    8000558a:	8ad2                	mv	s5,s4
    8000558c:	b749                	j	8000550e <create+0x76>
    iunlockput(dp);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	7f8080e7          	jalr	2040(ra) # 80003d88 <iunlockput>
    return 0;
    80005598:	8ad2                	mv	s5,s4
    8000559a:	bf95                	j	8000550e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000559c:	004a2603          	lw	a2,4(s4)
    800055a0:	00003597          	auipc	a1,0x3
    800055a4:	3e858593          	addi	a1,a1,1000 # 80008988 <names+0x2c0>
    800055a8:	8552                	mv	a0,s4
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	c74080e7          	jalr	-908(ra) # 8000421e <dirlink>
    800055b2:	04054463          	bltz	a0,800055fa <create+0x162>
    800055b6:	40d0                	lw	a2,4(s1)
    800055b8:	00003597          	auipc	a1,0x3
    800055bc:	3d858593          	addi	a1,a1,984 # 80008990 <names+0x2c8>
    800055c0:	8552                	mv	a0,s4
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	c5c080e7          	jalr	-932(ra) # 8000421e <dirlink>
    800055ca:	02054863          	bltz	a0,800055fa <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800055ce:	004a2603          	lw	a2,4(s4)
    800055d2:	fb040593          	addi	a1,s0,-80
    800055d6:	8526                	mv	a0,s1
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	c46080e7          	jalr	-954(ra) # 8000421e <dirlink>
    800055e0:	00054d63          	bltz	a0,800055fa <create+0x162>
    dp->nlink++;  // for ".."
    800055e4:	04a4d783          	lhu	a5,74(s1)
    800055e8:	2785                	addiw	a5,a5,1
    800055ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	46a080e7          	jalr	1130(ra) # 80003a5a <iupdate>
    800055f8:	b761                	j	80005580 <create+0xe8>
  ip->nlink = 0;
    800055fa:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055fe:	8552                	mv	a0,s4
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	45a080e7          	jalr	1114(ra) # 80003a5a <iupdate>
  iunlockput(ip);
    80005608:	8552                	mv	a0,s4
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	77e080e7          	jalr	1918(ra) # 80003d88 <iunlockput>
  iunlockput(dp);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	774080e7          	jalr	1908(ra) # 80003d88 <iunlockput>
  return 0;
    8000561c:	bdcd                	j	8000550e <create+0x76>
    return 0;
    8000561e:	8aaa                	mv	s5,a0
    80005620:	b5fd                	j	8000550e <create+0x76>

0000000080005622 <sys_dup>:
{
    80005622:	7179                	addi	sp,sp,-48
    80005624:	f406                	sd	ra,40(sp)
    80005626:	f022                	sd	s0,32(sp)
    80005628:	ec26                	sd	s1,24(sp)
    8000562a:	e84a                	sd	s2,16(sp)
    8000562c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000562e:	fd840613          	addi	a2,s0,-40
    80005632:	4581                	li	a1,0
    80005634:	4501                	li	a0,0
    80005636:	00000097          	auipc	ra,0x0
    8000563a:	dc0080e7          	jalr	-576(ra) # 800053f6 <argfd>
    return -1;
    8000563e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005640:	02054363          	bltz	a0,80005666 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005644:	fd843903          	ld	s2,-40(s0)
    80005648:	854a                	mv	a0,s2
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	e0c080e7          	jalr	-500(ra) # 80005456 <fdalloc>
    80005652:	84aa                	mv	s1,a0
    return -1;
    80005654:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005656:	00054863          	bltz	a0,80005666 <sys_dup+0x44>
  filedup(f);
    8000565a:	854a                	mv	a0,s2
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	30a080e7          	jalr	778(ra) # 80004966 <filedup>
  return fd;
    80005664:	87a6                	mv	a5,s1
}
    80005666:	853e                	mv	a0,a5
    80005668:	70a2                	ld	ra,40(sp)
    8000566a:	7402                	ld	s0,32(sp)
    8000566c:	64e2                	ld	s1,24(sp)
    8000566e:	6942                	ld	s2,16(sp)
    80005670:	6145                	addi	sp,sp,48
    80005672:	8082                	ret

0000000080005674 <sys_read>:
{
    80005674:	7179                	addi	sp,sp,-48
    80005676:	f406                	sd	ra,40(sp)
    80005678:	f022                	sd	s0,32(sp)
    8000567a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000567c:	fd840593          	addi	a1,s0,-40
    80005680:	4505                	li	a0,1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	812080e7          	jalr	-2030(ra) # 80002e94 <argaddr>
  argint(2, &n);
    8000568a:	fe440593          	addi	a1,s0,-28
    8000568e:	4509                	li	a0,2
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	7e4080e7          	jalr	2020(ra) # 80002e74 <argint>
  if(argfd(0, 0, &f) < 0)
    80005698:	fe840613          	addi	a2,s0,-24
    8000569c:	4581                	li	a1,0
    8000569e:	4501                	li	a0,0
    800056a0:	00000097          	auipc	ra,0x0
    800056a4:	d56080e7          	jalr	-682(ra) # 800053f6 <argfd>
    800056a8:	87aa                	mv	a5,a0
    return -1;
    800056aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056ac:	0007cc63          	bltz	a5,800056c4 <sys_read+0x50>
  return fileread(f, p, n);
    800056b0:	fe442603          	lw	a2,-28(s0)
    800056b4:	fd843583          	ld	a1,-40(s0)
    800056b8:	fe843503          	ld	a0,-24(s0)
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	436080e7          	jalr	1078(ra) # 80004af2 <fileread>
}
    800056c4:	70a2                	ld	ra,40(sp)
    800056c6:	7402                	ld	s0,32(sp)
    800056c8:	6145                	addi	sp,sp,48
    800056ca:	8082                	ret

00000000800056cc <sys_write>:
{
    800056cc:	7179                	addi	sp,sp,-48
    800056ce:	f406                	sd	ra,40(sp)
    800056d0:	f022                	sd	s0,32(sp)
    800056d2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056d4:	fd840593          	addi	a1,s0,-40
    800056d8:	4505                	li	a0,1
    800056da:	ffffd097          	auipc	ra,0xffffd
    800056de:	7ba080e7          	jalr	1978(ra) # 80002e94 <argaddr>
  argint(2, &n);
    800056e2:	fe440593          	addi	a1,s0,-28
    800056e6:	4509                	li	a0,2
    800056e8:	ffffd097          	auipc	ra,0xffffd
    800056ec:	78c080e7          	jalr	1932(ra) # 80002e74 <argint>
  if(argfd(0, 0, &f) < 0)
    800056f0:	fe840613          	addi	a2,s0,-24
    800056f4:	4581                	li	a1,0
    800056f6:	4501                	li	a0,0
    800056f8:	00000097          	auipc	ra,0x0
    800056fc:	cfe080e7          	jalr	-770(ra) # 800053f6 <argfd>
    80005700:	87aa                	mv	a5,a0
    return -1;
    80005702:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005704:	0007cc63          	bltz	a5,8000571c <sys_write+0x50>
  return filewrite(f, p, n);
    80005708:	fe442603          	lw	a2,-28(s0)
    8000570c:	fd843583          	ld	a1,-40(s0)
    80005710:	fe843503          	ld	a0,-24(s0)
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	4a0080e7          	jalr	1184(ra) # 80004bb4 <filewrite>
}
    8000571c:	70a2                	ld	ra,40(sp)
    8000571e:	7402                	ld	s0,32(sp)
    80005720:	6145                	addi	sp,sp,48
    80005722:	8082                	ret

0000000080005724 <sys_close>:
{
    80005724:	1101                	addi	sp,sp,-32
    80005726:	ec06                	sd	ra,24(sp)
    80005728:	e822                	sd	s0,16(sp)
    8000572a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000572c:	fe040613          	addi	a2,s0,-32
    80005730:	fec40593          	addi	a1,s0,-20
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	cc0080e7          	jalr	-832(ra) # 800053f6 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005740:	02054463          	bltz	a0,80005768 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	3b8080e7          	jalr	952(ra) # 80001afc <myproc>
    8000574c:	fec42783          	lw	a5,-20(s0)
    80005750:	07e9                	addi	a5,a5,26
    80005752:	078e                	slli	a5,a5,0x3
    80005754:	953e                	add	a0,a0,a5
    80005756:	00053423          	sd	zero,8(a0)
  fileclose(f);
    8000575a:	fe043503          	ld	a0,-32(s0)
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	25a080e7          	jalr	602(ra) # 800049b8 <fileclose>
  return 0;
    80005766:	4781                	li	a5,0
}
    80005768:	853e                	mv	a0,a5
    8000576a:	60e2                	ld	ra,24(sp)
    8000576c:	6442                	ld	s0,16(sp)
    8000576e:	6105                	addi	sp,sp,32
    80005770:	8082                	ret

0000000080005772 <sys_fstat>:
{
    80005772:	1101                	addi	sp,sp,-32
    80005774:	ec06                	sd	ra,24(sp)
    80005776:	e822                	sd	s0,16(sp)
    80005778:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000577a:	fe040593          	addi	a1,s0,-32
    8000577e:	4505                	li	a0,1
    80005780:	ffffd097          	auipc	ra,0xffffd
    80005784:	714080e7          	jalr	1812(ra) # 80002e94 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005788:	fe840613          	addi	a2,s0,-24
    8000578c:	4581                	li	a1,0
    8000578e:	4501                	li	a0,0
    80005790:	00000097          	auipc	ra,0x0
    80005794:	c66080e7          	jalr	-922(ra) # 800053f6 <argfd>
    80005798:	87aa                	mv	a5,a0
    return -1;
    8000579a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000579c:	0007ca63          	bltz	a5,800057b0 <sys_fstat+0x3e>
  return filestat(f, st);
    800057a0:	fe043583          	ld	a1,-32(s0)
    800057a4:	fe843503          	ld	a0,-24(s0)
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	2d8080e7          	jalr	728(ra) # 80004a80 <filestat>
}
    800057b0:	60e2                	ld	ra,24(sp)
    800057b2:	6442                	ld	s0,16(sp)
    800057b4:	6105                	addi	sp,sp,32
    800057b6:	8082                	ret

00000000800057b8 <sys_link>:
{
    800057b8:	7169                	addi	sp,sp,-304
    800057ba:	f606                	sd	ra,296(sp)
    800057bc:	f222                	sd	s0,288(sp)
    800057be:	ee26                	sd	s1,280(sp)
    800057c0:	ea4a                	sd	s2,272(sp)
    800057c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c4:	08000613          	li	a2,128
    800057c8:	ed040593          	addi	a1,s0,-304
    800057cc:	4501                	li	a0,0
    800057ce:	ffffd097          	auipc	ra,0xffffd
    800057d2:	6e6080e7          	jalr	1766(ra) # 80002eb4 <argstr>
    return -1;
    800057d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d8:	10054e63          	bltz	a0,800058f4 <sys_link+0x13c>
    800057dc:	08000613          	li	a2,128
    800057e0:	f5040593          	addi	a1,s0,-176
    800057e4:	4505                	li	a0,1
    800057e6:	ffffd097          	auipc	ra,0xffffd
    800057ea:	6ce080e7          	jalr	1742(ra) # 80002eb4 <argstr>
    return -1;
    800057ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f0:	10054263          	bltz	a0,800058f4 <sys_link+0x13c>
  begin_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	cfc080e7          	jalr	-772(ra) # 800044f0 <begin_op>
  if((ip = namei(old)) == 0){
    800057fc:	ed040513          	addi	a0,s0,-304
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	ad0080e7          	jalr	-1328(ra) # 800042d0 <namei>
    80005808:	84aa                	mv	s1,a0
    8000580a:	c551                	beqz	a0,80005896 <sys_link+0xde>
  ilock(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	31a080e7          	jalr	794(ra) # 80003b26 <ilock>
  if(ip->type == T_DIR){
    80005814:	04449703          	lh	a4,68(s1)
    80005818:	4785                	li	a5,1
    8000581a:	08f70463          	beq	a4,a5,800058a2 <sys_link+0xea>
  ip->nlink++;
    8000581e:	04a4d783          	lhu	a5,74(s1)
    80005822:	2785                	addiw	a5,a5,1
    80005824:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	230080e7          	jalr	560(ra) # 80003a5a <iupdate>
  iunlock(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	3b4080e7          	jalr	948(ra) # 80003be8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000583c:	fd040593          	addi	a1,s0,-48
    80005840:	f5040513          	addi	a0,s0,-176
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	aaa080e7          	jalr	-1366(ra) # 800042ee <nameiparent>
    8000584c:	892a                	mv	s2,a0
    8000584e:	c935                	beqz	a0,800058c2 <sys_link+0x10a>
  ilock(dp);
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	2d6080e7          	jalr	726(ra) # 80003b26 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005858:	00092703          	lw	a4,0(s2)
    8000585c:	409c                	lw	a5,0(s1)
    8000585e:	04f71d63          	bne	a4,a5,800058b8 <sys_link+0x100>
    80005862:	40d0                	lw	a2,4(s1)
    80005864:	fd040593          	addi	a1,s0,-48
    80005868:	854a                	mv	a0,s2
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	9b4080e7          	jalr	-1612(ra) # 8000421e <dirlink>
    80005872:	04054363          	bltz	a0,800058b8 <sys_link+0x100>
  iunlockput(dp);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	510080e7          	jalr	1296(ra) # 80003d88 <iunlockput>
  iput(ip);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	45e080e7          	jalr	1118(ra) # 80003ce0 <iput>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	ce4080e7          	jalr	-796(ra) # 8000456e <end_op>
  return 0;
    80005892:	4781                	li	a5,0
    80005894:	a085                	j	800058f4 <sys_link+0x13c>
    end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	cd8080e7          	jalr	-808(ra) # 8000456e <end_op>
    return -1;
    8000589e:	57fd                	li	a5,-1
    800058a0:	a891                	j	800058f4 <sys_link+0x13c>
    iunlockput(ip);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	4e4080e7          	jalr	1252(ra) # 80003d88 <iunlockput>
    end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	cc2080e7          	jalr	-830(ra) # 8000456e <end_op>
    return -1;
    800058b4:	57fd                	li	a5,-1
    800058b6:	a83d                	j	800058f4 <sys_link+0x13c>
    iunlockput(dp);
    800058b8:	854a                	mv	a0,s2
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	4ce080e7          	jalr	1230(ra) # 80003d88 <iunlockput>
  ilock(ip);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	262080e7          	jalr	610(ra) # 80003b26 <ilock>
  ip->nlink--;
    800058cc:	04a4d783          	lhu	a5,74(s1)
    800058d0:	37fd                	addiw	a5,a5,-1
    800058d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	182080e7          	jalr	386(ra) # 80003a5a <iupdate>
  iunlockput(ip);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	4a6080e7          	jalr	1190(ra) # 80003d88 <iunlockput>
  end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	c84080e7          	jalr	-892(ra) # 8000456e <end_op>
  return -1;
    800058f2:	57fd                	li	a5,-1
}
    800058f4:	853e                	mv	a0,a5
    800058f6:	70b2                	ld	ra,296(sp)
    800058f8:	7412                	ld	s0,288(sp)
    800058fa:	64f2                	ld	s1,280(sp)
    800058fc:	6952                	ld	s2,272(sp)
    800058fe:	6155                	addi	sp,sp,304
    80005900:	8082                	ret

0000000080005902 <sys_unlink>:
{
    80005902:	7151                	addi	sp,sp,-240
    80005904:	f586                	sd	ra,232(sp)
    80005906:	f1a2                	sd	s0,224(sp)
    80005908:	eda6                	sd	s1,216(sp)
    8000590a:	e9ca                	sd	s2,208(sp)
    8000590c:	e5ce                	sd	s3,200(sp)
    8000590e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005910:	08000613          	li	a2,128
    80005914:	f3040593          	addi	a1,s0,-208
    80005918:	4501                	li	a0,0
    8000591a:	ffffd097          	auipc	ra,0xffffd
    8000591e:	59a080e7          	jalr	1434(ra) # 80002eb4 <argstr>
    80005922:	18054163          	bltz	a0,80005aa4 <sys_unlink+0x1a2>
  begin_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	bca080e7          	jalr	-1078(ra) # 800044f0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000592e:	fb040593          	addi	a1,s0,-80
    80005932:	f3040513          	addi	a0,s0,-208
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	9b8080e7          	jalr	-1608(ra) # 800042ee <nameiparent>
    8000593e:	84aa                	mv	s1,a0
    80005940:	c979                	beqz	a0,80005a16 <sys_unlink+0x114>
  ilock(dp);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	1e4080e7          	jalr	484(ra) # 80003b26 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000594a:	00003597          	auipc	a1,0x3
    8000594e:	03e58593          	addi	a1,a1,62 # 80008988 <names+0x2c0>
    80005952:	fb040513          	addi	a0,s0,-80
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	698080e7          	jalr	1688(ra) # 80003fee <namecmp>
    8000595e:	14050a63          	beqz	a0,80005ab2 <sys_unlink+0x1b0>
    80005962:	00003597          	auipc	a1,0x3
    80005966:	02e58593          	addi	a1,a1,46 # 80008990 <names+0x2c8>
    8000596a:	fb040513          	addi	a0,s0,-80
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	680080e7          	jalr	1664(ra) # 80003fee <namecmp>
    80005976:	12050e63          	beqz	a0,80005ab2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000597a:	f2c40613          	addi	a2,s0,-212
    8000597e:	fb040593          	addi	a1,s0,-80
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	684080e7          	jalr	1668(ra) # 80004008 <dirlookup>
    8000598c:	892a                	mv	s2,a0
    8000598e:	12050263          	beqz	a0,80005ab2 <sys_unlink+0x1b0>
  ilock(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	194080e7          	jalr	404(ra) # 80003b26 <ilock>
  if(ip->nlink < 1)
    8000599a:	04a91783          	lh	a5,74(s2)
    8000599e:	08f05263          	blez	a5,80005a22 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059a2:	04491703          	lh	a4,68(s2)
    800059a6:	4785                	li	a5,1
    800059a8:	08f70563          	beq	a4,a5,80005a32 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059ac:	4641                	li	a2,16
    800059ae:	4581                	li	a1,0
    800059b0:	fc040513          	addi	a0,s0,-64
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	454080e7          	jalr	1108(ra) # 80000e08 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059bc:	4741                	li	a4,16
    800059be:	f2c42683          	lw	a3,-212(s0)
    800059c2:	fc040613          	addi	a2,s0,-64
    800059c6:	4581                	li	a1,0
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	506080e7          	jalr	1286(ra) # 80003ed0 <writei>
    800059d2:	47c1                	li	a5,16
    800059d4:	0af51563          	bne	a0,a5,80005a7e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059d8:	04491703          	lh	a4,68(s2)
    800059dc:	4785                	li	a5,1
    800059de:	0af70863          	beq	a4,a5,80005a8e <sys_unlink+0x18c>
  iunlockput(dp);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	3a4080e7          	jalr	932(ra) # 80003d88 <iunlockput>
  ip->nlink--;
    800059ec:	04a95783          	lhu	a5,74(s2)
    800059f0:	37fd                	addiw	a5,a5,-1
    800059f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059f6:	854a                	mv	a0,s2
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	062080e7          	jalr	98(ra) # 80003a5a <iupdate>
  iunlockput(ip);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	386080e7          	jalr	902(ra) # 80003d88 <iunlockput>
  end_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	b64080e7          	jalr	-1180(ra) # 8000456e <end_op>
  return 0;
    80005a12:	4501                	li	a0,0
    80005a14:	a84d                	j	80005ac6 <sys_unlink+0x1c4>
    end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	b58080e7          	jalr	-1192(ra) # 8000456e <end_op>
    return -1;
    80005a1e:	557d                	li	a0,-1
    80005a20:	a05d                	j	80005ac6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a22:	00003517          	auipc	a0,0x3
    80005a26:	f7650513          	addi	a0,a0,-138 # 80008998 <names+0x2d0>
    80005a2a:	ffffb097          	auipc	ra,0xffffb
    80005a2e:	b16080e7          	jalr	-1258(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a32:	04c92703          	lw	a4,76(s2)
    80005a36:	02000793          	li	a5,32
    80005a3a:	f6e7f9e3          	bgeu	a5,a4,800059ac <sys_unlink+0xaa>
    80005a3e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a42:	4741                	li	a4,16
    80005a44:	86ce                	mv	a3,s3
    80005a46:	f1840613          	addi	a2,s0,-232
    80005a4a:	4581                	li	a1,0
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	38a080e7          	jalr	906(ra) # 80003dd8 <readi>
    80005a56:	47c1                	li	a5,16
    80005a58:	00f51b63          	bne	a0,a5,80005a6e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a5c:	f1845783          	lhu	a5,-232(s0)
    80005a60:	e7a1                	bnez	a5,80005aa8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a62:	29c1                	addiw	s3,s3,16
    80005a64:	04c92783          	lw	a5,76(s2)
    80005a68:	fcf9ede3          	bltu	s3,a5,80005a42 <sys_unlink+0x140>
    80005a6c:	b781                	j	800059ac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a6e:	00003517          	auipc	a0,0x3
    80005a72:	f4250513          	addi	a0,a0,-190 # 800089b0 <names+0x2e8>
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	aca080e7          	jalr	-1334(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a7e:	00003517          	auipc	a0,0x3
    80005a82:	f4a50513          	addi	a0,a0,-182 # 800089c8 <names+0x300>
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	aba080e7          	jalr	-1350(ra) # 80000540 <panic>
    dp->nlink--;
    80005a8e:	04a4d783          	lhu	a5,74(s1)
    80005a92:	37fd                	addiw	a5,a5,-1
    80005a94:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a98:	8526                	mv	a0,s1
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	fc0080e7          	jalr	-64(ra) # 80003a5a <iupdate>
    80005aa2:	b781                	j	800059e2 <sys_unlink+0xe0>
    return -1;
    80005aa4:	557d                	li	a0,-1
    80005aa6:	a005                	j	80005ac6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	2de080e7          	jalr	734(ra) # 80003d88 <iunlockput>
  iunlockput(dp);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	2d4080e7          	jalr	724(ra) # 80003d88 <iunlockput>
  end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	ab2080e7          	jalr	-1358(ra) # 8000456e <end_op>
  return -1;
    80005ac4:	557d                	li	a0,-1
}
    80005ac6:	70ae                	ld	ra,232(sp)
    80005ac8:	740e                	ld	s0,224(sp)
    80005aca:	64ee                	ld	s1,216(sp)
    80005acc:	694e                	ld	s2,208(sp)
    80005ace:	69ae                	ld	s3,200(sp)
    80005ad0:	616d                	addi	sp,sp,240
    80005ad2:	8082                	ret

0000000080005ad4 <sys_open>:

uint64
sys_open(void)
{
    80005ad4:	7131                	addi	sp,sp,-192
    80005ad6:	fd06                	sd	ra,184(sp)
    80005ad8:	f922                	sd	s0,176(sp)
    80005ada:	f526                	sd	s1,168(sp)
    80005adc:	f14a                	sd	s2,160(sp)
    80005ade:	ed4e                	sd	s3,152(sp)
    80005ae0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ae2:	f4c40593          	addi	a1,s0,-180
    80005ae6:	4505                	li	a0,1
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	38c080e7          	jalr	908(ra) # 80002e74 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005af0:	08000613          	li	a2,128
    80005af4:	f5040593          	addi	a1,s0,-176
    80005af8:	4501                	li	a0,0
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	3ba080e7          	jalr	954(ra) # 80002eb4 <argstr>
    80005b02:	87aa                	mv	a5,a0
    return -1;
    80005b04:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b06:	0a07c963          	bltz	a5,80005bb8 <sys_open+0xe4>

  begin_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	9e6080e7          	jalr	-1562(ra) # 800044f0 <begin_op>

  if(omode & O_CREATE){
    80005b12:	f4c42783          	lw	a5,-180(s0)
    80005b16:	2007f793          	andi	a5,a5,512
    80005b1a:	cfc5                	beqz	a5,80005bd2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b1c:	4681                	li	a3,0
    80005b1e:	4601                	li	a2,0
    80005b20:	4589                	li	a1,2
    80005b22:	f5040513          	addi	a0,s0,-176
    80005b26:	00000097          	auipc	ra,0x0
    80005b2a:	972080e7          	jalr	-1678(ra) # 80005498 <create>
    80005b2e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b30:	c959                	beqz	a0,80005bc6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b32:	04449703          	lh	a4,68(s1)
    80005b36:	478d                	li	a5,3
    80005b38:	00f71763          	bne	a4,a5,80005b46 <sys_open+0x72>
    80005b3c:	0464d703          	lhu	a4,70(s1)
    80005b40:	47a5                	li	a5,9
    80005b42:	0ce7ed63          	bltu	a5,a4,80005c1c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	db6080e7          	jalr	-586(ra) # 800048fc <filealloc>
    80005b4e:	89aa                	mv	s3,a0
    80005b50:	10050363          	beqz	a0,80005c56 <sys_open+0x182>
    80005b54:	00000097          	auipc	ra,0x0
    80005b58:	902080e7          	jalr	-1790(ra) # 80005456 <fdalloc>
    80005b5c:	892a                	mv	s2,a0
    80005b5e:	0e054763          	bltz	a0,80005c4c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b62:	04449703          	lh	a4,68(s1)
    80005b66:	478d                	li	a5,3
    80005b68:	0cf70563          	beq	a4,a5,80005c32 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b6c:	4789                	li	a5,2
    80005b6e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b72:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b76:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b7a:	f4c42783          	lw	a5,-180(s0)
    80005b7e:	0017c713          	xori	a4,a5,1
    80005b82:	8b05                	andi	a4,a4,1
    80005b84:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b88:	0037f713          	andi	a4,a5,3
    80005b8c:	00e03733          	snez	a4,a4
    80005b90:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b94:	4007f793          	andi	a5,a5,1024
    80005b98:	c791                	beqz	a5,80005ba4 <sys_open+0xd0>
    80005b9a:	04449703          	lh	a4,68(s1)
    80005b9e:	4789                	li	a5,2
    80005ba0:	0af70063          	beq	a4,a5,80005c40 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ba4:	8526                	mv	a0,s1
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	042080e7          	jalr	66(ra) # 80003be8 <iunlock>
  end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	9c0080e7          	jalr	-1600(ra) # 8000456e <end_op>

  return fd;
    80005bb6:	854a                	mv	a0,s2
}
    80005bb8:	70ea                	ld	ra,184(sp)
    80005bba:	744a                	ld	s0,176(sp)
    80005bbc:	74aa                	ld	s1,168(sp)
    80005bbe:	790a                	ld	s2,160(sp)
    80005bc0:	69ea                	ld	s3,152(sp)
    80005bc2:	6129                	addi	sp,sp,192
    80005bc4:	8082                	ret
      end_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	9a8080e7          	jalr	-1624(ra) # 8000456e <end_op>
      return -1;
    80005bce:	557d                	li	a0,-1
    80005bd0:	b7e5                	j	80005bb8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bd2:	f5040513          	addi	a0,s0,-176
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	6fa080e7          	jalr	1786(ra) # 800042d0 <namei>
    80005bde:	84aa                	mv	s1,a0
    80005be0:	c905                	beqz	a0,80005c10 <sys_open+0x13c>
    ilock(ip);
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	f44080e7          	jalr	-188(ra) # 80003b26 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bea:	04449703          	lh	a4,68(s1)
    80005bee:	4785                	li	a5,1
    80005bf0:	f4f711e3          	bne	a4,a5,80005b32 <sys_open+0x5e>
    80005bf4:	f4c42783          	lw	a5,-180(s0)
    80005bf8:	d7b9                	beqz	a5,80005b46 <sys_open+0x72>
      iunlockput(ip);
    80005bfa:	8526                	mv	a0,s1
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	18c080e7          	jalr	396(ra) # 80003d88 <iunlockput>
      end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	96a080e7          	jalr	-1686(ra) # 8000456e <end_op>
      return -1;
    80005c0c:	557d                	li	a0,-1
    80005c0e:	b76d                	j	80005bb8 <sys_open+0xe4>
      end_op();
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	95e080e7          	jalr	-1698(ra) # 8000456e <end_op>
      return -1;
    80005c18:	557d                	li	a0,-1
    80005c1a:	bf79                	j	80005bb8 <sys_open+0xe4>
    iunlockput(ip);
    80005c1c:	8526                	mv	a0,s1
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	16a080e7          	jalr	362(ra) # 80003d88 <iunlockput>
    end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	948080e7          	jalr	-1720(ra) # 8000456e <end_op>
    return -1;
    80005c2e:	557d                	li	a0,-1
    80005c30:	b761                	j	80005bb8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c32:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c36:	04649783          	lh	a5,70(s1)
    80005c3a:	02f99223          	sh	a5,36(s3)
    80005c3e:	bf25                	j	80005b76 <sys_open+0xa2>
    itrunc(ip);
    80005c40:	8526                	mv	a0,s1
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	ff2080e7          	jalr	-14(ra) # 80003c34 <itrunc>
    80005c4a:	bfa9                	j	80005ba4 <sys_open+0xd0>
      fileclose(f);
    80005c4c:	854e                	mv	a0,s3
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	d6a080e7          	jalr	-662(ra) # 800049b8 <fileclose>
    iunlockput(ip);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	130080e7          	jalr	304(ra) # 80003d88 <iunlockput>
    end_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	90e080e7          	jalr	-1778(ra) # 8000456e <end_op>
    return -1;
    80005c68:	557d                	li	a0,-1
    80005c6a:	b7b9                	j	80005bb8 <sys_open+0xe4>

0000000080005c6c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c6c:	7175                	addi	sp,sp,-144
    80005c6e:	e506                	sd	ra,136(sp)
    80005c70:	e122                	sd	s0,128(sp)
    80005c72:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	87c080e7          	jalr	-1924(ra) # 800044f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c7c:	08000613          	li	a2,128
    80005c80:	f7040593          	addi	a1,s0,-144
    80005c84:	4501                	li	a0,0
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	22e080e7          	jalr	558(ra) # 80002eb4 <argstr>
    80005c8e:	02054963          	bltz	a0,80005cc0 <sys_mkdir+0x54>
    80005c92:	4681                	li	a3,0
    80005c94:	4601                	li	a2,0
    80005c96:	4585                	li	a1,1
    80005c98:	f7040513          	addi	a0,s0,-144
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	7fc080e7          	jalr	2044(ra) # 80005498 <create>
    80005ca4:	cd11                	beqz	a0,80005cc0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	0e2080e7          	jalr	226(ra) # 80003d88 <iunlockput>
  end_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	8c0080e7          	jalr	-1856(ra) # 8000456e <end_op>
  return 0;
    80005cb6:	4501                	li	a0,0
}
    80005cb8:	60aa                	ld	ra,136(sp)
    80005cba:	640a                	ld	s0,128(sp)
    80005cbc:	6149                	addi	sp,sp,144
    80005cbe:	8082                	ret
    end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	8ae080e7          	jalr	-1874(ra) # 8000456e <end_op>
    return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	b7fd                	j	80005cb8 <sys_mkdir+0x4c>

0000000080005ccc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ccc:	7135                	addi	sp,sp,-160
    80005cce:	ed06                	sd	ra,152(sp)
    80005cd0:	e922                	sd	s0,144(sp)
    80005cd2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	81c080e7          	jalr	-2020(ra) # 800044f0 <begin_op>
  argint(1, &major);
    80005cdc:	f6c40593          	addi	a1,s0,-148
    80005ce0:	4505                	li	a0,1
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	192080e7          	jalr	402(ra) # 80002e74 <argint>
  argint(2, &minor);
    80005cea:	f6840593          	addi	a1,s0,-152
    80005cee:	4509                	li	a0,2
    80005cf0:	ffffd097          	auipc	ra,0xffffd
    80005cf4:	184080e7          	jalr	388(ra) # 80002e74 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cf8:	08000613          	li	a2,128
    80005cfc:	f7040593          	addi	a1,s0,-144
    80005d00:	4501                	li	a0,0
    80005d02:	ffffd097          	auipc	ra,0xffffd
    80005d06:	1b2080e7          	jalr	434(ra) # 80002eb4 <argstr>
    80005d0a:	02054b63          	bltz	a0,80005d40 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d0e:	f6841683          	lh	a3,-152(s0)
    80005d12:	f6c41603          	lh	a2,-148(s0)
    80005d16:	458d                	li	a1,3
    80005d18:	f7040513          	addi	a0,s0,-144
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	77c080e7          	jalr	1916(ra) # 80005498 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d24:	cd11                	beqz	a0,80005d40 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	062080e7          	jalr	98(ra) # 80003d88 <iunlockput>
  end_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	840080e7          	jalr	-1984(ra) # 8000456e <end_op>
  return 0;
    80005d36:	4501                	li	a0,0
}
    80005d38:	60ea                	ld	ra,152(sp)
    80005d3a:	644a                	ld	s0,144(sp)
    80005d3c:	610d                	addi	sp,sp,160
    80005d3e:	8082                	ret
    end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	82e080e7          	jalr	-2002(ra) # 8000456e <end_op>
    return -1;
    80005d48:	557d                	li	a0,-1
    80005d4a:	b7fd                	j	80005d38 <sys_mknod+0x6c>

0000000080005d4c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d4c:	7135                	addi	sp,sp,-160
    80005d4e:	ed06                	sd	ra,152(sp)
    80005d50:	e922                	sd	s0,144(sp)
    80005d52:	e526                	sd	s1,136(sp)
    80005d54:	e14a                	sd	s2,128(sp)
    80005d56:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	da4080e7          	jalr	-604(ra) # 80001afc <myproc>
    80005d60:	892a                	mv	s2,a0
  
  begin_op();
    80005d62:	ffffe097          	auipc	ra,0xffffe
    80005d66:	78e080e7          	jalr	1934(ra) # 800044f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d6a:	08000613          	li	a2,128
    80005d6e:	f6040593          	addi	a1,s0,-160
    80005d72:	4501                	li	a0,0
    80005d74:	ffffd097          	auipc	ra,0xffffd
    80005d78:	140080e7          	jalr	320(ra) # 80002eb4 <argstr>
    80005d7c:	04054b63          	bltz	a0,80005dd2 <sys_chdir+0x86>
    80005d80:	f6040513          	addi	a0,s0,-160
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	54c080e7          	jalr	1356(ra) # 800042d0 <namei>
    80005d8c:	84aa                	mv	s1,a0
    80005d8e:	c131                	beqz	a0,80005dd2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	d96080e7          	jalr	-618(ra) # 80003b26 <ilock>
  if(ip->type != T_DIR){
    80005d98:	04449703          	lh	a4,68(s1)
    80005d9c:	4785                	li	a5,1
    80005d9e:	04f71063          	bne	a4,a5,80005dde <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005da2:	8526                	mv	a0,s1
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	e44080e7          	jalr	-444(ra) # 80003be8 <iunlock>
  iput(p->cwd);
    80005dac:	15893503          	ld	a0,344(s2)
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	f30080e7          	jalr	-208(ra) # 80003ce0 <iput>
  end_op();
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	7b6080e7          	jalr	1974(ra) # 8000456e <end_op>
  p->cwd = ip;
    80005dc0:	14993c23          	sd	s1,344(s2)
  return 0;
    80005dc4:	4501                	li	a0,0
}
    80005dc6:	60ea                	ld	ra,152(sp)
    80005dc8:	644a                	ld	s0,144(sp)
    80005dca:	64aa                	ld	s1,136(sp)
    80005dcc:	690a                	ld	s2,128(sp)
    80005dce:	610d                	addi	sp,sp,160
    80005dd0:	8082                	ret
    end_op();
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	79c080e7          	jalr	1948(ra) # 8000456e <end_op>
    return -1;
    80005dda:	557d                	li	a0,-1
    80005ddc:	b7ed                	j	80005dc6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	fa8080e7          	jalr	-88(ra) # 80003d88 <iunlockput>
    end_op();
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	786080e7          	jalr	1926(ra) # 8000456e <end_op>
    return -1;
    80005df0:	557d                	li	a0,-1
    80005df2:	bfd1                	j	80005dc6 <sys_chdir+0x7a>

0000000080005df4 <sys_exec>:

uint64
sys_exec(void)
{
    80005df4:	7145                	addi	sp,sp,-464
    80005df6:	e786                	sd	ra,456(sp)
    80005df8:	e3a2                	sd	s0,448(sp)
    80005dfa:	ff26                	sd	s1,440(sp)
    80005dfc:	fb4a                	sd	s2,432(sp)
    80005dfe:	f74e                	sd	s3,424(sp)
    80005e00:	f352                	sd	s4,416(sp)
    80005e02:	ef56                	sd	s5,408(sp)
    80005e04:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e06:	e3840593          	addi	a1,s0,-456
    80005e0a:	4505                	li	a0,1
    80005e0c:	ffffd097          	auipc	ra,0xffffd
    80005e10:	088080e7          	jalr	136(ra) # 80002e94 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e14:	08000613          	li	a2,128
    80005e18:	f4040593          	addi	a1,s0,-192
    80005e1c:	4501                	li	a0,0
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	096080e7          	jalr	150(ra) # 80002eb4 <argstr>
    80005e26:	87aa                	mv	a5,a0
    return -1;
    80005e28:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e2a:	0c07c363          	bltz	a5,80005ef0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e2e:	10000613          	li	a2,256
    80005e32:	4581                	li	a1,0
    80005e34:	e4040513          	addi	a0,s0,-448
    80005e38:	ffffb097          	auipc	ra,0xffffb
    80005e3c:	fd0080e7          	jalr	-48(ra) # 80000e08 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e40:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e44:	89a6                	mv	s3,s1
    80005e46:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e48:	02000a13          	li	s4,32
    80005e4c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e50:	00391513          	slli	a0,s2,0x3
    80005e54:	e3040593          	addi	a1,s0,-464
    80005e58:	e3843783          	ld	a5,-456(s0)
    80005e5c:	953e                	add	a0,a0,a5
    80005e5e:	ffffd097          	auipc	ra,0xffffd
    80005e62:	f78080e7          	jalr	-136(ra) # 80002dd6 <fetchaddr>
    80005e66:	02054a63          	bltz	a0,80005e9a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e6a:	e3043783          	ld	a5,-464(s0)
    80005e6e:	c3b9                	beqz	a5,80005eb4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e70:	ffffb097          	auipc	ra,0xffffb
    80005e74:	d74080e7          	jalr	-652(ra) # 80000be4 <kalloc>
    80005e78:	85aa                	mv	a1,a0
    80005e7a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e7e:	cd11                	beqz	a0,80005e9a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e80:	6605                	lui	a2,0x1
    80005e82:	e3043503          	ld	a0,-464(s0)
    80005e86:	ffffd097          	auipc	ra,0xffffd
    80005e8a:	fa2080e7          	jalr	-94(ra) # 80002e28 <fetchstr>
    80005e8e:	00054663          	bltz	a0,80005e9a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e92:	0905                	addi	s2,s2,1
    80005e94:	09a1                	addi	s3,s3,8
    80005e96:	fb491be3          	bne	s2,s4,80005e4c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e9a:	f4040913          	addi	s2,s0,-192
    80005e9e:	6088                	ld	a0,0(s1)
    80005ea0:	c539                	beqz	a0,80005eee <sys_exec+0xfa>
    kfree(argv[i]);
    80005ea2:	ffffb097          	auipc	ra,0xffffb
    80005ea6:	bbe080e7          	jalr	-1090(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eaa:	04a1                	addi	s1,s1,8
    80005eac:	ff2499e3          	bne	s1,s2,80005e9e <sys_exec+0xaa>
  return -1;
    80005eb0:	557d                	li	a0,-1
    80005eb2:	a83d                	j	80005ef0 <sys_exec+0xfc>
      argv[i] = 0;
    80005eb4:	0a8e                	slli	s5,s5,0x3
    80005eb6:	fc0a8793          	addi	a5,s5,-64
    80005eba:	00878ab3          	add	s5,a5,s0
    80005ebe:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ec2:	e4040593          	addi	a1,s0,-448
    80005ec6:	f4040513          	addi	a0,s0,-192
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	168080e7          	jalr	360(ra) # 80005032 <exec>
    80005ed2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed4:	f4040993          	addi	s3,s0,-192
    80005ed8:	6088                	ld	a0,0(s1)
    80005eda:	c901                	beqz	a0,80005eea <sys_exec+0xf6>
    kfree(argv[i]);
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	b84080e7          	jalr	-1148(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee4:	04a1                	addi	s1,s1,8
    80005ee6:	ff3499e3          	bne	s1,s3,80005ed8 <sys_exec+0xe4>
  return ret;
    80005eea:	854a                	mv	a0,s2
    80005eec:	a011                	j	80005ef0 <sys_exec+0xfc>
  return -1;
    80005eee:	557d                	li	a0,-1
}
    80005ef0:	60be                	ld	ra,456(sp)
    80005ef2:	641e                	ld	s0,448(sp)
    80005ef4:	74fa                	ld	s1,440(sp)
    80005ef6:	795a                	ld	s2,432(sp)
    80005ef8:	79ba                	ld	s3,424(sp)
    80005efa:	7a1a                	ld	s4,416(sp)
    80005efc:	6afa                	ld	s5,408(sp)
    80005efe:	6179                	addi	sp,sp,464
    80005f00:	8082                	ret

0000000080005f02 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f02:	7139                	addi	sp,sp,-64
    80005f04:	fc06                	sd	ra,56(sp)
    80005f06:	f822                	sd	s0,48(sp)
    80005f08:	f426                	sd	s1,40(sp)
    80005f0a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f0c:	ffffc097          	auipc	ra,0xffffc
    80005f10:	bf0080e7          	jalr	-1040(ra) # 80001afc <myproc>
    80005f14:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f16:	fd840593          	addi	a1,s0,-40
    80005f1a:	4501                	li	a0,0
    80005f1c:	ffffd097          	auipc	ra,0xffffd
    80005f20:	f78080e7          	jalr	-136(ra) # 80002e94 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f24:	fc840593          	addi	a1,s0,-56
    80005f28:	fd040513          	addi	a0,s0,-48
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	dbc080e7          	jalr	-580(ra) # 80004ce8 <pipealloc>
    return -1;
    80005f34:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f36:	0c054463          	bltz	a0,80005ffe <sys_pipe+0xfc>
  fd0 = -1;
    80005f3a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f3e:	fd043503          	ld	a0,-48(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	514080e7          	jalr	1300(ra) # 80005456 <fdalloc>
    80005f4a:	fca42223          	sw	a0,-60(s0)
    80005f4e:	08054b63          	bltz	a0,80005fe4 <sys_pipe+0xe2>
    80005f52:	fc843503          	ld	a0,-56(s0)
    80005f56:	fffff097          	auipc	ra,0xfffff
    80005f5a:	500080e7          	jalr	1280(ra) # 80005456 <fdalloc>
    80005f5e:	fca42023          	sw	a0,-64(s0)
    80005f62:	06054863          	bltz	a0,80005fd2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f66:	4691                	li	a3,4
    80005f68:	fc440613          	addi	a2,s0,-60
    80005f6c:	fd843583          	ld	a1,-40(s0)
    80005f70:	6ca8                	ld	a0,88(s1)
    80005f72:	ffffc097          	auipc	ra,0xffffc
    80005f76:	816080e7          	jalr	-2026(ra) # 80001788 <copyout>
    80005f7a:	02054063          	bltz	a0,80005f9a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f7e:	4691                	li	a3,4
    80005f80:	fc040613          	addi	a2,s0,-64
    80005f84:	fd843583          	ld	a1,-40(s0)
    80005f88:	0591                	addi	a1,a1,4
    80005f8a:	6ca8                	ld	a0,88(s1)
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	7fc080e7          	jalr	2044(ra) # 80001788 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f94:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f96:	06055463          	bgez	a0,80005ffe <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f9a:	fc442783          	lw	a5,-60(s0)
    80005f9e:	07e9                	addi	a5,a5,26
    80005fa0:	078e                	slli	a5,a5,0x3
    80005fa2:	97a6                	add	a5,a5,s1
    80005fa4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005fa8:	fc042783          	lw	a5,-64(s0)
    80005fac:	07e9                	addi	a5,a5,26
    80005fae:	078e                	slli	a5,a5,0x3
    80005fb0:	94be                	add	s1,s1,a5
    80005fb2:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005fb6:	fd043503          	ld	a0,-48(s0)
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	9fe080e7          	jalr	-1538(ra) # 800049b8 <fileclose>
    fileclose(wf);
    80005fc2:	fc843503          	ld	a0,-56(s0)
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	9f2080e7          	jalr	-1550(ra) # 800049b8 <fileclose>
    return -1;
    80005fce:	57fd                	li	a5,-1
    80005fd0:	a03d                	j	80005ffe <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fd2:	fc442783          	lw	a5,-60(s0)
    80005fd6:	0007c763          	bltz	a5,80005fe4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fda:	07e9                	addi	a5,a5,26
    80005fdc:	078e                	slli	a5,a5,0x3
    80005fde:	97a6                	add	a5,a5,s1
    80005fe0:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005fe4:	fd043503          	ld	a0,-48(s0)
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	9d0080e7          	jalr	-1584(ra) # 800049b8 <fileclose>
    fileclose(wf);
    80005ff0:	fc843503          	ld	a0,-56(s0)
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	9c4080e7          	jalr	-1596(ra) # 800049b8 <fileclose>
    return -1;
    80005ffc:	57fd                	li	a5,-1
}
    80005ffe:	853e                	mv	a0,a5
    80006000:	70e2                	ld	ra,56(sp)
    80006002:	7442                	ld	s0,48(sp)
    80006004:	74a2                	ld	s1,40(sp)
    80006006:	6121                	addi	sp,sp,64
    80006008:	8082                	ret
    8000600a:	0000                	unimp
    8000600c:	0000                	unimp
	...

0000000080006010 <kernelvec>:
    80006010:	7111                	addi	sp,sp,-256
    80006012:	e006                	sd	ra,0(sp)
    80006014:	e40a                	sd	sp,8(sp)
    80006016:	e80e                	sd	gp,16(sp)
    80006018:	ec12                	sd	tp,24(sp)
    8000601a:	f016                	sd	t0,32(sp)
    8000601c:	f41a                	sd	t1,40(sp)
    8000601e:	f81e                	sd	t2,48(sp)
    80006020:	fc22                	sd	s0,56(sp)
    80006022:	e0a6                	sd	s1,64(sp)
    80006024:	e4aa                	sd	a0,72(sp)
    80006026:	e8ae                	sd	a1,80(sp)
    80006028:	ecb2                	sd	a2,88(sp)
    8000602a:	f0b6                	sd	a3,96(sp)
    8000602c:	f4ba                	sd	a4,104(sp)
    8000602e:	f8be                	sd	a5,112(sp)
    80006030:	fcc2                	sd	a6,120(sp)
    80006032:	e146                	sd	a7,128(sp)
    80006034:	e54a                	sd	s2,136(sp)
    80006036:	e94e                	sd	s3,144(sp)
    80006038:	ed52                	sd	s4,152(sp)
    8000603a:	f156                	sd	s5,160(sp)
    8000603c:	f55a                	sd	s6,168(sp)
    8000603e:	f95e                	sd	s7,176(sp)
    80006040:	fd62                	sd	s8,184(sp)
    80006042:	e1e6                	sd	s9,192(sp)
    80006044:	e5ea                	sd	s10,200(sp)
    80006046:	e9ee                	sd	s11,208(sp)
    80006048:	edf2                	sd	t3,216(sp)
    8000604a:	f1f6                	sd	t4,224(sp)
    8000604c:	f5fa                	sd	t5,232(sp)
    8000604e:	f9fe                	sd	t6,240(sp)
    80006050:	c53fc0ef          	jal	ra,80002ca2 <kerneltrap>
    80006054:	6082                	ld	ra,0(sp)
    80006056:	6122                	ld	sp,8(sp)
    80006058:	61c2                	ld	gp,16(sp)
    8000605a:	7282                	ld	t0,32(sp)
    8000605c:	7322                	ld	t1,40(sp)
    8000605e:	73c2                	ld	t2,48(sp)
    80006060:	7462                	ld	s0,56(sp)
    80006062:	6486                	ld	s1,64(sp)
    80006064:	6526                	ld	a0,72(sp)
    80006066:	65c6                	ld	a1,80(sp)
    80006068:	6666                	ld	a2,88(sp)
    8000606a:	7686                	ld	a3,96(sp)
    8000606c:	7726                	ld	a4,104(sp)
    8000606e:	77c6                	ld	a5,112(sp)
    80006070:	7866                	ld	a6,120(sp)
    80006072:	688a                	ld	a7,128(sp)
    80006074:	692a                	ld	s2,136(sp)
    80006076:	69ca                	ld	s3,144(sp)
    80006078:	6a6a                	ld	s4,152(sp)
    8000607a:	7a8a                	ld	s5,160(sp)
    8000607c:	7b2a                	ld	s6,168(sp)
    8000607e:	7bca                	ld	s7,176(sp)
    80006080:	7c6a                	ld	s8,184(sp)
    80006082:	6c8e                	ld	s9,192(sp)
    80006084:	6d2e                	ld	s10,200(sp)
    80006086:	6dce                	ld	s11,208(sp)
    80006088:	6e6e                	ld	t3,216(sp)
    8000608a:	7e8e                	ld	t4,224(sp)
    8000608c:	7f2e                	ld	t5,232(sp)
    8000608e:	7fce                	ld	t6,240(sp)
    80006090:	6111                	addi	sp,sp,256
    80006092:	10200073          	sret
    80006096:	00000013          	nop
    8000609a:	00000013          	nop
    8000609e:	0001                	nop

00000000800060a0 <timervec>:
    800060a0:	34051573          	csrrw	a0,mscratch,a0
    800060a4:	e10c                	sd	a1,0(a0)
    800060a6:	e510                	sd	a2,8(a0)
    800060a8:	e914                	sd	a3,16(a0)
    800060aa:	6d0c                	ld	a1,24(a0)
    800060ac:	7110                	ld	a2,32(a0)
    800060ae:	6194                	ld	a3,0(a1)
    800060b0:	96b2                	add	a3,a3,a2
    800060b2:	e194                	sd	a3,0(a1)
    800060b4:	4589                	li	a1,2
    800060b6:	14459073          	csrw	sip,a1
    800060ba:	6914                	ld	a3,16(a0)
    800060bc:	6510                	ld	a2,8(a0)
    800060be:	610c                	ld	a1,0(a0)
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	30200073          	mret
	...

00000000800060ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ca:	1141                	addi	sp,sp,-16
    800060cc:	e422                	sd	s0,8(sp)
    800060ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060d0:	0c0007b7          	lui	a5,0xc000
    800060d4:	4705                	li	a4,1
    800060d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060d8:	c3d8                	sw	a4,4(a5)
}
    800060da:	6422                	ld	s0,8(sp)
    800060dc:	0141                	addi	sp,sp,16
    800060de:	8082                	ret

00000000800060e0 <plicinithart>:

void
plicinithart(void)
{
    800060e0:	1141                	addi	sp,sp,-16
    800060e2:	e406                	sd	ra,8(sp)
    800060e4:	e022                	sd	s0,0(sp)
    800060e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	9e8080e7          	jalr	-1560(ra) # 80001ad0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060f0:	0085171b          	slliw	a4,a0,0x8
    800060f4:	0c0027b7          	lui	a5,0xc002
    800060f8:	97ba                	add	a5,a5,a4
    800060fa:	40200713          	li	a4,1026
    800060fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006102:	00d5151b          	slliw	a0,a0,0xd
    80006106:	0c2017b7          	lui	a5,0xc201
    8000610a:	97aa                	add	a5,a5,a0
    8000610c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006110:	60a2                	ld	ra,8(sp)
    80006112:	6402                	ld	s0,0(sp)
    80006114:	0141                	addi	sp,sp,16
    80006116:	8082                	ret

0000000080006118 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006118:	1141                	addi	sp,sp,-16
    8000611a:	e406                	sd	ra,8(sp)
    8000611c:	e022                	sd	s0,0(sp)
    8000611e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006120:	ffffc097          	auipc	ra,0xffffc
    80006124:	9b0080e7          	jalr	-1616(ra) # 80001ad0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006128:	00d5151b          	slliw	a0,a0,0xd
    8000612c:	0c2017b7          	lui	a5,0xc201
    80006130:	97aa                	add	a5,a5,a0
  return irq;
}
    80006132:	43c8                	lw	a0,4(a5)
    80006134:	60a2                	ld	ra,8(sp)
    80006136:	6402                	ld	s0,0(sp)
    80006138:	0141                	addi	sp,sp,16
    8000613a:	8082                	ret

000000008000613c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000613c:	1101                	addi	sp,sp,-32
    8000613e:	ec06                	sd	ra,24(sp)
    80006140:	e822                	sd	s0,16(sp)
    80006142:	e426                	sd	s1,8(sp)
    80006144:	1000                	addi	s0,sp,32
    80006146:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	988080e7          	jalr	-1656(ra) # 80001ad0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006150:	00d5151b          	slliw	a0,a0,0xd
    80006154:	0c2017b7          	lui	a5,0xc201
    80006158:	97aa                	add	a5,a5,a0
    8000615a:	c3c4                	sw	s1,4(a5)
}
    8000615c:	60e2                	ld	ra,24(sp)
    8000615e:	6442                	ld	s0,16(sp)
    80006160:	64a2                	ld	s1,8(sp)
    80006162:	6105                	addi	sp,sp,32
    80006164:	8082                	ret

0000000080006166 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006166:	1141                	addi	sp,sp,-16
    80006168:	e406                	sd	ra,8(sp)
    8000616a:	e022                	sd	s0,0(sp)
    8000616c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000616e:	479d                	li	a5,7
    80006170:	04a7cc63          	blt	a5,a0,800061c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006174:	00245797          	auipc	a5,0x245
    80006178:	fc478793          	addi	a5,a5,-60 # 8024b138 <disk>
    8000617c:	97aa                	add	a5,a5,a0
    8000617e:	0187c783          	lbu	a5,24(a5)
    80006182:	ebb9                	bnez	a5,800061d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006184:	00451693          	slli	a3,a0,0x4
    80006188:	00245797          	auipc	a5,0x245
    8000618c:	fb078793          	addi	a5,a5,-80 # 8024b138 <disk>
    80006190:	6398                	ld	a4,0(a5)
    80006192:	9736                	add	a4,a4,a3
    80006194:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006198:	6398                	ld	a4,0(a5)
    8000619a:	9736                	add	a4,a4,a3
    8000619c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061a8:	97aa                	add	a5,a5,a0
    800061aa:	4705                	li	a4,1
    800061ac:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800061b0:	00245517          	auipc	a0,0x245
    800061b4:	fa050513          	addi	a0,a0,-96 # 8024b150 <disk+0x18>
    800061b8:	ffffc097          	auipc	ra,0xffffc
    800061bc:	066080e7          	jalr	102(ra) # 8000221e <wakeup>
}
    800061c0:	60a2                	ld	ra,8(sp)
    800061c2:	6402                	ld	s0,0(sp)
    800061c4:	0141                	addi	sp,sp,16
    800061c6:	8082                	ret
    panic("free_desc 1");
    800061c8:	00003517          	auipc	a0,0x3
    800061cc:	81050513          	addi	a0,a0,-2032 # 800089d8 <names+0x310>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	370080e7          	jalr	880(ra) # 80000540 <panic>
    panic("free_desc 2");
    800061d8:	00003517          	auipc	a0,0x3
    800061dc:	81050513          	addi	a0,a0,-2032 # 800089e8 <names+0x320>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	360080e7          	jalr	864(ra) # 80000540 <panic>

00000000800061e8 <virtio_disk_init>:
{
    800061e8:	1101                	addi	sp,sp,-32
    800061ea:	ec06                	sd	ra,24(sp)
    800061ec:	e822                	sd	s0,16(sp)
    800061ee:	e426                	sd	s1,8(sp)
    800061f0:	e04a                	sd	s2,0(sp)
    800061f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061f4:	00003597          	auipc	a1,0x3
    800061f8:	80458593          	addi	a1,a1,-2044 # 800089f8 <names+0x330>
    800061fc:	00245517          	auipc	a0,0x245
    80006200:	06450513          	addi	a0,a0,100 # 8024b260 <disk+0x128>
    80006204:	ffffb097          	auipc	ra,0xffffb
    80006208:	a78080e7          	jalr	-1416(ra) # 80000c7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000620c:	100017b7          	lui	a5,0x10001
    80006210:	4398                	lw	a4,0(a5)
    80006212:	2701                	sext.w	a4,a4
    80006214:	747277b7          	lui	a5,0x74727
    80006218:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000621c:	14f71b63          	bne	a4,a5,80006372 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006220:	100017b7          	lui	a5,0x10001
    80006224:	43dc                	lw	a5,4(a5)
    80006226:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006228:	4709                	li	a4,2
    8000622a:	14e79463          	bne	a5,a4,80006372 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000622e:	100017b7          	lui	a5,0x10001
    80006232:	479c                	lw	a5,8(a5)
    80006234:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006236:	12e79e63          	bne	a5,a4,80006372 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000623a:	100017b7          	lui	a5,0x10001
    8000623e:	47d8                	lw	a4,12(a5)
    80006240:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006242:	554d47b7          	lui	a5,0x554d4
    80006246:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000624a:	12f71463          	bne	a4,a5,80006372 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000624e:	100017b7          	lui	a5,0x10001
    80006252:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006256:	4705                	li	a4,1
    80006258:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000625a:	470d                	li	a4,3
    8000625c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000625e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006260:	c7ffe6b7          	lui	a3,0xc7ffe
    80006264:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47db34e7>
    80006268:	8f75                	and	a4,a4,a3
    8000626a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000626c:	472d                	li	a4,11
    8000626e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006270:	5bbc                	lw	a5,112(a5)
    80006272:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006276:	8ba1                	andi	a5,a5,8
    80006278:	10078563          	beqz	a5,80006382 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000627c:	100017b7          	lui	a5,0x10001
    80006280:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006284:	43fc                	lw	a5,68(a5)
    80006286:	2781                	sext.w	a5,a5
    80006288:	10079563          	bnez	a5,80006392 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000628c:	100017b7          	lui	a5,0x10001
    80006290:	5bdc                	lw	a5,52(a5)
    80006292:	2781                	sext.w	a5,a5
  if(max == 0)
    80006294:	10078763          	beqz	a5,800063a2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006298:	471d                	li	a4,7
    8000629a:	10f77c63          	bgeu	a4,a5,800063b2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000629e:	ffffb097          	auipc	ra,0xffffb
    800062a2:	946080e7          	jalr	-1722(ra) # 80000be4 <kalloc>
    800062a6:	00245497          	auipc	s1,0x245
    800062aa:	e9248493          	addi	s1,s1,-366 # 8024b138 <disk>
    800062ae:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	934080e7          	jalr	-1740(ra) # 80000be4 <kalloc>
    800062b8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	92a080e7          	jalr	-1750(ra) # 80000be4 <kalloc>
    800062c2:	87aa                	mv	a5,a0
    800062c4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062c6:	6088                	ld	a0,0(s1)
    800062c8:	cd6d                	beqz	a0,800063c2 <virtio_disk_init+0x1da>
    800062ca:	00245717          	auipc	a4,0x245
    800062ce:	e7673703          	ld	a4,-394(a4) # 8024b140 <disk+0x8>
    800062d2:	cb65                	beqz	a4,800063c2 <virtio_disk_init+0x1da>
    800062d4:	c7fd                	beqz	a5,800063c2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062d6:	6605                	lui	a2,0x1
    800062d8:	4581                	li	a1,0
    800062da:	ffffb097          	auipc	ra,0xffffb
    800062de:	b2e080e7          	jalr	-1234(ra) # 80000e08 <memset>
  memset(disk.avail, 0, PGSIZE);
    800062e2:	00245497          	auipc	s1,0x245
    800062e6:	e5648493          	addi	s1,s1,-426 # 8024b138 <disk>
    800062ea:	6605                	lui	a2,0x1
    800062ec:	4581                	li	a1,0
    800062ee:	6488                	ld	a0,8(s1)
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	b18080e7          	jalr	-1256(ra) # 80000e08 <memset>
  memset(disk.used, 0, PGSIZE);
    800062f8:	6605                	lui	a2,0x1
    800062fa:	4581                	li	a1,0
    800062fc:	6888                	ld	a0,16(s1)
    800062fe:	ffffb097          	auipc	ra,0xffffb
    80006302:	b0a080e7          	jalr	-1270(ra) # 80000e08 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006306:	100017b7          	lui	a5,0x10001
    8000630a:	4721                	li	a4,8
    8000630c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000630e:	4098                	lw	a4,0(s1)
    80006310:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006314:	40d8                	lw	a4,4(s1)
    80006316:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000631a:	6498                	ld	a4,8(s1)
    8000631c:	0007069b          	sext.w	a3,a4
    80006320:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006324:	9701                	srai	a4,a4,0x20
    80006326:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000632a:	6898                	ld	a4,16(s1)
    8000632c:	0007069b          	sext.w	a3,a4
    80006330:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006334:	9701                	srai	a4,a4,0x20
    80006336:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000633a:	4705                	li	a4,1
    8000633c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000633e:	00e48c23          	sb	a4,24(s1)
    80006342:	00e48ca3          	sb	a4,25(s1)
    80006346:	00e48d23          	sb	a4,26(s1)
    8000634a:	00e48da3          	sb	a4,27(s1)
    8000634e:	00e48e23          	sb	a4,28(s1)
    80006352:	00e48ea3          	sb	a4,29(s1)
    80006356:	00e48f23          	sb	a4,30(s1)
    8000635a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000635e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006362:	0727a823          	sw	s2,112(a5)
}
    80006366:	60e2                	ld	ra,24(sp)
    80006368:	6442                	ld	s0,16(sp)
    8000636a:	64a2                	ld	s1,8(sp)
    8000636c:	6902                	ld	s2,0(sp)
    8000636e:	6105                	addi	sp,sp,32
    80006370:	8082                	ret
    panic("could not find virtio disk");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	69650513          	addi	a0,a0,1686 # 80008a08 <names+0x340>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	6a650513          	addi	a0,a0,1702 # 80008a28 <names+0x360>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	6b650513          	addi	a0,a0,1718 # 80008a48 <names+0x380>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	6c650513          	addi	a0,a0,1734 # 80008a68 <names+0x3a0>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	196080e7          	jalr	406(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	6d650513          	addi	a0,a0,1750 # 80008a88 <names+0x3c0>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	186080e7          	jalr	390(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	6e650513          	addi	a0,a0,1766 # 80008aa8 <names+0x3e0>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	176080e7          	jalr	374(ra) # 80000540 <panic>

00000000800063d2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063d2:	7119                	addi	sp,sp,-128
    800063d4:	fc86                	sd	ra,120(sp)
    800063d6:	f8a2                	sd	s0,112(sp)
    800063d8:	f4a6                	sd	s1,104(sp)
    800063da:	f0ca                	sd	s2,96(sp)
    800063dc:	ecce                	sd	s3,88(sp)
    800063de:	e8d2                	sd	s4,80(sp)
    800063e0:	e4d6                	sd	s5,72(sp)
    800063e2:	e0da                	sd	s6,64(sp)
    800063e4:	fc5e                	sd	s7,56(sp)
    800063e6:	f862                	sd	s8,48(sp)
    800063e8:	f466                	sd	s9,40(sp)
    800063ea:	f06a                	sd	s10,32(sp)
    800063ec:	ec6e                	sd	s11,24(sp)
    800063ee:	0100                	addi	s0,sp,128
    800063f0:	8aaa                	mv	s5,a0
    800063f2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063f4:	00c52d03          	lw	s10,12(a0)
    800063f8:	001d1d1b          	slliw	s10,s10,0x1
    800063fc:	1d02                	slli	s10,s10,0x20
    800063fe:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006402:	00245517          	auipc	a0,0x245
    80006406:	e5e50513          	addi	a0,a0,-418 # 8024b260 <disk+0x128>
    8000640a:	ffffb097          	auipc	ra,0xffffb
    8000640e:	902080e7          	jalr	-1790(ra) # 80000d0c <acquire>
  for(int i = 0; i < 3; i++){
    80006412:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006414:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006416:	00245b97          	auipc	s7,0x245
    8000641a:	d22b8b93          	addi	s7,s7,-734 # 8024b138 <disk>
  for(int i = 0; i < 3; i++){
    8000641e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006420:	00245c97          	auipc	s9,0x245
    80006424:	e40c8c93          	addi	s9,s9,-448 # 8024b260 <disk+0x128>
    80006428:	a08d                	j	8000648a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000642a:	00fb8733          	add	a4,s7,a5
    8000642e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006432:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006434:	0207c563          	bltz	a5,8000645e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006438:	2905                	addiw	s2,s2,1
    8000643a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000643c:	05690c63          	beq	s2,s6,80006494 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006440:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006442:	00245717          	auipc	a4,0x245
    80006446:	cf670713          	addi	a4,a4,-778 # 8024b138 <disk>
    8000644a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000644c:	01874683          	lbu	a3,24(a4)
    80006450:	fee9                	bnez	a3,8000642a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006452:	2785                	addiw	a5,a5,1
    80006454:	0705                	addi	a4,a4,1
    80006456:	fe979be3          	bne	a5,s1,8000644c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000645a:	57fd                	li	a5,-1
    8000645c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000645e:	01205d63          	blez	s2,80006478 <virtio_disk_rw+0xa6>
    80006462:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006464:	000a2503          	lw	a0,0(s4)
    80006468:	00000097          	auipc	ra,0x0
    8000646c:	cfe080e7          	jalr	-770(ra) # 80006166 <free_desc>
      for(int j = 0; j < i; j++)
    80006470:	2d85                	addiw	s11,s11,1
    80006472:	0a11                	addi	s4,s4,4
    80006474:	ff2d98e3          	bne	s11,s2,80006464 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006478:	85e6                	mv	a1,s9
    8000647a:	00245517          	auipc	a0,0x245
    8000647e:	cd650513          	addi	a0,a0,-810 # 8024b150 <disk+0x18>
    80006482:	ffffc097          	auipc	ra,0xffffc
    80006486:	d38080e7          	jalr	-712(ra) # 800021ba <sleep>
  for(int i = 0; i < 3; i++){
    8000648a:	f8040a13          	addi	s4,s0,-128
{
    8000648e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006490:	894e                	mv	s2,s3
    80006492:	b77d                	j	80006440 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006494:	f8042503          	lw	a0,-128(s0)
    80006498:	00a50713          	addi	a4,a0,10
    8000649c:	0712                	slli	a4,a4,0x4

  if(write)
    8000649e:	00245797          	auipc	a5,0x245
    800064a2:	c9a78793          	addi	a5,a5,-870 # 8024b138 <disk>
    800064a6:	00e786b3          	add	a3,a5,a4
    800064aa:	01803633          	snez	a2,s8
    800064ae:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064b0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800064b4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064b8:	f6070613          	addi	a2,a4,-160
    800064bc:	6394                	ld	a3,0(a5)
    800064be:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064c0:	00870593          	addi	a1,a4,8
    800064c4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064c6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064c8:	0007b803          	ld	a6,0(a5)
    800064cc:	9642                	add	a2,a2,a6
    800064ce:	46c1                	li	a3,16
    800064d0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064d2:	4585                	li	a1,1
    800064d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064d8:	f8442683          	lw	a3,-124(s0)
    800064dc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064e0:	0692                	slli	a3,a3,0x4
    800064e2:	9836                	add	a6,a6,a3
    800064e4:	058a8613          	addi	a2,s5,88
    800064e8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064ec:	0007b803          	ld	a6,0(a5)
    800064f0:	96c2                	add	a3,a3,a6
    800064f2:	40000613          	li	a2,1024
    800064f6:	c690                	sw	a2,8(a3)
  if(write)
    800064f8:	001c3613          	seqz	a2,s8
    800064fc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006500:	00166613          	ori	a2,a2,1
    80006504:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006508:	f8842603          	lw	a2,-120(s0)
    8000650c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006510:	00250693          	addi	a3,a0,2
    80006514:	0692                	slli	a3,a3,0x4
    80006516:	96be                	add	a3,a3,a5
    80006518:	58fd                	li	a7,-1
    8000651a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000651e:	0612                	slli	a2,a2,0x4
    80006520:	9832                	add	a6,a6,a2
    80006522:	f9070713          	addi	a4,a4,-112
    80006526:	973e                	add	a4,a4,a5
    80006528:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000652c:	6398                	ld	a4,0(a5)
    8000652e:	9732                	add	a4,a4,a2
    80006530:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006532:	4609                	li	a2,2
    80006534:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006538:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000653c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006540:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006544:	6794                	ld	a3,8(a5)
    80006546:	0026d703          	lhu	a4,2(a3)
    8000654a:	8b1d                	andi	a4,a4,7
    8000654c:	0706                	slli	a4,a4,0x1
    8000654e:	96ba                	add	a3,a3,a4
    80006550:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006554:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006558:	6798                	ld	a4,8(a5)
    8000655a:	00275783          	lhu	a5,2(a4)
    8000655e:	2785                	addiw	a5,a5,1
    80006560:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006564:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006568:	100017b7          	lui	a5,0x10001
    8000656c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006570:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006574:	00245917          	auipc	s2,0x245
    80006578:	cec90913          	addi	s2,s2,-788 # 8024b260 <disk+0x128>
  while(b->disk == 1) {
    8000657c:	4485                	li	s1,1
    8000657e:	00b79c63          	bne	a5,a1,80006596 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006582:	85ca                	mv	a1,s2
    80006584:	8556                	mv	a0,s5
    80006586:	ffffc097          	auipc	ra,0xffffc
    8000658a:	c34080e7          	jalr	-972(ra) # 800021ba <sleep>
  while(b->disk == 1) {
    8000658e:	004aa783          	lw	a5,4(s5)
    80006592:	fe9788e3          	beq	a5,s1,80006582 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006596:	f8042903          	lw	s2,-128(s0)
    8000659a:	00290713          	addi	a4,s2,2
    8000659e:	0712                	slli	a4,a4,0x4
    800065a0:	00245797          	auipc	a5,0x245
    800065a4:	b9878793          	addi	a5,a5,-1128 # 8024b138 <disk>
    800065a8:	97ba                	add	a5,a5,a4
    800065aa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065ae:	00245997          	auipc	s3,0x245
    800065b2:	b8a98993          	addi	s3,s3,-1142 # 8024b138 <disk>
    800065b6:	00491713          	slli	a4,s2,0x4
    800065ba:	0009b783          	ld	a5,0(s3)
    800065be:	97ba                	add	a5,a5,a4
    800065c0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065c4:	854a                	mv	a0,s2
    800065c6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065ca:	00000097          	auipc	ra,0x0
    800065ce:	b9c080e7          	jalr	-1124(ra) # 80006166 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065d2:	8885                	andi	s1,s1,1
    800065d4:	f0ed                	bnez	s1,800065b6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065d6:	00245517          	auipc	a0,0x245
    800065da:	c8a50513          	addi	a0,a0,-886 # 8024b260 <disk+0x128>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	7e2080e7          	jalr	2018(ra) # 80000dc0 <release>
}
    800065e6:	70e6                	ld	ra,120(sp)
    800065e8:	7446                	ld	s0,112(sp)
    800065ea:	74a6                	ld	s1,104(sp)
    800065ec:	7906                	ld	s2,96(sp)
    800065ee:	69e6                	ld	s3,88(sp)
    800065f0:	6a46                	ld	s4,80(sp)
    800065f2:	6aa6                	ld	s5,72(sp)
    800065f4:	6b06                	ld	s6,64(sp)
    800065f6:	7be2                	ld	s7,56(sp)
    800065f8:	7c42                	ld	s8,48(sp)
    800065fa:	7ca2                	ld	s9,40(sp)
    800065fc:	7d02                	ld	s10,32(sp)
    800065fe:	6de2                	ld	s11,24(sp)
    80006600:	6109                	addi	sp,sp,128
    80006602:	8082                	ret

0000000080006604 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006604:	1101                	addi	sp,sp,-32
    80006606:	ec06                	sd	ra,24(sp)
    80006608:	e822                	sd	s0,16(sp)
    8000660a:	e426                	sd	s1,8(sp)
    8000660c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000660e:	00245497          	auipc	s1,0x245
    80006612:	b2a48493          	addi	s1,s1,-1238 # 8024b138 <disk>
    80006616:	00245517          	auipc	a0,0x245
    8000661a:	c4a50513          	addi	a0,a0,-950 # 8024b260 <disk+0x128>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	6ee080e7          	jalr	1774(ra) # 80000d0c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006626:	10001737          	lui	a4,0x10001
    8000662a:	533c                	lw	a5,96(a4)
    8000662c:	8b8d                	andi	a5,a5,3
    8000662e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006630:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006634:	689c                	ld	a5,16(s1)
    80006636:	0204d703          	lhu	a4,32(s1)
    8000663a:	0027d783          	lhu	a5,2(a5)
    8000663e:	04f70863          	beq	a4,a5,8000668e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006642:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006646:	6898                	ld	a4,16(s1)
    80006648:	0204d783          	lhu	a5,32(s1)
    8000664c:	8b9d                	andi	a5,a5,7
    8000664e:	078e                	slli	a5,a5,0x3
    80006650:	97ba                	add	a5,a5,a4
    80006652:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006654:	00278713          	addi	a4,a5,2
    80006658:	0712                	slli	a4,a4,0x4
    8000665a:	9726                	add	a4,a4,s1
    8000665c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006660:	e721                	bnez	a4,800066a8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006662:	0789                	addi	a5,a5,2
    80006664:	0792                	slli	a5,a5,0x4
    80006666:	97a6                	add	a5,a5,s1
    80006668:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000666a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000666e:	ffffc097          	auipc	ra,0xffffc
    80006672:	bb0080e7          	jalr	-1104(ra) # 8000221e <wakeup>

    disk.used_idx += 1;
    80006676:	0204d783          	lhu	a5,32(s1)
    8000667a:	2785                	addiw	a5,a5,1
    8000667c:	17c2                	slli	a5,a5,0x30
    8000667e:	93c1                	srli	a5,a5,0x30
    80006680:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006684:	6898                	ld	a4,16(s1)
    80006686:	00275703          	lhu	a4,2(a4)
    8000668a:	faf71ce3          	bne	a4,a5,80006642 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000668e:	00245517          	auipc	a0,0x245
    80006692:	bd250513          	addi	a0,a0,-1070 # 8024b260 <disk+0x128>
    80006696:	ffffa097          	auipc	ra,0xffffa
    8000669a:	72a080e7          	jalr	1834(ra) # 80000dc0 <release>
}
    8000669e:	60e2                	ld	ra,24(sp)
    800066a0:	6442                	ld	s0,16(sp)
    800066a2:	64a2                	ld	s1,8(sp)
    800066a4:	6105                	addi	sp,sp,32
    800066a6:	8082                	ret
      panic("virtio_disk_intr status");
    800066a8:	00002517          	auipc	a0,0x2
    800066ac:	41850513          	addi	a0,a0,1048 # 80008ac0 <names+0x3f8>
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	e90080e7          	jalr	-368(ra) # 80000540 <panic>
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

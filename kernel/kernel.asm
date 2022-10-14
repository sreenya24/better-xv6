
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae813103          	ld	sp,-1304(sp) # 80008ae8 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	af070713          	addi	a4,a4,-1296 # 80008b40 <timer_scratch>
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
    80000066:	e1e78793          	addi	a5,a5,-482 # 80005e80 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb04f>
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
    8000018e:	af650513          	addi	a0,a0,-1290 # 80010c80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b7a080e7          	jalr	-1158(ra) # 80000d0c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	ae648493          	addi	s1,s1,-1306 # 80010c80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b7690913          	addi	s2,s2,-1162 # 80010d18 <cons+0x98>
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
    8000022a:	a5a50513          	addi	a0,a0,-1446 # 80010c80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b92080e7          	jalr	-1134(ra) # 80000dc0 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a4450513          	addi	a0,a0,-1468 # 80010c80 <cons>
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
    80000276:	aaf72323          	sw	a5,-1370(a4) # 80010d18 <cons+0x98>
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
    800002d0:	9b450513          	addi	a0,a0,-1612 # 80010c80 <cons>
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
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	98650513          	addi	a0,a0,-1658 # 80010c80 <cons>
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
    80000322:	96270713          	addi	a4,a4,-1694 # 80010c80 <cons>
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
    8000034c:	93878793          	addi	a5,a5,-1736 # 80010c80 <cons>
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
    8000037a:	9a27a783          	lw	a5,-1630(a5) # 80010d18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	8f670713          	addi	a4,a4,-1802 # 80010c80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	8e648493          	addi	s1,s1,-1818 # 80010c80 <cons>
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
    800003da:	8aa70713          	addi	a4,a4,-1878 # 80010c80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	92f72a23          	sw	a5,-1740(a4) # 80010d20 <cons+0xa0>
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
    80000416:	86e78793          	addi	a5,a5,-1938 # 80010c80 <cons>
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
    8000043a:	8ec7a323          	sw	a2,-1818(a5) # 80010d1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	8da50513          	addi	a0,a0,-1830 # 80010d18 <cons+0x98>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	82050513          	addi	a0,a0,-2016 # 80010c80 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	814080e7          	jalr	-2028(ra) # 80000c7c <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	1a078793          	addi	a5,a5,416 # 80242618 <devsw>
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
    80000550:	7e07aa23          	sw	zero,2036(a5) # 80010d40 <pr+0x18>
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
    80000584:	58f72023          	sw	a5,1408(a4) # 80008b00 <panicked>
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
    800005c0:	784dad83          	lw	s11,1924(s11) # 80010d40 <pr+0x18>
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
    800005fe:	72e50513          	addi	a0,a0,1838 # 80010d28 <pr>
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
    8000075c:	5d050513          	addi	a0,a0,1488 # 80010d28 <pr>
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
    80000778:	5b448493          	addi	s1,s1,1460 # 80010d28 <pr>
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
    800007d8:	57450513          	addi	a0,a0,1396 # 80010d48 <uart_tx_lock>
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
    80000804:	3007a783          	lw	a5,768(a5) # 80008b00 <panicked>
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
    8000083c:	2d07b783          	ld	a5,720(a5) # 80008b08 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	2d073703          	ld	a4,720(a4) # 80008b10 <uart_tx_w>
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
    80000866:	4e6a0a13          	addi	s4,s4,1254 # 80010d48 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	29e48493          	addi	s1,s1,670 # 80008b08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	29e98993          	addi	s3,s3,670 # 80008b10 <uart_tx_w>
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
    800008d4:	47850513          	addi	a0,a0,1144 # 80010d48 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	434080e7          	jalr	1076(ra) # 80000d0c <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2207a783          	lw	a5,544(a5) # 80008b00 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	22673703          	ld	a4,550(a4) # 80008b10 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2167b783          	ld	a5,534(a5) # 80008b08 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	44a98993          	addi	s3,s3,1098 # 80010d48 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	20248493          	addi	s1,s1,514 # 80008b08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	20290913          	addi	s2,s2,514 # 80008b10 <uart_tx_w>
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
    80000938:	41448493          	addi	s1,s1,1044 # 80010d48 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	1ce7b423          	sd	a4,456(a5) # 80008b10 <uart_tx_w>
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
    800009be:	38e48493          	addi	s1,s1,910 # 80010d48 <uart_tx_lock>
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
    800009f8:	38c50513          	addi	a0,a0,908 # 80010d80 <kmem>
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
    80000a1a:	38a70713          	addi	a4,a4,906 # 80010da0 <refcnt>
    80000a1e:	9736                	add	a4,a4,a3
    80000a20:	4318                	lw	a4,0(a4)
    80000a22:	02e05763          	blez	a4,80000a50 <increse+0x68>
  {
    panic("increase ref cnt");
  }
  refcnt[pn]++;
    80000a26:	078a                	slli	a5,a5,0x2
    80000a28:	00010697          	auipc	a3,0x10
    80000a2c:	37868693          	addi	a3,a3,888 # 80010da0 <refcnt>
    80000a30:	97b6                	add	a5,a5,a3
    80000a32:	2705                	addiw	a4,a4,1
    80000a34:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a36:	00010517          	auipc	a0,0x10
    80000a3a:	34a50513          	addi	a0,a0,842 # 80010d80 <kmem>
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
    80000a78:	d3c78793          	addi	a5,a5,-708 # 802437b0 <end>
    80000a7c:	06f56563          	bltu	a0,a5,80000ae6 <kfree+0x86>
    80000a80:	47c5                	li	a5,17
    80000a82:	07ee                	slli	a5,a5,0x1b
    80000a84:	06f57163          	bgeu	a0,a5,80000ae6 <kfree+0x86>
  // Fill with junk to catch dangling refs.
  // memset(pa, 1, PGSIZE);

  r = (struct run *)pa;

  acquire(&kmem.lock);
    80000a88:	00010517          	auipc	a0,0x10
    80000a8c:	2f850513          	addi	a0,a0,760 # 80010d80 <kmem>
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	27c080e7          	jalr	636(ra) # 80000d0c <acquire>
  int pn = (uint64)r / PGSIZE;
    80000a98:	00c4d793          	srli	a5,s1,0xc
    80000a9c:	2781                	sext.w	a5,a5
  if (refcnt[pn] < 1)
    80000a9e:	00279693          	slli	a3,a5,0x2
    80000aa2:	00010717          	auipc	a4,0x10
    80000aa6:	2fe70713          	addi	a4,a4,766 # 80010da0 <refcnt>
    80000aaa:	9736                	add	a4,a4,a3
    80000aac:	4318                	lw	a4,0(a4)
    80000aae:	04e05463          	blez	a4,80000af6 <kfree+0x96>
    panic("kfree panic");
  refcnt[pn] -= 1;
    80000ab2:	377d                	addiw	a4,a4,-1
    80000ab4:	0007091b          	sext.w	s2,a4
    80000ab8:	078a                	slli	a5,a5,0x2
    80000aba:	00010697          	auipc	a3,0x10
    80000abe:	2e668693          	addi	a3,a3,742 # 80010da0 <refcnt>
    80000ac2:	97b6                	add	a5,a5,a3
    80000ac4:	c398                	sw	a4,0(a5)
  int tmp = refcnt[pn];
  release(&kmem.lock);
    80000ac6:	00010517          	auipc	a0,0x10
    80000aca:	2ba50513          	addi	a0,a0,698 # 80010d80 <kmem>
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
    80000b18:	26c90913          	addi	s2,s2,620 # 80010d80 <kmem>
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
    80000b6a:	23ab0b13          	addi	s6,s6,570 # 80010da0 <refcnt>
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
    80000bbc:	1c850513          	addi	a0,a0,456 # 80010d80 <kmem>
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	0bc080e7          	jalr	188(ra) # 80000c7c <initlock>
  freerange(end, (void *)PHYSTOP);
    80000bc8:	45c5                	li	a1,17
    80000bca:	05ee                	slli	a1,a1,0x1b
    80000bcc:	00243517          	auipc	a0,0x243
    80000bd0:	be450513          	addi	a0,a0,-1052 # 802437b0 <end>
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
    80000bf2:	19248493          	addi	s1,s1,402 # 80010d80 <kmem>
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
    80000c12:	19270713          	addi	a4,a4,402 # 80010da0 <refcnt>
    80000c16:	9736                	add	a4,a4,a3
    80000c18:	4318                	lw	a4,0(a4)
    80000c1a:	e321                	bnez	a4,80000c5a <kalloc+0x76>
      panic("refcnt kalloc");
    }
    refcnt[pn] = 1;
    80000c1c:	078a                	slli	a5,a5,0x2
    80000c1e:	00010717          	auipc	a4,0x10
    80000c22:	18270713          	addi	a4,a4,386 # 80010da0 <refcnt>
    80000c26:	97ba                	add	a5,a5,a4
    80000c28:	4705                	li	a4,1
    80000c2a:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000c2c:	609c                	ld	a5,0(s1)
    80000c2e:	00010517          	auipc	a0,0x10
    80000c32:	15250513          	addi	a0,a0,338 # 80010d80 <kmem>
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
    80000c6e:	11650513          	addi	a0,a0,278 # 80010d80 <kmem>
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
    80000fc2:	b5a70713          	addi	a4,a4,-1190 # 80008b18 <started>
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
    80001000:	ec4080e7          	jalr	-316(ra) # 80005ec0 <plicinithart>
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
    80001080:	e2e080e7          	jalr	-466(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001084:	00005097          	auipc	ra,0x5
    80001088:	e3c080e7          	jalr	-452(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    8000108c:	00002097          	auipc	ra,0x2
    80001090:	fd0080e7          	jalr	-48(ra) # 8000305c <binit>
    iinit();         // inode table
    80001094:	00002097          	auipc	ra,0x2
    80001098:	670080e7          	jalr	1648(ra) # 80003704 <iinit>
    fileinit();      // file table
    8000109c:	00003097          	auipc	ra,0x3
    800010a0:	616080e7          	jalr	1558(ra) # 800046b2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a4:	00005097          	auipc	ra,0x5
    800010a8:	f24080e7          	jalr	-220(ra) # 80005fc8 <virtio_disk_init>
    userinit();      // first user process
    800010ac:	00001097          	auipc	ra,0x1
    800010b0:	d28080e7          	jalr	-728(ra) # 80001dd4 <userinit>
    __sync_synchronize();
    800010b4:	0ff0000f          	fence
    started = 1;
    800010b8:	4785                	li	a5,1
    800010ba:	00008717          	auipc	a4,0x8
    800010be:	a4f72f23          	sw	a5,-1442(a4) # 80008b18 <started>
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
    800010d2:	a527b783          	ld	a5,-1454(a5) # 80008b20 <kernel_pagetable>
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
    8000138e:	78a7bb23          	sd	a0,1942(a5) # 80008b20 <kernel_pagetable>
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
    80001950:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdbb84f>
    80001954:	95da                	add	a1,a1,s6
    while (n > 0)
    80001956:	96da                	add	a3,a3,s6
      if (*p == '\0')
    80001958:	00f60733          	add	a4,a2,a5
    8000195c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbb850>
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
    800019a0:	83448493          	addi	s1,s1,-1996 # 802311d0 <proc>
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
    800019ba:	a1aa0a13          	addi	s4,s4,-1510 # 802383d0 <tickslock>
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
    80001a3c:	36850513          	addi	a0,a0,872 # 80230da0 <pid_lock>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	23c080e7          	jalr	572(ra) # 80000c7c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	7d858593          	addi	a1,a1,2008 # 80008220 <digits+0x1e0>
    80001a50:	0022f517          	auipc	a0,0x22f
    80001a54:	36850513          	addi	a0,a0,872 # 80230db8 <wait_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	224080e7          	jalr	548(ra) # 80000c7c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	0022f497          	auipc	s1,0x22f
    80001a64:	77048493          	addi	s1,s1,1904 # 802311d0 <proc>
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
    80001a86:	94e98993          	addi	s3,s3,-1714 # 802383d0 <tickslock>
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
    80001af0:	2e450513          	addi	a0,a0,740 # 80230dd0 <cpus>
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
    80001b18:	28c70713          	addi	a4,a4,652 # 80230da0 <pid_lock>
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
    80001b50:	ee47a783          	lw	a5,-284(a5) # 80008a30 <first.1>
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
    80001b6a:	ec07a523          	sw	zero,-310(a5) # 80008a30 <first.1>
    fsinit(ROOTDEV);
    80001b6e:	4505                	li	a0,1
    80001b70:	00002097          	auipc	ra,0x2
    80001b74:	b14080e7          	jalr	-1260(ra) # 80003684 <fsinit>
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
    80001b8a:	21a90913          	addi	s2,s2,538 # 80230da0 <pid_lock>
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	17c080e7          	jalr	380(ra) # 80000d0c <acquire>
  pid = nextpid;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	e9c78793          	addi	a5,a5,-356 # 80008a34 <nextpid>
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
    80001d16:	4be48493          	addi	s1,s1,1214 # 802311d0 <proc>
    80001d1a:	00236917          	auipc	s2,0x236
    80001d1e:	6b690913          	addi	s2,s2,1718 # 802383d0 <tickslock>
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
    80001dec:	d4a7b023          	sd	a0,-704(a5) # 80008b28 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001df0:	03400613          	li	a2,52
    80001df4:	00007597          	auipc	a1,0x7
    80001df8:	c4c58593          	addi	a1,a1,-948 # 80008a40 <initcode>
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
    80001e36:	27c080e7          	jalr	636(ra) # 800040ae <namei>
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
    80001f66:	7e2080e7          	jalr	2018(ra) # 80004744 <filedup>
    80001f6a:	00a93023          	sd	a0,0(s2)
    80001f6e:	b7e5                	j	80001f56 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f70:	150ab503          	ld	a0,336(s5)
    80001f74:	00002097          	auipc	ra,0x2
    80001f78:	950080e7          	jalr	-1712(ra) # 800038c4 <idup>
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
    80001fa4:	e1848493          	addi	s1,s1,-488 # 80230db8 <wait_lock>
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
    80002012:	d9270713          	addi	a4,a4,-622 # 80230da0 <pid_lock>
    80002016:	9756                	add	a4,a4,s5
    80002018:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000201c:	0022f717          	auipc	a4,0x22f
    80002020:	dbc70713          	addi	a4,a4,-580 # 80230dd8 <cpus+0x8>
    80002024:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002026:	498d                	li	s3,3
        p->state = RUNNING;
    80002028:	4b11                	li	s6,4
        c->proc = p;
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	0022fa17          	auipc	s4,0x22f
    80002030:	d74a0a13          	addi	s4,s4,-652 # 80230da0 <pid_lock>
    80002034:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002036:	00236917          	auipc	s2,0x236
    8000203a:	39a90913          	addi	s2,s2,922 # 802383d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002042:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002046:	10079073          	csrw	sstatus,a5
    8000204a:	0022f497          	auipc	s1,0x22f
    8000204e:	18648493          	addi	s1,s1,390 # 802311d0 <proc>
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
    800020be:	ce670713          	addi	a4,a4,-794 # 80230da0 <pid_lock>
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
    800020e4:	cc090913          	addi	s2,s2,-832 # 80230da0 <pid_lock>
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	97ca                	add	a5,a5,s2
    800020ee:	0ac7a983          	lw	s3,172(a5)
    800020f2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f4:	2781                	sext.w	a5,a5
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	0022f597          	auipc	a1,0x22f
    800020fc:	ce058593          	addi	a1,a1,-800 # 80230dd8 <cpus+0x8>
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
    80002220:	fb448493          	addi	s1,s1,-76 # 802311d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002224:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002226:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002228:	00236917          	auipc	s2,0x236
    8000222c:	1a890913          	addi	s2,s2,424 # 802383d0 <tickslock>
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
    80002294:	f4048493          	addi	s1,s1,-192 # 802311d0 <proc>
      pp->parent = initproc;
    80002298:	00007a17          	auipc	s4,0x7
    8000229c:	890a0a13          	addi	s4,s4,-1904 # 80008b28 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a0:	00236997          	auipc	s3,0x236
    800022a4:	13098993          	addi	s3,s3,304 # 802383d0 <tickslock>
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
    800022f4:	00007797          	auipc	a5,0x7
    800022f8:	8347b783          	ld	a5,-1996(a5) # 80008b28 <initproc>
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
    8000231c:	47e080e7          	jalr	1150(ra) # 80004796 <fileclose>
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
    80002334:	f9e080e7          	jalr	-98(ra) # 800042ce <begin_op>
  iput(p->cwd);
    80002338:	1509b503          	ld	a0,336(s3)
    8000233c:	00001097          	auipc	ra,0x1
    80002340:	780080e7          	jalr	1920(ra) # 80003abc <iput>
  end_op();
    80002344:	00002097          	auipc	ra,0x2
    80002348:	008080e7          	jalr	8(ra) # 8000434c <end_op>
  p->cwd = 0;
    8000234c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002350:	0022f497          	auipc	s1,0x22f
    80002354:	a6848493          	addi	s1,s1,-1432 # 80230db8 <wait_lock>
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
    800023c2:	e1248493          	addi	s1,s1,-494 # 802311d0 <proc>
    800023c6:	00236997          	auipc	s3,0x236
    800023ca:	00a98993          	addi	s3,s3,10 # 802383d0 <tickslock>
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
    800024a2:	0022f517          	auipc	a0,0x22f
    800024a6:	91650513          	addi	a0,a0,-1770 # 80230db8 <wait_lock>
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
    800024bc:	f1898993          	addi	s3,s3,-232 # 802383d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c0:	0022fc17          	auipc	s8,0x22f
    800024c4:	8f8c0c13          	addi	s8,s8,-1800 # 80230db8 <wait_lock>
    havekids = 0;
    800024c8:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ca:	0022f497          	auipc	s1,0x22f
    800024ce:	d0648493          	addi	s1,s1,-762 # 802311d0 <proc>
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
    80002508:	0022f517          	auipc	a0,0x22f
    8000250c:	8b050513          	addi	a0,a0,-1872 # 80230db8 <wait_lock>
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	8b0080e7          	jalr	-1872(ra) # 80000dc0 <release>
          return pid;
    80002518:	a0b5                	j	80002584 <wait+0x106>
            release(&pp->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	8a4080e7          	jalr	-1884(ra) # 80000dc0 <release>
            release(&wait_lock);
    80002524:	0022f517          	auipc	a0,0x22f
    80002528:	89450513          	addi	a0,a0,-1900 # 80230db8 <wait_lock>
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
    80002572:	0022f517          	auipc	a0,0x22f
    80002576:	84650513          	addi	a0,a0,-1978 # 80230db8 <wait_lock>
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
    80002682:	caa48493          	addi	s1,s1,-854 # 80231328 <proc+0x158>
    80002686:	00236917          	auipc	s2,0x236
    8000268a:	ea290913          	addi	s2,s2,-350 # 80238528 <bcache+0x140>
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
    80002786:	c4e50513          	addi	a0,a0,-946 # 802383d0 <tickslock>
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
    800027a4:	65078793          	addi	a5,a5,1616 # 80005df0 <kernelvec>
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
    800028da:	afa48493          	addi	s1,s1,-1286 # 802383d0 <tickslock>
    800028de:	8526                	mv	a0,s1
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	42c080e7          	jalr	1068(ra) # 80000d0c <acquire>
  ticks++;
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	24850513          	addi	a0,a0,584 # 80008b30 <ticks>
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
    80002948:	5b4080e7          	jalr	1460(ra) # 80005ef8 <plic_claim>
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
    80002976:	5aa080e7          	jalr	1450(ra) # 80005f1c <plic_complete>
    return 1;
    8000297a:	4505                	li	a0,1
    8000297c:	bf55                	j	80002930 <devintr+0x1e>
      uartintr();
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	01a080e7          	jalr	26(ra) # 80000998 <uartintr>
    80002986:	b7ed                	j	80002970 <devintr+0x5e>
      virtio_disk_intr();
    80002988:	00004097          	auipc	ra,0x4
    8000298c:	a5c080e7          	jalr	-1444(ra) # 800063e4 <virtio_disk_intr>
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
    800029ce:	42678793          	addi	a5,a5,1062 # 80005df0 <kernelvec>
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
    80002bd2:	97a70713          	addi	a4,a4,-1670 # 80008548 <states.0+0x248>
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
[SYS_trace] 1,
};

void
syscall(void)
{
    80002d30:	7139                	addi	sp,sp,-64
    80002d32:	fc06                	sd	ra,56(sp)
    80002d34:	f822                	sd	s0,48(sp)
    80002d36:	f426                	sd	s1,40(sp)
    80002d38:	f04a                	sd	s2,32(sp)
    80002d3a:	ec4e                	sd	s3,24(sp)
    80002d3c:	e852                	sd	s4,16(sp)
    80002d3e:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	dbc080e7          	jalr	-580(ra) # 80001afc <myproc>
    80002d48:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002d4a:	6d24                	ld	s1,88(a0)
    80002d4c:	74dc                	ld	a5,168(s1)
    80002d4e:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d52:	37fd                	addiw	a5,a5,-1
    80002d54:	475d                	li	a4,23
    80002d56:	00f76e63          	bltu	a4,a5,80002d72 <syscall+0x42>
    80002d5a:	00399713          	slli	a4,s3,0x3
    80002d5e:	00006797          	auipc	a5,0x6
    80002d62:	80278793          	addi	a5,a5,-2046 # 80008560 <syscalls>
    80002d66:	97ba                	add	a5,a5,a4
    80002d68:	639c                	ld	a5,0(a5)
    80002d6a:	c781                	beqz	a5,80002d72 <syscall+0x42>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d6c:	9782                	jalr	a5
    80002d6e:	f8a8                	sd	a0,112(s1)
    80002d70:	a015                	j	80002d94 <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d72:	86ce                	mv	a3,s3
    80002d74:	15890613          	addi	a2,s2,344
    80002d78:	03092583          	lw	a1,48(s2)
    80002d7c:	00005517          	auipc	a0,0x5
    80002d80:	6d450513          	addi	a0,a0,1748 # 80008450 <states.0+0x150>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	806080e7          	jalr	-2042(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d8c:	05893783          	ld	a5,88(s2)
    80002d90:	577d                	li	a4,-1
    80002d92:	fbb8                	sd	a4,112(a5)
  }

  if (p->tracemask >> num) {
    80002d94:	03492783          	lw	a5,52(s2)
    80002d98:	4137d7bb          	sraw	a5,a5,s3
    80002d9c:	eb89                	bnez	a5,80002dae <syscall+0x7e>
        printf("%d ", ar);                         
      }
        
    printf(") -> %d\n", p->trapframe->a0);
}
    80002d9e:	70e2                	ld	ra,56(sp)
    80002da0:	7442                	ld	s0,48(sp)
    80002da2:	74a2                	ld	s1,40(sp)
    80002da4:	7902                	ld	s2,32(sp)
    80002da6:	69e2                	ld	s3,24(sp)
    80002da8:	6a42                	ld	s4,16(sp)
    80002daa:	6121                	addi	sp,sp,64
    80002dac:	8082                	ret
	  printf("%d: syscall %s (", 
    80002dae:	00399713          	slli	a4,s3,0x3
    80002db2:	00005797          	auipc	a5,0x5
    80002db6:	7ae78793          	addi	a5,a5,1966 # 80008560 <syscalls>
    80002dba:	97ba                	add	a5,a5,a4
    80002dbc:	67f0                	ld	a2,200(a5)
    80002dbe:	03092583          	lw	a1,48(s2)
    80002dc2:	00005517          	auipc	a0,0x5
    80002dc6:	6ae50513          	addi	a0,a0,1710 # 80008470 <states.0+0x170>
    80002dca:	ffffd097          	auipc	ra,0xffffd
    80002dce:	7c0080e7          	jalr	1984(ra) # 8000058a <printf>
      for(int i = 0; i<syscallNos[num]; i++)
    80002dd2:	00299713          	slli	a4,s3,0x2
    80002dd6:	00006797          	auipc	a5,0x6
    80002dda:	ca278793          	addi	a5,a5,-862 # 80008a78 <syscallNos>
    80002dde:	97ba                	add	a5,a5,a4
    80002de0:	439c                	lw	a5,0(a5)
    80002de2:	04f05863          	blez	a5,80002e32 <syscall+0x102>
    80002de6:	4481                	li	s1,0
        printf("%d ", ar);                         
    80002de8:	00005a17          	auipc	s4,0x5
    80002dec:	6a0a0a13          	addi	s4,s4,1696 # 80008488 <states.0+0x188>
      for(int i = 0; i<syscallNos[num]; i++)
    80002df0:	00006797          	auipc	a5,0x6
    80002df4:	c8878793          	addi	a5,a5,-888 # 80008a78 <syscallNos>
    80002df8:	00e789b3          	add	s3,a5,a4
    80002dfc:	a015                	j	80002e20 <syscall+0xf0>
        else ar = p->trapframe->a0;
    80002dfe:	05893783          	ld	a5,88(s2)
    80002e02:	7bbc                	ld	a5,112(a5)
    80002e04:	fcf42623          	sw	a5,-52(s0)
        printf("%d ", ar);                         
    80002e08:	fcc42583          	lw	a1,-52(s0)
    80002e0c:	8552                	mv	a0,s4
    80002e0e:	ffffd097          	auipc	ra,0xffffd
    80002e12:	77c080e7          	jalr	1916(ra) # 8000058a <printf>
      for(int i = 0; i<syscallNos[num]; i++)
    80002e16:	2485                	addiw	s1,s1,1
    80002e18:	0009a783          	lw	a5,0(s3)
    80002e1c:	00f4db63          	bge	s1,a5,80002e32 <syscall+0x102>
        if(i != 0)
    80002e20:	dcf9                	beqz	s1,80002dfe <syscall+0xce>
          argint(i, &ar);
    80002e22:	fcc40593          	addi	a1,s0,-52
    80002e26:	8526                	mv	a0,s1
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	e90080e7          	jalr	-368(ra) # 80002cb8 <argint>
    80002e30:	bfe1                	j	80002e08 <syscall+0xd8>
    printf(") -> %d\n", p->trapframe->a0);
    80002e32:	05893783          	ld	a5,88(s2)
    80002e36:	7bac                	ld	a1,112(a5)
    80002e38:	00005517          	auipc	a0,0x5
    80002e3c:	65850513          	addi	a0,a0,1624 # 80008490 <states.0+0x190>
    80002e40:	ffffd097          	auipc	ra,0xffffd
    80002e44:	74a080e7          	jalr	1866(ra) # 8000058a <printf>
    80002e48:	bf99                	j	80002d9e <syscall+0x6e>

0000000080002e4a <sys_exit>:
#include "proc.h"
// #include "date.h"

uint64
sys_exit(void)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e52:	fec40593          	addi	a1,s0,-20
    80002e56:	4501                	li	a0,0
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	e60080e7          	jalr	-416(ra) # 80002cb8 <argint>
  exit(n);
    80002e60:	fec42503          	lw	a0,-20(s0)
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	474080e7          	jalr	1140(ra) # 800022d8 <exit>
  return 0;  // not reached
}
    80002e6c:	4501                	li	a0,0
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	6105                	addi	sp,sp,32
    80002e74:	8082                	ret

0000000080002e76 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e76:	1141                	addi	sp,sp,-16
    80002e78:	e406                	sd	ra,8(sp)
    80002e7a:	e022                	sd	s0,0(sp)
    80002e7c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	c7e080e7          	jalr	-898(ra) # 80001afc <myproc>
}
    80002e86:	5908                	lw	a0,48(a0)
    80002e88:	60a2                	ld	ra,8(sp)
    80002e8a:	6402                	ld	s0,0(sp)
    80002e8c:	0141                	addi	sp,sp,16
    80002e8e:	8082                	ret

0000000080002e90 <sys_fork>:

uint64
sys_fork(void)
{
    80002e90:	1141                	addi	sp,sp,-16
    80002e92:	e406                	sd	ra,8(sp)
    80002e94:	e022                	sd	s0,0(sp)
    80002e96:	0800                	addi	s0,sp,16
  return fork();
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	01a080e7          	jalr	26(ra) # 80001eb2 <fork>
}
    80002ea0:	60a2                	ld	ra,8(sp)
    80002ea2:	6402                	ld	s0,0(sp)
    80002ea4:	0141                	addi	sp,sp,16
    80002ea6:	8082                	ret

0000000080002ea8 <sys_wait>:

uint64
sys_wait(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002eb0:	fe840593          	addi	a1,s0,-24
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	e22080e7          	jalr	-478(ra) # 80002cd8 <argaddr>
  return wait(p);
    80002ebe:	fe843503          	ld	a0,-24(s0)
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	5bc080e7          	jalr	1468(ra) # 8000247e <wait>
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	6105                	addi	sp,sp,32
    80002ed0:	8082                	ret

0000000080002ed2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ed2:	7179                	addi	sp,sp,-48
    80002ed4:	f406                	sd	ra,40(sp)
    80002ed6:	f022                	sd	s0,32(sp)
    80002ed8:	ec26                	sd	s1,24(sp)
    80002eda:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002edc:	fdc40593          	addi	a1,s0,-36
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	dd6080e7          	jalr	-554(ra) # 80002cb8 <argint>
  addr = myproc()->sz;
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	c12080e7          	jalr	-1006(ra) # 80001afc <myproc>
    80002ef2:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002ef4:	fdc42503          	lw	a0,-36(s0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	f5e080e7          	jalr	-162(ra) # 80001e56 <growproc>
    80002f00:	00054863          	bltz	a0,80002f10 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f04:	8526                	mv	a0,s1
    80002f06:	70a2                	ld	ra,40(sp)
    80002f08:	7402                	ld	s0,32(sp)
    80002f0a:	64e2                	ld	s1,24(sp)
    80002f0c:	6145                	addi	sp,sp,48
    80002f0e:	8082                	ret
    return -1;
    80002f10:	54fd                	li	s1,-1
    80002f12:	bfcd                	j	80002f04 <sys_sbrk+0x32>

0000000080002f14 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f14:	7139                	addi	sp,sp,-64
    80002f16:	fc06                	sd	ra,56(sp)
    80002f18:	f822                	sd	s0,48(sp)
    80002f1a:	f426                	sd	s1,40(sp)
    80002f1c:	f04a                	sd	s2,32(sp)
    80002f1e:	ec4e                	sd	s3,24(sp)
    80002f20:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f22:	fcc40593          	addi	a1,s0,-52
    80002f26:	4501                	li	a0,0
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	d90080e7          	jalr	-624(ra) # 80002cb8 <argint>
  acquire(&tickslock);
    80002f30:	00235517          	auipc	a0,0x235
    80002f34:	4a050513          	addi	a0,a0,1184 # 802383d0 <tickslock>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	dd4080e7          	jalr	-556(ra) # 80000d0c <acquire>
  ticks0 = ticks;
    80002f40:	00006917          	auipc	s2,0x6
    80002f44:	bf092903          	lw	s2,-1040(s2) # 80008b30 <ticks>
  while(ticks - ticks0 < n){
    80002f48:	fcc42783          	lw	a5,-52(s0)
    80002f4c:	cf9d                	beqz	a5,80002f8a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f4e:	00235997          	auipc	s3,0x235
    80002f52:	48298993          	addi	s3,s3,1154 # 802383d0 <tickslock>
    80002f56:	00006497          	auipc	s1,0x6
    80002f5a:	bda48493          	addi	s1,s1,-1062 # 80008b30 <ticks>
    if(killed(myproc())){
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	b9e080e7          	jalr	-1122(ra) # 80001afc <myproc>
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	4e6080e7          	jalr	1254(ra) # 8000244c <killed>
    80002f6e:	ed15                	bnez	a0,80002faa <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f70:	85ce                	mv	a1,s3
    80002f72:	8526                	mv	a0,s1
    80002f74:	fffff097          	auipc	ra,0xfffff
    80002f78:	230080e7          	jalr	560(ra) # 800021a4 <sleep>
  while(ticks - ticks0 < n){
    80002f7c:	409c                	lw	a5,0(s1)
    80002f7e:	412787bb          	subw	a5,a5,s2
    80002f82:	fcc42703          	lw	a4,-52(s0)
    80002f86:	fce7ece3          	bltu	a5,a4,80002f5e <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f8a:	00235517          	auipc	a0,0x235
    80002f8e:	44650513          	addi	a0,a0,1094 # 802383d0 <tickslock>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	e2e080e7          	jalr	-466(ra) # 80000dc0 <release>
  return 0;
    80002f9a:	4501                	li	a0,0
}
    80002f9c:	70e2                	ld	ra,56(sp)
    80002f9e:	7442                	ld	s0,48(sp)
    80002fa0:	74a2                	ld	s1,40(sp)
    80002fa2:	7902                	ld	s2,32(sp)
    80002fa4:	69e2                	ld	s3,24(sp)
    80002fa6:	6121                	addi	sp,sp,64
    80002fa8:	8082                	ret
      release(&tickslock);
    80002faa:	00235517          	auipc	a0,0x235
    80002fae:	42650513          	addi	a0,a0,1062 # 802383d0 <tickslock>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	e0e080e7          	jalr	-498(ra) # 80000dc0 <release>
      return -1;
    80002fba:	557d                	li	a0,-1
    80002fbc:	b7c5                	j	80002f9c <sys_sleep+0x88>

0000000080002fbe <sys_kill>:

uint64
sys_kill(void)
{
    80002fbe:	1101                	addi	sp,sp,-32
    80002fc0:	ec06                	sd	ra,24(sp)
    80002fc2:	e822                	sd	s0,16(sp)
    80002fc4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002fc6:	fec40593          	addi	a1,s0,-20
    80002fca:	4501                	li	a0,0
    80002fcc:	00000097          	auipc	ra,0x0
    80002fd0:	cec080e7          	jalr	-788(ra) # 80002cb8 <argint>
  return kill(pid);
    80002fd4:	fec42503          	lw	a0,-20(s0)
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	3d6080e7          	jalr	982(ra) # 800023ae <kill>
}
    80002fe0:	60e2                	ld	ra,24(sp)
    80002fe2:	6442                	ld	s0,16(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret

0000000080002fe8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fe8:	1101                	addi	sp,sp,-32
    80002fea:	ec06                	sd	ra,24(sp)
    80002fec:	e822                	sd	s0,16(sp)
    80002fee:	e426                	sd	s1,8(sp)
    80002ff0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ff2:	00235517          	auipc	a0,0x235
    80002ff6:	3de50513          	addi	a0,a0,990 # 802383d0 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	d12080e7          	jalr	-750(ra) # 80000d0c <acquire>
  xticks = ticks;
    80003002:	00006497          	auipc	s1,0x6
    80003006:	b2e4a483          	lw	s1,-1234(s1) # 80008b30 <ticks>
  release(&tickslock);
    8000300a:	00235517          	auipc	a0,0x235
    8000300e:	3c650513          	addi	a0,a0,966 # 802383d0 <tickslock>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	dae080e7          	jalr	-594(ra) # 80000dc0 <release>
  return xticks;
}
    8000301a:	02049513          	slli	a0,s1,0x20
    8000301e:	9101                	srli	a0,a0,0x20
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	64a2                	ld	s1,8(sp)
    80003026:	6105                	addi	sp,sp,32
    80003028:	8082                	ret

000000008000302a <sys_trace>:

uint64
sys_trace(void)
{
    8000302a:	1141                	addi	sp,sp,-16
    8000302c:	e406                	sd	ra,8(sp)
    8000302e:	e022                	sd	s0,0(sp)
    80003030:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tracemask);
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	aca080e7          	jalr	-1334(ra) # 80001afc <myproc>
    8000303a:	03450593          	addi	a1,a0,52
    8000303e:	4501                	li	a0,0
    80003040:	00000097          	auipc	ra,0x0
    80003044:	c78080e7          	jalr	-904(ra) # 80002cb8 <argint>
  if (myproc()->tracemask < 0)
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	ab4080e7          	jalr	-1356(ra) # 80001afc <myproc>
    80003050:	5948                	lw	a0,52(a0)
		return -1;

	return 0;
    80003052:	957d                	srai	a0,a0,0x3f
    80003054:	60a2                	ld	ra,8(sp)
    80003056:	6402                	ld	s0,0(sp)
    80003058:	0141                	addi	sp,sp,16
    8000305a:	8082                	ret

000000008000305c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000305c:	7179                	addi	sp,sp,-48
    8000305e:	f406                	sd	ra,40(sp)
    80003060:	f022                	sd	s0,32(sp)
    80003062:	ec26                	sd	s1,24(sp)
    80003064:	e84a                	sd	s2,16(sp)
    80003066:	e44e                	sd	s3,8(sp)
    80003068:	e052                	sd	s4,0(sp)
    8000306a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000306c:	00005597          	auipc	a1,0x5
    80003070:	68458593          	addi	a1,a1,1668 # 800086f0 <names+0xc8>
    80003074:	00235517          	auipc	a0,0x235
    80003078:	37450513          	addi	a0,a0,884 # 802383e8 <bcache>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	c00080e7          	jalr	-1024(ra) # 80000c7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003084:	0023d797          	auipc	a5,0x23d
    80003088:	36478793          	addi	a5,a5,868 # 802403e8 <bcache+0x8000>
    8000308c:	0023d717          	auipc	a4,0x23d
    80003090:	5c470713          	addi	a4,a4,1476 # 80240650 <bcache+0x8268>
    80003094:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003098:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000309c:	00235497          	auipc	s1,0x235
    800030a0:	36448493          	addi	s1,s1,868 # 80238400 <bcache+0x18>
    b->next = bcache.head.next;
    800030a4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030a6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030a8:	00005a17          	auipc	s4,0x5
    800030ac:	650a0a13          	addi	s4,s4,1616 # 800086f8 <names+0xd0>
    b->next = bcache.head.next;
    800030b0:	2b893783          	ld	a5,696(s2)
    800030b4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030b6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030ba:	85d2                	mv	a1,s4
    800030bc:	01048513          	addi	a0,s1,16
    800030c0:	00001097          	auipc	ra,0x1
    800030c4:	4c8080e7          	jalr	1224(ra) # 80004588 <initsleeplock>
    bcache.head.next->prev = b;
    800030c8:	2b893783          	ld	a5,696(s2)
    800030cc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030ce:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d2:	45848493          	addi	s1,s1,1112
    800030d6:	fd349de3          	bne	s1,s3,800030b0 <binit+0x54>
  }
}
    800030da:	70a2                	ld	ra,40(sp)
    800030dc:	7402                	ld	s0,32(sp)
    800030de:	64e2                	ld	s1,24(sp)
    800030e0:	6942                	ld	s2,16(sp)
    800030e2:	69a2                	ld	s3,8(sp)
    800030e4:	6a02                	ld	s4,0(sp)
    800030e6:	6145                	addi	sp,sp,48
    800030e8:	8082                	ret

00000000800030ea <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ea:	7179                	addi	sp,sp,-48
    800030ec:	f406                	sd	ra,40(sp)
    800030ee:	f022                	sd	s0,32(sp)
    800030f0:	ec26                	sd	s1,24(sp)
    800030f2:	e84a                	sd	s2,16(sp)
    800030f4:	e44e                	sd	s3,8(sp)
    800030f6:	1800                	addi	s0,sp,48
    800030f8:	892a                	mv	s2,a0
    800030fa:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030fc:	00235517          	auipc	a0,0x235
    80003100:	2ec50513          	addi	a0,a0,748 # 802383e8 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	c08080e7          	jalr	-1016(ra) # 80000d0c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000310c:	0023d497          	auipc	s1,0x23d
    80003110:	5944b483          	ld	s1,1428(s1) # 802406a0 <bcache+0x82b8>
    80003114:	0023d797          	auipc	a5,0x23d
    80003118:	53c78793          	addi	a5,a5,1340 # 80240650 <bcache+0x8268>
    8000311c:	02f48f63          	beq	s1,a5,8000315a <bread+0x70>
    80003120:	873e                	mv	a4,a5
    80003122:	a021                	j	8000312a <bread+0x40>
    80003124:	68a4                	ld	s1,80(s1)
    80003126:	02e48a63          	beq	s1,a4,8000315a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000312a:	449c                	lw	a5,8(s1)
    8000312c:	ff279ce3          	bne	a5,s2,80003124 <bread+0x3a>
    80003130:	44dc                	lw	a5,12(s1)
    80003132:	ff3799e3          	bne	a5,s3,80003124 <bread+0x3a>
      b->refcnt++;
    80003136:	40bc                	lw	a5,64(s1)
    80003138:	2785                	addiw	a5,a5,1
    8000313a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000313c:	00235517          	auipc	a0,0x235
    80003140:	2ac50513          	addi	a0,a0,684 # 802383e8 <bcache>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	c7c080e7          	jalr	-900(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    8000314c:	01048513          	addi	a0,s1,16
    80003150:	00001097          	auipc	ra,0x1
    80003154:	472080e7          	jalr	1138(ra) # 800045c2 <acquiresleep>
      return b;
    80003158:	a8b9                	j	800031b6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000315a:	0023d497          	auipc	s1,0x23d
    8000315e:	53e4b483          	ld	s1,1342(s1) # 80240698 <bcache+0x82b0>
    80003162:	0023d797          	auipc	a5,0x23d
    80003166:	4ee78793          	addi	a5,a5,1262 # 80240650 <bcache+0x8268>
    8000316a:	00f48863          	beq	s1,a5,8000317a <bread+0x90>
    8000316e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003170:	40bc                	lw	a5,64(s1)
    80003172:	cf81                	beqz	a5,8000318a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003174:	64a4                	ld	s1,72(s1)
    80003176:	fee49de3          	bne	s1,a4,80003170 <bread+0x86>
  panic("bget: no buffers");
    8000317a:	00005517          	auipc	a0,0x5
    8000317e:	58650513          	addi	a0,a0,1414 # 80008700 <names+0xd8>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      b->dev = dev;
    8000318a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000318e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003192:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003196:	4785                	li	a5,1
    80003198:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000319a:	00235517          	auipc	a0,0x235
    8000319e:	24e50513          	addi	a0,a0,590 # 802383e8 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	c1e080e7          	jalr	-994(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    800031aa:	01048513          	addi	a0,s1,16
    800031ae:	00001097          	auipc	ra,0x1
    800031b2:	414080e7          	jalr	1044(ra) # 800045c2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031b6:	409c                	lw	a5,0(s1)
    800031b8:	cb89                	beqz	a5,800031ca <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031ba:	8526                	mv	a0,s1
    800031bc:	70a2                	ld	ra,40(sp)
    800031be:	7402                	ld	s0,32(sp)
    800031c0:	64e2                	ld	s1,24(sp)
    800031c2:	6942                	ld	s2,16(sp)
    800031c4:	69a2                	ld	s3,8(sp)
    800031c6:	6145                	addi	sp,sp,48
    800031c8:	8082                	ret
    virtio_disk_rw(b, 0);
    800031ca:	4581                	li	a1,0
    800031cc:	8526                	mv	a0,s1
    800031ce:	00003097          	auipc	ra,0x3
    800031d2:	fe4080e7          	jalr	-28(ra) # 800061b2 <virtio_disk_rw>
    b->valid = 1;
    800031d6:	4785                	li	a5,1
    800031d8:	c09c                	sw	a5,0(s1)
  return b;
    800031da:	b7c5                	j	800031ba <bread+0xd0>

00000000800031dc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031e8:	0541                	addi	a0,a0,16
    800031ea:	00001097          	auipc	ra,0x1
    800031ee:	472080e7          	jalr	1138(ra) # 8000465c <holdingsleep>
    800031f2:	cd01                	beqz	a0,8000320a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031f4:	4585                	li	a1,1
    800031f6:	8526                	mv	a0,s1
    800031f8:	00003097          	auipc	ra,0x3
    800031fc:	fba080e7          	jalr	-70(ra) # 800061b2 <virtio_disk_rw>
}
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	64a2                	ld	s1,8(sp)
    80003206:	6105                	addi	sp,sp,32
    80003208:	8082                	ret
    panic("bwrite");
    8000320a:	00005517          	auipc	a0,0x5
    8000320e:	50e50513          	addi	a0,a0,1294 # 80008718 <names+0xf0>
    80003212:	ffffd097          	auipc	ra,0xffffd
    80003216:	32e080e7          	jalr	814(ra) # 80000540 <panic>

000000008000321a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	e04a                	sd	s2,0(sp)
    80003224:	1000                	addi	s0,sp,32
    80003226:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003228:	01050913          	addi	s2,a0,16
    8000322c:	854a                	mv	a0,s2
    8000322e:	00001097          	auipc	ra,0x1
    80003232:	42e080e7          	jalr	1070(ra) # 8000465c <holdingsleep>
    80003236:	c92d                	beqz	a0,800032a8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003238:	854a                	mv	a0,s2
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	3de080e7          	jalr	990(ra) # 80004618 <releasesleep>

  acquire(&bcache.lock);
    80003242:	00235517          	auipc	a0,0x235
    80003246:	1a650513          	addi	a0,a0,422 # 802383e8 <bcache>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	ac2080e7          	jalr	-1342(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003252:	40bc                	lw	a5,64(s1)
    80003254:	37fd                	addiw	a5,a5,-1
    80003256:	0007871b          	sext.w	a4,a5
    8000325a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000325c:	eb05                	bnez	a4,8000328c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000325e:	68bc                	ld	a5,80(s1)
    80003260:	64b8                	ld	a4,72(s1)
    80003262:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003264:	64bc                	ld	a5,72(s1)
    80003266:	68b8                	ld	a4,80(s1)
    80003268:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000326a:	0023d797          	auipc	a5,0x23d
    8000326e:	17e78793          	addi	a5,a5,382 # 802403e8 <bcache+0x8000>
    80003272:	2b87b703          	ld	a4,696(a5)
    80003276:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003278:	0023d717          	auipc	a4,0x23d
    8000327c:	3d870713          	addi	a4,a4,984 # 80240650 <bcache+0x8268>
    80003280:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003282:	2b87b703          	ld	a4,696(a5)
    80003286:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003288:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000328c:	00235517          	auipc	a0,0x235
    80003290:	15c50513          	addi	a0,a0,348 # 802383e8 <bcache>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	b2c080e7          	jalr	-1236(ra) # 80000dc0 <release>
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6902                	ld	s2,0(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret
    panic("brelse");
    800032a8:	00005517          	auipc	a0,0x5
    800032ac:	47850513          	addi	a0,a0,1144 # 80008720 <names+0xf8>
    800032b0:	ffffd097          	auipc	ra,0xffffd
    800032b4:	290080e7          	jalr	656(ra) # 80000540 <panic>

00000000800032b8 <bpin>:

void
bpin(struct buf *b) {
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	1000                	addi	s0,sp,32
    800032c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032c4:	00235517          	auipc	a0,0x235
    800032c8:	12450513          	addi	a0,a0,292 # 802383e8 <bcache>
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	a40080e7          	jalr	-1472(ra) # 80000d0c <acquire>
  b->refcnt++;
    800032d4:	40bc                	lw	a5,64(s1)
    800032d6:	2785                	addiw	a5,a5,1
    800032d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032da:	00235517          	auipc	a0,0x235
    800032de:	10e50513          	addi	a0,a0,270 # 802383e8 <bcache>
    800032e2:	ffffe097          	auipc	ra,0xffffe
    800032e6:	ade080e7          	jalr	-1314(ra) # 80000dc0 <release>
}
    800032ea:	60e2                	ld	ra,24(sp)
    800032ec:	6442                	ld	s0,16(sp)
    800032ee:	64a2                	ld	s1,8(sp)
    800032f0:	6105                	addi	sp,sp,32
    800032f2:	8082                	ret

00000000800032f4 <bunpin>:

void
bunpin(struct buf *b) {
    800032f4:	1101                	addi	sp,sp,-32
    800032f6:	ec06                	sd	ra,24(sp)
    800032f8:	e822                	sd	s0,16(sp)
    800032fa:	e426                	sd	s1,8(sp)
    800032fc:	1000                	addi	s0,sp,32
    800032fe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003300:	00235517          	auipc	a0,0x235
    80003304:	0e850513          	addi	a0,a0,232 # 802383e8 <bcache>
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	a04080e7          	jalr	-1532(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003310:	40bc                	lw	a5,64(s1)
    80003312:	37fd                	addiw	a5,a5,-1
    80003314:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003316:	00235517          	auipc	a0,0x235
    8000331a:	0d250513          	addi	a0,a0,210 # 802383e8 <bcache>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	aa2080e7          	jalr	-1374(ra) # 80000dc0 <release>
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	64a2                	ld	s1,8(sp)
    8000332c:	6105                	addi	sp,sp,32
    8000332e:	8082                	ret

0000000080003330 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003330:	1101                	addi	sp,sp,-32
    80003332:	ec06                	sd	ra,24(sp)
    80003334:	e822                	sd	s0,16(sp)
    80003336:	e426                	sd	s1,8(sp)
    80003338:	e04a                	sd	s2,0(sp)
    8000333a:	1000                	addi	s0,sp,32
    8000333c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000333e:	00d5d59b          	srliw	a1,a1,0xd
    80003342:	0023d797          	auipc	a5,0x23d
    80003346:	7827a783          	lw	a5,1922(a5) # 80240ac4 <sb+0x1c>
    8000334a:	9dbd                	addw	a1,a1,a5
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	d9e080e7          	jalr	-610(ra) # 800030ea <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003354:	0074f713          	andi	a4,s1,7
    80003358:	4785                	li	a5,1
    8000335a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000335e:	14ce                	slli	s1,s1,0x33
    80003360:	90d9                	srli	s1,s1,0x36
    80003362:	00950733          	add	a4,a0,s1
    80003366:	05874703          	lbu	a4,88(a4)
    8000336a:	00e7f6b3          	and	a3,a5,a4
    8000336e:	c69d                	beqz	a3,8000339c <bfree+0x6c>
    80003370:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003372:	94aa                	add	s1,s1,a0
    80003374:	fff7c793          	not	a5,a5
    80003378:	8f7d                	and	a4,a4,a5
    8000337a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000337e:	00001097          	auipc	ra,0x1
    80003382:	126080e7          	jalr	294(ra) # 800044a4 <log_write>
  brelse(bp);
    80003386:	854a                	mv	a0,s2
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	e92080e7          	jalr	-366(ra) # 8000321a <brelse>
}
    80003390:	60e2                	ld	ra,24(sp)
    80003392:	6442                	ld	s0,16(sp)
    80003394:	64a2                	ld	s1,8(sp)
    80003396:	6902                	ld	s2,0(sp)
    80003398:	6105                	addi	sp,sp,32
    8000339a:	8082                	ret
    panic("freeing free block");
    8000339c:	00005517          	auipc	a0,0x5
    800033a0:	38c50513          	addi	a0,a0,908 # 80008728 <names+0x100>
    800033a4:	ffffd097          	auipc	ra,0xffffd
    800033a8:	19c080e7          	jalr	412(ra) # 80000540 <panic>

00000000800033ac <balloc>:
{
    800033ac:	711d                	addi	sp,sp,-96
    800033ae:	ec86                	sd	ra,88(sp)
    800033b0:	e8a2                	sd	s0,80(sp)
    800033b2:	e4a6                	sd	s1,72(sp)
    800033b4:	e0ca                	sd	s2,64(sp)
    800033b6:	fc4e                	sd	s3,56(sp)
    800033b8:	f852                	sd	s4,48(sp)
    800033ba:	f456                	sd	s5,40(sp)
    800033bc:	f05a                	sd	s6,32(sp)
    800033be:	ec5e                	sd	s7,24(sp)
    800033c0:	e862                	sd	s8,16(sp)
    800033c2:	e466                	sd	s9,8(sp)
    800033c4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033c6:	0023d797          	auipc	a5,0x23d
    800033ca:	6e67a783          	lw	a5,1766(a5) # 80240aac <sb+0x4>
    800033ce:	cff5                	beqz	a5,800034ca <balloc+0x11e>
    800033d0:	8baa                	mv	s7,a0
    800033d2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033d4:	0023db17          	auipc	s6,0x23d
    800033d8:	6d4b0b13          	addi	s6,s6,1748 # 80240aa8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033dc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033de:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033e2:	6c89                	lui	s9,0x2
    800033e4:	a061                	j	8000346c <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033e6:	97ca                	add	a5,a5,s2
    800033e8:	8e55                	or	a2,a2,a3
    800033ea:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800033ee:	854a                	mv	a0,s2
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	0b4080e7          	jalr	180(ra) # 800044a4 <log_write>
        brelse(bp);
    800033f8:	854a                	mv	a0,s2
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	e20080e7          	jalr	-480(ra) # 8000321a <brelse>
  bp = bread(dev, bno);
    80003402:	85a6                	mv	a1,s1
    80003404:	855e                	mv	a0,s7
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	ce4080e7          	jalr	-796(ra) # 800030ea <bread>
    8000340e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003410:	40000613          	li	a2,1024
    80003414:	4581                	li	a1,0
    80003416:	05850513          	addi	a0,a0,88
    8000341a:	ffffe097          	auipc	ra,0xffffe
    8000341e:	9ee080e7          	jalr	-1554(ra) # 80000e08 <memset>
  log_write(bp);
    80003422:	854a                	mv	a0,s2
    80003424:	00001097          	auipc	ra,0x1
    80003428:	080080e7          	jalr	128(ra) # 800044a4 <log_write>
  brelse(bp);
    8000342c:	854a                	mv	a0,s2
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	dec080e7          	jalr	-532(ra) # 8000321a <brelse>
}
    80003436:	8526                	mv	a0,s1
    80003438:	60e6                	ld	ra,88(sp)
    8000343a:	6446                	ld	s0,80(sp)
    8000343c:	64a6                	ld	s1,72(sp)
    8000343e:	6906                	ld	s2,64(sp)
    80003440:	79e2                	ld	s3,56(sp)
    80003442:	7a42                	ld	s4,48(sp)
    80003444:	7aa2                	ld	s5,40(sp)
    80003446:	7b02                	ld	s6,32(sp)
    80003448:	6be2                	ld	s7,24(sp)
    8000344a:	6c42                	ld	s8,16(sp)
    8000344c:	6ca2                	ld	s9,8(sp)
    8000344e:	6125                	addi	sp,sp,96
    80003450:	8082                	ret
    brelse(bp);
    80003452:	854a                	mv	a0,s2
    80003454:	00000097          	auipc	ra,0x0
    80003458:	dc6080e7          	jalr	-570(ra) # 8000321a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000345c:	015c87bb          	addw	a5,s9,s5
    80003460:	00078a9b          	sext.w	s5,a5
    80003464:	004b2703          	lw	a4,4(s6)
    80003468:	06eaf163          	bgeu	s5,a4,800034ca <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000346c:	41fad79b          	sraiw	a5,s5,0x1f
    80003470:	0137d79b          	srliw	a5,a5,0x13
    80003474:	015787bb          	addw	a5,a5,s5
    80003478:	40d7d79b          	sraiw	a5,a5,0xd
    8000347c:	01cb2583          	lw	a1,28(s6)
    80003480:	9dbd                	addw	a1,a1,a5
    80003482:	855e                	mv	a0,s7
    80003484:	00000097          	auipc	ra,0x0
    80003488:	c66080e7          	jalr	-922(ra) # 800030ea <bread>
    8000348c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000348e:	004b2503          	lw	a0,4(s6)
    80003492:	000a849b          	sext.w	s1,s5
    80003496:	8762                	mv	a4,s8
    80003498:	faa4fde3          	bgeu	s1,a0,80003452 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000349c:	00777693          	andi	a3,a4,7
    800034a0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034a4:	41f7579b          	sraiw	a5,a4,0x1f
    800034a8:	01d7d79b          	srliw	a5,a5,0x1d
    800034ac:	9fb9                	addw	a5,a5,a4
    800034ae:	4037d79b          	sraiw	a5,a5,0x3
    800034b2:	00f90633          	add	a2,s2,a5
    800034b6:	05864603          	lbu	a2,88(a2)
    800034ba:	00c6f5b3          	and	a1,a3,a2
    800034be:	d585                	beqz	a1,800033e6 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c0:	2705                	addiw	a4,a4,1
    800034c2:	2485                	addiw	s1,s1,1
    800034c4:	fd471ae3          	bne	a4,s4,80003498 <balloc+0xec>
    800034c8:	b769                	j	80003452 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800034ca:	00005517          	auipc	a0,0x5
    800034ce:	27650513          	addi	a0,a0,630 # 80008740 <names+0x118>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	0b8080e7          	jalr	184(ra) # 8000058a <printf>
  return 0;
    800034da:	4481                	li	s1,0
    800034dc:	bfa9                	j	80003436 <balloc+0x8a>

00000000800034de <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034de:	7179                	addi	sp,sp,-48
    800034e0:	f406                	sd	ra,40(sp)
    800034e2:	f022                	sd	s0,32(sp)
    800034e4:	ec26                	sd	s1,24(sp)
    800034e6:	e84a                	sd	s2,16(sp)
    800034e8:	e44e                	sd	s3,8(sp)
    800034ea:	e052                	sd	s4,0(sp)
    800034ec:	1800                	addi	s0,sp,48
    800034ee:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034f0:	47ad                	li	a5,11
    800034f2:	02b7e863          	bltu	a5,a1,80003522 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800034f6:	02059793          	slli	a5,a1,0x20
    800034fa:	01e7d593          	srli	a1,a5,0x1e
    800034fe:	00b504b3          	add	s1,a0,a1
    80003502:	0504a903          	lw	s2,80(s1)
    80003506:	06091e63          	bnez	s2,80003582 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000350a:	4108                	lw	a0,0(a0)
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	ea0080e7          	jalr	-352(ra) # 800033ac <balloc>
    80003514:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003518:	06090563          	beqz	s2,80003582 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000351c:	0524a823          	sw	s2,80(s1)
    80003520:	a08d                	j	80003582 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003522:	ff45849b          	addiw	s1,a1,-12
    80003526:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000352a:	0ff00793          	li	a5,255
    8000352e:	08e7e563          	bltu	a5,a4,800035b8 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003532:	08052903          	lw	s2,128(a0)
    80003536:	00091d63          	bnez	s2,80003550 <bmap+0x72>
      addr = balloc(ip->dev);
    8000353a:	4108                	lw	a0,0(a0)
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	e70080e7          	jalr	-400(ra) # 800033ac <balloc>
    80003544:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003548:	02090d63          	beqz	s2,80003582 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000354c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003550:	85ca                	mv	a1,s2
    80003552:	0009a503          	lw	a0,0(s3)
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	b94080e7          	jalr	-1132(ra) # 800030ea <bread>
    8000355e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003560:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003564:	02049713          	slli	a4,s1,0x20
    80003568:	01e75593          	srli	a1,a4,0x1e
    8000356c:	00b784b3          	add	s1,a5,a1
    80003570:	0004a903          	lw	s2,0(s1)
    80003574:	02090063          	beqz	s2,80003594 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003578:	8552                	mv	a0,s4
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	ca0080e7          	jalr	-864(ra) # 8000321a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003582:	854a                	mv	a0,s2
    80003584:	70a2                	ld	ra,40(sp)
    80003586:	7402                	ld	s0,32(sp)
    80003588:	64e2                	ld	s1,24(sp)
    8000358a:	6942                	ld	s2,16(sp)
    8000358c:	69a2                	ld	s3,8(sp)
    8000358e:	6a02                	ld	s4,0(sp)
    80003590:	6145                	addi	sp,sp,48
    80003592:	8082                	ret
      addr = balloc(ip->dev);
    80003594:	0009a503          	lw	a0,0(s3)
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	e14080e7          	jalr	-492(ra) # 800033ac <balloc>
    800035a0:	0005091b          	sext.w	s2,a0
      if(addr){
    800035a4:	fc090ae3          	beqz	s2,80003578 <bmap+0x9a>
        a[bn] = addr;
    800035a8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035ac:	8552                	mv	a0,s4
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	ef6080e7          	jalr	-266(ra) # 800044a4 <log_write>
    800035b6:	b7c9                	j	80003578 <bmap+0x9a>
  panic("bmap: out of range");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	1a050513          	addi	a0,a0,416 # 80008758 <names+0x130>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f80080e7          	jalr	-128(ra) # 80000540 <panic>

00000000800035c8 <iget>:
{
    800035c8:	7179                	addi	sp,sp,-48
    800035ca:	f406                	sd	ra,40(sp)
    800035cc:	f022                	sd	s0,32(sp)
    800035ce:	ec26                	sd	s1,24(sp)
    800035d0:	e84a                	sd	s2,16(sp)
    800035d2:	e44e                	sd	s3,8(sp)
    800035d4:	e052                	sd	s4,0(sp)
    800035d6:	1800                	addi	s0,sp,48
    800035d8:	89aa                	mv	s3,a0
    800035da:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035dc:	0023d517          	auipc	a0,0x23d
    800035e0:	4ec50513          	addi	a0,a0,1260 # 80240ac8 <itable>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	728080e7          	jalr	1832(ra) # 80000d0c <acquire>
  empty = 0;
    800035ec:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ee:	0023d497          	auipc	s1,0x23d
    800035f2:	4f248493          	addi	s1,s1,1266 # 80240ae0 <itable+0x18>
    800035f6:	0023f697          	auipc	a3,0x23f
    800035fa:	f7a68693          	addi	a3,a3,-134 # 80242570 <log>
    800035fe:	a039                	j	8000360c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003600:	02090b63          	beqz	s2,80003636 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003604:	08848493          	addi	s1,s1,136
    80003608:	02d48a63          	beq	s1,a3,8000363c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000360c:	449c                	lw	a5,8(s1)
    8000360e:	fef059e3          	blez	a5,80003600 <iget+0x38>
    80003612:	4098                	lw	a4,0(s1)
    80003614:	ff3716e3          	bne	a4,s3,80003600 <iget+0x38>
    80003618:	40d8                	lw	a4,4(s1)
    8000361a:	ff4713e3          	bne	a4,s4,80003600 <iget+0x38>
      ip->ref++;
    8000361e:	2785                	addiw	a5,a5,1
    80003620:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003622:	0023d517          	auipc	a0,0x23d
    80003626:	4a650513          	addi	a0,a0,1190 # 80240ac8 <itable>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	796080e7          	jalr	1942(ra) # 80000dc0 <release>
      return ip;
    80003632:	8926                	mv	s2,s1
    80003634:	a03d                	j	80003662 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003636:	f7f9                	bnez	a5,80003604 <iget+0x3c>
    80003638:	8926                	mv	s2,s1
    8000363a:	b7e9                	j	80003604 <iget+0x3c>
  if(empty == 0)
    8000363c:	02090c63          	beqz	s2,80003674 <iget+0xac>
  ip->dev = dev;
    80003640:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003644:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003648:	4785                	li	a5,1
    8000364a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000364e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003652:	0023d517          	auipc	a0,0x23d
    80003656:	47650513          	addi	a0,a0,1142 # 80240ac8 <itable>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	766080e7          	jalr	1894(ra) # 80000dc0 <release>
}
    80003662:	854a                	mv	a0,s2
    80003664:	70a2                	ld	ra,40(sp)
    80003666:	7402                	ld	s0,32(sp)
    80003668:	64e2                	ld	s1,24(sp)
    8000366a:	6942                	ld	s2,16(sp)
    8000366c:	69a2                	ld	s3,8(sp)
    8000366e:	6a02                	ld	s4,0(sp)
    80003670:	6145                	addi	sp,sp,48
    80003672:	8082                	ret
    panic("iget: no inodes");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	0fc50513          	addi	a0,a0,252 # 80008770 <names+0x148>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ec4080e7          	jalr	-316(ra) # 80000540 <panic>

0000000080003684 <fsinit>:
fsinit(int dev) {
    80003684:	7179                	addi	sp,sp,-48
    80003686:	f406                	sd	ra,40(sp)
    80003688:	f022                	sd	s0,32(sp)
    8000368a:	ec26                	sd	s1,24(sp)
    8000368c:	e84a                	sd	s2,16(sp)
    8000368e:	e44e                	sd	s3,8(sp)
    80003690:	1800                	addi	s0,sp,48
    80003692:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003694:	4585                	li	a1,1
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	a54080e7          	jalr	-1452(ra) # 800030ea <bread>
    8000369e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036a0:	0023d997          	auipc	s3,0x23d
    800036a4:	40898993          	addi	s3,s3,1032 # 80240aa8 <sb>
    800036a8:	02000613          	li	a2,32
    800036ac:	05850593          	addi	a1,a0,88
    800036b0:	854e                	mv	a0,s3
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	7b2080e7          	jalr	1970(ra) # 80000e64 <memmove>
  brelse(bp);
    800036ba:	8526                	mv	a0,s1
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	b5e080e7          	jalr	-1186(ra) # 8000321a <brelse>
  if(sb.magic != FSMAGIC)
    800036c4:	0009a703          	lw	a4,0(s3)
    800036c8:	102037b7          	lui	a5,0x10203
    800036cc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036d0:	02f71263          	bne	a4,a5,800036f4 <fsinit+0x70>
  initlog(dev, &sb);
    800036d4:	0023d597          	auipc	a1,0x23d
    800036d8:	3d458593          	addi	a1,a1,980 # 80240aa8 <sb>
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	b4a080e7          	jalr	-1206(ra) # 80004228 <initlog>
}
    800036e6:	70a2                	ld	ra,40(sp)
    800036e8:	7402                	ld	s0,32(sp)
    800036ea:	64e2                	ld	s1,24(sp)
    800036ec:	6942                	ld	s2,16(sp)
    800036ee:	69a2                	ld	s3,8(sp)
    800036f0:	6145                	addi	sp,sp,48
    800036f2:	8082                	ret
    panic("invalid file system");
    800036f4:	00005517          	auipc	a0,0x5
    800036f8:	08c50513          	addi	a0,a0,140 # 80008780 <names+0x158>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	e44080e7          	jalr	-444(ra) # 80000540 <panic>

0000000080003704 <iinit>:
{
    80003704:	7179                	addi	sp,sp,-48
    80003706:	f406                	sd	ra,40(sp)
    80003708:	f022                	sd	s0,32(sp)
    8000370a:	ec26                	sd	s1,24(sp)
    8000370c:	e84a                	sd	s2,16(sp)
    8000370e:	e44e                	sd	s3,8(sp)
    80003710:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003712:	00005597          	auipc	a1,0x5
    80003716:	08658593          	addi	a1,a1,134 # 80008798 <names+0x170>
    8000371a:	0023d517          	auipc	a0,0x23d
    8000371e:	3ae50513          	addi	a0,a0,942 # 80240ac8 <itable>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	55a080e7          	jalr	1370(ra) # 80000c7c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000372a:	0023d497          	auipc	s1,0x23d
    8000372e:	3c648493          	addi	s1,s1,966 # 80240af0 <itable+0x28>
    80003732:	0023f997          	auipc	s3,0x23f
    80003736:	e4e98993          	addi	s3,s3,-434 # 80242580 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000373a:	00005917          	auipc	s2,0x5
    8000373e:	06690913          	addi	s2,s2,102 # 800087a0 <names+0x178>
    80003742:	85ca                	mv	a1,s2
    80003744:	8526                	mv	a0,s1
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	e42080e7          	jalr	-446(ra) # 80004588 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000374e:	08848493          	addi	s1,s1,136
    80003752:	ff3498e3          	bne	s1,s3,80003742 <iinit+0x3e>
}
    80003756:	70a2                	ld	ra,40(sp)
    80003758:	7402                	ld	s0,32(sp)
    8000375a:	64e2                	ld	s1,24(sp)
    8000375c:	6942                	ld	s2,16(sp)
    8000375e:	69a2                	ld	s3,8(sp)
    80003760:	6145                	addi	sp,sp,48
    80003762:	8082                	ret

0000000080003764 <ialloc>:
{
    80003764:	715d                	addi	sp,sp,-80
    80003766:	e486                	sd	ra,72(sp)
    80003768:	e0a2                	sd	s0,64(sp)
    8000376a:	fc26                	sd	s1,56(sp)
    8000376c:	f84a                	sd	s2,48(sp)
    8000376e:	f44e                	sd	s3,40(sp)
    80003770:	f052                	sd	s4,32(sp)
    80003772:	ec56                	sd	s5,24(sp)
    80003774:	e85a                	sd	s6,16(sp)
    80003776:	e45e                	sd	s7,8(sp)
    80003778:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000377a:	0023d717          	auipc	a4,0x23d
    8000377e:	33a72703          	lw	a4,826(a4) # 80240ab4 <sb+0xc>
    80003782:	4785                	li	a5,1
    80003784:	04e7fa63          	bgeu	a5,a4,800037d8 <ialloc+0x74>
    80003788:	8aaa                	mv	s5,a0
    8000378a:	8bae                	mv	s7,a1
    8000378c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000378e:	0023da17          	auipc	s4,0x23d
    80003792:	31aa0a13          	addi	s4,s4,794 # 80240aa8 <sb>
    80003796:	00048b1b          	sext.w	s6,s1
    8000379a:	0044d593          	srli	a1,s1,0x4
    8000379e:	018a2783          	lw	a5,24(s4)
    800037a2:	9dbd                	addw	a1,a1,a5
    800037a4:	8556                	mv	a0,s5
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	944080e7          	jalr	-1724(ra) # 800030ea <bread>
    800037ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037b0:	05850993          	addi	s3,a0,88
    800037b4:	00f4f793          	andi	a5,s1,15
    800037b8:	079a                	slli	a5,a5,0x6
    800037ba:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037bc:	00099783          	lh	a5,0(s3)
    800037c0:	c3a1                	beqz	a5,80003800 <ialloc+0x9c>
    brelse(bp);
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	a58080e7          	jalr	-1448(ra) # 8000321a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ca:	0485                	addi	s1,s1,1
    800037cc:	00ca2703          	lw	a4,12(s4)
    800037d0:	0004879b          	sext.w	a5,s1
    800037d4:	fce7e1e3          	bltu	a5,a4,80003796 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	fd050513          	addi	a0,a0,-48 # 800087a8 <names+0x180>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	daa080e7          	jalr	-598(ra) # 8000058a <printf>
  return 0;
    800037e8:	4501                	li	a0,0
}
    800037ea:	60a6                	ld	ra,72(sp)
    800037ec:	6406                	ld	s0,64(sp)
    800037ee:	74e2                	ld	s1,56(sp)
    800037f0:	7942                	ld	s2,48(sp)
    800037f2:	79a2                	ld	s3,40(sp)
    800037f4:	7a02                	ld	s4,32(sp)
    800037f6:	6ae2                	ld	s5,24(sp)
    800037f8:	6b42                	ld	s6,16(sp)
    800037fa:	6ba2                	ld	s7,8(sp)
    800037fc:	6161                	addi	sp,sp,80
    800037fe:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003800:	04000613          	li	a2,64
    80003804:	4581                	li	a1,0
    80003806:	854e                	mv	a0,s3
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	600080e7          	jalr	1536(ra) # 80000e08 <memset>
      dip->type = type;
    80003810:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003814:	854a                	mv	a0,s2
    80003816:	00001097          	auipc	ra,0x1
    8000381a:	c8e080e7          	jalr	-882(ra) # 800044a4 <log_write>
      brelse(bp);
    8000381e:	854a                	mv	a0,s2
    80003820:	00000097          	auipc	ra,0x0
    80003824:	9fa080e7          	jalr	-1542(ra) # 8000321a <brelse>
      return iget(dev, inum);
    80003828:	85da                	mv	a1,s6
    8000382a:	8556                	mv	a0,s5
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	d9c080e7          	jalr	-612(ra) # 800035c8 <iget>
    80003834:	bf5d                	j	800037ea <ialloc+0x86>

0000000080003836 <iupdate>:
{
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	e426                	sd	s1,8(sp)
    8000383e:	e04a                	sd	s2,0(sp)
    80003840:	1000                	addi	s0,sp,32
    80003842:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003844:	415c                	lw	a5,4(a0)
    80003846:	0047d79b          	srliw	a5,a5,0x4
    8000384a:	0023d597          	auipc	a1,0x23d
    8000384e:	2765a583          	lw	a1,630(a1) # 80240ac0 <sb+0x18>
    80003852:	9dbd                	addw	a1,a1,a5
    80003854:	4108                	lw	a0,0(a0)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	894080e7          	jalr	-1900(ra) # 800030ea <bread>
    8000385e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003860:	05850793          	addi	a5,a0,88
    80003864:	40d8                	lw	a4,4(s1)
    80003866:	8b3d                	andi	a4,a4,15
    80003868:	071a                	slli	a4,a4,0x6
    8000386a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000386c:	04449703          	lh	a4,68(s1)
    80003870:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003874:	04649703          	lh	a4,70(s1)
    80003878:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000387c:	04849703          	lh	a4,72(s1)
    80003880:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003884:	04a49703          	lh	a4,74(s1)
    80003888:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000388c:	44f8                	lw	a4,76(s1)
    8000388e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003890:	03400613          	li	a2,52
    80003894:	05048593          	addi	a1,s1,80
    80003898:	00c78513          	addi	a0,a5,12
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	5c8080e7          	jalr	1480(ra) # 80000e64 <memmove>
  log_write(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	bfe080e7          	jalr	-1026(ra) # 800044a4 <log_write>
  brelse(bp);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	96a080e7          	jalr	-1686(ra) # 8000321a <brelse>
}
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6902                	ld	s2,0(sp)
    800038c0:	6105                	addi	sp,sp,32
    800038c2:	8082                	ret

00000000800038c4 <idup>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	1000                	addi	s0,sp,32
    800038ce:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d0:	0023d517          	auipc	a0,0x23d
    800038d4:	1f850513          	addi	a0,a0,504 # 80240ac8 <itable>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	434080e7          	jalr	1076(ra) # 80000d0c <acquire>
  ip->ref++;
    800038e0:	449c                	lw	a5,8(s1)
    800038e2:	2785                	addiw	a5,a5,1
    800038e4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038e6:	0023d517          	auipc	a0,0x23d
    800038ea:	1e250513          	addi	a0,a0,482 # 80240ac8 <itable>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	4d2080e7          	jalr	1234(ra) # 80000dc0 <release>
}
    800038f6:	8526                	mv	a0,s1
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <ilock>:
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000390e:	c115                	beqz	a0,80003932 <ilock+0x30>
    80003910:	84aa                	mv	s1,a0
    80003912:	451c                	lw	a5,8(a0)
    80003914:	00f05f63          	blez	a5,80003932 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003918:	0541                	addi	a0,a0,16
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	ca8080e7          	jalr	-856(ra) # 800045c2 <acquiresleep>
  if(ip->valid == 0){
    80003922:	40bc                	lw	a5,64(s1)
    80003924:	cf99                	beqz	a5,80003942 <ilock+0x40>
}
    80003926:	60e2                	ld	ra,24(sp)
    80003928:	6442                	ld	s0,16(sp)
    8000392a:	64a2                	ld	s1,8(sp)
    8000392c:	6902                	ld	s2,0(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret
    panic("ilock");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	e8e50513          	addi	a0,a0,-370 # 800087c0 <names+0x198>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c06080e7          	jalr	-1018(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003942:	40dc                	lw	a5,4(s1)
    80003944:	0047d79b          	srliw	a5,a5,0x4
    80003948:	0023d597          	auipc	a1,0x23d
    8000394c:	1785a583          	lw	a1,376(a1) # 80240ac0 <sb+0x18>
    80003950:	9dbd                	addw	a1,a1,a5
    80003952:	4088                	lw	a0,0(s1)
    80003954:	fffff097          	auipc	ra,0xfffff
    80003958:	796080e7          	jalr	1942(ra) # 800030ea <bread>
    8000395c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395e:	05850593          	addi	a1,a0,88
    80003962:	40dc                	lw	a5,4(s1)
    80003964:	8bbd                	andi	a5,a5,15
    80003966:	079a                	slli	a5,a5,0x6
    80003968:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000396a:	00059783          	lh	a5,0(a1)
    8000396e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003972:	00259783          	lh	a5,2(a1)
    80003976:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000397a:	00459783          	lh	a5,4(a1)
    8000397e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003982:	00659783          	lh	a5,6(a1)
    80003986:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000398a:	459c                	lw	a5,8(a1)
    8000398c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000398e:	03400613          	li	a2,52
    80003992:	05b1                	addi	a1,a1,12
    80003994:	05048513          	addi	a0,s1,80
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	4cc080e7          	jalr	1228(ra) # 80000e64 <memmove>
    brelse(bp);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	878080e7          	jalr	-1928(ra) # 8000321a <brelse>
    ip->valid = 1;
    800039aa:	4785                	li	a5,1
    800039ac:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ae:	04449783          	lh	a5,68(s1)
    800039b2:	fbb5                	bnez	a5,80003926 <ilock+0x24>
      panic("ilock: no type");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	e1450513          	addi	a0,a0,-492 # 800087c8 <names+0x1a0>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b84080e7          	jalr	-1148(ra) # 80000540 <panic>

00000000800039c4 <iunlock>:
{
    800039c4:	1101                	addi	sp,sp,-32
    800039c6:	ec06                	sd	ra,24(sp)
    800039c8:	e822                	sd	s0,16(sp)
    800039ca:	e426                	sd	s1,8(sp)
    800039cc:	e04a                	sd	s2,0(sp)
    800039ce:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039d0:	c905                	beqz	a0,80003a00 <iunlock+0x3c>
    800039d2:	84aa                	mv	s1,a0
    800039d4:	01050913          	addi	s2,a0,16
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	c82080e7          	jalr	-894(ra) # 8000465c <holdingsleep>
    800039e2:	cd19                	beqz	a0,80003a00 <iunlock+0x3c>
    800039e4:	449c                	lw	a5,8(s1)
    800039e6:	00f05d63          	blez	a5,80003a00 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039ea:	854a                	mv	a0,s2
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	c2c080e7          	jalr	-980(ra) # 80004618 <releasesleep>
}
    800039f4:	60e2                	ld	ra,24(sp)
    800039f6:	6442                	ld	s0,16(sp)
    800039f8:	64a2                	ld	s1,8(sp)
    800039fa:	6902                	ld	s2,0(sp)
    800039fc:	6105                	addi	sp,sp,32
    800039fe:	8082                	ret
    panic("iunlock");
    80003a00:	00005517          	auipc	a0,0x5
    80003a04:	dd850513          	addi	a0,a0,-552 # 800087d8 <names+0x1b0>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	b38080e7          	jalr	-1224(ra) # 80000540 <panic>

0000000080003a10 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a10:	7179                	addi	sp,sp,-48
    80003a12:	f406                	sd	ra,40(sp)
    80003a14:	f022                	sd	s0,32(sp)
    80003a16:	ec26                	sd	s1,24(sp)
    80003a18:	e84a                	sd	s2,16(sp)
    80003a1a:	e44e                	sd	s3,8(sp)
    80003a1c:	e052                	sd	s4,0(sp)
    80003a1e:	1800                	addi	s0,sp,48
    80003a20:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a22:	05050493          	addi	s1,a0,80
    80003a26:	08050913          	addi	s2,a0,128
    80003a2a:	a021                	j	80003a32 <itrunc+0x22>
    80003a2c:	0491                	addi	s1,s1,4
    80003a2e:	01248d63          	beq	s1,s2,80003a48 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a32:	408c                	lw	a1,0(s1)
    80003a34:	dde5                	beqz	a1,80003a2c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a36:	0009a503          	lw	a0,0(s3)
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	8f6080e7          	jalr	-1802(ra) # 80003330 <bfree>
      ip->addrs[i] = 0;
    80003a42:	0004a023          	sw	zero,0(s1)
    80003a46:	b7dd                	j	80003a2c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a48:	0809a583          	lw	a1,128(s3)
    80003a4c:	e185                	bnez	a1,80003a6c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a4e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a52:	854e                	mv	a0,s3
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	de2080e7          	jalr	-542(ra) # 80003836 <iupdate>
}
    80003a5c:	70a2                	ld	ra,40(sp)
    80003a5e:	7402                	ld	s0,32(sp)
    80003a60:	64e2                	ld	s1,24(sp)
    80003a62:	6942                	ld	s2,16(sp)
    80003a64:	69a2                	ld	s3,8(sp)
    80003a66:	6a02                	ld	s4,0(sp)
    80003a68:	6145                	addi	sp,sp,48
    80003a6a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a6c:	0009a503          	lw	a0,0(s3)
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	67a080e7          	jalr	1658(ra) # 800030ea <bread>
    80003a78:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a7a:	05850493          	addi	s1,a0,88
    80003a7e:	45850913          	addi	s2,a0,1112
    80003a82:	a021                	j	80003a8a <itrunc+0x7a>
    80003a84:	0491                	addi	s1,s1,4
    80003a86:	01248b63          	beq	s1,s2,80003a9c <itrunc+0x8c>
      if(a[j])
    80003a8a:	408c                	lw	a1,0(s1)
    80003a8c:	dde5                	beqz	a1,80003a84 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a8e:	0009a503          	lw	a0,0(s3)
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	89e080e7          	jalr	-1890(ra) # 80003330 <bfree>
    80003a9a:	b7ed                	j	80003a84 <itrunc+0x74>
    brelse(bp);
    80003a9c:	8552                	mv	a0,s4
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	77c080e7          	jalr	1916(ra) # 8000321a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aa6:	0809a583          	lw	a1,128(s3)
    80003aaa:	0009a503          	lw	a0,0(s3)
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	882080e7          	jalr	-1918(ra) # 80003330 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ab6:	0809a023          	sw	zero,128(s3)
    80003aba:	bf51                	j	80003a4e <itrunc+0x3e>

0000000080003abc <iput>:
{
    80003abc:	1101                	addi	sp,sp,-32
    80003abe:	ec06                	sd	ra,24(sp)
    80003ac0:	e822                	sd	s0,16(sp)
    80003ac2:	e426                	sd	s1,8(sp)
    80003ac4:	e04a                	sd	s2,0(sp)
    80003ac6:	1000                	addi	s0,sp,32
    80003ac8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aca:	0023d517          	auipc	a0,0x23d
    80003ace:	ffe50513          	addi	a0,a0,-2 # 80240ac8 <itable>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	23a080e7          	jalr	570(ra) # 80000d0c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ada:	4498                	lw	a4,8(s1)
    80003adc:	4785                	li	a5,1
    80003ade:	02f70363          	beq	a4,a5,80003b04 <iput+0x48>
  ip->ref--;
    80003ae2:	449c                	lw	a5,8(s1)
    80003ae4:	37fd                	addiw	a5,a5,-1
    80003ae6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ae8:	0023d517          	auipc	a0,0x23d
    80003aec:	fe050513          	addi	a0,a0,-32 # 80240ac8 <itable>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	2d0080e7          	jalr	720(ra) # 80000dc0 <release>
}
    80003af8:	60e2                	ld	ra,24(sp)
    80003afa:	6442                	ld	s0,16(sp)
    80003afc:	64a2                	ld	s1,8(sp)
    80003afe:	6902                	ld	s2,0(sp)
    80003b00:	6105                	addi	sp,sp,32
    80003b02:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b04:	40bc                	lw	a5,64(s1)
    80003b06:	dff1                	beqz	a5,80003ae2 <iput+0x26>
    80003b08:	04a49783          	lh	a5,74(s1)
    80003b0c:	fbf9                	bnez	a5,80003ae2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b0e:	01048913          	addi	s2,s1,16
    80003b12:	854a                	mv	a0,s2
    80003b14:	00001097          	auipc	ra,0x1
    80003b18:	aae080e7          	jalr	-1362(ra) # 800045c2 <acquiresleep>
    release(&itable.lock);
    80003b1c:	0023d517          	auipc	a0,0x23d
    80003b20:	fac50513          	addi	a0,a0,-84 # 80240ac8 <itable>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	29c080e7          	jalr	668(ra) # 80000dc0 <release>
    itrunc(ip);
    80003b2c:	8526                	mv	a0,s1
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	ee2080e7          	jalr	-286(ra) # 80003a10 <itrunc>
    ip->type = 0;
    80003b36:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b3a:	8526                	mv	a0,s1
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	cfa080e7          	jalr	-774(ra) # 80003836 <iupdate>
    ip->valid = 0;
    80003b44:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00001097          	auipc	ra,0x1
    80003b4e:	ace080e7          	jalr	-1330(ra) # 80004618 <releasesleep>
    acquire(&itable.lock);
    80003b52:	0023d517          	auipc	a0,0x23d
    80003b56:	f7650513          	addi	a0,a0,-138 # 80240ac8 <itable>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <acquire>
    80003b62:	b741                	j	80003ae2 <iput+0x26>

0000000080003b64 <iunlockput>:
{
    80003b64:	1101                	addi	sp,sp,-32
    80003b66:	ec06                	sd	ra,24(sp)
    80003b68:	e822                	sd	s0,16(sp)
    80003b6a:	e426                	sd	s1,8(sp)
    80003b6c:	1000                	addi	s0,sp,32
    80003b6e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	e54080e7          	jalr	-428(ra) # 800039c4 <iunlock>
  iput(ip);
    80003b78:	8526                	mv	a0,s1
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	f42080e7          	jalr	-190(ra) # 80003abc <iput>
}
    80003b82:	60e2                	ld	ra,24(sp)
    80003b84:	6442                	ld	s0,16(sp)
    80003b86:	64a2                	ld	s1,8(sp)
    80003b88:	6105                	addi	sp,sp,32
    80003b8a:	8082                	ret

0000000080003b8c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b8c:	1141                	addi	sp,sp,-16
    80003b8e:	e422                	sd	s0,8(sp)
    80003b90:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b92:	411c                	lw	a5,0(a0)
    80003b94:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b96:	415c                	lw	a5,4(a0)
    80003b98:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b9a:	04451783          	lh	a5,68(a0)
    80003b9e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ba2:	04a51783          	lh	a5,74(a0)
    80003ba6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003baa:	04c56783          	lwu	a5,76(a0)
    80003bae:	e99c                	sd	a5,16(a1)
}
    80003bb0:	6422                	ld	s0,8(sp)
    80003bb2:	0141                	addi	sp,sp,16
    80003bb4:	8082                	ret

0000000080003bb6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb6:	457c                	lw	a5,76(a0)
    80003bb8:	0ed7e963          	bltu	a5,a3,80003caa <readi+0xf4>
{
    80003bbc:	7159                	addi	sp,sp,-112
    80003bbe:	f486                	sd	ra,104(sp)
    80003bc0:	f0a2                	sd	s0,96(sp)
    80003bc2:	eca6                	sd	s1,88(sp)
    80003bc4:	e8ca                	sd	s2,80(sp)
    80003bc6:	e4ce                	sd	s3,72(sp)
    80003bc8:	e0d2                	sd	s4,64(sp)
    80003bca:	fc56                	sd	s5,56(sp)
    80003bcc:	f85a                	sd	s6,48(sp)
    80003bce:	f45e                	sd	s7,40(sp)
    80003bd0:	f062                	sd	s8,32(sp)
    80003bd2:	ec66                	sd	s9,24(sp)
    80003bd4:	e86a                	sd	s10,16(sp)
    80003bd6:	e46e                	sd	s11,8(sp)
    80003bd8:	1880                	addi	s0,sp,112
    80003bda:	8b2a                	mv	s6,a0
    80003bdc:	8bae                	mv	s7,a1
    80003bde:	8a32                	mv	s4,a2
    80003be0:	84b6                	mv	s1,a3
    80003be2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003be4:	9f35                	addw	a4,a4,a3
    return 0;
    80003be6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003be8:	0ad76063          	bltu	a4,a3,80003c88 <readi+0xd2>
  if(off + n > ip->size)
    80003bec:	00e7f463          	bgeu	a5,a4,80003bf4 <readi+0x3e>
    n = ip->size - off;
    80003bf0:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf4:	0a0a8963          	beqz	s5,80003ca6 <readi+0xf0>
    80003bf8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bfa:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bfe:	5c7d                	li	s8,-1
    80003c00:	a82d                	j	80003c3a <readi+0x84>
    80003c02:	020d1d93          	slli	s11,s10,0x20
    80003c06:	020ddd93          	srli	s11,s11,0x20
    80003c0a:	05890613          	addi	a2,s2,88
    80003c0e:	86ee                	mv	a3,s11
    80003c10:	963a                	add	a2,a2,a4
    80003c12:	85d2                	mv	a1,s4
    80003c14:	855e                	mv	a0,s7
    80003c16:	fffff097          	auipc	ra,0xfffff
    80003c1a:	996080e7          	jalr	-1642(ra) # 800025ac <either_copyout>
    80003c1e:	05850d63          	beq	a0,s8,80003c78 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c22:	854a                	mv	a0,s2
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	5f6080e7          	jalr	1526(ra) # 8000321a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2c:	013d09bb          	addw	s3,s10,s3
    80003c30:	009d04bb          	addw	s1,s10,s1
    80003c34:	9a6e                	add	s4,s4,s11
    80003c36:	0559f763          	bgeu	s3,s5,80003c84 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c3a:	00a4d59b          	srliw	a1,s1,0xa
    80003c3e:	855a                	mv	a0,s6
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	89e080e7          	jalr	-1890(ra) # 800034de <bmap>
    80003c48:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c4c:	cd85                	beqz	a1,80003c84 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c4e:	000b2503          	lw	a0,0(s6)
    80003c52:	fffff097          	auipc	ra,0xfffff
    80003c56:	498080e7          	jalr	1176(ra) # 800030ea <bread>
    80003c5a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5c:	3ff4f713          	andi	a4,s1,1023
    80003c60:	40ec87bb          	subw	a5,s9,a4
    80003c64:	413a86bb          	subw	a3,s5,s3
    80003c68:	8d3e                	mv	s10,a5
    80003c6a:	2781                	sext.w	a5,a5
    80003c6c:	0006861b          	sext.w	a2,a3
    80003c70:	f8f679e3          	bgeu	a2,a5,80003c02 <readi+0x4c>
    80003c74:	8d36                	mv	s10,a3
    80003c76:	b771                	j	80003c02 <readi+0x4c>
      brelse(bp);
    80003c78:	854a                	mv	a0,s2
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	5a0080e7          	jalr	1440(ra) # 8000321a <brelse>
      tot = -1;
    80003c82:	59fd                	li	s3,-1
  }
  return tot;
    80003c84:	0009851b          	sext.w	a0,s3
}
    80003c88:	70a6                	ld	ra,104(sp)
    80003c8a:	7406                	ld	s0,96(sp)
    80003c8c:	64e6                	ld	s1,88(sp)
    80003c8e:	6946                	ld	s2,80(sp)
    80003c90:	69a6                	ld	s3,72(sp)
    80003c92:	6a06                	ld	s4,64(sp)
    80003c94:	7ae2                	ld	s5,56(sp)
    80003c96:	7b42                	ld	s6,48(sp)
    80003c98:	7ba2                	ld	s7,40(sp)
    80003c9a:	7c02                	ld	s8,32(sp)
    80003c9c:	6ce2                	ld	s9,24(sp)
    80003c9e:	6d42                	ld	s10,16(sp)
    80003ca0:	6da2                	ld	s11,8(sp)
    80003ca2:	6165                	addi	sp,sp,112
    80003ca4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca6:	89d6                	mv	s3,s5
    80003ca8:	bff1                	j	80003c84 <readi+0xce>
    return 0;
    80003caa:	4501                	li	a0,0
}
    80003cac:	8082                	ret

0000000080003cae <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cae:	457c                	lw	a5,76(a0)
    80003cb0:	10d7e863          	bltu	a5,a3,80003dc0 <writei+0x112>
{
    80003cb4:	7159                	addi	sp,sp,-112
    80003cb6:	f486                	sd	ra,104(sp)
    80003cb8:	f0a2                	sd	s0,96(sp)
    80003cba:	eca6                	sd	s1,88(sp)
    80003cbc:	e8ca                	sd	s2,80(sp)
    80003cbe:	e4ce                	sd	s3,72(sp)
    80003cc0:	e0d2                	sd	s4,64(sp)
    80003cc2:	fc56                	sd	s5,56(sp)
    80003cc4:	f85a                	sd	s6,48(sp)
    80003cc6:	f45e                	sd	s7,40(sp)
    80003cc8:	f062                	sd	s8,32(sp)
    80003cca:	ec66                	sd	s9,24(sp)
    80003ccc:	e86a                	sd	s10,16(sp)
    80003cce:	e46e                	sd	s11,8(sp)
    80003cd0:	1880                	addi	s0,sp,112
    80003cd2:	8aaa                	mv	s5,a0
    80003cd4:	8bae                	mv	s7,a1
    80003cd6:	8a32                	mv	s4,a2
    80003cd8:	8936                	mv	s2,a3
    80003cda:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cdc:	00e687bb          	addw	a5,a3,a4
    80003ce0:	0ed7e263          	bltu	a5,a3,80003dc4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ce4:	00043737          	lui	a4,0x43
    80003ce8:	0ef76063          	bltu	a4,a5,80003dc8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cec:	0c0b0863          	beqz	s6,80003dbc <writei+0x10e>
    80003cf0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cf6:	5c7d                	li	s8,-1
    80003cf8:	a091                	j	80003d3c <writei+0x8e>
    80003cfa:	020d1d93          	slli	s11,s10,0x20
    80003cfe:	020ddd93          	srli	s11,s11,0x20
    80003d02:	05848513          	addi	a0,s1,88
    80003d06:	86ee                	mv	a3,s11
    80003d08:	8652                	mv	a2,s4
    80003d0a:	85de                	mv	a1,s7
    80003d0c:	953a                	add	a0,a0,a4
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	8f4080e7          	jalr	-1804(ra) # 80002602 <either_copyin>
    80003d16:	07850263          	beq	a0,s8,80003d7a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d1a:	8526                	mv	a0,s1
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	788080e7          	jalr	1928(ra) # 800044a4 <log_write>
    brelse(bp);
    80003d24:	8526                	mv	a0,s1
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	4f4080e7          	jalr	1268(ra) # 8000321a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d2e:	013d09bb          	addw	s3,s10,s3
    80003d32:	012d093b          	addw	s2,s10,s2
    80003d36:	9a6e                	add	s4,s4,s11
    80003d38:	0569f663          	bgeu	s3,s6,80003d84 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d3c:	00a9559b          	srliw	a1,s2,0xa
    80003d40:	8556                	mv	a0,s5
    80003d42:	fffff097          	auipc	ra,0xfffff
    80003d46:	79c080e7          	jalr	1948(ra) # 800034de <bmap>
    80003d4a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d4e:	c99d                	beqz	a1,80003d84 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d50:	000aa503          	lw	a0,0(s5)
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	396080e7          	jalr	918(ra) # 800030ea <bread>
    80003d5c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5e:	3ff97713          	andi	a4,s2,1023
    80003d62:	40ec87bb          	subw	a5,s9,a4
    80003d66:	413b06bb          	subw	a3,s6,s3
    80003d6a:	8d3e                	mv	s10,a5
    80003d6c:	2781                	sext.w	a5,a5
    80003d6e:	0006861b          	sext.w	a2,a3
    80003d72:	f8f674e3          	bgeu	a2,a5,80003cfa <writei+0x4c>
    80003d76:	8d36                	mv	s10,a3
    80003d78:	b749                	j	80003cfa <writei+0x4c>
      brelse(bp);
    80003d7a:	8526                	mv	a0,s1
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	49e080e7          	jalr	1182(ra) # 8000321a <brelse>
  }

  if(off > ip->size)
    80003d84:	04caa783          	lw	a5,76(s5)
    80003d88:	0127f463          	bgeu	a5,s2,80003d90 <writei+0xe2>
    ip->size = off;
    80003d8c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d90:	8556                	mv	a0,s5
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	aa4080e7          	jalr	-1372(ra) # 80003836 <iupdate>

  return tot;
    80003d9a:	0009851b          	sext.w	a0,s3
}
    80003d9e:	70a6                	ld	ra,104(sp)
    80003da0:	7406                	ld	s0,96(sp)
    80003da2:	64e6                	ld	s1,88(sp)
    80003da4:	6946                	ld	s2,80(sp)
    80003da6:	69a6                	ld	s3,72(sp)
    80003da8:	6a06                	ld	s4,64(sp)
    80003daa:	7ae2                	ld	s5,56(sp)
    80003dac:	7b42                	ld	s6,48(sp)
    80003dae:	7ba2                	ld	s7,40(sp)
    80003db0:	7c02                	ld	s8,32(sp)
    80003db2:	6ce2                	ld	s9,24(sp)
    80003db4:	6d42                	ld	s10,16(sp)
    80003db6:	6da2                	ld	s11,8(sp)
    80003db8:	6165                	addi	sp,sp,112
    80003dba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dbc:	89da                	mv	s3,s6
    80003dbe:	bfc9                	j	80003d90 <writei+0xe2>
    return -1;
    80003dc0:	557d                	li	a0,-1
}
    80003dc2:	8082                	ret
    return -1;
    80003dc4:	557d                	li	a0,-1
    80003dc6:	bfe1                	j	80003d9e <writei+0xf0>
    return -1;
    80003dc8:	557d                	li	a0,-1
    80003dca:	bfd1                	j	80003d9e <writei+0xf0>

0000000080003dcc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dcc:	1141                	addi	sp,sp,-16
    80003dce:	e406                	sd	ra,8(sp)
    80003dd0:	e022                	sd	s0,0(sp)
    80003dd2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dd4:	4639                	li	a2,14
    80003dd6:	ffffd097          	auipc	ra,0xffffd
    80003dda:	102080e7          	jalr	258(ra) # 80000ed8 <strncmp>
}
    80003dde:	60a2                	ld	ra,8(sp)
    80003de0:	6402                	ld	s0,0(sp)
    80003de2:	0141                	addi	sp,sp,16
    80003de4:	8082                	ret

0000000080003de6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003de6:	7139                	addi	sp,sp,-64
    80003de8:	fc06                	sd	ra,56(sp)
    80003dea:	f822                	sd	s0,48(sp)
    80003dec:	f426                	sd	s1,40(sp)
    80003dee:	f04a                	sd	s2,32(sp)
    80003df0:	ec4e                	sd	s3,24(sp)
    80003df2:	e852                	sd	s4,16(sp)
    80003df4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003df6:	04451703          	lh	a4,68(a0)
    80003dfa:	4785                	li	a5,1
    80003dfc:	00f71a63          	bne	a4,a5,80003e10 <dirlookup+0x2a>
    80003e00:	892a                	mv	s2,a0
    80003e02:	89ae                	mv	s3,a1
    80003e04:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e06:	457c                	lw	a5,76(a0)
    80003e08:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e0a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0c:	e79d                	bnez	a5,80003e3a <dirlookup+0x54>
    80003e0e:	a8a5                	j	80003e86 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e10:	00005517          	auipc	a0,0x5
    80003e14:	9d050513          	addi	a0,a0,-1584 # 800087e0 <names+0x1b8>
    80003e18:	ffffc097          	auipc	ra,0xffffc
    80003e1c:	728080e7          	jalr	1832(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e20:	00005517          	auipc	a0,0x5
    80003e24:	9d850513          	addi	a0,a0,-1576 # 800087f8 <names+0x1d0>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	718080e7          	jalr	1816(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e30:	24c1                	addiw	s1,s1,16
    80003e32:	04c92783          	lw	a5,76(s2)
    80003e36:	04f4f763          	bgeu	s1,a5,80003e84 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e3a:	4741                	li	a4,16
    80003e3c:	86a6                	mv	a3,s1
    80003e3e:	fc040613          	addi	a2,s0,-64
    80003e42:	4581                	li	a1,0
    80003e44:	854a                	mv	a0,s2
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	d70080e7          	jalr	-656(ra) # 80003bb6 <readi>
    80003e4e:	47c1                	li	a5,16
    80003e50:	fcf518e3          	bne	a0,a5,80003e20 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e54:	fc045783          	lhu	a5,-64(s0)
    80003e58:	dfe1                	beqz	a5,80003e30 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e5a:	fc240593          	addi	a1,s0,-62
    80003e5e:	854e                	mv	a0,s3
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	f6c080e7          	jalr	-148(ra) # 80003dcc <namecmp>
    80003e68:	f561                	bnez	a0,80003e30 <dirlookup+0x4a>
      if(poff)
    80003e6a:	000a0463          	beqz	s4,80003e72 <dirlookup+0x8c>
        *poff = off;
    80003e6e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e72:	fc045583          	lhu	a1,-64(s0)
    80003e76:	00092503          	lw	a0,0(s2)
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	74e080e7          	jalr	1870(ra) # 800035c8 <iget>
    80003e82:	a011                	j	80003e86 <dirlookup+0xa0>
  return 0;
    80003e84:	4501                	li	a0,0
}
    80003e86:	70e2                	ld	ra,56(sp)
    80003e88:	7442                	ld	s0,48(sp)
    80003e8a:	74a2                	ld	s1,40(sp)
    80003e8c:	7902                	ld	s2,32(sp)
    80003e8e:	69e2                	ld	s3,24(sp)
    80003e90:	6a42                	ld	s4,16(sp)
    80003e92:	6121                	addi	sp,sp,64
    80003e94:	8082                	ret

0000000080003e96 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e96:	711d                	addi	sp,sp,-96
    80003e98:	ec86                	sd	ra,88(sp)
    80003e9a:	e8a2                	sd	s0,80(sp)
    80003e9c:	e4a6                	sd	s1,72(sp)
    80003e9e:	e0ca                	sd	s2,64(sp)
    80003ea0:	fc4e                	sd	s3,56(sp)
    80003ea2:	f852                	sd	s4,48(sp)
    80003ea4:	f456                	sd	s5,40(sp)
    80003ea6:	f05a                	sd	s6,32(sp)
    80003ea8:	ec5e                	sd	s7,24(sp)
    80003eaa:	e862                	sd	s8,16(sp)
    80003eac:	e466                	sd	s9,8(sp)
    80003eae:	e06a                	sd	s10,0(sp)
    80003eb0:	1080                	addi	s0,sp,96
    80003eb2:	84aa                	mv	s1,a0
    80003eb4:	8b2e                	mv	s6,a1
    80003eb6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eb8:	00054703          	lbu	a4,0(a0)
    80003ebc:	02f00793          	li	a5,47
    80003ec0:	02f70363          	beq	a4,a5,80003ee6 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ec4:	ffffe097          	auipc	ra,0xffffe
    80003ec8:	c38080e7          	jalr	-968(ra) # 80001afc <myproc>
    80003ecc:	15053503          	ld	a0,336(a0)
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	9f4080e7          	jalr	-1548(ra) # 800038c4 <idup>
    80003ed8:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003eda:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003ede:	4cb5                	li	s9,13
  len = path - s;
    80003ee0:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ee2:	4c05                	li	s8,1
    80003ee4:	a87d                	j	80003fa2 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003ee6:	4585                	li	a1,1
    80003ee8:	4505                	li	a0,1
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	6de080e7          	jalr	1758(ra) # 800035c8 <iget>
    80003ef2:	8a2a                	mv	s4,a0
    80003ef4:	b7dd                	j	80003eda <namex+0x44>
      iunlockput(ip);
    80003ef6:	8552                	mv	a0,s4
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	c6c080e7          	jalr	-916(ra) # 80003b64 <iunlockput>
      return 0;
    80003f00:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f02:	8552                	mv	a0,s4
    80003f04:	60e6                	ld	ra,88(sp)
    80003f06:	6446                	ld	s0,80(sp)
    80003f08:	64a6                	ld	s1,72(sp)
    80003f0a:	6906                	ld	s2,64(sp)
    80003f0c:	79e2                	ld	s3,56(sp)
    80003f0e:	7a42                	ld	s4,48(sp)
    80003f10:	7aa2                	ld	s5,40(sp)
    80003f12:	7b02                	ld	s6,32(sp)
    80003f14:	6be2                	ld	s7,24(sp)
    80003f16:	6c42                	ld	s8,16(sp)
    80003f18:	6ca2                	ld	s9,8(sp)
    80003f1a:	6d02                	ld	s10,0(sp)
    80003f1c:	6125                	addi	sp,sp,96
    80003f1e:	8082                	ret
      iunlock(ip);
    80003f20:	8552                	mv	a0,s4
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	aa2080e7          	jalr	-1374(ra) # 800039c4 <iunlock>
      return ip;
    80003f2a:	bfe1                	j	80003f02 <namex+0x6c>
      iunlockput(ip);
    80003f2c:	8552                	mv	a0,s4
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	c36080e7          	jalr	-970(ra) # 80003b64 <iunlockput>
      return 0;
    80003f36:	8a4e                	mv	s4,s3
    80003f38:	b7e9                	j	80003f02 <namex+0x6c>
  len = path - s;
    80003f3a:	40998633          	sub	a2,s3,s1
    80003f3e:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003f42:	09acd863          	bge	s9,s10,80003fd2 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003f46:	4639                	li	a2,14
    80003f48:	85a6                	mv	a1,s1
    80003f4a:	8556                	mv	a0,s5
    80003f4c:	ffffd097          	auipc	ra,0xffffd
    80003f50:	f18080e7          	jalr	-232(ra) # 80000e64 <memmove>
    80003f54:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f56:	0004c783          	lbu	a5,0(s1)
    80003f5a:	01279763          	bne	a5,s2,80003f68 <namex+0xd2>
    path++;
    80003f5e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f60:	0004c783          	lbu	a5,0(s1)
    80003f64:	ff278de3          	beq	a5,s2,80003f5e <namex+0xc8>
    ilock(ip);
    80003f68:	8552                	mv	a0,s4
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	998080e7          	jalr	-1640(ra) # 80003902 <ilock>
    if(ip->type != T_DIR){
    80003f72:	044a1783          	lh	a5,68(s4)
    80003f76:	f98790e3          	bne	a5,s8,80003ef6 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003f7a:	000b0563          	beqz	s6,80003f84 <namex+0xee>
    80003f7e:	0004c783          	lbu	a5,0(s1)
    80003f82:	dfd9                	beqz	a5,80003f20 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f84:	865e                	mv	a2,s7
    80003f86:	85d6                	mv	a1,s5
    80003f88:	8552                	mv	a0,s4
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	e5c080e7          	jalr	-420(ra) # 80003de6 <dirlookup>
    80003f92:	89aa                	mv	s3,a0
    80003f94:	dd41                	beqz	a0,80003f2c <namex+0x96>
    iunlockput(ip);
    80003f96:	8552                	mv	a0,s4
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	bcc080e7          	jalr	-1076(ra) # 80003b64 <iunlockput>
    ip = next;
    80003fa0:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	01279763          	bne	a5,s2,80003fb4 <namex+0x11e>
    path++;
    80003faa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	ff278de3          	beq	a5,s2,80003faa <namex+0x114>
  if(*path == 0)
    80003fb4:	cb9d                	beqz	a5,80003fea <namex+0x154>
  while(*path != '/' && *path != 0)
    80003fb6:	0004c783          	lbu	a5,0(s1)
    80003fba:	89a6                	mv	s3,s1
  len = path - s;
    80003fbc:	8d5e                	mv	s10,s7
    80003fbe:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fc0:	01278963          	beq	a5,s2,80003fd2 <namex+0x13c>
    80003fc4:	dbbd                	beqz	a5,80003f3a <namex+0xa4>
    path++;
    80003fc6:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003fc8:	0009c783          	lbu	a5,0(s3)
    80003fcc:	ff279ce3          	bne	a5,s2,80003fc4 <namex+0x12e>
    80003fd0:	b7ad                	j	80003f3a <namex+0xa4>
    memmove(name, s, len);
    80003fd2:	2601                	sext.w	a2,a2
    80003fd4:	85a6                	mv	a1,s1
    80003fd6:	8556                	mv	a0,s5
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	e8c080e7          	jalr	-372(ra) # 80000e64 <memmove>
    name[len] = 0;
    80003fe0:	9d56                	add	s10,s10,s5
    80003fe2:	000d0023          	sb	zero,0(s10)
    80003fe6:	84ce                	mv	s1,s3
    80003fe8:	b7bd                	j	80003f56 <namex+0xc0>
  if(nameiparent){
    80003fea:	f00b0ce3          	beqz	s6,80003f02 <namex+0x6c>
    iput(ip);
    80003fee:	8552                	mv	a0,s4
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	acc080e7          	jalr	-1332(ra) # 80003abc <iput>
    return 0;
    80003ff8:	4a01                	li	s4,0
    80003ffa:	b721                	j	80003f02 <namex+0x6c>

0000000080003ffc <dirlink>:
{
    80003ffc:	7139                	addi	sp,sp,-64
    80003ffe:	fc06                	sd	ra,56(sp)
    80004000:	f822                	sd	s0,48(sp)
    80004002:	f426                	sd	s1,40(sp)
    80004004:	f04a                	sd	s2,32(sp)
    80004006:	ec4e                	sd	s3,24(sp)
    80004008:	e852                	sd	s4,16(sp)
    8000400a:	0080                	addi	s0,sp,64
    8000400c:	892a                	mv	s2,a0
    8000400e:	8a2e                	mv	s4,a1
    80004010:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004012:	4601                	li	a2,0
    80004014:	00000097          	auipc	ra,0x0
    80004018:	dd2080e7          	jalr	-558(ra) # 80003de6 <dirlookup>
    8000401c:	e93d                	bnez	a0,80004092 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401e:	04c92483          	lw	s1,76(s2)
    80004022:	c49d                	beqz	s1,80004050 <dirlink+0x54>
    80004024:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004026:	4741                	li	a4,16
    80004028:	86a6                	mv	a3,s1
    8000402a:	fc040613          	addi	a2,s0,-64
    8000402e:	4581                	li	a1,0
    80004030:	854a                	mv	a0,s2
    80004032:	00000097          	auipc	ra,0x0
    80004036:	b84080e7          	jalr	-1148(ra) # 80003bb6 <readi>
    8000403a:	47c1                	li	a5,16
    8000403c:	06f51163          	bne	a0,a5,8000409e <dirlink+0xa2>
    if(de.inum == 0)
    80004040:	fc045783          	lhu	a5,-64(s0)
    80004044:	c791                	beqz	a5,80004050 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004046:	24c1                	addiw	s1,s1,16
    80004048:	04c92783          	lw	a5,76(s2)
    8000404c:	fcf4ede3          	bltu	s1,a5,80004026 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004050:	4639                	li	a2,14
    80004052:	85d2                	mv	a1,s4
    80004054:	fc240513          	addi	a0,s0,-62
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	ebc080e7          	jalr	-324(ra) # 80000f14 <strncpy>
  de.inum = inum;
    80004060:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004064:	4741                	li	a4,16
    80004066:	86a6                	mv	a3,s1
    80004068:	fc040613          	addi	a2,s0,-64
    8000406c:	4581                	li	a1,0
    8000406e:	854a                	mv	a0,s2
    80004070:	00000097          	auipc	ra,0x0
    80004074:	c3e080e7          	jalr	-962(ra) # 80003cae <writei>
    80004078:	1541                	addi	a0,a0,-16
    8000407a:	00a03533          	snez	a0,a0
    8000407e:	40a00533          	neg	a0,a0
}
    80004082:	70e2                	ld	ra,56(sp)
    80004084:	7442                	ld	s0,48(sp)
    80004086:	74a2                	ld	s1,40(sp)
    80004088:	7902                	ld	s2,32(sp)
    8000408a:	69e2                	ld	s3,24(sp)
    8000408c:	6a42                	ld	s4,16(sp)
    8000408e:	6121                	addi	sp,sp,64
    80004090:	8082                	ret
    iput(ip);
    80004092:	00000097          	auipc	ra,0x0
    80004096:	a2a080e7          	jalr	-1494(ra) # 80003abc <iput>
    return -1;
    8000409a:	557d                	li	a0,-1
    8000409c:	b7dd                	j	80004082 <dirlink+0x86>
      panic("dirlink read");
    8000409e:	00004517          	auipc	a0,0x4
    800040a2:	76a50513          	addi	a0,a0,1898 # 80008808 <names+0x1e0>
    800040a6:	ffffc097          	auipc	ra,0xffffc
    800040aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>

00000000800040ae <namei>:

struct inode*
namei(char *path)
{
    800040ae:	1101                	addi	sp,sp,-32
    800040b0:	ec06                	sd	ra,24(sp)
    800040b2:	e822                	sd	s0,16(sp)
    800040b4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040b6:	fe040613          	addi	a2,s0,-32
    800040ba:	4581                	li	a1,0
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	dda080e7          	jalr	-550(ra) # 80003e96 <namex>
}
    800040c4:	60e2                	ld	ra,24(sp)
    800040c6:	6442                	ld	s0,16(sp)
    800040c8:	6105                	addi	sp,sp,32
    800040ca:	8082                	ret

00000000800040cc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040cc:	1141                	addi	sp,sp,-16
    800040ce:	e406                	sd	ra,8(sp)
    800040d0:	e022                	sd	s0,0(sp)
    800040d2:	0800                	addi	s0,sp,16
    800040d4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040d6:	4585                	li	a1,1
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	dbe080e7          	jalr	-578(ra) # 80003e96 <namex>
}
    800040e0:	60a2                	ld	ra,8(sp)
    800040e2:	6402                	ld	s0,0(sp)
    800040e4:	0141                	addi	sp,sp,16
    800040e6:	8082                	ret

00000000800040e8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040e8:	1101                	addi	sp,sp,-32
    800040ea:	ec06                	sd	ra,24(sp)
    800040ec:	e822                	sd	s0,16(sp)
    800040ee:	e426                	sd	s1,8(sp)
    800040f0:	e04a                	sd	s2,0(sp)
    800040f2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040f4:	0023e917          	auipc	s2,0x23e
    800040f8:	47c90913          	addi	s2,s2,1148 # 80242570 <log>
    800040fc:	01892583          	lw	a1,24(s2)
    80004100:	02892503          	lw	a0,40(s2)
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	fe6080e7          	jalr	-26(ra) # 800030ea <bread>
    8000410c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000410e:	02c92683          	lw	a3,44(s2)
    80004112:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004114:	02d05863          	blez	a3,80004144 <write_head+0x5c>
    80004118:	0023e797          	auipc	a5,0x23e
    8000411c:	48878793          	addi	a5,a5,1160 # 802425a0 <log+0x30>
    80004120:	05c50713          	addi	a4,a0,92
    80004124:	36fd                	addiw	a3,a3,-1
    80004126:	02069613          	slli	a2,a3,0x20
    8000412a:	01e65693          	srli	a3,a2,0x1e
    8000412e:	0023e617          	auipc	a2,0x23e
    80004132:	47660613          	addi	a2,a2,1142 # 802425a4 <log+0x34>
    80004136:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004138:	4390                	lw	a2,0(a5)
    8000413a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000413c:	0791                	addi	a5,a5,4
    8000413e:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004140:	fed79ce3          	bne	a5,a3,80004138 <write_head+0x50>
  }
  bwrite(buf);
    80004144:	8526                	mv	a0,s1
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	096080e7          	jalr	150(ra) # 800031dc <bwrite>
  brelse(buf);
    8000414e:	8526                	mv	a0,s1
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	0ca080e7          	jalr	202(ra) # 8000321a <brelse>
}
    80004158:	60e2                	ld	ra,24(sp)
    8000415a:	6442                	ld	s0,16(sp)
    8000415c:	64a2                	ld	s1,8(sp)
    8000415e:	6902                	ld	s2,0(sp)
    80004160:	6105                	addi	sp,sp,32
    80004162:	8082                	ret

0000000080004164 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004164:	0023e797          	auipc	a5,0x23e
    80004168:	4387a783          	lw	a5,1080(a5) # 8024259c <log+0x2c>
    8000416c:	0af05d63          	blez	a5,80004226 <install_trans+0xc2>
{
    80004170:	7139                	addi	sp,sp,-64
    80004172:	fc06                	sd	ra,56(sp)
    80004174:	f822                	sd	s0,48(sp)
    80004176:	f426                	sd	s1,40(sp)
    80004178:	f04a                	sd	s2,32(sp)
    8000417a:	ec4e                	sd	s3,24(sp)
    8000417c:	e852                	sd	s4,16(sp)
    8000417e:	e456                	sd	s5,8(sp)
    80004180:	e05a                	sd	s6,0(sp)
    80004182:	0080                	addi	s0,sp,64
    80004184:	8b2a                	mv	s6,a0
    80004186:	0023ea97          	auipc	s5,0x23e
    8000418a:	41aa8a93          	addi	s5,s5,1050 # 802425a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004190:	0023e997          	auipc	s3,0x23e
    80004194:	3e098993          	addi	s3,s3,992 # 80242570 <log>
    80004198:	a00d                	j	800041ba <install_trans+0x56>
    brelse(lbuf);
    8000419a:	854a                	mv	a0,s2
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	07e080e7          	jalr	126(ra) # 8000321a <brelse>
    brelse(dbuf);
    800041a4:	8526                	mv	a0,s1
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	074080e7          	jalr	116(ra) # 8000321a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ae:	2a05                	addiw	s4,s4,1
    800041b0:	0a91                	addi	s5,s5,4
    800041b2:	02c9a783          	lw	a5,44(s3)
    800041b6:	04fa5e63          	bge	s4,a5,80004212 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ba:	0189a583          	lw	a1,24(s3)
    800041be:	014585bb          	addw	a1,a1,s4
    800041c2:	2585                	addiw	a1,a1,1
    800041c4:	0289a503          	lw	a0,40(s3)
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	f22080e7          	jalr	-222(ra) # 800030ea <bread>
    800041d0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041d2:	000aa583          	lw	a1,0(s5)
    800041d6:	0289a503          	lw	a0,40(s3)
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	f10080e7          	jalr	-240(ra) # 800030ea <bread>
    800041e2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041e4:	40000613          	li	a2,1024
    800041e8:	05890593          	addi	a1,s2,88
    800041ec:	05850513          	addi	a0,a0,88
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	c74080e7          	jalr	-908(ra) # 80000e64 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041f8:	8526                	mv	a0,s1
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	fe2080e7          	jalr	-30(ra) # 800031dc <bwrite>
    if(recovering == 0)
    80004202:	f80b1ce3          	bnez	s6,8000419a <install_trans+0x36>
      bunpin(dbuf);
    80004206:	8526                	mv	a0,s1
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	0ec080e7          	jalr	236(ra) # 800032f4 <bunpin>
    80004210:	b769                	j	8000419a <install_trans+0x36>
}
    80004212:	70e2                	ld	ra,56(sp)
    80004214:	7442                	ld	s0,48(sp)
    80004216:	74a2                	ld	s1,40(sp)
    80004218:	7902                	ld	s2,32(sp)
    8000421a:	69e2                	ld	s3,24(sp)
    8000421c:	6a42                	ld	s4,16(sp)
    8000421e:	6aa2                	ld	s5,8(sp)
    80004220:	6b02                	ld	s6,0(sp)
    80004222:	6121                	addi	sp,sp,64
    80004224:	8082                	ret
    80004226:	8082                	ret

0000000080004228 <initlog>:
{
    80004228:	7179                	addi	sp,sp,-48
    8000422a:	f406                	sd	ra,40(sp)
    8000422c:	f022                	sd	s0,32(sp)
    8000422e:	ec26                	sd	s1,24(sp)
    80004230:	e84a                	sd	s2,16(sp)
    80004232:	e44e                	sd	s3,8(sp)
    80004234:	1800                	addi	s0,sp,48
    80004236:	892a                	mv	s2,a0
    80004238:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000423a:	0023e497          	auipc	s1,0x23e
    8000423e:	33648493          	addi	s1,s1,822 # 80242570 <log>
    80004242:	00004597          	auipc	a1,0x4
    80004246:	5d658593          	addi	a1,a1,1494 # 80008818 <names+0x1f0>
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	a30080e7          	jalr	-1488(ra) # 80000c7c <initlock>
  log.start = sb->logstart;
    80004254:	0149a583          	lw	a1,20(s3)
    80004258:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000425a:	0109a783          	lw	a5,16(s3)
    8000425e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004260:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004264:	854a                	mv	a0,s2
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	e84080e7          	jalr	-380(ra) # 800030ea <bread>
  log.lh.n = lh->n;
    8000426e:	4d34                	lw	a3,88(a0)
    80004270:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004272:	02d05663          	blez	a3,8000429e <initlog+0x76>
    80004276:	05c50793          	addi	a5,a0,92
    8000427a:	0023e717          	auipc	a4,0x23e
    8000427e:	32670713          	addi	a4,a4,806 # 802425a0 <log+0x30>
    80004282:	36fd                	addiw	a3,a3,-1
    80004284:	02069613          	slli	a2,a3,0x20
    80004288:	01e65693          	srli	a3,a2,0x1e
    8000428c:	06050613          	addi	a2,a0,96
    80004290:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004292:	4390                	lw	a2,0(a5)
    80004294:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004296:	0791                	addi	a5,a5,4
    80004298:	0711                	addi	a4,a4,4
    8000429a:	fed79ce3          	bne	a5,a3,80004292 <initlog+0x6a>
  brelse(buf);
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	f7c080e7          	jalr	-132(ra) # 8000321a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042a6:	4505                	li	a0,1
    800042a8:	00000097          	auipc	ra,0x0
    800042ac:	ebc080e7          	jalr	-324(ra) # 80004164 <install_trans>
  log.lh.n = 0;
    800042b0:	0023e797          	auipc	a5,0x23e
    800042b4:	2e07a623          	sw	zero,748(a5) # 8024259c <log+0x2c>
  write_head(); // clear the log
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	e30080e7          	jalr	-464(ra) # 800040e8 <write_head>
}
    800042c0:	70a2                	ld	ra,40(sp)
    800042c2:	7402                	ld	s0,32(sp)
    800042c4:	64e2                	ld	s1,24(sp)
    800042c6:	6942                	ld	s2,16(sp)
    800042c8:	69a2                	ld	s3,8(sp)
    800042ca:	6145                	addi	sp,sp,48
    800042cc:	8082                	ret

00000000800042ce <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042ce:	1101                	addi	sp,sp,-32
    800042d0:	ec06                	sd	ra,24(sp)
    800042d2:	e822                	sd	s0,16(sp)
    800042d4:	e426                	sd	s1,8(sp)
    800042d6:	e04a                	sd	s2,0(sp)
    800042d8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042da:	0023e517          	auipc	a0,0x23e
    800042de:	29650513          	addi	a0,a0,662 # 80242570 <log>
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	a2a080e7          	jalr	-1494(ra) # 80000d0c <acquire>
  while(1){
    if(log.committing){
    800042ea:	0023e497          	auipc	s1,0x23e
    800042ee:	28648493          	addi	s1,s1,646 # 80242570 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f2:	4979                	li	s2,30
    800042f4:	a039                	j	80004302 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042f6:	85a6                	mv	a1,s1
    800042f8:	8526                	mv	a0,s1
    800042fa:	ffffe097          	auipc	ra,0xffffe
    800042fe:	eaa080e7          	jalr	-342(ra) # 800021a4 <sleep>
    if(log.committing){
    80004302:	50dc                	lw	a5,36(s1)
    80004304:	fbed                	bnez	a5,800042f6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004306:	5098                	lw	a4,32(s1)
    80004308:	2705                	addiw	a4,a4,1
    8000430a:	0007069b          	sext.w	a3,a4
    8000430e:	0027179b          	slliw	a5,a4,0x2
    80004312:	9fb9                	addw	a5,a5,a4
    80004314:	0017979b          	slliw	a5,a5,0x1
    80004318:	54d8                	lw	a4,44(s1)
    8000431a:	9fb9                	addw	a5,a5,a4
    8000431c:	00f95963          	bge	s2,a5,8000432e <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004320:	85a6                	mv	a1,s1
    80004322:	8526                	mv	a0,s1
    80004324:	ffffe097          	auipc	ra,0xffffe
    80004328:	e80080e7          	jalr	-384(ra) # 800021a4 <sleep>
    8000432c:	bfd9                	j	80004302 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000432e:	0023e517          	auipc	a0,0x23e
    80004332:	24250513          	addi	a0,a0,578 # 80242570 <log>
    80004336:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	a88080e7          	jalr	-1400(ra) # 80000dc0 <release>
      break;
    }
  }
}
    80004340:	60e2                	ld	ra,24(sp)
    80004342:	6442                	ld	s0,16(sp)
    80004344:	64a2                	ld	s1,8(sp)
    80004346:	6902                	ld	s2,0(sp)
    80004348:	6105                	addi	sp,sp,32
    8000434a:	8082                	ret

000000008000434c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000434c:	7139                	addi	sp,sp,-64
    8000434e:	fc06                	sd	ra,56(sp)
    80004350:	f822                	sd	s0,48(sp)
    80004352:	f426                	sd	s1,40(sp)
    80004354:	f04a                	sd	s2,32(sp)
    80004356:	ec4e                	sd	s3,24(sp)
    80004358:	e852                	sd	s4,16(sp)
    8000435a:	e456                	sd	s5,8(sp)
    8000435c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000435e:	0023e497          	auipc	s1,0x23e
    80004362:	21248493          	addi	s1,s1,530 # 80242570 <log>
    80004366:	8526                	mv	a0,s1
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	9a4080e7          	jalr	-1628(ra) # 80000d0c <acquire>
  log.outstanding -= 1;
    80004370:	509c                	lw	a5,32(s1)
    80004372:	37fd                	addiw	a5,a5,-1
    80004374:	0007891b          	sext.w	s2,a5
    80004378:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000437a:	50dc                	lw	a5,36(s1)
    8000437c:	e7b9                	bnez	a5,800043ca <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000437e:	04091e63          	bnez	s2,800043da <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004382:	0023e497          	auipc	s1,0x23e
    80004386:	1ee48493          	addi	s1,s1,494 # 80242570 <log>
    8000438a:	4785                	li	a5,1
    8000438c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000438e:	8526                	mv	a0,s1
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	a30080e7          	jalr	-1488(ra) # 80000dc0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004398:	54dc                	lw	a5,44(s1)
    8000439a:	06f04763          	bgtz	a5,80004408 <end_op+0xbc>
    acquire(&log.lock);
    8000439e:	0023e497          	auipc	s1,0x23e
    800043a2:	1d248493          	addi	s1,s1,466 # 80242570 <log>
    800043a6:	8526                	mv	a0,s1
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	964080e7          	jalr	-1692(ra) # 80000d0c <acquire>
    log.committing = 0;
    800043b0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043b4:	8526                	mv	a0,s1
    800043b6:	ffffe097          	auipc	ra,0xffffe
    800043ba:	e52080e7          	jalr	-430(ra) # 80002208 <wakeup>
    release(&log.lock);
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	a00080e7          	jalr	-1536(ra) # 80000dc0 <release>
}
    800043c8:	a03d                	j	800043f6 <end_op+0xaa>
    panic("log.committing");
    800043ca:	00004517          	auipc	a0,0x4
    800043ce:	45650513          	addi	a0,a0,1110 # 80008820 <names+0x1f8>
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	16e080e7          	jalr	366(ra) # 80000540 <panic>
    wakeup(&log);
    800043da:	0023e497          	auipc	s1,0x23e
    800043de:	19648493          	addi	s1,s1,406 # 80242570 <log>
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffe097          	auipc	ra,0xffffe
    800043e8:	e24080e7          	jalr	-476(ra) # 80002208 <wakeup>
  release(&log.lock);
    800043ec:	8526                	mv	a0,s1
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	9d2080e7          	jalr	-1582(ra) # 80000dc0 <release>
}
    800043f6:	70e2                	ld	ra,56(sp)
    800043f8:	7442                	ld	s0,48(sp)
    800043fa:	74a2                	ld	s1,40(sp)
    800043fc:	7902                	ld	s2,32(sp)
    800043fe:	69e2                	ld	s3,24(sp)
    80004400:	6a42                	ld	s4,16(sp)
    80004402:	6aa2                	ld	s5,8(sp)
    80004404:	6121                	addi	sp,sp,64
    80004406:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004408:	0023ea97          	auipc	s5,0x23e
    8000440c:	198a8a93          	addi	s5,s5,408 # 802425a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004410:	0023ea17          	auipc	s4,0x23e
    80004414:	160a0a13          	addi	s4,s4,352 # 80242570 <log>
    80004418:	018a2583          	lw	a1,24(s4)
    8000441c:	012585bb          	addw	a1,a1,s2
    80004420:	2585                	addiw	a1,a1,1
    80004422:	028a2503          	lw	a0,40(s4)
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	cc4080e7          	jalr	-828(ra) # 800030ea <bread>
    8000442e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004430:	000aa583          	lw	a1,0(s5)
    80004434:	028a2503          	lw	a0,40(s4)
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	cb2080e7          	jalr	-846(ra) # 800030ea <bread>
    80004440:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004442:	40000613          	li	a2,1024
    80004446:	05850593          	addi	a1,a0,88
    8000444a:	05848513          	addi	a0,s1,88
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	a16080e7          	jalr	-1514(ra) # 80000e64 <memmove>
    bwrite(to);  // write the log
    80004456:	8526                	mv	a0,s1
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	d84080e7          	jalr	-636(ra) # 800031dc <bwrite>
    brelse(from);
    80004460:	854e                	mv	a0,s3
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	db8080e7          	jalr	-584(ra) # 8000321a <brelse>
    brelse(to);
    8000446a:	8526                	mv	a0,s1
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	dae080e7          	jalr	-594(ra) # 8000321a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004474:	2905                	addiw	s2,s2,1
    80004476:	0a91                	addi	s5,s5,4
    80004478:	02ca2783          	lw	a5,44(s4)
    8000447c:	f8f94ee3          	blt	s2,a5,80004418 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004480:	00000097          	auipc	ra,0x0
    80004484:	c68080e7          	jalr	-920(ra) # 800040e8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004488:	4501                	li	a0,0
    8000448a:	00000097          	auipc	ra,0x0
    8000448e:	cda080e7          	jalr	-806(ra) # 80004164 <install_trans>
    log.lh.n = 0;
    80004492:	0023e797          	auipc	a5,0x23e
    80004496:	1007a523          	sw	zero,266(a5) # 8024259c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	c4e080e7          	jalr	-946(ra) # 800040e8 <write_head>
    800044a2:	bdf5                	j	8000439e <end_op+0x52>

00000000800044a4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044a4:	1101                	addi	sp,sp,-32
    800044a6:	ec06                	sd	ra,24(sp)
    800044a8:	e822                	sd	s0,16(sp)
    800044aa:	e426                	sd	s1,8(sp)
    800044ac:	e04a                	sd	s2,0(sp)
    800044ae:	1000                	addi	s0,sp,32
    800044b0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044b2:	0023e917          	auipc	s2,0x23e
    800044b6:	0be90913          	addi	s2,s2,190 # 80242570 <log>
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	850080e7          	jalr	-1968(ra) # 80000d0c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044c4:	02c92603          	lw	a2,44(s2)
    800044c8:	47f5                	li	a5,29
    800044ca:	06c7c563          	blt	a5,a2,80004534 <log_write+0x90>
    800044ce:	0023e797          	auipc	a5,0x23e
    800044d2:	0be7a783          	lw	a5,190(a5) # 8024258c <log+0x1c>
    800044d6:	37fd                	addiw	a5,a5,-1
    800044d8:	04f65e63          	bge	a2,a5,80004534 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044dc:	0023e797          	auipc	a5,0x23e
    800044e0:	0b47a783          	lw	a5,180(a5) # 80242590 <log+0x20>
    800044e4:	06f05063          	blez	a5,80004544 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044e8:	4781                	li	a5,0
    800044ea:	06c05563          	blez	a2,80004554 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044ee:	44cc                	lw	a1,12(s1)
    800044f0:	0023e717          	auipc	a4,0x23e
    800044f4:	0b070713          	addi	a4,a4,176 # 802425a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044f8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044fa:	4314                	lw	a3,0(a4)
    800044fc:	04b68c63          	beq	a3,a1,80004554 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004500:	2785                	addiw	a5,a5,1
    80004502:	0711                	addi	a4,a4,4
    80004504:	fef61be3          	bne	a2,a5,800044fa <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004508:	0621                	addi	a2,a2,8
    8000450a:	060a                	slli	a2,a2,0x2
    8000450c:	0023e797          	auipc	a5,0x23e
    80004510:	06478793          	addi	a5,a5,100 # 80242570 <log>
    80004514:	97b2                	add	a5,a5,a2
    80004516:	44d8                	lw	a4,12(s1)
    80004518:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000451a:	8526                	mv	a0,s1
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	d9c080e7          	jalr	-612(ra) # 800032b8 <bpin>
    log.lh.n++;
    80004524:	0023e717          	auipc	a4,0x23e
    80004528:	04c70713          	addi	a4,a4,76 # 80242570 <log>
    8000452c:	575c                	lw	a5,44(a4)
    8000452e:	2785                	addiw	a5,a5,1
    80004530:	d75c                	sw	a5,44(a4)
    80004532:	a82d                	j	8000456c <log_write+0xc8>
    panic("too big a transaction");
    80004534:	00004517          	auipc	a0,0x4
    80004538:	2fc50513          	addi	a0,a0,764 # 80008830 <names+0x208>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	004080e7          	jalr	4(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004544:	00004517          	auipc	a0,0x4
    80004548:	30450513          	addi	a0,a0,772 # 80008848 <names+0x220>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004554:	00878693          	addi	a3,a5,8
    80004558:	068a                	slli	a3,a3,0x2
    8000455a:	0023e717          	auipc	a4,0x23e
    8000455e:	01670713          	addi	a4,a4,22 # 80242570 <log>
    80004562:	9736                	add	a4,a4,a3
    80004564:	44d4                	lw	a3,12(s1)
    80004566:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004568:	faf609e3          	beq	a2,a5,8000451a <log_write+0x76>
  }
  release(&log.lock);
    8000456c:	0023e517          	auipc	a0,0x23e
    80004570:	00450513          	addi	a0,a0,4 # 80242570 <log>
    80004574:	ffffd097          	auipc	ra,0xffffd
    80004578:	84c080e7          	jalr	-1972(ra) # 80000dc0 <release>
}
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6902                	ld	s2,0(sp)
    80004584:	6105                	addi	sp,sp,32
    80004586:	8082                	ret

0000000080004588 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004588:	1101                	addi	sp,sp,-32
    8000458a:	ec06                	sd	ra,24(sp)
    8000458c:	e822                	sd	s0,16(sp)
    8000458e:	e426                	sd	s1,8(sp)
    80004590:	e04a                	sd	s2,0(sp)
    80004592:	1000                	addi	s0,sp,32
    80004594:	84aa                	mv	s1,a0
    80004596:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004598:	00004597          	auipc	a1,0x4
    8000459c:	2d058593          	addi	a1,a1,720 # 80008868 <names+0x240>
    800045a0:	0521                	addi	a0,a0,8
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	6da080e7          	jalr	1754(ra) # 80000c7c <initlock>
  lk->name = name;
    800045aa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045ae:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045b2:	0204a423          	sw	zero,40(s1)
}
    800045b6:	60e2                	ld	ra,24(sp)
    800045b8:	6442                	ld	s0,16(sp)
    800045ba:	64a2                	ld	s1,8(sp)
    800045bc:	6902                	ld	s2,0(sp)
    800045be:	6105                	addi	sp,sp,32
    800045c0:	8082                	ret

00000000800045c2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045c2:	1101                	addi	sp,sp,-32
    800045c4:	ec06                	sd	ra,24(sp)
    800045c6:	e822                	sd	s0,16(sp)
    800045c8:	e426                	sd	s1,8(sp)
    800045ca:	e04a                	sd	s2,0(sp)
    800045cc:	1000                	addi	s0,sp,32
    800045ce:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d0:	00850913          	addi	s2,a0,8
    800045d4:	854a                	mv	a0,s2
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	736080e7          	jalr	1846(ra) # 80000d0c <acquire>
  while (lk->locked) {
    800045de:	409c                	lw	a5,0(s1)
    800045e0:	cb89                	beqz	a5,800045f2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045e2:	85ca                	mv	a1,s2
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffe097          	auipc	ra,0xffffe
    800045ea:	bbe080e7          	jalr	-1090(ra) # 800021a4 <sleep>
  while (lk->locked) {
    800045ee:	409c                	lw	a5,0(s1)
    800045f0:	fbed                	bnez	a5,800045e2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045f2:	4785                	li	a5,1
    800045f4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045f6:	ffffd097          	auipc	ra,0xffffd
    800045fa:	506080e7          	jalr	1286(ra) # 80001afc <myproc>
    800045fe:	591c                	lw	a5,48(a0)
    80004600:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	7bc080e7          	jalr	1980(ra) # 80000dc0 <release>
}
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6902                	ld	s2,0(sp)
    80004614:	6105                	addi	sp,sp,32
    80004616:	8082                	ret

0000000080004618 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004618:	1101                	addi	sp,sp,-32
    8000461a:	ec06                	sd	ra,24(sp)
    8000461c:	e822                	sd	s0,16(sp)
    8000461e:	e426                	sd	s1,8(sp)
    80004620:	e04a                	sd	s2,0(sp)
    80004622:	1000                	addi	s0,sp,32
    80004624:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004626:	00850913          	addi	s2,a0,8
    8000462a:	854a                	mv	a0,s2
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	6e0080e7          	jalr	1760(ra) # 80000d0c <acquire>
  lk->locked = 0;
    80004634:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004638:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffe097          	auipc	ra,0xffffe
    80004642:	bca080e7          	jalr	-1078(ra) # 80002208 <wakeup>
  release(&lk->lk);
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	778080e7          	jalr	1912(ra) # 80000dc0 <release>
}
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6902                	ld	s2,0(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000465c:	7179                	addi	sp,sp,-48
    8000465e:	f406                	sd	ra,40(sp)
    80004660:	f022                	sd	s0,32(sp)
    80004662:	ec26                	sd	s1,24(sp)
    80004664:	e84a                	sd	s2,16(sp)
    80004666:	e44e                	sd	s3,8(sp)
    80004668:	1800                	addi	s0,sp,48
    8000466a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000466c:	00850913          	addi	s2,a0,8
    80004670:	854a                	mv	a0,s2
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	69a080e7          	jalr	1690(ra) # 80000d0c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000467a:	409c                	lw	a5,0(s1)
    8000467c:	ef99                	bnez	a5,8000469a <holdingsleep+0x3e>
    8000467e:	4481                	li	s1,0
  release(&lk->lk);
    80004680:	854a                	mv	a0,s2
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	73e080e7          	jalr	1854(ra) # 80000dc0 <release>
  return r;
}
    8000468a:	8526                	mv	a0,s1
    8000468c:	70a2                	ld	ra,40(sp)
    8000468e:	7402                	ld	s0,32(sp)
    80004690:	64e2                	ld	s1,24(sp)
    80004692:	6942                	ld	s2,16(sp)
    80004694:	69a2                	ld	s3,8(sp)
    80004696:	6145                	addi	sp,sp,48
    80004698:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000469a:	0284a983          	lw	s3,40(s1)
    8000469e:	ffffd097          	auipc	ra,0xffffd
    800046a2:	45e080e7          	jalr	1118(ra) # 80001afc <myproc>
    800046a6:	5904                	lw	s1,48(a0)
    800046a8:	413484b3          	sub	s1,s1,s3
    800046ac:	0014b493          	seqz	s1,s1
    800046b0:	bfc1                	j	80004680 <holdingsleep+0x24>

00000000800046b2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046b2:	1141                	addi	sp,sp,-16
    800046b4:	e406                	sd	ra,8(sp)
    800046b6:	e022                	sd	s0,0(sp)
    800046b8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046ba:	00004597          	auipc	a1,0x4
    800046be:	1be58593          	addi	a1,a1,446 # 80008878 <names+0x250>
    800046c2:	0023e517          	auipc	a0,0x23e
    800046c6:	ff650513          	addi	a0,a0,-10 # 802426b8 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5b2080e7          	jalr	1458(ra) # 80000c7c <initlock>
}
    800046d2:	60a2                	ld	ra,8(sp)
    800046d4:	6402                	ld	s0,0(sp)
    800046d6:	0141                	addi	sp,sp,16
    800046d8:	8082                	ret

00000000800046da <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046da:	1101                	addi	sp,sp,-32
    800046dc:	ec06                	sd	ra,24(sp)
    800046de:	e822                	sd	s0,16(sp)
    800046e0:	e426                	sd	s1,8(sp)
    800046e2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046e4:	0023e517          	auipc	a0,0x23e
    800046e8:	fd450513          	addi	a0,a0,-44 # 802426b8 <ftable>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	620080e7          	jalr	1568(ra) # 80000d0c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046f4:	0023e497          	auipc	s1,0x23e
    800046f8:	fdc48493          	addi	s1,s1,-36 # 802426d0 <ftable+0x18>
    800046fc:	0023f717          	auipc	a4,0x23f
    80004700:	f7470713          	addi	a4,a4,-140 # 80243670 <disk>
    if(f->ref == 0){
    80004704:	40dc                	lw	a5,4(s1)
    80004706:	cf99                	beqz	a5,80004724 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004708:	02848493          	addi	s1,s1,40
    8000470c:	fee49ce3          	bne	s1,a4,80004704 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004710:	0023e517          	auipc	a0,0x23e
    80004714:	fa850513          	addi	a0,a0,-88 # 802426b8 <ftable>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	6a8080e7          	jalr	1704(ra) # 80000dc0 <release>
  return 0;
    80004720:	4481                	li	s1,0
    80004722:	a819                	j	80004738 <filealloc+0x5e>
      f->ref = 1;
    80004724:	4785                	li	a5,1
    80004726:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004728:	0023e517          	auipc	a0,0x23e
    8000472c:	f9050513          	addi	a0,a0,-112 # 802426b8 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	690080e7          	jalr	1680(ra) # 80000dc0 <release>
}
    80004738:	8526                	mv	a0,s1
    8000473a:	60e2                	ld	ra,24(sp)
    8000473c:	6442                	ld	s0,16(sp)
    8000473e:	64a2                	ld	s1,8(sp)
    80004740:	6105                	addi	sp,sp,32
    80004742:	8082                	ret

0000000080004744 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004744:	1101                	addi	sp,sp,-32
    80004746:	ec06                	sd	ra,24(sp)
    80004748:	e822                	sd	s0,16(sp)
    8000474a:	e426                	sd	s1,8(sp)
    8000474c:	1000                	addi	s0,sp,32
    8000474e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004750:	0023e517          	auipc	a0,0x23e
    80004754:	f6850513          	addi	a0,a0,-152 # 802426b8 <ftable>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	5b4080e7          	jalr	1460(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    80004760:	40dc                	lw	a5,4(s1)
    80004762:	02f05263          	blez	a5,80004786 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004766:	2785                	addiw	a5,a5,1
    80004768:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000476a:	0023e517          	auipc	a0,0x23e
    8000476e:	f4e50513          	addi	a0,a0,-178 # 802426b8 <ftable>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	64e080e7          	jalr	1614(ra) # 80000dc0 <release>
  return f;
}
    8000477a:	8526                	mv	a0,s1
    8000477c:	60e2                	ld	ra,24(sp)
    8000477e:	6442                	ld	s0,16(sp)
    80004780:	64a2                	ld	s1,8(sp)
    80004782:	6105                	addi	sp,sp,32
    80004784:	8082                	ret
    panic("filedup");
    80004786:	00004517          	auipc	a0,0x4
    8000478a:	0fa50513          	addi	a0,a0,250 # 80008880 <names+0x258>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	db2080e7          	jalr	-590(ra) # 80000540 <panic>

0000000080004796 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004796:	7139                	addi	sp,sp,-64
    80004798:	fc06                	sd	ra,56(sp)
    8000479a:	f822                	sd	s0,48(sp)
    8000479c:	f426                	sd	s1,40(sp)
    8000479e:	f04a                	sd	s2,32(sp)
    800047a0:	ec4e                	sd	s3,24(sp)
    800047a2:	e852                	sd	s4,16(sp)
    800047a4:	e456                	sd	s5,8(sp)
    800047a6:	0080                	addi	s0,sp,64
    800047a8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047aa:	0023e517          	auipc	a0,0x23e
    800047ae:	f0e50513          	addi	a0,a0,-242 # 802426b8 <ftable>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	55a080e7          	jalr	1370(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    800047ba:	40dc                	lw	a5,4(s1)
    800047bc:	06f05163          	blez	a5,8000481e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047c0:	37fd                	addiw	a5,a5,-1
    800047c2:	0007871b          	sext.w	a4,a5
    800047c6:	c0dc                	sw	a5,4(s1)
    800047c8:	06e04363          	bgtz	a4,8000482e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047cc:	0004a903          	lw	s2,0(s1)
    800047d0:	0094ca83          	lbu	s5,9(s1)
    800047d4:	0104ba03          	ld	s4,16(s1)
    800047d8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047dc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047e0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047e4:	0023e517          	auipc	a0,0x23e
    800047e8:	ed450513          	addi	a0,a0,-300 # 802426b8 <ftable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	5d4080e7          	jalr	1492(ra) # 80000dc0 <release>

  if(ff.type == FD_PIPE){
    800047f4:	4785                	li	a5,1
    800047f6:	04f90d63          	beq	s2,a5,80004850 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047fa:	3979                	addiw	s2,s2,-2
    800047fc:	4785                	li	a5,1
    800047fe:	0527e063          	bltu	a5,s2,8000483e <fileclose+0xa8>
    begin_op();
    80004802:	00000097          	auipc	ra,0x0
    80004806:	acc080e7          	jalr	-1332(ra) # 800042ce <begin_op>
    iput(ff.ip);
    8000480a:	854e                	mv	a0,s3
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	2b0080e7          	jalr	688(ra) # 80003abc <iput>
    end_op();
    80004814:	00000097          	auipc	ra,0x0
    80004818:	b38080e7          	jalr	-1224(ra) # 8000434c <end_op>
    8000481c:	a00d                	j	8000483e <fileclose+0xa8>
    panic("fileclose");
    8000481e:	00004517          	auipc	a0,0x4
    80004822:	06a50513          	addi	a0,a0,106 # 80008888 <names+0x260>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	d1a080e7          	jalr	-742(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000482e:	0023e517          	auipc	a0,0x23e
    80004832:	e8a50513          	addi	a0,a0,-374 # 802426b8 <ftable>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	58a080e7          	jalr	1418(ra) # 80000dc0 <release>
  }
}
    8000483e:	70e2                	ld	ra,56(sp)
    80004840:	7442                	ld	s0,48(sp)
    80004842:	74a2                	ld	s1,40(sp)
    80004844:	7902                	ld	s2,32(sp)
    80004846:	69e2                	ld	s3,24(sp)
    80004848:	6a42                	ld	s4,16(sp)
    8000484a:	6aa2                	ld	s5,8(sp)
    8000484c:	6121                	addi	sp,sp,64
    8000484e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004850:	85d6                	mv	a1,s5
    80004852:	8552                	mv	a0,s4
    80004854:	00000097          	auipc	ra,0x0
    80004858:	34c080e7          	jalr	844(ra) # 80004ba0 <pipeclose>
    8000485c:	b7cd                	j	8000483e <fileclose+0xa8>

000000008000485e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000485e:	715d                	addi	sp,sp,-80
    80004860:	e486                	sd	ra,72(sp)
    80004862:	e0a2                	sd	s0,64(sp)
    80004864:	fc26                	sd	s1,56(sp)
    80004866:	f84a                	sd	s2,48(sp)
    80004868:	f44e                	sd	s3,40(sp)
    8000486a:	0880                	addi	s0,sp,80
    8000486c:	84aa                	mv	s1,a0
    8000486e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004870:	ffffd097          	auipc	ra,0xffffd
    80004874:	28c080e7          	jalr	652(ra) # 80001afc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004878:	409c                	lw	a5,0(s1)
    8000487a:	37f9                	addiw	a5,a5,-2
    8000487c:	4705                	li	a4,1
    8000487e:	04f76763          	bltu	a4,a5,800048cc <filestat+0x6e>
    80004882:	892a                	mv	s2,a0
    ilock(f->ip);
    80004884:	6c88                	ld	a0,24(s1)
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	07c080e7          	jalr	124(ra) # 80003902 <ilock>
    stati(f->ip, &st);
    8000488e:	fb840593          	addi	a1,s0,-72
    80004892:	6c88                	ld	a0,24(s1)
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	2f8080e7          	jalr	760(ra) # 80003b8c <stati>
    iunlock(f->ip);
    8000489c:	6c88                	ld	a0,24(s1)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	126080e7          	jalr	294(ra) # 800039c4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048a6:	46e1                	li	a3,24
    800048a8:	fb840613          	addi	a2,s0,-72
    800048ac:	85ce                	mv	a1,s3
    800048ae:	05093503          	ld	a0,80(s2)
    800048b2:	ffffd097          	auipc	ra,0xffffd
    800048b6:	ed6080e7          	jalr	-298(ra) # 80001788 <copyout>
    800048ba:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048be:	60a6                	ld	ra,72(sp)
    800048c0:	6406                	ld	s0,64(sp)
    800048c2:	74e2                	ld	s1,56(sp)
    800048c4:	7942                	ld	s2,48(sp)
    800048c6:	79a2                	ld	s3,40(sp)
    800048c8:	6161                	addi	sp,sp,80
    800048ca:	8082                	ret
  return -1;
    800048cc:	557d                	li	a0,-1
    800048ce:	bfc5                	j	800048be <filestat+0x60>

00000000800048d0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048d0:	7179                	addi	sp,sp,-48
    800048d2:	f406                	sd	ra,40(sp)
    800048d4:	f022                	sd	s0,32(sp)
    800048d6:	ec26                	sd	s1,24(sp)
    800048d8:	e84a                	sd	s2,16(sp)
    800048da:	e44e                	sd	s3,8(sp)
    800048dc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048de:	00854783          	lbu	a5,8(a0)
    800048e2:	c3d5                	beqz	a5,80004986 <fileread+0xb6>
    800048e4:	84aa                	mv	s1,a0
    800048e6:	89ae                	mv	s3,a1
    800048e8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ea:	411c                	lw	a5,0(a0)
    800048ec:	4705                	li	a4,1
    800048ee:	04e78963          	beq	a5,a4,80004940 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048f2:	470d                	li	a4,3
    800048f4:	04e78d63          	beq	a5,a4,8000494e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f8:	4709                	li	a4,2
    800048fa:	06e79e63          	bne	a5,a4,80004976 <fileread+0xa6>
    ilock(f->ip);
    800048fe:	6d08                	ld	a0,24(a0)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	002080e7          	jalr	2(ra) # 80003902 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004908:	874a                	mv	a4,s2
    8000490a:	5094                	lw	a3,32(s1)
    8000490c:	864e                	mv	a2,s3
    8000490e:	4585                	li	a1,1
    80004910:	6c88                	ld	a0,24(s1)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	2a4080e7          	jalr	676(ra) # 80003bb6 <readi>
    8000491a:	892a                	mv	s2,a0
    8000491c:	00a05563          	blez	a0,80004926 <fileread+0x56>
      f->off += r;
    80004920:	509c                	lw	a5,32(s1)
    80004922:	9fa9                	addw	a5,a5,a0
    80004924:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004926:	6c88                	ld	a0,24(s1)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	09c080e7          	jalr	156(ra) # 800039c4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004930:	854a                	mv	a0,s2
    80004932:	70a2                	ld	ra,40(sp)
    80004934:	7402                	ld	s0,32(sp)
    80004936:	64e2                	ld	s1,24(sp)
    80004938:	6942                	ld	s2,16(sp)
    8000493a:	69a2                	ld	s3,8(sp)
    8000493c:	6145                	addi	sp,sp,48
    8000493e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004940:	6908                	ld	a0,16(a0)
    80004942:	00000097          	auipc	ra,0x0
    80004946:	3c6080e7          	jalr	966(ra) # 80004d08 <piperead>
    8000494a:	892a                	mv	s2,a0
    8000494c:	b7d5                	j	80004930 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000494e:	02451783          	lh	a5,36(a0)
    80004952:	03079693          	slli	a3,a5,0x30
    80004956:	92c1                	srli	a3,a3,0x30
    80004958:	4725                	li	a4,9
    8000495a:	02d76863          	bltu	a4,a3,8000498a <fileread+0xba>
    8000495e:	0792                	slli	a5,a5,0x4
    80004960:	0023e717          	auipc	a4,0x23e
    80004964:	cb870713          	addi	a4,a4,-840 # 80242618 <devsw>
    80004968:	97ba                	add	a5,a5,a4
    8000496a:	639c                	ld	a5,0(a5)
    8000496c:	c38d                	beqz	a5,8000498e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000496e:	4505                	li	a0,1
    80004970:	9782                	jalr	a5
    80004972:	892a                	mv	s2,a0
    80004974:	bf75                	j	80004930 <fileread+0x60>
    panic("fileread");
    80004976:	00004517          	auipc	a0,0x4
    8000497a:	f2250513          	addi	a0,a0,-222 # 80008898 <names+0x270>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	bc2080e7          	jalr	-1086(ra) # 80000540 <panic>
    return -1;
    80004986:	597d                	li	s2,-1
    80004988:	b765                	j	80004930 <fileread+0x60>
      return -1;
    8000498a:	597d                	li	s2,-1
    8000498c:	b755                	j	80004930 <fileread+0x60>
    8000498e:	597d                	li	s2,-1
    80004990:	b745                	j	80004930 <fileread+0x60>

0000000080004992 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004992:	715d                	addi	sp,sp,-80
    80004994:	e486                	sd	ra,72(sp)
    80004996:	e0a2                	sd	s0,64(sp)
    80004998:	fc26                	sd	s1,56(sp)
    8000499a:	f84a                	sd	s2,48(sp)
    8000499c:	f44e                	sd	s3,40(sp)
    8000499e:	f052                	sd	s4,32(sp)
    800049a0:	ec56                	sd	s5,24(sp)
    800049a2:	e85a                	sd	s6,16(sp)
    800049a4:	e45e                	sd	s7,8(sp)
    800049a6:	e062                	sd	s8,0(sp)
    800049a8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049aa:	00954783          	lbu	a5,9(a0)
    800049ae:	10078663          	beqz	a5,80004aba <filewrite+0x128>
    800049b2:	892a                	mv	s2,a0
    800049b4:	8b2e                	mv	s6,a1
    800049b6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b8:	411c                	lw	a5,0(a0)
    800049ba:	4705                	li	a4,1
    800049bc:	02e78263          	beq	a5,a4,800049e0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049c0:	470d                	li	a4,3
    800049c2:	02e78663          	beq	a5,a4,800049ee <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c6:	4709                	li	a4,2
    800049c8:	0ee79163          	bne	a5,a4,80004aaa <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049cc:	0ac05d63          	blez	a2,80004a86 <filewrite+0xf4>
    int i = 0;
    800049d0:	4981                	li	s3,0
    800049d2:	6b85                	lui	s7,0x1
    800049d4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800049d8:	6c05                	lui	s8,0x1
    800049da:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800049de:	a861                	j	80004a76 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049e0:	6908                	ld	a0,16(a0)
    800049e2:	00000097          	auipc	ra,0x0
    800049e6:	22e080e7          	jalr	558(ra) # 80004c10 <pipewrite>
    800049ea:	8a2a                	mv	s4,a0
    800049ec:	a045                	j	80004a8c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049ee:	02451783          	lh	a5,36(a0)
    800049f2:	03079693          	slli	a3,a5,0x30
    800049f6:	92c1                	srli	a3,a3,0x30
    800049f8:	4725                	li	a4,9
    800049fa:	0cd76263          	bltu	a4,a3,80004abe <filewrite+0x12c>
    800049fe:	0792                	slli	a5,a5,0x4
    80004a00:	0023e717          	auipc	a4,0x23e
    80004a04:	c1870713          	addi	a4,a4,-1000 # 80242618 <devsw>
    80004a08:	97ba                	add	a5,a5,a4
    80004a0a:	679c                	ld	a5,8(a5)
    80004a0c:	cbdd                	beqz	a5,80004ac2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a0e:	4505                	li	a0,1
    80004a10:	9782                	jalr	a5
    80004a12:	8a2a                	mv	s4,a0
    80004a14:	a8a5                	j	80004a8c <filewrite+0xfa>
    80004a16:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a1a:	00000097          	auipc	ra,0x0
    80004a1e:	8b4080e7          	jalr	-1868(ra) # 800042ce <begin_op>
      ilock(f->ip);
    80004a22:	01893503          	ld	a0,24(s2)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	edc080e7          	jalr	-292(ra) # 80003902 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a2e:	8756                	mv	a4,s5
    80004a30:	02092683          	lw	a3,32(s2)
    80004a34:	01698633          	add	a2,s3,s6
    80004a38:	4585                	li	a1,1
    80004a3a:	01893503          	ld	a0,24(s2)
    80004a3e:	fffff097          	auipc	ra,0xfffff
    80004a42:	270080e7          	jalr	624(ra) # 80003cae <writei>
    80004a46:	84aa                	mv	s1,a0
    80004a48:	00a05763          	blez	a0,80004a56 <filewrite+0xc4>
        f->off += r;
    80004a4c:	02092783          	lw	a5,32(s2)
    80004a50:	9fa9                	addw	a5,a5,a0
    80004a52:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a56:	01893503          	ld	a0,24(s2)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	f6a080e7          	jalr	-150(ra) # 800039c4 <iunlock>
      end_op();
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	8ea080e7          	jalr	-1814(ra) # 8000434c <end_op>

      if(r != n1){
    80004a6a:	009a9f63          	bne	s5,s1,80004a88 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a6e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a72:	0149db63          	bge	s3,s4,80004a88 <filewrite+0xf6>
      int n1 = n - i;
    80004a76:	413a04bb          	subw	s1,s4,s3
    80004a7a:	0004879b          	sext.w	a5,s1
    80004a7e:	f8fbdce3          	bge	s7,a5,80004a16 <filewrite+0x84>
    80004a82:	84e2                	mv	s1,s8
    80004a84:	bf49                	j	80004a16 <filewrite+0x84>
    int i = 0;
    80004a86:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a88:	013a1f63          	bne	s4,s3,80004aa6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a8c:	8552                	mv	a0,s4
    80004a8e:	60a6                	ld	ra,72(sp)
    80004a90:	6406                	ld	s0,64(sp)
    80004a92:	74e2                	ld	s1,56(sp)
    80004a94:	7942                	ld	s2,48(sp)
    80004a96:	79a2                	ld	s3,40(sp)
    80004a98:	7a02                	ld	s4,32(sp)
    80004a9a:	6ae2                	ld	s5,24(sp)
    80004a9c:	6b42                	ld	s6,16(sp)
    80004a9e:	6ba2                	ld	s7,8(sp)
    80004aa0:	6c02                	ld	s8,0(sp)
    80004aa2:	6161                	addi	sp,sp,80
    80004aa4:	8082                	ret
    ret = (i == n ? n : -1);
    80004aa6:	5a7d                	li	s4,-1
    80004aa8:	b7d5                	j	80004a8c <filewrite+0xfa>
    panic("filewrite");
    80004aaa:	00004517          	auipc	a0,0x4
    80004aae:	dfe50513          	addi	a0,a0,-514 # 800088a8 <names+0x280>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	a8e080e7          	jalr	-1394(ra) # 80000540 <panic>
    return -1;
    80004aba:	5a7d                	li	s4,-1
    80004abc:	bfc1                	j	80004a8c <filewrite+0xfa>
      return -1;
    80004abe:	5a7d                	li	s4,-1
    80004ac0:	b7f1                	j	80004a8c <filewrite+0xfa>
    80004ac2:	5a7d                	li	s4,-1
    80004ac4:	b7e1                	j	80004a8c <filewrite+0xfa>

0000000080004ac6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ac6:	7179                	addi	sp,sp,-48
    80004ac8:	f406                	sd	ra,40(sp)
    80004aca:	f022                	sd	s0,32(sp)
    80004acc:	ec26                	sd	s1,24(sp)
    80004ace:	e84a                	sd	s2,16(sp)
    80004ad0:	e44e                	sd	s3,8(sp)
    80004ad2:	e052                	sd	s4,0(sp)
    80004ad4:	1800                	addi	s0,sp,48
    80004ad6:	84aa                	mv	s1,a0
    80004ad8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ada:	0005b023          	sd	zero,0(a1)
    80004ade:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	bf8080e7          	jalr	-1032(ra) # 800046da <filealloc>
    80004aea:	e088                	sd	a0,0(s1)
    80004aec:	c551                	beqz	a0,80004b78 <pipealloc+0xb2>
    80004aee:	00000097          	auipc	ra,0x0
    80004af2:	bec080e7          	jalr	-1044(ra) # 800046da <filealloc>
    80004af6:	00aa3023          	sd	a0,0(s4)
    80004afa:	c92d                	beqz	a0,80004b6c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	0e8080e7          	jalr	232(ra) # 80000be4 <kalloc>
    80004b04:	892a                	mv	s2,a0
    80004b06:	c125                	beqz	a0,80004b66 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b08:	4985                	li	s3,1
    80004b0a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b0e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b12:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b16:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b1a:	00004597          	auipc	a1,0x4
    80004b1e:	99e58593          	addi	a1,a1,-1634 # 800084b8 <states.0+0x1b8>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	15a080e7          	jalr	346(ra) # 80000c7c <initlock>
  (*f0)->type = FD_PIPE;
    80004b2a:	609c                	ld	a5,0(s1)
    80004b2c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b30:	609c                	ld	a5,0(s1)
    80004b32:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b36:	609c                	ld	a5,0(s1)
    80004b38:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b3c:	609c                	ld	a5,0(s1)
    80004b3e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b42:	000a3783          	ld	a5,0(s4)
    80004b46:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b4a:	000a3783          	ld	a5,0(s4)
    80004b4e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b52:	000a3783          	ld	a5,0(s4)
    80004b56:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b5a:	000a3783          	ld	a5,0(s4)
    80004b5e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b62:	4501                	li	a0,0
    80004b64:	a025                	j	80004b8c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b66:	6088                	ld	a0,0(s1)
    80004b68:	e501                	bnez	a0,80004b70 <pipealloc+0xaa>
    80004b6a:	a039                	j	80004b78 <pipealloc+0xb2>
    80004b6c:	6088                	ld	a0,0(s1)
    80004b6e:	c51d                	beqz	a0,80004b9c <pipealloc+0xd6>
    fileclose(*f0);
    80004b70:	00000097          	auipc	ra,0x0
    80004b74:	c26080e7          	jalr	-986(ra) # 80004796 <fileclose>
  if(*f1)
    80004b78:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b7c:	557d                	li	a0,-1
  if(*f1)
    80004b7e:	c799                	beqz	a5,80004b8c <pipealloc+0xc6>
    fileclose(*f1);
    80004b80:	853e                	mv	a0,a5
    80004b82:	00000097          	auipc	ra,0x0
    80004b86:	c14080e7          	jalr	-1004(ra) # 80004796 <fileclose>
  return -1;
    80004b8a:	557d                	li	a0,-1
}
    80004b8c:	70a2                	ld	ra,40(sp)
    80004b8e:	7402                	ld	s0,32(sp)
    80004b90:	64e2                	ld	s1,24(sp)
    80004b92:	6942                	ld	s2,16(sp)
    80004b94:	69a2                	ld	s3,8(sp)
    80004b96:	6a02                	ld	s4,0(sp)
    80004b98:	6145                	addi	sp,sp,48
    80004b9a:	8082                	ret
  return -1;
    80004b9c:	557d                	li	a0,-1
    80004b9e:	b7fd                	j	80004b8c <pipealloc+0xc6>

0000000080004ba0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ba0:	1101                	addi	sp,sp,-32
    80004ba2:	ec06                	sd	ra,24(sp)
    80004ba4:	e822                	sd	s0,16(sp)
    80004ba6:	e426                	sd	s1,8(sp)
    80004ba8:	e04a                	sd	s2,0(sp)
    80004baa:	1000                	addi	s0,sp,32
    80004bac:	84aa                	mv	s1,a0
    80004bae:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	15c080e7          	jalr	348(ra) # 80000d0c <acquire>
  if(writable){
    80004bb8:	02090d63          	beqz	s2,80004bf2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bbc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bc0:	21848513          	addi	a0,s1,536
    80004bc4:	ffffd097          	auipc	ra,0xffffd
    80004bc8:	644080e7          	jalr	1604(ra) # 80002208 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bcc:	2204b783          	ld	a5,544(s1)
    80004bd0:	eb95                	bnez	a5,80004c04 <pipeclose+0x64>
    release(&pi->lock);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	1ec080e7          	jalr	492(ra) # 80000dc0 <release>
    kfree((char*)pi);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	e82080e7          	jalr	-382(ra) # 80000a60 <kfree>
  } else
    release(&pi->lock);
}
    80004be6:	60e2                	ld	ra,24(sp)
    80004be8:	6442                	ld	s0,16(sp)
    80004bea:	64a2                	ld	s1,8(sp)
    80004bec:	6902                	ld	s2,0(sp)
    80004bee:	6105                	addi	sp,sp,32
    80004bf0:	8082                	ret
    pi->readopen = 0;
    80004bf2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bf6:	21c48513          	addi	a0,s1,540
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	60e080e7          	jalr	1550(ra) # 80002208 <wakeup>
    80004c02:	b7e9                	j	80004bcc <pipeclose+0x2c>
    release(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	1ba080e7          	jalr	442(ra) # 80000dc0 <release>
}
    80004c0e:	bfe1                	j	80004be6 <pipeclose+0x46>

0000000080004c10 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c10:	711d                	addi	sp,sp,-96
    80004c12:	ec86                	sd	ra,88(sp)
    80004c14:	e8a2                	sd	s0,80(sp)
    80004c16:	e4a6                	sd	s1,72(sp)
    80004c18:	e0ca                	sd	s2,64(sp)
    80004c1a:	fc4e                	sd	s3,56(sp)
    80004c1c:	f852                	sd	s4,48(sp)
    80004c1e:	f456                	sd	s5,40(sp)
    80004c20:	f05a                	sd	s6,32(sp)
    80004c22:	ec5e                	sd	s7,24(sp)
    80004c24:	e862                	sd	s8,16(sp)
    80004c26:	1080                	addi	s0,sp,96
    80004c28:	84aa                	mv	s1,a0
    80004c2a:	8aae                	mv	s5,a1
    80004c2c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	ece080e7          	jalr	-306(ra) # 80001afc <myproc>
    80004c36:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	0d2080e7          	jalr	210(ra) # 80000d0c <acquire>
  while(i < n){
    80004c42:	0b405663          	blez	s4,80004cee <pipewrite+0xde>
  int i = 0;
    80004c46:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c48:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c4a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c4e:	21c48b93          	addi	s7,s1,540
    80004c52:	a089                	j	80004c94 <pipewrite+0x84>
      release(&pi->lock);
    80004c54:	8526                	mv	a0,s1
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	16a080e7          	jalr	362(ra) # 80000dc0 <release>
      return -1;
    80004c5e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c60:	854a                	mv	a0,s2
    80004c62:	60e6                	ld	ra,88(sp)
    80004c64:	6446                	ld	s0,80(sp)
    80004c66:	64a6                	ld	s1,72(sp)
    80004c68:	6906                	ld	s2,64(sp)
    80004c6a:	79e2                	ld	s3,56(sp)
    80004c6c:	7a42                	ld	s4,48(sp)
    80004c6e:	7aa2                	ld	s5,40(sp)
    80004c70:	7b02                	ld	s6,32(sp)
    80004c72:	6be2                	ld	s7,24(sp)
    80004c74:	6c42                	ld	s8,16(sp)
    80004c76:	6125                	addi	sp,sp,96
    80004c78:	8082                	ret
      wakeup(&pi->nread);
    80004c7a:	8562                	mv	a0,s8
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	58c080e7          	jalr	1420(ra) # 80002208 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c84:	85a6                	mv	a1,s1
    80004c86:	855e                	mv	a0,s7
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	51c080e7          	jalr	1308(ra) # 800021a4 <sleep>
  while(i < n){
    80004c90:	07495063          	bge	s2,s4,80004cf0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c94:	2204a783          	lw	a5,544(s1)
    80004c98:	dfd5                	beqz	a5,80004c54 <pipewrite+0x44>
    80004c9a:	854e                	mv	a0,s3
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	7b0080e7          	jalr	1968(ra) # 8000244c <killed>
    80004ca4:	f945                	bnez	a0,80004c54 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ca6:	2184a783          	lw	a5,536(s1)
    80004caa:	21c4a703          	lw	a4,540(s1)
    80004cae:	2007879b          	addiw	a5,a5,512
    80004cb2:	fcf704e3          	beq	a4,a5,80004c7a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb6:	4685                	li	a3,1
    80004cb8:	01590633          	add	a2,s2,s5
    80004cbc:	faf40593          	addi	a1,s0,-81
    80004cc0:	0509b503          	ld	a0,80(s3)
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	b84080e7          	jalr	-1148(ra) # 80001848 <copyin>
    80004ccc:	03650263          	beq	a0,s6,80004cf0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cd0:	21c4a783          	lw	a5,540(s1)
    80004cd4:	0017871b          	addiw	a4,a5,1
    80004cd8:	20e4ae23          	sw	a4,540(s1)
    80004cdc:	1ff7f793          	andi	a5,a5,511
    80004ce0:	97a6                	add	a5,a5,s1
    80004ce2:	faf44703          	lbu	a4,-81(s0)
    80004ce6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cea:	2905                	addiw	s2,s2,1
    80004cec:	b755                	j	80004c90 <pipewrite+0x80>
  int i = 0;
    80004cee:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cf0:	21848513          	addi	a0,s1,536
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	514080e7          	jalr	1300(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	0c2080e7          	jalr	194(ra) # 80000dc0 <release>
  return i;
    80004d06:	bfa9                	j	80004c60 <pipewrite+0x50>

0000000080004d08 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d08:	715d                	addi	sp,sp,-80
    80004d0a:	e486                	sd	ra,72(sp)
    80004d0c:	e0a2                	sd	s0,64(sp)
    80004d0e:	fc26                	sd	s1,56(sp)
    80004d10:	f84a                	sd	s2,48(sp)
    80004d12:	f44e                	sd	s3,40(sp)
    80004d14:	f052                	sd	s4,32(sp)
    80004d16:	ec56                	sd	s5,24(sp)
    80004d18:	e85a                	sd	s6,16(sp)
    80004d1a:	0880                	addi	s0,sp,80
    80004d1c:	84aa                	mv	s1,a0
    80004d1e:	892e                	mv	s2,a1
    80004d20:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d22:	ffffd097          	auipc	ra,0xffffd
    80004d26:	dda080e7          	jalr	-550(ra) # 80001afc <myproc>
    80004d2a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	fde080e7          	jalr	-34(ra) # 80000d0c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d36:	2184a703          	lw	a4,536(s1)
    80004d3a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d42:	02f71763          	bne	a4,a5,80004d70 <piperead+0x68>
    80004d46:	2244a783          	lw	a5,548(s1)
    80004d4a:	c39d                	beqz	a5,80004d70 <piperead+0x68>
    if(killed(pr)){
    80004d4c:	8552                	mv	a0,s4
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	6fe080e7          	jalr	1790(ra) # 8000244c <killed>
    80004d56:	e949                	bnez	a0,80004de8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d58:	85a6                	mv	a1,s1
    80004d5a:	854e                	mv	a0,s3
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	448080e7          	jalr	1096(ra) # 800021a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d64:	2184a703          	lw	a4,536(s1)
    80004d68:	21c4a783          	lw	a5,540(s1)
    80004d6c:	fcf70de3          	beq	a4,a5,80004d46 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d70:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d72:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d74:	05505463          	blez	s5,80004dbc <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004d78:	2184a783          	lw	a5,536(s1)
    80004d7c:	21c4a703          	lw	a4,540(s1)
    80004d80:	02f70e63          	beq	a4,a5,80004dbc <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d84:	0017871b          	addiw	a4,a5,1
    80004d88:	20e4ac23          	sw	a4,536(s1)
    80004d8c:	1ff7f793          	andi	a5,a5,511
    80004d90:	97a6                	add	a5,a5,s1
    80004d92:	0187c783          	lbu	a5,24(a5)
    80004d96:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d9a:	4685                	li	a3,1
    80004d9c:	fbf40613          	addi	a2,s0,-65
    80004da0:	85ca                	mv	a1,s2
    80004da2:	050a3503          	ld	a0,80(s4)
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	9e2080e7          	jalr	-1566(ra) # 80001788 <copyout>
    80004dae:	01650763          	beq	a0,s6,80004dbc <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db2:	2985                	addiw	s3,s3,1
    80004db4:	0905                	addi	s2,s2,1
    80004db6:	fd3a91e3          	bne	s5,s3,80004d78 <piperead+0x70>
    80004dba:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dbc:	21c48513          	addi	a0,s1,540
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	448080e7          	jalr	1096(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004dc8:	8526                	mv	a0,s1
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	ff6080e7          	jalr	-10(ra) # 80000dc0 <release>
  return i;
}
    80004dd2:	854e                	mv	a0,s3
    80004dd4:	60a6                	ld	ra,72(sp)
    80004dd6:	6406                	ld	s0,64(sp)
    80004dd8:	74e2                	ld	s1,56(sp)
    80004dda:	7942                	ld	s2,48(sp)
    80004ddc:	79a2                	ld	s3,40(sp)
    80004dde:	7a02                	ld	s4,32(sp)
    80004de0:	6ae2                	ld	s5,24(sp)
    80004de2:	6b42                	ld	s6,16(sp)
    80004de4:	6161                	addi	sp,sp,80
    80004de6:	8082                	ret
      release(&pi->lock);
    80004de8:	8526                	mv	a0,s1
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	fd6080e7          	jalr	-42(ra) # 80000dc0 <release>
      return -1;
    80004df2:	59fd                	li	s3,-1
    80004df4:	bff9                	j	80004dd2 <piperead+0xca>

0000000080004df6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004df6:	1141                	addi	sp,sp,-16
    80004df8:	e422                	sd	s0,8(sp)
    80004dfa:	0800                	addi	s0,sp,16
    80004dfc:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dfe:	8905                	andi	a0,a0,1
    80004e00:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004e02:	8b89                	andi	a5,a5,2
    80004e04:	c399                	beqz	a5,80004e0a <flags2perm+0x14>
      perm |= PTE_W;
    80004e06:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e0a:	6422                	ld	s0,8(sp)
    80004e0c:	0141                	addi	sp,sp,16
    80004e0e:	8082                	ret

0000000080004e10 <exec>:

int
exec(char *path, char **argv)
{
    80004e10:	de010113          	addi	sp,sp,-544
    80004e14:	20113c23          	sd	ra,536(sp)
    80004e18:	20813823          	sd	s0,528(sp)
    80004e1c:	20913423          	sd	s1,520(sp)
    80004e20:	21213023          	sd	s2,512(sp)
    80004e24:	ffce                	sd	s3,504(sp)
    80004e26:	fbd2                	sd	s4,496(sp)
    80004e28:	f7d6                	sd	s5,488(sp)
    80004e2a:	f3da                	sd	s6,480(sp)
    80004e2c:	efde                	sd	s7,472(sp)
    80004e2e:	ebe2                	sd	s8,464(sp)
    80004e30:	e7e6                	sd	s9,456(sp)
    80004e32:	e3ea                	sd	s10,448(sp)
    80004e34:	ff6e                	sd	s11,440(sp)
    80004e36:	1400                	addi	s0,sp,544
    80004e38:	892a                	mv	s2,a0
    80004e3a:	dea43423          	sd	a0,-536(s0)
    80004e3e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	cba080e7          	jalr	-838(ra) # 80001afc <myproc>
    80004e4a:	84aa                	mv	s1,a0

  // printf("1\n");

  begin_op();
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	482080e7          	jalr	1154(ra) # 800042ce <begin_op>

  if((ip = namei(path)) == 0){
    80004e54:	854a                	mv	a0,s2
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	258080e7          	jalr	600(ra) # 800040ae <namei>
    80004e5e:	c93d                	beqz	a0,80004ed4 <exec+0xc4>
    80004e60:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	aa0080e7          	jalr	-1376(ra) # 80003902 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e6a:	04000713          	li	a4,64
    80004e6e:	4681                	li	a3,0
    80004e70:	e5040613          	addi	a2,s0,-432
    80004e74:	4581                	li	a1,0
    80004e76:	8556                	mv	a0,s5
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	d3e080e7          	jalr	-706(ra) # 80003bb6 <readi>
    80004e80:	04000793          	li	a5,64
    80004e84:	00f51a63          	bne	a0,a5,80004e98 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e88:	e5042703          	lw	a4,-432(s0)
    80004e8c:	464c47b7          	lui	a5,0x464c4
    80004e90:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e94:	04f70663          	beq	a4,a5,80004ee0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e98:	8556                	mv	a0,s5
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	cca080e7          	jalr	-822(ra) # 80003b64 <iunlockput>
    end_op();
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	4aa080e7          	jalr	1194(ra) # 8000434c <end_op>
  }
  return -1;
    80004eaa:	557d                	li	a0,-1
}
    80004eac:	21813083          	ld	ra,536(sp)
    80004eb0:	21013403          	ld	s0,528(sp)
    80004eb4:	20813483          	ld	s1,520(sp)
    80004eb8:	20013903          	ld	s2,512(sp)
    80004ebc:	79fe                	ld	s3,504(sp)
    80004ebe:	7a5e                	ld	s4,496(sp)
    80004ec0:	7abe                	ld	s5,488(sp)
    80004ec2:	7b1e                	ld	s6,480(sp)
    80004ec4:	6bfe                	ld	s7,472(sp)
    80004ec6:	6c5e                	ld	s8,464(sp)
    80004ec8:	6cbe                	ld	s9,456(sp)
    80004eca:	6d1e                	ld	s10,448(sp)
    80004ecc:	7dfa                	ld	s11,440(sp)
    80004ece:	22010113          	addi	sp,sp,544
    80004ed2:	8082                	ret
    end_op();
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	478080e7          	jalr	1144(ra) # 8000434c <end_op>
    return -1;
    80004edc:	557d                	li	a0,-1
    80004ede:	b7f9                	j	80004eac <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	cde080e7          	jalr	-802(ra) # 80001bc0 <proc_pagetable>
    80004eea:	8b2a                	mv	s6,a0
    80004eec:	d555                	beqz	a0,80004e98 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eee:	e7042783          	lw	a5,-400(s0)
    80004ef2:	e8845703          	lhu	a4,-376(s0)
    80004ef6:	c735                	beqz	a4,80004f62 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ef8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004efa:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004efe:	6a05                	lui	s4,0x1
    80004f00:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f04:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f08:	6d85                	lui	s11,0x1
    80004f0a:	7d7d                	lui	s10,0xfffff
    80004f0c:	ac3d                	j	8000514a <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f0e:	00004517          	auipc	a0,0x4
    80004f12:	9aa50513          	addi	a0,a0,-1622 # 800088b8 <names+0x290>
    80004f16:	ffffb097          	auipc	ra,0xffffb
    80004f1a:	62a080e7          	jalr	1578(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f1e:	874a                	mv	a4,s2
    80004f20:	009c86bb          	addw	a3,s9,s1
    80004f24:	4581                	li	a1,0
    80004f26:	8556                	mv	a0,s5
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	c8e080e7          	jalr	-882(ra) # 80003bb6 <readi>
    80004f30:	2501                	sext.w	a0,a0
    80004f32:	1aa91963          	bne	s2,a0,800050e4 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004f36:	009d84bb          	addw	s1,s11,s1
    80004f3a:	013d09bb          	addw	s3,s10,s3
    80004f3e:	1f74f663          	bgeu	s1,s7,8000512a <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004f42:	02049593          	slli	a1,s1,0x20
    80004f46:	9181                	srli	a1,a1,0x20
    80004f48:	95e2                	add	a1,a1,s8
    80004f4a:	855a                	mv	a0,s6
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	246080e7          	jalr	582(ra) # 80001192 <walkaddr>
    80004f54:	862a                	mv	a2,a0
    if(pa == 0)
    80004f56:	dd45                	beqz	a0,80004f0e <exec+0xfe>
      n = PGSIZE;
    80004f58:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f5a:	fd49f2e3          	bgeu	s3,s4,80004f1e <exec+0x10e>
      n = sz - i;
    80004f5e:	894e                	mv	s2,s3
    80004f60:	bf7d                	j	80004f1e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f62:	4901                	li	s2,0
  iunlockput(ip);
    80004f64:	8556                	mv	a0,s5
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	bfe080e7          	jalr	-1026(ra) # 80003b64 <iunlockput>
  end_op();
    80004f6e:	fffff097          	auipc	ra,0xfffff
    80004f72:	3de080e7          	jalr	990(ra) # 8000434c <end_op>
  p = myproc();
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	b86080e7          	jalr	-1146(ra) # 80001afc <myproc>
    80004f7e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f80:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f84:	6785                	lui	a5,0x1
    80004f86:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f88:	97ca                	add	a5,a5,s2
    80004f8a:	777d                	lui	a4,0xfffff
    80004f8c:	8ff9                	and	a5,a5,a4
    80004f8e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f92:	4691                	li	a3,4
    80004f94:	6609                	lui	a2,0x2
    80004f96:	963e                	add	a2,a2,a5
    80004f98:	85be                	mv	a1,a5
    80004f9a:	855a                	mv	a0,s6
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	5aa080e7          	jalr	1450(ra) # 80001546 <uvmalloc>
    80004fa4:	8c2a                	mv	s8,a0
  ip = 0;
    80004fa6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fa8:	12050e63          	beqz	a0,800050e4 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fac:	75f9                	lui	a1,0xffffe
    80004fae:	95aa                	add	a1,a1,a0
    80004fb0:	855a                	mv	a0,s6
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	7a4080e7          	jalr	1956(ra) # 80001756 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fba:	7afd                	lui	s5,0xfffff
    80004fbc:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fbe:	df043783          	ld	a5,-528(s0)
    80004fc2:	6388                	ld	a0,0(a5)
    80004fc4:	c925                	beqz	a0,80005034 <exec+0x224>
    80004fc6:	e9040993          	addi	s3,s0,-368
    80004fca:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fce:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	fb2080e7          	jalr	-78(ra) # 80000f84 <strlen>
    80004fda:	0015079b          	addiw	a5,a0,1
    80004fde:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fe2:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004fe6:	13596663          	bltu	s2,s5,80005112 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fea:	df043d83          	ld	s11,-528(s0)
    80004fee:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ff2:	8552                	mv	a0,s4
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	f90080e7          	jalr	-112(ra) # 80000f84 <strlen>
    80004ffc:	0015069b          	addiw	a3,a0,1
    80005000:	8652                	mv	a2,s4
    80005002:	85ca                	mv	a1,s2
    80005004:	855a                	mv	a0,s6
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	782080e7          	jalr	1922(ra) # 80001788 <copyout>
    8000500e:	10054663          	bltz	a0,8000511a <exec+0x30a>
    ustack[argc] = sp;
    80005012:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005016:	0485                	addi	s1,s1,1
    80005018:	008d8793          	addi	a5,s11,8
    8000501c:	def43823          	sd	a5,-528(s0)
    80005020:	008db503          	ld	a0,8(s11)
    80005024:	c911                	beqz	a0,80005038 <exec+0x228>
    if(argc >= MAXARG)
    80005026:	09a1                	addi	s3,s3,8
    80005028:	fb3c95e3          	bne	s9,s3,80004fd2 <exec+0x1c2>
  sz = sz1;
    8000502c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005030:	4a81                	li	s5,0
    80005032:	a84d                	j	800050e4 <exec+0x2d4>
  sp = sz;
    80005034:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005036:	4481                	li	s1,0
  ustack[argc] = 0;
    80005038:	00349793          	slli	a5,s1,0x3
    8000503c:	f9078793          	addi	a5,a5,-112
    80005040:	97a2                	add	a5,a5,s0
    80005042:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005046:	00148693          	addi	a3,s1,1
    8000504a:	068e                	slli	a3,a3,0x3
    8000504c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005050:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005054:	01597663          	bgeu	s2,s5,80005060 <exec+0x250>
  sz = sz1;
    80005058:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000505c:	4a81                	li	s5,0
    8000505e:	a059                	j	800050e4 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005060:	e9040613          	addi	a2,s0,-368
    80005064:	85ca                	mv	a1,s2
    80005066:	855a                	mv	a0,s6
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	720080e7          	jalr	1824(ra) # 80001788 <copyout>
    80005070:	0a054963          	bltz	a0,80005122 <exec+0x312>
  p->trapframe->a1 = sp;
    80005074:	058bb783          	ld	a5,88(s7)
    80005078:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000507c:	de843783          	ld	a5,-536(s0)
    80005080:	0007c703          	lbu	a4,0(a5)
    80005084:	cf11                	beqz	a4,800050a0 <exec+0x290>
    80005086:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005088:	02f00693          	li	a3,47
    8000508c:	a039                	j	8000509a <exec+0x28a>
      last = s+1;
    8000508e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005092:	0785                	addi	a5,a5,1
    80005094:	fff7c703          	lbu	a4,-1(a5)
    80005098:	c701                	beqz	a4,800050a0 <exec+0x290>
    if(*s == '/')
    8000509a:	fed71ce3          	bne	a4,a3,80005092 <exec+0x282>
    8000509e:	bfc5                	j	8000508e <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800050a0:	4641                	li	a2,16
    800050a2:	de843583          	ld	a1,-536(s0)
    800050a6:	158b8513          	addi	a0,s7,344
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	ea8080e7          	jalr	-344(ra) # 80000f52 <safestrcpy>
  oldpagetable = p->pagetable;
    800050b2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050b6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050ba:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050be:	058bb783          	ld	a5,88(s7)
    800050c2:	e6843703          	ld	a4,-408(s0)
    800050c6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050c8:	058bb783          	ld	a5,88(s7)
    800050cc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050d0:	85ea                	mv	a1,s10
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	b8a080e7          	jalr	-1142(ra) # 80001c5c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050da:	0004851b          	sext.w	a0,s1
    800050de:	b3f9                	j	80004eac <exec+0x9c>
    800050e0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050e4:	df843583          	ld	a1,-520(s0)
    800050e8:	855a                	mv	a0,s6
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	b72080e7          	jalr	-1166(ra) # 80001c5c <proc_freepagetable>
  if(ip){
    800050f2:	da0a93e3          	bnez	s5,80004e98 <exec+0x88>
  return -1;
    800050f6:	557d                	li	a0,-1
    800050f8:	bb55                	j	80004eac <exec+0x9c>
    800050fa:	df243c23          	sd	s2,-520(s0)
    800050fe:	b7dd                	j	800050e4 <exec+0x2d4>
    80005100:	df243c23          	sd	s2,-520(s0)
    80005104:	b7c5                	j	800050e4 <exec+0x2d4>
    80005106:	df243c23          	sd	s2,-520(s0)
    8000510a:	bfe9                	j	800050e4 <exec+0x2d4>
    8000510c:	df243c23          	sd	s2,-520(s0)
    80005110:	bfd1                	j	800050e4 <exec+0x2d4>
  sz = sz1;
    80005112:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005116:	4a81                	li	s5,0
    80005118:	b7f1                	j	800050e4 <exec+0x2d4>
  sz = sz1;
    8000511a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511e:	4a81                	li	s5,0
    80005120:	b7d1                	j	800050e4 <exec+0x2d4>
  sz = sz1;
    80005122:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005126:	4a81                	li	s5,0
    80005128:	bf75                	j	800050e4 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000512a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512e:	e0843783          	ld	a5,-504(s0)
    80005132:	0017869b          	addiw	a3,a5,1
    80005136:	e0d43423          	sd	a3,-504(s0)
    8000513a:	e0043783          	ld	a5,-512(s0)
    8000513e:	0387879b          	addiw	a5,a5,56
    80005142:	e8845703          	lhu	a4,-376(s0)
    80005146:	e0e6dfe3          	bge	a3,a4,80004f64 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000514a:	2781                	sext.w	a5,a5
    8000514c:	e0f43023          	sd	a5,-512(s0)
    80005150:	03800713          	li	a4,56
    80005154:	86be                	mv	a3,a5
    80005156:	e1840613          	addi	a2,s0,-488
    8000515a:	4581                	li	a1,0
    8000515c:	8556                	mv	a0,s5
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	a58080e7          	jalr	-1448(ra) # 80003bb6 <readi>
    80005166:	03800793          	li	a5,56
    8000516a:	f6f51be3          	bne	a0,a5,800050e0 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000516e:	e1842783          	lw	a5,-488(s0)
    80005172:	4705                	li	a4,1
    80005174:	fae79de3          	bne	a5,a4,8000512e <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005178:	e4043483          	ld	s1,-448(s0)
    8000517c:	e3843783          	ld	a5,-456(s0)
    80005180:	f6f4ede3          	bltu	s1,a5,800050fa <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005184:	e2843783          	ld	a5,-472(s0)
    80005188:	94be                	add	s1,s1,a5
    8000518a:	f6f4ebe3          	bltu	s1,a5,80005100 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000518e:	de043703          	ld	a4,-544(s0)
    80005192:	8ff9                	and	a5,a5,a4
    80005194:	fbad                	bnez	a5,80005106 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005196:	e1c42503          	lw	a0,-484(s0)
    8000519a:	00000097          	auipc	ra,0x0
    8000519e:	c5c080e7          	jalr	-932(ra) # 80004df6 <flags2perm>
    800051a2:	86aa                	mv	a3,a0
    800051a4:	8626                	mv	a2,s1
    800051a6:	85ca                	mv	a1,s2
    800051a8:	855a                	mv	a0,s6
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	39c080e7          	jalr	924(ra) # 80001546 <uvmalloc>
    800051b2:	dea43c23          	sd	a0,-520(s0)
    800051b6:	d939                	beqz	a0,8000510c <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051b8:	e2843c03          	ld	s8,-472(s0)
    800051bc:	e2042c83          	lw	s9,-480(s0)
    800051c0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051c4:	f60b83e3          	beqz	s7,8000512a <exec+0x31a>
    800051c8:	89de                	mv	s3,s7
    800051ca:	4481                	li	s1,0
    800051cc:	bb9d                	j	80004f42 <exec+0x132>

00000000800051ce <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051ce:	7179                	addi	sp,sp,-48
    800051d0:	f406                	sd	ra,40(sp)
    800051d2:	f022                	sd	s0,32(sp)
    800051d4:	ec26                	sd	s1,24(sp)
    800051d6:	e84a                	sd	s2,16(sp)
    800051d8:	1800                	addi	s0,sp,48
    800051da:	892e                	mv	s2,a1
    800051dc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051de:	fdc40593          	addi	a1,s0,-36
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	ad6080e7          	jalr	-1322(ra) # 80002cb8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ea:	fdc42703          	lw	a4,-36(s0)
    800051ee:	47bd                	li	a5,15
    800051f0:	02e7eb63          	bltu	a5,a4,80005226 <argfd+0x58>
    800051f4:	ffffd097          	auipc	ra,0xffffd
    800051f8:	908080e7          	jalr	-1784(ra) # 80001afc <myproc>
    800051fc:	fdc42703          	lw	a4,-36(s0)
    80005200:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbb86a>
    80005204:	078e                	slli	a5,a5,0x3
    80005206:	953e                	add	a0,a0,a5
    80005208:	611c                	ld	a5,0(a0)
    8000520a:	c385                	beqz	a5,8000522a <argfd+0x5c>
    return -1;
  if(pfd)
    8000520c:	00090463          	beqz	s2,80005214 <argfd+0x46>
    *pfd = fd;
    80005210:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005214:	4501                	li	a0,0
  if(pf)
    80005216:	c091                	beqz	s1,8000521a <argfd+0x4c>
    *pf = f;
    80005218:	e09c                	sd	a5,0(s1)
}
    8000521a:	70a2                	ld	ra,40(sp)
    8000521c:	7402                	ld	s0,32(sp)
    8000521e:	64e2                	ld	s1,24(sp)
    80005220:	6942                	ld	s2,16(sp)
    80005222:	6145                	addi	sp,sp,48
    80005224:	8082                	ret
    return -1;
    80005226:	557d                	li	a0,-1
    80005228:	bfcd                	j	8000521a <argfd+0x4c>
    8000522a:	557d                	li	a0,-1
    8000522c:	b7fd                	j	8000521a <argfd+0x4c>

000000008000522e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000522e:	1101                	addi	sp,sp,-32
    80005230:	ec06                	sd	ra,24(sp)
    80005232:	e822                	sd	s0,16(sp)
    80005234:	e426                	sd	s1,8(sp)
    80005236:	1000                	addi	s0,sp,32
    80005238:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	8c2080e7          	jalr	-1854(ra) # 80001afc <myproc>
    80005242:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005244:	0d050793          	addi	a5,a0,208
    80005248:	4501                	li	a0,0
    8000524a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000524c:	6398                	ld	a4,0(a5)
    8000524e:	cb19                	beqz	a4,80005264 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005250:	2505                	addiw	a0,a0,1
    80005252:	07a1                	addi	a5,a5,8
    80005254:	fed51ce3          	bne	a0,a3,8000524c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005258:	557d                	li	a0,-1
}
    8000525a:	60e2                	ld	ra,24(sp)
    8000525c:	6442                	ld	s0,16(sp)
    8000525e:	64a2                	ld	s1,8(sp)
    80005260:	6105                	addi	sp,sp,32
    80005262:	8082                	ret
      p->ofile[fd] = f;
    80005264:	01a50793          	addi	a5,a0,26
    80005268:	078e                	slli	a5,a5,0x3
    8000526a:	963e                	add	a2,a2,a5
    8000526c:	e204                	sd	s1,0(a2)
      return fd;
    8000526e:	b7f5                	j	8000525a <fdalloc+0x2c>

0000000080005270 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005270:	715d                	addi	sp,sp,-80
    80005272:	e486                	sd	ra,72(sp)
    80005274:	e0a2                	sd	s0,64(sp)
    80005276:	fc26                	sd	s1,56(sp)
    80005278:	f84a                	sd	s2,48(sp)
    8000527a:	f44e                	sd	s3,40(sp)
    8000527c:	f052                	sd	s4,32(sp)
    8000527e:	ec56                	sd	s5,24(sp)
    80005280:	e85a                	sd	s6,16(sp)
    80005282:	0880                	addi	s0,sp,80
    80005284:	8b2e                	mv	s6,a1
    80005286:	89b2                	mv	s3,a2
    80005288:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000528a:	fb040593          	addi	a1,s0,-80
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	e3e080e7          	jalr	-450(ra) # 800040cc <nameiparent>
    80005296:	84aa                	mv	s1,a0
    80005298:	14050f63          	beqz	a0,800053f6 <create+0x186>
    return 0;

  ilock(dp);
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	666080e7          	jalr	1638(ra) # 80003902 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052a4:	4601                	li	a2,0
    800052a6:	fb040593          	addi	a1,s0,-80
    800052aa:	8526                	mv	a0,s1
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	b3a080e7          	jalr	-1222(ra) # 80003de6 <dirlookup>
    800052b4:	8aaa                	mv	s5,a0
    800052b6:	c931                	beqz	a0,8000530a <create+0x9a>
    iunlockput(dp);
    800052b8:	8526                	mv	a0,s1
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	8aa080e7          	jalr	-1878(ra) # 80003b64 <iunlockput>
    ilock(ip);
    800052c2:	8556                	mv	a0,s5
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	63e080e7          	jalr	1598(ra) # 80003902 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052cc:	000b059b          	sext.w	a1,s6
    800052d0:	4789                	li	a5,2
    800052d2:	02f59563          	bne	a1,a5,800052fc <create+0x8c>
    800052d6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbb894>
    800052da:	37f9                	addiw	a5,a5,-2
    800052dc:	17c2                	slli	a5,a5,0x30
    800052de:	93c1                	srli	a5,a5,0x30
    800052e0:	4705                	li	a4,1
    800052e2:	00f76d63          	bltu	a4,a5,800052fc <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052e6:	8556                	mv	a0,s5
    800052e8:	60a6                	ld	ra,72(sp)
    800052ea:	6406                	ld	s0,64(sp)
    800052ec:	74e2                	ld	s1,56(sp)
    800052ee:	7942                	ld	s2,48(sp)
    800052f0:	79a2                	ld	s3,40(sp)
    800052f2:	7a02                	ld	s4,32(sp)
    800052f4:	6ae2                	ld	s5,24(sp)
    800052f6:	6b42                	ld	s6,16(sp)
    800052f8:	6161                	addi	sp,sp,80
    800052fa:	8082                	ret
    iunlockput(ip);
    800052fc:	8556                	mv	a0,s5
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	866080e7          	jalr	-1946(ra) # 80003b64 <iunlockput>
    return 0;
    80005306:	4a81                	li	s5,0
    80005308:	bff9                	j	800052e6 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000530a:	85da                	mv	a1,s6
    8000530c:	4088                	lw	a0,0(s1)
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	456080e7          	jalr	1110(ra) # 80003764 <ialloc>
    80005316:	8a2a                	mv	s4,a0
    80005318:	c539                	beqz	a0,80005366 <create+0xf6>
  ilock(ip);
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	5e8080e7          	jalr	1512(ra) # 80003902 <ilock>
  ip->major = major;
    80005322:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005326:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000532a:	4905                	li	s2,1
    8000532c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005330:	8552                	mv	a0,s4
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	504080e7          	jalr	1284(ra) # 80003836 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000533a:	000b059b          	sext.w	a1,s6
    8000533e:	03258b63          	beq	a1,s2,80005374 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005342:	004a2603          	lw	a2,4(s4)
    80005346:	fb040593          	addi	a1,s0,-80
    8000534a:	8526                	mv	a0,s1
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	cb0080e7          	jalr	-848(ra) # 80003ffc <dirlink>
    80005354:	06054f63          	bltz	a0,800053d2 <create+0x162>
  iunlockput(dp);
    80005358:	8526                	mv	a0,s1
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	80a080e7          	jalr	-2038(ra) # 80003b64 <iunlockput>
  return ip;
    80005362:	8ad2                	mv	s5,s4
    80005364:	b749                	j	800052e6 <create+0x76>
    iunlockput(dp);
    80005366:	8526                	mv	a0,s1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	7fc080e7          	jalr	2044(ra) # 80003b64 <iunlockput>
    return 0;
    80005370:	8ad2                	mv	s5,s4
    80005372:	bf95                	j	800052e6 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005374:	004a2603          	lw	a2,4(s4)
    80005378:	00003597          	auipc	a1,0x3
    8000537c:	56058593          	addi	a1,a1,1376 # 800088d8 <names+0x2b0>
    80005380:	8552                	mv	a0,s4
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	c7a080e7          	jalr	-902(ra) # 80003ffc <dirlink>
    8000538a:	04054463          	bltz	a0,800053d2 <create+0x162>
    8000538e:	40d0                	lw	a2,4(s1)
    80005390:	00003597          	auipc	a1,0x3
    80005394:	55058593          	addi	a1,a1,1360 # 800088e0 <names+0x2b8>
    80005398:	8552                	mv	a0,s4
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	c62080e7          	jalr	-926(ra) # 80003ffc <dirlink>
    800053a2:	02054863          	bltz	a0,800053d2 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800053a6:	004a2603          	lw	a2,4(s4)
    800053aa:	fb040593          	addi	a1,s0,-80
    800053ae:	8526                	mv	a0,s1
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	c4c080e7          	jalr	-948(ra) # 80003ffc <dirlink>
    800053b8:	00054d63          	bltz	a0,800053d2 <create+0x162>
    dp->nlink++;  // for ".."
    800053bc:	04a4d783          	lhu	a5,74(s1)
    800053c0:	2785                	addiw	a5,a5,1
    800053c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	46e080e7          	jalr	1134(ra) # 80003836 <iupdate>
    800053d0:	b761                	j	80005358 <create+0xe8>
  ip->nlink = 0;
    800053d2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053d6:	8552                	mv	a0,s4
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	45e080e7          	jalr	1118(ra) # 80003836 <iupdate>
  iunlockput(ip);
    800053e0:	8552                	mv	a0,s4
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	782080e7          	jalr	1922(ra) # 80003b64 <iunlockput>
  iunlockput(dp);
    800053ea:	8526                	mv	a0,s1
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	778080e7          	jalr	1912(ra) # 80003b64 <iunlockput>
  return 0;
    800053f4:	bdcd                	j	800052e6 <create+0x76>
    return 0;
    800053f6:	8aaa                	mv	s5,a0
    800053f8:	b5fd                	j	800052e6 <create+0x76>

00000000800053fa <sys_dup>:
{
    800053fa:	7179                	addi	sp,sp,-48
    800053fc:	f406                	sd	ra,40(sp)
    800053fe:	f022                	sd	s0,32(sp)
    80005400:	ec26                	sd	s1,24(sp)
    80005402:	e84a                	sd	s2,16(sp)
    80005404:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005406:	fd840613          	addi	a2,s0,-40
    8000540a:	4581                	li	a1,0
    8000540c:	4501                	li	a0,0
    8000540e:	00000097          	auipc	ra,0x0
    80005412:	dc0080e7          	jalr	-576(ra) # 800051ce <argfd>
    return -1;
    80005416:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005418:	02054363          	bltz	a0,8000543e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000541c:	fd843903          	ld	s2,-40(s0)
    80005420:	854a                	mv	a0,s2
    80005422:	00000097          	auipc	ra,0x0
    80005426:	e0c080e7          	jalr	-500(ra) # 8000522e <fdalloc>
    8000542a:	84aa                	mv	s1,a0
    return -1;
    8000542c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000542e:	00054863          	bltz	a0,8000543e <sys_dup+0x44>
  filedup(f);
    80005432:	854a                	mv	a0,s2
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	310080e7          	jalr	784(ra) # 80004744 <filedup>
  return fd;
    8000543c:	87a6                	mv	a5,s1
}
    8000543e:	853e                	mv	a0,a5
    80005440:	70a2                	ld	ra,40(sp)
    80005442:	7402                	ld	s0,32(sp)
    80005444:	64e2                	ld	s1,24(sp)
    80005446:	6942                	ld	s2,16(sp)
    80005448:	6145                	addi	sp,sp,48
    8000544a:	8082                	ret

000000008000544c <sys_read>:
{
    8000544c:	7179                	addi	sp,sp,-48
    8000544e:	f406                	sd	ra,40(sp)
    80005450:	f022                	sd	s0,32(sp)
    80005452:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005454:	fd840593          	addi	a1,s0,-40
    80005458:	4505                	li	a0,1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	87e080e7          	jalr	-1922(ra) # 80002cd8 <argaddr>
  argint(2, &n);
    80005462:	fe440593          	addi	a1,s0,-28
    80005466:	4509                	li	a0,2
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	850080e7          	jalr	-1968(ra) # 80002cb8 <argint>
  if(argfd(0, 0, &f) < 0)
    80005470:	fe840613          	addi	a2,s0,-24
    80005474:	4581                	li	a1,0
    80005476:	4501                	li	a0,0
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	d56080e7          	jalr	-682(ra) # 800051ce <argfd>
    80005480:	87aa                	mv	a5,a0
    return -1;
    80005482:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005484:	0007cc63          	bltz	a5,8000549c <sys_read+0x50>
  return fileread(f, p, n);
    80005488:	fe442603          	lw	a2,-28(s0)
    8000548c:	fd843583          	ld	a1,-40(s0)
    80005490:	fe843503          	ld	a0,-24(s0)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	43c080e7          	jalr	1084(ra) # 800048d0 <fileread>
}
    8000549c:	70a2                	ld	ra,40(sp)
    8000549e:	7402                	ld	s0,32(sp)
    800054a0:	6145                	addi	sp,sp,48
    800054a2:	8082                	ret

00000000800054a4 <sys_write>:
{
    800054a4:	7179                	addi	sp,sp,-48
    800054a6:	f406                	sd	ra,40(sp)
    800054a8:	f022                	sd	s0,32(sp)
    800054aa:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054ac:	fd840593          	addi	a1,s0,-40
    800054b0:	4505                	li	a0,1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	826080e7          	jalr	-2010(ra) # 80002cd8 <argaddr>
  argint(2, &n);
    800054ba:	fe440593          	addi	a1,s0,-28
    800054be:	4509                	li	a0,2
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	7f8080e7          	jalr	2040(ra) # 80002cb8 <argint>
  if(argfd(0, 0, &f) < 0)
    800054c8:	fe840613          	addi	a2,s0,-24
    800054cc:	4581                	li	a1,0
    800054ce:	4501                	li	a0,0
    800054d0:	00000097          	auipc	ra,0x0
    800054d4:	cfe080e7          	jalr	-770(ra) # 800051ce <argfd>
    800054d8:	87aa                	mv	a5,a0
    return -1;
    800054da:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054dc:	0007cc63          	bltz	a5,800054f4 <sys_write+0x50>
  return filewrite(f, p, n);
    800054e0:	fe442603          	lw	a2,-28(s0)
    800054e4:	fd843583          	ld	a1,-40(s0)
    800054e8:	fe843503          	ld	a0,-24(s0)
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	4a6080e7          	jalr	1190(ra) # 80004992 <filewrite>
}
    800054f4:	70a2                	ld	ra,40(sp)
    800054f6:	7402                	ld	s0,32(sp)
    800054f8:	6145                	addi	sp,sp,48
    800054fa:	8082                	ret

00000000800054fc <sys_close>:
{
    800054fc:	1101                	addi	sp,sp,-32
    800054fe:	ec06                	sd	ra,24(sp)
    80005500:	e822                	sd	s0,16(sp)
    80005502:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005504:	fe040613          	addi	a2,s0,-32
    80005508:	fec40593          	addi	a1,s0,-20
    8000550c:	4501                	li	a0,0
    8000550e:	00000097          	auipc	ra,0x0
    80005512:	cc0080e7          	jalr	-832(ra) # 800051ce <argfd>
    return -1;
    80005516:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005518:	02054463          	bltz	a0,80005540 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000551c:	ffffc097          	auipc	ra,0xffffc
    80005520:	5e0080e7          	jalr	1504(ra) # 80001afc <myproc>
    80005524:	fec42783          	lw	a5,-20(s0)
    80005528:	07e9                	addi	a5,a5,26
    8000552a:	078e                	slli	a5,a5,0x3
    8000552c:	953e                	add	a0,a0,a5
    8000552e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005532:	fe043503          	ld	a0,-32(s0)
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	260080e7          	jalr	608(ra) # 80004796 <fileclose>
  return 0;
    8000553e:	4781                	li	a5,0
}
    80005540:	853e                	mv	a0,a5
    80005542:	60e2                	ld	ra,24(sp)
    80005544:	6442                	ld	s0,16(sp)
    80005546:	6105                	addi	sp,sp,32
    80005548:	8082                	ret

000000008000554a <sys_fstat>:
{
    8000554a:	1101                	addi	sp,sp,-32
    8000554c:	ec06                	sd	ra,24(sp)
    8000554e:	e822                	sd	s0,16(sp)
    80005550:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005552:	fe040593          	addi	a1,s0,-32
    80005556:	4505                	li	a0,1
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	780080e7          	jalr	1920(ra) # 80002cd8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005560:	fe840613          	addi	a2,s0,-24
    80005564:	4581                	li	a1,0
    80005566:	4501                	li	a0,0
    80005568:	00000097          	auipc	ra,0x0
    8000556c:	c66080e7          	jalr	-922(ra) # 800051ce <argfd>
    80005570:	87aa                	mv	a5,a0
    return -1;
    80005572:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005574:	0007ca63          	bltz	a5,80005588 <sys_fstat+0x3e>
  return filestat(f, st);
    80005578:	fe043583          	ld	a1,-32(s0)
    8000557c:	fe843503          	ld	a0,-24(s0)
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	2de080e7          	jalr	734(ra) # 8000485e <filestat>
}
    80005588:	60e2                	ld	ra,24(sp)
    8000558a:	6442                	ld	s0,16(sp)
    8000558c:	6105                	addi	sp,sp,32
    8000558e:	8082                	ret

0000000080005590 <sys_link>:
{
    80005590:	7169                	addi	sp,sp,-304
    80005592:	f606                	sd	ra,296(sp)
    80005594:	f222                	sd	s0,288(sp)
    80005596:	ee26                	sd	s1,280(sp)
    80005598:	ea4a                	sd	s2,272(sp)
    8000559a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000559c:	08000613          	li	a2,128
    800055a0:	ed040593          	addi	a1,s0,-304
    800055a4:	4501                	li	a0,0
    800055a6:	ffffd097          	auipc	ra,0xffffd
    800055aa:	752080e7          	jalr	1874(ra) # 80002cf8 <argstr>
    return -1;
    800055ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b0:	10054e63          	bltz	a0,800056cc <sys_link+0x13c>
    800055b4:	08000613          	li	a2,128
    800055b8:	f5040593          	addi	a1,s0,-176
    800055bc:	4505                	li	a0,1
    800055be:	ffffd097          	auipc	ra,0xffffd
    800055c2:	73a080e7          	jalr	1850(ra) # 80002cf8 <argstr>
    return -1;
    800055c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c8:	10054263          	bltz	a0,800056cc <sys_link+0x13c>
  begin_op();
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	d02080e7          	jalr	-766(ra) # 800042ce <begin_op>
  if((ip = namei(old)) == 0){
    800055d4:	ed040513          	addi	a0,s0,-304
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	ad6080e7          	jalr	-1322(ra) # 800040ae <namei>
    800055e0:	84aa                	mv	s1,a0
    800055e2:	c551                	beqz	a0,8000566e <sys_link+0xde>
  ilock(ip);
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	31e080e7          	jalr	798(ra) # 80003902 <ilock>
  if(ip->type == T_DIR){
    800055ec:	04449703          	lh	a4,68(s1)
    800055f0:	4785                	li	a5,1
    800055f2:	08f70463          	beq	a4,a5,8000567a <sys_link+0xea>
  ip->nlink++;
    800055f6:	04a4d783          	lhu	a5,74(s1)
    800055fa:	2785                	addiw	a5,a5,1
    800055fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	234080e7          	jalr	564(ra) # 80003836 <iupdate>
  iunlock(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	3b8080e7          	jalr	952(ra) # 800039c4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005614:	fd040593          	addi	a1,s0,-48
    80005618:	f5040513          	addi	a0,s0,-176
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	ab0080e7          	jalr	-1360(ra) # 800040cc <nameiparent>
    80005624:	892a                	mv	s2,a0
    80005626:	c935                	beqz	a0,8000569a <sys_link+0x10a>
  ilock(dp);
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	2da080e7          	jalr	730(ra) # 80003902 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005630:	00092703          	lw	a4,0(s2)
    80005634:	409c                	lw	a5,0(s1)
    80005636:	04f71d63          	bne	a4,a5,80005690 <sys_link+0x100>
    8000563a:	40d0                	lw	a2,4(s1)
    8000563c:	fd040593          	addi	a1,s0,-48
    80005640:	854a                	mv	a0,s2
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	9ba080e7          	jalr	-1606(ra) # 80003ffc <dirlink>
    8000564a:	04054363          	bltz	a0,80005690 <sys_link+0x100>
  iunlockput(dp);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	514080e7          	jalr	1300(ra) # 80003b64 <iunlockput>
  iput(ip);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	462080e7          	jalr	1122(ra) # 80003abc <iput>
  end_op();
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	cea080e7          	jalr	-790(ra) # 8000434c <end_op>
  return 0;
    8000566a:	4781                	li	a5,0
    8000566c:	a085                	j	800056cc <sys_link+0x13c>
    end_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	cde080e7          	jalr	-802(ra) # 8000434c <end_op>
    return -1;
    80005676:	57fd                	li	a5,-1
    80005678:	a891                	j	800056cc <sys_link+0x13c>
    iunlockput(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	4e8080e7          	jalr	1256(ra) # 80003b64 <iunlockput>
    end_op();
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	cc8080e7          	jalr	-824(ra) # 8000434c <end_op>
    return -1;
    8000568c:	57fd                	li	a5,-1
    8000568e:	a83d                	j	800056cc <sys_link+0x13c>
    iunlockput(dp);
    80005690:	854a                	mv	a0,s2
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	4d2080e7          	jalr	1234(ra) # 80003b64 <iunlockput>
  ilock(ip);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	266080e7          	jalr	614(ra) # 80003902 <ilock>
  ip->nlink--;
    800056a4:	04a4d783          	lhu	a5,74(s1)
    800056a8:	37fd                	addiw	a5,a5,-1
    800056aa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	186080e7          	jalr	390(ra) # 80003836 <iupdate>
  iunlockput(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	4aa080e7          	jalr	1194(ra) # 80003b64 <iunlockput>
  end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	c8a080e7          	jalr	-886(ra) # 8000434c <end_op>
  return -1;
    800056ca:	57fd                	li	a5,-1
}
    800056cc:	853e                	mv	a0,a5
    800056ce:	70b2                	ld	ra,296(sp)
    800056d0:	7412                	ld	s0,288(sp)
    800056d2:	64f2                	ld	s1,280(sp)
    800056d4:	6952                	ld	s2,272(sp)
    800056d6:	6155                	addi	sp,sp,304
    800056d8:	8082                	ret

00000000800056da <sys_unlink>:
{
    800056da:	7151                	addi	sp,sp,-240
    800056dc:	f586                	sd	ra,232(sp)
    800056de:	f1a2                	sd	s0,224(sp)
    800056e0:	eda6                	sd	s1,216(sp)
    800056e2:	e9ca                	sd	s2,208(sp)
    800056e4:	e5ce                	sd	s3,200(sp)
    800056e6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056e8:	08000613          	li	a2,128
    800056ec:	f3040593          	addi	a1,s0,-208
    800056f0:	4501                	li	a0,0
    800056f2:	ffffd097          	auipc	ra,0xffffd
    800056f6:	606080e7          	jalr	1542(ra) # 80002cf8 <argstr>
    800056fa:	18054163          	bltz	a0,8000587c <sys_unlink+0x1a2>
  begin_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	bd0080e7          	jalr	-1072(ra) # 800042ce <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005706:	fb040593          	addi	a1,s0,-80
    8000570a:	f3040513          	addi	a0,s0,-208
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	9be080e7          	jalr	-1602(ra) # 800040cc <nameiparent>
    80005716:	84aa                	mv	s1,a0
    80005718:	c979                	beqz	a0,800057ee <sys_unlink+0x114>
  ilock(dp);
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	1e8080e7          	jalr	488(ra) # 80003902 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005722:	00003597          	auipc	a1,0x3
    80005726:	1b658593          	addi	a1,a1,438 # 800088d8 <names+0x2b0>
    8000572a:	fb040513          	addi	a0,s0,-80
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	69e080e7          	jalr	1694(ra) # 80003dcc <namecmp>
    80005736:	14050a63          	beqz	a0,8000588a <sys_unlink+0x1b0>
    8000573a:	00003597          	auipc	a1,0x3
    8000573e:	1a658593          	addi	a1,a1,422 # 800088e0 <names+0x2b8>
    80005742:	fb040513          	addi	a0,s0,-80
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	686080e7          	jalr	1670(ra) # 80003dcc <namecmp>
    8000574e:	12050e63          	beqz	a0,8000588a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005752:	f2c40613          	addi	a2,s0,-212
    80005756:	fb040593          	addi	a1,s0,-80
    8000575a:	8526                	mv	a0,s1
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	68a080e7          	jalr	1674(ra) # 80003de6 <dirlookup>
    80005764:	892a                	mv	s2,a0
    80005766:	12050263          	beqz	a0,8000588a <sys_unlink+0x1b0>
  ilock(ip);
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	198080e7          	jalr	408(ra) # 80003902 <ilock>
  if(ip->nlink < 1)
    80005772:	04a91783          	lh	a5,74(s2)
    80005776:	08f05263          	blez	a5,800057fa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000577a:	04491703          	lh	a4,68(s2)
    8000577e:	4785                	li	a5,1
    80005780:	08f70563          	beq	a4,a5,8000580a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005784:	4641                	li	a2,16
    80005786:	4581                	li	a1,0
    80005788:	fc040513          	addi	a0,s0,-64
    8000578c:	ffffb097          	auipc	ra,0xffffb
    80005790:	67c080e7          	jalr	1660(ra) # 80000e08 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005794:	4741                	li	a4,16
    80005796:	f2c42683          	lw	a3,-212(s0)
    8000579a:	fc040613          	addi	a2,s0,-64
    8000579e:	4581                	li	a1,0
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	50c080e7          	jalr	1292(ra) # 80003cae <writei>
    800057aa:	47c1                	li	a5,16
    800057ac:	0af51563          	bne	a0,a5,80005856 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057b0:	04491703          	lh	a4,68(s2)
    800057b4:	4785                	li	a5,1
    800057b6:	0af70863          	beq	a4,a5,80005866 <sys_unlink+0x18c>
  iunlockput(dp);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	3a8080e7          	jalr	936(ra) # 80003b64 <iunlockput>
  ip->nlink--;
    800057c4:	04a95783          	lhu	a5,74(s2)
    800057c8:	37fd                	addiw	a5,a5,-1
    800057ca:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057ce:	854a                	mv	a0,s2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	066080e7          	jalr	102(ra) # 80003836 <iupdate>
  iunlockput(ip);
    800057d8:	854a                	mv	a0,s2
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	38a080e7          	jalr	906(ra) # 80003b64 <iunlockput>
  end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	b6a080e7          	jalr	-1174(ra) # 8000434c <end_op>
  return 0;
    800057ea:	4501                	li	a0,0
    800057ec:	a84d                	j	8000589e <sys_unlink+0x1c4>
    end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	b5e080e7          	jalr	-1186(ra) # 8000434c <end_op>
    return -1;
    800057f6:	557d                	li	a0,-1
    800057f8:	a05d                	j	8000589e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057fa:	00003517          	auipc	a0,0x3
    800057fe:	0ee50513          	addi	a0,a0,238 # 800088e8 <names+0x2c0>
    80005802:	ffffb097          	auipc	ra,0xffffb
    80005806:	d3e080e7          	jalr	-706(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000580a:	04c92703          	lw	a4,76(s2)
    8000580e:	02000793          	li	a5,32
    80005812:	f6e7f9e3          	bgeu	a5,a4,80005784 <sys_unlink+0xaa>
    80005816:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000581a:	4741                	li	a4,16
    8000581c:	86ce                	mv	a3,s3
    8000581e:	f1840613          	addi	a2,s0,-232
    80005822:	4581                	li	a1,0
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	390080e7          	jalr	912(ra) # 80003bb6 <readi>
    8000582e:	47c1                	li	a5,16
    80005830:	00f51b63          	bne	a0,a5,80005846 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005834:	f1845783          	lhu	a5,-232(s0)
    80005838:	e7a1                	bnez	a5,80005880 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000583a:	29c1                	addiw	s3,s3,16
    8000583c:	04c92783          	lw	a5,76(s2)
    80005840:	fcf9ede3          	bltu	s3,a5,8000581a <sys_unlink+0x140>
    80005844:	b781                	j	80005784 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005846:	00003517          	auipc	a0,0x3
    8000584a:	0ba50513          	addi	a0,a0,186 # 80008900 <names+0x2d8>
    8000584e:	ffffb097          	auipc	ra,0xffffb
    80005852:	cf2080e7          	jalr	-782(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005856:	00003517          	auipc	a0,0x3
    8000585a:	0c250513          	addi	a0,a0,194 # 80008918 <names+0x2f0>
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	ce2080e7          	jalr	-798(ra) # 80000540 <panic>
    dp->nlink--;
    80005866:	04a4d783          	lhu	a5,74(s1)
    8000586a:	37fd                	addiw	a5,a5,-1
    8000586c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	fc4080e7          	jalr	-60(ra) # 80003836 <iupdate>
    8000587a:	b781                	j	800057ba <sys_unlink+0xe0>
    return -1;
    8000587c:	557d                	li	a0,-1
    8000587e:	a005                	j	8000589e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	2e2080e7          	jalr	738(ra) # 80003b64 <iunlockput>
  iunlockput(dp);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	2d8080e7          	jalr	728(ra) # 80003b64 <iunlockput>
  end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	ab8080e7          	jalr	-1352(ra) # 8000434c <end_op>
  return -1;
    8000589c:	557d                	li	a0,-1
}
    8000589e:	70ae                	ld	ra,232(sp)
    800058a0:	740e                	ld	s0,224(sp)
    800058a2:	64ee                	ld	s1,216(sp)
    800058a4:	694e                	ld	s2,208(sp)
    800058a6:	69ae                	ld	s3,200(sp)
    800058a8:	616d                	addi	sp,sp,240
    800058aa:	8082                	ret

00000000800058ac <sys_open>:

uint64
sys_open(void)
{
    800058ac:	7131                	addi	sp,sp,-192
    800058ae:	fd06                	sd	ra,184(sp)
    800058b0:	f922                	sd	s0,176(sp)
    800058b2:	f526                	sd	s1,168(sp)
    800058b4:	f14a                	sd	s2,160(sp)
    800058b6:	ed4e                	sd	s3,152(sp)
    800058b8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058ba:	f4c40593          	addi	a1,s0,-180
    800058be:	4505                	li	a0,1
    800058c0:	ffffd097          	auipc	ra,0xffffd
    800058c4:	3f8080e7          	jalr	1016(ra) # 80002cb8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058c8:	08000613          	li	a2,128
    800058cc:	f5040593          	addi	a1,s0,-176
    800058d0:	4501                	li	a0,0
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	426080e7          	jalr	1062(ra) # 80002cf8 <argstr>
    800058da:	87aa                	mv	a5,a0
    return -1;
    800058dc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058de:	0a07c963          	bltz	a5,80005990 <sys_open+0xe4>

  begin_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	9ec080e7          	jalr	-1556(ra) # 800042ce <begin_op>

  if(omode & O_CREATE){
    800058ea:	f4c42783          	lw	a5,-180(s0)
    800058ee:	2007f793          	andi	a5,a5,512
    800058f2:	cfc5                	beqz	a5,800059aa <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058f4:	4681                	li	a3,0
    800058f6:	4601                	li	a2,0
    800058f8:	4589                	li	a1,2
    800058fa:	f5040513          	addi	a0,s0,-176
    800058fe:	00000097          	auipc	ra,0x0
    80005902:	972080e7          	jalr	-1678(ra) # 80005270 <create>
    80005906:	84aa                	mv	s1,a0
    if(ip == 0){
    80005908:	c959                	beqz	a0,8000599e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000590a:	04449703          	lh	a4,68(s1)
    8000590e:	478d                	li	a5,3
    80005910:	00f71763          	bne	a4,a5,8000591e <sys_open+0x72>
    80005914:	0464d703          	lhu	a4,70(s1)
    80005918:	47a5                	li	a5,9
    8000591a:	0ce7ed63          	bltu	a5,a4,800059f4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	dbc080e7          	jalr	-580(ra) # 800046da <filealloc>
    80005926:	89aa                	mv	s3,a0
    80005928:	10050363          	beqz	a0,80005a2e <sys_open+0x182>
    8000592c:	00000097          	auipc	ra,0x0
    80005930:	902080e7          	jalr	-1790(ra) # 8000522e <fdalloc>
    80005934:	892a                	mv	s2,a0
    80005936:	0e054763          	bltz	a0,80005a24 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000593a:	04449703          	lh	a4,68(s1)
    8000593e:	478d                	li	a5,3
    80005940:	0cf70563          	beq	a4,a5,80005a0a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005944:	4789                	li	a5,2
    80005946:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000594a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000594e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005952:	f4c42783          	lw	a5,-180(s0)
    80005956:	0017c713          	xori	a4,a5,1
    8000595a:	8b05                	andi	a4,a4,1
    8000595c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005960:	0037f713          	andi	a4,a5,3
    80005964:	00e03733          	snez	a4,a4
    80005968:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000596c:	4007f793          	andi	a5,a5,1024
    80005970:	c791                	beqz	a5,8000597c <sys_open+0xd0>
    80005972:	04449703          	lh	a4,68(s1)
    80005976:	4789                	li	a5,2
    80005978:	0af70063          	beq	a4,a5,80005a18 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	046080e7          	jalr	70(ra) # 800039c4 <iunlock>
  end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	9c6080e7          	jalr	-1594(ra) # 8000434c <end_op>

  return fd;
    8000598e:	854a                	mv	a0,s2
}
    80005990:	70ea                	ld	ra,184(sp)
    80005992:	744a                	ld	s0,176(sp)
    80005994:	74aa                	ld	s1,168(sp)
    80005996:	790a                	ld	s2,160(sp)
    80005998:	69ea                	ld	s3,152(sp)
    8000599a:	6129                	addi	sp,sp,192
    8000599c:	8082                	ret
      end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	9ae080e7          	jalr	-1618(ra) # 8000434c <end_op>
      return -1;
    800059a6:	557d                	li	a0,-1
    800059a8:	b7e5                	j	80005990 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059aa:	f5040513          	addi	a0,s0,-176
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	700080e7          	jalr	1792(ra) # 800040ae <namei>
    800059b6:	84aa                	mv	s1,a0
    800059b8:	c905                	beqz	a0,800059e8 <sys_open+0x13c>
    ilock(ip);
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	f48080e7          	jalr	-184(ra) # 80003902 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059c2:	04449703          	lh	a4,68(s1)
    800059c6:	4785                	li	a5,1
    800059c8:	f4f711e3          	bne	a4,a5,8000590a <sys_open+0x5e>
    800059cc:	f4c42783          	lw	a5,-180(s0)
    800059d0:	d7b9                	beqz	a5,8000591e <sys_open+0x72>
      iunlockput(ip);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	190080e7          	jalr	400(ra) # 80003b64 <iunlockput>
      end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	970080e7          	jalr	-1680(ra) # 8000434c <end_op>
      return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b76d                	j	80005990 <sys_open+0xe4>
      end_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	964080e7          	jalr	-1692(ra) # 8000434c <end_op>
      return -1;
    800059f0:	557d                	li	a0,-1
    800059f2:	bf79                	j	80005990 <sys_open+0xe4>
    iunlockput(ip);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	16e080e7          	jalr	366(ra) # 80003b64 <iunlockput>
    end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	94e080e7          	jalr	-1714(ra) # 8000434c <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	b761                	j	80005990 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a0a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a0e:	04649783          	lh	a5,70(s1)
    80005a12:	02f99223          	sh	a5,36(s3)
    80005a16:	bf25                	j	8000594e <sys_open+0xa2>
    itrunc(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	ff6080e7          	jalr	-10(ra) # 80003a10 <itrunc>
    80005a22:	bfa9                	j	8000597c <sys_open+0xd0>
      fileclose(f);
    80005a24:	854e                	mv	a0,s3
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	d70080e7          	jalr	-656(ra) # 80004796 <fileclose>
    iunlockput(ip);
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	134080e7          	jalr	308(ra) # 80003b64 <iunlockput>
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	914080e7          	jalr	-1772(ra) # 8000434c <end_op>
    return -1;
    80005a40:	557d                	li	a0,-1
    80005a42:	b7b9                	j	80005990 <sys_open+0xe4>

0000000080005a44 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a44:	7175                	addi	sp,sp,-144
    80005a46:	e506                	sd	ra,136(sp)
    80005a48:	e122                	sd	s0,128(sp)
    80005a4a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	882080e7          	jalr	-1918(ra) # 800042ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a54:	08000613          	li	a2,128
    80005a58:	f7040593          	addi	a1,s0,-144
    80005a5c:	4501                	li	a0,0
    80005a5e:	ffffd097          	auipc	ra,0xffffd
    80005a62:	29a080e7          	jalr	666(ra) # 80002cf8 <argstr>
    80005a66:	02054963          	bltz	a0,80005a98 <sys_mkdir+0x54>
    80005a6a:	4681                	li	a3,0
    80005a6c:	4601                	li	a2,0
    80005a6e:	4585                	li	a1,1
    80005a70:	f7040513          	addi	a0,s0,-144
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	7fc080e7          	jalr	2044(ra) # 80005270 <create>
    80005a7c:	cd11                	beqz	a0,80005a98 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	0e6080e7          	jalr	230(ra) # 80003b64 <iunlockput>
  end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	8c6080e7          	jalr	-1850(ra) # 8000434c <end_op>
  return 0;
    80005a8e:	4501                	li	a0,0
}
    80005a90:	60aa                	ld	ra,136(sp)
    80005a92:	640a                	ld	s0,128(sp)
    80005a94:	6149                	addi	sp,sp,144
    80005a96:	8082                	ret
    end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	8b4080e7          	jalr	-1868(ra) # 8000434c <end_op>
    return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	b7fd                	j	80005a90 <sys_mkdir+0x4c>

0000000080005aa4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005aa4:	7135                	addi	sp,sp,-160
    80005aa6:	ed06                	sd	ra,152(sp)
    80005aa8:	e922                	sd	s0,144(sp)
    80005aaa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	822080e7          	jalr	-2014(ra) # 800042ce <begin_op>
  argint(1, &major);
    80005ab4:	f6c40593          	addi	a1,s0,-148
    80005ab8:	4505                	li	a0,1
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	1fe080e7          	jalr	510(ra) # 80002cb8 <argint>
  argint(2, &minor);
    80005ac2:	f6840593          	addi	a1,s0,-152
    80005ac6:	4509                	li	a0,2
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	1f0080e7          	jalr	496(ra) # 80002cb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ad0:	08000613          	li	a2,128
    80005ad4:	f7040593          	addi	a1,s0,-144
    80005ad8:	4501                	li	a0,0
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	21e080e7          	jalr	542(ra) # 80002cf8 <argstr>
    80005ae2:	02054b63          	bltz	a0,80005b18 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ae6:	f6841683          	lh	a3,-152(s0)
    80005aea:	f6c41603          	lh	a2,-148(s0)
    80005aee:	458d                	li	a1,3
    80005af0:	f7040513          	addi	a0,s0,-144
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	77c080e7          	jalr	1916(ra) # 80005270 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005afc:	cd11                	beqz	a0,80005b18 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	066080e7          	jalr	102(ra) # 80003b64 <iunlockput>
  end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	846080e7          	jalr	-1978(ra) # 8000434c <end_op>
  return 0;
    80005b0e:	4501                	li	a0,0
}
    80005b10:	60ea                	ld	ra,152(sp)
    80005b12:	644a                	ld	s0,144(sp)
    80005b14:	610d                	addi	sp,sp,160
    80005b16:	8082                	ret
    end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	834080e7          	jalr	-1996(ra) # 8000434c <end_op>
    return -1;
    80005b20:	557d                	li	a0,-1
    80005b22:	b7fd                	j	80005b10 <sys_mknod+0x6c>

0000000080005b24 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b24:	7135                	addi	sp,sp,-160
    80005b26:	ed06                	sd	ra,152(sp)
    80005b28:	e922                	sd	s0,144(sp)
    80005b2a:	e526                	sd	s1,136(sp)
    80005b2c:	e14a                	sd	s2,128(sp)
    80005b2e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	fcc080e7          	jalr	-52(ra) # 80001afc <myproc>
    80005b38:	892a                	mv	s2,a0
  
  begin_op();
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	794080e7          	jalr	1940(ra) # 800042ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b42:	08000613          	li	a2,128
    80005b46:	f6040593          	addi	a1,s0,-160
    80005b4a:	4501                	li	a0,0
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	1ac080e7          	jalr	428(ra) # 80002cf8 <argstr>
    80005b54:	04054b63          	bltz	a0,80005baa <sys_chdir+0x86>
    80005b58:	f6040513          	addi	a0,s0,-160
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	552080e7          	jalr	1362(ra) # 800040ae <namei>
    80005b64:	84aa                	mv	s1,a0
    80005b66:	c131                	beqz	a0,80005baa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	d9a080e7          	jalr	-614(ra) # 80003902 <ilock>
  if(ip->type != T_DIR){
    80005b70:	04449703          	lh	a4,68(s1)
    80005b74:	4785                	li	a5,1
    80005b76:	04f71063          	bne	a4,a5,80005bb6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	e48080e7          	jalr	-440(ra) # 800039c4 <iunlock>
  iput(p->cwd);
    80005b84:	15093503          	ld	a0,336(s2)
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	f34080e7          	jalr	-204(ra) # 80003abc <iput>
  end_op();
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	7bc080e7          	jalr	1980(ra) # 8000434c <end_op>
  p->cwd = ip;
    80005b98:	14993823          	sd	s1,336(s2)
  return 0;
    80005b9c:	4501                	li	a0,0
}
    80005b9e:	60ea                	ld	ra,152(sp)
    80005ba0:	644a                	ld	s0,144(sp)
    80005ba2:	64aa                	ld	s1,136(sp)
    80005ba4:	690a                	ld	s2,128(sp)
    80005ba6:	610d                	addi	sp,sp,160
    80005ba8:	8082                	ret
    end_op();
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	7a2080e7          	jalr	1954(ra) # 8000434c <end_op>
    return -1;
    80005bb2:	557d                	li	a0,-1
    80005bb4:	b7ed                	j	80005b9e <sys_chdir+0x7a>
    iunlockput(ip);
    80005bb6:	8526                	mv	a0,s1
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	fac080e7          	jalr	-84(ra) # 80003b64 <iunlockput>
    end_op();
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	78c080e7          	jalr	1932(ra) # 8000434c <end_op>
    return -1;
    80005bc8:	557d                	li	a0,-1
    80005bca:	bfd1                	j	80005b9e <sys_chdir+0x7a>

0000000080005bcc <sys_exec>:

uint64
sys_exec(void)
{
    80005bcc:	7145                	addi	sp,sp,-464
    80005bce:	e786                	sd	ra,456(sp)
    80005bd0:	e3a2                	sd	s0,448(sp)
    80005bd2:	ff26                	sd	s1,440(sp)
    80005bd4:	fb4a                	sd	s2,432(sp)
    80005bd6:	f74e                	sd	s3,424(sp)
    80005bd8:	f352                	sd	s4,416(sp)
    80005bda:	ef56                	sd	s5,408(sp)
    80005bdc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005bde:	e3840593          	addi	a1,s0,-456
    80005be2:	4505                	li	a0,1
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	0f4080e7          	jalr	244(ra) # 80002cd8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bec:	08000613          	li	a2,128
    80005bf0:	f4040593          	addi	a1,s0,-192
    80005bf4:	4501                	li	a0,0
    80005bf6:	ffffd097          	auipc	ra,0xffffd
    80005bfa:	102080e7          	jalr	258(ra) # 80002cf8 <argstr>
    80005bfe:	87aa                	mv	a5,a0
    return -1;
    80005c00:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c02:	0c07c363          	bltz	a5,80005cc8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c06:	10000613          	li	a2,256
    80005c0a:	4581                	li	a1,0
    80005c0c:	e4040513          	addi	a0,s0,-448
    80005c10:	ffffb097          	auipc	ra,0xffffb
    80005c14:	1f8080e7          	jalr	504(ra) # 80000e08 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c18:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c1c:	89a6                	mv	s3,s1
    80005c1e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c20:	02000a13          	li	s4,32
    80005c24:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c28:	00391513          	slli	a0,s2,0x3
    80005c2c:	e3040593          	addi	a1,s0,-464
    80005c30:	e3843783          	ld	a5,-456(s0)
    80005c34:	953e                	add	a0,a0,a5
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	fe4080e7          	jalr	-28(ra) # 80002c1a <fetchaddr>
    80005c3e:	02054a63          	bltz	a0,80005c72 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c42:	e3043783          	ld	a5,-464(s0)
    80005c46:	c3b9                	beqz	a5,80005c8c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c48:	ffffb097          	auipc	ra,0xffffb
    80005c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <kalloc>
    80005c50:	85aa                	mv	a1,a0
    80005c52:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c56:	cd11                	beqz	a0,80005c72 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c58:	6605                	lui	a2,0x1
    80005c5a:	e3043503          	ld	a0,-464(s0)
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	00e080e7          	jalr	14(ra) # 80002c6c <fetchstr>
    80005c66:	00054663          	bltz	a0,80005c72 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c6a:	0905                	addi	s2,s2,1
    80005c6c:	09a1                	addi	s3,s3,8
    80005c6e:	fb491be3          	bne	s2,s4,80005c24 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c72:	f4040913          	addi	s2,s0,-192
    80005c76:	6088                	ld	a0,0(s1)
    80005c78:	c539                	beqz	a0,80005cc6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	de6080e7          	jalr	-538(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c82:	04a1                	addi	s1,s1,8
    80005c84:	ff2499e3          	bne	s1,s2,80005c76 <sys_exec+0xaa>
  return -1;
    80005c88:	557d                	li	a0,-1
    80005c8a:	a83d                	j	80005cc8 <sys_exec+0xfc>
      argv[i] = 0;
    80005c8c:	0a8e                	slli	s5,s5,0x3
    80005c8e:	fc0a8793          	addi	a5,s5,-64
    80005c92:	00878ab3          	add	s5,a5,s0
    80005c96:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c9a:	e4040593          	addi	a1,s0,-448
    80005c9e:	f4040513          	addi	a0,s0,-192
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	16e080e7          	jalr	366(ra) # 80004e10 <exec>
    80005caa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cac:	f4040993          	addi	s3,s0,-192
    80005cb0:	6088                	ld	a0,0(s1)
    80005cb2:	c901                	beqz	a0,80005cc2 <sys_exec+0xf6>
    kfree(argv[i]);
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	dac080e7          	jalr	-596(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cbc:	04a1                	addi	s1,s1,8
    80005cbe:	ff3499e3          	bne	s1,s3,80005cb0 <sys_exec+0xe4>
  return ret;
    80005cc2:	854a                	mv	a0,s2
    80005cc4:	a011                	j	80005cc8 <sys_exec+0xfc>
  return -1;
    80005cc6:	557d                	li	a0,-1
}
    80005cc8:	60be                	ld	ra,456(sp)
    80005cca:	641e                	ld	s0,448(sp)
    80005ccc:	74fa                	ld	s1,440(sp)
    80005cce:	795a                	ld	s2,432(sp)
    80005cd0:	79ba                	ld	s3,424(sp)
    80005cd2:	7a1a                	ld	s4,416(sp)
    80005cd4:	6afa                	ld	s5,408(sp)
    80005cd6:	6179                	addi	sp,sp,464
    80005cd8:	8082                	ret

0000000080005cda <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cda:	7139                	addi	sp,sp,-64
    80005cdc:	fc06                	sd	ra,56(sp)
    80005cde:	f822                	sd	s0,48(sp)
    80005ce0:	f426                	sd	s1,40(sp)
    80005ce2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ce4:	ffffc097          	auipc	ra,0xffffc
    80005ce8:	e18080e7          	jalr	-488(ra) # 80001afc <myproc>
    80005cec:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005cee:	fd840593          	addi	a1,s0,-40
    80005cf2:	4501                	li	a0,0
    80005cf4:	ffffd097          	auipc	ra,0xffffd
    80005cf8:	fe4080e7          	jalr	-28(ra) # 80002cd8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005cfc:	fc840593          	addi	a1,s0,-56
    80005d00:	fd040513          	addi	a0,s0,-48
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	dc2080e7          	jalr	-574(ra) # 80004ac6 <pipealloc>
    return -1;
    80005d0c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d0e:	0c054463          	bltz	a0,80005dd6 <sys_pipe+0xfc>
  fd0 = -1;
    80005d12:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d16:	fd043503          	ld	a0,-48(s0)
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	514080e7          	jalr	1300(ra) # 8000522e <fdalloc>
    80005d22:	fca42223          	sw	a0,-60(s0)
    80005d26:	08054b63          	bltz	a0,80005dbc <sys_pipe+0xe2>
    80005d2a:	fc843503          	ld	a0,-56(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	500080e7          	jalr	1280(ra) # 8000522e <fdalloc>
    80005d36:	fca42023          	sw	a0,-64(s0)
    80005d3a:	06054863          	bltz	a0,80005daa <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d3e:	4691                	li	a3,4
    80005d40:	fc440613          	addi	a2,s0,-60
    80005d44:	fd843583          	ld	a1,-40(s0)
    80005d48:	68a8                	ld	a0,80(s1)
    80005d4a:	ffffc097          	auipc	ra,0xffffc
    80005d4e:	a3e080e7          	jalr	-1474(ra) # 80001788 <copyout>
    80005d52:	02054063          	bltz	a0,80005d72 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d56:	4691                	li	a3,4
    80005d58:	fc040613          	addi	a2,s0,-64
    80005d5c:	fd843583          	ld	a1,-40(s0)
    80005d60:	0591                	addi	a1,a1,4
    80005d62:	68a8                	ld	a0,80(s1)
    80005d64:	ffffc097          	auipc	ra,0xffffc
    80005d68:	a24080e7          	jalr	-1500(ra) # 80001788 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d6c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d6e:	06055463          	bgez	a0,80005dd6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d72:	fc442783          	lw	a5,-60(s0)
    80005d76:	07e9                	addi	a5,a5,26
    80005d78:	078e                	slli	a5,a5,0x3
    80005d7a:	97a6                	add	a5,a5,s1
    80005d7c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d80:	fc042783          	lw	a5,-64(s0)
    80005d84:	07e9                	addi	a5,a5,26
    80005d86:	078e                	slli	a5,a5,0x3
    80005d88:	94be                	add	s1,s1,a5
    80005d8a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d8e:	fd043503          	ld	a0,-48(s0)
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	a04080e7          	jalr	-1532(ra) # 80004796 <fileclose>
    fileclose(wf);
    80005d9a:	fc843503          	ld	a0,-56(s0)
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	9f8080e7          	jalr	-1544(ra) # 80004796 <fileclose>
    return -1;
    80005da6:	57fd                	li	a5,-1
    80005da8:	a03d                	j	80005dd6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005daa:	fc442783          	lw	a5,-60(s0)
    80005dae:	0007c763          	bltz	a5,80005dbc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005db2:	07e9                	addi	a5,a5,26
    80005db4:	078e                	slli	a5,a5,0x3
    80005db6:	97a6                	add	a5,a5,s1
    80005db8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005dbc:	fd043503          	ld	a0,-48(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	9d6080e7          	jalr	-1578(ra) # 80004796 <fileclose>
    fileclose(wf);
    80005dc8:	fc843503          	ld	a0,-56(s0)
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	9ca080e7          	jalr	-1590(ra) # 80004796 <fileclose>
    return -1;
    80005dd4:	57fd                	li	a5,-1
}
    80005dd6:	853e                	mv	a0,a5
    80005dd8:	70e2                	ld	ra,56(sp)
    80005dda:	7442                	ld	s0,48(sp)
    80005ddc:	74a2                	ld	s1,40(sp)
    80005dde:	6121                	addi	sp,sp,64
    80005de0:	8082                	ret
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	cb7fc0ef          	jal	ra,80002ae6 <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	6d0c                	ld	a1,24(a0)
    80005e8c:	7110                	ld	a2,32(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	c08080e7          	jalr	-1016(ra) # 80001ad0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	97aa                	add	a5,a5,a0
    80005eec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	bd0080e7          	jalr	-1072(ra) # 80001ad0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5151b          	slliw	a0,a0,0xd
    80005f0c:	0c2017b7          	lui	a5,0xc201
    80005f10:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f12:	43c8                	lw	a0,4(a5)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	ba8080e7          	jalr	-1112(ra) # 80001ad0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	04a7cc63          	blt	a5,a0,80005fa8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f54:	0023d797          	auipc	a5,0x23d
    80005f58:	71c78793          	addi	a5,a5,1820 # 80243670 <disk>
    80005f5c:	97aa                	add	a5,a5,a0
    80005f5e:	0187c783          	lbu	a5,24(a5)
    80005f62:	ebb9                	bnez	a5,80005fb8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f64:	00451693          	slli	a3,a0,0x4
    80005f68:	0023d797          	auipc	a5,0x23d
    80005f6c:	70878793          	addi	a5,a5,1800 # 80243670 <disk>
    80005f70:	6398                	ld	a4,0(a5)
    80005f72:	9736                	add	a4,a4,a3
    80005f74:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005f78:	6398                	ld	a4,0(a5)
    80005f7a:	9736                	add	a4,a4,a3
    80005f7c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f80:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f84:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f88:	97aa                	add	a5,a5,a0
    80005f8a:	4705                	li	a4,1
    80005f8c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005f90:	0023d517          	auipc	a0,0x23d
    80005f94:	6f850513          	addi	a0,a0,1784 # 80243688 <disk+0x18>
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	270080e7          	jalr	624(ra) # 80002208 <wakeup>
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret
    panic("free_desc 1");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	98050513          	addi	a0,a0,-1664 # 80008928 <names+0x300>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	590080e7          	jalr	1424(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	98050513          	addi	a0,a0,-1664 # 80008938 <names+0x310>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	580080e7          	jalr	1408(ra) # 80000540 <panic>

0000000080005fc8 <virtio_disk_init>:
{
    80005fc8:	1101                	addi	sp,sp,-32
    80005fca:	ec06                	sd	ra,24(sp)
    80005fcc:	e822                	sd	s0,16(sp)
    80005fce:	e426                	sd	s1,8(sp)
    80005fd0:	e04a                	sd	s2,0(sp)
    80005fd2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fd4:	00003597          	auipc	a1,0x3
    80005fd8:	97458593          	addi	a1,a1,-1676 # 80008948 <names+0x320>
    80005fdc:	0023d517          	auipc	a0,0x23d
    80005fe0:	7bc50513          	addi	a0,a0,1980 # 80243798 <disk+0x128>
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	c98080e7          	jalr	-872(ra) # 80000c7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fec:	100017b7          	lui	a5,0x10001
    80005ff0:	4398                	lw	a4,0(a5)
    80005ff2:	2701                	sext.w	a4,a4
    80005ff4:	747277b7          	lui	a5,0x74727
    80005ff8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ffc:	14f71b63          	bne	a4,a5,80006152 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006000:	100017b7          	lui	a5,0x10001
    80006004:	43dc                	lw	a5,4(a5)
    80006006:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006008:	4709                	li	a4,2
    8000600a:	14e79463          	bne	a5,a4,80006152 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600e:	100017b7          	lui	a5,0x10001
    80006012:	479c                	lw	a5,8(a5)
    80006014:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006016:	12e79e63          	bne	a5,a4,80006152 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	47d8                	lw	a4,12(a5)
    80006020:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006022:	554d47b7          	lui	a5,0x554d4
    80006026:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000602a:	12f71463          	bne	a4,a5,80006152 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006036:	4705                	li	a4,1
    80006038:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000603a:	470d                	li	a4,3
    8000603c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000603e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006040:	c7ffe6b7          	lui	a3,0xc7ffe
    80006044:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbafaf>
    80006048:	8f75                	and	a4,a4,a3
    8000604a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604c:	472d                	li	a4,11
    8000604e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006050:	5bbc                	lw	a5,112(a5)
    80006052:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006056:	8ba1                	andi	a5,a5,8
    80006058:	10078563          	beqz	a5,80006162 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000605c:	100017b7          	lui	a5,0x10001
    80006060:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006064:	43fc                	lw	a5,68(a5)
    80006066:	2781                	sext.w	a5,a5
    80006068:	10079563          	bnez	a5,80006172 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000606c:	100017b7          	lui	a5,0x10001
    80006070:	5bdc                	lw	a5,52(a5)
    80006072:	2781                	sext.w	a5,a5
  if(max == 0)
    80006074:	10078763          	beqz	a5,80006182 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006078:	471d                	li	a4,7
    8000607a:	10f77c63          	bgeu	a4,a5,80006192 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	b66080e7          	jalr	-1178(ra) # 80000be4 <kalloc>
    80006086:	0023d497          	auipc	s1,0x23d
    8000608a:	5ea48493          	addi	s1,s1,1514 # 80243670 <disk>
    8000608e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	b54080e7          	jalr	-1196(ra) # 80000be4 <kalloc>
    80006098:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000609a:	ffffb097          	auipc	ra,0xffffb
    8000609e:	b4a080e7          	jalr	-1206(ra) # 80000be4 <kalloc>
    800060a2:	87aa                	mv	a5,a0
    800060a4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060a6:	6088                	ld	a0,0(s1)
    800060a8:	cd6d                	beqz	a0,800061a2 <virtio_disk_init+0x1da>
    800060aa:	0023d717          	auipc	a4,0x23d
    800060ae:	5ce73703          	ld	a4,1486(a4) # 80243678 <disk+0x8>
    800060b2:	cb65                	beqz	a4,800061a2 <virtio_disk_init+0x1da>
    800060b4:	c7fd                	beqz	a5,800061a2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800060b6:	6605                	lui	a2,0x1
    800060b8:	4581                	li	a1,0
    800060ba:	ffffb097          	auipc	ra,0xffffb
    800060be:	d4e080e7          	jalr	-690(ra) # 80000e08 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060c2:	0023d497          	auipc	s1,0x23d
    800060c6:	5ae48493          	addi	s1,s1,1454 # 80243670 <disk>
    800060ca:	6605                	lui	a2,0x1
    800060cc:	4581                	li	a1,0
    800060ce:	6488                	ld	a0,8(s1)
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	d38080e7          	jalr	-712(ra) # 80000e08 <memset>
  memset(disk.used, 0, PGSIZE);
    800060d8:	6605                	lui	a2,0x1
    800060da:	4581                	li	a1,0
    800060dc:	6888                	ld	a0,16(s1)
    800060de:	ffffb097          	auipc	ra,0xffffb
    800060e2:	d2a080e7          	jalr	-726(ra) # 80000e08 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e6:	100017b7          	lui	a5,0x10001
    800060ea:	4721                	li	a4,8
    800060ec:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060ee:	4098                	lw	a4,0(s1)
    800060f0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060f4:	40d8                	lw	a4,4(s1)
    800060f6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060fa:	6498                	ld	a4,8(s1)
    800060fc:	0007069b          	sext.w	a3,a4
    80006100:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006104:	9701                	srai	a4,a4,0x20
    80006106:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000610a:	6898                	ld	a4,16(s1)
    8000610c:	0007069b          	sext.w	a3,a4
    80006110:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006114:	9701                	srai	a4,a4,0x20
    80006116:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000611a:	4705                	li	a4,1
    8000611c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000611e:	00e48c23          	sb	a4,24(s1)
    80006122:	00e48ca3          	sb	a4,25(s1)
    80006126:	00e48d23          	sb	a4,26(s1)
    8000612a:	00e48da3          	sb	a4,27(s1)
    8000612e:	00e48e23          	sb	a4,28(s1)
    80006132:	00e48ea3          	sb	a4,29(s1)
    80006136:	00e48f23          	sb	a4,30(s1)
    8000613a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000613e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006142:	0727a823          	sw	s2,112(a5)
}
    80006146:	60e2                	ld	ra,24(sp)
    80006148:	6442                	ld	s0,16(sp)
    8000614a:	64a2                	ld	s1,8(sp)
    8000614c:	6902                	ld	s2,0(sp)
    8000614e:	6105                	addi	sp,sp,32
    80006150:	8082                	ret
    panic("could not find virtio disk");
    80006152:	00003517          	auipc	a0,0x3
    80006156:	80650513          	addi	a0,a0,-2042 # 80008958 <names+0x330>
    8000615a:	ffffa097          	auipc	ra,0xffffa
    8000615e:	3e6080e7          	jalr	998(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006162:	00003517          	auipc	a0,0x3
    80006166:	81650513          	addi	a0,a0,-2026 # 80008978 <names+0x350>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3d6080e7          	jalr	982(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006172:	00003517          	auipc	a0,0x3
    80006176:	82650513          	addi	a0,a0,-2010 # 80008998 <names+0x370>
    8000617a:	ffffa097          	auipc	ra,0xffffa
    8000617e:	3c6080e7          	jalr	966(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006182:	00003517          	auipc	a0,0x3
    80006186:	83650513          	addi	a0,a0,-1994 # 800089b8 <names+0x390>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3b6080e7          	jalr	950(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006192:	00003517          	auipc	a0,0x3
    80006196:	84650513          	addi	a0,a0,-1978 # 800089d8 <names+0x3b0>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a6080e7          	jalr	934(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800061a2:	00003517          	auipc	a0,0x3
    800061a6:	85650513          	addi	a0,a0,-1962 # 800089f8 <names+0x3d0>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	396080e7          	jalr	918(ra) # 80000540 <panic>

00000000800061b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b2:	7119                	addi	sp,sp,-128
    800061b4:	fc86                	sd	ra,120(sp)
    800061b6:	f8a2                	sd	s0,112(sp)
    800061b8:	f4a6                	sd	s1,104(sp)
    800061ba:	f0ca                	sd	s2,96(sp)
    800061bc:	ecce                	sd	s3,88(sp)
    800061be:	e8d2                	sd	s4,80(sp)
    800061c0:	e4d6                	sd	s5,72(sp)
    800061c2:	e0da                	sd	s6,64(sp)
    800061c4:	fc5e                	sd	s7,56(sp)
    800061c6:	f862                	sd	s8,48(sp)
    800061c8:	f466                	sd	s9,40(sp)
    800061ca:	f06a                	sd	s10,32(sp)
    800061cc:	ec6e                	sd	s11,24(sp)
    800061ce:	0100                	addi	s0,sp,128
    800061d0:	8aaa                	mv	s5,a0
    800061d2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d4:	00c52d03          	lw	s10,12(a0)
    800061d8:	001d1d1b          	slliw	s10,s10,0x1
    800061dc:	1d02                	slli	s10,s10,0x20
    800061de:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800061e2:	0023d517          	auipc	a0,0x23d
    800061e6:	5b650513          	addi	a0,a0,1462 # 80243798 <disk+0x128>
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	b22080e7          	jalr	-1246(ra) # 80000d0c <acquire>
  for(int i = 0; i < 3; i++){
    800061f2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061f4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061f6:	0023db97          	auipc	s7,0x23d
    800061fa:	47ab8b93          	addi	s7,s7,1146 # 80243670 <disk>
  for(int i = 0; i < 3; i++){
    800061fe:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006200:	0023dc97          	auipc	s9,0x23d
    80006204:	598c8c93          	addi	s9,s9,1432 # 80243798 <disk+0x128>
    80006208:	a08d                	j	8000626a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000620a:	00fb8733          	add	a4,s7,a5
    8000620e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006212:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006214:	0207c563          	bltz	a5,8000623e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006218:	2905                	addiw	s2,s2,1
    8000621a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000621c:	05690c63          	beq	s2,s6,80006274 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006220:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006222:	0023d717          	auipc	a4,0x23d
    80006226:	44e70713          	addi	a4,a4,1102 # 80243670 <disk>
    8000622a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000622c:	01874683          	lbu	a3,24(a4)
    80006230:	fee9                	bnez	a3,8000620a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006232:	2785                	addiw	a5,a5,1
    80006234:	0705                	addi	a4,a4,1
    80006236:	fe979be3          	bne	a5,s1,8000622c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000623a:	57fd                	li	a5,-1
    8000623c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000623e:	01205d63          	blez	s2,80006258 <virtio_disk_rw+0xa6>
    80006242:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006244:	000a2503          	lw	a0,0(s4)
    80006248:	00000097          	auipc	ra,0x0
    8000624c:	cfe080e7          	jalr	-770(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    80006250:	2d85                	addiw	s11,s11,1
    80006252:	0a11                	addi	s4,s4,4
    80006254:	ff2d98e3          	bne	s11,s2,80006244 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006258:	85e6                	mv	a1,s9
    8000625a:	0023d517          	auipc	a0,0x23d
    8000625e:	42e50513          	addi	a0,a0,1070 # 80243688 <disk+0x18>
    80006262:	ffffc097          	auipc	ra,0xffffc
    80006266:	f42080e7          	jalr	-190(ra) # 800021a4 <sleep>
  for(int i = 0; i < 3; i++){
    8000626a:	f8040a13          	addi	s4,s0,-128
{
    8000626e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006270:	894e                	mv	s2,s3
    80006272:	b77d                	j	80006220 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006274:	f8042503          	lw	a0,-128(s0)
    80006278:	00a50713          	addi	a4,a0,10
    8000627c:	0712                	slli	a4,a4,0x4

  if(write)
    8000627e:	0023d797          	auipc	a5,0x23d
    80006282:	3f278793          	addi	a5,a5,1010 # 80243670 <disk>
    80006286:	00e786b3          	add	a3,a5,a4
    8000628a:	01803633          	snez	a2,s8
    8000628e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006290:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006294:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006298:	f6070613          	addi	a2,a4,-160
    8000629c:	6394                	ld	a3,0(a5)
    8000629e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062a0:	00870593          	addi	a1,a4,8
    800062a4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062a6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062a8:	0007b803          	ld	a6,0(a5)
    800062ac:	9642                	add	a2,a2,a6
    800062ae:	46c1                	li	a3,16
    800062b0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062b2:	4585                	li	a1,1
    800062b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062b8:	f8442683          	lw	a3,-124(s0)
    800062bc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062c0:	0692                	slli	a3,a3,0x4
    800062c2:	9836                	add	a6,a6,a3
    800062c4:	058a8613          	addi	a2,s5,88
    800062c8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062cc:	0007b803          	ld	a6,0(a5)
    800062d0:	96c2                	add	a3,a3,a6
    800062d2:	40000613          	li	a2,1024
    800062d6:	c690                	sw	a2,8(a3)
  if(write)
    800062d8:	001c3613          	seqz	a2,s8
    800062dc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062e0:	00166613          	ori	a2,a2,1
    800062e4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062e8:	f8842603          	lw	a2,-120(s0)
    800062ec:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062f0:	00250693          	addi	a3,a0,2
    800062f4:	0692                	slli	a3,a3,0x4
    800062f6:	96be                	add	a3,a3,a5
    800062f8:	58fd                	li	a7,-1
    800062fa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062fe:	0612                	slli	a2,a2,0x4
    80006300:	9832                	add	a6,a6,a2
    80006302:	f9070713          	addi	a4,a4,-112
    80006306:	973e                	add	a4,a4,a5
    80006308:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000630c:	6398                	ld	a4,0(a5)
    8000630e:	9732                	add	a4,a4,a2
    80006310:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006312:	4609                	li	a2,2
    80006314:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006318:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000631c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006320:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006324:	6794                	ld	a3,8(a5)
    80006326:	0026d703          	lhu	a4,2(a3)
    8000632a:	8b1d                	andi	a4,a4,7
    8000632c:	0706                	slli	a4,a4,0x1
    8000632e:	96ba                	add	a3,a3,a4
    80006330:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006334:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006338:	6798                	ld	a4,8(a5)
    8000633a:	00275783          	lhu	a5,2(a4)
    8000633e:	2785                	addiw	a5,a5,1
    80006340:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006344:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006348:	100017b7          	lui	a5,0x10001
    8000634c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006350:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006354:	0023d917          	auipc	s2,0x23d
    80006358:	44490913          	addi	s2,s2,1092 # 80243798 <disk+0x128>
  while(b->disk == 1) {
    8000635c:	4485                	li	s1,1
    8000635e:	00b79c63          	bne	a5,a1,80006376 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006362:	85ca                	mv	a1,s2
    80006364:	8556                	mv	a0,s5
    80006366:	ffffc097          	auipc	ra,0xffffc
    8000636a:	e3e080e7          	jalr	-450(ra) # 800021a4 <sleep>
  while(b->disk == 1) {
    8000636e:	004aa783          	lw	a5,4(s5)
    80006372:	fe9788e3          	beq	a5,s1,80006362 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006376:	f8042903          	lw	s2,-128(s0)
    8000637a:	00290713          	addi	a4,s2,2
    8000637e:	0712                	slli	a4,a4,0x4
    80006380:	0023d797          	auipc	a5,0x23d
    80006384:	2f078793          	addi	a5,a5,752 # 80243670 <disk>
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000638e:	0023d997          	auipc	s3,0x23d
    80006392:	2e298993          	addi	s3,s3,738 # 80243670 <disk>
    80006396:	00491713          	slli	a4,s2,0x4
    8000639a:	0009b783          	ld	a5,0(s3)
    8000639e:	97ba                	add	a5,a5,a4
    800063a0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063a4:	854a                	mv	a0,s2
    800063a6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063aa:	00000097          	auipc	ra,0x0
    800063ae:	b9c080e7          	jalr	-1124(ra) # 80005f46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063b2:	8885                	andi	s1,s1,1
    800063b4:	f0ed                	bnez	s1,80006396 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063b6:	0023d517          	auipc	a0,0x23d
    800063ba:	3e250513          	addi	a0,a0,994 # 80243798 <disk+0x128>
    800063be:	ffffb097          	auipc	ra,0xffffb
    800063c2:	a02080e7          	jalr	-1534(ra) # 80000dc0 <release>
}
    800063c6:	70e6                	ld	ra,120(sp)
    800063c8:	7446                	ld	s0,112(sp)
    800063ca:	74a6                	ld	s1,104(sp)
    800063cc:	7906                	ld	s2,96(sp)
    800063ce:	69e6                	ld	s3,88(sp)
    800063d0:	6a46                	ld	s4,80(sp)
    800063d2:	6aa6                	ld	s5,72(sp)
    800063d4:	6b06                	ld	s6,64(sp)
    800063d6:	7be2                	ld	s7,56(sp)
    800063d8:	7c42                	ld	s8,48(sp)
    800063da:	7ca2                	ld	s9,40(sp)
    800063dc:	7d02                	ld	s10,32(sp)
    800063de:	6de2                	ld	s11,24(sp)
    800063e0:	6109                	addi	sp,sp,128
    800063e2:	8082                	ret

00000000800063e4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063e4:	1101                	addi	sp,sp,-32
    800063e6:	ec06                	sd	ra,24(sp)
    800063e8:	e822                	sd	s0,16(sp)
    800063ea:	e426                	sd	s1,8(sp)
    800063ec:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ee:	0023d497          	auipc	s1,0x23d
    800063f2:	28248493          	addi	s1,s1,642 # 80243670 <disk>
    800063f6:	0023d517          	auipc	a0,0x23d
    800063fa:	3a250513          	addi	a0,a0,930 # 80243798 <disk+0x128>
    800063fe:	ffffb097          	auipc	ra,0xffffb
    80006402:	90e080e7          	jalr	-1778(ra) # 80000d0c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006406:	10001737          	lui	a4,0x10001
    8000640a:	533c                	lw	a5,96(a4)
    8000640c:	8b8d                	andi	a5,a5,3
    8000640e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006410:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006414:	689c                	ld	a5,16(s1)
    80006416:	0204d703          	lhu	a4,32(s1)
    8000641a:	0027d783          	lhu	a5,2(a5)
    8000641e:	04f70863          	beq	a4,a5,8000646e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006422:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006426:	6898                	ld	a4,16(s1)
    80006428:	0204d783          	lhu	a5,32(s1)
    8000642c:	8b9d                	andi	a5,a5,7
    8000642e:	078e                	slli	a5,a5,0x3
    80006430:	97ba                	add	a5,a5,a4
    80006432:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006434:	00278713          	addi	a4,a5,2
    80006438:	0712                	slli	a4,a4,0x4
    8000643a:	9726                	add	a4,a4,s1
    8000643c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006440:	e721                	bnez	a4,80006488 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006442:	0789                	addi	a5,a5,2
    80006444:	0792                	slli	a5,a5,0x4
    80006446:	97a6                	add	a5,a5,s1
    80006448:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000644a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000644e:	ffffc097          	auipc	ra,0xffffc
    80006452:	dba080e7          	jalr	-582(ra) # 80002208 <wakeup>

    disk.used_idx += 1;
    80006456:	0204d783          	lhu	a5,32(s1)
    8000645a:	2785                	addiw	a5,a5,1
    8000645c:	17c2                	slli	a5,a5,0x30
    8000645e:	93c1                	srli	a5,a5,0x30
    80006460:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006464:	6898                	ld	a4,16(s1)
    80006466:	00275703          	lhu	a4,2(a4)
    8000646a:	faf71ce3          	bne	a4,a5,80006422 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000646e:	0023d517          	auipc	a0,0x23d
    80006472:	32a50513          	addi	a0,a0,810 # 80243798 <disk+0x128>
    80006476:	ffffb097          	auipc	ra,0xffffb
    8000647a:	94a080e7          	jalr	-1718(ra) # 80000dc0 <release>
}
    8000647e:	60e2                	ld	ra,24(sp)
    80006480:	6442                	ld	s0,16(sp)
    80006482:	64a2                	ld	s1,8(sp)
    80006484:	6105                	addi	sp,sp,32
    80006486:	8082                	ret
      panic("virtio_disk_intr status");
    80006488:	00002517          	auipc	a0,0x2
    8000648c:	58850513          	addi	a0,a0,1416 # 80008a10 <names+0x3e8>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	0b0080e7          	jalr	176(ra) # 80000540 <panic>
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

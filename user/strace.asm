
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/types.h"
#include "../kernel/stats.h"
#include "user.h"

int main(int argc, char* argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
   a:	84ae                	mv	s1,a1
  int forkReturn = fork();
   c:	00000097          	auipc	ra,0x0
  10:	2ec080e7          	jalr	748(ra) # 2f8 <fork>
  // fork errored
  if(forkReturn < 0)
  14:	04054163          	bltz	a0,56 <main+0x56>
  {
    printf("Unsuccesful fork\n");
    exit(0);
  }
  // in child
  else if(forkReturn != 0)
  18:	cd21                	beqz	a0,70 <main+0x70>
  {
    trace(atoi(argv[1]));
  1a:	6488                	ld	a0,8(s1)
  1c:	00000097          	auipc	ra,0x0
  20:	1ea080e7          	jalr	490(ra) # 206 <atoi>
  24:	00000097          	auipc	ra,0x0
  28:	38c080e7          	jalr	908(ra) # 3b0 <trace>
    exec(argv[2], argv+2);
  2c:	01048593          	addi	a1,s1,16
  30:	6888                	ld	a0,16(s1)
  32:	00000097          	auipc	ra,0x0
  36:	306080e7          	jalr	774(ra) # 338 <exec>
    printf("Execution of %s failed.\n", argv[1]);
  3a:	648c                	ld	a1,8(s1)
  3c:	00001517          	auipc	a0,0x1
  40:	81c50513          	addi	a0,a0,-2020 # 858 <malloc+0xfe>
  44:	00000097          	auipc	ra,0x0
  48:	65e080e7          	jalr	1630(ra) # 6a2 <printf>
    exit(0);
  4c:	4501                	li	a0,0
  4e:	00000097          	auipc	ra,0x0
  52:	2b2080e7          	jalr	690(ra) # 300 <exit>
    printf("Unsuccesful fork\n");
  56:	00000517          	auipc	a0,0x0
  5a:	7ea50513          	addi	a0,a0,2026 # 840 <malloc+0xe6>
  5e:	00000097          	auipc	ra,0x0
  62:	644080e7          	jalr	1604(ra) # 6a2 <printf>
    exit(0);
  66:	4501                	li	a0,0
  68:	00000097          	auipc	ra,0x0
  6c:	298080e7          	jalr	664(ra) # 300 <exit>
  }
	exit(0);
  70:	4501                	li	a0,0
  72:	00000097          	auipc	ra,0x0
  76:	28e080e7          	jalr	654(ra) # 300 <exit>

000000000000007a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  7a:	1141                	addi	sp,sp,-16
  7c:	e406                	sd	ra,8(sp)
  7e:	e022                	sd	s0,0(sp)
  80:	0800                	addi	s0,sp,16
  extern int main();
  main();
  82:	00000097          	auipc	ra,0x0
  86:	f7e080e7          	jalr	-130(ra) # 0 <main>
  exit(0);
  8a:	4501                	li	a0,0
  8c:	00000097          	auipc	ra,0x0
  90:	274080e7          	jalr	628(ra) # 300 <exit>

0000000000000094 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  9a:	87aa                	mv	a5,a0
  9c:	0585                	addi	a1,a1,1
  9e:	0785                	addi	a5,a5,1
  a0:	fff5c703          	lbu	a4,-1(a1)
  a4:	fee78fa3          	sb	a4,-1(a5)
  a8:	fb75                	bnez	a4,9c <strcpy+0x8>
    ;
  return os;
}
  aa:	6422                	ld	s0,8(sp)
  ac:	0141                	addi	sp,sp,16
  ae:	8082                	ret

00000000000000b0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  b0:	1141                	addi	sp,sp,-16
  b2:	e422                	sd	s0,8(sp)
  b4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  b6:	00054783          	lbu	a5,0(a0)
  ba:	cb91                	beqz	a5,ce <strcmp+0x1e>
  bc:	0005c703          	lbu	a4,0(a1)
  c0:	00f71763          	bne	a4,a5,ce <strcmp+0x1e>
    p++, q++;
  c4:	0505                	addi	a0,a0,1
  c6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  c8:	00054783          	lbu	a5,0(a0)
  cc:	fbe5                	bnez	a5,bc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ce:	0005c503          	lbu	a0,0(a1)
}
  d2:	40a7853b          	subw	a0,a5,a0
  d6:	6422                	ld	s0,8(sp)
  d8:	0141                	addi	sp,sp,16
  da:	8082                	ret

00000000000000dc <strlen>:

uint
strlen(const char *s)
{
  dc:	1141                	addi	sp,sp,-16
  de:	e422                	sd	s0,8(sp)
  e0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  e2:	00054783          	lbu	a5,0(a0)
  e6:	cf91                	beqz	a5,102 <strlen+0x26>
  e8:	0505                	addi	a0,a0,1
  ea:	87aa                	mv	a5,a0
  ec:	4685                	li	a3,1
  ee:	9e89                	subw	a3,a3,a0
  f0:	00f6853b          	addw	a0,a3,a5
  f4:	0785                	addi	a5,a5,1
  f6:	fff7c703          	lbu	a4,-1(a5)
  fa:	fb7d                	bnez	a4,f0 <strlen+0x14>
    ;
  return n;
}
  fc:	6422                	ld	s0,8(sp)
  fe:	0141                	addi	sp,sp,16
 100:	8082                	ret
  for(n = 0; s[n]; n++)
 102:	4501                	li	a0,0
 104:	bfe5                	j	fc <strlen+0x20>

0000000000000106 <memset>:

void*
memset(void *dst, int c, uint n)
{
 106:	1141                	addi	sp,sp,-16
 108:	e422                	sd	s0,8(sp)
 10a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 10c:	ca19                	beqz	a2,122 <memset+0x1c>
 10e:	87aa                	mv	a5,a0
 110:	1602                	slli	a2,a2,0x20
 112:	9201                	srli	a2,a2,0x20
 114:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 118:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 11c:	0785                	addi	a5,a5,1
 11e:	fee79de3          	bne	a5,a4,118 <memset+0x12>
  }
  return dst;
}
 122:	6422                	ld	s0,8(sp)
 124:	0141                	addi	sp,sp,16
 126:	8082                	ret

0000000000000128 <strchr>:

char*
strchr(const char *s, char c)
{
 128:	1141                	addi	sp,sp,-16
 12a:	e422                	sd	s0,8(sp)
 12c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 12e:	00054783          	lbu	a5,0(a0)
 132:	cb99                	beqz	a5,148 <strchr+0x20>
    if(*s == c)
 134:	00f58763          	beq	a1,a5,142 <strchr+0x1a>
  for(; *s; s++)
 138:	0505                	addi	a0,a0,1
 13a:	00054783          	lbu	a5,0(a0)
 13e:	fbfd                	bnez	a5,134 <strchr+0xc>
      return (char*)s;
  return 0;
 140:	4501                	li	a0,0
}
 142:	6422                	ld	s0,8(sp)
 144:	0141                	addi	sp,sp,16
 146:	8082                	ret
  return 0;
 148:	4501                	li	a0,0
 14a:	bfe5                	j	142 <strchr+0x1a>

000000000000014c <gets>:

char*
gets(char *buf, int max)
{
 14c:	711d                	addi	sp,sp,-96
 14e:	ec86                	sd	ra,88(sp)
 150:	e8a2                	sd	s0,80(sp)
 152:	e4a6                	sd	s1,72(sp)
 154:	e0ca                	sd	s2,64(sp)
 156:	fc4e                	sd	s3,56(sp)
 158:	f852                	sd	s4,48(sp)
 15a:	f456                	sd	s5,40(sp)
 15c:	f05a                	sd	s6,32(sp)
 15e:	ec5e                	sd	s7,24(sp)
 160:	1080                	addi	s0,sp,96
 162:	8baa                	mv	s7,a0
 164:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 166:	892a                	mv	s2,a0
 168:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 16a:	4aa9                	li	s5,10
 16c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 16e:	89a6                	mv	s3,s1
 170:	2485                	addiw	s1,s1,1
 172:	0344d863          	bge	s1,s4,1a2 <gets+0x56>
    cc = read(0, &c, 1);
 176:	4605                	li	a2,1
 178:	faf40593          	addi	a1,s0,-81
 17c:	4501                	li	a0,0
 17e:	00000097          	auipc	ra,0x0
 182:	19a080e7          	jalr	410(ra) # 318 <read>
    if(cc < 1)
 186:	00a05e63          	blez	a0,1a2 <gets+0x56>
    buf[i++] = c;
 18a:	faf44783          	lbu	a5,-81(s0)
 18e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 192:	01578763          	beq	a5,s5,1a0 <gets+0x54>
 196:	0905                	addi	s2,s2,1
 198:	fd679be3          	bne	a5,s6,16e <gets+0x22>
  for(i=0; i+1 < max; ){
 19c:	89a6                	mv	s3,s1
 19e:	a011                	j	1a2 <gets+0x56>
 1a0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1a2:	99de                	add	s3,s3,s7
 1a4:	00098023          	sb	zero,0(s3)
  return buf;
}
 1a8:	855e                	mv	a0,s7
 1aa:	60e6                	ld	ra,88(sp)
 1ac:	6446                	ld	s0,80(sp)
 1ae:	64a6                	ld	s1,72(sp)
 1b0:	6906                	ld	s2,64(sp)
 1b2:	79e2                	ld	s3,56(sp)
 1b4:	7a42                	ld	s4,48(sp)
 1b6:	7aa2                	ld	s5,40(sp)
 1b8:	7b02                	ld	s6,32(sp)
 1ba:	6be2                	ld	s7,24(sp)
 1bc:	6125                	addi	sp,sp,96
 1be:	8082                	ret

00000000000001c0 <stats>:

int
stats(const char *n, struct stats *st)
{
 1c0:	1101                	addi	sp,sp,-32
 1c2:	ec06                	sd	ra,24(sp)
 1c4:	e822                	sd	s0,16(sp)
 1c6:	e426                	sd	s1,8(sp)
 1c8:	e04a                	sd	s2,0(sp)
 1ca:	1000                	addi	s0,sp,32
 1cc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ce:	4581                	li	a1,0
 1d0:	00000097          	auipc	ra,0x0
 1d4:	170080e7          	jalr	368(ra) # 340 <open>
  if(fd < 0)
 1d8:	02054563          	bltz	a0,202 <stats+0x42>
 1dc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1de:	85ca                	mv	a1,s2
 1e0:	00000097          	auipc	ra,0x0
 1e4:	178080e7          	jalr	376(ra) # 358 <fstat>
 1e8:	892a                	mv	s2,a0
  close(fd);
 1ea:	8526                	mv	a0,s1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	13c080e7          	jalr	316(ra) # 328 <close>
  return r;
}
 1f4:	854a                	mv	a0,s2
 1f6:	60e2                	ld	ra,24(sp)
 1f8:	6442                	ld	s0,16(sp)
 1fa:	64a2                	ld	s1,8(sp)
 1fc:	6902                	ld	s2,0(sp)
 1fe:	6105                	addi	sp,sp,32
 200:	8082                	ret
    return -1;
 202:	597d                	li	s2,-1
 204:	bfc5                	j	1f4 <stats+0x34>

0000000000000206 <atoi>:

int
atoi(const char *s)
{
 206:	1141                	addi	sp,sp,-16
 208:	e422                	sd	s0,8(sp)
 20a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 20c:	00054683          	lbu	a3,0(a0)
 210:	fd06879b          	addiw	a5,a3,-48
 214:	0ff7f793          	zext.b	a5,a5
 218:	4625                	li	a2,9
 21a:	02f66863          	bltu	a2,a5,24a <atoi+0x44>
 21e:	872a                	mv	a4,a0
  n = 0;
 220:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 222:	0705                	addi	a4,a4,1
 224:	0025179b          	slliw	a5,a0,0x2
 228:	9fa9                	addw	a5,a5,a0
 22a:	0017979b          	slliw	a5,a5,0x1
 22e:	9fb5                	addw	a5,a5,a3
 230:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 234:	00074683          	lbu	a3,0(a4)
 238:	fd06879b          	addiw	a5,a3,-48
 23c:	0ff7f793          	zext.b	a5,a5
 240:	fef671e3          	bgeu	a2,a5,222 <atoi+0x1c>
  return n;
}
 244:	6422                	ld	s0,8(sp)
 246:	0141                	addi	sp,sp,16
 248:	8082                	ret
  n = 0;
 24a:	4501                	li	a0,0
 24c:	bfe5                	j	244 <atoi+0x3e>

000000000000024e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 24e:	1141                	addi	sp,sp,-16
 250:	e422                	sd	s0,8(sp)
 252:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 254:	02b57463          	bgeu	a0,a1,27c <memmove+0x2e>
    while(n-- > 0)
 258:	00c05f63          	blez	a2,276 <memmove+0x28>
 25c:	1602                	slli	a2,a2,0x20
 25e:	9201                	srli	a2,a2,0x20
 260:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 264:	872a                	mv	a4,a0
      *dst++ = *src++;
 266:	0585                	addi	a1,a1,1
 268:	0705                	addi	a4,a4,1
 26a:	fff5c683          	lbu	a3,-1(a1)
 26e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 272:	fee79ae3          	bne	a5,a4,266 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 276:	6422                	ld	s0,8(sp)
 278:	0141                	addi	sp,sp,16
 27a:	8082                	ret
    dst += n;
 27c:	00c50733          	add	a4,a0,a2
    src += n;
 280:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 282:	fec05ae3          	blez	a2,276 <memmove+0x28>
 286:	fff6079b          	addiw	a5,a2,-1
 28a:	1782                	slli	a5,a5,0x20
 28c:	9381                	srli	a5,a5,0x20
 28e:	fff7c793          	not	a5,a5
 292:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 294:	15fd                	addi	a1,a1,-1
 296:	177d                	addi	a4,a4,-1
 298:	0005c683          	lbu	a3,0(a1)
 29c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2a0:	fee79ae3          	bne	a5,a4,294 <memmove+0x46>
 2a4:	bfc9                	j	276 <memmove+0x28>

00000000000002a6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2a6:	1141                	addi	sp,sp,-16
 2a8:	e422                	sd	s0,8(sp)
 2aa:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ac:	ca05                	beqz	a2,2dc <memcmp+0x36>
 2ae:	fff6069b          	addiw	a3,a2,-1
 2b2:	1682                	slli	a3,a3,0x20
 2b4:	9281                	srli	a3,a3,0x20
 2b6:	0685                	addi	a3,a3,1
 2b8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2ba:	00054783          	lbu	a5,0(a0)
 2be:	0005c703          	lbu	a4,0(a1)
 2c2:	00e79863          	bne	a5,a4,2d2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2c6:	0505                	addi	a0,a0,1
    p2++;
 2c8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2ca:	fed518e3          	bne	a0,a3,2ba <memcmp+0x14>
  }
  return 0;
 2ce:	4501                	li	a0,0
 2d0:	a019                	j	2d6 <memcmp+0x30>
      return *p1 - *p2;
 2d2:	40e7853b          	subw	a0,a5,a4
}
 2d6:	6422                	ld	s0,8(sp)
 2d8:	0141                	addi	sp,sp,16
 2da:	8082                	ret
  return 0;
 2dc:	4501                	li	a0,0
 2de:	bfe5                	j	2d6 <memcmp+0x30>

00000000000002e0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2e0:	1141                	addi	sp,sp,-16
 2e2:	e406                	sd	ra,8(sp)
 2e4:	e022                	sd	s0,0(sp)
 2e6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2e8:	00000097          	auipc	ra,0x0
 2ec:	f66080e7          	jalr	-154(ra) # 24e <memmove>
}
 2f0:	60a2                	ld	ra,8(sp)
 2f2:	6402                	ld	s0,0(sp)
 2f4:	0141                	addi	sp,sp,16
 2f6:	8082                	ret

00000000000002f8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2f8:	4885                	li	a7,1
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <exit>:
.global exit
exit:
 li a7, SYS_exit
 300:	4889                	li	a7,2
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <wait>:
.global wait
wait:
 li a7, SYS_wait
 308:	488d                	li	a7,3
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 310:	4891                	li	a7,4
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <read>:
.global read
read:
 li a7, SYS_read
 318:	4895                	li	a7,5
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <write>:
.global write
write:
 li a7, SYS_write
 320:	48c1                	li	a7,16
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <close>:
.global close
close:
 li a7, SYS_close
 328:	48d5                	li	a7,21
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <kill>:
.global kill
kill:
 li a7, SYS_kill
 330:	4899                	li	a7,6
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <exec>:
.global exec
exec:
 li a7, SYS_exec
 338:	489d                	li	a7,7
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <open>:
.global open
open:
 li a7, SYS_open
 340:	48bd                	li	a7,15
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 348:	48c5                	li	a7,17
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 350:	48c9                	li	a7,18
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 358:	48a1                	li	a7,8
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <link>:
.global link
link:
 li a7, SYS_link
 360:	48cd                	li	a7,19
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 368:	48d1                	li	a7,20
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 370:	48a5                	li	a7,9
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <dup>:
.global dup
dup:
 li a7, SYS_dup
 378:	48a9                	li	a7,10
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 380:	48ad                	li	a7,11
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 388:	48b1                	li	a7,12
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 390:	48b5                	li	a7,13
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 398:	48b9                	li	a7,14
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 3a0:	48d9                	li	a7,22
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 3a8:	48dd                	li	a7,23
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <trace>:
.global trace
trace:
 li a7, SYS_trace
 3b0:	48e1                	li	a7,24
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <cps>:
.global cps
cps:
 li a7, SYS_cps
 3b8:	48e5                	li	a7,25
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <chpr>:
.global chpr
chpr:
 li a7, SYS_chpr
 3c0:	48e9                	li	a7,26
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3c8:	1101                	addi	sp,sp,-32
 3ca:	ec06                	sd	ra,24(sp)
 3cc:	e822                	sd	s0,16(sp)
 3ce:	1000                	addi	s0,sp,32
 3d0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3d4:	4605                	li	a2,1
 3d6:	fef40593          	addi	a1,s0,-17
 3da:	00000097          	auipc	ra,0x0
 3de:	f46080e7          	jalr	-186(ra) # 320 <write>
}
 3e2:	60e2                	ld	ra,24(sp)
 3e4:	6442                	ld	s0,16(sp)
 3e6:	6105                	addi	sp,sp,32
 3e8:	8082                	ret

00000000000003ea <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ea:	7139                	addi	sp,sp,-64
 3ec:	fc06                	sd	ra,56(sp)
 3ee:	f822                	sd	s0,48(sp)
 3f0:	f426                	sd	s1,40(sp)
 3f2:	f04a                	sd	s2,32(sp)
 3f4:	ec4e                	sd	s3,24(sp)
 3f6:	0080                	addi	s0,sp,64
 3f8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3fa:	c299                	beqz	a3,400 <printint+0x16>
 3fc:	0805c963          	bltz	a1,48e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 400:	2581                	sext.w	a1,a1
  neg = 0;
 402:	4881                	li	a7,0
 404:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 408:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 40a:	2601                	sext.w	a2,a2
 40c:	00000517          	auipc	a0,0x0
 410:	4cc50513          	addi	a0,a0,1228 # 8d8 <digits>
 414:	883a                	mv	a6,a4
 416:	2705                	addiw	a4,a4,1
 418:	02c5f7bb          	remuw	a5,a1,a2
 41c:	1782                	slli	a5,a5,0x20
 41e:	9381                	srli	a5,a5,0x20
 420:	97aa                	add	a5,a5,a0
 422:	0007c783          	lbu	a5,0(a5)
 426:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 42a:	0005879b          	sext.w	a5,a1
 42e:	02c5d5bb          	divuw	a1,a1,a2
 432:	0685                	addi	a3,a3,1
 434:	fec7f0e3          	bgeu	a5,a2,414 <printint+0x2a>
  if(neg)
 438:	00088c63          	beqz	a7,450 <printint+0x66>
    buf[i++] = '-';
 43c:	fd070793          	addi	a5,a4,-48
 440:	00878733          	add	a4,a5,s0
 444:	02d00793          	li	a5,45
 448:	fef70823          	sb	a5,-16(a4)
 44c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 450:	02e05863          	blez	a4,480 <printint+0x96>
 454:	fc040793          	addi	a5,s0,-64
 458:	00e78933          	add	s2,a5,a4
 45c:	fff78993          	addi	s3,a5,-1
 460:	99ba                	add	s3,s3,a4
 462:	377d                	addiw	a4,a4,-1
 464:	1702                	slli	a4,a4,0x20
 466:	9301                	srli	a4,a4,0x20
 468:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 46c:	fff94583          	lbu	a1,-1(s2)
 470:	8526                	mv	a0,s1
 472:	00000097          	auipc	ra,0x0
 476:	f56080e7          	jalr	-170(ra) # 3c8 <putc>
  while(--i >= 0)
 47a:	197d                	addi	s2,s2,-1
 47c:	ff3918e3          	bne	s2,s3,46c <printint+0x82>
}
 480:	70e2                	ld	ra,56(sp)
 482:	7442                	ld	s0,48(sp)
 484:	74a2                	ld	s1,40(sp)
 486:	7902                	ld	s2,32(sp)
 488:	69e2                	ld	s3,24(sp)
 48a:	6121                	addi	sp,sp,64
 48c:	8082                	ret
    x = -xx;
 48e:	40b005bb          	negw	a1,a1
    neg = 1;
 492:	4885                	li	a7,1
    x = -xx;
 494:	bf85                	j	404 <printint+0x1a>

0000000000000496 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 496:	7119                	addi	sp,sp,-128
 498:	fc86                	sd	ra,120(sp)
 49a:	f8a2                	sd	s0,112(sp)
 49c:	f4a6                	sd	s1,104(sp)
 49e:	f0ca                	sd	s2,96(sp)
 4a0:	ecce                	sd	s3,88(sp)
 4a2:	e8d2                	sd	s4,80(sp)
 4a4:	e4d6                	sd	s5,72(sp)
 4a6:	e0da                	sd	s6,64(sp)
 4a8:	fc5e                	sd	s7,56(sp)
 4aa:	f862                	sd	s8,48(sp)
 4ac:	f466                	sd	s9,40(sp)
 4ae:	f06a                	sd	s10,32(sp)
 4b0:	ec6e                	sd	s11,24(sp)
 4b2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4b4:	0005c903          	lbu	s2,0(a1)
 4b8:	18090f63          	beqz	s2,656 <vprintf+0x1c0>
 4bc:	8aaa                	mv	s5,a0
 4be:	8b32                	mv	s6,a2
 4c0:	00158493          	addi	s1,a1,1
  state = 0;
 4c4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4c6:	02500a13          	li	s4,37
 4ca:	4c55                	li	s8,21
 4cc:	00000c97          	auipc	s9,0x0
 4d0:	3b4c8c93          	addi	s9,s9,948 # 880 <malloc+0x126>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4d4:	02800d93          	li	s11,40
  putc(fd, 'x');
 4d8:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4da:	00000b97          	auipc	s7,0x0
 4de:	3feb8b93          	addi	s7,s7,1022 # 8d8 <digits>
 4e2:	a839                	j	500 <vprintf+0x6a>
        putc(fd, c);
 4e4:	85ca                	mv	a1,s2
 4e6:	8556                	mv	a0,s5
 4e8:	00000097          	auipc	ra,0x0
 4ec:	ee0080e7          	jalr	-288(ra) # 3c8 <putc>
 4f0:	a019                	j	4f6 <vprintf+0x60>
    } else if(state == '%'){
 4f2:	01498d63          	beq	s3,s4,50c <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4f6:	0485                	addi	s1,s1,1
 4f8:	fff4c903          	lbu	s2,-1(s1)
 4fc:	14090d63          	beqz	s2,656 <vprintf+0x1c0>
    if(state == 0){
 500:	fe0999e3          	bnez	s3,4f2 <vprintf+0x5c>
      if(c == '%'){
 504:	ff4910e3          	bne	s2,s4,4e4 <vprintf+0x4e>
        state = '%';
 508:	89d2                	mv	s3,s4
 50a:	b7f5                	j	4f6 <vprintf+0x60>
      if(c == 'd'){
 50c:	11490c63          	beq	s2,s4,624 <vprintf+0x18e>
 510:	f9d9079b          	addiw	a5,s2,-99
 514:	0ff7f793          	zext.b	a5,a5
 518:	10fc6e63          	bltu	s8,a5,634 <vprintf+0x19e>
 51c:	f9d9079b          	addiw	a5,s2,-99
 520:	0ff7f713          	zext.b	a4,a5
 524:	10ec6863          	bltu	s8,a4,634 <vprintf+0x19e>
 528:	00271793          	slli	a5,a4,0x2
 52c:	97e6                	add	a5,a5,s9
 52e:	439c                	lw	a5,0(a5)
 530:	97e6                	add	a5,a5,s9
 532:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 534:	008b0913          	addi	s2,s6,8
 538:	4685                	li	a3,1
 53a:	4629                	li	a2,10
 53c:	000b2583          	lw	a1,0(s6)
 540:	8556                	mv	a0,s5
 542:	00000097          	auipc	ra,0x0
 546:	ea8080e7          	jalr	-344(ra) # 3ea <printint>
 54a:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 54c:	4981                	li	s3,0
 54e:	b765                	j	4f6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 550:	008b0913          	addi	s2,s6,8
 554:	4681                	li	a3,0
 556:	4629                	li	a2,10
 558:	000b2583          	lw	a1,0(s6)
 55c:	8556                	mv	a0,s5
 55e:	00000097          	auipc	ra,0x0
 562:	e8c080e7          	jalr	-372(ra) # 3ea <printint>
 566:	8b4a                	mv	s6,s2
      state = 0;
 568:	4981                	li	s3,0
 56a:	b771                	j	4f6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 56c:	008b0913          	addi	s2,s6,8
 570:	4681                	li	a3,0
 572:	866a                	mv	a2,s10
 574:	000b2583          	lw	a1,0(s6)
 578:	8556                	mv	a0,s5
 57a:	00000097          	auipc	ra,0x0
 57e:	e70080e7          	jalr	-400(ra) # 3ea <printint>
 582:	8b4a                	mv	s6,s2
      state = 0;
 584:	4981                	li	s3,0
 586:	bf85                	j	4f6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 588:	008b0793          	addi	a5,s6,8
 58c:	f8f43423          	sd	a5,-120(s0)
 590:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 594:	03000593          	li	a1,48
 598:	8556                	mv	a0,s5
 59a:	00000097          	auipc	ra,0x0
 59e:	e2e080e7          	jalr	-466(ra) # 3c8 <putc>
  putc(fd, 'x');
 5a2:	07800593          	li	a1,120
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	e20080e7          	jalr	-480(ra) # 3c8 <putc>
 5b0:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5b2:	03c9d793          	srli	a5,s3,0x3c
 5b6:	97de                	add	a5,a5,s7
 5b8:	0007c583          	lbu	a1,0(a5)
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	e0a080e7          	jalr	-502(ra) # 3c8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5c6:	0992                	slli	s3,s3,0x4
 5c8:	397d                	addiw	s2,s2,-1
 5ca:	fe0914e3          	bnez	s2,5b2 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5ce:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5d2:	4981                	li	s3,0
 5d4:	b70d                	j	4f6 <vprintf+0x60>
        s = va_arg(ap, char*);
 5d6:	008b0913          	addi	s2,s6,8
 5da:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5de:	02098163          	beqz	s3,600 <vprintf+0x16a>
        while(*s != 0){
 5e2:	0009c583          	lbu	a1,0(s3)
 5e6:	c5ad                	beqz	a1,650 <vprintf+0x1ba>
          putc(fd, *s);
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	dde080e7          	jalr	-546(ra) # 3c8 <putc>
          s++;
 5f2:	0985                	addi	s3,s3,1
        while(*s != 0){
 5f4:	0009c583          	lbu	a1,0(s3)
 5f8:	f9e5                	bnez	a1,5e8 <vprintf+0x152>
        s = va_arg(ap, char*);
 5fa:	8b4a                	mv	s6,s2
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	bde5                	j	4f6 <vprintf+0x60>
          s = "(null)";
 600:	00000997          	auipc	s3,0x0
 604:	27898993          	addi	s3,s3,632 # 878 <malloc+0x11e>
        while(*s != 0){
 608:	85ee                	mv	a1,s11
 60a:	bff9                	j	5e8 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 60c:	008b0913          	addi	s2,s6,8
 610:	000b4583          	lbu	a1,0(s6)
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	db2080e7          	jalr	-590(ra) # 3c8 <putc>
 61e:	8b4a                	mv	s6,s2
      state = 0;
 620:	4981                	li	s3,0
 622:	bdd1                	j	4f6 <vprintf+0x60>
        putc(fd, c);
 624:	85d2                	mv	a1,s4
 626:	8556                	mv	a0,s5
 628:	00000097          	auipc	ra,0x0
 62c:	da0080e7          	jalr	-608(ra) # 3c8 <putc>
      state = 0;
 630:	4981                	li	s3,0
 632:	b5d1                	j	4f6 <vprintf+0x60>
        putc(fd, '%');
 634:	85d2                	mv	a1,s4
 636:	8556                	mv	a0,s5
 638:	00000097          	auipc	ra,0x0
 63c:	d90080e7          	jalr	-624(ra) # 3c8 <putc>
        putc(fd, c);
 640:	85ca                	mv	a1,s2
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	d84080e7          	jalr	-636(ra) # 3c8 <putc>
      state = 0;
 64c:	4981                	li	s3,0
 64e:	b565                	j	4f6 <vprintf+0x60>
        s = va_arg(ap, char*);
 650:	8b4a                	mv	s6,s2
      state = 0;
 652:	4981                	li	s3,0
 654:	b54d                	j	4f6 <vprintf+0x60>
    }
  }
}
 656:	70e6                	ld	ra,120(sp)
 658:	7446                	ld	s0,112(sp)
 65a:	74a6                	ld	s1,104(sp)
 65c:	7906                	ld	s2,96(sp)
 65e:	69e6                	ld	s3,88(sp)
 660:	6a46                	ld	s4,80(sp)
 662:	6aa6                	ld	s5,72(sp)
 664:	6b06                	ld	s6,64(sp)
 666:	7be2                	ld	s7,56(sp)
 668:	7c42                	ld	s8,48(sp)
 66a:	7ca2                	ld	s9,40(sp)
 66c:	7d02                	ld	s10,32(sp)
 66e:	6de2                	ld	s11,24(sp)
 670:	6109                	addi	sp,sp,128
 672:	8082                	ret

0000000000000674 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 674:	715d                	addi	sp,sp,-80
 676:	ec06                	sd	ra,24(sp)
 678:	e822                	sd	s0,16(sp)
 67a:	1000                	addi	s0,sp,32
 67c:	e010                	sd	a2,0(s0)
 67e:	e414                	sd	a3,8(s0)
 680:	e818                	sd	a4,16(s0)
 682:	ec1c                	sd	a5,24(s0)
 684:	03043023          	sd	a6,32(s0)
 688:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 68c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 690:	8622                	mv	a2,s0
 692:	00000097          	auipc	ra,0x0
 696:	e04080e7          	jalr	-508(ra) # 496 <vprintf>
}
 69a:	60e2                	ld	ra,24(sp)
 69c:	6442                	ld	s0,16(sp)
 69e:	6161                	addi	sp,sp,80
 6a0:	8082                	ret

00000000000006a2 <printf>:

void
printf(const char *fmt, ...)
{
 6a2:	711d                	addi	sp,sp,-96
 6a4:	ec06                	sd	ra,24(sp)
 6a6:	e822                	sd	s0,16(sp)
 6a8:	1000                	addi	s0,sp,32
 6aa:	e40c                	sd	a1,8(s0)
 6ac:	e810                	sd	a2,16(s0)
 6ae:	ec14                	sd	a3,24(s0)
 6b0:	f018                	sd	a4,32(s0)
 6b2:	f41c                	sd	a5,40(s0)
 6b4:	03043823          	sd	a6,48(s0)
 6b8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6bc:	00840613          	addi	a2,s0,8
 6c0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6c4:	85aa                	mv	a1,a0
 6c6:	4505                	li	a0,1
 6c8:	00000097          	auipc	ra,0x0
 6cc:	dce080e7          	jalr	-562(ra) # 496 <vprintf>
}
 6d0:	60e2                	ld	ra,24(sp)
 6d2:	6442                	ld	s0,16(sp)
 6d4:	6125                	addi	sp,sp,96
 6d6:	8082                	ret

00000000000006d8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6d8:	1141                	addi	sp,sp,-16
 6da:	e422                	sd	s0,8(sp)
 6dc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6de:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e2:	00001797          	auipc	a5,0x1
 6e6:	91e7b783          	ld	a5,-1762(a5) # 1000 <freep>
 6ea:	a02d                	j	714 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6ec:	4618                	lw	a4,8(a2)
 6ee:	9f2d                	addw	a4,a4,a1
 6f0:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6f4:	6398                	ld	a4,0(a5)
 6f6:	6310                	ld	a2,0(a4)
 6f8:	a83d                	j	736 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6fa:	ff852703          	lw	a4,-8(a0)
 6fe:	9f31                	addw	a4,a4,a2
 700:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 702:	ff053683          	ld	a3,-16(a0)
 706:	a091                	j	74a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 708:	6398                	ld	a4,0(a5)
 70a:	00e7e463          	bltu	a5,a4,712 <free+0x3a>
 70e:	00e6ea63          	bltu	a3,a4,722 <free+0x4a>
{
 712:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 714:	fed7fae3          	bgeu	a5,a3,708 <free+0x30>
 718:	6398                	ld	a4,0(a5)
 71a:	00e6e463          	bltu	a3,a4,722 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 71e:	fee7eae3          	bltu	a5,a4,712 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 722:	ff852583          	lw	a1,-8(a0)
 726:	6390                	ld	a2,0(a5)
 728:	02059813          	slli	a6,a1,0x20
 72c:	01c85713          	srli	a4,a6,0x1c
 730:	9736                	add	a4,a4,a3
 732:	fae60de3          	beq	a2,a4,6ec <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 736:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 73a:	4790                	lw	a2,8(a5)
 73c:	02061593          	slli	a1,a2,0x20
 740:	01c5d713          	srli	a4,a1,0x1c
 744:	973e                	add	a4,a4,a5
 746:	fae68ae3          	beq	a3,a4,6fa <free+0x22>
    p->s.ptr = bp->s.ptr;
 74a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 74c:	00001717          	auipc	a4,0x1
 750:	8af73a23          	sd	a5,-1868(a4) # 1000 <freep>
}
 754:	6422                	ld	s0,8(sp)
 756:	0141                	addi	sp,sp,16
 758:	8082                	ret

000000000000075a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 75a:	7139                	addi	sp,sp,-64
 75c:	fc06                	sd	ra,56(sp)
 75e:	f822                	sd	s0,48(sp)
 760:	f426                	sd	s1,40(sp)
 762:	f04a                	sd	s2,32(sp)
 764:	ec4e                	sd	s3,24(sp)
 766:	e852                	sd	s4,16(sp)
 768:	e456                	sd	s5,8(sp)
 76a:	e05a                	sd	s6,0(sp)
 76c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 76e:	02051493          	slli	s1,a0,0x20
 772:	9081                	srli	s1,s1,0x20
 774:	04bd                	addi	s1,s1,15
 776:	8091                	srli	s1,s1,0x4
 778:	0014899b          	addiw	s3,s1,1
 77c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 77e:	00001517          	auipc	a0,0x1
 782:	88253503          	ld	a0,-1918(a0) # 1000 <freep>
 786:	c515                	beqz	a0,7b2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 788:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 78a:	4798                	lw	a4,8(a5)
 78c:	02977f63          	bgeu	a4,s1,7ca <malloc+0x70>
 790:	8a4e                	mv	s4,s3
 792:	0009871b          	sext.w	a4,s3
 796:	6685                	lui	a3,0x1
 798:	00d77363          	bgeu	a4,a3,79e <malloc+0x44>
 79c:	6a05                	lui	s4,0x1
 79e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7a2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7a6:	00001917          	auipc	s2,0x1
 7aa:	85a90913          	addi	s2,s2,-1958 # 1000 <freep>
  if(p == (char*)-1)
 7ae:	5afd                	li	s5,-1
 7b0:	a895                	j	824 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7b2:	00001797          	auipc	a5,0x1
 7b6:	85e78793          	addi	a5,a5,-1954 # 1010 <base>
 7ba:	00001717          	auipc	a4,0x1
 7be:	84f73323          	sd	a5,-1978(a4) # 1000 <freep>
 7c2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7c4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7c8:	b7e1                	j	790 <malloc+0x36>
      if(p->s.size == nunits)
 7ca:	02e48c63          	beq	s1,a4,802 <malloc+0xa8>
        p->s.size -= nunits;
 7ce:	4137073b          	subw	a4,a4,s3
 7d2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7d4:	02071693          	slli	a3,a4,0x20
 7d8:	01c6d713          	srli	a4,a3,0x1c
 7dc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7de:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7e2:	00001717          	auipc	a4,0x1
 7e6:	80a73f23          	sd	a0,-2018(a4) # 1000 <freep>
      return (void*)(p + 1);
 7ea:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ee:	70e2                	ld	ra,56(sp)
 7f0:	7442                	ld	s0,48(sp)
 7f2:	74a2                	ld	s1,40(sp)
 7f4:	7902                	ld	s2,32(sp)
 7f6:	69e2                	ld	s3,24(sp)
 7f8:	6a42                	ld	s4,16(sp)
 7fa:	6aa2                	ld	s5,8(sp)
 7fc:	6b02                	ld	s6,0(sp)
 7fe:	6121                	addi	sp,sp,64
 800:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 802:	6398                	ld	a4,0(a5)
 804:	e118                	sd	a4,0(a0)
 806:	bff1                	j	7e2 <malloc+0x88>
  hp->s.size = nu;
 808:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 80c:	0541                	addi	a0,a0,16
 80e:	00000097          	auipc	ra,0x0
 812:	eca080e7          	jalr	-310(ra) # 6d8 <free>
  return freep;
 816:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 81a:	d971                	beqz	a0,7ee <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 81c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 81e:	4798                	lw	a4,8(a5)
 820:	fa9775e3          	bgeu	a4,s1,7ca <malloc+0x70>
    if(p == freep)
 824:	00093703          	ld	a4,0(s2)
 828:	853e                	mv	a0,a5
 82a:	fef719e3          	bne	a4,a5,81c <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 82e:	8552                	mv	a0,s4
 830:	00000097          	auipc	ra,0x0
 834:	b58080e7          	jalr	-1192(ra) # 388 <sbrk>
  if(p == (char*)-1)
 838:	fd5518e3          	bne	a0,s5,808 <malloc+0xae>
        return 0;
 83c:	4501                	li	a0,0
 83e:	bf45                	j	7ee <malloc+0x94>

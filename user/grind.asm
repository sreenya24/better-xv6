
user/_grind:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <do_rand>:
#include "kernel/riscv.h"

// from FreeBSD.
int
do_rand(unsigned long *ctx)
{
       0:	1141                	addi	sp,sp,-16
       2:	e422                	sd	s0,8(sp)
       4:	0800                	addi	s0,sp,16
 * October 1988, p. 1195.
 */
    long hi, lo, x;

    /* Transform to [1, 0x7ffffffe] range. */
    x = (*ctx % 0x7ffffffe) + 1;
       6:	611c                	ld	a5,0(a0)
       8:	80000737          	lui	a4,0x80000
       c:	ffe74713          	xori	a4,a4,-2
      10:	02e7f7b3          	remu	a5,a5,a4
      14:	0785                	addi	a5,a5,1
    hi = x / 127773;
    lo = x % 127773;
      16:	66fd                	lui	a3,0x1f
      18:	31d68693          	addi	a3,a3,797 # 1f31d <base+0x1cf15>
      1c:	02d7e733          	rem	a4,a5,a3
    x = 16807 * lo - 2836 * hi;
      20:	6611                	lui	a2,0x4
      22:	1a760613          	addi	a2,a2,423 # 41a7 <base+0x1d9f>
      26:	02c70733          	mul	a4,a4,a2
    hi = x / 127773;
      2a:	02d7c7b3          	div	a5,a5,a3
    x = 16807 * lo - 2836 * hi;
      2e:	76fd                	lui	a3,0xfffff
      30:	4ec68693          	addi	a3,a3,1260 # fffffffffffff4ec <base+0xffffffffffffd0e4>
      34:	02d787b3          	mul	a5,a5,a3
      38:	97ba                	add	a5,a5,a4
    if (x < 0)
      3a:	0007c963          	bltz	a5,4c <do_rand+0x4c>
        x += 0x7fffffff;
    /* Transform to [0, 0x7ffffffd] range. */
    x--;
      3e:	17fd                	addi	a5,a5,-1
    *ctx = x;
      40:	e11c                	sd	a5,0(a0)
    return (x);
}
      42:	0007851b          	sext.w	a0,a5
      46:	6422                	ld	s0,8(sp)
      48:	0141                	addi	sp,sp,16
      4a:	8082                	ret
        x += 0x7fffffff;
      4c:	80000737          	lui	a4,0x80000
      50:	fff74713          	not	a4,a4
      54:	97ba                	add	a5,a5,a4
      56:	b7e5                	j	3e <do_rand+0x3e>

0000000000000058 <rand>:

unsigned long rand_next = 1;

int
rand(void)
{
      58:	1141                	addi	sp,sp,-16
      5a:	e406                	sd	ra,8(sp)
      5c:	e022                	sd	s0,0(sp)
      5e:	0800                	addi	s0,sp,16
    return (do_rand(&rand_next));
      60:	00002517          	auipc	a0,0x2
      64:	fa050513          	addi	a0,a0,-96 # 2000 <rand_next>
      68:	00000097          	auipc	ra,0x0
      6c:	f98080e7          	jalr	-104(ra) # 0 <do_rand>
}
      70:	60a2                	ld	ra,8(sp)
      72:	6402                	ld	s0,0(sp)
      74:	0141                	addi	sp,sp,16
      76:	8082                	ret

0000000000000078 <go>:

void
go(int which_child)
{
      78:	7159                	addi	sp,sp,-112
      7a:	f486                	sd	ra,104(sp)
      7c:	f0a2                	sd	s0,96(sp)
      7e:	eca6                	sd	s1,88(sp)
      80:	e8ca                	sd	s2,80(sp)
      82:	e4ce                	sd	s3,72(sp)
      84:	e0d2                	sd	s4,64(sp)
      86:	fc56                	sd	s5,56(sp)
      88:	f85a                	sd	s6,48(sp)
      8a:	1880                	addi	s0,sp,112
      8c:	84aa                	mv	s1,a0
  int fd = -1;
  static char buf[999];
  char *break0 = sbrk(0);
      8e:	4501                	li	a0,0
      90:	00001097          	auipc	ra,0x1
      94:	e24080e7          	jalr	-476(ra) # eb4 <sbrk>
      98:	8aaa                	mv	s5,a0
  uint64 iters = 0;

  mkdir("grindir");
      9a:	00001517          	auipc	a0,0x1
      9e:	2d650513          	addi	a0,a0,726 # 1370 <malloc+0xea>
      a2:	00001097          	auipc	ra,0x1
      a6:	df2080e7          	jalr	-526(ra) # e94 <mkdir>
  if(chdir("grindir") != 0){
      aa:	00001517          	auipc	a0,0x1
      ae:	2c650513          	addi	a0,a0,710 # 1370 <malloc+0xea>
      b2:	00001097          	auipc	ra,0x1
      b6:	dea080e7          	jalr	-534(ra) # e9c <chdir>
      ba:	cd11                	beqz	a0,d6 <go+0x5e>
    printf("grind: chdir grindir failed\n");
      bc:	00001517          	auipc	a0,0x1
      c0:	2bc50513          	addi	a0,a0,700 # 1378 <malloc+0xf2>
      c4:	00001097          	auipc	ra,0x1
      c8:	10a080e7          	jalr	266(ra) # 11ce <printf>
    exit(1);
      cc:	4505                	li	a0,1
      ce:	00001097          	auipc	ra,0x1
      d2:	d5e080e7          	jalr	-674(ra) # e2c <exit>
  }
  chdir("/");
      d6:	00001517          	auipc	a0,0x1
      da:	2c250513          	addi	a0,a0,706 # 1398 <malloc+0x112>
      de:	00001097          	auipc	ra,0x1
      e2:	dbe080e7          	jalr	-578(ra) # e9c <chdir>
  
  while(1){
    iters++;
    if((iters % 500) == 0)
      e6:	00001997          	auipc	s3,0x1
      ea:	2c298993          	addi	s3,s3,706 # 13a8 <malloc+0x122>
      ee:	c489                	beqz	s1,f8 <go+0x80>
      f0:	00001997          	auipc	s3,0x1
      f4:	2b098993          	addi	s3,s3,688 # 13a0 <malloc+0x11a>
    iters++;
      f8:	4485                	li	s1,1
  int fd = -1;
      fa:	5a7d                	li	s4,-1
      fc:	00001917          	auipc	s2,0x1
     100:	55c90913          	addi	s2,s2,1372 # 1658 <malloc+0x3d2>
     104:	a825                	j	13c <go+0xc4>
      write(1, which_child?"B":"A", 1);
    int what = rand() % 23;
    if(what == 1){
      close(open("grindir/../a", O_CREATE|O_RDWR));
     106:	20200593          	li	a1,514
     10a:	00001517          	auipc	a0,0x1
     10e:	2a650513          	addi	a0,a0,678 # 13b0 <malloc+0x12a>
     112:	00001097          	auipc	ra,0x1
     116:	d5a080e7          	jalr	-678(ra) # e6c <open>
     11a:	00001097          	auipc	ra,0x1
     11e:	d3a080e7          	jalr	-710(ra) # e54 <close>
    iters++;
     122:	0485                	addi	s1,s1,1
    if((iters % 500) == 0)
     124:	1f400793          	li	a5,500
     128:	02f4f7b3          	remu	a5,s1,a5
     12c:	eb81                	bnez	a5,13c <go+0xc4>
      write(1, which_child?"B":"A", 1);
     12e:	4605                	li	a2,1
     130:	85ce                	mv	a1,s3
     132:	4505                	li	a0,1
     134:	00001097          	auipc	ra,0x1
     138:	d18080e7          	jalr	-744(ra) # e4c <write>
    int what = rand() % 23;
     13c:	00000097          	auipc	ra,0x0
     140:	f1c080e7          	jalr	-228(ra) # 58 <rand>
     144:	47dd                	li	a5,23
     146:	02f5653b          	remw	a0,a0,a5
    if(what == 1){
     14a:	4785                	li	a5,1
     14c:	faf50de3          	beq	a0,a5,106 <go+0x8e>
    } else if(what == 2){
     150:	47d9                	li	a5,22
     152:	fca7e8e3          	bltu	a5,a0,122 <go+0xaa>
     156:	050a                	slli	a0,a0,0x2
     158:	954a                	add	a0,a0,s2
     15a:	411c                	lw	a5,0(a0)
     15c:	97ca                	add	a5,a5,s2
     15e:	8782                	jr	a5
      close(open("grindir/../grindir/../b", O_CREATE|O_RDWR));
     160:	20200593          	li	a1,514
     164:	00001517          	auipc	a0,0x1
     168:	25c50513          	addi	a0,a0,604 # 13c0 <malloc+0x13a>
     16c:	00001097          	auipc	ra,0x1
     170:	d00080e7          	jalr	-768(ra) # e6c <open>
     174:	00001097          	auipc	ra,0x1
     178:	ce0080e7          	jalr	-800(ra) # e54 <close>
     17c:	b75d                	j	122 <go+0xaa>
    } else if(what == 3){
      unlink("grindir/../a");
     17e:	00001517          	auipc	a0,0x1
     182:	23250513          	addi	a0,a0,562 # 13b0 <malloc+0x12a>
     186:	00001097          	auipc	ra,0x1
     18a:	cf6080e7          	jalr	-778(ra) # e7c <unlink>
     18e:	bf51                	j	122 <go+0xaa>
    } else if(what == 4){
      if(chdir("grindir") != 0){
     190:	00001517          	auipc	a0,0x1
     194:	1e050513          	addi	a0,a0,480 # 1370 <malloc+0xea>
     198:	00001097          	auipc	ra,0x1
     19c:	d04080e7          	jalr	-764(ra) # e9c <chdir>
     1a0:	e115                	bnez	a0,1c4 <go+0x14c>
        printf("grind: chdir grindir failed\n");
        exit(1);
      }
      unlink("../b");
     1a2:	00001517          	auipc	a0,0x1
     1a6:	23650513          	addi	a0,a0,566 # 13d8 <malloc+0x152>
     1aa:	00001097          	auipc	ra,0x1
     1ae:	cd2080e7          	jalr	-814(ra) # e7c <unlink>
      chdir("/");
     1b2:	00001517          	auipc	a0,0x1
     1b6:	1e650513          	addi	a0,a0,486 # 1398 <malloc+0x112>
     1ba:	00001097          	auipc	ra,0x1
     1be:	ce2080e7          	jalr	-798(ra) # e9c <chdir>
     1c2:	b785                	j	122 <go+0xaa>
        printf("grind: chdir grindir failed\n");
     1c4:	00001517          	auipc	a0,0x1
     1c8:	1b450513          	addi	a0,a0,436 # 1378 <malloc+0xf2>
     1cc:	00001097          	auipc	ra,0x1
     1d0:	002080e7          	jalr	2(ra) # 11ce <printf>
        exit(1);
     1d4:	4505                	li	a0,1
     1d6:	00001097          	auipc	ra,0x1
     1da:	c56080e7          	jalr	-938(ra) # e2c <exit>
    } else if(what == 5){
      close(fd);
     1de:	8552                	mv	a0,s4
     1e0:	00001097          	auipc	ra,0x1
     1e4:	c74080e7          	jalr	-908(ra) # e54 <close>
      fd = open("/grindir/../a", O_CREATE|O_RDWR);
     1e8:	20200593          	li	a1,514
     1ec:	00001517          	auipc	a0,0x1
     1f0:	1f450513          	addi	a0,a0,500 # 13e0 <malloc+0x15a>
     1f4:	00001097          	auipc	ra,0x1
     1f8:	c78080e7          	jalr	-904(ra) # e6c <open>
     1fc:	8a2a                	mv	s4,a0
     1fe:	b715                	j	122 <go+0xaa>
    } else if(what == 6){
      close(fd);
     200:	8552                	mv	a0,s4
     202:	00001097          	auipc	ra,0x1
     206:	c52080e7          	jalr	-942(ra) # e54 <close>
      fd = open("/./grindir/./../b", O_CREATE|O_RDWR);
     20a:	20200593          	li	a1,514
     20e:	00001517          	auipc	a0,0x1
     212:	1e250513          	addi	a0,a0,482 # 13f0 <malloc+0x16a>
     216:	00001097          	auipc	ra,0x1
     21a:	c56080e7          	jalr	-938(ra) # e6c <open>
     21e:	8a2a                	mv	s4,a0
     220:	b709                	j	122 <go+0xaa>
    } else if(what == 7){
      write(fd, buf, sizeof(buf));
     222:	3e700613          	li	a2,999
     226:	00002597          	auipc	a1,0x2
     22a:	dfa58593          	addi	a1,a1,-518 # 2020 <buf.0>
     22e:	8552                	mv	a0,s4
     230:	00001097          	auipc	ra,0x1
     234:	c1c080e7          	jalr	-996(ra) # e4c <write>
     238:	b5ed                	j	122 <go+0xaa>
    } else if(what == 8){
      read(fd, buf, sizeof(buf));
     23a:	3e700613          	li	a2,999
     23e:	00002597          	auipc	a1,0x2
     242:	de258593          	addi	a1,a1,-542 # 2020 <buf.0>
     246:	8552                	mv	a0,s4
     248:	00001097          	auipc	ra,0x1
     24c:	bfc080e7          	jalr	-1028(ra) # e44 <read>
     250:	bdc9                	j	122 <go+0xaa>
    } else if(what == 9){
      mkdir("grindir/../a");
     252:	00001517          	auipc	a0,0x1
     256:	15e50513          	addi	a0,a0,350 # 13b0 <malloc+0x12a>
     25a:	00001097          	auipc	ra,0x1
     25e:	c3a080e7          	jalr	-966(ra) # e94 <mkdir>
      close(open("a/../a/./a", O_CREATE|O_RDWR));
     262:	20200593          	li	a1,514
     266:	00001517          	auipc	a0,0x1
     26a:	1a250513          	addi	a0,a0,418 # 1408 <malloc+0x182>
     26e:	00001097          	auipc	ra,0x1
     272:	bfe080e7          	jalr	-1026(ra) # e6c <open>
     276:	00001097          	auipc	ra,0x1
     27a:	bde080e7          	jalr	-1058(ra) # e54 <close>
      unlink("a/a");
     27e:	00001517          	auipc	a0,0x1
     282:	19a50513          	addi	a0,a0,410 # 1418 <malloc+0x192>
     286:	00001097          	auipc	ra,0x1
     28a:	bf6080e7          	jalr	-1034(ra) # e7c <unlink>
     28e:	bd51                	j	122 <go+0xaa>
    } else if(what == 10){
      mkdir("/../b");
     290:	00001517          	auipc	a0,0x1
     294:	19050513          	addi	a0,a0,400 # 1420 <malloc+0x19a>
     298:	00001097          	auipc	ra,0x1
     29c:	bfc080e7          	jalr	-1028(ra) # e94 <mkdir>
      close(open("grindir/../b/b", O_CREATE|O_RDWR));
     2a0:	20200593          	li	a1,514
     2a4:	00001517          	auipc	a0,0x1
     2a8:	18450513          	addi	a0,a0,388 # 1428 <malloc+0x1a2>
     2ac:	00001097          	auipc	ra,0x1
     2b0:	bc0080e7          	jalr	-1088(ra) # e6c <open>
     2b4:	00001097          	auipc	ra,0x1
     2b8:	ba0080e7          	jalr	-1120(ra) # e54 <close>
      unlink("b/b");
     2bc:	00001517          	auipc	a0,0x1
     2c0:	17c50513          	addi	a0,a0,380 # 1438 <malloc+0x1b2>
     2c4:	00001097          	auipc	ra,0x1
     2c8:	bb8080e7          	jalr	-1096(ra) # e7c <unlink>
     2cc:	bd99                	j	122 <go+0xaa>
    } else if(what == 11){
      unlink("b");
     2ce:	00001517          	auipc	a0,0x1
     2d2:	13250513          	addi	a0,a0,306 # 1400 <malloc+0x17a>
     2d6:	00001097          	auipc	ra,0x1
     2da:	ba6080e7          	jalr	-1114(ra) # e7c <unlink>
      link("../grindir/./../a", "../b");
     2de:	00001597          	auipc	a1,0x1
     2e2:	0fa58593          	addi	a1,a1,250 # 13d8 <malloc+0x152>
     2e6:	00001517          	auipc	a0,0x1
     2ea:	15a50513          	addi	a0,a0,346 # 1440 <malloc+0x1ba>
     2ee:	00001097          	auipc	ra,0x1
     2f2:	b9e080e7          	jalr	-1122(ra) # e8c <link>
     2f6:	b535                	j	122 <go+0xaa>
    } else if(what == 12){
      unlink("../grindir/../a");
     2f8:	00001517          	auipc	a0,0x1
     2fc:	16050513          	addi	a0,a0,352 # 1458 <malloc+0x1d2>
     300:	00001097          	auipc	ra,0x1
     304:	b7c080e7          	jalr	-1156(ra) # e7c <unlink>
      link(".././b", "/grindir/../a");
     308:	00001597          	auipc	a1,0x1
     30c:	0d858593          	addi	a1,a1,216 # 13e0 <malloc+0x15a>
     310:	00001517          	auipc	a0,0x1
     314:	15850513          	addi	a0,a0,344 # 1468 <malloc+0x1e2>
     318:	00001097          	auipc	ra,0x1
     31c:	b74080e7          	jalr	-1164(ra) # e8c <link>
     320:	b509                	j	122 <go+0xaa>
    } else if(what == 13){
      int pid = fork();
     322:	00001097          	auipc	ra,0x1
     326:	b02080e7          	jalr	-1278(ra) # e24 <fork>
      if(pid == 0){
     32a:	c909                	beqz	a0,33c <go+0x2c4>
        exit(0);
      } else if(pid < 0){
     32c:	00054c63          	bltz	a0,344 <go+0x2cc>
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
     330:	4501                	li	a0,0
     332:	00001097          	auipc	ra,0x1
     336:	b02080e7          	jalr	-1278(ra) # e34 <wait>
     33a:	b3e5                	j	122 <go+0xaa>
        exit(0);
     33c:	00001097          	auipc	ra,0x1
     340:	af0080e7          	jalr	-1296(ra) # e2c <exit>
        printf("grind: fork failed\n");
     344:	00001517          	auipc	a0,0x1
     348:	12c50513          	addi	a0,a0,300 # 1470 <malloc+0x1ea>
     34c:	00001097          	auipc	ra,0x1
     350:	e82080e7          	jalr	-382(ra) # 11ce <printf>
        exit(1);
     354:	4505                	li	a0,1
     356:	00001097          	auipc	ra,0x1
     35a:	ad6080e7          	jalr	-1322(ra) # e2c <exit>
    } else if(what == 14){
      int pid = fork();
     35e:	00001097          	auipc	ra,0x1
     362:	ac6080e7          	jalr	-1338(ra) # e24 <fork>
      if(pid == 0){
     366:	c909                	beqz	a0,378 <go+0x300>
        fork();
        fork();
        exit(0);
      } else if(pid < 0){
     368:	02054563          	bltz	a0,392 <go+0x31a>
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
     36c:	4501                	li	a0,0
     36e:	00001097          	auipc	ra,0x1
     372:	ac6080e7          	jalr	-1338(ra) # e34 <wait>
     376:	b375                	j	122 <go+0xaa>
        fork();
     378:	00001097          	auipc	ra,0x1
     37c:	aac080e7          	jalr	-1364(ra) # e24 <fork>
        fork();
     380:	00001097          	auipc	ra,0x1
     384:	aa4080e7          	jalr	-1372(ra) # e24 <fork>
        exit(0);
     388:	4501                	li	a0,0
     38a:	00001097          	auipc	ra,0x1
     38e:	aa2080e7          	jalr	-1374(ra) # e2c <exit>
        printf("grind: fork failed\n");
     392:	00001517          	auipc	a0,0x1
     396:	0de50513          	addi	a0,a0,222 # 1470 <malloc+0x1ea>
     39a:	00001097          	auipc	ra,0x1
     39e:	e34080e7          	jalr	-460(ra) # 11ce <printf>
        exit(1);
     3a2:	4505                	li	a0,1
     3a4:	00001097          	auipc	ra,0x1
     3a8:	a88080e7          	jalr	-1400(ra) # e2c <exit>
    } else if(what == 15){
      sbrk(6011);
     3ac:	6505                	lui	a0,0x1
     3ae:	77b50513          	addi	a0,a0,1915 # 177b <digits+0x63>
     3b2:	00001097          	auipc	ra,0x1
     3b6:	b02080e7          	jalr	-1278(ra) # eb4 <sbrk>
     3ba:	b3a5                	j	122 <go+0xaa>
    } else if(what == 16){
      if(sbrk(0) > break0)
     3bc:	4501                	li	a0,0
     3be:	00001097          	auipc	ra,0x1
     3c2:	af6080e7          	jalr	-1290(ra) # eb4 <sbrk>
     3c6:	d4aafee3          	bgeu	s5,a0,122 <go+0xaa>
        sbrk(-(sbrk(0) - break0));
     3ca:	4501                	li	a0,0
     3cc:	00001097          	auipc	ra,0x1
     3d0:	ae8080e7          	jalr	-1304(ra) # eb4 <sbrk>
     3d4:	40aa853b          	subw	a0,s5,a0
     3d8:	00001097          	auipc	ra,0x1
     3dc:	adc080e7          	jalr	-1316(ra) # eb4 <sbrk>
     3e0:	b389                	j	122 <go+0xaa>
    } else if(what == 17){
      int pid = fork();
     3e2:	00001097          	auipc	ra,0x1
     3e6:	a42080e7          	jalr	-1470(ra) # e24 <fork>
     3ea:	8b2a                	mv	s6,a0
      if(pid == 0){
     3ec:	c51d                	beqz	a0,41a <go+0x3a2>
        close(open("a", O_CREATE|O_RDWR));
        exit(0);
      } else if(pid < 0){
     3ee:	04054963          	bltz	a0,440 <go+0x3c8>
        printf("grind: fork failed\n");
        exit(1);
      }
      if(chdir("../grindir/..") != 0){
     3f2:	00001517          	auipc	a0,0x1
     3f6:	09650513          	addi	a0,a0,150 # 1488 <malloc+0x202>
     3fa:	00001097          	auipc	ra,0x1
     3fe:	aa2080e7          	jalr	-1374(ra) # e9c <chdir>
     402:	ed21                	bnez	a0,45a <go+0x3e2>
        printf("grind: chdir failed\n");
        exit(1);
      }
      kill(pid);
     404:	855a                	mv	a0,s6
     406:	00001097          	auipc	ra,0x1
     40a:	a56080e7          	jalr	-1450(ra) # e5c <kill>
      wait(0);
     40e:	4501                	li	a0,0
     410:	00001097          	auipc	ra,0x1
     414:	a24080e7          	jalr	-1500(ra) # e34 <wait>
     418:	b329                	j	122 <go+0xaa>
        close(open("a", O_CREATE|O_RDWR));
     41a:	20200593          	li	a1,514
     41e:	00001517          	auipc	a0,0x1
     422:	03250513          	addi	a0,a0,50 # 1450 <malloc+0x1ca>
     426:	00001097          	auipc	ra,0x1
     42a:	a46080e7          	jalr	-1466(ra) # e6c <open>
     42e:	00001097          	auipc	ra,0x1
     432:	a26080e7          	jalr	-1498(ra) # e54 <close>
        exit(0);
     436:	4501                	li	a0,0
     438:	00001097          	auipc	ra,0x1
     43c:	9f4080e7          	jalr	-1548(ra) # e2c <exit>
        printf("grind: fork failed\n");
     440:	00001517          	auipc	a0,0x1
     444:	03050513          	addi	a0,a0,48 # 1470 <malloc+0x1ea>
     448:	00001097          	auipc	ra,0x1
     44c:	d86080e7          	jalr	-634(ra) # 11ce <printf>
        exit(1);
     450:	4505                	li	a0,1
     452:	00001097          	auipc	ra,0x1
     456:	9da080e7          	jalr	-1574(ra) # e2c <exit>
        printf("grind: chdir failed\n");
     45a:	00001517          	auipc	a0,0x1
     45e:	03e50513          	addi	a0,a0,62 # 1498 <malloc+0x212>
     462:	00001097          	auipc	ra,0x1
     466:	d6c080e7          	jalr	-660(ra) # 11ce <printf>
        exit(1);
     46a:	4505                	li	a0,1
     46c:	00001097          	auipc	ra,0x1
     470:	9c0080e7          	jalr	-1600(ra) # e2c <exit>
    } else if(what == 18){
      int pid = fork();
     474:	00001097          	auipc	ra,0x1
     478:	9b0080e7          	jalr	-1616(ra) # e24 <fork>
      if(pid == 0){
     47c:	c909                	beqz	a0,48e <go+0x416>
        kill(getpid());
        exit(0);
      } else if(pid < 0){
     47e:	02054563          	bltz	a0,4a8 <go+0x430>
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
     482:	4501                	li	a0,0
     484:	00001097          	auipc	ra,0x1
     488:	9b0080e7          	jalr	-1616(ra) # e34 <wait>
     48c:	b959                	j	122 <go+0xaa>
        kill(getpid());
     48e:	00001097          	auipc	ra,0x1
     492:	a1e080e7          	jalr	-1506(ra) # eac <getpid>
     496:	00001097          	auipc	ra,0x1
     49a:	9c6080e7          	jalr	-1594(ra) # e5c <kill>
        exit(0);
     49e:	4501                	li	a0,0
     4a0:	00001097          	auipc	ra,0x1
     4a4:	98c080e7          	jalr	-1652(ra) # e2c <exit>
        printf("grind: fork failed\n");
     4a8:	00001517          	auipc	a0,0x1
     4ac:	fc850513          	addi	a0,a0,-56 # 1470 <malloc+0x1ea>
     4b0:	00001097          	auipc	ra,0x1
     4b4:	d1e080e7          	jalr	-738(ra) # 11ce <printf>
        exit(1);
     4b8:	4505                	li	a0,1
     4ba:	00001097          	auipc	ra,0x1
     4be:	972080e7          	jalr	-1678(ra) # e2c <exit>
    } else if(what == 19){
      int fds[2];
      if(pipe(fds) < 0){
     4c2:	fa840513          	addi	a0,s0,-88
     4c6:	00001097          	auipc	ra,0x1
     4ca:	976080e7          	jalr	-1674(ra) # e3c <pipe>
     4ce:	02054b63          	bltz	a0,504 <go+0x48c>
        printf("grind: pipe failed\n");
        exit(1);
      }
      int pid = fork();
     4d2:	00001097          	auipc	ra,0x1
     4d6:	952080e7          	jalr	-1710(ra) # e24 <fork>
      if(pid == 0){
     4da:	c131                	beqz	a0,51e <go+0x4a6>
          printf("grind: pipe write failed\n");
        char c;
        if(read(fds[0], &c, 1) != 1)
          printf("grind: pipe read failed\n");
        exit(0);
      } else if(pid < 0){
     4dc:	0a054a63          	bltz	a0,590 <go+0x518>
        printf("grind: fork failed\n");
        exit(1);
      }
      close(fds[0]);
     4e0:	fa842503          	lw	a0,-88(s0)
     4e4:	00001097          	auipc	ra,0x1
     4e8:	970080e7          	jalr	-1680(ra) # e54 <close>
      close(fds[1]);
     4ec:	fac42503          	lw	a0,-84(s0)
     4f0:	00001097          	auipc	ra,0x1
     4f4:	964080e7          	jalr	-1692(ra) # e54 <close>
      wait(0);
     4f8:	4501                	li	a0,0
     4fa:	00001097          	auipc	ra,0x1
     4fe:	93a080e7          	jalr	-1734(ra) # e34 <wait>
     502:	b105                	j	122 <go+0xaa>
        printf("grind: pipe failed\n");
     504:	00001517          	auipc	a0,0x1
     508:	fac50513          	addi	a0,a0,-84 # 14b0 <malloc+0x22a>
     50c:	00001097          	auipc	ra,0x1
     510:	cc2080e7          	jalr	-830(ra) # 11ce <printf>
        exit(1);
     514:	4505                	li	a0,1
     516:	00001097          	auipc	ra,0x1
     51a:	916080e7          	jalr	-1770(ra) # e2c <exit>
        fork();
     51e:	00001097          	auipc	ra,0x1
     522:	906080e7          	jalr	-1786(ra) # e24 <fork>
        fork();
     526:	00001097          	auipc	ra,0x1
     52a:	8fe080e7          	jalr	-1794(ra) # e24 <fork>
        if(write(fds[1], "x", 1) != 1)
     52e:	4605                	li	a2,1
     530:	00001597          	auipc	a1,0x1
     534:	f9858593          	addi	a1,a1,-104 # 14c8 <malloc+0x242>
     538:	fac42503          	lw	a0,-84(s0)
     53c:	00001097          	auipc	ra,0x1
     540:	910080e7          	jalr	-1776(ra) # e4c <write>
     544:	4785                	li	a5,1
     546:	02f51363          	bne	a0,a5,56c <go+0x4f4>
        if(read(fds[0], &c, 1) != 1)
     54a:	4605                	li	a2,1
     54c:	fa040593          	addi	a1,s0,-96
     550:	fa842503          	lw	a0,-88(s0)
     554:	00001097          	auipc	ra,0x1
     558:	8f0080e7          	jalr	-1808(ra) # e44 <read>
     55c:	4785                	li	a5,1
     55e:	02f51063          	bne	a0,a5,57e <go+0x506>
        exit(0);
     562:	4501                	li	a0,0
     564:	00001097          	auipc	ra,0x1
     568:	8c8080e7          	jalr	-1848(ra) # e2c <exit>
          printf("grind: pipe write failed\n");
     56c:	00001517          	auipc	a0,0x1
     570:	f6450513          	addi	a0,a0,-156 # 14d0 <malloc+0x24a>
     574:	00001097          	auipc	ra,0x1
     578:	c5a080e7          	jalr	-934(ra) # 11ce <printf>
     57c:	b7f9                	j	54a <go+0x4d2>
          printf("grind: pipe read failed\n");
     57e:	00001517          	auipc	a0,0x1
     582:	f7250513          	addi	a0,a0,-142 # 14f0 <malloc+0x26a>
     586:	00001097          	auipc	ra,0x1
     58a:	c48080e7          	jalr	-952(ra) # 11ce <printf>
     58e:	bfd1                	j	562 <go+0x4ea>
        printf("grind: fork failed\n");
     590:	00001517          	auipc	a0,0x1
     594:	ee050513          	addi	a0,a0,-288 # 1470 <malloc+0x1ea>
     598:	00001097          	auipc	ra,0x1
     59c:	c36080e7          	jalr	-970(ra) # 11ce <printf>
        exit(1);
     5a0:	4505                	li	a0,1
     5a2:	00001097          	auipc	ra,0x1
     5a6:	88a080e7          	jalr	-1910(ra) # e2c <exit>
    } else if(what == 20){
      int pid = fork();
     5aa:	00001097          	auipc	ra,0x1
     5ae:	87a080e7          	jalr	-1926(ra) # e24 <fork>
      if(pid == 0){
     5b2:	c909                	beqz	a0,5c4 <go+0x54c>
        chdir("a");
        unlink("../a");
        fd = open("x", O_CREATE|O_RDWR);
        unlink("x");
        exit(0);
      } else if(pid < 0){
     5b4:	06054f63          	bltz	a0,632 <go+0x5ba>
        printf("grind: fork failed\n");
        exit(1);
      }
      wait(0);
     5b8:	4501                	li	a0,0
     5ba:	00001097          	auipc	ra,0x1
     5be:	87a080e7          	jalr	-1926(ra) # e34 <wait>
     5c2:	b685                	j	122 <go+0xaa>
        unlink("a");
     5c4:	00001517          	auipc	a0,0x1
     5c8:	e8c50513          	addi	a0,a0,-372 # 1450 <malloc+0x1ca>
     5cc:	00001097          	auipc	ra,0x1
     5d0:	8b0080e7          	jalr	-1872(ra) # e7c <unlink>
        mkdir("a");
     5d4:	00001517          	auipc	a0,0x1
     5d8:	e7c50513          	addi	a0,a0,-388 # 1450 <malloc+0x1ca>
     5dc:	00001097          	auipc	ra,0x1
     5e0:	8b8080e7          	jalr	-1864(ra) # e94 <mkdir>
        chdir("a");
     5e4:	00001517          	auipc	a0,0x1
     5e8:	e6c50513          	addi	a0,a0,-404 # 1450 <malloc+0x1ca>
     5ec:	00001097          	auipc	ra,0x1
     5f0:	8b0080e7          	jalr	-1872(ra) # e9c <chdir>
        unlink("../a");
     5f4:	00001517          	auipc	a0,0x1
     5f8:	dc450513          	addi	a0,a0,-572 # 13b8 <malloc+0x132>
     5fc:	00001097          	auipc	ra,0x1
     600:	880080e7          	jalr	-1920(ra) # e7c <unlink>
        fd = open("x", O_CREATE|O_RDWR);
     604:	20200593          	li	a1,514
     608:	00001517          	auipc	a0,0x1
     60c:	ec050513          	addi	a0,a0,-320 # 14c8 <malloc+0x242>
     610:	00001097          	auipc	ra,0x1
     614:	85c080e7          	jalr	-1956(ra) # e6c <open>
        unlink("x");
     618:	00001517          	auipc	a0,0x1
     61c:	eb050513          	addi	a0,a0,-336 # 14c8 <malloc+0x242>
     620:	00001097          	auipc	ra,0x1
     624:	85c080e7          	jalr	-1956(ra) # e7c <unlink>
        exit(0);
     628:	4501                	li	a0,0
     62a:	00001097          	auipc	ra,0x1
     62e:	802080e7          	jalr	-2046(ra) # e2c <exit>
        printf("grind: fork failed\n");
     632:	00001517          	auipc	a0,0x1
     636:	e3e50513          	addi	a0,a0,-450 # 1470 <malloc+0x1ea>
     63a:	00001097          	auipc	ra,0x1
     63e:	b94080e7          	jalr	-1132(ra) # 11ce <printf>
        exit(1);
     642:	4505                	li	a0,1
     644:	00000097          	auipc	ra,0x0
     648:	7e8080e7          	jalr	2024(ra) # e2c <exit>
    } else if(what == 21){
      unlink("c");
     64c:	00001517          	auipc	a0,0x1
     650:	ec450513          	addi	a0,a0,-316 # 1510 <malloc+0x28a>
     654:	00001097          	auipc	ra,0x1
     658:	828080e7          	jalr	-2008(ra) # e7c <unlink>
      // should always succeed. check that there are free i-nodes,
      // file descriptors, blocks.
      int fd1 = open("c", O_CREATE|O_RDWR);
     65c:	20200593          	li	a1,514
     660:	00001517          	auipc	a0,0x1
     664:	eb050513          	addi	a0,a0,-336 # 1510 <malloc+0x28a>
     668:	00001097          	auipc	ra,0x1
     66c:	804080e7          	jalr	-2044(ra) # e6c <open>
     670:	8b2a                	mv	s6,a0
      if(fd1 < 0){
     672:	04054f63          	bltz	a0,6d0 <go+0x658>
        printf("grind: create c failed\n");
        exit(1);
      }
      if(write(fd1, "x", 1) != 1){
     676:	4605                	li	a2,1
     678:	00001597          	auipc	a1,0x1
     67c:	e5058593          	addi	a1,a1,-432 # 14c8 <malloc+0x242>
     680:	00000097          	auipc	ra,0x0
     684:	7cc080e7          	jalr	1996(ra) # e4c <write>
     688:	4785                	li	a5,1
     68a:	06f51063          	bne	a0,a5,6ea <go+0x672>
        printf("grind: write c failed\n");
        exit(1);
      }
      struct stats st;
      if(fstat(fd1, &st) != 0){
     68e:	fa840593          	addi	a1,s0,-88
     692:	855a                	mv	a0,s6
     694:	00000097          	auipc	ra,0x0
     698:	7f0080e7          	jalr	2032(ra) # e84 <fstat>
     69c:	e525                	bnez	a0,704 <go+0x68c>
        printf("grind: fstat failed\n");
        exit(1);
      }
      if(st.size != 1){
     69e:	fb442583          	lw	a1,-76(s0)
     6a2:	4785                	li	a5,1
     6a4:	06f59d63          	bne	a1,a5,71e <go+0x6a6>
        printf("grind: fstat reports wrong size %d\n", (int)st.size);
        exit(1);
      }
      if(st.ino > 200){
     6a8:	fac42583          	lw	a1,-84(s0)
     6ac:	0c800793          	li	a5,200
     6b0:	08b7e463          	bltu	a5,a1,738 <go+0x6c0>
        printf("grind: fstat reports crazy i-number %d\n", st.ino);
        exit(1);
      }
      close(fd1);
     6b4:	855a                	mv	a0,s6
     6b6:	00000097          	auipc	ra,0x0
     6ba:	79e080e7          	jalr	1950(ra) # e54 <close>
      unlink("c");
     6be:	00001517          	auipc	a0,0x1
     6c2:	e5250513          	addi	a0,a0,-430 # 1510 <malloc+0x28a>
     6c6:	00000097          	auipc	ra,0x0
     6ca:	7b6080e7          	jalr	1974(ra) # e7c <unlink>
     6ce:	bc91                	j	122 <go+0xaa>
        printf("grind: create c failed\n");
     6d0:	00001517          	auipc	a0,0x1
     6d4:	e4850513          	addi	a0,a0,-440 # 1518 <malloc+0x292>
     6d8:	00001097          	auipc	ra,0x1
     6dc:	af6080e7          	jalr	-1290(ra) # 11ce <printf>
        exit(1);
     6e0:	4505                	li	a0,1
     6e2:	00000097          	auipc	ra,0x0
     6e6:	74a080e7          	jalr	1866(ra) # e2c <exit>
        printf("grind: write c failed\n");
     6ea:	00001517          	auipc	a0,0x1
     6ee:	e4650513          	addi	a0,a0,-442 # 1530 <malloc+0x2aa>
     6f2:	00001097          	auipc	ra,0x1
     6f6:	adc080e7          	jalr	-1316(ra) # 11ce <printf>
        exit(1);
     6fa:	4505                	li	a0,1
     6fc:	00000097          	auipc	ra,0x0
     700:	730080e7          	jalr	1840(ra) # e2c <exit>
        printf("grind: fstat failed\n");
     704:	00001517          	auipc	a0,0x1
     708:	e4450513          	addi	a0,a0,-444 # 1548 <malloc+0x2c2>
     70c:	00001097          	auipc	ra,0x1
     710:	ac2080e7          	jalr	-1342(ra) # 11ce <printf>
        exit(1);
     714:	4505                	li	a0,1
     716:	00000097          	auipc	ra,0x0
     71a:	716080e7          	jalr	1814(ra) # e2c <exit>
        printf("grind: fstat reports wrong size %d\n", (int)st.size);
     71e:	00001517          	auipc	a0,0x1
     722:	e4250513          	addi	a0,a0,-446 # 1560 <malloc+0x2da>
     726:	00001097          	auipc	ra,0x1
     72a:	aa8080e7          	jalr	-1368(ra) # 11ce <printf>
        exit(1);
     72e:	4505                	li	a0,1
     730:	00000097          	auipc	ra,0x0
     734:	6fc080e7          	jalr	1788(ra) # e2c <exit>
        printf("grind: fstat reports crazy i-number %d\n", st.ino);
     738:	00001517          	auipc	a0,0x1
     73c:	e5050513          	addi	a0,a0,-432 # 1588 <malloc+0x302>
     740:	00001097          	auipc	ra,0x1
     744:	a8e080e7          	jalr	-1394(ra) # 11ce <printf>
        exit(1);
     748:	4505                	li	a0,1
     74a:	00000097          	auipc	ra,0x0
     74e:	6e2080e7          	jalr	1762(ra) # e2c <exit>
    } else if(what == 22){
      // echo hi | cat
      int aa[2], bb[2];
      if(pipe(aa) < 0){
     752:	f9840513          	addi	a0,s0,-104
     756:	00000097          	auipc	ra,0x0
     75a:	6e6080e7          	jalr	1766(ra) # e3c <pipe>
     75e:	10054063          	bltz	a0,85e <go+0x7e6>
        fprintf(2, "grind: pipe failed\n");
        exit(1);
      }
      if(pipe(bb) < 0){
     762:	fa040513          	addi	a0,s0,-96
     766:	00000097          	auipc	ra,0x0
     76a:	6d6080e7          	jalr	1750(ra) # e3c <pipe>
     76e:	10054663          	bltz	a0,87a <go+0x802>
        fprintf(2, "grind: pipe failed\n");
        exit(1);
      }
      int pid1 = fork();
     772:	00000097          	auipc	ra,0x0
     776:	6b2080e7          	jalr	1714(ra) # e24 <fork>
      if(pid1 == 0){
     77a:	10050e63          	beqz	a0,896 <go+0x81e>
        close(aa[1]);
        char *args[3] = { "echo", "hi", 0 };
        exec("grindir/../echo", args);
        fprintf(2, "grind: echo: not found\n");
        exit(2);
      } else if(pid1 < 0){
     77e:	1c054663          	bltz	a0,94a <go+0x8d2>
        fprintf(2, "grind: fork failed\n");
        exit(3);
      }
      int pid2 = fork();
     782:	00000097          	auipc	ra,0x0
     786:	6a2080e7          	jalr	1698(ra) # e24 <fork>
      if(pid2 == 0){
     78a:	1c050e63          	beqz	a0,966 <go+0x8ee>
        close(bb[1]);
        char *args[2] = { "cat", 0 };
        exec("/cat", args);
        fprintf(2, "grind: cat: not found\n");
        exit(6);
      } else if(pid2 < 0){
     78e:	2a054a63          	bltz	a0,a42 <go+0x9ca>
        fprintf(2, "grind: fork failed\n");
        exit(7);
      }
      close(aa[0]);
     792:	f9842503          	lw	a0,-104(s0)
     796:	00000097          	auipc	ra,0x0
     79a:	6be080e7          	jalr	1726(ra) # e54 <close>
      close(aa[1]);
     79e:	f9c42503          	lw	a0,-100(s0)
     7a2:	00000097          	auipc	ra,0x0
     7a6:	6b2080e7          	jalr	1714(ra) # e54 <close>
      close(bb[1]);
     7aa:	fa442503          	lw	a0,-92(s0)
     7ae:	00000097          	auipc	ra,0x0
     7b2:	6a6080e7          	jalr	1702(ra) # e54 <close>
      char buf[4] = { 0, 0, 0, 0 };
     7b6:	f8042823          	sw	zero,-112(s0)
      read(bb[0], buf+0, 1);
     7ba:	4605                	li	a2,1
     7bc:	f9040593          	addi	a1,s0,-112
     7c0:	fa042503          	lw	a0,-96(s0)
     7c4:	00000097          	auipc	ra,0x0
     7c8:	680080e7          	jalr	1664(ra) # e44 <read>
      read(bb[0], buf+1, 1);
     7cc:	4605                	li	a2,1
     7ce:	f9140593          	addi	a1,s0,-111
     7d2:	fa042503          	lw	a0,-96(s0)
     7d6:	00000097          	auipc	ra,0x0
     7da:	66e080e7          	jalr	1646(ra) # e44 <read>
      read(bb[0], buf+2, 1);
     7de:	4605                	li	a2,1
     7e0:	f9240593          	addi	a1,s0,-110
     7e4:	fa042503          	lw	a0,-96(s0)
     7e8:	00000097          	auipc	ra,0x0
     7ec:	65c080e7          	jalr	1628(ra) # e44 <read>
      close(bb[0]);
     7f0:	fa042503          	lw	a0,-96(s0)
     7f4:	00000097          	auipc	ra,0x0
     7f8:	660080e7          	jalr	1632(ra) # e54 <close>
      int st1, st2;
      wait(&st1);
     7fc:	f9440513          	addi	a0,s0,-108
     800:	00000097          	auipc	ra,0x0
     804:	634080e7          	jalr	1588(ra) # e34 <wait>
      wait(&st2);
     808:	fa840513          	addi	a0,s0,-88
     80c:	00000097          	auipc	ra,0x0
     810:	628080e7          	jalr	1576(ra) # e34 <wait>
      if(st1 != 0 || st2 != 0 || strcmp(buf, "hi\n") != 0){
     814:	f9442783          	lw	a5,-108(s0)
     818:	fa842703          	lw	a4,-88(s0)
     81c:	8fd9                	or	a5,a5,a4
     81e:	ef89                	bnez	a5,838 <go+0x7c0>
     820:	00001597          	auipc	a1,0x1
     824:	e0858593          	addi	a1,a1,-504 # 1628 <malloc+0x3a2>
     828:	f9040513          	addi	a0,s0,-112
     82c:	00000097          	auipc	ra,0x0
     830:	3b0080e7          	jalr	944(ra) # bdc <strcmp>
     834:	8e0507e3          	beqz	a0,122 <go+0xaa>
        printf("grind: exec pipeline failed %d %d \"%s\"\n", st1, st2, buf);
     838:	f9040693          	addi	a3,s0,-112
     83c:	fa842603          	lw	a2,-88(s0)
     840:	f9442583          	lw	a1,-108(s0)
     844:	00001517          	auipc	a0,0x1
     848:	dec50513          	addi	a0,a0,-532 # 1630 <malloc+0x3aa>
     84c:	00001097          	auipc	ra,0x1
     850:	982080e7          	jalr	-1662(ra) # 11ce <printf>
        exit(1);
     854:	4505                	li	a0,1
     856:	00000097          	auipc	ra,0x0
     85a:	5d6080e7          	jalr	1494(ra) # e2c <exit>
        fprintf(2, "grind: pipe failed\n");
     85e:	00001597          	auipc	a1,0x1
     862:	c5258593          	addi	a1,a1,-942 # 14b0 <malloc+0x22a>
     866:	4509                	li	a0,2
     868:	00001097          	auipc	ra,0x1
     86c:	938080e7          	jalr	-1736(ra) # 11a0 <fprintf>
        exit(1);
     870:	4505                	li	a0,1
     872:	00000097          	auipc	ra,0x0
     876:	5ba080e7          	jalr	1466(ra) # e2c <exit>
        fprintf(2, "grind: pipe failed\n");
     87a:	00001597          	auipc	a1,0x1
     87e:	c3658593          	addi	a1,a1,-970 # 14b0 <malloc+0x22a>
     882:	4509                	li	a0,2
     884:	00001097          	auipc	ra,0x1
     888:	91c080e7          	jalr	-1764(ra) # 11a0 <fprintf>
        exit(1);
     88c:	4505                	li	a0,1
     88e:	00000097          	auipc	ra,0x0
     892:	59e080e7          	jalr	1438(ra) # e2c <exit>
        close(bb[0]);
     896:	fa042503          	lw	a0,-96(s0)
     89a:	00000097          	auipc	ra,0x0
     89e:	5ba080e7          	jalr	1466(ra) # e54 <close>
        close(bb[1]);
     8a2:	fa442503          	lw	a0,-92(s0)
     8a6:	00000097          	auipc	ra,0x0
     8aa:	5ae080e7          	jalr	1454(ra) # e54 <close>
        close(aa[0]);
     8ae:	f9842503          	lw	a0,-104(s0)
     8b2:	00000097          	auipc	ra,0x0
     8b6:	5a2080e7          	jalr	1442(ra) # e54 <close>
        close(1);
     8ba:	4505                	li	a0,1
     8bc:	00000097          	auipc	ra,0x0
     8c0:	598080e7          	jalr	1432(ra) # e54 <close>
        if(dup(aa[1]) != 1){
     8c4:	f9c42503          	lw	a0,-100(s0)
     8c8:	00000097          	auipc	ra,0x0
     8cc:	5dc080e7          	jalr	1500(ra) # ea4 <dup>
     8d0:	4785                	li	a5,1
     8d2:	02f50063          	beq	a0,a5,8f2 <go+0x87a>
          fprintf(2, "grind: dup failed\n");
     8d6:	00001597          	auipc	a1,0x1
     8da:	cda58593          	addi	a1,a1,-806 # 15b0 <malloc+0x32a>
     8de:	4509                	li	a0,2
     8e0:	00001097          	auipc	ra,0x1
     8e4:	8c0080e7          	jalr	-1856(ra) # 11a0 <fprintf>
          exit(1);
     8e8:	4505                	li	a0,1
     8ea:	00000097          	auipc	ra,0x0
     8ee:	542080e7          	jalr	1346(ra) # e2c <exit>
        close(aa[1]);
     8f2:	f9c42503          	lw	a0,-100(s0)
     8f6:	00000097          	auipc	ra,0x0
     8fa:	55e080e7          	jalr	1374(ra) # e54 <close>
        char *args[3] = { "echo", "hi", 0 };
     8fe:	00001797          	auipc	a5,0x1
     902:	cca78793          	addi	a5,a5,-822 # 15c8 <malloc+0x342>
     906:	faf43423          	sd	a5,-88(s0)
     90a:	00001797          	auipc	a5,0x1
     90e:	cc678793          	addi	a5,a5,-826 # 15d0 <malloc+0x34a>
     912:	faf43823          	sd	a5,-80(s0)
     916:	fa043c23          	sd	zero,-72(s0)
        exec("grindir/../echo", args);
     91a:	fa840593          	addi	a1,s0,-88
     91e:	00001517          	auipc	a0,0x1
     922:	cba50513          	addi	a0,a0,-838 # 15d8 <malloc+0x352>
     926:	00000097          	auipc	ra,0x0
     92a:	53e080e7          	jalr	1342(ra) # e64 <exec>
        fprintf(2, "grind: echo: not found\n");
     92e:	00001597          	auipc	a1,0x1
     932:	cba58593          	addi	a1,a1,-838 # 15e8 <malloc+0x362>
     936:	4509                	li	a0,2
     938:	00001097          	auipc	ra,0x1
     93c:	868080e7          	jalr	-1944(ra) # 11a0 <fprintf>
        exit(2);
     940:	4509                	li	a0,2
     942:	00000097          	auipc	ra,0x0
     946:	4ea080e7          	jalr	1258(ra) # e2c <exit>
        fprintf(2, "grind: fork failed\n");
     94a:	00001597          	auipc	a1,0x1
     94e:	b2658593          	addi	a1,a1,-1242 # 1470 <malloc+0x1ea>
     952:	4509                	li	a0,2
     954:	00001097          	auipc	ra,0x1
     958:	84c080e7          	jalr	-1972(ra) # 11a0 <fprintf>
        exit(3);
     95c:	450d                	li	a0,3
     95e:	00000097          	auipc	ra,0x0
     962:	4ce080e7          	jalr	1230(ra) # e2c <exit>
        close(aa[1]);
     966:	f9c42503          	lw	a0,-100(s0)
     96a:	00000097          	auipc	ra,0x0
     96e:	4ea080e7          	jalr	1258(ra) # e54 <close>
        close(bb[0]);
     972:	fa042503          	lw	a0,-96(s0)
     976:	00000097          	auipc	ra,0x0
     97a:	4de080e7          	jalr	1246(ra) # e54 <close>
        close(0);
     97e:	4501                	li	a0,0
     980:	00000097          	auipc	ra,0x0
     984:	4d4080e7          	jalr	1236(ra) # e54 <close>
        if(dup(aa[0]) != 0){
     988:	f9842503          	lw	a0,-104(s0)
     98c:	00000097          	auipc	ra,0x0
     990:	518080e7          	jalr	1304(ra) # ea4 <dup>
     994:	cd19                	beqz	a0,9b2 <go+0x93a>
          fprintf(2, "grind: dup failed\n");
     996:	00001597          	auipc	a1,0x1
     99a:	c1a58593          	addi	a1,a1,-998 # 15b0 <malloc+0x32a>
     99e:	4509                	li	a0,2
     9a0:	00001097          	auipc	ra,0x1
     9a4:	800080e7          	jalr	-2048(ra) # 11a0 <fprintf>
          exit(4);
     9a8:	4511                	li	a0,4
     9aa:	00000097          	auipc	ra,0x0
     9ae:	482080e7          	jalr	1154(ra) # e2c <exit>
        close(aa[0]);
     9b2:	f9842503          	lw	a0,-104(s0)
     9b6:	00000097          	auipc	ra,0x0
     9ba:	49e080e7          	jalr	1182(ra) # e54 <close>
        close(1);
     9be:	4505                	li	a0,1
     9c0:	00000097          	auipc	ra,0x0
     9c4:	494080e7          	jalr	1172(ra) # e54 <close>
        if(dup(bb[1]) != 1){
     9c8:	fa442503          	lw	a0,-92(s0)
     9cc:	00000097          	auipc	ra,0x0
     9d0:	4d8080e7          	jalr	1240(ra) # ea4 <dup>
     9d4:	4785                	li	a5,1
     9d6:	02f50063          	beq	a0,a5,9f6 <go+0x97e>
          fprintf(2, "grind: dup failed\n");
     9da:	00001597          	auipc	a1,0x1
     9de:	bd658593          	addi	a1,a1,-1066 # 15b0 <malloc+0x32a>
     9e2:	4509                	li	a0,2
     9e4:	00000097          	auipc	ra,0x0
     9e8:	7bc080e7          	jalr	1980(ra) # 11a0 <fprintf>
          exit(5);
     9ec:	4515                	li	a0,5
     9ee:	00000097          	auipc	ra,0x0
     9f2:	43e080e7          	jalr	1086(ra) # e2c <exit>
        close(bb[1]);
     9f6:	fa442503          	lw	a0,-92(s0)
     9fa:	00000097          	auipc	ra,0x0
     9fe:	45a080e7          	jalr	1114(ra) # e54 <close>
        char *args[2] = { "cat", 0 };
     a02:	00001797          	auipc	a5,0x1
     a06:	bfe78793          	addi	a5,a5,-1026 # 1600 <malloc+0x37a>
     a0a:	faf43423          	sd	a5,-88(s0)
     a0e:	fa043823          	sd	zero,-80(s0)
        exec("/cat", args);
     a12:	fa840593          	addi	a1,s0,-88
     a16:	00001517          	auipc	a0,0x1
     a1a:	bf250513          	addi	a0,a0,-1038 # 1608 <malloc+0x382>
     a1e:	00000097          	auipc	ra,0x0
     a22:	446080e7          	jalr	1094(ra) # e64 <exec>
        fprintf(2, "grind: cat: not found\n");
     a26:	00001597          	auipc	a1,0x1
     a2a:	bea58593          	addi	a1,a1,-1046 # 1610 <malloc+0x38a>
     a2e:	4509                	li	a0,2
     a30:	00000097          	auipc	ra,0x0
     a34:	770080e7          	jalr	1904(ra) # 11a0 <fprintf>
        exit(6);
     a38:	4519                	li	a0,6
     a3a:	00000097          	auipc	ra,0x0
     a3e:	3f2080e7          	jalr	1010(ra) # e2c <exit>
        fprintf(2, "grind: fork failed\n");
     a42:	00001597          	auipc	a1,0x1
     a46:	a2e58593          	addi	a1,a1,-1490 # 1470 <malloc+0x1ea>
     a4a:	4509                	li	a0,2
     a4c:	00000097          	auipc	ra,0x0
     a50:	754080e7          	jalr	1876(ra) # 11a0 <fprintf>
        exit(7);
     a54:	451d                	li	a0,7
     a56:	00000097          	auipc	ra,0x0
     a5a:	3d6080e7          	jalr	982(ra) # e2c <exit>

0000000000000a5e <iter>:
  }
}

void
iter()
{
     a5e:	7179                	addi	sp,sp,-48
     a60:	f406                	sd	ra,40(sp)
     a62:	f022                	sd	s0,32(sp)
     a64:	ec26                	sd	s1,24(sp)
     a66:	e84a                	sd	s2,16(sp)
     a68:	1800                	addi	s0,sp,48
  unlink("a");
     a6a:	00001517          	auipc	a0,0x1
     a6e:	9e650513          	addi	a0,a0,-1562 # 1450 <malloc+0x1ca>
     a72:	00000097          	auipc	ra,0x0
     a76:	40a080e7          	jalr	1034(ra) # e7c <unlink>
  unlink("b");
     a7a:	00001517          	auipc	a0,0x1
     a7e:	98650513          	addi	a0,a0,-1658 # 1400 <malloc+0x17a>
     a82:	00000097          	auipc	ra,0x0
     a86:	3fa080e7          	jalr	1018(ra) # e7c <unlink>
  
  int pid1 = fork();
     a8a:	00000097          	auipc	ra,0x0
     a8e:	39a080e7          	jalr	922(ra) # e24 <fork>
  if(pid1 < 0){
     a92:	02054163          	bltz	a0,ab4 <iter+0x56>
     a96:	84aa                	mv	s1,a0
    printf("grind: fork failed\n");
    exit(1);
  }
  if(pid1 == 0){
     a98:	e91d                	bnez	a0,ace <iter+0x70>
    rand_next ^= 31;
     a9a:	00001717          	auipc	a4,0x1
     a9e:	56670713          	addi	a4,a4,1382 # 2000 <rand_next>
     aa2:	631c                	ld	a5,0(a4)
     aa4:	01f7c793          	xori	a5,a5,31
     aa8:	e31c                	sd	a5,0(a4)
    go(0);
     aaa:	4501                	li	a0,0
     aac:	fffff097          	auipc	ra,0xfffff
     ab0:	5cc080e7          	jalr	1484(ra) # 78 <go>
    printf("grind: fork failed\n");
     ab4:	00001517          	auipc	a0,0x1
     ab8:	9bc50513          	addi	a0,a0,-1604 # 1470 <malloc+0x1ea>
     abc:	00000097          	auipc	ra,0x0
     ac0:	712080e7          	jalr	1810(ra) # 11ce <printf>
    exit(1);
     ac4:	4505                	li	a0,1
     ac6:	00000097          	auipc	ra,0x0
     aca:	366080e7          	jalr	870(ra) # e2c <exit>
    exit(0);
  }

  int pid2 = fork();
     ace:	00000097          	auipc	ra,0x0
     ad2:	356080e7          	jalr	854(ra) # e24 <fork>
     ad6:	892a                	mv	s2,a0
  if(pid2 < 0){
     ad8:	02054263          	bltz	a0,afc <iter+0x9e>
    printf("grind: fork failed\n");
    exit(1);
  }
  if(pid2 == 0){
     adc:	ed0d                	bnez	a0,b16 <iter+0xb8>
    rand_next ^= 7177;
     ade:	00001697          	auipc	a3,0x1
     ae2:	52268693          	addi	a3,a3,1314 # 2000 <rand_next>
     ae6:	629c                	ld	a5,0(a3)
     ae8:	6709                	lui	a4,0x2
     aea:	c0970713          	addi	a4,a4,-1015 # 1c09 <digits+0x4f1>
     aee:	8fb9                	xor	a5,a5,a4
     af0:	e29c                	sd	a5,0(a3)
    go(1);
     af2:	4505                	li	a0,1
     af4:	fffff097          	auipc	ra,0xfffff
     af8:	584080e7          	jalr	1412(ra) # 78 <go>
    printf("grind: fork failed\n");
     afc:	00001517          	auipc	a0,0x1
     b00:	97450513          	addi	a0,a0,-1676 # 1470 <malloc+0x1ea>
     b04:	00000097          	auipc	ra,0x0
     b08:	6ca080e7          	jalr	1738(ra) # 11ce <printf>
    exit(1);
     b0c:	4505                	li	a0,1
     b0e:	00000097          	auipc	ra,0x0
     b12:	31e080e7          	jalr	798(ra) # e2c <exit>
    exit(0);
  }

  int st1 = -1;
     b16:	57fd                	li	a5,-1
     b18:	fcf42e23          	sw	a5,-36(s0)
  wait(&st1);
     b1c:	fdc40513          	addi	a0,s0,-36
     b20:	00000097          	auipc	ra,0x0
     b24:	314080e7          	jalr	788(ra) # e34 <wait>
  if(st1 != 0){
     b28:	fdc42783          	lw	a5,-36(s0)
     b2c:	ef99                	bnez	a5,b4a <iter+0xec>
    kill(pid1);
    kill(pid2);
  }
  int st2 = -1;
     b2e:	57fd                	li	a5,-1
     b30:	fcf42c23          	sw	a5,-40(s0)
  wait(&st2);
     b34:	fd840513          	addi	a0,s0,-40
     b38:	00000097          	auipc	ra,0x0
     b3c:	2fc080e7          	jalr	764(ra) # e34 <wait>

  exit(0);
     b40:	4501                	li	a0,0
     b42:	00000097          	auipc	ra,0x0
     b46:	2ea080e7          	jalr	746(ra) # e2c <exit>
    kill(pid1);
     b4a:	8526                	mv	a0,s1
     b4c:	00000097          	auipc	ra,0x0
     b50:	310080e7          	jalr	784(ra) # e5c <kill>
    kill(pid2);
     b54:	854a                	mv	a0,s2
     b56:	00000097          	auipc	ra,0x0
     b5a:	306080e7          	jalr	774(ra) # e5c <kill>
     b5e:	bfc1                	j	b2e <iter+0xd0>

0000000000000b60 <main>:
}

int
main()
{
     b60:	1101                	addi	sp,sp,-32
     b62:	ec06                	sd	ra,24(sp)
     b64:	e822                	sd	s0,16(sp)
     b66:	e426                	sd	s1,8(sp)
     b68:	1000                	addi	s0,sp,32
    }
    if(pid > 0){
      wait(0);
    }
    sleep(20);
    rand_next += 1;
     b6a:	00001497          	auipc	s1,0x1
     b6e:	49648493          	addi	s1,s1,1174 # 2000 <rand_next>
     b72:	a829                	j	b8c <main+0x2c>
      iter();
     b74:	00000097          	auipc	ra,0x0
     b78:	eea080e7          	jalr	-278(ra) # a5e <iter>
    sleep(20);
     b7c:	4551                	li	a0,20
     b7e:	00000097          	auipc	ra,0x0
     b82:	33e080e7          	jalr	830(ra) # ebc <sleep>
    rand_next += 1;
     b86:	609c                	ld	a5,0(s1)
     b88:	0785                	addi	a5,a5,1
     b8a:	e09c                	sd	a5,0(s1)
    int pid = fork();
     b8c:	00000097          	auipc	ra,0x0
     b90:	298080e7          	jalr	664(ra) # e24 <fork>
    if(pid == 0){
     b94:	d165                	beqz	a0,b74 <main+0x14>
    if(pid > 0){
     b96:	fea053e3          	blez	a0,b7c <main+0x1c>
      wait(0);
     b9a:	4501                	li	a0,0
     b9c:	00000097          	auipc	ra,0x0
     ba0:	298080e7          	jalr	664(ra) # e34 <wait>
     ba4:	bfe1                	j	b7c <main+0x1c>

0000000000000ba6 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
     ba6:	1141                	addi	sp,sp,-16
     ba8:	e406                	sd	ra,8(sp)
     baa:	e022                	sd	s0,0(sp)
     bac:	0800                	addi	s0,sp,16
  extern int main();
  main();
     bae:	00000097          	auipc	ra,0x0
     bb2:	fb2080e7          	jalr	-78(ra) # b60 <main>
  exit(0);
     bb6:	4501                	li	a0,0
     bb8:	00000097          	auipc	ra,0x0
     bbc:	274080e7          	jalr	628(ra) # e2c <exit>

0000000000000bc0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
     bc0:	1141                	addi	sp,sp,-16
     bc2:	e422                	sd	s0,8(sp)
     bc4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     bc6:	87aa                	mv	a5,a0
     bc8:	0585                	addi	a1,a1,1
     bca:	0785                	addi	a5,a5,1
     bcc:	fff5c703          	lbu	a4,-1(a1)
     bd0:	fee78fa3          	sb	a4,-1(a5)
     bd4:	fb75                	bnez	a4,bc8 <strcpy+0x8>
    ;
  return os;
}
     bd6:	6422                	ld	s0,8(sp)
     bd8:	0141                	addi	sp,sp,16
     bda:	8082                	ret

0000000000000bdc <strcmp>:

int
strcmp(const char *p, const char *q)
{
     bdc:	1141                	addi	sp,sp,-16
     bde:	e422                	sd	s0,8(sp)
     be0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     be2:	00054783          	lbu	a5,0(a0)
     be6:	cb91                	beqz	a5,bfa <strcmp+0x1e>
     be8:	0005c703          	lbu	a4,0(a1)
     bec:	00f71763          	bne	a4,a5,bfa <strcmp+0x1e>
    p++, q++;
     bf0:	0505                	addi	a0,a0,1
     bf2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     bf4:	00054783          	lbu	a5,0(a0)
     bf8:	fbe5                	bnez	a5,be8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     bfa:	0005c503          	lbu	a0,0(a1)
}
     bfe:	40a7853b          	subw	a0,a5,a0
     c02:	6422                	ld	s0,8(sp)
     c04:	0141                	addi	sp,sp,16
     c06:	8082                	ret

0000000000000c08 <strlen>:

uint
strlen(const char *s)
{
     c08:	1141                	addi	sp,sp,-16
     c0a:	e422                	sd	s0,8(sp)
     c0c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c0e:	00054783          	lbu	a5,0(a0)
     c12:	cf91                	beqz	a5,c2e <strlen+0x26>
     c14:	0505                	addi	a0,a0,1
     c16:	87aa                	mv	a5,a0
     c18:	4685                	li	a3,1
     c1a:	9e89                	subw	a3,a3,a0
     c1c:	00f6853b          	addw	a0,a3,a5
     c20:	0785                	addi	a5,a5,1
     c22:	fff7c703          	lbu	a4,-1(a5)
     c26:	fb7d                	bnez	a4,c1c <strlen+0x14>
    ;
  return n;
}
     c28:	6422                	ld	s0,8(sp)
     c2a:	0141                	addi	sp,sp,16
     c2c:	8082                	ret
  for(n = 0; s[n]; n++)
     c2e:	4501                	li	a0,0
     c30:	bfe5                	j	c28 <strlen+0x20>

0000000000000c32 <memset>:

void*
memset(void *dst, int c, uint n)
{
     c32:	1141                	addi	sp,sp,-16
     c34:	e422                	sd	s0,8(sp)
     c36:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     c38:	ca19                	beqz	a2,c4e <memset+0x1c>
     c3a:	87aa                	mv	a5,a0
     c3c:	1602                	slli	a2,a2,0x20
     c3e:	9201                	srli	a2,a2,0x20
     c40:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     c44:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     c48:	0785                	addi	a5,a5,1
     c4a:	fee79de3          	bne	a5,a4,c44 <memset+0x12>
  }
  return dst;
}
     c4e:	6422                	ld	s0,8(sp)
     c50:	0141                	addi	sp,sp,16
     c52:	8082                	ret

0000000000000c54 <strchr>:

char*
strchr(const char *s, char c)
{
     c54:	1141                	addi	sp,sp,-16
     c56:	e422                	sd	s0,8(sp)
     c58:	0800                	addi	s0,sp,16
  for(; *s; s++)
     c5a:	00054783          	lbu	a5,0(a0)
     c5e:	cb99                	beqz	a5,c74 <strchr+0x20>
    if(*s == c)
     c60:	00f58763          	beq	a1,a5,c6e <strchr+0x1a>
  for(; *s; s++)
     c64:	0505                	addi	a0,a0,1
     c66:	00054783          	lbu	a5,0(a0)
     c6a:	fbfd                	bnez	a5,c60 <strchr+0xc>
      return (char*)s;
  return 0;
     c6c:	4501                	li	a0,0
}
     c6e:	6422                	ld	s0,8(sp)
     c70:	0141                	addi	sp,sp,16
     c72:	8082                	ret
  return 0;
     c74:	4501                	li	a0,0
     c76:	bfe5                	j	c6e <strchr+0x1a>

0000000000000c78 <gets>:

char*
gets(char *buf, int max)
{
     c78:	711d                	addi	sp,sp,-96
     c7a:	ec86                	sd	ra,88(sp)
     c7c:	e8a2                	sd	s0,80(sp)
     c7e:	e4a6                	sd	s1,72(sp)
     c80:	e0ca                	sd	s2,64(sp)
     c82:	fc4e                	sd	s3,56(sp)
     c84:	f852                	sd	s4,48(sp)
     c86:	f456                	sd	s5,40(sp)
     c88:	f05a                	sd	s6,32(sp)
     c8a:	ec5e                	sd	s7,24(sp)
     c8c:	1080                	addi	s0,sp,96
     c8e:	8baa                	mv	s7,a0
     c90:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     c92:	892a                	mv	s2,a0
     c94:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     c96:	4aa9                	li	s5,10
     c98:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     c9a:	89a6                	mv	s3,s1
     c9c:	2485                	addiw	s1,s1,1
     c9e:	0344d863          	bge	s1,s4,cce <gets+0x56>
    cc = read(0, &c, 1);
     ca2:	4605                	li	a2,1
     ca4:	faf40593          	addi	a1,s0,-81
     ca8:	4501                	li	a0,0
     caa:	00000097          	auipc	ra,0x0
     cae:	19a080e7          	jalr	410(ra) # e44 <read>
    if(cc < 1)
     cb2:	00a05e63          	blez	a0,cce <gets+0x56>
    buf[i++] = c;
     cb6:	faf44783          	lbu	a5,-81(s0)
     cba:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     cbe:	01578763          	beq	a5,s5,ccc <gets+0x54>
     cc2:	0905                	addi	s2,s2,1
     cc4:	fd679be3          	bne	a5,s6,c9a <gets+0x22>
  for(i=0; i+1 < max; ){
     cc8:	89a6                	mv	s3,s1
     cca:	a011                	j	cce <gets+0x56>
     ccc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     cce:	99de                	add	s3,s3,s7
     cd0:	00098023          	sb	zero,0(s3)
  return buf;
}
     cd4:	855e                	mv	a0,s7
     cd6:	60e6                	ld	ra,88(sp)
     cd8:	6446                	ld	s0,80(sp)
     cda:	64a6                	ld	s1,72(sp)
     cdc:	6906                	ld	s2,64(sp)
     cde:	79e2                	ld	s3,56(sp)
     ce0:	7a42                	ld	s4,48(sp)
     ce2:	7aa2                	ld	s5,40(sp)
     ce4:	7b02                	ld	s6,32(sp)
     ce6:	6be2                	ld	s7,24(sp)
     ce8:	6125                	addi	sp,sp,96
     cea:	8082                	ret

0000000000000cec <stats>:

int
stats(const char *n, struct stats *st)
{
     cec:	1101                	addi	sp,sp,-32
     cee:	ec06                	sd	ra,24(sp)
     cf0:	e822                	sd	s0,16(sp)
     cf2:	e426                	sd	s1,8(sp)
     cf4:	e04a                	sd	s2,0(sp)
     cf6:	1000                	addi	s0,sp,32
     cf8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     cfa:	4581                	li	a1,0
     cfc:	00000097          	auipc	ra,0x0
     d00:	170080e7          	jalr	368(ra) # e6c <open>
  if(fd < 0)
     d04:	02054563          	bltz	a0,d2e <stats+0x42>
     d08:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d0a:	85ca                	mv	a1,s2
     d0c:	00000097          	auipc	ra,0x0
     d10:	178080e7          	jalr	376(ra) # e84 <fstat>
     d14:	892a                	mv	s2,a0
  close(fd);
     d16:	8526                	mv	a0,s1
     d18:	00000097          	auipc	ra,0x0
     d1c:	13c080e7          	jalr	316(ra) # e54 <close>
  return r;
}
     d20:	854a                	mv	a0,s2
     d22:	60e2                	ld	ra,24(sp)
     d24:	6442                	ld	s0,16(sp)
     d26:	64a2                	ld	s1,8(sp)
     d28:	6902                	ld	s2,0(sp)
     d2a:	6105                	addi	sp,sp,32
     d2c:	8082                	ret
    return -1;
     d2e:	597d                	li	s2,-1
     d30:	bfc5                	j	d20 <stats+0x34>

0000000000000d32 <atoi>:

int
atoi(const char *s)
{
     d32:	1141                	addi	sp,sp,-16
     d34:	e422                	sd	s0,8(sp)
     d36:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     d38:	00054683          	lbu	a3,0(a0)
     d3c:	fd06879b          	addiw	a5,a3,-48
     d40:	0ff7f793          	zext.b	a5,a5
     d44:	4625                	li	a2,9
     d46:	02f66863          	bltu	a2,a5,d76 <atoi+0x44>
     d4a:	872a                	mv	a4,a0
  n = 0;
     d4c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
     d4e:	0705                	addi	a4,a4,1
     d50:	0025179b          	slliw	a5,a0,0x2
     d54:	9fa9                	addw	a5,a5,a0
     d56:	0017979b          	slliw	a5,a5,0x1
     d5a:	9fb5                	addw	a5,a5,a3
     d5c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     d60:	00074683          	lbu	a3,0(a4)
     d64:	fd06879b          	addiw	a5,a3,-48
     d68:	0ff7f793          	zext.b	a5,a5
     d6c:	fef671e3          	bgeu	a2,a5,d4e <atoi+0x1c>
  return n;
}
     d70:	6422                	ld	s0,8(sp)
     d72:	0141                	addi	sp,sp,16
     d74:	8082                	ret
  n = 0;
     d76:	4501                	li	a0,0
     d78:	bfe5                	j	d70 <atoi+0x3e>

0000000000000d7a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     d7a:	1141                	addi	sp,sp,-16
     d7c:	e422                	sd	s0,8(sp)
     d7e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     d80:	02b57463          	bgeu	a0,a1,da8 <memmove+0x2e>
    while(n-- > 0)
     d84:	00c05f63          	blez	a2,da2 <memmove+0x28>
     d88:	1602                	slli	a2,a2,0x20
     d8a:	9201                	srli	a2,a2,0x20
     d8c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     d90:	872a                	mv	a4,a0
      *dst++ = *src++;
     d92:	0585                	addi	a1,a1,1
     d94:	0705                	addi	a4,a4,1
     d96:	fff5c683          	lbu	a3,-1(a1)
     d9a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     d9e:	fee79ae3          	bne	a5,a4,d92 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     da2:	6422                	ld	s0,8(sp)
     da4:	0141                	addi	sp,sp,16
     da6:	8082                	ret
    dst += n;
     da8:	00c50733          	add	a4,a0,a2
    src += n;
     dac:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     dae:	fec05ae3          	blez	a2,da2 <memmove+0x28>
     db2:	fff6079b          	addiw	a5,a2,-1
     db6:	1782                	slli	a5,a5,0x20
     db8:	9381                	srli	a5,a5,0x20
     dba:	fff7c793          	not	a5,a5
     dbe:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     dc0:	15fd                	addi	a1,a1,-1
     dc2:	177d                	addi	a4,a4,-1
     dc4:	0005c683          	lbu	a3,0(a1)
     dc8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     dcc:	fee79ae3          	bne	a5,a4,dc0 <memmove+0x46>
     dd0:	bfc9                	j	da2 <memmove+0x28>

0000000000000dd2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     dd2:	1141                	addi	sp,sp,-16
     dd4:	e422                	sd	s0,8(sp)
     dd6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     dd8:	ca05                	beqz	a2,e08 <memcmp+0x36>
     dda:	fff6069b          	addiw	a3,a2,-1
     dde:	1682                	slli	a3,a3,0x20
     de0:	9281                	srli	a3,a3,0x20
     de2:	0685                	addi	a3,a3,1
     de4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     de6:	00054783          	lbu	a5,0(a0)
     dea:	0005c703          	lbu	a4,0(a1)
     dee:	00e79863          	bne	a5,a4,dfe <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     df2:	0505                	addi	a0,a0,1
    p2++;
     df4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     df6:	fed518e3          	bne	a0,a3,de6 <memcmp+0x14>
  }
  return 0;
     dfa:	4501                	li	a0,0
     dfc:	a019                	j	e02 <memcmp+0x30>
      return *p1 - *p2;
     dfe:	40e7853b          	subw	a0,a5,a4
}
     e02:	6422                	ld	s0,8(sp)
     e04:	0141                	addi	sp,sp,16
     e06:	8082                	ret
  return 0;
     e08:	4501                	li	a0,0
     e0a:	bfe5                	j	e02 <memcmp+0x30>

0000000000000e0c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e0c:	1141                	addi	sp,sp,-16
     e0e:	e406                	sd	ra,8(sp)
     e10:	e022                	sd	s0,0(sp)
     e12:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e14:	00000097          	auipc	ra,0x0
     e18:	f66080e7          	jalr	-154(ra) # d7a <memmove>
}
     e1c:	60a2                	ld	ra,8(sp)
     e1e:	6402                	ld	s0,0(sp)
     e20:	0141                	addi	sp,sp,16
     e22:	8082                	ret

0000000000000e24 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     e24:	4885                	li	a7,1
 ecall
     e26:	00000073          	ecall
 ret
     e2a:	8082                	ret

0000000000000e2c <exit>:
.global exit
exit:
 li a7, SYS_exit
     e2c:	4889                	li	a7,2
 ecall
     e2e:	00000073          	ecall
 ret
     e32:	8082                	ret

0000000000000e34 <wait>:
.global wait
wait:
 li a7, SYS_wait
     e34:	488d                	li	a7,3
 ecall
     e36:	00000073          	ecall
 ret
     e3a:	8082                	ret

0000000000000e3c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     e3c:	4891                	li	a7,4
 ecall
     e3e:	00000073          	ecall
 ret
     e42:	8082                	ret

0000000000000e44 <read>:
.global read
read:
 li a7, SYS_read
     e44:	4895                	li	a7,5
 ecall
     e46:	00000073          	ecall
 ret
     e4a:	8082                	ret

0000000000000e4c <write>:
.global write
write:
 li a7, SYS_write
     e4c:	48c1                	li	a7,16
 ecall
     e4e:	00000073          	ecall
 ret
     e52:	8082                	ret

0000000000000e54 <close>:
.global close
close:
 li a7, SYS_close
     e54:	48d5                	li	a7,21
 ecall
     e56:	00000073          	ecall
 ret
     e5a:	8082                	ret

0000000000000e5c <kill>:
.global kill
kill:
 li a7, SYS_kill
     e5c:	4899                	li	a7,6
 ecall
     e5e:	00000073          	ecall
 ret
     e62:	8082                	ret

0000000000000e64 <exec>:
.global exec
exec:
 li a7, SYS_exec
     e64:	489d                	li	a7,7
 ecall
     e66:	00000073          	ecall
 ret
     e6a:	8082                	ret

0000000000000e6c <open>:
.global open
open:
 li a7, SYS_open
     e6c:	48bd                	li	a7,15
 ecall
     e6e:	00000073          	ecall
 ret
     e72:	8082                	ret

0000000000000e74 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     e74:	48c5                	li	a7,17
 ecall
     e76:	00000073          	ecall
 ret
     e7a:	8082                	ret

0000000000000e7c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     e7c:	48c9                	li	a7,18
 ecall
     e7e:	00000073          	ecall
 ret
     e82:	8082                	ret

0000000000000e84 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     e84:	48a1                	li	a7,8
 ecall
     e86:	00000073          	ecall
 ret
     e8a:	8082                	ret

0000000000000e8c <link>:
.global link
link:
 li a7, SYS_link
     e8c:	48cd                	li	a7,19
 ecall
     e8e:	00000073          	ecall
 ret
     e92:	8082                	ret

0000000000000e94 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     e94:	48d1                	li	a7,20
 ecall
     e96:	00000073          	ecall
 ret
     e9a:	8082                	ret

0000000000000e9c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     e9c:	48a5                	li	a7,9
 ecall
     e9e:	00000073          	ecall
 ret
     ea2:	8082                	ret

0000000000000ea4 <dup>:
.global dup
dup:
 li a7, SYS_dup
     ea4:	48a9                	li	a7,10
 ecall
     ea6:	00000073          	ecall
 ret
     eaa:	8082                	ret

0000000000000eac <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     eac:	48ad                	li	a7,11
 ecall
     eae:	00000073          	ecall
 ret
     eb2:	8082                	ret

0000000000000eb4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     eb4:	48b1                	li	a7,12
 ecall
     eb6:	00000073          	ecall
 ret
     eba:	8082                	ret

0000000000000ebc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     ebc:	48b5                	li	a7,13
 ecall
     ebe:	00000073          	ecall
 ret
     ec2:	8082                	ret

0000000000000ec4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     ec4:	48b9                	li	a7,14
 ecall
     ec6:	00000073          	ecall
 ret
     eca:	8082                	ret

0000000000000ecc <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
     ecc:	48d9                	li	a7,22
 ecall
     ece:	00000073          	ecall
 ret
     ed2:	8082                	ret

0000000000000ed4 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
     ed4:	48dd                	li	a7,23
 ecall
     ed6:	00000073          	ecall
 ret
     eda:	8082                	ret

0000000000000edc <trace>:
.global trace
trace:
 li a7, SYS_trace
     edc:	48e1                	li	a7,24
 ecall
     ede:	00000073          	ecall
 ret
     ee2:	8082                	ret

0000000000000ee4 <cps>:
.global cps
cps:
 li a7, SYS_cps
     ee4:	48e5                	li	a7,25
 ecall
     ee6:	00000073          	ecall
 ret
     eea:	8082                	ret

0000000000000eec <chpr>:
.global chpr
chpr:
 li a7, SYS_chpr
     eec:	48e9                	li	a7,26
 ecall
     eee:	00000073          	ecall
 ret
     ef2:	8082                	ret

0000000000000ef4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     ef4:	1101                	addi	sp,sp,-32
     ef6:	ec06                	sd	ra,24(sp)
     ef8:	e822                	sd	s0,16(sp)
     efa:	1000                	addi	s0,sp,32
     efc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     f00:	4605                	li	a2,1
     f02:	fef40593          	addi	a1,s0,-17
     f06:	00000097          	auipc	ra,0x0
     f0a:	f46080e7          	jalr	-186(ra) # e4c <write>
}
     f0e:	60e2                	ld	ra,24(sp)
     f10:	6442                	ld	s0,16(sp)
     f12:	6105                	addi	sp,sp,32
     f14:	8082                	ret

0000000000000f16 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f16:	7139                	addi	sp,sp,-64
     f18:	fc06                	sd	ra,56(sp)
     f1a:	f822                	sd	s0,48(sp)
     f1c:	f426                	sd	s1,40(sp)
     f1e:	f04a                	sd	s2,32(sp)
     f20:	ec4e                	sd	s3,24(sp)
     f22:	0080                	addi	s0,sp,64
     f24:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f26:	c299                	beqz	a3,f2c <printint+0x16>
     f28:	0805c963          	bltz	a1,fba <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f2c:	2581                	sext.w	a1,a1
  neg = 0;
     f2e:	4881                	li	a7,0
     f30:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f34:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f36:	2601                	sext.w	a2,a2
     f38:	00000517          	auipc	a0,0x0
     f3c:	7e050513          	addi	a0,a0,2016 # 1718 <digits>
     f40:	883a                	mv	a6,a4
     f42:	2705                	addiw	a4,a4,1
     f44:	02c5f7bb          	remuw	a5,a1,a2
     f48:	1782                	slli	a5,a5,0x20
     f4a:	9381                	srli	a5,a5,0x20
     f4c:	97aa                	add	a5,a5,a0
     f4e:	0007c783          	lbu	a5,0(a5)
     f52:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     f56:	0005879b          	sext.w	a5,a1
     f5a:	02c5d5bb          	divuw	a1,a1,a2
     f5e:	0685                	addi	a3,a3,1
     f60:	fec7f0e3          	bgeu	a5,a2,f40 <printint+0x2a>
  if(neg)
     f64:	00088c63          	beqz	a7,f7c <printint+0x66>
    buf[i++] = '-';
     f68:	fd070793          	addi	a5,a4,-48
     f6c:	00878733          	add	a4,a5,s0
     f70:	02d00793          	li	a5,45
     f74:	fef70823          	sb	a5,-16(a4)
     f78:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     f7c:	02e05863          	blez	a4,fac <printint+0x96>
     f80:	fc040793          	addi	a5,s0,-64
     f84:	00e78933          	add	s2,a5,a4
     f88:	fff78993          	addi	s3,a5,-1
     f8c:	99ba                	add	s3,s3,a4
     f8e:	377d                	addiw	a4,a4,-1
     f90:	1702                	slli	a4,a4,0x20
     f92:	9301                	srli	a4,a4,0x20
     f94:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     f98:	fff94583          	lbu	a1,-1(s2)
     f9c:	8526                	mv	a0,s1
     f9e:	00000097          	auipc	ra,0x0
     fa2:	f56080e7          	jalr	-170(ra) # ef4 <putc>
  while(--i >= 0)
     fa6:	197d                	addi	s2,s2,-1
     fa8:	ff3918e3          	bne	s2,s3,f98 <printint+0x82>
}
     fac:	70e2                	ld	ra,56(sp)
     fae:	7442                	ld	s0,48(sp)
     fb0:	74a2                	ld	s1,40(sp)
     fb2:	7902                	ld	s2,32(sp)
     fb4:	69e2                	ld	s3,24(sp)
     fb6:	6121                	addi	sp,sp,64
     fb8:	8082                	ret
    x = -xx;
     fba:	40b005bb          	negw	a1,a1
    neg = 1;
     fbe:	4885                	li	a7,1
    x = -xx;
     fc0:	bf85                	j	f30 <printint+0x1a>

0000000000000fc2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     fc2:	7119                	addi	sp,sp,-128
     fc4:	fc86                	sd	ra,120(sp)
     fc6:	f8a2                	sd	s0,112(sp)
     fc8:	f4a6                	sd	s1,104(sp)
     fca:	f0ca                	sd	s2,96(sp)
     fcc:	ecce                	sd	s3,88(sp)
     fce:	e8d2                	sd	s4,80(sp)
     fd0:	e4d6                	sd	s5,72(sp)
     fd2:	e0da                	sd	s6,64(sp)
     fd4:	fc5e                	sd	s7,56(sp)
     fd6:	f862                	sd	s8,48(sp)
     fd8:	f466                	sd	s9,40(sp)
     fda:	f06a                	sd	s10,32(sp)
     fdc:	ec6e                	sd	s11,24(sp)
     fde:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
     fe0:	0005c903          	lbu	s2,0(a1)
     fe4:	18090f63          	beqz	s2,1182 <vprintf+0x1c0>
     fe8:	8aaa                	mv	s5,a0
     fea:	8b32                	mv	s6,a2
     fec:	00158493          	addi	s1,a1,1
  state = 0;
     ff0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
     ff2:	02500a13          	li	s4,37
     ff6:	4c55                	li	s8,21
     ff8:	00000c97          	auipc	s9,0x0
     ffc:	6c8c8c93          	addi	s9,s9,1736 # 16c0 <malloc+0x43a>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
    1000:	02800d93          	li	s11,40
  putc(fd, 'x');
    1004:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    1006:	00000b97          	auipc	s7,0x0
    100a:	712b8b93          	addi	s7,s7,1810 # 1718 <digits>
    100e:	a839                	j	102c <vprintf+0x6a>
        putc(fd, c);
    1010:	85ca                	mv	a1,s2
    1012:	8556                	mv	a0,s5
    1014:	00000097          	auipc	ra,0x0
    1018:	ee0080e7          	jalr	-288(ra) # ef4 <putc>
    101c:	a019                	j	1022 <vprintf+0x60>
    } else if(state == '%'){
    101e:	01498d63          	beq	s3,s4,1038 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
    1022:	0485                	addi	s1,s1,1
    1024:	fff4c903          	lbu	s2,-1(s1)
    1028:	14090d63          	beqz	s2,1182 <vprintf+0x1c0>
    if(state == 0){
    102c:	fe0999e3          	bnez	s3,101e <vprintf+0x5c>
      if(c == '%'){
    1030:	ff4910e3          	bne	s2,s4,1010 <vprintf+0x4e>
        state = '%';
    1034:	89d2                	mv	s3,s4
    1036:	b7f5                	j	1022 <vprintf+0x60>
      if(c == 'd'){
    1038:	11490c63          	beq	s2,s4,1150 <vprintf+0x18e>
    103c:	f9d9079b          	addiw	a5,s2,-99
    1040:	0ff7f793          	zext.b	a5,a5
    1044:	10fc6e63          	bltu	s8,a5,1160 <vprintf+0x19e>
    1048:	f9d9079b          	addiw	a5,s2,-99
    104c:	0ff7f713          	zext.b	a4,a5
    1050:	10ec6863          	bltu	s8,a4,1160 <vprintf+0x19e>
    1054:	00271793          	slli	a5,a4,0x2
    1058:	97e6                	add	a5,a5,s9
    105a:	439c                	lw	a5,0(a5)
    105c:	97e6                	add	a5,a5,s9
    105e:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
    1060:	008b0913          	addi	s2,s6,8
    1064:	4685                	li	a3,1
    1066:	4629                	li	a2,10
    1068:	000b2583          	lw	a1,0(s6)
    106c:	8556                	mv	a0,s5
    106e:	00000097          	auipc	ra,0x0
    1072:	ea8080e7          	jalr	-344(ra) # f16 <printint>
    1076:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
    1078:	4981                	li	s3,0
    107a:	b765                	j	1022 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    107c:	008b0913          	addi	s2,s6,8
    1080:	4681                	li	a3,0
    1082:	4629                	li	a2,10
    1084:	000b2583          	lw	a1,0(s6)
    1088:	8556                	mv	a0,s5
    108a:	00000097          	auipc	ra,0x0
    108e:	e8c080e7          	jalr	-372(ra) # f16 <printint>
    1092:	8b4a                	mv	s6,s2
      state = 0;
    1094:	4981                	li	s3,0
    1096:	b771                	j	1022 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    1098:	008b0913          	addi	s2,s6,8
    109c:	4681                	li	a3,0
    109e:	866a                	mv	a2,s10
    10a0:	000b2583          	lw	a1,0(s6)
    10a4:	8556                	mv	a0,s5
    10a6:	00000097          	auipc	ra,0x0
    10aa:	e70080e7          	jalr	-400(ra) # f16 <printint>
    10ae:	8b4a                	mv	s6,s2
      state = 0;
    10b0:	4981                	li	s3,0
    10b2:	bf85                	j	1022 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    10b4:	008b0793          	addi	a5,s6,8
    10b8:	f8f43423          	sd	a5,-120(s0)
    10bc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    10c0:	03000593          	li	a1,48
    10c4:	8556                	mv	a0,s5
    10c6:	00000097          	auipc	ra,0x0
    10ca:	e2e080e7          	jalr	-466(ra) # ef4 <putc>
  putc(fd, 'x');
    10ce:	07800593          	li	a1,120
    10d2:	8556                	mv	a0,s5
    10d4:	00000097          	auipc	ra,0x0
    10d8:	e20080e7          	jalr	-480(ra) # ef4 <putc>
    10dc:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    10de:	03c9d793          	srli	a5,s3,0x3c
    10e2:	97de                	add	a5,a5,s7
    10e4:	0007c583          	lbu	a1,0(a5)
    10e8:	8556                	mv	a0,s5
    10ea:	00000097          	auipc	ra,0x0
    10ee:	e0a080e7          	jalr	-502(ra) # ef4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    10f2:	0992                	slli	s3,s3,0x4
    10f4:	397d                	addiw	s2,s2,-1
    10f6:	fe0914e3          	bnez	s2,10de <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
    10fa:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    10fe:	4981                	li	s3,0
    1100:	b70d                	j	1022 <vprintf+0x60>
        s = va_arg(ap, char*);
    1102:	008b0913          	addi	s2,s6,8
    1106:	000b3983          	ld	s3,0(s6)
        if(s == 0)
    110a:	02098163          	beqz	s3,112c <vprintf+0x16a>
        while(*s != 0){
    110e:	0009c583          	lbu	a1,0(s3)
    1112:	c5ad                	beqz	a1,117c <vprintf+0x1ba>
          putc(fd, *s);
    1114:	8556                	mv	a0,s5
    1116:	00000097          	auipc	ra,0x0
    111a:	dde080e7          	jalr	-546(ra) # ef4 <putc>
          s++;
    111e:	0985                	addi	s3,s3,1
        while(*s != 0){
    1120:	0009c583          	lbu	a1,0(s3)
    1124:	f9e5                	bnez	a1,1114 <vprintf+0x152>
        s = va_arg(ap, char*);
    1126:	8b4a                	mv	s6,s2
      state = 0;
    1128:	4981                	li	s3,0
    112a:	bde5                	j	1022 <vprintf+0x60>
          s = "(null)";
    112c:	00000997          	auipc	s3,0x0
    1130:	58c98993          	addi	s3,s3,1420 # 16b8 <malloc+0x432>
        while(*s != 0){
    1134:	85ee                	mv	a1,s11
    1136:	bff9                	j	1114 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
    1138:	008b0913          	addi	s2,s6,8
    113c:	000b4583          	lbu	a1,0(s6)
    1140:	8556                	mv	a0,s5
    1142:	00000097          	auipc	ra,0x0
    1146:	db2080e7          	jalr	-590(ra) # ef4 <putc>
    114a:	8b4a                	mv	s6,s2
      state = 0;
    114c:	4981                	li	s3,0
    114e:	bdd1                	j	1022 <vprintf+0x60>
        putc(fd, c);
    1150:	85d2                	mv	a1,s4
    1152:	8556                	mv	a0,s5
    1154:	00000097          	auipc	ra,0x0
    1158:	da0080e7          	jalr	-608(ra) # ef4 <putc>
      state = 0;
    115c:	4981                	li	s3,0
    115e:	b5d1                	j	1022 <vprintf+0x60>
        putc(fd, '%');
    1160:	85d2                	mv	a1,s4
    1162:	8556                	mv	a0,s5
    1164:	00000097          	auipc	ra,0x0
    1168:	d90080e7          	jalr	-624(ra) # ef4 <putc>
        putc(fd, c);
    116c:	85ca                	mv	a1,s2
    116e:	8556                	mv	a0,s5
    1170:	00000097          	auipc	ra,0x0
    1174:	d84080e7          	jalr	-636(ra) # ef4 <putc>
      state = 0;
    1178:	4981                	li	s3,0
    117a:	b565                	j	1022 <vprintf+0x60>
        s = va_arg(ap, char*);
    117c:	8b4a                	mv	s6,s2
      state = 0;
    117e:	4981                	li	s3,0
    1180:	b54d                	j	1022 <vprintf+0x60>
    }
  }
}
    1182:	70e6                	ld	ra,120(sp)
    1184:	7446                	ld	s0,112(sp)
    1186:	74a6                	ld	s1,104(sp)
    1188:	7906                	ld	s2,96(sp)
    118a:	69e6                	ld	s3,88(sp)
    118c:	6a46                	ld	s4,80(sp)
    118e:	6aa6                	ld	s5,72(sp)
    1190:	6b06                	ld	s6,64(sp)
    1192:	7be2                	ld	s7,56(sp)
    1194:	7c42                	ld	s8,48(sp)
    1196:	7ca2                	ld	s9,40(sp)
    1198:	7d02                	ld	s10,32(sp)
    119a:	6de2                	ld	s11,24(sp)
    119c:	6109                	addi	sp,sp,128
    119e:	8082                	ret

00000000000011a0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    11a0:	715d                	addi	sp,sp,-80
    11a2:	ec06                	sd	ra,24(sp)
    11a4:	e822                	sd	s0,16(sp)
    11a6:	1000                	addi	s0,sp,32
    11a8:	e010                	sd	a2,0(s0)
    11aa:	e414                	sd	a3,8(s0)
    11ac:	e818                	sd	a4,16(s0)
    11ae:	ec1c                	sd	a5,24(s0)
    11b0:	03043023          	sd	a6,32(s0)
    11b4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    11b8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    11bc:	8622                	mv	a2,s0
    11be:	00000097          	auipc	ra,0x0
    11c2:	e04080e7          	jalr	-508(ra) # fc2 <vprintf>
}
    11c6:	60e2                	ld	ra,24(sp)
    11c8:	6442                	ld	s0,16(sp)
    11ca:	6161                	addi	sp,sp,80
    11cc:	8082                	ret

00000000000011ce <printf>:

void
printf(const char *fmt, ...)
{
    11ce:	711d                	addi	sp,sp,-96
    11d0:	ec06                	sd	ra,24(sp)
    11d2:	e822                	sd	s0,16(sp)
    11d4:	1000                	addi	s0,sp,32
    11d6:	e40c                	sd	a1,8(s0)
    11d8:	e810                	sd	a2,16(s0)
    11da:	ec14                	sd	a3,24(s0)
    11dc:	f018                	sd	a4,32(s0)
    11de:	f41c                	sd	a5,40(s0)
    11e0:	03043823          	sd	a6,48(s0)
    11e4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    11e8:	00840613          	addi	a2,s0,8
    11ec:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    11f0:	85aa                	mv	a1,a0
    11f2:	4505                	li	a0,1
    11f4:	00000097          	auipc	ra,0x0
    11f8:	dce080e7          	jalr	-562(ra) # fc2 <vprintf>
}
    11fc:	60e2                	ld	ra,24(sp)
    11fe:	6442                	ld	s0,16(sp)
    1200:	6125                	addi	sp,sp,96
    1202:	8082                	ret

0000000000001204 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    1204:	1141                	addi	sp,sp,-16
    1206:	e422                	sd	s0,8(sp)
    1208:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    120a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    120e:	00001797          	auipc	a5,0x1
    1212:	e027b783          	ld	a5,-510(a5) # 2010 <freep>
    1216:	a02d                	j	1240 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    1218:	4618                	lw	a4,8(a2)
    121a:	9f2d                	addw	a4,a4,a1
    121c:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1220:	6398                	ld	a4,0(a5)
    1222:	6310                	ld	a2,0(a4)
    1224:	a83d                	j	1262 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1226:	ff852703          	lw	a4,-8(a0)
    122a:	9f31                	addw	a4,a4,a2
    122c:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
    122e:	ff053683          	ld	a3,-16(a0)
    1232:	a091                	j	1276 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1234:	6398                	ld	a4,0(a5)
    1236:	00e7e463          	bltu	a5,a4,123e <free+0x3a>
    123a:	00e6ea63          	bltu	a3,a4,124e <free+0x4a>
{
    123e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1240:	fed7fae3          	bgeu	a5,a3,1234 <free+0x30>
    1244:	6398                	ld	a4,0(a5)
    1246:	00e6e463          	bltu	a3,a4,124e <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    124a:	fee7eae3          	bltu	a5,a4,123e <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
    124e:	ff852583          	lw	a1,-8(a0)
    1252:	6390                	ld	a2,0(a5)
    1254:	02059813          	slli	a6,a1,0x20
    1258:	01c85713          	srli	a4,a6,0x1c
    125c:	9736                	add	a4,a4,a3
    125e:	fae60de3          	beq	a2,a4,1218 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
    1262:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    1266:	4790                	lw	a2,8(a5)
    1268:	02061593          	slli	a1,a2,0x20
    126c:	01c5d713          	srli	a4,a1,0x1c
    1270:	973e                	add	a4,a4,a5
    1272:	fae68ae3          	beq	a3,a4,1226 <free+0x22>
    p->s.ptr = bp->s.ptr;
    1276:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
    1278:	00001717          	auipc	a4,0x1
    127c:	d8f73c23          	sd	a5,-616(a4) # 2010 <freep>
}
    1280:	6422                	ld	s0,8(sp)
    1282:	0141                	addi	sp,sp,16
    1284:	8082                	ret

0000000000001286 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    1286:	7139                	addi	sp,sp,-64
    1288:	fc06                	sd	ra,56(sp)
    128a:	f822                	sd	s0,48(sp)
    128c:	f426                	sd	s1,40(sp)
    128e:	f04a                	sd	s2,32(sp)
    1290:	ec4e                	sd	s3,24(sp)
    1292:	e852                	sd	s4,16(sp)
    1294:	e456                	sd	s5,8(sp)
    1296:	e05a                	sd	s6,0(sp)
    1298:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    129a:	02051493          	slli	s1,a0,0x20
    129e:	9081                	srli	s1,s1,0x20
    12a0:	04bd                	addi	s1,s1,15
    12a2:	8091                	srli	s1,s1,0x4
    12a4:	0014899b          	addiw	s3,s1,1
    12a8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    12aa:	00001517          	auipc	a0,0x1
    12ae:	d6653503          	ld	a0,-666(a0) # 2010 <freep>
    12b2:	c515                	beqz	a0,12de <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    12b4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    12b6:	4798                	lw	a4,8(a5)
    12b8:	02977f63          	bgeu	a4,s1,12f6 <malloc+0x70>
    12bc:	8a4e                	mv	s4,s3
    12be:	0009871b          	sext.w	a4,s3
    12c2:	6685                	lui	a3,0x1
    12c4:	00d77363          	bgeu	a4,a3,12ca <malloc+0x44>
    12c8:	6a05                	lui	s4,0x1
    12ca:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    12ce:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    12d2:	00001917          	auipc	s2,0x1
    12d6:	d3e90913          	addi	s2,s2,-706 # 2010 <freep>
  if(p == (char*)-1)
    12da:	5afd                	li	s5,-1
    12dc:	a895                	j	1350 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    12de:	00001797          	auipc	a5,0x1
    12e2:	12a78793          	addi	a5,a5,298 # 2408 <base>
    12e6:	00001717          	auipc	a4,0x1
    12ea:	d2f73523          	sd	a5,-726(a4) # 2010 <freep>
    12ee:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    12f0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    12f4:	b7e1                	j	12bc <malloc+0x36>
      if(p->s.size == nunits)
    12f6:	02e48c63          	beq	s1,a4,132e <malloc+0xa8>
        p->s.size -= nunits;
    12fa:	4137073b          	subw	a4,a4,s3
    12fe:	c798                	sw	a4,8(a5)
        p += p->s.size;
    1300:	02071693          	slli	a3,a4,0x20
    1304:	01c6d713          	srli	a4,a3,0x1c
    1308:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    130a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    130e:	00001717          	auipc	a4,0x1
    1312:	d0a73123          	sd	a0,-766(a4) # 2010 <freep>
      return (void*)(p + 1);
    1316:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    131a:	70e2                	ld	ra,56(sp)
    131c:	7442                	ld	s0,48(sp)
    131e:	74a2                	ld	s1,40(sp)
    1320:	7902                	ld	s2,32(sp)
    1322:	69e2                	ld	s3,24(sp)
    1324:	6a42                	ld	s4,16(sp)
    1326:	6aa2                	ld	s5,8(sp)
    1328:	6b02                	ld	s6,0(sp)
    132a:	6121                	addi	sp,sp,64
    132c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    132e:	6398                	ld	a4,0(a5)
    1330:	e118                	sd	a4,0(a0)
    1332:	bff1                	j	130e <malloc+0x88>
  hp->s.size = nu;
    1334:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1338:	0541                	addi	a0,a0,16
    133a:	00000097          	auipc	ra,0x0
    133e:	eca080e7          	jalr	-310(ra) # 1204 <free>
  return freep;
    1342:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1346:	d971                	beqz	a0,131a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1348:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    134a:	4798                	lw	a4,8(a5)
    134c:	fa9775e3          	bgeu	a4,s1,12f6 <malloc+0x70>
    if(p == freep)
    1350:	00093703          	ld	a4,0(s2)
    1354:	853e                	mv	a0,a5
    1356:	fef719e3          	bne	a4,a5,1348 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    135a:	8552                	mv	a0,s4
    135c:	00000097          	auipc	ra,0x0
    1360:	b58080e7          	jalr	-1192(ra) # eb4 <sbrk>
  if(p == (char*)-1)
    1364:	fd5518e3          	bne	a0,s5,1334 <malloc+0xae>
        return 0;
    1368:	4501                	li	a0,0
    136a:	bf45                	j	131a <malloc+0x94>

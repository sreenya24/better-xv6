#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}


uint64 sigalarm(void)
{
    int ticks;
    uint64 adrs;

    if(argint(0, &ticks) < 0)
        return -1;
    else if(argaddr(1, &adrs) < 0)
        return -1;

    myproc()->alarmticks = ticks;
    myproc()->alarmhandler = adrs;

    return 0;
}

uint64 sigreturn(void)
{
    struct proc *p = myproc();
    memmove(p->trapframe, p->alarm_trap, sizeof(struct trapframe));
    kfree(p->alarm_trap);
    
    p->alarm_trap = 0; //Have to initialize
    p->alarm_on = 0; //Have to initialize
    p->curticks = 0; //Have to initialize

    return 0;
}

uint64
sys_trace(void)
{
  int mask;
  if(argint(0, &mask) < 0) return -1;
  struct proc* p = myproc();
  if(mask == 0)
  {
    for(int i = 0; i<30; i++)
      p->trac[i] = 1;
  }
  else
  {
    for(int i = 1; i<30; i++)
    {
      mask = mask>>1;
      if(mask%2 != 0)
        p->trac[i] = 1;
    }
  }
  return 0;
}

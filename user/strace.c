#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int main(int argc, char* argv[])
{
  int forkReturn = fork();
  // fork errored
  if(forkReturn < 0)
  {
    printf("Unsuccesful fork\n");
    exit(0);
  }
  // in child
  else if(forkReturn != 0)
  {
    trace(atoi(argv[1]));
    exec(argv[2], argv+2);
    printf("Execution of %s failed.\n", argv[1]);
    exit(0);
  }
	exit(0);
}
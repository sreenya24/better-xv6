OSN A4 Report

Strace Syscall - This is used to trace the execution of the process. It prints out all the syscalls used by said process. 
sigalarm and sigreturn - They notify the processes and return signal outputs when consuming CPU time

Scheduling Algorithms Implemented - 
FCFS
PBS

Working logic

FCFS Scheduling follows exactly what it says - First Come First Serve. We traverse the process list to find the one which appeared first, that is, had the least value of creation time. Upon finding that process, we lock it and switch context to start the execution. After execution is complete, we release the lock and move on to the other processes. But this can only work if the process in question is runnable, which is why we check for that condition before looking at its arrival time.


PBS Scheduling works on a priority-based system. Each process has 3 priority values associated with it - static priority, dynamic priority and niceness. The dynamic priority is calculated using static priority and niceness and is what determines which process is executed first. 
The process list is traversed to obtain the dynamic priority and niceness of every process. Then a process is locked and checked to see if it is runnable. If the locked process is not runnable, it is released and we move on to the next one. If the locked process is runnable, the priority is checked with the rest of the values and the process with the least priority is picked. Context switching is applied in the chosen process and it is executed.

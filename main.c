
#include "stm32g070xx.h"
#include "kernel.h"
#include "threads.h"



int main(void){
	
	//initialize kernel
	Kernel_Init();
	
	//create threads with priority
	//arg1->thread function pointer
	//arg2->thread priority (lower value -> higher priority)
	Kernel_Thread_Create(THREAD_SysSVC, 0);
	Kernel_Thread_Create(THREAD_TFT, 1);
	
	//run threads according to the priority
	Kernel_Thread_Run_All();
	
	while(1)
	{
		
		//nothing to do
		//all threads are managed by kernel
		
	}
	
}




#include "stm32g070xx.h"
#include "threads.h"
#include "kernel.h"
#include "debug.h"
#include "spi.h"
#include "tft.h"



__attribute__((noreturn)) 
void THREAD_SysSVC(void)
{
	//update system clock
	SystemCoreClockUpdate();
	
	//access debug port
	//print kernel info
	Debug_Init(38400);
	Kernel_Print_Info(Debug_Tx_Byte);
	
	
	while(1)
	{
		//check stack usage
		//report error in case of memory boundary violation
		//clear system watchdog to prevent reset
		//check system restart and reset causes
		Kernel_Thread_Sleep(1000);
		
	}
}




__attribute__((noreturn)) 
void THREAD_TFT(void)
{
	TFT_Init();
	TFT_Fill_Rect(0, 0, 240, 320, 0x0000);
	
	while(1)
	{
		TFT_Print_Number(2 ,  40, 135, 32, 48, 0xFFFF);
		TFT_Print_Number(5 ,  75, 135, 32, 48, 0xFFFF);
		TFT_Print_Number(12, 110, 135, 32, 48, 0xFFFF);
		TFT_Print_Raining(140, 120);
		Kernel_Thread_Sleep(1000);
	}
	
}

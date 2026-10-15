


/*
 * File          : kernel.h
 * Author        : MD. Faridul Islam (faridmdislam@gmail.com)
 * Source        : https://github.com/farid132097/STM32G030_RTOS
 * Description   : ARM Cortex M0+ kernel for bare-metal RTOS
 * Created       : Sep 02, 2025, 09:30 PM
 * Last Modified : Oct 01, 2026, 04:28 PM
 *
*/




#ifndef  _KERNEL_H_
#define  _KERNEL_H_

#include "stdint.h"


void     Kernel_Init(void);
void     Kernel_Thread_Create(void (*func)(void), uint32_t prio);
void     Kernel_Thread_Idle(void);
void     Kernel_Thread_Sleep(uint32_t val);
void     Kernel_Thread_Run_All(void);
uint32_t Kernel_Tick_SS32_Get(void);
uint64_t Kernel_Tick_SS64_Get(void);
uint32_t Kernel_Tick_S_Get(void);
void     Kernel_Timeout_Set(uint32_t val);
uint32_t Kernel_Timeout_Status(void);
uint32_t Kernel_CPU_Usage_x10_Get(void);
uint32_t Kernel_CPU_Usage_Avg_x10_Get(void);
uint8_t  Kernel_Version_Major_Get(void);
uint8_t  Kernel_Version_Minor_Get(void);
uint8_t  Kernel_Version_Patch_Get(void);
uint8_t  Kernel_Info_Char_Get(uint32_t index);
void     Kernel_Print_Info(void (*func)(uint8_t));

#endif




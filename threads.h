

#ifndef  _THREADS_H_
#define	 _THREADS_H_

#include "threads.h"

void    THREAD_SysSVC(void);
void    THREAD_WiFi_Communication(void);
void    THREAD_Power_Measurement(void);
void    THREAD_Load_Switch(void);
void	THREAD_Thermocouple(void);
void    THREAD_RTC(void);
void 	THREAD_Debug(void);
void    THREAD_Data_Sync(void);
void    THREAD_TFT(void);

#endif



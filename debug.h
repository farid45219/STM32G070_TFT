

/*
 * File:   debug.h
 * Author: MD. Faridul Islam
 * faridmdislam@gmail.com
 * LL Driver -> Debug Library
 * Rev 3.3 (23 Apr, 2025)
 * Created on December 12, 2024, 9:44 PM
 */
 



#ifndef  _DEBUG_H_
#define  _DEBUG_H_

#include "stdint.h"

void     Debug_Struct_Init(void);
void     Debug_RX_Packet_Struct_Init(void);

void     Debug_Config_GPIO(void);
void     Debug_Config_Clock(void);
void     Debug_Config_BAUD_Rate(uint32_t baud_rate);
void     Debug_Config_Tx(void);
void     Debug_Config_Rx(void);
void     Debug_Config_Rx_Interrupt(void);
void     Debug_Clear_Interrupt_Flag(void);
void     Debug_Tx_Byte(uint8_t val);
uint8_t  Debug_Rx_Byte(void);

void     Debug_Timer_Struct_Init(void);
void     Debug_Timer_Init(void);
void     Debug_Timer_Enable(void);
void     Debug_Timer_Disable(void);
uint8_t  Debug_Timer_Get_Status(void);
uint16_t Debug_Timer_Get_Val(void);
void     Debug_Timer_Value_Reset(void);
void     Debug_Timer_Clear_Interrupt_Flag(void);

void     Debug_Tx_Buf(volatile uint8_t *data, uint8_t start, uint8_t len);

void     Debug_Tx_NL(void);
void     Debug_Tx_SP(void);
void     Debug_Tx_CM(void);


void     Debug_Tx_Text(char *str);
void     Debug_Tx_Text_NL(char *str);
void     Debug_Tx_Text_SP(char *str);
void     Debug_Tx_Text_CM(char *str);


void     Debug_Determine_Digit_Numbers(uint32_t num);
void     Debug_Tx_Number_Digits(void);
void     Debug_Tx_Number(int32_t num);

void     Debug_Tx_Number_Hex_Raw(uint64_t val);
void     Debug_Tx_Number_Hex(uint64_t val);

void     Debug_Tx_Number_Bin_Raw(uint64_t val);
void     Debug_Tx_Number_Bin(uint64_t val);


void     Debug_Tx_Number_NL(int32_t num);
void     Debug_Tx_Number_SP(int32_t num);
void     Debug_Tx_Number_CM(int32_t num);


void     Debug_Tx_Number_Hex_NL(uint64_t num);
void     Debug_Tx_Number_Hex_SP(uint64_t num);
void     Debug_Tx_Number_Hex_CM(uint64_t num);


void     Debug_Tx_Number_Bin_NL(uint64_t num);
void     Debug_Tx_Number_Bin_SP(uint64_t num);
void     Debug_Tx_Number_Bin_CM(uint64_t num);


void     Debug_Tx_Parameter_NL(char *name, int32_t num);
void     Debug_Tx_Parameter_SP(char *name, int32_t num);
void     Debug_Tx_Parameter_CM(char *name, int32_t num);


void     Debug_Tx_Parameter_Hex_NL(char *name, uint64_t num);
void     Debug_Tx_Parameter_Hex_SP(char *name, uint64_t num);
void     Debug_Tx_Parameter_Hex_CM(char *name, uint64_t num);


void     Debug_Tx_Parameter_Bin_NL(char *name, uint64_t num);
void     Debug_Tx_Parameter_Bin_SP(char *name, uint64_t num);
void     Debug_Tx_Parameter_Bin_CM(char *name, uint64_t num);

void     Debug_Tx_Version(char *name, uint8_t major, uint8_t minor, uint8_t patch);

void     Debug_Tx_Parameter_Unit_NL(char *name, int32_t num, char *unit);
void     Debug_Tx_Parameter_Unit_SP(char *name, int32_t num, char *unit);
void     Debug_Tx_Parameter_Unit_CM(char *name, int32_t num, char *unit);

void     Debug_Tx_Parameter_Float_Unit_NL(char *name, float num, uint8_t dp, char *unit);
void     Debug_Tx_Parameter_Float_Unit_SP(char *name, float num, uint8_t dp, char *unit);
void     Debug_Tx_Parameter_Float_Unit_CM(char *name, float num, uint8_t dp, char *unit);

//Receiver Functions
void     Debug_Buf_Flush(void);
uint8_t  Debug_Buf_Get(uint16_t index);
uint16_t Debug_Buf_Get_Index(void);


//Debug Data Functions
uint8_t  Debug_Data_Available(void);
uint16_t Debug_Data_Len_Get(void);

uint16_t Debug_Data_Calculated_CRC_Get(void);
uint16_t Debug_Data_Received_CRC_Get(void);
uint8_t  Debug_Data_CRC_Status_Get(void);
uint8_t  Debug_Data_Read_Complete_Status(void);

void     Debug_Data_Clear_Available_Flag(void);
void     Debug_Data_Clear_Read_Complete_Flag(void);

void     Debug_Data_Copy_Buf(uint8_t *buf);
void     Debug_Data_Print_Buf(void);

uint8_t  Debug_Error_Code_Get(void);
void     Debug_Error_Code_Clear(void);
uint8_t  Debug_Sticky_Error_Code_Get(void);

void     Debug_ISR_Handler(void);
void     Debug_Timer_ISR_Handler(void);


uint16_t Debug_CRC_Calculate_Byte(uint16_t crc, uint8_t data);
uint16_t Debug_CRC_Calculate_Block(volatile uint8_t *buf, uint8_t len);

void     Debug_RX_Packet_CRC_Check(void);
void     Debug_RX_Packet_Disassemble(void);
void     Debug_RX_Packet_Read_Complete(void);

void     Debug_Init(uint32_t baud);

#endif



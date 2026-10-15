

#ifndef  _TFT_H_
#define  _TFT_H_

#include "stdint.h"


void 	TFT_Struct_Init(void);
void 	TFT_GPIO_Init(void);
void    TFT_RS_Pin_State_Set(uint8_t state);
void    TFT_Reset_Pin_State_Set(uint8_t state);
void 	TFT_Write_Cmd(uint8_t cmd);
void 	TFT_Write_Data(uint8_t cmd);
void 	TFT_Reg_Init(void);
void    TFT_Fill_Rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color);
void    TFT_Print_Number(uint8_t num, uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color);
void    TFT_Print_Integer_Number(int16_t num, uint16_t x, uint16_t y, uint16_t color);
void    TFT_Print_Image(uint8_t *image, uint16_t x, uint16_t y, uint16_t w, uint16_t h);
void    TFT_Print_Cloud(uint16_t x, uint16_t y);
void    TFT_Print_Droplet(uint16_t x, uint16_t y);
void 	TFT_Init(void);


#endif


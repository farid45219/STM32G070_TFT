

#ifndef  _SPI_H_
#define  _SPI_H_

#include "stdint.h"


void 	SPI_Struct_Init(void);
void 	SPI_GPIO_Init(void);
void	SPI_Clock_Init(void);
void	SPI_Reg_Init(uint32_t bit_rate);
void 	SPI_Slave_Select(void);
void 	SPI_Slave_Deselect(void);
void    SPI_Transfer(uint8_t data);
uint8_t SPI_Transceive(uint8_t data);
uint8_t SPI_Error_Get(void);
void 	SPI_Init(uint32_t bit_rate);


#endif



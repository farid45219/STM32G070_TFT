

#include "stm32g070xx.h"
#include "kernel.h"
#include "cdefs.h"
#include "spi.h"

typedef struct spi_t
{
	uint32_t  LoopCnt;
	uint32_t  CycleConst;
	uint8_t   Error;
}spi_t;


enum
{
	SPI_ERROR_NONE                 = 0x00,
	SPI_ERROR_TX_EMPTY_TIMEOUT     = 0x01,
	SPI_ERROR_RX_NOT_EMPTY_TIMEOUT = 0x02,
};


spi_t SPI;

void SPI_Struct_Init(void)
{
	SPI.LoopCnt = 0;
	SPI.Error = SPI_ERROR_NONE;
}

void SPI_GPIO_Init(void)
{
	//SCK->PB13, MISO->PC2, MOSI->PC3, CSN->PB14
	RCC->IOPENR |= RCC_IOPENR_GPIOBEN;
	RCC->IOPENR |= RCC_IOPENR_GPIOCEN;
	
	//config SCK as AFRH -> AF0
	GPIOB->AFR[1]  &=~ GPIO_AFRH_AFSEL13_Msk;
	GPIOB->AFR[1]  |=  (0 <<GPIO_AFRH_AFSEL13_Pos);
	GPIOB->OSPEEDR |=  GPIO_OSPEEDR_OSPEED13_Msk;
	GPIOB->MODER   &=~ GPIO_MODER_MODE13_Msk;
	GPIOB->MODER   |=  (2 << GPIO_MODER_MODE13_Pos);
	
	
	//config MISO as AFRL -> AF1
	GPIOC->AFR[0]  &=~ GPIO_AFRL_AFSEL2_Msk;
	GPIOC->AFR[0]  |=  (1 <<GPIO_AFRL_AFSEL2_Pos);
	GPIOC->OSPEEDR |=  GPIO_OSPEEDR_OSPEED2_Msk;
	GPIOC->MODER   &=~ GPIO_MODER_MODE2_Msk;
	GPIOC->MODER   |=  (2 << GPIO_MODER_MODE2_Pos);
	
	//config MOSI as AFRL -> AF1
	GPIOC->AFR[0]  &=~ GPIO_AFRL_AFSEL3_Msk;
	GPIOC->AFR[0]  |=  (1 <<GPIO_AFRL_AFSEL3_Pos);
	GPIOC->OSPEEDR |=  GPIO_OSPEEDR_OSPEED3_Msk;
	GPIOC->MODER   &=~ GPIO_MODER_MODE3_Msk;
	GPIOC->MODER   |=  (2 << GPIO_MODER_MODE3_Pos);
	
	//config CSN as GP output
	GPIOB->BSRR     =  GPIO_BSRR_BS14;
	GPIOB->OSPEEDR |=  GPIO_OSPEEDR_OSPEED14_Msk;
	GPIOB->MODER   &=~ GPIO_MODER_MODE14_Msk;
	GPIOB->MODER   |=  (1 << GPIO_MODER_MODE14_Pos);
}

void SPI_Clock_Init(void)
{
	RCC->APBENR1 |= RCC_APBENR1_SPI2EN;
}

void SPI_Reg_Init(uint32_t bit_rate)
{
	uint32_t tmp, br[8] = {2,4,8,16,32,64,128,256}, index = 0;
	SystemCoreClockUpdate();
	//calculate approximate cycle count per ms
	//this will be used for timeout
	SPI.CycleConst  = SystemCoreClock;
	SPI.CycleConst /= 1000; 
	
	tmp  = SystemCoreClock;
	tmp /= bit_rate;
	for(;;)
	{
		if( (tmp >= br[index]) && (tmp < br[index+1]) )
		{
			break;
		}
		else
		{
			index++;
		}
	}
	if(index > 7)
	{
		index = 7;
	}
	
	//disable spi
	SPI2->CR1 &=~ SPI_CR1_SPE;
	
	//config in CR1 register
	//config bit rate
	SPI2->CR1 &=~ SPI_CR1_BR_Msk;
	SPI2->CR1 |=  index << SPI_CR1_BR_Pos;
	//config CPOL, CPHA
	SPI2->CR1 |=  SPI_CR1_CPOL;
	SPI2->CR1 |=  SPI_CR1_CPHA;
	//config bidirectional mode
	SPI2->CR1 &=~ SPI_CR1_RXONLY;
	SPI2->CR1 &=~ SPI_CR1_BIDIMODE;
	SPI2->CR1 &=~ SPI_CR1_BIDIOE;
	//config LSB/MSB first
	SPI2->CR1 &=~ SPI_CR1_LSBFIRST;
	//config SSM, SSI
	SPI2->CR1 |=  SPI_CR1_SSM;
	SPI2->CR1 |=  SPI_CR1_SSI;
	//config MSTR
	SPI2->CR1 |=  SPI_CR1_MSTR;
	
	//config in CR2 register
	//config data len DRS[3:0]
	SPI2->CR2 &=~ SPI_CR2_DS_Msk;
	SPI2->CR2 |=  SPI_CR2_DS_0 | SPI_CR2_DS_1 | SPI_CR2_DS_2;
	//config fifo threshold
	SPI2->CR2 |=  SPI_CR2_FRXTH;
	//config DMA if req
	//config ss output
	//SPI2->CR2 |=  SPI_CR2_SSOE;
	SPI2->CR1 |=  SPI_CR1_SPE;
}

void SPI_Slave_Select(void)
{
	GPIOB->BSRR   =  GPIO_BSRR_BR14;
}

void SPI_Slave_Deselect(void)
{
	GPIOB->BSRR   =  GPIO_BSRR_BS14;
}

void SPI_Transfer(uint8_t data)
{
	while(( SPI2->SR & SPI_SR_TXE) != SPI_SR_TXE)
	{
		//wait until data register is empty
	}
	*((volatile uint8_t *)&SPI2->DR) = data;
	while(( SPI2->SR & SPI_SR_RXNE) != SPI_SR_RXNE)
	{
		//wait until data register is not empty
	}
	(void)SPI2->DR;
}

uint8_t SPI_Transceive(uint8_t data)
{
	uint8_t  rx_data = 0;
	/*uint32_t timeout;
	SPI.Error = SPI_ERROR_NONE;
	SPI.LoopCnt = 0;
	timeout = SPI.CycleConst * 5;*/
	while(( SPI2->SR & SPI_SR_TXE) != SPI_SR_TXE)
	{
		/*SPI.LoopCnt++;
		if(SPI.LoopCnt > timeout)
		{
			SPI.Error |= SPI_ERROR_TX_EMPTY_TIMEOUT;
			return rx_data;
		}*/
	}
	/*SPI.LoopCnt = 0;
	timeout = SPI.CycleConst * 5;*/
	*((volatile uint8_t *)&SPI2->DR) = data;
	while(( SPI2->SR & SPI_SR_RXNE) != SPI_SR_RXNE)
	{
		/*SPI.LoopCnt++;
		if(SPI.LoopCnt > timeout)
		{
			SPI.Error |= SPI_ERROR_RX_NOT_EMPTY_TIMEOUT;
			return rx_data;
		}*/
	}
	rx_data = *((volatile uint8_t *)&SPI2->DR);
	return rx_data;
}


uint8_t SPI_Error_Get(void)
{
	return SPI.Error;
}



void SPI_Init(uint32_t bit_rate)
{
	SPI_Struct_Init();
	SPI_GPIO_Init();
	SPI_Clock_Init();
	SPI_Reg_Init(bit_rate);
}
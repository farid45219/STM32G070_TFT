
/*
 * File:   debug.c
 * Author: MD. Faridul Islam
 * faridmdislam@gmail.com
 * LL Driver -> Debug Library
 * Rev 3.3 (23 Apr, 2025)
 * Created on December 12, 2024, 9:44 PM
 */


//add includes according to hardware
#include "stm32g070xx.h"


//must be included
#include "debug.h"


#define  DEBUG_DOUBLE_SPEED
#define  DEBUG_ENABLE_TX    
//#define  DEBUG_ENABLE_RX    
//#define  DEBUG_ENABLE_RX_INT

#define  DEBUG_BUFFER_SIZE               (  64U)
#define  DEBUG_RX_PCKT_CMPLT_DELAY       (  20U)
#define  DEBUG_INT_PRIORITY              (   4U)
#define  DEBUG_TIMEOUT_INT_PRIORITY      (   6U)


//#define  DEBUG_CRC_ENABLE     //Uncomment if packet validation by CRC is needed
#define  DEBUG_CRC_XMODEM     //Uncomment if X-MODEM CRC Protocol is used
//#define  DEBUG_CRC_ALTERNATE     //Uncomment if Alternate CRC Protocol is used




//Define Software Error Codes
#define  DEBUG_RX_ERR_NO_ERR             (0x00U)
#define  DEBUG_RX_ERR_FRAMING            (0x01U)
#define  DEBUG_RX_ERR_OVERRUN            (0x02U)
#define  DEBUG_RX_ERR_READ_INCOMPLETE    (0x10U)


typedef struct debug_timer_t{
  volatile uint8_t    Enabled;
  volatile uint8_t    ResetVal;
}debug_timer_t;

typedef struct debug_rx_packet_t{
  volatile uint16_t   CalculatedCRC;
  volatile uint16_t   ReceivedCRC;
  volatile uint8_t    CRCStatus;
  volatile uint8_t    DataAvailable;
  volatile uint8_t    DataReadComplete;
  volatile uint8_t    Reserved;
}debug_rx_packet_t;

typedef struct debug_t{
  volatile uint8_t    Error;
  volatile uint8_t    StickyError;
  uint8_t             Digits[8];
  uint8_t             InputNumDigits;

  volatile uint8_t    LastRxByte;
  volatile uint8_t    Buf[DEBUG_BUFFER_SIZE];
  volatile uint8_t    Reserved;
  volatile uint16_t   BufSize;
  volatile uint16_t   BufIndex;
  
  debug_timer_t       Timer;
  
  debug_rx_packet_t   RxPacket;
}debug_t;


enum{
  DEBUG_FALSE = 0,
  DEBUG_TRUE  = 1,
  DEBUG_NULL  = 0
};


static debug_t Debug;






/*******************Debug Structure Functions Start****************/

void Debug_Struct_Init(void){
  Debug.Error = DEBUG_NULL;
  Debug.StickyError = DEBUG_NULL;
  for(uint8_t i = 0; i < 8; i++){
    Debug.Digits[i] = DEBUG_NULL;
  }
  Debug.InputNumDigits = DEBUG_NULL;
  Debug.LastRxByte = DEBUG_NULL;
  Debug.BufSize = DEBUG_BUFFER_SIZE;
  Debug.BufIndex = 0;
  for(uint8_t i = 0; i < Debug.BufSize; i++){
    Debug.Buf[i] = DEBUG_NULL;
  }
}

void Debug_RX_Packet_Struct_Init(void){
  Debug.RxPacket.CalculatedCRC    = DEBUG_NULL;
  Debug.RxPacket.ReceivedCRC      = DEBUG_NULL;
  Debug.RxPacket.CRCStatus        = DEBUG_FALSE;
  Debug.RxPacket.DataAvailable    = DEBUG_FALSE;
  Debug.RxPacket.DataReadComplete = DEBUG_TRUE;
}

/********************Debug Structure Functions End*****************/









/*********************Debug Init Functions Start******************/

void Debug_Config_GPIO(void){
	//PA0->TX, PC11->RX
	if( (RCC->IOPENR & RCC_IOPENR_GPIOAEN)!= RCC_IOPENR_GPIOAEN ){
		RCC->IOPENR |= RCC_IOPENR_GPIOAEN;
	}
	
	/*
	if( (RCC->IOPENR & RCC_IOPENR_GPIOCEN)!= RCC_IOPENR_GPIOCEN ){
		RCC->IOPENR |= RCC_IOPENR_GPIOCEN;
	}*/
	
	//Config PA0 as alternate Func
	GPIOA->MODER &=~ GPIO_MODER_MODE0_Msk;
	GPIOA->MODER |=  GPIO_MODER_MODE0_1;
	
	//Enable Pull-up in PA0
	GPIOA->PUPDR &=~ GPIO_PUPDR_PUPD0_Msk;
	GPIOA->PUPDR |=  GPIO_PUPDR_PUPD0_0;
	
	//Select TX in AFR
	GPIOA->AFR[0]&=~ GPIO_AFRL_AFSEL0_Msk;
	GPIOA->AFR[0]|=  (4<<GPIO_AFRL_AFSEL0_Pos);

	/*
	//Config PC11 as alternate Func
	GPIOC->MODER &=~ GPIO_MODER_MODE11_Msk;
	GPIOC->MODER |=  GPIO_MODER_MODE11_1;
	
	//Enable Pull-up in PC11
	GPIOC->PUPDR &=~ GPIO_PUPDR_PUPD11_Msk;
	GPIOC->PUPDR |=  GPIO_PUPDR_PUPD11_0;
	
	//Select RX in AFR
	GPIOC->AFR[1]&=~ GPIO_AFRH_AFSEL11_Msk;
	GPIOC->AFR[1]|=  (1<<GPIO_AFRH_AFSEL11_Pos);
	*/
}

void Debug_Config_Clock(void){
  //add clock config
	RCC->APBENR1 |= RCC_APBENR1_USART4EN;
}

void Debug_Config_BAUD_Rate(uint32_t baud_rate){
  //add baud rate config
	SystemCoreClockUpdate();
	if(USART4->CR1 & USART_CR1_UE){
    USART4->CR1 &=~USART_CR1_UE;
	}
  USART4->BRR   = (uint16_t)(SystemCoreClock/baud_rate);
}


void Debug_Config_Tx(void){
  //add tx config
	USART4->CR1   |= USART_CR1_TE;
	if((USART4->CR1 & USART_CR1_UE) != USART_CR1_UE){
	  USART4->CR1 |= USART_CR1_UE;
	}
}


void Debug_Config_Rx(void){
  //add rx config
	USART4->CR1   |= USART_CR1_RE;
	if((USART4->CR1 & USART_CR1_UE) != USART_CR1_UE){
	  USART4->CR1 |= USART_CR1_UE;
	}
}

void Debug_Config_Rx_Interrupt(void){
  //add rx int config
	USART4->CR1  |= USART_CR1_RXNEIE_RXFNEIE;
	NVIC_EnableIRQ(USART3_4_IRQn);
	NVIC_SetPriority(USART3_4_IRQn, DEBUG_INT_PRIORITY);
}

void Debug_Clear_Interrupt_Flag(void){
  //Clear flag if necessary
}

void Debug_Tx_Byte(uint8_t val){
  //tx byte
	USART4->TDR=val;
	while((USART4->ISR & USART_ISR_TC)!=USART_ISR_TC);
	USART4->ICR|=USART_ICR_TCCF;	
}

uint8_t Debug_Rx_Byte(void){
  volatile uint8_t val = 0;
  val = (uint8_t)USART4->RDR;
  return val;
}



//add debug interrupt handler vector
//call Debug_ISR_Handler() inside ISR

/*
void USART3_4_IRQHandler(void){
	Debug_ISR_Handler();
}*/

/**********************Debug Init Functions End*******************/









/********************Debug Timer Functions Start*****************/

void Debug_Timer_Struct_Init(void){
  Debug.Timer.Enabled  = DEBUG_FALSE;
  Debug.Timer.ResetVal = DEBUG_NULL;
}

void Debug_Timer_Init(void){
  //config debug timer for auto packet validation
  //calculate Debug.Timer.ResetVal if overflow intterrupt is used
	SystemCoreClockUpdate();
	RCC->APBENR2 |= RCC_APBENR2_TIM17EN;
	TIM17->PSC    = (SystemCoreClock/1000)-1;
	TIM17->ARR    = DEBUG_RX_PCKT_CMPLT_DELAY;
	TIM17->DIER  |= TIM_DIER_UIE;
	NVIC_EnableIRQ(TIM17_IRQn);
	NVIC_SetPriority(TIM17_IRQn, DEBUG_TIMEOUT_INT_PRIORITY);
}

void Debug_Timer_Enable(void){
  //debug timer enable
	TIM17->CR1   |= TIM_CR1_CEN;
}

void Debug_Timer_Disable(void){ 
  //debug timer disable
	TIM17->CR1   &=~TIM_CR1_CEN;
}

uint8_t Debug_Timer_Get_Status(void){
  return Debug.Timer.Enabled;
}

uint16_t Debug_Timer_Get_Val(void){
  //return current timer val
	return (uint16_t)TIM17->CNT;
}


void Debug_Timer_Value_Reset(void){
  //reset timer val if compare mode selected
	TIM17->CNT = 0;
  //set timer val to Debug.Timer.ResetVal if Overflow int is used
}

void Debug_Timer_Clear_Interrupt_Flag(void){
  //Clear flag if necessary
	TIM17->SR &=~ TIM_SR_CC1IF;
	TIM17->SR &=~ TIM_SR_UIF;
}

//add debug timer interrupt handler vector
//call Debug_Timer_ISR_Handler() inside ISR

void TIM17_IRQHandler(void){
	Debug_Timer_ISR_Handler();
}


/*********************Debug Timer Functions End******************/









/********************Buffer Tx Functions Start*******************/

void Debug_Tx_Buf(volatile uint8_t *data, uint8_t start, uint8_t len){
  len += start;
  for(uint16_t i = 0; i < len; i++){
	Debug_Tx_Byte( data[i] );
  }
}

/*********************Buffer Tx Functions End********************/









/*******************End Char Functions Start******************/

void Debug_Tx_NL(void){
  Debug_Tx_Byte('\r');
  Debug_Tx_Byte('\n');
}

void Debug_Tx_SP(void){
  Debug_Tx_Byte(' ');
}

void Debug_Tx_CM(void){
  Debug_Tx_Byte(',');
}

/*******************End Char Functions End*******************/









/*********************Text Functions Start*******************/

void Debug_Tx_Text(char *str){
  uint8_t i = 0;
  while(str[i] != '\0'){
    Debug_Tx_Byte(str[i]);
    i++;
  }
}

void Debug_Tx_Text_NL(char *str){
  Debug_Tx_Text(str);
  Debug_Tx_NL();
}

void Debug_Tx_Text_SP(char *str){
  Debug_Tx_Text(str);
  Debug_Tx_SP();
}

void Debug_Tx_Text_CM(char *str){
  Debug_Tx_Text(str);
  Debug_Tx_CM();
}

/*********************Text Functions End********************/









/*********************Number Functions Start********************/

void Debug_Determine_Digit_Numbers(uint32_t num){
  uint8_t i = 0;
  if(num == 0){
    Debug.Digits[0] = 0;
    Debug.InputNumDigits = 1;
  }else{
    while(num != 0){
      Debug.Digits[i] = num%10;
      num /= 10;
      i++;
    }
	Debug.InputNumDigits = i;
  }
}

void Debug_Tx_Number_Digits(void){
  for(uint8_t i = Debug.InputNumDigits; i > 0; i--){
    uint8_t temp = i;
    temp -= 1;
    temp  = Debug.Digits[temp];
    temp += 48;
    Debug_Tx_Byte(temp);
  }
}

void Debug_Tx_Number(int32_t num){
  if(num < 0){
    Debug_Tx_Byte('-');
	  num = -num;
  }
  Debug_Determine_Digit_Numbers((uint32_t)num);
  Debug_Tx_Number_Digits();
}

void Debug_Tx_Number_Hex_Raw(uint64_t val){
  uint16_t hex_digit, index = 0, loop_counter = 0;
  if(val <= 0xFF){
    index = 8;
    loop_counter = 2;
  }
	else if(val <= 0xFFFF){
    index = 16;
    loop_counter = 4;     
  }
	else if(val <= 0xFFFFFF){
    index = 24;
    loop_counter = 6;     
  }
	else if(val <= 0xFFFFFFFF){
    index = 32;
    loop_counter = 8;     
  }
	else if(val <= 0xFFFFFFFFFF){
    index = 40;
    loop_counter = 10;     
  }
	else if(val <= 0xFFFFFFFFFFFF){
    index = 48;
    loop_counter = 12;     
  }
	else if(val <= 0xFFFFFFFFFFFFFF){
    index = 56;
    loop_counter = 14;     
  }
	else{
    index = 64;
    loop_counter = 16;
  }
  for(uint8_t i = 0; i < loop_counter; i++){
	  index -= 4;
	  hex_digit = ((val >> index) & 0x0F);
	  if(hex_digit > 9){
	    hex_digit += 55;
	  }
	  else{
	    hex_digit += 48;
	  }
	  Debug_Tx_Byte((uint8_t)hex_digit);
  }
}

void Debug_Tx_Number_Hex(uint64_t val){
  Debug_Tx_Byte('0');
  Debug_Tx_Byte('x');
  Debug_Tx_Number_Hex_Raw(val);
}


void Debug_Tx_Number_Bin_Raw(uint64_t val){
  uint8_t loop_counter = 0;
  if(val <= 0xFF){
    loop_counter = 7;
  }else if(val <= 0xFFFF){
    loop_counter = 15;     
  }else{
    loop_counter = 31;
  }
	
	if(val <= 0xFF){
    loop_counter = 7;
  }
	else if(val <= 0xFFFF){
    loop_counter = 15;     
  }
	else if(val <= 0xFFFFFF){
    loop_counter = 23;     
  }
	else if(val <= 0xFFFFFFFF){
    loop_counter = 31;     
  }
	else if(val <= 0xFFFFFFFFFF){
    loop_counter = 39;     
  }
	else if(val <= 0xFFFFFFFFFFFF){
    loop_counter = 47;     
  }
	else if(val <= 0xFFFFFFFFFFFFFF){
    loop_counter = 55;     
  }
	else{
    loop_counter = 63;
  }
  
  for(int i = loop_counter; i >= 0; i--){
    if( (val>>i) & 1){
      Debug_Tx_Byte( 49 );   
    }else{
      Debug_Tx_Byte( 48 );         
    }
  }
}

void Debug_Tx_Number_Bin(uint64_t val){
  Debug_Tx_Byte('0');
  Debug_Tx_Byte('b');
  Debug_Tx_Number_Bin_Raw(val);
}
/*********************Number Functions End*********************/









/************Number with End Char Functions Start**************/

void Debug_Tx_Number_NL(int32_t num){
  Debug_Tx_Number(num);
  Debug_Tx_NL();
}

void Debug_Tx_Number_SP(int32_t num){
  Debug_Tx_Number(num);
  Debug_Tx_SP();
}

void Debug_Tx_Number_CM(int32_t num){
  Debug_Tx_Number(num);
  Debug_Tx_CM();
}

/*************Number with End Char Functions End***************/









/**********Hex Number with End Char Functions Start************/

void Debug_Tx_Number_Hex_NL(uint64_t num){
  Debug_Tx_Number_Hex(num);
  Debug_Tx_NL();
}

void Debug_Tx_Number_Hex_SP(uint64_t num){
  Debug_Tx_Number_Hex(num);
  Debug_Tx_SP();
}

void Debug_Tx_Number_Hex_CM(uint64_t num){
  Debug_Tx_Number_Hex(num);
  Debug_Tx_CM();
}

/***********Hex Number with End Char Functions End*************/









/**********Bin Number with End Char Functions Start************/

void Debug_Tx_Number_Bin_NL(uint64_t num){
  Debug_Tx_Number_Bin(num);
  Debug_Tx_NL();
}

void Debug_Tx_Number_Bin_SP(uint64_t num){
  Debug_Tx_Number_Bin(num);
  Debug_Tx_SP();
}

void Debug_Tx_Number_Bin_CM(uint64_t num){
  Debug_Tx_Number_Bin(num);
  Debug_Tx_CM();
}

/***********Bin Number with End Char Functions End*************/









/************Number with Parameter Functions Start*************/

void Debug_Tx_Parameter_NL(char *name, int32_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_NL(num);
}

void Debug_Tx_Parameter_SP(char *name, int32_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_SP(num);
}

void Debug_Tx_Parameter_CM(char *name, int32_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_CM(num);
}

/*************Number with Parameter Functions End**************/









/**********Hex Number with Parameter Functions Start***********/

void Debug_Tx_Parameter_Hex_NL(char *name, uint64_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_Hex_NL(num);
}

void Debug_Tx_Parameter_Hex_SP(char *name, uint64_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_Hex_SP(num);
}

void Debug_Tx_Parameter_Hex_CM(char *name, uint64_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_Hex_CM(num);
}

/***********Hex Number with Parameter Functions End************/









/**********Bin Number with Parameter Functions Start***********/

void Debug_Tx_Parameter_Bin_NL(char *name, uint64_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_Bin_NL(num);
}

void Debug_Tx_Parameter_Bin_SP(char *name, uint64_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_Bin_SP(num);
}

void Debug_Tx_Parameter_Bin_CM(char *name, uint64_t num){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_Bin_CM(num);
}

/***********Bin Number with Parameter Functions End************/









/**********Bin Number with Parameter Functions Start***********/

void Debug_Tx_Version(char *name, uint8_t major, uint8_t minor, uint8_t patch){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number(major);
	Debug_Tx_Text(".");
	Debug_Tx_Number(minor);
	Debug_Tx_Text(".");
	Debug_Tx_Number(patch);
	Debug_Tx_NL();
}

/***********Bin Number with Parameter Functions End************/









/**********Number with Parameter-Unit Functions Start***********/

void Debug_Tx_Parameter_Unit_NL(char *name, int32_t num, char *unit){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_SP(num);
	Debug_Tx_Text_NL(unit);
}

void Debug_Tx_Parameter_Unit_SP(char *name, int32_t num, char *unit){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_SP(num);
	Debug_Tx_Text_SP(unit);
}

void Debug_Tx_Parameter_Unit_CM(char *name, int32_t num, char *unit){
  Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number_SP(num);
	Debug_Tx_Text_CM(unit);
}

/***********Number with Parameter-Unit Functions End***********/









/********Number with float Parameter-Unit Functions Start********/

void Debug_Tx_Parameter_Float_Unit_Base(char *name, float num, uint8_t dp, char *unit){
	float    fval;
	int32_t  dval;
	dval = (int32_t)num;
	fval = (float)dval;
	num -= fval;
	
	Debug_Tx_Text(name);
  Debug_Tx_SP();
  Debug_Tx_Number(dval);
	
	if(dp == 1){
		num *= 10;
		dval = (int32_t)num;
		Debug_Tx_Text(".");
		Debug_Tx_Number( dval );
		Debug_Tx_SP();
		Debug_Tx_Text(unit);
	}
	else if(dp == 2){
		num *= 100;
		dval = (int32_t)num;
		Debug_Tx_Text(".");
		Debug_Tx_Number( (dval/10)%10 );
		Debug_Tx_Number( (dval/1)%10 );
		Debug_Tx_SP();
		Debug_Tx_Text(unit);
	}
  else if(dp == 3){
		num *= 1000;
		dval = (int32_t)num;
		Debug_Tx_Text(".");
		Debug_Tx_Number( (dval/100)%10 );
		Debug_Tx_Number( (dval/10)%10 );
		Debug_Tx_Number( (dval/1)%10 );
		Debug_Tx_SP();
		Debug_Tx_Text(unit);
	}
	else if(dp == 4){
		num *= 10000;
		dval = (int32_t)num;
		Debug_Tx_Text(".");
		Debug_Tx_Number( (dval/1000)%10 );
		Debug_Tx_Number( (dval/100)%10 );
		Debug_Tx_Number( (dval/10)%10 );
		Debug_Tx_Number( (dval/1)%10 );
		Debug_Tx_SP();
		Debug_Tx_Text(unit);
	}
}

void Debug_Tx_Parameter_Float_Unit_NL(char *name, float num, uint8_t dp, char *unit){
	Debug_Tx_Parameter_Float_Unit_Base(name, num, dp, unit);
	Debug_Tx_NL();
}

void Debug_Tx_Parameter_Float_Unit_SP(char *name, float num, uint8_t dp, char *unit){
  Debug_Tx_Parameter_Float_Unit_Base(name, num, dp, unit);
	Debug_Tx_SP();
}

void Debug_Tx_Parameter_Float_Unit_CM(char *name, float num, uint8_t dp, char *unit){
  Debug_Tx_Parameter_Float_Unit_Base(name, num, dp, unit);
	Debug_Tx_CM();
}

/********Number with float Parameter-Unit Functions End********/









/*******************Debug Buffer Functions Start***************/

void Debug_Buf_Flush(void){
  for(uint8_t i = 0; i < DEBUG_BUFFER_SIZE; i++){
	Debug.Buf[i] = 0;
  }
  Debug.BufIndex = 0;
}

uint8_t Debug_Buf_Get(uint16_t index){
  return Debug.Buf[index];
}

uint16_t Debug_Buf_Get_Index(void){
  return Debug.BufIndex;
}

/********************Debug Buffer Functions End****************/









/*******************Debug Data Functions Start****************/

uint8_t Debug_Data_Available(void){
  return Debug.RxPacket.DataAvailable;
}

uint16_t Debug_Data_Len_Get(void){
  return Debug_Buf_Get_Index();
}

uint16_t Debug_Data_Calculated_CRC_Get(void){
  return Debug.RxPacket.CalculatedCRC;
}

uint16_t Debug_Data_Received_CRC_Get(void){
  return Debug.RxPacket.ReceivedCRC;
}

uint8_t Debug_Data_CRC_Status_Get(void){
  return Debug.RxPacket.CRCStatus;
}

uint8_t Debug_Data_Read_Complete_Status(void){
  return Debug.RxPacket.DataReadComplete;
}

void Debug_Data_Clear_Available_Flag(void){
  Debug.RxPacket.DataAvailable = DEBUG_FALSE;
}

void Debug_Data_Clear_Read_Complete_Flag(void){
  Debug.RxPacket.DataReadComplete = DEBUG_TRUE;
}



void Debug_Data_Copy_Buf(uint8_t *buf){
  for(uint16_t i = 0; i < Debug_Data_Len_Get(); i++){
	buf[i] = Debug_Buf_Get(i);
  }
}


void Debug_Data_Print_Buf(void){
  for(uint16_t i = 0; i < Debug_Data_Len_Get(); i++){
	Debug_Tx_Byte( Debug_Buf_Get(i) );
  }
  Debug_Tx_NL();
}

/********************Debug Data Functions End*****************/









/******************Error Code Functions Start****************/

uint8_t Debug_Error_Code_Get(void){
  return Debug.Error;
}

void Debug_Error_Code_Clear(void){
  Debug.Error = 0;
}

uint8_t Debug_Sticky_Error_Code_Get(void){
  uint8_t temp;
  temp = Debug.StickyError;
  Debug.StickyError = DEBUG_NULL;
  return temp;
}

/******************Error Code Functions End******************/









/***************Debug ISR Handler Functions Start************/

void Debug_ISR_Handler(void){
  Debug_Clear_Interrupt_Flag();
  Debug.LastRxByte = (uint8_t)Debug_Rx_Byte();
  if(Debug.Error == 0x00){
    Debug.Buf[Debug.BufIndex] = Debug.LastRxByte;
    Debug.BufIndex++;
    if(Debug.BufIndex >= Debug.BufSize){
      Debug.BufIndex = 0;
    }
  }
  else{
    Debug.LastRxByte = DEBUG_NULL;
	if(Debug.StickyError == DEBUG_NULL){
	  Debug.StickyError = Debug.Error;
	}
	Debug.Error = DEBUG_NULL;
  }
  
  Debug_Timer_Value_Reset();
  if(Debug.Timer.Enabled == DEBUG_FALSE){
	Debug_Timer_Enable();
	Debug.Timer.Enabled = DEBUG_TRUE;
  }
  
}

void Debug_Timer_ISR_Handler(void){
  Debug_Timer_Clear_Interrupt_Flag();
  if(Debug.Timer.Enabled == DEBUG_TRUE){
    Debug_Timer_Disable();
	Debug.Timer.Enabled = DEBUG_FALSE;
  }
  
  if(Debug_Buf_Get_Index() != DEBUG_NULL){
	if(Debug.RxPacket.DataReadComplete == DEBUG_FALSE){
	  Debug.Error = DEBUG_RX_ERR_READ_INCOMPLETE;
	  if(Debug.StickyError == DEBUG_NULL){
	    Debug.StickyError = Debug.Error;
	  }
	  Debug.Error = DEBUG_NULL;
	}
	
    Debug_RX_Packet_CRC_Check();
	
    #ifdef DEBUG_CRC_ENABLE
	if(Debug.RxPacket.CRCStatus == DEBUG_TRUE){
	  Debug.RxPacket.DataAvailable = DEBUG_TRUE;
	  Debug.RxPacket.DataReadComplete = DEBUG_FALSE;
	  Debug_RX_Packet_Disassemble();
	}
	else{
	  Debug_RX_Packet_Read_Complete();
	}
	#else
	Debug.RxPacket.DataAvailable = DEBUG_TRUE;
    Debug.RxPacket.DataReadComplete = DEBUG_FALSE;
	Debug_RX_Packet_Disassemble();
	#endif
  }
}

/****************Debug ISR Handler Functions End*************/









/******************Debug CRC Functions Start****************/

#ifdef   DEBUG_CRC_XMODEM

uint16_t Debug_CRC_Calculate_Byte(uint16_t crc, uint8_t data){
  uint16_t temp = data;
  temp <<= 8;
  crc = crc ^ temp;
  for(uint8_t i = 0; i < 8; i++){
    if(crc & 0x8000){
	  temp   = crc;
	  temp <<= 0x01;
	  temp  ^= 0x1021;
	  crc = temp;
	}
    else{
	  crc <<= 1;
	}
  }
  return crc;
}

uint16_t Debug_CRC_Calculate_Block(volatile uint8_t *buf, uint8_t len){
  uint16_t crc = 0;
  for(uint8_t i = 0; i < len; i++){
    crc = Debug_CRC_Calculate_Byte(crc,buf[i]);
  }
  return crc;
}
#endif

#ifdef   DEBUG_CRC_ALTERNATE

uint16_t CRCTable[16] = {
  0x0000, 0xCC01, 0xD801, 0x1400,
  0xF001, 0x3C00, 0x2800, 0xE401,
  0xA001, 0x6C00, 0x7800, 0xB401,
  0x5000, 0x9C01, 0x8801, 0x4400
};


uint16_t Debug_CRC_Calculate_Block(volatile uint8_t *buf, uint8_t len){
  uint16_t crc = 0xFFFF, i;
  uint8_t  Data;
  for (i = 0; i < len; i++) {
    Data = *buf++;
    crc = CRCTable[(Data ^ crc) & 0x0f] ^ (crc >> 4);
    crc = CRCTable[((Data >> 4) ^ crc) & 0x0f] ^ (crc >> 4);
  }
  crc = ((crc & 0xFF) << 8) | ((crc >> 8) & 0xFF);
  return crc;
}

#endif

/*******************Debug CRC Functions End*****************/









/*************Debug RX Packet Functions Start***************/

void Debug_RX_Packet_CRC_Check(void){
  uint8_t  temp = 0;
  uint16_t crc_calc = 0, crc_recv = 0;
  Debug.RxPacket.CRCStatus = DEBUG_FALSE;
  if( Debug_Data_Len_Get() > 2){
    temp  = (uint8_t)Debug_Data_Len_Get();
	temp -= 2;
    crc_calc   =  Debug_CRC_Calculate_Block(Debug.Buf, temp);
    crc_recv   =  Debug_Buf_Get(Debug_Data_Len_Get() - 2);
    crc_recv <<= 8;
    crc_recv  |= Debug_Buf_Get(Debug_Data_Len_Get() - 1);
	Debug.RxPacket.CalculatedCRC = crc_calc;
    Debug.RxPacket.ReceivedCRC = crc_recv;
    if( Debug.RxPacket.CalculatedCRC == Debug.RxPacket.ReceivedCRC ){
      Debug.RxPacket.CRCStatus = DEBUG_TRUE;
	}
  }
}

void Debug_RX_Packet_Disassemble(void){
  //Disassemble packet
}


void Debug_RX_Packet_Read_Complete(void){
  Debug_Buf_Flush();
  Debug_Data_Clear_Available_Flag();
  Debug_Data_Clear_Read_Complete_Flag();
  Debug_Error_Code_Clear();
}

/**************Debug RX Packet Functions End****************/









/*****************Debug Init Functions Start****************/

void Debug_Init(uint32_t baud){
  Debug_Struct_Init();
  Debug_RX_Packet_Struct_Init();
  Debug_Timer_Struct_Init();
  
  Debug_Config_GPIO();
  Debug_Config_Clock();
  Debug_Config_BAUD_Rate(baud);
  
  #ifdef DEBUG_ENABLE_TX  
  Debug_Config_Tx();
  #endif
  
  #ifdef DEBUG_ENABLE_RX
  Debug_Config_Rx();
  #endif
  
  #ifdef DEBUG_ENABLE_RX_INT
  Debug_Config_Rx_Interrupt();
  #endif
  
  Debug_Timer_Init();
  Debug_Timer_Value_Reset();
  Debug_Timer_Enable();
  Debug_Buf_Flush();
}

/******************Debug Init Functions End*****************/



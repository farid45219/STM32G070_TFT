 
 
 
 ; File          : kernel.s
 ; Author        : MD. Faridul Islam (faridmdislam@gmail.com)
 ; Source        : https://github.com/farid132097/STM32G030_RTOS
 ; Description   : ARM Cortex M0+ kernel for bare-metal RTOS
 ; Devices       : Tested on STM32G030F6P6
 ; Created       : Sep 02, 2025, 09:30 PM
 ; Last Modified : Oct 01, 2026, 04:28 PM




;;=============================system type definition starting===============================;; 
                      THUMB                                        ;enable thumb mode
                      PRESERVE8                                    ;8 bytes stack alignment
;;===============================system type definition end==================================;; 





;;============================constant area definition starting==============================;; 
                      AREA       |.constdata|, DATA, READONLY
;;==============================constant area definition end=================================;; 





;;==================================kernel config starting===================================;; 
DEF_KERNEL_VER_MAJOR  EQU        0x00000001                        ;set kernel version major
DEF_KERNEL_VER_MINOR  EQU        0x00000001                        ;set kernel version minor
DEF_KERNEL_VER_PATCH  EQU        0x00000001                        ;set kernel version patch
DEF_64MHZ_PLL_ENABLE  EQU        0x00000001                        ;enable/disable PLL 64MHz
DEF_KER_MAX_NTHREAD   EQU        0x0000000A                        ;number of maximum threads
DEF_KER_STACK_SIZE    EQU        0x00000200                        ;stack size for each thread
DEF_DBG_GPIO_TICK_EN  EQU        0x00000000                        ;enable/disable gpio toggle
DEF_DBG_GPIO_PORT     EQU        0x00000002                        ;value 00-05h,00->A, 01->B..
DEF_DBG_GPIO_PIN      EQU        0x0000000B                        ;pin number, value 00-0fh
DEF_INFO_BLOCK_SIZE   EQU        0x00000200                        ;info block size 512 bytes
;;====================================kernel config end======================================;;





;;===============================define address bases starting===============================;; 
DEF_PERIPHERAL_BASE   EQU        0x40000000                        ;peripheral start address
DEF_AHB_BASE          EQU        DEF_PERIPHERAL_BASE + 0x00020000  ;AHB start address
DEF_IOPORT_BASE       EQU        DEF_PERIPHERAL_BASE + 0x10000000  ;IO port start address
DEF_GPIO_BASE         EQU        DEF_IOPORT_BASE     + 0x00000000  ;GPIO start address
DEF_RCC_BASE          EQU        DEF_AHB_BASE        + 0x00001000  ;RCC start address
DEF_FLASH_BASE        EQU        DEF_AHB_BASE        + 0x00002000  ;Flash start address
DEF_SCS_BASE          EQU        0xE000E010                        ;SCS start address
DEF_SCB_BASE          EQU        0xE000ED00                        ;SCB start address
;;=================================define address bases end==================================;; 





;;==============================define flash addresses starting==============================;; 
DEF_FLASH_ACR         EQU        DEF_FLASH_BASE      + 0x00000000  ;Flash start address
;;================================define flash addresses end=================================;; 





;;===============================define rcc addresses starting===============================;; 
DEF_RCC_CR            EQU        DEF_RCC_BASE        + 0x00000000  ;RCC->CR start address
DEF_RCC_CFGR          EQU        DEF_RCC_BASE        + 0x00000008  ;RCC->CFGR start address
DEF_RCC_PLLCFGR       EQU        DEF_RCC_BASE        + 0x0000000C  ;RCC->PLLCFGR start address
;;==================================define rcc addresses end=================================;; 





;;============================define systick addresses starting==============================;; 
DEF_STK_CTRL          EQU        DEF_SCS_BASE        + 0x00000000  ;Systick->CTRL start address
DEF_STK_LOAD          EQU        DEF_SCS_BASE        + 0x00000004  ;Systick->LOAD start address
DEF_STK_VAL           EQU        DEF_SCS_BASE        + 0x00000008  ;Systick->VAL start address
;;===============================define systick addresses end================================;;





;;===============================define SCB addresses starting===============================;; 
DEF_SCB_ICSR          EQU        DEF_SCB_BASE        + 0x00000004  ;SCB->ICSR start address
DEF_SCB_SHPR3         EQU        DEF_SCB_BASE        + 0x00000020  ;SCB->SHPR3 start address
;;==================================define SCB addresses end=================================;;





;;===========================define GPIO related addresses starting==========================;; 
DEF_RCC_IOPENR        EQU        DEF_RCC_BASE        + 0x00000034  ;RCC->IOPENR start address
DEF_DBG_OFF           EQU        DEF_DBG_GPIO_PORT   * 0x00000400  ;calculate offset
DEF_DBG_GPIO_BASE     EQU        DEF_GPIO_BASE       + DEF_DBG_OFF ;calculate offset
DEF_DBG_GPIO_MODER    EQU        DEF_DBG_GPIO_BASE   + 0x00000000  ;calculate MODER addr
DEF_DBG_GPIO_BSRR     EQU        DEF_DBG_GPIO_BASE   + 0x00000018  ;calculate BSRR addr
DEF_DBG_GPIO_PORT_BM  EQU        ( 1 << DEF_DBG_GPIO_PORT )        ;calculate port bit mask
DEF_DBG_GPIO_PIN_BM   EQU        ( 1 << DEF_DBG_GPIO_PIN )         ;calculate bit mask value
DEF_DBG_GPIO_GM_OFF   EQU        ( DEF_DBG_GPIO_PIN << 1 )         ;calculate group offset
DEF_DBG_GPIO_PIN_GM   EQU        ( 3 << DEF_DBG_GPIO_GM_OFF )      ;calculate group mask value
DEF_DBG_GPIO_PIN_OUT  EQU        ( 1 << DEF_DBG_GPIO_GM_OFF )      ;calculate out group value
DEF_DBG_BSRR_BS_VAL   EQU        ( DEF_DBG_GPIO_PIN_BM   )         ;calculate BS val
DEF_DBG_BSRR_BR_OFF   EQU        ( DEF_DBG_GPIO_PIN + 16 )         ;calculate BR offset
DEF_DBG_BSRR_BR_VAL   EQU        ( 1 << DEF_DBG_BSRR_BR_OFF )      ;calculate BR val
;;=============================define GPIO related addresses end=============================;; 





;;==========================define stack size related value starting=========================;; 
DEF_KER_SYS_THREADS   EQU        DEF_KER_MAX_NTHREAD + 1
DEF_KER_STACK_SPACE   EQU        DEF_KER_SYS_THREADS * DEF_KER_STACK_SIZE   ;max stack size
;;============================define stack size related value end============================;; 





;;================================define system macro starting===============================;; 
THREAD_STS_READY      EQU        0x00                              ;ready state                 
THREAD_STS_BLOCKED    EQU        0x01                              ;blocked state               
THREAD_STS_SUSPENDED  EQU        0x02                              ;suspended state             
THREAD_STS_CONS_LAT   EQU        0x03                              ;constant latency state      
THREAD_STS_EXECUTING  EQU        0x04                              ;executing state             
;;===================================define system macro end=================================;; 





;;==============================RAM area definition starting=================================;; 
                      AREA       |.data|, DATA, READWRITE, ALIGN=3
;;================================RAM area definition end====================================;; 





;;=========================global variable declaration starting==============================;; 
                      EXPORT     KER_TICK_SS
                      EXPORT     KER_TICK_S
                      EXPORT     KER_TICK_S_CNT
                      EXPORT     KER_TOTAL_TICK_CNT
                      EXPORT     KER_ACTV_TICK_CNT
                      EXPORT     KER_CPU_USAGE
                      EXPORT     KER_CPU_USAGE_AVG
                      EXPORT     KER_THREAD_STACK
                      EXPORT     KER_THREAD_ID
                      EXPORT     KER_NTHREAD
                      EXPORT     KER_THREAD_PSP
                      EXPORT     KER_THREAD_PRIO
                      EXPORT     KER_THREAD_HI_PRIO
                      EXPORT     KER_THREAD_PRIO_TID
                      EXPORT     KER_THREAD_SLEEP
                      EXPORT     KER_THREAD_YIELD
                      EXPORT     KER_THREAD_STS
                      EXPORT     KER_THREAD_TOUT
                      EXPORT     KER_INFO_BLOCK
                      EXPORT     KER_TMP_VAR
;;===========================global variable declaration end=================================;; 





;;===========================global variable definition starting=============================;; 
KER_SYSTICK_RLD       SPACE      4                                 ;systick reload val
KER_TICK_SS           SPACE      8                                 ;64 bit sub-seconds counter
KER_TICK_S            SPACE      4                                 ;32 bit seconds counter
KER_TICK_S_CNT        SPACE      4                                 ;tick counter for Seconds
KER_TOTAL_TICK_CNT    SPACE      4                                 ;reference tick counter
KER_ACTV_TICK_CNT     SPACE      4                                 ;active thread entry counter
KER_CPU_USAGE         SPACE      4                                 ;instantenious cpu usage
KER_CPU_USAGE_AVG     SPACE      4                                 ;average cpu usage
KER_NTHREAD           SPACE      4                                 ;total created threads
KER_THREAD_STACK      SPACE      DEF_KER_STACK_SPACE + 0x08        ;total stack space
KER_THREAD_ID         SPACE      4                                 ;current thread id
KER_THREAD_PSP        SPACE      4 * DEF_KER_SYS_THREADS           ;PSP for 10 threads
KER_THREAD_PRIO       SPACE      4 * DEF_KER_SYS_THREADS           ;thread priority
KER_THREAD_HI_PRIO    SPACE      4                                 ;highest priority
KER_THREAD_PRIO_TID   SPACE      4                                 ;highest priority thread_id
KER_THREAD_SLEEP      SPACE      4 * DEF_KER_SYS_THREADS           ;thread sleep duration
KER_THREAD_YIELD      SPACE      4                                 ;thread yield status
KER_THREAD_STS        SPACE      4 * DEF_KER_SYS_THREADS           ;thread status
KER_THREAD_TOUT       SPACE      8 * DEF_KER_SYS_THREADS           ;2 byte timeout timestamps
KER_TMP_VAR           SPACE      4                                 ;temporary variables
;;=============================global variable definition end================================;; 





;;===============================kernel info block starting==================================;; 
KER_INFO_BLOCK
                      DCB        0x0D, 0x0A, 0x0D, 0x0A
                      DCB        0x4F, 0x53, 0x20, 0x45, 0x6E, 0x76, 0x69, 0x72
                      DCB        0x6F, 0x6E, 0x6D, 0x65, 0x6E, 0x74, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x46, 0x2D, 0x52, 0x54, 0x4F, 0x53
                      DCB        0x0D, 0x0A
                      DCB        0x4F, 0x53, 0x20, 0x50, 0x6C, 0x61, 0x74, 0x66
                      DCB        0x6F, 0x72, 0x6D, 0x20, 0x20, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x41, 0x52, 0x4D, 0x20, 0x43, 0x6F
                      DCB        0x72, 0x74, 0x65, 0x78, 0x20, 0x4D, 0x30, 0x2B
                      DCB        0x0D, 0x0A
                      DCB        0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x43
                      DCB        0x6F, 0x64, 0x65, 0x20, 0x20, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x67, 0x69, 0x74, 0x68, 0x75, 0x62
                      DCB        0x2E, 0x63, 0x6F, 0x6D, 0x2F, 0x66, 0x61, 0x72
                      DCB        0x69, 0x64, 0x31, 0x33, 0x32, 0x30, 0x39, 0x37
                      DCB        0x0D, 0x0A
                      DCB        0x41, 0x75, 0x74, 0x68, 0x6F, 0x72, 0x20, 0x45
                      DCB        0x6D, 0x61, 0x69, 0x6C, 0x20, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x66, 0x61, 0x72, 0x69, 0x64, 0x6D
                      DCB        0x64, 0x69, 0x73, 0x6C, 0x61, 0x6D, 0x40, 0x67
                      DCB        0x6D, 0x61, 0x69, 0x6C, 0x2E, 0x63, 0x6F, 0x6D
                      DCB        0x0D, 0x0A
KER_VERSION_INFO
                      DCB        0x4B, 0x65, 0x72, 0x6E, 0x65, 0x6C, 0x20, 0x56
                      DCB        0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x30, 0x2E, 0x30, 0x2E, 0x30, 0x0D
                      DCB        0x0A      
KER_MAX_THREAD_INFO
                      DCB        0x4D, 0x61, 0x78, 0x20, 0x54, 0x68, 0x72, 0x65
                      DCB        0x61, 0x64, 0x73, 0x20, 0x20, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x30, 0x30, 0x0D, 0x0A
KER_THREADS_CREATED_INFO
                      DCB        0x54, 0x68, 0x72, 0x65, 0x61, 0x64, 0x73, 0x20
                      DCB        0x43, 0x72, 0x65, 0x61, 0x74, 0x65, 0x64, 0x20
                      DCB        0x3A, 0x20, 0x30, 0x30, 0x0D, 0x0A
KER_STACK_MODEL_INFO
                      DCB        0x53, 0x74, 0x61, 0x63, 0x6B, 0x20, 0x4D, 0x6F
                      DCB        0x64, 0x65, 0x6C, 0x20, 0x20, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x55, 0x6E, 0x69, 0x66, 0x69, 0x65
                      DCB        0x64, 0x0D, 0x0A
KER_STACK_SIZE_INFO
                      DCB        0x53, 0x74, 0x61, 0x63, 0x6B, 0x20, 0x53, 0x69
                      DCB        0x7A, 0x65, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x30, 0x30, 0x30, 0x30, 0x20, 0x42
                      DCB        0x0D, 0x0A
KER_GPIO_TICK_DEBUG_INFO
                      DCB        0x47, 0x50, 0x49, 0x4F, 0x20, 0x54, 0x69, 0x63
                      DCB        0x6B, 0x20, 0x44, 0x65, 0x62, 0x75, 0x67, 0x20
                      DCB        0x3A, 0x20, 0x44, 0x69, 0x73, 0x61, 0x62, 0x6C
                      DCB        0x65, 0x64, 0x0D, 0x0A
KER_PLL_STATUS_INFO
                      DCB        0x43, 0x50, 0x55, 0x20, 0x50, 0x4C, 0x4C, 0x20
                      DCB        0x36, 0x34, 0x4D, 0x48, 0x7A, 0x20, 0x20, 0x20
                      DCB        0x3A, 0x20, 0x44, 0x69, 0x73, 0x61, 0x62, 0x6C
                      DCB        0x65, 0x64, 0x0D, 0x0A
                      DCB        0x0D, 0x0A, 0x0D, 0x0A
                      DCB        0x00, 0x00
KER_INFO_DATA_END
                      SPACE      DEF_INFO_BLOCK_SIZE - (KER_INFO_BLOCK - KER_INFO_DATA_END)
KER_INFO_BLOCK_END
;;==================================kernel info block end====================================;;





;;==============================code area definition starting================================;; 
                      AREA       |.ram_code|, CODE, READONLY, ALIGN=4
;;=================================code area definition end==================================;; 





;;=========================global function declaration starting==============================;; 
                      EXPORT     Kernel_Init
                      EXPORT     Kernel_Thread_Create
                      EXPORT     Kernel_Thread_Idle
                      EXPORT     Kernel_Thread_Sleep
                      EXPORT     Kernel_Thread_Run_All
                      EXPORT     Kernel_Tick_SS32_Get
                      EXPORT     Kernel_Tick_SS64_Get
                      EXPORT     Kernel_Tick_S_Get
                      EXPORT     Kernel_Timeout_Set
                      EXPORT     Kernel_Timeout_Status
                      EXPORT     Kernel_CPU_Usage_x10_Get
                      EXPORT     Kernel_CPU_Usage_Avg_x10_Get
                      EXPORT     Kernel_Version_Major_Get
                      EXPORT     Kernel_Version_Minor_Get
                      EXPORT     Kernel_Version_Patch_Get
                      EXPORT     Kernel_Info_Char_Get
                      EXPORT     Kernel_Print_Info
                      EXPORT     SysTick_Handler
                      EXPORT     PendSV_Handler
;;===========================global function declaration end=================================;; 





;;==========================macro for unsigned divide starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_KER_UDIV32      $ML                    ;macro name
                      MOV        R3,   R1                          ;R3 = divisor
                      MOVS       R1,   #0                          ;R1 = remainder
                      MOVS       R2,   #32                         ;loop counter
$ML.UDIV32_LOOP
                      LSLS       R0,   R0, #1                      ;left shift by 1
                      ADCS       R1,   R1, R1                      ;rem = rem*2+carry
                      CMP        R1,   R3                          ;compare val
                      BLO        $ML.UDIV32_NO_SUB                 ;
                      SUBS       R1,   R1, R3
                      ADDS       R0,   R0, #1
$ML.UDIV32_NO_SUB
                      SUBS       R2,   R2, #1
                      BNE        $ML.UDIV32_LOOP
                      MEND                                         ;macro end
;;============================macro for unsigned divide end==================================;; 




;;========================macro for loading system info starting=============================;; 
                      MACRO                                        ;macro start
                      MACRO_KER_INFO_INIT   $ML                    ;macro name
                      ;update version info
                      LDR        R0,   =KER_VERSION_INFO           ;load addr
                      MOVS       R1,   #DEF_KERNEL_VER_MAJOR       ;load addr
                      ADDS       R1,   R1, #0x30                   ;add 48
                      STRB       R1,   [R0, #18]                   ;offset store
                      MOVS       R1,   #DEF_KERNEL_VER_MINOR       ;load addr
                      ADDS       R1,   R1, #0x30                   ;add 48
                      STRB       R1,   [R0, #20]                   ;offset store
                      MOVS       R1,   #DEF_KERNEL_VER_PATCH       ;load addr
                      ADDS       R1,   R1, #0x30                   ;add 48
                      STRB       R1,   [R0, #22]                   ;offset store
                      ;update max number of threads info
                      LDR        R0,   =DEF_KER_MAX_NTHREAD        ;load max nthread
                      MOVS       R1,   #10                         ;divider
                      MACRO_KER_UDIV32 DIV1                        ;divide by 10
                      MOVS       R3,   #0xFF                       ;copy val
                      ANDS       R0,   R0, R3                      ;take LSByte
                      ANDS       R1,   R1, R3                      ;take LSByte
                      ADDS       R0,   R0, #0x30                   ;add 48
                      ADDS       R1,   R1, #0x30                   ;add 48
                      LDR        R2,   =KER_MAX_THREAD_INFO        ;load addr
                      STRB       R0,   [R2, #18]                   ;offset store
                      STRB       R1,   [R2, #19]                   ;offset store
                      ;update threads created info
                      LDR        R0,   =KER_NTHREAD                ;load nthread addr
                      LDR        R0,   [R0]                        ;load nthread val
                      SUBS       R0,   R0, #1                      ;discard idle thread
                      MOVS       R1,   #10                         ;divider
                      MACRO_KER_UDIV32 DIV2                        ;divide by 10
                      MOVS       R3,   #0xFF                       ;copy val
                      ANDS       R0,   R0, R3                      ;take LSByte
                      ANDS       R1,   R1, R3                      ;take LSByte
                      ADDS       R0,   R0, #0x30                   ;add 48
                      ADDS       R1,   R1, #0x30                   ;add 48
                      LDR        R2,   =KER_THREADS_CREATED_INFO   ;load addr
                      STRB       R0,   [R2, #18]                   ;offset store
                      STRB       R1,   [R2, #19]                   ;offset store
                      ;update stack size info
                      LDR        R0,   =DEF_KER_STACK_SIZE         ;load max nthread
                      LDR        R1,   =1000                       ;divider
                      MACRO_KER_UDIV32 DIV3                        ;divide by 1000
                      MOVS       R3,   #0xFF                       ;copy val
                      ANDS       R0,   R0, R3                      ;take LSByte
                      ADDS       R0,   R0, #0x30                   ;add 48
                      LDR        R2,   =KER_STACK_SIZE_INFO        ;load addr
                      STRB       R0,   [R2, #18]                   ;offset store
                      MOVS       R0,   R1                          ;copy remainder
                      MOVS       R1,   #100                        ;load val
                      MACRO_KER_UDIV32 DIV4                        ;divide by 100
                      MOVS       R3,   #0xFF                       ;copy val
                      ANDS       R0,   R0, R3                      ;take LSByte
                      ADDS       R0,   R0, #0x30                   ;add 48
                      LDR        R2,   =KER_STACK_SIZE_INFO        ;load addr
                      STRB       R0,   [R2, #19]                   ;offset store
                      MOVS       R0,   R1                          ;copy remainder
                      MOVS       R1,   #10                         ;load val
                      MACRO_KER_UDIV32 DIV5                        ;divide by 10
                      MOVS       R3,   #0xFF                       ;copy val
                      ANDS       R0,   R0, R3                      ;take LSByte
                      ADDS       R0,   R0, #0x30                   ;add 48
                      LDR        R2,   =KER_STACK_SIZE_INFO        ;load addr
                      STRB       R0,   [R2, #20]                   ;offset store
                      MOVS       R3,   #0xFF                       ;copy val
                      ANDS       R1,   R1, R3                      ;take LSByte
                      ADDS       R1,   R1, #0x30                   ;add 48
                      STRB       R1,   [R2, #21]                   ;offset store
                      ;update gpio tick debug info
                      MOVS       R0,   #DEF_DBG_GPIO_TICK_EN       ;load config
                      BEQ        $ML.TICK_DBG_SKIP                 ;jump to exit
                      LDR        R0,   =KER_GPIO_TICK_DEBUG_INFO   ;load addr
                      MOVS       R1,   #0x45                       ;load char
                      STRB       R1,   [R0, #18]                   ;offset store
                      MOVS       R1,   #0x6E                       ;load char
                      STRB       R1,   [R0, #19]                   ;offset store
                      MOVS       R1,   #0x61                       ;load char
                      STRB       R1,   [R0, #20]                   ;offset store
                      MOVS       R1,   #0x62                       ;load char
                      STRB       R1,   [R0, #21]                   ;offset store
                      MOVS       R1,   #0x6C                       ;load char
                      STRB       R1,   [R0, #22]                   ;offset store
                      MOVS       R1,   #0x65                       ;load char
                      STRB       R1,   [R0, #23]                   ;offset store
                      MOVS       R1,   #0x64                       ;load char
                      STRB       R1,   [R0, #24]                   ;offset store
                      MOVS       R1,   #0x20                       ;load char
                      STRB       R1,   [R0, #25]                   ;offset store DEF_64MHZ_PLL_ENABLE
$ML.TICK_DBG_SKIP
                      ;update cpu pll info
                      MOVS       R0,   #DEF_64MHZ_PLL_ENABLE       ;load config
                      BEQ        $ML.CPU_PLL_STATUS_SKIP           ;jump to exit
                      LDR        R0,   =KER_PLL_STATUS_INFO        ;load addr
                      MOVS       R1,   #0x45                       ;load char
                      STRB       R1,   [R0, #18]                   ;offset store
                      MOVS       R1,   #0x6E                       ;load char
                      STRB       R1,   [R0, #19]                   ;offset store
                      MOVS       R1,   #0x61                       ;load char
                      STRB       R1,   [R0, #20]                   ;offset store
                      MOVS       R1,   #0x62                       ;load char
                      STRB       R1,   [R0, #21]                   ;offset store
                      MOVS       R1,   #0x6C                       ;load char
                      STRB       R1,   [R0, #22]                   ;offset store
                      MOVS       R1,   #0x65                       ;load char
                      STRB       R1,   [R0, #23]                   ;offset store
                      MOVS       R1,   #0x64                       ;load char
                      STRB       R1,   [R0, #24]                   ;offset store
                      MOVS       R1,   #0x20                       ;load char
                      STRB       R1,   [R0, #25]                   ;offset store 
$ML.CPU_PLL_STATUS_SKIP
                      MEND                                         ;macro end
;;===========================macro for loading system info end===============================;;





;;=======================macro for system variable init starting=============================;; 
                      MACRO                                        ;macro start
                      MACRO_SYS_VAR_INIT                           ;macro name
                      LDR        R0,   =KER_TICK_SS                ;load tick_ss addr
                      MOVS       R1,   #0x00                       ;set val 0
                      STR        R1,   [R0]                        ;store tick_ssL val
                      STR        R1,   [R0,  #4]                   ;store tick_ssH val
                      LDR        R0,   =KER_TICK_S                 ;load tick_s addr
                      STR        R1,   [R0]                        ;store tick_s val
                      LDR        R0,   =KER_TICK_S_CNT             ;load tick_s_cnt addr
                      STR        R1,   [R0]                        ;store all_tick_cnt val
                      LDR        R0,   =KER_TOTAL_TICK_CNT         ;load all_tick_cnt addr
                      STR        R1,   [R0]                        ;store all_tick_cnt val
                      LDR        R0,   =KER_ACTV_TICK_CNT          ;load active_tick_cnt addr
                      STR        R1,   [R0]                        ;store idle_tick_cnt val
                      LDR        R0,   =KER_CPU_USAGE              ;load cpu_usage addr
                      STR        R1,   [R0]                        ;store cpu_usage val
                      LDR        R0,   =KER_CPU_USAGE_AVG          ;load cpu_usage_avg addr
                      STR        R1,   [R0]                        ;store cpu_usage_avg val
                      LDR        R0,   =KER_NTHREAD                ;load nthread addr
                      STR        R1,   [R0]                        ;store nthread val
                      LDR        R0,   =KER_THREAD_ID              ;load thread_id addr
                      STR        R1,   [R0]                        ;store thread_id val
                      LDR        R0,   =KER_THREAD_YIELD           ;load nthread addr
                      STR        R1,   [R0]                        ;store nthread val
                      MEND                                         ;macro end
;;==========================macro for system variable init end===============================;; 





;;==========================macro for debug gpio init starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_GPIO_INIT  $ML                         ;macro name
                      ;if debug disabled, skip
                      MOVS       R0,   #DEF_DBG_GPIO_TICK_EN       ;load device config
                      BEQ        $ML.EXIT                          ;jump to exit
                      ;enable clock from rcc
                      LDR        R0,   =DEF_RCC_IOPENR             ;load IOPENR address
                      LDR        R1,   [R0]                        ;load IOPENR val
                      LDR        R2,   =DEF_DBG_GPIO_PORT_BM       ;load bit mask val
                      ORRS       R1,   R1, R2                      ;set bit WRT PORT
                      STR        R1,   [R0]                        ;store val to IOPENR
                      ;set BSRR->BR->pin low
                      LDR        R0,   =DEF_DBG_GPIO_BSRR          ;load BSRR address
                      LDR        R1,   =DEF_DBG_BSRR_BR_VAL        ;load BSRR->BR val
                      STR        R1,   [R0]                        ;store val
                      ;set pin as general purpose i/o
                      LDR        R0,   =DEF_DBG_GPIO_MODER         ;load MODER address
                      LDR        R1,   [R0]                        ;load MODER val
                      LDR        R2,   =DEF_DBG_GPIO_PIN_GM        ;load MODER group mask val
                      MVNS       R2,   R2                          ;invert bits
                      ANDS       R1,   R1, R2                      ;clear mode bits
                      LDR        R2,   =DEF_DBG_GPIO_PIN_OUT       ;load MODER ->out val
                      ORRS       R1,   R1, R2                      ;set output mode
                      STR        R1,   [R0]                        ;store val to MODER
$ML.EXIT
                      MEND                                         ;macro end
;;==========================macro for debug gpio init end====================================;; 





;;===========================macro for gpio set starting=====================================;; 
                      MACRO                                        ;macro start
                      MACRO_GPIO_SET   $ML                         ;macro name
                      ;if debug disabled, skip
                      MOVS       R0,   #DEF_DBG_GPIO_TICK_EN       ;load device config
                      BEQ        $ML.EXIT                          ;jump to exit
                      LDR        R0,   =DEF_DBG_GPIO_BSRR          ;load BSRR address
                      LDR        R1,   =DEF_DBG_BSRR_BS_VAL        ;load bit set val
                      STR        R1,   [R0]                        ;store val
$ML.EXIT
                      MEND                                         ;macro end
;;=============================macro for gpio set end========================================;; 





;;===========================macro for gpio clear starting===================================;; 
                      MACRO                                        ;macro start
                      MACRO_GPIO_CLEAR  $ML                        ;macro name
                      ;if debug disabled, skip
                      MOVS       R0,   #DEF_DBG_GPIO_TICK_EN       ;load device config
                      BEQ        $ML.EXIT                          ;jump to exit
                      LDR        R0,   =DEF_DBG_GPIO_BSRR          ;load BSRR address
                      LDR        R1,   =DEF_DBG_BSRR_BR_VAL        ;load bit clear val
                      STR        R1,   [R0]                        ;store val
$ML.EXIT
                      MEND                                         ;macro end
;;=============================macro for gpio clear end======================================;; 





;;========================macro for PLL Clock config starting================================;; 
                      MACRO                                        ;macro start
                      MACRO_64MHZ_PLL_CONFIG  $ML                  ;macro name
$ML.HSI16ON
                      LDR        R0,   =DEF_RCC_CR                 ;load addr
                      LDR        R1,   [R0]                        ;load val
                      LDR        R2,   =0x100                      ;bit8, HSI ON
                      ORRS       R1,   R1, R2                      ;R1 | R2
                      LDR        R2,   =0x3800                     ;bit 11,12,13 set
                      MVNS       R2,   R2                          ;invert all bits
                      ANDS       R1,   R1, R2                      ;clear HSIDIV
                      STR        R1,   [R0]                        ;store val
$ML.HSI16READY        
                      LDR        R1,   [R0]                        ;load val
                      LDR        R0,   =0x400                      ;bit10, HSIRDY
                      TST        R0,   R1                          ;check bit 10
                      BEQ        $ML.HSI16READY                    ;wait unitl ready
$ML.CHECKCONFIG        
                      MOVS       R0,   #DEF_64MHZ_PLL_ENABLE       ;load device config
                      BEQ        $ML.CLOCK16MHZ                    ;jump to 16Mhz if 0
$ML.CLOCK64MHZ        
                      LDR        R0,   =63999                      ;load val for 1ms
                      LDR        R1,   =KER_SYSTICK_RLD            ;load reload reg addr
                      STR        R0,   [R1]                        ;store val
                      LDR        R0,   =DEF_FLASH_ACR              ;load addr
                      LDR        R1,   [R0]                        ;load data
                      MOVS       R2,   #7                          ;load val
                      MVNS       R2,   R2                          ;invert bits
                      ANDS       R1,   R1, R2                      ;clear bits 0-2
                      MOVS       R2,   #2                          ;load val
                      ORRS       R1,   R1, R2                      ;set 2 wait states
                      STR        R1,   [R0]                        ;store val
$ML.WAITSTATES        
                      LDR        R1,   [R0]                        ;load val
                      MOVS       R2,   #7                          ;load val
                      ANDS       R1,   R1, R2                      ;mask bits 0-2
                      MOVS       R2,   #2                          ;load val
                      CMP        R1,   R2                          ;compare
                      BNE        $ML.WAITSTATES                    ;jmp to label
$ML.PLLDISABLE        
                      LDR        R0,   =DEF_RCC_CR                 ;load addr
                      LDR        R1,   [R0]                        ;load val
                      LDR        R2,   =0x01000000                 ;bit 24, PLLON
                      MVNS       R2,   R2                          ;invert bits
                      ANDS       R1,   R2                          ;clear bit
                      STR        R1,   [R0]                        ;store val
$ML.PLLUNLOCK         
                      LDR        R1,   [R0]                        ;load val
                      LDR        R2,   =0x02000000                 ;bit 25, PLLRDY
                      ANDS       R1,   R2                          ;check bit
                      BNE        $ML.PLLUNLOCK                     ;wait until unlocked
$ML.PLLSETUP          
                      LDR        R0,   =DEF_RCC_PLLCFGR            ;load addr
                      LDR        R1,   =0x30000802                 ;R=2, N=8, N=1, REN, HSISRC
                      STR        R1,   [R0]                        ;store val
                      LDR        R0,   =DEF_RCC_CR                 ;load addr
                      LDR        R1,   [R0]                        ;load val
                      LDR        R2,   =0x01000000                 ;bit 24, PLLON
                      ORRS       R1,   R1, R2                      ;set bit 24
                      STR        R1,   [R0]                        ;store val
$ML.PLLLOCK           
                      LDR        R1,   [R0]                        ;load val
                      LDR        R2,   =0x02000000                 ;bit 25, PLLRDY
                      ANDS       R1,   R2                          ;check bit
                      BEQ        $ML.PLLLOCK                       ;wait until locked
$ML.SWPLLRSW           
                      LDR        R0,   =DEF_RCC_CFGR               ;load addr
                      LDR        R1,   [R0]                        ;load val
                      MOVS       R2,   #0x07                       ;set bit0-2
                      MVNS       R2,   R2                          ;invert all bits
                      ANDS       R1,   R1, R2                      ;clear SW bits
                      MOVS       R2,   #0x02                       ;PLLRCLK
                      ORRS       R1,   R1, R2                      ;set PLLRCLK
                      STR        R1,   [R0]                        ;store val
$ML.SWSPLLR           
                      LDR        R1,   [R0]                        ;load val
                      MOVS       R2,   #0x38                       ;set bit0-2
                      ANDS       R1,   R1, R2                      ;clear SW bits
                      MOVS       R2,   #0x10                       ;PLLRCLK
                      CMP        R1,   R2                          ;compare
                      BNE        $ML.SWSPLLR                       ;jmp to label
                      B          $ML.EXIT                          ;jmp to label
$ML.CLOCK16MHZ
                      LDR        R0,   =15999                      ;load val for 1ms
                      LDR        R1,   =KER_SYSTICK_RLD            ;load reload reg addr
                      STR        R0,   [R1]                        ;store val
                      LDR        R0,   =DEF_RCC_CFGR               ;load addr
                      LDR        R1,   [R0]                        ;load val
                      MOVS       R2,   #0x07                       ;set bit0-2
                      MVNS       R2,   R2                          ;invert all bits
                      ANDS       R1,   R1, R2                      ;clear SW bits
                      STR        R1,   [R0]                        ;store val
$ML.SWSHSISYS         
                      LDR        R1,   [R0]                        ;load val
                      MOVS       R2,   #0x38                       ;bit 3,4,5 set
                      TST        R1,   R2                          ;check bits
                      BNE        $ML.SWSHSISYS                     ;wait until switched
                      
$ML.EXIT
                      MEND                                         ;macro end
;;==========================macro for PLL Clock config end===================================;; 





;;===========================macro for systick config starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_SYSTICK_CONFIG                         ;macro name
                      LDR        R0,   =KER_SYSTICK_RLD            ;load reload reg addr
                      LDR        R0,   [R0]                        ;load reload val
                      LDR        R1,   =DEF_STK_LOAD               ;load stk_load reg address
                      STR        R0,   [R1]                        ;set val to reg
                      LDR        R0,   =DEF_STK_VAL                ;load stk_val reg address
                      MOVS       R1,   #0x00                       ;clear reg
                      STR        R1,   [R0]                        ;clear stk_val reg
                      LDR        R0,   =DEF_STK_CTRL               ;load stk_ctrl reg address
                      MOVS       R1,   #0x07                       ;mask bit0, bit1 & bit2
                      STR        R1,   [R0]                        ;set val to stk_ctrl
                      MEND                                         ;macro end
;;=============================macro for systick config end==================================;; 





;;===========================macro for pushing R4-R11 starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_PUSH_R4_R11                            ;macro name
                      MRS        R0,   PSP                         ;load PSP in R0
                      SUBS       R0,   #32                         ;subtract 32 bytes
                      STR        R4,   [R0, #0]                    ;load data
                      STR        R5,   [R0, #4]                    ;load data
                      STR        R6,   [R0, #8]                    ;load data
                      STR        R7,   [R0, #12]                   ;load data
                      MOV        R1,   R8                          ;copy
                      STR        R1,   [R0, #16]                   ;load data
                      MOV        R1,   R9                          ;copy
                      STR        R1,   [R0, #20]                   ;load data
                      MOV        R1,   R10                         ;copy
                      STR        R1,   [R0, #24]                   ;load data
                      MOV        R1,   R11                         ;copy
                      STR        R1,   [R0, #28]                   ;load data
                      MSR        PSP,  R0                          ;update new top of stack
                      MEND                                         ;macro end
;;============================macro for pushing R4-R11 end===================================;; 





;;===========================macro for popping R4-R11 starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_POP_R11_R4                             ;macro name
                      LDR        R4,   [R0, #0]                    ;load data
                      LDR        R5,   [R0, #4]                    ;load data
                      LDR        R6,   [R0, #8]                    ;load data
                      LDR        R7,   [R0, #12]                   ;load data
                      LDR        R1,   [R0, #16]                   ;load data
                      MOV        R8,   R1                          ;copy
                      LDR        R1,   [R0, #20]                   ;load data
                      MOV        R9,   R1                          ;copy
                      LDR        R1,   [R0, #24]                   ;load data
                      MOV        R10,  R1                          ;copy
                      LDR        R1,   [R0, #28]                   ;load data
                      MOV        R11,  R1                          ;copy
                      ADDS       R0,   #32                         ;add 32 bytes
                      MSR        PSP,  R0                          ;update new top of stack
                      MEND                                         ;macro end
;;==============================macro for popping R4-R11 end=================================;; 





;;================================macro for offset starting==================================;; 
                      MACRO                                        ;macro start
                      MACRO_OFFSET_CALC                            ;macro name
                      LDR        R0,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R0,   [R0]                        ;load thread_id val
                      LSLS       R0,   R0,  #0x02                  ;left shift 2 times to x4
                      MEND                                         ;macro end
;;===================================macro for offset end====================================;; 




;;==============================macro for saving psp starting================================;; 
                      MACRO                                        ;macro start
                      MACRO_SAVE_PSP                               ;macro name
                      MACRO_OFFSET_CALC                            ;calculate offset, ret R0
                      LDR        R1,   =KER_THREAD_PSP             ;load thread psp addr base
                      ADD        R0,   R0,  R1                     ;calc offset from psp base
                      MRS        R1,   PSP                         ;load PSP in R1
                      STR        R1,   [R0]                        ;set val to reg
                      MEND                                         ;macro end
;;=================================macro for saving psp end==================================;; 





;;==============================macro for loading psp starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_LOAD_PSP                               ;macro name
                      MACRO_OFFSET_CALC                            ;calculate offset, ret R0
                      LDR        R1,   =KER_THREAD_PSP             ;load thread psp addr base
                      ADD        R0,   R0,  R1                     ;calc offset from psp base
                      LDR        R0,   [R0]                        ;load thread PSP
                      MEND                                         ;macro end
;;=================================macro for loading psp end=================================;; 





;;=============================macro for context save starting===============================;; 
                      MACRO                                        ;macro start
                      MACRO_CONTEXT_SAVE                           ;macro name
                      MACRO_PUSH_R4_R11                            ;push R4-R11 manually
                      MACRO_SAVE_PSP                               ;save psp
                      MEND                                         ;macro end
;;================================macro for context save end=================================;; 





;;============================macro for context restore starting=============================;; 
                      MACRO                                        ;macro start
                      MACRO_CONTEXT_RESTORE                        ;macro name
                      MACRO_LOAD_PSP                               ;load psp
                      MACRO_POP_R11_R4                             ;pop R11-R4 manually
                      MEND                                         ;macro end
;;==============================macro for context restore end================================;; 





;;=======================macro for sleep time management starting============================;; 
                      MACRO                                        ;macro start
                      MACRO_KER_SLP_TIME_MGNT $ML                  ;macro name, local label
                      MACRO_OFFSET_CALC                            ;calculate offset, ret R0
                      LDR        R1,   =KER_THREAD_SLEEP           ;load sleep addr
                      ADDS       R1,   R1, R0                      ;sleep base+offset
                      LDR        R2,   [R1]                        ;load sleep duration
                      CMP        R2,   #0x00                       ;compare with 0
                      BEQ        $ML.TREADY                        ;jmp to label
                      
                      ;check if yield flag(R1 is sleep val addr, R2 is curr sleep val)
                      LDR        R3,   =KER_THREAD_YIELD           ;load yield flag addr
                      LDR        R3,   [R3]                        ;load yield flag val
                      TST        R3,   R3                          ;test val
                      BNE        $ML.TBLOCKED                      ;if !=0, skip decrement
$ML.SLPDEC                                                         ;sleep time decrement
                      SUBS       R2,   R2, #0x01                   ;decrease by 1
                      STR        R2,   [R1]                        ;store new val
                      CMP        R2,   #0x00                       ;compare with 0
                      BEQ        $ML.TREADY                        ;jmp to label
$ML.TBLOCKED                                                       ;label->thread blocked
                      LDR        R1,   =THREAD_STS_BLOCKED         ;set status blocked
                      B          $ML.UPDSTS                        ;jmp to label
$ML.TREADY                                                         ;label->thread ready
                      LDR        R1,   =THREAD_STS_READY           ;set status ready
$ML.UPDSTS                                                         ;label->update status
                      LDR        R2,   =KER_THREAD_STS             ;load status base addr
                      ADDS       R2,   R2, R0                      ;base+offset
                      STR        R1,   [R2]                        ;store status
$ML.EXIT
                      MEND                                         ;macro end
;;=========================macro for sleep time management end===============================;; 





;;============================macro for scheduler starting===================================;; 
                      MACRO                                        ;macro start
                      MACRO_KER_RUN_SCHEDULER $ML1, $ML2           ;macro name, local label
                      
                      ;init values before loop entry
                      MOVS       R0,   #0xFF                       ;set val
                      LDR        R1,   =KER_THREAD_HI_PRIO         ;load hi-prio addr
                      STR        R0,   [R1]                        ;store lowest priority
                      MOVS       R0,   #0x00                       ;set val
                      LDR        R1,   =KER_THREAD_PRIO_TID        ;load prio tid addr
                      STR        R0,   [R1]                        ;store prio tid
                      MOVS       R0,   #0x00                       ;set val
                      LDR        R1,   =KER_THREAD_ID              ;load thread_id addr
                      STR        R0,   [R1]                        ;store thread_id
                      
$ML2.LP_STRT                                                       ;label-> loop start
                      MACRO_KER_SLP_TIME_MGNT $ML1                 ;time mangement
                      
                      ;calculate offset R0, load status 
                      LDR        R1,   =KER_THREAD_STS             ;load status base addr
                      ADDS       R1,   R1, R0                      ;status base+offset
                      LDR        R1,   [R1]                        ;load status
                      
                      ;check if thread ready
                      LDR        R2,   =THREAD_STS_READY           ;load ready status
                      CMP        R1,   R2                          ;compare
                      BNE        $ML2.BL_OR_LP                     ;jmp to label (blocked)
                      
                      ;thread is ready
                      LDR        R1,   =KER_THREAD_HI_PRIO         ;load hi-prio addr
                      LDR        R2,   [R1]                        ;load hi-prio val
                      LDR        R3,   =KER_THREAD_PRIO            ;load prio base addr
                      ADDS       R3,   R3, R0                      ;prio base+offset
                      LDR        R3,   [R3]                        ;load prio val
                      
                      ;check current priority >= highest priority (lower val is higher priority)
                      CMP        R3,   R2                          ;compare 
                      BHS        $ML2.BL_OR_LP                     ;jmp to label (low prio)
                      
                      ;new high prio found
                      STR        R3,   [R1]                        ;store new hi-prio
                      LDR        R0,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R0,   [R0]                        ;load thread_id val
                      LDR        R1,   =KER_THREAD_PRIO_TID        ;load prio thread_id addr
                      STR        R0,   [R1]                        ;store prio thread_id
$ML2.BL_OR_LP                                                      ;label->blocked or low priority
                      LDR        R0,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R1,   [R0]                        ;load thread_id val
                      ADDS       R1,   R1, #1                      ;increment
                      LDR        R2,   =KER_NTHREAD                ;load nthread addr
                      LDR        R2,   [R2]                        ;load nthread val
                      CMP        R1,   R2                          ;compare
                      BHS        $ML2.LP_END                       ;thread_id>=nthread
                      STR        R1,   [R0]                        ;store new thread_id
                      B          $ML2.LP_STRT                      ;loop start
$ML2.LP_END                                                        ;loop complete
                      LDR        R0,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R1,   =KER_THREAD_PRIO_TID        ;load prio tid addr
                      LDR        R1,   [R1]                        ;load prio tid val
                      STR        R1,   [R0]                        ;store new prio tid
$ML2.EXIT
                      MEND                                         ;macro end
;;================================macro for scheduler end====================================;; 





;;==========================macro for sub-seconds counter starting===========================;; 
                      MACRO                                        ;macro start
                      MACRO_SS_CNT     $ML                         ;macro name
                      LDR        R0,   =KER_THREAD_YIELD           ;load yield flag addr
                      LDR        R1,   [R0]                        ;load yield flag val
                      TST        R1,   R1                          ;test val
                      BNE        $ML.EXIT                          ;jmp to label
                      LDR        R0,   =KER_TICK_SS                ;load tick_ss base addr
                      LDR        R1,   [R0]                        ;load systick ss LSW val
                      ADDS       R1,   R1,  #1                     ;increment val
                      STR        R1,   [R0]                        ;store val
                      BNE        $ML.EXIT                          ;jmp to label
                      LDR        R1,   [R0, #4]                    ;load systick ss HSW val
                      ADDS       R1,   R1,  #1                     ;increment val
                      STR        R1,   [R0, #4]                    ;store val
$ML.EXIT
                      MEND                                         ;macro end
;;============================macro for sub-seconds counter end==============================;; 





;;============================macro for seconds counter starting=============================;; 
                      MACRO                                        ;macro start
                      MACRO_S_CNT      $ML                         ;macro name
                      LDR        R0,   =KER_THREAD_YIELD           ;load yield flag addr
                      LDR        R1,   [R0]                        ;load yield flag val
                      TST        R1,   R1                          ;test val
                      BNE        $ML.EXIT                          ;jmp to label
                      LDR        R0,   =KER_TICK_S_CNT             ;load tick_s_cnt addr
                      LDR        R1,   [R0]                        ;load systick ss LSW val
                      ADDS       R1,   R1,  #1                     ;increment val
                      LDR        R2,   =1000                       ;compare with 1000ms
                      CMP        R1,   R2                          ;compare with val
                      BLO        $ML.SAVE_TICK                     ;no need to inc sec
                      LDR        R1,   =0x00000000                 ;clear counter
                      LDR        R2,   =KER_TICK_S                 ;load tick_s addr
                      LDR        R3,   [R2]                        ;load tick_s val
                      ADDS       R3,   R3,  #1                     ;increment val
                      STR        R3,   [R2]                        ;store tick_s val
$ML.SAVE_TICK
                      STR        R1,   [R0]                        ;store tick_s_cnt val
$ML.EXIT
                      MEND                                         ;macro end
;;==============================macro for seconds counter end================================;; 





;;========================macro for cpu usage calculation starting===========================;; 
                      MACRO                                        ;macro start
                      MACRO_CPU_USAGE  $ML                         ;macro name
                      LDR        R0,   =KER_THREAD_YIELD           ;load yield flag addr
                      LDR        R1,   [R0]                        ;load yield flag val
                      TST        R1,   R1                          ;test val
                      BNE        $ML.EXIT                          ;jmp to label
                      LDR        R0,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R1,   [R0]                        ;load thread_id
                      LDR        R2,   =KER_ACTV_TICK_CNT          ;load active_tick_cnt addr
                      LDR        R0,   [R2]                        ;load active_tick_cnt
                      TST        R1,   R1                          ;check val
                      BEQ        $ML.SKIP_INC                      ;if thread = idle thread, skip
                      ADDS       R0,   R0,  #1                     ;increment val
                      STR        R0,   [R2]                        ;store val, R0 active_tick_cnt
$ML.SKIP_INC                                                       ;label->no increment
                      LDR        R1,   =KER_TOTAL_TICK_CNT         ;load cmp_tick_cnt addr
                      LDR        R2,   [R1]                        ;load cmp_tick_cnt val
                      ADDS       R2,   R2,  #1                     ;increment val
                      LDR        R3,   =1000                       ;load compare val
                      CMP        R2,   R3                          ;compare values
                      BLO        $ML.SKIP_WRAP                     ;jmp to label
                      LDR        R3,   =KER_CPU_USAGE              ;load cpu_usage addr
                      STR        R0,   [R3]                        ;store
                      LDR        R3,   =KER_CPU_USAGE_AVG          ;IIR LPF, Alpha=0.5
                      LDR        R3,   [R3]                        ;load val
                      LSRS       R0,   R0, #1                      ;divide by 2
                      LSRS       R3,   R3, #1                      ;divide by 2
                      ADDS       R0,   R0, R3                      ;prev/2 + curr/2
                      LDR        R3,   =KER_CPU_USAGE_AVG          ;load addr
                      STR        R0,   [R3]                        ;store avarge val
                      MOVS       R2,   #0x00                       ;set val to 0
                      LDR        R0,   =KER_ACTV_TICK_CNT          ;load cmp_tick_cnt addr
                      STR        R2,   [R0]                        ;store
                      
$ML.SKIP_WRAP                                                      ;label->no wrapping
                      STR        R2,   [R1]                        ;store new val
$ML.EXIT                                                           ;label->exit
                      MEND                                         ;macro end
;;===========================macro for cpu usage calculation end=============================;; 





;;===========================macro for clear yield flag starting=============================;; 
                      MACRO                                        ;macro start
                      MACRO_CLEAR_YIELD_FLAG     $ML               ;macro name
                      LDR        R0,   =KER_THREAD_YIELD           ;load yield flag addr
                      MOVS       R1,   #0x00                       ;clear yield flag
                      STR        R1,   [R0]                        ;store val
$ML.EXIT
                      MEND                                         ;macro end
;;=============================macro for clear yield flag end================================;; 




;;===================================idle thread starting====================================;; 
Kernel_Thread_Idle
                      ;Idle thread, does nothing
                      B          .                                 ;forever loop
;;=====================================idle thread end=======================================;; 




;;===============================emit literal pool starting==================================;; 
                      ALIGN      4
                      LTORG
;;=================================emit literal pool end=====================================;; 




;;==================================kernel init starting=====================================;; 
Kernel_Init
                      PUSH       {LR}
                      
                      MACRO_GPIO_INIT         PLBL1                ;gpio init for debug
                      MACRO_SYS_VAR_INIT                           ;system variable init
                      MACRO_64MHZ_PLL_CONFIG  PLBL2                ;config pll if enabled
                      
                      ;set PendSV as lowest priority interrupt
                      LDR        R0,   =DEF_SCB_SHPR3              ;load SHPR3 addr
                      LDR        R1,   [R0]                        ;load SHPR3 val
                      LDR        R2,   =0xFF<<16                   ;set lowest priority
                      ORRS       R1,   R2                          ;set all bits
                      STR        R1,   [R0]                        ;store val
                      
                      LDR        R0,   =Kernel_Thread_Idle         ;load idle thread addr
                      MOVS       R1,   #0xFF                       ;lowest priority
                      BL         Kernel_Thread_Create              ;create idle thread
                      
                      POP        {PC}
;;====================================kernel init end========================================;; 




;;===============================emit literal pool starting==================================;; 
                      ALIGN      4
                      LTORG
;;=================================emit literal pool end=====================================;; 




;;=================================thread create starting====================================;; 
Kernel_Thread_Create
                      ;calculate stack top for this thread (R0:R1 are used by arguments)
                      LDR        R2,   =DEF_KER_STACK_SIZE         ;load each stack size
                      LDR        R3,   =KER_NTHREAD                ;load nthread addr
                      LDR        R3,   [R3]                        ;load nthread val
                      ADDS       R3,   R3, #1                      ;thread_id+1
                      MULS       R2,   R3, R2                      ;(thread_id+1)*size
                      LDR        R3,   =KER_THREAD_STACK           ;PSP start base
                      ADDS       R2,   R2, R3                      ;add offset
                      
                      ;create space for stack frame (R0:R1 arg, R2 stack top)
                      SUBS       R2,   #32                         ;space for R4-R11
                      SUBS       R2,   #32                         ;space for hardware frame
                      MOVS       R3,   #0x00                       ;clear reg
                      
                      ;create software stack (R0:R1 arg, R2 stack top, R3 for clearing)
                      STR        R3,   [R2, #0]                    ;R4
                      STR        R3,   [R2, #4]                    ;R5
                      STR        R3,   [R2, #8]                    ;R6
                      STR        R3,   [R2, #12]                   ;R7
                      STR        R3,   [R2, #16]                   ;R8
                      STR        R3,   [R2, #20]                   ;R9
                      STR        R3,   [R2, #24]                   ;R10
                      STR        R3,   [R2, #28]                   ;R11
                      
                      ;create hardware stack (R0:R1 arg, R2 stack top, R3 for clearing)
                      STR        R3,   [R2, #32]                   ;R0
                      STR        R3,   [R2, #36]                   ;R1
                      STR        R3,   [R2, #40]                   ;R2
                      STR        R3,   [R2, #44]                   ;R3
                      STR        R3,   [R2, #48]                   ;R12
                      STR        R3,   [R2, #52]                   ;LR
                      MOV        R3,   R0                          ;func addr
                      STR        R3,   [R2, #56]                   ;PC
                      LDR        R3,   =0x01000000                 ;thumb bit set
                      STR        R3,   [R2, #60]                   ;xPSR (Thumb)
                      
                      ;calculate offset(R1 arg, R2 stack top)
                      LDR        R0,   =KER_NTHREAD                ;load nthread addr
                      LDR        R0,   [R0]                        ;load nthread val
                      LSLS       R0,   R0, #2                      ;left shift to x4
                      
                      ;store PSP (R0 offset, R1 arg, R2 stack top)
                      LDR        R3,   =KER_THREAD_PSP             ;PSP base
                      ADDS       R3,   R3, R0                      ;PSP base+offset
                      STR        R2,   [R3]                        ;save PSP
                      
                      ;store priority (R0 offset, R1 arg)
                      LDR        R2,   =KER_THREAD_PRIO            ;priority base
                      ADDS       R2,   R2, R0                      ;priority base+offset
                      STR        R1,   [R2]                        ;save priority
                      
                      ;store sleep (R0 offset)
                      LDR        R1,   =KER_THREAD_SLEEP           ;sleep base
                      MOVS       R2,   #0x00                       ;set sleep duration 0
                      ADDS       R1,   R1, R0                      ;sleep base+offset
                      STR        R2,   [R1]                        ;save sleep duration
                      
                      ;store status (R0 offset)
                      LDR        R1,   =KER_THREAD_STS             ;priority base
                      LDR        R2,   =THREAD_STS_READY           ;set status ready
                      ADDS       R1,   R1, R0                      ;priority base+offset
                      STR        R2,   [R1]                        ;save priority
                      
                      ;increment nthread (R0 offset)
                      LDR        R0,   =KER_NTHREAD                ;load nthread addr
                      LDR        R1,   [R0]                        ;load nthread val
                      ADDS       R1,   R1, #1                      ;nthread+1
                      STR        R1,   [R0]                        ;save PSP
                      
                      BX         LR                                ;return
;;====================================thread create end======================================;; 




;;===============================emit literal pool starting==================================;; 
                      ALIGN      4
                      LTORG
;;=================================emit literal pool end=====================================;; 




;;=================================start threads starting====================================;; 
Kernel_Thread_Run_All
                      ;configure SysTick timer
                      MACRO_SYSTICK_CONFIG                         ;configure systick
                      MACRO_KER_INFO_INIT    DBG_INFO              ;init kernel info
                      ;calculate stack top for this thread
                      LDR        R0,   =DEF_KER_STACK_SIZE         ;load each stack size
                      LDR        R1,   =KER_THREAD_STACK           ;PSP start base
                      ADDS       R0,   R0, R1                      ;add offset
                      ;Setup PSP for main
                      MSR        PSP,  R0                          ;set PSP
                      MRS        R1,   CONTROL
                      MOVS       R2,   #0x02
                      ORRS       R1,   R1, R2                      ;CONTROL.SPSEL = 1
                      MSR        CONTROL, R1                       ;switch to PSP
                      ISB                                          ;instruction barrier
                      B          Kernel_Thread_Idle                ;call a thread
;;====================================start threads end======================================;; 




;;===============================emit literal pool starting==================================;; 
                      ALIGN      4
                      LTORG
;;=================================emit literal pool end=====================================;; 




;;=================================systick isr starting======================================;; 
SysTick_Handler
                      ;request for PendSV
                      LDR        R0,   =DEF_SCB_ICSR               ;load SCB->ICSR addr
                      LDR        R1,   =0x10000000                 ;load set_PendSV bit
                      STR        R1,   [R0]                        ;sote val
                      BX         LR                                ;return
;;====================================systick isr end========================================;; 




;;=============================pending service isr starting==================================;; 
PendSV_Handler
                      ;Hardware pushed (address wise, high->low) xPSR,PC,LR,R12,R3-R0
                      ;Software pushed (address wise, high->low) R11-R4
                      CPSID      I                                 ;disable interrupts
                      MACRO_GPIO_SET          ISRLBL1              ;debug pin set
                      MACRO_CONTEXT_SAVE                           ;save context
                      MACRO_KER_RUN_SCHEDULER ISRLBL2, ISRLBL3     ;run scheduler, local label
                      
                      MACRO_SS_CNT            ISRLBL4              ;sub-seconds counter
                      MACRO_S_CNT             ISRLBL5              ;seconds counter
                      MACRO_CPU_USAGE         ISRLBL6              ;calculate cpu usage
                      
                      MACRO_CLEAR_YIELD_FLAG  ISRLBL7              ;clear yield flag
                      MACRO_CONTEXT_RESTORE                        ;restore context
                      MACRO_GPIO_CLEAR        ISRLBL8              ;debug pin clear
                      CPSIE      I                                 ;enable interrupt
                      BX         LR                                ;return from interrupt
;;================================pending service isr end====================================;; 




;;===============================emit literal pool starting==================================;; 
                      ALIGN      4
                      LTORG
;;=================================emit literal pool end=====================================;; 




;;==============================kernel thread sleep starting=================================;; 
Kernel_Thread_Sleep
                      CPSID      I                                 ;disable interrupts
                      
                      ;find offset (R0 arg)
                      LDR        R1,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R1,   [R1]                        ;load thread_id val
                      LSLS       R1,   R1, #2                      ;left shift 2 times to x4
                      
                      ;set sleep val (R0 arg, R1 offset)
                      LDR        R2,   =KER_THREAD_SLEEP           ;load sleep base addr
                      ADDS       R2,   R2, R1                      ;add offset
                      STR        R0,   [R2]                        ;store sleep duration
                      
                      ;set status (R1 offset)
                      LDR        R2,   =KER_THREAD_STS             ;load status base addr
                      ADDS       R2,   R2, R1                      ;add offset
                      LDR        R1,   =THREAD_STS_BLOCKED         ;set status blocked
                      STR        R1,   [R2]                        ;store status
                      
                      ;set thread yield flag
                      LDR        R0,   =KER_THREAD_YIELD           ;load nthread addr
                      MOVS       R1,   #0x01                       ;set flag
                      STR        R1,   [R0]                        ;store val
                      
                      LDR        R0,   =DEF_SCB_ICSR               ;load SCB->ICSR addr
                      LDR        R1,   =0x10000000                 ;load set_PendSV bit
                      STR        R1,   [R0]                        ;sote val
                      DSB                                          ;data sync barier
                      ISB                                          ;instruction sync barier
                      
                      CPSIE      I                                 ;enable interrupt
                      BX         LR                                ;return
;;=================================kernel thread sleep end===================================;; 




;;==========================kernel tick 32bit SS val get starting============================;; 
Kernel_Tick_SS32_Get
                      LDR        R0,   =KER_TICK_SS                ;load sub-seconds addr
                      LDR        R0,   [R0]                        ;load sub-seconds val
                      BX         LR                                ;return
;;============================kernel tick 32bit SS val get end===============================;; 




;;==========================kernel tick 64bit SS val get starting============================;;   
Kernel_Tick_SS64_Get
                      CPSID      I                                 ;disable interrupts
                      LDR        R0,   =KER_TICK_SS                ;load sub-seconds addr
                      LDR        R1,   [R0, #4]                    ;load HW sub-seconds val
                      LDR        R0,   [R0]                        ;load LW sub-seconds val
                      CPSIE      I                                 ;enable interrupt
                      BX         LR                                ;return
;;============================kernel tick 64bit SS val get end===============================;; 




;;==========================kernel tick seconds val get starting=============================;; 
Kernel_Tick_S_Get
                      LDR        R0,   =KER_TICK_S                 ;load seconds addr
                      LDR        R0,   [R0]                        ;load seconds val
                      BX         LR                                ;return
;;============================kernel tick seconds val get end================================;; 




;;==============================kernel timeout set starting==================================;; 
Kernel_Timeout_Set
                      PUSH       {LR}
                      MOV        R3,   R0                          ;copy reg
                      LDR        R0,   =KER_THREAD_TOUT            ;load timeout addr
                      LDR        R1,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R1,   [R1]                        ;load thread_id val
                      LSLS       R1,   R1, #3                      ;multiply by 8
                      ADDS       R2,   R0, R1                      ;offset addr of timeout
                      BL         Kernel_Tick_SS64_Get              ;get 64bit timestamp
                      ADDS       R0,   R0, R3                      ;low word + timeout
                      MOVS       R3,   #0x00                       ;load 0x00
                      ADCS       R1,   R1, R3                      ;add carry with high word 
                      STR        R0,   [R2]                        ;store low word
                      STR        R1,   [R2, #4]                    ;store high word
                      POP        {PC}                              ;return
;;=================================kernel timeout set end====================================;; 




;;===============================emit literal pool starting==================================;; 
                      ALIGN      4
                      LTORG
;;=================================emit literal pool end=====================================;; 




;;==============================kernel timeout set starting==================================;; 
Kernel_Timeout_Status 
                      PUSH       {LR}                              ;save return addr
                      LDR        R0,   =KER_THREAD_TOUT            ;load timeout addr
                      LDR        R1,   =KER_THREAD_ID              ;load thread_id addr
                      LDR        R1,   [R1]                        ;load thread_id val
                      LSLS       R1,   R1, #3                      ;multiply by 8
                      ADDS       R2,   R0, R1                      ;offset addr of timeout
                      LDR        R3,   [R2, #4]                    ;load high word
                      LDR        R2,   [R2]                        ;load low word
                      BL         Kernel_Tick_SS64_Get              ;get 64bit timestamp
                      CMP        R1,   R3                          ;compare high words
                      BHI        KER_IS_TOUT_TRUE                  ;jump to true
                      BLO        KER_IS_TOUT_FALSE                 ;jump to false
                      CMP        R0,   R2                          ;compare low words
                      BHI        KER_IS_TOUT_TRUE                  ;jump to true
KER_IS_TOUT_FALSE
                      MOVS       R0,   #0x00                       ;load 0
                      B          KER_IS_TOUT_EXIT                  ;jump to exit
KER_IS_TOUT_TRUE
                      MOVS       R0,   #0x01                       ;load 0
KER_IS_TOUT_EXIT
                      POP        {PC}                              ;return
;;=================================kernel timeout set end====================================;; 




;;==============================kernel cpu usage get starting================================;; 
Kernel_CPU_Usage_x10_Get
                      LDR        R0,   =KER_CPU_USAGE              ;load cpu_usage addr
                      LDR        R0,   [R0]                        ;load cpu_usage val
                      BX         LR                                ;return
;;=================================kernel cpu usage get end==================================;; 




;;==========================kernel cpu usage average get starting============================;; 
Kernel_CPU_Usage_Avg_x10_Get
                      LDR        R0,   =KER_CPU_USAGE_AVG          ;load cpu_usage_avg addr
                      LDR        R0,   [R0]                        ;load cpu_usage_avg val
                      BX         LR                                ;return
;;============================kernel cpu usage average get end===============================;; 





;;============================kernel version major get starting==============================;; 
Kernel_Version_Major_Get
                      MOVS       R0,   #DEF_KERNEL_VER_MAJOR       ;load kernel ver major val
                      BX         LR                                ;return
;;==============================kernel version major get end=================================;; 





;;============================kernel version minor get starting==============================;; 
Kernel_Version_Minor_Get
                      MOVS       R0,   #DEF_KERNEL_VER_MINOR       ;load kernel ver minor val
                      BX         LR                                ;return
;;==============================kernel version minor get end=================================;; 





;;============================kernel version patch get starting==============================;; 
Kernel_Version_Patch_Get
                      MOVS       R0,   #DEF_KERNEL_VER_PATCH       ;load kernel ver patch val
                      BX         LR                                ;return
;;==============================kernel version patch get end=================================;; 





;;============================kernel version patch get starting==============================;; 
Kernel_Info_Char_Get
                      LDR        R1,   =KER_INFO_BLOCK             ;load pointer addr
                      LDRB       R0,   [R1, R0]                    ;load byte with offset
                      BX         LR                                ;return
;;==============================kernel version patch get end=================================;; 




;;===============================kernel print info starting==================================;; 
Kernel_Print_Info
                      PUSH       {R4, R5,  LR}                     ;save return addr
                      MOVS       R4,   R0                          ;copy function pointer
                      MOVS       R5,   #0                          ;set loop cnt 0
KER_PRINT_CHAR        
                      MOVS       R0,   R5                          ;copy
                      BL         Kernel_Info_Char_Get              ;get char
                      TST        R0,   R0                          ;check if 0
                      BEQ        KER_PRINT_EXIT                    ;exit from func
                      BLX        R4                                ;jmp to func ptr
                      ADDS       R5,   R5, #1                      ;increment
                      BL         KER_PRINT_CHAR                    ;jmp to label
KER_PRINT_EXIT
                      POP        {R4, R5, PC}                      ;return
;;=================================kernel print info end=====================================;;  





;;====================================kernel file end========================================;; 
                      ALIGN      4
                      END                                          ;end of file
;;====================================kernel file end========================================;; 






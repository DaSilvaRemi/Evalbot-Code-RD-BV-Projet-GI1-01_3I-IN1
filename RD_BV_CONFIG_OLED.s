;(p803 datasheet de lm3s9b92.pdf)
;; RD BV - Evalbot (Cortex M3 de Texas Instrument);
; Configure and display content on OLED

;----------------------------------------SYSTEM VAR-----------------------;

SYSCTL_RCGC1_R  EQU 0X400FE104 ; SYSCTL_RCGC1_R (p283 datasheet de lm3s9b92.pdf)

; This register controls the clock gating logic in normal Run mode
SYSCTL_RCGC2_R	EQU	0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)
	
;----------------------------------------GPIO VAR-----------------------;

GPIO_PORT_G_BASE EQU 0x40026000
	
GPIO_AFSEL EQU 0X420 ;GPIO Alternate Function Select (p426 datasheet de lm3s9b92.pdf)
	
GPIO_O_DR EQU 0X50C ;GPIO Open Drain Select (p431 datasheet de lm3s9b92.pdf)
	
GPIO_0_PCTL EQU 0X52C ;GPIO Port Control (p426 datasheet de lm3s9b92.pdf)
	
;----------------------------------------I2C VAR-----------------------;
	
I2C_1 EQU 0x40021000	;(p818 datasheet de lm3s9b92.pdf)
	
I2C_M_CR EQU 0x020 ;I2C Master Configuration (p818 datasheet de lm3s9b92.pdf)
	
I2C_M_TPR EQU 0x00C ;I2C Master Timer Period (p813 datasheet de lm3s9b92.pdf)
	
I2C_M_SA EQU 0x000 ;I2C Master Slave Adress (p806 datasheet de lm3s9b92.pdf)
	
I2C_M_DR EQU 0x008 ;I2C Master Data (p812 datasheet de lm3s9b92.pdf)
	
I2C_M_CS EQU 0x004 ;I2C Master Control/Status (p807 datasheet de lm3s9b92.pdf)

;----------------------------------------PINS-----------------------;
BROCHE_G_0_1 EQU 0X03
	
										AREA    _CONFIG_OLED_, CODE, READONLY
										ENTRY

										EXPORT __CONFIG_0LED
										EXPORT __DISPLAY_BYTE_DATA

;----------------------------------------START OLED CONFIGURATION------------------------------------------------;
__CONFIG_0LED
										; ;; Enable the I2C peripheral clock 		(p279 datasheet de lm3s9B96.pdf)
										LDR R6, =SYSCTL_RCGC1_R  			;; RCGC1
										LDR R0, [R6]
										ORR R0, R0, #0x00000010  			;; Enable I2C CLock
										STR R0, [R6]
								
										; ;; Enable the Port G peripheral clock 	(p1261 & 291 datasheet de lm3s9B96.pdf)
										LDR R6, =SYSCTL_RCGC2_R  			;; RCGC2
										LDR R0, [R6]
										ORR R0, R0, #0x60  			;; Enable clock on GPIO G (0x40 == 0b0100 0000) where OLED were connected on (0x03 == 0b0000 0011)
										; ;;														(GPIO::HGFE DCBA)					
										STR R0, [R6]

										; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
										NOP
										NOP
										NOP
								
										;Follow (p803 datasheet de lm3s9B92.pdf) for make this configuration
										;----------------------------------------GPIO CONFIGURATION-----------------------;
																		
										;Alternate Function Select (AFSEL) (p 426), PE2 et PE3 use QEI so Alternate funct
										;;so PE2 et PE3 = 1
										LDR R6, = GPIO_PORT_G_BASE+GPIO_AFSEL
										ORR R0, R6, #0x03
										STR R0, [R6]
										
										LDR R6, =0x00

										;;GPIO Open Drain Select (GPIOODR) (p431)
										LDR R6, =GPIO_PORT_G_BASE+GPIO_O_DR    ;; Enable the I2C pins for open-drain operation
										LDR R0, =0x01
										STR R0, [R6]

										;;GPIO Port Control (GPIOPCTL) (p444)
										LDR R6, =GPIO_PORT_G_BASE+GPIO_0_PCTL	;; Configure PORT
										LDR R0, =0x03 ;Switch on I2C on Port G0 & G1 with put 1 on the third bit
										STR R0, [R6]
								
										;----------------------------------------I2C CONFIGURATION-----------------------;
								
										LDR R6, =I2C_1+I2C_M_CR	;; Initialize the I2C master
										LDR R0, =0x00000010
										STR R0, [R6]

										LDR R6, =I2C_1+I2C_M_TPR ;; Set the number of system clock periods in one SCL clock period 
										LDR R0, =0x00000009
										STR R0, [R6]
								
										LDR R6, =I2C_1+I2C_M_SA ;; Set the number of system clock periods in one SCL clock period 
										LDR R0, =0x00000076
										STR R0, [R6]

										BX LR
;----------------------------------------END OLED CONFIGURATION------------------------------------------------;

;----------------------------------------START DISPLAY BYTE DATA CONFIGURATION------------------------------------------------;

__DISPLAY_BYTE_DATA						
										LDR R6, =I2C_0+I2C_M_CR ;;Prepare data to be transmitted
										STR R2, [R6]
								
										LDR R6, =I2C_0+I2C_M_CS ;;Initiate a single byte transmit of data from Master to Slave
										LDR R0, =0X00000007
										STR R2, [R6]
										
start_while_transmission_is_not_clear	
										;Check if I2C are finished to transmit
										LDR R0, =2_00100000 
										MOV R1, R6
										AND R0, R1
								
										CMP R0, #1 ;If the bus it's busy we return to the start
										BEQ start_while_transmission_is_not_clear
end_while_transmission_is_not_clear		

										LDR R0, =2_00000010 
										MOV R1, R6
										AND R0, R1
										
										CMP R0, #0 ;Check if the bus doesn't throw error
										
										BX LR
;----------------------------------------END DISPLAY BYTE DATA CONFIGURATION------------------------------------------------;

										END
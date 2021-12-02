	;; RD BV - Evalbot (Cortex M3 de Texas Instrument);
;; Program to manage config of the SWITCHs

; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO 		EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet in lm3s9b92.pdf)

; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  			EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet in lm3s9B92.pdf)

; Pull_up
GPIO_I_PUR   			EQU 	0x00000510  ; GPIO Pull-Up Select  (p432 datasheet in lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORT_D_BASE		EQU		0x40007000	; GPIO Port D (APB) base: 0x4002.7000 (p416 datasheet in lm3s9B92.pdf)

BROCHE_D_6				EQU 	0x40		; SW1

BROCHE_D_7				EQU 	0x80		; SW2

BROCHE_D_6_7			EQU 	0xC0		; SW1_2


									AREA    _CONFIG_SWITCH_, CODE, READONLY
									ENTRY

									EXPORT __CONFIG_SW
									EXPORT __READ_STATE_SW_1
									EXPORT __READ_STATE_SW_2

;----------------------------------------START SWITCH CONFIGURATION------------------------------------------------;
__CONFIG_SW
									; ;; Enable the Port D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
									; ;;
									LDR R6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
									LDR R0, [R6]
									ORR R0, R0, #0x08	;; Enable clock on GPIO D (0x08 == 0b0000 1000) where SWITCH were connected on (0xC0 == 0b1100 0000)
									; ;;										   (GPIO::HGFE DCBA)
									STR R0, [R6]

									; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet in lm3s9B92.pdf)
									NOP
									NOP
									NOP

									LDR R6, = GPIO_PORT_D_BASE + GPIO_I_PUR	;; Pull_up
									LDR R0, = BROCHE_D_6_7
									STR R0, [R6]

									LDR R6, = GPIO_PORT_D_BASE + GPIO_O_DEN	;; Enable Digital Function
									LDR R0, [R6]
									ORR R0, R0, #BROCHE_D_6_7
									STR R0, [R6]
									

									BX LR

;----------------------------------------END SWITCH CONFIGURATION------------------------------------------------;

;----------------------------------------READ STATE OF SW1------------------------------------------------;
__READ_STATE_SW_1
									PUSH { R10, R11, LR }
									
									LDR R11, = GPIO_PORT_D_BASE + (BROCHE_D_6<<2)  ;; @data Register = @base + (mask<<2) ==> SW1
									LDR R10, [R11]
									CMP R10, #0x00
									
									POP { R10, R11, PC }

;----------------------------------------READ STATE OF SW2------------------------------------------------;
__READ_STATE_SW_2
									PUSH { R10, R12, LR }
									
									LDR R12, = GPIO_PORT_D_BASE + (BROCHE_D_7<<2)  ;; @data Register = @base + (mask<<2) ==> SW2
									LDR R10, [R12]
									CMP R10, #0x00
									
									POP { R10, R12, PC }

									END

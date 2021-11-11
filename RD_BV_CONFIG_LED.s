; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO 		EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORT_F_BASE			EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   					EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   				EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  					EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE_F_4						EQU		0x10		; led1 on broche 4

BROCHE_F_5						EQU		0x20		; led2 on broche  5

BROCHE_F_4_5					EQU		0x30		; led1 & led2 on broche 4 & 5

SHUTDOWN_MASK_LED_1	 	EQU 0xEF ;Mask to shutdown LED 1 (0b11101111)

SHUTDOWN_MASK_LED_2		EQU 0xDF ;Mask to shutdown LED 2 (0b11011111)

SHUTDOWN_MASK_LED_1_2	EQU 0xCF ;Mask to shutdown LED 2 (0b11001111)

											AREA    _CONFIG_LED_, CODE, READONLY
	  									ENTRY

											EXPORT __CONFIG_LED
											EXPORT __SWITCH_ON_LED_1
											EXPORT __SWITCH_ON_LED_2
											EXPORT __SWITCH_ON_LED_1_2
											EXPORT __SWITCH_OFF_LED_1
											EXPORT __SWITCH_OFF_LED_2
											EXPORT __SWITCH_OFF_LED_1_2
											EXPORT __BLINK_LED_1_2

;----------------------------------------START LED CONFIGURATION------------------------------------------------;
__CONFIG_LED
													; ;; Enable the Port F & E peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
													LDR R6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
													LDR R0, [R6]
													ORR R0, R0, #0x00000020  				;; Enable clock sur GPIO F o� sont branch�s les leds (0x20 == 0b0010 0000)
													; ;;														 							(GPIO::HGFE DCBA)
													STR R0, [R6]

													; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
													NOP
													NOP
													NOP

													LDR R6, = GPIO_PORT_F_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 et 5 : 00110000)
													LDR R0, = BROCHE_F_4_5
													STR R0, [R6]

													LDR R6, = GPIO_PORT_F_BASE+GPIO_O_DEN	;; Enable Digital Function
													LDR R0, = BROCHE_F_4_5
													STR R0, [R6]

													LDR R6, = GPIO_PORT_F_BASE+GPIO_O_DR2R	;; Choix de l'intensit� de sortie (2mA)
													LDR R0, = BROCHE_F_4_5
													STR R0, [R6]

													LDR R4, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1

													BX LR
;----------------------------------------END LED CONFIGURATION------------------------------------------------;

;----------------------------------------SET VALUE OF R4 REGISTER WHERE LED WAS CONFIGURED------------------------------------------------;
__SET_VAL_DATA_REGISTER
													AND R2, R4
													STR R2, [R4]
													BX LR

;----------------------------------------SWITCH ON LED 1------------------------------------------------;
__SWITCH_ON_LED_1
													PUSH {R2-R4, LR}
													MOV R2, #BROCHE_F_4		;; SWITCH ON LED portF broche 4 : 0b00010000
													BL __SET_VAL_DATA_REGISTER
													POP {R2-R4, PC}

;----------------------------------------SWITCH ON LED 2------------------------------------------------;
__SWITCH_ON_LED_2
													PUSH {R2-R4, LR}
													MOV R2, #BROCHE_F_5		;; SWITCH ON portF broche 5 : 0b00100000
													BL __SET_VAL_DATA_REGISTER
													POP {R2-R4, PC}

;----------------------------------------SWITCH ON LED 1 & 2------------------------------------------------;
__SWITCH_ON_LED_1_2
													PUSH {R2-R4, LR}
													MOV R2, #BROCHE_F_4_5		;; SWITCH ON portF broche 4 & 5 : 0b00110000
													BL __SET_VAL_DATA_REGISTER
													POP {R2-R4, PC}

;----------------------------------------SWITCH OFF LED 1------------------------------------------------;
__SWITCH_OFF_LED_1
													PUSH {R2-R4, LR}
													MOV R2, #SHUTDOWN_MASK_LED_1 ;; SWITCH OFF LED portF broche 4 : 0b00010000
													BL __SET_VAL_DATA_REGISTER
													POP {R2-R4, PC}

;----------------------------------------SWITCH OFF LED 2------------------------------------------------;
__SWITCH_OFF_LED_2
													PUSH {R2-R4, LR}
													MOV R2, #SHUTDOWN_MASK_LED_2 ;; SWITCH OFF LED portF broche 5 : 0b00100000
													BL __SET_VAL_DATA_REGISTER
													POP {R2-R4, PC}

;----------------------------------------SWITCH OFF LED 1 & é------------------------------------------------;
__SWITCH_OFF_LED_1_2
													PUSH {R2-R4, LR}
													MOV R2, #SHUTDOWN_MASK_LED_1_2 ;; SWITCH OFF LED portF broche 4 & 5 : 0b00110000
													BL __SET_VAL_DATA_REGISTER
													POP {R2-R4, PC}


;----------------------------------------BLINK LED 1 & 2------------------------------------------------;
__BLINK_LED_1_2
													PUSH {R1-R4 LR}
													BL __SWITCH_ON_LED_1_2
													BL __SWITCH_OFF_LED_1_2
													BL __WAITING_BETWEEN_BLINKY
													BL __SWITCH_ON_LED_1_2
													BL __WAITING_BETWEEN_BLINKY
													BL SWITCH_OFF_LED
													PUSH {R1-R4 LR}

__WAITING_BETWEEN_BLINKY
													LDR R1, =0x002FFFFF						;; Waiting Time

while											SUBS R1, #1
													BNE while
													BX LR ;return to caller

													END

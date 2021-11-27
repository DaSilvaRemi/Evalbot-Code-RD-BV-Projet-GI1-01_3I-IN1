	;; RD BV - Evalbot (Cortex M3 de Texas Instrument);
;; Program to manage config of the LED

; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO 		EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet in lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORT_F_BASE			EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet in lm3s9B92.pdf)

; Configure the corresponding pin to be an output
GPIO_O_DIR   					EQU 	0x00000400  ; GPIO Direction (p417 datasheet in lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   				EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet in lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  					EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet in lm3s9B92.pdf)

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

								IMPORT __WAIT

;----------------------------------------START LED CONFIGURATION------------------------------------------------;
;;;
;;Config the clock and GPIO for the LED
;;;
__CONFIG_LED
								;; Enable the Port F & E peripheral clock 		(p291 datasheet in lm3s9B96.pdf)
								LDR R6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
								LDR R0, [R6]
								ORR R0, R0, #0x00000020  				;; Enable clock on GPIO F (0x20 == 0b0010 0000) where LED were connected on (0x30 == 0b0011 0000)
								;;														 		  (GPIO::HGFE DCBA)
								STR R0, [R6]

								;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
								NOP
								NOP
								NOP

								LDR R6, = GPIO_PORT_F_BASE+GPIO_O_DIR    ;; 2 Output Pins of F port (broche 4 and 5 : 00110000)
								LDR R0, = BROCHE_F_4_5
								STR R0, [R6]

								LDR R6, = GPIO_PORT_F_BASE+GPIO_O_DEN	;; Enable Digital Function
								LDR R0, = BROCHE_F_4_5
								STR R0, [R6]

								LDR R6, = GPIO_PORT_F_BASE+GPIO_O_DR2R	;; Choose output intensity (2mA)
								LDR R0, = BROCHE_F_4_5
								STR R0, [R6]

								BX LR
;----------------------------------------END LED CONFIGURATION------------------------------------------------;

;----------------------------------------START LED REGISTER CONFIGURATION------------------------------------------------;
;;;
;;Config the LED register by loading @data Register in R4
;;;
__CONFIG_LED_REGISTER
								LDR R4, = GPIO_PORT_F_BASE + (BROCHE_F_4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
								BX LR
;----------------------------------------END LED REGISTER CONFIGURATION------------------------------------------------;


;----------------------------------------SET VALUE OF R4 REGISTER WHERE LED WAS CONFIGURED WITH AND OPERATOR------------------------------------------------;
;;;
;;Config the LED register by loading @data Register in R4 with AND operator
;;;
__SET_VAL_DATA_REGISTER_AND
								PUSH {R2, R4, LR}
								
								BL __CONFIG_LED_REGISTER
								AND R2, R4
								BL __SET_VAL_DATA_REGISTER
								
								POP {R2, R4, PC}
								
;----------------------------------------SET VALUE OF R4 REGISTER WHERE LED WAS CONFIGURED WITH ORR OPERATOR------------------------------------------------;
;;;
;;Config the LED register by loading @data Register in R4 with OR operator
;;;
__SET_VAL_DATA_REGISTER_ORR
								PUSH {R2, R4, LR}
								BL __CONFIG_LED_REGISTER
								ORR R2, R4
								BL __SET_VAL_DATA_REGISTER
								
								POP {R2, R4, PC}
								
;----------------------------------SET VALUE OF R4 REGISTER WHERE LED WAS CONFIGURED---------------------;
;;;
;;Config the LED register by loading @data Register in R4
;;;
__SET_VAL_DATA_REGISTER
								STR R2, [R4] ;LOAD value of R2, in R4 the register of the MED
								BX LR

;----------------------------------------SWITCH ON LED 1-------------------------------------------------;
__SWITCH_ON_LED_1
								PUSH {R2, R4, LR}
								MOV R2, #BROCHE_F_4		;; SWITCH ON LED portF broche 4 : 0b00010000
								BL __SET_VAL_DATA_REGISTER_ORR
								POP {R2, R4, PC}

;----------------------------------------SWITCH ON LED 2-------------------------------------------------;
__SWITCH_ON_LED_2
								PUSH {R2, R4, LR}
								MOV R2, #BROCHE_F_5		;; SWITCH ON portF broche 5 : 0b00100000
								BL __SET_VAL_DATA_REGISTER_ORR
								POP {R2, R4, PC}

;----------------------------------------SWITCH ON LED 1 & 2---------------------------------------------;
__SWITCH_ON_LED_1_2
								PUSH {R2, R4, LR}
								MOV R2, #BROCHE_F_4_5		;; SWITCH ON portF broche 4 & 5 : 0b00110000
								BL __SET_VAL_DATA_REGISTER_ORR
								POP {R2, R4, PC}

;----------------------------------------SWITCH OFF LED 1------------------------------------------------;
__SWITCH_OFF_LED_1
								PUSH {R2, R4, LR}
								MOV R2, #SHUTDOWN_MASK_LED_1 ;; SWITCH OFF LED portF broche 4 : 0b00010000
								BL __SET_VAL_DATA_REGISTER_AND
								POP {R2, R4, PC}

;----------------------------------------SWITCH OFF LED 2------------------------------------------------;
__SWITCH_OFF_LED_2
								PUSH {R2, R4, LR}
								MOV R2, #SHUTDOWN_MASK_LED_2 ;; SWITCH OFF LED portF broche 5 : 0b00100000
								BL __SET_VAL_DATA_REGISTER_AND
								POP {R2, R4, PC}

;----------------------------------------SWITCH OFF LED 1 & é--------------------------------------------;
__SWITCH_OFF_LED_1_2
								PUSH {R2, R4, LR}
								MOV R2, #SHUTDOWN_MASK_LED_1_2 ;; SWITCH OFF LED portF broche 4 & 5 : 0b00110000
								BL __SET_VAL_DATA_REGISTER_AND
								POP {R2, R4, PC}


;----------------------------------------BLINK LED 1 & 2-------------------------------------------------;
__BLINK_LED_1_2
								;SWITCH ON OFF LED - WAIT - SWITCH ON LED - WAIT - SWITCH OFF LED
								PUSH {R1, R2, R4, LR}
								BL __WAIT
								BL __SWITCH_ON_LED_1_2
								BL __WAIT
								BL __WAIT
								BL __SWITCH_OFF_LED_1_2
								BL __WAIT
								POP {R1, R2, R4, PC}

								END
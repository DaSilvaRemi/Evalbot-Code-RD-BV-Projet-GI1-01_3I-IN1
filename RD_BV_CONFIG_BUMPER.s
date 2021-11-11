; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO 		EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   			EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  			EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   			EQU 	0x00000510  ; GPIO Digital Enable (p432 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORT_E_BASE		EQU		0x40024000	; GPIO Port E (APB) base: 0x4002.4000 (p416 datasheet de lm3s9B92.pdf)

BROCHE_E_1				EQU 	0x02		; Bumper Left

BROCHE_E_0				EQU 	0x01		; Bumper Right

BROCHE_E_0_1			EQU 	0x03		; Bumper Right/Right


											AREA    _CONFIG_BUMPER_, CODE, READONLY
											ENTRY

											EXPORT __CONFIG_BUMPER
											EXPORT __READ_STATE_BUMPER_1
											EXPORT __READ_STATE_BUMPER_2

;----------------------------------------START BUMPER CONFIGURATION------------------------------------------------;
__CONFIG_BUMPER
											; ;; Enable the Port E peripheral clock 	(p291 datasheet de lm3s9B96.pdf)
											; ;;
											LDR R6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
											LDR R0, [R6]
											ORR R0, R0, #0x00000010  				;; Enable clock on GPIO E (0x08 == 0b0001 0000) where BUMPER were connected on (0x03 == 0b0000 0011)
											; ;;														 									        (GPIO::HGFE DCBA)
											STR R0, [R6]

											; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
											NOP
											NOP
											NOP

											LDR R6, = GPIO_PORT_E_BASE+GPIO_I_PUR	;; PULL_UP
											LDR R0, = BROCHE_E_0_1
											STR R0, [R6]

											LDR R6, = GPIO_PORT_E_BASE+GPIO_O_DEN	;; ENABLE DIGITAL FUNCTION
											LDR R0, = BROCHE_E_0_1
											STR R0, [R6]

											LDR R7, = GPIO_PORT_E_BASE + (BROCHE_E_1<<2)  ;; @data Register = @base + (mask<<2) ==> Bumper Left
											LDR R8, = GPIO_PORT_E_BASE + (BROCHE_E_0<<2)  ;; @data Register = @base + (mask<<2) ==> Bumper Right

											BX LR

;----------------------------------------END BUMPER CONFIGURATION------------------------------------------------;

;----------------------------------------READ STATE OF BUMPER LEFT------------------------------------------------;
__READ_STATE_BUMPER_1
											LDR R10,[R7]
											CMP R10,#0x00
											BX LR

;----------------------------------------READ STATE OF BUMPER RIGHT------------------------------------------------;
__READ_STATE_BUMPER_2
											LDR R10,[R8]
											CMP R10,#0x00
											BX LR

											END
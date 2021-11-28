	;; RD BV - Evalbot (Cortex M3 de Texas Instrument);
; Control 2 ENGINES of Evalbot by PWM all in ASM (configure the pwms + GPIO)
;Code are based of code of Mr Kachouri Rostrom

;Connection :
;pin 10/PD0/PWM0 => input PWM bridge in H DRV8801RT
;pin 11/PD1/PWM1 => input Phase_R  bridge in H DRV8801RT
;pin 12/PD2		 => input SlowDecay common of 2 bridge in H
;pin 98/PD5		 => input Enable 12v du conv DC/DC
;pin 86/PH0/PWM2 => input PWM of 2nd bridge in H
;pin 85/PH1/PWM3 => input Phase of 2nd bridge in H

;; Hexa corresponding values to pin numbers
GPIO_0		EQU		0x1
GPIO_1		EQU		0x2
GPIO_2		EQU		0x4
GPIO_3		EQU		0x08
GPIO_5		EQU		0x20
GPIO_6		EQU		0x40
GPIO_7		EQU		0x80

;; pour enable clock    0x400FE000
SYSCTL_RCGC0	EQU		0x400FE100		;SYSCTL_RCGC0: offset 0x100 (p271 datasheet de lm3s9b92.pdf)
SYSCTL_RCGC2	EQU		0x400FE108		;SYSCTL_RCGC2: offset 0x108 (p291 datasheet de lm3s9b92.pdf)

;; General-Purpose Input/Outputs (GPIO) configuration
PORTD_BASE			EQU		0x40007000
GPIODATA_D			EQU		PORTD_BASE
GPIODIR_D			EQU		PORTD_BASE+0x00000400
GPIODR2R_D			EQU		PORTD_BASE+0x00000500
GPIODEN_D			EQU		PORTD_BASE+0x0000051C
GPIOPCTL_D			EQU		PORTD_BASE+0x0000052C ; GPIO Port Control (GPIOPCTL), offset 0x52C; p444
GPIOAFSEL_D			EQU		PORTD_BASE+0x00000420 ; GPIO Alternate Function Select (GPIOAFSEL), offset 0x420; p426

PORTH_BASE			EQU		0x40027000
GPIODATA_H			EQU		PORTH_BASE
GPIODIR_H			EQU		PORTH_BASE+0x00000400
GPIODR2R_H			EQU		PORTH_BASE+0x00000500
GPIODEN_H			EQU		PORTH_BASE+0x0000051C
GPIOPCTL_H			EQU		PORTH_BASE+0x0000052C ; GPIO Port Control (GPIOPCTL), offset 0x52C; p444
GPIOAFSEL_H			EQU		PORTH_BASE+0x00000420 ; GPIO Alternate Function Select (GPIOAFSEL), offset 0x420; p426

;; Pulse Width Modulator (PWM) configuration
PWM_BASE			EQU		0x040028000 	   ;BASE des Block PWM p.1138
PWMENABLE			EQU		PWM_BASE+0x008	   ; p1145

;Block PWM0 pour outputs PWM0 et PWM1 (ENGINE 1)
PWM0CTL				EQU		PWM_BASE+0x040 ;p1167
PWM0LOAD			EQU		PWM_BASE+0x050
PWM0CMPA			EQU		PWM_BASE+0x058
PWM0CMPB			EQU		PWM_BASE+0x05C
PWM0GENA			EQU		PWM_BASE+0x060
PWM0GENB			EQU		PWM_BASE+0x064

;Block PWM1 pour outputs PWM1 et PWM2 (ENGINE 2)
PWM1CTL				EQU		PWM_BASE+0x080
PWM1LOAD			EQU		PWM_BASE+0x090
PWM1CMPA			EQU		PWM_BASE+0x098
PWM1CMPB			EQU		PWM_BASE+0x09C
PWM1GENA			EQU		PWM_BASE+0x0A0
PWM1GENB			EQU		PWM_BASE+0x0A4

;0x1A2
VITESSE				EQU		0x100	
								; Smaller Values => Faster speed exemple 0x192
								; Bigger Value => Lower speed exemple 0x1B2


									AREA    _CONFIG_ENGINE_, CODE, READONLY
									ENTRY

									;; The EXPORT command specifies that a symbol can be accessed by other shared objects or executables.
									EXPORT	__ENGINE_INIT
									EXPORT	__ENGINE_RIGHT_ON
									EXPORT  __ENGINE_RIGHT_OFF
									EXPORT  __ENGINE_RIGHT_FRONT
									EXPORT  __ENGINE_RIGHT_BACK
									EXPORT  __ENGINE_RIGHT_INVERSE
									EXPORT	__ENGINE_LEFT_ON
									EXPORT  __ENGINE_LEFT_OFF
									EXPORT  __ENGINE_LEFT_FRONT
									EXPORT  __ENGINE_LEFT_BACK
									EXPORT  __ENGINE_LEFT_INVERSE
									EXPORT __ENGINE_LEFT_RIGHT_ON
									EXPORT __ENGINE_LEFT_RIGHT_OFF
									EXPORT __ENGINE_LEFT_RIGHT_FRONT
									EXPORT __ENGINE_LEFT_RIGHT_BACK
									EXPORT __ENGINE_LEFT_BACK_RIGHT_FRONT
									EXPORT __ENGINE_LEFT_FRONT_RIGHT_BACK
									EXPORT __ENGINE_LEFT_RIGHT_INVERSE


__ENGINE_INIT
									;CONFIGURE CLOCK RCGC0
									LDR R6, = SYSCTL_RCGC0
									LDR	R0, [R6]
									ORR	R0, R0, #0x00100000  ;;bit 20 = PWM recoit clock: ON (p271)
									STR R0, [R6]

									;ROM_SysCtlPWMClockSet(SYSCTL_PWMDIV_1);PWM clock is processor clock /1
									;Do nothing by default = OK!!
									;*(int *) (0x400FE060)= *(int *)(0x4
									;RCGC2 :  Enable port D GPIO(p291 ) because ENGINE RIGHT in port D
									LDR R6, = SYSCTL_RCGC2
									LDR	R0, [R6]
									ORR	R0, R0, #0x08  ;; Enable port D GPIO
									STR R0, [R6]

									;MOT2 : RCGC2 :  Enable port H GPIO  (2eme ENGINEs)
									LDR R6, = SYSCTL_RCGC2
									LDR	R0, [R6]
									ORR	R0, R0, #0x80  ;; Enable port H GPIO
									STR R0, [R6]

									NOP
									NOP
									NOP

									;;Pin muxing for PWM, port D, reg. GPIOPCTL(p444), 4bits of PCM0=0001<=>PWM (see p1261)
									;;Need to set 1 to have PD0=PWM0 and PD1=PWM1
									LDR R6, = GPIOPCTL_D
									;LDR	R0, [R6] 	 ;;	*(int *)(0x40007000+0x0000052C)=1;
									;ORR	R0, R0, #0x01 ;; Port D, pin 1 = PWM
									MOV	R0, #0x01
									STR R0, [R6]

									;;MOT2 : Pin muxing for PWM, port H, reg. GPIOPCTL(p444), 4bits in PCM0=0001<=>PWM (see p1261)
									;;we need to set mux = 2 to have PH0=PWM2 and PH1=PWM3
									LDR R6, = GPIOPCTL_H
									MOV	R0, #0x02
									STR R0, [R6]

									;;Alternate Function Select (p 426), PD0 use alernate fonction (PWM upward)
									;;so PD0 = 1
									LDR R6, =GPIOAFSEL_D
									LDR	R0, [R6] 	  ;*(int *)(0x40007000+0x00000420)= *(int *)(0x40007000+0x00000420) | 0x00000001;
									ORR	R0, R0, #0x01 ;
									STR R0, [R6]

									;;MOT2 : Alternate Function Select (p 426), PH0 use PWM so Alternate funct
									;;so PH0 = 1
									LDR R6, =GPIOAFSEL_H
									LDR	R0, [R6] 	  ;*(int *)(0x40007000+0x00000420)= *(int *)(0x40007000+0x00000420) | 0x00000001;
									ORR	R0, R0, #0x01 ;
									STR R0, [R6]

									;;-----------PWM0 pour ENGINE 1 connect at PD0
									;;PWM0 produce PWM0 and PWM1 output
									;;Config Modes PWM0 + mode GenA + mode GenB
									LDR R6, = PWM0CTL
									MOV	R0, #2		;Mode up-down-up-down, not synchro
									STR R0, [R6]

									LDR R6, =PWM0GENA ;Descending count, when CMPA = CPT => output pwmA=0
									;Croissant count, when CMPA = CPT => output pwmA=1
									MOV	R0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:nothing), ACTCMPBU=00(B up nothing)
									STR R0, [R6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00

									LDR R6, =PWM0GENB;in Croissant count, when CMPB = CPT => output pwmA=1
									MOV	R0,	#0x0B00	;in decending count, when CMPB = CPT => output pwmB=0
									STR R0, [R6]
									;Config CPT, CMP A et CMP B
														;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
									;;mesure : SysCtlClockGet=0F42400h, /16=0x3E8,
									;;divide by 2 because ENGINE 6v on alim 12v
									LDR	R6, =PWM0LOAD ;PWM0LOAD=periode/2 =0x1F4
									MOV R0,	#0x1F4
									STR	R0,[R6]

									LDR	R6, =PWM0CMPA ;Value cyclique report : for 10% => 1C2h if clock = 0F42400
									MOV	R0, #VITESSE
									STR	R0, [R6]

									LDR	R6, =PWM0CMPB ;PWM0CMPB receive same value. (cyclique report depending of CMPA)
									MOV	R0,	#0x1F4
									STR	R0,	[R6]

									;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
									LDR	R6, =PWM0CTL
									LDR	R0, [R6]
									ORR	R0,	R0,	#0x07
									STR	R0,	[R6]

									;;-----------PWM2 for ENGINE 2 connect to PH0
									;;PWM1block produce PWM2 et PWM3 output
									;;Config Modes PWM2 + mode GenA + mode GenB
									LDR R6, = PWM1CTL
									MOV	R0, #2		;Mode up-down-up-down, not synchro
									STR R0, [R6]	;*(int *)(0x40028000+0x040)=2;

									LDR R6, =PWM1GENA ;decount, when CMPA = CPT => output pwmA=0
									;croissant count, when CMPA = CPT => output pwmA=1
									MOV	R0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:nothing), ACTCMPBU=00(B up nothing)
									STR R0, [R6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00

 									;*(int *)(0x40028000+0x060)=0x0B0; //
									LDR R6, =PWM1GENB	;*(int *)(0x40028000+0x064)=0x0B00;
									MOV	R0,	#0x0B00	;in decount, when CMPB = CPT => output pwmB=0
									STR R0, [R6]	;in count croissant, when CMPB = CPT => output pwmA=1
									;Config CPT, CMP A et CMP B
									;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
									;;in mesure : SysCtlClockGet=0F42400h, /16=0x3E8,
									;;divide by 2 because ENGINE 6v sur alim 12v
									;*(int *)(0x40028000+0x050)=0x1F4; //PWM0LOAD=periode/2 =0x1F4
									LDR	R6, =PWM1LOAD
									MOV R0,	#0x1F4
									STR	R0,[R6]

									LDR	R6, =PWM1CMPA ;cyclique value report : pour 10% => 1C2h if clock = 0F42400
									MOV	R0,	#VITESSE
									STR	R0, [R6]  ;*(int *)(0x40028000+0x058)=0x01C2;

									LDR	R6, =PWM1CMPB ;PWM0CMPB recoit meme value. (CMPA depend du cyclique report)
									MOV	R0,	#0x1F4	; *(int *)(0x40028000+0x05C)=0x1F4;
									STR	R0,	[R6]

									;Control PWM : activate PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
									LDR	R6, =PWM1CTL
									LDR	R0, [R6]	;*(int *) (0x40028000+0x40)= *(int *)(0x40028000+0x40) | 0x07;
									ORR	R0,	R0,	#0x07
									STR	R0,	[R6]

									;;-----End config of PWMs

									;PORT D OUTPUT pin0 (pwm)=pin1(direction)=pin2(slow decay)=pin5(12v enable)
									LDR	R6, =GPIODIR_D
									LDR	R0, [R6]
									ORR	R0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
									STR	R0,[R6]
									;Port D, 2mA same
									LDR	R6, =GPIODR2R_D ;
									LDR	R0, [R6]
									ORR	R0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
									STR	R0,[R6]
									;Port D, Digital Enable
									LDR	R6, =GPIODEN_D ;
									LDR	R0, [R6]
									ORR	R0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
									STR	R0,[R6]
									;Port D : set to 1 the slow Decay and 12V et set 0 for dir and pwm
									LDR	R6, =(GPIODATA_D+((GPIO_0+GPIO_1+GPIO_2+GPIO_5)<<2))
									MOV	R0, #(GPIO_2+GPIO_5) ; #0x24
									STR	R0,[R6]

									;MOT2, PH1 for direction ENGINE ouput
									LDR	R6, =GPIODIR_H
									MOV	R0,	#0x03	;
									STR	R0,[R6]
									;Port H, 2mA same
									LDR	R6, =GPIODR2R_H
									MOV R0, #0x03
									STR	R0,[R6]
									;Port H, Digital Enable
									LDR	R6, =GPIODEN_H
									MOV R0, #0x03
									STR	R0,[R6]
									;Port H : set to 1 for dir
									LDR	R6, =(GPIODATA_H +(GPIO_1<<2))
									MOV	R0, #0x02
									STR	R0,[R6]

									BX	LR	; END init program

;Enable PWM0 (bit 0) and PWM2 (bit 2) p1145
;Warning here it's output PWM0 and PWM2 we controling, npt the blocks PWM0 and PWM1!!!
__ENGINE_RIGHT_ON
									;Enable output PWM0 (bit 0), p1145
									LDR	R6,	=PWMENABLE
									LDR R0, [R6]
									ORR R0,	#0x01 ;bit 0 = 1
									STR	R0,	[R6]
									BX	LR

__ENGINE_RIGHT_OFF
									LDR	R6,	=PWMENABLE
									LDR R0,	[R6]
									AND	R0,	#0x0E	;bit 0 = 0
									STR	R0,	[R6]
									BX	LR

__ENGINE_LEFT_ON
									LDR	R6,	=PWMENABLE
									LDR	R0, [R6]
									ORR	R0,	#0x04	;bit 2 = 1
									STR	R0,	[R6]
									BX	LR

__ENGINE_LEFT_OFF
									LDR	R6,	=PWMENABLE
									LDR	R0,	[R6]
									AND	R0,	#0x0B	;bit 2 = 0
									STR	R0,	[R6]
									BX	LR

__ENGINE_LEFT_RIGHT_ON
;;;
;;Start engine LEFT and RIGHT
;;;
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_ON
									BL __ENGINE_RIGHT_ON
									POP { R0, R6, PC}

__ENGINE_LEFT_RIGHT_OFF
;;;
;;Stop engine LEFT and RIGHT
;;;
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_OFF
									BL __ENGINE_RIGHT_OFF
									POP { R0, R6, PC}

__ENGINE_RIGHT_BACK
									;Inverse Direction (GPIO_D1)
									LDR	R6, =(GPIODATA_D+(GPIO_1<<2))
									MOV	R0, #0
									STR	R0,[R6]
									BX	LR

__ENGINE_RIGHT_FRONT
									;Inverse Direction (GPIO_D1)
									LDR	R6, =(GPIODATA_D+(GPIO_1<<2))
									MOV	R0, #2
									STR	R0,[R6]
									BX	LR

__ENGINE_LEFT_BACK
									;Inverse Direction (GPIO_D1)
									LDR	R6, =(GPIODATA_H+(GPIO_1<<2))
									MOV	R0, #2 ; contraire du ENGINE RIGHT
									STR	R0,[R6]
									BX	LR

__ENGINE_LEFT_FRONT
									;Inverse Direction (GPIO_D1)
									LDR	R6, =(GPIODATA_H+(GPIO_1<<2))
									MOV	R0, #0
									STR	R0,[R6]
									BX	LR

__ENGINE_RIGHT_INVERSE
									;Inverse Direction (GPIO_D1)
									LDR	R6, =(GPIODATA_D+(GPIO_1<<2))
									LDR	r1, [R6]
									EOR	R0, r1, #GPIO_1
									STR	R0,[R6]
									BX	LR

__ENGINE_LEFT_INVERSE
									;Inverse Direction (GPIO_D1)
									LDR	R6, =(GPIODATA_H+(GPIO_1<<2))
									LDR	r1, [R6]
									EOR	R0, r1, #GPIO_1
									STR	R0,[R6]
									BX	LR

__ENGINE_LEFT_RIGHT_FRONT
;;;
;;LEFT and RIGHT go FRONT
;;;
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_FRONT
									BL __ENGINE_RIGHT_FRONT
									POP { R0, R6, PC}

__ENGINE_LEFT_RIGHT_BACK
;;;
;;LEFT and RIGHT go BACK
;;;
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_BACK
									BL __ENGINE_RIGHT_BACK
									POP { R0, R6, PC}

__ENGINE_LEFT_FRONT_RIGHT_BACK
;;;
;;TURN RIGHT
;;;
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_FRONT
									BL __ENGINE_RIGHT_BACK
									POP { R0, R6, PC}


__ENGINE_LEFT_BACK_RIGHT_FRONT
;;;
;;TURN LEFT
;;;
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_BACK
									BL __ENGINE_RIGHT_FRONT
									POP { R0, R6, PC}

__ENGINE_LEFT_RIGHT_INVERSE
;;;
;;INVERSE BOTH ENGINE
;;;
									PUSH { R0, R1, R6, LR}
									BL __ENGINE_LEFT_INVERSE
									BL __ENGINE_RIGHT_INVERSE
									POP { R0, R1, R6, PC}

									END

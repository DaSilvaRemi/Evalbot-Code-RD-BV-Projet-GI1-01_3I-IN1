	;; RD BV - Evalbot (Cortex M3 de Texas Instrument);
; programme - Pilotage 2 ENGINEs Evalbot par PWM tout en ASM (configure les pwms + GPIO)

;Les pages se réfèrent au datasheet lm3s9b92.pdf

;Cablage :
;pin 10/PD0/PWM0 => input PWM du pont en H DRV8801RT
;pin 11/PD1/PWM1 => input Phase_R  du pont en H DRV8801RT
;pin 12/PD2		 => input SlowDecay commune aux 2 ponts en H
;pin 98/PD5		 => input Enable 12v du conv DC/DC
;pin 86/PH0/PWM2 => input PWM du 2nd pont en H
;pin 85/PH1/PWM3 => input Phase du 2nd pont en H

;; Hexa cORResponding values to pin numbers
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

GPIO_PORT_E_BASE 	EQU 	0x4005C000
GPIODATA_E			EQU 	GPIO_PORT_E_BASE
GPIODIR_E			EQU		GPIO_PORT_E_BASE+0x00000400
GPIODR2R_E			EQU 	GPIO_PORT_E_BASE+0x00000500
GPIODEN_E			EQU		GPIO_PORT_E_BASE+0x0000051C
GPIOPCTL_E			EQU		GPIO_PORT_E_BASE+0x0000052C ; GPIO Port Control (GPIOPCTL), offset 0x52C; p444
GPIOAFSEL_E			EQU		GPIO_PORT_E_BASE+0x00000420 ; GPIO Alternate Function Select (GPIOAFSEL), offset 0x420; p426

;; Pulse Width Modulator (PWM) configuration
PWM_BASE			EQU		0x040028000 	   ;BASE des Block PWM p.1138
PWMENABLE			EQU		PWM_BASE+0x008	   ; p1145

;Block PWM0 pour sorties PWM0 et PWM1 (ENGINE 1)
PWM0CTL				EQU		PWM_BASE+0x040 ;p1167
PWM0LOAD			EQU		PWM_BASE+0x050
PWM0CMPA			EQU		PWM_BASE+0x058
PWM0CMPB			EQU		PWM_BASE+0x05C
PWM0GENA			EQU		PWM_BASE+0x060
PWM0GENB			EQU		PWM_BASE+0x064

;Block PWM1 pour sorties PWM1 et PWM2 (ENGINE 2)
PWM1CTL				EQU		PWM_BASE+0x080
PWM1LOAD			EQU		PWM_BASE+0x090
PWM1CMPA			EQU		PWM_BASE+0x098
PWM1CMPB			EQU		PWM_BASE+0x09C
PWM1GENA			EQU		PWM_BASE+0x0A0
PWM1GENB			EQU		PWM_BASE+0x0A4

;;Quadrature Encoder Interface (QEI) configuration (p1204)
QEI_0				EQU		0x4002C000
QEI_1				EQU		0x4002D000

PortE_R_QEI_A		EQU  GPIO_2 ;(0000 0100)
PortE_L_QEI_A		EQU  GPIO_3 ;(0000 1000)
PortE_LR_QEI_A		EQU  GPIO_2+GPIO_3 ;(0000 1100)

;0x1A2
VITESSE				EQU		0x192	; Valeures plus petites => Vitesse plus rapide exemple 0x192
								; Valeures plus grANDes => Vitesse moins rapide exemple 0x1B2


									AREA    _CONFIG_ENGINE_, CODE, READONLY
									ENTRY

									;; The EXPORT commAND specifies that a symbol can be accessed by other shared objects or executables.
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
									LDR R6, = SYSCTL_RCGC0
									LDR	R0, [R6]
									ORR	R0, R0, #0x00100000  ;;bit 20 = PWM recoit clock: ON (p271)
									STR R0, [R6]
									
									LDR R6, = SYSCTL_RCGC0
									LDR	R0, [R6]
									ORR	R0, R0, #0x00000100  ;;bit 04 = QEI recoit clock: ON (p1209)
									STR R0, [R6]

									;ROM_SysCtlPWMClockSet(SYSCTL_PWMDIV_1);PWM clock is processor clock /1
									;Je ne fais rien car par defaut = OK!!
									;*(int *) (0x400FE060)= *(int *)(0x4
									;RCGC2 :  Enable port D GPIO(p291 ) car ENGINE RIGHT sur port D
									LDR R6, = SYSCTL_RCGC2
									LDR	R0, [R6]
									ORR	R0, R0, #0x08  ;; Enable port D GPIO
									STR R0, [R6]

									;MOT2 : RCGC2 :  Enable port H GPIO  (2eme ENGINEs)
									LDR R6, = SYSCTL_RCGC2
									LDR	R0, [R6]
									ORR	R0, R0, #0x80  ;; Enable port H GPIO
									STR R0, [R6]

									;RCGC2 :  Enable port E GPIO  (QEI (p1204))
									LDR R6, = SYSCTL_RCGC2
									LDR	R0, [R6]
									ORR	R0, R0, #0x10  ;; Enable port E GPIO :(0000 0000) / (HGFE DCBA)
									STR R0, [R6]

									NOP
									NOP
									NOP

									;;Pin muxing pour PWM, port D, reg. GPIOPCTL(p444), 4bits de PCM0=0001<=>PWM (voir p1261)
									;;il faut mettre 1 pour avoir PD0=PWM0 et PD1=PWM1
									LDR R6, = GPIOPCTL_D
									;LDR	R0, [R6] 	 ;;	*(int *)(0x40007000+0x0000052C)=1;
									;ORR	R0, R0, #0x01 ;; Port D, pin 1 = PWM
									MOV	R0, #0x01
									STR R0, [R6]

									;;MOT2 : Pin muxing pour PWM, port H, reg. GPIOPCTL(p444), 4bits de PCM0=0001<=>PWM (voir p1261)
									;;il faut mettre mux = 2 pour avoir PH0=PWM2 et PH1=PWM3
									LDR R6, = GPIOPCTL_H
									MOV	R0, #0x02
									STR R0, [R6]

									;;In port E GPIOPCTL(p444), We need the PHA0 and PHB0 set in PORT E 2 & 3
									;;We need to put mux = 4 to have PE0=PHA0 & PE1=PHA1
									LDR R6, = GPIOPCTL_E
									MOV R0, #0x04
									STR R0, [R6]

									;;Alternate Function Select (p 426), PD0 utilise alernate fonction (PWM au dessus)
									;;donc PD0 = 1
									LDR R6, =GPIOAFSEL_D
									LDR	R0, [R6] 	  ;*(int *)(0x40007000+0x00000420)= *(int *)(0x40007000+0x00000420) | 0x00000001;
									ORR	R0, R0, #0x01 ;
									STR R0, [R6]

									;;MOT2 : Alternate Function Select (p 426), PH0 utilise PWM donc Alternate funct
									;;donc PH0 = 1
									LDR R6, =GPIOAFSEL_H
									LDR	R0, [R6] 	  ;*(int *)(0x40007000+0x00000420)= *(int *)(0x40007000+0x00000420) | 0x00000001;
									ORR	R0, R0, #0x01 ;
									STR R0, [R6]

									;Alternate Function Select (p 426), PE2 et PE3 utilise QEI so Alternate funct
									;;donc PE2 et PE3 = 1
									;LDR R6, =GPIOAFSEL_E
									;LDR R0, [R6]
									;ORR R0, #0x01
									;STR R0, [R6]

									;;-----------PWM0 pour ENGINE 1 connect� � PD0
									;;PWM0 produit PWM0 et PWM1 output
									;;Config Modes PWM0 + mode GenA + mode GenB
									LDR R6, = PWM0CTL
									MOV	R0, #2		;Mode up-down-up-down, pas synchro
									STR R0, [R6]

									LDR R6, =PWM0GENA ;en decomptage, qd comparateurA = compteur => sortie pwmA=0
									;en comptage croissant, qd comparateurA = compteur => sortie pwmA=1
									MOV	R0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:rien), ACTCMPBU=00(B up rien)
									STR R0, [R6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00

									LDR R6, =PWM0GENB;en comptage croissant, qd comparateurB = compteur => sortie pwmA=1
									MOV	R0,	#0x0B00	;en decomptage, qd comparateurB = compteur => sortie pwmB=0
									STR R0, [R6]
									;Config Compteur, comparateur A et comparateur B
														;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
									;;en mesure : SysCtlClockGet=0F42400h, /16=0x3E8,
									;;on divise par 2 car ENGINE 6v sur alim 12v
									LDR	R6, =PWM0LOAD ;PWM0LOAD=periode/2 =0x1F4
									MOV R0,	#0x1F4
									STR	R0,[R6]

									LDR	R6, =PWM0CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
									MOV	R0, #VITESSE
									STR	R0, [R6]

									LDR	R6, =PWM0CMPB ;PWM0CMPB recoit meme valeur. (rapport cyclique depend de CMPA)
									MOV	R0,	#0x1F4
									STR	R0,	[R6]

									;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
									LDR	R6, =PWM0CTL
									LDR	R0, [R6]
									ORR	R0,	R0,	#0x07
									STR	R0,	[R6]

									;;-----------PWM2 pour ENGINE 2 connect� � PH0
									;;PWM1block produit PWM2 et PWM3 output
									;;Config Modes PWM2 + mode GenA + mode GenB
									LDR R6, = PWM1CTL
									MOV	R0, #2		;Mode up-down-up-down, pas synchro
									STR R0, [R6]	;*(int *)(0x40028000+0x040)=2;

									LDR R6, =PWM1GENA ;en decomptage, qd comparateurA = compteur => sortie pwmA=0
									;en comptage croissant, qd comparateurA = compteur => sortie pwmA=1
									MOV	R0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:rien), ACTCMPBU=00(B up rien)
									STR R0, [R6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00

 									;*(int *)(0x40028000+0x060)=0x0B0; //
									LDR R6, =PWM1GENB	;*(int *)(0x40028000+0x064)=0x0B00;
									MOV	R0,	#0x0B00	;en decomptage, qd comparateurB = compteur => sortie pwmB=0
									STR R0, [R6]	;en comptage croissant, qd comparateurB = compteur => sortie pwmA=1
									;Config Compteur, comparateur A et comparateur B
									;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
									;;en mesure : SysCtlClockGet=0F42400h, /16=0x3E8,
									;;on divise par 2 car ENGINE 6v sur alim 12v
									;*(int *)(0x40028000+0x050)=0x1F4; //PWM0LOAD=periode/2 =0x1F4
									LDR	R6, =PWM1LOAD
									MOV R0,	#0x1F4
									STR	R0,[R6]

									LDR	R6, =PWM1CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
									MOV	R0,	#VITESSE
									STR	R0, [R6]  ;*(int *)(0x40028000+0x058)=0x01C2;

									LDR	R6, =PWM1CMPB ;PWM0CMPB recoit meme valeur. (CMPA depend du rapport cyclique)
									MOV	R0,	#0x1F4	; *(int *)(0x40028000+0x05C)=0x1F4;
									STR	R0,	[R6]

									;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
									LDR	R6, =PWM1CTL
									LDR	R0, [R6]	;*(int *) (0x40028000+0x40)= *(int *)(0x40028000+0x40) | 0x07;
									ORR	R0,	R0,	#0x07
									STR	R0,	[R6]

									;;-----Fin config des PWMs

									;PORT D OUTPUT pin0 (pwm)=pin1(direction)=pin2(slow decay)=pin5(12v enable)
									LDR	R6, =GPIODIR_D
									LDR	R0, [R6]
									ORR	R0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
									STR	R0,[R6]
									;Port D, 2mA les meme
									LDR	R6, =GPIODR2R_D ;
									LDR	R0, [R6]
									ORR	R0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
									STR	R0,[R6]
									;Port D, Digital Enable
									LDR	R6, =GPIODEN_D ;
									LDR	R0, [R6]
									ORR	R0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
									STR	R0,[R6]
									;Port D : mise à 1 de slow Decay et 12V et mise � 0 pour dir et pwm
									LDR	R6, =(GPIODATA_D+((GPIO_0+GPIO_1+GPIO_2+GPIO_5)<<2))
									MOV	R0, #(GPIO_2+GPIO_5) ; #0x24
									STR	R0,[R6]

									;MOT2, PH1 pour sens ENGINE ouput
									LDR	R6, =GPIODIR_H
									MOV	R0,	#0x03	;
									STR	R0,[R6]
									;Port H, 2mA les meme
									LDR	R6, =GPIODR2R_H
									MOV R0, #0x03
									STR	R0,[R6]
									;Port H, Digital Enable
									LDR	R6, =GPIODEN_H
									MOV R0, #0x03
									STR	R0,[R6]
									;Port H : mise à 1 pour dir
									LDR	R6, =(GPIODATA_H +(GPIO_1<<2))
									MOV	R0, #0x02
									STR	R0,[R6]
									
									;;InfraLed Configuration
									
									;LDR R6, =GPIODIR_E    ;; 1 Pin du portF en sortie (broche 4 et 5 : 00110000)
									;LDR R0, [R6]
									;ORR R0, #GPIO_6
									;STR R0, [R6]

									;LDR R6, =GPIODEN_E	;; Enable Digital Function
									;LDR R0, [R6]
									;ORR R0, #GPIO_6
									;STR R0, [R6]

									;LDR R6, =GPIODR2R_E	;; Choix de l'intensite de sortie (2mA)
									;LDR R0, [R6]
									;ORR R0, #GPIO_6
									;STR R0, [R6]
									
									;LDR R4, =GPIO_PORT_E_BASE + (GPIO_6<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
									;MOV R2, #GPIO_6
									;ORR R2, R4
									;STR	R2, [R4]

									BX	LR	; FIN du sous programme d'init.

;Enable PWM0 (bit 0) et PWM2 (bit 2) p1145
;Attention ici c'est les sorties PWM0 et PWM2
;qu'on controle, pas les blocks PWM0 et PWM1!!!
__ENGINE_RIGHT_ON
									;Enable sortie PWM0 (bit 0), p1145
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
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_ON
									BL __ENGINE_RIGHT_ON
									POP { R0, R6, PC}

__ENGINE_LEFT_RIGHT_OFF
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
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_FRONT
									BL __ENGINE_RIGHT_FRONT
									POP { R0, R6, PC}

__ENGINE_LEFT_RIGHT_BACK
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_BACK
									BL __ENGINE_RIGHT_BACK
									POP { R0, R6, PC}

__ENGINE_LEFT_FRONT_RIGHT_BACK
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_FRONT
									BL __ENGINE_RIGHT_BACK
									POP { R0, R6, PC}


__ENGINE_LEFT_BACK_RIGHT_FRONT
									PUSH { R0, R6, LR}
									BL __ENGINE_LEFT_BACK
									BL __ENGINE_RIGHT_FRONT
									POP { R0, R6, PC}

__ENGINE_LEFT_RIGHT_INVERSE
									PUSH { R0, R1, R6, LR}
									BL __ENGINE_LEFT_INVERSE
									BL __ENGINE_RIGHT_INVERSE
									POP { R0, R1, R6, PC}

									END

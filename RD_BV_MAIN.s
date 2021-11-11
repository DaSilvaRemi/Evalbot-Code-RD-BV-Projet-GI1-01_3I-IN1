					AREA    _MAIN_PROGRAM_, CODE, READONLY
					ENTRY
					EXPORT	__main

					;----------------------------------------IMPORT------------------------------------------------;
					;----------------------ENGINE-----------------;
					IMPORT	__ENGINE_INIT ; init engine (configure pwms + GPIO)
					IMPORT	__ENGINE_RIGHT_ON ; activate right engine
					IMPORT  __ENGINE_RIGHT_OFF ; desactivate right engine
					IMPORT  __ENGINE_RIGHT_FRONT ; right  engine go forward
					IMPORT  __ENGINE_RIGHT_BACK	; back engine go backward
					IMPORT  __ENGINE_RIGHT_INVERSE ; inverse rotation direction of roght engine
					IMPORT	__ENGINE_LEFT_ON ; activate left engine
					IMPORT  __ENGINE_LEFT_OFF ; desactivate left engine
					IMPORT  __ENGINE_LEFT_FRONT ; right  engine go forward
					IMPORT  __ENGINE_LEFT_BACK ; back engine go backward
					IMPORT  __ENGINE_LEFT_INVERSE ; inverse rotation direction of left engine

					;----------------------SWITCH-----------------;
					IMPORT __CONFIG_SW ; configure SW (configure pwms + GPIO)
					IMPORT __READ_STATE_SW_1 ;Read state of SW1
					IMPORT __READ_STATE_SW_2 ;Read state of SW2

					;----------------------BUMPER-----------------;
					IMPORT __CONFIG_BUMPER ; configure Bumper (configure pwms + GPIO)
					IMPORT __READ_STATE_BUMPER_1 ;Read state of Bumper 1
					IMPORT __READ_STATE_BUMPER_2 ;Read state of Bumper 2

					;----------------------LED-----------------;
					IMPORT __CONFIG_LED ; configure Led (configure pwms + GPIO)
					IMPORT __SWITCH_ON_LED_1 ;Switch on LED1
					IMPORT __SWITCH_ON_LED_2 ;Switch off LED2
					IMPORT __SWITCH_ON_LED_1_2 ;Switch off LED1 1 & 2
					IMPORT __SWITCH_OFF_LED_1 ;Switch on LED2
					IMPORT __SWITCH_OFF_LED_2 ;Switch off LED2
					IMPORT __SWITCH_OFF_LED_1_2 ;Switch off LED1 1 & 2
					IMPORT __BLINK_LED_1_2 ;Blink LED 1 & 2

__main


__init

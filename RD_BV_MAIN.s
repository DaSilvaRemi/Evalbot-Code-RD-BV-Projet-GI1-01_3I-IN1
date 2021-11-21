TEMPS_X EQU 0x121EAC0
TEMPS_Y EQU 0x11A49A0

									AREA    _MAIN_PROGRAM_, CODE, READONLY
									ENTRY
									EXPORT	__main

									;----------------------------------------IMPORT------------------------------------------------;
									;----------------------ENGINE-----------------;
									IMPORT	__ENGINE_INIT ; init engine (configure pwms + GPIO)
									IMPORT	__ENGINE_RIGHT_ON ; activate right engine
									IMPORT  __ENGINE_RIGHT_OFF ; desactivate right engine
									IMPORT  __ENGINE_RIGHT_FRONT ; right  engine go forward
									IMPORT  __ENGINE_RIGHT_BACK	; right engine go backward
									IMPORT  __ENGINE_RIGHT_INVERSE ; inverse rotation direction of roght engine
									IMPORT	__ENGINE_LEFT_ON ; activate left engine
									IMPORT  __ENGINE_LEFT_OFF ; desactivate left engine
									IMPORT  __ENGINE_LEFT_FRONT ; left  engine go forward
									IMPORT  __ENGINE_LEFT_BACK ; left  engine go backward
									IMPORT  __ENGINE_LEFT_INVERSE ; inverse rotation direction of left engine
									IMPORT __ENGINE_LEFT_RIGHT_ON ; activate right and left engine
									IMPORT __ENGINE_LEFT_RIGHT_OFF ; desactivate right and left engine
									IMPORT __ENGINE_LEFT_RIGHT_FRONT ; left and right  engine go forward
									IMPORT __ENGINE_LEFT_RIGHT_BACK ; left and right  engine go backward
									IMPORT __ENGINE_LEFT_BACK_RIGHT_FRONT ; left engine go backward and right  engine go frontward
									IMPORT __ENGINE_LEFT_FRONT_RIGHT_BACK ; left engine go frontward and right  engine go backward
									IMPORT __ENGINE_LEFT_RIGHT_INVERSE ; inverse rotation direction of right & left engine

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
										
									;----------------------OLED-----------------;
									;IMPORT __CONFIG_0LED
									;IMPORT __DISPLAY_BYTE_DATA

									;----------------------TOOLS-----------------;
									IMPORT __WAIT
									IMPORT __WAIT_HALF_ROTATION
									IMPORT __WAIT_A_TIME

;----------------------------------------START MAIN------------------------------------------------;

__main
									BL __INIT_START
									
									BL __CONFIG_BUMPER

start_while_is_start_wall
									BL __READ_STATE_BUMPER_1
									BEQ end_while_is_start_wall

									BL __READ_STATE_BUMPER_2
									BNE start_while_is_start_wall

end_while_is_start_wall
									BL __WHILE_IS_NOT_END_WALL

									BL __ENGINE_LEFT_RIGHT_OFF
									BL __CONFIG_SW
									BL __CONFIG_LED
sw1
									BL __READ_STATE_SW_1
									BNE sw1

									BL __DISPLAY_BINARY_MSG

						 			B sw1

;----------------------------------------END MAIN------------------------------------------------;

;----------------------------------------START INIT START------------------------------------------------;

__INIT_START
									PUSH { R0, R6, R10-R12, LR }

									BL __ENGINE_INIT
									BL __CONFIG_SW

sw2
									BL __READ_STATE_SW_2
									BNE sw2

									BL __ENGINE_LEFT_RIGHT_ON
									BL __ENGINE_LEFT_RIGHT_FRONT

									POP { R0, R6, R10-R12, PC }

;----------------------------------------END INIT START------------------------------------------------;

;----------------------------------------START INIT AFTER SW2------------------------------------------------;

__INIT_AFTER_SW2
									LDR R2, =TEMPS_X
									LDR R3, =TEMPS_Y
									LDR R7, =2_00000000
									BX LR

;----------------------------------------END INIT AFTER SW2------------------------------------------------;

;----------------------------------------START TURN 90 RIGHT------------------------------------------------;

__TURN_90_RIGHT
									PUSH { R0, R1, R6, LR }
									BL __ENGINE_LEFT_FRONT_RIGHT_BACK
									BL __WAIT_HALF_ROTATION
									POP { R0, R1, R6, PC }

;----------------------------------------END TURN 90 RIGHT------------------------------------------------;

;----------------------------------------START TURN 90 LEFT------------------------------------------------;

__TURN_90_LEFT
									PUSH { R0, R1, R6, LR }
									BL __ENGINE_LEFT_BACK_RIGHT_FRONT
									BL __WAIT_HALF_ROTATION
									POP { R0, R1, R6, PC }

;----------------------------------------END TURN 90 LEFT------------------------------------------------;


;----------------------------------------START TURN_ARROUND------------------------------------------------;

__TURN_ARROUND
									PUSH { R0, R1, R6, LR }
									BL __TURN_90_RIGHT
									BL __TURN_90_RIGHT
									POP { R0, R1, R6, PC }

;----------------------------------------END TURN_ARROUND------------------------------------------------;

;----------------------------------------START WHILE IS NOT END WALL------------------------------------------------;

__WHILE_IS_NOT_END_WALL
									PUSH { R0-R10, LR }
init_startup_while_var
									BL __INIT_AFTER_SW2
									LDR R4, =0
									LDR R5, =2_00000001

start_while_is_not_end_wall

									BL __ENGINE_LEFT_RIGHT_BACK
									;BL __TURN_ARROUND
									;BL __ENGINE_LEFT_RIGHT_FRONT

wait_to_be_outside_range_Y_DOWN
									MOV R1, R3
									BL __WAIT_A_TIME
									
move_to_the_right
									BL __TURN_90_RIGHT
									BL __ENGINE_LEFT_RIGHT_FRONT

wait_to_be_outside_range_X
									MOV R1, R2
									BL __WAIT_A_TIME
end_wall_is_bumped
									BL __READ_STATE_BUMPER_1
									BEQ end_while_is_not_end_wall

									BL __READ_STATE_BUMPER_2
									BEQ end_while_is_not_end_wall
move_to_the_up
									BL __TURN_90_LEFT
									BL __ENGINE_LEFT_RIGHT_FRONT

wait_to_be_outside_range_Y_UP
									MOV R1, R3
									BL __WAIT_A_TIME

basic_wall_is_bumped
									BL __READ_STATE_BUMPER_1
									BEQ save_1_binary

									BL __READ_STATE_BUMPER_2
									BEQ save_1_binary
									B shift_binary_mask

save_1_binary
									ORR  R7, R5, R7

shift_binary_mask
									LSL  R5, R5, R4
									ADD R4, #1
									B start_while_is_not_end_wall

end_while_is_not_end_wall
									POP { R0-R10, PC }

;----------------------------------------END WHILE IS NOT END WALL------------------------------------------------;

;----------------------------------------START DISPLAY_BINARY_MSG------------------------------------------------;

__DISPLAY_BINARY_MSG
									PUSH { R0-R4, R6, R7, LR }
									
									LDR R3, =0
start_while_binary_msg
									CMP R3, #7
									BEQ end_while_binary_msg

									AND R2, R7, #2_00000001

									CMP R2, #1
									BEQ display_1

									CMP R2, #0
									BEQ display_0

display_1
									BL __SWITCH_ON_LED_1
									B end_display
		
display_0		
									BL __SWITCH_ON_LED_2
end_display
									BL __WAIT
									BL __SWITCH_OFF_LED_1_2

									ADD R3, #1
									LSR R7, R3
									B start_while_binary_msg
end_while_binary_msg

									POP { R0-R4, R6, R7, PC }
									
;----------------------------------------END DISPLAY_BINARY_MSG------------------------------------------------;

end_p
									END
									NOP

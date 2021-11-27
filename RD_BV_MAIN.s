; TIME X TO WAIT WHILE EVALBOT MOVE ON X AXE
TEMPS_X EQU 0x90f560
; TIME Y TO WAIT WHILE EVALBOT MOVE ON Y AXE
TEMPS_Y EQU 0x469268

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

									;----------------------TOOLS-----------------;
									IMPORT __WAIT ;WAIT A DEFAULT TIME
									IMPORT __WAIT_HALF_ROTATION ; WAIT HAL ROTATION OF EVALBOT
									IMPORT __WAIT_A_TIME ; WAIT A TIME SET IN PARAM

;----------------------------------------START MAIN------------------------------------------------;

;;;
;;main program
;;;
__main
									;------------------CONFIG SW, BUMPER and init ENGINE--------------------------;
									BL __INIT_START ;init engine and SW and wait SW2 to be activated
									BL __CONFIG_BUMPER ; config bumper after SW2 is activated
									
									;------------------WAIT TO HIT START WALL--------------------------;
start_while_is_start_wall
									BL __READ_STATE_BUMPER_1
									BEQ end_while_is_start_wall

									BL __READ_STATE_BUMPER_2
									BNE start_while_is_start_wall

									;------------------WAIT TO HIT END WALL--------------------------;
end_while_is_start_wall
									BL __WHILE_IS_NOT_END_WALL ;Lauchn binary counter and wait to hit end

									;------------------STOP ENGINE AND WAIT USER ACTION--------------------------;
									BL __ENGINE_LEFT_RIGHT_OFF 
									BL __CONFIG_SW
									BL __CONFIG_LED ;CONFIG LED to display MSG
									
									;------------WAIT USER PRESSED SW1-------------;
sw1
									BL __READ_STATE_SW_1
									BNE sw1
									
									;If user press SW1 display MSG
									BL __DISPLAY_BINARY_MSG

						 			B sw1

;----------------------------------------END MAIN------------------------------------------------;

;----------------------------------------START INIT START------------------------------------------------;

;;;
;;INIT the engine and config SWITCH. Wait SW2 is activated and turn on engine.
;;;
__INIT_START
									PUSH { R0, R6, R10-R12, LR }

									//CONFIG ENGINE AND SW
									BL __ENGINE_INIT
									BL __CONFIG_SW
									
									//WAIT SW2 TO BE PRESSED
sw2
									BL __READ_STATE_SW_2
									BNE sw2

									//TURN ON ENGINE
									BL __ENGINE_LEFT_RIGHT_ON
									BL __ENGINE_LEFT_RIGHT_FRONT

									POP { R0, R6, R10-R12, PC }

;----------------------------------------END INIT START------------------------------------------------;

;----------------------------------------START INIT AFTER SW2------------------------------------------------;

;;;
;; LOAD WAIT TIME and SET the registor to MSG
;;;
__INIT_AFTER_SW2
									LDR R2, =TEMPS_X
									LDR R3, =TEMPS_Y
									LDR R7, =2_00000000
									BX LR

;----------------------------------------END INIT AFTER SW2------------------------------------------------;

;----------------------------------------START TURN 90 RIGHT------------------------------------------------;
;;;
;; LOAD 90 degrees to the right
;;;
__TURN_90_RIGHT
									PUSH { R0, R1, R6, LR }
									BL __ENGINE_LEFT_FRONT_RIGHT_BACK
									BL __WAIT_HALF_ROTATION
									POP { R0, R1, R6, PC }

;----------------------------------------END TURN 90 RIGHT------------------------------------------------;

;----------------------------------------START TURN 90 LEFT------------------------------------------------;
;;;
;; LOAD 90 degrees to the left
;;;
__TURN_90_LEFT
									PUSH { R0, R1, R6, LR }
									BL __ENGINE_LEFT_BACK_RIGHT_FRONT
									BL __WAIT_HALF_ROTATION
									POP { R0, R1, R6, PC }

;----------------------------------------END TURN 90 LEFT------------------------------------------------;

;----------------------------------------START WHILE IS NOT END WALL------------------------------------------------;

;;;
;;SAVE 1 or 0 while evalbot doesn't bump END wall
;;
;;@returns BINARY MSG LOAD IN R7
;;;
__WHILE_IS_NOT_END_WALL
									PUSH { R0-R6, R8-R10, LR }
init_startup_while_var
									;INIT REGISTER
									BL __INIT_AFTER_SW2
									LDR R4, =0
									LDR R5, =2_00000001

start_while_is_not_end_wall

									BL __ENGINE_LEFT_RIGHT_BACK
									;GO BACK AFTER HIT OR NOT A WALL
wait_to_be_outside_range_Y_DOWN
									MOV R1, R3 ;LOAD Y WAIT TIME IN WAIT PARAMETER
									BL __WAIT_A_TIME ;WAIT THE SET TIME
									
move_to_the_right
									BL __TURN_90_RIGHT
									BL __ENGINE_LEFT_RIGHT_FRONT ;GO to the front

wait_to_be_outside_range_X
									MOV R1, R2 ;LOAD X WAIT TIME IN WAIT PARAMETER
									BL __WAIT_A_TIME

									;Check if evablot was bumped the evalbot during he runs in x Axes
end_wall_is_bumped
									BL __READ_STATE_BUMPER_1
									BEQ end_while_is_not_end_wall

									BL __READ_STATE_BUMPER_2
									BEQ end_while_is_not_end_wall
									
									;If evalvot doesn't bump wall we turn to the left and continue searching wall
move_to_the_up
									BL __TURN_90_LEFT 
									BL __ENGINE_LEFT_RIGHT_FRONT 

wait_to_be_outside_range_Y_UP
									MOV R1, R3 ;LOAD Y WAIT TIME IN WAIT PARAMETER
									BL __WAIT_A_TIME ;WAIT THE SET TIME

									;Check if evalbot bump binary wall
basic_wall_is_bumped
									BL __READ_STATE_BUMPER_1
									BEQ save_1_binary

									BL __READ_STATE_BUMPER_2
									BEQ save_1_binary
									B shift_binary_mask

save_1_binary
									;If evalbot bump a wall we save 1 Else 0 by default
									ORR  R7, R5, R7 ;Set the 1 binary in message register with mask example 0001 0111 | 0010 0000 = 0011 0111

shift_binary_mask
									LSL  R5, #1 ; Shift the mask to set the the bit at good position example 0000 0001 << 1 = 0000 0010
									B start_while_is_not_end_wall

end_while_is_not_end_wall
									POP { R0-R6, R8-R10, PC }

;----------------------------------------END WHILE IS NOT END WALL------------------------------------------------;

;----------------------------------------START DISPLAY_BINARY_MSG------------------------------------------------;

__DISPLAY_BINARY_MSG
									PUSH { R0-R4, R6, R7, LR }
									
									;Before start we  blink the led to inform user we start display msg
									LDR R3, =0
									BL __BLINK_LED_1_2

									;;Display the binary msg with LED
start_while_binary_msg
									CMP R3, #8 ;If we display a byte we stop the display
									BEQ end_while_binary_msg

									AND R2, R7, #2_00000001 ;We do and AND operation with a mask and the value of msg

									CMP R2, #1 ;If R7 value & 00000001 = 1 it's a wall so we display 1 with a LED
									BEQ display_1

									CMP R2, #0 ;If R7 value & 00000001 = 0 it's not a wall so we display 0 with a LED
									BEQ display_0
									B end_display

display_1
									BL __SWITCH_ON_LED_2 ;Display a 1
									B end_display
		
display_0		
									BL __SWITCH_ON_LED_1 ;Display a 0
end_display
									BL __WAIT ;WAIT USER READING TIME
									BL __SWITCH_OFF_LED_1_2 ; SWITCH OFF 2 LED

									ADD R3, #1 ;ADD THE CPT TO KNOW WHAT BIT WE NEED TO DISPLAY
									LSR R7, #1 ;Logical Shit Right in the message to display from the LSB to HSB
									BL __WAIT ;WAIT
									B start_while_binary_msg ;Continue display while it's not 8
end_while_binary_msg

									POP { R0-R4, R6, R7, PC }
									
;----------------------------------------END DISPLAY_BINARY_MSG------------------------------------------------;

end_p
									END
									NOP

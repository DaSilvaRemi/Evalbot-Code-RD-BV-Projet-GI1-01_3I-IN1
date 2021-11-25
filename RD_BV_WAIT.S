WAITING_BASE_TIME EQU 0x002FFFFF
;;0x33000000
WAITING_HALF_ROTATION_TIME EQU 0x5f5e10
;;0x11A49A0 
						AREA    _WAIT_, CODE, READONLY
						ENTRY

						EXPORT __WAIT
						EXPORT __WAIT_HALF_ROTATION
						EXPORT __WAIT_A_TIME

__WAIT
						PUSH {R1, LR}
						LDR R1, =WAITING_BASE_TIME	;; Waiting Time
						BL __WAIT_A_TIME
						POP {R1, PC}

__WAIT_HALF_ROTATION
						PUSH {R1, LR}
						LDR R1, =WAITING_HALF_ROTATION_TIME	;; Waiting Rotation Time
						BL __WAIT_A_TIME
						POP {R1, PC}

__WAIT_A_TIME
while
						SUBS R1, #1
						BNE while
						BX LR ;return to caller
                
						END

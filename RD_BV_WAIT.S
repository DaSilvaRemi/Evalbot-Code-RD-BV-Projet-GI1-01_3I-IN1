	;; RD BV - Evalbot (Cortex M3 de Texas Instrument);
;; Program to manage wait time

WAITING_BASE_TIME EQU 0x002FFFFF
WAITING_HALF_ROTATION_TIME EQU 0x5f5e10
						AREA    _WAIT_, CODE, READONLY
						ENTRY

						EXPORT __WAIT
						EXPORT __WAIT_HALF_ROTATION
						EXPORT __WAIT_A_TIME
;;;
;;WAIT A DEFAULT TIME
;;;
__WAIT
						PUSH {R1, LR}
						LDR R1, =WAITING_BASE_TIME	;; Waiting Time
						BL __WAIT_A_TIME
						POP {R1, PC}

__WAIT_HALF_ROTATION
;;;
;;WAIT A HALF ROTATION TIME
;;;
						PUSH {R1, LR}
						LDR R1, =WAITING_HALF_ROTATION_TIME	;; Waiting Rotation Time
						BL __WAIT_A_TIME
						POP {R1, PC}
;;;
;;WAIT A TIME
;;@params The time to wait (Need to be load in R1 register)
;;;
__WAIT_A_TIME
while
						SUBS R1, #1
						BNE while
						BX LR ;return to caller
                
						END

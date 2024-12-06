    AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL   EQU     0x20007B00 ; originally 0x20007500
SYS_EXIT        EQU     0x0        ; address 20007B00
SYS_ALARM       EQU     0x1        ; address 20007B04
SYS_SIGNAL      EQU     0x2        ; address 20007B08
SYS_MEMCPY      EQU     0x3        ; address 20007B0C
SYS_MALLOC      EQU     0x4        ; address 20007B10
SYS_FREE        EQU     0x5        ; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
        EXPORT  _syscall_table_init
_syscall_table_init
        STMFD   SP!, {R1-R12, LR}        ; Save registers
        
        LDR     R0, =SYSTEMCALLTBL
        
        IMPORT  _kalloc
        LDR     R1, =_kalloc
        STR     R1, [R0, #SYS_MALLOC*4]

        IMPORT  _kfree
        LDR     R1, =_kfree
        STR     R1, [R0, #SYS_FREE*4]

        IMPORT  _signal_handler
        LDR     R1, =_signal_handler
        STR     R1, [R0, #SYS_SIGNAL*4]

        IMPORT  _timer_start
        LDR     R1, =_timer_start
        STR     R1, [R0, #SYS_ALARM*4]

	; restore registers and return
        LDMFD   SP!, {R1-R12, LR}        
        MOV     PC, LR                   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT  _syscall_table_jump
_syscall_table_jump
        STMFD   SP!, {R1-R12, LR}        ; Save registers
        
        LDR     R1, =SYSTEMCALLTBL
        LDR     R2, [R1, R0, LSL #2]     ; Load address of the system call from the table
        BX      R2                       ; Jump to the system call routine
        
	; restore registers and return
        LDMFD   SP!, {R1-R12, lr}        
        MOV     pc, lr                   

        END



		

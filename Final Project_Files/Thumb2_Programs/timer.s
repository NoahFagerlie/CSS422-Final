        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL          EQU     0xE000E010      ; SysTick Control and Status Register
STRELOAD        EQU     0xE000E014      ; SysTick Reload Value Register
STCURRENT       EQU     0xE000E018      ; SysTick Current Value Register

STCTRL_STOP     EQU     0x00000004      ; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO       EQU     0x00000007      ; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX     EQU     0x00FFFFFF      ; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR      EQU     0x00000000      ; Clear STCURRENT and STCTRL.COUNT
SIGALRM         EQU     14              ; sig alarm

; System Variables
SECOND_LEFT     EQU     0x20007B80      ; Seconds left for alarm()
USR_HANDLER     EQU     0x20007B84      ; Address of a user-given signal handler function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
        EXPORT          _timer_init
_timer_init
        LDR     R1, =STCTRL             ; Address of SysTick control register
        MOV     R0, #0                  ; Disable SysTick
        STR     R0, [R1]                ; Write to disable register
        LDR     R1, =STCURRENT          ; Address of SysTick current value register
        STR     R0, [R1]                ; Clear current value
        LDR     R1, =STRELOAD           ; Address of SysTick reload register
        STR     R0, [R1]                ; Clear reload value
        BX      LR                      ; Return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
        EXPORT          _timer_start
_timer_start
        LDR     R1, =SECOND_LEFT        ; Address of seconds left variable
        STR     R0, [R1]                ; Store the input seconds to SECOND_LEFT
        LDR     R1, =STRELOAD           ; Address of SysTick reload register
        LDR     R2, =STRELOAD_MX        ; Maximum reload value (1 second)
        STR     R2, [R1]                ; Set reload value
        LDR     R1, =STCTRL             ; Address of SysTick control register
        LDR     R2, =STCTRL_GO          ; Enable timer
        STR     R2, [R1]                ; Start SysTick
        BX      LR                      ; Return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
        EXPORT          _timer_update
_timer_update
        LDR     R1, =SECOND_LEFT        ; Address of seconds left
        LDR     R2, [R1]                ; Load remaining seconds
        SUBS    R2, R2, #1              ; Decrement by 1
        STR     R2, [R1]                ; Store the updated value
        CMP     R2, #0                  ; Check if time is up
        BGT     _timer_update_exit      ; Exit if time is not up

        ; Time is up, call user-defined signal handler
        LDR     R3, =USR_HANDLER        ; Address of user handler
        LDR     R4, [R3]                ; Load user handler function
        CMP     R4, #0                  ; Check if handler is set
        BEQ     _timer_update_exit      ; Exit if no handler
        BLX     R4                      ; Call user handler

_timer_update_exit
        BX      LR                      ; Return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Signal Handler
; void* signal_handler( int signum, void* handler )
        EXPORT          _signal_handler
_signal_handler
        CMP     R0, #SIGALRM            ; Check if the signal is SIGALRM
        BNE     _signal_handler_exit    ; Exit if not SIGALRM

        LDR     R3, =USR_HANDLER        ; Address of user handler storage
        LDR     R2, [R3]                ; Load current handler
        STR     R1, [R3]                ; Store new handler

_signal_handler_exit
        MOV     R0, R2                  ; Return the previous handler
        BX      LR                      ; Return to Reset_Handler

        END

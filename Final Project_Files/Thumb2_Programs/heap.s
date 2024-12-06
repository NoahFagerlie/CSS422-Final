		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself
	
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
		MOV		pc, lr
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
        EXPORT  _kfree
_kfree
        PUSH    {lr}               ; Save LR
        CMP     R0, #0             ; Check if ptr is NULL
        BEQ     kfree_end          ; If NULL, nothing to free

        LDR     R1, =MCB_TOP       ; Load MCB_TOP address into R1
        LDR     R2, =MCB_BOT       ; Load MCB_BOT address into R2

kfree_loop
        CMP     R1, R2             ; Compare current MCB entry with MCB_BOT
        BHI     kfree_end          ; If reached the end, done

        LDRH    R3, [R1]           ; Load MCB entry
        CMP     R3, R0             ; Compare with ptr
        BNE     kfree_next         ; If not matching, check next entry

        ; Free the block
        MOVS    R3, #0             ; Clear the entry
        STRH    R3, [R1]           ; Store 0 in MCB

kfree_next
        ADD     R1, R1, #2         ; Move to next MCB entry
        B       kfree_loop         ; Repeat to find the block

kfree_end
        POP     {lr}               ; Restore LR
        MOV     pc, lr             ; Return

        END


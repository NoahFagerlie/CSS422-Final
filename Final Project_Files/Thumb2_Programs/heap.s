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

; _kinit (heap_init): The initialization must writes 1638410 (0x4000) onto mcb[0] at 0x20006800-0x20006801, indicating that the entire 16KB space is available. All the other mcb entries from 0x20006802 to 0x20006BFE must be zero-initialized (step 1 in figure 2).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself

		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size ) CURRENTLY UNTESTED
                EXPORT _kalloc
_kalloc
    PUSH {r4-r7, lr}         ; Save registers and link register
    MOV r4, r0               ; Store requested size in r4
    BL _align_to_power_of_2  ; Align size to nearest power of 2
    MOV r5, r0               ; Store aligned size in r5
    LDR r6, =MCB_TOP       ; Load the start of the mcb
    LDR r7, =MCB_BOT         ; Load the end of the mcb
    BL _find_and_allocate    ; Find and allocate memory
    POP {r4-r7, pc}          ; Restore registers and return

_align_to_power_of_2
    ; Aligh R0 (size) to the nearest power of 2
    MOV r1, #1               ; Start with 1 (2^0)
align_loop
    CMP r0, r1               ; Compare size with current power of 2
    BLS aligned              ; If size <= power of 2, it’s aligned
    LSL r1, r1, #1           ; Shift left (multiply by 2)
    B align_loop             ; Repeat
aligned
    MOV r0, r1               ; Return aligned size
    MOV pc, lr               ; Return

_find_and_allocate
    ; Find a block in the MCB and allocate it
    ; Inputs:
    ;   R0: size
    ;   R6: start of MCB (top)
    ;   R7: end of MCB (bottom)
    ; Output:
    ;   R0: Address of allocated memory, or 0 if failed

find_loop
    CMP r6, r7               ; Check if we've reached the end
    BHI fail                 ; If so, fail
    LDRH r2, [r6]            ; Load current MCB entry (16 bits)

    ; Check if the block is available and big enough
    ANDS r3, r2, #1          ; Check availability (LSB)
    BNE next_block           ; Skip if not available
    LSR r3, r2, #4           ; Extract block size (bits 15-4)
    CMP r3, r0               ; Compare block size to requested size
    BLT next_block           ; Skip if block is too small

    ; Allocation!
    MOV r3, r2               ; Copy the current MCB entry
    ORR r3, r3, #1           ; Mark as allocated (set LSB)
    STRH r3, [r6]            ; Update MCB entry

    ; Calculate the block's memory address
    SUB r3, r6, MCB_TOP    ; Offset of MCB entry
    LSL r3, r3, #5           ; Multiply offset by 32 (block size)
    ADD r0, HEAP_TOP, r3   ; Base address of allocated block
    BX lr                    ; Return allocated address

next_block
    ADD r6, r6, #2           ; Move to the next MCB entry
    B find_loop

fail
    MOV r0, #0
    BX lr




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


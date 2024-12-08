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
		EXPORT	_kinit
_kinit
    EXPORT _kinit

    STMFD sp!, {r1-r12, lr}       ; Save registers

    LDR R4, =MCB_TOP              ; Start of the MCB
    LDR R5, =MAX_SIZE             ; Maximum heap size in blocks
    MOV R1, #0x4000               ; Entire heap as free (16384 bytes)
    STRH R1, [R4]                 ; Initialize MCB[0] with 0x4000

    ; Zero out remaining MCB entries
    ADD R0, R4, #2                ; Start from MCB[1] (0x20006802)
    LDR R6, =MCB_BOT              ; End of the MCB (0x20006BFE)

clear_loop
    CMP R0, R6                    ; Check if we've reached the end
    BGE done                      ; If so, exit the loop
    MOV R3, #0                    ; Write zero
    STRH R3, [R0]                 ; Store to current MCB entry
    ADD R0, R0, #2                ; Move to the next MCB entry
    B clear_loop                  ; Repeat

done
    LDMFD sp!, {r1-r12, lr}       ; Restore registers
    BX LR                         ; Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
                EXPORT _kalloc
_kalloc
	STMFD	sp!, {r1-r12,lr}  ; Save registers and link register
    MOV R4, R0               ; Store requested size in r4
    BL _align_to_power_of_2  ; Align size to nearest power of 2
    MOV R5, R0               ; Store aligned size in r5
    LDR R6, =MCB_TOP       	; Load the start of the mcb
    LDR R7, =MCB_BOT         ; Load the end of the mcb
    BL _ralloc    ; Find and allocate memory
    LDMFD sp!, {r1-r12,lr}          ; Restore registers and return

_align_to_power_of_2
    ; Aligh R0 (size) to the nearest power of 2
    MOV R1, #1               ; Start with 1 (2^0)
align_loop
    CMP R0, R1               ; Compare size with current power of 2
    BLS aligned              ; If size <= power of 2, it’s aligned
    LSL R1, R1, #1           ; Shift left (multiply by 2)
    B align_loop             ; Repeat
aligned
    MOV R0, R1               ; Return aligned size
    MOV PC, LR               ; Return

_ralloc
    ; Inputs:
    ;   R0: size (aligned size)
    ;   R6: start of MCB (MCB_TOP)
    ;   R7: end of MCB (MCB_BOT)
    ; Output:
    ;   R0: Address of allocated memory, or 0 if failed

find_loop
    CMP R6, R7               ; Check if we've reached the end
    BHI fail                 ; If top of MCB > bottom of MCB then we failed

    LDRH R2, [R6]            ; Load current MCB entry (MCB[i] (16 bits))

    ; Check if the block is available and big enough
    AND R3, R2, #1           ; Extract availability (LSB)
    CMP R3, #0               ; Check if block is free
    BNE next_block           ; If not free, skip

    LSR R3, R2, #4           ; Extract block size (bits 15–4)
    CMP R3, R0               ; Compare block size to requested size
    BLT next_block           ; If block is too small, skip

    ; Allocate the block
    MOV R3, R2               ; Copy current MCB entry
    ORR R3, R3, #1           ; Mark as allocated (set LSB)
    STRH R3, [R6]            ; Update MCB entry

    ; Calculate the address of the allocated block
    LDR R4, =MCB_TOP
    SUB R3, R6, R4           ; Offset of MCB entry
    LSL R3, R3, #5           ; Multiply offset by 32 (block size)

    LDR R4, =HEAP_TOP
    ADD R0, R4, R3           ; Base address of allocated block
    BX LR                    ; Return allocated address

next_block
    ADD R6, R6, #2           ; Move to the next MCB entry
    B find_loop

fail
    MOV R0, #0               ; No suitable block found
    BX LR




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
        EXPORT  _kfree
_kfree
        STMFD	sp!, {r1-r12,lr}
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
        LDMFD sp!, {r1-r12,lr}               ; Restore LR
        MOV     pc, lr             ; Return

        END


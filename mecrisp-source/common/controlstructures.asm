;
;    Mecrisp - A native code Forth implementation for MSP430 microcontrollers
;    Copyright (C) 2011  Matthias Koch
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

; Jumps, Utilities and Control Structures

;------------------------------------------------------------------------------
; --- Jumps and Utilities ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "jump," ; Write a jump into dictionary
jumpgenerator: ; ( Address-of-hole-for-jump Target Bitmask -- )
;------------------------------------------------------------------------------
  mov 2(r4), r7
  sub 4(r4), r7 ; Difference of address of hole and target
  decd r7       ; -2 to adjust for current instruction

  push r7
  ; Check if jump distance is within possible range. Check also for uneven distances...
  and #1111110000000001b, r7
  jz + ; If zero, positive distances are ok.

  cmp #1111110000000000b, r7
  je + ; If equal, negative distances are ok.

  writeln "Jump too far"
  br #quit ; As quit resets stacks, we don't have to tidy up here.

+ ; Distance is valid. Go on.
  pop r7
  ; clrc  ; This bit is shifted into MSB, but as it is cleared by and-mask anyway...
  rrc r7 ; Divide distance in bytes by two because jumps have a 10 Bit Word-Offset
  ;    9876543210
  and #1111111111b, r7 ; Apply mask

  ; Assemble Opcode and prepare stack
  bis r7, @r4
  ; ( Address-of-hole-for-jump Target Opcode -- )
  mov 4(r4), r7 ; Fetch Address-of-hole-for-jump

  push &DictionaryPointer      ; Write the jump with the help of ,
  mov r7, &DictionaryPointer  ; as this is the easiest way to handle writing into Ram or Flash.
  call #komma
  pop &DictionaryPointer

  add #4, r4 ; 2drop
  ret

;------------------------------------------------------------------------------.
; Some jump primitives that are useful for building control structures
;------------------------------------------------------------------------------

branch_r:     ; ( -- Target ) "branch<--"  ; Intro of conditional and unconditional backwards jump
    pushda &DictionaryPointer
    ret

r_branch_jnz:
    push #02000h ; Opcode for conditional jump jnz
    jmp +

r_nullbranch: ; ( Target -- ) "<--0branch" ; Finalisation of conditional backwards jump
    call #nullprobekomma
    push #0010010000000000b ; Opcode for conditional jump jz
    jmp +

r_branch:     ; ( Target -- ) "<--branch" ; Finalisation of unconditional backwards jump
    push #0011110000000000b ; Opcode for unconditional jump jmp
+   call #branch_v    ; pushdadouble &DictionaryPointer, #2
                      ; call #allot
    call #swap_sprung ; swap
    r_from
    jmp jumpgenerator

nullbranch_v: ; ( -- Address-for-Opcode ) "0branch-->" ; Intro of conditional forward jump
    call #nullprobekomma
branch_v:     ; ( -- Address-for-Opcode ) "branch-->"  ; Intro of unconditional forward jump
    pushda &DictionaryPointer
    br #zwei_allot

v_casebranch:
    push #02000h ; Opcode für einen bedingten Sprung jnz
    jmp +

v_nullbranch: ; ( Address-for-Opcode -- ) "-->0branch" ; Finalisation of conditional forward jump
    push #0010010000000000b ; Opcode for conditional jump jz
    jmp +

v_branch:     ; ( Address-for-Opcode -- ) "-->branch" ; Finalisation of unconditional forward jump
    push #0011110000000000b ; Opcode for unconditional jump jmp
+   pushdadouble &DictionaryPointer, @sp+
    jmp jumpgenerator

;------------------------------------------------------------------------------
; --- Control Structures ---
;------------------------------------------------------------------------------

Strukturpaar macro Marke ; Simple syntax checking
               mov @r4+, r7
               cmp #Marke, r7
               jne strukturen_passen_nicht
             endm

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "then"
  ; ( -- Address-for-Jump 2 | Address-for-Jump 5 )
;------------------------------------------------------------------------------
  mov @r4+, r7
  cmp #5, r7 ; Coming from else
  je v_branch
+ cmp #2, r7 ; Coming directly from if
  je v_nullbranch

strukturen_passen_nicht:
  writeln "Structures don't match"
  br #quit

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "else"
  ; ( Address-for-Jump 2 -- Address-for-Jump 5 )
;------------------------------------------------------------------------------
  ; Else macht es ein kleines bisschen Komplizierter.
  ; Bedingung  if           [true]    else                  [false]   then      Folgendes.
  ;            0branch-->             branch--> -->0branch            -->branch

  Strukturpaar 2

  ; ( Conditional-Jump )
  call #branch_v
  ; ( Conditional-Jump Unconditional-Jump )
  call #swap_sprung
  ; ( Unconditional-Jump Conditional-Jump )
  call #v_nullbranch
  ; ( Unconditional-Jump )
  pushda #5 ; For structure matching
  ; ( Unconditional-Jump 5 )
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "if"
struktur_if: ; ( -- Address-for-Jump 2 )
;------------------------------------------------------------------------------
  call #nullbranch_v
  pushda #2           ; For structure matching
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "repeat"
  ; ( Target Address-for-Jump 4 -- )
;------------------------------------------------------------------------------
  ; begin (Flag) while (To Do) repeat

  ; ( Target-Beginning Address-for-jump-to-End 4 )
  Strukturpaar 4
  ; ( Target-Beginning Address-for-jump-to-End )
  call #swap_sprung
  ; ( Address-for-jump-to-End Target-Beginning )
  call #r_branch ; Write jump back to beginning into dictionary
  ; ( Address-for-jump-to-End )
  jmp v_nullbranch ; Write exit of structure into dictionary

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "while"
  ; ( Target 1 -- Target Address-for-Jump 4 )
;------------------------------------------------------------------------------
  ; begin (Flag) while (To Do) repeat

  Strukturpaar 1
  ; ( Target ) Used for jump back later
  call #struktur_if ; Simply use if to generate the needed code
  ; ( Target Address-for-Jump 2 )
  add #2, @r4
  ; ( Target Address-for-Jump 4 ) ; Syntax matching with 4 !
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "until"  ; Conditional Loop
  ; ( Target 1 -- )
;------------------------------------------------------------------------------
  Strukturpaar 1
  jmp r_nullbranch

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "again"  ; Infinite Loop
  ; ( Target 1 -- )
;------------------------------------------------------------------------------
  Strukturpaar 1
  jmp r_branch

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "begin"
  ; ( -- Target 1 )
;------------------------------------------------------------------------------
  call #branch_r
  pushda #1       ; For syntax matching
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "exit" ; Writes a ret opcode into current definition. Take care with inlining !
;------------------------------------------------------------------------------
  br #retkomma

  ; Loop indexes are valid within loops only and they are inserted inline for speed.
;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "k" ; Third loop index
;------------------------------------------------------------------------------
  ; Returnstack ( Limit Index Limit Index )
  pushda 4(sp)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "j" ; Second loop index
;------------------------------------------------------------------------------
  ; Returnstack ( Limit Index )
  pushda @sp
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "i" ; First loop index
;------------------------------------------------------------------------------
  ; Returnstack ( )
  pushda r5 ; Always in register.
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "unloop" ; Remove loop structure from returnstack
unloop:
;------------------------------------------------------------------------------
  pop r5  ; Fetch back old loop values
  pop r6
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "leave" ; Terminates loop immediately.
  ; ( ... OldLeavePointer 0 Target 3 ... )
  ; --
  ; ( ... OldLeavePointer Forward-Jump-Target{or-1-JZ} NumberofJumps Target 3 ... )
;------------------------------------------------------------------------------
  ; LeavePointer points to the location which counts the number of jumps that have to be inserted later.
  ; Leave moves all elements of stack further, inserts address for jump opcode, increments counter and allots space.

  push #0  ; Denotes that we need an unconditional jump.

leave_bedingt:
  ; Shift stack.
  mov r4, r7
  decd r4 ; One more element

- mov @r7, -2(r7)
  incd r7
  cmp r7, &leavepointer
  jne -

  mov @r7, -2(r7) ; One last time
  ; All elements are shifted, we have a hole in stack now.

  inc -2(r7) ; One more jump !
  mov &DictionaryPointer, @r7 ; Put DictionaryPointer into the hole on stack
  bis @sp+, @r7               ; Mark (un)conditional jumps

  decd &leavepointer ; Update leavepointer as its position shifted
  br #zwei_allot     ; Prepare hole to insert jump opcode later into.

; ANS:
; Discard the current loop control parameters. An ambiguous condition exists if they are unavailable.
; Continue execution immediately following the innermost syntactically enclosing DO ... LOOP or DO ... +LOOP.

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "+loop" ; Usage: ( Increment -- ).
  ; ( Target 3 -- ) without leave
  ; ( OldLeavePointer ... NumberofJumps Target 3 -- ) with leave
;------------------------------------------------------------------------------
  Strukturpaar 3

  pushda #struktur_doplusloop_intern ; Insert +loop structure as call, this is shorter than inlining it completely.
  call #callkomma

  call #r_branch

  jmp loop_generator_spaeter


struktur_doplusloop_intern:
  ; Increment Index.
  ; If Limit is reached or skipped, terminate and unloop.

  add #8000h, r5 ; Index + $8000
  sub r6, r5     ; Index + $8000 - Limit

  add @r4+, r5   ; Index + $8000 - Limit + Increment

  bit #100h, sr  ; Check overflow flag here

  jnc +           ; Terminate on overflow
    incd @sp      ; Skip unconditional jump after this call entry.
+

  add r6, r5     ; Index + $8000 + Increment
  sub #8000h, r5 ; Index + Increment

  ret

; ANS: Add n to the loop index. If the loop index did not cross the boundary between
; the loop limit minus one and the loop limit, continue execution at the beginning of
; the loop. Otherwise, discard the current loop control parameters and continue execution
; immediately following the loop.
; Problem is that Limit can be skipped from both sides !

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "loop" ; Usage: ( -- ).
  ; ( Target 3 -- ) without leave
  ; ( OldLeavePointer ... NumberofJumps Target 3 -- ) with leave
;------------------------------------------------------------------------------
  Strukturpaar 3

  pushdadouble #09506h, #05315h  ; inc r5      ; Increment Index
  call #doppelkomma              ; cmp r5, r6  ; Compare to Limit

  call #r_branch_jnz

loop_generator_spaeter:
  call #spruenge_einpflegen ; Same code as in endcase

  mov @r4, &leavepointer ; Fetch back leave pointer for old loop structure
  mov #unloop, @r4 ; Insert: pop r5
  br #inlinekomma  ;         pop r6

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly|Flag_opcodierbar_spezialfall, "?do" ; Usage: ( Limit Index -- ).
  ; ( -- OldLeavePointer Forward-Jump-Target 1 Target 3 )
  ; This loop terminates immediately if Limit=Index.
;------------------------------------------------------------------------------
  call #do_anfang ; Start a normal do loop !

  ; ( ... Target 3 )
  ; As ?do inserts a comparision now, we have to advance the loop target.

qdo_inneneinsprung:
  ; ( OldLeavePointer 0 Target 3 )
  add #4, 2(r4) ; Advance Target by space needed for comparision and jump

  pushda #09506h ; cmp r5, r6   ; Index = Limit ?
  call #komma

  push #1  ; Denotes that we need a conditional jump

  jmp leave_bedingt
  ret ; Only to denote entry for special optimization handler
  ;------------------------------------------------------------------------------
  ; Special case: Compile with at least one folding constant available
    call #do_opcodierung
    jmp qdo_inneneinsprung

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly|Flag_opcodierbar_spezialfall, "do" ; Usage: ( Limit Index -- ).
  ; ( -- Target 3 ) without leave
  ; ( -- OldLeavePointer 0 Target 3 ) with leave
;------------------------------------------------------------------------------
do_anfang:
  pushda #struktur_do
  call #inlinekomma

do_inneneinsprung:
  pushdadouble &leavepointer, #0
  mov r4, &leavepointer ; Save current position of stack pointer

  call #branch_r ; Prepare backwards loop jump
  pushda #3      ; For syntax matching
  ret

  ;------------------------------------------------------------------------------
  ; Special case: Compile with at least one folding constant available
do_opcodierung:
    mov #struktur_do, r12
    call #inline_at_r4_plus
    jmp do_inneneinsprung

struktur_do:
  push r6
  push r5
  popda r5
  popda r6
  ret

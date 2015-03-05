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

; Datastack - a second stack, emulated, but interrupt-proof.

  padding on ; Strings sometimes need an extra padding zero so that instructions are aligned.


popda           macro   dst         ; Fetch from datastack - 2 Bytes
                  mov     @r4+, dst ; Increment stackpointer by two after fetching content.
                endm


pushda          macro   src        ; Put something on datastack - 8 Bytes
                  decd r4          ; Adjust stack pointer
                  mov src, @r4     ; and put value in.
                endm

pushdadouble    macro   src1, src2 ; Put two elements at once on datastack.
                  sub #4, r4         ; Adjust stack pointer
                  mov src1, 2(r4)    ; and put values in.
                  mov src2, 0(r4)
                endm

; Datastack not designed for byte access...

; DUP ( n -- n n ) Duplicates the top stack item.
dup             macro
                  pushda 2(r4)
                endm

ddup            macro
                  sub #4, r4
                  mov 4(r4), 0(r4)
                  mov 6(r4), 2(r4)
                endm

; OVER ( n1 n2 -- n1 n2 n1 ) Makes a copy of the second item and pushes it on top.
over            macro
                  pushda 4(r4)
                endm

; SWAP ( n1 n2 -- n2 n1 ) Reverses the top two stack items.
;swap            macro
;                  push 2(r4)         ; ( B A ) R : B
;                  mov @r4,   2(r4)   ; ( A A ) R : B
;                  pop @r4            ; ( A B ) R : B
;                endm

swap          macro ; Same length, other way
                 mov @r4, r7        ; ( B A ) r7 : A
                 mov 2(r4), @r4     ; ( B B ) r7 : A
                 mov r7, 2(r4)      ; ( A B ) r7 : A
               endm

; ROT ( n1 n2 n3 -- n2 n3 n1 ) Rotates the third item to the top.
; rot rot rot is identity.
rot             macro                ; ( 1 2 3 )
                  mov @r4, r7        ; ( 1 2 3 ) R: 3
                  mov 4(r4), 0(r4)   ; ( 1 2 1 ) R: 3
                  mov 2(r4), 4(r4)   ; ( 2 2 1 ) R: 3
                  mov r7, 2(r4)      ; ( 2 3 1 ) R: 3
                endm

minusrot        macro                ; ( 1 2 3 )
                  mov @r4, r7        ; ( 1 2 3 ) R: 3
                  mov 2(r4), 0(r4)   ; ( 1 2 2 ) R: 3
                  mov 4(r4), 2(r4)   ; ( 1 1 2 ) R: 3
                  mov r7, 4(r4)      ; ( 3 1 2 ) R: 3
                endm

; DROP ( n -- ) Discards the top stack item.
drop            macro ; 2 Bytes long
                  incd r4
                endm

ddrop           macro ; 2 Bytes long
                  add #4, r4
                endm

; NIP ( x1 x2 -- x2 ) Drop the first item below the top of stack.
nip             macro
                  mov @r4+, 0(r4) ; Deletes second element of stack.
                endm

; Fetch and store on second stack - Returnstack
to_r            macro ; >R  2 Bytes long
                  push @r4+
                endm

r_from          macro ; R>  4 Bytes long
                  pushda @sp+
                endm

; Fast calculations

plus		macro
                  add @r4+, 0(r4)  ; Add top two elements of stack
                endm

minus           macro
                  sub @r4+, 0(r4)
                endm

negate          macro ; Flip sign
                  inv @r4
                  inc @r4
                endm

abs             macro ; Calculate absolute value
                  bit #8000h, @r4
                  jnc +
                  negate
+
                endm

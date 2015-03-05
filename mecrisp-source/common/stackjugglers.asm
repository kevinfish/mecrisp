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

; Everything useful to juggle stacks.

;------------------------------------------------------------------------------
; --- Double stack jugglers ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "2nip"
doppelnip:
  mov @r4+, 2(r4)
  mov @r4+, 2(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_2, "2drop"
  add #4, r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_6, "2-rot" ; ( 1a 1b 2a 2b 3a 3b -- 3a 3b 1a 1b 2a 2b )
  ; Rotates backwards.                                10 8  6  4  2  0  Position on Stack

  mov @r4, r7        ; ( 1 2 3 ) R7: 3
  mov 4(r4), @r4     ; ( 1 2 2 ) R7: 3
  mov 8(r4), 4(r4)   ; ( 1 1 2 ) R7: 3
  mov r7, 8(r4)      ; ( 3 1 2 ) R7: 3

  mov 2(r4), r7      ; ( 1 2 3 ) R7: 3
  mov 6(r4), 2(r4)   ; ( 1 2 2 ) R7: 3
  mov 10(r4), 6(r4)  ; ( 1 1 2 ) R7: 3
  mov r7, 10(r4)     ; ( 3 1 2 ) R7: 3

  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_6, "2rot" ; ( 1a 1b 2a 2b 3a 3b -- 2a 2b 3a 3b 1a 1b )
  ; Rotates third element to top.                    10 8  6  4  2  0  Position on Stack

  mov @r4, r7        ; ( 1 2 3 ) R7: 3
  mov 8(r4), 0(r4)   ; ( 1 2 1 ) R7: 3
  mov 4(r4), 8(r4)   ; ( 2 2 1 ) R7: 3
  mov r7, 4(r4)      ; ( 2 3 1 ) R7: 3

  mov 2(r4), r7      ; ( 1 2 3 ) R7: 3
  mov 10(r4), 2(r4)  ; ( 1 2 1 ) R7: 3
  mov 6(r4), 10(r4)  ; ( 2 2 1 ) R7: 3
  mov r7, 6(r4)      ; ( 2 3 1 ) R7: 3

  ret  ; 2rot 2rot 2rot is identity

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "2tuck" ; ( 1a 1b 2a 2b -- 2a 2b 1a 1b 2a 2b )
                                                  ;   6  4  2  0     10  8  6  4  2  0 Position on Stack
  over ;   10  8  6  4  2  0
  over ; ( 1a 1b 2a 2b 2a 2b )

  mov  8(r4), 4(r4) ;   10  8  6  4  2  0
  mov 10(r4), 6(r4) ; ( 1a 1b 1a 1b 2a 2b )

  mov @r4, 8(r4)
  mov 2(r4), 10(r4)

  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "2swap"
dswap:  ; Rearranged to get lower stack depth
  mov @r4, r7
  mov 4(r4), @r4
  mov r7, 4(r4)

  mov 2(r4), r7
  mov 6(r4), 2(r4)
  mov r7, 6(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "2over"
  sub #4, r4
  mov  8(r4), 0(r4)
  mov 10(r4), 2(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "2dup"
  sub #4, r4
  mov 4(r4), 0(r4)
  mov 6(r4), 2(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2>r" ; Puts the two top elements of stack on returnstack.
                                ; Equal to swap >r >r
;------------------------------------------------------------------------------
  ; ( R: Return )
  sub #4, sp
  ; ( R: Space Space )
  mov 4(sp), 0(sp)
  ; ( R: Return Space Return )
  mov @r4+, 2(sp)
  mov @r4+, 4(sp)
  ; ( R: Low High Return )
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2r>" ; Fetches back two elements of returnstack.
zwei_r_from:                    ; r> r> swap
;------------------------------------------------------------------------------
  ; ( R: Low High Return )
  sub #4, r4
  mov 2(sp), @r4
  mov 4(sp), 2(r4)

  mov @sp, 4(sp)
  add #4, sp
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2r@" ; Copies the two top elements of returnsteack
;------------------------------------------------------------------------------
  ; ( R: Low High Return )
  sub #4, r4
  mov 2(sp), @r4
  mov 4(sp), 2(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "2rdrop" ; Removes two elements of return stack
;------------------------------------------------------------------------------
  add #4, sp
  ret

;------------------------------------------------------------------------------
; --- Stack jugglers ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "depth" ; ( -- Number of elements that have been on stack before calling this )
  mov #datenstackanfang, r7
  sub r4, r7
  clrc
  rrc r7
  pushda r7
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "pick"
  mov @r4, r7
  inc r7
  rla r7
  add r4, r7
  mov @r7, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_2, "nip"
  nip
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "drop"
drop_vektor:
  drop
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "rot"
  rot
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "-rot"
  minusrot
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "swap"
swap_sprung:
  swap
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "tuck" ; ( x1 x2 -- x2 x1 x2 )
tuck:
  decd r4            ;  ( 2  0  --  4  2  0 )
  mov 2(r4), 0(r4)
  mov 4(r4), 2(r4)
  mov @r4, 4(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "over"
  over
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "?dup"
  tst @r4
  jnz +
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "dup"
+ dup
  ret

;------------------------------------------------------------------------------
; --- Returnstack ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, ">r" ; Puts TOS on returnstack, inline only !
;------------------------------------------------------------------------------
  push @r4+
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "r>" ; Fetches back from returnstack, inline only !
;------------------------------------------------------------------------------
  pushda @sp+
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "r@" ; Copies the top element of returnstack, inline only !
;------------------------------------------------------------------------------
  pushda @sp
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "rdrop" ; Removes the top element of return stack, inline only !
;------------------------------------------------------------------------------
  incd sp
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "rdepth" ; ( -- Number of elements that have been on return stack before calling this )
;------------------------------------------------------------------------------
  mov #returnstackanfang, r7
  sub sp, r7
  clrc
  rrc r7
  pushda r7
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "rpick"
;------------------------------------------------------------------------------
  mov @r4, r7
  rla r7
  add sp, r7
  mov @r7, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "sp@"
;------------------------------------------------------------------------------
  mov r4, r7
  decd r4
  mov r7, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "sp!"
;------------------------------------------------------------------------------
  mov @r4, r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "rp@"
;------------------------------------------------------------------------------
  pushda sp
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_inline, "rp!"
;------------------------------------------------------------------------------
  popda sp
  ret

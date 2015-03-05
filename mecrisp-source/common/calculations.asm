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

; Small calculations with 16 bits and number base

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "min" ; Keeps the signed smaller of the two top elements
  popda r7
  cmp @r4, r7
  jge +
  mov r7, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "max" ; Keeps the signed greater of the two top elements
  popda r7
  cmp @r4, r7
  jl +
  mov r7, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "umin" ; Keeps the unsigned smaller of the two top elements
  popda r7
  cmp @r4, r7
  jhs +
  mov r7, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "umax" ; Keeps the unsigned greater of the two top elements
  popda r7
  cmp @r4, r7
  jlo +
  mov r7, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "2-"
  decd @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "1-"
  dec @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "2+"
  incd @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "1+"
  inc @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "even"
  bit #1, @r4
  adc @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "2*"
  rla @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "2/"
  rra @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "abs" ; Absolute value
  tst @r4
  jn +
  ret

;------------------------------------------------------------------------------
;  Wortbirne Flag_visible|Flag_foldable_2, "?negate" ; Negate number, if TOS is negative
;  add @r4+, -2(r4)   ; Emulated rla @r4+ - Shifts MSB into carry.
;  jc +
;  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "negate" ; Negate number
+ inv @r4
  inc @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_opcodierbar_rechenlogik, "-"
  minus
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_opcodierbar_rechenlogik, "+"
  plus
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "binary"
  mov #2, &Base
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "decimal"
  mov #10, &Base
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "hex"
  mov #16, &Base
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "base"
  CoreVariable base
;------------------------------------------------------------------------------
  pushda #base
  ret
  .word 10

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "cells"
;------------------------------------------------------------------------------
  rla @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "cell+"
;------------------------------------------------------------------------------
  incd @r4
  ret

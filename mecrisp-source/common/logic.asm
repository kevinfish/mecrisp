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

; Logic functions

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "><" ; Swap Bytes.
  swpb @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "arshift" ; ( x u -- x ) Shifts x right with sign for u places

  clr r7
  xor @r4+, r7 ; Fetch counter, like mov, but sets flags ! Important if there are 0 places to shift.
  jz +

- rra @r4
  jz +     ; Save cycles by stopping if value got zero.
  dec r7  ; Decrement counter and test
  jnz -

+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "rshift" ; ( x u -- x ) Shifts x right for u places

  clr r7
  xor @r4+, r7 ; Fetch counter, like mov, but sets flags ! Important if there are 0 places to shift.
  jz +

- clrc
  rrc @r4
  jz +     ; Save cycles by stopping if value got zero.
  dec r7  ; Decrement counter and test
  jnz -

+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "lshift" ; ( x u -- x ) Shifts x left for u places

  clr r7
  xor @r4+, r7 ; Fetch counter, like mov, but sets flags ! Important if there are 0 places to shift.
  jz +

- rla @r4
  jz +     ; Save cycles by stopping if value got zero.
  dec r7  ; Decrement counter and test
  jnz -

+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "shr"
  clrc
  rrc @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "shl"
  rla @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "ror"
  clrc
  rrc @r4
  jnc +
    bis #8000h, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "rol"
  rla @r4
  adc @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_opcodierbar_rechenlogik, "bic" ; Could be called "andnot"
  bic @r4+, 0(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_1, "not"
  inv @r4
  ret

;------------------------------------------------------------------------------
;  Wortbirne Flag_visible_inline|Flag_foldable_1, "invert" ; Simply another name for not
;  inv @r4
;  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_opcodierbar_rechenlogik, "xor"
  xor @r4+, 0(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_opcodierbar_rechenlogik, "or"
  bis @r4+, 0(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_opcodierbar_rechenlogik, "and"
  and @r4+, 0(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_0, "true"
  pushda #-1
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_0, "false"
  pushda #0
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "clz"
  mov #-1, r7
- inc r7
  setc
  rlc @r4
  jnc -
  mov r7, @r4
  ret

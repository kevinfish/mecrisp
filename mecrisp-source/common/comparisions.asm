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

; Comparision operators

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "u<="
  mov @r4+, r7
  cmp @r4, r7
  jmp +
;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "u>="
  cmp @r4+, @r4
+ subc @r4, @r4
  inv @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "u>"
  mov @r4+, r7
  cmp @r4, r7
  jmp +
;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_rechenlogik, "u<"
  cmp @r4+, @r4
+ subc @r4, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "<="
  mov @r4+, r7
  cmp @r4, r7
  jmp +
;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, ">="
  cmp @r4+, @r4
+ clr @r4
  jl +
  mov #-1, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, ">"
  mov @r4+, r7
  cmp @r4, r7
  jmp +
;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "<"
  cmp @r4+, @r4
+ clr @r4
  jge +
  mov #-1, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "0<"  ; Is number negative ?
  xor #08000h, @r4
  bit #n, sr        ; N-Flag is set, if both operands have been negative
  subc @r4, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "0<>"  ; Is number NOT zero ?
  cmp #0, @r4   ; Zero keeps Zero
  jz +
  mov #-1, @r4  ; Else put a clean -1 into
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "0="
  bit #-1, @r4   ; C is set if result of "and" is NOT zero
  subc @r4, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_rechenlogik, "<>"
  cmp @r4+, @r4
  bit #2, sr ; Check Z-Flag and put into Carry
  subc @r4, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_rechenlogik, "="
  xor @r4+, @r4  ; Equals to zero if both are same
  subc @r4, @r4
  ret

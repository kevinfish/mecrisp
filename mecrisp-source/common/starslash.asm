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

; Multiply and Divide

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "um*" ; This is u* in FIG Forth
um_star: ; Multiply unsigned 16*16 = 32
        ; ( u u -- d )
;------------------------------------------------------------------------------
  push r10 ; Result high
  push r11 ; Result low
  push r12 ; 1. Factor
  push r13 ; 2. Factor
  ;    r7  ; Counter

  mov @r4,   r12
  mov 2(r4), r13

  ; Multiply r12 * r13, Result in r10:r11
  clr r10 ; Clear result-high
  clr r11 ; Clear result-low
  mov #16, r7 ; Set loop counter
- rla r11 ; Last Result * 2
  rlc r10 ;   rotate...
  rla r13 ; Shift next bit into Carry-Flag
  jnc +
  add r12, r11
  adc r10
+ dec r7
  jnz -

  mov r11, 2(r4) ; Result low
  mov r10, 0(r4) ;        high

ende_pop_13_10:
  pop r13
  pop r12
  pop r11
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "u/mod"
u_divmod: ; Divide 16/16 = 16 Remainder 16. Never overflows.
;------------------------------------------------------------------------------
  ; ( Dividend Divisor -- Remainder Result )
  ;        2        0

  push r10 ; Dividend
  push r11 ; Shift-in register for dividend
  push r12 ; Divisor
  push r13 ; Result
  ;    r7  ; Counter

  clr r11 ; Clear shift register
  mov   @r4, r12 ; Dividend
  mov 2(r4), r10 ; Divisor

  ; No need to clear result at the beginning, as it is shifted in and 16 steps occupy all bits.

  mov #16, r7
- ; Loop
  ; Shift.
  rla r10 ; Shift dividend one bit at a time 
  rlc r11 ;                into shift register.

  cmp r12, r11 ; Compare shift register with divisor
  jhs +
  ; Smaller: Don't subtract.
  clrc    ; Zero for result
  jmp ++
+ ; Greater or equal: Subtract !
  sub  r12, r11
  setc    ; One for result
+ rlc r13 ; Rotate into result

  dec r7
  jnz -

  mov r13, 0(r4)
  mov r11, 2(r4)

  pop r13
  pop r12
  pop r11
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "/mod"
divmod: ; Signed symmetric divide
        ; ( Dividend Divisor -- Remainder Result )
;------------------------------------------------------------------------------
  push r10
  clr r10

  bit #8000h, 0(r4) ; Check divisor
  jnc +
    inc r10
    negate

+ bit #8000h, 2(r4) ; Check dividend
  push sr           ; Note if it has been negative !
  jnc +
    inc r10
    inv 2(r4) ; Negate second element on stack.
    inc 2(r4)
+

  call #u_divmod

  pop sr ; Fetch back sign of dividend
  jnc +
    inv 2(r4) ; Negate remainder, if dividend has been negative
    inc 2(r4)
+

  ; Set sign of result
  bit #1, r10
  jnc +
  negate
+
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "mod"
  ; ( Dividend Divisor -- Remainder )
;------------------------------------------------------------------------------
  call #divmod
  drop
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "/"
  ; ( Dividend Divisor -- Result )
;------------------------------------------------------------------------------
  call #divmod
  nip
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "*" ; Handles sign as long as no overflow occours
  call #um_star
  drop
  ret

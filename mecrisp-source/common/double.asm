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

; Calculations and comparisions with double numbers

;------------------------------------------------------------------------------
;--- Calculations with double numbers ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "*/" ; The Scalar ;-)
  ; ( n1 n2 n3 -- n1*n2/n3 ) With double intermediate result
;------------------------------------------------------------------------------
  call #starslashmod
  nip
  ret

; : u*/  ( u1 u2 u3 -- u1 * u2 / u3 )  >r um* r> um/mod nip 3-foldable ;
;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "u*/" ; The unsigned Scalar ;-)
  ; ( u1 u2 u3 -- u1*u2/u3 ) With double intermediate result
;------------------------------------------------------------------------------
  to_r
  call #um_star
  r_from
  call #um_slash_mod
  nip
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "*/mod"
 starslashmod: ; ( n1 n2 n3 -- Remainder n1*n2/n3 ) With double intermediate result
;------------------------------------------------------------------------------
  to_r
  call #mstar
  r_from
  jmp mslashmod

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "m/mod"
mslashmod:
  ; Signed symmetric divide of double numbers with remainder.
  ; Almost exactly like /mod
  ; ( Dividend Divisor -- Remainder Result )
              ; ( d n1 -- n2 n3 ) Signed Divide
              ;  32/16 = 16 Remainder 16
;------------------------------------------------------------------------------
  push r10
  clr r10

  bit #8000h, 0(r4) ; Check Divisor
  jnc +
    inc r10
    negate

+ bit #8000h, 2(r4) ; Check Dividend
  push sr           ; Note if it has been negative !
  jnc +
    inc r10

    to_r            ; Dnegate second element on stack
    call #dnegate
    r_from
+

  call #um_slash_mod

  pop sr ; Fetch back sign of dividend
  jnc +
    inv 2(r4) ; Negate remainder, if dividend has been negative
    inc 2(r4)
+

  ; Set sign of result.
  bit #1, r10
  jnc +
  negate
+
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "m*"
mstar:        ; ( n1 n2 -- d ) Signed Multiply
              ;  d= n1 * n2
;------------------------------------------------------------------------------
  ; Zuerst die einzelnen Teile vom Vorzeichen befreien und das Vorzeichen für das Ergebnis bestimmen.
  push r10
  clr r10
  xor 2(r4), r10 ; Set MSB for Negative
  bit #4, sr ; Flag N --> C
  jnc +
    inv 2(r4)  ; Negate
    inc 2(r4)
+
  xor @r4, r10 ; Set sign for result in r10
  bit #8000h, @r4 ; Check sign of second factor
  jnc +
    inv @r4
    inc @r4
+
  call #um_star

  rlc r10 ; r10 contains sign of result in MSB
  pop r10

  jc dnegate
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_3, "um/mod"
um_slash_mod: ; ( ud u -- u u ) Dividend Divisor -- Remainder Result
             ; 32/16 = 16 Remainder 16
             ; Sets Carry-Flag on overflow with result $FFFF.
;------------------------------------------------------------------------------
  ; Register usage:
  ; r12:r11 / r10 = r13, Remainder in r12, r7 Counter.
  push r10
  push r11
  push r12
  push r13

  popda r10      ; Divisor
  mov @r4, r12   ; Dividend - high
  mov 2(r4), r11 ;          - low

  clr r13
  mov #17, r7
- cmp r10, r12
  jlo +
  sub r10, r12
/ rlc r13
  jc ende_r12_r13_ergebnisse_auf_den_stack
  dec r7
  jz ende_r12_r13_ergebnisse_auf_den_stack
  rla r11
  rlc r12
  jnc --
  sub r10, r12
  setc
  jmp -

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "ud/mod"
ud_slash_mod: ; Divide 32/32 = 32 Remainder 32.
;------------------------------------------------------------------------------
  ; ( DividendL DividendH DivisorL DivisorH -- RemainderL RemainderH ResultL ResultH )
  ;   6         4         2        0

  push r10 ; Shift-in register for dividend low
  clr r10  ; Normally no shift of places. Used for s15.16 numbers !

ud_slash_mod_kommastellenverschiebung:
  push r11 ; Shift-in register for dividend high
  push r12 ; Result low
  push r13 ; Result high
  ;    r7  ; Counter

  push r15 ; To shift places. Needed for f/ and s15.16 numbers.
  mov r10, r15 ; Put it into correct register

  clr r10 ; Zero out dividend shift register
  clr r11

  ; No need to clear result at the beginning, as it is shifted in and 32 steps occupy all bits.

  mov #32, r7
- ; Loop
  ; Shift.
  rla 6(r4) ;  Low-part of Dividend
  rlc 4(r4) ; High-part of Dividend
  rlc r10   ;  Low-part of shift register
  rlc r11   ; High-part of shift register
  ; If an one is shifted out here, an overflow occoured.

  ; Shift decimal point places.
  tst r15
  jz +
  dec r15
  jmp -
+ ; This is used only once.

  ; Compare if shift register is greater or equal to dividend. Compilcated, as we have to compare 32 bit values.

  cmp 0(r4), r11 ; Compare shift-register-high with divisor-high
  jne + ; Jump if high-parts unequal
  ; Both are equal. Decide on low-parts.
  cmp 2(r4), r10 ; Compare shift-register-low with divisor-low
+ jhs + ; Jump to subtract
  ; Smaller: Don't subtract
  clrc    ; Zero for result
  jmp ++
+ ; Greater or Equal: Subtract !
  sub  2(r4), r10 ; Subtract divisor-low  of shift-register-low
  subc 0(r4), r11 ; Subtract divisor-high of shift-register-high with carry
  setc    ; One for result
+ rlc r12 ; Rotate into result: Low
  rlc r13 ;                     High.

  dec r7
  jnz -

  pop r15

ende_r10_r11_r12_r13_ergebnisse_auf_den_stack:
  mov r10, 6(r4)  ; Remainder low
  mov r11, 4(r4)  ; Remainder high
ende_r12_r13_ergebnisse_auf_den_stack:
  mov r12, 2(r4)  ; Result low
  mov r13, 0(r4)  ; Result high
  jmp ende_pop_13_10

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "udm*"
ud_star: ; Unsigned multiply 32*32 = 64
         ; ( ud ud -- 2*ud)
;------------------------------------------------------------------------------

  ; ( 1L 1H 2L 2H -- LL L H HH )
  ;    6  4  2  0
  ; Need a very long result register !


  push r10 ; Result (1) LSB
  push r11 ; Result (2)
  push r12 ; Result (3)
  push r13 ; Result (4) MSB
  ;    r7  ; Counter

  clr r10 ; Clear result register
  clr r11
  clr r12
  clr r13

  mov #32, r7 ; Initialize counter to how many loop counts are needed.

- ; Shift result left one bit
  rla r10 ; Last result * 2
  rlc r11 ;   rotate
  rlc r12 ;   rotate
  rlc r13 ;   rotate

  ; Shift factor left one bit
  rla 2(r4) ; 2. Factor low
  rlc 0(r4) ; 2. Factor high

  ; Check if a carry fell out
  jnc +
  ; An One fell out ? Then add 1. Factor to Result.
  add  6(r4), r10
  addc 4(r4), r11
  adc         r12
  adc         r13

+ dec r7
  jnz -

  jmp ende_r10_r11_r12_r13_ergebnisse_auf_den_stack

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "d2/"
  rra @r4   ; High-part first
  rrc 2(r4) ;  Low-part with carry
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "d2*"
  rla 2(r4) ;  Low-Part first
  rlc @r4   ; High-part with carry
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "dshr"
  clrc
  rrc @r4   ; High-part first
  rrc 2(r4) ;  Low-part with carry
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "dshl"
  rla 2(r4) ;  Low-Part first
  rlc @r4   ; High-part with carry
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "dabs"
dabs:
  tst @r4 ; Check sign in high-part
  jn dnegate
  ret ; Not negative ? Nothing to do !

;------------------------------------------------------------------------------
;  Wortbirne Flag_visible|Flag_foldable_3, "?dnegate" ; Negate a double number if top element on stack is negative.
;  add @r4+, -2(r4)   ; Emulated rla @r4+ - Shifts MSB into Carry and removes value from stack
;  jc dnegate
;  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "dnegate"
dnegate:
  inv 2(r4) ; Invert
  inv @r4
  inc 2(r4) ; Add one
  adc @r4   ;   with carry
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "d-" ; ( 1L 1H 2L 2H )
dminus:                                        ;   6  4  2  0
  sub  2(r4), 6(r4) ;  Low-part first
  subc 0(r4), 4(r4) ; High-part with carry
  add #4, r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "d+"
dplus:
  add  2(r4), 6(r4)
  addc 0(r4), 4(r4)
  add #4, r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "s>d" ; ( n - dl dh ) Single --> Double conversion
doppeltlangmachen:
  pushda #-1
  tst 2(r4)
  jn +

clr_at_r4_ret:
  clr @r4
+ ret


;------------------------------------------------------------------------------
;--- Double-Comparisions ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "du>"
  ; ( 2L 2H 1L 1H -- Flag )
  ;   6  4  2  0
  call #dswap
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "du<"
  ; ( 2L 2H 1L 1H -- Flag )
  ;   6  4  2  0

+ cmp @r4, 4(r4)
  jlo ++ ; Is smaller. Finished.
  jne +  ; Not smaller, not equal. That means bigger. Finished.

  ; Check low parts.
  cmp 2(r4), 6(r4)
  jlo ++ ; They are smaller --> True

+ ; Exit False
  mov #0, 6(r4)
  jmp ++
+ ; Exit True
  mov #-1, 6(r4)
+ add #6, r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "d>"
  ; ( 2L 2H 1L 1H -- Flag )
  ;   6  4  2  0
  call #dswap
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "d<"
  ; ( 2L 2H 1L 1H -- Flag )
  ;   6  4  2  0

+ cmp @r4, 4(r4)
  jl  ++ ; Is smaller. Finished.
  jne +  ; Not smaller, not equal. That means bigger. Finished.

  ; Check low parts.
  cmp 2(r4), 6(r4)
  jlo ++ ; They are smaller --> True

+ ; Exit False
  mov #0, 6(r4)
  jmp ++
+ ; Exit True
  mov #-1, 6(r4)
+ add #6, r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "d0<"  ; Is double number negative ?
  ; ( 1L 1H -- Flag )
  ; Rotate MSB of 1H, the sign bit, into Carry.
  add @r4+, -2(r4)  ; Emulated rrc @r4+
  jnc clr_at_r4_ret ; If sign was not set
  mov #-1, @r4      ; Put a true flag in place.
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_2, "d0="
  ; ( 1L 1H -- Flag )

  bit @r4+, -2(r4) ; Is top element 1H zero ? Remove it.
  jnz clr_at_r4_ret ; Not zero - finished.

  bit #-1, @r4 ; C is set, if result of "and" is NOT zero
  subc @r4, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "d<>"
  ; ( 2L 2H 1L 1H -- Flag )
  ;   6  4  2  0

  call #dgleich
  xor #-1, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "d="
  ; ( 2L 2H 1L 1H -- Flag )
  ;   6  4  2  0

dgleich:
  xor @r4+, 2(r4) ; Compare 1H with 2H
  jc +
  ; ( 2L 2H 1L -- Flag )
  ;   4  2  0

  xor 0(r4), 4(r4) ; Check second pair if the first one is equal
+ subc 4(r4), 4(r4)
  add #4, r4
  ret

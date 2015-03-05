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

; Calculations with s15.16 fixpoint numbers, their input and output. 
; Number is also defined here and handles all types of numbers.

;------------------------------------------------------------------------------
; --- Calculations for s15.16 numbers ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
uf_slash_mod: ; Divide 32/32 = 32 Remainder 32. Puts decimal point in the middle. Overflow possible.
              ; Internal helper only.
;------------------------------------------------------------------------------
  push r10
  mov #16, r10
  jmp ud_slash_mod_kommastellenverschiebung

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "f/"
f_div: ; Signed divide for s15.16. Overflow possible. Sign wrong in this case.
;------------------------------------------------------------------------------
  ; Take care of sign ! ( 1L 1H 2L 2H - EL EH )
  push r10
  clr r10

  bit #8000h, 0(r4)
  jnc +
    inc r10
    call #dnegate

+ bit #8000h, 4(r4)
  jnc +
    inc r10
    ; Negate second double on stack
    call #dswap
    call #dnegate
    call #dswap
+
  call #uf_slash_mod
  call #doppelnip ; Drop Remainder
  ; call #dabs ; Why ? On overflow, result is wrong either.

  bit #1, r10
  jnc +
  call #dnegate
+
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_4, "f*"
f_star: ; Signed multiply s15.16
        ; ( fi fi -- fi )
        ; Overflow possible. Sign wrong in this case.
;------------------------------------------------------------------------------
  ; Take care of sign ! ( 1L 1H 2L 2H - EL EH )
  push r10
  clr r10

  bit #8000h, 0(r4)
  jnc +
    inc r10
    call #dnegate

+ call #dswap
  bit #8000h, 0(r4)
  jnc +
    inc r10
    call #dnegate
+
  call #ud_star

;   Implement some sort of overflow handler ?
;   tst @r4 ; High-Part that is cutted off
;   jz +
;   writeln " Overflow in f* !"
; +

  ; Result is 64 bits wide. Drop first and last 16 bits.
  mov 4(r4), 6(r4)
  mov 2(r4), 4(r4)
  add #4, r4

  bit #1, r10
  jnc +
  call #dnegate
+
  pop r10
  ret

;------------------------------------------------------------------------------
; --- Input and Output for s15.16 ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
 Wortbirne Flag_visible, "hold<"
zahlanhaengen: ; ( Character -- ) Insert one character at the end of number buffer
;------------------------------------------------------------------------------
  cmp.b #Zahlenpufferlaenge, &Zahlenpuffer
  jhs + ; Number buffer full ?

  inc.b &Zahlenpuffer ; Increment length
  mov.b &Zahlenpuffer, r7     ; Fetch length into register
  mov.b @r4, Zahlenpuffer(r7) ; and store character into buffer

+ incd r4 ; Drop character from stack
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "f#S"
falleziffern: ; ( u -- u=0 )
      ; Inserts all digits, at least one, into number buffer.
;------------------------------------------------------------------------------
  push r10
  mov #16, r10

- call #fziffer
  dec r10
  jnz -

+ pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "f#"
fziffer: ; ( u -- u )
      ; Insert one more digit into number buffer
;------------------------------------------------------------------------------
  ; Handles parts after decimal point
  ; Idea: Multiply with base, next digit will be shifted into high-part of multiplication result.

  pushda &Base ; Base
  call #um_star ; ( After-Decimal-Point Base -- Low High )
  call #digitausgeben ; ( Low=Still-after-decimal-point Character )

  jmp zahlanhaengen ; Add character to number buffer


;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "f."
      ; ( Low High -- )
      ; Prints a s15.16 number

  push #16
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "f.n"
      ; ( Low High n -- )
      ; Prints a s15.16 number
  to_r

+ ; ( Low High -- )
  call #tuck ; ( Sign Low High )
  call #dabs ; ( Sign uLow uHigh )

  pushda #0  ; ( Sign After-decimal-point=uL Before-decimal-point-low=uH Before-decimal-point-high=0 )
  call #zifferstringanfang

  call #alleziffern ; Processing of high-part finished. ( Sign uL 0 0 )
  drop ; ( Sign uL 0 )

  mov #44, @r4 ; Add a comma to number buffer ( Sign uL 44 )
  call #zahlanhaengen ; ( Sign uL )

- call #fziffer ; Processing of fractional parts ( Sign 0 )
  dec @sp
  jnz -
  incd sp

  mov 2(r4), @r4     ; ( Sign Sign )
  call #vorzeichen   ; ( Sign )

  decd r4 ; ( Sign Random ) Will be dropped anyway.
  jmp abschluss_zahlenausgabe

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "number" ; Number-Input.
  ; ( String Length -- 0 )    Not recognized
  ; ( String Length -- n 1 )  Single number
  ; ( String Length -- d 2 )  Double number or fixpoint s15.16

number: ; Tries to convert a string in one of the supported number formats.
;------------------------------------------------------------------------------
  push r10 ; Pointer
  push r11 ; Characters left
  push r12 ; Low  part for double or Before-decimal-point for s15.16
  push r13 ; High part for double or  After-decimal-point for s15.16
  push r14 ; Size of result
  push &Base

  clr r14 ; No results yet.

  popda r11 ; Fetch length
  popda r10        ; Fetch string address

  tst r11 ; Is string empty ?
  jz universalnumber_aussprung  ; Empty strings are no numbers.

  ; Check for base changing characters:
  mov.b @r10, r13 ; Fetch first character

  cmp.b #36, r13 ; It is "$" ? Base 16
  mov #16, r12
  je +

  cmp.b #37, r13 ; It is "%" ? Base 2
  mov #2, r12
  je +

  cmp.b #35, r13 ; It is "#" ? Base 10
  mov #10, r12
  jne ++

+ ; Base has to be changed.

    mov r12, &Base
    inc r10 ; Increment Pointer
    dec r11 ; Decrement length left
    jz universalnumber_aussprung ; Empty strings or base changing characters alone are no valid numbers.

+ ; Finished base checks.

;------------------------------------------------------------------------------
; Check for sign:

  cmp.b #45, @r10  ; Is first character "-" ?
  push sr ; Store Zero-Flag on Returnstack for later usage.
  jne +
    inc r10 ; Increment Pointer
    dec r11 ; Decrement length left
+ ; Sign handled and removed.

  ; String contains now  Digits-before-decimal-Point  .|,  Digits-after-decimal-Point
;------------------------------------------------------------------------------
  clr r12 ;  Low-part   - No results at the beginning.
  clr r13 ; High-part

  mov #1, r14 ; Result will be a single number.

universalnumber_vorkommastellen:
  tst r11 ; Is string empty ?
  jz universalnumber_vorzeichenbearbeiten ; Finished !

  ; Check for occurence of . that denotes double numbers
  cmp.b #46, @r10 ; "."
  jne +
    mov #2, r14   ; Double result !
    jmp ++

+ decd r4
  mov.b @r10, @r4  ; Fetch character out of buffer
  clr.b 1(r4)      ; Clear high part in stack

  call #flagdigit  ; Convert
  bit @r4+, -2(r4) ;   and check if successful
  jz universalnumber_nachkommastellen ; Not successful ? Then I might have encountered "," for s15.16 numbers.

  sub #8, r4
  mov r12,   6(r4) ; uL
  mov r13,   4(r4) ; uH
  mov &Base, 2(r4) ; Base low
  mov #0,    0(r4) ; Base high = 0

  call #ud_star  ; Multiply
  add #4, r4     ; Drop topmost 32 bits
  popda r13      ; Fetch back uH
  popda r12      ; Fetch back uL
  add @r4+, r12  ; Add new digit
  adc r13        ;   and take care of Carry

+ inc r10 ; Increment Pointer
  dec r11 ; Decrement length left

  jmp universalnumber_vorkommastellen ; Process next character

;------------------------------------------------------------------------------

universalnumber_nachkommastellen: ; Continue with digits after the decimal point for s15.16 numbers.
  ; tst r11                  ; There is always one character left that has been rejected when entering this.
  ; jz universalnumber_leer

  mov r12, r13 ; Move Double-Low into s15.16-High
  clr r12      ; Clear s15.16-Low

  pushda r12 ; ( 0 )

- ; ( Digits-after-decimal-Point )

  decd r4
    add r11, r10
    dec r10
  mov.b @r10, @r4  ; Get character from end of string
    inc r10
    sub r11, r10
  clr.b 1(r4)      ; Clear high-byte on stack

  ; ( Digits-after-decimal-Point Character )
  call #flagdigit  ; Convert
  bit @r4+, -2(r4) ;   and check if successful
  jz universalnumber_nachkommafertig ; Not successful ? Check if this is ","

  dec r11 ; Decrement length left, but don't move pointer, as we take characters from the back.

  pushda &Base       ; ( Old.. New-Digit Base )
  call #um_slash_mod ; ( Remainder New.. )
  nip                ; ( Digits-after-decimal-Point )

  jmp -

;------------------------------------------------------------------------------

universalnumber_nachkommafertig: ; Finished s15.16.
  popda r12 ; Fetch back Digits-after-decimal-Point

  clr r14 ; No result...

  cmp #1, r11          ; Exactly one character left ?
  jne universalnumber_vorzeichenbearbeiten
  cmp.b #44, @r10      ; Is this one a "," ?
  jne universalnumber_vorzeichenbearbeiten

  ; Fine. Successfully converted a s15.16 number.
  mov #2, r14

;------------------------------------------------------------------------------
; Handle sign that has been on returnstack for a while
universalnumber_vorzeichenbearbeiten:
  pop sr
  jne +
    inv r12 ; Invert Low-part
    inv r13 ; Invert High-part
    inc r12 ; Add one to Low-part
    adc r13 ;   and handle Carry
+

  ; Put results on stack: ( [Low [High]] Size )

  cmp #1, r14
  jlo ++
    pushda r12 ; Low-part

+ cmp #2, r14
  jlo +
    pushda r13 ; High-part

;------------------------------------------------------------------------------
universalnumber_aussprung:
+ pushda r14 ; Size
  pop &Base
  pop r14
  jmp ende_pop_13_10

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

; Input and Output of numbers

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, ".digit"
digitausgeben: ; ( u -- c ) Converts a digit into a character.
               ; If base is bigger than 36, unprintable digits are written as #
;------------------------------------------------------------------------------
  mov @r4, r7  ; Fetch digit

  cmp #10, r7  ; 0-9:
  jhs +
  add #48, r7  ; Shift to beginning of ASCII numbers
  jmp +++

+ cmp #36, r7  ; A-Z:
  jhs +
  add #55, r7  ; Shift to beginning of ASCII-capital-letters- 10 = 55.
  jmp ++        ; For small letters: 87.

+ mov #35, r7  ; Character #, if digit is not printable

+ mov r7, @r4  ; Return Character
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "digit" ; Converts a character into a digit.
flagdigit: ; ( c -- false / u true )
;------------------------------------------------------------------------------
  mov @r4, r7   ; Fetch character

  sub #48, r7   ; Subtract "0"
  jlo +          ; Negative ? --> Invalid character.

  cmp #10, r7   ; In range up to "9" ?
  jlo ++         ; Digit recognized properly.

  ; Character is a letter. 

  sub #7,  r7  ; Beginning of capital letters "A"
  cmp #10, r7  ; Values of letters start with 10
  jlo +         ; --> Character has been a special one between numbers and capital letters.

  cmp #36, r7  ; 26 letters available.
  jlo ++        ; In this range ? Digit recognized properly.

  ; Try to recognize small letters.

  sub #32, r7  ; Beginning of small letters "a"
  cmp #10, r7  ; Values of letters start with 10
  jlo +         ; --> Character has been a special one between small and capital letters.

  cmp #36, r7  ; 26 letters available.
  jlo ++        ; In this range ? Digit recognized properly.

  ; Not yet recognized ? --> Character has been a special one above small letters or in Unicode.
  ; No valid digit then..

/ clr @r4  ; Error.
  ret

+ ; Check if digit is within current base !
  cmp &Base, r7
  jhs -          ; Do not accept digits greater than current base

  mov r7, @r4
  pushda #-1
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "hold" ; Insert one character at the beginning of number buffer
hold: ; ( Character -- )
;------------------------------------------------------------------------------
  cmp.b #Zahlenpufferlaenge, &Zahlenpuffer
  jhs ++ ; Number buffer full ?

  ; Old String:  | Length     |     |
  ; New String:  | Length + 1 | New |

  ; Old String:  | Length     | I   | II  | III |     |
  ; New String:  | Length + 1 | New | I   | II  | III |

  mov.b &Zahlenpuffer, r7 ; Fetch old length of buffer
  inc.b &Zahlenpuffer      ; Increment it

  ; Check if at least one character has to be moved
  tst r7
  je +

    ; Yes, move r7 characters.
-   mov.b Zahlenpuffer(r7), Zahlenpuffer+1(r7)
    dec r7
    jnz -

+ mov.b @r4, &Zahlenpuffer+1 ; Insert new character

+ incd r4 ; Drop character from stack
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "sign"
vorzeichen: ; ( n -- ) Checks flag of number on stack and adds a minus to number buffer if it is negative.
;------------------------------------------------------------------------------
  tst @r4
  jn +
  drop
  ret

+ mov #45, @r4  ; ASCII for minus
  jmp hold      ; put it into number buffer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "#S"
alleziffern: ; ( u|ud -- u|ud=0 )
             ; Inserts all digits, at least one, into number buffer.
;------------------------------------------------------------------------------
- call #ziffer
  tst @r4   ; Continue if there is still something in high part
  jne -
    tst 2(r4) ; or in low part of number to print.
    jne -
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "#"
ziffer: ; ( uL uH -- uL uH )
        ; Insert one more digit into number buffer
;------------------------------------------------------------------------------
  ; Idea: Divide by base. Remainder is digit, Result is to be handled in next run.

    pushdadouble &Base, #0 ; Base-Low and Base-High
    ; ( uL uH BaseL BaseH )
    call #ud_slash_mod
    ; ( RemainderL RemainderH uL uH )
    call #dswap
    ; ( uL uH RemainderL RemainderH )
    drop
    ; ( uL uH RemainderL )
    call #digitausgeben
    jmp hold

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "#>" ; ( ud -- Address Length )
zifferstringende:  ; Finishes a number string and gives back its address.
;------------------------------------------------------------------------------
  mov #Zahlenpuffer+1, 2(r4)
  mov #Zahlenpuffer, r7
  mov.b @r7, r7
  mov r7, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "<#" ; ( d -- )
zifferstringanfang: ; Opens a number string
;------------------------------------------------------------------------------
  clr.b &Zahlenpuffer ; Clear number buffer
  ret

; Taken from Starting Forth:
;   : UD. <# #S #> TYPE SPACE ;
;   : D.  TUCK DABS <#  #S ROT SIGN  #>  TYPE SPACE ;

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "u." ; ( u -- )
udot: ; Prints an unsigned single number
;------------------------------------------------------------------------------
  pushda #0 ; Convert to unsigned double
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "." ; ( n -- )
dot: ; Prints a signed single number
;------------------------------------------------------------------------------
  call #doppeltlangmachen
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "ud." ; ( ud -- )
      ; Prints an unsigned double number
;------------------------------------------------------------------------------
  ; In Forth: <# #S #>
  call #zifferstringanfang
  call #alleziffern
  jmp abschluss_zahlenausgabe

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "d." ; ( d -- )
     ; Prints a signed double number
;------------------------------------------------------------------------------
+ call #tuck
  call #dabs

  call #zifferstringanfang
  call #alleziffern ; ( Sign 0 0 )
  add #4, r4
  call #vorzeichen
  sub #4, r4  ; ( Random Random ) Will be dropped anyway.

abschluss_zahlenausgabe:
  call #zifferstringende
  call #type
  write " "
  ret

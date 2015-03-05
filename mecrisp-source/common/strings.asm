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

; Routines for counted strings

lowercase macro Zeichen ; Change character in register into lowercase
  ;    Hex Dec  Hex Dec
  ; A  41  65   61  97  a
  ; Z  5A  90   7A  122 z

  cmp.b #041h, Zeichen
  jlo +
  cmp.b #05Bh, Zeichen
  jhs +
  add.b #020h, Zeichen
+ ; Fertig
          endm

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "compare"
flagstringvergleich: ; ( Address Length Address Length -- true | false )
;------------------------------------------------------------------------------
  push r10  ; Address of first  string
  push r11  ; Address of second string
  push r12  ; Character out of first  string
  push r13  ; Character out of second string
  ;    r7   ; Length

  popda r7     ; Fetch length  of first  string
  popda r10    ; Fetch address of first  string
  popda r12    ; Fetch length  of second string
  mov @r4, r11 ; Fetch address of second string
  clr @r4      ; Prepare false flag

  cmp r7, r12  ; Compare lengths of strings
  jnz stringvergleich_ungleich
  tst r7   ; Just in case empty strings are compared
  jz stringvergleich_gleich

- ; Lengths are equal. Now check characters.
  mov.b @r10+, r12
  mov.b @r11+, r13

  ; Lowercase r12 for r13 for beeing case-insensitive.
  lowercase r12
  lowercase r13

  cmp.b r12, r13
  jnz stringvergleich_ungleich

  dec r7
  jnz -
  ; If falling out here, Z is set and strings are equal.

stringvergleich_gleich:
  mov #-1, @r4
stringvergleich_ungleich:
  jmp ende_pop_13_10

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "skipstring"
stringueberlesen: ; ( Adress -- Adress )
                  ; Skips a string.
;------------------------------------------------------------------------------
  push r10
  mov @r4, r10 ; Start address of string
  call #stringueberlesen_r10
  mov r10, @r4
  pop r10
  ret

stringueberlesen_r10:
  mov.b @r10+, r7 ; Fetch length to r11, skip length byte
  add r7, r10     ; Add number of characters

  ; Skip filling-zero if uneven address
  bit #1, r10
  adc r10
  ; Address now points to first instruction after the string.
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "ctype"
schreibestringmitlaenge: ; ( Address -- )
                ; Writes a string with emit
                  ; Example: 
                  ; Moinstring:  .byte 5, "Moin", 10
                  ; pushda #Moinstring
                  ; call #schreibestringmitlaenge
;------------------------------------------------------------------------------
  push r10
  push r11

  popda r10          ; Fetch start address of string
  mov.b @r10+, r11   ; Fetch length of string
                     ; r10 is address pointer

- cmp #0, r11        ; Finished if length is zero.
  je +

  mov.b @r10+, r7    ; Clear high byte, just in case.
  pushda r7
  call #emit

  dec r11            ; Decrement length
  jnz -

+ pop r11
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "type" ; ( Address Length -- )
;------------------------------------------------------------------------------
type:
  push r10
  push r11

  popda r11  ; Fetch length of string
  popda r10  ; Fetch start address of string

  jmp -      ; Share code with ctype

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "s\i" ; ( -- address ) This is s" and gives back address and length of a string in runtime.
;------------------------------------------------------------------------------
  push #algaensefuesschen
  jmp gaensefuesschendetektor

algaensefuesschen:
  ; ( R: String-address-in-Return )

  ; Address of string is given by return address.
  pushda @sp ; Save string address for later use on stack
  call #count
  jmp dotgaensefuesschen_inneneinsprung

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "c\i" ; ( -- address ) This is c" and gives back a pointer to a string in runtime.
;------------------------------------------------------------------------------
  push #sgaensefuesschen
  jmp gaensefuesschendetektor

sgaensefuesschen:
  ; ( R: String-address-in-Return )

  ; Address of string is given by return address.
  pushda @sp ; Save string address for later use on stack
  ; call #schreibestringmitlaenge ; This is only the difference to ."
  jmp dotgaensefuesschen_inneneinsprung

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, ".\i" ; This is ."
;------------------------------------------------------------------------------
  push #dotgaensefuesschen

gaensefuesschendetektor:
  r_from
  call #callkomma

  pushda #34
  call #parse
  br #kommastring

  ; Usage:
  ; call #dotgaensefuesschen
  ; .byte Length, Characters [, 0 to align address]

dotgaensefuesschen:
  ; ( R: String-address-in-Return )

  ; Address of string is given by return address.
  pushda @sp
  call #schreibestringmitlaenge

dotgaensefuesschen_inneneinsprung:

  pushda @sp+ ; Save string address for later use on stack
  call #stringueberlesen ; Advance return address to first instruction after string.
  mov @r4+, pc ; Return to address on datastack

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate|Flag_Foldable_0, "\40" ; ( -- ) Comment (
  mov #41, r7 ; [char] )
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "count" ; ( c-addr -- c-addr+1 len ) Count of a string
count:
  mov @r4, r7
  inc @r4
  mov.b @r7, r7
  pushda r7
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate|Flag_Foldable_0, "\\" ; ( -- ) Long Comment \ to end of line
  clr r7 ; Character 0 never occours in buffer - scan to end of line.
+ pushda r7
  call #parse
  ddrop
  ret

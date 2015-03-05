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

; Tools for deep insight into Mecrisp and its Stacks.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "hex." ; ( x -- ) Print a number in Base 16.
hexdot:
;------------------------------------------------------------------------------
  mov @r4, r7 ; Fetch number which is to be printed
  swpb r7 ; High-Byte first
  call #bytedot

  mov @r4+, r7 ; Fetch number which is to be printed
  call #bytedot
  jmp space

;------------------------------------------------------------------------------
bytedot: ; Prints byte in r7 with Base 16.
  mov.b r7, r7 ; Apply mask $FF

  pushda r7
  and #15, @r4

  rra r7 ; Sign bit already contains zero
  rra r7
  rra r7
  rra r7
  pushda r7

  call #digitausgeben
  call #emit

  call #digitausgeben
  jmp emit

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cr" ; ( -- ) Emit line feed
  writeln ""
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline|Flag_foldable_0, "bl"
  pushda #32
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "space" ; ( -- ) Emit space
space:
  write " "
  ret  

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "spaces" ; ( u -- ) Emit spaces
  tst @r4
  jz +
-   call #space
    sub #1, @r4
    jnz -   
+ drop
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "words" ; ( -- ) Print list of words with debug information
;------------------------------------------------------------------------------
  push r10
  writeln "words"
  call #dictionarystart

- write "Address: "
  dup
  call #hexdot

  write "Flags: "
  mov @r4, r7
  mov.b @r7, r7
  call #bytedot

  mov @r4, r10 ; Fetch current address
  inc r10      ; Skip Flags
  pushda r10   ; Save address for printing name later

  call #stringueberlesen_r10

  ; Pointer now reached link
  write " Link: "
  pushda @r10
  call #hexdot

  incd r10
  pushda r10
 
  ; Write code start address
  write "Code: "
  call #hexdot

  ; Write name
  write "Name: "
  call #schreibestringmitlaenge
  writeln "" ; cr

  call #dictionarynext
  bit @r4+, -2(r4) ; End of Dictionary reached ?
  jz - 

  drop
  pop r10
  ret


;------------------------------------------------------------------------------
  Wortbirne Flag_visible, ".s"
;------------------------------------------------------------------------------
  push r12
  mov #dot, r12
  jmp dots_intern

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "h.s"
;------------------------------------------------------------------------------
  push r12
  mov #hexdot, r12
  jmp dots_intern

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "u.s"
dotS: ; Prints out data stack, uses unsigned numbers. 
      ; Especially useful for logic, addresses and counters.
;------------------------------------------------------------------------------
  push r12
  mov #udot, r12

dots_intern:
  push r10
  push r11
  mov #datenstackanfang, r10  ; Top address of stack
  mov r10, r11                ; Copy it
  sub r4, r11                 ; Calculate fill level

  write " Stack: ["

dotseinsprung:
  clrc
  rrc r11                     ; Divide fill level by two, as stack is organized in words..

  ; Pointer in r10, number of words to print in r11.

  push &Base      ; Print fill level
  mov #10, &Base
    pushda r11
    call #udot
  pop &Base

  write "] "

  tst r11 ; Reached Zero, finished printing ?
  je +

- decd r10       ; Print content
  pushda @r10
  call r12

  dec r11
  jz +
  write ", "
  jmp -

+ writeln " *>"

  pop r11
  pop r10
  pop r12
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, ".rs"
      ; Prints out return stack, uses unsigned numbers. 
      ; Especially useful for logic, addresses and counters.
;------------------------------------------------------------------------------
  push r12
  mov #hexdot, r12

  push r10
  push r11
  mov #returnstackanfang, r10 ; Top address of stack
  mov r10, r11                ; Copy it
  sub sp, r11                 ; Calculate fill level
  sub #6, r11                 ; Off by 6 for entry into .rs and saved registers.

  write " Returnstack: ["
  jmp dotseinsprung

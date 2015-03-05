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

; Token and parse to cut contents of input buffer apart

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "token"
token: ; ( -- Addr Length ) Separates one Token out of input buffer.
       ; Gives back an empty string if buffer empty..
;------------------------------------------------------------------------------
  mov #32, r7 ; Space as separator, Parse recognizes this as special case.
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "parse"
parse: ; ( Character -- Addr Length ) Takes out of input buffer until separator character is found or buffer is empty.
;------------------------------------------------------------------------------
  popda r7 ; Delimiting character

+ push r10
  push r11
  push r12
  push r13

  mov &current_source+2, r10    ; Address of source
  mov &current_source, r11  ; Length  of source
  mov &Pufferstand, r12       ; Current >IN gauge

  ; Special case for token: Skip trailing spaces !
  cmp #32, r7
  jne +

-   cmp r11, r12 ; Any characters left ?
    jeq +

    mov r10, r13
    add r12, r13
    mov.b @r13, r13 ; Fetch character.
    cmp r7, r13     ; It is space ?
    jne +
      inc r12 ; Don't collect spaces, advance >IN to skip.
      jmp -

+ pushda r10            ; Store address of string
  add r12, @r4          ;   and adjust for current >IN
  mov r12, &Pufferstand ; Store new >IN

  ; Trailing spaces cut off, continue to collect characters.

- cmp r11, r12 ; Any characters left ?
  jz +
    mov r10, r13    ; Calculate address
    add r12, r13    ; of nect character
    mov.b @r13, r13 ; Fetch character.

    inc r12         ; Advance >IN

    cmp r7, r13     ; Is this the delimiter ?
    jne -
      ; Finished, fallthrough for delimiter detected.
      add #1, &Pufferstand ; Do not collect the delimiter character, but it should be handled for new >IN

+ ; End reached, fallthrough for empty strings.
  pushda r12 ; Prepare length of string
  sub &Pufferstand, @r4 ; Calculate collected length
  mov r12, &Pufferstand ; Store new >IN gauge

  pop r13
  pop r12
  pop r11
  pop r10
  ret
 
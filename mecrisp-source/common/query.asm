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

; Input routine Query - with Unicode support.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, ">in"
  CoreVariable Pufferstand
;------------------------------------------------------------------------------
  pushda #Pufferstand
  ret
  .word 0

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_2variable, "current-source"
  DoubleCoreVariable current_source
;------------------------------------------------------------------------------
  pushda #current_source
  ret
  .word 0              ; Empty TIB for default
  .word Eingabepuffer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "source"
;------------------------------------------------------------------------------
source:
  sub #4, r4
  mov &current_source, @r4
  mov &current_source+2, 2(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "setsource"
;------------------------------------------------------------------------------
setsource:
  popda &current_source
  popda &current_source+2
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_0, "tib" ; Puts address of TIB on stack
;------------------------------------------------------------------------------
  pushda #Eingabepuffer
  ret

; -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "query" ; Collecting your keystrokes into TIB ! Forth at your fingertips :-)
query: ; ( -- ) Nimmt einen String in den Eingabepuffer auf
; -----------------------------------------------------------------------------
  clr &Pufferstand ; Zero characters consumed yet
  pushda #Eingabepuffer
  dup
  pushda #MaximaleEingabe
  call #accept
  call #setsource
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cexpect" ; ( cstr-addr maxlength ) Collecting your keystrokes into a counted string !
;------------------------------------------------------------------------------
  push 2(r4)     ; Fetch address
  inc 2(r4)      ; Add one to skip length byte for accept area
  call #accept
  pop r7
  mov.b @r4, @r7 ; Store accepted length into length byte of counted string
  drop
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "accept" ; ( c-addr maxlength -- length ) Collecting your keystrokes !
accept: ; Nimmt einen String entgegen und legt ihn in einen Puffer.
;------------------------------------------------------------------------------
  push r10 ; Character
  push r11 ; Current length
  push r12 ; Maximum length

  clr r11   ; Empty buffer
  popda r12 ; Fetch maximum length
  ; ( c-addr )

QuerySchleife:
  call #key   ; Wait for key press
  popda r10         ; and fetch character.

  ; Check for control characters.

  cmp #32, r10 ; ASCII 0-31 are control characters, 32 is space. Some deserve special treatment.
  jhs QueryZeichen ; Jump to include printable characters into buffer.
  ; -----------------------------------------------------------------
  ; Handle control characters: 10, 13 CR; 8 Backspace.

  ; Exchange TAB with whitespace and add to buffer
  cmp #9, r10
  jne +
    mov #32, r10
    jmp QueryZeichen
+

  ; Check for CR and Return:
  cmp #10, r10
  je +
  cmp #13, r10
  jne ++

+ ; Return:
    mov r11, @r4 ; Put length on stack
    write " "    ; Print a space instead of CR
    pop r12
    pop r11
    pop r10
    ret

+ ; Check for Backspace and perhaps other control characters:
  cmp #8, r10
  jne QuerySchleife ; Not Backspace ? Then ignore this character completely.

    ; If Buffer is not empty, delete last character of buffer and clear it visually.
    tst r11           ; Check buffer fill level
    je QuerySchleife  ; If zero, nothing to do.

    call #dotgaensefuesschen ; Clear a character visually.
    .byte 3, 8, 32, 8        ; Step back cursor, overwrite with space, step back cursor again.

      ; dec r11 ; For "normal" character sets simply remove one byte. No need for special treatment in any case.
      ; jmp QuerySchleife

    ; Remove character from buffer and watch for Unicode !
    ; Unicode: Maybe I have to remove more than one byte from buffer.
      ; Unicode-Characters have this format:
      ; 11xx xxxx,  10xx xxxx,  10xx xxxx......
      ; If the last character has 10... then I have to delete until i reach a character that has 11....
      ; Always check if buffer may be already empty !

-     tst r11 ; Check buffer fill level
      je QuerySchleife ; Zero ? Nothing to delete !

      ; Check last character.
      dec r11 ; Back one place
      mov @r4, r10
      add r11, r10
      mov.b @r10, r10 ; Fetch character

      ; Check character for Unicode, is MSB set ?
      bit #10000000b, r10
      jnc QuerySchleife ; If not, then this has been a normal character and my task is finished.

      ; Else I have to remove more bytes of this single Unicode character.
      ; Have I reached the first byte of this particular Unicode character yet ?
      bit #01000000b, r10
      jnc - ; If not, delete more.
      ; If yes, this is done.
      jmp QuerySchleife

QueryZeichen:
+ ; -----------------------------------------------------------------
  ; Add a character to buffer if there is space left and echo it back.

  cmp r12, r11 ; Check buffer fill level.
  jhs QuerySchleife ; Full ? Don't let it overflow !

  ; Buffer has space left. Put character into.
  mov @r4, r7
  add r11, r7
  mov.b r10, @r7 ; Put character at the end.
  inc r11   ; Increment buffer fill level, has been checked just before.

  pushda r10 ; Echo back
  call #emit ;   this character.

  jmp QuerySchleife

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

    pushdadouble #Anfangswortnamensstring, #4
    call #wortsuche
    tst 2(r4) ; Found turnkey definition ?
    jz +
    ; Found:

      clr &konstantenfaltungszeiger ; No constant folding in progress.
      drop       ; Drop Flags
      call @r4+  ; Execute
      br &hook_quit ; Internal entry to preserve what init might have done.

+ ; Not found ? Don't tidy up. Quit clears stacks for us.
  br #quit

Anfangswortnamensstring: .byte "init"
  align 2

  Wortbirne Flag_invisible, "--- Flash Dictionary ---"
;------------------------------------------------------------------------------
; Set latest link into user changeable flash dictionary.
Backlink_{Backlink_Label} equ nFlashDictionaryAnfang ; Dies ist der Zeiger in das veränderliche Flash-Dictionary.

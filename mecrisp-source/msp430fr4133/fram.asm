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

; Routines to write and erase of FRAM memory

;------------------------------------------------------------------------------
; Register and Constants for FRAM access
;------------------------------------------------------------------------------

SYSCFG0 equ 0140h + 20h

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "eraseflashfrom" ; ( Start-Address -- )
;------------------------------------------------------------------------------
  popda r7
  bic #1, r7 ; Make sure address is even
  cmp #kernelstartadresse, r7 ; Preserves Forth core !
  jlo +
    ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "eraseflash" ; Forgets whole user dictionary.
                                       ; Cold start, initialise everything new.
;------------------------------------------------------------------------------
  ; Don't need to save anything, as I perform Reset after this.
  mov #nFlashDictionaryAnfang, r7

+ dint                  ; Just for sure, deactivate everything that could interrupt this.
  mov #5A80h, &WDTCTL

  bic #1, &SYSCFG0 ; Enable write access

- mov #0FFFFh, @r7
  incd r7
  cmp #nFlashDictionaryEnde, r7
  jne -

  ; Finished.
  bis #1, &SYSCFG0 ; Disable write access again
  clr &wdtctl ; Reset with cold start, this will disable write access anyway.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cflash!"
flashcstore: ; ( n Address -- ) Writes a byte into flash
;------------------------------------------------------------------------------
  push r10
  popda r10 ; Address
  popda r7  ; Content

  cmp #kernelstartadresse, r10 ; Preserves Forth core
  jhs ++

  bic #1, &SYSCFG0 ; Enable write access
  mov.b r7, @r10 ; Store Data
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "flash!"
flashstore: ; ( n Address -- ) Writes a word into flash
;------------------------------------------------------------------------------
  push r10
  popda r10 ; Address
  popda r7  ; Content

  cmp #kernelstartadresse, r10 ; Preserves Forth core
  jhs ++

  bit #1, r10 ; Word access only to even addresses
  jc ++

  bic #1, &SYSCFG0 ; Enable write access
  mov r7, @r10 ; Store Data
+ bis #1, &SYSCFG0 ; Disable write access again

+ pop r10
  ret

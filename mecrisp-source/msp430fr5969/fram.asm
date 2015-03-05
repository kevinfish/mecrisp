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

  mov #0A500h, &MPUCTL0 ; Enable write access by disabling MPU

- mov #0FFFFh, @r7
  incd r7
  cmp #nFlashDictionaryEnde, r7
  jne -

  ; Finished.
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

  mov #0A500h, &MPUCTL0 ; Enable write access by disabling MPU
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

  mov #0A500h, &MPUCTL0 ; Enable write access by disabling MPU
  mov r7, @r10 ; Store Data
+ mov #0A501h, &MPUCTL0 ; Disable write access again
  mov.b #0, &MPUCTL0+1  ; Disable MPU access

+ pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "x@" ; ( d -- x ) Fetch from double-address location
;------------------------------------------------------------------------------
  push @r4+      ; Push low half of address
  push @r4       ; Push high half of address
  .word 0117h    ; Get 20 bit address into register, popx.a r7 = mova @r1+, r7 Opcode
  mov @r7, @r4   ; Fetch data
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cx@" ; ( d -- c ) Fetch byte from double-address location
;------------------------------------------------------------------------------
  push @r4+      ; Push low half of address
  push @r4       ; Push high half of address
  .word 0117h    ; Get 20 bit address into register, popx.a r7 = mova @r1+, r7 Opcode
  mov.b @r7, r7  ; Fetch data
  mov r7, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "x!" ; ( x d -- ) Store to double-address location
;------------------------------------------------------------------------------
  push @r4+      ; Push low half of address
  push @r4+      ; Push high half of address
  .word 0117h    ; Get 20 bit address into register, popx.a r7 = mova @r1+, r7 Opcode
  mov @r4+, @r7  ; Store data
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cx!" ; ( x c -- ) Store byte to double-address location
;------------------------------------------------------------------------------
  push @r4+      ; Push low half of address
  push @r4+      ; Push high half of address
  .word 0117h    ; Get 20 bit address into register, popx.a r7 = mova @r1+, r7 Opcode
  mov.b @r4, @r7 ; Store data
  drop
  ret

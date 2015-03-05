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

; Routines to write and erase of flash memory

        ; Flash Memory Controller
        ; Flash Timing Generator frequency must be 257-476 kHz.
        ; 8 MHZ/17 = 470.59 kHz.   tFTG=2.125 msec.
        ; At 470 kHz, byte/word program time is 35*tFTG = 75 usec.
        ; Cumulative program time to any 64-byte block (between erasures)
        ; must not exceed 4 msec, thus 53 writes at 250 kHz.  Therefore,
        ; do not use exclusively byte writes in a 64-byte block.
        ; Also, "a flash word (low + high byte) must not
        ; be written more than twice between erasures."
        ; Program/Erase endurance is 10,000 cycles minimum.

        ; In Mecrisp: 400kHz --> 2,5 us tFTG --> 35*tFTG = 87,5 us.
        ; May write for 10 ms maximum... --> 10ms/87.5us = 114 write access possible on every 64-Byte-Block.
        ; That is good. Can write in byte mode only.
        ; This routines take care that nothing is written twice.

;------------------------------------------------------------------------------
; Register and Constants for Flash access
;------------------------------------------------------------------------------

FCTL1 equ 0128h
FCTL2 equ 012Ah
FCTL3 equ 012Ch

; Key for all flash registers:
FWKEY equ 0A500h

;------------------------------------------------------------------------------
; Constants for FCTL1:
         ; 76543210
BLKWRT equ 10000000b ; Block Write Mode
WRT    equ  1000000b ; Write
                     ; Reserviert
EEIEX  equ    10000b ; Emergency Exit
EEI    equ     1000b ; Enable Erase Interrupts
MERAS  equ      100b ; Mass erase
ERASE  equ       10b ; Erase
                     ; Reserviert

;------------------------------------------------------------------------------
; Constants for FCTL2:
         ; 76543210
FSSEL_0 equ 00000000b ; ACLK
FSSEL_1 equ 01000000b ; MCLK
FSSEL_2 equ 10000000b ; SMCLK
FSSEL_3 equ 11000000b ; SMCLK

FSSEL0 equ FSSEL_1
FSSEL1 equ FSSEL_2

; Clock divider in Bit 0-5. Divides by (Value + 1)
FN0    equ          1b ; 2^0 = 1
FN1    equ         10b ; 2^1 = 2
FN2    equ        100b ; 2^2 = 4
FN3    equ       1000b ; 2^3 = 8
FN4    equ      10000b ; 2^4 = 16
FN5    equ     100000b ; 2^5 = 32

;------------------------------------------------------------------------------
; Constants for FCTL3:
         ; 76543210
FAIL  equ  10000000b ; Operation Failure
LOCKA equ   1000000b ; SegmentA and Info Lock. Writing 1 toggles state.
EMEX  equ    100000b ; Emergency Exit
LOCK  equ     10000b ; Lock. This bit unlocks flash memory for writing or erasing.
WAIT  equ      1000b ; Wait. Indicates Flash memory is being written to.
ACCVIFG equ     100b ; Access violation interrupt flag
KEYV  equ        10b ; Flash security key violation
BUSY  equ         1b ; Busy-Flag

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
  clr.b &IE1
  mov #5A80h, &WDTCTL

- cmp #0FFFFh, @r7
  je +
    ; Segment Erase: Take care: Lock and Clear have to be set for every segment again !
    mov #0A500h, &FCTL3 ; Lock = 0   #FWKEY
    mov #0A502h, &FCTL1 ; Erase = 1  #FWKEY+ERASE

      mov #0FFFFh, @r7 ; Dummy write to start erasure.

    mov #0A500h, &FCTL1 ; Erase = 0  #FWKEY
    mov #0A510h, &FCTL3 ; Lock = 1   #FWKEY+LOCK

+ incd r7
  cmp #nFlashDictionaryEnde, r7
  jne -

  ; Finished.
  clr &wdtctl ; Reset with cold start

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cflash!"
flashcstore: ; ( n Address -- ) Writes a byte into flash
;------------------------------------------------------------------------------
  push r10
  push r11
  popda r10 ; Address
  popda r11 ; Content

  cmp #kernelstartadresse, r10 ; Preserves Forth core
  jhs ++

  cmp.b #0FFh, r11 ; FF never gets written.
  je ++

  cmp.b #0FFh, @r10 ; Burn only if there is FF at the choosen location.
  jne ++            ; This combination ensures that maximum flash write cycles are never exceeded.

  ; Write.
            push sr
            dint
            mov.w   #FWKEY, &FCTL3           ; Clear LOCK bit
            mov.w   #FWKEY+WRT,&FCTL1        ; Set WRT bit for write operation

  mov.b r11, @r10
            jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "flash!"
flashstore: ; ( n Address -- ) Writes a word into flash
;------------------------------------------------------------------------------
  push r10
  push r11
  popda r10 ; Address
  popda r11 ; Content

  cmp #kernelstartadresse, r10 ; Preserves Forth core
  jhs ++

  bit #1, r10 ; Word access only to even addresses
  jc ++

  cmp #0FFFFh, r11 ; FFFF never gets written.
  je ++

  cmp #0FFFFh, @r10 ; Burn only if there is FFFF at the choosen location.
  jne ++            ; This combination ensures that maximum flash write cycles are never exceeded.

  ; Write.
            push sr
            dint
            mov.w   #FWKEY, &FCTL3           ; Clear LOCK bit
            mov.w   #FWKEY+WRT,&FCTL1        ; Set WRT bit for write operation
  mov r11, @r10
  ; Raise shield for flash again.
+           mov.w   #FWKEY, &FCTL1           ; Clear WRT bit
            mov.w   #FWKEY+LOCK,&FCTL3       ; Set LOCK bit
            pop sr

+ pop r11
  pop r10
  ret

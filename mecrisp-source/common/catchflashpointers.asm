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

; Initialise Pointers and Flash-Variables after Reset.
; This is included directly and only used once on startup, so registers are not saved here.

  mov   #returnstackanfang, sp    ; Init return stack pointer
  mov   #datenstackanfang,  r4    ; Init data stack pointer

  ; Register usage:
  ; r10 Address pointer
  ; r11 Flags
  ; r12 Occupied Ram
  ; r13 Search for end of dictionary structure
  ; r14 Copy of r10 for init variables
  ; r15 copy of r12 for init variables

  mov #nRamDictionaryEnde, r12 ; To count space for variables
  mov #CoreDictionaryAnfang, r10 ; Begin with the beginning.

  ; Structure of words in dictionary:
  ; Flags | Length-of-name  or $FFFF
  ; Name (|0)
  ; Link towards end of dictionary or $FFFF if not filled in yet

  ; There are two possibilities to detect end:
  ; - Link is $FFFF
  ; - Link is set, but points to memory that contains $FFFF.
  ; Last case happens if nothing is compiled yet, as the latest link in core always
  ; points to the beginning of user writeable/eraseable part of dictionary space.

SucheFlashPointer_Hangelschleife:
  mov r10, r13 ; Maybe this is the end ?
  ; r10 points directly to flags.

    mov.b @r10+, r11 ; Fetch flags and skip them
    call #stringueberlesen_r10

    ; Ignore this word if flags are $FF
    cmp.b #-1, r11
    je ++

    ; Does this word allocates Ram ?
    bit #Flag_ramallot, r11
    jnc ++ ; Finished, if not.

    ; Yes, this word allocates Ram.
    and #0Fh, r11 ; Mask Low-Nibble
    rla r11       ; multiply with two
    sub r11, r12  ; and advance pointer accordingly.

    mov r10, r14 ; r14: Copy address pointer
    mov r12, r15 ; r15: Copy Ram-Variable-Pointer

    incd r14 ; Skip Link
-   incd r14 ; Advance one word further
    cmp #4130h, -2(r14) ; Is ret opcode found on the last place ? Then I found end of code for this word.
    jne -

    ; r14 now points to initial values for variables or to the length of the buffer.

    tst r11
    jne + ; "Zero Bytes" denotes an uninitialised buffer which length is stored at the end of the definition.
      sub @r14, r12 ; Adjust variable pointer by desired buffer length
      jmp ++

    ; It is time to initialise freshly allocated variables
    ; Copy the content into the allocated ram locations. r11 counts bytes.
/   mov.b @r14+, @r15
    inc r15
    dec r11
    jnz -

+ ; Finished with initialisations.

  mov @r10, r10
  cmp #0FFFFh, r10  ; Is link set ?
  je +
  cmp #0FFFFh, @r10  ; Is there something else than $FFFF ?
  jne SucheFlashPointer_Hangelschleife

+ mov r12, &VariablenPointer

  ifdef flashkompilationsstart
    mov r13, &Fadenende
    mov #CoreDictionaryAnfang, &ZweitFadenEnde
  else
    mov r13, &ZweitFadenende
    mov #CoreDictionaryAnfang, &FadenEnde
  endif

  ; Search for Dictionary-Pointer.

  mov #nFlashDictionaryEnde, r10 ; Go back from end of dictionary space until I reach some data.
- cmp #nFlashDictionaryAnfang, r10 ; If begin of dictionary space is hit meanwhile, this is the dictionary pointer.
  je +

  decd r10
  cmp #0FFFFh, @r10
  je - ; Not equal ? Then I found the location the dictionary is filled up to.

  incd r10

+ ; Found Dictionary-Pointer.

  ifdef flashkompilationsstart
    mov r10, &DictionaryPointer
    mov #nRamDictionaryAnfang, &ZweitDictionaryPointer
  else
    mov r10, &ZweitDictionaryPointer
    mov #nRamDictionaryAnfang, &DictionaryPointer
  endif

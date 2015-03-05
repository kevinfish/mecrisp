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

; Memory Access of all kind

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "move"
       ; ( Source-Addr Target-Addr Byte-Count -- )
       ; Copies a memory block to another place.
       ; This is able to copy forward and backward.
;------------------------------------------------------------------------------
  push r10
  push r11

  popda r7 ; Count
  popda r11 ; Target Address
  popda r10 ; Source Address

  tst r7   ; Check if number of bytes to copy is zero.
  je ++     ; If yes this is finished.

  ; At least one byte has to be copied yet.

  cmp r11, r10 ; Compare Source and Target
  jhs +

  add r7, r10
  add r7, r11

- mov.b @r10, @r11 ; Copy from source to target
  dec r10  ; Decrement source address
  dec r11  ; Decrement target address
  dec r7  ; Decrement number of bytes left.
  jnz -    ; Any left ?

  jmp ++


/ mov.b @r10+, @r11 ; Copy from source to target
           ; Increment source address
  inc r11  ; Increment target address
  dec r7  ; Decrement number of bytes left.
  jnz -    ; Any left ?

+ pop r11
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "fill" ; @ ( Destination Count Filling -- )
;------------------------------------------------------------------------------
  ; 6.1.1540 FILL CORE ( c-addr u char -- ) If u is greater than zero, store char in each of u consecutive characters of memory beginning at c-addr. 

  push r10
  push r11

  popda r7  ; Filling
  popda r11 ; Count
  popda r10 ; Destination

  tst r11
  jz +

- mov.b r7, @r10
  inc r10
  dec r11
  jnz -

+ pop r11
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_opcodierbar_spezialfall, "cbit@" ; Test Bit(s) ( Mask Addr -- Flag )

  popda r7 ; Fetch address
  bit.b @r4, @r7 ; Test Bits

  jmp + ; Exactly as in bit@.

  ret ; Not executed, only needed for detection of beginning of opcoding helper.
  ;------------------------------------------------------------------------------
      ; Entry point for compiling with at least one folding constant.
      ; Put opcode in place to factor out common code.

      mov #0B0E2h, r12  ; r12 is already saved on this special entry point.
      ; bis #00400h for bit.b @r4,  &Address = 0B4E2h
      ; bis #00010h for bit.b @pc+, &Address = 0B0F2h
      jmp bitfetch_opcodierung

;------------------------------------------------------------------------------
  Wortbirne Flag_opcodierbar_spezialfall, "bit@" ; Test Bit(s) ( Mask Addr -- Flag )

  popda r7 ; Fetch address
  bit @r4, @r7 ; Test Bits
+

bitfetch_flagsetzer:
  bit #z, sr
  subc @r4, @r4
  ret
  ;------------------------------------------------------------------------------
      ; Entry point for compiling with at least one folding constant.

      mov #0B0A2h, r12  ; r12 is already saved on this special entry point.
      ; bis #00400h for bit.b @r4,  &Address = 0B4E2h
      ; bis #00010h for bit.b @pc+, &Address = 0B0F2h

bitfetch_opcodierung:

      cmp #1, r11 ; Exactly one folding constant available ?
      jne +
        ; Only address is fixed by constant.
        bis #00400h, r12  ; Switch Opcode to correct mode
        pushda r12
        call #doppelkomma ; Write Opcode and Address
        ; Zero constants left.
        clr &konstantenfaltungszeiger
        jmp bitfetch_flagsetzerschreiben

+     ; At least two constants. Address and Bitmask are fixed by folding constants.
      bis #00010h, r12

          to_r ; Move needed constants to return stack
          to_r
          decd r11
          call #interpret_konstantenschreiben ; Write out all other constants left.
          call #zwei_r_from ; Fetch back and SWAP !

      pushda #08324h ; decd r4
      call #komma

      ; Now I have two constants in right order available.

      call #pushda_r12_konstantenopcodierer ; Write Opcode+Bitmask
      call #komma                           ; Write Address

bitfetch_flagsetzerschreiben:
      pushda #bitfetch_flagsetzer ; Writes sequence bit #z, sr
      br #inlinekomma             ;                 subc @r4, @r4

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "cxor!" ; Toggles Bits ( n addr -- )

  popda r7 ; Fetch Address
  xor.b @r4, @r7 ; Toggle Bits
  drop
  ret
  .word 0e0f2h ; Opcode ! xor.b #Constant, &Address. Use e4f2 for xor.b @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "xor!" ; Toggles Bits ( n addr -- )

  popda r7 ; Fetch Address
  xor @r4+, @r7 ; Toggle Bits
  ret
  .word 0e0b2h ; Opcode ! xor #Constant, &Address. Use e4b2 for xor @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "cbic!" ; Clears Bits ( n addr -- )

  popda r7 ; Fetch Address
  bic.b @r4, @r7 ; Clear Bits
  drop
  ret
  .word 0c0f2h ; Opcode ! bic.b #Constant, &Address. Use c4f2 for bic.b @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "bic!" ; Clears Bits ( n addr -- )

  popda r7 ; Fetch Address
  bic @r4+, @r7 ; Clear Bits
  ret
  .word 0c0b2h ; Opcode ! bic #Constant, &Address. Use c4b2 for bic @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "cbis!" ; Sets Bits ( n addr -- )

  popda r7 ; Fetch Address
  bis.b @r4, @r7 ; Set Bits
  drop
  ret
  .word 0d0f2h ; Opcode ! bis.b #Konstante, &Adresse. Für die Wirkung bis.b @r4+, &Adresse muss ich d4f2 benutzen.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "bis!" ; Sets Bits ( n addr -- )

  popda r7 ; Fetch Address
  bis @r4+, @r7 ; Set Bits
  ret
  .word 0d0b2h ; Opcode ! bis #Constant, &Address. Use d4b2 for bis @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2constant" ; ( d -- ) Creates a double constant.
;------------------------------------------------------------------------------
  call #create
  call #dliteralkomma
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "constant" ; ( n -- ) Creates a constant.
;------------------------------------------------------------------------------
  call #create
  call #literalkomma

+ call #retkomma

setze_faltbarflag_und_smudge:
  call #setze_faltbarflag
  br #smudge

; Variables in Flash:
; pushda #Address ret Initial-Value

; Variables in Ram:
; pushda #Adresse ret Value

; Difference is that address of flash-variables is somewhere in Ram
; initialisation values are copied to this location.
; Because of this similiarities, they share most of the code.

; To allocate Ram-Memory, flag the word with Flag_ramallot|Size in words and
; decrement the variable pointer accordingly. Check, if there is enough Ram first.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2variable" ; ( Low High -- )
  ; Creates an initialised double variable
;------------------------------------------------------------------------------
  pushda #2
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "variable" ; ( n -- )
  ; Creates an initialised variable
;------------------------------------------------------------------------------
  pushda #1
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "nvariable" ; ( Init-Values Length -- )
; Creates an initialised variable of given length.
;------------------------------------------------------------------------------
  tst @r4
  jz buffer ; Zero-length variables ? They can be implemented with buffer:
 
+ call #create

  ; On Stack: ( Init-Values Length -- )
  ; Prepare code and put initial values in place.

  cmp #nBacklinkgrenze, &DictionaryPointer
  jlo nvariable_fuer_ram
    ; Flash-variables allocate Ram. Is there enough left ?

    and #000Fh, @r4 ; Maximum length for flash variables !

    mov #Flag_ramallot, &FlashFlags ; Only do this when writing to flash.
    bis @r4, &FlashFlags ; How many words should be initialised ?

    sub @r4, &VariablenPointer
    sub @r4, &VariablenPointer  ; Subtract two times the size in words to get size in bytes.

    pushda &VariablenPointer ; Ram-Address for new variable
    jmp nvariable_codeschreiben

nvariable_fuer_ram:
  pushda &DictionaryPointer ; Use this address for normal variables in Ram.
  add #10, @r4 ; Pointer to value in a place 10 bytes ahead of the code.

  ; ( Init-Values Length Ram-Address -- )
nvariable_codeschreiben:  ; You could weed out some instructions here if you always compile to Ram only.
  push r10
  push r11
  mov @r4, r11 ; Fetch target address

  call #literalkomma ; Compile target address
  call #retkomma

  ; ( Init-Values... Length -- )
  ; Write given amount of initialisation values (to flash) and update ram locations.

  popda r10 ; Fetch Length
  ; ( Init-Values... )

- mov @r4, @r11  ; This way Ram-Variables get initialised twice, but it doesn't matter :-)
  incd r11
  call #komma ; Put initialisation in place.
  dec r10
  jnz -

+ pop r11
  pop r10

  jmp setze_faltbarflag_und_smudge
  ; Variables have flag for folding set, but that doesn't matter as Ramallot-Flag is checked for first.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "buffer:" ; ( Length -- )
; Creates an uninitialised buffer of given length.
;------------------------------------------------------------------------------
buffer:
  ; On Stack: ( Length -- )
  bit #1, @r4 ; Adjust to even length
  adc @r4

    cmp #nBacklinkgrenze, &DictionaryPointer
    jlo buffer_fuer_ram
      ; Flash-Variables allocate Ram. Is there enough left ?
      mov &VariablenPointer, r7
      sub @r4, r7
      jnc + ; Check for 16-Bit-Rollover
      cmp #nRamDictionaryAnfang, r7
      jhs ++
+       writeln "Not enough RAM"
        br #quit

+     call #create
      mov #Flag_ramallot, &FlashFlags ; Only do this when writing to flash.
      sub @r4, &VariablenPointer
      pushda &VariablenPointer ; Ram-Address for new variable
      call #literalkomma ; Compile target address
      call #retkomma
      call #komma ; Length of buffer
      jmp setze_faltbarflag_und_smudge

buffer_fuer_ram:
  call #create
  pushda &DictionaryPointer ; Use this address for normal variables in Ram.
  add #10, @r4 ; Pointer to value in a place 10 bytes ahead of the code.
  ; ( Length Ram-Address -- )
  call #literalkomma ; Compile target address
  call #retkomma
  call #allot
  jmp setze_faltbarflag_und_smudge
  ; Variables have flag for folding set, but that doesn't matter as Ramallot-Flag is checked for first.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "+!" ; Plus-Store ( n addr -- )

  popda r7 ; Fetch address
  add @r4+, @r7 ; Add
  ret
  .word 50b2h ; Opcode ! add #Constant, &Address. Use 54b2 for add @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "c+!" ; C-Plus-Store ( n c-addr -- )

  popda r7 ; Fetch address
  add.b @r4, @r7 ; Add
  drop
  ret
  .word 50f2h ; Opcode ! add.b #Constant, &Address. Use 54f2 for add.b @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2!" ; Store ( d addr -- )
    popda r7 ; Fetch address
    popda @r7  ; High-Word to Address
    incd r7
    popda @r7  ; Low-Word to Address+2
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2@" ; Fetch ( addr -- d )
    mov @r4, r7  ; Fetch address
    decd r4
    mov @r7+, @r4
    mov @r7, 2(r4)
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "c!" ; c-Store ( c addr -- )
    popda r7  ; Fetch address
    mov.b @r4, @r7 ; Put character into
    drop
  ret
  .word 40f2h ; Opcode ! mov.b #Constant, &Address. Use 44f2 for mov.b @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherlesen, "c@" ; c-Fetch ( addr -- c )
c_fetch:
    mov @r4, r7  ; Fetch address
    mov.b @r7, r7 ; Fetch content of this address
    mov r7, @r4  ; Put content on datastack
  ret
  .word 42d4h ; Opcode ! mov.b &Address, 0(r4). You have to insert decd r4 = $8324 before.
              ;          High-Byte in stack keeps random. Clear with clr.b 1(r4)

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherschreiben, "!" ; Store ( n addr -- )
    popda r7  ; Fetch address
    popda @r7 ; Put data into
  ret
  .word 40b2h ; Opcode ! mov #Constant, &Address. Use 44b2 for mov @r4+, &Address

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_opcodierbar_speicherlesen, "@" ; Fetch ( addr -- n )
    mov @r4, r7  ; Fetch address
    mov @r7, @r4 ; Fetch content of this address into datastack
  ret
  .word 4294h ; Opcode ! mov &Address, 0(r4). You have to insert decd r4 = $8324 before.

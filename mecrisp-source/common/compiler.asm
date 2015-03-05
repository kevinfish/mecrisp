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
; 
; Compiler: Fill your Dictionary with Comma, Create and Joy :-)

;------------------------------------------------------------------------------
; --- Grow your dictionary ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "dictionarystart" ; ( -- Address ) Gives back start of currently active dictionary
dictionarystart: ; ( -- Start-of-Dictionary  )
                 ; Entry point for dictionary searches.
                 ; This is different for RAM and for Flash and it changes with new definitions.
;------------------------------------------------------------------------------
  decd r4
  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs +
  ; For Ram:
    mov &Fadenende, @r4
    ret
+ ; For Flash
    mov #CoreDictionaryAnfang, @r4
    ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "dictionarynext" ; @ ( Address -- Address flag )
dictionarynext: ; Scans dictionary chain and returns true if end is reached.
;------------------------------------------------------------------------------
  inc @r4                 ; Skip Flags
  call #stringueberlesen  ; Skip Name
  mov @r4, r7             ; Fetch address of Link field
  mov @r7, r7             ; Fetch link field
  mov r7, @r4             ;   and store on stack.

  pushda #-1   ; Prepare true flag

  cmp #-1, r7  ; Link field of $FFFF means end of dictionary.
  jeq +
  cmp #-1, @r7 ; Does link point to a location containing $FFFF ? End of dictionary, too.
  jeq +
    clr @r4    ; End not reached yet --> false flag
+ ret

;------------------------------------------------------------------------------
nullprobekomma: ; Writes a zero test into dictionary.
;------------------------------------------------------------------------------
  pushdadouble #0FFFEh, #0B4B4h   ; Opcode for bit @r4+, -2(r4)
                                  ; Check first element of stack for zero and remove it.
;------------------------------------------------------------------------------
doppelkomma: ; Writes two words into dictionary
  call #komma
  jmp komma

;------------------------------------------------------------------------------
nullkomma: ; Writes a zero into dictionary
  pushda #0
  jmp komma

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, ","
komma: ; ( n -- ) Writes one word into dictionary
;------------------------------------------------------------------------------
  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs +
    ; Für Ram
    mov &DictionaryPointer, r7
    mov @r4+, @r7
    jmp ++

+   ; Für Flash
    pushda &DictionaryPointer
    call #flashstore
+

zwei_allot:
  pushda #2
  jmp allot

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "c,"
ckomma: ; ( c -- ) Writes a byte into dictionary
;------------------------------------------------------------------------------
  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs +
    ; For Ram
    mov &DictionaryPointer, r7
    mov.b @r4, @r7
    incd r4
    jmp ++
+   ; For Flash
    pushda &DictionaryPointer
    call #flashCstore
+
  pushda #1
  jmp allot

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "align"
kommagrade: ; Aligns dictionary pointer by writing a zero if needed.
;------------------------------------------------------------------------------
  bit #1, &DictionaryPointer
  jnc +
  pushda #0
  jmp ckomma
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_foldable_1, "aligned"
;------------------------------------------------------------------------------
  bit #1, @r4
  adc @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate|Flag_foldable_0, "[char]" ; ( -- )
    ; Gets a character from input stream and make it available for folding
;------------------------------------------------------------------------------
  jmp holechar

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "char" ; Gets a character from input stream
holechar: ; ( -- Char )
;------------------------------------------------------------------------------
  call #token ; ( String-Address Length )
  drop
  br #c_fetch ; Fetch character

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "string,"
kommastring: ; ( String-Address Length -- )
             ; Inserts a string into dictionary and aligns it
;------------------------------------------------------------------------------
  push r10
  push r11
  and.b #-1, @r4 ; Maximum string length

  mov @r4, r11 ; Length of string
  call #ckomma ; Write length byte
  popda r10 ; Address of string

  tst r11
  jz +

- decd r4
  mov.b @r10+, @r4 ; Fetch next byte
  call #ckomma
  dec r11
  jnz -

+ pop r11
  pop r10

  jmp kommagrade ; Align dictionary

;------------------------------------------------------------------------------
pushda_r12_konstantenopcodierer:
  pushda r12
  jmp +
;------------------------------------------------------------------------------
mov_konstantenopcodierer: ; ( x -- )  Writes a Mov-Opcode to dictionary
  pushda #40B4h ; mov #Constant, ...(r4)
;------------------------------------------------------------------------------
konstantenopcodierer: ; ( x Opcode -- )
                      ; Generate code for instructions with constants. 
                      ; Take special care for constant generator values -1, 0, 1, 2, 4, 8
                      ; This improves code quality and size a lot !
;------------------------------------------------------------------------------
+ push r10

  mov @r4, r7 ; Fetch Opcode, but don't remove from stack.
  bic #0F30h, r7 ; Remove Source-Addressing-Mode @pc+

  mov 2(r4), r10  ; Fetch desired Constant

  cmp #0, r10
  jne +
  bis #0300h, r7
  jmp literalkomma_opcodieren

+ cmp #1, r10
  jne +
  bis #0310h, r7
  jmp literalkomma_opcodieren

+ cmp #2, r10
  jne +
  bis #0320h, r7
  jmp literalkomma_opcodieren

+ cmp #-1, r10
  jne +
- bis #0330h, r7
  jmp literalkomma_opcodieren

+ cmp #255, r10
  jne +
  bit #ByteOpcodeBit, r7 ; Check for byte instruction. In this case I can opcode 255 as -1.
  jc -

+ cmp #4, r10
  jne +
  bis #0220h, r7
  jmp literalkomma_opcodieren

+ cmp #8, r10
  jne +
  bis #0230h, r7
literalkomma_opcodieren:
  ; ( x Opcode )
  drop
  ; ( x )
  mov r7, @r4
  ; ( Opcode* )
  jmp ++

+ ; When reaching this, the constant cannot be generated by constant generator.
  call #komma ; Write normal Opcode
+ pop r10
  jmp komma   ; Number or Constant-Generator-Opcode, common to both execution paths.


;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "literal,"
literalkomma: ; ( n -- ) Writes a literal into dictionary
;------------------------------------------------------------------------------
  push r11
  mov #1, r11
- call #interpret_konstantenschreiben ; The helper for folding handles this with glee.
  pop r11
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "2literal,"
dliteralkomma: ; ( d -- ) Writes a double literal into dictionary
               ; ( n2 n1 -- ) and needs less code for that than two single literal,
               ;              as stack pointer is updated only once.
;------------------------------------------------------------------------------
  push r11
  mov #2, r11
  jmp -

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "inline,"
inlinekomma: ; ( Code-Address -- )
             ; Writes code into dictionary until a ret opcode is found.
             ; Take care if your definition contains multiple rets or 
             ; constants or strings that contain something looking like ret.
;------------------------------------------------------------------------------
  push r10

  popda r10 ; Fetch Code start for inlining

- mov @r10+, r7  ; Fetch Data
  cmp #4130h, r7 ; Ret-Opcode ?
  je +            ; If yes, finished.

  pushda r7
  call #komma
  jmp -

+ ; Ret found, finished.
  pop r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "call,"
callkomma:    ; ( n -- ) Writes a subroutine call into dictionary
;------------------------------------------------------------------------------
  pushda #12B0h   ; Write Opcode for call #... = call @pc+
  jmp doppelkomma ; and Address itself

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "ret,"
retkomma:    ; Writes a Return into dictionary
;------------------------------------------------------------------------------
  pushda #4130h ; Code für ret = mov @r1+, r0
  jmp komma

;------------------------------------------------------------------------------
;  Wortbirne Flag_visible, "latest" ; ( -- Address  ) Gives back address of current definition
;------------------------------------------------------------------------------
;  pushda &Fadenende ; Internal use only, no external access anymore.
;  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "flashvar-here" ; ( -- Address ) Gives back Flash variable pointer
;------------------------------------------------------------------------------
  pushda &VariablenPointer
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "here" ; ( -- Address ) Gives back dictionary pointer
;------------------------------------------------------------------------------
  pushda &DictionaryPointer
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "allot" ; Allocates space in dictionary without writing to it.
allot:  ; Includes checks for memory borders !
;------------------------------------------------------------------------------
  mov &DictionaryPointer, r7
  add @r4+, r7

  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs +
    cmp &VariablenPointer, r7   ; As long as pointer is within Ram
    jlo ++  
    writeln " Ram full"
    jmp quit

+ cmp #nFlashDictionaryEnde, r7
  jlo +  ; Check against end of user dictionary space in Flash
  writeln " Flash full"
  jmp quit

+ mov r7, &DictionaryPointer
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "(create)"
create: ; Create takes a token from input stream and writes a new header into dictionary.
        ; Note that freshly created words have NO standard action - they are simply empty.
;------------------------------------------------------------------------------
  call #token  ; Get a name for new definition
  ; ( Name-String-Address Length )

  ; Check whether the string is empty. This happens if input buffer is empty directly after invocation of create.
  tst @r4
  jne +
    ; No name ?
    writeln " Create needs name !"
    jmp quit

+ ; Name accepted.
  ; It is known before ? Check for redefinitions !

  ; ( Name Length )
  ddup
  call #wortsuche
  ; ( Name Length Entry Flags )
  drop ; No need for Flags here, as I only want to know if it exists.
  ; ( Name Length Entry )
  popda r7
  ; ( Name Length )
  tst r7 ; Entry Point is zero if not found.
  je +

    write "Redefine "
    ddup
    call #type   ; Print name
    writeln "."

+ ; ( Name Length )

  call #kommagrade ; Align dictionary pointer, just in case. Maybe someone did c, just before and forget to align.
  push &DictionaryPointer

  pushda #Flag_invisible  ; $FF
  call #ckomma            ; In Flash $FF never gets written, and in Ram this doesn't matter.
  mov #Flag_visible, &FlashFlags   ; For Flash

  ; Write Name-String into dictionary
  call #kommastring

  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs +
    ; For RAM - Links
    pushda &FadenEnde
    call #komma
    jmp ++

+   ; For Flash - Backlinks

  ; Prepare and insert Backlink
  call #zwei_allot ; Allot two bytes for backling that is filled in later

  ; Insert Backlink into hole in last definition
  ; Calculate address of link field of last definition:
    call #Fadenende_Einsprungadresse  ; Fetch address of code start of last definition
    popda r7                ; put it into register
    decd r7                 ; Link field is two bytes before code start
    cmp #0FFFFh, @r7        ; Is link field empty ?
    jne +                    ; If yes,
      pushdadouble @sp, r7    ; set link of last definition to current definition.
      call #flashstore
+

  pop &FadenEnde ; Current definition is new "latest"
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "compiletoram?"
;------------------------------------------------------------------------------
  pushda #-1
  cmp #nBacklinkgrenze, &DictionaryPointer
  jlo +
    clr @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "compiletoram" ; New definitions compile into Ram
compiletoram:
;------------------------------------------------------------------------------
  cmp #nBacklinkgrenze, &DictionaryPointer
  jlo +

  call #zweitpointertausch ; Exchange pointers

  cmp &VariablenPointer, &DictionaryPointer ; Check if freshly defined variables in flash collide with dictionary in Ram.
  jlo +                                     ; Flash has priority, so this is checked late.
    writeln " Variables collide with dictionary"  ; Issue a warning if that happens !

+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "compiletoflash" ; New definitions compile into Flash
compiletoflash:
;------------------------------------------------------------------------------
  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs +

zweitpointertausch: ; Exchange pointers
  mov &DictionaryPointer, r7
  mov &ZweitDictionaryPointer, &DictionaryPointer
  mov r7, &ZweitDictionaryPointer

  mov &FadenEnde, r7
  mov &ZweitFadenEnde, &FadenEnde
  mov r7, &ZweitFadenEnde

+ ret

;------------------------------------------------------------------------------
; --- Links & Flags ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
Fadenende_Einsprungadresse: ; ( Entry-Point -- Code-Start-Address )
                ; Calculates code start address from flag field address
;------------------------------------------------------------------------------
  pushda &Fadenende
  inc @r4                  ; Flags
  call #stringueberlesen   ; Name
  incd @r4                 ; Link  überlesen
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "smudge"
smudge: ; Renders current definition visible and writes collected flags to flash.
        ; As Flash cannot written mutiple times, all Flags for a new definition
        ; are collected in a variable FlashFlags and written at once when definition is finished.
        ; Because of that, inline and immediate have to be INSIDE of a definition when compiling into flash.
;------------------------------------------------------------------------------
  ; In Ram, smudge simply has to make current definition visible.
  ; In Flash, smudge has to check if current definition ends with $FFFF.
  ; This is important as that would be recognized ad free space on pointer catching on next Reset
  ; and would be overwritten later. 
  ; To prevent this, smudge writes an additional zero into dictionary in that case.

    cmp #nBacklinkgrenze, &DictionaryPointer
    jhs smudge_flash

    ; Few to do in Ram:
    mov #Flag_visible, r7
    jmp flagsetzer

smudge_flash:
    ; More work in Flash:

    ; Check for $FFFF at the end.
    mov &DictionaryPointer, r7
    cmp #-1, -2(r7) ; Decrement, as Dictionary pointer points to first free location.
    jne +
    call #nullkomma  ; Write zero into dictionary.
+   ; Definition has fine ending now.

    ; Set Flags.
    push &DictionaryPointer
    mov &FadenEnde, &DictionaryPointer
    pushda &FlashFlags
    call #ckomma
    pop &DictionaryPointer
    ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "compileonly"
;------------------------------------------------------------------------------
  mov #Flag_inline|Flag_immediate, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "inline"
; Flags current definition as inline.
; Has to be INSIDE of definition if compiling into flash !
;------------------------------------------------------------------------------
  mov #Flag_inline, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "immediate"
; Flags current definition as immediate.
; Has to be INSIDE of definition if compiling into flash !
;------------------------------------------------------------------------------
  mov #Flag_immediate, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
setze_faltbarflag: ; Flags current definition as 0-foldable
  mov #Flag_foldable, r7
  jmp flagsetzer
;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "setflags" ; Flags current definition and collects Flags if compiling into flash
  popda r7

flagsetzer: ; Internal entry with r10 saved and containing flag.
;------------------------------------------------------------------------------
  cmp #nBacklinkgrenze, &DictionaryPointer
  jhs flagsetzer_flash

  push r11
  mov &Fadenende, r11
  cmp.b #-1, @r11      ; Freshly defined words have $FF meaning invisible.
  jne +
  mov.b r7, @r11
  jmp ++
+ bis.b r7, @r11
+ pop r11
  ret

flagsetzer_flash:
  bis.b r7, &FlashFlags
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "find"
Wortsuche: ; ( Name-String-Address Length -- Entry-Point Flags )
           ; Takes address and length of string and searches for it in dictionary.
           ; Gives back entry point address and flags.
           ; If not found, the ADDRESS is zero ! Flags have special meanings in Mecrisp.
;------------------------------------------------------------------------------
  push r10  ; Current Address in Dictionary
  push r11  ; Current Flags
  push r12  ; Address of latest hit
  push r13  ; Flags   of latest hit
  push r14  ; Backup  of name

  call #dictionarystart
  popda r10

  clr r12   ; Nothing found yet
  clr r13   ; No flags yet

  ; Stack contains ( Name-String-Address Length )

  ; Header: Flags     Length of name
  ;         Name...   0 (for aligning, if needed)
  ;         Link
  ;         Code

- mov.b @r10+, r11 ; Save Flags for later use
  mov r10, r14 ; Save address of name for later comparision
  call #stringueberlesen_r10 ; Skip name string and advance to link field
  ; ( Name-String-Address )

  ; Check visibility:
  cmp.b #-1, r11 ; $FF denotes invisibility:
  jc +           ; Skip invisible definitions.

  ; Only do name comparisions with visible definitions.
    ddup ; ( Addr Len Addr Len )
    pushda r14
    call #count
    ; ( Name Name Name-of-current-definition-in-dictionary )
    call #flagstringvergleich
    bit @r4+, -2(r4)
    jz +

    ; Found:
    mov r10, r12 ; Store its address
    incd r12     ; Skip link field and advance pointer to code start
    mov r11, r13 ; Store Flags

    ; For Ram, task is done with first hit.
    ; For Flash with Backlinks, we have to search through whole dictionary and 
    ; report latest hit to allow redefinitions. Continue in this case.

    cmp #nBacklinkgrenze, r12 ; Determine Ram / Flash with address range.
    jlo ++ ; Finished when searching in Ram, continue when searching in flash.

+ ; Continue searching

  mov @r10, r10
  cmp #0FFFFh, r10  ; $FFFF-Links denote end of dictionary
  je +
  cmp #0FFFFh, @r10 ; $FFFF at the place for flags and length ? End of Dictionary found !
  jne -

+ ; Finished.
  mov r12, 2(r4) ; Replace string address on stack with code start address
  mov r13, @r4   ; Put Flags on stack

  pop r14
  br #ende_pop_13_10

;------------------------------------------------------------------------------
; --- Compiler ---
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "execute" ; Execute address on datastack.
;------------------------------------------------------------------------------
  call @r4+
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "recurse" ; For recursion. Calls the freshly defined definition.
;------------------------------------------------------------------------------
  call #Fadenende_Einsprungadresse
  jmp callkomma

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "postpone" ; Search for next token in input stream
                                               ; and compile this in a special way.
;------------------------------------------------------------------------------
  call #tick ; Tick delivers Flags in r7 !

  bit #010h, r7
  jc callkomma ; Immediate

+ bit #020h, r7
  jnc +
  ; Inline
    call #literalkomma    ; Write Entry-Point as literal into dictionary
    pushda #inlinekomma   ; Write a call to inline,
    jmp callkomma         ;   into dictionary

+ ; Normal
    call #literalkomma    ; Write Entry-Point as literal into dictionary
    pushda #callkomma     ; Write a call to call,
    jmp callkomma         ;   into dictionary

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "does>"
does: ; Gives freshly defined word a special action.
      ; Has to be used together with <builds !
;------------------------------------------------------------------------------
    ; At the place where does> is used, a jump to dodoes is inserted and
    ; after that a R> to put the address of the definition entering the does>-part
    ; on datastack. This is a very special implementation !

    call #dodoes
    r_from        ; This makes for the inline R> in definition of defining word !
  ret ; Very important as delimiter as does> itself is inline.

dodoes:
  ; The call to dodoes never returns.
  ; Instead, it compiles a call to the part after its invocation into the dictionary
  ; and exits through two call layers.

  ; Have a close look on the stacks:
  ; ( ) ( R: Return-of-defining-definition-that-called-does>  Return-of-dodoes-itself )

  push &DictionaryPointer ; Push Dictionary pointer before changing it as , is the easiest way handle writing code to flash or ram.
  ; ( ) ( R: Return-of-defining-definition-that-called-does>  Return-of-dodoes-itself Old-Dictionary-Pointer )
  ; Fetch address to where a call should be inserted:
  call #Fadenende_Einsprungadresse ; Call into does>-part should be inserted into CURRENT definition. Calculate pointer.
  ; ( Place-to-insert-call-opcode ) ( R: Return-of-defining-definition-that-called-does>  Return-of-dodoes-itself Old-Dictionary-Pointer )
  mov @r4, &DictionaryPointer ; This is the place to insert the call-opcode !
  mov 2(sp), @r4  ; Target-Address for call-opcode is return address of dodoes which points to the does>-part of defining word.  
  ; ( Call-Target-Address ) ( R: Return-of-defining-definition-that-called-does>  Return-of-dodoes-itself Old-Dictionary-Pointer )
  call #callkomma ; Write call into dictionary
  ; ( ) ( R: Return-of-defining-definition-that-called-does>  Return-of-dodoes-itself Old-Dictionary-Pointer )
  pop &DictionaryPointer ; Restore dictionary pointer.
  ; ( ) ( R: Return-of-defining-definition-that-called-does>  Return-of-dodoes-itself )
  incd sp ; Remove one return layer
  ; ( ) ( R: Return-of-defining-definition-that-called-does> )
  jmp smudge ; Render current definition visible and Return

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "<builds"
builds: ; Brother of does> that creates a new definition and leaves space to insert a call instruction later.
;------------------------------------------------------------------------------
  call #create  ; Create new empty definition
  pushda #4 ; A call instruction will go here - but I don't know its target address for now.
  jmp allot ; Make a hole 4 bytes big to insert it later.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "create"
;------------------------------------------------------------------------------
  call #builds
  ; Copy of the inline-code of does>
  call #dodoes
  r_from
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "state"
  CoreVariable state
;------------------------------------------------------------------------------
  pushda #state
  ret
  .word 0

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "]" ; Switch to compile mode
  mov #-1, &state ; true-Flag for State
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "[" ; Switch to execute mode
  clr &state ; false-Flag for State
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, ";"
  ; Finishes a definition and renders it visible.
;------------------------------------------------------------------------------
  cmp r4, &Datenstacksicherung ; Compare stack fill level with saved value for simple syntax checking
  je +
    writeln " Stack not balanced."
    br #quit

+ clr &state ; false-Flag for State --> Execute Mode
  call #retkomma
  jmp smudge

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, ":"
  ; Opens a new definition
;------------------------------------------------------------------------------
  mov r4, &Datenstacksicherung ; Save current fill level of datastack for simple syntax checking

  call #create    ; Create a new definition
  mov #-1, &state ; true-Flag for State --> Compile Mode
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "0-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_0, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "1-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_1, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "2-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_2, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "3-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_3, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "4-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_4, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "5-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_5, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "6-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_6, r7
  jmp flagsetzer

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate, "7-foldable"
;------------------------------------------------------------------------------
  mov #Flag_foldable_7, r7
  jmp flagsetzer

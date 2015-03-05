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

; Interpret and Optimizations.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_immediate|Flag_foldable_0, "[']" 
  ; Search for a definition and make its code address available for folding
;------------------------------------------------------------------------------
  jmp tick

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "'" ; Sucht das nächste Wort im Eingabestrom
tick: ; ( -- Code-Address ) Search for a definition
;------------------------------------------------------------------------------
  push r10
  push r11

  call #token
  ; ( String Length )
  mov 2(r4), r10 ; Address of string
  mov @r4, r11   ; Length  of string

  call #wortsuche
  ; ( Entry-Point Flags )
  mov @r4+, r7 ; "Drop" Flags into r7 for postpone !
  ; ( Entry-Point )
  tst @r4
    jeq unknown_r10_r11

  pop r11
  pop r10
  ret

; -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "evaluate" ; ( ... Address Length -- ... )
; -----------------------------------------------------------------------------
  push &current_source
  push &current_source+2
  push &Pufferstand

  call #setsource
  clr &Pufferstand
  call #interpret

  pop &Pufferstand
  pop &current_source+2
  pop &current_source
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "interpret"
interpret: ; Interprets contents of input buffer with lots of special wizardy.
;------------------------------------------------------------------------------
  push r10
  push r11
  ; Stack empty, at least for interprets scope. Interrupts, you know...

interpret_weitermachen: ; This is an important loop return point.
  ;------------------------------------------------------------------------------
  ; Check for stack borders, catch over- and underflows.
  ; Check only for datastack, as returnstack mistakes most likely crash system.

  cmp #datenstackanfang+2, r4
  jlo +
  writeln " Stack underflow"
  jmp quit

+ cmp #datenstackende, r4
  jhs +
  writeln " Stack overflow"
  jmp quit

+ ; Stack is ok.
  ;------------------------------------------------------------------------------

  call #token              ; Token crawls input buffer and gives back address and length of a string.
  tst @r4                  ; Check length of string.
  jne +                    ; Nothing inside ? Finished !
    ; Buffer empty, interpret has nothing more to do.
    ddrop ; Forget string completely.
    pop r11
    pop r10
    ret

  ;------------------------------------------------------------
+ ; Found token. Its on top of datastack.

  ; Set Constant-Folding-Pointer
  tst &Konstantenfaltungszeiger ; If not set yet, set it now.
  jne +
  mov r4, &Konstantenfaltungszeiger
  add #4, &Konstantenfaltungszeiger ; Adjust pointer as there still is token string address and length.
+ ; Pointer successfully updated.

  mov 2(r4), r10 ; Address of string
  mov @r4, r11   ; Length  of string

  ; ( Address Length )
  call #wortsuche      ; Attemp to find token in dictionary.
  ; ( Entry-Address Flags )
  tst 2(r4)            ; Entry-Address is zero if not found ! Note that Flags have very special meanings in Mecrisp !
  jne interpret_token  ; Jump to process a found token.

  ;------------------------------------------------------------
interpret_zahlen:
  ; Take care of numbers. Clean and simple !
  ; At the moment, there is ( 0 0 ) left on stack.

  mov r10, 2(r4) ; Put string address in place. Saves some moves on stack.
  mov r11, @r4   ; Put length in place

  call #number
  bit @r4+, -2(r4) ; Did number recognize the string ?
  jnz interpret_weitermachen ; Finished.

  ; Number gives back ( 0 ) or ( x 1 ) or ( Low High 2 ).
  ; Zero means: Not recognized.
  ; Note that literals actually are not written/compiled here.
  ; They are simply placed on stack and constant folding takes care of them later.

unknown_r10_r11:
  pushdadouble r10, r11 ; Get string address and length ready for typing
  call #type
  writeln " not found."
  jmp quit

  ;------------------------------------------------------------
interpret_token: ; Found token in dictionary. Decide what to do.
  ; ( Address Flags ) Results of Dictionary search.

  tst &state ; Compile or Execute ?
  jne interpret_kompilierzustand

  popda r7
  and #30h, r7
  cmp #30h, r7
  jne +
    pushdadouble r10, r11 ; Get string address and length ready for typing
    call #type
    writeln " is compile-only"
    jmp quit

+ ; Execute ! 
  clr &Konstantenfaltungszeiger ; Do not collect literals for folding in execute mode. They simply stay on stack.
  call @r4+
  jmp interpret_weitermachen

  ;------------------------------------------------------------
interpret_kompilierzustand:
  ; Time to compile. Lots of special cases and optimizations around !
  popda r10
  ; ( Entry-Address )  Flags in r10
  to_r ; Move Entry-Address to returnstack. Wish for folding constants only in datastack.

    ; Calculate number of folding constants available.
    mov &konstantenfaltungszeiger, r11
    tst r11
    jz +
    sub r4, r11
    jmp ++
+   clr r11
+   rra r11 ; Divide by two to get number of stack elements.
    ; Number of folding constants now available in r11.

    ; Check for possible optimizations !
    bit #Flag_ramallot, r10         ; Ramallot-Words always 0-foldable !
    jc interpret_faltoptimierung    ; Check this first, as Ramallot is set together with foldability,
                                    ; but the meaning of the lower 4 bits is different.

    bit #Flag_foldable, r10 ; Check for foldability.
    jnc interpret_unoptimierbar ; No ? Not optimizeable then.

    ; Check for opcodability.
    bit #Flag_opcodierbar, r10
    jnc +        ; Flag is set
    tst r11
    je +         ; And at least one constant is available for folding.
    jmp interpret_opcodierbar
+   ; Not opcodable.

    ; How many constants are necessary to fold this word ?
    mov r10, r7
    and #111b, r7 ; Lower 3 bits give number of folding constants needed.
    cmp r7, r11
    jlo interpret_unoptimierbar

interpret_faltoptimierung: ; Do folding by running the definition. Note that Constant-Folding-Pointer is already set to keep track of results calculated.
    pop r10
    call r10  ; Don't try call @sp+ instead, as this crashes CPU.
    jmp interpret_weitermachen


interpret_unoptimierbar:
    ; No optimizations possible. Compile the normal way.
    call #interpret_konstantenschreiben ; Write all folding constants left into dictionary.
  r_from ; Fetch back entry address.
;------------------------------------------------------------
; interpret_klassisch_kompilieren: ; ( Entry-Address ) Flags in r10
  push #interpret_weitermachen    ; Return-Address to interpret loop. Saves space.
  bit #Flag_immediate, r10        ; Is definition immediate ?
  jnc interpret_einkompilieren
  br @r4+                         ; Run it.

interpret_einkompilieren:
  bit #Flag_inline, r10           ; Is definition inline ?
  jc inlinekomma                  ; Inline it.
  jmp callkomma                   ; Classical compile as subroutine call.

;------------------------------------------------------------
; Helpers for interpret follow
;------------------------------------------------------------

ByteOpcodeBit equ 040h ; Bit in Opcode that denotes byte instructions.

;------------------------------------------------------------------------------
interpret_opcodierbar: ; Flags of Definition in r10
                       ; Number of folding constants available in r11, at least one
                       ; Entry-Point of Definition on Returnstack
;------------------------------------------------------------------------------
  ; There is something opcodable, and at least one folding constant is available.
  ; Check for the different opcodable cases and do the work.

  push r12
  mov 2(sp), r12 ; Fetch entry Point

  ; Decide on the different cases. As I don't return, I can change Flag register freely.
  and #111b, r10 ; Mask opcodability type

  cmp #1, r10
  jne ++
    ;------------------------------------------------------------------------------
    ; Calculus and Logic (Rechenlogik)

    cmp #1, r11 ; Opcode only with exactly one constant. Do folding with two constants or more in this case !
    je +
      pop r12   ; Register not needed for folding.
      jmp interpret_faltoptimierung ; Do folding
+   ; Exactly one constant. Do opcoding !
    call #inline_at_r4_plus ; Inline the definition and replace @r4+ instructions by @pc+ with constant instructions.
    jmp interpret_opcodierbar_fertig
+   ; Finished Calculus and Logic.


  ; Scan through code of definition until ret is found. 
  ; An Opcode or optimization code is placed after the first ret !
- incd r12            ; Step through code.
  cmp #4130h, -2(r12) ; Found ret on last location ? Then I have the address of special parts following the definition.
  jne -

    cmp #4, r10
    jne +
      ;------------------------------------------------------------------------------
      ; Special cases that do not have their own handling in interpret.
      ; They have their own handlers at the end of definition that is called here.
      ; At least one folding constant available, r10, r11, r12 are saved,
      ; r11 contains number of constants available for folding. Take care of those !

      call r12 ; Call special optimization handler.
      jmp interpret_opcodierbar_fertig ; Finished.
+

  ; All following cases are handled in interpret, they don't have a handler at its own and only carry an Opcode.
  ; r12 contains address of Opcode.
  mov @r12, r12 ; Fetch Opcode from the end of definition.

  cmp #2, r10
  jne interpret_opcodierbar_speicherlesen
    ;------------------------------------------------------------------------------
    ; Write Memory (Speicher schreiben)

    ; Two cases: Exactly one constant and at least two constants.
    cmp #1, r11
    je +
      ; At least two constants
      call #swap_sprung ; Performs swap, but shorter code
      call #pushda_r12_konstantenopcodierer ; Compile Opcode and Constant which is still left on datastack
      call #komma ; Compile next Constant as Address for write instruction
      jmp interpret_opcodierbar_fertig

    ; To do for one folding constant only:
    ; Opcode, adjusted for byte instructions
    ; Address
    ; For byte instructions additionally: incd r4

+   ; Exactly one constant:
    bis #0400h, r12 ; Switch Opcode from @r0+ to @r4+
    bit #ByteOpcodeBit, r12
    jnc +
      bic #10h, r12 ; Switch instruction.b @r4+, &Address into instruction.b @r4, &Address
+     ; Only change address mode on byte instructions !
    pushda r12 ; Put Opcode on datastack
    ; ( Destination-Address Opcode )
    call #doppelkomma

    bit #ByteOpcodeBit, r12 ; Byte-Writes cannot adjust stack pointer properly.
    jnc +                   ; We have to add incd r4 in that case.
      ; Write Memory Byte with one Constant only:
      call #dropkomma ; Compile Opcode for incd r4 = add #2, r4
+   ; Okay.
    jmp interpret_opcodierbar_fertig

interpret_opcodierbar_speicherlesen:
  ; As there are no more cases, there is no need for another check.
    ;------------------------------------------------------------------------------
    ; Read Memory (Speicher lesen)
    ; Needs exactly one constant, have at least one constant.
    ; Cannot be folded over, have to stop folding here.

    ; Benötige genau eine Konstante, Habe mindestens eine Konstante, zerstört Konstantenstack.
    ; Brauche die Einsprungadresse nicht mehr.

    mov @r4+, r10 ; Fetch folding constant as memory address
    dec r11       ; One constant less available
    call #interpret_konstantenschreiben ; Write constants left into dictionary

    pushdadouble r12, #8324h  ; decd r4
    call #doppelkomma         ; Opcode from r12
    pushdadouble #0, r10      ; Address
    call #doppelkomma         ; Zero for 0(r4)

    bit #ByteOpcodeBit, r12 ; Is this a byte-read ? For example: mov.b &Address, @r4 ?
    jnc +                   ; Then High-Byte is random on stack. Clear it !
      ; Read Memory Byte only:
      pushdadouble #0001h, #43c4h ; Opcode for clr.b 1(r4) $43c4 $0001
      call #doppelkomma
+   ; Finished.

interpret_opcodierbar_fertig:
    pop r12
    incd sp ; Forget entry point
    jmp interpret_weitermachen


;------------------------------------------------------------------------------
interpret_konstantenschreiben: ; Write folding constants to dictionary.
  ; Special requirements !
  ; - r11 number of folding constants to compile as literals, zero is ok, too.
  ; - Constant Folding Pointer set
;------------------------------------------------------------------------------
  rla r11  ; Multiply by two to get number of bytes.
  jz +     ; Nothing to do for zero folding constants

  pushdadouble r11, #08034h  ; sub #Size, r4
  call #konstantenopcodierer

  push r12 ; Save r12 as contents are needed later.
  clr r12

- call #mov_konstantenopcodierer ; Generate code for literals. This is the mov-Opcode with special care for constant generator values -1, 0, 1, 2, 4, 8
  pushda r12
  incd r12
  call #komma ; Index into stack. Instructions generated: mov #Constant, Index(r4)
  cmp r12, r11
  jne -

  pop r12

+ ; Folding is over. Clear Constant Folding Pointer.
  clr &konstantenfaltungszeiger
  ret


;------------------------------------------------------------------------------
inline_at_r4_plus: ; Inlines a definition and replaces @r4+ instructions with @pc+ and folding constants.
;------------------------------------------------------------------------------
  ; r10: Changed
  ; r11: Number of folding constants available
  ; r12: Address of code to inline

- mov @r12+, r10     ; Fetch instruction
  cmp #4130h, r10    ; Ret-Opcode ?
  je interpret_konstantenschreiben ; If yes, finished. Write constants left.

  ; Check for @r4+ instructions.
  pushda r10 ; Save the opcode for later, as the check changes r10.

  and #00F70h, r10  ; Mask Source-Address-Mode and Source-Register
  cmp #00430h, r10  ; @r4+ ?
  jne +

  ; Enough constants left ?
  tst r11
  jz +
    dec r11 ; One less.    
    bic #00400h, @r4 ; Switch Opcode to @pc+
    call #konstantenopcodierer ; Compile with special care for constant generator.
    jmp -

+ call #komma ; Simply comma in other instructions.
  jmp -


;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "hook-quit"
  CoreVariable hook_quit
;------------------------------------------------------------------------------
  pushda #hook_quit
  ret
  .word quit_innenschleife

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "quit"
quit: ; Main loop of Forth system.
;------------------------------------------------------------------------------
  ; Clear stacks and tidy up.
  mov #returnstackanfang, SP ; Returnstack
  mov #datenstackanfang,  r4 ; Datastack

  mov #10, &Base ; Base Decimal.
  clr &state     ; Execute Mode.
  clr &konstantenfaltungszeiger ; No constant folding in progress.
  clr &Pufferstand ; Start at the beginning
  mov #Eingabepuffer, &current_source+2 ; TIB is input source
  mov #0, &current_source               ; Empty

  br &hook_quit

quit_innenschleife:
  call #query
  call #interpret
  writeln " ok."
  jmp quit_innenschleife ; Infinite Loop


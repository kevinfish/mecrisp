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

; Case-Structure

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "case"
  ; ( -- 0 8 )
;------------------------------------------------------------------------------
  pushdadouble #0, #8
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "?of"
  ; ( ... #of 8 -- ... addr #of+1 9 )
  ; Takes Flag instead of constant. Useful to build your own comparisions for case.
;------------------------------------------------------------------------------
  cmp #8, @r4
  jne strukturen_passen_nicht

  ; A flag is on the stack. True:  Take this case !
  ;                         False: Continue. Jump with JNE !

  call #nullprobekomma   ; bit @r4+, -2(r4)
  mov #0b322h, @r4       ; bit #z, sr        Flips Z-Flag
  call #komma

  jmp of_inneneinsprung_fuer_qof

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly|Flag_opcodierbar_spezialfall, "of"
  ; ( ... #of 8 -- ... addr #of+1 9 )
;------------------------------------------------------------------------------
  cmp #8, @r4
  jne strukturen_passen_nicht

  mov #094B4h, @r4 ; Opcode for cmp @r4+, 0(r4)
  call #komma

of_inneneinsprung:
  call #nullkomma
of_inneneinsprung_fuer_qof:

  ; ( #of --> Addr #of+1)

  call #branch_v ; here 2 allot
  call #swap_sprung
  inc @r4

  pushda #9 ; Structure matching

dropkomma:
  pushda #05324h ; Opcode for drop
  call #komma
  ret ; Ret is needed for recognition of helper for opcoding. No Tail-Call-Optimisation here !

  ;------------------------------------------------------------------------------
  ; Entry with at least one constant:
  ;------------------------------------------------------------------------------
      ; As this is a special entry, r10 is already saved.
      ; I have at least one constant for building opcodes with.
      ; Folding-Constants are on top of stack !

      popda r10 ; Fetch folding constant into r10

        dec r11 ; Reduce number of folding constants
        call #interpret_konstantenschreiben ; End of folding. Write all constants left, whose number is in r11.

      cmp #8, @r4                 ; Cannot check this earlier because
      jne strukturen_passen_nicht ;   there have been folding constants on stack...

      mov r10, @r4
      mov #090b4h, r12
      call #pushda_r12_konstantenopcodierer   ; cmp #Constant, 0(r4)
      jmp of_inneneinsprung


;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "endof"
  ; ( ... addr-jne #of 9 -- ... addr-jmp #of 8 )
;------------------------------------------------------------------------------
  mov @r4+, r7
  cmp #9, r7
  jne strukturen_passen_nicht

  to_r ; #of on Returnstack

    call #branch_v    ; here 2 allot
    call #swap_sprung ; ( here Addr-jne )
    call #v_casebranch

  pushdadouble @sp+, #8
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_immediate_compileonly, "endcase"
  ; ( ... addrs-jmp #of 8 -- )
;------------------------------------------------------------------------------
  mov @r4+, r7
  cmp #8, r7
  jne strukturen_passen_nicht

  call #dropkomma

spruenge_einpflegen:
    ; Fill in collected jumps of ?do, leave and case.
    push r10
    popda r10 ; Fetch number of jumps to be filled in
    tst r10
    je +++

-   bit #1, @r4 ; Test if it should be a conditional or an unconditional jump:
    jnc +
      bic #1, @r4 ; Remove marker for conditional jump
      call #v_nullbranch
      jmp ++
+   call #v_branch
+   dec r10
    jnz -
+   pop r10 ; Finished with all jumps
  ret

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

; Common tools for interrupts

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "dint"
;------------------------------------------------------------------------------
  dint
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "eint"
;------------------------------------------------------------------------------
  eint
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "eint?"
;------------------------------------------------------------------------------
  decd r4
  bit #GIE, sr
  bit #z, sr
  subc @r4, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "nop"
nop_vektor:
;------------------------------------------------------------------------------
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "reset"
;------------------------------------------------------------------------------
  clr &wdtctl ; Reset with cold start

;------------------------------------------------------------------------------
null_handler: ; Catches unwired interrupts
;------------------------------------------------------------------------------
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "lpm0" ; ( -- )
  bis #LPM0|GIE, sr
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "lpm1" ; ( -- )
  bis #LPM1|GIE, sr
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "lpm2" ; ( -- )
  bis #LPM2|GIE, sr
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "lpm3" ; ( -- )
  bis #LPM3|GIE, sr
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "lpm4" ; ( -- )
  bis #LPM4|GIE, sr
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible_inline, "wakeup"
;------------------------------------------------------------------------------
  ; Return stack contents on entry: ( Return SR r7 PC )
  ; You can use this directly as interrupt handler.
  bic #lpm4, 4(sp)
  ret

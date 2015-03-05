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

; Hardware independent vectorized parts of terminal routines

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "hook-key?"
  CoreVariable hook_qkey
;------------------------------------------------------------------------------
  pushda #hook_qkey
  ret
  .word serial_qkey

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "hook-key"
  CoreVariable hook_key
;------------------------------------------------------------------------------
  pushda #hook_key
  ret
  .word serial_key

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "hook-emit?"
  CoreVariable hook_qemit
;------------------------------------------------------------------------------
  pushda #hook_qemit
  ret
  .word serial_qemit

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "hook-emit"
  CoreVariable hook_emit
;------------------------------------------------------------------------------
  pushda #hook_emit
  ret
  .word serial_emit

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "key?" ; ( -- Flag ) Check for key press, vectorized
qkey:
;------------------------------------------------------------------------------
  br &hook_qkey

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "key" ; ( -- c ) Fetch key, vectorized
key:
;------------------------------------------------------------------------------
  br &hook_key

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "emit?" ; ( -- Flag ) Ready to emit, vectorized
qemit:
;------------------------------------------------------------------------------
  br &hook_qemit

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "emit" ; ( c -- ) Emit character, vectorized
emit:
;------------------------------------------------------------------------------
  br &hook_emit

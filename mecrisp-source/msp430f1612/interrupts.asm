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

; Interrupt vectors and handlers that can be exchanged on the fly.

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-port1"
  CoreVariable irq_hook_port1
;------------------------------------------------------------------------------
  pushda #irq_hook_port1
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_port1:
  push r7
  call &irq_hook_port1
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-port2"
  CoreVariable irq_hook_port2
;------------------------------------------------------------------------------
  pushda #irq_hook_port2
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_port2:
  push r7
  call &irq_hook_port2
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-adc"
  CoreVariable irq_hook_adc
;------------------------------------------------------------------------------
  pushda #irq_hook_adc
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_adc:
  push r7
  call &irq_hook_adc
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-timera1"
  CoreVariable irq_hook_timera1
;------------------------------------------------------------------------------
  pushda #irq_hook_timera1
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_timera1:
  push r7
  call &irq_hook_timera1
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-timera0"
  CoreVariable irq_hook_timera0
;------------------------------------------------------------------------------
  pushda #irq_hook_timera0
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_timera0:
  push r7
  call &irq_hook_timera0
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-watchdog"
  CoreVariable irq_hook_watchdog
;------------------------------------------------------------------------------
  pushda #irq_hook_watchdog
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_watchdog:
  push r7
  call &irq_hook_watchdog
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-timerb1"
  CoreVariable irq_hook_timerb1
;------------------------------------------------------------------------------
  pushda #irq_hook_timerb1
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_timerb1:
  push r7
  call &irq_hook_timerb1
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-timerb0"
  CoreVariable irq_hook_timerb0
;------------------------------------------------------------------------------
  pushda #irq_hook_timerb0
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_timerb0:
  push r7
  call &irq_hook_timerb0
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-comp"
  CoreVariable irq_hook_comp
;------------------------------------------------------------------------------
  pushda #irq_hook_comp
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_comp:
  push r7
  call &irq_hook_comp
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-dac"
  CoreVariable irq_hook_dac
;------------------------------------------------------------------------------
  pushda #irq_hook_dac
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_dac:
  push r7
  call &irq_hook_dac
  pop r7
  reti

; Terminal interrupts for Glen :-)

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-tx0"
  CoreVariable irq_hook_tx0
;------------------------------------------------------------------------------
  pushda #irq_hook_tx0
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_tx0:
  push r7
  call &irq_hook_tx0
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-rx0"
  CoreVariable irq_hook_rx0
;------------------------------------------------------------------------------
  pushda #irq_hook_rx0
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_rx0:
  push r7
  call &irq_hook_rx0
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-tx1"
  CoreVariable irq_hook_tx1
;------------------------------------------------------------------------------
  pushda #irq_hook_tx1
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_tx1:
  push r7
  call &irq_hook_tx1
  pop r7
  reti

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_Variable, "irq-rx1"
  CoreVariable irq_hook_rx1
;------------------------------------------------------------------------------
  pushda #irq_hook_rx1
  ret
  .word nop_vektor  ; Initial value for unused interrupts

irq_vektor_rx1:
  push r7
  call &irq_hook_rx1
  pop r7
  reti

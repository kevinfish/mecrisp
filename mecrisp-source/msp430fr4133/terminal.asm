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

; Serial terminal routines for MSP430FR4133

;------------------------------------------------------------------------------
; Registers and Constants
;------------------------------------------------------------------------------

PM5CTL0  equ 0130h
LOCKLPM5 equ 1

WDTCTL   equ 01CCh

P1SEL0   equ 020Ah

;------------------------------------------------------------------------------
; UART

UCA0_Base equ 0500h

UCA0CTLW0 equ UCA0_Base
UCA0CTLW1 equ UCA0_Base +  2
UCA0BRW   equ UCA0_Base +  6
UCA0MCTLW equ UCA0_Base +  8
UCA0RXBUF equ UCA0_Base + 0Ch
UCA0TXBUF equ UCA0_Base + 0Eh
UCA0IFG   equ UCA0_Base + 1Ch

UCSWRST equ 1
UCSSEL__SMCLK equ 80h

UCBRF_1  equ 010h
UCBRF_5  equ 050h
UCBRF_8  equ 080h
UCBRF_13 equ 0D0h

UCRXIFG equ 1
UCTXIFG equ 2

;------------------------------------------------------------------------------
  Wortbirne Flag_visible|Flag_variable, "hook-pause"
  CoreVariable hook_pause
;------------------------------------------------------------------------------
  pushda #hook_pause
  ret
  .word nop_vektor

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "pause" ; ( -- )
pause:
;------------------------------------------------------------------------------
  br &hook_pause

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key?" ; ( -- Flag ) Check for key press
;------------------------------------------------------------------------------
serial_qkey:
  call &hook_pause
  pushda #0
  bit.b #UCRXIFG, &UCA0IFG
  jz +
  mov #-1, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key" ; ( -- c ) Fetch key
;------------------------------------------------------------------------------
serial_key:
- call #serial_qkey
  bit @r4+, -2(r4) ; Did number recognize the string ?
  jz -

  decd r4
  clr @r4
  mov.b &UCA0RXBUF, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit?" ; ( -- Flag ) Ready to emit
;------------------------------------------------------------------------------
serial_qemit:
  call &hook_pause
  pushda #0
  bit.b #UCTXIFG, &UCA0IFG
  jz +
  mov #-1, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit" ; ( c -- ) Emit character
;------------------------------------------------------------------------------
serial_emit:
- call #serial_qemit
  bit @r4+, -2(r4) ; Did number recognize the string ?
  jz -

  mov.b @r4, &UCA0TXBUF         ; TX -> RXed character
  drop
  ret

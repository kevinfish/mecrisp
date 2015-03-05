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

; Serial terminal routines for MSP430F5529

;------------------------------------------------------------------------------
; Registers and Constants
;------------------------------------------------------------------------------

WDTCTL equ 015Ch
P3SEL  equ 022Ah
P4SEL  equ 022Bh

;------------------------------------------------------------------------------
; UART

; UCA0_Base equ 05C0h

; UCA0CTL1  equ UCA0_Base + 0
; UCA0CTL0  equ UCA0_Base + 1
; UCA0BR0   equ UCA0_Base + 6
; UCA0BR1   equ UCA0_Base + 7
; UCA0MCTL  equ UCA0_Base + 8
; UCA0STAT  equ UCA0_Base + 10
; UCA0RXBUF equ UCA0_Base + 12
; UCA0TXBUF equ UCA0_Base + 14
; UCA0IFG   equ UCA0_Base + 1Dh

UCA1_Base equ 0600h

UCA1CTL1  equ UCA1_Base + 0
UCA1CTL0  equ UCA1_Base + 1
UCA1BRW   equ UCA1_Base + 6
UCA1MCTL  equ UCA1_Base + 8
UCA1STAT  equ UCA1_Base + 10
UCA1RXBUF equ UCA1_Base + 12
UCA1TXBUF equ UCA1_Base + 14
UCA1IFG   equ UCA1_Base + 1Dh

UCSWRST equ 1
UCSSEL_2 equ 80h

UCOS16 equ 1
UCBRF_0 equ 00h
UCBRF_1 equ 10h
UCBRF_5 equ 50h
UCBRF_8 equ 80h

UCBRS_0 equ 00h
UCBRS_1 equ 02h
UCBRS_2 equ 04h
UCBRS_3 equ 06h
UCBRS_4 equ 08h
UCBRS_5 equ 0Ah
UCBRS_6 equ 0Ch
UCBRS_7 equ 0Eh

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
  bit.b #UCRXIFG, &UCA1IFG
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
  mov.b &UCA1RXBUF, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit?" ; ( -- Flag ) Ready to emit
;------------------------------------------------------------------------------
serial_qemit:
  call &hook_pause
  pushda #0
  bit.b #UCTXIFG, &UCA1IFG
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

  mov.b @r4, &UCA1TXBUF         ; TX -> RXed character
  drop
  ret

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

; Serial terminal routines for F1612

;----------------------------------------------------------------------------
; USART 0

U0CTL           equ     070h
U0TCTL          equ     071h
U0RCTL          equ     072h
U0MCTL          equ     073h
U0BR0           equ     074h
U0BR1           equ     075h
U0RXBUF         equ     076h
U0TXBUF         equ     077h

;----------------------------------------------------------------------------
; USART 1

U1CTL           equ     078h
U1TCTL          equ     079h
U1RCTL          equ     07Ah
U1MCTL          equ     07Bh
U1BR0           equ     07Ch
U1BR1           equ     07Dh
U1RXBUF         equ     07Eh
U1TXBUF         equ     07Fh

; Constants for UxCTL

PENA   equ 128
PEV    equ  64
SPB    equ  32
CHAR   equ  16
LISTEN equ   8
SYNC   equ   4
MM     equ   2
SWRST  equ   1

; Constants for UxTCTL

CKPL   equ 64
SSEL1  equ 32
SSEL0  equ 16
URXSE  equ 8
TXWAKE equ 4
; Unused
TXEPT  equ 1

; For Module Enable Register 1
UTXE0 equ 128
URXE0 equ 64

; For Module Enable Register 2
UTXE1 equ 32
URXE1 equ 16

; For IE1
UTXIE0 equ 128
URXIE0 equ 64

; For IE2
UTXIE1 equ 32
URXIE1 equ 16

; For IFG1
UTXIFG0 equ 128
URXIFG0 equ 64

; For IFG2
UTXIFG1 equ 32
URXIFG1 equ 16

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
  bit.b #URXIFG0, &IFG1
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
  mov.b &U0RXBUF, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit?" ; ( -- Flag ) Ready to emit
;------------------------------------------------------------------------------
serial_qemit:
  call &hook_pause
  pushda #0
  bit.b #UTXIFG0, &IFG1
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

  mov.b @r4, &U0TXBUF           ; TX -> RXed character
  drop
  ret

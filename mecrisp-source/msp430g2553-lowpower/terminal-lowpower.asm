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

; Terminal with sleep mode

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key?" ; ( -- Flag ) Check for key press
;------------------------------------------------------------------------------
serial_qkey:
  pushda #0
  bit.b #UCA0RXIFG, &IFG2
  jz +
  mov #-1, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key" ; ( -- c ) Fetch key
;------------------------------------------------------------------------------
serial_key:
  mov #UCA0RXIFG, r7
  call #terminal_schlafroutine
  decd r4
  clr @r4
  mov.b &UCA0RXBUF, @r4
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit?" ; ( -- Flag ) Ready to emit
;------------------------------------------------------------------------------
serial_qemit:
  pushda #0
  bit.b #UCA0TXIFG, &IFG2
  jz +
  mov #-1, @r4
+ ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit" ; ( c -- ) Emit character
;------------------------------------------------------------------------------
serial_emit:
  mov #UCA0TXIFG, r7
  call #terminal_schlafroutine
  mov.b @r4, &UCA0TXBUF
  drop
  ret

;------------------------------------------------------------------------------
terminal_schlafroutine:
  push sr
  dint
  nop
  bis.b r7, &ie2 ; Enable interrupt source for incoming characters

- bit.b r7, &IFG2 ; Check
  jnz +
    bit #gie, @sp ; if interrupts have been enabled before ?
    jnc -         ; If not, simply poll for a character.

    bis #lpm3|gie, sr ; If yes, switch off CPU and DCO in sleep mode and wait for interrupt.
Schnuffelstelle_Terminal:
    jmp -

+ bic.b r7, &ie2 ; Deactivate interrupt source for incoming characters again.
  nop
  reti

;------------------------------------------------------------------------------
irq_wecken_tx:
irq_wecken_rx:
  cmp #Schnuffelstelle_Terminal, 2(sp)
  jne +
    bic #lpm3+gie, 0(sp)
+ reti

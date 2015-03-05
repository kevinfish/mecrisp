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

; Access to ADC10 - as comfortable as possible !

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "adc-vcc" ; ( Channel -- Value ) Reads analog-digital converter
;------------------------------------------------------------------------------
  push #SREF_0+ADC10SHT_3+ADC10ON  ; Reference Vcc
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "adc-1.5" ; ( Channel -- Value ) Reads analog-digital converter
;------------------------------------------------------------------------------
  push #SREF_1+REFON+ADC10SHT_3+ADC10ON  ; Reference 1.5V
  jmp +

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "analog" ; ( Channel -- Value ) Reads analog-digital converter
;------------------------------------------------------------------------------
  push #SREF_1+REFON+REF2_5V+ADC10SHT_3+ADC10ON  ; Reference 2.5V

+ bic #ENC, &ADC10CTL0 ; Switch off ADC to change its configuration !

  ; The topmost 4 bits choose one of the 16 input channels.
  mov @r4, r7
  and #1111b, r7
  swpb r7
  rla r7
  rla r7
  rla r7
  rla r7

  bis #ADC10SSEL_0+ADC10DIV_3+CONSEQ_0, r7 ; Single shot, select clock: ADC10OSC / 4
  mov r7, &ADC10CTL1 ; Select channel

    ; Select Reference, enable ADC
    ; Select Sample-and-Hold-time, long measurement.

  pop &ADC10CTL0 ; Fetch reference from returnstack
  bis #ENC+ADC10SC, &ADC10CTL0 ; Start sampling/conversion

- bit #ADC10BUSY, &ADC10CTL1   ; ADC10BUSY? Wait for finished sampling
  jnz -

  mov &ADC10MEM, @r4 ; Return conversion result
  ret

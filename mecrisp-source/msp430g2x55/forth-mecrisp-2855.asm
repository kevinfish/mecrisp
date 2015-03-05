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

; Main file for Mecrisp for MSP430G2855.

;------------------------------------------------------------------------------
; Base Definitions
;------------------------------------------------------------------------------
  cpu msp430
  include "../common/mspregister.asm"
  include "../common/registers-classic.asm"
  include "../common/datastack.asm"

;------------------------------------------------------------------------------
; Memory map
;------------------------------------------------------------------------------

RamAnfang   equ 1100h ; Start of RAM
RamEnde     equ 2100h ; End of RAM, 4 kb
FlashAnfang equ 4000h ; Start of Flash, 48 kb, Flash end always is $FFFF.

  org 0D400h          ; Start of Forth kernel. Needs to be on a 512 byte boundary !

;------------------------------------------------------------------------------
; Prepare Dictionary
;------------------------------------------------------------------------------

  include "../common/forth-core.asm"  ; Include everything of Mecrisp

;------------------------------------------------------------------------------
; Include chip specific terminal, analog & interrupt hooks code
;------------------------------------------------------------------------------

  include "../common/terminal.asm"
  include "../common/analog.asm"
  include "../common/flash.asm"
  include "interrupts.asm"

;------------------------------------------------------------------------------
Reset: ; Main entry point. Chip specific initialisations go here.
;------------------------------------------------------------------------------

  mov   #WDTPW+WDTHOLD, &WDTCTL    ; Watchdog off
  include "../common/catchflashpointers.asm" ; Setup stacks and catch dictionary pointers

  ; Now it is time to initialize hardware. (Porting: Change this !)

  ; 8 MHz ! Take care: If you change clock, you have to change Flash clock divider, too !
  ; Current divider 19+1 --> 400kHz @ 8 MHz. Has to be in range 257 kHz - 476 kHz.

  mov.b &CALBC1_8MHZ, &BCSCTL1   ; Set DCO
  mov.b &CALDCO_8MHZ, &DCOCTL    ;   to 8 MHz.

  bis.b #030h, &P3SEL            ; Use P3.4/P3.5 for USCI_A0

  ;------------------------------------------------------------------------------
  ; Init serial communication
  bis.b   #UCSSEL_2,&UCA0CTL1     ; SMCLK
  mov.b   #65,&UCA0BR0            ; 8MHz 9600 baud --> 833 cycles/bit
  mov.b   #3,&UCA0BR1             ; 8MHz 9600 baud
  mov.b   #UCBRS_2,&UCA0MCTL      ; Modulation UCBRSx = 2
  bic.b   #UCSWRST,&UCA0CTL1      ; **Initialize USCI state machine**
  ;------------------------------------------------------------------------------

  clr.b &IE1 ; Clear interrupt flags of oscillator fault, NMR and flash violation.
  mov.w #FWKEY, &FCTL1            ; Lock flash against writing
  mov.w #FWKEY|FSSEL_1|19, &FCTL2 ; MCLK/20 for Flash Timing Generator

  welcome " for MSP430G2855 by Matthias Koch"

  ; Initialisation is complete. Ready to fly ! Prepare to enter Forth:

  include "../common/boot.asm"
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;           Interrupt vectors of G2855
;------------------------------------------------------------------------------

 org 0FFE0h ; Interrupt table with hooks

  .word   irq_vektor_timerc1   ; 01: 0FFE0  Timer C
  .word   irq_vektor_timerc0   ; 02: 0FFE2  Timer C
  .word   irq_vektor_port1     ; 03: 0FFE4  Port 1
  .word   irq_vektor_port2     ; 04: 0FFE6  Port 2
  .word   null_handler         ; 05: 0FFE8  Unused
  .word   irq_vektor_adc       ; 06: 0FFEA  ADC10
  .word   irq_vektor_tx        ; 07: 0FFEC  USCI Transmit
  .word   irq_vektor_rx        ; 08: 0FFEE  USCI Receive
  .word   irq_vektor_timera1   ; 09: 0FFF0  Timer A
  .word   irq_vektor_timera0   ; 10: 0FFF2  Timer A
  .word   irq_vektor_watchdog  ; 11: 0FFF4  Watchdog
  .word   irq_vektor_comp      ; 12: 0FFF6  Comparantor
  .word   irq_vektor_timerb1   ; 13: 0FFF8  Timer B
  .word   irq_vektor_timerb0   ; 14: 0FFFA  Timer B
  .word   null_handler         ; 15: 0FFFC  NMI. Unused.
  .word   Reset                ; 16: 0FFFE  Main entry point

end

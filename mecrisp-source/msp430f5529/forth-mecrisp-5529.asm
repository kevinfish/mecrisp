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

; Main file for Mecrisp for MSP430F5529.

;------------------------------------------------------------------------------
; Base Definitions
;------------------------------------------------------------------------------
  cpu msp430
  include "../common/mspregister.asm"
  include "../common/datastack.asm"

;------------------------------------------------------------------------------
; Memory map
;------------------------------------------------------------------------------

; RamAnfang   equ  1C00h ; Start of RAM, with additional 2 kb USB-RAM

RamAnfang   equ 2400h ; Start of RAM
RamEnde     equ 4400h ; End of RAM, 8 kb
FlashAnfang equ 4400h ; Start of Flash, 47 kb, Flash end always is $FFFF.

  org 0D400h          ; Start of Forth kernel. Needs to be on a 512 byte boundary !

;------------------------------------------------------------------------------
; Prepare Dictionary
;------------------------------------------------------------------------------

  include "../common/forth-core.asm"  ; Include everything of Mecrisp

;------------------------------------------------------------------------------
; Include chip specific terminal & interrupt hooks code
;------------------------------------------------------------------------------

  include "terminal.asm"
  include "flash.asm"
  include "interrupts.asm"

;------------------------------------------------------------------------------
Reset: ; Main entry point. Chip specific initialisations go here.
;------------------------------------------------------------------------------

  mov #5A80h, &WDTCTL ; Watchdog off

  ; mov.b #1, &0204h ; P1DIR  ; Red LED on
  ; mov.b #1, &0202h ; P1OUT

  include "../common/catchflashpointers.asm" ; Setup stacks and catch dictionary pointers

  ; Now it is time to initialize hardware. (Porting: Change this !)

  ; Backchannel UART communication over
  ; P4.4: UCA1TXD
  ; P4.5: UCA1RXD
  ; with 115200 Baud and 8 MHz clock

  ;------------------------------------------------------------------------------
  ; Init Clock

  bis.w #40h, r2
  mov.w #20h, &166h
  mov.w #144h, &168h
  mov.w #1308h, &160h
  mov.w #40h, &162h
  mov.w #0F4h, &164h
  nop
  nop
  nop
  bic.w #40h, r2

- mov.w #0h, &16Eh
  bic.w #2h, &102h
  bit.w #2h, &102h
  jc -

  ; This is just some Forth code which I disassembled and inserted here:

  ; : disable-fll ( -- ) [ $D032 , $0040 , ] inline ; \ Set   SCG0  Opcode bis #40, r2
  ; : enable-fll  ( -- ) [ $C032 , $0040 , ] inline ;  \ Clear SCG0  Opcode bic #40, r2

  ; disable-fll
  ; 2 4 lshift CSCTL3 ! \ Select REFOCLK as FLL reference
  ; 1 8 lshift          \ ACLK = REFOCLK
  ; 4 4 lshift or       \ SMCLK = DCOCLKDIV
  ; 4 or       CSCTL4 ! \ MCLK = DCOCLKDIV
  ;
  ; $1308      CSCTL0 ! \ A good DCO guess for quickly reaching target frequency
  ; 4 4 lshift CSCTL1 ! \ DCO Range around 8 MHz
  ; 244        CSCTL2 ! \ REFOCLK * 244 = 32768 Hz * 244 = 7 995 392 Hz
  ; nop                 \ Wait a little bit
  ; enable-fll
  ;
  ; begin
  ;   0 CSCTL7 !      \ Clear oscillator fault flags
  ;   2 SFRIFG1 bic!    \ Clear oscillator fault flag
  ;   2 SFRIFG1 bit@ not \ No more oscillator faults ?
  ; until

  ;------------------------------------------------------------------------------
  ; Init IO

  mov.b #030h, &P4SEL                 ; Use P4.4/P4.5 for USCI_A1 TXD/RXD

  ;------------------------------------------------------------------------------
  ; Init serial communication

  mov.b #UCSWRST, &UCA1CTL1         ; **Put state machine in reset**
  bis.b #UCSSEL_2, &UCA1CTL1        ; SMCLK

  mov.w #4, &UCA1BRW                ; 8 MHz 115200 Baud
  mov.b #3Bh, &UCA1MCTL             ; Modulation UCBRSx=5, UCBRFx=3, UCOS16

  bic.b #UCSWRST, &UCA1CTL1         ; **Initialize USCI state machine**
  ;------------------------------------------------------------------------------

  ; mov.b #0, &0202h ; P1OUT   ; Red LED off

  welcome " for MSP430F5529 by Matthias Koch"

  ; Initialisation is complete. Ready to fly ! Prepare to enter Forth:

  include "../common/boot.asm"
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;           Interrupt vectors of F5529
;------------------------------------------------------------------------------

 org 0FFD2h ; Interrupt vector table

  .word   irq_vektor_rtc       ; 0FFD2  RTC
  .word   irq_vektor_port2     ; 0FFD4  Port 2
  .word   null_handler         ; 0FFD6  TA2CCR1
  .word   null_handler         ; 0FFD8  TA2CCR0
  .word   null_handler         ; 0FFDA  USCI-B1
  .word   null_handler         ; 0FFDC  USCI-A1
  .word   irq_vektor_port1     ; 0FFDE  Port 1

  .word   null_handler         ; 0FFE0  TA1CCR1
  .word   null_handler         ; 0FFE2  TA1CCR0
  .word   null_handler         ; 0FFE4  DMS
  .word   null_handler         ; 0FFE6  USB
  .word   null_handler         ; 0FFE8  TA0CCR1
  .word   null_handler         ; 0FFEA  TA0CCR0
  .word   irq_vektor_adc       ; 0FFEC  ADC
  .word   null_handler         ; 0FFEE  USCI-B0

  .word   null_handler         ; 0FFF0  USCI-A0
  .word   irq_vektor_watchdog  ; 0FFF2  Watchdog
  .word   null_handler         ; 0FFF4  TB0CCR1
  .word   null_handler         ; 0FFF6  TB0CCR0
  .word   irq_vektor_comp      ; 0FFF8  Comparator
  .word   null_handler         ; 0FFFA  User NMI. Unused.
  .word   null_handler         ; 0FFFC  System NMI. Unused.
  .word   Reset                ; 0FFFE  Main entry point

end

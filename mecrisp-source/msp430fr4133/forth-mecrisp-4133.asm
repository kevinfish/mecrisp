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

; Main file for Mecrisp for MSP430FR4133.

;------------------------------------------------------------------------------
; Base Definitions
;------------------------------------------------------------------------------
  cpu msp430
  include "../common/mspregister.asm"
  include "../common/datastack.asm"

;------------------------------------------------------------------------------
; Memory map
;------------------------------------------------------------------------------

RamAnfang   equ  2000h ; Start of RAM
RamEnde     equ  2800h ; End of RAM, 2 kb
FlashAnfang equ 0C400h ; Start of Flash, 15 kb, Flash end always is $FFFF.

  org 0D400h          ; Start of Forth kernel. Needs to be on a 512 byte boundary !

;------------------------------------------------------------------------------
; Prepare Dictionary
;------------------------------------------------------------------------------

  include "../common/forth-core.asm"  ; Include everything of Mecrisp

;------------------------------------------------------------------------------
; Include chip specific terminal & interrupt hooks code
;------------------------------------------------------------------------------

  include "terminal.asm"
  include "fram.asm"
  include "interrupts.asm"

;------------------------------------------------------------------------------
Reset: ; Main entry point. Chip specific initialisations go here.
;------------------------------------------------------------------------------

  mov #5A80h, &WDTCTL ; Watchdog off

  ; mov.b #1, &0225h ; P4DIR  ; Green LED on
  ; mov.b #1, &0223h ; P4OUT

  include "../common/catchflashpointers.asm" ; Setup stacks and catch dictionary pointers

  ; Now it is time to initialize hardware. (Porting: Change this !)

  ; Backchannel UART communication over
  ; P1.0: UCA0TXD
  ; P1.1: UCA0RXD
  ; with 115200 Baud and 8 MHz clock

  ;------------------------------------------------------------------------------
  ; Init Clock

  bis.w #40h, r2
  mov.w #10h, &186h
  mov.w #150h, &180h
  mov.w #6h, &182h
  mov.w #0F4h, &184h
  nop
  nop
  nop
  bic.w #40h, r2

- bit.w #300h, &18Eh
  jc -

  ; This is just some Forth code which I disassembled and inserted here:

  ; : disable-fll ( -- ) [ $D032 , $0040 , ] inline ; \ Set   SCG0  Opcode bis #40, r2
  ; : enable-fll  ( -- ) [ $C032 , $0040 , ] inline ;  \ Clear SCG0  Opcode bic #40, r2

  ; disable-fll
  ; 1 4 lshift CSCTL3 ! \ Select REFOCLK as FLL reference
  ; $0150      CSCTL0 ! \ A good DCO guess for quickly reaching target frequency
  ; 3 1 lshift CSCTL1 ! \ DCO Range around 8 MHz
  ; 244        CSCTL2 ! \ REFOCLK * 244 = 32768 Hz * 244 = 7 995 392 Hz
  ; nop                 \ Wait a little bit
  ; enable-fll
  ; begin $0300 CSCTL7 bit@ not until \ Wait for FLL to lock

  ;------------------------------------------------------------------------------
  ; Init IO

  bic   #LOCKLPM5, &PM5CTL0         ; Unlock I/O pins
  mov.b #3, &P1SEL0                 ; Configure UART pins

  ;------------------------------------------------------------------------------
  ; Init serial communication

  mov #UCSWRST, &UCA0CTLW0          ; **Put state machine in reset**
  bis #UCSSEL__SMCLK, &UCA0CTLW0    ; SMCLK

  mov #4, &UCA0BRW                  ; 8 MHz 115200 Baud
  mov #05551h, &UCA0MCTLW           ; Modulation UCBRSx=55h, UCBRFx=5, UCOS16

  bic #UCSWRST, &UCA0CTLW0          ; **Initialize USCI state machine**
  ;------------------------------------------------------------------------------

  ; mov.b #0, &0223h ; P4OUT   ; Green LED off

  welcome " for MSP430FR4133 by Matthias Koch"

  ; Initialisation is complete. Ready to fly ! Prepare to enter Forth:

  include "../common/boot.asm"
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;           Interrupt vectors of FR4133
;------------------------------------------------------------------------------

 org 0FF80h ; Protection Signatures

  .word   0FFFFh  ; JTAG-Signature 1
  .word   0FFFFh  ; JTAG-Signature 2
  .word   0FFFFh  ; BSL-Signature 1
  .word   0FFFFh  ; BSL-Signature 2

 org 0FFE0h ; Interrupt table with hooks

  .word   null_handler         ; 01: 0FFE0  Unused
  .word   irq_vektor_lcd       ; 02: 0FFE2  LCD
  .word   irq_vektor_port1     ; 03: 0FFE4  Port 1
  .word   irq_vektor_port2     ; 04: 0FFE6  Port 2
  .word   irq_vektor_adc       ; 05: 0FFE8  ADC10
  .word   irq_vektor_uscia     ; 06: 0FFEA  USCI B0
  .word   irq_vektor_uscib     ; 07: 0FFEC  USCI A0
  .word   irq_vektor_watchdog  ; 08: 0FFEE  Watchdog
  .word   irq_vektor_rtc       ; 09: 0FFF0  RTC Counter
  .word   irq_vektor_timerb1   ; 10: 0FFF2  Timer 1
  .word   irq_vektor_timerb0   ; 11: 0FFF4  Timer 1
  .word   irq_vektor_timera1   ; 12: 0FFF6  Timer 0
  .word   irq_vektor_timera0   ; 13: 0FFF8  Timer 0
  .word   null_handler         ; 14: 0FFFA  User NMI. Unused.
  .word   null_handler         ; 15: 0FFFC  System NMI. Unused.
  .word   Reset                ; 16: 0FFFE  Main entry point

end

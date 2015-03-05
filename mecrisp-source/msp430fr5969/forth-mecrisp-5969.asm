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

; Main file for Mecrisp for MSP430FR5969.

;------------------------------------------------------------------------------
; Base Definitions
;------------------------------------------------------------------------------
  cpu msp430
  include "../common/mspregister.asm"
  include "../common/datastack.asm"

;------------------------------------------------------------------------------
; Memory map
;------------------------------------------------------------------------------

RamAnfang   equ 1C00h ; Start of RAM
RamEnde     equ 2400h ; End of RAM, 2 kb
FlashAnfang equ 4400h ; Start of Flash, 47 kb, Flash end always is $FFFF.

  org 0D400h          ; Start of Forth kernel.

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

  ; bic   #LOCKLPM5, &PM5CTL0  ; Unlock I/O pins
  ; mov.b #64, &0225h ; P4DIR  ; Red LED on
  ; mov.b #64, &0223h ; P4OUT

  ;------------------------------------------------------------------------------
  ; Forth core memory protection

  mov #0A500h, &MPUCTL0 ; Write password to enable access to MPU
;  mov #kernelstartadresse>>4, &MPUSEGB1 ; B1 = Forth core start address ($D400)
  mov #FlashAnfang>>4, &MPUSEGB1 ; B1 = Start of memory
  mov #1000h, &MPUSEGB2 ; B2 = 0x10000 (Segment 3 is upper mem)
  bic #32, &MPUSAM ; Write protect segment 2
  mov #0A501h, &MPUCTL0 ; Enable MPU
  mov.b #0, &MPUCTL0+1 ; Disable MPU access

  include "../common/catchflashpointers.asm" ; Setup stacks and catch dictionary pointers

  ; Now it is time to initialize hardware. (Porting: Change this !)

  ; Backchannel UART communication over
  ; P2.0: UCA0TXD
  ; P2.1: UCA0RXD
  ; with 115200 Baud and 8 MHz +- 3.5 % clock.

  ;------------------------------------------------------------------------------
  ; Init Clocks
                       ; DCO starts with 8 MHz
  mov #0A500h, &CSCTL0 ; Enable access to clock registers
  mov #0, &CSCTL3      ; Set all clock dividers to /1
  mov.b #0, &CSCTL0+1  ; Disable access to clock registers

  ;------------------------------------------------------------------------------
  ; Init IO

  bic   #LOCKLPM5, &PM5CTL0         ; Unlock I/O pins
  mov.b #3, &P2SEL1                 ; Use P2.0/P2.1 pins for Communication
  mov.b #0, &P2SEL0

  ;------------------------------------------------------------------------------
  ; Init serial communication

  ; f       Baud   UCOS16 UCBR UCBRF UCBRS
  ; 8000000 115200 1      4    5     0x55

  mov #UCSWRST, &UCA0CTLW0          ; **Put state machine in reset**
  bis #UCSSEL__SMCLK, &UCA0CTLW0    ; SMCLK

  mov #4, &UCA0BRW                  ; 8 MHz 115200 Baud
  mov #05501h|UCBRF_5, &UCA0MCTLW   ; Modulation UCBRSx=55h, UCBRFx=5, UCOS16

  bic #UCSWRST, &UCA0CTLW0          ; **Initialize USCI state machine**
  ;------------------------------------------------------------------------------

  ; mov.b #0, &0223h ; P4OUT   ; Red LED off

  welcome " for MSP430FR5969 by Matthias Koch"

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
  .word   0FFFFh  ; IP Encapsulation Signature 1
  .word   0FFFFh  ; IP Encapsulation Signature 2
  
 org 0FFCCh ; Interrupt table with hooks

  .word   null_handler         ; FFCC  AES
  .word   irq_vektor_rtc       ; FFCE  RTC_B

  .word   irq_vektor_port4     ; FFD0  Port 4
  .word   irq_vektor_port3     ; FFD2  Port 3
  .word   null_handler         ; FFD4  TA3CCR1
  .word   null_handler         ; FFD6  TA3CCR0
  .word   irq_vektor_port2     ; FFD8  Port 2
  .word   null_handler         ; FFDA  TA2CCR1
  .word   null_handler         ; FFDC  TA2CCR0
  .word   irq_vektor_port1     ; FFDE  Port 1

  .word   null_handler         ; FFE0  TA1CCR1
  .word   null_handler         ; FFE2  TA1CCR0
  .word   null_handler         ; FFE4  DMA
  .word   null_handler         ; FFE6  UCA0IFG
  .word   null_handler         ; FFE8  TA0CCR1
  .word   null_handler         ; FFEA  TA0CCR0
  .word   irq_vektor_adc       ; FFEC  ADC
  .word   null_handler         ; FFEE  UCB0IFG

  .word   null_handler         ; FFF0  UCA0IFG
  .word   irq_vektor_watchdog  ; FFF2  Watchdog
  .word   null_handler         ; FFF4  TB0CCR1
  .word   null_handler         ; FFF6  TB0CCR0
  .word   irq_vektor_comp      ; FFF8  Comparator
  .word   null_handler         ; FFFA  User NMI
  .word   null_handler         ; FFFC  System NMI
  .word   Reset                ; FFFE  Reset. Main entry point

end

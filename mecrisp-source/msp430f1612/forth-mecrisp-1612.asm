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

; Main file for Mecrisp for MSP430F1612.

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
RamEnde     equ 2500h ; End of RAM, 5 kb
FlashAnfang equ 2500h ; Start of Flash, 55 kb, Flash end always is $FFFF.

  org 0D400h          ; Start of Forth kernel. Needs to be on a 512 byte boundary !

;------------------------------------------------------------------------------
; Prepare Dictionary
;------------------------------------------------------------------------------

  include "../common/forth-core.asm"  ; Include everything of Mecrisp

;------------------------------------------------------------------------------
; Include chip specific terminal, analog & interrupt hooks code
;------------------------------------------------------------------------------

  include "usart0terminal.asm"
  include "../common/flash.asm"
  include "interrupts.asm"

;------------------------------------------------------------------------------
Reset: ; Main entry point. Chip specific initialisations go here.
;------------------------------------------------------------------------------

  mov   #WDTPW+WDTHOLD, &WDTCTL    ; Watchdog off

  ; Early hardware initialisations:

  ; Block I2C-Lines
  clr.b &P3OUT
  mov.b #2+4, &P3DIR ; Pull SDA and SCL low to block communication between TUSB3410 and EEprom

  ; Pull Reset for TUSB low
  clr.b &P4OUT
  mov.b #64, &P4DIR

  ; Start 12 MHz crystal on XT2
  bic.b   #XT2OFF, &BCSCTL1        ; XT2on

  ; Select USART0 TXD/RXD
  bis.b   #030h, &P3SEL

  include "../common/catchflashpointers.asm" ; Setup stacks and catch dictionary pointers

  ; Now it is time to initialize hardware. (Porting: Change this !)

  ; Select 12 MHz crystal on XT2 as main clock
  ; bic.b   #XT2OFF, &BCSCTL1        ; XT2on - already activated
- bic.b   #OFIFG, &IFG1            ; Clear OSC fault flag
  mov.w   #0FFh, r15               ; R15 = Delay
- dec.w   r15                      ; Additional delay to ensure start
  jnz     -
  bit.b   #OFIFG, &IFG1            ; OSC fault flag set?
  jnz     --                       ; OSC Fault, clear flag again
  bis.b   #SELM_2+SELS, &BCSCTL2   ; MCLK = SMCLK = XT2


  ; SMCLK output for TUSB3410 on P5.5
  mov.b #32, &P5DIR
  mov.b #32, &P5SEL
  
  ; Release Reset-line for TUSB3410
  clr.b &P4DIR

  ;------------------------------------------------------------------------------
  ; Init serial communication
            bis.b   #UTXE0+URXE0, &ME1       ; Enable USART0 TXD/RXD
            bis.b   #CHAR, &U0CTL            ; 8-bit characters
            mov.b   #SSEL1, &U0TCTL          ; UCLK = SMCLK
            mov.b   #0E2h, &U0BR0            ; 9600 @ 12Mhz
            mov.b   #004h, &U0BR1            ;
            clr.b   &U0MCTL                  ; No modulation
            bic.b   #SWRST, &U0CTL           ; **Initalize USART state machine**
  ;------------------------------------------------------------------------------

  ; 12 MHz ! Take care: If you change clock, you have to change Flash clock divider, too !
  ; Current divider 29+1 --> 400kHz @ 8 MHz. Has to be in range 257 kHz - 476 kHz.

  clr.b &IE1 ; Clear interrupt flags of oscillator fault, NMR and flash violation.
  mov.w #FWKEY, &FCTL1            ; Lock flash against writing
  mov.w #FWKEY|FSSEL_1|29, &FCTL2 ; MCLK/30 for Flash Timing Generator

  welcome " for MSP430F1611 by Matthias Koch"

  ; Initialisation is complete. Ready to fly ! Prepare to enter Forth:

  include "../common/boot.asm"
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;           Interrupt vectors of F1612
;------------------------------------------------------------------------------

 org 0FFE0h ; Interrupt table with hooks

  .word   irq_vektor_dac       ; 01: 0FFE0  DAC, DMA
  .word   irq_vektor_port2     ; 02: 0FFE2  Port 2
  .word   irq_vektor_tx1       ; 03: 0FFE4  USART1 TX
  .word   irq_vektor_rx1       ; 04: 0FFE6  USART1 RX
  .word   irq_vektor_port1     ; 05: 0FFE8  Port 1
  .word   irq_vektor_timera1   ; 06: 0FFEA  Timer A1
  .word   irq_vektor_timera0   ; 07: 0FFEC  Timer A0
  .word   irq_vektor_adc       ; 08: 0FFEE  ADC12
  .word   irq_vektor_tx0       ; 09: 0FFF0  USART0 TX
  .word   irq_vektor_rx0       ; 10: 0FFF2  USART0 RX
  .word   irq_vektor_watchdog  ; 11: 0FFF4  Watchdog
  .word   irq_vektor_comp      ; 12: 0FFF6  Comparantor
  .word   irq_vektor_timerb1   ; 13: 0FFF8  Timer B1
  .word   irq_vektor_timerb0   ; 14: 0FFFA  Timer B0
  .word   null_handler         ; 15: 0FFFC  NMI. Unused.
  .word   Reset                ; 16: 0FFFE  Main entry point

end


; Register definition file for 1xxx and 2xxx chips.

;----------------------------------------------------------------------------
; General Memory Layout
; ----------------------
;
; 0000 - 000f : Special Function Registers
; 0010 - 00ff :  8 bit Peripheral Modules
; 0100 - 01ff : 16 bit Peripheral Modules
; 0200 - .... : RAM Memory
;
; 0c00 - 0fff : 1 kb Bootstrap Loader ROM
;
; .... - ffdf : Flash Memory
; ffe0 - ffff : Interrupt Vector Table
;
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Special Function Register of MSP430x1xx Family, Byte Access

IE1             equ     000h            ; Interrupt Enable
IE2             equ     001h
IFG1            equ     002h            ; Interrupt Flag
IFG2            equ     003h
ME1             equ     004h            ; Modul Enable
ME2             equ     005h

;----------------------------------------------------------------------------
; Digital I/O, Byte Access

P1IN		equ	020h		; Input Register
P1OUT		equ	021h		; Output Register
P1DIR		equ	022h		; Direction Register
P1IFG		equ	023h		; Interrupt Flags
P1IES		equ	024h		; Interrupt Edge select
P1IE		equ	025h		; Interrupt enable
P1SEL		equ	026h		; Function select
P1REN           equ     027h            ; Ziehwiderstand aktivieren
P1SEL2          equ     041h            ; Function select 2

P2IN		equ	028h		; Input Register
P2OUT		equ	029h		; Output Register
P2DIR		equ	02Ah		; Direction Register
P2IFG		equ	02Bh		; Interrupt Flags
P2IES		equ	02Ch		; Interrupt Edge select
P2IE		equ	02Dh		; Interrupt enable
P2SEL		equ	02Eh		; Function select
P2REN           equ     02Fh            ; Resistor enable
P2SEL2          equ     042h            ; Function select 2

P3IN            equ     018h            ; Input Register
P3OUT           equ     019h            ; Output Register
P3DIR           equ     01Ah            ; Direction Register
P3SEL           equ     01Bh            ; Function select
P3REN           equ     010h            ; Ziehwiderstand aktivieren
P3SEL2          equ     043h            ; Function select 2

P4IN            equ     01Ch            ; Input Register
P4OUT           equ     01Dh            ; Output Register
P4DIR           equ     01Eh            ; Direction Register
P4SEL           equ     01Fh            ; Function select
P4REN           equ     011h            ; Ziehwiderstand aktivieren

P5IN            equ     030h
P5OUT           equ     031h
P5DIR           equ     032h
P5SEL           equ     033h

P6IN            equ     034h
P6OUT           equ     035h
P6DIR           equ     036h
P6SEL           equ     037h

;------------------------------------------------------------------------------
; ADC10 - Register
;------------------------------------------------------------------------------

ADC10CTL0      equ  01B0h    ; control register 0
ADC10CTL1      equ  01B2h    ; control register 0
ADC10MEM       equ  01B4h    ; memory

ADC10AE0       equ  004Ah    ; input enable register 0, Byte
ADC10AE1       equ  004Bh    ; input enable register 1, Byte

ADC10DTC0      equ  0048h    ; data transfer control register 0
ADC10DTC1      equ  0049h    ; data transfer control register 1
ADC10SA        equ  01BCh    ; data transfer start address

;------------------------------------------------------------------------------
; ADC10 - Konstanten für den Control Register 0
;------------------------------------------------------------------------------

; Auswahl der Spannungsreferenz, Bit 15-13
                 ; 5432109876543210
SREF_0         equ 0000000000000000b ; VR+ = AVCC and VR- = AVSS
SREF_1         equ 0010000000000000b ; VR+ = VREF+ and VR- = AVSS
SREF_2         equ 0100000000000000b ; VR+ = VEREF+ and VR- = AVSS
SREF_3         equ 0110000000000000b ; VR+ = buffered VEREF+ and VR- = AVSS
SREF_4         equ 1000000000000000b ; VR+ = AVCC and VR- = VREF-/VEREF-
SREF_5         equ 1010000000000000b ; VR+ = VREF+ and VR- = VREF-/VEREF-
SREF_6         equ 1100000000000000b ; VR+ = VEREF+ and VR- = VREF-/VEREF-
SREF_7         equ 1110000000000000b ; VR+ = buffered VEREF+ and VR- = VREF-/VEREF-

; sample-and-hold time, Bits 12-11
                 ; 5432109876543210
ADC10SHT_0     equ 0000000000000000b ; 4 x ADC10CLKs
ADC10SHT_1     equ 0000100000000000b ; 8 x ADC10CLKs
ADC10SHT_2     equ 0001000000000000b ; 16 x ADC10CLKs
ADC10SHT_3     equ 0001100000000000b ; 64 x ADC10CLKs
                 ; 5432109876543210
ADC10SC        equ 0000000000000001b
ENC            equ 0000000000000010b
ADC10IFG       equ 0000000000000100b
ADC10IE        equ 0000000000001000b
ADC10ON        equ 0000000000010000b
REFON          equ 0000000000100000b
REF2_5V        equ 0000000001000000b
MSC            equ 0000000010000000b
REFBURST       equ 0000000100000000b
REFOUT         equ 0000001000000000b
ADC10SR        equ 0000010000000000b


;------------------------------------------------------------------------------
; ADC10 - Konstanten für den Control Register 1
;------------------------------------------------------------------------------

; Eingangskanal, Bits 15-12
                 ; 5432109876543210
INCH_0         equ 0000000000000000b
INCH_1         equ 0001000000000000b
INCH_2         equ 0010000000000000b
INCH_3         equ 0011000000000000b
INCH_4         equ 0100000000000000b
INCH_5         equ 0101000000000000b
INCH_6         equ 0110000000000000b
INCH_7         equ 0111000000000000b
INCH_8         equ 1000000000000000b
INCH_9         equ 1001000000000000b
INCH_10        equ 1010000000000000b
INCH_11        equ 1011000000000000b
INCH_12        equ 1100000000000000b ; Selects Channel 11
INCH_13        equ 1101000000000000b ; Selects Channel 11
INCH_14        equ 1110000000000000b ; Selects Channel 11
INCH_15        equ 1111000000000000b ; Selects Channel 11

; sample-and-hold source select, Bits 11-10
                 ; 5432109876543210
SHS_0          equ 0000000000000000b ; ADC10SC - bit
SHS_1          equ 0000010000000000b ; TA OUT1
SHS_2          equ 0000100000000000b ; TA OUT0
SHS_3          equ 0000110000000000b ; TA OUT2

ADC10DF        equ 0000001000000000b ; Data format
ISSH           equ 0000000100000000b ; invert singnal sample-and-hold

; Taktteiler, Bits 7-5
                 ; 5432109876543210
ADC10DIV_0     equ 0000000000000000b
ADC10DIV_1     equ 0000000000100000b
ADC10DIV_2     equ 0000000001000000b
ADC10DIV_3     equ 0000000001100000b
ADC10DIV_4     equ 0000000010000000b
ADC10DIV_5     equ 0000000010100000b
ADC10DIV_6     equ 0000000011000000b
ADC10DIV_7     equ 0000000011100000b

; clock source select, Bits 4-3
                 ; 5432109876543210
ADC10SSEL_0    equ 0000000000000000b ; ADC10OSC
ADC10SSEL_1    equ 0000000000001000b ; ACLK
ADC10SSEL_2    equ 0000000000010000b ; MCLK
ADC10SSEL_3    equ 0000000000011000b ; SMCLK

; conversion sequenze mode select, Bits 2-1
                 ; 5432109876543210
CONSEQ_0       equ 0000000000000000b ; Single channel single conversion
CONSEQ_1       equ 0000000000000010b ; Sequence of channels
CONSEQ_2       equ 0000000000000100b ; Repeat single channel
CONSEQ_3       equ 0000000000000110b ; Repeat sequence of channels

ADC10BUSY      equ 0000000000000001b

;------------------------------------------------------------------------------
; ADC10 - Konstanten für den Data Transfer Control Register 0
;------------------------------------------------------------------------------
                 ; 5432109876543210
ADC10FETCH     equ 0000000000000001b
ADC10B1        equ 0000000000000010b
ADC10CT        equ 0000000000000100b
ADC10TB        equ 0000000000001000b

;----------------------------------------------------------------------------
; Watchdog Timer

; INTERRUPT CONTROL
; These two bits are defined in the Special Function Registers
WDTIE         equ  01h
WDTIFG        equ  01h

WDTCTL        equ     0120h

WDTIS0        equ  0001h
WDTIS1        equ  0002h
WDTSSEL       equ  0004h
WDTCNTCL      equ  0008h
WDTTMSEL      equ  0010h
WDTNMI        equ  0020h
WDTNMIES      equ  0040h
WDTHOLD       equ  0080h
WDTPW         equ  5A00h

; WDT is clocked by fACLK (assumed 32KHz)

WDT_ADLY_1000 equ  WDTPW + WDTTMSEL + WDTCNTCL + WDTSSEL                    ; 1000ms
WDT_ADLY_250  equ  WDTPW + WDTTMSEL + WDTCNTCL + WDTSSEL + WDTIS0           ; 250ms
WDT_ADLY_16   equ  WDTPW + WDTTMSEL + WDTCNTCL + WDTSSEL + WDTIS1           ; 16ms
WDT_ADLY_1_9  equ  WDTPW + WDTTMSEL + WDTCNTCL + WDTSSEL + WDTIS1 + WDTIS0  ; 1.9ms

;----------------------------------------------------------------------------
; Basic Clock Module
;------------------------------------------------------------------------------
  
; Basic Clock Registers, Byte Access

DCOCTL          equ     056h
BCSCTL1         equ     057h
BCSCTL2         equ     058h
BCSCTL3         equ     053h

;------------------------------------------------------------------------------
; Konstanten für DCOCTL

MOD0          equ      001h   ; Modulation Bit 0
MOD1          equ      002h   ; Modulation Bit 1
MOD2          equ      004h   ; Modulation Bit 2
MOD3          equ      008h   ; Modulation Bit 3
MOD4          equ      010h   ; Modulation Bit 4

DCO0          equ      020h   ; DCO Select Bit 0
DCO1          equ      040h   ; DCO Select Bit 1
DCO2          equ      080h   ; DCO Select Bit 2

;------------------------------------------------------------------------------
; Konstanten für BSCSTL1

XT2OFF  equ 128
XTS     equ  64

; ACLK Teiler
DIVA1 equ 20h
DIVA0 equ 10h

DIVA_0        equ 000h ; 00000000b  ; ACLK Divider 0: /1
DIVA_1        equ 010h ; 00010000b  ; ACLK Divider 1: /2
DIVA_2        equ 020h ; 00100000b  ; ACLK Divider 2: /4
DIVA_3        equ 030h ; 00110000b  ; ACLK Divider 3: /8


RSEL0         equ      001h   ; Resistor Select Bit 0
RSEL1         equ      002h   ; Resistor Select Bit 1
RSEL2         equ      004h   ; Resistor Select Bit 2

;------------------------------------------------------------------------------
; Konstanten für BSCSTL2

SELM1 equ 128
SELM0 equ 64

SELM_0 equ 0        ; DCOCLK
SELM_1 equ 64       ; DCOCLK
SELM_2 equ 128      ; XT2CLK oder LFXT1CLK or VLOCLK, falls kein XT2 vorhanden 
SELM_3 equ 128+64   ; LFXT1CLK or VLOCLK

DIVM1 equ 32
DIVM0 equ 16

DIVM_0 equ 0        ; /1
DIVM_1 equ 16       ; /2
DIVM_2 equ 32       ; /4
DIVM_3 equ 32+16    ; /8

SELS equ 8

; SMCLK - Teiler
DIVS1 equ 4
DIVS0 equ 2

DIVS_0        equ 000b  ; /1
DIVS_1        equ 010b  ; /2
DIVS_2        equ 100b  ; /4
DIVS_3        equ 110b  ; /8

DCOR equ 1

;------------------------------------------------------------------------------
; Konstanten für BSCSTL3

XT2S1  equ 128
XT2S0  equ 64

XT2S_0 equ 0         ; 0.4 - 1 MHZ crystal or resonator
XT2S_1 equ 64        ; 1 - 3 MHz
XT2S_2 equ 128       ; 3 - 16 MHz
XT2S_3 equ 128+64    ; Digital external 0.4 - 16 MHz clock source

LFXT1S1 equ 32
LFXT1S0 equ 16
                   ; XTS=0:                        / XTS=1:
LFXT1S_0 equ 0     ; 32768 Hz Crystal of LFXT1     / 0.4 - 1 MHZ crystal or resonator
LFXT1S_1 equ 16    ; Reserved                      / 1 - 3 MHz
LFXT1S_2 equ 32    ; VLOCLK                        / 3 - 16 MHz
LFXT1S_3 equ 32+16 ; Digital external clock source / 0.4 - 16MHz Digital external clock source

XCAP1 equ 8
XCAP0 equ 4

XCAP_0 equ 0       ; 1 pF
XCAP_1 equ 4       ; 6 pF
XCAP_2 equ 8       ; 10 pF
XCAP_3 equ 8+4     ; 12.5 pF

XT2OF equ 2        ; XT2 oscillator fault
LFXT1OF equ 1      ; XT1 oscillator fault

 ; Für Oszillator-Interrupt:
OFIE  equ 2 ; In IE1
OFIFG equ 2 ; In IFG1

;----------------------------------------------------------------------------
; Kalibrationsbytes für verschiedene Frequenzen des DCO:

CALBC1_1MHZ  equ 010FFh;
CALDCO_1MHz  equ 010FEh;

CALBC1_8MHZ  equ 010FDh;
CALDCO_8MHz  equ 010FCh;

CALBC1_12MHZ equ 010FBh;
CALDCO_12MHz equ 010FAh;

CALBC1_16MHZ equ 010F9h;
CALDCO_16MHz equ 010F8h;

;----------------------------------------------------------------------------
; Timer A

TASSEL2         equ    0400h  ; unused        ; to distinguish from UART SSELx
TASSEL1         equ    0200h  ; Timer A clock source select 0
TASSEL0         equ    0100h  ; Timer A clock source select 1
ID1             equ    0080h  ; Timer A clock input devider 1
ID0             equ    0040h  ; Timer A clock input devider 0
MC1             equ    0020h  ; Timer A mode control 1
MC0             equ    0010h  ; Timer A mode control 0
TACLR           equ    0004h  ; Timer A counter clear
TAIE            equ    0002h  ; Timer A counter interrupt enable
TAIFG           equ    0001h  ; Timer A counter interrupt flag

MC_0            equ    (0<<4)  ; Timer A mode control: 0 - Stop
MC_1            equ    (1<<4)  ; Timer A mode control: 1 - Up to CCR0
MC_2            equ    (2<<4)  ; Timer A mode control: 2 - Continous up
MC_3            equ    (3<<4)  ; Timer A mode control: 3 - Up/Down
ID_0            equ    (0<<6)  ; Timer A input divider: 0 - /1
ID_1            equ    (1<<6)  ; Timer A input divider: 1 - /2
ID_2            equ    (2<<6)  ; Timer A input divider: 2 - /4
ID_3            equ    (3<<6)  ; Timer A input divider: 3 - /8
TASSEL_0        equ    (0<<8)  ; Timer A clock source select: 0 - TACLK
TASSEL_1        equ    (1<<8)  ; Timer A clock source select: 1 - ACLK
TASSEL_2        equ    (2<<8)  ; Timer A clock source select: 2 - SMCLK
TASSEL_3        equ    (3<<8)  ; Timer A clock source select: 3 - INCLK

CM1             equ    8000h  ; Capture mode 1
CM0             equ    4000h  ; Capture mode 0
CCIS1           equ    2000h  ; Capture input select 1
CCIS0           equ    1000h  ; Capture input select 0
SCS             equ    0800h  ; Capture sychronize
SCCI            equ    0400h  ; Latched capture signal (read)
CAP             equ    0100h  ; Capture mode: 1 /Compare mode : 0
OUTMOD2         equ    0080h  ; Output mode 2
OUTMOD1         equ    0040h  ; Output mode 1
OUTMOD0         equ    0020h  ; Output mode 0
CCIE            equ    0010h  ; Capture/compare interrupt enable
CCI             equ    0008h  ; Capture input signal (read)
OUT             equ    0004h  ; PWM Output signal if output mode 0
COV             equ    0002h  ; Capture/compare overflow flag
CCIFG           equ    0001h  ; Capture/compare interrupt flag

OUTMOD_0        equ    (0<<5)  ; PWM output mode: 0 - output only
OUTMOD_1        equ    (1<<5)  ; PWM output mode: 1 - set
OUTMOD_2        equ    (2<<5)  ; PWM output mode: 2 - PWM toggle/reset
OUTMOD_3        equ    (3<<5)  ; PWM output mode: 3 - PWM set/reset
OUTMOD_4        equ    (4<<5)  ; PWM output mode: 4 - toggle
OUTMOD_5        equ    (5<<5)  ; PWM output mode: 5 - Reset
OUTMOD_6        equ    (6<<5)  ; PWM output mode: 6 - PWM toggle/set
OUTMOD_7        equ    (7<<5)  ; PWM output mode: 7 - PWM reset/set
CCIS_0          equ    (0<<12) ; Capture input select: 0 - CCIxA
CCIS_1          equ    (1<<12) ; Capture input select: 1 - CCIxB
CCIS_2          equ    (2<<12) ; Capture input select: 2 - GND
CCIS_3          equ    (3<<12) ; Capture input select: 3 - Vcc
CM_0            equ    (0<<14) ; Capture mode: 0 - disabled
CM_1            equ    (1<<14) ; Capture mode: 1 - pos. edge
CM_2            equ    (2<<14) ; Capture mode: 1 - neg. edge
CM_3            equ    (3<<14) ; Capture mode: 1 - both edges

;----------------------------------------------------------------------------
; Comparator_A Registers, Byte Access

CACTL1		equ	059h		; Comparator A control register 1
CACTL2		equ	05Ah		; Comparator A control register 2
CAPD		equ	05Bh		; Comparator A port disable


;----------------------------------------------------------------------------
; Hardware Multiplier, Word Access

;MPY		equ	0130h		; Multiply unsigned
;MPYS		equ	0132h		; Multiply signed
;MAC		equ	0134h		; MPY+ACC
;MACS		equ	0136h		; MPYS+ACC
;OP2		equ	0138h		; Second Operand
;ResLo		equ	013Ah		; Result low word
;ResHi		equ	013Ch		; Result high word
;SumExt		equ	013Eh		; Sum extend

;----------------------------------------------------------------------------
; Timer_A Registers, Word Access

TAIV            equ     012Eh  ; Timer_A Interrupt Vector, Word Access

TACTL		equ	0160h

CCTL0		equ	0162h
TACCTL0		equ	0162h

CCTL1		equ	0164h
TACCTL1		equ	0164h

CCTL2		equ	0166h
TACCTL2		equ	0166h

CCTL3		equ	0168h
TACCTL3		equ	0168h

CCTL4		equ	016Ah
TACCTL4		equ	016Ah

TAR		equ	0170h

CCR0		equ	0172h
TACCR0		equ	0172h

CCR1		equ	0174h
TACCR1		equ	0174h

CCR2		equ	0176h
TACCR2		equ	0176h

CCR3		equ	0178h
TACCR3		equ	0178h

CCR4		equ	017Ah
TACCR4		equ	017Ah

;----------------------------------------------------------------------------
; Timer_B Registers, Word Access

TBIV            equ     011Eh ; Timer_B Interrupt Vector, Word Access

TBCTL		equ	0180h
TBCCTL0		equ	0182h
TBCCTL1		equ	0184h
TBCCTL2		equ	0186h
TBCCTL3		equ	0188h
TBCCTL4		equ	018Ah
TBCCTL5		equ	018Ch
TBCCTL6		equ	018Eh
TBR		equ	0190h
TBCCR0		equ	0192h
TBCCR1		equ	0194h
TBCCR2		equ	0196h
TBCCR3		equ	0198h
TBCCR4		equ	019Ah
TBCCR5		equ	019Ch
TBCCR6		equ	019Eh

;----------------------------------------------------------------------------
; USCI_A0 Registers, Byte Access

UCA0TXBUF equ 067h
UCA0RXBUF equ 066h
UCA0STAT  equ 065h
UCA0MCTL  equ 064h
UCA0BR1   equ 063h
UCA0BR0   equ 062h
UCA0CTL1  equ 061h
UCA0CTL0  equ 060h

UCA0IRTCTL equ 05Eh ; USCI A0 IrDA Transmit Control
UCA0IRRCTL equ 05Fh ; USCI A0 IrDA Receive  Control

;----------------------------------------------------------------------------
; Konstanten für Register IE1
UCA0RXIFG equ 1
UCA0TXIFG equ 2

;----------------------------------------------------------------------------
; Konstanten für UCA0CTL1:
UCSWRST   equ 1
UCSSEL_0  equ 00000000b
UCSSEL_1  equ 01000000b
UCSSEL_2  equ 10000000b
UCSSEL_3  equ 11000000b

;----------------------------------------------------------------------------
; Konstanten für UCA0MCTL

; UCBRF Bit 7-4 Nur wenn 16-fach-Oversampling für IRDA.

UCBRF_0  equ 000h
UCBRF_1  equ 010h
UCBRF_2  equ 020h
UCBRF_3  equ 030h
UCBRF_4  equ 040h
UCBRF_5  equ 050h
UCBRF_6  equ 060h
UCBRF_7  equ 070h
UCBRF_8  equ 080h
UCBRF_9  equ 090h
UCBRF_10 equ 0A0h
UCBRF_11 equ 0B0h
UCBRF_12 equ 0C0h
UCBRF_13 equ 0D0h
UCBRF_14 equ 0E0h
UCBRF_15 equ 0F0h

; USBRS Bit 1-3

UCBRS_0   equ 0000b
UCBRS_1   equ 0010b
UCBRS_2   equ 0100b
UCBRS_3   equ 0110b
UCBRS_4   equ 1000b
UCBRS_5   equ 1010b
UCBRS_6   equ 1100b
UCBRS_7   equ 1110b

UCOS16 equ 1

;----------------------------------------------------------------------------
; Konstanten für UCA0IRTCTL

UCIRTXPL5 equ 080h ; IRDA Transmit Pulse Length 5
UCIRTXPL4 equ 040h ; IRDA Transmit Pulse Length 4
UCIRTXPL3 equ 020h ; IRDA Transmit Pulse Length 3
UCIRTXPL2 equ 010h ; IRDA Transmit Pulse Length 2
UCIRTXPL1 equ 008h ; IRDA Transmit Pulse Length 1
UCIRTXPL0 equ 004h ; IRDA Transmit Pulse Length 0

UCIRTXCLK equ 002h ; IRDA Transmit Pulse Clock Select */
UCIREN    equ 001h ; IRDA Encoder/Decoder enable */

;----------------------------------------------------------------------------
; Konstanten für UCA0IRRCTL

UCIRRXFL5 equ 080h ; IRDA Receive Filter Length 5
UCIRRXFL4 equ 040h ; IRDA Receive Filter Length 4
UCIRRXFL3 equ 020h ; IRDA Receive Filter Length 3
UCIRRXFL2 equ 010h ; IRDA Receive Filter Length 2
UCIRRXFL1 equ 008h ; IRDA Receive Filter Length 1
UCIRRXFL0 equ 004h ; IRDA Receive Filter Length 0

UCIRRXPL  equ 002h ; IRDA Receive Input Polarity
                   ; 0: IrDA transceiver delivers a high pulse when a light pulse is seen
                   ; 1: IrDA transceiver delivers a low pulse when a light pulse is seen

UCIRRXFE  equ 001h ; IRDA Receive Filter enable
 

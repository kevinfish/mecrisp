                save
                listing off   ; kein Listing über diesen File

;****************************************************************************
;*                                                                          *
;*   AS 1.41 - Datei REGMSP.INC von Alfred Arnold                           *
;*   					 			            *
;*   Sinn : enthält Makro- und Registerdefinitionen für den MSP430          *
;* 									    *
;*   letzte Änderungen : 2002-01-11                                         *
;*                       2010/2011/2012 erweitert von Matthias Koch         *
;*                                                                          *
;****************************************************************************

                ifndef  regmspinc      ; verhindert Mehrfacheinbindung

regmspinc       equ     1

                if      (MOMCPUNAME<>"MSP430")
                 fatal  "Falscher Prozessortyp eingestellt: nur MSP430 erlaubt!"
		endif

                if      MOMPASS=1
                 message "MSP430-Register+Befehlsdefinitionen (C) 1996 Alfred Arnold"
		endif

; Definitions for Instructions, Macros and Ports.

;----------------------------------------------------------------------------
; Arithmetik

adc             macro   op
                addc.attribute #0,op
                endm

dadc            macro   op
                dadd.attribute #0,op
                endm

dec             macro   op
                sub.attribute #1,op
                endm

decd            macro   op
                sub.attribute #2,op
                endm

inc             macro   op
                add.attribute #1,op
                endm

incd            macro   op
                add.attribute #2,op
                endm

sbc             macro   op
                subc.attribute #0,op
                endm

;----------------------------------------------------------------------------
; Logik

inv             macro   op
                xor.attribute #-1,op
                endm

rla             macro   op
                add.attribute op,op
                endm

rlc             macro   op
                addc.attribute op,op
                endm

;----------------------------------------------------------------------------
; Daten bewegen ;-)

clr             macro   op
                mov.attribute #0,op
                endm

clrc            macro
                bic     #1,sr
                endm

clrn            macro
                bic     #4,sr
                endm

clrz            macro
                bic     #2,sr
                endm

pop             macro   op         ; Muss hier noch ein Atribut anbringen ! Kann auch Bytes zurückladen...
                mov.attribute     @sp+,op
                endm

setc            macro
                bis     #1,sr
                endm

setn            macro
                bis     #4,sr
                endm

setz            macro
                bis     #2,sr
                endm

tst             macro   op
                cmp.attribute #0,op
                endm

;----------------------------------------------------------------------------
; Sprungbefehle

br              macro   op
                mov     op,pc
                endm

dint            macro
                bic     #8,sr
                endm

eint            macro
                bis     #8,sr
                endm

nop             macro                  ; mov #0, r3
                .word   04303h         ; den symbolischen Befehl würde AS zurückweisen
                endm

nop2            macro                  ; 1 Word, 2 Takte
                jmp $+2
                endm

nop3            macro
                nop2
                nop
                endm

nop4            macro
                nop2
                nop2
                endm

ret             macro
                mov     @sp+,pc
                endm

jlo		macro	label
		jnc	label
		endm

jhs		macro	label
		jc	label
		endm

jeq		macro	label
		jz	label
		endm

;----------------------------------------------------------------------------
; Flags im Statusregister

C             equ 0001h
Z             equ 0002h
N             equ 0004h
V             equ 0100h
GIE           equ 0008h
CPUOFF        equ 0010h
OSCOFF        equ 0020h
SCG0          equ 0040h
SCG1          equ 0080h

;----------------------------------------------------------------------------
; Low-Power-Mode Bitmuster

LPM0          equ CPUOFF
LPM1          equ SCG0 + CPUOFF
LPM2          equ SCG1 + CPUOFF
LPM3          equ SCG1 + SCG0 + CPUOFF
LPM4          equ SCG1 + SCG0 + OSCOFF + CPUOFF

;----------------------------------------------------------------------------

                endif                   ; von IFDEF...
		restore                 ; wieder erlauben
  listing on

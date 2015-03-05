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

; Forth for MSP430 architecture.

;------------------------------------------------------------------------------
kernelstartadresse equ $ ; Start address of Mecrisp Forth core
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Configuration and sizes of stacks, buffers and internal variables
;------------------------------------------------------------------------------

rampointer set RamAnfang ; Beginning of Ram

ramallot macro Name, Menge         ; To define labels for uninitialised variables and buffers for core usage
Name equ rampointer
rampointer set rampointer + Menge
         endm

  ramallot Dictionarypointer, 2        ; Variable with dictionarypointer
  ramallot FadenEnde, 2                ; Current entry point into dictionary for FIND
  ramallot Datenstacksicherung, 2      ; Copy of stackpointer for simple syntax checking.
  ramallot konstantenfaltungszeiger, 2 ; A Pointer for determine how many folding constants are currently on data stack
  ramallot leavepointer, 2             ; Pointer to generate leave exit points in loops
  ramallot ZweitDictionaryPointer, 2   ; Second dictionarypointer
  ramallot ZweitFadenEnde, 2           ; Second entry into dictionary
  ramallot FlashFlags, 2               ; Variable to collect flags for new definitions in Flash
  ramallot VariablenPointer, 2         ; Pointer for Ram allocation for Flash variables


  ; Length of number output buffer, has to be uneven
Zahlenpufferlaenge equ 35 ; 16 Bits, 1 Sign, 1 Space + 1 Spare = 19 Bytes + 1 Length-Byte
  ramallot Zahlenpuffer, Zahlenpufferlaenge + 1  ; You need at least 35 bytes for fixpoint number usage.

  ; Put data stack in a location with uncritical buffers around so that overflows and underflows wont't crash immediately.
datenstacklaenge equ 64 ; Size of datastack, has to be even
  ramallot datenstackende, datenstacklaenge
datenstackanfang equ datenstackende + datenstacklaenge

MaximaleEingabe equ 122 ; Size of input buffer, has to be even.
  ramallot Eingabepuffer, MaximaleEingabe

returnstacklaenge equ 64 ; Size of returnstack, has to be even
  ramallot returnstackende, returnstacklaenge
returnstackanfang equ returnstackende + returnstacklaenge

nRamDictionaryAnfang equ rampointer
nRamDictionaryEnde   equ RamEnde ; End of Ram

nFlashDictionaryAnfang equ FlashAnfang  ; Begin of Flash memory in chip for user dictionary (Porting: Change this !)
nFlashDictionaryEnde   equ kernelstartadresse ; End of user dictionary + 1.
nBacklinkgrenze equ nFlashDictionaryAnfang    ; Address border to compare with to find out if definition is in Ram or in Flash

;------------------------------------------------------------------------------
; Messages. There macros are defined early for printing and they don't like ( and ) in strings.
;------------------------------------------------------------------------------

write macro Text
  call #dotgaensefuesschen
  .byte STRLEN(Text), Text
  align 2
  endm

writeln macro Text
  call #dotgaensefuesschen
  .byte STRLEN(Text)+1, Text, 10
  align 2
  endm

welcome macro Text
  call #dotgaensefuesschen
  .byte STRLEN(Text)+14, "Mecrisp 2.0.0", Text, 10
  align 2
  endm

;------------------------------------------------------------------------------
; Some notes for hackers
;------------------------------------------------------------------------------

; Early beginnings on 20. Juny 2009.
; Started development on 18. February 2010 and finished main ideas of Mecrisp roughly in August 2011.
; But development goes on...

; 16 Bit Implementation, between subroutine threading and native code generation with constant folding and opcoding.
; Supports Unicode (utf8).

; No register optimisations, TOS in stack.
; Register with exception of R7 and SR are saved before use !
; Watch for interrupts and care to reserve space on stacks BEFORE putting values into.

; Register allocation:

; r0    PC
; r1    SP
; r2    SR
; r3    CG

; r4    Pointer for data stack
; r5    Index for loops
; r6    Limit for loops
; r7    Scratch register which is only saved on interrupt entry.
; r8  free
; r9  free

; r10    Heavy use ! Working registers that are saved every time.
; r11    ''
; r12    ''
; r13    ''
; r14    ''
; r15    ''

; Dictionary-Construction:
;  ---------------------------------
;  1 Byte Flags (immediate, inline and some others),
;  1 Byte Length of name
;  ---------------------------------
;  Name. If it is an uneven count of characters,
;        it is padded with one zero for alignment that is not counted in length byte.
;  ---------------------------------
;  Link. 2 Bytes. Points to flags of next definition.
;  ---------------------------------
;  After that, machine code begins. Everytime available, everytime executable.
;  Code + ret -- or a call/jump that never returns.
;  ---------------------------------
;  Optional: Data field. There is no link into. 
;            If you need it, search for ret opcode.

; Flag meaning: (hex)
;
;   FF  Invisible (Unsichtbar)
;
;   00  Visible (Sichtbar)
;   10  Immediate
;   20  Inline
;   30  Immediate&Inline at once: Immediate, Compile-Only
;   40  Foldable / Opcodable (Faltbar / Opcodierbar)
;   80  Allocates Ram (automatically 0-foldable)
;
;   More close:
;
;     Foldable/Opcodable:
;     40  0-Foldable
;     41  1-Foldable
;     .   ...
;     47  7-Foldable
;
;     "48" is base for opcodable cases:
;     49  Opcodable Calculus&Logic (Opcodierbar Rechenlogik) automatically 2-foldable (often in combination with inline: 69)
;     4A  Opcodable Write Memory   (Opcodierbar Speicherschreiben)
;     4B  Opcodable  Read Memory   (Opcodierbar Speicherlesen)
;     4C  Opcodable Special Case   (Opcodierbar Spezialfall)
;
;
; How many space should be allocated for kernel ? 
; Has to be on a 512-Byte-Boundary ! (Flash page organisation :-)
;
; 0E000h:  8   kb
; 0DE00h:  8.5 kb
; 0DC00h:  9   kb
; 0DA00h:  9.5 kb
; 0D800h: 10   kb
; 0D600h: 10.5 kb
; 0D400h: 11   kb
; 0D200h: 11.5 kb
; 0D000h: 12   kb

;------------------------------------------------------------------------------
; Definitions for Flags in Dictionary
;------------------------------------------------------------------------------

Flag_invisible  equ 0FFh ; Not set = Not written to in flash
Flag_visible    equ  0b
Flag_immediate  equ  10000b
Flag_inline     equ 100000b

Flag_visible_immediate equ Flag_visible|Flag_immediate
Flag_visible_inline    equ Flag_visible|Flag_inline

; Immediate and Inline cannot coexist. Because of that I use this combination for immediate, compile-only.
Flag_immediate_compileonly equ Flag_visible|Flag_immediate|Flag_inline 

Flag_foldable     equ 1000000b ; To check for Foldability
Flag_opcodierbar equ    1000b  ; To check for Opcodability

Flag_foldable_0 equ Flag_foldable|0
Flag_foldable_1 equ Flag_foldable|1
Flag_foldable_2 equ Flag_foldable|2
Flag_foldable_3 equ Flag_foldable|3
Flag_foldable_4 equ Flag_foldable|4
Flag_foldable_5 equ Flag_foldable|5
Flag_foldable_6 equ Flag_foldable|6
Flag_foldable_7 equ Flag_foldable|7

; Of course, some of those cases are not foldable at all. But this way their bitmask is constructed.
Flag_opcodierbar_rechenlogik       equ Flag_foldable|Flag_opcodierbar|1
Flag_opcodierbar_speicherschreiben equ Flag_foldable|Flag_opcodierbar|2
Flag_opcodierbar_speicherlesen     equ Flag_foldable|Flag_opcodierbar|3
Flag_opcodierbar_spezialfall       equ Flag_foldable|Flag_opcodierbar|4

Flag_ramallot  equ 10000000b
Flag_variable  equ Flag_ramallot|1
Flag_2variable equ Flag_ramallot|2

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Beginning of Dictionary !
; Start with header definitions.



; Normal case for standard links, it there is ram dictionary only

; Latest set 0FFFFh ; Pointer to last defined word
; Neu    set 0FFFFh ; Variable for current pointer

; Wortbirne macro Flagzustand, Name
;   align 2
; Neu set $ ; Save current address for link
;   .byte Flagzustand, STRLEN(Name), Name
;   align 2
;   .word Latest
; Latest set Neu
;           endm


CoreVariablenPointer set nRamDictionaryEnde

CoreVariable macro Name ; Use this mechanism to get initialised variables.
CoreVariablenPointer set CoreVariablenPointer - 2
Name equ CoreVariablenPointer
             endm

DoubleCoreVariable macro Name ; Use this mechanism to get initialised variables.
CoreVariablenPointer set CoreVariablenPointer - 4
Name equ CoreVariablenPointer
             endm

; Basically, this macro gives every definition its own label and defines it in the following definition.
; 1. Usage: .word Backlink_1
; 2. Usage: Backlink_1 gets defined and .word Backlink_2 is included
; Follow up. At the end, the last Backlink has to be defined manually.

Backlink_Zaehler set 0
Backlink_Label   set "\{Backlink_Zaehler}"

Wortbirne macro Flagzustand, Name
  align 2

Backlink_{Backlink_Label} equ $ ; Save current address for former Backlink.

Backlink_Zaehler set Backlink_Zaehler+1 ; Select next Label
Backlink_Label   set "\{Backlink_Zaehler}"  ; and assemble it.

  .byte Flagzustand, STRLEN(Name), Name
  align 2
  .word Backlink_{Backlink_Label} ; Include special links here.

          endm

; At the end:
; Backlink_{Backlink_Label} equ nFlashDictionaryAnfang ; Set pointer into changeable dictionary space.

;------------------------------------------------------------------------------
CoreDictionaryAnfang: ; Contains whole dictionary
;------------------------------------------------------------------------------
  Wortbirne Flag_invisible, "--- Mecrisp Core ---"

  include "../common/terminalhooks.asm"
  include "../common/deepinsight.asm"
  include "../common/stackjugglers.asm"
  include "../common/logic.asm"
  include "../common/numberstrings.asm"
  include "../common/fixpoint.asm"
  include "../common/double.asm"
  include "../common/starslash.asm"
  include "../common/strings.asm"
  include "../common/calculations.asm"
  include "../common/memory.asm"
  include "../common/query.asm"
  include "../common/token.asm"
  include "../common/interpreter.asm"
  include "../common/compiler.asm"
  include "../common/controlstructures.asm"
  include "../common/case.asm"
  include "../common/comparisions.asm"
  include "../common/interrupts-common.asm"


\ MSP430 Assembler, Copyright (C) 2012  Matthias Koch
\ This is free software under GNU General Public License v3.
\ Resolves constants, symbols and variable names and
\ gives you a comfortable way to write machine instructions.

This experimental assembler can insert instructions directly into your definitions.
It takes care of the constant generator and all adressing modes.
As a special feature, this is a postfix assembler !

As this is a native code implementation, there is no need for an asm intro.
Take care of saving registers other than SR you use !

It uses the following syntax, with some short examples:

Double Operand:

mov.b r10 r11
mov.w @sp r10
mov.w @r4+ r11
bis.b #34 &$29
bis.b #34 &p2out \ if you defined  "$29 constant P2OUT" before
add.w #3 (r4) 2  \ means "add.w #3, 2(r4)"

Single operand:

push.w (r5) 4
rrc.w r14

Note that there are some emulated shifts, but this assembler
accepts all adressing modes for those and takes care of them.

You can do: rlc.w @r10+ which will assemble to adc.w @r10+, -2(r10)

Zero operand:

setc
reti

Jumps:

  You can give the jump a numerical jump distance:
jmp -6
jlo 14

  Or you can use comfortable labels:

l-: xor.b #4 &P2OUT

l-: bit.b #1 &P2IN
    jnc -

    dec.w r10
    jz +

    jmp --

l+: clr.b &P2OUT

  The jumps accept +, ++, +++ and -, --, ---
  l-: simply notes the current address for further use,
  l+: has to fill in jumps that occured earlier.

  Because the adresses and jump opcodes have to be cached,
  there are 8 forward references maximum.

  You get the idea :-)
  Good luck, bug reports and ideas are welcome.
  For size reasons, use the msp430f2274 if you also want to include the disassembler.

  Matthias Koch, May 2012

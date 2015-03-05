//
//    Mecrimemu - An emulator for the MSP430 CPU
//    Copyright (C) 2011  Matthias Koch
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

unit zahlenzauber;

{ Jonglage mit Bits&Bytes f�r die lieben Menschen, die gerne mal genauer in ihre Bitfolgen schauen... }

interface

const high = true;
       low = false;

      power     : array[0..7]  of byte = (1, 2, 4, 8, 16, 32, 64, 128);
      powerword : array[0..15] of word = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768);
      
function  byte2bin(zahl : byte) : string;
function  word2bin(zahl : word) : string;
function  byte2hex(zahl : byte) : string;
function  word2hex(zahl : word) : string;
(*      
function wordvorzeichen(zahl : word) : boolean;
function word2integer(zahl : word) : integer;
function bytevorzeichen(zahl : byte) : boolean;
function byte2integer(zahl : byte) : integer;      
*)      
implementation

function byte2bin(zahl : byte) : string;
var i : integer;
    h : string = '';
begin
  //h := '';
  for i := 7 downto 0 do
    if (zahl and power[i]) = power[i] then h := h + '1'
                                      else h := h + '0';
  byte2bin := h;
end;

function word2bin(zahl : word) : string;
var i : integer;
    h : string = '';
begin
  //h := '';
  for i := 15 downto 0 do
    if (zahl and powerword[i]) = powerword[i] then h := h + '1'
                                              else h := h + '0';
  word2bin := h;
end;

function byte2hex(zahl : byte) : string;
const
    hexa : array [0..15] of char = '0123456789ABCDEF';
begin
  byte2hex := hexa[zahl shr 4] + hexa[zahl and 15];
end;

function word2hex(zahl : word) : string;
begin
  word2hex := Byte2Hex((zahl and $FF00) shr 8) + Byte2Hex(zahl and $00FF);
end;
(*
{ Umwandlungen, um mit Zweierkomplementen in Words besser umgehen zu können. }

{ True, wenn negativ; False, wenn positiv }
function wordvorzeichen(zahl : word) : boolean;
begin
  wordvorzeichen := (zahl and $8000) = $8000;
end;

function word2integer(zahl : word) : integer; // Wandelt ein Word mit Vorzeichen in ein Integer um.
begin
    if (zahl and $8000) = $8000 then word2integer := -((zahl xor $FFFF) + 1)
                                else word2integer := zahl;
end;

{ True, wenn negativ; False, wenn positiv }
function bytevorzeichen(zahl : byte) : boolean;
begin
  bytevorzeichen := (zahl and $80) = $80;
end;

function byte2integer(zahl : byte) : integer; // Wandelt ein Byte mit Vorzeichen in ein Integer um.
begin
    if (zahl and $80) = $80 then byte2integer := -((zahl xor $FF) + 1)
                            else byte2integer := zahl;
end;
*)

begin
end.
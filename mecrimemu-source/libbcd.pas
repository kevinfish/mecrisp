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

unit libbcd; // Helferlein für die Umwandlung gepackter BCD-Zahlen

interface

function byte2bcd(zahl : byte) : byte;
function bcd2byte(zahl : byte) : byte;
function word2bcd(zahl : word) : word;
function bcd2word(zahl : word) : word;

implementation

function byte2bcd(zahl : byte) : byte;
begin
  byte2bcd := zahl mod 10 or (((zahl div 10) mod 10) shl 4);  
end;

function bcd2byte(zahl : byte) : byte;
begin
  bcd2byte := ((zahl and $F0) shr 4) * 10 + (zahl and $0F);
end;

function word2bcd(zahl : word) : word;
begin
  word2bcd := zahl mod 10 
              or 
              (((zahl div 10)   mod 10) shl 4)
              or
              (((zahl div 100)  mod 10) shl 8)
              or
              (((zahl div 1000) mod 10) shl 12)
              ;
end;

function bcd2word(zahl : word) : word;
begin
  bcd2word := ((zahl and $F000) shr 12) * 1000
              +
              ((zahl and $0F00) shr 8)  * 100
              + 
              ((zahl and $00F0) shr 4)  * 10 
              + 
              (zahl and $000F)
              ;
end;

begin
end.
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

{ Eine ausgelagerte Routine, die Intel-Hex ließt und in den Speicher legt, }

procedure lese_ihex(dateiname : string);
// Dient allein dem Einlesen einer ihex-Datei. Habe diese Routine aus mecrisp...
var datei : file of char;
    summe : byte;
    
  function zeichen : char;
  var c : char;
  begin
    if not eof(datei) then read(datei, c)
                      else begin writeln('Datei unerwartet zu Ende'); halt; end;
    zeichen := c;
  end;

  function lesebyte : byte;
  var nibble_high, nibble_low : char;
      zahl, fehler : byte;
  begin  
    nibble_high := zeichen;
    nibble_low  := zeichen;
 
    val('$' + nibble_high + nibble_low, zahl, fehler);
    if fehler <> 0 then begin writeln('Unerlaubtes Zeichen in der Datei'); halt; end;

    summe := (summe + zahl) and $ff; { Prüfsumme berechnen }
    lesebyte := zahl;
  end;
    
var c : char;
    letzterrecord : boolean;
    datenlaenge   : byte;
    adresse_low   : byte;
    adresse_high  : byte;
    adresse       : word;
    recordtyp     : byte;
    daten         : array[0..255] of byte;
    i             : integer;
    fehler        : boolean = false;

begin
  assign(datei, dateiname);
  reset(datei);
    
  LetzterRecord := false;

  repeat
    c := ' ';
    while (c <> ':') do c := zeichen; { Startmarkierung suchen }
    summe := 0; { Neuer Record, neue Prüfsumme }
    
    datenlaenge  := lesebyte;
    adresse_high := lesebyte;
    adresse_low  := lesebyte;
    recordtyp    := lesebyte;
    adresse := (adresse_high shl 8) or adresse_low;
    //write('Datenlaenge: ', datenlaenge, ' Hi: ', adresse_high, ' Lo: ', adresse_low, ' ');

    { Datenlänge ist ein Byte, kann also maximal 255 groß sein. }
    fillchar(daten, sizeof(daten), $ff);
    for i := 0 to datenlaenge - 1 do daten[i] := lesebyte;

    { Prüfsumme bestimmen }
    lesebyte; { Ließt das Prüfsummenbyte, benötige den Wert aber nicht }
    if summe <> 0 then begin writeln('Prüfsummenfehler !'); fehler := true; end;
        
    if not fehler then    
    case recordtyp of
      00 : begin { Record enthält Daten }

             { Die gesammelte Datenzeile anzeigen }
       //      write('Adresse: ', word2hex(adresse), ' Daten: ');
       //      for i := 0 to datenlaenge - 1 do write(byte2hex(daten[i]), ' ');
       //      writeln;
             
             { Eine kleine Probe, ob das, was gelesen wurde auch gültig ist... 
               Ich würde aber vielleicht praktischerweise mit $FFs auffüllen, wenn etwas nicht so ganz stimmt, und trotzdem brennen.}
             if ((adresse mod 2) = 1) or ((datenlaenge mod 2) = 1) then begin writeln('Es dürfen nur gerade Adresse und Datenlaengen benutzt werden !'); fehler := true; end;

             { Gesammelte Daten in den Speicher schreiben. }
             for i := 0 to datenlaenge - 1 do
             begin
               speicher[adresse + i].inhalt := daten[i];
               speicher[adresse + i].belegt := true;
             end;
             
           end;
      01 : begin { Letzter Record }
             LetzterRecord := true;
           end;  
      else begin writeln('Nichtunterstützter Recordtyp !'); halt; end;
    end;
  until LetzterRecord or fehler;
  
  close(datei);
end;

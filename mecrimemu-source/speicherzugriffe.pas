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

//------------------------------------------------------------------------------  
// Routinen für den Speicherzugriff.

// Achtung: Die Wordports 110, 112, 114 wurden hier umdefiniert ! Sie werden NICHT an die Hardware weitergeleitet !
// Für Emit, Key, ?Key. Achte auf Kollisionen.

procedure speicherloeschen;
var i : word;
begin
  // Speicher löschen !
  for i := 0 to $FFFF do
  begin
    speicher[i].inhalt := $FF;
    speicher[i].belegt := false;
    
    speicher[i].opcode  := false;
    speicher[i].operand := false;
    speicher[i].fetched := 0;
    
    speicher[i].lesezugriff := false;
    speicher[i].schreibzugriff := false;
    speicher[i].gelesen := 0;
    speicher[i].geschrieben := 0;
    speicher[i].calleinsprung := false;
  end;
end;

// Variablen für das Sendeword
//var sendeword_flag : boolean = false;
//    sendeword_sendepuffer, sendeword_empfangspuffer : word;

function wordlesen_basis(adresse : word) : word; // Setzt keine Flags im Speicher !
begin
  if (adresse mod 2) = 1 then begin writeln(word2hex(register[pc]), ': Words dürfen nur an geraden Adressen gelesen werden ! ', word2hex(adresse)); halt; end;
  
  if not (
           ((sfr_anfang       <= adresse) and (adresse <= sfr_ende))       or
           ((wordports_anfang <= adresse) and (adresse <= wordports_ende)) or
           ((ram_anfang       <= adresse) and (adresse <= ram_ende))       or
           ((flash_anfang     <= adresse) and (adresse <= flash_ende))     
         ) then begin writeln(word2hex(register[pc]), ': Wildes Wordlesen bei ', word2hex(adresse), 'h ! '); halt; end;
         
  case adresse of // Spezielle Adressen erkennen
//    $100: writeln('$100 ist nur zum Lesen');
//    $102: begin
//            wordlesen_basis := sendeword_sendepuffer; // $102;
//          end;
    $112: begin
            wordlesen_basis := emulator_key;
          end;
    $114: begin
            wordlesen_basis := emulator_qkey;
          end;          
  else
    wordlesen_basis := speicher[adresse].inhalt or (speicher[adresse + 1].inhalt shl 8);
                   {$ifdef hardware}      if (wordports_anfang <= adresse) and (adresse <= wordports_ende) then wordlesen_basis := wordportlesen(adresse); {$endif}
  end;
  inc(zyklen);   
  trapadressprobe(adresse);
end;

function wordlesen(adresse : word) : word;  // Setzt die Flags für einen normalen Speicherzugriff.
begin
  wordlesen := wordlesen_basis(adresse);
  speicher[adresse  ].lesezugriff := true;
  speicher[adresse+1].lesezugriff := true;
  inc(speicher[adresse].gelesen);
  inc(speicher[adresse+1].gelesen);
end;

function bytelesen(adresse : word) : byte;
begin

  if not (
           ((byteports_anfang <= adresse) and (adresse <= byteports_ende)) or
           ((ram_anfang       <= adresse) and (adresse <= ram_ende))       or
           ((flash_anfang     <= adresse) and (adresse <= flash_ende))     
         ) then begin writeln(word2hex(register[pc]), ': Wildes Bytelesen bei ', word2hex(adresse), 'h ! '); halt; end;
  
  speicher[adresse].lesezugriff := true;
  inc(speicher[adresse].gelesen);
  bytelesen := speicher[adresse].inhalt;
  inc(zyklen);

  // Für die Emulation der seriellen Schnittstelle
  if adresse = $03 then bytelesen := (emulator_qkey and 1) or 2;
  if adresse = $66 then bytelesen := emulator_key;
  
                     {$ifdef hardware}      if (byteports_anfang <= adresse) and (adresse <= byteports_ende) then bytelesen := byteportlesen(adresse); {$endif}

  trapadressprobe(adresse);
end;

procedure byteschreiben(adresse : word; daten : byte);
begin

  if not (
           ((byteports_anfang <= adresse) and (adresse <= byteports_ende)) or
           ((ram_anfang       <= adresse) and (adresse <= ram_ende))       
         ) then begin writeln(word2hex(register[pc]), ': Wildes Byteschreiben bei ', word2hex(adresse), 'h mit ', byte2hex(daten), 'h !'); halt; end;

  speicher[adresse].inhalt := daten;
  speicher[adresse].schreibzugriff := true;
  inc(speicher[adresse].geschrieben);
  inc(zyklen);
  
  // Für die Emulation der seriellen Schnittstelle
  if adresse = $67 then emulator_emit(daten);
  
                         {$ifdef hardware}          if (byteports_anfang <= adresse) and (adresse <= byteports_ende) then byteportschreiben(adresse, daten); {$endif}
  trapadressprobe(adresse);
end;

procedure wordschreiben(adresse : word; daten : word);
begin
  if (adresse mod 2) = 1 then begin writeln(word2hex(register[pc]), ': Words dürfen nur an geraden Adressen geschrieben werden ! ', word2hex(adresse)); halt; end;
  
  if not (
           ((wordports_anfang <= adresse) and (adresse <= wordports_ende)) or
           ((ram_anfang       <= adresse) and (adresse <= ram_ende))       
         ) then begin writeln(word2hex(register[pc]), ': Wildes Wordschreiben bei ', word2hex(adresse), 'h mit ', word2hex(daten), 'h !'); halt; end;
  
  case adresse of // Spezielle Adressen erkennen
//    $100: begin
//            sendeword_flag := true; //writeln(word2hex(daten));//, ' ', chr(daten and $FF));
//            sendeword_empfangspuffer := daten;
//          end;  
//    $102: writeln('$102 ist nur zum Schreiben');
    $110: begin
            emulator_emit(daten);
          end;  
  else
    if (adresse = $0120) and ((daten and $FF00) <> $5A00) then
    begin
      emulationsende_freiwillig;      
    end;
    
    speicher[adresse].inhalt     := daten and $FF;
    speicher[adresse + 1].inhalt := (daten and $FF00) shr 8;

                       {$ifdef hardware}          if (wordports_anfang <= adresse) and (adresse <= wordports_ende) then wordportschreiben(adresse, daten); {$endif}   
  end;
  inc(zyklen);
  speicher[adresse  ].schreibzugriff := true;
  speicher[adresse+1].schreibzugriff := true;
  inc(speicher[adresse].geschrieben);
  inc(speicher[adresse+1].geschrieben);

  trapadressprobe(adresse);
end;
 

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


{ Eine Routine, die den ganzen Speicherinhalt anzeigt, }

{
procedure speicherschreiben;
var adresse, letzte_adresse : word;
    letztes_label : word;
    label_gesetzt : boolean;
    
begin
  letzte_adresse := 0;
  letztes_label := 0;
  label_gesetzt := false;
  
  for adresse := 0 to $FFFF do
  begin
    if speicher[adresse].belegt then 
    begin
  
      if (adresse <> (letzte_adresse + 1)) or 
         ((adresse - letztes_label) > 15) or
         not label_gesetzt then
         begin
           label_gesetzt := true;
           letztes_label := adresse;
           writeln;
           write('Adresse: ', word2hex(adresse), ' Daten: ');
           letztes_label := adresse;
         end;
      write(byte2hex(speicher[adresse].inhalt), ' ');
      letzte_adresse := adresse;
      //writeln(word2hex(adresse), ' ', byte2hex(speicher[adresse].inhalt));
    end;  
  end;
  writeln;  
end;
}

procedure speicherkarte(anfangsadresse, endadresse : word);
var adresse, letzte_adresse : word;
    letztes_label : word;
    label_gesetzt : boolean;
    einrueck : word;
        
    //i : byte;
begin
  writeln;
  writeln('Speicherkarte:');
  textcolor(0);       write('Unbenutzt  ');
  textcolor(red);     write('Opcode  ');
  textcolor(green);   write('Operand  ');
  textcolor(cyan);    write('Speicherzugriff ');
  textcolor(blue);    write('Übergeschrieben ');
  textcolor(0);
  writeln;

  letzte_adresse := anfangsadresse;
  letztes_label := anfangsadresse;
  label_gesetzt := false;
  
  for adresse := anfangsadresse to endadresse do
  begin
    if speicher[adresse].belegt or speicher[adresse].lesezugriff or speicher[adresse].schreibzugriff then 
    begin
  
      if (adresse <> (letzte_adresse + 1)) or 
         ((adresse - letztes_label) > 15) or
         not label_gesetzt then
         begin
           label_gesetzt := true;
           letztes_label := adresse and $FFF0;
           writeln;
           write('Adresse: ', word2hex(adresse and $FFF0), ' Daten: ');
           if (adresse and $F) <> 0 then 
           begin // Einrücken, falls es nicht direkt vorne beginnt.
             for einrueck := 1 to 3*(adresse and $F) do write(' ');
           end;
         end;
      // Farbe des Textes setzen !
//      if speicher[adresse].belegt then textbackground(blue)
//                                  else textbackground(0);
      
      if speicher[adresse].opcode 
        then textcolor(red)
        else if speicher[adresse].operand
               then textcolor(green{magenta})
               else if (speicher[adresse].lesezugriff or speicher[adresse].schreibzugriff)
                    then //textcolor(cyan)
                         begin
                           if speicher[adresse].geschrieben <= 1 then textcolor(cyan)
                                                                 else textcolor(blue);
                         end
                    else textcolor(black);
                    
      
      { Überschriebene Befehle und Operanden besonders hervorheben ! }
      if (speicher[adresse].opcode or speicher[adresse].operand) and       
         (speicher[adresse].geschrieben > 1) then textbackground(brown);
         
      //write('(');
      //if speicher[adresse].lesezugriff    then write('l') else write(' ');
      //if speicher[adresse].schreibzugriff then write('s') else write(' ');
      //if speicher[adresse].opcode         then write('b') else write(' ');
      //if speicher[adresse].operand        then write('o') else write(' ');
      //if speicher[adresse].calleinsprung  then write('c') else write(' ');
      //write(')');
      
      write(byte2hex(speicher[adresse].inhalt), ' ');
      
      textbackground(0);
      textcolor(0);
      
      letzte_adresse := adresse;
      //writeln(word2hex(adresse), ' ', byte2hex(speicher[adresse].inhalt));
    end;  
  end;
  
  (*
  writeln;
  writeln('Regenbogen');
  textbackground(blue);
  for i := 0 to 15 do 
  begin
    textcolor(i);
    writeln(byte2hex(i));
  end;
  *)
  
  // Standartwerte zurücksetzen !
  textbackground(0);
  textcolor(0);
  writeln;
end;

procedure listing;
// Schreibt die gesammelten, disassemblierten Befehle auf !
var adresse : word;
    disasmadresse : word;
begin
  writeln;
  writeln('Listing:');
  for adresse := 0 to $FFFF do
    if speicher[adresse].opcode and ((adresse mod 2) = 0) then
    begin
      disasmadresse := adresse;
      if speicher[adresse].calleinsprung then {begin writeln; }write('--> '){; end} else write('    ');
      writeln('[ ', speicher[adresse].fetched:8, ' ] $', word2hex(adresse), ' ', prozessor_disassembler(disasmadresse) {speicher[adresse].befehl});
    end;
end;

procedure bereichslisting(anfangsadresse, endadresse : word);
// Schreibt die gesammelten, disassemblierten Befehle auf !
var adresse : word;
    disasmadresse : word;
begin
  writeln;
  writeln('Listing:');
  for adresse := anfangsadresse to endadresse do
    if speicher[adresse].opcode and ((adresse mod 2) = 0) then
    begin
      disasmadresse := adresse;
      if speicher[adresse].calleinsprung then {begin writeln; }write('--> '){; end} else write('    ');
      writeln('[ ', speicher[adresse].fetched:8, ' ] $', word2hex(adresse), ' ', prozessor_disassembler(disasmadresse) {speicher[adresse].befehl});
    end;
end;
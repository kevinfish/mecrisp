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
// Einzelschritt-Oberfläche mit Ein- und Ausblicken

function geheimwordlesen(adresse : word) : word; // Unbemerkter Speicherzugriff ! Wird nur in der "bunten Emulation" benötigt. Keine Hardwareabfrage.
begin
  geheimwordlesen := speicher[adresse].inhalt or (speicher[adresse + 1].inhalt shl 8);
end;

procedure registereinblick(reg : tregister);
var i : integer;
begin
  for i := 0 to 15 do write(i:4, ' '); writeln;
  for i := 0 to 15 do write(word2hex(reg[i]), ' '); writeln;  
end;

procedure registereinblick_unterschied(alt, neu : tregister);
var i : integer;
begin
  for i := 0 to 15 do write(i:4, ' '); writeln;
  for i := 0 to 15 do 
  begin
    if alt[i] <> neu[i] then textcolor(magenta) else textcolor(0);
    write(word2hex(register[i]), ' ');
  end;
  textcolor(0);
  writeln;
end;

{
procedure flageinblick;
begin
  if lese_c then write('C') else write(' ');
  if lese_z then write('Z') else write(' ');
  if lese_n then write('N') else write(' ');
  if lese_v then write('V') else write(' ');
end;
}
procedure registerflageinblick(reg : tregister);
begin
  if (reg[sr] and flag_c) = flag_c then write('C') else write(' ');
  if (reg[sr] and flag_z) = flag_z then write('Z') else write(' ');
  if (reg[sr] and flag_n) = flag_n then write('N') else write(' ');
  if (reg[sr] and flag_v) = flag_v then write('V') else write(' ');
end;

procedure emulation_bunt;
var    
    k : integer;
    adresse : word;
    alteregister : tregister;
    
    disassemblierstelle : word;
    // zuletztausgefuehrterbefehl : string = '';
    breakpoint : word;
    ende : boolean = false;
    
begin
  
  //prozessfenster;
  //readln;
  
    //register[pc] := $F800; 
    alteregister := register;  
  repeat
  
  //for i := 1 to 100 do
  //begin
  {
    if debug then
    begin
    writeln('-------------');
    writeln('PC: ', word2hex(register[pc]));
    writeln('-------------');
    end
    else write('Adresse: ', word2hex(register[pc]), 'h : ');
    }
    (*
    gotoxy(1,1);
    writeln('-------------------------------------------------------------------------------');
    registereinblick;
    writeln('-------------------------------------------------------------------------------');
    write('Adresse: ', word2hex(register[pc]), 'h r4: ', word2hex(register[4]), 'h : ');
    clreol;
    writeln(prozessor_schritt);
    writeln('-------------------------------------------------------------------------------');
    registereinblick;
    writeln('-------------------------------------------------------------------------------');
    *)
    
    
    // Zeige den momentanen Stand des Programms an und disassembliere drumherum.
    
    clrscr;
    write('Bisherige Registerbelegung: Flags: '); {flageinblick;} registerflageinblick(alteregister); writeln;
    writeln('-------------------------------------------------------------------------------');
    registereinblick(alteregister);
    writeln('-------------------------------------------------------------------------------');
    
   // writeln('Zuletzt ausgeführter Befehl: ');
   // write(word2hex(alteregister[pc]), ' : ');
    //writeln(zuletztausgefuehrterbefehl);
    writeln;
    write(' Aktuelle Registerbelegung: Flags: '); {flageinblick;} registerflageinblick(register); writeln;
    
    writeln('-------------------------------------------------------------------------------');
    registereinblick_unterschied(alteregister, register);
    writeln('-------------------------------------------------------------------------------');
    //write('Adresse: ', word2hex(register[pc]), 'h r4: ', word2hex(register[4]), 'h : ');
    
    writeln;
    //writeln('Nächster auszuführender Befehl mit -->:');
    writeln('  Adresse: Inhalt: Ausgeführter Befehl:                   Disassembler:');
       
    disassemblierstelle := register[pc];
    
    for k := -10 to 10 do
    begin
      if k = 0 then write('--> ')
               else write('    ');
               
      adresse := register[pc] + k * 2;
      if speicher[adresse].opcode 
        then textcolor(red)
        else if speicher[adresse].operand
               then textcolor(green{magenta})
               else if (speicher[adresse].lesezugriff or speicher[adresse].schreibzugriff)
                    then textcolor(cyan)
                    else textcolor(black);
      
      write(word2hex(adresse), ' : ',
            byte2hex((speicher[adresse+1].inhalt)), byte2hex((speicher[adresse].inhalt)),
            'h : '
            );
      textcolor(0);
            
      if speicher[adresse].opcode then write(prozessor_disassembler(adresse));
      
      if adresse = disassemblierstelle then
      begin
        if wherex < 60 then gotoxy(60, wherey);
        if k = 0 then textcolor(red) else textcolor(8);
        write(prozessor_disassembler_schritt(disassemblierstelle));
        textcolor(0);        
      end;

      writeln;      
    end; // for k
    
    // Ab hier: Entscheide, was als nächstes getan werden soll.

    writeln;
    repeat until keypressed;

    alteregister := register;
    
    case readkey of 
      'c' : begin
              // Laufe solange, bis der Befehl überwunden ist. Bei call: bis zum Rücksprung.
              // Das Problem ist, wenn darauf Daten folgen.
              // Dann wird der Breakpoint nie erreicht.
              writeln('Setze Breakpoint nach aktuellem Befehl und laufe los...');
              breakpoint := register[pc];
              prozessor_disassembler_schritt(breakpoint); // Länge des Befehls überlesen.
              repeat
                //alteregister := register;
                prozessor_schritt;
            //    zuletztausgefuehrterbefehl := prozessor_schritt;
              until (register[pc] = breakpoint) or keypressed;
            end;
            
      'r' : begin
              // Laufe solange, bis der Befehl überwunden ist. Bei call: bis zum Rücksprung.
              // Das Problem ist, wenn darauf Daten folgen.
              // Dann wird der Breakpoint nie erreicht.
              writeln('Laufe bis zum nächsten ret oder reti...');
              breakpoint := register[pc];
              prozessor_disassembler_schritt(breakpoint); // Länge des Befehls überlesen.
              //alteregister := register;
              repeat
                
              //  zuletztausgefuehrterbefehl := prozessor_schritt;
                prozessor_schritt;
              until (geheimwordlesen(register[pc]) = $4130 {ret} ) or (geheimwordlesen(register[pc]) = $1300 {reti} ) or keypressed;
              //alteregister := register;
              //zuletztausgefuehrterbefehl := prozessor_schritt;
            end;
                        
      'l' : begin
              // Laufe solange, bis ein Knopf gedrückt wird.
              writeln('Laufe los...');
              repeat
                //alteregister := register;
                prozessor_schritt;
              until keypressed;
              
              //zuletztausgefuehrterbefehl := prozessor_schritt;              
            end;      
              {    
      'k' : begin
              // Laufe solange, bis ein Knopf gedrückt wird.
              writeln('Laufe los und Kommuniziere...');
              emulatorkommunikation;
              alteregister := register;
              //zuletztausgefuehrterbefehl := prozessor_schritt;              
            end;                    
            }
            
      #27 : ende := true;
    else    
      //alteregister := register;
     // zuletztausgefuehrterbefehl := prozessor_schritt;
      prozessor_schritt;
    end;
    
  until ende;
  
end;
 

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
// Disassembliert an der gegeben Adresse - verändert aber sonst nichts.
// Hiermit kann ich auch ohne weiteres mitten ins Blaue lesen...


function prozessor_disassembler_schritt(var adresse : word) : string;
//------------------------------------------------------------------------------
var disassembler : string;
    befehlscode : word;
    
  function fetch : word; // Holt das nächste Word ab PC
  begin
    fetch := speicher[adresse].inhalt or (speicher[adresse + 1].inhalt shl 8);//wordlesen(adresse);
    adresse := adresse + 2;
  end;  

var bytebefehl : boolean;
        
  //------------------------------------------------------------------------------
  procedure operand_dekodieren(registernummer : byte); // Dekodiert den Quelloperand für den Disassembler
  //------------------------------------------------------------------------------
  begin         
    case befehlscode and $0030 of
      $0000: case registernummer of // Register Direct
               cg: begin disassembler := disassembler + '#0'; end;
             else               
               disassembler := disassembler + 'r' + inttostr(registernummer);
             end; 
              
      $0010: case registernummer of // Indexed
               sr: begin disassembler := disassembler + '&' + word2hex(fetch) + 'h'; end;
               cg: begin disassembler := disassembler + '#1'; end;
             else // Indexed
               disassembler := disassembler + word2hex(fetch) + 'h(r' + inttostr(registernummer) + ')';
             end;

      $0020: case registernummer of // Indirect
               sr: begin disassembler := disassembler + '#4'; end;
               cg: begin disassembler := disassembler + '#2'; end;
             else  // Register Indirect
               disassembler := disassembler + '@r' + inttostr(registernummer);
             end;
             
      $0030: case registernummer of // Indirect Autoincrement
               sr: begin disassembler := disassembler + '#8';     end;
               cg: begin if bytebefehl then disassembler := disassembler + '#255'
                                       else disassembler := disassembler + '#65535'; end;
             else  // Indirect Autoincrement
               if registernummer = pc then disassembler := disassembler + '#' + word2hex(fetch) + 'h'
                                      else disassembler := disassembler + '@r' + inttostr(registernummer) + '+';
             end;                      
    end; // case befehlscode and $0030
  end;        
    
var zielregister : byte;
    zieltyp      : boolean;
    
    sprungoffset : word;
    sprungoffset_lesbar : integer;
    sprungziel : word;
    
begin
  disassembler := '';
  befehlscode := fetch;
  
  bytebefehl := (befehlscode and $0040) = $0040;

  //if (befehlscode and $F000) = $0000 then
  //  disassembler := 'Unbelegter Befehl' + disassembler; // Wird bei Zwei-Operanden-Befehlen mit Abgefangen.
  
  if ((befehlscode and $F000) = $1000) and ((befehlscode and $FC00) <> $1000) then
    disassembler := 'Unbelegter Befehl' + disassembler; 

  if (befehlscode and $FC00) = $1000 then
  begin
    operand_dekodieren(befehlscode and $000F);
    
    if bytebefehl then disassembler := '.b ' + disassembler
                  else disassembler := '.w ' + disassembler;
    
    case (befehlscode and $0380) of
      $0000: disassembler := 'rrc' + disassembler; 
      $0080: disassembler := 'swpb' + disassembler; 
      $0100: disassembler := 'rra' + disassembler; 
      $0180: disassembler := 'sxt' + disassembler; 
      $0200: disassembler := 'push' + disassembler; 
      $0280: disassembler := 'call' + disassembler; 
      $0300: disassembler := 'reti' + disassembler; 
      $0380: disassembler := 'Unbelegter Befehl' + disassembler;
    else
      disassembler := 'Unbelegter Befehl' + disassembler;
    end;    
  end; // Single Operand
  
  if (befehlscode and $E000) = $2000 then
  begin
    // Sprungziel berechnen:
    sprungoffset := (befehlscode and $03FF) shl 1; // Sprung ist nur zu geraden Adressen sinnvoll...
    // Dies Sprungziel ist negativ, muss für die Rechnungen das Vorzeichen erweitern !
    if (sprungoffset and $0400) = $0400 then sprungoffset := sprungoffset or $F800;
     
    sprungziel := adresse + sprungoffset;
    
    if (sprungoffset and $8000) = $8000 then sprungoffset_lesbar := -((sprungoffset xor $FFFF) + 1)
                                        else sprungoffset_lesbar := sprungoffset;
    
    disassembler := disassembler + inttostr(sprungoffset_lesbar) + ' ; ' + word2hex(sprungziel) + 'h';
    // Bedingung überprüfen
    case (befehlscode and $1C00) of
      $0000: begin disassembler := 'jnz ' + disassembler; end;
      $0400: begin disassembler := 'jz '  + disassembler; end;
      $0800: begin disassembler := 'jnc ' + disassembler; end;
      $0C00: begin disassembler := 'jc '  + disassembler; end;
      $1000: begin disassembler := 'jn '  + disassembler; end;
      $1400: begin disassembler := 'jge ' + disassembler; end;
      $1800: begin disassembler := 'jl '  + disassembler; end;
      $1C00: begin disassembler := 'jmp ' + disassembler; end;
    end;
    // Sprung durchführen oder auch nicht.
  end; // Conditional Jump
  
  if ((befehlscode and $F000) <> $1000) and ((befehlscode and $E000) <> $2000) then
  begin            
    operand_dekodieren((befehlscode and $0F00) shr 8);//quelloperand_dekodieren;
    disassembler := disassembler + ', ';    
    
    zielregister :=  befehlscode and $000F;
    zieltyp      := (befehlscode and $0080) = $0080;
    
    if zieltyp then
    begin
      // Ziel ist indiziert - also noch einen Operanden beachten      
      if zielregister = sr then disassembler := disassembler + '&' + word2hex(fetch) + 'h'
                           else disassembler := disassembler + word2hex(fetch) + 'h(r' + inttostr(zielregister) + ')';
    end   // Ziel ist ein direkter Register.
    else disassembler := disassembler + 'r' + inttostr(zielregister);
    
    if bytebefehl then disassembler := '.b ' + disassembler
                  else disassembler := '.w ' + disassembler;
                  
    case (befehlscode and $F000) of
      $4000: disassembler := 'mov' + disassembler;
      $5000: disassembler := 'add' + disassembler;
      $6000: disassembler := 'addc' + disassembler;
      $7000: disassembler := 'subc' + disassembler;
      $8000: disassembler := 'sub' + disassembler;
      $9000: disassembler := 'cmp' + disassembler;    
      $A000: disassembler := 'dadd' + disassembler;
      $B000: disassembler := 'bit' + disassembler;
      $C000: disassembler := 'bic' + disassembler;               
      $D000: disassembler := 'bis' + disassembler;               
      $E000: disassembler := 'xor' + disassembler;
      $F000: disassembler := 'and' + disassembler;                 
    else
      disassembler := 'Unbekannter Befehl' + disassembler;
    end;

  end; // Double Operand
  
  if befehlscode = $12b1 then disassembler := disassembler + ' Echte CPU stürzt ab !';
  
  prozessor_disassembler_schritt := disassembler; //writeln('Disassembler: ', disassembler);
end;

function prozessor_disassembler(adresse : word) : string; 
begin // Benutze dies, wenn ich die Adresse nicht inkrementieren möchte.
  prozessor_disassembler := prozessor_disassembler_schritt(adresse);
end; 

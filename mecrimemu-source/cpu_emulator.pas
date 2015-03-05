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
 
(*
MSP430 instruction set 
15       14      13      12      11      10      9       8       7       6       5       4       3       2       1       0       Instruction

0       0       0       1       0       0       opcode  B/W     As      register        Single-operand arithmetic

0       0       0       1       0       0       0       0       0       B/W     As      register        RRC Rotate right through carry
0       0       0       1       0       0       0       0       1       0       As      register        SWPB Swap bytes
0       0       0       1       0       0       0       1       0       B/W     As      register        RRA Rotate right arithmetic
0       0       0       1       0       0       0       1       1       0       As      register        SXT Sign extend byte to word
0       0       0       1       0       0       1       0       0       B/W     As      register        PUSH Push value onto stack
0       0       0       1       0       0       1       0       1       0       As      register        CALL Subroutine call; push PC and move source to PC
0       0       0       1       0       0       1       1       0       0       0       0       0       0       0       0       RETI Return from interrupt; pop SR then pop PC

0       0       1       condition       10-bit signed offset    Conditional jump; PC = PC + 2×offset

0       0       1       0       0       0       10-bit signed offset    JNE/JNZ Jump if not equal/zero
0       0       1       0       0       1       10-bit signed offset    JEQ/JZ Jump if equal/zero
0       0       1       0       1       0       10-bit signed offset    JNC/JLO Jump if no carry/lower
0       0       1       0       1       1       10-bit signed offset    JC/JHS Jump if carry/higher or same
0       0       1       1       0       0       10-bit signed offset    JN Jump if negative
0       0       1       1       0       1       10-bit signed offset    JGE Jump if greater or equal
0       0       1       1       1       0       10-bit signed offset    JL Jump if less
0       0       1       1       1       1       10-bit signed offset    JMP Jump (unconditionally)

opcode                          source  Ad      B/W     As      destination     Two-operand arithmetic

0       1       0       0       source  Ad      B/W     As      destination     MOV Move source to destination
0       1       0       1       source  Ad      B/W     As      destination     ADD Add source to destination
0       1       1       0       source  Ad      B/W     As      destination     ADDC Add source and carry to destination
0       1       1       1       source  Ad      B/W     As      destination     SUBC Subtract source from destination (with carry)
1       0       0       0       source  Ad      B/W     As      destination     SUB Subtract source from destination
1       0       0       1       source  Ad      B/W     As      destination     CMP Compare (pretend to subtract) source from destination
1       0       1       0       source  Ad      B/W     As      destination     DADD Decimal add source to destination (with carry)
1       0       1       1       source  Ad      B/W     As      destination     BIT Test bits of source AND destination
1       1       0       0       source  Ad      B/W     As      destination     BIC Bit clear (dest &= ~src)
1       1       0       1       source  Ad      B/W     As      destination     BIS Bit set (logical OR)
1       1       1       0       source  Ad      B/W     As      destination     XOR Exclusive or source with destination
1       1       1       1       source  Ad      B/W     As      destination     AND Logical AND source with destination (dest &= src)
*)

(*

Unbelegte Befehlscodes:

| 15 14 13 12 | 11 10  9  8 | 7  6  5  4 | 3  2  1  0 |
|             |             |            |            |
|  0  0  0  0 |  .  .  .  . | .  .  .  . | .  .  .  . | Unbelegt.
|             |             |            |            |
|  0  0  0  1 |  0  0  X  X | X  .  .  . | .  .  .  . | Single Operand.
|             |        1  1 | 1  .  .  . | .  .  .  . |   --> unbelegter Opcode.
|             |             |            |            |
|  0  0  0  1 |  X  X  .  . | .  .  .  . | .  .  .  . | Unbelegt.
|             |             |            |            |
|  0  0  1  X |  X  X  .  . | .  .  .  . | .  .  .  . | Sprünge, alle belegt.
|             |             |            |            |
|  0  1  X  X |  .  .  .  . | .  .  .  . | .  .  .  . | Double Operand, alle belegt
|  1  0  X  X |  .  .  .  . | .  .  .  . | .  .  .  . | Double Operand, alle belegt
|  1  1  X  X |  .  .  .  . | .  .  .  . | .  .  .  . | Double Operand, alle belegt

*)

(* Agenda !

Zykluszählung prüfen. Am 25. Juni 2009.
  Sprünge okay, 
  Zwei-Operandenbefehle hoffentlich richtig, 
  Ein-Operandenbefehle wohl noch nicht. call und push brauchen mehr Zyklen !!
  
  Wie werden die speziell dekodierten Konstanten aus SG und CG gezykelt ?? Gute Frage !
  
*)

// Schnellversion, ohne tickendem Disassembler

//------------------------------------------------------------------------------
// Die Flags. Helferlein, um sie zu lesen und zu setzen.
//------------------------------------------------------------------------------
const  flag_c = 1;   // Carry
       flag_z = 2;   // Zero
       flag_n = 4;   // Negative
       flag_v = 256; // Overflow

function lese_c : boolean; begin lese_c := (register[sr] and flag_c) = flag_c; end;
function lese_z : boolean; begin lese_z := (register[sr] and flag_z) = flag_z; end;
function lese_n : boolean; begin lese_n := (register[sr] and flag_n) = flag_n; end;
function lese_v : boolean; begin lese_v := (register[sr] and flag_v) = flag_v; end;

function carry : word; // Gibt den Übertrag als Zahl zurück
begin
  if lese_c then carry := 1
            else carry := 0;
end;

procedure setze_c(zustand : boolean); 
begin 
  if zustand then register[sr] := register[sr] or flag_c
             else register[sr] := register[sr] and not flag_c;
end;
                                                       
procedure setze_z(zustand : boolean); 
begin 
  if zustand then register[sr] := register[sr] or flag_z
             else register[sr] := register[sr] and not flag_z;
end;

procedure setze_n(zustand : boolean); 
begin 
  if zustand then register[sr] := register[sr] or flag_n
             else register[sr] := register[sr] and not flag_n;
end;

procedure setze_v(zustand : boolean); 
begin 
  if zustand then register[sr] := register[sr] or flag_v
             else register[sr] := register[sr] and not flag_v;
end;

//------------------------------------------------------------------------------
procedure prozessor_schritt;  // Lässt den Prozessor einen Befehl abarbeiten
                                    
//------------------------------------------------------------------------------
var befehlscode : word;
    bytebefehl  : boolean;
    
  //------------------------------------------------------------------------------
  // Helferlein für den Speicherzugriff
  // Dies sind zwei verschiedene, damit ich später leichter Markierungen
  // im Speicher anbringen kann.  
  //------------------------------------------------------------------------------
  function opcode_fetch : word; // Für den Befehlscode - damit ich später Befehlsanfänge markieren kann !
  begin
        speicher[register[pc]    ].opcode := true;
        speicher[register[pc] + 1].opcode := true;
    inc(speicher[register[pc]    ].fetched);
    inc(speicher[register[pc] + 1].fetched);
    
    opcode_fetch := wordlesen_basis(register[pc]);
    register[pc] := register[pc] + 2;
  end;  
  
  function fetch : word; // Holt das nächste Word als Operand ab PC
  begin
        speicher[register[pc]    ].operand := true;
        speicher[register[pc] + 1].operand := true;
    inc(speicher[register[pc]    ].fetched);
    inc(speicher[register[pc] + 1].fetched);
    
    fetch := wordlesen_basis(register[pc]);
    register[pc] := register[pc] + 2;
  end;  
  
  //------------------------------------------------------------------------------
  // Helferlein für 1-Operanden-Befehle  
  //------------------------------------------------------------------------------
  // Variable, die von 1-Operanden-Befehlen benutzt wird.
  var quellstelle : word;
    
  //------------------------------------------------------------------------------
  function quelloperand_dekodieren(registernummer : byte) : word; // Dekodiert den Quelloperand  
  //------------------------------------------------------------------------------
  var operand : word;                                             // Dieser wird IMMER gelesen !
  begin         
    case befehlscode and $0030 of
      $0000: case registernummer of // Register Direct
               cg: begin operand := 0;  end;
             else                             
               if bytebefehl then operand := register[registernummer] and $FF
                             else operand := register[registernummer];
             end; 
              
      $0010: case registernummer of // Indexed
               cg: begin operand := 1;  end;
             else // Indexed
               quellstelle := fetch;
               if registernummer <> sr then // SR enthält beim Indexed-Zugriff 0 - für absolute Adressierung !
                 quellstelle := (quellstelle + register[registernummer]) and $FFFF;
               if bytebefehl then operand := bytelesen(quellstelle)
                             else operand := wordlesen(quellstelle);
             end;

      $0020: case registernummer of // Indirect
               sr: begin operand := 4;  end;
               cg: begin operand := 2;  end;
             else  // Register Indirect
               quellstelle := register[registernummer];
               if bytebefehl then operand := bytelesen(quellstelle)
                             else operand := wordlesen(quellstelle);
             end;
             
      $0030: case registernummer of // Indirect Autoincrement
               sr: begin operand := 8;   end;
               cg: begin  // -1 
                     if bytebefehl then begin operand := 255;   end
                                   else begin operand := 65535; end;
                //    if bytebefehl then writeln('Kurzkonstante -1 im Bytebefehl ist nicht $FF !');
                //    operand := 65535;
                   end;
                   
             else  // Indirect Autoincrement           
               quellstelle := register[registernummer];                               
               if bytebefehl then begin // Byte-Zugriff
                                    operand := bytelesen(register[registernummer]);
                                    if (registernummer = pc) or (registernummer = sp) 
                                      then register[registernummer] := register[registernummer] + 2
                                      else register[registernummer] := register[registernummer] + 1;
                                  end
                             else begin // Word-Zugriff
                                    operand := wordlesen(register[registernummer]);
                                    register[registernummer] := register[registernummer] + 2;
                                  end;
             end;                      
    end; // case befehlscode and $0030
    quelloperand_dekodieren := operand; 
  end;    
  
  //------------------------------------------------------------------------------
  procedure ein_operand_ziel_schreiben(operand : word); // Für Ein-Operanden-Befehle
                                                        // Deren Ergebnisse gesichert werden sollen
  //------------------------------------------------------------------------------
  var registernummer : byte;                            // Dies geht bestimmt noch kürzer !
  begin
    if bytebefehl then operand := operand and $FF;
    registernummer := befehlscode and $000F;    
    case befehlscode and $0030 of
      $0000: case registernummer of // Register Direct
               cg: begin writeln('Immediate-CG 0 darf nicht geschrieben werden !'); halt; end;
             else
               if bytebefehl then operand := operand and $FF;
               register[registernummer] := operand;  
             end; 
              
      $0010: case registernummer of // Indexed
             // Braucht nicht gesondert behandelt zu werden, da die Quellstelle schon
             // beim Holen des Operandens gesetzt worden ist.
             //  sr: begin 
             //        if bytebefehl then byteschreiben(quellstelle, operand)
             //                      else wordschreiben(quellstelle, operand);
             //      end;
               cg: begin writeln('Immediate-CG 1 darf nicht geschrieben werden !'); halt; end;
             else // Indexed
               if bytebefehl then byteschreiben(quellstelle, operand)
                             else wordschreiben(quellstelle, operand);             
             end;

      $0020: case registernummer of
               sr: begin writeln('Immediate-SR 4 darf nicht geschrieben werden !'); halt; end;
               cg: begin writeln('Immediate-CG 2 darf nicht geschrieben werden !'); halt; end;
             else  // Register Indirect
               if bytebefehl then byteschreiben(quellstelle, operand)
                             else wordschreiben(quellstelle, operand); 
             end;
             
      $0030: case registernummer of
               sr: begin writeln('Immediate-SR 8 darf nicht geschrieben werden !');  halt; end;
               cg: begin writeln('Immediate-CG -1 darf nicht geschrieben werden !'); halt; end;
             else  // Indirect Autoincrement      
               if registernummer = pc then writeln('Immediate mit @PC+ wurde geschrieben...');
               if bytebefehl then byteschreiben(quellstelle, operand)
                             else wordschreiben(quellstelle, operand); 
             end;                      
    end; // case befehlscode and $0030
  end;
  
  
  //------------------------------------------------------------------------------
  // Helferlein speziell für Zwei-Operanden-Befehle
  //------------------------------------------------------------------------------
  
  // Variablen, die für Zwei-Operanden-Befehle benutzt werden.
  var zieltyp : boolean;
      zielregister : byte;
      zielstelle : word;
      
      
    (*  
  //------------------------------------------------------------------------------
  function zwei_operanden_ziel_lesen_ineins(lesen : boolean) : word; // Ließt das Zwei-Operanden-Ziel und nimmt den Inhalt auf,
  begin                                                              // wenn dies mit true angefordert wird.
    zielregister :=  befehlscode and $000F;                          // Mache die Unterscheidung zur Taktzählung !
    zieltyp      := (befehlscode and $0080) = $0080;
        
    if zieltyp then // Gibt den Zieltyp an !
    begin // Ziel ist indiziert - also noch einen Operanden beachten
      zielstelle := fetch;
      // SR enthält für die Indizierung 0 - Absolute Indizierung !
      if zielregister <> sr then zielstelle := zielstelle + register[zielregister];
                                
      if not lesen then inc(zyklen)
                   else
        if bytebefehl then zwei_operanden_ziel_lesen_ineins := bytelesen(zielstelle)
                      else zwei_operanden_ziel_lesen_ineins := wordlesen(zielstelle);                                
    end
    else
    begin // Ziel ist ein direkter Register.

      if lesen then 
      begin
        if bytebefehl then zwei_operanden_ziel_lesen_ineins := register[zielregister] and $FF
                      else zwei_operanden_ziel_lesen_ineins := register[zielregister];
      end;                
    end;      
  end;    
  //------------------------------------------------------------------------------
  // Habe dies noch einmal der Einfachheit aufgespalten.
  function  zwei_operanden_ziel_lesen : word; begin zwei_operanden_ziel_lesen := zwei_operanden_ziel_lesen_ineins(true);  end;
  procedure zwei_operanden_ziel;              begin                              zwei_operanden_ziel_lesen_ineins(false); end;
  
  *)
  function  zwei_operanden_ziel_lesen : word;  
  begin                                                              
    zielregister :=  befehlscode and $000F;
    zieltyp      := (befehlscode and $0080) = $0080;
        
    if zieltyp then // Gibt den Zieltyp an !
    begin // Ziel ist indiziert - also noch einen Operanden beachten
      zielstelle := fetch;
      // SR enthält für die Indizierung 0 - Absolute Indizierung !
      if zielregister <> sr then zielstelle := zielstelle + register[zielregister];                                
      if bytebefehl then zwei_operanden_ziel_lesen := bytelesen(zielstelle)
                    else zwei_operanden_ziel_lesen := wordlesen(zielstelle);                                
    end
    else
    begin // Ziel ist ein direkter Register.
      if bytebefehl then zwei_operanden_ziel_lesen := register[zielregister] and $FF
                    else zwei_operanden_ziel_lesen := register[zielregister];
    end;      
  end;    
  
  procedure zwei_operanden_ziel; // Identisch, nur ohne Leseoperation und mit Zykluszählung
  begin
    zielregister :=  befehlscode and $000F;
    zieltyp      := (befehlscode and $0080) = $0080;
        
    if zieltyp then // Gibt den Zieltyp an !
    begin // Ziel ist indiziert - also noch einen Operanden beachten
      zielstelle := fetch;
      // SR enthält für die Indizierung 0 - Absolute Indizierung !
      if zielregister <> sr then zielstelle := zielstelle + register[zielregister];                                
      inc(zyklen);
    end;
    // Im anderen Falle wäre das Ziel ein direkter Register, da ist nichts vorzubereiten.    
  end;      
  
  //------------------------------------------------------------------------------    
  procedure zwei_operanden_ziel_schreiben(operand : word); // Benutzt die in einer der beiden vorherigen Routinen bereiteten Angaben.   
  begin
    if bytebefehl then operand := operand and $FF; // Höherwertigen Bits Nullsetzen !
    
    if zieltyp then
    begin // Ziel ist indiziert
      if bytebefehl then byteschreiben(zielstelle, operand)
                    else wordschreiben(zielstelle, operand);
    end
    else begin // Ziel ist ein direkter Register.
           register[zielregister] := operand;  
           // Dient nur der Zyklenzählung.
           if (zielregister = pc) and ( // Wenn PC mit diesen beiden Varianten geschrieben wird, kostet das einen Extrazyklus.
                                         (((befehlscode and $0030)) = $0000) // Register
                                         or
                                         (((befehlscode and $0030)) = $0030) // @Rx+, auch Immediate !
                                      ) then inc(zyklen);    
         end;  
  end;
  
//------------------------------------------------------------------------------

function negativ(parameter : word) : boolean;
// Prüft, ob die gegenene Zahl negativ ist.
begin
  if bytebefehl then negativ := (parameter and $80)   = $80
                else negativ := (parameter and $8000) = $8000;
end;

function addc(parameter1, parameter2, parameter3 : word) : word;
// Führt die Rechenoperationen auf die "Addition mit Carry" zurück.
// Das sorgt für einheitliche Flags.
var ergebnis : word;
begin
  if bytebefehl then begin parameter1 := parameter1 and $FF; // Dies ist nötig, denn die invertierten Byte-Operanden
                           parameter2 := parameter2 and $FF; // haben durchaus die höheren 8 Bits gesetzt !
                           {parameter3 := parameter3 and $FF;}  end; // Carry ist immer 0 oder 1
                           
  if bytebefehl then setze_c( (parameter1 + parameter2 + parameter3) > $FF )
                else setze_c( (parameter1 + parameter2 + parameter3) > $FFFF );
  
  if bytebefehl then ergebnis := (parameter1 + parameter2 + parameter3) and $FF
                else ergebnis := (parameter1 + parameter2 + parameter3) and $FFFF;
  // Überlauf tritt ein, wenn die Operanden gleiche Vorzeichen hatten und dies beim Rechnen wechselt.             
  setze_v( ( negativ(parameter1) = negativ(parameter2) ) and ( negativ(parameter1) xor negativ(ergebnis) ) );  
  setze_n( negativ(ergebnis) );
  setze_z( ergebnis = 0 );
  addc := ergebnis;
end;

//------------------------------------------------------------------------------
// Der Hauptteil des prozessor_schritt;
//------------------------------------------------------------------------------
var quelle : word;
    
    // Variablen für Sprungbefehle
    sprungoffset : word;
    sprungziel : word;
    
    // Hilfsvariablen
    hilf1, hilf2 : word;
    hilfsflag : boolean;
    
    // Für die Beschriftung
    // opcodeadresse : word;
begin
  zyklen := 0;

  // opcodeadresse := register[pc]; Damit könnte ich bessere Fehlermeldungen ausgeben.
  befehlscode := opcode_fetch;  
  bytebefehl := (befehlscode and $0040) = $0040; // Wird für Sprünge natürlich nicht benötigt und ist da unsinnig !
    
  if (befehlscode and $F000) = $0000 then
  begin
    writeln(word2hex(register[pc]), ': Unbekannter Befehl: ', word2hex(befehlscode)); halt;
  end;
  
  if ((befehlscode and $F000) = $1000) and ((befehlscode and $FC00) <> $1000) then
  begin
    writeln(word2hex(register[pc]), ': Unbekannter Befehl: ', word2hex(befehlscode)); halt;
  end;
  
  if befehlscode = $12b1 then writeln('Mit call @sp+ stürzt echte CPU ab !');
  
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------  
  if (befehlscode and $FC00) = $1000 then
  begin    
    // quelle := quelloperand_dekodieren(befehlscode and $000F);   
    // Das rufe ich jetzt in jedem Befehl gesondert auf, da push erst den Stackregister verändert, 
    // bevor Adressbestimmungen durchgeführt werden.
    
    
    case (befehlscode and $0380) of // war mal 0280 - aber reti wird dann nicht erfasst !
      //------------------------------------------------------------------------------    
      $0000: begin // Links Rotieren
               quelle := quelloperand_dekodieren(befehlscode and $000F);   

               hilfsflag := lese_c;
               setze_n(hilfsflag);  // Der hineinzurotierende Carry wird das MSB - also das Vorzeichen.
               setze_c((quelle and 1) = 1); // LSB in Carry

               if bytebefehl then begin
                                    quelle := quelle and $FF;
                                    quelle := quelle shr 1;
                                    if hilfsflag then quelle := quelle or $80;
                                  end
                             else begin
                                    quelle := quelle shr 1;
                                    if hilfsflag then quelle := quelle or $8000;
                                  end;
               setze_v(false);
               setze_z(quelle = 0);
               ein_operand_ziel_schreiben(quelle);
             end;
      //------------------------------------------------------------------------------
      $0080: begin // swpb
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               if bytebefehl then writeln('swpb als Byte-Befehl aufgerufen...');
               ein_operand_ziel_schreiben(((quelle and $00FF) shl 8) or ((quelle and $FF00) shr 8));
             end;
      //------------------------------------------------------------------------------
      $0100: begin // Rechts Rotieren
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               setze_c((quelle and 1) = 1); // LSB in Carry
               
               if bytebefehl then begin
                                    quelle := quelle and $FF;
                                    quelle := quelle shr 1;
                                    hilfsflag := (quelle and $40) = $40;                                    
                                    if hilfsflag then quelle := quelle or $80;
                                  end
                             else begin
                                    quelle := quelle shr 1;
                                    hilfsflag := (quelle and $4000) = $4000;
                                    if hilfsflag then quelle := quelle or $8000;
                                  end;               
               setze_n(hilfsflag);
               setze_v(false);
               setze_z(quelle = 0);
               ein_operand_ziel_schreiben(quelle);
             end;
      //------------------------------------------------------------------------------       
      $0180: begin // sxt
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               if bytebefehl then writeln('sxt als Byte-Befehl aufgerufen...');
               
               hilfsflag := (quelle and $80) = $80; // Vorzeichen des Low-Bytes;
               setze_n(hilfsflag);
               quelle := quelle and $FF;
               if hilfsflag then quelle := quelle or $FF00;
               setze_z(quelle =  0);
               setze_c(quelle <> 0);
               setze_v(false);
               ein_operand_ziel_schreiben(quelle);
             end;
      //------------------------------------------------------------------------------       
      $0200: begin // push
               register[sp] := register[sp] - 2; // Erst verändern, dann Quelle dekodieren. Darin könnte relativ zu SP gerechnet werden.
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               wordschreiben(register[sp], quelle);
               
               if (befehlscode and $0030) = $0000 then zyklen := zyklen + 1; // Register                              
               if (befehlscode and $0030) = $0010 then zyklen := zyklen + 1; // Indexed                              
               if (befehlscode and $0030) = $0020 then zyklen := zyklen + 1; // Register Indirect
               
               if (befehlscode and $0030) = $0030 then
               begin
                 if (befehlscode and $000F) = 0 then zyklen := zyklen + 1  // Immediate
                                                else zyklen := zyklen + 2; // Register Indirect Autoimcrement / 
               end;                                 
             end;
      //------------------------------------------------------------------------------       
      $0280: begin // call
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               register[sp] := register[sp] - 2;
               wordschreiben(register[sp], register[pc]);
               register[pc] := quelle;
               speicher[quelle].calleinsprung := true;
               
               if (befehlscode and $0030) = $0000 then zyklen := zyklen + 3; // Register                              
               if (befehlscode and $0030) = $0010 then zyklen := zyklen + 1; // Indexed                              
               if (befehlscode and $0030) = $0020 then zyklen := zyklen + 1; // Register Indirect               
               if (befehlscode and $0030) = $0030 then zyklen := zyklen + 2; // Register Indirect Autoimcrement / Immediate 
             end;
      //------------------------------------------------------------------------------       
      $0300: begin // reti
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               inc(zyklen); inc(zyklen);
               if bytebefehl then writeln('reti als Byte-Befehl aufgerufen...');
               register[sr] := wordlesen(register[sp]);
               register[sp] := register[sp] + 2;
               register[pc] := wordlesen(register[sp]);
               register[sp] := register[sp] + 2;
             end;
      //------------------------------------------------------------------------------       
      $0380: begin // Unbenutzt !
               quelle := quelloperand_dekodieren(befehlscode and $000F);   
               writeln(word2hex(register[pc]), ': Unbekannter Befehl: ', word2hex(befehlscode)); halt;
             end;
    end;
    
  end; // Single Operand
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  
  
  
  
  
  
  
  
  
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  if (befehlscode and $E000) = $2000 then
  begin
    inc(zyklen);
    // Sprungziel berechnen:
    sprungoffset := (befehlscode and $03FF) shl 1; // Sprung ist nur zu geraden Adressen sinnvoll...
    // Dies Sprungziel ist negativ, muss für die Rechnungen das Vorzeichen erweitern !
    if (sprungoffset and $0400) = $0400 then sprungoffset := sprungoffset or $F800;
     
    sprungziel := register[pc] + sprungoffset;
   
    // Bedingung überprüfen
    case (befehlscode and $1C00) of
      $0000: begin if not lese_z then register[pc] := sprungziel; end;
      $0400: begin if     lese_z then register[pc] := sprungziel; end;
      $0800: begin if not lese_c then register[pc] := sprungziel; end;
      $0C00: begin if     lese_c then register[pc] := sprungziel; end;
      $1000: begin if     lese_n then register[pc] := sprungziel; end;
      $1400: begin if not(lese_n xor lese_v) then register[pc] := sprungziel; end;
      $1800: begin if     lese_n xor lese_v  then register[pc] := sprungziel; end;
      $1C00: begin register[pc] := sprungziel; end;
    end;
    // Sprung durchführen oder auch nicht.
  end; // Conditional Jump
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  
  
  
  
  
  
  //------------------------------------------------------------------------------
  //------------------------------------------------------------------------------
  if ((befehlscode and $F000) <> $1000) and ((befehlscode and $E000) <> $2000) then
  begin

    { Bei Double-Operand-Befehlen wird die Quelle nicht verändert, sondern das Ziel wird durch den zweiten Operanden bestimmt. }    
    quelle := quelloperand_dekodieren((befehlscode and $0F00) shr 8);    
                      
    case (befehlscode and $F000) of
      //------------------------------------------------------------------------------
      $4000: begin // mov -- Verändert die Flags nicht
               zwei_operanden_ziel; // Ließt den alten Zustand nicht !
               zwei_operanden_ziel_schreiben(quelle);
             end;
      //------------------------------------------------------------------------------       
      $5000: begin // add
               zwei_operanden_ziel_schreiben(addc(quelle, zwei_operanden_ziel_lesen, 0));
             end;
      //------------------------------------------------------------------------------       
      $6000: begin // addc
               zwei_operanden_ziel_schreiben(addc(quelle, zwei_operanden_ziel_lesen, carry));
             end;
      //------------------------------------------------------------------------------       
      $7000: begin // subc  (dst − src − 1 + C)
               zwei_operanden_ziel_schreiben(addc(not quelle, zwei_operanden_ziel_lesen, carry));
             end;
      //------------------------------------------------------------------------------       
      $8000: begin // sub
               zwei_operanden_ziel_schreiben(addc(not quelle, zwei_operanden_ziel_lesen, 1));
             end;
      //------------------------------------------------------------------------------       
      $9000: begin // cmp  --  Wie sub, nur das Ergebnis wird nicht gespeichert.
               addc(not quelle, zwei_operanden_ziel_lesen, 1);
             end;
      //------------------------------------------------------------------------------       
      $A000: begin // dadd                                                                **** Noch ungetestet.
               hilf1 := zwei_operanden_ziel_lesen;
                              
               if lese_c then hilf2 := 1 else hilf2 := 0;
               if bytebefehl then begin
                                    hilf2 := hilf2 + bcd2byte(quelle) + bcd2byte(hilf1);
                                    setze_c(hilf2 > 99);
                                    hilf2 := byte2bcd(hilf2);
                                  end  
                             else begin
                                    hilf2 := hilf2 + bcd2word(quelle) + bcd2word(hilf1);
                                    setze_c(hilf2 > 9999);
                                    hilf2 := word2bcd(hilf2);
                                  end; 
               setze_n(negativ(hilf2));                                   
               setze_z(hilf2 = 0);
               setze_v(false); // V-Zustand eigentlich undefiniert !!
               zwei_operanden_ziel_schreiben(hilf2);
             end;
      //------------------------------------------------------------------------------       
      $B000: begin // bit  --  Wie and, nur das Ergebnis wird nicht gespeichert.
               hilf1 := quelle and zwei_operanden_ziel_lesen;                                  
               setze_n(negativ(hilf1));                                  
               setze_z(hilf1 =  0);
               setze_c(hilf1 <> 0);
               setze_v(false);
             end;
      //------------------------------------------------------------------------------       
      $C000: begin // bic -- Verändert die Flags nicht
               zwei_operanden_ziel_schreiben(zwei_operanden_ziel_lesen and not quelle);
             end;
      //------------------------------------------------------------------------------       
      $D000: begin // bis -- Verändert die Flags nicht
               zwei_operanden_ziel_schreiben(zwei_operanden_ziel_lesen or quelle);               
             end;
      //------------------------------------------------------------------------------       
      $E000: begin // xor
               hilf1 := zwei_operanden_ziel_lesen;
               // Wenn beide Operanden negativ sind, wird V gesetzt.
               setze_v(negativ(quelle) and negativ(hilf1));
               hilf1 := quelle xor hilf1;         
               setze_n(negativ(hilf1));
               setze_z(hilf1 =  0);
               setze_c(hilf1 <> 0);
               zwei_operanden_ziel_schreiben(hilf1);                   
             end;
      //------------------------------------------------------------------------------       
      $F000: begin // and               
               hilf1 := quelle and zwei_operanden_ziel_lesen;                                  
               setze_n(negativ(hilf1));                                  
               setze_z(hilf1 =  0);
               setze_c(hilf1 <> 0);
               setze_v(false);               
               zwei_operanden_ziel_schreiben(hilf1);                   
             end;
      //------------------------------------------------------------------------------       
    else
      writeln(word2hex(register[pc]), ': Unbekannter Befehl: ', word2hex(befehlscode)); halt;
    end;


  end; // Double Operand

end;

(*  Ende des Emulators.

Noch ein Gedanke: Die vielen "and $FF" könnte ich bestimmt zum größten Teil weglassen,
da die Operanden brav Byte-Maskiert bereitgestellt werden. Ebenso sind die meisten logischen Operationen
treu in ihrem eigenen Byte... 

Gedanken, wie add, sub, addc, subc und cmp = sub ohne Ergebnisspeicherung zusammenzuführen wären.


add := addc mit Carry = 0
sub := subc mit Carry = 1

addc =      quelle  + hilf1 + carry
subc = (not quelle) + hilf1 + carry

also add =      quelle  + hilf1
     sub = (not quelle) + hilf1 + 1

Prinzipiell könnte ich subc quelle, hilf1 durch addc (not quelle), hilf1 ersetzen.
Die Flags müssen immer gleichmäßig gesetzt und gelöscht werden, wenn es um diese Rechnungen geht.
*)
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

 
(* Mecrimemu - angefangen am 19. Juni 2009 *)

(* Es soll einmal ein msp430-Prozessor-Emulator werden. *)
(* worin ich meine neuen Routinen und Gedanken testen kann. *)

(* Am 10. Juli 2009 waren bereits Einzelschritte möglich, 
   es wurde disassembliert, Statistiken aufgenommen
   und ein Speicherlisting rundete den Lauf ab. *)
   
(* Agenda:
     Breakpoints, Scrollen im Speicher, Stackfenster, Hardwareanbindung der IO-Ports.
     Fensterchen für die Ein/Ausgabe des Programms, wo auch während des Laufes aktualisiert wird.
     Vielleicht Einlesen des Assemblerlistings, wenn vorhanden ?
*)   

{ $define hardware}   

uses crt, sysutils, zahlenzauber, libbcd {$ifdef hardware}, hardwarezugriffe {$endif};                 // ****************


type tspeicherzelle = record
                        inhalt : byte;
                        belegt : boolean;
                        
                        opcode  : boolean;
                        operand : boolean;
                        fetched : longint;
                        lesezugriff    : boolean;
                        schreibzugriff : boolean;
                        gelesen : longint;
                        geschrieben : longint;
                        
                        calleinsprung : boolean;                        
                      end;  

var speicher : array[0..$FFFF] of tspeicherzelle;
    zyklen   : longint;

{$i ihex.pas}

   
type tregister = array[0..15] of word;

var register : tregister;

      // Standardmäßig wie beim F1232. 8k Flash, 256 Bytes Ram.
      ram_anfang   : word = $0200; 
      ram_ende     : word = $02FF; 

      flash_anfang : word = $E000;
      flash_ende   : word = $FFFF;  

{ Für den F201x    2k, 128 Bytes RAM
      ram_anfang   = $0200;
      ram_ende     = $027F;

      flash_anfang = $F800;
      flash_ende   = $FFFF;
}

      // Standardmäßig kein Image lesen/schreiben.
      image : boolean = false;
      image_anfang : word = $E000;
      image_ende   : word = $FFFF;
      imagedatei : string;

      // Einzelschrittbetrieb.
      terminal : boolean = false;

      // Definitionen laden.
      definitionenladen : boolean = false;
      definitionendatei : string;

      speicherkartegewuenscht : boolean = false;
      speicherkarte_anfang : word = $0000;
      speicherkarte_ende   : word = $FFFF;

      listinggewuenscht : boolean = false;
      listing_anfang : word = $0000;
      listing_ende   : word = $FFFF;

      // Normalerweise keine Fallen.
      trap : boolean = false;
      trapadresse : word;

      // Sonderfall: Image disassemblieren.
      disassemblieren : boolean = false;
      disasm_anfang : word = $0000;
      disasm_ende   : word = $FFFF;

const pc = 0; // Program Counter
      sp = 1; // Stack Pointer
      sr = 2; // Status Register
      //cg1 = 2; // SR benutzt als Konstantengenerator
      //cg2 = 3; // Konstantengenerator.
      cg  = 3;

//------------------------------------------------------------------------------
// Grenzen für die immer festgelegten Speicherbereiche:
      sfr_anfang   = $0000;
      sfr_ende     = $000F;
      
      //byteports_anfang = $0010;
      byteports_anfang = $0000; // Mit SFRs.
      byteports_ende   = $00FF;
      
      wordports_anfang = $0100;
      wordports_ende   = $01FF;
           
{$i cpu_disassembler.pas}      
{$i speicherkarte.pas}

      
//------------------------------------------------------------------------------  
// Routinen zur Kommunikation mit dem Emulatorinhalt      
            
var taste : word = 0;
    definitionen : file of byte;
    festspeicher : file of byte;
    lesedatei : boolean = false;

procedure emulator_emit(zeichen : word);

begin
  if (zeichen = 10) or (zeichen = 13) then writeln
  //writeln('Emulator-Emit');
  else write(chr(zeichen and $FF));
end;

function emulator_qkey : word;
begin
  //writeln('Emulator-?key');
  if lesedatei then
  begin
    if not eof(definitionen) then emulator_qkey := $FFFF
                             else begin emulator_qkey := 0; lesedatei := false; end;
                             
  end
  else
  begin  
    // if keypressed then emulator_qkey := $FFFF else emulator_qkey := 0; // True- und False-Flag
    emulator_qkey := $FFFF;
  end;  
end;

function emulator_key : word;
var b : byte;
begin
  //writeln('Emulator_key');
  if lesedatei then
  begin 
    b := 0; 
    if not eof(definitionen) then read(definitionen, b) else lesedatei := false;
    emulator_key := b and $FF;
  end
  else
  begin
    taste := ord(readkey) and $FF;
    emulator_key := taste;
  end;  
end;

//------------------------------------------------------------------------------  
// Anfang und Ende der Emulation. Vor- und Nachbereitungen.

procedure emulationsanfang;
var adresse : word; inhalt : byte;
begin
  writeln('Anfang der Emulation');

  {$ifdef hardware} hardware_init; {$endif}                                                                             // ****************

  // Wenn gewünscht, eine Definitionendatei zum Einlesen bereitlegen.
  if definitionenladen then
  begin
    assign(definitionen, definitionendatei);
    reset(definitionen);
    lesedatei := true;
  end;

  // Festspeicher laden
  if image then
  begin
    writeln('Lade Speicherabbild');
    if fileexists(imagedatei) then
    begin
      assign(festspeicher, imagedatei);
      reset(festspeicher);
      for adresse := image_anfang to image_ende do
      begin
        read(festspeicher, inhalt);
        speicher[adresse].inhalt := inhalt;
        speicher[adresse].belegt := true;
      end;
      close(festspeicher);
    end;
  end;
end;

procedure emulationsende;
var adresse : word;
begin
  {$ifdef hardware} hardware_abschluss; {$endif}                                                     // ****************

  if definitionenladen then close(definitionen);
  if image then
  begin
    writeln('Schreibe Speicherabbild');
    assign(festspeicher, imagedatei);
    rewrite(festspeicher, 1);
//    seek(festspeicher, 0);
    for adresse := image_anfang to image_ende do write(festspeicher, speicher[adresse].inhalt);
    close(festspeicher);
  end;
  writeln;
  if speicherkartegewuenscht then speicherkarte(speicherkarte_anfang, speicherkarte_ende);//speicherkarte(0, ram_ende);
  writeln;
  if listinggewuenscht then bereichslisting(listing_anfang, listing_ende);//bereichslisting(0, ram_ende);
  writeln;
  //speicherkarte(ram_ende+1, $FFFF);
end;

procedure emulationsende_freiwillig;
begin
  emulationsende;
  writeln('Freiwillig beendet.');
  writeln;
  halt;
end;

procedure emulationsende_gewaltsam;
begin
  emulationsende;
  writeln('Mit Esc beendet.');
  writeln;
  halt;
end; 


procedure notbremse;
var i, j, k : integer;
begin
  writeln;
  writeln;
  writeln('Notbremse gezogen an Adresse $', word2hex(trapadresse));
  writeln;
  writeln('Registerinhalte');
  write('       '); for i := 0 to 15 do write(i:4, ' '); writeln;
  write('       '); for i := 0 to 15 do write(word2hex(register[i]), ' '); writeln;  
  writeln('Speicherumgebung der Register');
  write('      '); for i := 0 to 15 do write(i:4, ' '); writeln;
  for i := -10 to 10 do
  begin
    k := 2*i;
    write(k:5, ': ');
    for j := 0 to 15 do write(byte2hex(speicher[register[j] + 2*i].inhalt),
                              byte2hex(speicher[register[j] + 2*i + 1].inhalt), ' ');
    writeln;
  end;
  writeln;
  emulationsende;
  writeln;
  halt;
end;

procedure trapadressprobe(adresse : { Lena kam und wir haben uns prima unterhalten ;-) } word);
begin
  if trap then
    if adresse = trapadresse then notbremse;
end;


//------------------------------------------------------------------------------  
// Routinen für die Speicherzugriffe
{$i speicherzugriffe.pas}

//------------------------------------------------------------------------------  
// Emulator für den Prozessor
{$i cpu_emulator.pas}

//------------------------------------------------------------------------------  
// Emulationsoberfläche

procedure emulation_stumm;
begin
  repeat 
    prozessor_schritt;
    //h := sendeword(0); 
    // writeln(word2hex(h), ' ', chr(h and $FF)); 
    //write(chr(h));
  until taste = 27;
end;

{
function sendeword(daten : word) : word;
begin
  sendeword_sendepuffer := daten;
  repeat prozessor_schritt until sendeword_flag or keypressed;
  sendeword := sendeword_empfangspuffer; 
  sendeword_flag := false; 
end;
}

{
procedure emulatorkommunikation;
var h : word;
begin
  clrscr; 
  // Kann nun wie gewohnt mit dem Emulator über mein geliebter Sendeword kommunizieren ;-)
  repeat 
    h := sendeword(0); 
    writeln(word2hex(h), ' ', chr(h and $FF)); 
  until keypressed;
end; 
}

{$i emulation-bunt.pas}


procedure disasm_image;
var alte_adresse, adresse, zeiger : word;
    befehl : string;    
  begin
    writeln ('Disassemblere.');
    adresse := disasm_anfang;
    while adresse <= disasm_ende do
    begin
      write(word2hex(adresse), ':   ');
      alte_adresse := adresse;
      befehl := prozessor_disassembler_schritt(adresse);
      for zeiger := (alte_adresse shr 1) to (adresse shr 1) - 1 do 
        write (word2hex(  speicher[zeiger shl 1].inhalt or (speicher[zeiger shl 1 + 1].inhalt shl 8)  ), ' ');
      gotoxy(26, wherey);
      writeln(befehl);
      //writeln;
    end;
    halt; { Nicht emulieren, sondern nur Disassemblieren. Gibt z.B. keine IRQ-Vektoren }
  end;


    
function strtoadr(zeile : string) : word;
var wandlung : word;
    fehler : integer;
begin
  val(zeile, wandlung, fehler);
  if fehler <> 0 then begin 
                        writeln(zeile, ' ist eine ungültige Adresse.');
                        writeln(wandlung);
                        halt;
                      end;
  strtoadr := wandlung;
end;

var parameterzaehler : integer;

function holeparameter : string;
begin
  if parameterzaehler <= paramcount then
  begin
    holeparameter := paramstr(parameterzaehler);
    inc(parameterzaehler);
  end
  else
  begin
    writeln('Seltsame Parameterkombination.');
    halt;
  end;  
end;

var aktueller_parameter : string;

begin  
  if paramcount < 1 then
  begin
    writeln('memu - Prozessorsimulator für MSP430 von Matthias Koch');
    writeln('Aufruf: memu');
    writeln('          hex (Intel-Hex-Datei)            Läd Programm');
    writeln('          speicher (Anfang) (Ende)         Veränderbarer Speicher');
    writeln('          flash (Anfang) (Ende)            Unveränderbarer Speicher');
    writeln('          image (Anfang) (Ende) (Image)    Läd und sichert einen Bereich des Speichers');
    writeln('          einzelschritt                    Erlaubt tiefe Prozessoreinblicke');
    writeln('          terminal                         Startet Terminalemulation');
    writeln('          definitionen (Definitionsdatei)  Läd zu Beginn eine Textdatei ins Terminal');
    writeln('          speicherkarte (Anfang) (Ende)    Zeigt ein Hexdump');
    writeln('          listing (Anfang) (Ende)          Listing mit Aufrufstatistik und Einsprungstellen');
    writeln('          trap (Adresse)                   Zieht Notbremse, wenn ein Zugriff auf diese Adresse erfolgt.');
    writeln('          disasm (Anfang) (Ende)           Disassembliert, aber führt nicht aus');
    halt;
  end;

  speicherloeschen; // Setzt am Anfang alles auf $FFFF.

  parameterzaehler := 1;
  while parameterzaehler <= paramcount do
  begin    
    aktueller_parameter := holeparameter;

    if lowercase(aktueller_parameter) = 'hex' then lese_ihex(holeparameter);

    if lowercase(aktueller_parameter) = 'definitionen' then 
    begin 
      definitionenladen := true; 
      definitionendatei := holeparameter;
    end;

    if lowercase(aktueller_parameter) = 'speicher' then 
    begin
      ram_anfang := strtoadr(holeparameter);
      ram_ende   := strtoadr(holeparameter);
    end;

    if lowercase(aktueller_parameter) = 'image' then 
    begin
      image := true;
      image_anfang := strtoadr(holeparameter);
      image_ende   := strtoadr(holeparameter);
      imagedatei := holeparameter;
    end;

    if lowercase(aktueller_parameter) = 'flash' then
    begin
      flash_anfang := strtoadr(holeparameter);
      flash_ende   := strtoadr(holeparameter);
    end;

    if lowercase(aktueller_parameter) = 'terminal' then terminal := true;
    if lowercase(aktueller_parameter) = 'einzelschritt' then terminal := false;

    if lowercase(aktueller_parameter) = 'speicherkarte' then 
    begin
      speicherkartegewuenscht := true;
      speicherkarte_anfang := strtoadr(holeparameter);
      speicherkarte_ende   := strtoadr(holeparameter);
    end;

    if lowercase(aktueller_parameter) = 'listing' then 
    begin
      listinggewuenscht := true;
      listing_anfang := strtoadr(holeparameter);
      listing_ende   := strtoadr(holeparameter);
    end;

    if lowercase(aktueller_parameter) = 'trap' then 
    begin
      trap := true;
      trapadresse := strtoadr(holeparameter);
    end;

    if lowercase(aktueller_parameter) = 'disasm' then
    begin
      disassemblieren := true;
      disasm_anfang := strtoadr(holeparameter);
      disasm_ende   := strtoadr(holeparameter);
    end;

  end; // while
  

  writeln('Speicherbereiche:');
  writeln('Ram von $', word2hex(ram_anfang), ' bis $', word2hex(ram_ende));
  writeln('Flash von $', word2hex(flash_anfang), ' bis $', word2hex(flash_ende));
  if image then writeln('Image von $', word2hex(image_anfang), ' bis $', word2hex(image_ende));
  writeln;

  // Anfang machen. Reset-Vektor laden.
  register[pc] := wordlesen($FFFE); // Reset-Vektor in PC legen.
  register[sr] := 0;                // CPU an !
  zyklen := 4; // Zahl der Zyklen, die bis zum ersten Befehl vergehen.

  emulationsanfang; { Präpariert den Speicher }

  if disassemblieren then disasm_image;
  
  if terminal then emulation_stumm
              else emulation_bunt;
    
  emulationsende_gewaltsam;
end.
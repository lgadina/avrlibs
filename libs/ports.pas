unit ports;

{$mode objfpc}{$H+}
{$ModeSwitch advancedrecords}

{$Optimization REGVAR}


interface

uses
  intrinsics;
const
  pmPullUp  = 0;
  pmInput   = 1;
  pmOutput  = 2;
  HIGH      = true;
  LOW       = false;

type
  generic TPin<const T: Byte> = record
  public
    procedure writeBit(const AValue: boolean);
    function readBit: boolean;

    procedure writeBitInline(const AValue: Boolean); inline;
    procedure setMode(AMode: Byte); inline;
    function readBitInline: boolean; inline;
  end;

function sbi(b, n: byte): byte; inline;
function cbi(b, n: byte): byte; inline;
function bitIsSet(b, n: byte): boolean; inline;
function bitIsClear(b, n: byte): boolean; inline;

implementation

{ TPin }

procedure TPin.writeBit(const AValue: boolean);
begin
  {$IfDef CPUAVR5}
  {$i portwrite.inc}
  {$EndIf}
end;

procedure TPin.writeBitInline(const AValue: Boolean);
begin
  {$IfDef CPUAVR5}
  {$i portwrite.inc}
  {$EndIf}
end;

function TPin.readBit: boolean;
begin
  {$IfDef CPUAVR5}
  {$i portread.inc}
  {$EndIf}
end;

function TPin.readBitInline: boolean;
begin
  {$IfDef CPUAVR5}
  {$i portread.inc}
  {$EndIf}
end;

procedure TPin.setMode(AMode: Byte);
var old: byte;
begin
  old := SREG;
  avr_cli;
  {$IfDef CPUAVR5}
  {$i portmode.inc}
  {$EndIf}
  SREG := old;
end;

function sbi(b, n: byte): byte;
begin
 result := b or byte(1 shl n);
end;

function cbi(b, n: byte): byte;
begin
  result := b and not (1 shl n);
end;

function bitIsSet(b, n: byte): boolean;
begin
  result := (b and (1 shl n)) > 0;
end;

function bitIsClear(b, n: byte): boolean;
begin
  result := (b and (1 shl n)) = 0;
end;

end.


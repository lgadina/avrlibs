unit timers;

{$mode ObjFPC}{$H+}
{$ModeSwitch advancedrecords}

interface

{$define MAX_PERIOD_8 := 1000000 * 1024 div F_CPU * 256}		// 16384 (61 Гц) на 16 МГц
{$define MAX_PERIOD_16 := 1000000 * 1024 div F_CPU * 65536}	// 4194304 (0.24 Гц) на 16 МГц
{$define WGM01 := 1}
{$define WGM00 := 0}
{$define CHANNEL_A := 0}
{$define CHANNEL_B := 1}

type

  { TAvrTimer1 }

  TAvrTimer = record
  public
    function setPeriod(APeriod: UInt32): UInt32;
    function setFrequency(AFrequency: UInt32): UInt32;
    procedure pause;
    procedure resume;
    procedure stop;
    procedure restart;
    procedure disableInterrupt(AChannel: UInt8);
    procedure enableInterrupt(AChannel: UInt8);
  end;

implementation

var timer0_clock: UInt8 = 0;

{ TAvrTimer1 }

function TAvrTimer.setPeriod(APeriod: UInt32): UInt32;
var cycles: UInt32;
    prescaler: UInt8;
    divider: UInt16;
    top: UInt8;
begin
 if APeriod > MAX_PERIOD_8 then
   APeriod := MAX_PERIOD_8;
 cycles := F_CPU div 1000000 * APeriod;
 if cycles < 256 then
   begin
     prescaler:=1;
     divider:=1;
   end else
  if cycles < (256 * 8) then
    begin
      prescaler:=2;
      divider:=8;
    end else
  if cycles < (256 * 64) then
    begin
      prescaler:=3;
      divider:=64;
    end else
  if cycles < (256 * 256) then
    begin
      prescaler:=4;
      divider:=256;
    end else
    begin
      prescaler:=5;
      divider:=1024;
    end;
    if cycles < (256 * 1024) then
      top := cycles div divider
    else
      top := 0;

{$IfDef CPUAVR}
    TCCR0A := (TCCR0A and $F0) or (1 shl WGM01) or (0 shl WGM00);
    TCCR0B := prescaler;
    OCR0A := top - 1;
    timer0_clock := (TCCR0B and $07);
{$EndIf}

    if top > 0 then
     result := 1000000 div ((F_CPU div divider) div top)
    else
     result := 1000000 div ((F_CPU div divider) div UInt8(top-1));
{$IfNDef CPUAVR}
    writeln('Cycles: ', cycles);
    writeln('Period: ', APeriod, ' us');
    Writeln('Real period: ', Result, ' us');
    writeln('Prescaler: ', prescaler);
    writeln('Divider: ', divider);
    writeln('Counter: ', top);
    writeln('Max period: ', MAX_PERIOD_8);
    writeln('F_CPU: ', F_CPU);

{$EndIf}
end;

function TAvrTimer.setFrequency(AFrequency: UInt32): UInt32;
begin
  result := 1000000 div (setPeriod(1000000 div AFrequency));
  {$IfNDef CPUAVR}
    writeln('Request freq: ', AFrequency, ' Hz');
    Writeln('Real freq: ', Result, ' Hz');
  {$EndIf}
end;

procedure TAvrTimer.pause;
begin
  {$IfDef CPUAVR}
    TCCR0B := (TCCR0B and $F8);
  {$EndIf}
end;

procedure TAvrTimer.resume;
begin
  {$IfDef CPUAVR}
    TCCR0B := (TCCR0B and $F8) or timer0_clock;
  {$EndIf}
end;

procedure TAvrTimer.stop;
begin
 pause;
 {$IfDef CPUAVR}
   TCNT0 := 0;
 {$EndIf}
end;

procedure TAvrTimer.restart;
begin
 resume;
 {$IfDef CPUAVR}
   TCNT0 := 0;
 {$EndIf}
end;

procedure TAvrTimer.disableInterrupt(AChannel: UInt8);
begin
  {$IfDef CPUAVR}
   if AChannel = CHANNEL_A then
    TIMSK0:= TIMSK0 and not (1 shl OCIE0A)
   else
   if AChannel = CHANNEL_B then
    TIMSK0:= TIMSK0 and not (1 shl OCIE0B);
  {$EndIf}
end;

procedure TAvrTimer.enableInterrupt(AChannel: UInt8);
begin
  {$IfDef CPUAVR}
  if AChannel = CHANNEL_A then
    TIMSK0 := TIMSK0 or (1 shl OCIE0A)
  else
  if AChannel = CHANNEL_B then
    TIMSK0 := TIMSK0 or (1 shl OCIE0B);
  {$EndIf}
end;


end.


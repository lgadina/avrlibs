unit timers;

{$mode ObjFPC}{$H+}
{$ModeSwitch advancedrecords}

interface

type

  { TAvrTimer1 }
  {
  TCCR0A
  +--------+--------+--------+--------+---+---+-------+-------+
  |   7    |   6    |   5    |   4    | 3 | 2 |   1   |   0   |
  | COM0A1 | COM0A0 | COM0B1 | COM0B0 | - | - | WGM01 | WGM00 |
  +--------+--------+--------+--------+---+---+-------+-------+

  TCCR0B
  +-------+-------+---+---+-------+------+------+------+
  |  7    |   6   | 5 | 4 |   3   |  2   |  1   |  0   |
  | FOC0A | FOC0B | - | - | WGM02 | CS02 | CS01 | CS00 |
  +-------+-------+---+---+-------+------+------+------+

  TIMSK0
  +---+---+---+---+---+--------+--------+-------+
  | 7 | 6 | 5 | 4 | 3 |    2   |  1     |   0   |
  | - | - | - | - | - | OCIE0B | OCIE0A | TOIE0 |
  +---+---+---+---+---+--------+--------+-------+

  TIFR0
  +---+---+---+---+---+-------+-------+------+
  | 7 | 6 | 5 | 4 | 3 |   2   |   1   |   0  |
  | - | - | - | - | - | OCF0B | OCF0A | TOV0 |
  +---+---+---+---+---+-------+-------+------+

  }
  generic TAvrTimer<const TimerNo: byte> = record
  private
  {$IfNDef CPUAVR}
    TCCR0A: byte;
    TCCR0B: byte;
    OCR0A: byte;
    TCNT0: byte;
    TIMSK0: byte;

    TCCR1A: byte;
    TCCR1B: byte;
    ICR1: word;
    TCNT1: byte;
    TIMSK1: byte;

    TCCR2A: byte;
    TCCR2B: byte;
    OCR2A: byte;
    TCNT2: byte;
    TIMSK2: byte;

    cycles: uint32;
    prescaler: uint8;
    divider: uint16;
    top: uint16;
    period: uint32;
    realPeriod: uint32;
    freq, realFreq: uint32;
  {$EndIf}

    timer0_clock: uint8;
  public
    function setPeriod(APeriod: uint32): uint32;
    function setFrequency(AFrequency: uint32): uint32;
    procedure pause;
    procedure resume;
    procedure stop;
    procedure restart;
    procedure disableInterrupt(AChannel: uint8);
    procedure enableInterrupt(AChannel: uint8);
  {$IfNDef CPUAVR}
    procedure printDebugInfo;
  {$EndIf}
  end;

const
  CHANNEL_A = 0;
  CHANNEL_B = 1;

const
  WGM01 = 1;
  WGM00 = 0;
  WGM21 = 1;
  WGM20 = 0;
  WGM13 = 4;
  WGM12 = 3;

{$IfNDef CPUAVR}
const
  OCIE0A = 1;
  OCIE0B = 2;
  OCIE1A = 1;
  OCIE1B = 2;
  OCIE2A = 1;
  OCIE2B = 2;
{$EndIf}

implementation

{$IfNDef CPUAVR}
uses
  StrUtils;

{$EndIf}


{$define MAX_PERIOD_8 := 1000000 * 1024 div F_CPU * 256}// 16384 (61 Гц) на 16 МГц
{$define MAX_PERIOD_16 := 1000000 * 1024 div F_CPU * 65536}// 4194304 (0.24 Гц) на 16 МГц


{ TAvrTimer1 }

function TAvrTimer.setPeriod(APeriod: uint32): uint32;
{$IfDef CPUAVR}
var
    cycles: UInt32;
    prescaler: UInt8;
    divider: UInt16;
    top: UInt16;
{$EndIf}
begin
  if TimerNo in [0, 2] then
  begin
    if APeriod > MAX_PERIOD_8 then
      APeriod := MAX_PERIOD_8;

    cycles := F_CPU div 1000000 * APeriod;
    if cycles < 256 then
    begin
      prescaler := 1;
      divider := 1;
    end
    else
    if cycles < (256 * 8) then
    begin
      prescaler := 2;
      divider := 8;
    end
    else
    if cycles < (256 * 64) then
    begin
      prescaler := 3;
      divider := 64;
    end
    else
    if cycles < (256 * 256) then
    begin
      prescaler := 4;
      divider := 256;
    end
    else
    begin
      prescaler := 5;
      divider := 1024;
    end;
    if cycles < (256 * 1024) then
      top := cycles div divider
    else
      top := 0;
    if TimerNo = 0 then
    begin
      TCCR0A := (TCCR0A and $F0) or (1 shl WGM01) or (0 shl WGM00);
      TCCR0B := prescaler;
      OCR0A := top - 1;
      timer0_clock := (TCCR0B and $07);
    end
    else if TimerNo = 2 then
    begin
      TCCR2A := (TCCR2A and $F0) or (1 shl WGM21) or (0 shl WGM20);
      TCCR2B := prescaler;
      OCR2A := top - 1;
    end;

    if top > 0 then
      Result := 1000000 div ((F_CPU div divider) div top)
    else
      Result := 1000000 div ((F_CPU div divider) div uint8(top - 1));

  end
  else
  if TimerNo = 1 then
  begin
    if APeriod > MAX_PERIOD_16 then
      APeriod := MAX_PERIOD_16;
    cycles := F_CPU div 1000000 * APeriod;
    if cycles < 65536 then
    begin
      prescaler := 1;
      divider := 1;
    end
    else
    if cycles < 65536 * 8 then
    begin
      prescaler := 2;
      divider := 8;
    end
    else
    if cycles < 65536 * 64 then
    begin
      prescaler := 3;
      divider := 64;
    end
    else
    if cycles < 65536 * 256 then
    begin
      prescaler := 4;
      divider := 256;
    end
    else
    begin
      prescaler := 5;
      divider := 1024;
    end;

    if cycles < 65536 * 1024 then
      top := cycles div divider
    else
      top := 65536;

    TCCR1A := TCCR1A and $F0;
    TCCR1B := ((1 shl WGM13) or (1 shl WGM12) or prescaler);
    ICR1 := top - 1;
    timer0_clock := (TCCR1B and $07);
    if top > 0 then
      Result := 1000000 div ((F_CPU div divider) div top)
    else
      Result := 1000000 div ((F_CPU div divider) div uint16(top - 1));
  end;
{$IfNDef CPUAVR}
  realPeriod := Result;
  period := APeriod;
{$EndIf}
end;

function TAvrTimer.setFrequency(AFrequency: uint32): uint32;
begin
  Result := 1000000 div (setPeriod(1000000 div AFrequency));
  {$IfNDef CPUAVR}
  freq := AFrequency;
  realFreq := Result;
  {$EndIf}
end;

procedure TAvrTimer.pause;
begin
  if TimerNo = 0 then
    TCCR0B := (TCCR0B and $F8)
  else if TimerNo = 1 then
    TCCR1B := (TCCR1B and $F8)
  else if TimerNo = 2 then
    TCCR2B := (TCCR2B and $F8);
end;

procedure TAvrTimer.resume;
begin
  if TimerNo = 0 then
    TCCR0B := (TCCR0B and $F8) or timer0_clock
  else if TimerNo = 1 then
    TCCR1B := (TCCR1B and $F8) or timer0_clock
  else if TimerNo = 2 then
    TCCR2B := (TCCR2B and $F8) or timer0_clock;
end;

procedure TAvrTimer.stop;
begin
  pause;
  if TimerNo = 0 then
    TCNT0 := 0
  else if TimerNo = 1 then
    TCNT1 := 0
  else if TimerNo = 2 then
    TCNT2 := 0;
end;

procedure TAvrTimer.restart;
begin
  resume;
  if TimerNo = 0 then
    TCNT0 := 0
  else if TimerNo = 1 then
    TCNT1 := 0
  else if TimerNo = 2 then
    TCNT2 := 0;

end;

procedure TAvrTimer.disableInterrupt(AChannel: uint8);
begin
  if TimerNo = 0 then
  begin
    if AChannel = CHANNEL_A then
      TIMSK0 := TIMSK0 and not (1 shl OCIE0A)
    else
    if AChannel = CHANNEL_B then
      TIMSK0 := TIMSK0 and not (1 shl OCIE0B);
  end
  else
  if TimerNo = 1 then
  begin
    if AChannel = CHANNEL_A then
      TIMSK1 := TIMSK1 and not (1 shl OCIE1A)
    else
    if AChannel = CHANNEL_B then
      TIMSK1 := TIMSK1 and not (1 shl OCIE1B);
  end
  else
  if TimerNo = 2 then
  begin
    if AChannel = CHANNEL_A then
      TIMSK2 := TIMSK2 and not (1 shl OCIE2A)
    else
    if AChannel = CHANNEL_B then
      TIMSK2 := TIMSK2 and not (1 shl OCIE2B);
  end;
end;

procedure TAvrTimer.enableInterrupt(AChannel: uint8);
begin
  if TimerNo = 0 then
  begin
    if AChannel = CHANNEL_A then
      TIMSK0 := TIMSK0 or (1 shl OCIE0A)
    else
    if AChannel = CHANNEL_B then
      TIMSK0 := TIMSK0 or (1 shl OCIE0B);
  end
  else
  if TimerNo = 1 then
  begin
    if AChannel = CHANNEL_A then
      TIMSK1 := TIMSK1 or (1 shl OCIE1A)
    else
    if AChannel = CHANNEL_A then
      TIMSK1 := TIMSK1 or (1 shl OCIE1B);
  end
  else
  if TimerNo = 2 then
  begin
    if AChannel = CHANNEL_A then
      TIMSK2 := TIMSK2 or (1 shl OCIE2A)
    else
    if AChannel = CHANNEL_B then
      TIMSK2 := TIMSK2 or (1 shl OCIE2B);
  end;
end;

{$IfNDef CPUAVR}
procedure TAvrTimer.printDebugInfo;
begin
  Writeln('Timer', TimerNo);
  writeln('Request freq: ', freq, ' Hz');
  Writeln('Real freq: ', realFreq, ' Hz');
  writeln('Cycles: ', cycles);
  writeln('Period: ', period, ' us');
  Writeln('Real period: ', realPeriod, ' us');
  writeln('Prescaler: ', prescaler);
  writeln('Divider: ', divider);
  writeln('Counter: ', top);
  writeln('F_CPU: ', F_CPU);
  if TimerNo = 0 then
  begin
    writeln('Max period: ', MAX_PERIOD_8);
    Writeln('TCCR0A: ', IntToBin(TCCR0A, 8));
    Writeln('TCCR0B: ', IntToBin(TCCR0B, 8));
    Writeln('TIMSK0: ', IntToBin(TIMSK0, 8));
  end
  else
  if TimerNo = 1 then
  begin
    writeln('Max period: ', MAX_PERIOD_16);
    Writeln('TCCR1A: ', IntToBin(TCCR1A, 8));
    Writeln('TCCR1B: ', IntToBin(TCCR1B, 8));
    Writeln('TIMSK1: ', IntToBin(TIMSK1, 8));
  end
  else
  if TimerNo = 2 then
  begin
    writeln('Max period: ', MAX_PERIOD_8);
    Writeln('TCCR2A: ', IntToBin(TCCR2A, 8));
    Writeln('TCCR2B: ', IntToBin(TCCR2B, 8));
    Writeln('TIMSK2: ', IntToBin(TIMSK2, 8));
  end;
end;

{$EndIf}

end.

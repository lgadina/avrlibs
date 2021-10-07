program project1;

uses {$IfDef CPUAVR} intrinsics, {$EndIf}
     ports,
     delay,
     onewire,
     uart,
     avrutils,
     timers;
{atmega328p}

var Pin : specialize TPin<13>;
    Pin6: specialize TPin<6>;
    Ow: specialize TOneWire<7>;
    addr: TOneWireRom;
    tmr: TAvrTimer;

procedure SystemTickInterrupt; public name 'TIMER0_COMPA_ISR'; interrupt;
begin
  Pin6.writeBitInline(not Pin6.readBitInline);
end;

begin
  avr_sei;

  Pin.SetMode(pmOutput);
  Pin6.SetMode(pmOutput);
  Pin6.writeBit(True);
  tmr.setFrequency(1000000);
  tmr.enableInterrupt(0);
  repeat
    Pin.writeBit(true);
    delay_usl(_calc_usw(480));
    Pin.writeBit(false);
    delay_usl(_calc_usw(410));
    Pin.writeBit(true);
    delay_us(_calc_usw(3));
    Pin.writeBit(false);
    delay_us(_calc_usw(10));
  until false;

end.


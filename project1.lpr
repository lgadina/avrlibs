program project1;

uses intrinsics, ports, delay, onewire, progmem;
{atmega328p}

var Pin : TPin<13>;
    Ow: TOneWire<7>;
    addr: TOneWireRom;

begin

  Pin.SetMode(pmOutput);
  Ow.&begin;
  ow.reset;
  if not ow.search(addr, true) then
   ;
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


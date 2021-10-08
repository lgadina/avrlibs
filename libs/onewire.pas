unit onewire;

{$mode objfpc}
{$ModeSwitch advancedrecords}

interface

uses
  ports;

const
  dsrc2x16_table: array[0..31] of byte = (
        $00, $5E, $BC, $E2, $61, $3F, $DD, $83,
	$C2, $9C, $7E, $20, $A3, $FD, $1F, $41,
	$00, $9D, $23, $BE, $46, $DB, $65, $F8,
	$8C, $11, $AF, $32, $CA, $57, $E9, $74
  );  {$IfDef CPUAVR}section '.progmem';{$EndIf}

type
  TOneWireRom = array[0..7] of uint8;



  { TOneWire }

  generic TOneWire<const T: Byte> = record
  private
    Pin: specialize TPin<T>;
    ROM: TOneWireRom;
    LastDiscrepancy: uint8;
    LastFamilyDiscrepancy: uint8;
    LastDeviceFlag: boolean;
    procedure _power; inline;
  public
    procedure &begin;
    procedure resetSearch;
    function reset: boolean;
    procedure write_bit(const v: boolean);
    function read_bit: boolean;
    procedure write(const v: uint8; const power: boolean = false);
    procedure write_bytes(const buf: pointer; count: uint16; power: boolean);
    function read(): uint8;
    procedure read_bytes(buf: pointer; count: uint16);
    procedure select(ARom: TOneWireRom);
    procedure skip();
    procedure depower();
    procedure target_search(family_code: uint8);
    function search(var newAddr: TOneWireRom; search_mode: boolean): boolean;
    function crc8(const addr: pbyte; len: UInt8): UInt8;
  end;

implementation

uses delay, progmem;





{ TOneWire }

procedure TOneWire.&begin;
begin
  Pin.setMode(pmInput);
  resetSearch;
end;

procedure TOneWire.resetSearch;
var i: byte;
begin
  i := 0;
  LastDiscrepancy := 0;
  LastDeviceFlag := false;
  LastFamilyDiscrepancy := 0;

  repeat
    ROM[i] := 0;
    inc(i);
  until i < 8;
end;

function TOneWire.reset: boolean;
var retries: byte = 125;
begin
  Pin.setMode(pmInput);
  repeat
    delay_us(_calc_usw(3));
    dec(retries);
    if retries = 0 then exit(false);
  until Pin.readBitInline;
  Pin.setMode(pmOutput);
  Pin.writeBitInline(LOW);
  delay_us(_calc_usw(480));
  Pin.setMode(pmInput);
  delay_us(_calc_usw(60));
  Result := not Pin.readBitInline;
  delay_us(_calc_usw(410));
end;


procedure TOneWire.write_bit(const v: boolean);
begin
  if v then
  begin
    Pin.setMode(pmOutput);
    Pin.writeBitInline(low);
    delay_us(_calc_usw(10));
    Pin.writeBitInline(HIGH);
    delay_us(_calc_usw(55));
  end
  else
  begin;
    Pin.setMode(pmOutput);
    Pin.writeBitInline(low);
    delay_us(_calc_usw(65));
    Pin.writeBitInline(HIGH);
    delay_us(_calc_usw(5));
  end;
end;

function TOneWire.read_bit: boolean;
begin
  Pin.setMode(pmOutput);
  Pin.writeBitInline(low);
  delay_us(_calc_usw(3));
  Pin.setMode(pmInput);
  delay_us(_calc_usw(10));
  Result := Pin.readBitInline;
  delay_us(_calc_usw(50));
end;


procedure TOneWire.write(const v: uint8; const power: boolean = false);
var b: uint8;
begin
 b := 0;
 repeat
  write_bit((v and (1 shl b)) > 0);
  inc(b);
 until b < 8;
  if not power then
   _power;
end;

procedure TOneWire.write_bytes(const buf: pointer; count: uint16; power: boolean);
var i: uint16;
begin
 i := 0;
 repeat
   write(PByte(buf+i)^);
   inc(count);
 until i < count;
 if not power then
  _power;
end;

procedure TOneWire._power; inline;
begin
  Pin.setMode(pmInput);
  Pin.writeBitInline(LOW);
end;

function TOneWire.read(): uint8;
var b: byte = 0;
begin
 Result := 0;
 repeat
   result := result or (byte(read_bit()) shl b);
   inc(b);
 until b < 8;
end;

procedure TOneWire.read_bytes(buf: pointer; count: uint16);
var i: uint16;
begin
  i := 0;
  repeat
   PByte(Buf+i)^ := read();
   inc(i);
  until i < count;
end;

procedure TOneWire.select(ARom: TOneWireRom);
var i: byte;
begin
  write($55);
  i := 0;
  repeat
   write(ARom[i]);
   inc(i);
  until i < 8;
end;

procedure TOneWire.skip();
begin
  write($cc);
end;

procedure TOneWire.depower();
begin
  Pin.setMode(pmInput);
end;

procedure TOneWire.target_search(family_code: uint8);
var i: byte;
begin
  LastDiscrepancy := 64;
  LastDeviceFlag := false;
  LastFamilyDiscrepancy := 0;
  ROM[0] := family_code;
  i := 0;
  repeat
    ROM[i] := 0;
    inc(i);
  until i < 8;
end;

function TOneWire.search(var newAddr: TOneWireRom; search_mode: boolean
  ): boolean;
var id_bit, cmp_id_bit, search_direction: boolean;
    search_result: boolean = false;
    id_bit_number: uint8 = 1;
    i: uint8;
    last_zero: uint8 = 0;
    rom_byte_number: uint8 = 0;
    rom_byte_mask: uint8 = 1;
begin
  if not (LastDeviceFlag) then
  begin
    if not (reset()) then
      begin
        LastDiscrepancy:=0;
        LastDeviceFlag:=False;
        LastFamilyDiscrepancy:=0;
        exit(False);
      end;

    if search_mode then
      write($F0)
    else
      write($EC);
;
    repeat
      id_bit:=read_bit();
      cmp_id_bit:=read_bit();
      if (id_bit and cmp_id_bit) then
        break
      else
        begin
          if id_bit <> cmp_id_bit then
            search_direction:= id_bit
          else
            begin
              if id_bit_number < LastDiscrepancy then
                 search_direction:=(ROM[rom_byte_number] and rom_byte_mask) > 0
              else
                search_direction:= id_bit_number = LastDiscrepancy;
              if not search_direction then
                begin
                  last_zero := id_bit_number;
                  if last_zero < 9 then
                    LastFamilyDiscrepancy:= last_zero;
                end;
            end;
          if search_direction then
            ROM[rom_byte_number] := ROM[rom_byte_number] or rom_byte_mask
          else
            ROM[rom_byte_number] := ROM[rom_byte_number] and not rom_byte_mask;

          write_bit(search_direction);

          id_bit_number:=id_bit_number + 1;
          rom_byte_mask:= rom_byte_mask shl 1;

          if (rom_byte_mask = 0) then
            begin
              rom_byte_number:=rom_byte_number+1;
              rom_byte_mask:=1;
            end;
        end;
    until rom_byte_number >= 8;
    if id_bit_number >= 65 then
      begin
        LastDiscrepancy := last_zero;
        if LastDiscrepancy = 0 then
          LastDeviceFlag:=true;
        search_result := true;
      end;
  end;
  if not search_result or (ROM[0] = 0) then
    begin
      LastDiscrepancy:=0;
      LastDeviceFlag:=false;
      LastFamilyDiscrepancy:=0;
      search_result:=false;
    end else
    for i := 0 to 7 do newAddr[i] := ROM[i];
    result := search_result;
end;

function TOneWire.crc8(const addr: pbyte; len: UInt8): UInt8;
var i: byte;
    crc: byte = 0;
    p, p2: pointer;
begin
 for i := 0 to len - 1 do
   begin
     crc := PByte(addr+i)^ xor crc;
     p := @dsrc2x16_table;
     inc(p, (crc and $0f));
     p2 := @dsrc2x16_table;
     inc(p2, 16 + byte(((crc shr 4) and $0f)));
     {$IfDef CPUAVR}
     crc := progmemByte(p) xor progmemByte(p2);
     {$EndIf}
   end;
  result := crc;
end;


end.


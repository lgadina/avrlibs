unit avrutils;

{$mode ObjFPC}{$H+}
{$ModeSwitch advancedrecords}

interface

type

  { TAvrUtil }

  TAvrUtil = record
  private
  public
    function getCpuFrequency: dword;
    function ticksOnMs: dword;
  end;

var AvrUtil: TAvrUtil;

implementation
{$IfDef CPUAVR}
uses intrinsics;
{$EndIf}

{ TAvrUtil }


function TAvrUtil.getCpuFrequency: dword;
begin
  Result := F_CPU;
end;

function TAvrUtil.ticksOnMs: dword;
begin
  result := F_CPU div 1024;
end;

end.


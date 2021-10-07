unit uart;

{$mode ObjFPC}{$H+}
{$ModeSwitch advancedrecords}

interface

type

    { TUART }

    TUART = record
    public
      procedure &begin(ABaud: DWord);
    end;

implementation

{ TUART }

procedure TUART.&begin(ABaud: DWord);
begin

end;

end.


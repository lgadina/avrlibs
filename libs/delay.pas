unit delay;

{$define FPC_HAS_MUL}
{$Optimization REGVAR}

interface

function _calc_usw(us: longint): word; inline;

procedure delay_us(ticks: word); inline;
procedure delay_usl(ticks: word);
implementation

procedure delay_us(ticks: word); inline;
begin
  repeat
    dec(ticks);
  until ticks = 0;
end;

procedure delay_usl(ticks: word);
begin
  delay_us(ticks);
end;

function _calc_usw(us: longint): word; inline;
begin
  result := (longint(us * 1000) div longint(6000 div (F_CPU div 1000000))) - 3;
end;

end.

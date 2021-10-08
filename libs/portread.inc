  case Byte(T) of
   0..7: result := PIND and (1 shl t) <> 0;
   8..13: result := PINB and (1 shl (t-8)) <> 0;
   14..20: result := PINC and (1 shl (t-14)) <> 0;
  end;

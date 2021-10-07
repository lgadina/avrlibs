  if AValue then
    case byte(T) of
      0..7: PORTD := PORTD or (1 shl T);
      8..13: PORTB := PORTB or (1 shl (T - 8));
      14..20: PORTC := PORTC or (1 shl (T-14));
    end
  else
    case byte(T) of
     0..7: PORTD := PORTD and not (1 shl T);
     8..13: PORTB := PORTB and not (1 shl (T - 8));
     14..20: PORTC := PORTC and not (1 shl (T-14));
    end;

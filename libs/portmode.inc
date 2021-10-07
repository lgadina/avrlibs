  case Byte(T) of
   0..7: if AMode < pmOutput then begin
            DDRD := DDRD and not (1 shl T);
            if AMode = pmPullUp then
               PORTD := PORTD or (1 shl T)
            else
               PORTD := PORTD and not (1 shl T);
           end else
            DDRD := DDRD or (1 shl T);
   8..13: if AMode < pmOutput then begin
             DDRB := DDRB and not (1 shl (T-8));
             if AMode = pmPullUp then
                PORTB := PORTB or (1 shl (T-8))
             else
                PORTB := PORTB and not (1 shl (T-8));
             end else
                 DDRB := DDRB or (1 shl (T-8));
   14..20: if AMode < pmOutput then begin
            DDRC := DDRC and not (1 shl (T-14));
            if AMode = pmPullUp then
              PORTC := PORTC or (1 shl (T-14))
            else
              PORTC := PORTC and not (1 shl (T-14));
           end else
            DDRC := DDRC or (1 shl (T-14));
  end; 
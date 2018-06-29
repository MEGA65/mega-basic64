
MUSIC_TOGGLE poke 1023, (peek(1023) or 2 ) - (peek(1023) and 2): if peek(1023)<2 goto RINGTONE_OFF
return

RINGTONE_ON poke 1023,1: return

' Stop music play routine, and turn off volume
RINGTONE_OFF poke 1023,peek (1023) and 254: poke 54296,0: return


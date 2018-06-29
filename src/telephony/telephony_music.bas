MUSIC_TOGGLE if peek(1023) goto MUSIC_OFF
' Fall through to MUSIC_ON

MUSIC_ON poke 1023,1: return

' Stop music play routine, and turn off volume
MUSIC_OFF poke 1023,0: poke 54296,0: return


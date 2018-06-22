' Setup a sprite that is used for overlaying on buttons when they are pressed to make it obvious.
SETUP_PRESS_SPRITE rem
' We want 32x24 pixels.  Easiest way is to have 16x12 with X and Y expansion enabled.
' Put the sprite data at $0380-$03BF, i.e., in the cassette buffer.
' Setup the sprite data
for i = 0 to 12: poke 896 + i*3,255: poke 897 + i*3,255: poke 898 + i*3,0:next
for i = 13 to 21: poke 896 + i*3,0: poke 897 + i*3,0: poke 898 + i*3,0:next
' We will draw the sprite as #7 using bitplane-modify-mode, so that it will add 128
' to the palette colour.
' Enable bitplane mode for sprite 7
poke 53323,peek(53323) or 128
' and make it use the correct palette when modified
poke 53360,48
' Enable sprite 7
poke 53269,128
' X expand sprite 7
poke 53277,128
' Y expand sprite 7
poke 53271,128
' Set sprite data source to $0380 ($380/$40 = 14)
poke 2047,14
' point the sprite data pointers to 2040
poke 53356,248:poke 53357,7:poke 53358,0
' Set upper 128 colours to be rearrangements of the lower 128
r=53248+256:g=r+256:b=r+256
for i = 0 to 127:poke b+128+i,peek(r) or peek(g):poke g+128,peek(g): poke r+128,peek(r):next
return
' Move sprite 7 to row sx, column sy
MOVE_SPRITE_TO_ROW_COLUMN rem
poke 53269,0: 'hide before redrawing, to avoid tears
poke 53263,yy*8+50
poke 53262,(xx*8+24) and 255
poke 53264,0: if (xx*8+24) > 255 then poke 53264,128
' Enable sprite 7
poke 53269,128
return
HIDE_SPRITE poke 53269,0: return
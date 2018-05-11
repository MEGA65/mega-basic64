01 poke 53281,0: poke 53280,1: rem "screen and border colour"
02 poke 0,65: poke 53248+111,128: rem "50mhz cpu and 60hz display"

10 i=1: if i=1 then print"": canvas 1 stamp on canvas 0 at 1,1: rem "works as expected"
20 i=1: if i=1 then gosub 100
99 end
100 canvas 1 stamp on canvas 0 at 10,10: return


10 poke53281,0:poke53280,0: rem screen and border colour
20 poke0,65:poke53248+111,128: rem 50mhz and 60hz display
20 print chr$(147);:rem clear screen
100 forx=1to3:fory=1to3
110 canvas x+(y-1)*3+1 stamp on canvas 0 at x*5-2,y*4+1
120 next y,x
130 canvas 11 stamp on canvas 0 at 3,17
140 canvas 1 stamp on canvas 0 at 8,17
150 canvas 12 stamp on canvas 0 at 13,17

160 canvas 11 stamp on canvas 0 at 3,21
170 canvas 1 stamp on canvas 0 at 8,21
180 canvas 12 stamp on canvas 0 at 13,21

190 print "{yel}UCCCCCCCCCCCCCCCCCCI"
200 print "B                  B"
210 print "B                  B"
220 print "B                  B"
230 print "JCCCCCCCCCCCCCCCCCCK"



999 goto 999

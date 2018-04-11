10 poke 53281,0: poke 53280,1: rem "screen and border colour"
20 poke 0,65: poke 53248+111,128: rem "50mhz cpu and 60hz display"
30 print chr$(147);: rem "clear screen"

100 for x=1 to 3: for y=1 to 3: rem
110 canvas x+(y-1)*3+1 stamp on canvas 0 at x*5-4,y*4+1: rem "1 to 9"
120 next y,x

130 canvas 11 stamp on canvas 0 at 1,17: rem "#"
140 canvas 1 stamp on canvas 0 at 6,17: rem "0"
150 canvas 12 stamp on canvas 0 at 11,17: rem "*"

160 canvas 18 stamp on canvas 0 at 1,21: rem "greephone"
170 canvas 15 stamp on canvas 0 at 6,21: rem "+"
180 canvas 17 stamp on canvas 0 at 11,21: rem "backspace"

190 canvas 14 stamp on canvas 0 at 16,9: rem "-"
191 canvas 13 stamp on canvas 0 at 16,13: rem "divide"
192 canvas 16 stamp on canvas 0 at 16,17: rem "="

200 print "{yel}";
210 print "UCCCCCCCCCCCCCCCCCCI"
220 print "B                  B"
230 print "B                  B"
240 print "B                  B"
250 print "JCCCCCCCCCCCCCCCCCCK"


999 goto 999

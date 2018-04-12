10 poke 53281,0: poke 53280,1: rem "screen and border colour"
20 poke 0,65: poke 53248+111,128: rem "50mhz cpu and 60hz display"
30 print chr$(147);: rem "clear screen"

100 for x=1 to 3: for y=1 to 3
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


1000 rem "read input chars and update string (phone number)"
1005 nb$=""
1010 u$="": get u$: if u$="" goto 1010
1020 if u$<>chr$(20) and len(nb$)>=18 goto 1010: rem "limit length is 18"
1030 if u$="0" or u$="1" or u$="2" or u$="3" or u$="4" or u$="5" or u$="6" or u$="7" or u$="8" or u$="9" or u$="+" or u$="*" or u$="#" then nb$=nb$+u$: gosub 1090
1035 if u$="-" or u$="/" or u$="=" or u$=chr$(13) then gosub 1090: rem "these characters don't update the string (for now)"
1040 if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): gosub 1090: rem "remove a character, but only if there's at least one"
1050 goto 1010

1090 rem "screen update subroutine"
1095 gosub 1100: gosub 1200: rem "calls both text and tiles update subroutines"
1099 return

1100 rem "screen text update"
1110 print chr$(147);
1120 print "{yel}";
1130 print "UCCCCCCCCCCCCCCCCCCI"
1140 print "B                  B"
1150 print "B";
1152 print nb$;
1154 for j=1 to 18-len(nb$): if len(nb$)<18 then print " ";: next j: rem "special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space"
1156 print "B"
1160 print "B                  B"
1170 print "JCCCCCCCCCCCCCCCCCCK"
1199 return

1200 rem "screen tiles update"
1210 for x=1 to 3: for y=1 to 3
1212 if val(u$)=x+(y-1)*3 then gosub 1312 
1214 next y,x
1220 if u$="#" then gosub 1320
1222 if u$="0" then gosub 1322
1224 if u$="*" then gosub 1324
1230 if u$=chr$(13) then gosub 1330
1232 if u$="+" then gosub 1332
1234 if u$=chr$(20) then gosub 1334
1240 if u$="-" then gosub 1340
1242 if u$="/" then gosub 1342
1244 if u$="=" then gosub 1344
1299 return

1312 canvas x+(y-1)*3+1+20 stamp on canvas 0 at x*5-4,y*4+1: return: rem "1 to 9 (pressed)"
1320 canvas 11+20 stamp on canvas 0 at 1,17: return: rem "# (pressed)"
1322 canvas 1+20 stamp on canvas 0 at 6,17: return: rem "0 (pressed)"
1324 canvas 12+20 stamp on canvas 0 at 11,17: return: rem "* (pressed)"
1330 canvas 18+20 stamp on canvas 0 at 1,21: return: rem "greephone (pressed)"
1332 canvas 15+20 stamp on canvas 0 at 6,21: return: rem "+ (pressed)"
1334 canvas 17+20 stamp on canvas 0 at 11,21: return: rem "backspace (pressed)"
1340 canvas 14+20 stamp on canvas 0 at 16,9: return: rem "- (pressed)"
1342 canvas 13+20 stamp on canvas 0 at 16,13: return: rem "divide (pressed)"
1344 canvas 16+20 stamp on canvas 0 at 16,17: return: rem "= (pressed)"

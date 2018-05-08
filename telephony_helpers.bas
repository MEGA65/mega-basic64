GOTO_LN rem "=== goto X subroutine ==="
rem "goes to line ln, if ln>0"
ln$=str$(ln): if ln<=0 then return
for i=0 to 5: poke ja+i,32:next: rem "first rub out with spaces in case line number is short"
for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
if ln>0 then gosub,00000: rem "gosub to line ln"
poke ja,44: rem "put the comma back in case we want to run again"
return

WRITE_STRING_TO_MODEM rem "=== send to modem ==="
rem "send string in s$ to modem"
for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
return

WAIT_FOR_KEY_PRESS rem "=== read from keyboard ==="
rem "receive one non-empty char from keyboard"
WFKP_LOOP u$="": get u$: if u$="" goto WFKP_LOOP
return

MOVE_CURSOR_XX_YY rem "=== move the cursor to position xx,yy ==="
print "{home}";
if xx>0 then for ii=1 to xx: print "{rght}";: next ii
if yy>0 then for jj=1 to yy: print "{down}";: next jj
return

DRAW_BOX rem
# "DRAW_BOX"
# "   Draws a w*h box with rounded corners at position x,y"
# "arguments"
# "   w: width of the box, frame included (w>=3)"
# "   h: width of the box, frame included (h>=3)"
# "   x: horizontal position of the upper-left corner (0<=x<=39)"
# "   y: vertical position of the upper-left corner (0<=y<=24)"
# "   r(): array of rows' index to be printed as lines [0:24]"
# "returns"
# "   none"
if w<3 or h<3 then return
xx=x: yy=y: gosub MOVE_CURSOR_XX_YY
print "U";: for i=1 to w-2: print "C";: next i: print "I";
for i=1 to h-2
xx=x: yy=y+i: gosub MOVE_CURSOR_XX_YY
if r(i)=0 then print "B";: for j=1 to w-2: print "{rght}";: next j: print "B";
if r(i)=1 then print chr$(171);: for j=1 to w-2: print "C";: next j: print chr$(179);
r(i)=0: next i
xx=x: yy=y+h-1: gosub MOVE_CURSOR_XX_YY
print "J";: for i=1 to w-2: print "C";: next i: c=peek(646): poke 55296+(y+h-1)*40+x+w-1,c: poke 1024+(y+h-1)*40+x+w-1,75
# "we poke the last character to the screen RAM (1024) and the color to the color RAM (55296), in case it's in the lower-right-hand corner, to avoid a CR/LF"
print "{home}"
return

DRAW_HORIZONTAL_LINE rem
# "DRAW_LINE"
# "   Draws a horizontal line of width w, with T-shaped sides at row r (from position x,y)"
# "arguments"
# "   w: width of the line, sides included (w>=3)"
# "   r: index of the row on which to print the line"
# "   x: horizontal position of the upper-left corner (0<=x<=39)"
# "   y: vertical position of the upper-left corner (0<=y<=24)"
# "returns"
# "   none"
if w<3 then return
xx=x: yy=y+r: gosub MOVE_CURSOR_XX_YY
print chr$(171);: for j=1 to w-2: print "C";: next j: print chr$(179);
return


BATTERY_UPDATE rem "=== update the battery level ==="
if btp>=0 and btp <=5 then bl%=0
if btp>5 and btp <=15 then bl%=1
if btp>15 and btp <=25 then bl%=2
if btp>25 and btp <=35 then bl%=3
if btp>35 and btp <=45 then bl%=4
if btp>45 and btp <=55 then bl%=5
if btp>55 and btp <=65 then bl%=6
if btp>65 and btp <=75 then bl%=7
if btp>75 and btp <=85 then bl%=8
if btp>85 and btp <=95 then bl%=9
if btp>95 and btp <=100 then bl%=10
return


rem "### switch to SCREEN ###"
rem "change the current screen"
rem "it switches graphics/text mode only if necessary"
rem "it triggers an initial update of the screen"

SWITCH_TO_SCREEN_0 rem "=== switch to screen 0 (debug) ==="
sc=0
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_0
return

SWITCH_TO_SCREEN_1 rem "=== switch to screen 1 ==="
sc=1
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_1: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_2 rem "=== switch to screen 2 ==="
sc=2
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_2: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_3 rem "=== switch to screen 3 ==="
sc=3
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_3: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_4 rem "=== switch to screen 4 ==="
sc=4
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_4: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_CONTACT rem "=== switch to screen CONTACT ==="
sc=5
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_CONTACT: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_CALL rem
# "=== switch to screen CALL ==="
sc=6
gosub SWITCH_SCREEN_CLEANUP
gosub DRAW_SCREEN_CALL: rem "trigger initial screen update"
return

SWITCH_SCREEN_CLEANUP rem
u$=""
print "{clr}";: canvas 0 clr: rem "clear screen"
return

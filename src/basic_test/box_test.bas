BEGIN rem
print "{clr}";"{wht}"
x=0:y=5:w=36:h=20: gosub DRAW_BOX
r=2: gosub DRAW_HORIZONTAL_LINE
r=15: gosub DRAW_HORIZONTAL_LINE
goto BEGIN


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
# "returns"
# "   none"
if w<3 or h<3 then return
xx=x: yy=y: gosub MOVE_CURSOR_XX_YY
print "U";: for i=1 to w-2: print "C";: next i: print "I";
for i=1 to h-2
xx=x: yy=y+i: gosub MOVE_CURSOR_XX_YY
print "B";: for j=1 to w-2: print " ";: next j: print "B";
next i
xx=x: yy=y+h-1: gosub MOVE_CURSOR_XX_YY
print "J";: for i=1 to w-2: print "C";: next i: print "K";
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

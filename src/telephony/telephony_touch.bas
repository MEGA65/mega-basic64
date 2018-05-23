' Scan the touch screen for the dialer
POLL_TOUCH_DIALER rem
' We trigger touches on release, so we need to watch
' for a release following a touch
te=(te*2+(peek(54960) and 1)) and 3
if te<>2 then return

' Get x,y coordinate of touch event
tx=peek(54969) or ((peek(54971) and 3)*256)
ty=peek(54970) or ((peek(54971) and 240)*16)
' convert to approximate row, column
c1=int((tx-54)/16)
r1=int((ty-80)/16)

' Debug display of touch info
' print "{home}";c1;",";r1;"   "

' First row of buttons
if r1>4 and r1<8 and c1>0 and c1<5 then u$="1"
if r1>4 and r1<8 and c1>4 and c1<9 then u$="2"
if r1>4 and r1<8 and c1>8 and c1<13  then u$="3"
if r1>4 and r1<8 and c1>12 and c1<18  then u$=""   ' switch active sim

' Second row of buttons
if r1>8 and r1<12 and c1>0 and c1<5 then u$="4"
if r1>8 and r1<12 and c1>4 and c1<9 then u$="5"
if r1>8 and r1<12 and c1>8 and c1<13  then u$="6"
if r1>8 and r1<12 and c1>12 and c1<18  then u$="-"

' Third row of buttons
if r1>12 and r1<16 and c1>0 and c1<5 then u$="7"
if r1>12 and r1<16 and c1>4 and c1<9 then u$="8"
if r1>12 and r1<16 and c1>8 and c1<13  then u$="9"
if r1>12 and r1<16 and c1>12 and c1<18  then u$="/"

' Fourth row of buttons
if r1>16 and r1<20 and c1>0 and c1<5 then u$="#"
if r1>16 and r1<20 and c1>4 and c1<9 then u$="0"
if r1>16 and r1<20 and c1>8 and c1<13  then u$="*"
if r1>16 and r1<20 and c1>12 and c1<18  then u$="="

' Fifth row of buttons
if r1>20 and r1<25 and c1>0 and c1<5 then u$=chr$(13)
if r1>20 and r1<25 and c1>4 and c1<9 then u$="+"
if r1>20 and r1<25 and c1>8 and c1<13  then u$=chr$(20)
if r1>20 and r1<25 and c1>12 and c1<18  then u$="@"

' Disable touch entry until released
if (peek(54960) and 1)=1 then te=0:return
return
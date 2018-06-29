' Convert raw touch position to row,column in c1,r1
' Get x,y coordinate of touch event ' convert to approximate row, column ' Debug display of touch info 'print "{home}";c1;",";r1;"   "
TOUCH_TO_ROW_COLUMN tx=peek(54969) or ((peek(54971) and 3)*256):ty=peek(54970) or ((peek(54971) and 240)*16):c1=int((tx-54)/16):r1=int((ty-120)/16):return

' Check for a touch-release event ' We trigger touches on release, so we need to watch ' for a release following a touch
TOUCH_CHECK_FOR_RELEASE te=(te*2+(peek(54960) and 1)) and 3:return

' Scan the touch screen for call dialing, answering and in-call
POLL_TOUCH_CALL_ACTIVE rem
POLL_TOUCH_CALL_INCOMING rem
POLL_TOUCH_CALL_DIALING rem
gosub TOUCH_CHECK_FOR_RELEASE
if te<>2 then return
gosub TOUCH_TO_ROW_COLUMN
' So far the touch scans for these modes are all common, so
' we save memory by having a single handler, until such time
' as we need to split it up.
'print "{home}{down}"r1;c1
if r1>6 and r1<10 and c1>-2 and c1<6 then u$="a"
if r1>10 and r1<14 and c1>-2 and c1<6 then u$="h"
return

' Scan the touch screen when displaying a contact
POLL_TOUCH_CONTACT rem
gosub TOUCH_CHECK_FOR_RELEASE
if te<>2 then return
gosub TOUCH_TO_ROW_COLUMN
'print "{home}{down}        {left}{left}{left}{left}{left}{left}{left}{left}"r1;c1
if r1>6 and r1<10 and c1>-2 and c1<6 then u$=c13$
return

' Scan the touch screen when displaying the contact edit screen
POLL_TOUCH_CONTACT_EDIT rem
gosub TOUCH_CHECK_FOR_RELEASE
'if te<>2 then return
'gosub TOUCH_TO_ROW_COLUMN
return

' Scan the touch screen for the dialer
POLL_TOUCH_DIALER rem
gosub TOUCH_CHECK_FOR_RELEASE
if te<>2 then return

gosub TOUCH_TO_ROW_COLUMN

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
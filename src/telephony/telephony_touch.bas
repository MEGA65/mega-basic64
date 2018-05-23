' Scan the touch screen for the dialer
POLL_TOUCH_DIALER rem
if (peek(54960) and 1)=0 then te=1:return
if te=0 or (peek(54960) and 1)=0 then return

' Get x,y coordinate of touch event
tx=peek(54969) or ((peek(54971) and 3)*256)
ty=peek(54970) or ((peek(54971) and 240)*16)
' convert to approximate row, column
c1=int((tx-54)/16)
r1=int((ty-80)/16)
print "{home}";c1;",";r1;"      ";
if r1>4 and r1<8 and c1>0 and c1<6 then tk$="1"
if r1>4 and r1<8 and c1>5 and c1<11 then tk$="2"
if r1>4 and r1<8 and c1>11 and c1<16 then tk$="3"

' Disable touch entry until released
if (peek(54960) and 1)=1 then te=0:return
return
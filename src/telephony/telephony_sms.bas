SMS_GET_FIRST_EMPTY_INDEX rem
'Get the first empty index of the SMS storage in RAM
'   if no empty index, return 0
k=0
for i=1 to slngth%
if sindex%(i)=0 then k=i: return
next i
return

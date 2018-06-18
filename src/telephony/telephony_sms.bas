SMS_GET_FIRST_EMPTY_INDEX rem
'Get the first empty index of the SMS storage in RAM
'   if no empty index, return 0
k=0
for i=1 to slngth%
if sidex%(i)=0 then k=i: return
next i
return

EMPTY_SMS rem
' Delete all SMS from RAM
for i=1 to slngth%
sidex%(i)=0: stxt$(i)="": snumber$(i)="": sd$(i)="": satus$(i)=""
next i
return

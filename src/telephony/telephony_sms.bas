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
sidex%(i)=0: stxt$(i)="": snumber$(i)="": sd$(i)="": satus%(i)=-1
next i
sidex%=0
return

QUERY_ALL_SMS rem
'poke 0,64 'for debugging only, far too slow!
'db=4: gosub SWITCH_TO_SCREEN_DEBUG
gosub EMPTY_SMS
sq=1: satus$="{yel}fetching SMS{elipsis}"
gosub QAS_NEXT
return

QAS_NEXT rem
if sidex%<sused% then goto QAS_QUERY 'we didn't query all SMS, so we query next one
jt%(100)=0: gosub QAS_ALL_SMS_LOADED: goto QAS_END 'we queried all SMS, so we go to ALL_SMS_LOADED
'--- Query next SMS ---
QAS_QUERY rem
sidex%=sidex%+1 'next SMS has index sidex%+1
jt%(100)= QAS_CALLBACK: k=sidex%: gosub SEND_AT+CMGR 'set callback and send message
QAS_END return

QAS_CALLBACK rem
' modem sent a response to at+cmgr=<i>
if db>=4 then print "SMS";sidex%;"/";sused%;"..."
if merror=0 then rem '1 SMS was successfully retrieved
if merror=1 then merror=0: serror=serror+1 'error getting 1 SMS
gosub QAS_NEXT
return

QAS_ALL_SMS_LOADED rem
if db>=4 then print "All SMS queried!"
if serror>0 then sq=2: satus$="{red}some not fetched!" 'at least 1 error
if serror=0 then sq=2: satus$="{grn}successfully fetched" 'SMS queried and all received
serror=0
'gosub WAIT_FOR_KEY_PRESS
'poke 0,65
'db=0: gosub SWITCH_TO_LAST_SCREEN
return

GET_STATUS_FROM_STRING rem
'Get SMS status integer from status string
'Arguments:
'  s$: the status string, with quotes
'Returns:
'  k: the status integer [0-4]
k=-1
for i=0 to 4:
if s$=sus$(i) then k=i: return
next i
return

GET_SMS_FROM_CONTACT rem
'Get the SMS from a particular contact
'Arguments:
'  s$: the number of the contact to get the SMS from
'Returns:
'  
return

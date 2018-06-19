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
sidex%=0
return

QUERY_SMS_FROM_CONTACT rem
'poke 0,64 'for debugging only, far too slow!
'db=4: gosub SWITCH_TO_SCREEN_DEBUG
gosub EMPTY_SMS
gosub QSFC_NEXT
return

QSFC_NEXT rem
if sidex%<sused% then goto QSFC_QUERY 'we didn't query all SMS, so we query next one
jt%(100)=0: gosub QSFC_ALL_SMS_LOADED: goto QSFC_END 'we queried all SMS, so we go to ALL_SMS_LOADED
'--- Query next SMS ---
QSFC_QUERY rem
sidex%=sidex%+1 'next SMS has index sidex%+1
jt%(100)= QSFC_CALLBACK: k=sidex%: gosub SEND_AT+CMGR 'set callback and send message
QSFC_END return

QSFC_CALLBACK rem
' modem sent a response to at+cmgr=<i>
if db>=4 then print "SMS";sidex%;"/";sused%;"..."
if merror=0 then rem '1 SMS was successfully retrieved
if merror=1 then merror=0: serror=serror+1 'error getting 1 SMS
gosub QSFC_NEXT
return

QSFC_ALL_SMS_LOADED rem
if db>=4 then print "All SMS queried!"
if serror>0 then sq=0: satus$="{red}error!" 'at least 1 error, we set the flag back to not queried
if serror=0 then sr%=cselected%: sq=2: satus$="{grn}success" 'SMS queried and all received
serror=0
'gosub WAIT_FOR_KEY_PRESS
'poke 0,65
'db=0: gosub SWITCH_TO_LAST_SCREEN
return

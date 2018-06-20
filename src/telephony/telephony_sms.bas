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
gosub EMPTY_SMS_PANE
return

EMPTY_CONTACT_SMS rem
'Delete the indices of Contact SMS
for i=1 to 100
mpindex(i)=0
next i
gosub EMPTY_SMS_CONTACT_PANE
mpindex%=0: mxindex%=0: mq=0
return

QUERY_ALL_SMS rem
'poke 0,64 'for debugging only, far too slow!
'db=4: gosub SWITCH_TO_SCREEN_DEBUG
gosub EMPTY_SMS
sq=1: satus$="{yel}fetching SMS{elipsis}"
sx=1 'enable cache mechanism for further SMS
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
if merror=0 then gosub SMS_TO_SMS_PANE '1 SMS was successfully retrieved, update SMS pane
if merror=1 then merror=0: serror=serror+1 'error getting 1 SMS
gosub QAS_NEXT
return

QAS_ALL_SMS_LOADED rem
if db>=4 then print "All SMS queried!"
if serror>0 then sq=2: satus$="{red}some not fetched!" 'at least 1 error
if serror=0 then sq=2: satus$="{grn}successfully fetched" 'SMS queried and all received
serror=0
sx=0 'disable cache mechanism for further SMS
gosub SMS_TO_SMS_PANE 'update SMS pane
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
'  r$: the number of the contact from whom we want the SMS
'Returns:
'  no return (fills the mpindex() array and query SMS missing from cache
'db=4: gosub SWITCH_TO_SCREEN_DEBUG
'poke 0,64 'for debugging only
if db>=4 then print "Get SMS from contact "+r$
'--- Get Contact's SMS indices ---
'We first get all the indices of the contact's SMS to fill pindex()
kk=1
for ii=sused% to 1 step -1
if db>=4 then print "SMS";ii ';snumber$(ii);left$(stxt$(ii),5)
if sidex%(ii)<>0 then goto GSFC_COMPARE
if db>=4 then print " SMS";ii;"doesn't exist"
goto GSFC_NEXT 'SMS doesn't exist --> next
GSFC_COMPARE s$=snumber$(ii) 'get the number of current SMS
gosub COMPARE_PHONE_NUMBERS: if b=1 then goto GSFC_CONTACT 'SMS exists and its number is the same as selected contact
if db>=4 then print " Not the same number"
goto GSFC_NEXT 'SMS doesn't exist or its number is not the same --> next
GSFC_CONTACT mpindex(kk)=ii 'add the SMS index to the array of the current contact's SMS
if db>=4 then print " Same number, add SMS to mpindex!"
kk=kk+1 'increment the counter
GSFC_NEXT rem
if db>=4 then gosub WAIT_FOR_KEY_PRESS 'debug
next ii
'Once here, we've gone through all the SMS
mxindex%=kk-1 'kk counter is too high of 1 (incremented after filling an index)
if db>=4 then print "SMS indices of selected contact ("+r$+"):";: for i=1 to mxindex%: print mpindex(i);",";: next i: print chr$(13);
'--- Query not-cached Contact's SMS ---
'We now need to go through the Contact's SMS and query those not in cache
mq=1: matus$="{yel}fetching SMS{elipsis}"
sx=0 'disable cache mechanism for further SMS
mpindex%=0
gosub GSFC_STEP
return

GSFC_STEP rem
mpindex%=mpindex%+1 'increment mpindex% at the beginning of STEP --> start at mpindex%=0
if mpindex%>mxindex% then jt%(100)=0: gosub GSFC_ALL_SMS_LOADED: goto GSFC_END 'we handled all SMS
sidex%=mpindex(mpindex%)
if stxt$(sidex%)<>"" then goto GSFC_IN_CACHE
goto GSFC_QUERY 'the SMS is not in cache, we need to query it
'--- SMS already in cache ---
GSFC_IN_CACHE rem
if db>=4 then print "SMS";sidex%;": in-cache"
goto GSFC_STEP 'this SMS is already in cache, go to next step
'--- Query next SMS ---
GSFC_QUERY rem
if db>=4 then print "SMS";sidex%;": query"
jt%(100)= GSFC_CALLBACK: k=sidex%: gosub SEND_AT+CMGR 'set callback and send message
GSFC_END return

GSFC_CALLBACK rem
' modem sent a response to at+cmgr=<i>
if db>=4 then print "Contact SMS";mpindex%;"/";mxindex%;"..."
if merror=0 then gosub SMS_TO_SMS_CONTACT_PANE '1 SMS was successfully retrieved, update SMS Contact pane
if merror=1 then merror=0: serror=serror+1 'error getting 1 SMS
if db>=4 then gosub WAIT_FOR_KEY_PRESS 'debug
gosub GSFC_STEP 'go to next step
return

GSFC_ALL_SMS_LOADED rem
if db>=4 then print "All Contact SMS queried!"
if serror>0 then matus$="{red}"+str$(serror)+" errors!" 'at least 1 error
if serror=0 then matus$="{grn}success" 'SMS queried and all received
mq=2 'Current contact's SMS have been queried
serror=0
gosub SMS_TO_SMS_CONTACT_PANE 'update Contact SMS pane
sr%=cselected%
if db>=4 then gosub WAIT_FOR_KEY_PRESS
poke 0,65
'db=0: gosub SWITCH_TO_LAST_SCREEN
return



SMS_TO_SMS_PANE rem
'Fill the SMS pane with in-RAM SMS entries (from highest index to lowest)
'Only entries in cache (i.e. with their body in memory) are displayed
kk=1
for ii=sused% to 1 step -1
if kk>smaxpane% then return 'don't fill more than smaxpane% (18) lines
if sidex%(ii)<>0 and stxt$(ii)<>"" then s$=snumber$(ii)+": "+stxt$(ii): l=38: gosub TRIM_STRING_SPACES: gosub RM_STRING_CRLF: spt$(kk)=s$: spi%(kk)=ii: kk=kk+1 'Remove <CR><LF> after having trimmed the string. It should speed up things a bit, since the RM_STRING_CRLF subroutine will go through 38 chars max instead of the whole string
next ii
return

EMPTY_SMS_PANE rem
'Empty the SMS pane
for ii=1 to smaxpane%
spt$(ii)="": spi%(ii)=0
next ii
return

SMS_TO_SMS_CONTACT_PANE rem
'Fill the SMS Contact pane with in-RAM SMS entries, iterating on the array of SMS belonging to the current contact
kk=1
for ii=1 to mxindex% 'no more than mxindex% SMS for this contact
if kk>mmaxpane% then return 'don't fill more than mmaxpane% (12) lines
if mpindex(ii)<>0 then s$=stxt$(mpindex(ii)):l=34: gosub TRIM_STRING_SPACES: gosub RM_STRING_CRLF: mpt$(kk)=s$: mpi%(kk)=mpindex(ii): kk=kk+1
next ii
return

EMPTY_SMS_CONTACT_PANE rem
'Empty the Contact SMS pane
for ii=1 to mxindex%
mpt$(ii)="": mpi%(ii)=0
next ii
return


SCREEN_HANDLER rem
if sc=0 then gosub DRAW_SCREEN_DEBUG
if sc=1 then gosub HANDLER_SCREEN_DIALLER
if sc=2 then gosub HANDLER_SCREEN_CONTACT
if sc=3 then gosub HANDLER_SCREEN_CALL
if sc=4 then gosub HANDLER_SCREEN_CONTACT_EDIT
return



'### DIALLER screen handler ###
HANDLER_SCREEN_DIALLER rem
'read input chars and update string (phone number)
u$="": get u$
gosub POLL_TOUCH_DIALER

'we trigger a dial tiles update every 1000 loops since last
tmr=tmr-1: if tmr=0 then up=1: su=1 'Request redrawing of dialpad (up), and mark screen as needing redrawing (su)
if u$="" then return
' Run terminal program for debugging modem communications
if u$="t" then up=1: su=1: gosub TERMINAL_PROGRAM: gosub SWITCH_TO_SCREEN_DIALLER
'navigation in contact pane
if u$="{up}" then mdv=centry%: hl%=fn mod(hl%-2)+1: su=1: uc=1 'Redraw contact list
if u$="{down}" then mdv=centry%: hl%=fn mod(hl%)+1: su=1: uc=1 'Redraw contact list
if u$="{rght}" and hl%<>0 then cselected%=cindex%(hl%): su=1: gosub SWITCH_TO_SCREEN_CONTACT
'dialler
'limit length is 18, go to loop start if over it or not enter or backspace
if u$<>chr$(20) and u$<>chr$(13) and len(nb$)>=19 then return
if (u$>="0" and u$<="9") or u$="+" or u$="*" or u$="#" or u$="a" or u$="b" or u$="c" or u$="d" then nb$=nb$+u$: u0$=u$: su=1: up=1: ud=1 'request dialpad and number update
'these characters don't update the string (for now)
if u$="-" or u$="/" or u$="=" or u$="@" or u$="<" or u$=">" then  u0$=u$: su=1
'backspace: remove a character, but only if there's at least one
if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): u0$=u$: su=1: up=1: ud=1
'delete char from dialed number. Update dial pad and number display
'enter: call the dialled number
if u$=chr$(13) then  u0$=u$: su=1: dnumber$=nb$: gosub CALL_DIAL: gosub SWITCH_TO_SCREEN_CALL
' XXX - Debug display dialer interface
if u$="z" then su=1: dsata=val(nb$): gosub SWITCH_TO_SCREEN_CALL
return


'### CONTACT screen handler ###
HANDLER_SCREEN_CONTACT rem
'handle user actions
u$="": get u$
gosub POLL_TOUCH_CONTACT
if u$="" then return
if u$=chr$(20) then u0$=u$: gosub SWITCH_TO_SCREEN_DIALLER
if u$=chr$(13) then u0$=u$: dnumber$=pnumber$(cselected%): gosub CALL_DIAL: gosub SWITCH_TO_SCREEN_CALL
if u$="e" then u0$=u$: ctrigger=1: gosub SWITCH_TO_SCREEN_CONTACT_EDIT
return


'### CONTACT_EDIT screen handler ###
HANDLER_SCREEN_CONTACT_EDIT rem
'handle user actions
u$="": get u$
gosub POLL_TOUCH_CONTACT_EDIT
if u$="" then return
if u$=chr$(19) then u0$=u$: gosub SWITCH_TO_LAST_SCREEN
if u$=chr$(13) then u0$=u$: gosub SWITCH_TO_LAST_SCREEN
if u$="{up}" then mdv=2: hl%=fn mod(hl%-2)+1: gosub HS_CONTACT_EDIT_ACTIVE_STRING: su=1 'Redraw field list
if u$="{down}" then mdv=2: hl%=fn mod(hl%)+1: gosub HS_CONTACT_EDIT_ACTIVE_STRING: su=1 'Redraw field list
if u$="{left}" then mdv=len(cfields$(hl%))+1: ul%=fn mod(ul%-2)+1
if u$="{rght}" then mdv=len(cfields$(hl%))+1: ul%=fn mod(ul%)+1
'Modify the selected field
if u$=chr$(20) and ul%>1 then s$=cfields$(hl%): s$=left$(s$, ul%-2)+right$(s$, len(s$)+1-ul%): cfields$(hl%)=s$: ul%=ul%-1
return

HS_CONTACT_EDIT_ACTIVE_STRING ul%=len(cfields$(hl%))+1: return

'### CALL screen handler ###
HANDLER_SCREEN_CALL rem
'general operations
'update the call timer and timer string
dtmr=time-tc
dtmr$=""
thour=int(dtmr/216000)
tmin=int((dtmr-thour)/3600)
tsec=int((dtmr-thour-tmin)/60)
if thour>=0 and thour<=9 then dtmr$=dtmr$+"0"
dtmr$=dtmr$+right$(str$(thour), len(str$(thour))-1)
if tmin>=0 and tmin<=9 then dtmr$=dtmr$+"0"
dtmr$=dtmr$+right$(str$(tmin), len(str$(tmin))-1)
if tsec>=0 and tsec<=9 then dtmr$=dtmr$+"0"
dtmr$=dtmr$+right$(str$(tsec), len(str$(tsec))-1)

'handle user actions
u$="": get u$
if dsta=0 goto HS_CALL_ACTIVE
if dsta=2 or dsta=3 goto HS_CALL_DIALING
if dsta=4 or dsta=5 goto HS_CALL_RINGING
'else, we want to always be able to hangup with H
if u$="h" or u$="H" then  u0$=u$: gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER
return

HS_CALL_ACTIVE rem
'=== Call state: active ===
' Possible actions:
'   h: hang-up call
'   TODO: more (mute, speaker, dialpad...)
'--- Hang-up call (H) ---
gosub POLL_TOUCH_CALL_ACTIVE
if u$="h" or u$="H" then  u0$=u$: gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER: return
return

HS_CALL_DIALING rem
'=== Call state: dialing ===
' Possible actions:
'   h: hang-up call
'   TODO: more (mute, speaker, dialpad...)
gosub POLL_TOUCH_CALL_DIALING
if u$="h" or u$="H" then  u0$=u$: gosub CALL_HANGUP: gosub SWITCH_TO_SCREEN_DIALLER: return
return

HS_CALL_RINGING rem
'=== Call state: ringing ===
' Possible actions:
'   a: answer call
'   r: reject call
'   TODO: more (mute, speaker, dialpad...)
gosub POLL_TOUCH_CALL_INCOMING
if u$="a" or u$="A" then  u0$=u$: su=1: gosub CALL_ANSWER: return
if u$="r" or u$="R" or u$="h" or u$="H" then  u0$=u$: gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER: return
return

return
'### end HANDLER_SCREEN_CALL ###


CALL_DIAL rem
'Dial the number in dnumber$
dactive=1: dia=1
gosub SEND_ATD
return

CALL_ANSWER rem
'Answer an incoming call
gosub SEND_ATA
tc=time
return

CALL_HANGUP rem
'Disconnect existing (current) voice or data call
gosub SEND_ATH
gosub CALL_HANGUP_CLEANUP
return

CALL_HANGUP_ALL rem
'Hang-up all voice call in the state of Active, Waiting and Held
gosub SEND_AT+CHUP
gosub CALL_HANGUP_CLEANUP
return

CALL_HANGUP_CLEANUP rem 'clean up
dactive=0
dsta=-1
cid$=""
dr$="": dnumber$=""
if dia=1 then dia=0
tc=0: dtmr=0: dtmr$="000000"
return

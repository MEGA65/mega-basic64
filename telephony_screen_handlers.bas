"### DIALLER screen handler ###"
HANDLER_SCREEN_DIALLER rem
# "read input chars and update string (phone number)"
if su=1 then gosub DRAW_SCREEN_DIALLER: su=0
u$="": get u$
# "we trigger a screen update every sr loops"
mdv=sr: if fn mod(cnt)=0 then gosub DRAW_SCREEN_DIALLER
# "we trigger a dial tiles update every 1000 loops since last"
tmr=tmr-1: if tmr=0 then gosub DS_DIALLER_DIALPAD: us=1
if u$="" then return
# "navigation in contact pane"
if u$="{up}" then mdv=centry%: hl%=fn mod(hl%-2)+1 : gosub DRAW_SCREEN_DIALLER
if u$="{down}" then mdv=centry%: hl%=fn mod(hl%)+1: gosub DRAW_SCREEN_DIALLER
if u$="{rght}" and hl%<>0 then cselected%=cindex%(hl%): gosub DRAW_SCREEN_DIALLER: gosub SWITCH_TO_SCREEN_CONTACT
# "dialler"
# "limit length is 18, go to loop start if over it or not enter or backspace"
if u$<>chr$(20) and u$<>chr$(13) and len(nb$)>=19 then return
if u$="0" or u$="1" or u$="2" or u$="3" or u$="4" or u$="5" or u$="6" or u$="7" or u$="8" or u$="9" or u$="+" or u$="*" or u$="#" or u$="a" or u$="b" or u$="c" or u$="d" then nb$=nb$+u$: gosub DRAW_SCREEN_DIALLER
# "these characters don't update the string (for now)"
if u$="-" or u$="/" or u$="=" or u$="@" or u$="<" or u$=">" then gosub DRAW_SCREEN_DIALLER
# "backspace: remove a character, but only if there's at least one"
if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): gosub DRAW_SCREEN_DIALLER
# "enter: call the dialled number"
if u$=chr$(13) then gosub DRAW_SCREEN_DIALLER: dnumber$=nb$: gosub CALL_DIAL: gosub SWITCH_TO_SCREEN_CALL
return


"### CONTACT screen handler ###"
HANDLER_SCREEN_CONTACT rem
mdv=sr: if fn mod(cnt)=0 then gosub DRAW_SCREEN_CONTACT
# "handle user actions"
u$="": get u$
if u$="" then return
if u$=chr$(20) then gosub SWITCH_TO_SCREEN_DIALLER
if u$=chr$(13) then gosub DRAW_SCREEN_CONTACT: dnumber$=pnumber$(cselected%): gosub CALL_DIAL: gosub SWITCH_TO_SCREEN_CALL
return


"### CALL screen handler ###"
HANDLER_SCREEN_CALL rem
# "general operations"
# "update the call timer and timer string"
dtmr=time-t0
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

# "screen update"
mdv=sr: if fn mod(cnt)=0 then gosub DRAW_SCREEN_CALL
# "handle user actions"
u$="": get u$
if u$="" then return
if dsta=0 goto HS_CALL_ACTIVE
if dsta=2 or dsta=3 goto HS_CALL_DIALING
if dsta=4 or dsta=5 goto HS_CALL_RINGING
# "else, we want to always be able to hangup with H"
if u$="h" or u$="H" then gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER
return

HS_CALL_ACTIVE rem
# "=== Call state: active ==="
# " Possible actions:"
# "   h: hang-up call"
# "   TODO: more (mute, speaker, dialpad...)"
# "--- Hang-up call (H) ---"
if u$="h" or u$="H" then gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER: return
return

HS_CALL_DIALING rem
# "=== Call state: dialing ==="
# " Possible actions:"
# "   h: hang-up call"
# "   TODO: more (mute, speaker, dialpad...)"
if u$="h" or u$="H" then gosub CALL_HANGUP: gosub SWITCH_TO_SCREEN_DIALLER: return
return

HS_CALL_RINGING rem
# "=== Call state: ringing ==="
# " Possible actions:"
# "   a: answer call"
# "   r: reject call"
# "   TODO: more (mute, speaker, dialpad...)"
if u$="a" or u$="A" then gosub CALL_ANSWER: return
if u$="r" or u$="R" or u$="h" or u$="H" then gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER: return
return

return
# "### end HANDLER_SCREEN_CALL ###"


CALL_DIAL rem
# "Dial the number in dnumber$"
dactive=1: dia=1
gosub SEND_ATD
return

CALL_ANSWER rem
# "Answer an incoming call"
gosub SEND_ATA
t0=time
return

CALL_HANGUP rem
# "Disconnect existing (current) voice or data call"
gosub SEND_ATH
gosub CALL_HANGUP_CLEANUP
return

CALL_HANGUP_ALL rem
# "Hang-up all voice call in the state of Active, Waiting and Held"
gosub SEND_AT+CHUP
gosub CALL_HANGUP_CLEANUP
return

CALL_HANGUP_CLEANUP
# "clean up"
dactive=0
dsta=-1
cid$=""
dr$="": dnumber$=""
if dia=1 then dia=0
t0=0: dtmr=0: dtmr$="000000"
return

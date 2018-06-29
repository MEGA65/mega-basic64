SCREEN_HANDLER if sc=0 then gosub HANDLER_SCREEN_DEBUG
if sc=1 then gosub HANDLER_SCREEN_DIALLER
if sc=2 then gosub HANDLER_SCREEN_CONTACT
if sc=3 then gosub HANDLER_SCREEN_CALL
if sc=4 then gosub HANDLER_SCREEN_CONTACT_EDIT
if sc=5 then gosub HANDLER_SCREEN_SMS
return


'keep the ability to hang-up
HANDLER_SCREEN_DEBUG u$="": get u$: if u$="" then return
if u$="H" then gosub CALL_HANGUP_ALL: return
if u$="{home}" then db=0: gosub SWITCH_TO_LAST_SCREEN: return
return


'### DIALLER screen handler ###
'read input chars and update string (phone number)
HANDLER_SCREEN_DIALLER u$="": get u$: gosub POLL_TOUCH_DIALER

'We wait for a short timer to expire after pressing a button, then we hide the sprite that makes
' the button look pressed.
ktmr=ktmr-1: if ktmr<1 then gosub HIDE_SPRITE
if u$="" then return
' Run terminal program for debugging modem communications
if u$="T" then up=1: su=1: gosub TERMINAL_PROGRAM: gosub SWITCH_TO_SCREEN_DIALLER
' O key displays oscilloscope like display
if u$="O" then poke 53280,1: sys 38656: su=1: up=1: uc=1: ud=1
' Toggle music using M
if u$="M" then gosub MUSIC_TOGGLE
' Go to SMS screen
if u$="S" then up=1: su=1: gosub SWITCH_TO_SCREEN_SMS
' Open the new contact screen with dialled number pre-populated
if u$="@" then ctrigger=2: cfields$(2)=nb$: gosub SWITCH_TO_SCREEN_CONTACT_EDIT
'navigation in contact pane
if u$="{up}" then mdv=centry%: hl%=fn mod(hl%-2)+1: su=1: uc=1 'Redraw contact list
if u$="{down}" then mdv=centry%: hl%=fn mod(hl%)+1: su=1: uc=1 'Redraw contact list
if u$="{rght}" and hl%<>0 then cselected%=cindex%(hl%): gosub SWITCH_TO_SCREEN_CONTACT 'Go to contact screen
'limit length is 18, go to loop start if over it or not enter or backspace
if u$<>chr$(20) and u$<>chr$(13) and len(nb$)>=19 then return
if (u$>="0" and u$<="9") or u$="+" or u$="*" or u$="#" or u$="A" or u$="B" or u$="C" or u$="D" then nb$=nb$+u$: u0$=u$: su=1: up=1: ud=1 'request dialpad and number update
'these characters don't update the string (for now)
if u$="-" or u$="/" or u$="=" or u$="<" or u$=">" then  u0$=u$: su=1
'backspace: remove a character, but only if there's at least one
if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): u0$=u$: su=1: up=1: ud=1
'delete char from dialed number. Update dial pad and number display
'enter: call the dialled number
if u$=chr$(13) then  u0$=u$: su=1: dnumber$=nb$: gosub SWITCH_TO_SCREEN_CALL: gosub CALL_DIAL
' XXX - Debug display dialer interface
if u$="Z" then su=1: dsta=val(nb$): gosub SWITCH_TO_SCREEN_CALL
return


'### CONTACT screen handler ###
HANDLER_SCREEN_CONTACT rem
'SMS querying
if sq=2 and mq=0 then r$=pnumber$(cselected%): gosub GET_SMS_FROM_CONTACT
if sq=0 or sq=1 then matus$="{yel}please wait{elipsis}"
'handle user actions
u$="": get u$
gosub POLL_TOUCH_CONTACT
if u$="" then return
if wsms=1 then goto HS_C_WRITE_SMS
goto HS_C_NORMAL

'normal interaction when not writing SMS
HS_C_NORMAL if u$="{home}" then u0$=u$: gosub SWITCH_TO_SCREEN_DIALLER 'HOME: go back to dialler
if u$=c13$ then u0$=u$: dnumber$=pnumber$(cselected%): gosub SWITCH_TO_SCREEN_CALL: gosub CALL_DIAL 'ENTER: call contact
if u$=chr$(135) and sq=2 then r$=pnumber$(cselected%): gosub GET_SMS_FROM_CONTACT 'F5: refresh SMS from contact
if u$="E" then u0$=u$: ctrigger=1: gosub SWITCH_TO_SCREEN_CONTACT_EDIT 'E: edit contact
if u$="N" then u0$=u$: gosub HS_C_BEGIN_WRITING: gosub ERASE_SCREEN: gosub VIRTUAL_KEYBOARD_ENABLE 'N: begin writing SMS
return

'interaction when writing SMS
'Stop writing SMS: HOME
HS_C_WRITE_SMS if u$="{home}" then wsms=0: watus$="": gosub ERASE_SCREEN: gosub VIRTUAL_KEYBOARD_DISABLE: return 'HOME: stop writing SMS
'Send SMS: ENTER / RETURN
if u$=c13$ then gosub HS_C_SEND_SMS: return 'ENTER: send SMS
'Move cursor left and right
if u$="{left}" then mdv=len(wsms$)+1: ul%=fn mod(ul%-2)+1 'move cursor left
if u$="{rght}" then mdv=len(wsms$)+1: ul%=fn mod(ul%)+1 'move cursor right
'Backspace: remove character
if u$=chr$(20) and ul%>1 then s$=wsms$: s$=left$(s$, ul%-2)+right$(s$, len(s$)+1-ul%): wsms$=s$: ul%=ul%-1
'Alphanumeric+ char: insert char in SMS
l=26*3-1: if u$<>"" and ((asc(u$)>=32 and asc(u$)<=95) or (asc(u$)>=193 and asc(u$)<=218)) then s$=wsms$: gosub STRING_INSERT_CHAR: wsms$=s$
return

HS_C_BEGIN_WRITING wsms=1: ul%=len(wsms$)+1: return 'called when going into "write SMS mode"

HS_C_SEND_SMS if len(wsms$)<=0 then watus$="{red}empty message": return 'the message is empty, don't send it
if dd=1 then db=4: gosub SWITCH_TO_SCREEN_DEBUG : poke 0,64 'enable debugging
ni=1 'disable user-interaction
'Send the message
'text of the message
'destination number for the message
'callback subroutine to be called when message sent (or at least response received)
sm$=wsms$: sn$=pnumber$(cselected%): mc= HS_C_SEND_SMS_CALLBACK : gosub SEND_SMS: watus$="{yel}sending SMS{elipsis}": return

're-enable user interaction
HS_C_SEND_SMS_CALLBACK ni=0 
if db>=4 then poke 0,65: db=0: gosub SWITCH_TO_LAST_SCREEN
if merror=1 then merror=0: watus$="{red}error sending SMS": gosub HS_C_BEGIN_WRITING 'modem error, stay on screen
if merror=0 then watus$="{grn}successfully sent": wsms$="": gosub HS_C_BEGIN_WRITING 'modem OK --> SMS sent; erase the SMS field
'TODO: add SMS to cache!!
return


'### CONTACT_EDIT screen handler ###
'check if user interactivity is enabled
HANDLER_SCREEN_CONTACT_EDIT if ni=1 then return
'enable virtual keyboard if it is disabled and a line is selected
gosub VIRTUAL_KEYBOARD_IS_ENABLED: if hl%<> 0 and b=0 then gosub VIRTUAL_KEYBOARD_ENABLE
'handle user actions
u$="": get u$: gosub POLL_TOUCH_CONTACT_EDIT: if u$="{home}" then u0$=u$: gosub HS_CE_CLEANUP: gosub SWITCH_TO_LAST_SCREEN: return 'HOME: go back to screen CONTACT
if u$=c13$ then u0$=u$: gosub HS_CE_SAVE_CONTACT: return
if u$=chr$(133) and cselected%>0 then u0$=u$: gosub HS_CE_DELETE_CONTACT: return 'delete on F1 (only if existing contact, not for new contacts!
if u$="{up}" then mdv=2: hl%=fn mod(hl%-2)+1: gosub HS_CE_ACTIVE_STRING: su=1 'Redraw field list
if u$="{down}" then mdv=2: hl%=fn mod(hl%)+1: gosub HS_CE_ACTIVE_STRING: su=1 'Redraw field list
if u$="{left}" then mdv=len(cfields$(hl%))+1: ul%=fn mod(ul%-2)+1
if u$="{rght}" then mdv=len(cfields$(hl%))+1: ul%=fn mod(ul%)+1
'Modify the selected field
if u$=chr$(20) and hl%>0 and ul%>1 then s$=cfields$(hl%): s$=left$(s$, ul%-2)+right$(s$, len(s$)+1-ul%): cfields$(hl%)=s$: ul%=ul%-1
' We have to cascade the IF statements here, because asc("") gives an error
l=20: if u$<>"" then if hl%>0 and ((asc(u$)>=32 and asc(u$)<=95) or (asc(u$)>=193 and asc(u$)<=218)) then s$=cfields$(hl%): gosub STRING_INSERT_CHAR: cfields$(hl%)=s$
return

'Insert char c$ in string s$, at position ul%
'Arguments:
'  c$: char to insert
'  s$: string in which to insert
'  ul%: position of insertion
'  l: limit length of the string
'Returns:
'  s$: the new string with inserted char
'move cursor flag
STRING_INSERT_CHAR k=0 : c$=u$: gosub PETSCII_TO_ASCII: u$=c$ 'convert the PETSCII keyboard input to ASCII
if len(s$)<l and ul%>=len(s$)+1 then s$=s$+u$: k=1 'if the string is under the limit length, and the cursor is at len+1, just add the char
if ul%<len(s$)+1 then s$=left$(s$, ul%-1)+u$+right$(s$, len(s$)-ul%): k=1 'if not (<=len), replace char at ul%
if k=1 then ul%=ul%+1 'move the cursor one char to right
return

HS_CE_ACTIVE_STRING ul%=len(cfields$(hl%))+1: return

'change status message and disable user interaction
HS_CE_SAVE_CONTACT cstatus$="{grn}saving{elipsis}": ni=1: if cselected%>0 then pindex%=cselected% 'editing existing contact
if cselected%=0 then gosub PHONEBOOK_GET_FIRST_EMPTY_INDEX: pindex%=k 'creating a new contact, we need the first available index
'ask modem to write the edited/created contact to SIM phonebook
jt%(100)= HS_CE_SAVE_CONTACT_CALLBACK: s$="+CPBW="+right$(str$(pindex%), len(str$(pindex%))-1)+","+chr$(34)+cfields$(2)+chr$(34)+",129,"+chr$(34)+cfields$(1)+chr$(34): gosub WRITE_AT_COMMAND_TO_MODEM: return

' modem sent a response to AT+CPBW
're-enable user interaction
HS_CE_SAVE_CONTACT_CALLBACK jt%(100)=0: ni=0 : db=0
if merror=1 then merror=0: cstatus$="{red}error while saving!" 'modem error, stay on screen
if merror=0 then gosub HS_CE_CONTACT_SAVED: gosub HS_CE_CLEANUP: gosub SWITCH_TO_LAST_SCREEN 'modem OK, save the contact into memory, switch to last screen
return

'Save the edited/created contact to phonebook in RAM
HS_CE_CONTACT_SAVED if cselected%>0 then pnumber$(cselected%)=cfields$(2): ptxt$(cselected%)=cfields$(1) 'edit contact
if cselected%=0 then gosub HS_CE_NEW_CONTACT 'new contact
gosub UPDATE_CONTACT_PANE 'update contact pane
return

'Create a new contact at the index given to modem for SIM storage
 'unknown number type; TODO: add the type field or auto-determine type
HS_CE_NEW_CONTACT pindex%(pindex%)=1: pnumber$(pindex%)=cfields$(2): ptxt$(pindex%)=cfields$(1): ptype%(pindex%)=129: cselected%=pindex%: return

'Delete the selected contact
'change status message and disable user interaction
'ask modem to write the delete contact from SIM phonebook
HS_CE_DELETE_CONTACT cstatus$="{yel}deleting{elipsis}": ni=1: jt%(100)= HS_CE_DELETE_CONTACT_CALLBACK: s$="+CPBW="+right$(str$(cselected%), len(str$(cselected%))-1):gosub WRITE_AT_COMMAND_TO_MODEM
return

'Modem sent a response to AT+CPBW
're-enable user interaction
HS_CE_DELETE_CONTACT_CALLBACK jt%(100)=0: ni=0: if merror=1 then merror=0: cstatus$="{red}error while deleting!" 'modem error, stay on screen
if merror=0 then gosub HS_CE_CONTACT_DELETED: gosub HS_CE_CLEANUP: gosub SWITCH_TO_SCREEN_DIALLER 'modem OK, delete contact from memory, go to screen dialler
return

'Contact has been deleted from storage, delete it from RAM
HS_CE_CONTACT_DELETED pindex%(cselected%)=0: pnumber$(cselected%)="": ptxt$(cselected%)="": ptype%(cselected%)=0: cselected%=0: gosub UPDATE_CONTACT_PANE: return

'clean-up before leaving screen
HS_CE_CLEANUP ctrigger=0: cstatus$="": cfields$(1)="": cfields$(2)="": return

'### end HANDLER_SCREEN_CONTACT_EDIT ###


'### CALL screen handler ###
'general operations
'update the call timer and timer string
'handle user actions
HANDLER_SCREEN_CALL dtmr=time-tc: k=dtmr: gosub REAL_TIME_TO_STRING: dtmr$=s$: u$="": get u$
print "{home}";u$
if u$="D" then db=1-db: gosub DS_CALL_DB_CLR 'enable call debugging information (appear where SMS should be)
if u$="H" then u0$=u$: gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER
' O key displays oscilloscope like display
if u$="O" then poke 53280,1: sys 38656: su=1 : up=1: uc=1: ud=1
' Toggle music using M
if u$="M" then gosub MUSIC_TOGGLE
if dsta=0 goto HS_CALL_ACTIVE
if dsta=2 or dsta=3 goto HS_CALL_DIALING
if dsta=4 or dsta=5 goto HS_CALL_RINGING
return

'=== Call state: active ===
' Possible actions:
'   h: hang-up call
'   TODO: more (mute, speaker, dialpad...)
'--- Hang-up call (H) ---
HS_CALL_ACTIVE goto POLL_TOUCH_CALL_ACTIVE

HS_CALL_DIALING rem
'=== Call state: dialing ===
' Possible actions:
'   h: hang-up call
'   TODO: more (mute, speaker, dialpad...)
gosub POLL_TOUCH_CALL_DIALING: return

'=== Call state: ringing ===
' Possible actions:
'   a: answer call
'   r: reject call
'   TODO: more (mute, speaker, dialpad...)
HS_CALL_RINGING gosub POLL_TOUCH_CALL_INCOMING
if u$="A" then  u0$=u$: su=1: gosub CALL_ANSWER
if u$="R" then  u0$=u$: gosub CALL_HANGUP_ALL: gosub SWITCH_TO_SCREEN_DIALLER
return

'### end HANDLER_SCREEN_CALL ###


'Dial the number in dnumber$
CALL_DIAL if dd=1 then db=4: gosub SWITCH_TO_SCREEN_DEBUG 'enable debugging
dactive=1: dia=1: jt%(100)= CALL_DIAL_CALLBACK: gosub SEND_ATD:return

'Result Code received after ATD command was sent
CALL_DIAL_CALLBACK jt%(100)=0
if merror=0 then goto SEND_AT+CLCC 'modem OK: ATD succeeded, dialling...
if merror=1 then merror=0: gosub CALL_HANGUP: gosub SWITCH_TO_SCREEN_DIALLER 'modem ERROR: we hang-up the call
return

'Answer an incoming call
CALL_ANSWER if dd=1 then db=4: gosub SWITCH_TO_SCREEN_DEBUG 'enable debugging
'answer, and set the call timer
gosub SEND_ATA: tc=time: return

'Disconnect existing (current) voice or data call
CALL_HANGUP gosub SEND_ATH: gosub CALL_HANGUP_CLEANUP: return

'Hang-up all voice call in the state of Active, Waiting and Held
CALL_HANGUP_ALL gosub SEND_AT+CHUP

' Fall through to CALL_HANGUP_CLEANUP below, instead of calling: gosub CALL_HANGUP_CLEANUP: return

'clean up after hanging-up
CALL_HANGUP_CLEANUP gosub RINGTONE_OFF: if db>=4 then db=0: gosub SWITCH_TO_LAST_SCREEN
dactive=0: dsta=-1: cid$="": dr$="": dnumber$="": if dia=1 then dia=0
tc=0: dtmr=0: dtmr$="000000": return

'### SMS screen handler ###
HANDLER_SCREEN_SMS if sq=0 then gosub QUERY_ALL_SMS 'launch the asynchronous query of all the SMS
'user actions
u$="": get u$:if u$="{home}" then u0$=u$: gosub SWITCH_TO_LAST_SCREEN 'HOME: go back to last screen (dialler)
return

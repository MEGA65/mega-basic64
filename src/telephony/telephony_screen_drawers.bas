SCREEN_DRAWER if sc<>0 then gosub DRAW_STATUS_BAR
if sc=0 then gosub DRAW_SCREEN_DEBUG
if sc=1 then gosub DRAW_SCREEN_DIALLER
if sc=2 then gosub DRAW_SCREEN_CONTACT
if sc=3 then gosub DRAW_SCREEN_CALL
if sc=4 then gosub DRAW_SCREEN_CONTACT_EDIT
if sc=5 then gosub DRAW_SCREEN_SMS
u0$="": us=1: return

'### STATUS BAR DRAWER ###
DRAW_STATUS_BAR print "{wht}";: gosub PRINT_NETWORK_NAME: gosub PRINT_CLOCK:
gosub STAMP_BATTERY_ICON
'Fall through to this: gosub STAMP_SIGNAL_ICON: return

'=== screen signal icon update ===
STAMP_SIGNAL_ICON shi=0: if len(ntype$)=3 then shi=0
if len(ntype$)=2 then shi=1
if len(ntype$)=1 then shi=2
'print shi spaces
'print the network type (abbreviation)
'print the signal level canvas in the status bar
'print the BER under signal strength
'xx=28: yy=1: gosub MOVE_CURSOR_XX_YY: print "ber";ber$;
xx=30: yy=0: gosub MOVE_CURSOR_XX_YY: for i=1 to shi: if shi<>0 then print " ";
next i: print ntype$;: canvas gs%+sl stamp on canvas 0 at 32,0: return

'=== screen battery icon update ===
STAMP_BATTERY_ICON shi=0: bls$=""
bls$=right$("    "+str$(int(btp+0.5)),4)+"%"
'print the battery level string
'print the battery level canvas in the status bar
xx=34: yy=0: gosub MOVE_CURSOR_XX_YY: print bls$;: canvas gb%+bl% stamp on canvas 0 at 39,0: return

'=== print clock in status bar ===
PRINT_CLOCK xx=16: yy=0: gosub MOVE_CURSOR_XX_YY
't$=time$
'print left$(t$,2);":";
'print mid$(t$,3,2);":";
'print right$(t$,2);
'ntm=time-tc
'dtmr$=""
 'returns current time in nrtm
 'converts k time to string s$
gosub CALCULATE_CURRENT_TIME: k=nrtm: gosub REAL_TIME_TO_STRING : print s$: return

'=== print network name in status bar ===
'limit to 10 characters
PRINT_NETWORK_NAME xx=0: yy=0: gosub MOVE_CURSOR_XX_YY: print left$(nname$,12): if len(nname$)>12 then print "{elipsis}"
return


'### DEBUG screen update subroutine ###
'we don't clr or print, and let debug messages be
DRAW_SCREEN_DEBUG return


'### DIALLER screen update subroutine ###
'call update subroutines
'About 25ms?
DRAW_SCREEN_DIALLER if ud then gosub DS_DIALLER_NUMBER: ud=0
'Contact list about 68ms (was 158ms+)
if uc then gosub DS_DIALLER_CONTACT: uc=0
'Dial pad takes about 32ms (2 frames) to draw
if up then gosub DS_DIALLER_DIALPAD: up=0
return

'=== print dialling field ===
'draw dialling box
DS_DIALLER_NUMBER print "{yel}";: x=0: y=2: w=21: h=3: gosub DRAW_BOX: xx=1: yy=3: gosub MOVE_CURSOR_XX_YY: if nb$<>"" then print nb$;
'special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space
for j=1 to 19-len(nb$): if len(nb$)<19 then print " ";: next j: return

'=== draw full-size contact pane ===
'draw contact pane box
DS_DIALLER_CONTACT print "{lblu}";:x=21: y=2: w=19: h=23: r(2)=1: r(19)=1: gosub DRAW_BOX: xx=22: yy=3: gosub MOVE_CURSOR_XX_YY: print "    Contacts     ";
'print contact names
for i=1 to cmaxindex%:xx=22: yy=4+i: gosub MOVE_CURSOR_XX_YY:if hl%=i then print "{yel}";
s$=cpane$(i): l=clngth%: gosub TRIM_STRING_SPACES: print s$"{lblu}";:next i:xx=37:yy=22: p=0: gosub STAMP_SEARCH:return

'=== draw dialpad ===
'reinitialize timer for hiding key press
DS_DIALLER_DIALPAD ktmr=5
'1-9
for x=1 to 3: for y=1 to 3: xx=x*5-4: yy=y*4+1: p=0: if val(u0$)=x+(y-1)*3 then p=1
gosub STAMP_1_TO_9: next y,x
'hash
p=0: xx=1:yy=17: if u0$="#" then p=1
gosub STAMP_HASH: xx=6:yy=17: p=0: if u0$="0" then p=1
gosub STAMP_0: xx=11:yy=17: p=0: if u0$="*" then p=1
gosub STAMP_STAR:xx=1:yy=21:p=0: if u0$=chr$(13) then p=1
gosub STAMP_GREENPHONE: xx=6:yy=21:p=0: if u0$="+" then p=1
gosub STAMP_PLUS: xx=11:yy=21: p=0:if u0$=chr$(20) then p=1
gosub STAMP_BACKSPACE: xx=16:yy=9:p=0:if u0$="-" then p=1
gosub STAMP_MINUS: xx=16:yy=13:p=0:if u0$="/" then p=1
gosub STAMP_DIVIDE:xx=16:yy=17:p=0:if u0$="=" then p=1
gosub STAMP_EQUAL:xx=16:yy=21:p=0:if u0$="@" then p=1
gosub STAMP_CONTACT_NEW: xx=16:yy=5: p=0:if u0$="<" or u$=">" then p=1
gosub STAMP_DUALSIM: return


'### CONTACT screen update subroutine ###
'buttons
DRAW_SCREEN_CONTACT xx=0: yy=2: p=0: gosub STAMP_ARROW_BACK: yy=6: gosub STAMP_GREENPHONE: yy=10: gosub STAMP_COG: gosub TRIM_CONTACT_DISPLAY_TEXT: print "{wht}";:x=4: y=2: w=36: h=3: gosub DRAW_BOX:xx=5: yy=3: gosub MOVE_CURSOR_XX_YY:if cdisplay$<>"" then print cdisplay$;
if len(cdisplay$)<34 then for j=1 to 34-len(cdisplay$): print " ";: next j
'SMS box
x=4: y=5: w=36: if wsms=0 then h=20: r(2)=1: r(15)=1 'box (when not writing SMS)
if wsms=1 then h=8: r(3)=1: 'box (when writing SMS)
gosub DRAW_BOX
'globe and message buttons
if wsms=0 then yy=21 'globe and message buttons height
if wsms=1 then yy=9 'globe and message buttons height
xx=5: p=0: gosub STAMP_GLOBE:xx=35: p=0 :if wsms=0 then gosub STAMP_MESSAGE 'write message button
if wsms=1 then gosub STAMP_SEND 'send message button
'SMS box heading w/ status message
xx=5: yy=6: gosub MOVE_CURSOR_XX_YY: l=34: if wsms=0 then s$="SMS conversation": if matus$<>"" then s$=s$+" ("+matus$+"{wht})"
if wsms=1 then s$="SMS writing": if watus$<>"" then s$=s$+" ("+watus$+"{wht})"
gosub TRIM_STRING_SPACES: print s$"{wht}";
'SMS messages
if wsms=0 and sq=2 then gosub DS_C_PRINT_SMS 'print SMS (if not writing one)
'Writen SMS message
l=26
'Split the wsms$ string in 3 strings for display on three lines
'TODO: code a cleaner way to do this
if len(wsms$)<=l then wsms$(0)=wsms$: wsms$(1)="": wsms$(2)=""
if len(wsms$)>l and len(wsms$)<=2*l then wsms$(0)=left$(wsms$,l): wsms$(1)=right$(wsms$,len(wsms$)-l): wsms$(2)=""
if len(wsms$)>2*l and len(wsms$)<=3*l then wsms$(0)=left$(wsms$,l): wsms$(1)=mid$(wsms$,l+1,l): wsms$(2)=right$(wsms$,len(wsms$)-2*l)
'Print the wsms$ strings on 3 lines:
if wsms=0 then yy=21: y=21
if wsms=1 then yy=9: y=9
xx=9: x=9: for ii=0 to 2:gosub MOVE_CURSOR_XX_YY: s$=wsms$(ii): gosub TRIM_STRING_SPACES: print s$;:yy=yy+1:next ii
'Revert the underlined character
if wsms=1 then mdv=26: k=fn mod(ul%-1): x=x+k: y=y+int((ul%-1)/26): gosub REVERT_CHAR 'revert underlined char
return

REVERT_CHAR rem
'For some reason, the character can be >127, which will provoke an ILLEGAL QUANTITY ERROR (poking a value >255)
'We get the modulo 128 of the value we peek to avoid this.
mdv=128: poke 1024+y*40+x,fn mod(peek(1024+y*40+x))+128
return

'Displays the Contact's SMS preformatted and stored in the Contact SMS pane array
DS_C_PRINT_SMS print"{wht}";:xx=5: yy=8: gosub MOVE_CURSOR_XX_YY:for ii=0 to mmaxpane%-1:print mpt$(ii);left$(ll$,34);"{down}";:next ii:return
'### end DRAW_SCREEN_CONTACT ###


'### CONTACT_EDIT screen update subroutine ###
'buttons
DRAW_SCREEN_CONTACT_EDIT xx=0: yy=2: p=0: gosub STAMP_ARROW_BACK: yy=6: gosub STAMP_SAVE:if cselected%>0 then yy=10: gosub STAMP_TRASH_BIN
'heading box
print "{wht}";:x=4: y=2: w=36: h=3: gosub DRAW_BOX:xx=5: yy=3: gosub MOVE_CURSOR_XX_YY:s$=""
if ctrigger=0 then s$="?" 'should not happen
if ctrigger=1 then s$="Edit contact"
if ctrigger=2 then s$="New contact"
'contact saving status
if cstatus$<>"" then s$=s$+" "+cstatus$
'trim and display heading
l=34: gosub TRIM_STRING_SPACES: print s$;
'contact fields box
gosub VIRTUAL_KEYBOARD_IS_ENABLED: if b=1 then h(8)=1
x=4: y=5: w=36: h=9: gosub DRAW_BOX
'erase last

'TODO: TO OPTIMIZE (do not use MOVE_CURSOR)
for i=1 to cfields%:xx=6: yy=5+2*i: gosub MOVE_CURSOR_XX_YY:print "{wht}"clabels$(i)+": ";:if hl%=i then print "{yel}";
s$=cfields$(i): l=34-3-len(clabels$(i)): gosub TRIM_STRING_SPACES: print s$:xx=6+2+len(clabels$(i)): yy=6+2*i: gosub MOVE_CURSOR_XX_YY: l=34-3-len(clabels$(i)): gosub SPACES: print s$ 'print spaces on the underline line
if hl%=i then xx=6+2+len(clabels$(i))+ul%-1: yy=6+2*i: gosub MOVE_CURSOR_XX_YY: print chr$(182); 'print underline char if the line is hilighted
next i:return
return
'### end DRAW_SCREEN_CONTACT_EDIT ###


'### CALL screen update subroutine ###
'call status box
'common buttons
DRAW_SCREEN_CALL print "{wht}";:x=0: y=2: w=40: h=3: gosub DRAW_BOX
xx=0: yy=10: p=0: gosub STAMP_REDPHONE: yy=14: gosub STAMP_COG
'TODO: mute, speakers...
'SMS box
x=4: y=5: w=36: h=20: r(15)=1: gosub DRAW_BOX: xx=5: yy=21: p=0: gosub STAMP_GLOBE:xx=35: yy=21: p=0: gosub STAMP_MESSAGE 'message

if db=1 then goto DS_CALL_DEBUG
goto DS_CALL_DSTA
DS_CALL_DEBUG s10$="          "
xx=5: yy=7: gosub MOVE_CURSOR_XX_YY:print "Call active="dactive;s10$:yy=8: gosub MOVE_CURSOR_XX_YY:print "Call state=";dsta;s10$:yy=9: gosub MOVE_CURSOR_XX_YY:print "Dialing="dia;s10$:yy=10: gosub MOVE_CURSOR_XX_YY:print "cid$=";cid$;s10$:yy=11: gosub MOVE_CURSOR_XX_YY:print "dnumber$=";dnumber$;s10$:yy=12: gosub MOVE_CURSOR_XX_YY:print "u$="u$;s10$

DS_CALL_DSTA if dsta=0 goto DS_CALL_ACTIVE
if dsta=2 or dsta=3 goto DS_CALL_DIALING
if dsta=4 or dsta=5 goto DS_CALL_RINGING
ddisplay$="Unknown status ("+str$(dsta)+")": gosub DS_CALL_DDISPLAY
return

DS_CALL_DB_CLR xx=5:for yy=7 to 12: gosub MOVE_CURSOR_XX_YY: print left$(ss$,34): next yy
'### end DRAW_SCREEN_CALL ###

'=== Call state: active ===

DS_CALL_ACTIVE ddisplay$="In-call with "+cid$:gosub DS_CALL_DDISPLAY: gosub DS_CALL_ERASE_GP: gosub DS_CALL_TIMER: return

'=== Call state: dialing ===
DS_CALL_DIALING ddisplay$="Dialling "+dnumber$:if dr$<>"" then ddisplay$=ddisplay$+" ("+dr$+")": gosub DS_CALL_DDISPLAY:gosub DS_CALL_ERASE_GP: return

'=== Call state: ringing ===
DS_CALL_RINGING gosub RINGTONE_ON: ddisplay$="Incoming call from "+cid$:gosub DS_CALL_DDISPLAY:xx=0: yy=6: p=0: gosub STAMP_GREENPHONE:return

DS_CALL_DDISPLAY xx=1: yy=3: gosub MOVE_CURSOR_XX_YY: if ddisplay$<>"" then print ddisplay$;
for j=1 to 38-len(ddisplay$): if len(ddisplay$)<38 then print " ";: next j: return

'=== print call timer ===
' Why on earth do we need the {up} character here after the second line?
' but if we don't, then the seconds appears on line lower than it should.
DS_CALL_TIMER print "{home}{down}{down}{down}{down}{down}{down}"left$(dtmr$,2)" h": print mid$(dtmr$,4,2)" m": print "{up}"right$(dtmr$,2)" s":return

'erase green phone (answer/pick-up)
DS_CALL_ERASE_GP canvas 0 clr from 0,6 to 4,9:return


'### SMS screen update subroutine ###
'buttons
'contact saving status
DRAW_SCREEN_SMS xx=0: yy=2: p=0: gosub STAMP_ARROW_BACK print "{wht}":x=4: y=2: w=36: h=3: gosub DRAW_BOX:xx=5: yy=3: gosub MOVE_CURSOR_XX_YY:s$="All SMS":if satus$<>"" then s$=s$+" ("+satus$+"{wht})"
'trim and display heading
'contact fields box
l=34: gosub TRIM_STRING_SPACES: print s$:print "{wht}";
x=0: y=5: w=40: h=20: gosub DRAW_BOX:gosub DS_S_PRINT_SMS:return

'Displays the SMS preformatted and stored in the SMS pane array
DS_S_PRINT_SMS print"{wht}":xx=1: yy=6: gosub MOVE_CURSOR_XX_YY:for ii=0 to smaxpane%-1:print spt$(ii);left$(ll$,38)"{down}":next ii:return
'### end DRAW_SCREEN_SMS ###


'### STAMP SUBROUTINES ###
'Those subroutines are used to stamp the different buttons/icons
'   Usage: xx=x: yy=y: p=0: gosub STAMP_ABCD
STAMP_BUTTON_CANVAS canvas k stamp on canvas 0 at xx,yy
'TODO: change the appearance of the sprite depending on p
if p then gosub MOVE_SPRITE_TO_ROW_COLUMN
return

STAMP_0 k=gd%: gosub STAMP_BUTTON_CANVAS: return
STAMP_1_TO_9 k=gd%+x+(y-1)*3: gosub STAMP_BUTTON_CANVAS: return
STAMP_HASH k=gd%+10: gosub STAMP_BUTTON_CANVAS: return
STAMP_STAR k=gd%+11: gosub STAMP_BUTTON_CANVAS: return
STAMP_DIVIDE k=gd%+12: gosub STAMP_BUTTON_CANVAS: return
STAMP_MINUS k=gd%+13: gosub STAMP_BUTTON_CANVAS: return
STAMP_PLUS k=gd%+14: gosub STAMP_BUTTON_CANVAS: return
STAMP_EQUAL k=gd%+15: gosub STAMP_BUTTON_CANVAS: return
STAMP_BACKSPACE k=gd%+16: gosub STAMP_BUTTON_CANVAS: return
STAMP_GREENPHONE k=gd%+17: gosub STAMP_BUTTON_CANVAS: return
STAMP_REDPHONE k=gd%+18: gosub STAMP_BUTTON_CANVAS: return
STAMP_DUALSIM k=gd%+19: gosub STAMP_BUTTON_CANVAS: return
STAMP_CONTACT_NEW k=gd%+20: gosub STAMP_BUTTON_CANVAS: return
STAMP_ARROW_BACK k=gd%+21: gosub STAMP_BUTTON_CANVAS: return
STAMP_COG k=gd%+22: gosub STAMP_BUTTON_CANVAS: return
STAMP_TRASH_BIN k=gd%+23: gosub STAMP_BUTTON_CANVAS: return
STAMP_GLOBE k=gd%+24: gosub STAMP_BUTTON_CANVAS: return
STAMP_MESSAGE k=gd%+25: gosub STAMP_BUTTON_CANVAS: return
STAMP_SEND k=gd%+26: gosub STAMP_BUTTON_CANVAS: return
STAMP_SEARCH k=gd%+27: gosub STAMP_BUTTON_CANVAS: return
STAMP_SAVE k=gd%+28: gosub STAMP_BUTTON_CANVAS: return

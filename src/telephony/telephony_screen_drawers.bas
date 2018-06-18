SCREEN_DRAWER rem
if sc<>0 then gosub DRAW_STATUS_BAR
if sc=0 then gosub DRAW_SCREEN_DEBUG
if sc=1 then gosub DRAW_SCREEN_DIALLER
if sc=2 then gosub DRAW_SCREEN_CONTACT
if sc=3 then gosub DRAW_SCREEN_CALL
if sc=4 then gosub DRAW_SCREEN_CONTACT_EDIT
u0$="": us=1
return



'### STATUS BAR DRAWER ###
DRAW_STATUS_BAR rem
print "{wht}";
gosub PRINT_NETWORK_NAME: gosub PRINT_CLOCK: gosub STAMP_SIGNAL_ICON: gosub STAMP_BATTERY_ICON
return

'=== screen signal icon update ===
STAMP_SIGNAL_ICON rem
shi=0
if len(nt$)=3 then shi=0
if len(nt$)=2 then shi=1
if len(nt$)=1 then shi=2
xx=30: yy=0: gosub MOVE_CURSOR_XX_YY
'print shi spaces
for i=1 to shi: if shi<>0 then print " ";: next i
'print the network type (abbreviation)
print nt$;
'print the signal level canvas in the status bar
canvas gs%+sl% stamp on canvas 0 at 32,0
'print the BER under signal strength
'xx=28: yy=1: gosub MOVE_CURSOR_XX_YY: print "ber";ber$;
return

'=== screen battery icon update ===
STAMP_BATTERY_ICON rem
shi=0: bls$=""
'btp=100
if len(str$(int(btp+0.5)))= 4 then shi=0
'10<=btp<=99
if len(str$(int(btp+0.5)))= 3 then shi=1
'0<=btp<=9
if len(str$(int(btp+0.5)))= 2 then shi=2
'we add shi spaces at the beginning of the printed string
for i=1 to shi: if shi<>0 then bls$=bls$+" ": next i
'genereate battery level string (e.g.: '100%', ' 75%', '  9%')
bls$=bls$+right$(str$(int(btp+0.5)),3-shi)+"%"
'unexpected length -> unexpected number
if len(str$(int(btp+0.5)))<2 or len(str$(int(btp+0.5)))>4 then bls$="   ?%"
'print the battery level string
xx=35: yy=0: gosub MOVE_CURSOR_XX_YY: print bls$;
'print the battery level canvas in the status bar
canvas gb%+bl% stamp on canvas 0 at 39,0
return

'=== print clock in status bar ===
PRINT_CLOCK rem
't$=time$
xx=16: yy=0: gosub MOVE_CURSOR_XX_YY
'print left$(t$,2);":";
'print mid$(t$,3,2);":";
'print right$(t$,2);
'ntm=time-tc
'dtmr$=""
gosub CALCULATE_CURRENT_TIME 'returns current time in nrtm
k=nrtm: gosub REAL_TIME_TO_STRING 'conberts k time to string s$
print s$
return

'=== print network name in status bar ===
PRINT_NETWORK_NAME rem
xx=0: yy=0: gosub MOVE_CURSOR_XX_YY
'limit to 10 characters
print left$(nname$,12)
if len(nname$)>12 then print "{elipsis}"
return


'### DEBUG screen update subroutine ###
DRAW_SCREEN_DEBUG rem
'we don't clr or print, and let debug messages be
return



'### DIALLER screen update subroutine ###
DRAW_SCREEN_DIALLER rem
'call update subroutines
'About 25ms?
if ud then gosub DS_DIALLER_NUMBER: ud=0
'Contact list about 68ms (was 158ms+)
if uc then gosub DS_DIALLER_CONTACT: uc=0
'Dial pad takes about 32ms (2 frames) to draw
if up then gosub DS_DIALLER_DIALPAD: up=0
return

'=== print dialling field ===
DS_DIALLER_NUMBER rem
'draw dialling box
print "{yel}";
x=0: y=2: w=21: h=3: gosub DRAW_BOX
xx=1: yy=3: gosub MOVE_CURSOR_XX_YY
if nb$<>"" then print nb$;
'special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space
for j=1 to 19-len(nb$): if len(nb$)<19 then print " ";: next j
return

'=== draw full-size contact pane ===
DS_DIALLER_CONTACT rem
'draw contact pane box
print "{lblu}";
x=21: y=2: w=19: h=23: r(2)=1: r(19)=1: gosub DRAW_BOX
xx=22: yy=3: gosub MOVE_CURSOR_XX_YY: print "    Contacts     ";
'print contact names
for i=1 to cmaxindex%
xx=22: yy=4+i: gosub MOVE_CURSOR_XX_YY
if hl%=i then print "{yel}";
s$=cpane$(i): l=clngth%: gosub TRIM_STRING_SPACES: print s$;
print "{lblu}";
next i
xx=37:yy=22: p=0: gosub STAMP_SEARCH 'stamp search icon
return

'=== draw dialpad ===
DS_DIALLER_DIALPAD rem 'reinitialize timer
tmr=20
'1-9
for x=1 to 3: for y=1 to 3
xx=x*5-4: yy=y*4+1
if val(u0$)=x+(y-1)*3 then p=1: goto T1
p=0
T1 gosub STAMP_1_TO_9: next y,x
'hash
xx=1:yy=17
if u0$="#" then p=1: goto T2
p=0
T2 gosub STAMP_HASH
'0
xx=6:yy=17
if u0$="0" then p=1: goto T3
p=0
T3 gosub STAMP_0
'star
xx=11:yy=17
if u0$="*" then p=1: goto T4
p=0
T4 gosub STAMP_STAR
'greenphone
xx=1:yy=21
if u0$=chr$(13) then p=1: goto T5
p=0
T5 gosub STAMP_GREENPHONE
'plus
xx=6:yy=21
if u0$="+" then p=1: goto T6
p=0
T6 gosub STAMP_PLUS
'backspace
xx=11:yy=21
if u0$=chr$(20) then p=1: goto T7
p=0
T7 gosub STAMP_BACKSPACE
'minus
xx=16:yy=9
if u0$="-" then p=1: goto T8
p=0
T8 gosub STAMP_MINUS
'divide
xx=16:yy=13
if u0$="/" then p=1: goto T9
p=0
T9 gosub STAMP_DIVIDE
'equal
xx=16:yy=17
if u0$="=" then p=1: goto T10
p=0
T10 gosub STAMP_EQUAL
'new contact
xx=16:yy=21
if u0$="@" then p=1: goto T11
p=0
T11 gosub STAMP_CONTACT_NEW
'dual sim
xx=16:yy=5
if u0$="<" or u$=">" then p=1: goto T12
p=0
T12 gosub STAMP_DUALSIM
return



'### CONTACT screen update subroutine ###
DRAW_SCREEN_CONTACT rem
'buttons
xx=0: yy=2: p=0: gosub STAMP_ARROW_BACK 'arrow back
xx=0: yy=6: p=0: gosub STAMP_GREENPHONE 'greephone
xx=0: yy=10: p=0: gosub STAMP_COG 'cog
'canvas 62 stamp on canvas 0 at 0,14 'cog
'contact name/number box
gosub TRIM_CONTACT_DISPLAY_TEXT
print "{wht}";
x=4: y=2: w=36: h=3: gosub DRAW_BOX
xx=5: yy=3: gosub MOVE_CURSOR_XX_YY
if cdisplay$<>"" then print cdisplay$;
if len(cdisplay$)<34 then for j=1 to 34-len(cdisplay$): print " ";: next j
'SMS box
print "{wht}";
x=4: y=5: w=36: h=20: r(2)=1: r(15)=1: gosub DRAW_BOX
xx=5: yy=21: p=0: gosub STAMP_GLOBE 'globe
xx=35: yy=21: p=0: gosub STAMP_MESSAGE 'message
'SMS box heading w/ status message
xx=5: yy=6: gosub MOVE_CURSOR_XX_YY: l=34: s$="SMS conversation"
if satus$<>"" then s$=s$+"("+satus$+"{wht})"
gosub TRIM_STRING_SPACES: print s$;
'SMS messages
if sq=2 then gosub DS_C_PRINT_SMS
return

DS_C_PRINT_SMS rem
print"{wht}";
xx=5: yy=8: gosub MOVE_CURSOR_XX_YY
for i=1 to slngth%
if sidex%(i)<>0 then print stxt$(i);
xx=5: yy=8+i: gosub MOVE_CURSOR_XX_YY
next i
return

'### end DRAW_SCREEN_CONTACT ###


'### CONTACT_EDIT screen update subroutine ###
DRAW_SCREEN_CONTACT_EDIT rem
'buttons
xx=0: yy=2: p=0: gosub STAMP_ARROW_BACK 'arrow back
xx=0: yy=6: p=0: gosub STAMP_SAVE
if cselected%>0 then xx=0: yy=10: p=0: gosub STAMP_TRASH_BIN
'heading box
print "{wht}";
x=4: y=2: w=36: h=3: gosub DRAW_BOX
xx=5: yy=3: gosub MOVE_CURSOR_XX_YY
s$=""
if ctrigger=0 then s$="?" 'should not happen
if ctrigger=1 then s$="Edit contact"
if ctrigger=2 then s$="New contact"
'contact saving status
if cstatus$<>"" then s$=s$+" "+cstatus$
'trim and display heading
l=34: gosub TRIM_STRING_SPACES: print s$;

'contact fields box
print "{wht}";
gosub VIRTUAL_KEYBOARD_IS_ENABLED: if b=1 then h(8)=1
x=4: y=5: w=36: h=9: gosub DRAW_BOX
'erase last

'TODO: TO OPTIMIZE (do not use MOVE_CURSOR)
for i=1 to cfields%
print "{wht}";
xx=6: yy=5+2*i: gosub MOVE_CURSOR_XX_YY
print clabels$(i)+": ";
if hl%=i then print "{yel}";
s$=cfields$(i): l=34-3-len(clabels$(i)): gosub TRIM_STRING_SPACES: print s$;
xx=6+2+len(clabels$(i)): yy=6+2*i: gosub MOVE_CURSOR_XX_YY: l=34-3-len(clabels$(i)): gosub SPACES: print s$; 'print spaces on the underline line
if hl%=i then xx=6+2+len(clabels$(i))+ul%-1: yy=6+2*i: gosub MOVE_CURSOR_XX_YY: print chr$(182); 'print underline char if the line is hilighted
next i

'xx=0: yy=15: gosub MOVE_CURSOR_XX_YY
return
'### end DRAW_SCREEN_CONTACT_EDIT ###


'### CALL screen update subroutine ###
DRAW_SCREEN_CALL rem
'call status box
print "{wht}";
x=0: y=2: w=40: h=3: gosub DRAW_BOX

'common buttons
xx=0: yy=10: p=0: gosub STAMP_REDPHONE 'redphone
xx=0: yy=14: p=0: gosub STAMP_COG 'cog
'xx=0: yy=18: p=0: gosub STAMP_COG 'cog

'SMS box
print "{wht}";
x=4: y=5: w=36: h=20: r(15)=1: gosub DRAW_BOX
xx=5: yy=21: p=0: gosub STAMP_GLOBE 'globe
xx=35: yy=21: p=0: gosub STAMP_MESSAGE 'message

'TODO: use another flag for debugging and logging
if db=1 then goto DS_CALL_DEBUG
goto DS_CALL_DSTA
DS_CALL_DEBUG rem
xx=1: yy=5: gosub MOVE_CURSOR_XX_YY
print "Call active=";dactive;"          ";
xx=1: yy=6: gosub MOVE_CURSOR_XX_YY
print "Call state=";dsta;"          ";
xx=1: yy=7: gosub MOVE_CURSOR_XX_YY
print "Dialing=";dia;"          ";
xx=1: yy=8: gosub MOVE_CURSOR_XX_YY
print "cid$=";cid$;"          ";
xx=1: yy=9: gosub MOVE_CURSOR_XX_YY
print "dnumber$=";dnumber$;"          ";
xx=1: yy=10: gosub MOVE_CURSOR_XX_YY
print "u$=";u$;"          ";

DS_CALL_DSTA rem
if dsta=0 goto DS_CALL_ACTIVE
if dsta=2 or dsta=3 goto DS_CALL_DIALING
if dsta=4 or dsta=5 goto DS_CALL_RINGING
ddisplay$="Unknown status ("+str$(dsta)+")": gosub DS_CALL_DDISPLAY

return
'### end DRAW_SCREEN_CALL ###


DS_CALL_ACTIVE rem
'=== Call state: active ===
ddisplay$="In-call with "+cid$
gosub DS_CALL_DDISPLAY
gosub DS_CALL_ERASE_GP
gosub DS_CALL_TIMER
return

DS_CALL_DIALING rem
'=== Call state: dialing ===
ddsiplay$="Dialling "+dnumber$
if dr$<>"" then ddisplay$=ddisplay$+" ("+dr$+")"
gosub DS_CALL_DDISPLAY
gosub DS_CALL_ERASE_TMR
gosub DS_CALL_ERASE_GP
return

DS_CALL_RINGING rem
'=== Call state: ringing ===
ddisplay$="Incoming call from "+cid$
gosub DS_CALL_DDISPLAY
gosub DS_CALL_ERASE_TMR
xx=0: yy=6: p=0: gosub STAMP_GREENPHONE 'greenphone to pick up
return

DS_CALL_DDISPLAY rem
xx=1: yy=3: gosub MOVE_CURSOR_XX_YY
if ddisplay$<>"" then print ddisplay$;
for j=1 to 38-len(ddisplay$): if len(ddisplay$)<38 then print " ";: next j
return

'=== print call timer ===
DS_CALL_TIMER rem
xx=0: yy=6: gosub MOVE_CURSOR_XX_YY
print left$(dtmr$,2);
xx=0: yy=7: gosub MOVE_CURSOR_XX_YY
print ":";mid$(dtmr$,4,2);
xx=1: yy=8: gosub MOVE_CURSOR_XX_YY
print ":";right$(dtmr$,2);
return

DS_CALL_ERASE_TMR rem
'erase timer text
xx=0: yy=6: gosub MOVE_CURSOR_XX_YY
print "    ";
xx=0: yy=7: gosub MOVE_CURSOR_XX_YY
print "    ";
xx=0: yy=8: gosub MOVE_CURSOR_XX_YY
print "    ";
return

DS_CALL_ERASE_GP rem
'erase green phone (answer/pick-up)
canvas 0 clr from 0,6 to 4,9
return


'### STAMP SUBROUTINES ###
'Those subroutines are used to stamp the different buttons/icons
'   Usage: xx=x: yy=y: p=0: gosub STAMP_ABCD
STAMP_BUTTON_CANVAS rem
'canvas k+p*gffset stamp on canvas 0 at xx,yy
canvas k stamp on canvas 0 at xx,yy
'TODO: change the appearance of the sprite depending on p
return

STAMP_0 k=gd%: gosub STAMP_BUTTON_CANVAS: return
STAMP_1_TO_9 k=gd%+x+(y-1)*3: gosub STAMP_BUTTON_CANVAS: return
STAMP_HASH k=gd%+10: gosub STAMP_BUTTON_CANVAS: return
STAMP_STAR k=gd%+10+1: gosub STAMP_BUTTON_CANVAS: return
STAMP_DIVIDE k=gd%+10+2: gosub STAMP_BUTTON_CANVAS: return
STAMP_MINUS k=gd%+10+3: gosub STAMP_BUTTON_CANVAS: return
STAMP_PLUS k=gd%+10+4: gosub STAMP_BUTTON_CANVAS: return
STAMP_EQUAL k=gd%+10+5: gosub STAMP_BUTTON_CANVAS: return
STAMP_BACKSPACE k=gd%+10+6: gosub STAMP_BUTTON_CANVAS: return
STAMP_GREENPHONE k=gd%+10+7: gosub STAMP_BUTTON_CANVAS: return
STAMP_REDPHONE k=gd%+10+8: gosub STAMP_BUTTON_CANVAS: return
STAMP_DUALSIM k=gd%+10+9: gosub STAMP_BUTTON_CANVAS: return
STAMP_CONTACT_NEW k=gd%+10+10: gosub STAMP_BUTTON_CANVAS: return
STAMP_ARROW_BACK k=gd%+10+11: gosub STAMP_BUTTON_CANVAS: return
STAMP_COG k=gd%+10+12: gosub STAMP_BUTTON_CANVAS: return
STAMP_TRASH_BIN k=gd%+10+13: gosub STAMP_BUTTON_CANVAS: return
STAMP_GLOBE k=gd%+10+14: gosub STAMP_BUTTON_CANVAS: return
STAMP_MESSAGE k=gd%+10+15: gosub STAMP_BUTTON_CANVAS: return
STAMP_SEND k=gd%+10+16: gosub STAMP_BUTTON_CANVAS: return
STAMP_SEARCH k=gd%+10+17: gosub STAMP_BUTTON_CANVAS: return
STAMP_SAVE k=gd%+10+18: gosub STAMP_BUTTON_CANVAS: return

SCREEN_DRAWER rem
gosub DRAW_STATUS_BAR
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
t$=time$
xx=16: yy=0: gosub MOVE_CURSOR_XX_YY
print left$(t$,2);":";
print mid$(t$,3,2);":";
print right$(t$,2);
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
xx=37:yy=22: gosub STAMP_SEARCH 'stamp search icon
return

'=== draw dialpad ===
DS_DIALLER_DIALPAD rem 'reinitialize timer
tmr=20
for x=1 to 3: for y=1 to 3
xx=x*5-4: yy=y*4+1
if val(u0$)=x+(y-1)*3 then gosub STAMP_1_TO_9_PRESSED: goto NEXTYX
gosub STAMP_1_TO_9
NEXTYX next y,x
T1 xx=1:yy=17
if u0$="#" then gosub STAMP_HASH_PRESSED: goto T2
gosub STAMP_HASH
T2 xx=6:yy=17
if u0$="0" then gosub STAMP_0_PRESSED: goto T3
gosub STAMP_0
T3 xx=11:yy=17
if u0$="*" then gosub STAMP_STAR_PRESSED: goto T4
gosub STAMP_STAR
T4 xx=1:yy=21
if u0$=chr$(13) then gosub STAMP_GREENPHONE_PRESSED: goto T5
gosub STAMP_GREENPHONE
T5 xx=6:yy=21
if u0$="+" then gosub STAMP_PLUS_PRESSED: goto T6
gosub STAMP_PLUS
T6 xx=11:yy=21
if u0$=chr$(20) then gosub STAMP_BACKSPACE_PRESSED: goto T7
gosub STAMP_BACKSPACE
T7 xx=16:yy=9
if u0$="-" then gosub STAMP_MINUS_PRESSED: goto T8
gosub STAMP_MINUS
T8 xx=16:yy=13
if u0$="/" then gosub STAMP_DIVIDE_PRESSED: goto T9
gosub STAMP_DIVIDE
T9 xx=16:yy=17
if u0$="=" then gosub STAMP_EQUAL_PRESSED: goto T10
gosub STAMP_EQUAL
T10 xx=16:yy=21
if u0$="@" then gosub STAMP_CONTACT_NEW_PRESSED: goto T11
gosub STAMP_CONTACT_NEW
T11 xx=16:yy=5
if u0$="<" or u$=">" then gosub STAMP_DUALSIM_PRESSED: goto T99
gosub STAMP_DUALSIM
T99 return

STAMP_0 canvas gd% stamp on canvas 0 at xx,yy: return
STAMP_0_PRESSED canvas gd%+gffset stamp on canvas 0 at xx,yy: return
STAMP_1_TO_9 canvas gd%+x+(y-1)*3 stamp on canvas 0 at xx,yy: return
STAMP_1_TO_9_PRESSED canvas gd%+x+(y-1)*3+gffset stamp on canvas 0 at xx,yy: return
STAMP_HASH canvas gd%+10 stamp on canvas 0 at xx,yy: return
STAMP_HASH_PRESSED canvas gd%+10+gffset stamp on canvas 0 at xx,yy: return
STAMP_STAR canvas gd%+10+1 stamp on canvas 0 at xx,yy: return
STAMP_STAR_PRESSED canvas gd%+10+1+gffset stamp on canvas 0 at xx,yy: return
STAMP_DIVIDE canvas gd%+10+2 stamp on canvas 0 at xx,yy: return
STAMP_DIVIDE_PRESSED canvas gd%+10+2+gffset stamp on canvas 0 at xx,yy: return
STAMP_MINUS canvas gd%+10+3 stamp on canvas 0 at xx,yy: return
STAMP_MINUS_PRESSED canvas gd%+10+3+gffset stamp on canvas 0 at xx,yy: return
STAMP_PLUS canvas gd%+10+4 stamp on canvas 0 at xx,yy: return
STAMP_PLUS_PRESSED canvas gd%+10+4+gffset stamp on canvas 0 at xx,yy: return
STAMP_EQUAL canvas gd%+10+5 stamp on canvas 0 at xx,yy: return
STAMP_EQUAL_PRESSED canvas gd%+10+5+gffset stamp on canvas 0 at xx,yy: return
STAMP_BACKSPACE canvas gd%+10+6 stamp on canvas 0 at xx,yy: return
STAMP_BACKSPACE_PRESSED canvas gd%+10+6+gffset stamp on canvas 0 at xx,yy: return
STAMP_GREENPHONE canvas gd%+10+7 stamp on canvas 0 at xx,yy: return
STAMP_GREENPHONE_PRESSED canvas gd%+10+7+gffset stamp on canvas 0 at xx,yy: return
STAMP_REDPHONE canvas gd%+10+8 stamp on canvas 0 at xx,yy: return
STAMP_REDPHONE_PRESSED canvas gd%+10+8+gffset stamp on canvas 0 at xx,yy: return
STAMP_DUALSIM canvas gd%+10+9 stamp on canvas 0 at xx,yy: return
STAMP_DUALSIM_PRESSED canvas gd%+10+9+gffset stamp on canvas 0 at xx,yy: return
STAMP_CONTACT_NEW canvas gd%+10+10 stamp on canvas 0 at xx,yy: return
STAMP_CONTACT_NEW_PRESSED canvas gd%+10+10+gffset stamp on canvas 0 at xx,yy: return
STAMP_ARROW_BACK canvas gd%+10+11 stamp on canvas 0 at xx,yy: return
STAMP_ARROW_BACK_PRESSED canvas gd%+10+11+gffset stamp on canvas 0 at xx,yy: return
STAMP_COG canvas gd%+10+12 stamp on canvas 0 at xx,yy: return
STAMP_COG_PRESSED canvas gd%+10+12+gffset stamp on canvas 0 at xx,yy: return
STAMP_TRASH_BIN canvas gd%+10+13 stamp on canvas 0 at xx,yy: return
STAMP_TRASH_BIN_PRESSED canvas gd%+10+13+gffset stamp on canvas 0 at xx,yy: return
STAMP_GLOBE canvas gd%+10+14 stamp on canvas 0 at xx,yy: return
STAMP_GLOBE_PRESSED canvas gd%+10+14+gffset stamp on canvas 0 at xx,yy: return
STAMP_MESSAGE canvas gd%+10+15 stamp on canvas 0 at xx,yy: return
STAMP_MESSAGE_PRESSED canvas gd%+10+15+gffset stamp on canvas 0 at xx,yy: return
STAMP_SEND canvas gd%+10+16 stamp on canvas 0 at xx,yy: return
STAMP_SEND_PRESSED canvas gd%+10+16+gffset stamp on canvas 0 at xx,yy: return
STAMP_SEARCH canvas gd%+10+17 stamp on canvas 0 at xx,yy: return
STAMP_SEARCH_PRESSED canvas gd%+10+17+gffset stamp on canvas 0 at xx,yy: return

'### CONTACT screen update subroutine ###
DRAW_SCREEN_CONTACT rem
'buttons
xx=0: yy=2: gosub STAMP_ARROW_BACK 'arrow back
xx=0: yy=6: gosub STAMP_GREENPHONE 'greephone
xx=0: yy=10: gosub STAMP_COG 'cog
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
x=4: y=5: w=36: h=20: r(15)=1: gosub DRAW_BOX
xx=5: yy=21: gosub STAMP_GLOBE 'globe
xx=35: yy=21: gosub STAMP_MESSAGE 'message
return
'### end DRAW_SCREEN_CONTACT ###


'### CONTACT_EDIT screen update subroutine ###
DRAW_SCREEN_CONTACT_EDIT rem
'buttons
xx=0: yy=2: gosub STAMP_ARROW_BACK 'arrow back
'heading box
print "{wht}";
x=4: y=2: w=36: h=3: gosub DRAW_BOX
xx=5: yy=3: gosub MOVE_CURSOR_XX_YY
s$=""
if ctrigger=0 then s$="?" 'should not happen
if ctrigger=1 then s$="Edit contact"
if ctrigger=2 then s$="New contact"
'contact saving status
if cstatus$<>"" then s$=s$+" {red}"+cstatus$
'trim and display heading
l=34: gosub TRIM_STRING_SPACES: print s$;
'contact fields box
print "{wht}";
x=4: y=5: w=36: h=20: gosub DRAW_BOX

'xx=6: yy=7: gosub MOVE_CURSOR_XX_YY
'print "name: ";: if hl%=1 then print "{yel}";
's$=cfields$(0): l=28: gosub TRIM_STRING: print s$;: print "{wht}";
'xx=6: yy=9: gosub MOVE_CURSOR_XX_YY
'print "number: ";: if hl%=2 then print "{yel}";
's$=cfields$(1): l=25: gosub TRIM_STRING: print s$;: print "{wht}";

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

return
'### end DRAW_SCREEN_CONTACT_EDIT ###


'### CALL screen update subroutine ###
DRAW_SCREEN_CALL rem
'call status box
print "{wht}";
x=0: y=2: w=40: h=3: gosub DRAW_BOX

'common buttons
xx=0: yy=10: gosub STAMP_REDPHONE 'redphone
xx=0: yy=14: gosub STAMP_COG 'cog
'xx=0: yy=18: gosub STAMP_COG 'cog

'SMS box
print "{wht}";
x=4: y=5: w=36: h=20: r(15)=1: gosub DRAW_BOX
xx=5: yy=21: gosub STAMP_GLOBE 'globe
xx=35: yy=21: gosub STAMP_MESSAGE 'message

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
canvas 18 stamp on canvas 0 at 0,6 'greenphone
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
print ":";mid$(dtmr$,3,2);
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

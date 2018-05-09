DRAW_STATUS_BAR rem "### STATUS BAR DRAWER ###"
print "{wht}";: rem "white text"
gosub PRINT_NETWORK_NAME: gosub PRINT_CLOCK: gosub STAMP_SIGNAL_ICON: gosub STAMP_BATTERY_ICON
return

STAMP_SIGNAL_ICON rem "=== screen signal icon update ==="
shi=0
if len(nt$)=3 then shi=0
if len(nt$)=2 then shi=1
if len(nt$)=1 then shi=2
xx=30: yy=0: gosub MOVE_CURSOR_XX_YY
for i=1 to shi: if shi<>0 then print " ";: next i: rem "print shi spaces"
print nt$;: rem "print the network type (abbreviation)"
canvas 40+1+sl% stamp on canvas 0 at 32,0: rem "print the signal level canvas in the status bar"
rem "BER is always 99" xx=25: yy=3: gosub MOVE_CURSOR_XX_YY: print "ber";ber$;: rem "print the BER under signal strength"
return

STAMP_BATTERY_ICON rem "=== screen battery icon update ==="
shi=0: bls$=""
if len(str$(int(btp+0.5)))= 4 then shi=0: rem "btp=100"
if len(str$(int(btp+0.5)))= 3 then shi=1: rem "10<=btp<=99"
if len(str$(int(btp+0.5)))= 2 then shi=2: rem "0<=btp<=9" 
for i=1 to shi: if shi<>0 then bls$=bls$+" ": next i: rem "we add shi spaces at the beginning of the printed string"
bls$=bls$+right$(str$(int(btp+0.5)),3-shi)+"%": rem "e.g.: '100%', ' 75%', '  9%'"
if len(str$(int(btp+0.5)))<2 or len(str$(int(btp+0.5)))>4 then bls$="   ?%": rem "unexpected length -> unexpected number"
xx=35: yy=0: gosub MOVE_CURSOR_XX_YY: print bls$;
canvas 49+bl% stamp on canvas 0 at 39,0: rem "print the battery level canvas in the status bar"
return

PRINT_CLOCK rem "=== print clock in status bar ==="
t$=time$
xx=16: yy=0: gosub MOVE_CURSOR_XX_YY
print left$(t$,2);":";
print mid$(t$,3,2);":";
print right$(t$,2);
return

PRINT_NETWORK_NAME rem "=== print network name in status bar ==="
xx=0: yy=0: gosub MOVE_CURSOR_XX_YY
print left$(nname$,10): rem "limit to 10 characters"
if len(nname$)>10 then print "..."
return


DRAW_SCREEN_1 rem "### SC 1 (DIALER) SCREEN UPDATE ###"
rem "=== dialer screen update subroutine ==="
gosub DRAW_STATUS_BAR
gosub DRAW_SCREEN_1_TEXT: gosub DRAW_SCREEN_1_TILES: rem "call update subroutines"
gosub DRAW_CONTACTS_PANE
us=1
return

DRAW_SCREEN_1_TEXT rem "=== screen text update ==="
# "draw dialling box"
print "{yel}";
x=0: y=2: w=21: h=3: gosub DRAW_BOX
xx=1: yy=3: gosub MOVE_CURSOR_XX_YY
if nb$<>"" then print nb$;
for j=1 to 19-len(nb$): if len(nb$)<19 then print " ";: next j: rem "special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space"
return

DRAW_CONTACTS_PANE rem "=== draw full-size contact pane ==="
# "draw contact pane box"
print "{lblu}";
x=21: y=2: w=19: h=23: r(2)=1: r(19)=1: gosub DRAW_BOX
xx=22: yy=3: gosub MOVE_CURSOR_XX_YY: print "    contacts     ";
# "print contact names"
for i=1 to cmaxindex%
xx=22: yy=4+i: gosub MOVE_CURSOR_XX_YY
if hl%=i then print "{yel}";
if cpane$(i)<>"" then print cpane$(i);
for j=1 to clngth%-len(cpane$(i)): if len(cpane$(i))<clngth% then print " ";: next j
print "{lblu}"
next i
# "stamp search icon"
canvas 66 stamp on canvas 0 at 37,22: rem "search"
return

DRAW_SCREEN_1_TILES rem "=== screen dial tiles update ==="
tmr=1000: rem "reinitialize timer"
for x=1 to 3: for y=1 to 3
if val(u$)=x+(y-1)*3 then gosub STAMP_1_TO_9_PRESSED: goto NEXTYX
gosub STAMP_1_TO_9
NEXTYX next y,x
T1 if u$="#" then gosub STAMP_HASH_PRESSED: goto T2
gosub STAMP_HASH
T2 if u$="0" then gosub STAMP_0_PRESSED: goto T3
gosub STAMP_0
T3 if u$="*" then gosub STAMP_STAR_PRESSED: goto T4
gosub STAMP_STAR
T4 if u$=chr$(13) then gosub STAMP_GREENPHONE_PRESSED: goto T5
gosub STAMP_GREENPHONE
T5 if u$="+" then gosub STAMP_PLUS_PRESSED: goto T6
gosub STAMP_PLUS
T6 if u$=chr$(20) then gosub STAMP_BACKSPACE_PRESSED: goto T7
gosub STAMP_BACKSPACE
T7 if u$="-" then gosub STAMP_MINUS_PRESSED: goto T8
gosub STAMP_MINUS
T8 if u$="/" then gosub STAMP_DIVIDE_PRESSED: goto T9
gosub STAMP_DIVIDE
T9 if u$="=" then gosub STAMP_EQUAL_PRESSED: goto T10
gosub STAMP_EQUAL
T10 if u$="@" then gosub STAMP_CONTACT_NEW_PRESSED: goto T11
gosub STAMP_CONTACT_NEW
T11 if u$="<" or u$=">" then gosub STAMP_DUALSIM_PRESSED: goto T99
gosub STAMP_DUALSIM
T99 return

STAMP_1_TO_9_PRESSED canvas x+(y-1)*3+1+20 stamp on canvas 0 at x*5-4,y*4+1: return: rem "1 to 9 (pressed)"
STAMP_1_TO_9 canvas x+(y-1)*3+1 stamp on canvas 0 at x*5-4,y*4+1: return: rem "1 to 9"
STAMP_HASH_PRESSED canvas 11+20 stamp on canvas 0 at 1,17: return: rem "# (pressed)"
STAMP_HASH canvas 11 stamp on canvas 0 at 1,17: return: rem "#"
STAMP_0_PRESSED canvas 1+20 stamp on canvas 0 at 6,17: return: rem "0 (pressed)"
STAMP_0 canvas 1 stamp on canvas 0 at 6,17: return: rem "0"
STAMP_STAR_PRESSED canvas 12+20 stamp on canvas 0 at 11,17: return: rem "* (pressed)"
STAMP_STAR canvas 12 stamp on canvas 0 at 11,17: return: rem "*"
STAMP_GREENPHONE_PRESSED canvas 18+20 stamp on canvas 0 at 1,21: return: rem "greephone (pressed)"
STAMP_GREENPHONE canvas 18 stamp on canvas 0 at 1,21: return: rem "greephone"
STAMP_PLUS_PRESSED canvas 15+20 stamp on canvas 0 at 6,21: return: rem "+ (pressed)"
STAMP_PLUS canvas 15 stamp on canvas 0 at 6,21: return: rem "+"
STAMP_BACKSPACE_PRESSED canvas 17+20 stamp on canvas 0 at 11,21: return: rem "backspace (pressed)"
STAMP_BACKSPACE canvas 17 stamp on canvas 0 at 11,21: return: rem "backspace"
STAMP_MINUS_PRESSED canvas 14+20 stamp on canvas 0 at 16,9: return: rem "- (pressed)"
STAMP_MINUS canvas 14 stamp on canvas 0 at 16,9: return: rem "-"
STAMP_DIVIDE_PRESSED canvas 13+20 stamp on canvas 0 at 16,13: return: rem "divide (pressed)"
STAMP_DIVIDE canvas 13 stamp on canvas 0 at 16,13: return: rem "divide"
STAMP_EQUAL_PRESSED canvas 16+20 stamp on canvas 0 at 16,17: return: rem "= (pressed)"
STAMP_EQUAL canvas 16 stamp on canvas 0 at 16,17: return: rem "="
STAMP_CONTACT_NEW_PRESSED canvas 68 stamp on canvas 0 at 16,21: return: rem "contact new (pressed)"
STAMP_CONTACT_NEW canvas 67 stamp on canvas 0 at 16,21: return: rem "contact new"
STAMP_DUALSIM_PRESSED canvas 48 stamp on canvas 0 at 16,5: return: rem "dual sim (pressed)"
STAMP_DUALSIM canvas 47 stamp on canvas 0 at 16,5: return: rem "dual sim"


DRAW_SCREEN_0 rem "### SC 0 (DEBUG) SCREEN UPDATE ###"
rem "we don't clr or print, and let debug messages be"
return

DRAW_SCREEN_CONTACT rem
gosub DRAW_STATUS_BAR
# "buttons"
canvas 60 stamp on canvas 0 at 0,2
canvas 18 stamp on canvas 0 at 0,6: rem "greephone"
canvas 61 stamp on canvas 0 at 0,10: rem "cog"
#canvas 62 stamp on canvas 0 at 0,14: rem "trash bin"
# "contact name/number box"
gosub TRIM_CONTACT_DISPLAY_TEXT
print "{wht}";
x=4: y=2: w=36: h=3: gosub DRAW_BOX
xx=5: yy=3: gosub MOVE_CURSOR_XX_YY
if cdisplay$<>"" then print cdisplay$;
for j=1 to 34-len(cdisplay$): if len(cdisplay$)<35 then print " ";: next j
# "SMS box"
print "{wht}";
x=4: y=5: w=36: h=20: r(15)=1: gosub DRAW_BOX
canvas 63 stamp on canvas 0 at 5,21: rem "globe"
canvas 64 stamp on canvas 0 at 35,21: rem "message"
return

DRAW_SCREEN_CALL rem
gosub DRAW_STATUS_BAR
# "call status box"
print "{wht}";
x=0: y=2: w=40: h=3: gosub DRAW_BOX

xx=1: yy=5: gosub MOVE_CURSOR_XX_YY
print "call active=";dactive;"          ";
xx=1: yy=6: gosub MOVE_CURSOR_XX_YY
print "call state=";dsta;"          ";
xx=1: yy=7: gosub MOVE_CURSOR_XX_YY
print "dialing=";dia;"          ";
xx=1: yy=8: gosub MOVE_CURSOR_XX_YY
print "cid$=";cid$;"          ";
xx=1: yy=9: gosub MOVE_CURSOR_XX_YY
print "dnumber$=";dnumber$;"          ";
xx=1: yy=10: gosub MOVE_CURSOR_XX_YY
print "u$=";u$;"          ";

if dsta=0 goto DS_CALL_ACTIVE
if dsta=2 or dsta=3 goto DS_CALL_DIALING
if dsta=4 or dsta=5 goto DS_CALL_RINGING
ddisplay$="unknown status": gosub DS_CALL_DDISPLAY
return

DS_CALL_ACTIVE rem
# "=== Call state: active ==="
ddisplay$="in-call with "+cid$
gosub DS_CALL_DDISPLAY
return

DS_CALL_DIALING rem
# "=== Call state: dialing ==="
ddsiplay$="dialling "+dnumber$
if dr$<>"" then ddisplay$=ddisplay$+" ("+dr$+")"
gosub DS_CALL_DDISPLAY
return

DS_CALL_RINGING rem
# "=== Call state: ringing ==="
ddisplay$="incoming call from "+cid$
gosub DS_CALL_DDISPLAY
return

DS_CALL_DDISPLAY rem
xx=1: yy=3: gosub MOVE_CURSOR_XX_YY
if ddisplay$<>"" then print ddisplay$;
for j=1 to 38-len(ddisplay$): if len(ddisplay$)<38 then print " ";: next j
return





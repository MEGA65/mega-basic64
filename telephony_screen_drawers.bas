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
xx=0: yy=2: gosub MOVE_CURSOR_XX_YY
print "{yel}";: rem "yellow text"
print "UCCCCCCCCCCCCCCCCCCCI"; : xx=0: yy=3: gosub MOVE_CURSOR_XX_YY
print "B";
if nb$<>"" then print nb$;
for j=1 to 19-len(nb$): if len(nb$)<19 then print " ";: next j: rem "special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space; TODO: use SPC(x) command!"
print "B";: xx=0: yy=4: gosub MOVE_CURSOR_XX_YY
print "JCCCCCCCCCCCCCCCCCCCK";
return

DRAW_CONTACTS_PANE rem "=== draw full-size contact pane ==="
xx=21: yy=2: gosub MOVE_CURSOR_XX_YY
print "{lblu}";
print "UCCCCCCCCCCCCCCCCCI"; : xx=21: yy=3: gosub MOVE_CURSOR_XX_YY
print "B    contacts     B"; : xx=21: yy=4: gosub MOVE_CURSOR_XX_YY
print chr$(171)+"CCCCCCCCCCCCCCCCC"+chr$(179); : xx=21: yy=5: gosub MOVE_CURSOR_XX_YY
for i=1 to cmaxindex%
print "B";: if hl%=i then print "{yel}";
if cpane$(i)<>"" then print cpane$(i);
for j=1 to clngth%-len(cpane$(i)): if len(cpane$(i))<clngth% then print " ";: next j: rem "special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space; TODO: use SPC(x) command!"
print "{lblu}";
print "B"; : xx=21: yy=5+i: gosub MOVE_CURSOR_XX_YY
next i
print chr$(171)+"CCCCCCCCCCCCCCCCC"+chr$(179); : xx=21: yy=22: gosub MOVE_CURSOR_XX_YY
print "B           searchB"; : xx=21: yy=23: gosub MOVE_CURSOR_XX_YY
print "JCCCCCCCCCCCCCCCCCK";
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
T10 if u$="@" then gosub STAMP_SATTELITE_PRESSED: goto T11
gosub STAMP_SATTELITE
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
STAMP_SATTELITE_PRESSED canvas 20+20 stamp on canvas 0 at 16,5: return: rem "satellite (pressed)"
STAMP_SATTELITE canvas 20 stamp on canvas 0 at 16,5: return: rem "satellite"
STAMP_DUALSIM_PRESSED canvas 48 stamp on canvas 0 at 16,21: return: rem "dual sim (pressed)"
STAMP_DUALSIM canvas 47 stamp on canvas 0 at 16,21: return: rem "dual sim"

DRAW_SCREEN_2 rem "### SC 2 (RING) SCREEN UPDATE ###"
gosub DRAW_STATUS_BAR
us=1
canvas 0 clr : print "{clr}";
print "Incoming call!"
if cid$<>"" then print "Caller: ";cid$: goto DS2_K
print "{down}";
DS2_K print "{down}[a]ccept or [r]eject?"
return

DRAW_SCREEN_3 rem "### SC 3 (IN-CALL) SCREEN UPDATE ###"
gosub DRAW_STATUS_BAR
us=1
canvas 0 clr : print "{clr}";
print "In-call with ";cid$
print "{down}[h]ang up"
return

DRAW_SCREEN_4 rem "### SC 4 (DIALLING) SCREEN UPDATE ###"
gosub DRAW_STATUS_BAR
us=1
canvas 0 clr : print "{clr}";
print "Dialling ";nb$
if dr$<>"" then print dr$: goto DS3_K
print "{down}";
DS3_K print "{down}[h]ang up"
return

DRAW_SCREEN_0 rem "### SC 0 (DEBUG) SCREEN UPDATE ###"
rem "we don't clr or print, and let debug messages be"
return

DRAW_SCREEN_CONTACT rem
gosub DRAW_STATUS_BAR
# "back button"
canvas 17 stamp on canvas 0 at 0,2
# "contact name/number"
gosub TRIM_CONTACT_DISPLAY_TEXT
xx=3: yy=2: gosub MOVE_CURSOR_XX_YY
print "{wht}";
print "UCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCI"; : xx=3: yy=3: gosub MOVE_CURSOR_XX_YY
print "B";
if cdisplay$<>"" then print cdisplay$;
for j=1 to 35-len(cdisplay$): if len(cdisplay$)<35 then print " ";: next j
print "B";: xx=3: yy=4: gosub MOVE_CURSOR_XX_YY
print "JCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCK";

xx=0: yy=5: gosub MOVE_CURSOR_XX_YY
print "UCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCI"; : xx=0: yy=6: gosub MOVE_CURSOR_XX_YY
print "B sms conversation                 B"; : xx=0: yy=7: gosub MOVE_CURSOR_XX_YY
print chr$(171)+"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"+chr$(179); : xx=0: yy=8: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=9: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=10: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=11: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=12: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=13: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=14: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=15: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=16: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=17: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=18: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=19: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=20: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=21: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=22: gosub MOVE_CURSOR_XX_YY
print chr$(171)+"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"+chr$(179); : xx=0: yy=23: gosub MOVE_CURSOR_XX_YY
print "B                                  B"; : xx=0: yy=24: gosub MOVE_CURSOR_XX_YY
print "JCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCK";

canvas 18 stamp on canvas 0 at 36,6: rem "greephone"
canvas 18 stamp on canvas 0 at 36,10: rem "greephone"
canvas 18 stamp on canvas 0 at 36,14: rem "greephone"

return

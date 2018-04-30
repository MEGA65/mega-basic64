DRAW_SCREEN_1 rem "### SC 1 (DIALER) SCREEN UPDATE ###"
rem "=== dialer screen update subroutine ==="
gosub DRAW_SCREEN_1_TEXT: gosub DRAW_SCREEN_1_TILES: gosub STAMP_SIGNAL_BARS: rem "call update subroutines"
us=1
return

DRAW_SCREEN_1_TEXT rem "=== screen text update ==="
print "{clr}";: rem "clr text"
print "{yel}";: rem "yellow text"
print "UCCCCCCCCCCCCCCCCCCCI"
print "B                   B"
print "B";
print nb$;
for j=1 to 19-len(nb$): if len(nb$)<19 then print " ";: next j: rem "special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space; TODO: use SPC(x) command!"
print "B"
print "B                   B"
print "JCCCCCCCCCCCCCCCCCCCK"
rem "BER is always 99" xx=35: yy=3: gosub MOVE_CURSOR_XX_YY: print "ber";ber$;: rem "print the BER under signal strength"
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

STAMP_SIGNAL_BARS rem "=== screen signal icon update ==="
canvas 40+1+sl% stamp on canvas 0 at 40-5,0: rem "print the signal level canvas in the top right-hand corner"
return

DRAW_SCREEN_2 rem "### SC 2 (RING) SCREEN UPDATE ###"
us=1
canvas 0 clr : print "{clr}";
print "Incoming call!"
if cid$<>"" then print "Caller: ";cid$: goto DS2_K
print "{down}";
DS2_K print "{down}[a]ccept or [r]eject?"
return

DRAW_SCREEN_3 rem "### SC 3 (IN-CALL) SCREEN UPDATE ###"
us=1
canvas 0 clr : print "{clr}";
print "In-call with ";cid$
print "{down}[h]ang up"
return

DRAW_SCREEN_4 rem "### SC 4 (DIALLING) SCREEN UPDATE ###"
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

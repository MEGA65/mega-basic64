1 poke 53280,0: poke 53281,0: rem "border and screen color (0: black)"
2 poke 0,65: rem "fast mode (50mhz cpu clock)"
3 poke 53248+111,128: rem "fix screen artifacts (60hz display)"

9 print chr$(147);: canvas 0 clr: rem "clear screen"


10 rem "### initialization ###"
11 gosub LOOKUP_GOTO_LN_PATCH_ADDRESS: rem "one-time only lookup patch address"
12 gosub SETUP_PROGRAM: rem "program state setup"
13 gosub SETUP_PARSER: gosub SETUP_MODEM: rem "modem parser and modem setup"
14 gosub SETUP_GUI: rem "GUI-related setup"
15 gosub DEFINE_FUNCTIONS: rem "define functions"

90 if db=1 then gosub SWITCH_TO_SCREEN_0: goto INIT_END: rem "if db=1, sc=0 (debug screen)"
91 gosub SWITCH_TO_SCREEN_1: rem "start the program on screen 1 (dialer)"
INIT_END goto MAIN_LOOP

LOOKUP_GOTO_LN_PATCH_ADDRESS rem "=== goto,X lookup of patch address"
101 for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next: return
199 return

GOTO_LN rem "=== goto X subroutine ==="
201 rem "goes to line ln, if ln>0"
210 ln$=str$(ln): if ln<=0 then return
220 for i=0 to 5: poke ja+i,32:next: rem "first rub out with spaces in case line number is short"
230 for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
240 if ln>0 then gosub,00000: rem "gosub to line ln"
250 poke ja,44: rem "put the comma back in case we want to run again"
299 return

SETUP_PROGRAM rem "=== program flags and variables setup ==="
305 db=0: rem "flag db (debug): print debugging information"
310 sd=1: rem "flag send: send characters typed on keyboard to modem right away"
320 sc=1: rem "current screen to be displayed and user input to be taken"
322 su=0: rem "flag su (screen update): a change in the program requires a screen update"
323 us=0: rem "flag us (updated screen): is set to 1 when the screen if actually updated"
330 cid$="": rem "caller id (number)"
332 dr$="": rem "dr (dialling result): user friendly information about dialling state"
334 dia=0: rem "flag dia (dialling): the modem is currently dialling"
336 rssi=99: rem "rssi: received signal strength indicator"
337 ber=99: rem "ber: channel bit error rate"
340 cnt=0: rem "loop counter"
399 return

SETUP_PARSER rem "=== setup for modem parser ==="
410 dim mf$(20): rem "fields from colon-comma formatted messages"
420 dim ol$(20): rem "lines from modem that don't conform to any normal message format"
430 dim jt%(100): rem "jump table for message handling"
440 for i=0 to 99: jt%(i)=10000+100*i: next i
450 open 1,2,1
499 return

SETUP_MODEM rem "=== modem setup ==="
510 s$="ate0"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "no echo from modem"
599 return

SETUP_GUI rem "=== GUI-related setup ==="
610 u$="": nb$="": rem "user-input char and number initialization"
630 sl%=0: rem "Signal Level integer [0:5]"
635 ber$="?": rem "Bit Error Rate string to be displayed"
650 tmr=1000: rem "timer for keystrokes"
699 return

DEFINE_FUNCTIONS rem "--- functions definition ---"
710 def fn m6(x) = x-(int(x/6)*6): rem "x modulo 6; x % 6"
720 def fn m1k(x) = x-(int(x/1000)*1000): rem "x modulo 1000; x % 1000"
750 mdv=1 : rem "modulo divisor"
760 def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"
799 return


MAIN_LOOP rem "### main loop ###"
1005 cnt=cnt+1
1010 rem "--- get user input / update screen ---"
1020 if sc=0 then gosub DRAW_SCREEN_0
1021 if sc=1 then gosub HANDLER_SCREEN_1: rem "user input and screen update for screen 1 (dialer)"
1022 if sc=2 then gosub HANDLER_SCREEN_2
1023 if sc=3 then gosub HANDLER_SCREEN_3
1024 if sc=4 then gosub HANDLER_SCREEN_4

1026 rem if us=1 then print "{home}+";: us=0: goto MAIN_LOOP_1: rem "print a char when screen is updated"
1027 rem if us=0 then print "{home} ";: goto MAIN_LOOP_1: rem "remove the char when screen wasn't updated"

MAIN_LOOP_1 rem "--- get modem input ---"
1052 gosub POLL_MODEM

1080 rem "--- perform regular tasks ---"
1082 mdv=500: if fn mod(cnt)=0 then s$="at+csq"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "request signal quality report every 500 loops"

1098 rem "--- end main loop ---"
1099 goto MAIN_LOOP


POLL_MODEM rem "=== read from modem ==="
1101 rem "read one char from cellular modem and parse received fields"
1110 get#1,c$: if c$="" then return
1120 if c$=chr$(13) or c$=chr$(10) then goto HANDLE_MODEM_LINE
1130 if c$=":" and fc=0 then mf$(0)=mf$: fc=1: mf$="": rem "first field is separated with a column"
1140 if c$="," and fc>0 and fc<20 then mf$(fc)=mf$: fc=fc+1: mf$="": rem "other fields are separated with a comma; limit=20"
1150 if c$<>"," and c$<>":" then mf$=mf$+c$
1160 ml$=ml$+c$
1199 return

WRITE_STRING_TO_MODEM rem "=== send to modem ==="
1201 rem "send string in s$ to modem"
1210 for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
1299 return

WAIT_FOR_KEY_PRESS rem "=== read from keyboard ==="
1501 rem "receive one non-empty char from keyboard"
WFKP_LOOP u$="": get u$: if u$="" goto WFKP_LOOP
1599 return


1900 rem "### change SCREEN ###"
1901 rem "change the current screen"
1902 rem "it switches graphics/text mode only if necessary"
1903 rem "it triggers an initial update of the screen"

SWITCH_TO_SCREEN_0 rem "=== change to screen 0 (debug) ==="
1906 sc=0 
1907 gosub DRAW_SCREEN_0
1909 return

SWITCH_TO_SCREEN_1 rem "=== change to screen 1 ==="
1912 sc=1
1914 if peek(53272)=22 or peek(53272)=134 then poke 53272,21: rem "we want graphics mode"
1916 gosub DRAW_SCREEN_1: rem "trigger initial screen update"
1919 return

SWITCH_TO_SCREEN_2 rem "=== change to screen 2 ==="
1922 sc=2
1924 if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
1926 gosub DRAW_SCREEN_2: rem "trigger initial screen update"
1929 return

SWITCH_TO_SCREEN_3 rem "=== change to screen 3 ==="
1932 sc=3
1934 if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
1936 gosub DRAW_SCREEN_3: rem "trigger initial screen update"
1939 return

SWITCH_TO_SCREEN_4 rem "=== change to screen 4 ==="
1942 sc=4
1944 if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
1946 gosub DRAW_SCREEN_4: rem "trigger initial screen update"
1949 return


HANDLE_MODEM_LINE rem "### handle modem line ###"

2101 rem "received complete line from modem"
2102 if mf$<>"" and fc<20 then mf$(fc)=mf$: fc=fc+1
2105 if ml$="" then return
2110 if db=1 then print "modem line: ";ml$
2120 if db=1 then print "modem field count: ";fc
2130 if db=1 then print "modem fields: ";
2140 if db=1 then for i=0 to(fc-1): print"[";mf$(i);"]",: next i
2180 f1$="": ml$="": fc=0: mf$=""
2190 mn=0

2199 rem "=== List of all messages ==="

2200 rem "--- URC (Unsollicited Result Codes) ---"
2201 if mf$(0)="+creg" then mn=1
2203 if mf$(0)="+cgreg" then mn=3
2205 if mf$(0)="+ctzv" then mn=5
2206 if mf$(0)="+ctze" then mn=6
2207 if mf$(0)="+cmti" then mn=7
2208 if mf$(0)="+cmt" then mn=8
2210 if mf$(0)="^hcmt" then mn=10
2211 if mf$(0)="+cbm" then mn=11
2213 if mf$(0)="+cds" then mn=13
2215 if mf$(0)="+cdsi" then mn=15
2216 if mf$(0)="^hcds" then mn=16
2217 if mf$(0)="+colp" then mn=17
2218 if mf$(0)="+clip" then mn=18
2219 if mf$(0)="+cring" then mn=19
2220 if mf$(0)="+ccwa" then mn=20
2221 if mf$(0)="+cssi" then mn=21
2222 if mf$(0)="+cssu" then mn=22
2223 if mf$(0)="+cusd" then mn=23
2224 if mf$(0)="rdy" then mn=24
2225 if mf$(0)="+cfun" then mn=25
2226 if mf$(0)="+cpin" then mn=26
2227 if mf$(0)="+qind" then mn=27
2229 if mf$(0)="powered down" then mn=29
2230 if mf$(0)="+cgev" then mn=30

2239 rem "--- Result Codes ---"
2240 if mf$(0)="ok" then mn=40
2241 if mf$(0)="connect" then mn=41
2242 if mf$(0)="ring" then mn=42
2243 if mf$(0)="no carrier" then mn=43
2244 if mf$(0)="error" then mn=44
2246 if mf$(0)="no dialtone" then mn=46
2247 if mf$(0)="busy" then mn=47
2248 if mf$(0)="no answer" then mn=48

2250 rem "--- AT commands responses ---"
2251 if mf$(0)="+clcc" then mn=51
2252 if mf$(0)="+csq" then mn=52

2300 rem "=== Jump to handler ==="
2310 if db=1 then print "message is type";mn
2320 rem "Check if jumptable is set for this message type, if so, call handler"
2330 ln=jt%(mn): if ln>0 then gosub GOTO_LN

2999 return

HANDLER_SCREEN_1 rem "### SC 1 (DIALER) HANDLER ###"
3002 rem "read input chars and update string (phone number)"
3009 if su=1 then gosub DRAW_SCREEN_1: su=0
3010 u$="": get u$
3012 if fn m1k(cnt)=0 then gosub DRAW_SCREEN_1: rem "we trigger a screen update every 1000 loops"
3013 tmr=tmr-1: if tmr=0 then gosub DRAW_SCREEN_1_TILES: us=1: rem "we trigger a dial tiles update every 1000 loops since last"
3014 if u$="" then return
3020 if u$<>chr$(20) and u$<>chr$(13) and len(nb$)>=19 then return: rem "limit length is 18, go to loop start"
3030 if u$="0" or u$="1" or u$="2" or u$="3" or u$="4" or u$="5" or u$="6" or u$="7" or u$="8" or u$="9" or u$="+" or u$="*" or u$="#" or u$="a" or u$="b" or u$="c" or u$="d" then nb$=nb$+u$: gosub DRAW_SCREEN_1
3035 if u$="-" or u$="/" or u$="=" or u$="@" or u$="<" or u$=">" then gosub DRAW_SCREEN_1: rem "these characters don't update the string (for now)"
3040 if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): gosub DRAW_SCREEN_1: rem "remove a character, but only if there's at least one"
3050 if u$=chr$(13) then gosub DRAW_SCREEN_1: gosub SWITCH_TO_SCREEN_4: s$="atd"+nb$+";"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "dial the number and switch to screen 4"
3099 return

HANDLER_SCREEN_2 rem "### SC 2 (RING) HANDLER ###"
3110 if su=1 then gosub DRAW_SCREEN_2: su=0
3112 if fn m1k(cnt)=0 then gosub DRAW_SCREEN_2
3120 u$="": get u$
3122 if u$="a" or u$="A" then goto HS2_A
3124 if u$="r" or u$="R" then goto HS2_R
3126 return: rem "unexpected char"
HS2_A rem "--- Answer call (A) ---"
3160 s$="ata"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send ATA (answer)"
3162 gosub SWITCH_TO_SCREEN_3: rem "SCREEN 3 (IN-CALL)"
3164 rem "we should wait for OK (OR ERROR)!!"
3165 return
HS2_R rem "--- Decline call (R) ---"
3190 s$="at+chup"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send AT+CHUP (call hang up)"
3192 gosub SWITCH_TO_SCREEN_1: rem "SCREEN 1 (DIALER)"
3194 rem "we should wait for OK (OR ERROR)!!"
3199 return

HANDLER_SCREEN_3 rem "### SC 3 (IN-CALL) HANDLER ###"
3110 if su=1 then gosub DRAW_SCREEN_3: su=0
3112 if fn m1k(cnt)=0 then gosub DRAW_SCREEN_3
3220 u$="": get u$
3222 if u$="h" or u$="H" then goto HS3_H
3226 return: rem "not H"
HS3_H rem "--- Hang-up call (H) ---"
3260 s$="at+chup"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send AT+CHUP (call hang up)"
3262 gosub SWITCH_TO_SCREEN_1: rem "SCREEN 1 (DIALER)"
3264 rem "we should wait for OK (OR ERROR)!!"
3299 return

HANDLER_SCREEN_4 rem "### SC 4 (DIALLING) HANDLER ###"
3310 if su=1 then gosub DRAW_SCREEN_4: su=0
3312 if fn m1k(cnt)=0 then gosub DRAW_SCREEN_4
3320 u$="":get u$
3322 if u$="h" or u$="H" then goto HS4_H
3326 return: rem "not H"
HS4_H rem "--- Hang-up call (H) ---"
3360 s$="ath"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send ATH (hang up)"
3362 gosub SWITCH_TO_SCREEN_1: rem "SCREEN 1 (DIALER)"
3364 rem "we should wait for OK (OR ERROR)!!"
3366 dr$="": rem "reset dialling result"
3399 return

DRAW_SCREEN_1 rem "### SC 1 (DIALER) SCREEN UPDATE ###"
5001 rem "=== dialer screen update subroutine ==="
5010 gosub DRAW_SCREEN_1_TEXT: gosub DRAW_SCREEN_1_TILES: gosub STAMP_SIGNAL_BARS: rem "call update subroutines"
5020 us=1
5099 return

DRAW_SCREEN_1_TEXT rem "=== screen text update ==="
5110 print "{clr}";: rem "clr text"
5120 print "{yel}";: rem "yellow text"
5130 print "UCCCCCCCCCCCCCCCCCCCI"
5140 print "B                   B"
5150 print "B";
5152 print nb$;
5154 for j=1 to 19-len(nb$): if len(nb$)<19 then print " ";: next j: rem "special case: for i=1 to 0 still goes into loop, so if len()=max we don't wanna print a space; TODO: use SPC(x) command!"
5156 print "B"
5160 print "B                   B"
5170 print "JCCCCCCCCCCCCCCCCCCCK"

5180 rem "BER is always 99" xx=35: yy=3: gosub MOVE_CURSOR_XX_YY: print "ber";ber$;: rem "print the BER under signal strength"

5199 return

DRAW_SCREEN_1_TILES rem "=== screen dial tiles update ==="
5205 tmr=1000: rem "reinitialize timer"
5210 for x=1 to 3: for y=1 to 3
5212 if val(u$)=x+(y-1)*3 then gosub STAMP_1_TO_9_PRESSED: goto NEXTYX
5213 gosub STAMP_1_TO_9
NEXTYX next y,x
T1 if u$="#" then gosub STAMP_HASH_PRESSED: goto T2
5221 gosub STAMP_HASH
T2 if u$="0" then gosub STAMP_0_PRESSED: goto T3
5223 gosub STAMP_0
T3 if u$="*" then gosub STAMP_STAR_PRESSED: goto T4
5225 gosub STAMP_STAR
T4 if u$=chr$(13) then gosub STAMP_GREENPHONE_PRESSED: goto T5
5231 gosub STAMP_GREENPHONE
T5 if u$="+" then gosub STAMP_PLUS_PRESSED: goto T6
5233 gosub STAMP_PLUS
T6 if u$=chr$(20) then gosub STAMP_BACKSPACE_PRESSED: goto T7
5235 gosub STAMP_BACKSPACE
T7 if u$="-" then gosub STAMP_MINUS_PRESSED: goto T8
5241 gosub STAMP_MINUS
T8 if u$="/" then gosub STAMP_DIVIDE_PRESSED: goto T9
5243 gosub STAMP_DIVIDE
T9 if u$="=" then gosub STAMP_EQUAL_PRESSED: goto T10
5245 gosub STAMP_EQUAL
T10 if u$="@" then gosub STAMP_SATTELITE_PRESSED: goto T11
5247 gosub STAMP_SATTELITE
T11 if u$="<" or u$=">" then gosub STAMP_DUALSIM_PRESSED: goto T99
5249 gosub STAMP_DUALSIM
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
5410 canvas 40+1+sl% stamp on canvas 0 at 40-5,0: rem "print the signal level canvas in the top right-hand corner"
5499 return

MOVE_CURSOR_XX_YY rem "=== move the cursor to position xx,yy ==="
5910 print "{home}";
5920 if xx>0 then for i=1 to xx: print "{rght}";: next i
5930 if yy>0 then for j=1 to yy: print "{down}";: next j
5999 return

DRAW_SCREEN_2 rem "### SC 2 (RING) SCREEN UPDATE ###"
6002 us=1
6005 canvas 0 clr : print "{clr}";
6010 print "Incoming call!"
6020 if cid$<>"" then print "Caller: ";cid$: goto DS2_K
6030 print "{down}";
DS2_K print "{down}[a]ccept or [r]eject?"
6099 return

DRAW_SCREEN_3 rem "### SC 3 (IN-CALL) SCREEN UPDATE ###"
6102 us=1
6105 canvas 0 clr : print "{clr}";
6110 print "In-call with ";cid$
6120 print "{down}[h]ang up"
6199 return

DRAW_SCREEN_4 rem "### SC 4 (DIALLING) SCREEN UPDATE ###"
6202 us=1
6205 canvas 0 clr : print "{clr}";
6210 print "Dialling ";nb$
6220 if dr$<>"" then print dr$: goto DS3_K
6230 print "{down}";
DS3_K print "{down}[h]ang up"
6299 return

DRAW_SCREEN_0 rem "### SC 0 (DEBUG) SCREEN UPDATE ###"
9010 rem "we don't clr or print, and let debug messages be"
9099 return


9999 rem "### MESSAGE HANDLERS ###"

MESSAGE_HANDLER_0 rem "Message handler: unknown/free-form"
10099 return

MESSAGE_HANDLER_1 rem "Message handler: message type 1"
10199 return

MESSAGE_HANDLER_2 rem "Message handler: message type 2"
10299 return

MESSAGE_HANDLER_3 rem "Message handler: message type 3"
10399 return

MESSAGE_HANDLER_4 rem "Message handler: message type 4"
10499 return

MESSAGE_HANDLER_5 rem "Message handler: message type 5"
10599 return

MESSAGE_HANDLER_6 rem "Message handler: message type 6"
10699 return

MESSAGE_HANDLER_7 rem "Message handler: message type 7"
10799 return

MESSAGE_HANDLER_8 rem "Message handler: message type 8"
10899 return

MESSAGE_HANDLER_9 rem "Message handler: message type 9"
10999 return

MESSAGE_HANDLER_10 rem "Message handler: message type 10"
11099 return

MESSAGE_HANDLER_11 rem "Message handler: message type 11"
11199 return

MESSAGE_HANDLER_12 rem "Message handler: message type 12"
11299 return

MESSAGE_HANDLER_13 rem "Message handler: message type 13"
11399 return

MESSAGE_HANDLER_14 rem "Message handler: message type 14"
11499 return

MESSAGE_HANDLER_15 rem "Message handler: message type 15"
11599 return

MESSAGE_HANDLER_16 rem "Message handler: message type 16"
11699 return

MESSAGE_HANDLER_17 rem "Message handler: message type 17"
11799 return

MESSAGE_HANDLER_18 rem "Message handler: message type 18"
11899 return

MESSAGE_HANDLER_19 rem "Message handler: message type 19"
11999 return

MESSAGE_HANDLER_20 rem "Message handler: message type 20"
12099 return

MESSAGE_HANDLER_21 rem "Message handler: message type 21"
12199 return

MESSAGE_HANDLER_22 rem "Message handler: message type 22"
12299 return

MESSAGE_HANDLER_23 rem "Message handler: message type 23"
12399 return

MESSAGE_HANDLER_24 rem "Message handler: message type 24"
12499 return

MESSAGE_HANDLER_25 rem "Message handler: message type 25"
12599 return

MESSAGE_HANDLER_26 rem "Message handler: message type 26"
12699 return

MESSAGE_HANDLER_27 rem "Message handler: message type 27"
12799 return

MESSAGE_HANDLER_28 rem "Message handler: message type 28"
12899 return

MESSAGE_HANDLER_29 rem "Message handler: message type 29"
12999 return

MESSAGE_HANDLER_30 rem "Message handler: message type 30"
13099 return

MESSAGE_HANDLER_31 rem "Message handler: message type 31"
13199 return

MESSAGE_HANDLER_32 rem "Message handler: message type 32"
13299 return

MESSAGE_HANDLER_33 rem "Message handler: message type 33"
13399 return

MESSAGE_HANDLER_34 rem "Message handler: message type 34"
13499 return

MESSAGE_HANDLER_35 rem "Message handler: message type 35"
13599 return

MESSAGE_HANDLER_36 rem "Message handler: message type 36"
13699 return

MESSAGE_HANDLER_37 rem "Message handler: message type 37"
13799 return

MESSAGE_HANDLER_38 rem "Message handler: message type 38"
13899 return

MESSAGE_HANDLER_39 rem "Message handler: message type 39"
13999 return

MESSAGE_HANDLER_OK rem "Message handler: OK"
14010 if sc=4 then dia=1: s$="at+clcc"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "ATD succeeded, dialling..."
14099 return

MESSAGE_HANDLER_41 rem "Message handler: message type 41"
14199 return

MESSAGE_HANDLER_RING rem "Message handler: incoming call (ring)"
14205 s$="at+clcc"+chr$(13):gosub WRITE_STRING_TO_MODEM: rem "send AT+CLCC (list current calls)"
14210 if sc<>2 then gosub SWITCH_TO_SCREEN_2: rem "SCREEN 2 (RING)"
14299 return

MESSAGE_HANDLER_NO_CARRIER rem "Message handler: no carrier"
14310 rem "TODO: depending on which screen we are, we can set different messages to be displayed to the user when the call is hung up"
14311 if sc=1 then s$="ath"+chr$(13): gosub WRITE_STRING_TO_MODEM: gosub SWITCH_TO_SCREEN_1: cid$="": return
14312 if sc=2 then s$="ath"+chr$(13): gosub WRITE_STRING_TO_MODEM: gosub SWITCH_TO_SCREEN_1: cid$="": return
14313 if sc=3 then s$="ath"+chr$(13): gosub WRITE_STRING_TO_MODEM: gosub SWITCH_TO_SCREEN_1: cid$="": return
14314 if sc=4 then dr$="connection cannot be established"
14399 return

MESSAGE_HANDLER_44 rem "Message handler: message type 44"
14499 return

MESSAGE_HANDLER_45 rem "Message handler: message type 45"
14599 return

MESSAGE_HANDLER_NO_DIAL_TONE rem "Message handler: no dial tone"
14610 if sc=4 then dr$="no dial tone"
14699 return

MESSAGE_HANDLER_BUSY rem "Message handler: busy"
14710 if sc=4 then dr$="target is busy"
14799 return

MESSAGE_HANDLER_NO_ANSWER rem "Message handler: no answer"
14899 return

MESSAGE_HANDLER_49 rem "Message handler: message type 49"
14999 return

MESSAGE_HANDLER_50 rem "Message handler: message type 50"
15099 return

MESSAGE_HANDLER_+CLCC rem "Message handler: +clcc (list current calls)"
15110 if sc<>4 and mf$(4)="0" then cid$=right$(left$(mf$(6),len(mf$(6))-1),len(mf$(6))-2): su=1
15150 if sc=4 and dia=1 and mf$(4)="0" then goto CLCC_DIALLING
15160 return
CLCC_DIALLING if mf$(3)="2" then dr$="Dialling...": su=1
15172 if mf$(3)="3" then dr$="Alerting target...!": su=1
15174 if mf$(3)="0" then dr$="": cid$=nb$: gosub SWITCH_TO_SCREEN_3: rem "call is active, switch to screen 3"
15179 s$="at+clcc"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send again the at+clcc command"
15199 return

MESSAGE_HANDLER_+CSQ rem "Message handler: +csq (signal quality report)"
15210 rssi=val(mf$(1)): ber=val(mf$(2))
15220 if rssi=99 or rssi=199 then sl%=0
15222 if rssi>=0 and rssi<=31 then sl%=int((rssi/32*5)+1)
15224 if rssi>=100 and rssi<=191 then sl%=int(((rssi-100)/92*5)+1)
15230 if ber>=0 and ber<=7 then ber$=str$(ber)
15232 if ber=99 then ber$="?"
15298 su=1: rem "trigger screen update"
15299 return

MESSAGE_HANDLER_53 rem "Message handler: message type 53"
15399 return

MESSAGE_HANDLER_54 rem "Message handler: message type 54"
15499 return

MESSAGE_HANDLER_55 rem "Message handler: message type 55"
15599 return

MESSAGE_HANDLER_56 rem "Message handler: message type 56"
15699 return

MESSAGE_HANDLER_57 rem "Message handler: message type 57"
15799 return

MESSAGE_HANDLER_58 rem "Message handler: message type 58"
15899 return

MESSAGE_HANDLER_59 rem "Message handler: message type 59"
15999 return

MESSAGE_HANDLER_60 rem "Message handler: message type 60"
16099 return

MESSAGE_HANDLER_61 rem "Message handler: message type 61"
16199 return

MESSAGE_HANDLER_62 rem "Message handler: message type 62"
16299 return

MESSAGE_HANDLER_63 rem "Message handler: message type 63"
16399 return

MESSAGE_HANDLER_64 rem "Message handler: message type 64"
16499 return

MESSAGE_HANDLER_65 rem "Message handler: message type 65"
16599 return

MESSAGE_HANDLER_66 rem "Message handler: message type 66"
16699 return

MESSAGE_HANDLER_67 rem "Message handler: message type 67"
16799 return

MESSAGE_HANDLER_68 rem "Message handler: message type 68"
16899 return

MESSAGE_HANDLER_69 rem "Message handler: message type 69"
16999 return

MESSAGE_HANDLER_70 rem "Message handler: message type 70"
17099 return

MESSAGE_HANDLER_71 rem "Message handler: message type 71"
17199 return

MESSAGE_HANDLER_72 rem "Message handler: message type 72"
17299 return

MESSAGE_HANDLER_73 rem "Message handler: message type 73"
17399 return

MESSAGE_HANDLER_74 rem "Message handler: message type 74"
17499 return

MESSAGE_HANDLER_75 rem "Message handler: message type 75"
17599 return

MESSAGE_HANDLER_76 rem "Message handler: message type 76"
17699 return

MESSAGE_HANDLER_77 rem "Message handler: message type 77"
17799 return

MESSAGE_HANDLER_78 rem "Message handler: message type 78"
17899 return

MESSAGE_HANDLER_79 rem "Message handler: message type 79"
17999 return

MESSAGE_HANDLER_80 rem "Message handler: message type 80"
18099 return

MESSAGE_HANDLER_81 rem "Message handler: message type 81"
18199 return

MESSAGE_HANDLER_82 rem "Message handler: message type 82"
18299 return

MESSAGE_HANDLER_83 rem "Message handler: message type 83"
18399 return

MESSAGE_HANDLER_84 rem "Message handler: message type 84"
18499 return

MESSAGE_HANDLER_85 rem "Message handler: message type 85"
18599 return

MESSAGE_HANDLER_86 rem "Message handler: message type 86"
18699 return

MESSAGE_HANDLER_87 rem "Message handler: message type 87"
18799 return

MESSAGE_HANDLER_88 rem "Message handler: message type 88"
18899 return

MESSAGE_HANDLER_89 rem "Message handler: message type 89"
18999 return

MESSAGE_HANDLER_90 rem "Message handler: message type 90"
19099 return

MESSAGE_HANDLER_91 rem "Message handler: message type 91"
19199 return

MESSAGE_HANDLER_92 rem "Message handler: message type 92"
19299 return

MESSAGE_HANDLER_93 rem "Message handler: message type 93"
19399 return

MESSAGE_HANDLER_94 rem "Message handler: message type 94"
19499 return

MESSAGE_HANDLER_95 rem "Message handler: message type 95"
19599 return

MESSAGE_HANDLER_96 rem "Message handler: message type 96"
19699 return

MESSAGE_HANDLER_97 rem "Message handler: message type 97"
19799 return

MESSAGE_HANDLER_98 rem "Message handler: message type 98"
19899 return

MESSAGE_HANDLER_99 rem "Message handler: message type 99"
19999 return

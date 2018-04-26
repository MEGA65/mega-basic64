1 poke 53280,0: poke 53281,0: rem "border and screen color (0: black)"
2 poke 0,65: rem "fast mode (50mhz cpu clock)"
3 poke 53248+111,128: rem "fix screen artifacts (60hz display)"

9 print chr$(147);: canvas 0 clr: rem "clear screen"


10 rem "### initialization ###"
11 gosub 100: rem "one-time only lookup patch address"
12 gosub 300: rem "program state setup"
13 gosub 400: gosub 500: rem "modem parser and modem setup"
14 gosub 600: rem "GUI-related setup"

80 rem "--- functions definition ---"
81 def fn m6(x) = x-(int(x/6)*6): rem "x modulo 6; x % 6"
82 def fn m1k(x) = x-(int(x/1000)*1000): rem "x modulo 1000; x % 1000"
85 mdv=1 : rem "modulo divisor"
86 def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"


90 if db=1 then gosub 1900: goto 99: rem "if db=1, sc=0 (debug screen)"
91 gosub 1910: rem "start the program on screen 1 (dialer)"
99 goto 1000


100 rem "=== goto,X lookup of patch address"
101 for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next: return
199 return

200 rem "=== goto X subroutine ==="
201 rem "goes to line ln, if ln>0"
210 ln$=str$(ln): if ln<=0 then return
220 for i=0 to 5: poke ja+i,32:next: rem "first rub out with spaces in case line number is short"
230 for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
240 if ln>0 then gosub,00000: rem "gosub to line ln"
250 poke ja,44: rem "put the comma back in case we want to run again"
299 return

300 rem "=== program flags and variables setup ==="
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

400 rem "=== setup for modem parser ==="
410 dim mf$(20): rem "fields from colon-comma formatted messages"
420 dim ol$(20): rem "lines from modem that don't conform to any normal message format"
430 dim jt%(100): rem "jump table for message handling"
440 for i=0 to 99: jt%(i)=10000+100*i: next i
450 open 1,2,1
499 return

500 rem "=== modem setup ==="
510 s$="ate0"+chr$(13): gosub 1200: rem "no echo from modem"
599 return

600 rem "=== GUI-related setup ==="
610 u$="": nb$="": rem "user-input char and number initialization"
630 sl%=0: rem "Signal Level integer [0:5]"
635 ber$="?": rem "Bit Error Rate string to be displayed"
650 tmr=1000: rem "timer for keystrokes"
699 return


1000 rem "### main loop ###"
1005 cnt=cnt+1
1010 rem "--- get user input / update screen ---"
1020 if sc=0 then gosub 9000
1021 if sc=1 then gosub 3000: rem "user input and screen update for screen 1 (dialer)"
1022 if sc=2 then gosub 3100
1023 if sc=3 then gosub 3200
1024 if sc=4 then gosub 3300

1026 rem if us=1 then print "{home}+";: us=0: goto 1050: rem "print a char when screen is updated"
1027 rem if us=0 then print "{home} ";: goto 1050: rem "remove the char when screen wasn't updated"

1050 rem "--- get modem input ---"
1052 gosub 1100

1080 rem "--- perform regular tasks ---"
1082 mdv=500: if fn mod(cnt)=0 then s$="at+csq"+chr$(13): gosub 1200: rem "request signal quality report every 500 loops"

1098 rem "--- end main loop ---"
1099 goto 1000


1100 rem "=== read from modem ==="
1101 rem "read one char from cellular modem and parse received fields"
1110 get#1,c$: if c$="" then return
1120 if c$=chr$(13) or c$=chr$(10) then goto 2000
1130 if c$=":" and fc=0 then mf$(0)=mf$: fc=1: mf$="": rem "first field is separated with a column"
1140 if c$="," and fc>0 and fc<20 then mf$(fc)=mf$: fc=fc+1: mf$="": rem "other fields are separated with a comma; limit=20"
1150 if c$<>"," and c$<>":" then mf$=mf$+c$
1160 ml$=ml$+c$
1199 return

1200 rem "=== send to modem ==="
1201 rem "send string in s$ to modem"
1210 for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
1299 return

1500 rem "=== read from keyboard ==="
1501 rem "receive one non-empty char from keyboard"
1510 u$="": get u$: if u$="" goto 5110
1599 return


1900 rem "### change SCREEN ###"
1901 rem "change the current screen"
1902 rem "it switches graphics/text mode only if necessary"
1903 rem "it triggers an initial update of the screen"

1905 rem "=== change to screen 0 (debug) ==="
1906 sc=0 
1907 gosub 9000
1909 return

1910 rem "=== change to screen 1 ==="
1912 sc=1
1914 if peek(53272)=22 or peek(53272)=134 then poke 53272,21: rem "we want graphics mode"
1916 gosub 5000: rem "trigger initial screen update"
1919 return

1920 rem "=== change to screen 2 ==="
1922 sc=2
1924 if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
1926 gosub 6000: rem "trigger initial screen update"
1929 return

1930 rem "=== change to screen 3 ==="
1932 sc=3
1934 if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
1936 gosub 6100: rem "trigger initial screen update"
1939 return

1940 rem "=== change to screen 4 ==="
1942 sc=4
1944 if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
1946 gosub 6200: rem "trigger initial screen update"
1949 return



2000 rem "### handle modem line ###"

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
2330 ln=jt%(mn): if ln>0 then gosub 200

2999 return


3000 rem "### SC 1 (DIALER) HANDLER ###"
3002 rem "read input chars and update string (phone number)"
3009 if su=1 then gosub 5000: su=0
3010 u$="": get u$
3012 if fn m1k(cnt)=0 then gosub 5000: rem "we trigger a screen update every 1000 loops"
3013 tmr=tmr-1: if tmr=0 then gosub 5200: us=1: rem "we trigger a dial tiles update every 1000 loops since last"
3014 if u$="" then return
3020 if u$<>chr$(20) and u$<>chr$(13) and len(nb$)>=19 then return: rem "limit length is 18, go to loop start"
3030 if u$="0" or u$="1" or u$="2" or u$="3" or u$="4" or u$="5" or u$="6" or u$="7" or u$="8" or u$="9" or u$="+" or u$="*" or u$="#" or u$="a" or u$="b" or u$="c" or u$="d" then nb$=nb$+u$: gosub 5000
3035 if u$="-" or u$="/" or u$="=" or u$="@" or u$="<" or u$=">" then gosub 5000: rem "these characters don't update the string (for now)"
3040 if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): gosub 5000: rem "remove a character, but only if there's at least one"
3050 if u$=chr$(13) then gosub 5000: gosub 1940: s$="atd"+nb$+";"+chr$(13): gosub 1200: rem "dial the number and switch to screen 4"
3099 return

3100 rem "### SC 2 (RING) HANDLER ###"
3110 if su=1 then gosub 6000: su=0
3112 if fn m1k(cnt)=0 then gosub 6000
3120 u$="": get u$
3122 if u$="a" or u$="A" then goto 3150
3124 if u$="r" or u$="R" then goto 3180
3126 return: rem "unexpected char"
3150 rem "--- Answer call (A) ---"
3160 s$="ata"+chr$(13): gosub 1200: rem "send ATA (answer)"
3162 gosub 1930: rem "SCREEN 3 (IN-CALL)"
3164 rem "we should wait for OK (OR ERROR)!!"
3165 return
3180 rem "--- Decline call (R) ---"
3190 s$="at+chup"+chr$(13): gosub 1200: rem "send AT+CHUP (call hang up)"
3192 gosub 1910: rem "SCREEN 1 (DIALER)"
3194 rem "we should wait for OK (OR ERROR)!!"
3199 return

3200 rem "### SC 3 (IN-CALL) HANDLER ###"
3110 if su=1 then gosub 6100: su=0
3112 if fn m1k(cnt)=0 then gosub 6100
3220 u$="": get u$
3222 if u$="h" or u$="H" then goto 3250
3226 return: rem "not H"
3250 rem "--- Hang-up call (H) ---"
3260 s$="at+chup"+chr$(13): gosub 1200: rem "send AT+CHUP (call hang up)"
3262 gosub 1910: rem "SCREEN 1 (DIALER)"
3264 rem "we should wait for OK (OR ERROR)!!"
3299 return

3300 rem "### SC 4 (DIALLING) HANDLER ###"
3310 if su=1 then gosub 6200: su=0
3312 if fn m1k(cnt)=0 then gosub 6200
3320 u$="":get u$
3322 if u$="h" or u$="H" then goto 3350
3326 return: rem "not H"
3350 rem "--- Hang-up call (H) ---"
3360 s$="ath"+chr$(13): gosub 1200: rem "send ATH (hang up)"
3362 gosub 1910: rem "SCREEN 1 (DIALER)"
3364 rem "we should wait for OK (OR ERROR)!!"
3366 dr$="": rem "reset dialling result"
3399 return

5000 rem "### SC 1 (DIALER) SCREEN UPDATE ###"
5001 rem "=== dialer screen update subroutine ==="
5010 gosub 5100: gosub 5200: gosub 5400: rem "call update subroutines"
5020 us=1
5099 return

5100 rem "=== screen text update ==="
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

5180 rem "BER is always 99" xx=35: yy=3: gosub 5900: print "ber";ber$;: rem "print the BER under signal strength"

5199 return

5200 rem "=== screen dial tiles update ==="
5205 tmr=1000: rem "reinitialize timer"
5210 for x=1 to 3: for y=1 to 3
5212 if val(u$)=x+(y-1)*3 then gosub 5312: goto 5214
5213 gosub 5313
5214 next y,x
5220 if u$="#" then gosub 5320: goto 5222
5221 gosub 5321
5222 if u$="0" then gosub 5322: goto 5224
5223 gosub 5323
5224 if u$="*" then gosub 5324: goto 5230
5225 gosub 5325
5230 if u$=chr$(13) then gosub 5330: goto 5232
5231 gosub 5331
5232 if u$="+" then gosub 5332: goto 5234
5233 gosub 5333
5234 if u$=chr$(20) then gosub 5334: goto 5240
5235 gosub 5335
5240 if u$="-" then gosub 5340: goto 5242
5241 gosub 5341
5242 if u$="/" then gosub 5342: goto 5244
5243 gosub 5343
5244 if u$="=" then gosub 5344: goto 5246
5245 gosub 5345
5246 if u$="@" then gosub 5346: goto 5299
5247 gosub 5347
5248 if u$="<" or u$=">" then gosub 5348: goto 5299
5249 gosub 5349
5299 return

5312 canvas x+(y-1)*3+1+20 stamp on canvas 0 at x*5-4,y*4+1: return: rem "1 to 9 (pressed)"
5313 canvas x+(y-1)*3+1 stamp on canvas 0 at x*5-4,y*4+1: return: rem "1 to 9"
5320 canvas 11+20 stamp on canvas 0 at 1,17: return: rem "# (pressed)"
5321 canvas 11 stamp on canvas 0 at 1,17: return: rem "#"
5322 canvas 1+20 stamp on canvas 0 at 6,17: return: rem "0 (pressed)"
5323 canvas 1 stamp on canvas 0 at 6,17: return: rem "0"
5324 canvas 12+20 stamp on canvas 0 at 11,17: return: rem "* (pressed)"
5325 canvas 12 stamp on canvas 0 at 11,17: return: rem "*"
5330 canvas 18+20 stamp on canvas 0 at 1,21: return: rem "greephone (pressed)"
5331 canvas 18 stamp on canvas 0 at 1,21: return: rem "greephone"
5332 canvas 15+20 stamp on canvas 0 at 6,21: return: rem "+ (pressed)"
5333 canvas 15 stamp on canvas 0 at 6,21: return: rem "+"
5334 canvas 17+20 stamp on canvas 0 at 11,21: return: rem "backspace (pressed)"
5335 canvas 17 stamp on canvas 0 at 11,21: return: rem "backspace"
5340 canvas 14+20 stamp on canvas 0 at 16,9: return: rem "- (pressed)"
5341 canvas 14 stamp on canvas 0 at 16,9: return: rem "-"
5342 canvas 13+20 stamp on canvas 0 at 16,13: return: rem "divide (pressed)"
5343 canvas 13 stamp on canvas 0 at 16,13: return: rem "divide"
5344 canvas 16+20 stamp on canvas 0 at 16,17: return: rem "= (pressed)"
5345 canvas 16 stamp on canvas 0 at 16,17: return: rem "="
5346 canvas 20+20 stamp on canvas 0 at 16,5: return: rem "satellite (pressed)"
5347 canvas 20 stamp on canvas 0 at 16,5: return: rem "satellite"
5348 canvas 48 stamp on canvas 0 at 16,21: return: rem "dual sim (pressed)"
5349 canvas 47 stamp on canvas 0 at 16,21: return: rem "dual sim"

5400 rem "=== screen signal icon update ==="
5410 canvas 40+1+sl% stamp on canvas 0 at 40-5,0: rem "print the signal level canvas in the top right-hand corner"
5499 return

5900 rem "=== move the cursor to position xx,yy ==="
5910 print "{home}";
5920 if xx>0 then for i=1 to xx: print "{rght}";: next i
5930 if yy>0 then for j=1 to yy: print "{down}";: next j
5999 return

6000 rem "### SC 2 (RING) SCREEN UPDATE ###"
6002 us=1
6005 canvas 0 clr : print "{clr}";
6010 print "Incoming call!"
6020 if cid$<>"" then print "Caller: ";cid$: goto 6040
6030 print "{down}";
6040 print "{down}[a]ccept or [r]eject?"
6099 return

6100 rem "### SC 3 (IN-CALL) SCREEN UPDATE ###"
6102 us=1
6105 canvas 0 clr : print "{clr}";
6110 print "In-call with ";cid$
6120 print "{down}[h]ang up"
6199 return

6200 rem "### SC 4 (DIALLING) SCREEN UPDATE ###"
6202 us=1
6205 canvas 0 clr : print "{clr}";
6210 print "Dialling ";nb$
6220 if dr$<>"" then print dr$: goto 6240
6230 print "{down}";
6240 print "{down}[h]ang up"
6299 return

9000 rem "### SC 0 (DEBUG) SCREEN UPDATE ###"
9010 rem "we don't clr or print, and let debug messages be"
9099 return

9999 rem "### MESSAGE HANDLERS ###"

10000 rem "Message handler: unknown/free-form"
10099 return

10100 rem "Message handler: message type 1"
10199 return

10200 rem "Message handler: message type 2"
10299 return

10300 rem "Message handler: message type 3"
10399 return

10400 rem "Message handler: message type 4"
10499 return

10500 rem "Message handler: message type 5"
10599 return

10600 rem "Message handler: message type 6"
10699 return

10700 rem "Message handler: message type 7"
10799 return

10800 rem "Message handler: message type 8"
10899 return

10900 rem "Message handler: message type 9"
10999 return

11000 rem "Message handler: message type 10"
11099 return

11100 rem "Message handler: message type 11"
11199 return

11200 rem "Message handler: message type 12"
11299 return

11300 rem "Message handler: message type 13"
11399 return

11400 rem "Message handler: message type 14"
11499 return

11500 rem "Message handler: message type 15"
11599 return

11600 rem "Message handler: message type 16"
11699 return

11700 rem "Message handler: message type 17"
11799 return

11800 rem "Message handler: message type 18"
11899 return

11900 rem "Message handler: message type 19"
11999 return

12000 rem "Message handler: message type 20"
12099 return

12100 rem "Message handler: message type 21"
12199 return

12200 rem "Message handler: message type 22"
12299 return

12300 rem "Message handler: message type 23"
12399 return

12400 rem "Message handler: message type 24"
12499 return

12500 rem "Message handler: message type 25"
12599 return

12600 rem "Message handler: message type 26"
12699 return

12700 rem "Message handler: message type 27"
12799 return

12800 rem "Message handler: message type 28"
12899 return

12900 rem "Message handler: message type 29"
12999 return

13000 rem "Message handler: message type 30"
13099 return

13100 rem "Message handler: message type 31"
13199 return

13200 rem "Message handler: message type 32"
13299 return

13300 rem "Message handler: message type 33"
13399 return

13400 rem "Message handler: message type 34"
13499 return

13500 rem "Message handler: message type 35"
13599 return

13600 rem "Message handler: message type 36"
13699 return

13700 rem "Message handler: message type 37"
13799 return

13800 rem "Message handler: message type 38"
13899 return

13900 rem "Message handler: message type 39"
13999 return

14000 rem "Message handler: OK"
14010 if sc=4 then dia=1: s$="at+clcc"+chr$(13): gosub 1200: rem "ATD succeeded, dialling..."
14099 return

14100 rem "Message handler: message type 41"
14199 return

14200 rem "Message handler: incoming call (ring)"
14205 s$="at+clcc"+chr$(13):gosub 1200: rem "send AT+CLCC (list current calls)"
14210 if sc<>2 then gosub 1920: rem "SCREEN 2 (RING)"
14299 return

14300 rem "Message handler: no carrier"
14310 rem "TODO: depending on which screen we are, we can set different messages to be displayed to the user when the call is hung up"
14311 if sc=1 then s$="ath"+chr$(13): gosub 1200: gosub 1910: cid$="": return
14312 if sc=2 then s$="ath"+chr$(13): gosub 1200: gosub 1910: cid$="": return
14313 if sc=3 then s$="ath"+chr$(13): gosub 1200: gosub 1910: cid$="": return
14314 if sc=4 then dr$="connection cannot be established"
14399 return

14400 rem "Message handler: message type 44"
14499 return

14500 rem "Message handler: message type 45"
14599 return

14600 rem "Message handler: no dial tone"
14610 if sc=4 then dr$="no dial tone"
14699 return

14700 rem "Message handler: busy"
14710 if sc=4 then dr$="target is busy"
14799 return

14800 rem "Message handler: no answer"
14899 return

14900 rem "Message handler: message type 49"
14999 return

15000 rem "Message handler: message type 50"
15099 return

15100 rem "Message handler: +clcc (list current calls)"
15110 if sc<>4 and mf$(4)="0" then cid$=right$(left$(mf$(6),len(mf$(6))-1),len(mf$(6))-2): su=1
15150 if sc=4 and dia=1 and mf$(4)="0" then goto 15170
15160 return
15170 if mf$(3)="2" then dr$="Dialling...": su=1
15172 if mf$(3)="3" then dr$="Alerting target...!": su=1
15174 if mf$(3)="0" then dr$="": cid$=nb$: gosub 1930: rem "call is active, switch to screen 3"
15179 s$="at+clcc"+chr$(13): gosub 1200: rem "send again the at+clcc command"
15199 return

15200 rem "Message handler: +csq (signal quality report)"
15210 rssi=val(mf$(1)): ber=val(mf$(2))
15220 if rssi=99 or rssi=199 then sl%=0
15222 if rssi>=0 and rssi<=31 then sl%=int((rssi/32*5)+1)
15224 if rssi>=100 and rssi<=191 then sl%=int(((rssi-100)/92*5)+1)
15230 if ber>=0 and ber<=7 then ber$=str$(ber)
15232 if ber=99 then ber$="?"
15298 su=1: rem "trigger screen update"
15299 return

15300 rem "Message handler: message type 53"
15399 return

15400 rem "Message handler: message type 54"
15499 return

15500 rem "Message handler: message type 55"
15599 return

15600 rem "Message handler: message type 56"
15699 return

15700 rem "Message handler: message type 57"
15799 return

15800 rem "Message handler: message type 58"
15899 return

15900 rem "Message handler: message type 59"
15999 return

16000 rem "Message handler: message type 60"
16099 return

16100 rem "Message handler: message type 61"
16199 return

16200 rem "Message handler: message type 62"
16299 return

16300 rem "Message handler: message type 63"
16399 return

16400 rem "Message handler: message type 64"
16499 return

16500 rem "Message handler: message type 65"
16599 return

16600 rem "Message handler: message type 66"
16699 return

16700 rem "Message handler: message type 67"
16799 return

16800 rem "Message handler: message type 68"
16899 return

16900 rem "Message handler: message type 69"
16999 return

17000 rem "Message handler: message type 70"
17099 return

17100 rem "Message handler: message type 71"
17199 return

17200 rem "Message handler: message type 72"
17299 return

17300 rem "Message handler: message type 73"
17399 return

17400 rem "Message handler: message type 74"
17499 return

17500 rem "Message handler: message type 75"
17599 return

17600 rem "Message handler: message type 76"
17699 return

17700 rem "Message handler: message type 77"
17799 return

17800 rem "Message handler: message type 78"
17899 return

17900 rem "Message handler: message type 79"
17999 return

18000 rem "Message handler: message type 80"
18099 return

18100 rem "Message handler: message type 81"
18199 return

18200 rem "Message handler: message type 82"
18299 return

18300 rem "Message handler: message type 83"
18399 return

18400 rem "Message handler: message type 84"
18499 return

18500 rem "Message handler: message type 85"
18599 return

18600 rem "Message handler: message type 86"
18699 return

18700 rem "Message handler: message type 87"
18799 return

18800 rem "Message handler: message type 88"
18899 return

18900 rem "Message handler: message type 89"
18999 return

19000 rem "Message handler: message type 90"
19099 return

19100 rem "Message handler: message type 91"
19199 return

19200 rem "Message handler: message type 92"
19299 return

19300 rem "Message handler: message type 93"
19399 return

19400 rem "Message handler: message type 94"
19499 return

19500 rem "Message handler: message type 95"
19599 return

19600 rem "Message handler: message type 96"
19699 return

19700 rem "Message handler: message type 97"
19799 return

19800 rem "Message handler: message type 98"
19899 return

19900 rem "Message handler: message type 99"
19999 return

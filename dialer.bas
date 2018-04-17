0 poke 53295,asc("g"): poke 53295,asc("s"): poke 53248+111,128
1 poke 0,65: rem "fast mode"
2 print chr$(14);: rem "switch to upper/lower charset"

10 gosub 700: rem "one-time only lookup patch address"
20 gosub 800: rem "program state setup"
30 gosub 900: gosub 600
40 goto 500

200 rem "== goto X subroutine =="
201 rem "goes to line ln, if ln>0"
210 ln$=str$(ln): if ln<=0 then return
220 for i=0 to 5: poke ja+i,32:next: rem "first rub out with spaces in case line number is short"
230 for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
240 if ln>0 then gosub,00000: rem "gosub to line ln"
250 poke ja,44: rem "put the comma back in case we want to run again"
299 return

500 rem "=== main loop ==="
505 rem "--- get user input ---"
510 get a$: if a$<>"" then goto 550: rem "get one keyboard char"
520 goto 570
550 if sd=1 then print#1,a$;: goto 500: rem "send mode, send char to modem"
560 if sd=0 and ui=1 then 
570 rem "--- get modem input ---"
575 gosub 1000
598 rem "--- end main loop ---"
599 goto 500

600 rem "setup modem"
699 return

700 rem "jump table: one-time only lookup patch address"
701 for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next: return
799 return

800 rem "program state setup"
810 sd=1: rem "flag send: send characters typed on keyboard to modem right away"
820 ui=0: rem "flag ui (user input): we're waiting on a 1-char keyboard input from the user"
830 ring=0: rem "flag ring (incoming call)"
899 return

900 rem "setup for modem parser"
910 dim mf$(20): rem "fields from colon-comma formatted messages"
920 dim ol$(20): rem "lines from modem that don't conform to any normal message format"
930 dim jt%(100): rem "jump table for message handling"
940 for i=0 to 99: jt%(i)=10000+100*i: next i
950 open 1,2,1
999 return

1000 rem "read from cellular modem and parse received fields"
1010 get#1,c$: if c$="" then return
1020 if c$=chr$(13) or c$=chr$(10) then goto 1100
1030 if c$=":" and fc=0 then mf$(0)=mf$: fc=1: mf$="": rem "first field is separated with a column"
1040 if c$="," and fc>0 and fc<20 then mf$(fc)=mf$: fc=fc+1: mf$="": rem "other fields are separated with a comma; limit=20"
1050 if c$<>"," and c$<>":" then mf$=mf$+c$
1060 ml$=ml$+c$
1099 return

1100 rem "received complete line from modem"
1102 if mf$<>"" and fc<20 then mf$(fc)=mf$: fc=fc+1
1105 if ml$="" then return
1110 print "modem line: ";ml$
1120 print "modem field count: ";fc
1130 print "modem fields: ";
1140 for i=0 to(fc-1): print"[";mf$(i);"]",: next i
1150 print
1180 f1$="": ml$="": fc=0: mf$=""
1190 mn=0

1200 rem "Parse modem messages": rem "URC (Unsollicited Result Codes)"

1201 if mf$(0)="+creg" then mn=1
1203 if mf$(0)="+cgreg" then mn=3
1205 if mf$(0)="+ctzv" then mn=5
1206 if mf$(0)="+ctze" then mn=6
1207 if mf$(0)="+cmti" then mn=7
1208 if mf$(0)="+cmt" then mn=8

1210 if mf$(0)="^hcmt" then mn=10
1211 if mf$(0)="+cbm" then mn=11
1213 if mf$(0)="+cds" then mn=13
1215 if mf$(0)="+cdsi" then mn=15
1216 if mf$(0)="^hcds" then mn=16
1217 if mf$(0)="+colp" then mn=17
1218 if mf$(0)="+clip" then mn=18
1219 if mf$(0)="+cring" then mn=19

1220 if mf$(0)="+ccwa" then mn=20
1221 if mf$(0)="+cssi" then mn=21
1222 if mf$(0)="+cssu" then mn=22
1223 if mf$(0)="+cusd" then mn=23
1224 if mf$(0)="rdy" then mn=24
1225 if mf$(0)="+cfun" then mn=25
1226 if mf$(0)="+cpin" then mn=26
1227 if mf$(0)="+qind" then mn=27
1229 if mf$(0)="powered down" then mn=29

1230 if mf$(0)="+cgev" then mn=30

1239 rem "Result Codes"
1240 if mf$(0)="ok" then mn=40
1241 if mf$(0)="connect" then mn=41
1242 if mf$(0)="ring" then mn=42
1243 if mf$(0)="no carrier" then mn=43
1244 if mf$(0)="error" then mn=44
1246 if mf$(0)="no dialtone" then mn=46
1247 if mf$(0)="busy" then mn=47
1248 if mf$(0)="no answer" then mn=48

1250 rem "TODO: all other messages (responses to AT commands)"

1300 print "message is type";mn
1310 rem "Check if jumptable is set for this message type, if so, call handler"
1320 ln=jt%(mn): if ln>0 then gosub 200

1999 return


5000 rem "send string in s$ to modem"
5010 for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
5099 return

5100 rem "receive one non-empty char from keyboard"
5110 u$="": get u$: if u$="" goto 5110
5120 return

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

14000 rem "Message handler: message type 40"
14099 return

14100 rem "Message handler: message type 41"
14199 return

14200 rem "Message handler: incoming call (ring)"
14210 print "Incoming call! Do you want to answer it? y/n"
14215 gosub 5100
14220 if u$="y" or u$="Y" then goto 14250
14230 if u$="n" or u$="N" then goto 14280
14240 print "Type y or n": goto 14215: rem "unexpected char"
14250 rem "--- Answer call (Y) ---"
14260 s$="ata"+chr$(13): gosub 5000: rem "send ATA (answer)"
14265 return
14280 rem "--- Decline call (N) ---"
14290 s$="at+chup"+chr$(13): gosub 5000: rem "send AT+CHUP (call hang up)"
14295 return
14299 return

14300 rem "Message handler: message type 43"
14399 return

14400 rem "Message handler: message type 44"
14499 return

14500 rem "Message handler: message type 45"
14599 return

14600 rem "Message handler: message type 46"
14699 return

14700 rem "Message handler: message type 47"
14799 return

14800 rem "Message handler: message type 48"
14899 return

14900 rem "Message handler: message type 49"
14999 return

15000 rem "Message handler: message type 50"
15099 return

15100 rem "Message handler: message type 51"
15199 return

15200 rem "Message handler: message type 52"
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




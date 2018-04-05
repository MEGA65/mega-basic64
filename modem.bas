00 poke 0,65: rem "fast mode"
01 poke 53272,23: rem "upper/lower chars"

10 print "EC25 modem communication"
11 print "========================"
12 print "a - AT -> hello"
13 print "b - ATI -> request modem info"
14 print "c - AT+GSN -> request IMEI"
15 print "x - exit"

20 open 1,2,1

100 print ">";
110 u$="": get u$: if u$="" then goto 110
120 print u$
130 gosub 4000
140 if m$="" goto 100: rem "undefined command, try again"

150 print "tx: ["+m$+"]"
160 gosub 2000: rem "transmit the cmd"
170 print "rx: [";
180 gosub 3000: rem "get the response"
190 print r$+"]"

200 goto 100: rem "loop back at user input"

990 print "goobye"
999 end


1000 rem "read character by character"
1010 b$="": get#1,b$: if b$<>"" then print b$;
1020 return


2000 rem "write a string to the modem, working around the print# bug"
2010 for i=1 to len(m$): print#1,right$(left$(m$,i),1);: next: return


3000 rem "get the response from the modem"
3010 r$="": c$="": last$=""
3020 last$=c$: c$="": get#1,c$
3031 if c$="" and last$="" goto 3020: rem "empty chars at the beginning of the response"
3032 if c$="" and last$<>"" then return: rem "empty chars at the end of the response"
3033 if c$<>"" then r$=r$+c$: goto 3020
3040 return


4000 rem "switch on user input to get correct message for modem"
4005 m$=""
4010 if u$="a" then m$="at"+chr$(13): return
4020 if u$="b" then m$="ati"+chr$(13): return
4030 if u$="c" then m$="at+gsn"+chr$(13): return
4090 if u$="x" goto 990
4099 print "undefined command, try again": return

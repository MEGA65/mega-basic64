00 poke 0,65: rem "fast mode"
01 poke 53272,23: rem "upper/lower chars"
02 rem "poke 53359, peek(53359) or 128": rem "uncomment if trouble with display"


10 print "EC25 modem communication"
11 print "========================"
12 print "a - AT -> hello"
13 print "b - ATI -> request modem info"
14 print "c - AT+GSN -> request IMEI"
15 print "d - AT&V -> request current configuration"
16 print "e - AT+CIMI -> request IMSI#"
17 print "f - AT+QCCID -> request IC Card ID#"
18 print "g - AT+QPINC? -> display PIN remainder"
19 print "q - AT+CPIN? -> display PIN status"
20 print "h - AT+QINISTAT -> display SIM Initialisation status"
21 print "i - AT+COPS=? -> display avail operator selection (long wait)" : rem "?string too long error in 3033"
22 print "j - AT+COPS?  -> display curnt operator selection"
23 print "k - AT+CREG?  -> display network registration status"
24 print "l - AT+CSQ  -> display signal strength"
25 print "m - AT+COPN -> display operator names (much output)" : rem "?string too long error in 3033"
26 print "n - AT+QLTS -> display network time (if available)"
27 print "o - AT+QNWINFO -> display network info"
28 print "p - AT+QSPN    -> display name of registered network"
29 print "r - AT+CNUM    -> display subscriber number"
30 print "s - AT+<misc>  -> display phonebook info"
31 print "t - AT+<misc>  -> read SMS"
32 print "u - AT+<misc>  -> send SMS"
33 print "v - not implemented"
34 print "y - <enter listen mode>"
35 print "z - AT+QPOWD -> power off"
80 print "w - <custom command>"
85 print "x - exit"
91 print "1 - AT+QURCCFG='urcport','uart1' -> send URC (e.g. RING) on UART"
98 print "8 - parse last response from modem"
99 print "9 - print last response with invisible characters"

	
100 open 1,2,1
105 print ">";
110 u$="": get u$: if u$="" then goto 110
120 print u$
130 gosub 4000
140 if m$="" goto 105: rem "undefined command, try again"

150 gosub 2000: rem "transmit the cmd"
160 gosub 3000: rem "get the response"
170 print "tx: ["+m$+"]"
180 print "rx: ["+r$+"]"

200 goto 105: rem "loop back at user input"

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
4012 if u$="a" then m$="at"+chr$(13): return
4013 if u$="b" then m$="ati"+chr$(13): return
4014 if u$="c" then m$="at+gsn"+chr$(13): return
4015 if u$="d" then m$="at&v"+chr$(13): return
4016 if u$="e" then m$="at+cimi"+chr$(13): return
4017 if u$="f" then m$="at+qccid"+chr$(13): return
4018 if u$="g" then m$="at+qpinc?"+chr$(13): return
4019 if u$="q" then m$="at+cpin?"+chr$(13): return
4020 if u$="h" then m$="at+qinistat"+chr$(13): return
4021 if u$="i" then m$="at+cops=?"+chr$(13): return
4022 if u$="j" then m$="at+cops?"+chr$(13): return
4023 if u$="k" then m$="at+creg?"+chr$(13): return
4024 if u$="l" then m$="at+csq"+chr$(13): return
4025 if u$="m" then m$="at+copn"+chr$(13): return
4026 if u$="n" then m$="at+qlts"+chr$(13): return
4027 if u$="o" then m$="at+qnwinfo"+chr$(13): return
4028 if u$="p" then m$="at+qspn"+chr$(13): return
4029 if u$="r" then m$="at+cnum"+chr$(13): return
4030 if u$="s" then gosub 7000: return
4031 if u$="t" then print "not implemented": return
4032 if u$="u" then print "not implemented": return
4033 if u$="v" then print "not implemented": return
4034 if u$="y" then gosub 6000: return
4035 if u$="z" then m$="at+qpowd"+chr$(13): return
4080 if u$="w" then gosub 5000: return
4085 if u$="x" goto 990
4091 if u$="1" then m$="at+qurccfg="+chr$(34)+"urcport"+chr$(34)+","+chr$(34)+"uart1"+chr$(34)+chr$(13): return
4092 if u$="2" then m$="ats3?"+chr$(13)+chr$(10): return
4098 if u$="8" then gosub 10000: return
4099 if u$="9" then st$=r$: gosub 8000: return
4100 print "undefined command, try again": return

5000 rem "get a custom command from the keyboard"
5010 input "enter your command: ";m$: m$=m$+chr$(13)
5020 return

6000 rem "listen mode: keeps reading from serial port, interrupted by any keystroke"
6010 print "[listen mode] press any key to return"
6020 c$="": get#1,c$
6030 u$="": get u$
6040 if c$<>"" then print c$;
6050 if u$<>"" then return
6060 goto 6020

7000 rem "display phonebook information"
7010 print "phonebook": print "---------"
7020 m$="at+cpbs?"+chr$(13): gosub 2000 : rem "query which current storage is in use, and find its size"
7025 print "tx: ["+m$+"]"
7030 gosub 3000 : rem "get the response"
7035 print "rx: ["+r$+"]"
7040 m$="": return: rem "TODO"

8000 rem "print a string with its invisible characters (CR, LF)"
8010 for j=1 to len(st$): ch$=right$(left$(st$,j),1): rem "iterate on characters"
8020 if ch$=chr$(13) then print "<CR>";: goto 8100
8020 if ch$=chr$(10) then print "<LF>";: goto 8100
8020 print ch$;
8100 next : rem "end of loop"
8200 print chr$(13);: rem "carriage return at the end of loop"
8300 return


10000 rem "modem response parser"

10005 rem "initialization"
10010 cch$="": cr=0: lf=0
10011 sep=0: prev=0
10011 echo=0: echo$=""
10012 rb=0: re=0: resp$=""
10013 cb=0: ce=0: code$=""
10021 rem "cch= Current CHaracter, cr= previous character was CR, lf= previous character was LF"
10022 rem "sep= the two previous characters were CR+LF, prev= the position of the previous CR+LF (position of LF)"
10023 rem "echo= an echo part is present"
10024 rem "rb= position of Response information Beginning (1st char), re= position of the Response Information End (last char)"
10025 rem "cb= position of result Code Beginning (1st char), re= position of the result Code End (last char)"

10100 rem "start of loop"
10110 for i=1 to len(r$): cch$=right$(left$(r$,i),1): rem "iterate on characters"

10200 rem "processing"
10210 if sep=1 and prev=0 and i>3 then echo=1: echo$=left$(r$,i-3): print "echo="+echo$: goto 10290: rem "first CR+LF, characters before -> echo=True"
10220 if sep=1 and prev=0 and i<=3 then echo=0: goto 10290: rem "first CR+LF, which is the first 2 chars -> echo=False"
10230 if sep=1 and prev>0 then print "line="+mid$(r$, prev+1, i-3): rem "another CR+LF"

10250 st$=left$(r$,i): gosub 8000
10260 print "i="+str$(i)+", cr="+str$(cr)+", lf="+str$(lf)+", sep="+str$(sep)+", prev="+str$(prev)

10300 rem "updating"
10310 if cch$=chr$(13) then cr=1: lf=0: goto 10500 : rem "current char is CR"
10320 if cch$=chr$(10) and cr=1 then cr=0: lf=1: sep=1: prev=i: goto 10500 "current char is LF and previous char was CR"
10330 if cch$=chr$(10) and cr=0 then cr=0: lf=1: sep=0: goto 10500 "current char is LF but previous char was not CR..."
10340 cr=0: lf=0: sep=0 : rem "not CR, not LF, not CR+LF"

10500 u$="": get u$: if u$<>chr$(13) then goto 10500
10510 next: rem "end of loop"
10999 return

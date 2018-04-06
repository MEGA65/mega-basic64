00 poke 0,65: rem "fast mode"
01 poke 53272,23: rem "upper/lower chars"

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
21 print "i - AT+COPS=? -> display avail operator selection (long wait)"
22 print "j - AT+COPS?  -> display curnt operator selection"
23 print "k - AT+CREG?  -> display network registration status"
24 print "l - AT+CSQ  -> display signal strength"
25 print "m - AT+COPN -> display operator names (much output)"
26 print "n - AT+QLTS -> display network time (if available)"
27 print "o - AT+QNWINFO -> display network info"
28 print "p - AT+QSPN    -> display name of registered network"
29 print "r - AT+CNUM    -> display number of SIM"
30 print "s - AT+<misc>  -> display phonebook info"
31 print "t - AT+<misc>  -> read SMS"
32 print "u - AT+<misc>  -> send SMS"
33 print "v - not implemented"
34 print "y - <enter listen mode>"
35 print "z - AT+QPOWD -> power off"
80 print "w - <custom command>"
85 print "x - exit"
91 print "1 - AT+QURCCFG='urcport','uart1' -> send URC (e.g. RING) on UART"


100 open 1,2,1
105 print ">";
110 u$="": get u$: if u$="" then goto 110
120 print u$
130 gosub 4000
140 if m$="" goto 105: rem "undefined command, try again"

150 print "tx: ["+m$+"]"
160 gosub 2000: rem "transmit the cmd"
170 print "rx: [";
180 gosub 3000: rem "get the response"
190 print r$+"]"

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
4034 if u$="y" then gosub 6000: return
4035 if u$="z" then m$="at+qpowd"+chr$(13): return
4080 if u$="w" then gosub 5000: return
4085 if u$="x" goto 990
4091 if u$="1" then m$="at+qurccfg="+chr$(34)+"urcport"+chr$(34)+","+chr$(34)+"uart1"+chr$(34)+chr$(13): return
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

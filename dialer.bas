0 poke 53295,asc("g"): poke 53295,asc("s"): poke 53248+111,128
1 poke 0,65: print chr$(14);

100 gosub 900: gosub 600
500 gosub 1000
510 get a$: if a$<>"" then print#1,a$;
599 goto 500

600 rem "setup modem"

899 return

900 rem "setup for modem parser"
910 dim mf$(20): rem "fields from colon-comma formatted messages"
920 dim ol$(20): rem "lines from modem that don't conform to any normal message format"
930 dim jt%(100):rem "jump table for message handling"
940 for i=1 to 99: jt%(i)=10000+100*i: next i
950 open 1,2,1

999 return

1000 rem "read from cellular modem"
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
1190 f1$="": ml$="": fc=0: mf$=""

1199 mn=0

rem "URC (Unsollicited Result Codes)"

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


1999 return

5000 rem "send string in s$ to modem"
5010 for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
5099 return

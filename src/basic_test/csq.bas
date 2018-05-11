00 poke 0,65
10 rem "request and prints +CSQ very frequently"

15 mdv=1: def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"
16 cnt=0
17 buf$=""

18 print "{clr}";

20 open 1,2,1
25 m$="ate0"+chr$(13): gosub 20000

30 cnt=cnt+1
40 gosub 2000
45 mdv=300: if fn mod(cnt)=0 then gosub 3000
50 goto 30

100 end

2000 rem "get character from serial, print it"
2010 b$=""
2020 get#1,b$: if b$<>"" then print b$;: buf$=buf$+b$
2021 if right$(buf$,2)="ok" then buf$="": print "{home}";cnt;
2030 return

3000 m$="at+csq"+chr$(13): gosub 20000

20000 rem "write a string to the modem, working around the print# bug"
20010 c$="": for i=1 to len(m$): c$=right$(left$(m$,i),1): print#1,c$;: next i
20099 return

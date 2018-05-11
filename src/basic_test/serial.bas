00 poke 0,65
10 print "prints the characters typed on keyboard to serial, and prints the characters received on serial on screen"

15 mdv=1: def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"
16 cnt=0
17 dbg=0: rem "print debug info (namely, <CR><LF>)"

20 open 1,2,1

25 cnt=cnt+1
30 gosub 1000
40 gosub 2000
50 goto 25

100 end

1000 rem "get character from keyboard, print it and send it on serial"
1010 a$=""
1020 get a$: if a$<>"" then print a$;: print#1,a$;
1030 return

2000 rem "get character from serial, print it"
2010 b$=""
2020 get#1,b$
2021 if dbg=0 and b$<>"" then print b$;
2022 if dbg=1 and b$<>"" and b$<>chr$(13) and b$<>chr$(10) then print b$;
2024 if dbg=1 and b$=chr$(13) then print chr$(13)+"<cr>";
2026 if dbg=1 and b$=chr$(10) then print "<lf>"+chr$(13);
2030 return

20000 rem "write a string to the modem, working around the print# bug"
20010 c$="": for i=1 to len(m$): c$=right$(left$(m$,i),1): print#1,c$;: print c$;: next i
20099 return

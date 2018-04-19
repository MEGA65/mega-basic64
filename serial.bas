00 poke 0,65
10 print "prints the characters typed on keyboard to serial, and prints the characters received on serial on screen"
20 open 1,2,1
30 gosub 1000
40 gosub 2000
50 goto 30

100 end

1000 rem "get character from keyboard, print it and send it on serial"
1010 a$=""
1020 get a$: if a$<>"" then print a$;: print#1,a$;
1030 return

2000 rem "get character from serial, print it"
2010 b$=""
2020 get#1,b$
2022 if b$<>"" and b$<>chr$(13) and b$<>chr$(10) then print b$;
2024 if b$=chr$(13) then print chr$(13)+"<cr>";
2026 if b$=chr$(10) then print "<lf>"+chr$(13);
2030 return

20000 rem "write a string to the modem, working around the print# bug"
20010 for i=1 to len(m$):print#1,right$(left$(m$,i),1): next: return

00 poke 0,65
10 print "receives characters on serial and prints them on screen"
20 open 1,2,1
30 gosub 1000

100 end

1000 rem get character from serial and print it
1010 b$=""
1020 get#1,b$: if b$<>"" then print b$;
1030 goto 1020
1040 return

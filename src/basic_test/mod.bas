02 poke 0,65: poke 53248+111,128: rem "50mhz cpu and 60hz display"

05 print "modulo calculator"
06 print "================="

10 b%=1: a%=0: r%=0
20 input "enter divisor b (different of 0): ";b%:
25 if b%=0 then print "you entered 0!": goto 20

30 def fn mod(x) = x-(int(x/b%)*b%): rem "x modulo b; x % b"

40 input "enter dividend: ";a%
50 r%=fn mod(a%)
60 print "";a%;" % ";b%;" = ";r%
70 goto 40

99 end

120 def fn m6(x) = x-(int(x/6)*6): rem "x modulo 6; x % 6"
130 def fn m1k(x) = x-(int(x/1000)*1000): rem "x modulo 1000; x % 1000"
140 cnt%=0: sl%=0
150 cnt%=cnt%+1: if fn m1k(cnt%)=0 then sl%=fn m6(sl%+1)
160 print chr$(147);"cnt%=";cnt%;" ; sl%=";sl%
170 goto 50

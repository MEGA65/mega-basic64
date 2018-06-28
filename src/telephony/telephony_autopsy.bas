63000 print "{clr}": canvas 0 clr: poke 53272,22
print "=== Timing summary ===" c13$ cnt" loops in";left$(str$(tt/60),6);"s, avg";left$(str$(tt/60*1000/cnt),6);"ms"
for i=0 to 10: print " sum:";left$(str$(ttmr(i)/60),6);" s ; avg:";left$(str$(tavg(i)/60*1000),6);" ms": next i
63999 stop

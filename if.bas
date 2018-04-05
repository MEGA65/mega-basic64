00 rem "This program demonstrates how to emulate a if... then... else structure"
05 print ">";
10 get a$: if a$="" goto 10
20 print a$+"=a ?"
30 if a$="a" then print "  true (then)": goto 50
40 print "  false (else)"
50 goto 05

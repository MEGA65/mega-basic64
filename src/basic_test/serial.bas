poke 0,65
print "Prints the characters typed on keyboard to serial, and prints the characters received on serial on screen"

mdv=1: def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"
cnt=0
dbg=1: rem "print debug info (namely, <CR><LF>)"

open 1,2,1
m$="ate1"+chr$(13): gosub WRITE_STRING_TO_MODEM

LOOP cnt=cnt+1
gosub GET_KEYBOARD_CHAR
gosub POLL_MODEM_CHAR
goto LOOP

end

GET_KEYBOARD_CHAR rem "get character from keyboard, print it and send it on serial"
a$=""
get a$
if a$=chr$(20) then a$=chr$(8)
if a$<>"" then print#1,a$;
return

POLL_MODEM_CHAR rem "get character from serial, print it"
b$=""
get#1,b$
if b$=chr$(8) then b$=chr$(20)
if dbg=0 and b$<>"" then print b$;
if dbg=1 and b$<>"" and b$<>chr$(13) and b$<>chr$(10) then print b$;
if dbg=1 and b$=chr$(13) then print chr$(13)+"<cr>";
if dbg=1 and b$=chr$(10) then print "<lf>"+chr$(13);
return

WRITE_STRING_TO_MODEM rem 'write a string to the modem, working around the print# bug
c$="": for i=1 to len(m$): c$=right$(left$(m$,i),1): print#1,c$;: print c$;: next i
return

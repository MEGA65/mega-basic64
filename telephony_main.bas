poke 53280,0: poke 53281,0: rem "border and screen color (0: black)"
poke 0,65: rem "fast mode (50mhz cpu clock)"
poke 53248+111,128: rem "fix screen artifacts (60hz display)"
poke 53272,20: rem "uppercase charset"

# "clear screen"
print "{clr}";: canvas 0 clr

goto INIT

INIT rem "### initialization ###"
# "one-time only lookup patch address"
gosub LOOKUP_GOTO_LN_PATCH_ADDRESS
# "program state setup"
gosub SETUP_PROGRAM
# "modem parser and modem setup"
gosub SETUP_PARSER: gosub SETUP_MODEM
# "GUI-related setup"
gosub SETUP_GUI
# "phonebook setup"
gosub SETUP_PHONEBOOK
# "define functions (e.g. modulo)"
gosub DEFINE_FUNCTIONS
# "--- switch to correct screen ---"
# "if db=1, sc=0 (debug screen)"
if db=1 then gosub SWITCH_TO_SCREEN_DEBUG: goto INIT_END
# "by defaults, start the program on DIALLER screen"
gosub SWITCH_TO_SCREEN_DIALLER

INIT_END goto MAIN_LOOP


MAIN_LOOP rem
# "### main loop ###"
tl=time
cnt=cnt+1
tt=time-t0

t1=time
# "--- get user input / update screen ---"
gosub SCREEN_HANDLER
# "screen updates debugging"
# if us=1 then print "{home}+";: us=0: goto ML1: rem "print a char when screen is updated"
# if us=0 then print "{home} ";: goto ML1: rem "remove the char when screen wasn't updated"
ML1 rem
ttmr(1)=ttmr(1)+(time-t1)

t1=time
# "--- get modem input ---"
gosub POLL_MODEM
ttmr(2)=ttmr(2)+(time-t1)

t1=time
# "--- perform regular tasks ---"
# "request signal quality report every 500 loops"
mdv=100: if fn mod(cnt)=0 then s$="at+csq"+chr$(13): gosub WRITE_STRING_TO_MODEM
# "[test] decrease battery level"
mdv=1000: if fn mod(cnt)=0 then mdv=100: btp=fn mod(btp-1): gosub BATTERY_UPDATE
# "request network info report every 1000 loops"
mdv=500: if fn mod(cnt+250)=0 then s$="at+qnwinfo"+chr$(13): gosub WRITE_STRING_TO_MODEM
# "request network name every 1000 loops"
mdv=500: if fn mod(cnt+500)=0 then s$="at+qspn"+chr$(13): gosub WRITE_STRING_TO_MODEM
# "fix charset bug"
if (peek(53272)and 7)=0 then poke 53272,20
ttmr(3)=ttmr(3)+(time-t1)

# "--- timing related operation ---"
ttmr(0)=ttmr(0)+(time-tl)
# "update the average"
for i=0 to 10: tavg(i)=ttmr(i)/cnt: next i

goto MAIN_LOOP
# "### main loop ###"

poke 53280,0: poke 53281,0: rem "border and screen color (0: black)"
poke 0,65: rem "fast mode (50mhz cpu clock)"
poke 53248+111,128: rem "fix screen artifacts (60hz display)"
poke 53272,20: rem "uppercase charset"

print "{clr}";: canvas 0 clr: rem "clear screen"

goto INIT

INIT rem "### initialization ###"
gosub LOOKUP_GOTO_LN_PATCH_ADDRESS: rem "one-time only lookup patch address"
gosub SETUP_PROGRAM: rem "program state setup"
gosub SETUP_PARSER: gosub SETUP_MODEM: rem "modem parser and modem setup"
gosub SETUP_GUI: rem "GUI-related setup"
gosub SETUP_PHONEBOOK: rem "phonebook setup"
gosub DEFINE_FUNCTIONS: rem "define functions"
if db=1 then gosub SWITCH_TO_SCREEN_0: goto INIT_END: rem "if db=1, sc=0 (debug screen)"
gosub SWITCH_TO_SCREEN_1: rem "start the program on screen 1 (dialer)"
INIT_END goto MAIN_LOOP


MAIN_LOOP rem "### main loop ###"
cnt=cnt+1
rem "--- get user input / update screen ---"
if sc=0 then gosub DRAW_SCREEN_0
if sc=1 then gosub HANDLER_SCREEN_1: rem "user input and screen update for screen 1 (dialer)"
if sc=2 then gosub HANDLER_SCREEN_2
if sc=3 then gosub HANDLER_SCREEN_3
if sc=4 then gosub HANDLER_SCREEN_4
if sc=5 then gosub HANDLER_SCREEN_CONTACT
rem "screen updates debugging"
rem if us=1 then print "{home}+";: us=0: goto ML1: rem "print a char when screen is updated"
rem if us=0 then print "{home} ";: goto ML1: rem "remove the char when screen wasn't updated"
ML1 rem "--- get modem input ---"
gosub POLL_MODEM
rem "--- perform regular tasks ---"
mdv=500: if fn mod(cnt)=0 then s$="at+csq"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "request signal quality report every 500 loops"
mdv=1000: if fn mod(cnt)=0 then mdv=100: btp=fn mod(btp-1): gosub BATTERY_UPDATE: rem "[test] decrease battery level"
mdv=1000: if fn mod(cnt+250)=0 then s$="at+qnwinfo"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "request network info report every 1000 loops"
mdv=1000: if fn mod(cnt+500)=0 then s$="at+qspn"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "request network name every 1000 loops"
if (peek(53272)and 7)=0 then poke 53272,20: rem "fix charset bug"
rem "--- end main loop ---"
goto MAIN_LOOP

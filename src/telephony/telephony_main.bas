poke 53280,11: poke 53281,0 'border and screen color (0: black)
poke 0,65 'fast mode (50mhz cpu clock)
poke 53248+111,128 'fix screen artifacts (60hz display)
poke 53272,20 'uppercase charset

print "{clr}";: canvas 0 clr 'clear screen

goto INIT

'### initialization ###
INIT rem
db=4 'turn on debugging information
'one-time only lookup patch address
gosub LOOKUP_GOTO_LN_PATCH_ADDRESS
'program state setup
gosub SETUP_PROGRAM
'modem parser and modem setup
gosub SETUP_PARSER: gosub SETUP_MODEM
if db>=4 then print "waiting for modem setup{elipsis}"
gosub WAIT_MODEM_READY
if db>=4 then print "modem setup is complete"
'GUI-related setup
gosub SETUP_GUI
gosub SETUP_DRAWING
'phonebook setup
gosub SETUP_PHONEBOOK
'define functions (e.g. modulo)
gosub DEFINE_FUNCTIONS
'gosub WAIT_FOR_KEY_PRESS
db=0 'turn off debugging information
'--- switch to correct screen ---
'if db=1, sc=0 (debug screen)
if db>0 then gosub SWITCH_TO_SCREEN_DEBUG: goto INIT_END
'by defaults, start the program on DIALLER screen
gosub SWITCH_TO_SCREEN_DIALLER

INIT_END t0=time

'Ask for all elements to be drawn first time around
up=1:uc=1:ud=1

'goto MAIN_LOOP

'### main loop ###
MAIN_LOOP rem
tl=time 'set loop timer
cnt=cnt+1
tt=time-t0

t1=time
'--- call screen handler (get user input, update program state...) ---
gosub SCREEN_HANDLER
ttmr(1)=ttmr(1)+(time-t1)

t1=time
'--- screen update ---
'if the clock gain 0.1s over last timed update, we trigger an update
if time-tu>=6 then su=1
'we trigger a screen update every sr loops, and only if needed (su=1)
mdv=sr: if su=1 then gosub SCREEN_DRAWER: tu=time: su=0: us=1

t=time
if us=1 then ttmr(5)=ttmr(5)+(t-t1): c5=c5+1
if us=0 then ttmr(6)=ttmr(6)+(t-t1)
us=0
ttmr(2)=ttmr(2)+(t-t1)

t1=time
'--- get modem input & handle received lines ---
gosub POLL_MODEM
t=time
if ml=1 then ttmr(7)=ttmr(7)+(t-t1): c7=c7+1
if ml=0 then ttmr(8)=ttmr(8)+(t-t1)
ml=0
ttmr(3)=ttmr(3)+(t-t1)

t1=time
'--- perform regular tasks ---
'request signal quality report every 500 loops
mdv=100: if fn mod(cnt)=0 then s$="at+csq"+chr$(13): gosub WRITE_STRING_TO_MODEM
'[test] decrease battery level
mdv=1000: if fn mod(cnt)=0 then mdv=100: btp=fn mod(btp-1): gosub BATTERY_UPDATE
'request network info report every 1000 loops
mdv=500: if fn mod(cnt+250)=0 then s$="at+qnwinfo"+chr$(13): gosub WRITE_STRING_TO_MODEM
'request network name every 1000 loops
mdv=500: if fn mod(cnt+500)=0 then s$="at+qspn"+chr$(13): gosub WRITE_STRING_TO_MODEM
'request network time every 10000 loops
mdv=10000: if fn mod(cnt-50)=0 then s$="at+qlts=2"+chr$(13): gosub WRITE_STRING_TO_MODEM
'fix charset bug
if (peek(53272)and 7)=0 then poke 53272,20
ttmr(4)=ttmr(4)+(time-t1)
'update the contact pane
mdv=1000: if fn mod(cnt+50)=0 then gosub PHONEBOOK_TO_CONTACT_PANE: gosub TRIM_CONTACT_PANE

'--- timing related operation ---
ttmr(0)=ttmr(0)+(time-tl)
'update the average
for i=0 to 10: tavg(i)=ttmr(i)/cnt: next i
if c5<>0 then tavg(5)=ttmr(5)/c5
if cnt<>c5 then tavg(6)=ttmr(6)/(cnt-c5)
if c7<>0 then tavg(7)=ttmr(7)/c7
if cnt<>c8 then tavg(8)=ttmr(8)/(cnt-c8)

goto MAIN_LOOP
'### main loop ###

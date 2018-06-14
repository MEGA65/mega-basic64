'=== goto,X lookup of patch address
LOOKUP_GOTO_LN_PATCH_ADDRESS rem
for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next
return

'=== program flags and variables setup ===
SETUP_PROGRAM rem
db=db 'flag db (debug): print debugging information
'  0: no logging
'  1: critical
'  2: error
'  3: warning
'  4: info
'  5: debug
sc=1 'current screen to be displayed and user input to be taken
ls=1 'last screen used before the current one
sr=10 'screen refresh rate: number of loops between 2 screen updates
su=0 'flag su (screen update): a change in the program requires a screen update
us=0 'flag us (updated screen): is set to 1 when the screen if actually updated
ml=0 'last call to POLL_MODEM resulted in a call to HANDLE_MODEM_LINE
cid$="" 'caller id (number)
dr$="" 'dr (dialling result): user friendly information about dialling state
dia=0 'flag dia (dialling): the modem is currently dialling
rssi=99 'rssi: received signal strength indicator
ber=99 'ber: channel bit error rate
btp=100.0 'remaining battery percentage [0:100]
cnt=0 'loop counter
nact$="" 'network access technology (GSM, EDGE, HSPA, LTE...)
ntype$="" 'network type, to be displayed (2G, 3G, 4G...)
nname$="" 'network name to be displayed
dactive=0 'dactive
'   0: no call active
'   1: call in progress
dsta=-1 'call/dialing state
'  -1: unknown/error/no call
'   0: active
'   1: held
'   2: dialing (outbound call)
'   3: alerting (outbound call)
'   4: incoming (inbound call)
'   5: waiting (inbound call)
dnumber$="" 'number to be dialed
ddisplay$="" 'the text to be displayed at the top of the call screen
tc=0 'tc: initial time at beginning of call
dtmr=0 'dtmr: call timer
dtmr$="000000" 'dtmr$: call timer, in the format HHMMSS

'=== arrays to time different parts of the program ===
'  0: loop time
'  1: screen handler
'  2: screen drawer
'  3: modem polling and message handling
'  4: regular tasks
'  5: screen drawer: redraw
'  6: screen drawer: no redraw
'  7: poll modem: line handled
'  8: screen drawer: no line handle
'======
't0: time at the beginning of the program
't1: time at the beginning of a subpart
'tl: time at the beginning of a loop
'tt: total time spent in program
'tu: time at last screen update
t0=0: t1=0: tl=0: tt=0: tu=0
'diverse counters
c5=0: c7=0
dim ttmr(10) 'array containing the total time spent
dim tavg(10) 'array containing the average time spent
return

'=== setup for modem parser ===
SETUP_PARSER rem
dim mf$(20) 'fields from colon-comma formatted messages
dim ol$(20) 'lines from modem that don't conform to any normal message format
dim jt%(100) 'jump table for message handling
for i=0 to 99: jt%(i)=10000+100*i: next i
cp=50 'counter parser: number of times we poll a char from modem in a loop
open 1,2,1
return

'=== modem setup ===
SETUP_MODEM rem
'no echo from modem
jt%(99)= SETUP_MODEM_STEP2: s$="ate0"+chr$(13): gosub WRITE_STRING_TO_MODEM: return
' NOTE: Changing PCM master/slave mode requires the modem to be physically power cycled
' before it takes effect!
' Setup modem as PCM audio master, 2MHz, 8KHz 16-bit linear samples
SETUP_MODEM_STEP2 jt%(99)= SETUP_MODEM_STEP3: s$="at+qdai=1,0,0,4,0"+chr$(13): gosub WRITE_STRING_TO_MODEM: return
' Setup modem as PCM audio slave, 2MHz, 8KHz 16-bit linear samples
's$="at+qdai=1,1,0,4,0"+chr$(13): gosub WRITE_STRING_TO_MODEM
' Disable audio muting
SETUP_MODEM_STEP3 jt%(99)= SETUP_MODEM_STEP4: s$="at+cmut=0"+chr$(13): gosub WRITE_STRING_TO_MODEM: return
SETUP_MODEM_STEP4 jt%(99)=0
return

'=== Simple terminal program for debugging/talking to modem. ===
'Press  HOME to exit.
TERMINAL_PROGRAM rem
canvas 0 clr: print "{clr}micro term. press home to exit."
' Set modem to echo mode for convenience
s$="ate1"+chr$(13): gosub WRITE_STRING_TO_MODEM
'Simple terminal program for debugging
MLOOP rem
get a$:if a$="{home}" then s$="ate0"+chr$(13): gosub WRITE_STRING_TO_MODEM: print "{clr}";: return
if a$ <> "" then print#1, a$;
get#1, a$:print a$;
goto MLOOP

'=== GUI-related setup ===
SETUP_GUI rem
'GUI offset: the offset between a canvas and its 'pressed' equivalent, i.e. the number of loaded 'button' canvas
gffst=28

'user-input char and number initialization
u$="": nb$=""
'Signal Level integer [0:5]
sl%=0
'Bit Error Rate string to be displayed
ber$="?"
'Battery Level integer [0:10]
bl%=10
'timer for keystrokes
tmr=1000
'highlighted line (for example in contact pane)
hl%=0
'rows to be printed in a box
dim r(24)

return

'=== phonebook setup ===
SETUP_PHONEBOOK rem
pused%=-1 'the number of contacts in the phonebook memory (i.e. SIM)
ptotal%=0 'the maximum number of contacts that can be stored in the phonebook memory (i.e. SIM)
'maximum number of contacts in the phonebook
plngth%=100
'index array
dim pindex%(plngth%)
pindex%=0 'the last phonebook index that was filled (i.e. the higher used phonebook index)'
'phone number array
dim pnumber$(plngth%)
'phone number type array [129, 145, 161]
dim ptype%(plngth%)
'text array
dim ptxt$(plngth%)
'sim index array
dim psim%(plngth%)
'dim of contact array
cmaxindex%=16
'max length that can be displayed in the contact pane
clngth%=17
'contact pane array: names to be displayed in the contact pane
dim cpane$(cmaxindex%)
'contact pane <-> phonebook index mapping
dim cindex%(cmaxindex%)
'number of entries in contact pane (<= cmaxindex%)
centry%=0
cselected%=0 'selected contact index (in phonebook)
cdisplay$="" 'the text to be displayed on the contact screen
ctrigger=0 'the trigger for opening the contact_edit screen
'  0: no contact_edit
'  1: edit existing contact
'  2: new contact
'cnumber$="" 'number of the contact being created/edited
'ctxt$="" 'name of the contact being created/edited
cfields%=2 'number of editable fields
dim cfields$(cfields%) 'array containing the fields of the contact being created/edited
'  1: name
'  2: number
dim clabels$(cfields%) 'array containing the labels of the previous fields
clabels$(1)="Name"
clabels$(2)="Number"
gosub LOAD_PHONEBOOK
gosub PHONEBOOK_TO_CONTACT_PANE
gosub TRIM_CONTACT_PANE
return

'=== functions definition ===
DEFINE_FUNCTIONS rem
'modulo divisor
mdv=1
'x modulo mdv; x % mdv
def fn mod(x) = x-(int(x/mdv)*mdv)
return

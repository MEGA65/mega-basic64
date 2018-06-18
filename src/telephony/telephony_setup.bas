'=== goto,X lookup of patch address
LOOKUP_GOTO_LN_PATCH_ADDRESS rem
for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next
return

'=== functions definition ===
DEFINE_FUNCTIONS rem
'modulo divisor
mdv=1
'x modulo mdv; x % mdv
def fn mod(x) = x-(int(x/mdv)*mdv)
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
ni=0 'no interaction flag
'  0: normal user interaction
'  1: disables user input
sc=1 'current screen to be displayed and user input to be taken
ls=1 'last screen used before the current one
sr=10 'screen refresh rate: number of loops between 2 screen updates
su=0 'flag su (screen update): a change in the program requires a screen update
us=0 'flag us (updated screen): is set to 1 when the screen if actually updated
ml=0 'last call to POLL_MODEM resulted in a call to HANDLE_MODEM_LINE
cnt=0 'loop counter

'=== various indicators ===
rssi=99 'rssi: received signal strength indicator
ber=99 'ber: channel bit error rate
btp=100.0 'remaining battery percentage [0:100]

'=== network-related variables ===
nact$="" 'network access technology (GSM, EDGE, HSPA, LTE...)
ntype$="" 'network type, to be displayed (2G, 3G, 4G...)
nname$="" 'network name to be displayed
dim ntm$(3) 'network time
'   1: hours
'   2: minutes
'   3: seconds
nltm=0 'network last synchronized time (the real time)
nmtm=0 'MEGA65 time when received network last synchronized time
nrtm=0 'current real time, based on network synchronized time

'=== dialling-related variables ===
cid$="" 'caller id (number)
dr$="" 'dr (dialling result): user friendly information about dialling state
dia=0 'flag dia (dialling): the modem is currently dialling
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
dtmr$="00:00:00" 'dtmr$: call timer, in the format HH:MM:SS


'=== time-related variables ===
thour=0: tmin=0: tsec=0
thour$="": tmin$="": tsec$=""
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
'---SMS setup---
'Set SMS mode to Text mode
SETUP_MODEM_STEP4 jt%(99)= SETUP_MODEM_STEP5: s$="at+cmgf=1"+chr$(13): gosub WRITE_STRING_TO_MODEM: return
'Set the memories to use for SMS storage; the memory used is MT (or ME), which has more space'
SETUP_MODEM_STEP5 jt%(99)= SETUP_MODEM_STEP6: s$="at+cpms="+chr$(34)+"MT"+chr$(34)+","+chr$(34)+"MT"+chr$(34)+","+chr$(34)+"MT"+chr$(34)+chr$(13): gosub WRITE_STRING_TO_MODEM: return
SETUP_MODEM_STEP6 jt%(99)=0
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
if a$=chr$(20) then a$=chr$(8)
if a$ <> "" then print#1, a$;
get#1, a$:if a$=chr$(8)then a$=chr$(20)
print a$;
goto MLOOP

'=== GUI-related setup ===
SETUP_GUI rem
'--- Canvas & Tiles ---
gs%=1 'Signal Index: index of the canvas at which the signal icons start
gb%=7 'Battery Index: index of the canvas at which the battery icons start
gd%=18 'Dialler Index: index of the canvas at which the dialler buttons start
gffst=28 'GUI offset: the offset between a canvas and its 'pressed' equivalent, i.e. the number of loaded 'button' canvas
'--- Other ---
u$="" 'user-input char
nb$="" 'phone number dialled on the dialler screen
sl%=0 'Signal Level integer [0:5]
ber$="?" 'Bit Error Rate string to be displayed
bl%=10 'Battery Level integer [0:10]
tmr=1000 'timer for keystrokes
hl%=0 'highlighted line (for example in contact pane)
ul%=0 'underlined column (when editing a field for example)
dim r(24) 'rows to be printed in a box
dim h(24) 'rows to be hidden in a box
return

'=== phonebook setup ===
SETUP_PHONEBOOK rem
psource$="sim" 'source of the contacts to load
'   "sim"
'   "code"
'   "sd"
pused%=-1 'the number of contacts in the phonebook memory (i.e. SIM)
ptotal%=0 'the maximum number of contacts that can be stored in the phonebook memory (i.e. SIM)
plngth%=100 'maximum number of contacts in the MEGA65 memory
dim pindex%(plngth%) 'index array
'   0: contact at index i doesn't exist / isn't active
'   1: contact at index i exists / is active
pindex%=0 'the last phonebook index that was filled (i.e. the higher used phonebook index)'
dim pnumber$(plngth%) 'phone number array
dim ptype%(plngth%) 'phone number type array [129, 145, 161]
dim ptxt$(plngth%) 'text array
'dim psim%(plngth%) 'sim index array
'   0: contact not in sim
'   X: contact in sim at index X
cmaxindex%=16 'dim of contact array
clngth%=17 'max length that can be displayed in the contact pane
dim cpane$(cmaxindex%) 'contact pane array: names to be displayed in the contact pane
dim cindex%(cmaxindex%) 'contact pane <-> phonebook index mapping
centry%=0 'number of entries in contact pane (<= cmaxindex%)
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
cstatus$="" 'status message on the contact edit screen
gosub LOAD_PHONEBOOK
gosub PHONEBOOK_TO_CONTACT_PANE
gosub TRIM_CONTACT_PANE
return


'=== SMS setup ===
SETUP_SMS rem
sused%=-1 'the number of SMS in selected storage
stotal%=0 'the maximum number of SMS that can be stored in the selected storage
slngth%=255 'maximum number of SMS in the MEGA65 memory
dim sidex%(slngth%) 'mapping between SMS in memory and in storage
'   sidex%(1)=32: the SMS in memory with index 1 has index 32 in storage
dim snumber$(slngth%) 'phone number of the sender of SMS
dim stxt$(slngth%) 'text of the SMS
dim sd$(slngth%) 'timestamp (date) of SMS
dim satus$(slngth%) 's(t)atus of SMS ("READ", "UNREAD", etc.)
sq=0 'SMS for contact Queried. Flag to indicate if the SMS for the currently selected contact have been queried.'
'	0: not queried
'	1: queried, not received
'	2: queried and received
satus$="" 'status message for SMS on the contact screen
sr%=0 'last contact for which SMS were Retrieved
return

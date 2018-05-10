LOOKUP_GOTO_LN_PATCH_ADDRESS rem "=== goto,X lookup of patch address"
for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next
return

SETUP_PROGRAM rem "=== program flags and variables setup ==="
# "flag db (debug): print debugging information"
db=0
# "current screen to be displayed and user input to be taken"
sc=1
# "screen refresh rate: number of loops between 2 screen updates"
sr=10
# "flag su (screen update): a change in the program requires a screen update"
su=0
# "flag us (updated screen): is set to 1 when the screen if actually updated"
us=0
# "last call to POLL_MODEM resulted in a call to HANDLE_MODEM_LINE"
ml=0
# "caller id (number)"
cid$=""
# "dr (dialling result): user friendly information about dialling state"
dr$=""
# "flag dia (dialling): the modem is currently dialling"
dia=0
# "rssi: received signal strength indicator"
rssi=99
# "ber: channel bit error rate"
ber=99
# "remaining battery percentage [0:100]"
btp=100.0
# "loop counter"
cnt=0
# "network access technology (GSM, EDGE, HSPA, LTE...)"
nact$=""
# "network type, to be displayed (2G, 3G, 4G...)"
ntype$=""
# "network name to be displayed"
nname$=""
# "dactive"
# "   0: no call active"
# "   1: call in progress"
dactive=0
# "dsta"
# "call/dialing state"
# "  -1: unknown/error/no call"
# "   0: active"
# "   1: held"
# "   2: dialing (outbound call)"
# "   3: alerting (outbound call)"
# "   4: incoming (inbound call)"
# "   5: waiting (inbound call)"
dsta=-1
# "dnumber"
# "number to be dialed"
dnumber$=""
# "ddisplay"
# "the text to be displayed at the top of the call screen"
ddisplay$=""
# "tc: initial time at beginning of call"
tc=0
# "dtmr: call timer"
dtmr=0
# "dtmr$: call timer, in the format HHMMSS"
dtmr$="000000"

# "=== arrays to time different parts of the program ==="
# "  0: loop time"
# "  1: screen handler"
# "  2: screen drawer"
# "  3: modem polling and message handling"
# "  4: regular tasks"
# "  5: screen drawer: redraw"
# "  6: screen drawer: no redraw"
# "  7: poll modem: line handled"
# "  8: screen drawer: no line handle"
# "======"
# "t0: time at the beginning of the program"
# "t1: time at the beginning of a subpart"
# "tl: time at the beginning of a loop"
# "tt: total time spent in program"
# "tu: time at last screen update"
t0=0: t1=0: tl=0: tt=0: tu=0
# "diverse counters"
c5=0: c7=0
# "array containing the total time spent"
dim ttmr(10)
# "array containing the average time spent"
dim tavg(10)
return

SETUP_PARSER rem "=== setup for modem parser ==="
dim mf$(20): rem "fields from colon-comma formatted messages"
dim ol$(20): rem "lines from modem that don't conform to any normal message format"
dim jt%(100): rem "jump table for message handling"
for i=0 to 99: jt%(i)=10000+100*i: next i
open 1,2,1
return

SETUP_MODEM rem "=== modem setup ==="
s$="ate0"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "no echo from modem"
return

SETUP_GUI rem "=== GUI-related setup ==="
u$="": nb$="": rem "user-input char and number initialization"
sl%=0: rem "Signal Level integer [0:5]"
ber$="?": rem "Bit Error Rate string to be displayed"
bl%=10: rem "Battery Level integer [0:10]"
tmr=1000: rem "timer for keystrokes"
hl%=0: rem "highlighted line (for example in contact pane)"
dim r(24): rem "rows to be printed in a box"
return

SETUP_PHONEBOOK rem "=== phonebook setup ==="
plngth%=200: rem "maximum number of contacts in the phonebook"
dim pindex%(plngth%): rem "index array"
dim pnumber$(plngth%): rem "phone number array"
dim ptype%(plngth%): rem "phone number type array [129, 145, 161]"
dim ptxt$(plngth%): rem "text array"
dim psim%(plngth%): rem "sim index array"
cmaxindex%=16: rem "dim of contact array"
clngth%=17: rem "max length that can be displayed in the contact pane"
dim cpane$(cmaxindex%): rem "contact pane array: names to be displayed in the contact pane"
dim cindex%(cmaxindex%): rem "contact pane <-> phonebook index mapping"
centry%=0: rem "number of entries in contact pane (<= cmaxindex%)"
cselected%=0: rem "selected contact index (in phonebook)"
cdisplay$="": rem "the text to be displayed on the contact screen"
gosub LOAD_PHONEBOOK
gosub PHONEBOOK_TO_CONTACT_PANE
gosub TRIM_CONTACT_PANE
return

DEFINE_FUNCTIONS rem "=== functions definition ==="
def fn m6(x) = x-(int(x/6)*6): rem "x modulo 6; x % 6"
def fn m1k(x) = x-(int(x/1000)*1000): rem "x modulo 1000; x % 1000"
mdv=1 : rem "modulo divisor"
def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"
return

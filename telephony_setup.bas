LOOKUP_GOTO_LN_PATCH_ADDRESS rem "=== goto,X lookup of patch address"
for ja=2048 to 40959: if peek(ja-1)<>141 or peek(ja)<>44 then next
return

SETUP_PROGRAM rem "=== program flags and variables setup ==="
db=0: rem "flag db (debug): print debugging information"
sd=1: rem "flag send: send characters typed on keyboard to modem right away"
sc=1: rem "current screen to be displayed and user input to be taken"
su=0: rem "flag su (screen update): a change in the program requires a screen update"
us=0: rem "flag us (updated screen): is set to 1 when the screen if actually updated"
cid$="": rem "caller id (number)"
dr$="": rem "dr (dialling result): user friendly information about dialling state"
dia=0: rem "flag dia (dialling): the modem is currently dialling"
rssi=99: rem "rssi: received signal strength indicator"
ber=99: rem "ber: channel bit error rate"
btp=100.0: rem "remaining battery percentage [0:100]"
cnt=0: rem "loop counter"
nact$="": rem "network access technology (GSM, EDGE, HSPA, LTE...)"
nt$="": rem "network type, to be displayed (2G, 3G, 4G...)"

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
return

DEFINE_FUNCTIONS rem "=== functions definition ==="
def fn m6(x) = x-(int(x/6)*6): rem "x modulo 6; x % 6"
def fn m1k(x) = x-(int(x/1000)*1000): rem "x modulo 1000; x % 1000"
mdv=1 : rem "modulo divisor"
def fn mod(x) = x-(int(x/mdv)*mdv): rem "x modulo mdv; x % mdv"
return

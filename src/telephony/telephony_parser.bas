'=== read from modem ===
POLL_MODEM rem
if db>=5 then print "polling modem"
'reinitialize parser counter
cp=50
'read one char from cellular modem and parse received fields
PM_GET get#1,c$: if c$="" then return
cp=cp-1
if c$=chr$(13) or c$=chr$(10) then goto HANDLE_MODEM_LINE
'first field is separated with a column
if c$=":" and fc=0 then mf$(0)=mf$: fc=1: mf$=""
'other fields are separated with a comma; limit=20
if c$="," and fc>0 and fc<20 then mf$(fc)=mf$: fc=fc+1: mf$=""
if c$<>"," and c$<>":" then mf$=mf$+c$
ml$=ml$+c$

'if we didn't handle a non-empty modem line, we poll the modem again (limit: cp times)
if ml=0 and cp>0 goto PM_GET
return

'=== handle modem line ===
HANDLE_MODEM_LINE rem
'received complete line from modem
if mf$<>"" and fc<20 then mf$(fc)=mf$: fc=fc+1
if ml$="" then return
for i=0 to(fc-1)
'trim one space at the beginning of each field, if there is a whitespace
if left$(mf$(i),1)=" " then mf$(i)=right$(mf$(i),len(mf$(i))-1)
next i
if db>=4 then print "Received modem line: ";ml$
if db>=5 then print "modem field count: ";fc
if db>=5 then print "modem fields: ";
if db>=5 then for i=0 to(fc-1): print"[";mf$(i);"]",: next i
f1$="": ml$="": fc=0: mf$=""
mn=0
gosub GET_MESSAGE_TYPE: gosub JUMP_TO_HANDLER
'a non-empty modem line has been handled
ml=1
'Check if we got an acceptable result code:
'  ok, error, +cme error, +cms error'
'  If so, then we will try and jump to a common callback
rc=0
if mn=40 or mn=44 or mn=49 or mn=50 then rc=1
'Check if we have a common callback registered
if rc=1 then mn=99: gosub JUMP_TO_HANDLER
return


'=== Jump to handler ===
JUMP_TO_HANDLER rem
if db>=5 then print "message is type";mn
'Check if jumptable is set for this message type, if so, call handler
ln=jt%(mn): if ln>0 then gosub GOTO_LN
return

'=== List of all messages ===
GET_MESSAGE_TYPE rem
'--- URC (Unsollicited Result Codes) ---
if mf$(0)="+creg" then mn=1
if mf$(0)="+cgreg" then mn=3
if mf$(0)="+ctzv" then mn=5
if mf$(0)="+ctze" then mn=6
if mf$(0)="+cmti" then mn=7
if mf$(0)="+cmt" then mn=8
if mf$(0)="^hcmt" then mn=10
if mf$(0)="+cbm" then mn=11
if mf$(0)="+cds" then mn=13
if mf$(0)="+cdsi" then mn=15
if mf$(0)="^hcds" then mn=16
if mf$(0)="+colp" then mn=17
if mf$(0)="+clip" then mn=18
if mf$(0)="+cring" then mn=19
if mf$(0)="+ccwa" then mn=20
if mf$(0)="+cssi" then mn=21
if mf$(0)="+cssu" then mn=22
if mf$(0)="+cusd" then mn=23
if mf$(0)="rdy" then mn=24
if mf$(0)="+cfun" then mn=25
if mf$(0)="+cpin" then mn=26
if mf$(0)="+qind" then mn=27
if mf$(0)="powered down" then mn=29
if mf$(0)="+cgev" then mn=30
'--- Result Codes ---
if mf$(0)="ok" then mn=40
if mf$(0)="connect" then mn=41
if mf$(0)="ring" then mn=42
if mf$(0)="no carrier" then mn=43
if mf$(0)="error" then mn=44
if mf$(0)="no dialtone" then mn=46
if mf$(0)="busy" then mn=47
if mf$(0)="no answer" then mn=48
if mf$(0)="+cme error" then mn=49
if mf$(0)="+cms error" then mn=50
'--- AT commands responses ---
if mf$(0)="+clcc" then mn=51
if mf$(0)="+csq" then mn=52
if mf$(0)="+qnwinfo" then mn=53
if mf$(0)="+qspn" then mn=54
if mf$(0)="+cpbs" then mn=55
if mf$(0)="+cpbr" then mn=56
return

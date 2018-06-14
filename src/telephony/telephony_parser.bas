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
if mf$(0)="+CREG" then mn=1
if mf$(0)="+CGREG" then mn=3
if mf$(0)="+CTZV" then mn=5
if mf$(0)="+CTZE" then mn=6
if mf$(0)="+CMTI" then mn=7
if mf$(0)="+CMT" then mn=8
if mf$(0)="^HCMT" then mn=10
if mf$(0)="+CBM" then mn=11
if mf$(0)="+CDS" then mn=13
if mf$(0)="+CDSI" then mn=15
if mf$(0)="^HCDS" then mn=16
if mf$(0)="+COLP" then mn=17
if mf$(0)="+CLIP" then mn=18
if mf$(0)="+CRING" then mn=19
if mf$(0)="+CCWA" then mn=20
if mf$(0)="+CSSI" then mn=21
if mf$(0)="+CSSU" then mn=22
if mf$(0)="+CUSD" then mn=23
if mf$(0)="RDY" then mn=24
if mf$(0)="+CFUN" then mn=25
if mf$(0)="+CPIN" then mn=26
if mf$(0)="+QIND" then mn=27
if mf$(0)="POWERED DOWN" then mn=29
if mf$(0)="+CGEV" then mn=30
'--- Result Codes ---
if mf$(0)="OK" then mn=40
if mf$(0)="CONNECT" then mn=41
if mf$(0)="RING" then mn=42
if mf$(0)="NO CARRIER" then mn=43
if mf$(0)="ERROR" then mn=44
if mf$(0)="NO DIALTONE" then mn=46
if mf$(0)="BUSY" then mn=47
if mf$(0)="NO ANSWER" then mn=48
if mf$(0)="+CME ERROR" then mn=49
if mf$(0)="+CMS ERROR" then mn=50
'--- AT commands responses ---
if mf$(0)="+CLCC" then mn=51
if mf$(0)="+CSQ" then mn=52
if mf$(0)="+QNWINFO" then mn=53
if mf$(0)="+QSPN" then mn=54
if mf$(0)="+CPBS" then mn=55
if mf$(0)="+CPBR" then mn=56
return

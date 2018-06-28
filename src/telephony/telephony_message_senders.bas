'=== Utility subroutines ===

' XXX - Add routine to write AT command, prefixing with AT, and suffixing with chr$(13)

WRITE_AT_COMMAND_TO_MODEM s$="at"+s$
' Fall through to WRITE_LINE_TO_MODEM

WRITE_LINE_TO_MODEM s$=s$+c13$
' Fall through to WRITE_STRING_TO_MODEM

'Send string s$ to modem
'Argument:
'  s$: the string to send to modem
WRITE_STRING_TO_MODEM rem
if db>=4 then print "Sent to modem: "+left$(s$, len(s$)-1)
for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i: return

WAIT_MODEM_READY rem
'Wait for the modem to be ready
'  This subroutine only returns once the modem is ready,
'  i.e. the call-back routine jt%(100) is set to 0
if db>=5 then print "wait modem ready"
WMR if db>=6 then print "  jt%(100)=",jt%(100)
if jt%(100)<>0 then gosub POLL_MODEM: goto WMR
if db>=5 then print "modem ready"
return

WRITE_LINE_TO_MODEM_READY s$=s$+chr$(13)
' Fall through to WRITE_STRING_TO_MODEM_READY

WRITE_STRING_TO_MODEM_READY rem
'Wait for the modem to be ready and send string s$ to modem
'Argument:
'  s$: the string to send to modem
gosub WAIT_MODEM_READY: gosub WRITE_STRING_TO_MODEM: return

MODEM_READY jt%(100)=0: return 'Call-back subroutine used with WAIT_MODEM_READY


'=== SEND subroutines: send messages to modem ===

'place a call by sending ATD (dial)
'Argument:
'  dnumber$: the number to dial
SEND_ATD s$="d"+dnumber$+";": gosub WRITE_AT_COMMAND_TO_MODEM: return

'end call by sending AT+CHUP (call hang up)
SEND_AT+CHUP s$="+chup": gosub WRITE_AT_COMMAND_TO_MODEM; return

'end call by sending ATH (hang up)
SEND_ATH s$="h": gosub WRITE_AT_COMMAND_TO_MODEM: return

'answer call by sending ATA (answer)
SEND_ATA s$="ata": gosub WRITE_LINE_TO_MODEM_READY

'If we send another command immediately, it can make the modem hang up.
'We have to wait for OK
jt%(100)= MODEM_READY: gosub WAIT_MODEM_READY 'wait for modem to be ready (Result Code received)
if merror=1 then merror=0: gosub CALL_HANGUP: gosub SWITCH_TO_SCREEN_DIALLER: return 'modem ERROR: hang-up the call
if merror=0 then return 'modem OK: everything is fine, we simply return

'send AT+CLCC (list current calls)
SEND_AT+CLCC s$="+clcc": gosub WRITE_AT_COMMAND_TO_MODEM: return

'send AT+CMGL (list SMS)
'Argument:
'   int k: stat
SEND_AT+CMGL s$="+cmgl="+sus$(k): gosub WRITE_AT_COMMAND_TO_MODEM: return

'send AT+CMGR (read SMS)
'Argument:
'   int k: index
SEND_AT+CMGR s$="+cmgr="+str$(k): gosub WRITE_AT_COMMAND_TO_MODEM: return

'send AT+CMGS (send SMS), text mode
'Argument:
'  sm$: the message string
'  sn$: the phone number to send to
SEND_AT+CMGS_1 s$="+CMGS="+chr$(34)+sn$+chr$(34): gosub WRITE_AT_COMMAND_TO_MODEM
return

'send AT+CMGD (delete SMS)
'Argument:
'  k: index of the SMS (on modem storage) to delete
SEND_AT+CMGD s$="+CMGD="+str$(k): gosub WRITE_AT_COMMAND_TO_MODEM: return

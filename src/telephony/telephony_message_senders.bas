'=== Utility subroutines ===

WRITE_STRING_TO_MODEM rem
'Send string s$ to modem
'Argument:
'  s$: the string to send to modem
if db>=4 then print "Sent to modem: "+left$(s$, len(s$)-1)
for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
return

WAIT_MODEM_READY rem
'Wait for the modem to be ready
'  This subroutine only returns once the modem is ready,
'  i.e. the call-back routine jt%(100) is set to 0
if db>=5 then print "wait modem ready"
WMR if db>=6 then print "  jt%(100)=",jt%(100)
if jt%(100)<>0 then gosub POLL_MODEM: goto WMR
if db>=5 then print "modem ready"
return

WRITE_STRING_TO_MODEM_READY rem
'Wait for the modem to be ready and send string s$ to modem
'Argument:
'  s$: the string to send to modem
gosub WAIT_MODEM_READY
gosub WRITE_STRING_TO_MODEM
return

MODEM_READY jt%(100)=0: return 'Call-back subroutine used with WAIT_MODEM_READY


'=== SEND subroutines: send messages to modem ===

SEND_ATD rem
'place a call by sending ATD (dial)
s$="atd"+dnumber$+";"+chr$(13): gosub WRITE_STRING_TO_MODEM
'we should wait for OK (or ERROR)
return

SEND_AT+CHUP rem
'end call by sending AT+CHUP (call hang up)
s$="at+chup"+chr$(13): gosub WRITE_STRING_TO_MODEM
'we should wait for OK (or ERROR)
return

SEND_ATH rem
'end call by sending ATH (hang up)
s$="ath"+chr$(13): gosub WRITE_STRING_TO_MODEM
'we should wait for OK (or ERROR)
return

SEND_ATA rem
'answer call by sending ATA (answer)
s$="ata"+chr$(13): gosub WRITE_STRING_TO_MODEM
'we should wait for OK (or ERROR)
' XXX If we send another command immediately, it can make the modem hang up.
' so wait a little while.
' XXX we should indeed wait for OK, so we wait no longer than is necessary.
for i = 1 to 10000: next i
return

SEND_AT+CLCC rem
'send AT+CLCC (list current calls)
s$="at+clcc"+chr$(13): gosub WRITE_STRING_TO_MODEM
return

SEND_AT+CMGL rem
'send AT+CMGL (list SMS)
'Argument:
'   int k: stat
s$="at+cmgl="+sus$(k)+chr$(13): gosub WRITE_STRING_TO_MODEM
return

SEND_AT+CMGR rem
'send AT+CMGR (read SMS)
'Argument:
'   int k: index
s$="at+cmgr="+str$(k)+chr$(13): gosub WRITE_STRING_TO_MODEM
return

SEND_AT+CMGS_1 rem
'send AT+CMGS (send SMS), text mode
'Argument:
'  sm$: the message string
'  sn$: the phone number to send to
s$="AT+CMGS="+chr$(34)+sn$+chr$(34)+chr$(13): gosub WRITE_STRING_TO_MODEM
return

SEND_AT+CMGD rem
'send AT+CMGD (delete SMS)
'Argument:
'  k: index of the SMS (on modem storage) to delete
s$="AT+CMGD="+str$(k)+chr$(13): gosub WRITE_STRING_TO_MODEM
return

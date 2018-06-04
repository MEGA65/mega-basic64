'=== subroutines: send messages to modem ===

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
for i = 1 to 5000: next i
return

SEND_AT+CLCC rem
'send AT+CLCC (list current calls)
s$="at+clcc"+chr$(13): gosub WRITE_STRING_TO_MODEM
return


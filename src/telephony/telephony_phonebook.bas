'=== load phonebook into memory (arrays)===
LOAD_PHONEBOOK rem
'This routine should load the phonebook entries from the storage (i.e. Sim or SD card) to the memory.
if psource$="sim" then gosub LOAD_PHONEBOOK_SIM
if psource$="code" then gosub LOAD_PHONEBOOK_CODE
return

LOAD_PHONEBOOK_SIM rem
'== load phonebook from sim ==
'We first need to get the number of contacts in storage
s$="at+cpbs?"+chr$(13): gosub WRITE_STRING_TO_MODEM_READY: jt%(99)= MODEM_READY
gosub WAIT_MODEM_READY
if db>=4 then print "+CPBS received, pused%=",pused%
'At this point, we know how many contacts there are in the SIM phonebook
'We try and retrieve those contacts
s$="at+cpbr=1,"+right$(str$(pused%),len(str$(pused%))-1)+chr$(13): gosub WRITE_STRING_TO_MODEM_READY: jt%(99)= MODEM_READY
gosub WAIT_MODEM_READY
if db>=4 then print "+CPBR received"
'The memory phonebook should be filled with entries from the SIM phonebook
print "+CPBR: phonebook entries received"
if db>=4 and pindex%>0 then for i=1 to pindex%: print pnumber$(i)+" "+ptxt$(i)+" "+str$(psim%(i)): next i
return

LOAD_PHONEBOOK_CODE rem
'== load phonebook from code ==
'For now, we load predefined entries from the program itself.
for i=1 to 5: pindex%(i)=1: psim%(i)=0: next i
pnumber$(1)="+61882013911": ptype%(1)=129 : ptxt$(1)="flinders uni"
pnumber$(2)="131444": ptype%(2)=129 : ptxt$(2)="sa police"
pnumber$(3)="000": ptype%(3)=129 : ptxt$(3)="emergency"
pnumber$(4)="": ptype%(4)=129 : ptxt$(4)=""
pnumber$(5)="": ptype%(5)=129 : ptxt$(5)=""
gosub PHONEBOOK_ENTRIES
'This subroutine is in another file, not uploaded to Git. It simply contains the same preceding lines, with actual data.
return

PHONEBOOK_TO_CONTACT_PANE rem
'Schedule redraw after
uc=1: su=1
'WARNING: probably bugs if O entries in phonebook
centry%=0: j=1
'contact pane not full
for i=1 to plngth%: if j<=cmaxindex% then goto PHBK_THEN_1
'contact pane full
goto PHBK_ELSE_1
'entry at index i
PHBK_THEN_1 if pindex%(i)=1 then goto PHBK_THEN_2
'no entry at index i
goto PHBK_ELSE_2
'phonebook i -> contact j
PHBK_THEN_2 cpane$(j)=ptxt$(i): cindex%(j)=i: j=j+1: next i
PHBK_ELSE_2 next i
'j=cmaxindex% (contact pane full) or i=plength% (end of phonebook)
PHBK_ELSE_1 centry%=j-1: return
centry%=j-1: return

TRIM_CONTACT_PANE rem
'trim contact pane entries to clength chars, adding ... if necessary
for i=1 to cmaxindex%
l=clngth%: s$=cpane$(i): gosub TRIM_STRING: cpane$(i)=s$
next i
return

TRIM_CONTACT_DISPLAY_TEXT rem
'generates and trim if necessary the text to be displayed at the top of the contact screen
'trim both name and number
if len(ptxt$(cselected%))>19 and len(pnumber$(cselected%))>12 then cdisplay$=left$(ptxt$(cselected%),19-1)+"{elipsis} ("+left$(pnumber$(cselected%),12-1)+"{elipsis})": return
'trim name
if len(pnumber$(cselected%))<12 and len(ptxt$(cselected%))>34-3-len(pnumber$(cselected%)) then cdisplay$=left$(ptxt$(cselected%),34-3-1-len(pnumber$(cselected%)))+"{elipsis} ("+pnumber$(cselected%)+")": return
'trim number
if len(ptxt$(cselected%))<19 and len(pnumber$(cselected%))>34-3-len(ptxt$(cselected%)) then cdisplay$=ptxt$(cselected%)+" ("+left$(pnumber$(cselected%),34-3-1-len(ptxt$(cselected%)))+"{elipsis})": return
'no trim
cdisplay$=ptxt$(cselected%)+" ("+pnumber$(cselected%)+")": return

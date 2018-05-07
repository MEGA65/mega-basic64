LOAD_PHONEBOOK rem "=== load phonebook into memory (arrays)==="
rem "This routine should load the phonebook entries from the storage (i.e. SD card) to the memory."
rem "For now, we load predefined entries from the program itself."
for i=1 to 5: pindex%(i)=1: psim%(i)=0: next i
pnumber$(1)="": ptype%(1)=129 : ptxt$(1)=""
pnumber$(2)="": ptype%(2)=129 : ptxt$(2)=""
pnumber$(3)="": ptype%(3)=129 : ptxt$(3)=""
pnumber$(4)="": ptype%(4)=129 : ptxt$(4)=""
pnumber$(5)="": ptype%(5)=129 : ptxt$(5)=""
gosub PHONEBOOK_ENTRIES: rem "This subroutine is in another file, not uploaded to Git. It simply contains the same preceding lines, with actual data."
return

PHONEBOOK_TO_CONTACT_PANE rem
# "WARNING: probably bugs if O entries in phonebook"
centry%=0: j=1
for i=1 to plngth%: if j<cmaxindex% then goto PHBK_THEN_1: rem "contact pane not full"
goto PHBK_ELSE_1: rem "contact pane full"
PHBK_THEN_1 if pindex%(i)=1 then goto PHBK_THEN_2: rem "entry at index i"
goto PHBK_ELSE_2 "no entry at index i"
PHBK_THEN_2 cpane$(j)=ptxt$(i): cindex%(j)=i: j=j+1: next i: rem "phonebook i -> contact j"
PHBK_ELSE_2 next i: rem 
PHBK_ELSE_1 centry%=j-1: return: rem "j=cmaxindex% (contact pane full) or i=plength% (end of phonebook)"
centry%=j-1: return

TRIM_CONTACT_PANE rem
# "trim contact pane entries to clength chars, adding ... if necessary"
for i=1 to cmaxindex%
if len(cpane$(i))>clngth% then cpane$(i)=left$(cpane$(i),clngth%-3)+"..."
next i
return

TRIM_CONTACT_DISPLAY_TEXT rem
# "generates and trim if necessary the text to be displayed at the top of the contact screen"
if len(ptxt$(cselected%))>20 and len(pnumber$(cselected%))>12 then cdisplay$=left$(ptxt$(cselected%),20-3)+"... ("+left$(pnumber$(cselected%),12-3)+"...)": return
if len(pnumber$(cselected%))<12 and len(ptxt$(cselected%))>35-3-len(pnumber$(cselected%)) then cdisplay$=left$(ptxt$(cselected%),35-3-3-len(pnumber$(cselected%)))+"... ("+pnumber$(cselected%)+")": return
if len(ptxt$(cselected%))<20 and len(pnumber$(cselected%))>35-3-len(ptxt$(cselected%)) then cdisplay$=ptxt$(cselected%)+" ("+left$(pnumber$(cselected%),35-3-3-len(ptxt$(cselected%)))+"...)": return
cdisplay$=ptxt$(cselected%)+" ("+pnumber$(cselected%)+")": return

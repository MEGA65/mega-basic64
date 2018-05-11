# "=== load phonebook into memory (arrays)==="
LOAD_PHONEBOOK rem
# "This routine should load the phonebook entries from the storage (i.e. SD card) to the memory."
# "For now, we load predefined entries from the program itself."
for i=1 to 5: pindex%(i)=1: psim%(i)=0: next i
pnumber$(1)="+61882013911": ptype%(1)=129 : ptxt$(1)="flinders uni"
pnumber$(2)="131444": ptype%(2)=129 : ptxt$(2)="sa police"
pnumber$(3)="000": ptype%(3)=129 : ptxt$(3)="emergency"
pnumber$(4)="": ptype%(4)=129 : ptxt$(4)=""
pnumber$(5)="": ptype%(5)=129 : ptxt$(5)=""
gosub PHONEBOOK_ENTRIES # "This subroutine is in another file, not uploaded to Git. It simply contains the same preceding lines, with actual data."
return

PHONEBOOK_TO_CONTACT_PANE rem
# Schedule redraw after
uc=1: su=1
# "WARNING: probably bugs if O entries in phonebook"
centry%=0: j=1
# "contact pane not full"
for i=1 to plngth%: if j<cmaxindex% then goto PHBK_THEN_1
# "contact pane full"
goto PHBK_ELSE_1
# "entry at index i"
PHBK_THEN_1 if pindex%(i)=1 then goto PHBK_THEN_2
# "no entry at index i"
goto PHBK_ELSE_2
# "phonebook i -> contact j"
PHBK_THEN_2 cpane$(j)=ptxt$(i): cindex%(j)=i: j=j+1: next i
PHBK_ELSE_2 next i
# "j=cmaxindex% (contact pane full) or i=plength% (end of phonebook)"
PHBK_ELSE_1 centry%=j-1: return
centry%=j-1: return

TRIM_CONTACT_PANE rem
# "trim contact pane entries to clength chars, adding ... if necessary"
for i=1 to cmaxindex%
if len(cpane$(i))>clngth% then cpane$(i)=left$(cpane$(i),clngth%-3)+"..."
next i
return

TRIM_CONTACT_DISPLAY_TEXT rem
# "generates and trim if necessary the text to be displayed at the top of the contact screen"
if len(ptxt$(cselected%))>19 and len(pnumber$(cselected%))>12 then cdisplay$=left$(ptxt$(cselected%),19-3)+"... ("+left$(pnumber$(cselected%),12-3)+"...)": return
if len(pnumber$(cselected%))<12 and len(ptxt$(cselected%))>34-3-len(pnumber$(cselected%)) then cdisplay$=left$(ptxt$(cselected%),34-3-3-len(pnumber$(cselected%)))+"... ("+pnumber$(cselected%)+")": return
if len(ptxt$(cselected%))<19 and len(pnumber$(cselected%))>34-3-len(ptxt$(cselected%)) then cdisplay$=ptxt$(cselected%)+" ("+left$(pnumber$(cselected%),34-3-3-len(ptxt$(cselected%)))+"...)": return
cdisplay$=ptxt$(cselected%)+" ("+pnumber$(cselected%)+")": return

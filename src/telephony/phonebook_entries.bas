PHONEBOOK_ENTRIES rem
'=== phonebook entries ===
'Private, do not upload to git
for i=1 to 5: pindex%(i)=1: psim%(i)=0: next i
pnumber$(1)="+61882013911": ptype%(1)=145 : ptxt$(1)="flinders uni"
pnumber$(2)="131444": ptype%(2)=129 : ptxt$(2)="sa police"
pnumber$(3)="000": ptype%(3)=129 : ptxt$(3)="emergency"
pnumber$(4)="": ptype%(4)=129 : ptxt$(4)=""
pnumber$(5)="": ptype%(5)=129 : ptxt$(5)=""
'test of edge cases (text or number too long to be displayed in the contact screen)
'len(pnumber)>12 and len(ptxt)>20
pindex%(6)=1: pnumber$(6)="0123456789123": ptype%(6)=129 : ptxt$(6)="a string longer than 20"
'len(pnumber)<12 and len(ptxt)+len(pnumber)>35
pindex%(7)=1: pnumber$(7)="0123456789": ptype%(7)=161 : ptxt$(7)="a string that is way way too long"
'len(ptxt)<20 and len(ptxt)+len(pnumber)>35
pindex%(8)=1: pnumber$(8)="12345678901234567890123456": ptype%(8)=161 : ptxt$(8)="short string"
return

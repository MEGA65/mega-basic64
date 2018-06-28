GOSUB_LN rem
'=== GOSUB LN subroutine ===
'Goes to line ln using gosub, if ln>0
'Argument:
'  ln: the line number to gosub to
ln$=str$(ln): if ln<=0 then return
'First, write 6 spaces (to overwrite ",00000"), in case line number is short
for i=0 to 5: poke ja+i,32:next
'Then, write the line number (right after the gosub token)
for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
'gosub to line ln
if ln>0 then gosub,00000 'This is the instruction that will be overwritten in memory
'Put the comma back for the next time we use this routine
poke ja,44
return

SETUP_DRAWING rem 'Prepare strings etc we use when drawing, to make drawing faster
' bt$ = box-top line
' bm$ = box-middle line
' br$ = box-row line
' bb$ = box-bottom line
' ll$ = line of cursor lefts
' hd$ = home, followed by lots of cursor downs
' ss$ = line of spaces
ss$="":bt$="{line-dr}": bm$="{line-ud}": br$="{line-udr}":bb$="{line-ur}":ll$="": hd$="{home}": for z = 1 to 40:bt$= bt$ + "{line-lr}": bm$=bm$+"{rght}": br$=br$+"{line-lr}": bb$=bb$+"{line-lr}":ll$=ll$+"{left}":hd$=hd$+"{down}": ss$=ss$+" ": next z: return


'=== remove quotes from string ===
' remove the leading and trailing quotes (") from string s$
'  (if it is at least 2 chars and has quotes)
REMOVE_QUOTES_STRING if len(s$)<2 then return 'string is shorter than 2 chars, we immediatly return
if left$(s$,1)=chr$(34) and right$(s$,1)=chr$(34) then s$=right$(left$(s$,len(s$)-1),len(s$)-2)
return

PETSCII_TO_ASCII rem
' converts the case of keyboard input character u$
'   lowercase PETSCII input [a-z] -> uppercase ASCII: [65,90] __+32__> [97,122]
'   uppercase PETSCII input [A-Z] -> lowercase ASCII: [193,218] __-128__> [65,90]
if asc(c$)>=65 and asc(c$)<=90 then c$=chr$(asc(c$)+32)
if asc(c$)>=193 and asc(c$)<=218 then c$=chr$(asc(c$)-128)
return 'no conversion


'=== read from keyboard ===
'receive one non-empty char from keyboard
WAIT_FOR_KEY_PRESS u$="": get u$: if u$="" goto WAIT_FOR_KEY_PRESS
return

'=== move the cursor to position xx,yy ===
'print "{home}";
MOVE_CURSOR_XX_YY print left$(hd$,yy+1)mid$(bm$,2,xx);
'MCXY1 if xx>1 then print "{rght}";: xx = xx - 1: goto MCXY1
return

'DRAW_BOX
'   Draws a w*h box with rounded corners at position x,y
'arguments
'   w: width of the box, frame included (w>=3)
'   h: height of the box, frame included (h>=3)
'   x: horizontal position of the upper-left corner (0<=x<=39)
'   y: vertical position of the upper-left corner (0<=y<=24)
'   r(): array of rows' index to be printed as lines [0:24]
'returns
'   none
DRAW_BOX if w<3 or h<3 then return
xx=x: yy=y: gosub MOVE_CURSOR_XX_YY: if h(0)=0 then print left$(bt$,w-1);"{line-dl}";
if h(0)=1 then h(0)=0: print left$(ss$,w);
for i=1 to h-2:print left$(ll$,w)"{down}";:xx=x: yy=y+i
if h(i)=1 then print " ";mid$(bm$,2,w-2);" ";
if r(i)=0 and h(i)=0 then print left$(bm$,w-1);"{line-ud}";
if r(i)=1 and h(i)=0 then print left$(br$,w-1);"{line-udl}";
r(i)=0: h(i)=0: next i: yy=y+h-1: xx=x: gosub MOVE_CURSOR_XX_YY
if h(h-1)=1 then print left$(ss$,w-1);: k=32 'print spaces and poke space
if h(h-1)=0 then print left$(bb$,w-1);: k=110 'print bottom line and poke ul corner
c=peek(646): poke 55296+(y+h-1)*40+x+w-1,c: poke 1024+(y+h-1)*40+x+w-1,k
'we poke the last character to the screen RAM (1024) and the color to the color RAM (55296), in case it's in the lower-right-hand corner, to avoid a CR/LF
h(h-1)=0
print "{home}":return

'DRAW_LINE
'   Draws a horizontal line of width w, with T-shaped sides at row r (from position x,y)
'arguments
'   w: width of the line, sides included (w>=3)
'   r: index of the row on which to print the line
'   x: horizontal position of the upper-left corner (0<=x<=39)
'   y: vertical position of the upper-left corner (0<=y<=24)
'returns
'   none
DRAW_HORIZONTAL_LINE rem
if w<3 then return
xx=x: yy=y+r: gosub MOVE_CURSOR_XX_YY:print left$(br$,w-1)"{line-udl}";:return

'TRIM_STRING
'   Trims a string s$ to length l, adding ... if too long
TRIM_STRING if len(s$)>l then s$=left$(s$,l-1)+"{elipsis}"
return

'TRIM_STRING_SPACES
'   Trims a string s$ to length l,
'      adding ... if too long
'      and adding spaces if too short
TRIM_STRING_SPACES gosub TRIM_STRING: if len(s$)<l then s$=s$+left$(ss$,l-len(s$)) 'add l-len spaces, so that len(s$)=l
return

'Remove characters <CR> and <LF> from string
'Arguments:
'  s$: the string to be modified
'Returns:
'  s$: the modified string
RM_STRING_CRLF ww$="":for i=1 to len(s$):c$=mid$(s$,i,1): if c$<>c13$ and c$<>chr$(10) then ww$=ww$+c$: goto RMSCRLF_NEXT 'add the char to string if not <CR> or <LF>
ww$=ww$+" " 'add a space if <CR> or <LF>
RMSCRLF_NEXT next i:s$=ww$:return

'Prints a string, replacing CR and LF by text <CR> and <LF>
'Arguments:
'  s$: the string to be printed
PRINT_STRING_CRLF for i=1 to len(s$): b$=right$(left$(s$,i),1)
if b$<>"" and b$<>c13$ and b$<>chr$(10) then print b$;
if b$=c13$ then print c13$+"<cr>";
if b$=chr$(10) then print "<lf>"
next i:return

'SPACES
'   Returns a string with l spaces'
SPACES s$="":if l>0 then s$=left$(ss$,l)
return

'POKE_SPACES
'   Pokes s space chars at row x, column y
'   NOTE: Probably not efficient for many characters?
POKE_SPACES a=1024+40*y+x:if s>0 then for ii=0 to s-1: poke a+ii,32: next ii
return


'=== update the battery level ===
BATTERY_UPDATE bl%=(btp+5)/10: return

CALCULATE_CURRENT_TIME mdv=5183999: nrtm=fn mod((time-nmtm)+nltm):return

'Converts a real time k to strings (thour$, tmin$, tsec$)
REAL_TIME_TO_STRINGS mdv=5183999: k=fn mod(k): thour=int(k/216000): tmin=int((k-thour*216000)/3600): tsec=int((k-thour*216000-tmin*3600)/60):thour$="": tmin$="": tsec$="": if thour>=0 and thour<=9 then thour$=thour$+"0"
thour$=thour$+right$(str$(thour), len(str$(thour))-1):if tmin>=0 and tmin<=9 then tmin$=tmin$+"0"
tmin$=tmin$+right$(str$(tmin), len(str$(tmin))-1):if tsec>=0 and tsec<=9 then tsec$=tsec$+"0"
tsec$=tsec$+right$(str$(tsec), len(str$(tsec))-1):return

'Converts a real time k to string s$ ("HH:MM:SS")
REAL_TIME_TO_STRING gosub REAL_TIME_TO_STRINGS: s$=thour$+":"+tmin$+":"+tsec$:return

'### switch to screen ###
'change the current screen
'it switches graphics/text mode only if necessary
'it triggers an initial update of the screen

'=== switch to the previous screen ===
SWITCH_TO_LAST_SCREEN ll=ls 'tmp storage of ls
if ll=0 then gosub SWITCH_TO_SCREEN_DEBUG
if ll=1 then gosub SWITCH_TO_SCREEN_DIALLER
if ll=2 then gosub SWITCH_TO_SCREEN_CONTACT
if ll=3 then gosub SWITCH_TO_SCREEN_CALL
if ll=4 then gosub SWITCH_TO_SCREEN_CONTACT_EDIT
if ll=5 then gosub SWITCH_TO_SCREEN_SMS
'set last screen back to the 2nd-last screen
ls=s2 : return

'=== switch to screen DEBUG (0) ===
SWITCH_TO_SCREEN_DEBUG gosub SWITCH_SCREEN_INIT:sc=0:gosub SWITCH_SCREEN_CLEANUP:su=1:return

'=== switch to screen DIALLER (1) ===
'set back previously highlighted contact
'Mark entire screen as requiring a re-draw
SWITCH_TO_SCREEN_DIALLER gosub SWITCH_SCREEN_INIT:sc=1:gosub SWITCH_SCREEN_CLEANUP:p=cselected%: gosub PHONEBOOK_TO_CONTACT_PANE_INDEX: hl%=k :su=1: up=1: uc=1: ud=1:return

'=== switch to screen CONTACT (2) ===
SWITCH_TO_SCREEN_CONTACT gosub SWITCH_SCREEN_INIT:sc=2:gosub SWITCH_SCREEN_CLEANUP:su=1:ul%=0:gosub PREP_CONTACT:return

'reinit SMS write status
PREP_CONTACT watus$="" :if sr%=cselected% then return
gosub EMPTY_CONTACT_SMS:mq=0: sr%=0:matus$="": return 'reinit SMS Contact status if change of contact

'=== switch to screen CALL (3) ===
SWITCH_TO_SCREEN_CALL gosub SWITCH_SCREEN_INIT:sc=3:gosub SWITCH_SCREEN_CLEANUP:su=1:return

'=== switch to screen CONTACT_EDIT (4) ===
SWITCH_TO_SCREEN_CONTACT_EDIT gosub SWITCH_SCREEN_INIT:sc=4:gosub SWITCH_SCREEN_CLEANUP:su=1:hl%=0: ul%=0
if ctrigger=1 and cselected%<=0 then stop 'we should have cselected% pointing to the contact to edit
if ctrigger=1 and cselected%>0 then gosub PREP_EDIT_CONTACT: return
if ctrigger=2 then cselected%=0
if ctrigger>2 then stop 'that shouldn't happen
return

'=== switch to screen SMS (5) ===
SWITCH_TO_SCREEN_SMS gosub SWITCH_SCREEN_INIT:sc=5:gosub SWITCH_SCREEN_CLEANUP:su=1:gosub SMS_TO_SMS_PANE:return

PREP_EDIT_CONTACT cfields$(1)=ptxt$(cselected%):cfields$(2)=pnumber$(cselected%):return

SWITCH_SCREEN_CLEANUP u0$="": u$="":gosub VIRTUAL_KEYBOARD_DISABLE
' Fall through to ERASE_SCREEN

ERASE_SCREEN print "{clr}";: canvas 0 clr: return

SWITCH_SCREEN_INIT if sc<>0 then s2=ls: ls=sc 'don't change the last screen to debug when switching from debug to another screen
if sc=0 then ls=s2 'when switching from debug to another screen, set last screen back to the 2nd-last screen
return

'enable hardware zoom (795 and 796)
 'use primary keyboard
 'place it at the bottom position
'center horizontally (21 centers the vk on the touchscreen)
 'make it appear
VIRTUAL_KEYBOARD_ENABLE poke 54795,192:poke 54796,192 :poke 54807,127 :poke 54806,127 :poke 54809,21:poke 54805,255:return

'disable hardware zoom, hide keyboard
VIRTUAL_KEYBOARD_DISABLE poke 54795,0:poke 54805,127:return

VIRTUAL_KEYBOARD_IS_ENABLED b=0:k=peek(54805):if k=255 then b=1
return

VIRTUAL_KEYBOARD_SWITCH gosub VIRTUAL_KEYBOARD_IS_ENABLED:if b=1 goto VIRTUAL_KEYBOARD_DISABLE
goto VIRTUAL_KEYBOARD_ENABLE

VIRTUAL_KEYBOARD_UP poke 54806,255: return

VIRTUAL_KEYBOARD_DOWN poke 54806,127: return


SD_CARD_STORE_SMS return 'should return the index on SD card in which it was stored

SD_CARD_GET_SMS return 'subroutine to get an SMS, given an index, from SD card

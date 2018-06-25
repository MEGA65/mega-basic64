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
'box-top line
bt$="{line-dr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}"
'box-middle line
bm$="{line-ud}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}"
'box-row line
br$="{line-udr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}"
'box-bottom line
bb$="{line-ur}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}{line-lr}"
'left line
ll$="{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}"
'home-down line
hd$="{home}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}"
'space line
ss$="                                         "
return


REMOVE_QUOTES_STRING rem
'=== remove quotes from string ===
' remove the leading and trailing quotes (") from string s$
'  (if it is at least 2 chars and has quotes)
if len(s$)<2 then return 'string is shorter than 2 chars, we immediatly return
if left$(s$,1)=chr$(34) and right$(s$,1)=chr$(34) then s$=right$(left$(s$,len(s$)-1),len(s$)-2)
return

PETSCII_TO_ASCII rem
' converts the case of keyboard input character u$
'   lowercase PETSCII input [a-z] -> uppercase ASCII: [65,90] __+32__> [97,122]
'   uppercase PETSCII input [A-Z] -> lowercase ASCII: [193,218] __-128__> [65,90]
if asc(c$)>=65 and asc(c$)<=90 then c$=chr$(asc(c$)+32): return
if asc(c$)>=193 and asc(c$)<=218 then c$=chr$(asc(c$)-128): return
return 'no conversion


WAIT_FOR_KEY_PRESS rem
'=== read from keyboard ===
'receive one non-empty char from keyboard
WFKP_LOOP u$="": get u$: if u$="" goto WFKP_LOOP
return

MOVE_CURSOR_XX_YY rem
'=== move the cursor to position xx,yy ===
'print "{home}";
print left$(hd$,yy+1);
print mid$(bm$,2,xx);
'MCXY1 if xx>1 then print "{rght}";: xx = xx - 1: goto MCXY1
return

DRAW_BOX rem
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
if w<3 or h<3 then return
xx=x: yy=y: gosub MOVE_CURSOR_XX_YY
if h(0)=0 then print left$(bt$,w-1);"{line-dl}";
if h(0)=1 then h(0)=0: print left$(ss$,w);
for i=1 to h-2
print left$(ll$,w);"{down}";
xx=x: yy=y+i
if h(i)=1 then print " ";mid$(bm$,2,w-2);" ";
if r(i)=0 and h(i)=0 then print left$(bm$,w-1);"{line-ud}";
if r(i)=1 and h(i)=0 then print left$(br$,w-1);"{line-udl}";
r(i)=0: h(i)=0: next i
yy=y+h-1: xx=x: gosub MOVE_CURSOR_XX_YY
if h(h-1)=1 then print left$(ss$,w-1);: k=32 'print spaces and poke space
if h(h-1)=0 then print left$(bb$,w-1);: k=110 'print bottom line and poke ul corner
c=peek(646): poke 55296+(y+h-1)*40+x+w-1,c: poke 1024+(y+h-1)*40+x+w-1,k
'we poke the last character to the screen RAM (1024) and the color to the color RAM (55296), in case it's in the lower-right-hand corner, to avoid a CR/LF
h(h-1)=0
print "{home}"
return

DRAW_HORIZONTAL_LINE rem
'DRAW_LINE
'   Draws a horizontal line of width w, with T-shaped sides at row r (from position x,y)
'arguments
'   w: width of the line, sides included (w>=3)
'   r: index of the row on which to print the line
'   x: horizontal position of the upper-left corner (0<=x<=39)
'   y: vertical position of the upper-left corner (0<=y<=24)
'returns
'   none
if w<3 then return
xx=x: yy=y+r: gosub MOVE_CURSOR_XX_YY
print left$(br$,w-1);"{line-udl}";
return


TRIM_STRING rem
'TRIM_STRING
'   Trims a string s$ to length l, adding ... if too long
if len(s$)<=l then return
if len(s$)>l then s$=left$(s$,l-1)+"{elipsis}": return

TRIM_STRING_SPACES rem
'TRIM_STRING_SPACES
'   Trims a string s$ to length l,
'      adding ... if too long
'      and adding spaces if too short
gosub TRIM_STRING
if len(s$)<l then s$=s$+left$(ss$,l-len(s$)) 'add l-len spaces, so that len(s$)=l
return

RM_STRING_CRLF rem
'Remove characters <CR> and <LF> from string
'Arguments:
'  s$: the string to be modified
'Returns:
'  s$: the modified string
ww$="" 'temp string
for i=1 to len(s$)
c$=mid$(s$,i,1)
if c$<>chr$(13) and c$<>chr$(10) then ww$=ww$+c$: goto RMSCRLF_NEXT 'add the char to string if not <CR> or <LF>
ww$=ww$+" " 'add a space if <CR> or <LF>
RMSCRLF_NEXT next i
s$=ww$ 'set s$ to the new string
return

PRINT_STRING_CRLF rem
'Prints a string, replacing CR and LF by text <CR> and <LF>
'Arguments:
'  s$: the string to be printed
for i=1 to len(s$): b$=right$(left$(s$,i),1)
if b$<>"" and b$<>chr$(13) and b$<>chr$(10) then print b$;
if b$=chr$(13) then print chr$(13)+"<cr>";
if b$=chr$(10) then print "<lf>"+chr$(13);
next i
return

SPACES rem
'SPACES
'   Returns a string with l spaces'
s$=""
if l>0 then s$=left$(ss$,l)
return

POKE_SPACES rem
'POKE_SPACES
'   Pokes s space chars at row x, column y
'   NOTE: Probably not efficient for many characters?
a=1024+40*y+x
if s>0 then for ii=0 to s-1: poke a+ii,32: next ii
return


BATTERY_UPDATE rem
'=== update the battery level ===
if btp>=0 and btp <=5 then bl%=0
if btp>5 and btp <=15 then bl%=1
if btp>15 and btp <=25 then bl%=2
if btp>25 and btp <=35 then bl%=3
if btp>35 and btp <=45 then bl%=4
if btp>45 and btp <=55 then bl%=5
if btp>55 and btp <=65 then bl%=6
if btp>65 and btp <=75 then bl%=7
if btp>75 and btp <=85 then bl%=8
if btp>85 and btp <=95 then bl%=9
if btp>95 and btp <=100 then bl%=10
return

CALCULATE_CURRENT_TIME rem
mdv=5183999: nrtm=fn mod((time-nmtm)+nltm)
return

REAL_TIME_TO_STRINGS rem
'Converts a real time k to strings (thour$, tmin$, tsec$)
mdv=5183999: k=fn mod(k)
thour=int(k/216000)
tmin=int((k-thour*216000)/3600)
tsec=int((k-thour*216000-tmin*3600)/60)
thour$="": tmin$="": tsec$=""
if thour>=0 and thour<=9 then thour$=thour$+"0"
thour$=thour$+right$(str$(thour), len(str$(thour))-1)
if tmin>=0 and tmin<=9 then tmin$=tmin$+"0"
tmin$=tmin$+right$(str$(tmin), len(str$(tmin))-1)
if tsec>=0 and tsec<=9 then tsec$=tsec$+"0"
tsec$=tsec$+right$(str$(tsec), len(str$(tsec))-1)
return

REAL_TIME_TO_STRING rem
'Converts a real time k to string s$ ("HH:MM:SS")
gosub REAL_TIME_TO_STRINGS
s$=thour$+":"+tmin$+":"+tsec$
return

'### switch to screen ###
'change the current screen
'it switches graphics/text mode only if necessary
'it triggers an initial update of the screen

SWITCH_TO_LAST_SCREEN rem
'=== switch to the previous screen ===
ll=ls 'tmp storage of ls
if ll=0 then gosub SWITCH_TO_SCREEN_DEBUG
if ll=1 then gosub SWITCH_TO_SCREEN_DIALLER
if ll=2 then gosub SWITCH_TO_SCREEN_CONTACT
if ll=3 then gosub SWITCH_TO_SCREEN_CALL
if ll=4 then gosub SWITCH_TO_SCREEN_CONTACT_EDIT
if ll=5 then gosub SWITCH_TO_SCREEN_SMS
ls=s2 'set last screen back to the 2nd-last screen
return

SWITCH_TO_SCREEN_DEBUG rem
'=== switch to screen DEBUG (0) ===
gosub SWITCH_SCREEN_INIT
sc=0
gosub SWITCH_SCREEN_CLEANUP
su=1
return

SWITCH_TO_SCREEN_DIALLER rem
'=== switch to screen DIALLER (1) ===
gosub SWITCH_SCREEN_INIT
sc=1
gosub SWITCH_SCREEN_CLEANUP
p=cselected%: gosub PHONEBOOK_TO_CONTACT_PANE_INDEX: hl%=k 'set back previously highlighted contact
'Mark entire screen as requiring a re-draw
su=1: up=1: uc=1: ud=1
return

SWITCH_TO_SCREEN_CONTACT rem
'=== switch to screen CONTACT (2) ===
gosub SWITCH_SCREEN_INIT
sc=2
gosub SWITCH_SCREEN_CLEANUP
su=1
ul%=0
gosub PREP_CONTACT
return

PREP_CONTACT rem
watus$="" 'reinit SMS write status
if sr%=cselected% then return
gosub EMPTY_CONTACT_SMS
mq=0: sr%=0
matus$="" 'reinit SMS Contact status if change of contact
return

SWITCH_TO_SCREEN_CALL rem
'=== switch to screen CALL (3) ===
gosub SWITCH_SCREEN_INIT
sc=3
gosub SWITCH_SCREEN_CLEANUP
su=1
return

SWITCH_TO_SCREEN_CONTACT_EDIT rem
'=== switch to screen CONTACT_EDIT (4) ===
gosub SWITCH_SCREEN_INIT
sc=4
gosub SWITCH_SCREEN_CLEANUP
su=1
hl%=0: ul%=0
if ctrigger=1 and cselected%<=0 then stop 'we should have cselected% pointing to the contact to edit
if ctrigger=1 and cselected%>0 then gosub PREP_EDIT_CONTACT: return
if ctrigger=2 then cselected%=0
if ctrigger>2 then stop 'that shouldn't happen
return

SWITCH_TO_SCREEN_SMS rem
'=== switch to screen SMS (5) ===
gosub SWITCH_SCREEN_INIT
sc=5
gosub SWITCH_SCREEN_CLEANUP
su=1
gosub SMS_TO_SMS_PANE
return

PREP_EDIT_CONTACT rem
cfields$(1)=ptxt$(cselected%)
cfields$(2)=pnumber$(cselected%)
return

SWITCH_SCREEN_CLEANUP rem
u0$="": u$=""
print "{clr}";: canvas 0 clr
gosub VIRTUAL_KEYBOARD_DISABLE
return

ERASE_SCREEN print "{clr}";: canvas 0 clr: return

SWITCH_SCREEN_INIT rem
if sc<>0 then s2=ls: ls=sc 'don't change the last screen to debug when switching from debug to another screen
if sc=0 then ls=s2 'when switching from debug to another screen, set last screen back to the 2nd-last screen
return


VIRTUAL_KEYBOARD_ENABLE rem
poke 54795,192 'enable hardware zoom
poke 54796,192 ' "
poke 54807,127 'use primary keyboard
poke 54806,127 'place it at the bottom position
poke 54809,21 'center horizontally (21 centers the vk on the touchscreen)
poke 54805,255 'make it appear
return

VIRTUAL_KEYBOARD_DISABLE rem
poke 54795,0 'disable hardware zoom
poke 54805,127
return

VIRTUAL_KEYBOARD_IS_ENABLED rem
b=0
k=peek(54805)
if k=255 then b=1: return
if k=127 then return
return

VIRTUAL_KEYBOARD_SWITCH rem
gosub VIRTUAL_KEYBOARD_IS_ENABLED
if b=1 then gosub VIRTUAL_KEYBOARD_DISABLE: return
if b=0 then gosub VIRTUAL_KEYBOARD_ENABLE: return

VIRTUAL_KEYBOARD_UP poke 54806,255: return

VIRTUAL_KEYBOARD_DOWN poke 54806,127: return


SD_CARD_STORE_SMS return 'should return the index on SD card in which it was stored

SD_CARD_GET_SMS return 'subroutine to get an SMS, given an index, from SD card

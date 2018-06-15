GOTO_LN rem
'=== gosub X subroutine ===
'goes to line ln, if ln>0
ln$=str$(ln): if ln<=0 then return
'first rub out with spaces in case line number is short
for i=0 to 5: poke ja+i,32:next
for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
'gosub to line ln
if ln>0 then gosub,00000
'put the comma back in case we want to run again
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


WRITE_STRING_TO_MODEM rem
'=== send to modem ===
'send string in s$ to modem
if db>=4 then print "Sent to modem: "+left$(s$, len(s$)-1)
for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
return

WAIT_MODEM_READY rem
if db>=5 then print "wait modem ready"
WMR if db>=5 then print "  jt%(99)=",jt%(99)
if jt%(99)<>0 then gosub POLL_MODEM: goto WMR
if db>=5 then print "modem ready"
return

WRITE_STRING_TO_MODEM_READY rem
gosub WAIT_MODEM_READY
gosub WRITE_STRING_TO_MODEM
return

MODEM_READY jt%(99)=0: return


REMOVE_QUOTES_STRING rem
'=== remove quotes from string ===
' remove the leading and trailing quotes (") from string s$
'  (if it has quotes) 
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
print "{home}";
print left$(hd$,yy+1);
print mid$(bm$,2,xx);
'MCXY1 if xx>1 then print "{rght}";: xx = xx - 1: goto MCXY1
return

DRAW_BOX rem
'DRAW_BOX
'   Draws a w*h box with rounded corners at position x,y
'arguments
'   w: width of the box, frame included (w>=3)
'   h: width of the box, frame included (h>=3)
'   x: horizontal position of the upper-left corner (0<=x<=39)
'   y: vertical position of the upper-left corner (0<=y<=24)
'   r(): array of rows' index to be printed as lines [0:24]
'returns
'   none
if w<3 or h<3 then return
xx=x: yy=y: gosub MOVE_CURSOR_XX_YY
print left$(bt$,w-1);"{line-dl}";
for i=1 to h-2
print left$(ll$,w);"{down}";
xx=x: yy=y+i
if r(i)=0 then print left$(bm$,w-1);"{line-ud}";
if r(i)=1 then print left$(br$,w-1);"{line-udl}";
r(i)=0: next i
yy=y+h-1:xx=x:gosub MOVE_CURSOR_XX_YY
print left$(bb$,w-1);
c=peek(646): poke 55296+(y+h-1)*40+x+w-1,c: poke 1024+(y+h-1)*40+x+w-1,110
'we poke the last character to the screen RAM (1024) and the color to the color RAM (55296), in case it's in the lower-right-hand corner, to avoid a CR/LF
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
kk=sc 'tmp storage of sc
ll=ls 'tmp storage of ls
if ll=0 then gosub SWITCH_TO_SCREEN_DEBUG
if ll=1 then gosub SWITCH_TO_SCREEN_DIALLER
if ll=2 then gosub SWITCH_TO_SCREEN_CONTACT
if ll=3 then gosub SWITCH_TO_SCREEN_CALL
if ll=4 then gosub SWITCH_TO_SCREEN_CONTACT_EDIT
ls=kk
return

SWITCH_TO_SCREEN_DEBUG rem
'=== switch to screen DEBUG (0) ===
ls=sc: sc=0
gosub SWITCH_SCREEN_CLEANUP
su=1
return

SWITCH_TO_SCREEN_DIALLER rem
'=== switch to screen DIALLER (1) ===
ls=sc: sc=1
gosub SWITCH_SCREEN_CLEANUP
p=cselected%: gosub PHONEBOOK_TO_CONTACT_PANE_INDEX: hl%=k 'set back previously highlighted contact
'Mark entire screen as requiring a re-draw
su=1: up=1: uc=1: ud=1
return

SWITCH_TO_SCREEN_CONTACT rem
'=== switch to screen CONTACT (2) ===
ls=sc: sc=2
gosub SWITCH_SCREEN_CLEANUP
su=1
return

SWITCH_TO_SCREEN_CALL rem
'=== switch to screen CALL (3) ===
ls=sc: sc=3
gosub SWITCH_SCREEN_CLEANUP
su=1
return

SWITCH_TO_SCREEN_CONTACT_EDIT rem
'=== switch to screen CONTACT_EDIT (4) ===
ls=sc: sc=4
gosub SWITCH_SCREEN_CLEANUP
su=1
hl%=0: ul%=0
if ctrigger=1 and cselected%<=0 then stop 'we should have cselected% pointing to the contact to edit
if ctrigger=1 and cselected%>0 then gosub PREP_EDIT_CONTACT: return
if ctrigger=2 then cselected%=0
if ctrigger>2 then stop 'that shouldn't happen
return

PREP_EDIT_CONTACT rem
cfields$(1)=ptxt$(cselected%)
cfields$(2)=pnumber$(cselected%)
return

SWITCH_SCREEN_CLEANUP rem
u0$="": u$=""
print "{clr}";: canvas 0 clr
return

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
bt$="UCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
bm$="B{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}{rght}"
bb$="JCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
ll$="{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}{left}"
hd$="{home}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}{down}"
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
print left$(bt$,w-1);"I";
for i=1 to h-2
print left$(ll$,w);"{down}";
xx=x: yy=y+i
print left$(bm$,w-1);"B";
next i
yy=y+h-1:xx=x:gosub MOVE_CURSOR_XX_YY
print left$(bb$,w-1);
c=peek(646): poke 55296+(y+h-1)*40+x+w-1,c: poke 1024+(y+h-1)*40+x+w-1,75
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
print chr$(171);: for j=1 to w-2: print "C";: next j: print chr$(179);
return


TRIM_STRING rem
'TRIM_STRING
'   Trims a string s$ to length l, adding ... if necessary
if len(s$)<=l then return
if len(s$)>l then s$=left$(s$,len(s$)-3)+"...": return


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
if ctrigger=1 and cselected%<=0 then stop 'we should have cselected% pointing to the contact to edit
if ctrigger=1 and cselected%>0 then gosub PREP_EDIT_CONTACT: return
if ctrigger=2 then cselected%=0
if ctrigger>2 then stop 'that shouldn't happen
return

PREP_EDIT_CONTACT rem
cnumber$=pnumber$(cselected%)
ctxt$=ptxt$(cselected%)
return

SWITCH_SCREEN_CLEANUP rem
u0$="": u$=""
print "{clr}";: canvas 0 clr
return

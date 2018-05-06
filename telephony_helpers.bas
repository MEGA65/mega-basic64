GOTO_LN rem "=== goto X subroutine ==="
rem "goes to line ln, if ln>0"
ln$=str$(ln): if ln<=0 then return
for i=0 to 5: poke ja+i,32:next: rem "first rub out with spaces in case line number is short"
for i=0 to len(ln$)-1: poke ja+i,asc(right$(left$(ln$,i+1),1)):next
if ln>0 then gosub,00000: rem "gosub to line ln"
poke ja,44: rem "put the comma back in case we want to run again"
return

WRITE_STRING_TO_MODEM rem "=== send to modem ==="
rem "send string in s$ to modem"
for i=1 to len(s$): c$=right$(left$(s$,i),1): print#1,c$;: next i
return

WAIT_FOR_KEY_PRESS rem "=== read from keyboard ==="
rem "receive one non-empty char from keyboard"
WFKP_LOOP u$="": get u$: if u$="" goto WFKP_LOOP
return

MOVE_CURSOR_XX_YY rem "=== move the cursor to position xx,yy ==="
print "{home}";
if xx>0 then for ii=1 to xx: print "{rght}";: next ii
if yy>0 then for jj=1 to yy: print "{down}";: next jj
return

BATTERY_UPDATE rem "=== update the battery level ==="
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


rem "### switch to SCREEN ###"
rem "change the current screen"
rem "it switches graphics/text mode only if necessary"
rem "it triggers an initial update of the screen"

SWITCH_TO_SCREEN_0 rem "=== switch to screen 0 (debug) ==="
sc=0
print "{clr}";: canvas 0 clr: rem "clear screen"
gosub DRAW_SCREEN_0
return

SWITCH_TO_SCREEN_1 rem "=== switch to screen 1 ==="
sc=1
print "{clr}";: canvas 0 clr: rem "clear screen"
if peek(53272)=22 or peek(53272)=134 then poke 53272,132: rem "we want graphics mode"
gosub DRAW_SCREEN_1: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_2 rem "=== switch to screen 2 ==="
sc=2
print "{clr}";: canvas 0 clr: rem "clear screen"
if peek(53272)=20 or peek(53272)=132 then poke 53272,134: rem "we want text mode"
gosub DRAW_SCREEN_2: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_3 rem "=== switch to screen 3 ==="
sc=3
print "{clr}";: canvas 0 clr: rem "clear screen"
if peek(53272)=20 or peek(53272)=132 then poke 53272,134: rem "we want text mode"
gosub DRAW_SCREEN_3: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_4 rem "=== switch to screen 4 ==="
sc=4
print "{clr}";: canvas 0 clr: rem "clear screen"
if peek(53272)=20 or peek(53272)=132 then poke 53272,134: rem "we want text mode"
gosub DRAW_SCREEN_4: rem "trigger initial screen update"
return

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
if xx>0 then for i=1 to xx: print "{rght}";: next i
if yy>0 then for j=1 to yy: print "{down}";: next j
return


rem "### switch to SCREEN ###"
rem "change the current screen"
rem "it switches graphics/text mode only if necessary"
rem "it triggers an initial update of the screen"

SWITCH_TO_SCREEN_0 rem "=== switch to screen 0 (debug) ==="
sc=0 
gosub DRAW_SCREEN_0
return

SWITCH_TO_SCREEN_1 rem "=== switch to screen 1 ==="
sc=1
if peek(53272)=22 or peek(53272)=134 then poke 53272,21: rem "we want graphics mode"
gosub DRAW_SCREEN_1: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_2 rem "=== switch to screen 2 ==="
sc=2
if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
gosub DRAW_SCREEN_2: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_3 rem "=== switch to screen 3 ==="
sc=3
if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
gosub DRAW_SCREEN_3: rem "trigger initial screen update"
return

SWITCH_TO_SCREEN_4 rem "=== switch to screen 4 ==="
sc=4
if peek(53272)=20 or peek(53272)=132 then poke 53272,23: rem "we want text mode"
gosub DRAW_SCREEN_4: rem "trigger initial screen update"
return

HANDLER_SCREEN_1 rem "### SC 1 (DIALER) HANDLER ###"
rem "read input chars and update string (phone number)"
if su=1 then gosub DRAW_SCREEN_1: su=0
u$="": get u$
if fn m1k(cnt)=0 then gosub DRAW_SCREEN_1: rem "we trigger a screen update every 1000 loops"
tmr=tmr-1: if tmr=0 then gosub DRAW_SCREEN_1_TILES: us=1: rem "we trigger a dial tiles update every 1000 loops since last"
if u$="" then return
if u$<>chr$(20) and u$<>chr$(13) and len(nb$)>=19 then return: rem "limit length is 18, go to loop start"
if u$="0" or u$="1" or u$="2" or u$="3" or u$="4" or u$="5" or u$="6" or u$="7" or u$="8" or u$="9" or u$="+" or u$="*" or u$="#" or u$="a" or u$="b" or u$="c" or u$="d" then nb$=nb$+u$: gosub DRAW_SCREEN_1
if u$="-" or u$="/" or u$="=" or u$="@" or u$="<" or u$=">" then gosub DRAW_SCREEN_1: rem "these characters don't update the string (for now)"
if u$=chr$(20) and len(nb$)>=1 then nb$=left$(nb$,len(nb$)-1): gosub DRAW_SCREEN_1: rem "remove a character, but only if there's at least one"
if u$=chr$(13) then gosub DRAW_SCREEN_1: gosub SWITCH_TO_SCREEN_4: s$="atd"+nb$+";"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "dial the number and switch to screen 4"
return

HANDLER_SCREEN_2 rem "### SC 2 (RING) HANDLER ###"
if su=1 then gosub DRAW_SCREEN_2: su=0
if fn m1k(cnt)=0 then gosub DRAW_SCREEN_2
u$="": get u$
if u$="a" or u$="A" then goto HS2_A
if u$="r" or u$="R" then goto HS2_R
return : rem "unexpected char"
HS2_A rem "--- Answer call (A) ---"
s$="ata"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send ATA (answer)"
gosub SWITCH_TO_SCREEN_3: rem "SCREEN 3 (IN-CALL)"
rem "we should wait for OK (OR ERROR)!!"
return
HS2_R rem "--- Decline call (R) ---"
s$="at+chup"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send AT+CHUP (call hang up)"
gosub SWITCH_TO_SCREEN_1: rem "SCREEN 1 (DIALER)"
rem "we should wait for OK (OR ERROR)!!"
return

HANDLER_SCREEN_3 rem "### SC 3 (IN-CALL) HANDLER ###"
if su=1 then gosub DRAW_SCREEN_3: su=0
if fn m1k(cnt)=0 then gosub DRAW_SCREEN_3
u$="": get u$
if u$="h" or u$="H" then goto HS3_H
return : rem "not H"
HS3_H rem "--- Hang-up call (H) ---"
s$="at+chup"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send AT+CHUP (call hang up)"
gosub SWITCH_TO_SCREEN_1: rem "SCREEN 1 (DIALER)"
rem "we should wait for OK (OR ERROR)!!"
return

HANDLER_SCREEN_4 rem "### SC 4 (DIALLING) HANDLER ###"
if su=1 then gosub DRAW_SCREEN_4: su=0
if fn m1k(cnt)=0 then gosub DRAW_SCREEN_4
u$="":get u$
if u$="h" or u$="H" then goto HS4_H
return : rem "not H"
HS4_H rem "--- Hang-up call (H) ---"
s$="ath"+chr$(13): gosub WRITE_STRING_TO_MODEM: rem "send ATH (hang up)"
gosub SWITCH_TO_SCREEN_1: rem "SCREEN 1 (DIALER)"
rem "we should wait for OK (OR ERROR)!!"
dr$="": rem "reset dialling result"
return

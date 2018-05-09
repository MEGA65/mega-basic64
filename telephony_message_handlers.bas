9999 rem "### MESSAGE HANDLERS ###"
9999 rem "we actually have to force the line numbers for the jump-table mechanism to work"
9999 rem "we could keep line numbers instead of labels, if we don't use those labels at all (outside of the jump-table)"

MESSAGE_HANDLER_0 rem "Message handler: unknown/free-form"
10099 return

MESSAGE_HANDLER_1 rem "Message handler: message type 1"
10199 return

MESSAGE_HANDLER_2 rem "Message handler: message type 2"
10299 return

MESSAGE_HANDLER_3 rem "Message handler: message type 3"
10399 return

MESSAGE_HANDLER_4 rem "Message handler: message type 4"
10499 return

MESSAGE_HANDLER_5 rem "Message handler: message type 5"
10599 return

MESSAGE_HANDLER_6 rem "Message handler: message type 6"
10699 return

MESSAGE_HANDLER_7 rem "Message handler: message type 7"
10799 return

MESSAGE_HANDLER_8 rem "Message handler: message type 8"
10899 return

MESSAGE_HANDLER_9 rem "Message handler: message type 9"
10999 return

MESSAGE_HANDLER_10 rem "Message handler: message type 10"
11099 return

MESSAGE_HANDLER_11 rem "Message handler: message type 11"
11199 return

MESSAGE_HANDLER_12 rem "Message handler: message type 12"
11299 return

MESSAGE_HANDLER_13 rem "Message handler: message type 13"
11399 return

MESSAGE_HANDLER_14 rem "Message handler: message type 14"
11499 return

MESSAGE_HANDLER_15 rem "Message handler: message type 15"
11599 return

MESSAGE_HANDLER_16 rem "Message handler: message type 16"
11699 return

MESSAGE_HANDLER_17 rem "Message handler: message type 17"
11799 return

MESSAGE_HANDLER_18 rem "Message handler: message type 18"
11899 return

MESSAGE_HANDLER_19 rem "Message handler: message type 19"
11999 return

MESSAGE_HANDLER_20 rem "Message handler: message type 20"
12099 return

MESSAGE_HANDLER_21 rem "Message handler: message type 21"
12199 return

MESSAGE_HANDLER_22 rem "Message handler: message type 22"
12299 return

MESSAGE_HANDLER_23 rem "Message handler: message type 23"
12399 return

MESSAGE_HANDLER_24 rem "Message handler: message type 24"
12499 return

MESSAGE_HANDLER_25 rem "Message handler: message type 25"
12599 return

MESSAGE_HANDLER_26 rem "Message handler: message type 26"
12699 return

MESSAGE_HANDLER_27 rem "Message handler: message type 27"
12799 return

MESSAGE_HANDLER_28 rem "Message handler: message type 28"
12899 return

MESSAGE_HANDLER_29 rem "Message handler: message type 29"
12999 return

MESSAGE_HANDLER_30 rem "Message handler: message type 30"
13099 return

MESSAGE_HANDLER_31 rem "Message handler: message type 31"
13199 return

MESSAGE_HANDLER_32 rem "Message handler: message type 32"
13299 return

MESSAGE_HANDLER_33 rem "Message handler: message type 33"
13399 return

MESSAGE_HANDLER_34 rem "Message handler: message type 34"
13499 return

MESSAGE_HANDLER_35 rem "Message handler: message type 35"
13599 return

MESSAGE_HANDLER_36 rem "Message handler: message type 36"
13699 return

MESSAGE_HANDLER_37 rem "Message handler: message type 37"
13799 return

MESSAGE_HANDLER_38 rem "Message handler: message type 38"
13899 return

MESSAGE_HANDLER_39 rem "Message handler: message type 39"
13999 return

MESSAGE_HANDLER_OK rem "Message handler: OK"
if dia=1 then gosub SEND_AT+CLCC: rem "ATD succeeded, dialling..."
14099 return

MESSAGE_HANDLER_41 rem "Message handler: message type 41"
14199 return

MESSAGE_HANDLER_RING rem "Message handler: incoming call (ring)"
gosub SEND_AT+CLCC
if dactive=0 then dactive=1: gosub SWITCH_TO_SCREEN_CALL
# "else: already in-call"
14299 return


MESSAGE_HANDLER_NO_CARRIER rem "Message handler: no carrier"
# "TODO: depending on which screen we are, we can set different messages to be displayed to the user when the call is hung up"
if dactive=1 then goto MH_NC_ACTIVE
# "else: already in-call"
goto MH_NC_END

MH_NC_ACTIVE rem "active call"
# "hang-up the active call"
gosub CALL_HANGUP
gosub SWITCH_TO_SCREEN_1
goto MH_NC_END

MH_NC_END rem
14399 return



MESSAGE_HANDLER_44 rem "Message handler: message type 44"
14499 return

MESSAGE_HANDLER_45 rem "Message handler: message type 45"
14599 return

MESSAGE_HANDLER_NO_DIAL_TONE rem "Message handler: no dial tone"
14610 if sc=4 then dr$="no dial tone"
14699 return

MESSAGE_HANDLER_BUSY rem "Message handler: busy"
14710 if sc=4 then dr$="target is busy"
14799 return

MESSAGE_HANDLER_NO_ANSWER rem "Message handler: no answer"
14899 return

MESSAGE_HANDLER_49 rem "Message handler: message type 49"
14999 return

MESSAGE_HANDLER_50 rem "Message handler: message type 50"
15099 return



MESSAGE_HANDLER_+CLCC rem "Message handler: +clcc (list current calls)"
# "update state and caller id only if voice call, and call active"
if mf$(4)="0" and dactive=1 then goto MH_CLCC_VOICE
return

MH_CLCC_VOICE rem
# "--- voice call ---"
# "set caller id (cid$)"
cid$=right$(left$(mf$(6),len(mf$(6))-1),len(mf$(6))-2): su=1
# "update call state (dsta)"
dsta=-1
if mf$(3)="0" then dsta=0
if mf$(3)="1" then dsta=1
if mf$(3)="2" then dsta=2
if mf$(3)="3" then dsta=3
if mf$(3)="4" then dsta=4
if mf$(3)="5" then dsta=5

if dia=1 then goto MH_CLCC_DIALLING
goto MH_CLCC_END

MH_CLCC_DIALLING rem
# "--- dialling ---"
if dsta=2 then dr$="dialling..."
if dsta=3 then dr$="alerting..."
# "0: the call has been established"
if dsta=0 then dr$="": dia=0: cid$=dnumber$
goto MH_CLCC_END

MH_CLCC_END rem
# "send again the at+clcc command"
gosub SEND_AT+CLCC
15199 return



MESSAGE_HANDLER_+CSQ rem "Message handler: +csq (signal quality report)"
rssi=val(mf$(1)): ber=val(mf$(2))
if rssi=99 or rssi=199 then sl%=0
if rssi>=0 and rssi<=31 then sl%=int((rssi/32*5)+1)
if rssi>=100 and rssi<=191 then sl%=int(((rssi-100)/92*5)+1)
if ber>=0 and ber<=7 then ber$=str$(ber)
if ber=99 then ber$="?"
su=1: rem "trigger screen update"
15299 return

MESSAGE_HANDLER_+QNWINFO rem "Message handler: +qnwinfo (network information report)"
nact$=right$(left$(mf$(1),len(mf$(1))-1),len(mf$(1))-2): rem "get nwact, without quotes"
nt$="?": rem "nwact is not in the following list (should not happen)"
if nact$="none" then nt$=""
if nact$="cdma1x" then nt$="3g": rem "3g? abbreviation to check"
if nact$="cdma1x and hdr" then nt$="3g": rem "3g? abbreviation to check"
if nact$="cdma1x and ehrpd" then nt$="3g": rem "3g? abbreviation to check"
if nact$="hdr" then nt$="2g": rem "2g? abbreviation to check"
if nact$="hdr-ehrpd" then nt$="3g": rem "3g? abbreviation to check"
if nact$="gsm" then nt$="2g"
if nact$="gprs" then nt$="g"
if nact$="edge" then nt$="e"
if nact$="wcdma" then nt$="3g"
if nact$="hsdpa" then nt$="h"
if nact$="hsupa" then nt$="h"
if nact$="hspa+" then nt$="h+"
if nact$="tdscdma" then nt$="3g"
if nact$="tdd lte" then nt$="lte"
if nact$="fdd lte" then nt$="lte"
su=1: rem "trigger screen update"
15399 return

MESSAGE_HANDLER_+QSPN rem "Message handler: +QSPN (registered network name report)"
nname$=right$(left$(mf$(2),len(mf$(2))-1),len(mf$(2))-2): rem "get SNN, without quotes"
rem "mf$(1) is FNN (Full Network Name), mf$(2) is SNN (Short Network Name)"
su=1: rem "trigger screen update"
15499 return

MESSAGE_HANDLER_55 rem "Message handler: message type 55"
15599 return

MESSAGE_HANDLER_56 rem "Message handler: message type 56"
15699 return

MESSAGE_HANDLER_57 rem "Message handler: message type 57"
15799 return

MESSAGE_HANDLER_58 rem "Message handler: message type 58"
15899 return

MESSAGE_HANDLER_59 rem "Message handler: message type 59"
15999 return

MESSAGE_HANDLER_60 rem "Message handler: message type 60"
16099 return

MESSAGE_HANDLER_61 rem "Message handler: message type 61"
16199 return

MESSAGE_HANDLER_62 rem "Message handler: message type 62"
16299 return

MESSAGE_HANDLER_63 rem "Message handler: message type 63"
16399 return

MESSAGE_HANDLER_64 rem "Message handler: message type 64"
16499 return

MESSAGE_HANDLER_65 rem "Message handler: message type 65"
16599 return

MESSAGE_HANDLER_66 rem "Message handler: message type 66"
16699 return

MESSAGE_HANDLER_67 rem "Message handler: message type 67"
16799 return

MESSAGE_HANDLER_68 rem "Message handler: message type 68"
16899 return

MESSAGE_HANDLER_69 rem "Message handler: message type 69"
16999 return

MESSAGE_HANDLER_70 rem "Message handler: message type 70"
17099 return

MESSAGE_HANDLER_71 rem "Message handler: message type 71"
17199 return

MESSAGE_HANDLER_72 rem "Message handler: message type 72"
17299 return

MESSAGE_HANDLER_73 rem "Message handler: message type 73"
17399 return

MESSAGE_HANDLER_74 rem "Message handler: message type 74"
17499 return

MESSAGE_HANDLER_75 rem "Message handler: message type 75"
17599 return

MESSAGE_HANDLER_76 rem "Message handler: message type 76"
17699 return

MESSAGE_HANDLER_77 rem "Message handler: message type 77"
17799 return

MESSAGE_HANDLER_78 rem "Message handler: message type 78"
17899 return

MESSAGE_HANDLER_79 rem "Message handler: message type 79"
17999 return

MESSAGE_HANDLER_80 rem "Message handler: message type 80"
18099 return

MESSAGE_HANDLER_81 rem "Message handler: message type 81"
18199 return

MESSAGE_HANDLER_82 rem "Message handler: message type 82"
18299 return

MESSAGE_HANDLER_83 rem "Message handler: message type 83"
18399 return

MESSAGE_HANDLER_84 rem "Message handler: message type 84"
18499 return

MESSAGE_HANDLER_85 rem "Message handler: message type 85"
18599 return

MESSAGE_HANDLER_86 rem "Message handler: message type 86"
18699 return

MESSAGE_HANDLER_87 rem "Message handler: message type 87"
18799 return

MESSAGE_HANDLER_88 rem "Message handler: message type 88"
18899 return

MESSAGE_HANDLER_89 rem "Message handler: message type 89"
18999 return

MESSAGE_HANDLER_90 rem "Message handler: message type 90"
19099 return

MESSAGE_HANDLER_91 rem "Message handler: message type 91"
19199 return

MESSAGE_HANDLER_92 rem "Message handler: message type 92"
19299 return

MESSAGE_HANDLER_93 rem "Message handler: message type 93"
19399 return

MESSAGE_HANDLER_94 rem "Message handler: message type 94"
19499 return

MESSAGE_HANDLER_95 rem "Message handler: message type 95"
19599 return

MESSAGE_HANDLER_96 rem "Message handler: message type 96"
19699 return

MESSAGE_HANDLER_97 rem "Message handler: message type 97"
19799 return

MESSAGE_HANDLER_98 rem "Message handler: message type 98"
19899 return

MESSAGE_HANDLER_99 rem "Message handler: message type 99"
19999 return

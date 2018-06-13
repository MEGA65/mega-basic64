'### MESSAGE HANDLERS ###
'we actually have to force the line numbers for the jump-table mechanism to work
'we could keep line numbers instead of labels, if we don't use those labels at all (outside of the jump-table)

9999 rem

'Message handler: unknown/free-form
MESSAGE_HANDLER_0 rem
10099 return

'Message handler: message type 1
MESSAGE_HANDLER_1 rem
10199 return

'Message handler: message type 2
MESSAGE_HANDLER_2 rem
10299 return

'Message handler: message type 3
MESSAGE_HANDLER_3 rem
10399 return

'Message handler: message type 4
MESSAGE_HANDLER_4 rem
10499 return

'Message handler: message type 5
MESSAGE_HANDLER_5 rem
10599 return

'Message handler: message type 6
MESSAGE_HANDLER_6 rem
10699 return

'Message handler: message type 7
MESSAGE_HANDLER_7 rem
10799 return

'Message handler: message type 8
MESSAGE_HANDLER_8 rem
10899 return

'Message handler: message type 9
MESSAGE_HANDLER_9 rem
10999 return

'Message handler: message type 10
MESSAGE_HANDLER_10 rem
11099 return

'Message handler: message type 11
MESSAGE_HANDLER_11 rem
11199 return

'Message handler: message type 12
MESSAGE_HANDLER_12 rem
11299 return

'Message handler: message type 13
MESSAGE_HANDLER_13 rem
11399 return

'Message handler: message type 14
MESSAGE_HANDLER_14 rem
11499 return

'Message handler: message type 15
MESSAGE_HANDLER_15 rem
11599 return

'Message handler: message type 16
MESSAGE_HANDLER_16 rem
11699 return

'Message handler: message type 17
MESSAGE_HANDLER_17 rem
11799 return

'Message handler: message type 18
MESSAGE_HANDLER_18 rem
11899 return

'Message handler: message type 19
MESSAGE_HANDLER_19 rem
11999 return

'Message handler: message type 20
MESSAGE_HANDLER_20 rem
12099 return

'Message handler: message type 21
MESSAGE_HANDLER_21 rem
12199 return

'Message handler: message type 22
MESSAGE_HANDLER_22 rem
12299 return

'Message handler: message type 23
MESSAGE_HANDLER_23 rem
12399 return

'Message handler: message type 24
MESSAGE_HANDLER_24 rem
12499 return

'Message handler: message type 25
MESSAGE_HANDLER_25 rem
12599 return

'Message handler: message type 26
MESSAGE_HANDLER_26 rem
12699 return

'Message handler: message type 27
MESSAGE_HANDLER_27 rem
12799 return

'Message handler: message type 28
MESSAGE_HANDLER_28 rem
12899 return

'Message handler: message type 29
MESSAGE_HANDLER_29 rem
12999 return

'Message handler: message type 30
MESSAGE_HANDLER_30 rem
13099 return

'Message handler: message type 31
MESSAGE_HANDLER_31 rem
13199 return

'Message handler: message type 32
MESSAGE_HANDLER_32 rem
13299 return

'Message handler: message type 33
MESSAGE_HANDLER_33 rem
13399 return

'Message handler: message type 34
MESSAGE_HANDLER_34 rem
13499 return

'Message handler: message type 35
MESSAGE_HANDLER_35 rem
13599 return

'Message handler: message type 36
MESSAGE_HANDLER_36 rem
13699 return

'Message handler: message type 37
MESSAGE_HANDLER_37 rem
13799 return

'Message handler: message type 38
MESSAGE_HANDLER_38 rem
13899 return

'Message handler: message type 39
MESSAGE_HANDLER_39 rem
13999 return

'Message handler: OK
MESSAGE_HANDLER_OK rem
if dia=1 then gosub SEND_AT+CLCC 'ATD succeeded, dialling...
14099 return

'Message handler: message type 41
MESSAGE_HANDLER_41 rem
14199 return

'Message handler: incoming call (ring)
MESSAGE_HANDLER_RING rem
gosub SEND_AT+CLCC
if dactive=0 then dactive=1: su=1: gosub SWITCH_TO_SCREEN_CALL
'else: already in-call
14299 return

'Message handler: no carrier
MESSAGE_HANDLER_NO_CARRIER rem
'TODO: depending on which screen we are, we can set different messages to be displayed to the user when the call is hung up
if dactive=1 then goto MH_NC_ACTIVE
'else: not in call
goto MH_NC_END

'active call
MH_NC_ACTIVE rem
'hang-up the active call
gosub CALL_HANGUP
su=1
gosub SWITCH_TO_SCREEN_DIALLER
goto MH_NC_END

MH_NC_END rem
14399 return


MESSAGE_HANDLER_ERROR rem
'Message handler: ERROR
'This message is received if an AT command failed'
'merror=1
14499 return

'Message handler: message type 45
MESSAGE_HANDLER_45 rem
14599 return

'Message handler: no dial tone
MESSAGE_HANDLER_NO_DIAL_TONE rem
if dia=1 then dr$="no dial tone": su=1
14699 return

'Message handler: busy
MESSAGE_HANDLER_BUSY rem
if dia=1 then dr$="target is busy": su=1
14799 return

'Message handler: no answer
MESSAGE_HANDLER_NO_ANSWER rem
14899 return


'Message handler: +CME ERROR
MESSAGE_HANDLER_+CME_ERROR rem
'This message is received after sending an AT command, if there is any error related to ME functionality'
'merror=1
'merror$=mf$(1)
14999 return

'Message handler: +CMS ERROR
MESSAGE_HANDLER_+CMS_ERROR rem
'This message is received after sending an AT command, if there is any error related to MS functionality'
'merror=1
'merror$=mf$(1)
15099 return


'Message handler: +clcc (list current calls)
MESSAGE_HANDLER_+CLCC rem
'update state and caller id only if voice call, and call active
if mf$(4)="0" and dactive=1 then goto MH_CLCC_VOICE
return

MH_CLCC_VOICE rem
'--- voice call ---
'set caller id (cid$)
su=1
cid$=right$(left$(mf$(6),len(mf$(6))-1),len(mf$(6))-2)
'update call state (dsta)
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
'--- dialling ---
if dsta=2 then dr$="dialling..."
if dsta=3 then dr$="alerting..."
'0: the call has been established
if dsta=0 then dr$="": dia=0: cid$=dnumber$: tc=time
goto MH_CLCC_END

MH_CLCC_END rem
'send again the at+clcc command
gosub SEND_AT+CLCC
15199 return


'Message handler: +csq (signal quality report)
MESSAGE_HANDLER_+CSQ rem
su=1
rssi=val(mf$(1)): ber=val(mf$(2))
if rssi=99 or rssi=199 then sl%=0
if rssi>=0 and rssi<=31 then sl%=int((rssi/32*5)+1)
if rssi>=100 and rssi<=191 then sl%=int(((rssi-100)/92*5)+1)
if ber>=0 and ber<=7 then ber$=str$(ber)
if ber=99 then ber$="?"
15299 return


'Message handler: +qnwinfo (network information report)
MESSAGE_HANDLER_+QNWINFO rem
su=1
'get nwact, without quotes
nact$=right$(left$(mf$(1),len(mf$(1))-1),len(mf$(1))-2)
'initialize to unknown, in case nwact is not in the following list (should not happen)
nt$="?"
if nact$="none" then nt$="x" '3g? abbreviation to check
if nact$="cdma1x" then nt$="3g" '3g? abbreviation to check
if nact$="cdma1x and hdr" then nt$="3g" '3g? abbreviation to check
if nact$="cdma1x and ehrpd" then nt$="3g" '2g? abbreviation to check
if nact$="hdr" then nt$="2g" '3g? abbreviation to check
if nact$="hdr-ehrpd" then nt$="3g"
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
15399 return


'Message handler: +QSPN (registered network name report)
MESSAGE_HANDLER_+QSPN rem
su=1
'get SNN, without quotes
nname$=right$(left$(mf$(2),len(mf$(2))-1),len(mf$(2))-2)
'mf$(1) is FNN (Full Network Name), mf$(2) is SNN (Short Network Name)
15499 return


'Message handler: +CPBS (phonebook memory storage)
MESSAGE_HANDLER_+CPBS rem
'This can either be:
' - a list of supported storages in response to AT+CPBS=?: +CPBS: ("sm","dc","mc","me","rc","en")
' - a report on the current storage in response to AT+CPBS?: +CPBS: <storage>,<used>,<total>
' For now, we only handle the second case
pused%=val(mf$(2))
ptotal%=val(mf$(3))
15599 return

'Message handler: +CPBR (read phonebook entries)
MESSAGE_HANDLER_+CPBR rem
'Phonebook entry: +CPBR: <index>,<number>,<type>,<text>
' Example: +CPBR: 1,"000",129,"emergency"
pindex%=pindex%+1
i=pindex%
pindex%(i)=1 'entry i is now used
psim%(i)=val(mf$(1)) 'SIM index of the entry
s$=mf$(2): gosub REMOVE_QUOTES_STRING: pnumber$(i)=s$ 'phone number
ptype%(i)=val(mf$(3)) 'type of phone number
s$=mf$(4): gosub REMOVE_QUOTES_STRING: ptxt$(i)=s$ 'contact name
15699 return

'Message handler: message type 57
MESSAGE_HANDLER_57 rem
15799 return

'Message handler: message type 58
MESSAGE_HANDLER_58 rem
15899 return

'Message handler: message type 59
MESSAGE_HANDLER_59 rem
15999 return

'Message handler: message type 60
MESSAGE_HANDLER_60 rem
16099 return

'Message handler: message type 61
MESSAGE_HANDLER_61 rem
16199 return

'Message handler: message type 62
MESSAGE_HANDLER_62 rem
16299 return

'Message handler: message type 63
MESSAGE_HANDLER_63 rem
16399 return

'Message handler: message type 64
MESSAGE_HANDLER_64 rem
16499 return

'Message handler: message type 65
MESSAGE_HANDLER_65 rem
16599 return

'Message handler: message type 66
MESSAGE_HANDLER_66 rem
16699 return

'Message handler: message type 67
MESSAGE_HANDLER_67 rem
16799 return

'Message handler: message type 68
MESSAGE_HANDLER_68 rem
16899 return

'Message handler: message type 69
MESSAGE_HANDLER_69 rem
16999 return

'Message handler: message type 70
MESSAGE_HANDLER_70 rem
17099 return

'Message handler: message type 71
MESSAGE_HANDLER_71 rem
17199 return

'Message handler: message type 72
MESSAGE_HANDLER_72 rem
17299 return

'Message handler: message type 73
MESSAGE_HANDLER_73 rem
17399 return

'Message handler: message type 74
MESSAGE_HANDLER_74 rem
17499 return

'Message handler: message type 75
MESSAGE_HANDLER_75 rem
17599 return

'Message handler: message type 76
MESSAGE_HANDLER_76 rem
17699 return

'Message handler: message type 77
MESSAGE_HANDLER_77 rem
17799 return

'Message handler: message type 78
MESSAGE_HANDLER_78 rem
17899 return

'Message handler: message type 79
MESSAGE_HANDLER_79 rem
17999 return

'Message handler: message type 80
MESSAGE_HANDLER_80 rem
18099 return

'Message handler: message type 81
MESSAGE_HANDLER_81 rem
18199 return

'Message handler: message type 82
MESSAGE_HANDLER_82 rem
18299 return

'Message handler: message type 83
MESSAGE_HANDLER_83 rem
18399 return

'Message handler: message type 84
MESSAGE_HANDLER_84 rem
18499 return

'Message handler: message type 85
MESSAGE_HANDLER_85 rem
18599 return

'Message handler: message type 86
MESSAGE_HANDLER_86 rem
18699 return

'Message handler: message type 87
MESSAGE_HANDLER_87 rem
18799 return

'Message handler: message type 88
MESSAGE_HANDLER_88 rem
18899 return

'Message handler: message type 89
MESSAGE_HANDLER_89 rem
18999 return

'Message handler: message type 90
MESSAGE_HANDLER_90 rem
19099 return

'Message handler: message type 91
MESSAGE_HANDLER_91 rem
19199 return

'Message handler: message type 92
MESSAGE_HANDLER_92 rem
19299 return

'Message handler: message type 93
MESSAGE_HANDLER_93 rem
19399 return

'Message handler: message type 94
MESSAGE_HANDLER_94 rem
19499 return

'Message handler: message type 95
MESSAGE_HANDLER_95 rem
19599 return

'Message handler: message type 96
MESSAGE_HANDLER_96 rem
19699 return

'Message handler: message type 97
MESSAGE_HANDLER_97 rem
19799 return

'Message handler: message type 98
MESSAGE_HANDLER_98 rem
19899 return

'Message handler: message type 99
MESSAGE_HANDLER_99 rem
19999 return

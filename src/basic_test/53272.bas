01 rem "Test of graphics/text mode (aka upper/lower case)"
09 print peek(53272)
10 poke 53272,23
20 print peek(53272): rem "22"
30 poke 53272,21
40 print peek(53272): rem "20"

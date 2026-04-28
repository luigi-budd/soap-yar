SafeFreeslot("SPR2_NADO")

SafeFreeslot("S_PLAY_TAKIS_TORNADO")
states[S_PLAY_TAKIS_TORNADO] = {
    sprite = SPR_PLAY,
    frame = SPR2_NADO,
    tics = -1,
}

SafeFreeslot("S_PLAY_TAKIS_HSTART")
states[S_PLAY_TAKIS_HSTART] = {
    sprite = SPR_PLAY,
    frame = SPR2_SPIN|FF_ANIMATE,
    tics = 8,
	var1 = 8,
	var2 = 1,
	nextstate = S_PLAY_MELEE
}
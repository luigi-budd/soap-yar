SafeFreeslot("S_TAKIS_CDUST1")
states[S_TAKIS_CDUST1] = {
	sprite = SPR_SOAP_GFX,
	frame = 4|FF_PAPERSPRITE|FF_ANIMATE,
	var1 = 8,
	var2 = 2,
	tics = 8*2,
	action = function(mo)
		P_SetScale(mo, mo.scale * 3/2, true)
	end
}

SafeFreeslot("S_TAKIS_CDUST2")
states[S_TAKIS_CDUST2] = {
	sprite = SPR_SOAP_GFX,
	frame = 12|FF_PAPERSPRITE|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 6,
	var2 = 2,
	tics = 6*2,
}

SafeFreeslot("S_TAKIS_SLINGFX")
states[S_TAKIS_SLINGFX] = {
	sprite = SPR_SOAP_GFX,
	frame = 18|FF_PAPERSPRITE|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 6,
	var2 = 1,
	tics = 7,
}

SafeFreeslot("S_TAKIS_BONKFX1")
SafeFreeslot("S_TAKIS_BONKFX2") -- bruh
states[S_TAKIS_BONKFX1] = {
	sprite = SPR_SOAP_GFX,
	frame = 38|FF_FULLBRIGHT,
	tics = 3,
	nextstate = S_TAKIS_BONKFX2
}
states[S_TAKIS_BONKFX2] = {
	sprite = SPR_SOAP_GFX,
	frame = 39|FF_FULLBRIGHT,
	tics = 3 * TR,
}

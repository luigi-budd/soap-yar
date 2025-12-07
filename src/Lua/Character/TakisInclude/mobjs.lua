SafeFreeslot("S_TAKIS_CDUST1")
states[S_TAKIS_CDUST1] = {
	sprite = SPR_SOAP_GFX,
	frame = 32|FF_PAPERSPRITE|FF_ANIMATE,
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
	frame = 40|FF_PAPERSPRITE|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 6,
	var2 = 2,
	tics = 6*2,
}

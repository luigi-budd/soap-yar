SafeFreeslot("sfx_tk_djm")
sfxinfo[sfx_tk_djm].caption = "Double jump"

for i = 0, 4
	sfxinfo[SafeFreeslot("sfx_tk_cl"..i)] = {
		caption = (i == 4) and "Misfire" or "Clutch Boost",
		flags = (i == 1) and SF_X2AWAYSOUND|SF_TOTALLYSINGLE or 0
	}
end

SafeFreeslot("sfx_tk_fst")
sfxinfo[sfx_tk_fst].caption = "/"

SafeFreeslot("sfx_tk_div")
sfxinfo[sfx_tk_div].caption = "Dive"

SafeFreeslot("sfx_tk_ahm")
sfxinfo[sfx_tk_ahm].caption = "Swing"
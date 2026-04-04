SafeFreeslot("sfx_flex")
SafeFreeslot("sfx_hahaha")
sfxinfo[sfx_flex].caption = "\x82".."Flex!!\x80"
sfxinfo[sfx_hahaha].caption = "Strange laughing"

SafeFreeslot("sfx_sp_dss")
sfxinfo[sfx_sp_dss].caption = "Dashing"
SafeFreeslot("sfx_sp_upr")
sfxinfo[sfx_sp_upr].caption = "Uppercut"
SafeFreeslot("sfx_sp_mac")
sfxinfo[sfx_sp_mac].caption = "R-Dashing"
--cowbells
SafeFreeslot("sfx_sp_mc2")
sfxinfo[sfx_sp_mc2].caption = "R-Dashing"
SafeFreeslot("sfx_sp_max")
sfxinfo[sfx_sp_max].caption = "Max speed!"
SafeFreeslot("sfx_sp_bom")
sfxinfo[sfx_sp_bom].caption = "Woomp"
SafeFreeslot("sfx_sp_dmg")
sfxinfo[sfx_sp_dmg].caption = "/"
SafeFreeslot("sfx_sp_top")
sfxinfo[sfx_sp_top].caption = "Ricochet"
SafeFreeslot("sfx_sp_tch")
sfxinfo[sfx_sp_tch].caption = "\x82SPINNING TOP\x80"
SafeFreeslot("sfx_sp_jm2")
sfxinfo[sfx_sp_jm2].caption = "/"

SafeFreeslot("sfx_sp_ow0")
sfxinfo[sfx_sp_ow0] = {
	flags = SF_X4AWAYSOUND,
	caption = "\x85".."EUROOOOWWWW!!!\x80"
}
SafeFreeslot("sfx_sp_ow1")
sfxinfo[sfx_sp_ow1] = {
	flags = SF_X4AWAYSOUND,
	caption = "\x85".."Ough!\x80"
}
SafeFreeslot("sfx_sp_ow2")
sfxinfo[sfx_sp_ow2] = {
	flags = SF_X4AWAYSOUND|SF_X2AWAYSOUND,
	caption = "\x85".."Auughhhh!\x80"
}

SafeFreeslot("sfx_sp_grb")
sfxinfo[sfx_sp_grb].caption = "Grab"
SafeFreeslot("sfx_sp_pry")
sfxinfo[sfx_sp_pry].caption = "Parry"
SafeFreeslot("sfx_sp_cln")
sfxinfo[sfx_sp_cln].caption = "Slide lunge"

for i = 0, 7
	SafeFreeslot("sfx_sp_dm"..i)
	sfxinfo[sfx_sp_dm0 + i] = {
		caption = "Damage",
		flags = SF_X2AWAYSOUND
	}
end
sfxinfo[sfx_sp_dm4] = {
	caption = "\x85Spike!\x80",
	flags = SF_X2AWAYSOUND
}

-- spike damage
for i = 0, 2
	SafeFreeslot("sfx_sp_ds"..i)
	sfxinfo[sfx_sp_ds0 + i] = {
		caption = "Damage",
		flags = SF_X2AWAYSOUND
	}
end
-- electric damage
for i = 0, 2
	SafeFreeslot("sfx_sp_de"..i)
	sfxinfo[sfx_sp_de0 + i] = {
		caption = "Damage",
		flags = SF_X2AWAYSOUND
	}
end
-- fire damage
for i = 0, 3
	SafeFreeslot("sfx_sp_df"..i)
	sfxinfo[sfx_sp_df0 + i] = {
		caption = "Damage",
		flags = SF_X2AWAYSOUND
	}
end
-- knockback
for i = 0, 2
	SafeFreeslot("sfx_sp_kb"..i)
	sfxinfo[sfx_sp_kb0 + i] = {
		caption = "/",
		flags = SF_X2AWAYSOUND
	}
end

for i = 0, 2
	SafeFreeslot("sfx_sp_st"..i)
	sfxinfo[sfx_sp_st0 + i] = {
		caption = "Step",
	}
end

SafeFreeslot("sfx_sp_smk")
sfxinfo[sfx_sp_smk].caption = "Smack"
SafeFreeslot("sfx_sp_kil")
sfxinfo[sfx_sp_kil].caption = "/"
SafeFreeslot("sfx_sp_spt")
sfxinfo[sfx_sp_spt].caption = "Splat!"
SafeFreeslot("sfx_sp_kco")
sfxinfo[sfx_sp_kco] = {
	flags = SF_X2AWAYSOUND,
	caption = "Knockout!!"
}

-- lol
SafeFreeslot("sfx_sp_em2")
sfxinfo[sfx_sp_em2] = {
	flags = SF_X2AWAYSOUND,
	caption = "\x89Six seven!!\x80"
}
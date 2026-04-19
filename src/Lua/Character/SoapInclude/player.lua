SafeFreeslot("SPR2_APOS")
SafeFreeslot("SPR2_FLEX")
SafeFreeslot("SPR2_BRDA")
SafeFreeslot("SPR2_OOF_")
SafeFreeslot("SPR2_SLID")
SafeFreeslot("SPR2_JSKI") -- :ajlooking:
SafeFreeslot("SPR2_NFL2") -- ugh also

spr2defaults[SPR2_APOS] = SPR2_STND
spr2defaults[SPR2_FLEX] = SPR2_STND
spr2defaults[SPR2_BRDA] = SPR2_ROLL
spr2defaults[SPR2_OOF_] = SPR2_PAIN
spr2defaults[SPR2_SLID] = SPR2_ROLL


SafeFreeslot("S_PLAY_SOAP_FLEX")
states[S_PLAY_SOAP_FLEX] = {
    sprite = SPR_PLAY,
    frame = SPR2_FLEX|FF_RANDOMANIM,
    tics = TR,
    nextstate = S_PLAY_STND
}

SafeFreeslot("S_PLAY_SOAP_LAUGH")
states[S_PLAY_SOAP_LAUGH] = {
	sprite = SPR_PLAY,
	frame = SPR2_APOS,
	var2 = 2,
	tics = TR,
	nextstate = S_PLAY_STND
}

SafeFreeslot("S_PLAY_SOAP_BREAKDANCE")
states[S_PLAY_SOAP_BREAKDANCE] = {
	sprite = SPR_PLAY,
	frame = SPR2_BRDA,
	tics = -1,
	nextstate = S_PLAY_SOAP_BREAKDANCE
}

SafeFreeslot("S_PLAY_SOAP_SPTOP")
states[S_PLAY_SOAP_SPTOP] = {
	sprite = SPR_PLAY,
	frame = A|SPR2_MSC1,
	tics = 1,
	nextstate = S_PLAY_SOAP_SPTOP
}

SafeFreeslot("S_PLAY_SOAP_KNOCKOUT")
states[S_PLAY_SOAP_KNOCKOUT] = {
	sprite = SPR_PLAY,
	frame = A|SPR2_OOF_,
	tics = -1,
}

SafeFreeslot("S_PLAY_SOAP_SLIP")
states[S_PLAY_SOAP_SLIP] = {
	sprite = SPR_PLAY,
	frame = A|SPR2_SLID,
	tics = 8,
	action = function(me)
		local p = me.player
		if not (p and p.valid) then return end
		local soap = p.soaptable
		if not soap then return end
		
		local speed = soap.accspeed
		if speed >= 25*FU
			me.tics = 1
		elseif speed >= 20*FU
			me.tics = 2
		elseif speed >= 15*FU
			me.tics = 4
		elseif speed >= 10*FU
			me.tics = 6
		end
	end,
	nextstate = S_PLAY_SOAP_SLIP,
}

SafeFreeslot("S_PLAY_SOAP_RAM")
states[S_PLAY_SOAP_RAM] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC5,
	tics = 8,
	nextstate = S_PLAY_DASH
}

SafeFreeslot("S_PLAY_SOAP_PUNCH1")
SafeFreeslot("S_PLAY_SOAP_PUNCH2")
SafeFreeslot("S_PLAY_SOAP_PUNCH3")
SafeFreeslot("S_PLAY_SOAP_PREPUNCH")
states[S_PLAY_SOAP_PREPUNCH] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC9|A,
	tics = -1,
	nextstate = S_PLAY_STND,
}
states[S_PLAY_SOAP_PUNCH1] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC6|A,
	tics = 2,
	nextstate = S_PLAY_SOAP_PUNCH2,
	action = function(mo)
		mo.mirrored = P_RandomChance(FU/2)
	end,
}
states[S_PLAY_SOAP_PUNCH2] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC6|B,
	tics = 12,
	nextstate = S_PLAY_SOAP_PUNCH3
}
states[S_PLAY_SOAP_PUNCH3] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC6|B,
	tics = 0,
	nextstate = S_PLAY_FALL,
	action = function(me)
		if P_IsObjectOnGround(me)
			me.state = S_PLAY_WALK
			Soap_ResetState(me.player)
			return
		end
		me.state = S_PLAY_FALL
	end
}

SafeFreeslot("S_PLAY_SOAP_FIREASS")
states[S_PLAY_SOAP_FIREASS] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC7|FF_ANIMATE,
	tics = 4,
	nextstate = S_PLAY_SOAP_FIREASS
}

SafeFreeslot("S_PLAY_SOAP_SIXSEV")
states[S_PLAY_SOAP_SIXSEV] = {
	sprite = SPR_PLAY,
	frame = SPR2_MSC8|FF_ANIMATE,
	tics = -1,
	nextstate = S_PLAY_SOAP_SIXSEV,
}

-- super color from supercolorsrevamp
SafeFreeslot("SKINCOLOR_SUPER_TOXIN1")
SafeFreeslot("SKINCOLOR_SUPER_TOXIN2")
SafeFreeslot("SKINCOLOR_SUPER_TOXIN3")
SafeFreeslot("SKINCOLOR_SUPER_TOXIN4")
SafeFreeslot("SKINCOLOR_SUPER_TOXIN5")

skincolors[SKINCOLOR_SUPER_TOXIN1] = {
    name = "Super Toxin 1",
    ramp = {80,88,96,97,112,113,113,114,115,116,116,117,118,119,111,31},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_GREENMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_TOXIN2] = {
    name = "Super Toxin 2",
    ramp = {80,89,98,99,100,100,114,115,115,116,117,117,118,119,111,31},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_GREENMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_TOXIN3] = {
    name = "Super Toxin 3",
    ramp = {80,89,90,91,101,103,104,105,107,107,108,109,119,110,111,31},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_GREENMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_TOXIN4] = {
    name = "Super Toxin 4",
    ramp = {0,89,90,91,92,93,94,94,94,95,95,109,109,110,111,31},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_GREENMAP,
    accessible = false
}
skincolors[SKINCOLOR_SUPER_TOXIN5] = {
    name = "Super Toxin 5",
    ramp = {0,5,11,16,22,23,24,25,26,26,27,28,29,29,30,31},
    invcolor = SKINCOLOR_ORANGE,
    invshade = 9,
    chatcolor = V_GREENMAP,
    accessible = false
}

SafeFreeslot("SPR2_APOS")
SafeFreeslot("SPR2_FLEX")
SafeFreeslot("SPR2_BRDA")
SafeFreeslot("SPR2_OOF_")
SafeFreeslot("SPR2_SLID")

spr2defaults[SPR2_APOS] = SPR2_STND
spr2defaults[SPR2_FLEX] = SPR2_STND
spr2defaults[SPR2_BRDA] = SPR2_ROLL
spr2defaults[SPR2_OOF_] = SPR2_DEAD
spr2defaults[SPR2_SLID] = SPR2_ROLL


SafeFreeslot("S_PLAY_SOAP_FLEX")
states[S_PLAY_SOAP_FLEX] = {
    sprite = SPR_PLAY,
    frame = SPR2_FLEX,
    var2 = 2,
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
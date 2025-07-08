local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SPINDUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end

Takis_Hook.addHook("Takis_Thinker",function(p)
	local me = p.mo
	local soap = p.soaptable
	
	local squishme = true
	
	if (p.skidtime)
	and (me.state == S_PLAY_SKID)
		--nothing to do here yet
	else
		S_StopSoundByID(me,skins["takisthefox"].soundsid[SKSSKID])
	end
	
	if (me.state == S_PLAY_WAIT)
	and (me.sprite2 == SPR2_WAIT)
		if (soap.last.anim.state == S_PLAY_STND)
			soap.waitframe = P_RandomRange(A, skins[p.skin].sprites[SPR2_WAIT].numframes - 1)
		end
		soap.waittics = $+1
		me.frame = soap.waitframe
		me.tics = -1
		me.anim_duration = 0
		
		if soap.waittics >= TR + P_RandomRange(0,TR)
			me.state = S_PLAY_STND
			me.tics = $ + P_RandomRange(TR,8*TR)
		end
	else
		soap.waittics = 0
	end
	
	p.charability2 = soap.inBattle and CA2_GUNSLINGER or CA2_NONE
	p.revitem = soap.inBattle and MT_CORK or MT_NULL
	
	Takis_VFX(p,me,soap, {
		squishme = squishme,
	})
end)

--jump effect
addHook("JumpSpecial", function(p)
	if p.mo.skin ~= "takisthefox" then return end
	
	local me = p.mo
	local soap = p.soaptable
	
	if not soap then return end
	
	if soap.jump > 1 then return end
	if (p.pflags & PF_THOKKED) then return end
	if (soap.jumptime > 0) then return end
	if p.inkart then return end
	if (p.pflags & PF_JUMPSTASIS) then return end
	if (p.pflags & (PF_JUMPED|PF_STARTJUMP) == PF_JUMPED) then return end
	
	if soap.onGround
	or me.soap_jumpeffect
		
		Soap_DustRing(me,
			dust_type(me), 8,
			{me.x,me.y,me.z},
			me.radius / 2,
			8*me.scale,
			me.scale * 3/2,
			me.scale / 2,
			false,
			dust_noviewmobj
		)
		
		local ease_time = 8
		local ease_func = "outsine"
		Soap_AddSquash(p, {
			ease_func = ease_func,
			start_v = -FU*7/10,
			end_v = 0,
			time = ease_time
		}, {
			ease_func = ease_func,
			start_v = FU/2,
			end_v = 0,
			time = ease_time
		})
		Soap_RemoveSquash(p, "landeffect")
		me.soap_jumpdust = 4
		me.soap_jumpeffect = nil
	end
end)

--double jump
addHook("AbilitySpecial", function(p)
	if p.mo.skin ~= "takisthefox" then return end
	
	local soap = p.soaptable
	
	if p.charability ~= CA_DOUBLEJUMP then return end
	
	if (p.pflags & PF_JUMPSTASIS)
		return true
	end
	if soap.inPain
		return true
	end
	
	local me = p.mo
	
	P_DoJump(p,false)
	S_StopSoundByID(me,skins["takisthefox"].soundsid[SKSJUMP])
	
	local jfactor = min(FixedDiv(p.jumpfactor,skins["takisthefox"].jumpfactor),FU)
	Soap_ZLaunch(p.mo,FixedMul(15*FU,jfactor))
	
	me.state = S_PLAY_ROLL
	local maxi = P_RandomRange(8,16)
	for i = 0, maxi
		local fa = FixedAngle(i*FixedDiv(360*FU,maxi*FU))
		Soap_DustRing(me,
			dust_type(me), 8,
			{me.x,me.y,me.z},
			me.radius / 2,
			16*me.scale,
			me.scale * 3/2,
			me.scale / 2,
			false,
			dust_noviewmobj
		)
	end

	--wind ring
	S_StartSoundAtVolume(me,sfx_tk_djm,4*255/5)
	if soap.inWater
		S_StartSound(me,sfx_splash)
	end
	
	p.jp = 1
	p.jt = 5
	p.pflags = $|(PF_JUMPED|PF_JUMPDOWN|PF_THOKKED|PF_STARTJUMP) & ~(PF_SPINNING|PF_STARTDASH)
	return true
end)
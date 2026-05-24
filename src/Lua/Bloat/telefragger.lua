local CV = SOAP_CV
SafeFreeslot("SPR_NSTELEFRAGGER")
SafeFreeslot("S_NSTFRAG_WALK")
states[S_NSTFRAG_WALK] = {
	sprite = SPR_NSTELEFRAGGER,
	frame = 0|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 1,
	var2 = (TR * 64/100),
	tics = (TR * 64/100)*2,
	nextstate = S_NSTFRAG_WALK
}
sfxinfo[SafeFreeslot("sfx_ntf_0")].caption = "/"
sfxinfo[SafeFreeslot("sfx_ntf_1")].caption = "/"

SafeFreeslot("MT_NSTELEFRAGGER")
mobjinfo[MT_NSTELEFRAGGER] = {
	doomednum = -1,
	spawnstate = S_NSTFRAG_WALK,
	deathstate = S_NSTFRAG_WALK,
	height = 80*FU,
	radius = 40*FU,
	spawnhealth = 1,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SPECIAL,
}

local function TFrag_SearchForPlayers(baby)
	local availplayers = {}
	local player = nil
	
	baby.target = nil
	for p in players.iterate
		if p.spectator then continue end
		local me = p.mo
		if not (me and me.valid and me.health) then continue end
		
		table.insert(availplayers, p)
	end
	if not (#availplayers) then return end
	
	baby.target = availplayers[P_RandomRange(1, #availplayers)].mo
	return true
end

local function settimer(mo)
	mo.extravalue1 = P_RandomRange(4*TR, 9*TR)
	if not mo.extravalue2
		mo.extravalue2 = P_RandomRange(2, 6)
	end
end
addHook("MobjThinker",function(mo)
	if not (mo and mo.valid) then return end
	if not S_SoundPlaying(mo, sfx_ntf_1)
		S_StartSound(mo, sfx_ntf_1)
	end
	if not (mo.backingvfx and mo.backingvfx.valid)
		local vfx = P_SpawnMobjFromMobj(mo, 0,0, FixedDiv(mo.height,mo.scale)/2, MT_PARTICLE)
		vfx.sprite = SPR_NSTELEFRAGGER
		vfx.frame = 3|FF_FULLBRIGHT
		vfx.tics = -1
		vfx.fuse = vfx.tics
		vfx.blendmode = AST_REVERSESUBTRACT
		vfx.dispoffset = -300
		mo.dispoffset = 100
		mo.renderflags = $|RF_NOCOLORMAPS
		mo.backingvfx = vfx
	else
		P_MoveOrigin(mo.backingvfx,
			mo.x + mo.momx,
			mo.y + mo.momy,
			mo.z + mo.momz + mo.height/2
		)
		mo.backingvfx.alpha = P_RandomRange(FU/3,FU)
	end
	
	if (leveltime % 3 == 0)
		local vfx = P_SpawnMobjFromMobj(mo, 0,0, FixedDiv(mo.height,mo.scale)/2, MT_THOK)
		vfx.sprite = SPR_NSTELEFRAGGER
		vfx.frame = 2|(P_RandomChance(FU/2) and FF_FULLBRIGHT or FF_FULLDARK)
		vfx.tics = 11
		vfx.fuse = vfx.tics
		vfx.scale = vfx.scale
		vfx.destscale = mo.scale * 6/5 --vfx.scale * 9/6
		vfx.scalespeed = FixedDiv(vfx.destscale - vfx.scale, vfx.fuse*FU)
		vfx.translation = "AllWhite"
		vfx.blendmode = AST_SUBTRACT
		vfx.dispoffset = -300
		P_SetObjectMomZ(vfx, FU / 2)
		vfx.momx = mo.momx
		vfx.momy = mo.momy
		vfx.momz = $ + mo.momz
	end

	local me = mo.target
	if not (me and me.valid)
		if not TFrag_SearchForPlayers(mo)
			return
		end
		if not (mo.extravalue1)
			settimer(mo)
		end
		me = mo.target
	end
	if not (me.health)
		mo.target = nil
		return
	end
	
	local ha,va = R_PointTo3DAngles(
		mo.x,mo.y, mo.z + mo.height/2,
		me.x,me.y, me.z + me.height/2
	)
	P_3DInstaThrust(mo, ha,va, 4*mo.scale)
	
	if (mo.extravalue1)
		if mo.extravalue1 == TR + 1
			if not mo.extravalue2
				local prevtarg = mo.target
				if not TFrag_SearchForPlayers(mo)
					mo.target = prevtarg
				end
			end
			
			S_StartSound(me, sfx_ntf_0)
		elseif mo.extravalue1 == 1
			local dist = 400 * me.scale
			P_SetOrigin(mo,
				me.x + P_ReturnThrustX(me.player.drawangle, dist),
				me.y + P_ReturnThrustY(me.player.drawangle, dist),
				me.z
			)
			mo.state = S_NSTFRAG_WALK
			
			local top_layer = P_SpawnMobjFromMobj(mo, 0,0,0, MT_PARTICLE)
			top_layer.state = S_SOAP_HITM_RSPRK
			top_layer.spritexscale = $ * 6
			top_layer.spriteyscale = top_layer.spritexscale
			top_layer.renderflags = $|RF_ALWAYSONTOP|RF_FULLBRIGHT|RF_NOCOLORMAPS
			top_layer.spriteyoffset = -40*FU
			top_layer.translation = "AllWhite"
			top_layer.dispoffset = 400
			top_layer.fuse = top_layer.tics
			
			if mo.extravalue2
				mo.extravalue2 = $ - 1
			end
		end
		if mo.extravalue1 <= TR + 1
			for i = 0,1
				local angle,vertang = FixedAngle(Soap_RandomFixedRange(0,360*FU)), FixedAngle(Soap_RandomFixedRange(0,360*FU))
				local toppush = FixedDiv(me.height,me.scale) / 2
				
				local s = P_SpawnMobjFromMobj(me,
					0,0,toppush, MT_PARTICLE
				)
				s.scale = FixedMul($/4, FU + Soap_RandomFixedRange(-FU/3,FU/3))
				s.state = P_RandomChance(FU/2) and S_SOAP_IMPACT_LINE2F or S_SOAP_IMPACT_LINE2
				s.angle = angle + ANGLE_180
				s.rollangle = InvAngle(vertang)
				s.translation = "AllWhite"
				s.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
				s.tracer = inf
				s.momx = $ + me.momx
				s.momy = $ + me.momy
				s.momz = $ + me.momz
			end
		end
		mo.extravalue1 = $ - 1
	else
		settimer(mo)
	end
end,MT_NSTELEFRAGGER)

local function unfuck(f, mo)
	if not (f and f.valid) then return end
	f.health = mobjinfo[f.type].spawnhealth
	return true
end
local function dotumble(p)
	local me = p.mo
	me.soap_tumble = true
	me.soap_tumble_oldmomz = me.momz
	me.soap_tumble_markedfordeath = CV.babykills.value == 1
end

local function doringing(bell, p)
	local mo = p.mo
	
	dotumble(p)
	
	local ang = FixedAngle(P_RandomRange(0,720)*FU)
	mo.state = S_PLAY_PAIN
	p.drawangle = ang + ANGLE_180
	
	if P_IsObjectOnGround(mo)
		mo.z = $ + P_MobjFlip(mo)
	end
	P_Thrust(mo, ang, 15*bell.scale)
	P_SetObjectMomZ(mo, 55*bell.scale)
	if Soap_IsLocalPlayer(p)
		Soap_StartQuake(20*FU, 10,
			nil,
			512*mo.scale
		)
	end
	
	Soap_Hitlag.addHitlag(mo, 12, true)
end
addHook("TouchSpecial",function(f, mo)
	if not (f and f.valid) then return false; end
	if not (mo and mo.valid) then return false; end
	--if not (mo.health) then return end
	if (mo == f.tracer and mo.fuckimmunity) then return unfuck(f,mo); end
	if (f.bell_cooldown) then return unfuck(f,mo); end
	if not (f and f.valid) then return false; end
	--if (mo.hitlag or mo.orbitbonk) then return end
	--if not Soap_ZCollide(f,mo, true) then return false; end
	
	local play = mo.player
	if (play and play.valid)
	and not (play.powers[pw_flashing])
		Soap_DamageSfx(mo,FU*3/4,FU)
		Soap_ImpactVFX(mo, f, nil, 3*FU)
		
		play.powers[pw_flashing] = 0
		P_ResetPlayer(play)
		mo.state = S_PLAY_PAIN
		
		doringing(f, play)
		
		return unfuck(f,mo)
	end
	if Soap_CanDamageEnemy(nil, mo)
		P_KillMobj(mo,f, f.tracer)
	end
	return unfuck(f,mo)
end,MT_NSTELEFRAGGER)
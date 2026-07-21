local CV = SOAP_CV
CV.belltumbles = CV_RegisterVar({
	name = "soap_belltumbles",
	defaultvalue = "On",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_OnOff,
})

local function SpawnExplosions(mine, doquake, docount)
	if doquake
		P_StartQuake(60*FU, TICRATE*2,
			{mine.x, mine.y, mine.z},
			550*mine.scale
		)
	end
	
	local radius = 32*FU
	local minz = 10
	local maxz = 30
	
	local count = docount
    if count == nil then count = 25 end

	local anglecount = FixedDiv(360*FU,count*FU)
	for i = 0,count
		local fa = FixedAngle(anglecount*i)
        -- adjusted fixed angle
        local afa = fa + P_RandomRange(-360, 360)*ANG1

		local mobj = P_SpawnMobjFromMobj(mine,
			FixedMul(cos(afa),radius + P_RandomRange(0,10)*FU),
			FixedMul(sin(afa),radius + P_RandomRange(0,10)*FU),
			0, --FU - FixedMul(mobjinfo[type].height,tracer.scale)/2,
			MT_THOK
		)
		mobj.flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_RUNSPAWNFUNC
		mobj.state = S_MM_TRIPMINE_EXPLODE
		mobj.momz = 0
		--mobj.spritexscale,mobj.spriteyscale = FU*2,FU*2
		mobj.flags2 = $ &~MF2_DONTDRAW
		
		mobj.angle = R_PointToAngle2(mobj.x,mobj.y, mine.x,mine.y)
		mobj.scale = $+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))
		
		P_Thrust(mobj, mobj.angle,
			-6*mobj.scale
		)
		P_SetObjectMomZ(mobj,P_RandomRange(minz,maxz)*FU)
		mobj.oldfx = true
		
		local static = P_SpawnMobjFromMobj(mine,
			FixedMul(cos(fa),radius + P_RandomRange(0,10)*FU),
			FixedMul(sin(fa),radius + P_RandomRange(0,10)*FU),
			0,
			MT_THOK
		)
		static.flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_RUNSPAWNFUNC
		static.state = S_MM_TRIPMINE_EXPLODE
		static.momz = 0
		static.flags2 = $ &~MF2_DONTDRAW
		
		static.angle = R_PointToAngle2(mobj.x,mobj.y, mine.x,mine.y)
		static.scale = $+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))
		
		P_Thrust(static, static.angle,
			-6*static.scale
		)
	end
end

local CV = SOAP_CV

SafeFreeslot("SPR_TRC1")
SafeFreeslot("SPR_SOAP_BLOATVFX")
SafeFreeslot("SPR_NSBELL")
SafeFreeslot("S_NSBELL_IDLE")
states[S_NSBELL_IDLE] = {
	sprite = SPR_NSBELL,
	frame = 0|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 34,
	var2 = 2,
	tics = (34*2),
	nextstate = S_NSBELL_IDLE
}

SafeFreeslot("S_NSBELL_RING")
states[S_NSBELL_RING] = {
	sprite = SPR_NSBELL,
	frame = 35|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 23,
	var2 = 2,
	tics = (23*2),
	nextstate = S_NSBELL_IDLE
}

SafeFreeslot("S_NSBELL_OVERTUNED")
states[S_NSBELL_OVERTUNED] = {
	sprite = SPR_TRC1,
	frame = A|FF_FULLBRIGHT|FF_ADD,
	tics = 1,
	nextstate = S_NSBELL_OVERTUNED,
	action = function(v)
		local me = v.target
		if not (me and me.valid and me.health and me.bell_overtuned)
			P_RemoveMobj(v)
			return
		end
		
		local p = me.player
		v.frame = ($ &~FF_FRAMEMASK)|(leveltime % 5)
		P_MoveOrigin(v, me.x,me.y,
			me.z - (((P_GetPlayerHeight(p) - me.height)/3) + (me.scale*2))
		)
		v.spritexscale = p.shieldscale / 2
		v.spriteyscale = v.spritexscale
	end
}

SafeFreeslot("S_NSBELL_CAURA")
states[S_NSBELL_CAURA] = {
	sprite = SPR_SOAP_BLOATVFX,
	frame = A|FF_FULLBRIGHT|FF_ADD,
	tics = 1,
	nextstate = S_NSBELL_CAURA,
	action = function(v)
		local me = v.target
		if not (me and me.valid)
			P_RemoveMobj(v)
			return
		end
		
		v.frame = ($ &~FF_FRAMEMASK)|(v.extravalue1 % 5)
		P_MoveOrigin(v, me.x,me.y,
			me.z + me.height/2
		)
		v.extravalue1 = $ + 1
	end
}

sfxinfo[SafeFreeslot("sfx_nbl_0")].caption = "Bell rings"
sfxinfo[SafeFreeslot("sfx_nbl_1")].caption = "Bell rings"
sfxinfo[SafeFreeslot("sfx_nbl_2")].caption = "Bell rings"
sfxinfo[SafeFreeslot("sfx_nbl_3")].caption = "Bell rings"

sfxinfo[SafeFreeslot("sfx_nbl_4")].caption = "/"
sfxinfo[SafeFreeslot("sfx_nbl_5")].caption = "/"
sfxinfo[SafeFreeslot("sfx_nbl_6")].caption = "/"
sfxinfo[SafeFreeslot("sfx_nbl_7")].caption = "/"

sfxinfo[SafeFreeslot("sfx_nbl_8")].caption = "/"
sfxinfo[SafeFreeslot("sfx_nbl_9")].caption = "/"

SafeFreeslot("MT_NSBELL")
mobjinfo[MT_NSBELL] = {
	doomednum = -1,
	spawnstate = S_NSBELL_IDLE,
	deathstate = S_NSBELL_IDLE,
	height = 134*FU,
	radius = 67*FU, --lol
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
		if not (me and me.valid) then continue end
		
		table.insert(availplayers, p)
	end
	if not (#availplayers) then return end
	
	baby.target = availplayers[P_RandomRange(1, #availplayers)].mo
	return true
end

local function settptimer(b)
	b.bell_teleporttime = P_RandomRange(6*TR, 20*TR)
end
addHook("MobjThinker",function(b)
	if not (b and b.valid) then return end
	
	if not (b.bell_init)
		b.bell_init = true
		
		b.soap_supervfx = true
		b.bell_cooldown = 0
		settptimer(b)
	end
	
	if b.bell_cooldown
		b.bell_cooldown = $ - 1
		if not b.bell_cooldown
			b.flags = $|MF_SPECIAL
		end
	end
	
	if (b.bell_teleporttime)
	and not (b.bell_cooldown)
		b.bell_teleporttime = $ - 1
		if not b.bell_teleporttime
			b.bell_teleportinanim = TR * 3/4
			
			local sfx = P_SpawnGhostMobj(b)
			sfx.flags2 = $|MF2_DONTDRAW
			sfx.fuse = 2 * TR
			sfx.tics = sfx.fuse
			S_StartSound(sfx, sfx_nbl_8)
		end
	end
	
	if (b.bell_teleportinanim)
		b.flags = $ &~MF_SPECIAL
		local frac = (FU / (TR*3/4))
		
		b.bell_teleportinanim = $ - 1
		b.spritexscale = ease.inback(
			FU - (frac * b.bell_teleportinanim),
			FU, 0, 2*FU
		)
		b.spriteyscale = b.spritexscale
		if CV.rotations.value
			b.rollangle = FixedAngle(ease.inexpo(
				FU - (frac * b.bell_teleportinanim),
				0, 360*FU
			))
		end
		
		if not b.bell_teleportinanim
			b.bell_teleportoutanim = TR / 2
			
			if TFrag_SearchForPlayers(b)
				local me = b.target
				local dist = Soap_RandomFixedRange(128*FU, 512*FU)
				local angle = FixedAngle(Soap_RandomFixedRange(0,360*FU))
				if P_RandomChance(FU/3)
					angle = R_PointToAngle2(0,0, me.momx,me.momy)
					local speed = R_PointToDist2(0,0, me.momx,me.momy)
					dist = 128*FU + speed
					if speed < FU
						angle = me.angle
					end
				end
				
				P_SetOrigin(b,
					me.x + P_ReturnThrustX(angle, dist),
					me.y + P_ReturnThrustY(angle, dist),
					me.z + Soap_RandomFixedRange(-256*FU, 256*FU)
				)
				b.z = clamp(b.floorz, $, b.ceilingz - b.height)
				local top_layer = P_SpawnMobjFromMobj(b, 0,0,0, MT_PARTICLE)
				top_layer.state = S_SOAP_HITM_RSPRK
				top_layer.spritexscale = $ * 6
				top_layer.spriteyscale = top_layer.spritexscale
				top_layer.renderflags = $|RF_ALWAYSONTOP|RF_FULLBRIGHT|RF_NOCOLORMAPS
				top_layer.spriteyoffset = -40*FU
				top_layer.translation = "AllWhite"
				top_layer.dispoffset = 400
				top_layer.fuse = top_layer.tics
			end
			
			S_StartSound(b, sfx_nbl_9)
		end
	end
	if (b.bell_teleportoutanim)
		b.flags = $ &~MF_SPECIAL
		local frac = (FU / (TR/2))
		
		b.bell_teleportoutanim = $ - 1
		b.spritexscale = ease.outback(
			FU - (frac * b.bell_teleportoutanim),
			0, FU, 2*FU
		)
		b.spriteyscale = b.spritexscale
		if CV.rotations.value
			b.rollangle = -FixedAngle(ease.outback(
				FU - (frac * b.bell_teleportoutanim),
				360*FU, 0, FU
			))
		end
		
		if not b.bell_teleportoutanim
			settptimer(b)
			b.flags = $|MF_SPECIAL
		end
	end
	
	if not S_SoundPlaying(b, sfx_nbl_4)
		S_StartSound(b, sfx_nbl_4)
	end
end,MT_NSBELL)

local BELL_EFFECT = 2*TR + TR/2
addHook("PlayerThink",function(p)
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if me.bell_init == nil
		me.bell_hits = 0
		me.bell_ticker = 0
		me.bell_overtuned = false
		me.bell_overtunevfx = false
		me.bell_overtuneticker = 0
		me.bell_effect = 0
		
		me.bell_init = true
	end
	
	if me.bell_ticker
	and not me.bell_overtuned
		me.bell_ticker = $ - 1
		if me.bell_ticker == 0
			me.bell_hits = max($ - 1, 0)
			if me.bell_hits
				-- holy nesting
				me.bell_ticker = 10*TR
			end
		end
	end
	
	if me.bell_overtuned
		if not me.bell_overtunevfx
			me.bell_overtunevfx = true
			local vfx = P_SpawnMobjFromMobj(me, 0,0,0,MT_PARTICLE)
			vfx.target = me
			vfx.state = S_NSBELL_OVERTUNED
			vfx.scale = $
			vfx.dispoffset = -100
		end
		
		if not S_SoundPlaying(me, sfx_nbl_5)
			S_StartSound(me, sfx_nbl_5, p)
		end
		me.bell_overtuneticker = $ - 1
		if not me.bell_overtuneticker
		or not me.health
			me.bell_overtuneticker = 0
			me.bell_overtuned = false
			S_StopSoundByID(me, sfx_nbl_5)
			S_StartSound(me, sfx_nbl_6)
			
			me.bell_hits = 0
			me.bell_ticker = 0
			
			if not me.health
				SpawnExplosions(me, true)
				for i = 0,4
					Soap_ImpactVFX(me,me, 4*FU, 2*FU, true,true)
				end
			end
		end
	else
		me.bell_overtunevfx = false
	end
	
	if (me.bell_effect)
		if me.bell_effect == (BELL_EFFECT - 4)
			p.flashpal = PAL_INVERT
		end
		
		me.bell_effect = $ - 1
		local frac = FU - FixedDiv(me.bell_effect, BELL_EFFECT)
		
		p.fovadd = ease.inquad(frac, -25*FU, 0)
		local ang = ease.inoutcubic(frac, 60*FU, 0)
		ang = FixedMul($, sin(FixedAngle(1080*frac)))
		
		if Soap_IsLocalPlayer(p)
			local cfrac = FU - ease.incubic(frac, FU * 5/6, 0)
			camera.momx = FixedMul($, cfrac)
			camera.momy = FixedMul($, cfrac)
			camera.momz = FixedMul($, cfrac)
		end
		p.viewrollangle = FixedAngle(ang)
	end
	
	if me.bell_deathanim
		me.bell_deathanim = $ - 1
		me.momx = $ * 3/4
		me.momy = $ * 3/4
		
		if me.bell_deathanim == 0
			P_FlashPal(p, PAL_WHITE, 2)
			
			P_KillMobj(me)
			me.fuse = 3*TR
			p.deadtimer = 3*TR
			p.soaptable.deadtimer = 3*TR
			
			me.soap_tumble = nil
			me.flags = $|MF_NOGRAVITY
			me.momx,me.momy,me.momz = 0,0,0
			me.flags2 = $|MF2_DONTDRAW
		end
	end
end)

addHook("HUD",function(v,p)
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if (me.bell_overtuned)
	or (me.bell_effect and (BELL_EFFECT - me.bell_effect < 12))
		local vignetteFlags = V_MODULATE|V_80TRANS
		
		local scale = FU
		local wid = (v.width() / v.dupx()) + 1
		local hei = (v.height() / v.dupy()) + 1
		local p_w = 320
		local p_h = 200
		
		local X_STR = FixedMul(FixedDiv(wid * FU, p_w * FU), scale)
		local Y_STR = FixedMul(FixedDiv(hei * FU, p_h * FU), scale)
		
		v.drawStretched(0,0, X_STR,Y_STR, v.cachePatch("VIGNTOP"),
			vignetteFlags|V_SNAPTOTOP|V_SNAPTOLEFT
		)
		v.drawStretched(0,200*FU, X_STR,Y_STR, v.cachePatch("VIGNBOTT"),
			vignetteFlags|V_SNAPTOBOTTOM|V_SNAPTOLEFT
		)
		
		v.drawStretched(320*FU,0, X_STR,Y_STR, v.cachePatch("VIGNTOP"),
			vignetteFlags|V_SNAPTOTOP|V_SNAPTORIGHT|V_FLIP
		)
		v.drawStretched(320*FU,200*FU, X_STR,Y_STR, v.cachePatch("VIGNBOTT"),
			vignetteFlags|V_SNAPTOBOTTOM|V_SNAPTORIGHT|V_FLIP
		)
	end
	
	/*
	if (me.bell_effect)
		local tick = (BELL_EFFECT - me.bell_effect) / 2
		if (tick >= 10) then return end
		local flag = V_MODULATE|(tick << V_ALPHAMASK)
		
		v.draw(0,0,v.cachePatch("VIGNTOP"),flag|V_SNAPTOTOP|V_SNAPTOLEFT)
		v.draw(0,0,v.cachePatch("VIGNBOTT"),flag|V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		v.draw(320,0,v.cachePatch("VIGNTOP"),flag|V_SNAPTOTOP|V_SNAPTORIGHT|V_FLIP)
		v.draw(320,0,v.cachePatch("VIGNBOTT"),flag|V_SNAPTOBOTTOM|V_SNAPTORIGHT|V_FLIP)
	end
	*/
end,"game")

local function unfuck(f, mo)
	if not (f and f.valid) then return end
	f.health = mobjinfo[f.type].spawnhealth
	return true
end
local function doringing(bell, p)
	bell.state = S_NSBELL_RING
	bell.bell_cooldown = TR * 4/5
	
	local top_layer = P_SpawnMobjFromMobj(bell, 0,0,0, MT_PARTICLE)
	top_layer.state = S_SOAP_HITM_RSPRK
	top_layer.spritexscale = $ * 6
	top_layer.spriteyscale = top_layer.spritexscale
	top_layer.renderflags = $|RF_ALWAYSONTOP|RF_FULLBRIGHT|RF_NOCOLORMAPS
	top_layer.spriteyoffset = -20*FU
	top_layer.fuse = top_layer.tics
	top_layer.translation = "AllWhite"
	
	local mo = p.mo
	
	if (CV.belltumbles.value or mo.bell_overtuned)
		Soap_DamageSfx(mo,FU*3/4,FU)
		Soap_ImpactVFX(mo, bell, nil, 3*FU)
		
		p.powers[pw_flashing] = 0
		P_ResetPlayer(p)
		mo.state = S_PLAY_PAIN
		
		mo.soap_tumble = true
		mo.soap_tumble_oldmomz = mo.momz
		mo.soap_tumble_markedfordeath = mo.bell_overtuned
		
		local ang = FixedAngle(P_RandomRange(0,720)*FU)
		mo.state = S_PLAY_PAIN
		p.drawangle = ang + ANGLE_180
		
		if P_IsObjectOnGround(mo)
			mo.z = $ + P_MobjFlip(mo)
		end
		P_Thrust(mo, ang, 15*bell.scale)
		P_SetObjectMomZ(mo, (mo.bell_overtuned and 50 or 22)*bell.scale)
	else
		mo.momx = $ / 4
		mo.momy = $ / 4
		P_SetObjectMomZ(mo, 40 * bell.scale)
	end
	
	S_StartSound(nil, sfx_nbl_0 + mo.bell_hits)
	S_StartSound(nil, sfx_nbl_0 + mo.bell_hits)
	
	if mo.bell_overtuned
		mo.bell_deathanim = TR
		S_StartSound(nil, sfx_nbl_7, play)
		S_StartSound(nil, sfx_nbl_7, play)
	end
	mo.bell_hits = $ + 1
	mo.bell_ticker = 10 * TR
	if mo.bell_hits == 3
		mo.bell_overtuned = true
		mo.bell_overtuneticker = 20*TR
	end
	Soap_Hitlag.addHitlag(mo, 12, mo.soap_tumble)
	
	for play in players.iterate
		play.realmo.bell_effect = BELL_EFFECT
		P_FlashPal(play, PAL_WHITE, 16)
		if Soap_IsLocalPlayer(play)
			Soap_StartQuake(30*FU, 12,
				nil,
				512*mo.scale
			)
		end
	end
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
		doringing(f, play)
		
		return unfuck(f,mo)
	end
	if Soap_CanDamageEnemy(nil, mo)
		P_KillMobj(mo,f, f.tracer)
	end
	return unfuck(f,mo)
end,MT_NSBELL)
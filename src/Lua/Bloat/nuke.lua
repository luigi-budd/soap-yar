local function SpawnExplosions(mine, doquake, docount)
	local radius = 70*FU
	local minz = 3
	local maxz = 60
	
	local count = 160
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
		mobj.fuse = TR * 3
		mobj.momz = 0
		--mobj.spritexscale,mobj.spriteyscale = FU*2,FU*2
		mobj.flags2 = $ &~MF2_DONTDRAW
		
		mobj.angle = R_PointToAngle2(mobj.x,mobj.y, mine.x,mine.y)
		mobj.forcescale = FU * 5 + Soap_RandomFixedRange(-4*FU, 2*FU)
		
		P_Thrust(mobj, mobj.angle,
			P_RandomRange(0, -30)*mobj.scale
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

sfxinfo[SafeFreeslot("sfx_sdn_0")] = {
	flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND,
	caption = "/"
}
sfxinfo[SafeFreeslot("sfx_sdn_1")].caption = "/"

SafeFreeslot("SPR_NSICBM")
SafeFreeslot("S_NSICBM_MISS")
states[S_NSICBM_MISS] = {
	sprite = SPR_NSICBM,
	frame = 0|FF_FULLBRIGHT,
	tics = -1,
	nextstate = S_NSICBM_MISS
}
SafeFreeslot("S_NSICBM_MARK")
states[S_NSICBM_MARK] = {
	sprite = SPR_NSICBM,
	frame = 1|FF_FULLBRIGHT|FF_ADD,
	tics = -1,
	nextstate = S_NSICBM_MARK
}
SafeFreeslot("MT_NSICBM")
mobjinfo[MT_NSICBM] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	deathstate = S_NULL,
	height = 64*FU,
	radius = 32*FU,
	spawnhealth = 1,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
}

local BELL_EFFECT = 2*TR + TR/2
addHook("MobjThinker", function(m)
	if not (m and m.valid) then return end
	local me = m.target
	if not (me and me.valid) then P_RemoveMobj(m); return end
	
	if not (m.mark and m.mark.valid)
		local b = P_SpawnMobjFromMobj(m, 0,0,0, MT_PARTICLE)
		b.state = S_NSICBM_MARK
		b.renderflags = $|RF_NOCOLORMAPS|RF_FLOORSPRITE|RF_NOSPLATBILLBOARD
		b.alpha = 0
		b.spritexscale = 4*FU
		b.spriteyscale = b.spritexscale
		b.dispoffset = 150
		m.trackingtime = 0
		m.explodetime = 0
		m.mark = b
		m.track = true
		
		local b = P_SpawnMobjFromMobj(m, 0,0,0, MT_PARTICLE)
		b.state = S_NSICBM_MARK
		b.frame = 2|FF_FULLBRIGHT|FF_ADD
		b.renderflags = $|RF_NOCOLORMAPS
		b.alpha = 0
		b.spritexscale = 20*FU
		b.spriteyscale = 0
		b.dispoffset = -100
		m.line = b
		
		local b = P_SpawnMobjFromMobj(m, 0,0,0, MT_PARTICLE)
		b.state = S_NSICBM_MISS
		b.renderflags = $|RF_NOCOLORMAPS
		b.flags2 = $|MF2_DONTDRAW
		b.scale = $ * 6
		m.missile = b
		
		S_StartSound(b, sfx_sdn_0)
	end
	
	if m.track
		local b = m.mark
		local l = m.line
		local v = m.missile
		P_MoveOrigin(b, me.x,me.y,me.z)
		P_MoveOrigin(l, b.x,b.y,b.z)
		P_MoveOrigin(v, b.x,b.y,b.z + 8000*b.scale)
		b.angle = $ + FixedAngle(5*FU)
		
		if m.trackingtime <= TR/2
			local frac = (FU/(TR/2)) * m.trackingtime
			b.alpha = ease.outquad(frac, 0, FU)
			b.spritexscale = ease.outquad(frac, 2*FU, FU)
			b.spriteyscale = b.spritexscale
		end
		if m.trackingtime == 2*TR + (TR*2/3)
			m.track = false
			b.renderflags = $|RF_ALWAYSONTOP
			v.flags2 = $ &~MF2_DONTDRAW
			S_StartSound(nil, sfx_sdn_1)
		end
		
		m.trackingtime = $ + 1
		return
	end
	local b = m.mark
	local l = m.line
	local v = m.missile
	local frac = FU/10
	b.angle = P_Lerp(frac, $, 0)
	b.spritexscale = P_Lerp(frac, $, 10*FU)
	b.spriteyscale = b.spritexscale
	
	l.alpha = P_Lerp(frac, $, FU)
	l.spritexscale = P_Lerp(frac, $, FU / 4)
	l.spriteyscale = P_Lerp(frac, $, 20*FU)
	
	v.z = ease.inquad((FU/(TR*3/2)) * m.explodetime,
		b.z + 8000*b.scale, b.z
	)
	
	m.explodetime = $ + 1
	P_StartQuake(m.explodetime * 4 * FU, 2)
	if m.explodetime == TR*3/2
		for p in players.iterate
			local me = p.realmo
			SpawnExplosions(me)
			for i = 0,12
				Soap_ImpactVFX(me,me, 6*FU, 6*FU, true,true)
			end
			S_StartSound(me, sfx_mmdie0)
			P_FlashPal(p, PAL_INVERT, 8)
			me.bell_effect = BELL_EFFECT * 3/2
			
			p.powers[pw_flashing] = 0
			P_ResetPlayer(p)
			me.state = S_PLAY_PAIN
			p.drawangle = R_PointToAngle2(me.x,me.y, b.x,b.y) + ANGLE_180
			
			if P_IsObjectOnGround(me)
				me.z = $ + P_MobjFlip(me)
			end
			me.soap_tumble = true
			me.soap_tumble_oldmomz = me.momz
			P_Thrust(me, R_PointToAngle2(me.x,me.y, b.x,b.y), 300 * m.scale)
			P_SetObjectMomZ(me, 300 * m.scale)
			
			if m.closeserver
				me.angle = R_PointToAngle2(me.x,me.y, b.x,b.y)
				p.cmd.angleturn = me.angle >> 16
			end
		end
		
		P_StartQuake(200*FU, 2*TR)
		
		SpawnExplosions(b)
		SpawnExplosions(b)
		for i = 0,12
			Soap_ImpactVFX(b,b, 6*FU, 6*FU, true,true)
		end
		if not m.closeserver
			P_RemoveMobj(m)
			P_RemoveMobj(b)
			P_RemoveMobj(l)
			P_RemoveMobj(v)
		else
			b.flags2 = $|MF2_DONTDRAW
			l.flags2 = $|MF2_DONTDRAW
			v.flags2 = $|MF2_DONTDRAW
		end
		return
	end
	if m.explodetime == (TR*3/2) + 23
		COM_BufInsertText(server, "exitgame")
		P_RemoveMobj(m)
		P_RemoveMobj(b)
		P_RemoveMobj(l)
		P_RemoveMobj(v)
	end
end,MT_NSICBM)

COM_AddCommand("nukethewholegeneration", function(p, closeserver)
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end

	local availplayers = {}
	for play in players.iterate
		if play.spectator then continue end
		local me = p.mo
		if not (me and me.valid and me.health) then continue end
		
		table.insert(availplayers, play)
	end
	if not (#availplayers) then return end
	local target = availplayers[P_RandomRange(1, #availplayers)].mo
	
	local nuke = P_SpawnMobjFromMobj(target, 0,0,0, MT_NSICBM)
	nuke.target = target
	nuke.closeserver = (closeserver ~= nil)
end)

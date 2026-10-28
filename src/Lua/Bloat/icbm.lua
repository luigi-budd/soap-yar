-- a REAL icbm and not a server nuke. Lol
local SpawnExplosions = Bloat_SpawnExplosions
local explosiondata = {
	radius = 70*FU,
	offsetlowbound = -20*FU,
	offsethighbound = 20*FU,
	scale = FU*3/2,
	scalelowbound = -FU/4,
	scalehighbound = FU/4,
	speed = 20*FU,
	speedlowbound = -5*FU,
	speedhighbound = 10*FU,
	momz = 0,
	momzlowbound = 3*FU,
	momzhighbound = 60*FU,
	scaletomobj = false,
	fuse = 2*TR,
	fuselowbound = -10,
	fusehighbound = 10,
}

-- warning
sfxinfo[SafeFreeslot("sfx_nci_0")] = {
	flags = SF_X2AWAYSOUND,
	caption = "/"
}
-- falling
sfxinfo[SafeFreeslot("sfx_nci_1")] = {
	flags = SF_X2AWAYSOUND,
	caption = "/"
}
-- explosion
sfxinfo[SafeFreeslot("sfx_nci_2")] = {
	flags = SF_X2AWAYSOUND,
	caption = "/"
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

local ST_COOLDOWN = 1
local ST_FOLLOWING = 2
local ST_TOUCHDOWN = 3
local ST_MAXSTATES = ST_FOLLOWING
local function TFrag_SearchForPlayers(baby)
	local availplayers = {}
	local player = nil
	
	baby.target = nil
	for p in players.iterate
		if p.spectator then continue end
		local me = p.mo
		if not (me and me.valid and me.health) then continue end
		if (p.playerstate == PST_DEAD) then continue end
		
		table.insert(availplayers, p)
	end
	if not (#availplayers) then return end
	
	baby.target = availplayers[P_RandomRange(1, #availplayers)].mo
	return true
end

local function settimer(mo)
	mo.extravalue1 = P_RandomRange(4*TR, 6*TR)
end

-- called when going to a state
local statefuncs = {
	[ST_COOLDOWN] = function(m)
		m.target = nil
		settimer(m)
		local b = m.mark
		local l = m.line
		local v = m.missile
		--if (b and b.valid) then P_RemoveMobj(b); end
		if (b and b.valid) then b.flags2 = $|MF2_DONTDRAW; end
		if (l and l.valid) then P_RemoveMobj(l); end
		if (v and v.valid) then P_RemoveMobj(v); end
		
		m.trackingtime = nil
		m.explodetime = nil
		m.track = nil
	end,
	[ST_FOLLOWING] = function(m)
		local b = m.mark
		if (b and b.valid) then P_RemoveMobj(b); end
		m.extravalue1 = 1
	end,
	[ST_TOUCHDOWN] = function(m)
		m.extravalue1 = 1
	end,
}

local BELL_EFFECT = 2*TR + TR/2
addHook("MobjThinker", function(m)
	if not (m and m.valid) then return end
	
	/*
	if m.extravalue1 == 0
		m.extravalue1 == ST_COOLDOWN
	end
	*/
	
	--print("missile", m.extravalue2, m.extravalue1)
	
	-- wait
	m.flags2 = $ &~MF2_DONTDRAW
	if m.extravalue2 == ST_COOLDOWN
		m.extravalue1 = $ - 1
		m.flags2 = $|MF2_DONTDRAW
	-- targeting
	elseif m.extravalue2 == ST_FOLLOWING
		local me = m.target
		if not (me and me.valid)
			if not TFrag_SearchForPlayers(m)
				return
			end
			me = m.target
		end
		if not (me and me.valid)
			m.target = nil
			return
		end
		
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
			b.scale = $ * 3
			m.missile = b
			
			local b = m.mark
			P_MoveOrigin(b, me.x,me.y,me.z)
			S_StartSound(m.mark, sfx_nci_0)
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
				S_StartSound(b, sfx_nci_1)
			end
			
			m.trackingtime = $ + 1
			return
		end
		local b = m.mark
		local l = m.line
		local v = m.missile
		local frac = FU/10
		b.angle = P_Lerp(frac, $, 0)
		b.spritexscale = P_Lerp(frac, $, 4*FU)
		b.spriteyscale = b.spritexscale
		
		l.alpha = P_Lerp(frac, $, FU)
		l.spritexscale = P_Lerp(frac, $, FU / 4)
		l.spriteyscale = P_Lerp(frac, $, 20*FU)
		
		v.z = ease.inquad((FU/(TR*5/3)) * (m.explodetime + 1),
			b.z + 4000*b.scale, b.z
		)
		
		m.explodetime = $ + 1
		if m.explodetime == TR/3
			S_StartSound(b, sfx_nci_2)
		end
		if m.explodetime == TR*5/3
			local killradius = FixedMul(90 * 4 * FU, m.scale)
			P_StartQuake(380*FU, 12, {b.x,b.y,b.z}, killradius*2)
			
			for p in players.iterate
				local me = p.mo
				if not (me and me.valid and me.health) then continue end
				
				local dist = R_PointTo3DDist(me.x,me.y,me.z + me.height, b.x,b.y,b.z)
				if dist - me.radius > killradius then continue end
				
				if (p.powers[pw_shield])
					S_StartSound(me, sfx_nssb)
					Soap_ImpactVFX(me, b, nil,nil,nil,nil, DMG_ELECTRIC)
					if (p.powers[pw_shield] & SH_FORCE)
						if (p.powers[pw_shield] & 255 == 0) -- no hp
							P_RemoveShield(p)
						else
							p.powers[pw_shield] = (($ & 255) - 1)|SH_FORCE
						end
					else
						P_RemoveShield(p)
					end
					p.powers[pw_flashing] = flashingtics - 1
					continue
				end
				
				-- Style inconsistency!!!! (Sfx vs VFX)
				Soap_DamageSfx(me, FU,FU,DMG_ELECTRIC,{vol = 255})
				Soap_ImpactVFX(me, b, nil, 3*FU, nil,nil, DMG_ELECTRIC)
				me.bell_effect = BELL_EFFECT
				me.bell_novignette = true
				
				if SOAP_CV.babykills.value
					P_DamageMobj(me, b,b, 1000, DMG_ELECTRIC)
				end
				
				if (me.health)
					p.powers[pw_flashing] = 3
					P_ResetPlayer(p)
					me.state = S_PLAY_PAIN
					
					me.soap_tumble = true
					me.soap_tumble_oldmomz = me.momz
				end
				
				local ang = R_PointToAngle2(me.x,me.y, b.x,b.y) + ANGLE_180
				me.state = S_PLAY_PAIN
				p.drawangle = ang + ANGLE_180
				
				if P_IsObjectOnGround(me)
					me.z = $ + P_MobjFlip(me)
				end
				P_InstaThrust(me, ang, 52*b.scale + FixedHypot(me.momx,me.momy))
				P_SetObjectMomZ(me, 72*b.scale)
				
				P_StartQuake(420*FU, 12)
				Soap_Hitlag.addHitlag(me, 28, true)
			end
			
			for i = 0,20
				local ha = FixedAngle(P_RandomRange(0,36) * 10*FU)
				local va = FixedAngle(P_RandomRange(-1,18) * 10*FU)
				local v = SphereToCartesian(ha,va)
				local s = P_SpawnMobjFromMobj(b,
					FixedMul(killradius, v.x),
					FixedMul(killradius, v.y),
					FixedMul(killradius, v.z),
					MT_PARTICLE
				)
				s.state = P_RandomChance(FU/2) and S_SOAP_IMPACT_LINE2F or S_SOAP_IMPACT_LINE2
				local offset = P_RandomRange(5, 10)
				s.tics = $ + offset
				s.anim_duration = $ + offset
				s.angle = ha
				s.rollangle = va
				s.renderflags = $|RF_ALWAYSONTOP|RF_NOCOLORMAPS
				s.color = SKINCOLOR_KETCHUP
				s.spritexscale = Soap_RandomFixedRange(FU*3, FU*7)
				s.spriteyscale = s.spritexscale
			end
			for i = 0,18
				Soap_ImpactVFX(b,b, 12*FU, Soap_RandomFixedRange(FU/2, 2*FU), false,false, DMG_NUKE)
			end
			SpawnExplosions(b, explosiondata)
			
			local iterations = 30
			local ang = FixedDiv(360*FU, iterations*FU)
			local limit = 28
			for i = 0, iterations
				local rock = P_SpawnMobjFromMobj(b,
					0,0, 4*FU,
					MT_LAVAFALLROCK
				)
				rock.flags = $|MF_NOCLIPTHING|MF_BOUNCE|MF_SLIDEME|MF_GRENADEBOUNCE &~(MF_PAIN|MF_SPECIAL)
				rock.state = S_ROCKCRUMBLEA+P_RandomRange(0, 3)
				rock.scale = $ * 3
				P_SetObjectMomZ(rock, Soap_RandomFixedRange(10*FU,20*FU))
				P_Thrust(rock, FixedAngle(ang * i), Soap_RandomFixedRange(10*FU,20*FU))
				rock.fuse = TR*3
			end
			Soap_DustRing(b,
				MT_SOAP_WALLBUMP,
				32,
				{b.x,b.y,b.z},
				killradius,
				killradius/20, --soap.last.momz,
				b.scale / 10,
				b.scale * 3,
				false, function(spark)
					--5 tics
					spark.scalespeed = FixedDiv(spark.destscale - (spark.scale / 10), 5*FU)
					
					spark.fuse = 5 * TR
					spark.startfuse = spark.fuse
					
					spark.random = P_RandomRange(-limit,limit) * ANG1
					spark.momz = Soap_RandomFixedRange(40*b.scale, 70*b.scale) * P_MobjFlip(b)
				end
			)
			
			-- P_RemoveMobj(b)
			P_RemoveMobj(l)
			P_RemoveMobj(v)
			m.extravalue1 = 0
		end
	end
	
	-- advance state
	if m.extravalue1 <= 0
		m.extravalue2 = $ + 1
		if m.extravalue2 > ST_MAXSTATES
			m.extravalue2 = ST_COOLDOWN
		end
		statefuncs[m.extravalue2](m)
	end
end, MT_NSICBM)
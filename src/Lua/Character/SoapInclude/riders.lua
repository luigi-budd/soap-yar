rawset(_G, "CR_RIDER", 1001)

freeslot("sfx_drift")
freeslot("MT_RIDERBOARD", "S_RIDERBOARD")
states[S_RIDERBOARD] = {
	sprite = SPR_GTOP,
	frame = G,
	tics = -1,
}
mobjinfo[MT_RIDERBOARD] = {
	doomednum = -1,
	spawnstate = S_RIDERBOARD,
	spawnhealth = 8,
	reactiontime = 4,
	deathstate = S_RIDERBOARD,
	speed = 30*FU,
	radius = 16*FU,
	height = 12*FU,
	mass = 100,
	flags = MF_SPECIAL|MF_SLIDEME|MF_SOLID
}

spr2defaults[freeslot("SPR2_GRND")] = SPR2_STND
states[freeslot("S_PLAY_GRIND")] = {
	sprite = SPR_PLAY,
	frame = SPR2_GRND,
	tics = -1,
}

local function spec(g)
	g.health = g.info.spawnhealth
	g.flags = $|MF_SPECIAL
end

addHook("TouchSpecial",function(glide, me)
	if not (me and me.valid) then return end
	local p = me.player
	
	if not (p and p.valid) then spec(glide); return end
	if (p.powers[pw_carry]) then spec(glide); return end
	
	p.powers[pw_carry] = CR_RIDER
	me.tracer = glide
	p.pflags = $|PF_JUMPSTASIS
	glide.target = me
	glide.flags = $ &~MF_SPECIAL
	
	glide.health = glide.info.spawnhealth
	glide.state = glide.info.spawnstate
	return true
end,MT_RIDERBOARD)

addHook("PostThinkFrame",do
for p in players.iterate
	local me = p.mo
	
	if not (me and me.valid) then continue end
	if p.powers[pw_carry] ~= CR_RIDER then continue end
	if not (me.tracer and me.tracer.valid) then continue end
	if me.tracer.type ~= MT_RIDERBOARD then continue end
	
	local top = me.tracer
	local p = me.player
	
	/*
	if R_PointToDist2(me.x,me.y, top.x,top.y) > top.radius * INT8_MAX
		P_MoveOrigin(top,
			me.x,
			me.y,
			me.z
		)
	end
	*/
	
	P_MoveOrigin(me,
		top.x, top.y,
		top.z + top.height + top.scale
	)
	
	p.skidtime = 0
	p.pflags = $|PF_FULLSTASIS
	p.powers[pw_nocontrol] = 2
	p.drawangle = top.angle
	p.soaptable.noability = $|SNOABIL_RDASH
	me.state = S_PLAY_GRIND
	me.momx = top.momx
	me.momy = top.momy
	me.momz = top.momz
	
	me.pitch = top.pitch
	me.roll = top.roll
end
end)

local function P_PitchRoll(me, frac)
	me.eflags = $|MFE_NOPITCHROLLEASING
	local angle = R_PointToAngle2(0,0, me.momx,me.momy)
	local mang = R_PointToAngle2(0,0, FixedHypot(me.momx, me.momy), me.momz)
	mang = InvAngle($)
	
	local destpitch = FixedMul(mang, cos(angle))
	local destroll = FixedMul(mang, sin(angle))
	me.pitch = P_Lerp(frac, $, destpitch)
	me.roll  = P_Lerp(frac, $, destroll)
end

local driftslide = tofixed("0.23")
local DRIFTSTAGE = 210
local driftcolors = {
	[0] = SKINCOLOR_WHITE,
	[1] = SKINCOLOR_SAPPHIRE,
	[2] = SKINCOLOR_SALMON,
	[3] = SKINCOLOR_GALAXY,
	[4] = SKINCOLOR_ISLAND,
}

addHook("MobjThinker",function(bo)
	if (bo.flags & MF_SPECIAL) then return end
	if not (bo.target and bo.target.valid)
		P_RemoveMobj(bo)
		return
	end
	local me = bo.target
	local p = me.player
	local cmd = p.cmd
	local soap = p.soaptable
	if not (p and p.valid)
		P_RemoveMobj(bo)
		return
	end
	if (me.tracer ~= bo)
	or (p.powers[pw_carry] ~= CR_RIDER)
		P_RemoveMobj(bo)
		return
	end
	
	bo.color = p.skincolor
	
	bo.grounded = P_IsObjectOnGround(bo) --or (bo.eflags & MFE_UNDERWATER)
	
	-- acceleration
	bo.friction = FU * 925/1000
	P_ButteredSlope(bo)
	bo.acceladd = $ or 0
	bo.forwardmove = P_Lerp(FU/2, $ or 0, soap.forwardmove*FU)
	bo.sidemove = P_Lerp(FU/6, $ or 0, soap.sidemove*FU)
	
	bo.angoffset = P_Lerp(FU/4, $ or 0, 0)
	bo.rollangle = P_Lerp(FU/4, $, 0)
	
	bo.drift = $ or 0
	bo.driftspark = $ or 0
	
	bo.accelboost = $ or 0
	bo.accelboosttic = $ or 0
	local noacceladd = false
	if bo.drift == 0 -- turning
		local offset = 60 * FixedDiv(bo.sidemove, 50*FU)
		bo.angoffset = -offset
		bo.rollangle = -FixedAngle(offset)
		
		if bo.oldangle ~= nil
			if (cmd.buttons & BT_SPIN)
			and ((soap.sidemove ~= 0) or (abs(me.angle - bo.oldangle) > ANG1*3))
			and not (bo.driftlockout)
				bo.drift = sign(soap.sidemove)
				if bo.drift == 0
					bo.drift = -sign(me.angle - bo.oldangle)
				end
			elseif (cmd.buttons & BT_SPIN == 0)
				bo.driftlockout = nil
			end
		end
	else
		if abs(bo.drift) < 5
			bo.drift = $ + (1 * sign($))
		end
		
		local slide = FixedMul(abs(bo.drift)*FU, driftslide)
		if P_IsLocalPlayer(p)
			camera.angle = $ - FixedAngle(slide)
		end
		if bo.grounded
			bo.driftspark = $ + 6
			if (soap.sidemove ~= 0)
				if (sign(soap.sidemove) == sign(bo.drift))
					slide = $ + abs(3 * FixedDiv(bo.sidemove, 50*FU))
					bo.acceladd = $ * 98/100
					bo.driftspark = $ - abs(3 * FixedDiv(bo.sidemove, 50*FU))/FU
					noacceladd = true
				else
					slide = $ - abs(3 * FixedDiv(bo.sidemove, 50*FU))
					bo.driftspark = $ + abs(8 * FixedDiv(bo.sidemove, 50*FU))/FU
				end
			end
			if (abs(bo.oldangle - me.angle) > FixedAngle(abs(slide)))
				local angdiff = (bo.oldangle - me.angle)
				if (sign(angdiff) == sign(bo.drift))
					bo.driftspark = $ + abs(6 * FixedDiv(angdiff, ANG10))/FU
					bo.acceladd = $ * 99/100
					noacceladd = true
				else
					if abs(angdiff) > ANG10
						me.angle = bo.oldangle + ANG10*sign(bo.drift)
						angdiff = ANG10 * sign($)
					end
					bo.driftspark = $ - abs(5 * FixedDiv(angdiff, ANG10))/FU
				end
			end
			me.angle = $ - FixedAngle(slide * sign(bo.drift))
			
			local spark = P_SpawnMobjFromMobj(bo,0,0,0,MT_SOAP_WALLBUMP)
			local speed = 6*bo.scale
			local limit = 28
			local my_ang = FixedAngle(Soap_RandomFixedRange(0,360*FU) - 9*FU*bo.drift)
			
			P_InstaThrust(spark, my_ang, speed)
			P_SetObjectMomZ(spark, Soap_RandomFixedRange(3*FU,8*FU) + (bo.driftspark/DRIFTSTAGE)*FU*3/2)
			
			P_SetScale(spark,bo.scale / 10, true)
			spark.destscale = bo.scale
			--5 tics
			spark.scalespeed = FixedDiv(bo.scale - bo.scale / 10, 5*FU)
			spark.color = driftcolors[bo.driftspark/DRIFTSTAGE]
			spark.colorized = true
			spark.fuse = TR
			
			spark.random = P_RandomRange(-limit,limit) * ANG1
			
			if (leveltime % 3 == 0)
				local sp = P_SpawnMobjFromMobj(bo,0,0,0,MT_SOAP_SPARK)
				sp.color = spark.color
				sp.adjust_angle = bo.angle + P_RandomRange(-70,70)*ANG1
				sp.target = bo
				
				sp.scale = $ / 3
				sp.spritexscale = FU
				sp.spriteyscale = FU - P_RandomFixed()/8
			end
			
			if not S_SoundPlaying(bo, sfx_drift)
				S_StartSound(bo,sfx_drift)
			end
		end
		bo.angoffset = -((9*FU*bo.drift) + slide*12 * sign(bo.drift))
		
		bo.driftspark = clamp(0, $, DRIFTSTAGE * 4)
		if (bo.driftspark/DRIFTSTAGE > bo.prevdriftspark/DRIFTSTAGE)
			S_StartSoundAtVolume(bo,sfx_s3ka2,192)
		end
		
		if not (cmd.buttons & BT_SPIN)
			local boost = 0
			if (bo.driftspark >= DRIFTSTAGE*4)
				bo.accelboost = FU/2
				bo.accelboosttic = 125
				boost = 25*bo.scale
				S_StartSound(bo,sfx_cdfm40)
				S_StartSound(bo,sfx_s3kc4l)
				S_StartSound(bo,sfx_kc5b)
			elseif (bo.driftspark >= DRIFTSTAGE*3)
				bo.accelboost = FU/4
				bo.accelboosttic = 85
				boost = 20*bo.scale
				S_StartSound(bo,sfx_cdfm40)
				S_StartSound(bo,sfx_kc5b)
			elseif (bo.driftspark >= DRIFTSTAGE*2)
				bo.accelboost = FU/5
				bo.accelboosttic = 50
				boost = 15*bo.scale
				S_StartSound(bo,sfx_kc5b)
			elseif (bo.driftspark >= DRIFTSTAGE)
				bo.accelboost = FU/6
				bo.accelboosttic = 20
				boost = 10*bo.scale
			end
			if boost
				P_Thrust(bo, cmd.angleturn << 16, boost)
				S_StartSound(bo,sfx_s23c)
			end
			
			bo.accelbooststage = bo.driftspark/DRIFTSTAGE
			bo.drift = 0
			bo.driftspark = 0
			S_StopSoundByID(bo, sfx_drift)
		end
		
		if FixedHypot(bo.momx,bo.momy) < 6*bo.scale
			bo.driftlockout = true
			bo.drift = 0
			bo.driftspark = 0
			S_StopSoundByID(bo, sfx_drift)
		end
	end
	bo.prevdriftspark = bo.driftspark
	
	local finalaccelboost = 0
	if bo.accelboosttic
		finalaccelboost = bo.accelboost
		Soap_WindLines(me,soap.rmomz, driftcolors[bo.accelbooststage])
		
		bo.accelboosttic = $ - 1
		if bo.accelboosttic == 0
			bo.accelboost = 0
		end
	end
	if (p.powers[pw_sneakers] or p.powers[pw_super])
		finalaccelboost = $ + FU/2
	end
	
	if (bo.oldrings ~= nil)
	and (p.rings > bo.oldrings)
		bo.ringboost = 12
	end
	bo.oldrings = p.rings
	
	if (bo.ringboost)
		finalaccelboost = $ + FU/3
		bo.ringboost = $ - 1
	end
	
	if bo.grounded
		if (soap.forwardmove ~= 0)
			local moveforce = min(FixedHypot(bo.forwardmove, bo.sidemove), 50*FU) * sign(bo.forwardmove)
			local movefact = FixedDiv(moveforce, 50*FU)
			local travelangle = bo.angle
			if (bo.drift ~= 0)
				travelangle = bo.movedir - FixedAngle(9*FU * bo.drift)
			end
			
			movefact = FixedMul($, FU + finalaccelboost)
			P_Thrust(bo, travelangle, FixedMul(2*FU + bo.acceladd, movefact))
			if not noacceladd
				bo.acceladd = min($ + FU/127, FU*3)
			end
		end
		if FixedHypot(bo.momx,bo.momy) / 12 < bo.acceladd
			bo.acceladd = FixedMul($, FU * 89/100)
		end
	else
		P_PitchRoll(bo, FU/6)
	end
	if (soap.forwardmove == 0)
		bo.acceladd = max($ - FU, 0)
	end
	bo.angle = P_Lerp(FU/7, $, me.angle + FixedAngle(bo.angoffset))
	bo.movedir = P_Lerp(FU/7, $, me.angle)
	bo.oldangle = me.angle
	
	if FixedHypot(bo.momx,bo.momy) > bo.scale
	and bo.grounded
		bo.rollangle = $ + (bo.movedir - R_PointToAngle2(0,0, bo.momx,bo.momy)) / 6
	end
	
	local extremeangle = (bo.drift ~= 0) and (55) or (45)
	if abs(bo.angle - R_PointToAngle2(0,0, bo.momx,bo.momy)) > FixedAngle(extremeangle*FU)
	and bo.grounded
	and FixedHypot(bo.momx,bo.momy) > 2 * bo.scale
	and (bo.drift == 0)
		local frac = FU * 902/1000
		bo.momx = FixedMul($, frac)
		bo.momy = FixedMul($, frac)
		bo.acceladd = FixedMul($, frac)
		
		if (leveltime % 3 == 0)
			local ang = bo.angle - ANGLE_90*sign(bo.angle - R_PointToAngle2(0,0, bo.momx,bo.momy))
			local dist = 12*FU
			for i = -3,3
				local off = ANG20 * i
				local angle = ang + off
				local dust = P_SpawnMobjFromMobj(bo,
					P_ReturnThrustX(nil, angle, dist),
					P_ReturnThrustY(nil, angle, dist),
					0, MT_SOAP_DUST
				)
				P_Thrust(dust,angle, 20*bo.scale)
				P_SetObjectMomZ(dust, (2 + (3 + i))*FU)
			end
			S_StartSoundAtVolume(bo,sfx_cdfm70, 255/2)
		end
	end
	
	-- jump
	if (cmd.buttons & BT_JUMP)
	and not (p.lastbuttons & BT_JUMP)
	and (bo.grounded)
	and (bo.drift == 0)
		P_SetObjectMomZ(bo, 12*FU)
	end
	if (cmd.buttons & BT_JUMP == 0)
	and (p.lastbuttons & BT_JUMP)
	and (not bo.grounded and (bo.momz * P_MobjFlip(bo) > 0))
		bo.momz = $ / 2
	end
	
	-- dismount
	if (cmd.buttons & (BT_JUMP|BT_SPIN) == (BT_JUMP|BT_SPIN))
		P_ResetPlayer(p)
		P_DoJump(p)
		p.pflags = $|PF_JUMPED &~PF_THOKKED
		me.tracer = nil
	end
	
	local speed = R_PointTo3DDist(0,0,0, bo.momx,bo.momy,bo.momz)
	Soap_AccelerativeSpeedlines(p,me,soap, speed, 40*bo.scale)
end,MT_RIDERBOARD)

addHook("MobjCollide",function(mo, thing)
	if thing.type == MT_RIDERBOARD
	and (thing == mo.tracer)
		return false
	end
end, MT_PLAYER)
addHook("MobjMoveCollide",function(mo, thing)
	if (thing.flags & MF_SPRING)
	and (mo.player.powers[pw_carry] == CR_RIDER)
		return false
	end
end, MT_PLAYER)
addHook("MobjMoveCollide",function(mo, thing)
	if thing == mo.target
		return false
	elseif (thing.flags & MF_SPRING)
		P_DoSpring(thing, mo)
	end
end, MT_RIDERBOARD)
addHook("MobjMoveBlocked",function(top,m,l)
	P_BounceMove(top)
end,MT_RIDERBOARD)
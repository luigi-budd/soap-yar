local AI_MINALPHA = FU/4
addHook("MobjThinker",function(ai)
	if (ai.target and ai.target.valid
	and ai.target.hitlag)
	and ai.checkedit
		return true
	end
	
	ai.frame = (ai.takis_frame or A)
	
	if SOAP_CV.ai_style.value == 3 then
		if (leveltime/4) & 1 then
			ai.flags2 = $|MF2_DONTDRAW
		else
			ai.flags2 = $ &~MF2_DONTDRAW
		end
	else
		local sine = abs(sin(FixedAngle(leveltime*FU*10)))
		ai.alpha = AI_MINALPHA + max(sine - AI_MINALPHA, 0)
		ai.flags2 = $ &~MF2_DONTDRAW
	end
	
	ai.checkedit = true
end,MT_SOAP_AFTERIMAGE)

--this isnt hardcode so get the state_t from states
local halftics = states[mobjinfo[MT_SOAP_SPEEDLINE].spawnstate].tics/2
addHook("MobjThinker",function(wind)
	if not (wind and wind.valid) then return end
	if (wind.source and wind.source.valid and wind.source.hitlag)
		return true
	end
	
	if wind.tics <= halftics
		local factor = FixedDiv(wind.tics*FU,halftics*FU) --* (halftics - wind.tics)
		
		--worse effect but i cant get the squishing
		--to look good
		wind.alpha = factor
	end
	
	if wind.topwind
	and (wind.source and wind.source.valid)
		local me = wind.source
		local ang = wind.movedir
		P_MoveOrigin(wind,
			me.x + P_ReturnThrustX(nil, ang, wind.offset),
			me.y + P_ReturnThrustY(nil, ang, wind.offset),
			me.z + wind.offsetz
		)
		wind.offsetz = $ + (wind.source.scale / 5 * P_MobjFlip(me))
		wind.angle = ang + ANGLE_90
		wind.movedir = $ - FixedAngle(35*FU)
	end
end,MT_SOAP_SPEEDLINE)

addHook("MobjThinker",function(bump)
	if not (bump and bump.valid) then return end
	
	local me = bump.target
	if (me and me.valid)
		if me.hitlag
			return true
		end
	end
	
	if bump.startfuse ~= nil
	and bump.fuse == bump.startfuse * 3/8
		bump.destscale = 0
		bump.scalespeed = FixedDiv(bump.scale, bump.fuse*FU)
	end
	
	if bump.grabmode
		local ro = bump.rotate
		local h_dist = FixedMul(cos(ro.va), ro.dist)
		P_MoveOrigin(bump,
			ro.x + P_ReturnThrustX(nil, ro.ha, h_dist),
			ro.y + P_ReturnThrustY(nil, ro.ha, h_dist),
			ro.z + FixedMul(sin(ro.va), ro.dist)
		)
		ro.va = $ + ANG20 * bump.sign
		ro.dist = $ + 6*bump.scale
		return
	end
	
	bump.momz = $ + P_GetMobjGravity(bump)
	bump.rollangle = $ + (bump.random or 0)
	bump.lifetime = (bump.lifetime ~= nil and $+1 or 0)
	
	if bump.shoemode
		bump.angle = $ + ANG15
	end
	if bump.sweat
		local squish = 0
		if bump.lifetime & 1 then --nothing
		else
			if (bump.lifetime/2) & 1
				squish = FU/4
			else
				squish = -FU/4
			end
		end
		bump.spritexscale = FU + squish
		bump.spriteyscale = FU - squish
	end
end,MT_SOAP_WALLBUMP)

addHook("MobjThinker",function(spark)
	if not (spark and spark.valid) then return end
	local me = spark.target
	if not (me and me.valid) then return end
	
	if not P_IsObjectOnGround(me)
	and not (spark.dontdelete)
		spark.target = nil
		return
	end
	
	if (spark.flags & MF_NOTHINK or me.flags & MF_NOTHINK) then return true; end
	
	P_MoveOrigin(spark, me.x,me.y,me.z)
	spark.angle = spark.adjust_angle
	--spark.flags2 = $^^MF2_DONTDRAW
end,MT_SOAP_SPARK)

addHook("MobjThinker",function(mo)
	if not (mo.target and mo.target.valid)
	or not (mo.target.health)
	or not (mo.target.soap_stunned)
		P_RemoveMobj(mo)
		return
	end
	
	mo.rollangle = $ + ANG10
	mo.timealive = $ + 10*FU
	mo.extravalue1 = $ + 23*FU
	local org = mo.target
	local angle = FixedAngle(mo.ang*mo.movecount + mo.timealive)
	local angle2 = FixedAngle(mo.ang*mo.movecount + mo.extravalue1)
	P_MoveOrigin(mo,
		org.x + P_ReturnThrustX(nil,angle,org.radius),
		org.y + P_ReturnThrustY(nil,angle,org.radius),
		org.z + org.height + 10*org.scale + FixedMul(5 * sin(angle2),org.scale)
	)
	mo.destscale = org.scale
	mo.scalespeed = mo.destscale
	
	if mo.hitlag_t
	and mo.target.soap_stunned < 10
		mo.alpha = (FU/10) * mo.target.soap_stunned
	else
		mo.alpha = FU
	end
end,MT_SOAP_STUNNED)

local damagecolors = {
	SKINCOLOR_WHITE,
	SKINCOLOR_RED,
	SKINCOLOR_MAGENTA,
	SKINCOLOR_YELLOW,
	SKINCOLOR_SAPPHIRE
}

local RED_OFFSET = 16*FU
local RED_STAROFFSET = 8*FU
local STAR_DRAG = FU*99/100
local function NewVFXThink(v)
	if (v.state == S_SOAP_HITM_RSPRK)
	and (v.tics == 1)
		for i = 0, 5
			local star = P_SpawnMobjFromMobj(v,
				Soap_RandomFixedRange(-RED_STAROFFSET, RED_STAROFFSET),
				Soap_RandomFixedRange(-RED_STAROFFSET, RED_STAROFFSET),
				Soap_RandomFixedRange(-RED_STAROFFSET, RED_STAROFFSET) + 40*FU,
				MT_SOAP_FREEZEGFX
			)
			star.state = S_SOAP_HITM_STAR
			star.soap_newvfx = true
			star.color = damagecolors[P_RandomRange(1, #damagecolors)]
			star.scale = $ * 2
			star.spritexscale = v.spritexscale / 4
			star.spriteyscale = star.spritexscale
			local ha,va = R_PointTo3DAngles(v.x,v.y,v.z, star.x,star.y,star.z)
			P_3DThrust(star, ha,va, P_RandomRange(12,20)*FU)
			star.vfx_roll = FixedAngle(P_RandomRange(-28,28)*FU)
			star.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP)
			star.momx = $ + v.vfx_mom[1]
			star.momy = $ + v.vfx_mom[2]
			star.momz = $ + v.vfx_mom[3] * 3/4
		end
		local wave = P_SpawnMobjFromMobj(v,0,0,0,MT_PARTICLE)
		wave.spritexscale = v.spritexscale
		wave.spriteyscale = wave.spritexscale
		wave.state = S_SOAP_HITM_SHCKW
	end
	if (v.state == S_SOAP_HITM_STAR)
		v.rollangle = $ + v.vfx_roll
		
		--v.momx = FixedMul($, STAR_DRAG)
		--v.momy = FixedMul($, STAR_DRAG)
		v.momz = FixedMul($, STAR_DRAG)
		
		if not P_TryMove(v, v.x + v.momx, v.y + v.momy, true)
			P_BounceMove(v)
		end
		if ((v.z + v.momz <= v.floorz)
		or (v.z + 16*v.spritexscale + v.momx >= v.ceilingz))
		and not (v.extravalue1)
			v.momz = -$
			v.extravalue1 = 1
			v.flags = $|MF_NOCLIPHEIGHT
		end
		
		P_ZMovement(v)
		v.momz = $ + P_GetMobjGravity(v)
		
		v.tics = $ - 1
		if v.tics == 0
			P_RemoveMobj(v)
		elseif v.tics == TR/4
			v.destscale = 0
			v.scalespeed = FixedDiv(v.scale, v.tics*FU)
		end
		return true
	end

	if v.vfx_tospawn
		if v.vfx_delays[v.vfx_tospawn] > 0
			v.vfx_delays[v.vfx_tospawn] = $ - 1
			return
		end
		
		local blue = P_SpawnMobjFromMobj(v,
			Soap_RandomFixedRange(-RED_OFFSET, RED_OFFSET),
			Soap_RandomFixedRange(-RED_OFFSET, RED_OFFSET),
			Soap_RandomFixedRange(-RED_OFFSET, RED_OFFSET),
			MT_PARTICLE
		)
		blue.state = S_SOAP_HITM_BSPRK
		blue.spritexscale = (v.spritexscale * 6/5) + P_RandomFixed()/2
		blue.spriteyscale = blue.spritexscale
		v.vfx_tospawn = $ - 1
	elseif (v.state == S_INVISIBLE)
		P_RemoveMobj(v)
		return
	end
end

--lol
local function FreezeInHitlag(mo)
	-- this is handled here because i cant be bothered to make a new mobj
	if mo.soap_newvfx
		return NewVFXThink(mo)
	end
	
	local me = mo.tracer
	if not (me and me.valid and me.health)
		P_RemoveMobj(mo)
		return
	end
	local p = me.player
	local soap = p.soaptable
	
	if (mo.state == S_SOAP_NWF_WIND)
	or (mo.state == S_SOAP_NWF_WIND_FAST)
	or (mo.state == S_TAKIS_SLINGFX)
		if mo.boostaura
			if (mo.frame & FF_FRAMEMASK) >= D
				mo.frame = A|($ &~FF_FRAMEMASK)
			end
		end
		
		local ang = R_PointToAngle2(0,0,me.momx,me.momy)
		if R_PointToDist2(0,0, me.momx,me.momy) < me.scale
			ang = p.drawangle
		end
		if (mo.state == S_TAKIS_SLINGFX)
			ang = me.angle
		end
		
		mo.dispoffset = me.dispoffset - 1
		mo.angle = ang
		if (mo.frame & FF_PAPERSPRITE)
		or (mo.renderflags & RF_PAPERSPRITE)
			mo.angle = $ - ANGLE_90
		end
		mo.destscale = me.scale
		mo.scalespeed = mo.destscale
		mo.color = me.color
		mo.pitch,mo.roll = me.pitch,me.roll
		
		P_MoveOrigin(mo,
			me.x + P_ReturnThrustX(nil,ang,mo.dist),
			me.y + P_ReturnThrustY(nil,ang,mo.dist),
			me.z + (mo.zoffset or 0)
		)
		
		if mo.zcorrect
			if (soap.gravflip == -1)
				mo.z = me.z + me.height - mo.height - (mo.zoffset or 0)
				mo.eflags = $|MFE_VERTICALFLIP
			else
				mo.eflags = $ &~MFE_VERTICALFLIP
			end
		end
		
	end
	if me.hitlag
		return true
	end
end
addHook("MobjThinker",FreezeInHitlag,MT_SOAP_FREEZEGFX)

local dust_mul = FU*19/22
addHook("MobjThinker",function(mo)
	if not mo.extravalue1
		mo.tics = $ + P_RandomKey(7)
		mo.extravalue1 = 1
	end
	mo.momx,mo.momy,mo.momz = FixedMul($1,dust_mul),FixedMul($2,dust_mul),FixedMul($3,dust_mul)
end,MT_SOAP_DUST)

local maces = {}
addHook("PostThinkFrame",do
	for k,mobj in ipairs(maces)
		if not (mobj and mobj.valid)
			table.remove(maces,k)
		end
	end
	for k,mace in ipairs(maces)
		if not (mace and mace.valid) then continue end
		mace.last_x = mace.x
		mace.last_y = mace.y
		mace.last_z = mace.z
	end
end)
addHook("NetVars",function(n) maces = n($); end)

local function macethinker(mace)
	table.insert(maces,mace)
end
addHook("MobjSpawn",macethinker,MT_SMALLMACE)
addHook("MobjSpawn",macethinker,MT_BIGMACE)

addHook("MobjThinker",function(rock)
	if not (rock and rock.valid) then return end
	if rock.soap_flingcooldown == nil
		rock.soap_flingcooldown = 0
	end
	
	if rock.soap_flingcooldown
		rock.takis_flingme = false
		rock.soap_flingcooldown = $ - 1
	else
		rock.takis_flingme = true
	end
end,MT_ROLLOUTROCK)

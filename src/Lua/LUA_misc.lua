local AI_MINALPHA = FU/4
addHook("MobjThinker",function(ai)
	if (ai.target and ai.target.valid
	and ai.target.hitlag)
	and ai.checkedit
		/*
		if (ai.savescale == nil)
			ai.savescale = ai.scalespeed
			ai.savedest = ai.destscale
		end
		ai.scalespeed = 0
		ai.destscale = ai.scale
		*/
		return true
	end
	/*
	if (ai.savescale ~= nil)
		ai.scalespeed = ai.savescale
		ai.destscale = ai.savedest
		
		ai.savescale = nil
		ai.savedest = nil
	end
	*/
	/*
	ai.spritexoffset = ai.takis_spritexoffset or 0
	ai.spriteyoffset = ai.takis_spriteyoffset or 0
	ai.spritexscale = ai.takis_spritexscale or FU
	ai.spriteyscale = ai.takis_spriteyscale or FU
	ai.rollangle = ai.takis_rollangle or 0
	ai.pitch = ai.takis_pitch or 0
	ai.roll = ai.takis_roll or 0
	*/
	
	ai.frame = ai.takis_frame
	
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
		/*
		wind.spritexscale = FU + FixedMul(factor, (cos(wind.rollangle)))
		wind.spriteyscale = FU - FixedMul(factor, (sin(wind.rollangle + ANGLE_90)))
		
		wind.spritexscale = $ + factor
		wind.spriteyscale = $ - factor
		
		wind.spritexscale = max($,1)
		wind.spriteyscale = max($,1)
		*/
		
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
	
	if bump.fuse == TR/2
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

--lol
local function FreezeInHitlag(mo)
	local me = mo.tracer
	if not (me and me.valid and me.health)
		P_RemoveMobj(mo)
		return
	end
	local p = me.player
	local soap = p.soaptable
	
	if (mo.state == S_SOAP_NWF_WIND)
	or (mo.state == S_SOAP_NWF_WIND_FAST)
		if mo.boostaura
			if (mo.frame & FF_FRAMEMASK) >= D
				mo.frame = A|($ &~FF_FRAMEMASK)
			end
		end
		
		mo.dispoffset = me.dispoffset - 1
		mo.angle = R_PointToAngle2(0,0,me.momx,me.momy)
		mo.destscale = me.scale
		mo.scalespeed = mo.destscale
		mo.color = me.color
		mo.pitch,mo.roll = me.pitch,me.roll
		
		P_MoveOrigin(mo,
			me.x + P_ReturnThrustX(nil,mo.angle,mo.dist),
			me.y + P_ReturnThrustY(nil,mo.angle,mo.dist),
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

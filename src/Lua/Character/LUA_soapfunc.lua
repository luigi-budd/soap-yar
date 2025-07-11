local CV = SOAP_CV
local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SPINDUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end

local function spawnbubble(p,me,soap)
	local h = FixedDiv(me.height, me.scale)/FU
	local buble = P_SpawnMobjFromMobj(me,
		P_RandomFixedRange(-16,16),
		P_RandomFixedRange(-16,16),
		P_RandomFixedRange(0,h),
		MT_THOK
	)
	P_SetObjectMomZ(buble, P_RandomFixedRange(1,4))
	P_Thrust(buble, R_PointToAngle2(buble.x,buble.y, me.x,me.y), P_RandomFixedRange(1,4))
	buble.fuse = P_RandomRange(TR/2, TR)
	buble.color = me.color
	buble.colorized = true
	local state = mobjinfo[P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE)].spawnstate
	buble.state = state
	buble.blendmode = AST_ADD
	buble.renderflags = $|RF_SEMIBRIGHT
	buble.mirrored = P_RandomChance(FU/2)
	local scale = P_RandomFixedRange(0, 2)/3
	buble.spritexscale = $ + scale
	buble.spriteyscale = $ + scale
	return buble
end

local BTtoTable = {
	[BT_CUSTOM1] = "c1",
	[BT_CUSTOM2] = "c2",
	[BT_CUSTOM3] = "c3",
	[BT_USE] = "use",
	[BT_TOSSFLAG] = "tossflag",
	[BT_ATTACK] = "fire",
	[BT_FIRENORMAL] = "firenormal",
	[BT_JUMP] = "jump",
	[BT_WEAPONNEXT] = "weaponnext",
	[BT_WEAPONPREV] = "weaponprev",
}

local function btntic(p,tic,enum)
	local btn = p.cmd.buttons
	if btn & enum
		if tic ~= 0
			p.soaptable[BTtoTable[enum].."_R"] = 5 + p.cmd.latency
		end
		tic = $+1
	else
		tic = 0
		if p.soaptable[BTtoTable[enum].."_R"] > 0
			p.soaptable[BTtoTable[enum].."_R"] = $-1
		end
	end
	return tic
end

rawset(_G,"Soap_ButtonStuff", function(p)
	local soap = p.soaptable
	
	soap.jump			= btntic(p,	$,	BT_JUMP			)
	soap.use			= btntic(p,	$,	BT_USE			)
	soap.tossflag		= btntic(p,	$,	BT_TOSSFLAG		)
	soap.c1				= btntic(p,	$,	BT_CUSTOM1		)
	soap.c2				= btntic(p,	$,	BT_CUSTOM2		)
	soap.c3				= btntic(p,	$,	BT_CUSTOM3		)
	soap.fire			= btntic(p,	$,	BT_ATTACK		)
	soap.firenormal		= btntic(p,	$,	BT_FIRENORMAL	)
	soap.weaponnext		= btntic(p,	$,	BT_WEAPONNEXT	)
	soap.weaponprev		= btntic(p,	$,	BT_WEAPONPREV	)
	
	if p.cmd.buttons & BT_WEAPONMASK
		soap.weaponmasktime = $+1
		soap.weaponmask = (p.cmd.buttons & BT_WEAPONMASK)
	else
		soap.weaponmasktime = 0
		soap.weaponmask = 0
	end
	
	if (gametyperules & GTR_RACE)
	and p.realtime == 0
		soap.c1 = 0
		soap.c2 = 0
		soap.c3 = 0		
	end
	
	/*
	if (p.pflags & PF_STASIS)
	or (p.powers[pw_nocontrol])
	or ((p.realmo and p.realmo.valid) 
	and ((p.realmo.reactiontime)
	or (p.realmo.hitlag)))
		soap.jump = 0
		soap.use = 0
		soap.tossflag = 0
		soap.c1 = 0
		soap.c2 = 0
		soap.c3 = 0
		soap.weaponnext = 0
		soap.weaponprev = 0
	end
	*/
end)

local MSF_TRIGGERSPECIAL_HEADBUMP	= MSF_TRIGGERSPECIAL_HEADBUMP	or 8
local MSF_FLIPSPECIAL_FLOOR			= MSF_FLIPSPECIAL_FLOOR			or 1
local MSF_FLIPSPECIAL_CEILING		= MSF_FLIPSPECIAL_CEILING		or 2

local function checkpredictedpitcollide(p, me, z)
	if (p.pflags & PF_GODMODE) then return end
	
	local sec = me.subsector.sector
	--dont use mobj->floorz/ceilingz because of fofs
	local secFloor = sec.floorheight
	local secTop = sec.ceilingheight
	if sec.f_slope
		secFloor = P_GetZAt(sec.f_slope, me.x,me.y)
	end
	if sec.c_slope
		secTop = P_GetZAt(sec.c_slope, me.x,me.y)
	end
	
	if (((z <= secFloor
		and ((sec.flags & MSF_TRIGGERSPECIAL_HEADBUMP)
			or (me.eflags & MFE_VERTICALFLIP == 0))
		and (sec.flags & MSF_FLIPSPECIAL_FLOOR))
	or (z >= secTop
		and ((sec.flags & MSF_TRIGGERSPECIAL_HEADBUMP)
			or (me.eflags & MFE_VERTICALFLIP))
		and sec.flags & MSF_FLIPSPECIAL_CEILING)))
	and (sec.damagetype == SD_DEATHPITTILT
	or sec.damagetype == SD_DEATHPITNOTILT) then
		return true
	end
	return false
end
--expose
rawset(_G,"P_CheckPredictedPitCollide",checkpredictedpitcollide)

rawset(_G,"Soap_Booleans", function(p)
	local soap = p.soaptable
	local me = p.realmo
	
	soap.gravflip = P_MobjFlip(me)
	
	local posz = me.floorz
	local z = me.z + me.momz
	local onPosZ
	if (P_MobjFlip(me) == -1)
		posz = me.ceilingz
		z = me.z+me.height + me.momz
		onPosZ = (z >= posz)
	else
		onPosZ = (z <= posz)
	end
	
	soap.onGround = (P_IsObjectOnGround(me) or onPosZ)
	if P_CheckDeathPitCollide(me) then soap.onGround = false; end
	if checkpredictedpitcollide(p, me, z) then soap.onGround = false; end
	
	soap.inPain = P_PlayerInPain(p)
	if (p.powers[pw_carry] == CR_NIGHTSMODE)
		if p.powers[pw_flashing] > (2*flashingtics)/3 then soap.inPain = true; end
	end
	
	--lol
	soap.inFangsHeist = FangsHeist and FangsHeist.playerHasSign(p)
	soap.inWater = (me.eflags & (MFE_UNDERWATER|MFE_TOUCHLAVA) == MFE_UNDERWATER)
	soap.in2D = (me.flags2 & MF2_TWOD or twodlevel)
	soap.inBattle = (CBW_Battle and CBW_Battle.BattleGametype())
	
	if (p.solchar)
		soap.isSolForm = (p.solchar.istransformed) and true or false
	else
		soap.isSolForm = false
	end
	
	soap.onWater = false
	if (p.charflags & SF_RUNONWATER)
		local water_top = me.watertop
		if (soap.gravflip == -1) then water_top = me.waterbottom end
		
		if P_IsObjectOnGround(me)
		and (water_top ~= me.z - 1000*FU)
		and (z == water_top)
			soap.onWater = true
		end
	end
	
end)

--came full circle
local AICOLOR_START = SKINCOLOR_PINK
local AICOLOR_END = FIRSTSUPERCOLOR
local AICOLOR_LENGTH = AICOLOR_END - AICOLOR_START
local AI_MINALPHA = FU/4
rawset(_G,"Soap_CreateAfterimage", function(p,me)
	if not (me and me.valid) then return end
	
	local soap = p.soaptable
	local rflags = RF_FULLBRIGHT|RF_NOCOLORMAPS
	local ghost = P_SpawnMobjFromMobj(me,-me.momx,-me.momy,-soap.rmomz*soap.gravflip,MT_SOAP_AFTERIMAGE)
	ghost.target = me
	ghost.flags2 = $|MF2_DONTDRAW
	
	ghost.skin = me.skin
	ghost.scale = me.scale
	
	ghost.sprite = me.sprite
	
	ghost.sprite2 = me.sprite2
	ghost.frame = me.frame & FF_FRAMEMASK
	ghost.takis_frame = me.frame & FF_FRAMEMASK
	
	local sine = abs(sin(FixedAngle(leveltime*FU*10)))
	ghost.alpha = AI_MINALPHA + max(sine - AI_MINALPHA, 0)
	
	ghost.tics = -1
	ghost.fuse = 4
	ghost.renderflags = $|rflags
	ghost.blendmode = AST_ADD
	
	ghost.angle = p.drawangle
	
	local rainbow = AICOLOR_START + (leveltime % (AICOLOR_LENGTH))
	if not SOAP_CV.rainbow_ai.value
		rainbow = ColorOpposite(p.skincolor)
	end
	
	ghost.colorized = true
	if G_GametypeHasTeams()
		rainbow = (p.ctfteam == 1) and skincolor_redteam or skincolor_blueteam
		rainbow = ($ + P_RandomRange(0,3)) % AICOLOR_END
	end
	ghost.color = rainbow
	
	ghost.spritexscale,ghost.spriteyscale = me.spritexscale, me.spriteyscale
	ghost.spritexoffset,ghost.spriteyoffset = me.spritexoffset, me.spriteyoffset
	ghost.rollangle = me.rollangle
	ghost.pitch = me.pitch or 0
	ghost.roll = me.roll or 0
	
	--Dont draw right ontop of our takis
	ghost.dontdrawforviewmobj = me
	ghost.dispoffset = me.dispoffset - 1
	--ghost.destscale = me.scale/2
	--ghost.scalespeed = FixedDiv(me.scale - ghost.destscale, ghost.fuse*FU)
	
	P_SetOrigin(ghost,
		ghost.x, ghost.y, ghost.z
	)
	
	if p.followitem == MT_SOAP_PEELOUT
	and (p.followmobj and p.followmobj.valid)
	and p.followmobj.outs ~= nil
		local m_peel = p.followmobj
		
		if m_peel.outs
			for i = -m_peel.max_outs,m_peel.max_outs
				if i == 0 then continue end
				if (i % 1) then continue end
				
				local peel = m_peel.outs[i]
				if not (peel and peel.valid) then continue end
				
				local ghost2 = P_SpawnMobjFromMobj(peel,-me.momx,-me.momy,-soap.rmomz*soap.gravflip,MT_SOAP_AFTERIMAGE)
				ghost2.target = me
				ghost2.flags2 = $|MF2_DONTDRAW
				
				ghost2.scale = me.scale
				
				ghost2.sprite = peel.sprite
				
				ghost2.frame = peel.frame
				ghost2.takis_frame = peel.frame
				ghost2.tics = -1
				ghost2.fuse = 4
				ghost2.renderflags = $|rflags|RF_PAPERSPRITE
				ghost2.blendmode = AST_ADD
				
				ghost2.angle = peel.angle
				local sine = abs(sin(FixedAngle(leveltime*FU*10)))
				ghost2.alpha = AI_MINALPHA + max(sine - AI_MINALPHA, 0)
				
				--dont copy color
				ghost2.color = rainbow
				ghost2.colorized = true
				ghost2.spritexscale,ghost2.spriteyscale = peel.spritexscale, peel.spriteyscale
				ghost2.spritexoffset,ghost2.spriteyoffset = peel.spritexoffset, peel.spriteyoffset
				
				ghost2.rollangle = peel.rollangle
				--ghost2.destscale = 0
				--ghost2.scalespeed = FixedDiv(me.scale - ghost2.destscale, ghost2.fuse*FU)
				
				--Dont draw right ontop of our takis
				ghost2.dontdrawforviewmobj = me
				ghost2.dispoffset = me.dispoffset - 1
				
				P_SetOrigin(ghost2,
					ghost2.x, ghost2.y, ghost2.z
				)
			end
		end
	end
	
	return ghost
end)

rawset(_G,"Soap_ControlDir",function(p)
	if (p.soaptable and p.soaptable.in2D)
		return (p.cmd.sidemove < 0) and ANGLE_180 or 0
	end
	return (p.cmd.angleturn << 16) + R_PointToAngle2(0, 0, p.cmd.forwardmove << 16, -p.cmd.sidemove << 16)
end)

--tatsuru
local function CheckAndCrumble(me, sec)
	local val = false
	for fof in sec.ffloors()
		if not (fof.flags & FF_EXISTS) continue end -- Does it exist?
		if not (fof.flags & FF_BUSTUP) continue end -- Is it bustable?
		
		if me.z + me.height + me.momz < fof.bottomheight continue end -- Are we too low?
		if me.z + me.momz > fof.topheight continue end -- Are we too high?
		
		EV_CrumbleChain(fof) -- Crumble
		val = true
	end
	return val
end

rawset(_G, "Soap_BreakFloors", function(p, me)
	return CheckAndCrumble(me, me.subsector.sector)
end)

--lul
rawset(_G, "Soap_DirBreak", function(p, me, angle, nomom)
	local soap = p.soaptable
	local val = false
	
	local momx = 0
	local momy = 0
	if not nomom
		momx = me.momx + P_ReturnThrustX(nil,angle,me.radius)
		momy = me.momy + P_ReturnThrustY(nil,angle,me.radius)
	end
	
	local my_mx = momx/4
	local my_my = momy/4
	for i = 1, (nomom and 1 or 4)
		local newsubsec = R_PointInSubsectorOrNil(
			me.x + my_mx*i,
			me.y + my_my*i
		)
		if not (newsubsec and newsubsec.valid) then continue end
		local newsec = newsubsec.sector
		if not (newsec and newsec.valid) then continue end
		
		for rover in newsec.ffloors()
			if not (rover.flags & FF_EXISTS) then continue end
			if not (rover.flags & FF_BUSTUP) then continue end
			
			--"equal to" checks because we want to be ABOVE the fof, not ON it
			--prevents being able to break floor bustables by just clutching
			if me.z + me.momz + me.height <= rover.bottomheight then continue end 
			if me.z + me.momz >= rover.topheight then continue end
			
			EV_CrumbleChain(rover)
			val = true
		end
	end
	return val
end)

--clairebun
rawset(_G, "Soap_ZLaunch", function(mo,thrust,relative)
	if mo.eflags&MFE_UNDERWATER
		thrust = FixedMul($,FixedDiv(117*FU,200*FU))	--lmao
	end
	P_SetObjectMomZ(mo,thrust,relative)
end)

--can @p1 damage @p2?
--P_TagDamage, P_PlayerHitsPlayer
--takis func
--no reason to rename this one lol (there is now)
rawset(_G, "Soap_CanHurtPlayer", function(p1,p2,nobs)
	if not (p1 and p1.valid)
	or not (p2 and p2.valid)
		return false
	end
	
	local allowhurt = true
	local ff = CV.FindVar("friendlyfire").value
	
	if not (nobs)
		--no griefing!
		if (TAKIS_NET
		and TAKIS_NET.inspecialstage)
		or G_IsSpecialStage(gamemap)
			return false
		end
		
		if not (p1.mo and p1.mo.valid)
			return false
		end
		if not (p2.mo and p2.mo.valid)
			return false
		end
		
		if not p1.mo.health
			return false
		end
		if not p2.mo.health
			return false
		end
		
		--non-supers can hit each other, supers can hit other supers,
		--but non-supers cant hit supers
		local superallowed = true
		if (p1.powers[pw_super])
			superallowed = true
		elseif (p2.powers[pw_super])
			superallowed = false
		end
		
		if ((p2.powers[pw_flashing])
		or (p2.powers[pw_invulnerability])
		or not superallowed)
			return false
		end
		
		if (leveltime <= CV.FindVar("hidetime").value*TR)
		and (gametyperules & GTR_STARTCOUNTDOWN)
			return false
		end
		
		if (p1.botleader == p2)
			return false
		end
		
		--battlemod parrying
		/*
		if (p2.guard and p2.guard == 1)
			return false
		end
		
		if p1.takistable
		and p1.takistable.inBattle
		and CBW_Battle.MyTeam(p1,p2)
			return false
		end
		
		if p1.takistable
		and p1.takistable.inSaxaMM
		and (p1.mm and p1.mm.role ~= MMROLE_MURDERER)
			return false
		end
		*/
	end
	
	-- In COOP/RACE, you can't hurt other players unless cv_friendlyfire is on
	if (not (ff or (gametyperules & GTR_FRIENDLYFIRE))
	and (gametyperules & (GTR_FRIENDLY|GTR_RACE)))
		allowhurt = false
	end
	
	if G_TagGametype()
		if ((p2.pflags & PF_TAGIT and not ((ff or (gametyperules & GTR_FRIENDLYFIRE))
		and p1.pflags & PF_TAGIT)))
			allowhurt = false
		end
		
		if (not (ff or (gametyperules & GTR_FRIENDLYFIRE))
		and (p2.pflags & PF_TAGIT == p1.pflags & PF_TAGIT))
			allowhurt = false
		end
	end
	
	if G_GametypeHasTeams()
		if (not (ff or gametyperules & GTR_FRIENDLYFIRE))
		and (p2.ctfteam == p1.ctfteam)
			allowhurt = false
		end
	end
	
	if P_PlayerInPain(p1)
		allowhurt = false
	end
	
	if Takis_Hook
		/*
			if true, force a hit
			if false, force no hits
			if nil, use the above checks
		*/
		local hook_event = Takis_Hook.events["CanPlayerHurtPlayer"]
		for i,v in ipairs(hook_event)
			local result = Takis_Hook.tryRunHook("CanPlayerHurtPlayer", v, p1,p2,nobs)
			if result ~= nil
				allowhurt = result
			end
		end
	end
	
	return allowhurt
end)

--clairebun
rawset(_G,"Soap_ZCollide", function(mo1, mo2, extraheight)
	local mo2_momz = (extraheight) and abs(mo2.momz*4/3) or 0
	local mo1_momz = (extraheight) and abs(mo1.momz*4/3) or 0
	if mo1.z > mo2.height+mo2.z + mo1_momz + mo2_momz then return false end
	if mo2.z > mo1.height+mo1.z + mo2_momz + mo1_momz then return false end
	return true
end)

rawset(_G,"Soap_DamageSfx", function(src, power, maxpow, props)
	props = $ or {}
	local secondary = P_RandomChance(FU/2)
	
	local nosfxmobj = props.nosfx or false
	if props.ultimate ~= nil
		secondary = not props.ultimate
	end
	
	local sfx = secondary and sfx_sp_dm0 or sfx_sp_db0
	local vol = secondary and 255 or 255/3
	
	sfx = $ + ease.linear(
		min(FU, FixedDiv(power, maxpow)),
		0,
		3
	)
	
	if not (src and src.valid and src.health)
	or (src.health == 1)
	and not nosfxmobj
		local sfx_m = P_SpawnGhostMobj(src)
		sfx_m.flags2 = $|MF2_DONTDRAW
		sfx_m.fuse = 5*TR
		sfx_m.tics = sfx_m.fuse
		src = sfx_m
	end
	S_StartSoundAtVolume(src, sfx, vol)
	S_StartSound(src, sfx_sp_kil)
	S_StartSound(src, sfx_sp_smk)
end)

--@src is the source of the vfx, not of the damage (thats @inf)
rawset(_G,"Soap_ImpactVFX",function(src,inf, distmul)
	/*
	if (SpawnBam ~= nil)
		SpawnBam(src,true)
		return
	end
	*/
	
	local disp = 25
	local off = {
		x = P_RandomFixedRange(-disp,disp),
		y = P_RandomFixedRange(-disp,disp),
		z = P_RandomFixedRange(-disp,disp)
	}
	
	local spr_scale = FU*3/4 + P_RandomFixedSigned() / 4
	local tntstate = S_TNTBARREL_EXPL3
	local rflags = RF_PAPERSPRITE|RF_FULLBRIGHT|RF_NOCOLORMAPS
	local applycolor = (multiplayer or netgame)
	
	if distmul ~= nil
		off.x = FixedMul($, distmul)
		off.y = FixedMul($, distmul)
		off.z = FixedMul($, distmul)
		spr_scale = FixedMul($, FU + (distmul - FU)/6)
	end
	
	for i = -1,1
		local adjust = 0
		local angle = (i == 1) and ANGLE_90 or 0
		
		if (i == 0)
			--50% of sprite's height - y offset
			adjust = FixedMul(34*FU, spr_scale) + off.z
			angle = 0
		end
		
		local bam = P_SpawnMobjFromMobj(src, off.x,off.y,
			adjust + off.z,
			MT_THOK
		)
		P_SetMobjStateNF(bam, tntstate)
		bam.spritexscale = FixedMul($, spr_scale)
		bam.spriteyscale = bam.spritexscale
		bam.renderflags = $|rflags
		bam.angle = angle
		if inf and inf.valid
		and applycolor
			bam.color = inf.color
			if (bam.color ~= nil and bam.color ~= SKINCOLOR_NONE)
				bam.colorized = true
			end
		end
		
		if i == 0
			bam.spriteyoffset = -34*FU
			bam.renderflags = $|RF_FLOORSPRITE|RF_NOSPLATBILLBOARD
			P_SetOrigin(bam, bam.x,bam.y,
				src.z + FixedMul(34*src.scale, spr_scale) + off.z
			)
		end
		
	end
end)

rawset(_G,"Soap_CanDamageEnemy",function(p, mobj,flags,exclude)
	if (CanFlingThing ~= nil)
		return CanFlingThing(p, mobj,flags,false,exclude)
	end
	
	local flingable = false
	flags = $ or MF_ENEMY|MF_BOSS|MF_MONITOR|MF_SHOOTABLE
	exclude = $ or 0
	
	if not (mobj and mobj.valid) then return false end
	
	if (mobj.flags2 & MF2_FRET)
		return false
	end
	
	if mobj.flags & (flags)
		flingable = true
	end
	
	if mobj.takis_flingme ~= nil
		if mobj.takis_flingme == true
			flingable = true
		elseif mobj.takis_flingme == false
			flingable = false
		end
	end
	
	if (mobj.flags & MF_SHOOTABLE and flags & MF_SHOOTABLE)
		if mobj.flags2 & MF2_INVERTAIMABLE
			flingable = not $
		end
	end
	
	if mobj.flags & (exclude)
		flingable = false
	end
	
	--use CanPlayerHurtPlayer instead
	if (mobj.player and mobj.player.valid) then flingable = false end
	
	if (mobj.type == MT_EGGMAN_BOX or mobj.type == MT_EGGMAN_GOLDBOX) then flingable = false end

	/*
		if true, force a hit
		if false, force no hits
		if nil, use the above checks
	*/
	local hook_event = Takis_Hook.events["CanFlingThing"]
	for i,v in ipairs(hook_event)
		if hook_event.typefor ~= nil
			if hook_event.typefor(mobj, v.typedef) == false then continue end
		end
		
		local result = Takis_Hook.tryRunHook("CanFlingThing", v, mobj, p,flags,false,exclude)
		if result ~= nil
			flingable = result
		end
	end
	
	return flingable
end)

-- P_DustRing translated to lua
rawset(_G,"Soap_DustRing",function(src,
	type,
	amount,
	pos,
	radius, speed,
	initscale, scale,
	threeaxis, --TODO
	callback
)
	radius = $ or 0
	speed = $ or 0
	initscale = $ or FU/2
	scale = $ or FU
	
	local flip = P_MobjFlip(src) == -1
	if flip
		pos[3] = $ + src.height
	end
	
	local ang = FixedDiv(360*FU, amount*FU)
	
	for i = 0, amount
		local fa = FixedAngle(ang * i)
		local dust = P_SpawnMobj(
			pos[1] + P_ReturnThrustX(nil, fa, radius),
			pos[2] + P_ReturnThrustY(nil, fa, radius),
			pos[3],
			type
		)
		if not (dust and dust.valid) then continue end
		
		dust.angle = fa + ANGLE_90
		P_SetScale(dust, FixedMul(initscale, scale), true)
		dust.destscale = FixedMul(4*FU + P_RandomFixed(), scale)
		dust.scalespeed = scale / 24
		P_Thrust(dust, fa, speed + FixedMul(P_RandomFixed(), scale))
		dust.momz = P_SignedRandom() * scale / 64
		
		if flip
			dust.z = $ - dust.height
			dust.flags2 = $|MF2_OBJECTFLIP
		end
		
		--remove interp
		P_SetOrigin(dust, dust.x,dust.y,dust.z)
		--Sure
		dust.alpha = src.alpha
		
		if callback ~= nil
			callback(dust)
		end
	end
end)

--returns whether the things was jostled or not. Soap.
rawset(_G,"Soap_JostleThings",function(me, found, range)
	if not (found and found.valid) then return end
	if (found == me) then return end
	if not (found.health) then return end
	if not P_IsObjectOnGround(found) then return end
	if (me.player.powers[pw_carry] and found == me.tracer) then return end
	
	local dx = found.x - me.x
	local dy = found.y - me.y
	local dz = found.z - me.z
	local dist = FixedHypot(FixedHypot(dx,dy),dz) - (found.radius + found.height)
	
	if (dist > range) then return end
	
	if Soap_CanDamageEnemy(me.player, found,nil,MF_MONITOR)
		Soap_Hitlag.stunEnemy(found, TR*3/2 + (range/FU)/25)
	end
	
	local tumbled = false
	local nobounce = false --bruh
	if found.player and me.player.soaptable.inBattle
		local p = me.player
		local p2 = found.player
		
		me.player.soaptable.bm.damaging = true
		if Soap_CanHurtPlayer(p,p2, true)
		and not (p2.tumble)
		--???
		and (p2.mo and p2.mo.valid)
		and (p2.guard == 0)
			local tics = TR * 13/10
			
			CBW_Battle.DoPlayerTumble(p2,tics,
				R_PointToAngle2(found.x,found.y,
					me.x,me.y
				), 0
			)
			Soap_ZLaunch(p2.mo, 10*me.scale)
			tumbled = true
			nobounce = true
		end
	--probably an enemy, func returns nil if it is nograv anyway
	else
		tumbled = true
	end
	
	if (found.flags & MF_NOGRAVITY) then return end
	if not nobounce
		--dont crush us
		if (found.flags & MF_MONITOR) then range = $ / 2 end
		Soap_ZLaunch(found, abs(range / 16) * P_MobjFlip(me))
	end
	return tumbled
end)

rawset(_G, "Soap_WindLines", function(me,rmomz,color,forceang)
	if not (me and me.valid) then return end --?
	if not me.health then return end
	
	local p = me.player
	
	if (p and p.valid)
	and (p.powers[pw_carry] == CR_ROLLOUT
	or p.powers[pw_carry] == CR_PLAYER)
		Soap_WindLines(me.tracer,p.soaptable.rmomz,color,forceang)
	end
	
	local momz = rmomz
	if momz == nil
		momz = me.momz
		if (p and p.valid)
			momz = p.soaptable.rmomz
		end
    end
	
	local offx,offy = 0,0
	if R_PointToDist2(0,0,me.momx,me.momy) > me.radius*2
		local timesx = FixedDiv(me.momx,me.radius*2)
		local timesy = FixedDiv(me.momy,me.radius*2)
		
		if timesx ~= 0
			offx = FixedDiv(me.momx,timesx) * P_RandomRange(0,timesx/me.scale)
		end
		if timesy ~= 0
			offy = FixedDiv(me.momy,timesy) * P_RandomRange(0,timesy/me.scale)
		end
	end
	
	local wind = P_SpawnMobj(
		me.x + P_RandomRange(-36,36)*me.scale + offx,
		me.y + P_RandomRange(-36,36)*me.scale + offy,
		me.z + (me.height/2) + P_RandomRange(-20,20)*me.scale + momz,
		MT_SOAP_SPEEDLINE
	)
	--wind.state = S_TAKIS_WINDLINE
	wind.scale = me.scale
	if forceang == nil
		local angle = (me.player and me.player.drawangle or me.angle)
		if FixedHypot(me.momx,me.momy) > me.scale
			angle = R_PointToAngle2(0,0,me.momx,me.momy)
		end
		wind.angle = angle
	else
		wind.angle = forceang
	end
	/*
	wind.momx = me.momx*3/4
	wind.momy = me.momy*3/4
	wind.momz = momz*3/4
	*/
	
	local mocolor = color
	if mocolor == nil
	and color == nil
		mocolor = SKINCOLOR_SAPPHIRE
	end
	wind.color = mocolor
	wind.rollangle = R_PointToAngle2(0, 0, R_PointToDist2(0,0,me.momx,me.momy), momz)
    
	wind.source = me
	
	return wind
end)

rawset(_G,"Soap_MomentumAngle",function(mo,fallback,Amomx,Amomy)
	if not (mo and mo.valid) then return end
	
	local momx,momy = (Amomx ~= nil) and Amomx or mo.momx, (Amomy ~= nil) and Amomy or mo.momy
	if (mo.player and mo.player.soaptable.isSliding)
		momx = mo.x - mo.player.soaptable.last.x
		momy = mo.y - mo.player.soaptable.last.y
	end
	momx,momy = FixedDiv($1, mo.scale), FixedDiv($2, mo.scale)
	
	if (momx/FU ~= 0 or momy/FU ~= 0)
		if (mo.player and mo.player.valid)
		and (Amomx == nil or Amomy == nil)
			momx,momy = $1 - FixedDiv(mo.player.cmomx,mo.scale), $2 - FixedDiv(mo.player.cmomy,mo.scale)
		end
		return R_PointToAngle2(0,0,momx,momy)
	else
		return (fallback ~= nil and fallback or ((mo.player and mo.player.valid) and mo.player.drawangle or mo.angle))
	end
end)

rawset(_G,"Soap_CheckFloorPic",function(me, checkgrounded)
	if checkgrounded and not P_IsObjectOnGround(me) then return ""; end
	
	local flip = me.eflags & MFE_VERTICALFLIP
	local floorpic = me.subsector.sector.floorpic
	if flip
		floorpic = me.subsector.sector.ceilingpic
	end
	
	for rover in me.subsector.sector.ffloors()
		if (rover.flags & FOF_BLOCKPLAYER) == 0 then continue end
		if (rover.flags & FF_EXISTS) == 0 then continue end
		
		local topheight = rover.topheight
		local bottomheight = rover.bottomheight
		if (rover.t_slope and rover.t_slope.valid)
			topheight = P_GetZAt(rover.t_slope, me.x,me.y)
		end
		if (rover.b_slope and rover.b_slope.valid)
			bottomheight = P_GetZAt(rover.b_slope, me.x,me.y)
		end
		
		-- over/under
		--TODO: checkgrounded works for both gravstates
		if (me.z > topheight and checkgrounded)
		or me.z + me.height < bottomheight -- FU
			continue
		end
		
		floorpic = flip and rover.bottompic or rover.toppic
	end
	return floorpic
end)

--destroys all vfx when they dont apply
rawset(_G,"Soap_FXDestruct",function(p)
	local me = p.mo
	local soap = p.soaptable

	--remove fx
	if me.skin ~= "takisthefox"
		if (soap.fx.waterrun_L and soap.fx.waterrun_L.valid)
			P_RemoveMobj(soap.fx.waterrun_L)
			soap.fx.waterrun_L = nil
		end
		if (soap.fx.waterrun_R and soap.fx.waterrun_R.valid)
			P_RemoveMobj(soap.fx.waterrun_R)
			soap.fx.waterrun_R = nil
		end
	end
	
	if (soap.fx.uppercut_aura and soap.fx.uppercut_aura.valid)
		P_RemoveMobj(soap.fx.uppercut_aura)
		soap.fx.uppercut_aura = nil
	end
	if (soap.fx.pound_aura and soap.fx.pound_aura.valid)
		P_RemoveMobj(soap.fx.pound_aura)
		soap.fx.pound_aura = nil
	end
	if (soap.fx.dash_aura and soap.fx.dash_aura.valid)
		P_RemoveMobj(soap.fx.dash_aura)
		soap.fx.dash_aura = nil
	end
end)

local function format_easestruct(input)
	return input ~= nil and {
		ease_func	= input.ease_func,
		timetake	= abs(input.time),
		start_v		= input.start_v,
		end_v		= input.end_v,
		back_v		= input.back_v,
		
		tics		= 0,
	} or nil
end

--@ease_func: string, ease["ease_func"] should return a valid func
/* format of x/y:
	{
		ease_func,
		time,
		start_v, end_v, [back_v],
		[name]
	}
*/
rawset(_G,"Soap_AddSquash",function(p, x,y, name)
	local output = {
		x = format_easestruct(x),
		y = format_easestruct(y),
		name = name,
	}
	
	table.insert(p.soaptable.squash, output)
	return output
end)

rawset(_G,"Soap_GetSquash",function(p, name)
	for k,v in ipairs(p.soaptable.squash)
		if v.name == name
			return v
		end
	end
	return false
end)

rawset(_G,"Soap_RemoveSquash",function(p, name)
	for k,v in ipairs(p.soaptable.squash)
		if v.name == name
			table.remove(p.soaptable.squash, k)
			return true
		end
	end
	return false
end)

rawset(_G, "Soap_TickSquashes",function(p,me,soap, donttick)
	local squash_count = #soap.squash
	local xscale = soap.spritexscale
	local yscale = soap.spriteyscale
	
	if squash_count
		
		for k,squash in ipairs(soap.squash)
			local has_any_tics = false
			if (squash.x and squash.x.tics < squash.x.timetake)
			or (squash.y and squash.y.tics < squash.y.timetake)
				has_any_tics = true
			end
			
			if not has_any_tics
			and not donttick
				table.remove(soap.squash,k); continue
			end
			
			if squash.x --and squash.x.tics ~= squash.x.timetake
				local func = ease[squash.x.ease_func]
				xscale = $ + func(
					(FU / squash.x.timetake) * squash.x.tics,
					squash.x.start_v,
					squash.x.end_v,
					squash.x.back
				)
				if not donttick
					squash.x.tics = min($ + 1, squash.x.timetake)
				end
			end
			
			if squash.y
				local func = ease[squash.y.ease_func]
				yscale = $ + func(
					(FU / squash.y.timetake) * squash.y.tics,
					squash.y.start_v,
					squash.y.end_v,
					squash.y.back
				)
				if not donttick
					squash.y.tics = min($ + 1, squash.y.timetake)
				end
			end
		end
		
		soap.last.squash_head = squash_count
	elseif soap.last.squash_head
		soap.last.squash_head = 0
	end
	
	me.spritexscale = max(xscale, 5)
	me.spriteyscale = max(yscale, 5)
	
	if not donttick
		if soap.afterimage
		and (me.skin == "soapthehedge" or me.skin == "takisthefox")
			Soap_CreateAfterimage(p, me)
		end
	end
	
	soap.spritexscale = FU
	soap.spriteyscale = FU
end)

--"Why not just use P_IsLocalPlayer?"
--that checks for MACHINE local player, not for
--the guy thats on your screen
rawset(_G,"Soap_IsLocalPlayer",function(p)
	return (p == displayplayer or p == secondarydisplayplayer)
end)

rawset(_G,"Soap_SpawnBumpSparks",function(me, thing, line, followme)
	local angle = R_PointToAngle2(0,0,me.momx,me.momy) + ANGLE_90
	if (line and line.valid)
		angle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)
	elseif (thing and thing.valid)
		angle = R_PointToAngle2(
			me.x, me.y,
			thing.x, thing.y
		) + ANGLE_90
	end
	
	local fa = FixedDiv(360*FU, 8*FU)
	local random = P_RandomFixedRange(0,73)
	local speed = 6*me.scale
	local limit = 28
	for i = 1,8
		local my_ang = FixedAngle((fa * i) + random)
		
		local spark = P_SpawnMobjFromMobj(me, 0, 0,
			FixedDiv((41*me.height)/48, me.scale),
			MT_SOAP_WALLBUMP
		)
		P_InstaThrust(spark, angle, FixedMul(cos(my_ang), speed))
		spark.momz = FixedMul(sin(my_ang), speed)
		
		P_SetScale(spark,me.scale / 10, true)
		spark.destscale = me.scale
		--5 tics
		spark.scalespeed = FixedDiv(me.scale - me.scale / 10, 5*FU)
		
		--spark.mirrored = P_RandomChance(FU/2)
		spark.fuse = TR*3/4
		
		spark.random = P_RandomRange(-limit,limit) * ANG1
		if followme
			spark.target = me
			spark.momx = $ + me.momx * 3/4
			spark.momy = $ + me.momy * 3/4
		end
	end
end)

--spinning top stuff is separated to make it easier to use in other cases
local function top_hitenemy(me,thing)
	Soap_ImpactVFX(thing,me)
	Soap_SpawnBumpSparks(me, thing)
	
	local nullify = false
	if (thing.player)
		local p2 = thing.player
		
		if (p2.guard ~= nil)
		and (p2.guard)
			nullify = true
		end
		if (p2.airdodge ~= nil
		and p2.airdodge > 0)
			nullify = true
		end
	end
	
	local sfx = P_SpawnGhostMobj(thing)
	sfx.flags = $|MF2_DONTDRAW
	sfx.fuse = 2*TR
	sfx.tics = sfx.fuse
	S_StartSound(sfx, sfx_sp_top)
	Soap_DamageSfx(thing, FU*3/4,FU)
	
	local hitlag_tics = 12
	if not nullify
		P_StartQuake(15*FU, hitlag_tics,
			{me.x, me.y, me.z},
			512*me.scale
		)
		
		P_InstaThrust(thing,
			R_PointToAngle2(thing.x,thing.y, me.x,me.y),
			20*me.scale
		)
		if (thing.player)
			P_MovePlayer(thing.player)
		end
		if not P_IsObjectOnGround(thing)
			P_SetObjectMomZ(me,4*FU,true)
		end
		P_DamageMobj(thing, me,me)
		
		Soap_Hitlag.addHitlag(me, 3, false)
	elseif (thing.player and thing.player.valid)
	and (thing.player.guard ~= nil)
	and (thing.player.guard)
		--allow parries
		P_DamageMobj(thing, me,me)
	end
	
	if (thing and thing.valid)
	and (thing.health)
	and not (thing.flags & MF_MONITOR)
	and not nullify
		Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
		thing.momz = me.momz
		thing.z = $ + me.momz
	end
	return not nullify
end

--SpinningTop
rawset(_G,"SoapST_Hitbox",function(p)
	local me = p.mo
	local soap = p.soaptable
	
	local fakerange = 128*FU
	local range = 64*me.scale
	
	--lets do the fx here too why not
	local angle = me.angle - FixedAngle(soap.topspin) + ANGLE_90
	local height = FixedDiv(me.height,me.scale)/FU
	for i = -1, 1, 2
		local offsetx = P_ReturnThrustX(nil,angle, FixedDiv(range,me.scale)* i)
		local offsety = P_ReturnThrustY(nil,angle, FixedDiv(range,me.scale) * i)
		local offsetz = P_RandomFixedRange(height/4,height)
		local wind = P_SpawnMobjFromMobj(me,
			offsetx,
			offsety,
			offsetz,
			MT_SOAP_SPEEDLINE
		)
		wind.source = me
		wind.angle = angle + ANGLE_90
		wind.color = p.skincolor
		wind.spritexscale = 2*FU
		wind.spriteyscale = FU * 8/10
		wind.rollangle = -ANG20
		wind.blendmode = AST_ADD
		wind.topwind = true
		wind.dontdrawforviewmobj = me
		wind.offsetz = FixedMul(offsetz,me.scale)
		wind.offset = range * i
		wind.movedir = angle
		
		if (p.powers[pw_super] or soap.isSolForm)
			local b = spawnbubble(p,me,soap)
			P_SetOrigin(b,
				me.x + offsetx,
				me.y + offsety,
				me.z + offsetz
			)
		end
	end
	
	searchBlockmap("objects", function(ref, found)
		if found == me then return end
		if not (found.health) then return end
		if not P_CheckSight(me,found) then return end
		if (found.flags & (MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING)) then return end
		if (found.player and found.player.airdodge ~= nil and found.player.airdodge > 0) then return end
		if (found.player and found.player.intangible) then return end
		
		local this_range = (found.flags & MF_MISSILE) and (range + 16*found.scale) or range
		if abs(me.x - found.x) > this_range + found.radius
		or abs(me.y - found.y) > this_range + found.radius
			return
		end
		if not Soap_ZCollide(me,found) then return end
		
		--weak to missiles
		if (found.flags & MF_MISSILE)
			--Toomble!
			if soap.inBattle
				CBW_Battle.DoPlayerTumble(p, 45,
					R_PointToAngle2(me.x,me.y,
						found.x,found.y
					), 3*found.scale,
					true, true
				)
				p.tumble_nostunbreak = true
				p.airdodge_spin = 0
				soap.toptics = 0
			else
				local owner = found.tracer
				if not (owner and owner.valid)
					owner = target
				end
				P_DamageMobj(me, found, owner)
				soap.toptics = 0
			end
		end
		
		local hit = false
		if (found.type == MT_TNTBARREL)
		or Soap_CanDamageEnemy(p, found,MF_ENEMY|MF_BOSS|MF_MONITOR|MF_SHOOTABLE)
			top_hitenemy(me,found)
			hit = true
		elseif (found.player and found.player.valid)
			if Soap_CanHurtPlayer(p,found.player,true)
				--2,2 priority
				if soap.inBattle
				and not (found.player.guard > 0)
					local apri = p.battle_atk
					local dpri = p.battle_def
					if dpri > 2
						return
					--Clash!
					elseif dpri == 2
						P_Thrust(me,
							R_PointToAngle2(found.x,found.y, me.x,me.y),
							20*found.scale + R_PointToDist2(0,0,found.momx,found.momy)
						)
						P_Thrust(found,
							R_PointToAngle2(me.x,me.y, found.x,found.y),
							20*me.scale + R_PointToDist2(0,0,me.momx,me.momy)
						)
						soap.linebump = max($,12)
						if (skins[found.player.skin].name == "soapthehedge")
							found.player.soaptable.linebump = max($, 12)
						end
						
						Soap_Hitlag.addHitlag(me, 12, false)
						Soap_Hitlag.addHitlag(found, 12, false)
						Soap_SpawnBumpSparks(me, found)
						
						S_StartSound(me,sfx_cdpcm9)
						S_StartSound(me,sfx_s259)
						for i = 0,1
							local me = (i and found or me)
							local sb = P_SpawnMobjFromMobj(me,0,0,0,MT_STUNBREAK)
							sb.scale = me.scale * 4/3
							sb.destscale = me.scale * 3
							sb.momz = me.momz * 3/4
							local sh = P_SpawnMobjFromMobj(me,0,0,0,MT_BATTLESHIELD)
							sh.target = me
						end
						return
					end
				end
				
				if top_hitenemy(me,found)
					found.state = S_PLAY_PAIN
				end
				hit = true
			end
		end
		
		if hit
			soap.toptics = max($ - 3, 0)
		end
	end, 
	me,
	me.x-fakerange, me.x+fakerange,
	me.y-fakerange, me.y+fakerange)
end)

rawset(_G,"SoapST_Start",function(p)
	local me = p.mo
	local soap = p.soaptable
	
	if soap.toptics then return end
	if not (me.health) then return end
	if (soap.noability & SNOABIL_TOP) then return end
	
	soap.topwindup = 13
	soap.toptics = TR
	
	S_StartSound(me, sfx_sp_tch)
end)

local cv_hidetime = CV.FindVar("hidetime")
rawset(_G,"Soap_HandleNoAbils", function(p)
	local soap = p.soaptable
	local me = p.realmo
	local na = 0
	
	if not (me and me.valid) then return end
	
	if (p.gotflag)
	or (p.gotcrystal)
		na = $|SNOABIL_UPPERCUT|SNOABIL_AIRDASH|SNOABIL_POUND
	end
	
	local hiding = false
	if (gametyperules & GTR_STARTCOUNTDOWN)
		if leveltime <= cv_hidetime.value*TR
			hiding = true
			if (gametyperules & (GTR_BLINDFOLDED|GTR_TAG))
				if not (p.pflags & PF_TAGIT)
					hiding = false
				end
			end
		else
			if (gametyperules & GTR_HIDEFROZEN)
			and not (p.pflags & PF_TAGIT)
				hiding = true
			end
		end
	end
	
	if (p.exiting)
	or (p.inkart)
	or hiding or ((gametyperules & GTR_RACE) and p.realtime == 0)
	or soap.toptics
		na = $|SNOABIL_ALL
		if (p.exiting)
		or (hiding or ((gametyperules & GTR_RACE) and p.realtime == 0))
			na = $ &~SNOABIL_BOTHTAUNTS
		end
	end
	
	if (soap.isSliding)
		na = $|SNOABIL_CROUCH|SNOABIL_RDASH|SNOABIL_AIRDASH|SNOABIL_POUND
	end
	if p.powers[pw_carry] == CR_ROPEHANG
		na = $|SNOABIL_AIRDASH|SNOABIL_UPPERCUT	
	end
	
	if soap.taunttime
		na = $|SNOABIL_CROUCH|SNOABIL_TOP
	end
	
	if (soap.slipping)
		na = $|SNOABIL_BOTHTAUNTS
	end
	
	--battle special cases
	if soap.inBattle
		local noaction = false
		if p.powers[pw_nocontrol]
		or p.powers[pw_carry]
		or (p.airdodge > 0)
		or (CBW_Battle.Exiting or CBW_Battle.Timeout)
		or (p.isjettysyn)
			noaction = true
		end
		
		if (p.tumble)
		or P_PlayerInPain(p)
		--or not CBW_Battle.CanDoAction(p)
		or noaction
			na = $|SNOABIL_ALL
			if (CBW_Battle.Exiting or CBW_Battle.Timeout)
				na = $ &~(SNOABIL_BOTHTAUNTS)
			end
		end
	end
	
	--Gametypes
	if (MM and MM:isMM())
	or gametype == GT_ZE2
		local debugmode = false
		if (MM and MM:isMM())
			if CV_MM.debug.value
				debugmode = true
			end
		elseif gametype == GT_ZE2
			if ZE2.cv_debug.value
				debugmode = true
			end
		end
		
		if not debugmode
			na = $|SNOABIL_TAUNTSONLY|SNOABIL_BREAKDANCE
		end
		if gametype == GT_ZE2
			if ZE2.game_ended
				na = $ &~SNOABIL_BREAKDANCE
			end
		end
	end
	
	if (me.state >= S_PLAY_SUPER_TRANS1)
	and (me.state <= S_PLAY_SUPER_TRANS6)
	or (me.punchtarget and me.punchtarget.valid)
	or (me.punchsource and me.punchsource.valid)
		na = $|SNOABIL_ALL
	end
	
	if (PSO)
		na = $|SNOABIL_ALL &~SNOABIL_BOTHTAUNTS
	end
	
	--return value: new noabilities field (absolute)
	local hook_event = Takis_Hook.events["Soap_NoAbility"]
	for i,v in ipairs(hook_event)
		local new_noabil = Takis_Hook.tryRunHook("Soap_NoAbility", v, p, na)
		if new_noabil ~= nil
		and type(new_noabil) == "number"
			na = abs(new_noabil)
		end
	end
	
	soap.noability = $|na
end)

local soap_airfric = tofixed("0.96")
rawset(_G,"Soap_DeathThinker",function(p,me,soap)
	if p.playerstate ~= PST_DEAD
		if (soap.firepain)
			local rad = FixedDiv(me.radius,me.scale)/FU
			local hei = FixedDiv(me.height,me.scale)/FU
			local dosmoke = soap.firepain <= TR
			
			if not dosmoke
				local flame = P_SpawnMobjFromMobj(me,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(0,hei)*FU,
					MT_FLAMEPARTICLE
				)
				P_SetObjectMomZ(flame,P_RandomRange(2,4)*me.scale+P_RandomFixed())
				flame.colorized = true
				flame.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
				flame.frame = $|FF_FULLBRIGHT
				flame.blendmode = AST_ADD
				flame.scale = $ + P_RandomRange(0,FU/2)
			end
			do
				local smoke = P_SpawnMobjFromMobj(me,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(0,hei)*FU,
					MT_SMOKE
				)
				P_SetObjectMomZ(smoke,P_RandomRange(1,2)*me.scale+P_RandomFixed())
				smoke.scale = $ + P_RandomRange(0,FU/2)
			end
			
			if not S_SoundPlaying(me, sfx_s3kc2s)
			and not dosmoke
				S_StartSound(me, sfx_s3kc2s)
			end
			soap.firepain = $ - 1
		end
		
		if (soap.elecpain)
			local rad = FixedDiv(me.radius,me.scale)/FU
			local hei = FixedDiv(me.height,me.scale)/FU
			for i = 0,1
				local spark = P_SpawnMobjFromMobj(me,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(0,hei)*FU,
					MT_WATERZAP
				)
				spark.color = P_RandomRange(SKINCOLOR_TANGERINE, SKINCOLOR_YELLOW)
				spark.colorized = true
				spark.angle = R_PointToAngle2(spark.x,spark.y, me.x, me.y) + ANGLE_90
				spark.renderflags = $|RF_PAPERSPRITE|RF_NOCOLORMAPS
				spark.frame = $|FF_FULLBRIGHT|FF_ADD
				spark.scale = $ + P_RandomRange(0,FU * 9/10)
			end
			
			soap.elecpain = $ - 1
		end
		
		return
	end
	soap.firepain = 0
	soap.elecpain = 0
	
	if me.soap_deadtimer == nil
		me.soap_deadtimer = 0
		me.soap_landondeath = true
	end
	
	soap.uppercutted = false
	soap.airdashed = false
	soap.rdashing = false
	soap.pounding = false
	
	if ((CBW_Battle
	and (CBW_Battle.Exiting or CBW_Battle.Timeout))
	or (me.soap_knockout))
	and not me.health
	--and (me.soap_deadtimer <= TR/3)
		if me.sprite2 ~= SPR2_MSC2
		and not (soap.onGround and me.soap_deadtimer > 3)
			me.state = S_PLAY_DEAD
			me.frame = A|($ &~FF_FRAMEMASK)
			me.sprite2 = SPR2_MSC2
			me.tics = -1
			me.soap_landondeath = true
			if me.soap_deadtimer < 3
				S_StartSound(me,sfx_sp_oww)
				S_StartSound(me,sfx_sp_kco)
			end
			
			--Bruh
			if me.soap_knockout_speed ~= nil
				me.momx,me.momy,me.momz = unpack(me.soap_knockout_speed)
				me.soap_knockout_speed = nil
			--cheesy
			elseif (me.soap_inf and me.soap_inf.valid)
				local inf = me.soap_inf
				P_Thrust(me,
					R_PointToAngle2(inf.x,inf.y, me.x,me.y),
					R_PointToDist2(0,0, inf.momx,inf.momy) + 6*inf.scale
				)
				me.angle = R_PointToAngle2(me.x,me.y, inf.x,inf.y)
				p.drawangle = me.angle
				--no seenames
				me.angle = $ + ANGLE_45
			end
		end
		if me.sprite2 == SPR2_MSC2
			local sweat = P_SpawnMobjFromMobj(me,
				P_RandomRange(-16,16)*FU,
				P_RandomRange(-16,16)*FU,
				P_RandomRange(0, FixedDiv(me.height,me.scale)/FU)*FU,
				MT_SPINDUST
			)
			sweat.spritexscale = $ + P_RandomFixedRange(0,1)/4
			sweat.spriteyscale = sweat.spritexscale
			
			if (me.soap_inf and me.soap_inf.valid)
			and me.soap_inf.color ~= SKINCOLOR_NONE
				sweat.color = me.soap_inf.color
				sweat.colorized = true
			end
			
			sweat.destscale = 1
			sweat.scalespeed = FixedDiv($, sweat.scale)
			P_SetObjectMomZ(sweat, FU*4)
			
			if (me.momz*soap.gravflip < 0)
			and soap.accspeed > FU
			or (P_IsObjectOnGround(me) and soap.accspeed > 2*FU)
				/*
				me.rollangle = R_PointToAngle2(0, 0,
					R_PointToDist2(0,0,me.momx,me.momy), me.momz/3
				)
				*/
				me.momx = FixedMul($, soap_airfric)
				me.momy = FixedMul($, soap_airfric)
			end
		end
	end
	
	--death anims
	local dmg = soap.deathtype
	if P_CheckDeathPitCollide(me)
	and soap.deathtype ~= DMG_DEATHPIT
		soap.deathtype = DMG_DEATHPIT
		dmg = soap.deathtype
		--reset
		me.soap_deadtimer = 0
	end
	
	if soap.allowdeathanims
		if dmg == DMG_DEATHPIT
			if not me.soap_deadtimer
				--cartoony effect where SOAP (bye bye takis) drops with a
				--smoke cloud in his shape
				local ghs = P_SpawnGhostMobj(me)
				ghs.tics = -1
				ghs.sprite = soap.last.anim.sprite
				ghs.sprite2 = soap.last.anim.sprite2
				ghs.frame = soap.last.anim.frame
				ghs.angle = soap.last.anim.angle
				ghs.colorized = true
				ghs.fuse = 23
				ghs.color = SKINCOLOR_WHITE
				
				local speed = 5*me.scale
				for i = 0,P_RandomRange(20,29)
					local poof = P_SpawnMobjFromMobj(me,
						P_RandomFixedRange(-15,15),
						P_RandomFixedRange(-15,15),
						FixedDiv(me.height,me.scale)/2 + P_RandomFixedRange(-15,15),
						MT_THOK
					)
					poof.state = mobjinfo[MT_SPINDUST].spawnstate
					local hang,vang = R_PointTo3DAngles(
						poof.x,poof.y,poof.z,
						me.x,me.y,me.z + me.height/2
					)
					P_3DThrust(poof, hang,vang, speed)
					
					poof.spritexscale = $ + P_RandomFixedRange(0,2)/3
					poof.spriteyscale = poof.spritexscale
				end
				S_StartSound(me,sfx_s3k51)
				
				--shoes
				local angle = soap.last.anim.angle
				local radius = FixedDiv(me.radius, me.scale)
				for i = -1,1,2
					local adjust = ANGLE_90*i
					local shoe = P_SpawnMobjFromMobj(me,
						P_ReturnThrustX(nil,angle + adjust, radius),
						P_ReturnThrustY(nil,angle + adjust, radius),
						FixedDiv(me.height, me.scale)/2,
						MT_SOAP_WALLBUMP
					)
					shoe.skin = me.skin
					shoe.state = S_INVISIBLE
					shoe.sprite = SPR_PLAY
					shoe.sprite2 = SPR2_MSC3
					shoe.angle = angle + adjust
					P_SetObjectMomZ(shoe, P_RandomFixedRange(14,20))
					P_Thrust(shoe, angle + adjust, 1*me.scale)
					shoe.random = P_RandomRange(-28,28) * ANG1
					shoe.fuse = 5*TR
					
					shoe.mirrored = (i == 1 and true or false)
					shoe.shoemode = true
				end
				
				local momz = soap.last.momz
				if momz < -30*me.scale*soap.gravflip
					momz = -30*me.scale*soap.gravflip
				end
				me.momz = momz
				me.state = S_PLAY_DEAD
			end
			me.momx,me.momy = 0,0
			me.soap_landondeath = false
		end
		
		--SPR2_FLY_ is crushed sprite
		if dmg == DMG_CRUSHED
			if me.soap_deadtimer == 1
				S_StartSound(me,sfx_sp_spt)
				Soap_DustRing(me,
					dust_type(me),
					P_RandomRange(8,14),
					{me.x,me.y,me.z},
					32*me.scale,
					me.scale*5,
					me.scale,
					me.scale/2,
					false, dust_noviewmobj
				)
				if soap.onGround
					Soap_ZLaunch(me,15*FU)
				end
				p.deadtimer = $ - TR/2
			end
			
			me.spritexscale,me.spriteyscale = FU,FU
			me.shadowscale = 0
			me.rollangle = 0
			me.fuse = -1
			if not (me.flags & MF_NOGRAVITY)
				local flip = soap.gravflip
				me.momz = FixedMul($, FU*60/63)
				local maxfall = -FixedMul(FU/2, me.scale)
				if flip*me.momz < maxfall
					me.momz = flip*FixedMul(flip*$, FU*60/63)
					if flip*me.momz > maxfall
						me.momz = flip*maxfall
						me.flags = $ | MF_NOGRAVITY
					end
				end
			end
			
			me.frame = A
			me.sprite2 = SPR2_FLY_
			me.frame = A
			me.height = 0
			me.flags = $ &~MF_NOCLIPHEIGHT
			me.renderflags = RF_FLOORSPRITE|RF_NOSPLATBILLBOARD|RF_OBJECTSLOPESPLAT|RF_SLOPESPLAT
			if (me.standingslope)
				P_CreateFloorSpriteSlope(me)
			else
				P_RemoveFloorSpriteSlope(me)
			end
			me.pitch,me.roll = 0,0
			me.soap_landondeath = false
		end
		
		if dmg == DMG_FIRE
			if (me.soap_deadtimer <= 3)
				me.momz = 0
				if me.soap_deadtimer == 1
					S_StartSound(me, sfx_s233)
				end
			end
			me.soap_landondeath = false
			me.flags = $ &~MF_NOCLIPHEIGHT
			
			if (me.soap_deadtimer <= 20)
				local rad = FixedDiv(me.radius,me.scale)/FU
				local hei = FixedDiv(me.height,me.scale)/FU
				
				local smoke = P_SpawnMobjFromMobj(me,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(0,hei)*FU,
					MT_SMOKE
				)
				P_SetObjectMomZ(smoke,P_RandomRange(2,4)*me.scale+P_RandomFixed())
				smoke.scale = $ + P_RandomRange(0,FU/3)
				me.alpha = (FU/20) * me.soap_deadtimer
			else
				if me.soap_deadtimer == 21
					local speed = 5*me.scale
					for i = 0,P_RandomRange(20,29)
						local poof = P_SpawnMobjFromMobj(me,
							P_RandomFixedRange(-15,15),
							P_RandomFixedRange(-15,15),
							FixedDiv(me.height,me.scale)/2 + P_RandomFixedRange(-15,15),
							MT_SMOKE
						)
						local hang,vang = R_PointTo3DAngles(
							poof.x,poof.y,poof.z,
							me.x,me.y,me.z + me.height/2
						)
						P_3DThrust(poof, hang,vang, speed)
						P_SetObjectMomZ(poof, FU)
						
						poof.spritexscale = $ + P_RandomFixedRange(0,2)/3
						poof.spriteyscale = poof.spritexscale
					end
					S_StopSound(me)
					S_StartSound(me, sfx_s3k43)
				end
				me.flags2 = $|MF2_DONTDRAW
			end
		end
		
		if dmg == DMG_DROWNED
			me.flags = $|MF_NOGRAVITY
			me.momx,me.momy,me.momz = 0,0,0
			
			if (me.soap_deadtimer == 20)
				local speed = 5 * me.scale
				for i = 0,P_RandomRange(20,25)
					local poof = P_SpawnMobjFromMobj(me,
						P_RandomFixedRange(-15,15),
						P_RandomFixedRange(-15,15),
						FixedDiv(me.height,me.scale)/2 + P_RandomFixedRange(-15,15),
						P_RandomRange(MT_SMALLBUBBLE, MT_MEDIUMBUBBLE)
					)
					poof.tics = -1
					poof.fuse = TR
					local hang,vang = R_PointTo3DAngles(
						poof.x,poof.y,poof.z,
						me.x,me.y,me.z + me.height/2
					)
					P_3DThrust(poof, hang,vang, speed)
					
					poof.spritexscale = $ + P_RandomFixedRange(0,2)/3
					poof.spriteyscale = poof.spritexscale
					poof.color = me.color
					poof.colorized = true
				end
				
				Soap_ImpactVFX(me)
				S_StartSound(me, sfx_pop)
				me.fuse = 0
				me.flags2 = $|MF2_DONTDRAW
			end
			me.soap_landondeath = false
		end
	end
	
	if me.soap_landondeath
		me.flags = $ &~MF_NOCLIPHEIGHT
		
		if soap.onGround
		and (me.soap_deadtimer > 3)
			if me.state ~= S_PLAY_SOAP_KNOCKOUT
			and (me.sprite2 ~= SPR2_CNT1) --whatever
				me.state = S_PLAY_SOAP_KNOCKOUT
				me.fuse = -1
				me.rollangle = 0
				me.spriteyoffset = 0
				
				S_StartSound(me,sfx_altdi1)
				S_StartSound(me,sfx_sp_smk)
				S_StartSound(me,sfx_s3k5d)
				
				P_StartQuake(15*FU, 10, {me.x,me.y,me.z}, 512*FU)
				Soap_DustRing(me,
					dust_type(me),
					P_RandomRange(8,14),
					{me.x,me.y,me.z},
					32*me.scale,
					me.scale*5,
					me.scale,
					me.scale/2,
					false, dust_noviewmobj
				)
				me.soap_landondeath = false
			end
		end
	end
	
	soap.accspeed = 0
	me.soap_deadtimer = $ + 1
end)

--P_MovePlayer but without moving and only animation changes
rawset(_G,"Soap_ResetState",function(p)
	local cmd = p.cmd
	local me = p.realmo
	
	if not (me and me.valid) then return end
	if P_PlayerInPain(p) then return end
	if not (me.health) then return end
	if p.tumble then return end
	
	local onground = P_IsObjectOnGround(me)
	local issuper = p.powers[pw_super]
	local soap = p.soaptable
	local accspeed = FixedMul(soap.accspeed,me.scale)
	
	local runspeed = FixedMul(p.runspeed,me.scale)
	if (issuper)
		runspeed = FixedMul($,FU*5/3)
	end
	runspeed = FixedMul($,me.movefactor)
	
	--P_SkidStuff(p)
	
	--lets start animating our player
	if ((cmd.forwardmove ~= 0 or cmd.sidemove ~= 0) or (issuper and not onground))
		if (p.charflags & SF_DASHMODE)
		and (p.dashmove >= 3*TR)
		and (p.panim == PA_RUN)
		and (not p.skidtime)
		and (onground or ((p.charability == CA_FLOAT or p.charability == CA_SLOWFALL) and p.secondjump == 1) or (issuper))
			me.state = S_PLAY_DASH
		elseif (accspeed >= runspeed and p.panim == PA_WALK and not p.skidtime
		and (onground or ((p.charability == CA_FLOAT or p.charability == CA_SLOWFALL) and p.secondjump == 1) or (issuper)))
			if not onground
				me.state = S_PLAY_FLOAT_RUN
			else
				me.state = S_PLAY_RUN
			end
		elseif ((((p.charability == CA_FLOAT or p.charability == CA_SLOWFALL) and p.secondjump == 1) or issuper) and p.panim == PA_IDLE and not onground)
			me.state = S_PLAY_FLOAT
		elseif ((p.rmomx or p.rmomy) and p.panim == PA_IDLE)
			me.state = S_PLAY_WALK
		end
	end
	
	if (p.charflags & SF_DASHMODE and p.panim == PA_DASH and p.dashmode < 3*TR)
		me.state = S_PLAY_RUN
	end
	
	if (p.panim == PA_RUN and accspeed < runspeed)
		if (not onground or (((p.charability == CA_FLOAT or p.charability == CA_SLOWFALL) and p.secondjump == 1) or (issuper)))
			me.state = S_PLAY_FLOAT
		else
			me.state = S_PLAY_WALK
		end
	end
	
	if onground
		if (me.state == S_PLAY_FLOAT)
			me.state = S_PLAY_WALK
		elseif (me.state == S_PLAY_FLOAT_RUN)
			me.state = S_PLAY_RUN
		end
	end
	
	if ((p.panim == PA_SPRING and me.momz*takis.gravflip < 0)
	or ((((p.charflags & SF_NOJUMPSPIN) and (p.pflags & PF_JUMPED)
	and p.panim == PA_JUMP)) and (me.momz*takis.gravflip < 0)))
		me.state = S_PLAY_FALL
	elseif (onground and (p.panim == PA_SPRING or p.panim == PA_FALL
	or p.panim == PA_RIDE or p.panim == PA_JUMP) and not me.momz)
		me.state = S_PLAY_STND
	end
	
	if (not me.momx and not me.momy and not me.momz and p.anim == PA_WALK)
		me.state = S_PLAY_STND
	end
	
	if onground and (me.momx or me.momy)
	and p.panim ~= PA_WALK
	and not me.momz
	and p.panim ~= PA_DASH
		if accspeed < runspeed
			me.state = S_PLAY_WALK
		else
			me.state = S_PLAY_RUN
		end
	end
	
	if not onground
	and (p.pflags & PF_JUMPED)
		if p.charflags & SF_NOJUMPSPIN
			if (me.momz*P_MobjFlip(me)) < 0
				me.state = S_PLAY_FALL
			else
				me.state = S_PLAY_JUMP
			end
		else
			me.state = S_PLAY_ROLL
		end
	end
	
	if (p.playerstate == PST_DEAD)
		me.state = S_PLAY_DEAD
	end
	
	--works fine as is so i dont think i need the rest of the func
end)

local lavacolor = SKINCOLOR_KETCHUP
local goocolor = SKINCOLOR_PURPLE
local waterruntype = MT_SOAP_FREEZEGFX
local function VFX_Waterrun(p,me,soap)
	--low friction on water
	if soap.onWater
		me.movefactor = tofixed("0.445")
		me.friction = tofixed("0.973")
	end
	
	local top_height = me.z + me.height
	local water_top = me.watertop
	if (soap.gravflip == -1)
		top_height = me.z
		water_top = me.waterbottom
	end
	
	if ((me.eflags & (MFE_TOUCHWATER|MFE_UNDERWATER) == MFE_TOUCHWATER and soap.onGround)
	or top_height > water_top)
	and (me.eflags & MFE_TOUCHWATER)
	and soap.accspeed >= 3*FU
	and me.health	--?? Why wasnt this here before
		if (soap.gravflip == -1)
			water_top = $ - FixedMul(mobjinfo[waterruntype].height, me.scale)
		end
		
		local angle = soap.fx.waterrun_A
		local radius = (me.radius) + 8*me.scale
		local forward_push_x = P_ReturnThrustX(nil, angle, radius)
		local forward_push_y = P_ReturnThrustY(nil, angle, radius)
		local rollangle = InvAngle(
			R_PointToAngle2(0, 0, R_PointToDist2(0,0,me.momx,me.momy), soap.rmomz)
		)
		
		local speedup_frame = false
		if (soap.accspeed > 50*FU)
			speedup_frame = P_RandomChance(
				min(FixedDiv(5*FU, soap.accspeed - 50*FU), FU)
			)
			if (soap.accspeed >= 55*FU) then speedup_frame = true end
		end
		local scale = FixedDiv(soap.accspeed, 60*FU)
		
		--left
		do
			if not (soap.fx.waterrun_L and soap.fx.waterrun_L.valid)
				local water = P_SpawnMobjFromMobj(me,0,0,0,waterruntype)
				water.angle = angle - ANGLE_180 - ANGLE_22h
				water.tracer = me
				water.state = S_SOAP_WATERTRAIL
				P_SetOrigin(water,
					(me.x + me.momx) + P_ReturnThrustX(nil, angle + ANGLE_90, radius) + forward_push_x,
					(me.y + me.momy) + P_ReturnThrustY(nil, angle + ANGLE_90, radius) + forward_push_y,
					water_top
				)
				P_SetScale(water, scale, true)
				soap.fx.waterrun_L = water
			end
			local water = soap.fx.waterrun_L
			water.angle = angle - ANGLE_180 - ANGLE_22h
			water.rollangle = rollangle
			P_MoveOrigin(water,
				(me.x + me.momx) + P_ReturnThrustX(nil, angle + ANGLE_90, radius) + forward_push_x,
				(me.y + me.momy) + P_ReturnThrustY(nil, angle + ANGLE_90, radius) + forward_push_y,
				water_top
			)
			if speedup_frame
			and (water.state ~= S_SOAP_WATERTRAIL_FAST)
				water.state = S_SOAP_WATERTRAIL_FAST
			end
			if (me.eflags & MFE_TOUCHLAVA)
				water.color = lavacolor
				water.colorized = true
			elseif (me.eflags & MFE_GOOWATER)
				water.color = goocolor
				water.colorized = true
			else
				water.color = SKINCOLOR_NONE
				water.colorized = false
			end
			P_SetScale(water, scale)
		end
		
		--right
		do
			if not (soap.fx.waterrun_R and soap.fx.waterrun_R.valid)
				local water = P_SpawnMobjFromMobj(me,0,0,0,waterruntype)
				water.angle = angle - ANGLE_180 + ANGLE_22h
				water.tracer = me
				water.state = S_SOAP_WATERTRAIL
				P_SetOrigin(water,
					(me.x + me.momx) + P_ReturnThrustX(nil, angle - ANGLE_90, radius) + forward_push_x,
					(me.y + me.momy) + P_ReturnThrustY(nil, angle - ANGLE_90, radius) + forward_push_y,
					water_top
				)
				P_SetScale(water, scale, true)
				soap.fx.waterrun_R = water
			end
			local water = soap.fx.waterrun_R
			water.angle = angle - ANGLE_180 + ANGLE_22h
			water.rollangle = rollangle
			P_MoveOrigin(water,
				(me.x + me.momx) + P_ReturnThrustX(nil, angle - ANGLE_90, radius) + forward_push_x,
				(me.y + me.momy) + P_ReturnThrustY(nil, angle - ANGLE_90, radius) + forward_push_y,
				water_top
			)
			if speedup_frame
			and (water.state ~= S_SOAP_WATERTRAIL_FAST)
				water.state = S_SOAP_WATERTRAIL_FAST
			end
			if (me.eflags & MFE_TOUCHLAVA)
				water.color = lavacolor
				water.colorized = true
			elseif (me.eflags & MFE_GOOWATER)
				water.color = goocolor
				water.colorized = true
			else
				water.color = SKINCOLOR_NONE
				water.colorized = false
			end
			P_SetScale(water, scale)
		end
		
		if not S_SoundPlaying(me, sfx_s3kdbs)
			local volume = (min(scale, FU) * 255) / FU
			S_StartSoundAtVolume(me, sfx_s3kdbs, volume, p)
		end
		soap.fx.waterrun_A = $ + FixedMul(Soap_MomentumAngle(me) - $, FU/5)
	else
		if (soap.fx.waterrun_L and soap.fx.waterrun_L.valid)
			P_RemoveMobj(soap.fx.waterrun_L)
			soap.fx.waterrun_L = nil
		end
		if (soap.fx.waterrun_R and soap.fx.waterrun_R.valid)
			P_RemoveMobj(soap.fx.waterrun_R)
			soap.fx.waterrun_R = nil
		end
		S_StopSoundByID(me,sfx_s3kdbs)
		soap.fx.waterrun_A = Soap_MomentumAngle(me)
	end
end

local dist = 8
local function VFX_JumpDust(p,me,soap)
	if me.soap_jumpdust ~= nil
		me.soap_jumpdust = $ - 1
		
		for i = 0,1
			if i and P_RandomChance(FU/3) then continue end
			
			local sweat = P_SpawnMobjFromMobj(me,
				P_RandomRange(-dist,dist)*FU,
				P_RandomRange(-dist,dist)*FU,
				0,
				dust_type(me)
			)
			--P_SetScale(sweat, me.scale * 3/2, true)
			P_SetOrigin(sweat, sweat.x,sweat.y,sweat.z)
			sweat.fuse = 6 - i
			sweat.destscale = 1
			sweat.scalespeed = FixedDiv(sweat.scale, sweat.fuse*FU)
			sweat.dontdrawforviewmobj = me
		end
		
		if me.soap_jumpdust == 0
		or not (p.pflags & PF_JUMPDOWN)
			me.soap_jumpdust = nil
		end
	end
end

local function VFX_LandDust(p,me,soap, props)
	--landing effect
	--land effect
	if (soap.onGround)
	and not soap.last.onground
	and not props.was_pounding
	and me.health
	and not (p.powers[pw_carry] == CR_NIGHTSMODE)
		local momz = abs(FixedDiv(soap.last.momz, me.scale))
		
		Soap_DustRing(me,
			dust_type(me),
			16 + max(
				(momz - 5*FU)/FU / 4,
				0
			),
			{me.x,me.y,me.z},
			me.radius/2,
			abs(soap.last.momz),
			me.scale,
			me.scale/2,
			false, dust_noviewmobj
		)
		
		--Yeah
		local ease_time = 8 + max(
			momz/2 - 5*FU,
			0
		)/2 / FU
		local ease_func = "insine"
		local strength = (FU/3) + min(max(momz/2 - 5*FU, 0)/6, (FU - (FU/3))*5/6)
		Soap_AddSquash(p, {
			ease_func = ease_func,
			start_v = strength,
			end_v = 0,
			time = ease_time
		}, {
			ease_func = ease_func,
			start_v = -strength*3/4,
			end_v = 0,
			time = ease_time
		}, "landeffect")
		S_StartSoundAtVolume(me,sfx_s3k4c,255/2)
	end
end

local function VFX_Squish(p,me,soap, props)
	--momentum based squash and stretch
	if props.squishme
	and not soap.onGround
	and abs(soap.rmomz) >= 18*me.scale
		local mom = FixedDiv(abs(soap.rmomz),me.scale)-18*FU
		mom = $/50
		mom = -min($,FU*4/5)
		soap.spritexscale,
		soap.spriteyscale = $1+mom,$2-(mom*9/10)
	end
end
rawset(_G, "Soap_VFXFuncs",{
	waterrun = VFX_Waterrun,
	jumpdust = VFX_JumpDust,
	landdust = VFX_LandDust,
	squish = VFX_Squish,
})

--preferrably we could handle the auras here but ehh whatever
rawset(_G,"Soap_VFX",function(p,me,soap, props)
	local allowed = {
		waterrun = true,
		jumpdust = true,
		landdust = true,
		squish = true,
		deathanims = true,
	}
	
	/*
		return value: table - table keys: override default behavior
		table entries:
			["waterrun"] = boolean
			["jumpdust"] = boolean
			["landdust"] = boolean
			["squish"] = boolean
			["deathanims"] = boolean
	*/
	local hook_event = Takis_Hook.events["Soap_VFX"]
	for i,v in ipairs(hook_event)
		local fxtable = Takis_Hook.tryRunHook("Soap_VFX", v, p, props)
		if fxtable == nil then continue end
		
		if fxtable.waterrun
			allowed.waterrun = false
		end
		if fxtable.jumpdust
			allowed.jumpdust = false
		end
		if fxtable.landdust
			allowed.landdust = false
		end
		if fxtable.squish
			allowed.squish = false
		end
		if fxtable.deathanims
			allowed.deathanims = false
		end
	end
	
	if allowed.waterrun
		VFX_Waterrun(p,me,soap)
	end
	
	if allowed.jumpdust
		VFX_JumpDust(p,me,soap)
	end
	
	if allowed.landdust
		VFX_LandDust(p,me,soap, props)
	end
	
	if allowed.squish
		VFX_Squish(p,me,soap, props)
	end
	
	soap.allowdeathanims = allowed.deathanims
end)

rawset(_G, "Soap_IsCompGamemode",function()
	local iscomp = (gametyperules & GTR_FRIENDLY) == 0
	if (gametyperules & GTR_RACE)
		iscomp = false
	end
	return iscomp
end)

rawset(_G, "Soap_SolThinker",function(p,me,soap)
	if ((leveltime % 3) == 0
	or (soap.accspeed > 40*FU))
	and (soap.isSolForm or p.powers[pw_super])
		spawnbubble(p,me,soap)
		if (soap.accspeed > 40*FU)
			spawnbubble(p,me,soap)
		end
	end
	
	if not (soap.isSolForm or p.powers[pw_super]) then return end
	p.powers[pw_underwater] = 0
	--spacedrown is different from water
end)

local SOAP_GRAB_ACTIONSTATE = 9999
rawset(_G,"Soap_GrabHitbox",function(p)
	local me = p.mo
	local soap = p.soaptable
	
	if me.soap_grabcooldown then return false; end
	
	local landed = false
	
	if (me.punchtarget and me.punchtarget.valid) then return end
	if (me.punchsource and me.punchsource.valid) then return end
	
	local fakerange = 128*FU
	local range = 32*me.scale
	local disp = P_SpawnMobjFromMobj(me,
		P_ReturnThrustX(nil, me.angle, FixedDiv(range + me.radius, me.scale)),
		P_ReturnThrustY(nil, me.angle, FixedDiv(range + me.radius, me.scale)),
		0, MT_THOK
	)
	disp.height = me.height
	searchBlockmap("objects", function(ref, found)
		if found == me then return end
		if not (found.health) then return end
		if not P_CheckSight(me,found) then return end
		if (found.flags & (MF_MISSILE|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING)) then return end
		if not (found.player and found.player.valid) then return end
		if (found.player and found.player.airdodge ~= nil and found.player.airdodge > 0) then return end
		if (found.player and found.player.intangible) then return end
		if (found.player.powers[pw_invulnerability]
		or found.player.powers[pw_flashing])
			return
		end
		
		if abs(disp.x - found.x) > range + found.radius
		or abs(disp.y - found.y) > range + found.radius
			return
		end
		if not Soap_ZCollide(disp,found) then return end
		
		--Already being grabbed
		if (found.punchsource and found.punchsource.valid) then return end
		--Already grabbing something
		if (found.punchtarget and found.punchtarget.valid) then return end
		
		if Soap_CanHurtPlayer(p,found.player, soap.inBattle)
			p.drawangle = me.angle
			Soap_GrabStart(me, found)
			
			soap.firenormal = 0
			p.cmd.buttons = $ &~BT_FIRENORMAL
			
			landed = true
			return true
		end
	end, 
	me,
	me.x-fakerange, me.x+fakerange,
	me.y-fakerange, me.y+fakerange)
	if (disp and disp.valid)
		P_RemoveMobj(disp)
	end
	return landed
end)

local function GrabSparks(me, flip)
	local fa = FixedDiv(360*FU, 8*FU)
	local dist = FixedDiv(me.radius,me.scale)
	local angle = me.punchangle
	for i = 1,8
		local my_ang = FixedAngle(fa * i)
		
		local spark = P_SpawnMobjFromMobj(me,
			P_ReturnThrustX(nil, angle, dist),
			P_ReturnThrustY(nil, angle, dist),
			FixedDiv((41*me.height)/48, me.scale),
			MT_SOAP_WALLBUMP
		)
		
		spark.sign = flip and -1 or 1
		
		spark.fuse = TR * 3/4
		spark.destscale = 0
		spark.scalespeed = FixedDiv(spark.scale, spark.fuse*FU)
		
		spark.grabmode = true
		spark.flags = $|MF_NOGRAVITY
		spark.color = me.player.skincolor
		spark.colorized = true
		
		spark.rotate = {
			x = spark.x,
			y = spark.y,
			z = spark.z,
			
			va = my_ang,
			ha = angle + ANGLE_90,
			
			dist = 0,
		}
	end
end

rawset(_G, "Soap_GrabStart",function(me, victim)
	me.punchtarget = victim
	me.punchpower = 10
	me.nothrow = 3
	me.punchangle = me.angle
	me.punchsparks = 6
	
	victim.punchsource = me
	victim.punchfree = 0
	victim.punchmash = 0
	victim.player.intangible = true
	victim.player.tumble = nil
	victim.flags = $ &~MF_NOCLIPHEIGHT
	
	S_StartSound(me, sfx_sp_grb)
	GrabSparks(me)
end)

rawset(_G, "Soap_GrabFree",function(from, me, idontflinch, theydontflinch)
	--Grabber gets endlag
	if not theydontflinch
	and not (from.player.guard)
	and CBW_Battle
		CBW_Battle.DoPlayerFlinch(from.player,
			TR/2, R_PointToAngle2(from.x,from.y, me.x,me.y),
			-3 * me.scale,
			false
		)
	end
	
	--And so do you
	if not idontflinch
	and CBW_Battle
		CBW_Battle.DoPlayerFlinch(from.player,
			TR/5, R_PointToAngle2(from.x,from.y, me.x,me.y),
			-3 * me.scale,
			false
		)
	end
	
	from.punchtarget = nil
	me.punchsource = nil
	me.player.intangible = false
	me.flags = $ &~MF_NOCLIPHEIGHT
	me.punchfree = nil
	me.punchmash = nil
	me.spritexoffset = 0
	me.hitlag = 0
	from.hitlag = 0
	from.soap_grabcooldown = TR*3/2
	from.nothrow = nil
	
	if (me.player.actionstate == SOAP_GRAB_ACTIONSTATE)
		me.player.actionstate = 0
	end
	if (from.player.actionstate == SOAP_GRAB_ACTIONSTATE)
		from.player.actionstate = 0
	end
end)

rawset(_G, "Soap_Grabbed",function(p,me,soap)
	local mo = me.punchsource
	local play = mo.player
	
	if not (mo.punchtarget and mo.punchtarget.valid)
	or (mo.punchtarget ~= me)
		Soap_GrabFree(mo, me, false, true)
	end
	
	p.powers[pw_nocontrol] = 2
	p.powers[pw_flashing] = 0
	p.pflags = $|PF_FULLSTASIS
	p.canguard = false
	me.momx,me.momy,me.momz = 0,0,0
	me.recoilangle = nil
	me.recoilthrust = nil
	me.flags2 = $ &~MF2_DONTDRAW
	
	p.guard = 0
	p.action2text = string.format("Release: %.1f%%", me.punchfree*100)
	p.canstunbreak = -5
	p.canguard = false
	
	local mashed = false
	if (soap.jump == 1)
	and not (me.punchmash)
	--Too late!
	and not (mo.punchtoss)
		mashed = true
	end
	
	if not (mo.punchtoss)
		p.drawangle = R_PointToAngle2(me.x,me.y, mo.x,mo.y)
	end
	
	if me.punchmash
		if not (me.hitlag)
			me.spritexoffset = (leveltime&1 and 1 or -1) * me.punchmash * FU/2
		end
		me.punchmash = $ - 1
	end
	
	if mashed
		S_StartSound(p.mo, sfx_s3kd7s)
		me.punchmash = TR/4
		me.punchfree = $ + FU/6
		if me.punchfree >= FU then
			Soap_GrabFree(me.punchsource, me)
			return
		end
		if CBW_Battle
			local shake = P_SpawnMobjFromMobj(me, 0, 0, 0, MT_THOK)
			shake.state = S_SHAKE
			p.shakemobj = shake
		end
	end
	
	if p.shakemobj and p.shakemobj.valid then
		P_MoveOrigin(p.shakemobj, me.x, me.y, me.z + (me.height/2))
	end
end)

rawset(_G, "Soap_Grabbing",function(p,me,soap)
	if not (me.punchtarget and me.punchtarget.valid) then return end
	if not (not me.health or P_PlayerInPain(p))
		me.state = S_PLAY_SKID
	end
	
	if me.punchsparks
	and (leveltime & 1)
		if (me.punchsparks % 2)
			GrabSparks(me, me.punchsparks % 4 == 3)
		end
		me.punchsparks = $ - 1
	end
	
	if (me.flags & MF_NOTHINK) then return end
	
	local mo = me.punchtarget
	local play = mo.player
	
	--let go of the guy
	if (p.guard)
	--or (soap.firenormal)
	or not (soap.onGround)
	or (soap.jump)
		Soap_GrabFree(me, mo, false, true)
		return
	end
	if (not me.health or P_PlayerInPain(p))
		me.hitlag = 0
		Soap_GrabFree(me, mo, false, true)
		return
	end
	
	p.powers[pw_nocontrol] = 2
	p.pflags = $|PF_STASIS
	me.momx,me.momy = 0,0
	me.recoilangle = nil
	me.recoilthrust = nil
	p.action2text = "Power: "..me.punchpower.."%"
	
	if CBW_Battle
		p.actioncooldown = max($, TR/2)
		play.actioncooldown = max($, TR/2)
	end
	p.actionstate = SOAP_GRAB_ACTIONSTATE
	play.actionstate = SOAP_GRAB_ACTIONSTATE
	
	mo.state = S_PLAY_PAIN
	local angle = (me.punchtoss) and (me.angle + FixedAngle(me.punchspin)) or (me.punchangle)
	local dist = me.radius + mo.radius + (10 * me.scale)
	P_MoveOrigin(mo,
		me.x + P_ReturnThrustX(nil, angle, dist),
		me.y + P_ReturnThrustY(nil, angle, dist),
		me.z + 3 * me.scale
	)
	play.drawangle = angle + ANGLE_180
	p.drawangle = me.punchangle
	
	if (soap.fire == 1)
	and not me.punchtoss
		Soap_ImpactVFX(mo,me)
		Soap_SpawnBumpSparks(mo, me)
		Soap_DamageSfx(mo, FU/3 + P_RandomRange(0, FU*2/3), FU)
		Soap_Hitlag.addHitlag(me, 12, false, true)
		Soap_Hitlag.addHitlag(mo, 12, true)
		me.punchpower = $ + 3
		
		if (play.rings)
			for i = 1, min(4, play.rings)
				local fling = P_SpawnMobjFromMobj(mo,
					0,0,0,
					MT_FLINGRING
				)
				fling.flags = $|MF_NOCLIPTHING
				fling.fuse = TR/2
				fling.angle = angle + FixedAngle(P_RandomFixedRange(-90,90))
				P_SetObjectMomZ(fling,
					P_RandomFixedRange(3, 6)
				)
				P_Thrust(fling, fling.angle, 10*fling.scale)
				P_GivePlayerRings(play, -1)
			end
		end
	end
	if (soap.firenormal == 1)
	and not me.punchtoss
	and not me.nothrow
		me.punchtoss = TR * 3/4
		me.punchspin = 0
		S_StartSound(me,sfx_mswing)
	end
	if me.nothrow then me.nothrow = $ - 1; end
	if me.punchtoss
		me.punchspin = $ + FixedDiv(360 * 2 * FU, (TR * 3/4)*FU)
		p.drawangle = me.angle + FixedAngle(me.punchspin)
		me.punchtoss = $ - 1
		
		if me.punchtoss == (TR*3/4)/2
			S_StartSound(me,sfx_mswing)
		elseif me.punchtoss == 1
			play.powers[pw_flashing] = 0
			mo.state = S_PLAY_PAIN
			mo.z = $ + mo.scale
			S_StartSound(mo,sfx_s3k51)
			if CBW_Battle
				CBW_Battle.DoPlayerTumble(play,TR*3/2,
					me.angle, 0
				)
				play.tumble_nostunbreak = true
				play.airdodge_spin = 0
			end
			
			local power = me.punchpower*me.scale
			P_3DInstaThrust(mo, me.angle, p.aiming, power)
			P_SetObjectMomZ(mo, 10*me.scale, true)
			
			Soap_GrabFree(me, mo, true)
			if CBW_Battle
				CBW_Battle.DoPlayerFlinch(p,
					TR/2, me.angle,
					-3 * me.scale,
					false
				)
			end
		end
	elseif (leveltime & 1)
	and false
		local marker = P_SpawnMobjFromMobj(me,0,0,0,MT_THOK)
		marker.drawonlyforplayer = p
		marker.sprite = SPR_LCKN
		marker.frame = A
		marker.renderflags = $|RF_FULLBRIGHT
		
		local power = me.punchpower*me.scale
		P_3DInstaThrust(marker, me.angle, p.aiming, power)
		P_SetObjectMomZ(marker, 10*me.scale, true)
		
		P_XYMovement(marker)
		P_ZMovement(marker)
		P_XYMovement(marker)
		P_ZMovement(marker)
		P_SetOrigin(marker, marker.x,marker.y,marker.z)
		
		marker.fuse = -1
		marker.tics = 2
	end
end)
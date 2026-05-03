-- freeslots the top object and handles its carrying stuff
local mbrelease = dofile("Vars/mbrelease.lua")

local TR = TICRATE

rawset(_G, "CR_GARDENTOP", 1000)
-- both sprites are from RR, nonreusable
freeslot("SPR_GTOP", "SPR_BDRF")
freeslot(
	"S_GARDENTOP_FLOATING",
	"S_GARDENTOP_SINKING1",
	"S_GARDENTOP_SINKING2",
	"S_GARDENTOP_SINKING3",
	"S_GARDENTOP_DEAD",
	"S_GARDENTOPSPARK"
)
freeslot("MT_GARDENTOP", "MT_GARDENTOPSPARK")

states[S_GARDENTOP_FLOATING] = {SPR_GTOP, FF_ANIMATE, -1, NULL, 5, 1, S_NULL}
states[S_GARDENTOP_SINKING1] = {SPR_GTOP, 0, 1, NULL, 5, 1, S_GARDENTOP_SINKING2}
states[S_GARDENTOP_SINKING2] = {SPR_GTOP, 2, 1, NULL, 5, 1, S_GARDENTOP_SINKING3}
states[S_GARDENTOP_SINKING3] = {SPR_GTOP, 4, 1, NULL, 5, 1, S_GARDENTOP_SINKING1}
states[S_GARDENTOP_DEAD] = {SPR_GTOP, FF_ANIMATE, 100, A_Scream, 5, 1, S_NULL}
states[S_GARDENTOPSPARK] = {SPR_BDRF, FF_FULLBRIGHT|FF_PAPERSPRITE|FF_ANIMATE|FF_RANDOMANIM, -1, NULL, 5, 2, S_NULL}
--states[S_GARDENTOPARROW] = {SPR_GTAR, FF_FULLBRIGHT|FF_PAPERSPRITE, -1, NULL, 5, 2, S_NULL}

mobjinfo[MT_GARDENTOP] = {
	doomednum = -1,
	spawnstate = S_GARDENTOP_FLOATING,
	spawnhealth = 8,
	reactiontime = 4,
	attacksound = sfx_s3k8b,
	deathstate = S_GARDENTOP_DEAD,
	deathsound = sfx_s3k7a,
	speed = 30*FU,
	radius = 30*FU,
	height = 68*FU,
	mass = 100,
	flags = MF_SPECIAL|MF_SLIDEME|MF_SOLID
}
mobjinfo[MT_GARDENTOPSPARK] = {
	doomednum = -1,
	spawnstate = S_GARDENTOPSPARK,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = 8,
	radius = 8*FU,
	height = 8*FU,
	mass = 100,
	dispoffset = 1,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
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
	
	p.powers[pw_carry] = CR_GARDENTOP
	me.tracer = glide
	p.pflags = $|PF_JUMPSTASIS
	glide.target = me
	glide.flags = $ &~MF_SPECIAL
	
	glide.health = glide.info.spawnhealth
	glide.state = glide.info.spawnstate
	return true
end,MT_GARDENTOP)

addHook("PostThinkFrame",do
for p in players.iterate
	local me = p.mo
	
	if not (me and me.valid) then continue end
	if p.powers[pw_carry] ~= CR_GARDENTOP then continue end
	if not (me.tracer and me.tracer.valid) then continue end
	if me.tracer.type ~= MT_GARDENTOP then continue end
	
	local top = me.tracer
	
	if R_PointToDist2(me.x,me.y, top.x,top.y) > top.radius * INT8_MAX
		P_MoveOrigin(me.tracer,
			me.x,
			me.y,
			me.z
		)
	end
	
	P_MoveOrigin(me,
		top.x, top.y,
		top.z + (FixedMul(top.height,top.spriteyscale) + (2 * top.scale) + top.spriteyoffset)*P_MobjFlip(me)
	)
	
	me.state = S_PLAY_STND
	me.momx = top.momx
	me.momy = top.momy
	me.momz = top.momz
end
end)

local function anchor_spark(spark)
	local top = spark.target
	P_MoveOrigin(spark,
		top.x,top.y,top.z
	)
	spark.angle = top.angle + spark.movedir
end

addHook("MobjThinker",function(spark)
	local top = spark.target
	if not (top and top.valid) then
		P_RemoveMobj(spark)
		return
	end
	
	anchor_spark(spark)
end,MT_GARDENTOPSPARK)

COM_AddCommand("hawktuah",function(p)
	if not (p.soaptable) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	local me = p.mo
	if not (me and me.valid) then return end
	
	P_SpawnMobjFromMobj(me,
		P_ReturnThrustX(nil, me.angle, 100*FU),
		P_ReturnThrustY(nil, me.angle, 100*FU),
		0,
		MT_GARDENTOP
	)
end)

-- handles the top object itself

local function sign(a)
	return (a ~= 0) and (a < 0 and -1 or 1) or 0
end

local function P_RandomFixedSigned()
	return P_RandomFixed() * sign(P_SignedRandom())
end

-- Takes 2 fixed_ts and returns a fixed_t
local function P_RandomFixedRange(a,b)
	return a + FixedMul((b - a), P_RandomFixed())
end

local function P_RandomSign()
	return sign(P_SignedRandom()) or -1 -- -1 if sign is 0
end

local TR = TICRATE

local topsfx_floating = sfx_s3k7d
local topsfx_grinding = sfx_s3k79
local topsfx_lift = sfx_s3ka0

local function spawn_spark(top, angle)
	local spark = P_SpawnMobjFromMobj(top,0,0,0,MT_GARDENTOPSPARK)
	spark.target = top
	spark.movedir = angle + P_RandomRange(0,360) * ANG1
	spark.color = SKINCOLOR_ISLAND
	spark.spriteyscale = 3*FU/4
	spark.fuse = 10
end
local function spawn_spark_circle(top, n)
	local a = FixedDiv(360*FU, n*FU)
	for i = 0, n
		spawn_spark(top, FixedAngle(a * i))
	end
end

local function spawn_grind_spark(top)
	-- MT_SOAP_WALLBUMP is a custom object, you can replace with your own or a vanilla MT_*
	local spark = P_SpawnMobjFromMobj(top,0,0,0,MT_SOAP_WALLBUMP)
	local speed = 6*top.scale
	local limit = 28
	local my_ang = FixedAngle(P_RandomFixedRange(0,360*FU))
	
	P_InstaThrust(spark, my_ang, speed)
	P_SetObjectMomZ(spark, P_RandomFixedRange(3*FU,8*FU))
	
	P_SetScale(spark,top.scale / 10, true)
	spark.destscale = top.scale
	--5 tics
	spark.scalespeed = FixedDiv(top.scale - top.scale / 10, 5*FU)
	spark.color = SKINCOLOR_ISLAND
	spark.colorized = true
	spark.fuse = TR
	
	spark.random = P_RandomRange(-limit,limit) * ANG1
	
	if not (leveltime % 8)
		spawn_spark_circle(top, 6)
	end
end

local function grinddown(top)
	local me = top.target
	local p = me.player
	return (p.cmd.buttons & BT_SPIN)
end
local function isgrinding(top)
	if top.float > 0 then return false; end
	if not P_IsObjectOnGround(top) then return false; end
	return true
end

local function accel(top)
	local me = top.target
	local p = me.player
	
	p.pflags = $ &~(PF_SPINNING|PF_JUMPED)
	
	if not isgrinding(top)
		if (p.cmd.forwardmove >= 0)
			top.friction = $ + 1024
		else
			top.friction = $ - 1024
		end
	else isgrinding(top)
		top.friction = $ - 1024
	end
	
	if P_IsObjectOnGround(top)
		P_ButteredSlope(top)
		if not isgrinding(top)
			P_Thrust(top, me.angle, 5 * top.friction)
		end
		/*
		local oldpos = {top.x,top.y,top.z}
		local tmomx = top.momx / 4
		local tmomy = top.momy / 4
		for i = 1,4
			if not P_TryMove(top,
				top.x + tmomx*i,
				top.y + tmomy*i,
				true
			)
				top.momx = $ / i
				top.momy = $ / i
				--P_BounceMove(top)
				break
			end
		end
		*/
	else
		local maxspeed = 50*top.scale
		local speed = R_PointToDist2(0,0, top.momx,top.momy)
		if grinddown(top)
			top.momz = $ - 4 * top.scale
			maxspeed = $ / 5
		end
		
		if speed > maxspeed
			local div = 32*FU
			
			local newspeed = speed - FixedDiv(speed - maxspeed,div)
			top.momx = FixedMul(FixedDiv(top.momx,speed), newspeed)
			top.momy = FixedMul(FixedDiv(top.momy,speed), newspeed)
		end
	end
end

local function loop_sfx(top, sfx)
	if sfx == topsfx_floating
		if S_SoundPlaying(top, sfx)
			return
		end
	elseif sfx == topsfx_grinding
		if top.sound ~= sfx
			top.soundtic = leveltime
		end
		
		if (leveltime - top.soundtic) % 28 > 0
			return
		end
	end
	S_StartSound(top, sfx)
end

local function modulate(top)
	local me = top.target
	local p
	if (me and me.valid)
		p = me.player
	end
	
	local max_hover = top.height / 4
	local hover_step = max_hover / 4
	
	local ambience = sfx_None
	
	if top.float == nil then top.float = 0; end
	
	if (me and me.valid)
	and grinddown(top)
		if top.float == max_hover
			top.state = S_GARDENTOP_SINKING1
		end
		if (top.float > 0)
			top.float = max(0, $ - hover_step)
		elseif P_IsObjectOnGround(top)
			spawn_grind_spark(top)
			ambience = topsfx_grinding
		end
	else
		if top.float == 0
			top.state = S_GARDENTOP_FLOATING
			S_StopSoundByID(top, topsfx_grinding)
			S_StartSound(top, topsfx_lift)
		end
		
		if top.float < max_hover
			top.float = min(max_hover, $ + hover_step)
		else
			ambience = topsfx_floating
		end
	end
	
	if top.loose
		if P_IsObjectOnGround(top)
			spawn_grind_spark(top)
			ambience = topsfx_grinding
		end
	end
	
	top.spriteyoffset = top.float
	
	if ambience ~= sfx_None
		loop_sfx(top, ambience)
	end
	top.sound = ambience
	
end

local function tilt(top)
	local me = top.target
	local p = me.player
	
	local tilt = top.rollangle
	local decay = ANG1 + ANG1
	
	if grinddown(top)
		local tiltmax = ANGLE_22h
		
		tilt = $ + (me.angle - top.oldpangle) / 2
		if abs(tilt) > tiltmax
			tilt = sign($) * tiltmax
		end
	end
	if abs(tilt) > decay
		tilt = $ - sign($) * decay
	else
		tilt = 0
	end
	
	top.rollangle = tilt
	top.oldpangle = me.angle
end

local function anchor_top(top)
	local me = top.target
	local p = me.player
	
	tilt(top)
	
	if top.lifetime == nil then top.lifetime = 0 end
	top.lifetime = $ + 1
	
	me.pitch = top.pitch
	me.roll = top.roll
	
	top.spritexscale = FU
	top.spriteyscale = FU
	if isgrinding(top)
		top.spritexscale = 6*FU/4
		top.spriteyscale = 2*FU/4
	end
	
	top.threshold = 20
	
	--release the top
	if (p.cmd.buttons & (BT_JUMP|BT_SPIN) == (BT_JUMP|BT_SPIN))
	and not (p.lastbuttons & (BT_JUMP|BT_SPIN) == (BT_JUMP|BT_SPIN))
	or (p.powers[pw_carry] ~= CR_GARDENTOP)
	or (me.tracer ~= top)
	and (top.lifetime > 3)
		P_ResetPlayer(p)
		P_DoJump(p)
		p.pflags = $|PF_JUMPED &~PF_THOKKED
		me.tracer = nil
		
		S_StartSound(top,sfx_kc5b)
		S_StartSound(top,sfx_s3k51)
		
		top.movedir = top.angle
		
		top.loose = true
		top.fuse = 10 * TR
		return
	end
	
	if (p.cmd.buttons & (BT_JUMP|BT_SPIN) == (BT_JUMP))
	and not (p.lastbuttons & (BT_JUMP|BT_SPIN) == (BT_JUMP))
	and P_IsObjectOnGround(top)
		P_SetObjectMomZ(top, 14*FU)
	end
end

local function angleDiff(ang1, ang2)
	local adiff = FixedAngle(
		AngleFixed(ang1) - AngleFixed(ang2)
	)
	if AngleFixed(adiff) > 180*FU
		adiff = InvAngle($)
	end
	return AngleFixed(adiff)
end

local function loose_think(top)
	local thrustamount = 20 * top.scale
	local momangle = R_PointToAngle2(0,0,top.momx,top.momy)
	
	local angle = top.angle
	
	local g = P_SpawnGhostMobj(top)
	g.color = SKINCOLOR_ISLAND
	g.colorized = true
	
	if angleDiff(angle, momangle) > 90*FU
		top.angle = momangle
	end
	
	if top.wavepause
		top.wavepause = $ - 1
	else
		angle = $ + abs(top.movedir) - ANGLE_90
	end
	
	P_InstaThrust(top, top.angle, thrustamount)
	P_Thrust(top, angle, thrustamount)
	
	top.movedir = $ + ANG10
	
	if (top.threshold)
		top.threshold = $ - 1
	end
	if (top.fuse < TR)
		top.flags2 = $^^MF2_DONTDRAW
	end
end

addHook("MobjThinker",function(top)
	local me = top.target
	if (top.flags & MF_SPECIAL) then return end
	--if not (me and me.valid) then return end
	
	modulate(top)
	if not (top and top.valid) then return end
	
	if not top.loose
		anchor_top(top)
		accel(top)
	else
		loose_think(top)
	end
end,MT_GARDENTOP)

-- collision and damage property relies on soap functions
-- you can reference this code and edit it to your liking,
-- but if you want to see how this works, remove the "--[[" and "]]"
-- and load soap before this mod
-- https://mb.srb2.org/addons/soap-the-hedge-yar-demo.8673/
local function try_pvp_collide(top,thing)
	if Soap_ZCollide == nil then return end
	if not (top and top.valid) then return end
	if not (thing and thing.valid) then return end
	
	if (top.lifetime == nil or top.lifetime < 3) then return end
	
	local me = top.target
	-- if not (me and me.valid) then return end
	-- if not (me.player and me.player.valid) then return end
	
	--??? why?
	if not top.health then return end
	-- if not me.health then return end
	if not thing.health then return end
	
	--players only
	-- if (me.type ~= MT_PLAYER) then return end
	if thing == me and top.threshold then return false; end
	if not Soap_ZCollide(top,thing) then return end
	
	local p
	if (me and me.valid)
		p = me.player
	end

	if thing.type ~= MT_PLAYER
	or not (thing.player and thing.player.valid)
		if not Soap_CanDamageEnemy(p, thing)
			if (thing.flags & MF_SPECIAL)
			and not (top.loose)
				P_TouchSpecialThing(thing, me)
			end
			
			if (thing.flags & MF_SPRING)
			and not (top.eflags & MFE_SPRUNG)
				P_DoSpring(thing, top)
			end
			
			if (thing.type == MT_SPIKE or thing.type == MT_WALLSPIKE)
				P_KillMobj(thing, top, me)
			end
			return
		end
		
		Soap_DamageSfx(thing, FU*3/4, FU)
		Soap_ImpactVFX(thing,me, FU, 2*FU)
		
		local hitlag_tics = TR/2
		P_StartQuake(50*FU, hitlag_tics,
			{top.x, top.y, top.z},
			512*top.scale
		)
		P_KillMobj(thing,top,me, DMG_CANHURTSELF)
		
		Soap_Hitlag.addHitlag(top, hitlag_tics, false)
		if (me and me.valid)
		and (me.tracer == top)
			Soap_Hitlag.addHitlag(me, hitlag_tics, false)
		end
		if (thing and thing.valid)
		and not (thing.flags & MF_MONITOR)
			Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
		end
		
		return false
	end
	
	--now for the other guy
	local p2 = thing.player
	local soap2 = p2.soaptable
	local battlepass = false --(soap.inBattle)
	
	-- if not Soap_CanHurtPlayer(p, p2, true) then return end

	Soap_DamageSfx(thing, FU*3/4, FU)
	Soap_ImpactVFX(thing,me, FU, 2*FU)
	
	local hitlag_tics = TR/2
	P_StartQuake(50*FU, hitlag_tics,
		{top.x, top.y, top.z},
		512*top.scale
	)
	
	if soap2.inBattle
		thing.state = S_PLAY_PAIN
		CBW_Battle.DoPlayerTumble(p2,TR*3,
			top.angle, 0
		)
		p2.tumble_nostunbreak = true
		p2.airdodge_spin = 0
	else
		P_DamageMobj(thing,top, nil, 1, 1)
	end
	thing.z = $ + thing.scale
	P_SetObjectMomZ(thing, 20 * top.scale)
	P_InstaThrust(thing,
		R_PointToAngle2(0,0,top.momx,top.momy),
		25*top.scale + R_PointToDist2(0,0,top.momx,top.momy)
	)

	Soap_Hitlag.addHitlag(top, hitlag_tics, false)
	if (me and me.valid)
	and (me.tracer == top)
		Soap_Hitlag.addHitlag(me, hitlag_tics, false)
	end
	if (thing and thing.valid)
		Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
	end
end

addHook("MobjMoveCollide",try_pvp_collide,MT_GARDENTOP)
addHook("MobjCollide",try_pvp_collide,MT_GARDENTOP)

addHook("MobjMoveBlocked",function(top,m,l)
	P_BounceMove(top)
	S_StartSound(top, top.info.attacksound)
end,MT_GARDENTOP)
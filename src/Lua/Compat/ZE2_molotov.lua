sfxinfo[SafeFreeslot("sfx_zm_fl")] = {
	caption = "Fire",
}
sfxinfo[SafeFreeslot("sfx_zm_fs")] = {
	caption = "Caught fire!",
}
sfxinfo[SafeFreeslot("sfx_zm_ft")] = {
	caption = "Molotov thrown",
}
sfxinfo[SafeFreeslot("sfx_zm_fe")] = {
	caption = "Molotov explodes",
}
for i = 0, 4
	sfxinfo[SafeFreeslot("sfx_zm_h"..i)] = {
		caption = "Molotov hits",
	}
end

local armacolors = {
	SKINCOLOR_KETCHUP, SKINCOLOR_PEPPER, SKINCOLOR_CRIMSON, SKINCOLOR_GARNET, SKINCOLOR_VOLCANIC
}
local ZEROVEC = Vec3.New(0,0,0)

local fire_radius = 185*FU
local fire_time = 2*TR

local cv_friendlyfire = SOAP_CV.FindVar("friendlyfire")
local function FriendlyFire()
	local gt_settings = xSlinger.getGametypeSettings()
	return cv_friendlyfire.value or gt_settings.friendlyfire
end

local function smoke_callback(smoke)
	smoke.state = mobjinfo[MT_SMOKE].spawnstate
	smoke.frame = $ &~FF_TRANSMASK
	smoke.renderflags = $|RF_SEMIBRIGHT
	smoke.flags = $|MF_NOCLIPHEIGHT
	P_SetObjectMomZ(smoke, 12*FU, true)
end

local function rim_callback(spark, m)
	spark.tics = m.rim_fuse
	spark.frame = A
	spark.sprite = SPR_SOAP_GFX
	spark.frame = 34|FF_PAPERSPRITE|FF_ADD
	spark.flags = $|MF_NOGRAVITY
	spark.colorized = true
	spark.color = SKINCOLOR_GARNET
	spark.momz = 0	
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	spark.type = MT_SOAP_WALLBUMP
	spark.alpha = m.rim_alpha
	
	spark.fusesquish = 5
	spark.scale = $ / 2
	spark.spritexscale = $ * 2
	spark.movefactor = FU * 89/100
	spark.fuse = spark.tics
	-- P_ThrustEvenIn2D(spark, spark.angle - ANGLE_90, speed*frac)
end

local function sixseven_callback(spark, me)
	spark.tics = 10
	spark.frame = A
	spark.sprite = SPR_SOAP_GFX
	spark.frame = 34|FF_PAPERSPRITE|FF_ADD
	spark.momz = 0
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	spark.alpha = FU
	spark.type = MT_SOAP_WALLBUMP
	spark.flags = $|MF_NOGRAVITY
	
	local speed = 30
	spark.scale = FU * 5
	spark.spritexscale = $ / 5
	spark.fusesquish = spark.tics
	spark.xstretch = FU/8
	spark.alpha = FU / 2
	spark.fuse = spark.tics
end

SafeFreeslot("S_MOLOTOV", "S_MOLOTOV_DEATH")
SafeFreeslot("MT_SOAPZE2_MOLOTOVHELPER")
mobjinfo[MT_SOAPZE2_MOLOTOVHELPER] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	radius = FU,
	height = 16*FU,
	flags = MF_NOSECTOR|MF_NOCLIP|MF_NOCLIPTHING
}

states[S_MOLOTOV] = {
	sprite = SPR_SOAP_GFX,
	frame = 64|FF_SEMIBRIGHT,
	tics = 1,
	action = function(mo)
		if not mo.isMissile then return end
		
		mo.spritexscale = FU * 3/2
		mo.spriteyscale = mo.spritexscale
		
		mo.extravalue1 = $ + 1
		if mo.extravalue1 > 12
		or abs(mo.momz) <= 12 * mo.scale
			local fric = FU * 97/100
			mo.momx = FixedMul($, fric)
			mo.momy = FixedMul($, fric)
			mo.momz = $ + P_GetMobjGravity(mo) * 3/4
		end
		mo.rollangle = $ + FixedAngle(R_PointTo3DDist(0,0,0, mo.momx,mo.momy,mo.momz) / 2)
		
		if leveltime % 2 == 0
			local range = 10*mo.scale
			local scalemul = mo.scale
			local anchorPos = Vec3.New(
				mo.x,mo.y,mo.z
			)
			
			local s = P_SpawnMobjFromMobj(mo,
				Soap_RandomFixedRange(-range,range),
				Soap_RandomFixedRange(-range,range),
				Soap_RandomFixedRange(0,range*2),
				MT_SOAP_FREEZEGFX
			)
			s.state = S_SOAP_NEWFLAME
			s.tracer = mo
			s.nofxadjust = true
			s.ninjadive = true
			s.spritexscale = Soap_RandomFixedRange(scalemul/3, scalemul*3/4)
			s.spriteyscale = s.spritexscale
			
			s.renderflags = $|RF_FULLBRIGHT
			s.blendmode = AST_ADD
			s.alpha = FU * 3/4
			
			s.anchor = anchorPos
			s.offset = Vec3.Sub(Vec3.MobjPosToVec(s), s.anchor)
			
			s.fuse = P_RandomRange(12, 24)
			
			s.offsetmom = ZEROVEC
			s.offsetparentmom = Vec3.MobjMomToVec(mo)
			s.offsetspeed = Soap_RandomFixedRange(5*scalemul, 25*scalemul)
			s.movefactor = P_RandomRange(FU*7/8, FU*98/100)
			s.angles = {
				h = FixedAngle(360*P_RandomFixed()),
				hc = Soap_RandomFixedRange(-18*scalemul, 18*scalemul),
				v = FixedAngle(Soap_RandomFixedRange(-180*FU, 180*FU)),
				vc = Soap_RandomFixedRange(-20*scalemul, 20*scalemul),
			}
			--s.fadewithfuse = true
			--s.fadeat = P_RandomRange(6,10)
			s.destscale = 0
			s.scalespeed = FixedDiv(s.scale, s.fuse*FU)
			P_3DThrust(s,
				FixedAngle(360 * P_RandomFixed()),
				FixedAngle(Soap_RandomFixedRange(20*FU, 80*FU)),
				20 * scalemul
			)
		end
		
		local p = displayplayer
		if not (p and p.valid) then return end
		local me = p.mo
		if not (me and me.valid) then return end
		if not (mo.team) then return end
		if me.team == mo.team then return end
		
		if not S_SoundPlaying(mo, sfx_zm_ft)
			S_StartSound(mo, sfx_zm_ft)
		end
	end,
	nextstate = S_MOLOTOV
}

states[S_MOLOTOV_DEATH] = {SPR_NULL, A, 1, function(mo) -- Explode within a radius setted by explode_radius local
	-- these are both a bit of hacky hacks,
	-- the height is set here so the function i copy-pasted
	-- from ze2 can work without much editing lol
	-- we set forcedamage here as a workaround for xslinger, making sure
	-- the blast damage will do 30 instead of the item's config damage
	mo.height = 1200 * mo.scale
	mo.forcedamage = 30
	
	searchBlockmap("objects", function(mo, foundmobj)
		local dist = R_PointToDist2(mo.x, mo.y, foundmobj.x, foundmobj.y)
		if (dist > fire_radius) then return end
		if not (foundmobj.health) then return end
		if not (foundmobj.flags & MF_SHOOTABLE) then return end
		if not ZE2.ZCollide(mo, foundmobj) then return end
		if foundmobj.team == mo.team and not FriendlyFire() then return end
		
		if foundmobj.player
			S_StartSound(foundmobj, sfx_zm_fs, foundmobj.player)
		end
		
		Soap_ImpactVFX(foundmobj, mo, FU*3/2, FU / 2, false, false, DMG_FIRE)
		P_DamageMobj(foundmobj, mo, mo.target, 30, DMG_FIRE)
	end, mo,
	mo.x - fire_radius, mo.x + fire_radius,
	mo.y - fire_radius, mo.y + fire_radius)
	
	P_StartQuake(12*FU, 5, {x = mo.x, y = mo.y, z = mo.z})
	
	local helper = P_SpawnMobjFromMobj(mo, 0,0,0, MT_SOAPZE2_MOLOTOVHELPER)
	helper.target = mo.target
	helper.fuse = fire_time
	helper.team = mo.team
	local sfx = P_SpawnGhostMobj(helper)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = fire_time * 2
	sfx.tics = sfx.fuse
	S_StartSound(sfx, sfx_zm_fl)
	
	Soap_ImpactVFX(mo, mo, 0, FU * 3/4, false, false, DMG_NUKE)
	local scalemul = mo.scale
	local range = 30 * scalemul
	local flamestate = S_SOAP_NEWFLAME
	local origin = helper
	local anchorVec = Vec3.New(
		origin.x,origin.y,origin.z
	)
	-- we should be fine passing this to each vfx mobj,
	-- since the vector library makes a new vector for each operation
	-- rather than modifying the source vector
	local originMom = Vec3.MobjMomToVec(origin)
	for i = 0, 12
		local s = P_SpawnMobjFromMobj(mo,
			Soap_RandomFixedRange(-range,range),
			Soap_RandomFixedRange(-range,range),
			Soap_RandomFixedRange(0,range*2),
			MT_SOAP_FREEZEGFX
		)
		s.state = flamestate
		s.tracer = origin
		s.nofxadjust = true
		s.ninjadive = true
		s.spritexscale = Soap_RandomFixedRange(scalemul/2, scalemul*3/2) * 2
		s.spriteyscale = s.spritexscale
		
		s.renderflags = $|RF_FULLBRIGHT
		s.blendmode = AST_ADD
		s.alpha = FU * 3/4
		
		s.anchor = anchorVec
		-- make this vector manually instead of using the vector
		-- metamethods for some extra performance
		local myPos = Vec3.New(s.x, s.y, s.z)
		s.offset = Vec3.Sub(myPos, s.anchor)
		
		s.fuse = P_RandomRange(32, 64)
		
		s.offsetmom = ZEROVEC
		s.offsetparentmom = originMom
		s.offsetspeed = Soap_RandomFixedRange(5*scalemul, 25*scalemul)
		s.movefactor = P_RandomRange(FU*89/100, FU)
		s.angles = {
			h = FixedAngle(360*P_RandomFixed()),
			hc = Soap_RandomFixedRange(-18*scalemul, 18*scalemul),
			v = FixedAngle(Soap_RandomFixedRange(-180*FU, 180*FU)),
			vc = Soap_RandomFixedRange(-20*scalemul, 20*scalemul),
		}
		--s.fadewithfuse = true
		--s.fadeat = P_RandomRange(6,10)
		s.destscale = 0
		s.scalespeed = FixedDiv(s.scale, s.fuse*FU)
		P_3DThrust(s,
			FixedAngle(360 * P_RandomFixed()),
			FixedAngle(Soap_RandomFixedRange(20*FU, 80*FU)),
			20 * scalemul
		)
	end
	Soap_DustRing(mo,
		MT_SOAP_DUST, 14,
		{mo.x,mo.y,mo.z},
		64*FU, 27*FU,
		mo.scale / 10,
		mo.scale * 4,
		false, smoke_callback
	)
	Soap_DustRing(mo,
		MT_SOAP_WALLBUMP, 24,
		{mo.x,mo.y,mo.z},
		64*FU, 10*FU,
		mo.scale / 10,
		mo.scale * 6,
		false, sixseven_callback
	)
end, 0, 0, S_NULL}

local burning_info = {
	normalspeed_multiplier = FU/2,
	actionspd_multiplier = 3*FU/2,
	damage_multiplier = FU/2,
}
local function Helper_FireSearch(m, found)
	if not (found and found.valid) then return end
	if not (found.health) then return end
	if not (found.flags & MF_SHOOTABLE) then return end
	if found.team == m.team and not FriendlyFire() then return end
	
	local dist = R_PointToDist2(m.x, m.y, found.x, found.y)
	if (dist > fire_radius) then return end
	if not ZE2.ZCollide(m, found) then return end
	
	if #found:search_effect("burning") then return end
	
	if found.player
		S_StartSound(found, sfx_zm_fs, found.player)
	end
	Soap_ImpactVFX(found, m, FU*3/2, FU / 2, false, false, DMG_FIRE)
	found:give_effect("burning", burning_info, TR*3/2, false)
	found.flameringtarget = m.target -- seems like a hacky fix but alright!
end

local FLAME_MOVEFACT = FU * 97/100
local function flamevfx(m)
	local dist = FixedMul(fire_radius, P_RandomFixed())
	local ang = FixedAngle(360 * P_RandomFixed())
	local s = P_SpawnMobjFromMobj(m,
		P_ReturnThrustX(ang,dist),
		P_ReturnThrustY(ang,dist),
		32 * P_RandomFixed(), MT_SOAP_WALLBUMP
	)
	s.state = S_SOAP_NEWFLAME
	s.blendmode = AST_SUBTRACT
	s.scale = FixedMul($, Soap_RandomFixedRange(FU * 3/2, 3*FU + FU/4))
	s.spritexscale = $ / 7
	s.flags = $|MF_NOGRAVITY
	
	s.fuse = P_RandomRange(7, 10)
	s.nothink = true
	s.fusesquish = s.fuse
	s.xstretch = FU / 7
	
	s.movefactor = FLAME_MOVEFACT
	P_Thrust(s, ang, Soap_RandomFixedRange(2*FU, 5*FU))
	
	-- flame spots
	s = P_SpawnMobjFromMobj(m,
		P_ReturnThrustX(ang,dist),
		P_ReturnThrustY(ang,dist),
		2*FU, MT_SOAP_WALLBUMP
	)
	s.state = S_INVISIBLE
	s.sprite = SPR_SOAP_GFX
	s.frame = 37|FF_ADD|FF_FULLBRIGHT
	s.fuse = 10
	s.color = armacolors[P_RandomRange(1,#armacolors)]
	s.renderflags = $|RF_FLOORSPRITE|RF_NOCOLORMAPS
	s.flags = $|MF_NOGRAVITY
	s.spritexscale = FixedMul($, Soap_RandomFixedRange(2*FU, 8*FU))
	s.spriteyscale = s.spritexscale
	s.fusefade = 8
	s.destscale = 0
	s.scalespeed = FixedDiv(s.scale, s.fuse*FU)
	s.xstretch = FU/10
end
addHook("MobjThinker", function(m)
	if not (m and m.valid) then return end
	
	-- blockmap is slower, but i also want this to affect enemies LOL!
	searchBlockmap("objects", Helper_FireSearch, m,
		m.x - fire_radius, m.x + fire_radius,
		m.y - fire_radius, m.y + fire_radius
	)
	
	-- flames
	flamevfx(m)
	flamevfx(m)
	flamevfx(m)
	
	if leveltime % 4 == 0
		m.rim_fuse = P_RandomRange(6,10)
		m.rim_alpha = FU*3/4 + P_RandomFixed()/4
		Soap_DustRing(m,
			MT_SOAP_WALLBUMP, 22,
			{m.x,m.y,m.z},
			fire_radius - 32*FU, 12*FU,
			m.scale,
			m.scale * 12/10,
			false, rim_callback
		)
	end
end,MT_SOAPZE2_MOLOTOVHELPER)

-- missile definition
local xsmissile_molotov = xSlinger.registerMissile("MOLOTOV", {
	speed = 62*FU,
	displayname = "Molotov Cocktail",
	state = S_MOLOTOV,
	deathstate = S_MOLOTOV_DEATH,
	deathsound = sfx_zm_fe,
	externaldeathsound = true,
	radius = 20*FU,
	height = 40*FU,
	antiknockback = true,
	delflags = MF_NOGRAVITY|MF_NOBLOCKMAP,
	
	blocked = function(self, me, mo, line)
		if not line then return end
		Soap_SpawnBumpSparks(mo, nil, line, false, FU / 2)
		
		local line_ang = R_PointToAngle2(
			line.v1.x, line.v1.y, line.v2.x, line.v2.y
		)
		local speed = FixedDiv(8*mo.scale, mo.friction)
		speed = $ + abs(FixedMul(
			R_PointToDist2(0,0,mo.momx,mo.momy) / 4,
			sin(line_ang - R_PointToAngle2(0,0,mo.momx,mo.momy))
		))
		
		--its ambiguous syntax to have the `func` definition on the same line
		--as the call, so :shrug:
		--C DOESNT COMPLAIN....
		local func = P_InstaThrust
		func(mo,
			line_ang - ANGLE_90*(P_PointOnLineSide(mo.x,mo.y, line) and 1 or -1),
			-speed
		)
		
		local sound = sfx_zm_h0
		if mo.extravalue2
			sound = P_RandomRange(sfx_zm_h1, sfx_zm_h4)
		end
		mo.extravalue2 = $ + 1
		mo.rollangle = $ + ANGLE_45
		S_StartSound(mo, sound)
		
		return true
	end
})

xSlinger.registerItem("molotov", {
	-- HUD
	displayname = "Molotov Cocktail";
	icon = "MOLOTOVIND";
	background_color = SKINCOLOR_APPLE,
	animation_time = TR / 2;

	-- Missile properties
	dropstate = S_MOLOTOV;
	hold_object = {
		state = S_MOLOTOV;
		pos = {  -- at this pos, the object is at the right of your body
			x = FU;
			y = FU/2;
			z = 0;
		};
		pos_anim = {
			x = -FU;
			y = (FU*3)/2;
			z = -FU/3;
		};
	};
	
	color = SKINCOLOR_GREEN;
	missile = "MOLOTOV";
    firerate = 14*TR;
	damage = 10;
	droppable = false;

	sounds = {};
	usefunc = function(self, me)
		S_StartSound(me,sfx_kc5b)
		S_StartSound(me,sfx_s3k51)
	end;
})
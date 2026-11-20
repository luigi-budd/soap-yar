xSlinger.registerEffect("blaster.slowdown", {
	max_duration = 2*TR,
	tick = function(effect, mobj, time_left)
		-- nothing lol
	end,
})

-- this is a recreation of the s-blast from splatoon 3,
-- using paintgun code since my bullet recreation from there
-- is already pretty accurate lol
local Paint = {}

-- distance-unit 2 fracunit scale factor
-- .35 du = 16 fu (player radii)
-- 45.714 is the scale factor cause, of math reasons :think:
Paint.DU2FU = 46*FU
-- multiply by 1.71428 to get 1/60 -> 1/35
Paint.SIXTY2THIRTYFIVE = tofixed("1.71428")
-- splat 3's is 0.95999998 which is basically 0.96
Paint.SPLAT2WALKSPEED = tofixed("0.096")

Paint.SS_STRAIGHT = 1
Paint.SS_BRAKE = 2
Paint.SS_FREE = 3

local bulletSimpleState = function(shot)
	local secgrav = P_GetMobjGravity(shot)
	local gravmul = abs(FixedDiv(secgrav, -shot.scale/2))
	
	local state = shot.s_state
	if state == Paint.SS_STRAIGHT
		if shot.lifespan >= shot.str_tics
			shot.s_state = Paint.SS_BRAKE
			shot.braketic = shot.lifespan
		end
	elseif state == Paint.SS_BRAKE
		if R_PointToDist2(0,0, shot.momx,shot.momy) >= shot.str2brk_maxspeed
			local new = shot.str2brk_maxspeed
			shot.momx = P_ReturnThrustX(nil,shot.baseangle,new)
			shot.momy = P_ReturnThrustY(nil,shot.baseangle,new)
		end
		local resist = shot.brk_airresist
		shot.momx = FixedMul($, resist)
		shot.momy = FixedMul($, resist)
		shot.momz = FixedMul($, resist)
		shot.momz = $ - FixedMul(shot.brk_gravity * P_MobjFlip(shot), gravmul)
		if (shot.momz*P_MobjFlip(shot) <= shot.brk2fre_minz)
		and (
			(R_PointToDist2(0,0, shot.momx,shot.momy) <= shot.brk2fre_minxy)
			or
			(shot.lifespan - shot.braketic >= shot.brk2fre_tics)
		)
			shot.s_state = Paint.SS_FREE
		end
	elseif state == Paint.SS_FREE
		local resist = shot.fre_airresist
		shot.momx = FixedMul($, resist)
		shot.momy = FixedMul($, resist)
		shot.momz = FixedMul($, resist)
		shot.momz = $ - FixedMul(shot.fre_gravity * P_MobjFlip(shot), gravmul)
	end
end

local cv_friendlyfire = SOAP_CV.FindVar("friendlyfire")
local function FriendlyFire()
	local gt_settings = xSlinger.getGametypeSettings()
	return cv_friendlyfire.value or gt_settings.friendlyfire
end

local function ShortenGroups(shot)
	if shot.expired then return end
	shot.expired = true
	shot.powerful = false
	
	local sfx = P_SpawnGhostMobj(shot)
	sfx.fuse = 2*TR
	sfx.tics = sfx.fuse
	sfx.flags2 = $|MF2_DONTDRAW
	S_StartSound(sfx, sfx_p_s3_1)
	
	shot.inner_radius = $ * 4/5
	shot.outer_radius = $ * 4/5
	
	shot.inner_damage = $ / 2
	shot.outer_damage = $ / 2
end

local nuke_sparkcolors = {
	SKINCOLOR_VOLCANIC, SKINCOLOR_SANGRIA, SKINCOLOR_KETCHUP, SKINCOLOR_GARNET,
	SKINCOLOR_FLAME, SKINCOLOR_PEPPER, SKINCOLOR_SALMON, SKINCOLOR_CHERRY,
}
local clrlen = #nuke_sparkcolors
local function ExplodeShot(shot)
	if shot.exploded then return end
	shot.exploded = true
	shot.powerful = false
	
	if not shot.expired
		local sfx = P_SpawnGhostMobj(shot)
		sfx.fuse = 2*TR
		sfx.tics = sfx.fuse
		sfx.flags2 = $|MF2_DONTDRAW
		S_StartSound(sfx, sfx_p_s3_0)
	end
	
	if shot.outer_radius == nil then return end -- Bruh
	
	local blockradius = shot.outer_radius + 64*FU
	searchBlockmap("objects", function(shot, foundmobj)
		if not (foundmobj.health) then return end
		if not (foundmobj.flags & MF_SHOOTABLE) then return end
		local dist = R_PointTo3DDist(shot.x, shot.y, shot.z, foundmobj.x, foundmobj.y, foundmobj.z)
		if (dist > shot.outer_radius + foundmobj.radius) then return end
		-- bro!
		if (foundmobj.player and foundmobj.player.spectator) then return end
		if (foundmobj == shot.target) then return end
		
		-- teammate
		if foundmobj.team == shot.team and not FriendlyFire()
			-- do nothing Lol
		else -- enemy
			local damage = shot.inner_damage
			local knockback = shot.inner_knockback
			if dist > shot.inner_radius
				local frac = FixedDiv(dist - shot.inner_radius, shot.outer_radius - shot.inner_radius)
				damage = ease.linear(
					frac, shot.inner_damage, shot.outer_damage
				)
				knockback = ease.linear(
					frac, shot.inner_knockback, shot.outer_knockback
				)
			end
			shot.forcedamage = damage
			shot.forceknockback = knockback
			
			P_DamageMobj(foundmobj, shot, shot.target, shot.forcedamage)
			shot.forcedamage = nil
			shot.forceknockback = nil
		end
	end, shot,
		shot.x - blockradius, shot.x + blockradius,
		shot.y - blockradius, shot.y + blockradius
	)
	shot.forcedamage = nil
	
	local innerrad = shot.inner_radius
	local outerrad = shot.outer_radius
	local outlinerad = outerrad * 4/5
	for i = 1,26
		local ha = FixedAngle(P_RandomRange(0,36) * 10*FU)
		local va = FixedAngle(P_RandomRange(0,36) * 10*FU)
		local v = SphereToCartesian(ha,va)
		local s = P_SpawnMobjFromMobj(shot,
			FixedMul(outlinerad, v.x),
			FixedMul(outlinerad, v.y),
			FixedMul(outlinerad, v.z),
			MT_PARTICLE
		)
		s.state = P_RandomChance(FU/2) and S_SOAP_IMPACT_LINE2F or S_SOAP_IMPACT_LINE2
		local offset = P_RandomRange(0, 8)
		s.tics = $ + offset
		s.anim_duration = $ + offset
		s.angle = ha
		s.rollangle = va
		s.renderflags = $|RF_ALWAYSONTOP|RF_NOCOLORMAPS
		s.color = SKINCOLOR_GOLDENROD
		s.spritexscale = P_RandomRange(FU*3/4, FU*6/5)
		s.spriteyscale = s.spritexscale
		
		local thisdist = FixedMul(outerrad, P_RandomFixed())
		local speed = Soap_RandomFixedRange(20*FU, 83*FU)
		local f = P_SpawnMobjFromMobj(shot,
			FixedMul(thisdist, v.x),
			FixedMul(thisdist, v.y),
			FixedMul(thisdist, v.z),
			MT_SOAP_WALLBUMP
		)
		f.spritexscale = P_RandomRange(FU, FU*7/5)
		f.spriteyscale = f.spritexscale
		f.state = S_SOAP_HITM_ESW
		f.tics = 1
		f.extravalue1 = $ + P_RandomRange(1,3)*3
		f.repeats = P_RandomRange(0, 3)
		f.renderflags = $|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)|RF_NOCOLORMAPS
		f.color = nuke_sparkcolors[P_RandomRange(1, clrlen)]
		
		-- clamp just in case...
		f.tics = max($, 1)
		f.extravalue1 = max($, 1)
		
		P_3DThrust(f, ha,va, speed)
		f.nothink = true
		f.movefactor = P_RandomRange(FU*69/100, FU*86/100)
		f.movefactoraffectsz = true
		f.flags = $|MF_NOGRAVITY
		f.blendmode = AST_SUBTRACT
	end
	
	local vfxscale = FixedDiv(outerrad, 40*FU)
	local fa = FixedDiv(360*FU, 4*FU)
	for i = 1,2
		local s = P_SpawnMobjFromMobj(shot,
			0,0,0,
			MT_SOAP_WALLBUMP
		)
		s.nothink = true
		s.flags = $|MF_NOGRAVITY
		s.frame = 36|FF_FULLBRIGHT|FF_ADD|FF_PAPERSPRITE
		s.spritexscale = vfxscale
		s.spriteyscale = vfxscale
		s.renderflags = $|RF_NOCOLORMAPS
		s.angle = FixedAngle(fa*i)
		s.fuse = 10
		s.fusefade = 10
		s.fusescale = {
			func = "inquad",
			fuseunder = 6,
			startscale = s.scale,
			destscale = 0,
			backparam = FU/2
		}
		s.color = SKINCOLOR_KETCHUP
	end
	
	vfxscale = FixedDiv(innerrad, 10*FU)
	fa = FixedDiv(360*FU, 4*FU)
	for i = 1,2
		local s = P_SpawnMobjFromMobj(shot,
			0,0,0,
			MT_SOAP_WALLBUMP
		)
		s.nothink = true
		s.flags = $|MF_NOGRAVITY
		s.frame = 37|FF_FULLBRIGHT|FF_ADD|FF_PAPERSPRITE
		s.spritexscale = vfxscale
		s.spriteyscale = vfxscale
		s.renderflags = $|RF_NOCOLORMAPS
		s.angle = FixedAngle(fa*i)
		s.fuse = 6
		s.fusefade = s.fuse
		s.fusescale = {
			func = "inquad",
			fuseunder = s.fuse,
			startscale = s.scale,
			destscale = 0,
			backparam = FU/2
		}
		s.color = SKINCOLOR_KETCHUP
	end
	
	/*
	local top_layer = P_SpawnMobjFromMobj(shot, 0,0,-80*FU, MT_PARTICLE)
	top_layer.state = S_SOAP_HITM_RSPRK
	top_layer.fuse = top_layer.tics
	top_layer.spritexscale = FU * 4
	top_layer.spriteyscale = top_layer.spritexscale
	top_layer.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
	top_layer.dispoffset = 200
	top_layer.colorized = true
	top_layer.color = elec_sparkcolors[P_RandomRange(1, #elec_sparkcolors)]
	*/
end

states[SafeFreeslot("S_TBLASTER")] = {
	sprite = SPR_SOAP_GFX,
	frame = 79|FF_SEMIBRIGHT,
	tics = 1,
	nextstate = S_TBLASTER,
	action = function(m)
		m.frame = ($ &~FF_FRAMEMASK)|(79 + m.extravalue1)
	end
}

states[SafeFreeslot("S_TBLASTER_DIE")] = {
	sprite = SPR_NULL,
	frame = A,
	tics = 1,
	action = ExplodeShot,
	nextstate = S_NULL,
}

states[SafeFreeslot("S_TBLASTER_ROCK")] = {
	sprite = SPR_SOAP_GFX,
	frame = 78|FF_SEMIBRIGHT,
	tics = 1,
	action = function(m)
		m.spritexscale = (FU * 17/10)
		m.spriteyscale = m.spritexscale
		if not m.isMissile then return end
		
		if not S_SoundPlaying(m, sfx_cdfm17)
			S_StartSoundAtVolume(m, sfx_cdfm17, 255 / 4)
		end
	end,
	nextstate = S_TBLASTER_ROCK
}

sfxinfo[SafeFreeslot("sfx_p_s3_0")] = {caption = "Explosion", flags = SF_X4AWAYSOUND}
sfxinfo[SafeFreeslot("sfx_p_s3_1")] = {caption = "Explosion", flags = SF_X2AWAYSOUND}
sfxinfo[SafeFreeslot("sfx_p_s3_2")].caption = "/"
sfxinfo[SafeFreeslot("sfx_p_s3_3")].caption = "/"
sfxinfo[SafeFreeslot("sfx_p_s3_4")].caption = "/"
sfxinfo[SafeFreeslot("sfx_p_s3_5")].caption = "/"

local xmissile_blastershot = xSlinger.registerMissile("TAKIS_BLASTER", {
	speed = FixedMul(FixedMul(tofixed("1.7"), Paint.DU2FU), Paint.SIXTY2THIRTYFIVE),
	displayname = "F-Rocket 900",
	state = S_TBLASTER_ROCK,
	deathstate = S_TBLASTER_DIE,
	deathsound = sfx_rs_die,
	radius = 20*FU,
	height = 40*FU,
	
	subtick = function(self, me, shot)
		local floorhit = (shot.z <= shot.floorz)
		local ceilinghit = (shot.z + shot.height >= shot.ceilingz)
		if floorhit or ceilinghit
			ShortenGroups(shot)
		end
		
		/*
		local w = Soap_WindLines(shot,nil,SKINCOLOR_MASTER)
		if not (w and w.valid) then return end
		w.scale = $ / 2
		w.blendmode = AST_ADD
		*/
	end,
	tick = function(self, me, shot)
		local floorhit = (shot.z <= shot.floorz)
		local ceilinghit = (shot.z + shot.height >= shot.ceilingz)
		if floorhit or ceilinghit
			ShortenGroups(shot)
		end
		
		shot.lifespan = $ + 1
		bulletSimpleState(shot)
		
		if (shot.lifespan > 1)
			local s = P_SpawnMobjFromMobj(shot, 0,0,FixedDiv(shot.height,shot.scale)/2, MT_SOAP_WALLBUMP)
			s.nothink = true
			s.flags = $|MF_NOGRAVITY
			s.frame = 42|FF_FULLBRIGHT|FF_ADD
			s.spritexscale = ($ * 3/5) + ((shot.lifespan - 2) * FU/11)
			s.spriteyscale = s.spritexscale
			s.renderflags = $|RF_NOCOLORMAPS
			s.fuse = 6
			s.fusefade = s.fuse
			s.fusescale = {
				func = "inquad",
				fuseunder = s.fuse,
				startscale = s.scale,
				destscale = 0,
			}
			s.color = SKINCOLOR_KETCHUP
			s.rollangle = FixedAngle(leveltime*33 * FU)
			s.random = FixedAngle(33*FU / 2)
		end
		
		if shot.lifespan >= shot.crs_guideframe
			shot.momx,shot.momy,shot.momz = 0,0,0
			P_KillMobj(shot)
			return
		end
	end,
	blocked = function(self, me, shot, line)
		ShortenGroups(shot)
	end,
})

xSlinger.registerItem("blaster", {
	displayname = "F-Rocket 900";
	icon = "BLASTERIND";
    hold_icon = "SPR_THOK"; -- Can be a normal graphic instead of a sprite too.
	
	missile = "TAKIS_BLASTER";
	dropstate = S_TBLASTER;
	color = SKINCOLOR_RED;

	damage = 90;
	velocity_precision = 4;

	autouse = true;
	ammo = 4;

	firerate = 29;
	reload_time = 2*TR + TR*3/4;

	flags2 = 0; -- MF2_...
	hold_object = {
		state = S_TBLASTER;
		pos = {  -- at this pos, the object is at the right of your body
			x = FU * 12/10;
			y = 0;
			z = FU/6;
		};
		pos_anim = {
			x = FU * 13/10;
			y = -FU * 6/5;
			z = FU/6 + FU/12;
		};
	};
    animation_time = TR * 4/3;
	
	knockback = 75*FU;
	alt_knockback = 116*FRACUNIT;
	knockback_time = 40;
	
	spawnspeed = FixedMul(FixedMul(tofixed("1.7"), Paint.DU2FU), Paint.SIXTY2THIRTYFIVE),
	str_tics = 6, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.65"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = tofixed("0.07"),
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 98/100,
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	crs_guideframe = 8, -- crosshair is placed at this frame in the shot's lifetime
	
	shot_radius = 20*FU,
	
	inner_radius = FixedMul(tofixed("1.475"), Paint.DU2FU),
	inner_knockback = 30*FU,
	inner_damage = 70,
	outer_radius = FixedMul(tofixed("3.385"), Paint.DU2FU),
	outer_knockback = 10*FU,
	outer_damage = 50,
	
	alt_spawnspeed = FixedMul(FixedMul(tofixed("0.72"), Paint.DU2FU), Paint.SIXTY2THIRTYFIVE),
	alt_str_tics = 4, -- straight state lasts this many tics
	alt_str2brk_maxspeed = FixedMul(tofixed("1.65"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	alt_brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	alt_brk_gravity = tofixed("0.07"),
	alt_brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	alt_brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	alt_brk2fre_tics = 4, -- or when brake state lasts this many tics
	alt_fre_airresist = FU * 98/100,
	alt_fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	alt_crs_guideframe = 5, -- crosshair is placed at this frame in the shot's lifetime
	
	alt_shot_radius = 28*FU,
	
	alt_inner_radius = FixedMul(tofixed("3.175"), Paint.DU2FU),
	alt_inner_knockback = 110*FU,
	alt_inner_damage = 70,
	alt_outer_radius = FixedMul(tofixed("4.287"), Paint.DU2FU),
	alt_outer_knockback = 58*FU,
	alt_outer_damage = 50,
	
	alternate = false,
	grow = 0,
	
	sounds = {
		use = sfx_None;
		reload = {sfx_xsrel1, sfx_xsrel2};
		pickup = sfx_None;
		drop = sfx_None;
	};
	
	holdfunc = function(self, me, view)
		local p = me.player
		local soap = p.soaptable
		local xS = p.xSlinger
		local hand = xS:hand()
		local skin = me.skin
		
		local oldalt = self:get("alternate", skin)
		if xS.delay <= 1
			if (not P_IsObjectOnGround(me))
			and (p.pflags & PF_JUMPED)
				self:set("alternate", true, skin)
			else
				self:set("alternate", false, skin)
			end
		end
		
		local alt = self:get("alternate", skin)
		if not xS.reload
			if (oldalt == false) and (alt == true)
				S_StartSound(nil, sfx_p_s3_3, p)
			elseif (oldalt == true) and (alt == false)
				S_StartSound(nil, sfx_p_s3_4, p)
			end
		end
		
		local grow = self:get("grow", skin)
		local ammo = min(self:get("ammo", skin), 3)
		if (xS.reload) then ammo = 0; end
		view.spritexscale = $ + (grow * FU/28)
		view.spriteyscale = view.spritexscale
		view.extravalue1 = (3 - ammo)
		--view.frame = ($ &~FF_FRAMEMASK)|view.extravalue1
		if grow > 0
			self:change("grow", -1, skin)
		end
	end;
	usefunc = function(self, me)
		if (me.player.ze2.crouching and P_IsObjectOnGround(me)) then return true end
		
		local skin = me.skin
		local alt = self:get("alternate", skin)
		S_StartSound(me, alt and sfx_p_s3_5 or sfx_p_s3_2)
		self:set("grow", 6, skin)
		
		local height = FixedDiv(me.height, me.scale)
		local top_layer = P_SpawnMobjFromMobj(me,
			P_ReturnThrustX(nil, me.angle, 60*FU) + P_ReturnThrustX(nil, me.angle - ANGLE_90, 32*FU),
			P_ReturnThrustY(nil, me.angle, 60*FU) + P_ReturnThrustY(nil, me.angle - ANGLE_90, 32*FU),
			10*FU, MT_SOAP_WALLBUMP
		)
		top_layer.nothink = true
		top_layer.flags = $|MF_NOGRAVITY
		top_layer.state = S_SOAP_HITM_RSPRK
		top_layer.fuse = top_layer.tics
		top_layer.spritexscale = FU
		top_layer.spriteyscale = top_layer.spritexscale
		top_layer.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
		top_layer.dispoffset = 200
		top_layer.followthis = me
		top_layer.followrelative = true
		top_layer.reloffsets = {x = top_layer.x - me.x, y = top_layer.y - me.y, z = top_layer.z - me.z}
		top_layer.dontdrawforviewmobj = me
		--top_layer.colorized = true
		--top_layer.color = elec_sparkcolors[P_RandomRange(1, #elec_sparkcolors)]
	end;
	missile_spawn = function(self, me, shot)
		SoapZ_Effect.Give(me, "blaster.slowdown", {
			normalspeed_multiplier = FixedDiv(tofixed("0.04"), Paint.SPLAT2WALKSPEED),
		}, self:get("firerate", skin) - 6, false)
		
		shot.isMissile = false
		local skin = me.skin
		local alt = self:get("alternate", skin)
		local prefix = alt and "alt_" or ""
		
		shot.str_tics			= self:get(prefix.."str_tics", skin)
		shot.str2brk_maxspeed	= self:get(prefix.."str2brk_maxspeed", skin)
		shot.brk_airresist		= self:get(prefix.."brk_airresist", skin)
		shot.brk_gravity		= self:get(prefix.."brk_gravity", skin)
		shot.brk2fre_minz		= self:get(prefix.."brk2fre_minz", skin)
		shot.brk2fre_minxy		= self:get(prefix.."brk2fre_minxy", skin)
		shot.brk2fre_tics		= self:get(prefix.."brk2fre_tics", skin)
		shot.fre_airresist		= self:get(prefix.."fre_airresist", skin)
		shot.fre_gravity		= self:get(prefix.."fre_gravity", skin)
		shot.crs_guideframe		= self:get(prefix.."crs_guideframe", skin)
		shot.lifespan = 0
		shot.s_state = Paint.SS_STRAIGHT
		
		shot.inner_radius		= self:get(prefix.."inner_radius", skin)
		shot.inner_knockback	= self:get(prefix.."inner_knockback", skin)
		shot.inner_damage		= self:get(prefix.."inner_damage", skin)
		shot.outer_radius		= self:get(prefix.."outer_radius", skin)
		shot.outer_knockback	= self:get(prefix.."outer_knockback", skin)
		shot.outer_damage		= self:get(prefix.."outer_damage", skin)
		shot.powerful = true
		
		local velpre = self:get("velocity_precision", skin)
		local speed = self:get(prefix.."spawnspeed", skin)
		speed = FixedDiv($, max(velpre - 1, 1)*FU)
		
		-- im lay-zee
		local momvector = Vec3.MobjMomToVec(shot):Normalize()
		momvector = Vec3.Mul(momvector, speed)
		momvector:ToMobjMom(shot, true)
		
		local radius = FixedMul(self:get(prefix.."shot_radius", skin), me.scale)
		shot.radius = radius
		shot.height = radius * 2
		
		P_TryMove(shot, shot.x + me.momx, shot.y + me.momy, true)
		shot.z = clamp(shot.floorz, $ + me.momz, shot.ceilingz - shot.height)
		shot.forceknockback = self:get(prefix.."knockback", skin)
		shot.isMissile = true
	end;
})
ZE2.Shop.listItem("blaster", 1650)

local function P_ClosestPointOnLine3D(p, lstart, lend)
	local t,d
	local V = Vec3.Sub(lend, lstart)
	local c = Vec3.Sub(p, lstart)
	
	d = R_PointTo3DDist(lstart.x,lstart.y,lstart.z, lend.x,lend.y,lend.z)
	if d <= 0 then return lstart, 0, 0; end
	
	local n = Vec3.Div(Vec3.New(V.x, V.y, V.z), d)
	t = Vec3.Dot(n, c)
	
	if t <= 0
		return lstart, t, d
	elseif t >= d
		return lend, t, d
	end
	
	n = $ * t
	return Vec3.Add(lstart, n), t, d
end
local function MobjIntersectsRay(start, destination, radius, height, mobj)
	local intersect, fraction, dist = P_ClosestPointOnLine3D(Vec3.MobjPosToVec(mobj), start, destination)
	intersect = Vec3.New(intersect.x, intersect.y, intersect.z - height / 2)
	if (abs(intersect.x - mobj.x) <= (mobj.radius + radius))
	and (abs(intersect.y - mobj.y) <= (mobj.radius + radius))
	and (
		(mobj.z <= (intersect.z + height)) -- check overhead
		and ((mobj.z + mobj.height) >= intersect.z) -- check underhead
	) then
		return true, intersect, fraction, dist
	end
	return false, nil, 0,0
end

local local_angle = 0
local local_aiming = 0
addHook("PlayerCmd",function(p,cmd)
	local_angle = cmd.angleturn << 16
	local_aiming = cmd.aiming << 16
end)

local this_raycast
local altfrac = 0
-- regular post think!!! not Takis_Hook!!!!
addHook("PostThinkFrame", do
	if isdedicatedserver then return end
	if not SOAP_CV.FindVar("showhud").value then return end
	
	local p = displayplayer
	if not (p and p.valid) then return end
	local me = p.mo
	if not (me and me.valid) then return end
	
	if (p ~= consoleplayer)
		local_angle = p.cmd.angleturn << 16
		local_aiming = p.cmd.aiming << 16
	end
	
	if not p["xSlinger[]"] then return end
	
	local xS = p.xSlinger
	if not xS:inv_get() then return end

	local hand = xS:hand()
	local selection = xS.slot
	local iteminfo = xS:slot_get(selection)
	if not iteminfo then return end
	if iteminfo.id ~= "blaster" then return end
	
	local skin = me.skin
	local alt = hand:get("alternate", skin)
	local prefix = alt and "alt_" or ""
	altfrac = P_Lerp(FU*3/5, $, alt and FU or 0)
	
	-- idk why but if we spawn a MT_RAY it acts weird going over fofs,
	-- even if you set its flags. MT_THOK doesnt have this issue though..?
	local ray = P_SpawnMobjFromMobj(me, 0,0,0, MT_THOK)
	
	-- xslinger only ever uses the defined height of the missile, so
	-- do that too
	local thisheight = FixedMul(hand:get("shot_radius", skin) * 2, me.scale)
	local shotz
	do
		local h = me.height
		local newheight = (41 * h / 48)
		
		if me.eflags & MFE_VERTICALFLIP then
			shotz = me.z + h - newheight
		else
			shotz = me.z + newheight - thisheight
		end
	end
	P_SetOrigin(ray,
		me.x + P_ReturnThrustX(nil, local_angle, FU),
		me.y + P_ReturnThrustY(nil, local_angle, FU),
		shotz
	)
	
	ray.flags = MF_NOCLIPTHING|MF_NOGRAVITY|MF_NOBLOCKMAP
	ray.health = 1
	ray.fuse = 1
	ray.tics = ray.fuse
	ray.flags2 = $|MF2_DONTDRAW
	
	ray.str_tics			= hand:get(prefix.."str_tics", skin)
	ray.str2brk_maxspeed	= hand:get(prefix.."str2brk_maxspeed", skin)
	ray.brk_airresist		= hand:get(prefix.."brk_airresist", skin)
	ray.brk_gravity			= hand:get(prefix.."brk_gravity", skin)
	ray.brk2fre_minz		= hand:get(prefix.."brk2fre_minz", skin)
	ray.brk2fre_minxy		= hand:get(prefix.."brk2fre_minxy", skin)
	ray.brk2fre_tics		= hand:get(prefix.."brk2fre_tics", skin)
	ray.fre_airresist		= hand:get(prefix.."fre_airresist", skin)
	ray.fre_gravity			= hand:get(prefix.."fre_gravity", skin)
	ray.crs_guideframe		= hand:get(prefix.."crs_guideframe", skin)
	ray.lifespan = 0
	ray.s_state = Paint.SS_STRAIGHT
	
	local velpre = hand:get("velocity_precision", skin)
	local speed = P_Lerp(altfrac, hand:get("spawnspeed", skin), hand:get("alt_spawnspeed", skin))
	speed = FixedDiv($, max(velpre - 1, 1)*FU)
	
	local momvector = Vec3.SphereToCartesian(local_angle, local_aiming)
	momvector = Vec3.Mul(momvector, speed)
	momvector:ToMobjMom(ray, true)
	
	local radius = FixedMul(hand:get(prefix.."shot_radius", skin), me.scale)
	ray.radius = radius
	ray.height = radius * 2
	
	-- then cast it
	-- i know theres a lot of code duplication in here,
	-- but i reaaaaally wanna limit the amount of functions
	-- i call in here
	local startposition = Vec3.New(
		ray.x, ray.y, ray.z
	)
	local blockadj = 220*FU
	
	local x = ray.x
	local y = ray.y
	local momx = ray.momx
	local momy = ray.momy
	local momz = ray.momz
	while ray.health > 0
		if (ray.z <= ray.floorz or ray.z + ray.height >= ray.ceilingz)
			if not ray.blocked
				ray.blocked = {x = ray.x, y = ray.y, z = ray.z}
				ray.momx = momx
				ray.momy = momy
				ray.momz = momz
				ray.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
			end
		end
		P_RailThinker(ray)
		if (ray.z <= ray.floorz or ray.z + ray.height >= ray.ceilingz)
			if not ray.blocked
				ray.blocked = {x = ray.x, y = ray.y, z = ray.z}
				ray.momx = momx
				ray.momy = momy
				ray.momz = momz
				ray.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
			end
		end
		
		ray.lifespan = $ + 1
		bulletSimpleState(ray)
		
		if ray.lifespan >= ray.crs_guideframe
			ray.momx,ray.momy,ray.momz = 0,0,0
			ray.health = 0
			break
		end
		
		for subtick = 1, velpre - 1, 1
			x = ray.x
			y = ray.y
			P_XYMovement(ray)
			if (not ray and ray.valid or not P_ZMovement(ray) or (ray.z <= ray.floorz or ray.z + ray.height >= ray.ceilingz))
			or (ray.x == x and ray.y == y)
				if not ray.blocked
					ray.blocked = {x = ray.x, y = ray.y, z = ray.z}
					ray.momx = momx
					ray.momy = momy
					ray.momz = momz
					ray.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
				end
			end
			
			if not P_TryMove(ray, ray.x, ray.y, true)
				if not ray.blocked
					ray.blocked = {x = ray.x, y = ray.y, z = ray.z}
					ray.momx = momx
					ray.momy = momy
					ray.momz = momz
					ray.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
				end
			end
		end
	end
	
	local endposition
	if ray.blocked
		endposition = Vec3.New(
			ray.blocked.x, ray.blocked.y, ray.blocked.z
		)
	else
		endposition = Vec3.New(
			ray.x, ray.y, ray.z
		)
	end
	
	local bounds = {
		x1 = min(startposition.x - blockadj, endposition.x - blockadj),
		x2 = max(startposition.x + blockadj, endposition.x + blockadj),
		y1 = min(startposition.y - blockadj, endposition.y - blockadj),
		y2 = max(startposition.y + blockadj, endposition.y + blockadj),
	}
	local ray_radius = ray.radius
	local ray_height = ray_radius * 2
	local intersections = {}
	local foundany = false
	local foundcount = 0
	-- THEN.... search objects we can hit
	searchBlockmap("objects",function(ray, found)
		if not (found and found.valid) then return end
		if not (found.health) then return end
		if not (found.flags & MF_SHOOTABLE) then return end
		if (found.player and found.player.spectator) then return end
		if (found == me) then return end
		
		-- teammate
		if found.team == me.team and not FriendlyFire() then return end
		
		local hits, intersect, fraction, dist = MobjIntersectsRay(startposition, endposition, ray_radius,ray_height, found)
		if not hits then return end
		
		local distancefraction
		if dist > 0
			distancefraction = FixedDiv(fraction, dist)
		else -- um
			distancefraction = foundcount
		end
		table.insert(intersections, {
			distance = distancefraction,
			mobj = found,
			intersection = intersect
		})
		foundany = true
		foundcount = $ + 1
	end, ray,
		bounds.x1, bounds.x2, bounds.y1, bounds.y2
	)
	
	if foundany
		table.sort(intersections, function(a,b)
			return a.distance < b.distance
		end)
		local inter = intersections[1].intersection
		ray.hits = {
			x = inter.x, y = inter.y, z = inter.z
		}
	end
	this_raycast = ray
end)

local crosshairwasdisabled = false
addHook("HUD",function(v,p,cam)
	if crosshairwasdisabled
		hud.enable("crosshair")
		crosshairwasdisabled = false
	end
	
	local inze2 = (gametype == GT_ZE2 or (ZE2 and ZE2.isGametype()))
	if not inze2 then return end
	-- if cam.chase then return end
	if not p["xSlinger[]"] then
		return
	end
	
	local xS = p.xSlinger
	if not xS:inv_get() then
		return
	end
	
	local me = p.realmo
	if not (me and me.valid and me.health) then return end
	local skin = me.skin
	local hand = xS:hand()
	local selection = xS.slot
	local iteminfo = xS:slot_get(selection)
	if not iteminfo then return end
	if iteminfo.id ~= "blaster" then return end
	if not (this_raycast and this_raycast.valid) then return end
	
	hud.disable("crosshair")
	crosshairwasdisabled = true
	
	local crs = this_raycast
	local r = K_GetScreenCoords(v,p,cam, {x = crs.x, y = crs.y, z = crs.z + crs.height/2}, {anglecliponly = true})
	if not r.onscreen then return end
	
	local color = v.getColormap(TC_DEFAULT, p.skincolor)
	local scale = FU/4
	scale = P_Lerp(altfrac, $, $ * 2)
	local crouching = (p.ze2.crouching and P_IsObjectOnGround(me))
	local opaque = (xS.reload or crouching) and V_50TRANS or 0
	local transparent = (xS.reload or crouching) and V_80TRANS or V_20TRANS
	
	v.dointerp(true)
	v.drawScaled(r.x, r.y, scale, v.cachePatch("PAINT_CR_BASE"), transparent)
	if crs.hits
		local block = crs.hits
		local r = K_GetScreenCoords(v,p,cam, {x = block.x, y = block.y, z = block.z + crs.height/2}, {anglecliponly = true})
		v.drawScaled(r.x, r.y, scale, v.cachePatch("PAINT_CR_BLOCKED"), opaque, color)
		v.drawScaled(r.x, r.y, scale, v.cachePatch("PAINT_CR_HIT"), opaque, color)
	
	elseif crs.blocked
		local block = crs.blocked
		local r = K_GetScreenCoords(v,p,cam, {x = block.x, y = block.y, z = block.z + crs.height/2}, {anglecliponly = true})
		v.drawScaled(r.x, r.y, scale, v.cachePatch("PAINT_CR_BLOCKED"), opaque, color)
	else
		v.drawScaled(r.x, r.y, scale, v.cachePatch("PAINT_CR_RET"), opaque)
	end
	v.dointerp(false)
end,"game")
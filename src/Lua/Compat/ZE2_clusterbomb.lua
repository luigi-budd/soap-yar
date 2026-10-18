local P_RandomFixed = P_RandomFixed
local Soap_RandomFixedRange = Soap_RandomFixedRange
local Vec3 = Vec3
local Soap_DustRing = Soap_DustRing

local cv_friendlyfire = SOAP_CV.FindVar("friendlyfire")
local function FriendlyFire()
	local gt_settings = xSlinger.getGametypeSettings()
	return cv_friendlyfire.value or gt_settings.friendlyfire
end

sfxinfo[SafeFreeslot("sfx_zc_c0")] = {
	caption = "Clusterbomb charged",
}
sfxinfo[SafeFreeslot("sfx_zc_c1")] = {
	caption = "Clusterbomb charged",
}
for i = 0,3
	sfxinfo[SafeFreeslot("sfx_zc_s"..i)] = {
		caption = "Shaking",
	}
end
sfxinfo[SafeFreeslot("sfx_zc_a0")] = {
	caption = "Fizzing",
}
sfxinfo[SafeFreeslot("sfx_zc_a1")] = {
	caption = "Fizzing",
}
sfxinfo[SafeFreeslot("sfx_zc_e")] = {
	caption = "Explosion",
	flags = SF_X2AWAYSOUND
}
sfxinfo[SafeFreeslot("sfx_zc_ee")] = {
	caption = "\x83".."Energized!\x80",
}
for i = 0, 4
	sfxinfo[SafeFreeslot("sfx_zc_h"..i)] = {
		caption = "Clusterbomb hits",
	}
end

local function bottlesound(mo)
	local sound = sfx_zc_h0
	if mo.extravalue2
		sound = P_RandomRange(sfx_zc_h1, sfx_zc_h4)
	end
	mo.extravalue2 = $ + 1
	mo.rollangle = $ + ANGLE_45
	S_StartSound(mo, sound)
	S_StartSound(mo, sound)
end

SafeFreeslot("S_CLUSTERBOMB")
states[S_CLUSTERBOMB] = {
	sprite = SPR_SOAP_GFX,
	frame = 77|FF_SEMIBRIGHT,
	tics = 1,
	action = function(m)
		if not m.isMissile then return end
		local blink = m.sizeblink or 0
		m.spritexscale = (FU * 3/2) + (FU/5 * blink)
		m.spriteyscale = m.spritexscale
	end,
	nextstate = S_CLUSTERBOMB
}

SafeFreeslot("S_CLUSBOM_CHARGEDMAX")
states[S_CLUSBOM_CHARGEDMAX] = {
	sprite = SPR_SOAP_GFX,
	frame = 65|FF_FULLBRIGHT|FF_ADD|FF_ANIMATE,
	tics = (11 * 1),
	var1 = 10,
	var2 = 1,
}

local function spawn_sweat_mobjs(mo, parent)
	local height = FixedDiv(mo.height,mo.scale)/FU
	local sweat = P_SpawnMobjFromMobj(mo,
		P_RandomRange(-16,16)*FU, --+ FixedDiv(me.momx,me.scale),
		P_RandomRange(-16,16)*FU, --+ FixedDiv(me.momy,me.scale),
		P_RandomRange(height/2,height)*FU,
		MT_SOAP_WALLBUMP
	)
	P_Thrust(sweat, 
		mo.angle + FixedAngle(Soap_RandomFixedRange(-45*FU,45*FU)),
		-FixedMul(Soap_RandomFixedRange(2*FU,5*FU), mo.scale)
	)
	sweat.momx = $ + mo.momx/2
	sweat.momy = $ + mo.momy/2
	sweat.momz = $ + mo.momz
	P_SetObjectMomZ(sweat, Soap_RandomFixedRange(5*FU,8*FU))
	sweat.fuse = TR*3/4
	sweat.frame = B|FF_TRANS30
	sweat.colorized = false
	sweat.sweat = true
	sweat.dontdrawforviewmobj = parent
	return sweat
end

local elec_sparkcolors = {
	SKINCOLOR_CERULEAN, SKINCOLOR_COBALT, SKINCOLOR_MIDNIGHT, SKINCOLOR_SAPPHIRE,
	SKINCOLOR_GALAXY, SKINCOLOR_VAPOR, SKINCOLOR_DUSK, SKINCOLOR_MAJESTY,
}
local damagecolors_elec = {
	unpack(elec_sparkcolors),
	SKINCOLOR_MINT, SKINCOLOR_SEAFOAM, SKINCOLOR_ISLAND, SKINCOLOR_BOTTLE,
	SKINCOLOR_JADE, SKINCOLOR_MASTER,
	SKINCOLOR_TOPAZ, SKINCOLOR_GOLDENROD, SKINCOLOR_PEAR, SKINCOLOR_LEMON,
	SKINCOLOR_LIME, SKINCOLOR_PERIDOT, SKINCOLOR_HEADLIGHT, SKINCOLOR_CHARTREUSE
}
local clrlen = #damagecolors_elec
local function exploderadius(mo, exradius)
	mo.forcedamage = mo.realdamage
	searchBlockmap("objects", function(mo, foundmobj)
		if not (foundmobj.health) then return end
		if not (foundmobj.flags & MF_SHOOTABLE) then return end
		local dist = R_PointTo3DDist(mo.x, mo.y, mo.z, foundmobj.x, foundmobj.y, foundmobj.z)
		if (dist > exradius + foundmobj.radius) then return end
		
		-- teammate
		if foundmobj.team == mo.team and not FriendlyFire()
			-- only on the first explosion...
			if mo.timesexploded then return end
			
			local play = foundmobj.player
			if (play and play.valid)
				S_StartSound(nil, sfx_zc_ee, play)
				
				local rad = FixedDiv(foundmobj.radius, foundmobj.scale)
				local hei = FixedDiv(foundmobj.height, foundmobj.scale)
				local rang = R_PointToAngle(foundmobj.x,foundmobj.y)
				for i = 0,16
					local w = P_SpawnMobjFromMobj(foundmobj,
						Soap_RandomFixedRange(-rad, rad),
						Soap_RandomFixedRange(-rad, rad),
						Soap_RandomFixedRange(0, hei),
						MT_SOAP_SPEEDLINE
					)
					w.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
					w.blendmode = AST_ADD
					w.angle = rang + ANGLE_90
					w.rollangle = ANGLE_90
					w.tracer = foundmobj
					w.color = SKINCOLOR_MASTER
					w.alpha = FU * 3/4
					w.spriteyscale = P_RandomRange(FU*8/10, FU*12/10)
					w.spritexscale = P_RandomRange(FU*9/10, FU*11/10)
					local off = P_RandomRange(0, 4)
					w.tics = $ + off
					w.anim_duration = $ + off
					
					w.momx = $ + foundmobj.momx
					w.momy = $ + foundmobj.momy
					w.momz = $ + foundmobj.momz
					w.drawonlyforplayer = play
				end
				
				foundmobj:give_effect("energy_drink", {
					normalspeed_multiplier = 10*FRACUNIT/7,
					damage_multiplier = 2*FRACUNIT,
					knockback_multiplier = 5*FRACUNIT,
				}, TR*3/2, true)
			end
		else -- enemy
			P_DamageMobj(foundmobj, mo, mo.target, mo.forcedamage)
		end
	end, mo,
		mo.x - exradius, mo.x + exradius,
		mo.y - exradius, mo.y + exradius
	)
	mo.forcedamage = nil
	
	/*
	local max = 16
	local fa = FixedDiv(360*FU, max*FU)
	local inner = exradius
	for i = 0,max-1
		for j = 0, (max*2)-1
			local v = SphereToCartesian(FixedAngle(fa*i), FixedAngle(fa*j))
			local part = P_SpawnMobjFromMobj(mo,
				FixedMul(inner,v.x),
				FixedMul(inner,v.y),
				FixedMul(inner,v.z),
				MT_THOK
			)
			part.color = mo.color
			part.scale = $ / 2
		end
	end
	*/
	
	local innerrad = exradius * 4/5
	local outerrad = exradius / 2
	for i = 1,26
		local ha = FixedAngle(P_RandomRange(0,36) * 10*FU)
		local va = FixedAngle(P_RandomRange(0,18) * 10*FU)
		local v = SphereToCartesian(ha,va)
		local s = P_SpawnMobjFromMobj(mo,
			FixedMul(innerrad, v.x),
			FixedMul(innerrad, v.y),
			FixedMul(innerrad, v.z),
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
		local f = P_SpawnMobjFromMobj(mo,
			FixedMul(thisdist, v.x),
			FixedMul(thisdist, v.y),
			FixedMul(thisdist, v.z),
			MT_SOAP_WALLBUMP
		)
		f.spritexscale = P_RandomRange(FU*3/4, FU*6/5) + (FU/3 * mo.timesexploded)
		f.spriteyscale = f.spritexscale
		f.state = S_SOAP_HITM_ESW
		f.tics = 1
		f.extravalue1 = $ + P_RandomRange(1,3)*3
		f.repeats = P_RandomRange(0, 3)
		f.renderflags = $|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)|RF_ALWAYSONTOP|RF_NOCOLORMAPS
		f.color = damagecolors_elec[P_RandomRange(1, clrlen)]
		
		-- clamp just in case...
		f.tics = max($, 1)
		f.extravalue1 = max($, 1)
		
		P_3DThrust(f, ha,va, speed)
		f.nothink = true
		f.movefactor = P_RandomRange(FU*69/100, FU*86/100)
		f.movefactoraffectsz = true
		f.flags = $|MF_NOGRAVITY
		f.blendmode = AST_ADD
	end
	
	-- 36
	local vfxscale = FixedDiv(exradius, 40*FU)
	local fa = FixedDiv(360*FU, 4*FU)
	for i = 1,2
		local s = P_SpawnMobjFromMobj(mo,
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
			destscale = 0
		}
		s.color = SKINCOLOR_MASTER
	end

	local top_layer = P_SpawnMobjFromMobj(mo, 0,0,-80*FU, MT_PARTICLE)
	top_layer.state = S_SOAP_HITM_RSPRK
	top_layer.fuse = top_layer.tics
	top_layer.spritexscale = FU * 4
	top_layer.spriteyscale = top_layer.spritexscale
	top_layer.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
	top_layer.dispoffset = 200
	top_layer.colorized = true
	top_layer.color = elec_sparkcolors[P_RandomRange(1, #elec_sparkcolors)]
	mo.timesexploded = $ + 1
end

-- missile definition
-- clustergal
local WARN_TICS_FIRST = 6
local WARN_TICS = 3
local xsmissile_cluster = xSlinger.registerMissile("CLUSTERBOMB", {
	speed = 55*FU,
	displayname = "Clusterbomb",
	state = S_CLUSTERBOMB,
	deathsound = sfx_none,
	externaldeathsound = true,
	-- delflags = MF_NOGRAVITY,
	addflags = MF_NOCLIPTHING|MF_NOBLOCKMAP,
	safeground = true,
	radius = 13*FU,
	height = 26*FU,

	tick = function(self, pmo, mo)
		local floorhit = (mo.z <= mo.floorz)
		local ceilinghit = (mo.z + mo.height == mo.ceilingz)
		local prevmomz = mo.bouncering_prevmomz or 0
		local newprevmomz = FixedDiv(abs(max(6*FU,prevmomz)), 5*FU/4)
		
		if (ceilinghit) then -- bounce
			Soap_SpawnBumpSparks(mo, nil, line, false, FU / 2, true)
			bottlesound(mo)
			
			local sign = (ceilinghit) and -1 or 1
			P_SetObjectMomZ(mo, newprevmomz * sign, true)
			
			if floorhit
				mo.momx = $ / 2
				mo.momy = $ / 2
			end
		elseif floorhit and not mo.washitfloor
			if R_PointToDist2(0,0, mo.momx,mo.momy) >= 20 * mo.scale
			and not mo.setfuse and mo.explosions > 1
				P_SetObjectMomZ(mo, 3*FU)
			end
			mo.momx = $ / 3
			mo.momy = $ / 3
			bottlesound(mo)
			
			local sfx = P_SpawnGhostMobj(mo)
			sfx.fuse = 5*TR
			sfx.tics = sfx.fuse
			sfx.flags2 = $|MF2_DONTDRAW
			S_StartSound(sfx, mo.setfuse and sfx_zc_a1 or sfx_zc_a0)
		end
		
		local doblink = false
		if not P_IsObjectOnGround(mo)
			mo.momx = FixedMul($, mo.airdrag)
			mo.momy = FixedMul($, mo.airdrag)
			mo.momz = $ - (FixedMul(mo.scale, mo.gravmul) * P_MobjFlip(mo))
			mo.momz = FixedMul($, mo.airdrag)
		else
			if mo.fakefuse
				if not mo.setfuse
					--S_StartSound(mo, sfx_zc_a1)
					mo.setfuse = true
				end
				doblink = (mo.fakefuse % 2)
				mo.fakefuse = $ - 1
			else
				mo.fakefuse = WARN_TICS
				--Soap_ImpactVFX(mo,nil, 0, FU*3/2, nil,nil, DMG_ELECTRIC)
				
				local sfx = P_SpawnGhostMobj(mo)
				sfx.fuse = 2*TR
				sfx.tics = sfx.fuse
				sfx.flags2 = $|MF2_DONTDRAW
				S_StartSound(sfx, sfx_zc_e)
				
				P_StartQuake(20*FU, 8, {mo.x,mo.y,mo.z}, mo.explosionradius*3/2)
				exploderadius(mo, mo.explosionradius)
				P_Thrust(mo, mo.angle + FixedAngle(Soap_RandomFixedRange(-8*FU,8*FU)), 12*mo.scale)
				P_SetObjectMomZ(mo, 8*FU)
				
				mo.realdamage = $ + mo.damageinc
				mo.explosionradius = $ + mo.radiusinc
				mo.explosions = $ - 1
				mo.blinking = 3
				mo.sizeblink = 8
				if mo.explosions <= 0
					Soap_ImpactVFX(mo, nil, 0,FU/2)
					P_KillMobj(mo); return
				end
			end
		end
		if mo.setfuse
			spawn_sweat_mobjs(mo)
		end
		if mo.blinking or doblink
			mo.translation = "AllWhite"
			mo.renderflags = $|RF_FULLBRIGHT
			mo.blinking = max($ - 1, 0)
		else
			mo.translation = nil
			mo.renderflags = $ &~RF_FULLBRIGHT
		end
		mo.sizeblink = max($ - 1, 0)
		
		mo.rollangle = $ + FixedAngle(R_PointTo3DDist(0,0,0, mo.momx,mo.momy,mo.momz) / 2)
		mo.washitfloor = floorhit
		mo.bouncering_prevmomz = mo.momz
	end,
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
		
		local newangle = line_ang - ANGLE_90*(P_PointOnLineSide(mo.x,mo.y, line) and 1 or -1)
		P_InstaThrust(mo,
			newangle,
			-speed
		)
		mo.angle = newangle + ANGLE_180
		bottlesound(mo)
		return true
	end
})

local CHARGE_TIME = 2*TR
local CHARGE_MOVECHANGE = 7
local CHARGE_PANCHANGE = 6
local CHARGE_JUMPCHANGE = 5
xSlinger.registerItem("clusterbomb", {
	-- HUD
	displayname = "Clusterbomb";
	icon = "CLUSTERBIND";
	background_color = SKINCOLOR_MASTER,
	animation_time = TR / 2;

	-- Missile properties
	dropstate = S_CLUSTERBOMB;
	hold_object = {
		state = S_CLUSTERBOMB;
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
	
	color = SKINCOLOR_JADE;
	missile = "CLUSTERBOMB";
	firerate = 4*TR;
	damage = 0;
	droppable = true;
	count = 4;
	maxcount = 12;

	knockback = 30*FRACUNIT;
	knockback_time = 7;

	autouse = false;
	semiautouse = true;
	
	chargetime = 0;
	chargeincwait = 0;
	shakewait = 0;
	shakeforce = FU;
	shakeanim = 0;
	charging = false;
	
	sounds = {};
	holdfunc = function(self, me)
		local p = me.player
		local soap = p.soaptable
		local xS = p.xSlinger
		local hand = xS:hand()
		local skin = me.skin
		
		if soap.fire == 1
		and not hand:get("firerate_left",skin)
			hand:set("charging", true, skin)
		end
		
		if hand:get("charging") and soap.fire
			local prevcharge = hand:get("chargetime", skin)
			if prevcharge < CHARGE_TIME
				hand:change("chargetime", 1, skin)
			end
			
			local shaketime = 10
			local shakeforce = 0
			local chargeinc = 0
			do
				local mycdir = (p.cmd.angleturn<<16) + R_PointToAngle2(0, 0, p.cmd.forwardmove << 16, -p.cmd.sidemove << 16)
				local oldcdir = (soap.last.cmd.angleturn<<16) + R_PointToAngle2(0, 0, soap.last.cmd.forwardmove << 16, -soap.last.cmd.sidemove << 16)
				
				if abs(oldcdir - mycdir) >= ANG30
					chargeinc = CHARGE_MOVECHANGE
					shaketime = 3
					shakeforce = FU*3/4
				end
			end
			do
				if abs(soap.last.cmd.angleturn - p.cmd.angleturn) >= (ANG15>>16)
					chargeinc = CHARGE_PANCHANGE
					shaketime = 5
					shakeforce = max($,FU/2)
				end
				if abs(soap.last.cmd.aiming - p.cmd.aiming) >= (ANG15>>16)/2
					chargeinc = CHARGE_PANCHANGE
					shaketime = 5
					shakeforce = max($,FU/2)
				end
			end
			if (soap.jump == 1)
				chargeinc = CHARGE_JUMPCHANGE
				shaketime = 7
				shakeforce = max($,FU/3)
			end
			
			if hand:get("chargeincwait", skin)
				hand:change("chargeincwait", -1, skin)
			end
			if chargeinc
				if not hand:get("chargeincwait", skin)
					hand:change("chargetime", chargeinc, skin)
					hand:set("chargeincwait", 8, skin)
				end
			end
			
			local fizzfreq = 9
			local chargetime = hand:get("chargetime", skin)
			if chargetime > CHARGE_TIME
				hand:set("chargetime", CHARGE_TIME, skin)
			else
				if chargetime == CHARGE_TIME
					fizzfreq = 2
				elseif chargetime >= CHARGE_TIME/2
					fizzfreq = 4
				end
			end
			
			local chargedup = 0
			if chargetime >= CHARGE_TIME/2 and prevcharge < CHARGE_TIME/2
				S_StartSound(nil, sfx_zc_c0, p)
				chargedup = 1
			end
			if chargetime >= CHARGE_TIME and prevcharge < CHARGE_TIME
				local view = xS.viewmobj
				local v = P_SpawnMobjFromMobj(view, 0,0,0, MT_SOAP_FREEZEGFX)
				v.state = S_CLUSBOM_CHARGEDMAX
				v.color = view.color
				v.tracer = view
				v.scale = $ * 2
				v.spriteyoffset = 10*FU
				v.dispoffset = 200
				v.dontdrawforviewmobj = me
				
				S_StartSound(nil, sfx_zc_c1, p)
				chargedup = 2
			end
			if chargedup
				local view = xS.viewmobj
				local v = P_SpawnMobjFromMobj(view, 0,0,0, MT_SOAP_WALLBUMP)
				v.nothink = true
				v.flags = $|MF_NOGRAVITY
				v.followthis = view
				v.tics = -1
				v.fuse = 8
				v.frame = 76|FF_ADD
				v.color = view.color
				
				v.scale = ($*3/4) + (FU/2 * (chargedup-1))
				v.fusefade = 6
				v.fusescale = {
					func = "inquad",
					fuseunder = 8,
					startscale = v.scale,
					destscale = 0
				}
				v.spriteyoffset = 20*FU
				v.dispoffset = -200
				v.dontdrawforviewmobj = me
			end
			
			if hand:get("shakewait", skin) > 0
				hand:change("shakewait", (shaketime ~= 10) and -3 or -1, skin)
			else
				hand:set("shakewait", shaketime, skin)
				S_StartSound(me, P_RandomRange(sfx_zc_s0, sfx_zc_s3))
			end
			
			local newforce = hand:set("shakeforce", P_Lerp(FU/4, hand:get("shakeforce",skin), FU + shakeforce*4), skin)
			local newang = hand:change("shakeanim", 17 * newforce, skin)
			
			xS.viewmobj.z = $ + 10*sin(FixedAngle(newang))
			xS.viewmobj.rollangle = FixedAngle(-18*sin(FixedAngle(newang)))
			xS.viewmobj.spritexoffset = -10*sin(FixedAngle(newang))
			xS.viewmobj.spritexscale = $ + (chargetime*540)
			xS.viewmobj.spriteyscale = xS.viewmobj.spritexscale
			
			if leveltime % fizzfreq == 0
				spawn_sweat_mobjs(xS.viewmobj, me)
				xS.viewmobj.colorized = true
			else
				xS.viewmobj.colorized = false
			end
		elseif hand:get("charging") and not soap.fire
			local missile_info = {
				source = me;
				type = hand.missile;
				angle = me.angle;
				allow_aim = true;
				iteminfo = hand;
				flags2 = hand.flags2;
			}
			local missile = xSlinger.SpawnMissile(missile_info)
			if (missile and missile.valid)
				missile.chargetime = hand:get("chargetime", skin)
				missile.airdrag = FU * 97/100
				missile.gravmul = FU
				missile.fakefuse = WARN_TICS_FIRST
				missile.timesexploded = 0
				missile.explosions = 1
				missile.realdamage = 42
				missile.damageinc = missile.realdamage / 2
				missile.explosionradius = 160*FU
				missile.radiusinc = 35*FU
				missile.shadowscale = FU
				missile.blinking = 0
				missile.sizeblink = 0
				if missile.chargetime >= CHARGE_TIME
					missile.explosions = $ + 2
				elseif missile.chargetime >= CHARGE_TIME/2
					missile.explosions = $ + 1
				end
				S_StartSound(me,sfx_kc5b)
				S_StartSound(me,sfx_s3k51)
				
				local count = hand:change("count", -1, skin)
				if not count then
					xS:hand_clear()
				end
			end
			xS.viewmobj_animation = hand:get("animation_time", skin)
			xS.viewmobj.rollangle = 0
			xS.viewmobj.spritexoffset = 0
			xS.viewmobj.colorized = false
			hand:set("chargetime", 0, skin)
			hand:set("chargeincwait", 0, skin)
			hand:set("shakewait", 0, skin)
			hand:set("firerate_left", hand:get("firerate",skin), skin)
			hand:set("shakeforce", FU, skin)
			hand:set("shakeanim", 0, skin)
			hand:set("charging", false, skin)
			soap.fire_R = 0
		end
	end;
	usefunc = function(self, me)
		local p = me.player
		local soap = p.soaptable
		return true
	end;
})
ZE2.Shop.listItem("clusterbomb", 125)

addHook("HUD",function(v,p,cam)
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
	if not (me and me.valid) then return end
	local skin = me.skin
	local hand = xS:hand()
	local selection = xS.slot
	local iteminfo = xS:slot_get(selection)
	if not iteminfo then return end
	if iteminfo.id ~= "clusterbomb" then return end
	if not hand:get("charging",skin) then return end

	local x,y = 160*FU, 100*FU
	local rad = 10*FU
	local maxsegs = 40
	local timetic = FixedDiv(hand:get("chargetime",skin)*FU, CHARGE_TIME*FU)
	
	local angtotal = 360 * timetic
	local cmap = v.getColormap(TC_DEFAULT, SKINCOLOR_MASTER)
	local patch = v.cachePatch("TA_LIVESFILL_FILL")
	for i = 0,maxsegs
		if timetic == 0 then break end
		
		local angmath = FixedMul(FixedDiv(angtotal, maxsegs*FU), i*FU) - 90*FU
		local angle = FixedAngle(angmath)
		v.drawScaled(
			x + FixedMul(rad, cos(angle)),
			y + FixedMul(rad, sin(angle)),
			FU/8, patch, V_ADD, cmap
		)
	end
end,"game")
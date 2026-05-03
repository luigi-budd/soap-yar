SafeFreeslot("SPR_NSBABY")
SafeFreeslot("S_NSBABY_IDLE")
states[S_NSBABY_IDLE] = {
	sprite = SPR_NSBABY,
	frame = 0|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 7,
	var2 = 2,
	tics = (8*2),
	nextstate = S_NSBABY_IDLE
}
SafeFreeslot("S_NSBABY_LOCKON")
states[S_NSBABY_LOCKON] = {
	sprite = SPR_NSBABY,
	frame = 8|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 8,
	var2 = 2,
	tics = -1,
	nextstate = S_NSBABY_IDLE
}
SafeFreeslot("S_NSBABY_CHASE")
SafeFreeslot("S_NSBABY_TOCHASE")
states[S_NSBABY_TOCHASE] = {
	sprite = SPR_NSBABY,
	frame = 17|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 3,
	var2 = 1,
	tics = 4,
	nextstate = S_NSBABY_CHASE
}
states[S_NSBABY_CHASE] = {
	sprite = SPR_NSBABY,
	frame = 21|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 11,
	var2 = 1,
	tics = 12,
	nextstate = S_NSBABY_CHASE
}
SafeFreeslot("S_NSBABY_TOIDLE")
states[S_NSBABY_TOIDLE] = {
	sprite = SPR_NSBABY,
	frame = 17|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 3,
	var2 = 1,
	tics = 4,
	nextstate = S_NSBABY_IDLE
}

SafeFreeslot("MT_NSBABY")
mobjinfo[MT_NSBABY] = {
	doomednum = -1,
	spawnstate = S_NSBABY_IDLE,
	deathstate = S_NSBABY_IDLE,
	height = 134*FU,
	radius = 67*FU, --lol
	spawnhealth = 1,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY,
}

-- alarm
sfxinfo[SafeFreeslot("sfx_nb_0")] = {
	caption = "/",
	flags = SF_X4AWAYSOUND
}
-- dash
sfxinfo[SafeFreeslot("sfx_nb_1")] = {
	caption = "/",
	flags = SF_X4AWAYSOUND
}
-- problem dash
sfxinfo[SafeFreeslot("sfx_nb_2")] = {
	caption = "/",
	flags = SF_X4AWAYSOUND
}
-- tantrum dash
sfxinfo[SafeFreeslot("sfx_nb_3")] = {
	caption = "/",
	flags = SF_X4AWAYSOUND
}

-- tantrum start
sfxinfo[SafeFreeslot("sfx_nb_4")] = {
	caption = "/",
	flags = SF_X2AWAYSOUND
}
-- tantrum loop
sfxinfo[SafeFreeslot("sfx_nb_5")] = {
	caption = "/",
	flags = SF_X2AWAYSOUND
}
-- tantrum end
sfxinfo[SafeFreeslot("sfx_nb_6")] = {
	caption = "/",
	flags = SF_X2AWAYSOUND
}

local function Baby_SetBaseStats(baby)
	baby.charge_wait = baby.base_charge_wait
	baby.charge_dist = baby.base_charge_dist
	baby.charge_time = baby.base_charge_time
	baby.charge_cool = baby.base_charge_cool
	
	baby.enraged = false
	baby.color = SKINCOLOR_NONE
	baby.colorized = false
	baby.rangecount = 0
	
	S_StopSoundByID(baby, sfx_nb_4)
	S_StopSoundByID(baby, sfx_nb_5)
	S_StartSound(baby, sfx_nb_6)
end
local function Baby_SetRageStats(baby)
	baby.charge_wait = baby.rage_charge_wait
	baby.charge_dist = baby.rage_charge_dist
	baby.charge_time = baby.rage_charge_time
	baby.charge_cool = baby.rage_charge_cool
	
	baby.enraged = true
	baby.color = SKINCOLOR_PEPPER
	baby.colorized = true
	baby.rangecount = 5
	
	S_StartSound(baby, sfx_nb_4)
end

local function Baby_Init(baby)
	baby.aiming = 0
	baby.tics = -1
	
	baby.touchlist = {}
	baby.enraged = false
	baby.rangecount = 0
	
	baby.base_charge_wait = (TR * 3/4) + 3
	baby.base_charge_dist = 2450*FU
	baby.base_charge_time = TR*8/5
	baby.base_charge_cool = 2*TR - baby.base_charge_time
	Baby_SetBaseStats(baby)

	baby.rage_charge_wait = TR * 46/100
	baby.rage_charge_dist = 3600*FU
	baby.rage_charge_time = TR - (baby.rage_charge_wait)
	baby.rage_charge_cool = 0
	
	baby.chargewind = 0
	baby.chargecooldown = P_RandomRange(0, baby.charge_time + baby.charge_cool)
	baby.chargingtics = 0
	baby.charging = (baby.chargecooldown > 0)
	
	baby.start_x = 0
	baby.start_y = 0
	baby.start_z = 0
	baby.end_x = 0
	baby.end_y = 0
	baby.end_z = 0
	
	baby.init = true
	baby.renderflags = RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_ALWAYSONTOP
end

local TELE_DOTS = 52
local function Baby_Telegraph(baby, angle,aim, dist, tics)
	dist = FixedDiv($, TELE_DOTS*FU)
	
	local adjtics = baby.charge_wait - tics
	local rflags = RF_ALWAYSONTOP|RF_FULLBRIGHT|RF_NOCOLORMAPS
	local vec = SphereToCartesian(angle,aim)
	local off = FixedDiv(baby.height,baby.scale) / 2
	for i = 0, TELE_DOTS do
		if ((i-leveltime) / 4) % 2 then continue end
		local frac = FixedDiv(i, TELE_DOTS*FU)
		local vfx = P_SpawnMobjFromMobj(baby,
			FixedMul(dist*i, vec.x),
			FixedMul(dist*i, vec.y),
			FixedMul(dist*i, vec.z) + off,
			MT_PARTICLE
		)
		vfx.frame = A
		vfx.sprite = SPR_SOAP_GFX
		vfx.frame = 37
		vfx.flags = $|MF_NOCLIP|MF_NOGRAVITY|MF_NOCLIPHEIGHT
		
		vfx.color = SKINCOLOR_RED
		
		vfx.renderflags = rflags
		vfx.tics = 2
		vfx.fuse = -1
		
		--vfx.blendmode = AST_ADD
		vfx.scale = $
		vfx.spritexscale = FU * 2
		vfx.spriteyscale = FU / 2
		vfx.scalespeed = FU
		
		if (adjtics <= 4)
			local grow = (FU/4) * (4 - adjtics)
			vfx.spritexscale = $ + grow
			vfx.spriteyscale = $ + grow
		end
		if tics < 10
			vfx.alpha = (FU/10) * tics
		end
	end
	if adjtics == 0
		local top_layer = P_SpawnMobjFromMobj(baby, 0,0,off, MT_PARTICLE)
		top_layer.state = S_SOAP_HITM_RSPRK
		top_layer.spritexscale = $ * 6
		top_layer.spriteyscale = top_layer.spritexscale
		top_layer.renderflags = $|rflags
		top_layer.spriteyoffset = -20*FU
		top_layer.fuse = top_layer.tics
		
		baby.state = S_NSBABY_LOCKON
	end
end

local base_easefunc = ease.outquint
local rage_easefunc = ease.outquad -- ease.inoutsine
local lunge_steps = 10
local lunge_random = 64 * FU
local function Baby_DoLunge(baby, angle,aim, dist, tics)
	local adjtics = baby.charge_time - tics
	local vec = SphereToCartesian(angle,aim)
	if adjtics == 0
		S_StartSound(baby, (baby.enraged) and sfx_nb_3 or sfx_nb_1)
		baby.state = S_NSBABY_TOCHASE
		
		baby.start_x = baby.x
		baby.start_y = baby.y
		baby.start_z = baby.z
		
		baby.end_x = baby.x + FixedMul(dist, vec.x)
		baby.end_y = baby.y + FixedMul(dist, vec.y)
		baby.end_z = baby.z + FixedMul(dist, vec.z)
		
		baby.flags = $|MF_SPECIAL
		baby.touchlist = {}
	end
	
	local easefunc = (baby.enraged) and rage_easefunc or base_easefunc
	local prevfrac = max(FixedDiv(adjtics - 1, baby.charge_time), 0)
	local nextfrac = FixedDiv(adjtics, baby.charge_time)
	-- for collision...
	local start = {
		x = easefunc(prevfrac, baby.start_x, baby.end_x),
		y = easefunc(prevfrac, baby.start_y, baby.end_y),
		z = easefunc(prevfrac, baby.start_z, baby.end_z)
	}
	local eased = {
		x = easefunc(nextfrac, baby.start_x, baby.end_x),
		y = easefunc(nextfrac, baby.start_y, baby.end_y),
		z = easefunc(nextfrac, baby.start_z, baby.end_z)
	}
	for i = 0, lunge_steps
		local frac = P_Lerp((FU/lunge_steps)*i, 0, FU)
		P_MoveOrigin(baby,
			P_Lerp(frac, start.x, eased.x),
			P_Lerp(frac, start.y, eased.y),
			P_Lerp(frac, start.z, eased.z)
		)
		
		-- this isnt in vanilla nullscape but i think it looks nice
		if baby.enraged
			local g = P_SpawnGhostMobj(baby)
			P_SetOrigin(g,
				g.x + Soap_RandomFixedRange(-lunge_random, lunge_random),
				g.y + Soap_RandomFixedRange(-lunge_random, lunge_random),
				g.z + Soap_RandomFixedRange(-lunge_random, lunge_random)
			)
			
			g.blendmode = AST_ADD
			g.destscale = 0
			g.renderflags = $ &~RF_ALWAYSONTOP
		end
	end
end

local function Baby_SearchForPlayers(baby)
	local closest_player = nil
	local closest_dist = INT32_MAX
	
	baby.target = nil
	for p in players.iterate
		if p.spectator then continue end
		local me = p.mo
		if not (me and me.valid and me.health) then continue end
		
		local dist = R_PointTo3DDist(baby.x,baby.y,baby.z, me.x,me.y,me.z)
		if dist < closest_dist
			closest_player = p
			closest_dist = dist
		end
	end
	if not (closest_player and closest_player.valid) then return end
	baby.target = closest_player.mo
end

addHook("MobjThinker",function(b)
	if not (b and b.valid) then return end
	
	if not b.init
		Baby_Init(b)
	end
	
	local me = b.target
	if not (me and me.valid)
		if not Baby_SearchForPlayers(b)
			return
		end
		me = b.target
	end
	if not (me.health)
		b.target = nil
		return
	end
	
	if not b.charging
	and not b.chargewind
		b.charging = true
		b.chargewind = b.charge_wait + 1
		b.angle,b.aiming = R_PointTo3DAngles(b.x,b.y,b.z, me.x,me.y,me.z)
		S_StartSound(b, sfx_nb_0)
	end

	if b.chargewind > 1
		Baby_Telegraph(b, b.angle,b.aiming, b.charge_dist, b.chargewind - 1)
		b.chargewind = $ - 1
	elseif b.chargewind == 1 -- charge
		b.chargecooldown = b.charge_time + b.charge_cool
		b.chargingtics = b.charge_time
		b.chargewind = 0
	end
	
	if b.chargingtics
		Baby_DoLunge(b, b.angle,b.aiming, b.charge_dist, b.chargingtics)
		b.chargingtics = $ - 1
		if not b.chargingtics
			b.state = S_NSBABY_TOIDLE
			b.flags = $ &~MF_SPECIAL
			b.target = nil
			
			local dist = R_PointTo3DDist(b.x,b.y,b.z, me.x,me.y,me.z)
			local distcap = b.charge_dist*4/5 + 524*FU
			if not b.enraged
			and (dist >= distcap)
				Baby_SetRageStats(b)
				b.rangecount = 5
			elseif b.enraged
			and (dist < distcap)
				b.rangecount = $ - 1
				if not b.rangecount
					Baby_SetBaseStats(b)
				end
			end
		end
	end
	
	if b.chargecooldown
		b.chargecooldown = $ - 1
		if b.chargecooldown == 0
			b.charging = false
		end
	end
	
	if b.enraged
		if not S_SoundPlaying(b, sfx_nb_4)
		and not S_SoundPlaying(b, sfx_nb_5)
			S_StartSound(b, sfx_nb_5)
		end
	end
end,MT_NSBABY)

local function unfuck(f, mo)
	if not (f and f.valid) then return end
	f.health = mobjinfo[f.type].spawnhealth
	f.flags = $|MF_SPECIAL
	return true
end
local function dotumble(p)
	local me = p.mo
	me.soap_tumble = true
	me.soap_tumble_oldmomz = me.momz
end
addHook("TouchSpecial",function(f, mo)
	if not (f and f.valid) then return false; end
	if not (mo and mo.valid) then return false; end
	--if not (mo.health) then return end
	if (mo == f.tracer and mo.fuckimmunity) then return unfuck(f,mo); end
	if (f.touchlist[mo] ~= nil) then return unfuck(f,mo); end
	if not (f and f.valid) then return false; end
	--if (mo.hitlag or mo.orbitbonk) then return end
	--if not Soap_ZCollide(f,mo, true) then return false; end
	
	f.touchlist[mo] = true
	local play = mo.player
	if (play and play.valid)
		Soap_DamageSfx(mo,FU*3/4,FU)
		Soap_ImpactVFX(mo, f)
		
		play.powers[pw_flashing] = 0
		P_ResetPlayer(play)
		--P_DoPlayerPain(play,f,f)
		mo.state = S_PLAY_PAIN
		play.drawangle = f.angle + ANGLE_180
		
		dotumble(play)
		P_Thrust(mo, f.angle, FixedMul(100*FU, f.scale))
		if P_IsObjectOnGround(mo)
			mo.z = $ + P_MobjFlip(mo)
		end
		P_SetObjectMomZ(mo, 75*FU, true)
		play.powers[pw_flashing] = flashingtics
		Soap_Hitlag.addHitlag(mo, TR/2, true)
		
		if Soap_IsLocalPlayer(play)
			Soap_StartQuake(15*FU, TR/2,
				nil,
				512*mo.scale
			)
		end
		S_StartSound(mo, sfx_sp_em1)
		return unfuck(f,mo)
	end
	if Soap_CanDamageEnemy(nil, mo)
		P_KillMobj(mo,f, f.tracer)
	end
	return unfuck(f,mo)
end,MT_NSBABY)

COM_AddCommand("clearbabies", function(p)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	local cleared = 0
	for mo in mobjs.iterate()
		if mo.type == MT_NSBABY
			P_RemoveMobj(mo)
			cleared = $ + 1
		end
	end
	CONS_Printf(p, "Cleared "..cleared.." babies")
end)

local function GetPlayerHelper(pname)
	-- Find a player using their node or part of their name.
	local N = tonumber(pname)
	if N ~= nil and N >= 0 and N < 32 then
		for player in players.iterate do
			if #player == N then
	return player
			end
		end
	end
	for player in players.iterate do
		if string.find(string.lower(player.name), string.lower(pname)) then
			return player
		end
	end
	return nil
end
local function GetPlayer(player, pname)
	local player2 = GetPlayerHelper(pname)
	if not player2 then
		CONS_Printf(player, "No one here has that name.")
	end
	return player2
end

local function thebaby(mo)
	local baby = P_SpawnMobjFromMobj(mo,
		P_RandomRange(-256, 256)*FU,
		P_RandomRange(-256, 256)*FU,
		P_RandomRange(-256, 256)*FU,
		MT_NSBABY
	)
end
COM_AddCommand("spawnbabyby", function(p, name)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end

	local me = p.realmo
	if not p.realmo and p.realmo.valid
		local temp = P_SpawnMobj(0,0,0, MT_RAY)
		temp.fuse = 2
		temp.tics = 2
		me = temp
	end
	
	if node == "@all"
		local newspeed = tofixed(speed or "")
		for p2 in players.iterate
			if p2 == p then continue end
			local mo = p2.realmo
			if not (mo and mo.valid) then continue end
			
			thebaby(mo)
		end
		return
	end
	
	local p2 = GetPlayer(p,node or "")
	if p2
		local mo = p2.realmo
		if not (mo and mo.valid)
			CONS_Printf(p,"This person's object isn't valid.")
			return
		end
		
		thebaby(mo)
	else
		CONS_Printf(p,"Spawns a Baby next to whoever.")
	end
	
end)

/*
Takis_Hook.addHook("Soap_Thinker",function(p)
	local me = p.realmo
	local soap = p.soaptable
	
	if soap.c3 == 1
		--Baby_Telegraph(me, me.angle,p.aiming, 1024*FU, TR)
		P_SpawnMobjFromMobj(me,0,0,0,MT_NSBABY)
		SOAP_DEBUG = $|DEBUG_SPEEDOMETER
	end
end)
*/

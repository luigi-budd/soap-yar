local mbrelease = dofile("Vars/mbrelease.lua")

SafeFreeslot("sfx_sp_em0")
sfxinfo[sfx_sp_em0] = {
	flags = SF_X2AWAYSOUND,
	caption = "Nice words"
}
SafeFreeslot("sfx_sp_em1")
sfxinfo[sfx_sp_em1].caption = "\x8F\"Fuck!\"\x80"

SafeFreeslot("MT_FUCK","S_FUCK", "S_FUCK_INF")
states[S_FUCK] = {
	sprite = SPR_SOAP_GFX,
	frame = C|FF_SEMIBRIGHT,
	tics = 10*TR
}
states[S_FUCK_INF] = {
	sprite = SPR_SOAP_GFX,
	frame = C|FF_SEMIBRIGHT,
	tics = -1
}
mobjinfo[MT_FUCK] = {
	doomednum = -1,
	spawnstate = S_FUCK,
	flags = MF_NOGRAVITY|MF_SPECIAL|MF_SLIDEME,
	radius = 64*FU,
	height = 140*FU,
	speed = 15*FU,
	spawnhealth = 1,
}

local function FuckIt(me, homing, target)
	local ang = me.angle
	local disp = mobjinfo[MT_FUCK].radius + mobjinfo[MT_PLAYER].radius + 10*FU
	local mx,my = FixedDiv(me.momx,me.scale),FixedDiv(me.momy,me.scale)
	local fuck = P_SpawnMobjFromMobj(me,
		P_ReturnThrustX(nil,ang, disp) + mx,
		P_ReturnThrustY(nil,ang, disp) + my,
		0, MT_FUCK
	)
	fuck.angle = ang
	fuck.tracer = me
	fuck.playernum = #me.player
	fuck.spritexscale = FU*2
	fuck.spriteyscale = fuck.spritexscale
	fuck.touchlist = {}
	me.fuckimmunity = 15
	
	if homing
		fuck.target_player = target.player
		fuck.state = S_FUCK_INF
		fuck.homing = true
		fuck.flags = $|MF_NOCLIPHEIGHT
	end
	fuck.speed = fuck.info.speed
	return fuck
end

COM_AddCommand("fu", function(p, speed)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	local f = FuckIt(p.realmo)
	local newspeed = tofixed(speed or "")
	if newspeed == nil or newspeed == 0
		newspeed = f.speed
	end
	f.speed = newspeed
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
COM_AddCommand("fucker", function(p, node, speed)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	local p2 = GetPlayer(p,node or "")
	if p2
		local mo = p2.realmo
		if not (mo and mo.valid)
			CONS_Printf(p,"This person's object isn't valid.")
			return
		end
		
		local f = FuckIt(p.realmo, true, mo)
		local newspeed = tofixed(speed or "")
		if newspeed == nil or newspeed == 0
			newspeed = f.speed
		end
		f.speed = newspeed
	else
		CONS_Printf(p,"Gotta add whoever you wanna fuck.")
	end
end)

addHook("MobjThinker",function(f)
	if not f.extravalue1
		S_StartSound(f, sfx_sp_em0)
		f.extravalue1 = 1
	end
	
	f.touchlist = {}
	f.spritexscale = FU*2
	f.spriteyscale = f.spritexscale
	Soap_WindLines(f,0,SKINCOLOR_WHITE).scale = $ * 2
	Soap_WindLines(f,0,SKINCOLOR_WHITE)
	
	if (f.tracer and f.tracer.valid and f.tracer.fuckimmunity)
		f.tracer.fuckimmunity = $ - 1
	end
	
	local play = f.target_player
	if (f.homing and (play and play.valid))
		local mo = play.realmo
		local speed = FixedMul(f.speed,f.scale)
		local ha,va = R_PointTo3DAngles(f.x,f.y,f.z, mo.x,mo.y,mo.z)
		P_3DInstaThrust(f, ha,va, speed)
		f.angle = ha
		
		if not S_SoundPlaying(f,sfx_kc64)
			S_StartSound(f,sfx_kc64)
		end
		
		return
	end
	
	if not (f.phys_held)
		P_InstaThrust(f, f.angle, FixedMul(f.speed,f.scale))
	end
end,MT_FUCK)

local function unfuck(f, mo)
	if f.homing
		if mo.player == f.target_player
		and not mo.fuckimmunity
			return
		end
	end
	f.health = mobjinfo[f.type].spawnhealth
	f.flags = $|MF_SPECIAL
	return true
end
addHook("TouchSpecial",function(f, mo)
	if not (f and f.valid) then return false; end
	if not (mo and mo.valid) then return false; end
	--if not (mo.health) then return end
	if (mo == f.tracer and mo.fuckimmunity) then return unfuck(f,mo); end
	if (f.touchlist[mo] ~= nil) then return unfuck(f,mo); end
	--if (mo.hitlag or mo.orbitbonk) then return end
	--if not Soap_ZCollide(f,mo, true) then return false; end
	
	f.touchlist[mo] = true
	local play = mo.player
	if (play and play.valid)
		Soap_DamageSfx(mo,FU*3/4,FU,{ultimate = true})
		Soap_ImpactVFX(mo, f)
		
		play.powers[pw_flashing] = 0
		P_ResetPlayer(play)
		--P_DoPlayerPain(play,f,f)
		mo.state = S_PLAY_PAIN
		play.drawangle = f.angle + ANGLE_180
		
		--just handles it all for us lollololo
		local tumbled = false
		if Orbit
			if Orbit.TumblePlayer ~= nil
				Orbit.TumblePlayer(mo,f,true)
				tumbled = true
			elseif Orbit.TumbleMobj ~= nil
				Orbit.TumbleMobj(mo, f, f.angle, 100 * f.scale, true)
				tumbled = true
			end
		end
		
		if not tumbled
			P_Thrust(mo, f.angle, FixedMul(100*FU + f.speed, f.scale))
			if P_IsObjectOnGround(mo)
				mo.z = $ + P_MobjFlip(mo)
			end
			P_SetObjectMomZ(mo, 60*FU)
			play.powers[pw_flashing] = flashingtics
			Soap_Hitlag.addHitlag(mo, TR/2, true)
		end
		
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
end,MT_FUCK)

-- the fuck STILL gets stuck
local function TheFuckGotStuck(f, line)
	return false
end
addHook("MobjLineCollide",TheFuckGotStuck,MT_FUCK)

local function TheFuckGetsStuck(f, thing,line)
	/*
	P_BounceMove(f)
	f.angle = R_PointToAngle2(0,0,f.momx,f.momy)
	*/
	-- just do nothing
end
addHook("MobjMoveBlocked",TheFuckGetsStuck,MT_FUCK)

Takis_Hook.addHook("MoveBlocked", function(me, thing,line)
	local p = me.player
	local soap = p.soaptable
	
	if me.orbitbonk
		S_StartSound(me, sfx_s3k49)
		Soap_SpawnBumpSparks(me, thing, line)
		if (line and line.valid)
			local line_ang = R_PointToAngle2(
				line.v1.x, line.v1.y, line.v2.x, line.v2.y
			)
			local speed = R_PointToDist2(0,0,me.momx,me.momy) + FixedHypot(p.cmomx,p.cmomy)
			
			P_InstaThrust(me,
				line_ang - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1),
				-speed
			)
			if soap.onGround
				P_MovePlayer(p)
			end
			if soap.in2D
				me.momy = 0
			end
			return true
		elseif (thing and thing.valid)
			local ang = R_PointToAngle2(me.x,me.y, thing.x,thing.y)
			local speed = R_PointToDist2(0,0,thing.momx,thing.momy) + FixedMul(
				20*FU, FixedSqrt(FixedMul(thing.scale,me.scale))
			)
			if soap.onGround then speed = FixedDiv($, me.friction) end
			P_InstaThrust(me, ang, -speed)
			if soap.in2D
				me.momy = 0
			end
			return true
		end
		P_SetObjectMomZ(me, 15*FU, true)
	end
end)

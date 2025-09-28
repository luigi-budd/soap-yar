SafeFreeslot("sfx_sp_em0")
sfxinfo[sfx_sp_em0] = {
	flags = SF_X2AWAYSOUND,
	caption = "Nice words"
}
SafeFreeslot("sfx_sp_em1")
sfxinfo[sfx_sp_em1].caption = "\x8F\"Fuck!\"\x80"

SafeFreeslot("MT_FUCK","S_FUCK")
states[S_FUCK] = {
	sprite = SPR_SOAP_GFX,
	frame = C|FF_SEMIBRIGHT,
	tics = 10*TR
}

mobjinfo[MT_FUCK] = {
	doomednum = -1,
	spawnstate = S_FUCK,
	flags = MF_NOGRAVITY,
	radius = 64*FU,
	height = 140*FU,
	speed = 15*FU,
}

local function FuckIt(me)
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
	me.fuckimmunity = 15
end

COM_AddCommand("fu", function(p)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if (p.name == "Epix" --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	FuckIt(p.realmo)
end)

addHook("MobjThinker",function(f)
	if not (f.phys_held)
		P_InstaThrust(f, f.angle, FixedMul(f.info.speed,f.scale))
	end
	if not f.extravalue1
		S_StartSound(f, sfx_sp_em0)
		f.extravalue1 = 1
	end
	
	f.spritexscale = FU*2
	f.spriteyscale = f.spritexscale
	Soap_WindLines(f,0,SKINCOLOR_WHITE).scale = $ * 2
	Soap_WindLines(f,0,SKINCOLOR_WHITE)
	
	if (f.tracer and f.tracer.valid and f.tracer.fuckimmunity)
		f.tracer.fuckimmunity = $ - 1
	end
end,MT_FUCK)

addHook("MobjMoveCollide",function(f, mo)
	if not (mo and mo.valid) then return false; end
	--if not (mo.health) then return end
	if not (f and f.valid) then return false; end
	if (mo == f.tracer and mo.fuckimmunity) then return false; end
	--if (mo.hitlag or mo.orbitbonk) then return end
	if not Soap_ZCollide(f,mo, true) then return false; end
	
	local play = mo.player
	if (play and play.valid)
		Soap_DamageSfx(mo,FU*3/4,FU,{ultimate = true})
		Soap_ImpactVFX(mo, f)
		
		play.powers[pw_flashing] = 0
		P_ResetPlayer(play)
		--P_DoPlayerPain(play,f,f)
		mo.state = S_PLAY_PAIN
		P_InstaThrust(mo, f.angle, 100*f.scale)
		mo.z = $ + P_MobjFlip(mo)
		play.drawangle = f.angle + ANGLE_180
		
		--just handles it all for us lollololo
		local tumbled = false
		if Orbit and (Orbit.TumblePlayer ~= nil)
			Orbit.TumblePlayer(mo,f,true)
			tumbled = true
		end
		P_SetObjectMomZ(mo, 60*FU)
		if not tumbled
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
		return false
	end
	if Soap_CanDamageEnemy(nil, mo)
		P_KillMobj(mo,f, f.tracer)
	end
	
	return false
end,MT_FUCK)

-- the fuck STILL gets stuck
/*
local function TheFuckGotStuck(f, line)
	return false
end
addHook("MobjLineCollide",TheFuckGotStuck,MT_FUCK)
*/
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
	and (Orbit and Orbit.version ~= "0.4.37")
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
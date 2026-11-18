SafeFreeslot("SPR_NSCADENCE")
states[SafeFreeslot("S_NSCADENCE_IDLE")] = {
	sprite = SPR_NSCADENCE,
	frame = 0|FF_FULLBRIGHT,
	tics = -1,
	nextstate = S_NSCADENCE_IDLE,
	action = function(c)
		c.spritexscale = FU * 3
		c.spriteyscale = c.spritexscale
		c.renderflags = $ &~RF_ALWAYSONTOP
		c.resetinterp = true
	end
}

SafeFreeslot("S_NSCADENCE_RAGESTART")
SafeFreeslot("S_NSCADENCE_ENRAGED")
states[S_NSCADENCE_RAGESTART] = {
	sprite = SPR_NSCADENCE,
	frame = 12|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 9,
	var2 = 2,
	tics = (10*2),
	nextstate = S_NSCADENCE_ENRAGED,
	action = function(c)
		c.spritexscale = FixedMul(FU * 3, FixedDiv(100*FU, 69*FU))
		c.spriteyscale = c.spritexscale
		c.renderflags = $|RF_ALWAYSONTOP
		c.resetinterp = true
	end
}
states[S_NSCADENCE_ENRAGED] = {
	sprite = SPR_NSCADENCE,
	frame = 22|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 3,
	var2 = 2,
	tics = (4*2),
	nextstate = S_NSCADENCE_ENRAGED,
	action = function(c)
		c.spritexscale = FU * 3
		c.spriteyscale = c.spritexscale
		c.renderflags = $|RF_ALWAYSONTOP
		c.resetinterp = true
	end
}

mobjinfo[SafeFreeslot("MT_NSCADENCE")] = {
	doomednum = -1,
	spawnstate = S_NSCADENCE_IDLE,
	deathstate = S_NSCADENCE_IDLE,
	height = 164*FU,
	radius = 100*FU,
	spawnhealth = 1,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_RUNSPAWNFUNC,
}

local INST_VIOLIN = true
local INST_HARP = not INST_VIOLIN

states[SafeFreeslot("S_NSCADENCE_INST")] = {
	sprite = SPR_NSCADENCE,
	frame = 26|FF_FULLBRIGHT,
	tics = -1,
	action = function(c)
		c.c_insttype = P_RandomChance(FU/2)
		if c.c_insttype == INST_VIOLIN
			c.frame = $ + 1
		end
	end
}

states[SafeFreeslot("S_NSCADENCE_INST_DIE")] = {
	sprite = SPR_NSCADENCE,
	frame = 26|FF_FULLBRIGHT,
	tics = TR,
	action = function(inst)
		if inst.c_insttype == INST_VIOLIN
			inst.frame = $ + 1
		end
		
		local cad = inst.tracer
		if not (cad and cad.valid) then return end
		
		table.remove(cad.instruments, inst.instindex)
	end
}
	
mobjinfo[SafeFreeslot("MT_NSCADENCE_INST")] = {
	doomednum = -1,
	spawnstate = S_NSCADENCE_INST,
	deathstate = S_NSCADENCE_INST_DIE,
	height = 100*FU,
	radius = 50*FU,
	spawnhealth = 1,
	flags = MF_NOGRAVITY|MF_SPECIAL|MF_RUNSPAWNFUNC,
}

sfxinfo[SafeFreeslot("sfx_nca_0")] = {flags = SF_X2AWAYSOUND, caption = "Ticking"}
sfxinfo[SafeFreeslot("sfx_nca_1")] = {flags = SF_X4AWAYSOUND, caption = "Ticking"}
sfxinfo[SafeFreeslot("sfx_nca_2")] = {flags = SF_X8AWAYSOUND|SF_X4AWAYSOUND, caption = "Ticking"}
sfxinfo[SafeFreeslot("sfx_nca_3")] = {flags = SF_X8AWAYSOUND|SF_X4AWAYSOUND|SF_X2AWAYSOUND, caption = "Ticking"}

sfxinfo[SafeFreeslot("sfx_nca_4")] = {flags = SF_X8AWAYSOUND|SF_X4AWAYSOUND|SF_X2AWAYSOUND, caption = "Cadence enrages"}

sfxinfo[SafeFreeslot("sfx_nca_5")] = {flags = SF_X8AWAYSOUND|SF_X2AWAYSOUND, caption = "Instrument spawns"}
sfxinfo[SafeFreeslot("sfx_nca_5a")] = {flags = SF_X8AWAYSOUND, caption = "Instrument spawns"}

sfxinfo[SafeFreeslot("sfx_nca_6")] = {flags = SF_X8AWAYSOUND, caption = "/"}

local RAGE_STAGE = 4*TR -- (4 * 4)*TR
local RAGE_MAX = RAGE_STAGE * 4
local ACCEL_MAX = FU / 37

local function Cad_CheckInst(c)
	local numinst = #c.instruments
	if numinst >= 2
		c.rage = max($ - 1, 0)
	else
		c.rage = min($ + 1, RAGE_MAX)
	end
end

local function Cad_GetInstTimer(c)
	local numinst = #c.instruments
	return 3*TR --(numinst >= 2) and 30*TR or 25*TR
end

local function Cad_Init(c)
	c.c_init = true
	c.soap_supervfx = true
	
	c.lifetime = 0
	c.stage = 0
	c.instruments = {}
	c.insttimer = Cad_GetInstTimer(c)
	c.instanim = 0
	c.rage = RAGE_MAX
	c.acceleration = 0
end

local function Cad_InstThinker(c)
	c.acceleration = 0
	c.flags = $ &~MF_SPECIAL
	
	if c.insttimer
		c.insttimer = $ - 1
		
		-- spawn instrument
		if c.insttimer == 0
			c.instanim = TR * 3/4
			S_StartSound(c, sfx_nca_5)
		end
	elseif c.instanim
		c.instanim = $ - 1
		if c.instanim == 0
			
			local p = consoleplayer
			local me = p.mo
			local inst = P_SpawnMobjFromMobj(me,
				P_ReturnThrustX(nil, me.angle, 200*FU),
				P_ReturnThrustY(nil, me.angle, 200*FU),
				0, MT_NSCADENCE_INST
			)
			inst.tracer = c
			inst.instindex = (#c.instruments) + 1
			
			local sfx = P_SpawnGhostMobj(inst)
			sfx.tics = 2*TR
			sfx.fuse = sfx.tics
			sfx.flags2 = $|MF2_DONTDRAW
			S_StartSound(sfx, sfx_nca_5a)
			
			table.insert(c.instruments, inst)
			c.insttimer = Cad_GetInstTimer(c)
		end
	end
	
	Cad_CheckInst(c)
end

local function Cad_Sound(c)
	c.stage = 0
	if (c.rage >= RAGE_STAGE*3)
		c.stage = 0
	elseif (c.rage >= RAGE_STAGE*2)
		c.stage = 1
	elseif (c.rage >= RAGE_STAGE)
		c.stage = 2
	else
		c.stage = 3
	end
	
	local sound = sfx_nca_0 + c.stage
	
	if (c.lifetime % (4*TR) == 0)
		S_StartSound(c, sound)
	end
end

local function Baby_SearchForPlayers(baby)
	local closest_player = nil
	local closest_dist = nil
	
	baby.target = nil
	for p in players.iterate
		if p.spectator then continue end
		if p.pflags & PF_INVIS then continue end
		local me = p.mo
		if not (me and me.valid and me.health) then continue end
		
		local dist = R_PointTo3DDist(baby.x,baby.y,baby.z, me.x,me.y,me.z)
		if (closest_dist == nil)
		or dist < closest_dist
			closest_player = p
			closest_dist = dist
		end
	end
	if not (closest_player and closest_player.valid) then return end
	baby.target = closest_player.mo
end

local function Cad_EnragedThinker(c)
	local friction = FU * 97/100
	c.momx = FixedMul($, friction)
	c.momy = FixedMul($, friction)
	c.momz = FixedMul($, friction)
	c.flags = $|MF_SPECIAL
	Cad_CheckInst(c)
	
	local me = c.target
	if not (me and me.valid)
		if not Baby_SearchForPlayers(c)
			c.acceleration = 0
			return
		end
		me = c.target
	end
	if not (me.health)
		c.target = nil
		c.acceleration = 0
		return
	end
	
	local ha,va = R_PointTo3DAngles(c.x,c.y,c.z + c.height/2, me.x,me.y,me.z + me.height/2)
	local wishspeed = 140*FU
	local acceleration = c.acceleration
	c.acceleration = P_Lerp(FU / 10, $, ACCEL_MAX)
	
	local addspeed = wishspeed - FixedHypot(FixedHypot(c.momx,c.momy), c.momz)
	if (addspeed > 0)
		local accelspeed = FixedMul(acceleration, wishspeed)
		if accelspeed > addspeed then accelspeed = addspeed; end
		
		local momvec = Vec3.MobjMomToVec(c)
		local wishangle = Vec3.SphereToCartesian(ha, va)
		local x = momvec.x + FixedMul(accelspeed, wishangle.x)
		local y = momvec.y + FixedMul(accelspeed, wishangle.y)
		local z = momvec.z + FixedMul(accelspeed, wishangle.z)
		c.momx = x
		c.momy = y
		c.momz = z
	end
end

addHook("MobjThinker",function(c)
	if not (c and c.valid) then return end
	
	if not c.c_init
		Cad_Init(c)
	end
	
	if c.rage
		Cad_InstThinker(c)
		
		Cad_Sound(c)
		if c.rage <= 0
			c.rage = 0
			
			S_StopSoundByID(c, sfx_nca_0)
			S_StopSoundByID(c, sfx_nca_1)
			S_StopSoundByID(c, sfx_nca_2)
			S_StopSoundByID(c, sfx_nca_3)
			
			S_StartSound(c, sfx_nca_4)
			
			c.state = S_NSCADENCE_RAGESTART
		end
	else
		Cad_EnragedThinker(c)
		if not S_SoundPlaying(c, sfx_nca_6)
			S_StartSound(c, sfx_nca_6)
		end
	end
	
	c.lifetime = $ + 1
end,MT_NSCADENCE)

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
	me.soap_tumble_markedfordeath = true
end
local function Baby_Collide(f, mo)
	if not (f and f.valid) then return false; end
	if not (mo and mo.valid) then return false; end
	if not (mo.health) then return end
	if not (f and f.valid) then return false; end
	--if (mo.hitlag or mo.orbitbonk) then return end
	if not Soap_ZCollide(f,mo, true) then return false; end
	
	local play = mo.player
	if (play and play.valid)
	and not (play.powers[pw_flashing])
		if (play.powers[pw_shield])
			S_StartSound(mo, sfx_nssb)
			Soap_ImpactVFX(mo, f, nil,nil,nil,nil, DMG_ELECTRIC)
			if (play.powers[pw_shield] & SH_FORCE)
				if (play.powers[pw_shield] & 255 == 0) -- no hp
					P_RemoveShield(play)
				else
					play.powers[pw_shield] = (($ & 255) - 1)|SH_FORCE
				end
			else
				P_RemoveShield(play)
			end
			play.powers[pw_flashing] = flashingtics - 1
			
			return unfuck(f,mo)
		end
		
		Soap_DamageSfx(mo,FU*3/4,FU)
		Soap_ImpactVFX(mo, f)
		
		play.powers[pw_flashing] = 0
		P_ResetPlayer(play)
		--P_DoPlayerPain(play,f,f)
		mo.state = S_PLAY_PAIN
		play.drawangle = f.angle + ANGLE_180
		
		dotumble(play)
		P_Thrust(mo, f.angle, FixedMul(140*FU, f.scale))
		if P_IsObjectOnGround(mo)
			mo.z = $ + P_MobjFlip(mo)
		end
		P_SetObjectMomZ(mo, 46*FU, true)
		play.powers[pw_flashing] = flashingtics
		
		local hitlagtics = 14
		Soap_Hitlag.addHitlag(mo, hitlagtics, true)
		Soap_Hitlag.addHitlag(f, hitlagtics, false)
		
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
end
addHook("TouchSpecial",Baby_Collide,MT_NSCADENCE)

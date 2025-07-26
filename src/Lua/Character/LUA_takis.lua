local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SPINDUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local function stupidbouncesectors(mobj, sector)
    for fof in sector.ffloors()
        if not (fof.fofflags & FOF_BOUNCY) and (GetSecSpecial(fof.master.frontsector.special, 1) != 15)
            continue
        end
        if not (fof.fofflags & FOF_EXISTS)
            continue
        end
        if (mobj.z+mobj.height+mobj.momz < fof.bottomheight) or (mobj.z-mobj.momz > fof.topheight)
            continue
        end
        return true
    end
end

Takis_Hook.addHook("Takis_Thinker",function(p)
	local me = p.realmo
	local soap = p.soaptable
	
	local squishme = true
	
	if (p.skidtime)
	and (me.state == S_PLAY_SKID)
		--nothing to do here yet
	else
		S_StopSoundByID(me,skins["takisthefox"].soundsid[SKSSKID])
	end
	
	if (me.state == S_PLAY_WAIT)
	and (me.sprite2 == SPR2_WAIT)
		if (soap.last.anim.state == S_PLAY_STND)
			soap.waitframe = P_RandomRange(A, skins[p.skin].sprites[SPR2_WAIT].numframes - 1)
		end
		soap.waittics = $+1
		me.frame = soap.waitframe
		me.tics = -1
		me.anim_duration = 0
		
		if soap.waittics >= TR + P_RandomRange(0,TR)
			me.state = S_PLAY_STND
			me.tics = $ + P_RandomRange(TR,8*TR)
		end
	else
		soap.waittics = 0
	end
	
	p.charability2 = soap.inBattle and CA2_GUNSLINGER or CA2_NONE
	p.revitem = soap.inBattle and MT_CORK or MT_NULL
	
	--Nope
	p.charflags = $ &~SF_SUPER
	/*
	Takis_VFX(p,me,soap, {
		squishme = squishme,
	})
	*/
end)

--jump effect
addHook("JumpSpecial", function(p)
	if p.mo.skin ~= "takisthefox" then return end
	
	local me = p.mo
	local soap = p.soaptable
	
	if not soap then return end
	
	if soap.jump > 1 then return end
	if (p.pflags & PF_THOKKED) then return end
	if (soap.jumptime > 0) then return end
	if p.inkart then return end
	if (p.pflags & PF_JUMPSTASIS) then return end
	if (p.pflags & (PF_JUMPED|PF_STARTJUMP) == PF_JUMPED) then return end
	if (p.jumpfactor <= 0) then return end
	
	if soap.onGround
	or me.soap_jumpeffect
		
		Soap_DustRing(me,
			dust_type(me), 8,
			{me.x,me.y,me.z},
			me.radius / 2,
			8*me.scale,
			me.scale * 3/2,
			me.scale / 2,
			false,
			dust_noviewmobj
		)
		
		local ease_time = 8
		local ease_func = "outsine"
		Soap_AddSquash(p, {
			ease_func = ease_func,
			start_v = -FU*7/10,
			end_v = 0,
			time = ease_time
		}, {
			ease_func = ease_func,
			start_v = FU/2,
			end_v = 0,
			time = ease_time
		})
		Soap_RemoveSquash(p, "landeffect")
		me.soap_jumpdust = 4
		me.soap_jumpeffect = nil
	end
end)

--double jump
addHook("AbilitySpecial", function(p)
	if p.mo.skin ~= "takisthefox" then return end
	
	local soap = p.soaptable
	
	if p.charability ~= CA_DOUBLEJUMP then return end
	if (p.pflags & PF_THOKKED) then return end
	if (p.pflags & PF_JUMPSTASIS)
		return true
	end
	if soap.inPain
		return true
	end
	
	local me = p.mo
	
	P_DoJump(p,false)
	S_StopSoundByID(me,skins["takisthefox"].soundsid[SKSJUMP])
	
	local jfactor = min(FixedDiv(p.jumpfactor,skins["takisthefox"].jumpfactor),FU)
	Soap_ZLaunch(p.mo,FixedMul(15*FU,jfactor))
	
	me.state = S_PLAY_ROLL
	Soap_DustRing(me,
		dust_type(me), P_RandomRange(8,14),
		{me.x,me.y,me.z},
		me.radius / 2,
		16*me.scale,
		me.scale * 3/2,
		me.scale / 2,
		false,
		dust_noviewmobj
	)

	--wind ring
	S_StartSoundAtVolume(me,sfx_tk_djm,4*255/5)
	if soap.inWater
		S_StartSound(me,sfx_splash)
	end
	
	local ease_time = 8
	local ease_func = "outsine"
	Soap_AddSquash(p, {
		ease_func = ease_func,
		start_v = -FU*7/10,
		end_v = 0,
		time = ease_time
	}, {
		ease_func = ease_func,
		start_v = FU/2,
		end_v = 0,
		time = ease_time
	})
	Soap_RemoveSquash(p, "landeffect")
	me.soap_jumpdust = 4
	
	p.pflags = $|(PF_JUMPED|PF_JUMPDOWN|PF_THOKKED|PF_STARTJUMP) & ~(PF_SPINNING|PF_STARTDASH)
	return true
end)

--pvp
--shitty battlemod
-- fucking stupid cocksucking motherfucking BattleMod
addHook("PlayerCanDamage",function(p)
	local me = p.mo
	if not (me and me.valid) then return end
	if (me.skin ~= "takisthefox") then return end
	local soap = p.soaptable
	
	if soap.pounding then return true; end
	
	if soap.uppercutted
	and (me.momz*soap.gravflip > 0)
	and (me.sprite2 == SPR2_MLEE)
		return true
	end

	if (soap.rdashing and p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash)
	or (soap.airdashed and me.state == S_PLAY_FLOAT_RUN)
		return true
	end
end)

Takis_Hook.addHook("MoveBlocked",function(me,thing,line, goingup)
	local p = me.player
	local soap = p.soaptable
	
	if me.skin ~= "takisthefox" then return end
	
	if not (me.state == S_PLAY_DASH or me.state == S_PLAY_FLOAT_RUN) then return end
	if goingup then return end
	
	if ( (soap.rdashing
	and (p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash))
	or (soap.airdashed) or true )
	and ((thing and thing.valid) or (line and line.valid and P_LineIsBlocking(me,line)))
		soap.rdashing = false
		if soap.airdashed
			soap.noairdashforme = true
		end
		
		if not soap.onGround
			me.state = S_PLAY_FALL
		else
			me.state = S_PLAY_WALK
		end
		soap.canuppercut = true
		soap.uppercutted = false
		
		P_StartQuake(5*FU, 8, {me.x,me.y,me.z}, 512*me.scale)
		S_StartSound(me, sfx_s3k49)
		Soap_SpawnBumpSparks(me, thing, line)
		
		if (line and line.valid)
			local line_ang = R_PointToAngle2(
				line.v1.x, line.v1.y, line.v2.x, line.v2.y
			)
			local speed = FixedDiv(20*me.scale, me.friction) + FixedHypot(p.cmomx,p.cmomy)
			speed = $ + abs(FixedMul(
				R_PointToDist2(0,0,me.momx,me.momy) * 3/4,
				sin(line_ang - R_PointToAngle2(0,0,me.momx,me.momy))
			))
			
			P_Thrust(me,
				line_ang - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1),
				-speed
			)
			soap.linebump = max($, 12)
			return true
		else
			local ang = R_PointToAngle2(me.x,me.y, thing.x,thing.y)
			local speed = R_PointToDist2(0,0,thing.momx,thing.momy) + FixedMul(
				20*FU, FixedSqrt(FixedMul(thing.scale,me.scale))
			)
			if soap.onGround then speed = FixedDiv($, me.friction) end
			P_InstaThrust(me, ang, -speed)
			soap.linebump = max($, 12)
			return true
		end
	end
end)

local function handleBump(p,me,thing)
	local soap = p.soaptable
	if (p.powers[pw_super] or soap.isSolForm or p.powers[pw_invulnerability]) then return end
	if soap.nodamageforme > 2 then return end
	
	local max_speed = (skins[p.skin].normalspeed + soap._maxdash)
	local speed_add = FixedMul(
		ease.inquart(
			FixedDiv(min(soap.accspeed, p.normalspeed), max_speed),
			0,FU
		),
		max_speed
	)
	speed_add = max($ - 3*FU, 0)
	
	if not (thing.flags & MF_MONITOR)
		if not (thing.flags & MF_NOGRAVITY)
			Soap_ZLaunch(thing, FixedMul(3*FU + speed_add/5, me.scale))
			P_Thrust(thing,
				R_PointToAngle2(thing.x,thing.y, me.x,me.y),
				FixedMul(3*FU + speed_add, -me.scale)
			)
		end
		if not (thing.player and thing.player.valid)
			Soap_Hitlag.stunEnemy(thing, (TR*3/2) + (speed_add / FU / 5))
		else
			P_MovePlayer(thing.player)
			thing.state = S_PLAY_FALL
		end
	end
	
	Soap_SpawnBumpSparks(me,thing)
	P_InstaThrust(me,
		R_PointToAngle2(me.x,me.y, thing.x,thing.y),
		-5 * thing.scale
	)
	Soap_ZLaunch(me, 3*thing.scale)
	P_MovePlayer(p)
	S_StartSound(me, sfx_s3k49)
	
	soap.nodamageforme = 5
	p.powers[pw_nocontrol] = 5
	p.skidtime = TR/2
	if p.powers[pw_carry] == CR_NONE
		me.state = S_PLAY_SKID
		me.tics = p.skidtime
	end
	soap.fakeskidtime = p.skidtime
	p.pflags = $ &~PF_SPINNING
	
	if P_IsLocalPlayer(p)
		S_StartSound(me, sfx_skid)
	end
end

local function try_pvp_collide(me,thing)
	if not (me and me.valid) then return end
	if not (thing and thing.valid) then return end
	
	--??? why?
	if not me.health then return end
	if not thing.health then return end
	
	--players only
	if (me.type ~= MT_PLAYER) then return end
	if not (me.player and me.player.valid) then return end
	
	local p = me.player
	local soap = p.soaptable
	
	if not soap then return end
	if me.skin ~= "takisthefox" then return end
	
	local DealDamage = (p.powers[pw_super] or soap.isSolForm or p.powers[pw_invulnerability]) and P_KillMobj or P_DamageMobj
	
	--if the thing we're killing ISNT a player, then theyre probably an enemy
	if thing.type ~= MT_PLAYER
	or not (thing.player and thing.player.valid)
		if Soap_CanDamageEnemy(p, thing)
			if not Soap_ZCollide(me,thing, true) then return end
			
			--hit by pound
			if (soap.pounding)
			and (thing.health)
				Soap_ImpactVFX(thing, me)
				local damage = 1
				
				local power = 5*FU + FixedDiv(abs(me.momz),me.scale*3)
				Soap_DamageSfx(thing, power, 35*FU)
				if (FixedDiv(power, 35*FU) >= FU/2)
					S_StartSound(me,sfx_sp_db4)
					local work = FixedDiv(power, 35*FU) - FU/2
					repeat
						Soap_ImpactVFX(thing,me, FU + work*7)
						work = $ - FU/4
						damage = $ + 2
					until (work <= 0)
				end
				
				local hitlag_tics = 10 + ((power/FU) / 5)
				P_StartQuake(power*2, hitlag_tics,
					{me.x, me.y, me.z},
					512*me.scale + power
				)
				
				DealDamage(thing, me,me, damage)
				me.momz = $ - (3 * me.scale * soap.gravflip)
				
				Soap_Hitlag.addHitlag(me, hitlag_tics - 3, false)
				if (thing and thing.valid)
				and not (thing.flags & MF_MONITOR)
					Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
					if not (thing.flags & MF_NOGRAVITY)
						Soap_ZLaunch(thing, power)
					end
				end
				
				Soap_ZLaunch(me, 3*FU, true)
				return
			end
			
			--hit by uppercut
			if soap.uppercutted
			and (me.momz*soap.gravflip > 0)
			and (me.sprite2 == SPR2_MLEE)
				Soap_ImpactVFX(thing,me)
				soap.uppercut_spin = 360*FU
				soap.canuppercut = true
				
				local power = 5*FU + FixedDiv(me.momz,me.scale)
				Soap_DamageSfx(thing, power, 35*FU)
				
				local hitlag_tics = 10 + (power/FU / 5)
				P_StartQuake(power*2, hitlag_tics,
					{me.x, me.y, me.z},
					512*me.scale + power
				)
				
				DealDamage(thing, me,me)
				
				Soap_Hitlag.addHitlag(me, hitlag_tics - 3, false)
				if (thing and thing.valid)
				and (thing.health)
				and not (thing.flags & MF_MONITOR)
					Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
					if not (thing.flags & MF_NOGRAVITY)
						Soap_ZLaunch(thing, power)
					end
				end
				
				Soap_ZLaunch(me, 3*FU, true)
				return
			end
			
			--r-dashing but too slow to deal damage
			if (soap.rdashing)
			and min(soap.accspeed, p.normalspeed) < skins[p.skin].normalspeed + soap._maxdash
			and (me.state == S_PLAY_RUN)
				handleBump(p,me,thing)
				return false
			end
			
			--hit by r-dash / b-rush
			if (soap.rdashing and p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash)
			or (soap.airdashed and me.state == S_PLAY_FLOAT_RUN)
				Soap_ImpactVFX(thing,me)
				
				local power = FixedMul(10*FU + max(soap.accspeed - 20*FU,0), me.scale)
				Soap_DamageSfx(thing, power, 60*FU)
				
				local hitlag_tics = 4 + (power/FU / 10)
				P_StartQuake(power/2, hitlag_tics,
					{me.x, me.y, me.z},
					512*me.scale + power
				)
				--P_Thrust(me, R_PointToAngle2(0,0,me.momx,me.momy), me.scale*8)
				
				DealDamage(thing, me,me)
				
				Soap_Hitlag.addHitlag(me, hitlag_tics, false)
				if (thing and thing.valid)
				and (thing.health)
				and not (thing.flags & MF_MONITOR)
					Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
					if not (thing.flags & MF_NOGRAVITY)
						Soap_ZLaunch(thing, 5*FU)
					end
				end
				Soap_SpawnBumpSparks(me, thing, nil, true)
				return
			end
		end
		return
	end
	
	if not Soap_ZCollide(me,thing) then return end
	
	--now for the other guy
	local p2 = thing.player
	local soap2 = p2.soaptable
	local battlepass = false --(soap.inBattle)
	
	if not Soap_CanHurtPlayer(p, p2, battlepass) then return end
	
	--hit by pound
	if (soap.pounding)
		Soap_ImpactVFX(thing,me)
		local damage = 25
		
		local power = 5*FU + FixedDiv(abs(me.momz),me.scale)
		Soap_DamageSfx(thing, power, 35*FU)
		if (FixedDiv(power, 35*FU) >= FU/2)
			S_StartSound(me,sfx_sp_db4)
			local work = FixedDiv(power, 35*FU) - FU/2
			repeat
				Soap_ImpactVFX(thing,me, FU + work*7)
				work = $ - FU/4
				damage = $ + 5
			until (work <= 0)
		end
		
		local hitlag_tics = 10 + (power/FU / 5)
		P_StartQuake(power*2, hitlag_tics,
			{me.x, me.y, me.z},
			512*me.scale + power
		)
		
		P_DamageMobj(thing, me,me, damage)
		me.momz = $ - (3 * me.scale * soap.gravflip)
		
		Soap_Hitlag.addHitlag(me, 7, false)
		if (thing and thing.valid)
			Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
			if not (thing.flags & MF_NOGRAVITY)
				Soap_ZLaunch(thing, 5*FU)
			end
		end
		
		Soap_ZLaunch(me, 3*FU, true)
		return
	end
	
	--hit by uppercut
	if soap.uppercutted
	and (me.momz*soap.gravflip > 0)
	and (me.momz*soap.gravflip) > (thing.momz * P_MobjFlip(thing))
	and (me.sprite2 == SPR2_MLEE)
		P_DamageMobj(thing, me,me, 40)
		soap.uppercut_spin = 360*FU
		soap.canuppercut = true
		
		local power = 5*FU + FixedDiv(me.momz,me.scale)
		Soap_ZLaunch(thing, power)
		Soap_DamageSfx(thing, power, 35*FU)
		
		local hitlag_tics = 15 + (power/FU / 3)
		P_StartQuake(power*2, hitlag_tics,
			{me.x, me.y, me.z},
			512*me.scale + power
		)
		
		Soap_Hitlag.addHitlag(me, hitlag_tics, false)
		Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
		
		Soap_ImpactVFX(thing,me)
		Soap_ZLaunch(me, 3*FU, true)
		return
	end
	
	--r-dashing but too slow to deal damage
	if (soap.rdashing)
	and min(soap.accspeed, p.normalspeed) < skins[p.skin].normalspeed + soap._maxdash
	and (me.state == S_PLAY_RUN)
		handleBump(p,me,thing)
		return false
	end
	
	--hit by r-dash / b-rush
	if (soap.rdashing and p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash)
	or (soap.airdashed and me.state == S_PLAY_FLOAT_RUN and soap.airdashcharge == 0)
	and (soap.accspeed > soap2.accspeed)
		
		Soap_ZLaunch(thing, 5*FU)
		local power = FixedMul(10*FU + soap.accspeed, me.scale)
		P_InstaThrust(thing,
			R_PointToAngle2(0,0,me.momx,me.momy),
			power
		)
		Soap_DamageSfx(thing, power, 85*FU)
		
		P_DamageMobj(thing, me,me, 30 + (power/2)/FU)
		
		local hitlag_tics = 15 + (power/FU / 7)
		P_StartQuake(power/2, hitlag_tics,
			{me.x, me.y, me.z},
			512*me.scale + power
		)
		P_Thrust(me, R_PointToAngle2(0,0,me.momx,me.momy), me.scale*8)
		
		Soap_ImpactVFX(thing,me)
		Soap_Hitlag.addHitlag(me, hitlag_tics, false)
		Soap_Hitlag.addHitlag(thing, hitlag_tics, true)
		Soap_SpawnBumpSparks(me, thing, nil, true)
		return
	end
end

addHook("MobjMoveCollide",try_pvp_collide,MT_PLAYER)
addHook("MobjCollide",try_pvp_collide,MT_PLAYER)
addHook("ShouldDamage",function(me, inf,src)
	local p = me.player
	if not (p and p.valid) then return end
	if not (p.soaptable) then return end
	if (me.hitlag) then return end
	
	if p.soaptable.nodamageforme
	and (inf and inf.valid or src and src.valid)
		return false
	end
	
end,MT_PLAYER)

--various effects
--handle soap damage
addHook("MobjDamage", function(me,inf,sor,dmg,dmgt)
	if not (me and me.valid) then return end
	if me.skin ~= "takisthefox" then return end
	
	local p = me.player 
	local soap = p.soaptable

	if ((p.powers[pw_flashing])
	and (p.powers[pw_carry] == CR_NIGHTSMODE))
		return
	end

	if p.ptsr and p.ptsr.outofgame then return end
	if (p.guard ~= nil and (p.guard == 1)) then return end
	p.pflags = $ &~(PF_THOKKED|PF_JUMPED|PF_SHIELDABILITY)
	
	if me.health
		S_StartSoundAtVolume(me,sfx_sp_smk,255*3/4)
		S_StartSound(me,sfx_sp_dmg)
		if (inf and inf.valid)
			local inf_speed = FixedHypot(inf.momx,inf.momy)
			Soap_DamageSfx(me, inf_speed, 40*inf.scale, {
				ultimate = (not soap.inBattle) and true or false,
				nosfx = true
			})
			
			if (inf_speed - 10 * inf.scale) > 0
				P_Thrust(me, 
					R_PointToAngle2(inf.x,inf.y,
						me.x,me.y
					),
					inf_speed - 10*inf.scale
				)
			end
		else
			S_StartSound(me,sfx_sp_db0)
		end
		
		Soap_ImpactVFX(me, inf)
		if Soap_IsLocalPlayer(p)
			P_StartQuake((20 + p.timeshit*3/2)*FU, 16 + 16*(p.losstime / (10*TR)),
				nil,
				512*me.scale
			)
		end
		
		/*
		if takis.heartcards > (not extraheight and 1 or 0)
			S_StartAntonOw(mo)
		end
		*/
		
		if (dmgt == DMG_FIRE)
			soap.firepain = TR * 2
			S_StartSound(me, sfx_s3kc2s)
			S_StartSound(me, sfx_s248)
			S_StartSound(me, sfx_s233)
			S_StartSound(me, sfx_s3kcds)
		elseif (dmgt == DMG_ELECTRIC)
			soap.elecpain = TR * 3/2
			S_StartSound(me, sfx_buzz2)
			S_StartSound(me, sfx_s250)
		end
	end

end,MT_PLAYER)

--soap death hook
--soap died by thing
addHook("MobjDeath", function(me,inf,sor,dmgt)
	if not (me and me.valid) then return end
	if me.skin ~= "takisthefox" then return end
	
	local p = me.player 
	local soap = p.soaptable
	
	me.soap_inf = inf
	me.soap_sor = sor
	
	soap.deathtype = dmgt
	--ehh whatever
	if (me.eflags & MFE_UNDERWATER)
		soap.deathtype = DMG_DROWNED
	end
	if P_InSpaceSector(me)
		soap.deathtype = DMG_SPACEDROWN
	end
	
	if (sor and sor.valid and (sor.flags & MF_BOSS))
		local killer = sor
		if (inf and inf.valid) then killer = inf; end
		
		me.z = $ + soap.gravflip
		local power = FixedHypot(FixedHypot(killer.momx,killer.momy),killer.momz)
		P_InstaThrust(me, R_PointToAngle2(killer.x,killer.y,me.x,me.y), power)
		P_SetObjectMomZ(me, 5*FU)
		
		me.soap_knockout = true
		me.soap_knockout_speed = {
			me.momx,me.momy,me.momz
		}
		
		p.drawangle = R_PointToAngle2(me.x,me.y,killer.x,killer.y)
		soap.deathtype = 0
	end
end)

local crouch_lerp = 0
Takis_Hook.addHook("PostThinkFrame",function(p)
	local me = p.mo
	local soap = p.soaptable
	
	if me.skin ~= "takisthefox" then return end
	
	if me.hitlag
		--still tick down
		if soap.airdashcharge
			/*
			if soap.airdashcharge % 3 == 0
				S_StartSound(me,sfx_kc67)
			end
			*/
			soap.airdashcharge = $ - 1
			
			if soap.airdashcharge == 0
			and me.state == S_PLAY_FLOAT_RUN
				S_StopSoundByID(me,sfx_kc63)
				S_StartSound(me,sfx_sp_dss)
			end
		end
		if not (p.charflags & SF_NOJUMPSPIN)
			if me.state == S_PLAY_JUMP
			or me.sprite2 == SPR2_JUMP
				me.state = S_PLAY_ROLL
			end
		end
		
		do_poundsquash(p,me,soap)
		return
	elseif me.oldhitlag
		--jump after ramming midair
		if (soap.rdashing and me.state == S_PLAY_DASH)
		and soap.jump
		and not soap.onGround
			p.pflags = $ &~(PF_JUMPED)
			soap.jump = 0
			soap.jumptime = 0
			me.soap_jumpeffect = true
			P_DoJump(p,true)
		end
	end
	
	if not (p.charflags & SF_NOJUMPSPIN)
		if me.state == S_PLAY_JUMP
		or me.sprite2 == SPR2_JUMP
			me.state = S_PLAY_ROLL
		end
	end
	
	if (me.flags & MF_NOTHINK and not me.hitlag) then return end
	
	--crouching viewheight
	--code shamelessly taken from ze2 lmao
	if Soap_IsLocalPlayer(p)
		if soap.crouching
			crouch_lerp = min($ + FU/7, FU)
		else
			crouch_lerp = max($ - FU/4, 0)
		end
		if crouch_lerp
			local eased = ease.inoutquad(crouch_lerp,
				0, FixedMul(p.height - p.spinheight, me.scale)
			)
			local height = me.z + p.viewheight - eased
			p.viewz = min($, height)
		end
	else
		crouch_lerp = 0
	end
	
	--this is really cool
	--handle pound landing here too so uhh
	local was_pounding = soap.pounding
	if soap.pounding
		--use soap.onGround here because our predicted
		--landing shouldve already happened
		if (soap.onGround)
		or (stupidbouncesectors(me,me.subsector.sector))
		and not P_CheckDeathPitCollide(me)
			soap_poundonland(p,me,soap)
		end
	end
	if was_pounding
	and not soap.pounding
		p.powers[pw_strong] = $ &~(STR_SPRING|STR_HEAVY|STR_SPIKE)
		me.spritexscale = FU
		me.spriteyscale = FU
	end
	
	--Refresh stuff on bouncy sectors
	if (stupidbouncesectors(me, me.subsector.sector))
		soap.airdashed = false
		soap.canuppercut = true
		p.pflags = $ &~PF_THOKKED
	end
	
	if me.sprite2 == SPR2_STUN
		p.drawangle = $ - ANG15
	end
	if me.sprite2 == SPR2_MSC0
		local newframe = abs(
			( FixedDiv(me.momz,me.scale)/FU / 3 ) --+ (leveltime/10)
		) % 4
		me.frame = ($ &~FF_FRAMEMASK)|newframe
		me.tics = -1
	end
	
	if soap.rdashing
	and (me.state == S_PLAY_JUMP or me.state == S_PLAY_ROLL)
	and (p.pflags & PF_JUMPED)
		if p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash
		or soap.airdashed
			if (me.state ~= S_PLAY_DASH)
				me.state = S_PLAY_DASH
				p.panim = PA_DASH
			end
		end
	end
	
	if soap.uppercut_spin ~= 0
		if not (me.flags & MF_NOTHINK)
			p.drawangle = me.angle - FixedAngle(soap.uppercut_spin)
			
			soap.uppercut_spin = $ + (0 - $) / (soap.inWater and 10 or 7)
			
			if FixedFloor(soap.uppercut_spin) < 6*FU
				soap.uppercut_spin = 0
			end
		end
	end
	if soap.topspin ~= false
		p.drawangle = me.angle - FixedAngle(soap.topspin)
	end
end)
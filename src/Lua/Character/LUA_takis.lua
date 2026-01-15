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

local function P_PitchRoll(me, frac)
	me.eflags = $|MFE_NOPITCHROLLEASING
	local angle = R_PointToAngle2(0,0, me.momx,me.momy)
	local mang = R_PointToAngle2(0,0, FixedHypot(me.momx, me.momy), me.momz)
	mang = InvAngle($)
	
	local destpitch = FixedMul(mang, cos(angle))
	local destroll = FixedMul(mang, sin(angle))
	me.pitch = P_Lerp(frac, $, destpitch)
	me.roll  = P_Lerp(frac, $, destroll)
end

local function dolunge(p,me,soap, fromjump)
	Soap_DoLunge(p, fromjump)
end

local accelerative_speedlines = Soap_AccelerativeSpeedlines

local function canslingshot(p, takis)
	local lenient = 8 + p.cmd.latency
	
	--clutch spin
	if ( ((takis.clutch.combo >= 1)
	and (takis.clutch.good >= TR - lenient))
	--or we just clutched but didnt spam
	or (takis.clutch.tics >= (23 - lenient) and takis.clutch.good >= 0 and takis.clutch.time >= (lenient - p.cmd.latency)) )
	--feels nice
	or takis.clutch.spin
		return true
	end
	return false
end

local function generic_slingshot(p,me,takis, stop_ang)
	local didit = false
	if canslingshot(p, takis)
		P_Thrust(me,R_PointToAngle2(0,0,me.momx,me.momy),10*me.scale)
		
		for i = 0,9
			Soap_WindLines(me)
		end
		
		if not (p.pflags & PF_SPINNING or p.inkart)
			takis.bashspin = TR/2
			takis.clutch.spin = TR*3/4 + p.cmd.latency
		end
		
		--S_StartSound(me,sfx_sp_top)
		me.state = S_PLAY_TAKIS_TORNADO
		
		--reset clutch timer
		takis.clutch.time = CLUTCH_TICS
		takis.clutch.spamtime = CLUTCH_TICS
		takis.clutch.misfire = CLUTCH_MISFIRE
		takis.frictionfreeze = $ + TR/2
		takis.clutch.slinglag = true
		
		Soap_SquashMacro(p, {
			ease_func = "inexpo",
			ease_time = 6,
			x = -FU * 3/5,
			y = -FU/3,
			singular = true
		})
		
		if not (takis.fx.dash_aura and takis.fx.dash_aura.valid)
			local follow = P_SpawnMobjFromMobj(me,0,0,0,MT_SOAP_FREEZEGFX)
			follow.tics = -1
			follow.fuse = -1
			follow.tracer = me
			follow.bigwind = true
			follow.state = S_TAKIS_SLINGFX
			follow.dontdrawforviewmobj = me
			follow.zcorrect = true
			follow.angle = me.angle - ANGLE_90
			follow.spritexscale = $ * 3/2
			follow.spriteyscale = follow.spritexscale
			takis.fx.dash_aura = follow
		else
			takis.fx.dash_aura.state = S_TAKIS_SLINGFX
		end
		local aura = takis.fx.dash_aura
		
		aura.dist = 20*me.scale
		didit = true
	else 
		takis.afterimaging = false
		/*
		stopmom(takis,me,
			stop_ang ~= nil and stop_ang or TakisMomAngle(me)
		)
		*/
	end
	return didit
end

Takis_Hook.addHook("Takis_Thinker",function(p)
	local me = p.realmo
	local soap = p.soaptable
	
	local squishme = true
	local clutch = soap.clutch
	local hammer = soap.hammer
	local washammering = hammer.down
	soap.afterimage = false
	p.powers[pw_strong] = $ &~(STR_SPIKE)
	
	--TODO: move this skid block somewhere else?
	if (p.skidtime)
	and (me.state == S_PLAY_SKID)
		--nothing to do here yet
	else
		S_StopSoundByID(me,skins[TAKIS_SKIN].soundsid[SKSSKID])
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
	
	--momentum speedslop msv6
	do
		local topspeed = p.normalspeed
		if (me.state == S_PLAY_RUN)
			topspeed = p.runspeed - 2*FU
		end
		
		if (p.cmd.forwardmove or p.cmd.sidemove)
		and soap.accspeed >= topspeed
		and me.friction < FU
			me.friction = FU - FU/50
		end
		
		if me.friction > ORIG_FRICTION
		and not p.spectator
			if (soap.frictionfreeze == 0)
				local offset = soap.accspeed - topspeed
				
				--staying at slightly above top speed
				if (offset <= FU*3/2)
					soap.frictionremove = $ + 1
					if soap.frictionremove >= TR/2
						me.friction = ORIG_FRICTION
					end
				else
					soap.frictionremove = 0
				end
				
			else
				soap.frictionfreeze = $-1
				if soap.accspeed >= 60*FU
					soap.frictionfreeze = $/2
				end
				soap.frictionfreeze = max($,0)
				soap.frictionremove = 0
				me.friction = FU
			end
		else
			soap.frictionfreeze = 0
			soap.frictionremove = 0
		end
	end
	
	--clutch timers
	do
		if soap.accspeed <= 9*FU
		or (p.playerstate ~= PST_LIVE)
		or (soap.inPain)
		--or (takis.pitanim)
			clutch.tics = 0
			clutch.time = 0
			clutch.combo = 0
			clutch.misfire = 0
		end
		if (p.pflags & PF_SPINNING)
		or (me.state == S_PLAY_SOAP_SLIP)
			clutch.misfire = 0
			clutch.tics = 0
			clutch.time = 0
		end
		
		if clutch.good > 0
			clutch.good = max($-1, 0)
		--spammed
		elseif clutch.good < 0
			clutch.good = min($+1, 0)
		end
		clutch.spin = max($-1,0)
		
		if clutch.tics > 0
			clutch.tics = $-1
		elseif clutch.time == 0
		and not hammer.down
			clutch.combo = 0
		end
		clutch.time = max($,0)
		
		if clutch.spamtime
			clutch.spamtime = $ - 1
		else
			clutch.spamcount = 0
		end
		
		if clutch.misfire
			if (soap.onGround)
			or p.powers[pw_carry] == CR_ROLLOUT
				if (p.panim == PA_DASH)
					clutch.misfire = $-1
					if clutch.misfire <= 0
						S_StartSoundAtVolume(me, sfx_tk_cl4, 255*4/5)
						clutch.time = 0
						me.state = S_PLAY_WALK
						Soap_ResetState(p)
					end
				else
					clutch.misfire = TR
				end
			else
				clutch.misfire = TR
			end
		end
		
		if clutch.slinglag
			S_StartSound(me, sfx_sp_top)
			clutch.slinglag = false
		end
	end
	
	--spin specials
	if (soap.use)
		
		--clutch
		if (soap.use == 1)
		and (soap.onGround or p.powers[pw_carry] == CR_ROLLOUT)
		--and not soap.taunttime
		and me.health
		and (me.state ~= S_PLAY_GASP)
		and (me.sprite2 ~= SPR2_PAIN)
		and not (soap.noability & NOABIL_CLUTCH)
		and not (soap.isSliding)
			Takis_DoClutch(p)
		end
		
		--hammer blast
		if soap.use == (TR/5)
		and not soap.onGround
		and not hammer.down
		and not (soap.inPain)
		and me.health
		and (soap.notCarried)
		and not (soap.noability & NOABIL_HAMMER or hammer.lockout)
			p.pflags = $|PF_THOKKED &~PF_SHIELDABILITY
			
			hammer.down = 1
			hammer.angle = p.drawangle
			S_StartSoundAtVolume(me,sfx_tk_ahm, 255*9/10)
			Soap_ZLaunch(me,
				10*skins["takisthefox"].jumpfactor
			)
			
			me.state = S_PLAY_MELEE
			me.tics = -1
			--P_SetObjectMomZ(me,-9*FU)
		end
	end
	
	--c1 specials (TODO: taunts will go here enventually)
	if (soap.c1)
		
		--dive
		if soap.c1 == 1
		and not soap.onGround
		and not (soap.dived)
		and (soap.notCarried)
		and me.state ~= S_PLAY_PAIN
		and me.health
		and not hammer.down
		--and not PSO
		and not (soap.noability & NOABIL_DIVE)
		and not (soap.inPain)
			hammer.jumped = 0
			soap.bashspin = 0
			
			local ang = Soap_ControlDir(p)
			S_StartSound(me,soap.inWater and sfx_splash or sfx_tk_div)
			
			--im not sure if this actually does anything
			--but it seems to work so im leaving it
			if ((me.flags2 & MF2_TWOD)
			or (twodlevel))
				if (p.cmd.sidemove > 0)
					ang = p.drawangle
				elseif (p.cmd.sidemove < 0)
					ang = InvAngle(p.drawangle)
				end
			end
			
			local speed = soap.accspeed
			if soap.accspeed < 20*FU
				speed = 20*FU
			end
			P_InstaThrust(me,ang,FixedMul(speed,me.scale))
			
			p.drawangle = ang
			--CreateWindRing(p,me)
			--TakisSpawnDustRing(me,16*me.scale,0)
			
			p.pflags = $|PF_THOKKED &~(PF_JUMPED|PF_SPINNING)
			soap.dived = true
			soap.sprung = false
			soap.noability = $|NOABIL_SLIDE
			--takis.thokked = true
			
			me.state = S_PLAY_GLIDE
			local momz = FixedDiv(me.momz,me.scale)*soap.gravflip
			local thrust = min((momz/2)+7*FU,18*FU)
			Soap_ZLaunch(me,thrust)
		end
		
	end
	
	-- c2 specials
	if (soap.c2)
		
		--slide
		-- soap's slide is just a better coded takis slide
		-- so we'll be using his code
		if (soap.c2 == 1 or (me.eflags & MFE_JUSTHITFLOOR))
		and soap.c3 == 0
		--and soap.taunttime == 0
		and me.health
		
			if soap.onGround
			and (me.state ~= S_PLAY_SOAP_SLIP)
			--and not ((takis.tauntmenu.open) and (takis.tossflag))
			and not (soap.isSliding)
			and not (soap.noability & NOABIL_SLIDE)
			and soap.notCarried
				--if you were spinning already, and WERENT sliding,
				--you can flop on your belly so you can lunge later
				local wasspinning = (p.pflags & PF_SPINNING)
				
				local ang = R_PointToAngle2(0,0, me.momx,me.momy)
				local thrust
				if not wasspinning
					ang = Soap_ControlDir(p)
					S_StartSound(me,sfx_tk_sld)
					S_StartSound(me,sfx_tk_v00)
					
					thrust = 7*FU + (soap.accspeed)
					if thrust > 22*FU
						if (soap.accspeed < 22*FU)
							thrust = (22*FU - soap.accspeed) + soap.accspeed
						else
							thrust = 0
						end
					end
					
					thrust = FixedMul($,me.scale)
					if thrust > 0
						P_InstaThrust(me,ang,thrust)
					end
				end
				
				me.state = S_PLAY_SOAP_SLIP
				p.pflags = $|PF_SPINNING
				if not wasspinning
					P_MovePlayer(p)
					if not ((p.cmd.forwardmove) and (p.cmd.sidemove))
					and soap.accspeed + thrust < 14*FU
						P_InstaThrust(me,ang,15*me.scale)
					end
				end
				Soap_SquashMacro(p, {ease_func = "insine", ease_time = 12, strength = (FU/3), name = "soap_slide"})
				Soap_RemoveSquash(p, "landeffect")
				
				local start = (R_PointToAngle2(0,0,me.momx,me.momy) + ANGLE_180) - ANGLE_45
				local ang_frac = FixedDiv(90*FU, 12*FU)
				local dist = FixedDiv(me.radius,me.scale)
				for i = 0,8
					local fa = start + FixedAngle((ang_frac*i) + Soap_RandomFixedRange(-5*FU,5*FU))
					local dust = P_SpawnMobjFromMobj(me,
						P_ReturnThrustX(nil,fa, dist),
						P_ReturnThrustY(nil,fa, dist),
						0, MT_SOAP_DUST
					)
					dust.angle = fa
					P_Thrust(dust,fa, FixedMul(Soap_RandomFixedRange(1*FU,15*FU),me.scale))
					P_SetObjectMomZ(dust, Soap_RandomFixedRange(3*FU,15*FU))
					dust.scale = $ * 7/6
					
					Soap_WindLines(me,0,nil,nil, i < 4 and 1 or -1)
				end
				local angoff = ANGLE_45
				local dist = 20*FU
				local pushx = P_ReturnThrustX(nil, ang + ANGLE_90, 8*FU)
				local pushy = P_ReturnThrustY(nil, ang + ANGLE_90, 8*FU)
				for i = -1,1, 2
					local fx = P_SpawnMobjFromMobj(me,
						P_ReturnThrustX(nil, ang + angoff*i, dist) + pushx*i,
						P_ReturnThrustY(nil, ang + angoff*i, dist) + pushy*i,
						0, MT_SOAP_FREEZEGFX
					)
					fx.angle = (ang - ANGLE_180) - (angoff/2)*i
					fx.tracer = me
					
					fx.momx,fx.momy = me.momx/2,me.momy/2
					fx.momz = soap.rmomz
					fx.state = S_TAKIS_CDUST1
				end
			--auto-lunge / auto lunge
			elseif me.state == S_PLAY_SOAP_SLIP
			--and soap.onGround
				dolunge(p,me,soap)
				me.state = S_PLAY_ROLL
			end
		end
	end
	
	--jump specials
	if (soap.jump)
		-- auto lunge part 2
		if (soap.jump == 1)
		and me.state == S_PLAY_SOAP_SLIP
		and not soap.onGround
			dolunge(p,me,soap)
		end
	end
	
	local waslunging = soap.lunge.lunged
	if soap.lunge.lunged
		if not (me.state == S_PLAY_JUMP or me.state == S_PLAY_ROLL)
			soap.lunge.lunged = false
		elseif me.state == S_PLAY_JUMP
			me.state = S_PLAY_ROLL
		end
	end
	
	if not (soap.noability & SNOABIL_CROUCH)
		if p.pflags & PF_JUMPED then p.pflags = $ &~PF_SPINNING end
		
		local reset = false
		local last = soap.last.anim.state
		if (me.state == S_PLAY_SOAP_SLIP and last ~= S_PLAY_SOAP_SLIP)
		or (me.state == S_PLAY_ROLL and last ~= S_PLAY_ROLL)
		or (soap.lunge.lunged ~= waslunging)
		or (soap.last.pflags & PF_SPINNING ~= p.pflags & PF_SPINNING)
			soap.setrolltrol = false
			reset = true
		end
		
		if ((p.pflags & PF_SPINNING)
		or soap.lunge.lunged)
			if not soap.setrolltrol
				if soap.onGround
				and (p.pflags & PF_SPINNING)
					p.thrustfactor = skins[p.skin].thrustfactor * (me.state == S_PLAY_SOAP_SLIP and 3 or 7)
				end
				if soap.lunge.lunged
					p.thrustfactor = 10
				end
			end
			soap.setrolltrol = true
		else
			if soap.setrolltrol or reset
				p.thrustfactor = skins[p.skin].thrustfactor
			end
			soap.setrolltrol = false
		end
	elseif soap.setrolltrol
		p.thrustfactor = skins[p.skin].thrustfactor
	end
	
	if me.state == S_PLAY_SOAP_SLIP
		local angle,thrust = Soap_SlopeInfluence(me,p, {
			allowstand = true, allowmult = true
		})
		if angle ~= nil
			P_Thrust(me,angle,thrust*3/4)
		end
		
		if soap.accspeed >= 4*FU
		and soap.onGround
			local chance = P_RandomChance(FU/3)
			if soap.accspeed >= 15*FU
				chance = true
			end
			
			--kick up dust
			if chance
				p.dashspeed = 100*FU
				P_DoSpinDashDust(p)
				if not (me.eflags & (MFE_UNDERWATER|MFE_TOUCHLAVA) == MFE_UNDERWATER)
					S_StartSound(me,sfx_s3k7e)
				end
			end
		elseif not soap.onGround
			P_PitchRoll(me, FU/10)
		end
	end
	
	--stuff to do while carried
	if (p.powers[pw_carry] == CR_NIGHTSMODE)
		squishme = false
		--wind effect
		local spd = 23*FU
		local accspeed = abs(FixedHypot(FixedHypot(me.momx,me.momy),me.momz))
		accelerative_speedlines(p,me,soap, accspeed, spd)
		
		local drilling = (p.drilltimer
							and p.drillmeter
							and not p.drilldelay)
							and (soap.jump)
							and (me.state == S_PLAY_NIGHTS_DRILL)
		
		--if accspeed >= spd and drilling then spawn_aura = true; end
		soap.accspeed = accspeed
	elseif p.powers[pw_carry] == CR_MACESPIN
		if me.state ~= S_PLAY_ROLL
			me.state = S_PLAY_ROLL
		end
	elseif p.powers[pw_carry] == CR_NONE
	and not (soap.pounding or (soap.rdashing and not soap.airdashed))
		accelerative_speedlines(p,me,soap, FixedDiv(R_PointTo3DDist(0,0,0,me.momx,me.momy,me.momz),me.scale), 40*FU)
		
		-- i think the wind lines here make you feel really aerodynamic and fast
		-- and cool
		if me.state == S_PLAY_RUN
		and not (leveltime % 12)
		and P_RandomChance(FU*3/4)
			Soap_WindLines(me)
		end
	--kinda annoying how you cant pound when exiting a dust devil
	elseif soap.last.carry == CR_DUSTDEVIL
		soap.sprung = true
	elseif p.powers[pw_carry] == CR_PTERABYTE
		if (soap.use == 1)
			Takis_DoClutch(p)
		end
		Takis_ResetHammerTime(p)
	elseif p.powers[pw_carry] == CR_MINECART	
		local cart = me.tracer
		
		local momx,momy = me.x - soap.last.x, me.y - soap.last.y
		soap.accspeed = FixedDiv(abs(FixedHypot(momx,momy)), me.scale)
		soap.rmomz = -(me.z - soap.last.z)
		if soap.use == 1
		and not (soap.inPain)
			Takis_DoClutch(p,cart)
		end
		if (soap.inPain)
		and soap.accspeed >= 15*cart.scale
			cart.momx = $*9/10
			cart.momy = $*9/10
		end
		
		--Moved here to remove a mobjthinker
		if (cart and cart.valid)
		and (cart.health and me.health)
		and (soap.c1)
			p.powers[pw_carry] = CR_NONE
			
			p.mo.momx,p.mo.momy = cart.momx,cart.momy
			
			p.pflags = $|PF_JUMPED &~PF_THOKKED
			soap.dived = false
			
			P_SetObjectMomZ(me,8*FU)
			P_DoJump(p,true)
			p.mo.state = S_PLAY_ROLL
			
			--TakisGiveCombo(p,takis,true)
			cart.target = nil
		end
	elseif (p.powers[pw_carry] == CR_ROLLOUT)
		local rock = me.tracer
		
		if (rock and rock.valid)
			if me.state == S_PLAY_FALL
			or me.state == S_PLAY_MELEE
				me.state = S_PLAY_STND
				P_MovePlayer(p)
			end
			
			if P_GetPlayerControlDirection(p) == 2
			and soap.accspeed >= 5*FU
				local skidsound = skins[TAKIS_SKIN].soundsid[SKSSKID]
				if not S_SoundPlaying(rock,skidsound)
				and not S_SoundPlaying(me,skidsound)
					S_StartSound(rock,skidsound)
				end
				
				rock.spriteyoffset = (2*FU)*((leveltime % 2) and 1 or -1)
				
				local sp = P_SpawnMobjFromMobj(rock,0,0,0,MT_SOAP_SPARK)
				sp.color = SKINCOLOR_GOLDENROD
				sp.adjust_angle = R_PointToAngle2(0,0, rock.momx, rock.momy) + FixedAngle(Soap_RandomFixedRange(-45*FU,45*FU))
				sp.adjust_angle = $ + ANGLE_180
				sp.angle = sp.adjust_angle
				sp.target = rock
				sp.dontdelete = true
				sp.spritexscale = FU
				sp.spriteyscale = FU * 3/4
				
				do --if (leveltime & 1)
					local spark = P_SpawnMobjFromMobj(rock,0,0,0,MT_SOAP_WALLBUMP)
					local speed = 12*rock.scale
					local limit = 28
					local my_ang = FixedAngle(Soap_RandomFixedRange(0,360*FU))
					
					P_InstaThrust(spark, my_ang, speed)
					P_SetObjectMomZ(spark, Soap_RandomFixedRange(3*FU,8*FU))
					
					P_SetScale(spark,rock.scale / 10, true)
					spark.destscale = rock.scale
					--5 tics
					spark.scalespeed = FixedDiv(rock.scale - rock.scale / 10, 5*FU)
					spark.color = SKINCOLOR_GOLDENROD
					spark.colorized = true
					spark.fuse = TR
					
					spark.spritexscale = FU * 3/2
					spark.spriteyscale = spark.spritexscale
					
					spark.random = P_RandomRange(-limit,limit) * ANG1
				end
				
				local friction = FU*21/22
				rock.momx,rock.momy = FixedMul($1,friction),FixedMul($2,friction)
			else
				S_StopSoundByID(rock, skins[TAKIS_SKIN].soundsid[SKSSKID])
				rock.spriteyoffset = 0
			end
		end
	end
	
	if not soap.notCarried
		Takis_ResetHammerTime(p)
	end
	
	if soap.canceltime
		soap.canceltime = $ - 1
		if soap.canceltime == 0
			soap.lunge.lunged = false
			soap.lunge.angle = nil
		end
	end
	
	if (me.state == S_PLAY_GLIDE)
		P_PitchRoll(me, FU/5)
		if soap.accspeed > FU
			p.drawangle = R_PointToAngle2(0,0,me.momx,me.momy)
		else
			p.drawangle = me.angle
		end
		p.thrustfactor = 2
		soap.setrolltrol = true
		
		-- jump out of a dive / cancel a dive
		if (soap.jump == 1 or soap.c1 == 1)
		and not (soap.noability & NOABIL_SLIDE)
		and not (soap.use)
			me.state = S_PLAY_SOAP_SLIP
			Soap_DoLunge(p, false)
			soap.noability = $|NOABIL_DIVE
			soap.setrolltrol = false
			soap.canceltime = TR/2
		end
	end
	
	p.charflags = $ &~(SF_RUNONWATER|SF_NOSKID)|(soap.lunge.effect and SF_NOSKID or 0)
	if not (soap.noability & NOABIL_AFTERIMAGE)
		if clutch.time
		/*
		or takis.glowyeffects
		or (takis.hammerblastdown and (me.momz*takis.gravflip <= -60*me.scale)
			and not takis.shotgunned)
		or (takis.drilleffect and takis.drilleffect.valid)
		*/
		or (clutch.nights)
		--or (takis.bashtime)
		/*
		or (p.inkart and (me.tracer and me.tracer.valid) and me.tracer.type == MT_TAKIS_KART_HELPER 
			and takis.accspeed >= 45*FU --FixedHypot(me.tracer.momx,me.tracer.momy) >= 45*FU
			and (true == false)
		)
		*/
		--or (takis.transfo & TRANSFO_BALL and takis.accspeed >= 50*FU)
		and ((me.health) or (p.playerstate == PST_LIVE))
			clutch.time = $+1
			soap.afterimage = true
			p.powers[pw_strong] = $|STR_SPIKE
			
			if not (soap.bashspin)
				clutch.dustspawn = $ + FixedDiv(soap.accspeed,64*FU) / 4
				while clutch.dustspawn > FU
					clutch.dustspawn = $-FU
					if (soap.onGround)
					and (soap.accspeed >= 12*FU)
						local ang = p.drawangle
						local aoff = ANGLE_45
						local dist = 20*FU
						local pushx = P_ReturnThrustX(nil, ang + ANGLE_90, 4*FU)
						local pushy = P_ReturnThrustY(nil, ang + ANGLE_90, 4*FU)
						for i = -1,1, 2
							local fx = P_SpawnMobjFromMobj(me,
								P_ReturnThrustX(nil, ang + aoff*i, dist) + pushx*i + FixedDiv(me.momx, me.scale),
								P_ReturnThrustY(nil, ang + aoff*i, dist) + pushy*i + FixedDiv(me.momy, me.scale),
								0, MT_SOAP_FREEZEGFX
							)
							fx.tracer = me
							fx.destscale = me.scale / 10
							fx.angle = (ang - ANGLE_180) - (aoff/2)*i
							fx.momx,fx.momy = me.momx/4, me.momy/4
							fx.momz = soap.rmomz
							fx.state = S_TAKIS_CDUST1
						end
					end
				end
			end
			
			--p.charflags = $|SF_CANBUSTWALLS
			--p.powers[pw_strong] = $|STR_WALL
			
			if Soap_DirBreak(p,me, R_PointToAngle2(0,0,me.momx,me.momy))
			and not (p.pflags & PF_SPINNING)
				generic_slingshot(p,me,soap)
				--S_StartSound(me,sfx_takmcn)
				Soap_StartQuake(20*FU, 19,
					{me.x,me.y,me.z},
					512*me.scale
				)
			end
			
			if (soap.accspeed >= skins[TAKIS_SKIN].normalspeed*2)
				p.charflags = $|SF_RUNONWATER
			else
				p.charflags = $ &~(SF_RUNONWATER)
			end
			
			--if not (p.pflags & PF_SPINNING)
			/*
			if not (takis.glowyeffects)
			and not (takis.clutchingtime % 2)
				TakisCreateAfterimage(p,me)
			end
			*/
			soap.afterimage = true
			
			if (soap.accspeed > FU)
				p.runspeed = soap.accspeed - FU
			else
				p.runspeed = skins[TAKIS_SKIN].runspeed/2
			end
			
			/*
			if p.panim == PA_DASH
				TakisSpawnDust(me,
					p.drawangle+FixedAngle(P_RandomRange(-45,45)*FU+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))),
					P_RandomRange(0,-50),
					P_RandomRange(-1,2)*me.scale,
					{
						xspread = 0,--(P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
						yspread = 0,--(P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
						zspread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
						
						thrust = P_RandomRange(0,-10)*me.scale,
						thrustspread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
						
						momz = P_RandomRange(4,0)*P_RandomRange(3,10)*(me.scale/2),
						momzspread = ((P_RandomChance(FU/2)) and 1 or -1),
						
						scale = me.scale,
						scalespread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
						
						fuse = 15+P_RandomRange(-5,5),
					}
				)
			end
			*/
		else
			if not p.inkart
				p.charflags = $ &~(SF_RUNONWATER)
				p.runspeed = skins[TAKIS_SKIN].runspeed/2
			end
			clutch.time = 0
		end
	else
		if not p.inkart
			p.charflags = $ &~(SF_RUNONWATER)
			p.runspeed = skins[TAKIS_SKIN].runspeed/2
		end
		clutch.time = 0
	end
	
	--hammer blast thinker
	--hammerblast thinker
	--hammerblast stuff
	--this is a bad spot for this but eh fuck it
	if hammer.down
		Takis_AbilityHelpers.hammerthinker(p)
	else
		p.powers[pw_strong] = $ &~(STR_SPRING|STR_HEAVY)
		/*
		if takis.transfo & TRANSFO_METAL
			p.powers[pw_strong] = $|STR_HEAVY
		end
		*/
		hammer.up = 0
		S_StopSoundByID(me,sfx_tk_fst)
		S_StopSoundByID(me,sfx_tk_hmd)
	end
	if hammer.lockout
		hammer.lockout = $ - 1
	end
	if hammer.jumped
		hammer.jumped = $+1
		if soap.onGround
			hammer.jumped = 0
		end
	end

	if not soap.afterimage
		if me.state == S_PLAY_DASH
			--doin this weird shit because there'd be a frame
			--where youd be in the walk state when above runspeed
			if (soap.accspeed) >= p.runspeed
				me.state = S_PLAY_RUN
			else
				me.state = S_PLAY_WALK
			end
			
			Soap_ResetState(p)
		end
	elseif not soap.bashspin
		if me.state == S_PLAY_WALK
		or me.state == S_PLAY_RUN
			me.state = S_PLAY_DASH
			Soap_ResetState(p)
			p.panim = PA_DASH
		end
	end
	
	--TODO: once state checkers like these are made, move this there
	if soap.sprung
	or Soap_BouncyCheck(p)
	or soap.onGround
	or (not soap.notCarried)
		if Soap_BouncyCheck(p)
			p.pflags = $ &~PF_THOKKED
		end
		
		soap.dived = false
	end
	
	if soap.bashspin
	and not ((p.pflags & PF_SPINNING)
	or p.skidtime and me.state == S_PLAY_SKID
	or me.state == S_PLAY_SPRING
	or (soap.inPain))
	and me.health
		if me.state ~= S_PLAY_TAKIS_TORNADO
			me.state = S_PLAY_TAKIS_TORNADO
		end
		if soap.bashspin == 1 then soap.bashendangle = p.drawangle end
		p.drawangle = me.angle - (soap.bashspin*ANG30)
		soap.bashspin = $-1
	else
		soap.bashspin = 0
		
		if (p.powers[pw_carry] == CR_NONE or p.powers[pw_carry] == CR_ROLLOUT)
		and me.state == S_PLAY_TAKIS_TORNADO
			if me.health
				me.state = S_PLAY_DASH
				Soap_ResetState(p)
			end
			
			if hammer.jumped
				me.state = S_PLAY_SPIN
			end
		end
	end
	if not soap.bashspin then soap.bashendangle = nil end
	if soap.bashspin < 0 then soap.bashspin = 0 end
	
	if (soap.fx.uppercut_aura and soap.fx.uppercut_aura.valid)
		P_RemoveMobj(soap.fx.uppercut_aura)
		soap.fx.uppercut_aura = nil
	end
	
	Soap_VFX(p,me,soap, {
		squishme = squishme,
		was_pounding = washammering,
		halfsquish = washammering or hammer.down
	})
	Soap_DeathThinker(p,me,soap)
end)

addHook("PlayerHeight",function(p)
	if not (p and p.valid) then return end
	if not p.soaptable then return end
	if (skins[p.skin].name ~= TAKIS_SKIN) then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if me.state == S_PLAY_GLIDE
	or me.state == S_PLAY_SPINDASH
		return P_GetPlayerSpinHeight(p)
	end
end)
addHook("PlayerCanEnterSpinGaps",function(p)
	if not (p and p.valid) then return end
	if not p.soaptable then return end
	if (skins[p.skin].name ~= TAKIS_SKIN) then return end
	local me = p.realmo
	if not (me and me.valid) then return end

	if me.state == S_PLAY_GLIDE
	or me.state == S_PLAY_SPINDASH
		return true
	end
end)

--jump effect
addHook("JumpSpecial", function(p)
	if p.mo.skin ~= TAKIS_SKIN then return end
	
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
	if (me.ceilingz - me.floorz <= me.height - 1) then return end
	
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
		
		Soap_SquashMacro(p, {ease_func = "outsine", ease_time = 8, x = -FU*7/10, y = -FU/2})
		Soap_RemoveSquash(p, "soap_slide")
		Soap_RemoveSquash(p, "landeffect")
		Soap_RemoveSquash(p, "Takis_Clutch")
		me.soap_jumpdust = 4
		me.soap_jumpeffect = nil
		soap.dived = false
		
		dolunge(p,me,soap, true)
		if soap.lunge.lunged
			me.state = S_PLAY_ROLL
		end
	end
end)

--double jump
addHook("AbilitySpecial", function(p)
	if p.mo.skin ~= TAKIS_SKIN then return end
	
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
	S_StopSoundByID(me,skins[TAKIS_SKIN].soundsid[SKSJUMP])
	
	local jfactor = min(FixedDiv(p.jumpfactor,skins[TAKIS_SKIN].jumpfactor),FU)
	Soap_ZLaunch(p.mo,FixedMul(12*FU,jfactor))
	
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
	if (me.skin ~= TAKIS_SKIN) then return end
	local soap = p.soaptable
	
	if (soap.afterimage)
		return true
	end
end)

Takis_Hook.addHook("MoveBlocked",function(me,thing,line, goingup)
	local p = me.player
	local soap = p.soaptable
	
	if me.skin ~= TAKIS_SKIN then return end
	
	if not (me.state == S_PLAY_DASH or me.state == S_PLAY_TAKIS_TORNADO or me.state == S_PLAY_GLIDE) then return end
	if goingup then return end
	
	if ((thing and thing.valid) or (line and line.valid and P_LineIsBlocking(me,line)))
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
	if (soap.damagedealtthistic > SOAP_MAXDAMAGETICS) then return end
	soap.damagedealtthistic = $ + 1
	if me.skin ~= TAKIS_SKIN then return end
	
	local DealDamage = (p.powers[pw_super] or soap.isSolForm or p.powers[pw_invulnerability]) and P_KillMobj or P_DamageMobj
	
	--if the thing we're killing ISNT a player, then theyre probably an enemy
	if thing.type ~= MT_PLAYER
	or not (thing.player and thing.player.valid)
		if Soap_CanDamageEnemy(p, thing)
			if not Soap_ZCollide(me,thing, true) then return end
			
			--hit by r-dash / b-rush
			if (soap.afterimage)
				Soap_ImpactVFX(thing,me)
				
				local power = FixedMul(10*FU + max(soap.accspeed - 20*FU,0), me.scale)
				
				local hitlag_tics = 5
				--P_Thrust(me, R_PointToAngle2(0,0,me.momx,me.momy), me.scale*8)
				
				DealDamage(thing, me,me)
				if generic_slingshot(p,me,soap)
					Soap_Hitlag.addHitlag(me, hitlag_tics, false)
					--Soap_DamageSfx(thing, FU*3/4,FU, {ultimate = false})
					S_StartSoundAtVolume(me, sfx_tk_hml, 255*3/4)
					S_StartSound(me, sfx_sp_kil)
					S_StartSound(me, sfx_sp_smk)
					
					P_StartQuake(power, hitlag_tics + 3,
						{me.x, me.y, me.z},
						512*me.scale + power
					)
				else
					Soap_DamageSfx(thing, power, 60*FU, {ultimate = true})
					P_StartQuake(power/2, hitlag_tics,
						{me.x, me.y, me.z},
						512*me.scale + power
					)
				end
				
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

--various effects
--handle soap damage
addHook("MobjDamage", function(me,inf,sor,dmg,dmgt)
	if not (me and me.valid) then return end
	if me.skin ~= TAKIS_SKIN then return end
	
	local p = me.player 
	local soap = p.soaptable

	local hook_event,hook_name = Takis_Hook.findEvent("Char_OnDamage")
	if hook_event
		for i,v in ipairs(hook_event)
			local short = Takis_Hook.tryRunHook(hook_name, v, me,inf,sor,dmg,dmgt)
			
			-- does not short out the calling MobjDamage
			if short == true then return; end
		end
	end
	
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
	if me.skin ~= TAKIS_SKIN then return end
	
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

Takis_Hook.addHook("PostThinkFrame",function(p)
	local me = p.mo
	local soap = p.soaptable
	
	if me.skin ~= TAKIS_SKIN then return end
	
	if (me.flags & MF_NOTHINK) then return end
	
	if me.sprite2 == SPR2_STUN
		p.drawangle = $ - ANG15
	end
	
end)
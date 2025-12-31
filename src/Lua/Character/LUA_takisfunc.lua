local CV = SOAP_CV
local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end

rawset(_G,"Takis_DoClutch",function(p,riding)
	local me = p.mo
	local takis = p.soaptable
	local clutch = takis.clutch
	
	if not (me and me.valid) then return end
	if (p.playerstate == PST_DEAD) then return end
	if not me.health then return end

	if (p.powers[pw_carry] == CR_NIGHTSMODE)
		if (p.bumpertime) then return end
		if (p.drillmeter < 30) then return end
		if (p.powers[pw_flashing] > (2*flashingtics/3)) then return end
		if not (me.state == S_PLAY_NIGHTS_FLY or me.state == S_PLAY_NIGHTS_DRILL) then return end
		--allow braking if you're not inputting anything
		if not (p.cmd.forwardmove or p.cmd.sidemove) then return end
		
		--TakisSoundEffect(me,sfx_tk_cl0,255*3/5,p)
		--TakisSoundEffect(me,sfx_tk_cl1,133,p)
		if not takis.inWater
			S_StartSoundAtVolume(me,sfx_tk_cl2,179)
		else
			S_StartSoundAtVolume(me,sfx_tk_cl3,220)
		end
		
		--align yourself
		local newangle = 0
		do
			if not (p.cmd.forwardmove)
				if (p.cmd.sidemove > 0)
					newangle = 0
				elseif p.cmd.sidemove < 0
					newangle = 180
				end
				
			elseif not (p.cmd.sidemove)
				if (p.cmd.forwardmove > 0)
					newangle = 90
				elseif p.cmd.forwardmove < 0
					newangle = 270
				end
				
			else
				newangle = FixedInt(AngleFixed(
					R_PointToAngle2(0,0,
						p.cmd.sidemove*FU,
						p.cmd.forwardmove*FU
					)
				))
			end
			newangle = $ - (p.viewrollangle/ANG1)
			
			if newangle < 0 then newangle = 360 + $ end
		end
		
		p.flyangle = newangle
		p.speed = min($ + 7500,20000)
		p.drillmeter = max($ - 30, 0)
		p.bumpertime = TR/2
		clutch.nights = p.bumpertime
		return
	end
	
	--but wait! first thing we needa do is check if we're
	--allowed to clutch on a rollout rock
	if (p.powers[pw_carry] == CR_ROLLOUT)
		local rock = me.tracer
		local inwater = rock.eflags & (MFE_TOUCHWATER|MFE_UNDERWATER)
		--if the rock isnt grounded, dont clutch
		if not (P_IsObjectOnGround(rock) or inwater)
			return
		end
	end
	
	local ccombo = min(clutch.combo,3)
	
	if ccombo >= 3
		if me.friction < FU
			me.friction = FU + FU/10
			takis.frictionfreeze = TR/2
		end
	end
	
	--sounds mostly similar to final game
	S_StartSoundAtVolume(me,sfx_tk_cl0,255*3/5)
	S_StartSoundAtVolume(me,sfx_tk_cl1,133)
	if not takis.inWater
		S_StartSoundAtVolume(me,sfx_tk_cl2,179)
	else
		S_StartSoundAtVolume(me,sfx_tk_cl3,220)
	end
	
	clutch.time = 1
	
	local thrust = 7*FU + FixedMul( (2*FU), (ccombo*FU)/2 )
	if p.powers[pw_sneakers]
		if thrust >= 25*FU
			thrust = 25*FU
		end
	else
		if thrust >= 12*FU
			thrust = 12*FU
		end
	end
	
	local clutchadjust = clutch.tics --max((takis.clutchtime - p.cmd.latency),0)
	local spammed = false
	local combod = false
	
	--clutch boost
	if (clutchadjust > 0)
		if (clutchadjust <= CLUTCH_TICS - CLUTCH_OKAY)
			combod = true
			clutch.combo = $+1
			clutch.combotime = 2*TR
			clutch.good = TR
			
			S_StartSoundAtVolume(me,sfx_kc5b,255/2)
			
			--effect
			local ghost = P_SpawnGhostMobj(me)
			ghost.scale = 3*me.scale/2
			ghost.destscale = FixedMul(me.scale,2)
			ghost.colorized = true
			ghost.frame = $|TR_TRANS10
			ghost.blendmode = AST_ADD
			ghost.state = S_PLAY_TAKIS_TORNADO
			ghost.tics = -1
			
			ghost.momx,ghost.momy = me.momx,me.momy
			ghost.momz = takis.rmomz
			
			thrust = $+(3*FU/2)+FU
		--dont thrust too early, now!
		elseif (clutchadjust > CLUTCH_TICS - CLUTCH_BAD)
		--Who cares!
		and not p.exiting
			
			spammed = true
			clutch.spamcount = $+1
			clutch.combo = 0
			clutch.combotime = 0
			thrust = FU/5
			if clutch.spamcount >= 3
				thrust = 0
			end
			clutch.good = -TR
		end
	end
	
	if p.powers[pw_sneakers]
		thrust = $*8/5
	end
	
	if p.gotflag
		thrust = $/6
	end
	
	--stop that stupid momentum mod from givin
	--us super speed for spamming
	if thrust == 0
	and not p.powers[pw_sneakers]
	and (clutch.spamcount >= 3)
		P_InstaThrust(me,Soap_ControlDir(p),FixedDiv(
				FixedMul(takis.accspeed,me.scale),
				3*FU
			)
		)
		me.movefactor = $/2
	end
	
	if (takis.accspeed > ((p.powers[pw_sneakers] or takis.isSuper) and 40*FU or 35*FU))
		takis.frictionfreeze = TR/2
		me.friction = FU + FU/10
		if not p.powers[pw_sneakers]
			thrust = 5 * FU
		end
	end
	
	local mo = (riding and riding.valid) and riding or ((p.powers[pw_carry] == CR_ROLLOUT) and me.tracer or me)
	
	local twod = (mo.flags2 & MF2_TWOD or twodlevel)
	local ang = Soap_ControlDir(p) --((Soap_ControlStyle ~= CS_AUTOMATIC) and not twod) and Soap_ControlDir(p) or me.angle
	
	local speedmul = FU
	if twod
		speedmul = $*3/4
		thrust = $/2
	end
	if (takis.inWater)
	and not twod
		speedmul = $*3/4
	end
	if (p.gotflag)
		speedmul = $*7/10
	end
	
	if (p.onconveyor == 4)
		local convspeed = FixedHypot(p.cmomx,p.cmomy)
		local convang = R_PointToAngle2(0,0, p.cmomx,p.cmomy)
		
		local angdiff = FixedAngle(
			AngleFixed(convang) - AngleFixed(ang)
		)
		if AngleFixed(angdiff) > 180*FU
			angdiff = InvAngle($)
		end
		
		--only give extra speed when going against
		if not (AngleFixed(angdiff) > 115*FU)
			convspeed = 0
		end
		
		thrust = $ + FixedMul(convspeed,me.scale)/4
	end
	
	thrust = FixedMul(thrust,me.scale)
	p.pflags = $ &~PF_SPINNING
	if mo == me
		P_Thrust(mo,ang,thrust)
		p.drawangle = ang
	else
		if (p.powers[pw_carry] == CR_ROLLOUT)
			P_InstaThrust(mo,ang,
				FixedHypot(mo.momx,mo.momy)+thrust
			)
			p.drawangle = ang + ANGLE_180
		else
			if (p.powers[pw_carry] == CR_MINECART)
				if takis.accspeed >= 50*mo.scale
					mo.momx = $*8/10
					mo.momy = $*8/10
					thrust = 0
				else
					thrust = $/4
				end
			end
			P_Thrust(mo,ang,thrust)
			p.drawangle = ang
		end
	end
	
	local runspeed = FixedMul(skins[TAKIS_SKIN].runspeed,speedmul) - 4*FU
	if takis.accspeed < runspeed
		P_Thrust(mo,ang, FixedMul(runspeed - takis.accspeed,me.scale))
	end
	
	--print(string.format("%f	  %f	%d	%f	%d", thrust, takis.accspeed, takis.clutchcombo, me.friction, takis.frictionfreeze))
	
	local ease_time = 5
	local ease_func = "insine"
	local strength = combod and (FU * 3/4) or (FU/2)
	Soap_AddSquash(p, {
		ease_func = ease_func,
		start_v = strength,
		end_v = 0,
		time = ease_time
	}, {
		ease_func = ease_func,
		start_v = -strength*3/4,
		end_v = 0,
		time = ease_time
	}, "Takis_Clutch", true)
	
	if takis.onGround
		me.state = S_PLAY_DASH
		P_MovePlayer(p)
		p.panim = PA_DASH
	end
	clutch.tics = CLUTCH_TICS
	clutch.spamtime = CLUTCH_TICS
	clutch.misfire = CLUTCH_MISFIRE
	takis.bashspin = 9
	takis.hammer.lockout = TR/5
	
	/*
	if takis.clutchspamcount == 5
		TakisAwardAchievement(p,ACHIEVEMENT_CLUTCHSPAM)
	end
	*/
	
	--takis.coyote = 0
	takis.noability = $ &~NOABIL_AFTERIMAGE
	
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
		
		-- original code used mo so it should probably stay that way
		fx.momx,fx.momy = mo.momx/2,mo.momy/2
		fx.momz = takis.rmomz
		fx.state = combod and S_TAKIS_CDUST2 or S_TAKIS_CDUST1
		fx.flags = $ &~MF_NOCLIPHEIGHT
	end
end)

local cv_hidetime = CV.FindVar("hidetime")
rawset(_G,"Takis_HandleNoAbils", function(p)
	local soap = p.soaptable
	local me = p.realmo
	local na = 0
	
	if not (me and me.valid) then return end
	if p.spectator
		soap.noability = NOABIL_ALL
		return
	end
	
	if (p.gotflag)
	or (p.gotcrystal)
		na = $|NOABIL_HAMMER|NOABIL_AFTERIMAGE
	end
	
	if soap.hammer.lockout
		na = $|NOABIL_HAMMER
	end
	
	local hiding = false
	if (gametyperules & (GTR_STARTCOUNTDOWN|GTR_FRIENDLY) == GTR_STARTCOUNTDOWN)
		if leveltime <= cv_hidetime.value*TR
			hiding = true
			if (gametyperules & (GTR_BLINDFOLDED|GTR_TAG))
				if not (p.pflags & PF_TAGIT)
					hiding = false
				end
			end
		else
			if (gametyperules & GTR_HIDEFROZEN)
			and not (p.pflags & PF_TAGIT)
				hiding = true
			end
		end
	end
	
	if (p.exiting)
	or (p.inkart)
	or hiding or ((gametyperules & GTR_RACE) and p.realtime == 0)
		na = $|NOABIL_ALL &~NOABIL_CLUTCH
		/*
		if (p.exiting)
		or (hiding or ((gametyperules & GTR_RACE) and p.realtime == 0))
			na = $ &~SNOABIL_BOTHTAUNTS
		end
		*/
	end
	
	/*
	if (soap.isSliding)
		na = $|SNOABIL_CROUCH|SNOABIL_RDASH|SNOABIL_AIRDASH|SNOABIL_POUND
	end
	if p.powers[pw_carry] == CR_ROPEHANG
		na = $|SNOABIL_AIRDASH|SNOABIL_UPPERCUT	
	elseif p.powers[pw_carry] == CR_MACESPIN
		na = $|SNOABIL_AIRDASH|SNOABIL_CROUCH|SNOABIL_POUND|SNOABIL_UPPERCUT
	end
	
	if soap.taunttime
		na = $|SNOABIL_CROUCH|SNOABIL_TOP
	end
	*/
	
	--battle special cases
	if soap.inBattle
		local noaction = false
		if p.powers[pw_nocontrol]
		or p.powers[pw_carry]
		or (p.airdodge > 0)
		or (CBW_Battle.Exiting or CBW_Battle.Timeout)
		or (p.isjettysyn)
			noaction = true
		end
		
		if (p.tumble)
		or P_PlayerInPain(p)
		--or not CBW_Battle.CanDoAction(p)
		or noaction
			na = $|SNOABIL_ALL
			if (CBW_Battle.Exiting or CBW_Battle.Timeout)
				na = $ &~(SNOABIL_BOTHTAUNTS)
			end
		end
	end
	
	--Gametypes
	if (MM and MM:isMM())
	or gametype == GT_ZE2
		local debugmode = false
		if (MM and MM:isMM())
			if CV_MM.debug.value
				debugmode = true
			end
		elseif gametype == GT_ZE2
			if ZE2.cv_debug.value
				debugmode = true
			end
		end
		
		if not debugmode
			na = $|SNOABIL_TAUNTSONLY|SNOABIL_BREAKDANCE
		end
		if gametype == GT_ZE2
			if ZE2.game_ended
				na = $ &~SNOABIL_BREAKDANCE
			end
		end
	end
	
	if (me.state >= S_PLAY_SUPER_TRANS1)
	and (me.state <= S_PLAY_SUPER_TRANS6)
		na = $|SNOABIL_ALL
	end
	
	if (PSO)
		na = $|SNOABIL_ALL &~SNOABIL_BOTHTAUNTS
	end
	
	--return value: new noabilities field (absolute)
	local hook_event,hook_name = Takis_Hook.findEvent("Char_NoAbility")
	if hook_event
		for i,v in ipairs(hook_event)
			local new_noabil = Takis_Hook.tryRunHook(hook_name, v, p, na)
			if new_noabil ~= nil
			and type(new_noabil) == "number"
				na = abs(new_noabil)
			end
		end
	end
	
	soap.noability = $|na
end)

--reset hammerblast
rawset(_G, "Takis_ResetHammerTime", function(p)
	local hammer = p.soaptable.hammer
	hammer.down = 0
	hammer.wentdown = false
	hammer.jumped = 0
	hammer.groundtime = 0
	hammer.up = 0
	p.thrustfactor = skins[TAKIS_SKIN].thrustfactor
end)

local function forcehambounce(p)
	local me = p.realmo
	local takis = p.soaptable
	local hammer = takis.hammer
	
	Takis_DoHammerBlastLand(p,false)
	
	hammer.jumped = 1
	
	P_DoJump(p,false)
	me.state = S_PLAY_SPINDASH
	
	local momz = 10*FU
	if me.health
	and not (takis.inPain)
		if takis.jump > 0
		and not (takis.noability & NOABIL_THOK)
			momz = 15*FU
		elseif takis.use > 0
			P_Thrust(me, me.angle, 8 * me.scale)
			momz = 8 * FU
			
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
		end
	end
	Soap_ZLaunch(me,momz)
	
	S_StartSoundAtVolume(me,sfx_kc52,180)
	
	p.pflags = $|PF_JUMPED &~PF_THOKKED
	takis.dived = false
end

--hammerhitbox
rawset(_G,"Takis_HammerBlastHitbox",function(p)
	local me = p.realmo
	local takis = p.soaptable
	local didit = false
	
	if takis.inBattle
		p.lockmove = false
		p.melee_state = 0
	end
	
	local dist = 62*FU
	local ang = p.drawangle
	local thok = P_SpawnMobjFromMobj(
		me,
		P_ReturnThrustX(nil,ang,dist) + FixedDiv(me.momx, me.scale),
		P_ReturnThrustY(nil,ang,dist) + FixedDiv(me.momy, me.scale),
		-TAKIS_HAMMERDISP + FixedDiv(me.momz * takis.gravflip, me.scale),
		MT_THOK
	)
	P_SetOrigin(thok, thok.x,thok.y,thok.z)
	thok.radius = 40*me.scale
	thok.height = 60*me.scale
	thok.scale = me.scale
	thok.fuse = 2
	thok.flags2 = $|MF2_DONTDRAW
	
	if Soap_BreakFloors(p,thok)
		didit = true
	end
	
	--wind ring
	/*
	if not (takis.hammerblastdown % 6)
	and takis.hammerblastdown > 6
	and (me.momz*takis.gravflip < 0)
	and (thok and thok.valid)
		local ring = P_SpawnMobjFromMobj(thok,
			0,0,-5*FU*takis.gravflip,MT_THOK --MT_WINDRINGLOL
		)
		if (ring and ring.valid)
			ring.renderflags = RF_FLOORSPRITE
			ring.frame = $|FF_TRANS50
			ring.startingtrans = FF_TRANS50
			ring.scale = FixedDiv(me.scale,2*FU)
			P_SetObjectMomZ(ring,10*me.scale)
			--i thought this would fade out the object
			ring.fuse = 10
			ring.destscale = FixedMul(ring.scale,2*FU)
			ring.colorized = true
			ring.color = SKINCOLOR_WHITE
			ring.state = S_SOAPYWINDRINGLOL
			if (takis.gravflip == -1)
				ring.z = $ - me.height
			end
		end
	end
	*/
	
	local nerfed = false
	if takis.inBattle
	or (FangsHeist and FangsHeist.isMode())
	or G_RingSlingerGametype()
		nerfed = true
	end
	
	local fakerange = 250*FU
	local range = thok.radius*3/2
	local enemyhit = false
	searchBlockmap("objects", function(ref, found)
		if found == me then return end
		if R_PointToDist2(found.x, found.y, thok.x, thok.y) > range + found.radius
			return
		end
		if not Soap_ZCollide(found,thok) then return end
		if not (found.health) then return end
		if not P_CheckSight(me,found) then return end
		if (found.alreadykilledthis) then return end
		
		if (found.type == MT_TNTBARREL)
			found.alreadykilledthis = true
			
			/*
			local bam1 = SpawnBam(ref)
			bam1.renderflags = $|RF_FLOORSPRITE
			S_StartSound(found,sfx_smack)
			*/
			P_KillMobj(found,me,me)
			didit = true
		elseif Soap_CanDamageEnemy(p, found,MF_ENEMY|MF_BOSS|MF_MONITOR|MF_SHOOTABLE)
			/*
			if not (found.flags & MF_BOSS)
				found.alreadykilledthis = true
			end
			
			local bam1 = SpawnBam(ref)
			bam1.renderflags = $|RF_FLOORSPRITE
			SpawnEnemyGibs(thok,found)
			SpawnRagThing(found,me,me)
			*/
			
			Soap_ImpactVFX(found, me, nil,nil, true)
			Soap_SpawnBumpSparks(found, me, nil,false, found.scale * 3/2, true)
			Soap_DamageSfx(found, abs(me.momz), 30*me.scale, {ultimate = true})
			local damage = 1
			if abs(takis.last.momz) >= 60*me.scale
				damage = 2
				S_StartSound(me,sfx_sp_db4)
			end
			
			P_DamageMobj(found,me,me, damage)
			enemyhit = true
			didit = true
		--Most likely a spike thing
		elseif (found.info.mass == DMG_SPIKE)
		and (found.takis_flingme ~= false)
			found.alreadykilledthis = true
			
			-- probably a cactus in acz
			if found.flags & MF_SCENERY
			and not (found.type == MT_SPIKE or found.type == MT_WALLSPIKE)
				local speed = 15*found.scale
				local range = 15*FU
				for i = 0,P_RandomRange(15,20)
					local poof = P_SpawnMobjFromMobj(found,
						Soap_RandomFixedRange(-range, range),
						Soap_RandomFixedRange(-range, range),
						FixedDiv(found.height,found.scale)/2 + Soap_RandomFixedRange(-range, range),
						MT_SOAP_DUST
					)
					local hang,vang = R_PointTo3DAngles(
						poof.x,poof.y,poof.z,
						found.x,found.y,found.z + found.height/2
					)
					P_3DThrust(poof, hang,vang, speed)
					
					poof.spritexscale = $ + Soap_RandomFixedRange(0,2*FU)/3
					poof.spriteyscale = poof.spritexscale
				end
				
				P_SpawnMobjFromMobj(found,0,0,0,MT_THOK).state = S_XPLD1
				local sfx = P_SpawnGhostMobj(found)
				sfx.flags2 = $|MF2_DONTDRAW
				sfx.fuse = TR
				sfx.tics = TR
				S_StartSound(sfx, sfx_pop)
			end
			P_KillMobj(found,me,me)
		elseif (found.flags & MF_SPRING)
		and (found.info.painchance ~= 3)
			local topheight = found.z + found.height
			if takis.gravflip == -1
				topheight = found.z
			end
			if (topheight > (takis.gravflip == 1 and me.floorz or me.ceilingz))
				Soap_ImpactVFX(found, me, nil,nil, true)
				P_DoSpring(found,me)
			end
		/*
		elseif (found.player and found.player.valid)
			if CanPlayerHurtPlayer(p,found.player)
				local bam1 = SpawnBam(ref)
				bam1.renderflags = $|RF_FLOORSPRITE
				SpawnEnemyGibs(thok,found)
				S_StartSound(found,sfx_smack)
				S_StartSound(me,sfx_sdmkil)
				if not nerfed
					P_KillMobj(found,me,me,DMG_CRUSHED)
				else
					P_DamageMobj(found,me,me,2)
				end
				TakisAddHurtMsg(found.player,p,HURTMSG_HAMMERBOX)
				if not found.health
					found.alreadykilledthis = true
				end
				didit = true
			elseif peptoboxed(found)
				didit = true
			end
		elseif not liteBuild
		and (found.type == MT_HHTRIGGER)
			local bam1 = SpawnBam(ref)
			bam1.renderflags = $|RF_FLOORSPRITE
			local tl = tonumber(mapheaderinfo[gamemap].takis_hh_timelimit or 3*60)*TR
			if mapheaderinfo[gamemap].takis_hh_timelimit ~= nil
			and string.lower(tostring(mapheaderinfo[gamemap].takis_hh_timelimit)) == "none"
				tl = 0
			end
			HH_Trigger(found,p,tl)
			
			S_StartSound(found,found.info.deathsound)
			found.state = found.info.deathstate
			
			found.spritexscaleadd = 2*FU
			found.spriteyscaleadd = -FU*3/2
			didit = true
		*/
		end
	end, 
	thok,
	thok.x-fakerange, thok.x+fakerange,
	thok.y-fakerange, thok.y+fakerange)		

	if (me.momz*takis.gravflip) <= -60*me.scale
		didit = false
	end
	
	if didit
		forcehambounce(p)
	end
	if enemyhit
		Soap_Hitlag.addHitlag(me, 2, false)
	end
	return didit
end)

rawset(_G,"Takis_DoHammerBlastLand",function(p,domoves)
	local me = p.realmo
	local takis = p.soaptable
	local hammer = takis.hammer
	
	local battle_tumble = false
	local br = 64*me.scale
	if abs(takis.last.momz) >= 20*me.scale
		br = $ + (abs(takis.last.momz)-20*me.scale) * 3/4
	end
	
	Soap_SquashMacro(p, {ease_func = "insine", ease_time = TR/3, strength = FU*3/4})
	Soap_DustRing(me,
		dust_type(me),
		16 + max(
			abs(FixedDiv(takis.last.momz, me.scale) - 5*FU)/FU / 4,
			0
		),
		{me.x,me.y,me.z},
		me.radius * 3/2,
		br/3, --soap.last.momz,
		me.scale / 2,
		me.scale * 3/2,
		false, dust_noviewmobj
	)
	do
		local px = me.x
		local py = me.y
		searchBlockmap("objects", function(me,fnd)
			battle_tumble = Soap_JostleThings(me,fnd,
				br + me.radius * 3
			)
			if not (fnd.player and fnd.player.valid)
				battle_tumble = false
			end
			
		end, me, px-br, px+br, py-br, py+br)
		/*
		P_SpawnMobj(px-br, py-br, me.z, MT_PINETREE).fuse = 6*TR
		P_SpawnMobj(px-br, py+br, me.z, MT_PINETREE).fuse = 6*TR
		P_SpawnMobj(px+br, py-br, me.z, MT_PINETREE).fuse = 6*TR
		P_SpawnMobj(px+br, py+br, me.z, MT_PINETREE).fuse = 6*TR
		*/
	end
	
	if abs(takis.last.momz) >= 60*me.scale
		S_StartSound(me, sfx_s3k9b)
		S_StartSoundAtVolume(me, sfx_s3k5f, 255/2)
		S_StartSound(me, sfx_pstop)
		
		local iterations = 16
		local ang = FixedDiv(360*FU, iterations*FU)
		local limit = 28
		for i = 0, iterations
			local rock = P_SpawnMobjFromMobj(me,
				0,0, 4*FU,
				MT_LAVAFALLROCK
			)
			rock.flags = $|MF_NOCLIPTHING &~(MF_PAIN|MF_SPECIAL)
			rock.state = S_ROCKCRUMBLEA+P_RandomRange(0, 3)
			P_SetObjectMomZ(rock, Soap_RandomFixedRange(10*FU,20*FU))
			P_Thrust(rock, FixedAngle(ang * i), Soap_RandomFixedRange(3*FU,7*FU))
			rock.fuse = TR*3
		end
		Soap_DustRing(me,
			MT_SOAP_WALLBUMP,
			16 + max(
				abs(FixedDiv(takis.last.momz, me.scale) - 5*FU)/FU / 4,
				0
			),
			{me.x,me.y,me.z},
			me.radius * 3/2,
			br/3, --soap.last.momz,
			me.scale / 10,
			me.scale * 3/2,
			false, function(spark)
				--5 tics
				spark.scalespeed = FixedDiv(spark.destscale - (spark.scale / 10), 5*FU)
				
				spark.fuse = 5 * TR
				spark.startfuse = spark.fuse
				
				spark.random = P_RandomRange(-limit,limit) * ANG1
				spark.momz = Soap_RandomFixedRange(15*me.scale, 30*me.scale) * takis.gravflip
				dust_noviewmobj(spark)
			end
		)
	end
	
	S_StartSoundAtVolume(me, sfx_pstop,2*255/5)
	S_StartSound(me,sfx_tk_hml)
	
	local quake_tics = 16 + (FixedDiv(br,me.scale)/FU / 25)
	Soap_StartQuake(20*FU + br/40, quake_tics,
		{me.x,me.y,me.z},
		512*me.scale
	)
	P_MovePlayer(p)
	if Soap_BreakFloors(p,me)
		forcehambounce(p)
		return
	end
	
	if domoves
		--holding jump while landing? boost us up!
		if takis.jump > 0
		and me.health
		and not (takis.inPain)
		and not (takis.noability & NOABIL_THOK)
			local time = min(hammer.down,TR*25/10)
			if p.powers[pw_shield] == SH_WHIRLWIND
				time = $*3/2
			end
			local basemomz = 13*FU
			if p.powers[pw_shield] == SH_BUBBLEWRAP
			or p.powers[pw_shield] == SH_ELEMENTAL
				basemomz = 18*FU
			end
			
			hammer.jumped = 1
			
			P_DoJump(p,false)
			me.state = S_PLAY_SPINDASH
			Soap_ZLaunch(me, basemomz + (time*FU/8) )
			
			S_StartSoundAtVolume(me,sfx_kc52,180)
			--p.jp = 1
			--p.jt = 5
			
			p.pflags = $|PF_JUMPED &~(PF_THOKKED|PF_SHIELDABILITY)
			
			takis.noability = $|NOABIL_SLIDE
		--holding spin while landing? boost us forward!
		elseif (takis.use > 0)
		and me.health
		and not (takis.noability & NOABIL_CLUTCH)
			Takis_DoClutch(p)
		end
	end
	hammer.down = 0
end)

--table of helper funcs?
rawset(_G,"Takis_AbilityHelpers",{
	hammerthinker = function(p)
		local me = p.realmo
		local takis = p.soaptable
		local hammer = takis.hammer
		
		if (me.flags & MF_NOTHINK)
			Takis_ResetHammerTime(p)
			takis.accspeed = 0
			me.momx,me.momy,me.momz = 0,0,0
			return
		end
		
		p.charflags = $ &~SF_RUNONWATER
		p.powers[pw_strong] = $|(STR_SPRING|STR_HEAVY|STR_SPIKE)
		takis.noability = $|NOABIL_HAMMER
		--control better
		takis.setrolltrol = true
		p.thrustfactor = skins[TAKIS_SKIN].thrustfactor*3/2
		p.drawangle = me.angle
		
		if (p.pflags & PF_SHIELDABILITY)
			p.pflags = $ &~PF_SHIELDABILITY
		end
		
		--right side up lol
		me.pitch = FixedMul($,FU*3/4)
		me.roll = FixedMul($,FU*3/4)
		
		if me.state ~= S_PLAY_MELEE
			me.state = S_PLAY_MELEE
		end
		
		hammer.jumped = 0
		if hammer.down == 1
			Soap_ZLaunch(me,12*FU)
			hammer.wentdown = false
		end
		
		takis.dived = true
		if takis.in2D
			p.drawangle = hammer.angle
		end
		me.momz = $+P_GetMobjGravity(me)
		
		local dontdostuff = false
		
		--the main stuff
		local fallingspeed = (8*me.scale)
		if (takis.inWater) then fallingspeed = $*3/4 end
		
		if me.momz*takis.gravflip <= fallingspeed
		or hammer.wentdown == true
			
			if (me.momz*takis.gravflip >= me.scale)
				hammer.up = $+1
			end
			if hammer.up >= TR
				Takis_ResetHammerTime(p)
				me.state = S_PLAY_FALL
				return
			end
			
			--me.momz = $*15/8
			me.momz = $-((me.scale*11/10)*takis.gravflip)
			if p.powers[pw_shield] & SH_FORCE
				me.momz = $+P_GetMobjGravity(me)
			end
			
			hammer.wentdown = true
			
			if not S_SoundPlaying(me,sfx_tk_hmd)
				S_StartSoundAtVolume(me,sfx_tk_hmd,255*8/10)
			end
			
			/*
			if hammer.down
			and (hammer.down % 5 == 0)
			and (me.momz*takis.gravflip <= 16*me.scale)
				P_SpawnGhostMobj(me)
			end
			*/
			dontdostuff = Takis_HammerBlastHitbox(p)
		end
		
		local superspeed = -60*me.scale
		if (me.momz*takis.gravflip <= superspeed + 5*me.scale)
		and not (takis.last.momz*takis.gravflip <= superspeed + 5*me.scale)
			S_StartSound(me,sfx_tk_fst)
		end
		
		hammer.down = $+1
		
		local domoves = true
		--cancel conds.
		if not (takis.notCarried)
			hammer.down = 0
			domoves = false
		elseif (me.eflags & MFE_SPRUNG
		or takis.fakesprung)
			hammer.down = 0
			me.state = S_PLAY_SPRING
			Soap_ResetState(p)
			
			p.pflags = $ &~(PF_JUMPED|PF_THOKKED)
			takis.dived = false
			domoves = false
		elseif not me.health
		or (takis.inPain)
		or not (takis.notCarried)
			hammer.down = 0
			domoves = false
		elseif dontdostuff
			hammer.down = 0
			domoves = false				
		end
		if not domoves
			Takis_ResetHammerTime(p)
			return
		end
		
		--hit ground
		if (takis.onGround or P_CheckDeathPitCollide(me))
		or (Soap_BouncyCheck(p))
			Takis_DoHammerBlastLand(p,domoves)
		end

	end,
})

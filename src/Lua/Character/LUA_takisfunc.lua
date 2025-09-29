local CV = SOAP_CV

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
			takis.frictionfreeze = 10
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
	
	local thrust = 4*FU + FixedMul( (2*FU), (ccombo*FU)/2 )
	
	--not too fast, now
	if thrust >= 13*FU
		thrust = 13*FU
	end
	
	local clutchadjust = clutch.tics --max((takis.clutchtime - p.cmd.latency),0)
	local spammed = false
	local combod = false
	
	--clutch boost
	if (clutchadjust > 0)
		if (clutchadjust <= 11)
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
			if not (G_RingSlingerGametype())
				P_ElementalFire(p)
				clutch.firefx = 2
			end
			
			ghost.momx,ghost.momy = me.momx,me.momy
			ghost.momz = takis.rmomz
			
			thrust = $+(3*FU/2)+FU
		--dont thrust too early, now!
		elseif clutchadjust > 16
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
	
	if (takis.accspeed > ((p.powers[pw_sneakers] or takis.isSuper) and 70*FU or 50*FU))
		takis.frictionfreeze = 10
		me.friction = FU + FU/10
		thrust = FU
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
				if takis.accspeed >= 90*mo.scale
					mo.momx = $*8/10
					mo.momy = $*8/10
					thrust = 0
				else
					thrust = $/2
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
	
	/*
	if not combod
		p.jp = 2
		p.jt = -5
	else
		p.jp = 3
		p.jt = -8
	end
	*/
	
	if takis.onGround
		me.state = S_PLAY_DASH
		P_MovePlayer(p)
		p.panim = PA_DASH
	end
	clutch.tics = 23
	clutch.spamtime = 23
	clutch.misfire = TR
	takis.bashspin = 9
	--takis.ropeletgo = TR/5
	
	/*
	if takis.clutchspamcount == 5
		TakisAwardAchievement(p,ACHIEVEMENT_CLUTCHSPAM)
	end
	*/
	
	--takis.coyote = 0
	takis.noability = $ &~NOABIL_AFTERIMAGE
	
	--save on effects?
	if spammed then return end
	
	/*
	--xmom code
	local d1,d2
	if takis.notCarried
	and combod
		d1 = P_SpawnMobjFromMobj(me, -20*cos(ang + ANGLE_45), -20*sin(ang + ANGLE_45), 0, MT_TAKIS_CLUTCHDUST)
		d2 = P_SpawnMobjFromMobj(me, -20*cos(ang - ANGLE_45), -20*sin(ang - ANGLE_45), 0, MT_TAKIS_CLUTCHDUST)
		d1.angle = R_PointToAngle2(me.x, me.y, d1.x, d1.y) --- ANG5
		d2.angle = R_PointToAngle2(me.x, me.y, d2.x, d2.y) --+ ANG5
		
		if combod
			d1.momx,d1.momy = mo.momx/2,mo.momy/2
			d2.momx,d2.momy = mo.momx/2,mo.momy/2
			d1.momz = takis.rmomz
			d2.momz = takis.rmomz
		end
		
		d1.state = S_TAKIS_CLUTCHDUST2
		d2.state = S_TAKIS_CLUTCHDUST2
	end
	
	for j = -1,1,2
		for i = 0,TAKIS_NET.noeffects and 2 or P_RandomRange(2,4)
			if not combod
				TakisKart_SpawnSpark(me,
					ang+FixedAngle(45*FU*j+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))),
					SKINCOLOR_ORANGE,
					true,
					true
				)
			end
			
			local dust = TakisSpawnDust(me,
				ang+FixedAngle(45*FU*j+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))),
				P_RandomRange(0,-50),
				P_RandomRange(-1,2)*me.scale,
				{
					--xspread = 0,--(P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
					--yspread = 0,--(P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
					zspread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
					
					thrust = P_RandomRange(0,-10)*me.scale,
					thrustspread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
					
					momz = (P_RandomRange(4,0)*i)*(me.scale/2),
					momzspread = ((P_RandomChance(FU/2)) and 1 or -1),
					
					scale = me.scale,
					scalespread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
					
					fuse = 15+P_RandomRange(-5,5),
				}
			)
		end
	end
	*/
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
	me.state = S_PLAY_ROLL
	
	local momz = 15*FU
	if takis.jump > 0
	and me.health
	and not (takis.inPain)
	and not (takis.noability & NOABIL_THOK)
		momz = 19*FU
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
	
	local dispx = FixedMul(42*me.scale+(20*me.scale),cos(p.drawangle))
	local dispy = FixedMul(42*me.scale+(20*me.scale),sin(p.drawangle))
	local thok = P_SpawnMobjFromMobj(
		me,
		dispx+me.momx,
		dispy+me.momy,
		--theres some discrepancies with these on different scales,
		--but its miniscule so whatever yknow
		(-FixedMul(TAKIS_HAMMERDISP,me.scale)*takis.gravflip)+me.momz
		+(takis.gravflip == -1 and -me.height or 0),
		MT_THOK
	)
	thok.radius = 40*me.scale
	thok.height = 60*me.scale
	thok.scale = me.scale
	thok.fuse = 2
	thok.flags2 = $|MF2_DONTDRAW
	P_SetOrigin(thok,
		me.x+dispx+me.momx,
		me.y+dispy+me.momy,
		me.z+(-FixedMul(TAKIS_HAMMERDISP,me.scale)*takis.gravflip)+me.momz
		+(takis.gravflip == -1 and -me.height+thok.height or 0)
	)
	
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
			if not (found.flags & MF_BOSS)
				found.alreadykilledthis = true
			end
			
			/*
			local bam1 = SpawnBam(ref)
			bam1.renderflags = $|RF_FLOORSPRITE
			SpawnEnemyGibs(thok,found)
			S_StartSound(found,sfx_smack)
			S_StartSound(me,sfx_sdmkil)
			SpawnRagThing(found,me,me)
			*/
			P_KillMobj(found,me,me)
			didit = true
		--Most likely a spike thing
		elseif (found.info.mass == DMG_SPIKE)
		and (found.takis_flingme ~= false)
			found.alreadykilledthis = true
			P_KillMobj(found,me,me)
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
		elseif (found.flags & MF_SPRING)
		and (found.info.painchance ~= 3)
			if (GetActorZ(found,me,2) > (takis.gravflip == 1 and me.floorz or me.ceilingz))
				local bam1 = SpawnBam(ref)
				bam1.renderflags = $|RF_FLOORSPRITE
				P_DoSpring(found,me)
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
	return didit
end)

rawset(_G,"Takis_DoHammerBlastLand",function(p,domoves)
	local me = p.realmo
	local takis = p.soaptable
	local hammer = takis.hammer

	--dust effect
	--if not (me.eflags & MFE_TOUCHWATER)
	/*
	local maxi = 16+abs(takis.lastmomz*takis.gravflip/me.scale/5)
	for i = 0, maxi
		local radius = FU*16
		local fa = FixedAngle(i*(FixedDiv(360*FU,maxi*FU)))
		local mz = takis.lastmomz/7
		local dust = TakisSpawnDust(me,
			fa,
			0,
			P_RandomRange(-1,2)*me.scale,
			{
				xspread = 0,
				yspread = 0,
				zspread = (P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
				
				thrust = 0,
				thrustspread = 0,
				
				momz = P_RandomRange(0,1)*me.scale,
				momzspread = P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1),
				
				scale = me.scale,
				scalespread = (P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
				
				fuse = 23+P_RandomRange(-2,3),
			}
		)
		dust.momx = FixedMul(FixedMul(sin(fa),radius),mz)/2
		dust.momy = FixedMul(FixedMul(cos(fa),radius),mz)/2
		
	end
	*/
	
	/*
	if takis.inBattle
		for play in players.iterate
			if play.spectator then continue end
			if play == p then continue end
			if not CanPlayerHurtPlayer(p,play) then continue end
			
			local found = play.mo
			
			if not (found and found.valid) then continue end
			if not (found.health) then continue end
			if (play.tumble) then continue end
			
			local dist = FixedHypot(FixedHypot(found.x - me.x, found.y - me.y),found.z - me.z)
			local maxdist = abs(takis.lastmomz)*11/2
			
			if dist > maxdist then continue end
			
			local tics = abs(takis.lastmomz)/me.scale
			
			CBW_Battle.DoPlayerTumble(play,tics,
				R_PointToAngle2(found.x,found.y,
					me.x,me.y
				),
				abs(takis.lastmomz)
			)
			
		end
		p.lockmove = false
		p.melee_state = 0
	end
	*/
	
	/*
	--impact sparks
	local superspeed = -60*me.scale
	if ((takis.lastmomz*takis.gravflip) <= superspeed)
		S_StartSound(me,sfx_s3k9b)
		local radius = abs(takis.lastmomz)
		if (p.powers[pw_shield] == SH_ARMAGEDDON)
			radius = $*2
		end
		
		for i = 0, 16
			local fa = (i*ANGLE_22h)
			local spark = P_SpawnMobjFromMobj(me,0,0,0,MT_SUPERSPARK)
			spark.momx = FixedMul(sin(fa),radius)
			spark.momy = FixedMul(cos(fa),radius)
			local spark2 = P_SpawnMobjFromMobj(me,0,0,0,MT_SUPERSPARK)
			spark2.color = me.color
			spark2.momx = FixedMul(sin(fa),radius/20)
			spark2.momy = FixedMul(cos(fa),radius/20)
		end
		DoQuake(p,FU*37,20)
		
		if not (G_RingSlingerGametype() or TAKIS_NET.hammerquakes == false)
			--KILL!
			local rad = takis.lastmomz
			local px = me.x
			local py = me.y
			local br = abs(rad*10)
			
			searchBlockmap("objects", function(me, found)
				if not (found and found.valid) then return end
				if not (found.health) then return end
				if (found.takis_nocollateral == true) then return end
				if (found.alreadykilledthis) then return end
				
				local dist = FixedHypot(FixedHypot(found.x - me.x, found.y - me.y),found.z - me.z)
				if dist > br then return end
				
				if CanFlingThing(p, found,nil,true)
					if not (found.flags & MF_BOSS)
						found.alreadykilledthis = true
					end
					local rag = SpawnRagThing(found,me)
					if (rag and rag.valid)
						S_StartSound(rag,sfx_sdmkil)
					end
				elseif (found.type == MT_PLAYER)
					if CanPlayerHurtPlayer(p,found.player)
						TakisAddHurtMsg(found.player,p,HURTMSG_HAMMERQUAKE)
						P_DamageMobj(found,me,me,abs(me.momz/FU/4))
					end
					DoQuake(found.player,
						FixedMul(
							75*FU, FixedDiv( br-FixedHypot(found.x-me.x,found.y-me.y),br )
						),
						15
					)
				elseif (SPIKE_LIST[found.type] == true)
				and (found.takis_nocollateral ~= true)
					found.alreadykilledthis = true
					P_KillMobj(found,me,me)
				end
			end, me, px-br, px+br, py-br, py+br)		
		end
	end
	*/
	
	S_StartSoundAtVolume(me, sfx_pstop,4*255/5)
	--S_StartSound(me,sfx_takmcn)
	
	Soap_StartQuake(25*FU, 17, me, 512*FU)
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
			local basemomz = 20*FU
			if p.powers[pw_shield] == SH_BUBBLEWRAP
			or p.powers[pw_shield] == SH_ELEMENTAL
				basemomz = 25*FU
			end
			
			hammer.jumped = 1
			
			P_DoJump(p,false)
			me.state = S_PLAY_SPINDASH
			Soap_ZLaunch(me,basemomz+(time*FU/8)*takis.gravflip)
			
			S_StartSoundAtVolume(me,sfx_kc52,180)
			--p.jp = 1
			--p.jt = 5
			
			p.pflags = $|PF_JUMPED &~PF_THOKKED
			
			takis.noability = $|NOABIL_SLIDE
			
		--holding spin while landing? boost us forward!
		--[[
		elseif (takis.use > 0)
		and me.health
		and not (takis.noability & NOABIL_CLUTCH)
			local spammed = false
			if not takis.dropdashstale
				S_StartSoundAtVolume(me,sfx_cltch2,255*3/5)
				S_StartSoundAtVolume(me,sfx_cltch3,133)
				if not takis.inWater
					S_StartSoundAtVolume(me,sfx_cltch4,179)
				else
					S_StartSoundAtVolume(me,sfx_cltch5,220)
				end
				takis.clutchtime = 23
				takis.clutchspamtime = 23
				takis.clutchmisfire = TR
				
				if takis.clutchcombotime
					takis.clutchcombotime = 2*TR
				end
			else
				--dont even bother doing the rest
				if takis.dropdashstale > 2 then takis.hammerblastdown = 0; return end
				
				S_StartSound(me,sfx_didbad)
				spammed = true
			end
			
			me.state = S_PLAY_DASH
			
			takis.clutchingtime = 1
			takis.glowyeffects = takis.hammerblastdown/3
			
			local ang = GetControlAngle(p)
			
			if ((me.flags2 & MF2_TWOD)
			or (twodlevel))
				if (p.cmd.sidemove > 0)
					ang = p.drawangle
				elseif (p.cmd.sidemove < 0)
					ang = InvAngle(p.drawangle)
				end
			end
			
			local boostpower = FixedDiv(
				FixedMul(
					15*FU + FixedDiv(me.momz, me.scale)*3/4,
					p.powers[pw_sneakers] and FU*7/5 or FU
				),
				max(FU,takis.dropdashstale*3/2*me.scale)
			)
			if spammed then boostpower = (-5*FU - $) end
			--print(string.format("%f,	%f", boostpower, takis.accspeed))
			
			if takis.accspeed+boostpower <= 80*FU
				P_InstaThrust(me,ang,
					FixedMul(takis.accspeed + boostpower,me.scale)
				)
			--okay, so the boost is too strong but we're not even as fast
			elseif takis.accspeed <= 80*FU
				P_InstaThrust(me, ang,
					FixedMul(80*FU - takis.accspeed,me.scale)
				)
			elseif not spammed
				takis.frictionfreeze = 15
				me.friction = FU
			end
			P_MovePlayer(p)
			
			takis.bashspin = max($,TR/2)
			
			--effect
			local ghost = P_SpawnGhostMobj(me)
			ghost.scale = 3*me.scale/2
			ghost.destscale = FixedMul(me.scale,2)
			ghost.colorized = true
			ghost.frame = $|TR_TRANS10
			ghost.blendmode = AST_ADD
			ghost.angle = p.drawangle
			ghost.state = S_PLAY_TAKIS_TORNADO
			ghost.momx,ghost.momy = me.momx*3/4,me.momy*3/4
			for j = -1,1,2
				for i = 3,P_RandomRange(4,7)
					TakisKart_SpawnSpark(me,
						ang+FixedAngle(45*FU*j+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))),
						SKINCOLOR_ORANGE,
						true,
						true
					)
					TakisSpawnDust(me,
						ang+FixedAngle(45*FU*j+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))),
						P_RandomRange(0,-50),
						P_RandomRange(-1,2)*me.scale,
						{
							xspread = 0,--(P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
							yspread = 0,--(P_RandomFixed()/2*((P_RandomChance(FU/2)) and 1 or -1)),
							zspread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
							
							thrust = P_RandomRange(0,-10)*me.scale,
							thrustspread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
							
							momz = (P_RandomRange(4,0)*i)*(me.scale/2),
							momzspread = ((P_RandomChance(FU/2)) and 1 or -1),
							
							scale = me.scale,
							scalespread = (P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1)),
							
							fuse = 15+P_RandomRange(-5,5),
						}
					)
				end
			end
			
			do
				local d1 = P_SpawnMobjFromMobj(me, -20*cos(ang + ANGLE_45), -20*sin(ang + ANGLE_45), 0, MT_TAKIS_CLUTCHDUST)
				local d2 = P_SpawnMobjFromMobj(me, -20*cos(ang - ANGLE_45), -20*sin(ang - ANGLE_45), 0, MT_TAKIS_CLUTCHDUST)
				d1.angle = R_PointToAngle2(me.x+me.momx, me.y+me.momy, d1.x, d1.y) --- ANG5
				d2.angle = R_PointToAngle2(me.x+me.momx, me.y+me.momy, d2.x, d2.y) --+ ANG5
				
				d1.momx,d1.momy = me.momx/2,me.momy/2
				d2.momx,d2.momy = me.momx/2,me.momy/2
				d1.momz = takis.rmomz
				d2.momz = takis.rmomz
			end
			
			takis.dropdashstale = $+1
			takis.dropdashstaletime = 3*TR
		]]
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
		takis.noability = $|NOABIL_SHOTGUN|NOABIL_HAMMER
		--control better
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
			
			/*
			if not S_SoundPlaying(me,sfx_takhmb)
				S_StartSoundAtVolume(me,sfx_takhmb,255*9/10)
			end
			*/
			
			if hammer.down
			and (hammer.down % 5 == 0)
			and (me.momz*takis.gravflip <= 16*me.scale)
				P_SpawnGhostMobj(me)
			end
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
		
		/*
		if not (takis.shotgunned)
			takis.dontlanddust = true
		end
		*/
		
		--hit ground
		if (takis.onGround or P_CheckDeathPitCollide(me))
		or (Soap_BouncyCheck(me,me.subsector.sector))
			Takis_DoHammerBlastLand(p,domoves)
		end

	end,
})

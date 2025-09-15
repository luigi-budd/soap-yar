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
			--ghost.state = S_PLAY_TAKIS_TORNADO
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
	local strength = (FU/3)
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
	--takis.bashspin = 9
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
	local hook_event = Takis_Hook.events["Char_NoAbility"]
	for i,v in ipairs(hook_event)
		local new_noabil = Takis_Hook.tryRunHook("Char_NoAbility", v, p, na)
		if new_noabil ~= nil
		and type(new_noabil) == "number"
			na = abs(new_noabil)
		end
	end
	
	soap.noability = $|na
end)

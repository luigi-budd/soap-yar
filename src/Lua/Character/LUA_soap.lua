--most of this code (as well as other code in other files) is just
--recycled takis code. working on an addon for ~2-3 years really helps
--when making another lol

/*
	--TODO LIST
	---------------------
	-wolffang winds spawn a separate mobj
	-death anims
	-replace P_MovePlayer with TakisResetState
	
	SPR2_MSC* list
	- MSC0: pound ball
	- MSC1: spinning top
	- MSC2: battlemod knockout
	- MSC3: death pit shoes
*/

--max speed increase
rawset(_G,"SOAP_MAXDASH", 21*FU)
--speed increase ramp-up time
rawset(_G,"SOAP_DASHTIME", TR/2)
--max extra speed charge
rawset(_G,"SOAP_EXTRADASH", 21*FU)
--spinning top
rawset(_G,"SOAP_TOPCOOLDOWN", 4*TR)
rawset(_G,"SOAP_MAXDAMAGETICS", 10)

local soap_baseuppercutturn = (360 + 180)*FU
local soap_pound_factor = tofixed("0.75")
local CV = SOAP_CV

local soap_crouchanimtime = 13
local max_mentums = (FU - ORIG_FRICTION) * 95 / 100
local soap_lowfriction = tofixed("0.97")

local soap_rdashwind_base = SKINCOLOR_SAPPHIRE
local soap_rdashwind_dest = SKINCOLOR_YELLOW
local soap_rdashwind_inc = (soap_rdashwind_dest - soap_rdashwind_base)

local sfx_armacharge = sfx_s3k84
local sfx_armacharge2 = sfx_s3ka3
local function armasound(me, stop)
	local soundfunc = (stop) and S_StopSoundByID or S_StartSoundAtVolume
	soundfunc(me, sfx_armacharge, 255/2)
	soundfunc(me, sfx_armacharge2, 255)
	me.player.soaptable.poundarma = not stop
end
local armacolors = {
	SKINCOLOR_KETCHUP, SKINCOLOR_PEPPER, SKINCOLOR_CRIMSON, SKINCOLOR_GARNET, SKINCOLOR_VOLCANIC
}

local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SPINDUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end

local function P_PitchRoll(me, frac)
	me.eflags = $|MFE_NOPITCHROLLEASING
	local angle = R_PointToAngle2(0,0, me.momx,me.momy)
	local mang = R_PointToAngle2(0,0, FixedHypot(me.momx, me.momy), me.momz)
	mang = InvAngle($)
	
	local destpitch = FixedMul(mang, cos(angle))
	local destroll = FixedMul(mang, sin(angle))
	me.pitch = P_AngleLerp(frac, $, destpitch)
	me.roll  = P_AngleLerp(frac, $, destroll)
end

local function Soap_SuperReady(player)
	if (not player.powers[pw_super]
	and not player.powers[pw_invulnerability]
	and not player.powers[pw_tailsfly]
	and (player.charflags & SF_SUPER)
	and (player.pflags & PF_JUMPED)
	-- and !(player->powers[pw_shield] & SH_NOSTACK) (lol)
	and not (maptol & TOL_NIGHTS)
	and All7Emeralds(emeralds)
	and (player.rings >= 50))
	and (player.powers[pw_carry] == CR_NONE)
		return true
	end
	
	return false
end

local function soap_poundonland(p,me,soap)
	local poundtime = soap.poundtime
	soap.pounding = false
	soap.poundtime = 0
	armasound(me,true)
	S_StopSoundByID(me,sfx_tk_fst)
	
	--diou9rs8749843
	if P_CheckDeathPitCollide(me) then return end
	
	if not (me.eflags & MFE_SPRUNG)
		local battle_tumble = false
		local br = 64*me.scale
		if abs(soap.last.momz) >= 20*me.scale
			br = $ + abs(soap.last.momz)-20*me.scale / 2
		end
		
		/*
		print("pound",
			string.format("%f\n%f\n%f\n%f\n%f",
				br,
				br - 64*me.scale,
				max(abs(soap.last.momz) / 3, 0),
				abs(soap.last.momz),
				abs(soap.last.momz) / 3
			)
		)
		*/
		local hook_event,hook_name = Takis_Hook.findEvent("Char_OnMove")
		if hook_event
			for i,v in ipairs(hook_event)
				local newrad = Takis_Hook.tryRunHook(hook_name, v, p, "poundland",
					br
				)
				if newrad ~= nil
				and (tonumber(newrad) ~= nil)
					br = abs(newrad)
				end
			end
		end
		
		if br >= 140*me.scale
			S_StartSound(me, sfx_s3k9b)
			S_StartSound(me, sfx_s3k5f)
			
			local iterations = 16
			local ang = FixedDiv(360*FU, iterations*FU)
			for i = 0, iterations
				local rock = P_SpawnMobjFromMobj(me,
					0,0, 4*FU,
					MT_LAVAFALLROCK
				)
				rock.flags = $|MF_NOCLIPTHING &~(MF_PAIN|MF_SPECIAL)
				rock.state = S_ROCKCRUMBLEA+P_RandomRange(0, 3)
				P_SetObjectMomZ(rock, Soap_RandomFixedRange(10,20))
				P_Thrust(rock, FixedAngle(ang * i), Soap_RandomFixedRange(3,7))
				rock.fuse = TR*3
			end
		end
		
		/*
		if me.health
		and not soap.inPain
			Soap_ZLaunch(me,4*FU)
		end
		*/
		local quake_tics = 16 + (FixedDiv(br,me.scale)/FU / 25)
		Soap_StartQuake(20*FU + br/40, quake_tics,
			{me.x,me.y,me.z},
			512*me.scale
		)
		Soap_DirBreak(p,me, R_PointToAngle2(0,0,me.momx,me.momy), true)
		S_StartSound(me,sfx_pstop)
		
		if me.health
			P_MovePlayer(p)
			
			if P_IsObjectInGoop(me)
				me.state = S_PLAY_ROLL
				P_SetObjectMomZ(me, 9*FU)
				S_StartSoundAtVolume(me,sfx_kc52,180)
				p.pflags = $ &~PF_THOKKED
			elseif Soap_BouncyCheck(p) 
				me.state = S_PLAY_ROLL
			end
		else
			if not (me.state == S_PLAY_DEAD
			or me.state == S_PLAY_DRWN
			or me.state == S_PLAY_PAIN)
				me.state = S_PLAY_PAIN
			end
		end
		
		Soap_SquashMacro(p, {ease_func = "insine", ease_time = TR/3, strength = FU*3/4})
		Soap_DustRing(me,
			dust_type(me),
			16 + max(
				abs(FixedDiv(soap.last.momz, me.scale) - 5*FU)/FU / 4,
				0
			),
			{me.x,me.y,me.z},
			me.radius * 3/2,
			br/2, --soap.last.momz,
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
		
		local shield = (p.powers[pw_shield] & SH_NOSTACK)
		if shield == SH_ELEMENTAL
			if me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)
				S_StartSound(me,sfx_s3k4c)
			else
				P_ElementalFire(p,true)
				S_StartSound(me,sfx_s3k47)
			end
		end
		
		--You need to be holding jump to activate the shield abilities
		if (soap.jump)
			if shield == SH_BUBBLEWRAP
			--dont bother if endlag's gonna kill our speed
			and not Soap_IsCompGamemode()
				P_DoBubbleBounce(p)
				p.pflags = $|PF_JUMPED &~PF_THOKKED
				soap.nofreefall = true
				soap.ranoff = false
				
				P_SetObjectMomZ(me, 12*FU)
				local speed = max(soap.accspeed, 20*FU)
				if (speed < 65*FU)
					speed = $ + 12*FU
				end
				P_InstaThrust(me, me.angle,
					FixedMul(speed, me.scale)
				)
				me.state = S_PLAY_ROLL
				p.drawangle = me.angle
			elseif shield == SH_ARMAGEDDON
			and not soap.inBattle
			and (poundtime >= 10)
				P_BlackOw(p)
			end
		end
		
		if Soap_IsCompGamemode()
			P_SetObjectMomZ(me, 4*FU)
			me.state = S_PLAY_FALL
			
			--hitting a tumble gives more forgiving endlag
			if (soap.inBattle)
				soap.bm.lockmove = (battle_tumble) and TR/2 or TR*3/4
			end
			p.pflags = $|PF_JUMPED|PF_THOKKED|PF_NOJUMPDAMAGE
			
			local ang = R_PointToAngle2(0,0,me.momx,me.momy)
			local speed = min(soap.accspeed,
				(battle_tumble) and 8*FU or 5*FU
			)
			me.momx = P_ReturnThrustX(nil,ang, speed)
			me.momy = P_ReturnThrustY(nil,ang, speed)
		else
			soap.canuppercut = true
			soap.uppercutted = false
		end
	end
end

local function do_poundsquash(p,me,soap)
	if not soap.pounding then return end
	local momz = me.momz*soap.gravflip
	
	if me.health
		if me.state ~= S_PLAY_MELEE
		and momz <= 14*me.scale
			me.state = S_PLAY_MELEE
			me.frame = $ &~FF_FRAMEMASK -- A
			me.sprite2 = SPR2_MSC0
			/*
			me.tics = -1
			me.frame = A
			*/
		elseif me.state ~= S_PLAY_ROLL
		and momz > 14*me.scale
			me.state = S_PLAY_ROLL
		end
	end
	
	local squash = me.scale * 3
	local max_squash = FU*4/5
	
	if (momz > 0)
	or (momz <= squash)
		local mom = FixedDiv(-me.momz,me.scale) * soap.gravflip -- FixedDiv(squash, me.scale)
		mom = $/50
		mom = -min($, max_squash)
		if momz < 0
			mom = ease.outsine(
				FixedDiv(mom, -max_squash),
				$, -max_squash
			)
		else
			mom = $ * 2
			mom = min($, max_squash)
		end
		
		soap.spritexscale = $ + mom
		soap.spriteyscale = $ - (mom*9/10)
	end
end

local tcs_numangles = 6
local tcs_limitangle = (360 / tcs_numangles)
local function spawn_thundercoin_sparks(p,me)
	local travelangle = me.angle + (P_RandomRange(-tcs_limitangle, tcs_limitangle) * ANG1)
	for i = 0, tcs_numangles
		local spark = P_SpawnMobjFromMobj(me, 0,0,0, MT_THUNDERCOIN_SPARK)
		if not (spark and spark.valid) then continue end
		P_InstaThrust(spark,
			travelangle + FixedAngle(
				FixedDiv(360*FU, tcs_numangles*FU) * i
			),
			4 * spark.scale
		)
		if (i % 2)
			P_SetObjectMomZ(spark, -4*FU)
		end
		spark.fuse = 18
	end
end

local function destroy_uppercut_aura(p,me,soap)
	local aura = soap.fx.uppercut_aura
	
	aura.alpha = FixedFloor(ease.linear(FU/3, $, 0) * 100)/100
	aura.dispoffset = me.dispoffset + 3
	
	if aura.alpha == 0
		P_RemoveMobj(soap.fx.uppercut_aura)
		soap.fx.uppercut_aura = nil
	end
end

local function spawn_sweat_mobjs(p,me,soap)
	local height = FixedDiv(me.height,me.scale)/FU
	local sweat = P_SpawnMobjFromMobj(me,
		P_RandomRange(-16,16)*FU, --+ FixedDiv(me.momx,me.scale),
		P_RandomRange(-16,16)*FU, --+ FixedDiv(me.momy,me.scale),
		P_RandomRange(height/2,height)*FU,
		MT_SOAP_WALLBUMP
	)
	P_Thrust(sweat, 
		R_PointToAngle2(0,0,me.momx,me.momy) + FixedAngle(Soap_RandomFixedRange(-45,45)),
		-Soap_RandomFixedRange(2,5)
	)
	sweat.momx = $ + me.momx/2
	sweat.momy = $ + me.momy/2
	sweat.momz = $ + soap.rmomz
	P_SetObjectMomZ(sweat, Soap_RandomFixedRange(5,8))
	sweat.fuse = TR*3/4
	sweat.dontdrawforviewmobj = me
	sweat.frame = B|FF_TRANS30
	sweat.colorized = false
	sweat.sweat = true
	return sweat
end

local function accelerative_speedlines(p,me,soap, speed, threshold, color)
	local rmomz = soap.rmomz
	if speed > (threshold*2)
		for i = 1,10
			if speed > (threshold*2)*i
				Soap_WindLines(me,rmomz,color)
				for j = 1,i
					Soap_WindLines(me,rmomz,color)
				end
			else
				break
			end
		end
	end
	
	local fang
	/*
	if (soap.pounding)
		fang = FixedAngle(Soap_RandomFixedRange(0,360))
	end
	*/
	
	if speed >= 8*threshold/5
		Soap_WindLines(me,rmomz,color,fang)
		
	elseif speed >= 7*threshold/5
	and not (leveltime % 2)
		Soap_WindLines(me,rmomz,color,fang)
		
	elseif speed >= 6*threshold/5
	and not (leveltime % 5)
		Soap_WindLines(me,rmomz,color,fang)
		
	elseif speed >= threshold
	and not (leveltime % 7)
		Soap_WindLines(me,rmomz,color,fang)
	end
end

local discoranges = {
	["DISCO1"] = true,
	["DISCO2"] = true,
	["DISCO3"] = true,
	["DISCO4"] = true,
}

Takis_Hook.addHook("PreThinkFrame",function(p)
	local me = p.realmo
	if (me.skin ~= SOAP_SKIN) then return end
	local soap = p.soaptable
	
	if soap.fakeskidtime
		if P_GetPlayerControlDirection(p) == 1
			p.cmd.forwardmove = $/2
		end
		soap.fakeskidtime = p.skidtime
	end
	
	soap.bm.damaging = false
	soap.bm.dmg_props = {
		att = 0,
		def = 0,
		s_att = 0,
		s_def = 0,
		name = ""
	}
	--Okay
	if soap.bm.lockmove
		p.cmd.forwardmove = $/5
		p.cmd.sidemove = $/5
		soap.bm.lockmove = $ - 1
	end
	
	local wassuper = false
	if p.powers[pw_super]
	and (p.rings)
	and (skins[soap.last.skin].flags & SF_SUPER)
		wassuper = true
	end
	
	if (p.cmd.buttons & BT_SPIN and (p.pflags & PF_USEDOWN == 0)
	and p.charflags & SF_SUPER)
	and not p.powers[pw_super]
	and not (maptol & TOL_NIGHTS or G_IsSpecialStage(gamemap))
	and not wassuper
		p.charflags = $ &~SF_SUPER
	end
end)

Takis_Hook.addHook("Soap_DashSpeeds", function(p, dash, time, noadjust)
	local soap = p.soaptable
	
	if (soap.inFangsHeist)
		dash = $ / 2
		time = $ * 3/2
		soap.nerfed = true
	end
	if soap.inBattle
	or Soap_IsCompGamemode()
		if not soap.inBattle
			dash = $ * 3/5
		--be about the same speed as heavy
		else
			noadjust = true
			dash = 19*FU
			--Cool...
			if soap.accspeed >= 15*FU
			and soap.in2D
				dash = 0
			end
		end
		time = $ * 3/5
	end
	
	if (p.powers[pw_sneakers])
		--uncontrollable otherwise
		dash = $ / 2
		time = $ / 5
	end
	if soap.doSuperBuffs
		dash = FixedMul($, tofixed("0.45"))
		time = $ / 5
	end
	
	if gametyperules & GTR_TAG
		--hiders are a bit slower
		if not (p.pflags & PF_TAGIT)
			dash = $ * 7/9
		end
	end
	if (p.gotflag)
	or (p.gotcrystal)
		time = $ * 4
		dash = $ * 5/8
		soap.nerfed = true
		
		if soap.inBattle
		and soap.accspeed >= 15*FU
			dash = 0
		end
	end
	
	return dash, time
end)

Takis_Hook.addHook("Soap_Thinker",function(p)
	local me = p.realmo
	local soap = p.soaptable

	soap.afterimage = false
	local cos_height = 6
	--for reset state
	local setstate = false
	
	if skins[p.skin].flags & SF_SUPER
		if p.rings >= 25
		or ((maptol & TOL_NIGHTS)
		or G_IsSpecialStage(gamemap))
			p.charflags = $|SF_SUPER
		elseif not p.powers[pw_super]
			p.charflags = $ &~SF_SUPER
		end
	else
		p.charflags = $ &~SF_SUPER
	end
	
	--taunts
	if (soap.tossflag and (soap.c2 or soap.c3))
	and (p.panim == PA_IDLE or p.panim == PA_RUN or soap.accspeed <= 5*FU)
	and (P_IsObjectOnGround(me))
	and not soap.taunttime
	and me.health
	and (soap.notCarried)
	and not (soap.noability & SNOABIL_TAUNTS)
		if (soap.c2)
			S_StartSound(me,sfx_flex)
			me.state = S_PLAY_SOAP_FLEX
			soap.taunttime = TR
			soap.crouch_cooldown = true
		elseif (soap.c3)
			S_StartSound(me,sfx_hahaha)
			me.state = S_PLAY_SOAP_LAUGH
			soap.taunttime = TR
		end
		setstate = true
		soap.stasistic = soap.taunttime
		
		me.momx,me.momy = p.cmomx,p.cmomy
	end
	
	if soap.taunttime
		local angle = (p.cmd.angleturn << 16)
		if soap.in2D then angle = ANGLE_90 end
		
		if me.state == S_PLAY_SOAP_FLEX
			p.drawangle = angle + ANGLE_90
		elseif me.state == S_PLAY_SOAP_LAUGH
			p.drawangle = angle + ANGLE_180
		end
		
		soap.taunttime = $-1
		if soap.taunttime == 0
			me.state = S_PLAY_STND
		end
		soap.noability = $|SNOABIL_TOP
	end
	
	if ((soap.weaponnext and soap.weaponprev)
	or (p.exiting and p.pflags & PF_FINISHED
		and soap.accspeed < FU/5
		and soap.onGround
	) or (
		soap.onGround
		and (soap.accspeed <= FU)
		and discoranges[Soap_CheckFloorPic(me,true)] == true
	))
	and (me.health)
	and not soap.taunttime
	and not (p.powers[pw_carry] or soap.isSliding)
	and not P_PlayerInPain(p)
	and not (soap.noability & SNOABIL_BREAKDANCE)
		if me.state ~= S_PLAY_SOAP_BREAKDANCE
			me.state = S_PLAY_SOAP_BREAKDANCE
		else
			--frame F = loop point start
			--frame 60 = animation end
			
			--init
			if skins[p.skin].sprites[SPR2_BRDA].numframes == 61
				if soap.breakdance < F
					me.frame = ($ &~FF_FRAMEMASK)|(soap.breakdance)
				--loop
				else
					local timer = (soap.breakdance - F) % (60 - F)
					me.frame = ($ &~FF_FRAMEMASK)|(timer + G)
				end
			else
				local timer = soap.breakdance % skins[p.skin].sprites[SPR2_ROLL].numframes
				me.frame = ($ &~FF_FRAMEMASK)|(timer)
			end
			p.drawangle = (p.cmd.angleturn << 16) + ANGLE_180
			local incre_frame = (leveltime & 1)
			if incre_frame
				soap.breakdance = $ + 1
			end
			soap.true_breakdance = $ + 1
			
			if soap.true_breakdance == TR * 3/2
			and not p.exiting
			and not (soap.boombox and soap.boombox.valid)
				local angle = me.angle + ANGLE_45
				local dist = 55*FU
				local boom = P_SpawnMobjFromMobj(me,
					0, --P_ReturnThrustX(nil,angle, dist),
					0, --P_ReturnThrustY(nil,angle, dist),
					0,
					MT_SOAP_BOOMBOX
				)
				local thrust_lul = FixedDiv(FixedMul(dist,me.scale),12*FU + 5*FU)
				if soap.inWater then thrust_lul = $ / 2 end
				Soap_ZLaunch(boom, 12*FU)
				P_Thrust(boom,angle,
					thrust_lul
				)
				
				boom.color = p.skincolor
				boom.tracer = me
				boom.lifetime = 0
				S_StartSoundAtVolume(me,sfx_sp_jm2, 255 * 8/10)
				boom.songid = 1
				if P_RandomChance(FU / 10)
					boom.funny = true
					boom.songid = P_RandomRange(2, #SOAP_BOOMBOXJAMS)
				end
				soap.boombox = boom
				
				local speed = 5*me.scale
				for i = 0,P_RandomRange(20,29)
					local poof = P_SpawnMobjFromMobj(boom,
						Soap_RandomFixedRange(-15,15),
						Soap_RandomFixedRange(-15,15),
						FixedDiv(boom.height,boom.scale)/2 + Soap_RandomFixedRange(-15,15),
						MT_THOK
					)
					poof.state = mobjinfo[MT_SPINDUST].spawnstate
					local hang,vang = R_PointTo3DAngles(
						poof.x,poof.y,poof.z,
						boom.x,boom.y,boom.z + boom.height/2
					)
					P_3DThrust(poof, hang,vang, speed)
					
					poof.spritexscale = $ + Soap_RandomFixedRange(0,2)/3
					poof.spriteyscale = poof.spritexscale
				end
			end
		end
	else
		if me.state == S_PLAY_SOAP_BREAKDANCE
			if not setstate
				me.state = S_PLAY_STND
				Soap_ResetState(p)
				if not soap.onGround then me.state = S_PLAY_FALL end
			end
		end
		soap.breakdance = 0
		soap.true_breakdance = 0
	end
	if not (soap.boombox and soap.boombox.valid and soap.boombox.health)
		soap.boombox = nil
	end
	
	soap.pound_cooldown = max($ - 1, 0)
	
	--MF_NOSQUISH
	local squishme = true
	
	local was_crouching = soap.crouching
	soap.crouch_removed = was_crouching
	soap.crouching = false
	
	local forced_crouch = false
	if not ((me.flags & MF_NOCLIPHEIGHT)
	or (p.pflags & PF_GODMODE))
	and me.health
		if (me.ceilingz - me.floorz < P_GetPlayerHeight(p))
		and not (p.pflags & PF_SPINNING)
		and not (soap.noability & SNOABIL_CROUCH)
		and (p.powers[pw_carry] == CR_NONE)
			forced_crouch = true
			p.pflags = $ &~PF_SPINNING
		end
	end
	
	--c2 specials
	if (soap.c2)
	or forced_crouch
		
		--crouching
		if soap.onGround
		and me.health
		and not (soap.pounding)
		and not (soap.taunttime)
		and not soap.crouch_cooldown
		and not soap.slipping
		and not (soap.noability & SNOABIL_CROUCH)
			local can_crouch = (
				soap.accspeed <= 10*FU or was_crouching or soap.slipping or forced_crouch
			)
			
			--uncurl
			if (p.pflags & PF_SPINNING)
			and soap.c2 == 1
			and soap.onGround
				p.pflags = $ &~PF_SPINNING
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
				
				soap.crouch_cooldown = true
				
			--spin launch
			elseif not can_crouch --soap.rdashing
			and not (p.pflags & PF_SPINNING)
			and (soap.c2 == 1 or me.eflags & MFE_JUSTHITFLOOR)
			and (abs(p.cmd.forwardmove) or abs(p.cmd.sidemove))
				p.pflags = $|PF_SPINNING
				me.state = S_PLAY_ROLL
				S_StartSound(me,sfx_zoom)
				
			--actually crouch
			elseif not (p.pflags & PF_SPINNING)
			and can_crouch
				soap.crouching = true
				soap.noability = $|SNOABIL_RDASH|SNOABIL_UPPERCUT|SNOABIL_TAUNTS
				
				p.normalspeed = skins[p.skin].normalspeed / 2
				p.accelstart = skins[p.skin].accelstart * 2
				
				soap.rdashing = false
				
				if soap.crouch_time == 0
					Soap_RemoveSquash(p, "crouchup_anim")
					
					local ease_time = soap_crouchanimtime
					local ease_func = "outback"
					local end_val = -FU/2
					Soap_AddSquash(p, {
						ease_func = ease_func,
						start_v = 0,
						end_v = tofixed("0.6"),
						time = ease_time
					}, {
						ease_func = ease_func,
						start_v = 0,
						end_v = end_val,
						time = ease_time
					}, "crouchdown_anim")
				end
				
				--TODO: remove when crouch animations are added
				if soap.crouch_time >= soap_crouchanimtime
					soap.spritexscale = FixedMul($, tofixed("1.6"))
					soap.spriteyscale = $/2
				end
				cos_height = $ - 3
				
				--slip down steep slopes
				P_ButteredSlope(me)
				if me.standingslope
					local slope = me.standingslope
					
					if (abs(slope.zdelta) >= FU/4)
						soap.slipping = true
						if soap.accspeed < 10*FU
							P_Thrust(me, slope.xydirection,
								10*me.scale * sign(slope.zdelta)
							)
						end
					end
				end
				
				soap.crouch_time = $ + 1
			end
		end
		
		if (p.pflags & (PF_JUMPED|PF_THOKKED) == PF_JUMPED)
		and (soap.c2 == 1)
		and Soap_SuperReady(p)
		and not soap.isSolForm
			P_DoSuperTransformation(p)
		end
		
		if (soap.inBattle and CBW_Battle)
		and (p.powers[pw_shield] & SH_NOSTACK == SH_ARMAGEDDON)
		and soap.c2 == 1
		and ((p.pflags & PF_JUMPED)
			and not p.powers[pw_carry]
			and not (p.pflags & PF_THOKKED)
			and not p.noshieldactive
		)
		and not (p.armachargeup)
			p.armachargeup = 1
			p.pflags = $ | PF_SHIELDABILITY | PF_FULLSTASIS | PF_JUMPED & ~PF_NOJUMPDAMAGE
			me.state = S_PLAY_ROLL
			
			CBW_Battle.teamSound(me, p, sfx_gbeep, sfx_s3kc4s, 200, true)
			CBW_Battle.teamSound(nil, p, sfx_gbeep, sfx_s3kc4s, 100, true)
			soap.airdashed = false
			soap.uppercutted = false
			soap.canuppercut = false
			soap.pounding = false
		end
	else
		soap.crouch_cooldown = false
	end
	
	if not soap.crouching
	and was_crouching
		p.normalspeed = skins[p.skin].normalspeed
		p.accelstart = skins[p.skin].accelstart
		
		soap.crouch_time = 0
		Soap_RemoveSquash(p, "crouchdown_anim")
		local ease_time = soap_crouchanimtime
		local ease_func = "outback"
		local end_val = -FU/2
		Soap_AddSquash(p, {
			ease_func = ease_func,
			start_v = tofixed("0.6"),
			end_v = 0,
			time = ease_time
		}, {
			ease_func = ease_func,
			start_v = end_val,
			end_v = 0,
			time = ease_time
		}, "crouchup_anim")
	end
	
	soap.topcooldown = max($-1, 0)
	--c3 specials
	if (soap.c3)
		
		local candotop = false
		local incoop = (CV.FindVar("friendlyfire").value and not Soap_IsCompGamemode()) and (multiplayer or netgame)
		
		--spininng top
		if ((soap.c3 == 1)
		or (soap.topcooldown == 0))
		and ((G_RingSlingerGametype()
		and (p.rings == 0))
		or incoop)
			candotop = true
			
			if gametyperules & GTR_TAG
			and (p.pflags & PF_TAGIT == 0)
				candotop = false
			end
		end
		
		if candotop
		and not soap.topcooldown
			SoapST_Start(p)
			soap.topcooldown = SOAP_TOPCOOLDOWN
			setstate = true
		end
	end
	
	if not (soap.noability & SNOABIL_CROUCH)
		if p.pflags & PF_JUMPED then p.pflags = $ &~PF_SPINNING end
		if (p.pflags & PF_SPINNING)
		and soap.onGround
			if not soap.setrolltrol
				p.thrustfactor = skins[p.skin].thrustfactor * 7
			end
			soap.setrolltrol = true
		else
			if soap.setrolltrol
				p.thrustfactor = skins[p.skin].thrustfactor
			end
			soap.setrolltrol = false
		end
	elseif soap.setrolltrol
		p.thrustfactor = skins[p.skin].thrustfactor
	end
	
	soap.nerfed = false
	local old_maxdash = soap._maxdash
	local my_maxdash = SOAP_MAXDASH
	local my_dashtime = SOAP_DASHTIME
	local my_noadjust = false
	do
		local hook_event,hook_name = Takis_Hook.findEvent("Soap_DashSpeeds")
		if hook_event
			for i,v in ipairs(hook_event)
				local new_md,new_dt,no_adjust = Takis_Hook.tryRunHook(hook_name, v, p,my_maxdash,my_dashtime)
				
				if new_md ~= nil
				and type(new_md) == "number"
					my_maxdash = abs(new_md)
				end
				if new_dt ~= nil
				and type(new_dt) == "number"
					my_dashtime = abs(new_dt)
				end
				if no_adjust ~= nil
				and type(no_adjust) == "boolean"
					my_noadjust = no_adjust
				end
			end
		end
		
		if soap.inWater
			soap._maxdash = $ * 3/2
		end
		
		--hacky
		--print(("%f"):format(p.gradualspeed))
		soap._maxdash = my_maxdash + (p.gradualspeed or 0)
		soap._maxdashtime = max(my_dashtime, 2)
		soap._noadjust = my_noadjust
	end
	
	--spin specials
	if (soap.use)
		
		--grabbing (lol)
		if (CV.FindVar("friendlyfire").value)
		and (not Soap_IsCompGamemode())
		and (soap.use_R)
		and (soap.use == 1)
		and (soap.onGround)
		and not (p.pflags & PF_SPINNING)
		and not (me.soap_grabcooldown)
			if not Soap_GrabHitbox(p)
				if (me.health)
					p.skidtime = TR/2
					if p.powers[pw_carry] == CR_NONE
						me.state = S_PLAY_SKID
						me.tics = p.skidtime
					end
					soap.fakeskidtime = p.skidtime
					p.pflags = $ &~PF_SPINNING
				end
				me.soap_grabcooldown = TR*3
			end
			soap.use_R = 0
		end
		
		--r-dash
		local rightway = false
		if (soap.in2D)
			rightway = abs(p.cmd.sidemove) > 0
		else
			if p.cmd.sidemove ~= 0
				rightway = (p.cmd.forwardmove >= 0)
			else
				rightway = (p.cmd.forwardmove > 0)
			end
		end
		
		if (P_GetPlayerControlDirection(p) == 1)
		--not going backwards
		and rightway
		and soap.onGround
		and not soap.crouching
		and not (soap.noability & SNOABIL_RDASH)
			local skin_t = skins[p.skin]
			local maximumspeed = skin_t.normalspeed + soap._maxdash
			soap.rdashing = true
			
			if soap.onGround
				local old_speed = p.normalspeed
				local extracharge = 0
				
				--speed boost when landing from an airdash,
				--pizza-tower style
				if soap.airdashed
				and (soap.accspeed >= 28*FU)
					p.normalspeed = $ + soap._maxdash/2
				end
				
				--this code is based off a script my friend marilyn wrote,
				--shoutouts to her!
				if me.standingslope
					local slope = me.standingslope
					local xydiff = R_PointToAngle2(0,0,me.momx,me.momy) - slope.xydirection
					local zangle = FixedMul(slope.zangle, cos(xydiff))
					
					zangle = AngleFixed($)/FU
					if zangle >= 180 then zangle = $ - 360 end
					
					--only add speed going DOWN slopes,
					--and never remove speed... (butteredslope should handle that)
					if -zangle > 0
						--GFZ2 slope-compliant
						p.normalspeed = $ - zangle * (FU/38)
						soap.chargingtime = min($ - zangle/5, 3*TR)
						if p.normalspeed > maximumspeed
						and (-zangle * (FU/38) >= FU*6/10)
							soap.chargingtime = 3*TR
							extracharge = (p.normalspeed - maximumspeed)/5
						end
						soap.speedlenient = max($, 3)
					--...BUT!!!	if we're going uphill while waterrunning,
					--we should be getting speed back, since water should
					--give almost no resistance
					elseif soap.onWater
						local angle,thrust = Soap_SlopeInfluence(me,p, {
							allowstand = true, allowmult = true
						})
						if angle ~= nil
							P_Thrust(me,angle, -thrust)
						end
					end
				end
				
				p.normalspeed = min(
					$ + (soap._maxdash/soap._maxdashtime),
					--dont go over
					maximumspeed
				)
				
				--readjust our normalspeed if the dash threshold changed
				if not soap._noadjust
					if soap._maxdash < old_maxdash
						p.normalspeed = $ - (old_maxdash - soap._maxdash)
					elseif soap._maxdash > old_maxdash
						p.normalspeed = $ + (soap._maxdash - old_maxdash)
					end
				end
				
				--charge sfx
				if p.normalspeed >= maximumspeed
				and old_speed < maximumspeed
					S_StartSound(me,sfx_sp_dss)
					soap.chargedtime = 10
					soap.speedlenient = max($,4)
					
					Soap_SquashMacro(p, {ease_func = "insine", ease_time = soap.chargedtime * 3/4, strength = (FU/3)})
					
					if (p.powers[pw_shield] & SH_NOSTACK == SH_FLAMEAURA)
						S_StartSound(me,sfx_s3k43)
					end
				end
				
				--add extra speed
				if p.normalspeed >= maximumspeed
				and not Soap_IsCompGamemode()
					local chargetime = soap.inWater and TR*3 or TR
					local frac = (FU/chargetime)
					if (p.powers[pw_sneakers])
						frac = $ * 3/2
					end
					
					if soap.chargingtime < 3*TR
						soap.dashcharge = 0
						soap.chargingtime = $ + (p.powers[pw_sneakers] and 2 or 1)
						
					elseif soap.dashcharge < SOAP_EXTRADASH
						soap.dashcharge = $ + frac + extracharge
						
						if soap.dashcharge >= SOAP_EXTRADASH
							S_StartSound(me,sfx_sp_max)
							soap.dashcharge = SOAP_EXTRADASH
							soap.speedlenient = max($,4)
						end
					--overcharge
					else
						soap.dashcharge = $ + frac + extracharge/2
						if soap.dashcharge >= 100*FU
							soap.dashcharge = ease.linear(FU/3, $, 100*FU)
						end
					end
					
					p.normalspeed = maximumspeed + soap.dashcharge
				else
					soap.dashcharge = 0
					soap.chargingtime = 0
				end
				
				local speed_diff = maximumspeed - p.normalspeed
				if speed_diff < 0
				and speed_diff >= -FU
				and (soap.dashcharge == 0)
					p.normalspeed = maximumspeed
				end
			end
		else
			if soap.onGround
				if not soap.dashgrace
				and not (p.pflags & PF_SPINNING)
					soap.rdashing = false
				else
					soap.dashgrace = max($ - 1, 0)
				end
			end
		end
		
		--b-rush
		--airdash
		if (soap.use == 1)
		and not soap.onGround
		and not soap.airdashed
		and not soap.inPain
		and not soap.pounding
		and me.health
		and (p.powers[pw_carry] == CR_NONE)
		and not soap.noairdashforme
		and not (soap.noability & SNOABIL_AIRDASH)
			local thrust = 12*FU
			local min_speed = 25*FU
			local max_speed = clamp(39*FU, soap.accspeed, 39*FU + soap._maxdash)
			if soap.nerfed
				thrust = $/4
				min_speed = $/2
			end
			if soap.inWater
				thrust = $*2/3
				min_speed = $*2/3
				max_speed = $*2/3
			end
			if (p.powers[pw_shield] & SH_NOSTACK) == SH_FLAMEAURA
				thrust = $*6/5
				min_speed = $*4/3
				S_StartSound(me,sfx_s3k43)
			end
			local hook_event,hook_name = Takis_Hook.findEvent("Char_OnMove")
			if hook_event
				for i,v in ipairs(hook_event)
					local new_t, new_min, new_max = Takis_Hook.tryRunHook(hook_name, v, p, "airdash", thrust,min_speed,max_speed)
					
					if new_t ~= nil
					and type(new_t) == "number"
						thrust = abs(new_t)
					end
					if new_min ~= nil
					and type(new_min) == "number"
						min_speed = abs(new_min)
					end
					if new_max ~= nil
					and type(new_max) == "number"
						max_speed = abs(new_max)
					end
				end
			end
			
			soap.airdashcharge = 0 --(gametyperules & GTR_FRIENDLY == 0) and TR/3 or 0
			local angle = Soap_ControlDir(p)
			if soap.accspeed + thrust < max_speed
				if soap.accspeed + thrust < min_speed
					thrust = $ + (min_speed - (soap.accspeed + thrust))
				end
				
				P_InstaThrust(me,
					angle,
					FixedMul(soap.accspeed + thrust,me.scale)
				)
			else
				local speed = max(max_speed, soap.accspeed)
				P_InstaThrust(me,
					angle,
					FixedMul(speed,me.scale)
				)
			end
			
			if not soap.onGround
			and soap.sprung
				soap.speedlenient = max($, TR/2)
			end
			
			if me.momz*soap.gravflip < 0
				me.momz = $/2
			elseif me.momz*soap.gravflip > 0
				if Soap_IsCompGamemode()
					me.momz = 0
				else
					me.momz = $ / 2
				end
			end
			
			if soap.airdashcharge == 0
				S_StartSound(me,sfx_sp_dss)
			else
				Soap_Hitlag.addHitlag(me,soap.airdashcharge,false)
				me.damageinhitlag = true
				S_StartSound(me,sfx_kc63)
			end
			me.state = S_PLAY_FLOAT_RUN
			p.panim = PA_DASH
			p.pflags = $|PF_JUMPED &~PF_SPINNING
			me.tics = 3
			p.drawangle = angle
			soap.uppercut_spin = 0
			soap.uppercutted = false
			soap.airdashed = true
			soap.rdashing = true
			soap.sprung = false
			setstate = true
		end
		
	else
		if soap.onGround
			if not soap.dashgrace
			and not (p.pflags & PF_SPINNING)
				soap.rdashing = false
			else
				soap.dashgrace = max($ - 1, 0)
			end
		end
	end
	
	--c1 specials
	if (soap.c1)
		
		--uppercut
		if soap.c1 == 1
		and soap.canuppercut
		and not soap.inPain
		and me.health
		and not soap.taunttime
		and not soap.pounding
		and not soap.uppercut_cooldown
		and (p.powers[pw_carry] == CR_NONE)
		and not (soap.noability & SNOABIL_UPPERCUT)
			soap.uppercut_spin = soap_baseuppercutturn
			
			local thrust = soap.nerfed and 10*FU or 13*FU
			local shield = p.powers[pw_shield] & SH_NOSTACK
			if (shield == SH_WHIRLWIND)
				thrust = $ + 4*FU
				S_StartSound(me, sfx_wdjump)
				
				Soap_DustRing(me,
					MT_SPINDUST,
					16,
					{me.x,me.y,me.z},
					me.radius * 3/2,
					FixedMul(thrust,me.scale),
					me.scale / 2,
					me.scale * 3/2,
					false,
					function(dust)
						dust_noviewmobj(dust)
						P_SetObjectMomZ(dust, thrust/2)
						dust.momx = $ + me.momx * 3/4
						dust.momy = $ + me.momy * 3/4
					end
				)
				soap.uppercut_spin = $ + 360*FU
			end
			if soap.doSuperBuffs
				thrust = $ + 5*FU
			end
			
			Soap_ZLaunch(me, thrust)
			p.pflags = $|PF_JUMPED &~(PF_STARTJUMP|PF_SPINNING)
			me.state = S_PLAY_MELEE
			me.tics = -1
			p.drawangle = me.angle
			soap.canuppercut = false
			
			--soap.rdashing = false
			soap.airdashed = false
			soap.just_uppercut = 3
			soap.onGround = false
			
			soap.sprung = false
			soap.ranoff = false
			
			local sound = true
			if (shield == SH_THUNDERCOIN)
				if not soap.uppercut_tc
					soap.canuppercut = true
					soap.uppercut_tc = true
				else
					if soap.just_uppercut
						S_StartSound(me, sfx_s3k45)
						sound = false
						
						spawn_thundercoin_sparks(p,me)
						soap.noairdashforme = true
						soap.uppercut_spin = $ + 360*FU
					end
				end
			end
			soap.uppercutted = true
			if sound
				S_StartSoundAtVolume(me,sfx_sp_upr, 255 * 8/10)
			end
			
			local hook_event,hook_name = Takis_Hook.findEvent("Char_OnMove")
			if hook_event
				for i,v in ipairs(hook_event)
					Takis_Hook.tryRunHook(hook_name, v, p, "uppercut", sound)
				end
			end
			setstate = true
		end
	end
	if soap.uppercut_cooldown then soap.uppercut_cooldown = $ - 1 end
	
	--jump specials
	if (soap.jump)
		
		--pound
		--bit of delay when you werent jumping to prevent
		--misinputs
		local pound_inittime = (soap.sprung and not soap.doublejumped) and TR/5 or 1
		
		if (soap.jump == pound_inittime)
		and not soap.onGround
		and not (p.pflags & PF_THOKKED)
		and (soap.doublejumped or soap.sprung)
		and me.health
		and not P_IsObjectInGoop(me)
		and (soap.pound_cooldown == 0)
		and not (soap.noability & SNOABIL_POUND)
			soap.pounding = true
			soap.sprung = false
			
			S_StartSound(me,sfx_sp_bom)
			Soap_ZLaunch(me,13*FU)
			p.pflags = $|PF_THOKKED|PF_JUMPED &~(PF_STARTJUMP|PF_SPINNING)
			
			local hook_event,hook_name = Takis_Hook.findEvent("Char_OnMove")
			if hook_event
				for i,v in ipairs(hook_event)
					Takis_Hook.tryRunHook(hook_name, v, p, "pound")
				end
			end
			setstate = true
		end
		
	end
	
	--sm64
	if (p.pflags & PF_JUMPED)
	--or not (p.pflags & PF_SPINNING)
	or soap.inPain
	or (not soap.notCarried)
	or ((not soap.onGround and soap.accspeed < 10*FU)
		or (soap.accspeed < 5*FU and me.standingslope == nil)
	)
	or not (me.health)
		soap.slipping = false
	end
	if soap.slipping
		local slope = me.standingslope
		p.pflags = $|PF_SPINNING
		soap.allowjump = true
		soap.stasistic = max($, 3)
		
		if (slope)
			local angdiff = R_PointToAngle2(0, 0, me.momx, me.momy) - slope.xydirection
			local speed = FixedHypot(me.momx, me.momy)
			
			--going down it
			if (P_ReturnThrustY(me, slope.zangle, P_ReturnThrustX(me, angdiff, speed))*soap.gravflip < 0)
				P_ButteredSlope(me)
			end
		end
		
		if soap.onGround
			local destang = R_PointToAngle2(0,0,me.momx,me.momy)
			
			if soap.sidemove ~= 0
				local adjust = (abs(soap.sidemove) * 3) * FU/525
				if (soap.accspeed < 12*FU)
					adjust = FixedMul($, ease.outquad(FixedDiv(soap.accspeed,12*FU),FU,0))
				end
				
				local angle = destang
				local turn = soap.sidemove
				--if we're facing OPPOSITE destang, make right inputs turn right,
				--otherwise, make right inputs turn left and vice versa
				if not (abs(destang - me.angle) > ANGLE_90)
					turn = -$
				end
				if turn < 0
					angle = $ - ANGLE_90
				else
					angle = $ + ANGLE_90
				end
				
				P_Thrust(me, angle, FixedMul(adjust, me.scale))
			end
			
			p.drawangle = destang + ANGLE_180
			
			local friction = ORIG_FRICTION + FU/13
			if (me.standingslope)
				me.friction = max($, friction)
			else
				--modifying friction doesnt do anything when the player
				--is spinning so we have to do it ourselves
				me.momx = FixedMul($, friction)
				me.momy = FixedMul($, friction)
			end
		else
			P_PitchRoll(me, FU/4)
		end
		
		if soap.sliptime > 4
		and (not slope
		or (slope and abs(slope.zdelta) <= FU/4 or soap.accspeed < FU))
		and soap.accspeed <= FU
			soap.slipping = false
		end
		soap.sliptime = $ + 1
		
		local chance = P_RandomChance(FU/3)
		if soap.accspeed >= 30*FU
			chance = true
		end
		if soap.accspeed <= 7*FU
			chance = false
		end
		if chance
		and not (me.eflags & (MFE_UNDERWATER|MFE_TOUCHLAVA) == MFE_UNDERWATER)
		and soap.onGround
			S_StartSound(me,sfx_s3k7e)
			local dust = P_SpawnMobjFromMobj(me,
				P_RandomRange(-16,16)*FU,
				P_RandomRange(-16,16)*FU,
				0,
				MT_SPINDUST
			)
			dust.destscale = 1
			dust.scalespeed = FixedDiv($, dust.scale)
			P_SetObjectMomZ(dust, FU*4 + soap.accspeed/20)
			
			P_InstaThrust(dust,
				R_PointToAngle2(dust.x,dust.y, me.x,me.y),
				-5*me.scale
			)
			--Yes!!
			if P_RandomChance(FU/2)
				local dust = P_SpawnMobjFromMobj(me,
					P_RandomRange(-16,16)*FU,
					P_RandomRange(-16,16)*FU,
					0,
					MT_SPINDUST
				)
				dust.destscale = 1
				dust.scalespeed = FixedDiv($, dust.scale)
				P_SetObjectMomZ(dust, FU*4 + soap.accspeed/20)
				
				P_InstaThrust(dust,
					R_PointToAngle2(dust.x,dust.y, me.x,me.y),
					-5*me.scale
				)
			end
		end
		if me.state ~= S_PLAY_SOAP_SLIP
			me.state = S_PLAY_SOAP_SLIP
		end
	else
		if soap.sliptime
		and not setstate
		and not (p.pflags & PF_JUMPED)
			Soap_ResetState(p)
			if not soap.onGround then me.state = S_PLAY_FALL end
		end
		
		soap.sliptime = 0
	end
	
	local spawn_aura = false
	
	--things to do when grounded
	if soap.onGround
	or soap.sprung
		soap.airdashed = false
		soap.doublejumped = false
		soap.canuppercut = true
		soap.uppercutted = false
		soap.uppercut_tc = false
		
		soap.noairdashforme = false
	end
	
	if soap.airdashed
		
		if (me.state == S_PLAY_FLOAT_RUN)
			if Soap_DirBreak(p,me, R_PointToAngle2(0,0,me.momx,me.momy))
				Soap_Hitlag.addHitlag(me, 7, false)
			end
			
			p.powers[pw_strong] = $|STR_SPIKE|STR_ANIM
			spawn_aura = true
			
			me.pitch = FixedMul($, FU*3/4)
			me.roll = FixedMul($, FU*3/4)
			
			p.runspeed = soap.accspeed - 10*FU
			if soap.accspeed >= FU
				p.drawangle = R_PointToAngle2(0,0, me.momx,me.momy)
			end
			soap.afterimage = true
		end
		
		--replenish
		if (me.eflags & MFE_SPRUNG)
			soap.airdashed = false
		end
		
		soap.nofreefall = true
	end
	
	if soap.uppercutted
	and me.health and not (soap.inPain or me.state == S_PLAY_GASP)
	and not (soap.noability & SNOABIL_UPPERCUT)
		if (me.momz*soap.gravflip >= 0)
			
			--replenish on badnik bounces
			if soap.last.momz*soap.gravflip < 0
			and not soap.just_uppercut
			and not soap.onGround
				soap.canuppercut = true
			end
			
			if me.sprite2 ~= SPR2_MLEE
				me.state = S_PLAY_MELEE
			end
			
			if (me.state == S_PLAY_MELEE
			--shitty
			or me.sprite2 == SPR2_MLEE)
			and not soap.pounding
				--soap.bm.intangible = max($, 2)
				
				if not (soap.fx.uppercut_aura and soap.fx.uppercut_aura.valid)
					local follow = P_SpawnMobjFromMobj(me,0,0,0,MT_SOAP_FREEZEGFX)
					follow.tics = -1
					follow.fuse = -1
					follow.tracer = me
					follow.topdown = true
					follow.state = S_SOAP_NWF_WIND
					follow.sprite = SPR_NWF_TOPDOWN
					follow.dontdrawforviewmobj = me
					follow.spritexscale = $*3/4
					follow.spriteyscale = follow.spritexscale
					follow.alpha = 0
					follow.dist = 0
					follow.zcorrect = true
					soap.fx.uppercut_aura = follow
				end
				local aura = soap.fx.uppercut_aura
				
				aura.alpha = FixedCeil(ease.linear(FU/3, $, FU) * 100)/100		
				aura.dispoffset = me.dispoffset + 3
				
				aura.zoffset = FixedMul(skins[p.skin].height, me.scale)
			elseif (soap.fx.uppercut_aura and soap.fx.uppercut_aura.valid)
				destroy_uppercut_aura(p,me,soap)
			end
			
			soap.afterimage = true
			if Soap_DirBreak(p,me, R_PointToAngle2(0,0,me.momx,me.momy))
				Soap_Hitlag.addHitlag(me, 7, false)
			end
		else
			if me.state == S_PLAY_MELEE
			--shitty
			or me.sprite2 == SPR2_MLEE
			and not setstate
				me.state = S_PLAY_FALL
			end
			
			if (soap.fx.uppercut_aura and soap.fx.uppercut_aura.valid)
				destroy_uppercut_aura(p,me,soap)
			end
		end
	else
		if (soap.fx.uppercut_aura and soap.fx.uppercut_aura.valid)
			destroy_uppercut_aura(p,me,soap)
		end
		
		if (me.sprite2 == SPR2_MLEE
		and not soap.onGround)
		and not (soap.inPain or P_PlayerInPain(p))
			me.state = (me.momz * soap.gravflip > 0) and S_PLAY_SPRING or S_PLAY_FALL
		end
	end
	soap.just_uppercut = max($-1,0)
	
	--cancel r-dash when
	if not me.health
	or soap.inPain
	or (not soap.notCarried)
	or (soap.noability & SNOABIL_RDASH)
		soap.rdashing = false
	end
	
	--r-dash thinker
	--r dash thinker
	--rdash thinker
	--idk why this lags
	
	--just take it off when we dont need it
	p.charflags = $ &~(SF_RUNONWATER|SF_NOSKID)
	if soap.rdashing and not soap.resetdash
		--local micros = getTimeMicros()
		local skin_t = skins[p.skin]
		local dashspeed = skin_t.normalspeed + soap._maxdash
		local setangle = false
		
		--5 tics to let you get back on your feet
		if (me.eflags & MFE_SPRUNG)
			soap.dashgrace = 5
		end
		p.charflags = $|SF_NOSKID
		
		if soap.use == 1
		and (p.pflags & PF_SPINNING)
		and soap.onGround
			p.pflags = $ &~PF_SPINNING
			p.thrustfactor = skin_t.thrustfactor
			me.state = S_PLAY_RUN
			
			soap.speedlenient = max($,4)
		end
		
		local momentums = ORIG_FRICTION + FixedMul(
			max_mentums,
			min(
				FixedDiv(p.normalspeed - skin_t.normalspeed, soap._maxdash or FU),
				FU
			)
		)
		momentums = min($, ORIG_FRICTION + max_mentums)
		if me.friction < momentums
			me.friction = momentums
		end
		
		if not Soap_IsCompGamemode()
			local angle,thrust = Soap_SlopeInfluence(me,p, {
				allowstand = true, allowmult = true
			})
			if angle ~= nil
				P_Thrust(me,angle, thrust/3)
			end
		end
		
		local slow_speed = (p.normalspeed - 7*FU)
		if soap.inWater
			slow_speed = $/3
		end
		if soap.in2D
			slow_speed = $/2
		end
		
		if (soap.accspeed < slow_speed
		and p.normalspeed > skin_t.normalspeed + soap._maxdash/3)
		and soap.onGround
		and not ((me.eflags & MFE_SPRUNG)
		or soap.speedlenient)
			p.normalspeed = max(soap.accspeed, skin_t.normalspeed)
			if soap.dashlose > 5
				soap.dashcharge = 0
				soap.chargingtime = 0
			else
				soap.dashlose = $ + 1
			end
		else
			soap.dashlose = 0
		end
		
		if (p.pflags & PF_SPINNING)
			if (me.state ~= S_PLAY_ROLL)
			and (me.sprite2 ~= SPR2_MLEE)
				me.state = S_PLAY_ROLL
			end
		else
			if p.normalspeed < dashspeed
				if (me.state == S_PLAY_DASH)
					me.state = S_PLAY_RUN
				end
				if (soap.dashgrace
				or p.powers[pw_justsprung])
				and soap.onGround
					if soap.accspeed > dashspeed
						p.normalspeed = max($, dashspeed)
					end
				end
			else
				--mrce
				if not soap.onGround
					p.wallCling = true
				end
				if (me.state == S_PLAY_RUN)
				or (me.state == S_PLAY_WALK)
					me.state = S_PLAY_DASH
					p.panim = PA_DASH
				end
			end
		end
		
		if p.normalspeed < dashspeed
			p.runspeed = max(soap.accspeed - 5*FU, FU)
			
			local eased = 0
			if soap._maxdash ~= 0
				eased = ease.inoutquad(FU/5,
					FixedDiv(p.normalspeed - skin_t.normalspeed, soap._maxdash),
					FU
				)
			end
			
			if P_RandomChance(eased)
				spawn_sweat_mobjs(p,me,soap)
				if soap.onGround
				and (me.state ~= S_PLAY_SKID)
					S_StartSound(me,
						P_RandomRange(sfx_sp_st0,sfx_sp_st2)
					)
				end
			end
			S_StopSoundByID(me,sfx_sp_mac)
			S_StopSoundByID(me,sfx_sp_mc2)
			soap.dashangle = p.drawangle
		else
			--None of this in free fall
			if not (soap.uppercutted and me.state == S_PLAY_FALL)
				soap.afterimage = true
				
				local color = soap_rdashwind_base
				if (soap.dashcharge)
					local speed_frac = clamp(0,ease.incubic(FU/2,
						FixedDiv(
							p.normalspeed - dashspeed,
							SOAP_EXTRADASH
						), FU
					), FU)
					
					color = $ + (FixedMul(
						soap_rdashwind_inc*FU,
						speed_frac)
					)/FU
				end
				color = max(0, min($, #skincolors - 1))
				Soap_WindLines(me,nil,color)
				accelerative_speedlines(p,me,soap, FixedDiv(R_PointTo3DDist(0,0,0,me.momx,me.momy,me.momz),me.scale), 65*FU, color)
				
				if Soap_DirBreak(p,me, R_PointToAngle2(0,0,me.momx,me.momy))
					Soap_Hitlag.addHitlag(me, 7, false)
				end
				
				p.powers[pw_strong] = $|STR_SPIKE|STR_ANIM|STR_HEAVY
				p.runspeed = 4*FU
			end
			
			if not Soap_IsCompGamemode()
				--test shallowness, so we dont get "stuck" on water
				local floor = ((soap.gravflip == -1) and P_CeilingzAtPos or P_FloorzAtPos)(me.x,me.y,me.z,me.height)
				local watertop = (soap.gravflip == -1) and me.waterbottom - me.height or me.watertop
				
				--we DO have a water fof near us...
				if (me.watertop ~= me.z - 1000*FU
				and me.waterbottom ~= me.z - 1000*FU)
				--maybe not while we're water running
				and (floor ~= watertop)
					if (watertop - floor)*soap.gravflip <= 38 * me.scale
						p.charflags = $ &~SF_RUNONWATER
					else
						p.charflags = $|SF_RUNONWATER
					end
				--otherwise, dont bother
				else
					p.charflags = $|SF_RUNONWATER
				end
			end
			
			if me.state == S_PLAY_DASH
				if not soap.onGround
					S_StopSoundByID(me, sfx_sp_mc2)
					if not S_SoundPlaying(me,sfx_sp_mac)
						S_StartSound(me,sfx_sp_mac)
					end
					P_PitchRoll(me, FU/2)
				else
					S_StopSoundByID(me, sfx_sp_mac)
					if not S_SoundPlaying(me,sfx_sp_mc2)
						S_StartSound(me,sfx_sp_mc2)
					end
				end
				if soap.accspeed >= 3*FU
					soap.dashangle = P_AngleLerp(FU/4, $, R_PointToAngle2(0,0,me.momx,me.momy))
					p.drawangle = soap.dashangle
					--TODO: drifting vfx
					setangle = true
				end
				if (leveltime & 1)
					spawn_sweat_mobjs(p,me,soap)
					if soap.onGround
					and not soap.onWater
						local sidemove = FixedDiv(me.radius,me.scale)
						local sideangle = ANGLE_45
						for i = -1,1,2
							local kickup = P_SpawnMobjFromMobj(me,
								Soap_RandomFixedRange(-4,4) + P_ReturnThrustX(nil, p.drawangle + sideangle * i, sidemove),
								Soap_RandomFixedRange(-4,4) + P_ReturnThrustY(nil, p.drawangle + sideangle * i, sidemove),
								0,
								MT_SPINDUST
							)
							if me.eflags & (MFE_TOUCHWATER|MFE_UNDERWATER)
								kickup.state = mobjinfo[MT_SMALLBUBBLE].spawnstate
								kickup.tics = -1
								kickup.fuse = 10
								if (me.eflags & MFE_TOUCHLAVA)
									kickup.colorized = true
									kickup.color = SKINCOLOR_KETCHUP
								end
							elseif (p.powers[pw_shield] == SH_ELEMENTAL)
								kickup.state = S_SPINDUST_FIRE1
							end
							kickup.destscale = 1
							kickup.scalespeed = FixedDiv($, kickup.scale)
							P_SetObjectMomZ(kickup, Soap_RandomFixedRange(4,6))
							kickup.spritexscale = FU + Soap_RandomFixedRange(0,1) / 5
							kickup.spriteyscale = kickup.spritexscale
							
							P_InstaThrust(kickup,
								R_PointToAngle2(kickup.x,kickup.y, me.x,me.y),
								-10*me.scale
							)
						end
					end
				end
				
				spawn_aura = true
			else
				S_StopSoundByID(me,sfx_sp_mac)
				S_StopSoundByID(me,sfx_sp_mc2)
			end
			if not setangle
				soap.dashangle = p.drawangle
			end
		end
		
		if soap.airdashed
			if (me.state == S_PLAY_RUN)
				me.state = S_PLAY_FLOAT_RUN
				p.panim = PA_DASH
			end
			p.runspeed = soap.accspeed - 10*FU
			if me.state == S_PLAY_FLOAT_RUN
				P_PitchRoll(me, FU/6)
			end
		end
		
		--print("case1: "..(getTimeMicros() - micros))
	elseif soap.lastrdash or soap.resetdash
		--local micros = getTimeMicros()
		me.friction = ORIG_FRICTION
		soap.dashlose = 0
		
		if p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash
		and me.health
		and soap.onGround
		and not soap.inPain
		and P_GetPlayerControlDirection(p) ~= 1
		and not p.guard
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
		
		if me.state == S_PLAY_DASH
		and not p.guard
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
		end
		
		p.normalspeed = skins[p.skin].normalspeed
		p.runspeed = skins[p.skin].runspeed
		
		soap.dashcharge = 0
		soap.chargingtime = 0
		S_StopSoundByID(me,sfx_sp_mac)
		S_StopSoundByID(me,sfx_sp_mc2)
		soap.resetdash = false
		
		--print("case2: "..(getTimeMicros() - micros))
	else
		--local micros = getTimeMicros()
		if me.state == S_PLAY_DASH
		and soap.onGround
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
		end
		soap.dashangle = p.drawangle
		
		--print("case3: "..(getTimeMicros() - micros))
	end
	soap.lastrdash = soap.rdashing
	soap.speedlenient = max($-1,0)
	
	--stuff to do while pounding (STOP BRO)
	local do_poundaura = false
	local was_pounding = soap.pounding
	
	if (soap.noability & SNOABIL_POUND)
		soap.pounding = false
		if me.state == S_PLAY_MELEE
		and (me.sprite2 ~= SPR2_MLEE)
			me.state = S_PLAY_ROLL
		end
	end
	
	if soap.pounding
	and not (soap.noability & SNOABIL_POUND)
		do_poundaura = true
		squishme = false
		
		p.pflags = $|PF_JUMPED|PF_JUMPSTASIS
		me.pitch = FixedMul($, FU*3/4)
		me.roll = FixedMul($, FU*3/4)
		
		if me.health
			p.powers[pw_strong] = $|STR_SPRING|STR_HEAVY|STR_SPIKE
			p.charflags = $ &~SF_RUNONWATER
		end
		
		me.momz = $ + P_GetMobjGravity(me)
		if me.momz*soap.gravflip <= (soap.inWater and 4 or 8)*me.scale
			local fall_strength =  P_GetMobjGravity(me) * 3
			if p.powers[pw_shield] & SH_FORCE then fall_strength = $ * 5/4 end
			fall_strength = $ - ((me.scale*11/10)*soap.gravflip)
			
			me.momz = $ + fall_strength
		end
		
		if Soap_BreakFloors(p,me)
			Soap_Hitlag.addHitlag(me, 7, false)
		end
		
		--wind lines
		local color
		if (soap.poundarma)
			color = armacolors[P_RandomRange(1,#armacolors)]
		end
		accelerative_speedlines(p,me,soap, -FixedDiv(me.momz,me.scale) * soap.gravflip, 20*FU, color)
		
		--landed
		if P_IsObjectOnGround(me) --(soap.onGround)
		or (Soap_BouncyCheck(p))
		and not P_CheckDeathPitCollide(me)
			do_poundaura = false
			soap_poundonland(p,me,soap)
		else
			--momentum based squash and stretch
			do_poundsquash(p,me,soap)
		end
		
		if me.momz*soap.gravflip <= -25*me.scale
		and soap.last.momz*soap.gravflip > -25*me.scale
			S_StartSound(me, sfx_tk_fst)
		end
		if me.momz*soap.gravflip <= -10*me.scale
			soap.afterimage = true
		end
		
		if not (p.pflags & PF_JUMPED)
		or (me.eflags & MFE_SPRUNG)
		or not me.health
		or soap.inPain
			soap.pounding = false
			do_poundaura = false
			if (me.health)
			and (p.powers[pw_carry] == CR_NONE)
				me.state = (me.momz*soap.gravflip) > 0 and S_PLAY_SPRING or S_PLAY_FALL
				if soap.inPain
					me.state = S_PLAY_PAIN
					p.powers[pw_flashing] = flashingtics
				end
			end
		end
		
		if (soap.jump and (p.powers[pw_shield] & SH_NOSTACK == SH_ARMAGEDDON)
		and not soap.inBattle
		and soap.poundtime >= 10)
			if not soap.poundarma
				armasound(me)
			end
			soap.poundarma = true
			local range = 22
			do
				local color = armacolors[P_RandomRange(1,#armacolors)]
				local spark = P_SpawnMobjFromMobj(me,
					Soap_RandomFixedRange(-range,range),
					Soap_RandomFixedRange(-range,range),
					Soap_RandomFixedRange(0,range),
					MT_WATERZAP
				)
				spark.spritexscale = FU*7
				spark.spriteyscale = FU*4
				local ha,va = R_PointTo3DAngles(spark.x,spark.y,spark.z, me.x,me.y,me.z)
				P_3DThrust(spark, ha,va, -P_RandomRange(10,15)*me.scale)
				spark.blendmode = AST_ADD
				spark.renderflags = $|RF_FULLBRIGHT|RF_PAPERSPRITE
				spark.colorized = true
				spark.color = color
				spark.angle = ha
				spark.momx = $ + me.momx
				spark.momy = $ + me.momy
				spark.momz = $ + soap.rmomz
				
				--top sparks
				local angle = FixedAngle(Soap_RandomFixedRange(0,360))
				local rad = FixedDiv(me.radius,me.scale)
				local hei = FixedDiv(me.height,me.scale)
				spark = P_SpawnMobjFromMobj(me,
					P_ReturnThrustX(nil,angle,rad),
					P_ReturnThrustY(nil,angle,rad),
					(hei/2) + Soap_RandomFixedRange(-17,17), MT_SOAP_SPARK
				)
				spark.color = color
				spark.adjust_angle = angle
				spark.angle = spark.adjust_angle
				spark.target = me
				local ha,va = R_PointTo3DAngles(spark.x,spark.y,spark.z, me.x,me.y,me.z)
				spark.rollangle = va
				
				spark.spritexscale = FU/3 + P_RandomRange(0, FU/2)
				spark.spriteyscale = FU/2
				spark.renderflags = $|(spark.z <= me.z+(hei/2) and RF_VERTICALFLIP or 0)
				spark.momx = $ + me.momx
				spark.momy = $ + me.momy
				spark.momz = $ + soap.rmomz
			end
		else
			armasound(me,true)
		end
		
		if (soap.pounding)
			local hook_event,hook_name = Takis_Hook.findEvent("Char_OnMove")
			if hook_event
				for i,v in ipairs(hook_event)
					Takis_Hook.tryRunHook(hook_name, v, p, "poundthinker")
				end
			end
		end
		soap.poundtime = $ + 1
	end
	
	if was_pounding
	and not soap.pounding
		p.powers[pw_strong] = $ &~(STR_SPRING|STR_HEAVY|STR_SPIKE)
		me.spritexscale = FU
		me.spriteyscale = FU
		soap.poundtime = 0
		if me.state == S_PLAY_MELEE
		and (me.sprite2 ~= SPR2_MLEE)
			me.state = S_PLAY_ROLL
			P_MovePlayer(p)
			
			local carry = p.powers[pw_carry]
			if (carry == CR_ROLLOUT)
				me.state = (soap.accspeed) and S_PLAY_WALK or S_PLAY_STND
			end
		end
		armasound(me,true)
		S_StopSoundByID(me,sfx_tk_fst)
	end
	
	if do_poundaura
		soap.uppercutted = false
		soap.canuppercut = false
		--soap.bm.intangible = max($,2)
		
		local spritemul = FU*3/4
		local height = FixedMul(
			FixedMul(skins[p.skin].height, me.scale),
			me.spriteyscale
		)
		if not (soap.fx.pound_aura and soap.fx.pound_aura.valid)
			local follow = P_SpawnMobjFromMobj(me,0,0,0,MT_SOAP_FREEZEGFX)
			follow.tics = -1
			follow.fuse = -1
			follow.tracer = me
			follow.topdown = true
			follow.state = S_SOAP_NWF_WIND
			follow.sprite = SPR_NWF_TOPDOWN
			follow.dontdrawforviewmobj = me
			follow.spritexscale = spritemul
			follow.spriteyscale = spritemul
			follow.rollangle = ANGLE_180
			follow.alpha = 0
			follow.dist = 0
			follow.zcorrect = true
			soap.fx.pound_aura = follow
		end
		local aura = soap.fx.pound_aura
		
		local speedup_frame = false
		local momz = abs(FixedDiv(me.momz,me.scale))
		if (momz >= 5*FU)
			speedup_frame = P_RandomChance(
				min(FixedDiv(5*FU, (momz - 5*FU) or 1), FU)
			)
			if (momz >= 32*FU) then speedup_frame = true end
		end
		if speedup_frame
		and (aura.state ~= S_SOAP_NWF_WIND_FAST and aura.tics >= states[S_SOAP_NWF_WIND].tics - 2)
			aura.state = S_SOAP_NWF_WIND_FAST
		end
		
		aura.alpha = FixedCeil(ease.linear(FU/5, $, FU) * 100)/100		
		aura.spritexscale = spritemul
		aura.spriteyscale = spritemul
		
		aura.dispoffset = me.dispoffset + 3
	elseif (soap.fx.pound_aura and soap.fx.pound_aura.valid)
		P_RemoveMobj(soap.fx.pound_aura)
		soap.fx.pound_aura = nil
	end
	
	--spinning top
	--EXCEPT for when this happens
	if soap.inPain
	or soap.inSlide
	or (not me.health)
	or p.tumble --battle
		soap.toptics = 0
		if soap.topwindup
			soap.topwindup = 0
			me.translation = nil
		end
	end
	
	if soap.toptics
		if soap.topwindup
			p.acceleration = skins[p.skin].acceleration
			
			if soap.topwindup & 1
				me.translation = "Invert"
			else
				me.translation = nil
			end
			
			soap.topwindup = $ - 1
			if soap.topwindup == 0
				S_StartSoundAtVolume(me, sfx_kc4e, 255/2)
			/*
			elseif soap.topwindup % 5 == 0
				S_StartSound(me, sfx_s3kab1 + (soap.topwindup/5) * 2)
			*/
				me.translation = nil
				soap.topairborne = (not soap.onGround) and (soap.jump)
			end
		-- the actual top spin
		else
			if soap.topspin == false
				soap.topspin = 0
			end
			soap.topspin = $ - 35*FU
			
			if soap.topsound == -1
				soap.topsound = leveltime
			end
			if me.state ~= S_PLAY_SOAP_SPTOP
				me.state = S_PLAY_SOAP_SPTOP
			end
			p.powers[pw_strong] = $|STR_SPIKE|STR_ANIM
			p.acceleration = skins[p.skin].acceleration * 2
			me.friction = FU - FU/45
			
			soap.bm.damaging = true
			soap.bm.dmg_props = {
				att = 2,
				def = 2,
				name = "Spinning Top"
			}
			
			SoapST_Hitbox(p)
			if soap.onGround
				local sp = P_SpawnMobjFromMobj(me,0,0,0,MT_SOAP_SPARK)
				sp.color = me.color
				sp.adjust_angle = P_RandomRange(-360,360)*ANG1
				sp.angle = p.drawangle + sp.adjust_angle
				sp.target = me
				
				sp.spritexscale = FU
				sp.spriteyscale = FU * 3/4
				
				if ((leveltime - soap.topsound) % 28 == 0)
					S_StartSoundAtVolume(me,sfx_s3k79, 255/2)
				end
				
				do --if (leveltime & 1)
					local spark = P_SpawnMobjFromMobj(me,0,0,0,MT_SOAP_WALLBUMP)
					local speed = 12*me.scale
					local limit = 28
					local my_ang = FixedAngle(Soap_RandomFixedRange(0,360))
					
					P_InstaThrust(spark, my_ang, speed)
					P_SetObjectMomZ(spark, Soap_RandomFixedRange(3,8))
					
					P_SetScale(spark,me.scale / 10, true)
					spark.destscale = me.scale
					--5 tics
					spark.scalespeed = FixedDiv(me.scale - me.scale / 10, 5*FU)
					spark.color = p.skincolor
					spark.colorized = true
					spark.fuse = TR
					
					spark.spritexscale = FU * 3/2
					spark.spriteyscale = spark.spritexscale
					
					spark.random = P_RandomRange(-limit,limit) * ANG1
				end
			else
				p.pflags = $ &~PF_STARTJUMP
				
				if soap.topairborne
					P_SetObjectMomZ(me, 8*FU)
				end
				
				do
					local angle = me.angle - ANGLE_90
					local mang = FixedAngle(15 * sin(soap.toptics*15*ANG1))
					
					me.roll = FixedMul(mang, sin(angle))
					me.pitch = FixedMul(mang, cos(angle))
				end
			end
			soap.toptics = max($ - 1, 0)
		end
	--ended or interrupted
	elseif soap.topspin ~= false
	or soap.topwindup
		soap.topspin = false
		soap.topsound = -1
		S_StopSoundByID(me,sfx_s3k79)
		S_StopSoundByID(me,sfx_kc4e)
		soap.topwindup = 0
		soap.toptics = 0
		soap.topairborne = false
		me.translation = nil
		
		p.acceleration = skins[p.skin].acceleration
		if me.state == S_PLAY_SOAP_SPTOP
			p.powers[pw_strong] = $ &~STR_SPIKE
			me.state = soap.onGround and S_PLAY_WALK or S_PLAY_FALL
			if not soap.onGround
				p.pflags = $|PF_THOKKED &~PF_JUMPED
			end
		end
	end
	
	if not (p.pflags & PF_JUMPED)
		soap.doublejumped = false
	end
	if soap.linebump
		if soap.onGround
			me.movefactor = tofixed("0.345")
			me.friction = tofixed("0.983")
		end
		soap.linebump = $ - 1
		p.powers[pw_noautobrake] = max($, 1)
	end
	
	if soap.chargedtime
		if (soap.chargedtime/2) & 1
			me.colorized = true
		else
			me.colorized = false
		end
		
		soap.chargedtime = $ - 1
		if soap.chargedtime == 0
			me.colorized = false
		end
	end
	
	--things to do while in pain
	if soap.inPain
		local ticker = leveltime/2
		local painflash = TR/2
		--not in actual hitlag but the "Invert" translation like
		--in wl4 seems a litle too harsh here
		if (soap.paintime < painflash)
			me.translation = (ticker & 1) and (Soap_Hitlag.hitlagTranslation) or nil
			soap.setpaintrans = true
			me.flags2 = $ &~MF2_DONTDRAW
		elseif (soap.paintime == painflash)
			me.translation = nil
			soap.setpaintrans = false
		end
		soap.taunttime = 0
		
		--recovery jump
		if soap.paintime >= TR/2
		and (soap.jump == 1)
		and (soap.notCarried)
		--not in match!
		and not Soap_IsCompGamemode()
			p.pflags = $ &~(PF_JUMPED|PF_THOKKED)
			P_DoJump(p, true)
			me.translation = nil
		end
		soap.afterimage = false
		soap.uppercutted = false
		soap.canuppercut = true
		soap.rdashing = false
		soap.sprung = false
		soap.airdashed = false
		
		soap.paintime = $ + 1
	else
		soap.paintime = 0
		
		if soap.setpaintrans
			me.translation = nil
			soap.setpaintrans = false
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
		
		if accspeed >= spd and drilling then spawn_aura = true; end
		soap.accspeed = accspeed
	elseif p.powers[pw_carry] == CR_BRAKGOOP
		if me.tracer and me.tracer.valid
			me.brakgoop = me.tracer
		end
		local goop = me.tracer
		
		if (goop and goop.valid)
		and goop.state == S_BLACKEGG_GOOP3
			--Mash!! (TODO: finish this)
			if (soap.jump == 1)
				me.state = S_PLAY_SKID
				me.tics = max($, 5)
				Soap_Hitlag.addHitlag(me, 6, true)
				
				goop.tics = max($ - 2, 3)
			end
		end
	elseif p.powers[pw_carry] == CR_MACESPIN
		if me.state ~= S_PLAY_ROLL
			me.state = S_PLAY_ROLL
		end
	elseif p.powers[pw_carry] == CR_NONE
	and not (soap.pounding or (soap.rdashing and not soap.airdashed))
		accelerative_speedlines(p,me,soap, FixedDiv(R_PointTo3DDist(0,0,0,me.momx,me.momy,me.momz),me.scale), 40*FU)
	--kinda annoying how you cant pound when exiting a dust devil
	elseif soap.last.carry == CR_DUSTDEVIL
		soap.sprung = true
	end
	
	--refresh moves (lol)
	if (p.powers[pw_carry] ~= CR_NONE)
		soap.rdashing = false
		soap.airdashed = false
		soap.uppercutted = false
		soap.canuppercut = true
		soap.pounding = false
	end
	
	if spawn_aura and me.health
		local super = (soap.doSuperBuffs or (p.powers[pw_sneakers] > 0)) --sneakers too lol
		--Show when the extra attack point will be applied
		if (soap.inBattle and soap.accspeed >= 45*FU)
			super = true
		end
		if (soap.dashcharge >= SOAP_MAXDASH)
			super = true
		end
		
		if not (soap.fx.dash_aura and soap.fx.dash_aura.valid)
			local follow = P_SpawnMobjFromMobj(me,0,0,0,MT_SOAP_FREEZEGFX)
			follow.tics = -1
			follow.fuse = -1
			follow.tracer = me
			follow.bigwind = true
			follow.state = S_SOAP_NWF_WIND
			follow.sprite = super and SPR_NWF_BOOSTAURA or SPR_NWF_WIND
			follow.alpha = 0
			follow.dontdrawforviewmobj = me
			follow.zcorrect = true
			if super
				follow.blendmode = AST_ADD
			end
			soap.fx.dash_aura = follow
		end
		local aura = soap.fx.dash_aura
		
		if (p.powers[pw_shield] & SH_NOSTACK) == SH_FLAMEAURA
			P_SetMobjStateNF(aura,S_SOAP_NWF_WIND)
			if aura.sprite ~= SPR_FIRS
				aura.frame = A
				aura.sprite = SPR_FIRS
				aura.frame = 18 | FF_FULLBRIGHT
			end
			if (leveltime & 1)
				aura.flags2 = $|MF2_DONTDRAW
			else
				aura.flags2 = $ &~MF2_DONTDRAW
			end
		else
			aura.flags2 = $ &~MF2_DONTDRAW
		end
		
		local speedup_frame = false
		if (soap.accspeed > 56*FU)
			speedup_frame = P_RandomChance(
				min(FixedDiv(5*FU, soap.accspeed - 56*FU), FU)
			)
			if (soap.accspeed > 52*FU) then speedup_frame = true end
		end
		if speedup_frame
		and (aura.state ~= S_SOAP_NWF_WIND_FAST and aura.tics >= states[S_SOAP_NWF_WIND].tics - 2)
		and (p.powers[pw_shield] & SH_NOSTACK) ~= SH_FLAMEAURA
			aura.state = S_SOAP_NWF_WIND_FAST
		end
		
		local dist = 20*me.scale
		if (p.powers[pw_carry] == CR_NIGHTSMODE)
			dist = 0
			aura.rollangle = me.rollangle
		else
			aura.rollangle = 0
		end
		aura.dist = dist
		aura.boostaura = super
		
		aura.alpha = FixedCeil(ease.linear(FU/5, $, FU) * 100)/100		
	else
		if (soap.fx.dash_aura and soap.fx.dash_aura.valid)
			local super = (soap.doSuperBuffs or (p.powers[pw_sneakers] > 0)) --sneakers too lol
			local aura = soap.fx.dash_aura
			
			local dist = 20*me.scale
			if (p.powers[pw_carry] == CR_NIGHTSMODE)
				dist = 0
				aura.rollangle = me.rollangle
			else
				aura.rollangle = 0
			end
			aura.dist = dist
			aura.boostaura = super
			
			if (p.powers[pw_shield] & SH_NOSTACK) == SH_FLAMEAURA
				P_SetMobjStateNF(aura,SPR_NWF_WIND)
				if aura.sprite ~= SPR_FIRS
					aura.frame = A
					aura.sprite = SPR_FIRS
					aura.frame = 18 | FF_FULLBRIGHT
				end
				if (leveltime & 1)
					aura.flags2 = $|MF2_DONTDRAW
				else
					aura.flags2 = $ &~MF2_DONTDRAW
				end
			else
				aura.flags2 = $ &~MF2_DONTDRAW
			end
			
			aura.alpha = FixedFloor(ease.linear(FU/5, $, 0) * 100)/100
			if soap.fx.dash_aura.alpha == 0
				P_RemoveMobj(soap.fx.dash_aura)
				soap.fx.dash_aura = nil
			end
		end	
	end
	
	--since we can be sure we arent modifying runspeed
	--at this point, we can reverse the multiplication
	--the game does for animations
	if soap.doSuperBuffs
	and (p.runspeed ~= skins[p.skin].runspeed)
		--plus 0.10 for a litle leeway
		p.runspeed = FixedDiv($, (5*FU/3) + FU/10)
	end
	
	Soap_VFX(p,me,soap, {
		was_pounding = was_pounding,
		squishme = squishme,
	})
	
	--handle battlemod
	if soap.bm.intangible
		soap.bm.intangible = $ - 1
		p.intangible = true
		if soap.bm.intangible == 0
			if (p.airdodge ~= nil)
			and p.airdodge <= 0
				p.intangible = false
			end
		end
	end
	
	if (p.pflags & (PF_JUMPED|PF_THOKKED) == PF_JUMPED)
	and (me.state == S_PLAY_JUMP or me.state == S_PLAY_SPRING)
		soap.jumptime = $+1
	else
		soap.jumptime = 0
	end
	
	if Cosmetics
		Cosmetics.SkinOffsets[SOAP_SKIN] = cos_height
	end
	
	Soap_DeathThinker(p,me,soap)
	Soap_SolThinker(p,me,soap)
	
	me.nohitlagforme = (p.powers[pw_invulnerability] > 0)
end)

addHook("PlayerSpawn",function(p)
	local soap = p.soaptable
	if not soap then return end
	local me = p.mo
	
	--reset any dangling variables
	soap.doublejumped = false 
	soap.sprung = false
	soap.jumptime = 0
	soap.rmomz = 0
	soap.slipping = false
	
	soap.pounding = false
	
	soap.canuppercut = true
	soap.uppercutted = false
	soap.uppercut_cooldown = 0
	
	soap.rdashing = false
	soap.airdashed = false
	
	soap.toptics = 0
	if soap.topwindup
		soap.topwindup = 0
		me.translation = nil
	end
	
	soap.deathtype = 0
end)

addHook("PlayerCanDamage",function(p, targ)
	if not p.soaptable then return end
	
	if not (p.mo and p.mo.valid) then return end
	
	if p.mo.skin ~= SOAP_SKIN then return end
	
	local soap = p.soaptable
	local me = p.mo
	
	if (soap.rdashing
	and p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash)
	or (soap.airdashed)
		if (targ.flags & (MF_MONITOR))
		or targ.type == MT_TNTBARREL
			return true
		end
	end
end)

addHook("PlayerHeight",function(p)
	if not (p and p.valid) then return end
	
	local me = p.realmo
	local soap = p.soaptable
	
	if not (me and me.valid) then return end
	if me.skin ~= SOAP_SKIN then return end
	if not soap then return end
	
	if (p.pflags & PF_THOKKED)
	and (me.sprite2 == SPR2_MLEE)
		return P_GetPlayerHeight(p)
	end
	
	if soap.crouching
		return P_GetPlayerSpinHeight(p)
	end
end)

addHook("PlayerSpawn",function(p)
	if not (p and p.valid) then return end
	
	local me = p.realmo
	local soap = p.soaptable
	
	if not (me and me.valid) then return end
	if not soap then return end
	
	soap.last.onground = P_IsObjectOnGround(me)
end)

addHook("PlayerCanEnterSpinGaps",function(p)
	if not (p and p.valid) then return end
	if not (p.soaptable) then return end
	
	if not (p.mo and p.mo.valid) then return end
	
	local me = p.mo
	local soap = p.soaptable
	
	if me.skin == SOAP_SKIN
		local phigh = me.height
		
		/*
		if takis.crushtime
			local high = P_GetPlayerHeight(p)
			if p.pflags & PF_SPINNING
				high = P_GetPlayerSpinHeight(p)
			end
			phigh = FixedMul(high,FixedDiv(takis.spriteyscale,FU))
		end
		if ((takis.transfo & TRANSFO_TORNADO)
		and not (takis.nadocrash))
		or (me.state == S_PLAY_TAKIS_SLIDE)
			phigh = P_GetPlayerSpinHeight(p)
		end
		*/
		
		if phigh <= P_GetPlayerSpinHeight(p)
			return true
		end
	end
end)

--use an extremely obscure mt_* so the mobjthinker destructor
--doesnt use more resources than necessary
local peelout_mobj = MT_TFOG
local peels = 9

addHook("FollowMobj",function(p, m_peel)
	if m_peel.outs == nil then m_peel.outs = {} end
	
	local me = p.mo
	local soap = p.soaptable
	
	if (me.flags & MF_NOTHINK) then return true; end
	
	m_peel.max_outs = peels
	
	if me.state ~= S_PLAY_DASH
	--and false
		if #m_peel.outs
			for i = -m_peel.max_outs, m_peel.max_outs
				local peel = m_peel.outs[i]
				if not (peel and peel.valid) then continue end
				
				P_RemoveMobj(peel)
				m_peel.outs[i] = nil
			end
		end
		
		return
	end
	
	local angle = soap.dashangle - FixedAngle(soap.uppercut_spin)
	local off = ANG20
	
	local radius = -FixedMul(me.radius*3/2, me.spritexscale)
	local forward = {
		x = P_ReturnThrustX(nil,angle, -radius*3/2),
		y = P_ReturnThrustY(nil,angle, -radius*3/2),
	}
	local side = 0
	
	for i = -peels, peels
		if i == 0
			side = 0
			continue
		end
		local sign = i < 0 and -1 or 1
		
		local func = P_MoveOrigin
		if m_peel.outs[i] == nil
		or not (m_peel.outs[i] and m_peel.outs[i].valid)
			local peel = P_SpawnMobjFromMobj(me,0,0,0,peelout_mobj)
			peel.tics = -1
			peel.fuse = -1
			peel.dontdrawforviewmobj = me
			peel.flags = $|MF_NOCLIPHEIGHT|MF_NOCLIPTHING
			
			peel.sprite = SPR_PEEL
			peel.frame = A|FF_PAPERSPRITE
			
			peel.spritexscale = FU/2
			peel.spriteyscale = peel.spritexscale
			peel.spritexoffset = 0
			
			peel.height = 5*FU
			peel.radius = 5*FU
			peel.tracer = m_peel
			
			m_peel.outs[i] = peel
			func = P_SetOrigin
		end
		local peel = m_peel.outs[i]
		if not (peel and peel.valid) then continue end
		
		local side_x = P_ReturnThrustX(nil,angle + ANGLE_90*sign, side)
		local side_y = P_ReturnThrustY(nil,angle + ANGLE_90*sign, side)
		
		func(peel,
			me.x + P_ReturnThrustX(nil,angle + off*sign, radius) + forward.x + side_x,
			me.y + P_ReturnThrustY(nil,angle + off*sign, radius) + forward.y + side_y,
			me.z
		)
		local this_z = me.z
		if P_IsObjectOnGround(me)
		and (me.standingslope)
			this_z = P_GetZAt(me.standingslope, peel.x,peel.y,me.z)
			if P_MobjFlip(me) == -1
				this_z = $ - peel.height - me.height
			end
		end
		peel.z = this_z
		
		if (P_MobjFlip(me) == -1)
			peel.z = ($ + me.height) - peel.height
			peel.eflags = $|MFE_VERTICALFLIP
		else
			peel.eflags = $ &~MFE_VERTICALFLIP
		end
		
		local frame = (me.frame & FF_FRAMEMASK) % E
		if sign == -1
			--this is Cool.
			if frame == A
				frame = C
			elseif frame == B
				frame = D
			elseif frame == C
				frame = A
			elseif frame == D
				frame = B
			end
		end
		
		peel.angle = angle + off*sign
		peel.frame = ($ &~FF_FRAMEMASK)|frame
		peel.renderflags = $|RF_PAPERSPRITE
		peel.destscale = me.scale
		peel.scalespeed = peel.destscale + 1
		peel.flags2 = ($ &~MF2_DONTDRAW)|(me.flags2 & MF2_DONTDRAW)
		peel.color = me.color
		peel.colorized = me.colorized
		peel.spritexscale = FixedDiv(me.spritexscale, 2*FU)
		peel.spriteyscale = FixedDiv(me.spriteyscale, 2*FU)
		peel.pitch,peel.roll = 0,0
		peel.translation = me.translation
		
		local pitchroll = 0
		local pitch = me.pitch
		local roll = me.roll
		--we're boring and dont have pitch/roll-tation
		if not takis_custombuild
			if (me.standingslope)
				local slope = me.standingslope
				local nz = slope.normal.z
				local ny = slope.normal.y
				local nx = slope.normal.x
				
				pitch = R_PointToAngle2(0,0, FixedSqrt(
					FixedMul(ny,ny) + FixedMul(nz,nz)), nx
				)
				roll = R_PointToAngle2(0,0, nz, ny)
			end
		end
		do
			local r_angle = p.drawangle + ANGLE_90
			
			pitchroll = FixedMul(pitch,-sin(r_angle)) + FixedMul(roll,cos(r_angle))
		end
		
		peel.rollangle = me.rollangle + pitchroll
		
		side = $ - me.scale/2
	end
end,MT_SOAP_PEELOUT)

--remove dereferenced peelouts
addHook("MobjThinker",function(peel)
	if not (peel and peel.valid) then return end
	if peel.sprite ~= SPR_PEEL then return end
	if not (peel.tracer and peel.tracer.valid)
		P_RemoveMobj(peel)
	end
end,peelout_mobj)

--pvp
--shitty battlemod
-- fucking stupid cocksucking motherfucking BattleMod
addHook("PlayerCanDamage",function(p)
	local me = p.mo
	if not (me and me.valid) then return end
	if (me.skin ~= SOAP_SKIN) then return end
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

----grab thinker		
addHook("PlayerThink",function(p)
	if not (p and p.valid) then return end
	if not p.soaptable then return end
	if not (p.mo and p.mo.valid) then return end
	
	local me = p.mo
	local soap = p.soaptable
	
	--lol
	if (me.skin ~= SOAP_SKIN)
		--free the other guy
		if (me.punchtarget and me.punchtarget.valid)
			Soap_GrabFree(me, me.punchtarget)
		end
	--only soaps can grab other people
	else
		Soap_Grabbing(p,me,soap)
	end
	if me.soap_grabcooldown then me.soap_grabcooldown = $ - 1; end
	
	if (me.punchsource and me.punchsource.valid)
		Soap_Grabbed(p,me,soap)
	end
end)
----

local function Soap_Bump(me,thing,line, weak)
	local p = me.player
	local soap = p.soaptable

	Soap_StartQuake(5*FU, 8, {me.x,me.y,me.z}, 512*me.scale)
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
		
		--its ambiguous syntax to have the `func` definition on the same line
		--as the call, so :shrug:
		--C DOESNT COMPLAIN....
		local func = ((soap.onGround or weak) and P_Thrust or P_InstaThrust)
		func(me,
			line_ang - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1),
			-speed
		)
		p.rmomx = me.momx - p.cmomx
		p.rmomy = me.momy - p.cmomy
		
		if me.health
			soap.linebump = max($, 12)
		end
		if soap.in2D
			me.momy = 0
		end
		return true
	elseif (thing and thing.valid)
		local ang = R_PointToAngle2(me.x,me.y, thing.x,thing.y)
		local speed = R_PointToDist2(0,0,thing.momx,thing.momy) + (R_PointToDist2(0,0,me.momx,me.momy)/2) + FixedMul(
			20*FU, FixedSqrt(FixedMul(thing.scale,me.scale))
		)
		if soap.onGround then speed = FixedDiv($, me.friction) end
		
		P_InstaThrust(me, ang, -speed)
		p.rmomx = me.momx - p.cmomx
		p.rmomy = me.momy - p.cmomy
		
		if soap.in2D
			me.momy = 0
		end
		if me.health
			soap.linebump = max($, 12)
		end
		return true
	end
	P_BounceMove(me)
	return true
end

Takis_Hook.addHook("MoveBlocked",function(me,thing,line, goingup)
	local p = me.player
	local soap = p.soaptable
	
	if me.skin ~= SOAP_SKIN then return end
	if goingup then return end
	
	if not (me.health)
	and not (p.spectator or p.playerstate ~= PST_DEAD)
		Soap_Bump(me,thing,line)
		return
	end
	
	if not (me.state == S_PLAY_DASH or me.state == S_PLAY_FLOAT_RUN) then return end
	
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
		
		return Soap_Bump(me,thing,line, true)
	end
end)

local function canBumpAtAll(p)
	local me = p.realmo
	local soap = p.soaptable

	if (soap.rdashing)
	and min(soap.accspeed, p.normalspeed) < skins[p.skin].normalspeed + soap._maxdash
	and (me.state == S_PLAY_RUN)
		return true
	end
	return false
end

local function handleBump(p,me,thing)
	local soap = p.soaptable
	if (soap.doSuperBuffs or p.powers[pw_invulnerability]) then return end
	if soap.nodamageforme > 2 then soap.nodamageforme = 10; return end
	
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
			thing.z = $ + thing.scale*P_MobjFlip(thing)
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
	
	soap.nodamageforme = 10
	p.powers[pw_nocontrol] = soap.nodamageforme
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
	return true
end

local function try_pound_bounce(me,thing)
	local p = me.player
	local soap = p.soaptable
	
	local sh = p.powers[pw_shield] & SH_NOSTACK
	if sh ~= SH_ELEMENTAL then return end
	if not soap.jump then return end
	
	P_SetObjectMomZ(me, -FixedMul(me.momz, soap_pound_factor))
	P_ElementalFire(p, true)
end

local function try_pvp_collide(me,thing)
	if not (me and me.valid) then return end
	if not (thing and thing.valid) then return end
	if (thing.flags & MF_MISSILE) then return end
	
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
	if me.skin ~= SOAP_SKIN then return end
	
	local DealDamage = (soap.doSuperBuffs or p.powers[pw_invulnerability]) and P_KillMobj or P_DamageMobj
	
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
				Soap_StartQuake(power*2, hitlag_tics,
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
				try_pound_bounce(me,thing)
				return
			end
			
			--hit by uppercut
			if soap.uppercutted
			and (me.momz*soap.gravflip > 0)
			and (me.sprite2 == SPR2_MLEE)
				Soap_ImpactVFX(thing,me)
				soap.uppercut_spin = soap_baseuppercutturn
				soap.canuppercut = true
				
				local power = 5*FU + FixedDiv(me.momz,me.scale)
				Soap_DamageSfx(thing, power, 35*FU)
				
				local hitlag_tics = 10 + (power/FU / 5)
				Soap_StartQuake(power*2, hitlag_tics,
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
			if canBumpAtAll(p)
				if handleBump(p,me,thing)
					return false
				end
				return
			end
			
			--hit by r-dash / b-rush
			if (soap.rdashing and p.normalspeed >= skins[p.skin].normalspeed + soap._maxdash)
			or (soap.airdashed and me.state == S_PLAY_FLOAT_RUN)
				Soap_ImpactVFX(thing,me)
				
				local power = FixedMul(10*FU + max(soap.accspeed - 20*FU,0), me.scale)
				Soap_DamageSfx(thing, power, 60*FU)
				
				local hitlag_tics = 4 + (power/FU / 10)
				Soap_StartQuake(power/2, hitlag_tics,
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
	
	if not (soap2) then return end
	if soap2.iwashitthistic then return end
	if not Soap_CanHurtPlayer(p, p2, battlepass) then return end
	soap2.iwashitthistic = true
	
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
		Soap_StartQuake(power*2, hitlag_tics,
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
		try_pound_bounce(me,thing)
		return
	end
	
	--hit by uppercut
	if soap.uppercutted
	and (me.momz*soap.gravflip > 0)
	and (me.momz*soap.gravflip) > (thing.momz * P_MobjFlip(thing))
	and (me.sprite2 == SPR2_MLEE)
		P_DamageMobj(thing, me,me, 40)
		soap.uppercut_spin = soap_baseuppercutturn
		soap.canuppercut = true
		
		local power = 5*FU + FixedDiv(me.momz,me.scale)
		Soap_ZLaunch(thing, power)
		Soap_DamageSfx(thing, power, 35*FU)
		
		local hitlag_tics = 15 + (power/FU / 3)
		Soap_StartQuake(power*2, hitlag_tics,
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
	if canBumpAtAll(p)
		if handleBump(p,me,thing)
			return false
		end
		return
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
		Soap_StartQuake(power/2, hitlag_tics,
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
	if skins[p.skin].name ~= SOAP_SKIN then return end
	if not (p and p.valid) then return end
	if not (p.soaptable) then return end
	if (me.hitlag) then return end
	if not (inf and inf.valid or src and src.valid) then return end
	if inf.flags & MF_MISSILE then return end
	
	local soap = p.soaptable
	
	if (leveltime == soap.trydamageframe) then return end
	soap.trydamageframe = leveltime
	
	local canbump = false
	if canBumpAtAll(p)
	and (inf and inf.valid or src and src.valid)
	and Soap_CanDamageEnemy(p,inf or src)
		soap.nodamageforme = 10
		canbump = true
	end
	
	if soap.nodamageforme
	and (inf and inf.valid or src and src.valid)
	or canbump
		return false
	end
end,MT_PLAYER)

addHook("AbilitySpecial",function(p)
	local me = p.mo
	if not (me and me.valid) then return end
	
	if me.skin ~= SOAP_SKIN then return end
	if (me.eflags & MFE_SPRUNG) or p.powers[pw_justsprung] >= 4 then return end
	
	p.soaptable.doublejumped = true
end)

--various effects
--handle soap damage
addHook("MobjDamage", function(me,inf,sor,dmg,dmgt)
	if not (me and me.valid) then return end
	if me.skin ~= SOAP_SKIN then return end
	
	local p = me.player 
	local soap = p.soaptable
	
	if (soap.hurtframe == leveltime) then return; end
	soap.hurtframe = leveltime
	
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
			
			P_Thrust(me, 
				R_PointToAngle2(inf.x,inf.y,
					me.x,me.y
				),
				inf_speed
			)
		else
			S_StartSound(me,sfx_sp_db0)
		end
		
		Soap_ImpactVFX(me, inf)
		if Soap_IsLocalPlayer(p)
			Soap_StartQuake((20 + p.timeshit*3/2)*FU, 16 + 16*(p.losstime / (10*TR)),
				nil,
				512*me.scale
			)
		end
		
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
	if me.skin ~= SOAP_SKIN then return end
	if not (me.player and me.player.valid) then return end
	
	local p = me.player
	local soap = p.soaptable
	
	--??? sometimes bumping certain enemies just kills you
	--inexplicably, so detect when it happens and prevent it
	/*
	if not ((inf and inf.valid) or (src and src.valid))
		if (soap.nodamageforme >= 7)
		or canBumpAtAll(p)
			--and it STILL KILLS YOU FUCKIN WHYYYYYY
			soap.nodamageforme = 10
			return true
		end
	end
	*/
	
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
		
		me.z = $ + FU*soap.gravflip
		local power = FixedHypot(FixedHypot(killer.momx,killer.momy),killer.momz)
		P_InstaThrust(me, R_PointToAngle2(killer.x,killer.y,me.x,me.y), power)
		P_SetObjectMomZ(me, 12*FU)
		
		me.soap_knockout = true
		me.soap_knockout_speed = {
			me.momx,me.momy,me.momz
		}
		
		p.drawangle = R_PointToAngle2(me.x,me.y,killer.x,killer.y)
		soap.deathtype = 0
	end
end)

--jump effect
addHook("JumpSpecial", function(p)
	if p.mo.skin ~= SOAP_SKIN then return end
	
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
		
		Soap_RemoveSquash(p, "landeffect")
		me.soap_jumpdust = 4
		me.soap_jumpeffect = nil
	end
end)

local crouch_lerp = 0
Takis_Hook.addHook("PostThinkFrame",function(p)
	local me = p.realmo
	local soap = p.soaptable
	
	soap.damagedealtthistic = 0
	soap.iwashitthistic = false
	if me.skin ~= SOAP_SKIN then return end
	
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
	
	if me.state == S_PLAY_DASH
		p.drawangle = R_PointToAngle2(0,0,me.momx,me.momy) --soap.dashangle
	end
	
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
		or (Soap_BouncyCheck(p))
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
	if (Soap_BouncyCheck(p))
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
			
			local grav_mul = abs(FixedDiv(P_GetMobjGravity(me),me.scale/2))
			soap.uppercut_spin = P_AngleLerp(
				FixedMul(FU/7, grav_mul),
				$, 0
			)
			
			if FixedFloor(soap.uppercut_spin) < FixedDiv(10*FU,grav_mul)
				soap.uppercut_spin = 0
			end
			
			if (leveltime & 1)
			and (p.powers[pw_shield] & SH_NOSTACK == SH_WHIRLWIND)
				local rad = FixedDiv(me.radius,me.scale) + 16*FU
				local hei = FixedDiv(me.height,me.scale)
				for i = -1,1,2
					local ang = p.drawangle + ANGLE_90*i
					local dust = P_SpawnMobjFromMobj(me,
						P_ReturnThrustX(nil,ang,rad),
						P_ReturnThrustY(nil,ang,rad),
						hei/2,
						MT_SPINDUST
					)
					P_Thrust(dust, R_PointToAngle2(dust.x,dust.y,me.x,me.y), -5*me.scale)
					dust.momx = $ + me.momx
					dust.momy = $ + me.momy
					dust.momz = me.momz * 3/4
					dust.destscale = dust.scale * 3/2
					dust.scalespeed = FixedDiv(dust.destscale - dust.scale, dust.tics*FU)
				end
			end
		end
	end
	if soap.topspin ~= false
		p.drawangle = me.angle - FixedAngle(soap.topspin)
	end
end)
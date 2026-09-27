local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local armacolors = {
	SKINCOLOR_KETCHUP, SKINCOLOR_PEPPER, SKINCOLOR_CRIMSON, SKINCOLOR_GARNET, SKINCOLOR_VOLCANIC
}

local PHASE_SEARCH = 0
local PHASE_SETUP = 1
local PHASE_WRESTLE = 2

local MAXGOTIME = TR*3/5 + 4
local gotime = 0

local MAXREADYTIME = TR * 3/2
local readytime = 0

local tauntinfo = {}

tauntinfo.name = "Arm Wrestle"
tauntinfo.cancelable = false

tauntinfo.run = function(p, me, soap, taunt)
	me.state = S_PLAY_SOAP_FLEX
	me.tics = -1
	
	me.tempangle = p.drawangle
	me.soap_arms = {
		phase = PHASE_SEARCH,
		phasetics = -1,
		nextphase = -1,
		
		partner = nil,
		progress = 0, -- [0,100]
		activity = 0,
	}
	
	soap.stasistic = max($, 2)
	taunt.tics = 2
	
	me.momx,me.momy = p.cmomx,p.cmomy
end

local function ResetTaunt(p)
	if not (p and p.valid) then return end
	local me = p.mo
	local soap = p.soaptable
	local taunt = soap.taunt
	if not (me and me.valid) then return end
	
	p.camerascale = FU
	me.tempangle = nil
	me.soap_arms = nil
	if (not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)) and me.health
		me.state = S_PLAY_WALK
		P_MovePlayer(p)
		Soap_ResetState(p)
	end
	soap.stasistic, taunt.tics = 0,0
end

local function SetPhase(p, arms, newstate, tics, nextstate)
	arms.phase = newstate
	arms.phasetics = tics
	if nextstate ~= nil and nextstate > -1
		arms.nextphase = nextstate
		
		-- lol
		if newstate == PHASE_SETUP and (p == displayplayer)
			readytime = MAXREADYTIME
		end
	end
end

local function GetMoveDistance(me, omo)
	return (me.radius + omo.radius) * 3/2
end

local function SearchPhase(p,me,soap,taunt,arms)
	local candidates = {}
	local counted = 0
	for play in players.iterate
		if (play == p) then continue end
		local mo = play.mo
		if not (mo and mo.valid and mo.health) then continue end
		if (play.spectator) then continue end
		if not (mo.skin == SOAP_SKIN or mo.skin == TAKIS_SKIN) then continue end
		if not (mo.soap_arms) then continue end
		if (mo.soap_arms.phase ~= PHASE_SEARCH) then continue end
		
		if not P_CheckSight(me, mo) then continue end
		-- also gotta be level with them
		if (P_MobjFlip(me) ~= P_MobjFlip(mo)) then continue end
		if abs(me.floorz - mo.floorz) > 12*FU then continue end
		
		local dist = R_PointToDist2(me.x,me.y, mo.x,mo.y)
		if dist > 128*FU then continue end
		
		table.insert(candidates, {play = play, dist = dist})
		counted = $ + 1
	end
	if not counted then return end
	
	local closestdist = INT32_MAX
	local closestplayer = nil
	for k, info in ipairs(candidates)
		local play = info.play
		local dist = info.dist
		if dist < closestdist
			closestdist = dist
			closestplayer = play
		end
	end
	if closestplayer == nil then return end
	
	local cmo = closestplayer.mo
	local ang = R_PointToAngle2(me.x,me.y, cmo.x,cmo.y)
	
	me.tempangle = ang
	arms.partner = closestplayer
	
	cmo.soap_arms.partner = p
	cmo.tempangle = ang + ANGLE_180
	
	-- try to move them
	local dist = GetMoveDistance(me, cmo)
	if not P_TryMove(cmo,
		me.x + P_ReturnThrustX(ang, dist),
		me.y + P_ReturnThrustY(ang, dist),
		false
	) then
		ResetTaunt(p)
		return false
	end
	
	local tics = 2*TR + TR/2
	SetPhase(p, arms, PHASE_SETUP, tics, PHASE_WRESTLE)
	SetPhase(closestplayer, cmo.soap_arms, PHASE_SETUP, tics, PHASE_WRESTLE)
	S_StartSound(nil, sfx_sp_awr, p)
	S_StartSound(nil, sfx_sp_awr, closestplayer)
	return true
end

local function CheckPartner(p,me,soap,taunt,arms)
	local play = arms.partner
	if not (play and play.valid)
		return false
	end
	local omo = play.mo -- othermo
	if not (omo and omo.valid and omo.health)
		return false
	end
	local arms2 = omo.soap_arms
	if not (arms2 and arms2.partner == p)
		return false
	end
	if not (omo.skin == SOAP_SKIN or omo.skin == TAKIS_SKIN)
		return false
	end
	return true
end

local function SetupPhase(p,me,soap,taunt,arms)
	if not CheckPartner(p,me,soap,taunt,arms)
		ResetTaunt(p)
		return
	end
	
	local play = arms.partner
	local omo = play.mo -- othermo
	local arms2 = omo.soap_arms
	
	if me.state ~= S_PLAY_SOAP_FLEX
		me.state = S_PLAY_SOAP_FLEX
		me.tics = -1
	end
	
	p.aiming = 0
	me.angle = me.tempangle + ANGLE_90
	p.camerascale = P_Lerp(FU/2, $, FU * 3/2)
	
	if arms.phasetics == 4
		S_StartSound(nil, sfx_sp_awg, p)
		if p == displayplayer
			gotime = MAXGOTIME
		end
	end
end

local function spawn_sweat_mobjs(p,me,soap)
	if soap.inWater then return end
	
	local height = FixedDiv(me.height,me.scale)/FU
	local sweat = P_SpawnMobjFromMobj(me,
		P_RandomRange(-16,16)*FU, --+ FixedDiv(me.momx,me.scale),
		P_RandomRange(-16,16)*FU, --+ FixedDiv(me.momy,me.scale),
		P_RandomRange(height/2,height)*FU,
		MT_SOAP_WALLBUMP
	)
	P_Thrust(sweat, 
		me.tempangle + FixedAngle(Soap_RandomFixedRange(-45*FU,45*FU)),
		-FixedMul(Soap_RandomFixedRange(2*FU,5*FU), me.scale)
	)
	sweat.momx = $ + me.momx/2
	sweat.momy = $ + me.momy/2
	sweat.momz = $ + soap.rmomz
	P_SetObjectMomZ(sweat, Soap_RandomFixedRange(5*FU,8*FU))
	sweat.fuse = TR*3/4
	sweat.dontdrawforviewmobj = me
	sweat.frame = B|FF_TRANS30
	sweat.colorized = false
	sweat.sweat = true
	return sweat
end

local function WrestlePhase(p,me,soap,taunt,arms)
	if not CheckPartner(p,me,soap,taunt,arms)
		ResetTaunt(p)
		ResetTaunt(play)
		return
	end
	
	local play = arms.partner
	local omo = play.mo -- othermo
	local arms2 = omo.soap_arms
	
	if me.state ~= S_PLAY_SOAP_FLEX
		me.state = S_PLAY_SOAP_FLEX
		me.tics = -1
	end
	
	local dist = GetMoveDistance(me, omo)
	if not P_TryMove(omo,
		me.x + P_ReturnThrustX(me.tempangle, dist),
		me.y + P_ReturnThrustY(me.tempangle, dist),
		false
	) then
		ResetTaunt(p)
		ResetTaunt(play)
		return
	end
	
	p.aiming = 0
	me.angle = me.tempangle + ANGLE_90
	p.camerascale = P_Lerp(FU/2, $, FU * 3/2)
	
	local increase = FU * 5/2
	if arms.activity
		arms.activity = $ - 1
	else
		arms.progress = max($ - increase/3, 0)
	end
	if arms.lockout then arms.lockout = $ - 1; end
	
	if soap.jump == 1 and not arms.lockout
		arms.progress = $ + increase
		arms.lockout = 1
		
		Soap_SquashMacro(p, {
			ease_func = "inexpo",
			ease_time = 3,
			x = FU * 1/5,
			y = FU/6,
			singular = true
		})
		
		if arms.progress < arms2.progress
			local diff = (arms2.progress - arms.progress) / max(arms.activity, 1)
			arms2.progress = max($ - diff, 0)
		end
		local activ = 1 + (100*FU - arms.progress) / FU / 12
		arms.activity = max($, max(activ, 3))
		arms2.activity = $ + 2
	end
	if (arms2.progress >= 70*FU)
		if leveltime % 2 == 0
			spawn_sweat_mobjs(p,me,soap)
		end
		if not S_SoundPlaying(me, sfx_pudpud)
			S_StartSound(me, sfx_pudpud)
		end
		local scale = skins[p.skin].highresscale
		if edit_custombuild
			scale = FU
		end
		me.spritexoffset = FixedDiv(FU, scale) * (leveltime % 2 and 1 or -1)
	else
		S_StopSoundByID(me, sfx_pudpud)
		me.spritexoffset = 0
	end
	
	-- tap out
	if (soap.c1)
		if soap.c1 == TR * 3/2
			arms2.progress = 110*FU
		end
		
		if not S_SoundPlaying(me, sfx_sp_dtn)
			S_StartSound(me,sfx_sp_dtn, p)
		end
	else
		S_StopSoundByID(me, sfx_sp_dtn)
	end
	
	if arms.progress >= 100*FU
		local tempangle = me.tempangle
		ResetTaunt(p)
		ResetTaunt(play)
		-- arms is no longer safe to access
		
		S_StopSoundByID(me, sfx_sp_dtn)
		S_StopSoundByID(omo, sfx_sp_dtn)
		
		soap.stasistic = TR
		play.soaptable.stasistic = TR
		
		-- spike!
		local halftic = 10
		Soap_DamageSfx(omo, FU*3/4,FU)
		S_StartSound(omo,sfx_sp_dm4)
		S_StartSound(me,sfx_sp_kco)
		
		local work = FU * 3/4
		repeat
			Soap_ImpactVFX(omo,me, FU + work*7, FU + work/2,nil,nil,vfxdmgt)
			work = $ - FU/4
		until (work <= 0)
		
		local rad = FixedDiv(omo.radius, omo.scale)
		local hei = FixedDiv(omo.height, omo.scale)
		local extra = abs(FixedDiv(omo.momz, 50*omo.scale))
		for i = 0, 32
			local s = P_SpawnMobjFromMobj(omo,
				Soap_RandomFixedRange(-rad, rad),
				Soap_RandomFixedRange(-rad, rad),
				Soap_RandomFixedRange(0, hei) + 256*FU,
				MT_PARTICLE
			)
			s.state = S_SOAP_IMPACT_LINE2
			if (soap.in2D)
				s.angle = 0
			else
				s.angle = omo.angle - ANGLE_90
			end
			s.color = armacolors[P_RandomRange(1, #armacolors)]
			s.rollangle = -ANGLE_90
			s.renderflags = $|RF_ALWAYSONTOP
			s.spriteyscale = $ * 3/2 + extra
			s.flags = $|MF_NOCLIPTHING|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP
			s.takis_flingme = false
			local offset = P_RandomRange(-4, 8)
			s.tics = $ + halftic + offset
			s.anim_duration = $ + halftic + offset
		end
		
		S_StartSound(me, sfx_sp_bsl)
		me.state = S_PLAY_SOAP_PUNCH1
		
		omo.state = S_PLAY_DEAD
		omo.frame = A|($ &~FF_FRAMEMASK)
		omo.sprite2 = SPR2_MSC2
		omo.tics = -1
		omo.soap_inf = me
		
		omo.z = $ + P_MobjFlip(omo)*FU
		Soap_ZLaunch(omo, 20*me.scale)
		P_Thrust(omo, tempangle, 7*me.scale)
		omo.soap_damagevar = {
			ang = tempangle,
			momz = 20 * me.scale,
			speed = 7 * me.scale,
			threshold = 7 * me.scale
		}
		soap.hud.painsurge = 6
		play.soaptable.hud.painsurge = 6
		
		Soap_Hitlag.addHitlag(me, 15, false)
		Soap_Hitlag.addHitlag(omo, 15, true)
	end
end

tauntinfo.think = function(p, me, soap, taunt)
	local arms = me.soap_arms
	if (me.tempangle == nil or arms == nil)
	or (SoapTaunt_CancelWhen(p,nil, true) and arms.phase == PHASE_SEARCH)
	or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
		ResetTaunt(p)
		return
	end
	
	soap.stasistic = max($, 2)
	taunt.tics = 2
	
	p.drawangle = me.tempangle
	soap.noability = SNOABIL_ALL
	
	if (arms.phasetics ~= -1)
		arms.phasetics = $ - 1
		if arms.phasetics == 0
			arms.phase = arms.nextphase
		end
	end
	
	if arms.phase == PHASE_SEARCH
		local result = SearchPhase(p,me,soap,taunt,arms)
		if result == false -- failed
			ResetTaunt(p)
			return
		end
	elseif arms.phase == PHASE_SETUP
		SetupPhase(p,me,soap,taunt,arms)
	elseif arms.phase == PHASE_WRESTLE
		WrestlePhase(p,me,soap,taunt,arms)
	end
end
tauntinfo.postthink = function(p, me, soap, taunt)
	if me.tempangle == nil then return end
	p.drawangle = me.tempangle
end
tauntinfo.canceled = function(p,me,soap)
	me.soap_arms = nil
	me.spritexoffset = 0
end
tauntinfo.drawer = function(v,i, x,y, selected, scale)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_MSC4,
		frame = A, angle = 2
	}, selected, scale)
end

addHook("HUD",function(v,p, cam)
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local me = p.realmo
	
	if readytime > 0
		local alpha = 0
		local mystr = "Ready..?"
		local strlen = 8
		local ticker = (MAXREADYTIME - readytime) * 4/5
		local newstr = string.sub(mystr, 1, min(ticker, strlen))
		
		if readytime < 10
			alpha = (10 - readytime) << V_ALPHASHIFT
		end
		v.drawString(
			160 - v.stringWidth(mystr, 0, "thin")/2,
			80, newstr, V_ALLOWLOWERCASE|alpha, "thin"
		)
		
		readytime = $ - 1
	end
	if gotime > 0
		v.dointerp(true)
		local scale = FU
		local alpha = 0
		if gotime >= MAXGOTIME - 4
			local tick = (MAXGOTIME - gotime)
			local frac = (FU/4) * tick
			scale = ease.inexpo(
				frac,
				0, FU * 3/2
			)
			alpha = ((9 * (FU - frac)) / FU) << V_ALPHASHIFT
		else
			local tick = (MAXGOTIME - 4) - gotime
			if tick <= 5
				scale = ease.insine(
					(FU/5) * tick,
					FU * 3/2, FU
				)
			end
			
			if gotime < 10
				alpha = (10 - gotime) << V_ALPHASHIFT
			end
		end
		
		v.drawScaled(160*FU, 100*FU, scale, v.cachePatch("SOAP_AR_GO"), alpha)
		gotime = $ - 1
		v.dointerp(false)
	end
	
	if not (me and me.valid) then return end
	if not (me.soap_arms) then return end
	if (me.soap_arms.phase ~= PHASE_WRESTLE) then return end
	
	if soap.c1
		local x,y = 160*FU, 80*FU
		local rad = 15*FU
		local maxsegs = 70
		local timetic = FixedDiv(soap.c1*FU, (TR*3/2)*FU)
		
		local angtotal = 360 * timetic
		local cmap = v.getColormap(TC_DEFAULT, SKINCOLOR_WHITE, "AllWhite")
		local patch = v.cachePatch("TA_LIVESFILL_FILL")
		for i = 0,maxsegs
			if timetic == 0 then break end
			
			local angmath = FixedMul(FixedDiv(angtotal, maxsegs*FU), i*FU) - 90*FU
			local angle = FixedAngle(angmath)
			v.drawScaled(
				x + FixedMul(rad, cos(angle)),
				y + FixedMul(rad, sin(angle)),
				FU/6, patch, 0, cmap
			)
		end
		
		v.drawString(x, y + rad + 2*FU, "Tapping out...", V_ALLOWLOWERCASE, "thin-fixed-center")
	end
	
	local arms = me.soap_arms
	local play = arms.partner
	if not (play and play.valid) then return end
	local omo = play.mo
	local arms2 = omo.soap_arms
	local w2s = K_GetScreenCoords(v,p,cam, {
			x = me.x/2 + omo.x/2,
			y = me.y/2 + omo.y/2,
			z = me.z/2 + omo.z/2,
		}, {anglecliponly = true}
	)
	local scale = FU
	w2s.y = $ + 18*scale
	
	v.dointerp(true)
	local leftpatch = v.cachePatch("SOAP_AR_LEFT")
	local myprogress = FixedDiv(arms.progress, 100*FU)
	v.drawCropped(w2s.x, w2s.y, scale,scale, leftpatch, 0, v.getColormap(TC_DEFAULT, p.skincolor),
		0,0, leftpatch.width * myprogress, leftpatch.height * FU
	)
	
	local rightpatch = v.cachePatch("SOAP_AR_RIGHT")
	local theirprogress = FU - FixedDiv(arms2.progress, 100*FU)
	v.drawCropped(w2s.x + rightpatch.width*theirprogress, w2s.y, scale,scale, rightpatch, 0, v.getColormap(TC_DEFAULT, play.skincolor),
		rightpatch.width*theirprogress,0, rightpatch.width*FU, rightpatch.height*FU
	)
	v.drawScaled(w2s.x, w2s.y, scale, v.cachePatch("SOAP_AR_BACK"), 0)
	
	v.drawString(w2s.x - 62*scale, w2s.y + 18*scale, "You", V_YELLOWMAP|V_ALLOWLOWERCASE, "thin-fixed")
	v.drawString(w2s.x + 62*scale, w2s.y + 18*scale, play.name, V_YELLOWMAP|V_ALLOWLOWERCASE, "thin-fixed-right")
	if (play.soaptable.c1)
		v.drawString(w2s.x + 62*scale, w2s.y + (18 + 8)*scale, "TAPPING OUT", V_REDMAP, "thin-fixed-right")
	end
	v.dointerp(false)
end,"game")

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
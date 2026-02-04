-- The taunt wheel is shared by both characters, and is sorta complicated
-- so it gets its own file.
local CV = SOAP_CV

local taunt_cmd = {
	active = false,
	x = 0,
	y = 0,
	pointing = -1,
	buttons = 0,
}

local function CheckTauntAvail(p)
	if gamestate ~= GS_LEVEL then return false; end
	if not (p and p.valid) then return false; end
	if p.spectator then return false; end
	local soap = p.soaptable
	if not soap then return false; end
	local taunt = soap.taunt
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return false; end
	local me = p.realmo
	if not (me and me.valid) then return false; end

	if (p.panim == PA_IDLE or p.panim == PA_RUN or soap.accspeed <= 5*FU)
	and (P_IsObjectOnGround(me))
	and not (taunt.active or taunt.tics)
	and me.health
	and (soap.notCarried)
	and not (soap.noability & SNOABIL_TAUNTS)
	and (SOAP_TAUNTS[me.skin] ~= nil and #SOAP_TAUNTS[me.skin])
		return true
	end
	return false
end

local function StartMenu()
	if taunt_cmd.active then return end
	taunt_cmd.active = true
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	input.ignoregameinputs = true
end
local function StopMenu()
	if not taunt_cmd.active then return end
	taunt_cmd.active = false
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	input.ignoregameinputs = false
end

local scroll_fact = 400
local wheel_radius = 60*FU
local wheel_start = 28*FU

local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local function chardrawer(v,i, x,y, props, selected)
	local scale = FixedMul(selected and (FU*3/5)/2 or (FU/4), skins[props.skin].highresscale)
	local patch,flip = v.getSprite2Patch(props.skin, props.spr2, false, props.frame, props.angle, 0)
	v.drawScaled(x, y + (patch.height * scale)/2,
		scale, patch, (flip) and V_FLIP or 0,
		v.getColormap(nil,nil, selected and "AllYellow" or "AllWhite")
	)
end

local function cancelConds(p, nobuttons)
	local me = p.realmo
	local soap = p.soaptable
	
	local cancel = false
	if (soap.inPain)
	or (not soap.notCarried)
		cancel = true
	end
	if (not soap.onGround)
	or soap.accspeed >= 4*FU
		cancel = true
	end
	if (soap.jump == 1 or soap.use)
	and not nobuttons
		cancel = true
	end
	return cancel
end

rawset(_G, "SOAP_TAUNTS", {})
SOAP_TAUNTS[SOAP_SKIN] = {
	[1] = {
		name = "Flex",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me,sfx_flex)
			me.state = S_PLAY_SOAP_FLEX
			soap.stasistic = TR
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		postthink = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			p.drawangle = angle + ANGLE_90
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = SOAP_SKIN,
				spr2 = SPR2_FLEX,
				frame = A, angle = 1
			}, selected)
		end,
	},
	[2] = {
		name = "Laugh",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me,sfx_hahaha)
			me.state = S_PLAY_SOAP_LAUGH
			soap.stasistic = TR
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		postthink = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			p.drawangle = angle + ANGLE_180
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = SOAP_SKIN,
				spr2 = SPR2_APOS,
				frame = A, angle = 1
			}, selected)
		end,
	},
	[3] = {
		name = "Death",
		
		run = function(p, me, soap, taunt)
			me.state = S_PLAY_DEAD
			me.sprite2 = SPR2_MSC4
			me.tics = -1
			
			me.tempangle = p.drawangle
			S_StartSound(me,sfx_altdi1,p)
			S_StartSound(me,sfx_sp_smk,p)
			S_StartSound(me,sfx_s3k5d)
			Soap_DustRing(me,
				dust_type(me),
				P_RandomRange(8,14),
				{me.x,me.y,me.z},
				16*me.scale,
				me.scale*5,
				me.scale,
				me.scale/2,
				false, dust_noviewmobj
			)
			Soap_StartQuake(10*FU, 10, {me.x,me.y,me.z}, 256*me.scale)
			
			soap.stasistic = max($, 2)
			taunt.tics = 2
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p)
			or me.tempangle == nil
				me.tempangle = nil
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
				Soap_ResetState(p)
				soap.stasistic, taunt.tics = 0,0
			else
				soap.stasistic = max($, 2)
				taunt.tics = 2
				
				p.drawangle = me.tempangle
				soap.noability = SNOABIL_ALL
				
				if me.state ~= S_PLAY_DEAD
					me.state = S_PLAY_DEAD
					me.tics = -1
				elseif me.sprite2 ~= SPR2_MSC4
					me.frame = $ &~FF_FRAMEMASK
					me.sprite2 = SPR2_MSC4
				end
			end
		end,
		postthink = function(p, me, soap, taunt)
			if me.tempangle == nil then return end
			p.drawangle = me.tempangle
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_MSC4,
				frame = A, angle = 2
			}, selected)
		end,
	}
}
SOAP_TAUNTS[TAKIS_SKIN] = {
	[1] = SOAP_TAUNTS[SOAP_SKIN][3]
}

local cmd_sig = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) cmd_sig = n($); end)

COM_AddCommand("_soap_dotaunt",function(p, sig, selected)
	if sig ~= cmd_sig then return end
	if not CheckTauntAvail(p) then return end
	selected = tonumber($)
	
	local soap = p.soaptable
	local me = p.realmo
	local taunt = soap.taunt
	
	taunt.num = selected + 1
	taunt.prev = taunt.num
	local taunt_t = SOAP_TAUNTS[me.skin][selected + 1]
	if not taunt_t then return end
	taunt_t.run(p, me, soap, taunt)
	
	soap.jumplockout = 2
end)

local gc2bt = {
	[GC_FIRE]		= BT_ATTACK,
	[GC_FIRENORMAL]	= BT_FIRENORMAL,
	[GC_TOSSFLAG]	= BT_TOSSFLAG,
	[GC_SPIN]		= BT_SPIN,
	[GC_JUMP]		= BT_JUMP,
}

addHook("KeyDown", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	
	local kname = key.name:lower()
	
	if kname == CV.taunt_key.string:lower()
		if taunt_cmd.active
		and (consoleplayer.soaptable and consoleplayer.soaptable.taunt.prev > 0)
			COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..(consoleplayer.soaptable.taunt.prev - 1))
			StopMenu()
		else
			StartMenu()
		end
	elseif kname == "escape"
	and taunt_cmd.active
		StopMenu()
		return true
	end
	
	-- game controls
	for gc, bt in pairs(gc2bt)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if key.num == k1 or key.num == k2
			taunt_cmd.buttons = $|bt
		end
	end
end)

addHook("KeyUp", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	
	-- game controls
	for gc, bt in pairs(gc2bt)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if key.num == k1 or key.num == k2
			taunt_cmd.buttons = $ &~bt
		end
	end
end)

local function ClientTauntHandle(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	
	if not taunt_cmd.active then return end
	
	-- nice one asshole
	if SOAP_TAUNTS[me.skin] == nil
		StopMenu()
		return
	end
	
	if MenuLib.client.currentMenu.id ~= -1
		MenuLib.initMenu(-2)
		input.ignoregameinputs = true
	end
	
	if (taunt_cmd.buttons & BT_SPIN)
	--or cancelConds(p, true)
		StopMenu()
	end
	
	-- negative angleturn is rightwards
	-- positive aiming is upwards
	local workx = -(mouse.dx*8) * scroll_fact
	local worky = -(mouse.dy*8) * scroll_fact
	taunt_cmd.x = $ - workx
	taunt_cmd.y = $ + worky
	local ang = R_PointToAngle2(0,0, taunt_cmd.x,taunt_cmd.y)
	local dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
	if (dist > wheel_radius)
		taunt_cmd.x = P_ReturnThrustX(nil,ang, wheel_radius)
		taunt_cmd.y = P_ReturnThrustY(nil,ang, wheel_radius)
		dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
	end
	
	local oldhover = taunt_cmd.pointing
	local selected = -1
	if (dist >= wheel_start)
		local avail = #SOAP_TAUNTS[me.skin]
		local angstep = FixedDiv(360*FU, avail*FU)
		ang = AngleFixed(InvAngle($ - ANGLE_90))
		selected = FixedTrunc(FixedDiv(ang, angstep)) / FU
		taunt_cmd.pointing = selected
	else
		taunt_cmd.pointing = -1
	end
	if (oldhover ~= taunt_cmd.pointing)
	and (dist >= wheel_start)
		S_StartSound(nil,sfx_menu1,p)
	end
	
	if (taunt_cmd.buttons & (BT_ATTACK|BT_JUMP))
	or (mouse.buttons & MB_BUTTON1)
	and (dist >= wheel_start)
		COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..selected)
		StopMenu()
	end
end

rawset(_G, "Soap_TauntWheelThink", function(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	local taunt = soap.taunt
	
	-- lets also handle the client stuff in here
	if p == consoleplayer
		ClientTauntHandle(p)
	end
	
	if taunt.tics > 0
		-- nice one asshole
		if SOAP_TAUNTS[me.skin] == nil
		or (me.skin ~= soap.last.skin)
			taunt.tics = 0
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
			return
		end
		
		local taunt_t = SOAP_TAUNTS[me.skin][taunt.num]
		if taunt_t.think
			taunt_t.think(p, me, soap, taunt)
		end
		
		taunt.tics = $ - 1
	else
		taunt.tics = 0
		taunt.num = 0
	end
end)

-- its just easier to handle the hud here
local wheel_inner = wheel_start + (wheel_radius - wheel_start)/2
addHook("HUD",function(v,p)
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local taunt = taunt_cmd
	
	if not taunt.active then return end
	
	v.drawScaled(160*FU,100*FU, FU/2, v.cachePatch("STAUNT_BG"), V_30TRANS)
	local dist = R_PointToDist2(0,0, taunt.x,taunt.y)
	local TAUNTS = SOAP_TAUNTS[skins[p.skin].name]
	local avail = #TAUNTS
	local angstep = FixedDiv(360*FU, avail*FU)
	for i = 0, avail - 1
		local ang = ANGLE_MAX - FixedAngle(angstep * i)
		v.drawScaled(160*FU,100*FU, FU/2,
			v.getSpritePatch(SPR_SOAP_GFX, 53, 0, ang),
			0
		)
		ang = ($ - ANGLE_90) + ANGLE_180 - FixedAngle(angstep / 2)
		
		if (TAUNTS[i + 1].drawer ~= nil)
			TAUNTS[i + 1].drawer(v, i,
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				(dist >= wheel_start) and (taunt.pointing == i)
			)
		else
			v.drawScaled(
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				FU/4,
				v.cachePatch("MISSING"),
				0
			)
		end
	end
	
	v.dointerp(1000)
	v.drawScaled(
		(160*FU) + taunt.x, --P_ReturnThrustX(nil,taunt.angle<<16, radius),
		(100*FU) - taunt.y, --P_ReturnThrustY(nil,taunt.aim<<16, radius),
		FU/4, v.cachePatch((dist >= wheel_start) and "ML_RBLX_POINT" or "ML_RBLX_CURS"),
		0
	)
	v.dointerp(false)
	
	if (dist >= wheel_start)
		local taunt_t = TAUNTS[taunt.pointing + 1]
		v.drawString(160*FU, 100*FU + (wheel_radius + 5*FU),
			taunt_t.name, V_ALLOWLOWERCASE|V_YELLOWMAP,
			"thin-fixed-center"
		)
	end
	
	v.drawString(160*FU, 100*FU - (wheel_radius + 10*FU),
		"Pick a taunt!", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 20*FU),
		"[JUMP/FIRE] - Select", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 28*FU),
		"[SPIN] - Cancel", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
end,"game")
-- The taunt wheel is shared by both characters, and is sorta complicated
-- so it gets its own file.
local CV = SOAP_CV

local GPAD_A = 256 + 8
local GPAD_B = GPAD_A + 1
local GPAD_X = GPAD_A + 2
local GPAD_Y = GPAD_A + 3

local GPAD_LBUMPER = GPAD_A + 4
local GPAD_RBUMPER = GPAD_A + 5

local GPAD_LCENTER = GPAD_A + 6
local GPAD_RCENTER = GPAD_A + 7

local GPAD_LSTICK = GPAD_A + 8
local GPAD_RSTICK = GPAD_A + 9

local GPAD_DUP = 296
local GPAD_DDOWN = 296 + 1
local GPAD_DLEFT = 296 + 2
local GPAD_DRIGHT = 296 + 3

local gpbuttonnames = {
	[GPAD_A] = "A",
	[GPAD_B] = "B",
	[GPAD_X] = "X",
	[GPAD_Y] = "Y",

	[GPAD_LBUMPER] = "Left Bumper",
	[GPAD_RBUMPER] = "Right Bumper",

	[GPAD_LCENTER] = "Select",
	[GPAD_RCENTER] = "Start",

	[GPAD_LSTICK] = "Left Stick",
	[GPAD_RSTICK] = "Right Stick",

	[GPAD_DUP] = "D-Pad Up",
	[GPAD_DDOWN] = "D-Pad Down",
	[GPAD_DLEFT] = "D-Pad Left",
	[GPAD_DRIGHT] = "D-Pad Right",
}

local TAUNT_ANIM = TR
local taunt_cmd = {
	active = false,
	closed = false, -- keeps ignoregameinputs on for a tic
	x = 0,
	y = 0,
	pointing = -1,
	buttons = 0,
	joystick = false,
	joy_spin = false,
	joy_fire = false,
	
	forward = 0,
	side = 0,
	
	animation = 0,
}

local function StartMenu()
	if taunt_cmd.active then return end
	taunt_cmd.active = true
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	taunt_cmd.closed = false
	input.ignoregameinputs = true
end
local function StopMenu()
	if not taunt_cmd.active then return end
	taunt_cmd.active = false
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	taunt_cmd.closed = true
	input.ignoregameinputs = false
end
local function TauntWarning()
	S_StartSoundAtVolume(nil, sfx_sp_cnt, 255 / 2)
	taunt_cmd.animation = TAUNT_ANIM
end

local scroll_fact = 400
local wheel_radius = 60*FU
local wheel_start = 28*FU

rawset(_G, "SOAP_TAUNTS", {})
rawset(_G, "SoapTaunt_AddTaunt", function(skin, info)
	if SOAP_TAUNTS[skin] == nil
		SOAP_TAUNTS[skin] = {}
	end
	SOAP_TAUNTS[skin][(#SOAP_TAUNTS[skin] + 1)] = info
	print(("\x83SOAP\x80: Registered taunt '%s' for skin '%s' in slot %d"):format(info.name, skin, #SOAP_TAUNTS[skin]))
end)
rawset(_G, "SoapTaunt_WheelDrawer", function(v,i, x,y, props, selected)
	local scale = FixedMul(selected and (FU*3/5)/2 or (FU/4), skins[props.skin].highresscale)
	local patch,flip = v.getSprite2Patch(props.skin, props.spr2, false, props.frame, props.angle, 0)
	v.drawScaled(x, y + (patch.height * scale)/2,
		scale, patch, (flip) and V_FLIP or 0,
		v.getColormap(nil,nil, selected and "AllYellow" or "AllWhite")
	)
end)
rawset(_G, "SoapTaunt_CancelWhen", function(p, nobuttons, checkspinonly)
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
	
	local buttoncancel = false
	if (soap.jump == 1 and not checkspinonly)
	or (soap.use)
		buttoncancel = true
	end
	if (buttoncancel)
	and not nobuttons
		cancel = true
		p.cmd.buttons = $ &~(BT_JUMP|BT_SPIN)
		soap.use = 0
		soap.jump = 0
		soap.jumplockout = true
		soap.uselockout = true
	end
	
	if me.soap_tauntforcecancel
		me.soap_tauntforcecancel = nil
		cancel = true
	end
	
	-- special case
	if (gametype == GT_ZE2 or (ZE2 and ZE2.isGametype()))
	and (me.sprite2 == SPR2_ROLL)
		cancel = true
	end
	
	return cancel
end)
rawset(_G, "SoapTaunt_TauntIsAvail", function(p, nobuttons, checkspinonly)
	if gamestate ~= GS_LEVEL then return false; end
	if not (p and p.valid) then return false; end
	if p.spectator then return false; end
	local soap = p.soaptable
	if not soap then return false; end
	local taunt = soap.taunt
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return false; end
	local me = p.realmo
	if not (me and me.valid) then return false; end
	
	local noabil_taunt = (skins[p.skin].name == TAKIS_SKIN) and NOABIL_TAUNTS or SNOABIL_TAUNTS
	if (p.panim == PA_IDLE or p.panim == PA_RUN or soap.accspeed <= 5*FU)
	and (P_IsObjectOnGround(me))
	and not ((taunt.active or taunt.tics) and checkactive)
	and me.health
	and (soap.notCarried)
	and not (soap.noability & noabil_taunt == noabil_taunt and checkactive)
	and (SOAP_TAUNTS[me.skin] ~= nil and #SOAP_TAUNTS[me.skin])
		return true
	end
	return false
end)
rawset(_G, "SoapTaunt_Warning",function(p)
	if p ~= consoleplayer then return end
	TauntWarning()
end)
local CheckTauntAvail = SoapTaunt_TauntIsAvail

local function addtaunt(path)
	dofile("Character/Taunts/"..path)
end
local tauntstoadd = {
	"Soap/1_flex.lua",
	"Soap/2_laugh.lua",
	"Soap/3_death.lua",
	"Soap/4_breakdance.lua",
	"Soap/5_sixseven.lua",
	"Soap/6_punch.lua",
	"Soap/7_gangnam.lua",

	"Takis/1_smug.lua",
	"Takis/2_omg.lua",
	"Takis/3_death.lua",
	"Takis/4_surfin.lua",
	"Takis/5_sixseven.lua",
	"Takis/6_caramell.lua",
}
for _, name in ipairs(tauntstoadd)
	addtaunt(name)
end

local cmd_sig = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) cmd_sig = n($); end)

COM_AddCommand("_soap_dotaunt",function(p, sig, selected)
	if sig ~= cmd_sig then return end
	if not CheckTauntAvail(p, false) then return end
	selected = tonumber($)
	
	local soap = p.soaptable
	local me = p.realmo
	local taunt = soap.taunt
	
	local prevnum = taunt.num
	local taunt_t = SOAP_TAUNTS[me.skin][selected + 1]
	if not taunt_t then return end
	
	if (taunt.active or taunt.tics)
		if taunt_t.cancelable and prevnum == selected + 1
			me.soap_tauntforcecancel = true
		end	
		return
	end
	
	if CheckTauntAvail(p, true)
		taunt.num = selected + 1
		taunt.prev = taunt.num
		
		taunt_t.run(p, me, soap, taunt)
	else
		return
	end
	
	soap.jumplockout = true
end)

local fakespinlockout = false
local gc2bt = {
	[GC_FIRE]		= BT_ATTACK,
	[GC_FIRENORMAL]	= BT_FIRENORMAL,
	[GC_TOSSFLAG]	= BT_TOSSFLAG,
	[GC_SPIN]		= BT_SPIN,
	[GC_JUMP]		= BT_JUMP,
}
local control_gc = {
	[GC_FORWARD]		= 1,
	[GC_BACKWARD]		= -1,
	
	[GC_STRAFELEFT]		= -2,
	[GC_TURNLEFT]		= -2,
	[GC_STRAFERIGHT]	= 2,
	[GC_TURNRIGHT]		= 2,
}
local keymovespeed = 7*FU
local numberkey = -1

local leftjoystick = {
	x = 0, y = 0
}
local rightjoystick = {
	x = 0, y = 0
}

local function CheckNoAbil(allowtaunting)
	local p = consoleplayer
	local noabil_taunt = (skins[p.skin].name == TAKIS_SKIN) and NOABIL_TAUNTS or SNOABIL_TAUNTS
	
	if (p.soaptable.noability & noabil_taunt)
	and not ((p.soaptable.taunt.active or p.soaptable.taunt.tics) and allowtaunting)
		return true
	end
	return false
end

addHook("KeyDown", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	
	local kname = key.name:lower()
	
	if kname == CV.taunt_key.string:lower()
	and (skins[consoleplayer.skin].name == SOAP_SKIN or skins[consoleplayer.skin].name == TAKIS_SKIN)
		local menuactive = MenuLib.client.currentMenu.id ~= -1
		
		if taunt_cmd.active
		and (consoleplayer.soaptable and consoleplayer.soaptable.taunt.prev > 0)
			COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..(consoleplayer.soaptable.taunt.prev - 1))
			StopMenu()
			return true
		elseif not (menuactive or consoleplayer.spectator) and not CheckNoAbil(true)
			StartMenu()
			return true
		elseif CheckNoAbil(true)
			TauntWarning()
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
	
	for gc, type in pairs(control_gc)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if not (key.num == k1 or key.num == k2) then continue end
		
		-- forwardmove keys
		if abs(type) == 1
			taunt_cmd.forward = keymovespeed * type
		elseif abs(type) == 2
			taunt_cmd.side = keymovespeed * sign(type)
		end
	end
	
	-- number keys can select taunts as well
	if tonumber(key.name) ~= nil
	and taunt_cmd.active
		local knum = tonumber(key.name)
		if knum == 0 then knum = 10; end -- if we ever have 10 taunts
		
		numberkey = knum - 1
		return true
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
	
	for gc, type in pairs(control_gc)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if not (key.num == k1 or key.num == k2) then continue end
		
		-- forwardmove keys
		if abs(type) == 1
			taunt_cmd.forward = 0
		elseif abs(type) == 2
			taunt_cmd.side = 0
		end
	end
end)

local TICCMD_RECIEVED = 1
local KEY_JOY1 = KEY_JOY1 or ((KEY_MOUSE1 or 256) + (MOUSEBUTTONS or 8))
local gp_waskeydown = false
addHook("PlayerCmd",function(p,cmd)
	leftjoystick.x = input.joyAxis(JA_STRAFE)
	leftjoystick.y = input.joyAxis(JA_MOVE)
	
	rightjoystick.x = input.joyAxis(JA_TURN)
	rightjoystick.y = -input.joyAxis(JA_LOOK)
	
	taunt_cmd.joy_spin = false
	taunt_cmd.joy_fire = false
	
	local gamepad_tb = CV.taunt_button.value
	if (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN)
	and (gamepad_tb > GPAD_A) and (gamekeydown[gamepad_tb] and not gp_waskeydown)
		local menuactive = MenuLib.client.currentMenu.id ~= -1
		
		if taunt_cmd.active
		and (p.soaptable and p.soaptable.taunt.prev > 0)
			COM_BufInsertText(p, "_soap_dotaunt "..cmd_sig.." "..(p.soaptable.taunt.prev - 1))
			StopMenu()
		elseif not (menuactive or p.spectator) and not CheckNoAbil(true)
			StartMenu()
			taunt_cmd.joystick = true
		elseif CheckNoAbil(true)
			TauntWarning()
		end
	end
	gp_waskeydown = gamekeydown[gamepad_tb]
	
	if fakespinlockout
		if (cmd.buttons & BT_SPIN)
			cmd.buttons = $ &~BT_SPIN
		else
			fakespinlockout = false
		end
	end
	
	if not (taunt_cmd.active or taunt_cmd.closed) then return end
	
	-- EAT SHIT AND DIE FUCK YOU GAME
	-- im gonna cry
	do -- gamepad buttons
		local spin1, spin2 = input.gameControlToKeyNum(GC_SPIN)
		local fire1, fire2 = input.gameControlToKeyNum(GC_FIRE)
		local spinaxis = input.joyAxis(JA_SPIN)
		local fireaxis = input.joyAxis(JA_FIRE)
		
		if ((spin1 > KEY_JOY1) and gamekeydown[spin1])
		or ((spin2 > KEY_JOY1) and gamekeydown[spin2])
		or (spinaxis > 0)
			taunt_cmd.joy_spin = true
		end

		if ((fire1 > KEY_JOY1) and gamekeydown[fire1])
		or ((fire2 > KEY_JOY1) and gamekeydown[fire2])
		or (fireaxis > 0)
			taunt_cmd.joy_fire = true
		end
	end
	
	input.ignoregameinputs = true
	
	cmd.forwardmove = 0
	cmd.sidemove = 0
	cmd.buttons = 0
	cmd.angleturn = p.cmd.angleturn &~TICCMD_RECIEVED -- this game drives me insane
	cmd.aiming = p.cmd.aiming
end)

local DEADZONE = 32
local function JoystickActive(stick)
	if abs(stick.x) > DEADZONE or abs(stick.y) > DEADZONE
		return true
	end
	return false
end

local function ClientTauntHandle(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	
	if not taunt_cmd.active then return end
	input.ignoregameinputs = true
	
	-- nice one asshole
	if SOAP_TAUNTS[me.skin] == nil
	or CheckNoAbil(false)
		StopMenu()
		if CheckNoAbil(false) then TauntWarning(); end
		return
	end
	
	if MenuLib.client.currentMenu.id ~= -1
		MenuLib.initMenu(-2)
		input.ignoregameinputs = true
	end
	
	if (taunt_cmd.buttons & BT_SPIN) or taunt_cmd.joy_spin
		StopMenu()
		fakespinlockout = true
	end
	
	-- negative angleturn is rightwards
	-- positive aiming is upwards
	local workx = -(mouse.dx*8) * scroll_fact
	local worky = -(mouse.dy*8) * scroll_fact
	workx = $ - taunt_cmd.side
	worky = $ + taunt_cmd.forward
	taunt_cmd.x = $ - workx
	taunt_cmd.y = $ + worky
	local ang = R_PointToAngle2(0,0, taunt_cmd.x,taunt_cmd.y)
	local dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
	if (dist > wheel_radius)
		taunt_cmd.x = P_ReturnThrustX(nil,ang, wheel_radius)
		taunt_cmd.y = P_ReturnThrustY(nil,ang, wheel_radius)
		dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
	end
	
	if taunt_cmd.joystick
		taunt_cmd.x = $ / 4
		taunt_cmd.y = $ / 4
		if (mouse.dx or mouse.dy)
			taunt_cmd.joystick = false
		end
	end
	if JoystickActive(leftjoystick) or JoystickActive(rightjoystick)
		local stick = leftjoystick
		if JoystickActive(rightjoystick)
			stick = rightjoystick
		end
		
		local maxmove = JOYAXISRANGE*FU
		local move = Vec2.New(
			FixedDiv(stick.x*FU, maxmove), 
			FixedDiv(stick.y*FU, maxmove)
		)
		local force = min(FixedHypot(move.x, move.y), FU)
		local ang = R_PointToAngle2(0,0, stick.x*FU,-stick.y*FU)
		taunt_cmd.x = P_ReturnThrustX(nil,ang, FixedMul(wheel_radius*3/4, force))
		taunt_cmd.y = P_ReturnThrustY(nil,ang, FixedMul(wheel_radius*3/4, force))
		dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
		
		taunt_cmd.joystick = true
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
	
	if (taunt_cmd.buttons & (BT_ATTACK))
	or (mouse.buttons & MB_BUTTON1)
	or (taunt_cmd.joy_fire)
	and (dist >= wheel_start)
	or (numberkey > -1)
		if numberkey > -1 then selected = numberkey; end
		COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..selected)
		StopMenu()
	end
	numberkey = -1
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
		or not (me.health)
		or (me.state >= S_PLAY_SUPER_TRANS1 and me.state <= S_PLAY_SUPER_TRANS6)
			local taunt_t = SOAP_TAUNTS[soap.last.skin][taunt.num]
			if taunt_t.canceled
				taunt_t.canceled(p, me, soap, taunt)
			end
			
			taunt.tics = 0
			if me.health
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
				Soap_ResetState(p)
			end
			return
		end
		
		local taunt_t = SOAP_TAUNTS[me.skin][taunt.num]
		if taunt_t.think
			taunt_t.think(p, me, soap, taunt)
		end
		
		if not (me.hitlag)
			taunt.tics = $ - 1
		end
	else
		taunt.tics = 0
		taunt.num = 0
	end
end)

addHook("PostThinkFrame",do
	if not (taunt_cmd.active or taunt_cmd.closed) then return end
	input.ignoregameinputs = false
	
	taunt_cmd.closed = false
end)

-- its just easier to handle the hud here
local wheel_inner = wheel_start + (wheel_radius - wheel_start)/2
local wheel_farther = wheel_start + (wheel_radius - wheel_start) --* 5/4
local fadewait = 0
local curfade = 0
addHook("HUD",function(v,p)
	-- bruh
	p = consoleplayer
	if not (p and p.valid) then return end -- DEMOSSSSSS. UGH.
	
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local taunt = taunt_cmd
	
	if taunt_cmd.animation
		local x = 160
		local cmap = 0
		if taunt_cmd.animation > TAUNT_ANIM - 10
			x = $ + (taunt_cmd.animation % 2 and 1 or -1)
			cmap = (taunt_cmd.animation % 2 and V_REDMAP or 0)
		end
		
		v.draw(x, 140, v.cachePatch("STAUNT_CNTBG"), V_SNAPTOBOTTOM|V_30TRANS)
		v.draw(x - 42, 139, v.cachePatch("STAUNT_ERR"), V_SNAPTOBOTTOM, v.getStringColormap(V_REDMAP))
		v.drawString(x + 6, 140,
			"Can't use taunts.", V_ALLOWLOWERCASE|V_SNAPTOBOTTOM|cmap,
			"thin-center"
		)
		
		taunt_cmd.animation = $ - 1
	end
	
	if not taunt.active then fadewait = TR/2; curfade = 0; return end
	
	if fadewait
		fadewait = $ - 1
	elseif curfade < 24
		curfade = $ + 1
	end
	if curfade
		v.fadeScreen(0xFF00, curfade)
	end
	
	v.drawScaled(160*FU,100*FU, FU/2, v.cachePatch("STAUNT_BG"), V_30TRANS)
	local dist = R_PointToDist2(0,0, taunt.x,taunt.y)
	local TAUNTS = SOAP_TAUNTS[skins[p.skin].name]
	local avail = #TAUNTS
	local angstep = FixedDiv(360*FU, avail*FU)
	for i = 0, avail - 1
		local ang = ANGLE_MAX - FixedAngle(angstep * i)
		v.drawScaled(160*FU,100*FU, FU/2,
			v.getSpritePatch(SPR_SOAP_GFX, 25, 0, ang),
			0
		)
		ang = ($ - ANGLE_90) + ANGLE_180 - FixedAngle(angstep / 2)
		local selected = (dist >= wheel_start) and (taunt.pointing == i)
		
		if (TAUNTS[i + 1].drawer ~= nil)
			TAUNTS[i + 1].drawer(v, i,
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				selected
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
		if not taunt_cmd.joystick
			v.drawString(
				160*FU + P_ReturnThrustX(nil, ang, wheel_farther),
				100*FU - P_ReturnThrustY(nil, ang, wheel_farther) - 4*FU,
				(i + 1), selected and V_YELLOWMAP or 0, "small-thin-fixed-center"
			)
		end
	end
	
	v.dointerp(1000)
	v.drawScaled(
		(160*FU) + taunt.x, --P_ReturnThrustX(nil,taunt.angle<<16, radius),
		(100*FU) - taunt.y, --P_ReturnThrustY(nil,taunt.aim<<16, radius),
		FU/4, v.cachePatch((dist >= wheel_start) and (taunt_cmd.joystick and "STAUNT_GPOINT" or "ML_RBLX_POINT") or (taunt_cmd.joystick and "STAUNT_GCUR" or "ML_RBLX_CURS")),
		0
	)
	v.dointerp(false)
	
	if (dist >= wheel_start)
		local taunt_t = TAUNTS[taunt.pointing + 1]
		if taunt_t
			v.drawString(160*FU, 100*FU + (wheel_radius + 5*FU),
				taunt_t.name, V_ALLOWLOWERCASE|V_YELLOWMAP,
				"thin-fixed-center"
			)
		end
	end
	
	v.drawString(160*FU, 100*FU - (wheel_radius + 10*FU),
		"Pick a taunt!", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 20*FU),
		"[FIRE] - Select", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 28*FU),
		"[SPIN] - Cancel", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
end,"game")
local CV = SOAP_CV
CV.unlockcommands = CV_RegisterVar({
	name = "soap_unlockcommands",
	defaultvalue = "No",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_OnOff,
})

local function GetPlayerHelper(pname)
	-- Find a player using their node or part of their name.
	local N = tonumber(pname)
	if N ~= nil and N >= 0 and N < 32 then
		for player in players.iterate do
			if #player == N then
	return player
			end
		end
	end
	for player in players.iterate do
		if string.find(string.lower(player.name), string.lower(pname)) then
			return player
		end
	end
	return nil
end
local function GetPlayer(player, pname)
	local player2 = GetPlayerHelper(pname)
	if not player2 then
		CONS_Printf(player, "No one here has that name.")
	end
	return player2
end

rawset(_G, "Bloat_CheckAdmin",function(p)
	if CV.unlockcommands.value then return true end
	
	local admin = (IsPlayerAdmin(p) or p == server)
	if (admin == false) and (p.soaptable and p.soaptable.bloataccess)
		admin = true
	end
	/*
	-- NO FUN ALLOWED UPDATE
	if not admin
	and (p.name == "Epix" and not mbrelease) --lol
		admin = true
	end
	*/
	return admin
end)
rawset(_G, "Bloat_RealAdmin",function(p)
	return (IsPlayerAdmin(p) or p == server)
end)

sfxinfo[SafeFreeslot("sfx_deez")] = {
	caption = "!?",
	flags = SF_X4AWAYSOUND
}

local prn = CONS_Printf
local CMD_PREFIX = "sb_"

local function NotInLevel()
	return not (gamestate == GS_LEVEL or gamestate == GS_DEDICATEDSERVER)
end

local checkadmin = true

/* @props = {
	prefix = string :: Command name prefix
	outoflevels = boolean :: Don't check for level-ness beforehand if true
	checksoap = boolean :: Check for player.soaptable
	flags = INT32 :: Command flags
	noadmin = boolean :: Don't check if the player is admin (only if checkadmin is FALSE)
	forcenoadmin = boolean :: Never check if the player is admin
	unsafe = boolean :: If checkadmin is FALSE, dont allow this command to be ran
} */
local function CMDConstructor(name, props)
	COM_AddCommand((props.prefix or '')..name,function(p, ...)
		if not props.outoflevels
		and NotInLevel()
			prn(p, "You must be in a level to use this.")
			return
		end
		if props.checksoap
		and not p.soaptable
			prn(p, "You can't use this right now.")
			return
		end
		
		local admin = Bloat_CheckAdmin(p)
		
		local adminonly = checkadmin
		if (not props.noadmin)
		and not checkadmin
			adminonly = false
		end
		if (not checkadmin)
			adminonly = props.unsafe
		end
		if (props.forcenoadmin)
			adminonly = false
		end
		
		if (not admin) and (adminonly)
			prn(p, "You can't use this.")
			return
		end
		
		props.func(p, ...)
	end,(props.flags or 0))
end

CMDConstructor("playsound", {prefix = CMD_PREFIX, func = function(p,...)
	local args = {...}
	local soundid = args[1]
	local vol = args[2]
	if soundid == nil then return end
	
	soundid = string.lower($)
	if (string.sub(soundid,1,3) ~= "sfx_")
		soundid = "sfx_"..$
	end
	soundid = _G[$]
	if soundid == nil
		prn(p,"Sound does not exist")
		return
	end
	
	if vol == nil or tonumber(vol) == nil
		vol = 255
	else
		vol = clamp(0, tonumber(vol), 255)
	end
	S_StartSoundAtVolume(nil, soundid, vol)
end})

local PHASEFLAGS = MF_NOCLIP|MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOTHINK
CMDConstructor("phase", {prefix = CMD_PREFIX, func = function(p,...)
	p.soap_phasemode = not $
	if not p.soap_phasemode then p.realmo.flags = $ &~PHASEFLAGS; p.pflags = $ &~(PF_GODMODE|PF_NOCLIP); end
	prn(p, "Phasing "..(p.soap_phasemode and "on" or "off"))
end})
Takis_Hook.addHook("PreThinkFrame",function(p)
	if not p.soap_phasemode then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	
	me.flags = $|PHASEFLAGS
	p.pflags = $|PF_GODMODE|PF_JUMPSTASIS|PF_NOCLIP
	local cmd = p.cmd
	local speed = (cmd.buttons & BT_CUSTOM3 and 45 or 20)*me.scale
	local friction = FU/2
	
	local sine = {
		angle   = sin(me.angle),
		angle_p = sin(me.angle - ANGLE_90),
		aim     = sin(p.aiming),
		aim_p   = sin(p.aiming + ANGLE_90),
		roll    = 0,
	}
	local cosine = {
		angle   = cos(me.angle),
		angle_p = cos(me.angle - ANGLE_90),
		aim     = cos(p.aiming),
		aim_p   = cos(p.aiming + ANGLE_90),
		roll    = FU,
	}
	
	local forwardVec = Vec3.New(
		FixedMul(cosine.aim, cosine.angle),
		FixedMul(cosine.aim, sine.angle),
		sine.aim
	)
	local rightVec = Vec3.New(
		 FixedMul(sine.angle, cosine.roll) + FixedMul(cosine.angle, FixedMul(sine.aim, sine.roll)),
		-FixedMul(cosine.angle, cosine.roll) + FixedMul(sine.angle, FixedMul(sine.aim, sine.roll)),
		-FixedMul(cosine.aim, sine.roll)
	)
	local upVec = Vec3.New(
		-FixedMul(cosine.angle, FixedMul(sine.aim, cosine.roll)) + FixedMul(sine.angle, sine.roll),
		-FixedMul(sine.angle, FixedMul(sine.aim, cosine.roll)) - FixedMul(cosine.angle, sine.roll),
		 FixedMul(cosine.roll, cosine.aim)
	)
	local push = Vec3.New(0,0,0)
	push.x = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.forwardmove*FU, 50*FU)), forwardVec.x)
	push.y = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.forwardmove*FU, 50*FU)), forwardVec.y)
	push.z = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.forwardmove*FU, 50*FU)), forwardVec.z)
	
	push.x = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.sidemove*FU, 50*FU)), rightVec.x)
	push.y = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.sidemove*FU, 50*FU)), rightVec.y)
	push.z = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.sidemove*FU, 50*FU)), rightVec.z)
	
	local pushsign = 0
	if (cmd.buttons & BT_JUMP)
		pushsign = 1
	elseif (cmd.buttons & BT_SPIN)
		pushsign = -1
	end
	if pushsign ~= 0
		local spd = (speed / 2) * pushsign * P_MobjFlip(me)
		push.x = $ + FixedMul(spd, upVec.x)
		push.y = $ + FixedMul(spd, upVec.y)
		push.z = $ + FixedMul(spd, upVec.z)
	end

	me.momx = P_Lerp(FU - friction, $, 0)
	me.momy = P_Lerp(FU - friction, $, 0)
	me.momz = P_Lerp(FU - friction, $, 0)
	
	me.momx = $ + push.x
	me.momy = $ + push.y
	me.momz = $ + push.z
	
	P_XYMovement(me)
	P_ZMovement(me)
end)
Takis_Hook.addHook("PostThinkFrame",function(p)
	if not p.soap_phasemode then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	
	-- bruh
	local viewheight = 41*me.height/48
	p.viewz = me.z + viewheight
	if P_MobjFlip(me) == -1
		p.viewz = me.z + me.height - viewheight
	end
end)

-- special promote functions for bloat commands
CMDConstructor("promote", {prefix = CMD_PREFIX, func = function(p,...)
	local args = {...}
	if CV.unlockcommands.value
		prn(p,"soap_unlockcommands is in effect, everyone has access to Soap commands.")
		return
	end
	
	local node = args[1] or ""
	local p2 = GetPlayer(p,node)
	if node == "" or (not p2)
		prn(p, "sb_promote [player]: Allows a player to use commands from Soap. \x85\Does not give them real admin.\x80")
		return
	end
	
	if (IsPlayerAdmin(p2) or p2 == server)
		prn(p, "\x85This player is an admin, they have access to commands by default.")
		return
	end
	
	if p2.soaptable.bloataccess
		prn(p, "\x85This player already has access to Soap commands.")
		return
	end
	
	p2.soaptable.bloataccess = true
	prn(p, "\x82Promoted " .. p2.name .. ".")
	prn(p2, "\x82You can now use Soap commands!")
end, flags = COM_ADMIN})
CMDConstructor("demote", {prefix = CMD_PREFIX, func = function(p,...)
	local args = {...}
	if CV.unlockcommands.value
		prn(p,"soap_unlockcommands is in effect, everyone has access to Soap commands.")
		return
	end
	
	local node = args[1] or ""
	local p2 = GetPlayer(p,node)
	if node == "" or (not p2)
		prn(p, "sb_demote [player]: Disallows a player from using commands from Soap. \x85\Does not give nor remove real admin.\x80")
		return
	end
	
	if (IsPlayerAdmin(p2) or p2 == server)
		prn(p, "\x85This player is an admin, they will maintain access to commands by default.")
		return
	end
	
	if not p2.soaptable.bloataccess
		prn(p, "\x85This player doesn't have access to Soap commands.")
		return
	end
	
	p2.soaptable.bloataccess = false
	prn(p, "\x82\Demoted " .. p2.name .. ".")
	prn(p2, "\x85You can no longer use Soap commands.")
end, flags = COM_ADMIN})
CMDConstructor("listadmin", {prefix = CMD_PREFIX, func = function(p,...)
	for play in players.iterate
		local admstr = ""
		if Bloat_RealAdmin(play)
			admstr = "(true admin)"
		elseif Bloat_CheckAdmin(play)
			admstr = "(bloat promoted)"
		end
		
		prn(p, ("[%.2d] - %s\t%s"):format(
			#play, play.name, admstr
		))
	end
end, noadmin = true})

CMDConstructor("jail", {prefix = CMD_PREFIX, func = function(p,...)
	local args = {...}
	local node = args[1] or ""
	if node == "@all"
		for play in players.iterate
			play.jailed = not $
		end
	elseif node == "@others"
		for play in players.iterate
			if play == p then continue end
			play.jailed = not $
		end
	elseif node == "@nonadmins"
		for play in players.iterate
			if Bloat_CheckAdmin(play) then continue end
			play.jailed = not $
		end
	end
	
	local p2 = GetPlayer(p,node)
	if not p2
		prn(p, "sb_jail [player]: lol")
		return
	end
	
	p2.jailed = not $
end, flags = COM_ADMIN})

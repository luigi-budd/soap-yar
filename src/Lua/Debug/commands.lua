local prn = CONS_Printf
local SOAP_DEVPREFIX = "sd_"

rawset(_G,"SOAP_DEBUG", 0)
rawset(_G,"DEBUGTOENUM", {})

local function enumflags(prefix, enums, callback)
	for k,enum in ipairs(enums)
		local val = 1<<(k-1)
		assert(val ~= -1,"\x85Ran out of bits for "..prefix.."! (k="..k..")\x80")
		
		rawset(_G,prefix..enum,val)
		print("Enummed "..prefix..""..enum.." ("..val..")")
		
		if callback ~= nil
			callback(k,enum,val)
		end
	end
end

enumflags("DEBUG_",{
	"POWERS",
}, function(k,enum,val)
	DEBUGTOENUM[val] = enum
end)


local function NotInLevel()
	return not (gamestate == GS_LEVEL or gamestate == GS_DEDICATEDSERVER)
end

/* @props = {
	prefix = string :: Command name prefix
	outoflevels = boolean :: Don't check for level-ness beforehand if true
	checksoap = boolean :: Check for player.soaptable
	flags = INT32 :: Command flags
} */
local function CMDConstructor(name, props)
	COM_AddCommand((props.prefix or '')..name,function(p, ...)
		if not props.outoflevels
		and NotInLevel()
			prn(p, "You must be in a level to use this.")
		end
		if props.checksoap
		and not p.soaptable
			prn(p, "You can't use this right now.")
		end
		
		props.func(p, ...)
	end,COM_ADMIN|(props.flags or 0))
end

local shields = {
	["n"] = SH_NONE,
	["p"] = SH_PITY,
	["w"] = SH_WHIRLWIND,
	["a"] = SH_ARMAGEDDON,
	["pk"] = SH_PINK,
	["e"] = SH_ELEMENTAL,
	["m"] = SH_ATTRACT,
	["fa"] = SH_FLAMEAURA,
	["b"] = SH_BUBBLEWRAP,
	["t"] = SH_THUNDERCOIN,
	["f"] = SH_FORCE|1,
	["ff"] = SH_FIREFLOWER,
}
CMDConstructor("shield", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	local sh = args[1]
	local hp = args[2]
	
	if sh == nil
		prn(p, SOAP_DEVPREFIX.."shield <shieldname> [<arg2>]")
		prn(p, "shieldnames:")
		prn(p, "	n	- none")
		prn(p, "	p	- pity")
		prn(p, "	w	- whirlwind")
		prn(p, "	a	- armageddon")
		prn(p, "	pk	- pink")
		prn(p, "	e	- elemental")
		prn(p, "	m	- attraction")
		prn(p, "	fa	- flame")
		prn(p, "	b	- bubble")
		prn(p, "	t	- thunder")
		prn(p, "	ff	- fireflower")
		prn(p, "	f	- force <arg2 = hp [0-255]>")
		prn(p, "set <shieldname> to setbits for more options")
		return		
	end

	sh = string.lower($)
	if not (sh == "setbit" or sh == "setbits")
		hp = abs(tonumber($) or 0)
		
		if shields[sh] ~= nil
			local shield = shields[sh]
			if shields[sh] ~= SH_NONE
				P_SpawnShieldOrb(p)
				if shield & SH_FORCE
					shield = SH_FORCE|hp
				end
				p.powers[pw_shield] = $ &~SH_STACK
				p.realmo.color = p.skincolor
			else
				P_RemoveShield(p)
				shield = SH_NONE
				p.powers[pw_shield] = $ &~SH_STACK
				p.realmo.color = p.skincolor
			end
			P_SwitchShield(p,shield)
			if sh == "ff"
				p.realmo.color = SKINCOLOR_WHITE
			end
		end
	else
		hp = abs(tonumber($) or 0)
		
		if hp == 0
			prn(p,"Second argument must be bits to be set.")
			prn(p,(1).."    - SH_PITY")
			prn(p,(2).."    - SH_WHIRLWIND")
			prn(p,(3).."    - SH_ARMAGEDDON")
			prn(p,(4).."    - SH_PINK")
			prn(p,(256).."  - SH_FORCE (255 & under = HP)")
			prn(p,(512).."  - SH_FIREFLOWER")
			prn(p,(1024).." - SH_PROTECTFIRE")
			prn(p,(2048).." - SH_PROTECTWATER")
			prn(p,(4096).." - SH_PROTECTELECTRIC")
			prn(p,(8192).." - SH_PROTECTSPIKE")
			return
		end
		
		p.powers[pw_shield] = hp
		P_SpawnShieldOrb(p)
	end
end})

CMDConstructor("debug", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	if not #args
		prn(p, "Current flags enabled:")
		local buf = ""
		for i = 0,31
			if SOAP_DEBUG & (1 << i)
				buf = $ .. DEBUGTOENUM[(1 << i)] .."\t"
			end
		end
		if buf == "" then buf = "None" end
		prn(p, buf)
		return
	end

	for _, enum in ipairs(args)
		local todo = string.upper(enum)
		local realnum = _G["DEBUG_"..todo] or 0
		if realnum ~= 0
			if SOAP_DEBUG & realnum
				SOAP_DEBUG = $ &~realnum
			else
				SOAP_DEBUG = $|realnum
			end
		else
			prn(p,"Flag invalid ("..todo..")")
		end
	end
end,flags = COM_LOCAL})

CMDConstructor("die", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	local type = args[1]
	if type == nil then return end
	
	type = string.upper($)
	type = _G["DMG_"..type] or DMG_INSTAKILL
	P_KillMobj(p.realmo,nil,nil,type)
	p.soaptable.deathtype = type
end})

CMDConstructor("scale", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	local scalemul = args[1]
	
	scalemul = tofixed($)
	if scalemul == 0
	or scalemul == nil
		prn(p, "Scale not valid.")
		return
	end
	
	p.realmo.destscale = scalemul
end})

CMDConstructor("leave", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	P_DoPlayerExit(p)
	p.exiting = 4
	p.pflags = $|PF_FINISHED
end})

local valid_flagprefixes = {
	["MF"] = true,		--object flags
	["MF2"] = true,		--object flags2
	["MFE"] = true,		--object eflags
	["PF"] = true,		--player flags
	["SF"] = true,		--player charflags
	["RF"] = true,		--object renderflags
	["AST"] = true,		--object blendmode
}
local valid_flagprefixesTOudata = {
	["MF"] = "flags",		--object flags
	["MF2"] = "flags2",		--object flags2
	["MFE"] = "eflags",		--object eflags
	["PF"] = "pflags",		--player flags
	["SF"] = "charflags",		--player charflags
	["RF"] = "renderflags",		--object renderflags
	["AST"] = "blendmode",		--object blendmode
}
CMDConstructor("toggleflags", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	if not #args
		prn(p, "\x82"..SOAP_DEVPREFIX.."_toggleflags <prefix> <name>\x80: Adds/removes flags from your mobj. Available prefixes:")
		for prefix,_ in pairs(valid_flagprefixes)
			prn(p, "\t\x83"..prefix)
		end
		return
	end
	
	local prefix
	local source = p.realmo
	local userdata
	for num, enum in ipairs(args)
		local work = string.upper(enum)
		if num == 1
			if valid_flagprefixes[work] ~= true
				prn(p, "\x85Unknown prefix '"..work.."'")
				return
			end
			if work == "PF" or work == "SF"
				source = p
			end
			prefix = work
			userdata = valid_flagprefixesTOudata[work]
			continue
		else
			--if the first couple of characters are equal to the prefix (ex. "MF2_"),
			--remove those letters so we can easily paste in flags from like
			--the wiki or whatever lol
			if (work:sub(1, prefix:len() + 1) == prefix.."_")
				work = $:sub(prefix:len() + 2)
			end
		end
		
		local flag = _G[prefix.."_"..work]
		if flag == nil
			prn(p,"Unknown flag '"..work.."'")
			continue
		end
		
		--blend modes are special
		if prefix == "AST"
			source[userdata] = flag
			prn(p,"Set '"..prefix.."_"..work.."' on yourself")
		else
			source[userdata] = $ ^^ flag
			if source[userdata] & flag
				prn(p,"Added flag '"..prefix.."_"..work.."' to yourself")
			else
				prn(p,"Removed flag '"..prefix.."_"..work.."' from yourself")
			end
		end
	end
end})

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

local function TPEffects(p,me, angle)
	p.cmomx,p.cmomy,p.speed = 0,0,0
	me.momx = 0
	me.momy = 0
	me.momz = 0
	
	P_ResetPlayer(p)
	me.reactiontime = TR/2
	me.state = S_PLAY_STND
	
	me.angle = angle
	p.drawangle = me.angle

	if P_IsLocalPlayer(p)
		P_ResetCamera(p, p == secondarydisplayplayer and camera2 or camera)
	end
	P_FlashPal(p, PAL_MIXUP, 10)
	S_StartSound(me,sfx_mixup,p)
end

CMDConstructor("goto", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	local node = args[1]
	if node == nil
		prn(p, "goto <name/node>: Teleports you to a player.")
		return
	end
	
	local me = p.realmo
	
	local p2 = GetPlayer(p,node)
	if p2
		local mo = p2.realmo
		if not (mo and mo.valid)
			prn(p,"This person's object isn't valid.")
			return
		end
		
		P_SetOrigin(me,mo.x,mo.y,mo.z)
		TPEffects(p,me, mo.angle)
	end	
end})
CMDConstructor("bring", {prefix = SOAP_DEVPREFIX, func = function(p,...)
	local args = {...}
	local node = args[1]
	if node == nil
		prn(p, "bring <name/node>: Brings a player to you. \x82Special node commands:")
		prn(p, "\t\x82@all:\x80 Brings everyone in the server")
		return
	end
	
	local me = p.realmo
	
	if node == "@all"
		for p2 in players.iterate
			if p2 == p then continue end
			if not (p2.realmo and p2.realmo.valid) then continue end
			
			P_SetOrigin(p2.realmo, me.x,me.y,me.z)
			TPEffects(p2,p2.realmo, me.angle)
		end
		return
	end
	
	local p2 = GetPlayer(p,node)
	if p2
		local mo = p2.realmo
		if not (mo and mo.valid)
			prn(p,"This person's object isn't valid.")
			return
		end
		
		P_SetOrigin(mo, me.x,me.y,me.z)
		TPEffects(p2,mo, me.angle)
	end	
end})
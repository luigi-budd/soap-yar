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

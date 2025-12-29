local mbrelease = dofile("Vars/mbrelease.lua")
--who even is this guy anyways
local not_in_mb = {
	--["character/LUA_takisinit.lua"] = true,
	--["character/LUA_takisfunc.lua"] = true,
	["character/LUA_takis.lua"] = true,
}

rawset(_G,"MENULIB_ROOT","Libs/Menulib/")
dofile(MENULIB_ROOT .. "exec.lua")
local filetree = {
	"LUA_init.lua",
	--math is important so run it up here
	"libs/LUA_math.lua",
	"LUA_console.lua",
	
	"libs/LUA_takishooklib.lua",
	"libs/LUA_hitlag.lua",
	"libs/LUA_world2screen.lua",
	"libs/LUA_customhud.lua",
	
	"character/LUA_tauntwheel.lua",
	--character inits MUST be run before any of their thinkers/funcs!
	"character/LUA_soapinit.lua",
	"character/LUA_soapfunc.lua",
	"character/LUA_takisinit.lua",
	"character/LUA_takisfunc.lua",
	
	"LUA_main.lua",
	
	"character/LUA_soap.lua",
	"character/LUA_takis.lua",
	--character hud
	"HUD/main.lua",
	
	"menus/LUA_main.lua",
	
	"LUA_thook.lua",
	"LUA_misc.lua",
	"LUA_compat.lua",
	"LUA_clientsave.lua",
	"LUA_watermark.lua",
}
local badfiles = {}

local function strapper(file)
	local loaded = loadfile(file)
	if type(loaded) == "string"
		error(string.format("\x85Something went wrong, but we couldn't find out why. Report the bug and send the latest-log.txt.\n     \x86(got: \"%s\")", loaded),2)
	end
	loaded()
end

local filesrangood = true
for k,file in ipairs(filetree)
	if mbrelease and not_in_mb[file] ~= nil
		continue
	end
	local status,result = pcall(strapper,file)
	if not status
		filesrangood = false
		table.insert(badfiles, {filename = file, reason = result})
	end
end

if not filesrangood
	S_StartSound(nil,sfx_skid)
	print("\x85WARNING: One or more files were not loaded properly")
end
for k,info in ipairs(badfiles)
	local filename = info.filename
	local reason = info.reason
	print('\x82* "'..filename..'\x82"\x85 FAILED')
	print('   \x82->\x80'..tostring(reason))
end

local compver,compdate = (loadfile("Vars/compver.lua"))(), (loadfile("Vars/compdate.lua"))()
rawset(_G,"Soap_PrintCompInfo",function(p)
	local str = {
		"\x82".."Compile info:",
		string.format("compver: %s\x80\t".."compdate: %s",compver,compdate),
	}
	for k, string in ipairs(str)
		if (p and p.valid)
			CONS_Printf(p, string)
		else
			print(string)
		end
	end
end)
Soap_PrintCompInfo()
print("\x89Made with love - EpixGamer21")

COM_AddCommand("soap_compdata",function(p)
	Soap_PrintCompInfo(p)
end)

/*
	CREDITS:
	
	- CoolThok (@tetract_) : Giving me their funny death sound lul ("sfx_sp_kco")
	- Paper Peelout : Peelout sprites
*/
local filetree = {
	"LUA_init.lua",
	"LUA_console.lua",
	--math is important so run it up here
	"libs/LUA_math.lua",
	
	"libs/LUA_takishooklib.lua",
	"libs/LUA_hitlag.lua",
	
	"character/LUA_soapfunc.lua",
	"character/LUA_takisfunc.lua",
	
	"LUA_main.lua",
	
	"character/LUA_soap.lua",
	"character/LUA_takis.lua",
	
	"LUA_thook.lua",
	"LUA_misc.lua",
	"LUA_compat.lua",
}
local badfiles = {}

local filesrangood = true
for k,file in ipairs(filetree)
	local status,result = pcall(do (loadfile(file))() end)
	if not status
		filesrangood = false
		table.insert(badfiles, file)
	end
end

if not filesrangood
	S_StartSound(nil,sfx_skid)
	print("\x85One or more files were not loaded properly")
end
for k,filename in ipairs(badfiles)
	print('\x82"'..filename..'\x82"\x85 FAILED')
end

/*
	CREDITS:
	
	- CoolThok (@tetract_) : Giving me their funny death sound lul
	- Paper Peelout : Peelout sprites
*/
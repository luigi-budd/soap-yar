--Soap-NOABILity, since takis uses NOABIL_
Soap_EnumFlags("SNOABIL_", {
	"RDASH",
	"AIRDASH",
	"UPPERCUT",
	"POUND",
	--maybe?
	"TOP",
	"TAUNTS",
	"CROUCH", -- used for sliding now
	"BREAKDANCE",
})
local function fakeenum(name,val)
	rawset(_G,name,val)
	print("Ennumed "..name.." ("..val..")")
end

--yeah just set all the bits lol
--noability macros/shortcuts (there is no preprocessor anymore)
fakeenum("SNOABIL_ALL",INT32_MAX)

fakeenum("SNOABIL_TAUNTSONLY",
	SNOABIL_ALL &~(SNOABIL_TAUNTS|SNOABIL_BREAKDANCE)
)

fakeenum("SNOABIL_BOTHTAUNTS",
	SNOABIL_TAUNTS|SNOABIL_BREAKDANCE
)

-- if either characters charabilities arent set to
-- CA_SOAPMOVE or CA2_SOAPMOVE, then all NOABIL_*s will be applied
rawset(_G,"CA_SOAPMOVE", 140)
rawset(_G,"CA2_SOAPMOVE", 140)

local includes = {
	"mobjs.lua",
	"funny.lua",
	"sounds.lua",
	"player.lua",
	"boombox.lua",
	"spiderman.lua",
}
for k,file in ipairs(includes)
	dofile("Character/SoapInclude/"..file)
end
--TODO: all soap freeslots and constants go here

--Soap-NOABILity, since takis uses NOABIL_
Soap_EnumFlags("SNOABIL_", {
	"RDASH",
	"AIRDASH",
	"UPPERCUT",
	"POUND",
	--maybe?
	"TOP",
	"TAUNTS",
	"CROUCH",
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
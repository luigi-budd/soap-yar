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
--yeah just set all the bits lol
--noability macros/shortcuts (there is no preprocessor anymore)
rawset(_G, "SNOABIL_ALL",
	INT32_MAX
)
rawset(_G, "SNOABIL_TAUNTSONLY",
	SNOABIL_ALL &~(SNOABIL_TAUNTS|SNOABIL_BREAKDANCE)
)
rawset(_G, "SNOABIL_BOTHTAUNTS",
	SNOABIL_TAUNTS|SNOABIL_BREAKDANCE
)
--takis gets his noabil enums back lol
Soap_EnumFlags("NOABIL_", {
	"CLUTCH",
	"HAMMER",
	"DIVE",
	"SLIDE",
	"SHIELD",
	"THOK",
	"AFTERIMAGE",	--i wouldnt really call afterimages an ability
	
	"SHOTGUN", --HOLDOVER: remove all remnants
})
local function fakeenum(name,val)
	rawset(_G,name,val)
	print("Ennumed "..name.." ("..val..")")
end

--remove the 'S' for consistancy's sake
fakeenum("NOABIL_ALL",SNOABIL_ALL)

rawset(_G, "TAKIS_HAMMERDISP", FixedMul(52*FU,9*FU/10))

local includes = {
	"sounds.lua",
}
for k,file in ipairs(includes)
	dofile("Character/TakisInclude/"..file)
end
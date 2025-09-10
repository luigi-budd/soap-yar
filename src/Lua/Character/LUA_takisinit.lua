--takis gets his noabil enums back lol
Soap_EnumFlags("NOABIL_", {
	"CLUTCH",
	"HAMMER",
	"DIVE",
	"SLIDE",
	"SHIELD",
	"THOK",
	"AFTERIMAGE",	--i wouldnt really call afterimages an ability
})
local function fakeenum(name,val)
	rawset(_G,name,val)
	print("Ennumed "..name.." ("..val..")")
end

--remove the 'S' for consistancy's sake
fakeenum("NOABIL_ALL",SNOABIL_ALL)

local includes = {
	"sounds.lua",
}
for k,file in ipairs(includes)
	dofile("Character/TakisInclude/"..file)
end
rawset(_G, "SOAP_MENUS",{})

local path = "menus/items/LUA_"
local tree = {
	"options"
}

for k,name in ipairs(tree)
	dofile(path .. name)
end
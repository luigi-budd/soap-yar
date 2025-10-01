rawset(_G, "SOAP_CV",{})
local CV = SOAP_CV

local iAmLua = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) iAmLua = n($); end)

local function CVSynched_CanChange(cv, value)
	if gamestate ~= GS_LEVEL
		-- its whatever, itll still be synched when we join a game
		if (gamestate == GS_TITLESCREEN)
			return true
		end
		print("You must be in a level to use this.")
		return false
	end
	
	if not (consoleplayer and consoleplayer.valid and consoleplayer.soaptable)
		print("You must be in a level to use this.")
		return false
	end
	return true
end

local CMD_BOOLEAN = 1
local CMD_STRING = 2
local function CMD_Constructor(cv_name, tablename, type)
	COM_AddCommand("_soap_"..cv_name, function(p, ...)
		if gamestate ~= GS_LEVEL then return end
		local args = {...}
		local sig = args[1]
		if sig ~= iAmLua then return end
		local value = args[2]
		
		local soap = p.soaptable
		
		if type == CMD_BOOLEAN
			soap.io[tablename] = (tonumber(value) == 1)
		elseif type == CMD_STRING
			soap.io[tablename] = tostring(value):lower()
		else
			print("\x83SOAP:\x80 bad value passed to _soap_"..cv_name.." ("..p.name..")")
		end
	end)
end

CV.ai_style = CV_RegisterVar({
	name = "soap_afterimagestyle",
	defaultvalue = "Opposite",
	flags = CV_SHOWMODIF,
	PossibleValue = {Rainbow = 0, Opposite = 1, Classic = 2},
})

CV.quake_mul = CV_RegisterVar({
	name = "soap_quakes",
	defaultvalue = "Normal",
	flags = CV_SHOWMODIF,
	PossibleValue = {Off = 0, Half = 1, Normal = 2, Double = 3},
})

--these will need to be synched
CV.crouch_toggle = CV_RegisterVar({
	name = "soap_airdashmode",
	defaultvalue = "Inputs", --MUST have matching init values in soaptable
	flags = CV_CALL,
	PossibleValue = {Inputs = 0, Camera = 1},
	can_change = CVSynched_CanChange,
	func = function(cv)
		COM_BufInsertText(consoleplayer, "_soap_airdashmode "..iAmLua.." "..cv.value)
	end,
})
CMD_Constructor("airdashmode", "airdashmode", CMD_STRING)

local CV_Lookup = {}
setmetatable(CV_Lookup, {
	__mode = "kv"
})

CV.FindVar = function(cv_name)
	if CV_Lookup[cv_name]
		return CV_Lookup[cv_name]
	end
	local cvar = CV_FindVar(cv_name)
	CV_Lookup[cv_name] = cvar
	return cvar
end
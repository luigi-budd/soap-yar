rawset(_G, "SOAP_CV",{})
local CV = SOAP_CV
local iAmLua = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) iAmLua = n($); end)

local function CVSynched_CanChange(cv, value)
	if gamestate ~= GS_LEVEL
	or not (consoleplayer and consoleplayer.valid and consoleplayer.soaptable)
		print("You must be in a level to use this.")
		return false
	end
	return true
end

local CMD_BOOLEAN = 1
local function CMD_Constructor(name, tablename, type)
	COM_AddCommand("_soap_"..name, function(p, ...)
		if gamestate ~= GS_LEVEL then return end
		local args = {...}
		local sig = args[1]
		if sig ~= iAmLua then return end
		local value = args[2]
		
		local soap = p.soaptable
		if type == CMD_BOOLEAN
			soap.io[tablename] = (tonumber(value) == 1)
		end
	end)
end

CMD_Constructor("crouchtoggle", "crouch_toggle", CMD_BOOLEAN)

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
	name = "soap_crouchtoggle",
	defaultvalue = "No", --MUST have matching init values in soaptable
	flags = CV_CALL,
	PossibleValue = CV_YesNo,
	can_change = CVSynched_CanChange,
	func = function(cv)
		COM_BufInsertText(consoleplayer, "_soap_crouchtoggle "..iAmLua.." "..cv.value)
	end,
})


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
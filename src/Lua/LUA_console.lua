rawset(_G, "SOAP_CV",{})
local CV = SOAP_CV
CV.PossibleValues = {}

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
CV.commandtypes = {}

local function CMD_Constructor(cv_name, tablename, type)
	CV.commandtypes["_soap_"..cv_name] = type
	COM_AddCommand("_soap_"..cv_name, function(p, ...)
		if gamestate ~= GS_LEVEL then return end
		local args = {...}
		local sig = args[1]
		if sig ~= iAmLua then return end
		local value = args[2]
		
		local soap = p.soaptable
		local type = CV.commandtypes["_soap_"..cv_name]
		if type == CMD_BOOLEAN
			soap.io[tablename] = (tonumber(value) == 1)
		elseif type == CMD_STRING
			soap.io[tablename] = tostring(value):lower()
		else
			print("\x83SOAP:\x80 bad value passed to _soap_"..cv_name.." ("..p.name..")")
		end
	end)
end

local ai_pv = {Rainbow = 0, Opposite = 1, Classic = 2, Retro = 3}
CV.ai_style = CV_RegisterVar({
	name = "soap_afterimagestyle",
	defaultvalue = "Opposite",
	flags = CV_SHOWMODIF,
	PossibleValue = ai_pv,
})
CV.PossibleValues["soap_afterimagestyle"] = {values = ai_pv, length = 4}

local quake_pv = {Off = 0, Half = 1, Normal = 2, Double = 3}
CV.quake_mul = CV_RegisterVar({
	name = "soap_quakes",
	defaultvalue = "Normal",
	flags = CV_SHOWMODIF,
	PossibleValue = quake_pv,
})
CV.PossibleValues["soap_quakes"] = {values = quake_pv, length = 4}

CV.taunt_key = CV_RegisterVar({
	name = "soap_tauntkey",
	defaultvalue = "B",
	flags = CV_SHOWMODIF,
})

-- cvars below here will need to be synched
-- as of 2.2.15, because these all have a `can_change` field,
-- we cant get the consvar_t directly from the CV_RegisterVar call
-- see also: https://git.do.srb2.org/STJr/SRB2/-/merge_requests/2753

CMD_Constructor("b-rushmode", "airdashmode", CMD_STRING)
local brush_pv = {Inputs = 0, Camera = 1}
CV.SYNC_airdashmode = CV_RegisterVar({
	name = "soap_b-rushmode",
	defaultvalue = "Inputs", --MUST have matching init values in soaptable
	flags = CV_CALL,
	PossibleValue = brush_pv,
	func = function(cv)
		COM_BufInsertText(consoleplayer, "_soap_b-rushmode "..iAmLua.." "..cv.string)
	end,
	can_change = CVSynched_CanChange,
})
CV.SYNC_airdashmode = CV.FindVar("soap_b-rushmode")
CV.PossibleValues["soap_b-rushmode"] = {values = brush_pv, length = 2}

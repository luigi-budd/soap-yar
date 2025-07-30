rawset(_G, "SOAP_CV",{})
local CV = SOAP_CV

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
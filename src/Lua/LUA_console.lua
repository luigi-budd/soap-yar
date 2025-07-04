rawset(_G, "SOAP_CV",{})
local CV = SOAP_CV

CV.rainbow_ai = CV_RegisterVar({
	name = "soap_rainbowimages",
	defaultvalue = "Off",
	flags = CV_SHOWMODIF,
	PossibleValue = CV_OnOff
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
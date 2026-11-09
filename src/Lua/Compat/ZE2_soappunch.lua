local P_RandomFixed = P_RandomFixed
local Soap_RandomFixedRange = Soap_RandomFixedRange
local Vec3 = Vec3
local Soap_DustRing = Soap_DustRing

local cv_friendlyfire = SOAP_CV.FindVar("friendlyfire")
local function FriendlyFire()
	local gt_settings = xSlinger.getGametypeSettings()
	return cv_friendlyfire.value or gt_settings.friendlyfire
end

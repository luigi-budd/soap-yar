local soaptaunt = SOAP_TAUNTS[SOAP_SKIN][1]
local tauntinfo = {}

tauntinfo.name = "Smugness"

tauntinfo.run = soaptaunt.run
tauntinfo.think = soaptaunt.think
tauntinfo.postthink = soaptaunt.postthink
tauntinfo.drawer = soaptaunt.drawer
tauntinfo.canceled = soaptaunt.canceled

SoapTaunt_AddTaunt(TAKIS_SKIN, tauntinfo)
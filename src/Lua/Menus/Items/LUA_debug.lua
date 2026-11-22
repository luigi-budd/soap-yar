-- debug menu for debug commands for debug people

local ML = MenuLib
local CV = SOAP_CV

ML.addMenu({
	stringId = "soap_debug",
	
	x = 320 - 120 - 10,
	y = 100 - 80,
	
	width = 120,
	height = 160,
	color = 27,
	outline = 30,
	
	title = "Debug",
	ps_flags = PS_NOSLIDEIN|PS_NOFADE|PS_DRAWTITLE,
	
	init = function()
	end,
	drawer = function(v, ML, menu, props)
		
	end
})

COM_AddCommand("sd_menu", function(p)
	if gamestate ~= GS_LEVEL then return end
	if ML.client.currentMenu.id ~= -1 then return end
	if #ML.client.popups then return end
	
	ML.initPopup(ML.findMenu("soap_debug"))
end, COM_LOCAL)
-- returns true if no menu NOR popups are open
local ML = MenuLib
return function()
	if (#ML.client.popups == 0 and ML.client.currentMenu.id == -1)
		return true
	end
	return false
end
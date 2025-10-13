local ML = MenuLib
local buffer = ""
local bufferid = ML.newBufferID()

local com_buffer = ""
local com_bufferid = ML.newBufferID()

ML.addMenu({
	stringId = "BoobMenu",
	title = "Booooooob",
	
	drawer = function(v, ML, menu, props)
		local corner_x = props.corner_x + 10
		local corner_y = props.corner_y + 18
		
		v.draw(corner_x + 2,
			corner_y + 22,
			v.cachePatch("MISSING"),
			0
		)
		
		ML.addButton(v, {
			id = 1,
			
			y = corner_y + 52,
			
			width = 68,
			height = 20,
			
			name = "Template",
			color = 5,
			
			selected = {
				color = 83
			},
			template = {x = corner_x},
		})
		
		ML.addButton(v, {
			id = 1,
			
			x = corner_x,
			y = corner_y,
			
			width = 68,
			height = 20,
			
			name = "Text input",
			color = 5,
			
			selected = {
				color = 83
			},
			
			pressFunc = function()
				print("Text input started")
				ML.startTextInput(buffer, bufferid, {
					onenter = function()
						buffer = ML.client.textbuffer
					end,
					tooltip = {
						"Type whatever.",
						"Multi-line tooltip test"
					}
				})
			end
		})
		v.drawString(corner_x,corner_y + menu.height/2,
			"buffer: "..buffer,
			V_ALLOWLOWERCASE,
			"thin"
		)
		
		ML.addButton(v, {
			id = 2,
			
			x = corner_x + 70,
			y = corner_y,
			
			width = 68,
			height = 20,
			
			name = "Command",
			color = 6,
			
			selected = {
				color = 83
			},
			
			pressFunc = function()
				ML.startTextInput(com_buffer, com_bufferid, {
					onenter = function()
						ML.client.commandbuffer = ML.client.textbuffer
						com_buffer = ""
					end,
					tooltip = "Type a command..."
				})
			end
		})
		
		ML.addButton(v, {
			id = 3,
			
			x = corner_x + 140,
			y = corner_y,
			
			width = 68,
			height = 20,
			
			name = "Popup",
			color = 7,
			
			selected = {
				color = 83
			},
			
			pressFunc = function()
				ML.initPopup(ML.findMenu("BoobPopup"))
			end
		})
		
		ML.addButton(v, {
			id = 4,
			
			x = corner_x + 210,
			y = corner_y,
			
			width = 68,
			height = 20,
			
			name = "Popup",
			color = 8,
			
			selected = {
				color = 83
			},
			
			pressFunc = function()
				ML.initMenu(ML.findMenu("BoobMenu2"))
			end
		})
	end,
})

ML.addMenu({
	stringId = "BoobMenu2",
	title = "Boob-SubMenu",
	outline = 13,
	width = 100,

	drawer = function(v, ML, menu, props)
		local corner_x = props.corner_x + 10
		local corner_y = props.corner_y + 18
		
		ML.addButton(v, {
			id = 1,
			
			x = corner_x,
			y = corner_y,
			
			width = 80,
			height = 50,
			
			name = "Go Deeper!",
			color = 5,
			
			selected = {
				color = 83
			},
			
			pressFunc = function()
				ML.initMenu(ML.findMenu("BoobMenu3"))
			end
		})
	end
})
ML.addMenu({
	stringId = "BoobMenu3",
	title = "Boob-SubMenu-2",
	outline = 13,
	drawer = function(v, ML, menu, props)
		local corner_x = props.corner_x + 10
		local corner_y = props.corner_y + 18
		
		ML.addButton(v, {
			id = 1,
			
			x = corner_x,
			y = corner_y,
			
			width = 80,
			height = 50,
			
			name = "Close all",
			color = 5,
			
			selected = {
				color = 83
			},
			
			pressFunc = function()
				ML.initMenu(-2)
			end
		})
	end
})

ML.addMenu({
	stringId = "BoobPopup",
	title = "Pop Up",
	
	x = 10,
	y = 50,
	width = 100,
	height = 100,
	
	color = 155,
	outline = 159,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		v.drawString(x + 2, y + 2, "Popup", V_ALLOWLOWERCASE, "thin")
		
		ML.addButton(v, {
			x = x + 2,
			y = y + 15,
			name = "popup 2",
			width = 50,
			height = 15,
			color = 5,
			
			pressFunc = function()
				ML.initPopup(ML.findMenu("BoobPopup2"))
			end
		})
	end
})

ML.addMenu({
	stringId = "BoobPopup2",
	title = "Another Popup!",
	
	x = 160,
	y = 50,
	width = 140,
	height = 32,
	
	color = 43,
	outline = 47,
	ps_flags = PS_NOESCAPE,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		v.drawString(x + 2, y + 2, "Another Popup!", V_ALLOWLOWERCASE, "thin")
		
		ML.addButton(v, {
			x = x + 2,
			y = y + 15,
			name = "popup 3",
			width = 50,
			height = 15,
			color = 5,
			
			pressFunc = function()
				ML.initPopup(ML.findMenu("BoobPopup3"))
			end
		})
	end
})

ML.addMenu({
	stringId = "BoobPopup3",
	title = "Another Popup!",
	
	x = 0,
	y = 0,
	width = 320,
	height = 200,
	
	color = 107,
	outline = 111,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		v.drawString(x + 2, y + 2, "Big Popup", V_ALLOWLOWERCASE, "thin")
		
	end
})

addHook("KeyDown", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	
	if key.name == "f"
		if (#ML.client.popups)
			ML.initPopup(-1)
		else
			ML.initMenu(1)
		end
	end
end)
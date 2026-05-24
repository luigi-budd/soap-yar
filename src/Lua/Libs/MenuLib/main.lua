local ML = MenuLib
local waittoupdate = false --for mouse
local waittoupdate_esc = false

ML.mainThinker = function()
	if ML.client.doMousePress
		if ML.client.mouseTime == -1
			ML.client.mouseTime = 0
		else
			ML.client.doMousePress = false
			ML.client.mouseTime = -1
		end
	end
	if not waittoupdate
		if ML.client.mouseHeld == 1
			ML.client.mouseHeld = 2
		elseif ML.client.mouseHeld == -1
			ML.client.mouseHeld = 0
		end
	end
	waittoupdate = false
	
	if ML.client.doEscapePress
		if ML.client.escapeTime == -1
			ML.client.escapeTime = 0
		else
			ML.client.doEscapePress = false
			ML.client.escapeTime = -1
		end
	end
	if not waittoupdate_esc
		if ML.client.escapeHeld == 1
			ML.client.escapeHeld = 2
		elseif ML.client.escapeHeld == -1
			ML.client.escapeHeld = 0
		end
	end
	waittoupdate_esc = false

	if ML.client.commandbuffer ~= nil
		COM_BufInsertText(consoleplayer,ML.client.commandbuffer)
		ML.client.commandbuffer = nil
	end
	
	ML.client.menuactive = false
	if ML.noMenuOpenAtAll()
		ML.client.currentMenu.layers = {}
		ML.client.menuTime = 0
		return
	end
	ML.client.menuactive = true
	ML.client.menuTime = $ + 1
	
	ML.client.mouse_x = $ + mouse.dx * 3700
	ML.client.mouse_y = $ + mouse.dy * 3700
	
	ML.client.mouse_x = ML.clamp(0, $, BASEVIDWIDTH*FU)
	ML.client.mouse_y = ML.clamp(0, $, BASEVIDHEIGHT*FU)
end

--keyhandler object stuff
ML.keyhandlerThinker_KD = function(key)
	if isdedicatedserver then return end
	
	if key.name == "lctrl"
	or key.name == "rctrl"
		ML.client.text_ctrldown = true
	end
	
	if key.name == "lshift"
	or key.name == "rshift"
		ML.client.text_shiftdown = true
	end
	
	if key.name == "caps lock"
	and not key.repeated
		ML.client.text_capslock = not $
	end
	
	if ML.client.textbuffer ~= nil
		local keydown = false
		ML.client.textbuffer,keydown = ML.keyHandler(key, ML.client.textbuffer)
		if keydown then return true; end
	end
end
ML.keyhandlerThinker_KU = function(key)
	if isdedicatedserver then return end
	
	if key.name == "lctrl"
	or key.name == "rctrl"
		ML.client.text_ctrldown = false
	end
	
	if key.name == "lshift"
	or key.name == "rshift"
		ML.client.text_shiftdown = false
	end
	
	--lul
	if key.name == "mouse1"
		ML.client.mouseHeld = -1
		waittoupdate = true
	end

	if key.name == "escape"
		ML.client.escapeHeld = -1
		waittoupdate_esc = true
	end
end

ML.controlHandler = function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	
	if (ML.client.menuTime < 2)
		ML.client.doMousePress = false
		ML.client.mouseTime = -1
		return
	end
	
	if key.name == "mouse1"
	and (ML.client.textbuffer_id == nil)
		ML.client.doMousePress = true
		ML.client.mouseHeld = 1
		waittoupdate = true
	elseif key.name == "escape"
	and not chatactive
		if (ML.client.textbuffer_id == nil)
			if #ML.client.popups
				if ML.menus[ML.client.popups[#ML.client.popups].id].ps_flags & PS_NOESCAPE --holy SHIT
					--do nothing
				else
					ML.initPopup(-1)
				end
			else
				if ML.menus[ML.client.currentMenu.id].ms_flags & MS_NOESCAPE
					-- do nothing
				else
					ML.initMenu(-1)
				end
			end
		else
			if ML.client.textbuffer_funcs.close ~= nil
				if ML.client.textbuffer_funcs.close()
					return true
				end
			end
			ML.stopTextInput()
		end
		ML.client.doEscapePress = true
		ML.client.escapeHeld = 1
		waittoupdate_esc = true
		return true
	elseif key.name == "enter"
	and not chatactive
	and (ML.client.textbuffer_id ~= nil)
		if ML.client.textbuffer_funcs.enter ~= nil
			ML.client.textbuffer_funcs.enter()
		end
		S_StartSound(nil,sfx_menu1,consoleplayer)
		ML.stopTextInput()
	end
end

if not ML.replacing
	addHook("PreThinkFrame", do
		ML.mainThinker()
	end)
	addHook("KeyDown", function(key)
		local res = ML.keyhandlerThinker_KD(key)
		if res ~= nil then return res end
	end)
	addHook("KeyUp", function(key)
		local res = ML.keyhandlerThinker_KU(key)
		if res ~= nil then return res end
	end)
	addHook("KeyDown", function(key)
		local res = ML.controlHandler(key)
		if res ~= nil then return res end
	end)
end
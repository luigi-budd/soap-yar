local ML = MenuLib
local CV = SOAP_CV

local widths = {
	["BIG"] = 12,
	["MEDIUM"] = 10,
	["SMALL"] = 8
}
SOAP_MENUS.drawRounded = function(v, x,y, w, size, clr)
	local wd = widths[size]
	if wd == nil then return end
	v.draw(x,y, v.cachePatch("SMENU_CIRC_"..size), 0, clr)
	v.drawStretched((x+(wd/2))*FU, y*FU, (w - wd)*FU, FU, v.cachePatch("SMENU_FILL_"..size),0, clr)
	v.draw(x+w,y, v.cachePatch("SMENU_CIRC_"..size), V_FLIP, clr)
end

local menu_buf = ""
local menu_bufid = MenuLib.newBufferID()

local sld_id = 0
local sld_grabbed = false
local sld_grabid = 0
local sld_lastvalue = 0
local sld_display = {
	id = -1, progress = 0, tics = 0
}

local highlite_index = 16
local highlite_strong = V_80TRANS
local highlite_weak = V_90TRANS
SOAP_MENUS.buttontoggle = function(v, x,y, width, props)
	if width <= 0 then return end
	local name = props.name
	local cv_name = props.cv_name
	local cv_type = props.cv_type
	local canPress = true
	if props.adminonly
	and not (IsPlayerAdmin(consoleplayer) or consoleplayer == server)
		canPress = false
	end
	
	sld_id = $ + 1
	SOAP_MENUS.drawRounded(v,x,y, width, "BIG", v.getColormap(TC_DEFAULT, SKINCOLOR_CARBON))
	
	v.drawString(x + 6, y + 1, name, V_ALLOWLOWERCASE, "left")
	
	local cv = CV.FindVar(cv_name)
	if cv_type == "boolean"
		local bwid = 29
		local bhalf = bwid - (10 + 2)
		local left = x + width - (bwid + 2)
		local hover = false
		if ML.mouseInZone(left,y+1, bwid,widths["MEDIUM"], false) and not sld_grabbed and canPress
			ML.client.canPressSomething = true
			hover = true
		end
		
		SOAP_MENUS.drawRounded(v, left, y + 1, bwid, "MEDIUM", v.getColormap(TC_DEFAULT,SKINCOLOR_BLACK))
		if hover
			for i = 1,10
				local x = left
				local w = bwid
				if (i == 1 or i == 10)
					x = $ + 3
					w = $ - 6
				elseif (i == 2 or i == 9)
					x = $ + 2
					w = $ - 4
				elseif (i == 3 or i == 8)
					x = $ + 1
					w = $ - 2
				end
				v.drawFill(x,y+i, w,1, highlite_index|((ML.client.mouseHeld > 0) and highlite_strong or highlite_weak))
			end
			if (ML.client.mouseHeld == -1)
				ML.client.commandbuffer = "toggle "..cv_name
				S_StartSound(nil,sfx_menu1)
			end
		end
		SOAP_MENUS.drawRounded(v, left + 1 + (bhalf*cv.value), y + 2, 10, "SMALL", v.getColormap(TC_DEFAULT,cv.value and SKINCOLOR_GREEN or SKINCOLOR_RED))
		v.drawString(left+3 + ((bhalf+7)*(1-cv.value)),y+3, cv.value and "On" or "Off", V_ALLOWLOWERCASE,cv.value and "thin" or "thin-right")
	elseif cv_type == "custom"
		local options = CV.PossibleValues[cv_name].values
		local items = CV.PossibleValues[cv_name].length
		local wid = (items * widths["SMALL"]) + 2
		local left = (x + width) - (wid + 2)
		
		local cv_str = '"'..cv.string..'"'
		local strwid = v.stringWidth(cv_str,0,"thin")+6
		
		local hover = false
		if ML.mouseInZone(left-strwid,y+1, wid+strwid,widths["MEDIUM"], false) and not sld_grabbed and canPress
			ML.client.canPressSomething = true
			hover = true
		end
		
		SOAP_MENUS.drawRounded(v, left-strwid, y + 1, wid+strwid, "MEDIUM", v.getColormap(TC_DEFAULT,SKINCOLOR_BLACK))
		SOAP_MENUS.drawRounded(v, left, y + 1, wid, "MEDIUM", v.getColormap(TC_DEFAULT,SKINCOLOR_BLACK))
		if hover
			for i = 1,10
				local x = left - strwid
				local w = wid + strwid
				if (i == 1 or i == 10)
					x = $ + 3
					w = $ - 6
				elseif (i == 2 or i == 9)
					x = $ + 2
					w = $ - 4
				elseif (i == 3 or i == 8)
					x = $ + 1
					w = $ - 2
				end
				v.drawFill(x,y+i, w,1, highlite_index|((ML.client.mouseHeld > 0) and highlite_strong or highlite_weak))
			end
			if (ML.client.mouseHeld == -1)
				ML.client.commandbuffer = cv_name.." "..((cv.value + 1) % items)
				S_StartSound(nil,sfx_menu1)
			end
		end
		for i = 0, items - 1
			if i == cv.value
				SOAP_MENUS.drawRounded(v, left + 1 + (8*i), y + 2, 8, "SMALL", v.getColormap(TC_DEFAULT,SKINCOLOR_GREEN))
			else
				v.drawFill(left + 4 + (8*i), y + 5, 2,2, 22)
			end
		end
		v.drawString(left - 2, y + 2, cv_str, V_ALLOWLOWERCASE|V_YELLOWMAP,"thin-right")
	elseif cv_type == "slider"
		local right = (x + width) - 4
		local hover = false
		local fixed = props.fixed
		
		y = $ + 1
		do
			local w = 20
			hover = ML.mouseInZone(right-w, y, w,10) and not sld_grabbed
			local c = 0
			if hover and canPress
				c = (ML.client.mouseHeld > 0) and 4 or 2
				ML.client.canPressSomething = true
				if (ML.client.mouseHeld == -1)
					S_StartSound(nil,sfx_menu1)
					ML.startTextInput(menu_buf,menu_bufid, {
						onenter = function()
							ML.client.commandbuffer = cv_name.." "..ML.client.textbuffer
							menu_buf = ""
						end,
						tooltip = cv_name.." \x86<"..(fixed and "decimal" or "integer")..">",
						--typesound = sfx_oldrad
					})
				end
			end
			v.drawFill((right - w),		y,   w,   10, 159 - c)
			v.drawFill((right - w)+1,	y+1, w-2, 1,  156 - c)
			v.drawFill((right - w)+1,	y+8, w-2, 1,  156 - c)
			v.drawFill((right - w+1),	y+1, 1,   8,  156 - c)
			v.drawFill((right - 2),		y+1, 1,   8,  156 - c)
			v.drawString(right - w/2, y, "...",0,"thin-center")
			right = $ - w
		end
		local slider_w = 70
		local slider_h = 10
		
		local str = (fixed and "%.1f" or "%d"):format(cv.value)
		local slider_move = 0
		local hovering = false
		do
			local startx = (right - slider_w)*FU
			local endx = (slider_w - 2)*FU
			local MIN = CV.PossibleValues[cv_name].min
			local MAX = CV.PossibleValues[cv_name].max
			if not fixed
				MIN = $ * FU
				MAX = $ * FU
			end
			
			if not sld_grabbed
				if ML.mouseInZone(startx, y*FU, slider_w*FU, slider_h*FU, true) and canPress
					hovering = true
					ML.client.mouse_graphic = "ML_RBLX_DHOVER"
					if ML.client.mouseHeld == 1
						sld_grabbed = true
						sld_grabid = sld_id
					end
				end
			elseif ML.client.mouseHeld == -1
			and sld_grabid == sld_id
				sld_grabbed = false
				sld_display.id = sld_id
				sld_display.tics = consoleplayer.cmd.latency + 1
				sld_display.progress = FixedDiv(sld_lastvalue - MIN, MAX - MIN)
				if not fixed then sld_lastvalue = $/FU; end
				ML.client.commandbuffer = cv_name.." "..(fixed and "%f" or "%d"):format(sld_lastvalue)
				sld_grabid = -1
			end
			
			if sld_grabbed and sld_grabid == sld_id
				ML.client.mouse_graphic = "ML_RBLX_DGRAB"
				local progress = ML.clamp(0, FixedDiv(ML.client.mouse_x - startx, endx), FU)
				slider_move = FixedMul(progress, endx)
				
				local final = MIN + FixedMul(MAX - MIN, progress)
				sld_lastvalue = final
				if not fixed then final = $/FU; end
				str = (fixed and "%.1f" or "%d"):format(final)
			else
				local value = fixed and (cv.value) or (cv.value*FU)
				local progress = ML.clamp(0, FixedDiv(value - MIN, MAX - MIN), FU)
				if sld_display.tics
				and sld_display.id == sld_id
					progress = sld_display.progress
					local final = MIN + FixedMul(MAX - MIN, progress)
					if not fixed then final = $/FU; end
					str = (fixed and "%.1f" or "%d"):format(final)
				end
				slider_move = FixedMul(progress, endx)				
			end
		end
		
		local strw = v.stringWidth(str,0,"thin")
		v.draw(right - slider_w - 1 - strw - widths["MEDIUM"]/2, y, v.cachePatch("SMENU_CIRC_MEDIUM"), 0, v.getColormap(TC_DEFAULT,SKINCOLOR_BLACK))
		v.drawFill(right - slider_w - 1 - strw, y, slider_w+strw + 1, slider_h, 28)
		if hovering
		or (sld_grabbed and sld_grabid == sld_id)
			for i = 1,10
				local x = right - slider_w - 1 - strw - widths["MEDIUM"]/2
				local w = slider_w+strw + 1 + widths["MEDIUM"]/2
				if (i == 1 or i == 10)
					x = $ + 3
					w = $ - 3
				elseif (i == 2 or i == 9)
					x = $ + 2
					w = $ - 2
				elseif (i == 3 or i == 8)
					x = $ + 1
					w = $ - 1
				end
				v.drawFill(x,y+i - 1, w,1, (sld_grabid == sld_id and 31|V_40TRANS or highlite_index|highlite_weak))
			end
		end
		
		v.drawFill(right - slider_w - 1, y + 1, 1, slider_h - 2, 22)
		v.drawFill(right - 2, y + 1, 1, slider_h - 2, 22)
		v.drawFill(right - slider_w - 1, y + 1, slider_w, 1, 22)
		v.drawFill(right - slider_w - 1, y + slider_h - 2, slider_w, 1, 22)
		for i = 1, 3
			local nudge = (slider_w * i)/4
			v.drawFill(right - slider_w - 2 + nudge, y + 3, 1, slider_h - 6, 24)
		end
		
		ML.interpolate(v, sld_id)
		v.drawScaled((right - slider_w - 2)*FU + slider_move, y*FU, FU,v.cachePatch("SMENU_SLIDER"),0)
		ML.interpolate(v, false)
		v.drawString(right - slider_w - 2, y+1, str, V_YELLOWMAP,"thin-right")
	end
end

local compver,compdate = (loadfile("Vars/compver.lua"))(), (loadfile("Vars/compdate.lua"))()
ML.addMenu({
	stringId = "soap_options",
	title = "Soap Options",
	width = 290,
	height = 110,
	ms_flags = MS_NOANIM,
	drawer = function(v,ML,menu, props)
		local cx = props.corner_x + 2
		local cy = props.corner_y + 16
		sld_id = 0
		
		v.drawString(cx, cy, "Local", V_ALLOWLOWERCASE|V_YELLOWMAP,"left")
		v.drawFill(cx, cy+9, menu.width - 4, 2, 26)
		v.drawFill(cx, cy+9, menu.width - 5, 1, 73)
		cy = $ + 13
		
		SOAP_MENUS.buttontoggle(v, cx,cy, menu.width - 4, {
			cv_name = "soap_afterimagestyle", name = "Afterimage Style",
			cv_type = "custom",
		})
		SOAP_MENUS.buttontoggle(v, cx,cy+13, menu.width - 4, {
			cv_name = "soap_quakes", name = "Earthquakes",
			cv_type = "custom",
		})
		cy = $ + 26
		
		v.drawString(cx, cy, "Netvars", V_ALLOWLOWERCASE|V_YELLOWMAP,"left")
		v.drawFill(cx, cy+9, menu.width - 4, 2, 26)
		v.drawFill(cx, cy+9, menu.width - 5, 1, 73)
		cy = $ + 13
		
		SOAP_MENUS.buttontoggle(v, cx,cy, menu.width - 4, {
			cv_name = "soap_hitlagmul", name = "Hitlag Multiplier",
			cv_type = "slider", fixed = true, adminonly = true
		})
		SOAP_MENUS.buttontoggle(v, cx,cy+13, menu.width - 4, {
			cv_name = "soap_maxhitlagtics", name = "Max Hitlag Tics",
			cv_type = "slider", adminonly = true
		})
		
		v.drawString(props.corner_x + 1,props.corner_y + menu.height - 5, string.format("\x82\compver: \x80%s\x82\t".."compdate: \x80%s",compver,compdate),V_ALLOWLOWERCASE,"small-thin")
		sld_display.tics = max($ - 1, 0)
	end
})

COM_AddCommand("soap_menu", function(p)
	if gamestate ~= GS_LEVEL then return end
	if ML.client.currentMenu.id ~= -1 then return end
	
	ML.initMenu(ML.findMenu("soap_options"))
end, COM_LOCAL)
-- Just temporary until a system is sorted out.
local CV = SOAP_CV

local amp_levels = {
	[0] = V_GRAYMAP,
	[1] = 0,
	[2] = V_AQUAMAP,
	[3] = V_SKYMAP,
	[4] = V_PERIDOTMAP,
	[5] = V_GREENMAP,
}
local amp_combo = {
	[0] = "Okay",
	[1] = "Better",
	[2] = "Good!",
	[3] = "Cool!",
	[4] = "Sick!!",
	[5] = "Amazing!!",
	[6] = "AWESOME!!!",
}
local rainbow_clr = {
	[0] = V_REDMAP,
	[1] = V_ORANGEMAP,
	[2] = V_YELLOWMAP,
	[3] = V_GREENMAP,
	[4] = V_BLUEMAP,
	[5] = V_SKYMAP,
	[6] = V_AZUREMAP,
	[7] = V_PURPLEMAP,
	[8] = V_ROSYMAP,
}

local supernotif = {
	seen = false,
	lastrings = 0,
	tics = 0,
}

local autoanim = {
	texttics = 0,
	ticker = 0
}
local hori_arrowfill = {
	1, 2, 3, 4, 3, 2, 1
}
local vert_arrowfill = {
	1, 3, 5, 7
}

-- drawfillfixed cant come any SOONER!!! (to vanilla)
local fillpatches = {}
local function arrowFill(v, x,y, w,h, c, flags)
	local patch = fillpatches[c]
	if not (patch and patch.valid)
		patch = v.cachePatch(string.format("SOAP_FILL_%.2d", c))
		fillpatches[c] = patch
	end
	
	v.drawStretched(x,y, w,h, patch, flags)
end

local function drawHorizontalAUTO(v,p, result, x,y,scale, align,sign)
	/*
	if autoanim.texttics < 16
		v.dointerp(11432)
		local t = autoanim.texttics
		local flags = 0
		local off = 0
		if t < 4
			off = (5 - t)*FU * 5/2
		elseif t >= (16 - 9)
			flags = (t - (16 - 9)) << V_ALPHASHIFT
		end
		
		v.drawString(x - off*sign - 15*FU,y, "AUTO", V_ALLOWLOWERCASE|flags, "thin-fixed"..align)
		autoanim.texttics = $ + 1
	end
	*/
	
	for i = 0, 2
		v.dointerp(10130 + i)
		if i and (autoanim.ticker < i*6) then continue end
		local trans = (5 * cos(FixedAngle((autoanim.ticker - i*6)*FU*12))) + 5*FU
		trans = (clamp(0, $, 10*FU) / FU)
		
		local yof = 0
		local clr = (1 + (3*trans))
		for j = 1,7
			local of = hori_arrowfill[j]*FU
			arrowFill(v, x - of - (5*FU * i),y + yof, of,FU, clr)
			yof = $ + FU
		end
	end
end

local function drawVerticalAUTO(v,p, result, x,y,scale, align,sign)
	/*
	if autoanim.texttics < 16
		v.dointerp(11432)
		local t = autoanim.texttics
		local flags = 0
		local off = 0
		if t < 4
			off = (5 - t)*FU
		elseif t >= (16 - 9)
			flags = (t - (16 - 9)) << V_ALPHASHIFT
		end
		
		v.drawString(x - off*sign,y - 24*FU, "A\nU\nT\nO", V_ALLOWLOWERCASE|flags|V_RETURN8, "thin-fixed"..align)
		autoanim.texttics = $ + 1
	end
	*/
	
	for i = 0, 2
		v.dointerp(10130 + i)
		if i and (autoanim.ticker < i*6) then continue end
		local trans = (5 * cos(FixedAngle((autoanim.ticker - i*6)*FU*12))) + 5*FU
		trans = (clamp(0, $, 10*FU) / FU)
		
		local yof = 0
		local clr = (1 + (3*trans))
		for j = 1,4
			local of = vert_arrowfill[j]*FU
			
			arrowFill(v, x - of/2, y + yof - (5*FU * i), of,FU, clr)
			yof = $ + FU
		end
	end
end

addHook("HUD",function(v,p, cam)
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if All7Emeralds(emeralds)
	and not supernotif.seen
	and (skins[p.skin].name == SOAP_SKIN)
		if (p.rings >= 50)
		and (supernotif.lastrings < 50)
			supernotif.seen = true
			supernotif.tics = 3*TR
			S_StartSound(nil, sfx_sp_amp)
		end
		supernotif.lastrings = p.rings
	end
	
	if hud.painsurge
		local frame = (7 - hud.painsurge)
		local patch = v.cachePatch("SOAP_PS_"..frame)
		local wid = (v.width() / v.dupx()) + 1
		local hei = (v.height() / v.dupy()) + 1
		local p_w = patch.width
		local p_h = patch.height
		v.drawStretched(0,0,
			FixedDiv(wid * FU, p_w * FU),
			FixedDiv(hei * FU, p_h * FU),
			patch,
			V_SNAPTOTOP|V_SNAPTOLEFT,
			v.getColormap(TC_DEFAULT,
				G_GametypeHasTeams() and
				(p.ctfteam == 1 and skincolor_redteam or skincolor_blueteam) or p.skincolor
			)
		)
	end
	
	if me.soap_totalamps
	or (leveltime < (me.soap_amppayouttime or 0))
	or (supernotif.tics)
		local x,y = 200*FU, 150*FU
		local scale = FU
		local result = K_GetScreenCoords(v,p,cam, me, {anglecliponly = true})
		local align = (skins[p.skin].name == TAKIS_SKIN) and "-right" or ""
		local sign = (skins[p.skin].name == TAKIS_SKIN) and -1 or 1
		if cam.chase
			if not result.onscreen then return end
			
			scale = abs(FixedMul(result.scale, me.scale)) * 8/5
			x = result.x + (25 * scale * sign)
			y = result.y
		elseif (sign == -1)
			x = 120*FU
		end
		
		if (supernotif.tics)
			local flags = 0
			local off = 0
			local time = supernotif.tics
			if time > (TR*3) - 4
				local ticker = time - (TR*3 - 4)
				flags = V_YELLOWMAP
				off = ticker*FU*2
			elseif time < 10
				flags = (10 - time) << V_ALPHASHIFT
			end
			
			v.dointerp(15430)
			v.drawString(x + off*sign,y-16*FU, "Hold C3 to", V_ALLOWLOWERCASE|flags, "thin-fixed"..align)
			v.drawString(x + off*sign,y-8*FU,  "transform!", V_ALLOWLOWERCASE|flags, "thin-fixed"..align)
		end
		if me.soap_totalamps
			local clr = amp_levels[me.soap_amplevel or 0]
			if clr == nil
				clr = rainbow_clr[(leveltime/2) % 9]
			end
			v.dointerp(15431)
			v.drawString(x,y, "x"..(me.soap_totalamps / 5).." COMBO", V_ALLOWLOWERCASE|clr, "thin-fixed"..align)
		end
		if (me.soap_amppayouttime)
		and (leveltime < me.soap_amppayouttime)
			local flags = 0
			local off = 0
			local time = abs(me.soap_amppayouttime - leveltime)
			if time > (TR*3/2) - 4
				local ticker = time - (TR*3/2 - 4)
				flags = V_YELLOWMAP
				off = ticker*FU*2
			elseif time < 10
				flags = (10 - time) << V_ALPHASHIFT
			end
			
			v.dointerp(15432)
			local str = ""
			if me.soap_amppayoutringmode
				str = "+"..(me.soap_amppayout).." ring"..(me.soap_amppayout ~= 1 and "s" or "")
			else
				str = amp_combo[me.soap_amppayoutlevel or 0]
				if not Soap_IsCompGamemode()
					str = $ .. " (+"..(me.soap_amppayout*90)..")"
				end
			end
			
			v.drawString(x - off*sign,y+8*FU, str, V_ALLOWLOWERCASE|flags, "thin-fixed"..align)
		end
		v.dointerp(false)
	end
	
	if soap.rdashtoggle
	and (soap.io.rdashmode == "toggle")
	and (skins[p.skin].name == SOAP_SKIN)
		local x,y = 200*FU, 150*FU
		local scale = FU
		local result = K_GetScreenCoords(v,p,cam, me, {anglecliponly = true})
		local align = "-right"
		local sign = -1
		if cam.chase
			if not result.onscreen then return end
			
			scale = abs(FixedMul(result.scale, me.scale)) * 8/5
			x = result.x + (25 * scale * sign)
			y = result.y
		elseif (sign == -1)
			x = 120*FU
		end
		
		if CV.autoside.value == 0
			drawHorizontalAUTO(v,p, result, x,y,scale, align,sign)
		else
			drawVerticalAUTO(v,p, result, x,y,scale, align,sign)
		end
		
		v.dointerp(false)
		autoanim.ticker = $ + 1
	else
		autoanim.texttics = 0
		autoanim.ticker = 0
	end
	
	if supernotif.tics
		supernotif.tics = $ - 1
	end
end,"game")

local CLUTCH_FADEOUT = 2*TR
local CLUTCH_FADE = 4
local clutchfade = 0
addHook("HUD",function(v,p, cam)
	if not v.dointerp
		v.dointerp = function(tag)
			if v.interpolate == nil then return end
			v.interpolate(tag)
		end
	end
	
	local takis = p.soaptable
	if not takis then return end
	if not (skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = takis.hud
	local me = p.realmo
	
	local x,y = 200*FU, 150*FU
	local scale = FU
	local result = K_GetScreenCoords(v,p,cam, me, {anglecliponly = true})
	if cam.chase
		if not result.onscreen then return end
		
		scale = abs(FixedMul(result.scale, me.scale)) * 8/5
		x = result.x + 40 * scale
		y = result.y
	end
	
	local clutch = takis.clutch
	local color = SKINCOLOR_CRIMSON
	if (clutch.tics <= CLUTCH_TICS - CLUTCH_OKAY)
	and (clutch.tics > 0)
		color = SKINCOLOR_GREEN
	end
	
	v.dointerp(true)
	
	local stra, strb
	local thina,thinb = false,false
	if clutch.combo
		stra,strb = "x"..(clutch.combo), "BOOSTS"
		thina,thinb = false,true
	elseif (clutch.spamcount)
		stra,strb = "CLUTCH ON", "GREEN"
		thina,thinb = true,true
	end
	
	if clutch.tics > 0
		clutchfade = 0
		
		local pre = "CLTCHMET_"
		local bg = v.cachePatch(pre .. "BACK")
		local fill = v.cachePatch(pre .. "FILL")
		
		v.drawScaled(x, y, scale, bg, V_HUDTRANS)
		
		local maxtic = CLUTCH_TICS*FU
		local timer = maxtic - (clutch.tics*FU)
		
		local frac = FixedDiv(timer,maxtic)
		local width = max((fill.height*FU) - FixedMul(frac, fill.height*FU), 0)
		
		v.drawCropped(x,y+FixedMul(width,scale),scale,scale,
			fill,
			V_HUDTRANS, 
			v.getColormap(nil,color,nil),
			0,width,
			fill.width*FU,fill.height*FU
		)
		
		v.drawScaled(x, y, scale, v.cachePatch(pre .. "MARK"), V_HUDTRANS)
	else
		clutchfade = min($ + 1, CLUTCH_FADEOUT)
	end
	
	local fade = 0
	if (clutchfade >= (CLUTCH_FADEOUT - CLUTCH_FADE))
		fade = (clutchfade - (CLUTCH_FADEOUT - CLUTCH_FADE))<<V_ALPHASHIFT
	end
	if stra
		local x = x
		local fade = fade
		if clutch.goodanim
			x = $ + (FU * clutch.goodanim)
			fade = $|V_YELLOWMAP
		end
		v.drawString(x,y,
			stra,
			V_ALLOWLOWERCASE|fade, thina and "thin-fixed" or "fixed"
		)
	end
	if strb
		v.drawString(x,y+8*FU,
			strb,
			V_ALLOWLOWERCASE|fade, thinb and "thin-fixed" or "fixed"
		)
	end
	v.dointerp(false)
end,"game")
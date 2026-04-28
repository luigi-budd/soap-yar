-- Just temporary until a system is sorted out.

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
		if cam.chase
			if not result.onscreen then return end
			
			scale = abs(FixedMul(result.scale, me.scale)) * 8/5
			x = result.x + 25 * scale
			y = result.y
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
			v.drawString(x + off,y-16*FU, "Hold C3 to", V_ALLOWLOWERCASE|flags, "thin-fixed")
			v.drawString(x + off,y-8*FU,  "transform!", V_ALLOWLOWERCASE|flags, "thin-fixed")
		end
		if me.soap_totalamps
			local clr = amp_levels[me.soap_amplevel or 0]
			if clr == nil
				clr = rainbow_clr[(leveltime/2) % 9]
			end
			v.dointerp(15431)
			v.drawString(x,y, "x"..(me.soap_totalamps / 5).." COMBO", V_ALLOWLOWERCASE|clr, "thin-fixed")
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
					str = $ .. " (+"..(me.soap_amppayout*50)..")"
				end
			end
			
			v.drawString(x - off,y+8*FU, str, V_ALLOWLOWERCASE|flags, "thin-fixed")
		end
		v.dointerp(false)
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
		
		v.drawScaled(x, y, scale, bg, V_PERPLAYER|V_HUDTRANS)
		
		local maxtic = CLUTCH_TICS*FU
		local timer = maxtic - (clutch.tics*FU)
		
		local frac = FixedDiv(timer,maxtic)
		local width = max((fill.height*FU) - FixedMul(frac, fill.height*FU), 0)
		
		v.drawCropped(x,y+FixedMul(width,scale),scale,scale,
			fill,
			V_PERPLAYER|V_HUDTRANS, 
			v.getColormap(nil,color,nil),
			0,width,
			fill.width*FU,fill.height*FU
		)
		
		v.drawScaled(x, y, scale, v.cachePatch(pre .. "MARK"), V_PERPLAYER|V_HUDTRANS)
	else
		clutchfade = min($ + 1, CLUTCH_FADEOUT)
	end
	
	local fade = 0
	if (clutchfade >= (CLUTCH_FADEOUT - CLUTCH_FADE))
		fade = (clutchfade - (CLUTCH_FADEOUT - CLUTCH_FADE))<<V_ALPHASHIFT
	end
	if stra
		v.drawString(x,y,
			stra,
			V_PERPLAYER|V_ALLOWLOWERCASE|fade, thina and "thin-fixed" or "fixed"
		)
	end
	if strb
		v.drawString(x,y+8*FU,
			strb,
			V_PERPLAYER|V_ALLOWLOWERCASE|fade, thinb and "thin-fixed" or "fixed"
		)
	end
	v.dointerp(false)
end,"game")
-- Just temporary until a system is sorted out.

addHook("HUD",function(v,p)
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN) then return end
	local hud = soap.hud
	
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
end,"game")

addHook("HUD",function(v,p, cam)
	v.dointerp = function(tag)
		if v.interpolate == nil then return end
		v.interpolate(tag)
	end
	v.dolatch = function(tag)
		if v.interpLatch == nil then return end
		v.interpLatch(tag)
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
		
		scale = abs(result.scale) * 8/5
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
	if stra
		v.drawString(x,y,
			stra,
			V_PERPLAYER|V_ALLOWLOWERCASE, thina and "thin-fixed" or "fixed"
		)
	end
	if strb
		v.drawString(x,y+8*FU,
			strb,
			V_PERPLAYER|V_ALLOWLOWERCASE, thinb and "thin-fixed" or "fixed"
		)
	end
	
	if clutch.tics > 0
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
	end
	v.dointerp(false)
end,"game")
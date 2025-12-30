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

local wheel_radius = 60*FU
local wheel_start = 28*FU
local wheel_inner = wheel_start + (wheel_radius - wheel_start)/2
addHook("HUD",function(v,p)
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local taunt = soap.taunt
	
	if not taunt.active then return end
	
	v.drawScaled(160*FU,100*FU, FU/2, v.cachePatch("STAUNT_BG"), V_30TRANS)
	local dist = R_PointToDist2(0,0, taunt.x,taunt.y)
	local TAUNTS = SOAP_TAUNTS[skins[p.skin].name]
	local avail = #TAUNTS
	local angstep = FixedDiv(360*FU, avail*FU)
	for i = 0, avail - 1
		local ang = ANGLE_MAX - FixedAngle(angstep * i)
		v.drawScaled(160*FU,100*FU, FU/2,
			v.getSpritePatch(SPR_SOAP_GFX, 53, 0, ang),
			0
		)
		ang = ($ - ANGLE_90) + ANGLE_180 - FixedAngle(angstep / 2)
		
		if (TAUNTS[i + 1].drawer ~= nil)
			TAUNTS[i + 1].drawer(v, i,
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				(dist >= wheel_start) and (taunt.pointing == i)
			)
		else
			v.drawScaled(
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				FU/4,
				v.cachePatch("MISSING"),
				0
			)
		end
	end
	
	v.dointerp(1000)
	v.drawScaled(
		(160*FU) + taunt.x, --P_ReturnThrustX(nil,taunt.angle<<16, radius),
		(100*FU) - taunt.y, --P_ReturnThrustY(nil,taunt.aim<<16, radius),
		FU/4, v.cachePatch((dist >= wheel_start) and "ML_RBLX_POINT" or "ML_RBLX_CURS"),
		0
	)
	v.dointerp(false)
	
	if (dist >= wheel_start)
		local taunt_t = TAUNTS[taunt.pointing + 1]
		v.drawString(160*FU, 100*FU + (wheel_radius + 5*FU),
			taunt_t.name, V_ALLOWLOWERCASE|V_YELLOWMAP,
			"thin-fixed-center"
		)
	end
	
	v.drawString(160*FU, 100*FU - (wheel_radius + 10*FU),
		"Pick a taunt!", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 20*FU),
		"[JUMP/FIRE] - Select", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 28*FU),
		"[SPIN] - Cancel", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
end,"game")
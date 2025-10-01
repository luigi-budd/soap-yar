local oldflags = 0
local oldlives = hud.enabled("lives")

local function DrawButton(v, player, x, y, flags, color, color2, butt, release, symb, strngtype, w,h)
	-- Buttons! Shows input controls.
	-- butt parameter is the button cmd in question.
	-- symb represents the button via drawn string.
	w = $ or 10
	h = $ or 10
	
	if release == nil then release = 0 end
	
	local offs, col
	if (butt >= 1) then
		if (butt == 1 and (release != false))
			offs = -1
			col = flags|color2
		else
			offs = 0
			col = flags|color
		end
	else
		offs = (not release) and 1 or 0
		col = flags|16
		v.drawFill(
			(x), (y+(h - 1)),
			w, 1, flags|29
		)
	end
	v.drawFill(
		(x), (y)-offs,
		w, h,	col
	)
	
	local stringx, stringy = 1, 1
	if (strngtype == 'thin') then
		stringy = 2
	end
	
	v.drawString(
		(x+stringx), (y+stringy)-offs,
		symb, flags, strngtype
	)
end

local function drawflag(v,x,y,string,flags,onmap,offmap,align,flag)
	local map = offmap
	if flag
		map = onmap
	end
	
	v.drawString(x,y,string,flags|map,align)
end

local function WRAP_buttons(v,p,c, me,soap)
	local color = (p.skincolor and skincolors[p.skincolor].ramp[4] or 0)
	local color2 = (ColorOpposite(p.skincolor) and skincolors[ColorOpposite(p.skincolor)].ramp[4] or 0)
	
	if (modeattacking or SOAP_CV.FindVar("showinput").value)
		local x, y = hudinfo[HUD_INPUT].x, hudinfo[HUD_INPUT].y
		local f = hudinfo[HUD_INPUT].f
		
		if (p.powers[pw_carry] == CR_NIGHTSMODE)
			y = $ + 8
		elseif (modeattacking or (not hud.enabled("lives")))
			y = $ + 24
		elseif G_RingSlingerGametype() and hud.enabled("powerstones")
			y = $ - 5
		end
		-- top left of the theoretical button next to "S"
		x = $ + (16 + 15 + 11)
		y = $ - 3
		
		DrawButton(v,p,x,     y, f, color, 0, (soap.c1), false, "1", "thin", 7)
		DrawButton(v,p,x + 8, y, f, color, 0, (soap.c2), false, "2", "thin", 7)
		DrawButton(v,p,x + 16,y, f, color, 0, (soap.c3), false, "3", "thin", 7)
		
		DrawButton(v,p,x,     y + 12, f, color, 0, (soap.tossflag), false, "TOSS", "thin", 23)
		--DrawButton(v, p, x, y, flags, color, color2, soap.jump, soap.jump_R, 'J', 'left')
		return
	end
	
	local x, y = 15, 176
	local flags = V_HUDTRANS|V_PERPLAYER|V_SNAPTOBOTTOM|V_SNAPTOLEFT
	
	v.drawString(
		x + 145 - 2,
		y - 10 - 23,
		p.cmd.forwardmove,
		flags,
		"thin-center"
	)
	v.drawString(
		x + 145 + 16,
		y - 10 - 6,
		p.cmd.sidemove,
		flags,
		"thin"
	)
	
	v.drawScaled(
		(x + 145 - 2)*FU,
		(y - 10 - 2)*FU,
		FU*6/5,
		v.cachePatch("TA_LIVESFILL_FILL"),
		flags,
		v.getColormap(nil,SKINCOLOR_CARBON)
	)
	
	v.drawScaled(
		(x + 145 - 2)*FU,
		(y - 10 - 2)*FU,
		FU/6,
		v.cachePatch("TA_LIVESFILL_FILL"),
		flags,
		v.getColormap(nil,ColorOpposite(p.skincolor), nil)
	)
	
	v.drawScaled(
		(x + 145 + p.cmd.sidemove/4 - 2)*FU,
		(y - 10 - p.cmd.forwardmove/4 - 2)*FU,
		FU/6,
		v.cachePatch("TA_LIVESFILL_FILL"),
		flags,
		v.getColormap(nil,p.skincolor)
	)
	
	DrawButton(v, p, x, y, flags, color, color2, soap.jump, soap.jump_R, 'J', 'left')
	DrawButton(v, p, x+11, y, flags, color, color2, soap.use, soap.use_R, 'S', 'left')
	DrawButton(v, p, x+22, y, flags, color, color2, soap.tossflag, soap.tossflag_R, 'TF', 'thin')
	DrawButton(v, p, x+33, y, flags, color, color2, soap.c1, soap.c1_R, 'C1', 'thin')
	DrawButton(v, p, x+44, y, flags, color, color2, soap.c2, soap.c2_R, 'C2', 'thin')
	DrawButton(v, p, x+55, y, flags, color, color2, soap.c3, soap.c3_R, 'C3', 'thin')
	DrawButton(v, p, x+66, y, flags, color, color2, soap.fire, soap.fire_R, 'F', 'left')
	DrawButton(v, p, x+77, y, flags, color, color2, soap.firenormal, soap.firenormal_R, 'FN', 'thin')
	DrawButton(v, p, x+88, y, flags, color, color2, soap.weaponmasktime,soap.weaponmasktime_R, soap.weaponmask, 'left')
	DrawButton(v, p, x+99, y, flags, color, color2, soap.weaponprev,soap.weaponprev_R, 'WP', 'thin')
	DrawButton(v, p, x+110, y, flags, color, color2, soap.weaponnext, soap.weaponnext_R, 'WN', 'thin')
	
	v.drawString(x,y-108,"pw_strong",flags,"thin")
	drawflag(v,x+00,y-100,"NN",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_NONE))
	drawflag(v,x+15,y-100,"AN",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_ANIM))
	drawflag(v,x+30,y-100,"PN",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_PUNCH))
	drawflag(v,x+45,y-100,"TL",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_TAIL))
	drawflag(v,x+60,y-100,"ST",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_STOMP))
	drawflag(v,x+75,y-100,"UP",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_UPPER))
	drawflag(v,x+90,y-100,"GD",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_GUARD))
	--line 2
	drawflag(v,x+00,y-90,"HV",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_HEAVY))
	drawflag(v,x+15,y-90,"DS",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_DASH))
	drawflag(v,x+30,y-90,"WL",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_WALL))
	drawflag(v,x+45,y-90,"FL",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_FLOOR))
	drawflag(v,x+60,y-90,"CL",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_CEILING))
	drawflag(v,x+75,y-90,"SP",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_SPRING))
	drawflag(v,x+90,y-90,"SK",flags,V_GREENMAP,V_REDMAP,"thin",(p.powers[pw_strong] & STR_SPIKE))
	
	/*
	"RDASH",
	"AIRDASH",
	"UPPERCUT",
	"POUND",
	--maybe?
	"TOP",
	"TAUNTS",
	"CROUCH",
	"BREAKDANCE",
	*/
	
	v.drawString(x,y-58,"noability",flags|V_GREENMAP,"thin")
	drawflag(v,x+00,y-50,"RD",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_RDASH))
	drawflag(v,x+15,y-50,"AD",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_AIRDASH))
	drawflag(v,x+30,y-50,"UC",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_UPPERCUT))
	drawflag(v,x+45,y-50,"PD",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_POUND))
	drawflag(v,x+60,y-50,"ST",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_TOP))
	drawflag(v,x+75,y-50,"TT",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_TAUNTS))
	drawflag(v,x+90,y-50,"CR",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_CROUCH))
	drawflag(v,x+105,y-50,"BD",flags,V_GREENMAP,V_REDMAP,"thin",(soap.noability & SNOABIL_BREAKDANCE))
	
	v.drawString(x,y-38,"STASIS TIC",flags|V_GREENMAP,"thin")
	v.drawString(x,y-30,soap.stasistic,flags,"thin")
	
	v.drawString(x+60,y-38,"stasis",flags,"thin")
	drawflag(v,x+60,y-30,"FS",flags,V_GREENMAP,V_REDMAP,"thin",(p.pflags & PF_FULLSTASIS == PF_FULLSTASIS))
	drawflag(v,x+78,y-30,"JS",flags,V_GREENMAP,V_REDMAP,"thin",(p.pflags & PF_JUMPSTASIS))
	drawflag(v,x+96,y-30,"SS",flags,V_GREENMAP,V_REDMAP,"thin",(p.pflags & PF_STASIS))
end

addHook("HUD",function(v,p)
	local me = p.realmo
	local soap = p.soaptable
	
	if not (me and me.valid) then return end
	
	if SOAP_DEBUG & DEBUG_BUTTONS
		if not (oldflags & DEBUG_BUTTONS)
			oldlives = hud.enabled("lives")
			hud.disable("lives")
		end
		WRAP_buttons(v,p,c, me,soap)
	elseif oldflags & DEBUG_BUTTONS
		if oldlives
			hud.enable("lives")
		end
		oldlives = false
	end
	if (SOAP_DEBUG & DEBUG_RDASH) and (v.drawFixedFill ~= nil)
		local w, h = 90*FU, 10*FU
		local x, y = 160*FU - w/2, (200 - 20)*FU
		local f = V_SNAPTOBOTTOM
		local skin = skins[p.skin]
		
		v.interpolate(true)
		v.drawFixedFill(x-FU,y-FU, w+2*FU,h+2*FU, 27|f)
		if soap.rdashing
			local progress = min(
				FixedDiv(
					p.normalspeed - skin.normalspeed - soap.dashcharge, soap._maxdash + SOAP_EXTRADASH
				), FU
			)
			local eprogress = min(FixedDiv(p.normalspeed - skin.normalspeed, soap._maxdash + SOAP_EXTRADASH), FU)
			v.drawFixedFill(x,y, FixedMul(w,eprogress),h, 162|f)
			v.drawFixedFill(x,y, FixedMul(w,progress),h, 134|f)
		end
		v.drawString(x,y+(h - 4*FU), string.format("R-Dash: %.1f%% (%.1f, %.1f/%.0f%%) (max %.1f)",
			FixedDiv(p.normalspeed - skin.normalspeed, soap._maxdash)*100,
			p.normalspeed, soap.dashcharge,
			FixedDiv(soap.chargingtime*FU,3*TR*FU)*100,
			soap._maxdash),
			f|V_ALLOWLOWERCASE, "small-thin-fixed"
		)
		v.interpolate(false)
	end
	
	oldflags = SOAP_DEBUG
end,"game")
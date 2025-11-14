local oldflags = 0
local oldlives = hud.enabled("lives")
local oldstr = {
	score = hud.enabled("score"),
	time = hud.enabled("time"),
	rings = hud.enabled("rings"),
}
local STR_CAP = 30

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

local v_width,v_height = 0,0
local function drawLine(v, x, y, t, angle, length, color)
    for i=0, length-1 do
		local destx = x + FixedMul(i*FU, cos(angle))
		local desty = y - FixedMul(i*FU, sin(angle))
		if destx < 0 or destx > v_width then continue end
		if desty < 0 or desty > v_height then continue end
        v.drawFixedFill(destx, desty, t*FU, t*FU, color)
    end
end
local function WRAP_buttons(v,p,c, me,soap)
	v_width = (v.width() / v.dupx())*FU
	v_height = (v.height() / v.dupy())*FU
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
	
	--control display
	do
		--string values
		v.drawString(x + 145 - 2, y - 10 - 23,
			p.cmd.forwardmove,
			flags,"thin-center"
		)
		v.drawString(x + 145 + 16, y - 10 - 6,
			p.cmd.sidemove,
			flags,"thin"
		)
		
		--backing
		v.drawScaled(
			(x + 145 - 2)*FU,
			(y - 10 - 2)*FU,
			FU*6/5,
			v.cachePatch("TA_LIVESFILL_FILL"),
			flags,
			v.getColormap(nil,SKINCOLOR_CARBON)
		)
		
		-- 0,0 circle
		v.drawScaled(
			(x + 145 - 2)*FU,
			(y - 10 - 2)*FU,
			FU/6,
			v.cachePatch("TA_LIVESFILL_FILL"),
			flags,
			v.getColormap(nil,ColorOpposite(p.skincolor), nil)
		)
		
		if (p.cmd.forwardmove ~= 0 or p.cmd.sidemove ~= 0)
		and v.drawFixedFill ~= nil
			local x,y = (x + 145 - 2)*FU, (y - 10 - 2)*FU
			local ang = InvAngle(R_PointToAngle2(x,y, x + (p.cmd.forwardmove*FU), y + (p.cmd.sidemove*FU))) + ANGLE_90
			drawLine(v, x, y, 1, ang,
				FixedHypot(p.cmd.sidemove/4, p.cmd.forwardmove/4), color2|flags
			)
		end
		
		-- input circle
		v.drawScaled(
			(x + 145 - 2)*FU + (p.cmd.sidemove*FU/4),
			(y - 10 - 2)*FU - (p.cmd.forwardmove*FU/4),
			FU/6,
			v.cachePatch("TA_LIVESFILL_FILL"),
			flags,
			v.getColormap(nil,p.skincolor)
		)
	end
	
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
	if (SOAP_DEBUG & DEBUG_HOOKS)
		if not (oldflags & DEBUG_HOOKS)
			oldstr = {
				score = hud.enabled("score"),
				time = hud.enabled("time"),
				rings = hud.enabled("rings"),
			}
			hud.disable("score")
			hud.disable("time")
			hud.disable("rings")
		end

		local x = 2
		local y = 2
		local flags = V_SNAPTOLEFT|V_SNAPTOTOP|V_ALLOWLOWERCASE
		local frametime = 0
		for etype, event_t in pairs(Takis_Hook.events)
			local starty = y
			local totaltime = 0

			x = $ + 4
			y = $ + 4
			for key,hook_t in pairs(event_t)
				-- these are irrelevant
				if (key == "typefor" or key == "handler")
					continue
				end
				local path = hook_t.src
				local strlen = path:len()
				if strlen > STR_CAP - 1
					path = path:sub(strlen - STR_CAP, strlen)
				end
				local clr = hook_t.activity and "\x80" or "\x86"

				v.drawString(x,y, "\x82["..tostring(key)..","..tostring(hook_t.id).."] - \x86"..path.." = "..clr..tostring(hook_t.us_taken).."us", flags, "small")
				if (hook_t.activity > 0)
					hook_t.activity = max($ - 1, 0)
					frametime = $ + hook_t.us_taken
					totaltime = $ + hook_t.us_taken
				elseif (hook_t.activity < 0)
					hook_t.activity = 0
				end

				y = $ + 4
			end
			x = $ - 4
			v.drawString(x,starty, etype..": "..(totaltime).."us",
				flags|(Takis_Hook.disabled[etype] == true and V_GRAYMAP or V_YELLOWMAP),
				"small"
			)
		end
		y = $ + 4
		v.drawString(x,y, "Frame time taken: "..(frametime).."us", flags|V_YELLOWMAP, "small")

	elseif oldflags & DEBUG_HOOKS
		for k,v in pairs(oldstr)
			if v
				hud.enable(k)
			end
		end
	end
	
	oldflags = SOAP_DEBUG
end,"game")
-- The taunt wheel is shared by both characters, and is sorta complicated
-- so it gets its own file.
local CV = SOAP_CV

local cam_still = CV.FindVar("cam_still")

local scroll_fact = 400
local wheel_radius = 60*FU
local wheel_start = 28*FU

local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local function chardrawer(v,i, x,y, props, selected)
	local scale = FixedMul(selected and (FU*3/5)/2 or (FU/4), skins[props.skin].highresscale)
	local patch,flip = v.getSprite2Patch(props.skin, props.spr2, false, props.frame, props.angle, 0)
	v.drawScaled(x, y + (patch.height * scale)/2,
		scale, patch, (flip) and V_FLIP or 0,
		v.getColormap(nil,nil, selected and "AllYellow" or "AllWhite")
	)
end

local function cancelConds(p, nobuttons)
	local me = p.realmo
	local soap = p.soaptable
	
	local cancel = false
	if (soap.inPain)
	or (not soap.notCarried)
		cancel = true
	end
	if (not soap.onGround)
	or soap.accspeed >= 4*FU
		cancel = true
	end
	if (soap.jump == 1 or soap.spin)
	and not nobuttons
		cancel = true
	end
	return cancel
end

rawset(_G, "SOAP_TAUNTS", {})
SOAP_TAUNTS[SOAP_SKIN] = {
	[1] = {
		name = "Flex",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me,sfx_flex)
			me.state = S_PLAY_SOAP_FLEX
			soap.stasistic = TR
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		think = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			p.drawangle = angle + ANGLE_90
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = SOAP_SKIN,
				spr2 = SPR2_FLEX,
				frame = A, angle = 1
			}, selected)
		end,
	},
	[2] = {
		name = "Laugh",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me,sfx_hahaha)
			me.state = S_PLAY_SOAP_LAUGH
			soap.stasistic = TR
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		think = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			p.drawangle = angle + ANGLE_180
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = SOAP_SKIN,
				spr2 = SPR2_APOS,
				frame = A, angle = 1
			}, selected)
		end,
	},
	[3] = {
		name = "Death",
		
		run = function(p, me, soap, taunt)
			me.state = S_PLAY_DEAD
			me.sprite2 = SPR2_MSC4
			me.tics = -1
			
			me.tempangle = p.drawangle
			S_StartSound(me,sfx_altdi1,p)
			S_StartSound(me,sfx_sp_smk,p)
			S_StartSound(me,sfx_s3k5d)
			Soap_DustRing(me,
				dust_type(me),
				P_RandomRange(8,14),
				{me.x,me.y,me.z},
				16*me.scale,
				me.scale*5,
				me.scale,
				me.scale/2,
				false, dust_noviewmobj
			)
			Soap_StartQuake(10*FU, 10, {me.x,me.y,me.z}, 256*me.scale)
			
			soap.stasistic = max($, 2)
			taunt.tics = 2
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p)
				me.tempangle = nil
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
				Soap_ResetState(p)
				soap.stasistic, taunt.tics = 0,0
			else
				soap.stasistic = max($, 2)
				taunt.tics = 2
				
				p.drawangle = me.tempangle
				soap.noability = SNOABIL_ALL
			end
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = SOAP_SKIN,
				spr2 = SPR2_MSC4,
				frame = A, angle = 2
			}, selected)
		end,
	}
}

rawset(_G, "Soap_TauntWheelThink", function(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	local taunt = soap.taunt
	
	-- init
	if (cmd.buttons & (BT_CUSTOM3) == (BT_CUSTOM3))
	and (p.panim == PA_IDLE or p.panim == PA_RUN or soap.accspeed <= 5*FU)
	and (P_IsObjectOnGround(me))
	and not (taunt.active or taunt.tics)
	and me.health
	and (soap.notCarried)
	and not (soap.noability & SNOABIL_TAUNTS)
	and (SOAP_TAUNTS[me.skin] ~= nil and #SOAP_TAUNTS[me.skin])
		taunt.active = true
		taunt.freeze_ang = cmd.angleturn
		taunt.freeze_aim = cmd.aiming
		
		-- um, sure...
		if cam_still and (p == consoleplayer)
			CV_Set(cam_still, 1 - cam_still.value)
		end
	end
	
	if taunt.active
		-- nice one asshole
		if SOAP_TAUNTS[me.skin] == nil
			taunt.active = false
			if cam_still and (p == consoleplayer)
				CV_Set(cam_still, 1 - cam_still.value)
			end
			P_MovePlayer(p)
			Soap_ResetState(p)
			return
		end
		
		if (cmd.buttons & BT_SPIN)
		or cancelConds(p)
			taunt.active = false
			if cam_still and (p == consoleplayer)
				CV_Set(cam_still, 1 - cam_still.value)
			end
		end
		
		-- negative angleturn is rightwards
		-- positive aiming is upwards
		local workx = scroll_fact * (soap.angleturn - taunt.freeze_ang)
		local worky = scroll_fact * (soap.aiming - taunt.freeze_aim)
		taunt.x = $ - workx
		taunt.y = $ + worky
		local ang = R_PointToAngle2(0,0, taunt.x,taunt.y)
		local dist = R_PointToDist2(0,0, taunt.x,taunt.y)
		if (dist > wheel_radius)
			taunt.x = P_ReturnThrustX(nil,ang, wheel_radius)
			taunt.y = P_ReturnThrustY(nil,ang, wheel_radius)
			dist = R_PointToDist2(0,0, taunt.x,taunt.y)
		end
		
		cmd.angleturn = taunt.freeze_ang
		cmd.aiming = taunt.freeze_aim
		
		me.angle = cmd.angleturn << 16
		--p.drawangle = me.angle
		p.aiming = cmd.aiming << 16
		
		cmd.forwardmove = 0
		cmd.sidemove = 0
		soap.noability = $|SNOABIL_ALL
		p.powers[pw_nocontrol] = 2
		p.pflags = $|PF_FULLSTASIS
		
		local oldhover = taunt.pointing
		local selected = -1
		if (dist >= wheel_start)
			local avail = #SOAP_TAUNTS[me.skin]
			local angstep = FixedDiv(360*FU, avail*FU)
			ang = AngleFixed(InvAngle($ - ANGLE_90))
			selected = FixedTrunc(FixedDiv(ang, angstep)) / FU
			taunt.pointing = selected
		else
			taunt.pointing = -1
		end
		if (oldhover ~= taunt.pointing)
		and (dist >= wheel_start)
			S_StartSound(nil,sfx_menu1,p)
		end
		
		if (cmd.buttons & (BT_ATTACK|BT_JUMP)) and taunt.active
		and (dist >= wheel_start)
			taunt.num = selected + 1
			local taunt_t = SOAP_TAUNTS[me.skin][selected + 1]
			taunt_t.run(p, me, soap, taunt)
			
			taunt.active = false
			if cam_still and (p == consoleplayer)
				CV_Set(cam_still, 1 - cam_still.value)
			end
			soap.jumplockout = 2
		end
		cmd.buttons = 0
	else
		taunt.x = 0
		taunt.y = 0
		taunt.pointing = -1
		
		if taunt.tics > 0
			-- nice one asshole
			if SOAP_TAUNTS[me.skin] == nil
				taunt.tics = 0
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
				Soap_ResetState(p)
				return
			end
			
			local taunt_t = SOAP_TAUNTS[me.skin][taunt.num]
			if taunt_t.think
				taunt_t.think(p, me, soap, taunt)
			end
			
			taunt.tics = $ - 1
		else
			taunt.tics = 0
			taunt.num = 0
		end
	end
end)
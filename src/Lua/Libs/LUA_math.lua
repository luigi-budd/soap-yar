--Golden
rawset(_G,"SphereToCartesian",function(alpha, beta)
    local t = {}

    t.x = FixedMul(cos(alpha), cos(beta))
    t.y = FixedMul(sin(alpha), cos(beta))
    t.z = sin(beta)
    --t.z = FixedMul(sin(alpha), sin(beta)) -- for elliptical orbit

    return t
end)

--[[
addHook("PlayerThink",function(p)
	local me = p.realmo
	
	me.ra = $ or 0
	if me.rd == nil
		me.rd = 20*FU
	end
	
	me.rx = $ or 0
	me.ry = $ or 0
	me.rz = $ or 0
	
	local c1 = (p.cmd.buttons & BT_CUSTOM1)
	local c2 = (p.cmd.buttons & BT_CUSTOM2)
	local c3 = (p.cmd.buttons & BT_CUSTOM3)
	
	if (p.cmd.buttons & BT_WEAPONNEXT)
		if c1
			me.ra = $ + 3*FU
		elseif c2
			me.ra = $ + 6*FU
		elseif c3
			me.rd = $ + 5*FU
		else
			me.rz = $ + 2*FU
		end
	elseif (p.cmd.buttons & BT_WEAPONPREV)
		if c1
			me.ra = $ - 3*FU
		elseif c2
			me.ra = $ - 6*FU
		elseif c3
			me.rd = $ - 5*FU
		else
			me.rz = $ - 2*FU
		end
	end
	me.ra = $ % (360*FU)
	me.rx = P_ReturnThrustX(nil, FixedAngle(me.ra), me.rd)
	me.ry = P_ReturnThrustY(nil, FixedAngle(me.ra), me.rd)
	
	local ha, va = R_PointTo3DAngles(0,0,0, me.rx, me.ry, me.rz)
	if FixedHypot(me.momx,me.momy) < FU
		--ha = p.drawangle
	end
	
	local v = {
		x = FixedMul(cos(ha), cos(va)),
		y = FixedMul(sin(ha), cos(va)),
		z = sin(va)
	}
	local step = 16*FU
	for i = 1,5
		local s = step * i
		local g = P_SpawnMobjFromMobj(me,
			FixedMul(s, v.x),
			FixedMul(s, v.y),
			FixedMul(s, v.z),
			MT_UNKNOWN
		)
		g.fuse = 2
		g.scale = $ / 2
		P_SetOrigin(g, g.x,g.y,g.z)
		g.momx = me.momx
		g.momy = me.momy
		g.momz = me.momz
	end
	
	/*
	local fha = AngleFixed(ha)
	if fha > 180*FU
		fha = -($ - 180*FU)
	end
	local fva = AngleFixed(va)
	if fva > 180*FU
		fva = -($ - 180*FU)
	end
	
	fha = FixedMul(fva, -cos(ha))
	fva = FixedMul(fva, -sin(ha))
	
	me.pitch = FixedAngle(fha) --FixedMul(va, -cos(ha))
	me.roll = FixedAngle(fva) --FixedMul(va, -sin(ha))
	*/
	me.pitch = FixedMul(va, -cos(ha))
	me.roll = FixedMul(va, -sin(ha))
	
	me.eflags = $|MFE_NOPITCHROLLEASING
	me.flags = $|MF_NOGRAVITY
	me.z = me.floorz + 32*FU
	me.momx = 0
	me.momy = 0
	p.drawangle = ha

	print(
		"coord",
		("%sa  %.2fd"):format((c1 or c2) and "\x82" or "", me.ra),
		("%sd  %.2f"):format(c3 and "\x82" or "", me.rd),
		"",
		("x  %.2f"):format(me.rx),
		("y  %.2f"):format(me.ry),
		("%sz  %.2f"):format((not (c1 or c2 or c3)) and "\x82" or "", me.rz),
		"",
		("ha %.2fd"):format(AngleFixed(ha)),
		("va %.2fd"):format(AngleFixed(va)),
		"",
		("p  %.2fd"):format(AngleFixed(me.pitch)),
		("r  %.2fd"):format(AngleFixed(me.roll))
	)
	
	v = {
		x = FixedMul(cos(me.pitch), cos(me.roll)),
		y = FixedMul(sin(me.pitch), cos(me.roll)),
		z = sin(me.roll)
	}
	
	for i = 1,5
		local s = step * i
		local g = P_SpawnMobjFromMobj(me,
			FixedMul(s, v.x),
			FixedMul(s, v.y),
			FixedMul(s, v.z),
			MT_UNKNOWN
		)
		g.fuse = 2
		g.scale = $ / 4
		g.frame = 1
		P_SetOrigin(g, g.x,g.y,g.z)
		g.momx = me.momx
		g.momy = me.momy
		g.momz = me.momz
	end
	
	-- pitch
	for i = -5, 5
		local s = step * i
		local g = P_SpawnMobjFromMobj(me,
			P_ReturnThrustX(nil, 0, s),
			P_ReturnThrustY(nil, 0, s),
			-16*FU,
			MT_UNKNOWN
		)
		g.fuse = 2
		if i > 0
			g.scale = $ / 5
		else
			g.scale = $ / 7
		end
		g.colorized = true
		g.color = SKINCOLOR_BLUE
		P_SetOrigin(g, g.x,g.y,g.z)
		g.momx = me.momx
		g.momy = me.momy
		g.momz = me.momz
	end
	-- roll
	for i = -5, 5
		local s = step * i
		local g = P_SpawnMobjFromMobj(me,
			P_ReturnThrustX(nil, ANGLE_90, s),
			P_ReturnThrustY(nil, ANGLE_90, s),
			-16*FU,
			MT_UNKNOWN
		)
		g.fuse = 2
		if i > 0
			g.scale = $ / 5
		else
			g.scale = $ / 7
		end
		g.colorized = true
		g.color = SKINCOLOR_GREEN
		P_SetOrigin(g, g.x,g.y,g.z)
		g.momx = me.momx
		g.momy = me.momy
		g.momz = me.momz
	end
end)
]]--

rawset(_G,"clamp",function(minimum,value,maximum)
	if maximum < minimum
		maximum, minimum = $2, $1
	end
	return max(minimum,min(maximum,value))
end)

rawset(_G,"sign",function(a)
	return (a ~= 0) and (a < 0 and -1 or 1) or 0
end)

rawset(_G,"Soap_RandomFixedSigned",do
	return P_RandomFixed() * sign(P_SignedRandom())
end)
-- Takes 2 fixed_ts and returns a fixed_t
rawset(_G,"Soap_RandomFixedRange",function(a,b)
	return a + FixedMul((b - a), P_RandomFixed())
end)
rawset(_G,"P_RandomSign",do
	return sign(P_SignedRandom()) or -1 -- -1 if sign is 0
end)

--returns lateral and vertical angles
rawset(_G,"R_PointTo3DAngles",function(x1,y1,z1, x2,y2,z2)
	return R_PointToAngle2(x1,y1,x2,y2), R_PointToAngle2(
		0,z1,
		R_PointToDist2(x1,y1,x2,y2), z2
	)
end)

--this function is a fraud...
-- R_PointToDist3D?
rawset(_G,"R_PointTo3DDist",function(x1,y1,z1, x2,y2,z2)
	--return R_PointToDist2(0, 0, R_PointToDist2(x1,y1,x2,y2), z1 - z2)
	return FixedHypot(FixedHypot(x2 - x1, y2 - y1), z2 - z1)
end)

rawset(_G,"P_3DThrust",function(mo, h_ang, v_ang, speed)
	local t = SphereToCartesian(h_ang,v_ang)
	mo.momx = $ + FixedMul(speed, t.x)
	mo.momy = $ + FixedMul(speed, t.y)
	mo.momz = $ + FixedMul(speed, t.z)
end)

rawset(_G,"P_3DInstaThrust",function(mo, h_ang, v_ang, speed)
	local t = SphereToCartesian(h_ang,v_ang)
	mo.momx = FixedMul(speed, t.x)
	mo.momy = FixedMul(speed, t.y)
	mo.momz = FixedMul(speed, t.z)
end)

rawset(_G,"P_Lerp",function(frac, from, to)
	return from + FixedMul(to - from, frac)
end)
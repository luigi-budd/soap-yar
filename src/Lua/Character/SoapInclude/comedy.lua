COM_AddCommand("phys_toggle",function(p)
	if not (p.soaptable) then return end
	if not (p.name == "Epix" or p.soaptable.isElevated) then return end
	if not (p.physgun) then return end
	p.physgun.active = not $
	if (p.physgun.active)
		S_StartSound(p.realmo, sfx_gnpick)
	else
		S_StartSound(p.realmo, sfx_gndrop)
	end
end)

COM_AddCommand("phys_throwforce",function(p, force)
	if not (p.physgun) then return end
	if (force == nil)
		CONS_Printf(p, ("phys_throwforce <decimal>: Adjusts how strong your throw is. Current: %.2f, default %.2f"):format(
			p.physgun.throwforce,
			PhysGun.DEFAULT_THROWFORCE
		))
		return
	end
	force = tofixed($)
	if force == nil
		CONS_Printf(p, "\x85Not a valid input.")
		return
	end
	force = abs($)
	p.physgun.throwforce = force
	CONS_Printf(p, ("\x82Throw force set to %f"):format(force))
end)

sfxinfo[freeslot("sfx_gtro1a")].caption = "Gravity gun throws"
sfxinfo[freeslot("sfx_gtro2a")].caption = sfxinfo[sfx_gtro1a].caption
sfxinfo[freeslot("sfx_gtro3a")].caption = sfxinfo[sfx_gtro1a].caption

sfxinfo[freeslot("sfx_gpick")].caption = "Gravity gun picks up"
sfxinfo[freeslot("sfx_gdrop")].caption = "Gravity gun drops"

sfxinfo[freeslot("sfx_gfir0")].caption = "Gravity gun fires"
sfxinfo[freeslot("sfx_gfir1")].caption = sfxinfo[sfx_gfir0].caption

sfxinfo[freeslot("sfx_gnpick")].caption = "Gravity gun equip"
sfxinfo[freeslot("sfx_gndrop")].caption = "Gravity gun unequip"

rawset(_G, "TR", TICRATE)
local function ResetInterp(g)
	P_SetOrigin(g, g.x,g.y,g.z)
end

local Phys = {}
Phys.DEFAULT_RANGE = 1024*FU
Phys.DEFAULT_THROWFORCE = 100*FU
Phys.createTable = function(p)
	p.physgun = {
		active = false,
		
		target = nil,
		holdmemory = {
			flags = 0
		}, --unused?
		
		--distance to hold it FROM you, not how far away the target is from you
		distance = 400*FU,
		--shot range
		range = Phys.DEFAULT_RANGE,
		throwforce = Phys.DEFAULT_THROWFORCE,
		queuethrow = false,
		holdtime = 0,
		
		--purely visual
		gun = nil,
	}
end
function Phys:holdMobj(p, mo, silent)
	local me = p.realmo
	local ph = p.physgun
	ph.target = mo
	ph.holdmemory.flags = mo.flags
	ph.holdtime = 0
	
	mo.phys_held = true
	if not silent
		S_StartSound(me, sfx_gpick)
	end
end
function Phys:releaseMobj(p, mo, silent)
	local me = p.realmo
	local ph = p.physgun
	ph.target = nil
	ph.holdtime = 0
	mo.flags = $|(mo.info.flags & MF_NOGRAVITY) &~MF_NOGRAVITY --ph.holdmemory.flags
	mo.phys_held = nil
	
	if not silent
		S_StartSound(me, sfx_gdrop)
	end
end
function Phys:throwVFX(p,mo)
	local me = p.realmo
	local ang = R_PointToAngle2(me.x,me.y, mo.x,mo.y)
	local push = FixedDiv(mo.radius,mo.scale) + 3*FU
	local mid = FixedDiv(mo.height,mo.scale)/2 - 4*FU
	
	local ring = P_SpawnMobjFromMobj(mo,
		P_ReturnThrustX(nil,ang,push),
		P_ReturnThrustY(nil,ang,push),
		mid, MT_GHOST
	)
	ring.sprite = states[S_FACESTABBERSPEAR].sprite
	ring.frame = A|FF_FULLBRIGHT|FF_PAPERSPRITE
	ring.tics = 28
	ring.fuse = ring.tics
	ring.destscale = ring.scale*3
	ring.scalespeed = FixedDiv(ring.destscale - ring.scale, ring.fuse*FU)
	ring.color = ColorOpposite(p.skincolor)
	ring.colorized = true
	ring.blendmode = AST_ADD
	ring.angle = ang + ANGLE_90
	--g.scale = $/2
	ResetInterp(ring)

	ring = P_SpawnMobjFromMobj(mo,
		P_ReturnThrustX(nil,ang,push),
		P_ReturnThrustY(nil,ang,push),
		mid, MT_THOK
	)
	P_SetMobjStateNF(ring,S_TNTBARREL_EXPL3)
	ring.renderflags = $|RF_FULLBRIGHT|RF_PAPERSPRITE
	ring.fuse = -1
	ring.destscale = ring.scale*2
	ring.scalespeed = FixedDiv(ring.destscale - ring.scale, ring.tics*FU)
	ring.color = ColorOpposite(p.skincolor)
	ring.colorized = true
	--ring.blendmode = AST_ADD
	ring.angle = ang + ANGLE_90
	--g.scale = $/2
	ResetInterp(ring)
end
function Phys:throwMobj(p,mo)
	local ph = p.physgun
	local me = p.realmo
	local force = FixedMul(ph.throwforce, me.scale)
	P_3DThrust(mo, me.angle,p.aiming, force)
	if (mo.player)
		P_MovePlayer(mo.player)
	end
	
	if (mo == ph.target)
		Phys:releaseMobj(p,mo, true)
	end
	S_StartSound(me, P_RandomRange(sfx_gtro1a,sfx_gtro3a))
end
/*
rawset(_G,"SphereToCartesian",function(alpha, beta)
    local t = {}
    t.x = FixedMul(cos(alpha), cos(beta))
    t.y = FixedMul(sin(alpha), cos(beta))
    t.z = sin(beta)
    return t
end)
rawset(_G,"R_PointTo3DAngles",function(x1,y1,z1, x2,y2,z2)
	return R_PointToAngle2(x1,y1,x2,y2), R_PointToAngle2(
		0,z1,
		R_PointToDist2(x1,y1,x2,y2), z2
	)
end)
rawset(_G,"R_PointTo3DDist",function(x1,y1,z1, x2,y2,z2)
	return FixedHypot(FixedHypot(x2 - x1, y2 - y1), z2 - z1)
end)
rawset(_G,"clamp",function(minimum,value,maximum)
	if maximum < minimum
		local temp = minimum
		minimum = maximum
		maximum = temp
	end
	return max(minimum,min(maximum,value))
end)
rawset(_G,"P_3DThrust",function(mo, h_ang, v_ang, speed)
	local t = SphereToCartesian(h_ang,v_ang)
	mo.momx = $ + FixedMul(speed, t.x)
	mo.momy = $ + FixedMul(speed, t.y)
	mo.momz = $ + FixedMul(speed, t.z)
end)
*/

local function ZCollide(mo1,mo2)
	if mo1.z > mo2.height+mo2.z then return false end
	if mo2.z > mo1.height+mo1.z then return false end
	return true
end

freeslot("S_PHYSGUN",/*"SPR_PHYSGUNSPR",*/"MT_PHYSGUN")
freeslot("SPR_RVOL")
states[S_PHYSGUN] = {
	sprite = SPR_RVOL,
	frame = A,
	tics = 1,
	action = function(mo)
		local t = mo.target
		if not (t and t.valid and t.player and t.player.valid and t.health and t.player.physgun and t.player.physgun.active)
			P_RemoveMobj(mo)
			return
		end
		local angle = t.angle - ANGLE_90
		local dist = t.radius + 8*t.scale
		P_MoveOrigin(mo,
			t.x + P_ReturnThrustX(nil,angle,dist),
			t.y + P_ReturnThrustY(nil,angle,dist),
			t.z + t.height/2
		)
		mo.angle = t.angle
		local aim = InvAngle(t.player.aiming)
		mo.pitch = FixedMul(aim, cos(mo.angle))
		mo.roll = FixedMul(aim, sin(mo.angle))
		
		mo.scale = t.scale
		mo.dontdrawforviewmobj = t
	end,
	nextstate = S_PHYSGUN
}
mobjinfo[MT_PHYSGUN] = {
	doomednum = -1,
	spawnstate = S_PHYSGUN,
	radius = 8*FU,
	height = 8*FU,
	flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_NOBLOCKMAP
}

freeslot("S_PHYSGUN_RAY","MT_PHYSGUN_RAY")
states[S_PHYSGUN_RAY] = {
	sprite = SPR_NULL,
	frame = A,
	tics = 1
}
mobjinfo[MT_PHYSGUN_RAY] = {
	doomednum = -1,
	spawnstate = S_PHYSGUN_RAY,
	radius = 16*FU,
	height = 32*FU,
	flags = MF_NOGRAVITY
}
local function RayVFX(ray, iter)
	if (iter % 6 == 0)
		local g = P_SpawnMobjFromMobj(ray,0,0,-20*FU, MT_GHOST)
		g.sprite = states[S_FACESTABBERSPEAR].sprite
		g.frame = A|FF_FULLBRIGHT|FF_PAPERSPRITE
		g.tics = 6
		g.fuse = g.tics
		g.color = ray.color
		g.colorized = true
		g.blendmode = AST_ADD
		g.angle = ray.angle + ANGLE_90
		g.scale = $/2
		if (ray.oneshot)
			g.type = MT_PARTICLE
			g.fuse = 2
			g.alpha = $/2
			g.scale = $/2
			g.z = $ + 8*ray.scale
		end
		ResetInterp(g)
	end
	local range = 5
	for j = 0,1
		local g = P_SpawnMobjFromMobj(ray,
			P_RandomRange(-range,range)*FU,
			P_RandomRange(-range,range)*FU,
			P_RandomRange(-range,range)*FU,
			MT_GHOST
		)
		g.scale = $/4
		g.color = ray.color
		g.colorized = true
		g.blendmode = AST_ADD
		g.frame = $|FF_FULLBRIGHT
		g.alpha = FU/2
		g.fuse = 10
		if (ray.oneshot)
			g.type = MT_PARTICLE
			g.fuse = 2
			--g.alpha = $/2
		end
		ResetInterp(g)
	end
	if not ray.nosparks
	and (P_RandomChance(FU/2))
		local g = P_SpawnMobjFromMobj(ray,
			P_RandomRange(-range,range)*FU,
			P_RandomRange(-range,range)*FU,
			P_RandomRange(-range,range)*FU,
			MT_GHOST
		)
		g.state = S_SHOCKWAVE1
		g.color = ray.color
		g.colorized = true
		g.blendmode = AST_ADD
		g.frame = $|FF_FULLBRIGHT
		g.scale = FU/5 + P_RandomFixed()/3
		g.mirrored = P_RandomChance(FU/2)
		local ha,va = R_PointTo3DAngles(g.x,g.y,g.z, ray.x,ray.y,ray.z)
		g.rollangle = va
		
		g.angle = ray.angle + ANGLE_90 + FixedAngle(P_RandomRange(-60,60)*FU)
		g.fuse = P_RandomRange(states[S_SHOCKWAVE1].tics, states[S_SHOCKWAVE1].tics/2)
		ResetInterp(g)
	end
end
local function colSearcher(ray, mo)
	if not (ray and ray.valid) then return end
	if not (mo and mo.valid) then return end
	if (mo == ray.target) then return end
	if (mo.type == ray.type) then return end
	if abs(ray.x - mo.x) > mo.radius + ray.radius
	or abs(ray.y - mo.y) > mo.radius + ray.radius
		return
	end
	if not ZCollide(ray,mo) then return end
	
	local me = ray.target
	local p = me.player
	local ph = p.physgun
	ph.distance = FixedDiv(R_PointTo3DDist(me.x,me.y,me.z, mo.x,mo.y,mo.z),me.scale)
	Phys:holdMobj(p,mo, ray.silent)
	P_RemoveMobj(ray)
	return true
end
addHook("MobjThinker",function(ray)
	if not (ray and ray.valid) then return end
	local org = ray.origin
	local dist = 0
	local iter = 0
	repeat
		if not (ray and ray.valid) then return; end
		if P_RailThinker(ray) then return; end
		if not (ray and ray.valid) then return; end
		if (ray.z <= ray.floorz or ray.z + ray.height >= ray.ceilingz)
		or not P_CheckPosition(ray, ray.x+ray.momx, ray.y+ray.momx, ray.z+ray.momz)
			if (ray and ray.valid) --WTF LOL???? WHY GAME WHYYY
				P_RemoveMobj(ray)
			end
			return
		end
		RayVFX(ray, iter + (leveltime + #ray.target.player))
		
		iter = $ + 1
		dist = R_PointTo3DDist(org.x,org.y,org.z, ray.x,ray.y,ray.z)
		
		if not (ray.visual)
			local br = ray.radius --+ 16*ray.scale
			local px = ray.x
			local py = ray.y
			searchBlockmap("objects",colSearcher, ray, px-br, px+br, py-br, py+br)
			if not (ray and ray.valid) then return; end
		end
	until (dist >= ray.range)
end,MT_PHYSGUN_RAY)
addHook("MobjMoveBlocked",function(ray, mo, line)
	if not (ray and ray.valid) then return end
	if (mo and mo.valid) then return end
	if (line and line.valid)
		P_RemoveMobj(ray)
	end
end,MT_PHYSGUN_RAY)
local function colFunc(ray, mo)
	--print("collide",mo.type, mo.info.doomednum, mo.info.typename)
	if not (ray and ray.valid) then return end
	if (ray.visual) then return end
	if not (ray.target and ray.target.valid) then return end
	if not (mo and mo.valid) then return end
	if (mo.phys_held) then return end
	if (mo == ray.target) then return end
	if not ZCollide(ray,mo) then return end
	
	local me = ray.target
	local p = me.player
	local ph = p.physgun
	ph.distance = FixedDiv(R_PointTo3DDist(me.x,me.y,me.z, mo.x,mo.y,mo.z),me.scale)
	Phys:holdMobj(p,mo, ray.silent)
	P_RemoveMobj(ray)
end
addHook("MobjMoveCollide",colFunc,MT_PHYSGUN_RAY)

function Phys:aimRay(p, ray, ang, aim)
	local speed = R_PointToDist2(0,0, ray.momx,ray.momy)
	if not speed then return end
	
	local me = p.realmo
	local ph = p.physgun
	
	local point = {
		x = me.x + P_ReturnThrustX(nil,ang,FixedMul(ph.range, me.scale)),
		y = me.y + P_ReturnThrustY(nil,ang,FixedMul(ph.range, me.scale)),
	}
	ray.angle = R_PointToAngle2(ray.x,ray.y, point.x,point.y)
	P_InstaThrust(ray, ray.angle, speed)
	
	ray.momx = FixedMul($, cos(aim))
	ray.momy = FixedMul($, cos(aim))
	ray.momz = FixedMul(speed, sin(aim))
end
function Phys:fireRay(p, nosound, visual, opposite)
	local ph = p.physgun
	local me = p.realmo
	local ang = me.angle
	local aim = p.aiming
	local ray = P_SpawnMobjFromMobj(me,
		2*cos(ang), 2*sin(ang),
		41*FixedDiv(me.height,me.scale)/48 - 8*FU,
		MT_PHYSGUN_RAY
	)
	ray.target = me
	ray.origin = {x = me.x, y = me.y, z = ray.z}
	ray.range = ph.range
	ray.lifespan = 0
	ray.silent = nosound
	ray.visual = visual
	ray.color = (ph.queuethrow or opposite) and ColorOpposite(p.skincolor) or p.skincolor
	P_SetOrigin(ray,
		ray.x + me.momx,
		ray.y + me.momy,
		ray.z + me.momz
	)
	if not (nosound)
		S_StartSound(me, P_RandomRange(sfx_gfir0,sfx_gfir1))
	end
	
	if not (ray and ray.valid) then return end
	P_InstaThrust(ray, ang, ray.radius*2)
	
	Phys:aimRay(p,ray, ang, aim)
	return ray
end
rawset(_G,"PhysGun",Phys)

addHook("PlayerThink",function(p)
	if not (p and p.valid) then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	if not p.physgun
		Phys.createTable(p)
		return
	end
	local ph = p.physgun
	
	if not ph.active
		if (ph.target and ph.target.valid)
			Phys:releaseMobj(p,ph.target)
		end
		return
	end
	
	if not (ph.gun and ph.gun.valid)
		local g = P_SpawnMobjFromMobj(me, 0,0,0, MT_PHYSGUN)
		g.target = me
		ph.gun = g
	end
	
	local fireinput = (p.cmd.buttons & BT_ATTACK) and not (p.lastbuttons & BT_ATTACK)
	local throwinput = (p.cmd.buttons & BT_FIRENORMAL) and not (p.lastbuttons & BT_FIRENORMAL)
	local hold = ph.target
	if (ph.queuethrow)
		if (ph.target and ph.target.valid)
			Phys:throwVFX(p, ph.target)
			Phys:throwMobj(p, ph.target)
		else
			S_StartSound(me, P_RandomRange(sfx_gfir0,sfx_gfir1))
		end
		ph.queuethrow = false
	end
	
	-- Grab stuff!
	if not (hold and hold.valid)
		ph.range = Phys.DEFAULT_RANGE
		if fireinput
			Phys:fireRay(p)
		elseif (throwinput)
			ph.queuethrow = true
			Phys:fireRay(p, true, false, true)
		end
	else
		if fireinput
			Phys:releaseMobj(p, hold)
		elseif (throwinput)
			Phys:fireRay(p, true, true, true)
			Phys:throwVFX(p, ph.target)
			Phys:throwMobj(p, hold)
		end
	end
	hold = ph.target
	
	local dist_change = 0
	if (p.cmd.buttons & BT_WEAPONNEXT)
		dist_change = 16*FU
	elseif (p.cmd.buttons & BT_WEAPONPREV)
		dist_change = -16*FU
	end
	ph.distance = clamp(100*FU, $ + dist_change, 1000*FU)
	--ph.range = ph.distance*14/10
	
	if (hold and hold.valid)
	and (R_PointTo3DDist(me.x,me.y,me.z, hold.x,hold.y,hold.z) <= FixedMul(ph.distance+32*FU,me.scale) + (hold.radius*4) + (me.radius))
		ph.holdtime = $ + 1
		local ang = me.angle
		local aim = p.aiming
		local range = FixedMul(ph.distance, me.scale)
		local vec = {
			x = FixedMul(P_ReturnThrustX(nil,ang,range), cos(aim)) + me.momx,
			y = FixedMul(P_ReturnThrustY(nil,ang,range), cos(aim)) + me.momy,
			z = (41*FixedDiv(me.height,me.scale)/48 - 8*FU) + FixedMul(range, sin(aim)),
		}
		hold.flags = $|MF_NOGRAVITY
		local easing = FU/4
		
		hold.momx = FixedMul((me.x + vec.x) - hold.x, easing)
		hold.momy = FixedMul((me.y + vec.y) - hold.y, easing)
		hold.momz = FixedMul((me.z + vec.z) - hold.z, easing)
		
		local chance = true
		local sparks = true
		local distanceto = ph.distance*3/2 - R_PointTo3DDist(me.x,me.y,me.z, hold.x,hold.y,hold.z)
		if distanceto <= 64*me.scale
			chance = (leveltime/2) % 2
			sparks = false
		elseif distanceto <= 200*me.scale
			sparks = false
		end
		
		if chance
			local olddist = ph.range
			ph.range = range
			
			local ray = Phys:fireRay(p, true, true, false)
			ray.oneshot = true
			ray.nosparks = not sparks
			
			ang,aim = R_PointTo3DAngles(ray.x,ray.y,ray.z, hold.x,hold.y,hold.z)
			P_SetOrigin(ray, ph.gun.x, ph.gun.y, ph.gun.z)
			P_InstaThrust(ray, ang, ray.radius*2)
			ray.origin = {x = ph.gun.x, y = ph.gun.y, z = ph.gun.z}
			ray.range = range
			
			Phys:aimRay(p, ray, ang, aim)
			
			ph.range = olddist
		end
	else
		if (ph.target and ph.target.valid)
			Phys:releaseMobj(p,ph.target)
		end
		ph.target = nil
	end
end)

addHook("HUD",function(v,p,c)
	if not p.physgun then return end
	local ph = p.physgun
	local hold = ph.target
	
	v.dointerp = function(tag)
		if v.interpolate == nil then return end
		v.interpolate(tag)
	end
	
	if (ph.holdtime >= 10*TR) then return end
	if (ph.queuethrow) then return end
	if not (hold and hold.valid) then return end
	local w2s = K_GetScreenCoords(v,p,c, hold, {anglecliponly = true})
	if not (w2s.onscreen) then return end
	
	v.dointerp(true)
	w2s.x = $ + 16*w2s.scale
	v.drawString(w2s.x,w2s.y,
		"\x82[FIRE]:\x80 Release",
		V_ALLOWLOWERCASE|V_20TRANS, "small-thin-fixed")
		
	v.drawString(w2s.x,w2s.y+4*FU,
		"\x82[FIRE NORMAL]:\x80 Throw",
		V_ALLOWLOWERCASE|V_20TRANS, "small-thin-fixed")
		
	v.drawString(w2s.x,w2s.y+8*FU,
		"\x82[W. NEXT/PREV]:\x80 Adjust Distance",
		V_ALLOWLOWERCASE|V_20TRANS, "small-thin-fixed")
	/*
	v.drawString(w2s.x,w2s.y+12*FU,
		("\x82\Distance:\x80 %.1f FU"):format(ph.distance),
		V_ALLOWLOWERCASE|V_20TRANS, "small-thin-fixed")
	*/
	v.dointerp(false)
end,"game")
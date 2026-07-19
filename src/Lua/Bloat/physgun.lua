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

rawset(_G,"PhysGun",{})
local Phys = PhysGun
Phys.DEFAULT_RANGE = 1024*FU
Phys.DEFAULT_THROWFORCE = 100*FU
Phys.DEFAULT_DISTNUDGE = 16*FU
Phys.createTable = function(p)
	p.physgun = {
		active = false,
		
		mode = "physgun",
		toolgun = {
			hit = -1, --{x, y, z}
			type = MT_RING,
		},
		
		target = nil,
		holdmemory = {
			flags = 0,
			mobj = nil
		}, --unused?
		
		--distance to hold it FROM you, not how far away the target is from you
		distance = 400*FU,
		distance_nudge = Phys.DEFAULT_DISTNUDGE,
		lost_timer = 0,
		
		--shot range
		range = Phys.DEFAULT_RANGE,
		throwforce = Phys.DEFAULT_THROWFORCE,
		queuethrow = false,
		holdtime = 0,
		
		--purely visual
		gun = nil,
	}
end

function Phys:setGunRecoil(p)
	local ph = p.physgun
	local gun = ph.gun
	if not (gun and gun.valid) then return end
	gun.kickback = 8
end

function Phys:holdMobj(p, mo, silent)
	local me = p.realmo
	local ph = p.physgun
	ph.target = mo
	
	if ph.holdmemory.mobj ~= mo
		ph.holdmemory.flags = mo.flags
		ph.holdmemory.mobj = mo
	end
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
	ph.holdmemory.mobj = nil
	
	mo.flags = $ &~MF_NOGRAVITY
	mo.flags = $|(mo.info.flags & MF_NOGRAVITY)|(ph.holdmemory.flags & MF_NOGRAVITY)
	mo.phys_held = nil
	
	if (mo.flags & MF_NOGRAVITY)
	-- dont remove throw momentum
	-- bad, but silent isnt used anywhere else
	and not silent
		mo.momx,mo.momy,mo.momz = 0,0,0
	end
	
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
	Phys:setGunRecoil(p)
end

rawset(_G,"SphereToCartesian",function(alpha, beta)
    local t = {}
    t.x = FixedMul(cos(alpha), cos(beta))
    t.y = FixedMul(sin(alpha), cos(beta))
    t.z = sin(beta)
    return t
end)
local function ZCollide(mo1,mo2)
	if mo1.z > mo2.height+mo2.z then return false end
	if mo2.z > mo1.height+mo1.z then return false end
	return true
end

freeslot("S_PHYSGUN",/*"SPR_PHYSGUNSPR",*/"MT_PHYSGUN")
freeslot("SPR_RVOL")
freeslot("SPR_LUGR")
states[S_PHYSGUN] = {
	sprite = SPR_LUGR,
	frame = A,
	tics = 1,
	action = function(mo)
		local t = mo.target
		if not (t and t.valid and t.player and t.player.valid and t.health and t.player.physgun and t.player.physgun.active)
			P_RemoveMobj(mo)
			return
		end
		mo.kickback = $ or 0
		local angle = t.angle - ANGLE_90
		local dist = t.radius + 8*t.scale
		local recoil = (mo.kickback*mo.scale) * 4
		P_MoveOrigin(mo,
			t.x + P_ReturnThrustX(nil,angle,dist) - P_ReturnThrustX(nil,t.angle,recoil),
			t.y + P_ReturnThrustY(nil,angle,dist) - P_ReturnThrustY(nil,t.angle,recoil),
			t.z + t.height/2
		)
		mo.kickback = max($-1, 0)
		mo.angle = t.angle
		local aim = InvAngle(t.player.aiming)
		mo.pitch = FixedMul(aim, cos(mo.angle))
		mo.roll = FixedMul(aim, sin(mo.angle))
		
		mo.scale = t.scale
		mo.dontdrawforviewmobj = t
		if (t.player.physgun.mode == "toolgun")
			mo.sprite = SPR_RVOL
		end
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

function Phys:rayHits(ray, mo)
	local me = ray.target
	local p = me.player
	local ph = p.physgun
	if ray.mode == "physgun"
		if not (mo and mo.valid) then return end
		
		ph.distance = FixedDiv(R_PointTo3DDist(me.x,me.y,me.z, mo.x,mo.y,mo.z),me.scale)
		Phys:holdMobj(p,mo, ray.silent)
	elseif ray.mode == "toolgun"
		ph.toolgun.hit = {x = ray.x, y = ray.y, z = ray.z}
	end
end

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
	
	Phys:rayHits(ray,mo)
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
				Phys:rayHits(ray)
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
		Phys:rayHits(ray)
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
	
	Phys:rayHits(ray,mo)
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
	ray.mode = ph.mode
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
	if not (visual)
		Phys:setGunRecoil(p)
	end
	return ray
end

function Phys:physgun_thinker(p, ph, me)
	if (ph.mode ~= "physgun")
		if (ph.target and ph.target.valid)
			Phys:releaseMobj(p,ph.target)
		end
		return
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
		dist_change = ph.distance_nudge
	elseif (p.cmd.buttons & BT_WEAPONPREV)
		dist_change = -ph.distance_nudge
	end
	if dist_change ~= 0
		--print(p.cmd.buttons & BT_FIRENORMAL)
	end
	ph.distance = clamp(100*FU, $ + dist_change, 1000*FU)
	--ph.range = ph.distance*14/10
	
	local inrange = false
	if (hold and hold.valid)
		inrange = true
		if R_PointTo3DDist(me.x,me.y,me.z, hold.x,hold.y,hold.z) > FixedMul(ph.distance+32*FU,me.scale) + (hold.radius*4) + (me.radius)
			ph.lost_timer = $ + 1
			if ph.lost_timer >= TR
				inrange = false
			end
		else
			ph.lost_timer = 0
		end
	else
		ph.lost_timer = 0
	end
	
	if (hold and hold.valid)
	and (inrange)
		ph.holdtime = $ + 1
		local ang = me.angle
		local aim = p.aiming
		local range = FixedMul(ph.distance, me.scale)
		local vec = {
			x = FixedMul(P_ReturnThrustX(nil,ang,range), cos(aim)) + me.momx,
			y = FixedMul(P_ReturnThrustY(nil,ang,range), cos(aim)) + me.momy,
			z = (41*(me.height)/48 - 8*FU) + FixedMul(range, sin(aim)),
		}
		hold.flags = $|MF_NOGRAVITY
		local easing = FU/3
		
		/*
		hold.momx = FixedMul((me.x + vec.x) - hold.x, easing)
		hold.momy = FixedMul((me.y + vec.y) - hold.y, easing)
		hold.momz = FixedMul((me.z + vec.z) - hold.z, easing)
		if (hold.flags & MF_NOTHINK)
			P_XYMovement(hold)
			if (hold and hold.valid)
				P_ZMovement(hold)
			end
			if not (hold and hold.valid)
				ph.target = nil
				return
			end
		end
		*/
		
		P_TryMove(hold,
			me.x + vec.x,-- + FixedMul((me.x + vec.x) - hold.x, easing),
			me.y + vec.y,-- + FixedMul((me.y + vec.y) - hold.y, easing),
			true
		)
		hold.z = clamp(hold.floorz, me.z + vec.z, hold.ceilingz - hold.height)
		hold.momx = 0
		hold.momy = 0
		hold.momz = 0
		
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
		ph.lost_timer = 0
		if (ph.target and ph.target.valid)
			Phys:releaseMobj(p,ph.target)
		end
		ph.target = nil
	end
end

function Phys:toolgun_thinker(p, ph, me)
	if (ph.mode ~= "toolgun")
		return
	end
	if (ph.target and ph.target.valid)
		Phys:releaseMobj(p,ph.target)
	end
	
	local fireinput = (p.cmd.buttons & BT_ATTACK) and not (p.lastbuttons & BT_ATTACK)
	if fireinput
		Phys:fireRay(p)
	end
	
	if ph.toolgun.hit ~= -1
		local pos = ph.toolgun.hit
		local new = P_SpawnMobj(
			pos.x,pos.y,pos.z, ph.toolgun.type
		)
		P_SetScale(new, me.scale, true)
		new.angle = me.angle
		if (new.frame & FF_PAPERSPRITE or new.renderflags & RF_PAPERSPRITE)
			new.angle = $ - ANGLE_90
		end
		ph.toolgun.hit = -1
	end
	
	/*
	-- Grab stuff!
	if not (hold and hold.valid)
		ph.range = Phys.DEFAULT_RANGE
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
	*/
end

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
	
	Phys:physgun_thinker(p, ph, me)
	Phys:toolgun_thinker(p, ph, me)
end)

COM_AddCommand("phys_toggle",function(p)
	if not (p.physgun) then return end
	p.physgun.active = not $
	if (p.physgun.active)
		S_StartSound(p.realmo, sfx_gnpick)
	else
		S_StartSound(p.realmo, sfx_gndrop)
	end
end,COM_ADMIN)

COM_AddCommand("phys_mode",function(p, mode)
	if not (p.physgun) then return end
	
	local valid = false
	local str = "Not a valid mode."
	if mode == "physgun"
		str = "Set mode to 'physgun'"
		valid = true
	elseif mode == "toolgun"
		str = "Set mode to 'toolgun'"
		valid = true
	end
	if valid
		p.physgun.mode = mode
	end
	CONS_Printf(p, str)
end,COM_ADMIN)

COM_AddCommand("phys_toolgun_type",function(p, type)
	if not (p.physgun) then return end
	if (type == nil)
		CONS_Printf(p, ("phys_toolgun_type <type>: Accepts numerical ID or MT_* type. Current ID: %d"):format(
			p.physgun.toolgun.type
		))
		return
	end
	
	local mobjtype
	if tonumber(type) ~= nil
		mobjtype = abs(tonumber(type))
		if (mobjinfo[mobjtype] == nil)
			mobjtype = nil
		end
	else
		if tostring(type) ~= nil
			local tstring = string.upper(tostring(type))
			if (string.sub(tstring,1,3) ~= "MT_")
				tstring = "MT_"..$
			end
			if constants[tstring] ~= nil
				mobjtype = constants[tstring]
			end
		end
	end
	
	if mobjtype == nil
		prn(p,"Type does not exist")
		return
	end
	
	p.physgun.toolgun.type = mobjtype
	CONS_Printf(p, ("\x82Set type to %s"):format(
		tostring(mobjtype)
	))
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

COM_AddCommand("phys_distadjust",function(p, force)
	if not (p.physgun) then return end
	if (force == nil)
		CONS_Printf(p, ("phys_distadjust <decimal>: Adjusts how much you adjust object distance by. Current: %.2f, default %.2f"):format(
			p.physgun.distance_nudge,
			PhysGun.DEFAULT_DISTNUDGE
		))
		return
	end
	force = tofixed($)
	if force == nil
		CONS_Printf(p, "\x85Not a valid input.")
		return
	end
	force = abs($)
	p.physgun.distance_nudge = force
	CONS_Printf(p, ("\x82\Distance nudge set to %f"):format(force))
end)

addHook("HUD",function(v,p,c)
	if not p.physgun then return end
	local ph = p.physgun
	local hold = ph.target
	
	if not ph.active then return end
	if ph.mode == "physgun" or ph.mode == "toolgun"
		v.drawString(160, 170, ph.mode == "physgun" and "Physgun" or "Toolgun", V_ALLOWLOWERCASE|V_YELLOWMAP|V_50TRANS, "small-center")
	end
	
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

local ML = MenuLib
local buffer = ""
local bufferid = ML.newBufferID()

local MT_FIRSTFREESLOT = 660

-- "if i can iterate from `0` to `MT_FIRSTFREESLOT` once,
--	then when an addon is loaded i search from `MT_FIRSTFREESLOT`
--	to `#mobjinfo - 1` and update anything i need to update"
local num_validmobjs = 0
local valid_mobjids = {}
local setvanilla = false
local function repopulate()
	local loop_start = MT_FIRSTFREESLOT
	local loop_end = #mobjinfo - 1
	if not setvanilla
		loop_start = 1 --Never count MT_NULL
		setvanilla = true
		-- vanilla valid_mobjids will always be valid
	end
	
	for i = loop_start, loop_end
		local info = mobjinfo[i]
		if info ~= nil
		and not (info.spawnstate == 0 and info.doomednum == -1) --Must be valid.
		and (valid_mobjids[i + 1] == nil)
			valid_mobjids[i + 1] = true
			num_validmobjs = $ + 1
			--print(("mobj id %d, type %s valid"):format(i, info.typename))
		else
			--There should not be holes in mobjinfo.
			continue
		end
	end
end
repopulate()
addHook("AddonLoaded",repopulate)

local FF_to_V = {
	[0] = 0,
	-- FF_BLENDMASK
	[FF_ADD] = V_ADD,
	[FF_MODULATE] = V_MODULATE,
	[FF_REVERSESUBTRACT] = V_REVERSESUBTRACT,
	[FF_SUBTRACT] = V_SUBTRACT,
	-- FF_TRANSMASK
	[FF_TRANS10] = V_10TRANS,
	[FF_TRANS20] = V_20TRANS,
	[FF_TRANS30] = V_30TRANS,
	[FF_TRANS40] = V_40TRANS,
	[FF_TRANS50] = V_50TRANS,
	[FF_TRANS60] = V_60TRANS,
	[FF_TRANS70] = V_70TRANS,
	[FF_TRANS80] = V_80TRANS,
	[FF_TRANS90] = V_90TRANS,
}

local clicktime = 0
local grabbed = false

local older_id = 0
local old_id = 0
local old_ticker = 0
local topbutton = {x = 0,y = 0,id = 0, active = false}

local card_width = 35
local card_height = 41
local card_menu

local animtimer = 0
local animframe = 0
local animated = false
local animstate = false
local animmem = states[S_NULL]
local function drawMobjCard(v, x,y, id, visual, uncapped)
	local info = mobjinfo[id]
	local invalid = false
	if not valid_mobjids[id + 1] then invalid = true; end
	if not invalid and not grabbed
		ML.addButton(v, {
			id = 100 + id,
			x = x,y = y,
			
			width = card_width,
			height = card_height,
			
			color = card_menu.color,
			outline = card_menu.color,
			
			name = "",
			pressFunc = function()
				if not visual
					ML.client.commandbuffer = "phys_toolgun_type "..id
				else
					local menu = ML.menus[ML.client.currentMenu.id]
					local id = id
					if (id % 5 == 0)
						id = $ - 1
					end
					menu.scroll = ((id/5)*5) + 1
				end
			end
		})
	end
	
	local baseclr = 22
	local insetclr = 26
	if invalid
		baseclr = 43
		insetclr = 47
	end
	v.drawFill(x,y, card_width, card_height, baseclr)
	v.drawFill(x+1,y+1, card_width-2,1, insetclr) --left
	v.drawFill(x+1,y+card_height-2, card_width-2,1, insetclr) --right
	v.drawFill(x+1,y+1, 1,card_height-2, insetclr) --up
	v.drawFill(x+card_width-2,y+1, 1,card_height-2, insetclr) --down
	
	local extraflags = 0
	if not invalid
		local state = states[info.spawnstate]
		local seestate = states[info.seestate]
		if (info.flags & MF_SPRING)
			seestate = states[info.raisestate]
		end
		if (seestate.sprite ~= state.sprite)
			seestate = state
		end
		
		local sprite
		local flip = 0
		if old_id ~= older_id
			animtimer = 0
			animframe = 0
		end
		if state.sprite ~= SPR_NULL
			if state.sprite == SPR_PLAY
				sprite = v.cachePatch("PLAYA0")
			else
				local frame = state.frame & FF_FRAMEMASK
				extraflags = (FF_to_V[state.frame & FF_BLENDMASK] or 0)|(FF_to_V[state.frame & FF_TRANSMASK] or 0)
				
				if older_id == 100 + id
					--what a huge mess
					if (state.frame & FF_ANIMATE)
					and (state.var1 > 0)
					and (state.var2 ~= 0)
						if not animated
							animtimer = $ + 1
							if (animtimer % state.var2 == 0)
								animframe = ($ + 1) % state.var1
							end
							animated = true
						end
						frame = ($ + animframe) & FF_FRAMEMASK
						animstate = false
						animmem = state
					elseif (seestate)
					and seestate.sprite == state.sprite
						if not animated
							if not animstate
								animtimer = state.tics
								animmem = seestate
								animstate = true
							end
							animtimer = $ - 1
							if animtimer <= 0
								local next = states[animmem.nextstate]
								if next.sprite == animmem.sprite
									animmem = next
								else
									animmem = seestate
								end
								animtimer = animmem.tics
							end
							extraflags = (FF_to_V[animmem.frame & FF_BLENDMASK] or 0)|(FF_to_V[animmem.frame & FF_TRANSMASK] or 0)
							animframe = (animmem.frame & FF_FRAMEMASK) - frame
							animated = true
						end
						frame = ($ + animframe) & FF_FRAMEMASK
					else
						animtimer = 0
						animframe = 0
						animmem = state
						animstate = false
					end
				end
				sprite,flip = v.getSpritePatch(state.sprite, frame, 2)
			end
		end
		if sprite == nil
			sprite = v.getSpritePatch("UNKN",A,0)
		end
		
		local sprite_bot = (card_height - 20)*FU
		local scale = FU/2
		do
			local top = FixedMul((sprite.height + (sprite.topoffset - sprite.height))*FU, scale)
			local over = (y + sprite_bot) - top
			if over < y
				local adjust = (y - over) / 60
				scale = FU/2 - abs(adjust)
			end
		end
		
		v.drawScaled((x + card_width/2)*FU, y*FU + sprite_bot, max(scale, FU/10),
			sprite, (flip and V_FLIP or 0)|extraflags, nil
		)
	end
	
	v.drawString(x + card_width/2, y + card_height - 10,
		"#"..id, 0, "thin-center"
	)
	if info.typename or info.name ~= nil
		local name = info.typename or info.name
		if (name:sub(1,3) ~= "MT_")
			name = "MT_"..$
		end
		if name:len() > 12 and not uncapped
			name = name:sub(1,12).."..."
		end
		if uncapped
			local wd = (v.stringWidth(name, 0, "thin") / 2) + 2
			local he = 6 / 2
			v.drawFill(
				(x + card_width/2) - wd/2,
				(y + card_height - 15) - he/2,
				wd, he + 2, 26
			)
		end
		v.drawString(x + card_width/2, y + card_height - 15,
			name, V_YELLOWMAP, "small-thin-center"
		)
	end
end

local filterstring = ""
ML.addMenu({
	stringId = "Phys_TypeSelector",
	title = "Spawn Menu",
	ms_flags = MS_NOANIM,
	
	width = 291,
	height = 131,
	
	exit = function()
		buffer = ""
		clicktime = 0
		grabbed = false
	end,
	drawer = function(v, ML, menu, props)
		local x = props.corner_x
		local y = props.corner_y + 14
		
		menu.scroll = $ or 1
		card_menu = menu
		
		local p = consoleplayer
		if not (p and p.valid) then return end
		local ph = p.physgun
		if not (ph) then return end
		
		older_id = old_id
		animated = false
		local bottom_height = 45
		
		if mouse.buttons & MB_BUTTON1
			clicktime = $ + 1
		else
			clicktime = 0
			grabbed = false
		end
		local within_scrollbar = false
		do
			local mx = ML.client.mouse_x
			local my = ML.client.mouse_y
			if  mx >= x*FU and mx <= (x+6)*FU
			and my >= y*FU and my <= (y + (props.fakeheight - bottom_height) - 1)*FU
				within_scrollbar = true
			end
		end
		
		if clicktime == 1
			if within_scrollbar
				grabbed = true
			end
		end
		if grabbed
			local y = y *FU
			local my = ML.client.mouse_y
			local height = (props.fakeheight - bottom_height)*FU
			my = ML.clamp(y, $, y + height) - y
			menu.scroll = (FixedMul((num_validmobjs/5)*FU, FixedDiv(my, height) )/FU) * 5
			menu.scroll = max($ + 1,1)
		end
		
		--"selected" panel
		local panel_width = 100
		do
			local x = x + props.fakewidth - panel_width
			local y = y
			if (props.fakeheight > 14)
				v.drawFill(x, y, 1,props.fakeheight-14, 0)
			end
			
			v.drawString((x + panel_width) - 4 - card_width,
				y + 2, "Selected:", V_ALLOWLOWERCASE|V_YELLOWMAP, "thin-right"
			)
			ML.interpolate(v,4000 + ph.toolgun.type)
			drawMobjCard(v, (x + panel_width) - 2 - card_width,
				y + 2, ph.toolgun.type, true
			)
			ML.interpolate(v,true)
			
			y = y + (menu.height - 50) - (30 + 4)
			x = $ + 4
			
			--TODO: "throwforce" and "distadjust" buttons
			v.drawString(x,y, "Phys-gun:", V_ALLOWLOWERCASE,"thin")
			ML.addButton(v, {
				id = 1,
				x = x,y = y + 10,
				
				width = panel_width - 8,
				height = 20,
				
				color = 13,
				outline = 19,
				
				name = ph.active and "On" or "Off",
				pressFunc = function()
					ML.client.commandbuffer = "phys_toggle"
				end
			})
			y = $ + 34
			
			-- y = starting_y + 130
			v.drawString(x,y, "Phys-gun Mode:", V_ALLOWLOWERCASE,"thin")
			ML.addButton(v, {
				id = 1,
				x = x,y = y + 10,
				
				width = panel_width - 8,
				height = 20,
				
				color = 13,
				outline = 19,
				
				name = '"'..ph.mode..'"',
				pressFunc = function()
					local newmode = ph.mode == "toolgun" and "physgun" or "toolgun"
					ML.client.commandbuffer = "phys_mode "..newmode
				end
			})
		end
		
		--scrolling menu (180, 86 free space)
		if not old_ticker
			topbutton = {x = 0,y = 0,id = 0, active = false}
		end
		do
			local scrolled = false
			if mouse.buttons & MB_SCROLLDOWN
				local invalids = 0
				for i = 0,4
					if not valid_mobjids[menu.scroll + i + 6]
						invalids = $ + 1
					end
				end
				local valid = invalids < 4
				if valid
					menu.scroll = min($ + 5, num_validmobjs + (num_validmobjs % 5))
					scrolled = true
				end
			elseif mouse.buttons & MB_SCROLLUP
				menu.scroll = max($ - 5, 1)
				scrolled = true
			end
			if scrolled
				topbutton = {x = 0,y = 0,id = 0, active = false}
				--old_id = 0
				old_ticker = 0
			end
			
			old_ticker = max($-1, 0)
			local y = y + 1
			local x = x + 7
			local start = x
			ML.interpolate(v,false)
			local workid = 0
			local i = 0
			while true
				--ML.interpolate(v, id)
				local id = menu.scroll + workid
				workid = $ + 1
				if (takis_custombuild)
				and (filterstring ~= "")
					if (id > (#mobjinfo-1))
						break
					end
					
					local info = mobjinfo[id]
					if not (info and info.typename ~= nil)
						continue
					end
					if not (info.typename:find(filterstring))
						continue
					end
				end
				
				drawMobjCard(v, x,y, id, (old_id == id))
				if (ML.client.hovering == 100 + id)
				and not old_ticker
					topbutton.active = true
					topbutton.x = x; topbutton.y = y; topbutton.id = id
					--old_id = id
					old_ticker = 4
				end
				
				x = $ + card_width + 2
				if i == 4
					y = $ + card_height + 2
					x = start
				end
				i = $ + 1
				if i > 9 then break end
			end
			ML.interpolate(v,true)
			if ML.client.hovering == -1
			and old_ticker < 3
				topbutton = {x = 0,y = 0,id = 0, active = false}
				old_id = 0
			end
		end
		old_id = ML.client.hovering
		if older_id ~= old_id
			animstate = false
		end
		
		do
			local x = x
			local y = y
			
			--scroll bar and text input AFTER
			--TODO: make the background a button and set menu.scroll based on mouse.y
			--		probably just easier to check for mouse presses and coords
			if (props.fakeheight > bottom_height)
				local baseclr = 29
				local barclr = 20
				if within_scrollbar or grabbed
					baseclr = 30
					barclr = grabbed and 26 or 22
				end
				local height = (props.fakeheight - bottom_height)
				local scrollheight = max(FixedDiv(height*FU, (num_validmobjs/10)*FU) / FU, 1)
				local offset = FixedMul(height*FU, FixedDiv(menu.scroll*FU, num_validmobjs*FU)) / FU
				v.drawFill(x,y,6, height, baseclr)
				v.drawFill(x,y + offset,6, scrollheight, barclr)
			end
			
			y = $ + props.fakeheight - bottom_height
			v.drawFill(x,y,max(props.fakewidth - panel_width, 1), 1,  0)
			
			-- "Type a MT_ name..."
			do
				local x = x + 4
				local y = y + 5
				local width = (props.fakewidth - panel_width) - 8
				-- filter/exact mode
				if takis_custombuild
					ML.interpolate(v, 100)
					ML.addButton(v, {
						id = 100,
						x = x,y = y,
						
						width = 20,
						height = 20,
						
						color = 159,
						outline = 159,
						
						name = "",
						pressFunc = function()
							filterstring = ""
							ML.startTextInput(buffer,bufferid, {
								onenter = function()
									local newstr = ML.client.textbuffer:upper()
									filterstring = newstr
								end,
								tooltip = {
									"Enter a MT_* name to filter."
								}
								--typesound = sfx_oldrad
							})
						end
					})
					-- inset
					do
						local width = 20
						v.drawFill(x,y,
							width,1, 156
						)
						v.drawFill(x,y + 19,
							width,1, 156
						)
						v.drawFill(x,y,
							1,20, 156
						)
						v.drawFill(x+width-1,y,
							1,20, 156
						)
					end
					ML.interpolate(v, false)
					x = $ + (21)
					width = $ - (21)
				end
				ML.addButton(v, {
					id = 4,
					x = x,y = y,
					
					width = width,
					height = 20,
					
					color = 159,
					outline = 159,
					
					name = "",
					pressFunc = function()
						buffer = ""
						ML.startTextInput(buffer,bufferid, {
							onenter = function()
								--ML.client.commandbuffer = "mm_stormradius "..ML.client.textbuffer
								local newstr = ML.client.textbuffer:upper()
								local isvalid = false
								if (newstr.sub(newstr,1,3) ~= "MT_")
									newstr = "MT_"..$
								end
								if (pcall(do return _G[newstr] end))
									isvalid = true
								end
								if isvalid
									buffer = newstr
									ML.client.commandbuffer = "phys_toolgun_type "..newstr
								else
									menu.notvalid = TR
								end
							end,
							tooltip = {
								"Enter a MT_* name.",
								"Your spawning type will be set to this."
							}
							--typesound = sfx_oldrad
						})
					end
				})
				-- inset
				do
					v.drawFill(x,y,
						width,1, 156
					)
					v.drawFill(x,y + 19,
						width,1, 156
					)
					v.drawFill(x,y,
						1,20, 156
					)
					v.drawFill(x+width-1,y,
						1,20, 156
					)
				end
				
				if filterstring ~= ""
					v.drawString(x + 3,y + (10 - 4),
						'Filtering for "'..filterstring..'"',
						V_ALLOWLOWERCASE|(not menu.notvalid and V_30TRANS or V_REDMAP),
						"thin"
					)
				else
					if buffer == ""
						v.drawString(x + 3,y + (10 - 4),
							menu.notvalid and "Not a valid type!" or "Type a MT_ name...",
							V_ALLOWLOWERCASE|(not menu.notvalid and V_30TRANS or V_REDMAP),
							"thin"
						)
					else
						v.drawString(x + 3,y + (10 - 4), buffer, 0, "thin")
					end
				end
			end
			if menu.notvalid ~= nil
				menu.notvalid = max($-1,0)
			end
		end
		
		if topbutton.active and old_ticker
			ML.interpolate(v, false)
			drawMobjCard(v, topbutton.x, topbutton.y, topbutton.id, false, true)
		elseif older_id == 0
		or (older_id ~= old_id)
			animtimer = 0
			animframe = 0
			animstate = false
		end
		
	end
})

addHook("KeyDown",function(key)
	if isdedicatedserver then return end
	if not (consoleplayer and consoleplayer.valid and consoleplayer.physgun) then return end
	if (chatactive) then return end
	if (key.repeated) then return end
	if ML.client.currentMenu.id ~= -1 then return end
	if not (consoleplayer == server or IsPlayerAdmin(consoleplayer)) then return end
	
	if (key.name == "]")
		MenuLib.initMenu(MenuLib.findMenu("Phys_TypeSelector"))
	elseif (key.name == "[")
		local newmode = consoleplayer.physgun.mode == "toolgun" and "physgun" or "toolgun"
		COM_BufInsertText(consoleplayer, "phys_mode "..newmode)
	elseif (key.name == "=")
		COM_BufInsertText(consoleplayer, "phys_toggle")
	end
end)
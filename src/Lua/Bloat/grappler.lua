local CV = SOAP_CV
COM_AddCommand("grappler",function(p, extra)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	if extra ~= nil
		p.grappler_extra = not $
		return
	end
	
	p.grappler = not $
	if (p.grappler)
		S_StartSound(p.realmo, sfx_z_strt)
	end
end)

freeslot("MT_GRAPPLERAY")
mobjinfo[MT_GRAPPLERAY] = {
	doomednum = -1,
	radius = 8*FU,
	height = 16*FU,
	spawnstate = S_PARTICLE,
	deathstate = S_PARTICLE,
	flags = MF_NOGRAVITY|MF_SOLID
}
local forcecollide = {
	[MT_NIGHTSBUMPER] = true,
	[MT_CYBRAKDEMON_ELECTRIC_BARRIER] = true,
}
local ringtypes = {
	[MT_RING] = true,
	[MT_FLINGRING] = true,
	[MT_COIN] = true,
	[MT_FLINGCOIN] = true,
	[MT_BLUESPHERE] = true,
	[MT_FLINGBLUESPHERE] = true,
}
local forcenocollide = {
	[MT_STARPOST] = true,
}
local forcereel = {
	[MT_NIGHTSBUMPER] = true
}

addHook("MobjMoveCollide",function(m, other)
	if not (other and other.valid and other.health) then return end
	if other == m.tracer
		return false
	end
	--print(other.info.typename, Soap_ZCollide(m,other))
	
	if other.grap_forcecollide == false
	or ringtypes[other.type] == true
	or forcenocollide[other.type] == true
		return false
	end
	
	if (
		(other.flags & (MF_BOSS|MF_ENEMY|MF_SOLID|MF_MONITOR|MF_SPECIAL|MF_SPRING))
		or forcecollide[other.type] == true
		or other.grap_forcecollide
	) and Soap_ZCollide(m,other)
		m.target = other
		P_KillMobj(m)
		return true
	end
end,MT_GRAPPLERAY)
addHook("MobjMoveBlocked",function(m, other)
	if (other and other.valid)
		m.target = other
	end
	P_KillMobj(m)
end,MT_GRAPPLERAY)

sfxinfo[freeslot("sfx_g_fire")].caption = "/"
sfxinfo[freeslot("sfx_g_hit")].caption = "/"

sfxinfo[freeslot("sfx_g_rea")].caption = "/"
sfxinfo[freeslot("sfx_g_reb")].caption = "/"
sfxinfo[freeslot("sfx_g_rel")].caption = "/"

local function SafeVecPos(v, mo, absolute)
	local destx = v.x
	local desty = v.y
	local destz = v.z
	if not absolute then
		destx = $ + mo.x
		desty = $ + mo.y
		destz = $ + mo.z
	end
	
	local oldmz = mo.momz
	mo.momz = destz - mo.z
	P_ZMovement(mo)
	mo.momz = oldmz
	
	if not P_TryMove(mo, destx, desty, true)
		return false
	end
	
	return true
end
local function RopeSolver(part, anc, ropeLength)
	if part.flags & MF_NOTHINK then return end
	
	local partPos = Vec3.MobjPosToVec(part)
	local ancPos = Vec3.MobjPosToVec(anc)
	
	local distFixed = R_PointTo3DDist(part.x,part.y,part.z + part.height/2, anc.x,anc.y,anc.z)
	
	local distVec = partPos - ancPos
	local unitVec = distVec / distFixed
	
	if distFixed > ropeLength
		local over = distFixed - ropeLength
		local pushVec = (unitVec * over)
		local wantVec = partPos - pushVec
		SafeVecPos(wantVec, part, true)
		
		local uDot = unitVec:Dot(Vec3.MobjMomToVec(part))
		if uDot > 0
			local momVec = unitVec * uDot
			momVec:Neg():ToMobjMom(part, false)
		end
	end
end

local TRACE_LEN = 90
local TRACE_WOB = 2
local TRACE_ENDWOB = 5
local function TraceRope(p,me,cmd,g,m, rpos)
	local mx = me.momx
	local my = me.momy
	local mz = me.momz
	if rpos ~= nil
		mx = $ + (rpos.x - me.x)
		my = $ + (rpos.y - me.y)
		mz = $ + (rpos.z - me.z)
	end
	
	local angle, mang = R_PointTo3DAngles(me.x+mx,me.y+my,me.z+mz+me.height/2, m.x,m.y,m.z)
	mang = InvAngle($)
	local step = R_PointTo3DDist(me.x+mx,me.y+my,me.z+mz+me.height/2, m.x,m.y,m.z)
	step = FixedMul($, FixedDiv(g.ropefx, m.xyzdist))
	step = $ / TRACE_LEN
	
	local wobblestrength = 70*FU
	if (g.reeling)
		wobblestrength = FixedMul($, FixedDiv(g.reel.progress, g.reel.distcover))
	end
	
	local vec = SphereToCartesian(angle, InvAngle(mang))
	local dist = step
	local ropecolor = (p.grappler_extra) and ColorOpposite(me.color) or me.color
	for i = 1, TRACE_LEN
		local wx,wy = 0,0
		if i > TRACE_WOB
		and (g.wigglefx)
			local wobblefrac = FixedDiv((i - TRACE_WOB)*FU, (TRACE_LEN-TRACE_WOB)*FU)
			if (i >= TRACE_LEN - TRACE_ENDWOB)
			and g.reeling
				local d = i - (TRACE_LEN - TRACE_ENDWOB)
				wobblefrac = FixedMul($, FU - FixedDiv(d*FU, TRACE_ENDWOB*FU))
			end
			
			local ang = angle + ANGLE_90
			local force = FixedMul(wobblestrength, sin(FixedAngle((leveltime*3*((g.ropefx>=m.xyzdist and not g.reeling) and 2 or 1) + (i-TRACE_WOB)/3)*FU*20)))
			force = FixedMul($, wobblefrac)
			force = FixedMul($, g.wigglefx)
			wx = FixedMul(force, cos(ang))
			wy = FixedMul(force, sin(ang))
		end
		
		local dot = g.ropeparts[i]
		local pos = {
			x = me.x+mx + FixedMul(dist, vec.x) + wx,
			y = me.y+my + FixedMul(dist, vec.y) + wy,
			z = me.z+mz+me.height/2 + FixedMul(dist, vec.z)
		}
		if not (dot and dot.valid)
			dot = P_SpawnMobj(pos.x, pos.y, pos.z, MT_PARTICLE)
			dot.state = S_THOK
			dot.tics = -1
			dot.fuse = -1
			dot.frame = $ &~FF_TRANSMASK
			dot.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
			dot.scale = FU/14 + FixedMul(FU/4, FixedDiv(i*FU, TRACE_LEN*FU))
			g.ropeparts[i] = dot
		else
			P_MoveOrigin(dot, pos.x,pos.y,pos.z)
		end
		dot.color = ropecolor
		--dot.blendmode = AST_ADD
		--dot.dontdrawforviewmobj = me
		dist = $ + step
	end
	
	
	local dot = g.destfx
	local pos = {
		x = me.x+mx + FixedMul(dist, vec.x),
		y = me.y+my + FixedMul(dist, vec.y),
		z = me.z+mz+me.height/2 + FixedMul(dist, vec.z)
	}
	if not (dot and dot.valid)
		dot = P_SpawnMobj(pos.x, pos.y, pos.z, MT_PARTICLE)
		dot.state = S_THOK
		dot.tics = -1
		dot.fuse = -1
		dot.frame = $ &~FF_TRANSMASK
		dot.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
		dot.scale = FU / 2
		g.destfx = dot
	else
		P_MoveOrigin(dot, pos.x,pos.y,pos.z)
	end
	dot.color = ColorOpposite(ropecolor)
end
local function DestroyRope(p,me,cmd,g)
	for i = 1, TRACE_LEN
		if (g.ropeparts[i] and g.ropeparts[i].valid)
			P_RemoveMobj(g.ropeparts[i])
			g.ropeparts[i] = nil
		end
	end
	if g.destfx and g.destfx.valid
		P_RemoveMobj(g.destfx)
		g.destfx = nil
	end
end

local function FollowGrapMobj(p,me,cmd,g,m, allowuntether)
	if (m.mo and m.mo.valid and m.mo.health)
		m.x = m.mo.x + P_ReturnThrustX(m.mo.angle + m.dispang, m.dispoff)
		m.y = m.mo.y + P_ReturnThrustY(m.mo.angle + m.dispang, m.dispoff)
		m.z = m.mo.z + m.dispz
	elseif m.dispang ~= nil and allowuntether
		S_StartSound(me, sfx_g_rea)
		
		me.state = S_PLAY_FALL
		
		p.pflags = $|PF_JUMPED|PF_THOKKED
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		return
	end
end

local function RopePart(p,me,cmd,g)
	local m = g.grappoint
	
	if ((P_IsObjectOnGround(me) and not p.grappler_extra) or P_PlayerInPain(p) or p.powers[pw_carry] ~= CR_NONE)
	or (me.eflags & MFE_SPRUNG)
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		P_MovePlayer(p)
		S_StartSound(me, sfx_g_rea)
		return
	end
	
	FollowGrapMobj(p,me,cmd,g,m, true)
	
	local angle, mang = R_PointTo3DAngles(me.x,me.y,me.z, m.x,m.y,m.z)
	mang = InvAngle($)
	
	if not (me.flags & (MF_NOGRAVITY|MF_NOTHINK))
	and not me.hitlag
		me.momz = $ + P_GetMobjGravity(me)*12/10
	end
	p.soaptable.noairdrag = max($, TR/2)
	
	do
		local ford = cmd.forwardmove
		local side = cmd.sidemove
		local wishangle = cmd.angleturn<<16 + R_PointToAngle2(0, 0, ford << 16, -side << 16)
		local wishspeed = 350*me.scale
		local acceleration = FU/4220 + (FixedDiv(FixedHypot(FixedHypot(me.momx,me.momy), me.momz), wishspeed)/120)
		
		local addspeed = wishspeed - FixedHypot(FixedHypot(me.momx,me.momy), me.momz)
		if (addspeed > 0)
			local accelspeed = FixedMul(acceleration, wishspeed)
			if accelspeed > addspeed then accelspeed = addspeed; end
			
			local momvec = Vec2.MobjMomToVec(me)
			wishangle = Vec2.SphereToCartesian($, 0)
			local x = momvec.x + FixedMul(accelspeed, wishangle.x)
			local y = momvec.y + FixedMul(accelspeed, wishangle.y)
			me.momx = x
			me.momy = y
		end
	end
	RopeSolver(me, m, m.xyzdist)
	TraceRope(p,me,cmd,g,m)
	
	p.pflags = $|PF_THOKKED
	if (g.jump == 1) and not (P_IsObjectOnGround(me) or p.soaptable.last.onground)
		S_StartSound(me, sfx_g_reb)
		P_SetObjectMomZ(me, 6*FU, true)
		
		me.state = S_PLAY_JUMP
		me.momx = $ * 108/100
		me.momy = $ * 108/100
		if me.momz*P_MobjFlip(me) > 0
			me.momz = $ * 6/5
		end
		
		p.pflags = $|PF_JUMPED|PF_THOKKED
		g.jumpdown = true
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		return
	end
	if (g.firenormal == 1)
		g.reeling = true
		g.reel.progress = 0
		g.reel.speed = max(30*me.scale, R_PointTo3DDist(0,0,0, me.momx, me.momy, me.momz))
		g.reel.startpos = {x = me.x+me.momx, y = me.y+me.momy, z = me.z+me.momz}
		g.reel.distcover = R_PointTo3DDist(me.x,me.y,me.z, m.x,m.y,m.z)
		S_StartSound(me, sfx_g_rel)
		return
	end
	if (g.fire == 1)
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		g.firelockout = true
		me.state = S_PLAY_FALL
		S_StartSound(me, sfx_g_rea)
		return
	end
end

local function ReelPart(p,me,cmd,g)
	local r = g.reel
	local m = g.grappoint
	local reelspeed = r.speed  --FixedMul(r.speed, me.scale)
	
	FollowGrapMobj(p,me,cmd,g,m, false)
	local prevprogress = FixedDiv(r.progress, r.distcover)
	r.progress = $ + reelspeed
	local progress = FixedDiv(r.progress, r.distcover)
	prevprogress = clamp(0, $, FU)
	progress = clamp(0, $, FU)
	
	me.momx,me.momy,me.momz = 0,0,0
	r.prevpos = {
		x = P_Lerp(prevprogress, r.startpos.x, m.x),
		y = P_Lerp(prevprogress, r.startpos.y, m.y),
		z = P_Lerp(prevprogress, r.startpos.z, m.z)
	}
	local pos = Vec3.New(
		P_Lerp(progress, r.startpos.x, m.x),
		P_Lerp(progress, r.startpos.y, m.y),
		P_Lerp(progress, r.startpos.z, m.z)
	)
	
	if (g.firenormal == 1)
	or (g.jump == 1)
	and (r.prevpos)
		S_StopSoundByID(me, sfx_g_rel)
		S_StartSound(me, sfx_g_reb)
		
		me.state = S_PLAY_JUMP
		me.momx = pos.x - r.prevpos.x
		me.momy = pos.y - r.prevpos.y
		me.momz = pos.z - r.prevpos.z
		P_SetObjectMomZ(me, 8*FU, true)
		
		p.pflags = $|PF_JUMPED|PF_THOKKED
		g.jumpdown = true
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		g.reeling = false
		return	
	end
	
	g.wigglefx = min($ + FixedDiv(reelspeed,80*me.scale)/8, FU)
	TraceRope(p,me,cmd,g,m, pos)
	local movegood = SafeVecPos(pos, me, true)
	
	if P_IsObjectOnGround(me)
	or (R_PointTo3DDist(me.x,me.y,me.z, m.x,m.y,m.z) <= ((me.radius+me.height)/2)*3/2 + 3*me.scale)
	or not movegood
		g.reeling = false
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		
		me.state = S_PLAY_FALL
		p.pflags = $|PF_THOKKED
		me.momx = pos.x - r.prevpos.x
		me.momy = pos.y - r.prevpos.y
		me.momz = pos.z - r.prevpos.z
		
		S_StopSoundByID(me, sfx_g_rel)
		S_StartSound(sfx, sfx_g_rea)
		
		return
	end
	
	searchBlockmap("objects",function(r, found)
		if not (found and found.valid and found.health) then return end
		if not ringtypes[found.type] then return end
		if R_PointTo3DDist(me.x,me.y,me.z, found.x,found.y,found.z) >= 128*me.scale then return end
		P_TouchSpecialThing(found, me)
	end, me)
	r.speed = $ + me.scale/12
end

local MAX_ROPE_DIST = 2150*FU
local ANTILAG = 10
local function TryRayPrefire(p,me,cmd,g)
	local speed = 16
	local maxdist = FixedMul(MAX_ROPE_DIST, me.scale)
	local ropecolor = (p.grappler_extra) and ColorOpposite(me.color) or me.color

	local ang = cmd.angleturn << 16
	local aim = cmd.aiming << 16
	local vec = SphereToCartesian(ang,aim)
	
	local ray = P_SpawnMobjFromMobj(me,
		0,0,
		41*FixedDiv(me.height,me.scale)/48 - 8*FU,
		MT_GRAPPLERAY
	)
	ray.angle = ang
	ray.tracer = me
	P_SetOrigin(ray,
		me.x + P_ReturnThrustX(ang,4*FU),
		me.y + P_ReturnThrustY(ang,4*FU),
		ray.z
	)
	
	ray.momx = speed * vec.x
	ray.momy = speed * vec.y
	ray.momz = speed * vec.z
	
	for i = 0,255
		if not (ray and ray.valid) then break; end
		
		if R_PointTo3DDist(me.x,me.y,me.z, ray.x,ray.y,ray.z) >= maxdist
			P_RemoveMobj(ray)
			break
		end
		
		if P_RailThinker(ray)
		or (ray.z + ray.height + ray.momz >= ray.ceilingz or ray.z + ray.momz <= ray.floorz)
		or not (ray.health)
			local t = P_SpawnMobjFromMobj(ray, 0,0,0,MT_PARTICLE)
			t.sprite = SPR_THOK
			t.fuse = 2
			t.tics = -1
			t.color = ColorOpposite(ropecolor)
			t.renderflags = $|RF_ALWAYSONTOP|RF_FULLBRIGHT
			t.drawonlyforplayer = p
			local scaleadd = 0 --FixedDiv(R_PointToDist(t.x,t.y), 512*FU)
			t.spritexscale = (FU/2) + scaleadd
			t.spriteyscale = t.spritexscale
			-- vanilla ughhh
			P_SetOrigin(t, t.x,t.y,t.z)
			
			P_RemoveMobj(ray)
			break
		end
	end
	
	if (ray and ray.valid)
		P_RemoveMobj(ray)
	end
end

local function TryRayFire(p,me,cmd,g)
	local speed = 16
	local maxdist = FixedMul(MAX_ROPE_DIST, me.scale)
	
	local numhits = 0
	local hits = {}
	local curlag = ((p.jointime-p.cmd.latency) % ANTILAG) + 1
	local firsthit = 0
	for j = 1, ANTILAG
		local step = g.antilag[j]
		local ang = step.angleturn << 16
		local aim = step.aiming << 16
		local vec = SphereToCartesian(ang,aim)
		
		local ray = P_SpawnMobjFromMobj(me,
			0,0,
			41*FixedDiv(me.height,me.scale)/48 - 8*FU,
			MT_GRAPPLERAY
		)
		ray.angle = ang
		ray.tracer = me
		P_SetOrigin(ray,
			step.x + P_ReturnThrustX(ang,4*FU),
			step.y + P_ReturnThrustY(ang,4*FU),
			ray.z
		)
		
		ray.momx = speed * vec.x
		ray.momy = speed * vec.y
		ray.momz = speed * vec.z
		
		for i = 0,255
			if not (ray and ray.valid) then break; end
			if R_PointTo3DDist(me.x,me.y,me.z, ray.x,ray.y,ray.z) >= maxdist
				P_RemoveMobj(ray)
				break
			end
			
			if P_RailThinker(ray)
			or (ray.z + ray.height + ray.momz >= ray.ceilingz or ray.z + ray.momz <= ray.floorz)
			or not (ray.health)
				numhits = $ + 1
				hits[numhits] = {
					x = ray.x,
					y = ray.y,
					z = ray.z,
					a = ray.angle,
					dist = R_PointTo3DDist(me.x,me.y,me.z+me.height/2, ray.x,ray.y,ray.z),
					grapmobj = ray.target
				}
				if j == curlag
					firsthit = numhits
				end
				P_RemoveMobj(ray)
				break
			end
		end
		
		if (ray and ray.valid)
			P_RemoveMobj(ray)
		end
	end
	
	if numhits
		local h
		if firsthit > 0
			h = hits[firsthit]
		else
			table.sort(hits,function(a,b)
				if a.grapmobj and (b and not b.grapmobj)
					return true
				end
				return a.dist < b.dist
			end)
			h = hits[1]
		end
		
		g.grappoint = {
			x = h.x,
			y = h.y,
			z = h.z,
			a = h.a,
			mo = h.grapmobj,
			xydist = R_PointToDist2(me.x,me.y, h.x,h.y),
			xyzdist = R_PointTo3DDist(me.x,me.y,me.z+me.height/2, h.x,h.y,h.z)
		}
		g.ropefx = 0
		g.wigglefx = FU
		
		local grapmobj = h.grapmobj
		if (grapmobj and grapmobj.valid)
			local m = g.grappoint
			if (grapmobj.flags & MF_SPRING)
			or forcereel[grapmobj.type]
			or (grapmobj.grap_forcereel)
				g.reeling = true
				g.reel.progress = 0
				g.reel.speed = max(30*me.scale, R_PointTo3DDist(0,0,0, me.momx, me.momy, me.momz))
				g.reel.startpos = {x = me.x+me.momx, y = me.y+me.momy, z = me.z+me.momz}
				g.reel.distcover = R_PointTo3DDist(me.x,me.y,me.z, m.x,m.y,m.z)
				S_StartSound(me, sfx_g_rel)
			end
			m.dispang = R_PointToAngle2(grapmobj.x,grapmobj.y, m.x,m.y) - grapmobj.angle
			m.dispoff = R_PointToDist2(grapmobj.x,grapmobj.y, m.x,m.y)
			m.dispz = m.z - grapmobj.z
		end
		
		S_StartSound(me, sfx_g_fire)
	end
end

addHook("PlayerThink",function(p)
	local me = p.realmo
	
	if not p.nsg
		p.nsg = {
			fire = 0,
			firelockout = false,
			firenormal = 0,
			jump = 0,
			antilag = {},
			grappoint = nil,
			reeling = false,
			reel = {
				speed = 0,
				progress = 0,
				startpos = nil,
				prevpos = nil,
				distcover = 0,
			},
			ropefx = 0,
			destfx = nil,
			wigglefx = 0,
			ropeparts = {},
		}
	end
	local cmd = p.cmd
	local g = p.nsg
	
	if not (me and me.valid and me.health and p.grappler)
		g.grappoint = nil
		DestroyRope(p,me,cmd,g)
		return
	end
	
	local oldfire = g.fire
	if (cmd.buttons & BT_ATTACK)
		if not g.firelockout
			g.fire = $ + 1
		else
			g.fire = 0
			oldfire = 0
		end
	else
		g.firelockout = false
		g.fire = 0
	end
	if (cmd.buttons & BT_FIRENORMAL)
		g.firenormal = $ + 1
	else
		g.firenormal = 0
	end
	if (cmd.buttons & BT_JUMP)
		g.jump = $ + 1
	else
		g.jump = 0
	end
	
	g.antilag[(p.jointime % ANTILAG) + 1] = {
		angleturn = p.cmd.angleturn,
		aiming = p.cmd.aiming,
		x = me.x,
		y = me.y,
		z = me.z,
		momx = me.momx,
		momy = me.momy,
		momz = me.momz,
	}
	
	if g.fire
	and not (g.grappoint or g.reeling)
		TryRayPrefire(p,me,cmd,g)
		if not P_IsObjectOnGround(me)
			p.drawangle = cmd.angleturn << 16
		end
	end
	
	local dontfire = false
	if (not p.grappler_extra)
		dontfire = P_IsObjectOnGround(me)
	end
	if oldfire and g.fire == 0
	and not dontfire
	and not (g.grappoint or g.reeling)
		TryRayFire(p,me,cmd,g)
	end
	
	if g.grappoint
		local m = g.grappoint
		
		if g.ropefx < m.xyzdist
			g.ropefx = $ + 150*FU
			if g.ropefx >= m.xyzdist
				g.ropefx = m.xyzdist
				S_StopSoundByID(me, sfx_g_fire)
				
				local sfx = P_SpawnMobj(m.x,m.y,m.z, MT_RAY)
				sfx.fuse = TR
				sfx.tics = sfx.fuse
				S_StartSound(sfx, sfx_g_hit)
				S_StartSound(me, sfx_g_hit)
				
				local angle = m.a
				local frontpush = -15*FU
				local ropecolor = (p.grappler_extra) and ColorOpposite(me.color) or me.color
				for i = 0,10
					local vertang = FixedAngle(Soap_RandomFixedRange(-70*FU,70*FU))
					local sidepush = Soap_RandomFixedRange(-frontpush/3, frontpush/3)
					local toppush = 6*FU + Soap_RandomFixedRange(-frontpush / 3, frontpush / 3)
					local s = P_SpawnMobj(
						m.x + P_ReturnThrustX(nil, angle, frontpush) + P_ReturnThrustX(nil, angle+ANGLE_90, sidepush),
						m.y + P_ReturnThrustY(nil, angle, frontpush) + P_ReturnThrustY(nil, angle+ANGLE_90, sidepush),
						m.z + toppush + FixedMul(sin(vertang), toppush), MT_PARTICLE
					)
					s.scale = FixedMul($ / 2, FU + Soap_RandomFixedRange(-FU/3,FU/3))
					s.state = S_SOAP_IMPACT_LINE2F
					local h,v = R_PointTo3DAngles(
						s.x,s.y,s.z,
						m.x+P_ReturnThrustX(nil, angle, frontpush*3/2),m.y+P_ReturnThrustY(nil, angle, frontpush*3/2),m.z + 6*FU
					)
					s.angle = h + ANGLE_180
					s.rollangle = v + InvAngle(vertang)
					s.color = ColorOpposite(ropecolor)
					local offset = P_RandomRange(2, 10)
					s.anim_duration = $ + offset
					s.tics = $ + offset
					s.scale = $ * 2
					s.drawonlyforplayer = p
					s.renderflags = $|RF_ALWAYSONTOP
					
					if not CV.rotations.value
						s.flags2 = $|MF2_DONTDRAW
					end
				end
			end
		elseif not g.reeling
			g.wigglefx = $ * 4/5
		end
		
		me.eflags = $|MFE_NOPITCHROLLEASING
		local frac = FU/2
		local angle, mang = R_PointTo3DAngles(me.x,me.y,me.z, m.x,m.y,m.z)
		if not (P_IsObjectOnGround(me) or P_PlayerInPain(p))
			p.drawangle = angle + ANGLE_90
		end
		mang = InvAngle($) + ANGLE_90
		
		local destpitch = FixedMul(mang, cos(angle))
		local destroll = FixedMul(mang, sin(angle))
		if not (P_IsObjectOnGround(me) or P_PlayerInPain(p))
			me.pitch = P_Lerp(frac, $, destpitch)
			me.roll  = P_Lerp(frac, $, destroll)
			me.state = S_PLAY_GLIDE
		end
		
		if not g.reeling
			RopePart(p,me,cmd,g)
		else
			ReelPart(p,me,cmd,g)
		end
	else
		g.reeling = false
		g.ropefx = 0
	end
end)
-- lets HANG people!
local function StartHanging(p)
	local me = p.mo
	
	local anchor = P_SpawnMobjFromMobj(me, 0,0, 200*FU, MT_THOK)
	anchor.fuse = 15*TR
	anchor.tics = anchor.fuse
	anchor.flags2 = $|MF2_DONTDRAW
	
	me.hanging = {
		active = true,
		tics = 12*TR,
		anchor = anchor,
		
		wigglefx = 2*FU,
		ropeparts = {},
		capped = false,
	}
	P_PlayJingleMusic(p, "_LOL", 0, false, JT_DROWN)
end

local TRACE_LEN = 90
local TRACE_WOB = 2
local TRACE_ENDWOB = 5
local function TraceRope(p,me,cmd,g,m, rpos)
	local mx = me.momx
	local my = me.momy
	local mz = me.momz
	local xyzdist = R_PointTo3DDist(me.x,me.y,me.z, m.x,m.y,m.z)
	if rpos ~= nil
		mx = $ + (rpos.x - me.x)
		my = $ + (rpos.y - me.y)
		mz = $ + (rpos.z - me.z)
	end
	
	local angle, mang = R_PointTo3DAngles(me.x+mx,me.y+my,me.z+mz+me.height/2, m.x,m.y,m.z)
	mang = InvAngle($)
	local step = R_PointTo3DDist(me.x+mx,me.y+my,me.z+mz+me.height/2, m.x,m.y,m.z)
	step = $ / TRACE_LEN
	
	local wobblestrength = 70*FU
	
	local vec = SphereToCartesian(angle, InvAngle(mang))
	local dist = step
	local ropecolor = (p.grappler_extra) and ColorOpposite(me.color) or me.color
	for i = 1, TRACE_LEN
		local wx,wy = 0,0
		if i > TRACE_WOB
		and (g.wigglefx)
			local wobblefrac = FixedDiv((i - TRACE_WOB)*FU, (TRACE_LEN-TRACE_WOB)*FU)
			if (i >= TRACE_LEN - TRACE_ENDWOB)
				local d = i - (TRACE_LEN - TRACE_ENDWOB)
				wobblefrac = FixedMul($, FU - FixedDiv(d*FU, TRACE_ENDWOB*FU))
			end
			
			local ang = angle + ANGLE_90
			local force = FixedMul(wobblestrength, sin(FixedAngle((leveltime*3*(2) + (i-TRACE_WOB)/3)*FU*20)))
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
		local pushVec = (unitVec * (FU*56/100)) * over 
		local wantVec = partPos - pushVec
		SafeVecPos(wantVec, part, true)
		
		local uDot = unitVec:Dot(Vec3.MobjMomToVec(part))
		if uDot > 0
			local momVec = unitVec * uDot
			momVec:Neg():ToMobjMom(part, false)
		end
		
		if not part.hanging.capped
			part.hanging.wigglefx = max($, over / 8)
		end
	end
	part.hanging.capped = distFixed > ropeLength
end

addHook("PlayerThink",function(p)
	local me = p.mo
	if not (me and me.valid) then return end
	local h = me.hanging
	if not (h and h.active) then return end
	
	if not me.health
		me.hanging = nil
		P_RestoreMusic(p)
		return
	end
	
	p.cmd.forwardmove = $ / 8
	p.cmd.sidemove = $ / 8
	
	me.state = S_PLAY_DRWN
	RopeSolver(me, h.anchor, 150*FU)
	TraceRope(p,me,p.cmd, h, h.anchor)
	h.wigglefx = $ * 78/100
	
	h.tics = $ - 1
	if h.tics == 0
		P_FlashPal(p, PAL_INVERT, 12)
		me.bell_effect = 2*TR * 3/2
	end
end)

local function GetPlayerHelper(pname)
	-- Find a player using their node or part of their name.
	local N = tonumber(pname)
	if N ~= nil and N >= 0 and N < 32 then
		for player in players.iterate do
			if #player == N then
	return player
			end
		end
	end
	for player in players.iterate do
		if string.find(string.lower(player.name), string.lower(pname)) then
			return player
		end
	end
	return nil
end
local function GetPlayer(player, pname)
	local player2 = GetPlayerHelper(pname)
	if not player2 then
		CONS_Printf(player, "No one here has that name.")
	end
	return player2
end
COM_AddCommand("hang", function(p, node)
	local certified = Bloat_CheckAdmin(p)
	if not certified then return end
	
	if node == "@all"
		for p2 in players.iterate
			local mo = p2.realmo
			if not (mo and mo.valid and mo.health) then continue end
			
			StartHanging(p2)
		end
		return
	end
	
	local p2 = GetPlayer(p,node or "")
	if p2
	and (node ~= nil)
		local mo = p2.realmo
		if not (mo and mo.valid and mo.health)
			CONS_Printf(p,"This person's object isn't valid.")
			return
		end
		
		StartHanging(p2)
	else
		CONS_Printf(p,"hang <player/node> - You know what this does.")
	end
	
end)
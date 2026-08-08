local function TraceRay(lstart,lend)
	for i = 0,19
		local frac = FixedDiv(i*FU, 20*FU)
		local t = P_SpawnMobj(
			P_Lerp(frac, lstart.x, lend.x),
			P_Lerp(frac, lstart.y, lend.y),
			P_Lerp(frac, lstart.z, lend.z),
			MT_PARTICLE
		)
		t.sprite = SPR_THOK
		t.scale = $ / 6
		t.fuse = 2
		t.tics = t.fuse
		t.blendmode = AST_ADD
		t.flags = $|MF_NOBLOCKMAP
	end
end
local function TraceBox(verts)
	TraceRay(verts[1], verts[2])
	TraceRay(verts[2], verts[3])
	TraceRay(verts[3], verts[4])
	TraceRay(verts[4], verts[1])

	TraceRay(verts[5], verts[6])
	TraceRay(verts[6], verts[7])
	TraceRay(verts[7], verts[8])
	TraceRay(verts[8], verts[5])
	
	TraceRay(verts[1], verts[5])
	TraceRay(verts[2], verts[6])
	TraceRay(verts[3], verts[7])
	TraceRay(verts[4], verts[8])
end

local BoxInfo = {
	wid = 100*FU,
	len = 60*FU,
	hei = 70*FU,
}
SafeFreeslot("MT_BLOAT_VAN")
mobjinfo[MT_BLOAT_VAN] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	flags = MF_SOLID,
	
	radius = max(BoxInfo.wid, BoxInfo.len),
	height = BoxInfo.hei,
}
for i = 0,12
	sfxinfo[SafeFreeslot(("sfx_krte%.2d"):format(i))].caption = "/"
end

local vanhud = {
	pos = nil,
	side = nil,
}

local function VanSearch(v)
	local vanPos = Vec3.MobjPosToVec(v)
	local driverPos = vanPos + (Vec3.SphereToCartesian(v.angle,0) * FixedMul(BoxInfo.wid / 2, v.scale))
	driverPos = $ + (Vec3.SphereToCartesian(v.angle+ANGLE_90,0) * FixedMul(BoxInfo.len, v.scale))
	driverPos.z = $ + v.height/2
	local t1 = P_SpawnMobj(driverPos.x,driverPos.y,driverPos.z, MT_THOK)
	t1.fuse = -1
	t1.tics = 2
	
	local passengerPos = vanPos + (Vec3.SphereToCartesian(v.angle,0) * FixedMul(BoxInfo.wid / 2, v.scale))
	passengerPos = $ + (Vec3.SphereToCartesian(v.angle-ANGLE_90,0) * FixedMul(BoxInfo.len, v.scale))
	passengerPos.z = $ + v.height/2
	local t2 = P_SpawnMobj(passengerPos.x,passengerPos.y,passengerPos.z, MT_THOK)
	t2.fuse = -1
	t2.tics = 2
	
	for p in players.iterate
		if (p.spectator) then continue end
		local me = p.realmo
		if not (me and me.valid and me.health) then continue end
		if me.inkidnapvan then continue end
		if me.vanlockout and leveltime < me.vanlockout then continue end
		
		if not v.tracer
		and R_PointTo3DDist(me.x,me.y,me.z, driverPos.x,driverPos.y,driverPos.z) < 100*v.scale
			
			if p == displayplayer
				vanhud.pos = driverPos
				vanhud.side = 1
			end
			
			t1.color = SKINCOLOR_RED
			if p.soaptable.c3 == TR
				v.tracer = me
				break
			end
		end
		if not v.target
		and R_PointTo3DDist(me.x,me.y,me.z, passengerPos.x,passengerPos.y,passengerPos.z) < 100*v.scale
			
			if p == displayplayer
				vanhud.pos = passengerPos
				vanhud.side = -1
			end
			
			t2.color = SKINCOLOR_RED
			if p.soaptable.c3 == TR
				v.target = me
				break
			end
		end
	end
end

local function VanMovePlayer(v, me, side)
	local p = me.player
	p.pflags = PF_FULLSTASIS
	me.flags = $|MF_NOCLIPTHING|MF_NOGRAVITY
	me.inkidnapvan = true
	me.kidvan = v
	
	local vanPos = Vec3.MobjPosToVec(v) + Vec3.MobjMomToVec(v)
	local sidePos = vanPos + (Vec3.SphereToCartesian(v.angle,0) * FixedMul(BoxInfo.wid / 2, v.scale))
	sidePos = $ + (Vec3.SphereToCartesian(v.angle+ANGLE_90*side,0) * FixedMul(BoxInfo.len/4, v.scale))
	sidePos.z = $ + v.height/2
	sidePos:ToMobjPos(me, true)

	me.angle = v.angle
	p.drawangle = me.angle
	p.camerascale = FU * 3/2
	me.state = S_PLAY_STND
	
	if p.soaptable.c3 == TR - 1
		if side == 1 then v.tracer = nil end
		if side == -1 then v.target = nil end
		
		me.inkidnapvan = nil
		me.kidvan = nil
		me.vanlockout = leveltime + 5
		me.flags = $ &~(MF_NOCLIPTHING|MF_NOGRAVITY)
		p.camerascale = skins[p.skin].camerascale
		
		local sidePos = vanPos + (Vec3.SphereToCartesian(v.angle,0) * FixedMul(BoxInfo.wid / 2, v.scale))
		sidePos = $ + (Vec3.SphereToCartesian(v.angle+ANGLE_90*side,0) * FixedMul(BoxInfo.len * 2, v.scale))
		sidePos.z = $ + v.height/2
		sidePos:ToMobjPos(me, true)
	end
end

local function VanControls(v)
	if not (v.tracer and v.tracer.valid) then return end
	
	local me = v.tracer
	local p = me.player
	local soap = p.soaptable
	
	local ford,side = soap.forwardmove, soap.sidemove
	if (side ~= 0)
		local speed = FixedHypot(v.momx,v.momy)
		local frac = min(FixedDiv(speed, 25*v.scale), FU)
		frac = FixedMul($, FixedDiv(side*FU, 50*FU))
		if not P_IsObjectOnGround(v)
			frac = $ / 5
		end
		
		local angturn = 6 * frac
		v.angle = $ - FixedAngle(angturn)
	end
		
	if (ford ~= 0)
		local wishangle = (v.angle) + R_PointToAngle2(0, 0, ford << 16, 0)
		local wishspeed = FixedMul(80*FU,v.scale)
		local acceleration = FU/110 + (v.acceltime*8)
		if not P_IsObjectOnGround(v)
			acceleration = 0
		end
		if (v.eflags & MFE_UNDERWATER)
			acceleration = $ * 5/6
		end
		acceleration = min($, FU)
		
		local addspeed = wishspeed - FixedHypot(v.momx,v.momy)
		if (addspeed > 0)
			local accelspeed = FixedMul(acceleration, wishspeed)
			if accelspeed > addspeed then accelspeed = addspeed; end
			
			local momvec = Vec2.MobjMomToVec(v)
			wishangle = Vec2.SphereToCartesian($, 0)
			local x = momvec.x + FixedMul(accelspeed, wishangle.x)
			local y = momvec.y + FixedMul(accelspeed, wishangle.y)
			v.momx = x
			v.momy = y
		end
		
		v.acceltime = min($ + 1, 40*TR)
	else
		v.acceltime = ($ or 0) / 2
	end	

	if (leveltime % 8 == 0)
		local targetsound = 0
		--targetsound = ((FixedHypot(6*ford, 6*side) / 25) + ((FixedDiv(FixedHypot(t.momx,t.momy),t.scale)/FU/5))) / 2
		targetsound = FixedMul(12*FU, (clamp(0, FixedDiv(FixedHypot(ford*FU,side*FU),50*FU), FU)*3/5 + FixedDiv(FixedHypot(v.momx,v.momy), 50*v.scale))/2) / FU
		targetsound = clamp(0,$,12)
		
		v.enginesound = $ or 0
		if v.enginesound < targetsound
			v.enginesound = $ + 1
		elseif v.enginesound > targetsound
			v.enginesound = $ - 1
		end
		v.enginesound = clamp(0,$,12)
		
		local vol = 255 * 3/4
		S_StartSound(v, sfx_krte00 + v.enginesound, vol)
	end
end

addHook("MobjThinker",function(v)
	if not (v and v.valid) then return end
	
	VanSearch(v)
	VanControls(v)
	if (v.tracer)
		VanMovePlayer(v, v.tracer, 1)
	end
	if (v.target)
		VanMovePlayer(v, v.target, -1)
	end
	
	local width = FixedMul(BoxInfo.wid, v.scale)
	local length = FixedMul(BoxInfo.len, v.scale)
	local height = FixedMul(BoxInfo.hei, v.scale)
	
	local localX = {-width, width, width, -width,		-width, width, width, -width}
	local localY = {-length, -length, length, length,	-length, -length, length, length}
	local localZ = {0,0,0,0,							 height, height, height, height}
	
	local sine = sin(v.angle)
	local cosine = cos(v.angle)
	local corners = {}
	for i = 1,8
		corners[i] = {
			x = v.x+v.momx + (FixedMul(localX[i],cosine) - FixedMul(localY[i],sine)),
			y = v.y+v.momy + (FixedMul(localX[i],sine) + FixedMul(localY[i],cosine)),
			z = v.z+v.momz + localZ[i]
		}
	end
	TraceBox(corners)
	v.verts = corners
	
	local a = P_SpawnMobjFromMobj(v,
		0,0,
		BoxInfo.hei/2, MT_PARTICLE
	)
	a.tics = 2
	a.fuse = 2
	a.sprite = SPR_SOAP_GFX
	a.frame = 30|FF_PAPERSPRITE|FF_ADD
	a.angle = v.angle
	a.spritexscale = $ * 2
	
	if (v.tracer and v.tracer.valid)
		v.radius = FixedMul(v.info.radius, v.scale)
		v.extravalue1 = max($ - 1, 0) -- collision fudge
		v.flags = $ &~MF_NOCLIP
	end
end,MT_BLOAT_VAN)

-- the collidor function is from
-- mario mode++, genuinely no clue how it
-- works its just black magic to me
-- https://github.com/TeamSprings/SRB2-MarioModePP/blob/main/
local function dotumble(p)
	local me = p.mo
	me.soap_tumble = true
	me.soap_tumble_oldmomz = me.momz
end

local function TryRunOver(v,mo)
	if not (v.tracer and v.tracer.valid) then return end
	if not Soap_ZCollide(v,mo) then return end
	if mo.type == MT_PLAYER
		local play = mo.player
		
		Soap_DamageSfx(mo,FU,FU)
		Soap_ImpactVFX(mo, v, nil,2*FU)
		
		play.powers[pw_flashing] = 0
		P_ResetPlayer(play)
		--P_DoPlayerPain(play,f,f)
		mo.state = S_PLAY_PAIN
		play.drawangle = v.angle + ANGLE_180
		
		dotumble(play)
		P_Thrust(mo, v.angle, FixedMul(140*FU, v.scale))
		if P_IsObjectOnGround(mo)
			mo.z = $ + P_MobjFlip(mo)
		end
		P_SetObjectMomZ(mo, 46*FU, true)
		play.powers[pw_flashing] = flashingtics
		
		Soap_Hitlag.addHitlag(mo, 13, true)
		if Soap_IsLocalPlayer(play)
			Soap_StartQuake(60*FU, TR/2,
				nil,
				512*mo.scale
			)
		end
	end
	
	if Soap_CanDamageEnemy(nil, mo)
		Soap_DamageSfx(mo,FU,FU)
		Soap_ImpactVFX(mo, v, nil,2*FU)
		P_KillMobj(mo)
		Soap_Hitlag.addHitlag(mo, 13, true)
		Soap_StartQuake(60*FU, TR/2,
			mo,
			512*mo.scale
		)
	end
end

local function blockCollisonLong(v, mo)
	if mo == v.tracer then return false end
	if mo == v.target then return false end
	
	if not TBSlib.rectangleCollidor(mo, v, FixedMul(BoxInfo.wid,v.scale), FixedMul(BoxInfo.len,v.scale), v.angle) then return false end
	if not Soap_ZCollide(v,mo) then return end
	if mo.vancollision == leveltime then return end
	mo.vancollision = leveltime
	
	TryRunOver(v,mo)
end
addHook("MobjCollide", blockCollisonLong, MT_BLOAT_VAN)
addHook("MobjMoveCollide", TryRunOver, MT_BLOAT_VAN)

-- this game is upsetting
local function P_ClosestPointOnLine3D(p, lstart, lend)
	local t,d
	local V = Vec3.Sub(lend, lstart)
	local c = Vec3.Sub(p, lstart)
	
	-- d = R_PointToDist2(0, lend.z, R_PointToDist2(lend.x, lend.y, lstart.x, lstart.y), lstart.z)
	d = R_PointTo3DDist(lstart.x,lstart.y,lstart.z, lend.x,lend.y,lend.z)
	local n = Vec3.New(V.x, V.y, V.z) / d
	t = Vec3.Dot(n, c)
	
	if t <= 0
		return lstart
	elseif t >= d
		return lend
	end
	
	n = $ * t
	return Vec3.Add(lstart, n)
end

addHook("MobjLineCollide", function(v, line)
	if not (line and line.valid) then return end
	if not P_LineIsBlocking(v, line) then return end
	if v.extravalue1 > 6 then return false end
	
	local vanPos = Vec3.MobjPosToVec(v) + Vec3.MobjMomToVec(v)
	vanPos.z = 0
	local lineStart = Vec3.New(line.v1.x, line.v1.y, 0)
	local lineEnd = Vec3.New(line.v2.x, line.v2.y, 0)
	
	local int = P_ClosestPointOnLine3D(vanPos, lineStart, lineEnd)
	
	if not TBSlib.rectangleCollidor(int, v, FixedMul(BoxInfo.wid,v.scale), FixedMul(BoxInfo.len,v.scale), v.angle) then return false end
	
	local facingang = R_PointToAngle2(int.x,int.y, v.x,v.y)
	
	local pushVec = Vec3.SphereToCartesian(facingang, 0)
	pushVec = $ * (32*FU)
	
	--pushVec:ToMobjMom(v, false)
	v.radius = 8*FU
	v.extravalue1 = $ + 1
	pushVec = $ + Vec3.MobjPosToVec(v)
	P_TryMove(v, pushVec.x, pushVec.y, true)
end, MT_BLOAT_VAN)

addHook("HUD",function(v,p,c)
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if not me.inkidnapvan
		if not vanhud.pos then return end
		
		local w2s = K_GetScreenCoords(v,p,c, vanhud.pos, {anglecliponly = true})
		if not (w2s.onscreen) then return end
		
		local x = w2s.x
		local y = w2s.y - 10*FU
		
		v.drawString(x,y, vanhud.side == 1 and "Driver" or "Passenger", V_ALLOWLOWERCASE, "thin-fixed")
		v.drawString(x,y+10*FU, "[C3] - Enter", V_ALLOWLOWERCASE, "thin-fixed")
	else
		local van = me.kidvan
		local speed = FixedDiv(FixedHypot(van.momx,van.momy), van.scale)
		
		v.drawString(160,160, ("%.2f fracs/t"):format(speed), V_ALLOWLOWERCASE, "thin-center")
		v.drawString(160,170, "[C3] - Exit", V_ALLOWLOWERCASE|V_50TRANS, "thin-center")
	end
end,"game")
addHook("PreThinkFrame",do
	vanhud.pos = nil
	vanhud.side = nil
end)

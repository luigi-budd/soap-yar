local mbrelease = dofile("Vars/mbrelease.lua")

sfxinfo[freeslot("sfx_z_fire")].caption = "/"
sfxinfo[freeslot("sfx_z_hit")].caption = "/"
sfxinfo[freeslot("sfx_z_mve0")].caption = "/"
sfxinfo[freeslot("sfx_z_mve1")].caption = "/"
sfxinfo[freeslot("sfx_z_rech")].caption = "/"
sfxinfo[freeslot("sfx_z_strt")].caption = "/"

freeslot("MT_SPIDERMAN_RAY", "S_ZIPCAST")
states[S_ZIPCAST] = {
	sprite = SPR_THOK,
	frame = A|FF_SEMIBRIGHT,
	action = function(mo)
		local g = P_SpawnGhostMobj(mo)
		g.fuse = TR
		g.tics = g.fuse
		g.scale = $ / 2
	end,
	tics = 1,
	nextstate = S_ZIPCAST
}
mobjinfo[MT_SPIDERMAN_RAY] = {
	spawnstate = S_ZIPCAST,
	doomednum = -1,
	radius = 16*FU,
	height = 32*FU,
	flags = MF_NOGRAVITY
}

local function blockedfunc(bomb, line)
	local p = bomb.tracer_player
	local me = p.mo
	p.zipcast_start = {x = me.x + me.momx, y = me.y + me.momy, z = me.z + me.momz}
	p.zipcast_end = {x = bomb.x, y = bomb.y, z = bomb.z}
	local cast_tics = 5
	local dist = R_PointTo3DDist(
		me.x + me.momx, me.y + me.momy, me.z + me.momz,
		bomb.x, bomb.y, bomb.z
	) / FU
	cast_tics = $ + abs(dist / 128)
	
	p.zipcast_startup = 8
	p.zipcast_tics = cast_tics
	p.zipcast_starttic = p.zipcast_tics
	p.zipcast_line = line
	
	S_StopSoundByID(me, sfx_z_fire)
	S_StartSound(me, sfx_z_hit)
	
	P_RemoveMobj(bomb)
	return true
end

addHook("MobjThinker",function(bomb)
	if not (bomb.tracer_player and bomb.tracer_player.valid)
		P_RemoveMobj(bomb)
		return
	end
	
	if not bomb.extravalue2
		bomb.base_momx = bomb.momx
		bomb.base_momy = bomb.momy
		bomb.base_momz = bomb.momz
		bomb.radius = 16*FU
		bomb.height = 32*FU
		
		bomb.extravalue2 = 1
		if not aimline
			S_StartSound(bomb.target, sfx_z_fire)
			bomb.tracer_player.zipcast_line = nil
		end
	end
	bomb.momx = bomb.base_momx
	bomb.momy = bomb.base_momy
	bomb.momz = bomb.base_momz
	
	for i = 0,2
		P_TryMove(bomb, bomb.x + bomb.momx, bomb.y + bomb.momy, true)
		P_ZMovement(bomb)
		if bomb.z + bomb.momz + bomb.height >= bomb.ceilingz
		or bomb.z + bomb.momz <= bomb.floorz
			blockedfunc(bomb)
			return
		end
	end
end,MT_SPIDERMAN_RAY)

addHook("MobjMoveBlocked",function(bomb, _,line)
	blockedfunc(bomb,line)
end,MT_SPIDERMAN_RAY)

COM_AddCommand("spiderman",function(p)
	if not (p.soaptable and p.realmo and p.realmo.valid) then return end
	
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	p.zipcaster = not $
	if (p.zipcaster)
		S_StartSound(p.realmo, sfx_z_strt)
	end
end)

local cameralag = 0
local factor = FU/3
local function camlag()
	camera.momx = FixedMul($, factor)
	camera.momy = FixedMul($, factor)
	camera.momz = FixedMul($, factor)	
end
addHook("ThinkFrame",do
	if not cameralag then return end
	
	camlag()
	cameralag = $ - 1
end)
local zip_thinker = function(p,me)
	if not me.health
		p.zipcast_startup = nil
		p.zipcast_tics = nil
		p.zipcast_start = nil
		p.zipcast_end = nil
		p.zipcast_line = nil
		p.zipcaster = false
		return
	end
	
	local zipping = false
	if p.zipcast_startup
	or p.zipcast_tics
		p.powers[pw_nocontrol] = 3
		p.pflags = $|PF_FULLSTASIS
		p.cmd.buttons = 0
		zipping = true
	end
	
	if p.zipcast_startup
		p.zipcast_startup = $ - 1
		local st = p.zipcast_start
		
		me.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		me.momx, me.momy, me.momz = 0,0,0
		me.state = S_PLAY_SPRING
		P_MoveOrigin(me,
			st.x,st.y,st.z
		)
		
		if p.zipcast_startup == 0
			S_StartSound(me, sfx_z_mve0)
			S_StartSound(me, sfx_z_mve1)
		end
	elseif p.zipcast_tics
		p.zipcast_tics = $ - 1
		local progress = ease.inquad(FU - ((FU/p.zipcast_starttic) * p.zipcast_tics), 0, FU)
		local st = p.zipcast_start
		local ed = p.zipcast_end
		local ox = st.x + FixedMul(ed.x - st.x, progress)
		local oy = st.y + FixedMul(ed.y - st.y, progress)
		local oz = st.z + FixedMul(ed.z - st.z, progress)
		me.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		me.momx, me.momy, me.momz = 0,0,0
		me.state = S_PLAY_GLIDE
		if not P_IsValidSprite2(me, SPR2_GLID)
			me.state = S_PLAY_ROLL
		end
		
		p.zipcast_fov = 28 * progress
		P_MoveOrigin(me,
			ox,oy,oz
		)
		if (p == displayplayer)
			cameralag = 20
		end
		
		me.angle = R_PointToAngle2(st.x,st.y, ed.x,ed.y)
		p.drawangle = me.angle
	elseif (p.zipcast_starttic)
		me.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)
		p.zipcast_start = nil
		p.zipcast_end = nil
		p.zipcast_starttic = nil
		
		S_StopSoundByID(me, sfx_z_mve0)
		S_StopSoundByID(me, sfx_z_mve1)
		S_StartSound(me, sfx_z_rech)
		
		if not (p.zipcast_line and p.zipcast_line.valid)
			me.state = S_PLAY_ROLL
		end
		if P_IsObjectOnGround(me)
			me.state = S_PLAY_WALK
		end
		P_ResetPlayer(p)
		P_MovePlayer(p)
	end
	
	if not zipping
	and (p.zipcast_line and p.zipcast_line.valid)
		local line = p.zipcast_line
		me.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		me.state = S_PLAY_CLING
		me.momx, me.momy, me.momz = 0,0,0
		p.powers[pw_nocontrol] = 3
		p.pflags = $|PF_FULLSTASIS
		
		local line_ang = R_PointToAngle2(
			line.v1.x, line.v1.y, line.v2.x, line.v2.y
		) - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1)
		p.drawangle = line_ang
		
		local ox,oy = P_ClosestPointOnLine(me.x,me.y, line)
		ox = $ + P_ReturnThrustX(nil, p.drawangle, -(me.radius*2 + 2*me.scale))
		oy = $ + P_ReturnThrustY(nil, p.drawangle, -(me.radius*2 + 2*me.scale))
		P_MoveOrigin(me, ox,oy, me.z)
		
		if (p.cmd.buttons & (BT_JUMP|BT_SPIN))
			p.powers[pw_nocontrol] = 0
			p.pflags = $ &~PF_FULLSTASIS
			if (p.cmd.buttons & BT_JUMP)
				P_DoJump(p, true)
				p.pflags = $|PF_JUMPDOWN
			else
				me.state = S_PLAY_FALL
			end
			
			p.zipcast_line = nil
			me.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)
		end
	end
end

addHook("PlayerThink",function(p)
	if p.zipcaster == nil
		p.zipcaster = false
	end
	
	local me = p.realmo
	if not (me and me.valid) then return end
	
	p.zipcast_fov = $ or 0
	p.zipcast_aiming = $ or 0
	local fireangle = p.cmd.angleturn << 16
	
	if p.zipcaster
		me.eflags = $|MFE_FORCESUPER
		me.renderflags = $|RF_FULLBRIGHT
		if not p.waszip
			me.state = $
		end
		
		local destcolor = (p.skincolor) - abs( ((leveltime/3) % 9) - 4 )
		destcolor = clamp(SKINCOLOR_WHITE, $, #skincolors)
		me.color = destcolor
		
		me.alpha = FU
		if (p.cmd.buttons & BT_FIRENORMAL)
		and not (p.zipcast_mobj and p.zipcast_mobj.valid)
		and not (p.zipcast_startup or p.zipcast_tics)
			p.zipcast_aiming = $ + 1
			local easefrac = 0
			if (p.zipcast_aiming >= TR/2)
				easefrac = min((FU/(TR*3/2)) * (p.zipcast_aiming - TR/2), FU)
				p.zipcast_fov = ease.inoutquad(
					easefrac,
					0, -30*FU
				)
			end
			if (p == displayplayer)
				me.alpha = ease.inoutquad(
					easefrac,
					$, FU/2
				)
				local handoffset = {
					P_ReturnThrustX(nil, fireangle - ANGLE_90, me.radius + FixedMul(6*FU,me.scale)),
					P_ReturnThrustY(nil, fireangle - ANGLE_90, me.radius + FixedMul(6*FU,me.scale))
				}
				local test = P_SpawnMobjFromMobj(me,
					0,0,
					41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
					MT_RAY
				)
				P_SetOrigin(test,
					test.x + handoffset[1] + me.momx,
					test.y + handoffset[2] + me.momy,
					test.z + me.momz
				)
				local vec = SphereToCartesian(fireangle, p.aiming)
				test.momx = FixedMul(FixedMul(65*FU, me.scale), vec.x)
				test.momy = FixedMul(FixedMul(65*FU, me.scale), vec.y)
				test.momz = FixedMul(FixedMul(65*FU, me.scale), vec.z)
				test.momz = $ * P_MobjFlip(me)
				
				test.target = me
				test.tracer_player = p
				
				test.color = p.skincolor
				
				while true
					if not P_TryMove(test, test.x + test.momx, test.y + test.momy, true)
						break
					end
					if not P_ZMovement(test) then break end
					
					if test.z <= test.floorz then break end
					if test.z + test.momz + test.height >= test.ceilingz
						break
					end
					
					local dot = P_SpawnMobj(
						test.x,test.y,test.z,
						MT_PARTICLE
					)
					dot.state = S_THOK
					dot.tics = -1
					dot.fuse = 2
					dot.frame = $ &~FF_TRANSMASK
					dot.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
					dot.scale = FU/5
					dot.color = me.color
					dot.blendmode = AST_ADD
					P_SetOrigin(dot, dot.x,dot.y,dot.z)
				end
			end
			
			p.drawangle = fireangle
		elseif p.zipcast_aiming
			local handoffset = {
				P_ReturnThrustX(nil, fireangle - ANGLE_90, me.radius + FixedMul(6*FU,me.scale)),
				P_ReturnThrustY(nil, fireangle - ANGLE_90, me.radius + FixedMul(6*FU,me.scale))
			}
			local bomb = P_SpawnMobjFromMobj(me,
				0,0,
				41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
				MT_SPIDERMAN_RAY
			)
			P_SetOrigin(bomb,
				bomb.x + handoffset[1] + me.momx,
				bomb.y + handoffset[2] + me.momy,
				bomb.z + me.momz
			)
			local vec = SphereToCartesian(fireangle, p.aiming)
			bomb.momx = FixedMul(FixedMul(65*FU, me.scale), vec.x)
			bomb.momy = FixedMul(FixedMul(65*FU, me.scale), vec.y)
			bomb.momz = FixedMul(FixedMul(65*FU, me.scale), vec.z)
			bomb.momz = $ * P_MobjFlip(me)
			
			bomb.target = me
			bomb.tracer_player = p
			
			bomb.color = p.skincolor
			p.zipcast_mobj = bomb
			p.zipcast_aiming = 0
		end
		
		zip_thinker(p,me)
	elseif p.waszip
		me.eflags = $ &~MFE_FORCESUPER
		me.renderflags = $ &~RF_FULLBRIGHT
		me.state = $
		me.color = p.skincolor
	end
	
	p.waszip = p.zipcaster
	p.fovadd = $ + p.zipcast_fov
	p.zipcast_fov = $ * 6/7
end)
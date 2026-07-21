-- lol
local CV = SOAP_CV
sfxinfo[SafeFreeslot("sfx_husk")].caption = "/"
sfxinfo[SafeFreeslot("sfx_husk2")].caption = "/"
sfxinfo[SafeFreeslot("sfx_husk3")].caption = "/"
-- sfx_sp_hsk


local TIMELAG = TR * 3/4 --TR*6/5
local SPAWNTIME = (TR + (TR*7/10)) - TIMELAG
local ANIM = (TR * 42/100)
local function RemoveHusk(me)
	for i = 1, me.husk_number
		P_RemoveMobj(me.husk_mo[i])
	end
	me.husk_history = nil
	me.husk_mo = nil
	me.husk_number = nil
	me.husk_wait = nil
	me.husk_taller = nil
	me.spawnhusk = nil
	if me.husk_ind and me.husk_ind.valid
		P_RemoveMobj(me.husk_ind)
	end
end
addHook("PostThinkFrame",do for p in players.iterate
	local me = p.realmo
	if not (me and me.valid and me.health)
		if not (me and me.valid) then continue end
		if not me.husk_history then continue end
		RemoveHusk(me)
		continue
	end
	if not me.spawnhusk then continue end
	
	if me.husk_history == nil
		me.husk_history = {}
		me.husk_mo = {}
		--me.husk_number = 100
		me.husk_wait = 3*TR + TR/2
		--me.husk_taller = true
		for i = 1, me.husk_number
			local husk = P_SpawnMobjFromMobj(me,0,0,0,MT_UNKNOWN)
			husk.sprite = SPR_PLAY
			husk.skin = me.skin
			husk.sprite2 = SPR2_STND
			husk.flags2 = $|MF2_DONTDRAW
			husk.translation = "Husk"
			husk.drawonlyforplayer = p
			husk.soap_supervfx = true
			me.husk_mo[i] = husk
		end
		local husk = P_SpawnMobjFromMobj(me,0,0,0,MT_UNKNOWN)
		husk.sprite = SPR_PLAY
		husk.skin = me.skin
		husk.sprite2 = SPR2_LIFE
		husk.flags2 = $|MF2_DONTDRAW
		husk.translation = "Husk"
		husk.drawonlyforplayer = p
		husk.dontdrawforviewmobj = me
		husk.soap_supervfx = true
		husk.rollangle = ANG20
		me.husk_ind = husk
	end
	
	if (me.husk_wait <= SPAWNTIME)
	and (me.husk_ind and me.husk_ind.valid)
		local h = me.husk_ind
		local tele = P_MoveOrigin
		if (h.flags2 & MF2_DONTDRAW)
			h.flags2 = $ &~MF2_DONTDRAW
			tele = P_SetOrigin
		end
		tele(h, me.x,me.y,me.z + me.height + 6*me.scale)
		h.extravalue1 = $ + 1
		h.skin = me.skin
		if (h.extravalue1 % ANIM == 0)
			h.rollangle = -$
		end
	end
	
	if me.husk_wait
		if me.husk_wait == SPAWNTIME
			S_StartSound(nil, sfx_husk, p)
		end
		me.husk_wait = $ - 1
		continue
	end
	
	table.insert(me.husk_history, 0, {
		x = me.x,
		y = me.y,
		z = me.z,
		momx = me.momx,
		momy = me.momy,
		momz = me.momz,
		
		skin = me.skin,
		sprite = me.sprite,
		sprite2 = me.sprite2,
		frame = me.frame,
		angle = p.drawangle,
		
		color = me.color,
		colorized = me.colorized,
		
		pitch = me.pitch,
		roll = me.roll,
		rollangle = me.rollangle,
		shadowscale = me.shadowscale,
		radius = me.radius,
		height = me.height,
		
		scale = me.scale,
		spritexscale = me.spritexscale,
		spriteyscale = me.spriteyscale,
		renderflags = me.renderflags,
		blendmode = me.blendmode,
		hitlag = me.hitlag
	})
	
	local history_len = #me.husk_history
	local lastindex = (TIMELAG*me.husk_number) - 1
	local killed = false
	for i = 1, me.husk_number
		local mylag = (TIMELAG*i) - 1
		if history_len < (mylag) then continue end
		
		local step = me.husk_history[mylag]
		local h = me.husk_mo[i]
		local tele = P_MoveOrigin
		if (h.flags2 & MF2_DONTDRAW)
			h.flags2 = $ &~MF2_DONTDRAW
			tele = P_SetOrigin
		end
		tele(h,
			step.x,step.y,step.z
		)
		h.skin = step.skin
		h.color = step.color
		h.colorized = step.colorized
		h.angle = step.angle
		h.frame = A
		h.sprite = step.sprite
		h.sprite2 = step.sprite2
		h.frame = step.frame
		
		h.pitch = step.pitch
		h.roll = step.roll
		h.rollangle = step.rollangle
		h.shadowscale = step.shadowscale
		h.radius = step.radius * (me.husk_taller and 2 or 1)
		h.height = step.height * (me.husk_taller and 2 or 1)
		
		h.scale = step.scale * (me.husk_taller and 2 or 1)
		h.spritexscale = step.spritexscale
		h.spriteyscale = step.spriteyscale
		h.renderflags = step.renderflags|RF_SEMIBRIGHT
		h.blendmode = step.blendmode
		
		local sound = (me.husk_taller) and sfx_husk3 or sfx_sp_hsk
		if not S_SoundPlaying(h, sound)
		and not S_IdPlaying(sound)
			S_StartSound(h, sound, p)
		end
		
		if abs(h.x - me.x) <= me.radius + h.radius
		and abs(h.y - me.y) <= me.radius + h.radius
		and Soap_ZCollide(me,h)
		and not (me.hitlag or step.hitlag)
		and not (me.husk_shieldloss and (leveltime - me.husk_shieldloss >= flashingtics))
			if (p.powers[pw_shield])
				S_StartSound(me, sfx_nssb)
				Soap_ImpactVFX(me, nil, nil,nil,nil,nil, DMG_ELECTRIC)
				if (p.powers[pw_shield] & SH_FORCE)
					if (p.powers[pw_shield] & 255 == 0) -- no hp
						P_RemoveShield(p)
					else
						p.powers[pw_shield] = (($ & 255) - 1)|SH_FORCE
					end
				else
					P_RemoveShield(p)
				end
				p.powers[pw_flashing] = flashingtics - 1
				me.husk_shieldloss = leveltime
				
				continue
			end
			
			local sfx = P_SpawnGhostMobj(h)
			sfx.flags2 = $|MF2_DONTDRAW
			sfx.tics = 3*TR
			sfx.fuse = sfx.tics
			S_StartSound(sfx, sfx_husk2)
			S_StartSound(me, sfx_husk2)
			
			Soap_DamageSfx(me, FU*3/4,FU,nil,{vol = 255/2})
			Soap_ImpactVFX(me, h, nil, 3*FU)
			
			p.powers[pw_flashing] = 0
			P_ResetPlayer(p)
			me.state = S_PLAY_PAIN
			
			me.soap_tumble = true
			me.soap_tumble_oldmomz = me.momz
			me.soap_tumble_markedfordeath = CV.babykills.value
			
			local ang = R_PointToAngle2(me.x,me.y, h.x,h.y)
			me.state = S_PLAY_PAIN
			p.drawangle = ang + ANGLE_180
			
			if P_IsObjectOnGround(me)
				me.z = $ + P_MobjFlip(me)
			end
			P_InstaThrust(me, ang, 22*h.scale + FixedHypot(step.momx,step.momy) + FixedHypot(me.momx,me.momy))
			P_SetObjectMomZ(me, 22*h.scale)
			me.momz = $ + step.momz
			
			Soap_Hitlag.addHitlag(me, 12, true)
			
			killed = true
			break
		end
	end
	if killed
		RemoveHusk(me)
		continue
	end
	if history_len >= lastindex
		table.remove(me.husk_history, lastindex)
		if me.husk_ind
			P_RemoveMobj(me.husk_ind)
			me.husk_ind = nil
		end
	end
end end)

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

local function givehusk(p, number, taller)
	local me = p.realmo
	me.husk_taller = taller
	
	if me.spawnhusk
		local prevnum = me.husk_number
		me.husk_number = $ + number
		if me.husk_number ~= prevnum
			for i = 1, number
				local husk = P_SpawnMobjFromMobj(me,0,0,0,MT_UNKNOWN)
				husk.sprite = SPR_PLAY
				husk.skin = me.skin
				husk.sprite2 = SPR2_STND
				husk.flags2 = $|MF2_DONTDRAW
				husk.translation = "Husk"
				husk.drawonlyforplayer = p
				husk.soap_supervfx = true
				me.husk_mo[prevnum + i] = husk		
			end
			
			if not (me.husk_ind and me.husk_ind.valid)
				local husk = P_SpawnMobjFromMobj(me,0,0,0,MT_UNKNOWN)
				husk.sprite = SPR_PLAY
				husk.skin = me.skin
				husk.sprite2 = SPR2_LIFE
				husk.flags2 = $|MF2_DONTDRAW
				husk.translation = "Husk"
				husk.drawonlyforplayer = p
				husk.soap_supervfx = true
				husk.rollangle = ANG20
				me.husk_ind = husk
			end
		end
		return
	end
	number = max($, 1)
	me.spawnhusk = true
	me.husk_number = number
end
COM_AddCommand("givehusk", function(p, node, number, taller)
	local certified = false
	if ((p.name == "Epix" and not mbrelease) --lol
	or p.soaptable.isElevated)
		certified = true
	end
	if not certified then return end
	
	number = abs(tonumber($ or "0"))
	taller = ($ ~= nil)
	
	if node == "@all"
		for p2 in players.iterate
			local mo = p2.realmo
			if not (mo and mo.valid and mo.health) then continue end
			
			givehusk(p2, number, taller)
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
		
		givehusk(p2, number, taller)
	else
		CONS_Printf(p,"givehusk <player/node> <husks> [<taller>] - Gives a player a Husk.")
	end
end)
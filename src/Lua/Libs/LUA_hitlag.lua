rawset(_G,"Soap_Hitlag",{})
local hl = Soap_Hitlag

/*
	mobj->foolhardy: mobj will not be stunned
	mobj->nohitlagforme: mobj will not get hitlag
*/

hl.hitlagged = {}
hl.hitlagTranslation = "Soap_AI2"

--lets handle stunned enemies here too
hl.stunned = {}

hl.cv_hitlagtics = CV_RegisterVar({
	name = "soap_maxhitlagtics",
	--too early to use TR i guess
	defaultvalue = tostring(TICRATE),
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {MIN = 0, /*off*/ MAX = 9001}, --its over 9
})

--lol
hl.cv_hitlagmulti = CV_RegisterVar({
	name = "soap_hitlagmul",
	defaultvalue = "1.0",
	flags = CV_NETVAR|CV_FLOAT|CV_SHOWMODIF,
	PossibleValue = {MIN = FU, MAX = 20*FU},
})

hl.iterateHitlagged = function()
	for k,v in ipairs(hl.hitlagged)
		local mo = v[1]
		local lastflags = v[2]
		if not (mo and mo.valid)
			table.remove(hl.hitlagged,k)
			continue
		end
		
		if mo.hitlag
			--hitlag takes priority
			if mo.soap_stunned
				mo.soap_stunned = 0
				mo.flags = mo.hldata_st_lastflags ~= nil 
					and mo.hldata_st_lastflags or lastflags
			end
			mo.flags = $|MF_NOTHINK
			mo.hldata_hl_lastflags = lastflags
			
			if (mo.player and mo.player.valid)
				local p = mo.player
				p.pflags = $|v[4]|PF_FULLSTASIS|PF_JUMPSTASIS
				p.powers[pw_nocontrol] = 1
				if mo.damageinhitlag ~= true
					p.powers[pw_flashing] = max($,flashingtics)
				end
				
				--freeze in place
				if Soap_IsLocalPlayer(p)
					local cam = (p == displayplayer) and camera or camera2
					cam.momx,cam.momy,cam.momz = 0,0,0
				end
				
				--dont drain rings while in hitlag
				if (p.powers[pw_super] or p.soaptable.isSolForm)
				and ((leveltime % TICRATE == 0) and (not p.exiting))
					p.rings = $ + 1
				end
			end
			
			if mo.hitlag > hl.cv_hitlagtics.value
				mo.hitlag = hl.cv_hitlagtics.value
			end
			mo.hitlag = max($ - 1, 0)
		else
			mo.flags = $ &~MF_NOTHINK --mo.hldata_st_lastflags or lastflags
			mo.spritexoffset = 0
			mo.hitlagfromdmg = false
			mo.translation = mo.hldata_hl_lasttransl and mo.hldata_hl_lasttransl.tr or nil
			mo.hldata_hl_lastflags = nil
			mo.hldata_hl_lasttransl = nil
			mo.damageinhitlag = nil
			
			if (mo.player and mo.player.valid)
				local p = mo.player
				if (p.followmobj and p.followmobj.valid)
					p.followmobj.spritexoffset = 0
					p.followmobj.translation = nil
				end
				p.pflags = $ &~PF_STARTJUMP
				if not (mo.state == S_PLAY_PAIN)
					p.powers[pw_flashing] = 0
				end
			end
			table.remove(hl.hitlagged,k)
			continue
		end
	end

	for k,v in ipairs(hl.stunned)
		local mo = v[1]
		local lastflags = v[2]
		if not (mo and mo.valid)
			table.remove(hl.stunned,k)
			continue
		end
		
		if mo.soap_stunned
		and mo.health
		and not mo.hitlag
			mo.flags = $|MF_NOTHINK|MF_SLIDEME &~(MF_SPECIAL|MF_ENEMY|MF_FLOAT|MF_NOGRAVITY)
			mo.hldata_st_lastflags = lastflags
			
			if mo.health
			and not mo.hitlag
				local hasstunstate = mo.info.stunstate ~= nil
				local stunstate = hasstunstate and mo.info.stunstate or mo.info.spawnstate
				if hasstunstate
					mo.state = stunstate
				else
					P_SetMobjStateNF(mo,
						stunstate
					)
				end
				local spinout = clamp(8, mo.soap_stunned/8, 1) * ANGLE_11hh
				mo.angle = $ - spinout
			end
			
			if P_IsObjectOnGround(mo)
			and v.tics
				P_SetObjectMomZ(mo, P_RandomFixedRange(3,6))
				S_StartSound(mo,sfx_s3k49)
			end
			v.tics = $ + 1
			
			P_XYMovement(mo)
			if (mo and mo.valid)
				if not P_ZMovement(mo)
					table.remove(hl.stunned,k)
					continue
				end
			else
				table.remove(hl.stunned,k)
				continue
			end
			P_ButteredSlope(mo)
			
			if (v.tics % 16 == 0)
			--and not S_SoundPlaying(mo, sfx_kc38)
				S_StartSoundAtVolume(mo, sfx_kc38, 255)
			end
			
			if not mo.soap_setvfx
				local ang = FixedDiv(360*FU,3*FU)
				for i = 1,3
					local vfx = P_SpawnMobjFromMobj(mo,
						P_ReturnThrustX(nil,FixedAngle(ang*i), FixedDiv(mo.radius,mo.scale)),
						P_ReturnThrustY(nil,FixedAngle(ang*i), FixedDiv(mo.radius,mo.scale)),
						FixedDiv(mo.height,mo.scale) + 10*FU,
						MT_SOAP_STUNNED
					)
					vfx.tics = -1
					vfx.target = mo
					vfx.timealive = 0
					vfx.ang = ang
					vfx.movecount = i
					vfx.hitlag_t = v
				end
				mo.soap_setvfx = true
			end
			
			local hook_event = Takis_Hook.events["Soap_StunnedThink"]
			for i,v in ipairs(hook_event)
				local result = Takis_Hook.tryRunHook("Soap_StunnedThink", v, mo)
			end
			
			if hl.cv_hitlagtics.value
			and mo.soap_stunned > hl.cv_hitlagtics.value
				mo.soap_stunned = ease.incubic(
					(FU/hl.cv_hitlagtics.value) * (mo.soap_stunned - hl.cv_hitlagtics.value),
					$,hl.cv_hitlagtics.value
				)
			end
			mo.soap_stunned = max($ - 1, 0)
			
			if not (mo.soap_stunned)
				S_StopSoundByID(mo, sfx_kc38)
				
				local resetstate = mo.info.seestate
				if resetstate == S_NULL
					resetstate = mo.info.spawnstate
				end
				if mo.info.endstunstate ~= nil
					resetstate = mo.info.endstunstate
				end
				mo.state = resetstate
			end
		else
			if mo.health
			and not mo.hitlag
				local my_lf = mo.hldata_hl_lastflags or lastflags
				mo.flags = my_lf
				if (my_lf & (MF_NOGRAVITY|MF_FLOAT))
					mo.momz = 0
					
					/*
					local zdiff = 0
					if (P_MobjFlip(mo) == 1)
						zdiff = v[5] - v[6]
					else
						zdiff = v[8] - v[7] 
					end
					mo.z = $ + zdiff*P_MobjFlip(mo)
					*/
				end
				
				mo.hldata_st_lastflags = nil
			else
				mo.flags = $ &~MF_NOTHINK
			end
			mo.soap_setvfx = nil
			S_StopSoundByID(mo, sfx_kc38)
			table.remove(hl.stunned,k)
			continue
		end
	end
end

--visuals mostly
hl.iterateHitlaggedPostThink = function()
	for k,v in ipairs(hl.hitlagged)
		local mo = v[1]
		if not (mo and mo.valid) then table.remove(hl.hitlagged,k); continue end
		
		if mo.hitlag
			
			if mo.hitlagfromdmg
				local offset = (mo.hitlag)*2*FU*((leveltime & 1) and 1 or -1)
				if mo.skin and mo.sprite == SPR_PLAY
				and skins[mo.skin].flags & SF_HIRES
					offset = FixedDiv($, skins[mo.skin].highresscale)
				end
				if (mo.spritexscale ~= FU)
					offset = FixedDiv($, mo.spritexscale)
				end
				
				mo.spritexoffset = offset
				mo.translation = hl.hitlagTranslation
			end
			
			if (mo.player and mo.player.valid)
				local p = mo.player
				p.pflags = $|v[4]|PF_FULLSTASIS|PF_JUMPSTASIS
				if (p.followmobj and p.followmobj.valid)
					p.followmobj.spritexoffset = mo.spritexoffset
					p.followmobj.translation = mo.translation
				end
				
				p.drawangle = v[3]
			end
			
			P_SetMobjStateNF(mo, v[5])
			mo.frame = A
			mo.sprite = v[6]
			if (mo.skin and mo.sprite == SPR_PLAY)
				mo.sprite2 = v[8]
			end
			mo.frame = v[7]
			
			mo.flags2 = $ &~MF2_DONTDRAW
		end
	end
end

hl.addHitlag = function(
	mo,tics,
	fromdamage,
	allowdamage --Players only
)
	if mo == nil then return end
	if mo.hitlag == nil then mo.hitlag = 0 end
	if mo.nohitlagforme then return end
	
	--hitlag off
	if hl.cv_hitlagtics.value == 0
		mo.hitlag = 0
		return
	end
	
	if hl.cv_hitlagmulti.value ~= FU
		tics = FixedMul($, hl.cv_hitlagmulti.value)
	end
	
	mo.hitlag = $+tics
	if mo.hitlag > hl.cv_hitlagtics.value
		mo.hitlag = hl.cv_hitlagtics.value
	end
	
	if not mo.hldata_hl_lasttransl
		mo.hldata_hl_lasttransl = {
			tr = mo.translation
		}
	end
	mo.hitlagfromdmg = (fromdamage == true)
	if fromdamage == true
		mo.translation = hl.hitlagTranslation
	end
	
	if (mo.soap_stunned)
		mo.soap_stunned = 0
	end
	
	if (mo.player and mo.player.valid)
		if not allowdamage
			mo.player.powers[pw_flashing] = max($,flashingtics)
		else
			mo.damageinhitlag = true
		end
	end
	
	for k,v in ipairs(hl.hitlagged)
		if v[1] == mo
			return
		end
	end
	table.insert(hl.hitlagged, {
		mo,
		mo.flags,
		(mo.player and mo.player.valid) and mo.player.drawangle,
		(mo.player and mo.player.valid) and mo.player.pflags,
		mo.state, mo.sprite, mo.frame, mo.sprite2
	})
end

hl.stunEnemy = function(mo,tics)
	if mo == nil then return end
	if mo.nohitlagforme or mo.foolhardy then return end
	if mo.soap_stunned == nil then mo.soap_stunned = 0 end
	--save us the trouble
	if (mo.flags & MF_BOSS) and (mo.info.stunstate == nil) then return end
	
	--hitlag off
	if hl.cv_hitlagtics.value == 0
		mo.soap_stunned = 0
		return
	end
	
	if hl.cv_hitlagmulti.value ~= FU
		tics = FixedMul($, hl.cv_hitlagmulti.value)
	end
	
	mo.soap_stunned = $+tics
	/*
	if mo.soap_stunned > hl.cv_hitlagtics.value
		mo.soap_stunned = hl.cv_hitlagtics.value
	end
	*/
	
	local hook_event = Takis_Hook.events["Soap_OnStunEnemy"]
	for i,v in ipairs(hook_event)
		local result = Takis_Hook.tryRunHook("Soap_OnStunEnemy", v, mo,tics)
	end
	
	for k,v in ipairs(hl.stunned)
		if v[1] == mo
			return
		end
	end
	table.insert(hl.stunned, {
		mo,
		mo.flags,
		(mo.player and mo.player.valid) and mo.player.drawangle,
		(mo.player and mo.player.valid) and mo.player.pflags,
		mo.z, mo.floorz,
		mo.z + mo.height, mo.ceilingz,
		
		tics = 0,
	})
	S_StartSound(mo,sfx_kc38)
end

addHook("PreThinkFrame",hl.iterateHitlagged)
addHook("PostThinkFrame",hl.iterateHitlaggedPostThink)

addHook("ShouldDamage",function(me,_,_,_,dmg)
	if me.hitlag
		if me.damageinhitlag ~= true
		and not (dmg & DMG_DEATHMASK)
			return false
		else
			me.hitlag = 0
			return true
		end
	end
end,MT_PLAYER)

--i think this is the only thing we need to synch?
addHook("NetVars",function(n)
	hl.hitlagged = n($)
	hl.stunned = n($)
	hl.hitlagTranslation = n($)
end)
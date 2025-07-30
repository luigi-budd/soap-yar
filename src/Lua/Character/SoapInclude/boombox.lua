SafeFreeslot("sfx_sp_jam")
sfxinfo[sfx_sp_jam].caption = "\x89".."Boombox Jam\x80"
SafeFreeslot("sfx_sp_epi")
sfxinfo[sfx_sp_epi] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."Epic Jam\x80"
}
SafeFreeslot("sfx_sp_mul")
sfxinfo[sfx_sp_mul] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."M.U.L.E. Jam\x80"
}
SafeFreeslot("sfx_sp_rto")
sfxinfo[sfx_sp_rto] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."Retro Jam\x80"
}

local S_CLIPPING_DIST = (1536*FU)
local set_musvol = false
local this_musvol = 100
local listening_boombox

local boomjam_bpm = 130*FU
local epicjam_bpm = 128*FU
local mulejam_bpm = 136*FU
local retrojam_bpm = 120*FU
--should be fine if we dont synch this
rawset(_G, "SOAP_BOOMBOXJAMS", {
	[1] = {sfx = sfx_sp_jam, bpm = boomjam_bpm, fadeto = 50},
	[2] = {sfx = sfx_sp_epi, bpm = epicjam_bpm, fadeto = 0},
	[3] = {sfx = sfx_sp_mul, bpm = mulejam_bpm, fadeto = 0},
	[4] = {sfx = sfx_sp_rto, bpm = retrojam_bpm, fadeto = 0},
})
rawset(_G, "Soap_MakeJamCrochet",function(fixed_bpm)
	return FixedDiv(60*TR*FU, fixed_bpm)
end)
for k,v in ipairs(SOAP_BOOMBOXJAMS)
	v.crochet = Soap_MakeJamCrochet(v.bpm)
end

SafeFreeslot("SPR_SOAP_BOOMBOX")
SafeFreeslot("S_SOAP_BOOMBOX")
SafeFreeslot("MT_SOAP_BOOMBOX")
states[S_SOAP_BOOMBOX] = {
    sprite = SPR_SOAP_BOOMBOX,
    frame = A,
	tics = 1,
	nextstate = S_SOAP_BOOMBOX,
	action = function(mo)
		local jam_t = SOAP_BOOMBOXJAMS[mo.songid or 1]
		local my_crochet =	(jam_t and jam_t.crochet) or SOAP_BOOMBOXJAMS[1].crochet
		local my_jam =		(jam_t and jam_t.sfx) or SOAP_BOOMBOXJAMS[1].sfx
		
		if (leveltime % 6) == 0
			local note = P_SpawnMobjFromMobj(mo,
				P_RandomRange(-48,48)*FU,
				P_RandomRange(-48,48)*FU,
				0, MT_THOK
			)
			note.sprite = SPR_SOAP_BOOMBOX
			note.frame = P_RandomRange(1,7)
			note.fuse = TR * 3/2
			note.tics = note.fuse
			P_SetObjectMomZ(note, P_RandomFixedRange(2,4))
		end
		mo.momz = $ + P_GetMobjGravity(mo)
		
		local me = mo.tracer
		local p
		local soap
		
		local killCond = false
		if (me and me.valid)
			p = me.player
			soap = p.soaptable
			
			if mo.funny
				if (soap.taunttime)
					killCond = true
				end
				if (soap.breakdance)
					me.markedfordeath = nil
				else
					if me.markedfordeath == nil
						me.markedfordeath = 45 * TR
					elseif me.markedfordeath
						me.markedfordeath = $ - 1
						if me.markedfordeath <= 0
							killCond = true
						end
					end
				end
			else
				killCond = not (soap.breakdance)
			end
		end
		
		if not (me and me.valid and me.skin == "soapthehedge" and me.health)
		or killCond
			local speed = 5*mo.scale
			for i = 0,P_RandomRange(20,29)
				local poof = P_SpawnMobjFromMobj(mo,
					P_RandomFixedRange(-15,15),
					P_RandomFixedRange(-15,15),
					FixedDiv(mo.height,mo.scale)/2 + P_RandomFixedRange(-15,15),
					MT_THOK
				)
				poof.state = mobjinfo[MT_SPINDUST].spawnstate
				local hang,vang = R_PointTo3DAngles(
					poof.x,poof.y,poof.z,
					mo.x,mo.y,mo.z + mo.height/2
				)
				P_3DThrust(poof, hang,vang, speed)
				
				poof.spritexscale = $ + P_RandomFixedRange(0,2)/3
				poof.spriteyscale = poof.spritexscale
			end
			
			P_SpawnMobjFromMobj(mo,0,0,0,MT_THOK).state = S_XPLD1
			local sfx = P_SpawnGhostMobj(mo)
			sfx.flags2 = $|MF2_DONTDRAW
			sfx.fuse = TR
			sfx.tics = TR
			S_StartSound(sfx, sfx_pop)
			
			P_RemoveMobj(mo)
			return
		end
		mo.color = me.player.skincolor
		mo.lifetime = $ + 1
		
		local disttome = R_PointTo3DDist(mo.x,mo.y,mo.z, me.x,me.y,me.z)
		if not me.hitlag
			if mo.wasinhitlag
				mo.momx,mo.momy,mo.momz = unpack(mo.hitlagmom)
				mo.wasinhitlag = nil
				mo.hitlagmom = nil
			end
			
			if disttome > 128 * me.scale
				local ha,va = R_PointTo3DAngles(mo.x,mo.y,mo.z, me.x,me.y,me.z)
				P_3DThrust(mo,
					ha,va,
					FixedDiv(disttome, 128*me.scale)
				)
				mo.flags = $|MF_NOGRAVITY|MF_NOCLIP
			elseif P_CheckPosition(mo, mo.x,mo.y,mo.z)
			and R_PointToDist2(0,0, mo.momx,mo.momy) <= 3 * mo.scale
				mo.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP)
			end
		else
			if not mo.wasinhitlag
				mo.hitlagmom = {mo.momx,mo.momy,mo.momz}
				mo.wasinhitlag = true
			end
			mo.momx,mo.momy,mo.momz = 0,0,0
		end
		
		if not S_SoundPlaying(mo,my_jam)
		-- Synch it
		and ((mo.lifetime*FU) % my_crochet < (mo.lifetime + 1)*FU % my_crochet)
			S_StartSound(mo,my_jam)
		end
		
		if P_IsObjectOnGround(mo)
		and (my_crochet ~= 0)
			local work = (mo.lifetime*FU) % my_crochet
			work = FixedDiv($*180, my_crochet)
			local bounce = sin(FixedAngle(work)) - FU/2
			mo.spritexscale = FU - bounce/6
			mo.spriteyscale = FU + bounce/6
			
			if not soap.breakdance
				soap.spritexscale = $ - bounce/6
				soap.spriteyscale = $ + bounce/6
			end
		else
			mo.spritexscale = FU
			mo.spriteyscale = FU
		end
		
		if (displayplayer and displayplayer.valid)
			local dis = displayplayer
			if not (dis.realmo and dis.realmo.valid) then return end
			local dmo = dis.realmo
			
			local sounddist = R_PointTo3DDist(mo.x,mo.y,mo.z, dmo.x,dmo.y,dmo.z)
			local my_sfx_t = sfxinfo[my_jam]
			
			if (my_sfx_t.flags & SF_X8AWAYSOUND)
				sounddist = FixedDiv($, 8*FU)
			end
			if (my_sfx_t.flags & SF_X4AWAYSOUND)
				sounddist = FixedDiv($, 4*FU)
			end
			if (my_sfx_t.flags & SF_X2AWAYSOUND)
				sounddist = FixedDiv($, 2*FU)
			end
			if sounddist > S_CLIPPING_DIST then return end
			
			listening_boombox = mo
		end
	end
}
mobjinfo[MT_SOAP_BOOMBOX] = {
	doomednum = -1,
	spawnstate = S_SOAP_BOOMBOX,
	spawnhealth = 1,
	height = 28*FRACUNIT,
	radius = 14*FRACUNIT,
	flags = MF_NOCLIPTHING
}
addHook("ShouldDamage",function(mo,_,_,_,dmgt)
	if dmgt == DMG_DEATHPIT
		return false
	end
end,MT_SOAP_BOOMBOX)

local voleasing = 15
addHook("ThinkFrame",do
	if not (displayplayer and displayplayer.valid) then return end
	
	local dest_fade = 100
	if listening_boombox and listening_boombox.valid
		local jam_t = SOAP_BOOMBOXJAMS[listening_boombox.songid or 1]
		
		dest_fade = min($, (jam_t.fadeto or 0))
		
		set_musvol = true
	elseif set_musvol
		if this_musvol == 100 then set_musvol = false; end
		
		this_musvol = $ + ((100 - $) / voleasing)
		if P_IsLocalPlayer(displayplayer)
			S_SetInternalMusicVolume(this_musvol, displayplayer)
		end
		
		if 100 - abs(this_musvol) < voleasing
			this_musvol = 100
		end
	end
	--this is done after so we can get the lowest volume to ease to
	if listening_boombox and listening_boombox.valid
		this_musvol = $ + ((dest_fade - $) / voleasing)
		if P_IsLocalPlayer(displayplayer)
			S_SetInternalMusicVolume(this_musvol, displayplayer)
		end
		if this_musvol - dest_fade < voleasing
			this_musvol = dest_fade
		end
	end
	listening_boombox = nil
end)

addHook("NetVars",function(n)
	SOAP_BOOMBOXJAMS = n($)
end)
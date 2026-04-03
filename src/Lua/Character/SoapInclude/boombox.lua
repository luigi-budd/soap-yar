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

-- Vylet Pony - ANTONYMPH
SafeFreeslot("sfx_sp_ant")
sfxinfo[sfx_sp_ant] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."ANTONYMPH Jam\x80"
}

local S_CLIPPING_DIST = (1536*FU)
local set_musvol = false
local this_musvol = 100
local listening_boombox, prev_listbox
local listening_leveltime = 0
local showtitle = 0

local boomjam_bpm = 130*FU
local epicjam_bpm = 128*FU
local mulejam_bpm = 136*FU
local retrojam_bpm = 120*FU
local larpyjam_bpm = 132*FU -- no hate to vylet or this song lol i love them both
local larpyjam_captions = {
	-- [timestamp] = {"multi-line", "captions"} 
	[1] = {""},
	[TR*4/10] = {"I'm the Antonymph", "of the internet!"},
	[3*TR + (TR*15/100)] = {"Still cleaning up", "the viruses,"},
	[5*TR + (TR*6/10)] = {"that you had left"},
	[7*TR + (TR*45/100)] = {"I think I'm falling", "in love again..."},
	[11*TR] = {""},
	
	[11*TR + (TR*3/10)] = {"Don't stop, don't stop", "until you-"},
	[13*TR + (TR*6/10)] = {""},

	[14*TR + (TR*9/10)] = {"I'm the Antonymph", "of the internet!"},
	[17*TR + (TR*9/10)] = {"Been fighting on Newgrounds", "over if my love is valid"},
	[21*TR + (TR*7/10)] = {""},
	[22*TR] = {"Fuck the cynicism,"},
	[23*TR + (TR*6/10)] = {"Fuck the cynicism,", "let the \x85".."c\x87o\x82l\x83o\x88u\x89r\x8Fs \x88".."f\x8Al\x81y"},
	[25*TR] = {"Don't care if you think it\'s cringe", "because its"},
	[27*TR + (TR*2/10)] = {"Don't care if you think it\'s cringe", "because its not"},
	[27*TR + (TR*7/10)] = {"Don't care if you think it\'s cringe", "because its not your"},
	[28*TR + (TR*1/10)] = {"Don't care if you think it\'s cringe", "because its not your life"},
	[29*TR] = {""},
}

--should be fine if we dont synch this
-- credits = {"song name", "artist"}
rawset(_G, "SOAP_BOOMBOXJAMS", {
	[1] = {sfx = sfx_sp_jam, bpm = boomjam_bpm, fadeto = 50},
	[2] = {sfx = sfx_sp_epi, bpm = epicjam_bpm, fadeto = 0, credits = {"Spectre", "Alan Walker"}},
	[3] = {sfx = sfx_sp_mul, bpm = mulejam_bpm, fadeto = 0, credits = {"M.U.L.E.", "Seth Sternberger, Michelle Sternberger"}},
	[4] = {sfx = sfx_sp_rto, bpm = retrojam_bpm, fadeto = 0},
	[5] = {sfx = sfx_sp_ant, bpm = larpyjam_bpm, fadeto = 0, credits = {"ANTONYMPH", "Vylet Pony"}, captions = larpyjam_captions},
})
rawset(_G, "Soap_MakeJamCrochet",function(fixed_bpm)
	return FixedDiv(60*TR*FU, fixed_bpm)
end)
for k,v in ipairs(SOAP_BOOMBOXJAMS)
	v.crochet = Soap_MakeJamCrochet(v.bpm)
end

local damping = 6
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
			P_SetObjectMomZ(note, Soap_RandomFixedRange(2*FU,4*FU))
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
				if (soap.taunt.num and soap.taunt.num ~= 4)
					killCond = true
				end
				if (soap.breakdance)
					mo.markedfordeath = nil
					mo.flags2 = $ &~MF2_DONTDRAW
				else
					if mo.markedfordeath == nil
						mo.markedfordeath = 45 * TR
					elseif mo.markedfordeath
						mo.markedfordeath = $ - 1
						if mo.markedfordeath <= 0
							killCond = true
						elseif mo.markedfordeath <= TR
							mo.flags2 = $^^MF2_DONTDRAW
						elseif mo.markedfordeath <= 4*TR
							if (mo.markedfordeath/2) % 2
								mo.flags2 = $ &~MF2_DONTDRAW
							else
								mo.flags2 = $|MF2_DONTDRAW
							end
						end
					end
				end
			else
				killCond = not (soap.breakdance)
			end
		end
		
		if not (me and me.valid and me.skin == SOAP_SKIN and me.health)
		or killCond
			local speed = 15*mo.scale
			local range = 15*FU
			for i = 0,P_RandomRange(20,29)
				local poof = P_SpawnMobjFromMobj(mo,
					Soap_RandomFixedRange(-range, range),
					Soap_RandomFixedRange(-range, range),
					FixedDiv(mo.height,mo.scale)/2 + Soap_RandomFixedRange(-range, range),
					MT_SOAP_DUST
				)
				--poof.state = mobjinfo[MT_SPINDUST].spawnstate
				local hang,vang = R_PointTo3DAngles(
					poof.x,poof.y,poof.z,
					mo.x,mo.y,mo.z + mo.height/2
				)
				P_3DThrust(poof, hang,vang, speed)
				
				poof.spritexscale = $ + Soap_RandomFixedRange(0,2*FU)/3
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
				mo.momx = (me.x - mo.x) / damping
				mo.momy = (me.y - mo.y) / damping
				mo.momz = (me.z - mo.z) / damping
				mo.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
			else
				mo.flags = $ &~MF_NOCLIPHEIGHT
				if P_CheckPosition(mo, mo.x,mo.y,mo.z)
				and R_PointToDist2(0,0, mo.momx,mo.momy) <= 3 * mo.scale
					mo.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP)
				end
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
		-- should stop this boombox from playing its tune if we're
		-- already listening to one
		and not (prev_listbox and prev_listbox.valid and prev_listbox ~= mo)
			S_StartSound(mo,my_jam)
			listening_leveltime = leveltime
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
			
			if (prev_listbox and prev_listbox.valid)
				local canplay = true
				if (displayplayer.soaptable.boombox and displayplayer.soaptable.boombox.valid)
					canplay = displayplayer.soaptable.boombox == mo
				end
				if canplay
					listening_boombox = mo
				else
					S_StopSoundByID(mo, my_jam)
				end
			else
				listening_boombox = mo
			end
			if prev_listbox ~= mo
				showtitle = 4*TR
			end
		end
	end
}
mobjinfo[MT_SOAP_BOOMBOX] = {
	doomednum = -1,
	spawnstate = S_SOAP_BOOMBOX,
	spawnhealth = 1,
	height = 28*FRACUNIT,
	radius = 14*FRACUNIT,
	flags = MF_NOCLIPTHING,
	painchance = FU, --FU / 6 -- special tune chance
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
	prev_listbox = listening_boombox
	listening_boombox = nil
	
	showtitle = max($ - 1, 0)
end)

local last_caption = nil
addHook("HUD",function(v,p,cam)
	if not v.dointerp
		v.dointerp = function(tag)
			if v.interpolate == nil then return end
			v.interpolate(tag)
		end
	end
	if not (prev_listbox and prev_listbox.valid) then return end
	
	local jam_t = SOAP_BOOMBOXJAMS[prev_listbox.songid or 1]
	local result = K_GetScreenCoords(v,p,cam, prev_listbox, {anglecliponly = true})
	
	-- credits drawer
	if (showtitle and jam_t.credits and result.onscreen)
		local fade = 0
		if showtitle < 9
			fade = (10 - showtitle) << V_ALPHASHIFT
		end
		v.dointerp(true)
		v.drawString(result.x,result.y + 4*FU, "\025  "..jam_t.credits[1], V_ALLOWLOWERCASE|fade, "small-thin-fixed-center")
		v.drawString(result.x,result.y + 8*FU, jam_t.credits[2], V_GRAYMAP|V_ALLOWLOWERCASE|fade, "small-thin-fixed-center")
		v.dointerp(false)
	end
	
	-- caption drawer
	local ticker = leveltime - listening_leveltime
	if not (jam_t.captions) then return end
	local captions = jam_t.captions
	
	if (captions[ticker] ~= nil)
		last_caption = captions[ticker]
	end
	if not last_caption then return end
	local numcaptions = #last_caption
	
	--v.drawString(result.x,result.y + 8*FU, ("%.2f sec"):format(FixedDiv(ticker, TR)), V_ALLOWLOWERCASE, "thin-fixed-center")
	if not result.onscreen then return end
	if numcaptions == 1 and last_caption[1] == "" then return end
	
	local work = -36*result.scale
	local width = 0
	for i = 1, numcaptions
		width = max($, v.stringWidth(last_caption[i], V_ALLOWLOWERCASE, "thin"))
	end
	width = $ / 2
	
	v.dointerp(true)
	v.drawStretched(result.x - FU - (width*FU/2), result.y + work - FU,
		(width + 2)*FU, numcaptions*FU + (FU/2),
		v.cachePatch("SOAP_CAP_FL"), V_40TRANS
	)
	v.drawScaled(result.x,result.y + work + (4*FU * numcaptions), FU, v.cachePatch("SOAP_CAP_AR"), V_40TRANS)
	
	for i = 1, numcaptions
		v.dointerp(1204 + i)
		v.drawString(result.x,result.y + work, last_caption[i], V_ALLOWLOWERCASE, "small-thin-fixed-center")
		work = $ + 4*FU
	end
	v.dointerp(false)
end,"game")

addHook("NetVars",function(n)
	SOAP_BOOMBOXJAMS = n($)
end)
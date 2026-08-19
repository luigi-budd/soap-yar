for i = 0, 3
	sfxinfo[SafeFreeslot("sfx_takst"..i)].caption = "Step"
end

local function Footsteps(p)
	local me = p.realmo
	local soap = p.soaptable
	if not (me and me.valid and not p.spectator) then return end
	
	if not (me.skin == SOAP_SKIN or me.skin == TAKIS_SKIN) then return end
	
	local dostep = false
	local frame = (me.frame & FF_FRAMEMASK)
	if me.sprite2 == SPR2_WALK and not (soap.last.anim.state == S_PLAY_STND)
		local numframes = skins[p.skin].sprites[SPR2_WALK].numframes
		dostep = (frame == 0) or (frame == (numframes/2))
	elseif me.sprite2 == SPR2_RUN_
		local numframes = skins[p.skin].sprites[SPR2_RUN_].numframes
		dostep = (frame == 0) or (frame == (numframes/2))
	elseif me.sprite2 == SPR2_DASH
		local numframes = skins[p.skin].sprites[SPR2_DASH].numframes
		dostep = (frame == 0) or (frame == (numframes/2))
	end
	
	if dostep and not soap.steppedthisframe and soap.onGround
		soap.steppedthisframe = true
		
		local vol = 255 * 3/4
		S_StartSoundAtVolume(me, sfx_takst0, vol)
		S_StartSoundAtVolume(me, P_RandomRange(sfx_takst1, sfx_takst3), vol)
	elseif not dostep
		soap.steppedthisframe = false
	end
end

Takis_Hook.addHook("PostThinkFrame", Footsteps)

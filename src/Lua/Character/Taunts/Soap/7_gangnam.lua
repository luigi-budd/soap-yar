local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local CV = SOAP_CV
local tauntinfo = {}

tauntinfo.name = "Gangnam Style"
tauntinfo.cancelable = true

tauntinfo.run = function(p, me, soap, taunt)
	me.state = S_PLAY_SOAP_GANGNAM
	
	soap.stasistic = max($, 2)
	taunt.tics = 2
	if Soap_IsLocalPlayer(p)
	and CV.boomboxsfx.value
		S_FadeMusic(0, MUSICRATE/4, p)
	end
	
	me.momx,me.momy = p.cmomx,p.cmomy
	me.temptics = 0
end
tauntinfo.think = function(p, me, soap, taunt)
	if SoapTaunt_CancelWhen(p) or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
		me.temptics = nil
		me.extravalue1 = 0
		if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
		end
		if Soap_IsLocalPlayer(p)
			S_FadeMusic(100, MUSICRATE/4, p)
		end
		local sound = (me.skin == TAKIS_SKIN) and sfx_sp_em4 or sfx_sp_em3
		S_StopSoundByID(me, sound)
		soap.stasistic, taunt.tics = 0,0
	else
		soap.stasistic = max($, 2)
		taunt.tics = 2
		
		soap.noability = SNOABIL_ALL
		
		if me.state ~= S_PLAY_SOAP_GANGNAM
			me.state = S_PLAY_SOAP_GANGNAM
		end
		
		local dontplay = false
		local vol = 255
		-- off
		if CV.boomboxsfx.value == 0
			dontplay = true
		-- mineonly
		elseif (CV.boomboxsfx.value == 2)
		and (consoleplayer and consoleplayer.valid)
			dontplay = (p ~= consoleplayer)
		-- on
		elseif (displayplayer and displayplayer.valid)
			local imtaunting = displayplayer.soaptable.taunt.num == 7 and (skins[displayplayer.skin].name == SOAP_SKIN)
			-- if everyones taunt audio is on for us,
			-- make other taunt volumes a little quieter
			-- if we're also using the same taunt
			if imtaunting and (displayplayer ~= p)
				vol = 255 / 6
			end
		end
		
		local sound = (me.skin == TAKIS_SKIN) and sfx_sp_em4 or sfx_sp_em3
		if not S_SoundPlaying(me, sound)
		and not dontplay
			S_StartSoundAtVolume(me, sound, vol)
		elseif dontplay
			S_StopSoundByID(me, sound)
		end
		
		if (me.skin == TAKIS_SKIN)
		and (me.temptics % (4*3) == 0)
			local vfx = P_SpawnMobjFromMobj(me, 0,0, FixedDiv(me.height,me.scale)/2, MT_SOAP_WALLBUMP)
			vfx.color = ColorOpposite(me.color)
			vfx.blendmode = AST_ADD
			vfx.renderflags = $|RF_FULLBRIGHT|(me.extravalue1 % 2 and RF_HORIZONTALFLIP or 0)
			vfx.dispoffset = -200
			vfx.flags = $|MF_NOGRAVITY
			vfx.fuse = 12
			vfx.tics = -1
			vfx.sprite = SPR_SOAP_GFX
			vfx.frame = 40
			vfx.scale = $ / 2
			--vfx.destscale = me.scale * 3/2
			--vfx.scalespeed = FixedDiv(vfx.destscale - vfx.scale, vfx.fuse*FU)
			vfx.sixseveneffect = true
			vfx.dontdrawforviewmobj = me
			
			me.extravalue1 = $ + 1
		end
		me.temptics = $ + 1
	end
end
tauntinfo.drawer = function(v,i, x,y, selected, scale)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_CLNG,
		frame = (skins[consoleplayer.skin].name == SOAP_SKIN) and C or A, angle = 0
	}, selected, scale)
end
tauntinfo.canceled = function(p, me, soap, taunt)
	S_StopSoundByID(me, sfx_sp_em3)
	S_StopSoundByID(me, sfx_sp_em4)
	if Soap_IsLocalPlayer(p)
		S_FadeMusic(100, MUSICRATE/4, p)
	end
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
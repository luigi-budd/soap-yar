local function ooomagawd_callback(spark, me)
	spark.tics = (me.soap_supertemp) and TR or 10
	spark.frame = A
	spark.sprite = SPR_SOAP_GFX
	spark.frame = 34|FF_PAPERSPRITE|FF_ADD
	spark.momz = 0
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	spark.type = MT_SOAP_WALLBUMP
	local frac = 0
	local speed = 14
	spark.alpha = min(frac*8/6, FU)
	if (me.soap_supertemp)
		frac = FU
		speed = 12
		spark.sixseveneffect = true
		if (me.soap_poundvfx)
			spark.sixseveneffect = nil
			spark.tics = 20
			speed = 30
			
			spark.scale = FU * 5
			spark.spritexscale = $ / 5
			spark.fusesquish = 10
			spark.xstretch = FU/6
			spark.alpha = FU / 5
		end
	else
		spark.fusesquish = 5
		spark.scale = frac*2
		spark.spritexscale = $ / 2
		spark.movefactor = FU * 89/100
	end
	spark.fuse = spark.tics
	P_ThrustEvenIn2D(spark, spark.angle - ANGLE_90, speed*frac)
	spark.momx = $ + me.momx
	spark.momy = $ + me.momy
end
local tauntinfo = {}

tauntinfo.name = "Laugh"

tauntinfo.run = function(p, me, soap, taunt)
	if me.skin == SOAP_SKIN
		S_StartSound(me,sfx_hahaha)
		me.state = S_PLAY_SOAP_LAUGH
		soap.stasistic = TR
	else
		local sound = sfx_tk_omg
		me.state = S_PLAY_SOAP_LAUGH
		me.sprite2 = SPR2_WAIT
		me.frame = ($ &~FF_FRAMEMASK)|D
		soap.stasistic = TR / 2
		me.tics = soap.stasistic
		
		if P_RandomChance(FU / 20)
			sound = sfx_tk_om2
			Soap_SquashMacro(p, {ease_func = "inoutback", ease_time = TR, strength = 2*FU, squish = -FU, back = 2*FU})
			me.soap_supertemp = true
			me.soap_poundvfx = true
			Soap_DustRing(me,
				MT_PARTICLE, 24,
				{me.x,me.y,me.z},
				8*FU, 10*FU,
				me.scale / 10,
				me.scale * 6,
				false, ooomagawd_callback
			)
			me.soap_supertemp = nil
			me.soap_poundvfx = nil
			
			for play in players.iterate
				if not (play.realmo and play.realmo.valid) then continue end
				if R_PointToDist2(play.realmo.x,play.realmo.y, me.x,me.y) > 4096*me.scale then continue end
				
				if Soap_IsLocalPlayer(play)
					Soap_StartQuake(6*FU, TR/2)
				end
				P_FlashPal(play, PAL_INVERT, 4)
			end
		elseif Soap_IsLocalPlayer(p)
			Soap_StartQuake(FU, TR/6)
		end
		S_StartSound(me,sound)
	end
	taunt.tics = soap.stasistic
	
	me.momx,me.momy = p.cmomx,p.cmomy
end
tauntinfo.postthink = function(p, me, soap, taunt)
	local angle = (p.cmd.angleturn << 16)
	if soap.in2D then angle = ANGLE_90 end
	
	p.drawangle = angle + ANGLE_180
end
tauntinfo.drawer = function(v,i, x,y, selected)
	local istakis = skins[consoleplayer.skin].name == TAKIS_SKIN
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = istakis and SPR2_WAIT or SPR2_APOS,
		frame = istakis and D or A, angle = 1
	}, selected)
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
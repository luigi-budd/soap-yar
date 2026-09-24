local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local sixseven_callback = function(spark, me)
	local frac = 0
	if (me.sixsev_super >= 6*TR)
		frac = (34230) + (me.sixsev_super - 6*TR) * 243
	else
		frac = (me.sixsev_super - 3*TR) * 326
	end
	
	spark.tics = (me.soap_supertemp) and TR or 10
	spark.frame = A
	spark.sprite = SPR_SOAP_GFX
	spark.frame = 34|FF_PAPERSPRITE|FF_ADD
	spark.momz = 0
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	spark.type = MT_SOAP_WALLBUMP
	local speed = 14
	spark.alpha = min(frac*8/6, FU / 3)
	spark.fusesquish = 5
	spark.scale = frac*2
	spark.spritexscale = $ / 2
	spark.movefactor = FU * 89/100
	spark.fuse = spark.tics
	P_ThrustEvenIn2D(spark, spark.angle - ANGLE_90, speed*frac)
	spark.momx = $ + me.momx
	spark.momy = $ + me.momy
end

local tauntinfo = {}

tauntinfo.name = "Six-Seven"
tauntinfo.cancelable = true

tauntinfo.run = function(p, me, soap, taunt)
	soap.stasistic = max($, 2)
	taunt.tics = 2
	me.sixseveeeen = 0
	me.sixsev_adjust = 0
	me.sixsev_super = 0
	
	me.momx,me.momy = p.cmomx,p.cmomy
	me.state = S_PLAY_SOAP_SIXSEV
end
tauntinfo.think = function(p, me, soap, taunt)
	if SoapTaunt_CancelWhen(p,nil, true) or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
		if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
		end
		soap.stasistic, taunt.tics = 0,0
		me.sixseveeeen = nil
		me.sixsev_adjust = nil
		me.sixsev_super = nil
		
		me.colorized = false
	else
		soap.stasistic = max($, 2)
		taunt.tics = 2
		
		soap.noability = SNOABIL_ALL
		if me.state ~= S_PLAY_SOAP_SIXSEV
		and not (soap.inPain or me.health <= 0)
			me.state = S_PLAY_SOAP_SIXSEV
		end
		
		if soap.jump == 1
			me.sixsev_adjust = min($ + 10, 20)
		end
		me.sixseveeeen = $ + 1 + me.sixsev_adjust
		me.sixsev_adjust = max($ - 1, 0)
		
		if me.sixsev_adjust > 10
			P_SpawnGhostMobj(me).alpha = FU / 2
			me.sixsev_super = $ + 1
			
			if (me.sixsev_super == TR)
			or (me.sixsev_super == 3*TR)
			or (me.sixsev_super == 6*TR)
				S_StartSoundAtVolume(me,sfx_s3ka2,192)
			end
			if (me.sixsev_super == 3*TR)
				S_StartSound(me,sfx_cdfm40)
				S_StartSound(me,sfx_sp_em2)
			elseif (me.sixsev_super == 6*TR)
				S_StartSoundAtVolume(me,sfx_s3k9c,192)
			end
		else
			me.sixsev_super = clamp(0, $ - 2, TR)
		end
		if me.sixsev_super >= TR
			if (leveltime % 4 == 0)
				Soap_DustRing(me,
					dust_type(me),
					P_RandomRange(6, 10),
					{me.x,me.y,me.z},
					16*me.scale + (me.sixsev_super - TR) * 783,
					me.scale*7,
					me.scale,
					me.scale/2,
					false, dust_noviewmobj
				)
				if me.sixsev_super >= 3*TR
					Soap_DustRing(me,
						MT_PARTICLE, 24,
						{me.x,me.y,me.z},
						8*FU, 10*FU,
						me.scale / 10,
						me.scale * 6,
						false, sixseven_callback
					)
					local frac = (me.sixsev_super - 3*TR) * 967
					if P_RandomChance(min(frac, FU))
						local offset = (200*FU) + (min(frac, FU) * 150)
						local offsetspeed = -offset / (states[mobjinfo[MT_SOAP_SPEEDLINE].spawnstate].tics)
						while frac > FU
							local ha = FixedAngle(360 * P_RandomFixed())
							local va = FixedAngle(360 * P_RandomFixed())
							local of = Vec3.SphereToCartesian(ha,va) * offset
							of.z = $ + FixedDiv(me.height, me.scale)/2
							local v = P_SpawnMobjFromMobj(me, of.x,of.y,of.z, MT_PARTICLE)
							P_SetMobjStateNF(v, mobjinfo[MT_SOAP_SPEEDLINE].spawnstate)
							v.renderflags = $|RF_ALWAYSONTOP
							v.color = ColorOpposite(p.skincolor)
							v.angle = ha + ANGLE_180
							v.rollangle = InvAngle(va)
							v.scale = ($ * 2) + frac
							v.blendmode = AST_ADD
							local finalvec = (Vec3.SphereToCartesian(ha,va) * offsetspeed)
							finalvec:ToMobjMom(v)
							frac = $ - FU
						end
					end
				end
			end
			
			local range = 20*FU
			local z = P_SpawnMobjFromMobj(me,
				Soap_RandomFixedRange(-range, range),
				Soap_RandomFixedRange(-range, range),
				Soap_RandomFixedRange(0, 30*FU),
				MT_WATERZAP
			)
			z.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
			if me.sixsev_super >= 3*TR
				local range = 4*me.scale
				local g = P_SpawnGhostMobj(me)
				g.colorized = true
				g.blendmode = AST_ADD
				g.destscale = 0
				g.dispoffset = -600
				P_SetObjectMomZ(g, 12*FU)
				
				P_SetOrigin(g,
					g.x + Soap_RandomFixedRange(-range, range),
					g.y + Soap_RandomFixedRange(-range, range),
					g.z + Soap_RandomFixedRange(-range, range)
				)
			end
			if me.sixsev_super >= 6*TR
				Soap_StartQuake(FU + (me.sixsev_super - 6*TR) * 2400, 2,
					{me.x,me.y,me.z}, 256*FU
				)
				me.colorized = (leveltime % 2 == 0)
			else
				me.colorized = false
			end
		else
			me.colorized = false
		end
		
		me.frame = $ &~FF_FRAMEMASK
		me.frame = $|((me.sixseveeeen / 10) % 8)
	end
end
tauntinfo.drawer = function(v,i, x,y, selected)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_MSC8,
		frame = 3, angle = 0
	}, selected)
end
tauntinfo.canceled = function(p,me,soap)
	me.sixseveeeen = nil
	me.sixsev_adjust = nil
	me.sixsev_super = nil
	
	me.colorized = false
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
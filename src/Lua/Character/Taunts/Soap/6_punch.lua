local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local CV = SOAP_CV
local tauntinfo = {}

tauntinfo.name = "Punch"

tauntinfo.run = function(p, me, soap, taunt)
	if (CV.tauntinterference.value == 0) and Soap_IsCompGamemode()
		SoapTaunt_Warning(p)
		return
	end
	
	me.state = S_PLAY_SOAP_PREPUNCH
	
	me.tempangle = me.angle
	me.punchwindup = 20
	S_StartSound(me,sfx_kc63)
	Soap_DustRing(me,
		dust_type(me),
		P_RandomRange(8,14),
		{me.x,me.y,me.z},
		16*me.scale,
		me.scale*5,
		me.scale,
		me.scale/2,
		false, dust_noviewmobj
	)
	
	soap.stasistic = max($, 2)
	taunt.tics = 34
	
	me.momx,me.momy = p.cmomx,p.cmomy
	soap.accspeed = 0
end
tauntinfo.think = function(p, me, soap, taunt)
	if SoapTaunt_CancelWhen(p, true) or me.tempangle == nil
		me.tempangle = nil
		if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
		end
		soap.stasistic, taunt.tics = 0,0
		return
	end
	soap.stasistic = max($, 2)
	
	p.drawangle = me.tempangle
	soap.noability = SNOABIL_ALL
	
	if me.punchwindup
		me.punchwindup = $ - 1
		if me.punchwindup == 0
			me.state = S_PLAY_SOAP_PUNCH1
			
			local dist = 35*FU
			local ang = me.tempangle
			local thok = P_SpawnMobjFromMobj(me,
				P_ReturnThrustX(nil,ang,dist),
				P_ReturnThrustY(nil,ang,dist),
				0,
				MT_THOK
			)
			P_SetOrigin(thok, thok.x,thok.y,thok.z)
			thok.radius = 35*me.scale
			thok.height = 70*me.scale
			thok.scale = me.scale
			thok.fuse = 2
			thok.flags2 = $|MF2_DONTDRAW
			thok.angle = ang
			
			S_StartSound(me, sfx_sp_bsl)
			local fakerange = 128*FU
			local range = thok.radius*3/2
			local enemyhit = false
			searchBlockmap("objects", function(ref, found)
				if found == me then return end
				if R_PointToDist2(found.x, found.y, thok.x, thok.y) > range + found.radius
					return
				end
				if not Soap_ZCollide(found,thok) then return end
				if not (found.health) then return end
				if not P_CheckSight(thok,found) then return end
				local topheight = found.z + found.height
				local botheight = me.floorz
				if soap.gravflip == -1
					topheight = found.z
					botheight = me.ceilingz
				end
				if (topheight < botheight) then return end
				
				if (found.type == MT_TNTBARREL)
					Soap_ImpactVFX(found, me, nil,nil, true)
					Soap_SpawnBumpSparks(found, me, nil,false, found.scale * 3/2, true)
					Soap_DamageSfx(found, FU, 2*FU)
					
					S_StartSound(found, found.info.attacksound)
					P_3DThrust(found, ang, ANG20, 25 * me.scale)
					found.flags = $|MF_MISSILE|MF_NOBLOCKMAP
					found.state = found.info.missilestate
					
					enemyhit = true
				elseif Soap_CanDamageEnemy(p, found,MF_ENEMY|MF_BOSS|MF_MONITOR|MF_SHOOTABLE)
					Soap_ImpactVFX(found, me, nil,nil, true)
					Soap_SpawnBumpSparks(found, me, nil,false, found.scale * 3/2, true)
					Soap_DamageSfx(found, 25*FU, 30*me.scale)
					P_DamageMobj(found,me,me, damage)
					Soap_Hitlag.addHitlag(found, 12, true)
					Soap_Hitlag.addHitlag(me, 12, false)
					Soap_StartQuake(10*FU, 12, {me.x, me.y, me.z}, 512*me.scale)
					
					enemyhit = true
				elseif (found.player and found.player.valid)
				and not (found.player.powers[pw_flashing] or found.player.powers[pw_invulnerability])
					local p2 = found.player
					
					Soap_SpawnBumpSparks(found, me, nil,false, found.scale * 3/2, true)
					Soap_DamageSfx(found, 25*FU, 30*me.scale)
					
					-- kou parries lol
					if (found.skin == "kou")
					and (p2.kou and p2.kou.parrytimer)
						me.soap_tumble = true
						me.soap_tumble_oldmomz = me.momz
						
						P_ResetPlayer(p)
						me.state = S_PLAY_PAIN
						me.tempangle = nil
						p.drawangle = ang + ANGLE_180
						
						if P_IsObjectOnGround(me)
							me.z = $ + P_MobjFlip(me)
						end
						local speed = (soap.taunt.tics) and 30*me.scale or 12*me.scale
						P_Thrust(me, ang, -speed*2)
						P_SetObjectMomZ(me, 30*me.scale, true)
						p.powers[pw_flashing] = flashingtics
						
						-- kou vfx
						P_FlashPal(p, PAL_INVERT, 4)
						P_FlashPal(p2, PAL_INVERT, 4)
						local kou = p2.kou
						kou.punchlagactive = 18
						
						if not (found.state == S_PLAY_KOU_DROP)
							found.state = S_PLAY_KOU_DROP
						end
						
						local circ = P_SpawnMobjFromMobj(found, 0, 0, 1, MT_KOUCIRCLE)
						circ.tics = 15
						circ.scale = found.scale + found.scale
						circ.destscale = found.scale * 30
						circ.scalespeed = found.scale * 3
						P_Telekinesis(found.player, 45*found.scale, 640*found.scale)
						local kicker = P_SpawnMobjFromMobj(found, 0,0,0, MT_KOU_MISSILEPARTICLE)
						kicker.destscale = $*8
						kicker.scalespeed = found.scale/2
						kicker.color = p2.skincolor
						kicker.blendmode = AST_ADD
						kicker.fuse = 6
						local sounds = {sfx_kodrp1, sfx_kodrp2}
						S_StartSound(found, sounds[P_RandomRange(1, #sounds)])
						
						Soap_Hitlag.addHitlag(found, 12, false)
						Soap_Hitlag.addHitlag(me, 12, true)
						Soap_StartQuake(10*FU, 12, {me.x, me.y, me.z}, 512*me.scale)
						Soap_ImpactVFX(me, found, nil,2*FU,nil,nil, DMG_ELECTRIC)
						Soap_DamageSfx(me, 25*FU, 30*me.scale, DMG_ELECTRIC)
						
						return true
					end
					Soap_ImpactVFX(found, me, nil,nil, true)
					
					if CV.tauntinterference.value
						found.soap_tumble = true
						found.soap_tumble_oldmomz = found.momz
						
						P_ResetPlayer(p2)
						found.state = S_PLAY_PAIN
						p2.drawangle = ang + ANGLE_180
						
						if P_IsObjectOnGround(found)
							found.z = $ + P_MobjFlip(found)
						end
						local speed = (p2.soaptable.taunt.tics) and 30*me.scale or 12*me.scale
						P_Thrust(found, ang, speed)
						P_SetObjectMomZ(found, 30*me.scale, true)
						p2.powers[pw_flashing] = flashingtics
						
						-- lolllll
						if (gametype == GT_ZE2 or (ZE2 and ZE2.isGametype()))
						and (p2.xSlinger and p2.xSlinger.team == 2)
							P_DamageMobj(found, me,me, 100)
						end
					else --lol
						P_DoPlayerPain(p2, me,me)
						found.momx = 0
						found.momy = 0
					end
					
					Soap_Hitlag.addHitlag(found, 12, true)
					Soap_Hitlag.addHitlag(me, 12, false)
					Soap_StartQuake(10*FU, 12, {me.x, me.y, me.z}, 512*me.scale)
					
					enemyhit = true
				--Most likely a spike thing
				elseif (found.info.mass == DMG_SPIKE)
				and (found.flags & (MF_PAIN))
				or (found.type == MT_SPIKE or found.type == MT_WALLSPIKE)
				and (found.takis_flingme ~= false)
					-- probably a cactus in acz
					if found.flags & MF_SCENERY
					and not (found.type == MT_SPIKE or found.type == MT_WALLSPIKE)
						local speed = 15*found.scale
						local range = 15*FU
						for i = 0,P_RandomRange(15,20)
							local poof = P_SpawnMobjFromMobj(found,
								Soap_RandomFixedRange(-range, range),
								Soap_RandomFixedRange(-range, range),
								FixedDiv(found.height,found.scale)/2 + Soap_RandomFixedRange(-range, range),
								MT_SOAP_DUST
							)
							local hang,vang = R_PointTo3DAngles(
								poof.x,poof.y,poof.z,
								found.x,found.y,found.z + found.height/2
							)
							P_3DThrust(poof, hang,vang, speed)
							
							poof.spritexscale = $ + Soap_RandomFixedRange(0,2*FU)/3
							poof.spriteyscale = poof.spritexscale
						end
						
						P_SpawnMobjFromMobj(found,0,0,0,MT_THOK).state = S_XPLD1
						local sfx = P_SpawnGhostMobj(found)
						sfx.flags2 = $|MF2_DONTDRAW
						sfx.fuse = TR
						sfx.tics = TR
						S_StartSound(sfx, sfx_pop)
					end
					P_KillMobj(found,me,me)
				end
			end, 
			thok,
			thok.x - fakerange, thok.x + fakerange,
			thok.y - fakerange, thok.y + fakerange)
		end
	end
end
tauntinfo.postthink = function(p, me, soap, taunt)
	if me.tempangle == nil then return end
	p.drawangle = me.tempangle --+ FixedAngle(36*FU * me.punchwindup)
end
tauntinfo.drawer = function(v,i, x,y, selected)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_MSC6,
		frame = A, angle = 1
	}, selected)
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
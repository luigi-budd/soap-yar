-- The taunt wheel is shared by both characters, and is sorta complicated
-- so it gets its own file.
local CV = SOAP_CV

local taunt_cmd = {
	active = false,
	x = 0,
	y = 0,
	pointing = -1,
	buttons = 0,
	
	forward = 0,
	side = 0,
}

local function CheckTauntAvail(p)
	if gamestate ~= GS_LEVEL then return false; end
	if not (p and p.valid) then return false; end
	if p.spectator then return false; end
	local soap = p.soaptable
	if not soap then return false; end
	local taunt = soap.taunt
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return false; end
	local me = p.realmo
	if not (me and me.valid) then return false; end

	if (p.panim == PA_IDLE or p.panim == PA_RUN or soap.accspeed <= 5*FU)
	and (P_IsObjectOnGround(me))
	and not (taunt.active or taunt.tics)
	and me.health
	and (soap.notCarried)
	and not (soap.noability & SNOABIL_TAUNTS)
	and (SOAP_TAUNTS[me.skin] ~= nil and #SOAP_TAUNTS[me.skin])
		return true
	end
	return false
end

local function StartMenu()
	if taunt_cmd.active then return end
	taunt_cmd.active = true
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	input.ignoregameinputs = true
end
local function StopMenu()
	if not taunt_cmd.active then return end
	taunt_cmd.active = false
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	input.ignoregameinputs = false
end

local scroll_fact = 400
local wheel_radius = 60*FU
local wheel_start = 28*FU

local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local function chardrawer(v,i, x,y, props, selected)
	local scale = FixedMul(selected and (FU*3/5)/2 or (FU/4), skins[props.skin].highresscale)
	local patch,flip = v.getSprite2Patch(props.skin, props.spr2, false, props.frame, props.angle, 0)
	v.drawScaled(x, y + (patch.height * scale)/2,
		scale, patch, (flip) and V_FLIP or 0,
		v.getColormap(nil,nil, selected and "AllYellow" or "AllWhite")
	)
end

local function cancelConds(p, nobuttons, checkspinonly)
	local me = p.realmo
	local soap = p.soaptable
	
	local cancel = false
	if (soap.inPain)
	or (not soap.notCarried)
		cancel = true
	end
	if (not soap.onGround)
	or soap.accspeed >= 4*FU
		cancel = true
	end
	
	local buttoncancel = false
	if (soap.jump == 1 and not checkspinonly)
	or (soap.use)
		buttoncancel = true
	end
	if (buttoncancel)
	and not nobuttons
		cancel = true
	end
	return cancel
end

local sixseven_callback = function(spark)
	spark.tics = 12
	spark.frame = A
	spark.sprite = SPR_SOAP_GFX
	spark.frame = 62|FF_PAPERSPRITE
	spark.momz = 0
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	P_ThrustEvenIn2D(spark, spark.angle - ANGLE_90, 8*FU)
end

rawset(_G, "SOAP_TAUNTS", {})
SOAP_TAUNTS[SOAP_SKIN] = {
	[1] = {
		name = "Flex",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me, (me.skin == TAKIS_SKIN) and sfx_tk_whp or sfx_flex)
			me.state = S_PLAY_SOAP_FLEX
			soap.stasistic = TR
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		postthink = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			local angoff = ANGLE_90
			if (me.skin == TAKIS_SKIN)
				angoff = ANGLE_180
			end
			p.drawangle = angle + angoff
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_FLEX,
				frame = A, angle = 1
			}, selected)
		end,
		-- canceled = function(p, me, soap, taunt)
		-- optional function that runs when the tuant is forcibly
		-- canceled, such as switching skins or dying
	},
	[2] = {
		name = "Laugh",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me,sfx_hahaha)
			me.state = S_PLAY_SOAP_LAUGH
			soap.stasistic = TR
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		postthink = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			p.drawangle = angle + ANGLE_180
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_APOS,
				frame = A, angle = 1
			}, selected)
		end,
	},
	[3] = {
		name = "Death",
		
		run = function(p, me, soap, taunt)
			me.state = S_PLAY_DEAD
			me.sprite2 = SPR2_MSC4
			me.tics = -1
			
			me.tempangle = p.drawangle
			S_StartSound(me,sfx_altdi1,p)
			S_StartSound(me,sfx_sp_smk,p)
			S_StartSound(me,sfx_s3k5d)
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
			Soap_StartQuake(10*FU, 10, {me.x,me.y,me.z}, 256*me.scale)
			
			soap.stasistic = max($, 2)
			taunt.tics = 2
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p)
			or me.tempangle == nil
				me.tempangle = nil
				if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
					me.state = S_PLAY_WALK
					P_MovePlayer(p)
					Soap_ResetState(p)
				end
				soap.stasistic, taunt.tics = 0,0
			else
				soap.stasistic = max($, 2)
				taunt.tics = 2
				
				p.drawangle = me.tempangle
				soap.noability = SNOABIL_ALL
				
				if me.state ~= S_PLAY_DEAD
					me.state = S_PLAY_DEAD
					me.tics = -1
				elseif me.sprite2 ~= SPR2_MSC4
					me.frame = $ &~FF_FRAMEMASK
					me.sprite2 = SPR2_MSC4
				end
			end
		end,
		postthink = function(p, me, soap, taunt)
			if me.tempangle == nil then return end
			p.drawangle = me.tempangle
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_MSC4,
				frame = A, angle = 2
			}, selected)
		end,
	},
	[4] = {
		name = "Breakdance",
		
		run = function(p, me, soap, taunt)
			soap.stasistic = max($, 2)
			taunt.tics = 2
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p)
				if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
					me.state = S_PLAY_WALK
					P_MovePlayer(p)
					Soap_ResetState(p)
				end
				soap.stasistic, taunt.tics = 0,0
			else
				soap.stasistic = max($, 2)
				taunt.tics = 2
				
				soap.noability = SNOABIL_ALL &~SNOABIL_BREAKDANCE
			end
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_BRDA,
				frame = F, angle = 2
			}, selected)
		end,
	},
	[5] = {
		name = "67",
		
		run = function(p, me, soap, taunt)
			soap.stasistic = max($, 2)
			taunt.tics = 2
			me.sixseveeeen = 0
			me.sixsev_adjust = 0
			me.sixsev_super = 0
			
			me.momx,me.momy = p.cmomx,p.cmomy
			me.state = S_PLAY_SOAP_SIXSEV
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p,nil, true)
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
					P_SpawnGhostMobj(me)
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
								MT_PARTICLE, 16,
								{me.x,me.y,me.z},
								8*FU, 8*FU,
								me.scale / 10,
								me.scale * 4,
								false, sixseven_callback
							)
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
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_MSC8,
				frame = 3, angle = 0
			}, selected)
		end,
	},
	[6] = {
		name = "Punch",
		
		run = function(p, me, soap, taunt)
			me.state = S_PLAY_SOAP_SPTOP
			
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
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p, true)
			or me.tempangle == nil
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
							P_KillMobj(found,me,me)
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
							local p2 = found.player
							
							Soap_ImpactVFX(found, me, nil,nil, true)
							Soap_SpawnBumpSparks(found, me, nil,false, found.scale * 3/2, true)
							Soap_DamageSfx(found, 25*FU, 30*me.scale)
							
							if Soap_CanHurtPlayer(p,p2)	
								P_DamageMobj(found,me,me, DMG_INSTAKILL)
							else
								found.soap_tumble = true
								found.soap_tumble_oldmomz = found.momz
								
								P_ResetPlayer(p2)
								found.state = S_PLAY_PAIN
								p2.drawangle = ang + ANGLE_180
								
								if P_IsObjectOnGround(found)
									found.z = $ + P_MobjFlip(found)
								end
								P_Thrust(found, ang, 12 * me.scale)
								P_SetObjectMomZ(found, 30*me.scale, true)
								p2.powers[pw_flashing] = flashingtics
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
			
		end,
		postthink = function(p, me, soap, taunt)
			if me.tempangle == nil then return end
			p.drawangle = me.tempangle + FixedAngle(36*FU * me.punchwindup)
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_MSC6,
				frame = A, angle = 1
			}, selected)
		end,
	},
}
SOAP_TAUNTS[TAKIS_SKIN] = {
	[1] = SOAP_TAUNTS[SOAP_SKIN][1],
	[2] = SOAP_TAUNTS[SOAP_SKIN][2],
	[3] = SOAP_TAUNTS[SOAP_SKIN][3],
	[4] = {
		name = "Surfin' Bird",
		
		run = function(p,me,soap, taunt)
			soap.stasistic = max($, 2)
			taunt.tics = 2
			
			me.momx,me.momy = p.cmomx,p.cmomy
			me.state = S_PLAY_SOAP_BREAKDANCE
			
			soap.breakdance = 0
		end,
		think = function(p,me,soap, taunt)
			if cancelConds(p)
				if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
					me.state = S_PLAY_WALK
					P_MovePlayer(p)
					Soap_ResetState(p)
				end
				soap.stasistic, taunt.tics = 0,0
				return
			end
			
			soap.stasistic = max($, 2)
			taunt.tics = 2
			if me.state ~= S_PLAY_SOAP_BREAKDANCE
				me.state = S_PLAY_SOAP_BREAKDANCE
			end
			
			--init
			local timer = soap.breakdance % skins[p.skin].sprites[SPR2_BRDA].numframes
			me.frame = ($ &~FF_FRAMEMASK)|(timer)
			
			p.drawangle = (p.cmd.angleturn << 16) + ANGLE_180
			local incre_frame = (leveltime & 3) == 0
			if incre_frame
				soap.breakdance = $ + 1
			end
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_BRDA,
				frame = A, angle = 0
			}, selected)
		end,
	},
	[5] = SOAP_TAUNTS[SOAP_SKIN][5],
}

local cmd_sig = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) cmd_sig = n($); end)

COM_AddCommand("_soap_dotaunt",function(p, sig, selected)
	if sig ~= cmd_sig then return end
	if not CheckTauntAvail(p) then return end
	selected = tonumber($)
	
	local soap = p.soaptable
	local me = p.realmo
	local taunt = soap.taunt
	
	taunt.num = selected + 1
	taunt.prev = taunt.num
	local taunt_t = SOAP_TAUNTS[me.skin][selected + 1]
	if not taunt_t then return end
	taunt_t.run(p, me, soap, taunt)
	
	soap.jumplockout = 2
end)

local gc2bt = {
	[GC_FIRE]		= BT_ATTACK,
	[GC_FIRENORMAL]	= BT_FIRENORMAL,
	[GC_TOSSFLAG]	= BT_TOSSFLAG,
	[GC_SPIN]		= BT_SPIN,
	[GC_JUMP]		= BT_JUMP,
}
local control_gc = {
	[GC_FORWARD]		= 1,
	[GC_BACKWARD]		= -1,
	
	[GC_STRAFELEFT]		= -2,
	[GC_TURNLEFT]		= -2,
	[GC_STRAFERIGHT]	= 2,
	[GC_TURNRIGHT]		= 2,
}
local keymovespeed = 7*FU
addHook("KeyDown", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	
	local kname = key.name:lower()
	
	if kname == CV.taunt_key.string:lower()
	and (skins[consoleplayer.skin].name == SOAP_SKIN or skins[consoleplayer.skin].name == TAKIS_SKIN)
		if taunt_cmd.active
		and (consoleplayer.soaptable and consoleplayer.soaptable.taunt.prev > 0)
			COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..(consoleplayer.soaptable.taunt.prev - 1))
			StopMenu()
		else
			StartMenu()
		end
		return true
	elseif kname == "escape"
	and taunt_cmd.active
		StopMenu()
		return true
	end
	
	-- game controls
	for gc, bt in pairs(gc2bt)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if key.num == k1 or key.num == k2
			taunt_cmd.buttons = $|bt
		end
	end
	
	for gc, type in pairs(control_gc)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if not (key.num == k1 or key.num == k2) then continue end
		
		-- forwardmove keys
		if abs(type) == 1
			taunt_cmd.forward = keymovespeed * type
		elseif abs(type) == 2
			taunt_cmd.side = keymovespeed * sign(type)
		end
	end
end)

addHook("KeyUp", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	
	-- game controls
	for gc, bt in pairs(gc2bt)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if key.num == k1 or key.num == k2
			taunt_cmd.buttons = $ &~bt
		end
	end
	
	for gc, type in pairs(control_gc)
		local k1, k2 = input.gameControlToKeyNum(gc)
		if not (key.num == k1 or key.num == k2) then continue end
		
		-- forwardmove keys
		if abs(type) == 1
			taunt_cmd.forward = 0
		elseif abs(type) == 2
			taunt_cmd.side = 0
		end
	end
end)

local function ClientTauntHandle(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	
	if not taunt_cmd.active then return end
	
	-- nice one asshole
	if SOAP_TAUNTS[me.skin] == nil
		StopMenu()
		return
	end
	
	if MenuLib.client.currentMenu.id ~= -1
		MenuLib.initMenu(-2)
		input.ignoregameinputs = true
	end
	
	if (taunt_cmd.buttons & BT_SPIN)
	--or cancelConds(p, true)
		StopMenu()
	end
	
	-- negative angleturn is rightwards
	-- positive aiming is upwards
	local workx = -(mouse.dx*8) * scroll_fact
	local worky = -(mouse.dy*8) * scroll_fact
	workx = $ - taunt_cmd.side
	worky = $ + taunt_cmd.forward
	taunt_cmd.x = $ - workx
	taunt_cmd.y = $ + worky
	local ang = R_PointToAngle2(0,0, taunt_cmd.x,taunt_cmd.y)
	local dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
	if (dist > wheel_radius)
		taunt_cmd.x = P_ReturnThrustX(nil,ang, wheel_radius)
		taunt_cmd.y = P_ReturnThrustY(nil,ang, wheel_radius)
		dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
	end
	
	local oldhover = taunt_cmd.pointing
	local selected = -1
	if (dist >= wheel_start)
		local avail = #SOAP_TAUNTS[me.skin]
		local angstep = FixedDiv(360*FU, avail*FU)
		ang = AngleFixed(InvAngle($ - ANGLE_90))
		selected = FixedTrunc(FixedDiv(ang, angstep)) / FU
		taunt_cmd.pointing = selected
	else
		taunt_cmd.pointing = -1
	end
	if (oldhover ~= taunt_cmd.pointing)
	and (dist >= wheel_start)
		S_StartSound(nil,sfx_menu1,p)
	end
	
	if (taunt_cmd.buttons & (BT_ATTACK|BT_JUMP))
	or (mouse.buttons & MB_BUTTON1)
	and (dist >= wheel_start)
		COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..selected)
		StopMenu()
	end
end

rawset(_G, "Soap_TauntWheelThink", function(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	local taunt = soap.taunt
	
	-- lets also handle the client stuff in here
	if p == consoleplayer
		ClientTauntHandle(p)
	end
	
	if taunt.tics > 0
		-- nice one asshole
		if SOAP_TAUNTS[me.skin] == nil
		or (me.skin ~= soap.last.skin)
		or not (me.health)
			local taunt_t = SOAP_TAUNTS[soap.last.skin][taunt.num]
			if taunt_t.canceled
				taunt_t.canceled(p, me, soap, taunt)
			end
			
			taunt.tics = 0
			if me.health
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
				Soap_ResetState(p)
			end
			return
		end
		
		local taunt_t = SOAP_TAUNTS[me.skin][taunt.num]
		if taunt_t.think
			taunt_t.think(p, me, soap, taunt)
		end
		
		if not (me.hitlag)
			taunt.tics = $ - 1
		end
	else
		taunt.tics = 0
		taunt.num = 0
	end
end)

-- its just easier to handle the hud here
local wheel_inner = wheel_start + (wheel_radius - wheel_start)/2
addHook("HUD",function(v,p)
	-- bruh
	p = consoleplayer
	
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local taunt = taunt_cmd
	
	if not taunt.active then return end
	
	v.drawScaled(160*FU,100*FU, FU/2, v.cachePatch("STAUNT_BG"), V_30TRANS)
	local dist = R_PointToDist2(0,0, taunt.x,taunt.y)
	local TAUNTS = SOAP_TAUNTS[skins[p.skin].name]
	local avail = #TAUNTS
	local angstep = FixedDiv(360*FU, avail*FU)
	for i = 0, avail - 1
		local ang = ANGLE_MAX - FixedAngle(angstep * i)
		v.drawScaled(160*FU,100*FU, FU/2,
			v.getSpritePatch(SPR_SOAP_GFX, 53, 0, ang),
			0
		)
		ang = ($ - ANGLE_90) + ANGLE_180 - FixedAngle(angstep / 2)
		
		if (TAUNTS[i + 1].drawer ~= nil)
			TAUNTS[i + 1].drawer(v, i,
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				(dist >= wheel_start) and (taunt.pointing == i)
			)
		else
			v.drawScaled(
				160*FU + P_ReturnThrustX(nil, ang, wheel_inner),
				100*FU - P_ReturnThrustY(nil, ang, wheel_inner),
				FU/4,
				v.cachePatch("MISSING"),
				0
			)
		end
	end
	
	v.dointerp(1000)
	v.drawScaled(
		(160*FU) + taunt.x, --P_ReturnThrustX(nil,taunt.angle<<16, radius),
		(100*FU) - taunt.y, --P_ReturnThrustY(nil,taunt.aim<<16, radius),
		FU/4, v.cachePatch((dist >= wheel_start) and "ML_RBLX_POINT" or "ML_RBLX_CURS"),
		0
	)
	v.dointerp(false)
	
	if (dist >= wheel_start)
		local taunt_t = TAUNTS[taunt.pointing + 1]
		if taunt_t
			v.drawString(160*FU, 100*FU + (wheel_radius + 5*FU),
				taunt_t.name, V_ALLOWLOWERCASE|V_YELLOWMAP,
				"thin-fixed-center"
			)
		end
	end
	
	v.drawString(160*FU, 100*FU - (wheel_radius + 10*FU),
		"Pick a taunt!", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 20*FU),
		"[JUMP/FIRE] - Select", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 28*FU),
		"[SPIN] - Cancel", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
end,"game")
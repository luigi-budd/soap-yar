-- The taunt wheel is shared by both characters, and is sorta complicated
-- so it gets its own file.
local CV = SOAP_CV

local GPAD_A = 256 + 8
local GPAD_B = GPAD_A + 1
local GPAD_X = GPAD_A + 2
local GPAD_Y = GPAD_A + 3

local GPAD_LBUMPER = GPAD_A + 4
local GPAD_RBUMPER = GPAD_A + 5

local GPAD_LCENTER = GPAD_A + 6
local GPAD_RCENTER = GPAD_A + 7

local GPAD_LSTICK = GPAD_A + 8
local GPAD_RSTICK = GPAD_A + 9

local GPAD_DUP = 296
local GPAD_DDOWN = 296 + 1
local GPAD_DLEFT = 296 + 2
local GPAD_DRIGHT = 296 + 3

local gpbuttonnames = {
	[GPAD_A] = "A",
	[GPAD_B] = "B",
	[GPAD_X] = "X",
	[GPAD_Y] = "Y",

	[GPAD_LBUMPER] = "Left Bumper",
	[GPAD_RBUMPER] = "Right Bumper",

	[GPAD_LCENTER] = "Select",
	[GPAD_RCENTER] = "Start",

	[GPAD_LSTICK] = "Left Stick",
	[GPAD_RSTICK] = "Right Stick",

	[GPAD_DUP] = "D-Pad Up",
	[GPAD_DDOWN] = "D-Pad Down",
	[GPAD_DLEFT] = "D-Pad Left",
	[GPAD_DRIGHT] = "D-Pad Right",
}

local TAUNT_ANIM = TR
local taunt_cmd = {
	active = false,
	closed = false, -- keeps ignoregameinputs on for a tic
	x = 0,
	y = 0,
	pointing = -1,
	buttons = 0,
	joystick = false,
	joy_spin = false,
	joy_fire = false,
	
	forward = 0,
	side = 0,
	
	animation = 0,
}

local function CheckTauntAvail(p, checkactive)
	if gamestate ~= GS_LEVEL then return false; end
	if not (p and p.valid) then return false; end
	if p.spectator then return false; end
	local soap = p.soaptable
	if not soap then return false; end
	local taunt = soap.taunt
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return false; end
	local me = p.realmo
	if not (me and me.valid) then return false; end
	
	local noabil_taunt = (skins[p.skin].name == TAKIS_SKIN) and NOABIL_TAUNTS or SNOABIL_TAUNTS
	if (p.panim == PA_IDLE or p.panim == PA_RUN or soap.accspeed <= 5*FU)
	and (P_IsObjectOnGround(me))
	and not ((taunt.active or taunt.tics) and checkactive)
	and me.health
	and (soap.notCarried)
	and not (soap.noability & noabil_taunt == noabil_taunt and checkactive)
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
	taunt_cmd.closed = false
	input.ignoregameinputs = true
end
local function StopMenu()
	if not taunt_cmd.active then return end
	taunt_cmd.active = false
	taunt_cmd.x = 0
	taunt_cmd.y = 0
	taunt_cmd.selected = -1
	taunt_cmd.closed = true
	input.ignoregameinputs = false
end
local function TauntWarning()
	S_StartSoundAtVolume(nil, sfx_sp_cnt, 255 / 2)
	taunt_cmd.animation = TAUNT_ANIM
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
	
	if me.soap_tauntforcecancel
		me.soap_tauntforcecancel = nil
		cancel = true
	end
	
	-- special case
	if (gametype == GT_ZE2)
	and (me.sprite2 == SPR2_ROLL)
		cancel = true
	end
	
	return cancel
end

local sixseven_callback = function(spark)
	spark.tics = 25
	spark.fuse = 25
	spark.type = MT_SOAP_WALLBUMP
	spark.sixseveneffect = true
	spark.frame = A
	spark.sprite = SPR_SOAP_GFX
	spark.frame = 34|FF_PAPERSPRITE|FF_ADD
	spark.momz = 0
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	P_ThrustEvenIn2D(spark, spark.angle - ANGLE_90, 8*FU)
end
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
			spark.drawonlyforplayer = me.player
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

rawset(_G, "SOAP_TAUNTS", {})
SOAP_TAUNTS[SOAP_SKIN] = {
	[1] = {
		name = "Flex",
		
		run = function(p, me, soap, taunt)
			S_StartSound(me, (me.skin == TAKIS_SKIN) and sfx_tk_whp or sfx_flex)
			me.state = S_PLAY_SOAP_FLEX
			soap.stasistic = TR
			if (me.skin == TAKIS_SKIN)
				soap.stasistic = $ / 2
				me.tics = $ / 2
			end
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
					
					if Soap_IsLocalPlayer(p)
						Soap_StartQuake(6*FU, TR/2)
						P_FlashPal(p, PAL_INVERT, 4)
					end
				elseif Soap_IsLocalPlayer(p)
					Soap_StartQuake(FU, TR/6)
				end
				S_StartSound(me,sound)
			end
			taunt.tics = soap.stasistic
			
			me.momx,me.momy = p.cmomx,p.cmomy
		end,
		postthink = function(p, me, soap, taunt)
			local angle = (p.cmd.angleturn << 16)
			if soap.in2D then angle = ANGLE_90 end
			
			p.drawangle = angle + ANGLE_180
		end,
		drawer = function(v,i, x,y, selected)
			local istakis = skins[consoleplayer.skin].name == TAKIS_SKIN
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = istakis and SPR2_WAIT or SPR2_APOS,
				frame = istakis and D or A, angle = 1
			}, selected)
		end,
	},
	[3] = {
		name = "Death",
		cancelable = true,
		
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
			or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
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
		cancelable = true,
		
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
		name = "Six-Seven",
		cancelable = true,
		
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
			or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
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
		canceled = function(p,me,soap)
			me.sixseveeeen = nil
			me.sixsev_adjust = nil
			me.sixsev_super = nil
			
			me.colorized = false
		end
	},
	[6] = {
		name = "Punch",
		
		run = function(p, me, soap, taunt)
			if (CV.tauntinterference.value == 0)
			and Soap_IsCompGamemode()
				CONS_Printf(p, "Can't use this taunt in this gamemode!")
				S_StartSound(nil, sfx_shldls, p)
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
								if (gametype == GT_ZE2)
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
			
		end,
		postthink = function(p, me, soap, taunt)
			if me.tempangle == nil then return end
			p.drawangle = me.tempangle --+ FixedAngle(36*FU * me.punchwindup)
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_MSC6,
				frame = A, angle = 1
			}, selected)
		end,
	},
	[7] = {
		name = "Gangnam Style",
		cancelable = true,
		
		run = function(p, me, soap, taunt)
			me.state = S_PLAY_SOAP_GANGNAM
			
			soap.stasistic = max($, 2)
			taunt.tics = 2
			if Soap_IsLocalPlayer(p)
			and CV.boomboxsfx.value
				S_FadeMusic(0, MUSICRATE/4, p)
			end
			
			me.momx,me.momy = p.cmomx,p.cmomy
			me.temptics = 0
		end,
		think = function(p, me, soap, taunt)
			if cancelConds(p)
			or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
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
				and (displayplayer and displayplayer.valid)
					dontplay = (p ~= displayplayer)
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
		end,
		drawer = function(v,i, x,y, selected)
			chardrawer(v,i, x,y, {
				skin = skins[consoleplayer.skin].name,
				spr2 = SPR2_CLNG,
				frame = (skins[consoleplayer.skin].name == SOAP_SKIN) and C or A, angle = 0
			}, selected)
		end,
		canceled = function(p, me, soap, taunt)
			S_StopSoundByID(me, sfx_sp_em3)
			S_StopSoundByID(me, sfx_sp_em4)
			if Soap_IsLocalPlayer(p)
				S_FadeMusic(100, MUSICRATE/4, p)
			end
		end
	},
}
SOAP_TAUNTS[TAKIS_SKIN] = {
	[1] = {
		name = "Smugness",
		run = SOAP_TAUNTS[SOAP_SKIN][1].run,
		think = SOAP_TAUNTS[SOAP_SKIN][1].think,
		drawer = SOAP_TAUNTS[SOAP_SKIN][1].drawer,
	},
	[2] = {
		name = "Oooomagawd",
		run = SOAP_TAUNTS[SOAP_SKIN][2].run,
		think = SOAP_TAUNTS[SOAP_SKIN][2].think,
		drawer = SOAP_TAUNTS[SOAP_SKIN][2].drawer,
	},
	[3] = SOAP_TAUNTS[SOAP_SKIN][3],
	[4] = {
		name = "Surfin' Bird",
		cancelable = true,
		
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
	[6] = {
		name = "Caramelldansen",
		cancelable = true,
		run = SOAP_TAUNTS[SOAP_SKIN][7].run,
		think = SOAP_TAUNTS[SOAP_SKIN][7].think,
		drawer = SOAP_TAUNTS[SOAP_SKIN][7].drawer,
		canceled = SOAP_TAUNTS[SOAP_SKIN][7].canceled,
	},
}

local cmd_sig = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) cmd_sig = n($); end)

COM_AddCommand("_soap_dotaunt",function(p, sig, selected)
	if sig ~= cmd_sig then return end
	if not CheckTauntAvail(p, false) then return end
	selected = tonumber($)
	
	local soap = p.soaptable
	local me = p.realmo
	local taunt = soap.taunt
	
	local prevnum = taunt.num
	local taunt_t = SOAP_TAUNTS[me.skin][selected + 1]
	if not taunt_t then return end
	
	if (taunt.active or taunt.tics) and prevnum == selected + 1
	and taunt_t.cancelable
		me.soap_tauntforcecancel = true
		return
	end
	
	if CheckTauntAvail(p, true)
		taunt.num = selected + 1
		taunt.prev = taunt.num
		
		taunt_t.run(p, me, soap, taunt)
	else
		return
	end
	
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
local numberkey = -1

local leftjoystick = {
	x = 0, y = 0
}
local rightjoystick = {
	x = 0, y = 0
}

local function CheckNoAbil(allowtaunting)
	local p = consoleplayer
	local noabil_taunt = (skins[p.skin].name == TAKIS_SKIN) and NOABIL_TAUNTS or SNOABIL_TAUNTS
	
	if (p.soaptable.noability & noabil_taunt)
	and not ((p.soaptable.taunt.active or p.soaptable.taunt.tics) and allowtaunting)
		return true
	end
	return false
end

addHook("KeyDown", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	
	local kname = key.name:lower()
	
	if kname == CV.taunt_key.string:lower()
	and (skins[consoleplayer.skin].name == SOAP_SKIN or skins[consoleplayer.skin].name == TAKIS_SKIN)
		local menuactive = MenuLib.client.currentMenu.id ~= -1
		
		if taunt_cmd.active
		and (consoleplayer.soaptable and consoleplayer.soaptable.taunt.prev > 0)
			COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..(consoleplayer.soaptable.taunt.prev - 1))
			StopMenu()
			return true
		elseif not (menuactive or consoleplayer.spectator) and not CheckNoAbil(true)
			StartMenu()
			return true
		elseif CheckNoAbil(true)
			TauntWarning()
		end
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
	
	-- number keys can select taunts as well
	if tonumber(key.name) ~= nil
	and taunt_cmd.active
		local knum = tonumber(key.name)
		if knum == 0 then knum = 10; end -- if we ever have 10 taunts
		
		numberkey = knum - 1
		return true
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

local TICCMD_RECIEVED = 1
local KEY_JOY1 = KEY_JOY1 or ((KEY_MOUSE1 or 256) + (MOUSEBUTTONS or 8))
local gp_waskeydown = false
addHook("PlayerCmd",function(p,cmd)
	leftjoystick.x = input.joyAxis(JA_STRAFE)
	leftjoystick.y = input.joyAxis(JA_MOVE)
	
	rightjoystick.x = input.joyAxis(JA_TURN)
	rightjoystick.y = -input.joyAxis(JA_LOOK)
	
	taunt_cmd.joy_spin = false
	taunt_cmd.joy_fire = false
	
	local gamepad_tb = CV.taunt_button.value
	if (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN)
	and (gamepad_tb > GPAD_A) and (gamekeydown[gamepad_tb] and not gp_waskeydown)
		local menuactive = MenuLib.client.currentMenu.id ~= -1
		
		if taunt_cmd.active
		and (p.soaptable and p.soaptable.taunt.prev > 0)
			COM_BufInsertText(p, "_soap_dotaunt "..cmd_sig.." "..(p.soaptable.taunt.prev - 1))
			StopMenu()
		elseif not (menuactive or p.spectator) and not CheckNoAbil(true)
			StartMenu()
			taunt_cmd.joystick = true
		elseif CheckNoAbil(true)
			TauntWarning()
		end
	end
	gp_waskeydown = gamekeydown[gamepad_tb]
	
	if not (taunt_cmd.active or taunt_cmd.closed) then return end
	
	-- EAT SHIT AND DIE FUCK YOU GAME
	-- im gonna cry
	do -- gamepad buttons
		local spin1, spin2 = input.gameControlToKeyNum(GC_SPIN)
		local fire1, fire2 = input.gameControlToKeyNum(GC_FIRE)
		local spinaxis = input.joyAxis(JA_SPIN)
		local fireaxis = input.joyAxis(JA_FIRE)
		
		if ((spin1 > KEY_JOY1) and gamekeydown[spin1])
		or ((spin2 > KEY_JOY1) and gamekeydown[spin2])
		or (spinaxis > 0)
			taunt_cmd.joy_spin = true
		end

		if ((fire1 > KEY_JOY1) and gamekeydown[fire1])
		or ((fire2 > KEY_JOY1) and gamekeydown[fire2])
		or (fireaxis > 0)
			taunt_cmd.joy_fire = true
		end
	end
	
	input.ignoregameinputs = true
	
	cmd.forwardmove = 0
	cmd.sidemove = 0
	cmd.buttons = 0
	cmd.angleturn = p.cmd.angleturn &~TICCMD_RECIEVED -- this game drives me insane
	cmd.aiming = p.cmd.aiming
end)

local DEADZONE = 32
local function JoystickActive(stick)
	if abs(stick.x) > DEADZONE or abs(stick.y) > DEADZONE
		return true
	end
	return false
end

local function ClientTauntHandle(p)
	local soap = p.soaptable
	local me = p.realmo
	local cmd = p.cmd
	
	if not taunt_cmd.active then return end
	input.ignoregameinputs = true
	
	-- nice one asshole
	if SOAP_TAUNTS[me.skin] == nil
	or CheckNoAbil(false)
		StopMenu()
		if CheckNoAbil(false) then TauntWarning(); end
		return
	end
	
	if MenuLib.client.currentMenu.id ~= -1
		MenuLib.initMenu(-2)
		input.ignoregameinputs = true
	end
	
	if (taunt_cmd.buttons & BT_SPIN) or taunt_cmd.joy_spin
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
	
	if taunt_cmd.joystick
		taunt_cmd.x = $ / 4
		taunt_cmd.y = $ / 4
		if (mouse.dx or mouse.dy)
			taunt_cmd.joystick = false
		end
	end
	if JoystickActive(leftjoystick) or JoystickActive(rightjoystick)
		local stick = leftjoystick
		if JoystickActive(rightjoystick)
			stick = rightjoystick
		end
		
		local maxmove = JOYAXISRANGE*FU
		local move = Vec2.New(
			FixedDiv(stick.x*FU, maxmove), 
			FixedDiv(stick.y*FU, maxmove)
		)
		local force = min(FixedHypot(move.x, move.y), FU)
		local ang = R_PointToAngle2(0,0, stick.x*FU,-stick.y*FU)
		taunt_cmd.x = P_ReturnThrustX(nil,ang, FixedMul(wheel_radius*3/4, force))
		taunt_cmd.y = P_ReturnThrustY(nil,ang, FixedMul(wheel_radius*3/4, force))
		dist = R_PointToDist2(0,0, taunt_cmd.x,taunt_cmd.y)
		
		taunt_cmd.joystick = true
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
	
	if (taunt_cmd.buttons & (BT_ATTACK))
	or (mouse.buttons & MB_BUTTON1)
	or (taunt_cmd.joy_fire)
	and (dist >= wheel_start)
	or (numberkey > -1)
		if numberkey > -1 then selected = numberkey; end
		COM_BufInsertText(consoleplayer, "_soap_dotaunt "..cmd_sig.." "..selected)
		StopMenu()
	end
	numberkey = -1
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
		or (me.state >= S_PLAY_SUPER_TRANS1 and me.state <= S_PLAY_SUPER_TRANS6)
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

addHook("PostThinkFrame",do
	if not (taunt_cmd.active or taunt_cmd.closed) then return end
	input.ignoregameinputs = false
	
	taunt_cmd.closed = false
end)

-- its just easier to handle the hud here
local wheel_inner = wheel_start + (wheel_radius - wheel_start)/2
addHook("HUD",function(v,p)
	-- bruh
	p = consoleplayer
	if not (p and p.valid) then return end -- DEMOSSSSSS. UGH.
	
	local soap = p.soaptable
	if not soap then return end
	if not (skins[p.skin].name == SOAP_SKIN or skins[p.skin].name == TAKIS_SKIN) then return end
	local hud = soap.hud
	local taunt = taunt_cmd
	
	if taunt_cmd.animation
		local x = 160
		local cmap = 0
		if taunt_cmd.animation > TAUNT_ANIM - 10
			x = $ + (taunt_cmd.animation % 2 and 1 or -1)
			cmap = (taunt_cmd.animation % 2 and V_REDMAP or 0)
		end
		
		v.draw(x, 140, v.cachePatch("STAUNT_CNTBG"), V_SNAPTOBOTTOM|V_30TRANS)
		v.draw(x - 42, 139, v.cachePatch("STAUNT_ERR"), V_SNAPTOBOTTOM, v.getStringColormap(V_REDMAP))
		v.drawString(x + 6, 140,
			"Can't use taunts.", V_ALLOWLOWERCASE|V_SNAPTOBOTTOM|cmap,
			"thin-center"
		)
		
		taunt_cmd.animation = $ - 1
	end
	
	if not taunt.active then return end
	
	v.drawScaled(160*FU,100*FU, FU/2, v.cachePatch("STAUNT_BG"), V_30TRANS)
	local dist = R_PointToDist2(0,0, taunt.x,taunt.y)
	local TAUNTS = SOAP_TAUNTS[skins[p.skin].name]
	local avail = #TAUNTS
	local angstep = FixedDiv(360*FU, avail*FU)
	for i = 0, avail - 1
		local ang = ANGLE_MAX - FixedAngle(angstep * i)
		v.drawScaled(160*FU,100*FU, FU/2,
			v.getSpritePatch(SPR_SOAP_GFX, 25, 0, ang),
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
		FU/4, v.cachePatch((dist >= wheel_start) and (taunt_cmd.joystick and "STAUNT_GPOINT" or "ML_RBLX_POINT") or (taunt_cmd.joystick and "STAUNT_GCUR" or "ML_RBLX_CURS")),
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
		"[FIRE] - Select", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	v.drawString(160*FU, 100*FU + (wheel_radius + 28*FU),
		"[SPIN] - Cancel", V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
end,"game")
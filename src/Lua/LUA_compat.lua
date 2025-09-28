local compat = {
	takiskart = false,
	battlemod = false,
	ptsrhook = false,
	heist = false,
	mrce = false,
	ze2config = false,
	--solform = false,
	mmportrait = false,
	orbitcompat = false,
	rsr = false,
}
local compat_names = {
	["takiskart"]	= "TakisKart        ",
	["battlemod"]	= "BattleMoveset    ",
	["ptsrhook"]	= "PTSR Hooks       ",
	["heist"]		= "Fang's Heist set ",
	["mrce"]		= "MRCE Compat.     ",
	["ze2config"]	= "ZE2 Config.      ",
	--["solform"]		= "Sol Form     ",
	["ze2config"]	= "ZE2 Config.      ",
	["mmportrait"]	= "EPIC!MM support  ",
	["orbitcompat"] = "Orbit Compat.    ",
	["rsr"]			= "RingSlinger Neo  ",
}

local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SPINDUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end

local function printf(...)
	
	local texts = {...}
	for k,v in ipairs(texts)
		print("\x83SOAP:\x80 "..v)
	end
	
	/*
	if not TAKIS_ISDEBUG then return end
	Tprtable("compat",compat)
	*/
end

local function SetCompat()
	if TakisKart_Karters
	and not compat.takiskart
		TakisKart_Karters[SOAP_SKIN] = true
		
		TakisKart_KarterData[SOAP_SKIN] = {
			basenormalspeed = 43,
			stats = {9,7},
			nolookback = true,
			legacyframes = true
		}
		if not TakisKart_Karters[TAKIS_SKIN]
			TakisKart_Karters[TAKIS_SKIN] = true
			TakisKart_KarterData[TAKIS_SKIN] = {
				basenormalspeed = 43,
				
				--speed,weight
				stats = {9,4},
				
				nolookback = true,
				takiskart = true,
				legacyframes = true,
			}
		end
		compat.takiskart = true
		printf("Added TakisKart stuff.")
	end
	
	if (CBW_Battle and CBW_Battle.SkinVars)
	and not compat.battlemod
		local B = CBW_Battle
		
		local function FakeExhaust(p, me, sweatonly)
			local soap = p.soaptable
			local sweatheight = FixedDiv(me.height, me.scale) * 3/2
			if not (leveltime & 7)
			and not (p.sweatobj and p.sweatobj.valid)
				if not sweatonly
					S_StartSound(me, sfx_s3kbb, p)
				end
				local sweat = P_SpawnMobjFromMobj(me, 0, 0, sweatheight, MT_THOK) --we got a local sweat in our area
				sweat.spritexoffset = $ - FixedDiv(me.radius,me.scale)*2
				sweat.state = S_SWEAT
				sweat.target = me
				B.InstaFlip(sweat)
				p.sweatobj = sweat
			end
			if (p.sweatobj and p.sweatobj.valid)
				local s = p.sweatobj
				B.InstaFlip(s)
				P_MoveOrigin(s,
					me.x + me.momx,
					me.y + me.momy,
					me.z + FixedMul(sweatheight, me.scale) + (soap.gravflip == -1 and
						me.height - s.height
					or 0)
				)
			end
			
			if not sweatonly
				if (leveltime&4)
					if me.soap_exclr == nil
						me.soap_exclr = me.color
					end
					me.color = SKINCOLOR_BRONZE
					me.colorized = true
				elseif me.soap_exclr ~= nil
					me.color = me.soap_exclr
					me.colorized = false
					me.soap_exclr = nil
				end
			elseif me.soap_exclr ~= nil
				me.color = me.soap_exclr
				me.colorized = false
				me.soap_exclr = nil
			end
			
			me.soap_exhaust = true
		end
		
		--returning true sets secondary stats (sourspot, in this case)
		B.AddPriorityFunction("soap_uppercut", function(me, mo)
			--youre only every going up while uppercutting
			if abs(me.momz) <= -3 * me.scale
				--about to fall, hit a sour spot
				return true
			end
			--full power!
			return false
		end)
		
		--also using this as a secondary playerthink lol
		local function Priority(p)
			local me = p.mo
			local soap = p.soaptable
			
			local setexhaust = false
			local exhausttimer = false
			
			if me.soap_poundcount == nil then me.soap_poundcount = 0; end
			if me.soap_adashcount == nil then me.soap_adashcount = 0; end
			
			if (soap.pounding)
				me.soap_poundtime = $ + 1
				local stale = false
				--fall faster lol
				if (me.soap_poundcount < 3)
					me.momz = $ + P_GetMobjGravity(me)
				--fall slower lol
				else
					if me.soap_poundtime > TR
						soap.pounding = false
						S_StartSound(me, sfx_s3k51)
						p.pflags = $|PF_NOJUMPDAMAGE
						me.state = S_PLAY_FALL
						me.soap_poundtimedout = true
					end
					
					local terminal = (-20 + me.soap_poundcount)*me.scale
					me.momz = $ - P_GetMobjGravity(me)
					if (me.momz*soap.gravflip < terminal)
						me.momz = terminal * soap.gravflip
					end
					stale = true
					
					FakeExhaust(p,me)
					setexhaust = true
				end
				
				B.SetPriority(p,
					--at least pierce spin jumps
					(stale and 1 or 2), 1,
					"fang_tailbounce",
					--sweet spot
					(stale and 2 or 3), (stale and 2 or 3),
					"pound"
				)
				
				return
			elseif soap.onGround
				if (me.soap_poundstale)
					me.soap_poundstale = $ - 1
					exhausttimer = true
				else
					me.soap_poundcount = 0
				end
				if me.soap_poundtimedout
					soap.pound_cooldown = $ + TR*3/2
					me.soap_poundtimedout = nil
				end
			elseif (me.soap_poundstale)
			and (me.soap_poundcount >= 3)
				exhausttimer = true
			end
			
			if not soap.pounding
				me.soap_poundtime = 0
			end
			
			--uppercut
			if soap.uppercutted
			and (me.momz*soap.gravflip > 0)
			and (me.sprite2 == SPR2_MLEE)
				B.SetPriority(p, 2, 1, "soap_uppercut",
					--sour spot
					1, 1,
					"Uppercut"
				)
				return
			end
			if me.soap_cutted
			and soap.onGround
				soap.uppercut_cooldown = TR/2
				me.soap_cutted = nil
			end
			
			if (soap.toptics
			and not soap.topwindup)
			and soap.topspin ~= false
				B.SetPriority(p, 2, 2, "can_damage",
					--no sour spot
					2, 2,
					"Spinning Top"
				)
			end
			
			if (soap.rdashing or soap.airdashed)
			and (me.state == S_PLAY_DASH or me.state == S_PLAY_FLOAT_RUN)
				local attack = 1
				local defense = 1
				local stale = (me.soap_adashcount > 2)
				
				if (soap.rdashing and me.state == S_PLAY_DASH)
				and (soap.accspeed >= 45*FU)
					attack = 2
				end
				if soap.airdashed
					if me.soap_airdashsweet
					and not stale
						attack = 2
					end
					if stale
						defense = 0
						FakeExhaust(p,me)
						setexhaust = true
						
						local maxspeed = (30 - (me.soap_adashcount * 2)) * me.scale
						maxspeed = max($, 5 * me.scale)
						if (p.speed > maxspeed)
							local div = 4 * FU
							
							local newspeed = p.speed - FixedDiv(p.speed - maxspeed,div)
							me.momx = FixedMul(FixedDiv(me.momx, p.speed), newspeed)
							me.momy = FixedMul(FixedDiv(me.momy, p.speed), newspeed)
						end
					end
				end
				
				B.SetPriority(p, 1, 1, "knuckles_glide",
					--sweet spot
					attack, defense,
					soap.airdashed and "B-Rush" or "R-Dash"
				)
				return
			elseif soap.onGround
				if (me.soap_adashstale)
					me.soap_adashstale = $ - 1
					exhausttimer = true
				else
					me.soap_adashcount = 0
				end
			elseif (me.soap_adashstale)
			and (me.soap_adashcount > 2)
				exhausttimer = true
			end
			
			if me.soap_airdashsweet then me.soap_airdashsweet = $ - 1; end
			
			if not setexhaust
				if me.soap_exhaust
					me.soap_exhaust = nil
					if (me.soap_exclr ~= nil)
						me.color = me.soap_exclr
						me.colorized = false
						me.soap_exclr = nil
					end
				end
				
				if exhausttimer
					FakeExhaust(p,me,true)
				end
			end
			
			--Bruh();
			if not (me.beingsucked)
			and me.soap_oldsucked
				p.actionstate = 0
			end
			
			if me.soap_spikevfx
				local range = 22
				do
					local color = G_GametypeHasTeams() and ((p.ctfteam == 1 and skincolor_redteam or skincolor_bluering)) or p.skincolor
					local spark = P_SpawnMobjFromMobj(me,
						Soap_RandomFixedRange(-range,range),
						Soap_RandomFixedRange(-range,range),
						Soap_RandomFixedRange(0,range),
						MT_WATERZAP
					)
					spark.spritexscale = FU*7
					spark.spriteyscale = FU*4
					local ha,va = R_PointTo3DAngles(spark.x,spark.y,spark.z, me.x,me.y,me.z)
					P_3DThrust(spark, ha,va, -P_RandomRange(10,15)*me.scale)
					spark.blendmode = AST_ADD
					spark.renderflags = $|RF_FULLBRIGHT|RF_PAPERSPRITE
					spark.colorized = true
					spark.color = color
					spark.angle = ha
					spark.momx = $ + me.momx
					spark.momy = $ + me.momy
					spark.momz = $ + soap.rmomz
					
					--top sparks
					local angle = FixedAngle(Soap_RandomFixedRange(0,360))
					local rad = FixedDiv(me.radius,me.scale)
					local hei = FixedDiv(me.height,me.scale)
					spark = P_SpawnMobjFromMobj(me,
						P_ReturnThrustX(nil,angle,rad),
						P_ReturnThrustY(nil,angle,rad),
						(hei/2) + Soap_RandomFixedRange(-17,17), MT_SOAP_SPARK
					)
					spark.color = color
					spark.adjust_angle = angle
					spark.angle = spark.adjust_angle
					spark.target = me
					local ha,va = R_PointTo3DAngles(spark.x,spark.y,spark.z, me.x,me.y,me.z)
					spark.rollangle = va
					
					spark.spritexscale = FU/3 + P_RandomRange(0, FU/2)
					spark.spriteyscale = FU/2
					spark.renderflags = $|(spark.z <= me.z+(hei/2) and RF_VERTICALFLIP or 0)
					spark.momx = $ + me.momx
					spark.momy = $ + me.momy
					spark.momz = $ + soap.rmomz
				end
				me.soap_spikevfx = $ - 1
			end
			
			if (soap.fire == 1)
			and (p.guard ~= 0)
			and not me.soap_grabcooldown
				if not Soap_GrabHitbox(p)
					if (me.health)
					and not p.tumble
						B.DoPlayerFlinch(p,
							TR*3/2, p.drawangle,
							-3 * me.scale,
							false
						)
					end
					me.soap_grabcooldown = TR*3/2
				end
				p.guard = 0
			end
			
			me.soap_oldsucked = me.beingsucked
		end
		
		Takis_Hook.addHook("Soap_OnMove", function(p, move, var1)
			local soap = p.soaptable
			local me = p.mo
			
			if not soap.inBattle then return end
			
			if move == "airdash"
				me.soap_airdashsweet = 11
				me.soap_adashcount = $ + 1
				me.soap_adashstale = TR * 5/4
			elseif move == "uppercut"
				me.soap_cutted = true
			elseif move == "pound"
				me.soap_poundcount = $ + 1
				me.soap_poundstale = TR * 3/2
			elseif move == "poundland"
				me.soap_noairdash = soap.bm.lockmove + TR/2
				return max(var1, 155*me.scale)
			end
		end)
		Takis_Hook.addHook("Soap_NoAbility", function(p, nb)
			local soap = p.soaptable
			local me = p.realmo
			
			if not (me and me.valid) then return end
			if not soap.inBattle then return end
			
			local na = nb
			if p.armachargeup
				na = $|SNOABIL_ALL
			end
			if soap.uppercutted
				na = $|SNOABIL_POUND
			end
			if me.soap_noairdash
				na = $|SNOABIL_AIRDASH
				me.soap_noairdash = $ - 1
			end
			
			--no easy recoveries, sorry
			if not soap.onGround
			and not (p.pflags & PF_JUMPED)
				na = $|SNOABIL_UPPERCUT
			end
			
			return na
		end)
		
		B.SkinVars[SOAP_SKIN] = {
			flags = SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
			weight = 125,
			shields = 1,
			guard_frame = 1,
			--special = Shotgunify,
			func_priority_ext = Priority,
			special = function(me,doaction)
				local p = me.player
				local soap = p.soaptable
				
				p.actiontext = "Spinning Top"
				p.actionrings = 10
				p.actionsuper = true
				
				if doaction == 1
					if p.rings < p.actionrings
						S_StartSound(nil, sfx_s3k8c, p)
						return
					end
					
					B.PayRings(p)
					B.ApplyCooldown(p, SOAP_TOPCOOLDOWN)
					
					SoapST_Start(p)
					Soap_DustRing(me,
						dust_type(me),
						16,
						{me.x,me.y,me.z},
						me.radius,
						16*me.scale,
						me.scale/2,
						me.scale,
						false, dust_noviewmobj
					)
					
				end
			end,
			func_precollide = function(
				n1,n2, play, mobjs,
				attacks, defenses, weights,
				hurt, pains, grounded, thrusts, thrusts2,
				colltype
			)
				local p = play[n1]
				local p2 = play[n2]
				if not (p2 and p2.valid) then return end
				local me = p.mo
				local mo = p2.mo
				local soap = p.soaptable
				local soap2 = p2.soaptable
				
				--store which moves we were doing for the postcollide
				--formatting here is immaculate (maybe)
				me.soap_bm_moves = {
					uppercut	=	(soap.uppercutted
									and (me.momz*soap.gravflip > 0)
									and (me.sprite2 == SPR2_MLEE)),
					pound		=	soap.pounding,
					rush		= 	((soap.rdashing or soap.airdashed)
									and (me.state == S_PLAY_DASH or me.state == S_PLAY_FLOAT_RUN)),
					momz		=	me.momz,
					damaged		=	false,
					power		=	FU,
					basepower	=	5*FU,
				}
			end,
			func_collide = function(
				n1,n2, play, mobjs,
				attacks, defenses, weights,
				hurt, pains, grounded, thrusts, thrusts2,
				colltype
			)
				local p = play[n1]
				local p2 = play[n2]
				if not (p2 and p2.valid) then return end
				local me = p.mo
				local mo = p2.mo
				local soap = p.soaptable
				local soap2 = p2.soaptable
				local last = me.soap_bm_moves
				local last2 = mo.soap_bm_moves
				local nodamage = false
				
				if soap.bm.intangible
					return true
				end
				
				if last.pound
				and defenses[n2] < attacks[n1]
				and (p2.guard == 0)
					--if grounded, launch up maybe for a combo
					if grounded[n2]
						Soap_ZLaunch(mo, 14*me.scale)
						
						if (B.PriorityFunction[p.battle_sfunc](me,mo))
							S_StartSound(mo, sfx_sp_db4)
						end
					--Spike!
					else
						--super-resetplayer
						B.ResetPlayerProperties(p2,false,false)
						P_ResetPlayer(p2)
						
						mo.state = S_PLAY_PAIN
						mo.momz = (-15*mo.scale) + abs(last.momz/2)
						mo.momz = $ * P_MobjFlip(mo)
						
						--onlyy if this is actually a spike
						if (B.PriorityFunction[p.battle_sfunc](me,mo))
							S_StartSound(mo, sfx_sp_db4)
							
							--tooomble
							CBW_Battle.DoPlayerTumble(p2,TR*3/2,
								R_PointToAngle2(me.x,me.y,
									mo.x,mo.y
								), 0
							)
							p2.tumble_nostunbreak = true
							p2.airdodge_spin = 0
							mo.momz = (-23*mo.scale) + abs(last.momz/2)
							mo.momz = $ * P_MobjFlip(mo)
						end
					end
					me.momz = $ / 2
					me.soap_spikevfx = TR/3
					
					last.power = 5*FU + FixedDiv(abs(last.momz),me.scale*3)
					last.basepower = 35*FU
				end
				if last.rush
				and defenses[n2] < attacks[n1]
				and (p2.guard == 0)
					if (p2.pflags & (PF_SPINNING|PF_JUMPED))
						P_ResetPlayer(p2)
						mo.state = S_PLAY_FALL
						p2.pflags = $|PF_NOJUMPDAMAGE &~PF_SPINNING
					end
				end
				
				if hurt == 1
				or hurt == 2
				and not nodamage
					last.damaged = true
				end
			end,
			func_postcollide = function(
				n1,n2, play, mobjs,
				attacks, defenses, weights,
				hurt, pains, grounded, thrusts, thrusts2,
				colltype
			)
				local p = play[n1]
				local p2 = play[n2]
				if not (p2 and p2.valid) then return end
				local me = p.mo
				local mo = p2.mo
				local soap = p.soaptable
				local soap2 = p2.soaptable
				local last = me.soap_bm_moves
				local last2 = mo.soap_bm_moves
				
				if last.pound
					soap.pounding = false
					me.state = S_PLAY_ROLL
					P_SetObjectMomZ(me, 8*FU)
					
					soap.rdashing = false
					soap.airdashed = false
				end
				if last.uppercut
					soap.uppercutted = false
					soap.uppercut_cooldown = TR
					soap.canuppercut = true --?
					me.state = S_PLAY_SPRING
					
					me.momz = last.momz * 4/5
					
					if defenses[n2] < attacks[n1]
					and last.damaged
						P_SetObjectMomZ(mo, 10*FU + last.momz/4)
					end
				end
				
				if last.damaged
					Soap_ImpactVFX(mo, me)
					Soap_DamageSfx(mo, last.power, last.basepower)
					Soap_SpawnBumpSparks(me, mo)
				end
				
				--we're done with this, free it
				me.soap_bm_moves = nil
			end,
			
			/*
			special = Titanium,
			func_precollide = Titanium_PreCollide,
			func_collide = Titanium_Collide,
			func_postcollide = Titanium_PostCollide
			*/
		}
		
		local S = B.SkinVars
		local Act = B.Action
		local G = B.GuardFunc
		
		S[TAKIS_SKIN] = {
			flags = SKINVARS_GUARD|SKINVARS_NOSPINSHIELD|SKINVARS_GUNSLINGER,
			weight = 100,
			special = Act.CombatRoll,
			guard_frame = 1,
			func_priority_ext = Act.CombatRoll_Priority,
			func_precollide = B.Fang_PreCollide,
			func_collide = B.Fang_Collide,
			func_postcollide = B.Fang_PostCollide,
		}
		
		--use priority
		Takis_Hook.addHook("CanPlayerHurtPlayer",function(p1,p2, nobs)
			if (B and B.BattleGametype())
				local soap = p1.soaptable
				
				if not soap.inBattle then return end
				if not nobs then return false; end
				
				if B.MyTeam(p1,p2)
					return false
				end
				
				if ((p2.powers[pw_flashing])
				or (p2.powers[pw_invulnerability])
				or (p2.powers[pw_super]))
					return false
				end
				
				if (p1.botleader == p2)
					return false
				end
				
				if not B.PlayerCanBeDamaged(p2)
					return false
				end
				
				return true
			end
		end)
		
		compat.battlemod = true
		printf("Added BattleMod stuff.")
	end
	
	if (PTSR
	and PTSR_AddHook)
	and not compat.ptsrhook
		
		PTSR_AddHook("pfplayerfind", function(pizza, p)
			if (p.mo and p.mo.valid and p.mo.hitlag)
				return true
			end
		end)
		PTSR_AddHook("pfdamage",function(touch,pizza)
			if not (touch and touch.valid) then return end
			
			if touch.hitlag
				PTSR.DoParry(touch,pizza)
				return true
			end
		end)
		PTSR_AddHook("pfthink",function(pizza)
			if pizza.pizza_target and pizza.pizza_target.valid and pizza.pizza_target.hitlag
				pizza.momx,pizza.momy,pizza.momz = 0,0,0
				pizza.pfstuntime = max($, 2)
				return true
			end
		end)
		
		Takis_Hook.addHook("CanFlingThing",function(pizza)
			return false
		end, MT_PIZZA_ENEMY)
		Takis_Hook.addHook("CanFlingThing",function(pizza)
			return false
		end, MT_PT_JUGGERNAUTCROWN)
		
		local function parry(me,thing)
			if not (me and me.valid) then return end
			if not (thing and thing.valid) then return end
			
			--??? why?
			if not me.health then return end
			if not thing.health then return end
			
			--players only
			if (me.type ~= MT_PLAYER) then return end
			if not (me.player and me.player.valid) then return end
			
			local p = me.player
			local soap = p.soaptable
			
			if not soap then return end
			if me.skin ~= SOAP_SKIN then return end
			
			if thing.type ~= MT_PIZZA_ENEMY then return end
			if not Soap_ZCollide(me,thing) then return end
			if not me.hitlag then return end
			
			PTSR.DoParry(touch,pizza)
		end
		addHook("MobjMoveCollide",parry,MT_PLAYER)
		addHook("MobjCollide",parry,MT_PLAYER)
		
		compat.ptsrhook = true
		printf("Added PTSR stuff.")
	end
	
	if FangsHeist
	and not compat.heist
		local FH = FangsHeist
		
		FH.makeCharacter(SOAP_SKIN, {
			isAttacking = function(self, p)
				return (p.heist.attack_time) or p.mo.state == S_PLAY_MELEE
			end,
			onHit = function(self,p, p2)
				Soap_ImpactVFX(p2.mo, p.mo)
			end,
			
			controls = {
				{
					key = "C1",
					name = "Uppercut",
					cooldown = function(self, p)
						return (p.heist.attack_cooldown or p.soaptable.uppercut_cooldown)
					end,
					visible = function(self, p)
						return not p.heist.blocking
					end
				},
				{
					key = "FIRE",
					name = "Attack",
					cooldown = function(self, p)
						return (p.heist.attack_cooldown)
					end,
					visible = function(self, p)
						return not p.heist.blocking
					end
				},
				{
					key = "FIRE NORMAL",
					name = "Block",
					cooldown = function(self, p)
						return (p.heist.attack_cooldown or p.heist.block_cooldown)
					end,
					visible = function(self, p)
						return true
					end
				}
			}
		})
		
		Takis_Hook.addHook("CanPlayerHurtPlayer",function(p1,p2, nobs)
			if FH.isMode() then
				return false
			end
		end)
		
		Takis_Hook.addHook("Soap_NoAbility",function(p, noabil)
			if not FH.isMode() then return end
			if p.heist.attack_cooldown
				return noabil|SNOABIL_POUND|SNOABIL_AIRDASH
			end
		end)
		
		Takis_Hook.addHook("Soap_OnMove",function(p, move, var1, var2, var3, var4)
			if not FH.isMode() then return end
			local soap = p.soaptable
			local me = p.mo
			
			if move == "uppercut"
				soap.uppercut_cooldown = 70
				p.heist.attack_cooldown = soap.uppercut_cooldown
				
				if FH.isPlayerNerfed(p)
					Soap_ZLaunch(me, 7*FU)
				end
			end
		end)
		
		compat.heist = true
		printf("Added Fang's Heist stuff.")
	end
	
	if mrceCharacterPhysics
	and not compat.mrce
		mrceCharacterPhysics(SOAP_SKIN,
			false,false,0,false
		)
		
		compat.mrce = true
		printf("Added MRCE stuff.")
	end
	
	if ZE2 and (ZE2.AddCharacterConfig ~= nil)
	and not compat.ze2config
		ZE2:AddCharacterConfig(SOAP_SKIN, {
            health = 125,
			charflags = SF_FASTEDGE,
			speed = "normal",
            desc1 = "Kick some zombie ass!",
            desc2 = "And also survive!",
			desc3 = "Hefty and reliable!",
		})
		ZE2:AddCharacterConfig(TAKIS_SKIN, {
			speed = "normal",
			health = 80,
			desc1 = "Ready to blast zombies.",
			desc2 = "Average speed, nothin' special."
		})
		
		compat.ze2config = true
		printf("Added ZE2 stuff.")
	end
	/*
	if solchars
	and not compat.solform
		local color = SKINCOLOR_SUPERSKY1
		if pcall(do return _G[SKINCOLOR_AQUAMARINE1] end)
			color = SKINCOLOR_AQUAMARINE1
		end
		
		solchars[SOAP_SKIN] = {color, 2}
		
		compat.solform = true
		printf("Added Sol forms.")
	end
	*/
	if MM and MM.showdownSprites
	and not compat.mmportraits
		MM.showdownSprites[SOAP_SKIN] = "MMSD_SOAPTH"
		MM.showdownSprites[TAKIS_SKIN] = "MMSD_TAKISTF"
		
		local function novfx()
			if not (MM and MM:isMM()) then return end
			
			return {
				jumpdust = true,
				landdust = true,
			}
		end
		
		Takis_Hook.addHook("Soap_VFX", novfx)
		Takis_Hook.addHook("Takis_VFX", novfx)
		
		MM.addHook("CorpseThink",function(corpse)
			if MM_N.gameover then return end
			local p = players[corpse.playerid]
			if not (p and p.valid) then return end
			local me = p.realmo
			if not (me and me.valid) then return end
			if p.spectator then return end
			if not (me.skin == SOAP_SKIN or me.skin == TAKIS_SKIN) then return end
			
			me.soap_landondeath = false
		end)
		
		compat.mmportraits = true
		printf("Added EPIC!MM stuff.")
	end
	if (skins["orbit"] ~= nil)
	and not compat.orbitcompat
		Takis_Hook.addHook("CanPlayerHurtPlayer",function(p1,p2, nobs)
			if not (p2.mo and p2.mo.valid) then return end
			if skins[p2.skin].name ~= "orbit" then return end
			local o = p2.orbittable
			
			if (o.frozen)
				--p1.soaptable.damagedealtthistic = SOAP_MAXDAMAGETICS
				return false
			end
		end)
		
		compat.orbitcompat = true
		printf("Added Orbit stuff.")
	end
	
	if RSR
	and not compat.rsr
		Takis_Hook.addHook("Char_OnDamage",function(me)
			if not (RSR.GamemodeActive()) then return end
			return true
		end)
		
		local thinker = function(p)
			if not (RSR.GamemodeActive()) then return end
			
			p.realmo.soap_landondeath = nil
		end
		Takis_Hook.addHook("Soap_Thinker",thinker)
		Takis_Hook.addHook("Takis_Thinker",thinker)
		
		compat.rsr = true
		printf("Added RSR stuff.")
	end
end
SetCompat()

addHook("AddonLoaded",SetCompat)
addHook("MapChange",SetCompat)

COM_AddCommand("soap_compatinfo",function(p)
	CONS_Printf(p, "Current Soap compatibles added:")
	for k,v in pairs(compat)
		local name = compat_names[k]
		CONS_Printf(p,"\t\x82"..name.."\x80 : " .. (v and "\x83".."Added" or "\x86Not added"))
	end
end)

Takis_Hook.addHook("CanPlayerHurtPlayer",function(p1,p2, nobs)
	if not (p2.mo and p2.mo.valid) then return end
	if p2.mo.skin == "maverick" then
		P_KillMobj(p2.mo)
		return true
	end
end)

local compat = {
	takiskart = false,
	battlemod = false,
	ptsrhook = false,
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
	["mrce"]		= "MRCE Compat.     ",
	["ze2config"]	= "ZE2 Config.      ",
	--["solform"]		= "Sol Form     ",
	["ze2config"]	= "ZE2 Config.      ",
	["mmportrait"]	= "EPIC!MM support  ",
	["orbitcompat"] = "Orbit Compat.    ",
	["rsr"]			= "RingSlinger Rev. ",
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
			
			--uppercut
			if (me.state == S_PLAY_MELEE)
			and (me.momz*soap.gravflip > 0)
			and (me.sprite2 == SPR2_MLEE)
				B.SetPriority(p, 2, 1, "soap_uppercut",
					--sour spot
					1, 1,
					"Uppercut"
				)
				return
			end
			
			if me.soap_sweeptics
				B.SetPriority(p, 1,1, "can_damage",
					--no sour spot
					1, 1,
					"Sweeping Kick"
				)
			end
			if me.soap_spiketics
				B.SetPriority(p, 2,1, "can_damage",
					--no sour spot
					2, 1,
					"Meteor Knuckle"
				)
			end
			
			if me.soap_sweeptics
				B.SetPriority(p, 1,1, "can_damage",
					--no sour spot
					1, 1,
					"Sweeping Kick"
				)
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
			
			--Bruh();
			if not (me.beingsucked)
			and me.soap_oldsucked
				p.actionstate = 0
			end
			
			/*
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
			*/
			
			me.soap_oldsucked = me.beingsucked
		end
		
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
				and not (soap.noability & SNOABIL_TOP)
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
				
				if me.soap_noguarding
				or (soap.toptics)
					p.canguard = false
					me.soap_noguarding = false
				end
			end,
			--[[
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
							S_StartSound(mo, sfx_sp_dm4)
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
							S_StartSound(mo, sfx_sp_dm4)
							
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
			]]--
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
			flags = SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
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
				
				if (p2.airdodge)
				or (p2.intangible)
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
	
	if mrceCharacterPhysics
	and not compat.mrce
		mrceCharacterPhysics(SOAP_SKIN,
			false,false,0,false
		)
		
		compat.mrce = true
		printf("Added MRCE stuff.")
	end
	
	if ZE2 and (ZE2.AddSurvivor ~= nil)
	and not compat.ze2config
		ZE2.AddSurvivor(SOAP_SKIN, {
            weight = 7,
			description = {
				"Kick some zombie ass!",
				"Hefty and reliable!",
			};
			items = {
				"red_ring",
				"auto_ring"
			};
		})
		ZE2.AddSurvivor(TAKIS_SKIN, {
            weight = 3,
			description = {
				"Ready to blast!",
				"On the lighter side.",
			};
			items = {
				"scatter_ring",
				"red_ring"
			};
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
	if (skins["orbit"] ~= nil) and Orbit
	and not compat.orbitcompat
		Takis_Hook.addHook("CanPlayerHurtPlayer",function(p1,p2, nobs)
			if not (p2.mo and p2.mo.valid) then return end
			if skins[p2.skin].name ~= "orbit" then return end
			
			if not Orbit.Yar --demos 4.37 and before
				local o = p2.orbittable
				
				if (o.frozen)
					--p1.soaptable.damagedealtthistic = SOAP_MAXDAMAGETICS
					return false
				end
			else
				if p2.mo.orbit_frozen
					return false
				end
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

local compat = {
	takiskart = false,
	battlemod = false,
	ptsrhook = false,
	mrce = false,
	ze2config = false,
	mmportrait = false,
	orbitcompat = false,
	rsr = false,
	manhunt = false,
}
local compat_names = {
	["takiskart"]	= "TakisKart        ",
	["battlemod"]	= "BattleMoveset    ",
	["ptsrhook"]	= "PTSR Hooks       ",
	["mrce"]		= "MRCE Compat.     ",
	["ze2config"]	= "ZE2 Config.      ",
	["mmportrait"]	= "EPIC!MM support  ",
	["orbitcompat"] = "Orbit Compat.    ",
	["rsr"]			= "RingSlinger Rev. ",
	["manhunt"]		= "Saxa's Manhunt   ",
}

local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SPINDUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local armacolors = {
	SKINCOLOR_KETCHUP, SKINCOLOR_PEPPER, SKINCOLOR_CRIMSON, SKINCOLOR_GARNET, SKINCOLOR_VOLCANIC
}

local function printnotice(...)
	
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
		printnotice("Added TakisKart stuff.")
	end
	
	if (CBW_Battle and CBW_Battle.SkinVars)
	and not compat.battlemod
		local B = CBW_Battle
		
		--returning true sets secondary stats (sourspot, in this case)
		B.AddPriorityFunction("soap_uppercut", function(me, mo)
			--youre only every going up while uppercutting
			if abs(me.momz) <= 3 * me.scale
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
			
			me.soap_oldsucked = me.beingsucked
		end
		
		B.SkinVars[SOAP_SKIN] = {
			flags = SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
			weight = 125,
			shields = 1,
			guard_frame = 1,
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
				or (me.state == S_PLAY_SOAP_KNOCKOUTDOLL or me.state == S_PLAY_SOAP_KNOCKOUT)
					p.canguard = false
					me.soap_noguarding = false
				end
			end,
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
		printnotice("Added BattleMod stuff.")
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
		printnotice("Added PTSR stuff.")
	end
	
	if mrceCharacterPhysics
	and not compat.mrce
		mrceCharacterPhysics(SOAP_SKIN,
			false,false,0,false
		)
		
		compat.mrce = true
		printnotice("Added MRCE stuff.")
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
				"splash_ring",
			};
		})
		ZE2.AddSurvivor(TAKIS_SKIN, {
            weight = 1,
			description = {
				"Ready to blast!",
				"On the lighter side.",
			};
			items = {
				"bounce_ring",
				"molotov"
			};
		})
		
		Takis_Hook.addHook("Char_VFX",function(p)
			local me = p.mo
			if not (me and me.valid) then return end
			local inze2 = (gametype == GT_ZE2 or (ZE2 and ZE2.isGametype()))
			if not inze2 then return end
			local game = ZE2.Game
			local settings = ZE2.getGametypeSettings()
			
			local shortcircuit = {}
			
			if settings.fall_damage
			and p.ze2.fall_height ~= nil -- lol
				-- no landing effect when fall damage is coming up
				if ((me.soap_oldfalldist or 0) > ZE2.MIN_FALL_DISTANCE)
					shortcircuit.landdust = true
				end
				me.soap_oldfalldist = (p.ze2.fall_height - me.z)
			end
			
			if game.state == ZE2.GS_PREGAME
				shortcircuit.landdust = true
				shortcircuit.squish = true
			end
			
			return shortcircuit
		end)
		Takis_Hook.addHook("Char_OnDeath",function(me, _,_, dmgt)
			local inze2 = (gametype == GT_ZE2 or (ZE2 and ZE2.isGametype()))
			if not inze2 then return end
			if not (dmgt == 6) then return end -- fall damage
			local p = me.player
			local soap = p.soaptable
			
			local rad = FixedDiv(me.radius, me.scale)
			local hei = FixedDiv(me.height, me.scale)
			local extra = abs(FixedDiv(me.momz, 50*me.scale))
			for i = 0, 22
				local s = P_SpawnMobjFromMobj(me,
					Soap_RandomFixedRange(-rad, rad),
					Soap_RandomFixedRange(-rad, rad),
					Soap_RandomFixedRange(0, hei) + 256*FU,
					MT_PARTICLE
				)
				s.state = S_SOAP_IMPACT_LINE2
				if (soap.in2D)
					s.angle = 0
				else
					s.angle = me.angle - ANGLE_90
				end
				s.color = armacolors[P_RandomRange(1, #armacolors)]
				s.rollangle = -ANGLE_90
				s.renderflags = $|RF_ALWAYSONTOP
				s.spriteyscale = $ * 13/10 + extra
				s.flags = $|MF_NOCLIPTHING|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP
				s.takis_flingme = false
				local offset = P_RandomRange(-4, 8)
				s.tics = $ + offset
				s.anim_duration = $ + offset
			end
			
			me.state = S_PLAY_PAIN
			Soap_Hitlag.addHitlag(me, 14, true)
			for k,v in ipairs(soap.squash)
				table.remove(soap.squash, k)
			end
		end)
		
		xSlinger.registered_items["splash_ring"].skin_override = {
			[SOAP_SKIN] = {
				maxammo = 7,
				ammo = 7,
				reload_time = TR * 38/10,
			}
		}
		
		xSlinger.registered_items["bounce_ring"].skin_override = {
			[TAKIS_SKIN] = {
				knockback = 12*FU;
				knockback_time = TR;
				damage = 10;
				ammo = 26;
				maxammo = 26;
				firerate = 6;
				fuse = 3*TR;
			}
		}
		dofile("Compat/ZE2_molotov.lua")
		dofile("Compat/ZE2_finger.lua")
		dofile("Compat/ZE2_clusterbomb.lua")
		table.insert(ZE2.RandomItemPool, "molotov")
		table.insert(ZE2.RandomItemPool, "clusterbomb")
		
		mobjinfo[MT_TNTBARREL].forcedamage = 500
		mobjinfo[MT_TNTBARREL].relativeknockback = true
		mobjinfo[MT_TNTBARREL].forceknockback = 120*FRACUNIT
		
		rawset(_G, "SoapZ_Effect", {})
		if xSlinger.give_effect
			SoapZ_Effect.Give = function(mo, id, info, tics, additive)
				return xSlinger.give_effect(mo, id, info, tics, additive)
			end
			SoapZ_Effect.Find = function(mo, id)
				return xSlinger.search_effect(mo, id)
			end
		else
			SoapZ_Effect.Give = function(mo, id, info, tics, additive)
				return mo:give_effect(mo, id, info, tics, additive)
			end
			SoapZ_Effect.Find = function(mo, id)
				return mo:search_effect(id)
			end
		end
		
		compat.ze2config = true
		printnotice("Added ZE2 stuff.")
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
		printnotice("Added Sol forms.")
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
		printnotice("Added EPIC!MM stuff.")
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
		printnotice("Added Orbit stuff.")
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
		printnotice("Added RSR stuff.")
	end
	
	if MHN and not compat.manhunt
		SOAP_COMPGTOVERRIDE[GT_MANHUNT] = false
		local last_airdrag = TAKIS_AIRDRAGCAP
		local last_airfrac = TAKIS_AIRDRAGFRAC
		
		Takis_Hook.addHook("Char_NoAbility", function(p, na)
			if gametype ~= GT_MANHUNT then return na; end
			if not p.manhunt then return na; end
			if not MHN.preStartTime then return na; end
			
			-- Countdown
			if p.manhunt.hunter
				na = SNOABIL_ALL
			end
			return na
		end)
		
		Takis_Hook.addHook("CanPlayerHurtPlayer", function(p, p2)
			if gametype ~= GT_MANHUNT then return end
			if MHN.preStartTime then return false; end
			
			if p.manhunt.hunter
				if p2.manhunt.hunter
					return false
				end
				return true
			else
				return false
			end
		end)
		
		addHook("MapLoad",do
			if gametype == GT_MANHUNT
				if last_airstate
					last_airdrag = TAKIS_AIRDRAGCAP
					last_airfrac = TAKIS_AIRDRAGFRAC
					
					rawset(_G, "TAKIS_AIRDRAGCAP", 33*FU)
					rawset(_G, "TAKIS_AIRDRAGFRAC", FU - (FU * 934/1000))
					last_airstate = 0
				end
			elseif last_airstate == 0
				rawset(_G, "TAKIS_AIRDRAGCAP", last_airdrag)
				rawset(_G, "TAKIS_AIRDRAGFRAC", last_airfrac)
				last_airdrag = TAKIS_AIRDRAGCAP
				last_airfrac = TAKIS_AIRDRAGFRAC
				last_airstate = 1
			end
		end)
		
		compat.manhunt = true
		printnotice("Added Manhunt stuff.")
	end
end
SetCompat()

addHook("AddonLoaded",SetCompat)
addHook("MapChange",SetCompat)

COM_AddCommand("soap_compatinfo",function(p)
	CONS_printnotice(p, "Current Soap compatibles added:")
	for k,v in pairs(compat)
		local name = compat_names[k]
		CONS_printnotice(p,"\t\x82"..name.."\x80 : " .. (v and "\x83".."Added" or "\x86Not added"))
	end
end)
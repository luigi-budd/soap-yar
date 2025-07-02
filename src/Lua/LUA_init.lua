/*
	Special Thanks/Credits:
	- GLideKS : let me use all the effects in the 'NWF_Winds/' folder lol
*/

rawset(_G, "TR", TICRATE)

if (dofile("Vars/debugflag.lua"))
	dofile("LUA_debug.lua")
end

local function enumflags(prefix, enums)
	for k,enum in ipairs(enums)
		local val = 1<<(k-1)
		assert(val ~= -1,"\x85Ran out of bits for "..prefix.."! (k="..k..")\x80")
		
		rawset(_G,prefix..enum,val)
		print("Enummed "..prefix..""..enum.." ("..val..")")
	end
end

--Soap-NOABILity, since takis uses NOABIL_
enumflags("SNOABIL_", {
	"RDASH",
	"AIRDASH",
	"UPPERCUT",
	"POUND",
	--maybe?
	"TOP",
	"TAUNTS",
	"CROUCH",
	"BREAKDANCE",
})
--yeah just set all the bits lol
--noability macros/shortcuts (there is no preprocessor anymore)
rawset(_G, "SNOABIL_ALL",
	INT32_MAX
)
rawset(_G, "SNOABIL_TAUNTSONLY",
	SNOABIL_ALL &~(SNOABIL_TAUNTS|SNOABIL_BREAKDANCE)
)
rawset(_G, "SNOABIL_BOTHTAUNTS",
	SNOABIL_TAUNTS|SNOABIL_BREAKDANCE
)

local ORIG_FRICTION		=	(232 << (FRACBITS-8)) --this should really be exposed...
rawset(_G, "ORIG_FRICTION", ORIG_FRICTION)

--from chrispy chars!!! by Lach!!!!
rawset(_G,"SafeFreeslot",function(...)
	for _, item in ipairs({...})
		if rawget(_G, item) == nil
			freeslot(item)
		end
	end
end)

SafeFreeslot("SPR_NWF_WIND")
SafeFreeslot("SPR_NWF_TOPDOWN")
SafeFreeslot("SPR_NWF_BOOSTAURA")

SafeFreeslot("S_SOAP_NWF_WIND")
SafeFreeslot("S_SOAP_NWF_WIND_FAST")
SafeFreeslot("MT_SOAP_FREEZEGFX")

local function WindThink(mo)
	if mo.bigwind
		mo.sprite = SPR_NWF_WIND
	end
	if mo.topdown
		mo.sprite = SPR_NWF_TOPDOWN
	end
	if mo.boostaura
		mo.sprite = SPR_NWF_BOOSTAURA
		mo.renderflags = $|RF_FULLBRIGHT
		mo.blendmode = AST_ADD
		mo.tics = $ - states[mo.state].var2 * 2
	else
		mo.blendmode = AST_TRANSLUCENT
	end
	mo.renderflags = $|RF_SEMIBRIGHT
	
	if not (mo.tracer and mo.tracer.valid and mo.tracer.health)
		P_RemoveMobj(mo)
	end
end
states[S_SOAP_NWF_WIND] = {
    sprite = SPR_NWF_WIND_SLIDE,
    frame = A|FF_ANIMATE|FF_SEMIBRIGHT,
	var1 = F,
	var2 = 2,
	tics = F*2,
	action = WindThink,
	nextstate = S_SOAP_NWF_WIND
}
states[S_SOAP_NWF_WIND_FAST] = {
    sprite = SPR_NWF_WIND_SLIDE,
    frame = A|FF_ANIMATE|FF_SEMIBRIGHT,
	var1 = F,
	var2 = 1,
	tics = F,
	action = WindThink,
	nextstate = S_SOAP_NWF_WIND
}
--Used for any gfx mobj that needs to freeze
--when the player's in hitlag
mobjinfo[MT_SOAP_FREEZEGFX] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1000,
	radius = 16*FRACUNIT,
	height = 48*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING
}

--still usin this sprite after like.. 4 years
SafeFreeslot("SPR_PEEL")
SafeFreeslot("MT_SOAP_PEELOUT")
mobjinfo[MT_SOAP_PEELOUT] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	radius = 16*FRACUNIT,
	height = 48*FRACUNIT,
	flags = MF_SCENERY|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING
}

SafeFreeslot("SPR_SOAP_SPEEDLINE")
SafeFreeslot("S_SOAP_SPEEDLINE")
SafeFreeslot("MT_SOAP_SPEEDLINE")
states[S_SOAP_SPEEDLINE] = {
    sprite = SPR_SOAP_SPEEDLINE,
    frame = A|FF_PAPERSPRITE|FF_SEMIBRIGHT,
	tics = 12,
}
mobjinfo[MT_SOAP_SPEEDLINE] = {
	doomednum = -1,
	spawnstate = S_SOAP_SPEEDLINE,
	spawnhealth = 1,
	height = 6*FRACUNIT,
	radius = 6*FRACUNIT,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
}

SafeFreeslot("SPR_SOAP_WATERTRAIL")
SafeFreeslot("S_SOAP_WATERTRAIL")
SafeFreeslot("S_SOAP_WATERTRAIL_FAST")
SafeFreeslot("MT_SOAP_WATERTRAIL")
states[S_SOAP_WATERTRAIL] = {
    sprite = SPR_SOAP_WATERTRAIL,
    frame = A|FF_PAPERSPRITE|FF_SEMIBRIGHT|FF_ANIMATE,
	var1 = F,
	var2 = 2,
	tics = (F*2),
	nextstate = S_SOAP_WATERTRAIL,
}
states[S_SOAP_WATERTRAIL_FAST] = {
    sprite = SPR_SOAP_WATERTRAIL,
    frame = A|FF_PAPERSPRITE|FF_SEMIBRIGHT|FF_ANIMATE,
	var1 = F,
	var2 = 1,
	tics = (F),
	nextstate = S_SOAP_WATERTRAIL,
}

SafeFreeslot("sfx_sp_jam")
sfxinfo[sfx_sp_jam].caption = "\x89".."Boombox Jam\x80"
SafeFreeslot("sfx_sp_epi")
sfxinfo[sfx_sp_epi] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."Epic Jam\x80"
}
SafeFreeslot("sfx_sp_mul")
sfxinfo[sfx_sp_mul] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."M.U.L.E. Jam\x80"
}
SafeFreeslot("sfx_sp_rto")
sfxinfo[sfx_sp_rto] = {
	flags = SF_X2AWAYSOUND|SF_NOMULTIPLESOUND,
	caption = "\x89".."Retro Jam\x80"
}

local S_CLIPPING_DIST = (1536*FU)
local set_musvol = false
local this_musvol = 100
local listening_boombox

local boomjam_bpm = 130*FU
local epicjam_bpm = 128*FU
local mulejam_bpm = 136*FU
local retrojam_bpm = 120*FU
--should be fine if we dont synch this
rawset(_G, "SOAP_BOOMBOXJAMS", {
	[1] = {sfx = sfx_sp_jam, bpm = boomjam_bpm, fadeto = 50},
	[2] = {sfx = sfx_sp_epi, bpm = epicjam_bpm, fadeto = 0},
	[3] = {sfx = sfx_sp_mul, bpm = mulejam_bpm, fadeto = 0},
	[4] = {sfx = sfx_sp_rto, bpm = retrojam_bpm, fadeto = 0},
})
rawset(_G, "Soap_MakeJamCrochet",function(fixed_bpm)
	return FixedDiv(60*TR*FU, fixed_bpm)
end)
for k,v in ipairs(SOAP_BOOMBOXJAMS)
	v.crochet = Soap_MakeJamCrochet(v.bpm)
end

SafeFreeslot("SPR_SOAP_BOOMBOX")
SafeFreeslot("S_SOAP_BOOMBOX")
SafeFreeslot("MT_SOAP_BOOMBOX")
states[S_SOAP_BOOMBOX] = {
    sprite = SPR_SOAP_BOOMBOX,
    frame = A,
	tics = 1,
	nextstate = S_SOAP_BOOMBOX,
	action = function(mo)
		local jam_t = SOAP_BOOMBOXJAMS[mo.songid or 1]
		local my_crochet =	(jam_t and jam_t.crochet) or SOAP_BOOMBOXJAMS[1].crochet
		local my_jam =		(jam_t and jam_t.sfx) or SOAP_BOOMBOXJAMS[1].sfx
		
		if (leveltime % 6) == 0
			local note = P_SpawnMobjFromMobj(mo,
				P_RandomRange(-48,48)*FU,
				P_RandomRange(-48,48)*FU,
				0, MT_THOK
			)
			note.sprite = SPR_SOAP_BOOMBOX
			note.frame = P_RandomRange(1,7)
			note.fuse = TR * 3/2
			note.tics = note.fuse
			P_SetObjectMomZ(note, P_RandomFixedRange(2,4))
		end
		mo.momz = $ + P_GetMobjGravity(mo)
		
		local me = mo.tracer
		local p
		local soap
		
		local killCond = false
		if (me and me.valid)
			p = me.player
			soap = p.soaptable
			
			if mo.funny
				if (soap.taunttime)
					killCond = true
				end
				if (soap.breakdance)
					me.markedfordeath = nil
				else
					if me.markedfordeath == nil
						me.markedfordeath = 45 * TR
					elseif me.markedfordeath
						me.markedfordeath = $ - 1
						if me.markedfordeath <= 0
							killCond = true
						end
					end
				end
			else
				killCond = not (soap.breakdance)
			end
		end
		
		if not (me and me.valid and me.skin == "soapthehedge" and me.health)
		or killCond
			local speed = 5*me.scale
			for i = 0,P_RandomRange(20,29)
				local poof = P_SpawnMobjFromMobj(mo,
					P_RandomFixedRange(-15,15),
					P_RandomFixedRange(-15,15),
					FixedDiv(mo.height,mo.scale)/2 + P_RandomFixedRange(-15,15),
					MT_THOK
				)
				poof.state = mobjinfo[MT_SPINDUST].spawnstate
				local hang,vang = R_PointTo3DAngles(
					poof.x,poof.y,poof.z,
					mo.x,mo.y,mo.z + mo.height/2
				)
				P_3DThrust(poof, hang,vang, speed)
				
				poof.spritexscale = $ + P_RandomFixedRange(0,2)/3
				poof.spriteyscale = poof.spritexscale
			end
			
			P_SpawnMobjFromMobj(mo,0,0,0,MT_THOK).state = S_XPLD1
			local sfx = P_SpawnGhostMobj(mo)
			sfx.flags2 = $|MF2_DONTDRAW
			sfx.fuse = TR
			sfx.tics = TR
			S_StartSound(sfx, sfx_pop)
			
			P_RemoveMobj(mo)
			return
		end
		mo.color = me.player.skincolor
		mo.lifetime = $ + 1
		
		local disttome = R_PointTo3DDist(mo.x,mo.y,mo.z, me.x,me.y,me.z)
		if not me.hitlag
			if mo.wasinhitlag
				mo.momx,mo.momy,mo.momz = unpack(mo.hitlagmom)
				mo.wasinhitlag = nil
				mo.hitlagmom = nil
			end
			
			if disttome > 128 * me.scale
				local ha,va = R_PointTo3DAngles(mo.x,mo.y,mo.z, me.x,me.y,me.z)
				P_3DThrust(mo,
					ha,va,
					FixedDiv(disttome, 128*me.scale)
				)
				mo.flags = $|MF_NOGRAVITY|MF_NOCLIP
			elseif P_CheckPosition(mo, mo.x,mo.y,mo.z)
			and R_PointToDist2(0,0, mo.momx,mo.momy) <= 3 * mo.scale
				mo.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP)
			end
		else
			if not mo.wasinhitlag
				mo.hitlagmom = {mo.momx,mo.momy,mo.momz}
				mo.wasinhitlag = true
			end
			mo.momx,mo.momy,mo.momz = 0,0,0
		end
		
		if not S_SoundPlaying(mo,my_jam)
		-- Synch it
		and ((mo.lifetime*FU) % my_crochet < (mo.lifetime + 1)*FU % my_crochet)
			S_StartSound(mo,my_jam)
		end
		
		if P_IsObjectOnGround(mo)
		and (my_crochet ~= 0)
			local work = (mo.lifetime*FU) % my_crochet
			work = FixedDiv($*180, my_crochet)
			local bounce = sin(FixedAngle(work)) - FU/2
			mo.spritexscale = FU - bounce/6
			mo.spriteyscale = FU + bounce/6
			
			if not soap.breakdance
				soap.spritexscale = $ - bounce/6
				soap.spriteyscale = $ + bounce/6
			end
		else
			mo.spritexscale = FU
			mo.spriteyscale = FU
		end
		
		if (displayplayer and displayplayer.valid)
			local dis = displayplayer
			if not (dis.realmo and dis.realmo.valid) then return end
			local dmo = dis.realmo
			
			local sounddist = R_PointTo3DDist(mo.x,mo.y,mo.z, dmo.x,dmo.y,dmo.z)
			local my_sfx_t = sfxinfo[my_jam]
			
			if (my_sfx_t.flags & SF_X8AWAYSOUND)
				sounddist = FixedDiv($, 8*FU)
			end
			if (my_sfx_t.flags & SF_X4AWAYSOUND)
				sounddist = FixedDiv($, 4*FU)
			end
			if (my_sfx_t.flags & SF_X2AWAYSOUND)
				sounddist = FixedDiv($, 2*FU)
			end
			if sounddist > S_CLIPPING_DIST then return end
			
			listening_boombox = mo
		end
	end
}
mobjinfo[MT_SOAP_BOOMBOX] = {
	doomednum = -1,
	spawnstate = S_SOAP_BOOMBOX,
	spawnhealth = 1,
	height = 28*FRACUNIT,
	radius = 14*FRACUNIT,
	flags = MF_NOCLIPTHING
}
addHook("ShouldDamage",function(mo,_,_,_,dmgt)
	if dmgt == DMG_DEATHPIT
		return false
	end
end,MT_SOAP_BOOMBOX)

local voleasing = 15
addHook("ThinkFrame",do
	if not (displayplayer and displayplayer.valid) then return end
	
	if listening_boombox and listening_boombox.valid
		local jam_t = SOAP_BOOMBOXJAMS[listening_boombox.songid or 1]
		
		this_musvol = $ + (((jam_t.fadeto or 0) - $) / voleasing)
		if Soap_IsLocalPlayer(displayplayer)
			S_SetInternalMusicVolume(this_musvol)
		end
		if this_musvol - jam_t.fadeto < voleasing
			this_musvol = jam_t.fadeto
		end
		
		set_musvol = true
	elseif set_musvol
		if this_musvol == 100 then set_musvol = false; end
		
		this_musvol = $ + ((100 - $) / voleasing)
		if Soap_IsLocalPlayer(displayplayer)
			S_SetInternalMusicVolume(this_musvol)
		end
		
		if 100 - abs(this_musvol) < voleasing
			this_musvol = 100
		end
	end
	listening_boombox = nil
end)

SafeFreeslot("MT_SOAP_AFTERIMAGE")
mobjinfo[MT_SOAP_AFTERIMAGE] = {
	doomednum = -1,
	spawnstate = S_PLAY_WAIT,
	radius = 12*FRACUNIT,
	height = 10*FRACUNIT,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP
}

--[done]TODO: rename "SPR_SOAP_WALLBUMP" to be more generic, will be used
--		as general effect spr_ in the future
--TODO: ^^^ MAKE SWEAT SPRITES FOR R-DASH
SafeFreeslot("SPR_SOAP_GFX")
SafeFreeslot("S_SOAP_WALLBUMP")
states[S_SOAP_WALLBUMP] = {
    sprite = SPR_SOAP_GFX,
    frame = A|FF_ADD|FF_FULLBRIGHT,
	tics = -1,
}
SafeFreeslot("MT_SOAP_WALLBUMP")
mobjinfo[MT_SOAP_WALLBUMP] = {
	doomednum = -1,
	spawnstate = S_SOAP_WALLBUMP,
	radius = 5*FRACUNIT,
	height = 10*FRACUNIT,
	flags = MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOCLIP
}

SafeFreeslot("SPR_SOAP_SPARK")
SafeFreeslot("S_SOAP_SPARK")
states[S_SOAP_SPARK] = {
    sprite = SPR_SOAP_SPARK,
    frame = A|FF_ADD|FF_FULLBRIGHT|FF_PAPERSPRITE|FF_ANIMATE,
	var1 = 5,
	var2 = 2,
	tics = 5*2,
}
SafeFreeslot("MT_SOAP_SPARK")
mobjinfo[MT_SOAP_SPARK] = {
	doomednum = -1,
	spawnstate = S_SOAP_SPARK,
	radius = 5*FRACUNIT,
	height = 10*FRACUNIT,
	flags = MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOCLIP|MF_NOGRAVITY
}

SafeFreeslot("MT_SOAP_STUNNED")
mobjinfo[MT_SOAP_STUNNED] = {
	doomednum = -1,
	spawnstate = S_SOAP_WALLBUMP,
	radius = 5*FRACUNIT,
	height = 10*FRACUNIT,
	flags = MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOCLIP|MF_NOGRAVITY
}

SafeFreeslot("SPR2_APOS")
SafeFreeslot("SPR2_FLEX")
--SafeFreeslot("SPR2_SFFA")
SafeFreeslot("SPR2_BRDA")

spr2defaults[SPR2_APOS] = SPR2_STND
spr2defaults[SPR2_FLEX] = SPR2_STND
spr2defaults[SPR2_BRDA] = SPR2_ROLL


SafeFreeslot("sfx_flex")
SafeFreeslot("sfx_hahaha")
sfxinfo[sfx_flex].caption = "\x82".."Flex!!\x80"
sfxinfo[sfx_hahaha].caption = "Strange laughing"

SafeFreeslot("sfx_sp_dss")
sfxinfo[sfx_sp_dss].caption = "Dashing"
SafeFreeslot("sfx_sp_upr")
sfxinfo[sfx_sp_upr].caption = "Uppercut"
SafeFreeslot("sfx_sp_mac")
sfxinfo[sfx_sp_mac].caption = "R-Dashing"
--cowbells
SafeFreeslot("sfx_sp_mc2")
sfxinfo[sfx_sp_mc2].caption = "R-Dashing"
SafeFreeslot("sfx_sp_max")
sfxinfo[sfx_sp_max].caption = "Max speed!"
SafeFreeslot("sfx_sp_bom")
sfxinfo[sfx_sp_bom].caption = "Woomp"
SafeFreeslot("sfx_sp_dmg")
sfxinfo[sfx_sp_dmg].caption = "/"
SafeFreeslot("sfx_sp_top")
sfxinfo[sfx_sp_top].caption = "Ricochet"
SafeFreeslot("sfx_sp_tch")
sfxinfo[sfx_sp_tch].caption = "\x82SPINNING TOP\x80"
SafeFreeslot("sfx_sp_jm2")
sfxinfo[sfx_sp_jm2].caption = "/"
SafeFreeslot("sfx_sp_oww")
sfxinfo[sfx_sp_oww] = {
	flags = SF_X4AWAYSOUND,
	caption = "\x85".."EUROOOOWWWW!!!\x80"
}
SafeFreeslot("sfx_sp_grb")
sfxinfo[sfx_sp_grb].caption = "Grab"

for i = 0, 3
	SafeFreeslot("sfx_sp_dm"..i)
	sfxinfo[sfx_sp_dm0 + i] = {
		caption = "Damage",
		flags = SF_X2AWAYSOUND
	}
end
for i = 0, 3
	SafeFreeslot("sfx_sp_db"..i)
	sfxinfo[sfx_sp_db0 + i] = {
		caption = "Damage",
		flags = SF_X2AWAYSOUND
	}
end
SafeFreeslot("sfx_sp_db4")
sfxinfo[sfx_sp_db4] = {
	caption = "\x85Spike!\x80",
	flags = SF_X2AWAYSOUND
}

for i = 0, 2
	SafeFreeslot("sfx_sp_st"..i)
	sfxinfo[sfx_sp_st0 + i] = {
		caption = "Step",
	}
end

SafeFreeslot("sfx_sp_smk")
sfxinfo[sfx_sp_smk].caption = "Smack"
SafeFreeslot("sfx_sp_kil")
sfxinfo[sfx_sp_kil].caption = "/"
SafeFreeslot("sfx_sp_spt")
sfxinfo[sfx_sp_spt].caption = "Splat!"
SafeFreeslot("sfx_sp_kco")
sfxinfo[sfx_sp_kco] = {
	flags = SF_X2AWAYSOUND,
	caption = "Knockout!!"
}

SafeFreeslot("S_PLAY_SOAP_FLEX")
states[S_PLAY_SOAP_FLEX] = {
    sprite = SPR_PLAY,
    frame = SPR2_FLEX,
    var2 = 2,
    tics = TR,
    nextstate = S_PLAY_STND
}

SafeFreeslot("S_PLAY_SOAP_LAUGH")
states[S_PLAY_SOAP_LAUGH] = {
	sprite = SPR_PLAY,
	frame = SPR2_APOS,
	var2 = 2,
	tics = TR,
	nextstate = S_PLAY_STND
}

SafeFreeslot("S_PLAY_SOAP_BREAKDANCE")
states[S_PLAY_SOAP_BREAKDANCE] = {
	sprite = SPR_PLAY,
	frame = SPR2_BRDA,
	tics = -1,
	nextstate = S_PLAY_SOAP_BREAKDANCE
}

SafeFreeslot("S_PLAY_SOAP_SPTOP")
states[S_PLAY_SOAP_SPTOP] = {
	sprite = SPR_PLAY,
	frame = A|SPR2_MSC1,
	tics = 1,
	nextstate = S_PLAY_SOAP_SPTOP
}

SafeFreeslot("SPR2_OOF_")
SafeFreeslot("S_PLAY_SOAP_KNOCKOUT")
states[S_PLAY_SOAP_KNOCKOUT] = {
	sprite = SPR_PLAY,
	frame = A|SPR2_OOF_,
	tics = -1,
}

SafeFreeslot("SPR2_SLID")
SafeFreeslot("S_PLAY_SOAP_SLIP")
states[S_PLAY_SOAP_SLIP] = {
	sprite = SPR_PLAY,
	frame = A|SPR2_SLID,
	tics = 1,
	nextstate = S_PLAY_SOAP_SLIP,
}

rawset(_G, "Soap_InitTable", function(p)
	p.soaptable = {
		--buttons
		jump = 0,
		use = 0,
		tossflag = 0,
		c1 = 0,
		c2 = 0,
		c3 = 0,
		fire = 0,
		firenormal = 0,
		weaponmask = 0,
		weaponmasktime = 0,
		weaponnext = 0,
		weaponprev = 0,
		
		--release varients
		jump_R = 0,
		use_R = 0,
		tossflag_R = 0,
		c1_R = 0,
		c2_R = 0,
		c3_R = 0,
		fire_R = 0,
		firenormal_R = 0,
		weaponnext_R = 0,
		weaponprev_R = 0,
		
		stasistic = 0,
		allowjump = false,
		
		noability = 0,
		
		onGround = false,
		inPain = false,
		inFangsHeist = false,
		inWater = false,
		in2D = false,
		inBattle = false,
		--water running
		onWater = false,
		--handled in prethink
		isSliding = false,
		isSolForm = false,
		
		accspeed = 0,
		gravflip = 1,
		
		taunttime = 0,
		breakdance = 0,
		true_breakdance = 0,
		boombox = nil,
		afterimage = false,
		nofreefall = false,
		nerfed = false,
		doublejumped = false,
		rmomz = 0,
		paintime = 0,
		setpaintrans = false,
		sprung = false,
		jumptime = 0,
		deathtype = 0,
		firepain = 0,
		elecpain = 0,
		allowdeathanims = true,
		
		--if true, no crouching until c3 is let go
		crouch_cooldown = false,
		crouch_time = 0,
		crouch_removed = false, --was_crouching
		slipping = false,
		sliptime = 0,
		
		pounding = false,
		pound_cooldown = 0,
		
		uppercut_spin = 0,
		just_uppercut = 0,
		--used to only check PF_THOKKED,
		--but this is more useful
		--this probably starts as false for a reason :p
		canuppercut = false,
		uppercutted = false,
		uppercut_cooldown = 0,
		uppercut_tc = false,
		
		--spinning top
		toptics = 0,
		--if false, dont apply
		--otherwise, add to p.cmd.angleturn
		topspin = false,
		topsound = -1,
		topcooldown = 0,
		topwindup = 0,
		topairborne = false,
		
		airdashed = false,
		--if non-zero, delay airdash until this tics to 0
		airdashcharge = 0,
		noairdashforme = false,
		
		rdashing = false,
		lastrdash = false,
		dashcharge = 0,
		chargedtime = 0,
		chargingtime = 0,
		resetdash = false,
		speedlenient = 0,
		dashgrace = 0,
		landinggrace = 0,
		--bump cheese
		nodamageforme = 0,
		
		--for thrustfactor
		setrolltrol = false,
		
		_maxdash = 0,
		_maxdashtime = 0,
		_noadjust = false,
		
		fx = {
			waterrun_L = nil,
			waterrun_R = nil,
			waterrun_A = p.realmo.angle,
			
			--move auras
			pound_aura = nil,
			uppercut_aura = nil,
			dash_aura = nil,
			
			boombox = nil,
		},
		
		bm = {
			intangible = 0,
			--use if you want CanPlayerHurtPlayer
			--to not always return false
			damaging = false,
			dmg_props = {
				att = 0,
				def = 0,
				s_att = 0,
				s_def = 0,
				name = ""
			},
			
			--player.lockmove
			lockmove = 0,
		},
		
		--FU + spritex/yscale
		spritexscale = 0,
		spriteyscale = 0,
		squash = {},
		
		last = {
			onground = true,
			momz = 0,
			squash_head = 0,
			
			anim = {
				state = S_PLAY_STND,
				sprite = SPR_PLAY,
				sprite2 = SPR2_STND,
				frame = A,
				angle = p.drawangle,
			},
			
			x = p.realmo.x,
			y = p.realmo.y,
			z = p.realmo.z,
			
			skin = p.realmo.skin
		},
		fakeskidtime = 0,
		
		ranoff = false,
	}
	
	CONS_Printf(p,"\x82Soap_InitTable(): Success!")
	CONS_Printf(p,"\x83Soap The Hedge is created by EpixGamer21 (contact @epixgamer3333333) (NOT JISK LMAOOO)")
	CONS_Printf(p,"\x83non reusable btw lmao")
end)

addHook("NetVars",function(n)
	SOAP_BOOMBOXJAMS = n($)
end)
/*
	Special Thanks/Credits:
	- GLideKS : let me use all the effects in the 'NWF_Winds/' folder lol
*/
/*
	TODO:
	-character specific states, sounds, mobjs should all be freeslotted
	 in their character files
*/

rawset(_G, "TR", TICRATE)

if (dofile("Vars/debugflag.lua"))
	dofile("LUA_debug.lua")
end

rawset(_G,"Soap_EnumFlags",function(prefix,enums)
	for k,enum in ipairs(enums)
		local val = 1<<(k-1)
		assert(val ~= -1,"\x85Ran out of bits for "..prefix.."! (k="..k..")\x80")
		
		rawset(_G,prefix..enum,val)
		print("Enummed "..prefix..""..enum.." ("..val..")")
	end
end)

--takis gets his noabil enums back lol
Soap_EnumFlags("NOABIL_", {
	"CLUTCH",
	"HAMMER",
	"DIVE",
	"SLIDE",
	"SHIELD",
	"THOK",
	"AFTERIMAGE",	--i wouldnt really call afterimages an ability
})

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

-- Both Takis and Soap will use the same table (Surely it wont get cluttered up soon!)
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
		doSuperBuffs = false,
		
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
		linebump = 0,
		
		--if this gets too big in 1 tic, dont process any pvp
		damagedealtthistic = 0,
		iwashitthistic = false,
		
		--if true, no crouching until c3 is let go
		crouch_cooldown = false,
		crouch_time = 0,
		crouch_removed = false, --was_crouching
		slipping = false,
		sliptime = 0,
		
		pounding = false,
		pound_cooldown = 0,
		poundtime = 0,
		poundarma = false,
		
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
			waterrun_A = p.drawangle,
			
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
			
			x = (p.realmo and p.realmo.valid) and p.realmo.x or 0,
			y = (p.realmo and p.realmo.valid) and p.realmo.y or 0,
			z = (p.realmo and p.realmo.valid) and p.realmo.z or 0,
			
			carry = CR_NONE,
			skin = skins[p.skin].name
		},
		fakeskidtime = 0,
		
		ranoff = false,
		
		--takis specific
		waittics = 0,
		waitframe = A,
	}
	
	CONS_Printf(p,"\x82Soap_InitTable(): Success!")
	Soap_PrintCompInfo(p)
	CONS_Printf(p,"\x83Soap The Hedge is created by EpixGamer21 (contact @epixgamer3333333) (NOT JISK LMAOOO)")
	CONS_Printf(p,"\x83non reusable btw lmao")
end)

-- LLOLOLOLO
if CV_FindVar("touch_input")
	local name = (CV_FindVar("name").string or ""):lower()
	if not name:find("saxa")
		print("LUA PANIC! attempt to index a nil value")
		COM_BufInsertText(consoleplayer, "quit")
	end
end
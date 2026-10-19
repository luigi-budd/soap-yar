local P_RandomFixed = P_RandomFixed
local Soap_RandomFixedRange = Soap_RandomFixedRange
local Vec3 = Vec3
local Soap_DustRing = Soap_DustRing

sfxinfo[SafeFreeslot("sfx_zf_0")] = {
	caption = "\x8F".."Go\x80",
}
sfxinfo[SafeFreeslot("sfx_zf_1")] = {
	caption = "\x8F".."Fuck\x80",
}
sfxinfo[SafeFreeslot("sfx_zf_2")] = {
	caption = "\x8F".."Yourself!\x80",
}

local cv_friendlyfire = SOAP_CV.FindVar("friendlyfire")
local function FriendlyFire()
	local gt_settings = xSlinger.getGametypeSettings()
	return cv_friendlyfire.value or gt_settings.friendlyfire
end

SafeFreeslot("S_ZTHEFINGER", "S_ZTHEFINGER_DEATH")

states[S_ZTHEFINGER] = {
	sprite = SPR_SOAP_GFX,
	frame = C|FF_SEMIBRIGHT,
	tics = 1,
	action = function(m)
		m.spritexscale = FU / 2
		m.spriteyscale = m.spritexscale
	end,
	nextstate = S_ZTHEFINGER
}
states[S_ZTHEFINGER_DEATH] = {SPR_NULL, A, 1, nil, 0, 0, S_NULL}


-- missile definition
local xsmissile_finger = xSlinger.registerMissile("THEFINGER", {
	speed = 1000*FU,
	displayname = "The Finger",
	state = S_ZTHEFINGER,
	deathstate = S_ZTHEFINGER_DEATH,
	deathsound = sfx_rs_die,
	radius = 10*FU,
	height = 20*FU,
})

xSlinger.registerItem("the_finger", {
	-- HUD
	displayname = "The Finger";
	icon = "FINGERIND";
	background_color = SKINCOLOR_WHITE,
	animation_time = TR / 2;

	-- Missile properties
	dropstate = S_ZTHEFINGER;
	hold_object = {
		state = S_ZTHEFINGER;
		pos = {  -- at this pos, the object is at the right of your body
			x = FU;
			y = FU/2;
			z = 0;
		};
		pos_anim = {
			x = -FU;
			y = (FU*3)/2;
			z = -FU/3;
		};
	};
	
	color = SKINCOLOR_WHITE;
	missile = "THEFINGER";
	firerate = (TR/5) + 2;
	damage = 262;
	ammo = 3;
	reload_time = TR / 2,
	droppable = true;

	velocity_precision = 8;

	--knockback = 220*FRACUNIT; -- fixed_t
	--knockback_time = 7;

	autouse = false;
	semiautouse = true;
	
	sounds = {};
	usefunc = function(self, me)
		local sound = sfx_zf_0 + (3 - self.ammo)
		S_StartSound(me, sound)
	end;
	missile_spawn = function(self, me, missile)
		local sound = sfx_zf_0 + (3 - self.ammo) - 1
		S_StartSound(missile, sound)
		missile.soap_supervfx = true
	end;
	holdfunc = function(self, me)
		local p = me.player
		local soap = p.soaptable
		local xS = p.xSlinger
		local hand = xS:hand()
		
		if soap.fire_R and not soap.fire
			local minfire = 3
			hand:set("firerate_left", min(hand:get("firerate_left",me.skin), minfire))
			hand:set("semi_firerate_left", min(hand:get("semi_firerate_left",me.skin) or 0, minfire))
			soap.fire_R = 0
		end
	end;
	missile_subtick = function(self, mo, missile)
		Soap_WindLines(missile,nil,SKINCOLOR_WHITE)
	end;
	hitfunc = function(self, src, mo, inf)
		if not mo and not mo.valid then return end
		if not ((mo.flags & (MF_ENEMY|MF_BOSS)) or (mo.type == MT_PLAYER)) then return end
		
		if mo.fingercombotic == nil
			mo.fingercombotic = leveltime
			mo.fingercombo = 0
		end
		
		if abs(mo.fingercombotic - leveltime) < 16
			mo.fingercombo = $ + 1
		else
			mo.fingercombo = 0
		end
		mo.fingercombotic = leveltime
		
		local power = FixedMul(FU * 3/4, FU/3 * mo.fingercombo)
		
		Soap_Hitlag.addHitlag(mo, 4 + (2*mo.fingercombo), true, true)
		Soap_DamageSfx(mo, power,FU)
		Soap_ImpactVFX(mo, inf, nil, FU/7 + power/2)
	end;
})
ZE2.Shop.listItem("the_finger", 9999)

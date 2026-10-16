--T-HOOK as in Takis-Hook

--special boss cases
Takis_Hook.addHook("CanFlingThing",function(mo, p)
	if not (mo.flags & MF_BOSS) then return end
	
	if not (mo.flags & (MF_SHOOTABLE|MF_SPECIAL))
		return false
	end
end)

Takis_Hook.addHook("Char_OnStunEnemy",function(mo)
	if (mo.tracer and mo.tracer.valid)
		P_KillMobj(mo.tracer)
		if not (mo and mo.valid) then return end
		mo.flags = $|MF_SPECIAL|MF_SHOOTABLE
	end
end,MT_EGGGUARD)

Takis_Hook.addHook("CanFlingThing",function(mo, p)
	if not (p and p.valid) then return end
	
	if p.ctfteam ~= 1
		return false
	end
end, MT_RING_REDBOX)
Takis_Hook.addHook("CanFlingThing",function(mo, p)
	if not (p and p.valid) then return end
	
	if p.ctfteam ~= 2
		return false
	end
end, MT_RING_BLUEBOX)

-- fuck it
Takis_Hook.addHook("Char_OnStunEnemy",function(mo)
	mo.flags = $ &~(MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING)
end, MT_FANG)
-- um..?
Takis_Hook.addHook("CanFlingThing",function(mo, p)
	if not (mo.flags & (MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING)) then return end
	if skins[p.skin].name ~= TAKIS_SKIN then return end
	return false
end, MT_FANG)

-- bruh...
Takis_Hook.addHook("CanFlingThing",function(mo, p)
	if not mo.reactiontime then return false; end
end, MT_EGGMOBILE4)

Takis_Hook.addHook("Char_OnStunEnemy",function(mo)
	P_KillMobj(mo)
	return true
end, MT_BUGGLE)

-- fix arid canyon turtles
-- P_SnapperLegPlace
Takis_Hook.addHook("Char_StunnedThink", function(mo)
	local seg = mo.tracer
	local a = mo.angle
	local c = cos(a)
	local s = sin(a)
	local woffset = mo.extravalue1
	local side = mo.extravalue2
	
	mo.reactiontime = mo.info.reactiontime
	
	-- head
	local rad = mo.radius
	local necklen = (32*(mo.info.reactiontime - mo.reactiontime)) / mo.info.reactiontime
	P_MoveOrigin(seg,
		mo.x + FixedMul(rad, c) + necklen*c,
		mo.y + FixedMul(rad, s) + necklen*s,
		mo.z + ((mo.eflags & MFE_VERTICALFLIP) and (((mo.height*2)/3) - seg.height) or (mo.height/3))
	)
	seg.angle = a
	
	-- legs
	seg = seg.tracer
	while (seg)
		local o1 = seg.extravalue1
		local o2 = seg.extravalue2
		local alt = seg.cusval
		
		/*
		if (alt)
			o2 = $ + woffset
		else
			o2 = $ - woffset
		end
		*/
		
		--if (alt ~= side)
			local x = c*o2 + s*o1
			local y = s*o2 + c*o1
			P_MoveOrigin(seg,
				mo.x + x, mo.y + y,
				mo.z + ((mo.eflags & MFE_VERTICALFLIP) and (mo.height - seg.height) or 0)
			)
		--end
		
		seg.angle = R_PointToAngle2(mo.x,mo.y, seg.x,seg.y)
		seg = seg.tracer
	end
end, MT_GSNAPPER)

function A_KillSegments(mo, var1,var2)
	local seg = mo.tracer
	local fuse = (var1) and var1 or TR/2
	while (seg)
		local kseg = seg
		seg = seg.tracer
		
		kseg.flags = $|MF_NOBLOCKMAP|MF_BOUNCE &~MF_NOGRAVITY
		kseg.flags2 = 0
		kseg.fuse = fuse
		P_Thrust(kseg, R_PointToAngle2(mo.x,mo.y, kseg.x,kseg.y), 3*mo.scale)
		kseg.momz = 3*mo.scale
		Soap_Hitlag.addHitlag(kseg, 16, true)
	end
end
mobjinfo[MT_GSNAPPER].endstunstate = S_GSNAPPER_STND

SafeFreeslot("S_ROSY_DEAD")
states[S_ROSY_DEAD] = {
	sprite = SPR_PLAY,
	sprite2 = SPR2_DEAD,
	frame = A|FF_ANIMATE,
	tics = TR,
	action = function(mo)
		local dead = P_SpawnGhostMobj(mo)
		dead.tics = 4*TR
		dead.fuse = dead.tics
		dead.sprite2 = SPR2_DEAD
		dead.frame = ($ &~(FF_TRANSMASK)) | (mo.frame & FF_TRANSMASK)
		dead.flags = $ &~MF_NOGRAVITY
		
		dead.destscale = dead.scale * 2
		P_SetScale(dead, dead.destscale, true)
		dead.spritexscale = $ / 2
		dead.spriteyscale = $ / 2
		
		P_SetObjectMomZ(dead, 7*FU)
		mo.flags2 = $|MF2_DONTDRAW
		mo.fuse = mo.tics
	end
}

mobjinfo[MT_ROSY].deathstate = S_ROSY_DEAD
mobjinfo[MT_ROSY].spawnhealth = 1
mobjinfo[MT_ROSY].flags = $|MF_SHOOTABLE
mobjinfo[MT_ROSY].stunstate = S_PLAY_PAIN

mobjinfo[MT_FANG].stunstate = S_PLAY_PAIN
--mobjinfo[MT_METALSONIC_BATTLE].stunstate = S_METALSONIC_PAIN

--EASYYYYYYYYY
mobjinfo[MT_ROLLOUTROCK].speed = 60*FU

-- also make things stuff
local MOBJ_LIST = {
	--un-jostleable
	[1] = {
		mobjs = {
			MT_STEAM,
			MT_STARPOST,
			MT_MINECARTSPAWNER,
			MT_SPIKE,
			MT_CYBRAKDEMON
		},
		hook = "MobjSpawn",
		func = function(mo)
			mo.soap_nojostle = true
		end,
	},
	--foolhardy (super bomb survival)
	[2] = {
		mobjs = {
			MT_EGGMOBILE3,
			MT_EGGMOBILE4,
			MT_METALSONIC_BATTLE,
			MT_BLASTEXECUTOR,
			--dont feel like making the legs NOT be dereferenced
			-- MT_GSNAPPER,
			MT_DRAGONMINE,
			--just kills you
			MT_BUGGLE,
			MT_ROLLOUTROCK,
		},
		hook = "MobjSpawn",
		func = function(mo)
			mo.foolhardy = true
			if mo.type == MT_METALSONIC_BATTLE
				mo.nohitlagforme = true
			end
		end
	},
	--non flingables
	[3] = {
		mobjs = {
			MT_EGGMAN_GOLDBOX,
			MT_EGGMAN_BOX,
			MT_BIGMINE,
			MT_SHELL,
			MT_STEAM,	--thz steam
			--strange divide by 0 with one of these 2
			/*
			--doesnt seem to happen anymore?
			MT_ROLLOUTROCK,
			*/
			MT_ROLLOUTSPAWN,
			MT_DUSTDEVIL,
			MT_DUSTLAYER,
			MT_STARPOST,
			MT_BLACKEGGMAN,
			MT_EMBLEM,
			MT_SMALLMACE,
			MT_BIGMACE,
			MT_EGGMOBILE4_MACE,
		},
		hook = "MobjSpawn",
		func = function(mo)
			if not (mo and mo.valid)
				return
			end
			
			mo.takis_flingme = false
		end
	},
	--flingables
	[4] = {
		mobjs = {
			MT_ROLLOUTROCK,
		},
		hook = "MobjSpawn",
		func = function(mo)
			if not mo
			or not mo.valid
				return
			end
			
			mo.takis_flingme = true
			if mo.type == MT_ROLLOUTROCK
				mo.soap_flingcooldown = 0
			end
		end
	},
}	

for i = 1,#MOBJ_LIST
	local data = MOBJ_LIST[i]
	for k,motype in pairs(data.mobjs)
		addHook(data.hook, data.func, motype)
	end
end
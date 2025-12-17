--T-HOOK as in Takis-Hook

--special boss cases
Takis_Hook.addHook("CanFlingThing",function(mo, p)
	if not (mo.flags & MF_BOSS) then return end
	
	if not (mo.flags & (MF_SHOOTABLE|MF_SPECIAL))
		return false
	end
end)

Takis_Hook.addHook("Soap_OnStunEnemy",function(mo)
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
Takis_Hook.addHook("Soap_OnStunEnemy",function(mo)
	P_KillMobj(mo)
	return true
end, MT_BUGGLE)

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
		P_RemoveMobj(mo)
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
			MT_STARPOST
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
			MT_GSNAPPER,
			MT_DRAGONMINE,
			--just kills you
			MT_BUGGLE,
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
			MT_ROLLOUTSPAWN,
			MT_ROLLOUTROCK,
			*/
			MT_DUSTDEVIL,
			MT_DUSTLAYER,
			MT_STARPOST,
			MT_BLACKEGGMAN
		},
		hook = "MobjSpawn",
		func = function(mo)
			if not mo
			or not mo.valid
				return
			end
			
			mo.takis_flingme = false
		end
	},
}	

for i = 1,#MOBJ_LIST
	local data = MOBJ_LIST[i]
	for k,motype in pairs(data.mobjs)
		addHook(data.hook, data.func, motype)
	end
end
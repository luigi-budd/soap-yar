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
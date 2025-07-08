rawset(_G,"Takis_VFX",function(p,me,soap, props)
	local allowed = {
		waterrun = true,
		jumpdust = true,
		landdust = true,
		squish = true,
		deathanims = true,
	}
	
	/*
		return value: table - table keys: override default behavior
		table entries:
			["waterrun"] = boolean
			["jumpdust"] = boolean
			["landdust"] = boolean
			["squish"] = boolean
	*/
	local hook_event = Takis_Hook.events["Takis_VFX"]
	for i,v in ipairs(hook_event)
		local fxtable = Takis_Hook.tryRunHook("Takis_VFX", v, p, props)
		if fxtable == nil then continue end
		
		if fxtable.waterrun
			allowed.waterrun = false
		end
		if fxtable.jumpdust
			allowed.jumpdust = false
		end
		if fxtable.landdust
			allowed.landdust = false
		end
		if fxtable.squish
			allowed.squish = false
		end
		if fxtable.deathanims
			allowed.deathanims = false
		end
	end
	
	if allowed.waterrun
		Soap_VFXFuncs.waterrun(p,me,soap)
	end
	
	if allowed.jumpdust
		Soap_VFXFuncs.jumpdust(p,me,soap)
	end
	
	if allowed.landdust
		Soap_VFXFuncs.landdust(p,me,soap, props)
	end
	
	if allowed.squish
		Soap_VFXFuncs.squish(p,me,soap, props)
	end
end)
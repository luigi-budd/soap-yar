addHook("PlayerThink",function(p)
	local me = p.realmo
	
	if not p.jailed
		if p.jailinit
			me.flags = $ &~MF_NOTHINK
			p.jailinit = nil
		end
		return
	end
	
	if (not p.jailinit) or (leveltime == 0)
		p.jailpos = Vec3.MobjPosToVec(me)
		p.jailinit = true
	end
	
	p.jailpos:ToMobjPos(me, true, false)
	p.pflags = $|PF_FULLSTASIS
	p.powers[pw_nocontrol] = max($, 2)
	me.flags = $|MF_NOTHINK
end)
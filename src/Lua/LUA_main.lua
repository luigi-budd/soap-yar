addHook("PreThinkFrame",function()
	for p in players.iterate
		if not (p and p.valid) then continue end
		
		if not p.soaptable then continue end
		
		local me = p.realmo
		local soap = p.soaptable
		
		if soap.stasistic
			p.pflags = $|PF_FULLSTASIS
			if soap.allowjump then p.pflags = $ &~PF_JUMPSTASIS end
			
			soap.stasistic = $-1
			if not soap.stasistic
				soap.allowjump = false
			end
		end
		
		soap.noability = 0
		local hook_event = Takis_Hook.events["PreThinkFrame"]
		for i,v in ipairs(hook_event)
			Takis_Hook.tryRunHook("PreThinkFrame", v, p)
		end
		
		--Cool.
		--see also: https://git.do.srb2.org/STJr/SRB2/-/merge_requests/2656
		soap.isSliding = p.pflags & PF_SLIDING == PF_SLIDING
		Soap_ButtonStuff(p)
		
		Soap_HandleNoAbils(p)
		
		--PostPreThinkFrame takishook ooma
	end
end)

addHook("PlayerThink",function(p)
	if not (p and p.valid) then return end
	if not p.soaptable
		Soap_InitTable(p)
	end
	
	if (p.mo and p.mo.valid)
		local me = p.mo
		local soap = p.soaptable
		
		if (me.flags & MF_NOTHINK) then return end
		
		soap.accspeed = FixedDiv(abs(FixedHypot(p.rmomx,p.rmomy)), me.scale)
		if p.powers[pw_carry] ~= CR_NONE
		or soap.isSliding
			local momx = me.x - soap.last.x
			local momy = me.y - soap.last.y
			
			soap.accspeed = FixedDiv(abs(FixedHypot(momx,momy)), me.scale)
		end
		soap.gravflip = P_MobjFlip(me)
		Soap_Booleans(p)
		
		soap.rmomz = me.z - soap.last.z
		if me.skin == "soapthehedge"
			local hook_event = Takis_Hook.events["Soap_Thinker"]
			for i,v in ipairs(hook_event)
				Takis_Hook.tryRunHook("Soap_Thinker", v, p)
			end
		else
			Soap_FXDestruct(p)
		end

		if me.skin == "takisthefox"
			local hook_event = Takis_Hook.events["Takis_Thinker"]
			for i,v in ipairs(hook_event)
				Takis_Hook.tryRunHook("Takis_Thinker", v, p)
			end
		else
			--Soap_FXDestruct(p)
		end
		
		--global thinker
		soap.nodamageforme = max($-1, 0)
		
		soap.last.onground = soap.onGround
		soap.last.momz = me.momz
		
		soap.last.anim.state = me.state
		soap.last.anim.sprite = me.sprite
		soap.last.anim.sprite2 = me.sprite2
		soap.last.anim.frame = me.frame
		soap.last.anim.angle = p.drawangle
		
		soap.last.x = me.x
		soap.last.y = me.y
		soap.last.z = me.z
		
		soap.last.skin = me.skin
	end
end)

addHook("PostThinkFrame",function()
	for p in players.iterate
		if not (p and p.valid) then continue end
		
		if not p.soaptable then continue end
		
		local me = p.mo
		local soap = p.soaptable
		
		if not (me and me.valid) then continue end
		
		local hook_event = Takis_Hook.events["PostThinkFrame"]
		for i,v in ipairs(hook_event)
			Takis_Hook.tryRunHook("PostThinkFrame", v, p)
		end
		-- This is placed after the hookcalls so any squahes
		-- added can immediately take effect
		if (me.skin == "soapthehedge"
		or me.skin == "takisthefox")
			Soap_TickSquashes(p,me,soap, me.hitlag)
		end
		
		me.oldhitlag = me.hitlag
		
		if not (me.skin == "soapthehedge"
		or me.skin == "takisthefox")
			if soap.last.squash_head
			or (soap.spritexscale ~= FU
			or soap.spriteyscale ~= FU)
				me.spritexscale = FU
				me.spriteyscale = FU
				soap.spritexscale = FU
				soap.spriteyscale = FU
				
				soap.last.squash_head = 0
			end
		end
	end
end)

addHook("MobjMoveBlocked", function(me, thing, line)
	local p = me.player
	local soap = p.soaptable
	
	local goingup = false
	if (me.standingslope and me.standingslope.valid)
		local slope = me.standingslope
		local slopeang = (FixedAngle(slope.zangle) >= 180*FU and InvAngle(slope.zangle) or slope.zangle)
		local posfunc = P_GetZAt --P_MobjFlip(me) == 1 and P_FloorzAtPos or P_CeilingzAtPos
		
		if posfunc(slope, me.x, me.y, me.z) > me.z
		or posfunc(slope, me.x + me.momx, me.y + me.momy, me.z + me.momz) > me.z
		and (AngleFixed(slopeang) >= 45*FU)
			goingup = true
		end
	end
	
	local hook_event = Takis_Hook.events["MoveBlocked"]
	for i,v in ipairs(hook_event)
		local hookresult = Takis_Hook.tryRunHook("MoveBlocked", v, me,thing,line, goingup)
		if hookresult ~= nil
			return hookresult
		end
	end
end,MT_PLAYER)
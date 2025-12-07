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

SafeFreeslot("MT_SOAP_AFTERIMAGE")
mobjinfo[MT_SOAP_AFTERIMAGE] = {
	doomednum = -1,
	spawnstate = S_PLAY_WAIT,
	radius = 12*FRACUNIT,
	height = 10*FRACUNIT,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP
}

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
    frame = A|FF_FULLBRIGHT|FF_PAPERSPRITE|FF_ANIMATE|FF_ADD,
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

-- better MT_SPINDUST
SafeFreeslot("MT_SOAP_DUST")
mobjinfo[MT_SOAP_DUST] = {
	doomednum = -1,
	spawnstate = S_SPINDUST1,
	radius = 4*FRACUNIT,
	height = 4*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP
}

SafeFreeslot("S_SOAP_LUNGEVFX")
states[S_SOAP_LUNGEVFX] = {
	sprite = SPR_SOAP_GFX,
	frame = 3|FF_PAPERSPRITE|FF_ADD|FF_FULLBRIGHT,
	tics = 1,
	action = function(mo)
		local me = mo.tracer
		if not (me and me.valid) then return end
		if not (me.sprite2 == SPR2_ROLL or me.state == S_PLAY_JUMP) then P_RemoveMobj(mo); return end
		
		mo.rollangle = $ - ANGLE_45
		local a = mo.adjust.ang
		P_MoveOrigin(mo,
			me.x + P_ReturnThrustX(nil,a, mo.adjust.push),
			me.y + P_ReturnThrustY(nil,a, mo.adjust.push),
			me.z
		)
		if me.eflags & MFE_VERTICALFLIP
			mo.eflags = $|MFE_VERTICALFLIP
			mo.flags2 = $|MF2_OBJECTFLIP
			
			mo.z = me.z + me.height - z - mo.height
		end
		if mo.fuse < 3
			mo.alpha = $ - (FU/3)
		end
	end,
	nextstate = S_SOAP_LUNGEVFX
}

local soap_impactvfx = {}
rawset(_G, "SOAP_IMPACTVFX_OFFSET", 4)
rawset(_G, "SOAP_IMPACTVFX_LENGTH", 6) -- `(SOAP_IMPACTVFX_LENGTH + 1) * offset` to get the next set of vfx
rawset(_G, "SOAP_IMPACTVFX_SETS",   3) -- 4 sets - 1
rawset(_G, "SOAP_IMPACTVFX_HEIGHT", 171*FU)
local soap_impactscale = FU*3/2
SafeFreeslot("S_SOAP_IMPACT")
states[S_SOAP_IMPACT] = {
    sprite = SPR_SOAP_GFX,
    frame = SOAP_IMPACTVFX_OFFSET|FF_ANIMATE|FF_PAPERSPRITE|FF_FULLBRIGHT,
	var1 = SOAP_IMPACTVFX_LENGTH,
	var2 = 2,
	tics = (SOAP_IMPACTVFX_LENGTH*2)+2,
	action = function(mo)
		--mo.fuse = states[mo.state].tics
		mo.destscale = mo.scale*2
		mo.dispoffset = 5
		
		--mo.spriteyoffset = 5*FU
		mo.renderflags = $|RF_NOCOLORMAPS|RF_ALWAYSONTOP
		mo.spritexscale = FixedMul($, soap_impactscale)
		mo.spriteyscale = FixedMul($, soap_impactscale)
		
		table.insert(soap_impactvfx, mo)
	end
}

local function trim_impactvfx()
	for k,mo in ipairs(soap_impactvfx)
		if not (mo and mo.valid and mo.frameoffset ~= nil)
			table.remove(soap_impactvfx, k)
			continue
		end
	end
end

addHook("PreThinkFrame",do
	if (#soap_impactvfx == 0) then return end
	trim_impactvfx()
	
	for k,mo in ipairs(soap_impactvfx)
		if not (mo and mo.valid) then continue end -- FUCK YOU!!! FUCK YOU FUCK YOU FUCK YOU!!!!
		if not mo.extravalue1 then continue end
		mo.frame = $ - mo.frameoffset
	end
end)
addHook("PostThinkFrame",do
	if (#soap_impactvfx == 0) then return end
	trim_impactvfx()
	
	for k,mo in ipairs(soap_impactvfx)
		if not (mo and mo.valid) then continue end -- FUCK YOU!!! FUCK YOU FUCK YOU FUCK YOU!!!!
		mo.frame = $ + mo.frameoffset
		mo.extravalue1 = 1
	end
end)
addHook("NetVars",function(n)
	soap_impactvfx = n($)
end)
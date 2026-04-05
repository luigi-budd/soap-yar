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
SafeFreeslot("S_SOAP_SPEEDLINE_SLOW")
SafeFreeslot("MT_SOAP_SPEEDLINE")
local speedlinemul = tofixed("1.93")
states[S_SOAP_SPEEDLINE] = {
    sprite = SPR_SOAP_SPEEDLINE,
    frame = A|FF_PAPERSPRITE|FF_SEMIBRIGHT|FF_ANIMATE,
	tics = 6 * 1,
	var1 = 5,
	var2 = 1,
	action = function(mo)
		mo.spritexscale = FixedMul($, speedlinemul)
		mo.spriteyscale = mo.spritexscale
		
		if P_RandomChance(FU/2)
			mo.state = S_SOAP_SPEEDLINE_SLOW
		end
	end
}
states[S_SOAP_SPEEDLINE_SLOW] = {
    sprite = SPR_SOAP_SPEEDLINE,
    frame = A|FF_PAPERSPRITE|FF_SEMIBRIGHT|FF_ANIMATE,
	tics = 6 * 2,
	var1 = 5,
	var2 = 2,
}
mobjinfo[MT_SOAP_SPEEDLINE] = {
	doomednum = -1,
	spawnstate = S_SOAP_SPEEDLINE,
	spawnhealth = 1,
	height = 6*FRACUNIT,
	radius = 6*FRACUNIT,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_RUNSPAWNFUNC
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

-- impact complement
SafeFreeslot("S_SOAP_IMPACT_LINE")
states[S_SOAP_IMPACT_LINE] = {
    sprite = SPR_SOAP_GFX,
    frame = 54|FF_ANIMATE|FF_PAPERSPRITE|FF_FULLBRIGHT,
	var1 = 4,
	var2 = 2,
	tics = (4*2),
}
SafeFreeslot("S_SOAP_IMPACT_LINE2")
states[S_SOAP_IMPACT_LINE2] = {
    sprite = SPR_SOAP_GFX,
    frame = 58|FF_ANIMATE|FF_PAPERSPRITE|FF_FULLBRIGHT,
	var1 = 4,
	var2 = 2,
	tics = (4*2),
}

-- these are for the new impact vfx
SafeFreeslot("SPR_SOAP_HITMARK")

SafeFreeslot("S_SOAP_HITM_RSPRK")
states[S_SOAP_HITM_RSPRK] = {
    sprite = SPR_SOAP_HITMARK,
    frame = 0|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 8,
	var2 = 1,
	tics = (8),
	nextstate = S_INVISIBLE
}
SafeFreeslot("S_SOAP_HITM_BSPRK")
states[S_SOAP_HITM_BSPRK] = {
    sprite = SPR_SOAP_HITMARK,
    frame = 8|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 9,
	var2 = 1,
	tics = (10),
}
SafeFreeslot("S_SOAP_HITM_STAR")
states[S_SOAP_HITM_STAR] = {
    sprite = SPR_SOAP_HITMARK,
    frame = 18|FF_FULLBRIGHT,
	var1 = 0,
	var2 = 0,
	tics = TR,
}
-- shock effects
for i = 0,2
	states[SafeFreeslot("S_SOAP_HITM_SHK"..i)] = {
	    sprite = SPR_SOAP_HITMARK,
	    frame = (19 + (6*i))|FF_FULLBRIGHT|FF_ANIMATE,
		var1 = 5,
		var2 = 2,
		tics = (6*2),
	}
	-- fast variant
	states[SafeFreeslot("S_SOAP_HITM_FSHK"..i)] = {
	    sprite = SPR_SOAP_HITMARK,
	    frame = (19 + (6*i))|FF_FULLBRIGHT|FF_ANIMATE,
		var1 = 5,
		var2 = 1,
		tics = (6*1),
	}
end
SafeFreeslot("S_SOAP_HITM_SHCKW")
states[S_SOAP_HITM_SHCKW] = {
    sprite = SPR_SOAP_HITMARK,
    frame = 37|FF_FULLBRIGHT|FF_ANIMATE|FF_ADD,
	var1 = 6,
	var2 = 1,
	tics = 7,
}

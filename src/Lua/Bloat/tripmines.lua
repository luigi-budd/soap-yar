local CV = SOAP_CV
CV.tripmines = CV_RegisterVar({
	name = "soap_tripmines",
	defaultvalue = "On",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_OnOff,
})
CV.tripmine_chance = CV_RegisterVar({
	name = "soap_tripmine_chance",
	defaultvalue = "6",
	flags = CV_SHOWMODIF|CV_NETVAR|CV_FLOAT,
	PossibleValue = {MIN = 1, MAX = 100*FU},
})

sfxinfo[SafeFreeslot("sfx_trpmn")] = {
	flags = SF_X8AWAYSOUND|SF_X4AWAYSOUND,
	caption = "/"
}

-- Sprites by @purp.porp
SafeFreeslot("SPR_NULLRING")
SafeFreeslot("S_NULLRING")
states[S_NULLRING] = {
	sprite = SPR_NULLRING,
	frame = A|FF_SEMIBRIGHT|FF_ANIMATE,
	var1 = 22,
	var2 = 1,
	tics = 23,
	nextstate = S_NULLRING,
	action = function(mo)
		mo.spritexscale = FU / 8
		mo.spriteyscale = mo.spritexscale
		mo.shadowscale = $ or FU
	end
}

SafeFreeslot("MT_TRIPMINE2")
mobjinfo[MT_TRIPMINE2] = {
	spawnstate = S_NULLRING,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_RUNSPAWNFUNC,
	spawnhealth = 1,
	doomednum = -1,
	radius = mobjinfo[MT_RING].radius,
	height = mobjinfo[MT_RING].height,
}

local rotlimit = 4
addHook("MobjThinker",function(m)
	if not (m and m.valid and m.health) then return end
	m.spritexscale = FU / 8
	m.spriteyscale = m.spritexscale
	m.flags2 = $|MF2_DONTDRAW
	
	if m.null_init == nil
		m.renderflags = $|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
		m.null_rot = FixedAngle(-rotlimit*FU + (rotlimit*2)*P_RandomFixed())
		if CV.rotations.value
			m.rollangle = FixedAngle(-90 + 180*P_RandomFixed())
		end
		-- m.shadowscale = $ * 4
		
		local offset = P_RandomRange(0, 20)
		m.frame = ($ &~FF_FRAMEMASK)|offset
		m.tics = $ - offset
		
		m.spawnpos = {
			x = m.x,
			y = m.y,
			z = m.z
		}
		P_SetOrigin(m, m.x,m.y,m.z)
		m.resetinterp = true
		
		m.null_init = true
	else
		m.flags2 = $ &~MF2_DONTDRAW
	end
	
	if CV.rotations.value
		m.rollangle = $ + m.null_rot
	end
	
	/*
	local pullrad = FixedMul(orgrad * 4, m.scale)
	--m.flags = $ &~MF_SPECIAL
	
	local pos = m.spawnpos
	for p in players.iterate
		if not (p.mo and p.mo.valid and p.mo.health) then continue end
		local me = p.mo
		
		local dist = R_PointTo3DDist(
			pos.x,pos.y, pos.z,
			me.x, me.y, me.z + me.height/2
		) - me.radius
		local mypull = pullrad
		if (p.pflags & PF_THOKKED)
			mypull = $ * 3
			if dist < mypull then dist = $ / 3; end
		end
		
		if dist < mypull
			local frac = FU - FixedDiv(dist, mypull)
			frac = ease.inquad($, 0, FU)
			
			P_MoveOrigin(m,
				P_Lerp(frac, pos.x, me.x),
				P_Lerp(frac, pos.y, me.y),
				P_Lerp(frac, pos.z, me.z + me.height/2)
			)
			m.rollangle = $ + FixedAngle(45 * frac)
			local frameoffset = (20 * frac) / FU
			m.frame = $ + frameoffset
			if (m.frame & FF_FRAMEMASK) > 22
				m.state = m.state
			else
				m.tics = $ - frameoffset
			end
			
			break
		end
	end
	*/
end, MT_TRIPMINE2)

local spawntypes = {MT_RING, MT_COIN} --, MT_FLINGRING}
for k, type in ipairs(spawntypes)
	addHook("MobjSpawn",function(m)
		if not CV.tripmines.value then return end
		if not P_RandomChance(FixedDiv(CV.tripmine_chance.value, 100*FU)) then return end
		m.origtype = m.type
		m.type = MT_TRIPMINE2
		m.state = S_NULLRING
	end, type)
end

states[SafeFreeslot("S_TMV_SHCK")] = {
	sprite = SPR_SOAP_BLOATVFX,
	frame = 7|FF_PAPERSPRITE|FF_FULLBRIGHT|FF_SUBTRACT|FF_ANIMATE,
	var1 = 11,
	var2 = 1,
	tics = 12,
	action = function(v)
		v.renderflags = $|RF_ALWAYSONTOP
	end
}

SafeFreeslot("S_TMV_SHCK2")
states[SafeFreeslot("S_TMV_SHCK2_WAIT")] = {
	sprite = SPR_NULL,
	frame = A,
	tics = TR/5 - 4,
	nextstate = S_TMV_SHCK2
}
states[S_TMV_SHCK2] = {
	sprite = SPR_SOAP_BLOATVFX,
	frame = 19|FF_PAPERSPRITE|FF_FULLBRIGHT|FF_ANIMATE|FF_ADD,
	var1 = 5,
	var2 = 2,
	tics = 12,
	action = function(v)
		v.renderflags = $|RF_ALWAYSONTOP
		v.colorized = true
		v.color = SKINCOLOR_MAGENTA
	end
}

states[SafeFreeslot("S_TMV_LINE")] = {
	sprite = SPR_SOAP_BLOATVFX,
	frame = 25|FF_PAPERSPRITE|FF_FULLBRIGHT|FF_ANIMATE,
	var1 = 6,
	var2 = 1,
	tics = 7,
	action = function(v)
		v.renderflags = $|RF_ALWAYSONTOP
		v.color = SKINCOLOR_MAGENTA
	end
}

states[SafeFreeslot("S_TMV_FLAIR")] = {
	sprite = SPR_SOAP_BLOATVFX,
	frame = 25|FF_PAPERSPRITE|FF_FULLBRIGHT|FF_ANIMATE|FF_ADD,
	var1 = 7,
	var2 = 2,
	tics = 16,
	action = function(v)
		v.renderflags = $|RF_ALWAYSONTOP
	end
}

local function T_PrimeVFX(mine, me)
	for k = 0, 1 -- LOL
		for i = 0,1
			for j = 0,1
				local v = P_SpawnMobjFromMobj(mine, 0,0,0, MT_PARTICLE)
				v.state = S_TMV_SHCK
				v.renderflags = $|(i and RF_HORIZONTALFLIP or 0)|(j and RF_VERTICALFLIP or 0)
				v.angle = mine.angle + (ANGLE_90 * k)
				v.scale = $ * 3
			end
		end
		
		local v = P_SpawnMobjFromMobj(mine, 0,0,0, MT_PARTICLE)
		v.state = S_TMV_SHCK2_WAIT
		v.angle = mine.angle + (ANGLE_90 * k) + ANGLE_45
		v.scale = $ * 4
	end
	
	-- k
	for i = 0,3
		local v = P_SpawnMobjFromMobj(mine, 0,0,0, MT_PARTICLE)
		v.state = S_TMV_FLAIR
		v.angle = mine.angle + (ANGLE_90 * i) + ANGLE_45
		v.scale = $ * 4
	end
	
	local offset = 800*FU
	local offsetspeed = -offset / (states[mobjinfo[MT_SOAP_SPEEDLINE].spawnstate].tics * 3/2)
	for i = 0,40
		local ha = FixedAngle(360 * P_RandomFixed())
		local va = FixedAngle(360 * P_RandomFixed())
		local of = Vec3.SphereToCartesian(ha,va) * offset
		local v = P_SpawnMobjFromMobj(mine, of.x,of.y,of.z, MT_PARTICLE)
		v.state = mobjinfo[MT_SOAP_SPEEDLINE].spawnstate
		v.renderflags = $|RF_ALWAYSONTOP
		v.color = SKINCOLOR_MAGENTA
		v.angle = ha + ANGLE_180
		v.rollangle = InvAngle(va)
		v.scale = $ * 4
		(Vec3.SphereToCartesian(ha,va) * offsetspeed):ToMobjMom(v)
	end

	local sfx = P_SpawnGhostMobj(me)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 12*TR
	sfx.tics = sfx.fuse
	S_StartSound(sfx, sfx_trpmn)
	S_StartSound(sfx, sfx_trpmn)
	
	P_FlashPal(me.player, PAL_INVERT, 2)
end

local function T_PrimeExplosion(mine, me)
	if not (me and me.valid and me.health) then return end
	local p = me.player
	
	mine.angle = R_PointToAngle2(mine.x,mine.y, me.x,me.y)
	T_PrimeVFX(mine, me)
	
	me.tripmine_death = TR / 5
	me.tripmine_mine = mine
	me.tripmine_minescale = mine.scale
	Soap_Hitlag.addHitlag(me, me.tripmine_death, true)
	Soap_Hitlag.addHitlag(mine, me.tripmine_death, false)
	
	-- mine.type = mine.origtype or MT_RING
end

addHook("MobjDeath", function(mine, _, me)
	T_PrimeExplosion(mine, me)
end, MT_TRIPMINE2)

local EXPLOSION_OUTER_RAD = 208*FU
local EXPLOSION_INNER_RAD = 80*FU
local EXPLOSION_OUTER_RFLAGS = RF_FULLBRIGHT|RF_NOCOLORMAPS
local EXPLOSION_INNER_RFLAGS = EXPLOSION_OUTER_RFLAGS|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
local function explosionVFX(mo, radius, angle, color)
	angle = $ or mo.angle
	color = $ or mo.color
	
	local bam = P_SpawnMobjFromMobj(mo, 0,0,0, MT_THOK)
	P_SetMobjStateNF(bam, S_TNTBARREL_EXPL3)
	bam.spritexscale = FixedDiv(radius, EXPLOSION_OUTER_RAD) * 2
	bam.spriteyscale = bam.spritexscale
	bam.renderflags = $|EXPLOSION_OUTER_RFLAGS
	bam.blendmode = AST_ADD
	bam.colorized = true
	bam.color = color
	
	for i = 0,2
		local outline = P_SpawnMobjFromMobj(mo, 0,0,0, MT_SOAP_WALLBUMP)
		outline.nothink = true
		outline.fusefade = 22
		outline.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIPTHING
		outline.fuse = 9
		outline.sprite = SPR_SOAP_GFX
		outline.frame = ($ &~FF_FRAMEMASK)|36
		outline.spritexscale = FixedDiv(radius, EXPLOSION_INNER_RAD) * 2
		outline.spriteyscale = outline.spritexscale
		outline.renderflags = $|EXPLOSION_INNER_RFLAGS
		outline.blendmode = AST_ADD
		outline.colorized = true
		outline.color = color
		outline.angle = angle + (ANGLE_90 * i)
		if i == 2
			outline.renderflags = $|RF_FLOORSPRITE &~RF_PAPERSPRITE
		end
	end
end

Takis_Hook.addHook("PostThinkFrame",function(p)
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if me.tripmine_blink
		me.tripmine_blink = $ - 1
	end
	if me.tripmine_dark
		me.tripmine_dark = $ - 1
	end
	
	if me.tripmine_death
		local mine = me.tripmine_mine
		
		me.tripmine_death = $ - 1
		if me.tripmine_death then return end
		
		local scale = me.tripmine_minescale
		
		Soap_StartQuake(620*FU, 8, me, 4096*scale * 2)
		Bloat_SpawnExplosions(me, {
			momz = 10*FU,
			count = 100,
			scale = scale,
			speed = 8*FU,
			color = SKINCOLOR_MAGENTA,
			fuse = 2*TR,
			fuselowbound = -15,
			fusehighbound = TR,
		})
		local scale = 3*scale
		local limit = 28
		for i = 0, 31
			local spark = P_SpawnMobjFromMobj(me,
				Soap_RandomFixedRange(-64*FU, 64*FU),
				Soap_RandomFixedRange(-64*FU, 64*FU),
				Soap_RandomFixedRange(0, 128*FU), MT_SOAP_WALLBUMP
			)
			P_SetScale(spark,scale / 10, true)
			spark.destscale = scale
			--5 tics
			spark.scalespeed = FixedDiv(scale - (scale / 10), 5*FU)
			spark.color = SKINCOLOR_MAGENTA
			spark.colorized = true
			--spark.mirrored = P_RandomChance(FU/2)
			spark.fuse = 6 * TR
			spark.startfuse = spark.fuse
			spark.flags = $|MF_NOGRAVITY
			spark.angle = FixedAngle(360 * P_RandomFixed())
			
			local speed = P_RandomRange(3, 8) * me.scale
			local ha,va = spark.angle, FixedAngle(P_RandomRange(-20,160)*FU)
			P_3DThrust(spark, ha,va, speed)
			
			spark.random = P_RandomRange(-limit,limit) * ANG1
			spark.movefactor = FU * 998/1000
		end
		for i = 0,6
			Soap_ImpactVFX(me,nil, 6*scale, Soap_RandomFixedRange(FU/4,4*FU), false,false, DMG_ELECTRIC)
		end
		if not (p.pflags & PF_GODMODE)
			P_KillMobj(me, mine,mine)
		end
		
		explosionVFX(me, 4096*scale / 30, 0, SKINCOLOR_MAGENTA)
		for play in players.iterate
			if not (play.realmo and play.realmo.valid) then continue end
			local dist = R_PointToDist2(play.realmo.x,play.realmo.y, me.x,me.y)
			if dist > 4096*2*scale then continue end
			
			play.mo.tripmine_blink = 10
			play.mo.tripmine_dark = 8*TR
			
			if (play.spectator) then continue end
			if (play.playerstate ~= PST_LIVE) then continue end
			if dist > 4096*scale / 30 then continue end
			play.mo.bell_overtuned = true
			P_KillMobj(play.mo, mine,mine)
		end
	end
end)

addHook("HUD",function(v,p)
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if me.tripmine_dark
		local trans = 0
		if me.tripmine_dark < 20
			trans = (10 - max(me.tripmine_dark/2, 1)) << V_ALPHASHIFT
		end
		--v.drawFill(0,0, v.width() / v.dupx(), v.height() / v.dupy(), 29|V_REVERSESUBTRACT|trans|V_SNAPTOLEFT|V_SNAPTOTOP)
		
		local pat = v.cachePatch("~024")
		local scalex = FixedDiv((v.width() / v.dupx())*FU, pat.width*FU)
		local scaley = FixedDiv((v.height() / v.dupy())*FU, pat.height*FU)
		v.drawStretched(0,0,
			scalex, scaley, pat,
			V_REVERSESUBTRACT|trans|V_SNAPTOLEFT|V_SNAPTOTOP
		)
	end
	
	if me.tripmine_blink
		local trans = (10 - (me.tripmine_blink)) << V_ALPHASHIFT
		--v.drawFill(0,0, v.width() / v.dupx(), v.height() / v.dupy(), 0|V_ADD|trans|V_SNAPTOLEFT|V_SNAPTOTOP)
		
		local pat = v.cachePatch("~000")
		local scalex = FixedDiv((v.width() / v.dupx())*FU, pat.width*FU)
		local scaley = FixedDiv((v.height() / v.dupy())*FU, pat.height*FU)
		v.drawStretched(0,0,
			scalex, scaley, pat,
			V_ADD|trans|V_SNAPTOLEFT|V_SNAPTOTOP
		)
	end
end,"game")
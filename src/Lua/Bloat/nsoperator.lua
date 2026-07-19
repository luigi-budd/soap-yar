local CV = SOAP_CV
CV.operator = CV_RegisterVar({
	name = "soap_operator",
	defaultvalue = "On",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_OnOff,
})
CV.operator_timeframe = CV_RegisterVar({
	name = "soap_operator_timeframe",
	defaultvalue = "30",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 900},
})

for i = 0,4
	sfxinfo[SafeFreeslot("sfx_nso"..i)].caption = "/"
end

local OP_STARTUP = TR * 3/4
local OP_REMOVE = TR
local OP_ACTIVE = 0
local OP_SUCCESS = 1
local function Op_Start(p)
	p.nsoper = {
		startup = OP_STARTUP,
		state = OP_ACTIVE,
		
		delay = 12,
		active = 0,
		ticks = 0,
		lockoutticks = 2,
		
		sign = 0,
		anganim = 0,
		
		inactive = 0,
	}
	
	S_StartSound(p.mo, sfx_nso0, p)
end

local function Op_Stop(p)
	p.nsoper.state = OP_SUCCESS
	p.nsoper.anganim = 15*FU
	p.nsoper.inactive = OP_REMOVE
	
	S_StopSoundByID(p.mo, sfx_nso0)
	S_StopSoundByID(p.mo, sfx_nso1)
	S_StopSoundByID(p.mo, sfx_nso2)
	S_StartSound(p.mo, sfx_nso3, p)
end

addHook("PlayerThink",function(p)
	if (leveltime and (leveltime % (CV.operator_timeframe.value*TR) == 0)
	and P_RandomChance(FU * 3/4))
	and not p.nsoper
	and CV.operator.value
	and (p.mo and p.mo.valid and p.mo.health)
		Op_Start(p)
	end
	if not p.nsoper then return end
	
	local op = p.nsoper
	op.startup = max($ - 1, 0)
	
	if op.state == OP_ACTIVE
		if op.delay
			op.delay = $ - 1
		else
			op.active = $ + 1
			op.anganim = P_Lerp(FU/2, $, 0)
			
			if op.active % 9 == 0
				if op.sign == 0
					op.sign = 1
				else
					op.sign = -$
				end
				op.anganim = 6*FU
				op.ticks = $ + 1
				op.lockoutticks = max($ - 1, 0)
				
				if op.ticks == 12
					Soap_Hitlag.addHitlag(p.mo, 12, true)
					P_FlashPal(p, PAL_INVERT, 12)
					P_KillMobj(p.mo)
					p.nsoper = nil
					
					S_StartSound(nil, sfx_nso4, p)
					Soap_ImpactVFX(p.mo, nil, nil,nil,nil,nil, DMG_ELECTRIC)
					return
				elseif op.ticks == 11
				elseif op.ticks == 10
					S_StartSound(p.mo, sfx_nso2, p)
				else
					S_StartSound(p.mo, sfx_nso1, p)
				end
			end
			
			if not op.lockoutticks
				local pass = false
				local cmd = p.cmd
				if (cmd.forwardmove == 0 and cmd.sidemove == 0)
				and (cmd.buttons & (BT_JUMP|BT_SPIN|BT_CUSTOM1|BT_CUSTOM2|BT_CUSTOM3|BT_ATTACK|BT_FIRENORMAL) == 0)
				and (p.pflags & (PF_THOKKED|PF_SPINNING|PF_STARTJUMP|PF_STARTDASH) == 0)
				and not (
					(p.panim == PA_ABILITY or p.panim == PA_ABILITY2)
					or (p.mo.state >= S_PLAY_SPINDASH and p.mo.state <= S_PLAY_MELEE_LANDING) 
				)
				and not (p.mo.hitlag)
					pass = true
				end
				
				if pass
					Op_Stop(p)
				end
			end
		end
	elseif op.state == OP_SUCCESS
		op.anganim = P_Lerp(FU/6, $, 0)
		op.ticks = 0
		op.inactive = $ - 1
		if op.inactive == 0
			p.nsoper = nil
		end
	end
end)

addHook("HUD",function(v,p)
	if not p.nsoper then return end
	
	local op = p.nsoper
	local offset = 0
	local fade = 0
	if op.startup
		offset = ease.outexpo(FU - FixedDiv(op.startup*FU, OP_STARTUP*FU), -200*FU, 0)
	end
	if op.inactive
		offset = $ - (OP_REMOVE - op.inactive) * FU / 4
		if op.inactive < 10
			fade = (10 - op.inactive) << V_ALPHASHIFT
		end
	end
	
	local patch = "NSOP_0"
	if op.ticks
		patch = "NSOP_1"
		if op.ticks == 11
			patch = "NSOP_3"
		elseif op.ticks == 10
			patch = "NSOP_2"
		end
	end
	
	local ang = (op.state == OP_ACTIVE) and 5*FU or 0
	v.dointerp(true)
	v.drawScaled(
		60*FU, 
		100*FU +offset+ (3*sin(FixedAngle(leveltime*FU * 3))), 
		FixedDiv(FU/10, FU/4),
		v.cachePatch(patch, FixedAngle((ang + op.anganim)*op.sign)), --FixedAngle(5*FU*(((leveltime/9)%2) and 1 or -1))),
		V_SNAPTOLEFT|fade
	)
	v.dointerp(false)
end)
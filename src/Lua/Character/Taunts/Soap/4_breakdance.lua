local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local tauntinfo = {}

tauntinfo.name = "Breakdance"
tauntinfo.cancelable = true

tauntinfo.run = function(p, me, soap, taunt)
	soap.stasistic = max($, 2)
	taunt.tics = 2
	
	me.momx,me.momy = p.cmomx,p.cmomy
end
tauntinfo.think = function(p, me, soap, taunt)
	if SoapTaunt_CancelWhen(p)
		if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
		end
		soap.stasistic, taunt.tics = 0,0
	else
		soap.stasistic = max($, 2)
		taunt.tics = 2
		
		soap.noability = SNOABIL_ALL &~SNOABIL_BREAKDANCE
	end
end
tauntinfo.drawer = function(v,i, x,y, selected, scale)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_BRDA,
		frame = F, angle = 2
	}, selected, scale)
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
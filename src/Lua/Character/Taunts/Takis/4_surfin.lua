local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local tauntinfo = {}

tauntinfo.name = "Surfin' Bird"
tauntinfo.cancelable = true

tauntinfo.run = function(p, me, soap, taunt)
	soap.stasistic = max($, 2)
	taunt.tics = 2
	
	me.momx,me.momy = p.cmomx,p.cmomy
	me.state = S_PLAY_SOAP_BREAKDANCE
	
	soap.breakdance = 0
end
tauntinfo.think = function(p, me, soap, taunt)
	if SoapTaunt_CancelWhen(p)
		if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
		end
		soap.stasistic, taunt.tics = 0,0
		return
	end
	
	soap.stasistic = max($, 2)
	taunt.tics = 2
	if me.state ~= S_PLAY_SOAP_BREAKDANCE
		me.state = S_PLAY_SOAP_BREAKDANCE
	end
	
	--init
	local timer = soap.breakdance % skins[p.skin].sprites[SPR2_BRDA].numframes
	me.frame = ($ &~FF_FRAMEMASK)|(timer)
	
	p.drawangle = (p.cmd.angleturn << 16) + ANGLE_180
	local incre_frame = (leveltime & 3) == 0
	if incre_frame
		soap.breakdance = $ + 1
	end
end
tauntinfo.drawer = function(v,i, x,y, selected)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_BRDA,
		frame = A, angle = 0
	}, selected)
end

SoapTaunt_AddTaunt(TAKIS_SKIN, tauntinfo)
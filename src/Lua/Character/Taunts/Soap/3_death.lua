local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_DUST
end
local function dust_noviewmobj(dust)
	dust.dontdrawforviewmobj = me
end
local tauntinfo = {}

tauntinfo.name = "Death"
tauntinfo.cancelable = true

tauntinfo.run = function(p, me, soap, taunt)
	me.state = S_PLAY_DEAD
	me.sprite2 = SPR2_MSC4
	me.tics = -1
	
	me.tempangle = p.drawangle
	S_StartSound(me,sfx_altdi1,p)
	S_StartSound(me,sfx_sp_smk,p)
	S_StartSound(me,sfx_s3k5d)
	Soap_DustRing(me,
		dust_type(me),
		P_RandomRange(8,14),
		{me.x,me.y,me.z},
		16*me.scale,
		me.scale*5,
		me.scale,
		me.scale/2,
		false, dust_noviewmobj
	)
	Soap_StartQuake(10*FU, 10, {me.x,me.y,me.z}, 256*me.scale)
	
	soap.stasistic = max($, 2)
	taunt.tics = 2
	
	me.momx,me.momy = p.cmomx,p.cmomy
end
tauntinfo.think = function(p, me, soap, taunt)
	if SoapTaunt_CancelWhen(p) or me.tempangle == nil
	or (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
		me.tempangle = nil
		if not (P_PlayerInPain(p) or me.state == S_PLAY_PAIN)
			me.state = S_PLAY_WALK
			P_MovePlayer(p)
			Soap_ResetState(p)
		end
		soap.stasistic, taunt.tics = 0,0
	else
		soap.stasistic = max($, 2)
		taunt.tics = 2
		
		p.drawangle = me.tempangle
		soap.noability = SNOABIL_ALL
		
		if me.state ~= S_PLAY_DEAD
			me.state = S_PLAY_DEAD
			me.tics = -1
		elseif me.sprite2 ~= SPR2_MSC4
			me.frame = $ &~FF_FRAMEMASK
			me.sprite2 = SPR2_MSC4
		end
	end
end
tauntinfo.postthink = function(p, me, soap, taunt)
	if me.tempangle == nil then return end
	p.drawangle = me.tempangle
end
tauntinfo.drawer = function(v,i, x,y, selected)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_MSC4,
		frame = A, angle = 2
	}, selected)
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
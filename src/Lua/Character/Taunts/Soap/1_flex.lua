local tauntinfo = {}

tauntinfo.name = "Flex"

tauntinfo.run = function(p, me, soap, taunt)
	S_StartSound(me, (me.skin == TAKIS_SKIN) and sfx_tk_whp or sfx_flex)
	me.state = S_PLAY_SOAP_FLEX
	soap.stasistic = TR
	if (me.skin == TAKIS_SKIN)
		soap.stasistic = $ / 2
		me.tics = $ / 2
	end
	taunt.tics = soap.stasistic
	
	me.momx,me.momy = p.cmomx,p.cmomy
end
tauntinfo.postthink = function(p, me, soap, taunt)
	local angle = (p.cmd.angleturn << 16)
	if soap.in2D then angle = ANGLE_90 end
	
	local angoff = ANGLE_90
	if (me.skin == TAKIS_SKIN)
		angoff = ANGLE_180
	end
	p.drawangle = angle + angoff
end
tauntinfo.drawer = function(v,i, x,y, selected, scale)
	SoapTaunt_WheelDrawer(v,i, x,y, {
		skin = skins[consoleplayer.skin].name,
		spr2 = SPR2_FLEX,
		frame = A, angle = 1
	}, selected, scale)
end

SoapTaunt_AddTaunt(SOAP_SKIN, tauntinfo)
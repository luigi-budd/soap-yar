addHook("HUD",function(v,p)
	if not (gametyperules & GTR_FRIENDLY) then return end
	local skin_name = skins[p.skin].name
	if not (skin_name == SOAP_SKIN or skin_name == TAKIS_SKIN) then return end
	
	local width = (v.width() / v.dupx())+1
	
	local str = "-- DEMO --   Not representative of final product.   -- DEMO --   Made by EpixGamer21   "
	local wid = v.stringWidth(str,0,"thin")/2
	local flags = V_REDMAP|V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_30TRANS|V_SNAPTOLEFT
	local offset = 4
	
	local marquee = leveltime % (wid)
	
	local w = width
	width = -($*2)
	marquee = $ - (w*2)
	while (width < w)
		v.drawString(marquee,
			200 - offset, str, flags, "small-thin")
		
		width = $ + wid
		marquee = $ + wid
	end
end,"game")
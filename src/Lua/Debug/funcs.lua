rawset(_G,"printf",function(fmt,...)
	print(string.format(fmt,...))
end)

local MAPBLOCKSHIFT = FRACBITS + 7
rawset(_G,"visualizeBlockmap",function(mo, fuse, x1,x2, y1,y2)
	local x1 = (x1 >> MAPBLOCKSHIFT) * 128*FU
	local x2 = (x2 >> MAPBLOCKSHIFT) * 128*FU
	local y1 = (y1 >> MAPBLOCKSHIFT) * 128*FU
	local y2 = (y2 >> MAPBLOCKSHIFT) * 128*FU
	local pos = {x1,x2, y1,y2}
	
	for i = 1, 2
		for j = 3,4
			local thisx = pos[i]
			local thisy = pos[j]
			local thisz = mo.z
			
			for k = -32,32
				local t = P_SpawnMobj(thisx, thisy, thisz + (4*FU*k), MT_THOK)
				t.spritexscale = $ / 2
				t.spriteyscale = t.spritexscale
				t.color = ColorOpposite(mo.color)
				t.blendmode = AST_ADD
				t.tics = fuse
				t.fuse = -1
				t.renderflags = $|RF_ALWAYSONTOP|RF_FULLBRIGHT
			end
		end
	end
end)

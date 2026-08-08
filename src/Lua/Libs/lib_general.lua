--[[
		Team Blue Spring's Series of Libaries.
		General Library - lib_general.lua

Contributors: Skydusk
@Team Blue Spring 2024
--]]

local TBSlib = {
	iteration = 6,
	string = '0.220',
}

-- #region Initiation

-- Alias
TBSlib.stringversion = TBSlib.string

local FRACUNIT = FRACUNIT
local FRACBITS = FRACBITS

local FixedSqrt = FixedSqrt
local FixedMul = FixedMul
local FixedDiv = FixedDiv

local asin = asin
local acos = acos

local sin = sin
local cos = cos
local tan = tan
local max = max
local min = min

local tostring = tostring
local tonumber = tonumber

local str_rep = string.rep
local table_insert = table.insert

---@alias alligment_types_tbs
---| '"left"'
---| '"center"'
---| '"right"'

-- #endregion
-- #region Drawers

-- Default fixed text drawer
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param leftadd 	number? int symbol padding
---@param symbol 	string? symbol used in padding
---@return void
function TBSlib.drawText(d, font, x, y, scale, text, flags, color, alligment, padding, leftadd, symbol)
	if text == nil then return end
	local str = text..""
	local fontoffset = 0
	local lenght = 0
	local cache = {}

	if leftadd then
		str = str_rep(symbol or ";", max(leftadd-#str, 0))..str
	end

	local maxv = #str

	for i = 1,maxv do
		local cur = TBSlib.cacheFont(d, patch, str, font, val, padding or 0, i)
		cache[i] = cur
		lenght = $+cur.width
	end

	x = FixedMul(x, scale)
	y = FixedMul(y, scale)

	if alligment == "center" then
		x = $-(lenght*scale >> 1)
	elseif alligment == "right" then
		x = $-lenght*scale
	end

	local drawer = d.drawScaled

	for i = 1,maxv do
		drawer(x+fontoffset*scale, y, scale, cache[i].patch, flags, color)
		fontoffset = $+cache[i].width
	end
end

-- Default fixed-point text drawer with no position adjustment to scale
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param leftadd 	number? int symbol padding
---@param symbol 	string? symbol used in padding
---@return void
function TBSlib.drawTextUnadjusted(d, font, x, y, scale, text, flags, color, alligment, padding, leftadd, symbol)
	if text == nil then return end
	local str = ''..text
	local fontoffset = 0
	padding = padding or 0

	local strlefttofill = (leftadd or 0)-#str
	if strlefttofill > 0 then
		str = str_rep(symbol or ";", strlefttofill)..str
	end

	local maxv = #str
	local lenght = 0
	local cache = {}

	for i = 1,maxv do
		local cur = TBSlib.cacheFont(d, patch, str, font, val, padding, i)
		table.insert(cache, cur)
		lenght = $+cur.width
	end

	if alligment == "center" then
		x = $-(lenght*scale >> 1)
	elseif alligment == "right" then
		x = $-lenght*scale
	end

	for i = 1,maxv do
		d.drawScaled(x+fontoffset*scale, y, scale, cache[i].patch, flags, color)
		fontoffset = $+cache[i].width
	end
end

-- Default integer text drawer with no position adjustment to scale
---@param d 		videolib
---@param font 		string
---@param x 		number 	integer
---@param y 		number 	integer
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param leftadd 	number? int symbol padding
---@param symbol 	string? symbol used in padding
---@return void
function TBSlib.drawTextInt(d, font, x, y, text, flags, color, alligment, padding, leftadd, symbol)
	if text == nil then return end
	local str = ''..text
	local fontoffset = 0
	padding = padding or 0

	local strlefttofill = (leftadd or 0)-#str
	if strlefttofill > 0 then
		str = str_rep(symbol or ";", strlefttofill)..str
	end

	local maxv = #str
	local lenght = 0
	local cache = {}

	for i = 1,maxv do
		local cur = TBSlib.cacheFont(d, patch, str, font, val, padding, i)
		table.insert(cache, cur)
		lenght = $+cur.width
	end

	if alligment == "center" then
		x = $-lenght >> 1
	elseif alligment == "right" then
		x = $-lenght
	end

	for i = 1,maxv do
		d.draw(x+fontoffset, y, cache[i].patch, flags, color)
		fontoffset = $+cache[i].width
	end
end

-- Simplified fixed-point text drawer
---@param v 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param padding 	number? int padding between numbers
---@return void
function TBSlib.drawTextSimple(v, font, x, y, scale, text, flags, color, padding)
	local draw, fontoffset, str = v.drawScaled, 0, ""..(text or "")

	x = FixedMul(x, scale)
	y = FixedMul(y, scale)

	for i = 1, #str do
		local cur = TBSlib.cacheFont(v, patch, str, font, val, padding or 0, i)
		draw(x + fontoffset*scale, y, scale, cur.patch, flags, color)

		fontoffset = $ + cur.width
	end
end

-- Simplified fixed-point text drawer with no position adjustment to scale
---@param v 		videolib
---@param font 		string
---@param x 		number 	fixed
---@param y 		number 	fixed
---@param scale 	number 	fixed
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param padding 	number? int padding between numbers
function TBSlib.drawTextSimpleUnadjusted(v, font, x, y, scale, text, flags, color, padding)
	local draw, fontoffset, str = v.drawScaled, 0, ""..(text or "")

	for i = 1, #str do
		local cur = TBSlib.cacheFont(v, patch, str, font, val, padding or 0, i)
		draw(x + fontoffset*scale, y, scale, cur.patch, flags, color)

		fontoffset = $ + cur.width
	end
end

-- Simplified integer text drawer
---@param v 		videolib
---@param font 		string
---@param x 		number 	integer
---@param y 		number 	integer
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param padding 	number? int padding between numbers
function TBSlib.drawTextSimpleInt(v, font, x, y, text, flags, color, padding)
	local draw, fontoffset, str = v.draw, 0, ""..(text or "")

	for i = 1, #str do
		local cur = TBSlib.cacheFont(v, patch, str, font, val, padding or 0, i)
		draw(x + fontoffset, y, cur.patch, flags, color)

		fontoffset = $ + cur.width
	end
end

-- Modifiable int text drawer
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param leftadd 	number? int symbol padding
---@param symbol 	string? symbol used in padding
---@param func 		function format: function(d, x, y, patch, flags, color, i)
---@return void
function TBSlib.drawTextModInt(d, font, x, y, text, flags, color, alligment, padding, leftadd, symbol, func)
	if not (text ~= nil and func) then return end
	local str = ''..text
	local fontoffset = 0
	padding = padding or 0

	local strlefttofill = (leftadd or 0)-#str
	if strlefttofill > 0 then
		str = str_rep(symbol or ";", strlefttofill)..str
	end

	local maxv = #str
	local lenght = 0
	local cache = {}

	for i = 1,maxv do
		local cur = TBSlib.cacheFont(d, patch, str, font, val, padding, i)
		table.insert(cache, cur)
		lenght = $+cur.width
	end

	if alligment == "center" then
		x = $-lenght >> 1
	elseif alligment == "right" then
		x = $-lenght
	end

	for i = 1,maxv do
		func(d, x+fontoffset, y, cache[i].patch, flags, color, i)
		fontoffset = $+cache[i].width
	end
end

-- Default fixed text drawer with y shift
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param shifty	number	int	shift by y position
---@param leftadd 	number? int symbol padding
---@param symbol 	string? symbol used in padding
---@return void
function TBSlib.drawTextShiftY(d, font, x, y, scale, text, flags, color, alligment, padding, shifty, leftadd, symbol)
	if text == nil then return end
	local str = ''..text
	local fontoffset = 0
	padding = padding or 0

	local strlefttofill = (leftadd or 0)-#str
	if strlefttofill > 0 then
		str = str_rep(symbol or ";", strlefttofill)..str
	end

	local maxv = #str
	local lenght = 0
	local cache = {}

	for i = 1,maxv do
		local cur = TBSlib.cacheFont(d, patch, str, font, val, padding, i)
		table.insert(cache, cur)
		lenght = $+cur.width
	end

	x = FixedDiv(x, scale)
	y = FixedDiv(y, scale)

	if alligment == "center" then
		x = $-(lenght*scale >> 1)
	elseif alligment == "right" then
		x = $-lenght*scale
	end

	for i = 1,maxv do
		d.drawScaled(x+fontoffset*scale, y, scale, cache[i].patch, flags, color)
		fontoffset = $+cache[i].width
		y = $+shifty
	end
end

-- Simplified fixed text drawer with y shift
---@param v 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param padding 	number? int padding between numbers
---@param shifty	number	int	shift by y position
---@return void
function TBSlib.drawTextSimpleShiftY(v, font, x, y, scale, text, flags, color, padding, shifty)
	local draw, fontoffset, str = v.drawScaled, 0, ""..(text or "")

	x = FixedMul(x, scale)
	y = FixedMul(y, scale)

	for i = 1, #str do
		local cur = TBSlib.cacheFont(v, patch, str, font, val, padding or 0, i)
		draw(x + fontoffset*scale, y, scale, cur.patch, flags, color)

		fontoffset = $ + cur.width
		y = $ + shifty
	end
end

-- Default fixed text drawer with y shift and no position adjusting to scale
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param shifty	number	int	shift by y position
---@param leftadd 	number? int symbol padding
---@param symbol 	string? symbol used in padding
---@return void
function TBSlib.drawTextUnadjustedShiftY(d, font, x, y, scale, text, flags, color, alligment, padding, shifty, leftadd, symbol)
	if text == nil then return end
	local str = ''..text
	local fontoffset = 0
	padding = padding or 0

	local strlefttofill = (leftadd or 0)-#str
	if strlefttofill > 0 then
		str = str_rep(symbol or ";", strlefttofill)..str
	end

	local maxv = #str
	local lenght = 0
	local cache = {}

	for i = 1,maxv do
		local cur = TBSlib.cacheFont(d, patch, str, font, val, padding, i)
		table.insert(cache, cur)
		lenght = $+cur.width
	end

	if alligment == "center" then
		x = $-(lenght*scale >> 1)
	elseif alligment == "right" then
		x = $-lenght*scale
	end

	for i = 1,maxv do
		d.drawScaled(x+fontoffset*scale, y, scale, cache[i].patch, flags, color)
		fontoffset = $+cache[i].width
		y = $+shifty
	end
end

local cachedText = {}

-- Static text drawer
-- Technically not static, use case is more so for stuff that simply is just plain unchanging text
-- Though it could be used for text as well, definitely not for constantly changing text, "once in longer term"
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@return void
function TBSlib.drawStaticText(d, font, x, y, scale, text, flags, color, alligment, padding)
	local storage = cachedText[font..'$'..tostring(text)]

	if not storage then
		local secured_text = tostring(text)
		storage = {}
		storage.lenght = 0

		for i = 1,#secured_text do
			local cur = TBSlib.cacheFont(d, patch, secured_text, font, val, padding or 0, i)
			storage[i] = {patch = cur.patch, fontoffset = storage.lenght}
			storage.lenght = $+cur.width
		end
	end

	x = FixedMul(x, scale)
	y = FixedMul(y, scale)

	if alligment == "center" then
		x = $ - (storage.lenght * scale >> 1)
	elseif alligment == "right" then
		x = $ - storage.lenght * scale
	end

	for i = 1,#storage do
		local char = storage[i]
		d.drawScaled(x + char.fontoffset * scale, y, scale, char.patch, flags, color)
	end
end

local function drawCroppedDim(v, x, y, scale, patch, flags, color, vec1_x, vec2_x, vec1_y, vec2_y)
	--if not (leveltime % 32) then print('\x82y:  '..FixedInt(y), 'x1: '..FixedInt(max(vec1_x-x, 0)), 'y1: '..FixedInt(max(vec1_y-y, 0))..' '..FixedInt(vec1_y), 'x2: '..FixedInt(max(vec2_x-x, 0)), 'y2: '..FixedInt(max(vec2_y-y, 0))..' '..FixedInt(vec2_y)) end
	v.drawCropped(x, y, scale, scale, patch, flags, color, max(vec1_x-x, 0), max(vec1_y-y, 0), max(vec2_x-x, 0), max(vec2_y-y, 0))
end

-- Static text drawer cropped
-- Technically not static, use case is more so for stuff that simply is just plain unchanging text
-- Though it could be used for text as well, definitely not for constantly changing text, "once in longer term"
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
---@param sx 		fixed_t
---@param sy 		fixed_t
---@param w 		fixed_t
---@param h 		fixed_t
---@return void
function TBSlib.drawStaticTextCropped(d, font, x, y, scale, text, flags, color, alligment, padding, sx, sy, w, h)
	local storage = cachedText[font..'$'..tostring(text)]

	if not storage then
		local secured_text = tostring(text)
		storage = {}
		storage.lenght = 0

		for i = 1,#secured_text do
			local cur = TBSlib.cacheFont(d, patch, secured_text, font, val, padding or 0, i)
			storage[i] = {patch = cur.patch, fontoffset = storage.lenght}
			storage.lenght = $+cur.width
		end
	end

	x = FixedMul(x, scale)
	y = FixedMul(y, scale)

	if alligment == "center" then
		x = $ - (storage.lenght * scale >> 1)
	elseif alligment == "right" then
		x = $ - storage.lenght * scale
	end

	for i = 1,#storage do
		local char = storage[i]
		d.drawCropped(x + char.fontoffset * scale, y, scale, scale, char.patch, flags, color, sx, sy, w, h)
	end
end

-- Static text drawer with no position adjustment
-- Technically not static, use case is more so for stuff that simply is just plain unchanging text
-- Though it could be used for text as well, definitely not for constantly changing text, "once in longer term"
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? int padding between numbers
function TBSlib.drawStaticTextUnadjusted(d, font, x, y, scale, text, flags, color, alligment, padding)
	local storage = cachedText[font..'$'..tostring(text)]

	if not storage then
		local secured_text = tostring(text)
		storage = {}
		storage.lenght = 0

		for i = 1,#secured_text do
			local cur = TBSlib.cacheFont(d, patch, secured_text, font, val, padding or 0, i)
			storage[i] = {patch = cur.patch, fontoffset = storage.lenght}
			storage.lenght = $+cur.width
		end
	end

	if alligment == "center" then
		x = $ - (storage.lenght * scale >> 1)
	elseif alligment == "right" then
		x = $ - storage.lenght * scale
	end

	for i = 1,#storage do
		local char = storage[i]
		d.drawScaled(x + char.fontoffset * scale, y, scale, char.patch, flags, color)
	end
end

-- Static text drawer
-- Technically not static, use case is more so for stuff that simply is just plain unchanging text
-- Though it could be used for text as well, definitely not for constantly changing text, "once in longer term"
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? 	byte
---@param color 	void? 		colormap_t
---@param alligment alligment_types_tbs
---@param padding 	number? 	int padding between numbers
---@param func 		function 	drawing function
---@return void
function TBSlib.drawStaticTextMod(d, font, x, y, scale, text, flags, color, alligment, padding, func)
	local storage = cachedText[font..'$'..tostring(text)]

	if not storage then
		local secured_text = tostring(text)
		storage = {}
		storage.lenght = 0

		for i = 1,#secured_text do
			local cur = TBSlib.cacheFont(d, patch, secured_text, font, val, padding or 0, i)
			storage[i] = {patch = cur.patch, fontoffset = storage.lenght}
			storage.lenght = $+cur.width
		end
	end

	x = FixedMul(x, scale)
	y = FixedMul(y, scale)

	if alligment == "center" then
		x = $ - (storage.lenght * scale >> 1)
	elseif alligment == "right" then
		x = $ - storage.lenght * scale
	end

	for i = 1,#storage do
		local char = storage[i]
		func(d, x + char.fontoffset * scale, y, scale, char.patch, flags, color, i)
	end
end

-- Default fixed text drawer with line breaking
---@param d 		videolib
---@param font 		string
---@param x 		fixed_t
---@param y 		fixed_t
---@param scale 	fixed_t
---@param text 		string?
---@param flags 	number? byte
---@param color 	void? 	colormap_t
---@param alligment alligment_types_tbs
---@param spacing 	number 	int padding between lines
---@return void
function TBSlib.drawLines(d, font, x, y, scale, text, flags, color, alligment, spacing)
	local text = ""..text
	local i = 0

	for breaks in text:gmatch("[^\r\n]+") do
		TBSlib.drawText(d, font, x, y+i*(spacing or 10)*scale, scale, breaks, flags, color, alligment)
		i = $+1
	end
end

TBSlib.ASCII = {}
local registeredFont = {}
for i = 0, 128 do
	TBSlib.ASCII[i] = string.char(i) or "NONE"
end

-- Register Font
---@param v 			videolib
---@param font 			string
---@param selectchar 	string?
---@return string
function TBSlib.registerFont(v, font, selectchar)
	registeredFont[font] = {}
	for byte, char in ipairs(TBSlib.ASCII) do
		local cache = registeredFont[font]

		local char_check = font..char
		if not v.patchExists(char_check) then
			local byte_check = font..byte

			if v.patchExists(byte_check) then
				cache[char] = v.cachePatch(byte_check)
			else
				cache[char] = v.cachePatch(font..'NONE')
			end
		else
			cache[char] = v.cachePatch(char_check)
		end
	end

	return registeredFont[font][selectchar]
end

-- Cache Font
---@param d 			videolib
---@param font 			string
---@param padding 		number
---@param i 			number  index
---@return table
function TBSlib.cacheFont(d, patch, str, font, val, padding, i)
	local char = str:sub(i, i)

	local symbol = registeredFont[font][char]
	and registeredFont[font][char]
	or TBSlib.registerFont(d, font, char)
	return {patch = symbol, width = symbol.width+padding}
end

-- Get lenght font
---@param d 			videolib
---@param font 			string
---@param padding 		number
---@param i 			number  index
---@return table
function TBSlib.getTextLenght(d, patch, str, font, val, padding, i)
	local char = str:sub(i, i)
	return (registeredFont[font] and registeredFont[font][char] or TBSlib.registerFont(d, font, char)).width+padding
end

-- Returns font table
---@param font 			string
---@return table
function TBSlib.returnFont(font)
	return registeredFont[font]
end

-- Caches range of graphic patches
---@param v 			videolib
---@param patch 		string
---@param start 		number
---@param ending 		number
---@return table
function TBSlib.registerPatchRange(v, patch, start, ending)
	local array = {}

	for i = start, ending do
		if v.patchExists(patch..i) then
			array[i] = v.cachePatch(patch..i)
		end
	end

	array._start = start
	array._end = ending

	return array
end

-- Picks one from range of graphic patches
---@param v 			videolib
---@param range 		table	patch_t array
---@param start 		number
---@param index 		number
---@return patch_t
function TBSlib.pickPatchRange(v, range, start, index)
	return range[max(min(index, #range), start)]
end

-- #endregion
-- #region Math

-- X^N
---@param x 	fixed_t 	value
---@param n 	number 		^n
---@return fixed_t
local function pow(x, n)
	local ogx = x
	for i = 1, (n-1) do
		x = FixedMul(x, ogx)
	end
	return x
end

-- X^N
---@param x 	fixed_t 	value
---@param n 	number 		^n
---@return fixed_t
function TBSlib.fixedPow(x, n)
	local ogx = x
	for i = 1, (n-1) do
		x = FixedMul(x, ogx)
	end
	return x
end

---@param x 	number 	value
---@param min_x number 	min
---@param max_x number 	max
---@return number
function TBSlib.clamp(x, min_x, max_x)
    return min(max(x, min_x), max_x)
end

---@param x 	number 	value
---@return number
function TBSlib.sign(x)
	if x > 0 then
		return 1
	else
		return -1
	end
end

---@param x 	number 	value
---@return number
function TBSlib.signZ(x)
	if x > 0 then
		return 1
	elseif x == 0 then
		return 0
	else
		return -1
	end
end


---@param x 	fixed_t 	value
---@return angle_t
function TBSlib.atan(x)
	local y = FRACUNIT + pow(x, 2)
	return asin(FixedDiv(x or FRACUNIT,FixedMul(y, FixedSqrt(y)) or FRACUNIT))
end

local atan = TBSlib.atan

---@param x 	fixed_t 	value
---@param y 	fixed_t 	value
---@return angle_t
TBSlib.atan2 = function(y,x)
    return atan(FixedDiv(y, x))
end

---@param jaw 	angle_t
---@param roll 	angle_t
---@param pitch angle_t
---@return angle_t directionXY
---@return angle_t zAngle
function TBSlib.projectToSlope(jaw, roll, pitch)
	local directionXY = TBSlib.atan2(sin(jaw), cos(jaw)) - roll

	local zAngle = TBSlib.atan2(sin(pitch), cos(pitch))

	return directionXY, zAngle
end

---@param t 	fixed_t 	delta
---@param a 	fixed_t? 	start
---@param b		fixed_t?	goal
---@return fixed_t
function TBSlib.lerp(t, a, b)
	return a + FixedMul(b - a, t)
end

--TBS's Fixedpoint interpretation of Roblox's lua doc interpretation's of Bezier's curve.
--Quadratic Bezier
---@param t 	fixed_t 	delta
---@param p0 	fixed_t? 	start
---@param p1	fixed_t?	mid
---@param p2	fixed_t?	goal
---@return fixed_t
function TBSlib.quadBezier(t, p0, p1, p2)
	return FixedMul(pow(FRACUNIT - t, 2), p0) + FixedMul(FixedMul(FRACUNIT - t, t), p1)<<1 + FixedMul(pow(t, 2), p2)
end

--Step by tip reach to destination
---@param curr_val 		number?
---@param dest_val 		number?
---@param step			number?
---@return number?
local function M_ReachDestination(curr_val, dest_val, step)
    local final_val = curr_val
	if final_val < dest_val then
        final_val = $ + step
        if final_val+step > dest_val then
            final_val = dest_val
        end
    elseif final_val > dest_val then
        final_val = $ - step
        if final_val-step < dest_val then
            final_val = dest_val
        end
    end
    return final_val
end

--Step by tip reach to destination
---@param curr_val 		number?
---@param dest_val 		number?
---@param step			number?
---@return number?
function TBSlib.reachNumber(curr_val, dest_val, step)
    return M_ReachDestination(curr_val, dest_val, step)
end

--Step by tip reach to destination
---@param curr_val 		angle_t
---@param dest_val 		angle_t
---@param step			angle_t
---@return angle_t
function TBSlib.reachAngle(curr_val, dest_val, step)
	local dif = dest_val - curr_val
	if dif > ANGLE_180 and dif <= ANGLE_MAX then
		dif = $ - ANGLE_MAX
	end

    return curr_val + M_ReachDestination(0, dif, step)
end

-- #endregion
-- #region Utilities

-- Gets simple checksum of string
---@param str string?
---@return number
function TBSlib.toCheckSum(str)
	local result = 0

	if str then
		for i = 1, #str do
			result = $ + string.byte(str, i, i)
		end
	end

	return result
end

-- Gets simple hex checksum of string
---@param str string?
---@return string
function TBSlib.toCheckSumHex(str)
	local result = 0

	if str then
		for i = 1, #str do
			result = $ + string.byte(str, i, i)
		end
	end

	return string.format('%x', ''..result)
end

-- Gets hexadecimal of value
---@param str string?
---@return string
function TBSlib.toHex(str)
	return string.format('%x', ''..str)
end

-- Gets value from hexadecimal value
---@param str string?
---@return number?
function TBSlib.fromHex(str)
	return tonumber('0x'..str)
end

---@param str string
---@return table?
function TBSlib.getBoolLine(str)
	local t = {}
	for i = 1, string.len(str) do
		table.insert(t, string.sub(str, i,i))
	end
	return t
end

---@param str string
---@return table?
function TBSlib.getBoolLineNum(str)
	local t = {}
	for i = 1, string.len(str) do
		table.insert(t, tonumber(string.sub(str, i,i)))
	end
	return t
end

---@param str string
---@param sep string seperator
---@return table?
function TBSlib.splitStr(str, sep)
	if sep == nil then return str end

	local result = {}
	for split in str:gmatch("([^"..sep.."]+)") do
		table.insert(result, split)
	end

	return result
end

---@param str string
---@param int number symbol position
---@return string
function TBSlib.charStr(str, int)
	return str:sub(int, int)
end

---@param str 	string
---@param enum 	table enum table
---@return number?
function TBSlib.toBitsString(str, enum)
	if not str then return 0 end
	local bits = 0

	for bit in str:gmatch("([^|]+)") do
		if not enum[bit] then continue end
		bits = $|enum[bit]
	end

	return bits
end

---@param str 	string
---@return table?
function TBSlib.parsePerLine(str)
	local result = {}

	for line in str:gmatch("[^\r\n]+") do
		if not line then continue end
		table.insert(result, line)
	end

	return result
end

---@param line 	string
---@return table?
function TBSlib.parseLine(line)
	local result = {}

	for w in line:gmatch("%S+") do
		if not w then continue end
		table.insert(result, w)
	end

	return result
end

---@param str 	string
---@return table?
function TBSlib.parse(str)
	local result = {}
	local i = 1

	for line in str:gmatch("[^\r\n]+") do
		if not line then continue end
		result[i] = {}

		for w in line:gmatch("%S+") do
			if not w then continue end
			table.insert(result[i], w)
		end
		i = $+1
	end

	return result
end

local write_series ---@type function

-- Recursive function used for Seralization
---@param current_tab 	table
---@param str 			string
---@param scope 		int
---@return string str
---@return number scope
local function write_series(current_tab, str, scope)
	if str and current_tab then
		str = $.."{".."\n"
		scope = $ or 1
		local white_space = string.rep("\t", scope)

		for k, v in pairs(current_tab) do
			local key = type(k) == "number" and "["..k.."]" or k

			if type(v) == "table" then
				if v then
					str = $..white_space..key.." = "
					scope = $+1
					str, scope = write_series(v, str, scope)
				else
					continue
				end
			else
				if v ~= nil then
					if type(v) == "boolean" then
						str = $..white_space..key.." = "..(v and "true" or "false")..",\n"
					elseif type(v) == "number" or type(v) == "string" then
						str = $..white_space..key.." = "..v..",\n"
					else
						continue
					end
				else
					continue
				end
			end
		end

		scope = $-1
		white_space = string.rep("\t", scope)
		str = $..white_space.."},".."\n"
		return str, scope
	end
end

-- Recursive function used for Seralization
---@param data 			table 	data table
---@param filepath 		string
---@param append 		string	appends
---@return boolean
---@return number
function TBSlib.serializeIO(data, filepath, append)
	local file = io.openlocal(filepath, "w")
	local serialization = write_series(data, append and ""..append or "")

	if file then
		file:write(serialization)
		file:close()

		return true, TBSlib.toCheckSum(serialization)
	end

	return false, TBSlib.toCheckSum(serialization)
end

-- Recursive function used for De-seralization
---@param filepath 		string
---@return table
function TBSlib.deserializeIO(filepath)
	local file = io.openlocal(filepath, "r")
	local n_table = {}
	local s_table = {}

	if file then
		file:seek("set")
		local cur_pos = 0
		for line in file:lines() do
			cur_pos = $+1
			if cur_pos == 1 then continue end

			local current = n_table
			if s_table then
				for y = 1, #s_table do
					current = current[s_table[y]]
				end
			end

			local parse = TBSlib.parseLine(line)

			local index = parse[1]
			if index:find("%[") and index:find("%]") then
				index = index:gsub("%[", "")
				index = index:gsub("%]", "")
				index = tonumber(index)
			end

			if line:find("{") then
				current[index] = {}
				table.insert(s_table, index)
			elseif line:find("}") then
				if not s_table then
					break
				end
				table.remove(s_table)
			else
				local val = string.gsub(parse[3], ",", "")
				if type(tonumber(val)) == "number" then
					current[index] = tonumber(val)
				elseif val == "true" then
					current[index] = true
				elseif val == "false" then
					current[index] = false
				else
					current[index] = val
				end
			end
		end
		file:close()
	end

	return n_table
end

---@param table table
---@param index number
---@return number 	new_index
---@return table 	table
function TBSlib.scrollTable(table, index)
	if index < 1 then
		index = #table + index
	end

	local new_index = ((index - 1) % #table) + 1

	return new_index, table[new_index]
end

-- https://stackoverflow.com/questions/1761626/weighted-random-numbers
---@param weights table
function TBSlib.randomizerWeights(weights)
	local sum_weights = 0

	for i = 1, #weights do
		sum_weights = $ + weights[i].weight
	end

	local random = P_RandomKey(sum_weights)
	for i = 1, #weights do
		if random < weights[i].weight then
			return weights[i]
		end

		sum_weights = $ - weights[i].weight
	end

	return weights[i]
end

-- #endregion
-- #region Gameplay Utilities

-- shoots a fake ray, in direction of choosing.
---@param origin	mobj_t?	can be just table
---@param angleh	angle_t horizontal
---@param anglev	angle_t vertical
---@return table
function TBSlib.ray(origin, angleh, anglev)
	if not (origin and origin == {} and origin.x and origin.y and origin.z and angleh and anglev) then return end

	local ray = P_SpawnMobj(origin.x, origin.y, origin.z, MT_RAY)
	P_TeleportMove(origin.x, origin.y, origin.z+P_ReturnThrustY(ray, anglev, INT8_MAX))
	P_InstaThrust(ray, angleh, INT8_MAX)
	ray.fuse = 2

	return {ray.x, ray.y, ray.z}
end

--[[
Example dataset:

local MushroomAnimation = {
	[0] = {offscale_x = 0, offscale_y = 0, tics = 4, nexts = 1},
	[1] = {offscale_x = 0, offscale_y = 0, tics = 3, nexts = 2},
	[2] = {offscale_x = -(FRACUNIT >> 3), offscale_y = (FRACUNIT >> 4), tics = 4, nexts = 3},
	[3] = {offscale_x = (FRACUNIT >> 3), offscale_y = -(FRACUNIT >> 4), tics = 3, nexts = 0},
}
--]]
---@param a			mobj_t?		object
---@param data_set	table		state table
---@return void
function TBSlib.scaleAnimator(a, data_set)
	if not a.animator_data then
		a.animator_data = {tics = 0, state = 0}
	end
	local data = data_set
	local cur_state = data[a.animator_data.state]
	local next_state = data[cur_state.nexts]
	local progress = (FRACUNIT/cur_state.tics)*a.animator_data.tics

	a.spritexscale = FRACUNIT+ease.outsine(progress, cur_state.offscale_x, next_state.offscale_x)
	a.spriteyscale = FRACUNIT+ease.outsine(progress, cur_state.offscale_y, next_state.offscale_y)

	a.animator_data.tics = $+1
	if a.animator_data.tics == cur_state.tics then
		a.animator_data.state = cur_state.nexts
		a.animator_data.tics = 0
	end
end

---@param a			mobj_t?		object
function TBSlib.resetAnimator(a)
	a.animator_data = {tics = 0, state = 0}
	a.spritexscale = FRACUNIT
	a.spriteyscale = FRACUNIT
end

---@param array table array of mobj_t
function TBSlib.removeMobjArray(array)
	for _,mo in ipairs(array) do
		P_RemoveMobj(mo)
	end
end

---@param a			mobj_t?		object
---@param data_set	table		state table
function TBSlib.objAnimator(a, data_set)
	if not a.animator_data then
		a.animator_data = {tics = 0, state = 0}
	end
	if a.animator_data.disable then return end

	local data = data_set
	local cur_state = data[a.animator_data.state]
	local waittill = cur_state.waittill

	if not waittill or a.animator_data.waited or (waittill and waittill(a, a.animator_data)) then
		a.animator_data.waited = true

		local next_state = data[cur_state.nexts]
		local progress = (FRACUNIT/cur_state.tics)*a.animator_data.tics
		local func = cur_state.func

		if cur_state.offscale_x and next_state.offscale_x then
			a.spritexscale = FRACUNIT+ease.outsine(progress, cur_state.offscale_x, next_state.offscale_x)
		end

		if cur_state.offscale_y and next_state.offscale_y then
			a.spriteyscale = FRACUNIT+ease.outsine(progress, cur_state.offscale_y, next_state.offscale_y)
		end

		a.animator_data.tics = $+1
		if a.animator_data.tics == cur_state.tics then
			if cur_state.nexts == nil then
				a.animator_data.disable = true
			else
				a.animator_data.waited = false
				a.animator_data.state = cur_state.nexts
				a.animator_data.tics = 0
				if func then
					func(a, a.animator_data)
				end
			end
		end
	end
end

---@param poly 		table array of points of polygon
---@param angle 	angle_t
---@param offset_x 	fixed_t
---@param offset_y	fixed_t
---@return table
local function Rotate2D_Polygon(poly, angle, offset_x, offset_y)
	local cosine = cos(angle)
	local sine = sin(angle)

	local points = poly
	local point_data = {}
	for i = 1, #points, 2 do
		point_data[i] = offset_x + FixedMul(points[i], cosine) - FixedMul(points[i+1], sine)
		point_data[i+1] = offset_y + FixedMul(points[i], sine) + FixedMul(points[i+1], cosine)
	end
	return point_data
end

-- https://stackoverflow.com/questions/67719116/check-if-a-given-point-is-within-the-boundary-of-the-rotated-element
-- Referenced from answer of Blindman67
---@param line table<table<number, number>>
---@param point table<number, number>
---@return number
function TBSlib.isPointLeft(line, point)
	return (0 < (FixedMul(line[2].x - line[1].x, point.y - line[1].y) - FixedMul(line[2].y - line[1].y, point.x - line[1].x)))
end

---@param poly 		table array of points of polygon
---@param x 	fixed_t x of object
---@param y		fixed_t y of object
---@return boolean
local function isPointInPolygon(x, y, poly)
	-- poly is a Lua list of pairs like {x1, y1, x2, y2, ... xn, yn}

	local x1, y1, x2, y2
	local len = #poly
	x2, y2 = poly[len - 1], poly[len]
	local wn = 0
	for idx = 1, len, 2 do
		x1, y1 = x2, y2
		x2, y2 = poly[idx], poly[idx + 1]

		if y1 > y then
			if (y2 <= y) and FixedMul(x1 - x, y2 - y) < FixedMul(x2 - x, y1 - y) then
				wn = wn + 1
			end
		else
			if (y2 > y) and FixedMul(x1 - x, y2 - y) > FixedMul(x2 - x, y1 - y) then
				wn = wn - 1
			end
		end
	end

	return wn % 2 ~= 0 -- even/odd rule
end

---@param mobj 		mobj_t
---@param obj 		mobj_t
---@param x_radius 	fixed_t
---@param y_radius	fixed_t
---@param angle 	angle_t
---@return boolean
function TBSlib.rectangleCollidor(mobj, obj, x_radius, y_radius, angle)
	local poly = {
		x_radius, y_radius,
		-x_radius, y_radius,
		-x_radius, -y_radius,
		x_radius, -y_radius,
	}
	
	local placed = Rotate2D_Polygon(poly, angle, obj.x, obj.y)
	return isPointInPolygon(mobj.x, mobj.y, placed)
end

---@param mobj 				mobj_t
---@param obj 				mobj_t
---@param horizontal_poly 	table
---@param vertical_poly		table
---@param jaw 				angle_t
---@param pitch 			angle_t
---@return boolean
function TBSlib.rectangle2D3DCollidor(mobj, obj, horizontal_poly, vertical_poly, jaw, pitch)
	local horizontal_plane = Rotate2D_Polygon(horizontal_poly, jaw, obj.x, obj.y)

	local cosine = cos(jaw)
	local sine = sin(jaw)

	local obj_horizontal_pos = FixedMul(obj.x, cosine) - FixedMul(obj.y, cosine)
	local mobj_horizontal_pos = FixedMul(mobj.x, sine) - FixedMul(mobj.y, sine)

	local vertical_plane = Rotate2D_Polygon(vertical_poly, pitch, obj_horizontal_pos, obj.z)
	return isPointInPolygon(mobj.x, mobj.y, horizontal_plane) and isPointInPolygon(mobj_horizontal_pos, mobj.z, vertical_plane)
end

-- #endregion

rawset(_G, "TBSlib", TBSlib)

return TBSlib
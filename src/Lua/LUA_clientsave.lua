--Saves (and loads) client-side cvars
--TODO: cvar onchange funcs that send commands
--		to change soaptable as IO
local CV = SOAP_CV
local filepath = "client/soapyar/clientcvars.dat"
local cv_save = {
	CV.ai_style.name,
	CV.quake_mul.name,
}
local function printf(...)
	for k,str in ipairs({...})
		print("\x83SOAP (I/O)\x80: "..str)
	end
end

--load
do
	local file = io.openlocal(filepath, "r")
	if file
		-- while this is meant to load client-side cvars,
		-- we'll also save and load our synched cvars here, and send
		-- the data on our PlayerJoin
		printf("Loading preferences from '"..filepath.."'...")
		local count = 1
		local cvarname = ''
		for line in file:lines()
			--Load values every other line
			if count % 2 == 0
				local cvar = CV.FindVar(cvarname)
				if cvar and cvarname:sub(1,4) == "soap"
					CV_Set(cvar, line)
				else
					printf("Bad cvar name '"..cvarname.."'")
				end
				count = $ + 1
				continue
			end
			cvarname = line
			count = $ + 1
		end
		file:close()
		printf("Done.")
	end
end

--save
addHook("GameQuit",do
	local file = io.openlocal(filepath, "w+")
	for k, cvname in ipairs(cv_save)
		local cv = CV.FindVar(cvname)
		file:write(tostring(cvname).."\n")
		file:write(tostring(cv.string).."\n")
	end
	file:flush()
	file:close()
end)
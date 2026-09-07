--this file is completely reusable if you wanna add compat for
--takis and soap for your mod, just make sure you keep the existing event types
--not my code anyway lol, its unmatched_brackets (AND JISKS) from PTSR and EPIC!MM

if not rawget(_G,"Takis_Hook")
	rawset(_G, "Takis_Hook", {})
	Takis_Hook.events = {}
	Takis_Hook.disabled = {}
	
	--Dont "expose" deprecated hooks
end

addHook("NetVars",function(n)
	Takis_Hook.disabled = n($)
end)

local debug = dofile("Vars/debugflag.lua")

/*
	return value: Boolean (override default behavior?)
	true = override, otherwise hook is ran then the default function after
*/
local handler_snaptrue = {
	func = function(current, ...)
		local arg = {...}
		return (#arg and true or false) or current
	end,
	initial = false
}

/*
	if true, then the default func will run
	if false, then the default func will be forced to not run
	if nil, use the default behavior
	...generally
*/
local handler_snapany = {
	func = function(current, ...)
		local arg = {...}
		if #arg then
			return unpack(arg)
		else
			return current ~= nil and unpack(current) or nil
		end
	end,
	initial = nil
}
local handler_default = handler_snaptrue

local typefor_mobj = function(this_mobj, ...)
	local arg = {...}
	local type = (#arg and arg[1] or nil)
	if (type == nil)
		return true
	end
	return this_mobj.type == type
end

local events = {}
events["CanPlayerHurtPlayer"] = {handler = handler_snapany}
events["CanFlingThing"] = {handler = handler_snapany, typefor = typefor_mobj}
events["PreThinkFrame"] = {}
events["PostThinkFrame"] = {}
events["MoveBlocked"] = {handler = handler_snapany} --runs for every skin

events["Soap_Thinker"] = {}

events["Takis_Thinker"] = {}

-- hooks for BOTH skins
events["Char_OnMove"] = {}
events["Char_NoAbility"] = {handler = handler_snapany}
events["Char_VFX"] = {handler = handler_snapany}
events["Char_OnDamage"] = {handler = handler_snaptrue}
events["Char_OnStunEnemy"] = {typefor = typefor_mobj}
events["Char_StunnedThink"] = {typefor = typefor_mobj}

local deprecated = {
	["Soap_OnMove"] = {
		correct = "Char_OnMove",
		seen = false,
	},
	["Soap_NoAbility"] = {
		correct = "Char_NoAbility",
		seen = false,
	},
	["Soap_VFX"] = {
		correct = "Char_VFX",
		seen = false,
	},
	["Takis_VFX"] = {
		correct = "Char_VFX",
		seen = false,
	},
	["Soap_OnStunEnemy"] = {
		correct = "Char_OnStunEnemy",
		seen = false,
	},
	["Soap_StunnedThink"] = {
		correct = "Char_StunnedThink",
		seen = false,
	},
}

--check for new events...
for event_name, event_t in pairs(events)
	if (Takis_Hook.events[event_name] == nil)
		if event_t.events == nil
			event_t.events = {}
			event_t.numhooks = 0
		end
		Takis_Hook.events[event_name] = event_t
		print("\x83TAKIS:\x80 Adding new hookevent... (\""..event_name..'")')
	else
		print("\x83TAKIS:\x80 Hooklib found an existing hookevent, not adding. (\""..event_name..'")')
	end
end

-- optional name argument if you want to name a hook
-- in case it errors
Takis_Hook.addHook = function(hooktype, func, typefor, name)
	local TH_events = Takis_Hook.events
	local event_t = TH_events[hooktype]
	
	local hook_okay = event_t ~= nil
	local dep_t = nil
	if not hook_okay
		hook_okay = deprecated[hooktype] ~= nil
		dep_t = deprecated[hooktype]
	end
	
	if hook_okay then
		if dep_t ~= nil
			if not dep_t.seen
				print("\x83TAKIS: \x82WARNING:\x80 Hook type \""..hooktype.."\" has been deprecated and will be removed. Use \""..dep_t.correct.."\" instead.")
				S_StartSound(nil,sfx_skid)
			end
			event_t = TH_events[dep_t.correct]
		end
		
		table.insert(event_t.events, {
			func = func,
			typedef = typefor,
			name = name or "anonymous hook",
			
			errored = false,
			
			-- debugging
			id = event_t.numhooks,
			src = edit_lumpname or "???",
			us_taken = 0, -- microseconds
			activity = 0,
			tic_called = -1,
		})
		event_t.numhooks = $ + 1
	else
		S_StartSound(nil,sfx_skid)
		error("\x83TAKIS: \x82WARNING:\x80 Hook type \""..hooktype.."\" does not exist.", 2)
	end
end

local work_hooktype = nil
local work_event = nil
local function ErrorCatcher(err)
	if work_event.errored then return end
	work_event.errored = true
	
	S_StartSound(nil,sfx_lose)
	print(
		("\x83TAKIS: \x82WARNING:\x80 Error in hooktype '%s' for hook '%s'\n\t\x86-> %s"):format(
			work_hooktype, work_event.name, err
		)
	)
end
Takis_Hook.tryRunHook = function(hooktype, v, ...)
	local TH_events = Takis_Hook.events
	local handler = TH_events[hooktype].handler or handler_default
	local override = handler.initial
	local debugmode = (debug and (SOAP_DEBUG & DEBUG_HOOKS))
	local starttime
	
	if (debugmode and Takis_Hook.disabled[hooktype] == true)
		return
	end
	if debugmode then starttime = getTimeMicros(); end
	
	work_hooktype = hooktype
	work_event = v
	local args = {...}
	local results = {xpcall(do
		v.func(unpack(args))
	end, ErrorCatcher)}
	local status = table.remove(results,1)
	
	if status then
		override = {handler.func(
			override,
			unpack(results)
		)}
	end

	if debugmode
		local taken = (getTimeMicros() - starttime)
		if v.tic_called == leveltime
			v.us_taken = $ + taken
		else
			v.us_taken = taken
		end
		v.activity = min($ + taken, TR)
		v.tic_called = leveltime
	end
	
	if override == nil then return nil; end
	if type(override) == "table" then return unpack(override)
	else return override; end
end
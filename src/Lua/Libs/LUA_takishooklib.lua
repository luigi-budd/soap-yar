--this file is completely reusable if you wanna add compat for
--takis and soap for your mod, just make sure you keep the existing event types
--not my code anyway lol, its unmatched_brackets (AND JISKS) from PTSR and EPIC!MM

if not rawget(_G,"Takis_Hook")
	rawset(_G, "Takis_Hook", {})
	Takis_Hook.events = {}
	
	--Dont "expose" deprecated hooks
end

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
events["Soap_DashSpeeds"] = {handler = handler_snapany}
events["Soap_OnStunEnemy"] = {typefor = typefor_mobj}
events["Soap_StunnedThink"] = {typefor = typefor_mobj}

events["Takis_Thinker"] = {}

-- hooks for BOTH skins
events["Char_OnMove"] = {}
events["Char_NoAbility"] = {handler = handler_snapany}
events["Char_VFX"] = {handler = handler_snapany}
events["Char_OnDamage"] = {handler = handler_snaptrue}

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
}

--check for new events...
for event_name, event_t in pairs(events)
	if (Takis_Hook.events[event_name] == nil)
		Takis_Hook.events[event_name] = event_t
		print("\x83TAKIS:\x80 Adding new hookevent... (\""..event_name..'")')
	else
		print("\x83TAKIS:\x80 Hooklib found an existing hookevent, not adding. (\""..event_name..'")')
	end
end

Takis_Hook.addHook = function(hooktype, func, typefor)
	local hook_okay = Takis_Hook.events[hooktype] ~= nil
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
			hooktype = dep_t.correct
		end
		
		table.insert(Takis_Hook.events[hooktype], {
			func = func,
			typedef = typefor,
			errored = false,
			id = #Takis_Hook.events[hooktype]
		})
	else
		S_StartSound(nil,sfx_skid)
		error("\x83TAKIS: \x82WARNING:\x80 Hook type \""..hooktype.."\" does not exist.", 2)
	end
end

Takis_Hook.tryRunHook = function(hooktype, v, ...)
	local handler = Takis_Hook.events[hooktype].handler or handler_default
	local override = handler.initial

	local results = {pcall(v.func, ...)}
	local status = results[1] or nil
	table.remove(results,1)
	
	if status then
		override = {handler.func(
			override,
			unpack(results)
		)}
	elseif (not v.errored) then
		v.errored = true
		S_StartSound(nil,sfx_lose)
		print("\x83TAKIS: \x82WARNING:\x80 Hook " .. hooktype .. " handler #" .. i .. " error:")
		print(unpack(results))
	end
	
	if override == nil then return nil; end
	if type(override) == "table" then return unpack(override)
	else return override; end
end

local notvalid = {}
Takis_Hook.findEvent = function(hooktype)
	local name = hooktype
	local events = Takis_Hook.events[name]
	
	if events == nil
	and deprecated[hooktype] ~= nil
		name = deprecated[hooktype].correct
		events = Takis_Hook[name]
	end
	
	if events == nil
	and not (notvalid[name])
		notvalid[name] = true
		print('\x83TAKIS:\x82WARNING\x80: could not find hookevent "'..hooktype..'"')
	end
	
	--can still return nil!
	return events, name
end
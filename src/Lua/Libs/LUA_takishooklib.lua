--this file is completely reusable if you wanna add compat for
--takis and soap for your mod, just make sure you keep the existing event types
--not my code anyway lol, its unmatched_brackets (AND JISKS) from PTSR and EPIC!MM

if not rawget(_G,"Takis_Hook")
	rawset(_G, "Takis_Hook", {})
	Takis_Hook.events = {}
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
events["Soap_NoAbility"] = {handler = handler_snapany}
events["Soap_DashSpeeds"] = {handler = handler_snapany}
events["Soap_OnStunEnemy"] = {typefor = typefor_mobj}
events["Soap_StunnedThink"] = {typefor = typefor_mobj}
events["Soap_OnMove"] = {}
events["Soap_VFX"] = {handler = handler_snapany}

events["Takis_Thinker"] = {}
events["Takis_VFX"] = {handler = handler_snapany}

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
	if Takis_Hook.events[hooktype] then
		table.insert(Takis_Hook.events[hooktype], {
			func = func,
			typedef = typefor,
			errored = false
		})
	else
		error("\x83TAKIS: \x82WARNING:\x80 Hook type \""..hooktype.."\" does not exist.", 2)
	end
end

Takis_Hook.tryRunHook = function(hooktype, v, ...)
	local handler = Takis_Hook.events[hooktype].handler or handler_default
	local override = handler.initial

	local results = {pcall(v.func, ...)}
	local status = results[1] or nil
	table.remove(results,1)
	
	if status ~= false then
		override = {handler.func(
			override,
			unpack(results)
		)}
	elseif (status == false) and (not v.errored) then
		v.errored = true
		S_StartSound(nil,sfx_lose)
		print("\x83TAKIS: \x82WARNING:\x80 Hook " .. hooktype .. " handler #" .. i .. " error:")
		print(result)
	end
	
	if override == nil then return nil; end
	return unpack(override)
end
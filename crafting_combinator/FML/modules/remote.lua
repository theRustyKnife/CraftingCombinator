local FML = require "therustyknife.FML"


if FML.STAGE ~= "runtime" then return nil; end


local function get_function_internal(clbck)
--[[ Get the interface function without checking if it exists. ]]
	return function(...) return remote.call(clbck.interface, clbck.func, ...); end
end

local function get_function_safe_internal(clbck)
--[[ Get the interface function as a safe function. ]]
	return function(...)
		if remote.interfaces[interface] and remote.interfaces[interface][func] then
			return remote.call(clbck.interface, clbck.func, ...)
		end
	end
end


local _M = {}
local _DOC = FML.make_doc(_M, {
	type = "module",
	name = "remote",
	desc = [[ Allows easy access to functions through the remote API. ]],
	notes = {[[
	The functions returned from here are mostly closures, so they're not safe for serialization. To serialize an interface
	function, use the Callback concept. To serialize an interface, simply store it's name as a string.
	]]}
})


_DOC.get_interface = {
	type = "function",
	short_desc = [[ Return all functions from an interface. ]],
	desc = [[
	Return all functions from an interface. If the interface doesn't exist, nil is returned. If safe is true, an
	empty table is returned instead.
	]],
	notes = {"Only functions that are currently present in the interface are taken into account, even if safe is true."},
	params = {
		{
			type = "string",
			name = "interface",
			desc = "The interface name",
		},
		{
			type = "bool",
			name = "safe",
			desc = "If true, safe functions are returned",
		},
	},
	returns = {
		{
			type = "Dictionary[string: function]",
			desc = "The interface represented by a table of functions",
		},
	},
}
function _M.get_interface(interface, safe)
	if not remote.interfaces[interface] then return safe and {} or nil; end
	local res = {}
	for func, _ in pairs(remote.interfaces[interface]) do
		if safe then
			res[func] = get_function_safe_internal{interface = interface, func = func}
		else
			res[func] = get_function_internal{interface = interface, func = func}; end
	end
	return res
end


_DOC.get_function_safe = {
	type = "function",
	short_desc = [[ Return a function representing the given Callback. ]],
	desc = [[
	Return a function representing the given Callback. This function is safe to call even if the interface function is
	not currently available. Additionally, the function is returned even if the interface doesn't exist (yet), so
	calling it should always be safe.
	]],
	params = {
		{
			type = "Callback",
			name = "clbck",
			desc = "The function to get",
		},
	},
	returns = {
		{
			type = "function(...)",
			desc = "The safe function",
		},
	},
}
function _M.get_function_safe(clbck)
	return get_function_safe_internal(clbck)
end

_DOC.get_function = {
	type = "function",
	short_desc = [[ Get a function from an interface. ]],
	desc = [[ Get a function from an interface. If the interface doesn't exist, nil will be returned. ]],
	notes = {"If the interface is removed, calling this function will crash."},
	params = {
		{
			type = "Callback",
			name = "clbck",
			desc = "The function to get",
		},
	},
	returns = {
		{
			type = "function(...)",
			desc = "The function",
		},
	},
}
function _M.get_function(clbck)
	if not remote.interfaces[clbck.interface] or not remote.interfaces[clbck.interface][clbck.func] then return nil; end
	
	return get_function_internal(clbck)
end


local function _callback_call_method(clbck, ...) return remote.call(clbck.interface, clbck.func, ...); end
local RICH_MT = {__call = _callback_call_method}

_DOC.enrich_callback = {
	type = "function",
	short_desc = [[ Give the Callback a call method. ]],
	desc = [[ Give the Callback a call method. This method is probably not serialization-safe. ]],
	notes = {[[
		The callback is also given a metatable that allows you to call it directly. This metatable is lost during
		serialization entirely.
	]]},
	params = {
		{
			type = "Callback",
			name = "clbck",
			desc = "The Callback to enrich",
		},
	},
	returns = {
		{
			type = "RichCallback",
			desc = "The enriched Callback. It is the isntance that was passed in"
		},
	},
}
function _M.enrich_callback(clbck)
	clbck.call = _callback_call_method
	setmetatable(clbck, RICH_MT)
	return clbck
end

_DOC.get_rich_callback = {
	type = "function",
	desc = [[ Construct a Callback that is already rich. ]],
	params = {
		{
			type = "string",
			name = "interface",
			desc = "The interface the Callback will represent",
		},
		{
			type = "string",
			name = "func",
			desc = "The function the Callback will represent",
		},
	},
	returns = {
		{
			type = "RichCallback",
			desc = "The constructed Callback",
		},
	},
}
function _M.get_rich_callback(interface, func)
	return _M.enrich_callback{interface = interface, func = func}
end

_DOC.call = {
	type = "function",
	short_desc = [[ Call the given Callback. ]],
	desc = [[ Call the given Callback. Any parameters except the Callback will be passed to the function. ]],
	params = {
		{
			type = "Callback",
			name = "clbck",
			desc = "What to call",
		},
		{
			type = "Any",
			name = "...",
			desc = "Any parameters to be passed to the called function",
		},
	},
	returns = {
		{
			type = "...",
			desc = "Any values returned by the called function",
		},
	},
}
function _M.call(clbck, ...)
	return _callback_call_method(clbck, ...)
end


_DOC.add_interface = {
	type = "function",
	desc = [[ Expose an interface through the remote API. ]],
	notes = {[[
	Care needs to be taken with getters, as constants with nil value will not have a getter generated. Moreover, if the
	getter should clash with any name already in the module, it won't be generated either.
	]]},
	params = {
		{
			type = "string",
			name = "name",
			desc = "The name of the new interface",
		},
		{
			type = "Module",
			name = "module",
			desc = "The module to be exposed as an interface",
		},
		{
			type = {"bool", "string"},
			name = "generate_getters",
			desc = [[
			If true, constants will have getter functions generated. If it is a string, it will be used as the prefix
			for the getter functions' names
			]],
			default = "get_",
		},
		{
			type = "bool",
			name = "overwrite",
			desc = "If true, existing interface will be overwritten, otherwise nothing will happen",
			default = "false",
		},
		{
			type = "bool",
			name = "ignore_tables",
			desc = "If true, only non-table constants are taken into account",
			default = "false",
		},
	},
	returns = {
		{
			type = "bool",
			desc = "true if the interface was successfully exposed, false otherwise",
		},
	},
}
function _M.add_interface(name, module, generate_getters, overwrite, ignore_tables)
	if remote.interfaces[name] then
		if overwrite then remote.remove_interface(name)
		else return false
		end
	end
	
	generate_getters = generate_getters == nil or generate_getters
	if generate_getters and type(generate_getters) ~= "string" then generate_getters = "get_"; end
	
	local interface = {}
	for name, value in pairs(module) do
		local t = type(value)
		if t == "function" then interface[name] = value
		elseif generate_getters and not module[generate_getters..name]
				and not (ignore_tables and type(value) == "table") then
			-- Index the value from module, to support changes of the value.
			interface[generate_getters..name] = function() return module[name]; end
		end
	end
	
	remote.add_interface(name, interface)
	
	return true
end

_DOC.exopse_interface = {
	type = "function",
	deprecated = 5,
	desc = "Use remote.add_interface instead.",
}
_M.expose_interface = _M.add_interface


--TODO: Callback handling - simple way to generate a callback from a function, where FML is going to handle exposing the
-- interface.


return _M

local function pack_method(method, object)
	return function(...) return method(object, ...); end
end


local _M = {}
--[[ Contains functions for loading modules. ]]


function _M.load_std(std, res_table, stage, config, version)
--[[ Maps functions from std to their respective positions in the main module. ]]
	res_table = res_table or {}
	res_table.CONFIG = config
	
	res_table.STAGE = stage
	res_table.VERSION = version
	
	res_table.safe_require = std.safe_require
	res_table.get_config = function() return res_table.CONFIG; end
	res_table.make_doc = std.make_doc
	res_table.get_version_code = pack_method(std.get_version_code, version)
	res_table.get_version_name = pack_method(std.get_version_name, version)
	
	if stage == "data" then
		res_table.put_to_global = std.put_to_global
		res_table.register_module = pack_method(std.register_module, res_table)
	elseif stage == "runtime" then
		res_table.get_structure = pack_method(std.get_structure, res_table)
		res_table.get_global = std.get_global
		res_table.get_fml_global = function(name) return std.get_global("therustyknife", "FML", name); end
	end
	
	return res_table
end


function _M.load_from_file(path, load_func, log_func)
--[[
Load and return a module from the file at path, using load_func. Returns nil if the module didn't return a table.
log_func can be nil, boolean or function(message). Logging won't work if load_func doesn't return the error as second
return value.
]]
	load_func = load_func or require
	if log_func == true then log_func = log; end
	
	local loaded, err = load_func(path)
	if type(loaded) ~= "table" then
		loaded = nil
		if err and log_func then
			log_func("Loading FML module from '"..tostring(path).."' failed: "..(err or "No error message."))
		end
	end
	
	return loaded
end

function _M.load_from_files(modules, res_table, load_func, log_func)
--[[
Load all the modules, calling load_from_file for each and putting them into res_table, indexed by their names.
Since this only internal, we can just ignore any modules whose names are already in the table, assuming they're supposed
to be there.
load_func and log_func is passed to load_from_file.
]]
	res_table = res_table or {}
	
	for _, module in ipairs(modules) do
		if res_table[module.name] == nil then
			res_table[module.name] = _M.load_from_file(module.path, load_func, log_func) or res_table[module.name]
		end
	end
	
	return res_table
end


--TODO: a mechanism for loading external modules in runtime stage


return _M

--TODO: docs

local _M = {}
--[[ Some functions that are not fit to be in a module, but are needed for FML to be useful. ]]


function _M.make_doc(module, doc)
	doc.funcs = {}
	module._DOC = doc
	return doc.funcs
end


function _M.safe_require(path, raise_errors)
--[[
Call require for the given path, even if the path was already required and leave the original value in package.loaded.
]]
	-- Save the original value
	local prev_loaded = package.loaded[path]
	package.loaded[path] = nil
	
	-- Try to require the path
	local res
	local status, err = pcall(function(path) res = require(path); end, path)
	
	-- Restore the original value
	package.loaded[path] = prev_loaded
	
	-- Handle errors
	if not status then
		if raise_errors then error(err)
		else return nil, err; end
	end
	
	return res
end

function _M.get_module_lookup(modules)
--[[ Convert the module definition in the config format into a path lookup table by name. ]]
	local res = {}
	for _, module in ipairs(modules) do res[module.name] = module.path; end
	return res
end

function _M.put_to_global(namespace, package_name, package)
--[[ Put a package into the global namespace. Useful during the data stage. ]]
	_G[namespace] = _G[namespace] or {}
	_G[namespace][package_name] = package
end


function _M.get_global(namespace, package_name, name)
--[[ Get a serialized table in the given namespace with the given name. A new table will be created if not present. ]]
	global[namespace] = global[namespace] or {}
	global[namespace][package_name] = global[namespace][package_name] or {}
	global[namespace][package_name][name] = global[namespace][package_name][name] or {}
	
	return global[namespace][package_name][name]
end


function _M.register_module(self, name, module)
--[[
Register a module into FML. Should be called as a method from the FML instance you want to register the module into.
It is an error to register a module to an already used name.
]]
	if type(self) ~= "table" or type(module) ~= "table" or type(name) ~= "string" then
		error("invalid attempt to register module: Wrong argument type.")
	end
	if self[name] ~= nil then
		error("Invalid attempt to register module: Name "..name.." already exists.")
	end
	
	self[name] = module
	--TODO: expose the module's interface
end

function _M.get_structure(self, const_to_func, depth)
--[[
Get the current structure of this FML instance (the one passed in self). Used for accessing the interface remotely.
If const_to_func is true, constants are going to be converted to getter functions, using const_to_func as prefix if it
is a string, "get_" otherwise.
Tables will be treated as modules up to the specified depth.
]]
	depth = depth or 1
	if const_to_func and type(const_to_func) ~= "string" then const_to_func = "get_"; end
	
	local function _constant(res_tab, name)
		if not const_to_func then
			res_tab[name] = "constant"
			return
		end
		res_tab[const_to_func..name] = "function"
	end
	
	local level = 1
	local function _get_structure(tab)
		local res = {}
		for name, value in pairs(tab) do
			local t = type(value)
			if t == "table" then
				if level <= depth then
					level = level+1
					res[name] = _get_structure(value)
					level = level-1
				else _constant(res, name) end
				
			elseif t == "function" then
				res[name] = "function"
			
			else
				_constant(res, name)
			end
		end
		return res
	end
	
	return _get_structure(self)
end


function _M.get_version_code(version) return version.CODE; end
function _M.get_version_name(version) return version.NAME; end


return _M

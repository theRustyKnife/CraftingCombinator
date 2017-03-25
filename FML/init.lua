local FML_VERSION_CODE = 3
local FML_VERSION_NAME = "0.1.0-alpha.3.0"


local _M = {}


-- requires a module without interfering with any other required modules
-- it is recommended that any FML modules use this instead of the regular require to prevent name/path clashes with the actual mod code
function _M.safe_require(path)
	-- store the original value
	local t = package.loaded[path]
	package.loaded[path] = nil
	-- try to load
	local res
	local status, err = pcall(function() res = require(path); end)
	package.loaded[path] = t -- set the value back to the original
	
	-- if loading failed, re-raise the error
	if (not status) then error(err); end
	
	return res
end


local config = _M.safe_require(".config")


package.loaded["therustyknife.FML"] = _M -- global access to this instance of FML
package.loaded["therustyknife.FML.config"] = config -- global access to the FML general config


-- this only runs when loaded from control
-- a better way to check for that would be good since if there appears a variable named script in the data loading stage it'll fail
if script and script.on_init then
	local global_handlers = {init = {}, load = {}, config_change = {}, fml_config_change = {}, mod_config_change = {}, fml_init = {}} -- handlers to be run on load and init
	
	-- the global table before global is accessible
	-- contains functions for registering various event handlers
	_M.global = {
		loaded = false, -- indicate that the global table is not yet loaded
		on_init = function(f) table.insert(global_handlers.init, f) end, -- same as script.on_init
		on_load = function(f) table.insert(global_handlers.load, f) end, -- same as script.on_load, except it also runs when on_init does
		on_config_change = function(f) table.insert(global_handlers.config_change, f) end, -- same as script.on_configuration_changed
		on_fml_config_change = function(f) table.insert(global_handlers.fml_config_change, f) end, -- runs when FML version changes, except when FML was first installed - passes a table containing the old and new versions
		on_mod_config_change = function(f) table.insert(global_handlers.mod_config_change, f) end, -- runs whenever there's an entry for the current MOD_NAME in on_config_change - passes the same data as on_config_change
		on_fml_init = function(f) table.insert(global_handlers.fml_init, f) end, -- called when FML is first installed (after on_init) - FML's global table is passed as argument
	}
	-- runs all the handlers from a table passing an argument to them
	local function run(handlers, arg) for _, handler in ipairs(handlers) do handler(arg); end end
	
	-- create the global table if it doesn't exist - if everything works properly it should be safe to call this from on_load
	local function init_global()
		global[config.GLOBAL_NAME] = global[config.GLOBAL_NAME] or {}
		_M.global = global[config.GLOBAL_NAME] -- get the reference to our global table
		
		-- this will return a table from the global, creating a new one if it's not present
		function _M.global.get(name)
			_M.global[name] = _M.global[name] or {}
			return _M.global[name]
		end
	end
	
	script.on_init(function()
		init_global()
		
		global.loaded = true -- indicate that the global table is loaded and contains the actual global values
		global.fml_version = {code = FML_VERSION_CODE, name = FML_VERSION_NAME}
		
		-- call all the respective handlers
		run(global_handlers.init)
		run(global_handlers.fml_init, _M.global)
		if config.ON_LOAD_AFTER_INIT then run(global_handlers.load); end
	end)
	
	script.on_load(function()
		--init_global()
		run(global_handlers.load)
	end)
	
	script.on_configuration_changed(function(data)
		run(global_handlers.config_change, data)
		
		if not global.fml_version then -- FML was just added to the mod
			global.fml_version = {code = FML_VERSION_CODE, name = FML_VERSION_NAME}
			run(global_handlers.fml_init, _M.global)
		elseif global.fml_version.code ~= FML_VERSION_CODE then -- FML version has changed
			local arg = {
				old = global.fml_version,
				new = {code = FML_VERSION_CODE, name = FML_VERSION_NAME},
			}
			global.fml_version = arg.new
			run(global_handlers.fml_config_change, arg)
		end
		
		if data.mod_changes[config.MOD_NAME] then
			init_global()
			run(global_handlers.mod_config_change, data)
		end
	end)
end


-- here we load the modules
for name, path in pairs(config.MODULES_TO_LOAD) do
	local function t_load() _M[name] = _M.safe_require(path); end
	
	if config.FORCE_LOAD_MODULES then t_load()
	else pcall(t_load)
	end
	
	if type(_M[name]) ~= "table" then _M[name] = nil; end
end


return _M

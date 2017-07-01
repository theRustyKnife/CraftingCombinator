local FML_stdlib = require "script.FML-stdlib"
local module_loader = FML_stdlib.safe_require("script.module-loader", true)

local config = FML_stdlib.safe_require(".config", true)


local remote_config = remote.call("therustyknife.FML", "get_config")
local function _merge_configs(local_config, remote_config)
	for key, value in pairs(local_config) do
		if type(value) == "table" and remote_config[key] then _merge_configs(value, remote_config[key]); end
	end
	setmetatable(local_config, {__index = remote_config})
end
_merge_configs(config, remote_config)


local _M = module_loader.load_std(FML_stdlib, nil, "runtime", config, config.VERSION)
package.loaded["therustyknife.FML"] = _M
package.loaded["therustyknife.FML.config"] = config

local module_lookup = FML_stdlib.get_module_lookup(config.MODULES_TO_LOAD)


-- Make sure remote is installed and loaded first, so we can use it for all the other things
assert(module_lookup["remote"], "FML couldn't find the remote module in mod "..config.MOD.NAME..".")
--TODO: allow logging using the log module
_M.remote = module_loader.load_from_file(module_lookup["remote"], FML_stdlib.safe_require)

local log_func = _M.remote.get_rich_callback("therustyknife.FML.log", "w") -- Use FML's logging

if module_lookup["log"] then
	_M.log = module_loader.load_from_file(module_lookup["log"], FML_stdlib.safe_require, log_func)
	if _M.log then log_func = _M.log.w; end
end

local remote_version_code = remote.call("therustyknife.FML", "get_version_code")
local local_version_code = _M.get_version_code()
if remote_version_code ~= local_version_code then
	local msg = "FML versions don't match: local = ".._M.get_version_name()..
			", remote = "..remote.call("therustyknife.FML", "get_version_name")
	if not pcall(log_func(msg)) then log(msg) end -- Try using the log function from FML, use log if it doesn't work.
end


module_loader.load_from_files(
		config.MODULES_TO_LOAD,
		_M,
		FML_stdlib.safe_require,
		log_func
	)

local interface_structure = remote.call("therustyknife.FML", "get_structure", true)
for name, value in pairs(interface_structure) do
	if not _M[name] then
		if value == "function" then
			_M[name] = _M.remote.get_function{interface = "therustyknife.FML", func = name}
		elseif type(value) == "table" then
			_M[name] = _M.remote.get_interface("therustyknife.FML."..name)
		end
	end
end


--[[ DEBUG
script.on_init(function()
	game.print(tostring(_M.table.getn{"one", "two"}))
end)
--]]


return _M

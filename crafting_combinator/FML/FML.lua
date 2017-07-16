-- Change this if you want to specify a config somewhere else than next to this file.
local CONFIG_PATH = ".config"


local FML_import = next(remote.interfaces["therustyknife.FML.serialized"]); FML_import = loadstring(FML_import)()

local module_loader = {}; FML_import.module_loader(module_loader)
local FML_stdlib = module_loader.init(FML_import.FML_stdlib)

local config = FML_stdlib.merge_configs(FML_stdlib.safe_require(CONFIG_PATH) or {}, FML_import.config)


local _M = module_loader.load_std(FML_stdlib, nil, "runtime", config, config.VERSION)
FML_stdlib.put_to_global("therustyknife", "FML", _M) -- Give global access to the library

for _, module in ipairs(config.MODULES_TO_LOAD) do
	if FML_import.modules[module.name] then
		_M[module.name] = module_loader.init(FML_import.modules[module.name])
	end
end


return _M

local config = require 'config'
local cc_control = require 'script.cc'


cc_control.on_load()
log("Adding missing settings to combinators...")
for _, combinator in pairs(global.cc.data) do
	cc_control.settings_parser:fill_defaults(combinator.settings, config.CC_DEFAULT_SETTINGS)
end

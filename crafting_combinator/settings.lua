local FML = require "FML.init"
local config = require "config"


FML.data.make_prototypes{
	{
		type = "int-setting",
		name = config.SETTING_NAME_REFRESH_RATE_CC,
		setting_type = "runtime-global",
		default_value = config.REFRESH_RATE_CC,
		minimum_value = 1,
	},
	{
		type = "int-setting",
		name = config.SETTING_NAME_REFRESH_RATE_RC,
		setting_type = "runtime-global",
		default_value = config.REFRESH_RATE_RC,
		minimum_value = 1,
	},
}

local config = require "config"

therustyknife.FML.data.make{
	type = "int-setting",
	name = config.NAME.SETTING_REFRESH_RATE,
	setting_type = "runtime-global",
	default_value = 60,
	minimum_value = 1,
}

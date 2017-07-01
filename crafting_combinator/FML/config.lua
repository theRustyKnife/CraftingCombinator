return {
	-- FML version info
	VERSION = {
		NAME = "0.1.0-alpha.4.1",
		CODE = 6,
	},
	
	
	-- Settings that need to be configured to reflect the mod FML is installed in
	MOD = {
		NAME = "crafting_combinator",
	},
	
	
	-- Modules with their paths that FML will attempt to load
	MODULES_TO_LOAD = {
		{name = "log", path = ".modules.log"},
		{name = "remote", path = ".modules.remote"},
		{name = "table", path = ".modules.table"},
		{name = "format", path = ".modules.format"},
		{name = "events", path = ".modules.events"},
		{name = "GUI", path = ".modules.GUI"},
		{name = "Semver", path = ".modules.Semver"},
	},
}

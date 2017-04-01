return {
	{
		type = "enum",
		name = "rc_mode",
		options = {"ingredient", "product"},
	},
	{
		type = "bool",
		name = "cc_mode_set",
	},
	{
		type = "bool",
		name = "cc_mode_read",
	},
	{
		type = "enum",
		name = "cc_item_dest",
		options = {"active", "passive", "normal", "none"},
	},
	{
		type = "enum",
		name = "cc_module_dest",
		options = {"active", "passive", "normal", "none"},
	},
	{
		type = "bool",
		name = "cc_empty_inserters",
	},
	{
		type = "bool",
		name = "cc_request_modules",
	},
}

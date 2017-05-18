return {
	{
		type = "enum",
		name = "rc_mode",
		options = {"ingredient", "product", "recipe"},
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
	{
		type = "number",
		name = "rc_time_multiplier"
	},
	{
		type = "bool",
		name = "cc_read_speed",
	},
	{
		type = "bool",
		name = "rc_multiply_by_input",
	},
	{
		type = "bool",
		name = "cc_read_bottleneck",
	},
}

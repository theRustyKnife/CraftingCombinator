return {
	CC_NAME = 'crafting_combinator:crafting-combinator',
	RC_NAME = 'crafting_combinator:recipe-combinator',
	MODULE_CHEST_NAME = 'crafting_combinator:module-chest',
	SETTINGS_ENTITY_NAME = 'crafting_combinator:settings-entity',
	REFRESH_RATE_CC_NAME = 'crafting_combinator:refresh-rate-cc',
	REFRESH_RATE_RC_NAME = 'crafting_combinator:refresh-rate-rc',
	RC_PROXY_NAME = 'crafting_combinator:rc-proxy',
	TIME_SIGNAL_NAME = 'crafting_combinator:recipe-time',
	SPEED_SIGNAL_NAME = 'crafting_combinator:crafting-speed',
	GROUP_NAME = 'crafting_combinator:virtual-recipes',
	RECIPE_SUBGROUP_PREFIX = 'crafting_combinator:virtual-recipe-subgroup:',
	UNSORTED_RECIPE_SUBGROUP = 'crafting_combinator:virtual-recipe-subgroup:unsorted',
	
	CC_DEFAULT_SETTINGS = {
		mode = {
			set = true,
			read = false,
		},
		discard_items = false,
		discard_fluids = true,
		empty_inserters = true,
		read_speed = false,
		read_bottleneck = false,
	},
	RC_DEFAULT_SETTINGS = {
		mode = 'ing',
		multiply_by_input = false,
		divide_by_output = false,
		differ_output = false,
		time_multiplier = 10,
	},
	
	ASSEMBLER_DISTANCE = 1,
	ASSEMBLER_SEARCH_DISTANCE = 2,
	CHEST_DISTANCE = -1,
	CHEST_SEARCH_DISTANCE = 2,
	INSERTER_SEARCH_RADIUS = 3,
	
	REFRESH_RATE_CC = 60,
	REFRESH_RATE_RC = 60,
	
	INSERTER_EMPTY_DELAY = 60,
	
	MODULE_CHEST_SIZE = 100,
	
	RC_SLOT_COUNT = 40,
	
	-- Recipes matching any of these strings will not get a virtual recipe
	RECIPES_TO_IGNORE = {
		'^compress%-',
		'^uncompress%-',
		'angels%-void',
	},
	
	FLYING_TEXT_INTERVAL = 180,
}

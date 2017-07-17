return {
	-- How many slots the overflow chests will have (normal will have twice as much)
	OVERFLOW_SLOT_COUNT = 1000,
	
	-- Recipes matching any of the strings will not get a virtual recipe
	RECIPES_TO_IGNORE = {
		--"^ngels%-fluid%-splitter-",
		--"^converter%-angels%-",
		"^compress%-",
		"^uncompress%-",
		"angels%-void",
	},
	
	NAME = {
		-- Crafting combinator entity name
		CC = "crafting_combinator_crafting-combinator",
		
		-- The setting group names
		CC_SETTINGS = "crafting_combinator_CC-settings",
		RC_SETTINGS = "crafting_combinator_RC-settings",
		
		-- Virtual recipe group name
		GROUP = "crafting_combinator_virtual-recipes",
		-- Virtual recipe subgroup name (default)
		SUBGROUP = "crafting_combinator_recipes",
		
		-- Time signal name
		TIME = "crafting_combinator_recipe-time",
		-- Speed signal name
		SPEED = "crafting_combinator_crafting-speed",
		
		-- Overflow chest names (active, passive, normal)
		OVERFLOW_A = "crafting_combinator_overflow-active",
		OVERFLOW_P = "crafting_combinator_overflow-passive",
		OVERFLOW_N = "crafting_combinator_overflow-normal",
	},
	
	CC_ASSEMBLER_DISTANCE = 1,
	CC_ASSEMBLER_OFFSET = 0.2,
	CC_INSERTER_SEARCH_DISTANCE = 10,
}

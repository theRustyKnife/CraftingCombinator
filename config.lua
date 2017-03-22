local config = {}


-- how many ticks between updates, changing this may break existing saves
-- recipe combinator
config.REFRESH_RATE_RC = 60
-- crafting combinator
config.REFRESH_RATE_CC = 60


-- how far to look for crafting combinators around an assembler
config.CC_SEARCH_DISTANCE = 2
-- how far in front of the combinator to search for an assembler
config.CC_ASSEMBLER_DISTANCE = 1
-- how wide of an area to search for an assembler
config.CC_ASSEMBLER_OFFSET = 0.2


-- the number of signal slots the recipe combinator will have
config.RC_SLOT_COUNT = 20


-- if true, recipes will be sorted into subgroups for better readability (in Factorio 0.14 this causes problems)
config.USE_RECIPE_SUBGROUPS = false

-- recipes matching any of the strings will not get a virtual recipe
config.RECIPES_TO_IGNORE = {
	--"angels%-fluid%-splitter-",
    --"converter%-angels%-",
    "compress%-",
    "uncompress%-",
}


-- crafting combinator name
config.CC_NAME = "crafting_combinator_crafting-combinator"
-- recipe combinator name
config.RC_NAME = "crafting_combinator_recipe-combinator"

-- active provider overflow chest
config.OVERFLOW_A_NAME = "crafting_combinator_overflow-active"
-- passive provider overflow chest
config.OVERFLOW_P_NAME = "crafting_combinator_overflow-passive"

-- virtual recipe group name
config.GROUP_NAME = "crafting_combinator_virtual-recipes"
-- virtual recipe subgroup name, if USE_RECIPE_SUBGROUPS is true this will be used as default
config.RECIPE_SUBGROUP_NAME = "crafting_combinator_recipes"

-- time signal name
config.TIME_NAME = "crafting_combinator_recipe-time"

-- the name of the menu key ipnut
config.MENU_KEY_NAME = "crafting_combinator_open-menu"


-- for some reason defines.inventory.assembling_machine_output does not seem to work properly so let's define it ourself
config.ASSEMBLING_MACHINE_OUTPUT_INDEX = 3

-- types to check for locale an icons
config.ITEM_TYPES = {"item", "module", "tool", "fluid", "ammo"}


return config

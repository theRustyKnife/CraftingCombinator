local combiname = "crafting-combinator"
local MODNAME = "__CraftingCombinator__"

local combi_entity = util.table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
combi_entity.name = combiname
combi_entity.minable.result = combiname
combi_entity.item_slot_count = 0

local combi_item = util.table.deepcopy(data.raw["item"]["constant-combinator"])
combi_item.name = combiname
combi_item.order = "b[combinators]-cb[crafting-combinator]"
combi_item.place_result = combiname

local combi_recipe = util.table.deepcopy(data.raw["recipe"]["constant-combinator"])
combi_recipe.name = combiname
combi_recipe.result = "crafting-combinator"

table.insert(data.raw.technology["circuit-network"].effects,
	{
		type = "unlock-recipe",
		recipe = "crafting-combinator"
	}
)

data:extend({combi_entity, combi_item, combi_recipe})
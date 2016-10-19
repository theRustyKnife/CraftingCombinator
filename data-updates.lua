local combiname = "crafting-combinator"
local recipe_combi_name = "recipe-combinator"
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
combi_recipe.result = combiname

local recipe_combi_out = util.table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
recipe_combi_out.name = recipe_combi_name
recipe_combi_out.minable.result = recipe_combi_name
recipe_combi_out.item_slot_count = 20

local recipe_combi_item = util.table.deepcopy(data.raw["item"]["constant-combinator"])
recipe_combi_item.name = recipe_combi_name
recipe_combi_item.order = "b[combinators]-cb[recipe-combinator]"
recipe_combi_item.place_result = recipe_combi_name

local recipe_combi_recipe = util.table.deepcopy(data.raw["recipe"]["constant-combinator"])
recipe_combi_recipe.name = recipe_combi_name
recipe_combi_recipe.result = recipe_combi_name

table.insert(data.raw.technology["circuit-network"].effects,
	{
		type = "unlock-recipe",
		recipe = "crafting-combinator"
	}
)
table.insert(data.raw.technology["circuit-network"].effects,
	{
		type = "unlock-recipe",
		recipe = "recipe-combinator"
	}
)

data:extend({combi_entity, combi_item, combi_recipe, recipe_combi_out, recipe_combi_item, recipe_combi_recipe,
	{
		type = "virtual-signal",
		name = "recipe-time",
		icon = "__core__/graphics/clock-icon.png",
		subgroup = "virtual-signal-recipe",
		order = "c[recipe-time]"
	},
})
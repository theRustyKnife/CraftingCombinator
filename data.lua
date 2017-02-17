--luacheck: globals util
local FML = require "FML.init"
local config = require "script.config"


-- Crafting Combinator
local crafting_combinator = {
	base = FML.data.inherit("constant-combinator", "constant-combinator"),
	properties = {
		name = config.CC_NAME,
		icon = "__crafting_combinator__/graphics/icon-crafting-combinator.png",
		item_slot_count = 0,
	},
	auto_generate = {
		item = {properties = {subgroup = "circuit-network"}},
		recipe = {base = FML.data.inherit("recipe", "constant-combinator"), unlock_with = "circuit-network"},
	},
}
-- set the images
for _, image in pairs(crafting_combinator.base.sprites) do
	image.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
	image.y = 0
end

-- Recipe Combinator
local recipe_combinator = {
	base = FML.data.inherit("constant-combinator", "constant-combinator"),
	properties = {
		name = config.RC_NAME,
		icon = "__crafting_combinator__/graphics/icon-recipe-combinator.png",
		item_slot_count = 20,
	},
	auto_generate = {
		item = {properties = {subgroup = "circuit-network"}},
		recipe = {base = FML.data.inherit("recipe", "constant-combinator"), unlock_with = "circuit-network"},
	},
}
-- set the images
for _, image in pairs(recipe_combinator.base.sprites) do
	image.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
	image.y = 63
end


FML.data.make_prototypes{
	{
		type = "item-group",
		name = "signals-crafting-combinator",
		order = "fb",
		icon = "__crafting_combinator__/graphics/recipe-book.png",
	},
	{
		type = "item-subgroup",
		name = "crafting-combinator",
		group = "signals",
		order = "zzz"
	},
	{
		type = "item-subgroup",
		name = "virtual-signal-recipe",
		group = "signals-crafting-combinator",
		order = "zzz"
	},
	{
		type = "virtual-signal",
		name = "recipe-time",
		icon = "__core__/graphics/clock-icon.png",
		subgroup = "crafting-combinator",
		order = "c[recipe-time]"
	},
	crafting_combinator,
	recipe_combinator,
	{ -- the overflow chest
		base = FML.data.inherit("logistic-container", "logistic-chest-active-provider"),
		properties = {
			name = config.CHEST_NAME,
			flags = {"placeable-off-grid"},
			minable = nil,
			selectable_in_game = false,
			selection_box = nil,
			collision_mask = {},
			hidden = true,
			item_slot_count = 1000,
			picture = {
				filename = "__crafting_combinator__/graphics/trans.png",
				width = 1,
				height = 1,
			},
			circuit_wire_max_distance = 0,
		},
	},
}

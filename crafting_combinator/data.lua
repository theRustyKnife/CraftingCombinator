local FML = require "FML.init"
local config = require "config"


-- Crafting Combinator
local cc = FML.data.make_prototype{
	base = FML.data.inherit("constant-combinator"),
	properties = {
		name = config.CC_NAME,
		icon = "__crafting_combinator__/graphics/icon-crafting-combinator.png",
		item_slot_count = 1,
	},
	auto_generate = {
		item = {properties = {subgroup = "circuit-network"}},
		recipe = {base = FML.data.inherit("recipe", "constant-combinator"), unlock_with = "circuit-network"},
	},
}
-- change images
for _, image in pairs(cc.sprites) do
	image.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
	image.y = 0
end

-- Recipe Combinator
local rc = FML.data.make_prototype{
	base = FML.data.inherit("constant-combinator"),
	properties = {
		name = config.RC_NAME,
		icon = "__crafting_combinator__/graphics/icon-recipe-combinator.png",
		item_slot_count = config.RC_SLOT_COUNT,
	},
	auto_generate = {
		item = {properties = {subgroup = "circuit-network"}},
		recipe = {base = FML.data.inherit("recipe", "constant-combinator"), unlock_with = "circuit-network"},
	},
}
-- change images
for _, image in pairs(rc.sprites) do
	image.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
	image.y = 63
end


FML.data.make_prototypes{
	{
		type = "item-group",
		name = config.GROUP_NAME,
		order = "fb",
		icon = "__crafting_combinator__/graphics/recipe-book.png",
	},
	{
		type = "item-subgroup",
		name = "crafting_combinator-signals",
		group = "signals", --TODO: change this to be in our group once 0.15 comes out
		order = "zzz",
	},
	{
		type = "item-subgroup",
		name = config.RECIPE_SUBGROUP_NAME,
		group = config.GROUP_NAME,
		order = "zzz[unsorted]",
	},
	{
		type = "virtual-signal",
		name = config.TIME_NAME,
		icon = "__core__/graphics/clock-icon.png",
		subgroup = "crafting_combinator-signals",
		order = "a[recipe-time]",
	},
	{ -- the active overflow chest
		base = FML.data.inherit("logistic-container", "logistic-chest-active-provider"),
		properties = {
			name = config.OVERFLOW_A_NAME,
			flags = {"placeable-off-grid"},
			minable = nil,
			selectable_in_game = false,
			selection_box = nil,
			collision_mask = {},
			hidden = true,
			item_slot_count = config.OVERFLOW_SLOT_COUNT,
			picture = {
				filename = "__crafting_combinator__/graphics/trans.png",
				width = 1,
				height = 1,
			},
			circuit_wire_max_distance = 0,
		},
	},
	{ -- the regular overflow chest
		base = FML.data.inherit("container", "steel-chest"),
		properties = {
			name = config.OVERFLOW_N_NAME,
			flags = {"placeable-off-grid"},
			minable = nil,
			selectable_in_game = false,
			selection_box = nil,
			collision_mask = {},
			hidden = true,
			item_slot_count = config.OVERFLOW_SLOT_COUNT,
			picture = {
				filename = "__crafting_combinator__/graphics/trans.png",
				width = 1,
				height = 1,
			},
			circuit_wire_max_distance = 0,
		},
	},
	{
		type = "custom-input",
		name = config.MENU_KEY_NAME,
		key_sequence = "mouse-button-1",
		consuming = "none",
	},
	{
		type = "custom-input",
		name = config.CLOSE_KEY_NAME,
		key_sequence = "E",
		consuming = "none",
	},
}


FML.data.make_prototype{ -- the passive overflow chest
	base = FML.data.inherit("logistic-container", config.OVERFLOW_A_NAME),
	properties = {
		name = config.OVERFLOW_P_NAME,
		logistic_mode = "passive-provider",
	},
}

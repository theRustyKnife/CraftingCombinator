--luacheck: globals util
local config = require "script.config"

-- the crafting time signal
data:extend{
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
}

-------------------------------------------------------------------------------
--[[Crafting Combinator]]--
-------------------------------------------------------------------------------
local cc = util.table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
cc.name = config.CC_NAME
cc.minable.result = config.CC_NAME
cc.icon = "__crafting_combinator__/graphics/icon-crafting-combinator.png"
cc.item_slot_count = 0
for _, image in pairs(cc.sprites) do
	image.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
	image.y = 0
end

local cc_item = util.table.deepcopy(data.raw["item"]["constant-combinator"])
cc_item.name = config.CC_NAME
cc_item.place_result = config.CC_NAME
cc_item.order = "b[combinators]-cb["..config.CC_NAME.."]"
cc_item.icon = "__crafting_combinator__/graphics/icon-crafting-combinator.png"

local cc_recipe = util.table.deepcopy(data.raw["recipe"]["constant-combinator"])
cc_recipe.name = config.CC_NAME
cc_recipe.result = config.CC_NAME


-------------------------------------------------------------------------------
--[[Recipe Combinator]]--
-------------------------------------------------------------------------------
local rc = util.table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
rc.name = config.RC_NAME
rc.minable.result = config.RC_NAME
rc.icon = "__crafting_combinator__/graphics/icon-recipe-combinator.png"
rc.item_slot_count = 20
for _, image in pairs(rc.sprites) do
	image.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
	image.y = 63
end

local rc_item = util.table.deepcopy(data.raw["item"]["constant-combinator"])
rc_item.name = config.RC_NAME
rc_item.place_result = config.RC_NAME
rc_item.order = "b[combinators]-cb["..config.RC_NAME.."]"
rc_item.icon = "__crafting_combinator__/graphics/icon-recipe-combinator.png"

local rc_recipe = util.table.deepcopy(data.raw["recipe"]["constant-combinator"])
rc_recipe.name = config.RC_NAME
rc_recipe.result = config.RC_NAME

-------------------------------------------------------------------------------
--[[Active Provider]]--
-------------------------------------------------------------------------------
local chest = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"])
chest.name = config.CHEST_NAME
chest.flags = {}
chest.subgroup = nil
chest.order = nil
chest.minable = nil
chest.selectable_in_game = false
chest.selection_box = nil
chest.collision_mask = {}
chest.hidden = true
chest.item_slot_count = 1000
chest.picture.filename = "__crafting_combinator__/graphics/trans.png"
chest.picture.width = 1
chest.picture.height = 1
chest.circuit_wire_max_distance = 0

-------------------------------------------------------------------------------
--[[Extend and insert into technologies]]--
-------------------------------------------------------------------------------
data:extend({cc, cc_item, cc_recipe, rc, rc_item, rc_recipe, chest})
table.insert(data.raw.technology["circuit-network"].effects, {type = "unlock-recipe", recipe = config.CC_NAME})
table.insert(data.raw.technology["circuit-network"].effects, {type = "unlock-recipe", recipe = config.RC_NAME})

local config = require "script.config"


-- define entities here, only name and slot item_slot_count needed, rest is from constant-combinator
local entities = {
	{
		name = config.CC_NAME,
		item_slot_count = 0,
	},
	{
		name = config.RC_NAME,
		item_slot_count = 20,
	},
	{
		type = "active-provider",
		name = config.CHEST_NAME,
		item_slot_count = 1000,
		hidden = true,
	}
}

-- the crafting time signal
data:extend{
	{
		type = "virtual-signal",
		name = "recipe-time",
		icon = "__core__/graphics/clock-icon.png",
		subgroup = "virtual-signal-recipe",
		order = "c[recipe-time]"
	},
}


-- here we create our entities with all the necessary stuff
for _, e in ipairs(entities) do
	-- entity
	local te
	if not e.type or e.type == "constant-combinator" then -- default type to constant-combinator
		te = util.table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
		te.name = e.name
		te.minable.result = e.name
		te.item_slot_count = e.item_slot_count
		
	elseif e.type == "active-provider" then
		te = util.table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"])
		te.name = e.name
		te.minable.result = e.mine_res
		te.iventory_size = e.item_slot_count
		
		if e.hidden then
			te.order = "?"
			te.collision_mask = {}
			te.selection_box = {{0, 0}, {0, 0}}
			te.picture.filename = "__crafting_combinator__/graphics/trans.png"
			te.picture.width = 1
			te.picture.height = 1
		end
	end
	
	local ti
	local tr
	if not e.hidden then
		-- item
		ti = util.table.deepcopy(data.raw["item"]["constant-combinator"])
		ti.name = e.name
		ti.place_result = e.name
		ti.order = "b[combinators]-cb[crafting-combinator]"
		
		-- recipe
		tr = util.table.deepcopy(data.raw["recipe"]["constant-combinator"])
		tr.name = e.name
		tr.result = e.name
		
		-- tech
		table.insert(data.raw.technology["circuit-network"].effects, {type = "unlock-recipe", recipe = e.name})
	end
	
	-- add to data
	data:extend{te, ti, tr}
end

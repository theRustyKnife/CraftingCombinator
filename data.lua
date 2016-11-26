local config = require "script.config"


-- define entities here, only name and slot ite_slot_count needed, rest is from constant-combinator
local entities = {
	{
		name = config.CC_NAME,
		item_slot_count = 0,
	},
	{
		name = config.RC_NAME,
		item_slot_count = 20,
	}
}


-- here we create our entities with all the necessary stuff
for _, e in ipairs(entities) do
	-- entity
	local te = util.table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
	te.name = e.name
	te.minable.result = e.name
	te.item_slot_count = e.item_slot_count
	
	-- item
	local ti = util.table.deepcopy(data.raw["item"]["constant-combinator"])
	ti.name = e.name
	ti.place_result = e.name
	ti.order = "b[combinators]-cb[crafting-combinator]"
	
	-- recipe
	local tr = util.table.deepcopy(data.raw["recipe"]["constant-combinator"])
	tr.name = e.name
	tr.result = e.name
	
	-- add to data
	data:extend{te, ti, tr}
	
	-- tech
	table.insert(data.raw.technology["circuit-network"].effects, {type = "unlock-recipe", recipe = e.name})
end

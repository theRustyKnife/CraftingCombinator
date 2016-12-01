local config = require ".config"
local entities = require ".entities"


local function get_special_cases()
	local INTERFACE_NAME = "crafting-combinator_init"
	
	local res = {}
	
	local i = 1
	while true do -- call all the interfaces
		if not remote.interfaces[INTERFACE_NAME .. i] then break; end
		local data = remote.call(INTERFACE_NAME .. i, "init")
		
		for i, v in pairs(data.overrides) do -- add the reverse of data to the result table
			if not (DATA_PRIORITY == "low" and res[v]) then
				res[v] = i
			end
		end
		
		i = i + 1
	end
	
	return res
end


local migration = {}

function migration.load()
-- sets up the metatables after load
	for _, tab in pairs(global.combinators) do
		if type(tab) == "table" then
			for _, v in pairs(tab) do
				local mt
				if v.type == "recipe-combinator" then
					mt = entities.RecipeCombinator
				elseif v.type == "crafting-combinator" then
					mt = entities.CraftingCombinator
				end
				if mt then
					setmetatable(v, mt)
					mt.__index = mt
				end
			end
		end
	end
end

function migration.init()
	global.special_cases = get_special_cases()
	
	global.combinators = global.combinators or {}
	global.combinators.next_index = global.next_index or 1
	global.combinators.get_next_index = global.combinators.get_next_index or
	function() 
	-- returns the next most suitable index
		best_i = 0
		best = #global.combinators[0]
		
		for i = 1, config.REFRESH_RATE - 1 do
			if #global.combinators[i] < best then
				best_i = i
				best = #global.combinators[i]
			end
		end
		
		return best_i
	end
	
	for i = 0, config.REFRESH_RATE - 1 do
		global.combinators[i] = global.combinators[i] or {}
	end
	
	-- find any entities potentially left by the old mod and register them into the system
	for _, surface in pairs(game.surfaces) do
		local ccs = surface.find_entities_filtered{name = config.CC_NAME}
		local rcs = surface.find_entities_filtered{name = config.RC_NAME}
		
		for _, cc in pairs(ccs) do
			entities.CraftingCombinator:new(cc):get_assembler()
		end
		for _, rc in pairs(rcs) do
			entities.RecipeCombinator:new(rc)
		end
	end
end

function migration.migrate(data)
	if data.mod_changes["crafting_combinator"] then
		local old_v = data.mod_changes["crafting_combinator"].old_version
		local new_v = data.mod_changes["crafting_combinator"].new_version
		for _, force in pairs(game.forces) do
			if force.technologies["circuit-network"].researched then
				force.recipes["crafting-combinator"].enabled = true
				force.recipes["recipe-combinator"].enabled = true
			end
		end
		
		if old_v and old_v < "0.3.0" then -- the code has changed a lot in 0.3 - re-register everything again
			global.combinators = nil
			global.recipe_combinators = nil
			
			migration.init()
		end
	end
end

return migration

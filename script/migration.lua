local config = require ".config"


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
end

function migration.migrate(data) --TODO: update, disabled for now
	migration.init()
	--[[global.combinators = global.combinators or {}
	global.recipe_combinators = global.recipe_combinators or {}
	for i = 0, refresh_rate - 1 do
		global.combinators[i] = global.combinators[i] or {}
		global.recipe_combinators[i] = global.recipe_combinators[i] or {}
	end
	
	if data.mod_changes["crafting_combinator"] then
		for _, force in pairs(game.forces) do
			if force.technologies["circuit-network"].researched then
				force.recipes["crafting-combinator"].enabled = true
				force.recipes["recipe-combinator"].enabled = true
			end
		end
	end]]
end

return migration

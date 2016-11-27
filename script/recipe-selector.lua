local recipe_selector = {}

function recipe_selector.get_recipe(control_behavior, recipe_to_ignore) -- LuaControlBehavior control_behavior, LuaRecipe recipe_to_ignore (optional)
-- searches the connected circuit network for the most suitable recipe signal
	s1, c1 = recipe_selector.get_recipe_from_wire(control_behavior, defines.wire_type.red, recipe_to_ignore)
	s2, c2 = recipe_selector.get_recipe_from_wire(control_behavior, defines.wire_type.green, recipe_to_ignore)
	
	return (c2 > c1 and s2) or s1 -- if c2 is bigger, return s2 else return s1
end

function recipe_selector.get_recipe_from_wire(control_behavior, wire, recipe_to_ignore) -- LuaControlBehavior control_behavior, defines.wire_type wire, LuaRecipe recipe_to_ignore (optional)
-- searches the particular wire type for a recipe signal
	local ings = {}
	if recipe_to_ignore then -- if we have a recipe to ignore, store its ingredients
		for _, r in pairs(recipe_to_ignore.ingredients) do
			ings[r.name] = r.amount
		end
	end
	
	local res
	local n = 0
	
	local cn = control_behavior.get_circuit_network(wire, defines.circuit_connector_id.combinator_input)
	if not cn then return res, n; end -- no network connected - no recipe to be found
	local signals = cn.signals
	local entity = control_behavior.entity
	
	for _, signal in pairs(signals) do
		local s = global.special_cases[signal.signal.name] or signal.signal.name -- if there's a special case for this signal, use it as name, else use the signal name
		local c = ings[s] or 0                                                   -- get the ignored recipe compensation number
		
		if entity.force.recipes[s] and entity.force.recipes[s].enabled and signal.count - c > n then
			res = s
			n = signal.count - c
		end
	end
	
	return res, n
end

return recipe_selector

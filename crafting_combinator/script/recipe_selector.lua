local _M = {}


function _M.get_recipe(control_behavior, items_to_ignore) -- LuaControlBehavior control_behavior, {"item-name"=amount, ...} items_to_ignore (optional)
-- searches the connected circuit network for the most suitable recipe signal
	local items_to_ignore = items_to_ignore or {}
	s1, c1 = _M.get_recipe_from_wire(control_behavior, defines.wire_type.red, items_to_ignore)
	s2, c2 = _M.get_recipe_from_wire(control_behavior, defines.wire_type.green, items_to_ignore)
	
	return (c2 > c1 and s2) or s1, (c2 > c1 and c2) or c1 -- if c2 is bigger, return s2, c2 else return s1, c1
end

function _M.get_recipe_from_wire(control_behavior, wire, items_to_ignore) -- LuaControlBehavior control_behavior, defines.wire_type wire, {"item-name"=amount, ...} items_to_ignore (optional)
-- searches the particular wire type for a recipe signal
	local res = nil
	local n = 0
	
	local cn = control_behavior.get_circuit_network(wire, defines.circuit_connector_id.combinator_input)
	if not cn then return res, n; end -- no network connected - no recipe to be found
	
	local signals = cn.signals or {}
	local entity = control_behavior.entity
	
	for _, signal in pairs(signals) do
		local s = entity.force.recipes[signal.signal.name]
		if s and s.enabled then
			local c = signal.count - (items_to_ignore[s.name] or 0)
			if c > n then
				res = s
				n = c
			end
		end
	end
	
	return res, n
end

function _M.get_highest_signal(control_behavior, items_to_ignore)
	local items_to_ignore = items_to_ignore or {}
	s1, c1 = _M.get_highest_signal_form_wire(control_behavior, defines.wire_type.red, items_to_ignore)
	s2, c2 = _M.get_highest_signal_form_wire(control_behavior, defines.wire_type.green, items_to_ignore)
	
	return (c2 > c1 and s2) or s1, (c2 > c1 and c2) or c1
end

function _M.get_highest_signal_form_wire(control_behavior, wire, items_to_ignore)
	local res = nil
	local n = 0
	
	local cn = control_behavior.get_circuit_network(wire, defines.circuit_connector_id.combinator_input)
	if not cn or not cn.signals then return res, n; end
	
	for _, signal in pairs(cn.signals) do
		local c = signal.count - (items_to_ignore[signal.signal.name] or 0)
		if c > n then
			res = signal.signal.name
			n = c
		end
	end
	
	return res, n
end

function _M.get_recipes(control_behavior, items_to_ignore)
	local highest = _M.get_highest_signal(control_behavior, items_to_ignore)
	if not highest then return {}; end
	
	local recipes = {}
	local item
	if game.item_prototypes[highest] then item = game.item_prototypes[highest]
	elseif game.fluid_prototypes[highest] then item = {name = highest, type = "fluid"}
	else item = {}
	end
	
	for name, recipe in pairs(control_behavior.entity.force.recipes) do
		if not recipe.hidden and recipe.enabled then
			for _, product in pairs(recipe.products) do
				if product.name == item.name and ((item.type ~= "fluid") or (item.type == product.type)) then
					table.insert(recipes, name)
					break
				end
			end
		end
	end
	
	return recipes
end

function _M.get_signal(recipe) -- string recipe
	if game.item_prototypes[recipe] then return {type = "item", name = recipe}; end
	if game.fluid_prototypes[recipe] then return {type = "fluid", name = recipe}; end
	if game.virtual_signal_prototypes[recipe] then return {type = "virtual", name = recipe}; end
end


return _M

local _M = {}


function _M.get_recipe(control_behavior, items_to_ignore) -- LuaControlBehavior control_behavior, {"item-name"=amount, ...} items_to_ignore (optional)
-- searches the connected circuit network for the most suitable recipe signal
	items_to_ignore = items_to_ignore or {}
	s1, c1 = _M.get_recipe_from_wire(control_behavior, defines.wire_type.red, items_to_ignore)
	s2, c2 = _M.get_recipe_from_wire(control_behavior, defines.wire_type.green, items_to_ignore)
	
	return (c2 > c1 and s2) or s1 -- if c2 is bigger, return s2 else return s1
end

function _M.get_recipe_from_wire(control_behavior, wire, items_to_ignore) -- LuaControlBehavior control_behavior, defines.wire_type wire, {"item-name"=amount, ...} items_to_ignore (optional)
-- searches the particular wire type for a recipe signal
	local res = nil
	local n = 0
	
	local cn = control_behavior.get_circuit_network(wire, defines.circuit_connector_id.combinator_input)
	if not cn then return res, n; end -- no network connected - no recipe to be found
	
	local signals = cn.signals
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


return _M

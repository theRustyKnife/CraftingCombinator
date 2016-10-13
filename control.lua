config = require "config"

local refresh_rate = 60

local look_offset = 0.5
local look_distance = 1
local assembler_surroundings_check_distance = 2
local function get_assembler(entity)
	local position = entity.position
	local direction = entity.direction
	
	local area
	
	if direction == defines.direction.north then
		area = {{position.x - look_offset, position.y - look_distance}, {position.x + look_offset, position.y - look_distance}}
	elseif direction == defines.direction.west then
		area = {{position.x - look_distance - 0.1, position.y - look_offset}, {position.x - look_distance + 0.1, position.y + look_offset}}
	elseif direction == defines.direction.south then
		area = {{position.x - look_offset, position.y + look_distance}, {position.x + look_offset, position.y + look_distance}}
	elseif direction == defines.direction.east then
		area = {{position.x + look_distance - 0.1, position.y - look_offset}, {position.x + look_distance + 0.1, position.y + look_offset}}
	end
	
	return entity.surface.find_entities_filtered{area = area, type = "assembling-machine"}[1]
end

local function get_recipe_from_wire(combinator, wire, recipe)
	local ings = {}
	if recipe then
		for _, r in pairs(recipe.ingredients) do
			ings[r.name] = r.amount
		end
	end
	
	local res
	local n = 0
	
	local cn = combinator.get_circuit_network(wire, defines.circuit_connector_id.combinator_input)
	local signals = {}
	if cn then signals = cn.signals end
	for _, signal in pairs(signals) do
		local s = signal.signal.name
		local c = ings[s] or 0
		
		if config.special_cases_r[s] then s = config.special_cases_r[s] end
		if combinator.force.recipes[s] and combinator.force.recipes[s].enabled and signal.count - c > n then
			res = s
			n = signal.count - c
		end
	end
	
	return res, n
end

local function get_recipe(combinator, recipe)
	s1, c1 = get_recipe_from_wire(combinator, defines.wire_type.red, recipe)
	s2, c2 = get_recipe_from_wire(combinator, defines.wire_type.green, recipe)
	
	if c2 > c1 then return s2 end
	return s1
end

local function find_in_global(combinator)
	for i = 0, refresh_rate - 1 do
		for ei, c in pairs(global.combinators[i]) do
			if c.entity == combinator then return c, i, ei end
		end
	end
end

local function on_built(event)
	local entity = event.created_entity
	--crafting-combinator
	if entity.name == "crafting-combinator" then
		local ei
		local n
		for i = 0, refresh_rate - 1 do
			if not n or n >= #global.combinators[i] then
				ei = i
				n = #global.combinators[i]
			end
		end
		entity.rotatable = true
		table.insert(global.combinators[ei], {entity = entity, assembler = get_assembler(entity)})
	end
	if entity.type == "assembling-machine" then
		local area = {
			{entity.position.x - assembler_surroundings_check_distance, entity.position.y - assembler_surroundings_check_distance},
			{entity.position.x + assembler_surroundings_check_distance, entity.position.y + assembler_surroundings_check_distance}
		}
		local combinators = entity.surface.find_entities_filtered{area = area, name = "crafting-combinator"}
		for _, combinator in pairs(combinators) do
			find_in_global(combinator).assembler = get_assembler(combinator)
		end
	end
	
	--recipe-combinator
	if entity.name == "recipe-combinator" then
		local ei
		local n
		for i = 0, refresh_rate - 1 do
			if not n or n >= #global.recipe_combinators[i] then
				ei = i
				n = #global.recipe_combinators[i]
			end
		end
		
		entity.operable = false
		
		res = {entity = entity}
		table.insert(global.recipe_combinators[ei], res)
	end
end

local function on_tick(event)
	for _, combinator in pairs(global.combinators[event.tick % refresh_rate]) do
		if combinator.assembler and combinator.assembler.valid then
			combinator.assembler.recipe = get_recipe(combinator.entity)
		end
	end
	
	for _, combinator in pairs(global.recipe_combinators[event.tick % refresh_rate]) do
		local recipe = get_recipe(combinator.entity, combinator.recipe)
		local params = {}
		if recipe then
			recipe = combinator.entity.force.recipes[recipe]
			combinator.recipe = recipe
			for i, ing in pairs(recipe.ingredients) do
				local r = 0
				if tonumber(ing.amount) % 1 > 0 then r = 1 end
				table.insert(params, {signal = {type = ing.type, name = ing.name}, count = math.floor(tonumber(ing.amount)) + r, index = i})
			end
		end
		combinator.entity.get_or_create_control_behavior().parameters = {enabled = true, parameters = params}
	end
end

local function on_rotated(event)
	local entity = event.entity
	if entity.name == "crafting-combinator" then
		find_in_global(entity).assembler = get_assembler(entity)
	end
end

local function on_destroyed(event)
	local entity = event.entity
	--crafting-combinator
	if entity.name == "crafting-combinator" then
		for i = 0, refresh_rate - 1 do
			for ei, combinator in pairs(global.combinators[i]) do
				if combinator.entity == entity then
					table.remove(global.combinators[i], ei)
					return
				end
			end
		end
	end
	if entity.type == "assembling-machine" then
		local area = {
			{entity.position.x - assembler_surroundings_check_distance, entity.position.y - assembler_surroundings_check_distance},
			{entity.position.x + assembler_surroundings_check_distance, entity.position.y + assembler_surroundings_check_distance}
		}
		local combinators = entity.surface.find_entities_filtered{area = area, name = "crafting-combinator"}
		for _, combinator in pairs(combinators) do
			find_in_global(combinator).assembler = get_assembler(combinator)
		end
	end
	
	--recipe-combinator
	if entity.name == "recipe-combinator" then
		for i = 0, refresh_rate - 1 do
			for ei, v in pairs(global.recipe_combinators) do
				if v.entity == entity then
					table.remove(global.recipe_combinators[i], ei)
					break
				end
			end
		end
	end
end

script.on_init(function()
	global.combinators = global.combinators or {}
	global.recipe_combinators = global.recipe_combinators or {}
	for i = 0, refresh_rate - 1 do
		global.combinators[i] = global.combinators[i] or {}
		global.recipe_combinators[i] = global.recipe_combinators[i] or {}
	end
end)

script.on_configuration_changed(function(data)
	global.combinators = global.combinators or {}
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
	end
end)

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)

script.on_event(defines.events.on_preplayer_mined_item, on_destroyed)
script.on_event(defines.events.on_robot_pre_mined, on_destroyed)
script.on_event(defines.events.on_entity_died, on_destroyed)

script.on_event(defines.events.on_tick, on_tick)

script.on_event(defines.events.on_player_rotated_entity, on_rotated)
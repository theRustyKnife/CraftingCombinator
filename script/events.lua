local config = require ".config"
local migration = require ".migration"
local entities = require ".entities"


local function on_built(event)
	local entity = event.created_entity
	
	if entity.name == config.CC_NAME then     entities.CraftingCombinator:new(entity):get_assembler()
	elseif entity.name == config.RC_NAME then entities.RecipeCombinator:new(entity)
	end
	
	if entity.type == "assembling-machine" then
		entities.CraftingCombinator.update_assemblers_around(entity.surface, entity.position)
	end
end

local function on_destroyed(event)
	local entity = event.entity
	
	entities.try_destroy(entity)
		
	if entity.type == "assembling-machine" then
		entities.CraftingCombinator.update_assemblers_around(entity.surface, entity.position)
	end
end

local function on_tick(event)
	local tab = global.combinators[event.tick % config.REFRESH_RATE]
	for i = 1, #tab do
		tab[i]:update()
	end
end

local function on_rotated(event)
	local entity = event.entity
	if entity.name == config.CC_NAME then
		find_in_global(entity):get_assembler()
	end
end


script.on_init(migration.init)

script.on_configuration_changed(migration.migrate)

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)

script.on_event(defines.events.on_preplayer_mined_item, on_destroyed)
script.on_event(defines.events.on_robot_pre_mined, on_destroyed)
script.on_event(defines.events.on_entity_died, on_destroyed)

script.on_event(defines.events.on_tick, on_tick)

script.on_event(defines.events.on_player_rotated_entity, on_rotated)
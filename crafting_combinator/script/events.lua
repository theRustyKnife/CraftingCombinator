local config = require "config"
local entities = require "therustyknife.crafting_combinator.entities"
local FML = require "therustyknife.FML"
local gui = require ".gui"


FML.global.on_init(function()
	global.to_close = global.to_close or {}
end)


local _M = {}


local function on_built(entity)
	if entity.valid and entity.type == "assembling-machine" then
		entities.CraftingCombinator.update_assemblers(entity.surface, entity.position)
	end
end

function _M.on_built(event)
	local entity = event.created_entity
	
	if entity.name == config.RC_NAME then entities.RecipeCombinator:new(entity, true); end
	if entity.name == config.CC_NAME then entities.CraftingCombinator:new(entity, true); end
	
	if entity.name == "entity-ghost" then FML.blueprint_data.check_built_entity(entity, true); end
	
	on_built(entity)
end
function _M.on_robot_built(event)
	local entity = event.created_entity
	
	if entity.name == config.RC_NAME then entities.RecipeCombinator:new(entity, true) end
	if entity.name == config.CC_NAME then entities.CraftingCombinator:new(entity, true) end
	
	on_built(entity)
end


function _M.on_destroyed(event)
	local entity = event.entity
	local player
	if event.player_index then player = game.players[event.player_index]; end
	
	entities.util.try_destroy(entity, player)
	
	if entity.type == "assembling-machine" then
		entities.CraftingCombinator.update_assemblers(entity.surface, entity.position)
	end
	
	if entity.name == "entity-ghost" then FML.blueprint_data.destroy_proxy(entity); end
end

local function run_update(tab, tick, rate)
	for i = tick % rate + 1, #tab, rate do tab[i]:update(); end
end

function _M.on_tick(event)
	for i, c in pairs(global.to_close) do
		c.entity.operable = true
		global.to_close[i] = nil
	end
	
	-- Execute delayed updates (emptying inserter hands)
	if global.delayed_run then
		if global.delayed_run[event.tick] then
			for _, e in pairs(global.delayed_run[event.tick]) do e:delayed_run(); end
			global.delayed_run[event.tick] = nil
		end
	else global.delayed_run = {}; end
	
	run_update(global.combinators.crafting, event.tick, settings.global[config.SETTING_NAME_REFRESH_RATE_CC].value+1)
	run_update(global.combinators.recipe, event.tick, settings.global[config.SETTING_NAME_REFRESH_RATE_RC].value+1)
end

function _M.on_rotated(event)
	local entity = event.entity
	
	if entity.name == config.CC_NAME then
		entities.util.find_in_global(entity):find_assembler()
	end
end

function _M.on_paste(event)
	local source = entities.util.find_in_global(event.source)
	local destination = entities.util.find_in_global(event.destination)
	
	if source and destination and source.type == destination.type then
		FML.blueprint_data.copy(source.entity, destination.entity)
		destination.settings = FML.table.deep_copy(source.settings)
		
		destination:update(true)
	end
end

function _M.on_menu_key_pressed(event)
	local player = game.players[event.player_index]
	local entity = player.selected
	if entity and not player.cursor_stack.valid_for_read then
		local combinator = entities.util.find_in_global(entity)
		if combinator then
			combinator.entity.operable = false
			combinator:open(event.player_index)
		end
	end
end

function _M.on_close_menu_key_pressed(event)
	gui.destroy_entity_frame(event.player_index)
end


return _M

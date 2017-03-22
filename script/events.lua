local config = require "config"
local entities = require "therustyknife.crafting_combinator.entities"
local FML = require "therustyknife.FML"


FML.global.on_init(function()
	global.settings = {refresh_rate = {cc = config.REFRESH_RATE_CC, rc = config.REFRESH_RATE_RC}}
end)


local _M = {}


function _M.on_built(event)
	local entity = event.created_entity
	
	if entity.name == config.RC_NAME then entities.RecipeCombinator:new(entity); end
	if entity.name == config.CC_NAME then entities.CraftingCombinator:new(entity); end
	
	if entity.type == "assembling-machine" then
		entities.CraftingCombinator.update_assemblers(entity.surface, entity.position)
	end
end

function _M.on_destroyed(event)
	local entity = event.entity
	local player
	if event.player_index then player = game.players[event.player_index]; end
	
	entities.util.try_destroy(entity, player)
	
	if entity.type == "assembling-machine" then
		entities.CraftingCombinator.update_assemblers(entity.surface, entity.position)
	end
end

local function run_update(tab, tick, rate)
	for i = tick % rate + 1, #tab, rate do tab[i]:update(); end
end

function _M.on_tick(event)
	run_update(global.combinators.crafting, event.tick, global.settings.refresh_rate.cc)
	run_update(global.combinators.recipe, event.tick, global.settings.refresh_rate.rc)
end

function _M.on_rotated(event)
	local entity = event.entity
	
	if entity.name == config.CC_NAME then
		entities.util.find_in_global(entity):find_assembler()
	end
end

function _M.on_menu_key_pressed(event)
	local player = game.players[event.player_index]
	local entity = player.selected
	if entity and not player.cursor_stack.valid_for_read then
		local combinator = entities.util.find_in_global(entity)
		if combinator then combinator:on_opened(player); end
	end
end


return _M

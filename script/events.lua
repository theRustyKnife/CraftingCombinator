local config = require "config"
local entities = require "therustyknife.crafting_combinator.entities"


local _M = {}


function _M.on_built(event)
	local entity = event.created_entity
	
	if entity.name == config.RC_NAME then entities.RecipeCombinator:new(entity); end
	if entity.name == config.CC_NAME then entities.CraftingCombinator:new(entity); end
end

function _M.on_destroyed(event)
	local entity = event.entity
	
	entities.util.try_destroy(entity)
end

function _M.on_tick(event)
	for _, tab in pairs{
		global.entities.recipe[event.tick % config.REFRESH_RATE_RC],
		global.entities.crafting[event.tick % config.REFRESH_RATE_CC],
	} do
		for i = 1, #tab do tab[i]:update(); end
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

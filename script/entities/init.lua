local FML = require "therustyknife.FML"
local config = require "config"


FML.global.on_init(function()
	global.combinators = global.combinators or {}
	global.combinators.all = global.combinators.all or {}
end)


local _M = {}

package.loaded["therustyknife.crafting_combinator.entities"] = _M


_M.util = {}

_M.util.entity_names = {[config.CC_NAME] = true, [config.RC_NAME]= true}


function _M.util.try_destroy(entity, player) -- player is optional and only used for CraftingCombinator
	if _M.util.entity_names[entity.name] then
		local c = _M.util.find_in_global(entity)
		if c then
			c:destroy(player)
			return true
		end
	end
	return false
end

function _M.util.find_in_global(entity)
	for _, combinator in ipairs(global.combinators.all) do
		if combinator.entity == entity then return combinator; end
	end
	return nil
end


_M.Combinator = require ".Combinator"
_M.RecipeCombinator = require ".RecipeCombinator"
_M.CraftingCombinator = require ".CraftingCombinator"


return _M

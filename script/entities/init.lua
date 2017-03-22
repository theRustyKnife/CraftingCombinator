local FML = require "therustyknife.FML"

local config = require "config"


FML.global.on_init(function()
	global.entities = global.entities or {}
end)


local _M = {}

package.loaded["therustyknife.crafting_combinator.entities"] = _M


_M.util = {}

_M.util.entity_names = {[config.CC_NAME] = true, [config.RC_NAME]= true}

local function update_count_on_tick(tick)
	local res = 0
	for _, tab in pairs(global.entities) do
		if tab[tick] then res = res + #tab[tick]; end
	end
	return res
end

function _M.util.get_best_index(max_index)
	local best_i = 0
	local best = update_count_on_tick(0)
	
	for i = 1, max_index do
		local count = update_count_on_tick(i)
		if count < best then
			best_i = i
			best = count
		end
	end
	
	return best_i
end

function _M.util.try_destroy(entity)
	if _M.util.entity_names[entity.name] then
		local e = _M.util.find_in_global(entity)
		if e then
			e:destroy()
			return true
		end
	end
	return false
end

function _M.util.find_in_global(entity)
	for _, type in pairs(global.entities) do
		for __, tab in pairs(type) do
			for ___, e in pairs(tab) do
				if e.entity == entity then return e; end
			end
		end
	end
	return nil
end


_M.Combinator = require ".Combinator"
_M.RecipeCombinator = require ".RecipeCombinator"
_M.CraftingCombinator = require ".CraftingCombinator"


return _M

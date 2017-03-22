local FML = require "therustyknife.FML"
local entities = require "therustyknife.crafting_combinator.entities"
local config = require "config"
local recipe_selector = require "script.recipe_selector"
local gui = require "script.gui"


FML.global.on_init(function()
	global.entities.recipe = global.entities.recipe or {}
	for i = 0, config.REFRESH_RATE_RC do
		global.entities.recipe[i] = global.entities.recipe[i] or {}
	end
end)


local _M = entities.Combinator:extend()


_M.REFRESH_RATE = config.REFRESH_RATE_RC

FML.global.on_load(function() _M.tab = global.entities.recipe end)


function _M:on_create()
	self.product_mode = false -- default to ingredient mode
	self.entity.operable = false
end

function _M:update(forced)
	local recipe = recipe_selector.get_recipe(self.control_behavior, self.items_to_ignore)
	
	if self.recipe ~= recipe or forced then
		self.recipe = recipe
		self.items_to_ignore = {}
		
		local params = {}
		
		if recipe then
			for i, ing in pairs((self.product_mode and recipe.products) or recipe.ingredients) do
				local t_amount = tonumber(ing.amount or ing.amount_min or ing.amount_max)
				local amount = math.floor(t_amount)
				if t_amount % 1 > 0 then amount = amount + 1; end
				
				table.insert(params, {
						signal = {type = ing.type, name = ing.name},
						count = amount,
						index = i,
					})
				
				self.items_to_ignore[ing.name] = amount
			end
			
			table.insert(params, {
					signal = {type = "virtual", name = config.TIME_NAME},
					count = math.floor(tonumber(recipe.energy) * 10),
					index = config.RC_SLOT_COUNT,
				})
		end
		
		self.control_behavior.parameters = {enabled = true, parameters = params}
	end
end

function _M:on_opened(player)
	gui.recipe_combinator_settings(self, player)
end


return _M

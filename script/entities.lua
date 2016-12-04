local config = require ".config"
local util = require ".util"
local recipe_selector = require ".recipe-selector"


local entities = {}
entities.names = {[config.CC_NAME] = true, [config.RC_NAME]= true}

function entities.try_destroy(entity)
	if entities.names[entity.name] then
		local e = entities.find_in_global(entity)
		if e then
			e:destroy()
			return true
		end
	end
	return false
end

function entities.find_in_global(entity)
	for i = 0, config.REFRESH_RATE - 1 do
		for _, v in pairs(global.combinators[i]) do
			if v.entity == entity then return v; end
		end
	end
end

function entities.get_next_index()
	-- returns the next most suitable index
	best_i = 0
	best = #global.combinators[0]

	for i = 1, config.REFRESH_RATE - 1 do
		if #global.combinators[i] < best then
			best_i = i
			best = #global.combinators[i]
		end
	end

	return best_i
end

entities.RecipeCombinator = {}
-------------------------------------------------------
function entities.RecipeCombinator:new(entity)
	local res = {
		tab = global.combinators[entities.get_next_index()],
		entity = entity,
		control_behavior = entity.get_or_create_control_behavior(),
		type = "recipe-combinator",
	}
	
	setmetatable(res, self)
	self.__index = self
	
	table.insert(res.tab, res)
	
	return res
end

function entities.RecipeCombinator:extend()
	child = {}
	setmetatable(child, self)
	self.__index = self
	return child
end

function entities.RecipeCombinator:destroy()
	table.remove(self.tab, self:get_index())
end

function entities.RecipeCombinator:get_index()
	for i, v in pairs(self.tab) do
		if v.entity == self.entity then return i; end
	end
end

function entities.RecipeCombinator:update()
	local recipe = recipe_selector.get_recipe(self.control_behavior, self.recipe)
	local params = {}
	if recipe then
		recipe = self.entity.force.recipes[recipe]
		self.recipe = recipe
		for i, ing in pairs(recipe.ingredients) do
			local r = 0
			if tonumber(ing.amount) % 1 > 0 then r = 1 end
			table.insert(params, {signal = {type = ing.type, name = ing.name}, count = math.floor(tonumber(ing.amount)) + r, index = i})
		end
		
		table.insert(params, {signal = {type = "virtual", name = "recipe-time"}, count = tonumber(recipe.energy) * 10, index = 20})
	end
	self.control_behavior.parameters = {enabled = true, parameters = params}
end

entities.CraftingCombinator = entities.RecipeCombinator:extend()
--------------------------------
function entities.CraftingCombinator.update_assemblers_around(surface, position)
	local combinators = surface.find_entities_filtered{area = util.get_area(position, config.CC_SEARCH_DISTANCE), name = config.CC_NAME}
	for _, combinator in pairs(combinators) do
		entities.find_in_global(combinator):get_assembler()
	end
end

function entities.CraftingCombinator:new(entity)
	local res = entities.RecipeCombinator:new(entity)
	res.type = "crafting-combinator"
	
	setmetatable(res, self)
	self.__index = self
	
	res:get_assembler()
	res.overflow = entity.surface.create_entity{name = config.CHEST_NAME, position = entity.position, force = entity.force} -- create the overflow chest
	res.overflow.destructible = false
	
	return res
end

function entities.CraftingCombinator:destroy()
	self.overflow.destroy()
	entities.RecipeCombinator.destroy(self)
end

function entities.CraftingCombinator:get_assembler()
	self.assembler = self.entity.surface.find_entities_filtered{
		area = util.get_directional_search_area(self.entity.position, self.entity.direction, config.CC_ASSEMBLER_SEARCH_DISTANCE, config.CC_ASSEMBLER_SEARCH_OFFSET),
		type = "assembling-machine",
	}[1]
end

function entities.CraftingCombinator:update()
	if self.assembler and self.assembler.valid then
		local recipe = recipe_selector.get_recipe(self.control_behavior) -- get the recipe selected by the cn
		
		-- if there was an active recipe and it has changed, copy the items from the assembler into the overflow chest
		if self.control_behavior.enabled and self.assembler.recipe and ((not recipe) or recipe ~= self.assembler.recipe.name) then
			local input_inv = self.assembler.get_inventory(defines.inventory.assembling_machine_input)
			local output_inv = self.assembler.get_inventory(config.ASSEMBLING_MACHINE_OUTPUT_INDEX)
			
			for i = 1, #output_inv do -- copy output inventory
				local s = output_inv[i]
				if s.valid_for_read and self.overflow.can_insert(s) then
					self.overflow.insert(s)
				end
			end
			for i = 1, #input_inv do -- copy input inventory
				local s = input_inv[i]
				if s.valid_for_read and self.overflow.can_insert(s) then
					self.overflow.insert(s)
				end
			end
		end
		
		self.assembler.recipe = recipe
	end
end

return entities

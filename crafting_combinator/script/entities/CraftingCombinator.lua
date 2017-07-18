local FML = therustyknife.FML
local blueprint_data = FML.blueprint_data
local table = FML.table

local config = require "config"
local Combinator = require ".Combinator"
local recipe_selector = require "script.recipe-selector"


local INVENTORIES = blueprint_data.get_enum(config.NAME.CC_SETTINGS, "item_dest")
local INVENTORIES_LUT = {}; for name, i in pairs(INVENTORIES) do INVENTORIES_LUT[i] = name; end


local _M = Combinator:extend(function(self, entity)
	self = self.super.new(self, entity)
	
	self.settings = blueprint_data.get(self.entity, config.NAME.CC_SETTINGS)
	self.modules_to_request = {}
	self.inventories = {assembler = {}}
	
	self.chests = {
		passive = self.entity.surface.create_entity{
			name = config.NAME.OVERFLOW_P,
			position = self.entity.position,
			force = self.entity.force
		},
		active = self.entity.surface.create_entity{
			name = config.NAME.OVERFLOW_A,
			position = self.entity.position,
			force = self.entity.force
		},
		normal = self.entity.surface.create_entity{
			name = config.NAME.OVERFLOW_N,
			position = self.entity.position,
			force = self.entity.force
		},
	}
	for type, chest in pairs(self.chests) do
		chest.destructible = false
		self.inventories[type] = chest.get_inventory(defines.inventory.chest)
	end
	
	self:find_assembler()
	
	return self
)


FML.events.on_load(function()
	global.combinators.crafting = table(global.combinators.crafting)
	_M.tab = global.combinators.crafting
	
	for _, o in pairs(_M.tab) do _M:load(o); end
end)

--TODO: read bottleneck signals on_config_change


_M.TYPE = "crafting"


function _M:update()
	if self.item_request_proxy and not self.item_request_proxy.valid then self.item_request_proxy = nil; end
	
	local params = table()
	if self.assembler and self.assembler.valid then
		-- Set mode
		if self.settings.mode_set then
			local recipe = recipe_selector.get_recipe(self.control_behavior, self.items_to_ignore)
			
			if self.assembler.recipe and ((not recipe) or recipe ~= self.assembler.recipe) then
				local target = self:get_target(self.settings.item_dest)
				self:move_items(target)
				self:empty_inserters(target)
			end
			
			if recipe and recipe ~= self.assembler.recipe then
				self:move_modules(recipe)
				if self.item_request_proxy then self:check_requested_modules(recipe); end
				if self.settings.request_modules then self:request_modules(recipe); end
			end
			
			self.assembler.recipe = recipe
		end
		
		-- Read mode
		if self.settings.mode_read and self.assembler.recipe then
			for type, type_tab in pairs{
						item = game.item_prototypes,
						fluid = game.fluid_prototypes,
						virtual = game.virtual_signal_prototypes,
					} do
				local prototype = type_tab[self.assembler.recipe.name]
				if prototype then
					params:insert{
						signal = {type = type, name = prototype.name},
						count = 1,
						index = 1,
					}
					self.items_to_ignore = {[prototype.name] = 1}
					break
				end
			end
		else self.items_to_ignore = nil; end
		
		-- Read speed
		if self.settings.read_speed then
			params:insert{
				signal = {type = "virtual", name = config.NAME.SPEED},
				count = game.entity_prototypes[self.assembler.name].crafting_speed * 100,
				index = 2,
			}
		end
		
		--Read Bottleneck
		if self.settings.read_bottleneck then
			local state = (remote.call("Bottleneck", "get_signal_data", self.assembler.unit_number) or {}).status
			local name
			--TODO: finish
		end
	end
end


function _M:find_assembler()
	self.assembler = self.entity.surface.find_entities_filtered{
		area = FML.surface.square(
				FML.surface.move(self.entity.position, self.entity.direction, config.CC_ASSEMBLER_DISTANCE),
				config.CC_ASSEMBLER_OFFSET
			),
		type = "assembling-machine",
	}[1]
	
	if self.assembler then
		self.inventories.assembler = {
			output = self.assembler.get_inventory(defines.inventory.assembling_machine_output),
			input = self.assembler.get_inventory(defines.inventory.assembling_machine_input),
			modules = self.assembler.get_inventory(defines.inventory.assembling_machine_modules),
		}
	else self.inventories.assembler = {}; end
end

local empty_target = {insert = function() end} -- When no chest is selected as overflow output
function _M:get_target(mode)
	if mode == INVENTORIES.none then return empty_target; end
	return self.chests[INVENTORIES_LUT[mode]]
end

function _M:move_items(target)
	for _, inventory in pairs{self.inventories.assembler.input, self.inventories.assembler.output} do
		for i=1, #inventory do
			local stack = inventory[i]
			if stack.valid_for_read then target.insert(stack); end
		end
	end
	
	if self.assembler.crafting_progress > 0 then
		for _, ing in pairs(self.assembler.recipe.ingredients) do
			if ing.type == "item" then
				target.insert{name = ing.name, count = ing.amount}
			end
		end
	end
end

function _M:empty_inserters(target)
	if self.settings.empty_inserters then
		for _, inserter in pairs(self.assembler.surface.find_entities_filtered{
					area = FML.surface.square(self.assembler.position, config.CC_INSERTER_SEARCH_DISTANCE),
					type = "inserter",
				}) do
			if inserter.drop_target == self.assembler then
				local stack = inserter.held_stack
				if stack.valid_for_read then
					target.insert(stack)
					stack.count = 0
				end
			end
		end
	end
end

function _M:move_modules(recipe)
	local target = self:get_target(self.settings.module_dest)
	local inventory = self.inventories.assembler.modules
	
	for i=1, #inventory do
		local stack = inventory[i]
		if stack.valid_for_read then
			local limitations = game.item_prototypes[stack.name].limitations
			if limitations and not table.is_empty(limitations) and not limitations[recipe.name] then
				target.insert(stack)
				if self.settings.request_modules then
					if self.modules_to_request[stack.name] then
						self.modules_to_request[stack.name] = self.modules_to_request[stack.name] + stack.count
					else self.modules_to_request[stack.name] = stack.count; end
				end
			end
		end
	end
end

function _M:check_requested_modules(recipe)
	for name, count in pairs(self.item_request_proxy.item_requests) do
		local limitations = game.item_prototypes[name].limitations
		if not limitations[recipe.name] and not table.is_empty(limitations) then
			self.item_request_proxy.item_requests[name] = 0
			if self.settings.request_modules then
				self.modules_to_request[name] = self.modules_to_request[name] or 0
				self.modules_to_request[name] = self.modules_to_request[name] + count
			end
		end
	end
end


return _M

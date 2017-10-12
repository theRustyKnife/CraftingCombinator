local FML = therustyknife.FML
local blueprint_data = FML.blueprint_data
local table = FML.table
local log = FML.log
local GUI = FML.GUI

local config = require "config"
local Combinator = require ".Combinator"
local recipe_selector = require "script.recipe-selector"


local _M = Combinator:extend("therustyknife.crafting_combinator.CraftingCombinator", function(self, entity)
	self = self.super.new(self, entity)
	
	FML.log.dump("Built a CraftingCombinator at ", self.entity.position)
	
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
end)

function _M:destroy(player)
	FML.log.dump("Destroying a CraftingCombinator at ", self.entity.position)
	
	self.settings:_reset()
	
	for _, inventory in ipairs{self.inventories.passive, self.inventories.active, self.inventories.normal} do
		for i=1, #inventory do
			local stack = inventory[i]
			if stack.valid_for_read then
				local remaining = stack.count
				if player then remaining = remaining - player.insert(stack); end
				if remaining > 0 then
					stack.count = remaining
					self.entity.surface.spill_item_stack(self.entity.position, stack, true)
				end
			end
		end
	end
	
	for _, chest in pairs(self.chests) do chest.destroy(); end
	
	if self.gui and self.gui.valid then
		self.gui.destroy()
		GUI.controls.prune()
	end
	
	_M.super.destroy(self)
end


local function load_bottleneck()
	if game.active_mods["Bottleneck"] then global.BOTTLENECK_STATES = remote.call("Bottleneck", "get_states"); end
end
FML.events.on_config_change(load_bottleneck); FML.events.on_init(load_bottleneck)


FML.events.on_built(function(event)
	local entity = event.created_entity
	if entity.name == config.NAME.CC then _M(entity); end
	if entity.type == "assembling-machine" then
		_M.update_assemblers(entity.surface, entity.position, entity.bounding_box)
	end
end)

FML.events.on_destroyed(function(event)
	local entity = event.entity
	local player = event.player_index and game.players[event.player_index]
	
	if entity.name == config.NAME.CC then Combinator.get(entity):destroy(player); end
	if entity.type == "assembling-machine" then
		_M.update_assemblers(entity.surface, entity.position, entity.bounding_box)
	end
end)

FML.events.on_player_rotated_entity(function(event)
	local entity = event.entity
	if entity.name == config.NAME.CC then Combinator.get(entity):find_assembler(); end
end)


GUI.watch_opening(config.NAME.CC, function(event)
--f on_open
--% private static
--- Sets up the GUI when a player opens a combinator.
--@ GuiOpenedEventData event
--: LuaGuiElement: The root element of the GUI
	if event.status then return nil; end
	
	local self = Combinator.get(event.entity)
	
	local parent = GUI.entity_base{
		parent = event.player.gui.center,
		entity = event.entity,
		cam_zoom = 1,
	}
	self.gui = parent.root
	
	-- Mode
	GUI.controls.CheckboxGroup{
		parent = parent.title,--GUI.entity_segment{parent = parent.primary, title = {"crafting_combinator-gui.cc-mode"}},
		name = "mode",
		options = {
			{name = "mode_set", state = self.settings.mode_set, caption = {"crafting_combinator-gui.cc-mode-set"}},
			{name = "mode_read", state = self.settings.mode_read, caption = {"crafting_combinator-gui.cc-mode-read"}},
			{name = "read_speed", state = self.settings.read_speed, caption = {"crafting_combinator-gui.cc-read-speed"}},
			game.active_mods["Bottleneck"] and {name = "read_bottleneck", state = self.settings.read_bottleneck, caption = {"crafting_combinator-gui.cc-read-bottleneck"}} or nil,
		},
		on_change = "therustyknife.crafting_combinator.cc_mode_change",
		meta = self,
		link_name = "therustyknife.crafting_combinator.CraftingCombinator.main.mode."..string.format("%d", self.entity.unit_number),
	}
	
	local dest_enum = blueprint_data.get_enum(config.NAME.CC_SETTINGS, "item_dest")
	local dests = {
		{name = dest_enum.active, caption = {"crafting_combinator-gui.cc-dest-active"}},
		{name = dest_enum.passive, caption = {"crafting_combinator-gui.cc-dest-passive"}},
		{name = dest_enum.normal, caption = {"crafting_combinator-gui.cc-dest-normal"}},
		{name = dest_enum.none, caption = {"crafting_combinator-gui.cc-dest-none"}},
	}
	
	-- Item dest
	GUI.controls.RadiobuttonGroup{
		parent = GUI.entity_segment{parent = parent.primary, title = {"crafting_combinator-gui.cc-item-dest"}},
		name = "item_dest",
		options = dests,
		selected = self.settings.item_dest,
		on_change = "therustyknife.crafting_combinator.cc_radio_change",
		meta = self,
		direction = "horizontal",
		link_name = "therustyknife.crafting_combinator.CraftingCombinator.main.item_dest."..string.format("%d", self.entity.unit_number),
	}
	
	-- Module dest
	GUI.controls.RadiobuttonGroup{
		parent = GUI.entity_segment{parent = parent.primary, title = {"crafting_combinator-gui.cc-module-dest"}},
		name = "module_dest",
		options = dests,
		selected = self.settings.module_dest,
		on_change = "therustyknife.crafting_combinator.cc_radio_change",
		meta = self,
		direction = "horizontal",
		link_name = "therustyknife.crafting_combinator.CraftingCombinator.main.module_dest."..string.format("%d", self.entity.unit_number),
	}
	
	-- Misc
	GUI.controls.CheckboxGroup{
		parent = GUI.entity_segment{parent = parent.primary, title = {"crafting_combinator-gui.cc-misc"}},
		name = "misc",
		options = {
			{name = "empty_inserters", state = self.settings.empty_inserters, caption = {"crafting_combinator-gui.cc-empty-inserters"}},
			{name = "request_modules", state = self.settings.request_modules, caption = {"crafting_combinator-gui.cc-request-modules"}},
		},
		on_change = "therustyknife.crafting_combinator.cc_mode_change",
		meta = self,
		link_name = "therustyknife.crafting_combinator.CraftingCombinator.main.misc."..string.format("%d", self.entity.unit_number),
	}
	
	return parent.root
end)

FML.handlers.add("therustyknife.crafting_combinator.cc_mode_change", function(group)
	local settings = group.meta.settings
	for name, state in pairs(group.values) do settings[name] = state; end
end)

FML.handlers.add("therustyknife.crafting_combinator.cc_radio_change", function(group)
	group.meta.settings[group.name] = tonumber(group.value)
end)


function _M.update_assemblers(surface, position, box)
	FML.log.dump("Updating assemblers around ", surface.name, position)
	box = box and FML.surface.expand(box, config.CC_ASSEMBLER_SEARCH_DISTANCE)
			or FML.surface.square(position, config.CC_ASSEMBLER_SEARCH_DISTANCE)
	log.dump("\tbox: ", box)
	for _, entity in pairs(surface.find_entities_filtered{area = box, name = config.NAME.CC}) do
		Combinator.get(entity):find_assembler()
	end
end


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
			if state == global.BOTTLENECK_STATES.STOPPED then name = "signal-red"
			elseif state == global.BOTTLENECK_STATES.FULL then name = "signal-yellow"
			elseif state == global.BOTTLENECK_STATES.RUNNING then name = "signal-green"
			end
			if name then
				params:insert{
					signal = {type = "virtual", name = name},
					count = 1,
					index = 3,
				}
			end
		end
	end
	
	self.control_behavior.parameters = {enabled = true, parameters = params}
end


function _M:find_assembler()
	log.d("Serching for assembler around CraftingCombinator unit_number="..self.entity.unit_number.."...")
	self.assembler = self.entity.surface.find_entities_filtered{
		area = FML.surface.square(
				FML.surface.move(self.entity.position, self.entity.direction, config.CC_ASSEMBLER_DISTANCE),
				config.CC_ASSEMBLER_OFFSET
			),
		type = "assembling-machine",
	}[1]
	
	if self.assembler then
		log.d("Found assembler unit_number="..self.assembler.unit_number)
		self.inventories.assembler = {
			output = self.assembler.get_inventory(defines.inventory.assembling_machine_output),
			input = self.assembler.get_inventory(defines.inventory.assembling_machine_input),
			modules = self.assembler.get_inventory(defines.inventory.assembling_machine_modules),
		}
	else log.d("No assembler found"); self.inventories.assembler = {}; end
end

local inventories
local inventories_lut
local empty_target = {insert = function() end} -- When no chest is selected as overflow output
function _M:get_target(mode)
	if not inventories then
		inventories = blueprint_data.get_enum(config.NAME.CC_SETTINGS, "item_dest")
		inventories_lut = {}; for name, i in pairs(inventories) do inventories_lut[i] = name; end
	end
	if mode == inventories.none then return empty_target; end
	return self.chests[inventories_lut[mode]]
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

function _M:request_modules(recipe)
	local to_request
	if self.item_request_proxy then to_request = table(self.item_request_proxy.item_requests)
	else to_request = table(); end
	
	for name, count in pairs(self.modules_to_request) do
		local limitations = table(game.item_prototypes[name.limitations])
		if limitations[recipe.name] or limitations:is_empty() then
			to_request[name] = to_request[name] or 0
			to_request[name] = to_request[name] + count
			self.modules_to_request[name] = nil
		end
	end
	
	if not self.item_request_proxy and not to_request:is_empty() then
		local modules = table()
		for name, count in to_request:pairs() do modules:insert{item = name, count = count}; end
		
		self.item_request_proxy = FML.random_util.make_request(self.assembler, modules)
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

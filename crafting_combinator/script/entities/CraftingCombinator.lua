local entities = require "therustyknife.crafting_combinator.entities"
local FML = require "therustyknife.FML"
local config = require "config"
local recipe_selector = require "script.recipe_selector"
local gui = require "script.gui"

local settings = FML.blueprint_data.settings


local function load_bottleneck()
	if game.active_mods["Bottleneck"] then global.BOTTLENECK_STATES = remote.call("Bottleneck", "get_states"); end
end

FML.global.on_init(function()
	global.combinators.crafting = global.combinators.crafting or {}
	load_bottleneck()
end)

FML.global.on_config_change(load_bottleneck)


local _M = entities.Combinator:extend()

_M.TYPE = "crafting"

FML.global.on_load(function()
	_M.tab = global.combinators.crafting
	
	for _, o in pairs(global.combinators.crafting or {}) do _M:load(o); end
end)


function _M.update_assemblers(surface, position)
	local found = surface.find_entities_filtered{
		area = FML.surface.area_around(position, config.CC_SEARCH_DISTANCE),
		name = config.CC_NAME,
	}
	
	for _, entity in pairs(found) do
		local c = entities.util.find_in_global(entity)
		if c then c:find_assembler(); end
	end
end


function _M:on_create(blueprint)
	self.settings = {
		cc_mode_set = true,
		cc_mode_read = false,
		
		cc_module_dest = settings.cc_module_dest.options.passive,
		cc_item_dest = settings.cc_item_dest.options.active,
		
		cc_empty_inserters = true,
		cc_request_modules = true,
		cc_read_speed = false,
		cc_read_bottleneck = false,
	}
	
	self.modules_to_request = {}
	
	if blueprint then
		local mode_set = FML.blueprint_data.read(self.entity, settings.cc_mode_set, false)
		if mode_set ~= nil then self.settings.cc_mode_set = mode_set; end
		
		local mode_read = FML.blueprint_data.read(self.entity, settings.cc_mode_read, false)
		if mode_read ~= nil then self.settings.cc_mode_read = mode_read; end
		
		self.settings.cc_module_dest = FML.blueprint_data.read(self.entity, settings.cc_module_dest, false) or self.settings.cc_module_dest
		self.settings.cc_item_dest = FML.blueprint_data.read(self.entity, settings.cc_item_dest, false) or self.settings.cc_item_dest
		
		local empty = FML.blueprint_data.read(self.entity, settings.cc_empty_inserters, false)
		if empty ~= nil then self.settings.cc_empty_inserters = empty; end
		
		local request = FML.blueprint_data.read(self.entity, settings.cc_request_modules, false)
		if request ~= nil then self.settings.cc_request_modules = request; end
		
		local read_speed = FML.blueprint_data.read(self.entity, settings.cc_read_speed, false)
		if read_speed ~= nil then self.settings.cc_read_speed = read_speed; end
		
		local read_bottleneck = FML.blueprint_data.read(self.entity, settings.cc_read_bottleneck, false)
		if game.active_mods["Bottleneck"] and read_bottleneck ~= nil then self.settings.cc_read_bottleneck = read_bottleneck; end
	end
	
	self.chests = {
		passive = self.entity.surface.create_entity{
			name = config.OVERFLOW_P_NAME,
			position = self.entity.position,
			force = self.entity.force,
		},
		active = self.entity.surface.create_entity{
			name = config.OVERFLOW_A_NAME,
			position = self.entity.position,
			force = self.entity.force,
		},
		normal = self.entity.surface.create_entity{
			name = config.OVERFLOW_N_NAME,
			position = self.entity.position,
			force = self.entity.force,
		},
	}
	
	for _, chest in pairs(self.chests) do chest.destructible = false; end
	
	self.inventories = {
		passive = self.chests.passive.get_inventory(defines.inventory.chest),
		active = self.chests.active.get_inventory(defines.inventory.chest),
		normal = self.chests.normal.get_inventory(defines.inventory.chest),
		assembler = {},
	}
	self:find_assembler()
end


function _M:move_items(target)
	for _, inventory in pairs{self.inventories.assembler.input, self.inventories.assembler.output} do
		for i = 1, #inventory do
			local stack = inventory[i]
			if stack.valid_for_read then target.insert(stack); end
		end
	end
	
	-- compensate for half-finished recipes that had already consumed their ingredients
	if self.assembler.crafting_progress > 0 then
		for _, ing in pairs(self.assembler.get_recipe().ingredients) do
			if ing.type == "item" then
				target.insert{name = ing.name, count = ing.amount}
			end
		end
	end
end

function _M:empty_inserters(target)
	if self.settings.cc_empty_inserters then
		for _, inserter in pairs(self.assembler.surface.find_entities_filtered{
			area = FML.surface.area_around(self.assembler.position, config.CC_INSERTER_SEARCH_DISTANCE),
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

function _M:check_requested_modules(recipe)
	for name, count in pairs(self.item_request_proxy.item_requests) do
		local limitations = game.item_prototypes[name].limitations
		if not limitations[recipe.name] and not FML.table.is_empty(limitations) then
			self.item_request_proxy.item_requests[name] = 0
			if self.settings.cc_request_modules then
				self.modules_to_request[name] = self.modules_to_request[name] or 0
				self.modules_to_request[name] = self.modules_to_request[name] + count
			end
		end
	end
end

function _M:request_modules(recipe)
	local to_request = {}
	if self.item_request_proxy then to_request = self.item_request_proxy.item_requests; end
	
	for name, count in pairs(self.modules_to_request) do
		local limitations = game.item_prototypes[name].limitations
		if FML.table.contains(limitations, recipe.name) or FML.table.is_empty(limitations) then
			to_request[name] = to_request[name] or 0
			to_request[name] = to_request[name] + count
			--table.insert(to_request, {item = name, count = count})
			self.modules_to_request[name] = nil
		end
	end
	
	if not self.item_request_proxy and not FML.table.is_empty(to_request) then
		self.item_request_proxy = self.entity.surface.create_entity{
			name = "item-request-proxy",
			target = self.assembler,
			modules = to_request,
			position = self.assembler.position,
			force = self.assembler.force,
		}
	end
end

function _M:move_modules(recipe)
	local target = self:get_target(self.settings.cc_module_dest)
	local inventory = self.inventories.assembler.modules
	
	for i = 1, #inventory do
		local stack = inventory[i]
		if stack.valid_for_read then
			local limitations = game.item_prototypes[stack.name].limitations -- table indexed by recipe names (?)
			if limitations and not FML.table.is_empty(limitations)
					and not FML.table.contains(limitations, recipe.name) then
				target.insert(stack)
				-- save modules that have been removed to request them back when possible
				if self.settings.cc_request_modules then
					if self.modules_to_request[stack.name] then
						self.modules_to_request[stack.name] = self.modules_to_request[stack.name] + stack.count
					else self.modules_to_request[stack.name] = stack.count; end
				end
			end
		end
	end
end

function _M:delayed_run()
	local target = self.get_target(self.settings.cc_item_dest)
	self:empty_inserters(target)
end

function _M:update()
	if self.item_request_proxy and not self.item_request_proxy.valid then self.item_request_proxy = nil; end
	
	local params = {}
	if self.assembler and self.assembler.valid then
		-- set mode
		if self.settings.cc_mode_set then
			local recipe = recipe_selector.get_recipe(self.control_behavior, self.items_to_ignore)
			
			if self.assembler.get_recipe() and ((not recipe) or recipe ~= self.assembler.get_recipe()) then
				-- figure out the correct place to put the items
				local target = self:get_target(self.settings.cc_item_dest)
				
				-- move items from the assembler to the overflow chests
				self:move_items(target)
				
				self:empty_inserters(target)
				
				-- prevent occasional jamming of inserters with stacksize by emptying them multiple times.
				local tick = game.tick + config.CC_INSERTER_EMPTY_INTERVAL
				global.delayed_run[tick] = global.delayed_run[tick] or {}
				table.insert(global.delayed_run[tick], self)
			end
			
			if recipe and recipe ~= self.assembler.get_recipe() then
				-- move the modules that will get discarded by this recipe change into the overflow
				self:move_modules(recipe)
				
				-- check that the modules in the item-request-proxy are still usable
				if self.item_request_proxy then self:check_requested_modules(recipe); end
				
				-- request modules that have been removed and can be used with the new recipe
				if self.settings.cc_request_modules then self:request_modules(recipe); end
			end
			
			-- set the new recipe
			self.assembler.set_recipe(recipe) 
		end
		
		-- read mode
		if self.settings.cc_mode_read and self.assembler.get_recipe() then
			for type, type_tab in pairs{
				item = game.item_prototypes,
				fluid = game.fluid_prototypes,
				virtual = game.virtual_signal_prototypes,
			} do
				local prototype = type_tab[self.assembler.get_recipe().name]
				if prototype then
					table.insert(params, {
							signal = {type = type, name = prototype.name},
							count = 1,
							index = 1,
						})
					self.items_to_ignore = {[prototype.name] = 1}
					break
				end
			end
		else
			self.items_to_ignore = nil
		end
		
		-- read crafting speed
		if self.settings.cc_read_speed then
			table.insert(params, {
				signal = {type = "virtual", name = config.SPEED_NAME},
				count = game.entity_prototypes[self.assembler.name].crafting_speed * 100,
				index = 2,
			})
		end
		
		-- read Bottleneck
		if self.settings.cc_read_bottleneck then
			local state = (remote.call("Bottleneck", "get_signal_data", self.assembler.unit_number) or {}).status
			local name
			if state == global.BOTTLENECK_STATES.STOPPED then name = "signal-red"
			elseif state == global.BOTTLENECK_STATES.FULL then name = "signal-yellow"
			elseif state == global.BOTTLENECK_STATES.RUNNING then name = "signal-green"
			end
			if name then
				table.insert(params, {
					signal = {type = "virtual", name = name},
					count = 1,
					index = 3,
				})
			end
		end
	end
	
	self.control_behavior.parameters = {enabled = true, parameters = params}
end

function _M:destroy(player)
	FML.blueprint_data.destroy_proxy(self.entity)
	
	-- if the player mined this, move items from overflow to her inventory, otherwise spill them on the ground --TODO: find a better way to handle the second case
	for _, inventory in pairs{self.inventories.passive, self.inventories.active, self.inventories.normal} do
		for i = 1, #inventory do
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
	
	if self.gui then self.gui.destroy(); end
	
	for _, chest in pairs(self.chests) do chest.destroy() end
	
	self.super.destroy(self)
end

function _M:open(player_index)
	self.super.open(self)
	
	local parent = gui.make_entity_frame(self, player_index, {"crafting_combinator_gui_title_crafting-combinator"})
	
	local modes = {}
	if self.settings.cc_mode_set then table.insert(modes, "cc_mode_set"); end
	if self.settings.cc_mode_read then table.insert(modes, "cc_mode_read"); end
	
	local misc = {}
	if self.settings.cc_empty_inserters then table.insert(misc, "cc_empty_inserters"); end
	if self.settings.cc_request_modules then table.insert(misc, "cc_request_modules"); end
	if self.settings.cc_read_speed then table.insert(misc, "cc_read_speed"); end
	if self.settings.cc_read_bottleneck then table.insert(misc, "cc_read_bottleneck"); end
	
	local options = settings.cc_item_dest.options
	
	gui.make_checkbox_group(parent, "mode", {"crafting_combinator_gui_title_mode"}, {
			cc_mode_set = {"crafting_combinator_gui_crafting-combinator_mode_set"},
			cc_mode_read = {"crafting_combinator_gui_crafting-combinator_mode_read"},
		}, modes)
	gui.make_radiobutton_group(parent, "cc_item_dest", {"crafting_combinator_gui_crafting-combinator_title_item-destination"}, {
			[options.active] = {"crafting_combinator_gui_destination_active"},
			[options.passive] = {"crafting_combinator_gui_destination_passive"},
			[options.normal] = {"crafting_combinator_gui_destination_normal"},
			[options.none] = {"crafting_combinator_gui_destination_none"},
		}, self.settings.cc_item_dest)
	gui.make_radiobutton_group(parent, "cc_module_dest", {"crafting_combinator_gui_crafting-combinator_title_module-destination"}, {
			[options.active] = {"crafting_combinator_gui_destination_active"},
			[options.passive] = {"crafting_combinator_gui_destination_passive"},
			[options.normal] = {"crafting_combinator_gui_destination_normal"},
			[options.none] = {"crafting_combinator_gui_destination_none"},
		}, self.settings.cc_module_dest)
	gui.make_checkbox_group(parent, "misc", {"crafting_combinator_gui_crafting-combinator_title_misc"}, {
			cc_empty_inserters = {"crafting_combinator_gui_crafting-combinator_empty-inserters"},
			cc_request_modules = {"crafting_combinator_gui_crafting-combinator_request-modules"},
			cc_read_speed = {"crafting_combinator_gui_crafting-combinator_read-speed"},
			cc_read_bottleneck = game.active_mods["Bottleneck"] and {"crafting_combinator_gui_crafting-combinator_read-bottleneck"},
		}, misc)
end

function _M:on_checkbox_changed(group, name, state)
	self.settings[name] = state
	FML.blueprint_data.write(self.entity, settings[name], state)
end

function _M:on_radiobutton_changed(group, selected)
	selected = tonumber(selected)
	self.settings[group] = selected
	FML.blueprint_data.write(self.entity, settings[group], selected)
end

function _M:on_button_clicked(player_index, name)
	if name == "save" then gui.destroy_entity_frame(player_index); end
end

function _M:find_assembler()
	self.assembler = self.entity.surface.find_entities_filtered{
		area = FML.surface.area_around(FML.surface.move_position(self.entity.position, self.entity.direction, config.CC_ASSEMBLER_DISTANCE), config.CC_ASSEMBLER_OFFSET),
		type = "assembling-machine",
	}[1]
	
	if self.assembler then
		self.inventories.assembler = {
			output = self.assembler.get_inventory(defines.inventory.assembling_machine_output),
			input = self.assembler.get_inventory(defines.inventory.assembling_machine_input),
			modules = self.assembler.get_inventory(defines.inventory.assembling_machine_modules),
		}
	else
		self.inventories.assembler = {}
	end
end

local empty_target = {insert = function() end} -- when no chest is selected as overflow output

function _M:get_target(mode)
	local options = settings.cc_item_dest.options
	if mode == options.active then return self.chests.active
	elseif mode == options.passive then return self.chests.passive
	elseif mode == options.normal then return self.chests.normal
	else return empty_target
	end
end


return _M
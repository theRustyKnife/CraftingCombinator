local util = require 'script.util'
local settings_parser = require 'script.settings-parser'
local recipe_selector = require 'script.recipe-selector'
local config = require 'config'


local _M = {}
local combinator_mt = {__index = _M}


_M.settings_parser = settings_parser {
	mode = {'m',
		set = {'s', 'bool'},
		read = {'r', 'bool'},
	},
	discard_items = {'d', 'bool'},
	empty_inserters = {'i', 'bool'},
	read_speed = {'s', 'bool'},
	read_bottleneck = {'b', 'bool'},
}


-- General housekeeping

function _M.init_global()
	global.cc = global.cc or {}
	global.cc.data = global.cc.data or {}
	global.cc.ordered = global.cc.ordered or {}
	global.cc.inserter_empty_queue = {}
end

local BOTTLENECK_STATES
function _M.on_load()
	BOTTLENECK_STATES = global.BOTTLENECK_STATES and {
		[global.BOTTLENECK_STATES.STOPPED] = 'signal-red',
		[global.BOTTLENECK_STATES.FULL] = 'signal-yellow',
		[global.BOTTLENECK_STATES.RUNNING] = 'signal-green',
	}
	for _, combinator in pairs(global.cc.data) do setmetatable(combinator, combinator_mt); end
end


-- Lifecycle events

function _M.create(entity)
	local combinator = setmetatable({
		entity = entity,
		control_behavior = entity.get_or_create_control_behavior(),
		module_chest = entity.surface.create_entity {
			name = config.MODULE_CHEST_NAME,
			position = entity.position,
			force = entity.force,
			create_build_effect_smoke = false,
		},
		settings = _M.settings_parser:read(entity, util.deepcopy(config.CC_DEFAULT_SETTINGS)),
		inventories = {},
		items_to_ignore = {},
		last_flying_text_tick = -config.FLYING_TEXT_INTERVAL,
		enabled = true,
	}, combinator_mt)
	
	combinator.module_chest.destructible = false
	combinator.inventories.module_chest = combinator.module_chest.get_inventory(defines.inventory.chest)
	
	global.cc.data[entity.unit_number] = combinator
	table.insert(global.cc.ordered, combinator)
	combinator:find_assembler()
end

function _M.mark_for_deconstruction(entity)
	local combinator = global.cc.data[entity.surface.find_entity(config.CC_NAME, entity.position).unit_number]
	combinator.enabled = false
	combinator:update()
end
function _M.cancel_deconstruction(entity)
	local combinator = global.cc.data[entity.surface.find_entity(config.CC_NAME, entity.position).unit_number]
	combinator.enabled = true
	combinator:update()
end

function _M.destroy_by_robot(entity)
	log("Destroy by robot: "..serpent.line(entity.position))
	local combinator_entity = entity.surface.find_entity(config.CC_NAME, entity.position)
	if not combinator_entity then return; end
	_M.destroy(combinator_entity)
	combinator_entity.destroy()
end

function _M.destroy(entity, player_index)
	local unit_number = entity.unit_number
	local combinator = global.cc.data[unit_number]
	
	if player_index then
		local inventory = combinator.inventories.module_chest
		if not inventory.is_empty() then
			local target = player_index and game.get_player(player_index).get_inventory(defines.inventory.player_main)
			for i = 1, #inventory do
				local stack = inventory[i]
				if stack.valid_for_read then
					local r = target and target.insert(stack) or 0
					if r < stack.count then
						stack.count = stack.count - r
						-- Clone the entity as replacement and tell the player the inventory is full
						game.get_player(player_index).print{'inventory-restriction.player-inventory-full', game.item_prototypes[stack.name].localised_name}
						
						-- Replace the entity if a player was trying to pick it up
						local old_entity = combinator.entity
						local old_cb = combinator.control_behavior
						combinator.entity = old_entity.clone{position = old_entity.position}
						combinator.control_behavior = combinator.entity.get_or_create_control_behavior()
						
						global.cc.data[unit_number] = nil
						global.cc.data[combinator.entity.unit_number] = combinator
						
						for _, connection in pairs(old_entity.circuit_connection_definitions) do
							combinator.entity.connect_neighbour(connection)
						end
						
						old_entity.destroy()
						return true -- Inidcate that the original entity was destroyed
					else stack.clear(); end
				end
			end
		end
	end
	
	if player_index then combinator.module_chest.destroy(); end
	settings_parser.destroy(entity)
	
	global.cc.data[unit_number] = nil
	for k, v in pairs(global.cc.ordered) do
		if v.entity.unit_number == unit_number then
			table.remove(global.cc.ordered, k)
			break
		end
	end
end

function _M.update_assemblers(surface, assembler)
	local combinators = surface.find_entities_filtered {
		area = util.area(game.entity_prototypes[assembler.name].selection_box):expand(config.ASSEMBLER_SEARCH_DISTANCE) + assembler.position,
		name = config.CC_NAME,
	}
	for _, entity in pairs(combinators) do global.cc.data[entity.unit_number]:find_assembler(); end
end

function _M.update_chests(surface, chest)
	local combinators = surface.find_entities_filtered {
		area = util.area(game.entity_prototypes[chest.name].selection_box):expand(config.CHEST_SEARCH_DISTANCE) + chest.position,
		name = config.CC_NAME,
	}
	for _, entity in pairs(combinators) do global.cc.data[entity.unit_number]:find_chest(); end
end

function _M:update()
	local params = {}
	if self.enabled and self.assembler and self.assembler.valid then
		self.assembler.active = true
		
		if self.settings.mode.set then
			self:set_recipe()
			self.items_to_ignore = {} -- I hate this, but couldn't find a way to make it less terribad
		end
		if self.settings.mode.read then self:read_recipe(params); end
		if self.settings.read_speed then self:read_speed(params); end
		if global.BOTTLENECK_STATES and self.settings.read_bottleneck then self:read_bottleneck(params); end
	end
	
	self.control_behavior.parameters = {enabled = true, parameters = params}
end


function _M:open(player_index)
	--TODO: Make this look decent
	local player = game.get_player(player_index)
	local gui = player.gui.center
	local name = 'crafting_combinator:cc:'..tostring(self.entity.unit_number)
	
	local frame = gui.add {
		type = 'frame',
		name = name,
		caption = {'entity-name.'..config.CC_NAME},
		direction = 'vertical',
	}
	
	local mode_container = frame.add {
		type = 'flow',
		name = name..':mode',
		direction = 'vertical',
	}
	mode_container.add {
		type = 'label',
		name = name..':mode:caption',
		caption = {'crafting_combinator_gui.mode'},
		style = 'caption_label',
	}
	
	mode_container.add {
		type = 'checkbox',
		name = name..':mode:set',
		caption = {'crafting_combinator_gui.mode-set'},
		state = self.settings.mode.set,
	}
	mode_container.add {
		type = 'checkbox',
		name = name..':mode:read',
		caption = {'crafting_combinator_gui.mode-read'},
		state = self.settings.mode.read,
	}
	
	local misc_container = frame.add {
		type = 'flow',
		name = name..':misc',
		direction = 'vertical',
	}
	misc_container.add {
		type = 'label',
		name = name..':misc:caption',
		caption = {'crafting_combinator_gui.misc'},
		style = 'caption_label',
	}
	
	misc_container.add {
		type = 'checkbox',
		name = name..':misc:discard-items',
		caption = {'crafting_combinator_gui.discard-items'},
		state = self.settings.discard_items,
	}
	misc_container.add {
		type = 'checkbox',
		name = name..':misc:empty-inserters',
		caption = {'crafting_combinator_gui.empty-inserters'},
		state = self.settings.empty_inserters,
	}
	misc_container.add {
		type = 'checkbox',
		name = name..':misc:read-speed',
		caption = {'crafting_combinator_gui.read-speed'},
		state = self.settings.read_speed,
	}
	if game.active_mods['Bottleneck'] then
		misc_container.add {
			type = 'checkbox',
			name = name..':misc:read-bottleneck',
			caption = {'crafting_combinator_gui.read-bottleneck'},
			state = self.settings.read_bottleneck,
		}
	end
	
	frame.add {
		type = 'button',
		name = name..':open-module-chest',
		caption = {'crafting_combinator_gui.open-module-chest'},
		mouse_button_filter = {'left'},
	}
	
	player.opened = frame
	return frame
end

function _M:on_checked_changed(name, state)
	local category, name = name:gsub(':.*$', ''), name:gsub('^.-:', ''):gsub('-', '_')
	if category == 'mode' then self.settings.mode[name] = state; end
	if category == 'misc' then self.settings[name] = state; end
	self.settings_parser:update(self.entity, self.settings)
end

function _M:on_click(name, element)
	if name == 'open-module-chest' then
		game.get_player(element.player_index).opened = self.module_chest
	end
end


-- Other stuff

function _M:read_recipe(params)
	local recipe = self.assembler.get_recipe()
	if recipe then
		table.insert(params, {
			signal = recipe_selector.get_signal(recipe.name),
			count = 1,
			index = 1,
		})
		self.items_to_ignore[recipe.name] = 1
	end
end

function _M:read_speed(params)
	local count = game.entity_prototypes[self.assembler.name].crafting_speed * 100
	table.insert(params, {
		signal = {type = 'virtual', name = config.SPEED_SIGNAL_NAME},
		count = count,
		index = 2,
	})
	self.items_to_ignore[config.SPEED_SIGNAL_NAME] = count
end

function _M:read_bottleneck(params)
	local state = (remote.call('Bottleneck', 'get_signal_data', self.assembler.unit_number) or {}).status
	table.insert(params, {
		signal = {type = 'virtual', name = BOTTLENECK_STATES[state]},
		count = 1,
		index = 3,
	})
	self.items_to_ignore[BOTTLENECK_STATES[state]] = 1
end

function _M:set_recipe()
	local recipe = recipe_selector.get_recipe(self.entity, self.items_to_ignore)
	local a_recipe = self.assembler.get_recipe()
	
	-- Move items if necessary
	if a_recipe and ((not recipe) or recipe ~= a_recipe) then
		if not self:move_items() then return self:on_chest_full(); end
		if self.settings.empty_inserters then
			if not self:empty_inserters() then return self:on_chest_full(); end
			
			local tick = game.tick + config.INSERTER_EMPTY_DELAY
			global.cc.inserter_empty_queue[tick] = global.cc.inserter_empty_queue[tick] or {}
			table.insert(global.cc.inserter_empty_queue[tick], self)
		end
	end
	
	-- Move modules if necessary
	if recipe and recipe ~= a_recipe then
		self:move_modules(recipe)
	end
	
	self.assembler.set_recipe(recipe)
	
	-- Move modules and items back into the machine
	self:insert_modules()
	self:insert_items()
	
	return true
end

function _M:move_modules(recipe)
	local target = self.inventories.module_chest
	local inventory = self.inventories.assembler.modules
	for i = 1, #inventory do
		local stack = inventory[i]
		if stack.valid_for_read then
			local limitations = util.module_limitations()[stack.name]
			--TODO: Deal with not enough space in the chest
			if limitations and not limitations[recipe.name] then target.insert(stack); end
		end
	end
end

function _M:insert_modules()
	local inventory = self.inventories.module_chest
	if inventory.is_empty() then return; end
	local target = self.inventories.assembler.modules
	
	for i = 1, #inventory do
		local stack = inventory[i]
		if stack.valid_for_read then
			local r = target.insert(stack)
			if r < stack.count then stack.count = stack.count - r
			else stack.clear(); end
		end
	end
end

function _M:insert_items()
	local inventory = self.inventories.chest
	if not inventory or inventory.is_empty() then return; end
	local target = self.inventories.assembler.input
	
	for i = 1, #inventory do
		local stack = inventory[i]
		if stack.valid_for_read then
			local r = target.insert(stack)
			if r < stack.count then stack.count = stack.count - r
			else stack.clear(); end
		end
	end
end

function _M:move_items()
	if self.settings.discard_items then return true; end
	local target = self.inventories.chest
	
	-- Compensate for half-finished crafts
	-- Do this first to avoid losing a lot of items
	if self.assembler.crafting_progress > 0 then
		if not target then return false; end
		local success = true
		for _, ing in pairs(self.assembler.get_recipe().ingredients) do
			if ing.type == 'item' then
				local r = target.insert{name = ing.name, count = ing.amount}
				if r < ing.amount then success = false; end
			end
		end
		self.assembler.crafting_progress = 0
		if not success then return false; end
	end
	
	-- Clear the assembler inventories
	-- This may become somewhat problematic if the input items can be moved, but the output can't, since inserters will
	-- continue to replace the items that were removed. I guess that's up to the player to deal with tho...
	for _, inventory in pairs{self.inventories.assembler.input, self.inventories.assembler.output} do
		for i=1, #inventory do
			local stack = inventory[i]
			if stack.valid_for_read then
				if not target then return false; end
				local r = target.insert(stack)
				if r < stack.count then
					stack.count = stack.count - r -- Make sure the items don't get duplicated
					return false
				end
				inventory[i].clear()
			end
		end
	end
	
	return true
end

function _M:on_chest_full()
	-- Prevent the assembler from crafting any more shit
	self.assembler.active = false
	if game.tick - self.last_flying_text_tick >= config.FLYING_TEXT_INTERVAL then
		self.last_flying_text_tick = game.tick
		self.entity.surface.create_entity {
			name = 'flying-text',
			position = self.entity.position,
			text = {'crafting_combinator_gui.chest-full'},
			color = {255, 0, 0},
		}
	end
end

function _M:empty_inserters()
	local target = self.inventories.chest
	
	for _, inserter in pairs(self.assembler.surface.find_entities_filtered {
				area = util.area(game.entity_prototypes[self.assembler.name].selection_box):expand(config.INSERTER_SEARCH_RADIUS) + self.assembler.position,
				type = 'inserter',
			}) do
		if inserter.drop_target == self.assembler then
			local stack = inserter.held_stack
			if stack.valid_for_read and not self.settings.discard_items then
				if not target then return false; end
				local r = target.insert(stack)
				if r < stack.count then
					stack.count = stack.count - r
					return false
				end
				stack.clear()
			else stack.clear(); end
		end
	end
	return true
end

function _M:find_assembler()
	self.assembler = self.entity.surface.find_entities_filtered {
		position = util.position(self.entity.position):shift(self.entity.direction, config.ASSEMBLER_DISTANCE),
		type = 'assembling-machine',
	}[1]
	
	if self.assembler then
		self.inventories.assembler = {
			output = self.assembler.get_inventory(defines.inventory.assembling_machine_output),
			input = self.assembler.get_inventory(defines.inventory.assembling_machine_input),
			modules = self.assembler.get_inventory(defines.inventory.assembling_machine_modules),
		}
	else self.inventories.assembler = {}; end
end

function _M:find_chest()
	self.chest = self.entity.surface.find_entities_filtered {
		position = util.position(self.entity.position):shift(self.entity.direction, config.CHEST_DISTANCE),
		type = {'container', 'logistic-container'},
	}[1]
	self.inventories.chest = self.chest and self.chest.get_inventory(defines.inventory.chest)
end


return _M

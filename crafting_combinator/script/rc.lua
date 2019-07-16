local config = require 'config'
local util = require 'script.util'
local gui = require 'script.gui'
local settings_parser = require 'script.settings-parser'
local recipe_selector = require 'script.recipe-selector'


local _M = {}
local combinator_mt = {__index = _M}


_M.settings_parser = settings_parser {
	mode = {'m', 'string'},
	multiply_by_input = {'i', 'bool'},
	divide_by_output = {'o', 'bool'},
	differ_output = {'d', 'bool'},
	time_multiplier = {'t', 'number'},
}


-- General housekeeping

function _M.init_global()
	global.rc = global.rc or {}
	global.rc.data = global.rc.data or {}
	global.rc.ordered = global.rc.ordered or {}
end

function _M.build_machine_cache()
	_M.item_map = {}
	_M.category_map = {}
	for name, prototype in pairs(game.entity_prototypes) do
		if prototype.crafting_categories and prototype.items_to_place_this then
			for category in pairs(prototype.crafting_categories) do
				_M.category_map[category] = _M.category_map[category] or {}
				for _, item in pairs(prototype.items_to_place_this) do
					_M.item_map[item.name] = {}
					table.insert(_M.category_map[category], item.name)
				end
			end
		end
	end
	for _, recipe in pairs(game.recipe_prototypes) do
		for _, product in pairs(recipe.products) do
			if _M.item_map[product.name] ~= nil then
				table.insert(_M.item_map[product.name], recipe.name)
			end
		end
	end
end

function _M.on_load()
	for _, combinator in pairs(global.rc.data) do setmetatable(combinator, combinator_mt); end
end


-- Lifecycle events

function _M.create(entity)
	local combinator = setmetatable({
		entity = entity,
		output_proxy = entity.surface.create_entity {
			name = config.RC_PROXY_NAME,
			position = entity.position,
			force = entity.force,
			create_build_effect_smoke = false,
		},
		input_control_behavior = entity.get_or_create_control_behavior(),
		settings = _M.settings_parser:read(entity, util.deepcopy(config.RC_DEFAULT_SETTINGS)),
	}, combinator_mt)
	
	entity.connect_neighbour {
		wire = defines.wire_type.red,
		target_entity = combinator.output_proxy,
		source_circuit_id = defines.circuit_connector_id.combinator_output,
	}
	entity.connect_neighbour {
		wire = defines.wire_type.green,
		target_entity = combinator.output_proxy,
		source_circuit_id = defines.circuit_connector_id.combinator_output,
	}
	combinator.output_proxy.destructible = false
	combinator.control_behavior = combinator.output_proxy.get_or_create_control_behavior()
	
	global.rc.data[entity.unit_number] = combinator
	table.insert(global.rc.ordered, combinator)
end

function _M.destroy(entity)
	local unit_number = entity.unit_number
	local combinator = global.rc.data[unit_number]
	
	combinator.output_proxy.destroy()
	settings_parser.destroy(entity)
	
	global.rc.data[unit_number] = nil
	for k, v in pairs(global.rc.ordered) do
		if v.entity.unit_number == unit_number then
			table.remove(global.rc.ordered, k)
			break
		end
	end
end

function _M:update(forced)
	if self.settings.mode == 'rec' then self:find_recipe()
	elseif self.settings.mode == 'mac' then self:find_machines(forced)
	else self:find_ingredients_and_products(forced); end
end

function _M:find_recipe()
	local params = {}
	local index = 1
	local recipes, count = recipe_selector.get_recipes(
			self.entity.get_merged_signals(defines.circuit_connector_id.combinator_input),
			self.entity.force.recipes)
	count = self.settings.multiply_by_input and count or 1
	for _, recipe in pairs(recipes) do
		local recipe_count = self.settings.divide_by_output and math.ceil(count/recipe.count) or count
		table.insert(params, {
			signal = recipe_selector.get_signal(recipe.name),
			count = self.settings.differ_output and index or recipe_count,
			index = index,
		})
		if params[#params].signal.type == 'invalid' then params[#params] = nil; index = index - 1; end
		index = index + 1
	end
	
	self.control_behavior.parameters = {enabled = true, parameters = params}
end

function _M:find_ingredients_and_products(forced)
	local recipe, input_count = recipe_selector.get_recipe(self.entity, nil, defines.circuit_connector_id.combinator_input)
	
	if self.recipe ~= recipe or forced or (self.settings.multiply_by_input and self.input_count ~= input_count) then
		self.recipe = recipe
		self.input_count = input_count
		
		local params = {}
		
		if recipe then
			local crafting_multiplier = self.settings.multiply_by_input and input_count or 1
			for i, ing in pairs(
						self.settings.mode == 'prod' and recipe.products or
						self.settings.mode == 'ing' and recipe.ingredients or {}
					) do
				local amount = math.ceil(
					tonumber(ing.amount or ing.amount_min or ing.amount_max) * crafting_multiplier
					* (tonumber(ing.probability) or 1)
				)
				amount = (amount + 2147483648) % 4294967296 - 2147483648 -- Simulate 32bit integer overflow
				
				table.insert(params, {
					signal = {type = ing.type, name = ing.name},
					count = self.settings.differ_output and i or amount,
					index = i,
				})
			end
			
			table.insert(params, {
				signal = {type = 'virtual', name = config.TIME_SIGNAL_NAME},
				count = math.floor(tonumber(recipe.energy) * self.settings.time_multiplier * crafting_multiplier),
				index = config.RC_SLOT_COUNT,
			})
		end
		
		self.control_behavior.parameters = {enabled = true, parameters = params}
	end
end


function _M:find_machines(forced)
	local recipe, input_count = recipe_selector.get_recipe(self.entity, nil, defines.circuit_connector_id.combinator_input)

	if self.recipe ~= recipe or forced or (self.settings.multiply_by_input and self.input_count ~= input_count) then
		self.recipe = recipe
		self.input_count = input_count
		if _M.item_map == nil then _M.build_machine_cache(); end

		local params = {}
		local index = 1
		if recipe and recipe.category then
			for _, item in pairs(_M.category_map[recipe.category] or {}) do
				for _, recipe in pairs(_M.item_map[item]) do
					local mac_res = self.entity.force.recipes[recipe]
					if mac_res and not mac_res.hidden and mac_res.enabled then
						table.insert(params, {
							signal = recipe_selector.get_signal(item),
							count = self.settings.multiply_by_input and input_count or
								self.settings.differ_output and index or 1,
							index = index,
						})
						if params[#params].signal.type == 'invalid' then params[#params] = nil; index = index - 1; end
						index = index + 1
						break
					end
				end
			end
		end
		self.control_behavior.parameters = {enabled = true, parameters = params}
	end
end


function _M:open(player_index)
	local root = gui.entity(self.entity, {
		gui.section {
			name = 'mode',
			gui.radio('ing', self.settings.mode, {locale='mode-ing', tooltip=true}),
			gui.radio('prod', self.settings.mode, {locale='mode-prod', tooltip=true}),
			gui.radio('rec', self.settings.mode, {locale='mode-rec', tooltip=true}),
			gui.radio('mac', self.settings.mode, {locale='mode-mac', tooltip=true}),
		},
		gui.section {
			name = 'misc',
			gui.checkbox('multiply-by-input', self.settings.multiply_by_input, {tooltip=true}),
			gui.checkbox('divide-by-output', self.settings.divide_by_output, {tooltip=true}),
			gui.checkbox('differ-output', self.settings.differ_output, {tooltip=true}),
			gui.number_picker('time-multiplier', self.settings.time_multiplier),
		}
	}):open(player_index)
	
	self:udpate_disabled_checkboxes(root)
end

function _M:on_checked_changed(name, state, element)
	local category, name = name:gsub(':.*$', ''), name:gsub('^.-:', ''):gsub('-', '_')
	if category == 'mode' then
		self.settings.mode = name
		for _, el in pairs(element.parent.children) do
			if el.type == 'radiobutton' then
				local _, _, el_name = gui.parse_entity_gui_name(el.name)
				el.state = el_name == 'mode:'..name
			end
		end
	end
	if category == 'misc' then self.settings[name] = state; end
	
	self:udpate_disabled_checkboxes(gui.get_root(element))
	
	self.settings_parser:update(self.entity, self.settings)
	self:update(true)
end

function _M:udpate_disabled_checkboxes(root)
	self:disable_checkbox(root, 'misc:divide-by-output', 'divide_by_output',
			self.settings.mode == 'rec' and not self.settings.differ_output)
	self:disable_checkbox(root, 'misc:multiply-by-input', 'multiply_by_input',
			not self.settings.divide_by_output and not self.settings.differ_output,
			self.settings.divide_by_output or self.settings.multiply_by_input)
	self:disable_checkbox(root, 'misc:differ-output', 'differ_output',
			not self.settings.multiply_by_input)
end

function _M:disable_checkbox(root, name, setting_name, enable, set_state)
	set_state = set_state or false
	local checkbox = gui.find_element(root, gui.name(self.entity, name))
	if checkbox.enabled ~= enable then
		checkbox.enabled = enable
		checkbox.state = set_state
		self.settings[setting_name] = set_state
	end
end

function _M:on_text_changed(name, text)
	if name == 'misc:time-multiplier:value' then
		self.settings.time_multiplier = tonumber(text) or self.settings.time_multiplier
		self.settings_parser:update(self.entity, self.settings)
		self:update(true)
	end
end


function _M:update_inner_positions()
	settings_parser.move_entity(self.entity, self.output_proxy.position)
	self.output_proxy.teleport(self.entity.position)
end


return _M

local config = require 'config'
local util = require 'script.util'
local settings_parser = require 'script.settings-parser'
local recipe_selector = require 'script.recipe-selector'


local _M = {}
local combinator_mt = {__index = _M}


_M.settings_parser = settings_parser {
	mode = {'m', 'string'},
	multiply_by_input = {'i', 'bool'},
	time_multiplier = {'t', 'number'},
}


-- General housekeeping

function _M.init_global()
	global.rc = global.rc or {}
	global.rc.data = global.rc.data or {}
	global.rc.ordered = global.rc.ordered or {}
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
	if self.settings.mode ~= 'rec' then self:find_ingredients_and_products(forced); end
	if self.settings.mode == 'rec' then self:find_recipe(); end
end

function _M:find_recipe()
	local params = {}
	local index = 1
	local recipes, count = recipe_selector.get_recipes(
			self.entity.get_merged_signals(defines.circuit_connector_id.combinator_input),
			self.entity.force.recipes)
	count = self.settings.multiply_by_input and count or 1
	for _, recipe in pairs(recipes) do
		table.insert(params, {
			signal = recipe_selector.get_signal(recipe),
			count = count,
			index = index,
		})
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
			for i, ing in pairs(
						self.settings.mode == 'prod' and recipe.products or
						self.settings.mode == 'ing' and recipe.ingredients or {}
					) do
				local t_amount = tonumber(ing.amount or ing.amount_min or ing.amount_max)
				if self.settings.multiply_by_input then t_amount = t_amount * input_count; end
				local amount = math.floor(t_amount)
				if t_amount % 1 > 0 then amount = amount + 1; end
				
				table.insert(params, {
					signal = {type = ing.type, name = ing.name},
					count = amount,
					index = i,
				})
			end
			
			table.insert(params, {
				signal = {type = 'virtual', name = config.TIME_SIGNAL_NAME},
				count = math.floor(tonumber(recipe.energy) * self.settings.time_multiplier),
				index = config.RC_SLOT_COUNT,
			})
		end
		
		self.control_behavior.parameters = {enabled = true, parameters = params}
	end
end


function _M:open(player_index)
	--TODO: Make this look decent
	local player = game.get_player(player_index)
	local gui = player.gui.center
	local name = 'crafting_combinator:rc:'..tostring(self.entity.unit_number)
	
	local frame = gui.add {
		type = 'frame',
		name = name,
		caption = {'entity-name.'..config.RC_NAME},
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
		type = 'radiobutton',
		name = name..':mode:ing',
		caption = {'crafting_combinator_gui.mode-ing'},
		state = self.settings.mode == 'ing',
	}
	mode_container.add {
		type = 'radiobutton',
		name = name..':mode:prod',
		caption = {'crafting_combinator_gui.mode-prod'},
		state = self.settings.mode == 'prod',
	}
	mode_container.add {
		type = 'radiobutton',
		name = name..':mode:rec',
		caption = {'crafting_combinator_gui.mode-rec'},
		state = self.settings.mode == 'rec',
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
		name = name..':misc:multiply-by-input',
		caption = {'crafting_combinator_gui.multiply-by-input'},
		state = self.settings.multiply_by_input,
	}
	
	local time_multiplier_container = misc_container.add {
		type = 'flow',
		name = name..':misc:time-multiplier',
		direction = 'horizontal',
	}
	time_multiplier_container.add {
		type = 'label',
		name = name..':misc:time-multiplier:caption',
		caption = {'crafting_combinator_gui.time-multiplier'},
	}
	time_multiplier_container.add {
		type = 'textfield',
		name = name..':misc:time-multiplier:value',
		text = tostring(self.settings.time_multiplier),
	}
	
	player.opened = frame
	return frame
end

function _M:on_checked_changed(name, state, element)
	local category, name = name:gsub(':.*$', ''), name:gsub('^.-:', ''):gsub('-', '_')
	if category == 'mode' then
		self.settings.mode = name
		for _, el in pairs(element.parent.children) do
			if el.type == 'radiobutton' then
				local _, _, el_name = util.parse_gui_name(el.name)
				el.state = el_name == 'mode:'..name
			end
		end
	end
	if category == 'misc' then self.settings[name] = state; end
	
	self.settings_parser:update(self.entity, self.settings)
	self:update(true)
end

function _M:on_text_changed(name, text)
	if name == 'misc:time-multiplier:value' then
		self.settings.time_multiplier = tonumber(text) or self.settings.time_multiplier
		self.settings_parser:update(self.entity, self.settings)
		self:update(true)
	end
end


return _M

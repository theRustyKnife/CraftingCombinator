local FML = therustyknife.FML
local blueprint_data = FML.blueprint_data
local table = FML.table
local log = FML.log
local GUI = FML.GUI

local config = require "config"
local Combinator = require ".Combinator"
local recipe_selector = require "script.recipe-selector"


local _M = Combinator:extend("therustyknife.crafting_combinator.RecipeCombinator", function(self, entity)
	self = self.super.new(self, entity)
	
	FML.log.dump("Built a RecipeCombinator at ", self.entity.position)
	
	self.settings = blueprint_data.get(self.entity, config.NAME.RC_SETTINGS)
	
	self.output_proxy = self.entity.surface.create_entity{
		name = config.NAME.RC_OUT_PROXY,
		position = self.entity.position,
		force = self.entity.force,
	}
	self.out_control_behavior = self.output_proxy.get_or_create_control_behavior()
	self.output_proxy.destructible = false
	self.output_proxy.operable = false
	self.output_proxy.connect_neighbour{
		target_entity = self.entity,
		wire = defines.wire_type.green,
		target_circuit_id = defines.circuit_connector_id.combinator_output,
	}
	self.output_proxy.connect_neighbour{
		target_entity = self.entity,
		wire = defines.wire_type.red,
		target_circuit_id = defines.circuit_connector_id.combinator_output,
	}
	
	return self
end)

function _M:destroy()
	FML.log.dump("Destroying a RecipeCombinator at ", self.entity.position)
	
	self.settings:_reset()
	self.output_proxy.destroy()
	
	if self.gui and self.gui.valid then
		self.gui.destroy()
		GUI.controls.prune()
	end
	
	_M.super.destroy(self)
end


FML.events.on_built(function(event)
	local entity = event.created_entity
	if entity.name == config.NAME.RC then _M(entity); end
end)

FML.events.on_destroyed(function(event)
	local entity = event.entity
	if entity.name == config.NAME.RC then
		Combinator.get(entity):destroy()
	end
end)


local MODE
GUI.watch_opening(config.NAME.RC, function(event)
	if event.status then return nil; end
	
	local self = Combinator.get(event.entity)
	
	local parent = GUI.entity_base{
		parent = event.player.gui.center,
		entity = event.entity,
		cam_zoom = 1,
	}
	self.gui = parent.root
	
	-- Mode
	MODE = MODE or blueprint_data.get_enum(config.NAME.RC_SETTINGS, "mode")
	
	GUI.controls.RadiobuttonGroup{
		parent = parent.title,
		name = "mode",
		options = {
			{name = MODE.ingredient, caption = {"crafting_combinator-gui.rc-mode-ingredient"}},
			{name = MODE.product, caption = {"crafting_combinator-gui.rc-mode-product"}},
			{name = MODE.recipe, caption = {"crafting_combinator-gui.rc-mode-recipe"}},
		},
		selected = self.settings.mode,
		on_change = "therustyknife.crafting_combinator.rc_mode_change",
		meta = self,
		link_name = "therustyknife.crafting_combinator.RecipeCombinator.main.mode."..string.format("%d", self.entity.unit_number),
	}
	
	local misc = GUI.entity_segment{parent = parent.primary, title = {"crafting_combinator-gui.rc-misc"}}
	
	-- Time multiplier
	GUI.controls.NumberSelector{
		parent = misc,
		name = "time_multiplier",
		caption = {"crafting_combinator-gui.rc-time-multiplier"},
		value = self.settings.time_multiplier,
		on_change = "therustyknife.crafting_combinator.rc_number_changed",
		meta = self,
		min = 1,
		max = 2147483647,
		link_name = "therustyknife.crafting_combinator.RecipeCombinator.main.time_multiplier."..string.format("%d", self.entity.unit_number),
		format_func = function(value) return string.format("%.0f", value); end,
	}
	
	--Multiply by input
	GUI.controls.CheckboxGroup{
		parent = misc,
		options = {
			{name = "multiply_by_input", state = self.settings.multiply_by_input, caption = {"crafting_combinator-gui.rc-multiply-by-input"}},
		},
		on_change = "therustyknife.crafting_combinator.rc_check_change",
		meta = self,
		link_name = "therustyknife.crafting_combinator.RecipeCombinator.main.multiply_by_input."..string.format("%d", self.entity.unit_number),
	}
	
	return parent.root
end)

FML.handlers.add("therustyknife.crafting_combinator.rc_mode_change", function(group)
	group.meta.settings[group.name] = tonumber(group.value)
	group.meta:update(true)
end)

FML.handlers.add("therustyknife.crafting_combinator.rc_check_change", function(group)
	local settings = group.meta.settings
	for name, state in pairs(group.values) do settings[name] = state; end
	group.meta:update(true)
end)

FML.handlers.add("therustyknife.crafting_combinator.rc_number_changed", function(picker)
	picker.meta.settings[picker.name] = picker.value
	picker.meta:update(true)
end)


function _M:update(forced)
	local recipe, input_count = recipe_selector.get_recipe(self.control_behavior)
	
	MODE = MODE or blueprint_data.get_enum(config.NAME.RC_SETTINGS, "mode")
	if self.settings.mode ~= MODE.recipe
			and (self.recipe ~= recipe or forced or (self.settings.multiply_by_input and self.input_count ~= input_count)) then
		self.recipe = recipe
		self.input_count = input_count
		local params = table()
		
		if recipe then
			for i, ing in pairs(
						((self.settings.mode == MODE.product) and recipe.products)
						or ((self.settings.mode == MODE.ingredient) and recipe.ingredients)
						or {}
					) do
				local t_amount = tonumber(ing.amount or ing.amount_min or ing.amount_max)
				if self.settings.multiply_by_input then t_amount = t_amount * input_count; end
				local amount = math.floor(t_amount)
				if t_amount % 1 > 0 then amount = amount + 1; end
				
				params:insert{
					signal = {type = ing.type, name = ing.name},
					count = FML.random_util.calculate_overflow(amount),
					index = i,
				}
			end
			
			params:insert{
				signal = {type = "virtual", name = config.NAME.TIME},
				count = FML.random_util.calculate_overflow(
					math.floor(tonumber(recipe.energy) * self.settings.time_multiplier)),
				index = config.RC_SLOT_COUNT,
			}
		end
		
		self.out_control_behavior.parameters = {enabled = true, parameters = params}
	end
	
	if self.settings.mode == MODE.recipe then
		local params = table()
		
		local index = 1
		local recipes, count = recipe_selector.get_recipes(self.control_behavior)
		for _, recipe in pairs(recipes) do
			local count = (self.settings.multiply_by_input and count) or 1
			params:insert{
				signal = recipe_selector.get_signal(recipe),
				count = FML.random_util.calculate_overflow(count),
				index = index,
			}
			index = index + 1
		end
		
		self.out_control_behavior.parameters = {enabled = true, parameters = params}
	end
end


return _M

local FML = require "therustyknife.FML"
local entities = require "therustyknife.crafting_combinator.entities"
local config = require "config"
local recipe_selector = require "script.recipe_selector"
local gui = require "script.gui"

local settings = FML.blueprint_data.settings


FML.global.on_init(function()
	global.combinators.recipe = global.combinators.recipe or {}
end)


local _M = entities.Combinator:extend()


_M.TYPE = "recipe"

FML.global.on_load(function()
	_M.tab = global.combinators.recipe
	
	for _, o in pairs(global.combinators.recipe or {}) do _M:load(o); end
end)


function _M:on_create(blueprint)
	self.settings = {
		rc_mode = settings.rc_mode.options.ingredient,
		rc_time_multiplier = 10,
		rc_multiply_by_input = false,
	}
	
	if blueprint then
		self.settings.rc_mode = FML.blueprint_data.read(self.entity, settings.rc_mode) or self.settings.rc_mode
		self.settings.rc_time_multiplier = FML.blueprint_data.read(self.entity, settings.rc_time_multiplier) or self.settings.rc_time_multiplier
		
		local rc_multiply_by_input = FML.blueprint_data.read(self.entity, settings.rc_multiply_by_input)
		if rc_multiply_by_input ~= nil then self.settings.rc_multiply_by_input = rc_multiply_by_input; end
	end
end

function _M:update(forced)
	local recipe, input_count = recipe_selector.get_recipe(self.control_behavior, self.items_to_ignore)
	
	if self.settings.rc_mode ~= settings.rc_mode.options.recipe and (self.recipe ~= recipe or (forced and self.settings.rc_mode ~= settings.rc_mode.options.recipe) or (self.settings.rc_multiply_by_input and self.input_count ~= input_count)) then
		self.recipe = recipe
		self.input_count = input_count
		self.items_to_ignore = {}
		
		local params = {}
		
		if recipe then
			for i, ing in pairs(
						((self.settings.rc_mode == settings.rc_mode.options.product) and recipe.products)
						or ((self.settings.rc_mode == settings.rc_mode.options.ingredient) and recipe.ingredients)
						or {}
					) do
				local t_amount = tonumber(ing.amount or ing.amount_min or ing.amount_max)
				if self.settings.rc_multiply_by_input then t_amount = t_amount * input_count; end
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
					count = math.floor(tonumber(recipe.energy) * self.settings.rc_time_multiplier),
					index = config.RC_SLOT_COUNT,
				})
		end
		
		self.control_behavior.parameters = {enabled = true, parameters = params}
	end
	
	if self.settings.rc_mode == settings.rc_mode.options.recipe then
		local params = {}
		
		local t_to_ignore = self.items_to_ignore
		self.items_to_ignore = {}
		
		local index = 1
		local recipes, count = recipe_selector.get_recipes(self.control_behavior, t_to_ignore)
		for _, recipe in pairs(recipes) do
			local count = (self.settings.rc_multiply_by_input and count) or 1
			table.insert(params, {
				signal = recipe_selector.get_signal(recipe),
				count = count,
				index = index,
			})
			
			self.items_to_ignore[recipe] = count
			index = index + 1
		end
		
		self.control_behavior.parameters = {enabled = true, parameters = params}
	end
end

function _M:destroy()
	if self.gui then self.gui.destroy(); end
	
	FML.blueprint_data.destroy_proxy(self.entity)
	
	self.super.destroy(self)
end

function _M:open(player_index)
	self.super.open(self)
	
	local parent = gui.make_entity_frame(self, player_index, {"crafting_combinator_gui_title_recipe-combinator"})
	gui.make_radiobutton_group(parent, "rc_mode", {"crafting_combinator_gui_title_mode"}, {
			[settings.rc_mode.options.ingredient] = {"crafting_combinator_gui_recipe-combinator_mode_ingredient"},
			[settings.rc_mode.options.product] = {"crafting_combinator_gui_recipe-combinator_mode_product"},
			[settings.rc_mode.options.recipe] = {"crafting_combinator_gui_recipe-combinator_mode_recipe"},
		}, self.settings.rc_mode)
	gui.make_number_selector(parent, "rc_time_multiplier", {"crafting_combinator_gui_recipe-combinator_time-multiplier"}, self.settings.rc_time_multiplier)
	gui.make_checkbox_group(parent, "misc", nil, {
		rc_multiply_by_input = {"crafting_combinator_gui_recipe-combinator_multiply-by-input"},
	}, self.settings.rc_multiply_by_input and {"rc_multiply_by_input"} or {})
end

function _M:on_radiobutton_changed(group, selected)
	self.settings[group] = tonumber(selected)
	FML.blueprint_data.write(self.entity, settings[group], self.settings[group])
	self:update(true)
end

function _M:on_button_clicked(player_index, name)
	if name == "save" then gui.destroy_entity_frame(player_index); end
end

function _M:on_number_selected(name, value)
	if value then
		self.settings[name] = value
		FML.blueprint_data.write(self.entity, settings[name], self.settings[name])
		self:update(true)
	else return self.settings[name]; end
end

function _M:on_checkbox_changed(group, name, state)
	self.settings[name] = state
	FML.blueprint_data.write(self.entity, settings[name], state)
end


return _M

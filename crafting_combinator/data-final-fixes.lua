local config = require 'config'


local item_types = {"fluid"} -- so that fluids have names and icons too (without stack_size)
for type, prototypes in pairs(data.raw) do
	-- Anything that's an item has to have the stack_size property, so that's how we find item types
	local key, value = next(prototypes)
	if key ~= nil and value.stack_size ~= nil then table.insert(item_types, type); end
end


local function _is_result(item, result, results)
	if item == result then return true; end
	for _, result in pairs(results or {}) do
		if result.name == item then return true; end
	end
	return false
end
local function is_result(recipe, item)
	if _is_result(item, recipe.result, recipe.results) then return true; end
	if recipe.normal and _is_result(item, recipe.normal.result, recipe.normal.results) then return true; end
	if recipe.expensive and _is_result(item, recipe.expensive.result, recipe.expensive.results) then return true; end
	return false
end

local function is_ignored(name)
	for _, ignore_name in pairs(config.RECIPES_TO_IGNORE) do
		if name:find(ignore_name) then return true; end
	end
	return false
end

local function is_hidden(recipe) -- Just end me please.
	if recipe.normal then return recipe.normal.hidden
	else return recipe.hidden; end
end

local function needs_signal(recipe)
	if type(recipe) == 'string' then recipe = data.raw['recipe'][recipe]; end
	local name = recipe.name
	return not (
			is_hidden(recipe)
			or is_ignored(name)
			or is_result(recipe, name)
			or data.raw['virtual-signal'][name]
		)
end

local function get_result_name(result) return result.name or result[1]; end

local function try_get_icons(item)
	if not item then return nil; end
	if item.icon then return {{icon = item.icon}}; end
	if item.icons then return item.icons; end
	return nil
end

local function get_possible_results(recipe)
	local res = {}
	local function _get_results(tab)
		if tab.result then table.insert(res, tab.result); end
		if tab.results then
			for _, result in pairs(tab.results) do table.insert(res, get_result_name(result)); end
		end
	end
	
	_get_results(recipe)
	if recipe.expensive then _get_results(recipe.expensive); end
	if recipe.normal then _get_results(recipe.normal); end
	
	return res
end

local function get_possible_ingredients(recipe)
	local res = {}
	local function _get_ingredients(tab)
		if tab.ingredients then
			for _, ingredient in pairs(tab.ingredients) do table.insert(res, get_result_name(ingredient)); end
		end
	end
	
	_get_ingredients(recipe)
	if recipe.expensive then _get_ingredients(recipe.expensive); end
	if recipe.normal then _get_ingredients(recipe.normal); end
	
	return res
end

local function get_max_ingredient_count(recipe)
	local max = 0
	local function check(tab)
		local size = type(tab.ingredients) == 'table' and table_size(tab.ingredients) or 0
		if size > max then max = size; end
	end
	
	check(recipe)
	if recipe.expensive then check(recipe.expensive); end
	if recipe.normal then check(recipe.normal); end
	
	return max
end

local function get_icons(recipe)
	if recipe.icon then return {{icon = recipe.icon}}; end
	if recipe.icons then return recipe.icons; end
	
	for _, type in pairs(item_types) do
		local first_icons
		for _, result in pairs(get_possible_results(recipe)) do
			local icons = try_get_icons(data.raw[type][result])
			if result == recipe.name and icons then return icons; end
			first_icons = first_icons or icons
		end
		if first_icons then return first_icons; end
	end
	
	log("Icon not found for: "..recipe.name)
	return {{icon = '__core__/graphics/clear.png', icon_size = 128}}
end

local function get_locale(recipe)
	local item
	local results = get_possible_results(recipe)
	for _, type in pairs(item_types) do
		item = data.raw[type][recipe.name] or data.raw[type][results[1]]
		if item then break; end
	end
	
	local key = {'recipe-name.'..recipe.name}
	if recipe.localised_name then key = recipe.localised_name
	elseif item and item.localised_name then key = item.localised_name
	elseif item and item.type == 'fluid' then key = {'fluid-name.'..item.name}
	elseif item and item.place_result then key = {'entity-name.'..item.place_result}
	elseif item and item.placed_as_equipment_result then key = {'equipment-name.'..item.placed_as_equipment_result}
	elseif item then key = {'item-name.'..item.name}
	end
	return {'crafting_combinator.recipe-locale', key}
end

local function get_order(recipe)
	local subgroup_order = (data.raw['item-subgroup'][recipe.subgroup] or {}).order or 'zzz'
	local recipe_order = recipe.order or 'zzz'
	return subgroup_order..'-'..recipe_order..'['..recipe.name..']'
end


local recipes_waiting_for_groups = {}

local function make_signal_for_recipe(name, recipe)
	if needs_signal(recipe) then
		if data.raw['item-subgroup'][recipe.subgroup] == nil then
			print("Recipe `"..tostring(name).."` needs subgroup `"..tostring(recipe.subgroup).."` which doesn't exist yet - waiting for it to be created...")
			recipes_waiting_for_groups[recipe.subgroup] = recipes_waiting_for_groups[recipe.subgroup] or {}
			table.insert(recipes_waiting_for_groups[recipe.subgroup], recipe)
			return
		end
		
		print("Generating virtual signal for recipe `"..tostring(name).."`")
		local subgroup = config.UNSORTED_RECIPE_SUBGROUP
		if recipe.subgroup then
			local group = data.raw['item-group'][data.raw['item-subgroup'][recipe.subgroup].group]
			subgroup = config.RECIPE_SUBGROUP_PREFIX..group.name
			if not data.raw['item-subgroup'][subgroup] then
				data:extend{{
					type = 'item-subgroup',
					name = subgroup,
					group = config.GROUP_NAME,
					order = group.order..'['..group.name..']',
				}}
			end
		end
		
		data:extend{{
			type = 'virtual-signal',
			name = name,
			localised_name = get_locale(recipe),
			icons = get_icons(recipe),
			subgroup = subgroup,
			icon_size = 32, --TODO: This can't possibly work correctly...
			order = get_order(recipe),
		}}
	end
end


local rc = data.raw['constant-combinator'][config.RC_PROXY_NAME]
local result_counts = {recipes = {}, uses = {}}

local function process_recipe(name, recipe)
	make_signal_for_recipe(name, recipe)
	
	-- Expand the rc slots, just in case there is some insane recipe with a hundred ingredients or something...
	local required_slots = get_max_ingredient_count(recipe) + config.RC_SLOT_RESERVE
	if required_slots > rc.item_slot_count then
		print(("Expanding rc slots to %d"):format(required_slots))
		rc.item_slot_count = required_slots
	end
	--TODO: Do the same for products?
	
	for _, result in pairs(get_possible_results(recipe)) do
		local count = (result_counts.recipes[result] or 0) + 1
		result_counts.recipes[result] = count
		if count + config.RC_SLOT_RESERVE > rc.item_slot_count then
			print("Expanding rc slots to fit recipes for "..tostring(result).." ("..tostring(count)..")")
			rc.item_slot_count = count + config.RC_SLOT_RESERVE
		end
	end
	
	for _, ingredient in pairs(get_possible_ingredients(recipe)) do
		local count = (result_counts.uses[ingredient] or 0) + 1
		result_counts.uses[ingredient] = count
		if count + config.RC_SLOT_RESERVE > rc.item_slot_count then
			print("Expanding rc slots to fit uses of "..tostring(ingredient).." ("..tostring(count)..")")
			rc.item_slot_count = count + config.RC_SLOT_RESERVE
		end
	end
end


-- Generate signals for all existing recipes that need it
for name, recipe in pairs(data.raw['recipe']) do process_recipe(name, recipe); end


local function hook_newindex(table, hook)
	local raw_mt = getmetatable(table) or {}
	setmetatable(table, raw_mt)
	local super_newindex = raw_mt.__newindex or rawset
	function raw_mt.__newindex(self, key, value)
		hook(self, key, value, function() return super_newindex(self, key, value); end)
	end
end


-- Listen for other mods adding recipes beyond this point and make signals for them if necessary
hook_newindex(data.raw['recipe'], function(self, key, value, super)
	if value ~= nil then process_recipe(key, value); end --TODO: Remove signals for recipes that get removed
	super()
end)

--Listen for other mods adding subgroups, so we can finish processing recipes that need them
hook_newindex(data.raw['item-subgroup'], function(self, key, value, super)
	super()
	
	local recipes = recipes_waiting_for_groups[key]
	if recipes ~= nil then
		recipes_waiting_for_groups[key] = nil
		for _, recipe in pairs(recipes) do make_signal_for_recipe(recipe.name, recipe); end
	end
end)

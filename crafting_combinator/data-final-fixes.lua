local FML = require "FML.init"
local config = require "config"


local function is_result_internal(item, result, results)
	if item == result then return true; end
	for _, result in pairs(results or {}) do
		if result.name == item then return true; end
	end
	return false
end
local function is_result(recipe, item)
	if is_result_internal(item, recipe.result, recipe.results) then return true; end
	if recipe.normal then
		if is_result_internal(item, recipe.normal.result, recipe.normal.results) then return true; end
	end
	if recipe.expensive then
		return is_result_internal(item, recipe.expensive,result, recipe.expensive.results)
	end
	return false
end

local function is_ignored(name)
	for _, ignore_name in pairs(config.RECIPES_TO_IGNORE) do
		if name:find(ignore_name) then return true; end
	end
	return false
end

local function needs_signal(recipe)
	local name
	if type(recipe) == "string" then
		name = recipe
		recipe = data.raw["recipe"][name]
	else name = recipe.name; end
	
	return not (
			recipe.hidden
			or is_ignored(recipe.name)
			or is_result(recipe, name)
			or data.raw["virtual-signal"][name]
		)
end

local function get_result_name(result)
	if result.name then return result.name
	else return result[1]; end
end


local function try_get_icons(item)
	if not item then return nil; end
	
	if item.icon then return {{icon = item.icon}}; end
	if item.icons then return item.icons; end
	
	return nil
end

local function get_icons(recipe)
	if recipe.icon then return {{icon = recipe.icon}}; end
	if recipe.icons then return recipe.icons; end
	
	for _, type in pairs(config.ITEM_TYPES) do
		local icons = try_get_icons(data.raw[type][recipe.result])
		if icons then return icons; end
		
		if recipe.results then
			local first_icons
			for _, result in pairs(recipe.results) do
				local result = data.raw[type][get_result_name(result)]
				
				local icons = try_get_icons(result)
				first_icons = first_icons or icons
				
				if result and result.name == recipe.name then
					if icons then return icons; end
					if first_icons then return first_icons; end
					break
				end
			end
			if first_icons then return first_icons; end
		end
	end
	-- no icon found - use the default one
    log("Icon not found for: "..recipe.name)
    return {{icon = "__crafting_combinator__/graphics/no-icon.png"}}
end

local function get_locale(recipe)
    --Try the best option to get a valid localised name

    local item, result_item
    for _, type in pairs(config.ITEM_TYPES) do
        item = data.raw[type][recipe.name]
        result_item = data.raw[type][recipe.result] or (recipe.results and data.raw[type][recipe.results[1].name])
        if item or result_item then break end
    end

    local loc_key = {"recipe-name."..recipe.name}
    if recipe.localised_name then
        loc_key = recipe.localised_name
    elseif item and item.localised_name then
        loc_key = item.localised_name
    elseif result_item and result_item.type == "fluid" then
        loc_key = {"fluid-name."..result_item.name}
    elseif result_item then
        loc_key = {"item-name."..result_item.name}
    elseif item and item.place_result then
        loc_key = {"entity-name."..item.place_result}
    elseif item and recipe.placed_as_equipment_result then
        loc_key = {"equipment-name."..item.placed_as_equipment_result}
    end
    return {"crafting-combinator.locale", loc_key}
end


-- create the virtual recipes
for name, recipe in pairs(data.raw.recipe) do
	if needs_signal(recipe) then
		local subgroup = data.raw["item-subgroup"][config.RECIPE_SUBGROUP_NAME]
		if config.USE_RECIPE_SUBGROUPS and recipe.subgroup then
			local group = data.raw["item-group"][data.raw["item-subgroup"][recipe.subgroup].group]
			
			subgroup = data.raw["item-subgroup"]["crafting-combinator-virtual-recipe-subgroup-"..group.name] or FML.data.make_prototype{
				type = "item-subgroup",
				name = "crafting-combinator-virtual-recipe-subgroup-"..group.name,
				group = config.GROUP_NAME,
				order = group.order.."["..group.name.."]",
			}
		end
		
		local localised_name = get_locale(recipe)
		
		FML.data.make_prototype{
			type = "virtual-signal",
			name = name,
			localised_name = localised_name,
			icons = get_icons(recipe),
			subgroup = subgroup.name,
			order = ((data.raw["item-subgroup"][recipe.subgroup] or {}).order or "zzz").."-"..(recipe.order or "zzz").."["..recipe.name.."]",
		}
	end
end

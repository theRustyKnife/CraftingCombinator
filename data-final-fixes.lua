--luacheck: globals crafting_combinator_data
crafting_combinator_data = crafting_combinator_data or {}
crafting_combinator_data.overrides = crafting_combinator_data.overrides or {}
crafting_combinator_data.icons = crafting_combinator_data.icons or {}

local function is_result(recipe, item) -- LuaRecipe recipe, string item
    -- is the item one of the results?
    if recipe.result and recipe.result == item then return true -- result is item... simple
    elseif recipe.results then -- result is not item but there's the results table - we have to chack that
        for _, v in pairs(recipe.results) do
            if v.name == item then return true end -- item is in results, yay
        end
    end
    return false -- everything failed, recipe is named differently
end

local function needs_signal(recipe) -- string recipe
    -- does it?
    local name = recipe
    recipe = data.raw.recipe[name]

    local res = not is_result(recipe, name) -- no need for a signal if there is an item with the same name
    res = res and not data.raw["virtual-signal"][name] -- no need for a signal if there already is a signal with that name
    res = res and not crafting_combinator_data.overrides[name] -- I TRUST U DO DA RITE TING

    return res
end

local function get_icon(recipe) -- LuaRecipe recipe
    --Attempts to find the best suitable icon for this recipe - uses a default one if none is found
    --Loop through recipes, Then result, then results, then finnally results type items, finally return no-icon if none found
    --returns an Icons table to support recipes with icons tables
    if crafting_combinator_data.icons[recipe.name] then
        return crafting_combinator_data.icons[recipe.name]
    end
    if recipe.icon then
        return {{icon = recipe.icon}}
    end
    if recipe.icons then
        return recipe.icons
    end
    for _, type in pairs({"item", "module", "tool", "fluid"}) do
        if recipe.result and data.raw[type][recipe.result] and data.raw[type][recipe.result].icon then
            return {{icon = data.raw[type][recipe.result].icon}}
        end
        if recipe.result and data.raw[type][recipe.result] and data.raw[type][recipe.result].icons then
            return data.raw[type][recipe.result].icons
        end
        if recipe.results then --loop twice, first look for matching name, then look for first available.
            for _, result in pairs(recipe.results) do
                if result.name == recipe.name and data.raw[type][result.name] and data.raw[type][result.name].icon then
                    return {{icon = data.raw[type][result.name].icon}}
                elseif result.name == recipe.name and data.raw[type][result.name] and data.raw[type][result.name].icons then
                    return data.raw[type][result.name].icons
                end
            end
            for _, result in pairs(recipe.results) do
                if data.raw[result.type][result.name] and data.raw[result.type][result.name].icon then
                    --log(serpent.line(data.raw[result.type][result.name].icon))
                    return {{icon = data.raw[result.type][result.name].icon}}
                elseif data.raw[result.type][result.name] and data.raw[result.type][result.name].icons then
                    --log(serpent.line(data.raw[result.type][result.name].icons))
                    return data.raw[type][result.name].icons
                end
            end
        end
    end
    -- no icon found - use the default one
    log("Icon not found for: "..recipe.name)
    return {{icon = "__crafting_combinator__/graphics/no-icon.png"}}
end

local function get_locale(recipe)
    --Try the best option to get a valid localised name

    local item, result_item
    for _, type in pairs({"item", "module", "tool", "fluid"}) do
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

local ignore_name_list = {
    -- "angels%-fluid%-splitter-",
    -- "converter%-angels%-",
    "compress%-",
    "uncompress%-",
}

local function ignore_recipes(name)
    for _, ignore_name in ipairs(ignore_name_list) do
        if name:find("^"..ignore_name) then return true end
    end
end

-- create virtual recipes
for name, recipe in pairs(data.raw.recipe) do
    -- only make virtual recipes if the name is not the same as result (or one of the results)
    if needs_signal(name) and not (recipe.hidden or ignore_recipes(recipe.name)) then
        data:extend{
            {
                type = "virtual-signal",
                name = name,
                localised_name = get_locale(recipe),
                icons = get_icon(recipe),
                subgroup = "virtual-signal-recipe",
                order = "zzz[virtual-signal-recipe]" .. (recipe.order or ""),
            }
        }
    end
end

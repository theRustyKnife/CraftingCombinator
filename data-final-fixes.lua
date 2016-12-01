crafting_combinator_data = crafting_combinator_data or {}
crafting_combinator_data.overrides = crafting_combinator_data.overrides or {}
crafting_combinator_data.icons = crafting_combinator_data.icons or {}


local function is_result(recipe, item) -- LuaRecipe recipe, string item
-- is the item one of the results?
	if recipe.result and recipe.result == item then return true -- result is item... simple
	elseif recipe.results then                                  -- result is not item but there's the results table - we have to chack that
		for _, v in pairs(recipe.results) do
			if v.name == item then return true end              -- item is in results, yay
		end
	end
	return false                                                -- everything failed, recipe is named differently
end

local function needs_signal(recipe) -- string recipe
-- does it?
	local name = recipe
	recipe = data.raw.recipe[name]
	
	local res = not is_result(recipe, name)                    -- no need for a signal if there is an item with the same name
	res = res and not data.raw["virtual-signal"][name]         -- no need for a signal if there already is a signal with that name
	res = res and not crafting_combinator_data.overrides[name] -- I TRUST U DO DA RITE TING
	
	return res
end

local function get_icon(recipe) -- LuaRecipe recipe
-- attempts to find the best suitable icon for this recipe - uses a default one if none is found
	if crafting_combinator_data.icons[recipe.name] then return crafting_combinator_data.icons[recipe.name]; end                                -- an icon is explicitly defined
	if recipe.icon then return recipe.icon; end                                                                                                -- the recipe has it's icon
	if recipe.result and data.raw.item[recipe.result] and data.raw.item[recipe.result].icon then return data.raw.item[recipe.result].icon; end -- the result has an icon
	if recipe.results then
		for _, v in pairs(recipe.results) do
			if v.name == recipe.name and data.raw.item[v.name] and data.raw.item[v.name].icon then return data.raw.item[v.name].icon; end      -- there's a matching item in the results table with an icon
		end
	end
	return "__crafting_combinator__/graphics/no-icon.png"                                                                                      -- no icon found - use the default one
end


-- create the subgroup for virtual recipes
data:extend{
	{
		type = "item-subgroup",
		name = "virtual-signal-recipe",
		group = "signals",
		order = "zzz"
	},
}

-- create virtual recipes
for name, recipe in pairs(data.raw.recipe) do
	-- only make virtual recipes if the name is not the same as result (or one of the results)
	if needs_signal(name) then
		data:extend{
			{
				type = "virtual-signal",
				name = name,
				icon = get_icon(recipe),
				subgroup = "virtual-signal-recipe",
				order = "zzz[virtual-signal-recipe]" .. (recipe.order or ""),
			}
		}
	end
end
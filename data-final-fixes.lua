config = require "config"

local function is_result(results, t)
	results = results or {}
	for _, v in pairs(results) do
		if v.name == t then return true end
	end
	return false
end

local function get_icon(recipe)
	if recipe.icon then return recipe.icon end
	if recipe.result and data.raw.item[recipe.result] and data.raw.item[recipe.result].icon then return data.raw.item[recipe.result].icon end
	if recipe.results then
		for _, v in pairs(recipe.results) do
			if v.name == recipe.name and data.raw.item[v.name] and data.raw.item[v.name].icon then return data.raw.item[v.name].icon end
		end
	end
	if config.virtual_icons[recipe.name] then return config.virtual_icons[recipe.name] end
	return "__crafting_combinator__/graphics/no-icon.png"
end

data:extend({
	{
		type = "item-subgroup",
		name = "virtual-signal-recipe",
		group = "signals",
		order = "zzz"
	},
})

for name, recipe in pairs(data.raw.recipe) do
	if not (recipe.result == name or is_result(recipe.results, name))
	  and not data.raw["virtual-signal"][name]
	  and not config.special_cases[name] then
		data:extend({
			{
				type = "virtual-signal",
				name = name,
				icon = get_icon(recipe),
				subgroup = "virtual-signal-recipe",
				order = "zzz[recipe]"
			}
		})
	end
end
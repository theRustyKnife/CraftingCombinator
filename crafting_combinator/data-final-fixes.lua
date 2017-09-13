local FML = therustyknife.FML

local config = require "config"


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
			or is_ignored(name)
			or FML.prototype_util.is_result(name, recipe)
			or data.raw["virtual-signal"][name]
		)
end

local function get_locale(recipe)
	return {"crafting-combinator.locale", FML.prototype_util.get_recipe_locale(recipe)}
end


for name, recipe in pairs(data.raw.recipe) do
	if needs_signal(recipe) then
		local subgroup = data.raw["item-subgroup"][config.NAME.SUBGROUP]
		if recipe.subgroup then
			local group = data.raw["item-group"][data.raw["item-subgroup"][recipe.subgroup].group]
			
			subgroup = data.raw["item-subgroup"]["crafting-combinator-virtual-recipe-subgroup-"..group.name] or FML.data.make{
				type = "item-subgroup",
				name = "crafting-combinator-virtual-recipe-subgroup-"..group.name,
				group = config.NAME.GROUP,
				order = group.order.."["..group.name.."]",
			}
		end
		
		local locale = get_locale(recipe)
		
		FML.data.make{
			type = "virtual-signal",
			name = name,
			localised_name = locale,
			icons = FML.prototype_util.get_recipe_icons(recipe),
			subgroup = subgroup.name,
			order = ((data.raw["item-subgroup"][recipe.subgroup] or {}).order or "zzz").."-"..(recipe.order or "zzz").."["..recipe.name.."]",
		}
	end
end

local _M = {}


function _M.get_recipe(entity, items_to_ignore, connector_id)
	items_to_ignore = items_to_ignore or {}
	local signals
	if connector_id ~= nil then signals = entity.get_merged_signals(connector_id)
	else signals = entity.get_merged_signals(); end
	if not signals then return nil; end
	
	local res = nil
	local count = nil
	local return_signal = nil
	for _, signal in pairs(signals) do
		local recipe = entity.force.recipes[signal.signal.name]
		if recipe and recipe.enabled then
			local c = signal.count - (items_to_ignore[recipe.name] or 0)
			if count == nil or c > count then res = recipe; count = c; return_signal = signal.signal; end
		end
	end
	
	return res, count, return_signal
end


function _M.get_highest_signal(signals)
	local res = nil
	local count = nil
	
	for _, signal in pairs(signals) do
		local c = signal.count
		if count == nil or c > count then res, count = signal.signal.name, c; end
	end
	
	return res, count or 0
end

function _M.get_recipes(signals, recipes)
	if not signals then return {}, 0; end
	local highest, count = _M.get_highest_signal(signals)
	if not highest then return {}, 0; end
	
	local res = {}
	local item
	if game.item_prototypes[highest] then item = {name = highest, type = 'item'}
	elseif game.fluid_prototypes[highest] then item = {name = highest, type = 'fluid'}
	else item = {}; end
	
	for name, recipe in pairs(recipes) do
		if not recipe.hidden and recipe.enabled then
			for _, product in pairs(recipe.products) do
				if product.name == item.name and (item.type == 'fluid' or item.type == product.type) then
					table.insert(res, name)
					break
				end
			end
		end
	end
	
	return res, count
end


function _M.get_signal(recipe)
	return {
		name = recipe,
		type = (game.item_prototypes[recipe] and 'item') or (game.fluid_prototypes[recipe] and 'fluid') or 'virtual'
	}
end


function _M.calculate_crafting_amount(recipe, signal, count)
	-- count when the signal is a recipe
	local amount = count
	for i, prod in pairs(recipe.products) do
		if prod.type == signal.type and prod.name == signal.name then
			-- when it is a product return how often you have to do the recipe
			amount = tonumber(prod.amount or prod.amount_min or prod.amount_max)
			amount = math.ceil(count / amount)
			break
		end
	end
	return amount
end


return _M

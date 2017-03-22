local _M = {}


function _M.on_gui_clicked(event)
	local clicked_combinator
	
	for _, v in pairs(global.entities) do
		for __, type in pairs(v) do
			for ___, combinator in pairs(type) do
				if combinator.gui == event.element.parent then clicked_combinator = combinator; end
			end
		end
	end
	
	if clicked_combinator then
		if event.element.name == "crafting_combinator_gui_recipe-combinator_save" then
			clicked_combinator.gui.destroy()
			clicked_combinator.gui = nil
		elseif event.element.name == "crafting_combinator_gui_recipe-combinator_mode-ingredient" then
			clicked_combinator.gui["crafting_combinator_gui_recipe-combinator_mode-product"].state = false
			clicked_combinator.product_mode = false
			clicked_combinator:update(true)
		elseif event.element.name == "crafting_combinator_gui_recipe-combinator_mode-product" then
			clicked_combinator.gui["crafting_combinator_gui_recipe-combinator_mode-ingredient"].state = false
			clicked_combinator.product_mode = true
			clicked_combinator:update(true)
			
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_mode-set" then
			clicked_combinator.settings.set_recipes = event.element.state
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_mode-read" then
			clicked_combinator.settings.read_recipes = event.element.state
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_items-dest-passive" then
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-active"].state = false
			clicked_combinator.settings.items_to_passive = true
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_items-dest-active" then
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-passive"].state = false
			clicked_combinator.settings.items_to_passive = false
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_save" then
			clicked_combinator.gui.destroy()
			clicked_combinator.gui = nil
		end
	end
end


function _M.recipe_combinator_settings(combinator, player)
	local frame_name = "crafting_combinator_gui_recipe-combinator_frame"
	
	if combinator.gui or player.gui.center[frame_name] then return; end
	
	local frame = player.gui.center.add{
		type = "frame",
		name = frame_name,
		caption = "Recipe Combinator",
		direction = "vertical",
	}
	frame.add{
		type = "label",
		name = "crafting_combinator_gui_recipe-combinator_mode-title",
		caption = "Mode",
	}
	frame.add{
		type = "radiobutton",
		name = "crafting_combinator_gui_recipe-combinator_mode-ingredient",
		caption = "Ingredient",
		state = not combinator.product_mode,
	}
	frame.add{
		type = "radiobutton",
		name = "crafting_combinator_gui_recipe-combinator_mode-product",
		caption = "Product",
		state = combinator.product_mode,
	}
	frame.add{
		type = "button",
		name = "crafting_combinator_gui_recipe-combinator_save",
		caption = "Save",
	}
	
	combinator.gui = frame
end

function _M.crafting_combinator_settings(combinator, player)
	local prefix = "crafting_combinator_gui_crafting-combinator_"
	local frame_name = prefix.."combinator_frame"
	
	if combinator.gui or player.gui.center[frame_name] then return; end
	
	local frame = player.gui.center.add{
		type = "frame",
		name = frame_name,
		caption = "Recipe Combinator",
		direction = "vertical",
	}
	frame.add{
		type = "label",
		name = prefix.."mode-title",
		caption = "Mode",
	}
	frame.add{
		type = "checkbox",
		name = prefix.."mode-set",
		caption = "Set recipes",
		state = combinator.settings.set_recipes,
	}
	frame.add{
		type = "checkbox",
		name = prefix.."mode-read",
		caption = "Read recipes",
		state = combinator.settings.read_recipes,
	}
	frame.add{
		type = "label",
		name = prefix.."items-dest-title",
		caption = "Move items to:",
	}
	frame.add{
		type = "radiobutton",
		name = prefix.."items-dest-passive",
		caption = "Passive provider",
		state = combinator.settings.items_to_passive,
	}
	frame.add{
		type = "radiobutton",
		name = prefix.."items-dest-active",
		caption = "Active provider",
		state = not combinator.settings.items_to_passive,
	}
	frame.add{
		type = "button",
		name = prefix.."save",
		caption = "Save",
	}
	
	combinator.gui = frame
end


return _M
local _M = {}


function _M.on_gui_clicked(event)
	local clicked_combinator
	
	for _, combinator in pairs(global.combinators.all) do
		if combinator.gui == event.element.parent then clicked_combinator = combinator; end
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
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-none"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-normal"].state = false
			clicked_combinator.settings.item_destination = "passive"
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_items-dest-active" then
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-passive"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-none"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-normal"].state = false
			clicked_combinator.settings.item_destination = "active"
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_items-dest-none" then
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-passive"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-active"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-normal"].state = false
			clicked_combinator.settings.item_destination = "none"
		elseif event.element.name == "crafting_combinator_gui_crafting-combinator_items-dest-normal" then
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-passive"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-active"].state = false
			clicked_combinator.gui["crafting_combinator_gui_crafting-combinator_items-dest-none"].state = false
			clicked_combinator.settings.item_destination = "normal"
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
		state = combinator.settings.item_destination == "passive",
	}
	frame.add{
		type = "radiobutton",
		name = prefix.."items-dest-active",
		caption = "Active provider",
		state = combinator.settings.item_destination == "active",
	}
	frame.add{
		type = "radiobutton",
		name = prefix.."items-dest-normal",
		caption = "Regular chest",
		state = combinator.settings.item_destination == "normal",
	}
	frame.add{
		type = "radiobutton",
		name = prefix.."items-dest-none",
		caption = "Nowhere",
		state = combinator.settings.item_destination == "none",
	}
	frame.add{
		type = "button",
		name = prefix.."save",
		caption = "Save",
	}
	
	combinator.gui = frame
end


return _M
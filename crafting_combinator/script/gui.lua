local FML = require "therustyknife.FML"


FML.global.on_init(function()
	global.gui = global.gui or {}
end)


local PREFIX = "crafting_combinator_"


local _M = {}


function _M.make_frame(parent, name, caption, direction)
	return parent.add{
		type = "frame",
		name = PREFIX..name,
		caption = caption,
		direction = direction or "vertical",
	}
end

function _M.make_container(parent, name, caption, direction)
	local container = parent.add{
		type = "flow",
		name = name,
		direction = direction or "vertical",
	}
	
	if caption then
		container.add{
			type = "label",
			name = "caption",
			caption = caption,
			style = "bold_label_style",
		}
	end
	
	return container
end

function _M.make_radiobutton_group(parent, name, caption, options, selected) -- options is in the format {name = caption, ...}, selected is a name from options
	local container = _M.make_container(parent, name, caption)
	
	local group = _M.make_container(container, name)
	
	for name, caption in pairs(options) do
		group.add{
			type = "radiobutton",
			name = name,
			caption = caption,
			state = name == selected,
		}
	end
	
	return container
end

function _M.make_checkbox_group(parent, name, caption, options, selected) -- same as radiobutton group just selected is an array of options
	local container = _M.make_container(parent, name, caption)
	
	local group = _M.make_container(container, name)
	
	for name, caption in pairs(options) do
		group.add{
			type = "checkbox",
			name = name,
			caption = caption,
			state = FML.table.contains(selected, name),
		}
	end
	
	return container
end

function _M.make_entity_frame(entity, player_index, caption)
	_M.destroy_entity_frame(player_index)
	
	local frame = _M.make_frame(game.players[player_index].gui.center, "entity-frame", caption)
	
	local container = _M.make_container(frame, "container")
	
	-- frame.add{
		-- type = "button",
		-- name = "change-refresh-rate",
		-- caption = {"crafting_combinator_gui_button_change-refresh-rate"},
	-- }
	
	frame.add{
		type = "button",
		name = "save",
		caption = {"crafting_combinator_gui_button_save"},
	}
	
	global.gui[player_index] = {gui = frame, entity = entity}
	
	return container
end

function _M.destroy_entity_frame(player_index)
	local todestroy = global.gui[player_index]
	if not todestroy then return; end
	
	todestroy.gui.destroy()
	local entity = todestroy.entity
	global.gui[player_index] = nil
	
	--entity:close()
end

function _M.is_open(entity)
	for _, v in pairs(global.gui) do
		if v.entity == entity then return true; end
	end
	return false
end


function _M.on_gui_clicked(event)
	local parent = event.element
	while true do
		if parent == nil then return; end
		if parent.name == PREFIX.."entity-frame" then break; end
		parent = parent.parent
	end
	
	local clicked_entity
	for _, v in pairs(global.gui) do
		if v.gui == parent then
			clicked_entity = v.entity
			break
		end
	end
	
	if event.element.type == "checkbox" then
		clicked_entity:on_checkbox_changed(event.element.parent.name, event.element.name, event.element.state)
	elseif event.element.type == "radiobutton" then
		for _, name in pairs(event.element.parent.children_names) do
			event.element.parent[name].state = name == event.element.name
		end
		clicked_entity:on_radiobutton_changed(event.element.parent.name, event.element.name)
	elseif event.element.type == "button" then
		clicked_entity:on_button_clicked(event.player_index, event.element.name)
	end
end


return _M

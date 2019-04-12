local _M = {}


local MOD_NAME = 'crafting_combinator'
local LOCALE_CATEGORY = MOD_NAME..'_gui'


local function build_list(specs, root)
	for _, spec in ipairs(specs) do
		if type(spec) == 'table' then spec:build(root); end
	end
	return root
end

local function elem_name(parent, name)
	if parent.name and parent.name:match('^'..MOD_NAME) then return parent.name..':'..name
	else return MOD_NAME..':'..name; end
end
local function locale(key) return {LOCALE_CATEGORY..'.'..key}; end


function _M.parse_entity_gui_name(name)
	local gui_name = name:gsub('^'..MOD_NAME..':', '')
	local unit_number = gui_name:gsub('^.-:', '')
	local element_name = unit_number:gsub('^.-:', '')
	return gui_name:gsub(':.*$', ''), tonumber((unit_number:gsub(':.*$', ''))), element_name
end


function _M.open(spec, player_index, root)
	local player = game.get_player(player_index)
	local root = root or player.gui.center
	local element = spec:build(root)
	player.opened = element
	return element
end


function _M.entity(entity, specs)
	specs.open = _M.open
	
	local entity_name = entity.name:match('[^:]*$')
	local unit_number = entity.unit_number
	local entity_locale = game.entity_prototypes[entity.name].localised_name
	
	function specs:build(root)
		local main = root.add {
			type = 'flow',
			name = elem_name(root, entity_name..':'..tostring(unit_number)),
			direction = 'vertical',
		}
		main.style.vertical_spacing = 0
		
		local title = main.add {
			type = 'frame',
			name = elem_name(main, 'title'),
			caption = entity_locale,
			direction = 'horizontal',
		}
		local preview = title.add {
			type = 'entity-preview',
			name = elem_name(title, 'preview'),
			style = 'entity_button_base',
		}
		preview.entity = entity
		
		if self.title_elements then build_list(self.title_elements, title); end
		
		build_list(self, main)
		
		return main
	end
	return specs
end

function _M.section(specs)
	function specs:build(root)
		local frame = root.add {
			type = 'frame',
			name = elem_name(root, specs.name),
			caption = specs.caption or locale(specs.name),
			direction = 'vertical',
		}
		
		build_list(self, frame)
		
		return frame
	end
	return specs
end

function _M.spacer()
	local specs = {}
	function specs:build(root)
		local res = root.add { type = 'flow' }
		res.style.horizontally_stretchable = true
		return res
	end
	return specs
end

function _M.checkbox(name, state, locale_key)
	local specs = {}
	function specs:build(root)
		return root.add {
			type = 'checkbox',
			name = elem_name(root, name),
			caption = locale(locale_key or name),
			state = state,
		}
	end
	return specs
end

function _M.radio(name, selected, locale_key)
	local specs = {}
	function specs:build(root)
		return root.add {
			type = 'radiobutton',
			name = elem_name(root, name),
			caption = locale(locale_key or name),
			state = selected == name,
		}
	end
	return specs
end

function _M.button(name)
	local specs = {}
	function specs:build(root)
		return root.add {
			type = 'button',
			name = elem_name(root, name),
			caption = locale(name),
			mouse_button_filter = {'left'},
		}
	end
	return specs
end

function _M.number_picker(name, value)
	local specs = {}
	function specs:build(root)
		local container = root.add {
			type = 'flow',
			name = elem_name(root, name),
			direction = 'horizontal',
		}
		container.add {
			type = 'label',
			name = elem_name(container, 'caption'),
			caption = locale(name),
		}
		local text_field = container.add {
			type = 'textfield',
			name = elem_name(container, 'value'),
			text = tostring(value or 0),
		}
		text_field.style.width = 100
		return container
	end
	return specs
end


return _M

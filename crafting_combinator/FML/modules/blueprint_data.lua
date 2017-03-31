local FML = require "therustyknife.FML"
local config = require "therustyknife.FML.config"


if not config.BLUEPRINT_DATA_PATH then return nil; end -- requires data to work


if type(config.BLUEPRINT_DATA_PATH) ~= "string" then return nil; end
local data = FML.safe_require(config.BLUEPRINT_DATA_PATH)
local PROTOTYPE_NAME = config.MOD_NAME.."_FML_"..config.BLUEPRINT_DATA_PROTOTYPE_NAME

local function get_name(name)
	return PROTOTYPE_NAME.."_"..name
end

local function get_name_rev(name)
	name, count = name:gsub(get_name(""), "")
	if count == 1 then return name; end
end


--[[
	definition format:
	{
		{
			type = "enum" or "number",
			name = "setting-name",
			options = {}, -- array of strings, only needed if type == "enum"
		},
		...
	}
]]


if not FML.global then
	local prototype = FML.data.make_prototype{
		base = FML.data.inherit("constant-combinator"),
		properties = {
			name = get_name("entity"),
			flags = {"placeable-off-grid", "placeable-neutral", "player-creation"},
			collision_mask = {},
			collision_box = config.BLUEPRINT_PROXY_SIZE,
			selection_box = {{0, 0}, {0, 0}},
			item_slot_count = FML.table.getn(data),
			icon = "__base__/graphics/icons/blueprint.png",
			hidden = true,
		},
		auto_generate = {"item"},
	}
	
	for _, img in pairs(prototype.sprites) do
		img.filename = "__"..config.MOD_NAME.."__"..config.FML_PATH.."/graphics/trans.png"
		img.x = 0
		img.y = 0
		img.width = 0
		img.height = 0
	end
	
	for _, v in pairs(data) do
		FML.data.make_prototype{
			type = "item",
			name = get_name(v.name),
			flags = {"hidden"},
			icon = "__"..config.MOD_NAME.."__"..config.FML_PATH.."/graphics/trans.png",
			stack_size = 1,
		}
	end
	
else
	local global
	
	local _M = {}
	
	
	_M.settings = {}
	
	for index, v in pairs(data) do
		_M.settings[v.name] = {
			type = v.type,
			index = index,
			name = v.name,
			signal_name = get_name(v.name),
			options = {},
		}
		
		if v.type == "enum" then
			for i, option in ipairs(v.options) do
				_M.settings[v.name].options[option] = i
			end
		end
	end
	
	
	local lut = {}
	local function get_proxy_internal(entity, create)
		local proxy = entity.surface.find_entity(get_name("entity"), entity.position)
		
		if not proxy then
			if create == false then return nil; end
			
			proxy = entity.surface.create_entity{
				name = get_name("entity"),
				position = entity.position,
				force = entity.force,
			}
			proxy.destructible = false
			proxy.operable = false
		end
		
		lut[entity] = proxy.get_or_create_control_behavior()
		return lut[entity]
	end
	local function get_proxy(entity, create)
		return lut[entity] or get_proxy_internal(entity, create)
	end
	
	
	function _M.write(entity, setting, value)
		local proxy = get_proxy(entity)
		
		-- we have to do this craziness here because the API is weird
		local params = {}
		for i, v in pairs(proxy.parameters.parameters) do
			if v.index ~= setting.index then table.insert(params, v)
			else
				if setting.type == "bool" then value = (value and 1) or 0; end
				table.insert(params, {
						signal = {type = "item", name = setting.signal_name},
						index = setting.index,
						count = value,
					})
			end
		end
		
		proxy.parameters = {enabled = true, parameters = params}
	end
	
	
	function _M.read(entity, setting)
		local proxy = get_proxy(entity)
		
		for _, v in pairs(proxy.parameters.parameters) do
			if v.signal.name == setting.signal_name then
				if setting.type == "bool" then
					if v.count == 0 then return false; else return true; end
				end
				return v.count
			end
		end
	end
	
	
	function _M.copy(source, dest)
		local source_proxy = get_proxy(source)
		local dest_proxy = get_proxy(dest)
		
		dest_proxy.parameters = source_proxy.parameters
	end
	
	
	function _M.destroy_proxy(entity)
		local proxy = get_proxy(entity, false)
		
		if proxy then
			proxy.entity.destroy()
			lut[entity] = nil
		end
	end
	
	
	function _M.migrate_settings(entity)
		local proxy = get_proxy(entity)
		if not proxy then return; end
		
		local params = {}
		for _, v in pairs(proxy.parameters.parameters) do
			local name = get_name_rev(v.signal.name)
			if name then
				table.insert(params, {
						signal = {type = "item", name = _M.settings[name].signal_name},
						index = _M.settings[name].index,
						count = v.count,
					})
			end
		end
		
		proxy.parameters = {enabled = true, parameters = params}
	end
	
	
	local e_name = get_name("entity")
	function _M.check_built_entity(entity)
		if entity.name == "entity-ghost" and entity.ghost_prototype.name == e_name then
			entity.revive()
		end
	end
	
	function _M.check_deconstruction(entity)
		if not entity.type then entity = entity.entity; end
		if entity.name == e_name then entity.cancel_deconstruction(entity.force); end
	end
	
	
	return _M
end

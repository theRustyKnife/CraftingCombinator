if not data then return nil; end -- requires data to load


local config = require "therustyknife.FML.config"
local FML = require "therustyknife.FML"


local function make_item_for(prototype, properties)
	properties = properties or {}
	local item = FML.table.deep_copy(properties.base or config.ITEM_BASE) -- get the base item
	
-- try to extract data from the prototype
	item.name = prototype.name
	item.place_result = prototype.name
	item.icon = prototype.icon or item.icon
	item.order = prototype.order or item.order
	item.subgroup = prototype.subgroup or item.subgroup
	
	if properties.properties then FML.table.insert_all(item, properties.properties, true, true); end -- override with explicitly defined properties
	
	data:extend{item}
	
	prototype.minable = prototype.minable or FML.table.deep_copy(config.DEFAULT_MINABLE) -- make sure there's a minable table
	prototype.minable.result = item.name
end

local function make_recipe_for(prototype, properties)
	properties = properties or {}
	local recipe = FML.table.deep_copy(properties.base or config.RECIPE_BASE) -- get the base recipe
	
	recipe.name = prototype.name
	recipe.result = prototype.name
	
	if properties.properties then FML.table.insert_all(recipe, properties.properties, true, true); end -- override with explicitly defined properties
	
	data:extend{recipe}
	
	if properties.unlock_with then -- add the recipe to the appropriate tech
		if data.raw["technology"] and data.raw["technology"][properties.unlock_with] then
			table.insert(data.raw["technology"][properties.unlock_with].effects, {type = "unlock-recipe", recipe = recipe.name})
		else
			error("Can't add recipe " .. recipe.name .. " to the " .. tostring(properties.unlock_with) .. " technology because it does not (yet) exist.")
		end
	end
end

local auto_gen_mapping = {item = make_item_for, recipe = make_recipe_for}
local function handle_auto_gen(prototype, auto_generate)
	if type(auto_generate) == "string" and auto_gen_mapping[auto_generate] then
		auto_gen_mapping[auto_generate](prototype)
		
	elseif type(auto_generate) == "table" then
		for i, v in pairs(auto_generate) do
			if type(v) == "string" and auto_gen_mapping[v] then
				auto_gen_mapping[v](prototype)
			elseif type(v) == "table" and type(i) == "string" and auto_gen_mapping[i] then
				auto_gen_mapping[i](prototype, v)
			end
		end
	end
end


local _M = {}


function _M.inherit(base_type, base_name)
	if not base_name then base_name = base_type; end -- use type as name if no name is specified
	if type(base_type) ~= "string" or type(base_name) ~= "string" or not data.raw[base_type] or not data.raw[base_type][base_name] then -- only inherit from valid entries
		error("can't inherit from type: " .. tostring(base_type) .. ", name: " .. tostring(base_name))
	end
	
	return FML.table.deep_copy(data.raw[base_type][base_name])
end

--[[
	prototypes format:
	prototype definition or {
		{
			base (optional) = {a table with a full or partial prototype definition, can be created from an exisiting prototype with inherit(base_type, base_name)},
			properties (optional) = {
				name = string, -- at least this should be overriden, otherwise you're just changing the base prototype (unless you defined base as a new prototype with a unique name)
				               -- if base is not defined, this table should look like the usual prototype definition
							   -- there's no checking for validity of the definition - the game's data loader will handle that
				...
			},
			auto_generate = one of the strings in the table or {
				"item", "recipe",
				item = {base = {a table with a full or partial item definition, can be created with inherit}, properties = {these will have the highest priority}},
				recipe = {base = {a table with a full or partial recipe definition, can be created with inherit}, properties = {these will have the highest priority}, unlock_with = string},
			}
		},
		...
	}
]]

function _M.make_prototypes(prototypes)
	for _, p in ipairs(prototypes) do _M.make_prototype(p); end
end

function _M.make_prototype(prototype)
	if prototype.type then data:extend{prototype} -- if it's a regular prototype definition, we add it to data right away
	else
		local res = FML.table.deep_copy(prototype.base) or {} -- get the base prototype
		
		if prototype.properties and type(prototype.properties == "table") then FML.table.insert_all(res, prototype.properties, true, true); end -- override with explicitly defined properties
		
		if prototype.auto_generate then handle_auto_gen(res, prototype.auto_generate); end -- auto-generate item and recipe
		
		data:extend{res}
	end
end

function _M.is_result(recipe, item)
	if type(recipe) == "string" then recipe = data.raw["recipe"][recipe]; end
	if type(item) == "table" then item = item.name; end
	assert(type(recipe) == "table", "Invalid recipe: " .. tostring(recipe))
	assert(type(item) == "string", "Invalid item: " .. tostring(item))
	
	if recipe.result and recipe.result == item then return true
	elseif recipe.results then
		for _, v in pairs(recipe.results) do
			if v.name == item then return true; end
		end
	end
	
	return false
end


return _M

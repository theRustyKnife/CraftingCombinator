local FML = require "therustyknife.FML"
local config = require "therustyknife.FML.config"


if not global then return nil; end -- require global to load


local global


local function on_load()
	global = FML.global.get("Object")
	setmetatable(global, {__mode = "v"}) -- make global a weak table to allow garbage colector to collect unreferenced Objects

	for _, o in pairs(global) do
		local prev = o.object
		for _, mt in ipairs(o.meta) do
			setmetatable(prev, mt)
			prev = mt
		end
	end
end

FML.global.on_fml_init(function(g)
	if not config.ON_LOAD_AFTER_INIT then on_load(); end
end)

FML.global.on_load(on_load)


local _M = {}


function _M:new(type)
	local res = {}
	local mt = type or self
	
	setmetatable(res, mt)
	mt.__index = mt
	
	res.Object_id = FML.table.get_next_index(global)
	global[Object_id] = {object = res, meta = {}}
	
	-- save the metatables for when we need them on load
	while mt ~= nil do
		table.insert(global[Object_id].meta, mt)
		mt = getmetatable(mt)
	end
	
	return res
end

function _M:extend()
	local child = {}
	child.super = {}
	
	setmetatable(child, self)
	setmetatable(child.super, self)
	self.__index = self
	
	return child
end


return _M

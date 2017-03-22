local FML = require "therustyknife.FML"
local entities = require "therustyknife.crafting_combinator.entities"


local _M = FML.Object:extend()


function _M:new(entity)
	local res = _M.super:new(self)
	res.tab = self.tab[entities.util.get_best_index(self.REFRESH_RATE)]
	table.insert(res.tab, res)
	res.entity = entity
	res.control_behavior = entity.get_or_create_control_behavior()
	
	res:on_create()
end

function _M:on_create() end -- abstract method that will be called when a new Combinator is created - use this instead of the constructor

function _M:update() end -- abstract method that will be called when this Combinator is supposed to be updated

function _M:on_opened(player) end -- abstract method that will be called when this combinator is opened

function _M:destroy()
	table.remove(self.tab, self:get_index())
end

function _M:get_index()
	for i, v in pairs(self.tab) do
		if v.entity == self.entity then return i; end
	end
end


return _M

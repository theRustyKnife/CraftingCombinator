local FML = require "therustyknife.FML"
local entities = require "therustyknife.crafting_combinator.entities"


local _M = FML.Object:extend()


function _M:new(entity)
	local res = _M.super:new(self)
	res.tab = self.tab
	table.insert(global.combinators.all, res)
	table.insert(res.tab, res)
	res.entity = entity
	res.control_behavior = entity.get_or_create_control_behavior()
	
	res.entity.operable = false
	
	res:on_create()
	
	return res
end

function _M:on_create() end -- abstract method that will be called when a new Combinator is created - use this instead of the constructor

function _M:update() end -- abstract method that will be called when this Combinator is supposed to be updated

function _M:on_opened(player) end -- abstract method that will be called when this combinator is opened

function _M:destroy()
	FML.table.remove_v(global.combinators.all, self)
	FML.table.remove_v(self.tab, self)
end


return _M

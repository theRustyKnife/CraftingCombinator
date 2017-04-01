local FML = require "therustyknife.FML"
local entities = require "therustyknife.crafting_combinator.entities"


local _M = FML.Object:extend()


function _M:new(entity, blueprint)
	local res = _M.super:new(self)
	res.type = self.TYPE
	res.tab = self.tab
	table.insert(global.combinators.all, res)
	table.insert(res.tab, res)
	res.entity = entity
	res.control_behavior = entity.get_or_create_control_behavior()
	
	res:on_create(blueprint)
	
	return res
end

function _M:on_create(blueprint) end -- abstract method that will be called when a new Combinator is created, true will be passed if built from blueprint - use this instead of the constructor

function _M:update() end -- abstract method that will be called when this Combinator is supposed to be updated

function _M:open(player)
	table.insert(global.to_close, self)
	self.entity.operable = false
end

function _M:on_checkbox_changed(group, name, state) end

function _M:on_radiobutton_changed(group, selected) end

function _M:on_button_clicked(player_index, name) end

function _M:on_number_selected(name, value) end

function _M:destroy()
	FML.table.remove_v(global.combinators.all, self)
	FML.table.remove_v(self.tab, self)
	
	_M.super.destroy(self)
end


return _M

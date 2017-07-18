local FML = therustyknife.FML
local table = FML.table


FML.events.on_load(function()
	global.combinators = table(global.combinators)
end)


local _M = FML.Object:extend("therustyknife.crafting_combinator.Combinator", function(self, entity)
	self.entity = entity
	self.control_behavior = entity.get_or_create_control_behavior()
	global.combinators:insert(self)
	
	return self
end)

function _M:destroy()
	global.combinators:remove_v(self)
	
	self.super.destroy(self)
end


--abstract
function _M:update() end


return _M

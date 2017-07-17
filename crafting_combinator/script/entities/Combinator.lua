local FML = therustyknife.FML
local table = FML.table


FML.events.on_load(function()
	global.combinators = table(global.combinators)
	global.combinators.all = table(global.combinators.all)
end)


local _M = FML.Object:extend(function(self, entity)
	self.entity = entity
	self.control_behavior = entity.get_or_create_control_behavior()
	
	--TODO: insert to global
end)





return _M

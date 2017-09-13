local FML = therustyknife.FML
local table = FML.table
local log = FML.log

local config = require "config"


FML.events.on_load(function()
	global.combinators = table(global.combinators)
	global.combinators.default = table(global.combinators.default)
	global.combinators.custom = table(global.combinators.custom)
end)


FML.events.on_tick(function(event)
	--TODO: proper tick handling
	-- Proposal: by default, all combinators are in one table updated using the modulo method
	--            -> Others will be placed in a table indexed by tick numbers and will re-place themselves into this
	--               table as needed
	
	-- Default
	local rate = settings.global[config.NAME.SETTING_REFRESH_RATE].value
	for i = event.tick % rate + 1, #global.combinators.default, rate do global.combinators.default[i]:update(); end
	
	-- Custom
	if global.combinators.custom[event.tick] then
		for _, c in pairs(global.combinators.custom[event.tick]) do if c.valid then c:update(); end end
		global.combinators.custom[event.tick] = nil
	end
end)


local _M = FML.Object:extend("therustyknife.crafting_combinator.Combinator", function(self, entity)
	log.dump("Created a new Combinator at ", entity.position)
	
	self.valid = true
	self.entity = entity
	self.control_behavior = entity.get_or_create_control_behavior()
	global.combinators.default:insert(self)
	
	return self
end)

function _M:destroy()
	log.dump("Destroying Combinator at ", self.entity.position)
	
	global.combinators.default:remove_v(self)
	self.valid = false
	_M.super.destroy(self)
end


FML.events.on_entity_settings_pasted(function(event)
	local src, dest = _M.get(event.source), _M.get(event.destination)
	
	if src and dest and src:typeof() == dest:typeof() then
		dest.settings:_copy(src.settings)
		dest:update(true) -- Pass true to indicate that settings have changed (force update)
	end
end)


function _M.get(entity)
	for _, c in global.combinators.default:ipairs() do
		if c.valid and c.entity == entity then return c; end
	end
	for _, t in global.combinators.custom:pairs() do
		for _, c in t:ipairs() do
			if c.valid and c.entity == entity then return c; end
		end
	end
	return nil
end


--abstract
_M:abstract("update")


return _M

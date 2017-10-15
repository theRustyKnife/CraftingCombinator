local FML = therustyknife.FML
local table = FML.table
local log = FML.log
local GUI = FML.GUI

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
		for _, c in ipairs(global.combinators.custom[event.tick]) do if c.valid then c:update(); end end
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

function _M:queue_for_update(interval)
--- Add this combinator to the update queue.
--@ uint interval=1: The interval to queue after
	self.last_queued_tick = game.tick+(interval or 1)
	global.combinators.custom:mk(self.last_queued_tick):insert(self)
end

function _M:use_custom_refresh_rate(state)
--- Handles changing from default to custom refresh rate and back.
--@ bool state: The desired state
	if not self.manual_update and state then
		-- Remove from the default global and queue for the next tick
		global.combinators.default:remove_v(self)
		self:queue_for_update()
		self.manual_update = true
	elseif self.manual_update and not state then
		global.combinators.default:insert(self)
		self.manual_update = false
	end
end

function _M:custom_refresh_rate_gui(parent)
	local flow = parent.add{type='flow', name='refresh_rate', direction='horizontal'}
	GUI.controls.CheckboxGroup{
		parent = flow,
		name = 'override_refresh_rate',
		options = {{name='override_enabled', state=self.settings.override_refresh_rate, caption={'crafting_combinator-gui.override-refresh-rate'}}},
		on_change = 'therustyknife.crafting_combinator.refresh_rate_override_change',
		meta = self,
		link_name = self:gui_link 'refresh_rate_override',
	}
	GUI.controls.NumberSelector{
		parent = flow,
		name = 'refresh_rate',
		value = self.settings.refresh_rate,
		on_change = 'therustyknife.crafting_combinator.refresh_rate_change',
		meta = self,
		min = 1,
		link_name = self:gui_link 'refresh_rate',
		format_func = function(value) return string.format("%.0f", value); end,
	}
end

FML.handlers.add('therustyknife.crafting_combinator.refresh_rate_override_change', function(group)
	local self = group.meta
	self.settings.override_refresh_rate = group.values.override_enabled
	self:use_custom_refresh_rate(self.settings.override_refresh_rate)
end)

FML.handlers.add('therustyknife.crafting_combinator.refresh_rate_change', function(picker)
	log.dump("Changed refresh_rate to ", picker.value)
	local self = picker.meta
	self.settings.refresh_rate = picker.value
	if self.last_queued_tick then global.combinators.custom[self.last_queued_tick]:remove_v(self); end
	self:queue_for_update()
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


_M:abstract 'update'

_M:abstract 'gui_link'


return _M

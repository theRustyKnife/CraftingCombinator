if not script then return nil; end -- requires script to load


local config = require "therustyknife.FML.config"
local FML = require "therustyknife.FML"


local GLOBAL_NAME = "events"


local _M = {}


local global = false -- the global serialized table for this module


-- handle the handlers that were to be added before global was loaded
local add_on_global_load = {}
local function delayed_add_handlers()
	for _, event in pairs(add_on_global_load) do
		_M.add_handler(event.id, event.f, event.name, event.keep_on_load)
	end
end

-- register the event to run any handlers that need to be run
local function register_event(event_id)
	script.on_event(event_id, function(event)
		for _, h in pairs(global.handlers[event_id]) do h.f(event); end
	end)
end

-- unregister an event
local function unregister_event(event_id)
	script.on_event(event_id, nil)
end


local function on_load()
	global = FML.global.get(GLOBAL_NAME)

	-- run the script for loading on the first tick so we don't modify the global table in on_load
	script.on_event(defines.events.on_tick, function(event)
		script.on_event(defines.events.on_tick, nil) -- remove the handler to only run in the first tick

		-- prune the handlers - remove the ones that were supposed to be run on load and eventually unregister unnecessary on_event hooks
		for event_id, handlers in pairs(global.handlers) do
			if FML.table.is_empty(handlers) then
				unregister_event(event_id)
				global.handlers[event_id] = nil
			else -- prune any handlers that aren't supposed to be reregistered
				for name, handler in pairs(handlers) do
					if not handler.keep_on_load then handlers[name] = nil; end
				end

				if FML.table.is_empty(handlers) then
					unregister_event(event_id)
					global.handlers[event_id] = nil
				end
			end
		end

		-- add the handlers that were supposed to be added before
		delayed_add_handlers()

		-- run the handlers for on_tick so they don't miss this one
		for _, h in pairs(global.handlers[defines.events.on_tick] or {}) do h.f(event); end
	end)
end

-- init the global table
FML.global.on_fml_init(function(g)
	global = g.get(GLOBAL_NAME)
	global.handlers = global.handlers or {}
	
	-- make sure that we init everything regardless of the users settings
	if not config.ON_LOAD_AFTER_INIT then on_load(); end
end)

FML.global.on_load(on_load)


function _M.add_handler(event_id, f, name, keep_on_load)
	-- if global hasn't been loaded yet add the handler to the delayed queue
	if not global then
		table.insert(
			add_on_global_load,
			{
				id = event_id,
				f = f,
				name = name,
				keep_on_load = keep_on_load,
			}
		)
		return name -- we don't know what the actual name will be if none was specified so we just return whatever the user passed in
	end
	
	-- if there was no handler for this event_id register it
	if FML.table.is_empty(global.handlers[event_id]) then
		register_event(event_id)
		global.handlers[event_id] = {}
	end
	
	name = name or FML.table.get_next_index(global.handlers[event_id])
	
	-- check argument validity
	assert(type(f) == "function", "Expected function for event handler, got " .. type(f) .. ".")
	assert(config.ALLOW_HANDLER_OVERRIDE or global.handlers[event_id][name] == nil, "A handler with name " .. tostring(name) .. " is already registered for event_id " .. tostring(event_id) .. " and override is disallowed.")
	
	global.handlers[event_id][name] = {f = f, keep_on_load = keep_on_load}
	
	return name
end

function _M.remove_handler(event_id, name)
	global.handlers[event_id][name] = nil
	
	if FML.table.is_empty(global.handlers[event_id]) then unregister_event(event_id); end
end

function _M.remove_all(event_id)
	unregister_event(event_id)
	global.handlers[event_id] = nil
end


-- some batches of events that often go together
_M.batches = {
	on_built = {defines.events.on_built_entity, defines.events.on_robot_built_entity},
	on_destroyed = {defines.events.on_entity_died, defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined},
}


function _M.batch_add_handler(events, f, name, keep_on_load) -- set a bunch of events to the same function
	for _, event_id in pairs(events) do _M.add_handler(event_id, f, name, keep_on_load); end
end

function _M.add_on_tick(f, interval, name)
	if interval == nil or interval <= 1 then return _M.add_handler(defines.events.on_tick, f, name); end
	
	return _M.add_handler(
		defines.events.on_tick,
		function(event) if event.tick % interval == 0 then f(event); end end,
		name
	)
end


-- a convenience for setting the events that avoids having to write defines.events...
_M.add = {}
for name, id in pairs(defines.events) do
	_M.add[name] = function(f, name, keep_on_load) _M.add_handler(id, f, name, keep_on_load); end
end


return _M

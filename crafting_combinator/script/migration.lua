local FML = therustyknife.FML
local table = therustyknife.FML.table
local log = therustyknife.FML.log

local entities = require 'script.entities.init'
local config = require 'config'


FML.events.on_mod_config_change(function(data)
	--TODO: earlier migration?
	
	if data.old_version < FML.Semver'0.10.0' then
		-- Random cleanup
		if global.therustyknife then global.therustyknife.get = nil; end
		global.fml_version = nil
		global.loaded = nil
		
		-- Get rid of the old combinators table
		local old_combinators = global.combinators; global.combinators = nil
		-- Set up the new table
		global.combinators = table(global.combinators)
		global.combinators.default = table(global.combinators.default)
		global.combinators.custom = table(global.combinators.custom)
		
		for _, c in pairs(old_combinators.crafting) do
			local new_c = entities.CraftingCombinator(c.entity)
			
			local settings = new_c.settings
			settings.empty_inserters = c.settings.cc_empty_inserters
			settings.mode_read = c.settings.cc_mode_read
			settings.mode_set = c.settings.cc_mode_set
			settings.read_bottleneck = c.settings.cc_read_bottleneck
			settings.read_speed = c.settings.cc_read_speed
			settings.request_modules = c.settings.cc_request_modules
			--! Careful with this - it just happened to work but may break in the future
			settings.item_dest = c.settings.cc_item_dest
			settings.module_dest = c.settings.cc_module_dest
			
			--TODO: chests and items from them, modules_to_request
		end
		
		--TODO: actually migrate these?
		for _, c in pairs(old_combinators.recipe) do
			log.dump("recipe combinator entity valid: ", c.entity.valid)
			if c.entity.valid then c.entity.destroy(); end
		end
		for _, surface in pairs(game.surfaces) do
			for _, entity in pairs(surface.find_entities_filtered{name=config.NAME.RC}) do
				entity.destroy()
			end
		end
		
		--TODO: global.to_close, global.gui
	end
end)

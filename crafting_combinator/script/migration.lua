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
			entities.CraftingCombinator(c.entity)
			
			--TODO: chests and items from them, modules_to_request, settings
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

local FML = require "therustyknife.FML"
local events = require "script.events"
local entities = require "therustyknife.crafting_combinator.entities"
local config = require "config"


local function register_entities(tab)
	for _, entity in pairs(tab) do
		events.on_built{created_entity = entity}
	end
end


FML.global.on_mod_config_change(function(data)
	local old_v = data.mod_changes["crafting_combinator"].old_version or ""
	
	if old_v < "0.5.0" then
		global.gui = {}
		global.combinators = {all = {}, crafting = {}, recipe = {}}
		
		global.settings = {refresh_rate = {cc = config.REFRESH_RATE_CC, rc = config.REFRESH_RATE_RC}}
		
		entities.util.update_global()
		
		for _, surface in pairs(game.surfaces) do
			register_entities(surface.find_entities_filtered{type = "constant-combinator"})
		end
	end
end)

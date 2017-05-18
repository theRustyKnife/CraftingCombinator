local FML = require "therustyknife.FML"
local events = require "script.events"
local entities = require "therustyknife.crafting_combinator.entities"
local config = require "config"


local function register_entities(tab)
	for _, entity in pairs(tab) do
		events.on_built{created_entity = entity}
	end
end

local function enable_researched_recipes()
	for _, force in pairs(game.forces) do
		if force.technologies["circuit-network"].researched then
			force.recipes["crafting_combinator_crafting-combinator"].enabled = true
			force.recipes["crafting_combinator_recipe-combinator"].enabled = true
		end
	end
end


FML.global.on_init(enable_researched_recipes)


FML.global.on_mod_config_change(function(data)
	enable_researched_recipes()
	
	local old_v = data.mod_changes["crafting_combinator"].old_version
	
	if not old_v then return; end
	
	log("found crafting_combinator version "..tostring(old_v))
	
	if old_v < "0.5.0" then
		log(" - updating to 0.5.0...")
		
		global.gui = {}
		global.combinators = {all = {}, crafting = {}, recipe = {}}
		
		global.settings = {
			cc_refresh_rate = config.REFRESH_RATE_CC,
			rc_refresh_rate = config.REFRESH_RATE_RC,
		}
		global.to_close = {}
		
		entities.util.update_global()
		
		for _, surface in pairs(game.surfaces) do
			register_entities(surface.find_entities_filtered{type = "constant-combinator"})
		end
		
		return
	end
	if old_v < "0.6.0" then
		log(" - updating to 0.6.0...")
		
		global.settings = {
			cc_refresh_rate = global.settings.refresh_rate.cc,
			rc_refresh_rate = global.settings.refresh_rate.rc,
		}
		
		local dests = {"active", "passive", "normal", "none"}
		
		for _, cc in pairs(global.combinators.crafting) do
			-- migrate settings to new format
			log("old_settings = "..serpent.line(cc.settings))
			cc.settings = {
				cc_mode_set = cc.settings.set_recipes,
				cc_mode_read = cc.settings.read_recipes,
				
				cc_module_dest = FML.blueprint_data.settings.cc_module_dest.options[cc.settings.module_destination],
				cc_item_dest = FML.blueprint_data.settings.cc_item_dest.options[cc.settings.item_destination],
				
				cc_empty_inserters = cc.settings.empty_inserters,
				cc_request_modules = true,
			}
			log("new_settings = "..serpent.line(cc.settings))
			
			-- save settings to blueprint_data
			for k, v in pairs(cc.settings) do
				FML.blueprint_data.write(cc.entity, FML.blueprint_data.settings[k], v)
			end
			
			cc.modules_to_request = {}
		end
		
		for _, rc in pairs(global.combinators.recipe) do
			rc.settings = {
				rc_mode = FML.blueprint_data.settings.rc_mode.options[rc.mode],
				rc_time_multiplier = 10,
			}
		end
	end
end)

FML.global.on_config_change(function(data)
	if data.mod_changes["Bottleneck"] or not data.mod_changes["Bottleneck"].new_version then
		log("Bottleneck was removed - disabling bottleneck read mode...")
		for _, combinator in pairs(global.combinators.crafting) do
			combinator.settings.cc_read_bottleneck = false
		end
	end
end)

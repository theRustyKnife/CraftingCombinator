local FML = require "FML.init"
local entities = require "script.entities.init"
local config = require "config"
local events = require "script.events"
local gui = require "script.gui"


require "script.migration"


script.on_event(defines.events.on_built_entity, events.on_built)
script.on_event(defines.events.on_robot_built_entity, events.on_built)

script.on_event(defines.events.on_preplayer_mined_item, events.on_destroyed)
script.on_event(defines.events.on_robot_pre_mined, events.on_destroyed)
script.on_event(defines.events.on_entity_died, events.on_destroyed)

script.on_event(defines.events.on_tick, events.on_tick)

script.on_event(config.MENU_KEY_NAME, events.on_menu_key_pressed)
script.on_event(config.CLOSE_KEY_NAME, events.on_close_menu_key_pressed)

script.on_event(defines.events.on_gui_click, gui.on_gui_clicked)

script.on_event(defines.events.on_player_rotated_entity, events.on_rotated)

local FML = therustyknife.FML

local config = require "config"


FML.data.make{
	{
	-- Crafting Combinator
		base = FML.data.inherit("constant-combinator"),
		properties = {
			name = config.NAME.CC,
			icon = "__crafting_combinator__/graphics/icon-crafting-combinator.png",
			item_slot_count = 3,
			sprites = {_tabs = function(val)
				val.filename = "__crafting_combinator__/graphics/crafting-combinator-entities.png"
				val.y = 0
			end},
		},
		generate = {
			item = {properties = {subgroup = "circuit-network"}},
			recipe = {base = FML.data.inherit("recipe", "constant-combinator"), unlock_with = "circuit-network"},
		},
	},
	--TODO: Recipe Combinator
	{
	-- Virtual recipe tab
		type = "item-group",
		name = config.NAME.GROUP,
		order = "fb",
		icon = "__crafting_combinator__/graphics/recipe-book.png",
		icon_size = 64,
	},
	{
	-- Default virtual recipe subgroup
		type = "item-subgroup",
		name = config.NAME.SUBGROUP,
		group = config.NAME.GROUP,
		order = "zzz[unsorted]",
	},
	{
	-- Subgroup for non virtual recipe signals
		type = "item-subgroup",
		name = "crafting_combinator-signals",
		group = config.NAME.GROUP,
		order = "___",
	},
	{
	-- Time signal
		type = "virtual-signal",
		name = config.NAME.TIME,
		icon = "__core__/graphics/clock-icon.png",
		subgroup = "crafting_combinator-signals",
		order = "[recipe-time]",
	},
	{
	-- Speed signal
		type = "virtual-signal",
		name = config.NAME.SPEED,
		icon = "__crafting_combinator__/graphics/speed-icon.png",
		subgroup = "crafting_combinator-signals",
		order = "b[crafting-speed]",
	},
	{
	-- Active overflow
		base = FML.data.inherit("logistic-container", "logistic-chest-active-provider"),
		properties = {
			name = config.NAME.OVERFLOW_A,
			flags = {"placeable-off-grid"},
			minable = nil,
			selectable_in_game = false,
			selection_box = nil,
			collision_mask = {},
			hidden = true,
			item_slot_count = config.OVERFLOW_SLOT_COUNT,
			picture = {
				filename = "__crafting_combinator__/graphics/trans.png",
				width = 1,
				height = 1,
			},
			circuit_wire_max_distance = 0,
		},
	},
	{
	-- Passive oerflow
		base = FML.data.inherit("logistic-container", config.NAME.OVERFLOW_A),
		properties = {
			name = config.NAME.OVERFLOW_P,
			logistic_mode = "passive-provider",
		},
	},
	{
	-- Normal overflow
		base = FML.data.inherit("container", "steel-chest"),
		properties = {
			name = config.NAME.OVERFLOW_N,
			flags = {"placeable-off-grid"},
			minable = nil,
			selectable_in_game = false,
			selection_box = nil,
			collision_mask = {},
			hidden = true,
			item_slot_count = config.OVERFLOW_SLOT_COUNT*2,
			picture = {
				filename = "__crafting_combinator__/graphics/trans.png",
				width = 1,
				height = 1,
			},
			circuit_wire_max_distance = 0,
		},
	},
}


FML.blueprint_data.add_prototype({
	name = config.NAME.CC_SETTINGS,
	settings = {
		mode_set = {
			type = "bool",
			index = 1,
			default = true,
		},
		mode_read = {
			type = "bool",
			index = 2,
			default = false,
		},
		item_dest = {
			type = "enum",
			index = 3,
			default = 1,
			options = {active = 1, passive = 2, normal = 3, none = 4},
		},
		module_dest = {
			type = "enum",
			index = 4,
			default = 2,
			options = {active = 1, passive = 2, normal = 3, none = 4},
		},
		empty_inserters = {
			type = "bool",
			index = 5,
			default = true,
		},
		request_modules = {
			type = "bool",
			index = 6,
			default = true,
		},
		read_speed = {
			type = "bool",
			index = 7,
			default = false,
		},
		read_bottleneck = {
			type = "bool",
			index = 8,
			default = false,
		},
	},
}, data.raw["constant-combinator"][config.NAME.CC].collision_box)

--[[ WIP
FML.blueprint_data.add_prototype({
	name = config.NAME.RC_SETTINGS,
	settings = {
		mode = {
			type = "enum",
			index = 1,
			default = 1,
			options = {ingredient = 1, product = 2, recipe = 3},
		},
		time_multiplier = {
			type = "int",
			index = 2,
			default = 1,
		},
		multiply_by_input = {
			type = "bool",
			index = 3,
			default = false,
		},
	},
}, nil) --TODO: fill in collision_box
--]]

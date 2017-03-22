local entities = require "therustyknife.crafting_combinator.entities"
local FML = require "therustyknife.FML"
local config = require "config"
local recipe_selector = require "script.recipe_selector"
local gui = require "script.gui"


FML.global.on_init(function()
	global.entities.crafting = global.entities.crafting or {}
	for i = 0, config.REFRESH_RATE_CC do
		global.entities.crafting[i] = global.entities.crafting[i] or {}
	end
end)


local _M = entities.Combinator:extend()

_M.REFRESH_RATE = config.REFRESH_RATE_CC

FML.global.on_load(function() _M.tab = global.entities.crafting end)


function _M:on_create()
	self.entity.operable = false
	self.settings = {
		set_recipes = true,
		read_recipes = false,
		modules_to_passive = true,
		items_to_passive = false,
	}
	self.chests = {
		passive = self.entity.surface.create_entity{
			name = config.OVERFLOW_P_NAME,
			position = self.entity.position,
			force = self.entity.force,
		},
		active = self.entity.surface.create_entity{
			name = config.OVERFLOW_A_NAME,
			position = self.entity.position,
			force = self.entity.force,
		},
	}
	
	for _, chest in pairs(self.chests) do chest.destructible = false; end
	
	self.inventories = {
		passive = self.chests.passive.get_inventory(defines.inventory.chest),
		active = self.chests.active.get_inventory(defines.inventory.chest),
	}
	
	self:find_assembler()
end

function _M:update()
	if self.assembler and self.assembler.valid then
		if self.settings.set_recipes then
			local recipe = recipe_selector.get_recipe(self.control_behavior)
			
			if self.assembler.recipe and ((not recipe) or recipe ~= self.assembler.recipe) then
				local target = self.chests.active
				if self.settings.items_to_passive then target = self.chests.passive; end
				
				for _, inventory in pairs{
					self.assembler.get_inventory(defines.inventory.assembling_machine_input),
					self.assembler.get_inventory(defines.inventory.assembling_machine_output),
				} do
					for i = 1, #inventory do
						local stack = inventory[i]
						if stack.valid_for_read then target.insert(stack); end
					end
				end
			end
			
			self.assembler.recipe = recipe
		end
		--TODO: read recipe
	end
end

function _M:destroy(player)
	-- if the player mined this, move items from overflow to her inventory, otherwise spill them on the ground --TODO: find a better way to handle the second case
	for _, inventory in pairs{self.inventories.passive, self.inventories.active} do
		for i = 1, #inventory do
			local stack = inventory[i]
			if stack.valid_for_read then
				local remaining = stack.count
				if player then remaining = remaining - player.insert(stack); end
				
				if remaining > 0 then
					stack.count = remaining
					self.entity.surface.spill_item_stack(self.entity.position, stack, true)
				end
			end
		end
	end
	
	self.chests.passive.destroy()
	self.chests.active.destroy()
	
	self.super.destroy(self)
end

function _M:on_opened(player)
	gui.crafting_combinator_settings(self, player)
end

function _M:find_assembler()
	self.assembler = self.entity.surface.find_entities_filtered{
		area = FML.surface.area_around(FML.surface.move_position(self.entity.position, self.entity.direction, config.CC_ASSEMBLER_DISTANCE), config.CC_ASSEMBLER_OFFSET),
		type = "assembling-machine",
	}[1]
	
	game.print("CraftingCombinator: found assembler = "..tostring(self.assembler))
end


return _M
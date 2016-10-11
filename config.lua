local special_cases = {
	--Item Collectors
	["item-collector"] = "item-collector-area",
	
	--Bio Industries
	["bi-liquid-air"] = "liquid-air",
	["bi-nitrogen"] = "nitrogen",
	["Bio_Cannon"] = "Bio_Cannon_Area",
	["bi-biomass-0"] = "bi-biomass",
	["bi-crushed-stone"] = "stone-crushed",
	["bi-seedling"] = "seedling",
}
local virtual_icons = {
	--Senpais Overhall
	["alien-artifact-from-small"] = "__base__/graphics/icons/alien-artifact.png",
	
	--Bio Industries
	["bi-plastic"] = "__base__/graphics/icons/plastic-bar.png",
	
	--Switch Liquid IO
	["flame-thrower-ammo-r"] = "__base__/graphics/icons/flame-thrower-ammo.png",
	["sulfur-r"] = "__base__/graphics/icons/sulfur.png",
}

local function reverse_table(tab)
	local res = {}
	for i, v in pairs(tab) do res[v] = i end
	return res
end

return {
	special_cases = special_cases,
	special_cases_r = reverse_table(special_cases),
	virtual_icons = virtual_icons
}
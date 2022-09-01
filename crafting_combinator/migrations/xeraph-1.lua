for _, combinator in pairs(global.cc.data) do
    combinator.entityUID = combinator.entity.unit_number
    combinator.last_assembler_recipe = false
    combinator.last_combinator_mode = combinator.settings.mode
end

for _, combinator in pairs(global.rc.data) do
    combinator.entityUID = combinator.entity.unit_number
end
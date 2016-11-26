local config = {}

-- how many ticks between updates
config.REFRESH_RATE = 60


-- how far to look for crafting combinators around an assembler
config.CC_SEARCH_DISTANCE = 2
-- how far in front of the combinator to search for an assembler
config.CC_ASSEMBLER_SEARCH_DISTANCE = 1
-- how wide of an area to search for an assembler
config.CC_ASSEMBLER_SEARCH_OFFSET = 0.5

-- crafting combinator name
config.CC_NAME = "crafting-combinator"
-- recipe combinator name
config.RC_NAME = "recipe-combinator"

return config
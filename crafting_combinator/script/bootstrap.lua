-- Fix that require raises an error when called after control.lua has finished executing, even if it doesn't actually
-- need to load anything... This was changed in 0.17.57 I think.
local _require = _G.require
_G.require = function(what, ...)
	if package.loaded[what] ~= nil then return package.loaded[what]; end
	return _require(what, ...)
end

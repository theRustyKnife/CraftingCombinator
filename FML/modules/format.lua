local FML = require "therustyknife.FML"


local _M = {}


if FML.surface then
	function _M.position(pos)
		local x, y = FML.surface.unpack_position(pos)
		return string.format("[%g, %g]", x, y)
	end
end


function _M.time(ticks) -- mostly borrowed from original util
	local s = ticks / 60
	local m = math.floor(s / 60)
	s = math.floor(s % 60)
	
	return string.format("%d:%02d", m, s)
end


return _M

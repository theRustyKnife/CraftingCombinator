local _M = {}


function _M.distance(pos1, pos2)
	local x1, y1 = _M.unpack_position(pos1)
	local x2, y2 = _M.unpack_position(pos2)
	return ((x1 - x2)^2 + (y1 - y2)^2)^0.5
end

function _M.move_position(position, direction, distance)
	local x, y = _M.unpack_position(position)
	
	if     direction == defines.direction.north then y = y - distance
	elseif direction == defines.direction.south then y = y + distance
	elseif direction == defines.direction.east  then x = x + distance
	elseif direction == defines.direction.west  then x = x - distance
	end
	
	return _M.pack_position(x, y)
end

function _M.flip_direction(direction)
	return (direction + 4) % 10 -- simplified implementation based on the defines values - I hope they don't change...
end

function _M.area_around(position, distance)
	local x, y = _M.unpack_position(position)
	local x1, y1, x2, y2 = x - distance, y - distance, x + distance, y + distance
	
	return {_M.pack_position(x1, y1), _M.pack_position(x2, y2)}
end

function _M.unpack_position(pos)
	local x, y = pos.x, pos.y
	
	if not x or not y then -- support both position formats ({x=x, y=y} and {[1]=x, [2]=y})
		x, y = pos[1], pos[2]
	end
	if not x or not y then error("Position not in correct format.") end
	
	return x, y
end

function _M.pack_position(x, y)
	return {x, y, x = x, y = y}
end


return _M
local _M = {}


_M.CONTAINER_TYPES = {
	['container'] = true,
	['logistic-container'] = true,
}


-- Coppied from __core__/lualib/util.lua
function _M.deepcopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		-- don't copy factorio rich objects
		elseif object.__self then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end


function _M.parse_gui_name(name)
	local gui_name = name:gsub('^crafting_combinator:', '')
	local unit_number = gui_name:gsub('^.-:', '')
	local element_name = unit_number:gsub('^.-:', '')
	return gui_name:gsub(':.*$', ''), tonumber((unit_number:gsub(':.*$', ''))), element_name
end


local _module_limitations
function _M.module_limitations()
	if not _module_limitations then
		_module_limitations = {}
		for _, item in pairs(game.item_prototypes) do
			if item.type == 'module' and next(item.limitations) then
				_module_limitations[item.name] = {}
				for _, limitation in pairs(item.limitations) do _module_limitations[item.name][limitation] = true; end
			end
		end
	end
	return _module_limitations
end


function _M.class(tab)
	tab = tab or {}
	tab.__mt = {__index = tab}
	tab.__class = tab
	function tab.__new() end
	function tab.new(...)
		local res = setmetatable({}, tab.__mt)
		return res:__new(...) or res
	end
	return setmetatable(tab, {__call = function(class, ...) return class.new(...); end})
end


_M.position = _M.class()
function _M.position:__new(x, y)
	if x and not y then
		self.x = x.x or x[1]
		self.y = x.y or x[2]
	else
		self.x = x or 0
		self.y = y or 0
	end
end

function _M.position.__mt:__unm() return _M.position(-self.x, -self.y); end
function _M.position.__mt:__add(other) return _M.position(self.x + other.x, self.y + other.y); end
function _M.position.__mt:__sub(other) return _M.position(self.x - other.x, self.y - other.y); end
function _M.position.__mt:__mul(q)
	if type(q) ~= 'number' then self, q = q, self; end
	return _M.position(self.x * q, self.y * q)
end

function _M.position.direction_vector(direction)
	if     direction == defines.direction.north then return _M.position( 0, -1)
	elseif direction == defines.direction.south then return _M.position( 0,  1)
	elseif direction == defines.direction.east  then return _M.position( 1,  0)
	elseif direction == defines.direction.west  then return _M.position(-1,  0)
	end
end

function _M.position:shift(direction, distance)
	return self + (_M.position.direction_vector(direction) * distance)
end

function _M.position:expand(x, y) return _M.area(self):expand(x, y); end


_M.area = _M.class()
function _M.area:__new(left_top, right_bottom)
	if left_top.left_top then left_top, right_bottom = left_top.left_top, left_top.right_bottom; end
	self.left_top = _M.position(left_top)
	self.right_bottom = _M.position(right_bottom or left_top)
end

function _M.area:expand(x, y)
	y = y or x
	return _M.area({self.left_top.x - x, self.left_top.y - y}, {self.right_bottom.x + x, self.right_bottom.y + y})
end

function _M.area.__mt:__add(other)
	if self.__class ~= _M.area then return other + self; end
	return _M.area(self.left_top + other, self.right_bottom + other)
end
function _M.area.__mt:__sub(other)
	if self.__class ~= _M.area then return other - self; end
	return self + (-other)
end

return _M

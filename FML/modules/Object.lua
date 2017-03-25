local FML = require "therustyknife.FML"
local config = require "therustyknife.FML.config"


local _M = {}


function _M:load(object)
	setmetatable(object, self)
	self.__index = self
end

function _M:new(type)
	local res = {}
	local mt = type or self
	
	setmetatable(res, mt)
	mt.__index = mt
	
	return res
end

function _M:extend()
	local child = {}
	child.super = {}
	
	setmetatable(child, self)
	setmetatable(child.super, self)
	self.__index = self
	
	return child
end

function _M:destroy() end


return _M

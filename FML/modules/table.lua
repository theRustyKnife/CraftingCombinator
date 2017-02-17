local _M = {}


function _M.deep_copy(tab) -- mostly borrowed from original util
	local lookup_table = {}
	
	local function _copy(tab)
		if type(tab) ~= "table" then return tab
		elseif tab.__self then return tab
		elseif lookup_table[tab] then return lookup_table[tab]
		end
		
		local new_table = {}
		lookup_table[tab] = new_table
		
		for i, v in pairs(tab) do new_table[_copy(i)] = _copy(v); end
		
		return setmetatable(new_table, getmetatable(tab))
	end
	
	return _copy(tab)
end

function _M.equals(tab1, tab2) -- mostly borrowed from original util
	if tab1 == tab2 then return true; end
	
	local function _equals_oneway(tab1, tab2)
		for i, v in pairs(tab1) do
			if type(v) == "table" and not v.__self and type(tab2[i]) == "table" and not tab2[i].__self then
				if not _M.equals(v, tab2[i]) then return false; end
			else
				if not v == tab1[i] then return false; end
			end
		end
	end
	
	return _equals_oneway(tab1, tab2) and _equals_oneway(tab2, tab1)
end

function _M.contains(tab, element)
	for _, v in pairs(tab) do if v == element then return true; end; end
	return false
end

function _M.insert_all(dest, src, overwrite, deep) -- overwrite is optional (default false), deep is optional (default false)
	if type(dest) ~= "table" or type(src) ~= "table" then return; end
	for i, v in pairs(src) do
		if overwrite or dest[i] == nil then
			if deep and type(v) == "table" then dest[i] = _M.deep_copy(v)
			else dest[i] = v
			end
		end
	end
end

function _M.getn(tab) -- count the number of elements in any table
	local n = 0
	for _ in pairs(tab) do n = n + 1; end
	return n
end

function _M.get_next_index(tab)
	local i = 1
	while true do
		if tab[i] == nil then return i; end
		i = i + 1
	end
end

function _M.is_empty(tab)
	if tab == nil then return true; end
	if _M.getn(tab) == 0 then return true; end
	return false
end


return _M

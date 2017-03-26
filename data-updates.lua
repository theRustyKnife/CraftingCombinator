local prototype = data.raw["item"]["rocket-part"]

if prototype then
	local new_flags = {}
	for _, flag in pairs(prototype.flags) do
		if flag ~= "hidden" then table.insert(new_flags, flag); end
	end
	prototype.flags = new_flags
end

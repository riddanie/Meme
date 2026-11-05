--!strict
-- PartCache.lua - Object pool for ragdoll instances
-- Prevents runtime lag from creating/destroying ragdolls mid-match

local PartCache = {}
PartCache.__index = PartCache

function PartCache.new(template: Model, capacity: number)
	local self = setmetatable({}, PartCache)
	self._template = template
	self._capacity = capacity
	self._available = {} -- Queue of available instances
	self._inUse = {} -- Set of currently used instances
	
	-- Pre-allocate instances
	for i = 1, capacity do
		local clone = template:Clone()
		clone.Parent = nil
		table.insert(self._available, clone)
	end
	
	return self
end

function PartCache:GetPart()
	if #self._available > 0 then
		local part = table.remove(self._available, 1)
		self._inUse[part] = true
		return part
	end
	
	-- Overflow: create new if pool exhausted
	local clone = self._template:Clone()
	self._inUse[clone] = true
	warn("[PartCache] Pool exhausted, created overflow instance")
	return clone
end

function PartCache:ReturnPart(part: Model)
	if self._inUse[part] then
		self._inUse[part] = nil
		part.Parent = nil
		table.insert(self._available, part)
	end
end

function PartCache:ReturnAll()
	for part, _ in pairs(self._inUse) do
		self._inUse[part] = nil
		part.Parent = nil
		table.insert(self._available, part)
	end
end

print("[PartCache] Module loaded")

return PartCache
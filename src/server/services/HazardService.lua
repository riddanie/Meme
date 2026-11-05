--!strict
-- HazardService.lua - Arena hazard management
-- Tsunami Boba, Anvil Rain, Lava Rising

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local HazardService = {}
HazardService.__index = HazardService

HazardService._activeHazards = {} -- [hazardId] = { type, data }
HazardService._hazardTimer = 0
HazardService._hazardCycle = 30 -- Switch hazards every 30 seconds
HazardService._currentHazard = "tsunami"

-- Hazard damage zones (for collision detection)
local DamageZones = {}

-- Tsunami Boba: Knockback + damage zone
function HazardService:SpawnTsunami()
	print("[HazardService] Tsunami Boba spawned")
	
	local tsunami = {
		id = "tsunami_" .. tick(),
		type = "tsunami",
		position = Vector3.new(0, 5, 0),
		radius = 20,
		damage = 10,
		knockback = 50,
		duration = 8,
		active = true,
	}
	
	self._activeHazards[tsunami.id] = tsunami
	
	-- Simulate wave movement
	task.delay(tsunami.duration, function()
		self._activeHazards[tsunami.id] = nil
		print("[HazardService] Tsunami ended")
	end)
	
	return tsunami
end

-- Anvil Rain: Physics damage + debris
function HazardService:SpawnAnvilRain()
	print("[HazardService] Anvil Rain spawned")
	
	local anvil = {
		id = "anvil_" .. tick(),
		type = "anvil",
		damage = 15,
		fallSpeed = 100,
		duration = 10,
		active = true,
	}
	
	self._activeHazards[anvil.id] = anvil
	
	-- Spawn anvils periodically
	local spawnCount = 0
	local spawnInterval = task.spawn(function()
		while anvil.active and spawnCount < 5 do
			spawnCount = spawnCount + 1
			-- Anvil spawn logic (physics part)
			task.wait(2)
		end
	end)
	
	task.delay(anvil.duration, function()
		anvil.active = false
		self._activeHazards[anvil.id] = nil
		print("[HazardService] Anvil Rain ended")
	end)
	
	return anvil
end

-- Lava Rising: DoT + climb-out mechanic
function HazardService:SpawnLavaRising()
	print("[HazardService] Lava Rising spawned")
	
	local lava = {
		id = "lava_" .. tick(),
		type = "lava",
		baseHeight = 0,
		riseSpeed = 1, -- Units per second
		damage = 5, -- DoT per second in lava
		duration = 15,
		active = true,
	}
	
	self._activeHazards[lava.id] = lava
	
	-- Lava rises over time
	local riseConnection = RunService.Heartbeat:Connect(function(dt)
		if lava.active then
			lava.baseHeight = lava.baseHeight + (lava.riseSpeed * dt)
		end
	end)
	
	task.delay(lava.duration, function()
		lava.active = false
		riseConnection:Disconnect()
		self._activeHazards[lava.id] = nil
		print("[HazardService] Lava Rising ended")
	end)
	
	return lava
end

-- Cycle through hazards
function HazardService:CycleHazards()
	local hazards = { "tsunami", "anvil", "lava" }
	local current = table.find(hazards, self._currentHazard) or 1
	local next = current % #hazards + 1
	self._currentHazard = hazards[next]
	
	if self._currentHazard == "tsunami" then
		return self:SpawnTsunami()
	elseif self._currentHazard == "anvil" then
		return self:SpawnAnvilRain()
	else
		return self:SpawnLavaRising()
	end
end

-- Get active hazards
function HazardService:GetActiveHazards()
	return self._activeHazards
end

-- Damage check (for player collision)
function HazardService:CheckHazardDamage(position: Vector3): { damage: number, hazard: string }
	local totalDamage = 0
	local hazardType = "none"
	
	for id, hazard in pairs(self._activeHazards) do
		if hazard.type == "tsunami" then
			local dist = (position - hazard.position).Magnitude
			if dist < hazard.radius then
				totalDamage = totalDamage + hazard.damage
				hazardType = "tsunami"
			end
		elseif hazard.type == "lava" then
			if position.Y < hazard.baseHeight + 5 then
				totalDamage = totalDamage + hazard.damage
				hazardType = "lava"
			end
		end
	end
	
	return {
		damage = totalDamage,
		hazard = hazardType,
	}
end

print("[HazardService] Module loaded")

return HazardService
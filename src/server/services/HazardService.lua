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
	
	local anvilData = {
		id = "anvil_" .. tick(),
		type = "anvil",
		damage = 15,
		fallSpeed = 100,
		duration = 10,
		active = true,
	}
	
	self._activeHazards[anvilData.id] = anvilData
	
	-- Spawn physical anvils
	local spawnCount = 0
	task.spawn(function()
		while anvilData.active and spawnCount < 8 do
			spawnCount = spawnCount + 1
			
			local anvilPart = Instance.new("Part")
			anvilPart.Name = "Hazard_Anvil"
			anvilPart.Size = Vector3.new(2, 2, 2)
			anvilPart.Material = Enum.Material.Metal
			anvilPart.Color = Color3.fromRGB(80, 80, 80)
			anvilPart.CollisionGroup = "Hazards"
			
			-- Random position above arena
			local rx = math.random(-80, 80)
			local rz = math.random(-80, 80)
			anvilPart.Position = Vector3.new(rx, 100, rz)
			anvilPart.Parent = workspace
			
			-- Add touch damage
			anvilPart.Touched:Connect(function(otherPart)
				local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
				if player then
					print("[HazardService] Anvil hit player:", player.Name)
					anvilPart:Destroy()
				end
			end)
			
			Debris:AddItem(anvilPart, 5)
			task.wait(1.2)
		end
	end)
	
	task.delay(anvilData.duration, function()
		anvilData.active = false
		self._activeHazards[anvilData.id] = nil
		print("[HazardService] Anvil Rain ended")
	end)
	
	return anvilData
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
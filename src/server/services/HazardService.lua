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

-- Gravity Vortex (Zone D): Radial pull + rotational force
function HazardService:SpawnGravityVortex()
	print("[HazardService] Gravity Vortex spawned")
	
	local vortex = {
		id = "vortex_" .. tick(),
		type = "vortex",
		position = Vector3.new(0, 5, 0), -- Center of arena
		outerRadius = 30,
		coreRadius = 8,
		pullStrength = 150,
		coreDamage = 8,
		outerDamage = 3,
		duration = 12,
		active = true,
	}
	
	self._activeHazards[vortex.id] = vortex
	
	-- Create vortex visual (placeholder sphere)
	local vortexPart = Instance.new("Part")
	vortexPart.Name = "Hazard_Vortex"
	vortexPart.Shape = Enum.PartType.Ball
	vortexPart.Size = Vector3.new(vortex.coreRadius * 2, vortex.coreRadius * 2, vortex.coreRadius * 2)
	vortexPart.Material = Enum.Material.Neon
	vortexPart.Color = Color3.fromRGB(138, 43, 226) -- Purple
	vortexPart.Transparency = 0.5
	vortexPart.CanCollide = false
	vortexPart.Anchored = true
	vortexPart.Position = vortex.position
	vortexPart.CollisionGroup = "Hazards"
	vortexPart.Parent = workspace
	
	-- Apply radial force to players in range
	local forceConnection = RunService.Heartbeat:Connect(function(dt)
		if not vortex.active then return end
		
		for _, player in ipairs(game.Players:GetPlayers()) do
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local hrp = character.HumanoidRootPart
				local dist = (hrp.Position - vortex.position).Magnitude
				
				if dist < vortex.outerRadius then
					-- Pull toward center
					local direction = (vortex.position - hrp.Position).Unit
					local pullForce = direction * vortex.pullStrength
					
					-- Apply velocity (simplified physics)
					if hrp:FindFirstChild("BodyVelocity") == nil then
						local bv = Instance.new("BodyVelocity")
						bv.Velocity = pullForce * dt
						bv.MaxForce = Vector3.new(5000, 0, 5000)
						bv.Parent = hrp
						Debris:AddItem(bv, 0.1)
					end
					
					-- Damage based on zone
					if dist < vortex.coreRadius then
						print("[HazardService] Vortex core damage:", player.Name, vortex.coreDamage)
					else
						print("[HazardService] Vortex outer damage:", player.Name, vortex.outerDamage)
					end
				end
			end
		end
	end)
	
	task.delay(vortex.duration, function()
		vortex.active = false
		forceConnection:Disconnect()
		vortexPart:Destroy()
		self._activeHazards[vortex.id] = nil
		print("[HazardService] Gravity Vortex ended")
	end)
	
	return vortex
end

-- Electric Grid (Zone E): Wave pattern electrified tiles
function HazardService:SpawnElectricGrid()
	print("[HazardService] Electric Grid spawned")
	
	local grid = {
		id = "grid_" .. tick(),
		type = "grid",
		tileSize = 7,
		gridDimension = 5, -- 5x5 grid = 25 tiles
		damage = 12,
		stunDuration = 0.5,
		knockupForce = 30,
		waveCount = 3,
		waveInterval = 4,
		duration = 12,
		active = true,
	}
	
	self._activeHazards[grid.id] = grid
	
	-- Create grid tiles
	local tiles = {}
	local startX = -17.5 -- Center 5x5 grid (35/2 = 17.5)
	local startZ = -17.5
	
	for row = 1, grid.gridDimension do
		for col = 1, grid.gridDimension do
			local tile = Instance.new("Part")
			tile.Name = "Hazard_GridTile"
			tile.Size = Vector3.new(grid.tileSize, 0.5, grid.tileSize)
			tile.Position = Vector3.new(
				startX + (col - 1) * grid.tileSize,
				0.25,
				startZ + (row - 1) * grid.tileSize
			)
			tile.Material = Enum.Material.Neon
			tile.Color = Color3.fromRGB(10, 10, 10) -- Dark (off state)
			tile.Anchored = true
			tile.CanCollide = false
			tile.CollisionGroup = "Hazards"
			tile.Parent = workspace
			
			table.insert(tiles, tile)
		end
	end
	
	-- Wave animation
	local waveCount = 0
	task.spawn(function()
		while grid.active and waveCount < grid.waveCount do
			waveCount = waveCount + 1
			print("[HazardService] Electric Grid wave", waveCount)
			
			-- Activate random tiles
			local activeTiles = {}
			for i = 1, math.random(8, 12) do
				local tile = tiles[math.random(1, #tiles)]
				tile.Color = Color3.fromRGB(11, 198, 227) -- Cyan (#0BC6E3)
				table.insert(activeTiles, tile)
			end
			
			-- Check player collisions
			task.delay(0.1, function()
				for _, tile in ipairs(activeTiles) do
					local region = Region3.new(
						tile.Position - tile.Size / 2,
						tile.Position + tile.Size / 2
					)
					-- Simplified collision check (proper raycast needed for production)
					for _, player in ipairs(game.Players:GetPlayers()) do
						local character = player.Character
						if character and character:FindFirstChild("HumanoidRootPart") then
							local hrp = character.HumanoidRootPart
							local dist = (hrp.Position - tile.Position).Magnitude
							if dist < 5 then
								print("[HazardService] Electric Grid hit:", player.Name)
								-- Apply knockup
								hrp.Velocity = hrp.Velocity + Vector3.new(0, grid.knockupForce, 0)
							end
						end
					end
				end
			end)
			
			-- Deactivate tiles
			task.delay(1, function()
				for _, tile in ipairs(activeTiles) do
					tile.Color = Color3.fromRGB(10, 10, 10)
				end
			end)
			
			task.wait(grid.waveInterval)
		end
	end)
	
	task.delay(grid.duration, function()
		grid.active = false
		for _, tile in ipairs(tiles) do
			tile:Destroy()
		end
		self._activeHazards[grid.id] = nil
		print("[HazardService] Electric Grid ended")
	end)
	
	return grid
end

-- Cycle through hazards
function HazardService:CycleHazards()
	local hazards = { "tsunami", "anvil", "lava", "vortex", "grid" }
	local current = table.find(hazards, self._currentHazard) or 1
	local next = current % #hazards + 1
	self._currentHazard = hazards[next]
	
	if self._currentHazard == "tsunami" then
		return self:SpawnTsunami()
	elseif self._currentHazard == "anvil" then
		return self:SpawnAnvilRain()
	elseif self._currentHazard == "lava" then
		return self:SpawnLavaRising()
	elseif self._currentHazard == "vortex" then
		return self:SpawnGravityVortex()
	else
		return self:SpawnElectricGrid()
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

-- Broadcast player death to clients
local function BroadcastPlayerDeath(player: Player, killerId: number?, mutationUsed: string?)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local src = ReplicatedStorage:FindFirstChild("src")
	if src then
		local shared = src:FindFirstChild("shared")
		if shared then
			local re = shared:FindFirstChild("RemoteEvents")
			if re then
				re = require(re)
				if re.PlayerDeath then
					re.PlayerDeath:FireAllClients({
						playerId = player.UserId,
						killerId = killerId,
						mutationUsed = mutationUsed,
						rewards = { dna = 10, placement = 1 }
					})
					print("[HazardService] Broadcasted death for", player.Name)
				end
			end
		end
	end
end

-- Check for void/fall death
function HazardService:CheckFallDamage(player: Player)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart
		-- Kill plane at Y = -50
		if hrp.Position.Y < -50 then
			print("[HazardService] Player fell into void:", player.Name)
			return true -- Player died from fall
		end
	end
	return false
end

-- Spawn player at Builder's SpawnLocation parts
function HazardService:SpawnPlayer(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	if character then
		local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local Humanoid = character:WaitForChild("Humanoid")
		
		-- Find random SpawnLocation in Workspace.Map
		local map = workspace:FindFirstChild("Map")
		if map then
			local spawns = map:FindFirstChildOfClass("SpawnLocation")
			if spawns then
				local spawnList = {}
				for _, part in ipairs(map:GetChildren()) do
					if part:IsA("SpawnLocation") then
						table.insert(spawnList, part)
					end
				end
				
				if #spawnList > 0 then
					local spawn = spawnList[math.random(1, #spawnList)]
					HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
					print("[HazardService] Spawned", player.Name, "at", spawn.Name)
				end
			else
				warn("[HazardService] No SpawnLocation found in Map")
				HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
			end
		else
			warn("[HazardService] Workspace.Map not found")
		end
		
		-- Grant spawn protection
		self:GrantSpawnProtection(player, 10)
		
		-- Wire Humanoid.Died for death payout
		Humanoid.Died:Connect(function()
			self:OnPlayerDeath(player)
		end)
	end
end

-- Handle player death + DNA payout
function HazardService:OnPlayerDeath(player: Player)
	print("[HazardService] Player", player.Name, "died")
	
	-- Calculate DNA reward (base 10 DNA per match)
	local dnaReward = 10
	
	-- Get DataService and save reward
	local DataService = nil
	local src = game.ServerScriptService:FindFirstChild("src")
	if src then
		local server = src:FindFirstChild("server")
		if server then
			local services = server:FindFirstChild("services")
			if services then
				local ds = services:FindFirstChild("DataService")
				if ds then
					DataService = require(ds)
					local profile = DataService:GetPlayerData(player)
					if profile and profile.Data then
						-- BUG #9 FIX: Map to schema fields
						profile.Data.MutagenDNA = (profile.Data.MutagenDNA or 0) + dnaReward
						profile.Data.TotalDeaths = (profile.Data.TotalDeaths or 0) + 1
						
						DataService:SavePlayerData(player, profile)
						print("[HazardService] Saved", dnaReward, "DNA (Total:", profile.Data.MutagenDNA, ") for", player.Name)
					end
				end
			end
		end
	end
	
	-- Broadcast death to clients
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local src2 = ReplicatedStorage:FindFirstChild("src")
	if src2 then
		local shared = src2:FindFirstChild("shared")
		if shared then
			local re = shared:FindFirstChild("RemoteEvents")
			if re then
				re = require(re)
				if re.PlayerDeath then
					re.PlayerDeath:FireAllClients({
						playerId = player.UserId,
						rewards = { dna = dnaReward, placement = 1 }
					})
				end
			end
		end
	end
end

-- Grant spawn protection (forcefield)
function HazardService:GrantSpawnProtection(player: Player, duration: number)
	local character = player.Character
	if character then
		local ff = Instance.new("ForceField")
		ff.Name = "SpawnProtection"
		ff.Visible = false
		ff.Parent = character
		task.delay(duration, function()
			if ff and ff.Parent then
				ff:Destroy()
			end
		end)
		print("[HazardService] Spawn protection granted to", player.Name, "for", duration, "seconds")
	end
end

return HazardService
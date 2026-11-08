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
HazardService._playerSpawnTimes = {} -- [player.UserId] = tick()
HazardService._playerDeathTimes = {} -- [player.UserId] = tick()
HazardService._respawnTime = 15 -- seconds
HazardService._lastDamageLogTimes = {} -- [player.UserId] = tick() for rate-limiting logs

-- Hazard damage zones (for collision detection)
local DamageZones = {}

function HazardService:CheckHazardDamage(player: Player, damage: number, hazardType: string)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Apply damage
	humanoid:TakeDamage(damage)
	
	-- Directive 3: Rate-limit damage log spam (1 log per player per 2s)
	local userId = player.UserId
	local now = tick()
	local lastLog = self._lastDamageLogTimes[userId] or 0
	if now - lastLog >= 2 then
		print("[HazardService] Player took damage from", hazardType, ":", player.Name)
		self._lastDamageLogTimes[userId] = now
	end
	
	-- Check for death (ragdoll + payout)
	if humanoid.Health <= 0 then
		print("[HazardService] Player killed by", hazardType, ":", player.Name)
		
		-- Ragdoll trigger
		self:TriggerRagdoll(player)
		
		-- Broadcast death & DNA payout (handled by OnPlayerDeath)
	end
end

function HazardService:TriggerRagdoll(player: Player)
	-- Load RagdollService
	local RagdollService = nil
	local src = game.ServerScriptService:FindFirstChild("src")
	if src then
		local server = src:FindFirstChild("server")
		if server then
			local services = server:FindFirstChild("services")
			if services then
				local rs = services:FindFirstChild("RagdollService")
				if rs then
					RagdollService = require(rs)
				end
			end
		end
	end
	
	if not RagdollService then
		warn("[HazardService] RagdollService not found")
		return
	end
	
	local character = player.Character
	if not character then return end
	
	-- Apply ragdoll variant based on active mutation
	local mutationId = "DEFAULT" -- TODO: Get from active mutation
	local ragdoll = RagdollService:ApplyMutation(player, mutationId)
	
	if ragdoll then
		-- Position ragdoll at player death location
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Fix 4: Ensure ragdoll PrimaryPart is set, then position
			local ragdollHRP = ragdoll:FindFirstChild("HumanoidRootPart")
			if ragdollHRP then
				if not ragdoll.PrimaryPart then
					ragdoll.PrimaryPart = ragdollHRP
				end
				ragdoll:SetPrimaryPartCFrame(hrp.CFrame)
				
				-- Apply death physics impulse
				ragdollHRP.AssemblyLinearVelocity = Vector3.new(
					math.random(-20, 20), 
					50, 
					math.random(-20, 20)
				)
			end
		end
		
		-- Cleanup after 5 seconds
		task.delay(5, function()
			RagdollService:ReturnRagdoll(player)
		end)
	end
	
	-- Disable player character physics
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
	end
	
	print("[HazardService] Ragdoll triggered for", player.Name)
end

-- Tsunami Boba: Knockback + damage zone
function HazardService:SpawnTsunami()
	print("[HazardService] Tsunami Boba spawned")
	
	-- Tsunami Visual
	local tsunamiPart = Instance.new("Part")
	tsunamiPart.Name = "TsunamiPart"
	tsunamiPart.Shape = Enum.PartType.Cylinder
	tsunamiPart.Size = Vector3.new(10, 40, 40)
	tsunamiPart.Material = Enum.Material.SmoothPlastic
	tsunamiPart.Color = Color3.fromRGB(11, 198, 227)
	tsunamiPart.Transparency = 0.5
	tsunamiPart.Anchored = true
	tsunamiPart.CanCollide = false
	tsunamiPart.Position = Vector3.new(0, 20, 0)
	tsunamiPart.Parent = workspace
	
	local tsunami = {
		id = "tsunami_" .. tick(),
		type = "tsunami",
		position = Vector3.new(0, 5, 0),
		radius = 20,
		damage = 10,
		knockback = 50,
		duration = 8,
		active = true,
		visual = tsunamiPart,
	}
	
	self._activeHazards[tsunami.id] = tsunami
	
	-- Check for player hits every heartbeat
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not tsunami.active then return end
		
		for _, player in ipairs(game.Players:GetPlayers()) do
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local hrp = character.HumanoidRootPart
				local dist = (hrp.Position - tsunami.position).Magnitude
				
				if dist < tsunami.radius then
					self:CheckHazardDamage(player, tsunami.damage, "Tsunami")
					
					-- Apply knockback
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 30, tsunami.knockback)
				end
			end
		end
	end)
	
	-- Cleanup
	task.delay(tsunami.duration, function()
		tsunami.active = false
		connection:Disconnect()
		if tsunami.visual then
			tsunami.visual:Destroy()
		end
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
			anvilPart.Name = "AnvilPart"
			anvilPart.Size = Vector3.new(2, 2, 2)
			anvilPart.Material = Enum.Material.SmoothPlastic
			anvilPart.Color = Color3.fromRGB(102, 102, 102)
			anvilPart.Transparency = 0
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
					self:CheckHazardDamage(player, anvilData.damage, "Anvil")
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
	
	-- Lava visual (pool part that rises)
	local lavaPool = Instance.new("Part")
	lavaPool.Name = "LavaPool"
	lavaPool.Size = Vector3.new(200, 1, 200)
	lavaPool.Material = Enum.Material.Neon
	lavaPool.Color = Color3.fromRGB(255, 69, 0)
	lavaPool.Transparency = 0.2
	lavaPool.Anchored = true
	lavaPool.CanCollide = false
	lavaPool.Position = Vector3.new(0, 0, 0)
	lavaPool.Parent = workspace
	
	local lava = {
		id = "lava_" .. tick(),
		type = "lava",
		baseHeight = 0,
		riseSpeed = 1, -- Units per second
		damage = 5, -- DoT per second in lava
		duration = 15,
		active = true,
		visual = lavaPool,
	}
	
	self._activeHazards[lava.id] = lava
	
	-- Lava rises over time
	local riseConnection = RunService.Heartbeat:Connect(function(dt)
		if lava.active then
			lava.baseHeight = lava.baseHeight + (lava.riseSpeed * dt)
			
			-- Update visual position
			if lavaPool then
				lavaPool.Position = Vector3.new(0, lava.baseHeight, 0)
			end
			
			-- Check for players below lava height
			for _, player in ipairs(game.Players:GetPlayers()) do
				local character = player.Character
				if character and character:FindFirstChild("HumanoidRootPart") then
					local hrp = character.HumanoidRootPart
					
					if hrp.Position.Y < lava.baseHeight then
						self:CheckHazardDamage(player, lava.damage * dt, "Lava")
					end
				end
			end
		end
	end)
	
	task.delay(lava.duration, function()
		lava.active = false
		riseConnection:Disconnect()
		if lava.visual then
			lava.visual:Destroy()
		end
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
	vortexPart.Name = "VortexSphere"
	vortexPart.Shape = Enum.PartType.Ball
	vortexPart.Size = Vector3.new(vortex.coreRadius * 2, vortex.coreRadius * 2, vortex.coreRadius * 2)
	vortexPart.Material = Enum.Material.Neon
	vortexPart.Color = Color3.fromRGB(46, 8, 84)
	vortexPart.Transparency = 0.7
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
					
					-- Damage based on zone (scaled by dt)
					local damage = 0
					if dist < vortex.coreRadius then
						damage = vortex.coreDamage * dt
					else
						damage = vortex.outerDamage * dt
					end
				
					-- Rate-limited damage via CheckHazardDamage
					self:CheckHazardDamage(player, damage, "vortex")
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
			tile.Name = "ElectricTile"
			tile.Size = Vector3.new(grid.tileSize, 0.5, grid.tileSize)
			tile.Position = Vector3.new(
				startX + (col - 1) * grid.tileSize,
				0.25,
				startZ + (row - 1) * grid.tileSize
			)
			tile.Material = Enum.Material.Neon
			tile.Color = Color3.fromRGB(255, 255, 0)
			tile.Transparency = 0.4
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
			
			-- Activate random tiles (make fully opaque)
			local activeTiles = {}
			for i = 1, math.random(8, 12) do
				local tile = tiles[math.random(1, #tiles)]
				tile.Transparency = 0 -- Flash to full brightness
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
					tile.Transparency = 0.4 -- Return to dim state
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
print("[HazardService] Module loaded")

-- Broadcast player death to clients
local function BroadcastPlayerDeath(player: Player, killerId: number?, mutationUsed: string?)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local src = ReplicatedStorage:FindFirstChild("src")
	if src then
		local shared = src:FindFirstChild("shared")
		if shared then
			local reModule = shared:FindFirstChild("RemoteEvents")
			if reModule then
				local re = require(reModule)
				if re.PlayerDeath then
					re.PlayerDeath:FireAllClients({
						playerId = player.UserId,
						killerId = killerId,
						mutationUsed = mutationUsed,
						timeSurvived = tick() - self._playerSpawnTimes[player.UserId],
						placement = self:CalculatePlacement(player.UserId),
						rewards = { dna = 10, placement = 1 }
					})
					print("[HazardService] Broadcasted death for", player.Name)
				end
			end
		end
	end
end

-- Check for void/fall death
function HazardService:CheckFallDamage(player: Player): boolean
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart
		-- Kill plane at Y = -50
		if hrp.Position.Y < -50 then
			print("[HazardService] Player fell into void:", player.Name)
			
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(100) -- Guaranteed death
			end
			
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
		
		-- Find random SpawnLocation in Workspace.Map.Spawns
		local map = workspace:FindFirstChild("Map")
		if map then
			local spawnsFolder = map:FindFirstChild("Spawns")
			if spawnsFolder then
				local spawnList = {}
				for _, part in ipairs(spawnsFolder:GetChildren()) do
					if part:IsA("SpawnLocation") then
						table.insert(spawnList, part)
					end
				end
				
				if #spawnList > 0 then
					local spawn = spawnList[math.random(1, #spawnList)]
					HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
					print("[HazardService] Spawned", player.Name, "at", spawn.Name)
					
					-- Track spawn time
					self._playerSpawnTimes[player.UserId] = tick()
				else
					warn("[HazardService] No SpawnLocations in Map.Spawns - spawning at fallback")
					HumanoidRootPart.CFrame = CFrame.new(100, 5, 100)
				end
			else
				warn("[HazardService] Workspace.Map.Spawns folder not found - spawning at fallback")
				HumanoidRootPart.CFrame = CFrame.new(100, 5, 100)
			end
		else
			warn("[HazardService] Workspace.Map not found")
		end
		
		-- Grant spawn protection
		self:GrantSpawnProtection(player, 10)
		end
end

-- Handle player death + DNA payout
function HazardService:OnPlayerDeath(player: Player)
	print("[HazardService] Player", player.Name, "died")
	
	-- Track death time for auto-respawn
	self._playerDeathTimes[player.UserId] = tick()
	
	-- Directive 1: Respawn via LoadCharacter after 3 seconds
	task.delay(3, function()
		if player and player.Parent then
			player:LoadCharacter()
			print("[HazardService] Respawned", player.Name)
		end
	end)
	
	-- Calculate DNA reward using GameConfig constants
	local survivalTime = 0
	if self._playerSpawnTimes and self._playerSpawnTimes[player.UserId] then
		survivalTime = math.floor(tick() - self._playerSpawnTimes[player.UserId])
	end
	
	-- Load GameConfig for constants
	local GameConfig = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("config"):WaitForChild("GameConfig"))
	
	local dnaReward = GameConfig.BASE_DNA_REWARD + (survivalTime * GameConfig.DNA_PER_SECOND_SURVIVED)
	
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
						print("[HazardService] Saved", dnaReward, "DNA (Survival:", survivalTime, "s, Total:", profile.Data.MutagenDNA, ") for", player.Name)
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
			local re = require(shared:FindFirstChild("RemoteEvents"))
			if re.PlayerEliminated then
				local totalAlive = 0
				for _, p in pairs(game.Players:GetPlayers()) do
					if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
						totalAlive += 1
					end
				end
				re.PlayerEliminated:FireAllClients({
					alive = totalAlive,
					total = #game.Players:GetPlayers()
				})
			end
	
			if re.PlayerDeath then
				re.PlayerDeath:FireAllClients({
					playerId = player.UserId,
					mutationUsed = "None",
					timeSurvived = tick() - self._playerSpawnTimes[player.UserId],
					placement = self:CalculatePlacement(player.UserId),
					rewards = { dna = dnaReward, placement = 1 }
				})
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

-- Init: Wire up death listeners
function HazardService:Init()
	local Players = game:GetService("Players")
	
	-- Wire for existing players at startup
	for _, player in ipairs(Players:GetPlayers()) do
		self:WirePlayerDeathListener(player)
	end
	
	-- Wire for future players
	Players.PlayerAdded:Connect(function(player)
		self:WirePlayerDeathListener(player)
	end)
	
	print("[HazardService] Death listeners wired")
end

function HazardService:WirePlayerDeathListener(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			self:OnPlayerDeath(player)
		end)
		
		-- Reset spawn time per life
		self._playerSpawnTimes[player.UserId] = tick()
	end)
end

-- Respawn check loop (runs every 1 second)
function HazardService:StartRespawnLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			local currentTime = tick()
			for userId, deathTime in pairs(self._playerDeathTimes) do
				if currentTime - deathTime >= self._respawnTime then
					-- Fix 3: Lookup player by UserId (GetUserIdFromCharacter doesn't exist)
					local player = nil
					for _, p in ipairs(game.Players:GetPlayers()) do
						if p.UserId == userId then
							player = p
							break
						end
					end
					
					if player and not player.Character then
						player:LoadCharacter()
						print("[HazardService] Respawned", player.Name, "after", self._respawnTime, "seconds")
					end
					
					self._playerDeathTimes[userId] = nil
				end
			end
		end
	end)
end

return HazardService
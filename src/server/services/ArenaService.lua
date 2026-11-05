--!strict
-- ArenaService.lua - Arena timer and match orchestration
-- Standalone version (no Knit dependency)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArenaService = {}
ArenaService.__index = ArenaService

ArenaService._matchActive = false
ArenaService._timeRemaining = 90
ArenaService._timerConnection = nil
ArenaService._hazardConnection = nil
ArenaService._mutationConnection = nil

-- Find shared modules
local function getSharedFolder()
	local src = ReplicatedStorage:FindFirstChild("src")
	if src then
		return src:FindFirstChild("shared")
	end
	return nil
end

local GameConfig = nil

local sharedFolder = getSharedFolder()
if sharedFolder then
	local config = sharedFolder:FindFirstChild("config")
	if config then
		local gameConfigModule = config:FindFirstChild("GameConfig")
		if gameConfigModule then
			GameConfig = require(gameConfigModule)
		end
	end
end

function ArenaService:StartMatch()
	if self._matchActive then
		print("[ArenaService] Match already active")
		return
	end

	self._matchActive = true
	self._timeRemaining = 90

	print("[ArenaService] Match started - 90 seconds")

	-- Load HazardService
	local HazardService = nil
	local src = game.ServerScriptService:FindFirstChild("src")
	if src then
		local server = src:FindFirstChild("server")
		if server then
			local services = server:FindFirstChild("services")
			if services then
				local hs = services:FindFirstChild("HazardService")
				if hs then
					HazardService = require(hs)
				end
			end
		end
	end

	-- Spawn first hazard immediately
	if HazardService then
		HazardService:CycleHazards()
	end

	-- Spawn all players once at match start
	if HazardService then
		for _, player in ipairs(game.Players:GetPlayers()) do
			HazardService:SpawnPlayer(player)
		end
	end

	-- Cycle mutations every 15s
	self._mutationConnection = task.spawn(function()
		while self._matchActive do
			task.wait(15)
			if self._matchActive then
				-- Load DataService and MutationService
				local DataService = nil
				local MutationService = nil
				local src = game.ServerScriptService:FindFirstChild("src")
				if src then
					local server = src:FindFirstChild("server")
					if server then
						local services = server:FindFirstChild("services")
						if services then
							local ds = services:FindFirstChild("DataService")
							local ms = services:FindFirstChild("MutationService")
							if ds then DataService = require(ds) end
							if ms then MutationService = require(ms) end
						end
					end
				end
				
				if not DataService or not MutationService then
					warn("[ArenaService] Required service(s) not found")
					return
				end
				
				for _, player in ipairs(game.Players:GetPlayers()) do
					local success, err = pcall(function()
						local profile = DataService:GetPlayerData(player)
						if profile then
							local pityCounter = profile.PityCounter or 0
							local mutation = MutationService:GenerateMutation(player, pityCounter)
							
							-- Update pity counter
							if mutation.rarity == "Legendary" or mutation.rarity == "Secret" then
								profile.PityCounter = 0
								print("[ArenaService] Pity reset for", player.Name)
							else
								profile.PityCounter = pityCounter + 1
								print("[ArenaService] Pity incremented to", profile.PityCounter, "for", player.Name)
							end
							
							DataService:SavePlayerData(player, profile)
							
							-- Broadcast to clients
							local RemoteEvents = ReplicatedStorage:FindFirstChild("src")
							if RemoteEvents then
								RemoteEvents = RemoteEvents:FindFirstChild("shared")
								if RemoteEvents then
									RemoteEvents = RemoteEvents:FindFirstChild("RemoteEvents")
									if RemoteEvents then
										RemoteEvents = require(RemoteEvents)
										if RemoteEvents.MutationBroadcast then
											RemoteEvents.MutationBroadcast:FireClient(player, {
												mutationId = mutation.mutationId,
												rarity = mutation.rarity,
												duration = mutation.duration,
											})
										end
									end
								end
							end
						else
							warn("[ArenaService] No profile for", player.Name)
						end
					end)
					
					if not success then
						warn("[ArenaService] Mutation generation failed:", err)
					end
				end
			end
		end
	end)

	-- Cycle hazards every 30 seconds
	self._hazardConnection = task.spawn(function()
		while self._matchActive do
			task.wait(30)
			if self._matchActive and HazardService then
				HazardService:CycleHazards()
			end
		end
	end)

	-- Start timer loop
	self._timerConnection = RunService.Heartbeat:Connect(function(dt)
		self._timeRemaining = self._timeRemaining - dt

		-- Match end
		if self._timeRemaining <= 0 then
			self:EndMatch()
		end
	end)
end

function ArenaService:EndMatch()
	if self._timerConnection then
		self._timerConnection:Disconnect()
		self._timerConnection = nil
	end

	self._matchActive = false
	print("[ArenaService] Match ended")
end

print("[ArenaService] Module loaded")

return ArenaService
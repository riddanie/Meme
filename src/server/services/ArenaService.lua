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

	-- Cycle mutations every 15s
	self._mutationConnection = task.spawn(function()
		while self._matchActive do
			task.wait(15)
			if self._matchActive then
				for _, player in ipairs(game.Players:GetPlayers()) do
					-- MutationService:GenerateMutation call here (requires ProfileService link)
					print("[ArenaService] Triggering mutation for:", player.Name)
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
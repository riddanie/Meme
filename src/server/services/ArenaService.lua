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
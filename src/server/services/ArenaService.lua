--!strict
-- Knit Service: Arena timer and match orchestration

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)
local RemoteEvents = require(game.ReplicatedStorage.Shared.RemoteEvents)

local ArenaService = Knit.CreateService {
	Name = "ArenaService",
	Client = {},
	_matchActive = false,
	_timeRemaining = 0,
}

function ArenaService:KnitStart()
	print("[ArenaService] Started")
end

function ArenaService:StartMatch()
	if self._matchActive then return end
	
	self._matchActive = true
	self._timeRemaining = GameConfig.ARENA_DURATION
	
	-- Arena timer loop
	task.spawn(function()
		while self._matchActive and self._timeRemaining > 0 do
			task.wait(1)
			self._timeRemaining -= 1
			
			-- Broadcast timer tick to clients
			if RemoteEvents.ArenaTimerTick then
				RemoteEvents.ArenaTimerTick:FireAllClients(self._timeRemaining)
			end
			
			-- Trigger mutation cycle every 15s
			if self._timeRemaining % GameConfig.MUTATION_INTERVAL == 0 then
				self:TriggerMutationCycle()
			end
		end
		
		self:EndMatch()
	end)
end

function ArenaService:TriggerMutationCycle()
	local MutationService = Knit.GetService("MutationService")
	local Players = game:GetService("Players")
	
	for _, player in Players:GetPlayers() do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if player.Character.Humanoid.Health > 0 then
				MutationService:GenerateMutation(player)
			end
		end
	end
end

function ArenaService:EndMatch()
	self._matchActive = false
	print("[ArenaService] Match ended")
	-- TODO: Calculate rewards and distribute DNA
end

function ArenaService:GetTimeRemaining(): number
	return self._timeRemaining
end

return ArenaService

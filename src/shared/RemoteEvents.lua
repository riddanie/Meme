--!strict
-- RemoteEvent definitions and stubs
-- Server creates, client references

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {
	-- Server → Client broadcasts
	MutationApplied = nil :: RemoteEvent?, -- Payload: { mutationId, rarity, duration }
	ArenaTimerTick = nil :: RemoteEvent?, -- Payload: { timeRemaining, isOvertime }
	PlayerDeath = nil :: RemoteEvent?, -- Payload: { killerId, mutationUsed, rewards: { dna, placement } }
	MutationBroadcast = nil :: RemoteEvent?, -- Payload: { playerId, mutation, rarity }
	PlayerEliminated = nil :: RemoteEvent?, -- Payload: { eliminatedId, killerId, placement }
	CosmeticEquipped = nil :: RemoteEvent?,
	UpdateBalance = nil :: RemoteEvent?, -- Payload: { balance: number }
	UpdateHUD = nil :: RemoteEvent?, -- Payload: { dna: number, health: number, playerCount: number }
	
	-- Client → Server requests
	SpinMutation = nil :: RemoteEvent?,
	EquipCosmetic = nil :: RemoteEvent?,
	RequestRespawn = nil :: RemoteEvent?,
	RequestSpectate = nil :: RemoteEvent?,
}

function RemoteEvents.CreateEvents()
	-- Server-side only: Create RemoteEvents
	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
	
	for eventName, _ in pairs(RemoteEvents) do
		if type(RemoteEvents[eventName]) ~= "function" then
			local remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = folder
			RemoteEvents[eventName] = remote
		end
	end
end

function RemoteEvents.GetEvents()
	-- Client-side: Reference existing RemoteEvents
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents")
	
	for eventName, _ in pairs(RemoteEvents) do
		if type(RemoteEvents[eventName]) ~= "function" then
			RemoteEvents[eventName] = folder:WaitForChild(eventName)
		end
	end
	
	return RemoteEvents
end

return RemoteEvents

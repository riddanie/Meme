--!strict
-- RemoteEvent definitions and stubs
-- Server creates, client references

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {
	-- Server → Client broadcasts
	MutationApplied = nil :: RemoteEvent?,
	ArenaTimerTick = nil :: RemoteEvent?,
	PlayerDeath = nil :: RemoteEvent?,
	CosmeticEquipped = nil :: RemoteEvent?,
	
	-- Client → Server requests
	SpinMutation = nil :: RemoteEvent?,
	EquipCosmetic = nil :: RemoteEvent?,
}

function RemoteEvents.CreateEvents()
	-- Server-side only: Create RemoteEvents
	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
	
	for eventName, _ in pairs(RemoteEvents) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = folder
		RemoteEvents[eventName] = remote
	end
end

function RemoteEvents.GetEvents()
	-- Client-side: Reference existing RemoteEvents
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents")
	
	for eventName, _ in pairs(RemoteEvents) do
		RemoteEvents[eventName] = folder:WaitForChild(eventName)
	end
	
	return RemoteEvents
end

return RemoteEvents

--!strict
-- RemoteEvent definitions and stubs
-- Server creates, client references

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENT_NAMES = {"MutationApplied", "ArenaTimerTick", "PlayerDeath", "MutationBroadcast", "PlayerEliminated", "CosmeticEquipped", "UpdateBalance", "RequestBalance", "UpdateHUD", "SpinMutation", "EquipCosmetic", "RequestRespawn", "RequestSpectate", "ShopPurchase", "ShopPurchaseResult", "ClaimDailyReward", "DailyRewardsSync"}

local RemoteEvents = {}

function RemoteEvents.CreateEvents()
	-- Server-side only: Create RemoteEvents
	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
	
	for _, eventName in ipairs(EVENT_NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = folder
		RemoteEvents[eventName] = remote
	end
end

function RemoteEvents.GetEvents()
	-- Client-side: Reference existing RemoteEvents
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents")
	
	for _, eventName in ipairs(EVENT_NAMES) do
		RemoteEvents[eventName] = folder:WaitForChild(eventName)
	end
	
	return RemoteEvents
end

return RemoteEvents

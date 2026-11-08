--!strict
-- MutationUIController.lua
-- Displays mutation spin UI with 15s countdown and queue (Wireframe 1)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))
local MutationDatabase = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("data"):WaitForChild("MutationDatabase"))

local MutationUIController = Knit.CreateController {
	Name = "MutationUIController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mutationFrame: ScreenGui? = nil
local timerLabel: TextLabel? = nil
local mutationQueue: { any } = {}

-- Create SurfaceGui layout for mutation UI
function MutationUIController:CreateUI()
	-- Reference existing ScreenGui from StarterGui
	local screenGui = playerGui:WaitForChild("MutationSpinUI")
	screenGui.DisplayOrder = 2
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Current mutation display
	local currentMutationFrame = screenGui:WaitForChild("CurrentMutation")
	local mutationName = currentMutationFrame:WaitForChild("MutationName")
	local mutationRarity = currentMutationFrame:WaitForChild("MutationRarity")
	local mutationTimerLabel = currentMutationFrame:WaitForChild("MutationTimerLabel")

	-- Mutations list (bottom center)
	local mutationsFrame = screenGui:WaitForChild("MutationsFrame")

	mutationFrame = screenGui
end

-- Show current mutation
function MutationUIController:ShowMutation(mutationId: string, rarity: string)
	if not mutationFrame then return end

	local currentMutationFrame = mutationFrame:FindFirstChild("CurrentMutation")
	if not currentMutationFrame then return end

	local mutationName = currentMutationFrame:FindFirstChild("MutationName")
	local mutationRarity = currentMutationFrame:FindFirstChild("MutationRarity")

	if mutationName then mutationName.Text = mutationId end
	if mutationRarity then
		mutationRarity.Text = string.upper(rarity)
		-- Color by rarity
		local rarityColors = {
			COMMON = Color3.fromRGB(68, 68, 68),
			RARE = Color3.fromRGB(11, 198, 227),
			EPIC = Color3.fromRGB(157, 78, 221),
			LEGENDARY = Color3.fromRGB(255, 215, 0),
			SECRET = Color3.fromRGB(255, 56, 100),
		}
		mutationRarity.BackgroundColor3 = rarityColors[string.upper(rarity)] or Color3.new(1, 1, 1)
	end
end

-- Update mutation queue display
function MutationUIController:UpdateQueue(mutations: { any })
	if not mutationFrame then return end

	local queueFrame = mutationFrame:FindFirstChild("QueueFrame")
	if not queueFrame then return end

	for i = 1, 3 do
		local queueItem = queueFrame:FindFirstChild("QueueItem" .. i)
		if queueItem then
			queueItem.Text = mutations[i] and mutations[i].id or "?"
		end
	end
end

-- Knit lifecycle
function MutationUIController:KnitInit()
	self:CreateUI()
end

function MutationUIController:KnitStart()
	RemoteEvents.GetEvents()

	-- Hook RemoteEvents (timer removed - handled by HUDController)

	if RemoteEvents.MutationBroadcast then
		RemoteEvents.MutationBroadcast.OnClientEvent:Connect(function(payload: any)
			self:ShowMutation(payload.mutationId, payload.rarity)
		end)
	end
end

return MutationUIController
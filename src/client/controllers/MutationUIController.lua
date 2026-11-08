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
	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MutationUI"
	screenGui.DisplayOrder = 2
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Current mutation display
	local currentMutationFrame = Instance.new("Frame")
	currentMutationFrame.Name = "CurrentMutation"
	currentMutationFrame.Size = UDim2.new(0, 280, 0, 64)
	currentMutationFrame.Position = UDim2.new(0.5, -140, 0, 112)
	currentMutationFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	currentMutationFrame.BackgroundTransparency = 0.2
	currentMutationFrame.BorderSizePixel = 0
	currentMutationFrame.Parent = screenGui

	local mutationName = Instance.new("TextLabel")
	mutationName.Name = "MutationName"
	mutationName.Size = UDim2.new(1, -100, 0, 28)
	mutationName.Position = UDim2.new(0, 8, 0, 6)
	mutationName.BackgroundTransparency = 1
	mutationName.TextColor3 = Color3.fromRGB(255, 255, 255)
	mutationName.TextSize = 18
	mutationName.Font = Enum.Font.GothamBold
	mutationName.Text = "SPEEDSTER"
	mutationName.TextXAlignment = Enum.TextXAlignment.Left
	mutationName.Parent = currentMutationFrame

	local mutationRarity = Instance.new("TextLabel")
	mutationRarity.Name = "MutationRarity"
	mutationRarity.Size = UDim2.new(0, 84, 0, 24)
	mutationRarity.AnchorPoint = Vector2.new(1, 0)
	mutationRarity.Position = UDim2.new(1, -8, 0, 8)
	mutationRarity.BackgroundColor3 = Color3.fromRGB(0, 198, 227)
	mutationRarity.BackgroundTransparency = 0.3
	mutationRarity.TextColor3 = Color3.fromRGB(255, 255, 255)
	mutationRarity.TextSize = 12
	mutationRarity.Font = Enum.Font.GothamBold
	mutationRarity.Text = "COMMON"
	mutationRarity.Parent = currentMutationFrame

	local mutationTimerLabel = Instance.new("TextLabel")
	mutationTimerLabel.Name = "MutationTimerLabel"
	mutationTimerLabel.Size = UDim2.new(1, -16, 0, 22)
	mutationTimerLabel.Position = UDim2.new(0, 8, 0, 36)
	mutationTimerLabel.BackgroundTransparency = 1
	mutationTimerLabel.TextColor3 = Color3.fromRGB(11, 198, 227)
	mutationTimerLabel.TextSize = 13
	mutationTimerLabel.Font = Enum.Font.Gotham
	mutationTimerLabel.Text = "Time: 00:30"
	mutationTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
	mutationTimerLabel.Parent = currentMutationFrame

	-- Mutations list (bottom center)
	local mutationsFrame = Instance.new("Frame")
	mutationsFrame.Name = "MutationsFrame"
	mutationsFrame.Size = UDim2.new(0, 280, 0, 96)
	mutationsFrame.Position = UDim2.new(0.5, -140, 1, -104)
	mutationsFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	mutationsFrame.BackgroundTransparency = 0.2
	mutationsFrame.BorderSizePixel = 0
	mutationsFrame.Parent = screenGui

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
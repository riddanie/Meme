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
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Timer display (center top)
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0, 200, 0, 80)
	timerLabel.Position = UDim2.new(0.5, -100, 0, 44)
	timerLabel.BackgroundTransparency = 0.8
	timerLabel.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	timerLabel.TextColor3 = Color3.fromRGB(11, 198, 227) -- Cyan
	timerLabel.TextSize = 48
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Text = "00:15"
	timerLabel.Parent = screenGui

	-- Current mutation display
	local currentMutationFrame = Instance.new("Frame")
	currentMutationFrame.Name = "CurrentMutation"
	currentMutationFrame.Size = UDim2.new(0, 350, 0, 80)
	currentMutationFrame.Position = UDim2.new(0.5, -175, 0, 150)
	currentMutationFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	currentMutationFrame.BackgroundTransparency = 0.2
	currentMutationFrame.BorderSizePixel = 0
	currentMutationFrame.Parent = screenGui

	local mutationName = Instance.new("TextLabel")
	mutationName.Name = "MutationName"
	mutationName.Size = UDim2.new(0, 250, 0, 40)
	mutationName.Position = UDim2.new(0, 8, 0, 8)
	mutationName.BackgroundTransparency = 1
	mutationName.TextColor3 = Color3.fromRGB(255, 255, 255)
	mutationName.TextSize = 18
	mutationName.Font = Enum.Font.GothamBold
	mutationName.Text = "SPEEDSTER"
	mutationName.Parent = currentMutationFrame

	local mutationRarity = Instance.new("TextLabel")
	mutationRarity.Name = "MutationRarity"
	mutationRarity.Size = UDim2.new(0, 100, 0, 30)
	mutationRarity.Position = UDim2.new(0, 260, 0, 12)
	mutationRarity.BackgroundColor3 = Color3.fromRGB(0, 198, 227)
	mutationRarity.BackgroundTransparency = 0.3
	mutationRarity.TextColor3 = Color3.fromRGB(255, 255, 255)
	mutationRarity.TextSize = 12
	mutationRarity.Font = Enum.Font.GothamBold
	mutationRarity.Text = "COMMON"
	mutationRarity.Parent = currentMutationFrame

	-- Upcoming mutations queue
	local queueFrame = Instance.new("Frame")
	queueFrame.Name = "QueueFrame"
	queueFrame.Size = UDim2.new(0, 350, 0, 150)
	queueFrame.Position = UDim2.new(0.5, -175, 0, 250)
	queueFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	queueFrame.BackgroundTransparency = 0.2
	queueFrame.BorderSizePixel = 0
	queueFrame.Parent = screenGui

	local queueLabel = Instance.new("TextLabel")
	queueLabel.Name = "QueueLabel"
	queueLabel.Size = UDim2.new(1, 0, 0, 30)
	queueLabel.BackgroundTransparency = 1
	queueLabel.TextColor3 = Color3.fromRGB(11, 198, 227)
	queueLabel.TextSize = 16
	queueLabel.Font = Enum.Font.GothamBold
	queueLabel.Text = "Next Mutations"
	queueLabel.Parent = queueFrame

	for i = 1, 3 do
		local queueItem = Instance.new("TextLabel")
		queueItem.Name = "QueueItem" .. i
		queueItem.Size = UDim2.new(1, -16, 0, 35)
		queueItem.Position = UDim2.new(0, 8, 0, 30 + (i - 1) * 40)
		queueItem.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		queueItem.BackgroundTransparency = 0.5
		queueItem.TextColor3 = Color3.fromRGB(255, 255, 255)
		queueItem.TextSize = 14
		queueItem.Font = Enum.Font.Gotham
		queueItem.Text = "?"
		queueItem.Parent = queueFrame
	end

	mutationFrame = screenGui
end

-- Update timer display
function MutationUIController:UpdateTimer(timeRemaining: number)
	if not timerLabel then return end

	local minutes = math.floor(timeRemaining / 60)
	local seconds = timeRemaining % 60
	timerLabel.Text = string.format("%02d:%02d", minutes, seconds)

	-- Flash red if low time (≤ 5 seconds)
	if timeRemaining <= 5 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 56, 100) -- Red
	else
		timerLabel.TextColor3 = Color3.fromRGB(11, 198, 227) -- Cyan
	end
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
		mutationRarity.Text = rarity
		-- Color by rarity
		local rarityColors = {
			Common = Color3.fromRGB(68, 68, 68),
			Rare = Color3.fromRGB(11, 198, 227),
			Epic = Color3.fromRGB(157, 78, 221),
			Legendary = Color3.fromRGB(255, 215, 0),
			Secret = Color3.fromRGB(255, 56, 100),
		}
		mutationRarity.BackgroundColor3 = rarityColors[rarity] or Color3.new(1, 1, 1)
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

	-- Hook RemoteEvents
	if RemoteEvents.ArenaTimerTick then
		RemoteEvents.ArenaTimerTick.OnClientEvent:Connect(function(payload: any)
			self:UpdateTimer(payload.timeRemaining)
		end)
	end

	if RemoteEvents.MutationApplied then
		RemoteEvents.MutationApplied.OnClientEvent:Connect(function(payload: any)
			self:ShowMutation(payload.mutationId, payload.rarity)
		end)
	end
end

return MutationUIController
--!strict
-- DeathController.lua
-- Displays death screen with rewards, replay controls, retry option (Wireframe 3)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))

local DeathController = Knit.CreateController {
	Name = "DeathController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local deathFrame: ScreenGui? = nil
local rewardLabels: { [string]: TextLabel } = {}

-- Create death screen UI
function DeathController:CreateUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeathScreen"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false -- Hidden by default
	screenGui.Parent = playerGui

	-- Fullscreen overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	overlay.BackgroundTransparency = 0.1
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Death message
	local deathFrame = Instance.new("Frame")
	deathFrame.Name = "DeathPanel"
	deathFrame.Size = UDim2.new(0, 382, 0, 600)
	deathFrame.Position = UDim2.new(0.5, -191, 0.5, -300)
	deathFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	deathFrame.BackgroundTransparency = 0.2
	deathFrame.BorderSizePixel = 0
	deathFrame.Parent = overlay

	local deathTitle = Instance.new("TextLabel")
	deathTitle.Name = "DeathTitle"
	deathTitle.Size = UDim2.new(1, 0, 0, 80)
	deathTitle.Position = UDim2.new(0, 0, 0, 16)
	deathTitle.BackgroundTransparency = 1
	deathTitle.TextColor3 = Color3.fromRGB(255, 56, 100)
	deathTitle.TextSize = 36
	deathTitle.Font = Enum.Font.GothamBold
	deathTitle.Text = "RAGDOLLED"
	deathTitle.Parent = deathFrame

	local killerLabel = Instance.new("TextLabel")
	killerLabel.Name = "KillerLabel"
	killerLabel.Size = UDim2.new(1, 0, 0, 30)
	killerLabel.Position = UDim2.new(0, 0, 0, 96)
	killerLabel.BackgroundTransparency = 1
	killerLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	killerLabel.TextSize = 14
	killerLabel.Font = Enum.Font.Gotham
	killerLabel.Text = "Killed by: Brainrot mutation"
	killerLabel.Parent = deathFrame
	rewardLabels["Killer"] = killerLabel

	-- Rewards section
	local rewardsFrame = Instance.new("Frame")
	rewardsFrame.Name = "RewardsFrame"
	rewardsFrame.Size = UDim2.new(1, -32, 0, 180)
	rewardsFrame.Position = UDim2.new(0, 16, 0, 140)
	rewardsFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	rewardsFrame.BackgroundTransparency = 0.3
	rewardsFrame.BorderSizePixel = 0
	rewardsFrame.Parent = deathFrame

	local rewardsTitle = Instance.new("TextLabel")
	rewardsTitle.Name = "Title"
	rewardsTitle.Size = UDim2.new(1, 0, 0, 30)
	rewardsTitle.BackgroundTransparency = 1
	rewardsTitle.TextColor3 = Color3.fromRGB(11, 198, 227)
	rewardsTitle.TextSize = 16
	rewardsTitle.Font = Enum.Font.GothamBold
	rewardsTitle.Text = "Rewards Earned"
	rewardsTitle.Parent = rewardsFrame

	local dnaLabel = Instance.new("TextLabel")
	dnaLabel.Name = "DNALabel"
	dnaLabel.Size = UDim2.new(1, -16, 0, 40)
	dnaLabel.Position = UDim2.new(0, 8, 0, 40)
	dnaLabel.BackgroundTransparency = 1
	dnaLabel.TextColor3 = Color3.fromRGB(0, 212, 170)
	dnaLabel.TextSize = 18
	dnaLabel.Font = Enum.Font.GothamBold
	dnaLabel.Text = "DNA Collected: +250"
	dnaLabel.TextXAlignment = Enum.TextXAlignment.Left
	dnaLabel.Parent = rewardsFrame
	rewardLabels["DNA"] = dnaLabel

	local placementLabel = Instance.new("TextLabel")
	placementLabel.Name = "PlacementLabel"
	placementLabel.Size = UDim2.new(1, -16, 0, 40)
	placementLabel.Position = UDim2.new(0, 8, 0, 80)
	placementLabel.BackgroundTransparency = 1
	placementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	placementLabel.TextSize = 18
	placementLabel.Font = Enum.Font.GothamBold
	placementLabel.Text = "Match Placement: #8 / 16"
	placementLabel.TextXAlignment = Enum.TextXAlignment.Left
	placementLabel.Parent = rewardsFrame
	rewardLabels["Placement"] = placementLabel

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, -16, 0, 40)
	timeLabel.Position = UDim2.new(0, 8, 0, 120)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(11, 198, 227)
	timeLabel.TextSize = 18
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.Text = "Time Survived: 01:22"
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = rewardsFrame
	rewardLabels["Time"] = timeLabel

	-- Replay controls
	local replayFrame = Instance.new("Frame")
	replayFrame.Name = "ReplayFrame"
	replayFrame.Size = UDim2.new(1, -32, 0, 100)
	replayFrame.Position = UDim2.new(0, 16, 0, 340)
	replayFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	replayFrame.BackgroundTransparency = 0.3
	replayFrame.BorderSizePixel = 0
	replayFrame.Parent = deathFrame

	local replayTitle = Instance.new("TextLabel")
	replayTitle.Name = "Title"
	replayTitle.Size = UDim2.new(1, 0, 0, 30)
	replayTitle.BackgroundTransparency = 1
	replayTitle.TextColor3 = Color3.fromRGB(11, 198, 227)
	replayTitle.TextSize = 16
	replayTitle.Font = Enum.Font.GothamBold
	replayTitle.Text = "Replay Controls"
	replayTitle.Parent = replayFrame

	local replayButton = Instance.new("TextButton")
	replayButton.Name = "ReplayButton"
	replayButton.Size = UDim2.new(0.48, 0, 0, 44)
	replayButton.Position = UDim2.new(0, 8, 0, 40)
	replayButton.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	replayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	replayButton.TextSize = 14
	replayButton.Font = Enum.Font.GothamBold
	replayButton.Text = "REPLAY DEATH"
	replayButton.Parent = replayFrame
	replayButton.MouseButton1Click:Connect(function()
		self:PlayReplay()
	end)

	local shareButton = Instance.new("TextButton")
	shareButton.Name = "ShareButton"
	shareButton.Size = UDim2.new(0.48, 0, 0, 44)
	shareButton.Position = UDim2.new(0.52, 0, 0, 40)
	shareButton.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	shareButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shareButton.TextSize = 14
	shareButton.Font = Enum.Font.GothamBold
	shareButton.Text = "SHARE CLIP"
	shareButton.Parent = replayFrame
	shareButton.MouseButton1Click:Connect(function()
		self:ShareClip()
	end)

	-- Action buttons
	local retryButton = Instance.new("TextButton")
	retryButton.Name = "RetryButton"
	retryButton.Size = UDim2.new(1, -32, 0, 50)
	retryButton.Position = UDim2.new(0, 16, 0, 460)
	retryButton.BackgroundColor3 = Color3.fromRGB(0, 212, 170)
	retryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	retryButton.TextSize = 16
	retryButton.Font = Enum.Font.GothamBold
	retryButton.Text = "RETRY MATCH (COST: 100 DNA)"
	retryButton.Parent = deathFrame
	retryButton.MouseButton1Click:Connect(function()
		self:RetryMatch()
	end)

	local lobbyButton = Instance.new("TextButton")
	lobbyButton.Name = "LobbyButton"
	lobbyButton.Size = UDim2.new(1, -32, 0, 50)
	lobbyButton.Position = UDim2.new(0, 16, 0, 525)
	lobbyButton.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	lobbyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	lobbyButton.TextSize = 16
	lobbyButton.Font = Enum.Font.GothamBold
	lobbyButton.Text = "RETURN TO LOBBY"
	lobbyButton.Parent = deathFrame
	lobbyButton.MouseButton1Click:Connect(function)
		self:ReturnToLobby()
	end)

	self.deathFrame = screenGui
end

-- Show death screen with rewards
function DeathController:ShowDeathScreen(killerMutation: string, rewards: any)
	if not self.deathFrame then return end

	self.deathFrame.Enabled = true

	if rewardLabels["Killer"] then
		rewardLabels["Killer"].Text = "Killed by: " .. killerMutation
	end
	if rewardLabels["DNA"] then
		rewardLabels["DNA"].Text = "DNA Collected: +" .. tostring(rewards.dna or 0)
	end
	if rewardLabels["Placement"] then
		rewardLabels["Placement"].Text = "Match Placement: #" .. tostring(rewards.placement or 0) .. " / 16"
	end
	if rewardLabels["Time"] then
		local minutes = math.floor((rewards.timeSurvived or 0) / 60)
		local seconds = (rewards.timeSurvived or 0) % 60
		rewardLabels["Time"].Text = "Time Survived: " .. string.format("%02d:%02d", minutes, seconds)
	end
end

-- Hide death screen
function DeathController:HideDeathScreen()
	if self.deathFrame then
		self.deathFrame.Enabled = false
	end
end

-- Play ragdoll replay
function DeathController:PlayReplay()
	print("[DeathController] Playing replay (TODO: orbital camera, 3s clip)")
	-- TODO: Implement orbital camera at 45° angle, 10 stud radius
end

-- Share clip
function DeathController:ShareClip()
	print("[DeathController] Share clip (TODO: export video)")
	-- TODO: Export 3-second clip, bonus DNA reward
end

-- Retry match
function DeathController:RetryMatch()
	print("[DeathController] Retry match (100 DNA cost)")
	if RemoteEvents.RequestRespawn then
		RemoteEvents.RequestRespawn:FireServer()
	end
	self:HideDeathScreen()
end

-- Return to lobby
function DeathController:ReturnToLobby()
	print("[DeathController] Return to lobby")
	self:HideDeathScreen()
	-- TODO: Teleport to lobby
end

-- Knit lifecycle
function DeathController:KnitInit()
	self:CreateUI()
end

function DeathController:KnitStart()
	RemoteEvents.GetEvents()

	-- Hook PlayerDeath event
	if RemoteEvents.PlayerDeath then
		RemoteEvents.PlayerDeath.OnClientEvent:Connect(function(payload: any)
			self:ShowDeathScreen(payload.mutationUsed or "Unknown", payload.rewards or {})
		end)
	end
end

return DeathController
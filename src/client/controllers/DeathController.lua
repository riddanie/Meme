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
	screenGui.DisplayOrder = 100
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
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
	deathFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	deathFrame.Size = UDim2.new(0, 360, 0, 310)
	deathFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	deathFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	deathFrame.BackgroundTransparency = 0.2
	deathFrame.BorderSizePixel = 0
	deathFrame.Parent = overlay

	local deathTitle = Instance.new("TextLabel")
	deathTitle.Name = "DeathTitle"
	deathTitle.Size = UDim2.new(1, -32, 0, 40)
	deathTitle.Position = UDim2.new(0, 16, 0, 10)
	deathTitle.BackgroundTransparency = 1
	deathTitle.TextColor3 = Color3.fromRGB(255, 56, 100)
	deathTitle.TextSize = 28
	deathTitle.Font = Enum.Font.GothamBold
	deathTitle.Text = "RAGDOLLED"
	deathTitle.Parent = deathFrame

	local killerLabel = Instance.new("TextLabel")
	killerLabel.Name = "KillerLabel"
	killerLabel.Size = UDim2.new(1, -32, 0, 24)
	killerLabel.Position = UDim2.new(0, 16, 0, 52)
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
	rewardsFrame.Size = UDim2.new(1, -32, 0, 120)
	rewardsFrame.Position = UDim2.new(0, 16, 0, 80)
	rewardsFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	rewardsFrame.BackgroundTransparency = 0.3
	rewardsFrame.BorderSizePixel = 0
	rewardsFrame.Parent = deathFrame

	local dnaLabel = Instance.new("TextLabel")
	dnaLabel.Name = "DNALabel"
	dnaLabel.Size = UDim2.new(1, -16, 0, 28)
	dnaLabel.Position = UDim2.new(0, 8, 0, 8)
	dnaLabel.BackgroundTransparency = 1
	dnaLabel.TextColor3 = Color3.fromRGB(0, 212, 170)
	dnaLabel.TextSize = 16
	dnaLabel.Font = Enum.Font.GothamBold
	dnaLabel.Text = "DNA Collected: +250"
	dnaLabel.TextXAlignment = Enum.TextXAlignment.Left
	dnaLabel.Parent = rewardsFrame
	rewardLabels["DNA"] = dnaLabel

	local placementLabel = Instance.new("TextLabel")
	placementLabel.Name = "PlacementLabel"
	placementLabel.Size = UDim2.new(1, -16, 0, 28)
	placementLabel.Position = UDim2.new(0, 8, 0, 40)
	placementLabel.BackgroundTransparency = 1
	placementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	placementLabel.TextSize = 16
	placementLabel.Font = Enum.Font.GothamBold
	placementLabel.Text = "Match Placement: #8 / 16"
	placementLabel.TextXAlignment = Enum.TextXAlignment.Left
	placementLabel.Parent = rewardsFrame
	rewardLabels["Placement"] = placementLabel

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, -16, 0, 28)
	timeLabel.Position = UDim2.new(0, 8, 0, 72)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(11, 198, 227)
	timeLabel.TextSize = 16
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.Text = "Time Survived: 01:22"
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = rewardsFrame
	rewardLabels["Time"] = timeLabel

	-- Action buttons
	local retryButton = Instance.new("TextButton")
	retryButton.Name = "RetryButton"
	retryButton.Size = UDim2.new(1, -32, 0, 44)
	retryButton.Position = UDim2.new(0, 16, 0, 208)
	retryButton.BackgroundColor3 = Color3.fromRGB(0, 212, 170)
	retryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	retryButton.TextSize = 16
	retryButton.Font = Enum.Font.GothamBold
	retryButton.Text = "RESPAWN"
	retryButton.Parent = deathFrame
	retryButton.MouseButton1Click:Connect(function()
		self:RetryMatch()
	end)

	local lobbyButton = Instance.new("TextButton")
	lobbyButton.Name = "LobbyButton"
	lobbyButton.Size = UDim2.new(1, -32, 0, 44)
	lobbyButton.Position = UDim2.new(0, 16, 0, 258)
	lobbyButton.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	lobbyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	lobbyButton.TextSize = 16
	lobbyButton.Font = Enum.Font.GothamBold
	lobbyButton.Text = "RETURN TO LOBBY"
	lobbyButton.Parent = deathFrame
	lobbyButton.MouseButton1Click:Connect(function()
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

	-- Hide death screen on respawn
	player.CharacterAdded:Connect(function()
		self:HideDeathScreen()
	end)

	-- Hook PlayerDeath event
	if RemoteEvents.PlayerDeath then
		RemoteEvents.PlayerDeath.OnClientEvent:Connect(function(payload: any)
			-- Only show death screen for local player
			if payload.playerId == player.UserId then
				self:ShowDeathScreen(payload.mutationUsed or "Unknown", payload.rewards or {})
			end
		end)
	end
end

return DeathController
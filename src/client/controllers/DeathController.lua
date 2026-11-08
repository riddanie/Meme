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
	local screenGui = playerGui:WaitForChild("DeathScreen")
	screenGui.DisplayOrder = 100
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false -- Hidden by default

	-- Fullscreen overlay
	local overlay = screenGui:WaitForChild("Overlay")

	-- Death panel
	local deathPanel = overlay:WaitForChild("DeathPanel")
	local deathTitle = deathPanel:WaitForChild("DeathTitle")
	local killerLabel = deathPanel:WaitForChild("KillerLabel")
	rewardLabels["Killer"] = killerLabel

	-- Rewards section
	local rewardsFrame = deathPanel:WaitForChild("RewardsFrame")
	local dnaLabel = rewardsFrame:WaitForChild("DNALabel")
	rewardLabels["DNA"] = dnaLabel

	local placementLabel = rewardsFrame:WaitForChild("PlacementLabel")
	rewardLabels["Placement"] = placementLabel

	local timeLabel = rewardsFrame:WaitForChild("TimeLabel")
	rewardLabels["Time"] = timeLabel

	-- Action buttons
	local retryButton = deathPanel:WaitForChild("RetryButton")
	retryButton.MouseButton1Click:Connect(function()
		self:RetryMatch()
	end)

	local lobbyButton = deathPanel:WaitForChild("LobbyButton")
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
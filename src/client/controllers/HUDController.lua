--!strict
-- HUDController.lua
-- Displays arena HUD with timer, stats, player count (Wireframe 2)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find Knit (may be missing)
local Knit
local kn = ReplicatedStorage:FindFirstChild("Packages")
if kn then
	local k = kn:FindFirstChild("Knit")
	if k then
		Knit = require(k)
	end
end

if not Knit then
	-- Manual controller if Knit absent
	Knit = {
		CreateController = function(self, tbl)
			return tbl
		end
	}
end

local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))

local HUDController = Knit.CreateController {
	Name = "HUDController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local statsLabels: { [string]: TextLabel } = {}
local timerLabel: TextLabel? = nil
local dnaLabel: TextLabel? = nil
local playersLabel: TextLabel? = nil
local healthFill: Frame? = nil

-- HUD layout already exists in StarterGui
function HUDController:CreateUI()
	local screenGui = playerGui:WaitForChild("ArenaHUD", 10)
	if not screenGui then
		warn("HUDController: ArenaHUD not found")
		return
	end
	
	screenGui.DisplayOrder = 1
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Arena timer (top center)
	timerLabel = screenGui:WaitForChild("TimerLabel", 10)
	if timerLabel then
		statsLabels["ArenaTimer"] = timerLabel
	end

	-- DNA and Players stats
	local dnaStat = screenGui:FindFirstChild("DNAStat")
	if dnaStat then
		dnaLabel = dnaStat:FindFirstChild("Label")
		if dnaLabel then
			statsLabels["DNA"] = dnaLabel
		end
	end

	local playersStat = screenGui:FindFirstChild("PlayersStat")
	if playersStat then
		playersLabel = playersStat:FindFirstChild("Label")
		if playersLabel then
			statsLabels["Players"] = playersLabel
		end
	end

	-- Health section
	local healthSection = screenGui:FindFirstChild("HealthSection")
	if healthSection then
		local healthBar = healthSection:FindFirstChild("HealthBar")
		if healthBar then
			healthFill = healthBar:FindFirstChild("HealthFill")
		end
	end

	print("HUDController Loaded")
end

-- Update arena timer
function HUDController:UpdateArenaTimer(timeRemaining: number)
	if not statsLabels["ArenaTimer"] then return end

	local minutes = math.floor(timeRemaining / 60)
	local seconds = timeRemaining % 60
	statsLabels["ArenaTimer"].Text = string.format("%02d:%02d", minutes, seconds)

	-- Flash red if low time (≤ 5 seconds)
	if timeRemaining <= 5 then
		statsLabels["ArenaTimer"].TextColor3 = Color3.fromRGB(255, 56, 100) -- Red
	else
		statsLabels["ArenaTimer"].TextColor3 = Color3.fromRGB(11, 198, 227) -- Cyan
	end
end

-- Update DNA only
function HUDController:UpdateDNA(dna: number)
	if statsLabels["DNA"] then
		statsLabels["DNA"].Text = "DNA: " .. tostring(dna)
	end
end

-- Update player count
function HUDController:UpdatePlayerCount(alive: number, total: number)
	if statsLabels["Players"] then
		statsLabels["Players"].Text = "#Players: " .. tostring(alive) .. "/" .. tostring(total)
	end
end

-- Update health bar
function HUDController:UpdateHealth(health: number, maxHealth: number)
	if healthFill then
		local healthPercent = math.clamp(health / maxHealth, 0, 1)
		healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
	end
end

-- Knit lifecycle
function HUDController:KnitInit()
	self:CreateUI()
end

function HUDController:KnitStart()
	RemoteEvents.GetEvents()

	-- Bind health to Humanoid
	local function bindHealth()
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				-- Initial update
				self:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
				
				-- Listen for changes
				humanoid.HealthChanged:Connect(function(health)
					self:UpdateHealth(health, humanoid.MaxHealth)
				end)
			end
		end
	end
	
	-- Bind on spawn and respawn
	bindHealth()
	player.CharacterAdded:Connect(bindHealth)

	-- Hook RemoteEvents
	if RemoteEvents.ArenaTimerTick then
		RemoteEvents.ArenaTimerTick.OnClientEvent:Connect(function(payload: any)
			self:UpdateArenaTimer(payload.timeRemaining)
		end)
	end

	if RemoteEvents.PlayerEliminated then
		RemoteEvents.PlayerEliminated.OnClientEvent:Connect(function(payload: any)
			-- Update player count when someone is eliminated
			self:UpdatePlayerCount(payload.alive or 0, payload.total or 0)
		end)
	end
	
	-- Listen for UpdateHUD events
	if RemoteEvents.UpdateHUD then
		RemoteEvents.UpdateHUD.OnClientEvent:Connect(function(payload: any)
			if payload.dna then
				self:UpdateDNA(payload.dna)
			end
			if payload.alive and payload.total then
				self:UpdatePlayerCount(payload.alive, payload.total)
			end
		end)
	end
end

return HUDController

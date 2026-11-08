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
local hudFrame: ScreenGui? = nil
local statsLabels: { [string]: TextLabel } = {}
local playerCountLabel: TextLabel? = nil

-- Create HUD layout
function HUDController:CreateUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ArenaHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Arena timer (top center)
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "ArenaTimer"
	timerLabel.Size = UDim2.new(0, 150, 0, 60)
	timerLabel.Position = UDim2.new(0.5, -75, 0, 44)
	timerLabel.BackgroundTransparency = 0.8
	timerLabel.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	timerLabel.TextColor3 = Color3.fromRGB(11, 198, 227)
	timerLabel.TextSize = 36
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Text = "01:30"
	timerLabel.Parent = screenGui
	statsLabels["ArenaTimer"] = timerLabel

	-- Store button (top right)
	local storeButton = Instance.new("TextButton")
	storeButton.Name = "StoreButton"
	storeButton.Size = UDim2.new(0, 90, 0, 40)
	storeButton.AnchorPoint = Vector2.new(1, 0)
	storeButton.Position = UDim2.new(1, -16, 0, 76)
	storeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	storeButton.BorderSizePixel = 0
	storeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	storeButton.TextSize = 16
	storeButton.Font = Enum.Font.GothamBold
	storeButton.Text = "STORE"
	storeButton.Parent = screenGui
	storeButton.MouseButton1Click:Connect(function()
		-- Open store (StoreController will handle)
		local StoreController = require(script.Parent.StoreController)
		if StoreController and StoreController.ShowStore then
			StoreController:ShowStore()
		end
	end)

	-- Player stats panel (left side)
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0, 200, 0, 200)
	statsFrame.Position = UDim2.new(0, 16, 0, 120)
	statsFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	statsFrame.BackgroundTransparency = 0.2
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = screenGui

	-- Health stat
	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.Size = UDim2.new(1, 0, 0, 40)
	healthLabel.Position = UDim2.new(0, 0, 0, 8)
	healthLabel.BackgroundTransparency = 1
	healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthLabel.TextSize = 16
	healthLabel.Font = Enum.Font.Gotham
	healthLabel.Text = "Health: 100%"
	healthLabel.TextXAlignment = Enum.TextXAlignment.Left
	healthLabel.Parent = statsFrame
	statsLabels["Health"] = healthLabel

	-- Shield stat
	local shieldLabel = Instance.new("TextLabel")
	shieldLabel.Name = "ShieldLabel"
	shieldLabel.Size = UDim2.new(1, 0, 0, 40)
	shieldLabel.Position = UDim2.new(0, 0, 0, 48)
	shieldLabel.BackgroundTransparency = 1
	shieldLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	shieldLabel.TextSize = 16
	shieldLabel.Font = Enum.Font.Gotham
	shieldLabel.Text = "Shield: 25%"
	shieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	shieldLabel.Parent = statsFrame
	statsLabels["Shield"] = shieldLabel

	-- DNA collected
	local dnaLabel = Instance.new("TextLabel")
	dnaLabel.Name = "DNALabel"
	dnaLabel.Size = UDim2.new(1, 0, 0, 40)
	dnaLabel.Position = UDim2.new(0, 0, 0, 88)
	dnaLabel.BackgroundTransparency = 1
	dnaLabel.TextColor3 = Color3.fromRGB(0, 212, 170)
	dnaLabel.TextSize = 16
	dnaLabel.Font = Enum.Font.GothamBold
	dnaLabel.Text = "DNA: 0"
	dnaLabel.TextXAlignment = Enum.TextXAlignment.Left
	dnaLabel.Parent = statsFrame
	statsLabels["DNA"] = dnaLabel

	-- Player count panel (right side)
	local playerCountFrame = Instance.new("Frame")
	playerCountFrame.Name = "PlayerCountFrame"
	playerCountFrame.Size = UDim2.new(0, 200, 0, 120)
	playerCountFrame.Position = UDim2.new(1, -216, 0, 120)
	playerCountFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	playerCountFrame.BackgroundTransparency = 0.2
	playerCountFrame.BorderSizePixel = 0
	playerCountFrame.Parent = screenGui

	local playerCountTitle = Instance.new("TextLabel")
	playerCountTitle.Name = "Title"
	playerCountTitle.Size = UDim2.new(1, 0, 0, 30)
	playerCountTitle.BackgroundTransparency = 1
	playerCountTitle.TextColor3 = Color3.fromRGB(11, 198, 227)
	playerCountTitle.TextSize = 14
	playerCountTitle.Font = Enum.Font.GothamBold
	playerCountTitle.Text = "Players Alive"
	playerCountTitle.Parent = playerCountFrame

	playerCountLabel = Instance.new("TextLabel")
	playerCountLabel.Name = "PlayerCount"
	playerCountLabel.Size = UDim2.new(1, 0, 0, 60)
	playerCountLabel.Position = UDim2.new(0, 0, 0, 40)
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.TextColor3 = Color3.fromRGB(0, 212, 170)
	playerCountLabel.TextSize = 32
	playerCountLabel.Font = Enum.Font.GothamBold
	playerCountLabel.Text = "0 / 16"
	playerCountLabel.Parent = playerCountFrame
	statsLabels["PlayerCount"] = playerCountLabel

	-- Active mutations list (bottom)
	local mutationsFrame = Instance.new("Frame")
	mutationsFrame.Name = "MutationsFrame"
	mutationsFrame.Size = UDim2.new(0, 300, 0, 120)
	mutationsFrame.Position = UDim2.new(0.5, -150, 1, -150)
	mutationsFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	mutationsFrame.BackgroundTransparency = 0.2
	mutationsFrame.BorderSizePixel = 0
	mutationsFrame.Parent = screenGui

	local mutationsTitle = Instance.new("TextLabel")
	mutationsTitle.Name = "Title"
	mutationsTitle.Size = UDim2.new(1, 0, 0, 30)
	mutationsTitle.BackgroundTransparency = 1
	mutationsTitle.TextColor3 = Color3.fromRGB(11, 198, 227)
	mutationsTitle.TextSize = 14
	mutationsTitle.Font = Enum.Font.GothamBold
	mutationsTitle.Text = "Active Mutations"
	mutationsTitle.Parent = mutationsFrame

	for i = 1, 3 do
		local mutationItem = Instance.new("TextLabel")
		mutationItem.Name = "MutationItem" .. i
		mutationItem.Size = UDim2.new(1, -16, 0, 25)
		mutationItem.Position = UDim2.new(0, 8, 0, 30 + (i - 1) * 28)
		mutationItem.BackgroundTransparency = 1
		mutationItem.TextColor3 = Color3.fromRGB(255, 255, 255)
		mutationItem.TextSize = 12
		mutationItem.Font = Enum.Font.Gotham
		mutationItem.Text = "• Mutation " .. i
		mutationItem.TextXAlignment = Enum.TextXAlignment.Left
		mutationItem.Parent = mutationsFrame
		statsLabels["Mutation" .. i] = mutationItem
	end

	hudFrame = screenGui
end

-- Update arena timer
function HUDController:UpdateArenaTimer(timeRemaining: number)
	if not statsLabels["ArenaTimer"] then return end

	local minutes = math.floor(timeRemaining / 60)
	local seconds = timeRemaining % 60
	statsLabels["ArenaTimer"].Text = string.format("%02d:%02d", minutes, seconds)
end

-- Update player stats
function HUDController:UpdateStats(health: number, shield: number, dna: number)
	if statsLabels["Health"] then
		statsLabels["Health"].Text = "Health: " .. math.floor(health) .. "%"
	end
	if statsLabels["Shield"] then
		statsLabels["Shield"].Text = "Shield: " .. math.floor(shield) .. "%"
	end
	if statsLabels["DNA"] then
		statsLabels["DNA"].Text = "DNA: " .. tostring(dna)
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
	if statsLabels["PlayerCount"] then
		statsLabels["PlayerCount"].Text = alive .. " / " .. total
	end
end

-- Show active mutations
function HUDController:ShowActiveMutations(mutations: { any })
	for i = 1, 3 do
		local label = statsLabels["Mutation" .. i]
		if label then
			if mutations[i] then
				local durationText = mutations[i].duration == -1 and "PERM" or (mutations[i].duration .. "s")
				label.Text = "• " .. mutations[i].id .. " (" .. durationText .. ")"
			else
				label.Text = ""
			end
		end
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
				humanoid.HealthChanged:Connect(function(health)
					local maxHealth = humanoid.MaxHealth
					local healthPercent = math.floor((health / maxHealth) * 100)
					if statsLabels["Health"] then
						statsLabels["Health"].Text = "Health: " .. healthPercent .. "%"
					end
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

	if RemoteEvents.MutationBroadcast then
		RemoteEvents.MutationBroadcast.OnClientEvent:Connect(function(payload: any)
			-- Update active mutations list
			-- TODO: maintain local mutation list and update it
		end)
	end
	
	-- Directive 2: Listen for UpdateHUD events
	if RemoteEvents.UpdateHUD then
		RemoteEvents.UpdateHUD.OnClientEvent:Connect(function(payload: any)
			if payload.dna then
				self:UpdateDNA(payload.dna)
			end
			if payload.playerCount then
				local maxPlayers = 16
				self:UpdatePlayerCount(payload.playerCount, maxPlayers)
			end
		end)
	end
end

return HUDController
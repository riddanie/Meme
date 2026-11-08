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

-- HUD layout already exists in StarterGui
function HUDController:CreateUI()
	local screenGui = playerGui:WaitForChild("ArenaHUD")
	screenGui.DisplayOrder = 1
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Arena timer (top center)
	local timerLabel = screenGui:WaitForChild("ArenaTimer")
	statsLabels["ArenaTimer"] = timerLabel

	-- Store button (top right)
	local storeButton = screenGui:WaitForChild("StoreButton")
	storeButton.MouseButton1Click:Connect(function()
		-- Open store (StoreController will handle)
		local StoreController = require(script.Parent.StoreController)
		if StoreController and StoreController.ShowStore then
			StoreController:ShowStore()
		end
	end)

	-- Player stats panel (left side)
	local statsFrame = screenGui:WaitForChild("StatsFrame")

	-- Health stat
	local healthLabel = statsFrame:WaitForChild("HealthLabel")
	statsLabels["Health"] = healthLabel

	-- Shield stat
	local shieldLabel = statsFrame:WaitForChild("ShieldLabel")
	statsLabels["Shield"] = shieldLabel

	-- DNA collected
	local dnaLabel = statsFrame:WaitForChild("DNALabel")
	statsLabels["DNA"] = dnaLabel

	-- Player count panel
	local playerCountFrame = screenGui:WaitForChild("PlayerCountFrame")
	playerCountLabel = playerCountFrame:WaitForChild("PlayerCount")
	statsLabels["PlayerCount"] = playerCountLabel

	-- Active mutations list (bottom)
	local mutationsFrame = screenGui:WaitForChild("MutationsFrame")
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

	-- Flash red if low time (≤ 5 seconds)
	if timeRemaining <= 5 then
		statsLabels["ArenaTimer"].TextColor3 = Color3.fromRGB(255, 56, 100) -- Red
	else
		statsLabels["ArenaTimer"].TextColor3 = Color3.fromRGB(11, 198, 227) -- Cyan
	end
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
--!strict
-- DailyRewardsController.lua: Handles daily reward claim interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit
local kn = ReplicatedStorage:FindFirstChild("Packages")
if kn then
	local k = kn:FindFirstChild("Knit")
	if k then Knit = require(k) end
end

if not Knit then Knit = { CreateController = function(self, tbl) return tbl end } end

local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))

local DailyRewardsController = Knit.CreateController {
	Name = "DailyRewardsController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dailyUI: ScreenGui? = nil
local streakLabel: TextLabel? = nil
local claimButton: TextButton? = nil

function DailyRewardsController:CreateUI()
	dailyUI = playerGui:FindFirstChild("DailyRewardsUI")
	if dailyUI then
		dailyUI.Enabled = false
		streakLabel = dailyUI:FindFirstChild("StreakLabel")
		claimButton = dailyUI:FindFirstChild("ClaimButton")
		
		if claimButton then
			claimButton.MouseButton1Click:Connect(function()
				self:ClaimReward()
			end)
		end
		
		-- Bind open button from ArenaHUD
		local screenGui = playerGui:FindFirstChild("ArenaHUD")
		if screenGui then
			local openBtn = screenGui:FindFirstChild("DailyButton")
			if openBtn then
				openBtn.MouseButton1Click:Connect(function()
					self:ShowUI()
				end)
			end
		end
	end
end

function DailyRewardsController:BindEvents()
	if RemoteEvents.DailyRewardsSync then
		RemoteEvents.DailyRewardsSync.OnClientEvent:Connect(function(payload)
			if payload.success then
				print("[DailyRewardsController] Claimed! Streak:", payload.streak)
				if streakLabel then
					streakLabel.Text = "Streak: " .. tostring(payload.streak)
				end
				if claimButton then
					claimButton.Visible = false
				end
			else
				warn("[DailyRewardsController] Claim failed:", payload.reason)
			end
		end)
	end
end

function DailyRewardsController:ShowUI()
	if dailyUI then dailyUI.Enabled = true end
end

function DailyRewardsController:ClaimReward()
	if RemoteEvents.ClaimDailyReward then
		RemoteEvents.ClaimDailyReward:FireServer()
	end
end

function DailyRewardsController:KnitInit()
	self:CreateUI()
end

function DailyRewardsController:KnitStart()
	self:BindEvents()
end

return DailyRewardsController

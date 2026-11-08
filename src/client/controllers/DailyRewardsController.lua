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
	-- Wait for DailyRewardsUI with timeout
	local success = pcall(function()
		dailyUI = playerGui:WaitForChild("DailyRewardsUI", 10)
	end)
	
	if not success or not dailyUI then
		warn("[DailyRewardsController] DailyRewardsUI not found within timeout")
		return
	end
	
	dailyUI.Enabled = false
	streakLabel = dailyUI:FindFirstChild("StreakLabel", true)
	claimButton = dailyUI:FindFirstChild("ClaimButton", true)
	
	if claimButton then
		claimButton.MouseButton1Click:Connect(function()
			self:ClaimReward()
		end)
	end
	
	-- Bind close button
	local header = dailyUI:FindFirstChild("Header", true)
	if header then
		local closeBtn = header:FindFirstChild("CloseButton", true)
		if closeBtn then
			closeBtn.MouseButton1Click:Connect(function()
				self:HideUI()
			end)
		end
	end
	
	-- Bind open button from ArenaHUD - wait with timeout
	local success2 = pcall(function()
		local screenGui = playerGui:WaitForChild("ArenaHUD", 10)
		if screenGui then
			local openBtn = screenGui:FindFirstChild("DailyButton", true)
			if openBtn then
				openBtn.MouseButton1Click:Connect(function()
					self:ShowUI()
				end)
			end
		end
	end)
end

function DailyRewardsController:BindEvents()
	if RemoteEvents.DailyRewardsSync then
		RemoteEvents.DailyRewardsSync.OnClientEvent:Connect(function(payload)
			if payload.success then
				print("[DailyRewardsController] Claimed! Streak:", payload.streak)
				if streakLabel then
					streakLabel.Text = "Day " .. tostring(payload.streak) .. " / 7"
				end
				if claimButton then
					claimButton.Visible = false
				end
				
				-- Day 7 pulse animation for CLAIM NOW badge
				local badgeContainer = dailyUI:FindFirstChild("BadgeContainer", true)
				if badgeContainer then
					for _, child in ipairs(badgeContainer:GetChildren()) do
						if child:IsA("TextLabel") and child.Text == "CLAIM NOW" then
							local TweenService = game:GetService("TweenService")
							local stroke = child:FindFirstChildOfClass("UIStroke")
							if not stroke then
								stroke = Instance.new("UIStroke")
								stroke.Color = Color3.fromRGB(11, 198, 227)
								stroke.Thickness = 2
								stroke.Parent = child
							end
							
							local tween = TweenService:Create(
								stroke,
								TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
								{Transparency = 0.5}
							)
							tween:Play()
						end
					end
				end
			else
				warn("[DailyRewardsController] Claim failed:", payload.reason)
			end
		end)
	end
end

function DailyRewardsController:ShowUI()
	if dailyUI then
		dailyUI.Enabled = true
	else
		warn("[DailyRewardsController] DailyRewardsUI not found")
	end
end

function DailyRewardsController:HideUI()
	if dailyUI then
		dailyUI.Enabled = false
	end
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

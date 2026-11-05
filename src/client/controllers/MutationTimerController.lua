--!strict
-- MutationTimerController.lua
-- Handles mutation timer display with permanent/countdown/danger states (BUG #7)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))

local MutationTimerController = Knit.CreateController {
	Name = "MutationTimerController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local timerLabel: TextLabel? = nil
local timerFrame: Frame? = nil
local activeMutations: { [string]: { id: string, duration: number, startTime: number, isPermanent: boolean } } = {}

-- Color palette
local COLOR_PERMANENT = Color3.fromRGB(255, 200, 0) -- Gold
local COLOR_NORMAL = Color3.fromRGB(11, 198, 227) -- Cyan
local COLOR_DANGER = Color3.fromRGB(255, 50, 50) -- Red

function MutationTimerController:CreateUI()
	-- Timer display frame
	timerFrame = Instance.new("Frame")
	timerFrame.Name = "MutationTimerFrame"
	timerFrame.Size = UDim2.new(0, 240, 0, 100)
	timerFrame.Position = UDim2.new(0.5, -120, 0, 40)
	timerFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	timerFrame.BackgroundTransparency = 0.7
	timerFrame.BorderSizePixel = 2
	timerFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	timerFrame.Parent = playerGui
	
	-- Add corner radius via UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = timerFrame
	
	-- Timer label (main display)
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 1, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.TextColor3 = COLOR_NORMAL
	timerLabel.TextSize = 56
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Text = "00:15"
	timerLabel.Parent = timerFrame
	
	print("[MutationTimerController] UI created")
end

function MutationTimerController:FormatTime(seconds: number): string
	if seconds < 0 then
		return "∞"
	end
	
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

function MutationTimerController:UpdateTimerState(remainingTime: number, isPermanent: boolean)
	if not timerLabel or not timerFrame then return end
	
	-- Update text
	if isPermanent then
		timerLabel.Text = "∞ PERMANENT"
		timerLabel.TextColor3 = COLOR_PERMANENT
		
		-- Pulse animation for permanent
		self:PlayPulseAnimation(timerFrame)
		
		-- Play permanent sound cue (placeholder)
		print("[MutationTimerController] Mutation permanent - sound cue triggered")
	elseif remainingTime <= 5 then
		-- Danger state: last 5 seconds
		timerLabel.Text = self:FormatTime(remainingTime)
		timerLabel.TextColor3 = COLOR_DANGER
		
		-- Red flashing animation
		self:PlayFlashAnimation(timerFrame, 0.3)
	else
		-- Normal countdown
		timerLabel.Text = self:FormatTime(remainingTime)
		timerLabel.TextColor3 = COLOR_NORMAL
	end
end

function MutationTimerController:PlayPulseAnimation(frame: Frame)
	-- Pulse animation for permanent mutations
	local tweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(
		0.6, -- Duration
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1, -- Repeat count (-1 = infinite)
		true, -- Reverse
		0 -- Delay
	)
	
	local tween = tweenService:Create(frame, tweenInfo, { BackgroundTransparency = 0.3 })
	tween:Play()
end

function MutationTimerController:PlayFlashAnimation(frame: Frame, interval: number)
	-- Red flashing for danger state
	local tweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(
		interval,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1, -- Repeat infinite
		true -- Reverse
	)
	
	local tween = tweenService:Create(frame, tweenInfo, { BorderColor3 = COLOR_DANGER })
	tween:Play()
end

function MutationTimerController:UpdateMutationTimer()
	-- Tick every 0.1 seconds to update remaining time
	local updateConnection
	updateConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		local currentTime = tick()
		local totalRemaining = 0
		local isPermanent = false
		
		-- Find the longest active mutation
		for mutationId, mutation in pairs(activeMutations) do
			if mutation.isPermanent then
				isPermanent = true
				totalRemaining = -1
				break
			else
				local remaining = (mutation.startTime + mutation.duration) - currentTime
				if remaining > 0 then
					totalRemaining = math.max(totalRemaining, remaining)
				end
			end
		end
		
		-- Update display
		self:UpdateTimerState(totalRemaining, isPermanent)
		
		-- Stop when no active mutations
		if totalRemaining <= 0 and not isPermanent then
			updateConnection:Disconnect()
		end
	end)
end

function MutationTimerController:HandleMutationApplied(payload: any)
	if not payload or not payload.mutationId then return end
	
	print("[MutationTimerController] Mutation applied:", payload.mutationId, "Duration:", payload.duration)
	
	-- Register mutation
	activeMutations[payload.mutationId] = {
		id = payload.mutationId,
		duration = payload.duration,
		startTime = tick(),
		isPermanent = (payload.duration == -1),
	}
	
	-- Start timer update loop
	self:UpdateMutationTimer()
	
	-- Schedule cleanup
	if payload.duration > 0 then
		task.delay(payload.duration, function()
			activeMutations[payload.mutationId] = nil
			print("[MutationTimerController] Mutation expired:", payload.mutationId)
		end)
	end
end

function MutationTimerController:KnitInit()
	self:CreateUI()
end

function MutationTimerController:KnitStart()
	RemoteEvents.GetEvents()
	
	-- Listen for mutation applications
	if RemoteEvents.MutationApplied then
		RemoteEvents.MutationApplied.OnClientEvent:Connect(function(payload: any)
			self:HandleMutationApplied(payload)
		end)
	end
	
	print("[MutationTimerController] Started")
end

return MutationTimerController

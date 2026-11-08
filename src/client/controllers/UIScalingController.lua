--!strict
-- UIScalingController: Dynamic viewport-based UI scaling for mobile/desktop
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"))

local UIScalingController = Knit.CreateController {
	Name = "UIScalingController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Target UI containers
local TARGET_UIS = {"StoreUI", "DailyRewardsUI"}

-- Base reference resolution (iPhone XR)
local BASE_WIDTH = 414
local BASE_HEIGHT = 896

function UIScalingController:ScaleUI(uiObject: ScreenGui)
	if not uiObject then return end
	
	local container = uiObject:FindFirstChild("Container", true)
	if not container then 
		warn("[UIScalingController] No Container found in", uiObject.Name)
		return 
	end
	
	-- Get current viewport size
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	
	-- Calculate scale factors
	local widthScale = viewportSize.X / BASE_WIDTH
	local heightScale = viewportSize.Y / BASE_HEIGHT
	
	-- Use the smaller scale to ensure UI fits within viewport
	local scale = math.min(widthScale, heightScale)
	
	-- Clamp scale between 0.6 and 1.2 for extreme resolutions
	scale = math.clamp(scale, 0.6, 1.2)
	
	-- Apply UIScale if not exists
	local uiScale = container:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = container
	end
	uiScale.Scale = scale
	
	-- Center container using AnchorPoint
	if container:IsA("Frame") then
		container.AnchorPoint = Vector2.new(0.5, 0.5)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	
	print("[UIScalingController] Scaled", uiObject.Name, "to", scale)
end

function UIScalingController:SetupScaling()
	-- Wait for UIs to replicate
	task.wait(2)
	
	for _, uiName in ipairs(TARGET_UIS) do
		local success = pcall(function()
			local ui = playerGui:WaitForChild(uiName, 10)
			if ui then
				self:ScaleUI(ui)
			end
		end)
		
		if not success then
			warn("[UIScalingController] Failed to scale", uiName)
		end
	end
	
	-- Re-scale on viewport size change
	local camera = workspace.CurrentCamera
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		for _, uiName in ipairs(TARGET_UIS) do
			local ui = playerGui:FindFirstChild(uiName)
			if ui then
				self:ScaleUI(ui)
			end
		end
	end)
end

function UIScalingController:KnitInit()
	print("[UIScalingController] Initializing...")
	self:SetupScaling()
end

return UIScalingController

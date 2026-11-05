--!strict
-- Client entry point - Manual controller initialization (Knit not installed)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load RemoteEvents
local RemoteEventsModule = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)
RemoteEvents.GetEvents()
print("[Client] RemoteEvents loaded")

-- Manual controller loading (Knit.CreateController replaced)
local controllers = {}

local srcFolder = playerScripts:FindFirstChild("src")
if srcFolder then
	local client = srcFolder:FindFirstChild("client")
	if client then
		local controllerFolder = client:FindFirstChild("controllers")
		if controllerFolder then
			for _, controller in ipairs(controllerFolder:GetChildren()) do
				if controller:IsA("ModuleScript") then
					local success, result = pcall(require, controller)
					if success then
						print("[Client] Loaded controller:", controller.Name)
						controllers[controller.Name] = result
						-- Call KnitInit if exists
						if result.KnitInit then
							result:KnitInit()
						end
					else
						warn("[Client] Failed to load controller:", controller.Name, result)
					end
				end
			end
		end
	end
end

-- Start all controllers (KnitStart equivalent)
for name, controller in pairs(controllers) do
	if controller.KnitStart then
		controller:KnitStart()
		print("[Client] Started controller:", name)
	end
end

print("[Client] Initialized (manual controller loading)")
--!strict
-- Client entry point - Knit initialization

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load RemoteEvents
local RemoteEventsModule = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)
RemoteEvents.GetEvents()
print("[Client] RemoteEvents loaded")

-- TODO: Install Knit via Wally/Roblox package manager
-- For now, manually require controllers

local srcFolder = playerScripts:FindFirstChild("src")
if srcFolder then
	local client = srcFolder:FindFirstChild("client")
	if client then
		local controllers = client:FindFirstChild("controllers")
		if controllers then
			for _, controller in ipairs(controllers:GetChildren()) do
				if controller:IsA("ModuleScript") then
					local success, result = pcall(require, controller)
					if success then
						print("[Client] Loaded controller:", controller.Name)
						-- Auto-start each controller
						if result.KnitStart then
							result:KnitStart()
						end
					else
						warn("[Client] Failed to load controller:", controller.Name, result)
					end
				end
			end
		end
	end
end

print("[Client] Initialized (Knit framework pending installation)")

-- TODO: Replace with Knit.Start() after Wally install
-- Knit.AddControllers(script.Parent.controllers)
-- Knit.Start():andThen(function()
-- 	print("[Client] Knit started")
-- end):catch(warn)
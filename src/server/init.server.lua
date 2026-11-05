-- Server entry point - Knit initialization

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load RemoteEvents and create them first
local RemoteEventsModule = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)
RemoteEvents.CreateEvents()
print("[Server] RemoteEvents created")

-- TODO: Install Knit via Wally/Roblox package manager
-- For now, manually require services

local ArenaService = nil

local serverFolder = ServerScriptService:FindFirstChild("src")
if serverFolder then
	local server = serverFolder:FindFirstChild("server")
	if server then
		local services = server:FindFirstChild("services")
		if services then
			for _, service in ipairs(services:GetChildren()) do
				if service:IsA("ModuleScript") then
					local success, result = pcall(require, service)
					if success then
						print("[Server] Loaded service:", service.Name)
						if service.Name == "ArenaService" then
							ArenaService = result
						end
					else
						warn("[Server] Failed to load service:", service.Name, result)
					end
				end
			end
		end
	end
end

-- Auto-start match when first player joins (test mode)
local matchStarted = false
Players.PlayerAdded:Connect(function(player)
	if not matchStarted and ArenaService then
		task.wait(3) -- Give player time to load
		matchStarted = true
		ArenaService:StartMatch()
		print("[Server] Auto-started match for testing")
	end
end)

print("[Server] Initialized (Knit framework pending installation)")
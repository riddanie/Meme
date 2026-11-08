-- Server entry point - Manual service initialization (Knit not installed)

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load RemoteEvents and create them first
local RemoteEventsModule = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)
RemoteEvents.CreateEvents()
print("[Server] RemoteEvents created")

-- Manual service loading (Knit.CreateService replaced)
local services = {}

local serverFolder = ServerScriptService:FindFirstChild("src")
if serverFolder then
	local server = serverFolder:FindFirstChild("server")
	if server then
		local serviceFolder = server:FindFirstChild("services")
		if serviceFolder then
			for _, service in ipairs(serviceFolder:GetChildren()) do
				if service:IsA("ModuleScript") then
					local success, result = pcall(require, service)
					if success then
						print("[Server] Loaded service:", service.Name)
						services[service.Name] = result
					else
						warn("[Server] Failed to load service:", service.Name, result)
					end
				end
			end
		end
	end
end

-- Auto-start ArenaService on first player join
local ArenaService = services["ArenaService"]
local HazardService = services["HazardService"]

-- Initialize death listeners
if HazardService and HazardService.Init then
	HazardService:Init()
	print("[Server] HazardService death listeners initialized")
end

-- Start respawn loop
if HazardService and HazardService.StartRespawnLoop then
	HazardService:StartRespawnLoop()
	print("[Server] HazardService respawn loop started")
end

Players.PlayerAdded:Connect(function(player)
	if ArenaService and ArenaService.StartMatch then
		ArenaService:StartMatch()
		print("[Server] Match started for player:", player.Name)
	end
end)

print("[Server] Initialized (manual service loading)")
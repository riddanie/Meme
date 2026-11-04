--!strict
-- Server entry point - Knit initialization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for Knit package (must be installed via Wally or manually)
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Add services
Knit.AddServices(ServerScriptService.Server.Services)

-- Start Knit
Knit.Start():andThen(function()
	print("[Server] Knit started successfully")
	
	-- Start first arena match after 5s grace period
	task.wait(5)
	local ArenaService = Knit.GetService("ArenaService")
	ArenaService:StartMatch()
	
end):catch(warn)

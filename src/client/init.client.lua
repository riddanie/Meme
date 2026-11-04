--!strict
-- Client entry point - Knit initialization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Add controllers
Knit.AddControllers(ReplicatedStorage.Client.Controllers)

-- Start Knit
Knit.Start():andThen(function()
	print("[Client] Knit started successfully")
end):catch(warn)

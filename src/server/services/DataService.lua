--!strict
-- Knit Service: Player data management via ProfileService

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local ProfileManager = require(script.Parent.Parent.Modules.ProfileService)

local DataService = Knit.CreateService {
	Name = "DataService",
	Client = {},
}

function DataService:KnitStart()
	local Players = game:GetService("Players")
	
	-- Load profiles on join
	Players.PlayerAdded:Connect(function(player)
		local profile = ProfileManager.LoadProfile(player)
		if profile then
			print("[DataService] Profile loaded for", player.Name)
		end
	end)
	
	-- Unload profiles on leave
	Players.PlayerRemoving:Connect(function(player)
		ProfileManager.UnloadProfile(player)
		print("[DataService] Profile unloaded for", player.Name)
	end)
end

function DataService:GetProfile(player: Player)
	return ProfileManager.GetProfile(player)
end

function DataService:AddDNA(player: Player, amount: number)
	local profile = ProfileManager.GetProfile(player)
	if profile then
		profile.Data.MutagenDNA += amount
		return true
	end
	return false
end

function DataService:IncrementPityCounter(player: Player)
	local profile = ProfileManager.GetProfile(player)
	if profile then
		profile.Data.PityCounter += 1
		return profile.Data.PityCounter
	end
	return 0
end

function DataService:ResetPityCounter(player: Player)
	local profile = ProfileManager.GetProfile(player)
	if profile then
		profile.Data.PityCounter = 0
	end
end

return DataService

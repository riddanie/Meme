--!strict
-- DataService.lua - Player data management via ProfileService
-- Standalone version (no Knit dependency)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Find ProfileService module
local ProfileServicePath = ServerScriptService:FindFirstChild("src")
local ProfileManager = nil

if ProfileServicePath then
	ProfileServicePath = ProfileServicePath:FindFirstChild("server")
	if ProfileServicePath then
		ProfileServicePath = ProfileServicePath:FindFirstChild("modules")
		if ProfileServicePath then
			ProfileServicePath = ProfileServicePath:FindFirstChild("ProfileService")
			if ProfileServicePath then
				ProfileManager = require(ProfileServicePath)
			end
		end
	end
end

local DataService = {}
DataService.__index = DataService

local _playerProfiles = {} -- [player] = profileData

-- Load player profile
function DataService:GetPlayerData(player: Player)
	return _playerProfiles[player]
end

-- Save player profile
function DataService:SavePlayerData(player: Player, data: any)
	_playerProfiles[player] = data
	print("[DataService] Saved data for", player.Name)
	
	-- Directive 2: Fire UpdateHUD to client
	local RemoteEvents = game.ReplicatedStorage:FindFirstChild("src")
	if RemoteEvents then
		RemoteEvents = RemoteEvents:FindFirstChild("shared")
		if RemoteEvents then
			RemoteEvents = RemoteEvents:FindFirstChild("RemoteEvents")
			if RemoteEvents then
				RemoteEvents = require(RemoteEvents)
				local updateHUD = RemoteEvents.GetEvents and RemoteEvents.GetEvents().UpdateHUD
				if updateHUD then
					local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
					local health = humanoid and (humanoid.Health / humanoid.MaxHealth * 100) or 100
					local playerCount = #Players:GetPlayers()
					
					updateHUD:FireClient(player, {
						dna = data.Data.MutagenDNA or 0,
						health = math.floor(health),
						playerCount = playerCount
					})
				end
			end
		end
	end
end

-- Initialize
function DataService:Init()
	if not ProfileManager then
		warn("[DataService] ProfileService module not found - using mock data")
		return
	end

	-- Load profiles on join
	Players.PlayerAdded:Connect(function(player)
		local profile = ProfileManager.LoadProfile(player)
		if profile then
			_playerProfiles[player] = profile
			print("[DataService] Profile loaded for", player.Name)
		end
	end)

	-- Save profiles on leave
	Players.PlayerRemoving:Connect(function(player)
		if _playerProfiles[player] then
			print("[DataService] Profile saved for", player.Name)
			_playerProfiles[player] = nil
		end
	end)

	print("[DataService] Initialized")
end

DataService:Init()

return DataService
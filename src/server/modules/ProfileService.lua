--!strict
-- ProfileService wrapper with schema definition
-- Install ProfileService from: https://madstudiorblx.github.io/ProfileService/

local ProfileService = require(game.ServerScriptService.ProfileService)
local PlayerDataTypes = require(game.ReplicatedStorage.Shared.Types.PlayerData)

type PlayerData = PlayerDataTypes.PlayerData

local ProfileTemplate: PlayerData = {
	MutagenDNA = 0,
	UnlockedMutations = {},
	MasteryLevels = {},
	PityCounter = 0,
	OwnedCosmetics = {},
	GamepassFlags = {
		StarterPack = false,
		ChaosMaster = false,
		RoyalePass = false,
	},
	TotalSpins = 0,
	TotalDeaths = 0,
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	ProfileTemplate
)

local Profiles = {}

local ProfileManager = {}

function ProfileManager.LoadProfile(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Profile released")
		end)
		
		if player:IsDescendantOf(game.Players) then
			Profiles[player] = profile
			return profile
		else
			profile:Release()
		end
	else
		player:Kick("Failed to load profile")
	end
	
	return nil
end

function ProfileManager.GetProfile(player: Player)
	return Profiles[player]
end

function ProfileManager.UnloadProfile(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
		Profiles[player] = nil
	end
end

return ProfileManager

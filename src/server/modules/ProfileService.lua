--!strict
-- ProfileService wrapper with schema definition
-- Install ProfileService from: https://madstudiorblx.github.io/ProfileService/

-- ProfileService library must be installed in ServerScriptService
-- Get from: https://madstudiorblx.github.io/ProfileService/
local ProfileService = game.ServerScriptService:FindFirstChild("ProfileService")
if ProfileService then
	ProfileService = require(ProfileService)
end

-- Define player data schema locally
local PlayerDataTemplate = {
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

local ProfileTemplate = {
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
	if not ProfileService then
		warn("[ProfileService] ProfileService library not installed - using mock profile")
		-- Return mock profile with default template
		local mockProfile = {
			Data = PlayerDataTemplate,
		}
		Profiles[player] = mockProfile
		return mockProfile
	end
	
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

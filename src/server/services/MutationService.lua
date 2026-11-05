--!strict
-- Knit Service: Server-authoritative mutation RNG and distribution
-- Implements weighted RNG + pity system (20 spins → guaranteed Legendary/Secret)

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local DataService = require(game.ReplicatedStorage.Packages.Knit.Services.DataService)
local RemoteEvents = require(game.ReplicatedStorage.Shared.RemoteEvents)
local MutationDatabase = require(game.ReplicatedStorage.Shared.Data.MutationDatabase)

local MutationService = Knit.CreateService {
	Name = "MutationService",
	Client = {
		MutationApplied = {},
	},
	_activeMutations = {}, -- [player] = { mutationId, rarity, duration } (session cache)
}

function MutationService:KnitStart()
	RemoteEvents.CreateEvents()
	print("[MutationService] Started")
end

-- Generate mutation with weighted RNG + pity system
function MutationService:GenerateMutation(player: Player): { mutationId: string, rarity: string, duration: number }
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		print("[MutationService] No player data for", player.Name)
		return { mutationId = "BRAINROT", rarity = "Common", duration = 15 }
	end

	-- Pity counter: 20 spins without Legendary/Secret guarantees Legendary
	local pity = playerData.PityCounter or 0
	local mutation = MutationDatabase.GetRandomMutation(pity)

	-- Update pity counter
	pity = pity + 1
	if mutation.rarity == "Legendary" or mutation.rarity == "Secret" then
		pity = 0
	end
	playerData.PityCounter = pity
	DataService:SavePlayerData(player, playerData)

	-- Cache in session
	self._activeMutations[player] = {
		mutationId = mutation.id,
		rarity = mutation.rarity,
		duration = mutation.duration,
	}

	-- Broadcast to all clients
	if RemoteEvents.MutationApplied then
		RemoteEvents.MutationApplied:FireAllClients({
			playerId = player.UserId,
			mutationId = mutation.id,
			rarity = mutation.rarity,
			duration = mutation.duration,
		})
	end

	-- Broadcast to all clients (with player name for display)
	if RemoteEvents.MutationBroadcast then
		RemoteEvents.MutationBroadcast:FireAllClients({
			playerId = player.UserId,
			playerName = player.Name,
			mutation = mutation.id,
			rarity = mutation.rarity,
		})
	end

	return {
		mutationId = mutation.id,
		rarity = mutation.rarity,
		duration = mutation.duration,
	}
end

-- Get active mutation for player
function MutationService:GetActiveMutation(player: Player): { mutationId: string, rarity: string, duration: number }?
	return self._activeMutations[player]
end

-- Clear mutation on player leave
function MutationService:ClearMutation(player: Player)
	self._activeMutations[player] = nil
end

-- Client request to mutate
function MutationService:ClientRequestMutation(player: Player)
	-- Server-authoritative, always allow (could add cooldown logic)
	return self:GenerateMutation(player)
end

return MutationService
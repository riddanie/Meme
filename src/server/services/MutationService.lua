--!strict
-- Knit Service: Server-authoritative mutation RNG and distribution

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)
local RemoteEvents = require(game.ReplicatedStorage.Shared.RemoteEvents)

local MutationService = Knit.CreateService {
	Name = "MutationService",
	Client = {},
	_activeMutations = {}, -- [player] = current mutation ID (session cache)
}

function MutationService:KnitStart()
	RemoteEvents.CreateEvents()
	print("[MutationService] Started - RemoteEvents created")
end

function MutationService:GenerateMutation(player: Player): string
	-- Server-authoritative RNG
	-- TODO: Implement pity system logic with DataService
	-- Stub: Return random mutation ID
	local mutationID = "MUTATION_" .. math.random(1, 10)
	
	self._activeMutations[player] = mutationID
	
	-- Broadcast to all clients
	if RemoteEvents.MutationApplied then
		RemoteEvents.MutationApplied:FireAllClients(player, mutationID)
	end
	
	return mutationID
end

function MutationService:GetActiveMutation(player: Player): string?
	return self._activeMutations[player]
end

function MutationService:ClearMutation(player: Player)
	self._activeMutations[player] = nil
end

return MutationService

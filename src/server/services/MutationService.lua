--!strict
-- MutationService.lua - Server-authoritative mutation RNG
-- Standalone version (no Knit dependency)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationService = {}
MutationService.__index = MutationService

MutationService._activeMutations = {} -- [player] = { mutationId, rarity, duration }

-- Find shared modules
local function getSharedFolder()
	local src = ReplicatedStorage:FindFirstChild("src")
	if src then
		return src:FindFirstChild("shared")
	end
	return nil
end

local MutationDatabase = nil
local sharedFolder = getSharedFolder()

if sharedFolder then
	local dataFolder = sharedFolder:FindFirstChild("data")
	if dataFolder then
		local mutationDb = dataFolder:FindFirstChild("MutationDatabase")
		if mutationDb then
			MutationDatabase = require(mutationDb)
		end
	end
end

-- Generate mutation with weighted RNG
function MutationService:GenerateMutation(player: Player, pityCounter: number)
	if not MutationDatabase then
		warn("[MutationService] MutationDatabase not found")
		return {
			mutationId = "BRAINROT",
			rarity = "Common",
			duration = 15,
		}
	end

	local mutation = MutationDatabase.GetRandomMutation(pityCounter or 0)

	-- Cache in session
	self._activeMutations[player] = {
		mutationId = mutation.id,
		rarity = mutation.rarity,
		duration = mutation.duration,
	}

	print("[MutationService] Generated mutation for", player.Name, "-", mutation.id, "(", mutation.rarity, ")")

	-- Apply ragdoll to player
	local RagdollService = nil
	local src = game.ServerScriptService:FindFirstChild("src")
	if src then
		local server = src:FindFirstChild("server")
		if server then
			local services = server:FindFirstChild("services")
			if services then
				local rs = services:FindFirstChild("RagdollService")
				if rs then
					RagdollService = require(rs)
				end
			end
		end
	end

	if RagdollService then
		RagdollService:ApplyMutation(player, mutation.id)
	end

	return {
		mutationId = mutation.id,
		rarity = mutation.rarity,
		duration = mutation.duration,
	}
end

-- Get active mutation for player
function MutationService:GetActiveMutation(player: Player)
	return self._activeMutations[player]
end

-- Clear mutation
function MutationService:ClearMutation(player: Player)
	self._activeMutations[player] = nil
end

print("[MutationService] Module loaded")

return MutationService
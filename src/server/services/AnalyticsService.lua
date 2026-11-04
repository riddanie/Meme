--!strict
-- Knit Service: GameAnalytics SDK integration scaffolding

local Knit = require(game.ReplicatedStorage.Packages.Knit)

local AnalyticsService = Knit.CreateService {
	Name = "AnalyticsService",
	Client = {},
}

function AnalyticsService:KnitStart()
	-- TODO: Install GameAnalytics SDK from Roblox marketplace
	-- https://gameanalytics.com/docs/item/roblox-sdk
	print("[AnalyticsService] Scaffolding ready - SDK not installed yet")
end

function AnalyticsService:TrackEvent(category: string, action: string, label: string?, value: number?)
	-- Stub: Log events until GameAnalytics SDK is integrated
	print(string.format("[Analytics] %s | %s | %s | %d", category, action, label or "N/A", value or 0))
	
	-- TODO: Replace with GameAnalytics:addDesignEvent() when SDK installed
end

function AnalyticsService:TrackPlayerDeath(player: Player, mutationID: string)
	self:TrackEvent("Combat", "PlayerDeath", mutationID)
end

function AnalyticsService:TrackMutationSpin(player: Player, mutationID: string, pityCounter: number)
	self:TrackEvent("Progression", "MutationSpin", mutationID, pityCounter)
end

return AnalyticsService

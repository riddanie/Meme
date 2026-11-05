--!strict
-- AnalyticsService.lua - GameAnalytics scaffold
-- Standalone version (no Knit dependency)

local AnalyticsService = {}
AnalyticsService.__index = AnalyticsService

function AnalyticsService:TrackEvent(eventName: string, eventData: { [string]: any })
	print("[AnalyticsService] Event:", eventName, "Data:", eventData)
end

function AnalyticsService:TrackPlayerJoin(player: any)
	self:TrackEvent("PlayerJoin", { playerId = player.UserId })
end

function AnalyticsService:TrackPlayerLeave(player: any)
	self:TrackEvent("PlayerLeave", { playerId = player.UserId })
end

print("[AnalyticsService] Module loaded")

return AnalyticsService
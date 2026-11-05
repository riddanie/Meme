--!strict
-- LightOptimizationService.lua
-- Manages light rendering budget: Only creates lights for local + nearby players

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LightOptimizationService = {}
LightOptimizationService.__index = LightOptimizationService

LightOptimizationService._activeLights = {} -- [playerId] = { mutationId, light }
LightOptimizationService._lightRadius = 25 -- Studs
LightOptimizationService._maxLights = 16 -- Local + nearby players
LightOptimizationService._updateInterval = 0.5 -- Check every 0.5s

function LightOptimizationService:Init()
	print("[LightOptimizationService] Initializing")
	
	-- Start light budget manager
	task.spawn(function()
		while true do
			task.wait(self._updateInterval)
			self:UpdateLightBudget()
		end
	end)
	
	print("[LightOptimizationService] Initialized")
end

function LightOptimizationService:GetNearbyPlayers(center: Vector3, radius: number): { Player }
	local nearby = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local dist = (character.HumanoidRootPart.Position - center).Magnitude
			if dist <= radius then
				table.insert(nearby, player)
			end
		end
	end
	
	-- Sort by distance and return top N
	table.sort(nearby, function(a, b)
		local distA = (a.Character.HumanoidRootPart.Position - center).Magnitude
		local distB = (b.Character.HumanoidRootPart.Position - center).Magnitude
		return distA < distB
	end)
	
	return nearby
end

function LightOptimizationService:UpdateLightBudget()
	local localPlayer = Players.LocalPlayer
	if not localPlayer or not localPlayer.Character then return end
	
	local localHRP = localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not localHRP then return end
	
	-- Get nearby players within light radius
	local nearbyPlayers = self:GetNearbyPlayers(localHRP.Position, self._lightRadius)
	
	-- Cap to max lights
	if #nearbyPlayers > self._maxLights then
		nearbyPlayers = { table.unpack(nearbyPlayers, 1, self._maxLights) }
	end
	
	-- Remove lights for players no longer nearby
	for playerId, lightData in pairs(self._activeLights) do
		local found = false
		for _, player in ipairs(nearbyPlayers) do
			if player.UserId == playerId then
				found = true
				break
			end
		end
		
		if not found then
			if lightData.light then
				lightData.light:Destroy()
			end
			self._activeLights[playerId] = nil
			print("[LightOptimizationService] Light removed (out of range):", playerId)
		end
	end
	
	-- Add lights for new nearby players
	for _, player in ipairs(nearbyPlayers) do
		if not self._activeLights[player.UserId] then
			self:CreatePlayerLight(player)
		end
	end
end

function LightOptimizationService:CreatePlayerLight(player: Player)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Create light above player
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 20
	light.Parent = hrp
	
	self._activeLights[player.UserId] = {
		player = player,
		light = light,
	}
	
	print("[LightOptimizationService] Light created for", player.Name, "(UserId:", player.UserId, ")")
end

function LightOptimizationService:RemovePlayerLight(playerId: number)
	local lightData = self._activeLights[playerId]
	if lightData and lightData.light then
		lightData.light:Destroy()
	end
	self._activeLights[playerId] = nil
end

LightOptimizationService:Init()

return LightOptimizationService

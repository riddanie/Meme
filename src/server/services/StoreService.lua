--!strict
-- StoreService.lua: Handles store purchases and cosmetic equipment server-side

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local StoreService = {}
StoreService.__index = StoreService

function StoreService:Init()
	print("[StoreService] Initializing...")
	
	-- Load RemoteEvents
	local shared = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
	local RemoteEvents = require(shared:WaitForChild("RemoteEvents"))
	
	-- Handle EquipCosmetic / Purchase
	if RemoteEvents.EquipCosmetic then
		RemoteEvents.EquipCosmetic.OnServerEvent:Connect(function(player, data)
			self:HandlePurchaseOrEquip(player, data)
		end)
	end
	
	-- Sync balance to client periodically or on request
	Players.PlayerAdded:Connect(function(player)
		task.wait(2)
		self:SyncBalance(player)
	end)
	
	print("[StoreService] Initialized")
end

function StoreService:SyncBalance(player: Player)
	local ds = script.Parent:FindFirstChild("DataService")
	if ds then
		local DataService = require(ds)
		local profile = DataService:GetPlayerData(player)
		if profile and profile.Data then
			local balance = profile.Data.MutagenDNA or 0
			
			local shared = ReplicatedStorage:FindFirstChild("src"):WaitForChild("shared")
			local RemoteEvents = require(shared:WaitForChild("RemoteEvents"))
			if RemoteEvents.UpdateBalance then
				RemoteEvents.UpdateBalance:FireClient(player, balance)
			end
		end
	end
end

function StoreService:HandlePurchaseOrEquip(player: Player, data: any)
	if not data or not data.cosmeticId then return end
	
	print("[StoreService] Processing purchase for", player.Name, "Item:", data.cosmeticId)
	
	local ds = script.Parent:FindFirstChild("DataService")
	if ds then
		local DataService = require(ds)
		local profile = DataService:GetPlayerData(player)
		if profile and profile.Data then
			-- Mock cosmetic cost (e.g. 100 DNA)
			local cost = 100
			local currentDNA = profile.Data.MutagenDNA or 0
			
			if currentDNA >= cost then
				profile.Data.MutagenDNA = currentDNA - cost
				DataService:SavePlayerData(player, profile)
				print("[StoreService] Purchase successful! New balance:", profile.Data.MutagenDNA)
				
				-- Resync balance
				self:SyncBalance(player)
			else
				warn("[StoreService] Insufficient DNA for", player.Name)
			end
		end
	end
end

StoreService:Init()

return StoreService

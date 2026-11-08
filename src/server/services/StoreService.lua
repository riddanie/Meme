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
	
	-- Handle RequestBalance
	if RemoteEvents.RequestBalance then
		RemoteEvents.RequestBalance.OnServerEvent:Connect(function(player)
			self:SyncBalance(player)
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
			local ownedCosmetics = profile.Data.OwnedCosmetics or {}
			local equippedCosmetic = profile.Data.EquippedCosmetic or "None"
			
			local shared = ReplicatedStorage:FindFirstChild("src"):WaitForChild("shared")
			local RemoteEvents = require(shared:WaitForChild("RemoteEvents"))
			if RemoteEvents.UpdateBalance then
				RemoteEvents.UpdateBalance:FireClient(player, {
					balance = balance,
					ownedCosmetics = ownedCosmetics,
					equippedCosmetic = equippedCosmetic
				})
			end
		end
	end
end

function StoreService:HandlePurchaseOrEquip(player: Player, data: any)
	if not data or not data.cosmeticId then 
		warn("[StoreService] Invalid request: missing cosmeticId")
		return 
	end
	
	-- Validate cosmeticId type
	if type(data.cosmeticId) ~= "string" then
		warn("[StoreService] Invalid cosmeticId type for", player.Name, "- expected string, got", type(data.cosmeticId))
		return
	end
	
	-- Load CosmeticDatabase for validation
	local shared = ReplicatedStorage:FindFirstChild("src"):WaitForChild("shared")
	local CosmeticDatabase = require(shared:WaitForChild("data"):WaitForChild("CosmeticDatabase"))
	
	-- Validate cosmetic exists
	local cosmetic = CosmeticDatabase.GetCosmetic(data.cosmeticId)
	if not cosmetic then
		warn("[StoreService] Invalid cosmetic ID:", data.cosmeticId)
		return
	end
	
	local ds = script.Parent:FindFirstChild("DataService")
	if not ds then return end
	
	local DataService = require(ds)
	local profile = DataService:GetPlayerData(player)
	if not profile or not profile.Data then return end
	
	-- Initialize owned cosmetics table
	if not profile.Data.OwnedCosmetics then
		profile.Data.OwnedCosmetics = {}
	end
	
	-- Check if already owned (prevent duplicate purchase)
	if profile.Data.OwnedCosmetics[data.cosmeticId] then
		print("[StoreService] Player already owns", data.cosmeticId, "- equipping instead")
		-- Just equip, don't charge
		profile.Data.EquippedCosmetic = data.cosmeticId
		DataService:SavePlayerData(player, profile)
		self:SyncBalance(player)
		return
	end
	
	-- Validate cost and DNA balance
	local cost = cosmetic.cost
	local currentDNA = profile.Data.MutagenDNA or 0
	
	if currentDNA < cost then
		warn("[StoreService] Insufficient DNA for", player.Name, "- need", cost, "have", currentDNA)
		return
	end
	
	-- Process purchase
	profile.Data.MutagenDNA = currentDNA - cost
	profile.Data.OwnedCosmetics[data.cosmeticId] = true
	profile.Data.EquippedCosmetic = data.cosmeticId
	
	DataService:SavePlayerData(player, profile)
	print("[StoreService] Purchase successful! Player:", player.Name, "Item:", data.cosmeticId, "New DNA:", profile.Data.MutagenDNA)
	
	-- Resync balance
	self:SyncBalance(player)
end

StoreService:Init()

return StoreService

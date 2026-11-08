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
	
	-- Handle DailyRewardsClaim
	if RemoteEvents.DailyRewardsClaim then
		RemoteEvents.DailyRewardsClaim.OnServerEvent:Connect(function(player)
			self:ClaimDailyReward(player)
		end)
	end
	
	-- Handle ShopPurchase
	if RemoteEvents.ShopPurchase then
		RemoteEvents.ShopPurchase.OnServerEvent:Connect(function(player, data)
			self:HandlePurchase(player, data)
		end)
	end
	
	-- Handle InventoryUpdate
	if RemoteEvents.InventoryUpdate then
		RemoteEvents.InventoryUpdate.OnServerEvent:Connect(function(player)
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

function StoreService:HandlePurchase(player: Player, data: any)
	if not data or not data.cosmeticId then 
		warn("[StoreService] Invalid purchase request: missing cosmeticId")
		return 
	end
	
	if type(data.cosmeticId) ~= "string" then
		warn("[StoreService] Invalid cosmeticId type for", player.Name)
		return
	end
	
	local shared = ReplicatedStorage:FindFirstChild("src"):WaitForChild("shared")
	local CosmeticDatabase = require(shared:WaitForChild("data"):WaitForChild("CosmeticDatabase"))
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
	
	if not profile.Data.OwnedCosmetics then
		profile.Data.OwnedCosmetics = {}
	end
	
	local cost = cosmetic.cost or cosmetic.price or 0
	local currentDNA = profile.Data.MutagenDNA or 0
	
	local RemoteEvents = require(shared:WaitForChild("RemoteEvents"))
	
	if profile.Data.OwnedCosmetics[data.cosmeticId] then
		print("[StoreService] Player already owns", data.cosmeticId)
		if RemoteEvents.ShopPurchaseResult then
			RemoteEvents.ShopPurchaseResult:FireClient(player, {
				success = false,
				reason = "Already owned",
				cosmeticId = data.cosmeticId
			})
		end
		return
	end
	
	if currentDNA < cost then
		warn("[StoreService] Insufficient DNA for", player.Name)
		if RemoteEvents.ShopPurchaseResult then
			RemoteEvents.ShopPurchaseResult:FireClient(player, {
				success = false,
				reason = "Insufficient DNA",
				cosmeticId = data.cosmeticId
			})
		end
		return
	end
	
	-- Process purchase
	profile.Data.MutagenDNA = currentDNA - cost
	profile.Data.OwnedCosmetics[data.cosmeticId] = true
	profile.Data.EquippedCosmetic = data.cosmeticId
	
	DataService:SavePlayerData(player, profile)
	print("[StoreService] Purchase successful!", player.Name, data.cosmeticId)
	
	if RemoteEvents.ShopPurchaseResult then
		RemoteEvents.ShopPurchaseResult:FireClient(player, {
			success = true,
			cosmeticId = data.cosmeticId,
			newBalance = profile.Data.MutagenDNA
		})
	end
	
	self:SyncBalance(player)
end

function StoreService:ClaimDailyReward(player: Player)
	local ds = script.Parent:FindFirstChild("DataService")
	if not ds then return end
	local DataService = require(ds)
	local profile = DataService:GetPlayerData(player)
	if not profile or not profile.Data then return end
	
	local lastClaim = profile.Data.LastDailyClaim or 0
	local now = os.time()
	local cooldown = 86400 -- 24 hours
	
	local shared = ReplicatedStorage:FindFirstChild("src"):WaitForChild("shared")
	local RemoteEvents = require(shared:WaitForChild("RemoteEvents"))
	
	if now - lastClaim < cooldown then
		print("[StoreService] Daily reward already claimed or on cooldown for", player.Name)
		if RemoteEvents.DailyRewardsSync then
			RemoteEvents.DailyRewardsSync:FireClient(player, {
				success = false,
				reason = "Cooldown active",
				nextClaimIn = cooldown - (now - lastClaim)
			})
		end
		return
	end
	
	if not profile.Data.ClaimedDays then
		profile.Data.ClaimedDays = {}
	end
	
	local streak = #profile.Data.ClaimedDays + 1
	table.insert(profile.Data.ClaimedDays, now)
	profile.Data.LastDailyClaim = now
	
	-- Grant DNA reward (base 100 * streak)
	local dnaReward = 100 * streak
	profile.Data.MutagenDNA = (profile.Data.MutagenDNA or 0) + dnaReward
	
	DataService:SavePlayerData(player, profile)
	print("[StoreService] Daily reward claimed by", player.Name, "Streak:", streak, "DNA:", dnaReward)
	
	if RemoteEvents.DailyRewardsSync then
		RemoteEvents.DailyRewardsSync:FireClient(player, {
			success = true,
			streak = streak,
			rewardDNA = dnaReward,
			newBalance = profile.Data.MutagenDNA,
			claimedDays = profile.Data.ClaimedDays
		})
	end
	
	self:SyncBalance(player)
end

StoreService:Init()

return StoreService

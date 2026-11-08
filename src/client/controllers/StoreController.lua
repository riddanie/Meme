--!strict
-- StoreController.lua: Handles Store UI interactions
--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit
local kn = ReplicatedStorage:FindFirstChild("Packages")
if kn then
	local k = kn:FindFirstChild("Knit")
	if k then
		Knit = require(k)
	end
end

if not Knit then
	Knit = {
		CreateController = function(self, tbl)
			return tbl
		end
	}
end

local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))

local StoreController = Knit.CreateController {
	Name = "StoreController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local storeUI: ScreenGui? = nil
local container: Frame? = nil
local balanceLabel: TextLabel? = nil
local itemsFrame: Frame? = nil
local openButton: TextButton? = nil

function StoreController:CreateUI()
	local screenGui = playerGui:FindFirstChild("ArenaHUD")
	if not screenGui then
		warn("[StoreController] ArenaHUD not found")
		return
	end

	-- Open button in ArenaHUD
	openButton = screenGui:FindFirstChild("StoreButton")
	if openButton then
		openButton.MouseButton1Click:Connect(function()
			self:ShowStore()
		end)
	end

	-- Store UI (from StarterGui)
	storeUI = playerGui:FindFirstChild("StoreUI")
	if storeUI then
		storeUI.Enabled = false
		container = storeUI:FindFirstChild("Container")
		balanceLabel = storeUI:FindFirstChild("BalanceLabel")
		itemsFrame = storeUI:FindFirstChild("ItemsFrame")
		
		-- Bind close button
		local header = storeUI:FindFirstChild("Header")
		if header then
			local closeBtn = header:FindFirstChild("CloseButton")
			if closeBtn then
				closeBtn.MouseButton1Click:Connect(function()
					self:HideStore()
				end)
			end
		end
	end
end

function StoreController:BindEvents()
	-- ShopPurchaseResult
	if RemoteEvents.ShopPurchaseResult then
		RemoteEvents.ShopPurchaseResult.OnClientEvent:Connect(function(payload)
			if payload.success then
				print("[StoreController] Purchase successful:", payload.cosmeticId)
				if balanceLabel then
					balanceLabel.Text = "DNA: " .. tostring(payload.newBalance)
				end
			else
				warn("[StoreController] Purchase failed:", payload.reason)
			end
		end)
	end

	-- UpdateBalance
	if RemoteEvents.UpdateBalance then
		RemoteEvents.UpdateBalance.OnClientEvent:Connect(function(payload)
			if balanceLabel then
				balanceLabel.Text = "DNA: " .. tostring(payload.balance)
			end
			-- TODO: Populate itemsFrame with owned/cost data
		end)
	end
end

function StoreController:ShowStore()
	if storeUI then
		storeUI.Enabled = true
		-- Trigger balance sync on open
		if RemoteEvents.RequestBalance then
			RemoteEvents.RequestBalance:FireServer()
		end
	else
		warn("[StoreController] StoreUI not found")
	end
end

function StoreController:HideStore()
	if storeUI then
		storeUI.Enabled = false
	end
end

function StoreController:PurchaseCosmetic(cosmeticId: string)
	if not RemoteEvents.ShopPurchase then
		warn("[StoreController] ShopPurchase remote not available")
		return
	end
	RemoteEvents.ShopPurchase:FireServer({
		cosmeticId = cosmeticId
	})
end

function StoreController:KnitInit()
	self:CreateUI()
end

function StoreController:KnitStart()
	self:BindEvents()
end

return StoreController

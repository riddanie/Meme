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
local CosmeticDatabase = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("data"):WaitForChild("CosmeticDatabase"))

local StoreController = Knit.CreateController {
	Name = "StoreController",
}

-- Helper: Brighten color
local function brighten(color: Color3, amount: number): Color3
	local h, s, v = color:ToHSV()
	v = math.clamp(v + amount, 0, 1)
	return Color3.fromHSV(h, s, v)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local storeUI: ScreenGui? = nil
local container: Frame? = nil
local balanceLabel: TextLabel? = nil
local itemsFrame: Frame? = nil
local openButton: TextButton? = nil

function StoreController:CreateUI()
	-- Wait for ArenaHUD with timeout
	local screenGui
	local success = pcall(function()
		screenGui = playerGui:WaitForChild("ArenaHUD", 10)
	end)
	
	if not success or not screenGui then
		warn("[StoreController] ArenaHUD not found within timeout")
		return
	end

	-- Open button in ArenaHUD
	openButton = screenGui:FindFirstChild("StoreButton", true)
	if openButton then
		openButton.MouseButton1Click:Connect(function()
			self:ShowStore()
		end)
	end

	-- Store UI (from StarterGui) - wait for replication
	local success2 = pcall(function()
		storeUI = playerGui:WaitForChild("StoreUI", 10)
	end)
	
	if success2 and storeUI then
		storeUI.Enabled = false
		container = storeUI:FindFirstChild("Container", true)
		balanceLabel = storeUI:FindFirstChild("BalanceLabel", true)
		itemsFrame = storeUI:FindFirstChild("ItemsFrame", true)
		
		-- Bind close button
		local header = storeUI:FindFirstChild("Header", true)
		if header then
			local closeBtn = header:FindFirstChild("CloseButton", true)
			if closeBtn then
				closeBtn.MouseButton1Click:Connect(function()
					self:HideStore()
				end)
			end
		end
	else
		warn("[StoreController] StoreUI not found within timeout")
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

function StoreController:PopulateItems()
	if not itemsFrame then
		warn("[StoreController] ItemsFrame not found")
		return
	end
	
	-- Clear existing items
	for _, child in ipairs(itemsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local allCosmetics = CosmeticDatabase.GetAllCosmetics()
	
	for _, cosmetic in ipairs(allCosmetics) do
		local itemCard = Instance.new("Frame")
		itemCard.Name = cosmetic.id
		itemCard.Size = UDim2.new(0, 120, 0, 120)
		itemCard.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		itemCard.Parent = itemsFrame
		
		-- Add UIStroke for card hover effect
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(60, 60, 60)
		cardStroke.Thickness = 1
		cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cardStroke.Parent = itemCard
		
		-- Card hover effect (cyan border)
		itemCard.MouseEnter:Connect(function()
			cardStroke.Color = Color3.fromRGB(11, 198, 227) -- #0BC6E3
			cardStroke.Thickness = 2
		end)
		itemCard.MouseLeave:Connect(function()
			cardStroke.Color = Color3.fromRGB(60, 60, 60)
			cardStroke.Thickness = 1
		end)
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0, 25)
		nameLabel.Position = UDim2.new(0, 0, 0, 0)
		nameLabel.Text = cosmetic.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 12
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = itemCard
		
		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.new(1, 0, 0, 20)
		costLabel.Position = UDim2.new(0, 0, 0, 65)
		costLabel.Text = tostring(cosmetic.cost) .. " DNA"
		costLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		costLabel.TextSize = 10
		costLabel.BackgroundTransparency = 1
		costLabel.Parent = itemCard
		
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.8, 0, 0, 25)
		buyButton.Position = UDim2.new(0.1, 0, 0, 90)
		buyButton.Text = "BUY"
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 10
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		buyButton.Parent = itemCard
		
		-- Store original button properties for hover animation
		local originalSize = buyButton.Size
		local originalColor = buyButton.BackgroundColor3
		
		-- Button hover/pressed animations
		buyButton.MouseEnter:Connect(function()
			buyButton.Size = UDim2.new(
				originalSize.X.Scale,
				originalSize.X.Offset,
				originalSize.Y.Scale,
				originalSize.Y.Offset + 2
			)
			buyButton.BackgroundColor3 = brighten(originalColor, 0.15)
		end)
		
		buyButton.MouseLeave:Connect(function()
			buyButton.Size = originalSize
			buyButton.BackgroundColor3 = originalColor
		end)
		
		buyButton.MouseButton1Click:Connect(function()
			self:PurchaseCosmetic(cosmetic.id)
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
	self:PopulateItems()
end

function StoreController:KnitStart()
	self:BindEvents()
end

return StoreController

--!strict
-- StoreController.lua
-- Displays store UI with cosmetics, VFX packs, purchase flow (Wireframe 4)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("RemoteEvents"))
local CosmeticDatabase = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("data"):WaitForChild("CosmeticDatabase"))

local StoreController = Knit.CreateController {
	Name = "StoreController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local storeFrame: ScreenGui? = nil
local selectedCosmetic: string? = nil
local balanceLabel: TextLabel? = nil
local playerDNA: number = 0

-- Create store UI
function StoreController:CreateUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StoreUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false -- Hidden by default
	screenGui.Parent = playerGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 382, 0, 700)
	container.Position = UDim2.new(0.5, -191, 0, 100)
	container.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = screenGui

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	header.BackgroundTransparency = 0.3
	header.BorderSizePixel = 0
	header.Parent = container

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 56, 100)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Text = "STORE"
	title.Parent = header

	-- Balance display
	local balanceFrame = Instance.new("Frame")
	balanceFrame.Name = "BalanceFrame"
	balanceFrame.Size = UDim2.new(1, -32, 0, 80)
	balanceFrame.Position = UDim2.new(0, 16, 0, 70)
	balanceFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	balanceFrame.BackgroundTransparency = 0.3
	balanceFrame.BorderSizePixel = 0
	balanceFrame.Parent = container

	balanceLabel = Instance.new("TextLabel")
	balanceLabel.Name = "BalanceLabel"
	balanceLabel.Size = UDim2.new(1, 0, 0, 50)
	balanceLabel.Position = UDim2.new(0, 0, 0, 15)
	balanceLabel.BackgroundTransparency = 1
	balanceLabel.TextColor3 = Color3.fromRGB(0, 212, 170)
	balanceLabel.TextSize = 32
	balanceLabel.Font = Enum.Font.GothamBold
	balanceLabel.Text = "2,150 DNA"
	balanceLabel.Parent = balanceFrame

	-- Products list (scrolling frame)
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "ProductsList"
	scrollingFrame.Size = UDim2.new(1, -32, 0, 400)
	scrollingFrame.Position = UDim2.new(0, 16, 0, 160)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.Parent = container

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0, 8)
	uiListLayout.Parent = scrollingFrame

	-- Populate products
	self:PopulateProducts(scrollingFrame)

	-- Action buttons
	local buttonFrame = Instance.new("Frame")
	buttonFrame.Name = "ButtonFrame"
	buttonFrame.Size = UDim2.new(1, -32, 0, 110)
	buttonFrame.Position = UDim2.new(0, 16, 1, -126)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = container

	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Name = "PurchaseButton"
	purchaseButton.Size = UDim2.new(1, 0, 0, 50)
	purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 56, 100)
	purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	purchaseButton.TextSize = 16
	purchaseButton.Font = Enum.Font.GothamBold
	purchaseButton.Text = "PURCHASE SELECTED"
	purchaseButton.Parent = buttonFrame
	purchaseButton.MouseButton1Click:Connect(function()
		self:PurchaseSelected()
	end)

	local previewButton = Instance.new("TextButton")
	previewButton.Name = "PreviewButton"
	previewButton.Size = UDim2.new(1, 0, 0, 50)
	previewButton.Position = UDim2.new(0, 0, 0, 60)
	previewButton.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	previewButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	previewButton.TextSize = 16
	previewButton.Font = Enum.Font.GothamBold
	previewButton.Text = "PREVIEW COSMETIC"
	previewButton.Parent = buttonFrame
	previewButton.MouseButton1Click:Connect(function()
		self:PreviewCosmetic()
	end)

	storeFrame = screenGui
end

-- Populate products from database
function StoreController:PopulateProducts(container: Instance)
	local cosmetics = CosmeticDatabase.GetAllCosmetics()

	for _, cosmetic in ipairs(cosmetics) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = cosmetic.id
		itemFrame.Size = UDim2.new(1, 0, 0, 60)
		itemFrame.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		itemFrame.BackgroundTransparency = 0.5
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = container

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.6, 0, 0, 30)
		nameLabel.Position = UDim2.new(0, 8, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = cosmetic.name
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame

		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Desc"
		descLabel.Size = UDim2.new(0.6, 0, 0, 20)
		descLabel.Position = UDim2.new(0, 8, 0, 35)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
		descLabel.TextSize = 12
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = cosmetic.description
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = itemFrame

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "Price"
		priceLabel.Size = UDim2.new(0.35, 0, 0, 40)
		priceLabel.Position = UDim2.new(0.65, 0, 0, 10)
		priceLabel.BackgroundTransparency = 1
		priceLabel.TextColor3 = Color3.fromRGB(0, 212, 170)
		priceLabel.TextSize = 18
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Text = cosmetic.cost .. " DNA"
		priceLabel.Parent = itemFrame

		-- Click to select
		itemFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:SelectCosmetic(cosmetic.id)
			end
		end)
	end
end

-- Select cosmetic
function StoreController:SelectCosmetic(cosmeticId: string)
	selectedCosmetic = cosmeticId
	print("[StoreController] Selected:", cosmeticId)
	-- TODO: Highlight selected item visually
end

-- Update balance display
function StoreController:UpdateBalance(dna: number)
	playerDNA = dna
	if balanceLabel then
		balanceLabel.Text = tostring(dna) .. " DNA"
	end
end

-- Purchase selected cosmetic
function StoreController:PurchaseSelected()
	if not selectedCosmetic then
		print("[StoreController] No cosmetic selected")
		return
	end

	local cosmetic = CosmeticDatabase.GetCosmetic(selectedCosmetic)
	if not cosmetic then
		print("[StoreController] Invalid cosmetic ID")
		return
	end

	-- Check balance (client-side validation, server will double-check)
	if playerDNA < cosmetic.cost then
		print("[StoreController] Insufficient DNA. Need:", cosmetic.cost, "Have:", playerDNA)
		-- TODO: Show error UI
		return
	end

	print("[StoreController] Purchasing:", selectedCosmetic, "for", cosmetic.cost, "DNA")

	-- Send to server
	if RemoteEvents.EquipCosmetic then
		RemoteEvents.EquipCosmetic:FireServer({
			cosmeticId = selectedCosmetic,
			action = "purchase",
		})
	end
end

-- Preview cosmetic
function StoreController:PreviewCosmetic()
	if not selectedCosmetic then
		print("[StoreController] No cosmetic selected for preview")
		return
	end

	print("[StoreController] Previewing:", selectedCosmetic)
	-- TODO: Show preview modal
end

-- Show/hide store
function StoreController:ToggleStore()
	if storeFrame then
		storeFrame.Enabled = not storeFrame.Enabled
	end
end

function StoreController:ShowStore()
	if storeFrame then
		storeFrame.Enabled = true
	end
end

function StoreController:HideStore()
	if storeFrame then
		storeFrame.Enabled = false
	end
end

-- Knit lifecycle
function StoreController:KnitInit()
	self:CreateUI()
end

function StoreController:KnitStart()
	RemoteEvents.GetEvents()

	-- Listen for balance updates from server
	-- TODO: Hook to DataService balance updates
end

return StoreController
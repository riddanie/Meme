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
	local screenGui = playerGui:WaitForChild("StoreUI")
	screenGui.DisplayOrder = 50
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false -- Hidden by default

	-- Main container
	local container = screenGui:WaitForChild("Container")

	-- Header
	local header = container:WaitForChild("Header")
	local title = header:WaitForChild("Title")
	local closeButton = header:WaitForChild("CloseButton")
	closeButton.MouseButton1Click:Connect(function()
		self:HideStore()
	end)

	-- Balance display
	local balanceFrame = container:WaitForChild("BalanceFrame")
	balanceLabel = balanceFrame:WaitForChild("BalanceLabel")

	-- Products list (scrolling frame)
	local scrollingFrame = container:WaitForChild("ProductsList")

	-- Populate products using template
	self:PopulateProducts(scrollingFrame)

	-- Action buttons
	local buttonFrame = container:WaitForChild("ButtonFrame")
	local purchaseButton = buttonFrame:WaitForChild("PurchaseButton")
	purchaseButton.MouseButton1Click:Connect(function()
		self:PurchaseSelected()
	end)

	local previewButton = buttonFrame:WaitForChild("PreviewButton")
	previewButton.MouseButton1Click:Connect(function()
		self:PreviewCosmetic()
	end)

	storeFrame = screenGui
end

-- Populate products from database using template
function StoreController:PopulateProducts(container: ScrollingFrame)
	local cosmetics = CosmeticDatabase.GetAllCosmetics()
	local template = container:FindFirstChild("ProductCard")

	for _, cosmetic in ipairs(cosmetics) do
		local itemFrame: GuiObject
		if template then
			itemFrame = template:Clone()
			itemFrame.Visible = true
		else
			itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, 0, 0, 60)
			itemFrame.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
			itemFrame.BackgroundTransparency = 0.5
			itemFrame.BorderSizePixel = 0
		end
		
		itemFrame.Name = cosmetic.id
		itemFrame.Parent = container

		local nameLabel = itemFrame:FindFirstChild("Name") :: TextLabel?
		if nameLabel then
			nameLabel.Text = cosmetic.name
		end

		local descLabel = itemFrame:FindFirstChild("Desc") :: TextLabel?
		if descLabel then
			descLabel.Text = cosmetic.description
		end

		local priceLabel = itemFrame:FindFirstChild("Price") :: TextLabel?
		if priceLabel then
			priceLabel.Text = cosmetic.price .. " DNA"
		end

		local selectButton = itemFrame:FindFirstChild("SelectButton") :: TextButton?
		if selectButton then
			selectButton.MouseButton1Click:Connect(function()
				self:SelectCosmetic(cosmetic.id, itemFrame)
			end)
		else
			itemFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					self:SelectCosmetic(cosmetic.id, itemFrame)
				end
			end)
		end
	end
	
	if template then
		template.Visible = false -- Hide template
	end
end
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
	
	-- Remove stroke from all items
	if storeFrame then
		local productsList = storeFrame:FindFirstChild("Container"):FindFirstChild("ProductsList")
		if productsList then
			for _, item in ipairs(productsList:GetChildren()) do
				if item:IsA("Frame") then
					local existingStroke = item:FindFirstChild("UIStroke")
					if existingStroke then
						existingStroke:Destroy()
					end
				end
			end
			
			-- Add stroke to selected item
			local selectedItem = productsList:FindFirstChild(cosmeticId)
			if selectedItem then
				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(0, 212, 170)
				stroke.Thickness = 2
				stroke.Parent = selectedItem
			end
		end
	end
end

-- Update balance display
function StoreController:UpdateBalance(dna: number)
	playerDNA = dna
	if balanceLabel then
		balanceLabel.Text = string.format("%d DNA", dna)
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
		-- Request current balance on open
		if RemoteEvents.RequestBalance then
			RemoteEvents.RequestBalance:FireServer()
		end
	end
end

function StoreController:HideStore()
	if storeFrame then
		storeFrame.Enabled = false
	end
end

-- Update balance
function StoreController:UpdateBalance(data: any)
	if type(data) == "table" then
		-- New format with cosmetics
		if balanceLabel then
			balanceLabel.Text = string.format("%d DNA", data.balance or 0)
		end
		playerDNA = data.balance or 0
		
		-- Store cosmetics data for display
		self.ownedCosmetics = data.ownedCosmetics or {}
		self.equippedCosmetic = data.equippedCosmetic or "None"
	else
		-- Legacy format (number only)
		if balanceLabel then
			balanceLabel.Text = string.format("%d DNA", data)
		end
		playerDNA = data
	end
end

-- Knit lifecycle
function StoreController:KnitInit()
	self:CreateUI()
end

function StoreController:KnitStart()
	RemoteEvents.GetEvents()

	-- Request initial balance
	if RemoteEvents.RequestBalance then
		RemoteEvents.RequestBalance:FireServer()
	end

	-- Listen for balance updates
	if RemoteEvents.UpdateBalance then
		RemoteEvents.UpdateBalance.OnClientEvent:Connect(function(balance: number)
			self:UpdateBalance(balance)
		end)
	end
end

return StoreController
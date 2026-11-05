--!strict
-- RagdollService.lua - Ragdoll physics + PartCache pooling
-- Manages 11 variants × 16 instances per variant

local RunService = game:GetService("RunService")

-- Find PartCache module
local PartCache = nil
local src = game.ServerScriptService:FindFirstChild("src")
if src then
	local server = src:FindFirstChild("server")
	if server then
		local modules = server:FindFirstChild("modules")
		if modules then
			local pc = modules:FindFirstChild("PartCache")
			if pc then
				PartCache = require(pc)
			end
		end
	end
end

local RagdollService = {}
RagdollService.__index = RagdollService

RagdollService._pools = {} -- [variantId] = PartCache
RagdollService._activeRagdolls = {} -- [player] = ragdoll model
RagdollService._variants = {
	"Default", "Blob", "Skeleton", "Jellyfish", "Cactus",
	"Pufferfish", "Robot", "Ghost", "Dragon", "Slime", "Mummy"
}

function RagdollService:InitializePools()
	if not PartCache then
		warn("[RagdollService] PartCache not loaded")
		return
	end
	
	-- Create template ragdolls (placeholder models)
	for _, variant in ipairs(self._variants) do
		local template = Instance.new("Model")
		template.Name = "Ragdoll_" .. variant
		
		-- Add humanoid root part
		local humanoidRootPart = Instance.new("Part")
		humanoidRootPart.Name = "HumanoidRootPart"
		humanoidRootPart.Shape = Enum.PartType.Ball
		humanoidRootPart.Size = Vector3.new(2, 2, 2)
		humanoidRootPart.CanCollide = false
		humanoidRootPart.Parent = template
		
		-- Add 4 limb parts for ragdoll skeleton
		local limbs = { "LeftArm", "RightArm", "LeftLeg", "RightLeg" }
		for _, limbName in ipairs(limbs) do
			local limb = Instance.new("Part")
			limb.Name = limbName
			limb.Shape = Enum.PartType.Cylinder
			limb.Size = Vector3.new(1, 3, 1)
			limb.CanCollide = true
			limb.TopSurface = Enum.SurfaceType.Smooth
			limb.BottomSurface = Enum.SurfaceType.Smooth
			limb.Parent = template
			
			-- Add joints (Ball socket for flexibility)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = humanoidRootPart
			weld.Part1 = limb
			weld.Parent = limb
		end
		
		-- Create pool of 16 instances per variant
		self._pools[variant] = PartCache.new(template, 16)
		print("[RagdollService] Pool created for variant:", variant)
	end
end

function RagdollService:ApplyMutation(player: Player, mutationId: string)
	-- Determine ragdoll variant from mutation
	local variantIndex = (string.byte(mutationId:sub(1, 1)) % #self._variants) + 1
	local variant = self._variants[variantIndex]
	
	-- Get ragdoll from pool
	if not self._pools[variant] then
		warn("[RagdollService] Pool not found for variant:", variant)
		return
	end
	
	-- Remove old ragdoll if exists
	if self._activeRagdolls[player] then
		local oldRagdoll = self._activeRagdolls[player]
		local oldVariant = oldRagdoll:GetAttribute("variant") or variant
		self._pools[oldVariant]:ReturnPart(oldRagdoll)
	end
	
	local ragdoll = self._pools[variant]:GetPart()
	ragdoll:SetAttribute("variant", variant)
	ragdoll.Parent = workspace
	self._activeRagdolls[player] = ragdoll
	
	print("[RagdollService] Mutation applied to", player.Name, "- Variant:", variant)
	
	return ragdoll
end

function RagdollService:GetPlayerRagdoll(player: Player)
	return self._activeRagdolls[player]
end

function RagdollService:ReturnRagdoll(player: Player)
	if self._activeRagdolls[player] then
		local ragdoll = self._activeRagdolls[player]
		local variant = ragdoll.Name:split("_")[2] or "Default"
		
		if self._pools[variant] then
			self._pools[variant]:ReturnPart(ragdoll)
		end
		
		self._activeRagdolls[player] = nil
	end
end

-- Tune physics (gravity + collision)
function RagdollService:TunePhysics(ragdoll: Model)
	for _, part in ipairs(ragdoll:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CustomPhysicalProperties = PhysicalProperties.new(
				0.5, -- Density
				0.3, -- Friction
				0.5  -- Elasticity
			)
		end
	end
end

RagdollService:InitializePools()

print("[RagdollService] Module loaded")

return RagdollService
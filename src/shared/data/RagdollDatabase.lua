--!strict
-- RagdollDatabase.lua - 11 Ragdoll variants with visual + physics properties

local RagdollDatabase = {}

-- Ragdoll variant definitions
RagdollDatabase.Variants = {
	{
		id = "default",
		name = "Default",
		description = "Classic humanoid ragdoll",
		color = Color3.fromRGB(150, 150, 150),
		mass = 1,
		friction = 0.3,
	},
	{
		id = "blob",
		name = "Blob",
		description = "Squishy blob form",
		color = Color3.fromRGB(100, 200, 100),
		mass = 0.8,
		friction = 0.5, -- More friction for blob
	},
	{
		id = "skeleton",
		name = "Skeleton",
		description = "Bony skeletal structure",
		color = Color3.fromRGB(200, 200, 200),
		mass = 0.6,
		friction = 0.2, -- Less friction (smooth bones)
	},
	{
		id = "jellyfish",
		name = "Jellyfish",
		description = "Gelatinous tentacled form",
		color = Color3.fromRGB(200, 100, 200),
		mass = 0.5,
		friction = 0.1, -- Slippery
	},
	{
		id = "cactus",
		name = "Cactus",
		description = "Spiky desert form",
		color = Color3.fromRGB(50, 150, 50),
		mass = 1.2,
		friction = 0.4,
	},
	{
		id = "pufferfish",
		name = "Pufferfish",
		description = "Inflated spiky form",
		color = Color3.fromRGB(255, 150, 0),
		mass = 0.9,
		friction = 0.35,
	},
	{
		id = "robot",
		name = "Robot",
		description = "Metallic mechanical form",
		color = Color3.fromRGB(100, 100, 150),
		mass = 1.5,
		friction = 0.2,
	},
	{
		id = "ghost",
		name = "Ghost",
		description = "Ethereal transparent form",
		color = Color3.fromRGB(200, 200, 255),
		mass = 0.3,
		friction = 0.05, -- Very slippery
	},
	{
		id = "dragon",
		name = "Dragon",
		description = "Draconic scaled form",
		color = Color3.fromRGB(200, 50, 50),
		mass = 1.3,
		friction = 0.25,
	},
	{
		id = "slime",
		name = "Slime",
		description = "Oozing gelatinous form",
		color = Color3.fromRGB(100, 200, 100),
		mass = 0.7,
		friction = 0.6, -- High friction for slime
	},
	{
		id = "mummy",
		name = "Mummy",
		description = "Wrapped bandaged form",
		color = Color3.fromRGB(200, 150, 100),
		mass = 1.1,
		friction = 0.3,
	},
}

function RagdollDatabase.GetVariant(id: string)
	for _, variant in ipairs(RagdollDatabase.Variants) do
		if variant.id == id then
			return variant
		end
	end
	return RagdollDatabase.Variants[1] -- Default fallback
end

function RagdollDatabase.GetRandomVariant()
	return RagdollDatabase.Variants[math.random(1, #RagdollDatabase.Variants)]
end

print("[RagdollDatabase] 11 variants loaded")

return RagdollDatabase
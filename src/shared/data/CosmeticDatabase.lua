--!strict
-- CosmeticDatabase.lua
-- Defines cosmetics for Store UI (Wireframe 4)

export type CosmeticType = "character" | "ragdoll" | "vfx" | "emote"
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"

export type CosmeticData = {
	id: string,
	name: string,
	description: string,
	type: CosmeticType,
	rarity: Rarity,
	cost: number,
	preview: string, -- URL or asset ID
}

local CosmeticDatabase: { [string]: CosmeticData } = {
	["CHAR_RED"] = {
		id = "CHAR_RED",
		name = "Red Theme",
		description = "Red color theme for your character",
		type = "character",
		rarity = "Common",
		cost = 100,
		preview = "rbxassetid://[PREVIEW_RED]",
	},
	["CHAR_CYAN"] = {
		id = "CHAR_CYAN",
		name = "Cyan Theme",
		description = "Cyan color theme for your character",
		type = "character",
		rarity = "Common",
		cost = 100,
		preview = "rbxassetid://[PREVIEW_CYAN]",
	},
	["CHAR_GOLD"] = {
		id = "CHAR_GOLD",
		name = "Golden God",
		description = "Golden glow effect on character",
		type = "character",
		rarity = "Legendary",
		cost = 1000,
		preview = "rbxassetid://[PREVIEW_GOLD]",
	},
	["VFX_PARTICLES"] = {
		id = "VFX_PARTICLES",
		name = "Particle Trail",
		description = "Trail of particles behind player",
		type = "vfx",
		rarity = "Common",
		cost = 250,
		preview = "rbxassetid://[PREVIEW_TRAIL]",
	},
	["VFX_LIGHTNING"] = {
		id = "VFX_LIGHTNING",
		name = "Lightning VFX",
		description = "Red lightning particles on movement",
		type = "vfx",
		rarity = "Epic",
		cost = 750,
		preview = "rbxassetid://[PREVIEW_LIGHTNING]",
	},
	["EMOTE_DANCE"] = {
		id = "EMOTE_DANCE",
		name = "Disco Dance",
		description = "Classic disco dance animation",
		type = "emote",
		rarity = "Common",
		cost = 300,
		preview = "rbxassetid://[PREVIEW_DANCE]",
	},
	["EMOTE_SALUTE"] = {
		id = "EMOTE_SALUTE",
		name = "Space Salute",
		description = "Futuristic salute animation",
		type = "emote",
		rarity = "Rare",
		cost = 500,
		preview = "rbxassetid://[PREVIEW_SALUTE]",
	},
	["RAGDOLL_NINJA"] = {
		id = "RAGDOLL_NINJA",
		name = "Ninja Ragdoll",
		description = "Black ninja-themed ragdoll variant",
		type = "ragdoll",
		rarity = "Rare",
		cost = 600,
		preview = "rbxassetid://[PREVIEW_NINJA]",
	},
	["RAGDOLL_ZOMBIE"] = {
		id = "RAGDOLL_ZOMBIE",
		name = "Zombie Ragdoll",
		description = "Green zombie-themed ragdoll variant",
		type = "ragdoll",
		rarity = "Rare",
		cost = 600,
		preview = "rbxassetid://[PREVIEW_ZOMBIE]",
	},
	["RAGDOLL_DEMON"] = {
		id = "RAGDOLL_DEMON",
		name = "Demon Ragdoll",
		description = "Red demon-themed ragdoll variant",
		type = "ragdoll",
		rarity = "Epic",
		cost = 900,
		preview = "rbxassetid://[PREVIEW_DEMON]",
	},
}

-- Get cosmetic by ID
local function GetCosmetic(id: string): CosmeticData?
	return CosmeticDatabase[id]
end

-- Get cosmetics by type
local function GetByType(type_: CosmeticType): { CosmeticData }
	local result = {}
	for _, cosmetic in pairs(CosmeticDatabase) do
		if cosmetic.type == type_ then
			table.insert(result, cosmetic)
		end
	end
	return result
end

-- Get cosmetics by rarity
local function GetByRarity(rarity: Rarity): { CosmeticData }
	local result = {}
	for _, cosmetic in pairs(CosmeticDatabase) do
		if cosmetic.rarity == rarity then
			table.insert(result, cosmetic)
		end
	end
	return result
end

-- Get all cosmetics
local function GetAllCosmetics(): { CosmeticData }
	local result = {}
	for _, cosmetic in pairs(CosmeticDatabase) do
		table.insert(result, cosmetic)
	end
	return result
end

return {
	Cosmetics = CosmeticDatabase,
	GetCosmetic = GetCosmetic,
	GetByType = GetByType,
	GetByRarity = GetByRarity,
	GetAllCosmetics = GetAllCosmetics,
}
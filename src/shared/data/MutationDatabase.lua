--!strict
-- MutationDatabase.lua
-- Defines all 10 mutations with rarity, VFX/SFX, and gameplay effects

export type MutationRarity = "Common" | "Rare" | "Epic" | "Legendary" | "Secret"
export type GameplayType = "cosmetic" | "mobility" | "defense" | "offense" | "zone" | "confusion" | "aoe" | "stealth" | "suicide" | "ultimate"

export type MutationData = {
	id: string,
	name: string,
	rarity: MutationRarity,
	chance: number,
	color: Color3,
	duration: number,
	vfx: {
		type: string,
		intensity: string,
		description: string,
	},
	sfx: string,
	gameplay: {
		type: GameplayType,
		effect: string,
	},
}

local MutationDatabase: { [string]: MutationData } = {
	["BRAINROT"] = {
		id = "BRAINROT",
		name = "BRAINROT",
		rarity = "Common",
		chance = 0.50,
		color = Color3.fromRGB(119, 119, 119),
		duration = 15,
		vfx = {
			type = "particles",
			intensity = "low",
			description = "Brain icon overlay, pink particles, screen shake",
		},
		sfx = "rbxassetid://[BRUH_SOUND]",
		gameplay = {
			type = "cosmetic",
			effect = "Distortion",
		},
	},
	["SPEEDSTER"] = {
		id = "SPEEDSTER",
		name = "SPEEDSTER",
		rarity = "Common",
		chance = 0.50,
		color = Color3.fromRGB(68, 68, 68),
		duration = 15,
		vfx = {
			type = "motion_lines",
			intensity = "low",
			description = "Blue speed lines trailing player, motion blur",
		},
		sfx = "rbxassetid://[WHOOSH_SOUND]",
		gameplay = {
			type = "mobility",
			effect = "Movement speed ×2, jump height ×1.5",
		},
	},
	["TINY_MODE"] = {
		id = "TINY_MODE",
		name = "TINY MODE",
		rarity = "Rare",
		chance = 0.25,
		color = Color3.fromRGB(11, 198, 227),
		duration = 15,
		vfx = {
			type = "particles",
			intensity = "medium",
			description = "Player model shrinks to 30%, sparkle particles",
		},
		sfx = "rbxassetid://[POP_SOUND]",
		gameplay = {
			type = "defense",
			effect = "50% damage reduction, harder to hit",
		},
	},
	["RAGDOLL_MASTER"] = {
		id = "RAGDOLL_MASTER",
		name = "RAGDOLL MASTER",
		rarity = "Rare",
		chance = 0.25,
		color = Color3.fromRGB(107, 91, 149),
		duration = 15,
		vfx = {
			type = "glow",
			intensity = "medium",
			description = "Player limbs glow purple, bone icons float",
		},
		sfx = "rbxassetid://[JOINT_CRACK_SOUND]",
		gameplay = {
			type = "offense",
			effect = "Can grab enemies, throw them (physics)",
		},
	},
	["GRAVITY_WELL"] = {
		id = "GRAVITY_WELL",
		name = "GRAVITY WELL",
		rarity = "Epic",
		chance = 0.15,
		color = Color3.fromRGB(157, 78, 221),
		duration = 15,
		vfx = {
			type = "vortex",
			intensity = "high",
			description = "Black hole effect around player, purple vortex",
		},
		sfx = "rbxassetid://[BASS_BOOM_SOUND]",
		gameplay = {
			type = "zone",
			effect = "Pulls nearby enemies toward player",
		},
	},
	["MEME_VIRUS"] = {
		id = "MEME_VIRUS",
		name = "MEME VIRUS",
		rarity = "Epic",
		chance = 0.15,
		color = Color3.fromRGB(255, 20, 147),
		duration = 15,
		vfx = {
			type = "glitch",
			intensity = "high",
			description = "Screen glitches, rainbow particles, face overlay",
		},
		sfx = "rbxassetid://[MEME_SONG_SOUND]",
		gameplay = {
			type = "confusion",
			effect = "Enemies see random meme images, brief confusion",
		},
	},
	["CHAOS_LIGHTNING"] = {
		id = "CHAOS_LIGHTNING",
		name = "CHAOS LIGHTNING",
		rarity = "Legendary",
		chance = 0.08,
		color = Color3.fromRGB(255, 215, 0),
		duration = 15,
		vfx = {
			type = "lightning",
			intensity = "extreme",
			description = "Red lightning strikes, screen flash, particle explosion",
		},
		sfx = "rbxassetid://[THUNDER_SOUND]",
		gameplay = {
			type = "aoe",
			effect = "Lightning kills on contact, chain to nearby enemies",
		},
	},
	["INVISIBLE_GHOST"] = {
		id = "INVISIBLE_GHOST",
		name = "INVISIBLE GHOST",
		rarity = "Legendary",
		chance = 0.08,
		color = Color3.fromRGB(255, 215, 0),
		duration = 15,
		vfx = {
			type = "fade",
			intensity = "extreme",
			description = "Player fades to transparent, ghostly trail",
		},
		sfx = "rbxassetid://[WHISPER_SOUND]",
		gameplay = {
			type = "stealth",
			effect = "Invisible to enemies, can pass through walls",
		},
	},
	["EXPLODING_CLOWN"] = {
		id = "EXPLODING_CLOWN",
		name = "EXPLODING CLOWN",
		rarity = "Secret",
		chance = 0.02,
		color = Color3.fromRGB(255, 56, 100),
		duration = -1, -- Permanent until match end
		vfx = {
			type = "confetti",
			intensity = "chaos",
			description = "Clown face overlay, confetti explosion, horn sound",
		},
		sfx = "rbxassetid://[HONK_SOUND]",
		gameplay = {
			type = "suicide",
			effect = "On death, explodes and takes nearby enemies with you",
		},
	},
	["GALAXY_GOD"] = {
		id = "GALAXY_GOD",
		name = "GALAXY GOD",
		rarity = "Secret",
		chance = 0.02,
		color = Color3.fromRGB(75, 0, 130),
		duration = 15,
		vfx = {
			type = "cosmic",
			intensity = "chaos",
			description = "Cosmic starfield, orbiting planets, purple galaxy trail",
		},
		sfx = "rbxassetid://[COSMIC_SOUND]",
		gameplay = {
			type = "ultimate",
			effect = "Gravity manipulation and flight",
		},
	},
}

-- Rarity weights for RNG
local RARITY_WEIGHTS = {
	{ rarity = "Common", weight = 50 },
	{ rarity = "Rare", weight = 25 },
	{ rarity = "Epic", weight = 15 },
	{ rarity = "Legendary", weight = 8 },
	{ rarity = "Secret", weight = 2 },
}

-- Get mutation by ID
local function GetMutation(id: string): MutationData?
	return MutationDatabase[id]
end

-- Get random mutation based on rarity weights
local function GetRandomMutation(pityCounter: number): MutationData
	-- Pity system: 20 spins without Legendary/Secret guarantees Legendary
	if pityCounter >= 20 then
		local legendaryPool = {}
		for _, mutation in pairs(MutationDatabase) do
			if mutation.rarity == "Legendary" or mutation.rarity == "Secret" then
				table.insert(legendaryPool, mutation)
			end
		end
		if #legendaryPool > 0 then
			return legendaryPool[math.random(1, #legendaryPool)]
		end
	end

	-- Weighted random
	local totalWeight = 0
	for _, r in ipairs(RARITY_WEIGHTS) do
		totalWeight = totalWeight + r.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0

	for _, r in ipairs(RARITY_WEIGHTS) do
		cumulative = cumulative + r.weight
		if roll <= cumulative then
			-- Collect ALL mutations of selected rarity into pool, then pick random
			local pool = {}
			for _, mutation in pairs(MutationDatabase) do
				if mutation.rarity == r.rarity then
					table.insert(pool, mutation)
				end
			end
			if #pool > 0 then
				return pool[math.random(1, #pool)]
			end
		end
	end

	-- Fallback
	return MutationDatabase["BRAINROT"]
end

-- Get all mutations
local function GetAllMutations(): { MutationData }
	local result = {}
	for _, mutation in pairs(MutationDatabase) do
		table.insert(result, mutation)
	end
	return result
end

return {
	Mutations = MutationDatabase,
	GetMutation = GetMutation,
	GetRandomMutation = GetRandomMutation,
	GetAllMutations = GetAllMutations,
	RarityWeights = RARITY_WEIGHTS,
}
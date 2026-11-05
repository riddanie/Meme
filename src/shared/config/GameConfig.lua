--!strict
-- Game configuration constants

local GameConfig = {
	-- Arena settings
	ARENA_DURATION = 90, -- seconds
	MUTATION_INTERVAL = 15, -- seconds
	
	-- Economy
	BASE_DNA_REWARD = 50,
	DNA_PER_SECOND_SURVIVED = 10,
	LAST_STANDING_BONUS = 200,
	
	-- Gacha system
	MAX_PITY_COUNTER = 20,
	
	-- Server capacity
	MAX_PLAYERS_PER_SERVER = 16,
	PARTCACHE_POOL_SIZE = 16,
	RAGDOLL_VARIANTS = 11,
	
	-- Performance limits
	MAX_PART_COUNT = 2500,
}

return GameConfig

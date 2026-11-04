--!strict
-- PlayerData type definition for ProfileService schema

export type PlayerData = {
	MutagenDNA: number,           -- Currency
	UnlockedMutations: {string},  -- Collection array
	MasteryLevels: {[string]: number}, -- Per-mutation XP
	PityCounter: number,          -- Spins since last rare (max 20)
	OwnedCosmetics: {string},     -- VFX variants
	GamepassFlags: {             -- Purchased passes
		StarterPack: boolean,
		ChaosMaster: boolean,
		RoyalePass: boolean
	},
	TotalSpins: number,           -- Analytics
	TotalDeaths: number           -- Analytics
}

return {}
